use strict;
use warnings;

use Test::More import => [ qw( plan ) ];

BEGIN {
  plan skip_all => 'Not release testing context'
    unless $ENV{ RELEASE_TESTING };
  plan skip_all => ".perlcriticrc not found (on purpose if you run 'make disttest' in release testing context)"
    unless -e '.perlcriticrc'
}

use Test::Needs qw( Test::Perl::Critic );

use File::Spec::Functions qw( catfile );

Test::Perl::Critic::all_critic_ok( 'Makefile.PL', 't', 'lib', grep { -d } qw( xt bin script ) )
