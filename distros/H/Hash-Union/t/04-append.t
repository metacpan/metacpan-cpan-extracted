#!perl -T

use Test::Simple tests => 8;
use Hash::Union qw'union';

my $h1 = {
	k1 => 1,
	k2 => 1,
	k3 => [1],
	k4 => [1],
	k5 => [1],
	k6 => [1],
	k7 => {a=>1},
	k8 => {a=>1},
};
my $h2 = {
	'=+ k1' => 2,
	'append: k2' => 2,
	'=+ k3' => [2],
	'=+ k4' => [2],
	'append: k5' => [2],
	'append: k6' => [2],
	'=+ k7' => {a=>2},
	'append: k8' => {a=>2},
};
my $r = union([$h1, $h2]);

ok( $r->{k1}==12,   '1st test of append' );
ok( $r->{k2}==12,   '2nd test of append' );
ok( $r->{k3}[0]==1, '3nd test of append' );
ok( $r->{k4}[1]==2, '4nd test of append' );
ok( $r->{k5}[0]==1, '5nd test of append' );
ok( $r->{k6}[1]==2, '6nd test of append' );
ok( $r->{k7}{a}==2, '7nd test of append' );
ok( $r->{k8}{a}==2, '8nd test of append' );

