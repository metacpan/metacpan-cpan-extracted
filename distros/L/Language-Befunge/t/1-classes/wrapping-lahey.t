#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

#
# Language::Befunge::Wrapping::LaheySpace
#

use strict;
use warnings;

use Test::More tests => 12;

use Language::Befunge::IP;
use Language::Befunge::Storage::2D::Sparse;
use aliased 'Language::Befunge::Vector' => 'LBV';
use Language::Befunge::Wrapping::LaheySpace;

# vars used within the file
my ($w, $s);
my $ip = Language::Befunge::IP->new(2);


#-- constructor

#- new()
$w = Language::Befunge::Wrapping::LaheySpace->new;
isa_ok($w, 'Language::Befunge::Wrapping');
isa_ok($w, 'Language::Befunge::Wrapping::LaheySpace');
can_ok($w, 'wrap');


#-- public methods

#- wrap()
# main cardinal directions
$s = Language::Befunge::Storage::2D::Sparse->new;
$s->set_value( LBV->new(5,10), 32 );
# east
$ip->set_position( LBV->new(6,3) );
$ip->set_delta( LBV->new(1,0) );
$w->wrap($s,$ip);
is($ip->get_position, '(0,3)', 'wrap() wraps xmax (east)');
# west
$ip->set_position( LBV->new(-1,4) );
$ip->set_delta( LBV->new(-1,0) );
$w->wrap($s,$ip);
is($ip->get_position, '(5,4)', 'wrap() wraps xmin (west)');
# south
$ip->set_position( LBV->new(2,11) );
$ip->set_delta( LBV->new(0,1) );
$w->wrap($s,$ip);
is($ip->get_position, '(2,0)', 'wrap() wraps ymax (south)');
# north
$ip->set_position( LBV->new(2,-1) );
$ip->set_delta( LBV->new(0,-1) );
$w->wrap($s,$ip);
is($ip->get_position, '(2,10)', 'wrap() wraps ymin (north)');
# east with delta that overflows width
$ip->set_position( LBV->new(11,3) );
$ip->set_delta( LBV->new(8,0) );
$w->wrap($s,$ip);
is($ip->get_position, '(3,3)', 'wrap() wraps xmax (big east delta)');
# west with delta that overflows width
$ip->set_position( LBV->new(-5,4) );
$ip->set_delta( LBV->new(-8,0) );
$w->wrap($s,$ip);
is($ip->get_position, '(3,4)', 'wrap() wraps xmin (big west delta)');
# south with delta that overflows height
$ip->set_position( LBV->new(2,20) );
$ip->set_delta( LBV->new(0,12) );
$w->wrap($s,$ip);
is($ip->get_position, '(2,8)', 'wrap() wraps ymax (big south delta)');
# north with delta that overflows height
$ip->set_position( LBV->new(2,-5) );
$ip->set_delta( LBV->new(0,-12) );
$w->wrap($s,$ip);
is($ip->get_position, '(2,7)', 'wrap() wraps ymin (big north delta)');

# diagonals
$s = Language::Befunge::Storage::2D::Sparse->new;
$s->set_value( LBV->new(-1,-2), 32 );
$s->set_value( LBV->new( 6, 5), 32 );
$ip->set_position( LBV->new(1,-3) );
$ip->set_delta( LBV->new(-2,-3) );
$w->wrap($s,$ip);
is($ip->get_position, '(5,3)', 'wrap() wraps even diagonals');


