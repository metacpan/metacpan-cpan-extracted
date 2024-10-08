#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use List::Stream;

my $stream = stream( 1, 2, 3, 4 );

my $mapped_stream =
  $stream->map( sub { $_ * 2 } )->map( sub { +{ $_ => ( $_ / 2 ) } } )
  ->map( sub { ( keys %$_ )[0] } )->map( sub { $_ * 2 } );

is $mapped_stream->count, $stream->count, 'is count still the same?';
my @data = $mapped_stream->to_list;
is_deeply [@data],                 [ 4, 8, 12, 16 ], 'mapped data is correct?';
is_deeply $mapped_stream->_values, [ 1, 2, 3,  4 ],  'still lazy?';

eval { $stream->map() };
ok $@, 'error thrown when mapping without mapper?';
ok $@ =~ /^Invalid operation provided to map, must be CODE.*/sm,
  'error thrown is correct?';

done_testing;
