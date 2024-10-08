#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use List::Stream;

my $stream = stream( { a => 'b' }, { a => 'c' }, { a => 'b' } );

is $stream->count, 3, 'count is proper?';
my $uq_stream = $stream->unique;
my @vals      = $uq_stream->to_list;
is @vals, 3, 'count is still three?';
my @uq_vals =
  $stream->unique( sub { return $_->{a} } )->to_list;
is @uq_vals, 2, 'count for unique is correct?';
is_deeply $uq_vals[0], { a => 'b' }, 'first elem correct?';
is_deeply $uq_vals[1], { a => 'c' }, 'second elem correct?';

done_testing;
