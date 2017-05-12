use strict;
use warnings;
use File::Spec;
use Test::More;

eval { require Test::Perl::Critic; };

if ( $@ ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 'etc', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
