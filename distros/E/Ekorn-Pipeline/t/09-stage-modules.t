use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline;

# A module of stages under a namespace of its own, as DBIx::Squirrel's
# are, built from the same parts as the canned stages.
package My::Stages::Words {    ## no critic (Modules::ProhibitMultiplePackages)
    use Exporter qw(import);

    use Ekorn::Pipeline::Errors qw(croakf);
    use Ekorn::Pipeline::Gather qw(gather);
    use Ekorn::Pipeline::Stop   qw();

    BEGIN { our @EXPORT_OK = qw(longer_than first_words word_count) }

    # Return a stage passing on the words longer than $length.
    sub longer_than ($length) {
        croakf 'Expected a length of 0 or more, not %s', $length // 'undef'
            unless defined $length && $length =~ m( \A \d+ \z )x;
        return sub ($word) { length $word > $length ? $word : () };
    }

    # Return a stage passing on the first $count words, then stopping.
    sub first_words ($count) {
        return gather {
            my $seen = 0;
            return sub ($word) {
                Ekorn::Pipeline::Stop->throw($word) if ++$seen == $count;
                return $word;
            };
        };
    }

    # Return a stage holding the words, and passing on their count at the
    # end.
    sub word_count () {
        return gather {
            my $count = 0;
            return (sub ($word) { $count++; return }, sub () { $count });
        };
    }
}

BEGIN { My::Stages::Words->import(qw(longer_than first_words word_count)) }

my @words = qw(a pipeline of stages for any function);

subtest 'its stages work in any pipeline' => sub {
    is [Ekorn::Pipeline->new(longer_than(3))->(@words)],
        [qw(pipeline stages function)], 'a plain stage';
    my $first = Ekorn::Pipeline->new(first_words(3));
    is [$first->(@words)], [qw(a pipeline of)],
        'one made with gather, which stops';
    is [$first->(qw(x y))], [qw(x y)], 'starting afresh on each run';
    is [Ekorn::Pipeline->new(longer_than(3), word_count)->(@words)], [3],
        'and one with an end';
};

subtest 'its mistakes are reported at the line that made the stage' => sub {
    my $line = __LINE__ + 1;
    is dies { longer_than('x') },
        "Expected a length of 0 or more, not x at ${\ __FILE__ } line $line.\n";
};

subtest 'a stage of its that dies is named by its place' => sub {
    my $p    = Ekorn::Pipeline->new(longer_than(1), sub { die "no\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line = __LINE__ + 1;
    is dies { $p->('word') },
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    no\n";
};

done_testing;
