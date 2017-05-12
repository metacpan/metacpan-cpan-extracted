=pod

=begin classdoc

Web network listener: accepts network connections, and routes
them to WebClient objects to handle the web requests. Creates and maintains
a pool of WebClient objects.
<p>
A threads::shared array is shared between this object and the WebClient
objects so that WebClients can return themselves to the free list quickly;
a future release may convert the freelist to a full object, in the event
the allocate/free methods require a more complex process.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified in the
at <a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2006-08-21
@self	$self



=end classdoc

=cut
package HTTP::Daemon::Threaded::Listener;

use Socket;
use Sys::Hostname;
use threads;
use threads::shared;
use HTTP::Daemon::Threaded::Socket;
use HTTP::Daemon::Threaded::WebClient;
use HTTP::Daemon::Threaded::IOSelector;
use HTTP::Daemon::Threaded::Logable;
use Thread::Apartment::MuxServer;

use base qw(HTTP::Daemon::Threaded::Logable Thread::Apartment::MuxServer);

use strict;
use warnings;

our $VERSION = '0.91';

use constant HTTPD_INTERVAL => 0.5;

=pod

=begin classdoc

Constructor. Opens the HTTPD listener socket and creates
its selector. Creates a pool of HTTP::Daemon::Threaded::WebClient
apartment threaded objects, based on the specified MaxClient
parameter.
<p>
Note that the following parameters are recognized by
HTTP::Daemon::Threaded and/or HTTP::Daemon::Threaded::WebClient, but
applications may supply additional parameter key/value pairs
which will be provided to the constructor for any specified
HTTP::Daemon::Threaded::ContentParams class.

@param AptTimeout		<i>(optional)</i> Thread::Apartment proxy return timeout
@param Port			<i>(optional)</i> TCP listen port; default 80.
@param MaxClients		<i>(optional)</i> max number of client handlers to spawn;
default 5
@param LogLevel		<i>(optional)</i> logging level; 1 => errors only; 2 => errors and warnings only; 3 => errors, warnings,
and info messages; default 1
@param EventLogger <i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
event notifications (except for web requests)
@param WebLogger	<i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
web request notifications
@param Handlers		<i>(required)</i> URI handler map; arrayref mapping URI regex's to handler package names
@param UserAuth		<i>(optional)</i> instance of a subclass of HTTP::Daemon::Threaded::Auth <i>(not yet supported)</i>
@param SessionCache	<i>(optional)</i> instance of a subclass of HTTP::Daemon::Threaded::SessionCache
to be used to create/manage sessions
@param InactivityTimer <i>(optional)</i> number of seconds a WebClient waits before disconnecting
an idle connection; default 10 minutes
@param ContentParams  <i>(optional)</i> name of concrete implementation of HTTP::Daemon::Threaded::ContentParams
@param DocRoot		<i>(optional)</i> root directory for default file based content handler
@param ProductTokens	<i>(optional)</i> product token string to return to client; default
is 'HTTP::Daemon::Threaded/<version>'
@param MediaTypes		<i>(optional)</i> hashref mapping 'Content-Type' specifications to
file qualifier strings. Values may be either a single string literal, or
@param SelectInterval	<i>(optional)</i> seconds to wait in select()'s on sockets. May be fractional; default 0.5

@return		HTTP::Daemon::Threaded object


=end classdoc

=cut
sub new {
	my ($class, %args) = @_;

	$args{SelectInterval} = HTTPD_INTERVAL
		unless $args{SelectInterval};

	my $self = { %args, _status => 'starting' };
	bless $self, $class;
#
#	setup our proxy version
#
	$self->set_client(delete $self->{AptTAC});
#
#	open our listener
#
	$self->{Port} = $args{Port} = 80
		unless exists $args{Port};
	$self->{_fd} = HTTP::Daemon::Threaded::Socket->new(
		LocalPort => $args{Port},
		Proto => 'tcp',
		Listen => 10);
	$self->logError("Cannot get listener for Web Server: $!"),
	$@ = "Cannot get listener for Web Server: $!",
	return undef
		unless $self->{_fd};
#
#	register ourselves with it
#	(for single threaded mode)
#
	$self->{_fd}->setContext($self);

	$self->logInfo("Created listener\n");
#
#	create a selector
#

	$self->{_sktsel} = HTTP::Daemon::Threaded::IOSelector->new($args{SelectInterval});
	$self->{_sktsel}->addNoWrite($self->{_fd});
#
#	create request handler pool
#
	my @avail_clients : shared = ();
	$self->{_avail_clients} = \@avail_clients;
	my @webclients = (undef);
	$self->{_clients} = \@webclients;
#
#	update the args
#
	$self->{LogLevel} = $args{LogLevel} = 1
		unless exists $args{LogLevel};
	delete $args{MaxClients};
#
#	normalize docroot if needed
#
	$args{DocRoot} .= '/'
		if (defined $args{DocRoot}) && (substr($args{DocRoot}, -1, 1) ne '/');

    my $url = "http://";
    my $addr = $self->{_fd}->sockaddr;
 	$url .= (!$addr || $addr eq INADDR_ANY) ?
 		lc Sys::Hostname::hostname() :
 		(gethostbyaddr($addr, AF_INET) || inet_ntoa($addr));
    my $port = $self->{_fd}->sockport;
    $url .= ":$args{Port}"
    	unless ($args{Port} == 80);
    $args{URL} = $url . '/';
	delete $args{Port};

	$args{ProductTokens} = "HTTP::Daemon::Threaded/$VERSION"
		unless $args{ProductTokens};

	$args{HTTPD} = $self->get_client();
	$args{AptClass} = 'HTTP::Daemon::Threaded::WebClient';
	$args{FreeList} = \@avail_clients;
#
#	note that this inactivity timer may be overridden by
#	any Session object's timeout
#
	$self->{InactivityTimer} = $args{InactivityTimer} = 10 * 60
		unless exists $args{InactivityTimer};

	foreach (1..$self->{MaxClients}) {
		$args{ID} = $_;
		push @webclients, Thread::Apartment->new(%args);

		pop @webclients,
		$@ = 'Unable to create a WebClient instance.',
		$self->logWarning('Unable to create a WebClient instance.'),
		return undef
			unless $webclients[-1];
		push @{$self->{_avail_clients}}, $_;
		$self->logInfo("Created WebClient\n");
	}

	$self->{_status} = 'running';
	return $self;
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
		if ($self->{_sktsel}) {
#
#	HTTP::Daemon::Threaded::IOSelector does the heavy lifting
#
			my $elapsed = $self->{_sktsel}->select();
			print STDERR "Long select!!! $elapsed\n"
				if ($elapsed >= 1);
		}
		else {
			select(undef, undef, undef, 0.1);
		}

		return undef
			unless $self->handle_method_requests();
#
#	shutdown may remove our selector
#
#		last unless $self->{_sktsel};
	}

	return undef;
}

sub status {
#print "Returning status ", $_[0]->{_status}, "\n";
	return $_[0]->{_status};
}

=pod

=begin classdoc

Overrides Thread::Apartment::Server::get_simplex_methods()

@return		hashref of simplex method names


=end classdoc

=cut
sub get_simplex_methods {
	return {
		close => 1,
		setLogLevel => 1,
		setListenInterval => 1,
	};
}

=pod

=begin classdoc

Closes the listen socket and stops all the WebClient
threads.

@simplex
@return		1


=end classdoc

=cut
sub close {
	my $self = shift;

	$self->logInfo("shutdown requested\n");

	delete $self->{_sktsel};

	$self->{_fd}->close(),
	delete $self->{_fd}
		if $self->{_fd};
#
#	queue stops first, then join
#
	if ($self->{_clients}) {
		map { $_->stop() if $_; } @{$self->{_clients}};
		map { $_->join() if $_; } @{$self->{_clients}};
	}
	$self->{_status} = 'stopped';
	return 1;
}

=pod

=begin classdoc

Return the listener socket.

@return		HTTP::Daemon::Threaded::Socket listen socket object


=end classdoc

=cut
sub getSocket { return shift->{_fd}; }
=pod

=begin classdoc

Handle listen socket events. Accepts a new connection request,
allocates a WebClient to handle it, and passes the new socket
to the WebClient

@return		1


=end classdoc

=cut
sub handleSocketEvent {
	my $self = shift;

	$self->logInfo('Got web connection request.');
#
#	client must accept(): must make this duplex, so we don't keep
#	pinging the listener
#
	my $skt = $self->{_fd}->accept();
	return 1 unless $skt;

	my $client = $self->_get_client();
	$skt->close(),
	return 1
		unless $client;
#
#	this waits for client...
#
	$client->acceptConnection($skt->fileno());

	return 1;
}
#
#	do we need to close the file here ?
#	maybe we should just let the clients accept() ?
#
=pod

=begin classdoc

Handle socket errors.

@deprecated
@return		undef


=end classdoc

=cut
sub handleSocketError {
	my $self = shift;

	$self->logWarn("Problem with web listener.");
	warn "Problem with web listener, exitting...\n";
	return undef;
}

sub _get_client {
	my $self = shift;
	my $client;
	{
		lock(@{$self->{_avail_clients}});
		$client = pop @{$self->{_avail_clients}};
	}
	return $client ? $self->{_clients}[$client] : undef;
}

=pod

=begin classdoc

Set log level. Called from WebClient when loglevel
update is requested.

@simplex
@param $level		new log level

@return		1


=end classdoc

=cut
sub setLogLevel {
	my ($self, $level) = @_;

	$_->setLogLevel($level)
		foreach (@{$self->{_clients}});
	$self->{LogLevel} = $level;
	return 1;
}
=pod

=begin classdoc

Set IO::Select() interval. Called when
HTTP::Daemon::Threaded select interval is updated.

@simplex
@param $interval		new interval; fractional number of seconds

@return		1


=end classdoc

=cut
sub setListenInterval {
	$_[0]->{_sktsel}->setTimeout($_[1]);
}
=pod

=begin classdoc

Get IO::Select() interval. Called when HTTP::Daemon::Threaded
config info is requested.

@return		current listener interval


=end classdoc

=cut
sub getListenInterval {
	return $_[0]->{_sktsel}->getTimeout();
}

1;

