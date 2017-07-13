#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;

use GraphViz::Graph;

my $file_base_name = 'test-003';
my $graph = GraphViz::Graph->new($file_base_name);

my $dot_file_name  = "$file_base_name.dot";
my $png_file_name  = "$file_base_name.png";
$graph->create('png');

ok(-e $png_file_name, "$png_file_name exists");

my $file_type = readpipe("file $png_file_name");
like ($file_type, qr/^test-003.png: PNG image data, /, "filetype is png");

unlink $png_file_name;
unlink $dot_file_name;
