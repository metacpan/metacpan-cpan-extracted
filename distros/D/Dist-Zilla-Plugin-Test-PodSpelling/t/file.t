use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use File::pushd 'pushd';
use Path::Tiny;
use Test::Script 1.05;

my $tzil
    = Builder->from_config(
        {
            dist_root    => 'corpus/a',
        },
        {
            add_files => {
                'source/lib/Foo.pm' => "package Foo;\n1;\n",
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    ['Test::PodSpelling']
                )
            }
        },
    );

$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $fn = $build_dir->child(qw(xt author pod-spell.t));

ok ( -e $fn, 'test file exists');

{
    my $wd = pushd $build_dir;

    $tzil->plugin_named('MakeMaker')->build;

    script_compiles( '' . $fn->relative, 'check test compiles' );
}

done_testing;
