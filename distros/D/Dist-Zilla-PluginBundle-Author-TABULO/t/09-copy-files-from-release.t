use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util      qw(first uniq );
use List::MoreUtils qw(arrayify);

use Data::Printer;

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-TABULO' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

my $tempdir = no_git_tempdir();

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        tempdir_root => $tempdir->stringify,
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ '@Author::TABULO' => {
                    installer => 'MakeMaker',
                    '-remove' => \@REMOVED_PLUGINS,
                    server => 'none',
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                } ],
            ) . "\ncopy_file_from_release = extra_file\n",
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n\n1",
            path(qw(source lib DZT Sample2.pm)) => "package DZT::Sample2;\n\n1",
            path(qw(source extra_file)) => "this is a random data file\n",
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

# in 0.006, this accessor changed from returning a listref to a (sorted) list.
my @filenames = sort(uniq(arrayify ($tzil->plugin_named('@Author::TABULO/copy generated files')->filename)));
#say STDERR "TAU : I got filenames : " . np @filenames;
cmp_deeply(
    \@filenames,
    # (eval { Dist::Zilla::Plugin::CopyFilesFromRelease->VERSION('0.006') }
    #     ? \@filenames
    #     : $filenames[0]),
    [ sort(uniq(qw(CONTRIBUTING INSTALL LICENCE LICENSE extra_file ppport.h))) ],
    'additional copy_files_from_release file does not overshadow the defaults',
);

# check that everything we loaded is in the pluginbundle's run-requires
all_plugins_in_prereqs($tzil,
    exempt => [ 'Dist::Zilla::Plugin::GatherDir' ],     # used by us here
    additional => [
        'Dist::Zilla::Plugin::MakeMaker::Fallback',     # via default installer option
        'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback', # ""
    ],
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
