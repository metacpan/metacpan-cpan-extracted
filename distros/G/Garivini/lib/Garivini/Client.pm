package Garivini::Client;

=head1 NAME

Garivini::Client - Thin client for submitting jobs via Garivini

=head1 SYNOPSIS

    use Garivini::Client;

    # Client
    my $cli = Garivini::Client->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysql:job:host=127.0.0.1', user => 'job',
            pass => 'job' } });
    $cli->insert_job(funcname => 'hello', arg => 'world');

    # Worker
    use Gearman::Worker;
    use JSON;

    my $cli = Garivini::Client->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysql:job:host=127.0.0.1', user => 'job',
            pass => 'job' } });
    my $worker = Gearman::Worker->new;
    $worker->job_servers('127.0.0.1');
    $worker->register_function('hello' => \&hello);
    $worker->work;

    sub hello {
        my $job = decode_json(${$_[0]->argref});
        print "Hello ", $job->{arg}, "\n";
        $cli->complete_job($job);
    }

=head1 DESCRIPTION

Client used for issuing and removing jobs directly from a Garivini database.
Used by client code directly, or indirectly via the supplied workers.

=head1 METHODS

=over

=item new

    $cli = Garivini::Client->new( %OPTIONS );

Creates a new client object. The only arguments it takes are for initializing
a L<Garivini::DB> object.

=cut

use strict;
use warnings;
use fields ('dbd',
            );

use Garivini::DB;

# Extremely simple shim client:
# Takes list of databases
# Takes serialized argument (or optional serialization command?)

sub new {
    my Garivini::Client $self = shift;
    $self = fields::new($self) unless ref $self;
    my %args = @_;

    $self->{dbd} = Garivini::DB->new(%args);

    return $self;
}

=item insert_job

Takes a hash of arguments and directly tosses a job into the a DB.

=over

=item job

Hash describing a job

=over

=item funcname

worker function name to execute the job

=item run_after

if given, offset from now for when to run job

=item unique

only run one job with this id (per database defined!)

=item coalesce

unimplemented. for running similar jobs together

=item arg

serialized blob payload.

=back

=item flag

Optional; if set to 'shim', indicates that the job will be completed by a
worker directly using L<Garivini::Client>. If set to 'controller', the system
will expect an L<Garivini::Controller> worker to manage completion of the job.

=back

=cut

# TODO: Allow run_after to be more flexible
sub insert_job {
    my $self = shift;
    my %args = @_;
    $args{unique}    = undef unless $args{unique};
    $args{coalesce}  = undef unless $args{coalesce};
    $args{flag}      = undef unless $args{flag};

    $args{run_after} = 'UNIX_TIMESTAMP() + ' . ($args{run_after} ?
        int($args{run_after}) : '0');
    my ($ret, $dbh, $dbid) = $self->{dbd}->do(undef,
        "INSERT IGNORE INTO job (funcname, run_after, uniqkey, coalesce, arg, flag) "
        . "VALUES (?, ?, ?, ?, ?, ?)", undef,
        @args{'funcname', 'run_after', 'unique', 'coalesce', 'arg', 'flag'});
    return ($dbh->last_insert_id(undef, undef, undef, undef), $dbid);
}

=item insert_jobs

    $cli->insert_jobs($jobs, $in, $flag);

Takes an array of arrays as jobs.

Jobs are defined as an array of arrays, in order: ['funcname', 'uniqkey',
'coalesce', 'arg']

Optionally $in is used for delaying job execution. All jobs will use the same
value.

Optionally $flag is defined, as noted in "insert_jobs" above. All jobs will
use the same value.

There is presently no way to do low latency submission for mass jobs, however
they may still be executed via controller workers afterwards.

=cut

sub insert_jobs {
    my ($self, $jobs, $in, $flag) = @_;
    my $run_after = 'UNIX_TIMESTAMP() + ' . ($in ? int($in) : 0);
    $flag      = undef unless $flag;

    my $sql = 'INSERT IGNORE INTO job (funcname, uniqkey, coalesce,'.
        "arg, flag, $run_after)".
        join(', ', ('?, ?, ?, ?, ?') x scalar @$jobs);
    my ($ret, $dbh, $dbid) =
        $self->{dbd}->do(undef, $sql, map { @$_, $flag, $run_after } @$jobs);
}

# Further potential admin commands:
sub list_jobs {

}

# Pull jobs scheduled for ENDOFTIME
sub failed_jobs {

}

=item complete_job

    $cli->complete_job($job_handle);

Takes a job handle and removes the job from the database. Job handles are
received by Gearman workers, with the dbid and jobid's filled in.

=cut

sub complete_job {
    my $self = shift;
    my $job  = shift;

    # Job should have the dbid buried in the reference.
    my $dbid = $job->{dbid}
        or die "Malformed job missing dbid argument";
    my $jobid = $job->{jobid}
        or die "Malformed job missing id argument";
    $self->{dbd}->do($dbid, "DELETE FROM job WHERE jobid=?", undef, $jobid);
}

=item reschedule_job

    $cli->reschedule_job($job_handle, $when);

Reschedules a job for some time in the future, in case of temporary failure.
You should call "failed_job" instead of this in most cases.

=over

=item when

When to reschedule the job.

"never" sets the job to execute in 2038, long after civilization has been
reclaimed. This leaves the job in the database for inspection, but will
avoid retrying it.

"+360" would retry the job again in six minutes from now.

"1313572984" would retry the job at a specific unix timestamp.

=back

=cut

# Bump the run_after in some specific way (relative, absolute, etc)
sub reschedule_job {
    my ($self, $job, $when) = @_;

    my $dbid = $job->{dbid}
        or die "Malformed job missing dbid argument";
    my $jobid = $job->{jobid}
        or die "Malformed job missing id argument";

    if ($when eq 'never') {
        $when = 2147483647; # "max value"
    } elsif ($when =~ m/^\+(\d+)$/) {
        $when = 'UNIX_TIMESTAMP() + ' . $1;
    } elsif ($when =~ m/^(\d+)$/) {
        $when = $1;
    } else {
        die "Invalid timestamp: " . $when;
    }

    my $failcount = $job->{failcount} || 0;
    $self->{dbd}->do($dbid, "UPDATE job SET run_after = $when, failcount = ? WHERE jobid=?",
        undef, $failcount, $jobid);
}

=item failed_job

    $cli->failed_job($job_handle);

Reschedules a job to retry in the future in case of a temporary failure.
Applies a generic backoff algorithm based on the number of times the job has
failed. Starts at two minutes and caps at one day.

=cut

sub failed_job {
    my ($self, $job) = @_;
    my $failcount = ($job->{failcount} || 0) + 1;
    my $delay = (2 ** $failcount) * 60;
    $delay = 86400 if $delay > 86400;

    $self->reschedule_job($job, "+$delay");
}

=back

=cut

1;
