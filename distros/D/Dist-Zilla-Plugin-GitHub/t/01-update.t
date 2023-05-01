use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Test::Deep::JSON;

{
    use Dist::Zilla::Plugin::GitHub;
    package Dist::Zilla::Plugin::GitHub;
    no warnings 'redefine';
    sub _build_credentials { return {login => 'bob', pass => q{} } }
    sub _get_repo_name { 'bob/My-Stuff' }
}

my $http_request;
{
    use HTTP::Tiny;
    package HTTP::Tiny;
    no warnings 'redefine';
    sub request {
        my $self = shift;
        $http_request = \@_;
        return +{
            success => 1,
            content => '{message:"?"}',
        };
    }
}

my @tests = (
    {
        test_name => 'homepage: meta_home',
        config => {
            meta_home => 1,
        },
        log_messages => [
            '[GitHub::Update] Updating GitHub repository info using distmeta URL',
        ],
        expected_request => [
            PATCH => 'https://api.github.com/repos/bob/My-Stuff' => {
                headers => { Accept => 'application/vnd.github.v3+json' },
                content => json({
                    name => 'My-Stuff',
                    description => 'Sample DZ Dist',
                    homepage => 'http://homepage',
                }),
            },
        ],
    },

    # tests needed:
    # - homepage: metacpan
    # - homepage: p4rl
    # - homepage: cpan
    # - 2fa
    # - no updates needed
);


subtest $_->{test_name} => sub
{
    my $test = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaResources => { homepage => 'http://homepage' } ],
                    [ MetaConfig => ],
                    [ FakeRelease => ],
                    [ 'GitHub::Update' => $test->{config} ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->release },
        undef,
        'release proceeds normally',
    );

    cmp_deeply(
        $http_request,
        $test->{expected_request},
        'HTTP request sent as requested',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::GitHub::Update',
                        config => {
                            'Dist::Zilla::Plugin::GitHub::Update' => $test->{config},
                        },
                        name => 'GitHub::Update',
                        version => ignore,
                    },
                ),
            }),
        }),
        'configs are logged',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    cmp_deeply(
        $tzil->log_messages,
        supersetof(@{ $test->{log_messages} }),
        'logged the right things',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
