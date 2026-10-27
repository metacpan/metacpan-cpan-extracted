
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

use File::Spec;
use Test::More;

eval { require Test::Perl::Critic };
if ( $@ ) {
    plan tests => 1;
    fail( 'You must install Test::Perl::Critic to run this test' );
    exit;
}

my $rcfile = File::Spec->catfile( 'xt', 'release', 'perlcritic.rc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
