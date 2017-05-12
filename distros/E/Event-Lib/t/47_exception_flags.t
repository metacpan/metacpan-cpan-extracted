# Test an event_add failure and the
# flags passed to the exception handler

use Test;
BEGIN { plan tests => 6 }

my $PATH = "t/foobar";

use Event::Lib;

sub handler {
    my ($ev, $exc, $type, @args) = @_;
    ok($ev->isa("Event::Lib::event"));
    ok($exc =~ /^Couldn't add event/);
    ok($type, -(EV_READ|EV_WRITE|EV_PERSIST));
    ok(shift @args, $_) for 1 .. 3;
}

open F, "+>", $PATH or die "Cannot create $PATH: $!";
my $e = event_new(\*F, EV_READ|EV_WRITE|EV_PERSIST, sub { ok(0) }, 1 .. 3);
$e->except_handler(\&handler);
close F;
$e->add;
event_mainloop;
unlink $PATH;
