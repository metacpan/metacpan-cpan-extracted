use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

subtest 'parallel inside series' => sub {
    my @order;
    my $finished = 0;
    
    series([
        sub {
            my $done = shift;
            push @order, 'series 1';
            $done->();
        },
        sub {
            my $done = shift;
            push @order, 'series 2 start';
            parallel([
                sub { my $d = shift; push @order, 'parallel 1'; $d->() },
                sub { my $d = shift; push @order, 'parallel 2'; $d->() },
            ], sub {
                push @order, 'series 2 parallel end';
                $done->();
            });
        },
        sub {
            my $done = shift;
            push @order, 'series 3';
            $done->();
        }
    ], sub {
        $finished = 1;
    });
    
    ok($finished, 'Nested parallel inside series finished');
    is($order[0], 'series 1', 'Step 1 ok');
    is($order[1], 'series 2 start', 'Step 2 started');
    # parallel 1 and 2 can be in any order
    my @p_tasks = sort @order[2,3];
    is_deeply(\@p_tasks, ['parallel 1', 'parallel 2'], 'Parallel tasks ran');
    is($order[4], 'series 2 parallel end', 'Parallel callback ran');
    is($order[5], 'series 3', 'Step 3 ran after parallel');
};

subtest 'series inside parallel' => sub {
    my %results;
    my $finished = 0;
    
    parallel([
        sub {
            my $done = shift;
            series([
                sub { my $d = shift; $results{a1} = 1; $d->() },
                sub { my $d = shift; $results{a2} = 1; $d->() },
            ], sub {
                $results{a_end} = 1;
                $done->();
            });
        },
        sub {
            my $done = shift;
            series([
                sub { my $d = shift; $results{b1} = 1; $d->() },
                sub { my $d = shift; $results{b2} = 1; $d->() },
            ], sub {
                $results{b_end} = 1;
                $done->();
            });
        }
    ], sub {
        $finished = 1;
    });
    
    ok($finished, 'Nested series inside parallel finished');
    is_deeply(\%results, {
        a1 => 1, a2 => 1, a_end => 1,
        b1 => 1, b2 => 1, b_end => 1
    }, 'All nested series tasks completed');
};

subtest 'async nested' => sub {
    my @order;
    my $finished = 0;
    our @w;
    
    series([
        sub {
            my $done = shift;
            push @order, 's1';
            push @w, EV::timer 0.01, 0, sub { $done->() };
        },
        sub {
            my $done = shift;
            push @order, 's2';
            parallel([
                sub {
                    my $d = shift;
                    push @w, EV::timer 0.02, 0, sub { push @order, 'p1'; $d->() };
                },
                sub {
                    my $d = shift;
                    push @w, EV::timer 0.01, 0, sub { push @order, 'p2'; $d->() };
                }
            ], sub {
                push @order, 'p_done';
                $done->();
            });
        }
    ], sub {
        push @order, 's_done';
        $finished = 1;
        EV::break;
    });
    
    EV::run;
    
    ok($finished, 'Async nested finished');
    is_deeply(\@order, ['s1', 's2', 'p2', 'p1', 'p_done', 's_done'], 'Async order preserved correctly');
};

subtest 'parallel_limit inside series' => sub {
    my @order;
    my $finished = 0;

    series([
        sub {
            my $done = shift;
            push @order, 's1';
            $done->();
        },
        sub {
            my $done = shift;
            parallel_limit([
                sub { my $d = shift; push @order, 'pl1'; $d->() },
                sub { my $d = shift; push @order, 'pl2'; $d->() },
                sub { my $d = shift; push @order, 'pl3'; $d->() },
            ], 2, sub {
                push @order, 'pl_done';
                $done->();
            });
        },
        sub {
            my $done = shift;
            push @order, 's3';
            $done->();
        }
    ], sub {
        $finished = 1;
    });

    ok($finished, 'parallel_limit inside series finished');
    is($order[0], 's1', 'series step 1 ok');
    is($order[-1], 's3', 'series step 3 ran after parallel_limit');
};

subtest 'deeply nested' => sub {
    my $val = 0;
    series([
        sub {
            my $d1 = shift;
            parallel([
                sub {
                    my $d2 = shift;
                    series([
                        sub { my $d3 = shift; $val += 1; $d3->() },
                        sub { my $d3 = shift; $val += 2; $d3->() },
                    ], sub { $d2->() });
                }
            ], sub { $d1->() });
        }
    ], sub {
        is($val, 3, 'Deeply nested value correct');
    });
};

done_testing;
