#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;

use Flux::Simple qw( array_out mapper );

my @data;
my $out = array_out(\@data);
my $mapped_out = mapper { $_[0] x 2 } | $out;

ok $mapped_out->does('Flux::Out');
$mapped_out->write('a');
$mapped_out->write('b');
is_deeply \@data, [qw( aa bb )];

done_testing;
