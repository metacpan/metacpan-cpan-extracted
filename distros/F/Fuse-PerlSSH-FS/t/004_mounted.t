#!/usr/bin/perl


use Test::More;
use Test::Virtual::Filesystem;


if( !$ENV{PERLSSH_TEST_MOUNTED} ){
	plan tests => 1;

	print STDERR "\n";
	print STDERR "###########################################################################\n";
	print STDERR "# This script performs tests against a live mounted filesystem.           #\n";
	print STDERR "#                                                                         #\n";
	print STDERR "# To enable this test, set the environment variable PERLSSH_TEST_MOUNTED  #\n";
	print STDERR "# to a local path which is a remotely mounted filesys and a subdir        #\n";
	print STDERR "# where it is okay to create a testdir. For example:                      #\n";
	print STDERR "# make test PERLSSH_TEST_MOUNTED=/path/to/mountpoint/emptydir             #\n";
	print STDERR "###########################################################################\n";

	ok( 1, "skipping" );
}else {
	plan tests => Test::Virtual::Filesystem->expected_tests(12);

	die "Test path '$ENV{PERLSSH_TEST_MOUNTED}' is not a dir" if !-d $ENV{PERLSSH_TEST_MOUNTED};

	my $dir = $ENV{PERLSSH_TEST_MOUNTED} .'/test-perlsshfs-'.time();
	print STDERR "Testing in dir '$dir'\n";
	mkdir($dir) or die "Could not make test dir '$dir': $!";

	my $tvf = Test::Virtual::Filesystem->new({ mountdir => $dir });
	$tvf->enable_test_xattr(0);
	$tvf->enable_test_time(1);
	$tvf->enable_test_atime(1);
	$tvf->enable_test_mtime(1);
	$tvf->enable_test_ctime(1);
	$tvf->enable_test_chown(0);
	$tvf->enable_test_permissions(1);
	$tvf->enable_test_special(0);
	$tvf->enable_test_nlink(0);
	$tvf->enable_test_hardlink(1);

	$tvf->runtests;

	## our own breed of xattr tests
	# something in Test::Virtual::Filesystem messes up the xattr functions
	# below tests all fail when run after T::V::F, probably that's why the
	# xattr test above fail as well 
	# plan tests => 12;
	print STDERR "our xattr tests, utf8, on file-path\n";

	# prepare a test-file
	my $file = $dir . '/fuse-perlssh-fs-utf8-test';
	open(my $f, ">", $file) or die "$!";
	print $f '1';
	close($f);

	## let's test if utf8 in the value is handled right
	my $xattr_key = 'perlsshfs.utf8';
	my $xattr_value = 'abc äöü';

	ok(File::ExtAttr::setfattr($file, $xattr_key, $xattr_value, {create => 1}), 'set xattr utf8 value');
	is(File::ExtAttr::getfattr($file, $xattr_key), $xattr_value, 'get xattr utf8 value');

	is(File::ExtAttr::delfattr($file, $xattr_key), 1, 'del xattr utf8 value');
	# Some implementations return undef, some return q{}
	my $get = File::ExtAttr::getfattr($file, $xattr_key);
	ok(!defined $get || q{} eq $get, ' xattr deleted utf8 value');

	unlink $file;

	# prepare a test-file
	$file = $dir . '/fuse-perlssh-fs-utf8-test2';
	open($f, ">", $file) or die "$!";
	print $f '1';
	close($f);

	## let's test if utf8 in the key is handled right
	$xattr_key = 'perlsshfs.utf8_äöü';
	$xattr_value = 'abc';

	ok(File::ExtAttr::setfattr($file, $xattr_key, $xattr_value, {create => 1}), 'set xattr utf8 key');
	is(File::ExtAttr::getfattr($file, $xattr_key), $xattr_value, 'get xattr utf8 key');

	ok(File::ExtAttr::delfattr($file, $xattr_key), 'del xattr utf8 key');
	# Some implementations return undef, some return q{}
	$get = File::ExtAttr::getfattr($file, $xattr_key);
	ok(!defined $get || q{} eq $get, 'xattr deleted utf8 key');

	unlink $f;

	print STDERR "xattr tests, on file-handle\n";

	# prepare a test-file
	$file = $dir . '/fuse-perlssh-fs-utf8-test3';
	open($f, ">", $file) or die "Err: $!";
	print $f '1';
	close($f);

	# ++ below tests on this fh fail
	# open(my $fh, ">", $file) or die "Err: $!";

	# ++ with an IO::File derived fh, it works
	require IO::File;
	$fh = new IO::File;
	$fh->open("> $file");

	$xattr_key = 'perlsshfs.fh-test';
	$xattr_value = 'abc';

	ok(File::ExtAttr::setfattr($fh, $xattr_key, $xattr_value, {create => 1}), 'set xattr on filehandle');
	is(File::ExtAttr::getfattr($fh, $xattr_key), $xattr_value, 'get xattr on filehandle');

	ok(File::ExtAttr::delfattr($fh, $xattr_key), 'del xattr on filehandle');
	# Some implementations return undef, some return q{}
	$get = File::ExtAttr::getfattr($fh, $xattr_key);
	ok(!defined $get || q{} eq $get, 'xattr deleted on filehandle');

	unlink $fh;
}
