package HPC::Runner::Command::execute_job;

use MooseX::App::Command;
use JSON;

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
    is        => 'rw',
    isa       => 'Num',
    required  => 0,
    predicate => 'has_batch_index_start',
    documentation =>
      'Counter to tell execute_array where to start reading in the infile.'
      . ' Omit this option in order to run in single node.'
);

sub BUILD {
    my $self = shift;

    $self->git_things;
    $self->gen_load_plugins;
    $self->job_load_plugins;

    my $job_meta;
    if ( $self->metastr ) {
        $job_meta = decode_json( $self->metastr );
    }
    return unless defined $job_meta;

    if(exists $job_meta->{job_cmd_start}){
      $self->counter($job_meta->{job_cmd_start} + $self->batch_index_start);
    }

    my $tar = $self->set_archive;
    $self->archive($tar);
}

sub execute {
    my $self = shift;

    $self->run_mce;
}

1;
