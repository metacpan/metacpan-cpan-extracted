use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Claims the reference makes that the other test files don't check, each
# subtest named for the reference's section that makes it.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Flow;
use Ekorn::Pipeline::Stop;

my $class = 'Ekorn::Pipeline';

# A subclass, for what it inherits.
package My::Pipeline {
    our @ISA = 'Ekorn::Pipeline';
}

# A module of stages whose helper, in a package of its own, croaks for
# the module's caller.
package My::Stages::Helper {
    use Ekorn::Pipeline::Errors qw(croakf);
    our @CARP_NOT = ('My::Stages::Checked');


    sub check_size ($size) {
        croakf 'Expected a size of 1 or more, not %s', $size unless $size >= 1;
        return;
    }
}

package My::Stages::Checked {
    our @CARP_NOT = ('My::Stages::Helper');


    sub chunked ($size) {
        My::Stages::Helper::check_size($size);
        return sub { $_ };
    }
}

subtest 'Calling a pipeline: from inside one of its own stages' => sub {
    my $countdown;
    $countdown = $class->new(sub { $_ > 0 ? ($_, $countdown->($_ - 1)) : $_ });
    is [$countdown->(3)], [3, 2, 1, 0];
};

subtest 'What a stage is given' => sub {
    local $_ = 'mine';
    $class->new(sub { $_ })->(1);
    is $_, 'mine', "\$_ is local to each call, so the caller's is left alone";

    my @values = (1, 2);
    $class->new(sub { $_ = 'changed' }, sub { $_[0] = 'again' })->(@values);
    is \@values, [1, 2],
        "assigning to \$_ or \$_[0] doesn't change the caller's values";

    my %track = (plays => 1);
    $class->new(sub { $_->{plays}++; $_ })->(\%track);
    is $track{plays}, 2,
        "a stage that changes a hash it's given changes the caller's";

    my @calls;
    $class->new(sub { push @calls, scalar @_; $_ })->(1, 2);
    is \@calls, [1, 1], 'always with exactly one argument';
};

subtest 'What a stage returns: a test passes on what the test returns' => sub {
    is [map { $_ ? 'true' : 'false' } $class->new(sub { $_ > 2 })->(1, 3)],
        ['false', 'true'];
};

subtest 'What a stop does' => sub {
    my @after;
    $class->new(sub { Stop($_); push @after, $_ })->(1);
    is \@after, [], "the rest of the stage that threw it doesn't run";

    my @seen;
    my $flat = $class->new(
        sub { (1, 2, 3) },
        sub { push @seen, $_; $_ == 1 ? Stop() : $_ },
    );
    is [$flat->('x', 'y')], [], 'nothing else is processed';
    is \@seen, [1], "the rest of what a stage returned as a flatMap is dropped";

    @seen = ();
    my $calls = 0;
    my $next  = $class->new(sub { push @seen, $_; $_ == 1 ? Stop($_) : $_ })
        ->iterator(sub { $calls++ ? () : (1, 2, 3) });
    my @got;
    while (my($x) = $next->()) { push @got, $x }
    is [\@got, \@seen, $calls], [[1], [1], 1],
        'and the rest of what a source returned in one call, without calling it again';
};

subtest 'ending: a pipeline run inside a stage has its own' => sub {
    my @seen;
    my $inner = $class->new(
        sub { push @seen, Ekorn::Pipeline::ending() ? 'inner ending' : 'inner'; $_ });
    $class->new(
        collect,
        sub {
            push @seen, Ekorn::Pipeline::ending() ? 'outer ending' : 'outer';
            $inner->($_);
        },
    )->(1);
    is \@seen, ['outer ending', 'inner'];
};

subtest 'take(0) sees one value first' => sub {
    my $calls = 0;
    my $next  = $class->new(take(0))->iterator(sub { $calls++; 1 });
    is [[$next->()], $calls], [[], 1], 'so the source is called once';
};

subtest 'Exports: Ekorn::Pipeline exports nothing by default' => sub {

    package My::Importer {
        use Ekorn::Pipeline;
    }
    ok !My::Importer->can('is_stage'), 'not is_stage';
};

subtest 'Pipelines: a subclass inherits import' => sub {
    ok lives { My::Pipeline->import },
        'with nothing to import, it does nothing';
    like dies { My::Pipeline->import('name') },
        qr( "name" \  is \  not \  exported \  by \  the \  My::Pipeline \  module )x,
        'and a name it doesn\'t export croaks';
};

subtest 'croakf' => sub {
    my $line = __LINE__ + 1;
    is dies { My::Stages::Checked::chunked(0) },
        "Expected a size of 1 or more, not 0 at ${\ __FILE__ } line $line.\n",
        "a helper in another package, each in the other's \@CARP_NOT, reports at the caller's line";

    package My::Percent {
        use Ekorn::Pipeline::Errors qw(croakf);
        sub fail () { croakf 'Expected 100%% or less' }
    }
    like dies { My::Percent::fail() }, qr( \A Expected\ 100%\ or\ less\  )x,
        'a % in the message is written %%';
};

done_testing;
