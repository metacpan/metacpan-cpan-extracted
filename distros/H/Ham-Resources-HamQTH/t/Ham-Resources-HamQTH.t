# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ham-Resources-HamQTH.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Ham::Resources::HamQTH') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

diag( "Testing Ham::Resources::HamQTH $Ham::Resources::HamQTH::VERSION, Perl $], $^X" );
my $HamQTH = Ham::Resources::HamQTH->new; 				# create a new object
ok (	defined $HamQTH											, 'new() creation'	);
ok (	$HamQTH->isa('Ham::Resources::HamQTH')				, 'Right class returned'	);
