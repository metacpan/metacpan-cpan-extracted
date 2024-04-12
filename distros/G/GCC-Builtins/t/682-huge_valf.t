#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.05';

use GCC::Builtins qw/:all/;

my $res = huge_valf();
my $expected = "Inf";
if( $expected =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ){
	my $dif = abs($res-$expected);
	ok($dif<1e-09, "called huge_valf() returned ($res) and expected ($expected) values differ ($dif) by less than 1e-09.");
} else {
	is($res, $expected, "called huge_valf() returned ($res) and expected ($expected) values are identical.");
}
diag("copy-this-expected-value 'huge_valf' => '$res',");

done_testing();
