use strict;
use warnings;
use utf8;

use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

if ( !eval { require Test::Perl::Critic; 1 } ) {
    plan skip_all => q{Test::Perl::Critic required for testing PBP compliance};
}
else {
	Test::Perl::Critic->import(
    	-profile => File::Spec->catfile( 't', 'perlcriticrc' ) );
	Test::Perl::Critic::all_critic_ok();
}
