use Test2::V1 -pragmas, qw( plan );

BEGIN {
  plan skip_all => 'Not release testing context'
    unless $ENV{ RELEASE_TESTING };
  plan skip_all => ".perlcriticrc not found (on purpose if you run 'make disttest' in release testing context)"
    unless -e '.perlcriticrc'
}

use Test2::Require::Module 'Test::Perl::Critic';
use Test::Perl::Critic;

Test::Perl::Critic::all_critic_ok( 'Makefile.PL', 't', 'lib', grep { -d } qw( xt bin script ) )
