use Test;
BEGIN { plan tests => 4 }

use Event::Lib;
ok(1);
use Data::Dumper;

{
    package E;
    sub new {
	my $class=shift;
	bless {@_}=>$class;
    }
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
    die E->new(msg=>"exception");
}

timer_new(\&time1, 1 .. 10_000)->add(0.25);
eval {
    event_mainloop;
};
if ($@->{msg} eq 'exception') {
    ok(1);
}
else {
    ok(0);
}
