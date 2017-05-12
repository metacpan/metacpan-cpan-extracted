use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Test::Perl::Critic; 1 }
        or plan skip_all => 'Test::Perl::Critic required to criticise code';
};

use File::Spec;


my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );

all_critic_ok( 'scripts', 'lib' );
