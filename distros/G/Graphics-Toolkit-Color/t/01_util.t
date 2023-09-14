#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 24;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Util';

eval "use $module";
is( not($@), 1, 'could load the module');

my $round = \&Graphics::Toolkit::Color::Space::Util::round;
is( $round->(0.5),           1,     'round 0.5 upward');
is( $round->(0.500000001),   1,     'everything above 0.5 gets also increased');
is( $round->(0.4999999),     0,     'everything below 0.5 gets smaller');
is( $round->(-0.5),         -1,     'round -0.5 downward');
is( $round->(-0.500000001), -1,     'everything beow -0.5 gets also lowered');
is( $round->(-0.4999999),    0,     'everything upward from -0.5 gets increased');

my $rmod = \&Graphics::Toolkit::Color::Space::Util::rmod;
my $close = \&Graphics::Toolkit::Color::Space::Util::close_enough;
is( $rmod->(),                       0,     'default to 0 when both values missing');
is( $rmod->(1),                      0,     'default to 0 when a value is missing');
is( $rmod->(1,0),                    0,     'default to 0 when a divisor is zero');
is( $rmod->(3, 2),                   1,     'normal int mod');
is( $close->($rmod->(2.1, 2), 0.1),  1,     'real mod when dividend is geater');
is( $close->($rmod->(.1, 2), 0.1),   1,     'real mod when divisor is geater');
is( $rmod->(-3, 2),                 -1,     'int mod with negative dividend');
is( $close->($rmod->(-3.1, 2), -1.1),1,     'real mod with negative dividend');
is( $rmod->(3, -2),                  1,     'int mod with negative divisor');
is( $close->($rmod->(3.1, -2), 1.1), 1,     'real mod with negative divisor');
is( $rmod->(-3, -2),                -1,     'int mod with negative divisor');
is( $close->($rmod->(-3.1, -2),-1.1),1,     'real mod with negative dividend and divisor');
is( $close->($rmod->(15.3, 4), 3.3), 1,     'real mod with different values');

my $min = \&Graphics::Toolkit::Color::Space::Util::min;
my $max = \&Graphics::Toolkit::Color::Space::Util::max;

is( $min->(1,2,3),     1  ,     'simple minimum');
is( $min->(-1.1,2,3), -1.1,     'negative minimum');
is( $max->(1,2,3),       3,           'simple maximum');
is( $max->(-1,2,10E3), 10000,   'any syntax maximum');

exit 0;
