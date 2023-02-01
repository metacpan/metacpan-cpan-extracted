package Lemonldap::NG::Manager::Conf::Tests;

use strict;
use utf8;
use strict;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Handler::Main;
use Lemonldap::NG::Common::Util qw(getSameSite);
use URI;

our $VERSION = '2.0.15';

## @method hashref tests(hashref conf)
# Return a hash ref where keys are the names of the tests and values
# subroutines to execute.
#
# Subroutines can return one of the followings :
# -  (1)         : everything is OK
# -  (1,message) : OK with a warning
# -  (0,message) : NOK
# - (-1,message) : OK, but must be confirmed (ignored if confirm parameter is
# set)
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
            my $url = $conf->{portal};

            # Append or remove trailing slashes
            $conf->{portal} =~ s%/*$%/%;
            return (
                1,
                (
                    ( $url =~ m%/$% )
                    ? ''
                    : "Portal URL should end with a /"
                )
            );
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
'All sessions may be lost and you must restart all your web servers'
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
            return 1;
        },

        # Warn if session timeout is lower than 10 minutes
        sessionTimeout => sub {
            return 1 unless ( defined $conf->{timeout} );
            return ( -1, "Session timeout should be higher than ten minutes" )
              unless ( $conf->{timeout} > 600
                || $conf->{timeout} == 0 );
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

        # Test support of timeouts for LDAPS connections
        ldapsNoTimeout => sub {

            # Skip test if no SMTP configuration
            return (1) unless ( $conf->{ldapServer} );

            if ( $conf->{ldapServer} =~ /ldaps:/ ) {

                if ( eval "require IO::Socket::SSL; require IO::Socket::IP;" ) {
                    if ( IO::Socket::SSL->isa('IO::Socket::IP') ) {
                        unless ( eval { IO::Socket::IP->VERSION(0.31) } ) {
                            return ( 1,
"Your version of IO::Socket::IP is too old to enforce "
                                  . "connection timeouts on ldaps:// URLs. Use ldap+tls:// instead"
                            );
                        }
                    }
                }
            }
            return (1);
        },

        # Test SMTP connection and authentication (warning only)
        smtpConfiguration => sub {

            # Skip test if no SMTP configuration
            return 1 unless ( $conf->{SMTPServer} );

            # Use SMTP
            eval "use Lemonldap::NG::Common::EmailTransport";
            return ( 1, "Could not load Lemonldap::NG::Common::EmailTransport" )
              if ($@);

            return Lemonldap::NG::Common::EmailTransport->configTest($conf);
        },

        # SAML entity ID must be unique
        samlIDPEntityIdUniqueness => sub {
            return 1
              unless ( $conf->{samlIDPMetaDataXML}
                and %{ $conf->{samlIDPMetaDataXML} } );
            my @msg;
            my $res = 1;
            my %entityIds;
            foreach my $idpId ( keys %{ $conf->{samlIDPMetaDataXML} } ) {
                if (
                    $conf->{samlIDPMetaDataXML}->{$idpId}->{samlIDPMetaDataXML}
                    =~ /entityID=(['"])(.+?)\1/si )
                {
                    my $eid = $2;
                    if ( defined $entityIds{$eid} ) {
                        push @msg,
"$idpId and $entityIds{$eid} have the same SAML EntityID";
                        $res = 0;
                        next;
                    }
                    $entityIds{$eid} = $idpId;
                }
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
                if (
                    $conf->{samlSPMetaDataXML}->{$spId}->{samlSPMetaDataXML} =~
                    /entityID=(['"])(.+?)\1/si )
                {
                    my $eid = $2;
                    if ( defined $entityIds{$eid} ) {
                        push @msg,
"$spId and $entityIds{$eid} have the same SAML EntityID";
                        $res = 0;
                        next;
                    }
                    $entityIds{$eid} = $spId;
                }
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

        samlSignatureOverrideNeedsCertificate => sub {
            return 1
              if $conf->{samlServicePublicKeySig}
              && $conf->{samlServicePublicKeySig} =~ /CERTIFICATE/;

            my @offenders;
            for my $idp ( keys %{ $conf->{samlIDPMetaDataOptions} } ) {
                if ( $conf->{samlIDPMetaDataOptions}->{$idp}
                    ->{samlIDPMetaDataOptionsSignatureMethod} )
                {
                    push @offenders, $idp;
                }
            }
            for my $sp ( keys %{ $conf->{samlSPMetaDataOptions} } ) {
                if ( $conf->{samlSPMetaDataOptions}->{$sp}
                    ->{samlSPMetaDataOptionsSignatureMethod} )
                {
                    push @offenders, $sp;
                }
            }
            return @offenders
              ? (
                0,
                "Cannot set non-default signature method on "
                  . join( ", ", @offenders )
                  . " unless SAML signature key is in certificate form"
              )
              : 1;
        },

        samlSignatureUnsupportedAlg => sub {
            return 1 unless $conf->{issuerDBSAMLActivation};
            return 1
              unless eval
'use Lasso; Lasso::check_version( 2, 5, 1, Lasso::Constants::CHECK_VERSION_NUMERIC) ? 0 : 1';

            my $allsha1 = 1;
            undef $allsha1
              unless $conf->{samlServiceSignatureMethod} eq "RSA_SHA1";

            for my $idp ( keys %{ $conf->{samlIDPMetaDataOptions} } ) {
                if ( $conf->{samlIDPMetaDataOptions}->{$idp}
                    ->{samlIDPMetaDataOptionsSignatureMethod} )
                {
                    if ( $conf->{samlIDPMetaDataOptions}->{$idp}
                        ->{samlIDPMetaDataOptionsSignatureMethod} ne
                        "RSA_SHA1" )
                    {
                        undef $allsha1;
                        last;
                    }
                }
            }
            for my $sp ( keys %{ $conf->{samlSPMetaDataOptions} } ) {
                if ( $conf->{samlSPMetaDataOptions}->{$sp}
                    ->{samlSPMetaDataOptionsSignatureMethod} )
                {
                    if ( $conf->{samlSPMetaDataOptions}->{$sp}
                        ->{samlSPMetaDataOptionsSignatureMethod} ne "RSA_SHA1" )
                    {
                        undef $allsha1;
                        last;
                    }
                }
            }
            return $allsha1
              ? 1
              : (
                0,
                "Algorithms other than SHA1 are only supported on Lasso>=2.5.1"
              );
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

            # Use WebAuthn
            if ( $conf->{webauthn2fActivation} ) {
                eval "use Authen::WebAuthn";
                return ( 1,
                    "Authen::WebAuthn module is required to enable WebAuthn" )
                  if ($@);
            }

            # WebAuthn requires https://
            if ( $conf->{webauthn2fActivation} ) {
                my $portal_uri = URI->new( $conf->{portal} );
                unless ( $portal_uri->scheme eq "https" ) {
                    return ( 1, "WebAuthn requires HTTPS" );
                }
            }

            # Use Yubikey
            if ( $conf->{yubikey2fActivation} ) {
                eval "use Auth::Yubikey_WebClient";
                return ( 1,
"Auth::Yubikey_WebClient module is required to enable Yubikey"
                ) if ($@);
            }
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
            foreach (qw(u totp yubikey webauthn)) {
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
            return 1;
        },

        # Warn if XSRF token TTL is higher than 30s
        formTimeout => sub {
            return 1 unless ( defined $conf->{formTimeout} );
            return ( 0, "XSRF form token TTL must be higher than 30s" )
              unless ( $conf->{formTimeout} > 30 );
            return ( 1, "XSRF form token TTL should not be higher than 2mn" )
              if ( $conf->{formTimeout} > 120 );
            return 1;
        },

        # Warn if issuers token TTL is higher than 30s
        issuersTimeout => sub {
            return 1 unless ( defined $conf->{issuersTimeout} );
            return ( 0, "Issuers token TTL must be higher than 30s" )
              unless ( $conf->{issuersTimeout} > 30 );

            # because of issue #2186
            return ( 1, "Issuers token TTL should not be higher than 10mn" )
              if ( $conf->{issuersTimeout} > 600 );
            return 1;
        },

        # Warn if number of password reset retries is null
        passwordResetRetries => sub {
            return 1 unless ( $conf->{portalDisplayResetPassword} );
            return ( 1, "Number of reset password retries should not be null" )
              unless ( $conf->{passwordResetAllowedRetries} );
            return 1;
        },

        # Warn if ldapPpolicyControl is used with AD (#2007)
        ppolicyAd => sub {
            return ( 1,
"LDAP password policy control should be disabled when using AD authentication"
              )
              if (  $conf->{ldapPpolicyControl}
                and $conf->{authentication} eq "AD" );
            return 1;
        },

        # Warn if bruteForceProtection enabled without History
        bruteForceProtection => sub {
            my @lockTimes =
              sort { $a <=> $b }
              map {
                $_ =~ s/\D//;
                abs $_;
              }
              grep { /\d+/ }
              split /\s*,\s*/, $conf->{bruteForceProtectionLockTimes} || '';
            $conf->{bruteForceProtectionLockTimes} = join ', ', @lockTimes
              if scalar @lockTimes;
            return 1 unless ( $conf->{bruteForceProtection} );
            return ( 0,
'"History" plugin is required to enable "BruteForceProtection" plugin'
            ) unless ( $conf->{loginHistoryEnabled} );
            return ( 0,
'Number of failed logins must be higher than 1 to enable "BruteForceProtection" plugin'
            ) unless ( $conf->{failedLoginNumber} > 1 );
            return ( 0,
'Number of allowed failed logins must be higher than 0 to enable "BruteForceProtection" plugin'
            ) unless ( $conf->{bruteForceProtectionMaxFailed} > 0 );
            return ( 0,
'Number of failed logins history must be higher or equal than allowed failed logins plus lock time values'
              )
              if ( $conf->{bruteForceProtectionIncrementalTempo}
                && $conf->{failedLoginNumber} <
                $conf->{bruteForceProtectionMaxFailed} + scalar @lockTimes );
            return ( 0,
'Number of failed logins history must be higher or equal than allowed failed logins'
              )
              unless ( $conf->{failedLoginNumber} >=
                $conf->{bruteForceProtectionMaxFailed} );
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
            return 1;
        },

        # Warn if Impersonation and ContextSwitching are simultaneously enabled
        impersonation => sub {
            return ( 1,
                "Impersonation and ContextSwitching are simultaneously enabled"
              )
              if (  $conf->{impersonationRule}
                and $conf->{contextSwitchingRule} );
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
            return ( 1,
                "History plugin enabled WITHOUT persistent session storage" )
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
            return 1;
        },

        # Warn if CertificateResetByMail dependencies seem missing
        certResetByMailDependencies => sub {
            return 1 unless ( $conf->{portalDisplayCertificateResetByMail} );
            return ( 0,
"LDAP RegisterDB is required to enable CertificateResetByMail plugin"
            ) unless ( $conf->{registerDB} eq 'LDAP' );
            eval "use DateTime::Format::RFC3339";
            return ( 1,
"DateTime::Format::RFC3339 module is required to enable CertificateResetByMail plugin"
            ) if ($@);
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

        # RS* OIDC algs require a signing key
        oidcRPNeedRSAKey => sub {
            return 1
              unless ( $conf->{oidcRPMetaDataOptions}
                and %{ $conf->{oidcRPMetaDataOptions} } );
            my @usingRSA =
              grep {
                $conf->{oidcRPMetaDataOptions}->{$_}
                  ->{oidcRPMetaDataOptionsIDTokenSignAlg}
                  and $conf->{oidcRPMetaDataOptions}->{$_}
                  ->{oidcRPMetaDataOptionsIDTokenSignAlg} =~ /^RS/
              } keys %{ $conf->{oidcRPMetaDataOptions} }, grep {
                $conf->{oidcRPMetaDataOptions}->{$_}
                  ->{oidcRPMetaDataOptionsAccessTokenSignAlg}
                  and $conf->{oidcRPMetaDataOptions}->{$_}
                  ->{oidcRPMetaDataOptionsAccessTokenSignAlg} =~ /^RS/
                  and $conf->{oidcRPMetaDataOptions}->{$_}
                  ->{oidcRPMetaDataOptionsAccessTokenJWT}
              } keys %{ $conf->{oidcRPMetaDataOptions} };

            if ( @usingRSA and not $conf->{oidcServicePrivateKeySig} ) {
                my $msg =
                  join( ", ", @usingRSA )
                  . ": using RS-type encryption, but no RSA key is defined in global OIDC configuration";
                return ( 0, $msg );
            }
            return 1;
        },

        # Public OIDC clients require a public key algorithm
        oidcRPPublicNeedPubAlg => sub {
            return 1
              unless ( $conf->{oidcRPMetaDataOptions}
                and %{ $conf->{oidcRPMetaDataOptions} || {} } );
            my @clients;
            for ( keys %{ $conf->{oidcRPMetaDataOptions} || {} } ) {
                if ( $conf->{oidcRPMetaDataOptions}->{$_}
                    ->{oidcRPMetaDataOptionsPublic}
                    and $conf->{oidcRPMetaDataOptions}->{$_}
                    ->{oidcRPMetaDataOptionsIDTokenSignAlg} =~ /^HS/ )
                {
                    push @clients, $_;
                }
            }
            if (@clients) {
                my $msg =
                    join( ", ", @clients )
                  . ": public clients should use a public key algorithm"
                  . " for ID token signature";
                return 1, $msg;
            }
            else {
                return 1;
            }
        },

        # OIDC RP Client ID must exist and be unique
        oidcRPClientIdUniqueness => sub {
            return 1
              unless ( $conf->{oidcRPMetaDataOptions}
                and %{ $conf->{oidcRPMetaDataOptions} } );
            my @msg;
            my $res = 1;
            my %clientIds;
            foreach
              my $clientConfKey ( keys %{ $conf->{oidcRPMetaDataOptions} } )
            {
                my $clientId =
                  $conf->{oidcRPMetaDataOptions}->{$clientConfKey}
                  ->{oidcRPMetaDataOptionsClientID};
                unless ($clientId) {
                    push @msg,
                      "$clientConfKey OIDC Relying Party has no Client ID";
                    $res = 0;
                    next;
                }

                if ( defined $clientIds{$clientId} ) {
                    push @msg,
"$clientConfKey and $clientIds{$clientId} have the same Client ID";
                    $res = 0;
                    next;
                }
                $clientIds{$clientId} = $clientConfKey;
            }
            return ( $res, join( ', ', @msg ) );
        },

        # CAS APP URL must be defined and unique
        casAppHostnameUniqueness => sub {
            return 1
              unless ( $conf->{casAppMetaDataOptions}
                and %{ $conf->{casAppMetaDataOptions} } );
            my @msg;
            my $res = 1;
            my %casUrl;
            foreach my $casConfKey ( keys %{ $conf->{casAppMetaDataOptions} } )
            {
                for my $appUrl (
                    split(
                        /\s+/,
                        $conf->{casAppMetaDataOptions}->{$casConfKey}
                          ->{casAppMetaDataOptionsService}
                    )
                  )
                {
                    $appUrl ||= "";
                    $appUrl =~ m#^(https?://[^/]+)(/.*)?$#;
                    my $appHost = $1;
                    unless ($appHost) {
                        push @msg,
                          "$casConfKey CAS Application has no Service URL";
                        $res = 0;
                        next;
                    }

                    if ( defined $casUrl{$appUrl} ) {
                        push @msg,
"$casConfKey and $casUrl{$appUrl} have the same Service URL";
                        $res = 0;
                        next;
                    }
                    $casUrl{$appUrl} = $casConfKey;
                }
            }
            return ( $res, join( ', ', @msg ) );
        },

        # Notification system required with removed SF notification
        sfRemovedNotification => sub {
            return 1 unless ( $conf->{sfRemovedMsgRule} );
            return ( 1,
'Notification system must be enabled to display a notification if a SF is removed'
              )
              if ( $conf->{sfRemovedUseNotif}
                and not $conf->{notification} );
            return 1;
        },

        # noAjaxHook and krbByJs are incompatible (#2237)
        noAjaxHookwithKrb => sub {
            return ( 1,
                    'noAjaxHook is not compatible with'
                  . ' AJAX Kerberos authentication' )
              if ( $conf->{noAjaxHook} and $conf->{krbByJs} );
            return 1;
        },

        # Cookie SameSite=None requires Secure flag
        # Same with SameSite=(auto) and SAML issuer in use
        SameSiteNoneWithSecure => sub {
            return ( -1, 'SameSite value = None requires the secured flag' )
              if ( getSameSite($conf) eq 'None'
                and !$conf->{securedCookie} );
            return 1;
        },

        # Secure cookies require HTTPS
        SecureCookiesRequireHttps => sub {
            return ( -1, 'Secure cookies require a HTTPS portal URL' )
              if (  $conf->{securedCookie} == 1
                and $conf->{portal}
                and $conf->{portal} !~ /^https:/ );
            return 1;
        },

        # Password module requires a password backend
        passwordModuleNeedsBackend => sub {
            return ( -1, 'Password module is enabled without password backend' )
              if (  $conf->{portalDisplayChangePassword}
                and $conf->{passwordDB} eq 'Null' );
            if (    $conf->{portalDisplayChangePassword}
                and $conf->{passwordDB} eq 'Choice'
                and $conf->{authChoiceModules} )
            {
                my $hasPwdBE = 0;
                foreach ( keys %{ $conf->{authChoiceModules} } ) {
                    my @mods = split /[;\|]/, $conf->{authChoiceModules}->{$_};
                    $hasPwdBE ||= 1 unless $mods[2] eq 'Null';
                }
                return ( -1,
'Password module is enabled without AuthChoice password backend'
                ) unless $hasPwdBE;
            }
            return 1;
        },

        # FindUser requires Impersonation and attributes
        findUserWithoutImpersonationOrAttributes => sub {
            return ( -1,
                '"Impersonation" plugin is required to enable "FindUser" plugin'
              )
              if ( $conf->{findUser}
                and !$conf->{impersonationRule} );
            return ( 1,
                '"FindUser" plugin enabled without searching attributes' )
              if ( $conf->{findUser}
                and scalar
                keys %{ $conf->{findUserSearchingAttributes} } == 0 );
            return 1;
        },

        # FindUser wildcard must be allowed
        findUserWildcard => sub {
            return 1
              unless ( $conf->{findUser}
                and $conf->{findUserWildcard}
                and $conf->{findUserControl} );
            return ( 1,
                'FindUser wildcard should be allowed by parameters control' )
              unless (
                $conf->{findUserWildcard} =~ /$conf->{findUserControl}/o );
            return 1;
        },

        # AuthChoice parameters must exist
        AuthChoiceParams => sub {
            return 1
              unless ( $conf->{authChoiceModules}
                and %{ $conf->{authChoiceModules} }
                and $conf->{authentication} eq 'Choice' );
            foreach (qw(AuthBasic FindUser)) {
                if ( $conf->{"authChoice$_"} ) {
                    my $test  = $conf->{"authChoice$_"};
                    my $param = grep /^$test$/,
                      keys %{ $conf->{authChoiceModules} };
                    return ( -1, "Choice $_ parameter does not exist" )
                      unless $param;
                }
            }
            return 1;
        },

        # FindUser authChoice parameter must be defined
        findUserChoiceParam => sub {
            return ( -1, 'FindUser choice parameter must be defined' )
              if (  $conf->{findUser}
                and $conf->{impersonationRule}
                and $conf->{authentication} eq 'Choice'
                and !$conf->{authChoiceFindUser} );
            return 1;
        },

        # Chain must be defined with AuthChoice
        authChoiceChains => sub {
            return ( -1, 'Authentication choice enabled without chain' )
              if ( $conf->{authentication} eq 'Choice'
                and scalar keys %{ $conf->{authChoiceModules} } == 0 );
            return 1;
        },

        # Internal portal URL must be defined with Proxy authentication
        authProxy => sub {
            return ( 0,
                'Proxy authentication enabled without internal portal URL' )
              if ( $conf->{authentication} eq 'Proxy'
                and !$conf->{proxyAuthService} );
            return 1;
        },

# Warn if Impersonation and proxyAuthServiceImpersonation are simultaneously enabled
        impersonationProxy => sub {
            return ( -1,
'Impersonation and internal portal Impersonation are simultaneously enabled'
              )
              if (  $conf->{impersonationRule}
                and $conf->{proxyAuthServiceImpersonation} );
            return 1;
        },

        # CheckDevOps requires Safe jail
        checkDevOpsWithSafeJail => sub {
            return ( 0, 'Safe jail must be enabled with CheckDevOps plugin' )
              if ( $conf->{checkDevOps}
                and !$conf->{useSafeJail} );
            return 1;
        },

        # Work around for #1740
        corruptApplicationConfig => sub {
            for my $cat ( keys %{ $conf->{applicationList} || {} } ) {
                if ( ref( $conf->{applicationList}->{$cat} ) eq "HASH" ) {
                    for my $app (
                        keys %{ $conf->{applicationList}->{$cat} || {} } )
                    {
                        if (
                            ref( $conf->{applicationList}->{$cat}->{$app} ) eq
                            "HASH"
                            and
                            $conf->{applicationList}->{$cat}->{$app}->{type} eq
                            "menuApp" )
                        {
                            return ( 0,
                                    'Error saving application list.'
                                  . ' Reload the manager and try again' );
                        }
                    }
                }
            }
            return 1;
        }
    };
}

1;
