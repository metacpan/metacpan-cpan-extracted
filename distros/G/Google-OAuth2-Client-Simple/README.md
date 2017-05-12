# NAME

Google::OAuth2::Client::Simple - Client for Google OAuth2.

# SYNOPSIS

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

# DESCRIPTION

A client library that talks to Googles OAuth 2.0 API, found at:
https://developers.google.com/identity/protocols/OAuth2WebServer

Provides methods to cover the whole OAuth flow to get an access token and connect to the Google API.

To get credentials, register your app by following the instructions under "Creating web application credentials":
https://developers.google.com/identity/protocols/OAuth2WebServer

Valid scopes can be found here:
https://developers.google.com/identity/protocols/googlescopes

# NOTE

It should be noted that token storage should be something handled by your application, if persistent usage is a requirement.
This client library doesn't do that because, well, it's simple ;)

## request\_user\_consent

Returns a Furl::Response, the contents of which will contain Googles
sign in form. Once the user signs in they will be shown a list of
scopes your application is requesting, and will either allow or
deny you permission.

This method should be called to start the oauth flow, meaning
before trying to exchange the code for an access token.

Once the user gives consent successfully, they will be redirected to
$self->redirect\_uri which will contain 'code' and 'state' params.
The 'code' is used to exchange it for an access token.

For example, in a CGI file you can do something like: `print $response->content();`

Or in an application framework like Mojolicious: `return $self->render( html => $response->content() );`

## exchange\_code\_for\_token($code)

Returns a _HashRef_ of token data which looks like:

    {
      "access_token":"1/fFAGRNJru1FTz70BzhT3Zg",
      "expires_in":3920,
      "token_type":"Bearer",
      "refresh_token":"XXXXXXXX"
    }

This method should be called once you successfully retrieved a 'code'
from request\_user\_consent(), to end the oauth process by getting
an access\_token.

'refresh\_token' is only returned from Google if the access\_type was 'offline' when
requesting user consent and it was the first time the access token was received.
It should be saved in long term storage as stated in the documentation for you
to be able to refresh access tokens for persistent usage.

## refresh\_token($refresh\_token)

For use when you require offline access.

Returns a _HashRef_ of token data similar to requesting an access token.

Assuming you are storing the access token in your own storage method,
the access token returned here should replace the old one stored
against the user.

## revoke\_token($access\_token)

Revokes the access token on Google on behalf of the user.

If successful, it will be as if the user had never given
consent to your application, so restarting the oauth flow
will be the necessary.
