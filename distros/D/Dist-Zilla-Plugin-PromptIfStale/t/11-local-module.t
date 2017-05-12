use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';
use File::pushd 'pushd';
use Dist::Zilla::App::Command::stale;

use lib 't/lib';
use NoNetworkHits;
use DiagFilehandles;

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
        # copy the module to the source directory, because that's where $tzil->build chdirs
        also_copy => { 't/corpus' => 'source/t/lib' },
    },
);

# find the library in the source dir, so that it is a directory beneath the current dir
unshift @INC, path($tzil->tempdir, qw(source t lib))->stringify;
{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [ ],
        'app finds no stale modules',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
}

$tzil->chrome->logger->set_debug(1);

# we will die if we are prompted
is(
    exception { $tzil->build },
    undef,
    'build was not aborted',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules...',
        '[PromptIfStale] Unindexed provided locally (at t/lib/Unindexed.pm); skipping version check',
        re(qr/^\Q[DZ] writing DZT-Sample in /),
    ),
    'module skipped, due to being local',
);

is(scalar @prompts, 0, 'there were no prompts');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
