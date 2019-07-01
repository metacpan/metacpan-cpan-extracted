##@class Lemonldap::NG::Portal::Main::Run
# Serve request part of Lemonldap::NG portal
#
# Parts of this file:
#  - response handler
#  - main entry points
#  - running methods
#  - utilities
#
package Lemonldap::NG::Portal::Main::Run;

our $VERSION = '2.0.5';

package Lemonldap::NG::Portal::Main;

use strict;
use URI::Escape;
use JSON;

has trOverCache => ( is => 'rw', default => sub { {} } );

# List constants
sub authProcess { qw(extractFormInfo getUser authenticate) }

sub sessionData {
    qw(setAuthSessionInfo setSessionInfo setMacros setGroups setPersistentSessionInfo
      setLocalGroups store secondFactor);
}

sub validSession {
    qw(storeHistory buildCookie);
}

# RESPONSE HANDLER
# ----------------
#
# - replace Lemonldap::NG::Common::PSGI::Request request by
#   Lemonldap::NG::Portal::Main::Request
# - launch Lemonldap::NG::Common::PSGI::Request::handler()
sub handler {
    my ( $self, $req ) = @_;

    bless $req, 'Lemonldap::NG::Portal::Main::Request';
    $req->init( $self->conf );
    my $sp = 0;

    # Restore pdata
    if ( my $v = $req->cookies->{ $self->conf->{cookieName} . 'pdata' } ) {
        $sp = 1;
        eval { $req->pdata( JSON::from_json( uri_unescape($v) ) ); };
        if ($@) {
            $self->logger->error("Bad JSON content in cookie pdata");
            $req->pdata( {} );
        }
    }
    my $res = $self->Lemonldap::NG::Common::PSGI::Router::handler($req);

    # Save pdata
    if ( $sp or %{ $req->pdata } ) {
        my %v = (
            name => $self->conf->{cookieName} . 'pdata',
            (
                %{ $req->pdata }
                ? ( value => uri_escape( JSON::to_json( $req->pdata ) ) )
                : (
                    value   => '',
                    expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
                )
            )
        );
        push @{ $res->[1] }, 'Set-Cookie', $self->cookie(%v);
    }
    return $res;
}

# MAIN ENTRY POINTS (declared in Lemonldap::NG::Portal::Main::Init)
# -----------------
#
# Entry points:
#  - "/ping": - authenticated() for already authenticated users
#             - pleaseAuth() for others
#  - "/":     - login() ~first access
#             - postLogin(), same for POST requests
#             - authenticatedRequest() for authenticated users

sub authenticated {
    my ( $self, $req ) = @_;
    return $self->sendJSONresponse( $req, { status => 1 } );
}

sub pleaseAuth {
    my ( $self, $req ) = @_;
    return $self->sendJSONresponse( $req, { status => 0 } );
}

sub login {
    my ( $self, $req ) = @_;
    return $self->do(
        $req,
        [
            'controlUrl',        @{ $self->beforeAuth },
            $self->authProcess,  @{ $self->betweenAuthAndData },
            $self->sessionData,  @{ $self->afterData },
            $self->validSession, @{ $self->endAuth },
        ]
    );
}

sub postLogin {
    my ( $self, $req ) = @_;
    return $self->do(
        $req,
        [
            'restoreArgs',                  'controlUrl',
            @{ $self->beforeAuth },         $self->authProcess,
            @{ $self->betweenAuthAndData }, $self->sessionData,
            @{ $self->afterData },          $self->validSession,
            @{ $self->endAuth },
        ]
    );
}

sub authenticatedRequest {
    my ( $self, $req ) = @_;
    return $self->do(
        $req,
        [
            'importHandlerData', 'controlUrl',
            'checkLogout',       @{ $self->forAuthUser }
        ]
    );
}

sub postAuthenticatedRequest {
    my ( $self, $req ) = @_;
    return $self->do(
        $req,
        [
            'importHandlerData', 'restoreArgs',
            'controlUrl',        'checkLogout',
            @{ $self->forAuthUser }
        ]
    );
}

sub refresh {
    my ( $self, $req ) = @_;
    $req->mustRedirect(1);
    my %data = %{ $req->userData };
    $req->user( $data{ $self->conf->{whatToTrace} } );
    $req->id( $data{_session_id} );
    $self->userLogger->notice( 'Refresh request for ' . $req->user );
    foreach ( keys %data ) {
        delete $data{$_} unless ( /^_/ or /^(?:startTime)$/ );
    }
    $data{_updateTime} = strftime( "%Y%m%d%H%M%S", localtime() );
    $self->logger->debug(
        "Set session $req->{id} _updateTime with $data{_updateTime}");
    $req->steps( [
            'getUser',
            @{ $self->betweenAuthAndData },
            'setAuthSessionInfo',
            'setSessionInfo',
            'setMacros',
            'setGroups',
            'setLocalGroups',
            sub {
                $req->sessionInfo->{$_} = $data{$_} foreach ( keys %data );
                $req->refresh(1);
                return PE_OK;
            },
            'store',
        ]
    );
    my $res = $req->error( $self->process($req) );
    if ($res) {
        $req->info(
            $self->loadTemplate(
                $req,
                'simpleInfo', params => { trspan => 'rightsReloadNeedsLogout' }
            )
        );
        $req->urldc( $self->conf->{portal} );
        return $self->do( $req, [ sub { PE_INFO } ] );
    }
    return $self->do( $req, [ sub { PE_OK } ] );
}

sub logout {
    my ( $self, $req ) = @_;
    return $self->do(
        $req,
        [
            'importHandlerData',      'controlUrl',
            @{ $self->beforeLogout }, 'authLogout',
            'deleteSession'
        ]
    );
}

# RUNNING METHODS
# ---------------

sub do {
    my ( $self, $req, $steps ) = @_;
    $req->steps($steps);
    $req->data->{activeTimer} = $self->conf->{activeTimer};
    my $err = $req->error( $self->process($req) );

    # Update status
    if ( my $p = $self->HANDLER->tsv->{statusPipe} ) {
        $p->print( ( $req->user ? $req->user : $req->address ) . ' => '
              . $req->uri
              . " $err\n" );
    }

    # Update history
    if ( $err == PE_SENDRESPONSE ) {
        return $req->response;
    }

    # Remove userData if authentication fails
    if ( $err == PE_BADCREDENTIALS ) {
        $req->userData( {} );
    }

    if ( !$self->conf->{noAjaxHook} and $req->wantJSON ) {
        $self->logger->debug('Processing to JSON response');
        if ( ( $err > 0 and !$req->id ) or $err eq PE_SESSIONNOTGRANTED ) {
            return [
                401,
                [ 'WWW-Authenticate' => "SSO " . $self->conf->{portal} ],
                [qq'{"result":0,"error":$err}']
            ];
        }
        elsif ( $err > 0 and $err != PE_PASSWORD_OK and $err != PE_LOGOUT_OK ) {
            return $self->sendJSONresponse(
                $req,
                { result => 0, error => $err },
                code => 400
            );
        }
        else {
            return $self->sendJSONresponse(
                $req,
                {
                    result => 1,
                    error  => $err,
                    id     => $req->id
                }
            );
        }
    }
    else {
        if (
            $req->info
            or (
                    $err
                and $err != PE_LOGOUT_OK
                and (
                    $err != PE_REDIRECT
                    or (    $err == PE_REDIRECT
                        and $req->data->{redirectFormMethod}
                        and $req->data->{redirectFormMethod} eq 'post' )
                )
            )
          )
        {
            my ( $tpl, $prms ) = $self->display($req);
            $self->logger->debug("Calling sendHtml with template $tpl");
            return $self->sendHtml( $req, $tpl, params => $prms );
        }
        else {
            $self->logger->debug('Calling autoredirect');
            return $self->autoRedirect($req);
        }
    }
}

# Utilities
# ---------

sub getModule {
    my ( $self, $req, $type ) = @_;
    if (
        my $mod = {
            auth     => '_authentication',
            user     => '_userDB',
            password => '_passwordDB'
        }->{$type}
      )
    {
        if ( my $sub = $self->$mod->can('name') ) {
            return $sub->( $self->$mod, $req, $type );
        }
        else {
            my $s = ref( $self->$mod );
            $s =~
s/^Lemonldap::NG::Portal::(?:(?:Issuer|UserDB|Auth|Password)::)?//;
            return $s;
        }
    }
    elsif ( $type eq 'issuer' ) {
        return $req->{_activeIssuerDB};
    }
    else {
        die "Unknown type $type";
    }
}

sub autoRedirect {
    my ( $self, $req ) = @_;

    # Set redirection URL if needed
    $req->{urldc} ||= $self->conf->{portal}
      if ( $req->mustRedirect and not( $req->info ) );

    # Redirection should be made if urldc defined
    if ( $req->{urldc} ) {
        $self->logger->debug("Building redirection to $req->{urldc}");
        if ( $self->_jsRedirect->( $req, $req->sessionInfo ) ) {
            $req->error(PE_REDIRECT);
            $req->data->{redirectFormMethod} = "get";
        }
        else {
            return [ 302,
                [ Location => $req->{urldc}, @{ $req->respHeaders } ], [] ];
        }
    }
    my ( $tpl, $prms ) = $self->display($req);
    $self->logger->debug("Calling sendHtml with template $tpl");
    return $self->sendHtml( $req, $tpl, params => $prms );
}

# Try to recover the session corresponding to id and return session data.
# If $id is set to undef or if $args{force} is true, return a new session.
sub getApacheSession {
    my ( $self, $id, %args ) = @_;
    $args{kind} //= "SSO";
    if ($id) {
        $self->logger->debug("Try to get $args{kind} session $id");
    }
    else {
        $self->logger->debug("Try to get a new $args{kind} session");
    }

    my $as = Lemonldap::NG::Common::Session->new( {
            storageModule        => $self->conf->{globalStorage},
            storageModuleOptions => $self->conf->{globalStorageOptions},
            cacheModule          => $self->conf->{localSessionStorage},
            cacheModuleOptions   => $self->conf->{localSessionStorageOptions},
            id                   => $id,
            force                => $args{force},
            kind                 => $args{kind},
            ( $args{info} ? ( info => $args{info} ) : () ),
        }
    );

    if ( my $err = $as->error ) {
        $self->lmLog(
            $err,
            (
                $err =~ /(?:Object does not exist|Invalid session ID)/
                ? 'notice'
                : 'error'
            )
        );
        return;
    }

    if ( $id and !$args{force} and !$as->data ) {
        $self->logger->debug("Session $args{kind} $id not found");
        return;
    }
    $self->logger->debug("Get session $id from Portal::Main::Run") if ($id);
    $self->logger->debug(
        "Check session validity  -> " . $self->conf->{timeoutActivity} . "s" )
      if ( $self->conf->{timeoutActivity} );
    my $now = time;
    if (
            $id
        and defined $as->data->{_utime}
        and (
            ( ( $now - $as->data->{_utime} ) > $self->conf->{timeout} )
            or (
                    $self->conf->{timeoutActivity}
                and $as->data->{_lastSeen}
                and ( ( $now - $as->data->{_lastSeen} ) >
                    $self->conf->{timeoutActivity} )
            )
        )
      )
    {
        $self->logger->debug("Session $args{kind} $id expired");
        return;
    }

    $self->logger->debug( "Return $args{kind} session " . $as->id );

    return $as;
}

# Try to recover the persistent session corresponding to uid and return session data.
sub getPersistentSession {
    my ( $self, $uid, $info ) = @_;

    return unless defined $uid;

    # Compute persistent identifier
    my $pid = $self->_md5hash($uid);

    $info->{_session_uid} = $uid;

    my $ps = Lemonldap::NG::Common::Session->new( {
            storageModule        => $self->conf->{persistentStorage},
            storageModuleOptions => $self->conf->{persistentStorageOptions},
            id                   => $pid,
            force                => 1,
            kind                 => "Persistent",
            ( $info ? ( info => $info ) : () ),
        }
    );

    if ( $ps->error ) {
        $self->logger->debug( $ps->error );
    }
    else {

        # Set _session_uid if not already present
        unless ( defined $ps->data->{_session_uid} ) {
            $ps->update( { _session_uid => $uid } );
        }

        # Set _utime if not already present
        unless ( defined $ps->data->{_utime} ) {
            $ps->update( { _utime => time } );
        }
    }

    return $ps;
}

# Update persistent session.
# Call updateSession() and store %$infos in a persistent session.
# Note that if the session does not exists, it will be created.
# @param infos hash reference of information to update
# @param uid optional Unhashed persistent session ID
# @param id optional SSO session ID
# @return nothing
sub updatePersistentSession {
    my ( $self, $req, $infos, $uid, $id ) = @_;

    # Return if no infos to update
    return () unless ( ref $infos eq 'HASH' and %$infos );
    $uid ||= $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
      || $req->userData->{ $self->conf->{whatToTrace} };
    $self->logger->debug("Found 'whatToTrace' -> $uid");
    unless ($uid) {
        $self->logger->debug('No uid found, skipping updatePersistentSession');
        return ();
    }
    $self->logger->debug("Update $uid persistent session");

    # Update current session
    $self->updateSession( $req, $infos, $id );

    my $persistentSession = $self->getPersistentSession( $uid, $infos );

    if ( $persistentSession->error ) {
        $self->logger->error(
            "Cannot update persistent session " . $self->_md5hash($uid) );
        $self->logger->error( $persistentSession->error );
    }
}

# Update session stored.
# If no id is given, try to get it from cookie.
# If the session is available, update data with $info.
# Note that outdated session data may remain some time on
# server local cache, if there are several LL::NG servers.
# @param infos hash reference of information to update
# @param id Session ID
# @return nothing
sub updateSession {
    my ( $self, $req, $infos, $id ) = @_;

    # Return if no infos to update
    return () unless ( ref $infos eq 'HASH' and %$infos );

    # Recover session ID unless given
    $id ||= $req->{id} || $req->userData->{_session_id};

    if ($id) {

        # Update sessionInfo data
        ## sessionInfo updated if $id defined : quite strange !!
        ## See https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues/430
        foreach ( keys %$infos ) {
            $self->logger->debug("Update sessionInfo $_");
            $self->_dump( $infos->{$_} );
            $req->{sessionInfo}->{$_} = $self->HANDLER->data->{$_} =
              $infos->{$_};
        }

        # Update session in global storage with _updateTime
        $infos->{_updateTime} = strftime( "%Y%m%d%H%M%S", localtime() );
        if ( my $apacheSession =
            $self->getApacheSession( $id, info => $infos ) )
        {
            if ( $apacheSession->error ) {
                $self->logger->error("Cannot update session $id");
                $self->logger->error( $apacheSession->error );
            }
        }
    }
}

# Delete an existing session. If "securedCookie" is set to 2, the http session
# will also be removed.
# @param h tied Apache::Session object
# @param preserveCookie do not delete cookie
# @return True if session has been deleted
sub _deleteSession {
    my ( $self, $req, $session, $preserveCookie ) = @_;

    # Invalidate http cookie and session, if set
    if ( $self->conf->{securedCookie} >= 2 ) {

        # Try to find a linked http session (securedCookie == 2)
        if ( $self->conf->{securedCookie} == 2
            and my $id2 = $session->data->{_httpSession} )
        {
            if ( my $session2 = $self->getApacheSession($id2) ) {
                $session2->remove;
                if ( $session2->error ) {
                    $self->logger->debug(
                        "Unable to remove linked session $id2");
                    $self->logger->debug( $session2->error );
                }
            }
        }

        # Create an obsolete cookie to remove it
        $req->addCookie(
            $self->cookie(
                name    => $self->conf->{cookieName} . 'http',
                value   => 0,
                domain  => $self->conf->{domain},
                secure  => 0,
                expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
            )
        ) unless ($preserveCookie);
    }

    HANDLER->localUnlog( $req, $session->id );
    $session->remove;

    # Create an obsolete cookie to remove it
    $req->addCookie(
        $self->cookie(
            name    => $self->conf->{cookieName},
            value   => 0,
            domain  => $self->conf->{domain},
            secure  => 0,
            expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
        )
    ) unless ($preserveCookie);

    # Log
    my $user = $req->{sessionInfo}->{ $self->conf->{whatToTrace} };
    my $mod  = $req->{sessionInfo}->{_auth};
    $self->userLogger->notice(
"User $user has been disconnected from $mod ($req->{sessionInfo}->{ipAddr})"
    ) if $user;

    return $session->error ? 0 : 1;
}

# Return md5(s)
sub _md5hash {
    my ( $self, $s ) = @_;
    return substr( Digest::MD5::md5_hex($s), 0, 32 );
}

# Check if an URL's domain name is declared in LL::NG config or is declared as
# trusted domain
sub isTrustedUrl {
    my ( $self, $url ) = @_;
    return $url =~ $self->trustedDomainsRe ? 1 : 0;
}

sub stamp {
    my $self = shift;
    my $res =
        $self->conf->{cipher}
      ? $self->conf->{cipher}->encrypt( time() )
      : 1;
    $res =~ s/\+/%2B/g;
    return $res;
}

# Transfer POST data with auto submit
# @return void
sub autoPost {
    my ( $self, $req ) = @_;

    # Get URL and Form fields
    $req->{urldc} = $req->postUrl;
    my $formFields = $req->postFields;

    $self->clearHiddenFormValue($req);
    foreach ( keys %$formFields ) {
        $self->setHiddenFormValue( $req, $_, $formFields->{$_}, "", 0 );
    }

    # Display info before redirecting
    if ( $req->info() ) {
        $req->{infoFormMethod} = $req->param('method') || "post";
        return PE_INFO;
    }

    $req->data->{redirectFormMethod} = "post";
    return PE_REDIRECT;
}

# Add element into $self->{portalHiddenFormValues}, those values could be
# used to hide values into HTML form.
# @param fieldname The field name which will contain the corresponding value
# @param value The associated value
# @param prefix Prefix of the field key
# @param base64 Encode value in base64
# @return nothing
sub setHiddenFormValue {
    my ( $self, $req, $key, $val, $prefix, $base64 ) = @_;

    # Default values
    $prefix = "lmhidden_" unless defined $prefix;
    $base64 = 1           unless defined $base64;
    $val    = ''          unless defined $val;

    # Store value
    if ( defined $val or !( $val & ~$val ) ) {
        $key = $prefix . $key;

        $val = encode_base64($val) if $base64;
        $req->{portalHiddenFormValues}->{$key} = $val;
        $self->logger->debug("Store $val in hidden key $key");
    }
}

## @method public void getHiddenFormValue(string fieldname, string prefix, boolean base64)
# Get value into $self->{portalHiddenFormValues}.
# @param fieldname The existing field name which contains a value
# @param prefix Prefix of the field key
# @param base64 Decode value from base64
# @return string The associated value
sub getHiddenFormValue {
    my ( $self, $req, $key, $prefix, $base64 ) = @_;

    # Default values
    $prefix = "lmhidden_" unless defined $prefix;
    $base64 = 1           unless defined $base64;

    $key = $prefix . $key;

    # Get value
    my $val = $req->param($key);
    if ( defined $val ) {
        $val = decode_base64($val) if $base64;
        $self->logger->debug("Hidden value $val found for key $key");
        return $val;
    }

    # No value found
    return undef;
}

## @method protected void clearHiddenFormValue(arrayref keys)
# Clear values form stored hidden fields
# Delete all keys if no keys provided
# @param keys Array reference of keys
# @return nothing
sub clearHiddenFormValue {
    my ( $self, $req, $keys ) = @_;

    unless ( defined $keys ) {
        delete $req->{portalHiddenFormValues};
        $self->logger->debug("Delete all hidden values");
    }
    else {
        foreach (@$keys) {
            delete $req->{portalHiddenFormValues}->{$_};
            $self->logger->debug("Delete hidden value for key $_");
        }
    }

    return;
}

# Get the first value of a multivaluated session value
sub getFirstValue {
    my ( $self, $value ) = @_;

    my @values = split /$self->{conf}->{multiValuesSeparator}/, $value;

    return $values[0];
}

sub info {
    my ( $self, $req, $info ) = @_;
    return $req->info($info);
}

sub fullUrl {
    my ( $self, $req ) = @_;
    my $pHost = $self->conf->{portal};
    $pHost =~ s#^(https?://[^/]+)(?:/.*)?$#$1#;
    return $pHost . $req->env->{REQUEST_URI};
}

sub cookie {
    my ( $self, %h ) = @_;
    my @res;
    $res[0] = "$h{name}" or die("name required");
    $res[0] .= "=$h{value}";
    $h{path} ||= '/';
    $h{HttpOnly} //= $self->conf->{httpOnly};
    $h{max_age}  //= $self->conf->{cookieExpiration}
      if ( $self->conf->{cookieExpiration} );
    foreach (qw(domain path expires max_age HttpOnly)) {
        my $f = $_;
        $f =~ s/_/-/g;
        push @res, "$f=$h{$_}" if ( $h{$_} );
    }
    push @res, 'secure' if ( $h{secure} );
    return join( '; ', @res );
}

sub _dump {
    my ( $self, $variable ) = @_;
    require Data::Dumper;
    $Data::Dumper::Indent  = 0;
    $Data::Dumper::Useperl = 1;
    $self->logger->debug( "Dump: " . Data::Dumper::Dumper($variable) );
    return;
}

sub sendHtml {
    my ( $self, $req, $template, %args ) = @_;

    my $templateDir = $self->conf->{templateDir} . '/' . $self->getSkin($req);
    $self->templateDir( [ $templateDir, @{ $self->templateDir } ] );

    # Check template
    $args{templateDir} = $templateDir;
    my $tmpl = $args{templateDir} . "/$template.tpl";
    unless ( -f $tmpl ) {
        $self->logger->debug("Template $tmpl not found");
        $args{templateDir} = $self->conf->{templateDir} . '/bootstrap';
        $tmpl = $args{templateDir} . "/$template.tpl";
        $self->logger->debug("-> Trying to load $tmpl");
    }

    # Override messages
    my $trOverMessages = JSON::from_json( $self->trOver );

    unless ( $self->trOverCache->{$templateDir} ) {
        opendir( DIR, $templateDir );
        my @langfiles = grep( /\.json$/, readdir(DIR) );
        close(DIR);

        foreach my $file (@langfiles) {
            my ($lang) = ( $file =~ /^(\w+)\.json/ );
            $self->logger->debug("Use $file to override messages");
            if ( open my $json, "<", $templateDir . "/" . $file ) {
                local $/ = undef;
                $trOverMessages->{$lang} = JSON::from_json(<$json>);
            }
            else {
                $self->logger->error("Unable to read $file");
            }
        }

        $self->trOverCache->{$templateDir} = JSON::to_json($trOverMessages);
    }
    $args{params}->{TROVER} = $self->trOverCache->{$templateDir};

    my $res = $self->SUPER::sendHtml( $req, $template, %args );
    push @{ $res->[1] },
      'X-XSS-Protection'       => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'Cache-Control' => 'no-cache, no-store, must-revalidate',    # HTTP 1.1
      'Pragma'        => 'no-cache',                               # HTTP 1.0
      'Expires'       => '0';                                      # Proxies

    my @cors = split /;/, $self->cors;
    if ( $self->conf->{corsEnabled} ) {
        push @{ $res->[1] }, @cors;
        $self->logger->debug(
            "Apply following CORS policy : " . Data::Dumper::Dumper( \@cors ) );
    }

    # Set authorized URL for POST
    my $csp = $self->csp . "form-action " . $self->conf->{cspFormAction};
    if ( my $url = $req->urldc ) {
        $self->logger->debug("Required urldc : $url");
        $url =~ s#(https?://[^/]+).*#$1#;
        $self->logger->debug("Set CSP form-action with urldc : $url");
        $csp .= " $url";
    }
    my $url = $args{params}->{URL};
    if ( defined $url ) {
        $self->logger->debug("Required Params URL : $url");
        if ( $url =~ s#(https?://[^/]+).*#$1# ) {
            $self->logger->debug("Set CSP form-action with Params URL : $url");
            $csp .= " $url";
        }
    }
    if ( defined $req->{cspFormAction} ) {
        $self->logger->debug(
            "Set CSP form-action with request URL: " . $req->{cspFormAction} );
        $csp .= " " . $req->{cspFormAction};
    }

    # Set SAML Discovery Protocol in form-action
    # See https://github.com/w3c/webappsec-csp/issues/8
    if ( $self->conf->{samlDiscoveryProtocolActivation}
        and defined $self->conf->{samlDiscoveryProtocolURL} )
    {
        $self->logger->debug(
            "Add SAML Discovery Protocol URL in CSP form-action");

        $csp .= " " . $self->conf->{samlDiscoveryProtocolURL};
    }
    $csp .= ';';

    # Deny using portal in frame except if it is required
    unless ( $req->frame or $self->conf->{portalAntiFrame} == 0 ) {
        push @{ $res->[1] }, 'X-Frame-Options' => 'DENY';
        $csp .= "frame-ancestors 'none';";
    }

    # Check if frames need to be embedded
    my @url;
    if ( $req->info ) {
        @url = map { s#https?://([^/]+).*#$1#; $_ }
          ( $req->info =~ /<iframe.*?src="(.*?)"/sg );
    }
    if (@url) {
        $csp .= join( ' ', 'child-src', @url, "'self'" ) . ';';
    }

    # Set CSP header
    push @{ $res->[1] }, 'Content-Security-Policy' => $csp;
    $self->logger->debug("Apply following CSP : $csp");
    return $res;
}

sub sendCss {
    my ( $self, $req ) = @_;
    my $s = '/* LL::NG Portal CSS */';
    if ( $self->conf->{portalSkinBackground} ) {
        $s .=
            'html,body{background:url("'
          . $self->staticPrefix
          . '/common/backgrounds/'
          . $self->conf->{portalSkinBackground}
          . '") no-repeat center fixed;'
          . 'background-size:cover;}';
    }
    return [
        200,
        [
            'Content-Type'   => 'text/css',
            'Content-Length' => length($s),
            'Cache-Control'  => 'public,max-age=3600',
        ],
        [$s]
    ];
}

sub lmError {
    my ( $self, $req, $error ) = @_;
    my $httpError = $req->param('code') || $error;

    # Check URL
    $self->controlUrl($req);
    $req->pdata( {} ) unless ( $httpError == 404 );

    if ( $req->wantJSON ) {
        return $self->sendJSONresponse(
            $req,
            { error => $httpError, result => 0 },
            code => $httpError
        );
    }

    my %templateParams = (
        MAIN_LOGO  => $self->conf->{portalMainLogo},
        LANGS      => $self->conf->{showLanguages},
        LOGOUT_URL => $self->conf->{portal} . "?logout=1",
        URL        => $req->{urldc},
    );

    # Error code
    $templateParams{"ERROR$_"} = ( $httpError == $_ ? 1 : 0 )
      foreach ( 403, 404, 500, 502, 503 );
    return $self->sendHtml( $req, 'error', params => \%templateParams );
}

sub rebuildCookies {
    my ( $self, $req ) = @_;
    my @tmp;
    for ( my $i = 0 ; $i < @{ $req->{respHeaders} } ; $i += 2 ) {
        push @tmp, $req->respHeaders->[$i], $req->respHeaders->[ $i + 1 ]
          unless ( $req->respHeaders->[$i] eq 'Set-Cookie' );
    }
    $req->{respHeaders} = \@tmp;
    $self->buildCookie($req);
}

sub tplParams {
    my ( $self, $req ) = @_;
    my %templateParams;

    my $portalPath = $self->conf->{portal};
    $portalPath =~ s#^https?://[^/]+/?#/#;
    $portalPath =~ s#[^/]+\.fcgi$##;

    for my $session_key ( keys %{ $req->{sessionInfo} } ) {
        $templateParams{ "session_" . $session_key } =
          $req->{sessionInfo}->{$session_key};
    }

    for my $env_key ( keys %{ $req->env } ) {
        $templateParams{ "env_" . $env_key } = $req->env->{$env_key};
    }

    return (
        SKIN       => $self->getSkin($req),
        PORTAL_URL => $self->conf->{portal},
        SKIN_PATH  => $portalPath . "skins",
        SKIN_BG    => $self->conf->{portalSkinBackground},
        ( $self->customParameters ? ( %{ $self->customParameters } ) : () ),
        %templateParams
    );
}

sub registerLogin {
    my ( $self, $req ) = @_;
    return
      unless ( $self->conf->{loginHistoryEnabled}
        and defined $req->authResult );

    # Check old login history
    if ( $req->sessionInfo->{loginHistory} ) {

        if ( !$req->sessionInfo->{_loginHistory} ) {
            $self->logger->debug("Restore old login history");

            # Restore success login
            $req->sessionInfo->{_loginHistory}->{successLogin} =
              $req->sessionInfo->{loginHistory}->{successLogin};

            # Restore failed login, with generic error
            if ( $req->sessionInfo->{loginHistory}->{failedLogin} ) {
                $self->logger->debug("Restore old failed logins");
                $req->sessionInfo->{_loginHistory}->{failedLogin} = [];
                foreach (
                    @{ $req->sessionInfo->{loginHistory}->{failedLogin} } )
                {
                    $self->logger->debug(
                        "Replace old failed login error " . $_->{error} );
                    $_->{error} = 5;
                    push @{ $req->sessionInfo->{_loginHistory}->{failedLogin} },
                      $_;
                }
            }
        }
        $self->updatePersistentSession( $req, { 'loginHistory' => undef } );
        delete $req->sessionInfo->{loginHistory};
    }

    my $history = $req->sessionInfo->{_loginHistory} ||= {};
    my $type = ( $req->authResult > 0 ? 'failed' : 'success' ) . 'Login';
    $history->{$type} ||= [];
    $self->logger->debug("Current login saved into $type");

    # Gather current login's parameters
    my $login = $self->_sumUpSession( $req->{sessionInfo}, 1 );
    $login->{error} = $self->error( $req->authResult )
      if ( $req->authResult );

    $self->logger->debug( " Current login -> " . $login->{error} )
      if ( $login->{error} );

    # Add current login into history
    unshift @{ $history->{$type} }, $login;

    # Forget oldest logins
    splice @{ $history->{$type} }, $self->conf->{ $type . "Number" }
      if ( scalar @{ $history->{$type} } > $self->conf->{ $type . "Number" } );

    # Save into persistent session
    $self->updatePersistentSession( $req, { _loginHistory => $history, } );

    PE_OK;
}

# put main session data into a hash ref
# @param hashref $session The session to sum up
# @return hashref
sub _sumUpSession {
    my ( $self, $session, $withoutUser ) = @_;
    my $res =
      $withoutUser
      ? {}
      : { user => $session->{ $self->conf->{whatToTrace} } };
    $res->{$_} = $session->{$_}
      foreach ( "_utime", "ipAddr",
        keys %{ $self->conf->{sessionDataToRemember} } );
    return $res;
}

# Temlate loader
sub loadTemplate {
    my ( $self, $req, $name, %prm ) = @_;
    $name .= '.tpl';
    my $tpl = HTML::Template->new(
        filename => $name,
        path     => [
            $self->conf->{templateDir} . '/' . $self->getSkin($req),
            $self->conf->{templateDir} . '/bootstrap/',
            $self->conf->{templateDir} . '/common/'
        ],
        search_path_on_include => 1,
        die_on_bad_params      => 0,
        die_on_missing_include => 1,
        cache                  => 1,
        global_vars            => 0,
        ( $prm{filter} ? ( filter => $prm{filter} ) : () ),
    );
    if ( $prm{params} ) {
        $tpl->param( %{ $prm{params} } );
    }
    return $tpl->output;
}

1;
