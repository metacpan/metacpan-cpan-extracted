# Test that our META.yml file matches the specification
use strict;
use warnings;
use Test::More;

my @MODULES = ( 'Test::CPAN::Meta 0.12', );

plan( skip_all => 'Only run meta test during RELEASE_TESTING' )
    unless $ENV{RELEASE_TESTING};

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

meta_yaml_ok();
1;
# md5sum:44071620f8f7727f10e4755cb5f2d581
