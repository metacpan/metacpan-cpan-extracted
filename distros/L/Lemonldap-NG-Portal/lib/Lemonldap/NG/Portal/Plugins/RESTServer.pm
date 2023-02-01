# Session server plugin for REST requests
#
# This plugin adds the following entry points:
# - Sessions backend (if restSessionServer is on)
#   * GET /sessions/<type>/<session-id>          : get session data
#   * GET /sessions/<type>/<session-id>/<key>    : get a session key value
#   * GET /sessions/<type>/<session-id>/[k1,k2]  : get some session key value
#   * POST /sessions/<type>                      : create a session
#   * POST /sessions/<type>?all=1                : get all sessions (needs a token)
#   * POST /sessions/<type>?all=1&search=uid,dwho: search all sessions where uid=dwho (needs a token)
#   * PUT /sessions/<type>/<session-id>          : update some keys
#   * DELETE /sessions/<type>/<session-id>       : delete a session
#
# - Sessions for connected users (if restSessionServer is on):
#   * GET /session/my/<type>                     : get session data
#   * GET /session/my/<type>/key                 : get session key
#   * DELETE /session/my                         : ask for logout
#   * DELETE /sessions/my                        : ask for global logout (if GlobalLogout plugin is on)
#
# - Authentication
#   * POST /sessions/<type>/<session-id>?auth    : authenticate with a fixed
#                                                  sessionId
#   * Note that the "getCookie" method (authentification via SOAP) exists for
#      REST requests directly by using '/' path : the portal recognize REST
#      calls and generate JSON response instead of web page.
#
# - Configuration (if restConfigServer is on)
#   * GET /config/latest                          : get the last config metadata
#   * GET /config/<cfgNum>                        : get the metadata for config
#                                                  n° <cfgNum>
#   * GET /config/<latest|cfgNum>/<key>           : get conf key value
#   * GET /config/<latest|cfgNum>?full            : get the full configuration
#   where <type> is the session type ("global" for SSO session or "persistent")
#   * GET /error/<lang>/<errNum>                  : get <errNum> message reference and errors file <lang>.json
#   Return 'en' error file if no <lang> specified
#
# - Endpoints for proxy auth/userdb/password
#   * POST /proxy/getUser                        : get user attributes (restAuthServer)
#   * POST /proxy/pwdReset                       : reset password (restPasswordServer)
#   * POST /proxy/pwdConfirm                     : check password (restAuthServer or restPasswordServer)
#
# - Authorizations for connected users (always):
#   * GET /mysession/?whoami                               : get "my" uid
#   * GET /mysession/?authorizationfor=<base64-encoded-url>: ask if url is
#                                                            authorized
#   * PUT /mysession/<type>                                : update some
#                                                            persistent data
#                                                            (restricted)
#   * DELETE /mysession/<type>/key                         : delete key in data
#                                                            (restricted)
#   * GET    /myapplications                               : get my appplications
#                                                            list
#
# There is no conflict with SOAP server, they can be used together

package Lemonldap::NG::Portal::Plugins::RESTServer;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use MIME::Base64;
use Lemonldap::NG::Portal::Main::Constants qw(
  URIRE
  PE_OK
  portalConsts
  PE_PASSWORD_OK
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has configStorage => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->{p}->HANDLER->localConfig->{configStorage};
    }
);
has exportedAttr => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $conf = $_[0]->{conf};
        if ( $conf->{exportedAttr} and $conf->{exportedAttr} !~ /^\s*\+/ ) {
            return '[' . join( ',', split /\s+/, $conf->{exportedAttr} ) . ']';
        }
        else {
            my @attributes = (
                'authenticationLevel', 'groups',
                'ipAddr',              '_startTime',
                '_utime',              '_lastSeen',
                '_session_id',         '_session_kind',
            );
            if ( my $exportedAttr = $conf->{exportedAttr} ) {
                $exportedAttr =~ s/^\s*\+\s+//;
                @attributes = ( @attributes, split( /\s+/, $exportedAttr ) );

                # Convert @attributes into hash to remove duplicates
                my %attributes = map( { $_ => 1 } @attributes );
                return '[' . join( ',', keys %attributes ) . ']';
            }

            # Convert @attributes into hash to remove duplicates
            my %attributes = map( { $_ => 1 } @attributes );
            %attributes = (
                %attributes,
                %{ $conf->{exportedVars} },
                %{ $conf->{macros} },
            );
            return '[' . join( ',', keys %attributes ) . ']';
        }
    }
);
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{formTimeout} );
        return $ott;
    }
);

# INITIALIZATION

sub init {
    my ($self)  = @_;
    my @parents = ('Lemonldap::NG::Portal::Main::Plugin');
    my $add     = 0;
    if ( $self->conf->{restConfigServer} ) {
        push @parents, 'Lemonldap::NG::Common::Conf::RESTServer';
        $add++;

        # Methods inherited from Lemonldap::NG::Common::Conf::RESTServer
        $self->addUnauthRoute(
            config => {
                ':cfgNum' => [
                    qw(virtualHosts samlIDPMetaDataNodes samlSPMetaDataNodes
                      applicationList oidcOPMetaDataNodes oidcRPMetaDataNodes
                      authChoiceModules grantSessionRules)
                ]
            },
            ['GET'],
          )

          ->addUnauthRoute(
            config => { ':cfgNum' => { '*' => 'getKey' } },
            ['GET']
          )

          ->addUnauthRoute( error => { '*' => 'getError' }, ['GET'] );
    }
    if ( $self->conf->{restSessionServer} ) {
        push @parents, 'Lemonldap::NG::Common::Session::REST';
        $add++;

        # Methods inherited from Lemonldap::NG::Common::Session::REST
        $self->addUnauthRoute(
            sessions => {
                ':sessionType' => (
                    $self->conf->{restExportSecretKeys}
                    ? 'rawSession'
                    : 'session'
                )
            },
            ['GET']
          )

          ->addUnauthRoute(
            sessions => { ':sessionType' => 'newSession' },
            ['POST']
          )

          # Methods written below
          ->addUnauthRoute(
            sessions => { ':sessionType' => 'updateSession' },
            ['PUT']
          )

          ->addUnauthRoute(
            sessions => { ':sessionType' => 'delSession' },
            ['DELETE']
          )

          ->addAuthRoute(
            session => { my => { ':sessionType' => 'getMyKey' } },
            [ 'GET', 'POST' ]
          )

          ->addAuthRoute(
            session => { my => 'removeSession' },
            ['DELETE']
          );

        if ( $self->conf->{globalLogoutRule} ) {
            $self->addAuthRoute(
                sessions => { my => 'removeSessions' },
                ['DELETE']
            );
        }
    }

    if ( $self->conf->{restPasswordServer} ) {
        $self->addUnauthRoute(
            proxy => {
                'pwdReset' => 'pwdReset',
            },
            ['POST']
        );
    }

    if ( $self->conf->{restAuthServer} or $self->conf->{restPasswordServer} ) {
        $self->addUnauthRoute(
            proxy => {
                'pwdConfirm' => 'pwdConfirm',
            },
            ['POST']
        );
    }

    if ( $self->conf->{restAuthServer} ) {
        $self->addUnauthRoute(
            proxy => {
                'getUser' => 'getUser',
            },
            ['POST']
        );
    }

    # Methods always available
    $self->addAuthRoute(
        mysession => { '*' => 'mysession' },
        [ 'GET', 'POST' ]
      )

      ->addAuthRoute(
        mysession => {
            ':sessionType' =>
              { ':key' => 'delKeyInMySession', '*' => 'delMySession' }
        },
        ['DELETE']
      )

      ->addAuthRoute(
        mysession => { ':sessionType' => 'updateMySession' },
        ['PUT']
      )

      ->addAuthRoute( myapplications => 'myApplications', ['GET'] );

    extends @parents               if ($add);
    $self->setTypes( $self->conf ) if ( $self->conf->{restSessionServer} );

    return 1;
}

sub newSession {
    my ( $self, $req, $id ) = @_;

    # If id is defined
    return $self->newAuthSession( $req, $id )
      if ( $id and exists $req->parameters->{auth} );
    my $mod = $self->getMod($req)
      or return $self->p->sendError( $req, undef, 400 );
    my $infos = $req->jsonBodyToObj
      or return $self->p->sendError( $req, undef, 400 );
    $infos->{_utime} = time();

    my $secret = delete $infos->{__secret};
    my $force  = $self->_checkSecret($secret);

    if ( $req->param('all') and not $id ) {
        return $self->p->sendError( $req,
            'Bad key, refuse to send all sessions', 400 )
          unless ($force);
        my $data = $infos->{data};
        my $opts = $self->conf->{globalStorageOptions} || {};
        $opts->{backend} = $self->conf->{globalStorage};
        my $sessions;
        if ( my $query = $req->param('search') ) {
            my ( $field, @values ) = split /,/, $query;
            $sessions = Lemonldap::NG::Common::Apache::Session->searchOn(
                $opts, $field,
                join( ',', @values ),
                ( $data ? @$data : () )
            );
        }
        else {
            $sessions =
              Lemonldap::NG::Common::Apache::Session
              ->get_key_from_all_sessions( $opts, $data );
        }
        return $self->p->sendJSONresponse( $req, $sessions );
    }
    my $session = $self->getApacheSession( $mod, $id, $infos, $force );
    return $self->p->sendError( $req, 'Unable to create session', 500 )
      unless ($session);

    $self->logger->debug(
        "SOAP request create a new session (" . $session->id . ")" );

    return $self->p->sendJSONresponse( $req,
        { result => 1, session => $session->data } );
}

sub newAuthSession {
    my ( $self, $req, $id ) = @_;

    # Check secret
    my $secret = $req->param('secret');
    unless ( $self->_checkSecret($secret) ) {
        return $self->p->sendError( $req, 'Bad secret', 403 );
    }

    $req->{id}    = $id;
    $req->{force} = 1;
    $req->user( $req->param('user') );
    $req->data->{password} = $req->param('password');
    $req->steps( [
            @{ $self->p->beforeAuth },
            qw(getUser extractFormInfo authenticate setAuthSessionInfo),
            @{ $self->p->betweenAuthAndData },
            $self->p->sessionData,
            @{ $self->p->afterData },
            $self->p->validSession,
            @{ $self->p->endAuth },
        ]
    );
    $req->{error} = $self->p->process($req);
    $self->logger->debug(
        "REST authentication result for $req->{user}: code $req->{error}");

    return $self->p->sendError( $req, 'Bad credentials', 401 )
      if ( $req->error > 0 );
    return $self->session( $req, $id );
}

sub updateSession {
    my ( $self, $req, $id ) = @_;
    $self->logger->debug("REST request to update session $id");
    my $mod = $self->getMod($req)
      or return $self->p->sendError( $req, undef, 400 );
    return $self->p->sendError( $req, 'ID is required', 400 ) unless ($id);

    # Get new info
    my $infos = $req->jsonBodyToObj
      or return $self->p->sendError( $req, undef, 400 );

    # Get secret if given
    my $secret = delete $infos->{__secret};
    my $force  = $self->_checkSecret($secret);

    # Get session and store info
    my $session = $self->getApacheSession( $mod, $id, $infos, $force )
      or return $self->p->sendError( $req, 'Session Id does not exist', 400 );

    return $self->p->sendJSONresponse( $req, { result => 1 } );
}

sub delSession {
    my ( $self, $req, $id ) = @_;
    my $mod = $self->getMod($req)
      or return $self->p->sendError( $req, undef, 400 );
    return $self->p->sendError( $req, 'ID is required', 400 ) unless ($id);

    # Get session
    my $session = $self->getApacheSession( $mod, $id )
      or return $self->p->sendError( $req, 'Session Id does not exist', 400 );

    # Delete it
    $self->logger->debug("REST request to delete session $id");
    my $res = $self->p->_deleteSession( $req, $session );
    $self->logger->debug(" Result is $res");

    return $self->p->sendJSONresponse( $req, { result => $res } );
}

sub delMySession {
    my ( $self, $req, $id ) = @_;

    return $self->delSession( $req, $req->userData->{_session_id} );
}

sub mysession {
    my ( $self, $req ) = @_;

    # 1. whoami
    return $self->p->sendJSONresponse( $req,
        { result => $req->userData->{ $self->conf->{whatToTrace} } } )
      if defined $req->param('whoami');

    if ( defined $req->param('gettoken') ) {
        return $self->p->sendJSONresponse( $req,
            { token => $self->ott->createToken() } );
    }

    # Verify authorizationfor arg
    elsif ( my $url = $req->param('authorizationfor') ) {

        # Verify that value is base64 encoded
        return $self->p->sendError( $req, "Value must be in BASE64", 400 )
          if ( $url =~ m#[^A-Za-z0-9\+/=]# );
        $req->urldc( decode_base64($url) );

        # Check for XSS problems
        return $self->p->sendError( $req, 'XSS attack detected', 400 )
          if ( $self->p->checkXSSAttack( 'authorizationfor', $req->urldc ) );

        # Split URL
        $req->urldc =~ URIRE;
        my ( $host, $uri ) = ( $3 . ( $4 ? ":$4" : '' ), $5 );
        $uri ||= '/';
        return $self->p->sendError( $req, "Bad URL $req->{urldc}", 400 )
          unless ($host);

        $self->logger->debug("Looking for authorization for $url");

        # Now check for authorization
        my $res =
          $self->p->HANDLER->grant( $req, $req->userData, $uri, undef, $host );
        $self->logger->debug(" Result is $res");
        return $self->p->sendJSONresponse( $req, { result => $res } );
    }

    return $self->p->sendError( $req,
        'whoami or authorizationfor is required', 400 );
}

sub getMyKey {
    my ( $self, $req, $key ) = @_;
    $key ||= '';
    if ($key) {
        $self->logger->debug(
            "Request to get personal session info -> Key: $key");
    }
    else {
        my $keys = $self->exportedAttr;
        $keys =~ s/(?:\[|\])//g;
        $keys =~ s/,/, /g;
        $self->logger->debug(
            "Request to get exported attributes -> Keys: $keys");
    }

    return $self->session(
        $req,
        $req->userData->{_session_id},
        $key || $self->exportedAttr
    );
}

sub updateMySession {
    my ( $self, $req ) = @_;
    my $res   = 0;
    my $mKeys = [];

    if ( my $token = $req->param('token') ) {
        if ( $self->ott->getToken($token) ) {
            if ( $req->param('sessionType') eq 'persistent' ) {
                foreach
                  my $key ( @{ $self->conf->{mySessionAuthorizedRWKeys} } )
                {
                    my $v;
                    if ( $key =~ /\*/ ) {
                        $key =~ s/\*/\.\*/g;
                        if ( my ($k) = grep( /$key/, $req->params ) ) {
                            $v = $req->param($k);
                        }
                    }
                    else {
                        $v = $req->param($key);
                    }
                    if ( defined $v ) {
                        $res++;
                        push @$mKeys, $key;
                        $self->p->updatePersistentSession( $req,
                            { $key => $v } );
                        $self->logger->debug(
                            "Request to update session -> Key : $key");
                    }
                }
            }
        }
        else {
            $self->logger->error('Update session request with invalid token');
        }
    }
    else {
        $self->logger->error('Update session request without token');
    }

    return $self->p->sendError( $req, 'Modification refused', 403 ) unless $res;
    return $self->p->sendJSONresponse( $req,
        { result => 1, count => $res, modifiedKeys => $mKeys } );
}

sub delKeyInMySession {
    my ( $self, $req ) = @_;
    my $res   = 0;
    my $mKeys = [];
    my $dkey  = $req->param('key');
    my $sub   = $req->param('sub');

    if ( my $token = $req->param('token') ) {
        if ( $self->ott->getToken($token) ) {
            if ( $req->param('sessionType') eq 'persistent' ) {
                foreach
                  my $key ( @{ $self->conf->{mySessionAuthorizedRWKeys} } )
                {
                    if ( $key =~ /\*/ ) {
                        $key =~ s/\*/\.\*/g;
                        if ( $dkey =~ /^$key$/ ) {
                            $res++;
                        }
                    }
                    elsif ( $dkey eq $key ) {
                        $res++;
                    }
                }
                if ($res) {
                    if ( $dkey !~ /^_oidcConsents$/ ) {
                        $self->p->updatePersistentSession( $req,
                            { $dkey => undef } );
                        $self->logger->debug(
                            "Update session -> delete Key : $dkey");
                    }
                    elsif ( $dkey =~ /^_oidcConsents$/ and defined $sub ) {

                        # Read existing oidcConsents
                        $self->logger->debug("Looking for OIDC Consents ...");
                        my $_oidcConsents;
                        if ( $req->userData->{_oidcConsents} ) {
                            $_oidcConsents = eval {
                                from_json( $req->userData->{_oidcConsents},
                                    { allow_nonref => 1 } );
                            };
                            if ($@) {
                                $self->logger->error(
                                    "Corrupted session (_oidcConsents): $@");
                                return $self->p->sendError( $req,
                                    "Corrupted session", 500 );
                            }
                        }
                        else {
                            $self->logger->debug("No OIDC Consent found");
                            $_oidcConsents = [];
                        }
                        my @keep = ();
                        while (@$_oidcConsents) {
                            my $element = shift @$_oidcConsents;
                            $self->logger->debug(
                                "Looking for OIDC Consent to delete ...");
                            push @keep, $element
                              unless ( $element->{rp} eq $sub );
                        }
                        $self->p->updatePersistentSession( $req,
                            { _oidcConsents => to_json( \@keep ) } );
                        $self->logger->debug(
"Update session -> delete Key : $dkey with Sub : $sub"
                        );
                    }
                    else {
                        $self->logger->error(
                            'Update session request with invalid Key or Sub');
                    }
                }
            }
        }
        else {
            $self->logger->error('Update session request with invalid token');
        }
    }
    else {
        $self->logger->error('Update session request without token');
    }

    return $self->p->sendError( $req, 'Modification refused', 403 ) unless $res;
    return $self->p->sendJSONresponse( $req,
        { result => 1, count => $res, modifiedKeys => $dkey } );
}

sub getError {
    my ( $self, $req, $lang, $errNum ) = @_;
    $lang ||= 'en';
    $errNum
      ? $self->logger->debug("Send $lang error file path with error: $errNum")
      : $self->logger->debug("Send $lang error file path");

    return $self->p->sendJSONresponse(
        $req,
        {
            result        => 1,
            lang          => $lang,
            errorNum      => $errNum ? $errNum : 'all',
            errorsFileURL =>
              "$self->{conf}->{staticPrefix}/languages/$lang.json",
            ( $errNum ? ( errorMsgRef => "PE$errNum" ) : () )
        }
    );
}

sub removeSession {
    my ( $self, $req ) = @_;
    my $id = $req->userData->{_session_id};
    return $self->p->sendError( $req, 'ID is required', 400 ) unless ($id);
    my $mod = $self->getGlobal()
      or return $self->p->sendError( $req, undef, 400 );

    # Get session
    my $session = $self->getApacheSession( $mod, $id )
      or return $self->p->sendError( $req, 'Session Id does not exist', 400 );

    # Delete it
    $self->logger->debug("REST request to delete global session $id");
    my $res = $self->p->_deleteSession( $req, $session );
    $self->logger->debug(" Result is $res");

    return $self->p->sendJSONresponse( $req, { result => $res } );
}

sub removeSessions {
    my ( $self, $req ) = @_;
    my $glPlugin =
      $self->p->loadedModules->{'Lemonldap::NG::Portal::Plugins::GlobalLogout'};
    my $sessions = $glPlugin->activeSessions($req);
    my $nbr      = $glPlugin->removeOtherActiveSessions( $req, $sessions );

    return $self->p->sendJSONresponse( $req, { result => $nbr } );
}

sub pwdReset {
    my ( $self, $req ) = @_;

    $self->logger->debug("Entering REST pwdReset method");

    unless ( $self->p->_passwordDB ) {
        $self->logger->error(
                "No Password module configured on this server, "
              . "cannot execute password change" );
        return $self->p->sendJSONresponse( $req, { 'result' => JSON::false } );
    }

    my $jsonBody = eval { from_json( $req->content ) };
    if ($@) {
        $self->logger->error("Received invalid JSON $@");
        return $self->p->sendError( $req, "Invalid JSON", 400 );
    }

    my $user     = $jsonBody->{user};
    my $mail     = $jsonBody->{mail};
    my $password = $jsonBody->{password};

    unless ( $user or $mail ) {
        $self->logger->error("Missing user or mail argument");
        return $self->p->sendError( $req, "Missing user or mail argument",
            400 );
    }

    unless ($password) {
        $self->logger->error("Missing password argument");
        return $self->p->sendError( $req, "Missing password argument", 400 );
    }

    $req->user( $user || $mail );
    $req->steps( ['getUser'] );
    my $result = $self->p->process( $req, ( $mail ? ( useMail => 1 ) : () ) );
    if ($result) {
        $self->logger->error( "Error while looking up user: $result ("
              . portalConsts->{$result}
              . ")" );
        return $self->p->sendError( $req, "User not found", 400 );
    }
    $result =
      $self->p->_passwordDB->setNewPassword( $req, $password, $mail ? 1 : 0 );
    $req->{user} = undef;

    if ( $result == PE_PASSWORD_OK or $result == PE_OK ) {
        return $self->p->sendJSONresponse( $req, { 'result' => JSON::true } );
    }
    else {
        $self->logger->error( "Error while changing user password: $result ("
              . portalConsts->{$result}
              . ")" );
        return $self->p->sendJSONresponse( $req, { 'result' => JSON::false } );
    }

}

sub pwdConfirm {
    my ( $self, $req ) = @_;

    $self->logger->debug("Entering REST pwdConfirm method");

    my $jsonBody = eval { from_json( $req->content ) };
    if ($@) {
        $self->logger->error("Received invalid JSON $@");
        return $self->p->sendError( $req, "Invalid JSON", 400 );
    }

    my $user     = $jsonBody->{user};
    my $password = $jsonBody->{password};

    unless ( $user and $password ) {
        $self->logger->error("Missing required arguments");
        return $self->p->sendError( $req, "Missing arguments user or password",
            400 );
    }

    $req->parameters->{user}     = $user;
    $req->parameters->{password} = $password;
    $req->data->{_pwdCheck}      = 1;
    $req->data->{skipToken}      = 1;

    if ( $self->p->_userDB ) {
        $req->steps( [ $self->p->authProcess ] );
        my $result = $self->p->process($req);
        if ( $result == PE_PASSWORD_OK or $result == PE_OK ) {
            return $self->p->sendJSONresponse( $req,
                { 'result' => JSON::true } );
        }
        else {
            $self->logger->error(
                "Process returned $result (" . portalConsts->{$result} . ")" );
            return $self->p->sendJSONresponse( $req,
                { 'result' => JSON::false } );
        }
    }
}

sub getUser {
    my ( $self, $req ) = @_;

    $self->logger->debug("Entering REST getUser method");

    my $jsonBody = eval { from_json( $req->content ) };
    if ($@) {
        $self->logger->error("Received invalid JSON $@");
        return $self->p->sendError( $req, "Invalid JSON", 400 );
    }

    my $user = $jsonBody->{user};
    my $mail = $jsonBody->{mail};

    unless ( $user or $mail ) {
        $self->logger->error("Missing user or mail argument");
        return $self->p->sendError( $req, "Missing user or mail argument",
            400 );
    }

    $req->user( $user || $mail );
    $req->data->{_pwdCheck} = 1;

    # Search user in database
    $req->steps( [
            'getUser',                 'setSessionInfo',
            $self->p->groupsAndMacros, 'setLocalGroups'
        ]
    );
    my $error = $self->p->process( $req, ( $mail ? ( useMail => 1 ) : () ) );
    if ( $error == PE_OK ) {
        return $self->p->sendJSONresponse(
            $req,
            {
                'result' => JSON::true,
                'info'   => $req->sessionInfo,
            }
        );
    }
    else {
        return $self->p->sendJSONresponse( $req, { 'result' => JSON::false } );
    }
}

sub myApplications {
    my ( $self, $req ) = @_;
    my @appslist = map {
        my @apps = map {
            {
                $_->{appname} => {
                    AppUri  => $_->{appuri},
                    AppDesc => $_->{appdesc}
                }
            }
        } @{ $_->{applications} };
        { Category => $_->{catname}, Applications => \@apps },
    } @{ $self->p->menu->appslist($req) };

    return $self->p->sendJSONresponse( $req,
        { result => 1, myapplications => \@appslist } );
}

sub _checkSecret {
    my ( $self, $secret ) = @_;
    my $isValid = 0;

    if ($secret) {
        my $t;
        if ( $t = $self->conf->{cipher}->decrypt($secret) ) {
            if (    $t <= time + $self->conf->{restClockTolerance}
                and $t > time - $self->conf->{restClockTolerance} )
            {
                $isValid = 1;
            }
            else {
                $self->logger->error( 'Clock drift between servers is'
                      . ' beyond tolerance, force denied.' );
            }
        }
        else {
            $self->logger->error('Bad key, force denied');
        }
    }

    return $isValid;
}

1;
