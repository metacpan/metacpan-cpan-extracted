package IPC::Simple;
# ABSTRACT: simple, non-blocking IPC
$IPC::Simple::VERSION = '0.02';

use strict;
use warnings;

use AnyEvent::Handle;
use AnyEvent;
use Carp;
use Fcntl;
use IPC::Open3 qw(open3);
use Moo;
use POSIX qw(:sys_wait_h);
use Symbol qw(gensym);
use Types::Standard -types;

use IPC::Simple::Channel;
use IPC::Simple::Message;

BEGIN{
  extends 'Exporter';

  our @EXPORT = qw(
    IPC_STDOUT
    IPC_STDERR
    IPC_ERROR
  );
}

use constant STATE_READY    => 0;
use constant STATE_RUNNING  => 1;
use constant STATE_STOPPING => 2;

has cmd =>
  is => 'ro',
  isa => Str,
  require => 1;

has args =>
  is => 'ro',
  isa => ArrayRef[Str],
  default => sub{ [] };

has eol =>
  is => 'ro',
  isa => Str,
  default => "\n";

has run_state =>
  is => 'rw',
  isa => Enum[ STATE_READY, STATE_RUNNING, STATE_STOPPING ],
  default => STATE_READY;

has pid =>
  is => 'rw',
  isa => Num,
  init_arg => undef;

has proc_monitor =>
  is => 'rw',
  init_arg => undef,
  clearer => 1;

has fh_in =>
  is => 'rw',
  isa => FileHandle,
  init_arg => undef;

has fh_out =>
  is => 'rw',
  isa => FileHandle,
  init_arg => undef;

has fh_err =>
  is => 'rw',
  isa => FileHandle,
  init_arg => undef;

has handle_out =>
  is => 'rw',
  isa => InstanceOf['AnyEvent::Handle'],
  init_arg => undef;

has handle_err =>
  is => 'rw',
  isa => InstanceOf['AnyEvent::Handle'],
  init_arg => undef;

has cv_exited =>
  is => 'rw',
  isa => InstanceOf['AnyEvent::CondVar'],
  init_arg => undef;

has exit_status =>
  is => 'rw',
  isa => Maybe[Int],
  init_arg => undef;

has messages =>
  is => 'rw',
  isa => InstanceOf['IPC::Simple::Channel'],
  init_arg => undef,
  handles => {
    recv => 'get',
  };

sub DEMOLISH {
  my $self = shift;
  $self->terminate;
  $self->join;
}

sub is_ready    { $_[0]->run_state == STATE_READY }
sub is_running  { $_[0]->run_state == STATE_RUNNING }
sub is_stopping { $_[0]->run_state == STATE_STOPPING }

sub exit_code {
  my $self = shift;
  return unless defined $self->exit_status;
  return $self->exit_status >> 8;
}

sub launch {
  my $self = shift;

  if ($self->is_running) {
    croak 'already running';
  }

  if ($self->is_stopping) {
    croak 'process is terminating';
  }

  debug('launching: %s %s', $self->cmd, "@{$self->args}");

  my $pid = open3(
    my $in,
    my $out,
    my $err = gensym,
    $self->cmd,
    @{$self->args},
  ) or croak $!;

  my $cv = AE::cv;

  $self->run_state(STATE_RUNNING);
  $self->cv_exited($cv);
  $self->pid($pid);
  $self->fh_in($in);
  $self->fh_out($out);
  $self->fh_err($err);
  $self->messages(IPC::Simple::Channel->new);
  $self->handle_err($self->_build_handle($err, IPC_STDERR));
  $self->handle_out($self->_build_handle($out, IPC_STDOUT));

  $self->proc_monitor(
    AE::child($pid, sub{
      my ($pid, $status) = @_;
      debug('child (pid %d) exited with status %d (exit code: %d)', $pid, $status, $status >> 8);
      $self->run_state(STATE_READY);
      $self->exit_status($status);
      $self->messages->shutdown;
      $cv->send($status);
      $self->clear_proc_monitor;
    })
  );

  return 1;
}

sub _build_handle {
  my ($self, $fh, $type) = @_;

  # set non-blocking
  my $flags = fcntl $fh, F_GETFL, 0;
  fcntl $fh, F_SETFL, $flags | O_NONBLOCK;

  return AnyEvent::Handle->new(
    fh => $fh,
    on_eof => sub{ $self->terminate },

    on_error => sub{
      my ($handle, $fatal, $msg) = @_;
      debug('recv error type=%d, msg="%s"', $type, $msg);

      $self->messages->put(
        IPC::Simple::Message->new(
          source  => IPC_ERROR,
          message => $msg,
        ),
      );

      $self->terminate if $fatal;
    },

    on_read => sub{
      my ($handle) = @_;
      debug('read event type=%d', $type);

      $handle->push_read(line => $self->eol, sub{
        my ($handle, $line) = @_;
        chomp $line;
        debug('recv type=%d, msg="%s"', $type, $line);

        $self->messages->put(
          IPC::Simple::Message->new(
            source  => $type,
            message => $line,
          ),
        );
      });
    },
  );
}

sub terminate {
  my $self = shift;
  if ($self->is_running) {
    debug('sending TERM to pid %d', $self->pid);
    $self->run_state(STATE_STOPPING);
    kill 'TERM', $self->pid;
  }
}

sub join {
  my $self = shift;
  if ($self->cv_exited) {
    debug('waiting for process to exit, pid %d', $self->pid);
    $self->cv_exited->recv;
  }
}

sub send {
  my ($self, $msg) = @_;
  my $fh = $self->fh_in;
  local $\ = $self->eol;
  local $| = 1;
  print $fh $msg;
}

sub async {
  my ($self, $cb) = @_;
  my $cv = $self->messages->async;
  $cv->cb(sub{ $cb->( $cv->recv ) });
  return;
}

sub debug {
  if ($ENV{IPC_SIMPLE_DEBUG}) {
    my $msg = sprintf shift, @_;
    warn "<IPC::Simple> $msg\n";
  }
}

after run_state => sub{
  my $self = shift;
  debug('run state changed to %d', @_) if @_;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Simple - simple, non-blocking IPC

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use IPC::Simple;

  my $ssh = IPC::Simple->new(
    cmd  => 'ssh',
    args => [ $host ],
    eol  => "\n",
  );

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

=head1 METHODS

=head1 new

Creates a new C<IPC::Simple> process object. The process is not immediately
launched; see L</launch>.

=head2 constructor arguments

=over

=item cmd

The command to launch in a child process.

=item args

An array ref of arguments to C<cmd>.

=item eol

The end-of-line character to print at the end of each call to L</send>.
Defaults to C<"\n">.

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

Sends the child process a `SIGTERM`. Returns immediately. Use L</join> to wait
for the process to finish.

=head2 join

Blocks until the child process has exited.

=head2 send

Sends a string of text to the child process. The string will be appended with a
single newline.

=head2 recv

Waits for and returns the next line of output from the process, which may be
from C<STDOUT>, from C<STDERR>, or it could be an error message resulting from
an I/O error while communicating with the process (e.g. a C<SIGPIPE> or
abnormal termination).

Each message returned by C<recv> is an object overloaded so that it can be
treated as a string as well as providing the following methods:

=head2 async

Schedules a callback for the next line of input to be received, returning
immediately.

  $proc->async(sub{
    my $msg = shift;

    if ($msg->stdout) {
      ...
    }
  });

This is done with L<AnyEvent/CONDITION-VARIABLES>, so the same caveats about
races and dead locks apply. It is up to the caller to manage their event loop.

=over

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

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
