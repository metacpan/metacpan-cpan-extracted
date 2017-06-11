package TestsFor::HPC::Runner::Command::Test012;

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

=head2 Purpose

Test for non linear task deps

=cut


sub write_test_file {
    my $test_dir = shift;

    my $t = "$test_dir/script/test002.1.sh";
    open( my $fh, ">$t" );
    print $fh <<EOF;

#HPC jobname=trimmomatic_gzip
#HPC commands_per_node=2

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1SE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2SE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read2_trimmomatic_2PE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read1_trimmomatic_1SE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read2_trimmomatic_2SE.fastq

#HPC jobname=trimmomatic_gzip1
#HPC deps=trimmomatic_gzip
#HPC commands_per_node=2

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1SE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2SE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read2_trimmomatic_2PE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read1_trimmomatic_1SE.fastq

#TASK tags=Sample_PAG025_V3_E2
gzip -f Sample_PAG025_V3_E2_read2_trimmomatic_2SE.fastq
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
            "submit_jobs", "--infile", $t, "--hpc_plugins",
            "Dummy",       "--use_batches"
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    $test->log( $test->init_log );
    return $test;
}

sub test_001 : Tags(use_batches) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    my ( $source, $dep );

    $test->parse_file_slurm();
    $test->iterate_schedule();

    is( $test->jobs->{'trimmomatic_gzip'}->{num_job_arrays},
        4, 'Num job arrays passes' );
    is( $test->jobs->{'trimmomatic_gzip'}->count_scheduler_ids,
        4, 'Count scheduler ids passes' );
    is( $test->jobs->{'trimmomatic_gzip'}->count_batch_indexes,
        4, 'Count batch indexes passes' );

    my $array_deps = {
        '1241' => [ '1236', '1237' ],
        '1240' => [ '1236', '1237' ],
        '1239' => [ '1234', '1235' ],
        '1238' => [ '1234', '1235' ]
    };

    my $rows = $test->summarize_jobs;

    my $expect_rows = [
        [ 'trimmomatic_gzip',  '1234', '1-2',   2 ],
        [ 'trimmomatic_gzip',  '1235', '3-4',   2 ],
        [ 'trimmomatic_gzip',  '1236', '5-6',   2 ],
        [ 'trimmomatic_gzip',  '1237', '7-8',   2 ],
        [ 'trimmomatic_gzip1', '1238', '9-10',  2 ],
        [ 'trimmomatic_gzip1', '1239', '11-12', 2 ],
        [ 'trimmomatic_gzip1', '1240', '13-14', 2 ],
        [ 'trimmomatic_gzip1', '1241', '15-16', 2 ]
    ];
    is_deeply( $rows, $expect_rows, 'Rows pass' );

    chdir($cwd);
    remove_tree($test_dir);
}

1;
