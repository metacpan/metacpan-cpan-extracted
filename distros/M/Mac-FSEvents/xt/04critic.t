use strict;
use warnings;

use File::Spec;
use FindBin ();
use Test::More;

use Test::Perl::Critic;

my $rcfile = File::Spec->catfile( $FindBin::Bin, '04critic.rc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
