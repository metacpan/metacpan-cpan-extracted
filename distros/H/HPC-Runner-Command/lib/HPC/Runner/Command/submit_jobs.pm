package HPC::Runner::Command::submit_jobs;

=head1 HPC::Runner::Command::submit_jobs

Call the hpcrunner.pl submit_jobs command

=cut

use MooseX::App::Command;
use Moose::Util qw/apply_all_roles/;
extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::submit_jobs::Utils::Plugin';
with 'HPC::Runner::Command::execute_job::Utils::Plugin';
with 'HPC::Runner::Command::Logger::JSON';
with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'HPC::Runner::Command::Utils::Git';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler';
with 'HPC::Runner::Command::submit_jobs::Logger::JSON';

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
    documentation => 'Do a dry run - do not submit to the scheduler.',
    cmd_aliases   => ['dr'],
);

sub BUILD {
    my $self = shift;

    if ( $self->dry_run ) {
        $self->hpc_plugins( ['Dummy'] );
    }

    $self->git_things;
    $self->gen_load_plugins;
    $self->hpc_load_plugins;

    if ( $self->use_batches ) {
        apply_all_roles( $self,
            'HPC::Runner::Command::submit_jobs::Utils::Scheduler::UseBatches' );
    }
    else {
        apply_all_roles( $self,
            'HPC::Runner::Command::submit_jobs::Utils::Scheduler::UseArrays' );
    }

    my $tar = $self->set_archive;
    $self->archive($tar);
}

sub execute {
    my $self = shift;

    $self->app_log->info('Parsing input file');
    $self->create_json_submission;
    $self->parse_file_slurm;
    $self->app_log->info('Submitting jobs');
    $self->iterate_schedule;
    $self->update_json_submission;
    $self->app_log->info('Your jobs have been submitted.');
    $self->app_log->info('Experimental! For status updates please run:');
    $self->app_log->info('hpcrunner.pl stats');
    $self->app_log->info('To get status updates for only this submission please run:');
    $self->app_log->info('hpcrunner.pl stats --data_tar '.$self->data_tar);
}

1;
