use strict;
use warnings;
use Test::More;

plan( skip_all => 'Only run check-changes test during RELEASE_TESTING' )
    unless $ENV{RELEASE_TESTING};

my @MODULES = ( 'Test::Kwalitee 1.01 qw(-no_symlinks)', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
# md5sum:73a56b39296e3e437993541c3cca8c34
