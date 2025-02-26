package EBook::Ishmael::EBook::PDF;
use 5.016;
our $VERSION = '0.07';
use strict;
use warnings;

use File::Temp qw(tempdir);

use File::Which;
use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;

# This module basically delegates the task of processing PDFs to some of
# Poppler's utilities. The processing is quite inefficient, and the output is
# ugly; PDF isn't really a format suited for plain text rendering.

my $PDFTOHTML = which 'pdftohtml';
my $PDFINFO   = which 'pdfinfo';
my $PDFTOPNG  = which 'pdftopng';

my $MAGIC = '%PDF';

sub heuristic {

	my $class = shift;
	my $file  = shift;

	open my $fh, '<', $file
		or die "Failed to open $file for reading: $!\n";
	binmode $fh;
	read $fh, my ($mag), 4;
	close $fh;

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

	my $info = qx/$PDFINFO "$self->{Source}"/;

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

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
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

	my $html = '';

	open my $fh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh, ':utf8';

	my $raw = qx/$PDFTOHTML -i -s -stdout "$self->{Source}"/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFTOHTML' on $self->{Source}\n";
	}

	my $dom = XML::LibXML->load_html(
		string => $raw
	);

	my ($body) = $dom->findnodes('/html/body');

	print { $fh } map { $_->toString() } $body->childNodes();

	close $fh;

	return $out // $html;

}

sub raw {

	my $self = shift;
	my $out  = shift;

	unless (defined $PDFTOHTML) {
		die "Cannot read PDF $self->{Source}: pdftohtml not installed\n";
	}

	my $raw = '';

	open my $fh, '>', $out // \$raw
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh, ':utf8';

	my $rawml = qx/$PDFTOHTML -i -s -stdout "$self->{Source}"/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFTOHTML' on $self->{Source}\n";
	}

	my $dom = XML::LibXML->load_html(
		string => $rawml
	);

	my ($body) = $dom->findnodes('/html/body');

	print { $fh } $body->textContent;

	close $fh;

	return $out // $raw;

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

	qx/$PDFTOPNG -f 1 -l 1 "$self->{Source}" "$tmproot"/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFTOPNG' on $self->{Source}\n";
	}

	my ($png) = glob "$tmpdir/*";

	unless (defined $png) {
		die "'$PDFTOPNG' could not produce a cover image from $self->{Source}\n";
	}

	my $bin;

	open my $wh, '>', $out // \$bin
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $wh;

	open my $rh, '<', $png
		or die "Failed to open $png for reading: $!\n";
	binmode $rh;

	while (read $rh, my ($buf), 1024) {
		print { $wh } $buf;
	}

	close $wh;
	close $rh;

	return $out // $bin;

}

1;
