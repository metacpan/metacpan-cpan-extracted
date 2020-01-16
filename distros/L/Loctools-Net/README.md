# Loctools::Net

A collection of utility modules to simplify working with HTTP and OAuth2-based services.

## Loctools::Net::OAuth2::Session

This is a wrapper on top of `Net::OAuth2::Profile::WebServer` that implements a session that persists in a file. It allows you to authorize the application on first use, and then loads the session from disk and renews the token automatically.

## Loctools::Net::OAuth2::Session::Google

This module is a wrapper on top of `Loctools::Net::OAuth2::Session` that presets Google OAuth2 parameters.

## Loctools::Net::HTTP::Client

This is a wrapper on top of `LWP::UserAgent` that implements HTTP requests with exponential back-off and automatic OAuth session renewal.

## Installation

    $ cpan Loctools::Net

## Usage

```perl
use Loctools::Net::OAuth2::Session::Google;
use Loctools::Net::HTTP::Client;

my $session = Loctools::Net::OAuth2::Session::Google->new(
    client_id     => '<my-client-id>',
    client_secret => '<my-client-secret>',
    scope         => '<scope-id>',
    session_file  => './oauth2-session.json',
);

# this will automatically load the session,
# renew the token if it is expired,
# or show the authorization prompt in the console
my $client = Loctools::Net::HTTP::Client->new(session => $session);

# $client->get('https://...');
# $client->post_json('https://...', { ... });
# ...
```
