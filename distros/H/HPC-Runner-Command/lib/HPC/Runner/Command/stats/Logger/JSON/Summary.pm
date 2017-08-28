package HPC::Runner::Command::stats::Logger::JSON::Summary;
use Moose::Role;

use JSON;
use Try::Tiny;

##This is probably mostly the same across plugins
sub iter_tasks_summary {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $running = $self->count_running_tasks( $submission_id, $jobname );
    my $success = $self->count_successful_tasks( $submission_id, $jobname );
    my $fail = $self->count_failed_tasks( $submission_id, $jobname );
    my $complete = $success + $fail;

    $self->task_data->{$jobname} = {
        complete => $complete,
        success  => $success,
        fail     => $fail,
        running  => $running
    };
}

sub count_running_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $basename = $self->data_tar->basename('.tar.gz');
    my $running_file =
      File::Spec->catdir( $basename, $jobname, 'running.json' );

    if ( $self->archive->contains_file($running_file) ) {
        my $running_json = $self->archive->get_content($running_file);
        ##TODO Add in some error checking
        my $running;
        try {
            $running = decode_json($running_json);
        }
        catch {
            $running = {};
        };
        my @keys = keys %{$running};
        return scalar @keys;
    }
    else {
        return 0;
    }
}

sub get_running_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $basename = $self->data_tar->basename('.tar.gz');
    my $running_file =
      File::Spec->catdir( $basename, $jobname, 'running.json' );

    if ( $self->archive->contains_file($running_file) ) {
        my $running_json = $self->archive->get_content($running_file);
        ##TODO Add in some error checking
        my $running = decode_json($running_json);
        return $running;
    }
    else {
        return {};
    }

}

sub get_completed_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $basename = $self->data_tar->basename('.tar.gz');
    my $complete_file =
      File::Spec->catdir( $basename, $jobname, 'complete.json' );

    if ( $self->archive->contains_file($complete_file) ) {
        my $complete_json = $self->archive->get_content($complete_file);
        ##TODO Add in some error checking
        my $complete = decode_json($complete_json);
        return $complete;
    }
    else {
        return {};
    }

}

sub count_successful_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    return $self->search_complete( $jobname, 1 );
}

sub count_failed_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    return $self->search_complete( $jobname, 0 );
}

=head3 search_complete

See which jobs completed successfully

=cut

sub search_complete {
    my $self    = shift;
    my $jobname = shift;
    my $success = shift;

    my $basename = $self->data_tar->basename('.tar.gz');
    my $complete_file =
      File::Spec->catdir( $basename, $jobname, 'complete.json' );

    if ( $self->archive->contains_file($complete_file) ) {
        my $complete_json = $self->archive->get_content($complete_file);
        my $complete;
        try {
            $complete = decode_json($complete_json);
        }
        catch {
            $complete = {};
        };
        ##TODO Add in some error checking
        return $self->look_for_exit_code( $complete, $success );
    }
    else {
        return 0;
    }
}

sub look_for_exit_code {
    my $self     = shift;
    my $complete = shift;
    my $success  = shift;

    my $task_count = 0;
    foreach my $task ( keys %{$complete} ) {
        my $task_data = $complete->{$task};

        if ( $success && $task_data->{exit_code} == 0 ) {
            $task_count++;
        }
        elsif ( !$success && $task_data->{exit_code} != 0 ) {
            $task_count++;
        }
    }

    return $task_count;
}

1;
