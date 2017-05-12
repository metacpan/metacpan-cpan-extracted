package EntityModel::Web::Apache2::Session;
BEGIN {
  $EntityModel::Web::Apache2::Session::VERSION = '0.001';
}
use EntityModel::Class {
	session	=> 'data',
}; 

use Apache2::Cookie;
use APR::UUID;

use EntityModel::Web::Session;

sub new {
	my $class = shift;
	my $r = shift;

	my $self = {
		r	=> $r,
		jar	=> Apache2::Cookie::Jar->new($r)
	};
	bless $self, $class;
	return $self;
}

=head2 is_logged_in

Returns the session if we are logged in.

=cut

sub is_logged_in {
	my $self = shift;

	unless ($self->{ _session }) {
		my @cookieList = $self->{ jar }->cookies(EntityModel::Config::CookieName);
		my $session;
		foreach (@cookieList) {
			logDebug("Checking cookie [%s]", $_->value);
			last if $session = EntityModel::Session->checkUUID($_->value);
		}
		logDebug("Got session for user " . ($session->user ? $session->user->login : 'unknown')) if $session;
		$self->{ _session } = $session;
	}
	return $self->{ _session };
}

sub session { shift->{_session}; }

=head2 create_session

Create a new user login session, recording the activity in the audit log and applying
to the current auth cookie.

=cut

sub create_session {
	my $self = shift;
	my $user = shift;

	my $token = APR::UUID->new->format;
	logDebug("Creating the session with %s as %s", $user, $token);
	my $session = EntityModel::Session->create({
		user		=> $user,
		token		=> $token
	});

	$user->audit({
		action	=> 'login',
		session	=> $token,
		addr	=> eval { $self->{ r }->connection->remote_ip; }
	});

	my $cookie = Apache2::Cookie->new(
		$self->{ r },
		-name		=> EntityModel::Config::CookieName,
		-domain		=> EntityModel::Config::CookieDomain,
		-path		=> '/',
		-expires	=> '+1h',
		-value		=> $session->token
	);
	logDebug("Bake the cookie");
	$cookie->bake($self->{ r });
	logDebug("Done");
}

=head2 delete_session

Remove all session information, including browser cookies, to log out the
currently-active user.

=cut

sub delete_session {
	my $self = shift;
	return logError("No session") unless $self->session;

	my $user = $self->session->user;
	logDebug("Deleting the current session for ", $user);
	$user->audit({
		action	=> 'logout',
		session	=> $self->session->token,
		addr	=> eval { $self->{ r }->connection->remote_ip; }
	});
	$self->session->remove;

	my $cookie = Apache2::Cookie->new(
		$self->{ r },
		-name		=> EntityModel::Config::CookieName,
		-domain		=> EntityModel::Config::CookieDomain,
		-path		=> '/',
		-expires	=> '0',
		-value		=> ''
	);
	logDebug("Apply new cookie data");
	$cookie->bake($self->{ r });
	logDebug("Done");
	return $self;
}

1;
