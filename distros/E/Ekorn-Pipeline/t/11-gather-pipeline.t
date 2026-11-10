use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Flow;
use Ekorn::Pipeline::Stop;

# A pipeline whose stages method returns what it's told to.
package My::Odd {
    our @ISA = 'Ekorn::Pipeline';

    our @STAGES;
    sub stages ($self) { return @STAGES }
}

my $class = 'Ekorn::Pipeline';

subtest 'a gather block can return a pipeline as its stage' => sub {
    my $made = 0;
    my $p    = $class->new(
        gather {
            my $n = 0;    # this run's
            $made++;
            $class->new(sub { ++$n . ":$_" }, take(2));
        },
        sub { uc },
    );
    is [$p->(qw(a b c))], ['1:A', '2:B'],
        'its stages run in place of the stage';
    is [$p->(qw(d e f))], ['1:D', '2:E'], 'made afresh on each run';
    is $made,             2,              'by calling the block for each run';

    my $calls = 0;
    my $next  = $class->new(gather { $class->new(take(2)) })
        ->iterator(sub { $calls++; 1 });
    my @got;
    while (my($x) = $next->()) { push @got, $x }
    is [\@got, $calls], [[1, 1], 2], 'a stop inside stops the source';

    my $run    = 0;
    my $choose = $class->new(gather {
        $class->new(++$run % 2 ? sub { 'odd run' } : sub { 'even run' })
    });
    is [$choose->(1), $choose->(1)], ['odd run', 'even run'],
        'and which pipeline can be chosen on each run';
};

subtest 'its end function' => sub {
    my @log;
    my $stage = gather {
        (
            $class->new(batch(2), sub { push @log, "in @$_"; "@$_" }),
            sub { push @log, 'end'; 'END' },
        );
    };
    is [$class->new($stage, sub { "<$_>" })->(1 .. 3)],
        ['<1 2>', '<3>', '<END>'],
        'goes through the stages after it';
    is \@log, ['in 1 2', 'in 3', 'end'], 'after the inner ends';

    is [$class->new(gather { ($class->new, sub { 'E' }) })->(1, 2)],
        [1, 2, 'E'],
        'even with an empty pipeline';
    is [$class->new(gather { $class->new })->(1, 2)], [1, 2],
        'and an empty pipeline without one passes values on';
};

subtest 'its stages are named inside it' => sub {
    my $boom = sub { die "boom\n" };    ## no critic (ErrorHandling::RequireCarping)
    my $p    = $class->new(
        sub { $_ },
        gather {
            $class->new(sub { $_ }, $boom)
        },
    );
    my $line = __LINE__ + 1;
    is dies { $p->(1) },
        "Pipeline stage #2.2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'by their position in each';

    my $end = $class->new(gather { ($class->new(sub { $_ }), $boom) });
    $line = __LINE__ + 1;
    is dies { $end->(1) },
        "Pipeline stage #1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'and its end by the gather stage';
};

subtest 'what it may return' => sub {
    my $msg
        = 'Expected stage #1, made with gather, to return a code reference or a pipeline, and optionally an end function';
    my @bad = (
        ['a pipeline and something else', sub { ($class->new, 'x') }],
        [
            'something else and an end',
            sub { ('x', sub { }) },
        ],
        [
            'three things',
            sub { ($class->new, sub { }, sub { }) },
        ],
    );
    for my $test (@bad) {
        my($name, $block) = @$test;
        my $p    = $class->new(gather { $block->() });
        my $line = __LINE__ + 1;
        is dies { $p->(1) }, "$msg at ${\ __FILE__ } line $line.\n", $name;
    }

    local @My::Odd::STAGES = (sub { $_ }, 'x');
    my $odd  = $class->new(gather { My::Odd->new });
    my $line = __LINE__ + 1;
    is dies { $odd->(1) }, "$msg at ${\ __FILE__ } line $line.\n",
        'a pipeline whose stages method returns something not a code reference';
};

done_testing;
