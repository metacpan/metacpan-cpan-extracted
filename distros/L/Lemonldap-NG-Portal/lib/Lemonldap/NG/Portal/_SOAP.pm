## @file
# SOAP methods for Lemonldap::NG portal

## @class
# Add SOAP methods to the Lemonldap::NG portal.
package Lemonldap::NG::Portal::_SOAP;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LibAccess;
require SOAP::Lite;
use base qw(Lemonldap::NG::Portal::_LibAccess);

our $VERSION = '1.9.1';

## @method void startSoapServices()
# Check the URI requested (PATH_INFO environment variable) and launch the
# corresponding SOAP methods using soapTest().
# If "soapOnly" is set, reject other request. Else, simply return.
sub startSoapServices {
    my $self = shift;

    # Load SOAP services
    $self->{CustomSOAPServices} ||= {};
    if (
        $ENV{PATH_INFO}
        and my $tmp = {
            %{ $self->{CustomSOAPServices} },
            '/sessions' =>
              'getCookies getAttributes isAuthorizedURI getMenuApplications',
            '/adminSessions' => 'getAttributes setAttributes isAuthorizedURI '
              . 'newSession deleteSession get_key_from_all_sessions',
            '/config' => 'getConfig lastCfg'
        }->{ $ENV{PATH_INFO} }
      )
    {

        # If $tmp is a HASHREF, extract SOAP functions and Object
        # tmp->f: functions list
        # tmp->o: object
        if ( ref($tmp) =~ /HASH/ ) {
            $self->soapTest( $tmp->{f}, $tmp->{o} );
        }
        else {
            $self->soapTest($tmp);
        }
        $self->{soapOnly} = 1;
    }
    else {
        $self->soapTest("getCookies error");
    }
    $self->abort( 'Bad request', 'Only SOAP requests are accepted here' )
      if ( $self->{soapOnly} );
}

####################
# SOAP subroutines #
####################

=begin WSDL

_IN user $string User name
_IN password $string Password
_RETURN $getCookiesResponse Response

=end WSDL

=cut

##@method SOAP::Data getCookies(string user,string password, string sessionid)
# Called in SOAP context, returns cookies in an array.
# This subroutine works only for portals working with user and password
#@param user uid
#@param password password
#@param sessionid optional session identifier
#@return session => { error => code , cookies => { cookieName1 => value ,... } }
sub getCookies {
    my ( $self, $user, $password, $sessionid ) = @_;
    $self->lmLog( "SOAP authentication request for $user", 'debug' );

    $self->{user}     = $user;
    $self->{password} = $password;
    if ( defined($sessionid) && $sessionid ) {
        $self->{id}    = $sessionid;
        $self->{force} = 1;
    }

    $self->{error} = PE_OK;

    # Skip extractFormInfo step, as we already get input data
    $self->{skipExtractFormInfo} = 1;

    # User and password are required
    unless ( $self->{user} && $self->{password} ) {
        $self->{error} = PE_FORMEMPTY;
    }

    # Launch process
    else {
        $self->{error} = $self->_subProcess(
            qw(authInit userDBInit extractFormInfo getUser setAuthSessionInfo
              setSessionInfo setMacros setGroups setPersistentSessionInfo
              setLocalGroups authenticate grantSession removeOther
              store authFinish buildCookie)
        );
        $self->lmLog(
            "SOAP authentication result for $user: code $self->{error}",
            'debug' );
        $self->updateSession();
    }
    my @tmp = ();
    push @tmp, SOAP::Data->name( errorCode => $self->{error} );
    my @cookies = ();
    unless ( $self->{error} ) {
        foreach ( @{ $self->{cookie} } ) {
            push @cookies,
              SOAP::Data->name( $_->name, $_->value )->type("string");
        }
    }
    push @tmp, SOAP::Data->name( cookies => \SOAP::Data->value(@cookies) );
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );
    $self->updateStatus;
    return $res;
}

=begin WSDL

_IN id $string Cookie value
_RETURN $getAttributesResponse Response

=end WSDL

=cut

##@method SOAP::Data getAttributes(string id)
# Return attributes of the session identified by $id.
# @param $id Cookie value
# @return SOAP::Data sequence
sub getAttributes {
    my ( $self, $id ) = @_;
    die 'id is required' unless ($id);

    my $session = $self->getApacheSession( $id, 1 );

    my @tmp = ();
    unless ($session) {
        $self->_sub( 'userNotice',
            "SOAP attributes request: session $id not found" );
        push @tmp, SOAP::Data->name( error => 1 )->type('int');
    }
    else {
        $self->_sub( 'userInfo',
            "SOAP attributes request for "
              . $session->data->{ $self->{whatToTrace} } );
        push @tmp, SOAP::Data->name( error => 0 )->type('int');
        push @tmp,
          SOAP::Data->name(
            attributes => _buildSoapHash( $session->data, $self->exportedAttr )
          );
    }
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );
    return $res;
}

## @method SOAP::Data setAttributes(string id,hashref args)
# Update datas in the session referenced by $id
# @param $id Id of the session
# @param $args datas to store
# @return true if succeed
sub setAttributes {
    my ( $self, $id, $args ) = @_;
    die 'id is required' unless ($id);

    my $session = $self->getApacheSession($id);

    unless ($session) {
        $self->lmLog( "Session $id does not exists ($@)", 'warn' );
        return 0;
    }

    $self->lmLog( "SOAP request to update session $id", 'debug' );

    my $infos = {};
    $infos->{$_} = $args->{$_} foreach ( keys %{$args} );

    $session->update($infos);

    return 1;
}

##@method SOAP::Data getConfig()
# Return Lemonldap::NG configuration. Warning, this is not a well formed
# SOAP::Data object so it can be difficult to read by other languages than
# Perl. It's not really a problem since this function is written to be read by
# Lemonldap::NG components and is not designed to be shared.
# @return hashref serialized in SOAP by SOAP::Lite
sub getConfig {
    my $self = shift;
    my $conf = $self->{lmConf}->getConf() or die("No configuration available");
    return $conf;
}

##@method int lastCfg()
# SOAP method that return the last configuration number.
# Call Lemonldap::NG::Common::Conf::lastCfg().
# @return Last configuration number
sub lastCfg {
    my $self = shift;
    return $self->{lmConf}->lastCfg();
}

## @method SOAP::Data newSession(hashref args)
# Store a new session.
# @return Session datas
sub newSession {
    my ( $self, $args ) = @_;

    my $session = $self->getApacheSession();

    unless ($session) {
        $self->lmLog( "Unable to create session", 'error' );
        return 0;
    }

    my $infos = {};
    $infos->{$_} = $args->{$_} foreach ( keys %{$args} );
    $infos->{_utime} = time();

    $session->update($infos);

    $self->lmLog(
        "SOAP request to store "
          . $session->id . " ("
          . $session->data->{ $self->{whatToTrace} } . ")",
        'debug'
    );

    return SOAP::Data->name( attributes => _buildSoapHash( $session->data ) );
}

## @method SOAP::Data deleteSession()
# Deletes an existing session
sub deleteSession {
    my ( $self, $id ) = @_;
    die('id parameter is required') unless ($id);

    my $session = $self->getApacheSession($id);

    return 0 unless ($session);

    $self->lmLog( "SOAP request to delete session $id", 'debug' );

    return $self->_deleteSession($session);
}

##@method SOAP::Data get_key_from_all_sessions
# Returns key from all sessions
sub get_key_from_all_sessions {
    my $self = shift;
    shift;

    my $moduleOptions = $self->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    require $module;

    no strict 'refs';
    return $module->get_key_from_all_sessions( $moduleOptions, @_ );
}

=begin WSDL

_IN id $string Cookie value
_IN uri $string URI to test
_RETURN $isAuthorizedURIResponse Response

=end WSDL

=cut

## @method boolean isAuthorizedURI (string id, string uri)
# Check user's authorization for uri.
# @param $id Id of the session
# @param $uri URL string
# @return True if granted
sub isAuthorizedURI {
    my $self = shift;
    my ( $id, $uri ) = @_;
    die 'id is required'  unless ($id);
    die 'uri is required' unless ($uri);

    # Get user session.
    my $session = $self->getApacheSession( $id, 1 );

    unless ($session) {
        $self->lmLog( "Session $id does not exists", 'warn' );
        return 0;
    }

    $self->{sessionInfo} = $session->data;
    my $r = $self->_grant($uri);

    return $r;
}

=begin WSDL

_IN id $string Cookie value
_RETURN $getMenuApplicationsResponse Response

=end WSDL

=cut

##@method SOAP::Data getMenuApplications(string id)
# @param $id Id of the session
#@return SOAP::Data
sub getMenuApplications {
    my ( $self, $id ) = @_;
    die 'id is required' unless ($id);

    $self->lmLog( "SOAP getMenuApplications request for id $id", 'debug' );

    # Get user session.
    my $session = $self->getApacheSession( $id, 1 );

    unless ($session) {
        $self->lmLog( "Session $id does not exists", 'warn' );
        return 0;
    }

    $self->{sessionInfo} = $session->data;

    # Build application list
    my $appslist = $self->appslist();

    # Return result
    return _buildSoapHash( { menu => $appslist } );

}

#########################
# Auxiliary subroutines #
#########################

## @method array exportedAttr
# Parse XML string to sustitute macros
# @return list of session data available through getAttribute SOAP request
sub exportedAttr {
    my $self = shift;
    if ( $self->{exportedAttr} and $self->{exportedAttr} !~ /^\s*\+/ ) {
        return split /\s+/, $self->{exportedAttr};
    }
    else {
        my @attributes = (
            'authenticationLevel', 'groups',
            'ipAddr',              'startTime',
            '_utime',              '_lastSeen',
            '_session_id',
        );
        if ( my $exportedAttr = $self->{exportedAttr} ) {
            $exportedAttr =~ s/^\s*\+\s+//;
            @attributes = ( @attributes, split( /\s+/, $exportedAttr ) );
        }

        # convert @attributes into hash to remove duplicates
        my %attributes = map( { $_ => 1 } @attributes );
        %attributes =
          ( %attributes, %{ $self->{exportedVars} }, %{ $self->{macros} }, );

        return sort keys %attributes;
    }
}

#######################
# Private subroutines #
#######################

##@fn private SOAP::Data _buildSoapHash()
# Serialize a hashref into SOAP::Data. Types are fixed to "string".
# @return SOAP::Data serialized datas
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

