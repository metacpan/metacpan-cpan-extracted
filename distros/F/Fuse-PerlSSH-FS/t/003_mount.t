#!/usr/bin/perl

use Test::More tests => 1;
use threads;
use Fuse::PerlSSH::FS;


SKIP: {
	skip("Programmatic mounting is todo", 1);

	my $testdir = '/tmp/fuse-perlssh-test-'. time();
	mkdir($testdir);

	## test mount
	my $fpfs = Fuse::PerlSSH::FS->new(
		mountpoint => $testdir,
		host => $ENV{PERLSSH_HOST},
		port => $ENV{PERLSSH_PORT} || 22,
		user => $ENV{PERLSSH_USER},
		root => $ENV{PERLSSH_ROOT},
	);

	# ok(-e $testdir, "mount testdir created");

	my $thr = threads->create(sub { $fpfs->mount(); });

	sleep(5);
	# ok(-e $testdir.'/somefile', "mount testdir created");

	## test umount
	use POSIX qw(WEXITSTATUS);
	system("fusermount -u $testdir");
	if(POSIX::WEXITSTATUS($?) != 0) {
		system("umount $testdir");
	}
	ok(POSIX::WEXITSTATUS($?) == 0,"unmount");

	## garbage collect
	unlink($testdir);
};
