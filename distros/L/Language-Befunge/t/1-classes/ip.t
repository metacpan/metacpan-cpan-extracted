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
# Language::Befunge::IP tests
#

use strict;
use warnings;

use Test::More tests => 132;
use Language::Befunge::IP;

my ($ip, $clone);


#-- constructor

# new()
$ip = Language::Befunge::IP->new(3);
isa_ok($ip,          "Language::Befunge::IP");
is($ip->get_dims, 3, "can specify the number of dims");
is($ip->get_id,   0, "unique ids begin with zero");
$ip = Language::Befunge::IP->new;
is($ip->get_dims, 2, "dims default to 2");
is($ip->get_id,   1, "each IP gets a unique id");


#-- accessors

$ip->get_position->set_component(0,36);
is( $ip->get_position->get_component(0), 36 );
$ip->get_position->set_component(1,27);
is( $ip->get_position->get_component(1), 27 );
$ip->set_position(Language::Befunge::Vector->new(4, 6));
is( $ip->get_position->get_component(0), 4 );
is( $ip->get_position->get_component(1), 6 );
$ip->get_delta->set_component(0,15);
is( $ip->get_delta->get_component(0), 15 );
$ip->get_delta->set_component(1,-4);
is( $ip->get_delta->get_component(1), -4 );
$ip->get_storage->set_component(0, -5 );
is( $ip->get_storage->get_component(0), -5 );
$ip->get_storage->set_component(0, 16 );
is( $ip->get_storage->get_component(0), 16 );
$ip->set_string_mode( 1 );
is( $ip->get_string_mode, 1 );
$ip->set_end( 1 );
is( $ip->get_end, 1 );
$ip->set_data({}); # meaningless, only to test accessors
$ip->set_libs([]); # meaningless, only to test accessors
$ip->set_ss([]);   # meaningless, only to test accessors


#-- stack operations

is( $ip->spop, 0, "empty stack returns a 0" );
is( $ip->spop_gnirts, "", "empty stack returns empty gnirts" );
is( $ip->svalue(5), 0); # empty stack should return a 0.
$ip->spush( 45 );
is( $ip->spop, 45);
$ip->spush( 65, 32, 78, 14, 0, 103, 110, 105, 114, 116, 83 );
is( $ip->svalue(2),  116 );
is( $ip->svalue(-2), 116 );
is( $ip->svalue(1),  83 );
is( $ip->svalue(-1), 83 );
is( $ip->scount, 11 );
is( $ip->spop_gnirts, "String" );
is( $ip->scount, 4 );
$ip->spush_vec(Language::Befunge::Vector->new(4, 5));
is( $ip->scount, 6);
is( $ip->spop, 5 );
is( $ip->spop, 4 );
$ip->spush(18, 74);
my $v = $ip->spop_vec;
is( ref($v), 'Language::Befunge::Vector' );
my ($x, $y) = $v->get_all_components;
is( $x, 18 );
is( $y, 74 );
($x, $y) = $ip->spop_mult(2);
is( $x, 78 );
is( $y, 14 );
$ip->spush_args( "foo", 7, "bar" );
is( $ip->scount, 11 );
is( $ip->spop, 98 );
is( $ip->spop, 97 );
is( $ip->spop, 114 );
is( $ip->spop, 0 );
is( $ip->spop, 7 );
is( $ip->spop_gnirts, "foo" );
$ip->sclear;
is( $ip->scount, 0 );


#-- stack stack

# The following table gives the line number where the
# corresponding test is done.
#
# create = $ip->ss_create
# remove = $ip->ss_remove
# transfer = $ip->ss_transfer
#
# enough means there's enough values in the start stack to perform the
# action. not enough means there's not enough values in the start
# stack to perform the action (filled with zeroes).
#
#                   enough   not enough
# create   (<0)      106         X
# create   (=0)      136         X
# create   (>0)       96        141
# remove   (<0)      121         X
# remove   (=0)      156         X
# remove   (>0)      164        127
# transfer (<0)      161        110
# transfer (=0)      153         X
# transfer (>0)      102        146
$ip->sclear;
$ip->spush( 11, 12, 13, 14, 15, 16, 17, 18, 19 );
is( $ip->scount, 9 );             # toss = (11,12,13,14,15,16,17,18,19)
is( $ip->ss_count, 0 );
$ip->ss_create( 2 );              # create new toss, filled with values (enough).
is( $ip->scount, 2 );             # toss = (18,19)
is( $ip->soss_count, 7 );         # soss = (11,12,13,14,15,16,17)
is( $ip->ss_count, 1 );
is( $ip->spop, 19 );              # toss = (18)
is( $ip->soss_pop, 17 );          # soss = (11,12,13,14,15,16)
$ip->ss_transfer( 2 );            # move elems from soss to toss (enough).
is( $ip->scount, 3 );             # toss = (18,16,15)
is( $ip->soss_count, 4 );         # soss = (11,12,13,14)
is( $ip->spop, 15 );              # toss = (18,16)
$ip->ss_create( -3 );             # create new toss, fill soss with zeroes.
is( $ip->scount, 0 );             # toss = ()
is( $ip->soss_count, 5 );         # soss = (18,16,0,0,0)
is( $ip->ss_count, 2 );
is( join("",$ip->ss_sizes), "054" );
is( $ip->spop, 0 );               # toss = ()
$ip->spush(0, 0);
$ip->ss_transfer( -10 );          # move elems from toss to soss (not enough).
is( $ip->scount, 0 );             # toss = ()
is( $ip->soss_count, 15 );        # soss = (18,17,0,0,0,0,0,0,0,0,0,0,0,0)
$ip->soss_push( 15 );             # soss = (18,17,0,0,0,0,0,0,0,0,0,0,0,0,15)
is( $ip->soss_pop, 15 );          # soss = (18,17,0,0,0,0,0,0,0,0,0,0)
$ip->soss_clear;                  # soss = ()
is( $ip->soss_pop, 0, "soss_pop returns a 0 on empty soss" );
is( $ip->soss_count, 0 );
$ip->spush( 16, 17 );             # toss = (16, 17)
$ip->soss_push( 13, 14, 15, 16 ); # soss = (13,14,15,16)
$ip->ss_remove( -1 );             # destroy toss, remove elems.
is( $ip->ss_count, 1 );
is( $ip->scount, 3 );             # toss = (13,14,15)
is( $ip->spop, 15 );              # toss = (13,14)
is( $ip->spop, 14 );              # toss = (13)
$ip->spush( 14, 15 );
$ip->ss_remove( 5 );              # destroy toss, push values (not enough).
is( $ip->ss_count, 0 );
is( $ip->scount, 9 );             # toss = (11,12,13,14,0,0,13,14,15)
is( $ip->spop, 15 );              # toss = (11,12,13,14,0,0,13,14)
is( $ip->spop, 14 );              # toss = (11,12,13,14,0,0,13)
is( $ip->spop, 13 );              # toss = (11,12,13,14,0,0)
is( $ip->spop, 0 );               # toss = (11,12,13,14,0)
is( $ip->spop, 0 );               # toss = (11,12,13,14)
is( $ip->spop, 14 );              # toss = (11,12,13)
$ip->ss_create( 0 );              # create new toss, no values filled.
is( $ip->scount, 0 );             # toss = ()
is( $ip->soss_count, 3 );         # soss = (11,12,13)
is( $ip->ss_count, 1 );
$ip->spush( 78 );                 # toss = (78)
$ip->ss_create( 3 );              # create new toss, filled with values (not enough).
is( $ip->scount, 3 );             # toss = (0,0,78)
is( $ip->soss_count, 0 );         # soss = ()
is( $ip->ss_count, 2 );
$ip->soss_push( 45 );             # soss = (45)
$ip->ss_transfer( 3 );            # move elems from soss to toss (not enough).
is( $ip->scount, 6 );             # toss = (0,0,78,45,0,0)
is( $ip->soss_count, 0 );         # soss = ()
is( $ip->spop, 0 );               # toss = (0,0,78,45,0)
is( $ip->spop, 0 );               # toss = (0,0,78,45)
is( $ip->spop, 45 );              # toss = (0,0,78)
$ip->soss_push( 12 );             # soss = (12)
$ip->ss_transfer( 0 );            # move 0 elems.
is( $ip->scount, 3 );
is( $ip->soss_count, 1 );
$ip->ss_remove( 0 );              # destroy toss, no values moved.
is( $ip->scount, 1 );             # toss = (12)
is( $ip->soss_count, 3 );         # soss = (11,12,13)
is( $ip->ss_count, 1 );
$ip->spush( 18 );                 # toss = (12,18)
$ip->ss_transfer( -1 );           # move elems from toss to soss (enough).
is( $ip->scount, 1 );             # toss = (12)
is( $ip->soss_count, 4 );         # soss = (11,12,13,18)
$ip->ss_remove( 1 );              # destroy toss, values filled (enough).
is( $ip->scount, 5 );             # toss = (11,12,13,18,12)
is( $ip->ss_count, 0 );
is( $ip->spop, 12 );              # toss = (11,12,13,18)
is( $ip->spop, 18 );              # toss = (11,12,13)
is( $ip->spop, 13 );              # toss = (11,12)
is( $ip->spop, 12 );              # toss = (11)
$ip->ss_create( 0 );              # toss = () soss = (11)
$ip->soss_push_vec( Language::Befunge::Vector->new(34, 48) );
is( $ip->soss_pop, 48 );
is( $ip->soss_pop, 34 );
$ip->soss_push_vec( Language::Befunge::Vector->new(49, 53) );
$v = $ip->soss_pop_vec;
is( ref($v), 'Language::Befunge::Vector' );
is( $v, "(49,53)" );
$ip->ss_remove( -3 );             # destroy toss, remove elems
is( $ip->scount, 0, "ss_remove can clear completely the soss-to-be-toss" );


#-- cardinal directions

$ip->dir_go_east;  is($ip->get_delta->as_string,  '(1,0)', "go_east changes delta");
$ip->dir_go_west;  is($ip->get_delta->as_string, '(-1,0)', "go_west changes delta");
$ip->dir_go_north; is($ip->get_delta->as_string, '(0,-1)', "go_north changes delta");
$ip->dir_go_south; is($ip->get_delta->as_string,  '(0,1)', "go_south changes delta");


#-- random direction

$ip->set_delta( Language::Befunge::Vector->new(3,2) );
my %wanted = ( map {$_=>undef} '(0,1)', '(0,-1)', '(1,0)', '(-1,0)' );
my $iter=0;
while ( keys %wanted ) {
    $iter++;
    $ip->dir_go_away;
    delete $wanted{ $ip->get_delta->as_string };
}
is(keys %wanted, 0, "go_away went north/east/south/west (in $iter iterations)");


#-- turn left

# cardinal directions
$ip->dir_go_east;
$ip->dir_turn_left; is($ip->get_delta->as_string, '(0,-1)', "turn left when going east works");
$ip->dir_turn_left; is($ip->get_delta->as_string, '(-1,0)', "turn left when going north works");
$ip->dir_turn_left; is($ip->get_delta->as_string,  '(0,1)', "turn left when going west works");
$ip->dir_turn_left; is($ip->get_delta->as_string,  '(1,0)', "turn left when going south works");

# non-cardinal delta
$ip->set_delta( Language::Befunge::Vector->new(3,2) );
$ip->dir_turn_left; is($ip->get_delta->as_string,  '(2,-3)', "turn left on non-cardinal delta works/1");
$ip->dir_turn_left; is($ip->get_delta->as_string, '(-3,-2)', "turn left on non-cardinal delta works/2");
$ip->dir_turn_left; is($ip->get_delta->as_string,  '(-2,3)', "turn left on non-cardinal delta works/3");
$ip->dir_turn_left; is($ip->get_delta->as_string,   '(3,2)', "turn left on non-cardinal delta works/4");


#-- turn right

# cardinal directions
$ip->dir_go_east;
$ip->dir_turn_right; is($ip->get_delta->as_string,  '(0,1)', "turn right when going east works");
$ip->dir_turn_right; is($ip->get_delta->as_string, '(-1,0)', "turn right when going south works");
$ip->dir_turn_right; is($ip->get_delta->as_string, '(0,-1)', "turn right when going west works");
$ip->dir_turn_right; is($ip->get_delta->as_string,  '(1,0)', "turn right when going north works");

# non-cardinal delta
$ip->set_delta( Language::Befunge::Vector->new(3,2) );
$ip->dir_turn_right; is($ip->get_delta->as_string,  '(-2,3)', "turn right on non-cardinal delta works/1");
$ip->dir_turn_right; is($ip->get_delta->as_string, '(-3,-2)', "turn right on non-cardinal delta works/2");
$ip->dir_turn_right; is($ip->get_delta->as_string,  '(2,-3)', "turn right on non-cardinal delta works/3");
$ip->dir_turn_right; is($ip->get_delta->as_string,   '(3,2)', "turn right on non-cardinal delta works/4");


#-- reverse

# cardinal directions
$ip->dir_go_east;
$ip->dir_reverse; is($ip->get_delta->as_string, '(-1,0)', "reverse from east works");
$ip->dir_reverse; is($ip->get_delta->as_string,  '(1,0)', "reverse from west works");

# non-cardinal delta
$ip->set_delta( Language::Befunge::Vector->new(2, -3) );
$ip->dir_reverse; is($ip->get_delta->as_string, '(-2,3)', "reverse on non-cardinal works/1");
$ip->dir_reverse; is($ip->get_delta->as_string, '(2,-3)', "reverse on non-cardinal works/2");


#-- cloning
$ip = Language::Befunge::IP->new;
$ip->spush( 1, 5, 6 );
$clone = $ip->clone;
isnt($ip->get_id, $clone->get_id, "clone change the IP unique id");
is($ip->spop,                  6, "clone did not changed the original IP");
is($clone->spop,               6, "clone also cloned the stack");


#-- extension data
$ip->extdata( "HELO", "foobar" );
is($ip->extdata("HELO"), 'foobar', "extdata() restore previously saved data");




