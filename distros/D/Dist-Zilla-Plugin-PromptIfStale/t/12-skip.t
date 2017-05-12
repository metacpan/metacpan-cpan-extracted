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

my @modules_queried;
{
    use Dist::Zilla::Plugin::PromptIfStale;
    package Dist::Zilla::Plugin::PromptIfStale;
    no warnings 'redefine';
    sub _indexed_version {
        my ($self, $module) = @_;
        push @modules_queried, $module;
        return version->parse('0');
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

my $checked_app;
BUILD:
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Prereqs => RuntimeRequires => { Carp => 0, DoesNotExist => 0 } ],
                [ 'PromptIfStale' => {
                        phase => 'build',
                        check_all_plugins => 1,
                        check_all_prereqs => 1,
                        modules => [ qw(NotMeEither Storable) ],
                        skip => [ qw(DoesNotExist Dist::Zilla::Plugin::Prereqs NotMeEither) ],
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

if (not $checked_app++)
{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [ ],
        'app finds no stale modules',
    );
    @modules_queried = ();
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
    goto BUILD;
}

$tzil->chrome->logger->set_debug(1);

# we will die if we are prompted
is(
    exception { $tzil->build },
    undef,
    'build was not halted - there were no prompts',
);

is(scalar @prompts, 0, 'there were no prompts') or diag 'got: ', explain \@prompts;

my @expected_checked = (qw(Carp Storable), map { 'Dist::Zilla::Plugin::' . $_ } qw(GatherDir PromptIfStale FinderCode));

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules, plugins...',
        '[PromptIfStale] checking for stale prerequisites...',
        (map { re(qr/^\Q[PromptIfStale] comparing indexed vs. local version for $_: indexed=0; local version=\E/) } @expected_checked),
        re(qr/^\Q[DZ] writing DZT-Sample in /),
    ),
    'build completed successfully',
);

cmp_deeply(
    \@modules_queried,
    bag(@expected_checked),
    'all modules, from both configs, are checked',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
