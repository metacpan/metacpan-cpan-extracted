use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use Moose::Util 'find_meta';
use version;
use File::pushd 'pushd';
use Dist::Zilla::App::Command::stale;

use lib 't/lib';
use NoNetworkHits;
use DiagFilehandles;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => { modules => [ 'Carp' ], check_all_plugins => 1, phase => 'build' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

my @prompts;
{
    my $meta = find_meta('Dist::Zilla::Chrome::Test');
    $meta->make_mutable;
    $meta->add_before_method_modifier(prompt_str => sub {
        my ($self, $prompt, $arg) = @_;
        push @prompts, $prompt;
    });
}

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

{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ do { Dist::Zilla::App::Command::stale->stale_modules($tzil) }],
        [ ],
        'app finds no stale modules',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
    @modules_queried = ();
}

$tzil->chrome->logger->set_debug(1);

# we will die if we are prompted
is(
    exception { $tzil->build },
    undef,
    'build succeeded when checking for a module that is not stale',
);

is(scalar @prompts, 0, 'there were no prompts') or diag 'got: ', explain \@prompts;

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules, plugins...',
        (map { re(qr/^\Q[PromptIfStale] comparing indexed vs. local version for Dist::Zilla::Plugin::$_: indexed=0; local version=\E/) } qw(GatherDir PromptIfStale)),
        re(qr/^\Q[DZ] writing DZT-Sample in /),
    ),
    'build completed successfully',
);

cmp_deeply(
    \@modules_queried,
    bag('Carp', map { 'Dist::Zilla::Plugin::' . $_ } qw(GatherDir PromptIfStale FinderCode)),
    'all modules, from both configs, are checked',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
