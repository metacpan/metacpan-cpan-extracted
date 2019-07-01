package Lemonldap::NG::Portal::Issuer::CAS;

use strict;
use Mouse;
use URI;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_CAS_SERVICE_NOT_ALLOWED
  PE_INFO
  PE_ERROR
  PE_LOGOUT_OK
  PE_OK
  PE_BADURL
  PE_SENDRESPONSE
);

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Portal::Main::Issuer',
  'Lemonldap::NG::Portal::Lib::CAS';

# INITIALIZATION

use constant beforeAuth  => 'storeEnvAndCheckGateway';
use constant sessionKind => 'ICAS';

has rule => ( is => 'rw' );

sub init {
    my ($self) = @_;

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug( "CAS rule -> " . $self->conf->{issuerDBCASRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{issuerDBCASRule} ) );
    unless ($rule) {
        $self->error( "Bad CAS rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->{rule} = $rule;

    # Launch parents initialization subroutines, then launch IdP and SP lists
    my $res = $self->Lemonldap::NG::Portal::Main::Issuer::init();
    return 0 unless ( $self->loadApp );
    $self->addUnauthRoute(
        ( $self->path ) => {
            serviceValidate => 'serviceValidate',
            validate        => 'validate',
            proxyValidate   => 'proxyValidate',
            proxy           => 'proxy',
            p3              => {
                serviceValidate => 'serviceValidate',
                proxyValidate   => 'proxyValidate'
            }
        },
        ['GET']
    );

    # Add CAS Services, so we can check service= parameter on logout
    foreach my $casSrv ( keys %{ $self->conf->{casAppMetaDataOptions} } ) {
        if ( my $serviceUrl =
            $self->conf->{casAppMetaDataOptions}->{$casSrv}
            ->{casAppMetaDataOptionsService} )
        {
            push @{ $self->p->{additionalTrustedDomains} }, $serviceUrl;
            $self->logger->debug(
                "CAS Service $serviceUrl added in trusted domains");
        }
    }
    return $res;
}

# RUNNING METHODS

sub storeEnvAndCheckGateway {
    my ( $self, $req ) = @_;
    my $service = $self->p->getHiddenFormValue( $req, 'service' )
      || $req->param('service');
    $service = '' if ( $self->p->checkXSSAttack( 'service', $service ) );
    my $gateway = $self->p->getHiddenFormValue( $req, 'gateway' )
      || $req->param('gateway');

    if ( $gateway and $gateway eq "true" ) {
        $self->logger->debug(
            "Gateway mode requested, redirect without authentication");
        $req->response( [ 302, [ Location => $service ], [] ] );
        $req->pdata( {} );
        return PE_SENDRESPONSE;
    }

    if ( $service and $service =~ m#^(https?://[^/]+)(/.*)?$# ) {
        my ( $host, $uri ) = ( $1, $2 );
        my $app = $self->casAppList->{$host};

        if ($app) {
            $req->env->{llng_cas_app} = $app;
        }
    }

    return PE_OK;
}

# Main method (launched only for authenticated users, see Main/Issuer)
sub run {
    my ( $self, $req, $target ) = @_;

    # Check activation rule
    unless ( $self->rule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->error('CAS service not authorized');
        return PE_CAS_SERVICE_NOT_ALLOWED;
    }

    # CAS URL
    my $cas_login              = 'login';
    my $cas_logout             = 'logout';
    my $cas_validate           = 'validate';
    my $cas_serviceValidate    = 'serviceValidate';
    my $cas_p3_serviceValidate = 'p3/serviceValidate';
    my $cas_proxyValidate      = 'proxyValidate';
    my $cas_p3_proxyValidate   = 'p3/proxyValidate';
    my $cas_proxy              = 'proxy';

    # Called URL
    my $url = $req->uri();

    # Session ID
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->{id};

    # Session creation timestamp
    my $time = $req->{sessionInfo}->{_utime} || time();

    # 1. LOGIN
    if ( $target eq $cas_login ) {

        $self->logger->debug("URL $url detected as an CAS LOGIN URL");

        # GET parameters
        my $service = $self->p->getHiddenFormValue( $req, 'service' )
          || $req->param('service');
        $service = '' if ( $self->p->checkXSSAttack( 'service', $service ) );
        my $renew = $self->p->getHiddenFormValue( $req, 'renew' )
          || $req->param('renew');
        my $gateway = $self->p->getHiddenFormValue( $req, 'gateway' )
          || $req->param('gateway');
        my $casServiceTicket;

        # Renew
        if (    $renew
            and $renew eq 'true'
            and time - $req->sessionInfo->{_utime} >
            $self->conf->{portalForceAuthnInterval} )
        {

            # Authentication must be replayed
            $self->logger->debug("Authentication renew requested");
            $self->{updateSession} = 1;
            $req->env->{QUERY_STRING} =~ s/renew=true/renew=false/;
            return $self->reAuth($req);
        }

        # If no service defined, exit
        unless ( defined $service ) {
            $self->logger->debug("No service defined in CAS URL");
            return PE_OK;
        }

        unless ( $service =~ m#^(https?://[^/]+)(/.*)?$# ) {
            $self->logger->error("Bad service $service");
            return PE_ERROR;
        }
        my ( $host, $uri ) = ( $1, $2 );
        my $app = $self->casAppList->{$host};

        # Check access on the service
        my $casAccessControlPolicy = $self->conf->{casAccessControlPolicy};

        if ( $casAccessControlPolicy =~ /^(error|faketicket)$/i ) {
            $self->logger->debug(
                "CAS access control requested on service $service");

            unless ($app) {
                $self->userLogger->error('CAS service not configured');
                return PE_CAS_SERVICE_NOT_ALLOWED;
            }
            if ( my $rule = $self->spRules->{$app} ) {
                if ( $rule->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug("CAS service $service access allowed");
                }

                else {
                    $self->userLogger->error(
                        "CAS service $service access not allowed");

                    if ( $casAccessControlPolicy =~ /^(error)$/i ) {
                        $self->logger->debug(
"Return error instead of redirecting user on CAS service"
                        );
                        return PE_CAS_SERVICE_NOT_ALLOWED;
                    }

                    else {
                        $self->logger->debug(
                            "Redirect user on CAS service with a fake ticket");
                        $casServiceTicket = "ST-F4K3T1CK3T";
                    }
                }
            }
        }

        unless ($casServiceTicket) {

            # Check last authentication time to decide if
            # the authentication is recent or not
            my $casRenewFlag = 0;
            my $last_authn_utime = $req->{sessionInfo}->{_lastAuthnUTime} || 0;
            if (
                time() - $last_authn_utime <
                $self->conf->{portalForceAuthnInterval} )
            {
                $self->logger->debug(
                    "Authentication is recent, will set CAS renew flag to true"
                );
                $casRenewFlag = 1;
            }

            # Create a service ticket
            $self->logger->debug(
                "Create a CAS service ticket for service $service");

            my $Sinfos;
            $Sinfos->{type}    = 'casService';
            $Sinfos->{service} = $service;
            $Sinfos->{renew}   = $casRenewFlag;
            $Sinfos->{_cas_id} = $session_id;
            $Sinfos->{_utime}  = $time;
            $Sinfos->{_casApp} = $app;

            my $casServiceSession = $self->getCasSession( undef, $Sinfos );

            unless ($casServiceSession) {
                $self->logger->error("Unable to create CAS session");
                return PE_ERROR;
            }

            my $casServiceSessionID = $casServiceSession->id;
            $casServiceTicket = "ST-" . $casServiceSessionID;

            $self->logger->debug(
                "CAS service session $casServiceSessionID created");
        }

        # Redirect to service
        my $service_url = $service;
        $service_url .= ( $service =~ /\?/ ? '&' : '?' )
          . build_urlencoded( ticket => $casServiceTicket );

        $self->logger->debug("Redirect user to $service_url");

        $req->{urldc} = $service_url;

        $req->steps( [] );
        return PE_OK;
    }

    # 2. LOGOUT
    if ( $target eq $cas_logout ) {

        $self->logger->debug("URL $url detected as an CAS LOGOUT URL");

        # Disable Content-Security-Policy header since logout can be embedded
        # in a frame
        $req->frame(1);

        # GET parameters
        my $logout_url     = $req->param('url');        # CAS 2.0
        my $logout_service = $req->param('service');    # CAS 3.0
        $logout_service = ''
          if ( $self->p->checkXSSAttack( 'service', $logout_service ) );

        # If we use access control, check that the service URL is trusted
        if ( $self->conf->{casAccessControlPolicy} =~ /^(error|faketicket)$/i )
        {
            if ( $logout_service
                and not $self->p->isTrustedUrl($logout_service) )
            {
                $self->userLogger->error(
                        "Untrusted service URL $logout_service"
                      . "specified for CAS Logout" );
                return PE_BADURL;
            }
        }

        # Delete linked CAS sessions
        $self->deleteCasSecondarySessions($session_id);

        # Delete local session
        if ( my $session = $self->p->getApacheSession($session_id) ) {
            unless ( $self->p->_deleteSession( $req, $session ) ) {
                $self->logger->error("Fail to delete session $session_id ");
            }

            if ($logout_url) {

                # Display a link to the provided URL
                $self->logger->debug(
                    "Logout URL $logout_url will be displayed");

                $req->info(
                    $self->loadTemplate(
                        $req, 'casBack2Url',
                        params => { url => $logout_url }
                    )
                );
                $req->data->{activeTimer} = 0;

                delete $req->pdata->{_url};
                return PE_INFO;
            }

            if ($logout_service) {
                $self->logger->debug(
                    "User will be redirected to $logout_service");
                $req->{urldc} = $logout_service;
                $req->steps( [] );
                return PE_OK;
            }
        }
        else {
            $self->logger->info("Unknown session $session_id");
        }

        return PE_LOGOUT_OK;

    }

    # 3. VALIDATE [CAS 1.0]
    if ( $target eq $cas_validate ) {

        $self->logger->debug("URL $url detected as an CAS VALIDATE URL");

        # This URL must not be called by authenticated users
        $self->userLogger->info(
            "CAS VALIDATE URL called by authenticated user, ignore it");

        return PE_OK;
    }

    # 4. SERVICE VALIDATE [CAS 2.0]
    if (   $target eq $cas_serviceValidate
        || $target eq $cas_p3_serviceValidate )
    {

        $self->logger->debug(
            "URL $url detected as an CAS SERVICE VALIDATE URL");

        # This URL must not be called by authenticated users
        $self->userLogger->info(
            "CAS SERVICE VALIDATE URL called by authenticated user, ignore it");

        return PE_OK;
    }

    # 5. PROXY VALIDATE [CAS 2.0]
    if ( $target eq $cas_proxyValidate || $target eq $cas_p3_proxyValidate ) {

        $self->logger->debug("URL $url detected as an CAS PROXY VALIDATE URL");

        # This URL must not be called by authenticated users
        $self->userLogger->info(
            "CAS PROXY VALIDATE URL called by authenticated user, ignore it");

        return PE_OK;
    }

    # 6. PROXY [CAS 2.0]
    if ( $target eq $cas_proxy ) {

        $self->logger->debug("URL $url detected as an CAS PROXY URL");

        # This URL must not be called by authenticated users
        $self->userLogger->info(
            "CAS PROXY URL called by authenticated user, ignore it");

        return PE_OK;
    }

    return PE_OK;
}

sub logout {
    my ( $self, $req ) = @_;

    # Session ID
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->{id};

    # Delete linked CAS sessions
    $self->deleteCasSecondarySessions($session_id) if ($session_id);

    return PE_OK;
}

# Direct request from SP to IdP

sub validate {
    my ( $self, $req ) = @_;
    $self->logger->debug(
        'URL ' . $req->uri . ' detected as an CAS VALIDATE URL' );

    # GET parameters
    my $service = $req->param('service');
    my $ticket  = $req->param('ticket');
    my $renew   = $req->param('renew');

    # Required parameters: service and ticket
    unless ( $service and $ticket ) {
        $self->logger->error("Service and Ticket parameters required");
        return $self->returnCasValidateError();
    }

    $self->logger->debug(
        "Get validate request with ticket $ticket for service $service");

    unless ( $ticket =~ s/^ST-// ) {
        $self->logger->error("Provided ticket is not a service ticket (ST)");
        return $self->returnCasValidateError();
    }

    my $casServiceSession = $self->getCasSession($ticket);

    unless ($casServiceSession) {
        $self->logger->error("Service ticket session $ticket not found");
        return $self->returnCasValidateError();
    }

    $self->logger->debug("Service ticket session $ticket found");

    my $service1_uri = URI->new($service);
    my $service2_uri = URI->new( $casServiceSession->data->{service} );

    # Check service
    unless ( $service1_uri->eq($service2_uri) ) {

        # Tolerate that relative URI are the same
        if (   $service1_uri->rel($service2_uri) eq "./"
            or $service2_uri->rel($service1_uri) eq "./" )
        {
            $self->logger->notice(
"Submitted service $service1_uri does not exactly match initial service "
                  . $service2_uri
                  . ' but difference is tolerated.' );
        }
        else {
            $self->logger->error(
                "Submitted service $service does not match initial service "
                  . $casServiceSession->data->{service} );
            $self->deleteCasSession($casServiceSession);
            return $self->returnCasValidateError();
        }
    }
    else {
        $self->logger->debug("Submitted service $service math initial servce");
    }

    # Check renew
    if ( $renew and $renew eq 'true' ) {

        # We should check the ST was delivered with primary credentials
        $self->logger->debug("Renew flag detected ");

        unless ( $casServiceSession->data->{renew} ) {
            $self->logger->error(
"Authentication renew requested, but not done in former authentication process"
            );
            $self->deleteCasSession($casServiceSession);
            return $self->returnCasValidateError();
        }
    }

    # Open local session
    my $localSession =
      $self->p->getApacheSession( $casServiceSession->data->{_cas_id} );

    unless ($localSession) {
        $self->logger->warn( "Local session "
              . $casServiceSession->data->{_cas_id}
              . " notfound" );
        $self->deleteCasSession($casServiceSession);
        return $self->returnCasValidateError();
    }

    # Get username
    my $app = $casServiceSession->data->{_casApp};
    my $username_attribute =
      (       $app
          and $self->conf->{casAppMetaDataOptions}->{$app}
          ->{casAppMetaDataOptionsUserAttribute} )
      ? $self->conf->{casAppMetaDataOptions}->{$app}
      ->{casAppMetaDataOptionsUserAttribute}
      : (    $self->conf->{casAttr}
          || $self->conf->{whatToTrace} );

    my $username = $localSession->data->{$username_attribute};

    $self->logger->debug("Get username $username");

    # Return success message
    $self->deleteCasSession($casServiceSession);
    return $self->returnCasValidateSuccess( $req, $username );
}

sub proxy {
    my ( $self, $req ) = @_;

    $self->logger->debug(
        'URL ' . $req->uri . " detected as an CAS PROXY URL" );

    # GET parameters
    my $pgt           = $req->param('pgt');
    my $targetService = $req->param('targetService');

    # Required parameters: pgt and targetService
    unless ( $pgt and $targetService ) {
        $self->logger->error("Pgt and TargetService parameters required");
        $self->returnCasProxyError( $req, 'INVALID_REQUEST',
            'Missing mandatory parameters (pgt, targetService)' );
    }

    $self->logger->debug(
        "Get proxy request with ticket $pgt for service $targetService");

    # Get CAS session corresponding to ticket
    unless ( $pgt =~ s/^PGT-// ) {
        $self->logger->error(
            "Provided ticket is not a proxy granting ticket (PGT)");
        $self->returnCasProxyError( $req, 'BAD_PGT',
            'Provided ticket is not a proxy granting ticket' );
    }

    my $casProxyGrantingSession = $self->getCasSession($pgt);

    unless ($casProxyGrantingSession) {
        $self->logger->error("Proxy granting ticket session $pgt not found");
        $self->returnCasProxyError( $req, 'BAD_PGT', 'Ticket not found' );
    }

    $self->logger->debug("Proxy granting session $pgt found");

    # Create a proxy ticket
    $self->logger->debug(
        "Create a CAS proxy ticket for service $targetService");

    my $casProxySession = $self->getCasSession();

    unless ($casProxySession) {
        $self->logger->error("Unable to create CAS proxy session");
        $self->returnCasProxyError( $req, 'INTERNAL_ERROR',
            'Error in proxy session management' );
    }

    my $Pinfos;
    $Pinfos->{type}    = 'casProxy';
    $Pinfos->{service} = $targetService;
    $Pinfos->{_cas_id} = $casProxyGrantingSession->data->{_cas_id};
    $Pinfos->{_utime}  = $casProxyGrantingSession->data->{_utime};
    $Pinfos->{proxies} = $casProxyGrantingSession->data->{proxies};

    $casProxySession->update($Pinfos);

    my $casProxySessionID = $casProxySession->id;
    my $casProxyTicket    = "PT-" . $casProxySessionID;

    $self->logger->debug("CAS proxy session $casProxySessionID created");

    return $self->returnCasProxySuccess( $req, $casProxyTicket );
}

sub serviceValidate {
    my ( $self, $req ) = @_;
    return $self->_validate2( 'SERVICE', $req );
}

sub proxyValidate {
    my ( $self, $req ) = @_;
    return $self->_validate2( 'PROXY', $req );
}

# INTERNAL METHODS

sub _validate2 {
    my ( $self, $urlType, $req ) = @_;
    $self->logger->debug(
        'URL ' . $req->uri . " detected as an CAS $urlType VALIDATE URL" );

    # GET parameters
    my $service = $req->param('service');
    my $ticket  = $req->param('ticket');
    my $pgtUrl  = $req->param('pgtUrl');
    my $renew   = $req->param('renew') // 'false';

    # PGTIOU
    my $casProxyGrantingTicketIOU;

    # Required parameters: service and ticket
    unless ( $service and $ticket ) {
        $self->logger->error("Service and Ticket parameters required");
        return $self->returnCasServiceValidateError( $req, 'INVALID_REQUEST',
            'Missing mandatory parameters (service, ticket)' );
    }

    $self->logger->debug( "Get "
          . lc($urlType)
          . " validate request with ticket $ticket for service $service" );

    # Get CAS session corresponding to ticket
    if ( $urlType eq 'SERVICE' and !( $ticket =~ s/^ST-// ) ) {
        $self->logger->error("Provided ticket is not a service ticket (ST)");
        return $self->returnCasServiceValidateError( $req, 'INVALID_TICKET',
            'Provided ticket is not a service ticket' );
    }
    elsif ( $urlType eq 'PROXY' and !( $ticket =~ s/^(P|S)T-// ) ) {
        $self->userLogger->error(
            "Provided ticket is not a service or proxy ticket ($1T)");
        return $self->returnCasServiceValidateError( $req, 'INVALID_TICKET',
            'Provided ticket is not a service or proxy ticket' );
    }

    my $casServiceSession = $self->getCasSession($ticket);

    unless ($casServiceSession) {
        $self->logger->error("$urlType ticket session $ticket not found");
        return $self->returnCasServiceValidateError( $req, 'INVALID_TICKET',
            'Ticket not found' );
    }
    my $app = $casServiceSession->data->{_casApp};

    $self->logger->debug("$urlType ticket session $ticket found");

    my $service1_uri = URI->new($service);
    my $service2_uri = URI->new( $casServiceSession->data->{service} );

    # Check service
    unless ( $service1_uri->eq($service2_uri) ) {

        # Tolerate that relative URI are the same
        if (   $service1_uri->rel($service2_uri) eq "./"
            or $service2_uri->rel($service1_uri) eq "./" )
        {
            $self->logger->notice(
"Submitted service $service1_uri does not exactly match initial service "
                  . $service2_uri
                  . ' but difference is tolerated.' );
        }
        else {
            $self->userLogger->error(
                "Submitted service $service does not match initial service "
                  . $casServiceSession->data->{service} );
            $self->deleteCasSession($casServiceSession);
            return $self->returnCasServiceValidateError( $req,
                'INVALID_SERVICE',
                'Submitted service does not match initial service' );
        }
    }
    else {
        $self->logger->debug(
            "Submitted service $service match initial service");
    }

    # Check renew
    if ( $renew and $renew eq 'true' ) {

        # We should check the ST was delivered with primary credentials
        $self->logger->debug("Renew flag detected ");

        unless ( $casServiceSession->data->{renew} ) {
            $self->logger->error(
"Authentication renew requested, but not done in former authentication process"
            );
            $self->deleteCasSession($casServiceSession);
            return $self->returnCasValidateError();
        }

    }

    # Proxies (for PROXY VALIDATE only)
    my $proxies = $casServiceSession->data->{proxies};

    # Proxy granting ticket
    if ($pgtUrl) {

        # Create a proxy granting ticket
        $self->logger->debug(
            "Create a CAS proxy granting ticket for service $service");

        my $PGinfos;

        # PGT session
        $PGinfos->{type}    = 'casProxyGranting';
        $PGinfos->{service} = $service;
        $PGinfos->{_cas_id} = $casServiceSession->data->{_cas_id};
        $PGinfos->{_utime}  = $casServiceSession->data->{_utime};
        $PGinfos->{_casApp} = $app;

        # Trace proxies
        $PGinfos->{proxies} = (
              $proxies
            ? $proxies . $self->conf->{multiValuesSeparator} . $pgtUrl
            : $pgtUrl
        );

        my $casProxyGrantingSession = $self->getCasSession( undef, $PGinfos );

        if ($casProxyGrantingSession) {

            my $casProxyGrantingSessionID = $casProxyGrantingSession->id;
            my $casProxyGrantingTicket    = "PGT-" . $casProxyGrantingSessionID;

            $self->logger->debug(
                "CAS proxy granting session $casProxyGrantingSessionID created"
            );

            # Generate the proxy granting ticket IOU
            my $tmpCasSession = $self->getCasSession();

            if ($tmpCasSession) {

                $casProxyGrantingTicketIOU = "PGTIOU-" . $tmpCasSession->id;
                $self->deleteCasSession($tmpCasSession);
                $self->logger->debug(
"Generate proxy granting ticket IOU $casProxyGrantingTicketIOU"
                );

                # Request pgtUrl
                if (
                    $self->callPgtUrl(
                        $pgtUrl, $casProxyGrantingTicketIOU,
                        $casProxyGrantingTicket
                    )
                  )
                {
                    $self->logger->debug(
                        "Proxy granting URL $pgtUrl called with success");
                }
                else {
                    $self->logger->error(
                        "Error calling proxy granting URL $pgtUrl");
                    $casProxyGrantingTicketIOU = undef;
                }
            }

        }
        else {
            $self->logger->warn(
                "Error in proxy granting ticket management, bypass it");
        }
    }

    # Open local session
    my $localSession =
      $self->p->getApacheSession( $casServiceSession->data->{_cas_id} );

    unless ($localSession) {
        $self->userLogger->error( "Local session "
              . $casServiceSession->data->{_cas_id}
              . " notfound" );
        $self->deleteCasSession($casServiceSession);
        return $self->returnCasServiceValidateError( $req, 'INTERNAL_ERROR',
            'No session associated to ticket' );
    }

    # Get username
    my $username_attribute =
      (       $app
          and $self->conf->{casAppMetaDataOptions}->{$app}
          ->{casAppMetaDataOptionsUserAttribute} )
      ? $self->conf->{casAppMetaDataOptions}->{$app}
      ->{casAppMetaDataOptionsUserAttribute}
      : (    $self->conf->{casAttr}
          || $self->conf->{whatToTrace} );

    my $username = $localSession->data->{$username_attribute};

    $self->logger->debug("Get username $username");

    # Get attributes [CAS 3.0]
    my $attributes = {};
    my $ev =
      ( $app and $self->conf->{casAppMetaDataExportedVars}->{$app} )
      ? $self->conf->{casAppMetaDataExportedVars}->{$app}
      : {};
    unless (%$ev) {
        $ev = $self->conf->{casAttributes} || {};
    }

    foreach my $casAttribute ( keys %$ev ) {
        my $localSessionValue = $localSession->data->{ $ev->{$casAttribute} };
        $attributes->{$casAttribute} = $localSessionValue
          if defined $localSessionValue;
    }

    # Return success message
    $self->deleteCasSession($casServiceSession);
    return $self->returnCasServiceValidateSuccess( $req, $username,
        $casProxyGrantingTicketIOU, $proxies, $attributes );
}

1;
