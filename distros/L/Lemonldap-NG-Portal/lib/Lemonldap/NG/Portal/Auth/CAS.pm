package Lemonldap::NG::Portal::Auth::CAS;

use strict;
use Mouse;
use URI::Escape;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_REDIRECT
  PE_IDPCHOICE
  PE_SENDRESPONSE
);

our $VERSION = '2.23.0';

extends qw(
  Lemonldap::NG::Portal::Main::Auth
  Lemonldap::NG::Portal::Lib::CAS
);

# PROPERTIES

has srvNumber => ( is => 'rw', default => 0 );
has srvList   => ( is => 'rw', default => sub { [] } );
use constant sessionKind => 'CAS';
use constant afterData   => 'authFinish';

# INITIALIZATION

sub init {
    my ($self) = @_;

    return 0 unless ( $self->loadSrv );
    my @tab = ( keys %{ $self->casSrvList } );
    unless (@tab) {
        $self->logger->error("No CAS server configured");
        return 0;
    }
    $self->srvNumber( scalar @tab );
    my @list;

    foreach (@tab) {
        my $name = $_;
        $name =
          $self->conf->{casSrvMetaDataOptions}->{$_}
          ->{casSrvMetaDataOptionsDisplayName}
          if $self->conf->{casSrvMetaDataOptions}->{$_}
          ->{casSrvMetaDataOptionsDisplayName};
        my $icon = $self->conf->{casSrvMetaDataOptions}->{$_}
          ->{casSrvMetaDataOptionsIcon};
        my $tooltip = $self->conf->{casSrvMetaDataOptions}->{$_}
          ->{casSrvMetaDataOptionsTooltip} || $name;
        my $order = $self->conf->{casSrvMetaDataOptions}->{$_}
          ->{casSrvMetaDataOptionsSortNumber} // 0;
        my $img_src;

        if ($icon) {
            $img_src =
              ( $icon =~ m#^https?://# )
              ? $icon
              : $self->p->staticPrefix . "/common/" . $icon;
        }
        push @list,
          {
            val   => $_,
            name  => $name,
            title => $tooltip,
            icon  => $img_src,
            order => $order
          };
    }
    @list =
      sort {
             $a->{order} <=> $b->{order}
          or $a->{name} cmp $b->{name}
          or $a->{val} cmp $b->{val}
      } @list;
    $self->srvList( \@list );

    return 1;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;

    # Local URL
    my $local_url = $self->p->fullUrl($req);

    # Remove cancel parameter
    $local_url =~ s/cancel=1&?//;

    # Catch proxy callback
    if ( $req->param('casProxy') ) {
        $self->logger->debug("CAS: Proxy callback detected");

        my $pgtIou = $req->param('pgtIou');
        my $pgtId  = $req->param('pgtId');

        if ( $pgtIou and $pgtId ) {

            # Store pgtId and pgtIou
            my $pgtSessionId = $self->storePGT( $pgtIou, $pgtId );
            unless ($pgtSessionId) {
                $self->userLogger->error(
                    "CAS: Unable to store pgtIou $pgtIou and pgtId $pgtId");
            }
            else {
                $self->logger->debug(
"CAS: Store pgtIou $pgtIou and pgtId $pgtId in session $pgtSessionId"
                );
            }
        }

        # Exit
        $req->response( $self->p->sendBinaryResponse( $req, "" ) );
        return PE_SENDRESPONSE;
    }

    if ($req->param('logoutRequest')) {
        my $xml = eval { $self->parser->parse_string( $req->param('logoutRequest') ) };
        if ($@) {
            $self->logger->error("Could not process logoutRequest: $@");
        } else {
            my $xpc = XML::LibXML::XPathContext->new($xml);
            $xpc->registerNs( 'samlp', 'urn:oasis:names:tc:SAML:2.0:protocol' );
            if (my $ticket = $xpc->findnodes('/samlp:LogoutRequest/samlp:SessionIndex')->string_value) {
                $self->_handleBackChannelLogout($req, $ticket);
            }
        }
        $req->response( [ 200, [ 'Content-Length' => 0 ], [] ] );
        return PE_SENDRESPONSE;
    }

    my $srv;

    # Check Service Ticket
    my $ticket = $req->param('ticket');

    # Check if CAS server is chosen
    unless ( ( $ticket and $srv = $req->cookies->{llngcasserver} )
        or $srv = $req->param('idp') )
    {
        $self->logger->debug("Redirecting user to CAS server list");

        # Auto select provider if there is only one
        if ( $self->srvNumber == 1 ) {
            ($srv) = keys %{ $self->casSrvList };
            $self->logger->debug("Selecting the only defined CAS server: $srv");
        }

        else {

            # Try to use server resolution rules
            foreach ( keys %{ $self->srvRules } ) {
                my $cond = $self->srvRules->{$_} or next;
                if ( $cond->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug(
                        "CAS Server $_ selected from resolution rule");
                    $srv = $_;
                    last;
                }
            }

            unless ($srv) {

                # Server list
                $req->data->{list}  = $self->srvList;
                $req->data->{login} = 1;
                return PE_IDPCHOICE;
            }
        }
    }

    my $srvConf = $self->conf->{casSrvMetaDataOptions}->{$srv};
    unless ($srvConf) {
        $self->userLogger->error("CAS server $srv not configured");
        return PE_ERROR;
    }

    # Provider is choosen
    $self->logger->debug("CAS server $srv choosen");

    $req->data->{_casSrvCurrent} = $srv;

    # Unless a ticket has been found, we redirect the user
    unless ($ticket) {

        # Add request state parameters
        if ( $req->data->{_url} ) {
            $local_url .= ( $local_url =~ /\?/ ? '&' : '?' )
              . build_urlencoded( url => $req->data->{_url} );
        }

        # Forward hidden fields
        if ( $req->{portalHiddenFormValues}
            and %{ $req->{portalHiddenFormValues} } )
        {

            $self->logger->debug("Add hidden values to CAS redirect URL\n");
            $local_url .= ( $local_url =~ /\?/ ? '&' : '?' )
              . build_urlencoded( %{ $req->{portalHiddenFormValues} } );
        }

        # Build login URL
        my $login_url = $self->getServerLoginURL( $local_url, $srvConf );
        $login_url .= '&renew=true' if $srvConf->{casSrvMetaDataOptionsRenew};
        $login_url .= '&gateway=true'
          if $srvConf->{casSrvMetaDataOptionsGateway};

        $self->logger->debug("CAS: Redirect user to $login_url");
        $req->{urldc} = $login_url;
        $req->steps( [] );
        $req->addCookie(
            $self->p->cookie(
                name   => 'llngcasserver',
                value  => $srv,
                secure => $self->conf->{securedCookie},
            )
        );
        return PE_REDIRECT;
    }

    $self->logger->debug("CAS: Service Ticket received: $ticket");

    # save it for authFinish
    $req->data->{ticket} = $ticket;

    my $proxied =
      $self->conf->{casSrvMetaDataOptionsProxiedServices}->{$srv} || {};

    # Ticket found, try to validate it
    $local_url =~ s/ticket=[^&]+//;
    $local_url =~ s/\?$//;
    $local_url =~ s/\&$//;
    ( $req->{user}, $req->data->{casAttrs} ) =
      $self->validateST( $req, $local_url, $ticket, $srvConf, $proxied );
    unless ( $req->{user} ) {
        $self->userLogger->error("CAS: Unable to validate ST $ticket");
        return PE_ERROR;
    }
    else {
        $self->logger->debug("CAS: User $req->{user} found");
    }

    # Request proxy tickets for proxied services
    if (%$proxied) {

        # Check we received a PGT
        my $pgtId = $req->data->{pgtId};

        unless ($pgtId) {
            $self->logger->error(
                "CAS: Proxy mode activated, but no PGT received");
            return PE_ERROR;
        }

        # Get a proxy ticket for each proxied service
        foreach ( keys %$proxied ) {
            my $service = $proxied->{$_};
            my $pt      = $self->retrievePT( $service, $pgtId, $srvConf );

            unless ($pt) {
                $self->logger->error(
                    "CAS: No proxy ticket received for service $service");
                return PE_ERROR;
            }

            $self->logger->debug(
                "CAS: Received proxy ticket $pt for service $service");

            # Store it in session
            $req->{sessionInfo}->{ '_casPT' . $_ } = $pt;
        }

    }

    return PE_OK;
}

sub _handleBackChannelLogout {
    my ($self, $req, $ticket) = @_;

    $self->logger->debug("CAS: Received BackChannel logoutRequest for ticket $ticket");

    if (my $id = $self->getSSOSessionIdByTicket($ticket)) {
        my $sessionData = $self->p->HANDLER->retrieveSession( $req, $id );
        if ($sessionData) {
          $self->logger->debug("Doing backchannel logout on session $id");
          $req->userData( $req->sessionInfo($sessionData) );
          $self->p->do( $req,
            [ @{ $self->p->beforeLogout }, 'authLogout', 'deleteSession' ] );
        }
    }
}

# Saves the link between IDP-side Session ID/NameID and LLNG session
sub authFinish {
    my ( $self, $req ) = @_;

    # Get saved ticket
    my $ticket = $req->data->{ticket};

    # Auth::CAS was not used for this session
    return unless ($ticket);

    # Real session was stored, get id and utime
    my $id    = $req->{id};
    my $utime = $req->{sessionInfo}->{_utime};

    $self->logger->debug( "Store ticket "
          . $ticket
          . " for session $id" );

    my $infos;
    $infos->{type}            = 'casTicket';  # Session type
    $infos->{_utime}          = $utime;       # Creation time
    $infos->{_cas_id}         = $id;          # SSO session id
    $infos->{auth_cas_ticket} = $ticket;      # CAS ticket

    # Save CAS session
    my $CASSessionInfo = $self->getCasSession( undef, $infos );

    return PE_ERROR unless $CASSessionInfo;

    my $session_id = $CASSessionInfo->id;

    $self->logger->debug("Link session $id to CAS session $session_id");

    return PE_OK;
}

sub authenticate {
    return PE_OK;
}

# Set authenticationLevel.
sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{casAuthnLevel};
    $req->{sessionInfo}->{_casSrv}             = $req->data->{_casSrvCurrent};
    return PE_OK;
}

sub authLogout {
    my ( $self, $req ) = @_;

    # Real session was previously deleted,
    # remove corresponding CAS sessions
    my $session_id = $req->sessionInfo->{_session_id};
    $self->deleteCasSecondarySessions($session_id);

    # Build CAS logout URL
    my $logout_url = $self->getServerLogoutURL( $self->p->fullUrl($req),
        $self->conf->{casSrvMetaDataOptions}->{ $req->userData->{_casSrv} }
          ->{casSrvMetaDataOptionsUrl} );

    $self->logger->debug("Build CAS logout URL: $logout_url");

    # Register CAS logout URL in logoutServices
    $req->data->{logoutServices}->{CASserver} = $logout_url;

    return PE_OK;
}

sub getDisplayType {
    return "logo";
}

1;
