#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use POSIX qw(_exit);
use File::Spec::Functions;
use Time::HiRes qw(sleep);;

BEGIN {
	if ( File::Spec->isa("File::Spec::Unix") ) {
		plan tests => 2;
	} else {
		plan skip_all => "not running on something UNIXish";
	}
}

use Test::TempDir qw(temp_root);

use ok 'Directory::Transactional';

my $root = temp_root();

{
	my $start = time;

	defined(my $pid = fork) or die $!;

	my $dir = Directory::Transactional->new(
		root    => $root->subdir("flock"),
		timeout => 0.2,
	);

	eval {
		$dir->txn_do(sub {
			sleep 0.1 unless $pid;
			my $first  = $dir->openw( $pid ? "foo" : "bar" );
			sleep 0.3 if $pid;
			my $second = $dir->openw( $pid ? "bar" : "foo" );
		});
	};

	if ( $pid ) {
		waitpid($pid, 0);
	} else {
		_exit(0);
	}

	my $end = time;

	cmp_ok( ($end - $start), "<=", 3, "reasonable time delta" );
}

# FIXME add a test for nfs timeouts... they're flakey though
