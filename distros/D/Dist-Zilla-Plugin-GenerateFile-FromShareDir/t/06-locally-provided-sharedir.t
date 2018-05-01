use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    name => 'This-Dist',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ ShareDir => { dir => 'share' } ],
                [ 'GenerateFile::FromShareDir' => {
                    '-dist' => 'This-Dist',
                    '-source_filename' => 'template.txt',
                    '-destination_filename' => 'data/useless_file.txt',
                    numero => 'nine',
                } ],
            ),
            path(qw(source share template.txt)) => "My number is {{ \$numero }}.\n",
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
my $file = $build_dir->child('data', 'useless_file.txt');
ok(-e $file, 'file created in build');

my $content = $file->slurp_utf8;
is($content, "My number is nine.\n", 'The file content was correctly generated from the template.');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        name => 'This-Dist',
        x_Dist_Zilla => superhashof({
            plugins => supersetof({
                class => 'Dist::Zilla::Plugin::GenerateFile::FromShareDir',
                config => superhashof({
                    'Dist::Zilla::Plugin::GenerateFile::FromShareDir' => {
                        dist => 'This-Dist',
                        encoding => 'UTF-8',
                        source_filename => 'template.txt',
                        destination_filename => 'data/useless_file.txt',
                        location => 'build',
                        numero => 'nine',
                    },
                    'Dist::Zilla::Role::RepoFileInjector' => superhashof({
                        version => Dist::Zilla::Role::RepoFileInjector->VERSION,
                    }),
                }),
                name => 'GenerateFile::FromShareDir',
                version => Dist::Zilla::Plugin::GenerateFile::FromShareDir->VERSION,
            }),
        }),
    }),
    'config is properly included in metadata',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

cmp_deeply(
    $tzil->log_messages,
    supersetof('[GenerateFile::FromShareDir] using template in ' . path($tzil->tempdir)->child('source', 'share', 'template.txt')),
    'logged the source of the template file',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
