# $Id: 13_critic.t 116 2009-08-02 20:43:55Z roland $
# $Revision: 116 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/13_critic.t $
# $Date: 2009-08-02 22:43:55 +0200 (Sun, 02 Aug 2009) $

use strict;
use warnings;
use utf8;

use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
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
