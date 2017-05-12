#!perl -T

use Test::Simple tests => 6;
use Hash::Union qw'union';

my $h1 = {
	k1     => 1,
	k2     => 1,
	k3     => 1,
	'= k5' => 1,
	'set: k6' => 1,
};
my $h2 = {
	k1        => 2,
	'= k2'    => 2,
	'set: k3' => 2,
	'set: k4' => 2,
};
my $r = union([$h1, $h2]);

ok( $r->{k1}==2, '1st test of set' );
ok( $r->{k2}==2, '2nd test of set' );
ok( $r->{k3}==2, '3rd test of set' );
ok( $r->{k4}==2, '4th test of set' );
ok( $r->{k5}==1, '5th test of set' );
ok( $r->{k6}==1, '6th test of set' );

