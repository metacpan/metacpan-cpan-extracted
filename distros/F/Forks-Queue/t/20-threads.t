use strict;
use warnings;
use Test::More;
use Forks::Queue;
use Time::HiRes;
require "t/exercises.tt";

if (!eval "use threads;1") {
    ok(1, '# skip - threads not available');
    done_testing();
    exit;
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
        sleep 2;
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
        $s = $q->status;
        if ($t - time > 5) {
            die "Took too long for queue to become available";
        }
    }
    ok($t - time < 5,
       'threads: simultaneous queue access from 3 procs not too slow');
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
