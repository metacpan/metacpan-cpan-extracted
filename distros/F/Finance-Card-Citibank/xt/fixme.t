# Check source files for FIXME statements
use strict;
use warnings;
use Test::More;

my @MODULES = ( 'Test::Fixme 0.04', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

run_tests( match => qw/\b([T]ODO|[F]IXME|[X]XXX|[B]UG)\b/,
           where => [ grep { -d } qw(lib root share t) ],
        );
1;
# md5sum:8ef6029c3a5f6c3103289ebc04b907ff
