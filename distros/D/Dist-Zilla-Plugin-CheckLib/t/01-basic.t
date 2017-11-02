use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Path::Tiny;
use Test::Fatal;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'MakeMaker' => ],
                [ 'CheckLib' => {
                        lib => [ qw(jpeg iconv) ],
                        header => 'jpeglib.h',
                        libpath => 'additional_path',
                        debug => 0,
                        LIBS => '-lfoo -lbar -Lkablammo',
                        incpath => [ qw(inc2 inc3 inc1) ],
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
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated file');

my $version = Dist::Zilla::Plugin::CheckLib->VERSION;

my $pattern = <<PATTERN;
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::CheckLib $version
use Devel::CheckLib;
check_lib_or_exit(
    header => 'jpeglib.h',
    incpath => [ 'inc1', 'inc2', 'inc3' ],
    lib => [ 'iconv', 'jpeg' ],
    libpath => 'additional_path',
    LIBS => '-lfoo -lbar -Lkablammo',
    debug => '0',
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
                    'Devel::CheckLib' => '0.9',
                    'ExtUtils::MakeMaker' => ignore,    # populated by [MakeMaker]
                },
            },
            # build prereqs go here
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::CheckLib',
                    config => {
                        'Dist::Zilla::Plugin::CheckLib' => superhashof({
                            header => ['jpeglib.h'],
                            incpath => ['inc1', 'inc2', 'inc3'],
                            lib => [ 'iconv', 'jpeg' ],
                            libpath => [ 'additional_path' ],
                            INC => undef,
                            LIBS => '-lfoo -lbar -Lkablammo',
                            debug => '0',
                        }),
                    },
                    name => 'CheckLib',
                    version => Dist::Zilla::Plugin::CheckLib->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the configure phase',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
