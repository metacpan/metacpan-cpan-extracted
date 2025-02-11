package EBook::Ishmael::EBook::PDF;
use 5.016;
our $VERSION = '0.02';
use strict;
use warnings;

use File::Which;
use XML::LibXML;

# This module basically delegates the task of processing PDFs to some of
# Poppler's utilities. The processing is quite inefficient, and the output is
# ugly; PDF isn't really a format suited for plain text rendering.

my $PDFTOHTML = which 'pdftohtml';
my $PDFINFO   = which 'pdfinfo';

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

	unless (defined $PDFINFO) {
		die "Cannot read PDF $self->{Source}: pdfinfo not installed\n";
	}

	my $info = qx/$PDFINFO "$self->{Source}"/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$PDFINFO' on $self->{Source}\n";
	}

	for my $l (split /\n/, $info) {

		my ($k, $v) = split /:\s*/, $l, 2;

		push @{ $self->{Metadata}->{ lc $k } }, $v;

	}

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => {},
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->_get_metadata();

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

sub metadata {

	my $self = shift;

	return $self->{Metadata};

}

1;
