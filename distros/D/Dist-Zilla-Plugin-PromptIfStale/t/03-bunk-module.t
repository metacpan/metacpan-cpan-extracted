use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use Moose::Util 'find_meta';
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
        return undef if $module eq 'Unindexed';
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
                [ 'PromptIfStale' => { modules => [ 'Unindexed' ], phase => 'build' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        also_copy => { 't/corpus' => 't/lib' },
    },
);

my $prompt = 'Unindexed is not indexed. Continue anyway?';
$tzil->chrome->set_response_for($prompt, 'n');

# ensure we find the library, not in a local directory, before we change directories
unshift @INC, path($tzil->tempdir, qw(t lib))->stringify;

{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [ 'Unindexed' ],
        'app finds stale modules',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
}

$tzil->chrome->logger->set_debug(1);

# if a response has not been configured for a particular prompt, we will die
like(
    exception { $tzil->build },
    qr/^\Q[PromptIfStale] Aborting build\E/,
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
        '[PromptIfStale] comparing indexed vs. local version for Unindexed: indexed=undef; local version=2.0',
        "[PromptIfStale] Aborting build\n[PromptIfStale] To remedy, do: cpanm Unindexed",
    ),
    'build was aborted, with remedy instructions',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
