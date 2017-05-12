package IO::Socket::CLI;
$IO::Socket::CLI::VERSION = '0.041';
use 5.006;
use strict;
use warnings;
use IO::Socket::SSL;
use IO::Socket::INET6;
use Carp;

# defaults
my $DEBUG = 0;			# boolean?
my $DELAY = 10;			# number of milliseconds between each attempt at reading the response from the server.
my $TIMEOUT = 5;		# number of seconds to wait for a response from server before returning an empty list.
my $PRINT_RESPONSE = 1;		# boolean
my $PREPEND = 1;		# boolean
our $SSL = 0;			# boolean
my $HOST = '127.0.0.1';		# IP or domain
our $PORT = '143';		# port
our $BYE = qr'^\* BYE( |\r?$)';	# string server sends when it hangs up.

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    my $args = (ref($_[0]) eq 'HASH') ? $_[0] : {@_};

    $self->{_HOST} = ($args->{HOST}) ? $args->{HOST} : $HOST;
    $self->{_PORT} = ($args->{PORT}) ? $args->{PORT} : $PORT;
    $self->{_BYE} = ($args->{BYE}) ? $args->{BYE} : $BYE;
    $self->{_DELAY} = ($args->{DELAY}) ? $args->{DELAY} : $DELAY;
    $self->{_TIMEOUT} = ($args->{TIMEOUT}) ? $args->{TIMEOUT} : $TIMEOUT;
    $self->{_PRINT_RESPONSE} = (defined $args->{PRINT_RESPONSE}) ? $args->{PRINT_RESPONSE} : $PRINT_RESPONSE;
    $self->{_PREPEND} = (defined $args->{PREPEND}) ? $args->{PREPEND} : $PREPEND;
    $self->{_DEBUG} = (defined $args->{DEBUG}) ? $args->{DEBUG} : $DEBUG;
    $self->{_SSL} = (defined $args->{SSL}) ? $args->{SSL} : $SSL;
    $self->{_SOCKET} = IO::Socket::INET6->new(PeerAddr => $self->{_HOST},
                                              PeerPort => $self->{_PORT},
                                              Blocking => 0) ||
            die "Can't bind : $@\n";

    ($self->{_SSL}) and IO::Socket::SSL->start_SSL($self->{_SOCKET});
    $self->{_OPEN} = ($self->{_SOCKET}->connected()) ? 1 : 0;
    $self->{_COMMAND} = '';
    $self->{_SERVER_RESPONSE} = [];

    bless ($self, $class);
    return $self;
}

sub read {
    my $self = shift;
    my $i = 0;
    my $max_i = $self->{_TIMEOUT} / ($self->{_DELAY} / 1000);

    do {
        select(undef, undef, undef, $self->{_DELAY} / 1000);
        @{$self->{_SERVER_RESPONSE}} = $self->{_SOCKET}->getlines;
        $i++;
    } while (!@{$self->{_SERVER_RESPONSE}} && $i < $max_i);

    if ($DEBUG || $self->{_DEBUG}) {
        print STDOUT "D: response took roughly " . ($i * $self->{_DELAY}) . " milliseconds\n";
    }

    $self->print_resp() if ($self->{_PRINT_RESPONSE});

    return  @{$self->{_SERVER_RESPONSE}};
}

sub response {
    my $self = shift;
    return @{$self->{_SERVER_RESPONSE}};
}

sub print_resp {
    my $self = shift;
    foreach (@{$self->{_SERVER_RESPONSE}}) {
        print STDOUT "" . (($self->{_PREPEND}) ? "S: " : "") . "$_";
    }
}

sub is_open {
    my $self = shift;
    my $bye = $self->{_BYE};
    $self->{_OPEN} = ($self->{_SOCKET}->connected()) ? 1 : 0;
    foreach (@{$self->{_SERVER_RESPONSE}}) {
        $self->{_OPEN} = 0 if (/$bye/);
        last;
    }
    return $self->{_OPEN};
}

sub send($) {
    my $self = shift;
    chomp (my $command = shift);
    $self->{_COMMAND} = $command;
    print STDOUT "" . ($self->{_PREPEND} ? "C: " : "") . "$command\r\n" if ($self->{_PRINT_RESPONSE});
    $self->{_SOCKET}->syswrite("$command\r\n");
}

sub prompt {
    my $self = shift;
    print STDOUT "C: " if ($self->{_PREPEND}); # client prompt
    chomp(my $command = <STDIN>);
    $self->{_COMMAND} = $command;
    $self->{_SOCKET}->syswrite("$command\r\n");
}

sub command() {
    my $self = shift;
    return $self->{_COMMAND};
}

sub print_response {
    my $self = shift;
    if (@_) {
        my $boolean = shift;
        if ($boolean and $boolean != 1) {
            carp "warning: valid settings for print_response() are 0 or 1 -- setting to $PRINT_RESPONSE";
            $boolean = $PRINT_RESPONSE;
        }
        $self->{_PRINT_RESPONSE} = $boolean;
    }
    return $self->{_PRINT_RESPONSE};
}

sub prepend {
    my $self = shift;
    if (@_) {
        my $boolean = shift;
        if ($boolean and $boolean != 1) {
            carp "warning: valid settings for prepend() are 0 or 1 -- setting to $PREPEND";
            $boolean = $PREPEND;
        }
        $self->{_PREPEND} = $boolean;
    }
    return $self->{_PREPEND};
}

sub timeout {
    my $self = shift;
    if (@_) {
        my $seconds = shift;
        if ($seconds < 0) {
            carp "warning: timeout() must be non-negative -- setting to $TIMEOUT";
            $seconds = $TIMEOUT;
        }
        $self->{_TIMEOUT} = $seconds;
    }
    return $self->{_TIMEOUT};
}

sub delay {
    my $self = shift;
    if (@_) {
        my $milliseconds = shift;
        if ($milliseconds < 1) {
            carp "warning: delay() must be positive -- setting to $DELAY";
            $milliseconds = $DELAY;
        }
        $self->{_DELAY} = $milliseconds;
    }
    return $self->{_DELAY};
}

sub bye {
    my $self = shift;
    if (@_) {
        my $bye = shift;
        unless ($bye =~ /\(\?(?:-xism|\^):.*\)/) {
            carp "warning: bye() must be a regexp-like quote: qr/STRING/ -- setting to '$BYE' instead of '$bye'";
            $bye = $BYE;
        }
        $self->{_BYE} = $bye;
    }
    return $self->{_BYE};
}

sub debug {
    my $self = shift;
    if (@_) {
        my $boolean = shift;
        if ($boolean and $boolean != 1) {
            carp "warning: valid settings for debug() are 0 or 1 -- setting to 1";
            $boolean = 1;
        }
        $self->{_DEBUG} = $boolean;
    }
    return $self->{_DEBUG};
}

#sub debug {
#    my $self = shift;
#    confess 'error: thing->debug($level)' unless @_ == 1;
#    my $level = shift;
#    if (ref($self)) {
#        $self->{_DEBUG} = $level; # just myself
#    } else {
#        $DEBUG = $level; # whole class
#    }
#}

sub socket {
    my $self = shift;
    return $self->{_SOCKET};
}

sub errstr {
    my $self = shift;
    if ($self->{_SSL}) {
        return $self->{_SOCKET}->errstr();
    } else {
        return undef;
    }
}

sub close {
    my $self = shift;
    return $self->{_SOCKET}->close();
    if ($self->{_SSL}) {
        return $self->{_SOCKET}->stop_SSL(SSL_ctx_free => 1);
    } else {
        return $self->{_SOCKET}->close();
    }
}

# object destructor
sub DESTROY {
    my $self = shift;
    if ($DEBUG || $self->{"_DEBUG"}) {
        carp "Destroying $self " . $self->{_HOST} . ":" . $self->{_PORT};
    }
    $self->close();
}

# class destructor
sub END {
    if ($DEBUG) {
        print STDOUT "class destroyed.\n";
    }
}

1;

__END__

=head1 NAME

IO::Socket::CLI - CLI for IO::Socket::INET6 and IO::Socket::SSL

=head1 VERSION

version 0.041

=head1 SYNOPSIS

  use IO::Socket::CLI;
  our @ISA = ("IO::Socket::CLI");

=head1 DESCRIPTION

C<IO::Socket::CLI> provides a command-line interface to L<IO::Socket::INET6> and
L<IO::Socket::SSL>.

=for comment
=head1 EXPORT
None by default.

=head1 METHODS

=over 2

=item new(...)

Creates a new IO::Socket::CLI object, returning its reference. Has the following options:

=over 2

=item HOST

Hostname or IP address. Default is C<'127.0.0.1'>.

=item PORT

Port of the service. Default is C<'143'>.

=item SSL

Boolean value for if an SSL connection. Default is C<0>.

=item BYE

String server sends when it hangs up. Default is C<qr'^\* BYE( |\r?$)'>.

=item TIMEOUT

Timeout in seconds for reading from the socket before returning an empty list. Default is C<5>.

=item DELAY

Delay in milliseconds between read attempts if nothing is returned. Default is C<10>.

=item PRINT_RESPONSE

Boolean value for if to automatically print the server response on L</read()>. Default is C<1>.

=item PREPEND

Boolean value for if to pretend client commands and server responses with C<"C: "> and C<"S: ">, respectively. Default is C<1>.

=item DEBUG

Boolean value for if to give verbose debugging info. Default is C<0>.

=back

=item read()

Reads the response from the server, returning it as a list. Tries every
C<DELAY> milliseconds until C<TIMEOUT> seconds. Optionally prints the
response to C<STDOUT> if C<PRINT_RESPONSE>.

=item response()

Returns the last stored response from the server as a list.

=item print_resp()

Prints each line of server response to C<STDOUT>, optionally prepending with C<"S: "> if C<PREPEND>.

=item is_open()

Returns if the server hung up according to the last server response.

=item send($command)

Sends C<$command> to the server. Optionally echoes C<$command> if C<PRINT_RESPONSE>.

=item prompt()

Reads command from C<STDIN> and sends it to the server.

=item command()

Returns last command sent.

=item print_response(), print_response($boolean)

Optionally turns C<PRINT_RESPONSE> on/off. Returns value.

=item prepend(), prepend($boolean)

Optionally turns C<PREPEND> on/off. Returns value.

=item timeout(), timeout($seconds)

Optionally sets C<TIMEOUT> in seconds. Must be non-negative. Returns value.

=item delay(), delay($milliseconds)

Optionally sets C<DELAY> in milliseconds. Must be positive. Returns value.

=item bye(), bye($bye)

Optionally sets C<BYE>. Must be a regexp-like quote: C<qr/STRING/>. Returns value.

=item debug(), debug($boolean)

Optionally turns debugging info/verbosity on/off. Returns value.

=item socket()

Returns the underlying socket.

=item errstr()

Returns C<errstr()> from the socket. Only for SSL - returns C<undef> otherwise.

=item close()

Closes the socket. Returns true on success. This method needs to be overridden for SSL connections.

=back

=head1 BUGS

Does not verify SSL connections. Has not been tried with STARTTLS.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<IO::Socket::INET6>

L<IO::Socket::INET>

L<IO::Socket::SSL>

L<IO::Socket>
