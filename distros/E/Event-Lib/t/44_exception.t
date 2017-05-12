use Test;
BEGIN { plan tests => 8 }

use Event::Lib;
ok(1);
use Data::Dumper;

# here test how an exception handler performs an async call which
# again triggers the exception handler

my $i = 0;	
sub handler {
    my ($ev, $err, $type, @args) = @_;
    ok($err =~ /^exception at/);
    my $next = $i < 3 ? \&exception : \&finish;
    timer_new($next, 1)->add(0.25);
}

sub exception {
    my ($ev, $type, @args) = @_;
    $i++;
    ok(1);
    die "exception" if $i < 4;
    ok(1);
}

sub finish {
    ok(1);
    exit;
}

event_register_except_handler(\&handler);
timer_new(\&exception, 1)->add(0.25);
event_mainloop;
ok(0);
