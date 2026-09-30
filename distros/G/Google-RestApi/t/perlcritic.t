use strict;
use warnings;

use File::Spec;
use FindBin;
use English qw(-no_match_vars);
use Test::More;

# Perl::Critic's verdict depends on which policy dists happen to be
# installed, not on this code, so this can't be run on smoke testers.
plan skip_all => 'Author test.  Set AUTHOR_TESTING=1 to run.'
  unless $ENV{AUTHOR_TESTING};

eval { require Test::Perl::Critic; 1 }
  or plan skip_all => 'Test::Perl::Critic required for this test';

my $rcfile = File::Spec->catfile( $FindBin::RealBin, 'etc', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok( "$FindBin::RealBin/../lib", "$FindBin::RealBin/unit" );
