use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# A run fed a value at a time (roadmap 2026-0044): $pipeline->feed
# opens a run, push runs values through it, giving what came out of
# them, and close ends it, giving what the flushes give. Each case
# feeds the same values, chunked several ways, and expects what an
# iterator of the same stages gives over a source of those values: the
# results, in order, how the run ended, how each end was told it ended,
# and any error. The caller stops pushing once the run has ended, as
# one must, a push after that croaking.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Feed qw();
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Source qw();
use Ekorn::Pipeline::Sinks  qw(keep keep_all keep_first count_items);
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Flow qw(take drop take_last take_while);
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';

# What each end was told, in order, by the stages log() makes.
our @log;    ## no critic (Variables::ProhibitPackageVars): localised by each case

# Return a stage passing each value on, whose end logs how it was told
# the run ended, as "$name $how".
sub log_end ($name) {
    return gather {
        return (sub ($value) { $value }, undef, sub ($how) { push @log, "$name $how" });
    };
}

# Return a stage holding its values back, and giving them all from its
# flush in a stop.
sub stop_in_flush () {
    return gather {
        my @held;
        return (sub ($value) { push @held, $value; return }, sub () { Stop(@held) });
    };
}

# Return a stage passing each value on, whose flush dies.
sub die_in_flush () {
    return gather {
        return (sub ($value) { $value }, sub () { die "flush failed\n" });
    };
}

# Return an error's text, with its line numbers made N, so a feed's
# and an iterator's compare.
sub plain_error ($error) {
    return ref $error ? $error : $error =~ s( \ line \ \d+ )( line N)xgr;
}

# Return what an iterator of $stages gives over a source of @values,
# one value a pull: [the results or the error, ended, the ends' log].
sub pulled ($stages, @values) {
    local @log;
    my @left = @values;
    my $next = $class->new(@$stages)->iterator(sub { @left ? shift @left : () });
    my $got  = eval { [$next->all] } // plain_error($@);
    return [$got, $next->ended, [@log]];
}

# Return what a feed of $stages gives for @values pushed in chunks of
# $size, then closed, stopping at the first push after which the run
# has ended: [the results or the error, ended, the ends' log].
sub fed ($stages, $size, @values) {
    local @log;
    my $feed = $class->new(@$stages)->feed;
    my @got;
    my $ok = eval {
        my @left = @values;
        while (@left && !defined $feed->ended) {
            push @got, $feed->push(splice @left, 0, $size);
        }
        push @got, $feed->close unless defined $feed->ended;
        1;
    };
    return [$ok ? \@got : plain_error($@), $feed->ended, [@log]];
}

my @cases = (
    ['a bare stage',           [sub { $_ * 2 }]],
    ['a filter',               [sub { $_ % 2 ? $_ : () }]],
    ['a stage giving several', [sub { ($_, -$_) }]],
    ['take(3)',                [take(3)]],
    ['drop(2)',                [drop(2)]],
    ['take_while',             [take_while { $_ < 4 }]],
    ['batch(3)',               [batch(3)]],
    ['collect',                [collect]],
    ['take_last',              [take_last]],
    ['keep_all',               [keep_all]],
    ['keep(2)',                [keep(2)]],
    ['keep_first',             [keep_first]],
    ['count_items',            [count_items]],
    [
        'a stop carrying values',
        [sub { $_ == 5 ? Stop('five', 'more') : $_ }, sub { "<$_>" }],
    ],
    ['a stop in a flush',  [stop_in_flush, sub { "<$_>" }, batch(4)]],
    ['a stage that dies',  [sub { die "bad $_\n" if $_ == 4; $_ }]],
    ['a flush that dies',  [die_in_flush]],
    ['several, with take', [sub { $_ * 10 }, take(4), batch(3), sub { "@$_" }]],
    ['take after batch',   [batch(2), take(2)]],
);

for my $case (@cases) {
    my($name, $stages) = @$case;
    for my $logged (0, 1) {
        # The last end logged is before a sink, which ends a pipeline.
        my @stages = @$stages;
        if ($logged) {
            my @sink  = Ekorn::Pipeline::is_sink($stages[-1]) ? (pop @stages)   : ();
            my @first = @stages                               ? (shift @stages) : ();
            @stages = (
                log_end('first'), @first, log_end('middle'), @stages, log_end('last'),
                @sink,
            );
        }
        for my $values ([], [1], [1 .. 10]) {
            my $want = pulled(\@stages, @$values);
            for my $size (1, 2, 10) {
                is fed(\@stages, $size, @$values), $want,
                    sprintf '%s%s, %d values, pushed %d at a time',
                    $name, $logged ? ', with ends' : '', scalar @$values, $size;
            }
        }
    }
}

subtest 'push gives what came out of its values, then and there' => sub {
    my $feed = $class->new(sub { $_ % 2 ? ($_, $_) : () }, batch(3))->feed;
    is [$feed->push(1)],    [],          'held by batch';
    is [$feed->push(2, 3)], [[1, 1, 3]], 'a batch fills';
    is [$feed->push],       [],          'a push of nothing gives nothing';
    is [$feed->close],      [[3]],       'close gives the flush';
    is $feed->ended,        'done',      'and the run is done';
};

subtest 'in scalar context, push and close give array references' => sub {
    my $feed   = $class->new(sub { $_ * 2 }, take_last)->feed;
    my $pushed = $feed->push(1, 2);
    is $pushed, [], 'push';
    my $closed = $feed->close;
    is $closed, [4], 'close';

    $feed = $class->new(count_items)->feed;
    $feed->push(qw(a b c));
    $closed = $feed->close;
    is $closed, [3], "a sink of one's result, in an array reference";
};

subtest 'a feed with no stages' => sub {
    my $feed = $class->new->feed;
    is [$feed->push(1, 2)], [1, 2], 'push gives its values';
    is [$feed->close],      [],     'close gives nothing';
    is $feed->ended,        'done', 'and the run is done';
};

subtest 'ended says nothing while the run is open' => sub {
    my $feed = $class->new(sub { $_ })->feed;
    is $feed->ended, undef, 'before a push';
    $feed->push(1);
    is $feed->ended, undef, 'after one';
};

subtest 'a stop ends the run in the push that meets it' => sub {
    local @log;
    my $feed
        = $class->new(log_end('first'), take(2), batch(5), log_end('last'))->feed;
    is [$feed->push(1)],    [],        'held by batch';
    is [$feed->push(2, 3)], [[1, 2]],  'take stops: batch flushes';
    is $feed->ended,        'stopped', 'and the run has stopped';
    is \@log, ['first stopped', 'last done'],
        'each end told from where it stands';
};

subtest 'a gather is made when the feed is' => sub {
    my $made     = 0;
    my $pipeline = $class->new(gather {
        $made++;
        sub ($value) { $value }
    });
    my $feed = $pipeline->feed;
    is $made, 1, 'made by feed';
    $feed->push(1);
    $feed->close;
    is $made, 1, 'and only then';

    local @log;
    like dies {
        $class->new(log_end('first'), gather { die "no set-up\n" })->feed
    },
        qr( \A no\ set-up \n \z )x, 'a set-up that dies dies in feed';
    is \@log, ['first died'], 'its ends made by then told it died';
};

subtest 'a stage that dies' => sub {
    local @log;
    my $feed
        = $class->new(log_end('first'), sub { die "bad $_\n" if $_ == 2; $_ })
        ->feed;
    is [$feed->push(1)], [1], 'a value before';
    like dies { $feed->push(2) },
        qr( \A Pipeline\ stage\ \#2\ failed\ at\ \S+\ line\ \d+ :\n \ {4} bad\ 2 \n \z )x,
        'dies in the push, named as a run names it, at the push';
    is $feed->ended, 'died',         'and the run died';
    is \@log,        ['first died'], 'its ends told so';
};

subtest 'once the run has ended, a push or a close croaks' => sub {
    my $at    = qr( \ at\ \S+\ line\ \d+ \.? \n \z )x;
    my %ended = (
        'closed'             => sub ($feed) { $feed->close },
        'finished'           => sub ($feed) { $feed->finish },
        'stopped by a stage' => sub ($feed) { $feed->push(1, 2) },
        'died'               => sub ($feed) {
            my $error = dies { $feed->push(3) }
        },
    );
    for my $how (sort keys %ended) {
        my $feed = $class->new(take(2), sub { die "three\n" if $_ == 3; $_ })->feed;
        $ended{$how}->($feed);
        my $why = {
            closed               => 'it was closed',
            finished             => 'it was finished',
            'stopped by a stage' => 'a stage stopped it',
            died                 => 'it died',
        }->{$how};
        like dies { $feed->push(9) },
            qr( \A Expected\ a\ feed\ still\ open,\ but\ its\ run\ has\ ended:\ \Q$why\E $at )x,
            "a push, once $how";
        like dies { $feed->close },
            qr( \A Expected\ a\ feed\ still\ open,\ but\ its\ run\ has\ ended:\ \Q$why\E $at )x,
            "a close, once $how";
        ok lives { $feed->finish }, "a finish, once $how, does nothing";
    }
};

subtest 'finish ends the run as from outside' => sub {
    local @log;
    my $feed = $class->new(log_end('first'), batch(5), log_end('last'))->feed;
    $feed->push(1, 2);
    $feed->finish;
    is $feed->ended, 'stopped', 'the run has stopped';
    is \@log, ['first stopped', 'last stopped'],
        'no flush, and its ends told it stopped';
};

subtest 'a feed let go is finished' => sub {
    local @log;
    {
        my $feed = $class->new(log_end('only'))->feed;
        $feed->push(1);
    }
    is \@log, ['only stopped'], 'its end told it stopped';
};

subtest 'no push, close or finish from inside the run' => sub {
    my $feed;
    my %inside = (
        push   => sub ($value) { $feed->push(0) },
        close  => sub ($value) { $feed->close },
        finish => sub ($value) { $feed->finish },
    );
    for my $method (sort keys %inside) {
        $feed = $class->new($inside{$method})->feed;
        like dies { $feed->push(1) },
            qr( \A Pipeline\ stage\ \#1\ failed .* :\n \ {4}
                Expected\ no\ \Q$method\E\ of\ a\ feed\ from\ inside\ its\ own\ run )xs,
            "a $method from a stage";
        is $feed->ended, 'died', 'kills the run';
    }
    undef $feed;
};

subtest 'a feed has no context, and its flushes are ending' => sub {
    my(@context, @ending);
    my $stage = gather {
        return (
            sub ($value) {
                push @context, Ekorn::Pipeline::run_context();
                push @ending,  Ekorn::Pipeline::ending();
                $value;
            },
            sub () { push @ending, Ekorn::Pipeline::ending(); return 'flushed' },
        );
    };
    my $feed
        = $class->new($stage, sub { push @ending, Ekorn::Pipeline::ending(); $_ })
        ->feed;
    $feed->push(1);
    $feed->close;
    is \@context, [undef], 'no context';
    is [map { $_ ? 1 : 0 } @ending], [0, 0, 1, 1],
        'ending in a flush, and the stages after it';
};

subtest 'a stage in a pipeline within, named as a pushed run names it' => sub {
    my $inner = $class->named(
        'My::Feed::inner' => sub { $_ },
        sub { die "bad\n" if $_ == 2; $_ },
    );
    my $end = gather { (sub ($value) { $value }, undef, sub ($how) { }) };
    for my $case (
        ['plain', [sub { $_ }, $inner]],
        ['full',  [sub { $_ }, $inner, $end]],
    ) {
        my($loop, $stages) = @$case;
        my $pipeline = $class->new(@$stages);
        my $pushed   = plain_error(dies { $pipeline->(1, 2) });
        my $feed     = $pipeline->feed;
        $feed->push(1);
        is plain_error(dies { $feed->push(2) }), $pushed, "the $loop loop";
        like $pushed, qr( \A Pipeline\ stage\ \#2\.2\ \(My::Feed::inner\#2\) )x,
            'as #2.2, by its name and place';
    }
};

subtest "a feed's stages see the context of the run pushing into it" => sub {
    my $source = Ekorn::Pipeline::Source->new(sub {
        my @left = (1, 2);
        return (sub { @left ? shift @left : () }, undef, {columns => ['n']});
    });
    my $end = gather { (sub ($value) { $value }, undef, sub ($how) { }) };
    for my $case (['plain', [sub { $_ }]], ['full', [sub { $_ }, $end]]) {
        my($loop, $stages) = @$case;
        my @seen;
        my $inner = $class->new(
            sub { push @seen, Ekorn::Pipeline::run_context(); () },
            @$stages,
        );
        my $feed = $inner->feed;
        $feed->push(0);
        $class->new(sub { $feed->push($_); $_ })->iterator($source)->all;
        is \@seen, [undef, {columns => ['n']}, {columns => ['n']}],
            "the $loop loop: none from outside a run, the run's from inside one";
    }
};

subtest 'a run that is not a feed, inside one with a context, has none' => sub {
    my $source = Ekorn::Pipeline::Source->new(sub {
        my @left = (1);
        return (sub { @left ? shift @left : () }, undef, {columns => ['n']});
    });
    my $end = gather { (sub ($value) { $value }, undef, sub ($how) { }) };
    my @seen;
    my $inner
        = $class->new(sub { push @seen, Ekorn::Pipeline::run_context(); () }, $end);
    $class->new(sub { $inner->($_); $_ })->iterator($source)->all;
    is \@seen, [undef], 'a pushed run with an end, called from a stage';
};

subtest 'a feed of plain stages takes the steps new made' => sub {
    my $made = 0;
    no warnings 'redefine';
    my $make_run = \&Ekorn::Pipeline::_make_run;
    local *Ekorn::Pipeline::_make_run
        = sub (@args) { $made++; return $make_run->(@args) };
    my $feed = $class->new(sub { $_ * 2 })->feed;
    is [$feed->push(1, 2)], [2, 4], 'it runs them';
    is $made,               0,      'without making the run';
    $class->new(take(1))->feed;
    is $made, 1, 'a gather is made, as before';
};

subtest 'feed takes no arguments' => sub {
    like dies { $class->new->feed(1) }, qr( Too\ many\ arguments )x, 'croaks';
};

subtest 'Ekorn::Pipeline::Feed is made by feed' => sub {
    isa_ok $class->new->feed, ['Ekorn::Pipeline::Feed'], 'feed makes one';
};

done_testing;
