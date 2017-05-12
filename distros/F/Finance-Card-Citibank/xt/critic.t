use warnings;
use strict;
use Test::More;
use File::Spec;

my @MODULES = ( 'Test::Perl::Critic 0.00', );

# Load the testing modules
for my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

my $rcfile = File::Spec->catfile( 'xt', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile, -severity => 3 );
all_critic_ok( qw(lib) );
1;
# md5sum:23c26a2052cdd91f4215d9262123e362
