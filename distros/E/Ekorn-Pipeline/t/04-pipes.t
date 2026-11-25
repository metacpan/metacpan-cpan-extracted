use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline;
use Ekorn::Pipeline::Pipes ();
use Ekorn::Pipeline::Sinks qw(count_items keep_all keep_first);
use Ekorn::Pipeline::Stop;

# A class of its own, with pipe and tap from Ekorn::Pipeline::Pipes.
package My::Thing {
    our @ISA = 'Ekorn::Pipeline::Pipes';


    sub new ($class) { return bless {log => []}, $class }


    sub answer ($self) { return 42 }


    sub note ($self, $note) { push @{ $self->{log} }, $note; return $self }
}

my $thing = My::Thing->new;

subtest 'the first stage is called with the object' => sub {
    my $arg = sub ($x) { $x };
    ref_is [$thing->pipe($arg)]->[0],       $thing, 'as its argument';
    ref_is [$thing->pipe(sub { $_ })]->[0], $thing, 'and in $_';
    is [$thing->pipe(sub { $_->answer })], [42], 'which it can use';
};

subtest 'with no stages, pipe returns the object' => sub {
    my @results = $thing->pipe;
    is scalar(@results), 1, 'one value';
    ref_is $results[0], $thing, 'the object';
};

subtest 'each value goes through the rest of the stages on its own' => sub {
    my @results = $thing->pipe(
        sub { (3, 4, 5) },
        sub { $_ % 2 ? $_ : () },
        sub { $_ * 2 },
    );
    is \@results, [6, 10];
};

# pipe gives what a pipeline gives, in either context (roadmap
# 2026-0053, D2). Until v0.4.0, in scalar context, it gave the first
# result, unlike a pipeline.
subtest 'in scalar context, pipe gives what a pipeline gives' => sub {
    my $count = $thing->pipe(sub { (7, 8, 9) });
    is $count, 3, 'how many came out, not the first';
    my $none = $thing->pipe(sub { () });
    is $none, 0, 'none';
    my $alone = $thing->pipe;
    is $alone, 1, 'with no stages, one: the object';
    my $first = $thing->pipe(sub { (7, 8, 9) }, keep_first);
    is $first, 7, "a sink of one's value";
    my $kept = $thing->pipe(sub { (7, 8, 9) }, keep_all);
    is $kept, [7, 8, 9], "a sink of many's list, as an array reference";
    my($read) = $thing->pipe(sub { (7, 8, 9) });
    is $read, 7, 'and one value read in list context is the first';
};

subtest 'pipe is a pipeline called with the object' => sub {
    for my $stages (
        [],
        [sub { (7, 8, 9) }],
        [sub { () }],
        [sub { (7, 8, 9) }, keep_first],
        [sub { (7, 8, 9) }, keep_all],
        [sub { (7, 8, 9) }, count_items],
        [sub { (7, 8, 9) }, sub { $_ == 8 ? Stop($_) : $_ }],
    ) {
        my $pipeline = Ekorn::Pipeline->new(@$stages);
        my @list     = $thing->pipe(@$stages);
        my $scalar   = $thing->pipe(@$stages);
        is \@list,  [$pipeline->($thing)],      'the same list';
        is $scalar, scalar $pipeline->($thing), 'the same in scalar context';
    }
};

subtest 'Stop ends the pipeline' => sub {
    my @results = $thing->pipe(
        sub { (1, 2, 3) },
        sub { $_ == 2 ? Stop('two') : $_ },
    );
    is \@results, [1, 'two'];
};

subtest 'tap returns the object' => sub {
    ref_is $thing->tap(sub { 'something else' }), $thing, 'whatever comes out';
    ref_is $thing->tap(sub { () }),               $thing, 'when nothing does';
    ref_is $thing->tap,                           $thing, 'with no stages';

    my @all = $thing->tap(sub { (1, 2, 3) });
    is scalar(@all), 1, 'and only the object, in list context';
    ref_is $all[0], $thing, 'the object';
};

subtest 'the stages of tap run for their side effects' => sub {
    my @seen;
    $thing->tap(
        sub ($x) { push @seen, ref $x; (1, 2, 3) },
        sub { $_ % 2 ? $_ : () },
        sub { push @seen, "last($_)"; $_ },
    );
    is \@seen, ['My::Thing', 'last(1)', 'last(3)'];
};

subtest 'tap carries on a chain of method calls' => sub {
    my $t = My::Thing->new;
    $t->tap(sub { $_->note('first') })->note('second');
    is $t->{log}, [qw(first second)];
};

subtest 'Stop ends the stages, and tap still returns the object' => sub {
    my @seen;
    my $object = $thing->tap(
        sub { (1, 2, 3) },
        sub { $_ == 2 ? Stop('two') : $_ },
        sub { push @seen, $_ },
    );
    ref_is $object, $thing, 'the object';
    is \@seen, [1, 'two'], 'the stages ran until the Stop';
};

subtest 'a stage that dies is reported where pipe or tap was called' => sub {
    my @stages = (sub { $_ }, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { $thing->pipe(@stages) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'pipe';

    $line = __LINE__ + 1;
    $err  = dies { $thing->tap(@stages) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'tap';
};

subtest 'a stage that is neither a code reference nor a pipeline' => sub {
    my @stages = (sub { $_ }, 'x');
    my $line   = __LINE__ + 1;
    my $err    = dies { $thing->pipe(@stages) };
    is $err,
        "Expected stage #2 to be a stage: a code reference, a pipeline, or an object offering a stage's role method at ${\ __FILE__ } line $line.\n",
        'pipe';

    $line = __LINE__ + 1;
    $err  = dies { $thing->tap(@stages) };
    is $err,
        "Expected stage #2 to be a stage: a code reference, a pipeline, or an object offering a stage's role method at ${\ __FILE__ } line $line.\n",
        'tap';
};

done_testing;
