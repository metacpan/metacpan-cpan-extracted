use strict;
use warnings;
use Test::More;
use Test::DZil;

subtest 'build_command' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ '@Alien' => {
            repo => 'http://localhost/foo/bar',
            exact_filename => 'foo.tar.gz',
            build_command => ['foo', 'bar'],
            test_command => ['bar','baz'],
            install_command => ['foo', 'baz'],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };
  
  ok $plugin, '[@Alien] adds [Alien]';

  is_deeply $plugin->module_build_args->{alien_repository}, { protocol => 'http', host => 'localhost', location => '/foo/bar', exact_filename => 'foo.tar.gz' }, 'alien_repository';
  is_deeply $plugin->module_build_args->{alien_build_commands}, [qw( foo bar )], 'build commands = foo bar';
  is_deeply $plugin->module_build_args->{alien_test_commands}, [qw( bar baz )], 'test commands = bar baz';
  is_deeply $plugin->module_build_args->{alien_install_commands}, [qw( foo baz )], 'install commands = foo baz';
};

done_testing;
