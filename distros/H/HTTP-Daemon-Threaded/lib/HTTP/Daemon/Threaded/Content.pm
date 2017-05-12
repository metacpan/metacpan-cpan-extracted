=pod

=begin classdoc

 Base class for Content classes.
 Provides an interface definition for
 generating or storing content, or generating a header,
 given an HTTP::Request, a URI, URL parameters or POSTed content,
 HTTP::Daemon::Threaded::SessionCache object, and
 a HTTP::Daemon::Threaded::ContentParams context
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

package HTTP::Daemon::Threaded::Content;

use HTTP::Daemon::Threaded::Logable;
use base qw(HTTP::Daemon::Threaded::Logable);

use strict;
use warnings;

our $VERSION = '0.91';

=pod

=begin classdoc


 Constructor. Stores ContentParams, SessionCache, and Logger objects,
 and performs any content-specific initialization.

 @param LogLevel		<i>(optional)</i> logging level; 1 => errors only; 2 => errors and warnings only; 3 => errors, warnings,
						and info messages; default 1
 @param EventLogger 	<i>(optional)</i> Instance of a HTTP::Daemon::Threaded::Logger to receive
						event notifications (except for web requests)
 @param SessionCache	<i>(optional)</i> threads::shared object implementing HTTP::Daemon::Threaded::SessionCache
 @param ContentParams	<i>(optional)</i> name of a ContentsParam concrete implementation

 @returns a HTTP::Daemon::Threaded::Content object

=end classdoc

=cut

sub new {
	my ($class, %args) = @_;
	return bless \%args, $class;
}

=pod

=begin classdoc


 Generate and send content. Uses input URI, URL parameters, Cookie and Session
 objects to load and/or generate content, including
 providing any needed HTTP headers. Note that the <code>$params</code>
 parameter <i>may</i> be an array of multipart HTTP::Message objects if
 a multipart POST request was received (e.g., for file upload).
 <p>
 Content handlers should restrict the HTTP::Daemon::ClientConn response
 methods to <code>send_response(), send_file_response(), send_error(), or
 send_redirect()</code>, as HTTP::Daemon::Threaded::Socket provides
 automatic web logging for those methods.

 @param $fd		HTTP::Daemon::Threaded::Socket object for the client
 @param $request	HTTP::Request object
 @param $uri		request URI
 @param $params	hashref of URL parameters (key => value) OR arrayref of HTTP::Message
					objects (for multipart POSTs)
 @param $session	<i>(optional)</i> a HTTP::Daemon::Threaded::Session object,
					if the application configured a SessionCache class, and if WebClient
					was able to recover an existing session from such a SessionCache.
=end classdoc

=cut

sub getContent {
	my ($self, $fd, $request, $uri, $params, $session) = @_;
	$fd->send_error(404);
}

=pod

=begin classdoc


 Generate and send content header only. Uses input URI, URL parameters, Cookie
 and Session objects to load and/or generate content, including
 providing any needed HTTP headers.
 <p>
 Content handlers should restrict the HTTP::Daemon::ClientConn response
 methods to <code>send_response(), send_file_header(), send_error(), or
 send_redirect()</code>, as HTTP::Daemon::Threaded::Socket provides
 automatic web logging for those methods.

 @param $fd		HTTP::Daemon::Threaded::Socket object for the client
 @param $request	HTTP::Request object
 @param $uri		request URI
 @param $params	hashref of URL parameters (key => value)
 @param $session	<i>(optional)</i> a HTTP::Daemon::Threaded::Session object,
					if the application configured a SessionCache class, and if WebClient
					was able to recover an existing session from such a SessionCache.
=end classdoc

=cut

sub getHeader {
	my ($self, $fd, $request, $uri, $params, $session) = @_;
	$fd->send_error(404);
}

=pod

=begin classdoc


 Put content. Uses input URI, URL parameters, Cookie and Session
 objects to process received content (via PUT request), including
 providing any needed HTTP headers.
 <p>
 Content handlers should restrict the HTTP::Daemon::ClientConn response
 methods to <code>send_response(), send_file_response(), send_file_header(), send_error(), or
 send_redirect()</code>, as HTTP::Daemon::Threaded::Socket provides
 automatic web logging for those methods.

 @param $fd		HTTP::Daemon::Threaded::Socket object for the client
 @param $request	HTTP::Request object
 @param $uri		request URI
 @param $content	decoded PUT content
 @param $session	<i>(optional)</i> a HTTP::Daemon::Threaded::Session object,
					if the application configured a SessionCache class, and if WebClient
					was able to recover an existing session from such a SessionCache.
=end classdoc

=cut

sub putContent {
	my ($self, $fd, $request, $uri, $content, $session) = @_;

	$fd->send_error(401);
}

=pod

=begin classdoc


 Set a response cookie. Convenience method to format and set a Set-Cookie header.

 @param $res	HTTP::Response object
 @param $session HTTP::Daemon::Threaded::Session object from which to extract the cookie.

 @return 	this Content object
=end classdoc

=cut

sub setCookie {
	my ($self, $res, $session) = @_;

	$res->header('Set-Cookie' => $session->getCookie());
	return $self;
}

1;
