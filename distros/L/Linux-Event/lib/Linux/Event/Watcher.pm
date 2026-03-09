package Linux::Event::Watcher;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

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

Linux::Event::Watcher - Mutable readiness watcher handle for Linux::Event::Reactor

=head1 SYNOPSIS

<<<<<<< HEAD
  my $watcher = $loop->watch(
    $fh,
    read => sub ($loop, $fh, $watcher) {
      ...
=======
  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new( model => 'reactor' );

  my $w = $loop->watch($fh,
    read => sub ($loop, $fh, $w) {
      my $buf;
      my $n = sysread($fh, $buf, 8192);

      if (!defined $n || $n == 0) {
        $w->cancel;
        close $fh;
        return;
      }

      # ... handle $buf ...
    },

    write => sub ($loop, $fh, $w) {
      # fd became writable
      $w->disable_write; # typical: only enable when you actually have pending output
    },

    error => sub ($loop, $fh, $w) {
      # error readiness reported (see DISPATCH SEMANTICS)
      $w->cancel;
      close $fh;
>>>>>>> 1401c31 (prep for cpan and release, new tool added)
    },
  );

  $watcher->disable_read;
  $watcher->enable_read;
  $watcher->cancel;

=head1 DESCRIPTION

C<Linux::Event::Watcher> is the lightweight handle returned by
L<Linux::Event::Reactor/watch>. It stores the current callbacks, enablement
flags, filehandle metadata, and a user data slot.

The watcher does not own backend policy. Methods that change interest state
simply delegate back into the loop.

=head1 METHODS

=head2 loop, fh, fd

Basic accessors.

=head2 is_active

True while the watcher is still registered with the loop.

=head2 data([$new])

Get or set the user data slot.

=head2 edge_triggered([$bool])

Get or set edge-triggered mode.

=head2 oneshot([$bool])

Get or set one-shot mode.

=head2 on_read([$cb])

=head2 on_write([$cb])

=head2 on_error([$cb])

Install or replace callbacks.

=head2 enable_read, disable_read

=head2 enable_write, disable_write

=head2 enable_error, disable_error

Toggle callback enablement.

=head2 cancel

Remove the watcher from the loop.

=head1 CALLBACK ABI

Watcher callbacks receive:

<<<<<<< HEAD
  $cb->($loop, $fh, $watcher)
=======
=head2 Error readiness ordering

If an epoll event indicates an error condition (for example C<EPOLLERR>), the loop
dispatches to the watcher's C<error> callback first (if installed and enabled)
and returns.

If no C<error> callback is installed/enabled, error readiness may be treated as
readable and/or writable (depending on the platform and backend behavior). Do not
rely on a specific fallback; install an C<error> handler if you want explicit
error handling.

=head2 Hangup / EOF

On hangup conditions (for example C<EPOLLHUP>), readable readiness is typically
delivered so user code can observe EOF via C<read(2)> returning 0.

=head1 VERSION

This document describes Linux::Event::Watcher version 0.009.
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

=head1 SEE ALSO

L<Linux::Event::Reactor>,
L<Linux::Event::Loop>

=cut
