use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Path::Tiny;
use Test::Fatal;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'MakeMaker' => ],
                [ 'CheckBin' => { command => [ qw(ls cd) ] } ],
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

my $version = Dist::Zilla::Plugin::CheckBin->VERSION || '<self>';

my $pattern = <<PATTERN;
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::CheckBin $version
use Devel::CheckBin;
check_bin('cd');
check_bin('ls');
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
                    'Devel::CheckBin' => '0',
                    'ExtUtils::MakeMaker' => ignore,    # populated by [MakeMaker]
                },
            },
            # build prereqs go here
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::CheckBin',
                    config => {
                        'Dist::Zilla::Plugin::CheckBin' => {
                            command => [ qw(cd ls) ],   # for now, commands are sorted
                        },
                    },
                    name => 'CheckBin',
                    version => ignore,
                },
            ),
        })
    }),
    'prereqs are properly injected for the configure phase; config is properly included in metadata',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
