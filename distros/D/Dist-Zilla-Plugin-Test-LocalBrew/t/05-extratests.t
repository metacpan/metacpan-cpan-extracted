use strict;
use warnings;
use lib 't/lib';

use Cwd qw(getcwd);
use Test::More;
use Test::DZil;
use LocalBrewTests qw(tests_pass);

sub run_tests {
    my ( $perlbrew, $plugin ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tzil = Builder->from_config(
        { dist_root => 'fake-distributions/Fake' },
        { add_files => {
            'source/dist.ini' => simple_ini({
                name    => 'Fake',
                version => '0.01',
            }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest', 'ExtraTests',
                [ Prereqs => {
                    'IO::String' => 0,
                }],
                [ $plugin => {
                    brews => $perlbrew,
                }],
            ),
          },
        },
    );

    my $tempdir       = $tzil->tempdir;
    my $builddir      = $tempdir->subdir('build');
    my $expected_file = $builddir->subdir('t')->file("release-localbrew-$perlbrew.t");

    $tzil->build;
    ok -e $expected_file, 'test created';
    chdir $builddir;

    local $ENV{'RELEASE_TESTING'} = 1;
    tests_pass($expected_file);
}

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}

my $wd = getcwd;

run_tests $perlbrew, 'LocalBrew';
chdir $wd;
run_tests $perlbrew, 'Test::LocalBrew';
chdir $wd;

done_testing;
