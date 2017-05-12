use strict; use warnings FATAL => 'all';
use Test::More;

# Ported from Dist::Zilla::Plugin::CheckLib (C) 2014 Karen Etheridge

use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Test::Warnings;

use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'MakeMaker' => ],
                [ 'FFI::CheckLib' => {
                        lib => [ qw(iconv jpeg) ],
                        libpath => 'additional_path',
                        symbol => [ qw(foo bar) ],
                        systempath => 'system',
                        recursive => 1,
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'nothing exploded',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated file');

my $version = Dist::Zilla::Plugin::FFI::CheckLib->VERSION || '<self>';

my $pattern = <<PATTERN;
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::FFI::CheckLib $version
use FFI::CheckLib;
check_lib_or_exit(
    lib => [ 'iconv', 'jpeg' ],
    libpath => 'additional_path',
    symbol => [ 'foo', 'bar' ],
    systempath => 'system',
    recursive => '1',
);
PATTERN

like(
    $content,
    qr/^\Q$pattern\E$/m,
    'code inserted into Makefile.PL',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            configure => {
                requires => {
                    'FFI::CheckLib' => '0.11',
                    'ExtUtils::MakeMaker' => ignore,    # populated by [MakeMaker]
                },
            },
            # build prereqs go here
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::FFI::CheckLib',
                    config => {
                        'Dist::Zilla::Plugin::FFI::CheckLib' => superhashof({
                            lib => [ 'iconv', 'jpeg' ],
                            libpath => [ 'additional_path' ],
                            symbol => [ 'foo', 'bar' ],
                            systempath => [ 'system' ],
                            recursive => 1,
                        }),
                    },
                    name => 'FFI::CheckLib',
                    version => ignore,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the configure phase',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
