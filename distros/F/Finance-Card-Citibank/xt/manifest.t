# Test that the module MANIFEST is up-to-date
use strict;
use warnings;
use Test::More;

my @MODULES = ( 'Test::DistManifest 1.003', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

manifest_ok();
1;
# md5sum:92c3293107898bd1284783c3475a8d5c
