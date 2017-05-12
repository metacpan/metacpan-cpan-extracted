package MyEvent;
use Event::Lib;
use base qw/Event::Lib::base Event::Lib::timer/;

my $_DESTROY = "not called";

sub new {
    my $class = shift;
    bless Event::Lib::timer_new(shift) => $class;
}

sub DESTROY {
    $_DESTROY = "called";
    shift->SUPER::DESTROY;
}

package main;
use Event::Lib;
use Test;
BEGIN { plan tests => 4; }

MyEvent->new(sub {})->add(0.25);
ok($_DESTROY, "not called");
event_one_loop;
ok($_DESTROY, "called", "Event::Lib::timer::DESTROY called too late");

$_DESTROY = "not called";
MyEvent->new(sub {(shift)->add(1);})->add(0.25);
ok($_DESTROY, "not called");
event_one_loop;
ok($_DESTROY, "not called", "Event::Lib::timer::DESTROY erroneously called");

