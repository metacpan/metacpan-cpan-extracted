package HPC::Runner::Command::stats;

use MooseX::App::Command;
use Log::Log4perl qw(:easy);
use JSON;
use Text::ASCIITable;

with 'HPC::Runner::Command::Plugin::Logger::Sqlite';

command_short_description 'Get an overview of your submission.';
command_long_description 'Query the sqlite database for a submission overview.';

#TODO project and jobname are already defined as options in execute_array

option 'project' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Query by project',
    required      => 0,
    predicate     => 'has_project',
);

option 'jobname' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Query by jobname',
    required      => 0,
    predicate     => 'has_jobname',
);

option 'summary' => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
'Summary view of your jobs - Number of running, completed, failed, successful.',
    required => 0,
    default  => 1,
);

option 'long' => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
      'Long view. More detailed report - Task tags, exit codes, duration, etc.',
    required => 0,
    default  => 0,
    trigger  => sub {
        my $self = shift;
        $self->summary(0) if $self->long;
    },
    cmd_aliases => ['l'],
);

has 'task_data' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    clearer => 'clear_task_data',
);

sub execute {
    my $self = shift;

    if ( $self->summary ) {
        $self->summary_view;
    }
    else {
        $self->long_view;
    }
}

sub long_view {
    my $self = shift;

    my $results_pass = $self->build_query;

    while ( my $res = $results_pass->next ) {

        my $table = $self->build_table($res);
        $table->setCols(
            [
                'JobName',
                'Task Tags',
                'Start Time',
                'End Time',
                'Duration',
                'Exit Code'
            ]
        );

        map { $self->iter_jobs_long($_) } @{ $res->{jobs} };
        while ( my ( $k, $v ) = each %{ $self->task_data } ) {
            foreach my $h ( @{$v} ) {
                $table->addRow(
                    [
                        $k,             $h->{task_tags}, $h->{start_time},
                        $h->{end_time}, $h->{duration},  $h->{exit_code}
                    ]
                );
            }
            $table->addRowLine;
        }
        $self->task_data( {} );
        print $table;
        print "\n";
    }
}

sub iter_jobs_long {
    my $self = shift;
    my $job  = shift;

    if ( !exists $self->task_data->{ $job->{job_name} } ) {
        $self->task_data->{ $job->{job_name} } = [];
    }

    map { $self->iter_tasks_long( $job->{job_name}, $_ ) } @{ $job->{tasks} };
}

sub iter_tasks_long {
    my $self    = shift;
    my $jobname = shift;
    my $task    = shift;

    my $exit_code = $task->{exit_code};
    $exit_code = "" if !defined $exit_code;

    push(
        @{ $self->task_data->{$jobname} },
        {
            'start_time' => $task->{start_time} || "",
            'end_time'   => $task->{exit_time}  || "",
            'task_tags'  => $task->{task_tags}  || "",
            'duration'   => $task->{duration}   || "",
            'exit_code'  => $exit_code,
        }
    );
}

sub summary_view {
    my $self = shift;

    my $results_pass = $self->build_query;

    while ( my $res = $results_pass->next ) {

        my $table = $self->build_table($res);
        $table->setCols(
            [ 'JobName', 'Complete', 'Running', 'Success', 'Fail', 'Total' ] );

        map { $self->iter_jobs_summary($_) } @{ $res->{jobs} };

        while ( my ( $k, $v ) = each %{ $self->task_data } ) {
            $table->addRow(
                [
                    $k,
                    $self->task_data->{$k}->{complete},
                    $self->task_data->{$k}->{running},
                    $self->task_data->{$k}->{success},
                    $self->task_data->{$k}->{fail},
                    $self->task_data->{$k}->{total},
                ]
            );
        }

        $self->task_data( {} );
        print $table;
        print "\n";
    }
}

sub build_table {
    my $self = shift;
    my $res  = shift;

    my $header = "Time: " . $res->{submission_time};
    $header .= " SubmissionID: " . $res->{submission_pi};
    $header .= " Project: " . $res->{project} if defined $res->{project};
    my $table = Text::ASCIITable->new( { headingText => $header } );

    return $table;
}

sub build_query {
    my $self = shift;

    # $self->schema->storage->debug(1);
    my $where = {};
    if ( $self->has_project ) {
        $where->{project} = $self->project;
    }
    if ( $self->has_jobname ) {
        $where->{'jobs.job_name'} = $self->jobname;
    }

    my $results_pass = $self->schema->resultset('Submission')->search(
        $where,
        {
            join     => { jobs    => 'tasks' },
            prefetch => { jobs    => 'tasks' },
            group_by => [ 'project', ],
            order_by => { '-desc' => 'submission_pi', },
        }
    );

    $results_pass->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return $results_pass;
}

sub iter_jobs_summary {
    my $self = shift;
    my $job  = shift;

    if ( !exists $self->task_data->{ $job->{job_name} } ) {
        my $job_meta    = decode_json( $job->{jobs_meta} );
        my $total_tasks = $job_meta->{job_tasks};
        $self->task_data->{ $job->{job_name} } = {
            complete => 0,
            success  => 0,
            fail     => 0,
            total    => $total_tasks,
            running  => 0
        };
    }

    map { $self->iter_tasks_summary( $job->{job_name}, $_ ) }
      @{ $job->{tasks} };

}

sub iter_tasks_summary {
    my $self     = shift;
    my $job_name = shift;
    my $task     = shift;

    if ( $self->task_is_running($task) ) {
        $self->task_data->{$job_name}->{running} += 1;
    }
    else {
        $self->task_data->{$job_name}->{complete} += 1;
        if ( $self->task_is_success($task) ) {
            $self->task_data->{$job_name}->{success} += 1;
        }
        else {
            $self->task_data->{$job_name}->{fail} += 1;
        }
    }
}

sub task_is_running {
    my $self = shift;
    my $task = shift;

    if ( !defined $task->{exit_code} ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub task_is_success {
    my $self = shift;
    my $task = shift;

    if ( $task->{exit_code} == 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
