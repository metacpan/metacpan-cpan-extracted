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
use Test::More tests => 4;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$lbi->set_curip( $ip );

$ip->spush( 12, 63, 42 );
Language::Befunge::Ops::decis_gt( $lbi );
is( $ip->spop, 1,  'decis_get pushes true if greater than' );
is( $ip->spop, 12, 'decis_get pops only two values' );

$ip->spush( 63, 63 );
Language::Befunge::Ops::decis_gt( $lbi );
is( $ip->spop, 0, 'decis_get pushes false if equal' );

$ip->spush( 42, 63 );
Language::Befunge::Ops::decis_gt( $lbi );
is( $ip->spop, 0, 'decis_get pushes false if less than' );
