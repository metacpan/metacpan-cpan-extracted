package EBook::Ishmael::EBook::PalmDoc;
use 5.016;
our $VERSION = '0.01';
use strict;
use warnings;

use EBook::Ishmael::Decode qw(lz77_decode);
use EBook::Ishmael::EBook::PDB;
use EBook::Ishmael::TextToHtml;

my $TYPE    = 'TEXt';
my $CREATOR = 'REAd';

my $RECSIZE = 4096;

sub heuristic {

	my $class = shift;
	my $file  = shift;

	return 0 unless -s $file >= 68;

	open my $fh, '<', $file
		or die "Failed to to open $file for reading: $!\n";
	binmode $fh;

	seek $fh, 32, 0;
	read $fh, my ($null), 1;

	# Last byte in title must be null
	unless ($null eq "\0") {
		return 0;
	}

	seek $fh, 60, 0;
	read $fh, my ($type),    4;
	read $fh, my ($creator), 4;

	close $fh;

	return $type eq $TYPE && $creator eq $CREATOR;

}

sub _decode_record {

	my $self = shift;
	my $rec  = shift;

	$rec++;

	my $encode = $self->{_pdb}->record($rec)->data;

	if ($self->{_compression} == 1) {
		return $encode;
	} elsif ($self->{_compression} == 2) {
		return lz77_decode($encode);
	}

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source       => undef,
		Metadata     => {},
		_pdb         => undef,
		_compression => undef,
		_textlen     => undef,
		_recnum      => undef,
		_recsize     => undef,
		_curpos      => undef,
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
		$self->{_curpos},
	) = unpack "n n N n n N", $hdr;

	if ($self->{_compression} != 1 and $self->{_compression} != 2) {
		die "$self->{Source} is not a PalmDoc file\n";
	}

	if ($self->{_recsize} != 4096) {
		die "$self->{Source} is not a PalmDoc file\n";
	}

	$self->{Metadata}->{title} = [ $self->{_pdb}->name ];
	$self->{Metadata}->{date} = [
		$self->{_pdb}->cdate
			? scalar gmtime $self->{_pdb}->cdate
			: 'Unknown'
	];

	return $self;

}

sub html {

	my $self = shift;
	my $out  = shift;

	my $html = '';

	open my $fh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

	print { $fh } text2html(
		join('', map { $self->_decode_record($_) } 0 .. $self->{_recnum} - 1)
	);

	close $fh;

	return $out // $html;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata};

}

1;
