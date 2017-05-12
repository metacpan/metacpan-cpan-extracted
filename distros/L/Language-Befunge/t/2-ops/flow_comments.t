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
use Test::More tests => 2;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$lbi->set_curip( $ip );

$lbi->store_code( ';   ;3 q' );
Language::Befunge::Ops::flow_comments( $lbi );
is( $ip->get_position, '(5,0)', 'flow_comments slurps comments' );

$v   = Language::Befunge::Vector->new_zeroes(2);
$ip->set_position( $v );
$lbi->store_code( ';;3 q' );
Language::Befunge::Ops::flow_comments( $lbi );
is( $ip->get_position, '(2,0)', 'flow_comments handles empty comments' );
