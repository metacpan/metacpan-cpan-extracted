package Linux::Event::Listen;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.016';

use Carp qw(croak);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK F_GETFD F_SETFD FD_CLOEXEC);
use Socket qw(
  SOL_SOCKET SO_ACCEPTCONN
  AF_INET6
  IPPROTO_IPV6 IPV6_V6ONLY
  unpack_sockaddr_in unpack_sockaddr_in6 unpack_sockaddr_un
  inet_ntoa inet_ntop
);
use IO::Socket::IP ();   # core
use IO::Socket::UNIX (); # core

# new(%args)
#
# Required:
#   loop      => $loop
#   on_accept => sub ($loop, $client_fh, $peer, $listen) { ... }
#
# Socket source (choose one):
#   fh   => $server_fh
#   host => $host, port => $port
#
# Optional:
#   backlog             => 4096
#   reuseaddr           => 1
#   reuseport           => 0
#   v6only              => undef (OS default; only for IPv6 sockets we create)
#   nonblocking         => 1  (best-effort; forced in practice)
#   cloexec             => 1
#   edge_triggered      => 1
#   oneshot             => 0
#   max_accept_per_tick => 128
#   owns_socket         => (default 1 if created, else 0 if fh provided)
#   on_error            => sub ($loop, $err, $listen) { ... }
#   warn_on_unhandled_error => 0
#
sub new ($class, %args) {
  my $loop = delete $args{loop} // croak 'loop is required';

  my $on_accept = delete $args{on_accept} // croak 'on_accept is required';
  croak 'on_accept must be a code reference' if ref($on_accept) ne 'CODE';

  my $on_error = delete $args{on_error};
  croak 'on_error must be a code reference' if defined($on_error) && ref($on_error) ne 'CODE';

  my $on_emfile = delete $args{on_emfile};
  croak 'on_emfile must be a code reference' if defined($on_emfile) && ref($on_emfile) ne 'CODE';

  my $warn_on_unhandled_error = delete($args{warn_on_unhandled_error}) // 0;

  my $user_edge = exists $args{edge_triggered} ? 1 : 0;
  my $edge_triggered = $user_edge ? delete($args{edge_triggered}) : 1;
  my $oneshot        = delete($args{oneshot}) // 0;

  my $user_cap = exists $args{max_accept_per_tick} ? 1 : 0;
  my $max_accept_per_tick = $user_cap ? delete($args{max_accept_per_tick}) : 128;

  # EPOLLET (edge-triggered) requires draining accept() until EAGAIN. If the
  # caller explicitly caps accepts-per-tick but did not explicitly request edge
  # triggering, default to level-triggered so the cap cannot stall the listener.
  if ($user_cap && !$user_edge) {
    $edge_triggered = 0;
  }
  croak 'max_accept_per_tick must be a positive integer'
    if $max_accept_per_tick !~ /\A[0-9]+\z/ || $max_accept_per_tick < 1;

  my $cloexec     = delete($args{cloexec})     // 1;
  my $nonblocking = delete($args{nonblocking}) // 1; # best-effort; forced on in practice

  my $backlog   = delete($args{backlog})   // 4096;
  my $reuseaddr = delete($args{reuseaddr}) // 1;
  my $reuseport = delete($args{reuseport}) // 0;
  my $v6only    = delete($args{v6only}); # undef means OS default

  my $fh   = delete $args{fh};
  my $host = delete $args{host};
  my $port = delete $args{port};
  my $path = delete $args{path};
  my $unlink = delete($args{unlink}) // 0;
  my $unlink_on_cancel = exists $args{unlink_on_cancel} ? delete($args{unlink_on_cancel}) : undef;

  my $owns_socket = delete($args{owns_socket});

  croak "unknown option(s): @{[ sort keys %args ]}" if %args;

  croak 'provide either fh => $server_fh OR host/port OR path' if defined($fh) && (defined($host) || defined($port) || defined($path));
  croak 'host and port must be provided together' if (defined($host) xor defined($port));
  croak 'path cannot be combined with host/port' if defined($path) && defined($host);


  if (!defined $fh) {
    croak 'either fh, host/port, or path is required' if !defined($host) && !defined($path);

    if (defined $path) {
      if ($unlink) {
        unlink($path);
      }

      $fh = IO::Socket::UNIX->new(
        Type  => Socket::SOCK_STREAM(),
        Local => $path,
        Listen => $backlog,
      );
    } else {
      $fh = IO::Socket::IP->new(
        LocalHost => $host,
        LocalPort => $port,
        Listen    => $backlog,
        Proto     => 'tcp',
        ReuseAddr => $reuseaddr ? 1 : 0,
        ($reuseport ? (ReusePort => 1) : ()),
      );
    }

    if (!$fh) {
      my $err = {
        op    => 'setup',
        errno => 0 + $!,
        error => "$!",
        fatal => 1,
      };
      if ($on_error) {
        eval { $on_error->($loop, $err, undef) };
      }
      croak "listen setup failed: $err->{error}";
    }

    # Optional: v6only on sockets we created.
    if (defined $v6only) {
      my $ok = eval {
        my $af = getsockopt($fh, Socket::SOL_SOCKET(), Socket::SO_DOMAIN());
        1;
      };
      # Some perls/platforms don't support SO_DOMAIN; best-effort:
      eval { setsockopt($fh, IPPROTO_IPV6, IPV6_V6ONLY, pack('I', $v6only ? 1 : 0)) };
    }

    $owns_socket = 1 if !defined $owns_socket;
    $unlink_on_cancel = 1 if defined($path) && !defined($unlink_on_cancel);
  } else {
    $owns_socket = 0 if !defined $owns_socket;
  }

  # If caller provided fh, validate it is in listening state.
  if (defined $fh && !defined $host) {
    my $acceptconn = getsockopt($fh, SOL_SOCKET, SO_ACCEPTCONN);
    if (!defined $acceptconn || !unpack('i', $acceptconn)) {
      croak 'fh is not a listening socket (SO_ACCEPTCONN is false)';
    }
  }

  # Force nonblocking + cloexec on the listening fh
  _set_nonblocking($fh) if $nonblocking;
  _set_cloexec($fh) if $cloexec;

  my $self = bless {
    loop  => $loop,
    fh    => $fh,
    owns_socket => $owns_socket ? 1 : 0,
    on_accept   => $on_accept,
    on_error    => $on_error,
    on_emfile => $on_emfile,
    warn_on_unhandled_error => $warn_on_unhandled_error ? 1 : 0,
    edge_triggered => $edge_triggered ? 1 : 0,
    oneshot        => $oneshot ? 1 : 0,
    max_accept_per_tick => $max_accept_per_tick,
    paused => 0,
    watcher => undef,
    _unix_path => (defined $path ? $path : undef),
    _unlink_on_cancel => ($unlink_on_cancel ? 1 : 0),
    _in_read_cb   => 0,
    _defer_close  => 0,
    _cancelled    => 0,
    cloexec => $cloexec ? 1 : 0,
    nonblocking => $nonblocking ? 1 : 0,
  }, $class;

  # Install watcher. Keep the accept loop in the callback to avoid layers.
  my %watch = (
    read => sub ($loop, $listen_fh, $w) {
      local $self->{_in_read_cb} = 1;
      my $accepted = 0;

      while ($accepted < $self->{max_accept_per_tick}) {
        my $client;
        my $peer_packed = accept($client, $listen_fh);

        if (!$peer_packed) {
          my $errno = 0 + $!;
          # EAGAIN/EWOULDBLOCK end-of-drain is the normal exit condition.
          # Treat EINTR/ECONNABORTED as retry.
          if ($errno == _EINTR() || $errno == _ECONNABORTED()) {
            next;
          }
          if ($errno == _EAGAIN() || $errno == _EWOULDBLOCK()) {
            last;
          }

          my $err = {
            op    => 'accept',
            errno => $errno,
            error => "$!",
            fatal => 0,
          };

          if (($errno == _EMFILE() || $errno == _ENFILE()) && $self->{on_emfile}) {
            eval { $self->{on_emfile}->($loop, $err, $self) };
          } elsif ($self->{on_error}) {

            eval { $self->{on_error}->($loop, $err, $self) };
          } elsif ($self->{warn_on_unhandled_error}) {
            warn "Linux::Event::Listen accept error: $err->{error}\n";
          }
          last;
        }

        _set_nonblocking($client) if $self->{nonblocking};
        _set_cloexec($client) if $self->{cloexec};

        my $peer = _peer_from_sockaddr($peer_packed);

        my $ok = eval { $self->{on_accept}->($loop, $client, $peer, $self); 1 };
        if (!$ok) {
          my $e = $@ || 'unknown error';
          my $err = {
            op    => 'on_accept',
            error => "$e",
            fatal => 0,
          };
          if ($self->{on_error}) {
            eval { $self->{on_error}->($loop, $err, $self) };
          } else {
            die $e;
          }
        }

        $accepted++;

        last if $self->{_cancelled};
      }

      if ($self->{_defer_close} && $self->{fh}) {
        close($self->{fh});
        delete $self->{fh};
        if ($self->{_unix_path} && $self->{_unlink_on_cancel}) {
          unlink($self->{_unix_path});
        }
        $self->{_defer_close} = 0;
      }
    },

    edge_triggered => $self->{edge_triggered},
    oneshot        => $self->{oneshot},
  );

  # If user wants error visibility, wire error callback too.
  if ($self->{on_error} || $self->{warn_on_unhandled_error}) {
    $watch{error} = sub ($loop, $listen_fh, $w) {
      my $err = { op => 'watch', error => 'listener socket error/hup', fatal => 0 };
      if ($self->{on_error}) {
        eval { $self->{on_error}->($loop, $err, $self) };
      } elsif ($self->{warn_on_unhandled_error}) {
        warn "Linux::Event::Listen watcher error: $err->{error}\n";
      }
    };
  }

  $self->{watcher} = $loop->watch($fh, %watch);

  return $self;
}

# Separate entry-point to keep call sites short:
#   my $listen = Linux::Event::Listen->listen($loop, host => ..., port => ..., on_accept => ...);
sub listen ($class, $loop, %args) {
  return $class->new(loop => $loop, %args);
}

# --- Control ---------------------------------------------------------------

sub watcher ($self) { return $self->{watcher} }
sub fh      ($self) { return $self->{fh} }

sub fd ($self) {
  my $fh = $self->{fh} // return undef;
  return fileno($fh);
}

sub pause ($self) {
  return $self if $self->{paused};
  $self->{watcher}->disable_read if $self->{watcher};
  $self->{paused} = 1;
  return $self;
}

sub resume ($self) {
  return $self if !$self->{paused};
  $self->{watcher}->enable_read if $self->{watcher};
  $self->{paused} = 0;
  return $self;
}

sub is_paused ($self) { return $self->{paused} ? 1 : 0 }

sub is_running ($self) { return $self->{watcher} ? 1 : 0 }

sub family ($self) { return $self->{_family} // 'unknown' }
sub is_unix ($self) { return ($self->{_family} // '') eq 'unix' ? 1 : 0 }
sub is_tcp  ($self) { return ($self->{_family} // '') =~ /\Ainet/ ? 1 : 0 }

sub sockhost ($self) {
  my $fh = $self->{fh} // return undef;
  return eval { $fh->sockhost };
}

sub sockport ($self) {
  my $fh = $self->{fh} // return undef;
  return eval { $fh->sockport };
}


sub cancel ($self) {
  $self->{_cancelled} = 1;

  my $w = delete $self->{watcher};
  $w->cancel if $w;

  if ($self->{owns_socket} && $self->{fh}) {
    if ($self->{_in_read_cb}) {
      $self->{_defer_close} = 1;
    } else {
      close($self->{fh});
      delete $self->{fh};
      if ($self->{_unix_path} && $self->{_unlink_on_cancel}) {
        unlink($self->{_unix_path});
      }
    }
  }

  return $self;
}

sub DESTROY ($self) {
  eval { $self->cancel };
  return;
}

# --- Internal utilities ----------------------------------------------------

sub _set_nonblocking ($fh) {
  my $flags = fcntl($fh, F_GETFL, 0);
  return if !defined $flags; # best-effort
  fcntl($fh, F_SETFL, $flags | O_NONBLOCK);
  return;
}

sub _set_cloexec ($fh) {
  my $fdflags = fcntl($fh, F_GETFD, 0);
  return if !defined $fdflags;
  fcntl($fh, F_SETFD, $fdflags | FD_CLOEXEC);
  return;
}

sub _peer_from_sockaddr ($packed) {
  my $len = length($packed);

  # IPv4 sockaddr_in length is typically 16; IPv6 is typically 28.
  if ($len == 16) {
    my ($port, $addr) = unpack_sockaddr_in($packed);
    return {
      family => 'inet',
      host   => inet_ntoa($addr),
      port   => $port,
    };
  }

  my ($port6, $addr6, $scope, $flow) = eval { unpack_sockaddr_in6($packed) };
  if (defined $port6) {
    my $host6 = inet_ntop(AF_INET6, $addr6);
    return {
      family   => 'inet6',
      host     => $host6,
      port     => $port6,
      scope_id => $scope,
    };
  }

  my $upath = eval { unpack_sockaddr_un($packed) };
  if (defined $upath) {
    return { family => 'unix', path => $upath };
  }

  return { family => 'unknown' };
}

# Errno constants without depending on POSIX::Errno exports.
sub _EINTR        () { 4 }
sub _EAGAIN       () { 11 }
sub _EWOULDBLOCK  () { 11 }   # Linux: same as EAGAIN
sub _ECONNABORTED () { 103 }
sub _EMFILE       () { 24 }
sub _ENFILE       () { 23 }

1;

__END__

=head1 NAME

Linux::Event::Listen - Listening sockets for Linux::Event

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;
  use Linux::Event::Listen;

  my $loop = Linux::Event->new;

  # Basic usage: accept sockets and attach your own per-connection watchers.
  my $listen = Linux::Event::Listen->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 3000,

    on_accept => sub ($loop, $client_fh, $peer, $listen) {
      # You own $client_fh. It is already non-blocking.
      $loop->watch($client_fh,
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
      );
    },

    on_error => sub ($loop, $err, $listen) {
      warn "listener error ($err->{op}): $err->{error}\n";
    },
  );

  # Canonical server pattern: Listen + Stream + line codec.
  # This keeps Listen focused on accepting sockets while Stream handles buffered
  # I/O and framing.
  #
  #   use Linux::Event::Stream;
  #
  #   Linux::Event::Listen->new(
  #     loop => $loop,
  #     host => '127.0.0.1',
  #     port => 3000,
  #
  #     on_accept => sub ($loop, $client_fh, $peer, $listen) {
  #       Linux::Event::Stream->new(
  #         loop       => $loop,
  #         fh         => $client_fh,
  #         codec      => 'line',
  #         on_message => sub ($stream, $line, $data) {
  #           $stream->write_message("echo: $line");
  #           $stream->close_after_drain if $line eq 'quit';
  #         },
  #       );
  #     },
  #   );

  $loop->run;

=head1 DESCRIPTION

B<Linux::Event::Listen> creates or wraps a listening socket and attaches it to a
L<Linux::Event> loop. When the socket becomes readable, it accepts connections
and invokes your C<on_accept> callback once per accepted client.

This distribution is intentionally small and policy-light:

=over 4

=item *

It accepts connections and invokes your callback; it does not implement any
application protocol.

=item *

It does not create per-connection watchers for you.

=item *

It guarantees the correct accept-drain behavior required for edge-triggered
notification (accept until C<EAGAIN>), with a fairness cap.

=back

=head1 CONSTRUCTOR

=head2 new

  my $listen = Linux::Event::Listen->new(%args);

Required:

=over 4

=item * C<loop>

A L<Linux::Event::Loop> instance.

=item * C<on_accept>

  on_accept => sub ($loop, $client_fh, $peer, $listen) { ... }

Called once per accepted connection.

=back

You must also provide either:

=over 4

=item * C<fh>

A listening socket handle (already bound and in listen state), or

=item * C<host> and C<port>

TCP address to bind and listen on, or

=item * C<path>

UNIX domain socket path to bind and listen on.

=back

=head1 OPTIONS

=head2 on_accept

  on_accept => sub ($loop, $client_fh, $peer, $listen) { ... }

Your callback is invoked once per accepted connection.

Ownership: you own C<$client_fh>. This module never closes it.

=head2 on_error

  on_error => sub ($loop, $err, $listen) { ... }

=head2 on_emfile

  on_emfile => sub ($loop, $err, $listen) { ... }

Optional callback invoked when accept() fails with C<EMFILE> or C<ENFILE>.
This is where production servers often implement "reserve FD" mitigation.

Optional callback invoked for accept-time errors and watcher error/hup events.

C<$err> is a hashref with keys like:

  { op => 'accept', errno => ..., error => "...", fatal => 0 }

=head2 edge_triggered

  edge_triggered => 1  # default

Sets the underlying watcher to edge-triggered mode. The accept loop always drains
the accept queue until C<EAGAIN>, which is required for correctness when edge
triggered.

=head2 oneshot

  oneshot => 0  # default

Passed through to the underlying watcher.

=head2 max_accept_per_tick

  max_accept_per_tick => 128  # default

Upper bound on accepted connections per readable event callback.

If you set this option without explicitly setting C<edge_triggered>, this module
will default to level-triggered readiness so the cap cannot stall the listener.

If you explicitly enable C<edge_triggered> and also cap accepts-per-tick, you
must ensure you still eventually drain accept() until C<EAGAIN> (for example by
using a level-triggered listener, or designing your own re-arm strategy).

=head2 cloexec

  cloexec => 1  # default

Sets C<FD_CLOEXEC> on the listening socket and accepted sockets (best-effort).

=head2 nonblocking

  nonblocking => 1  # default

Accepted sockets are set non-blocking (best-effort). The listening socket is also
set non-blocking.

=head2 path

  path => '/tmp/app.sock'

Bind and listen on a UNIX domain socket path.

=head2 unlink

  unlink => 1

If true and C<path> is used, unlink the path before binding (useful for restarts).

=head2 unlink_on_cancel

  unlink_on_cancel => 1

If true and C<path> is used, unlink the socket file when the listener is
cancelled (or destroyed). Defaults to true for internally-created UNIX sockets.

=head2 owns_socket

If true, C<< $listen->cancel >> will close the listening socket. Defaults to
false when C<fh> is provided, and true when the socket is created internally.

=head1 METHODS

=head2 fh

  my $fh = $listen->fh;

Return the listening socket handle.

=head2 fd

  my $fd = $listen->fd;

=head2 sockhost / sockport

  my $host = $listen->sockhost;
  my $port = $listen->sockport;

Convenience accessors that delegate to the underlying socket handle. For UNIX
sockets these may return undef, depending on the underlying implementation.

Return the numeric file descriptor of the listening socket (or undef).

=head2 watcher

  my $w = $listen->watcher;

=head2 is_running

  if ($listen->is_running) { ... }

True if the underlying watcher is installed.

Return the underlying L<Linux::Event::Watcher>.

=head2 pause / resume

  $listen->pause;
  $listen->resume;

Disable/enable read interest on the listening socket.

=head2 cancel

  $listen->cancel;

Cancel the underlying watcher and, if C<owns_socket> is true, close the listening
socket.

=head1 ERROR HASH

When C<on_error> or C<on_emfile> is invoked, the second argument is a hashref
describing the condition.

Common keys:

  op     - one of: setup, accept, watch, on_accept
  error  - string form of the error
  errno  - numeric errno (only when the error came from C<$!>)
  fatal  - boolean (true for setup failures)

Depending on how the listener was created, C<host>/C<port> or C<path> may be
present for C<op = setup> errors.

=head1 ACCEPT LOOP SEMANTICS

When the listening socket is readable, this module attempts to accept connections
in a loop until one of these conditions is met:

=over 4

=item * accept returns C<EAGAIN> / C<EWOULDBLOCK> (normal)

=item * C<max_accept_per_tick> is reached (fairness)

=item * a non-retryable accept error occurs

=back

The following errors are retried: C<EINTR>, C<ECONNABORTED>.

=head1 NOTES

=head1 STREAM INTEGRATION

Linux::Event::Listen is intentionally policy-light: it accepts connections and
hands you a non-blocking client filehandle. A common pattern is to immediately
wrap the client socket in L<Linux::Event::Stream> and use a codec to define
message boundaries. For example, line-delimited protocols:

  use Linux::Event::Stream;

  my $listen = Linux::Event::Listen->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 3000,

    on_accept => sub ($loop, $client_fh, $peer, $listen) {
      Linux::Event::Stream->new(
        loop       => $loop,
        fh         => $client_fh,
        codec      => 'line',
        on_message => sub ($stream, $line, $data) {
          $stream->write_message("echo: $line");
          $stream->close_after_drain if $line eq 'quit';
        },
      );
    },
  );

This keeps Listen focused on accepting sockets while Stream handles buffered I/O
and framing.

=head1 SEE ALSO

L<Linux::Event>, L<Linux::Event::Loop>, L<Linux::Event::Watcher>, L<IO::Socket::IP>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.
