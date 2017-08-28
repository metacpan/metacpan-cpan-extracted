package HPC::Runner::Command::single_node;

use MooseX::App::Command;
use namespace::autoclean;

extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::Logger::JSON';
with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'HPC::Runner::Command::Utils::Git';
with 'HPC::Runner::Command::execute_job::Utils::MCE';

command_short_description 'Execute commands';
command_long_description
  'Take the parsed files from hpcrunner.pl submit_jobs and executes the code';

option 'batch_index_start' => (
    is       => 'rw',
    isa      => 'Num',
    required => 0,
    predicate => 'has_batch_index_start',
    documentation =>
      'Counter to tell execute_array where to start reading in the infile.'
      . ' Omit this option in order to run in single node.'
);

sub BUILD {
    my $self = shift;

    $self->gen_load_plugins;
    $self->job_load_plugins;
}

sub execute {
    my $self = shift;

    $self->git_things;
    $self->single_node(1);
    $self->run_mce;
}

1;
