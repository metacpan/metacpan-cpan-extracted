# Test that adding an event with a filehandle that has been closed
# behaves sanely. It should not segfault and $! should be EBADF.
# Also, don't forget to pass the additional arguments!!

use Test;
BEGIN { plan tests => 5 }

use Event::Lib;
use Errno;

sub except_handler {
    my ($ev, $err, $evtype, @args) = @_;
    ok($!{EBADF});
    ok($err =~ /^Couldn't add event/);
    ok(shift @args, $_) for qw/1 2 3/;
}

event_register_except_handler(\&except_handler);

open FH, "<", $0 or die $!;

my $e = event_new(\*FH, EV_READ, sub { ok(0) }, qw/1 2 3/);
close FH;
$e->add;

event_mainloop;

