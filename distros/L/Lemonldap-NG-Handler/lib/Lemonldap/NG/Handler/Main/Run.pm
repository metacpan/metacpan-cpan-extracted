# Main running methods file
package Lemonldap::NG::Handler::Main::Run;

our $VERSION = '2.0.15';

package Lemonldap::NG::Handler::Main;

use strict;

#use AutoLoader 'AUTOLOAD';
use MIME::Base64;
use URI::Escape;
use Lemonldap::NG::Common::Session;

# Methods that must be overloaded

sub handler {
    die "Must be overloaded" unless ($#_);
    my ($res) = $_[0]->run( $_[1] );
    return $res;
}

sub logout {
    my $class;
    $class = $#_ ? shift : __PACKAGE__;
    return $class->unlog(@_);
}

sub status {
    my $class;
    $class = $#_ ? shift : __PACKAGE__;
    return $class->getStatus(@_);
}

# Public methods

# Return Handler::Lib::Status output
sub getStatus {
    my ( $class, $req ) = @_;
    $class->logger->debug("Request for status");
    my $statusPipe = $class->tsv->{statusPipe};
    my $statusOut  = $class->tsv->{statusOut};
    my $args       = '';
    if ( $ENV{LLNGSTATUSHOST} ) {
        require IO::Socket::INET;
        foreach ( 64322 .. 64331 ) {
            if ( $statusOut =
                IO::Socket::INET->new( Proto => 'udp', LocalPort => $_ ) )
            {
                $args =
                  ' host=' . ( $ENV{LLNGSTATUSCLIENT} || 'localhost' ) . ":$_";
                last;
            }
        }
        return $class->abort( $req,
            "$class: status page can not be displayed, unable to open socket" )
          unless ($statusOut);
    }
    return $class->abort( $req, "$class: status page can not be displayed" )
      unless ( $statusPipe and $statusOut );
    my $q = $req->{env}->{QUERY_STRING} || '';
    if ( $q =~ /\s/ ) {
        $class->logger->error("Bad characters in query");
        return $class->FORBIDDEN;
    }
    $statusPipe->print(
        "STATUS " . ( $req->{env}->{QUERY_STRING} || '' ) . "$args\n" );
    my $buf;

    while ( $_ = $statusOut->getline ) {
        last if (/^END$/);
        $buf .= $_;
    }
    $class->set_header_out( $req,
        "Content-Type" => "text/html; charset=UTF-8" );
    $class->print( $req, $buf );
    return $class->OK;
}

# Method that must be called by base packages (Handler::ApacheMP2,...) to get
# type of handler to call (Main, AuthBasic,...)
sub checkType {
    my ( $class, $req ) = @_;

    if ( time() - $class->lastCheck > $class->checkTime ) {
        unless ( $class->checkConf ) {
            $class->logger->error("$class: No configuration found");
            $req->data->{noTry} = 1;
            return 'Fail';
        }
    }
    my $vhost = $class->resolveAlias($req);
    return ( defined $class->tsv->{type}->{$vhost} )
      ? $class->tsv->{type}->{$vhost}
      : 'Main';
}

## @rmethod int run
# Check configuration and launch Lemonldap::NG::Handler::Main::run().
# Each $checkTime, server child verifies if its configuration is the same
# as the configuration stored in the local storage.
# @param $rule optional Perl expression to grant access
# @return constant

sub run {
    my ( $class, $req, $rule, $protection ) = @_;
    my ( $id, $session );
    my $vhost = $class->resolveAlias($req);

    return $class->DECLINED unless ( $class->is_initial_req($req) );

    # Direct return if maintenance mode is enabled
    if ( $class->checkMaintenanceMode($req) ) {

        if ( $class->tsv->{useRedirectOnError} ) {
            $class->logger->debug("Go to portal with maintenance error code");
            return $class->goToError( $req, '/', $class->MAINTENANCE );
        }
        else {
            $class->logger->debug("Return maintenance error code");
            return $class->MAINTENANCE;
        }
    }

    # Authentication process
    my $uri = $req->{env}->{REQUEST_URI};
    my ($cond);

    ( $cond, $protection ) = $class->conditionSub($rule) if ($rule);
    $protection = $class->isUnprotected( $req, $uri ) || 0
      unless ( defined $protection );

    if ( $protection == $class->SKIP ) {
        $class->logger->debug("Access control skipped");
        $class->updateStatus( $req, 'SKIP' );
        $class->hideCookie($req);
        $class->cleanHeaders($req);
        return $class->OK;
    }

    # Try to recover cookie and user session
    $id = $class->fetchId($req);
    $class->data( {} ) unless ($id);
    if (    $id
        and $session = $class->retrieveSession( $req, $id ) )
    {

        # AUTHENTICATION done

        # Local macros
        my $kc = keys %{$session};    # in order to detect new local macro

        # ACCOUNTING (1. Inform web server)
        $class->set_user( $req, $session->{ $class->tsv->{whatToTrace} } );

        my $custom;
        $custom = $session->{ $class->tsv->{customToTrace} }
          if (  $class->tsv->{customToTrace}
            and $session->{ $class->tsv->{customToTrace} } );
        if ( $class->tsv->{accessToTrace}->{$vhost} ) {
            my ( $function, @params ) = split /\s*,\s*/,
              $class->tsv->{accessToTrace}->{$vhost};
            if ( $function =~ qr/^(?:\w+(?:::\w+)*(?:\s+\w+(?:::\w+)*)*)?$/ ) {
                my $c = eval {
                    no strict 'refs';
                    &{$function}( {
                            req     => $req,
                            vhost   => $vhost,
                            session => $session,
                            custom  => $custom,
                            params  => \@params
                        }
                    );
                };
                if ($@) {
                    $class->logger->error(
                        "Failed to overwrite customToTrace: $@");
                }
                else {
                    $class->logger->debug("Overwrite customToTrace with: $c");
                    $custom = $c;
                }
            }
            else {
                $class->logger->error(
                    "accessToTrace: Bad custom function name");
            }
        }
        $class->set_custom( $req, $custom ) if $custom;

        # AUTHORIZATION
        return ( $class->forbidden( $req, $session ), $session )
          unless ( $class->grant( $req, $session, $uri, $cond ) );
        $class->updateStatus( $req, 'OK',
            $session->{ $class->tsv->{whatToTrace} } );

        # ACCOUNTING (2. Inform remote application)
        $class->sendHeaders( $req, $session );

        # Store local macros
        if ( keys %$session > $kc ) {
            $class->logger->debug("Update local cache");
            $req->data->{session}->update( $session, { updateCache => 2 } );
        }

        # Hide Lemonldap::NG cookie
        $class->hideCookie($req);

        # Log access granted
        $class->logger->debug( "User "
              . $session->{ $class->tsv->{whatToTrace} }
              . " was granted to access to $uri" );

        #  Catch POST rules
        $class->postOutputFilter( $req, $session, $uri );
        $class->postInputFilter( $req, $session, $uri );

        return ( $class->OK, $session );
    }

    elsif ( $protection == $class->UNPROTECT ) {

        # Ignore unprotected URIs
        $class->logger->debug("No valid session but unprotected access");
        $class->updateStatus( $req, 'UNPROTECT' );
        $class->hideCookie($req);
        $class->cleanHeaders($req);
        return $class->OK;
    }

    elsif ( $protection == $class->MAYSKIP
        and $class->grant( $req, $session, $uri, $cond ) eq '999_SKIP' )
    {
        $class->logger->debug("Access control skipped");
        $class->updateStatus( $req, 'SKIP' );
        $class->hideCookie($req);
        $class->cleanHeaders($req);
        return $class->OK;
    }

    else {

        # Redirect user to the portal
        $class->logger->info("No cookie found")
          unless ($id);

        # if the cookie was fetched, a log is sent by retrieveSession()
        $class->updateStatus( $req, $id ? 'EXPIRED' : 'REDIRECT' );
        return $class->goToPortal( $req, $req->{env}->{REQUEST_URI} );
    }
}

## @rmethod protected int unlog()
# Call localUnlog() then goToPortal() to unlog the current user.
# @return Constant value returned by goToPortal()
sub unlog {
    my ( $class, $req ) = @_;
    $class->localUnlog( $req, @_ );
    $class->updateStatus( $req, 'LOGOUT' );
    return $class->goToPortal( $req, '/', 'logout=1' );
}

# INTERNAL METHODS

## @rmethod protected void updateStatus(string action,string user,string url)
# Inform the status process of the result of the request if it is available
# @param action string Result of access control (as $class->OK, $class->SKIP, LOGOUT...)
# @param optional user string Username to log, if undefined defaults to remote IP
# @param optional url string URL to log, if undefined defaults to request URI
sub updateStatus {
    my ( $class, $req, $action, $user, $url ) = @_;
    my $statusPipe = $class->tsv->{statusPipe} or return;
    $user ||= $req->{env}->{REMOTE_ADDR};
    $url  ||= $req->{env}->{REQUEST_URI};
    eval {
        $statusPipe->print(
            "$user => " . $req->{env}->{HTTP_HOST} . "$url $action\n" );
    };
}

## @rmethod void lmLog(string msg, string level)
# Wrapper for Apache log system
# @param $msg message to log
# @param $level string (emerg|alert|crit|error|warn|notice|info|debug)
sub lmLog {
    my ( $class, $msg, $level ) = @_;
    return $class->logger->$level($msg);
}

## @rmethod protected boolean checkMaintenanceMode
# Check if we are in maintenance mode
# @return true if maintenance mode is enabled
sub checkMaintenanceMode {
    my ( $class, $req ) = @_;
    my $vhost = $class->resolveAlias($req);
    my $_maintenance =
      ( defined $class->tsv->{maintenance}->{$vhost} )
      ? $class->tsv->{maintenance}->{$vhost}
      : $class->tsv->{maintenance}->{_};

    if ($_maintenance) {
        $class->logger->debug("Maintenance mode enabled");
        return 1;
    }
    return 0;
}

## @rmethod int getLevel(string uri, string $vhost)
# Return required authentication level for this URI
# default to vhost authentication level
# @param $uri URI
# @param $vhost vhost name, default to current request
sub getLevel {
    my ( $class, $req, $uri, $vhost ) = @_;
    my $level;
    $vhost ||= $class->resolveAlias($req);

    # Using URL authentification level if exists
    for (
        my $i = 0 ;
        $i < ( $class->tsv->{locationCount}->{$vhost} || 0 ) ;
        $i++
      )
    {
        if ( $uri && $uri =~ $class->tsv->{locationRegexp}->{$vhost}->[$i] ) {
            $level = $class->tsv->{locationAuthnLevel}->{$vhost}->[$i];
            last;
        }
    }
    if ($level) {
        $class->logger->debug("Found AuthnLevel=$level for \"$vhost$uri\"");
        return $level;
    }
    else {
        $class->logger->debug("No URL authentication level found...");
        return $class->tsv->{authnLevel}->{$vhost};
    }
}

## @rmethod boolean grant(string uri, string cond)
# Grant or refuse client using compiled regexp and functions
# @param $uri URI
# @param $cond optional Function granting access
# @return True if the user is granted to access to the current URL
sub grant {
    my ( $class, $req, $session, $uri, $cond, $vhost ) = @_;

    return $cond->( $req, $session ) if $cond;

    $vhost ||= $class->resolveAlias($req);
    my $level = $class->getLevel( $req, $uri );

    # Using VH authentification level if exists
    if ($level) {
        if ( $session->{authenticationLevel} < $level ) {
            $class->logger->debug(
                "User authentication level = $session->{authenticationLevel}");
            $class->logger->debug("Required authentication level = $level");
            $class->logger->warn(
                'User rejected due to insufficient authentication level');
            if ( $class->tsv->{upgradeSession} ) {
                $class->logger->warn(' -> Session upgrade enabled');
                $session->{_upgrade} = 1;
            }
            return 0;
        }
    }
    for (
        my $i = 0 ;
        $i < ( $class->tsv->{locationCount}->{$vhost} || 0 ) ;
        $i++
      )
    {
        if ( $uri =~ $class->tsv->{locationRegexp}->{$vhost}->[$i] ) {
            $class->logger->debug( 'Regexp "'
                  . $class->tsv->{locationConditionText}->{$vhost}->[$i]
                  . '" match' );
            return $class->tsv->{locationCondition}->{$vhost}->[$i]
              ->( $req, $session );
        }
    }
    unless ( $class->tsv->{defaultCondition}->{$vhost} ) {
        $class->logger->warn(
            "User rejected because VirtualHost \"$vhost\" has no configuration"
        );
        return 0;
    }
    $class->logger->debug("$vhost: Apply default rule");
    return $class->tsv->{defaultCondition}->{$vhost}->( $req, $session );
}

## @rmethod protected int forbidden(string uri)
# Used to reject non authorized requests.
# Inform the status process and call logForbidden().
# @param $uri URI
# @return Constant $class->FORBIDDEN
sub forbidden {
    my ( $class, $req, $session, $vhost ) = @_;
    my $uri    = $req->{env}->{REQUEST_URI};
    my $portal = $class->tsv->{portal}->();
    $portal = ( $portal =~ m#^https?://([^/]*).*# )[0];
    $portal =~ s/:\d+$//;
    $vhost ||= $class->resolveAlias($req);

    if ( $session->{_logout} ) {
        $class->updateStatus( $req, 'LOGOUT',
            $session->{ $class->tsv->{whatToTrace} } );
        my $u = $session->{_logout};
        $class->localUnlog($req);
        return $class->goToPortal( $req, $u, 'logout=1' );
    }

    if ( $session->{_upgrade} ) {
        return $class->goToPortal( $req, $uri, undef, '/upgradesession' );
    }

    # Log forbidding
    $class->userLogger->notice( "User "
          . $session->{ $class->tsv->{whatToTrace} }
          . " was forbidden to access to $vhost$uri" );
    $class->updateStatus( $req, 'REJECT',
        $session->{ $class->tsv->{whatToTrace} } );

    # Redirect or Forbidden?
    if ( $class->tsv->{useRedirectOnForbidden} && $vhost ne $portal ) {
        $class->logger->debug("Use redirect for forbidden access ");
        return $class->goToError( $req, $uri, 403 );
    }
    else {
        $class->logger->debug("Self protected Portal URL") if $vhost eq $portal;
        $class->logger->debug("Return forbidden access");
        return $class->FORBIDDEN;
    }
}

## @rmethod protected void hideCookie()
# Hide Lemonldap::NG cookie to the protected application.
sub hideCookie {
    my ( $class, $req ) = @_;
    $class->logger->debug("removing cookie");
    my $cookie = $req->env->{HTTP_COOKIE};
    $class->logger->debug("Cookies -> $cookie");
    my $cn = $class->tsv->{cookieName};
    $class->logger->debug("CookieName -> $cn");
    $cookie =~ s/\b$cn(http)?=[^,;]*[,;\s]*//og;
    $class->logger->debug("newCookies -> $cookie");

    if ($cookie) {
        $class->set_header_in( $req, 'Cookie' => $cookie );
    }
    else {
        $class->unset_header_in( $req, 'Cookie' );
    }
}

## @rmethod protected string encodeUrl(string url)
# Encode URL in the format used by Lemonldap::NG::Portal for redirections.
# @return Base64 encoded string
sub encodeUrl {
    my ( $class, $req, $url ) = @_;
    $url = $class->_buildUrl( $req, $url ) if ( $url !~ m#^https?://# );
    return uri_escape( encode_base64( $url, '' ) );
}

## @rmethod protected int goToPortal(string url, string arg)
# Redirect non-authenticated users to the portal by setting "Location:" header.
# @param $url Url requested
# @param $arg optionnal GET parameters
# @return Constant $class->REDIRECT
sub goToPortal {
    my ( $class, $req, $url, $arg, $path ) = @_;
    $path ||= '';
    my ( $ret, $msg );
    my $urlc_init = $class->encodeUrl( $req, $url );
    $class->logger->debug(
        "Redirect $req->{env}->{REMOTE_ADDR} to portal (url was $url)");
    $class->set_header_out( $req,
            'Location' => $class->tsv->{portal}->()
          . "$path?url=$urlc_init"
          . ( $arg ? "&$arg" : "" ) );
    return $class->REDIRECT;
}

sub goToError {
    my ( $class, $req, $url, $code ) = @_;
    my $urlc_init = $class->encodeUrl( $req, $url );
    $class->logger->debug(
        "Redirect $req->{env}->{REMOTE_ADDR} to lmError (url was $url)");
    $class->set_header_out( $req,
            'Location' => $class->tsv->{portal}->()
          . "/lmerror/$code"
          . "?url=$urlc_init" );
    return $class->REDIRECT;
}

## @rmethod protected fetchId()
# Get user cookies and search for Lemonldap::NG cookie.
# @return Value of the cookie if found, 0 else
sub fetchId {
    my ( $class, $req ) = @_;
    my $t     = $req->{env}->{HTTP_COOKIE} or return 0;
    my $vhost = $class->resolveAlias($req);
    $class->logger->debug("VH $vhost is HTTPS")
      if $class->_isHttps( $req, $vhost );
    my $lookForHttpCookie = ( $class->tsv->{securedCookie} =~ /^(2|3)$/
          and not $class->_isHttps( $req, $vhost ) );
    my $cn    = $class->tsv->{cookieName};
    my $value = $lookForHttpCookie    # Avoid prefix and bad cookie name (#2417)
      ? ( $t =~ /(?<![-.~])\b${cn}http=([^,; ]+)/o ? $1 : 0 )
      : ( $t =~ /(?<![-.~])\b$cn=([^,; ]+)/o       ? $1 : 0 );

    if ( $value && $lookForHttpCookie && $class->tsv->{securedCookie} == 3 ) {
        $value = $class->tsv->{cipher}->decryptHex( $value, "http" );
    }
    elsif ( $value =~ s/^c:// ) {
        $value = $class->tsv->{cipher}->decrypt($value);
        unless ( $value =~ s/^(.*)? (.*)$/$1/ and $2 eq $vhost ) {
            $class->userLogger->error(
                "Bad CDA cookie: available for $2 instead of $vhost");
            return undef;
        }
    }
    return $value;
}

## @rmethod protected boolean retrieveSession(id)
# Tries to retrieve the session whose index is id
# @return true if the session was found, false else
sub retrieveSession {
    my ( $class, $req, $id ) = @_;
    my $now = time();

    # 1. Search if the user was the same as previous (very efficient in
    # persistent connection).
    # NB: timout is here the same value as current HTTP/1.1 Keep-Alive timeout
    #     (15 seconds)
    if (    defined $class->data->{_session_id}
        and $id eq $class->data->{_session_id}
        and ( $now - $class->dataUpdate < $class->tsv->{handlerInternalCache} )
      )
    {
        $class->logger->debug("Get session $id from Handler internal cache");
        return $class->data;
    }
    else {
        $class->data( {} );
    }

    # 2. Get the session from cache or backend
    my $session = $req->data->{session} = (
        Lemonldap::NG::Common::Session->new( {
                storageModule        => $class->tsv->{sessionStorageModule},
                storageModuleOptions => $class->tsv->{sessionStorageOptions},
                cacheModule          => $class->tsv->{sessionCacheModule},
                cacheModuleOptions   => $class->tsv->{sessionCacheOptions},
                id                   => $id,
                kind                 => "SSO",
            }
        )
    );

    unless ( $session->error ) {

        $class->data( $session->data );
        $class->logger->debug("Get session $id from Handler::Main::Run");

        # Verify that session is valid
        $class->logger->error(
"_utime is not defined. This should not happen. Check if it is well transmitted to handler"
        ) unless $session->data->{_utime};

        $class->logger->debug("Check session validity from Handler");
        $class->logger->debug( "Session timeout -> " . $class->tsv->{timeout} );
        $class->logger->debug( "Session timeoutActivity -> "
              . $class->tsv->{timeoutActivity}
              . "s" )
          if ( $class->tsv->{timeoutActivity} );
        $class->logger->debug(
            "Session _utime -> " . $session->data->{_utime} );
        $class->logger->debug( "now -> " . $now );
        $class->logger->debug( "_lastSeen -> " . $session->data->{_lastSeen} )
          if ( $session->data->{_lastSeen} );
        my $delta = $now - $session->data->{_lastSeen}
          if ( $session->data->{_lastSeen} );
        $class->logger->debug( "now - _lastSeen = " . $delta )
          if ( $session->data->{_lastSeen} );
        $class->logger->debug( "Session timeoutActivityInterval -> "
              . $class->tsv->{timeoutActivityInterval} )
          if ( $class->tsv->{timeoutActivityInterval} );
        my $ttl = $class->tsv->{timeout} - $now + $session->data->{_utime};
        $class->logger->debug( "Session TTL = " . $ttl );

        if (
            $now - $session->data->{_utime} > $class->tsv->{timeout}
            or (    $class->tsv->{timeoutActivity}
                and $session->data->{_lastSeen}
                and $delta > $class->tsv->{timeoutActivity} )
          )
        {
            $class->logger->info("Session $id expired");

            # Clean cached data
            $class->data( {} );
            return 0;
        }

        # Update the session to notify activity, if necessary
        if (
            $class->tsv->{timeoutActivity}
            and ( $now - $session->data->{_lastSeen} >
                $class->tsv->{timeoutActivityInterval} )
          )
        {
            $req->data->{session}->update( { '_lastSeen' => $now } );
            $class->data( $session->data );

            if ( $session->error ) {
                $class->logger->error("Cannot update session $id");
                $class->logger->error( $req->data->{session}->error );
            }
            else {
                $class->logger->debug("Update _lastSeen with $now");
            }
        }

        $class->dataUpdate($now);
        return $session->data;
    }
    else {
        $class->logger->info("Session $id can't be retrieved");
        $class->logger->info( $session->error );

        return 0;
    }
}

## @cmethod private int _getPort(string s)
# Returns the port on which this vhost is accessed
# @param $s VHost name
# @return PORT
sub _getPort {
    my ( $class, $req, $vhost ) = @_;
    if ( defined $class->tsv->{port}->{$vhost}
        and ( $class->tsv->{port}->{$vhost} > 0 ) )
    {
        return $class->tsv->{port}->{$vhost};
    }
    else {
        return ( defined $class->tsv->{port}->{_}
              and ( $class->tsv->{port}->{_} > 0 ) )
          ? $class->tsv->{port}->{_}
          : $req->port;
    }
}

## @cmethod private bool _isHttps(string s)
# Returns whether this VHost should be accessed
# via HTTPS
# @param $s VHost name
# @return TRUE if the vhost should be accessed over HTTPS
sub _isHttps {
    my ( $class, $req, $vhost ) = @_;
    if ( defined $class->tsv->{https}->{$vhost}
        and ( $class->tsv->{https}->{$vhost} > -1 ) )
    {
        return $class->tsv->{https}->{$vhost};
    }
    else {
        return ( defined $class->tsv->{https}->{_}
              and ( $class->tsv->{https}->{_} > -1 ) )
          ? $class->tsv->{https}->{_}
          : $req->secure;
    }
}

## @cmethod private string _buildUrl(string s)
# Transform /<s> into http(s?)://<host>:<port>/s
# @param $s path
# @return URL
sub _buildUrl {
    my ( $class, $req, $s ) = @_;
    my $realvhost  = $req->{env}->{HTTP_HOST};
    my $vhost      = $class->resolveAlias($req);
    my $_https     = $class->_isHttps( $req, $vhost );
    my $portString = $class->_getPort( $req, $vhost );
    $portString = (
             ( $realvhost =~ /:\d+/ )
          or ( $_https  && $portString == 443 )
          or ( !$_https && $portString == 80 )
    ) ? '' : ":$portString";
    my $url = "http" . ( $_https ? "s" : "" ) . "://$realvhost$portString$s";
    $class->logger->debug("Build URL $url");
    return $url;
}

## @rmethod protected int isUnprotected()
# @param $uri URI
# @return 0 if URI is protected,
# $class->UNPROTECT if it is unprotected by "unprotect",
# SKIP if unprotected by "skip"
sub isUnprotected {
    my ( $class, $req, $uri ) = @_;
    my $vhost = $class->resolveAlias($req);
    for (
        my $i = 0 ;
        $i < ( $class->tsv->{locationCount}->{$vhost} || 0 ) ;
        $i++
      )
    {
        return $class->tsv->{locationProtection}->{$vhost}->[$i]
          if ( $uri =~ $class->tsv->{locationRegexp}->{$vhost}->[$i] );
    }
    return $class->tsv->{defaultProtection}->{$vhost};
}

## @rmethod void sendHeaders()
# Launch function compiled by headersInit() for the current virtual host
sub sendHeaders {
    my ( $class, $req, $session ) = @_;
    my $vhost = $class->resolveAlias($req);
    if ( defined $class->tsv->{forgeHeaders}->{$vhost} ) {

        # Log headers in debug mode
        my %headers =
          $class->tsv->{forgeHeaders}->{$vhost}->( $req, $session );
        foreach my $h ( sort keys %headers ) {
            if ( defined( my $v = $headers{$h} ) ) {
                $class->logger->debug("Send header '$h' with value '$v'");
            }
            else {
                $class->logger->debug("Send header '$h' with an empty value");
            }
        }
        $class->set_header_in( $req, %headers );
    }
}

## @rfunction array ref checkHeaders()
# Return computed headers by headersInit() for the current virtual host
# [ { key => 'header1', value => 'value1' }, { key => 'header2', value => 'value2' }, ...]
sub checkHeaders {
    my ( $class, $req, $session ) = @_;
    my $vhost         = $class->resolveAlias($req);
    my $array_headers = [];
    if ( defined $class->tsv->{forgeHeaders}->{$vhost} ) {

        # Create array of hashes with headers
        my %headers =
          $class->tsv->{forgeHeaders}->{$vhost}->( $req, $session );
        foreach my $h ( sort keys %headers ) {
            defined $headers{$h}
              ? push @$array_headers, { key => $h, value => $headers{$h} }
              : push @$array_headers, { key => $h, value => '' };
        }
    }
    return $array_headers;
}

## @rmethod void cleanHeaders()
# Unset HTTP headers, when sendHeaders is skipped
sub cleanHeaders {
    my ( $class, $req ) = @_;
    my $vhost = $class->resolveAlias($req);
    if ( defined( $class->tsv->{headerList}->{$vhost} ) ) {
        $class->logger->debug("Remove headers relative to $vhost");
        $class->unset_header_in( $req,
            @{ $class->tsv->{headerList}->{$vhost} } );
    }
}

## @rmethod string resolveAlias
# returns vhost whose current hostname is an alias
sub resolveAlias {
    my ( $class, $req ) = @_;
    my $vhost = ref $req ? $req->{env}->{HTTP_HOST} : $req;

    $vhost =~ s/:\d+//;
    return $class->tsv->{vhostAlias}->{$vhost}
      if $class->tsv->{vhostAlias}->{$vhost};
    return $vhost if $class->tsv->{defaultCondition}->{$vhost};
    foreach ( @{ $class->tsv->{vhostReg} } ) {
        return $_->[1] if $vhost =~ $_->[0];
    }
    return $vhost;
}

#__END__

## @rmethod int abort(string msg)
# Logs message and exit or redirect to the portal if "useRedirectOnError" is
# set to true.
# @param $msg Message to log
# @return Constant ($class->REDIRECT, $class->SERVER_ERROR)
sub abort {
    my ( $class, $req, $msg ) = @_;

    # If abort is called without a valid request, fall to die
    eval {
        my $uri = $req->{env}->{REQUEST_URI};

        $class->logger->error($msg);

        # Redirect or die
        if ( $class->tsv->{useRedirectOnError} ) {
            $class->logger->debug("Use redirect for error");
            return $class->goToError( $req, $uri, 500 );
        }
        else {
            return $class->SERVER_ERROR;
        }
    };
    die $msg if ($@);
}

## @rmethod protected void localUnlog()
# Delete current user from local cache entry.
sub localUnlog {
    my ( $class, $req, $id ) = @_;
    $class->logger->debug('Local handler logout');

    # Delete thread data
    delete $req->data->{session};
    $class->data( {} );
    if ( $id //= $class->fetchId($req) ) {

        # Delete local cache
        if ( $class->tsv->{sessionCacheModule} ) {
            my $module  = $class->tsv->{sessionCacheModule};
            my $options = $class->tsv->{sessionCacheOptions};
            eval "use $module;";
            my $cache = $module->new($options);
            if ( $cache->get($id) ) {
                $cache->remove($id);
            }
        }
    }
}

## @rmethod protected postOutputFilter(string uri)
# Add a javascript to html page in order to fill html form with fake data
# @param uri URI to catch
sub postOutputFilter {
    my ( $class, $req, $session, $uri ) = @_;
    my $vhost = $class->resolveAlias($req);

    if ( defined( $class->tsv->{outputPostData}->{$vhost}->{$uri} ) ) {
        $class->logger->debug("Filling a html form with fake data");

        $class->unset_header_in( $req, "Accept-Encoding" );
        my %postdata =
          $class->tsv->{outputPostData}->{$vhost}->{$uri}->( $req, $session );
        my $formParams = $class->tsv->{postFormParams}->{$vhost}->{$uri};
        my $js = $class->postJavascript( $req, \%postdata, $formParams );
        $class->addToHtmlHead( $req, $js );
    }
}

## @rmethod protected postInputFilter(string uri)
# Replace request body with form data defined in configuration
# @param uri URI to catch
sub postInputFilter {
    my ( $class, $req, $session, $uri ) = @_;
    my $vhost = $class->resolveAlias($req);

    if ( defined( $class->tsv->{inputPostData}->{$vhost}->{$uri} ) ) {
        $class->logger->debug("Replacing fake data with real form data");

        my %data =
          $class->tsv->{inputPostData}->{$vhost}->{$uri}->( $req, $session );
        foreach ( keys %data ) {
            my $post_key   = uri_escape($_);
            my $post_value = uri_escape( $data{$_} );
            delete $data{$_};
            $data{$post_key} = $post_value;
            $class->logger->debug("Send key $post_key with value $post_value");
        }
        $class->setPostParams( $req, \%data );
    }
}

## @rmethod protected postJavascript(hashref data)
# build a javascript to fill a html form with fake data
# @param data hashref containing input => value
sub postJavascript {
    my ( $class, $req, $data, $formParams ) = @_;

    my $form = $formParams->{formSelector} || "form";

    my $filler;
    foreach my $name ( keys %$data ) {
        use bytes;
        my @characterSet = ( '0' .. '9', 'A' .. 'Z', 'a' .. 'z' );
        my $value        = join '' => map $characterSet[ rand @characterSet ],
          1 .. bytes::length( $data->{$name} );
        $filler .=
"form.find('input[name=\"$name\"], select[name=\"$name\"], textarea[name=\"$name\"]').val('$value')\n";
    }

    my $submitter =
        $formParams->{buttonSelector} eq "none" ? ""
      : $formParams->{buttonSelector}
      ? "form.find('$formParams->{buttonSelector}').click();\n"
      : "form.submit();\n";

    my $jqueryUrl = $formParams->{jqueryUrl} || "";
    $jqueryUrl =
      &{ $class->tsv->{portal} } . "static/bwr/jquery/dist/jquery.min.js"
      if ( $jqueryUrl eq "default" );
    $jqueryUrl = "<script type='text/javascript' src='$jqueryUrl'></script>\n"
      if ($jqueryUrl);

    return
        $jqueryUrl
      . "<script type='text/javascript'>\n"
      . "/* script added by Lemonldap::NG */\n"
      . "jQuery(window).on('load', function() {\n"
      . "var form = jQuery('$form');\n"
      . "form.attr('autocomplete', 'off');\n"
      . $filler
      . $submitter . "})\n"
      . "</script>\n";
}

1;
