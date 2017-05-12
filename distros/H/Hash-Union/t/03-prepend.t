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
	'+= k1' => 2,
	'prepend: k2' => 2,
	'+= k3' => [2],
	'+= k4' => [2],
	'prepend: k5' => [2],
	'prepend: k6' => [2],
	'+= k7' => {a=>2},
	'prepend: k8' => {a=>2},
};
my $r = union([$h1, $h2]);

ok( $r->{k1}==21,   '1st test of prepend' );
ok( $r->{k2}==21,   '2nd test of prepend' );
ok( $r->{k3}[0]==2, '3nd test of prepend' );
ok( $r->{k4}[1]==1, '4nd test of prepend' );
ok( $r->{k5}[0]==2, '5nd test of prepend' );
ok( $r->{k6}[1]==1, '6nd test of prepend' );
ok( $r->{k7}{a}==1, '7nd test of prepend' );
ok( $r->{k8}{a}==1, '8nd test of prepend' );

