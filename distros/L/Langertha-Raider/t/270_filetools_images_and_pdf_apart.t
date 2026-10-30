#!/usr/bin/env perl
# ABSTRACT: read_file asks sees_images and reads_pdf apart: a model can take images and no PDFs, or the reverse (karr k166)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;

use Langertha::Raider::FileTools qw( build_file_tools_server );

my $tmp  = Path::Tiny->tempdir;
my $root = $tmp->realpath;
$root->child('pic.png')->spew_raw("\x89PNG\r\n\x1a\n".( "\0" x 20 ));
$root->child('doc.pdf')->spew_raw("%PDF-1.4\n%%EOF\n");

my %can;
my $server = build_file_tools_server(
  root        => "$root",
  sees_images => sub { $can{images} },
  reads_pdf   => sub { $can{pdf} },
);
my ($tool) = grep { $_->name eq 'read_file' } @{ $server->tools };
sub read_file {
  my ($path) = @_;
  my $r = $tool->code->( $tool, { path => $path } );
  return ( $r->{isError} ? 1 : 0, join( "\n", map { $_->{text} // '' } @{ $r->{content} } ), $r );
}

# name, images, pdf, image refused?, pdf refused?
my @cases = (
  [ 'images only (Anthropic-like without PDF)', 1, 0, 0, 1 ],
  [ 'PDF only',                                 0, 1, 1, 0 ],
  [ 'both (Anthropic-like)',                    1, 1, 0, 0 ],
  [ 'neither (MiniMax/Perplexity-like)',        0, 0, 1, 1 ],
);
for my $c (@cases) {
  my ( $name, $images, $pdf, $image_refused, $pdf_refused ) = @$c;
  subtest $name => sub {
    @can{qw( images pdf )} = ( $images, $pdf );
    my ( $err, $text, $r ) = read_file('pic.png');
    is $err, $image_refused, 'the image is '.( $image_refused ? 'refused' : 'sent' );
    like $text, qr/cannot see images/, 'saying images' if $image_refused;
    is $r->{content}[0]{type}, 'image', 'as image content' unless $image_refused;
    ( $err, $text, $r ) = read_file('doc.pdf');
    is $err, $pdf_refused, 'the PDF is '.( $pdf_refused ? 'refused' : 'sent' );
    like $text, qr/cannot see PDF files/, 'saying PDF files' if $pdf_refused;
    is $r->{content}[1]{resource}{mimeType}, 'application/pdf', 'as a document' unless $pdf_refused;
  };
}

subtest 'neither callback falls back on the other' => sub {
  my $only_images = build_file_tools_server( root => "$root", sees_images => 0 );
  my ($t) = grep { $_->name eq 'read_file' } @{ $only_images->tools };
  my $r = $t->code->( $t, { path => 'doc.pdf' } );
  ok !$r->{isError}, 'reads_pdf not given: default true, sees_images does not decide for the PDF';
  my $only_pdf = build_file_tools_server( root => "$root", reads_pdf => 1, sees_images => 0 );
  ($t) = grep { $_->name eq 'read_file' } @{ $only_pdf->tools };
  $r = $t->code->( $t, { path => 'pic.png' } );
  ok $r->{isError}, 'sees_images false refuses the image whatever reads_pdf says';
};

subtest 'notebook output images follow sees_images, not reads_pdf' => sub {
  $root->child('nb.ipynb')->spew_utf8(<<'EOJ');
{ "metadata": {}, "cells": [ { "id": "c1", "cell_type": "code", "source": "plot()",
  "outputs": [ { "output_type": "display_data", "data": { "image/png": "iVBORw0KGgo=" } } ] } ] }
EOJ
  my %types;
  for my $c ( [ 1, 0 ], [ 0, 1 ] ) {
    @can{qw( images pdf )} = @$c;
    my ( $err, $text, $r ) = read_file('nb.ipynb');
    $types{ $c->[0] } = [ map { $_->{type} } @{ $r->{content} } ];
  }
  ok( ( grep { $_ eq 'image' } @{ $types{1} } ), 'images on: the output image is there' );
  ok( !( grep { $_ eq 'image' } @{ $types{0} } ), 'images off (PDF on): no image' );
};

done_testing;
