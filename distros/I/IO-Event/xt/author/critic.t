use Test2::Require::Module 'Test2::Tools::PerlCritic';
use Test2::Require::Module 'Perl::Critic';
use Test2::Require::Module 'Perl::Critic::Freenode';
use Test2::V0;
use Perl::Critic;
use Test2::Tools::PerlCritic;
use File::Glob qw( bsd_glob );

my $critic = Perl::Critic->new(
  -profile => 'perlcriticrc',
);

my @tests = grep { $_ ne 't/00_diag.t' } bsd_glob('t/*.t'), bsd_glob('t/*.tt');

perl_critic_ok ['lib', @tests], $critic;

done_testing;
