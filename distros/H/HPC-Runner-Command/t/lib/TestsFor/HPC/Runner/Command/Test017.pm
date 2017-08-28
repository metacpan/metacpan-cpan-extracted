package TestsFor::HPC::Runner::Command::Test017;

use strict;
use warnings;

use Test::Class::Moose;
use HPC::Runner::Command;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use File::Slurp;
use File::Spec;
use File::Temp qw/ tempfile /;
use Path::Tiny;
use Archive::Tar;
use File::Find::Rule;
use IPC::Cmd qw[can_run run run_forked];

extends 'TestMethods::Base';

=head2 Purpose

Test github integration

=cut


sub write_test_file {
    my $test_dir = shift;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test002.1.sh' );
    my $text = <<EOF;
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

    write_file( $file, $text );
}

sub construct {
    my $self = shift;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    write_file('.gitignore', ".biosails/.hpcrunner-data\nhpc-runner");
    diag `git add -A`;
    diag `git commit -m "commit"`;
    diag `git tag -a hpcrunner-0.01 -m "hello"`;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test002.1.sh' );
    MooseX::App::ParsedArgv->new(
        argv => [
            "submit_jobs", "--infile", $file,
            "--hpc_plugins", "Dummy",
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    $test->logger('app_log');
    $test->log( $test->init_log );
    return $test;
}

sub test_001 : Tags(use_batches) {
    my $test     = construct();
    my $test_dir = getcwd();

    $test->execute;
    is($test->version, 'hpcrunner-0.02');
    ok($test->can('tags'));

    chdir $Bin;
    remove_tree($test_dir);
}

1;
