=pod

=begin classdoc


Abstract base class for SessionCache classes.
Provides an interface definition for
caching session context in a threads::shared container.
Provides a default implementation to create non-persistent
sessions. Also acts as a factory for Session objects.
<p>
<b>Note:</b> Applications needing to provide their own
session class implementations should subclass this class instead, and
provide an instance of the subclass as the HTTP::Daemon::Threaded
constructor's SessionCache parameter. Such subclass instances may then
manufacture session objects using their own Session
subclass.
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
package HTTP::Daemon::Threaded::SessionCache;

use threads;
use threads::shared;
use HTTP::Daemon::Threaded::Session;

use strict;
use warnings;

our $VERSION = '0.91';
=pod

=begin classdoc

Constructor. Creates threads::shared object to contain
any Session object that will be created.
<p>
Subclasses should extend this to open any session storage,
and possible pre-cache session contexts.

@return		HTTP::Daemon::Threaded::SessionCache object


=end classdoc

=cut

sub new {
	my $class = shift;
	my %sessions : shared = ();
	my %self : shared = (
		_cache => \%sessions
		);
	return bless \%self, $class;
}

=pod

=begin classdoc

Add a new session to the cache.

@param $session	HTTP::Daemon::Threaded::Session object
@return		the HTTP::Daemon::Threaded::Session object


=end classdoc

=cut
sub addSession {
	my ($self, $session) = @_;

	my $id = $session->getID();
	my $cache = $self->{_cache};
	$cache->{$id} = $session;
	return $session;
}

=pod

=begin classdoc

Remove a session from the cache.

@param $id	unique ID of session to be removed
@return		the HTTP::Daemon::Threaded::SessionCache object


=end classdoc

=cut
sub removeSession {
	my ($self, $id) = @_;
	my $cache = $self->{_cache};
	delete $cache->{$id};
	return $self;
}

=pod

=begin classdoc

Get a session from the cache.

@param $request	HTTP::Request object for which a session is to be located
@return		the HTTP::Daemon::Threaded::Session object if it exists; undef otherwise


=end classdoc

=cut
sub getSession {
	my ($self, $request) = @_;

#
#	strictly speaking, this can be multivalued...but we're
#	not gonna deal with that for now
#
	my $cookie = $request->header('Cookie');
#	print STDERR "Sorry, no cookie\n" and
	return undef
		unless $cookie;
#	print STDERR "Cookie is $cookie\n";
	$cookie = ';' . $cookie;	# normalize
	return undef
		unless ($cookie=~/;Session=([^;]+)/i);

	my $id = $1;
	my $cache = $self->{_cache};

#	print STDERR "ID is $id\n";

	return $cache->{$id}->setLastAccessedTime()
		if (exists $cache->{$id});

#	print STDERR "Session $id not found\n";
	my $session = $self->openSession($cookie);
	return $session ? $session->setLastAccessedTime() : undef;
}

=pod

=begin classdoc

Create a new session and store in the cache.

@param $id	<i>(optional)</i> unique ID of session to retrieve; default is whatever
the session object class generates
@param $timeout	<i>(optional)</i> max inactivity timeout; default is class specific
@param $dough		<i>(optional)</i> any information to be included in the session's cookie;
the $id will be prepended to this information
@param $expires	<i>(optional)</i> RFC1123 formatted cookie expiration date string, or
'Never'; default is single session (nonpersistent)

@return		undef if a session with the same ID already exists, or if the
session object cannot be created; otherwise,
the created HTTP::Daemon::Threaded::Session object


=end classdoc

=cut
sub createSession {
	my $self = shift;
	my $id = shift;

	my $cache = $self->{_cache};
	return undef
		if defined($id) && (exists $cache->{$id});
	my $session = HTTP::Daemon::Threaded::Session->new($self, $id, @_);
	return undef
		unless $session;
	$id = $session->getID();
	$cache->{$id} = $session;
	$session->setLastAccessedTime();
	return $session;
}

=pod

=begin classdoc

Recover an existing session from persistent storage.

@param $cookie <i>(required)</i> HTTP Cookie header containing unique ID of
session to retrieve

@return		undef if the session object cannot be recovered; otherwise,
the HTTP::Daemon::Threaded::Session object


=end classdoc

=cut
sub openSession {
	my ($self, $cookie) = @_;

	$cookie = ';' . $cookie;	# normalize
	my $id = ($cookie=~/;Session=([^;]+)/i);

	my $cache = $self->{_cache};
	return $cache->{$id}
		if exists $cache->{$id};

	my $session = HTTP::Daemon::Threaded::Session->open($id, $self);
	return undef
		unless $session;
	$id = $session->getID();
	$cache->{$id} = $session;
	return $session;
}

1;
