=head1 NAME

Event::IO::Record - buffered asynchronous I/O, timeouts

=head1 METHODS

=cut
package Event::IO::Record;

use strict;
our $VERSION = '0.01';

use Event;
use Fcntl;
use Errno qw(:POSIX);

use constant READ_SIZE          => 1024;  # bytes per read


=head2 new ( named parameters... )

=over 4

=item init

If true (default), generate an init_event immediately (otherwise you must
call init_event later).

=item timeout

Default timeout; see Timeout method.

=item irs, ors

Input/output record separators; default irs => "\r?[\0\n]", ors => "\n".

=item handle

Handle for connection, should be an IO::Socket object (::INET or ::UNIX).

=back

=cut
sub new {
  my ($class,%param) = @_;
  my ($init,$timeout,$irs,$ors,$handle) =
   delete @param{qw[init timeout irs ors handle]};
  die 'unknown parameter(s): '.(join ', ',keys %param) if keys %param;

  # defaults
  $init      = 1 if not defined $init;
  $timeout ||= 0;
  $irs     ||= "\r?[\0\n]";
  $ors     ||= "\n";

  # create object
  my $self = bless { handle => $handle, in => '', out => '',
   timeout => $timeout, irs => $irs, ors => $ors }, ref $class || $class;
  $self->init_event() if $init;

  return $self
}


=head2 timeout ( time )

Time is the time in seconds; 0 disables; undef reinitializes the current value.
We generates a timeout_event when the timer expires.

=cut
sub timeout {
  my ($self,$time) = @_;
  $time = $self->{timeout} unless defined $time;

  if($self->{timer}) {
    $self->{timer}->cancel();
    delete $self->{timer};
  }

  $self->{timeout} = $time;

  $self->{timer} =
   Event->timer(after => $time, cb => [$self,'timeout_event'])
   if $time and $self->{init};
}


=head2 init_event

Initialization event, called before anything else happens.

=cut
sub init_event {
  my $self = shift;
  warn "@{[ref $self]} initialized twice!" if $self->{init}++;

  # set non-blocking
  if(my $flags = $self->{handle}->fcntl(F_GETFL,pack '') >= 0) {
    $self->{handle}->fcntl(F_SETFL,$flags | O_NONBLOCK);
  }

  # set up read/write event watchers and inactivity timeout
  $self->{read} =
   Event->io(fd => $self->{handle}, poll => 'r', cb => [$self,'read_event']);
  $self->{write} =
   Event->io(fd => $self->{handle}, poll => 'w', cb => [$self,'write_event'],
   repeat => 0, parked => 1);
  $self->timeout();
}


=head2 read_event

Data is available for reading.  We buffer it up and emit lines to derived
classes as C<line_event>s.

=cut
sub read_event {
  my $self = shift;
  $self->timer(0);

  # buffer up input until we can't read any more
  my ($data,$frag,$count) = ($self->{in},'',0);
  my $close;
  $self->{in} = '';

  do {{
    # undef means we have an error so log it and close
    unless(defined $self->{handle}->recv($frag,READ_SIZE)) {
      last if EAGAIN == $! or EWOULDBLOCK == $!;   # no data available
      next if EINTR == $!;                         # interrupted by signal

      # queue up the read error until we've processed what we've read
      warn "@{[ref $self]} socket read error: $!";
      $close = "read error: $!";
      last;
    }

    # assume if we got 0 bytes and no error that it's time to bail
    # if not, we get an infinite sequence of read_events....
    # don't bail until we've sent the lines that we have, however
    unless(length $frag) {
      $close = 'remote closed socket';
      last;
    }

    # otherwise append to the existing block and read until we run out of data
    $data .= $frag;
    $count .= length $frag;
  }} while length $frag == READ_SIZE;

  # send each line as an event
  my $irs = $self->{irs};
  while(length $data and $data =~ s/^(.*?)$irs//s) {
    $self->line_event($1);
    $irs = $self->{irs};  # refresh in case line_event changes it
  }
  $self->{in} = $data;

  $self->timer(1);

  # if the socket was closed, we can now send the close event
  $self->close($close) if $close;
}


=head2 line_event ( line )

Override in derived class to process incoming data.

=cut
sub line_event {
}


=head2 write( data )

Buffered write.

=cut
sub write {
  my ($self,$data) = @_;
  $self->{out} .= $data.$self->{ors};
  $self->write_event();
}


=head2 write_event

Write event - handle buffered writes.

=cut
sub write_event {
  my $self = shift;
  my $data = $self->{out};

  # send as much as we can from the buffer
  while(length $data) {
    my $count = $self->{handle}->send($data);
    unless(defined $count) {
      if(EAGAIN == $! or EWOULDBLOCK == $!) {   # writing would block
        $self->{write}->start();
        last;
      }
      next if EINTR == $!;                      # interrupted by signal
      warn "@{[ref $self]} socket write error: $!";
      $self->{out} = $data;
      return $self->close('write error');
    }
    $data = substr($data,$count);
    $self->timer(1) if $count;  # reinitialize the inactivity timer
  }
  $self->{out} = $data;

  # send an event if we've written everything in the buffer
  $self->sent_event() if not length $data and $self->can('sent_event');
}


=head2 timer ( enable flag )

Disable or restart inactivity timer.

=cut
sub timer {
  my ($self,$enable) = @_;
  $enable ?  $self->{timer}->again() : $self->{timer}->stop()
   if $self->{timer};
}


=head2 timeout_event

Inactivity timeout event.

=cut
sub timeout_event {
  my $self = shift;
  $self->error('closing inactive connection after '.
   "@{[$self->{timeout}]} s");
  $self->close('timed out');
}


=head2 close

Remove event handlers, this will close the connection (as long as no other
outstanding references exist).

=cut
sub close {
  my $self = shift;
  if($self->{read}) {
    for my $ev(qw[read write timer]) {
      (delete $self->{$ev})->cancel() if $self->{$ev};
    }
  }
  (delete $self->{handle})->close() if $self->{handle};  # close the socket
}


=head2 closed

Return true iff socket is closed.

=cut
sub closed {
  my $self = shift;
  return not $self->{read}
}


=head2 error( message )

Log error, subclasses may do more.

=cut
sub error {
  my ($self,$err) = @_;
  warn "@{[ref $self]} error: $err";
}


=head2 IRS( [ input record separator ] )

Get/set input record separator.

=cut
sub IRS {
  my $self = shift;
  $self->{irs} = shift if @_;
  $self->{irs}
}


=head2 ORS( [ output record separator ] )

Get/set output record separator.

=cut
sub ORS {
  my $self = shift;
  $self->{ors} = shift if @_;
  $self->{ors}
}


=head1 AUTHOR

David B. Robins E<lt>dbrobins@davidrobins.netE<gt>

=cut


1;
