use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use Path::Tiny;
use Test::Deep;
use File::pushd 'pushd';

local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = 'does-not-exist';

sub tzil {
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Run::Clean' => {
                        run => [ '"%x" script%pclean.pl' ],
                        eval => [ 'use Path::Tiny; path(\'CLEAN.txt\')->append_utf8("eval command\n");' ],
                      }
                    ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source script clean.pl)) => <<'SCRIPT',
use strict;
use warnings;
use Path::Tiny;
path('CLEAN.txt')->append_utf8("run command\n");
SCRIPT
            },
        },
    );
    $tzil->chrome->logger->set_debug(1);

    return $tzil;
}

{
    my $tzil = tzil();
    $tzil->build;

    my $clean_result = path($tzil->tempdir, qw(source CLEAN.txt));
    ok(!-f $clean_result, 'clean script was not run from a build');

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = tzil();

    # since we are not doing a build, we never changed directories
    my $wd = pushd $tzil->root;

    # instead of setting up a full dist.ini on disk and calling test_dzil,
    # we simply call the method that Dist::Zilla::App::Command::clean::execute does.
    $tzil->clean('this is the dry run flag');

    my $clean_result = path($tzil->tempdir, qw(source CLEAN.txt));
    ok(!-f $clean_result, 'clean script was not run from a clean --dry-run');

    cmp_deeply(
        [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
        [
            '[Run::Clean] dry run, would run: "%x" script%pclean.pl',
            '[Run::Clean] dry run, would evaluate: use Path::Tiny; path(\'CLEAN.txt\')->append_utf8("eval command\n");',
        ],
        'we logged the command we would run',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = tzil();

    # since we are not doing a build, we never changed directories
    my $wd = pushd $tzil->root;

    $tzil->clean();

    my $clean_result = path($tzil->tempdir, qw(source CLEAN.txt));
    ok(-f $clean_result, 'clean script was run from a clean command');

    is(
        $clean_result->slurp_utf8,
        "run command\neval command\n",
        'both the run and eval commands executed',
    );

    cmp_deeply(
        [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
        [
            re(qr/^\[Run::Clean\] executing: /),
            '[Run::Clean] command executed successfully',
            '[Run::Clean] evaluating: use Path::Tiny; path(\'CLEAN.txt\')->append_utf8("eval command\n");',
        ],
        'we logged the commands we ran',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
