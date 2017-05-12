#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;

use Flux::Simple qw(array_out);

my @data = qw( 0 1 2 );
my $out = array_out(\@data);
ok $out->does('Flux::Out'), 'array_out is Out';

$out->write('a');
$out->write('b');
$out->write_chunk(['c', 'd']);

is_deeply \@data, [qw( 0 1 2 a b c d )];
$out->commit;
is_deeply \@data, [qw( 0 1 2 a b c d )];

done_testing;
