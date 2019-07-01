package Lemonldap::NG::Portal::Plugins::CheckUser;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_TOKENEXPIRED
  PE_NOTOKEN
  PE_MALFORMEDUSER
);

our $VERSION = '2.0.5';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
  Lemonldap::NG::Portal::Lib::OtherSessions
);

# INITIALIZATION

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);
has idRule => ( is => 'rw', default => sub { 1 } );

sub hAttr {
    $_[0]->{conf}->{checkUserHiddenAttributes} . ' '
      . $_[0]->{conf}->{hiddenAttributes};
}

sub init {
    my ($self) = @_;
    my $hd = $self->p->HANDLER;
    $self->addAuthRoute( checkuser => 'check', ['POST'] );
    $self->addAuthRouteWithRedirect( checkuser => 'display', ['GET'] );

    # Parse identity rule
    $self->logger->debug(
        "checkUser identities rule -> " . $self->conf->{checkUserIdRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{checkUserIdRule} ) );
    unless ($rule) {
        $self->error(
            "Bad checkUser identities rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->idRule($rule);

    return 1;
}

# RUNNING METHOD

sub check {
    my ( $self, $req ) = @_;
    my ( $attrs, $array_attrs, $array_hdrs ) = ( {}, [], [] );
    my $msg = my $auth = my $compute = '';

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        my $token = $req->param('token');
        unless ($token) {
            $self->userLogger->warn('checkUser try without token');
            $msg   = PE_NOTOKEN;
            $token = $self->ott->createToken();
        }

        unless ( $self->ott->getToken($token) ) {
            $self->userLogger->warn('checkUser try with expired/bad token');
            $msg   = PE_TOKENEXPIRED;
            $token = $self->ott->createToken();
        }

        my $params = {
            PORTAL    => $self->conf->{portal},
            MAIN_LOGO => $self->conf->{portalMainLogo},
            LANGS     => $self->conf->{showLanguages},
            MSG       => "PE$msg",
            ALERTE    => 'alert-warning',
            LOGIN     => '',
            TOKEN     => $token,
        };
        return $self->p->sendJSONresponse( $req, $params )
          if ( $req->wantJSON );
        return $self->p->sendHtml( $req, 'checkuser', params => $params, )
          if $msg;
    }

    ## Check user session datas
    # Use submitted attribute if exists
    my $url  = $req->param('url')  || '';
    my $user = $req->param('user') || '';

    if ( $user and $user !~ /$self->{conf}->{userControl}/o ) {
        $user  = '';
        $attrs = {};
        return $self->p->sendError( $req, 'Malformed user', 400 )
          if ( $req->wantJSON );
        return $self->p->sendHtml(
            $req,
            'checkuser',
            params => {
                PORTAL    => $self->conf->{portal},
                MAIN_LOGO => $self->conf->{portalMainLogo},
                LANGS     => $self->conf->{showLanguages},
                MSG       => 'PE' . PE_MALFORMEDUSER,
                ALERTE    => 'alert-warning',
                LOGIN     => '',
                TOKEN     => (
                      $self->ottRule->( $req, {} )
                    ? $self->ott->createToken()
                    : ''
                )
            }
        );
    }

    if ( $user eq $req->{user} or !$user ) {
        $self->logger->debug("checkUser requested for myself");
        $self->userLogger->notice("Return userData...");
        $self->userLogger->warn("Using spoofed SSO groups if exist!!!")
          if ( $self->conf->{impersonationRule} );
        $attrs = $req->userData;
        $user  = $req->{user};
    }
    else {
        $self->logger->debug("checkUser requested for $user");

        # Try to retrieve session from sessions DB
        $self->userLogger->notice('Try to retrieve session from DB...');
        $self->logger->debug('Try to retrieve session from DB...');
        my $moduleOptions = $self->conf->{globalStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{globalStorage};
        my $sessions =
          $self->module->searchOn( $moduleOptions, $self->conf->{whatToTrace},
            $user );
        my $age = '1';
        foreach my $id ( keys %$sessions ) {
            my $session = $self->p->getApacheSession($id) or next;

            if ( $session->{data}->{_utime} gt $age ) {
                $attrs = $session->{data};
                $age   = $session->{data}->{_utime};
            }
        }
        unless ( defined $attrs->{_session_id} ) {
            $req->{user} = $user;
            $self->userLogger->notice(
                "NO session found in DB. Compute userData...");
            $self->logger->debug("NO session found in DB. Compute userData...");
            $attrs   = $self->_userData($req);
            $compute = 1;
        }
    }

    if ( $req->error ) {
        $msg         = 'PE' . $req->{error};
        $array_attrs = [ [], [], [] ];
        $attrs       = {};
    }
    else {
        $msg =
          $self->{conf}->{impersonationMergeSSOgroups} eq 1
          ? 'checkUserMerged'
          : 'checkUser';
        $msg = 'checkUserComputeSession' if $compute;

        # Create an array of hashes for template loop
        $self->logger->debug("Delete hidden or empty attributes");
        if ( $self->conf->{checkUserDisplayEmptyValues} ) {
            foreach my $k ( sort keys %$attrs ) {

                # Ignore hidden attributes
                push @$array_attrs, { key => $k, value => $attrs->{$k} }
                  unless ( $self->hAttr =~ /\b$k\b/ );
            }
        }
        else {
            foreach my $k ( sort keys %$attrs ) {

                # Ignore hidden attributes and empty values
                push @$array_attrs, { key => $k, value => $attrs->{$k} }
                  unless ( $self->hAttr =~ /\b$k\b/ or !$attrs->{$k} );
            }
        }

        # ARRAY_REF = [ A_REF GROUPS, A_REF MACROS, A_REF OTHERS ]
        $array_attrs = $self->_splitAttributes($array_attrs);
    }

    # Check if user is allowed to access submitted URL and compute headers
    if ( $url and %$attrs ) {

        # Check url format
        $url = $self->_urlFormat($url);

        # User is allowed ?
        $self->logger->debug(
"checkUser requested for user: $attrs->{ $self->{conf}->{whatToTrace} } and URL: $url"
        );
        $auth = $self->_authorization( $req, $url, $attrs );
        if ( $auth >= 0 ) {
            $auth = $auth ? "allowed" : "forbidden";
            $self->userLogger->notice(
                    "checkUser -> $attrs->{ $self->{conf}->{whatToTrace} } is "
                  . uc($auth)
                  . " to access: $url" );

            # Return VirtualHost headers
            $array_hdrs = $self->_headers( $req, $url, $attrs );
        }
        else {
            $auth = 'VHnotFound';
            $self->userLogger->notice(
                "checkUser -> URL: $url has no configuration");
        }
    }

    my $alert_auth = 'alert-warning';
    if    ( $auth eq 'allowed' )   { $alert_auth = 'alert-success' }
    elsif ( $auth eq 'forbidden' ) { $alert_auth = 'alert-danger' }

    # TODO:
    my $params = {
        PORTAL    => $self->conf->{portal},
        MAIN_LOGO => $self->conf->{portalMainLogo},
        LANGS     => $self->conf->{showLanguages},
        MSG       => $msg,
        ALERTE    => ( $msg eq 'checkUser' ? 'alert-info' : 'alert-warning' ),
        LOGIN     => $user,
        URL       => (
              $self->p->checkXSSAttack( 'URL', $url ) ? ""
            : $url
        ),
        ALLOWED     => $auth,
        ALERTE_AUTH => $alert_auth,
        HEADERS     => $array_hdrs,
        ATTRIBUTES  => $array_attrs->[2],
        MACROS      => $array_attrs->[1],
        GROUPS      => $array_attrs->[0],
        TOKEN       => (
            $self->ottRule->( $req, {} ) ? $self->ott->createToken()
            : ''
        )
    };
    return $self->p->sendJSONresponse( $req, $params ) if ( $req->wantJSON );

    # Display form
    return $self->p->sendHtml( $req, 'checkuser', params => $params, );
}

sub display {
    my ( $self, $req ) = @_;
    my ( $attrs, $array_attrs ) = ( {}, [] );

    $self->logger->debug("Display current session data...");
    $self->userLogger->notice("Retrieve session from Sessions database");
    $self->userLogger->warn("Using spoofed SSO groups if exist!!!")
      if ( $self->conf->{impersonationRule} );
    $attrs = $req->userData;

    # Create an array of hashes for template loop
    $self->logger->debug("Delete hidden or empty attributes");
    if ( $self->conf->{checkUserDisplayEmptyValues} ) {
        foreach my $k ( sort keys %$attrs ) {

            # Ignore hidden attributes
            push @$array_attrs, { key => $k, value => $attrs->{$k} }
              unless ( $self->hAttr =~ /\b$k\b/ );
        }
    }
    else {
        foreach my $k ( sort keys %$attrs ) {

            # Ignore hidden attributes and empty values
            push @$array_attrs, { key => $k, value => $attrs->{$k} }
              unless ( $self->hAttr =~ /\b$k\b/ or !$attrs->{$k} );
        }
    }

    # ARRAY_REF = [ A_REF GROUPS, A_REF MACROS, A_REF OTHERS ]
    $array_attrs = $self->_splitAttributes($array_attrs);

    # Display form
    my $params = {
        PORTAL    => $self->conf->{portal},
        MAIN_LOGO => $self->conf->{portalMainLogo},
        LANGS     => $self->conf->{showLanguages},
        MSG       => (
            $self->{conf}->{impersonationMergeSSOgroups} ? 'checkUserMerged'
            : 'checkUser'
        ),
        ALERTE => (
            $self->{conf}->{impersonationMergeSSOgroups} ? 'alert-warning'
            : 'alert-info'
        ),
        LOGIN      => $req->{userData}->{uid},
        ATTRIBUTES => $array_attrs->[2],
        MACROS     => $array_attrs->[1],
        GROUPS     => $array_attrs->[0],
        TOKEN      => (
            $self->ottRule->( $req, {} ) ? $self->ott->createToken()
            : ''
        )
    };
    return $self->sendJSONresponse( $req, $params ) if ( $req->wantJSON );
    return $self->p->sendHtml( $req, 'checkuser', params => $params, );
}

sub _urlFormat {
    my ( $self, $url ) = @_;

    $url = 'http://' . $url unless ( $url =~ m#^https?://[^/]*.*#i );
    my ( $proto, $vhost, $appuri ) = $url =~ m#^(https?://)([^/]*)(.*)#i;
    my ($port) = $vhost =~ m#^.+(:\d+)$#;
    $port ||= '';
    $vhost =~ s/:\d+$//;
    $vhost .= $self->conf->{domain} unless ( $vhost =~ /\./ );

    return lc("$proto$vhost$port") . "$appuri";
}

sub _userData {
    my ( $self, $req ) = @_;

    # Compute session
    my $steps = [ 'getUser', 'setSessionInfo', 'setMacros', 'setGroups' ];
    $self->conf->{checkUserDisplayPersistentInfo}
      ? push @$steps, 'setPersistentSessionInfo', 'setLocalGroups'
      : push @$steps, 'setLocalGroups';
    $req->steps($steps);
    if ( my $error = $self->p->process($req) ) {
        if ( $error == PE_BADCREDENTIALS ) {
            $self->userLogger->warn(
                    'checkUser requested for an unvalid user ('
                  . $req->{user}
                  . ")" );
        }
        $self->logger->debug("Process returned error: $error");
        return $req->error($error);
    }

    unless ( defined $req->sessionInfo->{uid} ) {

        # Avoid error with SAML, OIDC, etc...
        $self->logger->debug("\"$req->{user}\" NOT found in userDB");
        return $req->error(PE_BADCREDENTIALS);
    }

    # Check identities rule
    unless ( $self->idRule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->warn(
            'checkUser requested for an unvalid user (' . $req->{user} . ")" );
        $req->{sessionInfo} = {};
        $self->logger->debug('Identity not authorized');
        return $req->error(PE_BADCREDENTIALS);
    }

    $self->logger->debug("Return \"$req->{user}\" sessionInfo");
    return $req->{sessionInfo};
}

sub _authorization {
    my ( $self, $req, $uri, $attrs ) = @_;
    my ( $vhost, $appuri ) = $uri =~ m#^https?://([^/]*)(.*)#;
    my $exist = 0;

    $vhost =~ s/:\d+$//;
    foreach my $vh ( keys %{ $self->conf->{locationRules} } ) {
        if ( $vh eq $vhost ) {
            $exist = 1;
            $self->logger->debug("VirtualHost: $vh found in Conf");
            last;
        }
    }

    $self->logger->debug(
        "Return \"$attrs->{ $self->{conf}->{whatToTrace} }\" authorization");
    return $exist
      ? $self->p->HANDLER->grant( $req, $attrs, $appuri, undef, $vhost )
      : -1;
}

sub _headers {
    my ( $self, $req, $uri, $attrs ) = @_;
    my ($vhost) = $uri =~ m#^https?://([^/]*).*#;

    $vhost =~ s/:\d+$//;
    $req->{env}->{HTTP_HOST} = $vhost;
    $self->p->HANDLER->headersInit( $self->{conf} );
    $self->logger->debug(
        "Return \"$attrs->{ $self->{conf}->{whatToTrace} }\" headers");
    return $self->p->HANDLER->checkHeaders( $req, $attrs );
}

sub _splitAttributes {
    my ( $self, $attrs ) = @_;
    my ( $grps, $mcrs, $others ) = ( [], [], [] );
    my $macros = $self->{conf}->{macros};
    $self->logger->debug("Dispatching attributes...");
    while (@$attrs) {
        my $element = shift @$attrs;
        $self->logger->debug(
            'Processing element: ' . Data::Dumper::Dumper($element) );
        my $ok = 0;
        if ( $element->{key} eq 'groups' ) {
            $self->logger->debug('Key "groups" found');
            my $separator = $self->{conf}->{multiValuesSeparator};
            my @tmp = split /\Q$separator/, $element->{value};
            $grps = [ map { { value => $_ } } sort @tmp ];
            next;
        }
        if (%$macros) {
            foreach my $key ( sort keys %$macros ) {
                if ( $element->{key} eq $key ) {
                    $self->logger->debug('Macro found');
                    push @$mcrs, $element;
                    $ok = 1;
                    last;
                }
            }
        }
        push @$others, $element unless $ok;
    }

    # Sort real and spoofed attributes if required
    if ( $self->conf->{impersonationRule} ) {
        $self->logger->debug('Dispatching real and spoofed attributes...');
        my ( $realAttrs, $spoofedAttrs ) = ( [], [] );
        my $prefix = "$self->{conf}->{impersonationPrefix}";
        while (@$others) {
            my $element = shift @$others;
            $self->logger->debug(
                'Processing attribute: ' . Data::Dumper::Dumper($element) );
            if ( $element->{key} =~ /^$prefix.+$/ ) {
                push @$realAttrs, $element;
                $self->logger->debug(' -> Real attribute');
            }
            else {
                push @$spoofedAttrs, $element;
                $self->logger->debug(' -> Spoofed attribute');
            }
        }
        @$others = ( @$spoofedAttrs, @$realAttrs );
    }
    return [ $grps, $mcrs, $others ];
}

1;
