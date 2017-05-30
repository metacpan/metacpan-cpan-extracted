package TestsFor::HPC::Runner::Command::Test010;

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

Test for failing schedule

=cut

sub write_test_file {
    my $test_dir = shift;

    my $t = "$test_dir/script/test002.1.sh";
    open( my $fh, ">$t" );
    print $fh <<EOF;

#HPC jobname=fastqc
#HPC module=gencore/1 gencore_dev gencore_qc

#1234 t1
#TASK tags=Sample_1
fastqc Sample_1

#1234 t2
#TASK tags=Sample_2
fastqc Sample_2

#1235 t3
#TASK tags=Sample_3
fastqc Sample_4

#1235 t4
#TASK tags=Sample_4
fastqc Sample_4

#1236 t5
#TASK tags=Sample_5
fastqc Sample_5

#1236 t6
#TASK tags=Sample_6
fastqc Sample_6

#1237 t7
#TASK tags=Sample_6
fastqc Sample_6

#HPC jobname=remove_tmp
#HPC deps=fastqc

#1238 t8
#TASK tags=Sample_1
remove Sample_1

#1238 t9
#TASK tags=Sample_2
remove Sample_2

#1238 t10
#TASK tags=Sample_3
remove Sample_1

#1239 t11
#TASK tags=Sample_4
remove Sample_2

#1239 t12
#TASK tags=Sample_5
remove Sample_1

#1240 t13
#TASK tags=Sample_6
remove Sample_2

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
            $t,               "--max_array_size",
            2,                "--hpc_plugins",
            "Dummy",
        ]
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
    $test->iterate_schedule();

    my $array_deps = {
        '1238_8'  => ['1234_1'],
        '1238_9'  => ['1234_2'],
        '1239_10' => ['1235_3'],
        '1239_11' => ['1235_4'],
        '1240_12' => ['1236_5'],
        '1240_13' => ['1236_6', '1237_7'],
    };

    is_deeply( $test->array_deps, $array_deps );

    ok(1);

    # opendir DIR, $test->outdir or die "cannot open dir: $!";
    # my @files= readdir DIR;
    # diag(Dumper(\@files));
    # closedir DIR;
    #
    # my $file =  read_file($test->outdir.'/'.$files[4]);
    # diag($file);
    # is_deeply( $test->jobs->{raw_fastqc}->ntasks, 12 );

    chdir($cwd);
    remove_tree($test_dir);
}

1;
