package IO::Pipely;
{
  $IO::Pipely::VERSION = '0.005';
}

use warnings;
use strict;

use Symbol qw(gensym);
use IO::Socket qw(
  AF_UNIX
  PF_INET
  PF_UNSPEC
  SOCK_STREAM
  SOL_SOCKET
  SOMAXCONN
  SO_ERROR
  SO_REUSEADDR
  inet_aton
  pack_sockaddr_in
  unpack_sockaddr_in
);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Errno qw(EINPROGRESS EWOULDBLOCK);

our @EXPORT_OK = qw(pipely socketpairly);
use base qw(Exporter);

# The order of pipe primitives depends on the platform.

# It's not always safe to assume that a function can be used if it's
# present.

my (@oneway_pipe_types, @twoway_pipe_types);
if ($^O eq "MSWin32" or $^O eq "MacOS") {
  @oneway_pipe_types = qw(inet socketpair pipe);
  @twoway_pipe_types = qw(inet socketpair pipe);
}
elsif ($^O eq "cygwin") {
  @oneway_pipe_types = qw(pipe inet socketpair);
  @twoway_pipe_types = qw(inet pipe socketpair);
}
else {
  @oneway_pipe_types = qw(pipe socketpair inet);
  @twoway_pipe_types = qw(socketpair inet pipe);
}

# Provide dummy constants so things at least compile.  These constants
# aren't used if we're RUNNING_IN_HELL, but Perl needs to see them.

BEGIN {
  # older perls than 5.10 needs a kick in the arse to AUTOLOAD the constant...
  eval "F_GETFL" if $] < 5.010;

  if ( ! defined &Fcntl::F_GETFL ) {
    if ( ! defined prototype "F_GETFL" ) {
      *F_GETFL = sub { 0 };
      *F_SETFL = sub { 0 };
    } else {
      *F_GETFL = sub () { 0 };
      *F_SETFL = sub () { 0 };
    }
  }
}

# Make a socket.  This is a homebrew socketpair() for systems that
# don't support it.  The things I must do to make Windows happy.

sub _make_socket {

  ### Server side.

  my $acceptor = gensym();
  my $accepted = gensym();

  my $tcp = getprotobyname('tcp') or die "getprotobyname: $!";
  socket( $acceptor, PF_INET, SOCK_STREAM, $tcp ) or die "socket: $!";

  setsockopt( $acceptor, SOL_SOCKET, SO_REUSEADDR, 1) or die "reuse: $!";

  my $server_addr = inet_aton('127.0.0.1') or die "inet_aton: $!";
  $server_addr = pack_sockaddr_in(0, $server_addr)
    or die "sockaddr_in: $!";

  bind( $acceptor, $server_addr ) or die "bind: $!";

  $acceptor->blocking(0);

  $server_addr = getsockname($acceptor);

  listen( $acceptor, SOMAXCONN ) or die "listen: $!";

  ### Client side.

  my $connector = gensym();

  socket( $connector, PF_INET, SOCK_STREAM, $tcp ) or die "socket: $!";

  $connector->blocking(0);

  unless (connect( $connector, $server_addr )) {
    die "connect: $!" if $! and ($! != EINPROGRESS) and ($! != EWOULDBLOCK);
  }

  my $connector_address = getsockname($connector);
  my ($connector_port, $connector_addr) =
    unpack_sockaddr_in($connector_address);

  ### Loop around 'til it's all done.  I thought I was done writing
  ### select loops.  Damnit.

  my $in_read  = '';
  my $in_write = '';

  vec( $in_read,  fileno($acceptor),  1 ) = 1;
  vec( $in_write, fileno($connector), 1 ) = 1;

  my $done = 0;
  while ($done != 0x11) {
    my $hits = select( my $out_read   = $in_read,
                       my $out_write  = $in_write,
                       undef,
                       5
                     );
    unless ($hits) {
      next if ($! and ($! == EINPROGRESS) or ($! == EWOULDBLOCK));
      die "select: $!" unless $hits;
    }

    # Accept happened.
    if (vec($out_read, fileno($acceptor), 1)) {
      my $peer = accept($accepted, $acceptor);
      my ($peer_port, $peer_addr) = unpack_sockaddr_in($peer);

      if ( $peer_port == $connector_port and
           $peer_addr eq $connector_addr
         ) {
        vec($in_read, fileno($acceptor), 1) = 0;
        $done |= 0x10;
      }
    }

    # Connect happened.
    if (vec($out_write, fileno($connector), 1)) {
      $! = unpack('i', getsockopt($connector, SOL_SOCKET, SO_ERROR));
      die "connect: $!" if $!;

      vec($in_write, fileno($connector), 1) = 0;
      $done |= 0x01;
    }
  }

  # Turn blocking back on, damnit.
  $accepted->blocking(1);
  $connector->blocking(1);

  return ($accepted, $connector);
}

sub pipely {
  my %arg = @_;

  my $conduit_type = delete($arg{type});
  my $debug        = delete($arg{debug}) || 0;

  # Generate symbols to be used as filehandles for the pipe's ends.
  #
  # Filehandle autovivification isn't used for portability with older
  # versions of Perl.

  my ($a_read, $b_write)  = (gensym(), gensym());

  # Try the specified conduit type only.  No fallback.

  if (defined $conduit_type) {
    return ($a_read, $b_write) if _try_oneway_type(
      $conduit_type, $debug, \$a_read, \$b_write
    );
  }

  # Otherwise try all available conduit types until one works.
  # Conduit types that fail are discarded for speed.

  while (my $try_type = $oneway_pipe_types[0]) {
    return ($a_read, $b_write) if _try_oneway_type(
      $try_type, $debug, \$a_read, \$b_write
    );
    shift @oneway_pipe_types;
  }

  # There's no conduit type left.  Bummer!

  $debug and warn "nothing worked";
  return;
}

sub socketpairly {
  my %arg = @_;

  my $conduit_type = delete($arg{type});
  my $debug        = delete($arg{debug}) || 0;

  # Generate symbols to be used as filehandles for the pipe's ends.
  #
  # Filehandle autovivification isn't used for portability with older
  # versions of Perl.

  my ($a_read, $a_write) = (gensym(), gensym());
  my ($b_read, $b_write) = (gensym(), gensym());

  if (defined $conduit_type) {
    return ($a_read, $a_write, $b_read, $b_write) if _try_twoway_type(
      $conduit_type, $debug,
      \$a_read, \$a_write,
      \$b_read, \$b_write
    );
  }

  while (my $try_type = $twoway_pipe_types[0]) {
    return ($a_read, $a_write, $b_read, $b_write) if _try_twoway_type(
      $try_type, $debug,
      \$a_read, \$a_write,
      \$b_read, \$b_write
    );
    shift @oneway_pipe_types;
  }

  # There's no conduit type left.  Bummer!

  $debug and warn "nothing worked";
  return;
}

# Try a pipe by type.

sub _try_oneway_type {
  my ($type, $debug, $a_read, $b_write) = @_;

  # Try a pipe().
  if ($type eq "pipe") {
    eval {
      pipe($$a_read, $$b_write) or die "pipe failed: $!";
    };

    # Pipe failed.
    if (length $@) {
      warn "pipe failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a pipe";
      warn "ar($$a_read) bw($$b_write)\n";
    };

    # Turn off buffering.  POE::Kernel does this for us, but
    # someone might want to use the pipe class elsewhere.
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # Try a UNIX-domain socketpair.
  if ($type eq "socketpair") {
    eval {
      socketpair($$a_read, $$b_write, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    };

    if (length $@) {
      warn "socketpair failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a UNIX domain socketpair";
      warn "ar($$a_read) bw($$b_write)\n";
    };

    # It's one-way, so shut down the unused directions.
    shutdown($$a_read,  1);
    shutdown($$b_write, 0);

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # Try a pair of plain INET sockets.
  if ($type eq "inet") {
    eval {
      ($$a_read, $$b_write) = _make_socket();
    };

    if (length $@) {
      warn "make_socket failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a plain INET socket";
      warn "ar($$a_read) bw($$b_write)\n";
    };

    # It's one-way, so shut down the unused directions.
    shutdown($$a_read,  1);
    shutdown($$b_write, 0);

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # There's nothing left to try.
  $debug and warn "unknown pipely() socket type ``$type''";
  return;
}

# Try a pipe by type.

sub _try_twoway_type {
  my ($type, $debug, $a_read, $a_write, $b_read, $b_write) = @_;

  # Try a socketpair().
  if ($type eq "socketpair") {
    eval {
      socketpair($$a_read, $$b_read, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair 1 failed: $!";
    };

    # Socketpair failed.
    if (length $@) {
      warn "socketpair failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using UNIX domain socketpairs";
      warn "ar($$a_read) aw($$a_write) br($$b_read) bw($$b_write)\n";
    };

    # It's two-way, so each reader is also a writer.
    $$a_write = $$a_read;
    $$b_write = $$b_read;

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$a_write), $| = 1)[0]);
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # Try a couple pipe() calls.
  if ($type eq "pipe") {
    eval {
      pipe($$a_read, $$b_write) or die "pipe 1 failed: $!";
      pipe($$b_read, $$a_write) or die "pipe 2 failed: $!";
    };

    # Pipe failed.
    if (length $@) {
      warn "pipe failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a pipe";
      warn "ar($$a_read) aw($$a_write) br($$b_read) bw($$b_write)\n";
    };

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$a_write), $| = 1)[0]);
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # Try a pair of plain INET sockets.
  if ($type eq "inet") {
    eval {
      ($$a_read, $$b_read) = _make_socket();
    };

    # Sockets failed.
    if (length $@) {
      warn "make_socket failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a plain INET socket";
      warn "ar($$a_read) aw($$a_write) br($$b_read) bw($$b_write)\n";
    };

    $$a_write = $$a_read;
    $$b_write = $$b_read;

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$a_write), $| = 1)[0]);
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  $debug and warn "unknown pipely(2) socket type ``$type''";
  return;
}

1;

__END__

=head1 NAME

IO::Pipely - Portably create pipe() or pipe-like handles, one way or another.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

Please read DESCRIPTION for detailed semantics and caveats.

  use IO::Pipely qw(pipely socketpairly);

  # Create a one-directional pipe() or pipe-like thing
  # the best conduit type available.

  my ($read, $write) = pipely();

  # Create a one-directional pipe-like thing using an
  # INET socket specifically.  Other types are available.

  my ($read, $write) = pipely(type => 'inet');

  # Create a bidirectional pipe-like thing using
  # the best conduit type available.

  my (
    $side_a_read,  $side_b_read,
    $side_a_write, $side_b_write,
  ) = socketpairly();

  # Create a bidirectional pipe-like thing using an INET socket
  # specifically.

  my (
    $side_a_read,  $side_b_read,
    $side_a_write, $side_b_write,
  ) = socketpairly(type => 'inet');

=head1 DESCRIPTION

Pipes are troublesome beasts because there are a few different,
incompatible ways to create them.  Not all platforms support all ways,
and some platforms may have hidden difficulties like incomplete or
buggy support.

IO::Pipely provides a couple functions to portably create one- and
two-way pipes and pipe-like socket pairs.  It acknowledges and works
around known platform issues so you don't have to.

On the other hand, it doesn't work around unknown issues, so please
report any problems early and often.

IO::Pipely currently understands pipe(), UNIX-domain socketpair() and
regular IPv4 localhost sockets.  This covers every platform tested so
far, but it's hardly complete.  Please help support other mechanisms,
such as INET-domain socketpair() and IPv6 localhost sockets.

IO::Pipely will use different kinds of pipes or sockets depending on
the operating system's capabilities and the number of directions
requested.  The autodetection may be overridden by specifying a
particular pipe type.

=head2 pipely

pipely() creates a one-directional pipe() or socket.  It's modeled
after Perl's built-in pipe() function, but it creates and returns
handles rather than opening ones given to it.

On success, pipely() returns two file handles, the first to read from
the pipe, and the second writes into the pipe.  It returns nothing on
failure.

  use IO::Pipely qw(pipely);
  my ($a_read, $b_write) = pipely();
  die "pipely() failed: $!" unless $a_read;

When given a choice, it will prefer to use leaner pipe() calls instead
of socketpair() and socket().

pipely()'s choice can be forced using an optional named "type"
parameter.  See L</PIPE TYPES> for the types that can be used.

  my ($a_read, $b_write) = pipely(
    type => 'pipe',
  );

On most systems, pipely() will prefer to open a pipe() first.  It will
fall back to a UNIX socketpair() or two localhost Internet sockets, in
that order.

On Windows (ActiveState and Strawberry Perl), pipely() prefers two
localhost Internet sockets.  It will fall back to socketpair() and
pipe(), both of which will probably fail.

Cygwin Perl prefers pipe() first, localhost Internet sockets, and then
socketpair().  socketpair() has been known to have problems on Cygwin.

MacPerl (MacOS 9 and earlier) has similar capaibilities to Windows.

=head2 socketpairly

socketpairly() creates a two-directional socket pair.  It's modeled
after Perl's built-in socketpair(), but it creates and returns handles
rather than opening ones given to it.

On success, socketpairly() returns four file handles, read and write
for one end, and read and write for the other.  On failure, it returns
nothing.

  use IO::Pipely qw(socketpairly);
  my ($a_read, $b_read, $a_write, $b_write) = socketpairly();
  die "socketpairly() failed: $!" unless $a_read;

socketpairly() returns two extra "writer" handles.  They exist for the
fallback case where two pipe() calls are needed instead of one socket
pair.  The extra handles can be ignored whenever pipe() will never be
used.  For example:

  use IO::Pipely qw(socketpairly);
  my ($side_a, $side_b) = socketpairly( type => 'socketpair' );
  die "socketpairly() failed: $!" unless $side_a;

When given a choice, it will prefer bidirectional sockets instead of
pipe() calls.

socketpairly()'s choice can be forced using an optional named "type"
parameter.  See L</PIPE TYPES> for the types that can be used.  In
this example, two unidirectional pipes wil be used instead of a more
efficient pair of sockets:

  my ($a_read, $a_write, $b_read, $b_write) = pipely(
    type => 'pipe',
  );

On most systems, socketpairly() will try to open a UNIX socketpair()
first.  It will then fall back to a pair of localhost Internet
sockets, and finally it will try a pair of pipe() calls.

On Windows (ActiveState and Strawberry Perl), socketpairly() prefers a
pair of localhost Internet sockets first.  It will then fall back to a
UNIX socketpair(), and finally a couple of pipe() calls.  The fallback
options will probably fail, but the code remains hopeful.

Cygwin Perl prefers localhost Internet sockets first, followed by a
pair of pipe() calls, and finally a UNIX socketpair().  Those who know
may find this counter-intuitive, but it works around known issues in
some versions of Cygwin socketpair().

MacPerl (MacOS 9 and earlier) has similar capaibilities to Windows.

=head2 PIPE TYPES

IO::Pipely currently supports three types of pipe and socket.  Other
types are possible, but these three cover all known uses so far.
Please ask (or send patches) if additional types are needed.

=head3 pipe

Attempt to establish a one-way pipe using one pipe() filehandle pair
(2 file descriptors), or a two-way pipe-like connection using two
pipe() pairs (4 file descriptors).

IO::Pipely prefers to use pipe() for one-way pipes and some form of
socket pair for two-way pipelike things.

=head3 socketpair

Attempt to establish a one- or two-way pipelike connection using a
single socketpair() call.  This uses two file descriptors regardless
whether the connection is one- or two-way.

IO::Pipely prefers socketpair() for two-way connections, unless the
current platform has known issues with the socketpair() call.

Socket pairs are UNIX domain only for now.  INET domain may be added
if it improves compatibility on some platform, or if someone
contributes the code.

=head3 inet

Attempt to establish a one- or two-way pipelike connection using
localhost socket() calls.  This uses two file descriptors regardless
whether the connection is one- or two-way.

Localhost INET domain sockets are a last resort for platforms that
don't support something better.  They are the least secure method of
communication since tools like tcpdump and Wireshark can tap into
them.  On the other hand, this makes them easiest to debug.

=head1 KNOWN ISSUES

These are issues known to the developers at the time of this writing.
Things change, so check back now and then.

=head2 Cygwin

CygWin seems to have a problem with socketpair() and exec().  When
an exec'd process closes, any data on sockets created with
socketpair() is not flushed.  From irc.perl.org channel #poe:

  <dngnand>   Sounds like a lapse in cygwin's exec implementation.
              It works ok under Unix-ish systems?
  <jdeluise2> yes, it works perfectly
  <jdeluise2> but, if we just use POE::Pipe::TwoWay->new("pipe")
              it always works fine on cygwin
  <jdeluise2> by the way, it looks like the reason is that
              POE::Pipe::OneWay works because it tries to make a
              pipe first instead of a socketpair
  <jdeluise2> this socketpair problem seems like a long-standing
              one with cygwin, according to searches on google,
              but never been fixed.

=head2 MacOS 9

IO::Pipely supports MacOS 9 for historical reasons.
It's unclear whether anyone still uses MacPerl, but the support is
cheap since pipes and sockets there have many of the same caveats as
they do on Windows.

=head2 Symbol::gensym

IO::Pipely uses Symbol::gensym() instead of autovivifying file
handles.  The main reasons against gensym() have been stylistic ones
so far.  Meanwhile, gensym() is compatible farther back than handle
autovivification.

=head2 Windows

ActiveState and Strawberry Perl don't support pipe() or UNIX
socketpair().  Localhost Internet sockets are used for everything
there, including one-way pipes.

For one-way pipes, the unused socket directions are shut down to avoid
sending data the wrong way through them.  Use socketpairly() instead.

=head1 BUGS

The functions implemented here die outright upon failure, requiring
eval{} around their calls.

The following conduit types are currently unsupported because nobody
has needed them so far.  Please submit a request (and/or a patch) if
any of these is needed:

  UNIX socket()
  INET-domain socketpair()
  IPv4-specific localhost sockets
  IPv6-specific localhost sockets

=head1 AUTHOR & COPYRIGHT

IO::Pipely is copyright 2000-2013 by Rocco Caputo.
All rights reserved.
IO::Pipely is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 HISTORY

IO::Pipely is a spin-off of the L<POE> project's portable pipes.
Earlier versions of the code have been tested and used in production
systems for over a decade.

=cut

# rocco // vim: ts=2 sw=2 expandtab
