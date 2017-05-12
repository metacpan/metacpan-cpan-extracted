#!perl
use Test::Most;

use strict;
use warnings FATAL => 'all';

eval 'use Dist::Zilla 5.000; 1;';
plan skip_all => 'Dist::Zilla 5 required for full encoding support' if $@;

use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
binmode Test::More->builder->$_, ':encoding(UTF-8)' foreach qw(output failure_output todo_output);

use autodie;
use Test::DZil;
use Path::Tiny;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT_Latin1' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                'GatherDir',
                [ 'ReadmeAnyFromPod', 'ReadmeTextInBuild' ],
                [ 'Encoding' => { encoding => 'latin1', filename => 'lib/DZT/Sample.pm' } ],
            ),
        },
    }
);

lives_ok { $tzil->build; } "Built dist successfully";

my $build_dir = path($tzil->tempdir)->child('build');
my $file = path($build_dir, 'README');
ok( -e $file, 'README created in build');

my $content = $file->slurp_utf8;
like($content, qr/Dagfinn Ilmari Mannsåker/m,
     'file was written with correct encoding');

done_testing();
