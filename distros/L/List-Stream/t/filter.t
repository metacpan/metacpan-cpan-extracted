#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use List::Stream;

my $stream = stream( { a => 'b' }, { a => 'c' }, { a => 'b' } );

is $stream->filter( sub { $_->{a} eq 'c' } )->count, 1,
  'filters with sub properly?';
eval { $stream->filter() };
ok $@, 'error is thrown when no filterer provided?';
ok $@ =~ /^Invalid operation provided to filter, must be CODE.*/sm,
  'correct error message?';

done_testing;
