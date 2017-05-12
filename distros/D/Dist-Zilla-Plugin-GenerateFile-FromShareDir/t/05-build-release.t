use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

use Test::File::ShareDir -share => { -dist => { 'Some-Other-Dist' => 't/corpus' } };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'MetaConfig',
                [ 'GenerateFile::FromShareDir' => {
                    '-dist' => 'Some-Other-Dist',
                    '-source_filename' => 'template.txt',
                    '-destination_filename' => 'data/useless_file.txt',
                    '-location' => 'build',
                    '-phase' => 'release',
                    numero => 'neuf',
                } ],
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $nonfile1 = $build_dir->child('data', 'useless_file.txt');
ok(!-e $nonfile1, 'file not created in build');

my $source_dir = path($tzil->tempdir)->child('source');
my $nonfile2 = $source_dir->child('data', 'useless_file.txt');
ok(!-e $nonfile2, 'file not created in source');

cmp_deeply(
    $tzil->log_messages,
    supersetof(
        '[GenerateFile::FromShareDir] nonsensical and impossible combination of configs: -location = build, -phase = release',
    ),
    'build warning issued for nonsensical combination of configs',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
