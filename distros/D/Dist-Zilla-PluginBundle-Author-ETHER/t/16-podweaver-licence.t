use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use PadWalker 'closed_over';

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

my @tests = (
    {
        expected_file => 'LICENCE',
        config => {},
    },
    {
        expected_file => 'LICENCE',
        config => { licence => 'LICENCE' },
    },
    {
        expected_file => 'LICENCE',
        config => { 'License.filename' => 'LICENCE' },
    },
    {
        expected_file => 'LICENCE',
        config => { authority => 'cpan:ETHER' },
    },
    {
        expected_file => 'LICENSE',
        config => { licence => 'LICENSE' },
    },
    {
        expected_file => 'LICENSE',
        config => { 'License.filename' => 'LICENSE' },
    },
    {
        expected_file => 'LICENSE',
        config => { authority => 'cpan:OTHERDUDE' },
    },
    {
        expected_file => 'LICENCE',
        config => { authority => 'cpan:BOBTFISH' },
    },
);

subtest "expecting $_->{expected_file} from config: " . join(' => ', %{ $_->{config} }) => sub {
    my $expected_file = $_->{expected_file};
    my $config = $_->{config};

    my $tempdir = no_git_tempdir();

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            tempdir_root => $tempdir->stringify,
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    {   # merge into root section
                        version => '0.005',
                    },
                    'GatherDir',
                    [ '@Author::ETHER' => {
                        '-remove' =>  \@REMOVED_PLUGINS,
                        installer => 'MakeMaker',
                        'RewriteVersion::Transitional.skip_version_provider' => 1,
                        %$config,
                      },
                    ],
                ),
                path(qw(source lib MyModule.pm)) => "package MyModule;\n\n1",
                path(qw(source Changes)) => '',
            },
        },
    );

    assert_no_git($tzil);

    # allow [Authority] to run multiple times without exploding
    undef ${ closed_over(\&Dist::Zilla::Plugin::Authority::metadata)->{'$seen_author'} };

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    my $build_dir = path($tzil->tempdir)->child('build');
    ok($build_dir->child($expected_file)->exists, "$expected_file is generated in the build");

    my $other_file = $expected_file eq 'LICENCE' ? 'LICENSE' : 'LICENCE';
    ok(!$build_dir->child($other_file)->exists, "$other_file is not generated in the build");

    like(
        $tzil->slurp_file('build/lib/MyModule.pm'),
        qr/COPYRIGHT AND $expected_file/,
        'correct Legal header is woven into pod',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
