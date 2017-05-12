use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Safe::Isa;
use File::pushd 'pushd';

# ensure this loads, as well as getting prereqs autodetected
use Test::PAUSE::Permissions ();

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Test::PAUSE::Permissions' ],
                    [ '%PAUSE' => { username => 'username', password => 'password' } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child(qw(xt release pause-permissions.t));
    ok(-e $file, 'test created');

    my $content = $file->slurp_utf8;
    unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

    like($content, qr/^all_permissions_ok\('username'\);$/m, 'username extracted from stash and passed to test');

    my $error;
    subtest 'run the generated test' => sub
    {
        my $wd = pushd $build_dir;

        # ensure we don't call out to the network when running the test
        local $ENV{RELEASE_TESTING};

        my $test = eval 'sub { ' . $file->slurp_utf8 . ' }';
        return $error = $@ if $@;
        $test->();
        note 'ran tests successfully';
    };

    fail('failed to compile test file') and diag(explain($error)) if $error;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Test::PAUSE::Permissions' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child(qw(xt release pause-permissions.t));
    ok(-e $file, 'test created');

    my $content = $file->slurp_utf8;
    unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

    like($content, qr/^all_permissions_ok\(\);$/m, 'no username passed to test');

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
