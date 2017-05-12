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
distfile: R/RJ/RJBS/perl-5.20.0.tar.gz
version: 200.0
',
        } if $module eq 'strict';
        die 'should not be checking for ' . $module;
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => { modules => [ 'strict' ], phase => 'build' } ],
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
        [],
        'app finds no stale modules (core is exempt)',
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

# allow for dev releases - Module::Metadata includes _, but $VERSION does not.
my $STRICT_VERSION = Module::Metadata->new_from_module('strict')->version;

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[PromptIfStale] checking for stale modules...',
        '[PromptIfStale] core module strict is indexed at version 200.0 but you only have ' . $STRICT_VERSION . ' installed. You need to update your perl to get the latest version.',
        re(qr/^\Q[DZ] writing DZT-Sample in /),
    ),
    'log messages indicate what is checked',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
