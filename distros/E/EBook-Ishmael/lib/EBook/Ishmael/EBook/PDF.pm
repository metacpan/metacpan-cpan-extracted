package EBook::Ishmael::EBook::PDF;
use 5.016;
our $VERSION = '1.05';
use strict;
use warnings;

use File::Temp qw(tempdir);

use File::Which;
use XML::LibXML;

use EBook::Ishmael::Dir;
use EBook::Ishmael::EBook::Metadata;

# This module basically delegates the task of processing PDFs to some of
# Poppler's utilities. The processing is quite inefficient, and the output is
# ugly; PDF isn't really a format suited for plain text rendering.

my $PDFTOHTML = which 'pdftohtml';
my $PDFINFO   = which 'pdfinfo';
my $PDFTOPNG  = which 'pdftopng';
my $PDFIMAGES = which 'pdfimages';

our $CAN_TEST = (
	defined $PDFTOHTML and
	defined $PDFINFO   and
	defined $PDFTOPNG  and
	defined $PDFIMAGES
);

my $MAGIC = '%PDF';

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	read $fh, my ($mag), 4;

	return $mag eq $MAGIC;

}

sub _get_metadata {

	my $self = shift;

	my %meta = (
		'Author'       => sub { author      => shift },
		'CreationDate' => sub { created     => shift },
		'Creator'      => sub { contributor => shift },
		'ModDate'      => sub { modified    => shift },
		'PDF version'  => sub { format      => 'PDF ' . shift },
		'Producer'     => sub { contributor => shift },
		'Title'        => sub { title       => shift },
	);

	unless (defined $PDFINFO) {
		die "Cannot read PDF $self->{Source}: pdfinfo not installed\n";
	}

	my $info = qx/$PDFINFO '$self->{Source}'/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFINFO' on $self->{Source}\n";
	}

	for my $l (split /\n/, $info) {

		my ($field, $content) = split /:\s*/, $l, 2;

		unless (exists $meta{ $field } and $content) {
			next;
		}

		my ($k, $v) = $meta{ $field }->($content);

		push @{ $self->{Metadata}->$k }, $v;

	}

	return 1;

}

sub _images {

	my $self = shift;

	$self->{_imgdir} = tempdir(CLEANUP => 1);

	my $root = File::Spec->catfile($self->{_imgdir}, 'ishmael');

	qx/$PDFIMAGES -png '$self->{Source}' '$root'/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFIMAGES' on $self->{Source}\n";
	}

	@{ $self->{_images} } = dir($self->{_imgdir});

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
		_imgdir  => undef,
		_images  => [],
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->_get_metadata();

	unless (@{ $self->{Metadata}->format }) {
		$self->{Metadata}->format([ 'PDF' ]);
	}

	return $self;

}

sub html {

	my $self = shift;
	my $out  = shift;

	unless (defined $PDFTOHTML) {
		die "Cannot read PDF $self->{Source}: pdftohtml not installed\n";
	}

	my $raw = qx/$PDFTOHTML -i -s -stdout '$self->{Source}'/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFTOHTML' on $self->{Source}\n";
	}

	my $dom = XML::LibXML->load_html(
		string => $raw
	);

	my ($body) = $dom->findnodes('/html/body');

	my $html = join '', map { $_->toString } $body->childNodes;

	if (defined $out) {
		open my $fh, '>', $out
			or die "Failed to open $out for writing: $!\n";
		binmode $fh, ':utf8';
		print { $fh } $html;
		close $fh;
		return $out;
	} else {
		return $html;
	}

}

sub raw {

	my $self = shift;
	my $out  = shift;

	unless (defined $PDFTOHTML) {
		die "Cannot read PDF $self->{Source}: pdftohtml not installed\n";
	}

	my $rawml = qx/$PDFTOHTML -i -s -stdout '$self->{Source}'/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFTOHTML' on $self->{Source}\n";
	}

	my $dom = XML::LibXML->load_html(
		string => $rawml
	);

	my ($body) = $dom->findnodes('/html/body');

	my $raw = join '', $body->textContent;

	if (defined $out) {
		open my $fh, '>', $out
			or die "Failed to open $out for writing: $!\n";
		binmode $fh, ':utf8';
		print { $fh } $raw;
		close $fh;
		return $out;
	} else {
		return $raw;
	}

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

sub has_cover { 1 }

# Just use pdftopng to convert the first page of the PDF to a png then use that
# as the cover.
sub cover {

	my $self = shift;
	my $out  = shift;

	unless (defined $PDFTOPNG) {
		die "Cannot dump PDF $self->{Source} cover: pdftopng not installed\n";
	}

	my $tmpdir = tempdir(CLEANUP => 1);
	my $tmproot = File::Spec->catfile($tmpdir, 'tmp');

	qx/$PDFTOPNG -f 1 -l 1 '$self->{Source}' '$tmproot'/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFTOPNG' on $self->{Source}\n";
	}

	my ($png) = dir($tmpdir);

	unless (defined $png) {
		die "'$PDFTOPNG' could not produce a cover image from $self->{Source}\n";
	}

	open my $rh, '<', $png
		or die "Failed to open $png for reading: $!\n";
	binmode $rh;
	my $bin = do { local $/ = undef; readline $rh };
	close $rh;

	if (defined $out) {
		open my $wh, '>', $out
			or die "Failed to open $out for writing: $!\n";
		binmode $wh;
		print { $wh } $bin;
		close $wh;
		return $out;
	} else {
		return $bin;
	}

}

sub image_num {

	my $self = shift;

	unless (defined $self->{_imgdir}) {
		$self->_images;
	}

	return scalar @{ $self->{_images} };

}

sub image {

	my $self = shift;
	my $n    = shift;

	if ($n >= $self->image_num) {
		return undef;
	}

	open my $fh, '<', $self->{_images}[$n]
		or die "Failed to open $self->{_images}[$n]: $!\n";
	binmode $fh;
	my $img = do { local $/ = undef; readline $fh };
	close $fh;

	return \$img;

}

1;
