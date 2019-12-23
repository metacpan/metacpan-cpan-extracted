package Lemonldap::NG::Portal::Plugins::CheckUser;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_TOKENEXPIRED
  PE_NOTOKEN
  PE_MALFORMEDUSER
);

our $VERSION = '2.0.7';

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
has sorted => ( is => 'rw', default => sub { 0 } );

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
    $self->sorted( $self->conf->{impersonationRule}
          || $self->conf->{contextSwitchingRule} );
    return 1;
}

# RUNNING METHOD
sub display {
    my ( $self, $req ) = @_;
    my ( $attrs, $array_attrs ) = ( {}, [] );

    $self->logger->debug("Display current session data...");
    $self->userLogger->info("Using spoofed SSO groups if exist")
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
        SKIN      => $self->p->getSkin($req),
        LANGS     => $self->conf->{showLanguages},
        MSG       => (
            $self->{conf}->{impersonationMergeSSOgroups} ? 'checkUserMerged'
            : 'checkUser'
        ),
        ALERTE => (
            $self->{conf}->{impersonationMergeSSOgroups} ? 'alert-warning'
            : 'alert-info'
        ),
        LOGIN      => $req->{userData}->{ $self->conf->{whatToTrace} },
        ATTRIBUTES => $array_attrs->[2],
        MACROS     => $array_attrs->[1],
        GROUPS     => $array_attrs->[0],
        TOKEN      => (
            $self->ottRule->( $req, {} ) ? $self->ott->createToken()
            : ''
        )
    };
    return $self->sendJSONresponse( $req, $params ) if ( $req->wantJSON );

    # Display form
    return $self->p->sendHtml( $req, 'checkuser', params => $params );
}

sub check {
    my ( $self, $req ) = @_;
    my ( $attrs, $array_attrs, $array_hdrs ) = ( {}, [], [] );
    my $msg       = my $auth = my $compute = '';
    my $authLevel = $req->userData->{authenticationLevel};
    my $authMode  = $req->userData->{_auth};

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        my $token = $req->param('token');
        unless ($token) {
            $self->userLogger->warn('CheckUser called without token');
            $msg   = PE_NOTOKEN;
            $token = $self->ott->createToken();
        }

        unless ( $self->ott->getToken($token) ) {
            $self->userLogger->warn(
                'CheckUser called with an expired/bad token');
            $msg   = PE_TOKENEXPIRED;
            $token = $self->ott->createToken();
        }

        my $params = {
            PORTAL    => $self->conf->{portal},
            MAIN_LOGO => $self->conf->{portalMainLogo},
            SKIN      => $self->p->getSkin($req),
            LANGS     => $self->conf->{showLanguages},
            MSG       => "PE$msg",
            ALERTE    => 'alert-warning',
            LOGIN     => '',
            TOKEN     => $token,
        };
        return $self->p->sendJSONresponse( $req, $params )
          if ( $req->wantJSON );
        return $self->p->sendHtml( $req, 'checkuser', params => $params )
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
                SKIN      => $self->p->getSkin($req),
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

    if ( !$user or $user eq $req->{user} ) {
        $self->userLogger->info("checkUser requested for himself");
        $self->userLogger->info("Using spoofed SSO groups if exist")
          if ( $self->conf->{impersonationRule} );
        $attrs = $req->userData;
        $user  = $req->{user};
    }
    else {
        $self->userLogger->info("checkUser requested for $user");

        # Try to retrieve session from sessions DB
        $self->logger->debug('Try to retrieve session from DB...');
        my $moduleOptions = $self->conf->{globalStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{globalStorage};

        my $sessions = {};
        my $searchAttrs =
            $self->conf->{checkUserSearchAttributes}
          ? $self->conf->{whatToTrace} . ' '
          . $self->conf->{checkUserSearchAttributes}
          : $self->conf->{whatToTrace};

        foreach ( split /\s+/, $searchAttrs ) {
            $self->logger->debug("Searching with: $_ = $user");
            $sessions = $self->module->searchOn( $moduleOptions, $_, $user );
            last if ( keys %$sessions );
        }

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
            $self->userLogger->info(
                "No session found in DB. Compute userData...");
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
        if ($compute) {
            $msg                          = 'checkUserComputeSession';
            $attrs->{authenticationLevel} = $authLevel;
            $attrs->{_auth}               = $authMode;

            if ( $self->conf->{impersonationRule} ) {
                $self->logger->debug("Map real attributes...");
                my %realAttrs = map {
                    ( "$self->{conf}->{impersonationPrefix}$_" => $attrs->{$_} )
                } keys %$attrs;
                $attrs = { %$attrs, %realAttrs };
            }
        }

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
            $self->logger->debug(
                    "checkUser: $attrs->{ $self->{conf}->{whatToTrace} } is "
                  . "$auth to access to $url" );

            # Return VirtualHost headers
            $array_hdrs = $self->_headers( $req, $url, $attrs );
        }
        else {
            $auth = 'VHnotFound';
            $self->userLogger->info("checkUser: $url has no configuration");
        }
    }

    my $alert_auth = 'alert-warning';
    if    ( $auth eq 'allowed' )   { $alert_auth = 'alert-success' }
    elsif ( $auth eq 'forbidden' ) { $alert_auth = 'alert-danger' }

    # TODO:
    my $params = {
        PORTAL    => $self->conf->{portal},
        MAIN_LOGO => $self->conf->{portalMainLogo},
        SKIN      => $self->p->getSkin($req),
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
    return $self->p->sendHtml( $req, 'checkuser', params => $params );
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
            $req->env->{REQUEST_URI} = $appuri;
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
        $self->logger->debug( "Processing element: $element->{key} => "
              . ( $element->{value} // '' ) );
        my $ok = 0;
        if ( $element->{key} eq 'groups' ) {
            $self->logger->debug('Key "groups" found');
            my $separator = $self->{conf}->{multiValuesSeparator};
            my @tmp       = split /\Q$separator/, $element->{value};
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
    if ( $self->sorted ) {
        $self->logger->debug('Dispatching real and spoofed attributes...');
        my ( $realAttrs, $spoofedAttrs ) = ( [], [] );
        my $prefix = "$self->{conf}->{impersonationPrefix}";
        while (@$others) {
            my $element = shift @$others;
            $self->logger->debug( "Processing attribute $element->{key} => "
                  . ( $element->{value} // '' ) );
            if ( $element->{key} =~ /^$prefix.+$/ ) {
                push @$realAttrs, $element;
                $self->logger->debug(' -> Real attribute');
            }
            else {
                push @$spoofedAttrs, $element;

                #$self->logger->debug(' -> Spoofed attribute');
            }
        }
        @$others = ( @$spoofedAttrs, @$realAttrs );
    }
    return [ $grps, $mcrs, $others ];
}

1;
