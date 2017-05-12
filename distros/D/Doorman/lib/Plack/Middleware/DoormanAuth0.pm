package Plack::Middleware::DoormanAuth0;
use 5.010;
use parent 'Doorman::PlackMiddleware';
use strict;
use LWP::UserAgent;
use JSON qw/decode_json/;
use namespace::autoclean;

our $VERSION   = "0.01";
our $AUTHORITY = "https://recollect.net";

use feature qw(say);
use Plack::Request;
use URI;

sub auth0_client_id     { shift->{auth0_client_id} }
sub auth0_client_secret { shift->{auth0_client_secret} }
sub auth0_domain        { shift->{auth0_domain} }
sub auth0_redirect_uri  {
    my $self = shift;
    return $self->{root_url} . '/' . $self->scope . '/sign_in/auth0';
}

sub session_hash {
    my ($self) = @_;
    my $session = $self->{env}->{'psgix.session'};
    my $k = "doorman.@{[ $self->scope ]}.auth0";

    return unless $session && $session->{$k};
    return $session->{$k};
}

sub auth0_email {
    my ($self) = @_;
    my $sh = $self->session_hash or return;
    return $sh->{"email"};
}

sub auth0_user_id {
    my ($self) = @_;
    my $sh = $self->session_hash or return;
    return $sh->{"user_id"};
}

sub is_sign_in {
    my ($self) = @_;
    return defined $self->auth0_email;
}

sub sign_out_path {
    my ($self) = @_;
    my $path = $self->SUPER::sign_out_path();
    return $path .= '/auth0';
}

sub call {
    my ($self, $env) = @_;

    $self->prepare_call($env);

    $env->{"doorman.@{[ $self->scope ]}.auth0"} = $self;

    my $request = Plack::Request->new($env);
    my $session = $env->{'psgix.session'} or die "Session is required for Auth0.";
    if ($request->method eq 'GET') {
        if ($request->path eq $self->sign_in_path . '/auth0') {
            my $code = $request->parameters->{code};
            $self->process_sign_in($session, $code);
        }
        elsif ($request->path eq $self->sign_out_path) {
            if ($session) {
                delete $session->{"doorman.@{[$self->scope]}.auth0"};
            }
        }
    }

    return $self->app->($env);
}

sub process_sign_in {
    my $self    = shift;
    my $session = shift;
    my $code    = shift or return;
    my $access_token = $self->_exchange_auth0_code_for_token($code) or return;
    my $profile = $self->_fetch_auth0_profile($access_token)        or return;

    $session->{"doorman.@{[ $self->scope ]}.auth0"} = {
        (map { $_ => $profile->{$_} }
            qw/user_id email identities
               name given_name family_name nickname picture/),
    };
}

sub _exchange_auth0_code_for_token {
    my $self = shift;
    my $code = shift;
    my $url = 'https://' . $self->auth0_domain . '/oauth/token';
    my $resp = $self->_ua->post( $url,
        'Content-type' => 'application/x-www-form-urlencoded',
        Content => {
            client_id     => $self->auth0_client_id,
            redirect_uri  => $self->auth0_redirect_uri,
            client_secret => $self->auth0_client_secret,
            code          => $code,
            grant_type    => 'authorization_code',
        },
    );

    if ($resp->is_success) {
        my $data = eval { decode_json($resp->content) } || {};
        if ($@) {
            warn "Auth0: Got invalid JSON in Auth exchange: "
                . "code=$code status_line=" . $resp->status_line
                . " error=$@";
            return undef;
        }
        return $data->{access_token};
    }

    warn "Auth0: Failed request for access token"
        . "code=$code status_line=" . $resp->status_line;
    return undef;
}

sub _fetch_auth0_profile {
    my $self = shift;
    my $access_token = shift;
    my $resp = $self->_ua->get(
        'https://' . $self->auth0_domain . '/userinfo',
        Authorization => "Bearer $access_token",
    );
    if ($resp->is_success) {
        my $data = eval { decode_json($resp->content) } || {};
        if ($@) {
            warn "Auth0: Got invalid JSON in /userinfo: "
                . "token=$access_token response="
                . $resp->status_line . "  error=$@";
            return undef;
        }
        return $data;
    }
    warn "Auth0: Failed request for /userinfo: "
        . "token=$access_token response=" . $resp->status_line;
    return undef;
}

sub _ua { LWP::UserAgent->new(agent => "DoormanAuth0/$VERSION") }

1;

__END__

=head1 NAME

Plack::Middleware::DoormanAuth0 - The Auth0 login middleware.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Session::Cookie";
        enable "DoormanAuth0",
            root_url => 'http://localhost:5000',
            scope => 'users',
            auth0_domain => 'my-app.auth0.com',
            auth0_client_secret => '...',
            auth0_client_id     => '...';

        # The app code.
        sub {
            my $env = shift;

            # Retrive the Plack::Middleware::DoormanAuth0 object
            my $doorman = $env->{'doorman.users.auth0'};

            # Check sign-in status
            my @out;
            if ($doorman->is_sign_in) {
                push @out, qq{Hi, @{[ $doorman->auth0_email ]}!}
            }
            else {
                push @out, qq{ Please login via Auth0! }
            }

            ...
        }
    };

=head1 DESCRIPTION

This middleware module implements the Auth0 OAuth2 login flow.

Before you use it, you need to create an account with Auth0, and create an app.

Auth0 will supply you with the client secret and ID, and you'll set a domain
for auth.  Doorman will use these secrets to validate requests.

You need to enable "Session" middleware.  The implementation requires
L<Plack::Middleware::Session> and stores relevant authentication information
under C<$env->{psgi.session}{doorman.${scope}.auth0}>, where C<$scope> is
the scope name given by you. You may inspect this variable at runtime to get
the basic idea of how the middleware stores relevant information.

The Middleware will store all Auth0 User Profile attributes into the
session key, where you may access them.

After that, you can invoke several methods listed down below on the
object stored in C<$env->{'doorman.users.auth0'}>, which is of this
<Plack::Middleware::DoormanAuth0> class.

=head1 METHODS

=over 4

=item * is_sign_in

Return true if the current session is considered signed in.

=item * auth0_email

Return the email address of the authenticated Auth0 user.

=back
