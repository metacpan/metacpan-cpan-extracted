#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use List::Stream;

my $stream = stream( 1, 2, 3, 4 );

is $stream->reduce( sub { my ( $elem, $accum ) = @_; $elem += $accum }, 0 )
  ->count, 1,
  'reduces count properly?';
is $stream->reduce( sub { my ( $elem, $accum ) = @_; $elem += $accum }, 0 )
  ->first, 10,
  'reduces to correct value?';
eval { $stream->reduce() };
ok $@, 'error is thrown when no reducer provided?';
ok $@ =~ /^Invalid operation provided to reduce, must be CODE.*/sm,
  'correct error message?';
eval {
    $stream->reduce( sub { } );
};
ok $@, 'error is thrown when no accum provided?';
ok $@ =~ /^No default\/accumulator provided for reduce.*/sm,
  'correct error message?';

done_testing;
