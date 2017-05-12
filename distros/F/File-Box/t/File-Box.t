# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Box.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);

BEGIN 
{ 
	use_ok('File::Box');
	use_ok('IO::Extended', ':all' );
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $box = File::Box->new( env => { SOURCE => '/home/path/src' } );

println $box->path_home;

ok( $box );

println $box->path_local;

ok( $box );

println $box->request( 'bla.txt' );

ok( $box );

println $box->request( 'bla.txt', '__HOME' );

ok( $box );

println $box->request( 'bla.txt', '__LOCAL' );

ok( $box );

println $box->request( 'bla.txt', 'STUPID' );

ok( $box );

println $box->request( 'bla.txt', '__SOURCE' );

ok( $box );

println "Provocate carp now: Ignore dubious !";

println $box->request( 'bla.txt', '__UNKNOWN' );

ok( $box );
