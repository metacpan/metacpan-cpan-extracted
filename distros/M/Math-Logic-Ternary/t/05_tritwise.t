# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for tritwise operations of Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/05_tritwise.t'

#########################

use strict;
use warnings;
use Test::More tests => 44;
use Math::Logic::Ternary qw(:all);

#########################

my $op1 = word9('@tttfffnnn');
my $op2 = word9('@tfntfntfn');
my $op3 = word9('@fntfntfnt');
my $op4 = word9('@ntfntfntf');

is($op1->not->as_string, '@ffftttnnn');  # 1
is($op1->and($op2)->as_string, '@tfnfffnfn');  # 2
is($op1->or($op2)->as_string, '@ttttfntnn');  # 3

is($op1->generic('b012201120', $op2)->as_string, '@ntffnttfn');  # 4
is($op1->mpx($op2, $op3, $op4)->as_string, '@fntntftfn');  # 5

is(nil->xor($op2), nil);                # 6
is(nil->xor($op3), nil);                # 7
is(nil->xor($op4), nil);                # 8
is(true->xor($op2), nil);               # 9
is(true->xor($op3), false);             # 10
is(true->xor($op4), true);              # 11
is(false->xor($op2), nil);              # 12
is(false->xor($op3), true);             # 13
is(false->xor($op4), false);            # 14

is(nil->mpx($op2, $op3, $op4), nil);    # 15
is(nil->mpx($op3, $op4, $op2), true);   # 16
is(nil->mpx($op4, $op2, $op3), false);  # 17
is(true->mpx($op2, $op4, $op3), false);  # 18
is(true->mpx($op3, $op2, $op4), nil);   # 19
is(true->mpx($op4, $op3, $op2), true);  # 20
is(false->mpx($op2, $op4, $op3), true);  # 21
is(false->mpx($op3, $op2, $op4), false);  # 22
is(false->mpx($op4, $op3, $op2), nil);  # 23

is(word9->Mpx($op2, $op3, $op4), $op2);  # 24
is(word9->Mpx($op3, $op4, $op2), $op3);  # 25
is(word9->Mpx($op4, $op2, $op3), $op4);  # 26
is($op2->Mpx($op2, $op4, $op3), $op4);  # 27
is($op2->Mpx($op3, $op2, $op4), $op2);  # 28
is($op2->Mpx($op4, $op3, $op2), $op3);  # 29
is($op3->Mpx($op2, $op4, $op3), $op3);  # 30
is($op3->Mpx($op3, $op2, $op4), $op4);  # 31
is($op3->Mpx($op4, $op3, $op2), $op2);  # 32
is($op4->Mpx($op2, $op4, $op3), $op4);  # 33
is($op4->Mpx($op3, $op2, $op4), $op2);  # 34
is($op4->Mpx($op4, $op3, $op2), $op3);  # 35

is(nil->Mpx($op2, $op3, $op4), $op2);   # 36
is(nil->Mpx($op3, $op4, $op2), $op3);   # 37
is(nil->Mpx($op4, $op2, $op3), $op4);   # 38
is(true->Mpx($op2, $op4, $op3), $op4);  # 39
is(true->Mpx($op3, $op2, $op4), $op2);  # 40
is(true->Mpx($op4, $op3, $op2), $op3);  # 41
is(false->Mpx($op2, $op4, $op3), $op3);  # 42
is(false->Mpx($op3, $op2, $op4), $op4);  # 43
is(false->Mpx($op4, $op3, $op2), $op2);  # 44

__END__
