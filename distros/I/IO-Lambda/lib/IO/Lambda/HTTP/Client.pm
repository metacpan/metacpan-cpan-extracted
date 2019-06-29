package IO::Lambda::HTTP::Client;
use vars qw(@ISA @EXPORT_OK $DEBUG);
@ISA = qw(Exporter);
@EXPORT_OK = qw(http_request);

our $DEBUG = $IO::Lambda::DEBUG{http} || 0;

use strict;
use warnings;
use Socket;
use Exporter;
use IO::Socket;
use HTTP::Response;
use IO::Lambda qw(:lambda :stream);
use IO::Lambda::Socket qw(connect);
use Time::HiRes qw(time);

sub http_request(&) 
{
	__PACKAGE__-> new(context)-> 
		condition(shift, \&http_request, 'http_request')
}

sub new
{
	my ( $class, $req, %options) = @_;

	my $self = bless {}, $class;

	$self-> {deadline}     = $options{timeout} + time if defined $options{timeout};
	$self-> {deadline}     = $options{deadline}       if defined $options{deadline};
	$self-> {max_redirect} = defined($options{max_redirect}) ? $options{max_redirect} : 7;

	delete @options{qw(deadline timeout max_redirect)};
	$self-> {$_} = $options{$_} for keys %options;

	my %headers;
	$headers{'User-Agent'} = "perl/IO-Lambda-HTTP v$IO::Lambda::VERSION";

	if ( $self-> {keep_alive}) {
		unless ( $self-> {conn_cache}) {
			require LWP::ConnCache;
			$self-> {conn_cache} = LWP::ConnCache-> new;
		}
		unless ( $req-> protocol) {
			$req-> protocol('HTTP/1.1');
		}
		$headers{Host}         = $req-> uri-> host;
		$headers{Connection}   = 'Keep-Alive';
		$headers{'Keep-Alive'} = 300;
	}

	require IO::Lambda::DNS if $self-> {async_dns};
	
	my $h = $req-> headers;
	while ( my ($k, $v) = each %headers) {
		$h-> header($k, $v) unless defined $h-> header($k);
	}

	return $self-> handle_redirect( $req);
}

# HTTP::Response features methods base() and request() that we need to set as well
sub finalize_response
{
	my ( $self, $req, $response) = @_;
	$response-> request($req);
	return $response;
}

# reissue the request, if necessary, because of 30X or 401 errors
sub handle_redirect
{
	my ( $self, $req) = @_;
		
	my $was_redirected = 0;
	my $was_failed_auth = 0;

	my $auth = $self-> {auth};

	lambda {
		my $method;
		if ( $auth) {
			# create fake response for protocol initiation, -- but just once
			my $x = HTTP::Response-> new;
			$x-> headers-> header('WWW-Authenticate', split(',', $auth));
			$method = $self-> get_authenticator( $req, $x);
			undef $auth;
		}
		context $method || $self-> handle_connection( $req);
	tail   {
		# request is finished
		my $response = shift;
		return $response unless ref($response);

		if ( $response-> code =~ /^3/) {
			$was_failed_auth = 0;
			return 'too many redirects' 
				if ++$was_redirected > $self-> {max_redirect};

			my $location = $response-> header('Location');
			return $response unless defined $location;
			$req-> uri( URI-> new_abs( $location, $req-> uri));
			$req-> headers-> header( Host => $req-> uri-> host);

			warn "redirect to " . $req-> uri . "\n" if $DEBUG;

			this-> start; 
		} elsif ( 
			not($was_failed_auth) and 
			$response-> code eq '401' and
			defined($self-> {username}) and
			defined($self-> {password})
		) {
			$was_failed_auth++;
			$method = $self-> get_authenticator( $req, $response);
			context $method;
			return $method ? tail {
				my $r = shift;
				return $r unless $r;

				# start from beginning, from handle_connection;
				this-> start; 
			} : $self-> finalize_response($req, $response);
		} else {
			return $self-> finalize_response($req, $response);
		}
	}};
}

# if request needs authentication, and we can do something about it, create 
# a lambda that handles the authentication
sub get_authenticator
{
	my ( $self, $req, $response) = @_;

	# supports authentication?
	my %auth;
	for my $auth ( $response-> header('WWW-Authenticate')) {
		$auth =~ s/\s.*$//;
		$auth{$auth}++;
	}

	my %preferred = defined($self-> {preferred_auth}) ? (
		ref($self-> {preferred_auth}) ? 
			%{ $self-> {preferred_auth} } :
			( $self-> {preferred_auth} => 1 )
		) : ();
	
	my @auth = sort {
			($preferred{$b} || 0) <=> ($preferred{$a} || 0)
		} grep {
			not exists($preferred{$_}) or $preferred{$_} >= 0;
		} keys %auth;

	my $compilation_errors = '';
	for my $auth ( @auth) {
		if ( $auth eq 'Basic') {
			# always
			warn "trying basic authentication\n" if $DEBUG;
			$req-> authorization_basic( $self-> {username}, $self-> {password});
			return $self-> handle_connection( $req);
		}

		eval { require "IO/Lambda/HTTP/Authen/$auth.pm" };
		$compilation_errors .= "$@\n"
			if $@ and ($@ !~ m{^Can't locate IO/Lambda/HTTP/Authen/$auth});
		next if $@;
		
		my $lambda = "IO::Lambda::HTTP::Authen::$auth"-> 
			authenticate( $self, $req, $response);
		warn "trying authentication with '$auth'\n" if $DEBUG and $lambda;
		return $lambda if $lambda;
	}
	
	# XXX Propagate compilation errors as http errors. Doubtful.
	return lambda { $compilation_errors } if length $compilation_errors;

	return undef;
}


# get scheme and eventually load module
my $got_https;
sub prepare_transport
{
	my ( $self, $req) = @_;
	my $scheme = $req-> uri-> scheme;

	unless ( defined $scheme) {
		return "bad URI: " . $req-> uri-> as_string;
	} elsif ( $scheme eq 'https') {
		unless ( $got_https) {
			eval { require IO::Lambda::HTTP::HTTPS; };
			return  "https not supported: $@" if $@;
			$got_https++;
		}
		$self-> {reader} = IO::Lambda::HTTP::HTTPS::https_reader();
		$self-> {writer} = \&IO::Lambda::HTTP::HTTPS::https_writer;
		warn "https enabled\n" if $DEBUG;
	} elsif ( $scheme ne 'http') {
		return "bad URI scheme: $scheme";
	} else {
		$self-> {reader} = undef;
		$self-> {writer} = undef;
	}

	return;
}

# returns static lambda that reads from socket until a condition (see sysreader) is satisfied
sub http_read
{
	my ( $self, $cond) = @_;
	return $self-> {reader}, $self-> {socket}, \ $self-> {buf}, $cond, $self-> {deadline};
}

# read from socket until a condition (see sysreader) is satisfied
# after this call no communication should happen
sub http_tail
{
	my ( $self, $cond) = @_;
	context $self-> http_read($cond);
	&tail();
}

sub socket
{
	my ( $self, $host, $port) = @_;

	my $sock = IO::Socket::INET-> new(
		PeerAddr => $host,
		PeerPort => $port,
		Proto    => 'tcp',
		Blocking => 0,
	);
	return $sock, ( $sock ? undef : "connect: $!");
}

# Connect to the remote, wait for protocol to finish, and
# close the connection if needed. Returns HTTP::Response object on success
sub handle_connection
{
	my ( $self, $req) = @_;
	
	my ( $host, $port);
	if ( defined( $self-> {proxy})) {
		if ( ref($self->{proxy})) {
			return lambda { "'proxy' option must be a non-empty array" } if
				ref($self->{proxy}) ne 'ARRAY' or
				not @{$self->{proxy}};
			($host, $port) = @{$self->{proxy}};
		} else {
			$host = $self-> {proxy};
		}
		$port ||= $req-> uri-> port;
	} else {
		( $host, $port) = ( $req-> uri-> host, $req-> uri-> port);
	}

	# have a chance to load eventual modules early
	my $err = $self-> prepare_transport( $req);
	return lambda { $err } if defined $err;

	lambda {
		# resolve hostname
		if (
			$self-> {async_dns} and
			$host !~ /^(\d{1,3}\.){3}(\d{1,3})$/
		) {
			context $host, 
				timeout => ($self-> {deadline} || $IO::Lambda::DNS::TIMEOUT); 
			warn "resolving $host\n" if $DEBUG;
			return IO::Lambda::DNS::dns( sub {
				$host = shift;
				return $host unless $host =~ /^\d/; # error
				warn "resolved to $host\n" if $DEBUG;
				return this-> start; # restart the lambda with different $host
			});
		}

		delete $self-> {close_connection};
		$self-> {close_connection}++ 
			if ( $req-> header('Connection') || '') =~ /^close/i;
		
		# got cached socket?
		my ( $sock, $cached);
		my $cc = $self-> {conn_cache};

		if ( $cc) {
			$sock = $cc-> withdraw( __PACKAGE__, "$host:$port");
			if ( $sock) {
				my $err = unpack('i', getsockopt( $sock, SOL_SOCKET, SO_ERROR));
				$err ? undef $sock : $cached++;
				warn "reused socket is ".($err ? "bad" : "ok")."\n" if $DEBUG;
			}
		}

		# connect
		my $err;
		warn "connecting\n" if $DEBUG and not($sock);
		( $sock, $err) = $self-> socket( $host, $port) unless $sock;
		return $err unless $sock;
		context( $sock, $self-> {deadline});

	connect {
		return shift if @_;
		# connected

		$self-> {socket} = $sock;
		$self-> {reader} = readbuf ( $self-> {reader});
		$self-> {writer} = $self-> {writer}-> ($cached) if $self-> {writer}; 
		$self-> {writer} = writebuf( $self-> {writer});

		context $self-> handle_request( $req);
	autocatch tail {
		my $response = shift;
		
		# put back the connection, if possible
		if ( $cc and not $self-> {close_connection}) {
			my $err = unpack('i', getsockopt( $sock, SOL_SOCKET, SO_ERROR));
			warn "deposited socket back\n" if $DEBUG and not($err);
			$cc-> deposit( __PACKAGE__, "$host:$port", $sock)
				unless $err;
		}
			
		warn "connection:close\n" if $DEBUG and $self-> {close_connection};

		delete @{$self}{qw(close_connection socket buf writer reader)};
		
		return $response;
	}}}
}

# Execute single http request over an established connection.
# Returns either a HTTP::Response object, or an error string
sub handle_request
{
	my ( $self, $req) = @_;

	lambda {
		$self-> {buf} = '';

		context $self-> handle_request_in_buffer( $req);

		if ( $DEBUG) {
			warn "request sent\n";
			warn $req-> as_string . "\n" if $DEBUG > 1;
		}
	tail {
		my ( undef, $error) = @_; # readbuf style
		if ( $DEBUG) {
			warn "got response\n";
			warn (( $error ? $error : $self-> {buf})  . "\n") if $DEBUG > 1;
		}
		return defined($error) ? $error : $self-> parse( \ $self-> {buf} );
	}}
}

# Execute single http request over an established connection.
# Returns 2 parameters, readbuf-style, where actually only the 2nd matters,
# and signals error if defined. 2 parameters are there for readbuf() compatibility,
# so that the protocol handler can easily fall back to readbuf() itself.
sub handle_request_in_buffer
{
	my ( $self, $req) = @_;

	my $method = $req-> method;

	# fixup path - otherwise LWP generates request as GET http://hostname/uri HTTP/1.1
	# which not all servers understand
	my ($req_line, $save_uri);
	if (!$self-> {proxy} && ( $req-> protocol || '') =~ /http\/1.\d/i) {
		$save_uri = $req-> uri;

		my $fullpath = $save_uri-> path_query;
		$fullpath = "/$fullpath" unless $fullpath =~ m[^/];
		$req-> uri( $fullpath);
	}
	$req_line = $req-> as_string("\x0d\x0a");
	$req-> uri($save_uri) if defined $save_uri;

	lambda {
		# send request
		context 
			$self-> {writer}, 
			$self-> {socket}, \ $req_line, 
			undef, 0, $self-> {deadline};
	state write => tail {
		my ( $bytes_written, $error) = @_;
		return undef, $error if $error;

		context $self-> {socket}, $self-> {deadline};
	readable {
		# request sent, now wait for data
		return undef, 'timeout' unless shift;
		
		# read first line
		context $self-> http_read(qr/^.*?\n/);
	state head => tail {
		my $line = shift;
		unless ( defined $line) {
			my $error = shift;
			# remote closed connection and content is single-line HTTP/1.0
			return (undef, $error) if $error ne 'eof';
			return (undef, undef);
		}

		# no headers? 
		return $self-> http_tail
			unless $line =~ /^HTTP\/[\.\d]+\s+\d{3}\s+/i;

		# got some headers
		context $self-> http_read( qr/^.*?\r?\n\r?\n/s);
	state body => tail {
		$line = shift;
		return undef, shift unless defined $line;

		my $headers = HTTP::Response-> parse( $line);

		# Connection: close
		my $c = lc( $headers-> header('Connection') || '');
		$self-> {close_connection} = $c =~ /^close\s*$/i;

		return 1 if $method eq 'HEAD';

		return $self-> http_read_body( length $line, $headers);
	}}}}}
}

# have headers, read body
sub http_read_body
{
	my ( $self, $offset, $headers) = @_;

	# have Content-Length? read that many bytes then
	my $l = $headers-> header('Content-Length');
	return $self-> http_tail( $1 + $offset )
		if defined ($l) and $l =~ /^(\d+)\s*$/;

	# have 'Transfer-Encoding: chunked' ? read the chunks
	my $te = lc( $headers-> header('Transfer-Encoding') || '');
	return $self-> http_read_chunked($offset)
		if $self-> {chunked} = $te =~ /^chunked\s*$/i;

	# just read as much as possible then -- however with considerations;
	# we can't do that if server keeps connection open, otherwise we'll hang

	# http/1.0 and less doesn't implement open connections
	return $self-> http_tail if 
		$headers-> protocol =~ /^HTTP\/(\d+\.\d+)/ and
		$1 < 1.1;

	# server wants to close the connection
	return $self-> http_tail if
		$self-> {close_connection};
}

# read sequence of TE chunks
sub http_read_chunked
{
	my ( $self, $offset) = @_;

	# read chunk size
	pos( $self-> {buf} ) = $offset;
	context $self-> http_read( qr/\G[^\r\n]+\r?\n/i);
	state size => tail {
		my $line = shift;
		return undef, shift unless defined $line; # got error

		# advance
		substr( $self-> {buf}, $offset, length($line), '');
		pos( $self-> {buf} ) = $offset;
		$line =~ s/\r?\n//;
		return undef, "protocol error: chunk size error"
			unless $line =~ /^[\da-f]+$/;
		my $size = hex $line;
		warn "reading chunk $size bytes\n" if $DEBUG;
		return 1 unless $size;
		$size += 2; # CRLF

		my $frame = restartable;

	# read the chunk itself
	context $self-> http_read( $offset + $size);
	state chunk => tail {
		return undef, shift unless shift;

		$offset += $size - 2;
		substr( $self->{buf}, $offset, 2, '' ); # remove CRLF
		pos( $self-> {buf} ) = $offset;
		warn "chunk $size bytes ok\n" if $DEBUG;

		again($frame);
	}};
}


sub parse
{
	my ( $self, $buf_ptr) = @_;
	return HTTP::Response-> parse( $$buf_ptr) if $$buf_ptr =~ /^(HTTP\S+)\s+(\d{3})\s+/i;
	return HTTP::Response-> new( '000', '', undef, $$buf_ptr);
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::HTTP::Client - http requests lambda style

=head1 DESCRIPTION

The module exports a single condition C<http_request> that accepts a
C<HTTP::Request> object and set of options as parameters. The condition returns
either a C<HTTP::Response> on success, or an error string otherwise.

=head1 SYNOPSIS

   use HTTP::Request;
   use IO::Lambda qw(:all);
   use IO::Lambda::HTTP::Client qw(http_request);

   lambda {
      context shift;
      http_request {
         my $result = shift;
         if ( ref($result)) {
            print "good: ", length($result-> content), " bytes\n";
         } else {
            print "bad: $result\n";
         }
      }
   }-> wait(
       HTTP::Request-> new( GET => "http://www.perl.com/")
   );

=head1 API

=over

=item http_request $HTTP::Request -> $HTTP::Response

C<http_request> is a lambda condition that accepts C<HTTP::Request> object in
the context. Returns either a C<HTTP::Response> object on success, or error
string otherwise.

=item new $HTTP::Request :: () -> $HTTP::Response

Stores C<HTTP::Request> object and returns a new lambda that will finish when
the associated request completes. The lambda will return either a
C<HTTP::Response> object on success, or an error string otherwise. 

=back

=head1 OPTIONS

=over

=item async_dns BOOLEAN

If set, hostname will be resolved with L<IO::Lambda::DNS> using asynchronous
capabilities of L<Net::DNS>. Note that this method won't be able to account for
non-DNS (/etc/hosts, NIS) host names.

If unset (default), hostnames will be resolved in a blocking manner.

=item auth $AUTH

Normally, a request is sent without any authentication. If the request returns
error 401, then all available methods of authentication are tried. If the type
of authentication that shall be accepted by the remote is known in advance, the
non-authenticated request stage can be skipped altogether by explicitly setting
the C<auth> option:

   username => 'user',
   password => 'pass',
   auth     => 'Basic',

=item conn_cache $LWP::ConnCache = undef

The requestor can optionally use a C<LWP::ConnCache> object to reuse
connections on per-host per-port basis. Desired for HTTP/1.1. Required for the
NTLM/Negotiate authentication.  See L<LWP::ConnCache> for details.

=item deadline SECONDS = undef

Aborts a request and returns C<'timeout'> string as an error if the request is
not finished before the deadline (in epoch seconds). If undef, timeout never
occurs.

=item keep_alive BOOLEAN

If set, all incoming request objects are silently converted use HTTP/1.1, and 
connections are automatically reused. Same as combination of the following:

   $req-> protocol('HTTP/1.1');
   $req-> headers-> header( Host => $req-> uri-> host);
   new( $req, conn_cache => LWP::ConnCache-> new);

=item max_redirect NUM = 7

Maximum allowed redirects. If 0, no redirection attemps are made.

=item preferred_auth $AUTH|%AUTH

Sets list of preferred authentication methods, that is used in selection of the
authentication method when the remote server supports several. When the value
is a string, then the given method is tried first, and only then all other
available methods. When it is a hash, the hash values are treated as weight
factors, such as, the method with the greatest weight is tried first. Negative
values prevent the corresponding methods from being tried.

     # try basic and whatever else
     preferred_auth => 'Basic',

     # try basic and never ntlm
     preferred_auth => {
         Basic => 1,
	 NTLM  => -1,
     },

Note that the current implementation does not provide re-trying of
authentication if a method, or combination of username and password fails.
When at least one method is declared by the remote as supported, and was tried,
and subsequently failed, no further authentication retries are made, and the
request is reported as failed.

=item proxy HOSTNAME | [ HOSTNAME, PORT ]

If set, HOSTNAME (or HOSTNAME and PORT tuple) is used as HTTP proxy.

=item timeout SECONDS = undef

Maximum allowed time the request can take. If undef, no timeouts occur.

=back

=head1 BUGS

Non-blocking connects, and hence the module, don't work on win32 on perl5.8.X
due to under-implementation in ext/IO.xs.  They do work on 5.10 however. 

=head1 SEE ALSO

L<IO::Lambda>, L<HTTP::Request>, L<HTTP::Response>

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
