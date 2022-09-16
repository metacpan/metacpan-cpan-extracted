package Lemonldap::NG::Handler::Main::Reload;

our $VERSION = '2.0.15';

package Lemonldap::NG::Handler::Main;

use strict;
use Lemonldap::NG::Common::Conf::Constants;    #inherits
use Lemonldap::NG::Common::Crypto;
use Lemonldap::NG::Common::Safelib;            #link protected safe Safe object
use Lemonldap::NG::Handler::Main::Jail;
use Scalar::Util qw(weaken);

use constant UNPROTECT => 1;
use constant SKIP      => 2;
use constant MAYSKIP   => 3;

our @_onReload;

sub onReload {
    my ( $class, $obj, $sub ) = @_;
    weaken($obj);
    push @_onReload, [ $obj, $sub ];
}

# CONFIGURATION UPDATE

## @rmethod protected int checkConf(boolean force)
# Check if configuration is up to date, and reload it if needed.
# If the optional boolean $force is set to true,
# * cached configuration is ignored
# * and checkConf returns false if it fails to load remote config
# @param $force boolean
# @return true if config is up to date or if reload config succeeded
sub checkConf {
    my ( $class, $force ) = @_;
    $class->logger->debug("Check configuration for $class");
    my $prm  = { local => !$force, localPrm => $class->localConfig };
    my $conf = $class->confAcc->getConf($prm);
    chomp $Lemonldap::NG::Common::Conf::msg;

    unless ( ref($conf) ) {
        $class->logger->error(
"$class: Unable to load configuration: $Lemonldap::NG::Common::Conf::msg"
        );
        return $force ? 0 : $class->cfgNum ? 1 : 0;
    }

    if ($Lemonldap::NG::Common::Conf::msg) {
        if ( $Lemonldap::NG::Common::Conf::msg =~ /Error:/ ) {
            $class->logger->error($Lemonldap::NG::Common::Conf::msg);
        }
        elsif ( $Lemonldap::NG::Common::Conf::msg =~ /Warn:/ ) {
            $class->logger->warn($Lemonldap::NG::Common::Conf::msg);
        }
        else {
            $class->logger->debug($Lemonldap::NG::Common::Conf::msg);
        }
    }
    $Lemonldap::NG::Common::Conf::msg = '';

    if (   $force
        or !$class->cfgNum
        or !$class->cfgDate
        or $class->cfgNum != $conf->{cfgNum}
        or $class->cfgDate != $conf->{cfgDate} )
    {
        $class->logger->debug(
            "Get configuration $conf->{cfgNum} aged $conf->{cfgDate}");
        unless ( $class->cfgNum( $conf->{cfgNum} )
            && $class->cfgDate( $conf->{cfgDate} ) )
        {
            $class->logger->error('No configuration available');
            return 0;
        }
        $class->configReload($conf);
        foreach (@_onReload) {
            my ( $obj, $sub ) = @$_;
            if ($obj) {
                $class->logger->debug(
                    'Launching ' . ref($obj) . "->$sub(conf)" );
                unless ( $obj->$sub($conf) ) {
                    $class->logger->error( "Underlying object can't load conf ("
                          . ref($obj)
                          . "->$sub)" );
                    return 0;
                }
            }
        }
    }
    $class->checkTime( $conf->{checkTime} ) if $conf->{checkTime};
    $class->lastCheck( time() );
    $class->logger->debug("$class: configuration is up to date");
    return 1;
}

# RELOAD SYSTEM

## @rmethod int reload
# Launch checkConf() with $local=0, so remote configuration is tested.
# Then build a simple HTTP response that just returns "200 OK" or
# "500 Server Error".
# @return Apache constant ($class->OK or $class->SERVER_ERROR)
sub reload {
    my $class = shift;
    $class->logger->notice("Request for configuration reload");
    return $class->checkConf(1) ? $class->DONE : $class->SERVER_ERROR;
}

*refresh = *reload;

# INTERNAL METHODS

## @imethod void configReload(hashRef conf, hashRef tsv)
# Given a Lemonldap::NG configuration $conf, computes values used to
# handle requests and store them in a thread shared object called $tsv
#
# methods called by configReload, and thread shared values computed, are:
# - jailInit():
#      - jail
# - defaultValuesInit():
#      (scalars for global options)
#      - cookieExpiration  # warning: absent from default Conf
#      - cookieName
#      - securedCookie,
#      - httpOnly
#      - whatToTrace
#      - customFunctions
#      - timeoutActivity
#      - timeoutActivityInterval
#      - useRedirectOnError
#      - useRedirectOnForbidden
#      - useSafeJail
#      (objects)
#      - cipher  # Lemonldap::NG::Common::Crypto object
#      (hashrefs for vhost options)
#      - https
#      - port
#      - maintenance
# - portalInit():
#      - portal (functions that returns portal URL)
# - locationRulesInit():
#      - locationCount
#      - defaultCondition
#      - defaultProtection
#      - locationCondition
#      - locationProtection
#      - locationRegexp
#      - locationConditionText
# - sessionStorageInit():
#      - sessionStorageModule
#      - sessionStorageOptions
#      - sessionCacheModule
#      - sessionCacheOptions
# - headersInit():
#      - headerList
#      - forgeHeaders
# - postUrlInit():
#      - inputPostData
#      - outputPostData
# - aliasInit():
#      - vhostAlias
#
# The *Init() methods can be run in any order,
# but jailInit must be run first because $tsv->{jail}
# is used by locationRulesInit, headersInit and postUrlInit.

# @param $conf reference to the configuration hash
# @param $tsv reference to the thread-shared parameters conf
sub configReload {
    my ( $class, $conf ) = @_;
    $class->logger->info(
        "Loading configuration $conf->{cfgNum} for process $$");

    foreach my $sub (
        qw( defaultValuesInit jailInit portalInit locationRulesInit
        sessionStorageInit headersInit postUrlInit aliasInit oauth2Init )
      )
    {
        $class->logger->debug("Process $$ calls $sub");
        $class->$sub($conf);
    }
    return 1;
}

## @imethod protected void jailInit(hashRef args)
# Set default values for non-customized variables
# @param $args reference to the configuration hash
sub jailInit {
    my ( $class, $conf ) = @_;

    $class->tsv->{jail} = Lemonldap::NG::Handler::Main::Jail->new( {
            useSafeJail          => $conf->{useSafeJail},
            customFunctions      => $conf->{customFunctions},
            multiValuesSeparator => $conf->{multiValuesSeparator},
        }
    );
    $class->tsv->{jail}
      ->build_jail( $class, $conf->{require}, $conf->{requireDontDie} );
}

## @imethod protected void defaultValuesInit(hashRef args)
# Set default values for non-customized variables
# @param $args reference to the configuration hash
sub defaultValuesInit {
    my ( $class, $conf ) = @_;

    $class->tsv->{$_} = $conf->{$_}
      foreach ( qw(
        cookieExpiration        cookieName         customFunctions httpOnly
        securedCookie           timeout            timeoutActivity
        timeoutActivityInterval useRedirectOnError useRedirectOnForbidden
        useSafeJail             whatToTrace        handlerInternalCache
        handlerServiceTokenTTL  customToTrace      lwpOpts lwpSslOpts
        authChoiceAuthBasic     authChoiceParam    hiddenAttributes
        upgradeSession
        )
      );

    $class->tsv->{cipher} = Lemonldap::NG::Common::Crypto->new( $conf->{key} );

    foreach my $opt (qw(https port maintenance)) {

        # Record default value in key '_'
        $class->tsv->{$opt} = { _ => $conf->{$opt} };

        # Override with vhost options
        if ( $conf->{vhostOptions} ) {
            my $name = 'vhost' . ucfirst($opt);
            foreach my $vhost ( sort keys %{ $conf->{vhostOptions} } ) {
                $conf->{vhostOptions}->{$vhost} ||= {};
                my $val = $conf->{vhostOptions}->{$vhost}->{$name};

                # Keep global value if $val is negative
                if ( defined $val and $val >= 0 ) {
                    $class->logger->debug(
                        "Options $opt for vhost $vhost: $val");
                    $class->tsv->{$opt}->{$vhost} = $val;
                }
            }
        }
    }
    if ( $conf->{vhostOptions} ) {
        foreach my $vhost ( sort keys %{ $conf->{vhostOptions} } ) {
            $class->tsv->{type}->{$vhost} =
              $conf->{vhostOptions}->{$vhost}->{vhostType};
            $class->tsv->{authnLevel}->{$vhost} =
              $conf->{vhostOptions}->{$vhost}->{vhostAuthnLevel};
            $class->tsv->{serviceTokenTTL}->{$vhost} =
              $conf->{vhostOptions}->{$vhost}->{vhostServiceTokenTTL};
            $class->tsv->{accessToTrace}->{$vhost} =
              $conf->{vhostOptions}->{$vhost}->{vhostAccessToTrace};
            $class->tsv->{devOpsRulesUrl}->{$vhost} =
              $conf->{vhostOptions}->{$vhost}->{vhostDevOpsRulesUrl};
        }
    }
    return 1;
}

## @imethod protected void portalInit(hashRef args)
# Verify that portal variable exists. Die unless
# @param $args reference to the configuration hash
sub portalInit {
    my ( $class, $conf ) = @_;
    unless ( $conf->{portal} ) {
        $class->logger->error("portal parameter required");
        return 0;
    }
    if ( $conf->{portal} =~ /[\$\(&\|"']/ ) {
        ( $class->tsv->{portal} ) =
          $class->conditionSub( $conf->{portal} );
    }
    else {
        $class->tsv->{portal} = sub { return $conf->{portal} };
    }
    return 1;
}

## @imethod void locationRulesInit(hashRef args)
# Compile rules.
# Rules are stored in $args->{locationRules}->{&lt;virtualhost&gt;} that contains
# regexp=>test expressions where :
# - regexp is used to test URIs
# - test contains an expression used to grant the user
#
# This function creates 2 hashRef containing :
# - one list of the compiled regular expressions for each virtual host
# - one list of the compiled functions (compiled with conditionSub()) for each
# virtual host
# @param $args reference to the configuration hash
sub locationRulesInit {
    my ( $class, $conf, $orules ) = @_;

    $orules ||= $conf->{locationRules};
    $class->tsv->{vhostReg} = [];
    my @lastReg;

    foreach my $vhost ( keys %$orules ) {
        my $rules = $orules->{$vhost};
        if ( $vhost =~ /[\%\*]/ ) {
            my $expr = join '[^\.]*', map {
                my $elt = $_;
                join '.*', map { quotemeta $_ } split /\*/, $elt;
            } split /\%/, $vhost;
            if ($expr) {
                push @{ $class->tsv->{vhostReg} }, [ qr/^$expr$/, $vhost ];
            }
            else {
                push @lastReg, [ qr/.+/, $vhost ];
            }
        }
        $class->tsv->{locationCount}->{$vhost}         = 0;
        $class->tsv->{locationCondition}->{$vhost}     = [];
        $class->tsv->{locationProtection}->{$vhost}    = [];
        $class->tsv->{locationRegexp}->{$vhost}        = [];
        $class->tsv->{locationConditionText}->{$vhost} = [];
        $class->tsv->{locationAuthnLevel}->{$vhost}    = [];

        foreach my $url ( sort keys %{$rules} ) {
            my ( $cond, $prot ) = $class->conditionSub( $rules->{$url} );
            unless ($cond) {
                $class->tsv->{maintenance}->{$vhost} = 1;
                $class->logger->error(
                    "Unable to build rule '$rules->{$url}': "
                      . $class->tsv->{jail}->error );
                next;
            }

            if ( $url eq 'default' ) {
                $class->tsv->{defaultCondition}->{$vhost}  = $cond;
                $class->tsv->{defaultProtection}->{$vhost} = $prot;
            }
            else {
                push @{ $class->tsv->{locationCondition}->{$vhost} },  $cond;
                push @{ $class->tsv->{locationProtection}->{$vhost} }, $prot;
                push @{ $class->tsv->{locationRegexp}->{$vhost} },     qr/$url/;
                push @{ $class->tsv->{locationAuthnLevel}->{$vhost} },
                  $url =~ /\(\?#AuthnLevel=(-?\d+)\)/
                  ? $1
                  : undef;
                push @{ $class->tsv->{locationConditionText}->{$vhost} },
                    $url =~ /^\(\?#(.*?)\)/ ? $1
                  : $url =~ /^(.*?)##(.+)$/ ? $2
                  :                           $url;
                $class->tsv->{locationCount}->{$vhost}++;
            }
        }

        # Default policy set to 'accept'
        unless ( $class->tsv->{defaultCondition}->{$vhost} ) {
            $class->tsv->{defaultCondition}->{$vhost}  = sub { 1 };
            $class->tsv->{defaultProtection}->{$vhost} = 0;
        }
    }
    @{ $class->tsv->{vhostReg} } = sort {
        my $av = $a->[1];
        my $bv = $b->[1];
        return 1  if $av =~ /^\*/ and $bv !~ /^\*/;
        return -1 if $bv =~ /^\*/ and $av !~ /^\*/;
        return 1  if $av =~ /^\%/ and $bv !~ /^\%/;
        return -1 if $bv =~ /^\%/ and $av !~ /^\%/;
        return length($bv) <=> length($av) || $av cmp $bv;
    } @{ $class->tsv->{vhostReg} } if @{ $class->tsv->{vhostReg} };
    push @{ $class->tsv->{vhostReg} }, @lastReg if @lastReg;
    return 1;
}

## @imethod protected void sessionStorageInit(hashRef args)
# Initialize the Apache::Session::* module choosed to share user's variables
# and the Cache::Cache module chosen to cache sessions
# @param $args reference to the configuration hash
sub sessionStorageInit {
    my ( $class, $conf ) = @_;

    # Global session storage
    unless ( $class->tsv->{sessionStorageModule} = $conf->{globalStorage} ) {
        $class->logger->error("globalStorage required");
        return 0;
    }
    eval "use " . $class->tsv->{sessionStorageModule};
    die($@) if ($@);
    $class->tsv->{sessionStorageOptions} = $conf->{globalStorageOptions};

    # OIDC session storage
    if ( $conf->{oidcStorage} ) {
        eval "use " . $conf->{oidcStorage};
        die($@) if ($@);
        $class->tsv->{oidcStorageModule}  = $conf->{oidcStorage};
        $class->tsv->{oidcStorageOptions} = $conf->{oidcStorageOptions};

    }
    else {
        $class->tsv->{oidcStorageModule}  = $conf->{globalStorage};
        $class->tsv->{oidcStorageOptions} = $conf->{globalStorageOptions};
    }

    # Local session storage
    if ( $conf->{localSessionStorage} ) {
        $class->tsv->{sessionCacheModule} = $conf->{localSessionStorage};
        $class->tsv->{sessionCacheOptions} =
          $conf->{localSessionStorageOptions};
        $class->tsv->{sessionCacheOptions}->{default_expires_in} ||= 600;

        if ( $conf->{status} ) {
            my $params = "";
            if ( $class->tsv->{sessionCacheModule} ) {
                $params = $class->tsv->{sessionCacheModule} . ',{' . join(
                    ',',
                    map {
                        "$_ => '"
                          . $class->tsv->{sessionCacheOptions}->{$_} . "'"
                      }
                      keys %{ $class->tsv->{sessionCacheOptions} // {} }
                ) . '}';
            }
            $class->tsv->{statusPipe}->print("RELOADCACHE $params\n");
        }
    }
    return 1;
}

## @imethod void headersInit(hashRef args)
# Create the subroutines used to insert headers into the HTTP request.
# @param $args reference to the configuration hash
sub headersInit {
    my ( $class, $conf, $headers ) = @_;
    $headers ||= $conf->{exportedHeaders};

    # Creation of the subroutine which will generate headers
    foreach my $vhost ( keys %{$headers} ) {
        unless ($vhost) {
            $class->logger->warn('Empty vhost in headers, skipping');
            next;
        }
        $headers->{$vhost} ||= {};
        my %headers = %{ $headers->{$vhost} };
        $class->tsv->{headerList}->{$vhost} = [ keys %headers ];
        my $sub = '';
        foreach ( keys %headers ) {
            $headers{$_} ||= "''";
            my $val = $class->substitute( $headers{$_} ) . " // ''";
            $sub .= "('$_' => $val),";
        }

        unless ( $class->tsv->{forgeHeaders}->{$vhost} =
            $class->buildSub($sub) )
        {
            $class->tsv->{maintenance}->{$vhost} = 1;
            $class->logger->error( "$class Unable to forge $vhost headers: "
                  . $class->tsv->{jail}->error );
        }
    }
    return 1;
}

## @imethod protected void postUrlInit()
# Prepare methods to post form attributes
sub postUrlInit {
    my ( $class, $conf ) = @_;
    return unless ( $conf->{post} );

    # Browse all vhost
    foreach my $vhost ( keys %{ $conf->{post} } ) {

        #  Browse all POST URI
        foreach my $url ( keys %{ $conf->{post}->{$vhost} || {} } ) {
            my $d = $conf->{post}->{$vhost}->{$url};
            $class->logger->debug("Compiling POST data for $url");

            # Where to POST
            $d->{target} ||= $url;
            my $sub;
            $d->{vars} ||= [];
            foreach my $input ( @{ delete $d->{vars} } ) {
                $sub .=
                  "'$input->[0]' => " . $class->substitute( $input->[1] ) . ",";
            }
            unless (
                $class->tsv->{inputPostData}->{$vhost}->{ delete $d->{target} }
                = $class->tsv->{outputPostData}->{$vhost}->{$url} =
                $class->buildSub($sub) )
            {
                $class->tsv->{maintenance}->{$vhost} = 1;
                $class->logger->error( "$class: Unable to build post data: "
                      . $class->tsv->{jail}->error );
            }

            $class->tsv->{postFormParams}->{$vhost}->{$url} = $d;
        }
    }
    return 1;
}

## @imethod protected codeRef conditionSub(string cond)
# Returns a compiled function used to grant users (used by
# locationRulesInit(). The second value returned is a non null
# constant if URL is not protected (by "unprotect" or "skip"), 0 else.
# @param $cond The boolean expression to use
# @param $mainClass  optional
# @return array (ref(sub), int)
sub conditionSub {
    my ( $class, $cond ) = @_;
    $cond =~ s/\(\?#(\d+)\)$//;
    my ( $OK, $NOK ) = ( sub { 1 }, sub { 0 } );

    # Simple cases : accept and deny
    return ( $OK, 0 )
      if ( $cond =~ /^accept$/i );
    return ( $NOK, 0 )
      if ( $cond =~ /^deny$/i );

    # Cases unprotect and skip : 2nd value is 1 or 2
    return ( $OK, UNPROTECT )
      if ( $cond =~ /^unprotect$/i );
    return ( $OK, SKIP )
      if ( $cond =~ /^skip$/i );

    # Case logout
    if ( $cond =~ /^logout(?:_sso)?(?:\s+(.*))?$/i ) {
        my $url = $1;
        return (
            $url
            ? (
                sub {
                    $_[1]->{_logout} = $url;
                    return 0;
                },
                0
              )
            : (
                sub {
                    $_[1]->{_logout} = $class->tsv->{portal}->();
                    return 0;
                },
                0
            )
        );
    }

    # Since filter exists only with Apache>=2, logout_app and logout_app_sso
    # targets are available only for it.
    # This error can also appear with Manager configured as CGI script
    if ( $cond =~ /^logout_app/i
        and not $class->isa('Lemonldap::NG::Handler::ApacheMP2::Main') )
    {
        $class->logger->info(
            "Rules logout_app and logout_app_sso require Apache>=2");
        return ( sub { 1 }, 0 );
    }

    # logout_app
    if ( $cond =~ /^logout_app(?:\s+(.*))?$/i ) {
        my $u = $1 || $class->tsv->{portal}->();
        $class->logger->debug("logout_app redirect to $u");
        eval 'use Apache2::Filter' unless ( $INC{"Apache2/Filter.pm"} );
        return (
            sub {
                $_[0]->{env}->{'psgi.r'}->add_output_filter(
                    sub {
                        return $class->redirectFilter( $u, @_ );
                    }
                );
                1;
            },
            0
        );
    }
    elsif ( $cond =~ /^logout_app_sso(?:\s+(.*))?$/i ) {
        my $u = $1 || $class->tsv->{portal}->();
        $class->logger->debug("logout_app_sso redirect to $u");
        eval 'use Apache2::Filter' unless ( $INC{"Apache2/Filter.pm"} );
        return (
            sub {
                my ($req) = @_;
                $class->localUnlog( $req, @_ );
                $req->{env}->{'psgi.r'}->add_output_filter(
                    sub {
                        my $r = $_[0]->r;
                        return $class->redirectFilter(
                            &{ $class->tsv->{portal} }() . "?url="
                              . $class->encodeUrl( $req, $u )
                              . "&logout=1",
                            @_
                        );
                    }
                );
                1;
            },
            0
        );
    }

    my $mayskip = 0;
    $mayskip = MAYSKIP if $cond =~ /\bskip\b/;

    # Replace some strings in condition
    $cond = $class->substitute($cond);
    my $sub;
    unless ( $sub = $class->buildSub($cond) ) {
        $class->logger->error( "$class: Unable to build condition ($cond): "
              . $class->tsv->{jail}->error );
    }

    # Return sub and protected flag
    return ( $sub, $mayskip );
}

## @method arrayref aliasInit
# @param options vhostOptions configuration item
# @return arrayref of vhost and aliases
sub aliasInit {
    my ( $class, $conf ) = @_;

    foreach my $vhost ( keys %{ $conf->{vhostOptions} || {} } ) {
        if ( my $aliases = $conf->{vhostOptions}->{$vhost}->{vhostAliases} ) {
            foreach ( split /\s+/, $aliases ) {
                $class->tsv->{vhostAlias}->{$_} = $vhost;
                $class->logger->debug("Registering $_ as alias of $vhost");
            }
        }
    }
    return 1;
}

# TODO: support wildcards in aliases

## @method arrayref oauth2Init
# @param options vhostOptions configuration item
# @return arrayref of vhost and aliases
sub oauth2Init {
    my ( $class, $conf ) = @_;

    foreach my $rp ( keys %{ $conf->{oidcRPMetaDataOptions} || {} } ) {
        if (    $conf->{oidcRPMetaDataOptions}->{$rp}
            and $conf->{oidcRPMetaDataOptions}->{$rp}
            ->{oidcRPMetaDataOptionsClientID} )
        {
            $class->tsv->{oauth2Options}->{$rp}->{clientId} =
              $conf->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsClientID};
        }
    }
    return 1;
}

sub substitute {
    my ( $class, $expr ) = @_;
    $expr //= '';

    # substitute special vars, just for retro-compatibility
    $expr =~ s/\$date\b/&date/sg;
    $expr =~ s/\$vhost\b/\$ENV{HTTP_HOST}/sg;
    $expr =~ s/\$ip\b/\$ENV{REMOTE_ADDR}/sg;

    # substitute vars with session data, excepts special vars $_ and $\d+
    $expr =~ s/\$(?!(?:ENV|env)\b)(_\w+|[a-zA-Z]\w*)/\$s->{$1}/sg;
    $expr =~ s/\$ENV\{/\$r->{env}->\{/g;
    $expr =~ s/\$env->\{/\$r->{env}->\{/g;
    $expr =~ s/\bskip\b/q\{999_SKIP\}/g;

    # handle inGroup
    $expr =~ s/\binGroup\(([^)]*)\)/listMatch(\$s->{'hGroups'},$1,1)/g;

    # handle has2f
    $expr =~ s/\bhas2f\(([^),]*)\)/has2f_internal(\$s,$1)/g;

    return $expr;
}

sub buildSub {
    my ( $class, $val ) = @_;
    my $res =
      $class->tsv->{jail}->jail_reval("sub{my (\$r,\$s)=\@_;return($val)}");
    unless ($res) {
        $class->logger->error( $class->tsv->{jail}->error );
    }
    return $res;
}

1;
