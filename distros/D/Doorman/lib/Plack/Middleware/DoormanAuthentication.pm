package Plack::Middleware::DoormanAuthentication;
use 5.010;
use strict;

our $VERSION   = "0.06";
our $AUTHORITY = "http://gugod.org";

use parent 'Doorman::PlackMiddleware';

use Plack::Util::Accessor qw(authenticator);
use Plack::Session;

sub is_sign_in {
    $_[0]->session_get("authenticated");
}

sub call {
    my ($self, $env) = @_;

    $self->prepare_call($env);

    $env->{ $self->fq } = $self;

    my $request = Plack::Request->new($env);

    if ($request->method eq 'POST' and $request->path eq $self->sign_in_path) {
        my ($success, $error_message) = $self->authenticator->($self, $self->{env});
        if ($success) {
            $self->session_set("authenticated" => $success);
        }
        else {
            $self->env_set("error" => $error_message);
        }
    }
    elsif ($request->method eq 'GET' and $request->path eq $self->sign_out_path) {
        $self->session_remove("authenticated");
    }

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::DoormanAuthentication - The generic authentication middleware.

=head1 SYNOPSIS

    use Plack::Request;
    use Plack::Builder;

    builder {
        enable "Session";
        enable "DoormanAuthentication", authenticator => sub {
            my ($self, $env) = @_;
            my $request = Plack::Request->new($env);
            return $request->param("username")
                if $request->param("username") eq "john" && $request->param("password") eq "secret";
        };

        sub {
            my $env = shift;
            my $doorman = $env->{'doorman.users.authentication'};
            my $current_username = $doorman->is_sign_in;

            ...
        }
    };

=head1 DESCRIPTION

This middleware is for doing generic authentication. In other words,
it does not do the real authenticate at all, but merely just keep the
authentication info that your (the developer) provide from the
authenticator callback in the session.

=head1 OPTIONS

=over 4

=item * authenticator

This setting is mandatory, and it must be a CODEref callback that will
be called once this middleware need to do the real authentication work.

Here's an simple example that only authenticate "john" with correct password:

    enable "DoormanAuthentication", authenticator => sub {
        my ($self, $env) = @_;
        my $request = Plack::Request->new($env);
        return $request->param("username")
            if $request->param("username") eq "john" && $request->param("password") eq "secret";
    };

The authenticator callback is called as a method of an instance of
this middleware class, with the PSGI C<$env> hash as its sole method
parameter. For most web apps the authenticator checks certain form
fields like the examples above. If the authenticator is based on
request headers but not only form fields, it is still feasible by
building a L<Plack::Request> object from C<$env>.

The authenticator callback should return a false value (0 or undef)
when the sign-in request is not considered successful (eg, wrong
password). It should return an id of some sort for your app code to
latter retrieve user information from database. A numerical id or
username might work.

The returned value of the authenticator callback is kept in the
session and used to decide if current session is considered signed in.

=item * scope

This setting is optional with default value "users", and useful if you
need multiple roles to login in to your system.

For example, if you need "users" and "admins" roles to have different login session,
you can achieve it by:

    enable "DoormanAuthentication", scope => "users";
    enable "DoormanAuthentication", scope => "admins";

For each scope, a path named after that scope is taken by DoormanAuthentication middleware
as the end-points to perforam openid login.

By default, the following paths and HTTP methods are responded by this middleware:

    POST /users/sign_in
    GET  /users/sign_out
    GET  /users/openid_verified

For the "admins" scope, it'll add:

    POST /admins/sign_in
    GET  /admins/sign_out
    GET  /admins/openid_verified

=back

=head1 METHODS

=over 4

=item * sign_in_path, sign_in_url

Returns a path, or full url, that is used to let user POST an openid
url to sign in. It should be used as the value of "action" attribute
of a form. For example, like in this form:

    my $doorman = $env->{'doorman.users.authentication'};

    my $sign_in_form = <<HTML5;
    <form method="POST" action="@{[ $doorman->sign_in_path ]}">
      <p>
        <label>Username</label>
        <input type="text" name="username" autofocus>
      </p>
      <p>
        <label>Password</label>
        <input type="password" name="password">
      </p>
      <p>
        <input type="submit" value="Sign In">
      </p>
    </form>
    HTML5

The form uses C<username> and C<password> as the name of the fields.
Accordingly, the authenticator callback should be coded to authenticate
users by those values. In other words, you must choose the field names
that will be used to authenticate, and you need to properly code HTML and
authenticator callback to put them together.

=item * is_sign_in

Returns true if the current session is considered signed in.

In fact, it returns the return value of the authenticator callback. It
is recommended that your authenticator callback returns a primary key
to the authenticated user, and use that value to retrieve the user
object from whatever backend database you use:

    my $app = sub {
        my $env = shift;
        my $doorman = $env->{'doorman.users.authentication'};

        my $current_user = MyModel::User->load( $doorman->is_sign_in );

        ...
    };

=item * sign_out_path, sign_out_url

Returns a path that, when visited (GET), wipes out the signed in
information from the session.

=back
