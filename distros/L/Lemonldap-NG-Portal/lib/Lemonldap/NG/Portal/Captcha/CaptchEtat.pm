package Lemonldap::NG::Portal::Captcha::CaptchEtat;

use strict;
use Mouse;
use JSON;
use Lemonldap::NG::Common::UserAgent;
use HTTP::Request::Common;
use URI;

# Add constants used by this module

our $VERSION = '2.23.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

has client_id => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{captchaOptions}->{clientId};
    }
);

has client_secret => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{captchaOptions}->{clientSecret};
    }
);

has captcha_style_name => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{captchaOptions}->{captchaStyleName} || 'captchaFR';
    }
);

has oauth_token_endpoint => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{captchaOptions}->{oauthTokenEndpoint}
          || 'https://oauth.piste.gouv.fr/api/oauth/token';
    }
);

has oauth_scope => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{captchaOptions}->{oauthScope} || 'piste.captchetat';
    }
);

has captcha_api_base => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->conf->{captchaOptions}->{captchaApiBase}
          || 'https://api.piste.gouv.fr/piste/captchetat/v2';
    }
);

has access_token_cache => (
    is      => 'rw',
    builder => sub {
        {
            expires_at => 0,
            value      => 0,
        }
    },
);

sub init {
    my ($self) = @_;
    unless ( $self->client_id && $self->client_secret ) {
        $self->logger->error(
            'Missing required options for CaptchEtat: clientId, clientSecret');
        return 0;
    }

    $self->addAuthRoute(
        'simple-captcha-endpoint' => 'captchaProxy',
        [qw(GET)]
    );
    $self->addUnauthRoute(
        'simple-captcha-endpoint' => 'captchaProxy',
        [qw(GET)]
    );
    return 1;
}

sub getToken {
    my ($self) = @_;

    my $cache = $self->access_token_cache;

    if (    $cache->{expires_at}
        and $cache->{expires_at} > time
        and $cache->{value} )
    {
        return $cache->{value};
    }

    return $self->_getNewToken;
}

sub _getNewToken {
    my ($self) = @_;

    my $token_url = URI->new( $self->oauth_token_endpoint );
    $self->logger->debug("Calling CaptchEtat token endpoint $token_url");
    my $response = $self->ua->post(
        $token_url,
        Content => {
            grant_type    => 'client_credentials',
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
            scope         => $self->oauth_scope,
        }
    );

    if ( $response->is_success ) {
        my $res = eval { JSON::from_json( $response->decoded_content ) };
        if ($@) {
            $self->logger->error(
"Could not decode JSON response from CaptchEtat token endpoint: $@"
            );
            $self->logger->debug( $response->dump );
            return;
        }

        # Cache token if we can
        if ( $res->{expires_in} and $res->{access_token} ) {
            $self->access_token_cache( {
                    expires_at => ( time + $res->{expires_in} ),
                    value      => $res->{access_token},
                }
            );
        }
        else {
            $self->access_token_cache( {} );
        }
        return ( $res->{access_token} );
    }
    $self->logger->error(
        'CaptchEtat token endpoint error: ' . $response->status_line );
    $self->logger->debug( $response->dump );
    return;
}

sub captchaProxy {
    my ( $self, $req ) = @_;

    my $param_get = $self->_validateProxyParam( $req, 'get' );

    if ( !$param_get ) {
        $self->logger->error("CaptchEtat proxy: missing 'get' parameter");
        return $self->p->sendError( $req, 'invalid parameters', 400 );
    }

    my $param_c = $self->_validateProxyParam( $req, 'c' );
    if ( !$param_c ) {
        $self->logger->error("CaptchEtat proxy: missing 'c' parameter");
        return $self->p->sendError( $req, 'invalid parameters', 400 );
    }

    my $param_t = $self->_validateProxyParam( $req, 't' );
    if ( $param_get eq "sound" and !$param_t ) {
        $self->logger->error("CaptchEtat proxy: missing 't' parameter");
        return $self->p->sendError( $req, 'invalid parameters', 400 );
    }

    my $backend_uri = URI->new( $self->captcha_api_base );
    $backend_uri->path_segments( $backend_uri->path_segments,
        "simple-captcha-endpoint" );
    $backend_uri->query_form(
        get => $param_get,
        c   => $param_c,
        ( $param_t ? ( t => $param_t ) : () )
    );

    $self->logger->debug("Sending CaptchEtat request to $backend_uri");
    my $http_request =
      GET( $backend_uri, "Content-Type" => "application/json", );

    my $response = $self->request_authenticated_service($http_request);
    if ($response) {
        if ( $response->is_success ) {
            my $res = eval { JSON::from_json( $response->decoded_content ) };
            if ($@) {
                $self->logger->error(
                    "Could not decode JSON response from CaptchEtat: $@");
                $self->logger->debug( $response->dump );
                return $self->p->sendError( $req, 'CaptchEtat backend failed',
                    500 );
            }
            return $self->p->sendJSONresponse( $req, $res );
        }
        else {
            $self->logger->error(
                'CaptchEtat error: ' . $response->status_line );
            $self->logger->debug( $response->dump );
        }
    }
    return $self->p->sendError( $req, 'CaptchEtat backend failed', 500 );
}

sub _validateProxyParam {
    my ( $self, $req, $param_name ) = @_;

    my $value = $req->param($param_name) || "";

    if ( $value =~ /^[\w-]+$/ ) {
        return $value;
    }
    return;
}

sub init_captcha {
    my ( $self, $req ) = @_;

    my $cacheTag = $self->p->cacheTag;
    $req->data->{customScript} .= <<"EOF";
<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/captchetat-js.min.js?v=$cacheTag"></script>
EOF

    my $nomCaptcha = $self->captcha_style_name;

    my $sc = $req->script_name // "";
    $sc =~ s#/*$#/#;
    my $endpoint = "${sc}simple-captcha-endpoint";

    # Read option from the manager configuration
    my $html = <<EOF;
    <div id="captchetat" captchaStyleName="$nomCaptcha" altImage="alternativeImage" urlBackend="$endpoint"></div>
    <input type="text" id="captchaCode" name="captchaCode"/>
EOF
    $req->captchaHtml($html);
}

sub request_authenticated_service {
    my ( $self, $http_request ) = @_;

    my $response = $self->_request_with_token($http_request);

    # If we got an invalid token response, get new token and retry once
    if ( $self->_isInvalidTokenResponse($response) ) {
        $self->logger->debug( 'Current access token rejected,'
              . ' retrying request with a new Access Token' );

        # Invalidate token cache to make sure it will be refreshed
        $self->access_token_cache( {} );

        $response = $self->_request_with_token($http_request);
    }
    return $response;
}

sub _request_with_token {
    my ( $self, $http_request ) = @_;

    my $bearer_token = $self->getToken;

    unless ($bearer_token) {
        $self->logger->info('Could not get bearer token for CaptchEtat');
        return;
    }

    $http_request->header( Authorization => "Bearer $bearer_token" );

    return $self->ua->request($http_request);
}

sub _isInvalidTokenResponse {
    my ( $self, $r ) = @_;

    return unless $r;

    if ( $r->code and $r->code == 401 ) {

        # This dependency improves parsing of WWW-Authenticate headers
        require HTTP::Headers::Auth;

        my ( $auth_scheme, $params ) = $r->www_authenticate;

        if (    lc($auth_scheme) eq "bearer"
            and ref($params) eq "HASH"
            and $params->{error}
            and $params->{error} eq "invalid_token" )
        {
            return 1;
        }
    }
    return 0;
}

sub check_captcha {
    my ( $self, $req ) = @_;

    my $captcha_uuid  = $req->param('captchetat-uuid');
    my $captcha_input = $req->param('captchaCode');

    unless ($captcha_input) {
        $self->logger->info('No captcha value submitted');
        return 0;
    }

    unless ($captcha_uuid) {
        $self->logger->info('No captcha UUID received');
        return 0;
    }

    my $validation_url = URI->new( $self->captcha_api_base );
    $validation_url->path_segments( $validation_url->path_segments,
        "valider-captcha" );
    $self->logger->debug(
        "Sending CaptchEtat validation request to $validation_url");

    my $http_request = POST(
        $validation_url,
        "Content-Type" => "application/json",
        Content        => to_json( {
                uuid => $captcha_uuid,
                code => $captcha_input,
            }
        )
    );
    my $response = $self->request_authenticated_service($http_request);

    if ($response) {
        if ( $response->is_success ) {
            my $res = $response->decoded_content;
            return ( $res eq "true" );
        }
        else {
            $self->logger->error(
                'CaptchEtat error: ' . $response->status_line );
            $self->logger->debug( $response->dump );
        }
    }
    return 0;
}

1;

