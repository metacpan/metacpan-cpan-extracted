package HPC::Runner::Command::submit_jobs;

=head1 HPC::Runner::Command::submit_jobs

Call the hpcrunner.pl submit_jobs command

=cut

use MooseX::App::Command;
extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'HPC::Runner::Command::Utils::Git';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler';

command_short_description 'Submit jobs to the HPC system';
command_long_description 'This job parses your input file and writes out one or
more templates to submit to the scheduler of your choice (SLURM, PBS, etc)';

=head2 Attributes

=head2 Subroutines

=cut

option 'dry_run' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Do a dry run - do not submit to the scheduler.'
);

# TODO investigate changing this to after 'BUILD'.

sub BUILD {
    my $self = shift;

    if ( $self->dry_run ) {
        $self->hpc_plugins(['Dummy']);
    }

    $self->git_things;
    $self->gen_load_plugins;
    $self->hpc_load_plugins;
}

sub execute {
    my $self = shift;

    $self->parse_file_slurm();
    $self->iterate_schedule();
}

1;
