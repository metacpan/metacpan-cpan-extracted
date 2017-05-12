use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use File::pushd 'pushd';
use Dist::Zilla::Tester;

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

my $dist_root;
$dist_root = pushd('corpus/with_weaver_ini') if Dist::Zilla::Tester->VERSION < '6.003';

my $tzil = Builder->from_config(
    # newer Dist::Zilla::Tester chdirs into source/ so we need to copy the files we need
    { dist_root => Dist::Zilla::Tester->VERSION < '6.003' ? 'does-not-exist' : 'corpus/with_weaver_ini' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ '@Author::ETHER' => {
                    -remove => \@REMOVED_PLUGINS,
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    'Test::MinimumVersion.max_target_perl' => '5.008',
                } ],
            ),
            path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: Hello, this is foo

1;
=pod

=cut
FOO
            path(qw(source Changes)) => '',
        },
    },
);

assert_no_git($tzil);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $plugin = $tzil->plugin_named('@Author::ETHER/PodWeaver');
cmp_deeply(
    $plugin,
    noclass(superhashof({
        replacer => 'replace_with_comment',
        post_code_replacer => 'replace_with_nothing',
    })),
    'other [PodWeaver] configs survived',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::PodWeaver',
                    config => superhashof({
                        'Dist::Zilla::Plugin::PodWeaver' => all(
                            notexists('config_plugins'),
                            superhashof({
                                # check that all plugins came from '@Default',
                                # *not* [@Author::ETHER].
                                plugins => array_each(
                                    code(sub {
                                        ref $_[0] eq 'HASH' or return (0, 'not a HASH');
                                        $_[0]->{name} =~ m{^\@(CorePrep|Default)/}
                                            or $_[0]->{class} =~ /^Pod::Weaver::Section::(Generic|Collect)$/
                                            or return (0, 'weaver plugin has bad name');
                                        return 1;
                                    }),
                                ),
                                # TODO: Pod::Elemental::PerlMunger does not add these
                                # replacer => 'replace_with_comment',
                                # post_code_replacer => 'replace_with_nothing',
                            }),
                        ),
                    }),
                    name => '@Author::ETHER/PodWeaver',
                    version => Dist::Zilla::Plugin::PodWeaver->VERSION,
                },
            ),
        }),
    }),
    'weaver plugin config is properly included in metadata - weaver.ini exists, so bundle is NOT used',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
