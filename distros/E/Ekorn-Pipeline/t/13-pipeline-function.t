use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;
use experimental qw(builtin);

# pipeline(), from Factories, pipeline_in, named pipelines, kept per
# package, and a pipeline given last as stages (roadmap 2026-0011, moved
# to Factories by 2026-0021).

use Ekorn::Pipeline            qw(is_stage);
use Ekorn::Pipeline::Factories qw(pipeline gather);
use Ekorn::Pipeline::Stages::Flow;

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;
my $same  = sub { $_ };

# A subclass, for named and pipeline_in on a class of your own.
package My::Pipeline {
    our @ISA = 'Ekorn::Pipeline';
}

subtest 'pipeline: makes a new pipeline from stages' => sub {
    my $p = pipeline(sub { $_ * 2 }, take(2));
    isa_ok $p, $class;
    is [$p->(1 .. 5)],       [2, 4], 'which runs values through them';
    is [pipeline()->(1, 2)], [1, 2], 'with none, values come out unchanged';
    isnt pipeline(),         pipeline(), 'a new one each time';

    my $inner = pipeline(sub { $_ + 1 });
    is [pipeline($inner, sub { $_ * 10 })->(1, 2)], [20, 30],
        'a pipeline given is spliced in, as new does';
};

subtest 'named: on the class, defines a pipeline from stages' => sub {
    my $p = $class->named(doubled => sub { $_ * 2 });
    isa_ok $p, $class;
    is [$p->(1, 2)], [2, 4], 'and returns it';
    is pipeline('doubled'), object { prop blessed => $class },
        'which pipeline finds by its name';
    is [pipeline('doubled')->(3)], [6], 'and runs';
    is [pipeline('doubled' => take(1))->(1, 2)], [2],
        'with more stages after it';
    is [pipeline(sub { $_ + 1 }, 'doubled')->(1)], [4],
        'or before it';

    isa_ok(My::Pipeline->named(tripled => sub { $_ * 3 }), 'My::Pipeline');
};

subtest 'named: on a pipeline, names that one' => sub {
    my $p = pipeline(sub { $_ * 4 });
    ref_is $p->named('quadrupled'), $p, 'and returns it';
    is [pipeline('quadrupled')->(1)], [4], 'which pipeline finds';
    ok lives { $p->named('quadrupled') }, 'naming it again is no mistake';
};

subtest 'named: its stages can name other pipelines' => sub {
    $class->named(trimmed  => sub { s( \A \s+ | \s+ \z )()xgr });
    $class->named(nonempty => sub { length ? $_ : () });
    $class->named(cleaned  => 'trimmed', 'nonempty');
    is [pipeline('cleaned')->(' a ', '  ', 'b')], ['a', 'b'];
};

subtest 'A name is resolved when the pipeline is made' => sub {
    my $line = __LINE__ + 1;
    is dies { pipeline('not_yet') },
        "No pipeline named main::not_yet at $file line $line.\n",
        'so a name not yet defined fails then';
    is dies { $class->named(early => 'not_yet') },
        "No pipeline named main::not_yet at $file line ${\ ($line + 3) }.\n",
        'in named too';

    my $p = $class->named(fixed => sub { 'old' });
    my $q = pipeline('fixed');
    like dies {
        $class->named(fixed => sub { 'new' })
    },
        qr( \A A\ pipeline\ named\ main::fixed\ is\ already\ defined\ at\ )x,
        "and a name can't be defined again";
    is [$q->(1)], ['old'], 'so a pipeline made never sees another';
};

subtest 'Names are kept per package' => sub {

    package My::Music {
        use Ekorn::Pipeline::Factories qw(pipeline);
        Ekorn::Pipeline->named(loud => sub { uc });
        sub find ($name) { pipeline($name) }
    }
    is [My::Music::find('loud')->('a')], ['A'],
        'a name is looked up in the caller\'s package';
    like dies { pipeline('loud') }, qr( \A No\ pipeline\ named\ main::loud\ )x,
        'and not in another';
    is [pipeline('My::Music::loud')->('b')], ['B'],
        'unless it\'s qualified';

    $class->named('My::Music::soft' => sub { lc });
    is [My::Music::find('soft')->('C')], ['c'],
        'named can define in another package with a qualified name';

    package My::Other {
        use Ekorn::Pipeline::Factories qw(pipeline);
        Ekorn::Pipeline->named(loud => sub { "$_!" });
    }
    is [pipeline('My::Other::loud')->('d')], ['d!'],
        'so the same name in two packages names two pipelines';
};

subtest 'Names are the package\'s, whatever class defined them' => sub {
    My::Pipeline->named(sub_named => sub { "sub $_" });
    is [pipeline('sub_named')->('x')], ['sub x'],
        "a subclass's name is found by Factories' pipeline";
    like dies {
        $class->named(sub_named => sub { $_ })
    },
        qr( \A A\ pipeline\ named\ main::sub_named\ is\ already\ defined\  )x,
        'and is the same name as any class\'s';
};

subtest 'pipeline_in: the one method reading names' => sub {
    $class->named('My::Place::here' => sub { "here $_" });
    my $p = $class->pipeline_in('My::Place', 'here', take(1));
    isa_ok $p, $class;
    is [$p->('a', 'b')], ['here a'], 'looks names up in the package given';
    isa_ok $class->pipeline_in('My::Place'), $class;
    isa_ok(
        My::Pipeline->pipeline_in('My::Place', 'here'), ['My::Pipeline'],
        "and makes its invocant's class",
    );
    like dies { $class->pipeline_in('main', 'here') },
        qr( \A No\ pipeline\ named\ main::here\  )x,
        'and nowhere else';
};

subtest 'pipeline_in: one name alone gives the pipeline it names (2026-0029)' =>
    sub {
        my $here = $class->named('My::Alone::here' => sub { "here $_" });
        ref_is $class->pipeline_in('My::Alone', 'here'), $here, 'itself';
        ref_is pipeline('My::Alone::here'), $here, 'by the word pipeline too';
        ref_is $class->pipeline_in('My::Alone', 'My::Alone::here'), $here,
        'qualified or not';
        isnt $class->pipeline_in('My::Alone', 'here', take(1)), $here,
        'a new one, given more';
        isnt $class->pipeline_in('My::Alone', $here), $here,
        'and given a pipeline, not its name';
        my $made = My::Pipeline->pipeline_in('My::Alone', 'here');
        isnt $made, $here, 'a new one, if the class is not the invocant\'s';
        isa_ok $made, ['My::Pipeline'], 'of the invocant\'s class';
        is [$made->('a')], ['here a'], 'holding it';
        my $mine = My::Pipeline->named('My::Alone::mine' => sub { $_ });
        ref_is $class->pipeline_in('My::Alone', 'mine'), $mine,
        'but itself, if it is of a subclass';
        my $alias = $class->named('My::Alone::alias' => 'My::Alone::here');
        isnt $alias, $here, 'named always makes a new one, so a name never aliases';
    };

subtest 'Ekorn::Pipeline no longer exports pipeline' => sub {
    like dies { Ekorn::Pipeline->import('pipeline') },
        qr( "pipeline" \  is \  not \  exported )x,
        'it comes from Factories';
};

subtest 'What isn\'t a stage or a name croaks' => sub {
    my $line = __LINE__ + 1;
    is dies { pipeline($same, 'not a name') },
        "Expected stage #2 to be a stage: a code reference, a pipeline or its name, or an object offering a stage's role method at $file line $line.\n",
        'in pipeline, at the caller\'s line';
    for my $bad (undef, '', '1 2', '42', 'a::', '::a', 'a::1', [], {}) {
        like dies { pipeline($bad) },
            qr( \A Expected\ stage\ \#1\ to\ be\ a\ stage:\ a\ code\ reference,\ a\ pipeline\ or\ its\ name,\ or\ an\ object\ offering\ a\ stage's\ role\ method\  )x,
            'not ' . (defined $bad ? "'$bad'" : 'undef');
    }
    like dies {
        $class->named(bad => sub { $_ }, 42)
    },
        qr( \A Expected\ stage\ \#2\ to\ be\ a\ stage:\ a\ code\ reference,\ a\ pipeline\ or\ its\ name,\ or\ an\ object\ offering\ a\ stage's\ role\ method\  )x,
        'in named, counting the stages after the name';
    ok !is_stage('doubled'), 'and is_stage stays false for a name';
    like dies { $class->new('doubled') },
        qr( \A Expected\ stage\ \#1\ to\ be\ a\ stage:\ a\ code\ reference,\ a\ pipeline,\ or\ an\ object\ offering\ a\ stage's\ role\ method\  )x,
        'as new reads no names';
};

subtest 'named croaks on what isn\'t a name' => sub {
    my $line = __LINE__ + 1;
    is dies { $class->named('a b' => $same) },
        "Expected a name, made of words joined by :: at $file line $line.\n",
        'at the caller\'s line';
    for my $bad (undef, '', 'a::', sub { $_ }) {
        like dies { $class->named($bad) },
            qr( \A Expected\ a\ name,\ made\ of\ words\ joined\ by\ ::\  )x,
            'not ' . (defined $bad ? "'$bad'" : 'undef');
    }
    $line = __LINE__ + 1;
    is dies { pipeline()->named(extra => $same) },
        "Expected only a name, naming a pipeline you have at $file line $line.\n",
        'and on a pipeline, on stages after the name';
};

subtest 'A pipeline given last is stages' => sub {

    # A function whose values are code references, taking stages as a
    # pipeline given last.
    my $call_all = sub (@args) {
        my $stages
            = @args && $args[-1] isa 'Ekorn::Pipeline' ? pop @args : pipeline();
        return $stages->(map { $_->() } @args);
    };
    my @callbacks = (sub { 1 }, sub { 2 }, sub { 3 });
    is [$call_all->(@callbacks)], [1, 2, 3], 'without one, every value';
    is [$call_all->(@callbacks, pipeline(sub { $_ * 10 }, take(2)))], [10, 20],
        'with one, its stages, telling them from the values';
};

subtest 'name: the first name a pipeline was given, qualified' => sub {
    my $p = pipeline(sub { $_ });
    is $p->name, undef, 'none, until it is named';
    $p->named('first_name');
    $p->named('My::Place::second_name');
    is $p->name, 'main::first_name', 'then the first, qualified';
    is $class->named(own_name => sub { $_ })->name, 'main::own_name',
        'as named on the class gives it';
};

subtest 'A stage in a named pipeline is named with it in errors (2026-0013)' =>
    sub {
        $class->named(
            failing => sub { $_ },
            sub { die "bad $_\n" if $_ eq 'x'; $_ },
        );
        my $line = __LINE__ + 1;
        is dies { pipeline('failing')->('x') },
        "Pipeline stage #2 (main::failing#2) failed at $file line $line:\n    bad x\n",
        'by its place, then the pipeline\'s name and its place in it';
        like dies {
            $class->new(sub { $_ }, pipeline('failing'))->('x')
        },
        qr( \A Pipeline\ stage\ \#2\.2\ \(main::failing\#2\)\ failed\  )x,
        'however deep it is';
        like dies {
            $class->named(outer_named => sub { $_ }, 'failing')->('x')
        },
        qr( \A Pipeline\ stage\ \#2\.2\ \(main::failing\#2\)\ failed\  )x,
        'by the innermost named pipeline';
        like dies {
            $class->new(gather { pipeline('failing') })->('x')
        },
        qr( \A Pipeline\ stage\ \#1\.2\ \(main::failing\#2\)\ failed\  )x,
        'a gather\'s too';
        my $direct = $class->new(sub { die "direct\n" })->named('direct_run');
        like dies {
            $direct->iterator(sub { 1 })->()
        },
        qr( \A Pipeline\ stage\ \#1\ \(main::direct_run\#1\)\ failed\  )x,
        'and the pipeline run itself, pulled';
        like dies {
            $class->new(sub { die "plain\n" })->(1)
        },
        qr( \A Pipeline\ stage\ \#1\ failed\  )x,
        'but an unnamed one by its place alone, as before';

        my $later = $class->new(sub { die "later\n" });
        my $outer = $class->new($later);
        $later->named('named_later');
        like dies { $outer->(1) },
        qr( \A Pipeline\ stage\ \#1\.1\ \(main::named_later\#1\)\ failed\  )x,
        'by the name it has when the stage dies';

        my $ending
        = $class->new(gather { (sub { $_ }, undef, sub ($how) { die "end\n" }) })
        ->named('ending_run');
        like dies { $ending->(1) },
        qr( \A Pipeline\ end\ of\ stage\ \#1\ \(main::ending_run\#1\)\ failed\  )x,
        'an end that dies, too';
    };

subtest 'A pipeline is freed when let go, though its run names it' => sub {
    my $p    = $class->new(sub { $_ });
    my $weak = $p;
    builtin::weaken($weak);
    undef $p;
    is $weak, undef;
};

subtest 'A named pipeline\'s gather stages start afresh on each run' => sub {
    $class->named(
        numbered => gather {
            my $n = 0;
            sub { ++$n . ":$_" }
        },
    );
    is [pipeline('numbered')->('a', 'b')], ['1:a', '2:b'];
    is [pipeline('numbered')->('c')],      ['1:c'];
};

done_testing;
