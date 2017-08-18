use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';

use lib 't/lib';
use EnsureStdinTty;
use NoNetworkHits;
use DiagFilehandles;

# make it look like we are doing a regular Travis run (in some other repository)
$ENV{CONTINUOUS_INTEGRATION} = 'faked for t/27-travis.t';
undef $ENV{PROMPTIFSTALE_REALLY_RUN_TESTS};

# ...but also set a variable to get test working here again...
$ENV{HARNESS_ACTIVE} = 1;

my @prompts;
{
    use Dist::Zilla::Chrome::Test;
    my $meta = find_meta('Dist::Zilla::Chrome::Test');
    $meta->make_mutable;
    $meta->add_before_method_modifier(prompt_str => sub {
        my ($self, $prompt, $arg) = @_;
        push @prompts, $prompt;
    });
}

subtest "run_under_travis = $_" => sub {
    my $run_under_travis = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'PromptIfStale' => {
                            modules => [ 'StaleModule' ],
                            phase => 'build',
                            run_under_travis => $run_under_travis,
                        } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
            also_copy => { 't/lib' => 't/lib' },        },
    );

    my $prompt = 'StaleModule is not installed. Continue anyway?';
    $tzil->chrome->set_response_for($prompt, 'y') if $run_under_travis;

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    if ($run_under_travis)
    {
        cmp_deeply(\@prompts, [ $prompt ], 'we were indeed prompted');

        cmp_deeply(
            $tzil->log_messages,
            superbagof(
                '[PromptIfStale] checking for stale modules...',
                re(qr/^\Q[DZ] writing DZT-Sample in /),
            ),
            'log messages indicate a check is performed',
        );
    }
    else
    {
        cmp_deeply(\@prompts, [ ], 'we were not prompted');

        my @log_messages = grep { /^\[PromptIfStale\]/ } @{$tzil->log_messages};

        cmp_deeply(
            \@log_messages,
            [ '[PromptIfStale] travis detected: skipping checks...' ],
            'checks are skipped when run_under_travis=1',
        );

        is(@log_messages, 1, 'no other messages are logged');
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;

    @prompts = ();
}
foreach (1, 0);

done_testing;
