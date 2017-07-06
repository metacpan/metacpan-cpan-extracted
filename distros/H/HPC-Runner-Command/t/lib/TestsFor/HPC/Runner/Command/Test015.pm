package TestsFor::HPC::Runner::Command::Test015;

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
use File::Spec;
use File::Temp qw/ tempfile /;

extends 'TestMethods::Base';

=head2 Purpose

Test for non linear task deps

=cut

sub write_test_file {
    my $test_dir = shift;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    my $text = <<EOF;
#HPC jobname=trimmomatic_gzip

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq

#HPC jobname=trimmomatic_gzip1
#HPC deps=trimmomatic_gzip

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq
EOF

    write_file( $file, $text );
}

sub construct {
    my $self = shift;

    $ENV{'SLURM_ARRAY_TASK_ID'} = 1;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    MooseX::App::ParsedArgv->new(
        argv => [ "submit_jobs", "--infile", $file, '--hpc_plugins', 'PBS', '--verbose'] );

    my $test = HPC::Runner::Command->new_with_command();
    $test->log( $test->init_log );
    return $test;
}

sub test_001 : Tags(use_batches) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    $test->submit_command('echo 1234');
    $test->parse_file_slurm();
    $test->iterate_schedule();

    my $pbs_scheduler_id = $test->parse_pbs_scheduler_id('1234[].hpc.edu', 1);
    is($pbs_scheduler_id, '1234[1].hpc.edu', 'PBS shceduler id parsed successfully');

    # my @files = system( "tree " . $test->outdir );
    # my $text  = read_file( $test->outdir . "/002_trimmomatic_gzip1.sh" );
    # diag Dumper( \@files );
    # diag Dumper($text);

    ok(1);

    chdir($cwd);
    remove_tree($test_dir);
}

1;
