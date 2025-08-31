# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test2::V0;
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
            . "\n\nmy \$todo = todo('not yet implemented');"
            . "\nfail('this test is TODO!');\n"
}}
done_testing;
