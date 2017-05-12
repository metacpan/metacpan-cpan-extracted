use strict;
use warnings;
use Test::More;
use Test::DZil;

subtest 'msys on' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            msys => 1,
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is $plugin->module_build_args->{alien_msys}, 1, "aien_msys = 1";
  is $tzil->prereqs->as_string_hash->{runtime}->{requires}->{'Alien::Base'}, '0.006', 'runtime prereq';
  is $tzil->prereqs->as_string_hash->{configure}->{requires}->{'Alien::Base::ModuleBuild'}, '0.006', 'configure prereq';
  is $tzil->distmeta->{dynamic_config}, 1, 'dynamic_config';
};

subtest 'msys off' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is $plugin->module_build_args->{alien_msys}, undef, "aien_msys = undef";
};

subtest 'msys from %c' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            build_command => '%c',
          } ],
        ),
      },
    }
  );

  $tzil->build;

  is $tzil->distmeta->{dynamic_config}, 1, 'dynamic_config';

};

done_testing;
