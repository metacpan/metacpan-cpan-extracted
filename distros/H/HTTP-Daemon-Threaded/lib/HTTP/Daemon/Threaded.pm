=pod

=begin classdoc

Apartment threaded web server. Creates and maintains a pool of WebClient
apartment threaded objects. Permits application specific content and session
handler objects.
<p>
Copyright&copy 2006, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2006-08-21
@self	$self
@see  HTTP::Daemon::Threaded::Listener
@see  HTTP::Daemon::Threaded::Logable
@see  HTTP::Daemon::Threaded::Logger
@see  HTTP::Daemon::Threaded::WebClient
@see  HTTP::Daemon::Threaded::Content
@see  HTTP::Daemon::Threaded::ContentParams
@see  HTTP::Daemon::Threaded::SessionCache
@see  HTTP::Daemon::Threaded::Session



=end classdoc

=cut
package HTTP::Daemon::Threaded;

use threads;
use Thread::Apartment;

use base qw(Thread::Apartment);

use strict;
use warnings;

our $VERSION = '0.91';

our $container;
our $timeout;

=pod

=begin classdoc

Set TQD timeout.

@static
@param $timeout TQD timeout in seconds

@return		none


=end classdoc

=cut
sub setTimeout { $timeout = ($_[0] eq 'HTTP::Daemon::Threaded') ? $_[1] : $_[0]; }

=pod

=begin classdoc

Constructor. Provides facade for Thread::Apartment::new,
to create a TAS for HTTP::Daemon::Threaded::Listener.
Allocates or creates a thread, and installs a Listener in it.
<p>
Note that the following parameters are recognized by
HTTP::Daemon::Threaded, HTTP::Daemon::Threaded::Listener, and/or
HTTP::Daemon::Threaded::WebClient, but
applications may supply additional parameter key/value pairs
which will be provided to the constructor for any specified
HTTP::Daemon::Threaded::ContentParams class.

@param AptTimeout		<i>(optional)</i> Thread::Apartment proxy return timeout
@param Port			<i>(optional)</i> TCP listen port; default 80.
@param MaxClients		<i>(optional)</i> max number of client handlers to spawn;
default 5
@param LogLevel		<i>(optional)</i> logging level; 1 => errors only; 2 => errors and warnings only; 3 => errors, warnings,
and info messages; default 1
@param EventLogger	<i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
event notifications (except for web requests)
@param WebLogger		<i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
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
an arrayref of string literals, e.g.,<br>
<code>MediaTypes =&gt; { 'text/css' => 'css' }</code>. Used to
add media types for LWP::MediaTypes::guess_media_type()

@return		TAC proxy for HTTP::Daemon::Threaded::Listener object
@see <a href='http://search.cpan.org/search?mode=module&query=LWP::MediaTypes'>LWP::MediaTypes</a>


=end classdoc

=cut
sub new {
#
#	overrides T::A new, returning the container object
#
	my ($class, %args) = @_;

	$args{AptClass} = 'HTTP::Daemon::Threaded::Listener';
	$args{AptTimeout} = $timeout
		unless exists $args{AptTimeout};

	$container = Thread::Apartment->new( %args )
		|| die "Could not install into an apartment: $@.";
	return $container;
}

1;

