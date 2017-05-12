use Test;
BEGIN { plan tests => 5 }

use Event::Lib;
ok(1);
use Data::Dumper;

sub handler {
    my ($ev, $err, $type, @args) = @_;
    ok($err =~ /^exception at/);
    timer_new(sub {
	ok(1);
	exit;
    })->add(0.25);
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
