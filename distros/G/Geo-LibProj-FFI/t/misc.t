#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Various
# https://proj.org/development/reference/functions.html#various

plan tests => 3 + 1;

use Geo::LibProj::FFI qw( :all );


my ($a, $b, $c, $d, $v, $union);


# proj_coord

($a, $b, $c, $d) = (12.5, -34.5, 67.5, -89.5);
lives_and { ok $union = proj_coord($a, $b, $c, $d) } 'coord';
lives_and { $v = 0; ok $v = $union->v } 'v';
SKIP: { skip "(v failed)", 1 unless $v;
	is_deeply $v, [$a, $b, $c, $d], 'v array';
}

# proj_roundtrip

# proj_factors

# proj_torad

# proj_todeg

# proj_dmstor

# proj_rtodms

# proj_angular_input

# proj_angular_output

# proj_degree_input

# proj_degree_output


done_testing;
