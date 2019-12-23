package Lemonldap::NG::Manager::Conf::Tests;

use utf8;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Handler::Main;

our $VERSION = '2.0.7';

## @method hashref tests(hashref conf)
# Return a hash ref where keys are the names of the tests and values
# subroutines to execute.
#
# Subroutines can return one of the followings :
# -  (1)         : everything is OK
# -  (1,message) : OK with a warning
# -  (0,message) : NOK
# - (-1,message) : OK, but must be confirmed (ignored if confirm parameter is
# set
#
# Those subroutines can also modify configuration.
#
# @param $conf Configuration to test
# @return hash ref where keys are the names of the tests and values
sub tests {
    my $conf = shift;
    return {

        # 1. CHECKS

        # Check if portal is in domain
        portalIsInDomain => sub {
            return (
                1,
                (
                    index( $conf->{portal}, $conf->{domain} ) > 0
                    ? ''
                    : "Portal seems not to be in the domain $conf->{domain}"
                )
            );
        },

        # Check if portal URL is well formated
        portalURL => sub {

            # Checking for ending slash
            $conf->{portal} .= '/'
              unless ( $conf->{portal} =~ qr#/$# );

            # Deleting trailing ending slash
            my $regex = qr#/+$#;
            $conf->{portal} =~ s/$regex/\//;

            return 1;
        },

        # Check if virtual hosts are in the domain
        vhostInDomainOrCDA => sub {
            return 1 if ( $conf->{cda} );
            my @pb;
            foreach my $vh ( keys %{ $conf->{locationRules} } ) {
                push @pb, $vh unless ( index( $vh, $conf->{domain} ) >= 0 );
            }
            return (
                1,
                (
                    @pb
                    ? 'Virtual hosts '
                      . join( ', ', @pb )
                      . " are not in $conf->{domain} and cross-domain-authentication is not set"
                    : undef
                )
            );
        },

        # Check if virtual host do not contain a port
        vhostWithPort => sub {
            my @pb;
            foreach my $vh ( keys %{ $conf->{locationRules} } ) {
                push @pb, $vh if ( $vh =~ /:/ );
            }
            if (@pb) {
                return ( 0,
                        'Virtual hosts '
                      . join( ', ', @pb )
                      . " contain a port, this is not allowed" );
            }
            else { return 1; }
        },

        # Force vhost to be lowercase
        vhostUpperCase => sub {
            my @pb;
            foreach my $vh ( keys %{ $conf->{locationRules} } ) {
                push @pb, $vh if ( $vh ne lc $vh );
            }
            if (@pb) {
                return ( 0,
                        'Virtual hosts '
                      . join( ', ', @pb )
                      . " must be in lower case" );
            }
            else { return 1; }
        },

        # Check if "userDB" and "authentication" are consistent
        authAndUserDBConsistency => sub {
            foreach
              my $type (qw(Facebook Google OpenID OpenIDConnect SAML WebID))
            {
                return ( 0,
"\"$type\" can not be used as user database without using \"$type\" for authentication"
                  )
                  if (  $conf->{userDB} =~ /$type/
                    and $conf->{authentication} !~ /$type/ );
            }
            return 1;
        },

        # Check that OpenID macros exists
        checkAttrAndMacros => sub {
            my @tmp;
            foreach my $k ( keys %$conf ) {
                if ( $k =~
/^(?:openIdSreg_(?:(?:(?:full|nick)nam|languag|postcod|timezon)e|country|gender|email|dob)|whatToTrace)$/
                  )
                {
                    my $v = $conf->{$k};
                    $v =~ s/^$//;
                    next if ( $v =~ /^_/ );
                    push @tmp,
                      $k
                      unless (
                        defined(
                            $conf->{exportedVars}->{$v}
                              or defined( $conf->{macros}->{$v} )
                        )
                      );
                }
            }
            return (
                1,
                (
                    @tmp
                    ? 'Values of parameter(s) "'
                      . join( ', ', @tmp )
                      . '" are not defined in exported attributes or macros'
                    : ''
                )
            );
        },

        # Test that variables are exported if Google is used as UserDB
        checkUserDBGoogleAXParams => sub {
            my @tmp;
            if ( $conf->{userDB} =~ /^Google$/ ) {
                foreach my $k ( keys %{ $conf->{exportedVars} } ) {
                    my $v = $conf->{exportedVars}->{$k};
                    if ( $v !~ Lemonldap::NG::Common::Regexp::GOOGLEAXATTR() ) {
                        push @tmp, $v;
                    }
                }
            }
            return (
                1,
                (
                    @tmp
                    ? 'Values of parameter(s) "'
                      . join( ', ', @tmp )
                      . '" are not exported by Google'
                    : ''
                )
            );
        },

        # Test that variables are exported if OpenID is used as UserDB
        checkUserDBOpenIDParams => sub {
            my @tmp;
            if ( $conf->{userDB} =~ /^OpenID$/ ) {
                foreach my $k ( keys %{ $conf->{exportedVars} } ) {
                    my $v = $conf->{exportedVars}->{$k};
                    if ( $v !~ Lemonldap::NG::Common::Regexp::OPENIDSREGATTR() )
                    {
                        push @tmp, $v;
                    }
                }
            }
            return (
                1,
                (
                    @tmp
                    ? 'Values of parameter(s) "'
                      . join( ', ', @tmp )
                      . '" are not exported by OpenID SREG'
                    : ''
                )
            );
        },

        # Try to use Apache::Session module
        testApacheSession => sub {
            my ( $id, %h );
            my $gc = Lemonldap::NG::Handler::Main->tsv->{sessionStorageModule};
            return 1
              if ( ( $gc and $gc eq $conf->{globalStorage} )
                or $conf->{globalStorage} =~
                /^Lemonldap::NG::Common::Apache::Session::/ );
            eval "use $conf->{globalStorage}";
            return ( -1, "Unknown package $conf->{globalStorage}" ) if ($@);
            eval {
                tie %h, 'Lemonldap::NG::Common::Apache::Session', undef,
                  {
                    %{ $conf->{globalStorageOptions} },
                    backend => $conf->{globalStorage}
                  };
            };
            return ( -1, "Unable to create a session ($@)" )
              if ( $@ or not tied(%h) );
            eval {
                $h{a} = 1;
                $id = $h{_session_id} or return ( -1, 'No _session_id' );
                untie(%h);
                tie %h, 'Lemonldap::NG::Common::Apache::Session', $id,
                  {
                    %{ $conf->{globalStorageOptions} },
                    backend => $conf->{globalStorage}
                  };
            };
            return ( -1, "Unable to insert data ($@)" ) if ($@);
            return ( -1, "Unable to recover data stored" )
              unless ( $h{a} == 1 );
            eval { tied(%h)->delete; };
            return ( -1, "Unable to delete session ($@)" ) if ($@);
            return ( -1,
'All sessions may be lost and you must restart all your Apache servers'
            ) if ( $gc and $conf->{globalStorage} ne $gc );
            return 1;
        },

        # Warn if cookie name has changed
        cookieNameChanged => sub {
            my $cn = Lemonldap::NG::Handler::Main->tsv->{cookieName};
            return (
                1,
                (
                    $cn
                      and $cn ne $conf->{cookieName}
                    ? 'Cookie name has changed, you must restart all your web servers'
                    : ()
                )
            );
        },

        # Warn if cookie TTL is equal or lower than one hour
        cookieTTL => sub {
            return 1 unless ( defined $conf->{cookieExpiration} );
            return ( 0, "Cookie TTL must be higher than one minute" )
              unless ( $conf->{cookieExpiration} == 0
                || $conf->{cookieExpiration} > 60 );
            return ( 1, "Cookie TTL should be higher or equal than one hour" )
              unless ( $conf->{cookieExpiration} >= 3600
                || $conf->{cookieExpiration} == 0 );

            # Return
            return 1;
        },

        # Warn if session timeout is lower than 10 minutes
        sessionTimeout => sub {
            return 1 unless ( defined $conf->{timeout} );
            return ( -1, "Session timeout should be higher than ten minutes" )
              unless ( $conf->{timeout} > 600
                || $conf->{timeout} == 0 );

            # Return
            return 1;
        },

        # Error if session Activity Timeout is equal or lower than one minute
        sessionTimeoutActivity => sub {
            return 1 unless ( defined $conf->{timeoutActivity} );
            return ( 0,
"Session activity timeout must be higher or equal than one minute"
              )
              unless ( $conf->{timeoutActivity} > 59
                || $conf->{timeoutActivity} == 0 );

            # Return
            return 1;
        },

    # Error if activity timeout interval is higher than session activity timeout
        timeoutActivityInterval => sub {
            return 1 unless ( defined $conf->{timeoutActivityInterval} );
            return ( 0,
"Activity timeout interval must be lower than session activity timeout"
              )
              if (  $conf->{timeoutActivity}
                and $conf->{timeoutActivity} <=
                $conf->{timeoutActivityInterval} );

            # Return
            return 1;
        },

        # Warn if manager seems to be unprotected
        managerProtection => sub {
            return (
                1,
                (
                    $conf->{cfgAuthor} eq 'anonymous'
                    ? 'Your manager seems to be unprotected'
                    : ''
                )
            );
        },

        # Test SMTP connection and authentication (warning only)
        smtpConnectionAuthentication => sub {

            # Skip test if no SMTP configuration
            return 1 unless ( $conf->{SMTPServer} );

            # Use SMTP
            eval "use Net::SMTP";
            return ( 1, "Net::SMTP module is required to use SMTP server" )
              if ($@);

            # Create SMTP object
            my $smtp = Net::SMTP->new(
                $conf->{SMTPServer},
                Timeout => 5,
                ( $conf->{SMTPPort} ? ( Port => $conf->{SMTPPort} ) : () ),
            );
            return ( 1,
                "SMTP connection to " . $conf->{SMTPServer} . " failed" )
              unless ($smtp);

            # Skip other tests if no authentication
            return 1
              unless ( $conf->{SMTPAuthUser} and $conf->{SMTPAuthPass} );

            # Try authentication
            return ( 1, "SMTP authentication failed" )
              unless $smtp->auth( $conf->{SMTPAuthUser},
                $conf->{SMTPAuthPass} );

            # Return
            return 1;
        },

        # SAML entity ID must be uniq
        samlIDPEntityIdUniqueness => sub {
            return 1
              unless ( $conf->{samlIDPMetaDataXML}
                and %{ $conf->{samlIDPMetaDataXML} } );
            my @msg;
            my $res = 1;
            my %entityIds;
            foreach my $idpId ( keys %{ $conf->{samlIDPMetaDataXML} } ) {
                unless (
                    $conf->{samlIDPMetaDataXML}->{$idpId}->{samlIDPMetaDataXML}
                    =~ /entityID=(['"])(.+?)\1/si )
                {
                    push @msg, "$idpId SAML metadata has no EntityID";
                    $res = 0;
                    next;
                }
                my $eid = $2;
                if ( defined $entityIds{$eid} ) {
                    push @msg,
                      "$idpId and $entityIds{$eid} have the same SAML EntityID";
                    $res = 0;
                    next;
                }
                $entityIds{$eid} = $idpId;
            }
            return ( $res, join( ', ', @msg ) );
        },
        samlSPEntityIdUniqueness => sub {
            return 1
              unless ( $conf->{samlSPMetaDataXML}
                and %{ $conf->{samlSPMetaDataXML} } );
            my @msg;
            my $res = 1;
            my %entityIds;
            foreach my $spId ( keys %{ $conf->{samlSPMetaDataXML} } ) {
                unless (
                    $conf->{samlSPMetaDataXML}->{$spId}->{samlSPMetaDataXML} =~
                    /entityID=(['"])(.+?)\1/si )
                {
                    push @msg, "$spId SAML metadata has no EntityID";
                    $res = 0;
                    next;
                }
                my $eid = $2;
                if ( defined $entityIds{$eid} ) {
                    push @msg,
                      "$spId and $entityIds{$eid} have the same SAML EntityID";
                    $res = 0;
                    next;
                }
                $entityIds{$eid} = $spId;
            }
            return ( $res, join( ', ', @msg ) );
        },

        # Test if SAML private and public keys signature keys are set
        samlSecretKeys => sub {
            return 1 unless ( $conf->{issuerDBSAMLActivation} );
            return ( 0,
                'SAML service private and public keys signature must be set' )
              unless ( $conf->{samlServicePrivateKeySig}
                && $conf->{samlServicePublicKeySig} );
            return 1;
        },

        # Try to parse combination with declared modules
        checkCombinations => sub {
            return 1 unless ( $conf->{authentication} eq 'Combination' );
            require Lemonldap::NG::Common::Combination::Parser;
            return ( 0, 'No module declared for combination' )
              unless ( $conf->{combModules} and %{ $conf->{combModules} } );
            my $moduleList;
            foreach my $md ( keys %{ $conf->{combModules} } ) {
                my $entry = $conf->{combModules}->{$md};
                $moduleList->{$md} = (
                      $entry->{for} == 2 ? [ undef, {} ]
                    : $entry->{for} == 1 ? [ {}, undef ]
                    :                      [ {}, {} ]
                );
            }
            eval {
                Lemonldap::NG::Common::Combination::Parser->parse( $moduleList,
                    $conf->{combination} );
            };
            return ( 0, $@ ) if ($@);

            # Return
            return 1;
        },

        # Check Combination parameters
        combinationParameters => sub {
            return 1 unless ( $conf->{authentication} eq "Combination" );
            return ( 0, "Combination rule must be defined" )
              unless ( $conf->{combination} );
            return ( 0, 'userDB must be set to "Same" to enable Combination' )
              unless ( $conf->{userDB} eq "Same" );

            # Return
            return 1;
        },

        # Warn if 2F dependencies seem missing
        sfaDependencies => sub {
            my $ok = 0;
            foreach (qw(u totp utotp yubikey)) {
                $ok ||= $conf->{ $_ . '2fActivation' };
                last if ($ok);
            }
            return 1 unless ($ok);

            # Use TOTP
            if (   $conf->{totp2fActivation}
                or $conf->{utotp2fActivation} )
            {
                eval "use Convert::Base32";
                return ( 1,
                    "Convert::Base32 module is required to enable TOTP" )
                  if ($@);
            }

            # Use U2F
            if (   $conf->{u2fActivation}
                or $conf->{utotp2fActivation} )
            {
                eval "use Crypt::U2F::Server::Simple";
                return ( 1,
"Crypt::U2F::Server::Simple module is required to enable U2F"
                ) if ($@);
            }

            # Use Yubikey
            if ( $conf->{yubikey2fActivation} ) {
                eval "use Auth::Yubikey_WebClient";
                return ( 1,
"Auth::Yubikey_WebClient module is required to enable Yubikey"
                ) if ($@);
            }

            # Return
            return 1;
        },

        # Warn if TOTP or U2F is enabled with UTOTP (U2F + TOTP)
        utotp => sub {
            return 1 unless ( $conf->{utotp2fActivation} );
            my $w = "";
            foreach ( 'totp', 'u' ) {
                $w .= uc($_) . "2F is activated twice \n"
                  if ( $conf->{ $_ . '2fActivation' } eq '1' );
            }
            return ( 1, ( $w ? $w : () ) );
        },

        # Warn if TOTP not 6 or 8 digits long
        totp2fDigits => sub {
            return 1 unless ( $conf->{totp2fActivation} );
            return 1 unless ( defined $conf->{totp2fDigits} );
            return (
                1,
                ( (
                             $conf->{totp2fDigits} == 6
                          or $conf->{totp2fDigits} == 8
                    )
                    ? ''
                    : 'TOTP should be 6 or 8 digits long'
                )
            );
        },

        # Test TOTP params
        totp2fParams => sub {
            return 1 unless ( $conf->{totp2fActivation} );
            return ( 0, 'TOTP range must be defined' )
              unless ( $conf->{totp2fRange} );
            return ( 1, "TOTP interval should be higher than 10s" )
              unless ( $conf->{totp2fInterval} > 10 );

            # Return
            return 1;
        },

        # Error if Yubikey client ID and secret key are missing
        # Warn if Yubikey public ID size is not 12 digits long
        yubikey2fParams => sub {
            return 1 unless ( $conf->{yubikey2fActivation} );
            return ( 0, "Yubikey client ID and secret key must be set" )
              unless ( defined $conf->{yubikey2fSecretKey}
                && defined $conf->{yubikey2fClientID} );
            return (
                1,
                (
                    ( $conf->{yubikey2fPublicIDSize} == 12 )
                    ? ''
                    : 'Yubikey public ID size should be 12 digits long'
                )
            );
        },

        # Error if REST 2F verify URL is missing
        rest2fVerifyUrl => sub {
            return 1 unless ( $conf->{rest2fActivation} );
            return ( 0, "REST 2F Verify URL must be set" )
              unless ( defined $conf->{rest2fVerifyUrl} );

            # Return
            return 1;
        },

        # Warn if 2FA is required without a registrable 2F module enabled
        required2FA => sub {
            return 1 unless ( $conf->{sfRequired} );

            my $msg = '';
            my $ok  = 0;
            foreach (qw(u totp yubikey)) {
                $ok ||= $conf->{ $_ . '2fActivation' }
                  && $conf->{ $_ . '2fSelfRegistration' };
                last if ($ok);
            }

            $ok ||= $conf->{'utotp2fActivation'}
              && ( $conf->{'u2fSelfRegistration'}
                || $conf->{'totp2fSelfRegistration'} );
            $msg = "A self registrable module should be enabled to require 2FA"
              unless ($ok);

            return ( 1, $msg );
        },

        # Error if external 2F Send or Validate command is missing
        ext2fCommands => sub {
            return 1 unless ( $conf->{ext2fActivation} );
            return ( 0, "External 2F Send command must be set" )
              unless ( defined $conf->{ext2FSendCommand} );
            unless ( defined $conf->{ext2fCodeActivation} ) {
                return ( 0, "External 2F Validate command must be set" )
                  unless ( defined $conf->{ext2FValidateCommand} );
            }

            # Return
            return 1;
        },

        # Warn if XSRF token TTL is higher than 30s
        formTimeout => sub {
            return 1 unless ( defined $conf->{formTimeout} );
            return ( 0, "XSRF form token TTL must be higher than 30s" )
              unless ( $conf->{formTimeout} > 30 );
            return ( 1, "XSRF form token TTL should not be higher than 2mn" )
              if ( $conf->{formTimeout} > 120 );

            # Return
            return 1;
        },

        # Warn if issuers token TTL is higher than 30s
        issuersTimeout => sub {
            return 1 unless ( defined $conf->{issuerTimeout} );
            return ( 0, "Issuers token TTL must be higher than 30s" )
              unless ( $conf->{issuerTimeout} > 30 );
            return ( 1, "Issuers token TTL should not be higher than 2mn" )
              if ( $conf->{issuerTimeout} > 120 );

            # Return
            return 1;
        },

        # Warn if number of password reset retries is null
        passwordResetRetries => sub {
            return 1 unless ( $conf->{portalDisplayResetPassword} );
            return ( 1, "Number of reset password retries should not be null" )
              unless ( $conf->{passwordResetAllowedRetries} );

            # Return
            return 1;
        },

        # Warn if ldapPpolicyControl is used with AD (#2007)

        ppolicyAd => sub {
            if (    $conf->{ldapPpolicyControl}
                and $conf->{authentication} eq "AD" )
            {
                return ( 1,
"LDAP password policy control should be disabled when using AD authentication"
                );
            }
            return 1;
        },

        # Warn if bruteForceProtection enabled without History
        bruteForceProtection => sub {
            return 1 unless ( $conf->{bruteForceProtection} );
            return ( 1,
'"History" plugin is required to enable "BruteForceProtection" plugin'
            ) unless ( $conf->{loginHistoryEnabled} );
            return ( 1,
'Number of failed logins must be higher than 2 to enable "BruteForceProtection" plugin'
            ) unless ( $conf->{failedLoginNumber} > 2 );

            # Return
            return 1;
        },

        # Warn if Mailrest plugin is enabled without Token or Captcha
        checkMailResetSecurity => sub {
            return 1 unless ( $conf->{portalDisplayResetPassword} );
            return ( -1,
'"passwordMailReset" plugin is enabled without CSRF Token neither Captcha required'
              )
              unless ( $conf->{requireToken}
                or $conf->{captcha_mail_enabled} );

            # Return
            return 1;
        },

        # Warn if Impersonation and ContextSwitching are simultaneously enabled
        impersonation => sub {
            return ( 1,
                "Impersonation and ContextSwitching are simultaneously enabled"
              )
              if ( $conf->{impersonationRule}
                && $conf->{contextSwitchingRule} );

            # Return
            return 1;
        },

# Warn if persistent storage is disabled with 2FA, History, OIDCConsents, Notifications or BruteForce protection
        persistentStorage => sub {
            return 1 unless ( $conf->{disablePersistentStorage} );
            return ( 1, "2FA enabled WITHOUT persistent session storage" )
              if ( $conf->{totp2fActivation}
                || $conf->{yubikey2fActivation}
                || $conf->{u2fActivation}
                || $conf->{utotp2fActivation} );
            return ( 1, "History enabled WITHOUT persistent session storage" )
              if ( $conf->{loginHistoryEnabled} );
            return ( 1,
                "OIDC consents enabled WITHOUT persistent session storage" )
              if ( $conf->{portalDisplayOidcConsents} );
            return ( 1,
                "Notifications enabled WITHOUT persistent session storage" )
              if ( $conf->{notification} );
            return ( 1,
"BruteForceProtection plugin enabled WITHOUT persistent session storage"
            ) if ( $conf->{bruteForceProtection} );

            # Return
            return 1;
        },

        # Warn if XML dependencies seem missing
        xmlDependencies => sub {
            return 1 unless ( $conf->{oldNotifFormat} );
            eval "use XML::LibXML";
            return ( 1,
"XML::LibXML module is required to enable old format notifications"
            ) if ($@);
            eval "use XML::LibXSLT";
            return ( 1,
"XML::LibXSLT module is required to enable old format notifications"
            ) if ($@);

            # Return
            return 1;
        },

        # OIDC redirect URI must not be empty
        oidcRPRedirectURINotEmpty => sub {
            return 1
              unless ( $conf->{oidcRPMetaDataOptions}
                and %{ $conf->{oidcRPMetaDataOptions} } );
            my @msg;
            my $res = 1;
            foreach my $oidcRpId ( keys %{ $conf->{oidcRPMetaDataOptions} } ) {
                unless ( $conf->{oidcRPMetaDataOptions}->{$oidcRpId}
                    ->{oidcRPMetaDataOptionsRedirectUris} )
                {
                    push @msg,
                      "$oidcRpId OpenID Connect RP has no redirect URI defined";
                    $res = 0;
                    next;
                }
            }
            return ( $res, join( ', ', @msg ) );
        },

    };
}

1;
