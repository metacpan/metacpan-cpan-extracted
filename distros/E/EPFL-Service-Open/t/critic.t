# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# See the LICENSE file for more details.

use strict;
use warnings;

use File::Spec;
use English qw(-no_match_vars);

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
  plan( skip_all => 'Author tests not required for installation' );
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
  plan( skip_all => 'Test::Perl::Critic required to criticise code' );
}

my $rcfile = File::Spec->catfile('.perlcriticrc');
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok( 'bin', 'lib' );
