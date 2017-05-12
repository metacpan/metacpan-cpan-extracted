use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use Test::Needs { 'Dist::Zilla::Plugin::MakeMaker' => '5.022' };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    name => 'warnings',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ MakeMaker => ],
                [ DualLife  => ],
            ),
            path(qw(source lib warnings.pm)) => "package warnings;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');

my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');

like(
    $makefile,
    qr/\$WriteMakefileArgs\{INSTALLDIRS\} = 'perl'\s+if \"\$\]\" >= 5\.006 && \"\$\]\" <= 5\.011000;.*WriteMakefile\(\%WriteMakefileArgs\);/ms,
    'Makefile.PL has INSTALLDIRS arg set before calling WriteMakefile',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::DualLife',
                    config => superhashof({ # there will be configs for Dist::Zilla::Role::ModuleMetadata as well
                        'Dist::Zilla::Plugin::DualLife' => {
                            eumm_bundled => 0,
                        },
                    }),
                    name => 'DualLife',
                    version => Dist::Zilla::Plugin::DualLife->VERSION,
                },
            ),
        }),
    }),
    'dumped configs to metadata',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
