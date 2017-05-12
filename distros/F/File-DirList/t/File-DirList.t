# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-DirList.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('File::DirList') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $homeDir = ( "\L$^O" =~ m/win32/ ) ? '.' : glob('~');
print STDERR ("\nListing your home dir '$homeDir' for test purposes\n");
foreach my $item (@{File::DirList::list($homeDir, 'din', "\L$^O" =~ m/win32/ ? 1 : 0, 1, 1)})
	{ print STDERR (sprintf("%s'%s'%s\n", ($item->[14] ? 'dir  ' : 'file '), $item->[13], (!$item->[15] ? '' : ($item->[15] < 0 ? ' bad' : '').' link to \''.$item->[16].'\''))); };
ok("listing completed");
