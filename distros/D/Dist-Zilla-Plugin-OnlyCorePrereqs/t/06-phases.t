use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Moose::Util 'find_meta';

my @checked;
{
    use Module::CoreList;
    package Module::CoreList;
    no warnings 'redefine';
    sub first_release {
        my ($self, $module) = @_;
        push @checked, $module;
        return '5';  # pretend everything is in core
    }
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    (map {
                        my $type = $_;
                        map {
                            my $phase = $_;
                            [ Prereqs => ($phase . $type) => { "Prereq::${phase}::${type}" => '0' } ],
                        } qw(Configure Build Runtime Test Develop)
                    } qw(Requires Recommends Suggests Conflicts)),
                    [ OnlyCorePrereqs => ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build succeeded'
    );

    cmp_bag(
        \@checked,
        [ qw(
            Prereq::Configure::Requires
            Prereq::Build::Requires
            Prereq::Runtime::Requires
            Prereq::Test::Requires
        ) ],
        'correct phases and types are checked by default',
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
                                starting_version => 'to be determined from perl prereq',
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

undef @checked;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    (map {
                        my $type = $_;
                        map {
                            my $phase = $_;
                            [ Prereqs => ($phase . $type) => { "Prereq::${phase}::${type}" => '0' } ],
                        } qw(Configure Build Runtime Test Develop)
                    } qw(Requires Recommends Suggests Conflicts)),
                    [ OnlyCorePrereqs => { phase => [qw(develop)] }],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build succeeded'
    );

    cmp_bag(
        \@checked,
        [ qw(
            Prereq::Develop::Requires
        ) ],
        '"phase" option can be customized',
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
                                phases => [ 'develop' ],
                                starting_version => 'to be determined from perl prereq',
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

done_testing;
