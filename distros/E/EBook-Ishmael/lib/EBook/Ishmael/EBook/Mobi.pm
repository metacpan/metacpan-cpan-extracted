package EBook::Ishmael::EBook::Mobi;
use 5.016;
our $VERSION = '1.01';
use strict;
use warnings;

use Encode qw(from_to);

use XML::LibXML;

use EBook::Ishmael::Decode qw(lz77_decode);
use EBook::Ishmael::PDB;
use EBook::Ishmael::MobiHuff;

# Many thanks to Tommy Persson, the original author of mobi2html, a script
# which much of this code is based off of.

# TODO: Implement AZW3 support
# TODO: Implement AZW4 support

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
	my $fh    = shift;

	return 0 unless -s $file >= 68;

	seek $fh, 32, 0;
	read $fh, my ($null), 1;

	unless ($null eq "\0") {
		return 0;
	}

	seek $fh, 60, 0;
	read $fh, my ($type),    4;
	read $fh, my ($creator), 4;

	return $type eq $TYPE && $creator eq $CREATOR;

}

sub _clean_html {

	my $html = shift;

	$$html =~ s/<mbp:pagebreak\s*\//<br style=\"page-break-after:always\" \//g;
	$$html =~ s/<mbp:pagebreak\s*/<br style=\"page-break-after:always\" \//g;
	$$html =~ s/<\/mbp:pagebreak>//g;
	$$html =~ s/<guide>.*?<\/guide>//g;
	$$html =~ s/<\/?mbp:nu>//g;
	$$html =~ s/<\/?mbp:section//g;
	$$html =~ s/<\/?mbp:frameset>//g;
	$$html =~ s/<\/?mbp:slave-frame>//g;

	return 1;

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

	# Special exth handlers that do not handle normal metadata.
	my %special = (
		201 => sub {
			defined $self->{_imgrec}
				? $self->{_coverrec} = $self->{_imgrec} + unpack "N", $_[0]
				: undef
		},
	);

	my ($doctype, $len, $items) = unpack "a4 N N", $exth;

	my $pos = 12;

	for my $i (1 .. $items) {

		my (undef, $size) = unpack "N N", substr $exth, $pos;
		my $contlen = $size - 8;
		my ($id, undef, $content) = unpack "N N a$contlen", substr $exth, $pos;

		if (exists $EXTH_RECORDS{ $id }) {
			my ($k, $v) = $EXTH_RECORDS{ $id }->($content);
			push @{ $self->{Metadata}->$k }, $v;
		} elsif (exists $special{ $id }) {
			$special{ $id }->($content);
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
		_imgrec      => undef,
		_coverrec    => undef,
		_lastcont    => undef,
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{_pdb} = EBook::Ishmael::PDB->new($file);

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

	(
		$self->{_doctype},
		$self->{_length},
		$self->{_type},
		$self->{_codepage},
		$self->{_uid},
		$self->{_version},
	) = unpack "a4 N N N N N", substr $hdr, 16, 4 * 6;

	unless ($self->{_codepage} == 1252 or $self->{_codepage} == 65001) {
		die "Mobi $self->{Source} uses an unsupported text encoding\n";
	}

	if ($self->{_version} >= 8) {
		die "$self->{Source} uses an unsupported version of Mobi\n";
	}

	# Read some parts of the Mobi header that we care about.
	my ($toff, $tlen)    = unpack "N N", substr $hdr, 0x54, 8;
	$self->{_imgrec}     = unpack "N",   substr $hdr, 0x6c, 4;
	my ($hoff, $hcount)  = unpack "N N", substr $hdr, 0x70, 8;
	$self->{_exth_flag}  = unpack "N",   substr $hdr, 0x80, 4;
	$self->{_lastcont}   = unpack "n",   substr $hdr, 0xc2, 2;
	$self->{_extra_data} = unpack "n",   substr $hdr, 0xf2, 2;

	if ($self->{_lastcont} > $self->{_pdb}->recnum - 1) {
		$self->{_lastcont} = $self->{_pdb}->recnum - 1;
	}

	if ($self->{_imgrec} >= $self->{_lastcont}) {
		undef $self->{_imgrec};
	}

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
		$self->_read_exth(substr $hdr, $self->{_length} + 16);
	}

	unless (@{ $self->{Metadata}->created }) {
		$self->{Metadata}->created([ scalar gmtime $self->{_pdb}->cdate ]);
	}

	if ($self->{_pdb}->mdate) {
		$self->{Metadata}->modified([ scalar gmtime $self->{_pdb}->mdate ]);
	}

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

	if ($self->{_codepage} == 1252) {
		from_to($cont, "cp1252", "utf-8")
			or die "Failed to encode Mobi $self->{Source} text as utf-8\n";
	}

	_clean_html(\$cont);

	print { $fh } $cont;

	close $fh;

	return $out // $html;

}

sub raw {

	my $self = shift;
	my $out  = shift;

	my $raw = '';

	open my $fh, '>', $out // \$raw
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

	my $cont = join('', map { $self->_decode_record($_) } 0 .. $self->{_recnum} - 1);

	_clean_html(\$cont);

	my $dom = XML::LibXML->load_html(
		string => $cont,
		recover => 2
	);

	print { $fh } $dom->textContent;

	close $fh;

	return $out // $raw;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

sub has_cover {

	my $self = shift;

	return defined $self->{_coverrec} && $self->{_coverrec} < $self->{_pdb}->recnum;

}

sub cover {

	my $self = shift;
	my $out  = shift;

	return undef unless $self->has_cover;

	my $bin;

	open my $fh, '>', $out // \$bin
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh;

	print { $fh } $self->{_pdb}->record($self->{_coverrec})->data;

	close $fh;

	return $out // $bin;

}

sub image_num {

	my $self = shift;

	return defined $self->{_imgrec}
		? $self->{_lastcont} - ($self->{_imgrec} - 1)
		: 0;

}

sub image {

	my $self = shift;
	my $n    = shift;

	if ($n >= $self->image_num) {
		return undef;
	}

	my $img = $self->{_pdb}->record($self->{_imgrec} + $n)->data;

	return \$img;

}

1;
