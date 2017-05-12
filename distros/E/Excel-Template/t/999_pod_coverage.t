use strict;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

# These are methods that need naming work
my @private_methods = qw(
    render new min max resolve deltas
    enter_scope exit_scope iterate_over_children
);

# These are method names that have been commented out, for now
# max_of total_of
# begin_page end_page

my $private_regex = do {
    local $"='|';
    qr/^(?:@private_methods)$/
};

all_pod_coverage_ok( {
    also_private => [ $private_regex ],
});
