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

our $VERSION = '2.21.0';

package Lemonldap::NG::Portal::Main;

use strict;
use URI::Escape;
use URI;
use JSON;
use Lemonldap::NG::Common::Util qw(getPSessionID getSameSite);

has trOverCache => ( is => 'rw', default => sub { {} } );

# The execution order between groups and macros can be
# modified in config (#1877)
sub groupsAndMacros {
    return (
        $_[0]->conf->{groupsBeforeMacros}
        ? qw(setGroups setMacros)
        : qw(setMacros setGroups)
    );
}

# List constants
sub authProcess { qw(extractFormInfo getUser authenticate) }

sub sessionData {
    return qw(setAuthSessionInfo setSessionInfo), $_[0]->groupsAndMacros,
      qw(setPersistentSessionInfo setLocalGroups rememberBrowserCheck store secondFactor);
}

sub validSession {
    qw(storeHistory rememberBrowser buildCookie);
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

    # Set portal URL dynamically
    $req->portal( HANDLER->tsv->{portal}->($req) );
    my $sp = 0;

    # Restore pdata
    if ( my $v = $req->cookies->{ $self->conf->{cookieName} . 'pdata' } ) {
        $sp = 1;
        eval { $req->pdata( JSON::from_json( uri_unescape($v) ) ); };
        if ($@) {
            $self->logger->error("Bad JSON content in cookie pdata");
            $req->pdata( {} );
        }

        # Avoid fatal errors when using old keepPdata format
        if ( $req->pdata->{keepPdata}
            and not( ref $req->pdata->{keepPdata} eq "ARRAY" ) )
        {
            $req->pdata->{keepPdata} = [];
        }
    }
    my $res = $self->Lemonldap::NG::Common::PSGI::Router::handler($req);

    # Avoid permanent loop 'Portal <-> _url' if pdata cookie is not removed
    if (    $req->userData->{_url}
        and !$req->pdata->{keepPdata}
        and $req->userData->{_session_id}
        and $req->{env}->{HTTP_COOKIE}
        and $req->{env}->{HTTP_COOKIE} eq
        encode_base64( $req->userData->{_url}, '' ) )
    {
        $self->logger->info("Force cleaning pdata");
        $self->logger->warn("pdata cookie domain must be set")
          unless ( $self->conf->{pdataDomain} );
        $req->pdata( {} );
    }

    # Save pdata
    if ( $sp or %{ $req->pdata } ) {
        my %pdata_options = ();
        $pdata_options{domain} = $self->conf->{pdataDomain}
          if $self->conf->{pdataDomain};

        if ( %{ $req->pdata } ) {
            push @{ $res->[1] }, 'Set-Cookie',
              $self->cookie(
                name   => $self->conf->{cookieName} . 'pdata',
                secure => $self->conf->{securedCookie},
                value  => uri_escape( JSON::to_json( $req->pdata ) ),
                %pdata_options,
              );

        }
        else {
            push @{ $res->[1] }, 'Set-Cookie',
              $self->cookie(
                name    => $self->conf->{cookieName} . 'pdata',
                secure  => $self->conf->{securedCookie},
                value   => '',
                expires => 'Wed, 21 Oct 2015 00:00:00 GMT',
                %pdata_options,
              );

            # Avoid regressions with #3228
            push @{ $res->[1] }, 'Set-Cookie',
              $self->genDomainCookie(
                $req,
                name    => $self->conf->{cookieName} . 'pdata',
                secure  => $self->conf->{securedCookie},
                value   => '',
                expires => 'Wed, 21 Oct 2015 00:00:00 GMT',
                %pdata_options,
              );
        }
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

    return $self->do(
        $req,
        [
            'importHandlerData',
            'controlUrl',
            @{ $self->forAuthUser },
            sub {
                $req->response(
                    $self->sendJSONresponse( $req, { status => 1 } ) );
                return PE_SENDRESPONSE;
            }
        ]
    );
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
            'checkUnauthLogout', 'checkCancel',
            'controlUrl',        @{ $self->beforeAuth },
            $self->authProcess,  @{ $self->betweenAuthAndData },
            $self->sessionData,  @{ $self->afterData },
            $self->validSession, @{ $self->endAuth }
        ]
    );
}

sub postLogin {
    my ( $self, $req ) = @_;
    return $self->do(
        $req,
        [
            'checkUnauthLogout', 'restoreArgs',                    # Fix 2342
            'controlUrl',        @{ $self->beforeAuth },
            $self->authProcess,  @{ $self->betweenAuthAndData },
            $self->sessionData,  @{ $self->afterData },
            $self->validSession, @{ $self->endAuth }
        ]
    );
}

sub authenticatedRequest {
    my ( $self, $req ) = @_;
    $req->data->{alreadyAuthenticated} = 1;
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

sub processRefreshSession {
    my ( $self, $req ) = @_;

    my %data = %{ $req->userData };
    $req->user( $data{_user} || $data{ $self->conf->{whatToTrace} } );
    $req->id( $data{_session_id} );

    $self->auditLog(
        $req,
        message => ( 'Refresh request for ' . $req->user ),
        code    => "SESSION_REFRESH",
        user    => $req->user,
    );

    foreach ( keys %data ) {

        # Variables that start with _ are kept accross refresh
        if (/^_/) {

            # But not OIDC tokens, which can be refreshed
            delete $data{$_}
              if (
/^(_oidc_access_token|_oidc_refresh_token|_oidc_access_token_eol)$/
              );
        }

        # Other variables should be refreshed
        else {
            # But not these two
            if (/^(?:startTime|authenticationLevel)$/) {
                next;
            }
            else {
                delete $data{$_};
            }
        }
    }
    $data{_updateTime} = strftime( "%Y%m%d%H%M%S", localtime() );
    $self->logger->debug(
        "Set session $req->{id} _updateTime with $data{_updateTime}");

    # Avoid interferences when refresh is run on multiple sessions
    # in the same request
    $req->sessionInfo( {} );
    $req->steps( [
            'getUser',
            @{ $self->betweenAuthAndData },
            'setSessionInfo',
            sub {
                $_[0]->sessionInfo->{$_} = $data{$_} foreach ( keys %data );
                $_[0]->refresh(1);
                return PE_OK;
            },
            $self->groupsAndMacros,
            'setLocalGroups',
        ]
    );
    return $self->process($req);
}

sub refresh {
    my ( $self, $req ) = @_;
    $req->mustRedirect(1);

    $self->userLogger->notice( 'Refresh request for '
          . $req->userData->{ $self->conf->{whatToTrace} } );

    my $res = $self->processRefreshSession($req);

    # Run additional 'store' step We need to call process() here in case
    # 'store' is hooked by aroundSub or afterSub
    if ( $res == PE_OK ) {
        $req->steps( ['store'] );
        $res = $self->process($req);
    }

    $req->error($res);
    if ($res) {
        $req->info(
            $self->loadTemplate(
                $req,
                'simpleInfo', params => { trspan => 'rightsReloadNeedsLogout' }
            )
        );
        $req->urldc( $req->portal );
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
        ],
        1,    # No fail: logout should continue even if errors
    );
}

sub unauthLogout {
    my ( $self, $req ) = @_;
    $self->_unauthLogout($req);
    return $self->do( $req, [ 'controlUrl', sub { PE_LOGOUT_OK } ] );
}

sub _unauthLogout {
    my ( $self, $req ) = @_;
    $self->processHook( $req, 'unAuthLogout' );
    $self->logger->debug('Unauthenticated logout request');
    $self->logger->debug('Cleaning pdata');
    $self->logger->debug("Removing $self->{conf}->{cookieName} cookie");
    $req->pdata( {} );
    $req->addCookie(
        $self->genDomainCookie(
            $req,
            name    => $self->conf->{cookieName},
            secure  => $self->conf->{securedCookie},
            expires => 'Wed, 21 Oct 2015 00:00:00 GMT',
            value   => 0
        )
    );
}

# RUNNING METHODS
# ---------------

sub do {
    my ( $self, $req, $steps, $nofail ) = @_;
    $req->steps($steps);
    $req->data->{activeTimer} = $self->conf->{activeTimer};
    my $err = $req->error( $self->process( $req, nofail => $nofail ) );

    # Update status
    $self->HANDLER->publishStatus(
        user       => ( $req->user ? $req->user : $req->address ),
        url        => $req->{env}->{HTTP_HOST} . $req->{env}->{REQUEST_URI},
        portalCode => $err,
    );

    # Update history
    return $req->response if $err == PE_SENDRESPONSE;

    # Remove userData if authentication fails
    $req->userData( {} ) if ( $err == PE_BADCREDENTIALS or $err == PE_BADOTP );

    if ( !$self->conf->{noAjaxHook} and $req->wantJSON ) {
        $self->logger->debug('Processing to JSON response');
        if ( ( $err > 0 and !$req->id ) or $err eq PE_SESSIONNOTGRANTED ) {
            my $json = { result => 0, error => $err };
            if ( $req->wantErrorRender ) {
                $json->{html} = $self->loadTemplate( $req, 'errormsg',
                    params => { $self->getErrorTplParams($req) } );
            }
            return $self->sendJSONresponse(
                $req, $json,
                code    => 401,
                headers => [
                    'WWW-Authenticate' => "SSO " . $req->portal,
                    "Content-Type"     => "application/json"
                ],
            );
        }
        elsif ( $err > 0 and $err != PE_PASSWORD_OK and $err != PE_LOGOUT_OK ) {
            return $self->sendJSONresponse(
                $req,
                {
                    result => 0,
                    error  => $err,
                    (
                        $err == PE_NOTIFICATION && $req->id
                        ? ( ciphered_id => $req->id )
                        : ()
                    )
                },
                code => 400
            );
        }
        else {
            my $res = { result => 1, error => $err };
            unless ( $req->data->{alreadyAuthenticated} ) {
                $res->{id}      = $req->id;
                $res->{id_http} = $req->sessionInfo->{_httpSession}
                  if $req->sessionInfo->{_httpSession};
            }
            return $self->sendJSONresponse( $req, $res );
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
    if ( my $val =
        $req->userData->{ { auth => '_auth', user => '_userDB' }->{$type} } )
    {
        return $val;
    }
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
    if ( $req->mustRedirect and not( $req->info ) ) {
        if ( $req->error == PE_LOGOUT_OK ) {
            if ( !$req->urldc or !$self->_isExternalUrl( $req, $req->urldc ) ) {
                $req->urldc(
                    $self->buildUrl( $req->portal, { "logout" => 1 } ) );
            }
        }
        else {
            $req->{urldc} ||= $req->portal;
        }
    }

    # Redirection should be made if urldc defined
    if ( $req->{urldc} ) {
        if ( $req->{urldc} =~ /^\s*((?:java|vb)script|data):/ ) {
            $self->auditLog(
                $req,
                message  => "Redirection to $req->{urldc} blocked",
                code     => "UNAUTHORIZED_REDIRECT",
                url      => $req->{urldc},
                user     => $req->sessionInfo->{ $self->conf->{whatToTrace} } || $req->user,
            );
            delete $req->{urldc};
        }
        else {
            $self->logger->debug("Building redirection to $req->{urldc}");
            if (    $req->{pdata}->{_url}
                and $req->{pdata}->{_url} eq encode_base64( $req->{urldc}, '' )
              )
            {
                $self->logger->info("Force cleaning pdata");
                delete $req->{pdata}->{_url};
            }
            if ( $self->_jsRedirect->( $req, $req->sessionInfo ) ) {
                $req->error(PE_REDIRECT);
                $req->data->{redirectFormMethod} = "get";
            }
            else {
                return [
                    302,
                    [
                        Location => URI->new( $req->{urldc} )->as_string,
                        $req->spliceHdrs
                    ],
                    []
                ];
            }
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

            # The $args{hashStore} permits one to override the
            # hashedSessionStore parameter. It is used when sessions are given
            # by searchOn (like in Refresh plugin)
            hashStore => $args{hashStore} // $self->conf->{hashedSessionStore},
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
    $self->logger->debug("Get session $id from Portal::Main::Run")
      if ($id);
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

    return
      unless ( defined $uid
        and !$self->conf->{disablePersistentStorage} );

    # Compute persistent identifier
    my $pid = getPSessionID($uid);

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
    return ()
      unless ( ref $infos eq 'HASH'
        and %$infos
        and !$self->conf->{disablePersistentStorage} );

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
            "Cannot update persistent session " . getPSessionID($uid) );
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
    $id ||= $req->id || $req->userData->{_session_id};

    if ($id) {

        # Update sessionInfo data
        ## sessionInfo updated if $id defined : quite strange!!
        ## See https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues/430
        $self->logger->debug("Update session $id");
        foreach ( keys %$infos ) {
            $self->logger->debug("Update sessionInfo $_");
            $self->_dump( $infos->{$_} );
            $req->{sessionInfo}->{$_} = $infos->{$_};
            if (   $self->HANDLER->data->{_session_id}
                && $id eq $self->HANDLER->data->{_session_id} )
            {
                $self->HANDLER->data->{$_} = $infos->{$_};
            }
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

        # remove the corresponding session from handler cache
        HANDLER->publishEvent( $req, { action => 'unlog', id => $id } );
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
            $self->genDomainCookie(
                $req,
                name    => $self->conf->{cookieName} . 'http',
                value   => 0,
                secure  => 0,
                expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
            )
        ) unless ($preserveCookie);
    }

    # Publishing an "unlog" event will automatically remove the corresponding
    # session from handler cache. See publishEvent into Handler::Main::Run
    HANDLER->publishEvent( $req, { action => 'unlog', id => $session->id } );
    $session->remove;

    # Create an obsolete cookie to remove it
    $req->addCookie(
        $self->genDomainCookie(
            $req,
            name    => $self->conf->{cookieName},
            value   => 0,
            secure  => $self->conf->{securedCookie},
            expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
        )
    ) unless ($preserveCookie);

    # Log
    my $user = $req->{sessionInfo}->{ $self->conf->{whatToTrace} };
    my $mod  = $req->{sessionInfo}->{_auth};
    if ($user) {
        $self->auditLog(
            $req,
            message => (
"User $user has been disconnected from $mod ($req->{sessionInfo}->{ipAddr})"
            ),
            code     => "LOGOUT",
            user     => $user,
            auth     => $mod,
        );
    }

    return $session->error ? 0 : 1;
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
    if ( $req->{urldc} =~ /^\s*((?:java|vb)script|data):/ ) {
        $self->auditLog(
            $req,
            message  => "Redirection to $req->{urldc} blocked",
            code     => "UNAUTHORIZED_REDIRECT",
            url      => $req->{urldc},
            user     => $req->sessionInfo->{ $self->conf->{whatToTrace} } || $req->user,
        );
        return PE_BADURL;
    }
    my $formFields = $req->postFields;

    $self->clearHiddenFormValue($req);
    foreach ( keys %$formFields ) {
        $self->setHiddenFormValue( $req, $_, $formFields->{$_}, "", 0 );
    }

    # Display info before redirecting
    if ( $req->info() ) {
        $req->data->{infoFormMethod} = $req->param('method') || "post";
        return PE_INFO;
    }

    $req->data->{redirectFormMethod} = "post";

    # Case 2F wait
    if ( $req->data->{sfWait} ) {
        return PE_2FWAIT;
    }

    # Default case -> redirect
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
    my $pHost = $req->portal;
    $pHost =~ s#^(https?://[^/]+)(?:/.*)?$#$1#;
    return $pHost . $req->env->{REQUEST_URI};
}

# Generates a cookie header which can depend on the request
# If no domain was explicitely specified, use the default SSO domain
sub genDomainCookie {
    my ( $self, $req, %h ) = @_;

    $h{domain} ||= $self->getCookieDomain($req);
    return $self->cookie(%h);
}

# DEPRECATED, #3228
sub genCookie {
    my ( $self, $req, %h ) = @_;
    return $self->cookie(%h);
}

# Generate a cookie header
# If no domain was explicitely specified, only the portal will see
# this cookie
sub cookie {
    my ( $self, %h ) = @_;
    $h{path} ||= '/';
    $h{HttpOnly} //= $self->conf->{httpOnly};
    $h{max_age}  //= $self->conf->{cookieExpiration}
      if ( $self->conf->{cookieExpiration} );
    $h{SameSite} ||= $self->cookieSameSite;

    return $self->assemble_cookie(%h);
}

sub assemble_cookie {
    my ( $self, %h ) = @_;

    my @res;
    $res[0] = "$h{name}" or die("name required");
    $res[0] .= "=$h{value}";

    foreach (qw(domain path expires max_age HttpOnly SameSite)) {
        my $f = $_;
        $f =~ s/_/-/g;
        push @res, "$f=$h{$_}" if ( $h{$_} );
    }
    push @res, 'secure' if ( $h{secure} );
    return join( '; ', @res );
}

sub _dump {
    my ( $self, $variable ) = @_;
    if ( $self->conf->{logLevel} eq 'debug' ) {
        require Data::Dumper;
        $Data::Dumper::Indent  = 0;
        $Data::Dumper::Useperl = 1;
        $self->logger->debug( "Dump: " . Data::Dumper::Dumper($variable) );
    }
    return;
}

sub getSkinTplDir {
    my ( $self, $skin ) = @_;

    my $base = $self->conf->{skinTemplateDir} || $self->conf->{templateDir};
    return ( $base . '/' . $skin );
}

# Warning: this function returns a JSON string
sub getTrOver {
    my ( $self, $req, $templateDir ) = @_;

    $templateDir //= $self->getSkinTplDir( $self->getSkin($req) );

    unless ( $self->trOverCache->{$templateDir} ) {

        # Override messages
        my $trOverMessages = JSON::from_json( $self->trOver );

        opendir( DIR, $templateDir );
        my @langfiles = grep( /\.json$/, readdir(DIR) );
        close(DIR);

        foreach my $file (@langfiles) {
            my ($lang) = ( $file =~ /^(\w+)\.json/ );
            $self->logger->debug("Use $file to override messages");
            if ( open my $json, "<", $templateDir . "/" . $file ) {
                my $trdata;
                eval {
                    local $/ = undef;
                    $trdata = JSON::from_json(<$json>);
                };
                if ($@) {
                    $self->logger->warn("Ignoring $file because of error: $@");
                }
                if ( ref($trdata) eq "HASH" ) {
                    for my $msg ( keys %$trdata ) {

                        # lemonldap-ng.ini has priority
                        $trOverMessages->{$lang}->{$msg} //= $trdata->{$msg};
                    }
                }
            }
            else {
                $self->logger->error("Unable to read $file");
            }
        }

        $self->trOverCache->{$templateDir} = JSON::to_json($trOverMessages);
    }

    return $self->trOverCache->{$templateDir};
}

sub sendHtml {
    my ( $self, $req, $template, %args ) = @_;
    if ( $self->conf->{logParams} ) {
        $self->_dump($req);
        $self->_dump( \%args );
    }

    my $skin_template_dir = $self->getSkinTplDir( $self->getSkin($req) );

    # Look for templates in skin subdirectories instead of templateDir
    $args{templateDir} =
      [ $skin_template_dir, $self->conf->{templateDir} . "/bootstrap" ];

    $args{params}->{TROVER} = $self->getTrOver( $req, $skin_template_dir );

    $self->processHook( $req, 'sendHtml', \$template, \%args );

    my $res = $self->SUPER::sendHtml( $req, $template, %args );
    push @{ $res->[1] },
      'X-XSS-Protection'       => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'Cache-Control' => 'no-cache, no-store, must-revalidate',    # HTTP 1.1
      'Pragma'        => 'no-cache',                               # HTTP 1.0
      'Expires'       => '0';                                      # Proxies

    $self->setCorsHeaderFromConfig($res);

    if (    $self->conf->{strictTransportSecurityMax_Age}
        and $req->portal =~ /^https:/ )
    {
        push @{ $res->[1] },
          'Strict-Transport-Security' =>
          "max-age=$self->{conf}->{strictTransportSecurityMax_Age}";
        $self->logger->debug(
"Set Strict-Transport-Security with: $self->{conf}->{strictTransportSecurityMax_Age}"
        );
    }

    # Set authorized URL for POST
    my $csp = $self->csp . "form-action " . $self->conf->{cspFormAction};
    if ( my $url = $req->urldc ) {
        $self->logger->debug("Required urldc: $url");
        my $host = $self->cspGetHost($url);
        if ($host) {
            $self->logger->debug("Set CSP form-action with urldc: $url");
            $csp .= " $host";
        }
    }
    my $url = $args{params}->{URL};
    if ( defined $url ) {
        $self->logger->debug("Required Params URL: $url");
        my $host = $self->cspGetHost($url);
        if ($host) {
            $self->logger->debug("Set CSP form-action with Params URL: $url");
            $csp .= " $host";
        }
    }
    if ( defined $req->data->{cspFormAction}
        and ref( $req->data->{cspFormAction} ) eq "HASH" )
    {
        my $request_csp_form_action =
          join( " ", keys %{ $req->data->{cspFormAction} } );
        $self->logger->debug( "Set CSP form-action with request URL: "
              . $request_csp_form_action );
        $csp .= " " . $request_csp_form_action;
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
    unless ( $req->frame
        or $self->conf->{portalAntiFrame} == 0
        or $self->conf->{cspFrameAncestors} )
    {
        push @{ $res->[1] }, 'X-Frame-Options' => 'DENY';
        $csp .= "frame-ancestors 'none';";
    }
    if ( $self->conf->{cspFrameAncestors} ) {
        push @{ $res->[1] }, 'X-Frame-Options' => 'ALLOW-FROM '
          . "$self->{conf}->{cspFrameAncestors};";
        $csp .= "frame-ancestors $self->{conf}->{cspFrameAncestors};";
    }

    # Check if frames need to be embedded
    # FIXME: we should use $req->data->{cspChildSrc} anywhere an iframe is
    # created in the code, and remove this
    my @url;
    if ( $req->info ) {
        @url = map { s#https?://([^/]+).*#$1#r }
          ( $req->info =~ /<iframe.*?src="(.*?)"/sg );
    }

    # Update child-src header from request data
    if ( ref( $req->data->{cspChildSrc} ) eq "HASH" ) {
        push @url, keys %{ $req->data->{cspChildSrc} };
    }
    if (@url) {
        $csp .= join( ' ', 'child-src', @url, "'self'" ) . ';';
    }

    # Set CSP header
    push @{ $res->[1] }, 'Content-Security-Policy' => $csp
      unless $req->data->{dropCsp};
    $self->logger->debug("Apply following CSP: $csp");
    return $res;
}

sub imgok {
    my ( $self, $req, ) = @_;
    return $self->sendImage( $req, 'icons/ok.png' );
}

sub imgnok {
    my ( $self, $req, ) = @_;
    return $self->sendImage( $req, 'icons/warning.png' );
}

sub sendImage {
    my ( $self, $req, $img ) = @_;
    my $u = URI->new_abs( $self->staticPrefix . "/common/$img", $req->portal )
      ->as_string;

    return [
        302,
        [
            'Location' => $u,
        ],
        [],
    ];
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
        LOGOUT_URL => $self->buildUrl( $req->portal, { logout => 1 } ),
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

    my $portalPath = $req->portal;
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
        CACHE_TAG    => $self->cacheTag,
        PORTAL_URL   => $req->portal,
        PORTAL_BASE  => $portalPath,
        MAIN_LOGO    => $self->conf->{portalMainLogo},
        LANGS        => $self->conf->{showLanguages},
        SCROLL_TOP   => $self->conf->{scrollTop},
        FLOATING_CAT => $self->conf->{floatingCategoryName},
        SKIN         => $self->getSkin($req),
        SKIN_PATH    => $portalPath . "skins",
        SAMESITE     => getSameSite( $self->conf ),
        COOKIESECURE => ( $self->conf->{securedCookie} ? 1 : 0 ),
        SKIN_BG      => $self->conf->{portalSkinBackground},
        FAVICON      => $self->conf->{portalFavicon} || 'common/favicon.ico',
        LANGUAGE     => $self->getLanguage($req),
        CUSTOM_CSS   => $self->conf->{portalCustomCss},
        CUSTOM_JS    => $self->conf->{portalCustomJs},
        (
            $self->customParameters
            ? ( %{ $self->customParameters } )
            : ()
        ),
        %templateParams
    );
}

sub getErrorTplParams {
    my ( $self, $req ) = @_;

    my $err = $req->error;

    return (
        AUTH_ERROR               => $err,
        ( 'AUTH_ERROR_' . $err ) => 1,
        AUTH_ERROR_TYPE          => $req->error_type,
        AUTH_ERROR_ROLE          => $req->error_role,
        LOCKTIME                 => $req->lockTime(),
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
    my $type    = ( $req->authResult > 0 ? 'failed' : 'success' ) . 'Login';
    $history->{$type} ||= [];
    $self->logger->debug("Current login saved into $type");

    # Gather current login's parameters and force current time
    my $login =
      $self->_sumUpSession( { %{ $req->sessionInfo }, _utime => time }, 1 );
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

# Register access to protected app
# @param Lemonldap::NG::Portal::Main::Request $req The request
# @param string $uid The connected user ident
# @param string $app The application client/RP namespaced with protocol
sub registerProtectedAppAccess {
    my ( $self, $req, $uid, $app ) = @_;

    return unless $self->conf->{appAccessHistoryEnabled};

    $self->logger->debug("Registering $app access for user $uid");

    my $persistentSession = $self->getPersistentSession($uid);
    my $entry = $persistentSession->data->{_appHistory}->{$app} || {};

    $entry->{access_time} = time();
    $entry->{access_count}++;

    $self->updatePersistentSession(
        $req,
        {
            _appHistory => {
                %{ $persistentSession->data->{_appHistory} }, $app => $entry
            }
        },
        $uid
    );
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
      foreach (
        "_utime", "ipAddr",
        map {
            # Modifying key to remove ordering prefix
            $_ =~ s/(\d+_)?//;
            $_;
        } keys %{ $self->conf->{sessionDataToRemember} },
        keys %{ $self->pluginSessionDataToRemember }
      );
    return $res;
}

sub corsPreflight {
    my ( $self, $req ) = @_;
    my @headers;
    my $res = [ 204, \@headers, [] ];

    $self->setCorsHeaderFromConfig($res);

    return $res;
}

sub sendJSONresponse {
    my ( $self, $req, $j, %args ) = @_;
    $j->{token} = $req->token if $req->token;
    my $res = Lemonldap::NG::Common::PSGI::sendJSONresponse(@_);

    # Handle caching
    if ( $args{ttl} and $args{ttl} =~ /^\d+$/ ) {
        push @{ $res->[1] }, 'Cache-Control' => 'public, max-age=' . $args{ttl};
    }
    else {
        push @{ $res->[1] },
          'Cache-Control' => 'no-cache, no-store, must-revalidate',
          'Pragma'        => 'no-cache',
          'Expires'       => '0';
    }

    # If this is a cross-domain request from the portal itself
    # (Ajax SSL to a different VHost)
    # we allow CORS
    if ( $self->_checkSelfCors($req) ) {
        $self->logger->debug('AJAX request from portal, allowing CORS');
        push @{ $res->[1] },
          "Access-Control-Allow-Origin"      => $req->origin,
          "Access-Control-Allow-Methods"     => "*",
          "Access-Control-Allow-Credentials" => "true";

    }
    else {
        $self->setCorsHeaderFromConfig($res);
    }
    return $res;
}

sub _checkSelfCors {
    my ( $self, $req ) = @_;

    if ( $req->origin ) {
        my $origin = URI->new( $req->origin );
        my $portal = URI->new( $req->portal );

        return (  $origin->scheme
              and $portal->scheme eq $origin->scheme
              and $origin->host_port
              and $origin->host_port eq $portal->host_port );
    }
    return;
}

sub sendRawHtml {
    my ($self) = $_[0];
    my $res = Lemonldap::NG::Common::PSGI::sendRawHtml(@_);

    $self->setCorsHeaderFromConfig($res);

    return $res;
}

sub setCorsHeaderFromConfig {
    my ( $self, $response ) = @_;

    if ( $self->conf->{corsEnabled} ) {
        my @cors = split /;/, $self->cors;
        push @{ $response->[1] }, @cors;
        $self->logger->debug('Apply following CORS policy:');
        $self->logger->debug(" $_") for @cors;
    }
}

# Temlate loader
sub loadTemplate {
    my ( $self, $req, $name, %prm ) = @_;

    $self->processHook( $req, 'sendHtml', \$name, \%prm );
    $name .= '.tpl';
    my $tpl = HTML::Template->new(
        filename => $name,
        path     => [
            $self->getSkinTplDir( $self->getSkin($req) ),
            $self->conf->{templateDir} . '/bootstrap/',
            $self->conf->{templateDir} . '/common/'
        ],
        search_path_on_include => 1,
        die_on_bad_params      => 0,
        die_on_missing_include => 1,
        cache                  => ( defined $prm{cache} ? $prm{cache} : 1 ),
        global_vars            => 0,
        ( $prm{filter} ? ( filter => $prm{filter} ) : () ),
    );
    if ( $self->can('tplParams') ) {
        $tpl->param( $self->tplParams($req) );
    }
    if ( $prm{params} ) {
        $tpl->param( %{ $prm{params} } );
    }
    return $tpl->output;
}

# This method extracts the scheme://host:port part of a URL for use in
# Content-Security-Polity header
sub cspGetHost {
    my ( $self, $url ) = @_;
    return unless $url;
    my $uri = $url;
    unless ( blessed($uri) && $uri->isa("URI") ) {
        $uri = URI->new($uri);
    }
    my $scheme = $uri->scheme || "";
    if ( $scheme =~ /^https?/ ) {
        return (
            $scheme . "://"
              . (
                ( $uri->port == $uri->default_port )
                ? $uri->host
                : $uri->host_port
              )
        );
    }
    elsif ($scheme) {
        return ( $scheme . ":" );
    }
    return;
}

sub relativeUrl {
    my $self = shift;
    my $req  = shift;

    my $uri = $self->_buildUrlObj( $req->portal, @_ );
    return $uri->path_query;
}

sub buildUrl {
    my $self = shift;
    return $self->portal unless @_;

    return $self->_buildUrlObj(@_)->as_string;
}

sub _buildUrlObj {
    my $self = shift;
    return URI->new( $self->portal ) unless @_;

    # URL base is $self->portal unless first arg is an URL
    my $uri =
      URI->new( ( $_[0] =~ m#^https?://# ) ? shift(@_) : $self->portal );
    my @pathSg = grep { $_ ne '' } $uri->path_segments;
    while (@_) {
        my $s = shift;
        if ( ref $s ) {
            $uri->query_form($s);
            if (@_) {
                require Carp;
                Carp::confess('Query must be the last arg of buildUrl');
            }
        }
        else {
            push @pathSg, $s;
        }
    }
    $uri->path_segments(@pathSg);
    return $uri;
}

sub rememberBrowser {
    my ( $self, $req ) = @_;

    if (    $self->getService('trustedBrowser')
        and $self->getService('trustedBrowser')->can("newDevice") )
    {
        return $self->getService('trustedBrowser')->newDevice($req);
    }
    else {
        return PE_OK;
    }
}

sub rememberBrowserCheck {
    my ( $self, $req ) = @_;

    if (    $self->getService('trustedBrowser')
        and $self->getService('trustedBrowser')->can("check") )
    {
        return $self->getService('trustedBrowser')->check($req);
    }
    else {
        return PE_OK;
    }
}

1;
