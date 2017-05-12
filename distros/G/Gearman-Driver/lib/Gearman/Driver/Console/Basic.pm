package Gearman::Driver::Console::Basic;

use Moose::Role;
use DateTime;
use Time::HiRes;

=head1 NAME

Gearman::Driver::Console::Basic - Provides basic console commands

=head1 DESCRIPTION

This implements the basic management console commands like C<status>,
C<quit>, C<shutdown>, ...

=head1 COMMANDS

=head2 status

Parameters: C<none>

    status
    GDExamples::Convert::convert_to_jpeg  0  5  0  2010-01-29T20:37:17  1970-01-01T00:00:00
    GDExamples::Convert::convert_to_gif   0  5  0  2010-01-29T20:37:12  2010-01-29T20:37:12   some error
    .

Columns are separated by at least two spaces in this order:

=over 4

=item * job_name

=item * min_processes

=item * max_processes

=item * current_processes

=item * last_run

=item * last_error

=item * last_error_message

=back

=cut

sub status {
    my ($self) = @_;

    # get maximum lengths
    my @max = ( 0, 1, 1, 1, 1, 1, 1 );
    foreach my $job ( $self->driver->get_jobs ) {
        my $lasterror_msg = $job->lasterror_msg;
        $max[0] = length $job->name            if $max[0] < length $job->name;
        $max[1] = length $job->min_processes   if $max[1] < length $job->min_processes;
        $max[2] = length $job->max_processes   if $max[2] < length $job->max_processes;
        $max[3] = length $job->count_processes if $max[3] < length $job->count_processes;
        $max[4] = length $job->lastrun         if $max[4] < length $job->lastrun;
        $max[5] = length $job->lasterror       if $max[5] < length $job->lasterror;
    }

    my @result = ();
    foreach my $job ( $self->driver->get_jobs ) {
        my $lasterror_msg = $job->lasterror_msg;
        chomp $lasterror_msg;
        push @result,
          sprintf(
            "%-$max[0]s  %$max[1]d  %$max[2]d  %$max[3]d  %$max[4]s  %$max[5]s  %s",
            $job->name, $job->min_processes, $job->max_processes, $job->count_processes,
            DateTime->from_epoch( epoch => $job->lastrun ),
            DateTime->from_epoch( epoch => $job->lasterror ),
            $lasterror_msg ? "ERROR: $lasterror_msg" : ""
          );
    }

    return @result;
}

=head2 set_min_processes

Parameters: C<job_name min_processes>

    set_min_processes asdf 5
    ERR invalid_job_name: asdf
    set_min_processes GDExamples::Convert::convert_to_jpeg ten
    ERR invalid_value: min_processes must be >= 0
    set_min_processes GDExamples::Convert::convert_to_jpeg 10
    ERR invalid_value: min_processes must be smaller than max_processes
    set_min_processes GDExamples::Convert::convert_to_jpeg 5
    OK
    .

=cut

sub set_min_processes {
    my ( $self, $job_name, $min_processes ) = @_;

    my $job = $self->get_job($job_name);

    if ( !defined($min_processes) || $min_processes !~ /^\d+$/ || $min_processes < 0 ) {
        die "ERR invalid_value: min_processes must be >= 0\n";
    }

    if ( $min_processes > $job->max_processes ) {
        die "ERR invalid_value: min_processes must be smaller than max_processes\n";
    }

    $job->min_processes($min_processes);

    return "OK";
}

=head2 set_max_processes

Parameters: C<job_name max_processes>

    set_max_processes asdf 5
    ERR invalid_job_name: asdf
    set_max_processes GDExamples::Convert::convert_to_jpeg ten
    ERR invalid_value: max_processes must be >= 0
    set_max_processes GDExamples::Convert::convert_to_jpeg 0
    ERR invalid_value: max_processes must be greater than min_processes
    set_max_processes GDExamples::Convert::convert_to_jpeg 6
    OK
    .

=cut

sub set_max_processes {
    my ( $self, $job_name, $max_processes ) = @_;

    my $job = $self->get_job($job_name);

    if ( !defined($max_processes) || $max_processes !~ /^\d+$/ || $max_processes < 0 ) {
        die "ERR invalid_value: max_processes must be >= 0\n";
    }

    if ( $max_processes < $job->min_processes ) {
        die "ERR invalid_value: max_processes must be greater than min_processes\n";
    }

    $job->max_processes($max_processes);

    return "OK";
}

=head2 set_processes

Parameters: C<job_name min_processes max_processes>

    set_processes asdf 1 1
    ERR invalid_job_name: asdf
    set_processes GDExamples::Convert::convert_to_jpeg ten ten
    ERR invalid_value: min_processes must be >= 0
    set_processes GDExamples::Convert::convert_to_jpeg 1 ten
    ERR invalid_value: max_processes must be >= 0
    set_processes GDExamples::Convert::convert_to_jpeg 5 1
    ERR invalid_value: max_processes must be greater than min_processes
    set_processes GDExamples::Convert::convert_to_jpeg 1 5
    OK
    .

=cut

sub set_processes {
    my ( $self, $job_name, $min_processes, $max_processes ) = @_;

    my $job = $self->get_job($job_name);

    if ( !defined($min_processes) || $min_processes !~ /^\d+$/ || $min_processes < 0 ) {
        die "ERR invalid_value: min_processes must be >= 0\n";
    }

    if ( !defined($max_processes) || $max_processes !~ /^\d+$/ || $max_processes < 0 ) {
        die "ERR invalid_value: max_processes must be >= 0\n";
    }

    if ( $max_processes < $min_processes ) {
        die "ERR invalid_value: max_processes must be greater than min_processes\n";
    }

    $job->min_processes($min_processes);
    $job->max_processes($max_processes);

    return "OK";
}

=head2 show

Parameters: C<job_name>

    show GDExamples::Convert::convert_to_jpeg
    GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    3662
    3664
    3663
    .
    show GDExamples::Convert::convert_to_gif
    GDExamples::Convert::convert_to_gif  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    3665
    .

=cut

sub show {
    my ( $self, $job_name ) = @_;

    my $job = $self->get_job($job_name);

    my @result = ();

    my $lasterror_msg = $job->lasterror_msg;
    chomp $lasterror_msg;

    push @result,
      sprintf(
        "%s  %d  %d  %d  %s  %s  %s",
        $job->name, $job->min_processes, $job->max_processes, $job->count_processes,
        DateTime->from_epoch( epoch => $job->lastrun ),
        DateTime->from_epoch( epoch => $job->lasterror ),
        $lasterror_msg ? "ERROR: $lasterror_msg" : ""
      );

    push @result, $job->get_pids;

    return @result;
}

=head2 kill

Parameters: C<pid> [<pid> <pid> ...]

    kill 1
    ERR invalid_value: the given PID(s) do not belong to us
    kill 3662
    OK
    .

=cut

sub kill {
    my ( $self, @pids ) = @_;

    my @valid_pids = ();
    foreach my $job ( $self->driver->get_jobs ) {
        my @job_pids = $job->get_pids;
        foreach my $pid (@pids) {
            if ( grep $_ eq $pid, @job_pids ) {
                push @valid_pids, $pid;
            }
        }
    }

    die "ERR invalid_value: the given PID(s) do not belong to us\n" unless @valid_pids;

    CORE::kill 15, @valid_pids;

    return "OK";
}

=head2 killall

Kills all childs/pids of given job.

Parameters: C<job_name> [<job_name> <job_name> ...]

    killall GDExamples::Convert::convert_to_jpeg
    OK
    .

It also accepts C<*> as parameter to kill all jobs, so be careful
with that!

=cut

sub killall {
    my ( $self, @job_names ) = @_;

    die "ERR invalid_value: no job_names given\n" unless scalar(@job_names);

    my $kill = sub {
        my ($job) = @_;
        my @pids = $job->get_pids;
        CORE::kill 15, @pids;
        Time::HiRes::usleep(50);    # prevent POE from freaking out
    };

    if ( defined $job_names[0] && $job_names[0] eq '*' && scalar(@job_names) == 1 ) {
        foreach my $job ( $self->driver->get_jobs ) {
            $kill->($job);
        }
    }

    else {
        foreach my $job_name (@job_names) {
            my $job = $self->get_job($job_name);
            $kill->($job);
        }
    }

    return "OK";
}

=head2 quit

Parameters: C<none>

Closes your connection gracefully.

=head2 shutdown

Parameters: C<none>

Shuts L<Gearman::Driver> down.

=cut

sub shutdown {
    my ($self) = @_;
    $self->driver->shutdown;
}

=head1 AUTHOR

See L<Gearman::Driver>.

=head1 COPYRIGHT AND LICENSE

See L<Gearman::Driver>.

=head1 SEE ALSO

=over 4

=item * L<Gearman::Driver>

=item * L<Gearman::Driver::Adaptor>

=item * L<Gearman::Driver::Console>

=item * L<Gearman::Driver::Console::Client>

=item * L<Gearman::Driver::Job>

=item * L<Gearman::Driver::Job::Method>

=item * L<Gearman::Driver::Loader>

=item * L<Gearman::Driver::Observer>

=item * L<Gearman::Driver::Worker>

=back

=cut

no Moose::Role;

1;
