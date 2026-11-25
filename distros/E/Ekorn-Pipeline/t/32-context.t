use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Context (roadmap 2026-0046): what a stage can ask
# about the result it's making. result_number is the run's results so
# far, plus one, a result being a value leaving the last stage or
# reaching a sink (D2); result_original is the value the run's own
# source gave, or that was pushed, that the result is being made from,
# and undef in a flush and the stages after it (D3). Each run counts
# its own.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Context qw(result_number result_original);
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Sinks qw(keep_all);
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Flow qw(take take_if);
use Ekorn::Pipeline::Stages::Taps qw(tee);
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';

# Return a stage logging, for each value, "value:number:original", and
# passing the value on; undef is logged as "-".
sub log_into ($log) {
    return sub ($value) {
        push @$log, join ':', map { $_ // '-' } $value, result_number,
            result_original;
        return $value;
    };
}

# Return a source handing out the values given, then nothing.
sub source (@values) {
    return sub { @values ? shift @values : () };
}

# Each of a pipeline's ways of running it, by name, on the values given:
# pushed, an iterator's next and all, a feed pushed a value at a time and
# closed, and a feed pushed them all at once.
my %ways = (
    pushed => sub ($p, @values) { $p->(@values) },
    next   => sub ($p, @values) {
        my $next = $p->iterator(source(@values));
        my @got;
        while (my($value) = $next->()) { push @got, $value }
        return @got;
    },
    all  => sub ($p, @values) { $p->iterator(source(@values))->all },
    feed => sub ($p, @values) {
        my $feed = $p->feed;
        my @got;
        for my $value (@values) {
            push @got, $feed->push($value);
            last if defined $feed->ended;
        }
        push @got, $feed->close unless defined $feed->ended;
        return @got;
    },
    'feed, at once' => sub ($p, @values) {
        my $feed = $p->feed;
        my @got  = $feed->push(@values);
        push @got, $feed->close unless defined $feed->ended;
        return @got;
    },
);

# A gather with a flush, giving nothing: a stage that puts a run on the
# full loop, and passes values on.
my $full = gather { (sub { $_[0] }, sub () { () }) };

subtest 'what is exported' => sub {

    package Context::Nothing {
        use Ekorn::Pipeline::Context;
    }
    ok !Context::Nothing->can($_), "$_ not by default"
        for qw(result_number result_original);
    is [sort @Ekorn::Pipeline::Context::EXPORT_OK],
        [qw(result_number result_original)], 'both on request';
};

subtest 'a bare call is a term, as each has an empty prototype' => sub {
    is prototype(\&result_number),   '',     'result_number';
    is prototype(\&result_original), '',     'result_original';
    is result_number // 'none',      'none', "so // after one isn't a pattern";
    is [$class->new(sub { result_number + 1 })->(qw(a b))], [2, 3],
        'and + 1 after one adds, not passes it +1';
    is [$class->new(sub { result_original // 'none' })->(qw(a b))], [qw(a b)],
        'result_original too';
};

subtest 'undef outside a stage' => sub {
    is result_number,   undef, 'result_number';
    is result_original, undef, 'result_original';
};

for my $loop ('plain', 'full') {
    for my $way (sort keys %ways) {
        my $run  = $ways{$way};
        my @full = $loop eq 'full' ? ($full) : ();

        subtest "$way, $loop: each value its own result" => sub {
            my @log;
            is [$run->($class->new(@full, sub { $_[0] * 10 }, log_into(\@log)), 1 .. 3)
                ],
                [10, 20, 30], 'the values';
            is \@log, ['10:1:1', '20:2:2', '30:3:3'],
                'numbered from 1, each from its original';
        };

        subtest "$way, $loop: a value dropped makes no result" => sub {
            my @log;
            my $p = $class->new(@full, log_into(\@log), sub { $_[0] % 2 ? $_[0] : () });
            is [$run->($p, 1 .. 4)], [1, 3], 'the values';
            is \@log, ['1:1:1', '2:2:2', '3:2:3', '4:3:4'],
                'the number stays the same while values are dropped';
        };

        subtest "$way, $loop: each value a stage returns is a result" => sub {
            my @log;
            my $p = $class->new(@full, sub { ($_[0]) x $_[0] }, log_into(\@log));
            is [$run->($p, 1 .. 3)], [1, 2, 2, 3, 3, 3], 'the values';
            is \@log, ['1:1:1', '2:2:2', '2:3:2', '3:4:3', '3:5:3', '3:6:3'],
                'each numbered, from the one original';
        };

        subtest "$way, $loop: values a stop carries" => sub {
            my @log;
            my $p = $class->new(
                @full,
                sub { $_[0] == 2 ? Ekorn::Pipeline::Stop->throw('a', 'b') : $_[0] },
                log_into(\@log),
            );
            is [$run->($p, 1 .. 4)], [1, qw(a b)], 'the values';
            is \@log, ['1:1:1', 'a:2:2', 'b:3:2'],
                "the stopped value's original, numbered on";
        };
    }
}

subtest 'a flush, and the stages after it' => sub {
    for my $way (sort keys %ways) {
        my(@log, @flushed);
        my $p = $class->new(
            gather {
                my @held;
                return (
                    sub { push @held, $_[0]; () },


                    sub () {
                        push @flushed, join ':', map { $_ // '-' } result_number,
                            result_original;
                        return @held;
                    },
                );
            },
            log_into(\@log),
        );
        is [$ways{$way}->($p, 1 .. 2)], [1, 2], "$way: the values";
        is \@flushed, ['1:-'], "$way: the flush makes result 1, from no original";
        is \@log,     ['1:1:-', '2:2:-'], "$way: and its values have none";
    }

    my @log;
    my $p = $class->new(batch(2), sub { "@{$_[0]}" }, log_into(\@log));
    is [$p->(1 .. 3)], ['1 2', '3'], 'a batch';
    is \@log, ['1 2:1:2', '3:2:-'],
        "a batch filled by a value has its original; one from the flush has none";
};

subtest 'a value reaching a sink is a result' => sub {
    my @log;
    my $kept
        = $class->new(log_into(\@log), sub { $_[0] % 2 ? $_[0] : () }, keep_all)
        ->(1 .. 4);
    is $kept, [1, 3], "the sink's result";
    is \@log, ['1:1:1', '2:2:2', '3:2:3', '4:3:4'],
        'each value it took counted';
};

subtest 'each run counts its own' => sub {
    my(@outer, @inner);
    my $inner = $class->new(log_into(\@inner));
    my $p     = $class->new(
        sub { my @got = $inner->($_[0], $_[0]); $_[0] },
        log_into(\@outer),
    );
    $p->(qw(a b));
    is \@outer, ['a:1:a', 'b:2:b'],
        "a run inside a stage doesn't move its caller's count";
    is \@inner, ['a:1:a', 'a:2:a', 'b:1:b', 'b:2:b'],
        'and counts its own, each run from 1';

    (@outer, @inner) = ();
    my $reader = $class->new(sub { $_[0] * 10 }, log_into(\@inner))
        ->iterator(source(1 .. 3));
    $class->new(take_if { $_[0] > 10 }, log_into(\@outer))
        ->iterator($reader)
        ->all;
    is \@inner, ['10:1:1', '20:2:2', '30:3:3'],
        'an iterator read as a source counts its own';
    is \@outer, ['20:1:20', '30:2:30'],
        "and its reader's originals are what it handed out";

    (@outer, @inner) = ();
    $class->new(
        log_into(\@outer),
        tee(take_if { $_[0] ne 'b' }, log_into(\@inner)),
    )->(qw(a b c));
    is \@outer, ['a:1:a', 'b:2:b', 'c:3:c'], 'a tee passes every value on';
    is \@inner, ['a:1:a', 'c:2:c'], "and its branch counts its own results";
};

subtest 'nested in itself' => sub {
    my @log;
    my $p;
    $p = $class->new(
        sub ($value) {
            push @log, "outer $value:" . result_number;
            return length $value > 1 ? $value : join ',',
                $p->(map { "$value$_" } 1 .. 2);
        },
        log_into(\@log),
    );
    $p->(qw(a));
    is \@log,
        [
            'outer a:1', 'outer a1:1', 'a1:1:a1', 'outer a2:2', 'a2:2:a2',
            'a1,a2:1:a',
        ],
        'each run of the pipeline counts its own, and the outer is restored';
};

subtest 'undef again once a run ends' => sub {
    my @ends;
    my $p = $class->new(gather { (
        sub { $_[0] }, undef,
        sub ($how) { push @ends, [result_number, result_original] },
    ) });
    $p->(1, 2);
    is \@ends,        [[undef, undef]], 'in an end';
    is result_number, undef,            'after a pushed run';
    my $next = $p->iterator(source(1, 2));
    $next->();
    is result_number,   undef, "between an iterator's values";
    is result_original, undef, 'result_original too';
};

done_testing;
