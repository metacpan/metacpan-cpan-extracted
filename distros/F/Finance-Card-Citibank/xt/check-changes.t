# Test that Changes has an entry for current version
use warnings;
use strict;
use Test::More;

plan( skip_all => 'Only run check-changes test during RELEASE_TESTING' )
    unless $ENV{RELEASE_TESTING};

my @MODULES = ( 'Test::CheckChanges 0.08', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

ok_changes();
1;
# md5sum:b0b310655005de124f9800ef1bd5d4f6
