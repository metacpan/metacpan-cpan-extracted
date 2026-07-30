use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use EV;
use EV::Future;

subtest 'parallel_map passes each item to the worker' => sub {
    my @seen;
    my $final = 0;
    parallel_map([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @seen, $item;
        $done->();
    }, sub { $final++ });

    is_deeply([sort @seen], [qw(a b c)], 'worker saw every item');
    is($final, 1, 'final_cb fired once');
};

subtest 'parallel_map worker gets item first, done second' => sub {
    my ($got_item, $got_done);
    parallel_map(['only'], sub {
        ($got_item, $got_done) = @_;
        $got_done->();
    }, sub { });

    is($got_item, 'only', 'first argument is the item');
    is(ref($got_done), 'CODE', 'second argument is the done callback');
};

subtest 'parallel_map treats non-coderef items as data' => sub {
    my @seen;
    my $final = 0;
    parallel_map([1, undef, 'x'], sub {
        my ($item, $done) = @_;
        push @seen, defined $item ? $item : '(undef)';
        $done->();
    }, sub { $final++ });

    is(scalar @seen, 3, 'all three items dispatched, none skipped as no-ops');
    is($final, 1, 'final_cb fired once');
};

# The one rule that separates the map form from the task form: items are data
# even when they happen to be code references. Every other map subtest uses
# plain scalars for items, so they all survive a dispatch selector inverted
# from "call the worker" to "call the item if it is a coderef, else the
# worker" - which is exactly the regression this pins, in all three map
# primitives at once.
subtest 'map primitives pass a coderef item to the worker as data' => sub {
    my $invoked = 0;
    my $item = sub { $invoked++ };

    my @cases = (
        [ 'parallel_map',       sub { parallel_map([$item], $_[0], $_[1]) } ],
        [ 'parallel_map_limit', sub { parallel_map_limit([$item], $_[0], 1, $_[1]) } ],
        [ 'series_map',         sub { series_map([$item], $_[0], $_[1]) } ],
    );

    for my $case (@cases) {
        my ($name, $start) = @$case;
        my ($calls, $final, $got) = (0, 0, undef);
        $invoked = 0;

        $start->(sub {
            my ($i, $done) = @_;
            $calls++;
            $got = $i;
            $done->();
        }, sub { $final++ });

        is($calls, 1, "$name dispatched the worker once");
        is(refaddr($got), refaddr($item), "$name handed the coderef to the worker as \$_[0]");
        is($invoked, 0, "$name did not invoke the coderef item as a task");
        is($final, 1, "$name fired final_cb once");
    }
};

subtest 'parallel_map croaks on a non-coderef worker' => sub {
    eval { parallel_map([1, 2], 'not a coderef', sub { }) };
    like($@, qr/worker must be a code reference/, 'croaks before dispatch');
};

subtest 'parallel_map with an empty list fires final_cb immediately' => sub {
    my $final = 0;
    parallel_map([], sub { die 'never called' }, sub { $final++ });
    is($final, 1, 'final_cb fired');
};

subtest 'parallel_map async' => sub {
    our @w;
    my @seen;
    my $final = 0;
    parallel_map([qw(x y z)], sub {
        my ($item, $done) = @_;
        push @w, EV::timer 0.01, 0, sub { push @seen, $item; $done->() };
    }, sub { $final++; EV::break });

    EV::run;
    is(scalar @seen, 3, 'all async items completed');
    is($final, 1, 'final_cb fired once');
    @w = ();
};

subtest 'parallel_map unsafe mode' => sub {
    my @seen;
    my @dones;
    my $final = 0;
    parallel_map([qw(a b)], sub {
        my ($item, $done) = @_;
        push @seen, $item;
        push @dones, $done;
        $done->();
    }, sub { $final++ }, 1);

    is(scalar @seen, 2, 'unsafe mode dispatched both items');
    is($final, 1, 'final_cb fired once');
    is(refaddr($dones[0]), refaddr($dones[1]),
        'unsafe mode hands every item the same done coderef');
};

subtest 'parallel_map safe mode gives each item its own done coderef' => sub {
    my @dones;
    parallel_map([qw(a b)], sub {
        my ($item, $done) = @_;
        push @dones, $done;
        $done->();
    }, sub { });

    isnt(refaddr($dones[0]), refaddr($dones[1]),
        'safe mode hands each item a distinct done coderef');
};

subtest 'parallel_map with a holey array passes undef' => sub {
    my $list = [];
    $list->[2] = 'third';
    my @seen;
    parallel_map($list, sub {
        my ($item, $done) = @_;
        push @seen, defined $item ? $item : '(undef)';
        $done->();
    }, sub { });

    is_deeply(\@seen, ['(undef)', '(undef)', 'third'], 'holes arrive as undef');
};

subtest 'parallel_map_limit respects the limit' => sub {
    our @w;
    my ($active, $max_active, $final) = (0, 0, 0);
    my @seen;

    parallel_map_limit([1 .. 6], sub {
        my ($item, $done) = @_;
        $active++;
        $max_active = $active if $active > $max_active;
        push @w, EV::timer 0.01, 0, sub {
            push @seen, $item;
            $active--;
            $done->();
        };
    }, 2, sub { $final++; EV::break });

    EV::run;
    is(scalar @seen, 6, 'all six items completed');
    cmp_ok($max_active, '<=', 2, 'never more than 2 in flight');
    is($final, 1, 'final_cb fired once');
    @w = ();
};

subtest 'parallel_map_limit croaks on a non-coderef worker' => sub {
    eval { parallel_map_limit([1, 2], undef, 2, sub { }) };
    like($@, qr/worker must be a code reference/, 'croaks before dispatch');
};

subtest 'parallel_map_limit unsafe mode' => sub {
    my @seen;
    my @dones;
    my $final = 0;
    parallel_map_limit([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @seen, $item;
        push @dones, $done;
        $done->();
    }, 2, sub { $final++ }, 1);

    is(scalar @seen, 3, 'unsafe mode dispatched every item');
    is($final, 1, 'final_cb fired once');
    is(refaddr($dones[0]), refaddr($dones[1]),
        'unsafe mode hands the first two items the same done coderef');
    is(refaddr($dones[1]), refaddr($dones[2]),
        'unsafe mode hands the last two items the same done coderef');
};

subtest 'parallel_map_limit safe mode gives each item its own done coderef' => sub {
    my @dones;
    parallel_map_limit([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @dones, $done;
        $done->();
    }, 2, sub { });

    isnt(refaddr($dones[0]), refaddr($dones[1]),
        'safe mode hands the first two items distinct done coderefs');
    isnt(refaddr($dones[1]), refaddr($dones[2]),
        'safe mode hands the last two items distinct done coderefs');
};

subtest 'series_map runs items in order' => sub {
    my @seen;
    my $final = 0;
    series_map([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @seen, $item;
        $done->();
    }, sub { $final++ });

    is_deeply(\@seen, [qw(a b c)], 'items ran in order');
    is($final, 1, 'final_cb fired once');
};

subtest 'series_map async keeps order' => sub {
    our @w;
    my @seen;
    my $final = 0;
    series_map([1, 2, 3], sub {
        my ($item, $done) = @_;
        push @w, EV::timer 0.01, 0, sub { push @seen, $item; $done->() };
    }, sub { $final++; EV::break });

    EV::run;
    is_deeply(\@seen, [1, 2, 3], 'async items still ran in order');
    is($final, 1, 'final_cb fired once');
    @w = ();
};

subtest 'series_map cancellation via truthy done' => sub {
    my @seen;
    my $final = 0;
    series_map([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @seen, $item;
        $done->($item eq 'a' ? 1 : 0);
    }, sub { $final++ });

    is_deeply(\@seen, ['a'], 'truthy done skipped the rest');
    is($final, 1, 'final_cb still fired');
};

subtest 'series_map unsafe mode' => sub {
    my @seen;
    my @dones;
    my $final = 0;
    series_map([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @seen, $item;
        push @dones, $done;
        $done->();
    }, sub { $final++ }, 1);

    is(scalar @seen, 3, 'unsafe mode dispatched every item');
    is(scalar @dones, 3, 'captured a done ref for every item');
    is($final, 1, 'final_cb fired once');
    is(refaddr($dones[0]), refaddr($dones[1]),
        'unsafe mode hands the first two items the same done coderef');
    is(refaddr($dones[1]), refaddr($dones[2]),
        'unsafe mode hands the last two items the same done coderef');
};

subtest 'series_map safe mode gives each item its own done coderef' => sub {
    my @dones;
    series_map([qw(a b c)], sub {
        my ($item, $done) = @_;
        push @dones, $done;
        $done->();
    }, sub { });

    is(scalar @dones, 3, 'captured a done ref for every item');
    isnt(refaddr($dones[0]), refaddr($dones[1]),
        'safe mode hands the first two items distinct done coderefs');
    isnt(refaddr($dones[1]), refaddr($dones[2]),
        'safe mode hands the last two items distinct done coderefs');
};

subtest 'series_map croaks on a non-coderef worker' => sub {
    eval { series_map([1, 2], [], sub { }) };
    like($@, qr/worker must be a code reference/, 'croaks before dispatch');
};

subtest 'map primitives over a tied array' => sub {
    package TiedList;
    sub TIEARRAY  { bless { d => [@_[1 .. $#_]] }, $_[0] }
    sub FETCH     { $_[0]{d}[$_[1]] }
    sub FETCHSIZE { scalar @{$_[0]{d}} }
    sub STORE     { $_[0]{d}[$_[1]] = $_[2] }
    sub STORESIZE { }

    package main;
    tie my @items, 'TiedList', qw(p q r);

    my @seen;
    my $final = 0;
    series_map(\@items, sub {
        my ($item, $done) = @_;
        push @seen, $item;
        $done->();
    }, sub { $final++ });

    is_deeply(\@seen, [qw(p q r)], 'tied array falls back to av_fetch correctly');
    is($final, 1, 'final_cb fired once');
};

subtest 'map primitive nested inside another primitive' => sub {
    our @w;
    my @seen;
    my $final = 0;

    series([
        sub {
            my $outer = shift;
            parallel_map([qw(a b)], sub {
                my ($item, $done) = @_;
                push @w, EV::timer 0.01, 0, sub { push @seen, $item; $done->() };
            }, sub { $outer->() });
        },
        sub { my $d = shift; push @seen, 'after'; $d->() },
    ], sub { $final++; EV::break });

    EV::run;
    is(scalar @seen, 3, 'inner map and outer series both completed');
    is($seen[-1], 'after', 'outer series waited for the inner map');
    is($final, 1, 'final_cb fired once');
    @w = ();
};

subtest 'unsafe map abandons on an escaping exception' => sub {
    our @w;
    my $final = 0;

    eval {
        parallel_map([1, 2], sub {
            my ($item, $done) = @_;
            if ($item == 1) {
                push @w, EV::timer 0.01, 0, sub { $done->() };
            } else {
                $done->();
                die "boom\n";
            }
        }, sub { $final++ }, 1);
    };
    is($@, "boom\n", 'exception propagated to the caller');

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;
    is($final, 0, 'operation abandoned; final_cb never fired');
    @w = ();
};

done_testing;
