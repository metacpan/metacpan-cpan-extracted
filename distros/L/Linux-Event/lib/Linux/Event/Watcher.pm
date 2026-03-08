package Linux::Event::Watcher;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

use Carp qw(croak);
use Scalar::Util qw(weaken);

# NOTE:
# This object is intentionally lightweight. It is a handle and a data container.
# The Loop owns policy and backend interactions; Watcher methods delegate into Loop.

sub new ($class, %args) {
  my $loop = delete $args{loop};
  my $fh   = delete $args{fh};
  my $fd   = delete $args{fd};

  my $read  = delete $args{read};
  my $write = delete $args{write};
  my $error = delete $args{error};

  my $data          = delete $args{data};
  my $edge_triggered = delete $args{edge_triggered};
  my $oneshot        = delete $args{oneshot};

  croak "unknown args: " . join(", ", sort keys %args) if %args;

  croak "loop is required" if !$loop;
  croak "fh is required"   if !$fh;
  croak "fd is required"   if !defined $fd;

  if (defined $read && ref($read) ne 'CODE') {
    croak "read must be a coderef or undef";
  }
  if (defined $write && ref($write) ne 'CODE') {
    croak "write must be a coderef or undef";
  }
  if (defined $error && ref($error) ne 'CODE') {
    croak "error must be a coderef or undef";
  }

  
  # Store a weak reference to the filehandle to avoid ownership and to detect closes.
  # If the user drops/closes the handle, the weak ref becomes undef and dispatch will auto-purge.
  weaken($fh) if ref($fh);

# Default enablement: if a handler exists, it's enabled.
  my $read_enabled  = $read  ? 1 : 0;
  my $write_enabled = $write ? 1 : 0;
  my $error_enabled = $error ? 1 : 0;

  return bless {
    loop  => $loop,
    fh    => $fh,
    fd    => int($fd),

    data  => $data,

    read_cb  => $read,
    write_cb => $write,
    error_cb => $error,

    read_enabled  => $read_enabled,
    write_enabled => $write_enabled,
    error_enabled => $error_enabled,

    edge_triggered => $edge_triggered ? 1 : 0,
    oneshot        => $oneshot        ? 1 : 0,

    active => 1,
  }, $class;
}

sub loop ($self) { return $self->{loop} }
sub fh   ($self) { return $self->{fh} }
sub fd   ($self) { return $self->{fd} }

sub is_active ($self) { return $self->{active} ? 1 : 0 }

sub data ($self, @args) {
  if (@args) {
    $self->{data} = $args[0];
  }
  return $self->{data};
}

sub edge_triggered ($self, @args) {
  if (@args) {
    $self->{edge_triggered} = $args[0] ? 1 : 0;
    $self->{loop}->_watcher_update($self);
  }
  return $self->{edge_triggered} ? 1 : 0;
}

sub oneshot ($self, @args) {
  if (@args) {
    $self->{oneshot} = $args[0] ? 1 : 0;
    $self->{loop}->_watcher_update($self);
  }
  return $self->{oneshot} ? 1 : 0;
}

sub on_read ($self, $cb = undef) {
  if (defined $cb && ref($cb) ne 'CODE') {
    croak "read handler must be a coderef or undef";
  }
  $self->{read_cb} = $cb;

  # If a handler is installed and read was disabled, do not silently enable.
  # Callers can explicitly enable_read() if desired.
  if (!$cb) {
    $self->{read_enabled} = 0;
  }

  $self->{loop}->_watcher_update($self);
  return $self;
}

sub on_write ($self, $cb = undef) {
  if (defined $cb && ref($cb) ne 'CODE') {
    croak "write handler must be a coderef or undef";
  }
  $self->{write_cb} = $cb;

  if (!$cb) {
    $self->{write_enabled} = 0;
  }

  $self->{loop}->_watcher_update($self);
  return $self;
}


sub on_error ($self, $cb = undef) {
  if (defined $cb && ref($cb) ne 'CODE') {
    croak "error handler must be a coderef or undef";
  }
  $self->{error_cb} = $cb;

  if (!$cb) {
    $self->{error_enabled} = 0;
  }

  # Note: error interest is not an epoll subscription bit; epoll reports ERR regardless.
  # This method only controls dispatch.
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub enable_error ($self) {
  $self->{error_enabled} = 1;
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub disable_error ($self) {
  $self->{error_enabled} = 0;
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub enable_read ($self) {
  $self->{read_enabled} = 1;
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub disable_read ($self) {
  $self->{read_enabled} = 0;
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub enable_write ($self) {
  $self->{write_enabled} = 1;
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub disable_write ($self) {
  $self->{write_enabled} = 0;
  $self->{loop}->_watcher_update($self);
  return $self;
}

sub read_enabled  ($self) { return $self->{read_enabled}  ? 1 : 0 }
sub write_enabled ($self) { return $self->{write_enabled} ? 1 : 0 }
sub error_enabled ($self) { return $self->{error_enabled} ? 1 : 0 }

sub cancel ($self) {
  return 0 if !$self->{active};

  my $ok = $self->{loop}->_watcher_cancel($self);
  $self->{active} = 0 if $ok;
  return $ok ? 1 : 0;
}

1;

__END__

=head1 NAME

Linux::Event::Watcher - Mutable watcher handle for Linux::Event::Loop

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new;

  my $conn = My::Conn->new(...);

  my $w = $loop->watch($fh,
    read  => \&My::Conn::on_read,
    write => \&My::Conn::on_write,
    error => \&My::Conn::on_error,  # optional
    data  => $conn,                  # optional
  );

  $w->disable_write;

  # later...
  $w->enable_write;

  # stop watching (does not close the fh)
  $w->cancel;

=head1 DESCRIPTION

A watcher is a lightweight mutable handle owned by the loop. It stores callbacks,
enable/disable state, and optional user data. The loop manages backend polling
and dispatch.

Watchers do not own the underlying filehandle; user code is responsible for
closing resources. Recommended teardown order is C<< $w->cancel; close $fh; >>.

=head1 METHODS

=head2 loop / fh / fd

Accessors for the owning loop, the watched filehandle, and its file descriptor.

=head2 data

Get/set the user data slot:

  my $data = $w->data;
  $w->data($new);

=head2 on_read / on_write / on_error

Install or replace handlers. Passing undef removes the handler and disables it.

=head2 enable_read / disable_read
=head2 enable_write / disable_write
=head2 enable_error / disable_error

Toggle dispatch. Interest masks are inferred from installed handlers and enable
state. Note: epoll reports errors regardless of interest; enable/disable only
controls dispatch of C<error>.

=head2 edge_triggered / oneshot

Advanced epoll behaviors. These update the backend registration immediately.

=head2 cancel

Remove the watcher from the loop/backend. This operation is idempotent.

=head1 CALLBACK SIGNATURES

Handlers are invoked as:

  read  => sub ($loop, $fh, $watcher) { ... }
  write => sub ($loop, $fh, $watcher) { ... }
  error => sub ($loop, $fh, $watcher) { ... }

=head1 DISPATCH SEMANTICS

On EPOLLERR, the loop calls C<error> first (if installed+enabled) and returns.
If no error handler is installed, EPOLLERR behaves like both readable and writable.

On EPOLLHUP, read readiness is triggered (EOF detection via read() returning 0).

=head1 VERSION

This document describes Linux::Event::Watcher version 0.006.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.
