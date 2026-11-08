use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Stop;

package My::Stop {
    our @ISA = 'Ekorn::Pipeline::Stop';
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

subtest 'new checks its stages' => sub {
    my $p = $class->new(sub { $_ });
    isa_ok $p, [$class], 'a pipeline';
    ok ref($p) && $p->can('iterator'), 'with an iterator method';
    my $msg = qr( Expected\ stage\ \#2\ to\ be\ a\ code\ reference )x;
    my $at  = qr( at\ \Q${\ __FILE__ }\E\ line\ \d+ )x;
    like dies {
        $class->new(sub { $_ }, 'x')
    }, qr( \A $msg \ $at \. \n \z )x,
        'croaks on a stage that is not a code reference, naming it';
};

subtest 'a stage sees one value, in $_ and as its argument' => sub {
    my @seen;
    my $p = $class->new(sub ($x) {
        push @seen, [$_, $x];
        $x;
    });
    $p->(1, 2);
    is \@seen, [[1, 1], [2, 2]];
};

subtest 'stages map, filter and flatMap' => sub {
    is [$class->new(sub { $_ * 10 })->(1, 2, 3)],         [10, 20, 30], 'map';
    is [$class->new(sub { $_ % 2 ? () : $_ })->(1 .. 6)], [2,  4,  6],  'filter';
    is [$class->new(sub { ($_, $_ + 1) }, sub { $_ * 10 })->(1)], [10, 20],
        'flatMap, then map';
    is [$class->new(sub { $_ })->(1, undef, 3)], [1, undef, 3],
        'undef is a value';
};

subtest 'in scalar context, a pipeline returns how many results' => sub {
    my $n = $class->new(sub { $_ % 2 ? () : ($_, $_) })->(1 .. 6);
    is $n, 6, 'after a filter and a flatMap';
    $n = $class->new(sub { () })->(1 .. 3);
    is $n, 0, 'none';
    $n = $class->new->(1, undef, 3);
    is $n, 3, 'with no stages';
    $n = $class->new(sub { $_ == 3 ? Stop($_) : $_ })->(1 .. 9);
    is $n, 3, 'with a stop';
};

subtest 'stages returns the stages, to splice into another pipeline' => sub {
    my($double, $odd) = (sub { $_ * 2 }, sub { $_ % 2 ? $_ : () });
    my $p = $class->new($odd, $double);
    is [$p->stages], [exact_ref($odd), exact_ref($double)], 'in order';
    my $n = $p->stages;
    is $n,                    2,  'how many, in scalar context';
    is [$class->new->stages], [], 'none';

    my @stages = $p->stages;
    push @stages, sub { die "not this\n" };    ## no critic (ErrorHandling::RequireCarping)
    is [$p->(1 .. 4)], [2, 6], 'a copy: the pipeline is unchanged';

    my $taken = 0;
    my $two   = $class->new(gather {
        my $n = 0;
        sub { $taken++; ++$n <= 2 ? $_ : Stop() }
    });
    my $outer = $class->new($two->stages, sub { $_ * 10 });
    is [$outer->(1 .. 5)], [10, 20], 'spliced, a stop ends the run';
    is $taken,             3,        'and nothing more is fetched';
    is [$outer->(6 .. 9)], [60, 70], 'each run starts the gather afresh';
    is [$class->new($two->stages, $two->stages)->(1 .. 5)], [1, 2],
        'given twice, each keeps its own state';
    is [$two->(7, 8, 9)], [7, 8], 'and the pipeline still runs on its own';
};

subtest 'each value goes through every stage before the next starts' => sub {
    my @log;
    my $p = $class->new(
        sub { push @log, "s1($_)"; ("${_}a", "${_}b") },
        sub { push @log, "s2($_)"; $_ },
        sub { push @log, "s3($_)"; $_ },
    );
    is [$p->('x')], ['xa', 'xb'], 'values come out in order';
    is \@log,       [qw(s1(x) s2(xa) s3(xa) s2(xb) s3(xb))], 'depth-first';
};

subtest 'with no stages, values come back as they are' => sub {
    my $p = $class->new;
    is [$p->(1, undef, 3)], [1, undef, 3], 'pushed';
    my($src) = source(1, 2);
    is drain($p->iterator($src)), [1, 2], 'pulled';
};

subtest 'Stop keeps the values already out' => sub {
    my $p = $class->new(
        sub { ($_ * 10, $_ * 10 + 5) },
        sub { Stop() if $_ == 15; $_ + 1 },
    );
    is [$p->(1, 2)], [11], 'Stop';

    my $q = $class->new(sub { My::Stop->throw if $_ == 2; $_ });
    is [$q->(1, 2, 3)], [1], 'a subclass of Stop';
};

subtest 'the values a Stop carries go through the rest of the stages' => sub {
    my $p = $class->new(
        sub { $_ == 3 ? Stop("found $_", undef) : $_ },
        sub { defined ? "<$_>"                  : 'none' },
    );
    is [$p->(1 .. 9)], ['<1>', '<2>', '<found 3>', 'none'], 'pushed';

    my($src, $calls) = source(1 .. 9);
    my $next = $p->iterator($src);
    is drain($next), ['<1>', '<2>', '<found 3>', 'none'], 'pulled';
    is $$calls,      3,  'without calling the source again';
    is [$next->()],  [], 'and stays done';

    my $q = $class->new(
        sub { $_ == 2  ? Stop($_, 99) : $_ },
        sub { $_ == 99 ? Stop('last') : $_ },
    );
    is [$q->(1 .. 4)], [1, 2, 'last'], 'a later stage can stop them in turn';

    # Not made by throw, so not an array: a stop that carries nothing
    my $r = $class->new(sub { $_ == 2 ? die(bless {}, 'My::Stop') : $_ });
    is [$r->(1 .. 4)], [1], 'a stop that is not an array carries nothing';
};

subtest 'iterator hands out one value per call' => sub {
    my @log;
    my $p = $class->new(
        sub { push @log, "s1($_)"; ("${_}a", "${_}b") },
        sub { push @log, "s2($_)"; $_ },
    );
    my($src, $calls) = source(qw(x y));
    my $next = $p->iterator($src);

    is [$next->()], ['xa'],             'the first value';
    is \@log,       [qw(s1(x) s2(xa))], 'running only the stages it needed';
    is $$calls,     1,                  'after one call of the source';

    is drain($next), [qw(xb ya yb)], 'then the rest, in order';
    is [$next->()],  [],             'then nothing';
};

subtest 'iterator takes several values from one call of the source' => sub {
    my $once = 0;
    my $next
        = $class->new(sub { $_ * 2 })->iterator(sub { $once++ ? () : (1, 2, 3) });
    is drain($next), [2, 4, 6];
};

subtest 'iterator stops calling the source after Stop' => sub {
    my($src, $calls) = source(1 .. 6);
    my $next = $class->new(sub { Stop() if $_ == 3; $_ })->iterator($src);
    is drain($next), [1, 2], 'the values before the Stop';
    is $$calls,      3,      'the source was called no more';
    is [$next->()],  [],     'and stays done';
    is $$calls,      3,      'without calling it again';
};

subtest 'iterator checks its source' => sub {
    my $line = __LINE__ + 1;
    is dies { $class->new->iterator('x') },
        "Expected a code reference at ${\ __FILE__ } line $line.\n";
};

subtest 'a stage that dies says which it was' => sub {
    my $p    = $class->new(sub { $_ }, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line = __LINE__ + 1;
    my $err  = dies { $p->(1) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'pushed';

    my $next = $p->iterator(sub { 1 });
    $line = __LINE__ + 1;
    $err  = dies { $next->() };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'pulled';

    my $obj  = bless {}, 'My::Error';
    my $dies = $class->new(sub { die $obj });    ## no critic (ErrorHandling::RequireCarping)
    ref_is dies { $dies->(1) }, $obj, 'an exception object is passed on';
};

subtest 'a stage that dies ends the iterator' => sub {
    my @tests = (
        ['with a message', sub { die "boom\n" }],                 ## no critic (ErrorHandling::RequireCarping)
        ['with an object', sub { die bless {}, 'My::Error' }],    ## no critic (ErrorHandling::RequireCarping)
    );
    for my $test (@tests) {
        my($name, $die) = @$test;
        my($calls, $ends, @queue) = (0, 0, 1 .. 5);
        my $p = $class->new(
            sub ($n) { $n == 2 ? $die->() : ($n, $n * 10) },      # 1 gives 1 and 10; 2 dies
            gather { (sub { $_ }, sub { $ends++; 'end' }) },
        );
        my $next = $p->iterator(sub { $calls++; @queue ? shift @queue : () });
        is [$next->()], [1],  "$name: a value before";
        is [$next->()], [10], "$name: its sibling";
        ok dies { $next->() }, "$name: the stage dies";
        is [$next->()], [], "$name: then the iterator has ended";
        is [$next->()], [], "$name: and stays ended";
        is $calls,      2,  "$name: the source isn't called again";
        is $ends,       0,  "$name: and no end is called";
    }

    my $p = $class->new(
        sub ($n) { $n == 1 ? ($n, 'x')  : $n },
        sub { $_ eq 'x'    ? die("x\n") : $_ },
    );    ## no critic (ErrorHandling::RequireCarping)
    my @queue = 1 .. 3;
    my $next  = $p->iterator(sub { @queue ? shift @queue : () });
    is [$next->()], [1], 'a flatMap: the first value';
    ok dies { $next->() }, 'its sibling dies';
    is [$next->()], [], 'and nothing waiting goes on';
};

subtest 'iterator over a filehandle' => sub {
    my $text = "From: a\nTo: b\n\nHello,\nthere\n";
    open my $fh, '<', \$text or die "Can't open a string: $!";
    my $reads = 0;
    my $next  = $class->new(
        sub { m( \S )x ? $_ : Stop() },
        sub ($line) { split m( :\ )x, $line =~ s( \n \z )()xr },
    )->iterator(sub { $reads += 1; scalar(<$fh>) // () });

    is drain($next), [qw(From a To b)], 'split, up to the blank line';
    is $reads,       3,                 'without reading the lines after';
    close $fh;
};

subtest 'ending is true only for the values an end gives' => sub {
    my @seen;
    my $end = gather {
        (sub { push @seen, "stage($_)"; $_ }, sub { 'end' });
    };
    my $p = $class->new(
        $end,
        sub { push @seen, "$_: " . (Ekorn::Pipeline::ending() ? 1 : 0); $_ },
    );
    is [$p->(1, 2)], [1, 2, 'end'], 'the values, then the end';
    is \@seen, ['stage(1)', '1: 0', 'stage(2)', '2: 0', 'end: 1'],
        'true in the stages after an end, for what it gives';
    ok !Ekorn::Pipeline::ending(), 'and false outside a pipeline';
};

done_testing;
