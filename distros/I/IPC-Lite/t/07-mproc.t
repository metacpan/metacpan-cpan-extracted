use strict;
use warnings;
use Test::Simple tests=>2;

# not terribly thorough test of parent/child forking

BEGIN {
	(-d 'tmp') || mkdir('tmp') || die;
	eval {
		require Time::HiRes;
		Time::HiRes->import(qw(sleep));
	};
}

# set default path (set for this package only)
use IPC::Lite Path=>'tmp/test.db';

# bind style 1 (shared table, implicit use vars)
use IPC::Lite qw(@m $x @ok);

@m = ();
@ok = ();
$x = undef;

my $pid = fork;

if ($pid) {
	push @m, 'parent';
	$x = 5;
	wait;
	ok( $ok[0] eq 5, "ok 0 is 5");
	ok( $ok[1] eq "parent;child", "ok 1 is parent;child");
} else {
	# wait for parent to set $x
	while (! defined $x ) {
		sleep 0.01;
	}
	push @m, 'child';
	push @ok, $x;
	push @ok, join(';', @m);
}
