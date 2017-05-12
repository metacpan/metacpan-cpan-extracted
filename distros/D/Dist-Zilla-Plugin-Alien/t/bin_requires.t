use strict;
use warnings;
use Test::More;
use Test::DZil;

subtest 'bin_requires' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            bin_requires => [ 'Alien::foo', 'Alien::bar = 2.0' ],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is $plugin->module_build_args->{alien_bin_requires}->{"Alien::foo"}, 0, "Alien::foo = 0";
  is $plugin->module_build_args->{alien_bin_requires}->{"Alien::bar"}, '2.0', "Alien::bar = 2.0";
  is $tzil->prereqs->as_string_hash->{runtime}->{requires}->{'Alien::Base'}, '0.006', 'configure prereq';
  is $tzil->prereqs->as_string_hash->{configure}->{requires}->{'Alien::Base::ModuleBuild'}, '0.006', 'configure prereq';
  is $tzil->distmeta->{dynamic_config}, 1, 'dynamic_config';
};

done_testing;
