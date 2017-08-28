use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

foreach my $display (undef, ':0.0')
{
    local $ENV{DISPLAY} = $display;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ ExecDir => ],
                    [ 'Test::Compile' => { needs_display => 1 } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child(qw(t 00-compile.t));
    ok( -e $file, 'test created');

    my $error;
    my $display_str = $display || '<undef>';
    subtest "run the generated test (\$DISPLAY=$display_str)" => sub
    {
        my $wd = pushd $build_dir;
        $tzil->plugin_named('MakeMaker')->build;

        # I'm not sure why, but if we just 'do $file', we get the
        # Test::Builder::Exception object back in $@ that is actually being
        # used for flow control in Test::Builder::skip_all -- but if we
        # compile the code first and then run it, TB works properly and the
        # skip functionality completes
        my $test = eval 'sub { ' . $file->slurp_utf8 . ' }';
        return $error = $@ if $@;
        $test->();
    };

    if ($error)
    {
        fail('failed to compile test file: ' . $error);
    }
    else
    {
        my $tb = Test::Builder->new;
        my $skip = !$ENV{DISPLAY} && $^O ne 'MSWin32';
        cmp_deeply(
            ($tb->details)[$tb->current_test - 1],
            superhashof({
               ok       => 1,
               type     => !$skip ? '' : 'skip',
               reason   => !$skip ? '' : 'Needs DISPLAY',
               name     => !$skip
                            ? "run the generated test (\$DISPLAY=$display_str)"
                            : any('', "run the generated test (\$DISPLAY=$display_str)"),   # older TB handled this oddly
            }),
            !$skip ? 'test file ran successfully' : 'test file skipped because $DISPLAY was not set',
        );
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
