#! /usr/bin/perl
use strict;
use warnings;
use IO::Lambda qw(:all);
use Linux::Inotify2;
use IO::Lambda::Inotify qw(inotify);
use Test::More tests => 4;

END { rmdir $$; }
alarm(10);

my $inotify = Linux::Inotify2-> new;


######################################################

mkdir $$;
my $ok = 0;
lambda {
	context 0.01;
	timeout { rmdir $$ };
	context inotify($inotify, $$, IN_ALL_EVENTS, 1.0);
	tail { $ok++ }
}-> wait;

rmdir $$;
ok( $ok, 'normal');

######################################################

mkdir $$;
$ok = 0;
lambda {
	context inotify($inotify, $$, IN_ALL_EVENTS, 0.01);
	tail {
		$ok++ if !$_[0] and $_[1] eq 'timeout';
	}
}-> wait;

rmdir $$;
ok( $ok, 'timed-out');

######################################################

mkdir $$;
$ok = 0;
lambda {
	context 0.001;
	timeout { rmdir $$ };

	my $watch = inotify($inotify, $$, IN_ALL_EVENTS, 1.0);
	context $watch;
	tail {
		my $event = shift;
		context 0.001;
		timeout { $event-> w-> cancel }; # evil!!

		context $watch;
		tail { $ok = -1 } # should never execute

	};

	context 0.2;
	timeout {
		this-> terminate;
		$ok = 1;
	}
}-> wait;

rmdir $$;
ok( $ok == 1, "evil cancel ($ok)");

######################################################

mkdir $$;
my $watcher;
lambda {
	context 0.001;
	timeout { rmdir $$ };

	context inotify($inotify, $$, IN_ALL_EVENTS);
	tail { $watcher = shift-> w };
}-> wait;
rmdir $$;
IO::Lambda-> clear; # so inotify() result is not cached in the context 

ok((defined($watcher) and not(defined $watcher->{inotify})), "proper cancel");


######################################################
