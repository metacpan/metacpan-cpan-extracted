use Test;
BEGIN { plan tests => 3 }

use Event::Lib;
ok(1);

sub time1 {
    my $ev = shift;
    ok(1);
    timer_new(\&time2)->add(10);
    event_one_loop(0.5);
    ok(1);
}

sub time2 {
    my $ev = shift;
    ok(0);
    exit;
}

timer_new(\&time1)->add(0.25);
event_one_loop(5);
