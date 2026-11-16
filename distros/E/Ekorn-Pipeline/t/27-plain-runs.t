use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# A plain run, pulled (roadmap 2026-0040): an iterator whose run has no
# flush, no end of a stage's and no sink takes a shorter way, with none
# of their bookkeeping. Each case here runs the same source and stages
# both ways, the shorter way, checked to be taken, and the full path,
# forced by a gather after them that passes each value on and has an
# end, and expects the same: the values, how the run ended, what the
# source's end was told, and any error.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Iterator qw();
use Ekorn::Pipeline::Source   qw();
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';
my $same  = gather {
    return (sub ($value) { $value }, undef, sub ($how) { });
};

# A stop that isn't an array, made without throw.
package My::Hash::Stop {
    our @ISA = ('Ekorn::Pipeline::Stop');
}

# An error object, passed on as it is.
package My::Error {
    sub new ($class, $text) { return bless {text => $text}, $class }
}

# Return a source of the steps given, each called in turn for a pull,
# and then none, whose end logs how it was told the run ended.
sub source_of ($log, @steps) {
    return Ekorn::Pipeline::Source->new(sub {
        my @left = @steps;
        return (
            sub { @left ? (shift @left)->() : () },
            sub ($how) { push @$log, "source $how" },
        );
    });
}


# Return, by one way, what $read gives from an iterator of $stages over
# a source of @steps: [values or error, ended, the source's log].
sub run_one ($stages, $read, @steps) {
    my @log;
    my $next = $class->new(@$stages)->iterator(source_of(\@log, @steps));
    my $got  = eval { [$read->($next)] } // $@;
    $got =~ s( \ line \ \d+ )( line N)x unless ref $got;
    return [$got, $next->ended, \@log];
}


# Return what both ways give, the shorter way and the full path, as
# run_one does, failing unless the shorter way was taken, and only for
# the first.
sub both ($stages, $read, @steps) {
    my $taken = 0;
    my $plain;
    {
        no warnings 'redefine';
        my $shorter = \&Ekorn::Pipeline::_plain_iterator;
        local *Ekorn::Pipeline::_plain_iterator = sub (@args) {
            $taken++;
            return $shorter->(@args);
        };
        $plain = run_one($stages, $read, @steps);
        is $taken, 1, 'the shorter way is taken';
        run_one([@$stages, $same], $read, @steps);
        is $taken, 1, 'and not with a stage that has an end';
    }
    return ($plain, run_one([@$stages, $same], $read, @steps));
}


# Check both ways give the same, and what's expected.
sub same ($name, $stages, $read, $steps, $expected) {
    my($plain, $full) = both($stages, $read, @$steps);
    is $plain, $expected, "$name: the shorter way";
    is $full,  $plain,    "$name: the full path, the same";
    return;
}


# Read each value, one call at a time.
sub drain ($next) {
    my @values;
    while (my($value) = $next->()) { push @values, $value }
    return @values;
}

sub all ($next) { return $next->all }

# Read one value, then end the run from outside.
sub one_then_finish ($next) {
    my @values = $next->();
    $next->finish;
    return @values;
}

my @three = (sub { 1 }, sub { (2, 3) });

subtest 'Values go through as a run takes them' => sub {
    for my $read (\&drain, \&all) {
        same 'map, filter and flatMap, in order',
            [sub { $_ % 2 ? $_ : () }, sub { ($_, $_ * 10) }, sub { "<$_>" }],
            $read, [sub { (1, 2, 3) }, sub { 4 }],
            [[qw(<1> <10> <3> <30>)], 'done', ['source done']];
        same 'none, given none', [sub { $_ }], $read, [],
            [[], 'done', ['source done']];
        same 'a stage giving several, last', [sub { ($_, $_) }], $read, \@three,
            [[1, 1, 2, 2, 3, 3], 'done', ['source done']];
    }
    same 'no stages, read with all', [], \&all, \@three,
        [[1, 2, 3], 'done', ['source done']];
    same 'no stages, read one at a time', [], \&drain, \@three,
        [[1, 2, 3], 'done', ['source done']];
};

subtest 'A stop ends the run as a run ends it' => sub {
    for my $read (\&drain, \&all) {
        same 'a stop at a stage, carrying values on',
            [sub { $_ == 2 ? Stop($_, 20) : $_ }, sub { $_ * 10 }],
            $read, \@three, [[10, 20, 200], 'stopped', ['source stopped']];
        same 'a stop at the last stage, carrying values out',
            [sub { $_ }, sub { $_ == 2 ? Stop($_, 20) : $_ }],
            $read, \@three, [[1, 2, 20], 'stopped', ['source stopped']];
        same 'a stop made otherwise, carrying nothing',
            [sub { $_ == 2 ? die bless({}, 'My::Hash::Stop') : $_ }],
            $read, \@three, [[1], 'stopped', ['source stopped']];
        same 'a source that stops, carrying values',
            [sub { $_ * 10 }],
            $read, [sub { 1 }, sub { Stop(2, 3) }, sub { 4 }],
            [[10, 20, 30], 'done', ['source done']];
        same 'a source that stops, with no stages',
            [], $read, [sub { 1 }, sub { Stop(2, 3) }],
            [[1, 2, 3], 'done', ['source done']];
        same 'a source that stops otherwise, carrying nothing',
            [sub { $_ }], $read, [sub { 1 }, sub { die bless {}, 'My::Hash::Stop' }],
            [[1], 'done', ['source done']];
    }
};

subtest 'A run ended from outside' => sub {
    same 'with values waiting', [sub { ($_, $_) }], \&one_then_finish, \@three,
        [[1], 'stopped', ['source stopped']];
    same 'with values from the source waiting', [], \&one_then_finish,
        [sub { (1, 2) }], [[1], 'stopped', ['source stopped']];
    same 'with nothing waiting', [sub { $_ }], \&one_then_finish,
        [sub { 1 }, sub { 2 }], [[1], 'stopped', ['source stopped']];
    same 'once the source is done, with values waiting', [],
        \&one_then_finish, [sub { Stop(1, 2) }], [[1], 'stopped', ['source done']];

    my $it;
    same 'by a stage, from inside',
        [sub { $_ == 2 ? $it->finish : (); $_ }],
        sub ($next) { $it = $next; drain($next) },
        \@three, [[1], 'stopped', ['source stopped']];
    same 'by a stage, from inside, read with all',
        [sub { $_ == 2 ? $it->finish : (); $_ }],
        sub ($next) { $it = $next; $next->all },
        \@three, [[1], 'stopped', ['source stopped']];
    undef $it;
};

subtest 'What dies is reported as a run reports it' => sub {
    for my $read (\&drain, \&all) {
        same 'a stage that dies',
            [sub { $_ }, sub { $_ == 2 ? die "no\n" : $_ }], $read, \@three,
            [
                "Pipeline stage #2 failed at ${\__FILE__} line N:\n    no\n",
                'died', ['source died'],
            ];
        my $error = My::Error->new('no');
        same 'a stage that dies with an object',
            [sub { $_ == 2 ? die $error : $_ }], $read, \@three,
            [$error, 'died', ['source died']];
        same 'a source that dies', [sub { $_ }], $read,
            [sub { 1 }, sub { die "no\n" }],
            ["no\n", 'died', ['source died']];
        same 'a source that dies with an object', [], $read,
            [sub { 1 }, sub { die $error }], [$error, 'died', ['source died']];
    }
};

subtest "The source's end" => sub {
    my $source = sub ($end) {
        my @values = (1, 2);
        Ekorn::Pipeline::Source->new(sub { (sub { splice @values, 0, 1 }, $end) });
    };
    my $dies = $source->(sub ($how) {
        die "no end\n";
    });
    like dies {
        drain($class->new(sub { $_ })->iterator($dies))
    },
        qr( \A Pipeline\ end\ of\ the\ source\ failed\ at\ .*\n\ \ \ \ no\ end\n \z )x,
        'one that dies ends the run with its error';
    my $next = $class->new->iterator($source->(sub ($how) {
        die "no end\n";
    }));
    is [$next->(), $next->()], [1, 2], 'given every value first';
    ok dies { $next->() }, 'then dies';
    is [[$next->()], $next->ended], [[], 'died'], 'and the run died';

    my $context;
    $next = $class->new->iterator(Ekorn::Pipeline::Source->new(sub {
        my @values = (1);
        return (
            sub { splice @values },
            sub ($how) { $context = Ekorn::Pipeline::run_context() },
            {columns => ['a']},
        );
    }));
    drain($next);
    is $context, {columns => ['a']}, "and it's told the run's context";
};

subtest 'Within a flush, a plain run is not ending' => sub {
    my @seen;
    my $inner = $class->new(sub { push @seen, Ekorn::Pipeline::ending(); $_ });
    my $flush = sub () {
        push @seen, Ekorn::Pipeline::ending();
        return $inner->iterator(sub { 1 })->first;
    };
    my $outer = $class->new(gather {
        return (sub ($value) { () }, $flush);
    });
    is [$outer->(1)], [1], 'what the flush gives goes on';
    is \@seen, [T(), F()], 'the inner run, pulled in the flush, is not ending';
};

subtest 'A gather of a step only takes the shorter way' => sub {
    my $taken = 0;
    no warnings 'redefine';
    my $shorter = \&Ekorn::Pipeline::_plain_iterator;
    local *Ekorn::Pipeline::_plain_iterator = sub (@args) {
        $taken++;
        return $shorter->(@args);
    };
    my $n = 0;
    is [
        $class->new(gather {
            sub ($value) { $value + $n++ }
        })->(1, 1, 1)
        ],
        [1, 2, 3], 'made for the run';
    is $taken, 1, 'by the shorter way';
};

done_testing;
