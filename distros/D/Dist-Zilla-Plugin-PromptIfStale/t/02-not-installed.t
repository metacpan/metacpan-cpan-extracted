use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';
use version;
use File::pushd 'pushd';
use Dist::Zilla::App::Command::stale;

use lib 't/lib';
use NoNetworkHits;
use EnsureStdinTty;
use DiagFilehandles;

# simulate a response from the PAUSE index, without having to do a real HTTP hit

{
    use Dist::Zilla::Plugin::PromptIfStale;
    package Dist::Zilla::Plugin::PromptIfStale;
    no warnings 'redefine';
    sub _indexed_version {
        my ($self, $module) = @_;
        return version->parse('200.0') if $module eq 'Indexed::But::Not::Installed';
        die 'should not be checking for ' . $module;
    }
}

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

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => { modules => [ 'Indexed::But::Not::Installed' ], phase => 'build' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [ 'Indexed::But::Not::Installed' ],
        'app finds stale modules',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
}

my $prompt = 'Indexed::But::Not::Installed is not installed. Continue anyway?';
$tzil->chrome->set_response_for($prompt, 'n');

$tzil->chrome->logger->set_debug(1);

# if a response has not been configured for a particular prompt, we will die
like(
    exception { $tzil->build },
    qr/\Q[PromptIfStale] Aborting build\E/,
    'build aborted',
);

cmp_deeply(
    \@prompts,
    [ $prompt ],
    'we were indeed prompted',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules...',
        "[PromptIfStale] Aborting build\n[PromptIfStale] To remedy, do: cpanm Indexed::But::Not::Installed",
    ),
    'build was aborted, with remedy instructions',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
