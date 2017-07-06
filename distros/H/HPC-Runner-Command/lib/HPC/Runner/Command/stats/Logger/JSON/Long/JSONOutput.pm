package HPC::Runner::Command::stats::Logger::JSON::Long::JSONOutput;

use Moose::Role;
use namespace::autoclean;
use JSON;

with 'HPC::Runner::Command::stats::Logger::JSON::Summary';
with 'HPC::Runner::Command::stats::Logger::JSON::Summary::JSONOutput';

sub iter_jobs_long {
    my $self       = shift;
    my $submission = shift;
    my $jobref     = shift;

    my $submission_id = $submission->{uuid};
    my $start_time    = $submission->{submission_time} || '';
    my $project       = $submission->{project} || '';

    my $submission_obj = {};
    $submission_obj->{$submission_id}->{project}         = $project;
    $submission_obj->{$submission_id}->{submission_time} = $start_time;
    $submission_obj->{submission_data}                   = $submission;

    foreach my $job ( @{$jobref} ) {
        my $jobname = $job->{job};

        if ( $self->jobname ) {
            next unless $self->jobname eq $jobname;
        }
        my $total_tasks = $job->{total_tasks};

        # my $tasks = $self->get_tasks( $submission_id, $jobname );
        my $completed_tasks =
          $self->get_completed_tasks( $submission_id, $jobname );

        $submission_obj->{$submission_id}->{jobs}->{$jobname}->{tasks_complete}
          = $completed_tasks;

       # $submission_obj->{$submission_id}->{jobs}->{$jobname}->{tasks_complete}
       #   = $tasks;
        $self->task_data( {} );

        $self->iter_tasks_summary( $submission_id, $jobname );
        my $summary = $self->gen_job_tasks_summary($jobname);
        $summary->{$jobname}->{total_tasks} = $total_tasks;
        $submission_obj->{$submission_id}->{jobs}->{$jobname}->{summary} =
          $summary;

        my $running = $self->get_running_tasks( $submission_id, $jobname );
        $submission_obj->{$submission_id}->{jobs}->{$jobname}->{tasks_running}
          = $running;

        push( @{ $self->json_data }, $submission_obj );

    }

}

1;
