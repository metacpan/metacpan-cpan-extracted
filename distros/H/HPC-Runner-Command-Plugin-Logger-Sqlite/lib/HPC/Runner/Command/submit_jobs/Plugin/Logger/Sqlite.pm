package HPC::Runner::Command::submit_jobs::Plugin::Logger::Sqlite;

use Moose::Role;
use JSON::XS;
use Data::Dumper;
use DateTime;

with 'HPC::Runner::Command::Plugin::Logger::Sqlite';

=head1 HPC::Runner::Command::submit_jobs::Plugin::Logger::Sqlite;

=cut

=head2 Attributes

=cut

=head2 Subroutines

=cut

around 'execute' => sub {
    my $orig = shift;
    my $self = shift;

    $self->deploy_schema;
    my $dt1        = DateTime->now( time_zone => 'local' );
    my $ymd        = $dt1->ymd();
    my $hms        = $dt1->hms();
    my $start_time = "$ymd $hms";

    my $res = $self->schema->resultset('Submission')
      ->create( { total_processes => 0, total_batches => 0, submission_time => $start_time } );
    my $id = $res->submission_pi;

    $self->app_log->info("Saving to sqlite db as submission id : $id");
    $self->submission_id($id);

    $self->$orig(@_);

    my $obj = {};
    $obj->{batches}  = $self->job_stats->batches;
    $obj->{jobnames} = $self->job_stats->jobnames;
    my $json_text = encode_json $obj;

    $res->update(
        {
            submission_meta => $json_text,
            total_processes => $self->job_stats->total_processes,
            total_batches   => $self->job_stats->total_batches,
        }
    );

    $res->update({ project => $self->project }) if $self->project;
};

around 'create_plugin_str' => sub {

    my $orig = shift;
    my $self = shift;

    $self->job_plugins( [] ) unless $self->job_plugins;
    $self->job_plugins_opts( {} ) unless $self->job_plugins_opts;

    push( @{ $self->job_plugins }, 'Logger::Sqlite' );
    $self->job_plugins_opts->{submission_id} = $self->submission_id;
    my $val = $self->$orig(@_);

    return $val;
};

1;
