package Maypole::Authentication::UserSessionCookie;
use strict;
use warnings;
our $VERSION = '1.4';
use Apache::Cookie;
use URI;

=head1 NAME

Maypole::Authentication::UserSessionCookie - Track sessions and, optionally, users

=head1 SYNOPSIS

  use base qw(Apache::MVC Maypole::Authentication::UserSessionCookie);

    sub authenticate {
        my ($self, $r) = @_;
        $r->get_user;
        return OK if $r->{user};
        return OK if $r->{table} eq "user" and $r->{action} eq "subscribe";
        # Force them to the login page.
        $r->{template} = "login";
        return OK;
    }

=head1 DESCRIPTION

This module allows Maypole applications to have the concept of a user,
and to track that user using cookies and sessions.

It provides a number of methods to be inherited by a Maypole class. The
first is C<get_user>, which tries to populate the C<user> slot of the
Maypole request object.

=head2 get_user

    $r->get_user;

C<get_user> does this first by checking for a session cookie from the
user's browser, and if one is not found, calling C<check_credentials>,
whose behaviour will be described momentarily. If a session cookie is
found, the userid (C<uid>) is extracted and passing to C<uid_to_user>
which is expected to return a value (typically a C<User> object from the
model class representing the users of your system) to be stored in the
C<user> slot. The session hash is also placed in the C<session> slot of
the Maypole request for passing around user-specific session data.

=cut

sub get_user {
    my $r = shift;
    my $ar = $r->{ar};
    my $sid;
    my %jar = Apache::Cookie->new($ar)->parse;
    my $cookie_name = $r->config->{auth}{cookie_name} || "sessionid";
    if (exists $jar{$cookie_name}) { $sid = $jar{$cookie_name}->value(); }
    warn "SID from cookie: $sid";
    $sid = undef unless $sid; # Clear it, as 0 is a valid sid.
    my $new = !(defined $sid);
    my ($uid, $user);

    if ($new) {
        # Go no further unless login credentials are right.
        ($uid, $r->{user}) = $r->check_credentials;
        warn "Credentials OK";
        return 0 unless $uid;
    }
    warn "Giving cookie";
    $r->login_user($uid, $sid) or return 0;
    $r->{user} ||= $r->uid_to_user($r->{session}{uid});
    warn "User is : ".$r->{user};
}

=head2 login_user

This method is useful for the situation in which you've just created a user
from scratch, and want them to be logged in. You should pass in the user
ID of the user you want to log in.

=cut

sub login_user {
    my ($r, $uid, $sid) = @_;
    $sid = 0 unless defined $sid;
    my %session = ();
    my $session_class = $r->{config}{auth}{session_class} || 'Apache::Session::File';
    $session_class->require || die "Couldn't load session class $session_class";
    my $session_args  = $r->{config}{auth}{session_args} || {
        Directory     => "/tmp/sessions",
        LockDirectory => "/tmp/sessionlock",
    };
    eval {
        tie %session, $session_class, $sid, $session_args;
    };
    if ($@) { # Object does not exist in data store!
        if ($@ =~ /does not exist in data store/) {
            $r->_logout_cookie;
            return 0;
        } else { die $@ }
    }
    # Store the userid, and bake the cookie
    $session{uid} = $uid if $uid and not exists $session{uid};
    warn "Session's uid is $session{uid}";
    my $cookie_name = $r->config->{auth}{cookie_name} || "sessionid";
    my $cookie = Apache::Cookie->new($r->{ar},
        -name => $cookie_name,
        -value => $session{_session_id},
        -expires => $r->config->{auth}{cookie_expiry} || '',
        -path => URI->new($r->config->{base_uri})->path,
    );
    $cookie->bake();
    $r->{session} = \%session;
    return 1;
}

=head2 check_credentials

The C<check_credentials> method is expected to be overriden, but the
default implementation does what most people expect: it checks for the
two form parameters (typically C<user> and C<password> but configurable)
and does a C<search> on the user class for those values. See
L</Configuration> for how the user class is determined. This method
works well if the model class is C<Class::DBI>-based and may not work so
well otherwise.

C<check_credentials> is expected to return two values: the first will be
placed in the C<uid> slot of the session, the second is the user object
to be placed in C<$r->{user}>.

If the credentials are wrong, then C<$r->{template_args}{login_error}>
is set to an error string.

=cut

sub check_credentials {
    my $r = shift;
    my $user_class = $r->config->{auth}{user_class} || ((ref $r)."::User");
    $user_class->require || die "Couldn't load user class $user_class";
    my $user_field = $r->config->{auth}{user_field} || "user";
    my $pw_field = $r->config->{auth}{password_field} || "password";
    return unless exists $r->{params}{$user_field} and exists $r->{params}{$pw_field};
    my @users = $user_class->search(
        $user_field => $r->{params}{$user_field}, 
        $pw_field   => $r->{params}{$pw_field}, 
    );
    if (!@users) { 
        $r->{template_args}{login_error} = "Bad username or password";
        return;
    }
    return ($users[0]->id, $users[0]);
}

=head2 uid_to_user

By default, this returns the result of a C<retrieve> on the UID from the
user class. Again, see L</Configuration>.

=cut

sub uid_to_user {
    my $r = shift;
    my $user_class = $r->config->{auth}{user_class} || ((ref $r)."::User");
    $user_class->require || die "Couldn't load user class $user_class";
    $user_class->retrieve(shift);
}

=head2 logout

This method removes a user's session from the store and issues him a 
cookie which expires the old cookie.

=cut

sub logout {
    my $r = shift;
    delete $r->{user};
    tied(%{$r->{session}})->delete;
    $r->_logout_cookie;
}

sub _logout_cookie {
    my $r = shift;
    my $cookie = Apache::Cookie->new($r->{ar},
        -name => ($r->config->{auth}{cookie_name} || "session_id"),
        -value => undef,
        -path => URI->new($r->config->{base_uri})->path,
        -expires => "-10m"
    );
    $cookie->bake();
}

=head1 Session tracking without user authentication

For some application you may be interested in tracking sessions without
forcing users to log in. The way to do this would be to override 
C<check_credentials> to always return a new ID and an entry into some
shared storage, and C<uid_to_user> to look the user up in that shared
storage.

=head1 Configuration

The class provides sensible defaults for all that it does, but you can
change its operation through Maypole configuration parameters.

First, the session data. This is retrieved as follows. The Maypole
configuration parameter C<{auth}{session_class}> is used as a class to tie the session
hash, and this defaults to C<Apache::Session::File>. The parameters to the tie
are the session ID and the value of the C<{auth}{session_args}> configuration
parameter. This defaults to:

    { Directory => "/tmp/sessions", LockDirectory => "/tmp/sessionlock" }

For instance, you might instead want to say:

    $r->config->{auth} = {
        session_class => "Apache::Session::Flex",
        session_args  => {
            Store     => 'DB_File',
            Lock      => 'Null',
            Generate  => 'MD5',
            Serialize => 'Storable'
         }
    };

The cookie name is retrieved from C<{auth}{cookie_name}> but defaults to
"sessionid". It defaults to expiry at the end of the session, and this 
can be set in C<{auth}{cookie_expiry}>.

The user class is determined by C<{auth}{user_class}> in the
configuration, but attempts to guess the right user class for your
application otherwise. Probably best not to depend on that working.

The field in the user class which holds the username is stored in
C<{auth}{user_field}>, defaulting to "user"; similarly, the 
C<{auth}{password_field}> defaults to password.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

This may be distributed and modified under the same terms as Maypole itself.

=head1 SEE ALSO

L<Maypole>

=cut
