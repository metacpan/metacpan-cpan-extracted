use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 'first';
use Moose::Util 'find_meta';

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        # tempdir_root => default
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    version => '0.005',
                },
                [ 'GatherDir' => { exclude_filename => [ 'cpanfile' ] } ],
                [ '@Author::ETHER' => {
                    -remove => [ grep $_ ne 'Git::Commit', @REMOVED_PLUGINS ],
                    server => 'none',
                    installer => 'MakeMaker',
                    ':version' => '0.002',
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    cpanfile => 1,
                } ],
            ),
            path(qw(source lib MyModule.pm)) => "package MyModule;\n\n1",
            path(qw(source Changes)) => '',
            path(qw(source cpanfile)) => '',
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my @plugin_classes = map find_meta($_)->name, @{$tzil->plugins};
is(
    scalar(grep $_ eq 'Dist::Zilla::Plugin::CPANFile', @plugin_classes),
    1,
    'CPANFile is in the plugin list',
);

my $build_dir = path($tzil->tempdir)->child('build');

cmp_deeply(
    [ recursive_child_files($build_dir) ],
    supersetof('cpanfile'),
    'cpanfile is added to the distribution',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::CopyFilesFromRelease',
                    config => superhashof({
                        'Dist::Zilla::Plugin::CopyFilesFromRelease' => superhashof({
                            filename => superbagof(qw(cpanfile)),
                        }),
                    }),
                    name => '@Author::ETHER/copy generated files',
                    version => Dist::Zilla::Plugin::CopyFilesFromRelease->VERSION,
                },
            ),
        }),
    }),
    'config is properly included in metadata',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

SKIP: {
skip '$cwd needs to be $zilla->root for this test', 1 if not eval { Dist::Zilla->VERSION('6.003') };

my $git_commit = first { $_->isa('Dist::Zilla::Plugin::Git::Commit') } @{ $tzil->plugins };
cmp_deeply(
    $git_commit,
    methods(
        allow_dirty => [ map str($_), 'Changes', 'cpanfile' ],
    ),
    'payload for [Git::NextVersion] is passed along to [Git::Commit] that performs the release snapshot',
)
or diag 'got allow_dirty payload: ',
    explain $git_commit->allow_dirty;
}

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
