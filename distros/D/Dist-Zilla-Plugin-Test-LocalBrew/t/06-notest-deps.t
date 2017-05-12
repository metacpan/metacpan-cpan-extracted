use strict;
use warnings;
use lib 't/lib';

use Cwd qw(getcwd);
use Test::More;
use Test::DZil;
use LocalBrewTests qw(tests_fail tests_pass);

sub run_tests {
    my ( $perlbrew, $plugin ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $wd = getcwd;

    do { # try a bad distribution without notest_deps
        my $tzil = Builder->from_config(
            { dist_root => 'fake-distributions/RequiresBadFake' },
            { add_files => {
                'source/dist.ini' => simple_ini({
                    name    => 'RequiresBadFake',
                    version => '0.01',
                }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                    [ Prereqs => {
                        'BadFake' => 0,
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
        my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

        $tzil->build;

        chdir $builddir;
        tests_fail($expected_file);
    };

    chdir $wd;

    do { # try a bad distribution with notest_deps
        my $tzil = Builder->from_config(
            { dist_root => 'fake-distributions/RequiresBadFake' },
            { add_files => {
                'source/dist.ini' => simple_ini({
                    name    => 'RequiresBadFake',
                    version => '0.01',
                }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                    [ Prereqs => {
                        'BadFake' => 0,
                    }],
                    [ $plugin => {
                        notest_deps => 1,
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

        chdir $builddir;
        tests_pass($expected_file);
    };

    chdir $wd;

    do { # try a distribution with failing tests to make sure we actually test things
        my $tzil = Builder->from_config(
            { dist_root => 'fake-distributions/Fake' },
            { add_files => {
                'source/dist.ini' => simple_ini({
                    name    => 'Fake',
                    version => '0.01',
                }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                    [ $plugin => {
                        notest_deps => 1,
                        brews       => $perlbrew,
                    }],
                ),
              },
            },
        );

        my $tempdir       = $tzil->tempdir;
        my $builddir      = $tempdir->subdir('build');
        my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

        $tzil->build;

        chdir $builddir;

        tests_fail($expected_file);
    };

    chdir $wd;
}

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}

my $wd = getcwd;

$ENV{'PERL_CPANM_OPT'} = "--mirror-only --mirror file:///$wd/fake-cpan/";
run_tests $perlbrew, 'LocalBrew';
run_tests $perlbrew, 'Test::LocalBrew';

done_testing;
