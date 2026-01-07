use strict;
use warnings;

use File::Spec;
use FindBin;
use English qw(-no_match_vars);
use Test::More;
use Test::Perl::Critic;

my $rcfile = File::Spec->catfile( $FindBin::RealBin, 'etc', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok( "$FindBin::RealBin/../lib", "$FindBin::RealBin/unit" );
