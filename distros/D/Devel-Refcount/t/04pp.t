#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

# Some hackery to import the PP emulation
require Devel::Refcount;
require B;
*refcount = \&Devel::Refcount::_refcount_pp;

use Symbol qw( gensym );

my %refs = (
   SCALAR => do { my $var; \$var },
   ARRAY  => [],
   HASH   => +{},
   # This magic is to ensure the code ref is new, not shared. To be a new one
   # it has to contain a unique pad.
   CODE   => do { my $var; sub { $var } },
   GLOB   => gensym(),
   Regexp => do { my $var; qr/foo(?{ $var = 1 })/ },
);

is( refcount($refs{SCALAR}), 1, 'refcount(SCALAR) is 1');
is( refcount($refs{ARRAY}),  1, 'refcount(ARRAY) is 1');
is( refcount($refs{HASH}),   1, 'refcount(HASH) is 1');
is( refcount($refs{CODE}),   1, 'refcount(CODE) is 1');
is( refcount($refs{GLOB}),   1, 'refcount(GLOB) is 1');
is( refcount($refs{Regexp}), 1, 'refcount(Regexp) is 1');

my %otherrefs = %refs;
# Hope they're all 2 now

is( refcount($refs{SCALAR}), 2, 'refcount(SCALAR) is now 2');
is( refcount($refs{ARRAY}),  2, 'refcount(ARRAY) is now 2');
is( refcount($refs{HASH}),   2, 'refcount(HASH) is now 2');
is( refcount($refs{CODE}),   2, 'refcount(CODE) is now 2');
is( refcount($refs{GLOB}),   2, 'refcount(GLOB) is now 2');
is( refcount($refs{Regexp}), 2, 'refcount(Regexp) is now 2');
