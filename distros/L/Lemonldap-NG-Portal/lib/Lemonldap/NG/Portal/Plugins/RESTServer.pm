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
#   where <type> is the session type ("global" for SSO session)
#
# - Authorizations for connected users (always):
#   * GET /mysession/?whoami                               : get "my" uid
#   * GET /mysession/?authorizationfor=<base64-encoded-url>: ask if url is
#                                                            authorizated
#   * PUT /mysession/<type>                                : update some
#                                                            persistent data
#                                                            (restricted)
#   * DELETE /mysession/<type>/key                         : delete key in data
#                                                            (restricted)
#
# There is no conflict with SOAP server, they can be used together

package Lemonldap::NG::Portal::Plugins::RESTServer;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use MIME::Base64;

our $VERSION = '2.0.5';

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
            return [ split /\s+/, $conf->{exportedAttr} ];
        }
        else {
            my @attributes = (
                'authenticationLevel', 'groups',
                'ipAddr',              '_startTime',
                '_utime',              '_lastSeen',
                '_session_id',
            );
            if ( my $exportedAttr = $conf->{exportedAttr} ) {
                $exportedAttr =~ s/^\s*\+\s+//;
                @attributes = ( @attributes, split( /\s+/, $exportedAttr ) );
            }

            # convert @attributes into hash to remove duplicates
            my %attributes = map( { $_ => 1 } @attributes );
            %attributes =
              ( %attributes, %{ $conf->{exportedVars} }, %{ $conf->{macros} },
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
        );
        $self->addUnauthRoute(
            config => { ':cfgNum' => { '*' => 'getKey' } },
            ['GET']
        );
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
        );
        $self->addUnauthRoute(
            sessions => { ':sessionType' => 'newSession' },
            ['POST']
        );

        # Methods written below
        $self->addUnauthRoute(
            sessions => { ':sessionType' => 'updateSession' },
            ['PUT']
        );
        $self->addUnauthRoute(
            sessions => { ':sessionType' => 'delSession' },
            ['DELETE']
        );

        $self->addAuthRoute(
            session => { my => { ':sessionType' => 'getMyKey' } },
            [ 'GET', 'POST' ]
        );
    }

    # Methods always available
    $self->addAuthRoute(
        mysession => { '*' => 'mysession' },
        [ 'GET', 'POST' ]
    );
    $self->addAuthRoute(
        mysession => {
            ':sessionType' =>
              { ':key' => 'delKeyInMySession', '*' => 'delMySession' }
        },
        ['DELETE']
    );
    $self->addAuthRoute(
        mysession => { ':sessionType' => 'updateMySession' },
        ['PUT']
    );
    extends @parents if ($add);
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

    my $force = 0;
    if ( my $s = delete $infos->{__secret} ) {
        my $t;
        if ( $t =
                $self->conf->{cipher}->decrypt($s)
            and $t <= time
            and $t > time - 15 )
        {
            $force = 1;
        }
        else {
            $self->userLogger->error('Bad key, force denied');
        }
    }

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
    my $t;
    unless ($t = $req->param('secret')
        and $t = $self->conf->{cipher}->decrypt($t)
        and $t <= time
        and $t > time - 30 )
    {
        return $self->p->sendError( $req, 'Bad secret', 403 );
    }
    $req->{id}    = $id;
    $req->{force} = 1;
    $req->user( $req->param('user') );
    $req->data->{password} = $req->param('password');
    $req->steps( [
            @{ $self->p->beforeAuth },
            qw(getUser authenticate setAuthSessionInfo),
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

    if ( $req->error > 0 ) {
        return $self->p->sendError( $req, 'Bad credentials', 401 );
    }
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
    my $force = 0;
    if ( my $s = delete $infos->{__secret} ) {
        my $t;
        if ( $t =
                $self->conf->{cipher}->decrypt($s)
            and $t <= time
            and $t > time - 30 )
        {
            $force = 1;
        }
        else {
            $self->userLogger->error('Bad key, force denied');
        }
    }

    # Get session and store info
    my $session = $self->getApacheSession( $mod, $id, $infos, $force )
      or return $self->p->sendError( $req, 'Session id does not exists', 400 );

    return $self->p->sendJSONresponse( $req, { result => 1 } );
}

sub delSession {
    my ( $self, $req, $id ) = @_;
    my $mod = $self->getMod($req)
      or return $self->p->sendError( $req, undef, 400 );
    return $self->p->sendError( $req, 'ID is required', 400 ) unless ($id);

    # Get session
    my $session = $self->getApacheSession( $mod, $id )
      or return $self->p->sendError( $req, 'Session id does not exists', 400 );

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
    if ( defined $req->param('whoami') ) {
        return $self->p->sendJSONresponse( $req,
            { result => $req->userData->{ $self->conf->{whatToTrace} } } );
    }

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
        my ( $host, $uri ) = ( $req->urldc =~ m#^https?://([^/]+)(/.*)?$# );
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
    $self->logger->debug("Request to get personal session info -> Key : $key");
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
    unless ($res) {
        return $self->p->sendError( $req, 'Modification refused', 403 );
    }
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
    unless ($res) {
        return $self->p->sendError( $req, 'Modification refused', 403 );
    }
    return $self->p->sendJSONresponse( $req,
        { result => 1, count => $res, modifiedKeys => $dkey } );
}

1;
