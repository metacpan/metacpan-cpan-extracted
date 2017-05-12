package Plack::Middleware::DoormanTwitter;
use 5.010;
use parent 'Doorman::PlackMiddleware';
use strict;

our $VERSION   = "0.06";
our $AUTHORITY = "http://gugod.org";

use feature qw(say);
use Plack::Request;
use Plack::Util::Accessor qw(consumer_key consumer_secret);
use URI;
use Scalar::Util qw(weaken);
use Net::Twitter::Lite;

sub twitter {
    my ($self) = @_;

    my $nt = Net::Twitter::Lite->new(
        consumer_key    => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        legacy_lists_api => 0,
    );

    my $access = $self->twitter_access;
    if ($access) {
        $nt->access_token($access->{access_token});
        $nt->access_token_secret($access->{access_token_secret});
    }

    return $nt;
}

sub twitter_access {
    my ($self) = @_;
    my $env = $self->{env};
    my $session = $env->{'psgix.session'};
    my $scope = $self->scope;

    my $t = $session->{"doorman.${scope}.twitter"};

    if ($t->{"access_token"} && $t->{"access_token_secret"}) {
        return {
            access_token        => $t->{"access_token"},
            access_token_secret => $t->{"access_token_secret"}
        }
    }

    return;
}

sub twitter_verified_url {
    my ($self) = @_;
    return $self->scope_url . "/twitter_verified";
}

sub twitter_verified_path {
    my ($self) = @_;
    return URI->new($self->twitter_verified_url)->path;
}

sub twitter_screen_name {
    my ($self) = @_;
    my $session = $self->{env}->{'psgix.session'};
    my $k = "doorman.@{[ $self->scope ]}.twitter";

    return unless $session && $session->{$k};

    return $session->{$k}{"screen_name"};
}

sub is_sign_in {
    my ($self) = @_;
    return defined $self->twitter_screen_name;
}

sub call {
    my ($self, $env) = @_;

    $self->prepare_call($env);

    $env->{"doorman.@{[ $self->scope ]}.twitter"} = $self;

    my $request = Plack::Request->new($env);
    my $session = $env->{'psgix.session'} or die "Session is required for Twitter OAuth.";

    if ($request->method eq 'GET') {
        if ($request->path eq $self->sign_in_path) {
            my $nt = $self->twitter;
            my $url = $nt->get_authentication_url(callback => $self->twitter_verified_url);

            $session->{"doorman.@{[ $self->scope ]}.twitter.oauth"} = {
                token => $nt->request_token,
                token_secret => $nt->request_token_secret
            };

            return [302, [Location => $url->as_string], ['']];
        }
        elsif ($request->path eq $self->twitter_verified_path) {
            return $self->app->($env) if $request->param('denied');

            my $verifier = $request->param('oauth_verifier');
            my $oauth = $session->{"doorman.@{[ $self->scope ]}.twitter.oauth"};
            my $nt = $self->twitter;
            $nt->request_token($oauth->{token});
            $nt->request_token_secret($oauth->{token_secret});

            my ($access_token, $access_token_secret, $user_id, $screen_name)
                = $nt->request_access_token(verifier => $verifier);

            $session->{"doorman.@{[ $self->scope ]}.twitter"} = {
                access_token        => $access_token,
                access_token_secret => $access_token_secret,
                user_id             => $user_id,
                screen_name         => $screen_name
            };

            delete $session->{"doorman.@{[ $self->scope ]}.twitter.oauth"};
        }
        elsif ($request->path eq $self->sign_out_path) {
            if ($session) {
                delete $session->{"doorman.@{[$self->scope]}.twitter"};
            }
        }
    }

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::DoormanTwitter - The OAuth-based Twitter login middleware.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Session::Cookie";
        enable "DoormanTwitter", root_url => 'http://localhost:5000', scope => 'users',
            consumer_key    => "XXXX",
            consumer_secret => "YYYY";

        # The app code.
        sub {
            my $env = shift;

            # Retrive the Plack::Middleware::DoormanTwitter object
            my $doorman = $env->{'doorman.users.twitter'};
            my @out;

            # Check sign-in status, and provide sign-out link or sign-in link in the output.
            if ($doorman->is_sign_in) {
                push @out, qq{Hi, @{[ $doorman->twitter_screen_name ]}, <a href="@{[ $doorman->sign_out_path ]}">Logout</a>}
            }
            else {
                push @out, qq{ <a href="@{[ $doorman->sign_in_path ]}">Login</a>}
            }

            ...
        }
    };

=head1 DESCRIPTION

This middleware module implements the OAuth Twitter login flow
depicted here: L<http://dev.twitter.com/pages/sign_in_with_twitter>.

Before you use it, you need to register your application at
L<http://dev.twitter.com/> in order to get the consumer key and
secret. Also, this middleware requires you to specify `callback url`
of your app to be, for example, the root url of you
application. Basically in need something other then blank string or
"oob".

Second, the middleware requires you to specify the root URL in
the app builder in order to properly build the real callback URL
and many other URLs as the parameter for api.twitter.com.

Third, you need to name your authentication scope like "users". This
may sound awkward and unnecessary but it allows the flexibility to
allow multiple set of login. For example, you app can have a "users"
scope for whoever sign-in from from twitter, and a "admin" scope from
password-based authentication.

Last, and the most important, you need to enable "Session" middleware.
The implementation requires L<Plack::Middleware::Session> and stores
relevant authentication information under
C<$env->{psgi.session}{doorman.${scope}.twitter}>, where C<$scope> is
the scope name given by you. You may inspect this variable at runtime
to get the basic idea of how the middleware stores relevant
information.

After that, you can invoke several methods listed down below on the
object stored in C<$env->{'doorman.users.twitter'}>, which is of this
<Plack::Middleware::DoormanTwitter> class.

=head1 METHODS

=over 4

=item * is_sign_in

Return true if the current session is considered signed in.

=item * twitter_screen_name

Return the twitter screen name of the authenticated user.

=item * twitter_access

Returns a hash reference with keys: "access_token" and
"access_token_secret", which is the token you can use to act as the
current authenticated twitter user.

If the user did not authorize your request yet, this method returns
undef.

=item * twitter

Returns a L<Net::Twitter::Lite> object that you can use to perform api
calls, like posting a new status update.

=back
