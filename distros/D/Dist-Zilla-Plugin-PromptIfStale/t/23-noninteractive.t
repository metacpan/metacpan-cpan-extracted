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
use version;
use File::Spec;
use Dist::Zilla::App::Command::stale;

use lib 't/lib';
use NoNetworkHits;
use DiagFilehandles;

# make it look like we are running non-interactively
close STDIN;
open STDIN, '<', File::Spec->devnull;

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

{
    use Dist::Zilla::Plugin::PromptIfStale;
    package Dist::Zilla::Plugin::PromptIfStale;
    no warnings 'redefine';
    sub _indexed_version {
        my ($self, $module) = @_;
        return version->parse('200.0') if $module eq 'StaleModule';
        die 'should not be checking for ' . $module;
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => { modules => [ 'StaleModule' ], phase => 'build' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        also_copy => { 't/lib' => 't/lib' },
    },
);

# ensure we find the library, not in a local directory, before we change directories
unshift @INC, path($tzil->tempdir, qw(t lib))->stringify;

{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [ 'StaleModule' ],
        'app finds stale modules',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
}

$tzil->chrome->logger->set_debug(1);

# we will die if we are prompted
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

is(scalar @prompts, 0, 'there were no prompts') or diag 'got: ', explain \@prompts;

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules...',
        '[PromptIfStale] comparing indexed vs. local version for StaleModule: indexed=200.0; local version=1.0',
        "[PromptIfStale] StaleModule is indexed at version 200.0 but you only have 1.0 installed.\n[PromptIfStale] To remedy, do: cpanm StaleModule",
        re(qr/^\Q[DZ] writing DZT-Sample in /),
    ),
    'stale module was still found and logged',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
