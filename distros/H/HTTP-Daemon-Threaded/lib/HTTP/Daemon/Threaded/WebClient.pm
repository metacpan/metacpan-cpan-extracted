=pod

=begin classdoc

Provides web-based request handling. A pool of WebClient
objects are created and managed by HTTP::Daemon::Threaded::Listener. As
web connection requests are received, a WebClient
is allocated and assigned the network connection. A minimal
HTTP protocol implementation is provided via a subclass of HTTP::Daemon::ClientConn.
As requests are received, they are processed as needed,
possibly resulting in calls to any installed content handler components.
<p>
Content handlers are specified as an arrayref of 2-tuples
consisting of
<pre>
[ regular expression string, content handler class name ]
</pre>
When a client HTTP request is received, each registered content handler's regular expression
string is applied to the URI <i>in the order in which the handler's are listed in the
content handler map</i> until a match is found, at which point the content handler class's
<code>getContent()/putContent()/getHeader()</code> method is invoked.
If no regular expression matches the URI,
a HTTP 404 (NOT FOUND) error is returned to the client.
<p>
Application specific parameters for content handlers may be provided by
creating a concrete implemention of the HTTP::Daemon::Threaded::ContentParams
class, and supplying any constructor parameters as additional key/value
pairs in the WebClient constructor hash.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2006-08-21
@self	$self

=end classdoc

=cut

use strict;
use warnings;

package HTTP::Daemon::Threaded::WebClient;
use Socket;
use threads;
use threads::shared;
use Time::Local;
use Time::HiRes qw(sleep);
use HTTP::Response;
use LWP::MediaTypes qw(add_type);
use HTTP::Daemon::Threaded::Socket;
use HTTP::Daemon::Threaded::Logable;
use HTTP::Daemon::Threaded::CGIAdapter;
use Thread::Apartment::MuxServer;
use URI::Escape;
use CGI;
use base qw(HTTP::Daemon::Threaded::Logable Thread::Apartment::MuxServer);

our $VERSION = '0.91';

=pod

=begin classdoc

@constructor

Creates an empty HTTP::Daemon::Threaded::Socket object.
Creates any specified ContentParams object, and installs the content handler map.
<p>
Note that the following parameters are recognized by
HTTP::Daemon::Threaded::WebClient, but
applications may supply additional parameter key/value pairs
which will be provided to the constructor for any specified
HTTP::Daemon::Threaded::ContentParams class.

@param HTTPD		the parent daemon object
@param LogLevel		<i>(optional)</i> logging level; 1 => errors only; 2 => errors and warnings only; 3 => errors, warnings,
						and info messages; default 1
@param EventLogger <i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
					event notifications (except for web requests)
@param WebLogger	<i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
					web request notifications
@param Handlers	arrayref mapping URL regex strings to handler classes
@param ID			unique client identifier
@param InactivityTimer <i>(optional)</i> number of seconds to wait before disconnecting an idle connection
@param ContentParams	<i>(optional)</i> name of a ContentsParam concrete implementation
@param UserAuth		<i>(optional)</i> User authentication package name <i>(not yet supported)</i>
@param SessionCache	<i>(optional)</i> threads::shared object implementing HTTP::Daemon::Threaded::SessionCache
@param DocRoot		<i>(optional)</i> root directory for default file based content handler
@param URL			the base address/port of our listener
@param ProductTokens	product token string from listener
@param MediaTypes		<i>(optional)</i> hashref mapping 'Content-Type' specifications to
						file qualifier strings. Values may be either a single string literal, or
						an arrayref of string literals, e.g.,<br>
						<code>MediaTypes =&gt; { 'text/css' => 'css' }</code>. Used to
						add media types for LWP::MediaTypes::guess_media_type()
@param FreeList	free client list; threads::shared array optimized to quickly
					allocate/free WebClient objects
@param SelectInterval	seconds to wait in select()'s on sockets. May be fractional; default 0.5

@return		HTTP::Daemon::Threaded::WebClient object

=end classdoc

=cut

sub new {
	my ($class, %args) = @_;
#
#	install all web client modules
#
	my $media = delete $args{MediaTypes};
	my $self = { %args };
	bless $self, $class;
	$self->set_client(delete $self->{AptTAC})
		if $self->{AptTAC};
	$self->logInfo("WebClient $args{ID} created\n");
#
#	create any content handlers
#
	my %handlers = ();
	my $i = 0;
	while ($i <= $#{$args{Handlers}}) {
#
#	compile the regexp string
#
		$args{Handlers}[$i++] = qr/$args{Handlers}[$i]/;

		my $module = $args{Handlers}[$i];
		unless ($module eq '*') {
			if (exists $handlers{$module}) {
				$args{Handlers}[$i] = $handlers{$module};
			}
			else {
				eval "require $module;";
				$self->logError("Can't load content handler $module: $@"),
				$@ = "Can't load content handler $module: $@",
				return undef
					if $@;
				$args{Handlers}[$i] = $handlers{$module} =
					${module}->new(
						SessionCache => $args{SessionCache},
						ContentParams => $args{ContentParams},
						LogLevel => $args{LogLevel},
						EventLogger => $args{EventLogger},
						);
				$@ = "Can't create instance of content handler $module",
				return undef
					unless defined $handlers{$module};
			}
		}
		$i++;
	}
#	print "WebClient has ", join("\n", @{$args{Handlers}}), "\n";
#
#	create a selector
#
	$self->{_sktsel} = HTTP::Daemon::Threaded::IOSelector->new($args{SelectInterval});
#
#	use current time for display
#
	my @ts = split(/\s+/, scalar localtime());
	$self->{_started} = join(' ', $ts[3], $ts[0], $ts[1], $ts[2], $ts[4]);
#
#	add add'l media types
#
	if ($media) {
		my ($ct, $fq);
		add_type($ct => (ref $fq ? @$fq : $fq))
			while (($ct, $fq) = each %$media);
	}
#
#	crate local'ized %ENV
#
	local *ENV = { %ENV };
	return $self;
}

=pod

=begin classdoc

Overrides Thread::Apartment::Server::get_simplex_methods().

@return		hashref of simplex method names

=end classdoc

=cut

sub get_simplex_methods {
	return {
		setLogLevel => 1,
	};
}
=pod

=begin classdoc

Accepts a web client connection. Called from HTTP::Daemon::Threaded when a new connection
event occurs. Collects the peer info for logging purposes.
Converts the supplied socket file number to a HTTP::Daemon::Threaded::Socket
object.

@param $fn	file number of the new socket

@return		the object
@see	HTTP::Daemon::Threaded::Socket

=end classdoc

=cut

sub acceptConnection {
	my ($self, $fn) = @_;
#
#	create empty socket
#
	my $fd = HTTP::Daemon::Threaded::Socket->new();
	$self->logWarning("WebClient: fdopen($fn) failed: $!."),
	return undef
		unless $fd->fdopen($fn, '+>>');

	binmode $fd;
#
#	collect peer info
#
	my $sockaddr = getpeername($fd);
	my ($port, $addr) = sockaddr_in($sockaddr);
	my $clientaddr = inet_ntoa($addr) . ":$port";
	my $prefix = "Web client $clientaddr";
#	print "LINGER is ", join(', ', @res), "\n";
#
#	make sure to set options
#
#	$fd->sockopt(SO_KEEPALIVE, pack('l', 1));
#	$fd->setsockopt(SOL_SOCKET, SO_LINGER, pack('ll', 1,1));
#	my @res = $fd->getsockopt(SOL_SOCKET, SO_LINGER);
#	print "LINGER is ", join(', ', @res), "\n";
	$self->{LogPrefix}{$fn} = $prefix;
	$fd->setContext($self, 1);
#
#	add to selector
#
	$self->{_sktsel}->addNoWrite($fd);
	$fd->setSelector($self->{_sktsel});

	$self->{_curr_skt} = $fd;
	$self->{_idle_timer} = time();
	return $self->{ID};
}

=pod

=begin classdoc

Thread::Apartment::MuxServer::run() implementation.

@return		1

=end classdoc

=cut

sub run {
	my $self = shift;

	while (1) {
#
#	HTTP::Daemon::Threaded::IOSelector does the heavy lifting
#
		if (exists $self->{_curr_skt}) {
			my $elapsed = $self->{_sktsel}->select();
#
#	check idle time
#
			if ($self->{_curr_sess}) {
				$self->_shutdown()
					if $self->{_curr_sess}->isInactive($self->{_idle_timer});
			}
			elsif ($self->{InactivityTimer} < (time() - $self->{_idle_timer})) {
				$self->_shutdown();
			}
		}
		else {
#
#	if no connection installed, just kill time
#
			select(undef, undef, undef, 0.1);
		}
		return undef
			unless $self->handle_method_requests();
	}

	return 1;
}

sub _shutdown {
	my $self = shift;
	$self->logInfo("Shutting down connection...\n");
	my $fd = delete $self->{_curr_skt};
	delete $self->{LogPrefix}{fileno($fd)};
	$fd->close();
	$self->{_curr_sess}->close(),
	delete $self->{_curr_sess}
		if $self->{_curr_sess};
	$self->freeClient();
	return 1;
}

=pod

=begin classdoc

Handles a socket event. Accumulates a client request, parses it,
and then dispatches to the associated URL handler. Only a single
client request is handled, but the connection may be retained
indefinitely (for HTTP 1.1 Connection: keepalive clients).

@param $fd	the HTTP::Daemon::Threaded::Socket object on which the event occured

@return		the object

=end classdoc

=cut

sub handleSocketEvent {
	my ($self, $fd) = @_;

	my ($page, $method, $buffer, $request, $cgi, $params, $handler, $session);
	my $close_on_resp;
	$fd = $self->{_curr_skt};
	my $handlers = $self->{Handlers};
#
#	read the request in (up to some max size) and validate
#	the header
#
	$request = $fd->get_request();
	return $self->_shutdown()
		unless $request;

#	$self->logInfo("Got a request as a " . (ref $request) . "\n");
#
#	get HTTP protocol level; if < 1.1, we close the connection on exit
#
#	$self->logInfo("Got pre 1.1 client\n"),
	$close_on_resp = 1,
	$fd->force_last_request()
		unless $fd->proto_ge("1.1");

	$session = $self->{SessionCache}->getSession($request)
		if $self->{SessionCache};
	$self->logInfo("Got a session\n") if $session;
	$page = $request->uri;
	$method = $request->method;
	$self->logInfo("Got web request for $method $page\n");
	$self->{_idle_timer} = time();
#
#	should use other error...should also support HEAD and eventually
#	PUT and UPLOAD
#
	$fd->send_error(404),
	return $self->_shutdown()
		unless (($method eq 'GET') ||
			($method eq 'POST') ||
			($method eq 'HEAD') ||
			($method eq 'PUT'));

	if ($page=~/^([^\?]+?)\?(.*)$/) {
#
#	extract params and normalize uri
#
		($page, $cgi, $params) = ($1, 1, $2);
		$self->logInfo("Its a CGI with params $params\n");
	}
	else {
#
#	disable params and normalize uri
#
		($cgi, $params) = (undef, undef);
		$page .= 'index.html'
			if (substr($page, -1, 1) eq '/');
	}
#
#	if uri is just 'stop', shut everything down
#
	if (($page eq '/stop') && ($method eq 'GET')) {
		$self->_shutdown();
		my $httpd = $self->{HTTPD};
		$httpd->close();
		return 1;
	}

	my $i = 0;

	$i += 2
		while ($i <= $#$handlers) &&
			$self->logInfo("Trying $$handlers[$i] on $page\n") &&
			($page!~/$$handlers[$i]/);

	unless ($i <= $#$handlers) {
#		$self->logInfo("$prefix: Unknown request URL $page\n"),
		$self->logInfo("Unknown request URL $page\n");
		$fd->send_error(404);
		$self->_shutdown()
			if $close_on_resp;
		return 1;
	}

	$handler = $handlers->[$i+1];
#
#	read the rest of it (if anymore)
#	see HTTP::Daemon::ClientConn
#
	my $ct = (($method eq 'GET') || ($method eq 'HEAD')) ?
		'application/x-www-form-urlencoded' :
		$request->content_type();

	if ($ct && ($ct eq 'application/x-www-form-urlencoded')) {
		$params = $request->content(),
		$cgi = 1
			if ($method eq 'POST');
#
#	convert request to (param => value) hash
#
		my %reqparams = ();
		if ($cgi) {
			my @request = split(/\&/, $params);
			$self->logInfo("Orig Params are " . join(', ', @request) . "\n");
			my ($key, $val);

			foreach (@request) {
				($key, $val) = split /=/;
#
#	fixed per D. Hastings' bug report
#	NOTE: the unescape might be faster by running the regex locally
#
				$key=~tr/+/ /;
				$val=~tr/+/ /;
				($key, $val) = uri_unescape($key, $val);
#
#	support duplicate params
#
				if (exists $reqparams{$key}) {
					$reqparams{$key} = [ $reqparams{$key} ]
						unless ref $reqparams{$key};
					push @{$reqparams{$key}}, $val;
				}
				else {
					$reqparams{$key} = $val;
				}
			}
			$params = \%reqparams;
			$self->logInfo("Params are " . join(', ', %reqparams) . "\n");
		}
	}
	elsif ($ct && (length($ct) > 10) && (substr($ct, 0, 10) eq 'multipart/')) {
#
#	multipart request (e.g., file upload); collect the parts
#
		my @parts = $request->parts();
		$params = \@parts;
	}
	elsif ($method eq 'POST') {
#
#	could be anything, just grab it as the parameter and treat as a cgi
#
		$params = $request->content();
		$cgi = 1;
	}
	elsif ($method eq 'PUT') {
		$params = $request->content();
	}
#
#	if handler is docroot, just return the file (or its metadata as header)
#
#	$self->logInfo("Using handler " . (ref $handler) . "\n");
	unless (ref $handler) {
#
#	trim possible leading slash
#
		$page = substr($page, 1)
			if (substr($page, 0, 1) eq '/');
		$self->logInfo("Fetching $self->{DocRoot}$page\n");
		($method eq 'GET') ?
			$fd->send_file_response($self->{DocRoot} . $page) :
			$fd->send_file_header($self->{DocRoot} . $page);
		$self->_shutdown()
			if $close_on_resp;
		return 1;
	}
#
#	if handler is a CGI, build a CGI object for it
#
	if ($handler->isa('HTTP::Daemon::Threaded::CGIHandler')) {
		$self->logInfo("Routing to request for $page to handler " . (ref $handler) . "\n");
#		print STDERR "*** routing CGI request\n";
		my $cgireq = HTTP::Daemon::Threaded::CGIAdapter->new($request, $fd, $ct);
#		print STDERR "*** got CGI request, create CGI object\n";
		my $cgiobj = CGI->new();
#		print STDERR "*** got CGI object, call handleCGI\n";
		$handler->handleCGI($cgiobj, $session);
#		print STDERR "*** got CGI response, send response\n";
		my $rsp = $cgireq->restore->response;
#		print STDERR "*** Response is \n", $rsp->as_string(), "\n";
		$fd->send_response($rsp);
#		print STDERR "*** sent response\n";
		#
		#	!!!BE CAREFUL WHEN MERGING W/ 1.01: async will eave stdin/stoud/ENV
		#	in bogus states; we'll need to restore as needed
	}
	else {
	
	$self->logInfo("Routing to request for $page to handler " . (ref $handler) . "\n");
	my $result =
		($method eq 'HEAD') ?
			$handler->getHeader($fd, $request, $page, $params, $session) :
		($method eq 'PUT') ?
			$handler->putContent($fd, $request, $page, $params, $session) :
			$handler->getContent($fd, $request, $page, $params, $session);
	}
	$self->_shutdown()
		if $close_on_resp;
	return 1;
}
#
#	borrowed from HTTP::Daemon::ClientConn to emulate HTTP::Daemon
#
sub url
{
    return $_[0]->{URL};
}

sub product_tokens
{
    return $_[0]->{ProductTokens};
}

=pod

=begin classdoc

Return a client to the free list.

@param $client	ID of the client being freed

@return		1

=end classdoc

=cut

sub freeClient {
	my $self = shift;
	{
		lock(@{$self->{FreeList}});
		unshift @{$self->{FreeList}}, $self->{ID};
	}
}

1;

