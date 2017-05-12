use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -default => 1,
                            -prompt => 0,
                            # use default phase, type
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    x_default => 1,
                    description => 'feature description',
                    prereqs => {
                        runtime => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                runtime => { suggests => { A => 0 } },
                test => { requires => { Tester => 0 } },
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            always_suggest => 1,
                            require_develop => 1,
                            prompt => 0,
                            default => 1,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when -default is explicitly set to true',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

Dist::Zilla::Plugin::OptionalFeature::__clear_master_plugin();

{
    # if we always provide x_default in the metadata, this test is pretty
    # redundant with most of t/01-basic.t.
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -default => 0,
                            -prompt => 0,
                            # use default phase, type
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    x_default => 0,
                    description => 'feature description',
                    prereqs => {
                        runtime => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                runtime => { suggests => { A => 0 } },
                test => { requires => { Tester => 0 } },
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            always_suggest => 1,
                            require_develop => 1,
                            prompt => 0,
                            default => 0,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when -default is explicitly set to false',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
