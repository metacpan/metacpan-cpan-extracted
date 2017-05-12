use strict;
use warnings;
use lib 'lib';

use Cwd qw(getcwd);
use Test::Exception;
use Test::More;
use Test::DZil;

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
                }],
            ),
          },
        },
    );

    throws_ok {
        $tzil->build;
    } qr/No perlbrew environments specified/;
}

my $wd = getcwd;

run_tests 'LocalBrew';
chdir $wd;
run_tests 'Test::LocalBrew';
chdir $wd;

done_testing;
