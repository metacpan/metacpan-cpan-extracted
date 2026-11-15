use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;
use experimental qw(builtin);
use builtin      qw(blessed);

# The design's proofs (docs/design/DESIGN.md, section 19, on the tag
# archive/pipeline-experimental), and its settled decisions (2026-0022's
# record), run against the prototype built on pipeline-experimental. And the pattern that lets a package such as
# DBIx::Squirrel use Ekorn as it is: parts of its own, keeping Ekorn's
# protocols, that load nothing of Ekorn's to do it.

use Carp       qw(croak);
use File::Temp qw(tempdir);
use Ekorn::Pipeline;
use Ekorn::Pipeline::Factories qw(
    stage     source generator yield sink_one
    sink_many gather);
use Ekorn::Pipeline::Operators;
use Ekorn::Pipeline::Sink  qw();
use Ekorn::Pipeline::Sinks qw(
    keep keep_all count_items keep_first keep_last keep_single
    to_file);
use Ekorn::Pipeline::Sources qw(from_array from_file);
use Ekorn::Pipeline::Stages::Flow;
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';
my $dir   = tempdir(CLEANUP => 1);

# What the parts below were told, in order.
my @log;

# A source of the values given, logging its set-up, each pull, and how
# its run ended.
sub spy_source (@values) {
    return source {
        push @log, 'source set-up';
        my @remaining = @values;
        return (
            sub () { push @log, 'pull'; @remaining ? shift @remaining : () },
            sub ($how) { push @log, "source $how" },
        );
    };
}

# A list sink giving every value, logging its set-up and how its run
# ended.
sub spy_sink () {
    return sink_many {
        push @log, 'sink set-up';
        my @all;
        return (
            sub ($value) { push @all, $value },
            sub () { @all },
            sub ($how) { push @log, "sink $how" },
        );
    };
}

# A sink keeping its values only if the run is done, as a transaction
# commits, logging which; its result is how many it was given.
sub saving_sink ($saved) {
    return sink_one {
        my @pending;
        return (
            sub ($value) { push @pending, $value },
            sub () { scalar @pending },
            sub ($how) {
                if ($how eq 'done') { push @$saved, @pending; push @log, 'commit' }
                else                { push @log, "rollback ($how)" }
            },
        );
    };
}


sub drain_all ($next) {
    my @values;
    while (my($value) = $next->()) { push @values, $value }
    return @values;
}


sub write_file ($name, $content) {
    my $path = "$dir/$name";
    open my $fh, '>', $path or croak "Can't write $path: $!";
    print { $fh } $content;
    close $fh or croak "Can't write $path: $!";
    return $path;
}


sub read_file ($path) {
    open my $fh, '<', $path or croak "Can't read $path: $!";
    local $/ = undef;
    my $content = readline $fh;
    close $fh or croak "Can't read $path: $!";
    return $content;
}

subtest '19.1 A source joined directly to a sink' => sub {
    my $from = write_file('a.txt', "one\ntwo\nthree\n");

    subtest 'it copies, and gives how many records' => sub {
        my($n) = $class->new(to_file("$dir/b.txt"))->iterator(from_file($from))->();
        is $n,                      3,                   'pulled, through an iterator';
        is read_file("$dir/b.txt"), "one\ntwo\nthree\n", 'record for record';
        is from_file($from) | to_file("$dir/c.txt"), 3,  'and with |';
        is read_file("$dir/c.txt"), read_file("$dir/b.txt"), 'the same';
    };

    subtest 'a last line without a newline gains one' => sub {
        my $short = write_file('short.txt', "x\ny");
        is from_file($short) | to_file("$dir/short-copy.txt"), 2;
        is read_file("$dir/short-copy.txt"),                   "x\ny\n";
    };

    subtest 'run out: both told done, the source first (D11)' => sub {
        @log = ();
        my @result = drain_all($class->new(spy_sink)->iterator(spy_source(1, 2)));
        is \@result, [1, 2];
        is \@log,
            [
                'source set-up', 'sink set-up', 'pull', 'pull', 'pull', 'source done',
                'sink done',
            ];
    };

    subtest 'stopped by keep_first: the source stopped, after one value' =>
        sub {
            @log = ();
            my($first) = $class->new(keep_first)->iterator(spy_source(1, 2, 3))->();
            is $first, 1;
            is \@log,  ['source set-up', 'pull', 'source stopped'];
            is spy_source(7, 8) | keep_first, 7, 'and with |';
        };

    subtest "a sink that can't be set up: the source told died" => sub {
        @log = ();
        like dies {
            $class->new(to_file("$dir/no/such/dir/b.txt"))->iterator(spy_source(1))
        },
            qr( \A Can't\ write\ \S+/no/such/dir/b\.txt: )x;
        is \@log, ['source set-up', 'source died'];
    };

    subtest
        'a sink that dies on a value: both told died, and the error thrown' => sub {
            @log = ();
            my $fails = sink_one {
                return (
                    sub ($value) { die "No room\n" }, sub () { 0 },
                    sub ($how) { push @log, "sink $how" },
                );
            };
            like dies { drain_all($class->new($fails)->iterator(spy_source(1, 2))) },
            qr( \A Pipeline\ stage\ \#1\ failed .* No\ room )xs;
            is \@log, ['source set-up', 'pull', 'source died', 'sink died'];
        };

    subtest 'both forms agree' => sub {
        @log = ();
        my $by_iterator
            = ($class->new(count_items)->iterator(spy_source(1, 2, 3))->())[0];
        my @iterator_log = @log;
        @log = ();
        my $by_operator = spy_source(1, 2, 3) | count_items;
        is $by_operator, $by_iterator,   'the same result';
        is \@log,        \@iterator_log, 'the same ends';
    };
};

subtest 'A sink commits only if the whole run went through (D6, D11, D15)' =>
    sub {
        subtest 'a stage dying after the sink: rolled back' => sub {
            @log = ();
            my @saved;
            like dies {
                drain_all($class->new(saving_sink(\@saved), sub { die "Later\n" })
                    ->iterator(spy_source(1, 2)))
            }, qr( Later )x;
            is \@saved, [], 'nothing kept';
            is \@log,
            ['source set-up', 'pull', 'pull', 'pull', 'source died', 'rollback (died)'];
        };

        subtest "the source's end dying: known before the sink commits" => sub {
            @log = ();
            my @saved;
            my $closing = source {
                my @rest = (1, 2);
                return (
                    sub () { @rest ? shift @rest : () },
                    sub ($how) { die "Can't close\n" },
                );
            };
            like
            dies { drain_all($class->new(saving_sink(\@saved))->iterator($closing)) },
            qr( \A Pipeline\ end\ of\ the\ source\ failed .* Can't\ close )xs;
            is \@saved, [],                  'nothing kept';
            is \@log,   ['rollback (died)'], 'the sink told died';
        };

        subtest 'a pulled sink last commits as its result is ready' => sub {
            @log = ();
            my @saved;
            my $next = $class->new(saving_sink(\@saved))->iterator(spy_source(1, 2));
            my($n) = $next->();
            is $n,      2,      'its result';
            is \@saved, [1, 2], 'kept, while the iterator still lives';
            is \@log,
            ['source set-up', 'pull', 'pull', 'pull', 'source done', 'commit'];
        };
    };

subtest 'An end that dies (Q6, D27)' => sub {
    subtest
        'while the run is dying: a warning naming it, keeping the first error' =>
        sub {
            @log = ();
            my $fails = sink_one {
                return (
                    sub ($value) { croak 'First' }, sub () { 0 },
                    sub ($how) { croak 'Second' },
                );
            };
            my $warnings = warnings {
                like dies { drain_all($class->new($fails)->iterator(spy_source(1))) },
                qr( First )x;
            };
            is scalar @$warnings, 1;
            like $warnings->[0],
            qr( \A The\ end\ of\ stage\ \#1\ died .* dying:\ Second )x;
            is \@log, ['source set-up', 'pull', 'source died'],
            'and the source is still told';
        };

    subtest 'as the run ends: thrown, once the rest are told it died' => sub {
        @log = ();
        my $fails = sink_one {
            return (sub ($value) { return }, sub () { 0 }, sub ($how) { croak 'Full' });
        };
        like
            dies { drain_all($class->new($fails, spy_sink)->iterator(spy_source(1))) },
            qr( \A Pipeline\ end\ of\ stage\ \#1\ failed .* Full )xs;
        is \@log,
            [
                'source set-up', 'sink set-up', 'pull', 'pull', 'source done',
                'sink died',
            ];
    };
};

subtest 'How each part is told the run ended (D16, D20)' => sub {
    subtest 'a part whose input ran out is done, whatever follows it' => sub {
        @log = ();
        is [drain_all($class->new(spy_sink, take(1))->iterator(spy_source(1, 2, 3)))
        ], [1];
        is \@log,
            [
                'source set-up', 'sink set-up', 'pull', 'pull', 'pull', 'pull',
                'source done',   'sink done',
            ],
            'take(1) stops after the sink has had all its input';
    };

    subtest 'a stage stopping on the last value it will get is done' => sub {
        my $stopper = sub {
            return gather {
                return (
                    sub ($value) { Stop($value) }, undef,
                    sub ($how) { push @log, "stopper $how" },
                );
            };
        };
        @log = ();
        is [
            drain_all(
                $class->new(count_items, $stopper->())->iterator(spy_source(1, 2)))
            ],
            [2];
        is $log[-1], 'stopper done', 'given the one value a sink gives';
        @log = ();
        is [
            drain_all($class->new(spy_sink, $stopper->())->iterator(spy_source(1, 2)))
        ], [1];
        is $log[-1], 'stopper stopped',
            'but stopped with another value still waiting for it';
    };

    subtest 'a source that stops has had enough, and is done' => sub {
        @log = ();
        my $enough = source {
            my $n = 0;
            return (
                sub () { ++$n < 2 ? $n : Stop(9) },
                sub ($how) { push @log, "source $how" },
            );
        };
        is [drain_all($class->new(sub { $_ * 10 })->iterator($enough))], [10, 90],
            'what it carries is its last';
        is \@log, ['source done'];
    };

    subtest 'ended from outside: done for a part whose input ran out' => sub {
        @log = ();
        my $next = $class->new(spy_sink)->iterator(spy_source(1, 2, 3));
        is [$next->()], [1];
        $next->finish;
        is [$next->()], [], 'what was still to be handed out is dropped (D22)';
        is \@log,
            [
                'source set-up', 'sink set-up', 'pull', 'pull', 'pull', 'pull',
                'source done',   'sink done',
            ];
    };
};

subtest '19.2 A complete pipeline as a source' => sub {
    subtest 'the inner run ends at the first pull (D15)' => sub {
        @log = ();
        my $lines
            = $class->new(stage { uc }, spy_sink)->iterator(spy_source(qw(a b c)));
        my $next = $class->new(take(2))->iterator($lines);
        is [$next->()], ['A'];
        is \@log,
            [
                'source set-up', 'sink set-up', 'pull', 'pull', 'pull', 'pull',
                'source done',   'sink done',
            ],
            'its source and sink told done, before the outer run has its first value';
        is [drain_all($next)], ['B'], 'take(2) then stops the outer run';
        is scalar @log,        8,     "and the inner's parts, ended, aren't told again";
    };

    subtest "a die in the outer run doesn't reach the inner" => sub {
        @log = ();
        my $lines = $class->new(spy_sink)->iterator(spy_source(1, 2));
        my $next
            = $class->new(sub { $_ == 2 ? croak 'Two' : $_ })->iterator($lines);
        is [$next->()], [1];
        like dies { $next->() }, qr( Two )x;
        is \@log,
            [
                'source set-up', 'sink set-up', 'pull', 'pull', 'pull', 'source done',
                'sink done',
            ];
    };

    subtest 'a result of one value is a source of one value' => sub {
        my $counted = $class->new(count_items)->iterator(spy_source(qw(a b c)));
        is [drain_all($class->new->iterator($counted))], [3];
    };

    subtest 'without a sink, the inner run is pulled only as needed' => sub {
        @log = ();
        my $lines = $class->new(stage { uc })->iterator(spy_source(qw(a b c d)));
        is [drain_all($class->new(take(2))->iterator($lines))], [qw(A B)];
        is \@log, ['source set-up', 'pull', 'pull', 'source stopped'],
            'two pulls, and the inner source told stopped, as from outside';
    };

    subtest 'abandoned, it ends' => sub {
        @log = ();
        {
            my $lines = $class->new(stage { uc })->iterator(spy_source(qw(a b c)));
            my $next  = $class->new->iterator($lines);
            $next->();
        }
        is \@log, ['source set-up', 'pull', 'source stopped'],
            'let go after one pull';
    };

    subtest 'ended by finish, it stops, taking no verdict' => sub {
        @log = ();
        my $next = $class->new(stage { uc })->iterator(spy_source(qw(a b c)));
        is [$next->()], ['A'];
        ok dies { $next->finish('done') }, 'finish takes no verdict of its own';
        $next->finish;
        is [$next->()], [], 'nothing more is handed out';
        is \@log, ['source set-up', 'pull', 'source stopped'],
            'and nothing more pulled';
    };

    subtest 'finished from inside one of its own stages, it stops there' =>
        sub {
            @log = ();
            my $next;
            my $steps = 0;
            my $after = sink_one {
                return (
                    sub ($value) { $steps++ }, sub () { $steps },
                    sub ($how) { push @log, "sink $how" },
                );
            };
            $next = $class->new(sub { $next->finish if $_ == 2; $_ }, $after)
            ->iterator(spy_source(1, 2, 3));
            is [drain_all($next)], [];
            is $steps, 1, "the sink's step isn't called again";
            is \@log,
            ['source set-up', 'pull', 'pull', 'source stopped', 'sink stopped'];
            undef $next;
        };
};

subtest 'The caller asks how the run ended (D34)' => sub {
    my $next = $class->new(sub { $_ * 2 })->iterator(from_array(1, 2));
    is $next->ended, undef, 'nothing while it goes';
    my @values = drain_all($next);
    is $next->ended, 'done', 'done when its values ran out';

    $next = $class->new(take(1))->iterator(from_array(1, 2, 3));
    my @one = drain_all($next);
    is $next->ended, 'stopped', 'stopped when take(1) cut the reading short';

    $next = $class->new(sub { $_ })->iterator(from_array(1, 2, 3));
    $next->();
    $next->finish;
    is $next->ended, 'stopped', 'stopped when finished early';

    $next = $class->new(sub { die "No\n" })->iterator(from_array(1));
    ok dies { $next->() };
    is $next->ended, 'died', 'died when a stage died';

    my $failing = source {
        my @rest = (1);
        return (
            sub () { @rest ? shift @rest : () },
            sub ($how) { die "Can't close\n" },
        );
    };
    $next = $class->new->iterator($failing);
    ok dies { drain_all($next) };
    is $next->ended, 'died', 'and when an end died';
};

subtest 'A spent iterator is no source for another run (D41)' => sub {
    my $next = $class->new->iterator(from_array(1, 2));
    is [$next->()], [1];
    is [drain_all($class->new->iterator($next))], [2],
        'read in part, it goes on';
    like dies { $class->new->iterator($next) },
        qr( \A Expected\ a\ source\ with\ values\ still\ to\ give )x,
        'spent, it croaks, rather than give nothing';

    my $finished = $class->new->iterator(from_array(1, 2));
    $finished->finish;
    ok dies { $class->new->iterator($finished) }, 'and so when finished';

    my $result = $class->new(keep_all)->iterator(from_array(1, 2));
    is [$result->()], [1], "a run that's ended with values still to give";
    is [drain_all($class->new->iterator($result))], [2], 'still gives them';
};

subtest 'A part called directly (D42, D43)' => sub {
    is count_items->(1, 2, 3), 3, 'a sink called with values gives its result';
    my $n = count_items->(1 .. 4);
    is $n,                 4,      'in scalar context too';
    is [keep_all->(1, 2)], [1, 2], 'a list sink gives its list';
    is keep_first->(),     undef,  'and a scalar sink of nothing, undef';
    @log = ();
    is [spy_sink->(5)], [5],                'so a sink is tested on its own';
    is \@log, ['sink set-up', 'sink done'], 'its end told how its run ended';

    like dies { from_array(1)->() },
        qr( \A Expected\ a\ source\ to\ be\ read\ through\ iterator )x,
        'a source called directly croaks';

    is Ekorn::Pipeline::is_sink(count_items), 'one',
        'is_sink: a scalar sink';
    is Ekorn::Pipeline::is_sink(keep_all), 'many', 'a list sink';
    is Ekorn::Pipeline::is_sink($class->new(stage { $_ }, count_items)),
        'one',
        'a pipeline, by the sink it ends in';
    ok !Ekorn::Pipeline::is_sink($_), 'not a sink'
        for stage { $_ }, sub { $_ }, $class->new,
        $class->new(count_items, stage { $_ }), 'count';
};

subtest 'ended: was the source read to its end? Said once spent (D48)' => sub {
    my $next = $class->new(keep_first)->iterator(from_array(1, 2, 3));
    is [$next->()],  [1];
    is $next->ended, undef, 'nothing until the iterator has given all it will';
    is [$next->()],  [];
    is $next->ended, 'stopped',
        'keep_first stopped the source: there were more';

    $next
        = $class->new(take(2), sub { $_ })->iterator(from_array(1, 2, 3));
    my @two = drain_all($next);
    is $next->ended, 'stopped', 'take(2), wherever it is, cut the source short';

    $next = $class->new(sub { $_ })->iterator(from_array(1, 2));
    my @all = drain_all($next);
    is $next->ended, 'done', 'read to its end';

    $next = $class->new(keep_all)->iterator(from_array(1, 2, 3));
    $next->();
    is $next->ended, undef,
        'a list sink still handing out its result: nothing yet';
    $next->finish;
    is $next->ended, 'stopped', 'finished with values undelivered: stopped';
};

subtest 'An end dying with values still waiting: no more is handed out' => sub {
    my $dies = sink_many {
        my @all;
        return (
            sub ($v) { push @all, $v }, sub () { @all },
            sub ($how) { die "Late\n" },
        );
    };
    my $next = $class->new($dies)->iterator(from_array(1, 2, 3));
    like dies { $next->() }, qr( Late )x;
    is [$next->()], [], 'nothing more';
    is $next->ended, 'died';
};

subtest 'sink_many and sink_one (D47, D64)' => sub {
    my $list = sink_many {
        my @all;
        (sub ($v) { push @all, $v }, sub () { @all })
    };
    my $scalar = sink_one {
        my $n = 0;
        (sub ($v) { $n++ }, sub () { $n })
    };
    is Ekorn::Pipeline::is_sink($list), 'many',
        'sink_many {...} makes a list sink';
    is Ekorn::Pipeline::is_sink($scalar), 'one',
        'sink_one {...} a scalar sink';
    is [$list->(1, 2)], [1, 2], 'called, it gives its list';
    is from_array(1, 2) | $scalar, 2, 'a scalar sink ends a chain';
    is from_array(1, 2) | $list, [1, 2],
        'and a list sink, giving its list as an array reference (D51)';
};

subtest 'Fixes from the fourth review' => sub {
    my $stops_at_end = sink_many {
        return (sub ($value) { return }, sub () { 1 }, sub ($how) { Stop() });
    };
    like dies { $class->new($stops_at_end)->(1) },
        qr( \A Pipeline\ end\ of\ stage\ \#1 .* no\ stop\ in\ an\ end )xs,
        'a stop from an end is an error, not a raw stop (D16)';
    my $outer = $class->new(sub { $class->new($stops_at_end)->($_) });
    ok dies { $outer->(1) }, "and so can't quietly stop a run around it";

    my $stops_at_setup = gather { Stop() };
    like dies { $class->new($stops_at_setup)->(1) },
        qr( \A Expected\ no\ stop\ in\ a\ set-up )x, 'nor can a stop from a set-up';

    my $next = $class->new->iterator(from_array(1, 2));
    is [@{ $next | stage { $_ * 10 } }], [10, 20],
        'an iterator chains, and drains, as a source';
    like dies {
        my @x = @{ $next | sub { $_ } }
    }, qr( spent )x, 'and, spent, croaks when the chain runs';

    my $dies = $class->new(sub { die "No\n" })->iterator(from_array(1));
    ok dies { $dies->() };
    like dies { $class->new->iterator($dies) }, qr( spent )x,
        'an iterator that died is spent, as a source';

    like dies {
        my $x = $class->new(sub { $_ }) | stage { $_ }
    },
        qr( \A Expected\ a\ source, )x, 'a pipeline made with new has no |';

    my $counting = \&{ count_items() };
    is $counting->(1, 2, 3), 3, "a sink's code reference outlives the sink";
};

subtest 'Sinks named for what they give (D50)' => sub {
    is [keep_all->(1, 2)], [1, 2],
        'keep_all gives every item, as a list';
    is keep_single->(7), 7,     'keep_single gives the one item';
    is keep_single->(),  undef, 'or undef, given none';
    my $first;
    my $warnings = warnings { $first = keep_single->(7, 8, 9) };
    is $first,            7, 'given more, it gives the first';
    is scalar @$warnings, 1, 'and warns, once';
    like $warnings->[0], qr( \A Expected\ only\ one\ item )x;
    is from_array(9) | keep_single, 9, 'it ends a chain';
    is keep_first->(3, 4),          3, 'keep_first gives the first';

    is keep_last->(3, 4, 5),                5,     'keep_last gives the last';
    is keep_last->(),                       undef, 'or undef, given none';
    is from_array(1, 2) | keep_last,        2,     'it ends a chain';
    is Ekorn::Pipeline::is_sink(keep_last), 'one', 'a scalar sink';
    my $next = $class->new(keep_last)->iterator(from_array(1, 2, 3));
    is [$next->()],  [3],    'pulled, it gives the last';
    is [$next->()],  [],     'and only that';
    is $next->ended, 'done', 'having read the source to its end';
};

subtest 'An iterator gives all, first or single (D59)' => sub {
    my $next = $class->new(sub { $_ * 2 })->iterator(from_array(1 .. 4));
    is [$next->()],  [2],       'pulled once';
    is [$next->all], [4, 6, 8], 'all: the values still to come, as a list';
    is $next->ended, 'done',    'read to its end';
    is [$next->all], [],        'and none, once spent';
    $next = $class->new->iterator(from_array(1, 2));
    my $all = $next->all;
    is $all, [1, 2], 'an array reference, asked for one value';
    is $class->new->iterator(from_array())->all, [], 'empty, if none';

    $next = $class->new->iterator(from_array(1, 2, 3));
    is [$next->first], [1],       'first: the next value';
    is $next->ended,   'stopped', 'and the run ended, reading no more';
    is [$next->()],    [],        'nothing after it';
    is [$class->new->iterator(from_array())->first], [undef],
        'undef, if none';

    $next = $class->new->iterator(from_array(7));
    my $warnings = warnings { is $next->single, 7, 'single: the one value' };
    is $warnings,    [],     'no warning, if it was the only one';
    is $next->ended, 'done', 'the run read to its end';
    $next = $class->new->iterator(from_array(7, 8, 9));
    my $got;
    my $line = __LINE__ + 1;
    $warnings = warnings { $got = $next->single };
    is $got,              7, 'the first, if there were more';
    is scalar @$warnings, 1, 'and a warning, once';
    is $warnings->[0],
        "Expected only one item, but there were more at ${\ __FILE__ } line $line.\n",
        "at the caller's line";
    is $next->ended, 'stopped', 'the run ended, reading no more';
    is [$class->new->iterator(from_array())->single], [undef],
        'undef, if none';

    # A source's step may give several values at once.
    my @steps = ([1], [2, 3, 4]);
    my $steps = source {
        return sub () { my $step = shift @steps; $step ? @$step : () }
    };
    $next = $class->new->iterator($steps);
    is [$next->()],  [1],       'pulled once, from a step of one';
    is [$next->all], [2, 3, 4], 'all, from a step giving every value left';
    is $next->ended, 'done',    'read to its end';

    # all takes what's ready in bulk: it gives the same as pulling.
    $next = $class->new(keep_all)->iterator(from_array(1 .. 4));
    is [$next->()],  [1],       "a list sink's result, pulled once";
    is [$next->all], [2, 3, 4], 'then the rest of it, in bulk';
    is $next->ended, 'done';
    $next = $class->new(keep_all, sub { $_ * 10 })
        ->iterator(from_array(1, 2));
    is [$next->all], [10, 20], 'and through a stage after the sink';
    @steps = ([1, 2, 3], [4]);
    $next  = $class->new(take(2))->iterator($class->new->iterator(source {
        return sub () { my $step = shift @steps; $step ? @$step : () }
    }));
    is [$next->all], [1, 2], 'and stopped part way through a step';
    is $next->ended, 'stopped';
};

subtest "An iterator's code reference, taken once (D63)" => sub {
    my $it   = $class->new->iterator(from_array(1, 2, 3));
    my $next = \&$it;
    ok !blessed($next), 'a plain code reference, with no overload to call';
    is [$next->()], [1], 'pulled through it';
    is [$it->()],   [2], 'the same run as the iterator';
    undef $it;
    is [$next->()], [], 'and the run ended when the iterator was let go';
};

subtest 'from_array: the values given, afresh each run (D68)' => sub {
    my $source = from_array(1, undef, 3);
    is [drain_all($class->new->iterator($source))], [1, undef, 3],
        'every value, undef among them';
    is [drain_all($class->new->iterator($source))], [1, undef, 3],
        'and again, from the first, on another run';
    is [drain_all($class->new->iterator(from_array()))], [], 'none, given none';
};

subtest 'from_file slurps, with $/ undefined' => sub {
    my $dir = tempdir(CLEANUP => 1);
    for ([lines => "a\nb\n"], [empty => '']) {
        my($name, $text) = @$_;
        open my $fh, '>', "$dir/$name" or die "Can't write $dir/$name: $!";
        print { $fh } $text;
        close $fh;
    }
    local $/ = undef;
    is [$class->new->iterator(from_file("$dir/lines"))->all], ["a\nb\n"],
        'the whole file, as one record';
    is [$class->new->iterator(from_file("$dir/empty"))->all], [],
        'and an empty file, none';
};

subtest 'from_file and to_file take I/O layers, for bytes or text (D69)' =>
    sub {
        my $dir   = tempdir(CLEANUP => 1);
        my $bytes = join '', map { chr } 0 .. 255, 13, 10, 0, 26;
        {
            open my $fh, '>:raw', "$dir/in" or die "Can't write $dir/in: $!";
            print { $fh } $bytes;
            close $fh;
        }
        {
            local $/ = \7;    # fixed records, for bytes
            is [from_file("$dir/in", ':raw') | to_file("$dir/out", ':raw')],
            [38], 'a binary file of 260 bytes, in 38 records of up to 7';
        }
        open my $fh, '<:raw', "$dir/out" or die "Can't read $dir/out: $!";
        my $copy = do { local $/ = undef; <$fh> };
        close $fh;
        is $copy, $bytes, 'copied unchanged';

        my $word = "caf\x{e9} \x{2603}";
        my $n    = from_array($word) | to_file("$dir/text", ':encoding(UTF-8)');
        is [$class->new->iterator(from_file("$dir/text", ':encoding(UTF-8)'))->all],
        [$word], 'text, encoded and decoded as UTF-8';
        # The line ends in the platform's text mode: "\r\n" on Windows.
        open $fh, '<:raw', "$dir/text" or die "Can't read $dir/text: $!";
        my $written = do { local $/ = undef; <$fh> };
        close $fh;
        like $written, qr( \A caf\xc3\xa9 \  \xe2\x98\x83 \r? \n \z )x,
        'written as UTF-8: 9 bytes, then $/';
    };

subtest 'generator: a source of what its block yields (D70)' => sub {
    my $runs  = 0;
    my $pairs = generator {
        $runs++;
        for my $x (1 .. 3) {
            for my $y ($x .. 3) { yield [$x, $y] }
        }
    };
    is [map { "@$_" } @{ $pairs | keep_all }],
        ['1 1', '1 2', '1 3', '2 2', '2 3', '3 3'],
        'every value it yields, from loops, in order';
    is [map { "@$_" } @{ $pairs | take(2) | keep_all }], ['1 1', '1 2'],
        'and only what a stage takes';
    is $runs, 2, 'its block called once for each run';

    my $next = $class->new->iterator(generator { yield 1, undef; yield });
    is [$next->all], [1, undef], 'several at once, undef among them, or none';
    is $next->ended, 'done';
    is [$class->new->iterator(generator { return })->all], [],
        'nothing, if it yields nothing';

    my $inner = generator { yield 1, 2 };
    my $outer = generator {
        yield 'a';
        yield map { "b$_" } @{ $inner | keep_all };
        yield 'c';
    };
    is $outer | keep_all, [qw(a b1 b2 c)],
        "a generator read inside another's block keeps its own";

    my $line = __LINE__ + 1;
    is dies { yield 1 },
        "Expected yield to be called inside a generator at ${\ __FILE__ } line $line.\n",
        "yield outside a generator croaks, at the caller's line";
};

subtest 'keep(N): the first N items, stopping there (D57)' => sub {
    is [keep(2)->(1 .. 5)], [1, 2], 'the first two, as a list';
    my $kept = keep(2)->(1 .. 5);
    is $kept, [1, 2], 'a reference, asked for one value';
    is from_array(1 .. 5) | keep(2), [1, 2],
        'and so at the end of a chain';
    is from_array(1) | keep(2),           [1],    'fewer, if there were fewer';
    is from_array(1, 2) | keep(0),        [],     'none, for keep(0)';
    is Ekorn::Pipeline::is_sink(keep(2)), 'many', 'a list sink';

    my $next = $class->new(keep(2))->iterator(from_array(1 .. 5));
    is [drain_all($next)], [1, 2];
    is $next->ended, 'stopped', 'having stopped the source at two';
    $next = $class->new(keep(3))->iterator(from_array(1, 2));
    is [drain_all($next)], [1, 2];
    is $next->ended, 'done', 'or read it to its end, if it had fewer';

    for my $bad (-1, 1.5, 'x', '', undef) {
        my $line = __LINE__ + 1;
        is dies { keep($bad) },
            "Expected a count of 0 or more at ${\ __FILE__ } line $line.\n",
            'N is checked as take checks it: ' . ($bad // 'undef');
    }
};

subtest 'Sinks and context (D10, D17, D25, D51)' => sub {
    is from_array(1, 2) | keep_all, [1, 2],
        'a list sink at the end of a chain gives its list as an array reference';
    is from_array() | keep_all, [],
        'an empty one, if there were none';

    my $n = $class->new(count_items)->(1 .. 10);
    is $n, 10, "in scalar context, a pushed run gives a scalar sink's result";
    my $all = $class->new(sub { $_ * 2 }, keep_all)->(1 .. 3);
    is $all, [2, 4, 6], "and a list sink's list, as an array reference";
    $all = keep_all->(1, 2);
    is $all, [1, 2], 'as a list sink called directly does';
    $n = $class->new(sub { $_ * 2 })->(1 .. 10);
    is $n, 10, 'and otherwise how many came out, as in v0.2.0';

    is [$class->new(keep_first)->()], [undef],
        'a scalar sink with no values gives one undef';
    is from_array() | keep_first,    undef, 'and so from a chain';
    is $class->new(count_items)->(), 0,     'count of nothing is 0';
    is +(from_array(1, 2) | count_items) + 10, 12,
        'a chain in parentheses, in an expression';
    like dies { my $x = from_array(1, 2) | count_items + 10 },
        qr( \A Expected\ a\ stage\ or\ a\ sink\ on\ the\ right )x,
        'and without them, | binding loosest, a clear error';
};

subtest 'Chains (D14, D23)' => sub {
    my $trim  = stage { s( \A \s+ | \s+ \z )()xgr };
    my $loud  = stage { uc };
    my $clean = $trim | $loud;
    isa_ok $clean, [$class], 'a chain of stages is a pipeline';
    is [$clean->(' a ', 'b ')], [qw(A B)], 'called as one';
    is from_array(' a', 'b ') | $clean | keep_all, [qw(A B)],
        'and spliced into a chain';
    is [@{ from_array(1, 2) | stage { $_ * 2 } }], [2, 4],
        '@{} drains a chain';

    my $counted = $clean | count_items;
    is scalar $counted->(' a', 'b'), 2, 'a chain of stages can end in a sink';

    like dies {
        my $x = sub { 1 }
            | $loud
    }, qr( \A Expected\ a\ source, )x,
        'a plain code reference on the left croaks';

    {
        no Ekorn::Pipeline::Operators;
        like dies { my $x = from_array(1) | $loud },
            qr( \A Expected\ use\ Ekorn::Pipeline::Operators\ in\ scope )x,
            '| croaks where Operators is not in force (Q23)';
    }
    is [@{ from_array(1) | $loud }], [1], 'and works again where it is';
};

subtest "Ekorn's types are Elements, offering role methods (D5, D13, D19)" =>
    sub {
        my $plain    = sub { $_ * 2 };
        my $pipeline = $class->new($plain);
        my $stage    = ($pipeline->stages)[0];
        isa_ok $stage, ['Ekorn::Pipeline::Stage'],
        'a code reference given to new is made a Stage';
        ref_is $stage->code, $plain, 'of the code given, kept as it is';
        is [$pipeline->(1, 2)], [2, 4], 'and run as it is';

        my %made = (
            stage  => stage { $_ },
            gather => Ekorn::Pipeline::Gather::gather(sub {
                sub { $_ }
            }),
            sink   => count_items,
            source => source {
                sub { () }
            },
            pipeline => $pipeline,
            iterator => $pipeline->iterator(sub { () }),
        );
        for my $type (sort keys %made) {
            isa_ok $made{$type}, ['Ekorn::Pipeline::Element'], "a $type";
        }
        is {
            map { ($_ => Ekorn::Pipeline::is_stage($made{$_})) } keys %made
        },
        {
            stage    => T(),
            gather   => T(),
            sink     => T(),
            pipeline => T(),
            source   => F(),
            iterator => F(),
        },
        'each goes where a stage goes by its role methods';
        ok Ekorn::Pipeline::is_stage($plain), 'as a code reference does';

        like dies { $class->new($made{source}) },
        qr( \A Expected\ stage\ \#1\ to\ be\ a\ stage,\ not\ a\ source )x,
        'a source given as a stage croaks';
        like dies { $class->new->iterator($pipeline) },
        qr( \A Expected\ a\ source:\ a\ code\ reference,\ or\ an\ object\ offering\ EKORN_SOURCE )x,
        'and a pipeline given as a source';
        like dies { $class->new->iterator(count_items) },
        qr( \A Expected\ a\ source: )x,
        'and a sink';

        my $bind = bless [2], 'My::Set';
        ok !Ekorn::Pipeline::is_stage($bind),
        'an object with an as_list method of its own is no stage (D49)';
        is [$class->new(sub { $_ * 2 })->($bind->[0])], [4];

        my $both = bless {}, 'My::Both';
        like dies { $class->new($both) },
        qr( \A Expected\ stage\ \#1 .* EKORN_STAGE\ and\ EKORN_SINK_ONE )x,
        "a part offering both a stage's method and a sink's croaks";
    };

# A package outside Ekorn's namespace, standing for DBIx::Squirrel: a
# table of rows, read from as a source that gives its columns as the
# run's context, and stages and a sink of its own. It loads nothing of
# Ekorn's for its parts; only its | needs Operators' functions.
package My::Table {
    use Ekorn::Pipeline::Operators qw();
    use overload
        '|'   => \&Ekorn::Pipeline::Operators::chain,
        '@{}' => \&Ekorn::Pipeline::Operators::drain;


    sub new ($class, $columns, @rows) {
        return bless {columns => $columns, rows => \@rows, log => []}, $class;
    }


    sub EKORN_SOURCE ($self) {
        my $i = 0;
        return (
            sub () { $i < @{ $self->{rows} } ? $self->{rows}[$i++] : () },
            sub ($how) { push @{ $self->{log} }, $how },
            {columns => [@{ $self->{columns} }]},    # this run's
        );
    }


    sub column ($name) {
        return sub ($row) {
            my $columns = Ekorn::Pipeline::run_context()->{columns};
            my($at) = grep { $columns->[$_] eq $name } 0 .. $#$columns;
            return $row->[$at];
        };
    }
}

package My::Set {    ## no critic (Modules::ProhibitMultiplePackages)
    sub as_list ($self) { return @$self }
}

package My::Both {    ## no critic (Modules::ProhibitMultiplePackages)


    sub EKORN_STAGE ($self) {
        return sub { $_ }
    }


    sub EKORN_SINK_ONE ($self) {
        return (sub { }, sub { 0 });
    }
}

subtest 'A package delivers parts, using Ekorn as it is (D1, D5, D7, D24)' =>
    sub {
        my $people
        = My::Table->new([qw(id name)], [1, 'Ann'], [2, 'Bo'], [3, 'Cy']);

        is [drain_all($class->new(My::Table::column('name'))->iterator($people))],
        [qw(Ann Bo Cy)],
        'its stage asks the run for its columns';
        is $people->{log}, ['done'], 'its source is told how the run ended';

        is $people | My::Table::column('name') | take(2) | keep_all,
        [qw(Ann Bo)],
        "with |, composed with Ekorn's parts";
        is $people->{log},      ['done', 'stopped'], 'told stopped by take(2)';
        is scalar @{ $people }, 3,                   '@{} drains it';

        my $inner = $class->new(My::Table::column('id'))->iterator($people);
        is [
            drain_all(
                $class->new(sub { [$_, Ekorn::Pipeline::run_context()->{columns}] })
                ->iterator($inner))
        ],
        [map { [$_, [qw(id name)]] } 1 .. 3],
        'behind an iterator, a stage sees the context of the run inside it';

        my $context_of = $class->new(sub { Ekorn::Pipeline::run_context() });
        my @contexts   = map { $context_of->iterator($people)->() } 1 .. 2;
        ok $contexts[0] != $contexts[1], 'each run has its own';

        my($pushed) = $class->new(sub {
            $class->new(
                sub { defined Ekorn::Pipeline::run_context() ? 'some' : 'none' })->($_);
        })->iterator($people)->();
        is $pushed, 'none', 'a run pushed inside a stage has none of its own';
    };

done_testing;
