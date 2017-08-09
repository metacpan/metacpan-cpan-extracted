# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for the base package Math::Logic::Ternary

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/09_base.t'

#########################

use strict;
use warnings;
use Test::More tests => 20;
BEGIN { use_ok( 'Math::Logic::Ternary' => ':all' ); }  # 1

#########################

isa_ok(nil, 'Math::Logic::Ternary::Trit');  # 2
isa_ok(true, 'Math::Logic::Ternary::Trit');  # 3
isa_ok(false, 'Math::Logic::Ternary::Trit');  # 4

my $w9 = word9(nil, true, false);
isa_ok($w9, 'Math::Logic::Ternary::Word');  # 5
is($w9->Sign, false);                   # 6
is($w9->Rtrits + 0, 3);                 # 7
is($w9->Trits + 0, 9);                  # 8

my @w = $w9->Words(3);
is(@w + 0, 3);                          # 9
ok($w[2]->is_equal(nil));               # 10
ok(nil->is_equal($w[2]));               # 11
ok($w[1]->is_equal($w[2]));             # 12
ok($w9->is_equal($w[0]));               # 13
ok(!nil->is_true);                      # 14

my $w27 = word27->convert_base27('test_more');
isa_ok($w27, 'Math::Logic::Ternary::Word');  # 15
ok(!$w27->is_equal($w27->convert_base27('test_less')));  # 16

my $w81 = word81->convert_base27('big_math_logic_ternary_word');
isa_ok($w81, 'Math::Logic::Ternary::Word');  # 17
my $x81 = ternary_word(81, $w81->Rtrits);
isa_ok($x81, 'Math::Logic::Ternary::Word');  # 18
my $i = $x81->as_int;
isa_ok($i, 'Math::BigInt');             # 19
my $j = grep { !$_->is_nil } $x81->Trits;
is($j, 45);                             # 20

__END__
