# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
use_ok('IO::File::Lockable');
IO_File_flock: {
	use_ok('IO::File::flock');
	my $fh;
	ok( $fh = new IO::File::flock('test','>>','lock_un')	,'flock:create object');
	ok( $fh->lock_ex	,'flock: lock_ex');
	ok( $fh->lock_sh	,'flock: lock_sh');
	ok( $fh->lock_un	,'flock: lock_un');
};
IO_File_fcntl: {
	use_ok('IO::File::fcntl');
	my $fh;
	ok( $fh = new IO::File::flock('test','>>','lock_un')	,'fcntl: create object');
	ok( $fh->lock_ex	,'fcntl: lock_ex');
	ok( $fh->lock_sh	,'fcntl: lock_sh');
	ok( $fh->lock_un	,'fcntl: lock_un');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

