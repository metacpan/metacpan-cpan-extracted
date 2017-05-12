# Test that all modules have a version number
use strict;
use warnings;
use Test::More;

my @MODULES = ( 'Test::HasVersion 0.012', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

all_pm_version_ok();
1;
# md5sum:8d446926a200eee7d06b51dcb5ac3826
