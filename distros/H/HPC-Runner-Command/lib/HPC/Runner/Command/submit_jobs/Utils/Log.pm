package HPC::Runner::Command::submit_jobs::Utils::Log;

use Moose::Role;
use namespace::autoclean;
with 'HPC::Runner::Command::Utils::Log';

use Text::ASCIITable;
use File::Spec;
use File::Slurp;
use Log::Log4perl qw(:easy);

sub print_table_schedule_info {
    my $self = shift;
    my $t    = Text::ASCIITable->new();

    my @rows = ();
    foreach my $job ( $self->all_schedules ) {
        my $row = [];
        my $ref = $self->graph_job_deps->{$job};

        push( @$row, $job );

        my $depstring = join( ", ", @{$ref} );
        push( @$row, $depstring );

        my $count_cmd = $self->jobs->{$job}->cmd_counter;
        push( @$row, $count_cmd );

        my $mem = $self->jobs->{$job}->mem;
        push( @$row, $mem );

        my $cpus = $self->jobs->{$job}->cpus_per_task;
        push( @$row, $cpus );

        $self->assign_num_max_array($job);
        my $array_count = $self->jobs->{$job}->{num_job_arrays};

        push( @$row, $array_count );

        push( @rows, $row );
    }

    $t->setCols(
        [ "JobName", "Deps", "Task Count", "Mem", "Cpu", "Num Arrays" ] );
    map { $t->addRow($_) } @rows;
    $self->app_log->info(
        "Here is your tabular dependency list in submission order");
    $self->app_log->info( "\n\n" . $t );
}

=head3 summarize_jobs

=cut

#TODO Update this!

sub summarize_jobs {
    my $self = shift;

    my $t    = Text::ASCIITable->new();
    my $x    = 0;
    my @rows = ();

    #cmd_start is zero indexes
    #But batches are 1 indexes
    #WHY DO I DO THIS TO MYSELF
    foreach my $job ( $self->all_schedules ) {

        $DB::single = 2;
        my $cmd_start         = $self->jobs->{$job}->{cmd_start};
        my $commands_per_node = $self->jobs->{$job}->commands_per_node;

        for ( my $x = 0 ; $x < $self->jobs->{$job}->{num_job_arrays} ; $x++ ) {
            my $row = [];

            next unless $self->jobs->{$job}->batch_indexes->[$x];

            my $batch_indexes = $self->jobs->{$job}->batch_indexes->[$x];

            my $batch_index_start = $batch_indexes->{batch_index_start} - 1;
            my $batch_index_end   = $batch_indexes->{batch_index_end} - 1;

            my $start_array =
              $cmd_start +
              $self->jobs->{$job}->batches->[$batch_index_start]->{cmd_start};

            my $end_array =
              $cmd_start +
              $self->jobs->{$job}->batches->[$batch_index_end]->{cmd_start} +
              $self->jobs->{$job}->batches->[$batch_index_end]->{cmd_count} - 1;

            my $len = $end_array - $start_array + 1;

            push( @{$row}, $job );
            push( @{$row}, $self->jobs->{$job}->scheduler_ids->[$x] || '0' );
            push( @{$row}, "$start_array-$end_array" );
            push( @{$row}, $len );
            push( @rows,   $row );
        }
    }

    $t->setCols(
        [ "Job Name", "Scheduler ID", "Task Indices", "Total Tasks" ] );
    map { $t->addRow($_) } @rows;
    $self->app_log->info("Job Summary");
    $self->app_log->info( "\n" . $t );

    return \@rows;
}

sub write_job_project_table {
    my $self = shift;

    my $job_file = File::Spec->catdir( $self->logdir, 'project_job_table.md' );
    write_file( $job_file, '| Job | Status | Notes |' . "\n" );
    foreach my $job ( $self->all_schedules ) {
        write_file( $job_file, { append => 1 }, '| ' . $job . ' | | |' . "\n" );
    }
    $self->app_log->info( 'Project table per job: ' . $job_file );
}

sub write_task_project_table {
    my $self = shift;

    my $task_file =
      File::Spec->catdir( $self->logdir, 'project_task_table.md' );
    write_file( $task_file, '| Job | TaskID | Status | Notes |' . "\n" );
    foreach my $job ( $self->all_schedules ) {
        my $cmd_start = $self->jobs->{$job}->{cmd_start} + 1;
        my $cmd_end   = $self->jobs->{$job}->cmd_counter + $cmd_start - 1;
        for ( my $x = $cmd_start ; $x <= $cmd_end ; $x++ ) {
            write_file(
                $task_file,
                { append => 1 },
                '| ' . $job . ' | ' . $x . ' | | |' . "\n"
            );
        }
    }

    $self->app_log->info( 'Project table per task: ' . $task_file );
}

1;
