#!/usr/bin/perl

use strict;
use warnings;
use Graph;
use IO::Scalar;
use Module::Load;
use Graph::Writer::Dot;
use Graph::Reader::LoadClassHierarchy;

my $class_name = shift;
die "Usage: $0 class_name" unless defined $class_name;

my @additional_classes = @ARGV;
eval { load $_ for @additional_classes };

load $class_name;

my $reader = Graph::Reader::LoadClassHierarchy->new;
my $graph = $reader->read_graph( $class_name );

my $output = IO::Scalar->new;
my $writer = Graph::Writer::Dot->new;
$writer->write_graph( $graph, $output );

print $output;
