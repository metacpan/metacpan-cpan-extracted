package Lemonldap::NG::Portal::Auth::Twitter;

use strict;
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR);

extends 'Lemonldap::NG::Portal::Main::Auth';

our $VERSION = '2.0.12';

# INITIALIZATION

has twitterRequestTokenURL => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{twitterRequestTokenURL}
          || 'https://api.twitter.com/oauth/request_token';
    }
);

has twitterAuthorizeURL => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{twitterAuthorizeURL}
          || 'https://api.twitter.com/oauth/authorize';
    }
);

has twitterAccessTokenURL => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{twitterAccessTokenURL}
          || 'https://api.twitter.com/oauth/access_token';
    }
);

# return LWP::UserAgent object
has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {

        # TODO : LWP options to use a proxy for example
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

sub init {
    my ($self) = @_;
    unless ( $self->conf->{twitterKey} and $self->conf->{twitterSecret} ) {
        $self->error('twitterKey and twitterSecret parameters are required');
        return 0;
    }
    eval {
        require Net::OAuth;
        $Net::OAuth::PROTOCOL_VERSION = &Net::OAuth::PROTOCOL_VERSION_1_0A();
    };
    if ($@) {
        $self->error("Unable to load Net::OAuth: $@");
        return 0;
    }
    return 1;
}

sub extractFormInfo {
    my ( $self, $req ) = @_;
    my $nonce = time;

    # 1. Request to authenticate
    unless ( $req->param('twitterback') ) {
        $self->logger->debug('Redirection to Twitter');

        # 1.1 Try to get token to dialog with Twitter
        my $callback_url = $self->p->portal;

        # Twitter callback parameter
        my %prm = ( twitterback => 1 );

        # Add request state parameters
        if ( $req->data->{_url} ) {
            $prm{url} = $req->data->{_url};
        }

        # Forward hidden fields
        if ( exists $req->{portalHiddenFormValues} ) {

            $self->logger->debug("Add hidden values to Twitter redirect URL");

            foreach ( keys %{ $req->{portalHiddenFormValues} } ) {
                $prm{$_} = $req->{portalHiddenFormValues}->{$_};
            }
        }
        $callback_url .=
          ( $callback_url =~ /\?/ ? '&' : '?' ) . build_urlencoded(%prm);

        my $request = Net::OAuth->request("request token")->new(
            consumer_key     => $self->conf->{twitterKey},
            consumer_secret  => $self->conf->{twitterSecret},
            request_url      => $self->twitterRequestTokenURL,
            request_method   => 'POST',
            signature_method => 'HMAC-SHA1',
            timestamp        => time,
            nonce            => $nonce,
            callback         => $callback_url,
        );

        $request->sign;

        my $request_url = $request->to_url;

        $self->logger->debug("POST $request_url to Twitter");

        my $res = $self->ua()->post($request_url);
        $self->logger->debug( "Twitter response: " . $res->as_string );

        if ( $res->is_success ) {
            my $response = Net::OAuth->response('request token')
              ->from_post_body( $res->content );

            # 1.2 Store token key and secret in cookies (available 180s)
            $req->addCookie(
                $self->p->cookie(
                    name    => '_twitSec',
                    value   => $response->token_secret,
                    max_age => 180,
                )
            );

            # 1.3 Redirect user to Twitter
            $req->urldc( $self->twitterAuthorizeURL
                  . "?oauth_token="
                  . $response->token );
            $self->logger->debug( "Redirect user to " . $req->{urldc} );
            $req->continue(1);
            $req->steps( [] );
            return PE_OK;
        }
        else {
            $self->logger->error(
                'Twitter OAuth protocol error: ' . $res->content );
            return PE_ERROR;
        }
    }

    # 2. User is back from Twitter
    my $request_token = $req->param('oauth_token');
    my $verifier      = $req->param('oauth_verifier');
    unless ( $request_token and $verifier ) {
        $self->logger->error('Twitter OAuth protocol error');
        return PE_ERROR;
    }

    $self->logger->debug(
        "Get token $request_token and verifier $verifier from Twitter");

    # 2.1 Reconnect to Twitter
    my $access = Net::OAuth->request("access token")->new(
        consumer_key     => $self->conf->{twitterKey},
        consumer_secret  => $self->conf->{twitterSecret},
        request_url      => $self->twitterAccessTokenURL,
        request_method   => 'POST',
        signature_method => 'HMAC-SHA1',
        verifier         => $verifier,
        token            => $request_token,
        token_secret     => $self->p->cookie( name => '_twitSec' ),
        timestamp        => time,
        nonce            => $nonce,
    );
    $access->sign;

    my $access_url = $access->to_url;

    $self->logger->debug("POST $access_url to Twitter");

    my $res_access = $self->ua()->post($access_url);
    $self->logger->debug( "Twitter response: " . $res_access->as_string );

    if ( $res_access->is_success ) {
        my $response = Net::OAuth->response('access token')
          ->from_post_body( $res_access->content );

        # Get user_id and screename
        $req->data->{_twitterUserId} = $response->{extra_params}->{user_id};
        $req->data->{_twitterScreenName} =
          $response->{extra_params}->{screen_name};

        $self->logger->debug( "Get user id "
              . $req->data->{_twitterUserId}
              . " and screen name "
              . $req->data->{_twitterScreenName} );
        $req->user(
            $response->{extra_params}->{ $self->conf->{'twitterUserField'} } );
        $self->logger->debug("Good Twitter authentication for $req->{user}");
    }
    else {
        $self->logger->error(
            'Twitter OAuth protocol error: ' . $res_access->content );
        return PE_ERROR;
    }

    # Force redirection to avoid displaying OAuth data
    $req->{mustRedirect} = 1;

    # Clean temporaries cookies
    $req->addCookie(
        $self->p->cookie(
            name    => '_twitSec',
            value   => 0,
            expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
        )
    );
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;

    $req->{sessionInfo}->{authenticationLevel} =
      $req->data->{twitterAuthnLevel};
    $req->{sessionInfo}->{_twitterUserId} = $req->data->{_twitterUserId};
    $req->{sessionInfo}->{_twitterScreenName} =
      $req->data->{_twitterScreenName};

    return PE_OK;
}

sub authenticate {
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub getDisplayType {
    return "logo";
}

1;
