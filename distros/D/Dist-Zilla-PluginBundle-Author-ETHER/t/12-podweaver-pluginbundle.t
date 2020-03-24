use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

{
    package MyContributors;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider';
    sub metadata { +{ x_contributors => [ 'Anon Y. Moose <anon@null.com>' ] } }
}

# we need to test in a distribution with weaver.ini and without,
# to see that the same thing happens in each case --
# the config_plugins config is used, and
# we do not die from trying to use a broken weaver.ini.

# and we actually need to test without the config_plugin option as well, so we
# are sure we explode in each case!!

my @tests = (
    {
        name => 'weaver.ini is broken',
        corpus => 'corpus/with_broken_weaver_ini',
        has_config_plugin => 0,
        error => qr/illegal package name Pod::Weaver::PluginBundle::Def ault/,
    },
    {
        name => 'weaver.ini is broken',
        corpus => 'corpus/with_broken_weaver_ini',
        has_config_plugin => 1,
        # no error - config plugin used over weaver.ini
    },
    {
        name => 'weaver.ini is missing',
        corpus => 'corpus/with_no_weaver_ini',
        has_config_plugin => 0,
        # no error - no special config used
    },
    {
        name => 'weaver.ini is missing',
        corpus => 'corpus/with_no_weaver_ini',
        has_config_plugin => 1,
        # no error - config plugin used over weaver.ini
    },
);

subtest "$_->{name}, has_config_plugin = $_->{has_config_plugin}" => sub
{
    my $testcase = $_;
    my $tempdir = no_git_tempdir();

    my $tzil = Builder->from_config(
        { dist_root => $testcase->{corpus} },
        {
            tempdir_root => $tempdir->stringify,
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    '=MyContributors',
                    'MetaConfig',
                    [ PodWeaver => { $testcase->{has_config_plugin} ? ( config_plugin => '@Author::ETHER' ) : () } ],
                ),
                path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: Hello, this is foo

1;
=pod

=cut
FOO
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    if ($testcase->{error})
    {
        like(
            exception { $tzil->build },
            $testcase->{error},
            'build explodes when ' . $testcase->{name}
                . ' and there is ' . ($testcase->{has_config_file} ? 'a' : 'no' ) . ' config file',
        );

        diag 'got distmeta: ', explain $tzil->distmeta
            if not Test::Builder->new->is_passing;

        diag 'got log messages: ', explain $tzil->log_messages
            if not Test::Builder->new->is_passing;

        return;
    }

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally when ' . $testcase->{name}
            . ' and there is ' . ($testcase->{has_config_file} ? 'a' : 'no' ) . ' config file',
    );

    my $module = $tzil->slurp_file('build/lib/Foo.pm');
    my $version = $tzil->version;

    isnt(index($module, <<POD), -1, 'module has woven the encoding, NAME and VERSION sections into pod');
=pod

=encoding UTF-8

=head1 NAME

Foo - Hello, this is foo

=head1 VERSION

version $version

POD

    like($module, qr/^=head1 AUTHOR\n\n/m, 'module has woven the AUTHOR section into pod');

    my ($testsub, $verb) = $testcase->{has_config_plugin}
        ? ( sub { goto &like }, 'has' )
        : ( sub { goto &unlike }, "hasn't" );
    $testsub->(
        $module,
        qr/^=head1 CONTRIBUTOR\n\n.*Anon Y. Moose <anon\@null.com>\n\n/ms,
        "module $verb woven the CONTRIBUTOR section into pod",
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::PodWeaver',
                        config => superhashof({
                            'Dist::Zilla::Plugin::PodWeaver' => $testcase->{has_config_plugin}
                              ? (superhashof({
                                    config_plugins => [ '@Author::ETHER' ],
                                    # check that all plugins came from '@Author::ETHER'
                                    plugins => array_each(
                                        # TODO: we can use our bundle name in these
                                        # sections too, by adjusting how we set up the configs
                                        code(sub {
                                            ref $_[0] eq 'HASH' or return (0, 'not a HASH');
                                            $_[0]->{name} =~ m{^\@(CorePrep|Author::ETHER)/}
                                                or $_[0]->{class} =~ /^Pod::Weaver::Section::(Generic|Collect)$/
                                                or return (0, 'weaver plugin has bad name');
                                            return 1;
                                        }),
                                    ),
                                }))
                              : notexists('config_plugins'),
                        }),
                        name => 'PodWeaver',
                        version => Dist::Zilla::Plugin::PodWeaver->VERSION,
                    },
                ),
            }),
        }),
        'weaver plugin config is properly included in metadata - config_plugin is always used by [PodWeaver], when provided'
    )
    or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
