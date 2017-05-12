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

BEGIN {
    # dzil changes directories..
    unshift @INC, path(qw(t lib))->absolute->stringify;
}
use EnsureStdinTty;
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

{
    use HTTP::Tiny;
    package HTTP::Tiny;
    no warnings 'redefine';
    sub get {
        my ($self, $url) = @_;
        ::note 'in monkeypatched HTTP::Tiny::get for ' . $url;
        my ($module) = reverse split('/', $url);
        return +{
            success => 1,
            status => '200',
            reason => 'OK',
            protocol => 'HTTP/1.1',
            url => $url,
            headers => {
                'content-type' => 'text/x-yaml',
            },
            content => '---
distfile: A/AN/ANONYMOUS/Some-Dist-200.0.tar.gz
version: 200.0
',
        } if $module eq 'StaleModule';
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

my $prompt = 'StaleModule is indexed at version 200.0 but you only have 1.0 installed. Continue anyway?';
$tzil->chrome->set_response_for($prompt, 'y');

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

# if a response has not been configured for a particular prompt, we will die
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(\@prompts, [ $prompt ], 'we were indeed prompted');

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules...',
        '[PromptIfStale] comparing indexed vs. local version for StaleModule: indexed=200.0; local version=1.0',
        re(qr/^\Q[DZ] writing DZT-Sample in /),
    ),
    'log messages indicate what is checked',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
