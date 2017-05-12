package MyEvent;
use Event::Lib;
use base qw/Event::Lib::signal/;

my $_DESTROY = "not called";

sub new {
    my $class = shift;
    bless signal_new(@_) => $class;
}

sub DESTROY {
    $_DESTROY = "called";
    shift->SUPER::DESTROY;
}

package main;
$^W = 0;

use Event::Lib;
use POSIX qw/SIGHUP/;
use Test;
BEGIN { plan tests => 6; }

my $pid = fork;
if (not defined $pid) {
    skip("couldn't fork: $!", 1) for 1 .. 6;
    exit;
}

if ($pid) {
    # so the child can call event_init()
    sleep 1;
    kill SIGHUP => $pid;
    ok(1);
    wait;
} else {
    event_init;
    MyEvent->new(SIGHUP, sub {})->add;
    ok($_DESTROY, "not called");
    event_one_loop;
    ok($_DESTROY, "not called", "Event::Lib::signal::DESTROY erroneously called");
    exit;
}

$_DESTROY = "not called";

$pid = fork;
skip($!, 2) if not defined $pid;

if ($pid) {
    # so the child can call event_init()
    sleep 1;
    kill SIGHUP => $pid;
    ok(1);
    wait;
} else {
    event_init;
    MyEvent->new(SIGHUP, sub {shift->remove})->add;
    ok($_DESTROY, "not called");
    event_one_loop;
    ok($_DESTROY, "called", "Event::Lib::signal::DESTROY called too late");
    exit;
}
