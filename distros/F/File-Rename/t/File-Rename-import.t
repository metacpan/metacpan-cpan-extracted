# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Rename.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('File::Rename', qw(rename) ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# test 2
ok(
	eval q{ rename( ['bing.txt'], 1, 1 ); 1 },	# does nothing  
	'imported - rename' 
);

# test 3
ok(
	!eval q{ CORE::rename( 'bing.txt', 1, 1 ); 1 },	# syntax error
	'CORE::rename() is not rename()'
);

# test 4 
# use File::Rename includes File::Rename::Options
my $ok = eval q{ local @ARGV = (1); File::Rename::Options::GetOptions() };
ok($ok, 'imported - File::Rename::Options::GetOptions' );


