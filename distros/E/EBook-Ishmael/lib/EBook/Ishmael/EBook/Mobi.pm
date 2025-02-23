package EBook::Ishmael::EBook::Mobi;
use 5.016;
our $VERSION = '0.06';
use strict;
use warnings;

use XML::LibXML;

use EBook::Ishmael::Decode qw(lz77_decode);
use EBook::Ishmael::EBook::PDB;
use EBook::Ishmael::MobiHuff;

# Many thanks to Tommy Persson, the original author of mobi2html, a script
# which much of this code is based off of.

my $TYPE    = 'BOOK';
my $CREATOR = 'MOBI';

my $RECSIZE = 4096;

my %EXTH_RECORDS = (
	100 => sub { author      => shift },
	101 => sub { contributor => shift },
	103 => sub { description => shift },
	104 => sub { id          => shift },
	105 => sub { genre       => shift },
	106 => sub { created     => shift },
	108 => sub { contributor => shift },
	114 => sub { format      => "MOBI " . shift },
	524 => sub { language    => shift },
);

sub heuristic {

	my $class = shift;
	my $file  = shift;

	return 0 unless -s $file >= 68;

	open my $fh, '<', $file
		or die "Failed to to open $file for reading: $!\n";
	binmode $fh;

	seek $fh, 32, 0;
	read $fh, my ($null), 1;

	# The PDB title must be null-padded, so the last byte should be a null
	# byte
	unless ($null eq "\0") {
		return 0;
	}

	seek $fh, 60, 0;
	read $fh, my ($type),    4;
	read $fh, my ($creator), 4;

	close $fh;

	return $type eq $TYPE && $creator eq $CREATOR;

}

# The following trailing entry code was adapted from Calibre.

sub _trailing_entry_size {

	my $data = shift;

	my $size = length $data;

	my $pos = 0;
	my $res = 0;

	while (1) {
		my $v = ord substr $data, -1;
		$res |= ($v & 0x7f) << $pos;
		$pos += 7;
		$size -= 1;
		if (($v & 0x80) != 0 or $pos >= 28 or $size == 0) {
			return $res;
		}
	}

}

sub _trailing_entries_size {

	my $self = shift;
	my $data = shift;

	my $res = 0;
	my $size = length $data;
	my $flags = $self->{_extra_data} >> 1;

	while ($flags) {
		if ($flags & 1) {
			$res += _trailing_entry_size(substr $data, 0, $size - $res);
		}
		$flags >>= 1;
	}

	if ($flags & 1) {
		my $off = $size - $res - 1;
		$res += (ord(substr $data, $off, 1) & 0x3) + 1;
	}

	return $res;

}

sub _decode_record {

	my $self = shift;
	my $rec  = shift;

	$rec++;

	my $encode = $self->{_pdb}->record($rec)->data;
	my $trail = $self->_trailing_entries_size($encode);
	substr $encode, -$trail, $trail, '';

	if ($self->{_compression} == 1) {
		return $encode;
	} elsif ($self->{_compression} == 2) {
		return lz77_decode($encode);
	} elsif ($self->{_compression} == 17480) {
		return $self->{_huff}->decode($encode);
	}

}

# TODO: Could probably optimize this.
sub _read_exth {

	my $self = shift;
	my $exth = shift;

	my ($doctype, $len, $items) = unpack "a4 N N", $exth;

	my $pos = 12;

	for my $i (1 .. $items) {

		my (undef, $size) = unpack "N N", substr $exth, $pos;
		my $contlen = $size - 8;
		my ($id, undef, $content) = unpack "N N a$contlen", substr $exth, $pos;

		if (exists $EXTH_RECORDS{ $id }) {
			my ($k, $v) = $EXTH_RECORDS{ $id }->($content);
			push @{ $self->{Metadata}->$k }, $v;
		}

		$pos += $size;

	}

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source       => undef,
		Metadata     => EBook::Ishmael::EBook::Metadata->new,
		_pdb         => undef,
		_compression => undef,
		_textlen     => undef,
		_recnum      => undef,
		_recsize     => undef,
		_encryption  => undef,
		_doctype     => undef,
		_length      => undef,
		_type        => undef,
		_codepage    => undef,
		_uid         => undef,
		_version     => undef,
		_exth_flag   => undef,
		_extra_data  => undef,
		_huff        => undef,
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{_pdb} = EBook::Ishmael::EBook::PDB->new($file);

	my $hdr = $self->{_pdb}->record(0)->data;

	(
		$self->{_compression},
		undef,
		$self->{_textlen},
		$self->{_recnum},
		$self->{_recsize},
		$self->{_encryption},
		undef,
	) = unpack "n n N n n n n", $hdr;

	unless (
		$self->{_compression} == 1 or
		$self->{_compression} == 2 or
		$self->{_compression} == 17480
	) {
		die "Mobi $self->{Source} uses an unsupported compression level\n";
	}

	if ($self->{_recsize} != 4096) {
		die "$self->{Source} is not a Mobi file\n";
	}

	unless ($self->{_encryption} == 0) {
		die "Cannot read encrypted Mobi $self->{Source}\n";
	}

	my $mobihdr = substr $hdr, 16;

	(
		$self->{_doctype},
		$self->{_length},
		$self->{_type},
		$self->{_codepage},
		$self->{_uid},
		$self->{_version},
	) = unpack "a4 N N N N N", $mobihdr;

	my ($toff, $tlen) = unpack "N N", substr $mobihdr, 0x54 - 16;
	$self->{_exth_flag}  = unpack "N", substr $mobihdr, 0x70;
	$self->{_extra_data} = unpack "n", substr $mobihdr, 0xf2 - 16;
	my ($hoff, $hcount) = unpack "N N", substr $mobihdr, 0x70 - 16;

	if ($self->{_compression} == 17480) {

		unless ($EBook::Ishmael::MobiHuff::UNPACK_Q) {
			die "Cannot read AZW $self->{Source}; perl does not support " .
			    "unpacking 64-bit integars\n";
		}

		my @huffs = map { $self->{_pdb}->record($_)->data } ($hoff .. $hoff + $hcount - 1);
		$self->{_huff} = EBook::Ishmael::MobiHuff->new(@huffs);
	}

	$self->{Metadata}->title([ substr $hdr, $toff, $tlen ]);

	if ($self->{_exth_flag}) {
		$self->_read_exth(substr $mobihdr, $self->{_length});
	}

	unless (@{ $self->{Metadata}->created }) {
		$self->{Metadata}->created([ scalar gmtime $self->{_pdb}->cdate ]);
	}

	$self->{Metadata}->modified([ scalar gmtime $self->{_pdb}->mdate ]);

	unless (@{ $self->{Metadata}->format }) {
		$self->{Metadata}->format([ 'MOBI' ]);
	}

	return $self;

}

sub html {

	my $self = shift;
	my $out  = shift;

	my $html = '';

	open my $fh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

	my $cont = join('', map { $self->_decode_record($_) } 0 .. $self->{_recnum} - 1);

	$cont =~ s/<mbp:pagebreak\s*\//<br style=\"page-break-after:always\" \//g;
	$cont =~ s/<mbp:pagebreak\s*/<br style=\"page-break-after:always\" \//g;
	$cont =~ s/<\/mbp:pagebreak>//g;
	$cont =~ s/<guide>.*?<\/guide>//g;
	$cont =~ s/<\/?mbp:nu>//g;
	$cont =~ s/<\/?mbp:section//g;
	$cont =~ s/<\/?mbp:frameset>//g;
	$cont =~ s/<\/?mbp:slave-frame>//g;

	print { $fh } $cont;

	close $fh;

	return $out // $html;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

1;
