package TestsFor::HPC::Runner::Command::Test009;

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

extends 'TestMethods::Base';

=head2 Purpose

Test for failing schedule

=cut

sub write_test_file {
    my $test_dir = shift;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    my $text = <<EOF;
#HPC jobname=raw_fastqc
#HPC module=gencore/1 gencore_dev gencore_qc
#HPC ntasks=12

#TASK tags=Sample_KO-H3K4Me3_1_R1
fastqc Sample_KO-H3K4Me3_1_R1 Sample_KO-H3K4Me3_1_R1

#HPC jobname=remove_tmp
#HPC deps=raw_fastq

#TASK tags=Sample_KO-H3K4Me3_1
remove_tmp Sample_KO-H3K4Me3_2_R1

EOF

    write_file( $file, $text );
}

sub construct {
    my $self = shift;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    MooseX::App::ParsedArgv->new(
        argv => [ "submit_jobs", "--infile", $file, "--hpc_plugins", "Dummy", ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    $test->log( $test->init_log );
    return $test;
}

sub test_001 : Tags(execute_array) {

    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    my ( $source, $dep );

    $test->parse_file_slurm();

    # $test->iterate_schedule();

    # # opendir DIR, $test->outdir or die "cannot open dir: $!";
    # # my @file= readdir DIR;
    # # diag(Dumper(\@file));
    # # closedir DIR;
    #
    # my $file =  read_file($test->outdir."/001_raw_fastqc.sh");
    #
    # diag($file);
    is_deeply( $test->jobs->{raw_fastqc}->ntasks, 12 );

    chdir($cwd);
    remove_tree($test_dir);
}

1;
