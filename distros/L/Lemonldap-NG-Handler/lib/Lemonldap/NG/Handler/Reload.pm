# Methods run at configuration reload
package Lemonldap::NG::Handler::Reload;

#use Lemonldap::NG::Handler::Main qw(:all);
use Lemonldap::NG::Common::Safelib;    #link protected safe Safe object
use constant UNPROTECT => 1;
use constant SKIP      => 2;

use Lemonldap::NG::Handler::Main::Jail;
use Lemonldap::NG::Handler::Main::Logger;
use Lemonldap::NG::Handler::API qw(:httpCodes);
use Lemonldap::NG::Common::Crypto;

our $VERSION = '1.9.9';

## @imethod void configReload(hashRef conf, hashRef tsv)
# Given a Lemonldap::NG configuration $conf, computes values used to
# handle requests and store them in a thread shared object called $tsv
#
# methods called by configReload, and thread shared values computed, are:
# - jailInit():
#      - jail
# - defaultValuesInit():
#      (scalars for global options)
#      - cda
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
    my ( $class, $conf, $tsv ) = @_;
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "Loading configuration $conf->{cfgNum} for process $$", "info" );

    foreach my $sub (
        qw( defaultValuesInit jailInit portalInit locationRulesInit
        sessionStorageInit headersInit postUrlInit aliasInit )
      )
    {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Process $$ calls $sub",
            "debug" );
        $class->$sub( $conf, $tsv );
    }
    return 1;
}

## @imethod protected void jailInit(hashRef args)
# Set default values for non-customized variables
# @param $args reference to the configuration hash
sub jailInit {
    my ( $class, $conf, $tsv ) = @_;

    $tsv->{jail} = Lemonldap::NG::Handler::Main::Jail->new(
        'jail'            => $tsv->{jail},
        'useSafeJail'     => $conf->{useSafeJail},
        'customFunctions' => $conf->{customFunctions}
    );
    $tsv->{jail}->build_jail();
}

## @imethod protected void defaultValuesInit(hashRef args)
# Set default values for non-customized variables
# @param $args reference to the configuration hash
sub defaultValuesInit {
    my ( $class, $conf, $tsv ) = @_;

    $tsv->{$_} = $conf->{$_} foreach (
        qw(
        cda                    cookieExpiration cookieName
        customFunctions        httpOnly         securedCookie
        timeout                timeoutActivity  timeoutActivityInterval
        useRedirectOnError     useRedirectOnForbidden useSafeJail
        whatToTrace
        )
    );

    $tsv->{cipher} = Lemonldap::NG::Common::Crypto->new( $conf->{key} );

    foreach my $opt (qw(https port maintenance)) {
        if ( defined $conf->{$opt} ) {

            # Record default value in key '_'
            $tsv->{$opt} = { _ => $conf->{$opt} };
        }

        # Override with vhost options
        if ( $conf->{vhostOptions} ) {
            my $name = 'vhost' . ucfirst($opt);
            foreach my $vhost ( keys %{ $conf->{vhostOptions} } ) {
                my $val = $conf->{vhostOptions}->{$vhost}->{$name};
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Options $opt for vhost $vhost: $val", 'debug' );
                $tsv->{$opt}->{$vhost} = $val
                  if ( $val >= 0 );    # Keep default value if $val is negative
            }
        }
    }
    return 1;
}

## @imethod protected void portalInit(hashRef args)
# Verify that portal variable exists. Die unless
# @param $args reference to the configuration hash
sub portalInit {
    my ( $class, $conf, $tsv ) = @_;
    unless ( $conf->{portal} ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "portal parameter required", 'error' );
        return 0;
    }
    if ( $conf->{portal} =~ /[\$\(&\|"']/ ) {
        ( $tsv->{portal} ) = $class->conditionSub( $conf->{portal}, $tsv );
    }
    else {
        $tsv->{portal} = sub { return $conf->{portal} };
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
    my ( $class, $conf, $tsv ) = @_;

    foreach my $vhost ( keys %{ $conf->{locationRules} } ) {
        my $rules = $conf->{locationRules}->{$vhost};
        foreach my $url ( sort keys %{$rules} ) {
            my ( $cond, $prot ) = $class->conditionSub( $rules->{$url}, $tsv );
            unless ($cond) {
                $tsv->{maintenance}->{$vhost} = 1;
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Unable to build rule '$rules->{$url}': "
                      . $tsv->{jail}->error,
                    'error'
                );
                next;
            }

            if ( $url eq 'default' ) {
                $tsv->{defaultCondition}->{$vhost}  = $cond;
                $tsv->{defaultProtection}->{$vhost} = $prot;
            }
            else {
                push @{ $tsv->{locationCondition}->{$vhost} },  $cond;
                push @{ $tsv->{locationProtection}->{$vhost} }, $prot;
                push @{ $tsv->{locationRegexp}->{$vhost} },     qr/$url/;
                push @{ $tsv->{locationConditionText}->{$vhost} },
                    $cond =~ /^\(\?#(.*?)\)/ ? $1
                  : $cond =~ /^(.*?)##(.+)$/ ? $2
                  :                            $url;
                $tsv->{locationCount}->{$vhost}++;
            }
        }

        # Default policy set to 'accept'
        unless ( $tsv->{defaultCondition}->{$vhost} ) {
            $tsv->{defaultCondition}->{$vhost} = sub { 1 };
            $tsv->{defaultProtection}->{$vhost} = 0;
        }
    }
    return 1;
}

## @imethod protected void sessionStorageInit(hashRef args)
# Initialize the Apache::Session::* module choosed to share user's variables
# and the Cache::Cache module choosed to cache sessions
# @param $args reference to the configuration hash
sub sessionStorageInit {
    my ( $class, $conf, $tsv ) = @_;
    unless ( $tsv->{sessionStorageModule} = $conf->{globalStorage} ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "globalStorage required",
            'error' );
        return 0;
    }
    eval "use $tsv->{sessionStorageModule}";
    die($@) if ($@);
    $tsv->{sessionStorageOptions} = $conf->{globalStorageOptions};

    if ( $conf->{localSessionStorage} ) {
        $tsv->{sessionCacheModule}  = $conf->{localSessionStorage};
        $tsv->{sessionCacheOptions} = $conf->{localSessionStorageOptions};
        $tsv->{sessionCacheOptions}->{default_expires_in} ||= 600;

        if ( $conf->{status} ) {
            my $params = "";
            if ( $tsv->{sessionCacheModule} ) {
                require Data::Dumper;
                $params =
                  " $tsv->{sessionCacheModule},"
                  . Data::Dumper->new( [ $tsv->{sessionCacheOptions} ] )
                  ->Terse(1)->Indent(0)->Dump;    # To send params on one line
            }
            print { $tsv->{statusPipe} } "RELOADCACHE$params";
        }
    }
    return 1;
}

## @imethod void headersInit(hashRef args)
# Create the subroutines used to insert headers into the HTTP request.
# @param $args reference to the configuration hash
sub headersInit {
    my ( $class, $conf, $tsv ) = @_;

    # Creation of the subroutine which will generate headers
    foreach my $vhost ( keys %{ $conf->{exportedHeaders} } ) {
        my %headers = %{ $conf->{exportedHeaders}->{$vhost} };
        $tsv->{headerList}->{$vhost} = [ keys %headers ];
        my $sub;
        foreach ( keys %headers ) {
            my $val = $class->substitute( $headers{$_} );
            $sub .= "('$_' => $val),";
        }

        unless ( $tsv->{forgeHeaders}->{$vhost} =
            $tsv->{jail}->jail_reval("sub{return($sub)}") )
        {
            $tsv->{maintenance}->{$vhost} = 1;
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "$self: Unable to forge headers: " . $tsv->{jail}->error,
                'error' );
        }
    }
    return 1;
}

## @imethod protected void postUrlInit()
# Prepare methods to post form attributes
sub postUrlInit {
    my ( $class, $conf, $tsv ) = @_;
    return unless ( $conf->{post} );

    # Browse all vhost
    foreach my $vhost ( keys %{ $conf->{post} } ) {

        #  Browse all POST URI
        foreach my $url ( keys %{ $conf->{post}->{$vhost} } ) {
            my $d = $conf->{post}->{$vhost}->{$url};
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "Compiling POST data for $url", 'debug' );

            # Where to POST
            $d->{target} ||= $url;
            my $sub;
            $d->{vars} ||= [];
            foreach my $input ( @{ delete $d->{vars} } ) {
                $sub .=
                  "'$input->[0]' => " . $class->substitute( $input->[1] ) . ",";
            }
            unless ( $tsv->{inputPostData}->{$vhost}->{ delete $d->{target} } =
                $tsv->{outputPostData}->{$vhost}->{$url} =
                $tsv->{jail}->jail_reval("sub{$sub}") )
            {
                $tsv->{maintenance}->{$vhost} = 1;
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "$self: Unable to build post datas: " . $tsv->{jail}->error,
                    'error'
                );
            }

            $tsv->{postFormParams}->{$vhost}->{$url} = $d;
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
    my ( $class, $cond, $tsv ) = @_;
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
                    $Lemonldap::NG::Handler::Main::datas->{_logout} = $url;
                    return 0;
                },
                0
              )
            : (
                sub {
                    $Lemonldap::NG::Handler::Main::datas->{_logout} =
                      &{ $tsv->{portal} }();
                    return 0;
                },
                0
            )
        );
    }

    # Since filter exists only with Apache>=2, logout_app and logout_app_sso
    # targets are available only for it.
    # This error can also appear with Manager configured as CGI script
    if ( $cond =~ /^logout_app/i and MP() < 2 ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Rules logout_app and logout_app_sso require Apache>=2", 'warn' );
        return ( sub { 1 }, 0 );
    }

    # logout_app
    if ( $cond =~ /^logout_app(?:\s+(.*))?$/i ) {
        my $u = $1 || &{ $tsv->{portal} }();
        eval 'use Apache2::Filter' unless ( $INC{"Apache2/Filter.pm"} );
        return (
            sub {
                $Lemonldap::NG::Handler::API::ApacheMP2::request
                  ->add_output_filter(
                    sub {
                        return Lemonldap::NG::Handler::Main->redirectFilter( $u,
                            @_ );
                    }
                  );
                1;
            },
            0
        );
    }
    elsif ( $cond =~ /^logout_app_sso(?:\s+(.*))?$/i ) {
        my $u = $1 || &{ $tsv->{portal} }();
        eval 'use Apache2::Filter' unless ( $INC{"Apache2/Filter.pm"} );
        return (
            sub {
                Lemonldap::NG::Handler::Main->localUnlog;
                $Lemonldap::NG::Handler::API::ApacheMP2::request
                  ->add_output_filter(
                    sub {
                        my $r = $_[0]->r;
                        return Lemonldap::NG::Handler::Main->redirectFilter(
                            &{ $tsv->{portal} }() . "?url="
                              . Lemonldap::NG::Handler::Main->encodeUrl($u)
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

    # Replace some strings in condition
    $cond = $class->substitute($cond);
    my $sub;
    unless ( $sub = $tsv->{jail}->jail_reval("sub{return($cond)}") ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "$self: Unable to build condition ($cond): " . $tsv->{jail}->error,
            'error'
        );
    }

    # Return sub and protected flag
    return ( $sub, 0 );
}

## @method arrayref aliasInit
# @param options vhostOptions configuration item
# @return arrayref of vhost and aliases
sub aliasInit {
    my ( $class, $conf, $tsv ) = @_;

    foreach my $vhost ( keys %{ $conf->{vhostOptions} || {} } ) {
        if ( my $aliases = $conf->{vhostOptions}->{$vhost}->{vhostAliases} ) {
            foreach ( split /\s+/, $aliases ) {
                $tsv->{vhostAlias}->{$_} = $vhost;
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Registering $_ as alias of $vhost", 'debug' );
            }
        }
    }
    return 1;
}

# TODO: support wildcards in aliases

sub substitute {
    my ( $class, $expr ) = @_;

    # substitute special vars, just for retro-compatibility
    $expr =~ s/\$date\b/&date/sg;
    $expr =~ s/\$vhost\b/&hostname/sg;
    $expr =~ s/\$ip\b/&remote_ip/sg;

    # substitute vars with session datas, excepts special vars $_ and $\d+
    $expr =~ s/\$(?!ENV)(_*[a-zA-Z]\w*)/\$datas->{$1}/sg;

    return $expr;
}

1;
