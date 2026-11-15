use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The run's edges, as the POD of Ekorn::Pipeline and its core modules
# describes them: what each part's set-up may return, how a run reports
# what dies in it, and the classes' own methods. The design's proofs are
# in t/15-proofs.t.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Iterator qw();
use Ekorn::Pipeline::Sink     qw();
use Ekorn::Pipeline::Sinks    qw(keep_all);
use Ekorn::Pipeline::Source   qw();
use Ekorn::Pipeline::Stage    qw();
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';

# A part of its own, offering a stage's role method, as a package
# delivering parts for Ekorn would: its stage doubles each value, and
# its end says how the run ended.
package My::Doubler {
    sub new ($class, $log) { return bless {log => $log}, $class }


    sub EKORN_STAGE ($self) {
        my $log = $self->{log};
        return (sub ($x) { $x * 2 }, undef, sub ($how) { push @$log, $how });
    }
}

# A part whose role method returns what it's given, to check what a run
# accepts from one.
package My::Returns {


    sub new ($class, $role, @made) {
        return bless {made => \@made}, "My::Returns::$role";
    }

    package My::Returns::EKORN_STAGE {
        our @ISA = 'My::Returns';
        sub EKORN_STAGE ($self) { return @{ $self->{made} } }
    }

    package My::Returns::EKORN_SINK_ONE {
        our @ISA = 'My::Returns';
        sub EKORN_SINK_ONE ($self) { return @{ $self->{made} } }
    }

    package My::Returns::EKORN_SOURCE {
        our @ISA = 'My::Returns';
        sub EKORN_SOURCE ($self) { return @{ $self->{made} } }
    }
}

# A subclass of Sink with a role method of its own, which new_sink_many
# keeps.
package My::Sink {
    our @ISA = 'Ekorn::Pipeline::Sink';
    sub EKORN_SINK_MANY ($self) { return $self->{setup}->() }
}

# A subclass of Sink with a sink of one's role method of its own.
package My::SinkOfOne {
    our @ISA = 'Ekorn::Pipeline::Sink';
    sub EKORN_SINK_ONE ($self) { return $self->{setup}->() }
}

# A pipeline whose stages method gives what can't be a stage.
package My::Odd {
    our @ISA = 'Ekorn::Pipeline';
    sub stages ($self) { return 'not a stage' }
}

# A pipeline whose stages method gives a plain code reference of its own.
package My::Plain {
    our @ISA = 'Ekorn::Pipeline';


    sub stages ($self) {
        return sub { $_ + 100 }
    }
}

# An error object, thrown as it is.
package My::Error {
    sub new ($class, $text) { return bless {text => $text}, $class }
}

package main;

# A source of the values given, made for each run, logging how it ended.
sub logged_source ($log, @values) {
    return Ekorn::Pipeline::Source->new(sub {
        my $i = 0;
        return (
            sub () { $i < @values ? $values[$i++] : () },
            sub ($how) { push @$log, $how },
        );
    });
}


# A gather passing values on, logging its flush and how the run ended,
# its flush giving @flushed.
sub logged_gather ($log, $tag, @flushed) {
    return gather {
        return (
            sub ($x) { $x },
            sub () { push @$log, "$tag flush"; @flushed },
            sub ($how) { push @$log, "$tag $how" },
        );
    };
}

subtest 'Element: call calls it, as calling it as a code reference does' =>
    sub {
        is [$class->new(sub { uc })->call('a', 'b')], ['A', 'B'];
    };

subtest 'Stage: what new takes' => sub {
    my $code  = sub { defined $_ ? 'set' : 'unset' };
    my $stage = Ekorn::Pipeline::Stage->new($code);
    is $stage->code,    exact_ref($code), 'the code, kept as it is';
    is [$stage->('a')], ['unset'],        'called directly, it sets no $_';

    my $callable = bless [], 'My::Callable';
    {

        package My::Callable;
        use overload '&{}' => sub ($self, @) {
            sub { lc }
        }, fallback => 1;
    }
    my $object = Ekorn::Pipeline::Stage->new($callable);
    is [$class->new($object)->('A')], ['a'],
        'an object called as a code reference';
    is $object->code, exact_ref($callable), 'kept as it is';

    like dies { Ekorn::Pipeline::Stage->new('uc') },
        qr( \A Expected\ a\ code\ reference\ at\ \Q${\ __FILE__ }\E )x,
        'a string croaks';
    like dies { Ekorn::Pipeline::Stage->new($class->new) },
        qr( \A Expected\ a\ code\ reference,\ not\ one\ of\ Ekorn's\ types\ at\ \Q${\ __FILE__ }\E )x,
        "and one of Ekorn's own types, saying so";
};

subtest 'Source and Sink: a set-up is a code reference' => sub {
    for my $made (
        ['Source',        sub { Ekorn::Pipeline::Source->new('x') }],
        ['new_sink_one',  sub { Ekorn::Pipeline::Sink->new_sink_one('x') }],
        ['new_sink_many', sub { Ekorn::Pipeline::Sink->new_sink_many('x') }],
    ) {
        like dies { $made->[1]->() }, qr( \A Expected\ a\ code\ reference )x,
            "$made->[0], given a string, croaks";
    }
};

subtest "Sink: a subclass's own role method keeps its class" => sub {
    my $sink = My::Sink->new_sink_many(sub {
        my @seen;
        return (sub ($x) { push @seen, $x }, sub () { reverse @seen });
    });
    isa_ok $sink, ['My::Sink'], 'new_sink_many makes the subclass';
    is [$class->new($sink)->(1, 2, 3)], [3, 2, 1];
    isa_ok(
        My::Sink->new_sink_one(sub { (sub { }, sub () { 1 }) }),
        ['Ekorn::Pipeline::Sink::One'],
        "new_sink_one makes a Sink::One, as the subclass has no EKORN_SINK_ONE",
    );
    my $one = My::SinkOfOne->new_sink_one(sub {
        my $n = 0;
        return (sub ($x) { $n++ }, sub () { $n });
    });
    isa_ok $one, ['My::SinkOfOne'], 'and the subclass, if it has';
    is scalar $class->new($one)->(1, 2, 3), 3;
};

subtest 'A part of your own, offering a role method' => sub {
    my @log;
    is [$class->new(My::Doubler->new(\@log))->(1, 2)], [2, 4],
        'goes where a stage goes';
    is \@log, ['done'], 'and its end is told how the run ended';
};

subtest 'What a set-up may return' => sub {
    my %bad = (
        EKORN_STAGE    => [[], ['x'], [sub { }, 'x']],
        EKORN_SINK_ONE =>
            [['x', sub { }], [sub { }], [sub { }, 'x'], [sub { }, sub { }, 'x']],
    );
    my %message = (
        EKORN_STAGE =>
            qr( \A Expected\ stage\ \#1\ to\ return\ a\ code\ reference,\ and\ optionally\ a\ flush\ and\ an\ end\  )x,
        EKORN_SINK_ONE =>
            qr( \A Expected\ sink\ \#1\ to\ return\ a\ code\ reference,\ a\ flush,\ and\ optionally\ an\ end\  )x,
    );
    for my $role (sort keys %bad) {
        for my $made (@{ $bad{$role} }) {
            my $part = My::Returns->new($role, @$made);
            like dies { $class->new($part)->(1) }, $message{$role},
                sprintf '%s returning %d things, not all code', $role, scalar @$made;
        }
    }
    for my $made ([], ['x'], [sub { }, 'x']) {
        my $source = My::Returns->new('EKORN_SOURCE', @$made);
        like dies { $class->new->iterator($source) },
            qr( \A Expected\ the\ source\ to\ return\ a\ code\ reference,\ and\ optionally\ an\ end\ and\ a\ context\  )x,
            sprintf 'EKORN_SOURCE returning %d things, not all code', scalar @$made;
    }
};

subtest 'A set-up that dies' => sub {
    my @log;
    my $object = My::Error->new('no');
    my $source = logged_source(\@log, 1);
    my $dies   = gather { die $object };
    is
        dies { $class->new(logged_gather(\@log, 'a'), $dies)->iterator($source) },
        exact_ref($object), 'throws its error object as it is';
    is \@log, ['died', 'a died'],
        'after the ends of what was made are told it died';

    like dies {
        $class->new(gather { die "no\n" })->(1)
    }, qr( \A no\n \z )x,
        'and its message as it is';
};

subtest 'A source that dies' => sub {
    my @log;
    my $object = My::Error->new('no');
    my $next
        = $class->new(logged_gather(\@log, 'a'))->iterator(sub { die $object });
    is dies { $next->() }, exact_ref($object),
        'throws its error object as it is';
    is \@log,       ['a died'], 'after each end is told it died';
    is [$next->()], [],         'and the run gives nothing more';

    like dies {
        $class->new->iterator(sub { die "no\n" })->()
    },
        qr( \A no\n \z )x, 'and its message as it is';
};

subtest 'A source that stops' => sub {
    my @log;
    my $calls = 0;
    my $next  = $class->new(sub { $_ * 10 }, logged_gather(\@log, 'a'))
        ->iterator(sub { $calls++ ? Stop(2, 3) : 1 });
    is [$next->(), $next->()], [10, 20], 'gives what its stop carries';
    is \@log,                  [], 'and the run goes on while any of it waits';
    is [$next->()],            [30];
    is [[$next->()], \@log], [[], ['a flush', 'a done']],
        'then ends, the stages told done';

    is [drain($class->new(sub { $_ * 10 })->iterator(sub { Stop(1, 2, 3) }))],
        [10, 20, 30], 'all it carries goes through the stages';
    is [drain($class->new->iterator(sub { Stop(1, 2, 3) }))], [1, 2, 3],
        'and is handed out, where there are none';

    my $stopped = bless {}, 'Ekorn::Pipeline::Stop';
    is [$class->new->iterator(sub { die $stopped })->()], [],
        'a stop made otherwise than with Stop carries nothing';
};

subtest 'An end that dies, in a run that had not died' => sub {
    my @log;
    my $object = My::Error->new('no');
    my $first  = gather { (
        sub ($x) { $x }, undef, sub ($how) { push @log, "a $how"; die $object },) };
    my $second = gather { (
        sub ($x) { $x }, undef,
        sub ($how) { push @log, "b $how"; die "again\n" },
    ) };
    my @warnings;
    local $SIG{__WARN__} = sub ($warning) { push @warnings, $warning };
    is dies { $class->new($first, $second)->(1) }, exact_ref($object),
        'throws its error object as it is';
    is \@log, ['a done', 'b died'],
        'once the ends after it are told the run died';
    like \@warnings,
        [
        qr( \A The\ end\ of\ stage\ \#2\ died\ while\ the\ run\ was\ already\ dying:\ again\  )x
        ],
        'and any end after it that dies is a warning';
};

subtest 'A gather returning a pipeline and only an end' => sub {
    my @log;
    my $gather = gather {
        ($class->new(sub { $_ + 1 }), undef, sub ($how) { push @log, $how });
    };
    is [$class->new($gather)->(1, 2)], [2, 3],   'runs the pipeline';
    is \@log,                          ['done'], 'and calls the end';
};

subtest 'A sink whose flush stops' => sub {
    my $sink = Ekorn::Pipeline::Sink->new_sink_many(sub {
        my @seen;
        return (sub ($x) { push @seen, $x }, sub () { Stop(@seen, 'last') });
    });
    is [$class->new($sink, sub { uc })->('a', 'b')], ['A', 'B', 'LAST'],
        'gives what its stop carries to the stages after it';
};

subtest 'A stop in a flushed value' => sub {
    my @log;
    my $stopper = gather {
        (sub ($x) { Stop("$x!") }, undef, sub ($how) { push @log, "s $how" });
    };
    my $next = $class->new(
        logged_gather(\@log, 'a', 'x', 'y'),
        logged_gather(\@log, 'b'), $stopper, logged_gather(\@log, 'c'),
    )->iterator(sub { () });
    is [drain($next)], ['x!'], "the stop's values go on";
    is \@log,
        ['a flush', 'c flush', 'a done', 'b stopped', 's stopped', 'c done'],
        'a stage with a flushed value still to come is told stopped';

    @log  = ();
    $next = $class->new(
        logged_gather(\@log, 'a', 'x'),
        logged_gather(\@log, 'b'), $stopper, logged_gather(\@log, 'c'),
    )->iterator(sub { () });
    is [drain($next)], ['x!'];
    is \@log, ['a flush', 'c flush', 'a done', 'b done', 's stopped', 'c done'],
        "one whose input ran out is told done, though its flush is passed over, "
        . 'and the stage that stopped, with a flush still to come before it, stopped';

    @log  = ();
    $next = $class->new(
        logged_gather(\@log, 'a', 'x'),
        sub { $_ }, $stopper, logged_gather(\@log, 'c'),
    )->iterator(sub { () });
    is [drain($next)], ['x!'];
    is \@log, ['a flush', 'c flush', 'a done', 's done', 'c done'],
        'and with none to come, the stage that stopped is told done';
};

subtest "A gather's pipeline whose stages method gives plain code" => sub {
    my $plain = bless {stages => [], names => []}, 'My::Plain';
    is [$class->new(gather { $plain })->(1)], [101], 'runs the code as a stage';
};

subtest "Iterator: all, with values waiting part way through the stages" =>
    sub {
        my $next = $class->new(sub { ($_, $_ * 10) }, sub { $_ + 1 })->iterator(do {
            my @values = (1, 2);
            sub { @values ? shift @values : () };
        });
        is [$next->()],  [2],         'one value';
        is [$next->all], [11, 3, 21], 'then the rest';

        $next = $class->new(sub { ($_, $_ * 10) }, sub { ($_, -$_) })->iterator(do {
            my @values = (1);
            sub { @values ? shift @values : () };
        });
        is [$next->()], [1],
        'one value, with values waiting at the end and part way';
        is [$next->all], [-1, 10, -10], 'then the rest, in order';

        $next = $class->new(keep_all)->iterator(do {
            my @values = (1, 2, 3);
            sub { @values ? shift @values : () };
        });
        is [$next->all], [1, 2, 3],
        "and a sink of many's result, all waiting at the end";
    };

subtest 'Iterator: made with new, as the run makes it' => sub {
    my @values = (1, 2, 3);
    my $ended;
    my $iterator = Ekorn::Pipeline::Iterator->new(
        sub { @values ? shift @values : () },
        sub { $ended = 'from outside' },
    );
    is [$iterator->()], [1], 'its code is called for each value';
    is [$iterator->all], [2, 3],
        'all, without a bulk function, calls it for each';
    is [$iterator->ended], [], 'ended says nothing, without a function to ask';
    is [$class->new->iterator($iterator)->()], [],
        'and it can be a source, never said to be spent';
    undef $iterator;
    is $ended, 'from outside', 'and it ends its run when let go';
};

subtest "A pipeline whose stages aren't stages" => sub {
    my $odd = My::Odd->new(sub { $_ });
    like dies { $class->new($odd) },
        qr( \A Expected\ stage\ \#1,\ a\ pipeline,\ to\ give\ only\ stages\ from\ its\ stages\ method\  )x,
        'croaks given as a stage';
};

# Return every value the iterator given has still to hand out.
sub drain ($next) {
    my @values;
    while (my($value) = $next->()) { push @values, $value }
    return @values;
}

done_testing;
