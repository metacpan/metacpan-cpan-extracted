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
use Language::Befunge::Vector;
use Test::More tests => 4;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$lbi->set_curip( $ip );

$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$ip->spush( 12, 24, 46 );
Language::Befunge::Ops::decis_cmp( $lbi );
is( $ip->get_delta, '(0,-1)',
    'decis_cmp turns left if popped values are sorted' );
is( $ip->spop, 12, 'decis_cmp pops only two values' );

$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$ip->spush( 12, 24, 13 );
Language::Befunge::Ops::decis_cmp( $lbi );
is( $ip->get_delta, '(0,1)',
    'decis_cmp turns right if popped values are not sorted' );

$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$ip->spush( 12, 24, 24 );
Language::Befunge::Ops::decis_cmp( $lbi );
is( $ip->get_delta, '(1,0)',
    'decis_cmp continues forward if popped values are equal' );

