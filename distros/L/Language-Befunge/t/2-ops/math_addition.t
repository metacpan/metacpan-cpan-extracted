#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Test::Exception;
use Test::More tests => 4;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$lbi->set_curip( $ip );

$ip->spush( 21, 42, 63 );
Language::Befunge::Ops::math_addition( $lbi );
is( $ip->spop, 105, 'math_addition pushes new value' );
is( $ip->spop, 21,  'math_addition pops only two values' );

# overflow
$ip->spush( 2**31-2, 3 );
throws_ok( sub { Language::Befunge::Ops::math_addition($lbi) },
    qr/overflow/, 'math_addition barfs on overflow' );

# underflow
$ip->spush( -2**31+2, -3 );
throws_ok( sub { Language::Befunge::Ops::math_addition($lbi) },
    qr/under/, 'math_addition barfs on underflow' );
