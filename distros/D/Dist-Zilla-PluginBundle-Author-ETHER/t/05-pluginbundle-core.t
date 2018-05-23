use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

# tests the core plugin - with all options disabled

{
    my $tempdir = no_git_tempdir();
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            tempdir_root => $tempdir->stringify,
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    [ '@Author::ETHER' => {
                        '-remove' => \@REMOVED_PLUGINS,
                        server => 'none',
                        installer => 'MakeMaker',
                        'RewriteVersion::Transitional.skip_version_provider' => 1,
                      },
                    ],
                ),
                path(qw(source lib MyModule.pm)) => "package MyModule;\n\n1",
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

    # check that everything we loaded is properly declared as prereqs
    all_plugins_in_prereqs($tzil,
        exempt => [ 'Dist::Zilla::Plugin::GatherDir' ],     # used by us here
        additional => [ 'Dist::Zilla::Plugin::MakeMaker' ], # via installer option
    );

    is(
        $tzil->plugin_named('@Author::ETHER/Test::MinimumVersion')->max_target_perl,
        '5.006',
        'max_target_perl option defaults to 5.006 (when not overridden with a slice)',
    );

    ok(!-e "build/$_", "no $_ was created in the distribution") foreach qw(Makefile.PL Build.PL);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
