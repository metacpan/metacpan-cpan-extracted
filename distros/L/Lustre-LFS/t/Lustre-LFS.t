# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lustre-LFS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Lustre::LFS::File'); use_ok('Lustre::LFS::Dir') };



my $lfs_obj = Lustre::LFS::File->new;
ok( defined($lfs_obj), 'lfs-file object creation' );

my $tmpx = $lfs_obj->new_tmpfile;
ok( $tmpx, 'lfs-file temp' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

