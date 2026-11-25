use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# tee (roadmap 2026-0048): a tap that takes a pipeline. Each value goes
# through a branch of stages, one run of its own beside the main run,
# for what they do on the side, and is passed on unchanged.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Source qw();
use Ekorn::Pipeline::Sinks  qw(count_items keep_all to_fh);
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Flow qw(take take_if);
use Ekorn::Pipeline::Stages::Taps qw(tee  peek);
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';

# What each end was told, in order, by the stages log_end makes.
our @log;    ## no critic (Variables::ProhibitPackageVars): localised by each test

# Return a stage passing each value on, whose end logs how it was told
# the run ended, as "$name $how".
sub log_end ($name) {
    return gather {
        return (sub ($value) { $value }, undef, sub ($how) { push @log, "$name $how" });
    };
}

subtest 'what is exported' => sub {

    package Defaults {    ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Stages::Taps;
        ::ok !__PACKAGE__->can('tee'), 'not tee by default';
    }

    package All {         ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Stages::Taps qw(:all);
        ::ok __PACKAGE__->can('tee'), 'tee with :all';
    }

    package Tooling {     ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Tooling qw(:taps);
        ::ok __PACKAGE__->can('tee'), "tee with Tooling's :taps";
    }
};

subtest 'values go on unchanged, and the branch sees each' => sub {
    my @seen;
    my $p = $class->new(
        tee(sub { $_ * 10 }, sub { push @seen, $_; () }),
        sub { $_ + 1 },
    );
    is [$p->(1 .. 3)], [2 .. 4], 'pushed: the values go on as they came';
    is \@seen, [10, 20, 30],
        'and the branch ran each through its stages, in order';

    @seen = ();
    my @queue = (1 .. 3);
    my $next  = $p->iterator(sub { @queue ? shift @queue : () });
    is [$next->()],  [2],          'pulled: one value';
    is \@seen,       [10],         'the branch has seen only that one';
    is [$next->all], [3, 4],       'then the rest';
    is \@seen,       [10, 20, 30], 'and the branch the rest';
};

subtest 'what the branch returns is thrown away' => sub {
    my $p = $class->new(tee(sub { ($_, $_) }, keep_all));
    is [$p->(qw(a b))], [qw(a b)],
        'neither its extra values nor its sink reach the main run';
};

subtest 'the branch gets the value itself' => sub {
    my $p       = $class->new(tee(sub { $_->{seen} = 1; () }));
    my @results = $p->({}, {});
    is \@results, [{seen => 1}, {seen => 1}],
        'a hash it changes is changed for the main run';
};

subtest 'a stop in the branch ends only the branch' => sub {
    my @seen;
    my $p = $class->new(tee(take(2), sub { push @seen, $_; () }));
    is [$p->(1 .. 5)], [1 .. 5], 'the main run goes on';
    is \@seen,         [1, 2],   'the branch took two';

    local @log;
    my @queue = (1 .. 5);
    my $next  = $class->new(tee(log_end('branch'), take(1)), log_end('main'))
        ->iterator(sub { @queue ? shift @queue : () });
    is [$next->all], [1 .. 5],                 'pulled, the same';
    is $next->ended, 'done',                   'and the main run is done';
    is \@log, ['branch stopped', 'main done'], 'its ends told how each ended';
};

subtest "the branch's flushes are the tee's" => sub {
    my @batches;
    my $p = $class->new(
        tee(batch(2), sub { push @batches, "@$_"; () }),
        peek { push @batches, "main $_" },
    );
    $p->(1 .. 3);
    is \@batches, ['main 1', '1 2', 'main 2', 'main 3', '3'],
        'a batch as it fills, and the last when the main run runs out';

    my $total;
    $class->new(tee(count_items, sub { $total = $_; () }))->(qw(a b c));
    is $total, 3, "a sink's result, through the stages after it";
};

subtest "the branch's ends, as its run ends" => sub {
    local @log;
    $class->new(log_end('before'), tee(log_end('branch')), log_end('after'))
        ->(1, 2);
    is \@log, ['branch done', 'before done', 'after done'],
        "done, at the tee's flush, which closes the branch, before the main run's ends";

    @log = ();
    $class->new(tee(log_end('branch')), take(1))->(1, 2);
    is \@log, ['branch done'],
        "done, at the tee's end, which closes the branch, when a stop after the tee ends the main run";

    @log = ();
    my @queue = (1 .. 5);
    my $next  = $class->new(tee(log_end('branch')))
        ->iterator(sub { @queue ? shift @queue : () });
    $next->();
    $next->finish;
    is \@log, ['branch done'], 'done, when the main run is finished';

    @log = ();
    eval {
        $class->new(tee(log_end('branch')), sub { die "main\n" })->(1);
    };
    is \@log, ['branch stopped'],
        'stopped, when the main run dies, as a source read by a run that dies is';
};

subtest 'a stop after the tee closes the branch (roadmap 2026-0050)' => sub {
    my @batches;
    my $writer = sub { push @batches, "@$_"; () };
    is [$class->new(tee(batch(2), $writer), take(3))->(1 .. 10)], [1 .. 3],
        'the main run stops at its take';
    is \@batches, ['1 2', '3'],
        "and the branch's flush gives the batch it held";

    @batches = ();
    my @queue = (1 .. 10);
    my $next  = $class->new(tee(batch(2), $writer))
        ->iterator(sub { @queue ? shift @queue : () });
    is $next->first, 1,     "an iterator's first";
    is \@batches,    ['1'], 'closes it too';

    @batches = ();
    eval {
        $class->new(tee(batch(2), $writer), sub { die "main\n" })->(1);
    };
    is \@batches, [], 'but a main run that dies only finishes it';

    my @held;
    my $holder = gather {
        my @kept;
        return (sub { push @kept, $_[0]; () }, sub () { push @held, "@kept"; () });
    };
    is [$class->new(tee(tee($holder), take(2)), take(3))->(1 .. 10)], [1 .. 3],
        'a tee in a branch the stop ends';
    is \@held, ['1 2'], 'is closed by its own end, as the branch stops';

    my $flush_dies = gather {
        return (sub { $_[0] }, sub () { die "flush\n" });
    };
    like dies { $class->new(tee($flush_dies), take(1))->(1, 2) },
        qr( \A Pipeline\ end\ of\ stage\ \#1\ failed\ [^\n]+ \n
            \ {4} Pipeline\ stage\ \#1\ failed\ [^\n]+ \n
            \ {8} flush \n \z )x,
        "a branch's flush that dies there kills the run, from the tee's end";
};

subtest 'a death in the branch kills the run' => sub {
    local @log;
    my $p = $class->new(
        log_end('main'),
        tee(log_end('branch'), sub { die "bad $_\n" if $_ == 2; () }),
    );
    my $error = dies { $p->(1 .. 3) };
    like $error,
        qr( \A Pipeline\ stage\ \#2\ failed\ at\ \S+\ line\ \d+ :\n
            \ {4} Pipeline\ stage\ \#2\ failed\ at\ \S+\ line\ \d+ :\n
            \ {8} bad\ 2 \n \z )x,
        "named as the tee's stage, then the branch's";
    is \@log, ['branch died', 'main died'],
        "every end told it died, the branch's as it died";

    my $flush = $class->new(
        tee(gather { (sub ($value) { $value }, sub () { die "flush\n" }) }));
    like dies { $flush->(1) }, qr( \ {8} flush \n \z )x,
        "and in the branch's flush";
};

subtest 'a fresh branch for each run' => sub {
    my @seen;
    my $p = $class->new(tee(take(1), sub { push @seen, $_; () }));
    $p->(qw(a b));
    $p->(qw(c d));
    is \@seen, [qw(a c)], 'each run takes its own first';
};

subtest 'a pipeline given' => sub {
    my @seen;
    my $branch = $class->new(take_if { $_ % 2 }, sub { push @seen, $_; () });
    $class->new(tee($branch))->(1 .. 5);
    is \@seen, [1, 3, 5], 'goes in place of its stages';

    @seen = ();
    $class->new(tee)->(1, 2);
    is \@seen, [], 'and no stages does nothing';
};

subtest 'a sink last writes where it writes' => sub {
    open my $fh, '>', \my $written or die "Can't open a string: $!";
    my @results
        = $class->new(tee(sub { "<$_>" }, to_fh($fh)), sub { uc })->(qw(a b));
    close $fh;
    is \@results, [qw(A B)],    'the main run goes on';
    is $written,  "<a>\n<b>\n", 'and the branch writes';
};

subtest "the branch sees the main run's context" => sub {
    my $source = Ekorn::Pipeline::Source->new(sub {
        my @left = (1, 2);
        return (sub { @left ? shift @left : () }, undef, {columns => ['n']});
    });
    for my $case (['plain', []], ['full', [batch(1)]]) {
        my($loop, $more) = @$case;
        my @seen;
        $class->new(
            tee(@$more, sub { push @seen, Ekorn::Pipeline::run_context(); () }))
            ->iterator($source)
            ->all;
        is \@seen, [({columns => ['n']}) x 2], "a $loop branch";
    }
};

subtest 'the main run takes the plain loop where the branch allows' => sub {
    my $full = 0;
    no warnings 'redefine';
    my $full_iterator = \&Ekorn::Pipeline::_full_iterator;
    local *Ekorn::Pipeline::_full_iterator
        = sub (@args) { $full++; return $full_iterator->(@args) };
    $class->new(tee(sub { () }))->(1, 2);
    is $full, 0, 'a plain branch: neither run takes the full loop';
    $class->new(tee(batch(2), sub { () }))->(1, 2);
    is $full, 2, 'a branch with a flush: both do, as the tee has a flush';
};

subtest 'a tee in a branch' => sub {
    local @log;
    my $source = Ekorn::Pipeline::Source->new(sub {
        my @left = (1 .. 6);
        return (sub { @left ? shift @left : () }, undef, {columns => ['n']});
    });
    my(@outer, @inner, @context);
    my $next = $class->new(
        tee(
            take_if { $_ % 2 },
            tee(
                log_end('inner'),
                take(1),
                sub { push @inner, $_; push @context, Ekorn::Pipeline::run_context(); () },
            ),
            collect,
            sub { push @outer, "@$_"; () },
        ),
        sub { $_ * 10 },
    )->iterator($source);
    is [$next->all], [map { $_ * 10 } 1 .. 6],
        'the main run gets every value, unchanged';
    is \@outer, ['1 3 5'],
        'the outer branch, what passes its test, at its flush';
    is \@inner,   [1], 'the inner branch, what reaches it, until its stop';
    is \@log,     ['inner stopped'],    'which ends only the inner branch';
    is \@context, [{columns => ['n']}], "and it sees the main run's context";

    my $error = dies {
        $class->new(tee(tee(sub { die "deep\n" })))->(1)
    };
    like $error,
        qr( \A Pipeline\ stage\ \#1\ failed\ [^\n]+ \n
            \ {4} Pipeline\ stage\ \#1\ failed\ [^\n]+ \n
            \ {8} Pipeline\ stage\ \#1\ failed\ [^\n]+ \n
            \ {12} deep \n \z )x,
        'a death two branches down kills the run, nested a level for each tee';
};

subtest 'a tee in a pipeline a gather returns' => sub {
    local @log;
    my(@taken, @batches);
    my $made  = 0;
    my $stage = gather {
        $made++;
        my $n = 0;    # this run's
        return $class->new(
            sub { ++$n . ":$_" },
            tee(log_end('taken'), take(2), sub { push @taken, $_; () }),
            tee(batch(2), sub { push @batches, "@$_"; () }),
        );
    };
    my $p = $class->new($stage, sub { uc });

    is [$p->(qw(a b c))], [qw(1:A 2:B 3:C)], 'the main run gets every value';
    is \@taken, [qw(1:a 2:b)], "the first branch, until its stop";
    is \@batches, ['1:a 2:b', '3:c'],
        "the second, its last batch at the main run's flush";
    is \@log, ['taken stopped'], 'the stop ends only its branch';

    (@taken, @batches, @log) = ();
    is [$p->(qw(d e))], [qw(1:D 2:E)], 'a second run';
    is \@taken,         [qw(1:d 2:e)], 'gets a fresh branch';
    is \@batches,       ['1:d 2:e'],   'and a fresh batch';
    is $made,           2,             'as the gather is made for each run';

    my $error = dies {
        $class->new(
            sub { $_ },
            gather {
                $class->new(sub { $_ }, tee(sub { die "bad\n" }))
            },
        )->(1);
    };
    like $error,
        qr( \A Pipeline\ stage\ \#2\.2\ failed\ [^\n]+ \n
            \ {4} Pipeline\ stage\ \#1\ failed\ [^\n]+ \n
            \ {8} bad \n \z )x,
        "a death in its branch: the tee dotted, as it's spliced in, the branch's nested";
};

subtest 'mistakes croak at the caller' => sub {
    my $error = dies {
        tee(sub { $_ }, 'not a stage')
    };
    like $error,
        qr( \A Expected\ stage\ \#2\ to\ be\ a\ stage .* \ at\ \Q${\ __FILE__}\E\ line\ \d+ \. \n \z )xs,
        "a stage that is not one, counted among the tee's, at this file's line";
};

done_testing;
