#!perl -T

use Test::Simple tests => 6;
use Hash::Union qw'union';

my $h1 = {
	'?= k1' => 1,
	'ifnone: k2' => 1,
	'k3' => 1,
	'k4' => 1,
};
my $h2 = {
	'?= k3' => 2,
	'ifnone: k3' => 2,
	'?= k5' => 2,
	'ifnone: k6' => 2,
};
my $r = union([$h1, $h2]);

ok( $r->{k1}==1, '1st form of setif' );
ok( $r->{k2}==1, '2nd form of setif' );
ok( $r->{k3}==1, '3nd form of setif' );
ok( $r->{k4}==1, '4nd form of setif' );
ok( $r->{k5}==2, '5nd form of setif' );
ok( $r->{k6}==2, '6nd form of setif' );

