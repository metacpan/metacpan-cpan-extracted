package TestsFor::HPC::Runner::Command::Test006;

use strict;
use warnings;

use Test::Class::Moose;
use HPC::Runner::Command;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use Slurp;
use File::Slurp;

extends 'TestMethods::Base';

#Test for cases where we have a number of commnads not evenly divisable by the
#max_array_size

sub write_test_file {
    my $test_dir = shift;

    open( my $fh, ">$test_dir/script/test002.1.sh" );
    print $fh <<EOF;
#HPC jobname=pyfasta
#HPC procs=1
EOF

    for(my $x=1; $x<=13; $x++){
        print $fh "pyfasta split -n 20 Sample$x.fasta\n";
    }

    close($fh);
}

sub construct {
    my $self = shift;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t = "$test_dir/script/test002.1.sh";
    MooseX::App::ParsedArgv->new(
        argv => [
            "submit_jobs",    "--infile",
            $t,               "--outdir",
            "$test_dir/logs", "--hpc_plugins",
            "Dummy",
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    $test->log( $test->init_log );
    return $test;
}

sub test_001 : Tags(job_stats) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    $test->max_array_size(3);

    $test->parse_file_slurm();
    $test->iterate_schedule();

    is($test->jobs->{'pyfasta'}->{num_job_arrays}, 4);

    ok(1);
    
    chdir($cwd);
    remove_tree($test_dir);
}

1;
