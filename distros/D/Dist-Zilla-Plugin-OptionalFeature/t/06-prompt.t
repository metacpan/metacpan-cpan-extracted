use strict;
use warnings;

use utf8;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

binmode Test::More->builder->$_, ':encoding(UTF-8)' foreach qw(output failure_output todo_output);
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# need a simple feature with two runtime prereqs, defaulting to y
# observe that Makefile.PL is munged with correct content

# now use a feature with one test prereq, defaulting to n

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
                    [ MakeMaker => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'runtime',
                            -relationship => 'requires',
                            -prompt => 1,
                            -default => 1,
                            'Foo' => '1.0',
                        },
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            optional_features => {
                FeatureName => {
                    x_default => 1,
                    description => 'feature description',
                    prereqs => {
                        runtime => { requires => {
                            'Foo' => '1.0',
                        } },
                    },
                },
            },
            prereqs => {
                # no runtime recommendations
                configure => { requires => ignore },
                runtime => { suggests => { 'Foo' => '1.0' } },
                test => { requires => { Tester => 0 } },
                develop => { requires => {
                    'Foo' => '1.0',
                } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
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
                                prompt => 1,
                                default => 1,
                                check_prereqs => 1,
                                phase => 'runtime',
                                type => 'requires',
                                prereqs => {
                                    'Foo' => '1.0',
                                },
                            },
                        },
                    },
                    superhashof({
                        class   => 'Dist::Zilla::Plugin::DynamicPrereqs',
                        name    => 'via OptionalFeature',
                        version => Dist::Zilla::Plugin::DynamicPrereqs->VERSION,
                    }),
                ),
            }),
        }),
        'metadata correct when minimal config provided',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr!
\Qrequires('Foo', '1.0')\E
  \Qif has_module('Foo', '1.0')
    || prompt('install feature description? [Y/n]', 'Y') =~ /^y/i;\E
!,
        'Makefile.PL contains the correct code for runtime prereqs with -prompt = 1',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

Dist::Zilla::Plugin::OptionalFeature::__clear_master_plugin();

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
                    [ MakeMaker => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'test',
                            -relationship => 'requires',
                            -prompt => 1,
                            -default => 0,
                            'Foo' => '1.0', 'Bar' => '2.0',
                        },
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            optional_features => {
                FeatureName => {
                    x_default => 0,
                    description => 'feature description',
                    prereqs => {
                        test => { requires => {
                            'Foo' => '1.0',
                            'Bar' => '2.0',
                        } },
                    },
                },
            },
            prereqs => {
                configure => { requires => ignore },
                test => {
                    requires => { Tester => 0 },
                    suggests => {
                        'Foo' => '1.0',
                        'Bar' => '2.0',
                    },
                },
                develop => { requires => {
                    'Foo' => '1.0',
                    'Bar' => '2.0',
                } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
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
                                prompt => 1,
                                default => 0,
                                check_prereqs => 1,
                                phase => 'test',
                                type => 'requires',
                                prereqs => {
                                    'Foo' => '1.0',
                                    'Bar' => '2.0',
                                },
                            },
                        },
                    },
                    superhashof({
                        class   => 'Dist::Zilla::Plugin::DynamicPrereqs',
                        name    => 'via OptionalFeature',
                        version => Dist::Zilla::Plugin::DynamicPrereqs->VERSION,
                    }),
                ),
            }),
        }),
        'metadata correct when minimal config provided',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr!
\Qif (has_module('Bar', '2.0') && has_module('Foo', '1.0')
    || prompt('install feature description? [y/N]', 'N') =~ /^y/i) {\E
  \Qtest_requires('Bar', '2.0');\E
  \Qtest_requires('Foo', '1.0');\E
!,
        # } to mollify vim
        'Makefile.PL contains the correct code for runtime prereqs with -prompt = 1',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

Dist::Zilla::Plugin::OptionalFeature::__clear_master_plugin();

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'runtime',
                            -relationship => 'recommends',
                            -prompt => 1,
                            'Foo' => '1.0', 'Bar' => '2.0',
                        },
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/prompts are only used for the 'requires' type/,
        'prompting cannot be combined with the recommends or suggests prereq type',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

Dist::Zilla::Plugin::OptionalFeature::__clear_master_plugin();

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
                    [ MakeMaker => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description with "çƦăż\'ɏ" characters',
                            -phase => 'test',
                            -relationship => 'requires',
                            -prompt => 1,
                            -default => 0,
                            'Foo' => '1.0', 'Bar' => '2.0',
                        },
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            optional_features => {
                FeatureName => {
                    x_default => 0,
                    description => 'feature description with "çƦăż\'ɏ" characters',
                    prereqs => {
                        test => { requires => {
                            'Foo' => '1.0',
                            'Bar' => '2.0',
                        } },
                    },
                },
            },
            prereqs => {
                configure => { requires => ignore },
                test => {
                    requires => { Tester => 0 },
                    suggests => {
                        'Foo' => '1.0',
                        'Bar' => '2.0',
                    },
                },
                develop => { requires => {
                    'Foo' => '1.0',
                    'Bar' => '2.0',
                } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class   => 'Dist::Zilla::Plugin::OptionalFeature',
                        name    => 'FeatureName',
                        version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                        config => {
                            'Dist::Zilla::Plugin::OptionalFeature' => {
                                name => 'FeatureName',
                                description => 'feature description with "çƦăż\'ɏ" characters',
                                always_recommend => 0,
                                always_suggest => 1,
                                require_develop => 1,
                                prompt => 1,
                                default => 0,
                                check_prereqs => 1,
                                phase => 'test',
                                type => 'requires',
                                prereqs => {
                                    'Foo' => '1.0',
                                    'Bar' => '2.0',
                                },
                            },
                        },
                    },
                    superhashof({
                        class   => 'Dist::Zilla::Plugin::DynamicPrereqs',
                        name    => 'via OptionalFeature',
                        version => Dist::Zilla::Plugin::DynamicPrereqs->VERSION,
                    }),
                ),
            }),
        }),
        'metadata correct when minimal config provided',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    TODO: {
        local $TODO = 'x_ keys should be valid everywhere!';
        is_valid_spec($tzil);
    }

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr!
\Qif (has_module('Bar', '2.0') && has_module('Foo', '1.0')
    || prompt('install feature description with "çƦăż\'ɏ" characters? [y/N]', 'N') =~ /^y/i) {\E
  \Qtest_requires('Bar', '2.0');\E
  \Qtest_requires('Foo', '1.0');\E
!,
        # } to mollify vim
        'Makefile.PL contains the correct code for runtime prereqs with -prompt = 1',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
