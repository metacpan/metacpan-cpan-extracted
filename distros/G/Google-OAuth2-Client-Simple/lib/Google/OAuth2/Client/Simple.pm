package Google::OAuth2::Client::Simple;
# ABSTRACT: OAuth lib for Google OAuth 2.0
$Google::OAuth2::Client::Simple::VERSION = '0.004';
use Carp;
use Cpanel::JSON::XS;
use Furl;
use Moo;
use URI;

=head1 NAME

Google::OAuth2::Client::Simple - Client for Google OAuth2.

=head1 SYNOPSIS

    use Google::OAuth2::Client::Simple;

    my $google_client = Google::OAuth2::Client::Simple->new(
        client_id => $config->{client_id},
        client_secret => $config->{client_secret},
        redirect_uri => $config->{redirect_uri},
        scopes => ['https://www.googleapis.com/auth/drive.readonly', '...'],
    );

    within some page that connects to googleapis:
    if ( !$app->access_token() ) {
        $response = $google_client->request_user_consent();
        $response->content(); #show Googles html form to the user
    }

    then in your 'redirect_uri' route:
    my $token_ref = $google_client->exchange_code_for_token($self->param('code'), $self->param('state'));
    $app->access_token($token_ref->{access_token}); # set the access token somewhere (maybe in cache?), it lasts for an hour

=head1 DESCRIPTION

A client library that talks to Googles OAuth 2.0 API, found at:
https://developers.google.com/identity/protocols/OAuth2WebServer

Provides methods to cover the whole OAuth flow to get an access token and connect to the Google API.

To get credentials, register your app by following the instructions under "Creating web application credentials":
https://developers.google.com/identity/protocols/OAuth2WebServer

Valid scopes can be found here:
https://developers.google.com/identity/protocols/googlescopes

=head1 NOTE

It should be noted that token storage should be something handled by your application, if persistent usage is a requirement.
This client library doesn't do that because, well, it's simple ;)

=cut

has client_id => ( is => 'ro', required => 1 );
has client_secret => ( is => 'ro', required => 1 );
has redirect_uri => ( is => 'ro', required => 1 );

has login_hint => ( is => 'ro' );
has prompt => ( is => 'ro', default => sub { return 'consent' } );
has access_type => ( is => 'ro', default => sub { return 'offline' } );

has auth_uri => (
    is => 'ro',
    default => sub { return 'https://accounts.google.com/o/oauth2/v2/auth' }
);

has token_uri => (
    is => 'ro',
    default => sub { return 'https://www.googleapis.com/oauth2/v4/token' }
);

has revoke_uri => (
    is => 'ro',
    default => sub { return 'https://accounts.google.com/o/oauth2/revoke' }
);

has scopes => (
    is => 'rw',
    isa => sub {
        Carp::confess("Expecting scope to be an arrayref") unless ref($_[0]) eq 'ARRAY';
    },
    clearer => 1,
    required => 1,
);

has include_granted_scopes => (
    is => 'ro',
    isa => sub {
        Carp::confess("Only the strings 'true' or 'false' are valid options") unless $_[0] =~ m/^true|false$/;
    }
);

has state => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return shift->client_id;
    },
);

has ua => (
    is => 'ro',
    default => sub {
        return Furl->new();
    },
);

=head2 request_user_consent

Returns a Furl::Response, the contents of which will contain Googles
sign in form. Once the user signs in they will be shown a list of
scopes your application is requesting, and will either allow or
deny you permission.

This method should be called to start the oauth flow, meaning
before trying to exchange the code for an access token.

Once the user gives consent successfully, they will be redirected to
$self->redirect_uri which will contain 'code' and 'state' params.
The 'code' is used to exchange it for an access token.

For example, in a CGI file you can do something like: C<< print $response->content(); >>

Or in an application framework like Mojolicious: C<< return $self->render( html => $response->content() ); >>

=cut

sub request_user_consent {
    my ($self) = @_;

    my %params = (
        response_type   => 'code',
        client_id       => $self->client_id,
        redirect_uri    => $self->redirect_uri,
        state           => $self->state,
        scope           => join(' ', @{$self->scopes}),
        access_type     => $self->access_type,
        prompt          => $self->prompt,
    );
    $params{login_hint} = $self->login_hint if $self->login_hint;
    $params{include_granted_scopes} = $self->include_granted_scopes if $self->include_granted_scopes;

    my $uri = URI->new($self->auth_uri);
    $uri->query_form(\%params);

    my $response = $self->_request(
        method => 'GET',
        url => $uri->as_string
    );

    return $response;
}

=head2 exchange_code_for_token($code)

Returns a I<HashRef> of token data which looks like:

    {
      "access_token":"1/fFAGRNJru1FTz70BzhT3Zg",
      "expires_in":3920,
      "token_type":"Bearer",
      "refresh_token":"XXXXXXXX"
    }

This method should be called once you successfully retrieved a 'code'
from request_user_consent(), to end the oauth process by getting
an access_token.

'refresh_token' is only returned from Google if the access_type was 'offline' when
requesting user consent and it was the first time the access token was received.
It should be saved in long term storage as stated in the documentation for you
to be able to refresh access tokens for persistent usage.

=cut

sub exchange_code_for_token {
    my ($self, $code, $state) = @_;

    unless ( $code ) {
        Carp::confess("No auth code provided. An auth code must be requested before generating a token.");
    }

    if ( $state ) {
        if ( $self->state ne $state ) {
            Carp::confess("State mismatch. This could be a malicious attempt, process aborted.");
        }
    }

    my %params = (
        grant_type      => 'authorization_code',
        code            => $code,
        client_id       => $self->client_id,
        client_secret   => $self->client_secret,
        redirect_uri    => $self->redirect_uri,
    );

    my $response = $self->_request(
        method => 'POST',
        url => $self->token_uri,
        headers => ['Content-Type', 'application/x-www-form-urlencoded'],
        content => \%params
    );

    return decode_json($response->decoded_content());
}

=head2 refresh_token($refresh_token)

For use when you require offline access.

Returns a I<HashRef> of token data similar to requesting an access token.

Assuming you are storing the access token in your own storage method,
the access token returned here should replace the old one stored
against the user.

=cut

sub refresh_token {
    my ($self, $refresh_token) = @_;

    return unless $self->access_type eq 'offline';

    unless ( $refresh_token ) {
        Carp::confess("Refresh token was not given");
    }

    my %params = (
        grant_type      => 'refresh_token',
        refresh_token   => $refresh_token,
        client_id       => $self->client_id,
        client_secret   => $self->client_secret,
    );

    my $response = $self->_request(
        method => 'POST',
        url => $self->token_uri,
        headers => ['Content-Type', 'application/x-www-form-urlencoded'],
        content => \%params
    );

    return decode_json($response->decoded_content());
}

=head2 revoke_token($access_token)

Revokes the access token on Google on behalf of the user.

If successful, it will be as if the user had never given
consent to your application, so restarting the oauth flow
will be the necessary.

=cut

sub revoke_token {
    my ($self, $access_token) = @_;

    return unless $access_token;

    my $uri = URI->new($self->revoke_uri);
    $uri->query_form({ token => $access_token });

    $self->_request(
        method => 'GET',
        url => $uri->as_string
    );

    return 1;
}

sub _request {
    my ($self, %req) = @_;

    my $response = $self->ua->request(%req);

    if ( !$response->is_success() ) {
        Carp::confess("Request to $req{url} failed, response was:\n" . $response->as_string());
    }

    return $response;
}

1;
