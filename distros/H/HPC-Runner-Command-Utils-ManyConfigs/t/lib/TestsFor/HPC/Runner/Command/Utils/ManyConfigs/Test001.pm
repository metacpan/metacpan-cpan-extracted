package ManyConfigTest;

use MooseX::App;

with 'HPC::Runner::Command::Utils::ManyConfigs';

option '+config_base' => ( default => '.hpcrunner' );

has 'plugins' => ( is => 'rw' );

package ManyConfigsTest::submit_jobs;

use MooseX::App::Command;
extends 'ManyConfigTest';

has 'dry_run' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub run {
    my $self = shift;
    print 'hello!';
}

1;

package TestsFor::HPC::Runner::Command::Utils::ManyConfigs::Test001;

use Moose;
use Test::Class::Moose;
use ManyConfigTest;
use Cwd;
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use File::Spec;
use YAML::XS;
use File::Temp;

sub make_test_dir {

    my $tmpdir = File::Spec->tmpdir();
    my $tmp    = File::Temp->newdir(
        UNLINK   => 0,
        CLEANUP  => 0,
        TEMPLATE => $tmpdir . '/hpcrunnerXXXXXXX'
    );
    my $test_dir = $tmp->dirname;

    remove_tree($test_dir);
    make_path($test_dir);

    open( my $fh, ">$test_dir/.hpcrunner.yml" );

    print $fh <<EOF;
---
global:
   plugins:
     - Slurm
submit_jobs:
   dry_run: 1
EOF
    close($fh);

    chdir($test_dir);

    return $test_dir;
}

sub test_001 : Tags(new) {

    my $test_dir = make_test_dir;
    my $test     = ManyConfigTest->new(
        config_base => '.hpcrunner',
        search_path => [$test_dir]
    );

    is_deeply( [ File::Spec->catfile( $test_dir, '.hpcrunner.yml' ) ],
        $test->config_files, 'Config files match' );

    my $cd_exp = {
        'global' => {
            'plugins' => ['Slurm']
        },
        'submit_jobs' => {
            'dry_run' => 1
        }
    };

    is_deeply(
        $cd_exp,
        $test->_config_data->[0]->{ $test->config_files->[0] },
        'config data matches'
    );

    is_deeply( ['Slurm'], $test->plugins, 'Conf was applied' );
    ok(1);
}
