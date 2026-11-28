use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Where a value came from (roadmap 2026-0060): a stage that holds values
# back says so, with a holds part; it keeps an origin, kept_origin, for
# each value it keeps, and gives what it made from that value marked by
# the origin's gives; a value it gives unmarked has none. So the stages
# after it see each value's own original, in a flush too.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Tooling qw(:core :flow :batch :sources :context source);

my $class = 'Ekorn::Pipeline';

# Rows from a source with an original part, counting into $$asked how
# often it's asked: each value is a row's name, and its original the row.
sub rows ($n, $asked = undef) {
    return source {
        my $i = 0;
        return {
            step     => sub { $i < $n ? 'v' . ++$i : () },
            original => sub { $$asked++ if $asked; "row $i" },
        };
    };
}


# What a stage sees: its value, and the original it's given.
my $seen = sub { "$_ <- " . (result_original() // '-') };

# Return a stage holding each value back by one, giving the one before;
# its flush gives the last.
sub one_behind () {
    return gather {
        my @held;    # [value, origin]
        my $give = sub ($held) { $held->[1]->gives($held->[0]) };
        return {
            step => sub {
                push @held, [$_[0], kept_origin];
                return @held > 1 ? $give->(shift @held) : ();
            },
            flush => sub () {
                map { $give->($_) } splice @held;
            },
            holds => 1,
        };
    };
}


# Return a stage holding values until it has $n, then giving them all at
# once, in reverse: several values from one call, each from its own.
sub reversed_in ($n) {
    return gather {
        my @held;
        my $give = sub () {
            return map { $_->[1]->gives($_->[0]) } reverse splice @held;
        };
        return {
            step => sub {
                push @held, [$_[0], kept_origin];
                return @held >= $n ? $give->() : ();
            },
            flush => $give,
            holds => 1,
        };
    };
}


# Return a stage that holds values back, whose step is $step.
sub holding ($step, $flush = undef) {
    return gather { return {step => $step, flush => $flush, holds => 1} };
}

subtest "each value's own original, a flush's too" => sub {
    is [$class->new(one_behind(), $seen)->iterator(rows(3))->all],
        ['v1 <- row 1', 'v2 <- row 2', 'v3 <- row 3'], 'one behind';
    is [$class->new(reversed_in(2), $seen)->iterator(rows(5))->all],
        [
            'v2 <- row 2', 'v1 <- row 1', 'v4 <- row 4', 'v3 <- row 3',
            'v5 <- row 5',
        ],
        'several at once, each its own';
};

subtest 'the stage, and those before it, as now' => sub {
    my(@before, @inside);
    my $before = sub { push @before, result_original(); $_ };
    my $inside = holding(sub {
        push @inside, result_original();
        return kept_origin->gives($_[0]);
    });
    $class->new($before, $inside)->iterator(rows(2))->all;
    is \@before, ['row 1', 'row 2'], 'before it';
    is \@inside, ['row 1', 'row 2'], 'in it';
};

subtest 'maps, splits and a flush after it' => sub {
    my $split = sub { ("$_.a", "$_.b") };
    is [$class->new(one_behind(), $split, $seen)->iterator(rows(2))->all],
        ['v1.a <- row 1', 'v1.b <- row 1', 'v2.a <- row 2', 'v2.b <- row 2'],
        'split';
    my $total = gather {
        my $n = 0;
        return (sub { $n++; $_[0] }, sub () { "total $n" });
    };
    is [$class->new(one_behind(), $total, $seen)->iterator(rows(2))->all],
        ['v1 <- row 1', 'v2 <- row 2', 'total 2 <- -'],
        "a flush of a stage that doesn't hold values back: none, as now";
};

subtest "the source's part, asked only as a value is kept" => sub {
    my $asked = 0;
    $class->new(sub { $_ }, sub { $_ })->iterator(rows(5, \$asked))->all;
    is $asked, 0, 'never, through maps';
    $asked = 0;
    $class->new(sub { $_ }, one_behind(), sub { $_ })
        ->iterator(rows(5, \$asked))
        ->all;
    is $asked, 5, 'once a value it keeps';
    $asked = 0;
    $class->new(one_behind(), $seen, $seen)->iterator(rows(5, \$asked))->all;
    is $asked, 5, 'and not again when the stages after it ask';
    $asked = 0;
    $class->new(batch(2), $seen)->iterator(rows(5, \$asked))->all;
    is $asked, 0, 'never, by a stage that keeps no origin: batch';
};

subtest 'with no source, the value passed in' => sub {
    is [$class->new(sub { $_ * 10 }, one_behind(), $seen)->(1 .. 3)],
        ['10 <- 1', '20 <- 2', '30 <- 3'], 'pushed';
    my $feed = $class->new(one_behind(), $seen)->feed;
    my @got  = map { $feed->push($_) } qw(a b c);
    push @got, $feed->close;
    is \@got, ['a <- a', 'b <- b', 'c <- c'], 'fed';
};

subtest "a stop's values, marked" => sub {
    my $stops = holding(sub {
        my $origin = kept_origin;
        return $_[0] eq 'v2'
            ? Stop($origin->gives("$_[0]!"))
            : $origin->gives($_[0]);
    });
    is [$class->new($stops, $seen)->iterator(rows(4))->all],
        ['v1 <- row 1', 'v2! <- row 2'], 'from the value that stopped';
    my @held;
    my $held_stop = holding(sub {
        push @held, [$_[0], kept_origin];
        return if @held < 3;
        Stop(map { $_->[1]->gives($_->[0]) } splice @held);
    });
    is [$class->new($held_stop, $seen)->iterator(rows(5))->all],
        ['v1 <- row 1', 'v2 <- row 2', 'v3 <- row 3'], 'values it held';
};

subtest 'a value given unmarked has none' => sub {
    my @held;
    my $pairs = holding(sub {
        push @held, $_[0];
        return @held == 2 ? [splice @held] : ();
    });
    my $joined = sub { join ',', @{ $_[0] } };
    is [$class->new($pairs, $joined, $seen)->iterator(rows(4))->all],
        ['v1,v2 <- -', 'v3,v4 <- -'], 'made from many';
};

subtest "Ekorn's own: take_last, batch and collect" => sub {
    my $joined = sub { join ',', @{ $_[0] } };
    is [$class->new(take_last, $seen)->iterator(rows(3))->all],
        ['v3 <- row 3'], "take_last: the last value's, where it had none";
    is [$class->new(batch(2), $joined, $seen)->iterator(rows(3))->all],
        ['v1,v2 <- -', 'v3 <- -'], 'batch: none, where one filled had its';
    is [$class->new(collect, $joined, $seen)->iterator(rows(3))->all],
        ['v1,v2,v3 <- -'], 'collect: none, as now';
    is [$class->new(take_last)->(undef)], [undef], 'take_last of undef';
};

subtest 'an iterator read as a source' => sub {
    my $inner = $class->new(one_behind());
    is [$class->new($seen)->iterator($inner->iterator(rows(3)))->all],
        ['v1 <- row 1', 'v2 <- row 2', 'v3 <- row 3'],
        'passes on the original of the value it handed out';
    # A value from the flush of a later stage that doesn't hold values
    # back has no known original, so gets the source's latest, as before
    # (roadmap 2026-0060, D8).
    my $total = gather {
        my $n = 0;
        return (sub { $n++; $_[0] }, sub () { "total $n" });
    };
    my $totalled = $class->new(one_behind(), $total);
    is [$class->new($seen)->iterator($totalled->iterator(rows(2)))->all],
        ['v1 <- row 1', 'v2 <- row 2', 'total 2 <- row 2'],
        "a later flush's value: the source's latest, as before";
    my $plain = $class->new(sub { $_ });
    is [$class->new($seen)->iterator($plain->iterator(rows(2)))->all],
        ['v1 <- row 1', 'v2 <- row 2'], 'with no holding stage, as now';
};

subtest 'kept_origin only in a run that holds values back' => sub {
    my $croaks = qr(
        Expected\ kept_origin\ in\ the\ step\ of\ a\ stage\ that\ holds
        \ values\ back
    )x;
    like dies {
        $class->new(sub { kept_origin; $_ })->(1)
    }, $croaks, 'a map';
    like dies { kept_origin() }, $croaks, 'outside a run';
    my $nests = holding(sub {
        $class->new(sub { kept_origin; $_ })->($_[0]);
    });
    like dies { $class->new($nests)->(1) }, $croaks,
        'a run nested in its step';
    my $stops = holding(sub { Stop(kept_origin->gives("$_[0]!")) });
    my $tries = sub {
        my $inner = $class->new(sub { kept_origin; $_ });
        return (eval { $inner->($_); 1 } ? 'kept' : 'croaked') . " $_";
    };
    is [$class->new($stops, $tries)->(1, 2)], ['croaked 1!'],
        'a run nested in a stage after it, after its stop';
};

subtest 'in a flush, an origin of nothing' => sub {
    my $in_flush = holding(sub { return }, sub () { kept_origin->gives('x') });
    is [$class->new($in_flush, $seen)->(1)], ['x <- -'], 'marked, with none';
};

subtest 'by name only, and not beside a pipeline' => sub {
    my $listed = gather { (sub { $_[0] }, undef, undef) };
    is [$class->new($listed, $seen)->(1)], ['1 <- 1'], 'a list: a map, as now';
    my $object = bless {}, 'Local::Holds';
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{ 'Local::Holds::EKORN_STAGE' } = sub ($self) {
        return {step => sub { kept_origin->gives($_[0]) }, holds => 1};
    };
    is [$class->new($object, $seen)->(7)], ['7 <- 7'],
        "from a class's EKORN_STAGE";
    my $beside = gather {
        return {step => $class->new(sub { $_ }), holds => 1};
    };
    like dies { $class->new($beside)->(1) }, qr(
        \AExpected\ stage\ \#1,\ made\ with\ gather,\ to\ hold\ values\ back
        \ in\ its\ step,\ not\ in\ a\ pipeline
    )x, 'beside a pipeline, it croaks';
    my $four = gather { (sub { $_ }, undef, undef, undef) };
    like dies { $class->new($four)->(1) }, qr(
        \AExpected\ stage\ \#1,\ made\ with\ gather,\ to\ return\ a\ code
        \ reference\ or\ a\ pipeline,\ and\ optionally\ a\ flush\ and\ an\ end
    )x, "gather's message, word for word";
};

subtest 'a run ended from outside mid-step leaves nothing behind' => sub {
    my $inner_it;
    my $ends_inner = holding(sub {
        $inner_it->finish;
        my $origin = kept_origin;
        return ($origin->gives("$_[0]-a"), $origin->gives("$_[0]-b"));
    });
    my $split = sub ($x) {
        $inner_it = $class->new($ends_inner)->iterator(from_array('in'));
        $inner_it->next;
        return ("$x.a", "$x.b");
    };
    is [$class->new(take_last, $split, $seen)->iterator(rows(2))->all],
        ['v2.a <- row 2', 'v2.b <- row 2'], "the outer run's keep their own";
};

subtest 'nested in itself, in its own step' => sub {
    my $nesting = holding(sub {
        my $origin = kept_origin;
        my @inner  = $class->new(one_behind(), $seen)->iterator(rows(2))->all;
        return $origin->gives([@inner, $seen->()]);
    });
    is [$class->new($nesting)->iterator(rows(2))->all],
        [
            ['v1 <- row 1', 'v2 <- row 2', 'v1 <- row 1'],
            ['v1 <- row 1', 'v2 <- row 2', 'v2 <- row 2'],
        ],
        "a run inside its step answers for itself, and leaves its own run's";
};

done_testing;
