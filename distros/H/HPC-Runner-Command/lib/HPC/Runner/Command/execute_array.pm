package HPC::Runner::Command::execute_array;

use MooseX::App::Command;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;
use JSON::XS;
use Try::Tiny;

extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'HPC::Runner::Command::Utils::Git';
with 'HPC::Runner::Command::execute_job::Utils::MCE';

command_short_description 'Execute commands';
command_long_description
  'Take the parsed files from hpcrunner.pl submit_jobs and executes the code';

option 'infile' => (
    is       => 'rw',
    required => 0,
    documentation =>
q{File of commands separated by newline. The command 'wait' indicates all previous commands should finish before starting the next one.},
    isa    => AbsFile,
    coerce => 1,
);

has 'task_id' => (
    is      => 'rw',
    default => sub {
        return
             $ENV{'SLURM_ARRAY_TASK_ID'}
          || $ENV{'SBATCH_ARRAY_TASK_ID'}
          || $ENV{'PBS_ARRAYID'}
          || $ENV{'SGE_TASK_ID'}
          || 0;
    },
    required => 0,
);

sub BUILD {}

after 'BUILD' => sub {
    my $self = shift;

    if ( !$self->task_id && !$self->infile ) {
        $self->app_log->fatal(
'There is no infile and this does not seem to be an array job. Aborting mission!'
        );
        exit 1;
    }

    $self->git_things;

    $self->get_infile;
    $self->counter( $self->task_id );

    $self->gen_load_plugins;
    $self->job_load_plugins;
};

sub execute {
    my $self = shift;

    $self->run_mce;
}

sub get_infile {
    my $self = shift;

    my $outdir = $self->outdir;
    my $array_counter = sprintf( "%03d", $self->task_id );
    my $infile;

    $infile =
      $self->outdir . "/" . $self->logname . "_" . $array_counter . ".in";

    try {
        $self->infile($infile);
    }
    catch {
        $self->app_log->fatal(
            'Infile ' . $infile . ' does not exist! Aborting mission!' );
        exit 1;
    }
}

1;
