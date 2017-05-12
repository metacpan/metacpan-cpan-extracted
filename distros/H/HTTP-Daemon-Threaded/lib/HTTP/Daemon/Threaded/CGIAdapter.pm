=pod

=begin classdoc

Convert an <cpan>HTTP::Request</cpan> object into a CGI protocol
environment, and process the response emitted by the CGI handler.
Uses <cpan>IO::Scalar</cpan> to redirect STDIN and STDOUT to scalar
buffers, so that the CGI handler input and output are buffered until the
handler exits, at which point, the accumulated output buffer is
turned into an <cpan>HTTP::Response</cpan> object and then sent
back to the client.
<p>
Derived from <cpan>HTTP::Request::AsCGI</cpan>, by Christian Hansen, C<ch@ngmedia.com>
<p>
<b>WARNING:</b> <cpan>IO::Scalar</cpan> relies on filehandle ties, which are still
considered experimental in some releases of Perl 5.8. However, the functionality
used within this package is limited to simple input or output, and thus far
appears to function well.
<p>
Developers should be judicious in their use of the CGI interface for
HTTP::Daemon::Threaded: if the request is to return a very large (i.e.,
multi-megabyte) response, the underlying I/O buffering may consume
significant memory resources. Likewise, this package does not support
some methods of "Comet"-style streaming client-server interaction, as the 
response buffer will not be dispatched to the client until the CGI
invokation has completed.
<p>
Copyright&copy 2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified in the
at <a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2008-Mar-14
@see <cpan>HTTP::Request::AsCGI</cpan>

=end classdoc

=cut

package HTTP::Daemon::Threaded::CGIAdapter;

use strict;
use warnings;
use bytes;

use Carp;
use Socket;
use IO::Handle;
use IO::Scalar;
use HTTP::Response;

our $VERSION = '0.91';

sub new {
    my ($class, $request, $fd, $content_type)   = @_;

    my $self = bless { 
    	restored => 0, 
    	setuped => 0,
    	request => $request
    }, $class;

    my $host = $request->header('Host');
    my $uri  = $request->uri->clone;
    $uri->scheme('http')    unless $uri->scheme;
    $uri->host('localhost') unless $uri->host;
    $uri->port(80)          unless $uri->port;
    $uri->host_port($host)  unless !$host || ( $host eq $uri->host_port );

    $uri = $uri->canonical;

	my $sockaddr = getpeername($fd);
	my ($port, $addr) = sockaddr_in($sockaddr);

    my %environment = (
        GATEWAY_INTERFACE => 'CGI/1.1',
        HTTP_HOST         => $uri->host_port,
        HTTPS             => ( $uri->scheme eq 'https' ) ? 'ON' : 'OFF',
        PATH_INFO         => $uri->path,
        QUERY_STRING      => $uri->query || '',
        SCRIPT_NAME       => '/',
        SERVER_NAME       => $uri->host,
        SERVER_PORT       => $uri->port,
        SERVER_PROTOCOL   => $request->protocol || 'HTTP/1.1',
        SERVER_SOFTWARE   => "HTTP-Daemon-Threaded/$VERSION",
        REMOTE_ADDR       => inet_ntoa($addr),
        REMOTE_HOST       => '',
        REMOTE_PORT       => $port,
        REQUEST_URI       => $uri->path_query,
        REQUEST_METHOD    => $request->method,
    );

    foreach my $field ( $request->headers->header_field_names ) {

        my $key = uc("HTTP_$field");
        $key =~ tr/-/_/;
        $key =~ s/^HTTP_// if $field =~ /^Content-(Length|Type)$/;

		$environment{$key} ||= $request->headers->header($field);
    }

    unless ( $environment{SCRIPT_NAME} eq '/' && $environment{PATH_INFO} ) {
        $environment{PATH_INFO} =~ s/^\Q$environment{SCRIPT_NAME}\E/\//;
        $environment{PATH_INFO} =~ s/^\/+/\//;
    }

	$environment{CONTENT_TYPE} ||= $content_type;
    $self->{environment} = \%environment;
#
#	remap stdin to a buffer with the request data in it
#
	my $stdin_buffer = '';
    if ( $self->{request}->content_length ) {
        $stdin_buffer = $self->{request}->content
          or croak("Can't write request content to stdin handle: $!");
    }

	$self->{stdin_buffer} = \$stdin_buffer;
#
#	we should really do this just once, and reuse the values
#	it could even be a package variable
#
    open( $self->{restore}{stdin}, '<&=', \*STDIN )
      or croak("Can't redirect stdin: $!");

	tie *STDIN, 'IO::Scalar', \$stdin_buffer;
#
#	remap stdout to a buffer to hold the response
#
	my $stdout_buffer = '';
	$self->{stdout_buffer} = \$stdout_buffer;
	open( $self->{restore}{stdout}, '>&=', \*STDOUT)
          or croak("Can't dup stdout: $!");

	tie *STDOUT, 'IO::Scalar', \$stdout_buffer;
#
#	remap the environment
#
	my ($k, $v);
	$ENV{$k} = $v while (($k, $v) = each %environment);
#
#	is this trip really neccesary ?
#
	CGI::initialize_globals()
    	if $INC{'CGI.pm'};

    $self->{setuped}++;

    return $self;
}

sub response {
    my $self = shift;

    my $buf = $self->{stdout_buffer};
    return undef unless $buf;

	my ($headers) = ($$buf=~/^(.*?\x0d?\x0a\x0d?\x0a)/s);
    my $readlen = length($headers);
    
	$headers = "HTTP/1.1 500 Internal Server Error\x0d\x0a"
		unless $headers;

	$headers = "HTTP/1.1 200 OK\x0d\x0a$headers"
	    unless ( $headers =~ /^HTTP/ );

    my $response = HTTP::Response->parse($headers);
    $response->date( time() ) unless $response->date;

    my $message = $response->message;
    my $status  = $response->header('Status');

	$response->message($1)
    	if ( $message && $message =~ /^(.+)\x0d$/);

    if ( $status && $status =~ /^(\d\d\d)\s?(.+)?$/ ) {

        my $code    = $1;
        my $message = $2 || HTTP::Status::status_message($code);

        $response->code($code);
        $response->message($message);
    }
    
    my $length = length($$buf) - $readlen;

	$response->content( $response->error_as_HTML ),
	$response->content_type('text/html'),
	return $response
	    if ( $response->code == 500 && !$length );

	$response->add_content(substr($$buf, $readlen));
	$response->content_length($length)
		if ( $length && !$response->content_length );
#
#	Now we can discard the buffer
#
    delete $self->{stdout_buffer};
    return $response;
}

sub restore {
    my $self = shift;
#
#	NOTE: we're going to let non-CGI changes to %ENV persist
#	between invokations...not sure its the right thing to do...
#
	delete $ENV{$_} foreach keys (%{$self->{environment}});

	untie *STDIN;

	open(STDIN, "<&=", $self->{restore}{stdin})
		or croak("Can't restore stdin: $!");

    delete $self->{stdin_buffer};
	delete $self->{restore}{stdin};

    if ( $self->{restore}{stdout} ) {
#
#	!!!NOTE : we can't discard the buffer yet...response() needs it!
#
		untie *STDOUT;
		open(STDOUT, "<&=", $self->{restore}{stdout})
          or croak("Can't restore stdout: $!");
        delete $self->{restore}{stdout};
    }
    $self->{restored}++;

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->restore
    	if $self->{setuped} && !$self->{restored};
}

1;
