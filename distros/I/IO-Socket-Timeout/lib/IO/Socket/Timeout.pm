#
# This file is part of IO-Socket-Timeout
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package IO::Socket::Timeout;
$IO::Socket::Timeout::VERSION = '0.32';
use strict;
use warnings;
use Config;
use Carp;


# ABSTRACT: IO::Socket with read/write timeout


sub import {
    shift;
    foreach (@_) {
        _create_composed_class( $_, 'IO::Socket::Timeout::Role::SetSockOpt');
        _create_composed_class( $_, 'IO::Socket::Timeout::Role::PerlIO');
    }
}


sub enable_timeouts_on {
    my ($class, $socket) = @_;
    defined $socket
      or return;
    $socket->isa('IO::Socket')
      or croak 'make_timeouts_aware can be used only on instances that inherit from IO::Socket';

    my $osname = $Config{osname};
    if ( ! $ENV{PERL_IO_SOCKET_TIMEOUT_FORCE_SELECT}
         && ( $osname eq 'darwin' || $osname eq 'linux' || $osname eq 'freebsd' ) ) {
        _compose_roles($socket, 'IO::Socket::Timeout::Role::SetSockOpt');
    } else {
        require PerlIO::via::Timeout;
        binmode($socket, ':via(Timeout)');
        _compose_roles($socket, 'IO::Socket::Timeout::Role::PerlIO');
    }

    $socket->enable_timeout;
    return $socket;
}

sub _create_composed_class {
    my ($class, @roles) = @_;
    my $composed_class = $class . '__with__' . join('__and__', @roles);
    my $path = $composed_class; $path =~ s|::|/|g; $path .= '.pm';
    if ( ! exists $INC{$path}) {
        no strict 'refs';
        *{"${composed_class}::ISA"} = [ $class, @roles ];
        $INC{$path} = __FILE__;
    }
    return $composed_class;
}

sub _compose_roles {
    my ($instance, @roles) = @_;
    bless $instance, _create_composed_class(ref $instance, @roles);
}

# sysread FILEHANDLE,SCALAR,LENGTH,OFFSET
BEGIN {
    my $osname = $Config{osname};
    if ( $ENV{PERL_IO_SOCKET_TIMEOUT_FORCE_SELECT} ||
         $osname ne 'darwin' && $osname ne 'linux' && $osname ne 'freebsd'
       ) {
        # this variable avoids infinite recursion, because
        # PerlIO::via::Timeout->READ calls sysread.
        my $_prevent_deep_recursion;
        *CORE::GLOBAL::sysread = sub {
            my $args_count = scalar(@_);
               $_prevent_deep_recursion
            || ! PerlIO::via::Timeout::has_timeout_layer($_[0])
            || ! PerlIO::via::Timeout::timeout_enabled($_[0])
              and return (  $args_count == 4 ? CORE::sysread($_[0], $_[1], $_[2], $_[3])
                          :                    CORE::sysread($_[0], $_[1], $_[2])
                         );
            $_prevent_deep_recursion = 1;
            my $ret_val = PerlIO::via::Timeout->READ($_[1], $_[2], $_[0]);
            $_prevent_deep_recursion = 0;
            return $ret_val;
        }
    }
}

# syswrite FILEHANDLE,SCALAR,LENGTH,OFFSET
BEGIN {
    my $osname = $Config{osname};
    if ( $ENV{PERL_IO_SOCKET_TIMEOUT_FORCE_SELECT} ||
         $osname ne 'darwin' && $osname ne 'linux' && $osname ne 'freebsd'
       ) {
        # this variable avoids infinite recursion, because
        # PerlIO::via::Timeout->WRITE calls syswrite.
        my $_prevent_deep_recursion;
        *CORE::GLOBAL::syswrite = sub {
            my $args_count = scalar(@_);
               $_prevent_deep_recursion
            || ! PerlIO::via::Timeout::has_timeout_layer($_[0])
            || ! PerlIO::via::Timeout::timeout_enabled($_[0])
              and return(   $args_count == 4 ? CORE::syswrite($_[0], $_[1], $_[2], $_[3])
                          : $args_count == 3 ? CORE::syswrite($_[0], $_[1], $_[2])
                          :                    CORE::syswrite($_[0], $_[1])
                        );
            $_prevent_deep_recursion = 1;
            my $ret_val = PerlIO::via::Timeout->WRITE($_[1], $_[0]);
            $_prevent_deep_recursion = 0;
            return $ret_val;
        }
    }
}

package IO::Socket::Timeout::Role::SetSockOpt;
$IO::Socket::Timeout::Role::SetSockOpt::VERSION = '0.32';
use Carp;
use Socket;

sub _check_attributes {
    my ($self) = @_;
    grep { $_ < 0 } grep { defined } map { ${*$self}{$_} } qw(ReadTimeout WriteTimeout)
      and croak "if defined, 'ReadTimeout' and 'WriteTimeout' attributes should be >= 0";
}

sub read_timeout {
    my ($self) = @_;
    @_ > 1 and ${*$self}{ReadTimeout} = $_[1], $self->_check_attributes, $self->_set_sock_opt;
    ${*$self}{ReadTimeout}
}

sub write_timeout {
    my ($self) = @_;
    @_ > 1 and ${*$self}{WriteTimeout} = $_[1], $self->_check_attributes, $self->_set_sock_opt;
    ${*$self}{WriteTimeout}
}

sub enable_timeout { $_[0]->timeout_enabled(1) }
sub disable_timeout { $_[0]->timeout_enabled(0) }
sub timeout_enabled {
    my ($self) = @_;
    @_ > 1 and ${*$self}{TimeoutEnabled} = !!$_[1], $self->_set_sock_opt;
    ${*$self}{TimeoutEnabled}
}

sub _set_sock_opt {
    my ($self) = @_;
    my $read_seconds;
    my $read_useconds;
    my $write_seconds;
    my $write_useconds;
    if (${*$self}{TimeoutEnabled}) {
        my $read_timeout = ${*$self}{ReadTimeout} || 0;
        $read_seconds  = int( $read_timeout );
        $read_useconds = int( 1_000_000 * ( $read_timeout - $read_seconds ));
        my $write_timeout = ${*$self}{WriteTimeout} || 0;
        $write_seconds  = int( $write_timeout );
        $write_useconds = int( 1_000_000 * ( $write_timeout - $write_seconds ));
    } else {
        $read_seconds  = 0; $read_useconds  = 0;
        $write_seconds = 0; $write_useconds = 0;
    }
    my $read_struct  = pack( 'l!l!', $read_seconds, $read_useconds );
    my $write_struct = pack( 'l!l!', $write_seconds, $write_useconds );

    $self->setsockopt( SOL_SOCKET, SO_RCVTIMEO, $read_struct )
      or croak "setsockopt(SO_RCVTIMEO): $!";

    $self->setsockopt( SOL_SOCKET, SO_SNDTIMEO, $write_struct )
      or croak "setsockopt(SO_SNDTIMEO): $!";
}

package IO::Socket::Timeout::Role::PerlIO;
$IO::Socket::Timeout::Role::PerlIO::VERSION = '0.32';
use PerlIO::via::Timeout;

sub read_timeout    { goto &PerlIO::via::Timeout::read_timeout    }
sub write_timeout   { goto &PerlIO::via::Timeout::write_timeout   }
sub enable_timeout  { goto &PerlIO::via::Timeout::enable_timeout  }
sub disable_timeout { goto &PerlIO::via::Timeout::disable_timeout }
sub timeout_enabled { goto &PerlIO::via::Timeout::timeout_enabled }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Socket::Timeout - IO::Socket with read/write timeout

=head1 VERSION

version 0.32

=head1 SYNOPSIS

  use IO::Socket::Timeout;

  # creates a standard IO::Socket::INET object, with a connection timeout
  my $socket = IO::Socket::INET->new( Timeout => 2 );
  # enable read and write timeouts on the socket
  IO::Socket::Timeout->enable_timeouts_on($socket);
  # setup the timeouts
  $socket->read_timeout(0.5);
  $socket->write_timeout(0.5);

  # When using the socket:
  use Errno qw(ETIMEDOUT EWOULDBLOCK);
  print $socket "some request";
  my $response = <$socket>;
  if (! $response && ( 0+$! == ETIMEDOUT || 0+$! == EWOULDBLOCK )) {
    die "timeout reading on the socket";
  }

=head1 DESCRIPTION

C<IO::Socket> provides a way to set a timeout on the socket, but the timeout
will be used only for connection, not for reading / writing operations.

This module provides a way to set a timeout on read / write operations on an
C<IO::Socket> instance, or any C<IO::Socket::*> modules, like
C<IO::Socket::INET>.

=head1 CLASS METHOD

=head2 enable_timeouts_on

  IO::Socket::Timeout->enable_timeouts_on($socket);

Given a socket, it'll return it, but will enable read and write timeouts on it.
You'll have to use C<read_timeout> and C<write_timeout> on it later on.

Returns the socket, so that you can chain this method with others.

If the argument is C<undef>, the method simply returns empty list.

=head1 METHODS

These methods are to be called on a socket that has been previously passed to
C<enable_timeouts_on()>.

=head2 read_timeout

  my $current_timeout = $socket->read_timeout();
  $socket->read_timeout($new_timeout);

Get or set the read timeout value for a socket created with this module.

=head2 write_timeout

  my $current_timeout = $socket->write_timeout();
  $socket->write_timeout($new_timeout);

Get or set the write timeout value for a socket created with this module.

=head2 disable_timeout

  $socket->disable_timeout;

Disable the read and write timeouts for a socket created with this module.

=head2 enable_timeout

  $socket->enable_timeout;

Re-enable the read and write timeouts for a socket created with this module.

=head2 timeout_enabled

  my $is_timeout_enabled = $socket->timeout_enabled();
  $socket->timeout_enabled(0);

Get or Set the fact that a socket has timeouts enabled.

=head1 WHEN TIMEOUT IS HIT

When a timeout (read, write) is hit on the socket, the function trying to be
performed will return C<undef> or empty string, and C<$!> will be set to
C<ETIMEOUT> or C<EWOULDBLOCK>. You should test for both.

You can import C<ETIMEOUT> and C<EWOULDBLOCK> by using C<POSIX>:

  use Errno qw(ETIMEDOUT EWOULDBLOCK);

=head1 IF YOU NEED TO RETRY

If you want to implement a try / wait / retry mechanism, I recommend using a
third-party module, like C<Action::Retry>. Something like this:

  my $socket;

  my $action = Action::Retry->new(
    attempt_code => sub {
        # (re-)create the socket if needed
        if (! $socket) {
          $socket = IO::Socket->new(...);
          IO::Socket::Timeout->enable_timeouts_on($socket);
          $socket->read_timeout(0.5);
        }
        # send the request, read the answer
        $socket->print($_[0]);
        defined(my $answer = $socket->getline)
          or $socket = undef, die $!;
        $answer;
    },
    on_failure_code => sub { die 'aborting, to many retries' },
  );

  my $reply = $action->run('GET mykey');

=head1 IMPORT options

You can give a list of socket modules names when use-ing this module, so that
internally, composed classes needed gets created and loaded at compile time.

  use IO::Socket::Timeout qw(IO::Socket::INET);

=head1 ENVIRONMENT VARIABLE

=head2 PERL_IO_SOCKET_TIMEOUT_FORCE_SELECT

This module implements timeouts using one of two strategies. If possible (if
the operating system is linux, freebsd or mac), it uses C<setsockopt()> to set
read / write timeouts. Otherwise it uses C<select()> before performing socket
operations.

To force the use of C<select()>, you can set
PERL_IO_SOCKET_TIMEOUT_FORCE_SELECT to a true value at compile time (typically
in a BEGIN block)

=head1 SEE ALSO

L<Action::Retry>, L<IO::Select>, L<PerlIO::via::Timeout>, L<Time::Out>

=head1 THANKS

Thanks to Vincent Pitt, Christian Hansen and Toby Inkster for various help and
useful remarks.

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
