use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use utf8;

binmode Test::More->builder->$_, ':encoding(UTF-8)' foreach qw(output failure_output todo_output);
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

use Test::File::ShareDir -share => { -dist => { 'Some-Other-Dist' => 't/corpus' } };

{
    package Some::Other::Dist;
    $Some::Other::Dist::VERSION = '2.0';
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ 'GenerateFile::FromShareDir' => {
                    '-dist' => 'Some-Other-Dist',
                    '-encoding' => 'Latin1',
                    '-source_filename' => 'template_latin1.txt',
                    '-destination_filename' => 'data/useless_file.txt',
                    numero => 'neuf',
                } ],
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('data', 'useless_file.txt');
ok(-e $file, 'file created');

my $content = Encode::decode('Latin1', $file->slurp_raw, Encode::FB_CROAK());

my $zilla_version = Dist::Zilla->VERSION;

like($content, qr/^This file was generated with Dist::Zilla::Plugin::GenerateFile::FromShareDir /, '$plugin is passed to the template');
like($content, qr/Dist::Zilla $zilla_version/, '$zilla is passed to the template');
like($content, qr/Some-Other-Dist-2.0/, 'dist name can be fetched from the $plugin object');
like($content, qr/Le numéro de Maurice Richard est neuf./, 'arbitrary args are passed to the template');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
