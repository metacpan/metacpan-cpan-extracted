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
use EnsureStdinTty;
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

my $checked_app;
BUILD:
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ PromptIfStale => 'via_bundle' => {
                        phase => 'build',
                        module => [ map { 'Foo' . $_ } qw(A B C J X) ],
                        check_all_prereqs => 1,
                    },
                ],
                [ Prereqs => RuntimeRequires => {
                        perl => 0,
                        map { 'Foo' . $_ => 0 } qw(J K L A Y),
                    },
                ],
                [ PromptIfStale => 'direct' => {
                        phase => 'release',
                        module => [ map { 'Foo' . $_ } qw(X Y Z B K), ],
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

# modules to check:
# beforebuild (build 'modules'):               A B C J X
# afterbuild  (build 'prereqs'):               J K L A Y (new: K L Y)
# release (release 'modules' and 'prereqs') :  X Y Z B K (new: Z)


my %expected_prompts = (
    before_build => [
        map { '    Foo' . $_ . ' is not installed.' } qw(A B C J X) ],
    after_build => [
        map { '    Foo' . $_ . ' is not installed.' } qw(K L Y) ],
);

my @expected_prompts = ((map {
    "Issues found:\n" . join("\n", @{$expected_prompts{$_}}, 'Continue anyway?')
} qw(before_build after_build)),
    'FooZ is not installed. Continue anyway?',
);

$tzil->chrome->set_response_for($_, 'y') foreach @expected_prompts;

if (not $checked_app++)
{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [ map { 'Foo' . $_ } qw(A B C J K L X Y Z) ],
        'app finds stale modules',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
    goto BUILD;
}


$tzil->chrome->logger->set_debug(1);

# if a response has not been configured for a particular prompt, we will die
is(
    exception { $tzil->build },
    undef,
    'build succeeded when checking for a module that is not stale',
);
$_->before_release('Foo.tar.gz') for @{ $tzil->plugins_with(-BeforeRelease) };

cmp_deeply(
    \@prompts,
    \@expected_prompts,
    'we were indeed prompted, all at once per phase, and not twice for the duplicates',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[via_bundle] checking for stale modules...',
        '[via_bundle] checking for stale prerequisites...',
        '[direct] checking for stale modules...',
    ),
    'build completed successfully',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
