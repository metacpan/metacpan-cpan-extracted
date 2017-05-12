use strict;
use warnings;
use Test::More;
use Test::DZil;

subtest 'simple' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            env => [ "BAR = 1" ],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is_deeply $plugin->module_build_args->{alien_env}, { BAR => '1' };
  is_deeply $plugin->module_build_args->{requires}->{"Alien::Base"}, '0.027';
  is_deeply $plugin->module_build_args->{configure_requires}->{"Alien::Base::ModuleBuild"}, '0.027';
};

done_testing;
