package TestsFor::HPC::Runner::Command::Test007;

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

sub write_test_file {
    my $test_dir = shift;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    my $text = <<EOF;
#
# Starting raw_fastqc
#

#
#HPC jobname=raw_fastqc
#HPC module=gencore/1 gencore_dev gencore_qc
#HPC ntasks=1
#HPC procs=1
#HPC commands_per_node=1

#TASK tags=Sample_1
raw_fastqc sample1

#TASK tags=Sample_1
raw_fastqc sample1

#TASK tags=Sample_2
raw_fastqc sample2

#TASK tags=Sample_2
raw_fastqc sample2

#TASK tags=Sample_5
raw_fastqc sample5

#TASK tags=Sample_5
raw_fastqc sample5

#
#HPC jobname=trimmomatic
#HPC module=gencore/1 gencore_dev gencore_qc
#

#TASK tags=Sample_1
trimmomatic sample1

#TASK tags=Sample_2
trimmomatic sample2

#TASK tags=Sample_5
trimmomatic sample5

#
#HPC jobname=trimmomatic_fastqc
#HPC module=gencore/1 gencore_dev gencore_qc
#HPC deps=trimmomatic

#TASK tags=Sample_1
trimmomatic_fastqc sample1_read1

#TASK tags=Sample_1
trimmomatic_fastqc sample1_read2


#TASK tags=Sample_2
trimmomatic_fastqc sample2_read1

#TASK tags=Sample_2
trimmomatic_fastqc sample2_read2

#TASK tags=Sample_5
trimmomatic_fastqc sample5_read1

#TASK tags=Sample_5
trimmomatic_fastqc sample5_read2

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

sub test_001 : Tags(job_stats) {

    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    my ( $source, $dep );

    $test->parse_file_slurm();
    $test->iterate_schedule();

    is_deeply( [ 'raw_fastqc', 'trimmomatic', 'trimmomatic_fastqc' ],
        $test->schedule, 'Schedule passes' );

    my $logdir = $test->logdir;
    my $outdir = $test->outdir;

    my @files = glob( File::Spec->catdir( $test->outdir, "*" ) );

    #print "Files are ".join("\n", @files)."\n";

    my $submit_file = File::Spec->catdir( $outdir, "001_raw_fastqc.sh" );
    my $text = read_file($submit_file);

    #print "Submit file is \n$text\n";
    #diag "MOdules are ".Dumper($test->jobs->{'raw_fastqc'}->module);

    #foreach my $module (@{$test->jobs->{raw_fastqc}->module}){
    #diag("Module is ".Dumper($module));
    #}

    #is( scalar @files, 18, "Got the right number of files" );

    #diag(Dumper($test->jobs->{'blastx_scratch'}));
    #diag(Dumper($test->jobs->{'trimmomatic'}));
    #diag(Dumper($test->jobs->{'trimmomatic_fastqc'}->deps));
    #diag(Dumper($test->jobs->{'trimmomatic_fastqc'}->all_batch_indexes));
    #diag(Dumper($test->jobs->{'trimmomatic'}->all_batch_indexes));
    #diag(Dumper($test->jobs->{'blastx_scratch'}->batches->[0]->array_deps));

    diag('Ending Test007');
    chdir($cwd);
    remove_tree($test_dir);
}

1;
