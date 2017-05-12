# Test that the syntax of our POD documentation is valid
use strict;
use warnings;
use Test::More;

my @MODULES = ( 'Pod::Simple 3.07', 'Test::Pod 1.26', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

all_pod_files_ok();
1;
# md5sum:0dfac3cf7df94d35b3981b12492206ef
