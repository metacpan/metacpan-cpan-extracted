package Lemonldap::NG::Portal::Issuer::CAS;

use strict;
use Mouse;
use URI;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  portalConsts
  URIRE
  PE_OK
  PE_INFO
  PE_ERROR
  PE_LOGOUT_OK
  PE_SENDRESPONSE
  PE_UNKNOWNPARTNER
  PE_UNAUTHORIZEDURL
  PE_UNAUTHORIZEDPARTNER
  PE_BADURL
  PE_CAS_SERVICE_NOT_ALLOWED
);
use URI;

our $VERSION = '2.21.0';

extends 'Lemonldap::NG::Portal::Main::Issuer',
  'Lemonldap::NG::Portal::Lib::CAS';

# INITIALIZATION

use constant beforeAuth  => 'storeEnvAndCheckGateway';
use constant sessionKind => 'ICAS';

use constant hook => { updateSessionId => 'updateCasSecondarySessions', };

has rule => ( is => 'rw' );

sub init {
    my ($self) = @_;

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug( "CAS rule -> " . $self->conf->{issuerDBCASRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{issuerDBCASRule} ) );
    unless ($rule) {
        my $error = $hd->tsv->{jail}->error || '???';
        $self->error("Bad CAS activation rule -> $error");
        return 0;
    }
    $self->{rule} = $rule;

    # Launch parents initialization subroutines, then launch IdP and SP lists
    my $res = $self->Lemonldap::NG::Portal::Main::Issuer::init();
    return 0 unless ( $self->loadApp );
    $self->addUnauthRoute(
        ( $self->path ) => {
            samlValidate    => 'samlValidate',
            serviceValidate => 'serviceValidate',
            relayLogout     => 'relayLogout',
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

    $self->addUnauthRoute(
        ( $self->path ) => {
            samlValidate => 'samlValidate',
        },
        ['POST']
    );

    # Add CAS Services, so we can check service= parameter on logout
    foreach my $casSrv ( keys %{ $self->casAppList } ) {
        for my $serviceUrl (
            split(
                /\s+/,
                $self->casAppList->{$casSrv}->{casAppMetaDataOptionsService}
            )
          )
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
    $service = '' if ( $self->p->checkXSSAttackUrldc( 'service', $service ) );
    my $gateway = $self->p->getHiddenFormValue( $req, 'gateway' )
      || $req->param('gateway');

    if ( $gateway and $gateway eq "true" ) {
        if ( $self->_gatewayAllowedRedirect( $req, $service ) ) {
            $self->logger->debug(
                "Gateway mode requested, redirect without authentication");
            $req->response(
                [ 302, [ Location => URI->new($service)->as_string ], [] ] );
            for my $s ( $self->ipath, $self->ipath . 'Path' ) {
                $self->logger->debug("Removing $s from pdata")
                  if delete $req->pdata->{$s};
            }

            return PE_SENDRESPONSE;
        }
        else {
            $self->logger->error(
                "Disallowing redirection to unknown service $service");
            return PE_UNKNOWNPARTNER;
        }
    }

    if ( $service and $service =~ URIRE ) {
        my $app = $self->getCasApp($service);

        if ($app) {
            $req->env->{llng_cas_app} = $app;

            # Store target authentication level in pdata
            my $targetAuthnLevel = $self->spLevelRules->{$app}->( $req, {} );

            $req->pdata->{targetAuthnLevel} = $targetAuthnLevel
              if $targetAuthnLevel;

        }
    }

    return PE_OK;
}

sub _gatewayAllowedRedirect {
    my ( $self, $req, $service ) = @_;

    my $app                    = $self->getCasApp($service);
    my $casAccessControlPolicy = $self->conf->{casAccessControlPolicy};

    # Redirect is allowed if there is no access control or if
    # the service is declared in CAS apps
    if ( $casAccessControlPolicy !~ /^(error|faketicket)$/i ) {
        return 1;
    }
    if ($app) {
        return 1;
    }

    return 0;
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
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->id;

    # 1. LOGIN
    if ( $target eq $cas_login ) {

        $self->logger->debug("URL $url detected as an CAS LOGIN URL");

        my $cas_request = {};

        foreach my $param (qw/service renew gateway/) {
            $cas_request->{$param} =
                 $self->p->getHiddenFormValue( $req, $param )
              || $req->param($param);
        }

        my $h = $self->p->processHook( $req, 'casGotRequest', $cas_request );
        return $self->_failLogin(
            $req,
            msg => "casGotRequest hook failed",
            res => $h
        ) if ( $h != PE_OK );

        my $service = $cas_request->{service};
        $service = ''
          if ( $self->p->checkXSSAttackUrldc( 'service', $service ) );
        my $renew   = $cas_request->{renew};
        my $gateway = $cas_request->{gateway};

        # If no service defined, exit
        unless ( defined $service ) {
            $self->logger->debug("No service defined in CAS URL");
            return PE_OK;
        }

        unless ( $service =~ m#^(https?://[^/]+)(/.*)?$# ) {
            return $self->_failLogin(
                $req,
                msg => "Bad service $service",
                res => PE_BADURL,
            );
        }
        my $app = $self->getCasApp($service);

        my $spAuthnLevel = 0;
        if ($app) {
            $spAuthnLevel =
              $self->spLevelRules->{$app}->( $req, $req->sessionInfo );
        }

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

            $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
            return $self->reAuth($req);
        }

        # Check access on the service
        my $casAccessControlPolicy = $self->conf->{casAccessControlPolicy};

        if ( $casAccessControlPolicy =~ /^(error|faketicket)$/i ) {
            $self->logger->debug(
                "CAS access control requested on service $service");

            unless ($app) {
                return $self->_failLogin(
                    $req,
                    msg => 'CAS service not configured',
                    res => PE_UNKNOWNPARTNER,
                );
            }

            # Check if we have sufficient auth level
            my $authenticationLevel =
              $req->{sessionInfo}->{authenticationLevel} || 0;
            if ( $authenticationLevel < $spAuthnLevel ) {
                $self->logger->debug(
                        "Insufficient authentication level for service $app"
                      . " (has: $authenticationLevel, want: $spAuthnLevel)" );

                # Reauth with sp auth level as target
                $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
                return $self->upgradeAuth($req);
            }

            # Check access rule
            if ( my $rule = $self->spRules->{$app} ) {
                if ( $rule->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug("CAS service $service access allowed");
                }
                else {
                    return $self->_failLoginRule( $req, $cas_request, $app );
                }
            }
        }

        # Check last authentication time to decide if
        # the authentication is recent or not
        my $casRenewFlag     = 0;
        my $last_authn_utime = $req->{sessionInfo}->{_lastAuthnUTime} || 0;
        if (
            time() - $last_authn_utime <
            $self->conf->{portalForceAuthnInterval} )
        {
            $self->logger->debug(
                "Authentication is recent, will set CAS renew flag to true");
            $casRenewFlag = 1;
        }

        # Create a service ticket
        $self->logger->debug(
            "Create a CAS service ticket for service $service");

        my $_utime =
          $self->conf->{casTicketExpiration}
          ? (
            time + $self->conf->{casTicketExpiration} - $self->conf->{timeout} )
          : ( $req->{sessionInfo}->{_utime} || time() );

        my $Sinfos;
        $Sinfos->{type}    = 'casService';
        $Sinfos->{service} = $service;
        $Sinfos->{renew}   = $casRenewFlag;
        $Sinfos->{_cas_id} = $session_id;
        $Sinfos->{_utime}  = $_utime;
        $Sinfos->{_casApp} = $app;

        $h = $self->p->processHook( $req, 'casGenerateServiceTicket',
            $cas_request, $app, $Sinfos );
        return $self->_failLogin(
            $req,
            msg => 'casGenerateServiceTicket hook failed',
            res => $h,
            ( $app ? ( app => $app ) : () ),
        ) if ( $h != PE_OK );

        my $casServiceSession = $self->getCasSession( undef, $Sinfos );

        unless ($casServiceSession) {
            return $self->_failLogin(
                $req,
                msg => "Unable to create CAS session",
                ( $app ? ( app => $app ) : () ),
            );
        }

        my $casServiceSessionID = $casServiceSession->id;
        my $casServiceTicket    = "ST-" . $casServiceSessionID;

        $self->logger->debug(
            "CAS service session $casServiceSessionID created");

        my $user = $req->sessionInfo->{ $self->conf->{whatToTrace} };
        $self->auditLog(
            $req,
            code => "ISSUER_CAS_LOGIN_SUCCESS",
            ( $app ? ( app => $app ) : () ),
            service => $service,
            user    => $user,
            message => (
                $app
                ? ("User $user is authorized to access to $app")
                : ("User $user is redirected to $service")
            ),
        );

        return $self->_redirectUser( $req, $cas_request->{service},
            $casServiceTicket );
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
          if ( $self->p->checkXSSAttackUrldc( 'service', $logout_service ) );

        # If we use access control, check that the service URL is trusted
        if ( $self->conf->{casAccessControlPolicy} =~ /^(error|faketicket)$/i )
        {
            if ( $logout_service
                and not $self->p->isTrustedUrl($logout_service) )
            {
                $self->userLogger->error(
                        "Untrusted service URL $logout_service"
                      . "specified for CAS Logout" );
                return PE_UNAUTHORIZEDURL;
            }
        }

        # Delete local session
        if ( my $session = $self->p->getApacheSession($session_id) ) {

           # This will call Issuer logout methods, incluing our own
           # TODO: call authLogout and deleteSession instead of duplicating code
            my $res = $self->p->do( $req, [ @{ $self->p->beforeLogout } ] );

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
                return $self->_redirectUser( $req, $logout_service );
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
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->id;

    # Delete linked CAS sessions
    $self->deleteCasSecondarySessions($session_id) if ($session_id);

    $self->_send_back_channel_LogoutRequests( $req, $req->sessionInfo );

    return PE_OK;
}

# Direct request from SP to IdP
sub validate {
    my ( $self, $req ) = @_;
    $self->logger->debug(
        'URL ' . $req->uri . ' detected as an CAS VALIDATE URL' );

    return $self->_validate_generic(
        $req,
        ticket  => scalar( $req->param('ticket') ),
        service => scalar( $req->param('service') ),
        renew   => scalar( $req->param('renew') ),
        success => 'returnCasValidateSuccess',
        failure => '_failValidate1',
    );
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
        $self->logger->warn("Proxy granting ticket session $pgt not found");
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

    my $_utime =
      $self->conf->{casTicketExpiration}
      ? ( time + $self->conf->{casTicketExpiration} - $self->conf->{timeout} )
      : $casProxyGrantingSession->data->{_utime};

    my $Pinfos;
    $Pinfos->{type}    = 'casProxy';
    $Pinfos->{service} = $targetService;
    $Pinfos->{_cas_id} = $casProxyGrantingSession->data->{_cas_id};
    $Pinfos->{_utime}  = $_utime;
    $Pinfos->{proxies} = $casProxyGrantingSession->data->{proxies};

    $casProxySession->update($Pinfos);

    my $casProxySessionID = $casProxySession->id;
    my $casProxyTicket    = "PT-" . $casProxySessionID;

    $self->logger->debug("CAS proxy session $casProxySessionID created");

    return $self->returnCasProxySuccess( $req, $casProxyTicket );
}

sub serviceValidate {
    my ( $self, $req ) = @_;

    $self->logger->debug(
        'URL ' . $req->uri . " detected as an CAS SERVICE VALIDATE URL" );

    return $self->_validate_generic(
        $req,
        service => scalar( $req->param('service') ),
        ticket  => scalar( $req->param('ticket') ),
        pgtUrl  => scalar( $req->param('pgtUrl') ),
        renew   => scalar( $req->param('renew') ),
        success => 'returnCasServiceValidateSuccess',
        failure => '_failValidate2',
    );
}

sub samlValidate {
    my ( $self, $req ) = @_;

    my $service = $req->query_parameters->{TARGET};
    my $ticket  = $self->getServiceTicketFromSamlRequest( $req->content );

    return $self->_validate_generic(
        $req,
        service => $service,
        ticket  => $ticket,
        success => 'returnSamlValidateSuccess',
        failure => '_failValidateSaml',
    );
}

sub proxyValidate {
    my ( $self, $req ) = @_;

    $self->logger->debug(
        'URL ' . $req->uri . " detected as an CAS PROXY VALIDATE URL" );

    return $self->_validate_generic(
        $req,
        ticketType => "PROXY",
        service    => scalar( $req->param('service') ),
        ticket     => scalar( $req->param('ticket') ),
        pgtUrl     => scalar( $req->param('pgtUrl') ),
        renew      => scalar( $req->param('renew') ),
        success    => 'returnCasServiceValidateSuccess',
        failure    => '_failValidate2',
    );
}

# INTERNAL METHODS

sub _validate_generic {
    my ( $self, $req, %params ) = @_;

    my $service = $params{service};
    my $ticket  = $params{ticket};
    my $renew   = $params{renew} // "false";
    my $success = $params{success};
    my $failure = $params{failure};
    my $pgtUrl  = $params{pgtUrl};
    my $urlType = $params{ticketType} // "SERVICE";

    # PGTIOU
    my $casProxyGrantingTicketIOU;

    # Required parameters: service and ticket
    unless ( $service and $ticket ) {
        $self->logger->error("Service and Ticket parameters required");
        return $self->$failure(
            $req,
            code => 'INVALID_REQUEST',
            msg  => 'Missing mandatory parameters (service, ticket)'
        );
    }

    $self->logger->debug( "Get "
          . lc($urlType)
          . " validate request with ticket $ticket for service $service" );

    # Get CAS session corresponding to ticket
    if ( $urlType eq 'SERVICE' and !( $ticket =~ s/^ST-// ) ) {
        $self->logger->error("Provided ticket is not a service ticket (ST)");
        return $self->$failure(
            $req,
            code => 'INVALID_TICKET',
            msg  => 'Provided ticket is not a service ticket'
        );
    }
    elsif ( $urlType eq 'PROXY' and !( $ticket =~ s/^(P|S)T-// ) ) {
        $self->userLogger->error(
            "Provided ticket is not a service or proxy ticket ($1T)");
        return $self->$failure(
            $req,
            code => 'INVALID_TICKET',
            msg  => 'Provided ticket is not a service or proxy ticket'
        );
    }

    my $casServiceSession = $self->getCasSession($ticket);

    unless ($casServiceSession) {
        $self->logger->warn("$urlType ticket session $ticket not found");
        return $self->$failure(
            $req,
            code => 'INVALID_TICKET',
            msg  => 'Ticket not found'
        );
    }
    $self->deleteCasSession($casServiceSession);

    # Make sure the token is still valid, we already compensated for
    # different TTLs when storing _utime
    if ( $casServiceSession->{data}->{_utime} ) {
        if (
            time >
            ( $casServiceSession->{data}->{_utime} + $self->conf->{timeout} ) )
        {
            $self->logger->info("$urlType ticket session $ticket has expired");
            return $self->$failure(
                $req,
                code => 'INVALID_TICKET',
                msg  => 'Ticket expired'
            );
        }
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
            $self->logger->notice( "Submitted service $service1_uri"
                  . " does not exactly match initial service "
                  . $service2_uri
                  . ' but difference is tolerated.' );
        }
        else {
            $self->userLogger->error(
                "Submitted service $service does not match initial service "
                  . $casServiceSession->data->{service} );
            $self->deleteCasSession($casServiceSession);
            return $self->_failValidate2(
                $req,
                app  => $app,
                code => 'INVALID_SERVICE',
                msg  => 'Submitted service does not match initial service'
            );
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
            $self->logger->error( "Authentication renew requested,"
                  . " but not done in former authentication process" );
            return $self->$failure(
                $req,
                app  => $app,
                code => 'INVALID_TICKET',
                msg  => 'Authentication renew requested,'
                  . ' but not done in former authentication process'
            );
        }

    }

    # Proxies (for PROXY VALIDATE only)
    my $proxies = $casServiceSession->data->{proxies};

    # Proxy granting ticket
    if ($pgtUrl) {

        my $allow_proxy = 1;
        if ($app) {
            $allow_proxy =
              $self->casAppList->{$app}->{casAppMetaDataOptionsAllowProxy} // 1;
        }
        if ( !$allow_proxy ) {
            return $self->$failure(
                $req,
                app  => $app,
                code => 'UNAUTHORIZED_SERVICE_PROXY',
                msg  => 'CAS proxy is not allowed'
            );
        }

        # Create a proxy granting ticket
        $self->logger->debug(
            "Create a CAS proxy granting ticket for service $service");

        my $PGinfos;

        # PGT session
        $PGinfos->{type}    = 'casProxyGranting';
        $PGinfos->{service} = $service;
        $PGinfos->{_cas_id} = $casServiceSession->data->{_cas_id};
        $PGinfos->{_utime}  = time;
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
                $self->logger->debug( "Generate proxy granting ticket IOU"
                      . $casProxyGrantingTicketIOU );

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
        $self->userLogger->warn( "Local session "
              . $casServiceSession->data->{_cas_id}
              . " notfound" );
        return $self->$failure(
            $req,
            app  => $app,
            code => 'INTERNAL_ERROR',
            msg  => 'No session associated to ticket'
        );
    }

    # Get username
    my $username = $self->getUsernameForApp( $req, $app, $localSession->data );

    # Useful for logging
    $req->sessionInfo( $localSession->data );

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
        my $sessionAttr = $ev->{$casAttribute};
        my $value;

        # Lookup per-service macros first, and then local sessions
        #
        if ( $app and $self->spMacros->{$app}->{$sessionAttr} ) {
            $value = $self->spMacros->{$app}->{$sessionAttr}
              ->( $req, $localSession->data );
        }
        else {
            $value = $localSession->data->{$sessionAttr};
        }

        $attributes->{$casAttribute} = $value
          if defined $value;
    }

    # Return success message
    if ( $self->isLogoutEnabled($app) ) {
        $self->_save_ticket_for_single_logout( $localSession, $service,
            $req->param('ticket') );
    }

    $self->p->registerProtectedAppAccess( $req, $username, "cas:$app" ) if $app;

    my $h =
      $self->p->processHook( $req, 'casGenerateValidateResponse', $username,
        $attributes );
    return $self->$failure(
        $req,
        app  => $app,
        code => "INTERNAL_ERROR",
        msg  => "Internal error during request validation",
        res  => $h,
    ) if ( $h != PE_OK );

    my $user   = $req->sessionInfo->{ $self->conf->{whatToTrace} };
    my $by_app = $app ? " by $app" : "";
    my $attr_str =
        ( defined($attributes) && keys %$attributes )
      ? ( " with attributes " . join( ',', sort( keys(%$attributes) ) ) )
      : "";
    $self->auditLog(
        $req,
        code    => "ISSUER_CAS_VALIDATE_SUCCESS",
        message => (
                "CAS validation succeeded for ${user}${by_app}"
              . " as ${username}${attr_str}"
        ),
        ( $app ? ( app => $app ) : () ),
        user        => $user,
        cas_user    => $username,
        cas_proxies => $proxies,
        attributes  => $attributes,
    );
    return $self->$success( $req, $username,
        $casProxyGrantingTicketIOU, $proxies, $attributes );
}

# Returns the main attribute (sub) to use for this App
# It can be a session attribute, or per-App macro
sub getUsernameForApp {
    my ( $self, $req, $app, $data ) = @_;

    my $username_attribute =
      (       $app
          and $self->casAppList->{$app}->{casAppMetaDataOptionsUserAttribute} )
      ? $self->casAppList->{$app}->{casAppMetaDataOptionsUserAttribute}
      : (    $self->conf->{casAttr}
          || $self->conf->{whatToTrace} );

    my $username;

    # If the main attribute is a SP macro, resolve it
    # else, get it directly from session data
    if ( $app and $self->spMacros->{$app}->{$username_attribute} ) {
        $username =
          $self->spMacros->{$app}->{$username_attribute}->( $req, $data );
    }
    else {
        $username = $data->{$username_attribute};
    }
    return $username;
}

sub _save_ticket_for_single_logout {
    my ( $self, $localSession, $service, $ticket ) = @_;

    $self->logger->debug("Saving service $service ticket $ticket for SLO");

    my $service2ticket = $localSession->data->{cas_tickets_for_SLO} || {};
    $service2ticket->{$service} = $ticket;
    $localSession->update( { cas_tickets_for_SLO => $service2ticket } );
}

sub _send_back_channel_LogoutRequests {
    my ( $self, $req, $sessionData ) = @_;

    my $service2ticket = $sessionData->{cas_tickets_for_SLO} or return;

    my $content;
    foreach my $service ( keys %$service2ticket ) {

        # Create a new relay session
        my $relayInfos = {
            service => $service,
            ticket  => $service2ticket->{$service},
            _type   => "relay"
        };
        my $relaySession = $self->getCasSession( undef, $relayInfos );
        my $relayid      = $relaySession->id;

        # Build the URL that could be used to play this logout request
        my $slo_url =
          $self->p->buildUrl( $req->portal, "cas", "relayLogout",
            { relay => $relayid } );

        my $name = $self->getNameFromService($service);

        # Display information to the user
        $content .= $self->loadTemplate(
            $req,
            'samlSpSoapLogout',
            params => {
                imgUrl => $slo_url,
                name   => $name,
            }
        );
    }

    # Build Relay URL and display it
    $req->info(
        $self->loadTemplate(
            $req, 'samlSpsLogout', params => { content => $content }
        )
    ) if $content;
}

sub getNameFromService {
    my ( $self, $service ) = @_;

    my $app = $self->getCasApp($service);
    if ( $self->casAppList->{$app}->{casAppMetaDataOptionsDisplayName} ) {
        return $self->casAppList->{$app}->{casAppMetaDataOptionsDisplayName};
    }
    return $app;
}

sub relayLogout {
    my ( $self, $req ) = @_;

    my $relay = $req->param("relay");
    unless ($relay) {
        $self->logger->error("Missing relay parameter");
        return $self->p->imgnok($req);
    }

    my $session = $self->getCasSession($relay);
    unless ($session) {
        $self->logger->warn("CAS session $relay not found");
        return $self->p->imgnok($req);
    }

    unless ( $session->data->{_type} eq "relay" ) {
        $self->logger->error( "CAS session $relay has incorrect type "
              . $session->data->{_type} );
        return $self->p->imgnok($req);
    }

    my $service = $session->data->{service};
    my $ticket  = $session->data->{ticket};
    $self->logger->debug(
        "Sending back-channel LogoutRequest to $service (ticket $ticket)");

    my $logoutRequest = $self->buildLogoutRequest($ticket);

    $self->logger->debug("Sending back-channel LogoutRequest to $service");
    my $response = $self->ua->post(
        $service,
        { logoutRequest => $logoutRequest },
        "Content-Type" => 'application/x-www-form-urlencoded'
    );

    if ( $response->is_success ) {
        $self->logger->debug("CAS back-channel logout to $service OK");
        return $self->p->imgok($req);
    }
    else {
        $self->logger->error( "CAS back-channel logout to $service error: "
              . $response->message );
        $self->logger->debug( $response->dump );
        return $self->p->imgnok($req);
    }
}

sub isLogoutEnabled {
    my ( $self, $app ) = @_;

    my $option = -1;
    if ($app) {
        $option = $self->casAppList->{$app}->{casAppMetaDataOptionsLogout}
          // -1;
    }

    if ( $option == -1 ) {
        return $self->conf->{casBackChannelSingleLogout} || 0;
    }
    else {
        return $option;
    }
}

sub _failValidate1 {
    my ( $self, $req, %params ) = @_;
    my $reason = $params{'msg'} ? ": $params{'msg'}" : "";
    my $res    = $params{res} || PE_ERROR;
    my $app    = $params{app};

    $self->auditLog(
        $req,
        code    => "ISSUER_CAS_VALIDATE_FAILED",
        message => ( "CAS validation failed" . $reason ),
        ( $reason ? ( reason => $reason ) : () ),
        ( $app    ? ( app    => $app )    : () ),
        portal_error => portalConsts->{$res},
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

    return $self->returnCasValidateError();
}

sub _failValidate2 {
    my ( $self, $req, %params ) = @_;
    my $message = $params{'msg'} ? ": $params{'msg'}" : "";
    my $reason  = $params{'msg'};
    my $code    = $params{'code'} || 'INTERNAL_ERROR';
    my $res     = $params{res}    || PE_ERROR;
    my $app     = $params{app};

    $self->auditLog(
        $req,
        code    => "ISSUER_CAS_VALIDATE_FAILED",
        message => ( "CAS validation failed" . $message ),
        ( $reason ? ( reason => $reason ) : () ),
        ( $app    ? ( app    => $app )    : () ),
        cas_code     => $code,
        portal_error => portalConsts->{$res},
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

    return $self->returnCasServiceValidateError( $req, $code, $reason );
}

sub _failValidateSaml {
    my ( $self, $req, %params ) = @_;
    my $message = $params{'msg'} ? ": $params{'msg'}" : "";
    my $reason  = $params{'msg'};
    my $code    = $params{'code'};
    my $res     = $params{res} || PE_ERROR;
    my $app     = $params{app};

    $self->auditLog(
        $req,
        code    => "ISSUER_CAS_VALIDATE_FAILED",
        message => ( "CAS validation failed" . $message ),
        ( $reason ? ( reason => $reason ) : () ),
        ( $app    ? ( app    => $app )    : () ),
        cas_code     => $code,
        portal_error => portalConsts->{$res},
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

    return $self->returnSamlValidateError( $req, $code, $reason );
}

sub _failLogin {
    my ( $self, $req, %params ) = @_;
    my $reason = $params{'msg'} ? ": $params{'msg'}" : "";
    my $res    = $params{res} || PE_ERROR;
    my $app    = $params{app};

    $self->auditLog(
        $req,
        code    => "ISSUER_CAS_LOGIN_FAILED",
        message => ( "CAS login failed" . $reason ),
        ( $reason ? ( reason => $reason ) : () ),
        ( $app    ? ( app    => $app )    : () ),
        portal_error => portalConsts->{$res},
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

    return $res;
}

sub _failLoginRule {
    my ( $self, $req, $cas_request, $app ) = @_;
    my $casAccessControlPolicy = $self->conf->{casAccessControlPolicy};

    my $user = $req->sessionInfo->{ $self->conf->{whatToTrace} };
    $self->auditLog(
        $req,
        code => "ISSUER_CAS_LOGIN_FAILED",
        ( $app ? ( app => $app ) : () ),
        message  => ("User $user is not authorized to access to $app"),
        reason   => "User is not authorized by access rule",
        user     => $user,
    );

    if ( $casAccessControlPolicy =~ /^(error)$/i ) {
        return PE_UNAUTHORIZEDPARTNER;
    }
    else {
        return $self->_redirectUser( $req, $cas_request->{service},
            "ST-F4K3T1CK3T" );
    }
}

sub _redirectUser {
    my ( $self, $req, $destination, $ticket ) = @_;

    # Redirect to service
    # cas_request may have been modified by hook
    if ($ticket) {
        $destination .= ( $destination =~ /\?/ ? '&' : '?' )
          . build_urlencoded( ticket => $ticket );
    }

    $self->logger->debug("Redirect user to $destination");

    $req->{urldc} = $destination;
    $req->steps( [] );
    return PE_OK;
}

1;
