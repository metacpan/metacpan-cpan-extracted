use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;
use Test::Deep;
use Test::Fatal;
use Dist::Zilla;

# protect from external environment
local $ENV{TRIAL};
local $ENV{RELEASE_STATUS};

{
    package MyVersionProvider;
    use Moose;
    with 'Dist::Zilla::Role::VersionProvider';
    sub provide_version {
        my $self = shift;
        return '0.001' if $self->zilla->main_module;
    }
}

foreach my $trial (undef, 1)
{
    foreach my $release_status (undef, 'stable', 'unstable')
    { SKIP: {
        # When no environment variables are set, this test would fail with
        # Dist::Zilla >= 5.035, without our own adjustments to how we
        # calculate is_trial, because release_status is determined (by
        # default, when there are no ReleaseStatusProvider plugins) by
        # examining the distribution version, and calculating the version may
        # call VersionProvider plugins, which may require a main_module to be
        # present -- which is not the case if this is all happening before any
        # files have been gathered.

        local $ENV{TRIAL} = $trial if $trial;
        local $ENV{RELEASE_STATUS} = $release_status if $release_status;

        note 'TRIAL=' . ($ENV{TRIAL} || '')
            . '; RELEASE_STATUS=' . ($ENV{RELEASE_STATUS} || '');

        skip('inconsistent state; avoid trying to predict behaviour', 2)
            if $ENV{RELEASE_STATUS} and $ENV{TRIAL};

        skip('Dist::Zilla < 5.035 did not support this environment variable', 2)
            if $ENV{RELEASE_STATUS} and not eval { Dist::Zilla->VERSION('5.035') };

        skip('Dist::Zilla = 5.035 did not implement _release_status_from_env either', 2)
            if ($ENV{RELEASE_STATUS} or $ENV{TRIAL}) and Dist::Zilla->VERSION eq '5.035';

        my $tzil = Builder->from_config(
            { dist_root => 'does-not-exist' },
            {
                add_files => {
                    path(qw(source dist.ini)) => dist_ini(
                        {   # standard fields except no version
                            name     => 'DZT-Sample',
                            abstract => 'Sample DZ Dist',
                            author   => 'E. Xavier Ample <example@example.org>',
                            license  => 'Perl_5',
                            copyright_holder => 'E. Xavier Ample',
                        },
                        [ GatherDir => ],
                        [ '=MyVersionProvider' ],
                        [ MetaConfig => ],
                        [ 'Run::BeforeBuild' => {
                            run => [ '"%x" %o%pscript%pbefore_build.pl %o both' ],
                            run_if_trial => [ '"%x" %o%pscript%pbefore_build.pl %o trial' ],
                            run_no_trial => [ '"%x" %o%pscript%pbefore_build.pl %o notrial' ],
                          } ],
                    ),
                    path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                    path(qw(source script before_build.pl)) => <<'SCRIPT',
use strict;
use warnings;
use Path::Tiny;
path(shift, 'BEFORE_BUILD.txt')->append_utf8(shift, "\n");
SCRIPT
                },
            },
        );

        $tzil->chrome->logger->set_debug(1);
        is(
            exception { $tzil->build },
            undef,
            (join(' ',
                ( $ENV{RELEASE_STATUS} ? ('RELEASE_STATUS=' . $ENV{RELEASE_STATUS} ) : () ),
                ( $ENV{TRIAL} ? 'TRIAL=1' : () ),
            ) || 'normal')
                . ' build proceeded normally',
        );

        my $before_build_result = path($tzil->tempdir, qw(source BEFORE_BUILD.txt));

        is(
            $before_build_result->slurp_utf8,
            $ENV{TRIAL} || ($ENV{RELEASE_STATUS} || '') eq 'unstable' ? "both\ntrial\n" : "both\nnotrial\n",
            'before-build script was run at the right times',
        );

        diag 'got log messages: ', explain $tzil->log_messages
            if not Test::Builder->new->is_passing;
    } }
}

done_testing;
