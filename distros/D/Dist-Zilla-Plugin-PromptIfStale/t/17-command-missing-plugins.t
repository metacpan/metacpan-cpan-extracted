use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Dist::Zilla::App::Tester;
use Path::Tiny;
use File::pushd 'pushd';
use Term::ANSIColor 2.01 'colorstrip';
use Dist::Zilla::App::Command::stale;   # load this now, before we change directories
use App::Cmd::Tester 0.328;

use lib 't/lib';
use NoNetworkHits;
use DiagFilehandles;
use CaptureDiagnostics;

{
    local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = 'does-not-exist';

    # TODO: we should be able to call a sub that specifies our corpus layout
    # including dist.ini, rather than having to build it ourselves, here.
    # This would also help us improve the tests for the 'authordeps' command.

    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    my $root = $tempdir->child('source');
    $root->mkpath;
    $root->child('dist.ini')->spew_utf8(
        simple_ini(
            [ NonexistentPlugin => ],
            [ '=inc::LocalNotInstalled' => ],
        ),
    );
    my $inc = $root->child('inc');
    $inc->mkpath;
    $inc->child('LocalInstalled.pm')->spew_utf8(
        "package inc::LocalInstalled;\nuse Moose;\nwith 'Dist::Zilla::Role::Plugin';\n1;\n"
    );

    # TODO: when we have Dist::Zilla 7, we should not change directories.
    my $wd = pushd $root;
    my $result = test_dzil('.', [ 'stale' ]);

    is($result->exit_code, 1, 'dzil would have exited 1');
    is($result->stdout,
        "Dist::Zilla::Plugin::NonexistentPlugin\ninc::LocalNotInstalled\n",
        'dzil authordeps ran to get missing plugins',
    );
    is(
        colorstrip($result->stderr),
        "Some authordeps were missing. Run the stale command again to check for regular dependencies.\n",
        'user given a warning to run the command again',
    ) or diag 'got stderr output: ' . $result->stderr;

    if (not Test::Builder->new->is_passing)
    {
        diag 'got result: ', explain $result;
        diag 'plugin logged messages: ', explain(_log_messages());
    }
}

done_testing;
