#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use English qw(-no_match_vars);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import(
    -profile  => $rcfile,
    -severity => 1,
    -verbose  => 11,
);
all_critic_ok();
