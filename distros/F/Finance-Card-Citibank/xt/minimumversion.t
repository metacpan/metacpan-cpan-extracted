# Test that our declared minimum Perl version matches our syntax
use strict;
use warnings;
use Test::More;

my @MODULES = ( 'Perl::MinimumVersion 1.20', 'Test::MinimumVersion 0.008', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

all_minimum_version_from_metayml_ok();
1;
# md5sum:4ad0bd06ee736677dd9b2e83dfb1fca5
