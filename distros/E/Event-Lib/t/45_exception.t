use Test;
BEGIN { plan tests => 5 }

use Event::Lib;
ok(1);
use Data::Dumper;

sub handler {
    my ($ev, $err, $type, @args) = @_;

    ok($err =~ /^exception at/);

    # a reminder to exception handler writers, any non async-calls
    # need to be enclosed in eval {}, since if they fail Event::Lib
    # won't trap those and the app will die
    eval { exception() };
    if ($@ && $@ =~ /exception/) {
        ok(1);
        exit;
    }
}

sub exception {
    my ($ev, $type, @args) = @_;
    ok(1);
    die "exception";
}

event_register_except_handler(\&handler);
timer_new(\&exception, 1)->add(0.25);
event_mainloop;
ok(0);
