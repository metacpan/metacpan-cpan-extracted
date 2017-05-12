use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

use Cwd qw(getcwd);
use Test::More;
use Test::DZil;
use LocalBrewTests qw(tests_fail);

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}

sub run_tests {
    my ( $plugin ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tzil = Builder->from_config(
        { dist_root => 'fake-distributions/Fake' },
        { add_files => {
            'source/dist.ini' => simple_ini({
                name    => 'Fake',
                version => '0.01',
            }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                [ $plugin => {
                    brews => $perlbrew,
                }],
            ),
          },
        },
    );

    my $tempdir       = $tzil->tempdir;
    my $builddir      = $tempdir->subdir('build');
    my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

    $tzil->build;

    ok -e $expected_file, 'test created';
    chdir $builddir;

    tests_fail($expected_file);
}

my $wd = getcwd;

run_tests 'LocalBrew';
chdir $wd;
run_tests 'Test::LocalBrew';
chdir $wd;

done_testing;
