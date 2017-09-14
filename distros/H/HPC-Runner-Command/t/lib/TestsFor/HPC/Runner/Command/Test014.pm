package TestsFor::HPC::Runner::Command::Test014;

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

Test for non linear task deps

=cut

$ENV{'SLURM_ARRAY_TASK_ID'} = 1;

sub write_test_file {
    my $test_dir = shift;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    my $text = <<EOF;
#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_1SE.fastq

#TASK tags=Sample_PAG008_V4_E2
gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_1PE.fastq
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
        argv => [
            "execute_array", "--infile", $file, '--commands', 1,
            '--batch_index_start', 1,
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('001_trimmomatic');
    $test->log( $test->init_log );

    $self->{test_obj} = $test;
    $self->{test_dir} = $test_dir;
    return $test;
}

sub test_001 : Tags(use_batches) {
    my $self = shift;

    my $cwd      = getcwd();
    my $test     = $self->construct;
    my $test_dir = getcwd();

    is( $test->read_command, 0, 'Read command passes' );
    is( $test->commands,     1, 'Num of commands passes' );

    my $fh = IO::File->new( $test->infile, q{<} );
    my $cmds = $test->parse_cmd_file($fh);

    my $expect_cmds =
      [     "#TASK tags=Sample_PAG008_V4_E2\n"
          . "gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq\n" ];
    is_deeply( $cmds, $expect_cmds, 'Commands pass' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_002 : Tags(use_batches) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    $test->commands(2);
    is( $test->read_command, 0, 'Read command passes' );
    is( $test->commands,     2, 'Num of commands passes' );

    my $fh = IO::File->new( $test->infile, q{<} );
    my $cmds = $test->parse_cmd_file($fh);

    my $expect_cmds = [
            "#TASK tags=Sample_PAG008_V4_E2\n"
          . "gzip -f Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq\n",

        "#TASK tags=Sample_PAG008_V4_E2\n"
          . "gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq\n",
    ];
    is_deeply( $cmds, $expect_cmds, 'Commands pass' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_003 : Tags(use_batches) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    $test->read_command(1);
    $test->commands(2);
    is( $test->read_command, 1, 'Read command passes' );
    is( $test->commands,     2, 'Num of commands passes' );

    my $fh = IO::File->new( $test->infile, q{<} );
    my $cmds = $test->parse_cmd_file($fh);

    my $expect_cmds = [
        "#TASK tags=Sample_PAG008_V4_E2\n"
          . "gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_2PE.fastq\n",
        "#TASK tags=Sample_PAG008_V4_E2\n"
          . "gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_1SE.fastq\n"
    ];

    is_deeply( $cmds, $expect_cmds, 'Commands pass' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_004 : Tags(use_batches) {
    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    $test->read_command(3);
    is( $test->read_command, 3, 'Read command passes' );
    is( $test->commands,     1, 'Num of commands passes' );

    my $fh = IO::File->new( $test->infile, q{<} );
    my $cmds = $test->parse_cmd_file($fh);

    my $expect_cmds =
      [     "#TASK tags=Sample_PAG008_V4_E2\n"
          . "gzip -f Sample_PAG008_V4_E2_read2_trimmomatic_1PE.fastq\n" ];
    is_deeply( $cmds, $expect_cmds, 'Commands pass' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_005 : Tags(use_batches) {
    my $test     = construct();
    my $test_dir = getcwd();

    my $fh = IO::File->new( $test->infile, q{<} );
    my $cmds = $test->parse_cmd_file($fh);

    write_file( 'Sample_PAG008_V4_E2_read1_trimmomatic_1PE.fastq',
        'THIS IS A FILE' );

    $test->cmd( $cmds->[0] );
    $test->_log_commands;

    my $complete_file =
      File::Spec->catdir( $test->data_dir, 'job', 'complete.json' );
    my $running_file =
      File::Spec->catdir( $test->data_dir, 'job', 'running.json' );

    ok( -e $complete_file );
    ok( -e $running_file );

    # $test->lock_file->touchpath;
    # my $ret = $test->check_lock;
    # is( $ret, 0, 'Lock file exists and should not be removed' );

    # diag($test->archive->get_content($complete_file));
    ok(1);

    chdir($Bin);
    remove_tree($test_dir);
}

1;
