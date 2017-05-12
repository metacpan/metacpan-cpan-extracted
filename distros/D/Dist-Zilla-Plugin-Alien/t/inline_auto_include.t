use strict;
use warnings;
use Test::More;
use Test::DZil;

subtest 'plugin' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            inline_auto_include => [ qw( foo.h bar.h baz.h ) ],
            build_command => [ 'some command' ],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };
  is_deeply $plugin->module_build_args->{alien_inline_auto_include}, [qw( foo.h bar.h baz.h )], 'includes = foo.h bar.h baz.h';

  is $tzil->prereqs->as_string_hash->{runtime}->{requires}->{'Alien::Base'}, '0.006', 'configure prereq';
  is $tzil->prereqs->as_string_hash->{configure}->{requires}->{'Alien::Base::ModuleBuild'}, '0.006', 'configure prereq';
  is $tzil->prereqs->as_string_hash->{runtime}->{requires}->{'Alien::Base'}, '0.006', 'runtime prereq';
  is !!$tzil->distmeta->{dynamic_config}, '', 'dynamic_config';

};

done_testing;
