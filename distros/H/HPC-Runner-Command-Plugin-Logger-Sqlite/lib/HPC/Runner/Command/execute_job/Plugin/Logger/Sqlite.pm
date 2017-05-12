package HPC::Runner::Command::execute_job::Plugin::Logger::Sqlite;

use Moose::Role;
use Data::Dumper;
use DateTime;
use JSON;

with 'HPC::Runner::Command::Plugin::Logger::Sqlite';

=head1 HPC::Runner::Command::execute_job::Plugin::Logger::Sqlite;

=cut

=head2 Attributes

=cut

=head3 job_id

This is the ID for the hpcrunner.pl execute_job

=cut

has 'job_id' => (
    is        => 'rw',
    isa       => 'Str|Int',
    lazy      => 1,
    default   => '',
    predicate => 'has_job_id',
    clearer   => 'clear_job_id'
);

=head2 Subroutines

=cut

=head3 after log_table

Log the table data to the sqlite DB

Each start, stop time for the whole batch gets logged

Each start, stop time for each task gets logged

=cut

#$sql =<<EOF;
#CREATE TABLE IF NOT EXISTS jobs (
#jobs_pi INTEGER PRIMARY KEY NOT NULL,
#submission_id integer NOT NULL,
#start_time varchar(20) NOT NULL,
#exit_time varchar(20) NOT NULL,
#jobs_meta text,

##TODO Add Moose object with starttime, endtime, duration

around 'run_mce' => sub {
    my $orig = shift;
    my $self = shift;

    $self->deploy_schema;

    my $dt1        = DateTime->now( time_zone => 'local' );
    my $ymd        = $dt1->ymd();
    my $hms        = $dt1->hms();
    my $start_time = "$ymd $hms";

    my $job_meta = {};

    if ( $self->metastr ) {
        $job_meta = decode_json( $self->metastr );
    }

    if ( !exists $job_meta->{jobname} ) {
        $job_meta->{jobname} = 'undefined';
    }

    my $res = $self->schema->resultset('Job')->create(
        {
            submission_fk    => $self->submission_id,
            start_time       => $start_time,
            exit_time        => $start_time,
            job_scheduler_id => $self->job_scheduler_id,
            jobs_meta        => $self->metastr,
            job_name         => $job_meta->{jobname}
        }
    );

    my $id = $res->job_pi;
    $self->job_id($id);

    $self->$orig(@_);

    my $dt2 = DateTime->now( time_zone => 'local' );
    $ymd = $dt2->ymd();
    $hms = $dt2->hms();
    my $end_time = "$ymd $hms";
    my $duration = $dt2 - $dt1;
    my $format   = DateTime::Format::Duration->new( pattern =>
          '%e days, %H hours, %M minutes, %S seconds' );

    $duration = $format->format_duration($duration);

    $res->update( { exit_time => $end_time, duration => $duration } );
};

around 'start_command_log' => sub {
    my $orig   = shift;
    my $self   = shift;
    my $cmdpid = shift;

    my $res = $self->schema->resultset('Task')->create(
        {
            job_fk     => $self->job_id,
            pid        => $cmdpid,
            start_time => $self->table_data->{start_time},
        }
    );

    $self->$orig($cmdpid);

};

around 'log_table' => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    my $tags = "";
    if ( exists $self->table_data->{task_tags} ) {
        my $task_tags = $self->table_data->{task_tags};
        if ($task_tags) {
            $tags = $task_tags;
        }
    }

    my $started_task = $self->schema->resultset('Task')->find(
        {
            job_fk     => $self->job_id,
            pid        => $self->table_data->{cmdpid},
            start_time => $self->table_data->{start_time},
        }
    );

    $started_task->update(
        {
            exit_time => $self->table_data->{exit_time},
            duration  => $self->table_data->{duration},
            exit_code => $self->table_data->{exitcode},
            task_tags => $tags,
        }
    );
};

1;
