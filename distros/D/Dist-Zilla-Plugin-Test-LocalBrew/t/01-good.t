use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

use Cwd qw(getcwd);
use Test::More;
use Test::DZil;
use LocalBrewTests qw(tests_pass);

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

    # Thanks to test-kwailtee.t in the Dist-Zilla-Plugin-Test-Kwalitee
    # distribution for making this bit easier on me
    my $tempdir       = $tzil->tempdir;
    my $builddir      = $tempdir->subdir('build');
    my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

    $tzil->build;

    ok -e $expected_file, 'test created';
    chdir $builddir;

    tests_pass($expected_file);

    local $ENV{'PERL5LIB'} = ''; # not doing this breaks our bootstrap tests
    my $output = `eval \$(perlbrew env '$perlbrew') && export PATH="\$PERLBREW_PATH:\$PATH" && perl -MIO::String -e 'print \$INC{"IO/String.pm"}' 2>&1`;

    isnt $?, 0, "IO::String should not be successfully found after the test is run";
    like $output, qr#Can't locate IO/String.pm in \@INC#;
}

my $wd = getcwd;

run_tests 'LocalBrew';
chdir $wd;
run_tests 'Test::LocalBrew';
chdir $wd;

done_testing;
