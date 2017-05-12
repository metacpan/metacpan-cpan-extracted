#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;

use Devel::Refcount qw( assert_oneref );

my $anon = [];

ok( !exception { assert_oneref $anon },
    'assert_oneref on one-reference anon array' );

my $otherref = $anon;

like( exception { assert_oneref $anon },
      qr/^Expected ARRAY\(0x[[:xdigit:]]+\) to have only one reference, found 2 at /,
      'assert_oneref on two-reference anon array' );

my %hash = ( element => [] );

ok( !exception { assert_oneref delete $hash{element} },
    'assert_oneref on deleted hash element' );
