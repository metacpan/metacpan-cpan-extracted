use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

subtest 'series shared callback double-call' => sub {
    my @ran;
    my $finished = 0;
    our @w;
    
    series([
        sub {
            my $done = shift;
            push @ran, 'task1_start';
            push @w, EV::timer 0.01, 0, sub {
                $done->();
                # Double call after a slight delay
                push @w, EV::timer 0.01, 0, sub {
                    $done->();
                };
            };
        },
        sub {
            my $done = shift;
            push @ran, 'task2_start';
            # Task 2 takes longer than the double-call from Task 1
            push @w, EV::timer 0.05, 0, sub {
                push @ran, 'task2_done';
                $done->();
            };
        }
    ], sub {
        push @ran, 'final';
        $finished = 1;
        EV::break;
    });

    EV::run;
    
    is_deeply(\@ran, ['task1_start', 'task2_start', 'task2_done', 'final'], 'Task 2 must complete before final')
        or diag "Actually ran: ", join(", ", @ran);
};

done_testing;
