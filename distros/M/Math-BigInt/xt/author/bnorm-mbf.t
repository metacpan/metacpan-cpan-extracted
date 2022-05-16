# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 5;

use Math::BigFloat;

my $LIB = Math::BigFloat -> config('lib');

my $x = Math::BigFloat -> bzero();

my @data =
  (
   [ ['+',   '0', '-', '2'], ['+', '0', '+', '0'] ],
   [ ['+',   '0', '+', '0'], ['+', '0', '+', '0'] ],
   [ ['+',   '0', '+', '2'], ['+', '0', '+', '0'] ],
   [ ['+',  '10', '+', '0'], ['+', '1', '+', '1'] ],
   [ ['+', '100', '+', '0'], ['+', '1', '+', '2'] ],
  );

for my $entry (@data) {
    my $in  = $entry -> [0];
    my $out = $entry -> [1];

    my $x = bless {
                   sign => $in->[0],
                   _m   => $LIB -> _new($in->[1]),
                   _es  => $in->[2],
                   _e   => $LIB -> _new($in->[3]),
                  }, "Math::BigFloat";

    $x -> bnorm();

    my $test = $in->[0] . $in->[1] . 'e' . $in->[2] . $in->[3] . " => "
             . $out->[0] . $out->[1] . 'e' . $out->[2] . $out->[3];

    subtest $test => sub {
        plan tests => 4;

        is($x->{sign}, $out->[0], 'sign of mantissa');
        is($LIB->_str($x->{_m}), $out->[1], 'absolute value of mantissa');
        is($x->{_es}, $out->[2], 'sign of exponent');
        is($LIB->_str($x->{_e}), $out->[3], 'absolute value of exponent');
    };
}
