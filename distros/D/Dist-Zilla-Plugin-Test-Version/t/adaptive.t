use strict;
use warnings;
use Test::More;
use Test::DZil;
use Path::Tiny;

subtest normal => sub {

  my $tzil = Builder->from_config(
    {
      dist_root    => 'corpus/a',
    },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => '1.00' },
          ['GatherDir'],
          ['Test::Version', { is_strict => 'adaptive' } ]
        ),
        'source/lib/Foo.pm' => "package Foo;\nour \$VERSION = 1.00;\n1;\n",
      }
    },
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Test::Version') } @{ $tzil->plugins };

  ok $plugin->_is_strict, "\$plugin->_is_strict = 1 (@{[ $plugin->_is_strict ]})";

  my $fn = path($tzil->tempdir)->child('build', 'xt', 'author', 'test-version.t');

  ok ( -e $fn, 'test file exists');

  note $fn->slurp_raw;

};

subtest abbynormal => sub {

  my $tzil = Builder->from_config(
    {
      dist_root    => 'corpus/a',
    },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          { version => '1.00_01' },
          ['GatherDir'],
          ['Test::Version', { is_strict => 'adaptive' } ]
        ),
        'source/lib/Foo.pm' => "package Foo;\nour \$VERSION = 1.00_01;\n1;\n",
      }
    },
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Test::Version') } @{ $tzil->plugins };

  ok !$plugin->_is_strict, "\$plugin->_is_strict = 0 (@{[ $plugin->_is_strict ]})";

  my $fn = path($tzil->tempdir)->child('build', 'xt', 'author', 'test-version.t');

  ok ( -e $fn, 'test file exists');

  note $fn->slurp_raw;

};

done_testing;
