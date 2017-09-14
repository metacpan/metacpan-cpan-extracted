package HPC::Runner::Command::submit_jobs;

=head1 HPC::Runner::Command::submit_jobs

Call the hpcrunner.pl submit_jobs command

  hpcrunner.pl submit_jobs -h

=cut

use MooseX::App::Command;
use Moose::Util qw/apply_all_roles/;

use File::Spec;
use File::Slurp;
use DateTime;

extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::submit_jobs::Utils::Plugin';
with 'HPC::Runner::Command::execute_job::Utils::Plugin';
with 'HPC::Runner::Command::Logger::JSON';
with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'BioSAILs::Integrations::Github';
with 'BioSAILs::Utils::CacheUtils';
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
}

sub execute {
    my $self = shift;

    $self->write_cache_files;
    $self->git_things;
    $self->app_log->info('Parsing input file');
    $self->parse_file_slurm;
    $self->create_json_submission;
    $self->app_log->info('Submitting jobs');
    $self->iterate_schedule;
    $self->update_json_submission;
    $self->app_log->info('Your jobs have been submitted.');

    ##Rolling this back until a future release
    $self->app_log->info('Experimental! For status updates please run:');
    $self->app_log->info('hpcrunner.pl stats');
    $self->app_log->info(
        'To get status updates for only this submission please run:');
    $self->app_log->info( 'hpcrunner.pl stats --data_dir ' . $self->data_dir );
}

##TODO Combine this with the BioX cache file functions

sub write_cache_files {
    my $self          = shift;
    my $cmd_line_opts = $self->print_cmd_line_opts;
    my $config_data   = $self->print_config_data;

    my $dt = DateTime->now( time_zone => 'local' );
    $dt = "$dt";
    $dt =~ s/:/-/g;

    my $cache_base = $self->infile->basename;

    $self->cache_file(
        File::Spec->catdir(
            $self->cache_dir, '.hpcrunner-cache',
            $cache_base . '--' . $dt . '.cache'
        )
    );

    write_file($self->cache_file, $cmd_line_opts);
    write_file($self->cache_file, {append => 1}, $config_data);

    my $data = read_file($self->infile);
    write_file($self->cache_file, {append => 1}, $data);
}

1;
