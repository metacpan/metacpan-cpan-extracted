#! /usr/bin/perl
use strict;
use warnings;
use IO::Lambda qw(:all);
use Linux::Inotify2;
use IO::Lambda::Inotify qw(inotify);
use Test::More tests => 2;

END { rmdir $$; }
alarm(10);

mkdir $$;
my $ok = 0;
lambda {
	context 0.01;
	timeout { rmdir $$ };
	context inotify($$, IN_ALL_EVENTS, 1.0);
	tail { $ok++ }
}-> wait;

rmdir $$;
ok( $ok, 'normal');

mkdir $$;
$ok = 0;
lambda {
	context inotify($$, IN_ALL_EVENTS, 0.01);
	tail {
		$ok++ if !$_[0] and $_[1] eq 'timeout';
	}
}-> wait;

rmdir $$;
ok( $ok, 'timed-out');
