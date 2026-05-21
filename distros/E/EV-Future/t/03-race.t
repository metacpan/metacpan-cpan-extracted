use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

subtest 'sync race - first task wins' => sub {
    my $winner;
    my $finished = 0;
    race([
        sub { my $d = shift; $d->("first") },
        sub { my $d = shift; $d->("second") },
        sub { my $d = shift; $d->("third") },
    ], sub { $winner = shift; $finished = 1 });
    ok($finished, 'final_cb fired');
    is($winner, 'first', 'first task wins in sync race');
};

subtest 'args forwarded to final_cb' => sub {
    my @got;
    race([
        sub { my $d = shift; $d->("a", 1, [2, 3]) },
        sub { my $d = shift; $d->("b") },
    ], sub { @got = @_ });
    is_deeply(\@got, ["a", 1, [2, 3]], 'all args forwarded');

    # No args
    @got = (1);
    race([ sub { shift->() } ], sub { @got = @_ });
    is_deeply(\@got, [], 'no-args call forwarded as empty list');
};

subtest 'async race - fastest wins' => sub {
    my $winner;
    our @w;
    race([
        sub { my $d = shift; push @w, EV::timer 0.05, 0, sub { $d->("slow") } },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("fast") } },
        sub { my $d = shift; push @w, EV::timer 0.03, 0, sub { $d->("medium") } },
    ], sub { $winner = shift; EV::break });
    EV::run;
    is($winner, 'fast', 'fastest async task wins');
    @w = ();
};

subtest 'losers ignored after winner' => sub {
    my $count = 0;
    my @dones;
    race([
        sub { push @dones, shift; $dones[-1]->("won") },
        sub { push @dones, shift },  # captures done but never calls
    ], sub { $count++ });
    # Now manually call the loser's done — should be ignored
    $dones[1]->("late") if $dones[1];
    # And winner's done called again — also ignored
    $dones[0]->("again");
    is($count, 1, 'final_cb fires exactly once');
};

subtest 'async loser completes harmlessly after winner' => sub {
    my $winner;
    my $loser_ran = 0;
    our @w;
    race([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("won") } },
        sub { my $d = shift; push @w, EV::timer 0.05, 0, sub { $loser_ran++; $d->("late") } },
    ], sub { $winner = shift });

    # Run long enough for loser to fire
    my $end = EV::timer 0.1, 0, sub { EV::break };
    EV::run;
    is($winner, 'won', 'winner correct');
    is($loser_ran, 1, 'loser timer fired (we do not cancel)');
    @w = ();
};

subtest 'empty tasks' => sub {
    my $finished = 0;
    my @got = (1);
    race([], sub { @got = @_; $finished = 1 });
    ok($finished, 'final_cb fires on empty tasks');
    is_deeply(\@got, [], 'empty tasks => no winner args');
};

subtest 'non-coderef task short-circuits' => sub {
    my $finished = 0;
    my @got = (1);
    my $second_ran = 0;
    race([undef, sub { $second_ran = 1; shift->("real") }],
        sub { @got = @_; $finished = 1 });
    ok($finished, 'final_cb fires immediately');
    is_deeply(\@got, [], 'non-coderef winner has no args');
    is($second_ran, 0, 'subsequent tasks not dispatched');
};

subtest 'task exception in safe mode' => sub {
    eval {
        race([sub { die "race boom\n" }], sub { });
    };
    is($@, "race boom\n", 'exception propagated');

    # Exception cleanup leaves module in usable state
    my $w;
    race([sub { shift->("ok") }], sub { $w = shift });
    is($w, 'ok', 'race still usable after exception');
};

subtest 'safe mode: async loser harmless after sync exception' => sub {
    our @w;
    my $final_called = 0;
    eval {
        race([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("late") } },
            sub { die "race boom\n" },
        ], sub { $final_called++ });
    };
    is($@, "race boom\n", 'exception propagated');

    my $stop = EV::timer 0.05, 0, sub { EV::break };
    EV::run;
    is($final_called, 0, 'final_cb does not fire after exception (cleanup ran)');
    @w = ();
};

subtest 'final_cb exception propagates' => sub {
    eval {
        race([sub { shift->() }], sub { die "final boom\n" });
    };
    is($@, "final boom\n", 'final_cb exception propagated');
};

subtest 'undef final_cb does not crash' => sub {
    eval { race([sub { shift->("x") }], undef) };
    ok(!$@, 'race survives non-coderef final_cb');

    eval { race([], undef) };
    ok(!$@, 'race survives non-coderef final_cb on empty tasks');
};

subtest 'unsafe mode' => sub {
    my $winner;
    race([sub { shift->("u1") }], sub { $winner = shift }, 1);
    is($winner, 'u1', 'unsafe race with one task works');

    # Multiple tasks — first sync wins
    race([
        sub { shift->("first") },
        sub { shift->("second") },
    ], sub { $winner = shift }, 1);
    is($winner, 'first', 'unsafe race: first sync wins');

    # Async unsafe
    our @w;
    race([
        sub { my $d = shift; push @w, EV::timer 0.03, 0, sub { $d->("slow") } },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("fast") } },
    ], sub { $winner = shift; EV::break }, 1);
    EV::run;
    is($winner, 'fast', 'unsafe async race');
    @w = ();
};

subtest 'nested race' => sub {
    my $winner;
    our @w;
    series([
        sub {
            my $done = shift;
            race([
                sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("inner-fast") } },
                sub { my $d = shift; push @w, EV::timer 0.05, 0, sub { $d->("inner-slow") } },
            ], sub { $winner = shift; $done->() });
        },
    ], sub { EV::break });
    EV::run;
    is($winner, 'inner-fast', 'race nested in series works');
    @w = ();
};

subtest 'stress' => sub {
    my $count = 0;
    for (1..1000) {
        race([
            sub { shift->($_) },
            sub { shift->("loser") },
        ], sub { $count++ if $_[0] == $_ });
    }
    is($count, 1000, '1000 sync races, all winners correct');
};

subtest 'array with holes' => sub {
    my $tasks = [];
    $tasks->[2] = sub { shift->("hole") };
    my $finished = 0;
    eval { race($tasks, sub { $finished = 1 }) };
    ok(!$@, 'race survives holes');
    ok($finished, 'race with holes fires final_cb');
};

done_testing;
