package TestsFor::HPC::Runner::Command::Test005;

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

sub write_test_file {
    my $test_dir = shift;

    open( my $fh, ">$test_dir/script/test002.1.sh" );
    print $fh <<EOF;
#HPC jobname=pyfasta
#HPC module=gencore_dev gencore_metagenomics_dev
#HPC commands_per_node=1
#HPC cpus_per_task=1
#HPC procs=2
#HPC partition=ser_std
#HPC mem=4GB
#HPC walltime=00:15:00

#TASK tags=Sample1
pyfasta split -n 20 Sample1.fasta

#TASK tags=Sample2
pyfasta split -n 20 Sample2.fasta

#TASK tags=Sample3
pyfasta split -n 20 Sample3.fasta

#TASK tags=Sample4
pyfasta split -n 20 Sample4.fasta

#TASK tags=Sample5
pyfasta split -n 20 Sample4.fasta

#TASK tags=Sample6
pyfasta split -n 20 Sample6.fasta

#HPC jobname=blastx_scratch
#HPC deps=pyfasta
#HPC module=gencore_dev gencore_metagenomics
#HPC commands_per_node=1
#HPC cpus_per_task=7
#HPC procs=1
#HPC partition=ser_std
#HPC mem=20GB
#HPC walltime=06:00:00

#TASK tags=Sample1
blastx -db  env_nr -query Sample1

#TASK tags=Sample2
blastx -db  env_nr -query Sample2

#TASK tags=Sample3
blastx -db  env_nr -query Sample3

#TASK tags=Sample4
blastx -db  env_nr -query Sample4

#TASK tags=Sample5
blastx -db  env_nr -query Sample5

#TASK tags=Sample6
blastx -db  env_nr -query Sample6

EOF

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

    my ( $source, $dep );

    $test->max_array_size(2);

    $test->parse_file_slurm();
    $test->iterate_schedule();

    is_deeply( [ 'pyfasta', 'blastx_scratch' ],
        $test->schedule, 'Schedule passes' );

    my $logdir = $test->logdir;
    my $outdir = $test->outdir;

    my @files = glob( $test->outdir . "/*" );

    is( scalar @files, 8, "Got the right number of files" );

    # diag Dumper(\@files);

    #We have 6 different batches spread over 3 arrays
    #Each batch corresponds to max_array_size
    #With max_array_size=2
    #batch 0-1 are array 1
    #batch 2-3 are array 2
    #batch 4-5 are array 3
    # is_deeply( $test->jobs->{'blastx_scratch'}->batches->[0]->array_deps,
    #     [ [ '1237_7', '1234_1' ] ] );
    # is_deeply( $test->jobs->{'blastx_scratch'}->batches->[1]->array_deps,
    #     [ [ '1237_8', '1234_2' ] ] );
    # is_deeply( $test->jobs->{'blastx_scratch'}->batches->[2]->array_deps,
    #     [ [ '1238_9', '1235_3' ] ] );
    # is_deeply( $test->jobs->{'blastx_scratch'}->batches->[3]->array_deps,
    #     [ [ '1238_10', '1235_4' ] ] );
    # is_deeply( $test->jobs->{'blastx_scratch'}->batches->[4]->array_deps,
    #     [ [ '1239_11', '1236_5' ] ] );
    # is_deeply( $test->jobs->{'blastx_scratch'}->batches->[5]->array_deps,
    #     [ [ '1239_12', '1236_6' ] ] );

    my $array_deps = {
        '1237_7'  => [ '1234_1' ],
        '1237_8'  => [ '1234_2' ],
        '1238_9'  => [ '1235_3' ],
        '1238_10' => [ '1235_4' ],
        '1239_11' => [ '1236_5' ],
        '1239_12' => [ '1236_6' ],
    };

    is_deeply( $test->array_deps, $array_deps );

    is_deeply(
        $test->jobs->{'blastx_scratch'}->batch_indexes->[0],
        { 'batch_index_start' => 7, 'batch_index_end' => 8 }
    );
    is_deeply(
        $test->jobs->{'blastx_scratch'}->batch_indexes->[1],
        { 'batch_index_start' => 9, 'batch_index_end' => 10 }
    );
    is_deeply(
        $test->jobs->{'blastx_scratch'}->batch_indexes->[2],
        { 'batch_index_start' => 11, 'batch_index_end' => 12 }
    );
    is( $test->jobs->{'blastx_scratch'}->batch_indexes->[3], undef );

    chdir($cwd);
    remove_tree($test_dir);

}

1;
