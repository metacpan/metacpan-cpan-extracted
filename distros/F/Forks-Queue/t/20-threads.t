use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

if (!eval "use threads;1") {
    ok(1, '# skip - threads not available');
    done_testing();
    exit;
}

sub uninterruptable_sleep ($) {
    # SIGIO can interrupt CORE::sleep and Time::HiRes::sleep,
    # and sometimes we don't want that
    my $expire = Time::HiRes::time + $_[0];
    my $n = $_[0];
    while ($n > 0) {
        Time::HiRes::sleep $n;
        $n = $expire - Time::HiRes::time;
    }
    return $_[0];
}

for my $impl (IMPL()) {
    my $q = Forks::Queue->new( impl => $impl );

    my $kidthd = threads->create( sub {
        my $gkidthd = threads->create( sub {
            for my $i (0 .. 9) {
                eval { $q->put( +{ item => "grandchild$i" } ) };
                print STDERR $@ if $@;
            }
            return;
                                       } );
        for my $i (0 .. 9) {
            eval { $q->put("child$i") };
            print STDERR $@ if $@;
        }
        $gkidthd->join;
        uninterruptable_sleep 5;
        uninterruptable_sleep 5 if $^O =~ /freebsd/;
        $q->end;
        return;
    } );

    for my $i (0..9) {
        $q->put("parent$i");
    }

    my $s = $q->status;
    my $t = time;
    until ($s->{end}) {
        sleep 1;
        if (time - $t > 20) {
            diag "exercise_forks: ",
                "Taking too long for queue to become availabile";
            $q->end;
        }
        $s = $q->status;
        if (time - $t > 30) {
            die "Took too long for queue to become available";
        }
    }
    my $proctime = Time::HiRes::time - $t;
    if ($^O !~ /freebsd/) {
        ok($proctime < 10,
           'threads: simultaneous queue access from 3 procs not too slow'
           . " ($proctime s)");
    }
    is($q->pending, 30, 'threads: 30 items on queue');
    my @g = $q->get(30);
    is(scalar @g, 30, 'threads: get(30) retrieved 30 items from queue');

    my %expect;
    for my $i (0 .. 9) {
        $expect{"parent$i"} = $expect{"child$i"} =
            $expect{"grandchild$i"} = 1;
    }

    foreach my $g (@g) {
        if (ref($g)) {
            $g = $g->{item};
        }
        ok(delete $expect{$g}, "threads: found expected item $g");
    }
    ok(0 == keys %expect, "threads: all expected items removed from queue");
    $kidthd->join;
}

done_testing();
