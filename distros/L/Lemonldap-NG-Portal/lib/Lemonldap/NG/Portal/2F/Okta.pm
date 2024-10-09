package Lemonldap::NG::Portal::2F::Okta;

use HTTP::Request;
use JSON;
use Mouse;
use URI;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADCREDENTIALS
  PE_BADOTP
  PE_ERROR
  PE_NOTOKEN
  PE_SENDRESPONSE
  PE_TOKENEXPIRED
);

extends 'Lemonldap::NG::Portal::Lib::Code2F';
with 'Lemonldap::NG::Portal::Lib::Okta';

has prefix    => ( is => 'ro', default => 'okta' );
has conf_type => ( is => 'ro', default => 'okta' );

sub init {
    my ($self) = @_;

    # Check mandatory parameters
    unless ( $self->conf->{okta2fAdminURL} ) {
        $self->error("Okta 2F: Admin URL is required");
        return 0;
    }
    unless ( $self->conf->{okta2fApiKey} ) {
        $self->error("Okta 2F: API key is required");
        return 0;
    }

    # Add Okta factor choice endpoint
    unless ( $self->noRoute ) {
        $self->logger->debug( 'Adding ' . $self->prefix . '2fchoice route' );
        $self->addUnauthRoute(
            $self->prefix . '2fchoice' => '_issueFactor',
            ['POST']
        );
        $self->addUnauthRoute(
            $self->prefix . '2fchoice' => '_redirect',
            ['GET']
        );
        $self->logger->debug( 'Adding ' . $self->prefix . '2fwait route' );
        $self->addUnauthRoute(
            $self->prefix . '2fwait' => '_waitingFactor',
            ['POST']
        );
        $self->addUnauthRoute(
            $self->prefix . '2fwait' => '_redirect',
            ['GET']
        );
    }
    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;

    my $okta_login_attribute = $self->conf->{'okta2fLoginAttribute'} || '_user';
    my $okta_login           = $req->sessionInfo->{$okta_login_attribute};
    my $okta_userid          = $self->getOktaUserID($okta_login);
    unless ($okta_userid) {
        $self->logger->error( "No Okta user found for " . $okta_login );
        return PE_ERROR;
    }
    $self->ott->updateToken( $token, __oktaUserId => $okta_userid );

    # Get available factors ( factorid, factortype )
    my $okta_factors = $self->getOktaActiveFactors( $req, $okta_userid );

    unless ( keys %$okta_factors ) {
        $self->logger->error("No factor found for $okta_userid");
        return PE_ERROR;
    }

    $self->logger->debug("Found factors for $okta_userid");
    $self->p->_dump($okta_factors);

    # Only one factor available, skip choice
    if ( scalar keys %$okta_factors == 1 ) {
        my $factor_id = ( keys %$okta_factors )[0];
        $self->logger->debug("Only one factor found ($factor_id), use it");

        # Redirect on 2Fchoice endpoint
        my $redirect_uri = $self->p->portal . $self->prefix . "2fchoice";

        $self->logger->debug("Redirect user to $redirect_uri with POST");
        $req->postUrl($redirect_uri);
        $req->postFields( { token => $token, sf => $factor_id } );

        $req->steps( ['autoPost'] );
        return PE_OK;
    }

    # More than one factor has been found, display choice
    else {
        $self->logger->debug("Prepare Okta Factor choice");
        my $res = $self->p->sendHtml(
            $req,
            'okta2fchoice',
            params => {
                TOKEN   => $token,
                MODULES => [
                    map { { CODE => $_, LABEL => $okta_factors->{$_} } }
                    sort keys %$okta_factors
                ],
                ALERT => 'positive',
                MSG   => 'okta2fSelectFactor',
                $self->get2fTplParams($req),
            }
        );
        $req->response($res);
        return PE_SENDRESPONSE;
    }
}

sub verify {
    my ( $self, $req, $session ) = @_;

    if ( $req->param('code') ) {
        $self->logger->debug("Okta 2F is a code, verify it with Code2F module");
        return $self->SUPER::verify( $req, $session );
    }

    $self->logger->debug("Okta 2F is not a code, wait for user interaction");
    my $okta_userid   = $session->{__oktaUserId};
    my $okta_poll_url = $session->{__oktaPollUrl};

    my $okta_poll_result;
    my $poll_response;
    my $poll_content;
    for ( my $i = 0 ; $i <= 60 ; $i++ ) {

        $poll_response = $self->pollFactor($okta_poll_url);
        last unless ($poll_response);

        $self->logger->debug(
            "Get poll response for $okta_userid:" . $poll_response );

        $poll_content = $self->decodeJSON($poll_response);

        $okta_poll_result = $poll_content->{factorResult};

        unless ( $okta_poll_result eq "WAITING" ) {
            $self->logger->debug(
                "Okta push response received for $okta_userid ");
            last;
        }

        sleep 1;
    }

    if ( $okta_poll_result eq "SUCCESS" ) {
        $self->logger->debug("Okta push verified for $okta_userid");
        return PE_OK;
    }
    else {
        return PE_ERROR;
    }
}

sub verify_external {
    my ( $self, $req, $session, $code ) = @_;

    my $okta_userid     = $session->{__oktaUserId};
    my $selected_factor = $session->{__oktaFactorId};
    unless ( $okta_userid && $selected_factor ) {
        $self->logger->error("Missing Okta data (userid, factorid) in OTT");
        return PE_ERROR;
    }

    my $verify_factor_response =
      $self->verifyFactor( $okta_userid, $selected_factor, $code );
    return PE_ERROR unless ($verify_factor_response);

    $self->logger->debug(
        "Verify 2FA code $code with factor $selected_factor for $okta_userid:"
          . $verify_factor_response );
    my $okta_verification = $self->decodeJSON($verify_factor_response);

    unless ( $okta_verification->{factorResult} eq "SUCCESS" ) {
        $self->logger->error(
            "Verifiation failed for code $code for $okta_userid in Okta");
        return PE_BADOTP;
    }

    $self->logger->debug("2FA code verified in Okta for $okta_userid");

    return PE_OK;
}

# Convert JSON to HashRef
# @return HashRef JSON decoded content
sub decodeJSON {
    my ( $self, $json ) = @_;
    my $json_hash;

    eval { $json_hash = from_json( $json, { allow_nonref => 1 } ); };
    return undef if ($@);
    unless ( ref $json_hash ) {
        $self->logger->error("Wanted a JSON object, got: $json_hash");
        return undef;
    }

    return $json_hash;
}

# Get Okta user ID
# @return String Okta user ID
sub getOktaUserID {
    my ( $self, $okta_login ) = @_;
    my $okta_userid;

    # Search user
    $self->logger->debug("Search $okta_login in Okta");
    my $search_profile_response = $self->searchProfile($okta_login);
    return unless $search_profile_response;

    my $okta_user = $self->decodeJSON($search_profile_response);
    unless ( $okta_user and $okta_user->[0]->{id} ) {
        $self->logger->error("User $okta_login not found in Okta");
        return;
    }

    $okta_userid = $okta_user->[0]->{id};

    $self->logger->debug("Found Okta ID $okta_userid for user $okta_login");

    return $okta_userid;
}

# Get Okta active factors
# @return HashRef Okta factor list
sub getOktaActiveFactors {
    my ( $self, $req, $okta_userid ) = @_;
    my $okta_factors = {};

    # Search factors
    my $search_factors_response = $self->searchFactors($okta_userid);
    return unless $search_factors_response;

    $self->logger->debug(
        "Get factors for $okta_userid:" . $search_factors_response );

    my $okta_factor = $self->decodeJSON($search_factors_response);
    unless ($okta_factor) {
        $self->logger->error("No factors for $okta_userid in Okta");
        return $okta_factors;
    }

    # Keep active factors
    foreach (@$okta_factor) {

        my $factor_id     = $_->{id};
        my $factor_type   = $_->{factorType};
        my $factor_status = $_->{status};
        if ( $factor_status ne "ACTIVE" ) {
            $self->logger->debug(
"Factor $factor_id of type $factor_type for $okta_userid is not active, skipping it"
            );
            next;
        }

        $factor_type =~ s/://g;
        $okta_factors->{$factor_id} = $factor_type;
    }

    return $okta_factors;
}

sub _issueFactor {
    my ( $self, $req ) = @_;

    my $token;
    unless ( $token = $req->param('token') ) {
        $self->userLogger->error( $self->prefix . ' 2F access without token' );
        eval { $self->setSecurity($req) };
        $req->mustRedirect(1);
        return $self->p->do( $req, [ sub { PE_NOTOKEN } ] );
    }

    my $session;
    unless ( $session = $self->ott->getToken( $token, 1 ) ) {
        $self->userLogger->info(
            'Invalid token during ' . $self->prefix . '2f choice' );
        $req->noLoginDisplay(1);
        return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
    }

    my $okta_userid     = $session->{__oktaUserId};
    my $selected_factor = $req->param('sf');
    $self->ott->updateToken( $token, __oktaFactorId => $selected_factor );

    my $issue_factor_response =
      $self->issueFactor( $okta_userid, $selected_factor );
    unless ($issue_factor_response) {
        eval { $self->setSecurity($req) };
        $req->mustRedirect(1);
        return $self->p->do( $req, [ sub { PE_ERROR } ] );
    }

    $self->logger->debug(
        "2FA sent to $okta_userid: " . $issue_factor_response );

    my $okta_issue = $self->decodeJSON($issue_factor_response);

    if ( $okta_issue->{factorResult} eq "CHALLENGE" ) {

        $self->logger->debug(
            "2FA is a challenge, redirect $okta_userid to code form");

        my $tmp = $self->sendCodeForm( $req, TOKEN => $token );
        $req->response($tmp);

        return $self->p->do( $req, [ sub { PE_SENDRESPONSE } ] );
    }

    elsif ( $okta_issue->{factorResult} eq "WAITING" ) {

        $self->logger->debug(
            "2FA is not a code, redirect $okta_userid to waiting screen");

        # Get poll URL
        my $okta_poll_url = $okta_issue->{_links}->{poll}->{href};
        $self->ott->updateToken( $token, __oktaPollUrl => $okta_poll_url );

        # Redirect on 2Fcheck endpoint
        my $redirect_uri = $self->p->portal . $self->prefix . "2fcheck";

        $self->logger->debug("Redirect user to $redirect_uri with POST");
        $req->postUrl($redirect_uri);
        $req->postFields( { token => $token } );

        $req->data->{sfWait} = 1;
        return $self->p->do( $req, ['autoPost'] );
    }

    eval { $self->setSecurity($req) };
    $req->mustRedirect(1);
    return $self->p->do( $req, [ sub { PE_ERROR } ] );
}

1;
