package TestsFor::HPC::Runner::Command::Test011;

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

#1237 t8
#TASK tags=Sample_4
fastqc Sample_4

#HPC jobname=remove_tmp
#HPC deps=fastqc

#1238 t9
#TASK tags=Sample_1
remove Sample_1

#1238 t10
#TASK tags=Sample_2
remove Sample_2

#1238 t11
#TASK tags=Sample_3
remove Sample_1

#1239 t12
#TASK tags=Sample_4
remove Sample_2

#1239 t13
#TASK tags=Sample_5
remove Sample_1

#1240 t14
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
            "submit_jobs", "--infile",
            $t,            "--max_array_size",
            2,             "--hpc_plugins",
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
        '1238_9'  => ['1234_1'],
        '1238_10' => ['1234_2'],
        '1239_11' => ['1235_3'],
        '1239_12' => [ '1235_4', '1237_8' ],
        '1240_13' => ['1236_5'],
        '1240_14' => [ '1236_6', '1237_7' ],
    };

    is_deeply( $test->array_deps, $array_deps );
    is( $test->jobs->{'fastqc'}->{num_job_arrays}, 4 );

    my $rows = $test->summarize_jobs;

    ##TODO add in another one of these with commands_per_node
    my $expect_rows = [
        [ 'fastqc',     '1234', '1-2',   2 ],
        [ 'fastqc',     '1235', '3-4',   2 ],
        [ 'fastqc',     '1236', '5-6',   2 ],
        [ 'fastqc',     '1237', '7-8',   2 ],
        [ 'remove_tmp', '1238', '9-10',  2 ],
        [ 'remove_tmp', '1239', '11-12', 2 ],
        [ 'remove_tmp', '1240', '13-14', 2 ]
    ];
    is_deeply( $rows, $expect_rows, 'Summarize jobs passes pass' );

    $test->current_job('fastqc');
    is( $test->gen_array_str( $test->jobs->{fastqc}->batch_indexes->[0] ),
        '1-2:1', 'Array string passes' );
    is( $test->gen_array_str( $test->jobs->{fastqc}->batch_indexes->[1] ),
        '3-4:1', 'Array string passes' );
    is( $test->gen_array_str( $test->jobs->{fastqc}->batch_indexes->[2] ),
        '5-6:1', 'Array string passes' );
    is( $test->gen_array_str( $test->jobs->{fastqc}->batch_indexes->[3] ),
        '7-8:1', 'Array string passes' );

    $test->current_job('remove_tmp');
    is( $test->gen_array_str( $test->jobs->{remove_tmp}->batch_indexes->[0] ),
        '9-10:1', 'Array string passes' );
    is( $test->gen_array_str( $test->jobs->{remove_tmp}->batch_indexes->[1] ),
        '11-12:1', 'Array string passes' );
    is( $test->gen_array_str( $test->jobs->{remove_tmp}->batch_indexes->[2] ),
        '13-14:1', 'Array string passes' );

    chdir($cwd);
    remove_tree($test_dir);
}

1;
