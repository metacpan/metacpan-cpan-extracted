# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for logical operations of Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/04_logical.t'

#########################

use strict;
use warnings;
use Test::More tests => 39;
use Math::Logic::Ternary qw(:all);

#########################

my $t3 = ternary_word(3, '@tfn');
my $f3 = ternary_word(3, '@fnt');
my $n3 = ternary_word(3, '@nnn');

is($t3->NOT, false);                    # 1
is($f3->NOT, true);                     # 2
is($n3->NOT, nil);                      # 3

is($t3->AND($t3), true);                # 4
is($t3->AND($f3), false);               # 5
is($t3->AND($n3), nil);                 # 6
is($f3->AND($t3), false);               # 7
is($f3->AND($f3), false);               # 8
is($f3->AND($n3), false);               # 9
is($n3->AND($t3), nil);                 # 10
is($n3->AND($f3), false);               # 11
is($n3->AND($n3), nil);                 # 12

is($t3->OR($t3), true);                 # 13
is($t3->OR($f3), true);                 # 14
is($t3->OR($n3), true);                 # 15
is($f3->OR($t3), true);                 # 16
is($f3->OR($f3), false);                # 17
is($f3->OR($n3), nil);                  # 18
is($n3->OR($t3), true);                 # 19
is($n3->OR($f3), nil);                  # 20
is($n3->OR($n3), nil);                  # 21

is($n3->GENERIC('b012201120', $n3), nil);  # 22
is($n3->GENERIC('b012201120', $t3), true);  # 23
is($n3->GENERIC('b012201120', $f3), false);  # 24
is($t3->GENERIC('b012201120', $n3), false);  # 25
is($t3->GENERIC('b012201120', $t3), nil);  # 26
is($t3->GENERIC('b012201120', $f3), true);  # 27
is($f3->GENERIC('b012201120', $n3), true);  # 28
is($f3->GENERIC('b012201120', $t3), false);  # 29
is($f3->GENERIC('b012201120', $f3), nil);  # 30

is($n3->MPX($n3, $t3, $f3), nil);       # 31
is($n3->MPX($t3, $f3, $n3), true);      # 32
is($n3->MPX($f3, $n3, $t3), false);     # 33
is($t3->MPX($n3, $f3, $t3), false);     # 34
is($t3->MPX($t3, $n3, $f3), nil);       # 35
is($t3->MPX($f3, $t3, $n3), true);      # 36
is($f3->MPX($n3, $f3, $t3), true);      # 37
is($f3->MPX($t3, $n3, $f3), false);     # 38
is($f3->MPX($f3, $t3, $n3), nil);       # 39

__END__
