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

my $expected_stale;

{
    package Dist::Zilla::PluginBundle::UnsatisfiedDeps;
    use strict;
    use warnings;
    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';
    use Module::Runtime 'require_module';

    sub configure
    {
        my $self = shift;

        if ($expected_stale eq 'Dist::Zilla::Plugin::NotInstalled1')
        {
            require_module('Dist::Zilla::Plugin::NotInstalled1');
            $self->add_plugins('NotInstalled1');
        }
        elsif ($expected_stale eq 'Dist::Zilla::Plugin::Broken')
        {
            $self->add_plugins('Broken');
        }
        elsif ($expected_stale eq 'Broken')
        {
            require_module('Broken');
        }
        elsif ($expected_stale eq 'strict')
        {
            strict->VERSION('200');
        }
    }
}

foreach my $module ('Dist::Zilla::Plugin::NotInstalled1', 'Dist::Zilla::Plugin::Broken', 'Broken', 'strict')
{
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
    _clear_log_messages();

    $expected_stale = $module;
    local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = 'does-not-exist';

    # TODO: we should be able to call a sub that specifies our corpus layout
    # including dist.ini, rather than having to build it ourselves, here.
    # This would also help us improve the tests for the 'authordeps' command.

    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    my $root = $tempdir->child('source');
    $root->mkpath;
    my $wd = pushd $root;

    path($root, 'dist.ini')->spew_utf8(
        simple_ini(
            [ GatherDir => ],
            [ 'PromptIfStale' => {
                    phase => 'build',
                    check_all_plugins => 1,
                },
            ],
            '@UnsatisfiedDeps',
            'NotInstalled2',
        )
    );

    my $result = test_dzil('.', [ 'stale' ]);

    is($result->exit_code, 1, 'dzil would have exited 1');
    is(
        $result->stdout,
        join("\n",
            sort $module, 'Dist::Zilla::Plugin::NotInstalled2',
        ) . "\n",
        "stale module $module is properly detected and reported",
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
