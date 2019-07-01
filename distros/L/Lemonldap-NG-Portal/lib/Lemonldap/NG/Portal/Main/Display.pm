## @file
# Display functions for LemonLDAP::NG Portal
package Lemonldap::NG::Portal::Main::Display;

our $VERSION = '2.0.5';

package Lemonldap::NG::Portal::Main;
use strict;
use Mouse;
use JSON;
use Data::Dumper;

has skinRules => ( is => 'rw' );

sub displayInit {
    my ($self) = @_;
    $self->skinRules( [] );
    if ( $self->conf->{portalSkinRules} ) {
        foreach my $skinRule ( sort keys %{ $self->conf->{portalSkinRules} } ) {
            my $sub = HANDLER->buildSub( HANDLER->substitute($skinRule) );
            if ($sub) {
                push @{ $self->skinRules },
                  [ $self->conf->{portalSkinRules}->{$skinRule}, $sub ];
            }
            else {
                $self->logger->error(
                    qq(Skin rule "$skinRule" returns an error: )
                      . HANDLER->tsv->{jail}->error );
            }
        }
    }
}

# Call portal process and set template parameters
# @return template name and template parameters
sub display {
    my ( $self, $req ) = @_;

    my $skin_dir = $self->conf->{templateDir};
    my ( $skinfile, %templateParams );

    # 1. Authentication not complete

    # 1.1 A notification has to be done (session is created but hidden and
    #     unusable until the user has accept the message)
    if ( my $notif = $req->data->{notification} ) {
        $self->logger->debug('Display: notification detected');
        $skinfile       = 'notification';
        %templateParams = (
            MAIN_LOGO       => $self->conf->{portalMainLogo},
            LANGS           => $self->conf->{showLanguages},
            AUTH_ERROR_TYPE => $req->error_type,
            NOTIFICATION    => $notif,
            HIDDEN_INPUTS   => $self->buildHiddenForm($req),
            AUTH_URL        => $req->{data}->{_url},
            CHOICE_PARAM    => $self->conf->{authChoiceParam},
            CHOICE_VALUE    => $req->data->{_authChoice},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 1.2a An authentication (or userDB) module needs to ask a question
    #     before processing to the request
    elsif ( $req->{error} == PE_CONFIRM ) {
        $self->logger->debug('Display: confirm detected');
        $skinfile       = 'confirm';
        %templateParams = (
            MAIN_LOGO       => $self->conf->{portalMainLogo},
            LANGS           => $self->conf->{showLanguages},
            AUTH_ERROR      => $req->error,
            AUTH_ERROR_TYPE => $req->error_type,
            AUTH_URL        => $req->{data}->{_url},
            MSG             => $req->info,
            HIDDEN_INPUTS   => $self->buildHiddenForm($req),
            ACTIVE_TIMER    => $req->data->{activeTimer},
            FORM_METHOD     => $self->conf->{confirmFormMethod},
            CHOICE_PARAM    => $self->conf->{authChoiceParam},
            CHOICE_VALUE    => $req->data->{_authChoice},
            CHECK_LOGINS    => $self->conf->{portalCheckLogins}
              && $req->data->{login},
            ASK_LOGINS => $req->param('checkLogins') || 0,
            CONFIRMKEY => $self->stamp(),
            REMEMBER   => $req->data->{confirmRemember},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 1.2b An authentication (or userDB) module needs to ask a question
    #     before processing to the request
    elsif ( $req->{error} == PE_IDPCHOICE ) {
        $self->logger->debug('Display: IDP choice detected');
        $skinfile       = 'idpchoice';
        %templateParams = (
            MAIN_LOGO       => $self->conf->{portalMainLogo},
            LANGS           => $self->conf->{showLanguages},
            AUTH_ERROR      => $req->error,
            AUTH_ERROR_TYPE => $req->error_type,
            AUTH_URL        => $req->{data}->{_url},
            HIDDEN_INPUTS   => $self->buildHiddenForm($req),
            ACTIVE_TIMER    => $req->data->{activeTimer},
            FORM_METHOD     => $self->conf->{confirmFormMethod},
            CHOICE_PARAM    => $self->conf->{authChoiceParam},
            CHOICE_VALUE    => $req->data->{_authChoice},
            CHECK_LOGINS    => $self->conf->{portalCheckLogins}
              && $req->data->{login},
            ASK_LOGINS => $req->param('checkLogins') || 0,
            CONFIRMKEY => $self->stamp(),
            LIST       => $req->data->{list} || [],
            REMEMBER   => $req->data->{confirmRemember},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 1.3 There is a message to display
    elsif ( my $info = $req->info ) {
        $self->logger->debug('Display: info detected');
        $self->logger->debug(
            'Hidden values -> ' . Dumper( $req->{portalHiddenFormValues} ) );
        $skinfile       = 'info';
        %templateParams = (
            MAIN_LOGO       => $self->conf->{portalMainLogo},
            LANGS           => $self->conf->{showLanguages},
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $req->error_type,
            MSG             => $info,
            URL             => $req->{urldc},
            HIDDEN_INPUTS   => $self->buildHiddenForm($req),
            ACTIVE_TIMER    => $req->data->{activeTimer},
            FORM_METHOD     => $self->conf->{infoFormMethod},
            CHOICE_PARAM    => $self->conf->{authChoiceParam},
            CHOICE_VALUE    => $req->data->{_authChoice},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 1.4 OpenID menu page
    elsif ($req->{error} == PE_OPENID_EMPTY
        or $req->{error} == PE_OPENID_BADID )
    {
        $skinfile = 'openid';
        my $p = $self->conf->{portal} . $self->conf->{issuerDBOpenIDPath};
        $p =~ s#(?<!:)/?\^?/#/#g;
        my $id = $req->{sessionInfo}
          ->{ $self->conf->{openIdAttr} || $self->conf->{whatToTrace} };
        %templateParams = (
            MAIN_LOGO       => $self->conf->{portalMainLogo},
            LANGS           => $self->conf->{showLanguages},
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $req->error_type,
            PROVIDERURI     => $p,
            MSG             => $req->info(),
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
        $templateParams{ID} = $req->data->{_openidPortal} . $id if ($id);
    }

    # 2. Good authentication

    # 2.1 Redirection
    elsif ( $req->{error} == PE_REDIRECT ) {
        $skinfile       = "redirect";
        %templateParams = (
            URL           => $req->{urldc},
            HIDDEN_INPUTS => $self->buildHiddenForm($req),
            FORM_METHOD   => $req->data->{redirectFormMethod} || 'get',
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 2.2 Case : display menu (with error or not)
    elsif ( $req->error == PE_OK ) {
        $skinfile = 'menu';

        #utf8::decode($auth_user);
        %templateParams = (
            MAIN_LOGO => $self->conf->{portalMainLogo},
            LANGS     => $self->conf->{showLanguages},
            AUTH_USER => $req->{sessionInfo}->{ $self->conf->{portalUserAttr} },
            NEWWINDOW => $self->conf->{portalOpenLinkInNewWindow},
            LOGOUT_URL          => $self->conf->{portal} . "?logout=1",
            APPSLIST_ORDER      => $req->{sessionInfo}->{'_appsListOrder'},
            PING                => $self->conf->{portalPingInterval},
            REQUIRE_OLDPASSWORD => $self->conf->{portalRequireOldPassword},
            HIDE_OLDPASSWORD    => 0,
            $self->menu->params($req),
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    elsif ( $req->error == PE_RENEWSESSION ) {
        $skinfile       = 'upgradesession';
        %templateParams = (
            MAIN_LOGO  => $self->conf->{portalMainLogo},
            LANGS      => $self->conf->{showLanguages},
            MSG        => 'askToRenew',
            CONFIRMKEY => $self->stamp,
            PORTAL     => $self->conf->{portal},
            URL        => $req->data->{_url},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    elsif ( $req->error == PE_MUSTAUTHN ) {
        $skinfile       = 'updatesession';
        %templateParams = (
            MAIN_LOGO  => $self->conf->{portalMainLogo},
            LANGS      => $self->conf->{showLanguages},
            MSG        => 'PE87',
            CONFIRMKEY => $self->stamp,
            PORTAL     => $self->conf->{portal},
            URL        => $req->data->{_url},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 2.3 Case : user authenticated but an error was returned (bad url,...)
    elsif (
        $req->noLoginDisplay
        or (    not $req->data->{noerror}
            and $req->userData
            and %{ $req->userData } )
      )
    {
        $skinfile       = 'error';
        %templateParams = (
            MAIN_LOGO       => $self->conf->{portalMainLogo},
            LANGS           => $self->conf->{showLanguages},
            AUTH_ERROR      => $req->error,
            AUTH_ERROR_TYPE => $req->error_type,
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );
    }

    # 3 Authentication has been refused OR first access
    else {
        $skinfile = 'login';
        my $login = $self->userId($req);
        $login = '' if ( $login eq 'anonymous' );
        %templateParams = (
            MAIN_LOGO             => $self->conf->{portalMainLogo},
            LANGS                 => $self->conf->{showLanguages},
            AUTH_ERROR            => $req->error,
            AUTH_ERROR_TYPE       => $req->error_type,
            AUTH_URL              => $req->{data}->{_url},
            LOGIN                 => $login,
            CHECK_LOGINS          => $self->conf->{portalCheckLogins},
            ASK_LOGINS            => $req->param('checkLogins') || 0,
            DISPLAY_RESETPASSWORD => $self->conf->{portalDisplayResetPassword},
            DISPLAY_REGISTER      => $self->conf->{portalDisplayRegister},
            MAIL_URL              => $self->conf->{mailUrl},
            REGISTER_URL          => $self->conf->{registerUrl},
            HIDDEN_INPUTS         => $self->buildHiddenForm($req),
            STAYCONNECTED         => $self->conf->{stayConnected},
            SPOOFID               => $self->conf->{impersonationRule},
            (
                $req->data->{customScript}
                ? ( CUSTOM_SCRIPT => $req->data->{customScript} )
                : ()
            ),
        );

        # Display captcha if it's enabled
        if ( $req->captcha ) {
            %templateParams = (
                %templateParams,
                CAPTCHA_SRC  => $req->captcha,
                CAPTCHA_SIZE => $self->{conf}->{captcha_size} || 6
            );
        }
        if ( $req->token ) {
            %templateParams = ( %templateParams, TOKEN => $req->token, );
        }

        # Show password form if password policy error
        if (

               $req->{error} == PE_PP_CHANGE_AFTER_RESET
            or $req->{error} == PE_PP_MUST_SUPPLY_OLD_PASSWORD
            or $req->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY
            or $req->{error} == PE_PP_PASSWORD_TOO_SHORT
            or $req->{error} == PE_PP_PASSWORD_TOO_YOUNG
            or $req->{error} == PE_PP_PASSWORD_IN_HISTORY
            or $req->{error} == PE_PASSWORD_MISMATCH
            or $req->{error} == PE_BADOLDPASSWORD
            or $req->{error} == PE_PASSWORDFORMEMPTY
            or (    $req->{error} == PE_PP_PASSWORD_EXPIRED
                and $self->conf->{ldapAllowResetExpiredPassword} )
          )
        {
            %templateParams = (
                %templateParams,
                REQUIRE_OLDPASSWORD =>
                  1,    # Old password is required to check user credentials
                DISPLAY_FORM          => 0,
                DISPLAY_OPENID_FORM   => 0,
                DISPLAY_YUBIKEY_FORM  => 0,
                DISPLAY_PASSWORD      => 1,
                DISPLAY_RESETPASSWORD => 0,
                AUTH_LOOP             => [],
                CHOICE_PARAM          => $self->conf->{authChoiceParam},
                CHOICE_VALUE          => $req->data->{_authChoice},
                OLDPASSWORD           => $self->checkXSSAttack( 'oldpassword',
                    $req->data->{oldpassword} )
                ? ""
                : $req->data->{oldpassword},
                HIDE_OLDPASSWORD => $self->conf->{hideOldPassword},
            );
        }

        # Disable all forms on:
        # * Logout message
        # * Bad URL error
        elsif ($req->{error} == PE_LOGOUT_OK
            or $req->{error} == PE_WAIT
            or $req->{error} == PE_BADURL )
        {
            %templateParams = (
                %templateParams,
                DISPLAY_RESETPASSWORD => 0,
                DISPLAY_FORM          => 0,
                DISPLAY_OPENID_FORM   => 0,
                DISPLAY_YUBIKEY_FORM  => 0,
                AUTH_LOOP             => [],
                MSG                   => $req->info(),
            );

        }

        # Display authentication form
        else {

            # Authentication loop
            if ( $self->conf->{authentication} eq 'Choice'
                and my $authLoop = $self->_buildAuthLoop($req) )
            {
                %templateParams = (
                    %templateParams,
                    AUTH_LOOP            => $authLoop,
                    CHOICE_PARAM         => $self->conf->{authChoiceParam},
                    CHOICE_VALUE         => $req->data->{_authChoice},
                    DISPLAY_FORM         => 0,
                    DISPLAY_OPENID_FORM  => 0,
                    DISPLAY_YUBIKEY_FORM => 0,
                );
            }

            # Choose what form to display if not in a loop
            else {

                my $displayType =
                  eval { $self->_authentication->getDisplayType($req) }
                  || 'logo';

                $self->logger->debug("Display type $displayType ");

                %templateParams = (
                    %templateParams,
                    DISPLAY_FORM => $displayType =~ /\bstandardform\b/ ? 1
                    : 0,
                    DISPLAY_OPENID_FORM => $displayType =~ /\bopenidform\b/ ? 1
                    : 0,
                    DISPLAY_YUBIKEY_FORM => $displayType =~ /\byubikeyform\b/
                    ? 1
                    : 0,
                    DISPLAY_SSL_FORM  => $displayType =~ /sslform/ ? 1 : 0,
                    DISPLAY_GPG_FORM  => $displayType =~ /gpgform/ ? 1 : 0,
                    DISPLAY_LOGO_FORM => $displayType eq "logo"    ? 1 : 0,
                    module            => $displayType eq "logo"
                    ? $self->getModule( $req, 'auth' )
                    : "",
                    AUTH_LOOP => [],
                    PORTAL_URL =>
                      ( $displayType eq "logo" ? $self->conf->{portal} : 0 ),
                    MSG => $req->info(),
                );

            }

        }

    }

    if ( $req->data->{waitingMessage} ) {
        $templateParams{WAITING_MESSAGE} = 1;
    }

    $self->logger->debug("Skin returned: $skinfile");
    return ( $skinfile, \%templateParams );
}

##@method public void printImage(string file, string type)
# Print image to STDOUT
# @param $file The path to the file to print
# @param $type The content-type to use (ie: image/png)
# @return void
sub staticFile {
    my ( $self, $req, $file, $type ) = @_;
    require Plack::Util;
    require Cwd;
    require HTTP::Date;
    open my $fh, '<:raw', $self->conf->{templateDir} . "/$file"
      or return $self->sendError( $req,
        $self->conf->{templateDir} . "/$file: $!", 403 );
    my @stat = stat $file;
    Plack::Util::set_io_path( $fh, Cwd::realpath($file) );
    return [
        200,
        [
            'Content-Type'   => $type,
            'Content-Length' => $stat[7],
            'Last-Modified'  => HTTP::Date::time2str( $stat[9] )
        ],
        $fh,
    ];
}

sub buildHiddenForm {
    my ( $self, $req ) = @_;
    my @keys = keys %{ $req->{portalHiddenFormValues} };
    my $val  = '';

    foreach (@keys) {

        # Check XSS attacks
        next
          if $self->checkXSSAttack( $_, $req->{portalHiddenFormValues}->{$_} );

        # Build hidden input HTML code
        # 'id' is removed to avoid warning with Choice
        #$val .= qq{<input type="hidden" name="$_" id="$_" value="}
        $val .= qq{<input type="hidden" name="$_" value="}
          . $req->{portalHiddenFormValues}->{$_} . '" />';
    }

    return $val;
}

# Return skin name
# @return skin name
# TODO: create property for skinRule
sub getSkin {
    my ( $self, $req ) = @_;

    my $skin = $self->conf->{portalSkin};

    # Fill sessionInfo to eval rule if empty (unauthenticated user)
    $req->{sessionInfo}->{_url}   ||= $req->{urldc};
    $req->{sessionInfo}->{ipAddr} ||= $req->address;

    # Load specific skin from skinRules
    foreach my $rule ( @{ $self->{skinRules} } ) {
        if ( $rule->[1]->( $req, $req->sessionInfo ) ) {
            if ( -d $self->conf->{templateDir} . '/' . $rule->[0] ) {
                $skin = $rule->[0];
                $self->logger->debug("Skin $skin selected from skin rule");
                last;
            }
        }
    }

    # Check skin GET/POST parameter
    my $skinParam = $req->param('skin');
    if ( defined $skinParam ) {
        if ( $skinParam =~ /^[\w\-]+$/ ) {
            if ( -d $self->conf->{templateDir} . '/' . $skinParam ) {
                $skin = $skinParam;
                $self->logger->debug(
                    "Skin $skin selected from GET/POST parameter");
            }
            else {
                $self->userLogger->error(
                    "User tries to access to unexistent skin dir $skinParam");
            }
        }
        else {
            $self->userLogger->error("Strange skin parameter: $skinParam");
        }
    }

    return $skin;
}

# Build an HTML array to display sessions
# @param $sessions Array ref of hash ref containing sessions data
# @param $title Title of the array
# @param $displayUser To display "User" column
# @param $displaError To display "Error" column
# @return HTML string
sub mkSessionArray {
    my ( $self, $req, $sessions, $title, $displayUser, $displayError ) = @_;

    return "" unless ( ref $sessions eq "ARRAY" and @$sessions );

    my @fields = sort keys %{ $self->conf->{sessionDataToRemember} };
    return $self->loadTemplate(
        $req,
        'sessionArray',
        params => {
            title        => $title,
            displayUser  => $displayUser,
            displayError => $displayError,
            fields       => [
                map { { name => $self->conf->{sessionDataToRemember}->{$_} } }
                  @fields
            ],
            sessions => [
                map {
                    my $session = $_;
                    {
                        user   => $session->{user},
                        utime  => $session->{_utime},
                        ip     => $session->{ipAddr},
                        values => [ map { { v => $session->{$_} } } @fields ],
                        error  => $session->{error},
                        displayError => $displayError,
                    }
                } @$sessions
            ],
        }
    );
}

sub mkOidcConsent {
    my ( $self, $req, $session ) = @_;

    if ( defined( $self->conf->{oidcRPMetaDataOptions} )
        and ref( $self->conf->{oidcRPMetaDataOptions} ) )
    {

        # Set default RP displayname
        foreach my $oidc ( keys %{ $self->conf->{oidcRPMetaDataOptions} } ) {
            $self->conf->{oidcRPMetaDataOptions}->{$oidc}
              ->{oidcRPMetaDataOptionsDisplayName} ||= $oidc;
        }
    }

    # Loading existing oidcConsents
    $self->logger->debug("Searching OIDC Consents...");
    my $_oidcConsents;
    if ( exists $session->{_oidcConsents} ) {
        $_oidcConsents = eval {
            from_json( $session->{_oidcConsents}, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Corrupted session (_oidcConsents): $@");
            return PE_ERROR;
        }
    }
    else {
        $self->logger->debug("No OIDC Consent found");
    }
    my $consents = {};
    foreach (@$_oidcConsents) {
        if ( defined $_->{rp} ) {
            my $rp = $_->{rp};
            $self->logger->debug("RP { $rp } Consent found");
            $consents->{$rp}->{epoch} = $_->{epoch};
            $consents->{$rp}->{scope} = $_->{scope};
            $consents->{$rp}->{displayName} =
              $self->conf->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsDisplayName};
        }
    }

    # Display existing oidcConsents
    return $self->loadTemplate(
        $req,
        'oidcConsents',
        params => {
            partners => [
                map { {
                        name        => $_,
                        epoch       => $consents->{$_}->{epoch},
                        scope       => $consents->{$_}->{scope},
                        displayName => $consents->{$_}->{displayName}
                    }
                } ( sort keys %$consents )
            ],
            consents => join( ",", keys %$consents ),
        }
    );
}

1;
