use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer)) {
    eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

local $SIG{ALRM} = sub { die "timeout\n" };
alarm 5;

my $loop = Linux::Event::Loop->new( model => 'reactor', backend => 'epoll' );

subtest "close-safety + fd reuse: old watcher must not fire on reused fd" => sub {
    pipe(my $r1, my $w1) or die "pipe failed: $!";

    my $fd1 = fileno($r1);
    ok(defined $fd1, "got original fd");

    my $called = 0;

    # Watch then close without unwatching (the footgun case)
    $loop->watch($r1,
                 read => sub ($loop, $fh, $w) {
                     $called++;
                 },
    );

    close $r1;

    # Try to create a new pipe whose read end reuses the same fd.
    my ($r2, $w2);
    my $tries = 0;
    my $max   = 5000;
    my $got_reuse = 0;

    while ($tries++ < $max) {
        pipe(my $rr, my $ww) or die "pipe failed: $!";
        my $fd = fileno($rr);

        if (defined $fd && $fd == $fd1) {
            ($r2, $w2) = ($rr, $ww);
            $got_reuse = 1;
            last;
        }

        # Not reused; close and keep trying
        close $rr;
        close $ww;
    }

    if (!$got_reuse) {
        plan skip_all => "could not force fd reuse of $fd1 in $max attempts (this is normal)";
    }

    ok($got_reuse, "forced fd reuse: new read fd == old fd ($fd1)");

    # If the loop still had the old watcher keyed by fd, this write could
    # accidentally invoke it. Our M1 contract says it must not.
    $loop->after(0.02, sub ($loop) {
        local $SIG{PIPE} = 'IGNORE';
    syswrite($w2, "x");
    });

    $loop->after(0.08, sub ($loop) { $loop->stop });

    $loop->run;

    is($called, 0, "old watcher did not fire after fd reuse");
};

done_testing;
alarm 0;
