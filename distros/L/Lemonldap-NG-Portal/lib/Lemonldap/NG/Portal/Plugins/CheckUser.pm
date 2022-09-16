package Lemonldap::NG::Portal::Plugins::CheckUser;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_MALFORMEDUSER
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.15';

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

has displayHistoryRule           => ( is => 'rw', default => sub { 0 } );
has unrestrictedUsersRule        => ( is => 'rw', default => sub { 0 } );
has displayEmptyValuesRule       => ( is => 'rw', default => sub { 0 } );
has displayEmptyHeadersRule      => ( is => 'rw', default => sub { 0 } );
has displayPersistentInfoRule    => ( is => 'rw', default => sub { 0 } );
has displayComputedSessionRule   => ( is => 'rw', default => sub { 0 } );
has displayHiddenAttributesRule  => ( is => 'rw', default => sub { 0 } );
has displayNormalizedHeadersRule => ( is => 'rw', default => sub { 0 } );
has idRule                       => ( is => 'rw', default => sub { 1 } );
has sorted                       => ( is => 'rw', default => sub { 0 } );
has merged                       => ( is => 'rw', default => '' );

sub hAttr {
    $_[0]->{conf}->{checkUserHiddenAttributes} . ' '
      . $_[0]->{conf}->{hiddenAttributes};
}

sub persistentAttrs {
    $_[0]->{conf}->{persistentSessionAttributes}
      || '_loginHistory _2fDevices notification_';
}

sub init {
    my ($self) = @_;
    $self->addAuthRoute( checkuser => 'check', ['POST'] )
      ->addAuthRouteWithRedirect( checkuser => 'display', ['GET'] );

    # Parse checkUser rules
    $self->idRule(
        $self->p->buildRule( $self->conf->{checkUserIdRule}, 'checkUserId' ) );
    return 0 unless $self->idRule;

    $self->displayEmptyValuesRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayEmptyValues},
            'checkUserDisplayEmptyValues'
        )
    );
    return 0 unless $self->displayEmptyValuesRule;

    $self->displayEmptyHeadersRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayEmptyHeaders},
            'checkUserDisplayEmptyHeaders'
        )
    );
    return 0 unless $self->displayEmptyHeadersRule;

    $self->displayPersistentInfoRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayPersistentInfo},
            'checkUserDisplayPersistentInfo'
        )
    );
    return 0 unless $self->displayPersistentInfoRule;

    $self->unrestrictedUsersRule(
        $self->p->buildRule(
            $self->conf->{checkUserUnrestrictedUsersRule},
            'checkUserUnrestrictedUsersRule'
        )
    );
    return 0 unless $self->unrestrictedUsersRule;

    $self->displayComputedSessionRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayComputedSession},
            'checkUserdisplayComputedSession'
        )
    );
    return 0 unless $self->displayComputedSessionRule;

    $self->displayNormalizedHeadersRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayNormalizedHeaders},
            'checkUserDisplayNormalizedHeaders'
        )
    );
    return 0 unless $self->displayNormalizedHeadersRule;

    $self->displayHistoryRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayHistory},
            'checkUserDisplayHistory'
        )
    );
    return 0 unless $self->displayHistoryRule;

    $self->displayHiddenAttributesRule(
        $self->p->buildRule(
            $self->conf->{checkUserDisplayHiddenAttributes},
            'checkUserDisplayHiddenAttributes'
        )
    );
    return 0 unless $self->displayHistoryRule;

    # Init. other options
    $self->sorted( $self->conf->{impersonationRule}
          || $self->conf->{contextSwitchingRule} );
    $self->merged( $self->conf->{impersonationMergeSSOgroups}
          && $self->conf->{impersonationRule} ? 'Merged' : '' );

    return 1;
}

# RUNNING METHODS
sub display {
    my ( $self, $req ) = @_;
    my $history = [ [], [] ];
    my ( $attrs, $array_attrs ) = ( $req->userData, [] );

    $self->logger->debug("Display current session data...");
    $self->userLogger->info("Using spoofed SSO groups if exist")
      if ( $self->conf->{impersonationRule} );

    $history = $self->_concatHistory( $attrs->{_loginHistory} )
      if $self->displayHistoryRule->( $req, $req->userData )
      && $self->conf->{loginHistoryEnabled};

    $attrs =
      $self->_removeKeys( $attrs, $self->persistentAttrs,
        'Remove persistent session attributes...' )
      unless $self->displayPersistentInfoRule->( $req, $req->userData );

    # Create an array of hashes and dispatch attributes for template loop
    # ARRAY_REF = [ A_REF GROUPS, A_REF MACROS, A_REF OTHERS ]
    $array_attrs = $self->_dispatchAttributes(
        $self->_createArray( $req, $attrs, $req->userData ) );

    my $params = {
        MSG        => 'checkUser' . $self->merged,
        ALERTE     => ( $self->merged ? 'alert-warning' : 'alert-info' ),
        LOGIN      => $req->{userData}->{ $self->conf->{whatToTrace} },
        HISTORY    => ( @{ $history->[0] } || @{ $history->[1] } ) ? 1 : 0,
        SUCCESS    => $history->[0],
        FAILED     => $history->[1],
        ATTRIBUTES => $array_attrs->[2],
        MACROS     => $array_attrs->[1],
        GROUPS     => $array_attrs->[0],
        TOKEN      => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->sendJSONresponse( $req, $params ) if $req->wantJSON;

    # Display form
    return $self->p->sendHtml( $req, 'checkuser', params => $params );
}

sub check {
    my ( $self, $req ) = @_;
    my ( $attrs, $array_attrs, $array_hdrs ) = ( {}, [], [] );
    my $msg           = my $auth = my $computed = '';
    my $savedUserData = $req->userData;
    my $unUser  = $self->unrestrictedUsersRule->( $req, $savedUserData ) || 0;
    my $history = [ [], [] ];

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        my $token;
        if ( $token = $req->param('token') ) {
            unless ( $self->ott->getToken($token) ) {
                $self->userLogger->warn(
                    'CheckUser called with an expired/bad token');
                $msg   = PE_TOKENEXPIRED;
                $token = $self->ott->createToken();
            }
        }
        else {
            $self->userLogger->warn('CheckUser called without token');
            $msg   = PE_NOTOKEN;
            $token = $self->ott->createToken();
        }

        my $params = {
            MSG    => "PE$msg",
            ALERTE => 'alert-warning',
            LOGIN  => '',
            TOKEN  => $token,
        };
        return $self->p->sendJSONresponse( $req, $params )
          if $req->wantJSON && $msg;

        # Display form
        return $self->p->sendHtml( $req, 'checkuser', params => $params )
          if $msg;
    }

    ## Check user session datas
    # Use submitted attributes if exists
    my $url  = $req->param('url')  || '';
    my $user = $req->param('user') || '';

    if ( $user and $user !~ /$self->{conf}->{userControl}/o ) {
        $user  = '';
        $attrs = {};
        return $self->p->sendError( $req, 'Malformed user', 400 )
          if $req->wantJSON;
        return $self->p->sendHtml(
            $req,
            'checkuser',
            params => {
                MSG    => 'PE' . PE_MALFORMEDUSER,
                ALERTE => 'alert-warning',
                LOGIN  => '',
                TOKEN  => (
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
          if $self->conf->{impersonationRule};
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

        foreach ( split /[,\s]+/, $searchAttrs ) {
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
            $attrs    = $self->_userData($req);
            $computed = 1;
        }

        # Check identities rule
        $self->logger->info( '"'
              . $savedUserData->{ $self->conf->{whatToTrace} }
              . '" is an unrestricted user!' )
          if $unUser;
        unless ( $unUser || $self->idRule->( $req, $attrs ) ) {
            $self->userLogger->warn(
                "checkUser requested for an invalid user ($user)");
            $req->{sessionInfo} = {};
            $self->logger->debug('Identity not authorized');
            $req->error(PE_BADCREDENTIALS)
              ;    # Catch error to preserve protected Id
        }
    }

    if ( $req->error ) {
        $msg         = 'PE' . $req->{error};
        $array_attrs = [ [], [], [] ];
        $attrs       = {};
    }
    else {
        $msg     = 'checkUser' . $self->merged;
        $history = $self->_concatHistory( $attrs->{_loginHistory} )
          if $self->displayHistoryRule->( $req, $savedUserData )
          && $self->conf->{loginHistoryEnabled};

        $attrs =
          $self->_removeKeys( $attrs, $self->persistentAttrs,
            'Remove persistent session attributes...' )
          unless $self->displayPersistentInfoRule->( $req, $savedUserData );

        if ($computed) {
            if ( $self->displayComputedSessionRule->( $req, $savedUserData ) ) {
                $msg = 'checkUserComputedSession';
                if ( $self->conf->{impersonationRule} ) {
                    $self->logger->debug("Map real attributes...");
                    my %realAttrs = map {
                        ( "$self->{conf}->{impersonationPrefix}$_" =>
                              $attrs->{$_} )
                    } keys %$attrs;
                    $attrs = { %$attrs, %realAttrs };

                    # Compute groups and macros with real and spoofed attributes
                    $self->logger->debug(
"Compute groups and macros with real and spoofed attributes"
                    );
                    $req->sessionInfo($attrs);
                    delete $req->sessionInfo->{groups};
                    $req->steps(
                        [ $self->p->groupsAndMacros, 'setLocalGroups' ] );
                    if ( my $error = $self->p->process($req) ) {
                        $self->logger->debug("Process returned error: $error");
                        return $req->error($error);
                    }
                }
            }
            else {
                $attrs = {};
                $msg   = 'checkUserNoSessionFound';
            }
        }

        # Create an array of hashes and dispatch attributes for template loop
        # ARRAY_REF = [ A_REF GROUPS, A_REF MACROS, A_REF OTHERS ]
        $array_attrs = $self->_dispatchAttributes(
            $self->_createArray( $req, $attrs, $savedUserData ) );
    }

    if ( $self->p->checkXSSAttack( 'CheckUser URL', $url ) ) {
        $url  = '';
        $auth = 'VHnotFound';
    }

    # Check if user is allowed to access submitted URL and compute headers
    if ( $url and %$attrs ) {

        # Check url format
        my $originalUrl;
        ( $url, $originalUrl ) = $self->_resolveURL( $req, $url );

        # User is allowed ?
        $self->logger->debug(
"checkUser requested for user: $attrs->{ $self->{conf}->{whatToTrace} } and URL: $url | alias: $originalUrl"
        );
        $auth = $self->_authorization( $req, $originalUrl, $attrs );
        if ( $auth >= 0 ) {
            $auth = $auth ? "allowed" : "forbidden";
            $self->logger->debug(
                    "checkUser: $attrs->{ $self->{conf}->{whatToTrace} } is "
                  . "$auth to access to $url" );

            # Return VirtualHost headers
            $array_hdrs =
              $self->_headers( $req, $originalUrl, $attrs, $savedUserData );
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
        MSG         => $msg,
        ALERTE      => ( $msg eq 'checkUser' ? 'alert-info' : 'alert-warning' ),
        LOGIN       => $user,
        URL         => $url,
        ALLOWED     => $auth,
        ALERTE_AUTH => $alert_auth,
        HEADERS     => $array_hdrs,
        HISTORY     => ( @{ $history->[0] } || @{ $history->[1] } ) ? 1 : 0,
        SUCCESS     => $history->[0],
        FAILED      => $history->[1],
        ATTRIBUTES  => $array_attrs->[2],
        MACROS      => $array_attrs->[1],
        GROUPS      => $array_attrs->[0],
        TOKEN       => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->p->sendJSONresponse( $req, $params ) if $req->wantJSON;

    # Display form
    return $self->p->sendHtml( $req, 'checkuser', params => $params );
}

sub _resolveURL {
    my ( $self, $req, $url ) = @_;
    my ($proto) = $url =~ m#^(https?://).*#i;
    my ( $vhost, $appuri ) = $url =~ m@^(?:https?://)?([^/#]*)(.*)@i;
    my ($port) = $vhost =~ m#^.+(:\d+)$#;
    $port ||= '';
    $vhost =~ s/:\d+$//;
    $vhost .= $self->conf->{domain} unless ( $vhost =~ /\./ );
    $proto =
      $self->p->HANDLER->_isHttps( $req, $vhost ) ? 'https://' : 'http://'
      unless $proto;
    $self->logger->debug( 'VHost is ' . uc( ( split( /:/, $proto ) )[0] ) );
    my $originalVhost = $self->p->HANDLER->resolveAlias($vhost);

    return (
        lc("$proto$vhost$port") . $appuri,
        lc("$proto$originalVhost$port") . $appuri
    );
}

sub _userData {
    my ( $self, $req ) = @_;
    my $realAuthLevel = $req->userData->{authenticationLevel};

    # Compute session
    my $steps = [
        'getUser',        'setAuthSessionInfo',
        'setSessionInfo', $self->p->groupsAndMacros,
    ];
    $self->conf->{checkUserDisplayPersistentInfo}
      ? push @$steps, 'setPersistentSessionInfo', 'setLocalGroups'
      : push @$steps, 'setLocalGroups';
    $req->steps($steps);
    if ( my $error = $self->p->process($req) ) {
        $self->userLogger->warn(
            'checkUser requested for an invalid user (' . $req->{user} . ")" )
          if ( $error == PE_BADCREDENTIALS );
        $self->logger->debug("Process returned error: $error");
        return $req->error(PE_BADCREDENTIALS);
    }

    unless ( defined $req->sessionInfo->{uid} ) {

        # Avoid error with SAML, OIDC, etc...
        $self->logger->debug("\"$req->{user}\" NOT found in userDB");
        return $req->error(PE_BADCREDENTIALS);
    }

    # Compute groups & macros again with real authenticationLevel
    $req->sessionInfo->{authenticationLevel} = $realAuthLevel;
    delete $req->sessionInfo->{groups};

    $req->steps(
        [ 'setSessionInfo', $self->p->groupsAndMacros, 'setLocalGroups' ] );
    if ( my $error = $self->p->process($req) ) {
        $self->logger->debug("CheckUser: Process returned error: $error");
        return $req->error($error);
    }

    $self->logger->debug("Return \"$req->{user}\" sessionInfo");
    return $req->{sessionInfo};
}

sub _authorization {
    my ( $self, $req, $uri, $attrs ) = @_;
    my ( $vhost, $appuri ) = $uri =~ m@^https?://([^/#]*)(.*)@;
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
    my ( $self, $req, $uri, $attrs, $savedUserData ) = @_;
    my ($vhost) = $uri =~ m@^https?://([^/#]*).*@;

    $vhost =~ s/:\d+$//;
    $req->{env}->{HTTP_HOST} = $vhost;
    $self->p->HANDLER->headersInit( $self->{conf} );
    my $headers = $self->p->HANDLER->checkHeaders( $req, $attrs );

    # Remove hidden headers relative to VHost if required
    unless ( $self->unrestrictedUsersRule->( $req, $savedUserData ) ) {
        my $keysToRemove = '';
        $keysToRemove = '__ALL__'
          if exists $self->conf->{checkUserHiddenHeaders}->{$vhost};
        $keysToRemove = $self->conf->{checkUserHiddenHeaders}->{$vhost}
          if ( $keysToRemove
            && $self->conf->{checkUserHiddenHeaders}->{$vhost} =~ /\w+/ );

        if ( $keysToRemove && $keysToRemove eq '__ALL__' ) {
            $self->logger->debug(
                "Overwrite for VirtualHost: $vhost ALL valued header(s)...");
            @$headers = map {
                $_->{value} =~ /\w+/
                  ? { key => $_->{key}, value => '******' }
                  : $_
            } @$headers;
        }
        elsif ($keysToRemove) {
            $self->logger->debug(
                "Mask hidden header(s) for VirtualHost: $vhost");
            my $hash = { map { $_->{key} => $_->{value} } @$headers };
            $hash = $self->_removeKeys( $hash, $keysToRemove,
                "Overwrite valued \"$keysToRemove\" header(s)...", 1 );
            @$headers = (
                map { { key => $_, value => $hash->{$_} } }
                sort keys %$hash
            );
        }
    }

    # Remove empty headers if required
    unless ( $self->displayEmptyHeadersRule->( $req, $savedUserData ) ) {
        $self->logger->debug("Remove empty headers...");
        @$headers = grep $_->{value} =~ /.+/, @$headers;
    }

    # Normalize headers name if required
    if ( $self->displayNormalizedHeadersRule->( $req, $savedUserData ) ) {
        $self->logger->debug("Normalize headers...");
        @$headers = map {
            ;    # Prevent compilation error with old Perl versions
            no strict 'refs';
            {
                key   => &{ $self->p->HANDLER . '::cgiName' }( $_->{key} ),
                value => $_->{value}
            }
        } @$headers;
    }

    $self->logger->debug(
        "Return \"$attrs->{ $self->{conf}->{whatToTrace} }\" headers");
    return $headers;
}

sub _createArray {
    my ( $self, $req, $attrs, $userData ) = @_;
    my $array_attrs = [];

    foreach my $k ( sort keys %$attrs ) {
        push @$array_attrs,
          { key => $k, value => $attrs->{$k} }
          unless ( (
                $self->hAttr =~ /\b$k\b/
                && !$self->displayHiddenAttributesRule->( $req, $userData )
            )
            || (   !$attrs->{$k}
                && !$self->displayEmptyValuesRule->( $req, $userData ) )
          );
    }

    return $array_attrs;
}

sub _dispatchAttributes {
    my ( $self, $attrs ) = @_;
    my ( $grps, $mcrs, $others ) = ( [], [], [] );
    my $macros = $self->{conf}->{macros};

    $self->logger->debug("Dispatch attributes...");
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
        $self->logger->debug('Sort real and spoofed attributes...');
        my ( $realAttrs, $spoofedAttrs ) = ( [], [] );
        my $prefix = $self->{conf}->{impersonationPrefix};
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
            }
        }
        @$others = ( @$spoofedAttrs, @$realAttrs );
    }

    return [ $grps, $mcrs, $others ];
}

sub _removeKeys {
    my ( $self, $attrs, $hidden, $msg, $mask ) = @_;
    my $regex = '^(?:' . join( '|', split( /\s+/, $hidden ) ) . ')';
    my @keys  = grep /$regex/, keys %$attrs;

    $self->logger->debug($msg);
    if ($mask) {
        $self->userLogger->info('Hide some headers...');
        foreach (@keys) {
            $attrs->{$_} = '******' if $attrs->{$_} =~ /\w+/;
        }
    }
    else {
        $self->userLogger->info('Remove some headers...');
        delete @$attrs{@keys};
    }

    return $attrs;
}

sub _concatHistory {
    my ( $self,    $history ) = @_;
    my ( $success, $failed )  = ( [], [] );

    $self->logger->debug('Concatenate history...');
    @$success = map {
        my $element = $_;
        my $utime   = delete $element->{_utime};
        {
            utime  => $utime,
            values => join $self->conf->{multiValuesSeparator},
            map "$_=$element->{$_}", sort keys %$element
        }
    } @{ $history->{successLogin} };

    @$failed = map {
        my $element = $_;
        my $utime   = delete $element->{_utime};
        {
            utime  => $utime,
            values => join $self->conf->{multiValuesSeparator},
            map "$_=$element->{$_}", sort keys %$element
        }
    } @{ $history->{failedLogin} };

    return [ $success, $failed ];
}

1;
