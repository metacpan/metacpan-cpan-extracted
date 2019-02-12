use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny;
use Test::DZil;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Run::Test' => { run => [ '"%x" script%ptest.pl "%d" %n-%v' ] } ],
                    [ FakeRelease => ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source script test.pl)) => <<'SCRIPT',
use strict;
use warnings;
use Path::Tiny;
path($ARGV[ 0 ], 'test.txt')->spew_raw(join(' ', test => @ARGV));
SCRIPT
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build();

    my $build_dir = path($tzil->tempdir)->child('build');
    $tzil->run_tests_in($build_dir);

    my $test_file   = $build_dir->child('test.txt');

    ok(-f $test_file, 'Test script has been run');

    my $content     = path($tzil->tempdir)->child(qw(build test.txt))->slurp_raw;

    my $build_dir_canonical = $build_dir->canonpath;
    is($content, "test $build_dir_canonical DZT-Sample-0.001", 'Correct `test` result');

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
