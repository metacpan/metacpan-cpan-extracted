use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Moose::Util 'find_meta';

use Dist::Zilla::Plugin::OnlyCorePrereqs;   # make sure we are loaded!

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
                $module eq 'feature' ? '---
distfile: R/RJ/RJBS/perl-5.20.0.tar.gz
version: 1.36
'
                : $module eq 'if' ? '---
distfile: I/IL/ILYAZ/modules/if-0.0601.tar.gz
version: 0.0601
'
                : $module eq 'HTTP::Tiny' ? '---
distfile: D/DA/DAGOLDEN/HTTP-Tiny-0.053.tar.gz
version: 0.053
'
                : die "should not be checking for $module"
            ,
        };
    }
}


{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { 'HTTP::Tiny' => '0.025' } ],
                    [ OnlyCorePrereqs => { starting_version => '5.014', check_dual_life_versions => 0 } ],
                ),
            },
        },
    );

    # normally we'd see this:
    # [OnlyCorePrereqs] detected a runtime requires dependency on HTTP::Tiny
    # 0.025: perl 5.014 only has 0.012
    is(
        exception { $tzil->build },
        undef,
        'build succeeded, despite HTTP::Tiny not at 0.025 in perl 5.014'
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.014',
                                deprecated_ok => 0,
                                check_dual_life_versions => 0,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { 'HTTP::Tiny' => '0.025' } ],
                    # check_dual_life_versions defaults to true
                    [ OnlyCorePrereqs => { starting_version => '5.014' } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\Q[OnlyCorePrereqs] aborting build due to invalid dependencies\E/,
        'build aborted'
    );

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[OnlyCorePrereqs] detected a runtime requires dependency on HTTP::Tiny 0.025: perl 5.014 only has 0.012'),
        'build failed -- HTTP::Tiny not at 0.025 in perl 5.014'
    )
    or diag 'saw log messages: ', explain $tzil->log_messages;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.014',
                                deprecated_ok => 0,
                                check_dual_life_versions => 1,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { 'feature' => '1.33' } ],
                    [ OnlyCorePrereqs => { starting_version => '5.010000', check_dual_life_versions => 0 } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    # feature existed in 5.010, but not at the version we are asking for
    # feature is not dual-lifed, so we know the user hasn't upgraded.

    like(
        exception { $tzil->build },
        qr/\Q[OnlyCorePrereqs] aborting build due to invalid dependencies\E/,
        'build aborted'
    );

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[OnlyCorePrereqs] detected a runtime requires dependency on feature 1.33: perl 5.010000 only has 1.11'),
        'build failed -- feature not at this version in perl 5.010'
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.010000',
                                deprecated_ok => 0,
                                check_dual_life_versions => 0,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { 'if' => '0' } ],
                    [ OnlyCorePrereqs => { starting_version => '5.006', check_dual_life_versions => 0 } ],
                ),
            },
        },
    );

    # normally we'd see this:
    # [OnlyCorePrereqs] detected a runtime requires dependency that was not
    # added to core until 5.006002: if
    is(
        exception { $tzil->build },
        undef,
        'build succeeded, despite if (upstream=blead) not being in core in perl 5.006'
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.006',
                                deprecated_ok => 0,
                                check_dual_life_versions => 0,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { 'HTTP::Tiny' => '0.025' } ],
                    [ OnlyCorePrereqs => { starting_version => '5.008', check_dual_life_versions => 0 } ],
                ),
            },
        },
    );

    # normally we'd see this:
    # [OnlyCorePrereqs] detected a runtime requires dependency that was not
    # added to core until 5.013009: HTTP::Tiny
    is(
        exception { $tzil->build },
        undef,
        'build succeeded, despite HTTP::Tiny (upstream=cpan) not being in core in perl 5.008'
    )
    or diag 'saw log messages: ', explain $tzil->log_messages;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.008',
                                deprecated_ok => 0,
                                check_dual_life_versions => 0,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
