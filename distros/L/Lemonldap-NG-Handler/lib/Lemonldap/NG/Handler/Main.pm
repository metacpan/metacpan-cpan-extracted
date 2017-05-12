# Methods run at request serving
package Lemonldap::NG::Handler::Main;

use MIME::Base64;
use Exporter 'import';

use Lemonldap::NG::Common::Session;
use CGI::Util 'expires';
use URI::Escape;
use constant UNPROTECT => 1;
use constant SKIP      => 2;

#inherits Cache::Cache
#inherits Apache::Session
#link Lemonldap::NG::Common::Apache::Session::SOAP protected globalStorage

our $VERSION = '1.9.7';
our ( %EXPORT_TAGS, @EXPORT_OK, @EXPORT );

our $tsv = {};    # Hash ref containing thread-shared values, filled
                  # at config reload - see Reload.pm comments to know
                  # what it contains
our $session;     # Object for current user session
our $datas;       # Hash ref containing current user session datas
our $datasUpdate; # Last time the current user session was read

BEGIN {

    # globalStorage and locationRules are set for Manager compatibility only
    %EXPORT_TAGS = (
        globalStorage  => [qw(  )],
        locationRules  => [qw( )],
        jailSharedVars => [qw( $datas )],
        tsv            => [qw( $tsv )],
        import         => [qw( import @EXPORT_OK @EXPORT %EXPORT_TAGS )],
        post           => [qw(postFilter)],
    );
    push( @EXPORT_OK, @{ $EXPORT_TAGS{$_} } ) foreach ( keys %EXPORT_TAGS );
    $EXPORT_TAGS{all} = \@EXPORT_OK;

    # For importing MP(), required modules, and constants
    use Lemonldap::NG::Handler::API qw(:httpCodes);
    Lemonldap::NG::Handler::API->thread_share($tsv);
}

use Lemonldap::NG::Handler::Main::Jail;
use Lemonldap::NG::Handler::Main::Logger;

## @rmethod protected void updateStatus(string action,string user,string url)
# Inform the status process of the result of the request if it is available
# @param action string Result of access control (as OK, SKIP, LOGOUT...)
# @param optional user string Username to log, if undefined defaults to remote IP
# @param optional url string URL to log, if undefined defaults to request URI
sub updateStatus {
    my ( $class, $action, $user, $url ) = @_;
    my $statusPipe = $tsv->{statusPipe};
    $user ||= Lemonldap::NG::Handler::API->remote_ip;
    $url  ||= Lemonldap::NG::Handler::API->uri_with_args;
    eval {
            print $statusPipe "$user => "
          . Lemonldap::NG::Handler::API->hostname
          . "$url $action\n"
          if ($statusPipe);
    };
}

## @rmethod protected int forbidden(string uri)
# Used to reject non authorized requests.
# Inform the status processus and call logForbidden().
# @param $uri URI
# @return Constant FORBIDDEN
sub forbidden {
    my $class = shift;
    my $uri   = Lemonldap::NG::Handler::API->unparsed_uri;

    if ( $datas->{_logout} ) {
        $class->updateStatus( 'LOGOUT', $datas->{ $tsv->{whatToTrace} } );
        my $u = $datas->{_logout};
        $class->localUnlog;
        return $class->goToPortal( $u, 'logout=1' );
    }

    # Log forbidding
    my $vhost = $class->resolveAlias;
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "User "
          . $datas->{ $tsv->{whatToTrace} }
          . " was forbidden to access to $vhost$uri",
        "notice"
    );
    $class->updateStatus( 'REJECT', $datas->{ $tsv->{whatToTrace} } );

    # Redirect or Forbidden?
    if ( $tsv->{useRedirectOnForbidden} ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Use redirect for forbidden access", 'debug' );
        return $class->goToPortal( $uri, 'lmError=403' );
    }
    else {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Return forbidden access",
            'debug' );
        return FORBIDDEN;
    }
}

## @rmethod protected void hideCookie()
# Hide Lemonldap::NG cookie to the protected application.
sub hideCookie {
    my $class = shift;
    Lemonldap::NG::Handler::Main::Logger->lmLog( "removing cookie", 'debug' );
    my $cookie = Lemonldap::NG::Handler::API->header_in('Cookie');
    $cookie =~ s/$tsv->{cookieName}(http)?=[^,;]*[,;\s]*//og;
    if ($cookie) {
        Lemonldap::NG::Handler::API->set_header_in( 'Cookie' => $cookie );
    }
    else {
        Lemonldap::NG::Handler::API->unset_header_in('Cookie');
    }
}

## @rmethod protected string encodeUrl(string url)
# Encode URl in the format used by Lemonldap::NG::Portal for redirections.
# @return Base64 encoded string
sub encodeUrl {
    my ( $class, $url ) = @_;
    $url = $class->_buildUrl($url) if ( $url !~ m#^https?://# );
    return encode_base64( $url, '' );
}

## @rmethod protected int goToPortal(string url, string arg)
# Redirect non-authenticated users to the portal by setting "Location:" header.
# @param $url Url requested
# @param $arg optionnal GET parameters
# @return Constant REDIRECT
sub goToPortal {
    my ( $class, $url, $arg ) = @_;
    my ( $ret, $msg );
    my $urlc_init = $class->encodeUrl($url);
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "Redirect "
          . Lemonldap::NG::Handler::API->remote_ip
          . " to portal (url was $url)",
        'debug'
    );
    Lemonldap::NG::Handler::API->set_header_out(
            'Location' => &{ $tsv->{portal} }()
          . "?url=$urlc_init"
          . ( $arg ? "&$arg" : "" ) );
    return REDIRECT;
}

## @rmethod protected fetchId()
# Get user cookies and search for Lemonldap::NG cookie.
# @return Value of the cookie if found, 0 else
sub fetchId {
    my $class             = shift;
    my $t                 = Lemonldap::NG::Handler::API->header_in('Cookie');
    my $vhost             = $class->resolveAlias;
    my $lookForHttpCookie = $tsv->{securedCookie} =~ /^(2|3)$/
      && !(
        defined( $tsv->{https}->{$vhost} )
        ? $tsv->{https}->{$vhost}
        : $tsv->{https}->{_}
      );
    my $value =
      $lookForHttpCookie
      ? ( $t =~ /$tsv->{cookieName}http=([^,; ]+)/o ? $1 : 0 )
      : ( $t =~ /$tsv->{cookieName}=([^,; ]+)/o ? $1 : 0 );

    $value = $tsv->{cipher}->decryptHex( $value, "http" )
      if ( $value && $lookForHttpCookie && $tsv->{securedCookie} == 3 );
    return $value;
}

## @rmethod protected boolean retrieveSession(id)
# Tries to retrieve the session whose index is id
# @return true if the session was found, false else
sub retrieveSession {
    my ( $class, $id ) = @_;
    my $now = time();

    # 1. Search if the user was the same as previous (very efficient in
    # persistent connection).
    if (    defined $datas->{_session_id}
        and $id eq $datas->{_session_id}
        and ( $now - $datasUpdate < 60 ) )
    {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Get session $id from Handler internal cache", 'debug' );
        return 1;
    }

    # 2. Get the session from cache or backend
    $session = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $tsv->{sessionStorageModule},
            storageModuleOptions => $tsv->{sessionStorageOptions},
            cacheModule          => $tsv->{sessionCacheModule},
            cacheModuleOptions   => $tsv->{sessionCacheOptions},
            id                   => $id,
            kind                 => "SSO",
        }
    );

    unless ( $session->error ) {

        $datas = $session->data;

        Lemonldap::NG::Handler::Main::Logger->lmLog( "Get session $id",
            'debug' );

        # Verify that session is valid
        if (
            $now - $datas->{_utime} > $tsv->{timeout}
            or (    $tsv->{timeoutActivity}
                and $datas->{_lastSeen}
                and $now - $datas->{_lastSeen} > $tsv->{timeoutActivity} )
          )
        {
            Lemonldap::NG::Handler::Main::Logger->lmLog( "Session $id expired",
                'info' );

            # Clean cached data
            $datas = {};
            return 0;
        }

        # Update the session to notify activity, if necessary
        if ( $tsv->{timeoutActivity}
            and
            ( $now - $datas->{_lastSeen} > $tsv->{timeoutActivityInterval} ) )
        {
            $session->update( { '_lastSeen' => $now } );

            if ( $session->error ) {
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Cannot update session $id", 'error' );
                Lemonldap::NG::Handler::Main::Logger->lmLog( $session->error,
                    'error' );
            }
            else {
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Update _lastSeen with $now", 'debug' );
            }
        }

        $datasUpdate = $now;
        return 1;
    }
    else {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Session $id can't be retrieved", 'info' );
        Lemonldap::NG::Handler::Main::Logger->lmLog( $session->error, 'info' );

        return 0;
    }
}

## @rmethod protected hash getCDAInfos(id)
# Tries to retrieve the CDA session, get infos and delete session
# @return CDA session infos
sub getCDAInfos {
    my ( $class, $id ) = @_;
    my $infos = {};

    # Get the session
    my $cdaSession = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $tsv->{sessionStorageModule},
            storageModuleOptions => $tsv->{sessionStorageOptions},
            cacheModule          => $tsv->{sessionCacheModule},
            cacheModuleOptions   => $tsv->{sessionCacheOptions},
            id                   => $id,
            kind                 => "CDA",
        }
    );

    unless ( $cdaSession->error ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Get CDA session $id",
            'debug' );

        $infos->{cookie_value} = $cdaSession->data->{cookie_value};
        $infos->{cookie_name}  = $cdaSession->data->{cookie_name};

        $cdaSession->remove;
    }
    else {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "CDA Session $id can't be retrieved", 'info' );
        Lemonldap::NG::Handler::Main::Logger->lmLog( $cdaSession->error,
            'info' );
    }

    return $infos;
}

# MAIN SUBROUTINE

## @rmethod int run(string ĉonf, string protection)
# Main method used to control access.
# Calls :
# - fetchId()
# - retrieveSession()
# - grant()
# - forbidden() if user is rejected
# - sendHeaders() if user is granted
# - hideCookie()
# - updateStatus()
# @param $cond optional Function granting access
# @param $protection optional Set to 1 or 2 if access unprotected
# @return Constant (OK, FORBIDDEN, REDIRECT or SERVER_ERROR)
sub run {
    my ( $class, $cond, $protection ) = @_;
    return DECLINED
      unless ( Lemonldap::NG::Handler::API->is_initial_req );

    # Direct return if maintenance mode is active
    if ( $class->checkMaintenanceMode ) {

        if ( $tsv->{useRedirectOnError} ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "Got to portal with maintenance error code", 'debug' );
            return $class->goToPortal( '/', 'lmError=' . MAINTENANCE );
        }
        else {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "Return maintenance error code", 'debug' );
            return MAINTENANCE;
        }
    }

    # Cross domain authentication
    my $uri = Lemonldap::NG::Handler::API->unparsed_uri;
    if (    $tsv->{cda}
        and $uri =~ s/[\?&;]$tsv->{cookieName}cda=(\w+)$//oi )
    {
        my $cdaid = $1;
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "CDA request with id $cdaid", 'debug' );

        my $cdaInfos = $class->getCDAInfos($cdaid);
        unless ( $cdaInfos->{cookie_value} and $cdaInfos->{cookie_name} ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "CDA request for id $cdaid is not valid", 'error' );
            return FORBIDDEN;
        }

        my $redirectUrl   = $class->_buildUrl($uri);
        my $redirectHttps = ( $redirectUrl =~ m/^https/ );
        Lemonldap::NG::Handler::API->set_header_out(
            'Location'   => $redirectUrl,
            'Set-Cookie' => $cdaInfos->{cookie_name} . "="
              . $cdaInfos->{cookie_value}
              . "; path=/"
              . ( $redirectHttps   ? "; secure"   : "" )
              . ( $tsv->{httpOnly} ? "; HttpOnly" : "" )
              . (
                $tsv->{cookieExpiration}
                ? "; expires=" . expires( $tsv->{cookieExpiration}, 'cookie' )
                : ""
              )
        );
        return REDIRECT;
    }

    $uri        = Lemonldap::NG::Handler::API->uri_with_args;
    $protection = $class->isUnprotected($uri)
      unless ( defined $protection );

    if ( $protection == SKIP ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Access control skipped",
            'debug' );
        $class->updateStatus('SKIP');
        $class->hideCookie;
        $class->cleanHeaders;
        return OK;
    }

    my $id;

    # Try to recover cookie and user session
    if (    $id = $class->fetchId
        and $class->retrieveSession($id) )
    {

        # AUTHENTICATION done

        # Local macros
        my $kc = keys %$datas;    # in order to detect new local macro

        # ACCOUNTING (1. Inform web server)
        Lemonldap::NG::Handler::API->set_user(
            $datas->{ $tsv->{whatToTrace} } );

        # AUTHORIZATION
        return $class->forbidden unless ( $class->grant( $uri, $cond ) );
        $class->updateStatus( 'OK', $datas->{ $tsv->{whatToTrace} } );

        # ACCOUNTING (2. Inform remote application)
        $class->sendHeaders;

        # Store local macros
        if ( keys %$datas > $kc ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog( "Update local cache",
                'debug' );
            $session->update( $datas, { updateCache => 2 } );
        }

        # Hide Lemonldap::NG cookie
        $class->hideCookie;

        # Log access granted
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "User "
              . $datas->{ $tsv->{whatToTrace} }
              . " was granted to access to $uri",
            'debug'
        );

        #  Catch POST rules
        $class->postOutputFilter($uri);
        $class->postInputFilter($uri);

        return OK;
    }

    elsif ( $protection == UNPROTECT ) {

        # Ignore unprotected URIs
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "No valid session but unprotected access", 'debug' );
        $class->updateStatus('UNPROTECT');
        $class->hideCookie;
        $class->cleanHeaders;
        return OK;
    }

    else {

        # Redirect user to the portal
        Lemonldap::NG::Handler::Main::Logger->lmLog( "No cookie found", 'info' )
          unless ($id);

        # if the cookie was fetched, a log is sent by retrieveSession()
        $class->updateStatus( $id ? 'EXPIRED' : 'REDIRECT' );
        return $class->goToPortal( Lemonldap::NG::Handler::API->unparsed_uri );
    }
}

## @rmethod protected boolean checkMaintenanceMode
# Check if we are in maintenance mode
# @return true if maintenance mode
sub checkMaintenanceMode {
    my $class = shift;
    my $vhost = $class->resolveAlias;
    my $_maintenance =
      ( defined $tsv->{maintenance}->{$vhost} )
      ? $tsv->{maintenance}->{$vhost}
      : $tsv->{maintenance}->{_};

    if ($_maintenance) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Maintenance mode activated", 'debug' );
        return 1;
    }

    return 0;
}

## @rmethod int abort(string msg)
# Logs message and exit or redirect to the portal if "useRedirectOnError" is
# set to true.
# @param $msg Message to log
# @return Constant (REDIRECT, SERVER_ERROR)
sub abort {
    my ( $class, $msg ) = @_;

    # If abort is called without a valid request, fall to die
    eval {
        my $uri = Lemonldap::NG::Handler::API->unparsed_uri;

        Lemonldap::NG::Handler::Main::Logger->lmLog( $msg, 'error' );

        # Redirect or die
        if ( $tsv->{useRedirectOnError} ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "Use redirect for error", 'debug' );
            return $class->goToPortal( $uri, 'lmError=500' );
        }
        else {
            return SERVER_ERROR;
        }
    };
    die $msg if ($@);
}

## @rmethod boolean grant(string uri, string cond)
# Grant or refuse client using compiled regexp and functions
# @param $uri URI
# @param $cond optional Function granting access
# @return True if the user is granted to access to the current URL
sub grant {
    my ( $class, $uri, $cond ) = @_;
    return &{$cond}() if ($cond);

    my $vhost = $class->resolveAlias;
    for ( my $i = 0 ; $i < $tsv->{locationCount}->{$vhost} ; $i++ ) {
        if ( $uri =~ $tsv->{locationRegexp}->{$vhost}->[$i] ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                'Regexp "'
                  . $tsv->{locationConditionText}->{$vhost}->[$i]
                  . '" match',
                'debug'
            );
            return &{ $tsv->{locationCondition}->{$vhost}->[$i] }();
        }
    }
    unless ( $tsv->{defaultCondition}->{$vhost} ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "User rejected because VirtualHost \"$vhost\" has no configuration",
            'warn'
        );
        return 0;
    }
    Lemonldap::NG::Handler::Main::Logger->lmLog( "$vhost: Apply default rule",
        'debug' );
    return &{ $tsv->{defaultCondition}->{$vhost} }();
}

## @cmethod private string _buildUrl(string s)
# Transform /<s> into http(s?)://<host>:<port>/s
# @param $s path
# @return URL
sub _buildUrl {
    my ( $class, $s ) = @_;
    my $vhost = Lemonldap::NG::Handler::API->hostname;
    my $portString =
         $tsv->{port}->{$vhost}
      || $tsv->{port}->{_}
      || Lemonldap::NG::Handler::API->get_server_port;
    my $_https = (
        defined( $tsv->{https}->{$vhost} )
        ? $tsv->{https}->{$vhost}
        : $tsv->{https}->{_}
    );
    $portString =
        ( $_https  && $portString == 443 ) ? ''
      : ( !$_https && $portString == 80 )  ? ''
      :                                      ':' . $portString;
    my $url = "http" . ( $_https ? "s" : "" ) . "://$vhost$portString$s";
    Lemonldap::NG::Handler::Main::Logger->lmLog( "Build URL $url", 'debug' );
    return $url;
}

## @rmethod protected void localUnlog()
# Delete current user from local cache entry.
sub localUnlog {
    my $class = shift;
    if ( my $id = $class->fetchId ) {

        # Delete thread datas
        if ( $id eq $datas->{_session_id} ) {
            $datas = {};
        }

        # Delete local cache
        if ( $tsv->{refLocalStorage} and $tsv->{refLocalStorage}->get($id) ) {
            $tsv->{refLocalStorage}->remove($id);
        }
    }
}

## @rmethod protected int unlog()
# Call localUnlog() then goToPortal() to unlog the current user.
# @return Constant value returned by goToPortal()
sub unlog ($$) {
    my $class = shift;
    $class->localUnlog;
    $class->updateStatus('LOGOUT');
    return $class->goToPortal( '/', 'logout=1' );
}

## @rmethod int status
# Get the result from the status process and launch a PerlResponseHandler to
# display it.
# @return Constant OK
sub status($$) {
    my $class      = shift;
    my $statusPipe = $tsv->{statusPipe};
    my $statusOut  = $tsv->{statusOut};
    Lemonldap::NG::Handler::Main::Logger->lmLog( "Request for status",
        'debug' );
    return $class->abort("$class: status page can not be displayed")
      unless ( $statusPipe and $statusOut );
    print $statusPipe "STATUS"
      . (
        Lemonldap::NG::Handler::API->args
        ? " " . Lemonldap::NG::Handler::API->args
        : ''
      ) . "\n";
    my $buf;
    while (<$statusOut>) {
        last if (/^END$/);
        $buf .= $_;
    }
    Lemonldap::NG::Handler::API->set_header_out(
        ( "Content-Type" => "text/html; charset=UTF-8" ) );
    Lemonldap::NG::Handler::API->print($buf);
    return OK;
}

## @rmethod protected int redirectFilter(string url, Apache2::Filter f)
# Launch the current HTTP request then redirects the user to $url.
# Used by logout_app and logout_app_sso targets
# @param $url URL to redirect the user
# @param $f Current Apache2::Filter object
# @return Constant OK
sub redirectFilter {
    my ( $class, $url, $f ) = @_;
    unless ( $f->ctx ) {

        # Here, we can use Apache2 functions instead of set_header_out
        # since this function is used only with Apache2.
        $f->r->status(REDIRECT);
        $f->r->status_line("303 See Other");
        $f->r->headers_out->unset('Location');
        $f->r->err_headers_out->set( 'Location' => $url );
        $f->ctx(1);
    }
    while ( $f->read( my $buffer, 1024 ) ) {
    }
    $class->updateStatus( $f->r, 'REDIRECT',
        $datas->{ $tsv->{whatToTrace} }, 'filter' );
    return OK;
}

## @rmethod protected int isUnprotected()
# @param $uri URI
# @return 0 if URI is protected,
# UNPROTECT if it is unprotected by "unprotect",
# SKIP if is is unprotected by "skip"
sub isUnprotected {
    my ( $class, $uri ) = @_;
    my $vhost = $class->resolveAlias;
    for ( my $i = 0 ; $i < $tsv->{locationCount}->{$vhost} ; $i++ ) {
        if ( $uri =~ $tsv->{locationRegexp}->{$vhost}->[$i] ) {
            return $tsv->{locationProtection}->{$vhost}->[$i];
        }
    }
    return $tsv->{defaultProtection}->{$vhost};
}

## @rmethod void sendHeaders()
# Launch function compiled by forgeHeadersInit() for the current virtual host
sub sendHeaders {
    my $class = shift;
    my $vhost = $class->resolveAlias;

    if ( defined( $tsv->{forgeHeaders}->{$vhost} ) ) {

        # Log headers in debug mode
        my %headers = &{ $tsv->{forgeHeaders}->{$vhost} };
        foreach my $h ( sort keys %headers ) {
            if ( defined( my $v = $headers{$h} ) ) {
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Send header $h with value $v", "debug" );
            }
            else {
                Lemonldap::NG::Handler::Main::Logger->lmLog(
                    "Send header $h with empty value", "debug" );
            }
        }
        Lemonldap::NG::Handler::API->set_header_in(%headers);
    }
}

## @rmethod void cleanHeaders()
# Unset HTTP headers, when sendHeaders is skipped
sub cleanHeaders {
    my $class = shift;
    my $vhost = $class->resolveAlias;
    if ( defined( $tsv->{headerList}->{$vhost} ) ) {
        Lemonldap::NG::Handler::API->unset_header_in(
            @{ $tsv->{headerList}->{$vhost} } );
    }
}

## @rmethod string resolveAlias
# returns vhost whose current hostname is an alias
sub resolveAlias {
    my $class = shift;
    my $vhost = Lemonldap::NG::Handler::API->hostname;
    return $tsv->{vhostAlias}->{$vhost} || $vhost;
}

## @rmethod protected postOutputFilter(string uri)
# Add a javascript to html page in order to fill html form with fake data
# @param uri URI to catch
sub postOutputFilter {
    my ( $class, $uri ) = @_;
    my $vhost = $class->resolveAlias;

    if ( defined( $tsv->{outputPostData}->{$vhost}->{$uri} ) ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Filling a html form with fake data", "debug" );

        Lemonldap::NG::Handler::API->unset_header_in("Accept-Encoding");
        my %postdata   = &{ $tsv->{outputPostData}->{$vhost}->{$uri} };
        my $formParams = $tsv->{postFormParams}->{$vhost}->{$uri};
        my $js         = $class->postJavascript( \%postdata, $formParams );
        Lemonldap::NG::Handler::API->addToHtmlHead($js);
    }
}

## @rmethod protected postInputFilter(string uri)
# Replace request body with form datas defined in configuration
# @param uri URI to catch
sub postInputFilter {
    my ( $class, $uri ) = @_;
    my $vhost = $class->resolveAlias;

    if ( defined( $tsv->{inputPostData}->{$vhost}->{$uri} ) ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Replacing fake data with real form data", "debug" );

        my %data = &{ $tsv->{inputPostData}->{$vhost}->{$uri} };
        foreach ( keys %data ) {
            $data{$_} = uri_escape( $data{$_} );
        }
        Lemonldap::NG::Handler::API->setPostParams( \%data );
    }
}

## @rmethod protected postJavascript(hashref data)
# build a javascript to fill a html form with fake data
# @param data hashref containing input => value
sub postJavascript {
    my ( $class, $data, $formParams ) = @_;

    my $form = $formParams->{formSelector} || "form";

    my $filler;
    foreach my $name ( keys %$data ) {
        use bytes;
        my $value = "x" x bytes::length( $data->{$name} );
        $filler .=
"form.find('input[name=$name], select[name=$name], textarea[name=$name]').val('$value')\n";
    }

    my $submitter =
        $formParams->{buttonSelector} eq "none" ? ""
      : $formParams->{buttonSelector}
      ? "form.find('$formParams->{buttonSelector}').click();\n"
      : "form.submit();\n";

    my $jqueryUrl = $formParams->{jqueryUrl} || "";
    $jqueryUrl = &{ $tsv->{portal} } . "skins/common/js/jquery-1.10.2.js"
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
