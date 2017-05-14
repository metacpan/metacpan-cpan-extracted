#!/usr/bin/perl -w

use strict;

use lib ('.', 't/');
use _validate_kernel;

use Test::More;

use Linux::Fanotify qw(:consts :funcs);
use Fcntl;	# Provides O_* constants required for fanotify_init
use File::Basename qw(basename dirname);
use File::Temp qw(mkdtemp);
use File::Path qw(rmtree);
use Cwd qw(abs_path);
use POSIX qw(ENOSYS EINVAL);

if ($< != 0) {
	plan skip_all => 'no root';
}

my $feat = _fano_features();
if (defined($feat) && (! ($feat & HAS_FANO_PERM))) {
	plan skip_all => 'Kernel does not seem to have fanotify for access permissions enabled.';
}

my $fanogrp = new Linux::Fanotify::FanotifyGroup(FAN_CLOEXEC | FAN_CLASS_CONTENT, O_RDONLY | O_LARGEFILE);

if (!$fanogrp && ! defined($feat) && $! == ENOSYS) {
	plan skip_all => 'Unknown kernel features, and fanotify returned lacking kernel support.';
}

plan tests => 12;

ok($fanogrp, "Have an fd");

my $validfd = $fanogrp && UNIVERSAL::isa($fanogrp, 'Linux::Fanotify::FanotifyGroup');
ok($validfd, "Our fd is a Linux::Fanotify::FanotifyGroup");

SKIP: {
	skip 'Cannot continue without a valid fanofd', 10 unless ($validfd);

	#
	# Prepare a test directory with some test files that can later be marked
	#
	my $path = abs_path(dirname(__FILE__)) . '/testdir';

	mkdir($path);

	my $comm = $path . '/comm';
	my $fn1 = $path . '/allow';
	my $fn2 = $path . '/deny';

	my $fh;
	open($fh, '>', $fn1) || skip('Could not open ' . $fn1, 10); close($fh);
	open($fh, '>', $fn2) || skip('Could not open ' . $fn2, 10); close($fh);

	my $pid = fork();

	skip 'Fork failed, cannot proceed', 10 unless (defined($pid));

	if ($pid == 0) {
		#
		# Let parent mark() the fanotify group first
		#
		sleep(1);


		#
		# Don't risk hanging open/print/close
		#
		alarm(30);

		#
		# child process tries to create two files
		#

		my $fh;
		my $commstr = '';

		if (open($fh, '>', $fn1)) {
			# Should be allowed
			print($fh "Hello world");
			close($fh);
			$commstr .= '1';
		} else {
			$commstr .= '0';
		}

		if (open($fh, '>', $fn2)) {
			# Should be denied
			print($fh "Hello world");
			close($fh);
			$commstr .= '1';
		} else {
			$commstr .= '0';
		}

		if (open($fh, '>', $comm)) {
			# fanotify group should be closed at this time
			print($fh $commstr);
			close($comm);
		}

		exit;
	}

	my $ret = $fanogrp->mark(FAN_MARK_ADD, FAN_OPEN_PERM, -1, $fn1);

	if ((!$ret) && !defined($feat) && $! == EINVAL) {
		skip 'Unknown kernel features, and fanotify_mark returned EINVAL. Assuming lacking CONFIG_FANOTIFY_ACCESS_PERMISSIONS support.', 10;
	}

	ok($ret, 'Successfully fanotify_mark()ed target path ' . $fn1);
	if (!$ret) {
		diag("After failed fanotify_mark, errno is $!\n");
	}

	$ret = $fanogrp->mark(FAN_MARK_ADD, FAN_OPEN_PERM, -1, $fn2);

	ok($ret, 'Successfully fanotify_mark()ed target path ' . $fn2);
	if (!$ret) {
		diag("After failed fanotify_mark, errno is $!\n");
	}

	#
	# Don't risk an idling read()
	#
	alarm(30);

	my $seen = 0;

	while ($seen != 2) {
		my @events = $fanogrp->read(1);
		is(scalar(@events), 1, 'Received exactly one event');

		my $e = $events[0];

		my $fn = readlink('/proc/self/fd/' . $e->fd());

		my $base = basename($fn);

		ok( ($base eq 'allow' || $base eq 'deny'), 'One of the expected files was opened (allow, deny)');

		if ($base eq 'deny') {
			ok($e->needsResponse(), "$base request $e needs a response");
			$e->deny();
			$seen++;
		} else {
			#
			# Also allow any other file names (which we don't expect)
			#
			ok($e->needsResponse(), "$base request $e needs a response");
			$e->allow();
			$seen++;
		}
	}


	waitpid($pid, 0);

	$fanogrp->mark(FAN_MARK_FLUSH);
	# $fanogrp->close();

	ok(open($fh, '<', $comm), 'Successfully opened communication file');

	is(<$fh>, '10', 'Communication file contained expected string');

	# rmtree($path);
}

1;
