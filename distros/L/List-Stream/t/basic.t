#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'List::Stream';
}

use List::Stream;

ok \&stream, 'stream available?';

my @init   = qw(a b c d e f g);
my @orig   = (@init);
my $stream = stream @init;

ok $stream, 'stream is created properly?';
is ref($stream),            'List::Stream', 'stream is proper type?';
is $stream->count,          7,              'stream length is correct?';
is scalar $stream->to_list, 7,              'stream to_list returns values?';
my @data = $stream->map( sub { return shift . 'a' } )->to_list;
is scalar @data, 7, 'stream map to_list returns values?';
is scalar @init, 7, 'stream did not screw up init?';

for ( 0 .. 6 ) {
    is $init[$_], $orig[$_],
      'stream did not screw up init values? - value ' . $_;
    is $data[$_], $orig[$_] . 'a', 'stream map properly applied? - value ' . $_;
}

done_testing;
