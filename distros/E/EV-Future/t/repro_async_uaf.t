use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

subtest 'async uaf parallel_cleanup' => sub {
    my $finished = 0;
    our @w;
    our @junk;
    
    parallel([
        sub {
            my $done = shift;
            push @w, EV::timer 0.01, 0, sub {
                $done->();
                undef $done; # explicitly drop
                # allocate a ton of CVs to reuse the slot
                for (1..10000) {
                    push @junk, sub { $_ };
                }
            };
        },
        sub {
            my $done = shift;
            push @w, EV::timer 0.05, 0, sub {
                $done->();
            };
        }
    ], sub {
        $finished = 1;
        EV::break;
    });

    EV::run;
    ok($finished, "survived parallel_cleanup after one CV was freed");
};

done_testing;
