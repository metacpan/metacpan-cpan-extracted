##@class Lemonldap::NG::Portal::Main::Init
# Initialization part of Lemonldap::NG portal
#
# 2 public methods:
#  - init():       launch at startup. Load 'portal' section of lemonldap-ng.ini,
#                  initialize default route and launch reloadConf()
#  - reloadConf(): (re)load configuration using localConf (ie 'portal' section
#                  of lemonldap-ng.ini) and underlying handler configuration
package Lemonldap::NG::Portal::Main::Init;

our $VERSION = '2.21.0';

package Lemonldap::NG::Portal::Main;

use strict;
use Mouse;
use Regexp::Assemble;
use Lemonldap::NG::Common::Util qw(getSameSite);
use URI;
use Lemonldap::NG::Portal;
use MIME::Base64;
use Digest::SHA;

# PROPERTIES

# Configuration storage
has localConfig => ( is => 'rw', default => sub { {} } );
has conf        => ( is => 'rw', default => sub { {} } );
has trOver      => ( is => 'rw', default => sub { { all => {} } } );

# Sub modules
has _authentication => ( is => 'rw' );
has _userDB         => ( is => 'rw' );
has _passwordDB     => ( is => 'rw' );

has _loadedServices => ( is => 'rw', default => sub { {} } );

# Legacy
sub _captcha        { $_[0]->getService('captcha') }
sub _trustedBrowser { $_[0]->getService('trustedBrowser') }
sub _sfEngine       { $_[0]->getService('secondFactor') }
sub menu            { $_[0]->getService('menu') }

has _ppRules => ( is => 'rw', default => sub { {} } );

has loadedModules => ( is => 'rw' );

# Macros and groups
has _macros     => ( is => 'rw' );
has _groups     => ( is => 'rw' );
has _jsRedirect => ( is => 'rw' );

# TrustedDomain regexp
has trustedDomainsRe         => ( is => 'rw' );
has additionalTrustedDomains => ( is => 'rw', default => sub { [] } );

has cacheTag => ( is => 'rw' );

# Entrypoints
has _pluginEntryPoints =>
  ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

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
has afterSub  => ( is => 'rw', default => sub { {} } );
has aroundSub => ( is => 'rw', default => sub { {} } );

# Issuer hooks
has hook => ( is => 'rw', default => sub { {} } );

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

sub _resetPluginsAndServices {
    my ($self) = @_;
    $self->loadedModules( {} );
    $self->_loadedServices( {} );
    $self->afterSub( {} );
    $self->aroundSub( {} );
    $self->spRules( {} );
    $self->hook( {} );
    $self->pluginSessionDataToRemember( {} );
    $self->_pluginEntryPoints( [] );

    # Reinitialize arrays
    foreach ( qw(_macros _groups), @entryPoints ) {
        $self->{$_} = [];
    }
}

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
        elsif ( $k =~ /msg_(?:([a-z][a-z](?:_[A-Z][A-Z])?)_)?(\w+)$/ ) {
            my $lang = $1 || 'all';
            $self->trOver->{$lang}->{$2} = $self->localConfig->{$k};
        }
        else {
            $self->conf->{$k} = $self->localConfig->{$k};
        }
    }
    $self->trOver( JSON::to_json( $self->trOver ) );

    # Purge loaded module list
    $self->_resetPluginsAndServices;

    # Insert `reloadConf` in handler reload stack
    Lemonldap::NG::Handler::Main->onReload( $self, 'reloadConf' );

    # Register logout event (unlog event is only a local unlog: clean cache)
    &Lemonldap::NG::Handler::Main::MsgActions::addMsgAction(
        'logout',
        sub {
            my ( $class, $id, $req ) = @_;
            return $self->eventLogout( $req, $id );
        }
    );

    # Handler::PSGI::Try initialization
    unless ( $self->SUPER::init( $self->localConfig ) ) {
        $self->logger->error( 'Initialization failed: ' . $self->error );
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

    # Store default portal value in $self->portal
    $self->portal( Lemonldap::NG::Handler::Main->tsv->{portal}->() );

    # Handle requests (other path may be declared in enabled plugins)
    $self->setPortalRoutes;

    # Reinitialize $self->conf
    %{ $self->{conf} } = %{ $self->localConfig };

    # Purge loaded module list
    $self->_resetPluginsAndServices;

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

    $self->{staticPrefix} = $self->conf->{staticPrefix} || '/static';
    $self->{languages}    = $self->conf->{languages}    || 'en';

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

    # Initialize cookie SameSite value
    $self->cookieSameSite( getSameSite( $self->conf ) );
    $self->logger->debug(
        "Cookies will use SameSite=" . $self->cookieSameSite );

    # Load menu
    # ---------
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

    # Load services
    foreach my $service ( $self->enabledServices ) {
        $self->loadService(@$service) or return $self->fail;
    }

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
        my $default_portal = HANDLER->tsv->{portal}->();
        foreach ( @{ $self->{additionalTrustedDomains} }, $default_portal ) {
            my $p = $_;
            $p =~ s#https?://([^/]*).*$#$1#;
            $re->add( quotemeta($p) );
        }

        foreach my $vhost ( sort keys %{ $self->conf->{locationRules} } ) {
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
        my $user_log    = $_[0]->{sessionInfo}->{ $self->conf->{whatToTrace} };
        my $auth_module = $_[0]->{sessionInfo}->{_auth};
        my $ipAddr      = $_[0]->{sessionInfo}->{ipAddr};

        if ($user_log) {
            $self->auditLog(
                $_[0],
                message => (
                        "User "
                      . $user_log
                      . " connected from $auth_module ($ipAddr)"
                ),
                code => "LOGIN",
                user => $user_log,
            );
        }
        if (@$tmp) {
            $self->logger->debug(
                'Add ' . join( ',', @$tmp ) . ' in keepPdata' );
            $_[0]->pdata->{keepPdata} = $tmp;
        }
        return PE_OK;
    };

    # Failsafe: allow handler access to portal in case it's missing in conf
    my $default_portal_uri  = URI->new( HANDLER->tsv->{portal}->() );
    my $default_portal_host = eval { $default_portal_uri->host };
    if ($default_portal_host) {
        HANDLER->tsv->{defaultCondition}->{$default_portal_host} ||= sub { 1 };
    }

    # Set asset tag from version and optional salt
    my $cacheTagSalt = $self->conf->{cacheTagSalt} // "";
    my $key          = $self->conf->{key}          // "";
    my $digest       = substr(
        MIME::Base64::encode_base64url(
            Digest::SHA::hmac_sha256(
                $Lemonldap::NG::Portal::VERSION . $cacheTagSalt, $key
            )
        ),
        0, 8
    );
    $self->cacheTag($digest);

    1;
}

# Method used to load plugins

sub loadService {
    my ( $self, $name, $plugin ) = @_;
    $self->logger->debug("Loading service $name from $plugin");
    return $self->_loadedServices->{$name} = $self->loadPlugin($plugin);
}

sub getService {
    my ( $self, $name ) = @_;
    return $_[0]->_loadedServices->{$name};
}

sub loadPlugin {
    my ( $self, $plugin ) = @_;
    unless ($plugin) {
        require Carp;
        Carp::confess('Calling loadPugin without arg!');
    }

    my $full_name =
      ( $plugin =~ /^::/ ) ? "Lemonldap::NG::Portal$plugin" : $plugin;
    if (
        grep {
            my $item_full_name =
              ( $_ =~ /^::/ ) ? "Lemonldap::NG::Portal$_" : $_;
            $item_full_name eq $full_name
        } split( /[\s,]+/, $self->conf->{disabledPlugins} // "" )
      )
    {
        $self->logger->debug(
            "Module $plugin is disallowed by disabledPlugins and was not loaded"
        );
        return 1;
    }

    return 0 unless ( my $obj = $self->loadModule($plugin) );
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

    # Rules for menu
    if ( $obj->can('spRules') ) {
        foreach my $k ( keys %{ $obj->spRules } ) {
            $self->logger->info(
"$k is defined more than one time, it can have some bad effects on Menu display"
            ) if ( $self->spRules->{$k} );
            $self->spRules->{$k} = $obj->spRules->{$k};
        }
    }

    # Plugin entrypoints
    for my $ep ( @{ $self->_pluginEntryPoints } ) {
        if (   ( $ep->{can} and $obj->can( $ep->{can} ) )
            or ( $ep->{isa}  and $obj->isa( $ep->{isa} ) )
            or ( $ep->{does} and $obj->does( $ep->{does} ) ) )
        {
            my @args = @{ $ep->{args} || [] };
            if ( my $callback = $ep->{callback} ) {
                $self->logger->debug(
                    "Invoking callback registered by $ep->{_pkg}");
                $callback->( $obj, @args );
            }
            elsif ( $ep->{service} && $ep->{method} ) {
                my $service = $self->getService( $ep->{service} );
                if ($service) {
                    if ( my $method = $service->can( $ep->{method} ) ) {
                        $self->logger->debug(
                                "Invoking $ep->{method} on $ep->{service}"
                              . " on behalf of $ep->{_pkg}" );
                        $service->$method( $obj, @args );
                    }
                    else {
                        $self->logger->warn(
                            "Service $ep->{service} has no $ep->{method} method"
                              . " in entrypoint added by $ep->{_pkg}" );
                    }
                }
                else {
                    $self->logger->warn(
                            "Could not find service $ep->{service}"
                          . " in entrypoint added by $ep->{_pkg}" );
                }
            }
        }
    }

    $self->logger->debug("Plugin $plugin initialized");

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
        $self->error("$module load error: $@");
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
        $self->error("$module init failed");
        return 0;
    }

    $self->loadedModules->{$module} = $obj;
    return $obj;
}

sub fail {
    $_[0]->logger->error( $_[0]->error );
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
    $ruleDesc ||= '';
    my $compiledRule =
      $self->HANDLER->buildSub( $self->HANDLER->substitute($rule) );
    unless ($compiledRule) {
        my $error =
          $self->HANDLER->tsv->{jail}->error || 'Unable to compile rule';
        $self->logger->error("Bad $ruleDesc rule: $error");
        return undef;
    }

    # Avoid deep recursion
    my $overLoadedRule = $compiledRule;
    if ( $self->conf->{logParams} ) {
        $overLoadedRule = sub {
            $self->_dump($_[0]);
            return $compiledRule->(@_);
        };
    }
    return $overLoadedRule;
}

sub addPasswordPolicyDisplay {
    my ( $self, $id, $options ) = @_;
    $self->_ppRules->{$id} = {%$options};
}

sub _addPluginEntryPoint {
    my ( $self, %entryPointDescription ) = @_;
    push @{ $self->_pluginEntryPoints },
      { _pkg => "[unknown]", %entryPointDescription };
}

1;
