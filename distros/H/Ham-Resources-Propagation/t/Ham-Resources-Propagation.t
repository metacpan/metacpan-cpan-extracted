# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ham-Resources-Propagation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Ham::Resources::Propagation') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

diag( "Testing Ham::Resources::Propagation $Ham::Resources::Propagation::VERSION, Perl $], $^X" );
my $propagation = Ham::Resources::Propagation->new; 				# create a new object
ok (	defined $propagation													, 'new() creation'	);
ok (	$propagation->isa('Ham::Resources::Propagation')			, 'Right class returned'	);
ok (	$propagation->get('*')												, 'get()'	);
ok	(	$propagation->all_item_names										, 'all_item_names'	);
like ( 	$propagation->get('updated'), qr/\d+/						, 'Received datas'	);
