# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-Distribution.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use Linux::Distribution::Packages;

my $linux=new Linux::Distribution::Packages();

ok( defined($linux) ,     'new() works 1' );
like( ref $linux, qr/^Linux::Distribution::Packages.*/,     'new() works 2' );
ok( $linux->distribution_write(),     'distribution_write() works'    );

