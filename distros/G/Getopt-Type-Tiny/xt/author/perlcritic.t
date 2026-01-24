use strict;
use warnings;
use File::Spec;
use Test::More;

eval { require Test::Perl::Critic; 1 } or do {
    my $error = $@;
    my $msg   = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
};

my $rcfile = File::Spec->catfile( 'xt', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
