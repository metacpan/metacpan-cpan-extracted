package Lemonldap::NG::Portal::Auth::GitHub;

use strict;
use JSON;
use Mouse;
use MIME::Base64 qw/encode_base64 decode_base64/;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_REDIRECT);

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Portal::Main::Auth';

# INITIALIZATION

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

has githubAuthorizationEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{githubAuthorizationEndpoint}
          || 'https://github.com/login/oauth/authorize';
    }
);

has githubTokenEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{githubTokenEndpoint}
          || 'https://github.com/login/oauth/access_token';
    }
);

has githubUserEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{githubUserEndpoint}
          || 'https://api.github.com/user';
    }
);

sub init {
    my ($self) = @_;

    my $ret = 1;
    foreach my $arg (qw(githubClientID githubClientSecret)) {
        unless ( $self->conf->{$arg} ) {
            $ret = 0;
            $self->error("Parameter $arg is required");
        }
    }

    return $ret;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    my $nonce = time;

    # Build redirect_uri
    my $callback_url = $self->conf->{portal};

    # Check return values
    my $code  = $req->param("code");
    my $state = $req->param("state");

    # Code
    if ($code) {
        my %form;
        $form{"code"}          = $code;
        $form{"state"}         = $state if $state;
        $form{"client_id"}     = $self->conf->{githubClientID};
        $form{"client_secret"} = $self->conf->{githubClientSecret};
        $form{"redirect_uri"}  = $callback_url;

        my $response = $self->ua->post(
            $self->githubTokenEndpoint,
            \%form,
            "Content-Type" => 'application/x-www-form-urlencoded',
            'Accept'       => 'application/json'
        );

        if ( $response->is_error ) {
            $self->logger->error(
                "Bad authorization response: " . $response->message );
            $self->logger->debug( $response->content );
            return PE_ERROR;
        }

        my $content = $response->decoded_content;

        my $json_hash;

        eval { $json_hash = from_json( $content, { allow_nonref => 1 } ); };

        if ($@) {
            $self->logger->error("Unable to decode JSON $content");
            return PE_ERROR;
        }

        my $access_token = $json_hash->{access_token};

        $self->logger->debug("Get access token $access_token from GitHub");

        # Call People EndPoint URI
        $self->logger->debug(
            "Call GitHub People Endpoint " . $self->githubUserEndpoint );

        my $people_response = $self->ua->get( $self->githubUserEndpoint,
            "Authorization" => "token $access_token" );

        if ( $people_response->is_error ) {
            $self->logger->error(
                "Bad authorization response: " . $people_response->message );
            $self->logger->debug( $people_response->content );
            return PE_ERROR;
        }

        my $user_content = $people_response->decoded_content;

        $self->logger->debug("Response from GitHub People API: $user_content");

        eval {
            $json_hash = from_json( $user_content, { allow_nonref => 1 } ); };
        if ($@) {
            $self->logger->error("Unable to decode JSON $user_content");
            return PE_ERROR;
        }

        foreach ( keys %$json_hash ) {
            $req->data->{githubData}->{$_} = $json_hash->{$_};
        }

        $req->user(
            $req->data->{githubData}->{ $self->conf->{githubUserField} } );

        $self->logger->debug( "Good GitHub authentication for " . $req->user );

        # Extract state
        if ($state) {
            my $stateSession = $self->p->getApacheSession( $state, 1 );

            $req->urldc( $stateSession->data->{urldc} );
            $req->{checkLogins} = $stateSession->data->{checkLogins};

            $stateSession->remove;
        }

        return PE_OK;
    }

    # No code, redirect to GitHub
    else {
        $self->logger->debug('Redirection to GitHub');

        # Store state
        my $stateSession =
          $self->p->getApacheSession( undef, 1, 0, 'GitHubState' );

        my $stateInfos = {};
        $stateInfos->{_utime}      = time() + $self->conf->{timeout};
        $stateInfos->{urldc}       = $req->urldc;
        $stateInfos->{checkLogins} = $req->{checkLogins};

        $stateSession->update($stateInfos);

        my $authn_uri = $self->githubAuthorizationEndpoint;
        my $client_id = $self->conf->{githubClientID};
        my $scope     = $self->conf->{githubScope};
        $authn_uri .= '?'
          . build_urlencoded(
            response_type => 'code',
            client_id     => $client_id,
            redirect_uri  => $callback_url,
            scope         => $scope,
            state         => $stateSession->id,
          );

        $req->urldc($authn_uri);

        $self->logger->debug( "Redirect user to " . $req->urldc );

        return PE_REDIRECT;
    }
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;

    $req->{sessionInfo}->{authenticationLevel} =
      $self->conf->{githubAuthnLevel};

    foreach ( keys %{ $req->data->{githubData} } ) {
        $req->{sessionInfo}->{ 'github_' . $_ } =
          $req->data->{githubData}->{$_};
    }

    PE_OK;
}

sub authenticate {
    PE_OK;
}

sub authFinish {
    PE_OK;
}

sub authLogout {
    PE_OK;
}

sub authForce {
    return 0;
}

sub getDisplayType {
    return "logo";
}

1;
