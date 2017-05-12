use Test;
BEGIN { plan tests => 9 }

use Event::Lib;
ok(1);

my $tests = 3;

sub time1 {
    my $ev = shift;
    ok(1);
    $tests--;
    timer_new(\&time2)->add(0.5);
}

sub time2 {
    my $ev = shift;
    ok(1);
    $tests--;
    timer_new(\&time3)->add(0.5);
}

sub time3 {
    my $ev = shift;
    ok(1);
    $tests--;
}

timer_new(\&time1)->add(0.5);

while ($tests) {
    event_one_nbloop;
    select undef, undef, undef, 0.05;
}
ok(1);

timer_new(\&time1)->add(0.5);
$tests = 3;
while ($tests) {
    event_one_loop;
}
ok(1);
