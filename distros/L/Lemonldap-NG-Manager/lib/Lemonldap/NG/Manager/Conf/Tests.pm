package Lemonldap::NG::Manager::Conf::Tests;

use utf8;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Handler::SharedConf;

our $VERSION = '1.9.10';

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
            my $gc =
              $Lemonldap::NG::Handler::SharedConf::tsv->{sessionStorageModule};
            return 1
              if ( ( $gc and $gc eq $conf->{globalStorage} )
                or $conf->{globalStorage} eq
                'Lemonldap::NG::Common::Apache::Session::SOAP' );
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
            return ( -1, "Unable to insert datas ($@)" ) if ($@);
            return ( -1, "Unable to recover data stored" )
              unless ( $h{a} == 1 );
            eval { tied(%h)->delete; };
            return ( -1, "Unable to delete session ($@)" ) if ($@);
            return ( -1,
'All sessions may be lost and you must restart all your Apache servers'
            ) if ( $conf->{globalStorage} ne $gc );
            return 1;
        },

        # Warn if cookie name has changed
        cookieNameChanged => sub {
            my $cn = $Lemonldap::NG::Handler::SharedConf::tsv->{cookieName};
            return (
                1,
                (
                    $cn
                      and $cn ne $conf->{cookieName}
                    ? 'Cookie name has changed, you must restart all your Apache servers'
                    : ()
                )
            );
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

        # Test SMTP connection and authentication
        smtpConnectionAuthentication => sub {

            # Skip test if no SMTP configuration
            return 1 unless ( $conf->{SMTPServer} );

            # Use SMTP
            eval "use Net::SMTP";
            return ( 1, "Net::SMTP module is required to use SMTP server" )
              if ($@);

            # Create SMTP object
            my $smtp = Net::SMTP->new( $conf->{SMTPServer}, Timeout => 5 );
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

        # SAML entity ID must be unique
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
    };
}

1;
