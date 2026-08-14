package Lemonldap::NG::Portal::Auth::LinkedIn;

use strict;
use JSON;
use Mouse;
use MIME::Base64 qw/encode_base64 decode_base64/;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_REDIRECT);

our $VERSION = '2.23.3';

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

# Used to protect the authorization request against CSRF and to restore the
# initial request across the LinkedIn round trip
has state_ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott = $_[0]->{p}->loadModule('::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{timeout} );

        # LinkedIn sends the user back to any portal of the farm, so the state
        # must not be stored in the local cache, whatever tokenUseGlobalStorage
        # says
        $ott->cache(undef);
        return $ott;
    }
);

has linkedInAuthorizationEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{linkedInAuthorizationEndpoint}
          || 'https://www.linkedin.com/oauth/v2/authorization';
    }
);

has linkedInTokenEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{linkedInTokenEndpoint}
          || 'https://www.linkedin.com/oauth/v2/accessToken';
    }
);

has linkedInPeopleEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{linkedInPeopleEndpoint}
          || 'https://api.linkedin.com/v2/me';
    }
);

has linkedInEmailEndpoint => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{linkedInEmailEndpoint}
          || 'https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))';
    }
);

sub init {
    my ($self) = @_;

    my $ret = 1;
    foreach my $arg (qw(linkedInClientID linkedInClientSecret)) {
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
    my $callback_url = $req->portal;

    # Check return values
    my $error = $req->param("error");
    my $code  = $req->param("code");
    my $state = $req->param("state");

    # Error
    if ($error) {
        $self->logger->error(
            "Error $error with LinkedIn: " . $req->param("error_description") );
        return PE_ERROR;
    }

    # Code
    if ($code) {

        # Restore initial request. This also protects against login CSRF: the
        # state token can only have been created by this portal
        unless ($state) {
            $self->userLogger->error(
                'LinkedIn response without state parameter');
            return PE_ERROR;
        }
        my $stateData = $self->state_ott->getToken($state);
        unless ( $stateData
            and ( $stateData->{_type} // '' ) eq 'linkedInState' )
        {
            $self->userLogger->error('Invalid or expired LinkedIn state');
            return PE_ERROR;
        }
        $req->urldc( $stateData->{urldc} ) if $stateData->{urldc};
        $req->{checkLogins} = $stateData->{checkLogins};

        my %form;
        $form{"code"}          = $code;
        $form{"client_id"}     = $self->conf->{linkedInClientID};
        $form{"client_secret"} = $self->conf->{linkedInClientSecret};
        $form{"redirect_uri"}  = $callback_url;
        $form{"grant_type"}    = "authorization_code";

        my $response = $self->ua->post( $self->linkedInTokenEndpoint,
            \%form, "Content-Type" => 'application/x-www-form-urlencoded' );

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

        $self->logger->debug("Get access token $access_token from LinkedIn");

        # Call People EndPoint URI
        $self->logger->debug(
            "Call LinkedIn People Endpoint " . $self->linkedInPeopleEndpoint );

        my $people_response = $self->ua->get( $self->linkedInPeopleEndpoint,
            "Authorization" => "Bearer $access_token" );

        if ( $people_response->is_error ) {
            $self->logger->error(
                "Bad authorization response: " . $people_response->message );
            $self->logger->debug( $people_response->content );
            return PE_ERROR;
        }

        my $people_content = $people_response->decoded_content;

        $self->logger->debug(
            "Response from LinkedIn People API: $people_content");

        eval {
            $json_hash = from_json( $people_content, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Unable to decode JSON $people_content");
            return PE_ERROR;
        }

        foreach ( keys %$json_hash ) {
            $req->data->{linkedInData}->{$_} = $json_hash->{$_};
        }

        # Call Email EndPoint URI
        if ( $self->conf->{linkedInScope} =~ /r_emailaddress/ ) {

            $self->logger->debug( "Call LinkedIn Email Endpoint "
                  . $self->linkedInEmailEndpoint );

            my $email_response = $self->ua->get( $self->linkedInEmailEndpoint,
                "Authorization" => "Bearer $access_token" );

            if ( $email_response->is_error ) {
                $self->logger->error(
                    "Bad authorization response: " . $email_response->message );
                $self->logger->debug( $email_response->content );
                return PE_ERROR;
            }

            my $email_content = $email_response->decoded_content;

            $self->logger->debug(
                "Response from LinkedIn Email API: $email_content");

            eval {
                $json_hash = from_json( $email_content, { allow_nonref => 1 } );
            };
            if ($@) {
                $self->logger->error("Unable to decode JSON $email_content");
                return PE_ERROR;
            }

            $req->data->{linkedInData}->{"emailAddress"} =
              $json_hash->{"elements"}->[0]{"handle~"}->{"emailAddress"};
        }

        $req->user(
            $req->data->{linkedInData}->{ $self->conf->{linkedInUserField} } );

        $self->logger->debug(
            "Good LinkedIn authentication for " . $req->user );

        return PE_OK;
    }

    # No code, redirect to LinkedIn
    else {
        $self->logger->debug('Redirection to LinkedIn');

        # Store state
        my $stateToken = $self->state_ott->createToken(
            {
                _type       => 'linkedInState',
                urldc       => $req->urldc,
                checkLogins => $req->{checkLogins},
            }
        );
        unless ($stateToken) {
            $self->logger->error('Unable to create LinkedIn state token');
            return PE_ERROR;
        }

        my $authn_uri = $self->linkedInAuthorizationEndpoint;
        my $client_id = $self->conf->{linkedInClientID};
        my $scope     = $self->conf->{linkedInScope};
        $authn_uri .= '?'
          . build_urlencoded(
            response_type => 'code',
            client_id     => $client_id,
            redirect_uri  => $callback_url,
            scope         => $scope,
            state         => $stateToken,
          );

        $req->urldc($authn_uri);

        $self->logger->debug( "Redirect user to " . $req->urldc );

        return PE_REDIRECT;
    }
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;

    $req->{sessionInfo}->{authenticationLevel} =
      $self->conf->{linkedInAuthnLevel};

    foreach ( keys %{ $req->data->{linkedInData} } ) {
        $req->{sessionInfo}->{ 'linkedIn_' . $_ } =
          $req->data->{linkedInData}->{$_};
    }

    return PE_OK;
}

sub authenticate {
    return PE_OK;
}

sub authFinish {
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub authForce {
    return 0;
}

sub getDisplayType {
    return "logo";
}

1;
