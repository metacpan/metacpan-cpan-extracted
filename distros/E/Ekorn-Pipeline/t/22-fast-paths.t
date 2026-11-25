use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The fast paths (roadmap 2026-0028): a push through stages that are all
# plain steps runs in a plain loop, with no run's machinery. Each case
# here runs the same stages both ways, the plain loop, with the full
# path made to die so it can't be taken, and the full path, forced by a
# gather after them that passes each value on, with a flush that gives
# nothing, and expects the same.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Stop;
use Ekorn::Pipeline::Sinks        qw(keep_all);
use Ekorn::Pipeline::Sources      qw(from_array);
use Ekorn::Pipeline::Stages::Flow qw(take drop take_last);

my $class = 'Ekorn::Pipeline';
my $same  = gather {
    return (sub ($value) { $value }, sub () { return });
};

# Return what calling, in list context, a pipeline of @stages with
# @values gives, or its error, by the plain loop and by the full path.
sub both ($stages, @values) {
    my $plain = $class->new(@$stages);
    my $full  = $class->new(@$stages, $same);
    my @got;
    {
        no warnings 'redefine';
        local *Ekorn::Pipeline::_full_iterator = sub { die "the full path\n" };
        push @got, [eval { [$plain->(@values)] } // $@];
    }
    push @got, [eval { [$full->(@values)] } // $@];
    # The two calls are on different lines.
    for my $got (@got) {
        $got->[0] =~ s( \ line \ \d+ )( line N)x unless ref $got->[0];
    }
    return @got;
}

# Check both ways give the same, and what's expected.
sub same ($name, $stages, $values, $expected) {
    my($plain, $full) = both($stages, @$values);
    is $plain, [$expected], "$name: the plain loop";
    is $full,  $plain,      "$name: the full path, the same";
    return;
}

# A stop that isn't an array, made without throw.
package My::Hash::Stop {
    our @ISA = ('Ekorn::Pipeline::Stop');
}

subtest 'Values go through as a run takes them' => sub {
    same 'map, filter and flatMap, in order',
        [sub { $_ % 2 ? $_ : () }, sub { ($_, $_ * 10) }, sub { "<$_>" }],
        [1 .. 4], [qw(<1> <10> <3> <30>)];
    same 'none, given none', [sub { $_ }], [], [];
    same 'undef, 0 and the empty string kept', [sub { $_ }], [undef, 0, ''],
        [undef, 0, ''];
    my @values = (1, 2);
    same 'a copy of the caller\'s values', [sub { $_ = 'x'; $_[0] = 'y'; $_ }],
        \@values, [qw(x x)];
    is \@values, [1, 2], 'left alone';
};

subtest 'A stop ends the run as a run ends it' => sub {
    same 'its values going on from the step after it',
        [sub { $_ == 2 ? Stop("$_!") : $_ }, sub { "<$_>" }], [1 .. 5],
        [qw(<1> <2!>)];
    same 'and nothing else, a flatMap\'s rest dropped',
        [sub { ($_, $_ + 10) }, sub { $_ == 1 ? Stop() : $_ }], [1, 2], [];
    same 'from the last step', [sub { $_ }, sub { $_ == 3 ? Stop($_) : $_ }],
        [1 .. 5], [1, 2, 3];
    same 'a stop\'s values stopped again',
        [sub { $_ == 2 ? Stop(7, 8, 9) : $_ }, sub { $_ == 8 ? Stop() : $_ }],
        [1 .. 5], [1, 7];
    same 'a stop not an array carrying nothing',
        [sub { $_ == 2 ? die(bless {}, 'My::Hash::Stop') : $_ }], [1 .. 5], [1];
};

# Roadmap 2026-0041: a stage made for a run takes the plain loop too,
# once it's made, unless it has a flush or an end.
subtest 'A stage made for a run takes the plain loop' => sub {
    no warnings 'redefine';
    local *Ekorn::Pipeline::_full_iterator = sub { die "the full path\n" };
    is [$class->new(sub { $_ }, take(2))->(1 .. 5)], [1, 2],
        'take, made with gather';
    my $n = 0;
    is [
        $class->new(gather {
            my $i = $n++;
            sub ($value) { "$i:$value" }
        })->(qw(a b))
        ],
        [qw(0:a 0:b)], 'made once for the run';
    is [
        $class->new(gather {
            sub ($value) { $value }
        })->()
        ],
        [], 'given no values';
    is dies { $class->new(take_last)->(1 .. 3) }, "the full path\n",
        'take_last, with a flush, by the full path';
    is dies {
        $class->new(gather {
            return (sub ($v) { $v }, undef, sub ($how) { })
        })->(1)
    },
        "the full path\n", 'a stage with an end, by the full path';
    is dies {
        $class->new(sub { $_ }, keep_all)->(1)
    },
        "the full path\n", 'a sink, by the full path';
};

subtest 'A set-up that dies, pushed, is reported as before' => sub {
    my @ended;
    my $ending = gather {
        return (sub ($v) { $v }, undef, sub ($how) { push @ended, $how })
    };
    like dies {
        $class->new($ending, gather { die "no set-up\n" })->(1)
    },
        qr( \A no\ set-up \n \z )x, 'its error thrown on';
    is \@ended, ['died'], 'the end made before it told the run died';
    like dies {
        $class->new(gather { Ekorn::Pipeline::Stop->throw })->(1)
    },
        qr( \A Expected\ no\ stop\ in\ a\ set-up, )x, 'a stop in it croaks';
};

subtest 'A step that dies is named as a run names it' => sub {
    my($plain, $full) = both([sub { $_ }, sub { die "bad $_\n" }], 'x');
    like $plain->[0],
        qr( \A Pipeline\ stage\ \#2\ failed\ at\ .+:\n\ {4}bad\ x\n \z )x,
        'by its place';
    is $full->[0], $plain->[0], 'the same, by the full path';

    my $named
        = $class->new(sub { $_ }, sub { die "worse\n" })->named('fast_failing');
    ($plain, $full) = both([sub { $_ }, $named], 'x');
    like $plain->[0],
        qr( \A Pipeline\ stage\ \#2\.2\ \(main::fast_failing\#2\)\ failed\  )x,
        'and its named pipeline';
    is $full->[0], $plain->[0], 'the same, by the full path';

    my $object = bless {}, 'My::Error';
    ($plain, $full) = both([sub { die $object }], 'x');
    ref_is $plain->[0], $object, 'an exception object thrown on, unchanged';
    ref_is $full->[0],  $object, 'by the full path too';
};

subtest 'A pushed run has no context, and gives nothing from a flush' => sub {
    my @seen;
    my $inner = $class->new(sub {
        push @seen,
            [
                Ekorn::Pipeline::ending() ? 'ending' : 'not',
                Ekorn::Pipeline::run_context(),
            ];
        $_;
    });
    my $outer_source = Ekorn::Pipeline::Source->new(sub {
        my @left = (1);
        return {step => sub () { @left ? shift @left : () }, context => 'outer'};
    });
    my $outer = $class->new(
        sub { $inner->($_) },
        gather {
            return {step => sub ($v) { () }, flush => sub () { $inner->('f') }};
        },
    );
    $outer->iterator($outer_source)->all;
    is \@seen, [['not', undef], ['not', undef]],
        'in a run called from a stage, or a flush, of a run with a context';
};

subtest "all takes what the last part gives at once straight, in order" => sub {
    # all collects the values after the first that the last part returns
    # at once without queueing them; next queues them. Each gives the same.
    my $many = sub ($value) {
        map { "$value$_" } qw(a b c);
    };
    my $flush = gather {
        my @held;
        return (sub ($value) { push @held, $value; () }, sub () { splice @held });
    };
    my %stages = (
        'a last step returning several'         => [$many],
        'a last stage, full, returning several' => [$same, $many],
        "a last gather's flush"                 => [$flush],
        "a list sink's result"                  => [keep_all],
        'several, then a flush of several'      => [$many, $flush],
        'a stop carrying several, at the end'   =>
            [sub { Stop->throw('x', 'y') if $_[0] == 2; $_[0] }, $many],
    );
    for my $name (sort keys %stages) {
        my $p    = $class->new(@{ $stages{$name} });
        my $next = $p->iterator(from_array(1 .. 3));
        my @one;
        while (my($value) = $next->()) { push @one, $value }
        is [$p->iterator(from_array(1 .. 3))->all], \@one, "$name: all as next";
        is [$p->(1 .. 3)],                          \@one, "$name: pushed as next";
    }
    is [$class->new($many)->iterator(from_array(1, 2))->all],
        [qw(1a 1b 1c 2a 2b 2c)], 'in order';
};

subtest 'In scalar context, how many' => sub {
    is scalar $class->new(sub { ($_, $_) })->(1, 2), 4;
};

subtest 'A pipeline calls itself from a step' => sub {
    my $countdown;
    $countdown
        = $class->new(sub { $_ > 0 ? ($_, $countdown->($_ - 1)) : 'off' });
    is [$countdown->(2)], [2, 1, 'off'];
};

done_testing;
