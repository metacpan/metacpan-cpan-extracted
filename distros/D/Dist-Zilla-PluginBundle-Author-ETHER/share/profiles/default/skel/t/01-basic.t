use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
{{
    ($zilla_plugin) = ($dist->name =~ /^Dist-Zilla-Plugin-(.+)$/g);
    $zilla_plugin //= '';
    $zilla_plugin =~ s/-/::/g;

    $zilla_plugin
        ? <<PLUGIN
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

my \$tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      path(qw(source dist.ini)) => simple_ini(
        [ GatherDir => ],
        [ MetaConfig => ],
        [ '$zilla_plugin' => ... ],
      ),
      path(qw(source lib Foo.pm)) => "package Foo;\\n1;\\n",
    },
  },
);

\$tzil->chrome->logger->set_debug(1);
is(
  exception { \$tzil->build },
  undef,
  'build proceeds normally',
);

cmp_deeply(
  \$tzil->distmeta,
  superhashof({
    x_Dist_Zilla => superhashof({
      plugins => supersetof(
        {
          class => 'Dist::Zilla::Plugin::$zilla_plugin',
          config => {
            'Dist::Zilla::Plugin::$zilla_plugin' => {
              ...
            },
          },
          name => '$zilla_plugin',
          version => Dist::Zilla::Plugin::$zilla_plugin->VERSION,
        },
      ),
    }),
  }),
  'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain \$tzil->distmeta;

diag 'got log messages: ', explain \$tzil->log_messages
  if not Test::Builder->new->is_passing;
PLUGIN
        : 'use ' . $dist->name =~ s/-/::/gr . ';'
            . "\n\nfail('this test is TODO!');"
}}
done_testing;
