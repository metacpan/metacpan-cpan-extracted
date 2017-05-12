# Test that re-adding an event from inside its handler
# doesn't constantly increment its reference-count thus
# causing a leak. 

package MyEvent;
use Event::Lib;
use base qw/Event::Lib::timer/;

my $_DESTROY = "not called";

sub new {
    my $class = shift;
    bless timer_new(@_) => $class;
}

sub DESTROY {
    $_DESTROY = "called";
    shift->SUPER::DESTROY;
}

package main;

use Test;
BEGIN { plan tests => 6; }

use constant COUNT	=> 5;
use constant TIMEOUT	=> 0.3;

sub handler {
    $_[2]--;	# $count-- by alias
    my ($ev, undef, $count) = @_;
    ok(1);
    $ev->add(TIMEOUT) if $count;
}

{
    MyEvent->new(\&handler, my $c = COUNT)->add(TIMEOUT);
    Event::Lib::event_mainloop;
}

ok($_DESTROY, "called");
