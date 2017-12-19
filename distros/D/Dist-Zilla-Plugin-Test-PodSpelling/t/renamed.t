use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use File::pushd 'pushd';
use Path::Tiny;

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
                    [ ExtraTests => ],
                    ['Test::PodSpelling']
                )
            }
        },
    );

$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(t author-pod-spell.t));

ok(-e $file, 'test file exists');

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    #$tzil->plugin_named('MakeMaker')->build;

    local $ENV{AUTHOR_TESTING} = 1;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

done_testing;
