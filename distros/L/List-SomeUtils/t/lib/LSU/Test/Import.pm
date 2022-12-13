package LSU::Test::Import;

use strict;
use warnings;

BEGIN {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $| = 1;
}

use Test::More;

sub run_tests {
    use_ok(
        'List::SomeUtils',
        qw(
            after
            after_incl
            all
            all_u
            any
            any_u
            apply
            before
            before_incl
            bsearch
            bsearchidx
            each_array
            each_arrayref
            false
            firstidx
            firstres
            firstval
            indexes
            insert_after
            insert_after_string
            lastidx
            lastres
            lastval
            mesh
            minmax
            mode
            natatime
            none
            none_u
            notall
            notall_u
            nsort_by
            one
            one_u
            onlyidx
            onlyres
            onlyval
            pairwise
            part
            singleton
            sort_by
            true
            uniq
        ),
        qw(
            bsearch_index
            distinct
            first_index
            first_result
            first_value
            last_index
            last_result
            last_value
            only_index
            only_result
            only_value
            zip
        )
    );
    done_testing();
}

1;

