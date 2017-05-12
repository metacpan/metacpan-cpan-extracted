=pod

=begin classdoc


Abstract base class for Session classes.
Provides an interface definition for
a single threads::shared session context container.
Loosely based on the <a href='http://java.sun.com/j2ee/tutorial/1_3-fcs/doc/Servlets.html'>
Java Servlets</a> <a href='http://java.sun.com/j2ee/sdk_1.3/techdocs/api/javax/servlet/http/HttpSession.html'>
HttpSession</a> class.
<p>
<b>Note:</b> This implementation does not provide interfaces for user
authorization/authentication. The intent is to outsource such functionality
to the application level, which can populate and retrieve attributes
as needed, and apply any encryption or privileges in an application specific
manner. Future releases may provide stock objects providing common auth&amp;auth
functionality.
<p>
<b>Note2:</b> The default implementation does not support Set-Cookie2/Cookie2
HTTP headers.
<p>
Copyright&copy 2006-2008, Dean Arnold, Presicient Corp., USA<br>
All rights reserved.
<p>
Licensed under the Academic Free License version 3.0, as specified in the
License.txt file included in this software package, or at
<a href='http://www.opensource.org/licenses/afl-3.0.php'>OpenSource.org</a>.

@author D. Arnold
@since 2006-08-21
@self	$self
@see <a href='http://java.sun.com/j2ee/sdk_1.3/techdocs/api/javax/servlet/http/HttpSession.html'>HttpSession</a>
@see <a href='http://java.sun.com/j2ee/tutorial/1_3-fcs/doc/Servlets.html'>Java Servlets</a>


=end classdoc

=cut
package HTTP::Daemon::Threaded::Session;

use threads;
use threads::shared;
use Time::HiRes qw(time);

use strict;
use warnings;

our $VERSION = '0.91';

our $id_gen : shared = 0;

=pod

=begin classdoc

Constructor. Uses input ID, Inactivity timeout, cookie "dough"
and expiration timestamp to create a new session context.

@param $cache		<i>(required)</i> parent SessionCache object
@param $id		<i>(optional)</i> unique identifier for the session; default is generated from
an internal integer generator
@param $timeout	<i>(optional)</i> max inactivity timeout; default is 10 minutes
@param $dough		<i>(optional)</i> any information to be included in the session cookie;
the $id will be prepended to this information
@param $expires	<i>(optional)</i> RFC1123 formatted cookie expiration date string, or 'Never'; default
is single session (nonpersistent)

@return		HTTP::Response object


=end classdoc

=cut

sub new {
	my ($class, $cache, $id, $timeout, $dough, $expires) = @_;
	unless (defined($id)) {
#
#	if none provided, create our own
#
		lock($id_gen);
		$id_gen = int(time())
			unless $id_gen;
		$id = ++$id_gen;
	}

	my $cookie = (defined($dough) ? "Session=$id;$dough" : "Session=$id");
	$cookie .= ";Expires=$expires" if $expires;
	my %attrs : shared = ();
	my %self : shared = (
		_created	=> time(),
		_id			=> $id,
		_attributes => \%attrs,
		_max_inactive => $timeout || 600,
		_cookie_sent => undef,
		_cache		=> $cache,
		_last_access => time(),
		_expires	=> $expires,
		_cookie		=> $cookie
	);
	return bless \%self, $class;
}

=pod

=begin classdoc

Constructor. Uses input identifier to load a session context
from persistent storage.
<p>
<b>NOTE:</b> this default implementation simply returns undef,
as it does not use persistent storage

@param $id		unique identifier for the session to be recovered
@param $cache		parent SessionCache object

@return		undef if the session cannot be recovered, otherwise, the
HTTP::Daemon::Threaded::Session object


=end classdoc

=cut

sub open {
	my ($class, $id, $cache) = @_;
	return undef;
}

=pod

=begin classdoc

Closes this session and removes it from the parent SessionCache.
May cause any underlying persistent session store to delete its
version of the session.

@return	undef (to optimize clearing any containers)


=end classdoc

=cut
sub close {
	my $self = shift;
	lock(%$self);
	$self->{_cache}->removeSession($self->{_id});
	delete $self->{_cache};
	return undef;
}

=pod

=begin classdoc

Returns the object bound with the specified name.

@param $name	name of attribute to retrieve

@return	the value of the named attribute (if any)


=end classdoc

=cut
sub getAttribute {
	my ($self, $name) = @_;
	lock(%$self);
	return $self->{_attributes}{$name};
}

=pod

=begin classdoc

Returns the list of attributes bound to this session.

@returnlist	the alphabetically sorted list of attribute names


=end classdoc

=cut
sub getAttributeNames {
	my $self = shift;
	lock(%$self);
	return sort keys %{$self->{_attributes}};
}

=pod

=begin classdoc

Removes the object bound to the specified name from this session.

@param $name	name of attribute to remove
@return 	the value of the removed attribute


=end classdoc

=cut
sub removeAttribute {
	my ($self, $name) = @_;
	my ($cookie, $key, $val) = ('', '', '');

	lock(%$self);
	my $attrs = $self->{_attributes};
	my $expires = $self->{_expires};
	my $old = delete $attrs->{$name};
	$cookie .= "$key=$val;"
		while (($key, $val) = each %$attrs);

	chop $cookie;
	$cookie .= ";Expires=$expires" if $expires;
	$self->{_cookie} = $cookie;
	return $old;
}

=pod

=begin classdoc

Set an attribute on this session, using the name specified.
<p>
<b>NOTE:</b> Since Session objects are threads shared, their
attributes hash is also threads::shared, which means that
any non-scalar values to be assigned to an attribute must
also be threads::shared.

@param $name	name of attribute to set
@param $value	value of the attribute to set
@return 	the Session object


=end classdoc

=cut
sub setAttribute {
	my ($self, $name, $value) = @_;
	my ($cookie, $key, $val) = ('', '', '');

	lock(%$self);
	my $attrs = $self->{_attributes};
	my $expires = $self->{_expires};
	$attrs->{$name} = $value;
	$cookie .= "$key=$val;"
		while (($key, $val) = each %$attrs);

	chop $cookie;
	$cookie .= ";Expires=$expires" if $expires;
	$self->{_cookie} = $cookie;

	return $self;
}

=pod

=begin classdoc

Get expiration on this session.

@return 	the RFC1123 formatted expiration (if any)


=end classdoc

=cut
sub getExpiration {
	my $self = shift;

	lock(%$self);
	return $self->{_expires};
}

=pod

=begin classdoc

Set expiration on this session. If no date is given,
then the cookie is expired.

@param $expires	RFC1123 expiration timestamp

@return 	the Session object


=end classdoc

=cut
sub setExpiration {
	my ($self, $expires) = @_;

	lock(%$self);
	$self->{_expires} = $expires;
	my $cookie = $self->{_cookie};
	$cookie=~s/;Expires=.*$//;
	$cookie .= ";Expires=$expires"
		if $expires;
	$self->{_cookie} = $cookie;

	return $self;
}

=pod

=begin classdoc

Returns the creation time of this session as a fractional number.
<p>
<b>NOTE:</b> As a read operation on a static value, no lock is required.

@return 	the creation time of the session as a floating point number of seconds
since the epoch.


=end classdoc

=cut
sub getCreationTime {
	my $self = shift;
	return $self->{_created};
}

=pod

=begin classdoc

Returns the unique ID time of this session
<p>
<b>NOTE:</b> As a read operation on a static value, no lock is required.

@return 	the ID string


=end classdoc

=cut
sub getID {
	my $self = shift;
	return $self->{_id};
}

=pod

=begin classdoc

Returns the last time the client sent a request for this session.

@return 	the time as a floating point number of seconds sinc the epoch


=end classdoc

=cut
sub getLastAccessedTime {
	my $self = shift;
	lock(%$self);
	return $self->{_last_access};
}

=pod

=begin classdoc

Set the last time the client sent a request for this session.

@return 	this Session object


=end classdoc

=cut
sub setLastAccessedTime {
	my $self = shift;
	lock(%$self);
	$self->{_last_access} = time();
	return $self;
}

=pod

=begin classdoc

Returns the last time the client sent a request for this session.

@return 	the time as a floating point number of seconds sinc the epoch


=end classdoc

=cut
sub getMaxInactiveInterval {
	my $self = shift;
	lock(%$self);
	return $self->{_max_inactive};
}

=pod

=begin classdoc

Set the max inactivity interval, in seconds, for this session.

@param $timeout	inactivity interval in seconds
@return 	this Session object


=end classdoc

=cut
sub setMaxInactiveInterval {
	my $self = shift;
	lock(%$self);
	$self->{_max_inactive} = $_[0];
	return $self;
}

#
#	should we also apply the cookie expiration here ?
#
=pod

=begin classdoc

Has this session timed out ?

@return 	boolean true if the inactivity timeout has expired; else false


=end classdoc

=cut
sub isInactive {
	my ($self, $idle) = @_;
	lock(%$self);
	return ($self->{_max_inactive} < (time() - $idle));
}

=pod

=begin classdoc

Returns true if the cookie for the session has not yet been sent to the client.
Note that this session instance may have been revivified from persistent storage,
and has not yet sent its cookie to the client, but the client has previously
stored the cookie, in which case this method should return false.

@return 	1 if the cookie has not been sent, undef otherwise


=end classdoc

=cut
sub isNew {
	my $self = shift;
	lock(%$self);
	return !$self->{_cookie_sent};
}

=pod

=begin classdoc

Called to indicate that the cookie has been sent to the client.
<p>
<b>Note:</b> Subclasses which implement <code>open()</code> should
already set this flag when a session is successfully recovered.

@return 	this Session object


=end classdoc

=cut
sub cookieSent {
	my $self = shift;
	lock(%$self);
	$self->{_cookie_sent} = 1;
	return $self;
}

=pod

=begin classdoc

Returns this session's cookie

@return 	the cookie string, including the unique session ID, and any dough and/or
expiration date supplied when the session was created


=end classdoc

=cut
sub getCookie {
	my $self = shift;
	lock(%$self);
	return $self->{_cookie};
}

1;
