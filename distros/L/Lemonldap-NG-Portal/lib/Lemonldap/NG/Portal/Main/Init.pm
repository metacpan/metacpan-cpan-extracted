##@class Lemonldap::NG::Portal::Main::Init
# Initialization part of Lemonldap::NG portal
#
# 2 public methods:
#  - init():       launch at startup. Load 'portal' section of lemonldap-ng.ini,
#                  initialize default route and launch reloadConf()
#  - reloadConf(): (re)load configuration using localConf (ie 'portal' section
#                  of lemonldap-ng.ini) and underlying handler configuration
package Lemonldap::NG::Portal::Main::Init;

our $VERSION = '2.0.15';

package Lemonldap::NG::Portal::Main;

use strict;
use Mouse;
use Regexp::Assemble;
use Lemonldap::NG::Common::Util qw(getSameSite);

# PROPERTIES

# Configuration storage
has localConfig => ( is => 'rw', default => sub { {} } );
has conf        => ( is => 'rw', default => sub { {} } );
has menu        => ( is => 'rw', default => sub { {} } );
has trOver      => ( is => 'rw', default => sub { { all => {} } } );

# Sub modules
has _authentication => ( is => 'rw' );
has _userDB         => ( is => 'rw' );
has _passwordDB     => ( is => 'rw' );
has _sfEngine       => ( is => 'rw' );
has _captcha        => ( is => 'rw' );

has loadedModules => ( is => 'rw' );

# Macros and groups
has _macros     => ( is => 'rw' );
has _groups     => ( is => 'rw' );
has _jsRedirect => ( is => 'rw' );

# TrustedDomain regexp
has trustedDomainsRe         => ( is => 'rw' );
has additionalTrustedDomains => ( is => 'rw', default => sub { [] } );

# Lists to store plugins entry-points
my @entryPoints;

BEGIN {
    @entryPoints = (

        # Auth process entrypoints
        qw(beforeAuth betweenAuthAndData afterData endAuth),

        # Authenticated users entrypoint
        'forAuthUser',

        # Logout entrypoint
        'beforeLogout',

        # Special endpoint
        'authCancel',    # Clean pdata when user click on "cancel"
    );

    foreach (@entryPoints) {
        has $_ => (
            is      => 'rw',
            isa     => 'ArrayRef',
            default => sub { [] }
        );
    }
}

# Endpoints inserted after any main sub
has 'afterSub'  => ( is => 'rw', default => sub { {} } );
has 'aroundSub' => ( is => 'rw', default => sub { {} } );

# Issuer hooks
has 'hook' => ( is => 'rw', default => sub { {} } );

has spRules => (
    is      => 'rw',
    default => sub { {} }
);

# Custom template parameters
has customParameters => ( is => 'rw', default => sub { {} } );

# Content-Security-Policy headers
has csp => ( is => 'rw' );

# Cross-Origine Resource Sharing headers
has cors => ( is => 'rw' );

# Cookie SameSite value
has cookieSameSite => ( is => 'rw' );

# Plugins may declare the session data they want to store in login history here
has pluginSessionDataToRemember =>
  ( is => 'rw', isa => "HashRef", default => sub { {} } );

# INITIALIZATION

sub init {
    my ( $self, $args ) = @_;
    $args ||= {};
    my $confAcc = Lemonldap::NG::Common::Conf->new( $args->{configStorage} );
    unless ($confAcc) {
        die( 'Could not read configuration: '
              . $Lemonldap::NG::Common::Conf::msg );
    }
    $self->localConfig( { %{ $confAcc->getLocalConf('portal') }, %$args } );

    # Load override messages from lemonldap-ng.ini
    foreach my $k ( keys %{ $self->localConfig } ) {
        if ( $k =~ /tpl_(.*)/ ) {
            $self->customParameters->{$1} = $self->localConfig->{$k};
        }
        elsif ( $k =~ /error_(?:(\w+?)_)?(\d+)$/ ) {
            my $lang = $1 || 'all';
            $self->trOver->{$lang}->{"PE$2"} = $self->localConfig->{$k};
        }
        elsif ( $k =~ /msg_(?:(\w+?)_)?(\w+)$/ ) {
            my $lang = $1 || 'all';
            $self->trOver->{$lang}->{$2} = $self->localConfig->{$k};
        }
    }
    $self->trOver( JSON::to_json( $self->trOver ) );

    # Purge loaded module list
    $self->loadedModules( {} );
    $self->afterSub( {} );
    $self->aroundSub( {} );
    $self->hook( {} );

    # Insert `reloadConf` in handler reload stack
    Lemonldap::NG::Handler::Main->onReload( $self, 'reloadConf' );

    # Handler::PSGI::Try initialization
    unless ( $self->SUPER::init( $self->localConfig ) ) {
        $self->logger->error( 'Initialization failed: ' . $self->error );
        $self->error(
"Initialization failed! Enable debug logs, reload your web server and catch main error..."
        );
        return 0;
    }
    if ( $self->error ) {
        $self->logger->error( $self->error );
        return 0;
    }

    # Default routes must point to routines declared above
    $self->defaultAuthRoute('');
    $self->defaultUnauthRoute('');
    return 1;
}

sub setPortalRoutes {
    my ($self) = @_;
    $self->authRoutes( {
            GET     => {},
            POST    => {},
            PUT     => {},
            PATCH   => {},
            DELETE  => {},
            OPTIONS => {}
        }
    );
    $self->unAuthRoutes( {
            GET     => {},
            POST    => {},
            PUT     => {},
            PATCH   => {},
            DELETE  => {},
            OPTIONS => {}
        }
    );
    $self

      # "/" or undeclared paths
      ->addUnauthRoute( '*' => 'login',     ['GET'] )
      ->addUnauthRoute( '*' => 'postLogin', ['POST'] )
      ->addAuthRoute( '*' => 'authenticatedRequest',     ['GET'] )
      ->addAuthRoute( '*' => 'postAuthenticatedRequest', ['POST'] )

      # psgi.js
      ->addUnauthRoute( 'psgi.js' => 'sendJs', ['GET'] )
      ->addAuthRoute( 'psgi.js' => 'sendJs', ['GET'] )

      # portal.css
      ->addUnauthRoute( 'portal.css' => 'sendCss', ['GET'] )
      ->addAuthRoute( 'portal.css' => 'sendCss', ['GET'] )

      # lmerror
      ->addUnauthRoute( lmerror => { ':code' => 'lmError' }, ['GET'] )
      ->addAuthRoute( lmerror => { ':code' => 'lmError' }, ['GET'] )

      # Core REST API
      ->addUnauthRoute( ping => 'pleaseAuth', ['GET'] )
      ->addAuthRoute( ping => 'authenticated', ['GET'] )

      # Refresh session
      ->addAuthRoute( refresh => 'refresh', ['GET'] )

      ->addAuthRoute( '*' => 'corsPreflight', ['OPTIONS'] )
      ->addUnauthRoute( '*' => 'corsPreflight', ['OPTIONS'] )

      # Logout
      ->addAuthRoute( logout => 'logout', ['GET'] )
      ->addUnauthRoute( logout => 'unauthLogout', ['GET'] );

    # Default routes must point to routines declared above
    $self->defaultAuthRoute('');
    $self->defaultUnauthRoute('');
    return 1;

}

sub reloadConf {
    my ( $self, $conf ) = @_;

    # Handle requests (other path may be declared in enabled plugins)
    $self->setPortalRoutes;

    # Reinitialize $self->conf
    %{ $self->{conf} } = %{ $self->localConfig };

    # Reinitialize arrays
    foreach ( qw(_macros _groups), @entryPoints ) {
        $self->{$_} = [];
    }
    $self->afterSub( {} );
    $self->aroundSub( {} );
    $self->spRules( {} );
    $self->hook( {} );

    # Plugin history fields
    $self->pluginSessionDataToRemember( {} );

    # Load conf in portal object
    foreach my $key ( keys %$conf ) {
        $self->{conf}->{$key} ||= $conf->{$key};
    }

    # Initialize content-security-policy headers
    my $csp = '';
    foreach (qw(default img src style font connect script)) {
        my $prm = $self->conf->{ 'csp' . ucfirst($_) };
        $csp .= "$_-src $prm;" if ($prm);
    }
    $self->csp($csp);
    $self->logger->debug( "Initialized CSP headers : " . $self->csp );

    # Initialize Cross-Origin Resource Sharing headers
    my $cors = '';
    foreach (
        qw(Allow_Origin Allow_Credentials Allow_Headers Allow_Methods Expose_Headers Max_Age)
      )
    {
        my $header = $_;
        my $prm    = $self->conf->{ 'cors' . $_ };
        if ( $header and $prm ) {
            $header =~ s/_/-/;
            $prm    =~ s/\s+//;
            $cors .= "Access-Control-$header;$prm;";
        }
    }
    $self->cors($cors);
    $self->logger->debug( "Initialized CORS headers : " . $self->cors );

    # Initialize templateDir
    $self->{templateDir} =
      $self->conf->{templateDir} . '/' . $self->conf->{portalSkin}
      if ( $self->conf->{templateDir} and $self->conf->{portalSkin} );
    unless ( -d $self->{templateDir} ) {
        $self->error("Template dir $self->{templateDir} doesn't exist");
        return $self->fail;
    }
    $self->templateDir(
        [ $self->{templateDir}, $self->conf->{templateDir} . '/bootstrap' ] );

    $self->{staticPrefix} = $self->conf->{staticPrefix} || '/static';
    $self->{languages}    = $self->conf->{languages}    || '/';

    # Initialize session DBs
    unless ( $self->conf->{globalStorage} ) {
        $self->error(
            'globalStorage not defined (perhaps configuration can not be read)'
        );
        return $self->fail;
    }

    # Initialize persistent session DB
    unless ( $self->conf->{persistentStorage} ) {
        $self->conf->{persistentStorage} = $self->conf->{globalStorage};
        $self->conf->{persistentStorageOptions} =
          $self->conf->{globalStorageOptions};
    }

    # Initialize cookie domain
    unless ( $self->conf->{domain} ) {
        $self->error('Configuration error: no domain');
        return $self->fail;
    }
    $self->conf->{domain} =~ s/^([^\.])/.$1/;

    # Initialize cookie SameSite value
    $self->cookieSameSite( getSameSite( $self->conf ) );
    $self->logger->debug(
        "Cookies will use SameSite=" . $self->cookieSameSite );

    # Load menu
    # ---------
    $self->menu( $self->loadPlugin('::Main::Menu') );
    $self->displayInit;

    # Load authentication/userDB
    # --------------------------
    my $mod;
    for my $type (qw(authentication userDB)) {
        unless ( $self->conf->{$type} ) {
            $self->error("$type is not set");
            return $self->fail;
        }
        $mod = $self->conf->{$type}
          unless ( $self->conf->{$type} eq 'Same' );
        my $module = '::' . ucfirst($type) . '::' . $mod;
        $module =~ s/Authentication/Auth/;

        # Launch and initialize module
        return $self->fail
          unless ( $self->{"_$type"} = $self->loadPlugin($module) );
    }

    # Load second-factor engine
    return $self->fail
      unless $self->{_sfEngine} =
      $self->loadPlugin( $self->conf->{'sfEngine'} );

    # Load Captcha module
    return $self->fail
      unless $self->_captcha(
        $self->loadPlugin(
            $self->conf->{'captcha'} || '::Captcha::SecurityImage'
        )
      );

    # Compile macros in _macros, groups in _groups
    foreach my $type (qw(macros groups)) {
        $self->{"_$type"} = {};
        if ( $self->conf->{$type} ) {
            for my $name ( sort keys %{ $self->conf->{$type} } ) {
                my $sub =
                  HANDLER->buildSub(
                    HANDLER->substitute( $self->conf->{$type}->{$name} ) );
                if ($sub) {
                    $self->{"_$type"}->{$name} = $sub;
                }
                else {
                    $self->logger->error( "$type $name returns an error: "
                          . HANDLER->tsv->{jail}->error );
                }
            }
        }
    }
    $self->{_jsRedirect} =
      HANDLER->buildSub( HANDLER->substitute( $self->conf->{jsRedirect} ) )
      or $self->logger->error(
        'jsRedirect returns an error: ' . HANDLER->tsv->{jail}->error );

    # Load plugins
    foreach my $plugin ( $self->enabledPlugins ) {
        $self->loadPlugin($plugin) or return $self->fail;
    }

    # Initialize trusted domain regexp
    if (    $self->conf->{trustedDomains}
        and $self->conf->{trustedDomains} =~ /^\s*\*\s*$/ )
    {
        $self->trustedDomainsRe(qr#^https?://#);
    }
    else {
        my $re = Regexp::Assemble->new();
        if ( my $td = $self->conf->{trustedDomains} ) {
            $td =~ s/^\s*(.*?)\s*/$1/;
            foreach ( split( /\s+/, $td ) ) {
                next unless ($td);
                s#^\.#([^/]+\.)?#;
                $self->logger->debug("Domain $_ added in trusted domains");
                s/\./\\./g;

                # This regexp is valid for the followings hosts:
                #  - $td
                #  - $domainlabel.$td
                # $domainlabel is build looking RFC2396
                # (see Regexp::Common::URI::RFC2396)
                $_ =~
                  s/\*\\\./(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9]\\.)*/g;
                $re->add("$_");
            }
        }
        foreach ( @{ $self->{additionalTrustedDomains} },
            $self->conf->{portal} )
        {
            my $p = $_;
            $p =~ s#https?://([^/]*).*$#$1#;
            $re->add( quotemeta($p) );
        }

        foreach my $vhost ( keys %{ $self->conf->{locationRules} } ) {
            my $expr = quotemeta($vhost);

            # Handle wildcards
            if ( $vhost =~ /[\%\*]/ ) {
                $expr =~ s/\\\*/[A-Za-z0-9\-\.]\*/;
                $expr =~ s/\\\%/[A-Za-z0-9\-]\*/;
            }
            $re->add($expr);
            $self->logger->debug("Vhost $vhost added in trusted domains");
            $self->conf->{vhostOptions} ||= {};
            if ( my $tmp =
                $self->conf->{vhostOptions}->{$vhost}->{vhostAliases} )
            {
                foreach my $alias ( split /\s+/, $tmp ) {
                    $self->logger->debug(
                        "Alias $alias added in trusted domains");
                    $re->add( quotemeta($alias) );
                }
            }
        }

        my $tmp = '^https?://' . $re->as_string . '(?::\d+)?(?:/|$)';
        $self->trustedDomainsRe(qr/$tmp/);

    }

    # Clean $req->pdata after authentication
    push @{ $self->endAuth }, sub {
        my $tmp = $_[0]->pdata->{keepPdata} //= [];
        foreach my $k ( keys %{ $_[0]->pdata } ) {
            unless ( grep { $_ eq $k } @$tmp ) {
                $self->logger->debug("Removing $k from pdata");
                delete $_[0]->pdata->{$k};
            }
        }
        my $user_log = $_[0]->{sessionInfo}->{ $self->conf->{whatToTrace} };
        $self->userLogger->notice( $user_log . ' connected' ) if $user_log;
        if (@$tmp) {
            $self->logger->debug(
                'Add ' . join( ',', @$tmp ) . ' in keepPdata' );
            $_[0]->pdata->{keepPdata} = $tmp;
        }
        return PE_OK;
    };
    unshift @{ $self->beforeAuth }, sub {
        if ( $_[0]->param('cancel') ) {
            $self->logger->debug('Cancel called, push authCancel calls');
            unshift @{ $_[0]->steps }, @{ $self->authCancel };
            return PE_OK;
        }
    };
    my $portal = $self->conf->{portal};
    $portal =~ s#^https?://(.*?)(?:[:/].*)?$#$1#;
    HANDLER->tsv->{defaultCondition}->{$portal} ||= sub { 1 };

    1;
}

# Method used to load plugins
sub loadPlugin {
    my ( $self, $plugin ) = @_;
    unless ($plugin) {
        require Carp;
        Carp::confess('Calling loadPugin without arg !');
    }
    my $obj;
    return 0
      unless ( $obj = $self->loadModule("$plugin") );
    return $self->findEP( $plugin, $obj );
}

# Insert declared entry points into corresponding arrays
sub findEP {
    my ( $self, $plugin, $obj ) = @_;

    # Standards entry points
    foreach my $sub (@entryPoints) {
        if ( $obj->can($sub) ) {
            $self->logger->debug(" Found $sub entry point:");
            if ( my $callback = $obj->$sub ) {
                push @{ $self->{$sub} }, sub {
                    eval {
                        $obj->logger->debug("Launching ${plugin}::$callback");
                    };
                    $obj->$callback(@_);
                };
                $self->logger->debug("  -> $callback");
            }
        }
    }
    if ( $obj->can('afterSub') ) {
        $self->logger->debug("Found afterSub in $plugin");
        my $h = $obj->afterSub;
        unless ( ref $h and ref($h) eq 'HASH' ) {
            $self->logger->error(
                '"afterSub" endpoint must be a hashref, skipped');
        }
        else {
            foreach my $ep ( keys %$h ) {
                my $callback = $h->{$ep};
                push @{ $self->afterSub->{$ep} }, sub {
                    eval {
                        $obj->logger->debug(
                            "Launching ${plugin}::$callback afterSub $ep");
                    };
                    $obj->$callback(@_);
                };
            }
        }
    }
    if ( $obj->can('aroundSub') ) {
        $self->logger->debug("Found aroundSub in $plugin");
        my $h = $obj->aroundSub;
        unless ( ref $h and ref($h) eq 'HASH' ) {
            $self->logger->error(
                '"aroundSub" endpoint must be a hashref, skipped');
        }
        else {
            foreach my $ep ( keys %$h ) {
                my $callback    = $h->{$ep};
                my $previousSub = $self->aroundSub->{$ep} ||= sub {
                    $self->logger->debug(
                        "$ep launched inside ${plugin}::$callback");
                    $self->$ep(@_);
                };
                $self->aroundSub->{$ep} = sub {
                    $self->logger->debug(
                        "Launching ${plugin}::$callback instead of $ep");
                    $obj->$callback( $previousSub, @_ );
                };
            }
        }
    }
    if ( $obj->can('hook') ) {
        $self->logger->debug("Found hook in $plugin");
        my $h = $obj->hook;
        unless ( ref $h and ref($h) eq 'HASH' ) {
            $self->logger->error('"hook" endpoint must be a hashref, skipped');
        }
        else {
            foreach my $hookname ( keys %$h ) {
                my $callback = $h->{$hookname};
                push @{ $self->hook->{$hookname} }, sub {
                    eval {
                        $obj->logger->debug(
                            "Launching ${plugin}::$callback on hook $hookname");
                    };
                    $obj->$callback(@_);
                };
            }
        }
    }
    $self->logger->debug("Plugin $plugin initialized");

    # Rules for menu
    if ( $obj->can('spRules') ) {
        foreach my $k ( keys %{ $obj->{spRules} } ) {
            $self->logger->info(
"$k is defined more than one time, it can have some bad effects on Menu display"
            ) if ( $self->spRules->{$k} );
            $self->spRules->{$k} = $obj->{spRules}->{$k};
        }
    }
    return $obj;
}

sub loadModule {
    my ( $self, $module, $conf, %args ) = @_;
    $conf //= $self->conf;
    my $obj;
    $module = "Lemonldap::NG::Portal$module" if ( $module =~ /^::/ );

    eval "require $module";
    if ($@) {
        $self->logger->error("$module load error: $@");
        return 0;
    }
    eval {
        $obj = $module->new( { p => $self, conf => $conf, %args } );
        $self->logger->debug("Module $module loaded");
    };
    if ($@) {
        $self->logger->error("Unable to build $module object: $@");
        return 0;
    }
    unless ($obj) {
        $self->logger->error("$module new() method returned undef");
        return 0;
    }
    if ( $obj->can("init") and ( !$obj->init ) ) {
        $self->logger->error("$module init failed");
        return 0;
    }

    $self->loadedModules->{$module} = $obj;
    return $obj;
}

sub fail {
    $_[0]->userLogger->error( $_[0]->error );
    $_[0]->addUnauthRoute( '*' => 'displayError' );
    $_[0]->addAuthRoute( '*' => 'displayError' );
    return 0;
}

sub displayError {
    my ( $self, $req ) = @_;
    return $self->sendError( $req,
        'Portal error, contact your administrator', 500 );
}

# This helper method builds a rule from a string expression
# - $rule: rule text
# - $ruleDesc optional hint of what the rule is for, to display in error message
# returns undef if the rule syntax was invalid
sub buildRule {
    my ( $self, $rule, $ruleDesc ) = @_;
    if ($ruleDesc) {
        $ruleDesc = " $ruleDesc ";
    }
    else {
        $ruleDesc = " ";
    }
    my $compiledRule =
      $self->HANDLER->buildSub( $self->HANDLER->substitute($rule) );
    unless ($compiledRule) {
        my $error =
          $self->HANDLER->tsv->{jail}->error || 'Unable to compile rule';
        $self->logger->error( "Bad" . $ruleDesc . "rule: " . $error );
    }
    return $compiledRule,;
}

1;
