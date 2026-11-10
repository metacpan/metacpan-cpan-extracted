use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline qw(is_stage);
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Pipes ();
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Flow;
use Ekorn::Pipeline::Stop;

package My::Pipeline {
    our @ISA = 'Ekorn::Pipeline';
}

# A pipeline whose stages method puts a stage of its own first.
package My::Prefixed {
    our @ISA = 'Ekorn::Pipeline';


    sub stages ($self) {
        return (sub { $_ + 100 }, $self->SUPER::stages);
    }
}

# A pipeline whose stages method returns what it's told to.
package My::Odd {
    our @ISA = 'Ekorn::Pipeline';

    our @STAGES;
    sub stages ($self) { return @STAGES }
}

# A pipeline whose stages method returns what it would anyway.
package My::Same {
    our @ISA = 'Ekorn::Pipeline';

    sub stages ($self) { return $self->SUPER::stages }
}

package My::Thing {
    our @ISA = 'Ekorn::Pipeline::Pipes';

    sub new ($class, $n) { return bless {n => $n}, $class }
}

my $class = 'Ekorn::Pipeline';

# Return every value an iterator hands out.
sub drain ($next) {
    my @xs;
    while (my($x) = $next->()) { push @xs, $x }
    return \@xs;
}

# Return a source handing out @xs one per call, and a reference to the
# number of times it was called.
sub source (@xs) {
    my $calls = 0;
    return sub { $calls += 1; @xs ? shift @xs : () }, \$calls;
}

subtest 'is_stage' => sub {
    ok is_stage(sub { $_ }), 'a code reference';
    ok is_stage(gather {
        sub { $_ }
        }),
        'a stage made with gather';
    ok is_stage($class->new),       'a pipeline';
    ok is_stage(My::Pipeline->new), 'a subclass of one';
    ok !is_stage($_), 'not ' . ($_ // 'undef')
        for undef, 'x', 42, [], {}, \'x', bless({}, 'My::Other');
    is is_stage(sub { }), T(), 'true';
    is is_stage('x'),     F(), 'false';
};

subtest 'a pipeline given as a stage runs as its stages would' => sub {
    my $two   = $class->new(sub { $_ % 2 ? $_ : () }, take(2));
    my $outer = $class->new($two,                     sub { $_ * 10 });
    is [$outer->(1 .. 9)], [10, 30], 'take inside takes from the whole run';
    is [$outer->stages], [$two->stages, ($outer->stages)[-1]],
        'its stages are spliced in, flat';

    # Stages that leave alone the array references batch and collect
    # hand on, so the results can be compared.
    my @kinds = (
        [sub { ref           ? $_ : $_ + 1 }],
        [sub { ref || $_ % 3 ? $_ : () }],
        [sub { ($_, $_) }],
        [take(3)],
        [drop(2)],
        [batch(2)],
        [collect],
        [sub { !ref && $_ == 4 ? Stop($_) : $_ }],
        [],
    );
    for my $front (@kinds) {
        for my $back (@kinds) {
            my $given  = $class->new($class->new(@$front), $class->new(@$back));
            my $listed = $class->new(@$front,              @$back);
            is [$given->(1 .. 7)], [$listed->(1 .. 7)],
                'the same as the stages listed';
        }
    }
    is [$class->new($class->new, sub { $_ * 2 })->(1, 2)], [2, 4],
        'an empty pipeline adds nothing';
    is [$class->new(My::Pipeline->new(take(1)))->(1, 2)], [1], 'a subclass';
    is [My::Pipeline->new($class->new(take(1)))->(1, 2)], [1],
        'or into a subclass';
};

subtest 'a stop inside stops the source' => sub {
    my($source, $calls) = source(1 .. 100);
    my $p = $class->new($class->new(take(3)), sub { $_ * 2 });
    is drain($p->iterator($source)), [2, 4, 6], 'three values';
    is $$calls,                      3,         'from three calls';
};

subtest 'state is per run' => sub {
    my $p = $class->new($class->new(take(2)));
    is [$p->(1 .. 5)], [1, 2], 'a run';
    is [$p->(6 .. 9)], [6, 7], 'and another, afresh';
    my $c = $class->new(collect);
    is [$class->new($c, $c)->(1, 2, 3)], [[[1, 2, 3]]],
        'the same pipeline given twice keeps two states';
};

subtest 'ends run in order' => sub {
    my $p = $class->new($class->new(batch(2)), sub { "@$_" });
    is [$p->(1 .. 5)], ['1 2', '3 4', '5'], 'an end inside, then a stage';
    is [$class->new(collect, $class->new(collect))->(1 .. 4)], [[[1, 2, 3, 4]]],
        'an end feeding an end inside';
};

subtest "a stop's values go on" => sub {
    my $p = $class->new(
        $class->new(sub { $_ == 3 ? Stop($_ * 10) : $_ }),
        sub { $_ + 1 },
    );
    is [$p->(1 .. 5)], [2, 3, 31];
};

subtest 'ending is true inside, when an end feeds it' => sub {
    my @seen;
    my $inner
        = $class->new(sub { push @seen, Ekorn::Pipeline::ending() ? 1 : 0; $_ });
    $class->new(collect, $inner)->(1, 2);
    is \@seen, [1];
};

subtest 'messages name a stage inside by its place in each pipeline' => sub {
    my $boom  = sub { die "boom\n" };    ## no critic (ErrorHandling::RequireCarping)
    my @tests = (
        [[sub { $_ }, $boom],                                      '2'],
        [[sub { $_ }, $class->new(sub { $_ }, sub { $_ }, $boom)], '2.3'],
        [
            [$class->new(sub { $_ }, $class->new(sub { $_ }, sub { $_ }, $boom))],
            '1.2.3',
        ],
    );
    for my $test (@tests) {
        my($stages, $name) = @$test;
        my $p    = $class->new(@$stages);
        my $line = __LINE__ + 1;
        is dies { $p->(1) },
            "Pipeline stage #$name failed at ${\ __FILE__ } line $line:\n    boom\n",
            "#$name, pushed";
        my $next = $p->iterator(sub { 1 });
        $line = __LINE__ + 1;
        is dies { $next->() },
            "Pipeline stage #$name failed at ${\ __FILE__ } line $line:\n    boom\n",
            "#$name, pulled";
    }

    my $ends
        = $class->new(sub { $_ }, $class->new(gather { (sub { () }, $boom) }));
    my $line = __LINE__ + 1;
    is dies { $ends->(1) },
        "Pipeline stage #2.1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'an end inside';

    my $bad = $class->new(sub { $_ }, $class->new(sub { $_ }, gather { 'x' }));
    $line = __LINE__ + 1;
    is dies { $bad->(1) },
        'Expected stage #2.2, made with gather, to return a code reference or a pipeline, and optionally an end function'
        . " at ${\ __FILE__ } line $line.\n",
        'a bad gather inside';

    my $spliced
        = $class->new(sub { $_ }, $class->new(sub { $_ }, $boom)->stages);
    $line = __LINE__ + 1;
    is dies { $spliced->(1) },
        "Pipeline stage #3 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'stages() splices them flat, named as such';
};

subtest 'a bad stage is refused as it was' => sub {
    my $line = __LINE__ + 2;
    is dies {
        $class->new($class->new(sub { $_ }), 'x')
    },
        "Expected stage #2 to be a code reference or a pipeline at ${\ __FILE__ } line $line.\n",
        'beside a pipeline';
    $line = __LINE__ + 2;
    is dies {
        $class->new(sub { $_ }, $class->new(sub { $_ }, 'x'))
    },
        "Expected stage #2 to be a code reference or a pipeline at ${\ __FILE__ } line $line.\n",
        'inside one, by its place there, when it is made';
};

subtest 'its stages come from its stages method' => sub {
    my $boom   = sub { die "boom\n" };                ## no critic (ErrorHandling::RequireCarping)
    my $prefix = My::Prefixed->new(sub { $_ * 2 });
    is [$class->new($prefix)->(1)], [$class->new($prefix->stages)->(1)],
        'as giving its stages would';
    is [$class->new($prefix)->(1)], [202], 'which a subclass can change';

    my $p = $class->new(
        sub { $_ },
        My::Prefixed->new($class->new(sub { $_ }, $boom)),
    );
    my $line = __LINE__ + 1;
    is dies { $p->(1) },
        "Pipeline stage #2.3 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'named by their places in what it returns, if not the stages it was made with';

    $p    = $class->new(sub { $_ }, My::Same->new($class->new(sub { $_ }, $boom)));
    $line = __LINE__ + 1;
    is dies { $p->(1) },
        "Pipeline stage #2.1.2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'or by their own names, if so';

    local @My::Odd::STAGES = (sub { $_ }, 'x');
    $line = __LINE__ + 2;
    is dies {
        $class->new(sub { $_ }, My::Odd->new)
    },
        "Expected stage #2 to be a code reference or a pipeline at ${\ __FILE__ } line $line.\n",
        'and refused if they are not code references';

    my $first = sub { $_ };
    local @My::Odd::STAGES = ($first, 'x');
    $line = __LINE__ + 2;
    is dies {
        $class->new(My::Odd->new($first, sub { $_ }))
    },
        "Expected stage #1 to be a code reference or a pipeline at ${\ __FILE__ } line $line.\n",
        'as many as it was made with, or not';

    local @My::Odd::STAGES = ($first, $boom);
    $p    = $class->new(My::Odd->new($first, $class->new(sub { $_ })));
    $line = __LINE__ + 1;
    is dies { $p->(1) },
        "Pipeline stage #1.2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'named by their places in what it returns, if as many but not the same';
};

subtest 'pipe and tap take a pipeline' => sub {
    my $thing = My::Thing->new(5);
    my $p     = $class->new(sub { $_->{n} }, sub { $_ * 2 });
    is $thing->pipe($p, sub { $_ + 1 }), 11, 'pipe';
    my $seen;
    ref_is $thing->tap($class->new(sub { $seen = $_->{n} })), $thing, 'tap';
    is $seen, 5, 'which ran it';
};

done_testing;
