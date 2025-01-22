# Default 2FA engine
#
# 2FA engine provides 3 functions and 1 interface:
#  - init()
#  - run($req): called during auth process after session populating
#  - display2fRegisters($req, $session): indicates if a 2F registration is
#                                        available for this user
#  - /2fregisters: the URL path that displays 2F registration menu

package Lemonldap::NG::Portal::2F::Engines::Default;

use strict;
use Mouse;
use MIME::Base64 qw(encode_base64);
use JSON qw(from_json to_json);
use POSIX qw(strftime);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_NOTOKEN
  PE_SENDRESPONSE
  PE_BADCREDENTIALS
  PE_TOKENEXPIRED
  PE_NO_SECOND_FACTORS
  PE_RETRY_2FA
  portalConsts
);

use Lemonldap::NG::Common::Util qw/display2F filterKey2F/;

our $VERSION = '2.20.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';
with qw(
  Lemonldap::NG::Portal::Lib::OverConf
  Lemonldap::NG::Portal::Lib::2fDevices
);

# INITIALIZATION

# Arrayref of objects
# p => module prefix
# m => module instance
# r => compiled rule
# t => type of record in _2fDevices
has sfModules  => ( is => 'rw', default => sub { [] } );
has sfRModules => ( is => 'rw', default => sub { [] } );
has sfReq      => ( is => 'rw' );
has sfMsgRule  => ( is => 'rw' );

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{sfLoginTimeout}
              || $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

has regOtt => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        my $timeout = $_[0]->{conf}->{sfRegisterTimeout}
          // $_[0]->{conf}->{formTimeout};
        $ott->timeout($timeout);
        return $ott;
    }
);

sub init {
    my ($self) = @_;

    # Load 2F modules
    for my $i ( 0 .. 1 ) {
        foreach (
            split /,\s*/,
            $self->conf->{
                $i
                ? 'available2FSelfRegistration'
                : 'available2F'
            }
          )
        {
            return 0 unless $self->_load_2f_module_by_prefix( $_, $i );
        }
    }

    # Extra 2F modules
    $self->logger->debug('Processing Extra 2F modules');
    foreach my $extraKey ( sort keys %{ $self->conf->{sfExtra} } ) {

        my $moduleType = $self->conf->{sfExtra}->{$extraKey}->{type};
        next unless ($moduleType);
        my $over = $self->conf->{sfExtra}->{$extraKey}->{over};

        $self->logger->debug(
            "Loading extra 2F module $extraKey of type $moduleType");
        my $m = $self->loadModule(
            "::2F::$moduleType",
            $over,
            prefix => $extraKey,
            (
                $self->conf->{sfExtra}->{$extraKey}->{register}
                ? ( is_registrable => 1 )
                : ()
            ),
        ) or return 0;

        $self->_registerRoutes($m);

        # Rule and prefix may be modified by 2F module, reread them
        my $rule = $self->conf->{sfExtra}->{$extraKey}->{rule} || 1;
        my $reg_rule;
        my $prefix = $m->prefix;
        if ( $self->conf->{sfExtra}->{$extraKey}->{register} ) {
            $reg_rule = $self->conf->{sfExtra}->{$extraKey}->{regrule} || $rule;
            $rule     = "( $rule ) and has2f('$prefix')";
        }

        # Overwrite logo, label, level from user configuration
        $m->logo( $self->conf->{sfExtra}->{$extraKey}->{logo} )
          if $self->conf->{sfExtra}->{$extraKey}->{logo};
        $m->label( $self->conf->{sfExtra}->{$extraKey}->{label} )
          if $self->conf->{sfExtra}->{$extraKey}->{label};
        $m->authnLevel( $self->conf->{sfExtra}->{$extraKey}->{level} )
          if $self->conf->{sfExtra}->{$extraKey}->{level};

        # Compile rule
        $rule = $self->p->buildRule( $rule, "extra 2F activation for $prefix" );
        return 0 unless $rule;

        # Store module
        push @{ $self->{'sfModules'} },
          {
            p => $prefix,
            m => $m,
            r => $rule,
            t => $prefix
          };

        # Push register module
        if ( $self->conf->{sfExtra}->{$extraKey}->{register} ) {
            $self->logger->debug(
                "Loading register module for $extraKey of type $moduleType");
            my $register_module_name = $self->findRegisterModuleFor($m);
            if ($register_module_name) {
                my $rm = $self->loadModule(
                    "::2F::Register::Generic",
                    $over,
                    prefix             => $extraKey,
                    type               => $extraKey,
                    logo               => $m->logo,
                    label              => $m->label,
                    userCanRemove      => 1,
                    verificationModule => $m,
                    authnLevel => $self->conf->{sfExtra}->{$extraKey}->{level},
                ) or return 0;

                my $reg_rule = $self->p->buildRule( $reg_rule,
                    "extra 2F registration for $prefix" );
                return 0 unless $reg_rule;
                push @{ $self->{'sfRModules'} },
                  {
                    p => $prefix,
                    m => $rm,
                    r => $reg_rule,
                    t => $prefix,
                  };
            }
            else {
                $self->logger->warn(
                    "Could not find a proper register module for $moduleType");
            }
        }
    }

    unless (
        $self->sfReq(
            $self->p->buildRule( $self->conf->{sfRequired}, 'sfRequired' )
        )
      )
    {
        return 0;
    }

    unless (
        $self->sfMsgRule(
            $self->p->buildRule(
                $self->conf->{sfRemovedMsgRule},
                'sfRemovedMsg'
            )
        )
      )
    {
        return 0;
    }

    $self->addAuthRoute( '2fchoice' => '_choice',   ['POST'] );
    $self->addAuthRoute( '2fchoice' => '_redirect', ['GET'] );
    $self->addUnauthRoute( '2fchoice' => '_choice',   ['POST'] );
    $self->addUnauthRoute( '2fchoice' => '_redirect', ['GET'] );

    # Registration base
    $self->addAuthRoute( '2fregisters' => '_displayRegister', ['GET'] );
    $self->addAuthRoute( '2fregisters' => 'register',         ['POST'] );
    $self->addUnauthRoute(
        '2fregisters' => 'restoreSession',
        [ 'GET', 'POST' ]
    ) if ( $self->conf->{sfRequired} );

    $self->addEntryPoint(
        isa     => 'Lemonldap::NG::Portal::Main::SecondFactor',
        service => "secondFactor",
        method  => "_enable_2f_module",
    );

    $self->addEntryPoint(
        isa     => 'Lemonldap::NG::Portal::2F::Register::Base',
        service => "secondFactor",
        method  => "_enable_2f_register_module",
    );

    return 1;
}

sub _load_2f_module_by_prefix {
    my ( $self, $name, $isRegister ) = @_;
    {
        my $prefix = lc($name);
        $prefix =~ s/2f$//i;

        # Activation parameter
        my $ap =
          $prefix . ( $isRegister ? '2fSelfRegistration' : '2fActivation' );
        $self->logger->debug("Checking $ap");

        # Unless $rule, skip loading
        if ( $self->conf->{$ap} ) {
            $self->logger->debug("Trying to load $name 2F");
            my $m =
              $self->p->loadModule(
                $isRegister ? "::2F::Register::$name" : "::2F::$name" )
              or return 0;

            if ($isRegister) {
                $self->_enable_2f_register_module($m) or return 0;
            }
            else {
                $self->_enable_2f_module($m) or return 0;
            }
        }
        else {
            $self->logger->debug(' -> not enabled');
        }
    }
    return 1;
}

sub _enable_2f_register_module {
    my ( $self, $m ) = @_;
    return $self->_enable_module( $m, $self->sfRModules );
}

sub _enable_2f_module {
    my ( $self, $m ) = @_;

    $self->_registerRoutes($m);
    return $self->_enable_module( $m, $self->sfModules );
}

sub _enable_module {
    my ( $self, $m, $array ) = @_;

    my $rule = $self->p->buildRule( $m->rule );
    return 0 unless $rule;

    push @$array,
      {
        p => $m->prefix,
        m => $m,
        r => $rule,
        t => ( $m->can('type') ? $m->type : $m->prefix ),
      };
    return 1;
}

# RUNNING METHODS

# public PE_CODE run($req)
#
# run() is called at each authentication, just after sessionInfo populated
sub run {
    my ( $self, $req ) = @_;
    my $checkLogins   = $req->param('checkLogins');
    my $forceUpgrade  = $req->param('forceUpgrade');
    my $stayconnected = $req->param('stayconnected');
    my $spoofId       = $req->param('spoofId') || '';
    $self->logger->debug("2F checkLogins is set")  if $checkLogins;
    $self->logger->debug("2F forceUpgrade is set") if $forceUpgrade;

    # Skip 2F unless a module has been registered
    unless ( @{ $self->sfModules } ) {
        if ( $self->conf->{sfOnlyUpgrade} and $req->data->{doingSfUpgrade} ) {
            $self->logger->error(
                    "Trying to perform 2FA session upgrade but no "
                  . "second factor modules are configured" );
            return PE_ERROR;
        }
        else {
            return PE_OK;
        }
    }

    # Skip 2F if authnLevel is already high enough
    if (
            $self->conf->{sfOnlyUpgrade}
        and !$forceUpgrade
        and ( ( $req->pdata->{targetAuthnLevel} || 0 ) <=
            ( $req->sessionInfo->{authenticationLevel} || 0 ) )
      )
    {
        $self->logger->debug(
                "Current authentication level satisfied target service,"
              . " skipping 2FA" );
        return PE_OK;
    }

    # Remove expired 2F devices
    my $session    = $req->sessionInfo;
    my $_2fDevices = $self->get2fDevices( $req, $session );
    if ( scalar @$_2fDevices ) {
        my ( $removed, $name, $now, @expired2fDevices );

        $self->logger->debug("Looking for expired 2F device(s)...");
        $now = time();
        foreach my $device (@$_2fDevices) {
            my $type = lc( $device->{type} );
            $type =~ s/2f$//i;
            $type = 'yubikey' if $type eq 'ubk';
            my $ttl = $self->conf->{ $type . '2fTTL' };
            if ( $ttl and $ttl > 0 and $now - $device->{epoch} > $ttl ) {
                $self->logger->debug(
"Remove $device->{type} -> $device->{name} / $device->{epoch}"
                );
                $self->auditLog(
                    $req,
                    message => ("Remove expired $device->{type}"),
                    code    => "2FA_DEVICE_EXPIRED",
                    device  => display2F($device),
                    user    => $req->user,
                );
                push @expired2fDevices, $device;
                $name .= "$device->{name}; ";
                $removed++;
            }
        }

        if ($removed) {
            $name =~ s/;\s$//;
            $self->logger->debug(
"Found $removed EXPIRED 2F device(s) => Update persistent session"
            );
            $self->userLogger->notice(
                " -> $removed expired 2F device(s) will be removed ($name)");

            # Display message if required
            if (   $self->del2fDevices( $req, $session, \@expired2fDevices )
                && $self->sfMsgRule->( $req, $req->sessionInfo ) )
            {
                my $uid  = $req->user;
                my $date = strftime "%Y-%m-%d", localtime;
                my $ref  = $self->conf->{sfRemovedNotifRef} || 'RemoveSF';
                $ref .= '-' . time();
                my $title = $self->conf->{sfRemovedNotifTitle}
                  || 'Second factor notification';
                my $msg = $self->conf->{sfRemovedNotifMsg}
                  || "$removed expired second factor(s) has/have been removed ($name)!";
                $msg =~ s/\b_removedSF_\b/$removed/;
                $msg =~ s/\b_nameSF_\b/$name/;
                my $params =
                  $removed > 1
                  ? { trspan => "expired2Fremoved, $removed, $name" }
                  : { trspan => "oneExpired2Fremoved, $name" };

                my $notifEngine = $self->p->loadedModules->{
                    'Lemonldap::NG::Portal::Plugins::Notifications'};

                my $res =
                  ( $self->conf->{sfRemovedUseNotif} && $notifEngine )
                  ? $self->createNotification( $req, $uid, $date, $ref, $title,
                    $msg )
                  : $self->displayTemplate( $req, 'simpleInfo', $params );
                return $res if $res;
            }
        }
    }

    # Search for authorized modules for this user
    my @am = $self->searchForAuthorized2Fmodules($req);

    # If no 2F module is authorized, skipping 2F
    # Note that a rule may forbid access after (GrantSession plugin)
    unless (@am) {

        # Except if 2FA is required, move to registration
        if ( $self->sfReq->( $req, $req->sessionInfo ) ) {
            $self->logger->debug("2F is required...");
            $self->logger->debug(" -> Register 2F");
            $req->pdata->{sfRegToken} =
              $self->regOtt->createToken( $self->save2faSessionInfo($req) );
            $self->logger->debug("Just one 2F is enabled");
            $self->logger->debug(" -> Redirect to 2fregisters/");
            $req->response( [
                    302,
                    [
                        Location =>
                          $self->p->buildUrl( $req->portal, '2fregisters' )
                    ],
                    []
                ]
            );
            return PE_SENDRESPONSE;
        }
        else {
            if ( $self->conf->{sfOnlyUpgrade} and $req->data->{doingSfUpgrade} )
            {

                # cancel redirection to issuer/vhost
                delete $req->pdata->{_url};
                return PE_NO_SECOND_FACTORS;
            }
            else {
                return PE_OK;
            }
        }
    }

    $self->auditLog(
        $req,
        message => (
            'Second factor required for '
              . $req->sessionInfo->{ $self->conf->{whatToTrace} }
        ),
        code => "2FA_REQUIRED",
        user => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

    delete $req->{authResult};

    $req->data->{_2fRetries} = $self->conf->{sfRetries};
    my $token = $self->ott->createToken( $self->save2faSessionInfo($req) );

    # If only one 2F is authorized, display it
    unless ($#am) {
        $self->auditLog(
            $req,
            message => (
                    'Second factor '
                  . $am[0]->prefix
                  . '2f selected for '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
            ),
            code => "2FA_SELECTED",
            user => $req->sessionInfo->{ $self->conf->{whatToTrace} },
            type => $am[0]->prefix,
        );

        my $res = $am[0]->run( $req, $token );
        $req->authResult($res);
        return $res;
    }

    # More than 1 2F has been found, display choice
    $self->logger->debug("Prepare 2F choice");
    my $res = $self->p->sendHtml(
        $req,
        '2fchoice',
        params => {
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayconnected,
            TOKEN         => $token,
            MSG           => $self->canUpdateSfa($req) || 'choose2f',
            ALERT   => ( $self->canUpdateSfa($req) ? 'warning' : 'positive' ),
            MODULES => [
                map {
                    {
                        CODE  => $_->prefix,
                        LOGO  => $_->logo,
                        LABEL => $_->label
                    }
                } @am
            ],
        }
    );
    $req->response($res);
    return PE_SENDRESPONSE;
}

sub save2faSessionInfo {
    my ( $self, $req ) = @_;
    my $spoofId = $req->param('spoofId') || '';

    my $info = { %{ $req->sessionInfo } };

    # Store user data in a token
    $info->{_2fRetries}     = $req->data->{_2fRetries};
    $info->{_2fRealSession} = $req->id;
    $info->{_2fUrldc}       = $req->urldc;
    $info->{_2fUtime}       = $req->sessionInfo->{_utime};
    if ( $self->conf->{impersonationRule} ) {
        $info->{_impSpoofId} = $spoofId;
        $info->{_impUser}    = $req->user;
    }

    return $info;
}

sub restore2faSessionInfo {
    my ( $self, $req, $info ) = @_;

    # Update sessionInfo
    delete $info->{$_}
      foreach (qw(tokenSessionStartTimestamp tokenTimeoutTimestamp _type));
    $req->data->{_2fRetries} = delete $info->{_2fRetries};
    $req->sessionInfo($info);
    $req->id( delete $req->sessionInfo->{_2fRealSession} );
    $req->urldc( delete $req->sessionInfo->{_2fUrldc} );
    $req->{sessionInfo}->{_utime} = delete $req->{sessionInfo}->{_2fUtime};
}

# bool public display2fRegisters($req, $session)
#
# Return true if at least 1 register module is available for this user.
# Used by Menu for displaying or not /2fregisters page
sub display2fRegisters {
    my ( $self, $req, $session ) = @_;
    foreach my $m ( @{ $self->sfRModules } ) {
        return 1 if $m->{r}->( $req, $session );
    }
    return 0;
}

sub _choice {
    my ( $self, $req ) = @_;

    my ( $tokres, $session ) = $self->_check_token($req);
    if ( $tokres != PE_OK ) {
        $self->auditLog(
            $req,
            message      => "Token validation failed during 2FA type selection",
            code         => "2FA_SELECTION_FAILED",
            user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
            reason       => "Token validation failed",
            portal_error => portalConsts->{$tokres},
        );
        return $self->p->do( $req, [ sub { $tokres } ] );
    }

    $req->sessionInfo($session);

    my $ch = $req->param('sf');
    foreach my $m ( @{ $self->sfModules } ) {
        if ( $m->{m}->prefix eq $ch ) {
            $self->auditLog(
                $req,
                message => (
                        'Second factor '
                      . $m->{m}->prefix
                      . '2f selected for '
                      . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                ),
                code => "2FA_SELECTED",
                user => $req->sessionInfo->{ $self->conf->{whatToTrace} },
                type => $m->{m}->prefix,
            );

            # New token
            my $token = $self->ott->createToken( $req->sessionInfo );
            my $res   = $m->{m}->run( $req, $token );
            $req->authResult($res);
            return $self->p->do(
                $req,
                [
                    sub { $res },  'controlUrl',
                    'buildCookie', @{ $self->p->endAuth },
                ]
            );
        }
    }
    $self->auditLog(
        $req,
        message      => ('Bad 2F choice'),
        code         => "2FA_SELECTION_FAILED",
        reason       => "Unknown type",
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
        portal_error => portalConsts->{PE_ERROR},
        type         => $ch,
    );
    return $self->p->do( $req, [ sub { PE_ERROR } ] );
}

sub _redirect {
    my ( $self, $req ) = @_;
    my $arg = $req->env->{QUERY_STRING};

    $self->logger->debug('Call sfEngine _redirect method');
    return [ 302, [ Location => $req->portal . ( $arg ? "?$arg" : '' ) ], [] ];
}

sub _displayRegister {
    my ( $self, $req, $prefix ) = @_;
    my $_2fDevices = [];
    my @am;
    my %tplParams;

    if ( $req->params("continue") ) {
        %tplParams = (
            %tplParams,
            MSG   => 'your2faIsRegistered',
            ALERT => "positive",
        );
    }

    $self->p->importHandlerData($req);

    # After verifying rule:
    #  - display template if $prefix
    #  - else display choice template
    if ($prefix) {
        my ($m) =
          grep { $_->{m}->prefix eq $prefix } @{ $self->sfRModules };
        return $self->p->sendError( $req, 'Inexistent register module', 400 )
          unless $m;
        return $self->p->sendError( $req, 'Registration not authorized', 403 )
          unless $m->{r}->( $req, $req->userData );
        my $mod = $m->{m};

        if ( $mod->can('initDisplay') ) {
            $mod->initDisplay($req);
        }
        return $self->p->sendHtml(
            $req,
            $mod->template,
            params => {
                CUSTOM_SCRIPT    => $req->data->{customScript},
                PREFIX           => $prefix,
                "PREFIX_$prefix" => 1,
                MSG              => $self->canUpdateSfa($req) || $mod->welcome,
                ALERT => ( $self->canUpdateSfa($req) ? 'warning' : 'positive' ),
            }
        );
    }

    foreach my $m ( @{ $self->sfRModules } ) {
        $self->logger->debug(
            'Looking if ' . $m->{m}->prefix . '2f register is available' );
        if ( $m->{r}->( $req, $req->userData ) ) {
            push @am,
              {
                CODE  => $m->{m}->prefix,
                URL   => '/2fregisters/' . $m->{m}->prefix,
                LOGO  => $m->{m}->logo,
                LABEL => $m->{m}->label
              };
        }
    }

    # Retrieve user all second factors
    if ( $self->canUpdateSfa($req) ) {
        $self->userLogger->warn("Do not display 2F devices!");
    }
    else {
        $_2fDevices = $self->get2fDevices( $req, $req->userData );
    }

    # If only one 2F is available, redirect to it
    return [
        302,
        [
            Location =>
              $self->p->buildUrl( $req->portal, '2fregisters', $am[0]->{CODE} )
        ],
        []
      ]
      if (
        @am == 1
        and not( @$_2fDevices
            or $req->data->{sfRegRequired} )
      );

   # Parse second factors to display delete button if allowed and upgrade button
    my ( $displayUpgBtn, $action ) = ( 0, '' );
    foreach my $reg_mod_info ( @{ $self->sfRModules } ) {
        my $type   = $reg_mod_info->{t};
        my $prefix = $reg_mod_info->{p};
        my $module = $reg_mod_info->{m};
        foreach (@$_2fDevices) {

            if ( $_->{type} eq $type ) {

                # Set k_v template variables for non_private values
                # and also not for epoch/name
                my $extrakeys = filterKey2F( $_, "epoch", "name" );
                while ( my ( $k, $v ) = each %$extrakeys ) {
                    $_->{"${k}_${v}"} = 1;
                }

                # Populate additional info for template engine
                $_->{prefix}     = $prefix;
                $_->{label}      = $module->label;
                $_->{delAllowed} = $self->isDelAllowed( $req, $reg_mod_info );

                # Display upgrade button
                $displayUpgBtn ||= $module->authnLevel
                  && $module->authnLevel >
                  $req->userData->{authenticationLevel};
            }
            $action ||= $_->{delAllowed};
        }
    }
    $displayUpgBtn = 0 unless $self->conf->{upgradeSession};

    # Display template
    return $self->p->sendHtml(
        $req,
        '2fregisters',
        params => {
            MODULES      => \@am,
            SFDEVICES    => $_2fDevices,
            ACTION       => $action,
            REG_REQUIRED => $req->data->{sfRegRequired},
            DISPLAY_UPG  => $displayUpgBtn,
            MSG          => $self->canUpdateSfa($req) || 'choose2f',
            ALERT => ( $self->canUpdateSfa($req) ? 'warning' : 'positive' ),
            SFREGISTERS_URL => encode_base64(
                $self->p->buildUrl( $req->portal, '2fregisters' ), ''
            ),
            %tplParams,
        }
    );
}

sub isDelAllowed {
    my ( $self, $req, $reg_mod_info ) = @_;
    return ( $self->isRegistrationEnabled( $req, $reg_mod_info )
          && $reg_mod_info->{m}->userCanRemove );
}

sub isRegistrationEnabled {
    my ( $self, $req, $reg_mod_info ) = @_;
    my $module = $reg_mod_info->{m};
    my $prefix = $module->prefix;

    my $rule = $reg_mod_info->{r};

    # Extra modules require special processing
    if ( $self->conf->{sfExtra}->{$prefix} ) {
        return $rule->( $req, $req->userData );
    }
    else {
        return $self->conf->{ $prefix . '2fActivation' }
          && $rule->( $req, $req->userData );
    }
}

# Check rule and display
sub register {
    my ( $self, $req, $prefix, @args ) = @_;
    my @am;

    # After verifying rule:
    #   - call register run method if $prefix
    #   - else give JSON list of available registers for this user
    if ($prefix) {
        my ($m) =
          grep { $_->{m}->prefix eq $prefix } @{ $self->sfRModules };
        return $self->p->sendError( $req, 'Unknown register module', 400 )
          unless $m;
        unless ( $m->{r}->( $req, $req->userData ) ) {
            $self->userLogger->error("${prefix}2F registration not allowed");
            return $self->p->sendError( $req, "notAuthorized", 403 );
        }

        my $can_update_error = $self->canUpdateSfa( $req, $m->{m}, @args );
        return $can_update_error
          ? $self->sendError( $req, $can_update_error, 400 )
          : $m->{m}->run( $req, @args );
    }

    foreach ( @{ $self->sfRModules } ) {
        $self->logger->debug(
            'Looking if ' . $_->{m}->prefix . '2F register is available' );
        if ( $_->{r}->( $req, $req->userData ) ) {
            $self->logger->debug(' -> OK');
            my $name = $_->{m}->prefix;
            push @am,
              {
                name => $name,
                logo => $_->{m}->logo,
                url  => "/2fregisters/$name"
              };
        }
    }
    return $self->p->sendJSONresponse( $req, \@am );
}

sub restoreSession {
    my ( $self, $req, @path ) = @_;

    if ( my $token = $req->pdata->{sfRegToken} ) {
        if ( my $sessionData = $self->regOtt->getToken( $token, 1 ) ) {

            unless ( $sessionData->{_2fRealSession} ) {
                $self->logger->error("Invalid 2FA registration token");
                return [ 302, [ Location => $req->portal ], [] ];
            }
            $self->restore2faSessionInfo( $req, $sessionData );

            if ( $req->params("continue") ) {
                return $self->continueLoginAfterRegistration($req);
            }

            $req->userData( $req->sessionInfo );
            $req->data->{sfRegRequired} = 1;
            if ( $req->method eq 'POST' ) {
                my $res = $self->register( $req, @path );

                if ( $req->data->{_2fRegistered} ) {
                    $self->regOtt->updateToken( $token,
                        "_2f" => $req->userData->{'_2f'} );
                    if ( my $authnLevel =
                        $req->userData->{registeredAuthenticationLevel} )
                    {
                        $self->regOtt->updateToken( $token,
                            "newAuthenticationLevel" => $authnLevel );
                    }
                }
                return $res;
            }
            else {
                return $self->_displayRegister( $req, @path );
            }
        }
    }
    $self->logger->warn(
        "Cannot restore session state during mandatory 2FA registration");
    return [ 302, [ Location => $req->portal ], [] ];
}

sub continueLoginAfterRegistration {
    my ( $self, $req ) = @_;

    # Check if registration was done
    if ( !$req->sessionInfo->{_2f} ) {
        $self->logger->error("2FA registration was not completed");
        return $self->p->do( $req, [ sub { PE_ERROR } ] );
    }

    # Else restore session
    $req->mustRedirect(1);

    my $prefix = $req->sessionInfo->{_2f};
    my $level  = $req->sessionInfo->{newAuthenticationLevel};
    return $self->_continueLogin( $req, $prefix, $level );
}

sub _continueLogin {
    my ( $self, $req, $prefix, $level ) = @_;

    if ($level) {
        $self->logger->debug(
            "Update sessionInfo with new authenticationLevel: $level");
        $req->sessionInfo->{authenticationLevel} = $level;

        # Compute macros & local groups again with new authenticationLevel
        $self->logger->debug("Compute macros and local groups...");
        $req->steps( [ 'setMacros', 'setLocalGroups' ] );
        if ( my $error = $self->p->process($req) ) {
            $self->logger->debug("SFA: Process returned error: $error");
            $req->error($error);
            return $self->p->do( $req, [ sub { $error } ] );
        }
        $self->logger->debug("De-duplicate groups...");
        $req->sessionInfo->{groups} = join $self->conf->{multiValuesSeparator},
          keys %{ {
                map { $_ => 1 } split $self->conf->{multiValuesSeparator},
                $req->sessionInfo->{groups}
            }
          };

        $self->logger->debug("Filter macros...");
        my %macros = (
            map { $_ => $req->sessionInfo->{$_} }
              keys %{ $self->{conf}->{macros} }
        );

        $self->logger->debug(
"Update session with new authenticationLevel, groups, hGroups and macros"
        );
        $self->p->updateSession(
            $req,
            {
                authenticationLevel => $level,
                groups              => $req->sessionInfo->{groups},
                hGroups             => $req->sessionInfo->{hGroups},
                _2f                 => $prefix,
                %macros
            }
        );
    }
    else {
        # Only update _2f session key
        $self->p->updateSession(
            $req,
            {
                _2f => $prefix,
            }
        );
    }

    $req->authResult(PE_SENDRESPONSE);
    return $self->p->do(
        $req,
        [
            @{ $self->p->afterData },
            $self->p->validSession,
            @{ $self->p->endAuth },
            sub { PE_OK }
        ]
    );
}

sub _verify {
    my ( $self, $prefix, $req ) = @_;

    # Locate the module which handles this prefix
    my ($m) =
      grep { $_->{m}->prefix eq $prefix } @{ $self->sfModules };
    return $self->p->sendError( $req, 'Unknown 2F module', 400 )
      unless $m;
    my $module = $m->{m};

    my ( $tokres, $session ) = $self->_check_token($req);
    if ( $tokres != PE_OK ) {
        $self->auditLog(
            $req,
            message => (
                "Token validation failed during ${prefix}2f verification ("
                  . portalConsts->{$tokres} . ")"
            ),
            code         => "2FA_FAILED",
            reason       => "Token validation failed",
            type         => $prefix,
            portal_error => portalConsts->{$tokres},
        );
        return $self->p->do( $req, [ sub { $tokres } ] );
    }

    my $user = $session->{ $self->conf->{whatToTrace} };

    # Evaluate hook
    {
        my $h =
          $self->p->processHook( $req, 'sfBeforeVerify', $module, $session );
        if ( $h != PE_OK ) {
            $req->noLoginDisplay(1);
            return $self->p->do( $req, [ sub { $h } ] );
        }
    }

    # Launch second factor verification
    my $verify_result = {
        result              => $module->verify( $req, $session ),
        authenticationLevel => $module->authnLevel,
        retries             => ( $session->{_2fRetries} || 0 ),
        (
            $req->data->{_2fDevice} ? ( device => $req->data->{_2fDevice} ) : ()
        ),
        (
            $req->data->{_2fLogInfo}
            ? ( logInfo => $req->data->{_2fLogInfo} )
            : ()
        ),
    };

    # Evaluate hook
    {
        my $h = $self->p->processHook( $req, 'sfAfterVerify', $module, $session,
            $verify_result );
        if ( $h != PE_OK ) {
            $req->noLoginDisplay(1);
            return $self->p->do( $req, [ sub { $h } ] );
        }
    }

    # May be modified by sfAfterVerify
    my $res        = $verify_result->{result};
    my $authnLevel = $verify_result->{authenticationLevel};
    my $retries    = $verify_result->{retries};

    $self->restore2faSessionInfo( $req, $session );

    # Case error
    if ( $res and $retries == 0 ) {
        $req->noLoginDisplay(1);
        $req->authResult(PE_BADCREDENTIALS);

        $self->auditLog(
            $req,
            message => (
                "Second factor ${prefix}2f failed for $user ("
                  . portalConsts->{$res} . ")"
            ),
            code         => "2FA_FAILED",
            user         => $user,
            type         => $prefix,
            portal_error => portalConsts->{$res},
        );

        # Set the failed 2f type in case you want to store it in history
        # through sessionDataToRemember
        $req->sessionInfo->{'_2f'} = $prefix;
        return $self->p->do( $req, [ 'storeHistory', sub { $res } ] );
    }
    elsif ($res) {
        $req->data->{_2fRetries} = (
            ( $retries > 0 )
            ? $retries - 1
            : 0
        );

        # Evaluate hook
        {
            my $h = $self->p->processHook( $req, 'sfBeforeRetry', $module );
            if ( $h != PE_OK ) {
                $req->noLoginDisplay(1);
                return $self->p->do( $req, [ sub { $h } ] );
            }
        }

        $self->logger->debug(
            "Retrying 2FA: " . $req->data->{_2fRetries} . " retries left" );

        $req->error(PE_RETRY_2FA);
        my $token = $self->ott->createToken( $self->save2faSessionInfo($req) );
        my $res   = $module->run( $req, $token );
        $req->authResult($res);

        return $self->p->do( $req, [ sub { $res } ] );
    }

    # Else restore session
    $req->mustRedirect(1);
    my $device  = $verify_result->{device};
    my $logInfo = $verify_result->{logInfo} || {};
    my $logInfoStr =
      join( ', ', map { "$_: " . $logInfo->{$_} } keys %$logInfo );

    $self->auditLog(
        $req,
        message => (
                "Second factor ${prefix}2f verification succeeded for $user"
              . ( $device     ? ( " with device " . display2F($device) ) : "" )
              . ( $logInfoStr ? " ($logInfoStr)"                         : "" )
        ),
        code => "2FA_SUCCESS",
        user => $user,
        type => $prefix,
        ( $device ? ( device => display2F($device) ) : () ),
        %$logInfo,
    );

    return $self->_continueLogin( $req, $prefix, $authnLevel, );
}

sub searchForAuthorized2Fmodules {
    my ( $self, $req, $session ) = @_;
    $session ||= $req->sessionInfo;
    my @am;
    foreach ( @{ $self->sfModules } ) {
        my $authModuleName = $_->{m}->prefix;
        $self->logger->debug('Looking for ' . $authModuleName . ' 2f');

        # Adding targetAuthnLevel from req to session;
        my $modifiedSession = {%$session};
        $modifiedSession->{targetAuthnLevel} = $req->{pdata}->{targetAuthnLevel}
          if $req->{pdata}->{targetAuthnLevel};

        if ( $_->{r}->( $req, $modifiedSession ) ) {
            $self->logger->debug(' -> ' . $authModuleName . ' 2f is available');
            push @am, $_->{m};
        }
    }
    return @am;
}

sub canUpdateSfa {
    my ( $self, $req, $module, $action ) = @_;
    my $user   = $req->userData->{ $self->conf->{whatToTrace} };
    my $prefix = '';
    my $msg;

    # Test actions
    if ( $module && $action ) {
        my $requiredLevel = $module->authnLevel;
        $prefix = $module->prefix;
        $self->logger->debug("$user request to $action ${prefix}2f device");

        if ( $action eq 'delete' ) {
            $msg = 'notAuthorizedAuthLevel'
              if ( $requiredLevel
                && $req->userData->{authenticationLevel} < $requiredLevel );
        }
        if ( $action =~ /^(regist|verify)/ ) {
            my $_2fDevices = $self->get2fDevices( $req, $req->userData );
            if ( !$self->checkMaximumSfaCount( $req, $_2fDevices ) ) {
                $msg = 'maxNumberOf2FDevicesReached';
            }
            elsif (
                !$self->checkMaxAvailableAuthenticationLevel(
                    $req, $_2fDevices
                )
              )
            {
                $msg = 'notAuthorizedAuthLevel';
            }
            else {
                $self->logger->debug(
                    "$user is allowed to $action ${prefix}2f device");
            }
        }
    }

    unless ($msg) {
        my $module;
        $action ||= 'update';

        # Test if Impersonation is in progress
        if ( $self->conf->{impersonationRule} ) {
            $self->logger->debug('Impersonation plugin is enabled');
            $module = 'Impersonation';
            $msg    = 'notAuthorized'
              if ( $req->userData->{"$self->{conf}->{impersonationPrefix}_user"}
                && $req->userData->{"$self->{conf}->{impersonationPrefix}_user"}
                ne $req->userData->{_user} );
        }

        # Test if ContextSwitching is in progress
        if ( $self->conf->{contextSwitchingRule} ) {
            $self->logger->debug('ContextSwitching plugin is enabled');
            $module = 'ContextSwitching';
            $msg    = 'notAuthorized'
              if (
                $req->userData->{
                    "$self->{conf}->{contextSwitchingPrefix}_session_id"}
                && !$self->conf->{contextSwitchingAllowed2fModifications}
              );

        }
        if ($msg) {
            $self->userLogger->warn(
"$module in progress! $user is not allowed to $action ${prefix}2f device"
            );
            $self->logger->debug(
"$user is NOT allowed to $action ${prefix}2f device because $module is in progress"
            );
        }
        else {
            $self->logger->debug(
                "$user is allowed to $action ${prefix}2f device");
        }
    }

    return $msg;
}

sub findRegisterModuleFor {
    my ( $self, $mod ) = @_;

    return $mod->isa("Lemonldap::NG::Portal::Lib::Code2F")
      ? "::2F::Register::Generic"
      : undef;
}

# Check if user can register one more SFA
sub checkMaximumSfaCount {
    my ( $self, $req, $_2fDevices ) = @_;
    my $user    = $req->userData->{ $self->conf->{whatToTrace} };
    my $maxSize = $self->conf->{max2FDevices};
    my $size    = @$_2fDevices;
    $self->logger->debug("Registered 2F device(s) for $user: $size / $maxSize");
    if ( $size >= $maxSize ) {
        $self->userLogger->warn(
            "Max number of 2F devices is reached for $user");
        return 0;
    }
    return 1;
}

# Check if user's authentication is sufficient to register a SFA
sub checkMaxAvailableAuthenticationLevel {
    my ( $self, $req, $_2fDevices ) = @_;
    my $user          = $req->userData->{ $self->conf->{whatToTrace} };
    my $requiredLevel = my $authnLevel = $req->userData->{authenticationLevel};
    my @am = $self->searchForAuthorized2Fmodules( $req, $req->userData );
    my %authnLevel = map { $_->type => $_->authnLevel } @am;
    foreach (@$_2fDevices) {
        $requiredLevel = $authnLevel{ $_->{type} }
          if ( $authnLevel{ $_->{type} }
            && $authnLevel{ $_->{type} } > $requiredLevel );
    }
    if ( $requiredLevel > $authnLevel ) {
        $self->userLogger->warn(
            "$user request rejected due to insufficient authentication level!");
        $self->logger->debug(
            "authnLevel: $authnLevel < requiredLevel: $requiredLevel");
        return 0;
    }
    return 1;
}

sub _registerRoutes {
    my ( $self, $m ) = @_;
    unless ( $m->noRoute ) {
        my $prefix = $m->prefix;
        $self->logger->debug( 'Adding ' . $prefix . '2fcheck routes' );
        $self->addAuthRoute(
            $prefix . '2fcheck' => sub {
                my $self = shift;
                return $self->_verify( $prefix, @_ );
            },
            ['POST']
        );
        $self->addAuthRoute(
            $prefix . '2fcheck' => '_redirect',
            ['GET']
        );
        $self->addUnauthRoute(
            $prefix . '2fcheck' => sub {
                my $self = shift;
                return $self->_verify( $prefix, @_ );
            },
            ['POST']
        );
        $self->addUnauthRoute(
            $prefix . '2fcheck' => '_redirect',
            ['GET']
        );
    }
}

sub get2fTplParams {
    my ( $self, $req, $module ) = @_;
    my %param       = $self->p->getErrorTplParams($req);
    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug( $module->prefix . '2f: checkLogins set' )
      if $checkLogins;

    my $stayConnected = $req->param('stayconnected');
    $self->logger->debug( $module->prefix . '2f: stayConnected set' )
      if $stayConnected;

    $param{CHECKLOGINS}   = $checkLogins;
    $param{STAYCONNECTED} = $stayConnected;

    return %param;
}

sub _check_token {
    my ( $self, $req ) = @_;

    my $token;
    unless ( $token = $req->param('token') ) {
        $self->logger->error('2F choice requested without token');
        $req->mustRedirect(1);
        return PE_NOTOKEN;
    }

    my $session;
    unless ( $session = $self->ott->getToken($token) ) {
        $self->logger->error('Invalid 2F choice form token');
        $req->noLoginDisplay(1);
        return PE_TOKENEXPIRED;
    }

    unless ( $session->{_2fRealSession} ) {
        $self->logger->error("Invalid 2FA session token");
        $req->noLoginDisplay(1);
        return PE_ERROR;
    }
    return ( PE_OK, $session );
}

1;
