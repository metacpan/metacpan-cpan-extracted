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
            content =>
                $module eq 'strict' ? '---
distfile: R/RJ/RJBS/perl-5.20.0.tar.gz
version: 200.0
'
                : $module eq 'Carp' ? '---
distfile: Z/ZE/ZEFRAM/Carp-1.3301.tar.gz
version: 200.0
'
                : die "should not be checking for $module"
            ,
        };
        die 'should not be checking for ' . $module;
    }
}

{
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
        },
    );

    $tzil->chrome->logger->set_debug(1);

    {
        my $wd = pushd $tzil->root;
        cmp_deeply(
            [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
            [ ],
            'app finds no stale modules',
        );
        Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
    }

    # we will die if we are prompted
    is(
        exception { $tzil->build },
        undef,
        'build succeeded when the stale module is core only',
    );

    is(scalar @prompts, 0, 'there were no prompts') or diag 'got: ', explain \@prompts;

    # allow for dev releases - Module::Metadata includes _, but $VERSION does not.
    my $STRICT_VERSION = Module::Metadata->new_from_module('strict')->version;

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            '[PromptIfStale] checking for stale modules...',
            '[PromptIfStale] comparing indexed vs. local version for strict: indexed=200.0; local version=' . $STRICT_VERSION,
            re(qr/^\Q[DZ] writing DZT-Sample in /),
        ),
        'build completed successfully',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

@prompts = ();
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'PromptIfStale' => { modules => [ 'Carp' ], phase => 'build' } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    # allow for dev releases - Module::Metadata includes _, but $VERSION does not.
    my $CARP_VERSION = Module::Metadata->new_from_module('Carp')->version;

    my $prompt = 'Carp is indexed at version 200.0 but you only have ' . $CARP_VERSION
        . ' installed. Continue anyway?';
    $tzil->chrome->set_response_for($prompt, 'y');

    {
        my $wd = pushd $tzil->root;
        cmp_deeply(
            [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
            [ 'Carp' ],
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

    cmp_deeply(
        \@prompts,
        [ $prompt ],
        'we were indeed prompted',
    );

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            '[PromptIfStale] comparing indexed vs. local version for Carp: indexed=200.0; local version=' . $CARP_VERSION,
            re(qr/^\Q[DZ] writing DZT-Sample in /),
        ),
        'build completed successfully',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
