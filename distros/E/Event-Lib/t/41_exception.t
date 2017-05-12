use Test;
BEGIN { plan tests => 6 }

use Event::Lib;
ok(1);
use Data::Dumper;

sub handler {
    my ($ev, $exc, $type, @args) = @_;
    ok($ev->isa("Event::Lib::timer"));
    ok(@args == 10_000);
    if ($exc =~ /^exception at/) {
	ok(1);
    } else {
	ok(0);
    }
    exit;
}

sub time1 {
    my ($ev, $type, @args) = @_;
    ok(1);
    timer_new(\&time2, @args)->add(0.25);
}

sub time2 {
    my ($ev, $type, @args) = @_;
    ok(1);
    timer_new(\&time3, @args)->add(0.25);
}

sub time3 {
    my ($ev, $type, @args) = @_;
    die "exception";
}

event_register_except_handler(\&handler);
timer_new(\&time1, 1 .. 10_000)->add(0.25);
event_mainloop;
ok(0);
