# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests=>12;
#use Test::More (no_plan);
use Data::Dumper;
use strict;
BEGIN { use_ok('HTML::WebDAO') }
BEGIN { use_ok('HTML::WebDAO::Store::Abstract') }

#BEGIN { use_ok('HTML::WebDAO::Store::MLDBM') };
BEGIN { use_ok('HTML::WebDAO::Store::Storable') }
BEGIN { use_ok('HTML::WebDAO::Container') }
BEGIN { use_ok('HTML::WebDAO::Engine') }
BEGIN { use_ok('HTML::WebDAO::SessionSH') }

sub test_storage {
    my $object = shift;
    ok( $object, "Create Store " . ref($object) );
    my $ref = { test => 'test' };
    my $id = "ID";
    $object->store( $id, $ref );
    ok( $object->load($id)->{test} eq $ref->{test}, "Test load" );
}
my $store_st = new HTML::WebDAO::Store::Storable:: path => 'tmp';
test_storage($store_st);
my $store_ml = new HTML::WebDAO::Store::MLDBM:: path => 'tmp';
test_storage($store_ml);
my $store_ab = new HTML::WebDAO::Store::Abstract::;
ok( $store_ab, "Create abstract Store" );
my $session = new HTML::WebDAO::SessionSH::;
ok( $session, "Create abstract Store" );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

