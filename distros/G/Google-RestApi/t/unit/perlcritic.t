use strict;
use warnings;

use File::Spec;
use English qw(-no_match_vars);
use Test::More;
use Test::Perl::Critic;

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
