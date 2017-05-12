#! /usr/bin/perl
use strict;
use warnings;
use IO::Lambda qw(:all);
use Linux::Inotify2;
use IO::Lambda::Inotify qw(inotify_server);
use IO::Lambda::Mutex qw(:all);
use Test::More tests => 1;

END { rmdir $$; }
alarm(10);

my $inotify = Linux::Inotify2-> new;

my $mutex = IO::Lambda::Mutex-> new;
$mutex-> take;

my $server = inotify_server($inotify);
$server-> start; # <-- comment and observe TEH FAIL!

mkdir $$;
my $ok = 0;
$inotify-> watch( $$, IN_ALL_EVENTS, sub { 
	$mutex-> release;
	$ok = 1;
});

rmdir $$;
$mutex-> waiter(1.0)-> wait;
ok( $ok, "watcher ok");
