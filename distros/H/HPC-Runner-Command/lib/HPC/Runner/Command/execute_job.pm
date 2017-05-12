package HPC::Runner::Command::execute_job;

use MooseX::App::Command;

extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'HPC::Runner::Command::Utils::Git';
with 'HPC::Runner::Command::execute_job::Utils::MCE';

command_short_description 'Execute commands';
command_long_description 'Take the parsed files from hpcrunner.pl submit_jobs and executes the code';

sub BUILD {
    my $self = shift;

    $self->git_things;
    $self->gen_load_plugins;
    $self->job_load_plugins;
}

sub execute {
    my $self = shift;

    $self->run_mce;
}

1;
