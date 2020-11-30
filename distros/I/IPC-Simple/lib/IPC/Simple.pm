package IPC::Simple;
# ABSTRACT: simple, non-blocking IPC
$IPC::Simple::VERSION = '0.07';

use strict;
use warnings;

use Carp;
use AnyEvent qw();
use AnyEvent::Handle qw();
use IPC::Open3 qw(open3);
use POSIX qw(:sys_wait_h);
use Symbol qw(gensym);

use IPC::Simple::Channel qw();
use IPC::Simple::Group qw();
use IPC::Simple::Message;

use constant STATE_READY    => 0;
use constant STATE_RUNNING  => 1;
use constant STATE_STOPPING => 2;

BEGIN{
  use base 'Exporter';
  our @EXPORT_OK = qw(
    spawn
    process_group
  );
}

#-------------------------------------------------------------------------------
# Convenience constructor
#-------------------------------------------------------------------------------
sub spawn ($;%) {
  my ($cmd, @args) = @_;
  return IPC::Simple->new(cmd => $cmd, @args);
}

sub process_group {
  return IPC::Simple::Group->new(@_);
}

#-------------------------------------------------------------------------------
# Constructor
#-------------------------------------------------------------------------------
sub new {
  my ($class, %param) = @_;
  my $cmd     = ref $param{cmd} ? $param{cmd} : [ $param{cmd} ];
  my $eol     = defined $param{eol} ? $param{eol} : "\n";
  my $name    = $param{name} || "@$cmd";
  my $recv_cb = $param{recv_cb};
  my $term_cb = $param{term_cb};

  bless{
    name        => $name,
    cmd         => $cmd,
    eol         => $eol,
    recv_cb     => $recv_cb,
    term_cb     => $term_cb,
    run_state   => STATE_READY,
    pid         => undef,
    handle_in   => undef,
    handle_out  => undef,
    handle_err  => undef,
    exit_status => undef,
    exit_code   => undef,
    messages    => undef,
    kill_timer  => undef,
  }, $class;
}

#-------------------------------------------------------------------------------
# State accessor and predicates
#-------------------------------------------------------------------------------
sub run_state {
  my $self = shift;

  if (@_) {
    my $new_state = shift;
    $self->debug('run state changed to %d', $new_state);
    $self->{run_state} = $new_state;
  }

  return $self->{run_state};
}

sub is_ready    { $_[0]->run_state == STATE_READY }
sub is_running  { $_[0]->run_state == STATE_RUNNING }
sub is_stopping { $_[0]->run_state == STATE_STOPPING }

#-------------------------------------------------------------------------------
# Other accessors
#-------------------------------------------------------------------------------
sub name        { $_[0]->{name} }
sub pid         { $_[0]->{pid} }
sub exit_status { $_[0]->{exit_status} }
sub exit_code   { $_[0]->{exit_code} }

#-------------------------------------------------------------------------------
# Ensure the process is cleaned up when the object is garbage collected.
#-------------------------------------------------------------------------------
sub DESTROY {
  my $self = shift;

  # Localize globals to avoid affecting global state during shutdown
  local ($., $@, $!, $^E, $?);

  if ($self->{pid} && waitpid($self->{pid}, WNOHANG) == 0) {
    kill 'KILL', $self->{pid};
    waitpid $self->{pid}, 0;
  }
}

#-------------------------------------------------------------------------------
# Logs debug messages
#-------------------------------------------------------------------------------
sub debug {
  my $self = shift;

  if ($ENV{IPC_SIMPLE_DEBUG}) {
    my $msg = sprintf shift, @_;

    my ($pkg, $file, $line) = caller;
    my $pid = $self->{pid} || '(ready)';
    my $ts = time;

    warn "<$pkg:$line | $ts | pid:$pid> $msg\n";
  }
}

#-------------------------------------------------------------------------------
# Launch and helpers
#-------------------------------------------------------------------------------
sub launch {
  my $self = shift;

  if ($self->is_running) {
    croak 'already running';
  }

  if ($self->is_stopping) {
    croak 'process is terminating';
  }

  my $cmd = $self->{cmd};

  $self->debug('launching: %s', "@$cmd");

  my $pid = open3(my $in, my $out, my $err = gensym, @$cmd)
    or croak $!;

  $self->debug('process launched with pid %d', $pid);

  $self->run_state(STATE_RUNNING);

  $self->{exit_status} = undef;
  $self->{exit_code}   = undef;
  $self->{kill_timer}  = undef;
  $self->{pid}         = $pid;
  $self->{handle_err}  = $self->_build_input_handle($err, IPC_STDERR);
  $self->{handle_out}  = $self->_build_input_handle($out, IPC_STDOUT);
  $self->{handle_in}   = $self->_build_output_handle($in);
  $self->{messages}    = IPC::Simple::Channel->new;

  return 1;
}

sub _build_output_handle {
  my ($self, $fh) = @_;

  # set non-blocking
  AnyEvent::fh_unblock($fh);

  my $handle = AnyEvent::Handle->new(
    fh => $fh,
    on_error => sub{ $self->_on_error(IPC_STDIN, @_) },
  );

  return $handle;
}

sub _build_input_handle {
  my ($self, $fh, $type) = @_;

  # set non-blocking
  AnyEvent::fh_unblock($fh);

  my $handle = AnyEvent::Handle->new(
    fh       => $fh,
    on_eof   => sub{ $self->terminate },
    on_error => sub{ $self->_on_error($type, @_) },
    on_read  => sub{ $self->_on_read($type, @_) },
  );

  # push an initial read to prime the queue
  $self->_push_read($handle, $type);

  return $handle;
}

sub _on_error {
  my ($self, $type, $handle, $fatal, $msg) = @_;
  $self->_queue_message(IPC_ERROR, $msg);

  if ($fatal) {
    $self->terminate;
  }
}

sub _on_exit {
  my ($self, $status) = @_;
  undef $self->{kill_timer};
  $self->run_state(STATE_READY);
  $self->{exit_status} = $status || 0;
  $self->{exit_code} = $self->{exit_status} >> 8;

  $self->debug('child (pid %s) exited with status %d (exit code: %d)',
    $self->{pid} || '(no pid)',
    $self->{exit_status},
    $self->{exit_code},
  );

  # May not be set yet if launch fails early enough
  if ($self->{messages}) {
    $self->{messages}->shutdown;
  }
}

sub _on_read {
  my ($self, $type, $handle) = @_;
  $self->debug('read event type=%s', $type);
  $self->_push_read($handle, $type);
}

sub _push_read {
  my ($self, $handle, $type) = @_;
  $handle->push_read(line => $self->{eol}, sub{
    my ($handle, $line) = @_;
    chomp $line;
    $self->_queue_message($type, $line);
  });
}

sub _queue_message {
  my ($self, $type, $msg) = @_;
  $self->debug('buffered type=%s, msg="%s"', $type, $msg);

  my $message = IPC::Simple::Message->new(
    source  => $self,
    type    => $type,
    message => $msg,
  );

  if ($self->{recv_cb}) {
    $self->{recv_cb}->($message);
  } else {
    $self->{messages}->put($message);
  }
}

#-------------------------------------------------------------------------------
# Send a signal to the process
#-------------------------------------------------------------------------------
sub signal {
  my ($self, $signal) = @_;
  if ($self->{pid}) {
    $self->debug('sending %s to pid %d', $signal, $self->{pid});
    kill $signal, $self->{pid};
  }
}

#-------------------------------------------------------------------------------
# Stopping the process and waiting on it to complete
#-------------------------------------------------------------------------------
sub terminate {
  my $self = shift;
  my $timeout = shift;

  if ($self->is_running) {
    $self->signal('TERM');
    $self->run_state(STATE_STOPPING);

    $self->{handle_in}->push_shutdown;
    $self->{handle_out}->push_shutdown;
    $self->{handle_err}->push_shutdown;

    if (defined $timeout) {
      $self->{kill_timer} = AnyEvent->timer(
        after => $timeout,
        cb => sub{
          $self->signal('KILL');
          undef $self->{kill_timer};
        },
      );
    }

    if ($self->{term_cb}) {
      $self->{term_cb}->($self);
    }
  }
}

sub join {
  my $self = shift;

  return if $self->is_ready;

  $self->debug('waiting for process to exit, pid %d', $self->{pid});

  my $done = AnyEvent->condvar;

  my $timer; $timer = AnyEvent->timer(
    after => 0,
    interval => 0.01,
    cb => sub{
      # non-blocking waitpid returns 0 if the pid is still alive
      if (waitpid($self->{pid}, WNOHANG) != 0) {
        my $status = $?;

        # another waiter might have already called _on_exit
        unless ($self->is_ready) {
          $self->_on_exit($?);
        }

        $done->send;
      }
    },
  );

  $done->recv;
}

#-------------------------------------------------------------------------------
# Messages
#-------------------------------------------------------------------------------
sub send {
  my ($self, $msg) = @_;
  $self->debug('sending "%s"', $msg);
  $self->{handle_in}->push_write($msg . $self->{eol});
  1;
}

sub recv {
  my ($self, $type) = @_;
  $self->debug('waiting on message from pid %d', $self->{pid});
  $self->{messages}->get;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Simple - simple, non-blocking IPC

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use IPC::Simple qw(spawn);

  my $ssh = spawn ['ssh', $host];

  if ($ssh->launch) {
    $ssh->send('ls -lah');          # get directory listing
    $ssh->send('echo');             # signal our loop that the listing is done

    while (my $msg = $ssh->recv) {  # echo's output will be an empty string
      if ($msg->error) {            # I/O error
        croak $msg;
      }
      elsif ($msg->stderr) {        # output to STDERR
        warn $msg;
      }
      elsif ($msg->stdout) {        # output to STDOUT
        say $msg;
      }
    }

    $ssh->send('exit');             # terminate the connection
    $ssh->join;                     # wait for the process to terminate
  }

=head1 DESCRIPTION

Provides a simplified interface for managing and kibbitzing with a child
process.

=head1 EXPORTS

Nothing is exported by default, but the following subroutines may be requested
for import.

=head2 spawn

Returns a new C<IPC::Simple> object. The first argument is either the command
line string or an array ref of the command and its arguments. Any remaining
arguments are treated as keyword pairs for the constructor.

C<spawn> does I<not> launch the process.

  my $proc = spawn ["echo", "hello world"], eol => "\n";

Is equivalent to:

  my $proc = IPC::Simple->new(
    cmd => ["echo", "hello world"],
    eol => "\n",
  );

=head2 process_group

Builds a combined message queue for a group of I<unlaunched> C<IPC::Simple>
objects that may be used to process all of the group's messages together.
Returns an L<IPC::Simple::Group>.

  my $group = process_group(
    spawn('...', name => 'foo'),
    spawn('...', name => 'bar'),
    spawn('...', name => 'baz'),
  );

  $group->launch;

  while (my $msg = $group->recv) {
    if ($msg->source->name eq 'foo') {
      ...
    }
  }

  $group->terminate;
  $group->join;

=head1 METHODS

=head1 new

Creates a new C<IPC::Simple> process object. The process is not immediately
launched; see L</launch>.

=head2 constructor arguments

=over

=item cmd

The command to launch in a child process. This may be specified as the entire
command string or as an array ref of the command and its arguments.

=item name

Optionally specify a name for this process. This is useful when grouping
processes together to identify the source of a message. If not provided, the
command string is used by default.

=item eol

The end-of-line character to print at the end of each call to L</send>.
Defaults to C<"\n">.

=item recv_cb

Optionally, a callback may be specified to receive messages as they arrive.

  my $proc = spawn [...], recv_cb => sub{
    my $msg = shift;
    my $proc = $msg->source;
    ...
  };

  $proc->launch;
  $proc->join;

=item term_cb

Another optional callback to be triggered when the process is terminated. The
exit status and exit code are available once the L</join> method has been
called on the process object passed to the callback.

  my $proc = spawn [...], term_cb => sub{
    my $proc = shift;
    $proc->join;

    my $code = $proc->exit_code;
    my $status = $proc->exit_status;
    ...
  };

=back

=head2 pid

Once launched, returns the pid of the child process.

=head2 exit_status

Once a child process exits, this is set to the exit status (C<$?>) of the child
process.

=head2 exit_code

Once a child process has terminated, this is set to the exit code of the child
process.

=head2 launch

Starts the child process. Returns true on success, croaks on failure to launch
the process.

=head2 terminate

Sends the child process a C<SIGTERM>. Returns immediately. Use L</join> to wait
for the process to finish. An optional timeout may be specified in fractional
seconds, after which the child process is issued a C<SIGKILL>.

=head2 signal

Sends a signal to the child process. Accepts a single argument, the signal type
to send.

  $proc->signal('TERM');

=head2 join

Blocks until the child process has exited.

=head2 send

Sends a string of text to the child process. The string will be appended with
the value of L</eol>.

=head2 recv

Waits for and returns the next line of output from the process, which may be
from C<STDOUT>, from C<STDERR>, or it could be an error message resulting from
an I/O error while communicating with the process (e.g. a C<SIGPIPE> or
abnormal termination).

Each message returned by C<recv> is an object overloaded so that it can be
treated as a string as well as a L<IPC::Simple::Message> with the following
significant methods:

=over

=item source

The C<IPC::Simple> object from which the message originated.

=item stdout

True when the message came from the child process' C<STDOUT>.

=item stderr

True when the message came from the child process' C<STDERR>.

=item error

True when the message is a sub-process communication error.

=back

=head1 DEBUGGING

C<IPC::Simple> will emit highly verbose messages to C<STDERR> if the
environment variable C<IPC_SIMPLE_DEBUG> is set to a true value.

=head1 MSWIN32 SUPPORT

Nope.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
