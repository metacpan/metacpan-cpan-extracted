package IO::Lambda::HTTP::Server;
use vars qw(@ISA @EXPORT_OK $DEBUG);
@EXPORT = qw(http_server);
use base qw(Exporter IO::Lambda);

our $DEBUG = $IO::Lambda::DEBUG{httpd} || 0;

use strict;
use warnings;
use Socket;
use Exporter;
use IO::Socket::INET;
use HTTP::Request;
use HTTP::Response;
use IO::Lambda qw(:lambda :stream);
use IO::Lambda::Socket qw(accept);
use Time::HiRes qw(time);

my $CRLF = "\x0d\x0a";

sub _close($$)
{
	warn "$_[1]\n" if $DEBUG;
	close($_[0]);
}

sub _msg
{
	my ( $status, $msg, $close) = @_;
	my $resp = "HTTP/1.1 $status${CRLF}Content-Length: ".length($msg)."$CRLF";
	$resp .= "Connection: ".($close ? 'close' : 'keep-alive')."$CRLF";
	$resp .= "Date: ". scalar(localtime).$CRLF;
	$resp .= "Content-Type: text/plain$CRLF" if length($msg);
	$resp .= $CRLF . $msg;
	return $resp;
}

sub _bye
{
	my ( $self, $conn, $close, $msg) = @_;
	tail {
		my $resp = _msg( $msg, '', $close);
		context writebuf, $conn, \$resp, length($resp), 0, $self->{timeout};
	tail {
		if ( $close ) {
			warn "[$self->{sessions}->{$conn}->{remote}] disconnect\n" if $DEBUG;
			if ( !close($conn)) {
				warn "close error:$!\n" if $DEBUG;
			}
		}
	}}
}

sub _bad_request
{
	my ( $self, $conn, $close) = @_;
	$self->_bye( $conn, $close, "400 Bad Request");
}

sub _timeout
{
	my ( $self, $conn) = @_;
	$self->_bye($conn, 1, "408 Timeout");
}

sub handle_connection
{
	my ($self, $conn, $cb) = @_;
	my %session;
	my $session_data = $self->{sessions}->{"$conn"};
	my $buf = '';
	lambda {
		$session_data->{active} = 0;
		context readbuf, $conn, \$buf, 1, $self->{timeout};
	tail {
		$session_data->{active} = 1;
		context readbuf, $conn, \$buf, qr/^.*?\x{0D}?\x{0A}\x{0D}?\x{0A}/s, $self->{timeout};
	tail {
		my ( $match, $error) = @_;
		return $self->_timeout($conn) if defined($error) and $error eq 'timeout';
		return _close $conn, $error unless defined $match;
		warn length($buf), " bytes read\n" if $DEBUG > 1;

		my $req = HTTP::Request-> parse( $match);
		return $self->_bad_request($conn, 1) unless $req;

		my $proto = (( $req->protocol // '') =~ /^HTTP\/([\d\.]+)$/i) ? $1 : 1.0;
		my $keep_alive =
			$proto >= 1.1 &&
			(lc( $req->header('Connection') // 'keep-alive') eq 'keep-alive');
		$keep_alive = 0 if $self->{shutdown};

		my $cl = length($match) + ($req->header('Content-Length') // 0);
		context readbuf, $conn, \$buf, $cl, $self->{timeout};
	tail {
		my ( undef, $error) = @_;
		return $self->_timeout($conn) if defined($error) and $error eq 'timeout';
		return _close $conn, $error if defined $error;

		warn length($buf), " bytes read\n" if $DEBUG > 1;
		unless ($req = HTTP::Request-> parse( $buf)) {
			return lambda {
				context $self->_bad_request($conn, !$keep_alive);
			tail {
				this->start if $keep_alive && !($self->{shutdown} && !length($buf)); 
			}};
		}
		substr( $buf, 0, $cl, '');

		my $resp;
		eval { ($resp, $error) = $cb->($req, \%session); };
		context UNIVERSAL::isa( $resp, 'IO::Lambda') ?
			$resp : lambda { $resp, $error };
	tail {
		my $error;
		($resp, $error) = @_;
		$keep_alive = 0 if $self->{shutdown};
		if ( $error ) {
			$resp = _msg("500 Server Error", $error, !$keep_alive);
		} elsif ( UNIVERSAL::isa( $resp, 'HTTP::Response')) {
			$resp->header(Connection => ($keep_alive ? 'keep-alive' : 'close'));
			$resp = "HTTP/1.1 " . $resp->as_string($CRLF);
		} else {
			$resp = _msg("200 OK", $resp // '', !$keep_alive);
		}
		context writebuf, $conn, \$resp, length($resp), 0, $self->{timeout};
	tail {
		my ( undef, $error) = @_;
		return _close $conn, $error if defined $error;
		warn length($resp), " bytes written\n" if $DEBUG > 1;
		return this->start if $keep_alive && !($self->{shutdown} && !length($buf));

		warn "[$session_data->{remote}] disconnect\n" if $DEBUG;
		if ( !close($conn)) {
			warn "error during response:$!\n" if $DEBUG;
		}
	}}}}}}
}

sub http_server(&$;@)
{
	my ( $cb, $listen, %opt) = @_;
	
	my $port = 80;
	unless ( ref $listen ) {
		($listen, $port) = ($1, $2) if $listen =~ /^(.*)\:(\d+)$/;
		$listen = IO::Socket::INET->new(
			Listen => 5,
			LocalAddr => $listen,
			LocalPort => $port,
			Proto     => 'tcp',
			ReuseAddr => 1,
		);
		unless ( $listen ) {
			warn "$!\n" if $DEBUG;
			return (undef, $!);
		}
	} else {
		$port = $listen->sockport;
	}
	return __PACKAGE__->new(
		socket   => $listen,
		port     => $port,
		callback => $cb,
		%opt
	);
}

sub new
{
	my ( $class, %opt ) = @_;

	my $cb     = delete $opt{callback};

	my $self;
	$self = lambda {
		context $self->{socket};
	$self->{accept_event} = accept {
		return if $self->{shutdown};

		my $conn = shift;
		$self->{accept_event} = again;

		unless ( ref($conn)) {
			warn "accept() error:$conn\n" if $DEBUG;
			return;
		}
		$conn-> blocking(0);
		my $sess = $self->{sessions}->{"$conn"} = {
			active  => 0,
		};
		$sess->{remote} = inet_ntoa((sockaddr_in(getsockname($conn)))[1]);
		warn "[$sess->{remote}] connect\n" if $DEBUG;

		$sess->{handler}  = handle_connection($self, $conn, $cb);
		context $sess->{handler};
	tail {
		delete $self->{sessions}->{"$conn"};
	}}};
	bless $self, $class;
	$self->{$_} = $opt{$_} for qw(socket port timeout);
	$self->{sessions} = {};
	$self->{shutdown} = 0;
	return $self;
}

sub shutdown
{
	my $self = shift;
	$self->{shutdown} = 1;
	$self->cancel_event($self->{accept_event});
	$_->{handler}->terminate for grep { !$_->{active}} values %{ $self->{sessions}};
}

1;

=head1 NAME

IO::Lambda::HTTP::Server - simple httpd server

=head1 DESCRIPTION

The module exports a single function C<http_server> that accepts a callback
and a socket, with optional parameters. The callback accepts a C<HTTP::Request>
object, and is expected to return either a C<HTTP::Response> object or a lambda
that in turn returns a a C<HTTP::Response> object.

=head1 SYNOPSIS

   use HTTP::Request;
   use IO::Lambda qw(:all);
   use IO::Lambda::HTTP qw(http_request);
   use IO::Lambda::HTTP::Server;

   my $server = http_server {
        my $req = shift;
	if ( $req->uri =~ /weather/) {
                context( HTTP::Request-> new( GET => "http://www.google.com/?q=weather"));
		return &http_request;
	} else {
   		return HTTP::Response->new(200, 'OK', ['Content-Type' => 'text/plain'], "hello world");
	}
   } "localhost:80"; 
   $server->start; # runs in 'background' now

=head1 API

=over
 
=item http_server &callback, $socket, [ %options ]

Creates lambda that listens on C<$socket>, that is either a C<IO::Socket::INET> object
or a string such as C<"localhost"> or C<"127.0.0.1:9999">. 

The callback accepts a C<HTTP::Request> object, and is expected to return
either a C<HTTP::Response> object or a lambda that in turn returns a a
C<HTTP::Response> object.

Options:

=over

=item timeout $integer

Connection timeout or a deadline.

=back

=item shutdown

Enter a graceful shutdown mode - stop accepting new connections, handle the
running ones, and stop after all connections are served.

=back

=head1 SEE ALSO

L<IO::Lambda>, L<HTTP::Request>, L<HTTP::Response>

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
