# Session server plugin for SOAP call
#
# This plugin adds the following entry points:
#  * POST /sessions     , methods: getCookies getAttributes isAuthorizedURI
#  * POST /adminSessions, methods: getAttributes setAttributes isAuthorizedURI
#                                  newSession deleteSession getCipheredToken
#                                  get_key_from_all_sessions
#  * POST /config       , methods: getConfig lastCfg
#
# There is no conflict with REST server, they can be used together

package Lemonldap::NG::Portal::Plugins::SOAPServer;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_FORMEMPTY
  URIRE
);

our $VERSION = '2.0.12';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Common::Conf::AccessLib
);

has server => ( is => 'rw' );
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

            return [ sort keys %attributes ];
        }
    }
);

########
# WSDL #
########

has wsdl => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my @cookies = ( $self->conf->{cookieName} );
        push @cookies, $self->conf->{cookieName} . 'http'
          if ( $self->conf->{securedCookie} >= 2 );
        my $cookieList = join "\n",
          map { "<element name='$_' type='xsd:string'></element>" } @cookies;

        my $attrList = join "\n", map {
            "<element name='$_' type='xsd:string' nillable='true'></element>"
        } @{ $self->exportedAttr };
        my $resp = join( '', <DATA> );
        close DATA;
        $resp =~ s/\$cookieList/$cookieList/g;
        $resp =~ s/\$attrList/$attrList/g;
        $resp =~ s/\$portal/$self->conf->{portal}/ge;
        return [
            200,
            [
                'Content-Type'   => 'application/wsdl+xml',
                'Content-Length' => length($resp)
            ],
            [$resp]
        ];
    }
);

# INITIALIZATION

sub init {
    my ($self) = @_;
    eval {
        require Lemonldap::NG::Common::PSGI::SOAPServer;
        require Lemonldap::NG::Common::PSGI::SOAPService;
    };
    if ($@) {
        $self->error($@);
        return 0;
    }
    $self->server( Lemonldap::NG::Common::PSGI::SOAPServer->new );
    if ( $self->conf->{soapSessionServer} ) {
        $self->addUnauthRoute(
            sessions => { '*' => 'unauthSessions' },
            ['POST']
          )

          ->addUnauthRoute(
            adminSessions => 'unauthAdminSessions',
            ['POST']
          )

          ->addAuthRoute(
            sessions => { '*' => 'badSoapRequest' },
            ['POST']
          )

          ->addAuthRoute(
            adminSessions => { '*' => 'badSoapRequest' },
            ['POST']
          );
    }
    if ( $self->conf->{soapConfigServer} ) {
        $self->addUnauthRoute( config => { '*' => 'config' }, ['POST'] )
          ->addAuthRoute( config => { '*' => 'badSoapRequest' }, ['POST'] );
    }
    if ( $self->conf->{wsdlServer} ) {
        $self->addUnauthRoute( 'portal.wsdl' => 'getWsdl', ['GET'] )
          ->addAuthRoute( 'portal.wsdl' => 'getWsdl', ['GET'] );
    }

    return 1;
}

# SOAP DISPATCHERS
sub unauthSessions {
    my ( $self, $req ) = @_;
    return $self->dispatch_to( $req,
        qw(error getCookies getAttributes isAuthorizedURI getMenuApplications)
    );
}

sub unauthAdminSessions {
    my ( $self, $req ) = @_;
    return $self->dispatch_to(
        $req,
        qw(getCookies getAttributes isAuthorizedURI getMenuApplications
          newSession setAttributes deleteSession getCipheredToken
          get_key_from_all_sessions)
    );
}

sub config {
    my ( $self, $req ) = @_;
    return $self->dispatch_to( $req, qw(getConfig lastCfg) );
}

sub badSoapRequest {
    my ( $self, $req ) = @_;
    return $self->p->sendError( $req, 'Bad request', 400 );
}

# Private dispatcher
sub dispatch_to {
    my ( $self, $req, @functions ) = @_;
    unless ( $req->env->{HTTP_SOAPACTION} ) {
        return $self->p->sendError( $req, 'SOAP requests only', 400 );
    }
    return $self->server->dispatch_to(
        Lemonldap::NG::Common::PSGI::SOAPService->new(
            $self, $req, @functions
        )
    )->handle($req);
}

# RESPONSE METHODS

# Called in SOAP context, returns cookies in an array.
# This subroutine works only for portals working with user and password

sub getWsdl {
    return $_[0]->wsdl;
}

sub error {
    my ( $self, $no, $lang ) = @_;
    return "Error $no";
}

=begin WSDL

_IN user $string User name
_IN password $string Password
_RETURN $getCookiesResponse Response

=end WSDL

=cut

sub getCookies {
    my ( $self, $req, $user, $password, $sessionid ) = @_;
    $self->logger->debug("SOAP authentication request for $user");

    $req->{user} = $user;
    $req->data->{password} = $password;
    if ($sessionid) {
        $req->{id}    = $sessionid;
        $req->{force} = 1;
    }

    $req->{error} = PE_OK;

    # User and password are required
    unless ( $req->{user} && $req->data->{password} ) {
        $req->{error} = PE_FORMEMPTY;
    }

    # Launch process
    else {
        $req->steps( [
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
            "SOAP authentication result for $user: code $req->{error}");
        $self->p->updateSession($req);
    }
    my @tmp = ();
    push @tmp, SOAP::Data->name( errorCode => $req->{error} );
    my @cookies = ();
    unless ( $req->{error} ) {
        for ( my $i = 0 ; $i < @{ $req->respHeaders } ; $i += 2 ) {
            if ( $req->respHeaders->[$i] eq 'Set-Cookie' ) {
                my ( $k, $v ) =
                  ( $req->respHeaders->[ $i + 1 ] =~ /^(\w+)\s*=\s*([^;]*)/ );
                push @cookies, SOAP::Data->name( $k, $v )->type("string");
            }
        }
    }
    push @tmp, SOAP::Data->name( cookies => \SOAP::Data->value(@cookies) );
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );

    #TODO: updateStatus
    #$self->p->updateStatus($req);
    return $res;
}

# Return attributes of the session identified by $id.
# @param $id Cookie value

=begin WSDL

_IN id $string Cookie value
_RETURN $getAttributesResponse Response

=end WSDL

=cut

sub getAttributes {
    my ( $self, $req, $id ) = @_;
    die 'id is required' unless ($id);

    my $session = $self->p->getApacheSession( $id, kind => '' );

    my @tmp = ();
    unless ($session) {
        $self->userLogger->notice(
            "SOAP attributes request: session $id not found");
        push @tmp, SOAP::Data->name( error => 1 )->type('int');
    }
    else {
        my $wtt = $session->data->{ $self->conf->{whatToTrace} };
        $self->userLogger->info(
            "SOAP attributes request for " . ( $wtt ? $wtt : $id ) );
        push @tmp, SOAP::Data->name( error => 0 )->type('int');
        push @tmp,
          SOAP::Data->name(
            attributes => _buildSoapHash(
                $session->data,
                ( (
                              $session->{_session_kind}
                          and $session->{_session_kind} eq 'SSO'
                    )
                    ? ( @{ $self->exportedAttr } )
                    : ()
                )
            )
          );
    }
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );
    return $res;
}

# Update data in the session referenced by $id
# @param $id Id of the session
# @param $args data to store

=begin WSDL

_IN id $string Cookie value
_RETURN $setAttributesResponse Response

=end WSDL

=cut

sub setAttributes {
    my ( $self, $req, $id, $args ) = @_;
    die 'id is required' unless ($id);

    my $infos = {};
    %$infos = %$args;

    my $session = $self->p->getApacheSession( $id, info => $infos );

    unless ($session) {
        $self->logger->warn("Session $id does not exists ($@)");
        return 0;
    }

    $self->logger->debug("SOAP request to update session $id");

    return 1;
}

# Return Lemonldap::NG configuration. Warning, this is not a well formed
# SOAP::Data object so it can be difficult to read by other languages than
# Perl. It's not really a problem since this function is written to be read by
# Lemonldap::NG components and is not designed to be shared.

sub getConfig {
    my ( $self, $req, $id ) = @_;
    my $conf = $self->confAcc->getConf( { raw => 1, cfgNum => $id } )
      or die("No configuration available");
    return $conf;
}

# SOAP method that return the last configuration number.
# Call Lemonldap::NG::Common::Conf::lastCfg().

sub lastCfg {
    my $self = shift;
    return $self->confAcc->lastCfg;
}

# Store a new session.

sub newSession {
    my ( $self, $req, $args ) = @_;

    $args ||= {};
    my $infos = {};
    %$infos = %$args;
    $infos->{_utime} = time();

    my $session = $self->p->getApacheSession( undef, info => $infos );

    unless ($session) {
        $self->logger->error("Unable to create session");
        return 0;
    }

    $self->logger->debug(
        "SOAP request create a new session (" . $session->id . ")" );

    return SOAP::Data->name( attributes => _buildSoapHash( $session->data ) );
}

# Deletes an existing session

sub deleteSession {
    my ( $self, $req, $id ) = @_;
    die('id parameter is required') unless ($id);

    my $session = $self->p->getApacheSession( $id, kind => '' );

    return 0 unless ($session);

    $self->logger->debug("SOAP request to delete session $id");

    return $self->p->_deleteSession( $req, $session );
}

# Returns key from all sessions

sub getCipheredToken {
    my ( $self, $req ) = @_;
    require Lemonldap::NG::Portal::Lib::OneTimeToken;
    return $self->conf->{cipher}->encrypt(
        Lemonldap::NG::Portal::Lib::OneTimeToken->new(
            { p => $self->p, conf => $self->conf, timeout => 5 }
        )->createToken()
    );
}

sub get_key_from_all_sessions {
    my $self  = shift;
    my $req   = shift;
    my $token = shift;

    # Verify that token is valid (must be unciphered by client)
    require Lemonldap::NG::Portal::Lib::OneTimeToken;
    unless (
        Lemonldap::NG::Portal::Lib::OneTimeToken->new(
            { p => $self->p, conf => $self->conf }
        )->getToken($token)
      )
    {
        die SOAP::Fault->faultcode('Server.Custom')->faultstring('Bad token');
    }
    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};
    require Lemonldap::NG::Common::Apache::Session;

    no strict 'refs';
    return Lemonldap::NG::Common::Apache::Session->get_key_from_all_sessions(
        $moduleOptions, @_ );
}

# Check user's authorization for uri.
# @param $id Id of the session
# @param $uri URL string

=begin WSDL

_IN id $string Cookie value
_IN uri $string URI to test
_RETURN $isAuthorizedURIResponse Response

=end WSDL

=cut

sub isAuthorizedURI {
    my ( $self, $req, $id, $url ) = @_;
    die 'id is required'  unless ($id);
    die 'uri is required' unless ($url);
    die 'Bad uri'         unless ( $url =~ URIRE );
    my ( $host, $uri ) = ( $1, $2 );

    # Get user session.
    my $session = $self->p->getApacheSession($id);

    unless ($session) {
        $self->logger->warn("Session $id does not exists");
        return 0;
    }

    $req->{sessionInfo} = $session->data;
    my $r =
      $self->p->HANDLER->grant( $req, $req->{sessionInfo}, $uri, undef, $host );

    return $r;
}

# @param $id Id of the session

#######################
# Private subroutines #
#######################

##@fn private SOAP::Data _buildSoapHash()
# Serialize a hashref into SOAP::Data. Types are fixed to "string".
# @return SOAP::Data serialized data
sub _buildSoapHash {
    my ( $h, @keys ) = @_;
    my @tmp = ();
    @keys = keys %$h unless (@keys);
    foreach (@keys) {
        if ( ref( $h->{$_} ) eq 'ARRAY' ) {
            push @tmp, SOAP::Data->name( $_, @{ $h->{$_} } );
        }
        elsif ( ref( $h->{$_} ) ) {
            push @tmp, SOAP::Data->name( $_ => _buildSoapHash( $h->{$_} ) );
        }
        else {
            push @tmp, SOAP::Data->name( $_, $h->{$_} )->type('string')
              if ( defined( $h->{$_} ) );
        }
    }
    return \SOAP::Data->value(@tmp);
}

1;

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<wsdl:definitions
    targetNamespace="urn:Lemonldap/NG/Common/PSGI/SOAPService"
    xmlns:impl="urn:Lemonldap/NG/Common/PSGI/SOAPService"
    xmlns:wsdlsoap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:tns1="urn:Lemonldap/NG/Common/PSGI/SOAPService">

  <!-- types definitions -->

  <wsdl:types>
    <schema targetNamespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" xmlns="http://www.w3.org/2001/XMLSchema">
      <import namespace="http://schemas.xmlsoap.org/soap/encoding/" />

      <complexType name="CookiesSequence">
        <sequence>
$cookieList
        </sequence>
      </complexType>
      <complexType name="AttributesSequence">
        <sequence>
$attrList
        </sequence>
      </complexType>
      <complexType name="GetCookieResponse">
        <sequence>
          <element name="errorCode" type="xsd:int"></element>
          <element name="cookies" minOccurs="0" type="tns1:CookiesSequence"></element>
        </sequence>
      </complexType>
      <complexType name="GetAttributesResponse">
        <sequence>
          <element name="error" type="xsd:int"></element>
          <element name="attributes" type="tns1:AttributesSequence"></element>
        </sequence>
      </complexType>

    </schema>
  </wsdl:types>

  <!-- sessions service -->

  <wsdl:message name="errorRequest">
    <wsdl:part name="code" type="xsd:int" />
    <wsdl:part name="lang" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="errorResponse">
    <wsdl:part name="result" type="xsd:string" />
  </wsdl:message>

  <wsdl:message name="getCookiesRequest">
    <wsdl:part name="user" type="xsd:string" />
    <wsdl:part name="password" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="getCookiesResponse">
    <wsdl:part name="session" type="tns1:GetCookieResponse" />
  </wsdl:message>

  <wsdl:message name="getAttributesRequest">
    <wsdl:part name="id" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="getAttributesResponse">
    <wsdl:part name="session" type="tns1:GetAttributesResponse" />
  </wsdl:message>

  <wsdl:message name="isAuthorizedURIRequest">
    <wsdl:part name="id" type="xsd:string" />
    <wsdl:part name="uri" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="isAuthorizedURIResponse">
    <wsdl:part name="result" type="xsd:int" />
  </wsdl:message>

  <wsdl:message name="getMenuApplicationsRequest">
    <wsdl:part name="id" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="getMenuApplicationsResponse">
    <wsdl:part name="result" type="xsd:anyType" />
  </wsdl:message>

  <wsdl:portType name="sessionsPortType">
    <wsdl:operation name="error" parameterOrder="code lang">
      <wsdl:input message="impl:errorRequest" name="errorRequest" />
      <wsdl:output message="impl:errorResponse" name="errorResponse" />
    </wsdl:operation>
    <wsdl:operation name="getCookies" parameterOrder="user password">
      <wsdl:input message="impl:getCookiesRequest" name="getCookiesRequest" />
      <wsdl:output message="impl:getCookiesResponse" name="getCookiesResponse" />
    </wsdl:operation>
    <wsdl:operation name="getAttributes" parameterOrder="id">
      <wsdl:input message="impl:getAttributesRequest" name="getAttributesRequest" />
      <wsdl:output message="impl:getAttributesResponse" name="getAttributesResponse" />
    </wsdl:operation>
    <wsdl:operation name="isAuthorizedURI" parameterOrder="id uri">
      <wsdl:input message="impl:isAuthorizedURIRequest" name="isAuthorizedURIRequest" />
      <wsdl:output message="impl:isAuthorizedURIResponse" name="isAuthorizedURIResponse" />
    </wsdl:operation>
    <wsdl:operation name="getMenuApplications" parameterOrder="id">
      <wsdl:input message="impl:getMenuApplicationsRequest" name="getMenuApplicationsRequest" />
      <wsdl:output message="impl:getMenuApplicationsResponse" name="getMenuApplicationsResponse" />
    </wsdl:operation>
  </wsdl:portType>

  <wsdl:binding name="sessionsBinding" type="impl:sessionsPortType">
    <wsdlsoap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="error">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="errorRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="errorResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="getCookies">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="getCookiesRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="getCookiesResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="getAttributes">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="getAttributesRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="getAttributesResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="isAuthorizedURI">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="isAuthorizedURIRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="isAuthorizedURIResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="getMenuApplications">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="getMenuApplicationsRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="getMenuApplicationsResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>

  </wsdl:binding>

  <wsdl:service name="sessionsService">
    <wsdl:port binding="impl:sessionsBinding" name="sessionsPort">
      <wsdlsoap:address location="$portal/sessions" />
    </wsdl:port>
  </wsdl:service>

  <!-- end sessions service -->

  <!-- notification service -->

  <wsdl:message name="newNotificationRequest">
    <wsdl:part name="notification" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="newNotificationResponse">
    <wsdl:part name="result" type="xsd:int" />
  </wsdl:message>
  <wsdl:message name="deleteNotificationRequest">
    <wsdl:part name="uid" type="xsd:string" />
    <wsdl:part name="myref" type="xsd:string" />
  </wsdl:message>
  <wsdl:message name="deleteNotificationResponse">
    <wsdl:part name="result" type="xsd:int" />
  </wsdl:message>

  <wsdl:portType name="notificationPortType">
    <wsdl:operation name="newNotification" parameterOrder="notification">
      <wsdl:input message="impl:newNotificationRequest" name="newNotificationRequest" />
      <wsdl:output message="impl:newNotificationResponse" name="newNotificationResponse" />
    </wsdl:operation>
    <wsdl:operation name="deleteNotification" parameterOrder="uid myref">
      <wsdl:input message="impl:deleteNotificationRequest" name="deleteNotificationRequest" />
      <wsdl:output message="impl:deleteNotificationResponse" name="deleteNotificationResponse" />
    </wsdl:operation>
  </wsdl:portType>

  <wsdl:binding name="notificationBinding" type="impl:notificationPortType">
    <wsdlsoap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="newNotification">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="newNotificationRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="newNotificationResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="deleteNotification">
      <wsdlsoap:operation soapAction="" />
      <wsdl:input name="deleteNotificationRequest">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:input>
      <wsdl:output name="deleteNotificationResponse">
        <wsdlsoap:body encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" namespace="urn:Lemonldap/NG/Common/PSGI/SOAPService" use="encoded" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>

  <wsdl:service name="notificationService">
    <wsdl:port binding="impl:notificationBinding" name="notificationPort">
      <wsdlsoap:address location="$portal/notifications" />
    </wsdl:port>
  </wsdl:service>

  <!-- end notification service -->

</wsdl:definitions>
