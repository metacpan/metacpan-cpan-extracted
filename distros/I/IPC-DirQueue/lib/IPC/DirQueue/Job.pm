=head1 NAME

IPC::DirQueue::Job - an IPC::DirQueue task

=head1 SYNOPSIS

    my $dq = IPC::DirQueue->new({ dir => "/path/to/queue" });
    my $job = $dq->pickup_queued_job();

    open(IN, "<".$job->get_data_path());
    my $str = <IN>;
    # ...
    close IN;
    $job->finish();
    
    # or...
    
    my $data = $job->get_data();
    $job->finish();

=head1 DESCRIPTION

A job object returned by C<IPC::DirQueue>.   This class provides various
methods to access job information, and report job progress and completion.

=head1 DATA

Any submitted metadata can be accessed through the C<$job-E<gt>{metadata}>
hash reference.  For example:

    print "email: ", $job->{metadata}->{submitter_email}, "\n";

Otherwise, you can access the queued data file using C<get_data_path()>,
or directly as a string using C<get_data()>.

=head1 METHODS

=over 4

=cut

package IPC::DirQueue::Job;
use strict;
use bytes;

our @ISA = ();

###########################################################################

sub new {
  my $class = shift;
  my $dqmaster = shift;
  my $opts = shift;
  $class = ref($class) || $class;

  my $self = $opts;
  $self->{dqmaster} = $dqmaster;
  $self->{metadata} = { };

  bless ($self, $class);
  $self;
}

###########################################################################

=item $data = $job->get_data();

Return the job's data. The return value will be a string, the data that was
originally enqueued for this job.

=cut

sub get_data {
  my ($self) = @_;
  my $data;
  open IN, $self->{QDFN} or die $!;
  while (<IN>) {
      $data .= $_;
  }
  close IN;
  return $data;
}

=item $path = $job->get_data_path();

Return the full path to the task's data file.  This can be opened and read
safely while the job is active.

=cut

sub get_data_path {
  my ($self) = @_;
  return $self->{QDFN};
}

=item $nbytes = $job->get_data_size_bytes();

Retrieve the size of the data without performing a C<stat> operation.

=cut

sub get_data_size_bytes {
  my ($self) = @_;
  return $self->{QDSB};
}

=item $secs = $job->get_time_submitted_secs();

Get the seconds-since-epoch (in other words, the C<time_t>) on the
submitting host when this task was submitted.

=cut

sub get_time_submitted_secs {
  my ($self) = @_;
  return $self->{QSTT};
}

=item $usecs = $job->get_time_submitted_usecs();

Get the microseconds within that second, as measured by C<gettimeofday> on
the submitting host, when this task was submitted.

=cut

sub get_time_submitted_usecs {
  my ($self) = @_;
  return $self->{QSTM};
}

=item $hostname = $job->get_hostname_submitted();

Get the name of the submitting host where this task originated.

=cut

sub get_hostname_submitted {
  my ($self) = @_;
  return $self->{QSHN};
}

=item $job->touch_active_lock();

Update the lockfile to reflect that this task is still being processed. If a
task has been active, but the lockfile has not been touched for more than 600
seconds, another C<IPC::DirQueue> queue processor may take it over.

=cut

sub touch_active_lock {
  my ($self) = @_;
  open (TOUCH, ">>".$self->{pathactive});
  close TOUCH;
}

###########################################################################

=item $job->finish();

Report that the job has been completed, and may be removed from the queue.

=cut

sub finish {
  my ($self) = @_;
  $self->{dqmaster}->finish_job ($self, 1);
  delete $self->{dqmaster};     # clean up circ ref
  return 1;
}

=item $job->return_to_queue();

Return the job to the queue, unfinished.  Another task processor
may then pick it up.

=cut

sub return_to_queue {
  my ($self) = @_;
  $self->{dqmaster}->finish_job ($self, 0);
  delete $self->{dqmaster};     # clean up circ ref
  return 1;
}

###########################################################################

1;

=back
