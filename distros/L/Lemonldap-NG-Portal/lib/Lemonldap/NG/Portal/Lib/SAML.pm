package Lemonldap::NG::Portal::Lib::SAML;

use strict;
use Mouse;
use Lemonldap::NG::Common::Conf::SAML::Metadata;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::FormEncode;
use XML::Simple;
use MIME::Base64;
use HTTP::Request;         # SOAP call
use POSIX qw(strftime);    # Convert SAML2 date into timestamp
use Time::Local;           # Convert SAML2 date into timestamp
use Encode;                # Encode attribute values
use URI;                   # Get metadata URL path
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_REDIRECT
  PE_SAML_SLO_ERROR
);

our $VERSION = '2.0.5';

# PROPERTIES

has lassoServer => ( is => 'rw' );
has spList      => ( is => 'rw', default => sub { {} } );
has idpList     => ( is => 'rw', default => sub { {} } );
has idpRules    => ( is => 'rw', default => sub { {} } );
has spRules     => ( is => 'rw', default => sub { {} } );

# return LWP::UserAgent object
has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {

        # TODO : LWP options to use a proxy for example
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

# SAML storage
has aModule => ( is => 'rw' );
has amOpts  => ( is => 'rw' );

# INITIALIZATION

BEGIN {

    # Load Glib if available
    eval 'use Glib;';
    if ($@) {
        print STDERR
          "Glib Lasso messages will not be catched (require Glib module)\n";
        eval "use constant GLIB => 0";
    }
    else {
        eval "use constant GLIB => 1";
    }

    # Load Lasso.pm
    eval 'use Lasso;';
    if ($@) {
        print STDERR "Lasso.pm not loaded: $@";
        eval
'use constant LASSO => 0;use constant BADLASSO => 0;use constant LASSOTHINSESSIONS => 0';
    }
    else {
        no strict 'subs';
        eval 'use constant LASSO => 1';

        # Check Lasso version >= 2.3.0
        my $lasso_check_version_mode =
          eval 'Lasso::Constants::CHECK_VERSION_NUMERIC';
        my $check_version =
          Lasso::check_version( 2, 3, 0, $lasso_check_version_mode );
        unless ($check_version) {
            eval 'use constant BADLASSO => 1';
        }
        else {
            eval 'use constant BADLASSO => 0';
        }

        # Try to set thin-sessions flag
        eval 'Lasso::set_flag("thin-sessions");';
        if ($@) {
            eval 'use constant LASSOTHINSESSIONS => 0';
        }
        else {
            eval 'use constant LASSOTHINSESSIONS => 1';
        }
    }

}

sub init {
    my ($self) = @_;

    # Initialize SAML storage
    my $moduleOptions;
    if ( $self->conf->{samlStorage} ) {
        $moduleOptions = $self->conf->{samlStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{samlStorage};
    }
    else {
        $moduleOptions = $self->conf->{globalStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{globalStorage};
    }
    $self->aModule( $moduleOptions->{backend} );
    $self->amOpts($moduleOptions);

    # Check for Lasso errors/messages (see BEGIN)
    unless (LASSO) {
        $self->logger->error("Module Lasso not loaded (see below)");
        return 0;
    }

    if (BADLASSO) {
        $self->logger->error('Lasso version >= 2.3.0 required');
        return 0;
    }

    unless (LASSOTHINSESSIONS) {
        $self->logger->warn('Lasso thin-sessions flag could not be set');
    }
    else {
        $self->logger->debug('Lasso thin-sessions flag set');
    }
    if (GLIB) {
        Glib::Log->set_handler(
            "Lasso",
            [qw/ error critical warning message info debug /],
            sub {
                $self->logger->debug(
                    $_[0] . " error " . $_[1] . ": " . $_[2] );
            }
        );
    }

    # Conf initialization

    return 0 unless ( $self->lassoServer( $self->loadService ) );
    $self->addUnauthRoute(
        ( $self->{path} || 'saml' ) =>
          { 'metadata' => { ':type' => 'metadata' } },
        ['GET']
    );
    $self->addAuthRoute(
        ( $self->{path} || 'saml' ) =>
          { 'metadata' => { ':type' => 'metadata' } },
        ['GET']
    );
    return 1;
}

# METHODS

sub loadService {
    my ($self) = @_;

    # Check if certificate is available
    unless ($self->conf->{samlServicePublicKeySig}
        and $self->conf->{samlServicePrivateKeySig} )
    {
        $self->logger->error(
            'SAML private and public key not found in configuration');
        return 0;
    }

    my $serviceCertificate;
    if (    $self->conf->{samlServiceUseCertificateInResponse}
        and $self->conf->{samlServicePublicKeySig} =~ /CERTIFICATE/ )
    {
        $serviceCertificate = $self->conf->{samlServicePublicKeySig};
        $self->logger->debug('Certificate will be used in SAML responses');

    }

    # Get metadata from configuration
    $self->logger->debug("Get Metadata for this service");
    my $service_metadata = Lemonldap::NG::Common::Conf::SAML::Metadata->new();

    # Create Lasso server with service metadata
    my $server = $self->createServer(
        $service_metadata->serviceToXML( $self->conf, '' ),
        $self->conf->{samlServicePrivateKeySig},
        $self->conf->{samlServicePrivateKeySigPwd},

        # use signature cert for encryption unless defined
        (
            $self->conf->{samlServicePrivateKeyEnc}
            ? (
                $self->conf->{samlServicePrivateKeyEnc},
                $self->conf->{samlServicePrivateKeyEncPwd}
              )
            : (
                $self->conf->{samlServicePrivateKeySig},
                $self->conf->{samlServicePrivateKeySigPwd}
            )
        ),
        $serviceCertificate
    );

    # Signature method
    my $method = $self->conf->{samlServiceSignatureMethod} || 'RSA_SHA1';
    $server->signature_method( $self->getSignatureMethod($method) );
    $self->logger->debug("Set $method as SAML server signature method ");

    # Log
    unless ($server) {
        $self->logger->error('Unable to create Lasso server');
        return 0;
    }
    $self->logger->debug("Service created");

    return $server;
}

sub loadIDPs {
    my ($self) = @_;

    # Check presence of at least one identity provider in configuration
    unless ( $self->conf->{samlIDPMetaDataXML}
        and keys %{ $self->conf->{samlIDPMetaDataXML} } )
    {
        $self->logger->debug("No IDP found in configuration");
    }

    # Load identity provider metadata
    # IDP metadata are listed in $self->{samlIDPMetaDataXML}
    # Each key is the IDP name
    # Build IDP list for later use in extractFormInfo
    $self->idpList( {} );

    foreach ( keys %{ $self->conf->{samlIDPMetaDataXML} } ) {
        $self->logger->debug("Get Metadata for IDP $_");

        my $idp_metadata =
          $self->conf->{samlIDPMetaDataXML}->{$_}->{samlIDPMetaDataXML};

        # Check metadata format
        if ( ref $idp_metadata eq "HASH" ) {
            $self->logger->error(
"Metadata for IDP $_ is in old format. Please reload them from Manager"
            );
            next;
        }

        if ( $self->conf->{samlMetadataForceUTF8} ) {
            $idp_metadata = encode( "utf8", $idp_metadata );
        }

        # Add this IDP to Lasso::Server
        my $result = $self->addIDP( $self->lassoServer, $idp_metadata );

        unless ($result) {
            $self->logger->error("Fail to use IDP $_ Metadata");
            next;
        }

        # Store IDP entityID and Organization Name
        my ( $tmp, $entityID ) =
          ( $idp_metadata =~ /entityID=(['"])(.+?)\1/si );
        my $name = $self->getOrganizationName( $self->lassoServer, $entityID )
          || ucfirst($_);
        $self->idpList->{$entityID}->{confKey} = $_;
        $self->idpList->{$entityID}->{name}    = $name;

        # Set encryption mode
        my $encryption_mode = $self->conf->{samlIDPMetaDataOptions}->{$_}
          ->{samlIDPMetaDataOptionsEncryptionMode};
        my $lasso_encryption_mode = $self->getEncryptionMode($encryption_mode);

        unless (
            $self->setProviderEncryptionMode(
                $self->lassoServer->get_provider($entityID),
                $lasso_encryption_mode
            )
          )
        {
            $self->logger->error(
                "Unable to set encryption mode $encryption_mode on IDP $_");
            next;
        }
        $self->logger->debug("Set encryption mode $encryption_mode on IDP $_");

        # Set display options
        $self->idpList->{$entityID}->{displayName} =
          $self->conf->{samlIDPMetaDataOptions}->{$_}
          ->{samlIDPMetaDataOptionsDisplayName};
        $self->idpList->{$entityID}->{icon} =
          $self->conf->{samlIDPMetaDataOptions}->{$_}
          ->{samlIDPMetaDataOptionsIcon};
        $self->idpList->{$entityID}->{order} =
          $self->conf->{samlIDPMetaDataOptions}->{$_}
          ->{samlIDPMetaDataOptionsSortNumber};

        # Set rule
        my $cond = $self->conf->{samlIDPMetaDataOptions}->{$_}
          ->{samlIDPMetaDataOptionsResolutionRule};
        if ( length $cond ) {
            $cond = $self->p->HANDLER->substitute($cond);
            unless ( $cond = $self->p->HANDLER->buildSub($cond) ) {
                $self->logger->error( 'SAML IdP rule error: '
                      . $self->p->HANDLER->tsv->{jail}->error );
                next;
            }
            $self->idpRules->{$entityID} = $cond;
        }

        $self->logger->debug("IDP $_ added");
    }
    return 1;
}

sub loadSPs {
    my ($self) = @_;

    # Check presence of at least one service provider in configuration
    unless ( $self->conf->{samlSPMetaDataXML}
        and keys %{ $self->conf->{samlSPMetaDataXML} } )
    {
        $self->logger->debug("No SP found in configuration");
    }

    # Load service provider metadata
    # SP metadata are listed in $self->{samlSPMetaDataXML}
    # Each key is the SP name
    # Build SP list for later use in extractFormInfo
    $self->spList( {} );
    foreach ( keys %{ $self->conf->{samlSPMetaDataXML} } ) {

        $self->logger->debug("Get Metadata for SP $_");

        my $sp_metadata =
          $self->conf->{samlSPMetaDataXML}->{$_}->{samlSPMetaDataXML};

        # Check metadata format
        if ( ref $sp_metadata eq "HASH" ) {
            $self->logger->error(
"Metadata for SP $_ is in old format. Please reload them from Manager"
            );
            next;
        }

        if ( $self->conf->{samlMetadataForceUTF8} ) {
            $sp_metadata = encode( "utf8", $sp_metadata );
        }

        # Add this SP to Lasso::Server
        my $result = $self->addSP( $self->lassoServer, $sp_metadata );

        unless ($result) {
            $self->logger->error("Fail to use SP $_ Metadata");
            next;
        }

        # Store SP entityID and Organization Name
        my ( $tmp, $entityID ) = ( $sp_metadata =~ /entityID=(['"])(.+?)\1/si );
        my $name = $self->getOrganizationName( $self->lassoServer, $entityID )
          || ucfirst($_);
        $self->spList->{$entityID}->{confKey} = $_;
        $self->spList->{$entityID}->{name}    = $name;

        # Set encryption mode
        my $encryption_mode = $self->conf->{samlSPMetaDataOptions}->{$_}
          ->{samlSPMetaDataOptionsEncryptionMode};
        my $lasso_encryption_mode = $self->getEncryptionMode($encryption_mode);

        unless (
            $self->setProviderEncryptionMode(
                $self->lassoServer->get_provider($entityID),
                $lasso_encryption_mode
            )
          )
        {
            $self->logger->error(
                "Unable to set encryption mode $encryption_mode on SP $_");
            next;
        }
        $self->logger->debug("Set encryption mode $encryption_mode on SP $_");

        my $rule = $self->conf->{samlSPMetaDataOptions}->{$_}
          ->{samlSPMetaDataOptionsRule};
        if ( length $rule ) {
            $rule = $self->p->HANDLER->substitute($rule);
            unless ( $rule = $self->p->HANDLER->buildSub($rule) ) {
                $self->logger->error( 'SAML SP rule error: '
                      . $self->p->HANDLER->tsv->{jail}->error );
                next;
            }
            $self->spRules->{$entityID} = $rule;
        }

        $self->logger->debug("SP $_ added");
    }

    return 1;
}

# Check SAML requests and responses
sub checkMessage {
    my ( $self, $req, $url, $request_method, $content_type, $profile_type ) =
      @_;
    $profile_type ||= "login";

    # Create Profile object
    my $profile;
    $profile = $self->createLogin( $self->lassoServer )
      if ( $profile_type eq "login" );
    $profile = $self->createLogout( $self->lassoServer )
      if ( $profile_type eq "logout" );

    # Get relayState
    my $relaystate = $req->param('RelayState');
    my ( $method, $request, $response, $artifact, $message );

    # 2.1. HTTP REDIRECT
    if ( $request_method eq 'GET' ) {

        $method = Lasso::Constants::HTTP_METHOD_REDIRECT;
        $self->logger->debug("SAML method: HTTP-REDIRECT");

        if ( $req->param('SAMLResponse') ) {

            # Response in query string
            $response = $self->getQueryString($req);
            $self->logger->debug("HTTP-REDIRECT: SAML Response $response");

        }

        if ( $req->param('SAMLRequest') ) {

            # Request in query string
            $request = $self->getQueryString($req);
            $self->logger->debug("HTTP-REDIRECT: SAML Request $request");

        }

        if ( $req->param('SAMLart') ) {

            # Artifact in query string
            $artifact = $self->getQueryString($req);
            $self->logger->debug("HTTP-REDIRECT: SAML Artifact $artifact");

            # Resolve Artifact
            $method = Lasso::Constants::HTTP_METHOD_ARTIFACT_GET;
            $message = $self->resolveArtifact( $profile, $artifact, $method );

            # Request or response ?
            if ( $message =~ /samlp:response/i ) {
                $response = $message;
            }
            else {
                $request = $message;
            }
        }

    }

    # 2.2. HTTP POST AND SOAP
    elsif ( $request_method =~ /^POST$/ ) {

        # 2.2.1. POST
        if ( $content_type !~ /xml/ ) {

            $method = Lasso::Constants::HTTP_METHOD_POST;
            $self->logger->debug("SAML method: HTTP-POST");

            if ( $req->param('SAMLResponse') ) {

                # Response in body part
                $response = $req->param('SAMLResponse');
                $response =~ s/ /+/gs;
                $self->logger->debug("HTTP-POST: SAML Response $response");

            }

            elsif ( $req->param('SAMLRequest') ) {

                # Request in body part
                $request = $req->param('SAMLRequest');
                $self->logger->debug("HTTP-POST: SAML Request $request");

            }

            elsif ( $req->param('SAMLart') ) {

                # Artifact in SAMLart param
                $artifact = $req->param('SAMLart');
                $self->logger->debug("HTTP-POST: SAML Artifact $artifact");

                # Resolve Artifact
                $method = Lasso::Constants::HTTP_METHOD_ARTIFACT_POST;
                $message =
                  $self->resolveArtifact( $profile, $artifact, $method );

                # Request or response ?
                if ( $message =~ /samlp:response/i ) {
                    $response = $message;
                }
                else {
                    $request = $message;
                }

            }

        }

        # 2.2.2. SOAP
        else {

            $method = Lasso::Constants::HTTP_METHOD_SOAP;
            $self->logger->debug("SAML method: HTTP-SOAP");

            # SOAP is always a request
            $request = $req->content;
            $self->logger->debug("HTTP-SOAP: SAML Request $request");

        }

    }

    # 4. Return values
    return ( $request, $response, $method, $relaystate, $artifact ? 1 : 0 );
}

## @method boolean checkLassoError(Lasso::Error error, string level)
# Log Lasso error code and message if this is actually a Lasso::Error with code > 0
# @param error Lasso error object
# @param level optional log level (debug by default)
# @return 1 if no error
sub checkLassoError {
    my ( $self, $error, $level ) = @_;
    $level ||= 'debug';

    # If $error is not a Lasso::Error object, display error string
    unless ( ref($error) and $error->isa("Lasso::Error") ) {
        return 1 unless $error;
        $self->p->lmLog( "Lasso error: $error", $level );
        return 0;
    }

    # Else check error code and error message
    if ( $error->{code} ) {
        $self->p->lmLog(
            "Lasso error code " . $error->{code} . ": " . $error->{message},
            $level );
        return 0;
    }

    return 1;
}

## @method Lasso::Server createServer(string metadata, string private_key, string private_key_password, string private_key_enc, string private_key_enc_password, string certificate)
# Load service metadata and create Lasso::Server object
# @param metadata SAML metadata
# @param private_key private key
# @param private_key_password optional private key password
# @param private_key_enc optional private key for encryption
# @param private_key_enc_password optional private key password for encryption
# @param certificate optional certificate
# @return Lasso::Server object
sub createServer {
    my ( $self, $metadata, $private_key, $private_key_password,
        $private_key_enc, $private_key_enc_password, $certificate )
      = @_;
    my $server;

    eval {
        $server = Lasso::Server::new_from_buffers( $metadata, $private_key,
            $private_key_password, $certificate );

        # Set private key for encryption
        if ($private_key_enc) {
            Lasso::Server::set_encryption_private_key_with_password( $server,
                $private_key_enc, $private_key_enc_password );
        }
    };

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $server;
}

## @method boolean addIDP(Lasso::Server server, string metadata, string public_key, string ca_cert_chain)
# Add IDP to an existing Lasso::Server
# @param server Lasso::Server object
# @param metadata IDP metadata
# @param public_key optional public key
# @param ca_cert_chain optional ca cert chain
# @return boolean result
sub addIDP {
    my ( $self, $server, $metadata, $public_key, $ca_cert_chain ) = @_;

    return 0 unless ( $server->isa("Lasso::Server") and defined $metadata );

    return $self->addProvider( $server, Lasso::Constants::PROVIDER_ROLE_IDP,
        $metadata, $public_key, $ca_cert_chain );
}

## @method boolean addSP(Lasso::Server server, string metadata, string public_key, string ca_cert_chain)
# Add SP to an existing Lasso::Server
# @param server Lasso::Server object
# @param metadata SP metadata
# @param public_key optional public key
# @param ca_cert_chain optional ca cert chain
# @return boolean result
sub addSP {
    my ( $self, $server, $metadata, $public_key, $ca_cert_chain ) = @_;

    return 0 unless ( $server->isa("Lasso::Server") and defined $metadata );

    return $self->addProvider( $server, Lasso::Constants::PROVIDER_ROLE_SP,
        $metadata, $public_key, $ca_cert_chain );
}

## @method boolean addAA(Lasso::Server server, string metadata, string public_key, string ca_cert_chain)
# Add Attribute Authority to an existing Lasso::Server
# @param server Lasso::Server object
# @param metadata AA metadata
# @param public_key optional public key
# @param ca_cert_chain optional ca cert chain
# @return boolean result
sub addAA {
    my ( $self, $server, $metadata, $public_key, $ca_cert_chain ) = @_;

    return 0 unless ( $server->isa("Lasso::Server") and defined $metadata );

    return $self->addProvider( $server,
        Lasso::Constants::PROVIDER_ROLE_ATTRIBUTE_AUTHORITY,
        $metadata, $public_key, $ca_cert_chain );
}

## @method boolean addProvider(Lasso::Server server, int role, string metadata, string public_key, string ca_cert_chain)
# Add provider to an existing Lasso::Server
# @param server Lasso::Server object
# @param role (IDP, SP or Both)
# @param metadata IDP metadata
# @param public_key optional public key
# @param ca_cert_chain optional ca cert chain
# @return boolean result
sub addProvider {
    my ( $self, $server, $role, $metadata, $public_key, $ca_cert_chain ) = @_;

    return 0
      unless ( $server->isa("Lasso::Server")
        and defined $role
        and defined $metadata );

    eval {
        Lasso::Server::add_provider_from_buffer( $server, $role, $metadata,
            $public_key, $ca_cert_chain );
    };

    return $self->checkLassoError($@);

}

## @method string getOrganizationName(Lasso::Server server, string idp)
# Return name of organization picked up from metadata
#@param server Lasso::Server object
#@param idp entity ID
#@return string organization name
sub getOrganizationName {
    my ( $self, $server, $idp ) = @_;
    my ( $provider, $node );

    # Get provider from server
    eval { $provider = Lasso::Server::get_provider( $server, $idp ); };

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    # Get organization node
    eval { $node = Lasso::Provider::get_organization($provider); };

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    # Return if node is empty
    return unless $node;

    # Extract organization name
    my $xs   = XML::Simple->new();
    my $data = $xs->XMLin($node);
    return $data->{OrganizationName}->{content};
}

## @method string getNextProviderId(Lasso::Logout logout)
# Returns the provider id from providerID_index in list of providerIDs in
# principal session with the exception of initial service provider ID.
# @param logout Lasso::Logout object
# @return string
sub getNextProviderId {
    my $self   = shift;
    my $logout = shift;
    my $providerId;

    eval { $providerId = Lasso::Logout::get_next_providerID($logout); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $providerId;
}

## @method boolean resetProviderIdIndex(Lasso::Logout logout)
# Reset the providerID_index attribute in Lasso::Logout object
# @param logout Lasso::Logout object
# @return boolean
sub resetProviderIdIndex {
    my $self   = shift;
    my $logout = shift;

    eval { Lasso::Logout::reset_providerID_index($logout); };
    return $self->checkLassoError($@);
}

## @method Lasso::Login createAuthnRequest(Lasso::Server server, string idp, int method, boolean forceAuthn, boolean isPassive, string nameIDFormat, boolean allowProxiedAuthn, boolean signSSOMessage, string requestedAuthnContext)
# Create authentication request for selected IDP
# @param server Lasso::Server object
# @param idp IDP entityID
# @param method HTTP method
# @param forceAuthn force authentication on IDP
# @param isPassive require passive authentication
# @param nameIDFormat SAML2 NameIDFormat
# @param allowProxiedAuthn allow proxy on IDP
# @param signSSOMessage sign request
# @param requestedAuthnContext authentication context
# @return Lasso::Login object
sub createAuthnRequest {
    my (
        $self,           $req,          $server,
        $idp,            $method,       $forceAuthn,
        $isPassive,      $nameIDFormat, $allowProxiedAuthn,
        $signSSOMessage, $requestedAuthnContext
    ) = @_;
    my $proxyCount;
    my $proxyRequestedAuthnContext;

    # Create Lasso Login
    my $login = $self->createLogin($server);

    unless ($login) {
        $self->logger->error('Unable to create Lasso login');
        return;
    }

    # Init authentication request
    unless ( $self->initAuthnRequest( $login, $idp, $method ) ) {
        $self->logger->error(
            "Could not initiate authentication request on $idp");
        return;
    }

    # Set RelayState
    if ( my $relaystate = $self->storeRelayState( $req, 'urldc' ) ) {
        $login->msg_relayState($relaystate);
        $self->logger->debug("Set $relaystate in RelayState");
    }

    # Customize request
    my $request = $login->request();

    # Maybe we are in IDP proxy mode (SAML request received on IDP side)
    # In this case:
    # * Check proxy conditions
    # * Forward some authn constraints
    if ( $req->data->{_proxiedSamlRequest} ) {

        $self->logger->debug("IDP Proxy mode detected");

        # Get ProxyCount value
        eval {
            $proxyCount =
              $req->data->{_proxiedSamlRequest}->Scoping()->ProxyCount();
        };

        # Deny request if ProxyCount eq 0
        if ( defined $proxyCount ) {

            $self->logger->debug(
                "Found proxyCount $proxyCount in proxied request");

            if ( $proxyCount eq 0 ) {
                $self->userLogger->error(
                    "SAML request cannot be proxied (ProxyCount 0)");
                return;
            }
            else {

                # Decrease ProxyCount
                my $scoping = $req->data->{_proxiedSamlRequest}->Scoping();
                $scoping->ProxyCount( $proxyCount-- );
                eval { $request->Scoping($scoping); };
            }
        }

        # isPassive
        eval { $isPassive = $req->data->{_proxiedSamlRequest}->IsPassive(); };

        # forceAuthn
        eval { $forceAuthn = $req->data->{_proxiedSamlRequest}->ForceAuthn(); };

        # requestedAuthnContext
        eval {
            $proxyRequestedAuthnContext =
              $req->data->{_proxiedSamlRequest}->RequestedAuthnContext();
        };
    }

    # NameIDFormat
    if ($nameIDFormat) {
        $self->logger->debug("Use NameIDFormat $nameIDFormat");
        $request->NameIDPolicy()->Format($nameIDFormat);
    }

    # Always allow NameID creation
    $request->NameIDPolicy()->AllowCreate(1);

    # Force authentication
    if ($forceAuthn) {
        $self->logger->debug("Force authentication on IDP");
        $request->ForceAuthn(1);
    }

    # Passive authentication
    if ($isPassive) {
        $self->logger->debug("Passive authentication on IDP");
        $request->IsPassive(1);
    }

    # Allow proxy
    unless ($allowProxiedAuthn) {
        $self->logger->debug("Do not allow this request to be proxied");
        eval {
            my $proxyRestriction = Lasso::Saml2ProxyRestriction->new();
            $proxyRestriction->Audience($idp);
            $proxyRestriction->Count(0);
            my $conditions = $request->Conditions()
              || Lasso::Saml2Conditions->new();
            $conditions->ProxyRestriction($proxyRestriction);
            $request->Conditions($conditions);
        };
        if ($@) {
            $self->checkLassoError($@);
            return;
        }
    }

    # Signature
    if ( $signSSOMessage == 0 ) {
        $self->logger->debug("SSO request will not be signed");
        $self->disableSignature($login);
    }
    elsif ( $signSSOMessage == 1 ) {
        $self->logger->debug("SSO request will be signed");
        $self->forceSignature($login);
    }
    else {
        $self->logger->debug("SSO request signature according to metadata");
    }

    # Requested authentication context
    if ($proxyRequestedAuthnContext) {
        $self->logger->debug("Use RequestedAuthnContext from proxied request");
        $request->RequestedAuthnContext($proxyRequestedAuthnContext);
    }
    elsif ($requestedAuthnContext) {
        $self->logger->debug("Request $requestedAuthnContext context");
        eval {
            my $context = Lasso::Samlp2RequestedAuthnContext->new();
            $context->AuthnContextClassRef($requestedAuthnContext);
            $context->Comparison("minimum");
            $request->RequestedAuthnContext($context);
        };
        if ($@) {
            $self->checkLassoError($@);
            return;
        }
    }

    # Build authentication request
    unless ( $self->buildAuthnRequestMsg($login) ) {
        $self->logger->error("Could not build authentication request on $idp");
        return;
    }

    # Artifact
    if (   $method == $self->getHttpMethod("artifact-get")
        or $method == $self->getHttpMethod("artifact-post") )
    {

        # Get artifact ID and Content, and store them
        my $artifact_id      = $login->get_artifact;
        my $artifact_message = $login->get_artifact_message;

        $self->storeArtifact( $artifact_id, $artifact_message );
    }
    return $login;
}

## @method Lasso::Login createLogin(Lasso::Server server, string dump)
# Create Lasso::Login object
# @param server Lasso::Server object
# @param dump optional XML dump
# @return Lasso::Login object
sub createLogin {
    my ( $self, $server, $dump ) = @_;
    my $login;

    if ($dump) {
        eval { $login = Lasso::Login::new_from_dump( $server, $dump ); };
    }
    else {
        eval { $login = Lasso::Login->new($server); };
    }

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $login;
}

## @method boolean initAuthnRequest(Lasso::Login login, string idp, int method)
# Init authentication request
# @param login Lasso::Login
# @param idp entityID
# @param method HTTP method
# @return boolean result
sub initAuthnRequest {
    my ( $self, $login, $idp, $method ) = @_;

    eval { Lasso::Login::init_authn_request( $login, $idp, $method ); };

    return $self->checkLassoError($@);
}

## @method boolean initIdpInitiatedAuthnRequest(Lasso::Login login, string idp)
# Init authentication request
# @param login Lasso::Login
# @param idp entityID
# @return boolean result
sub initIdpInitiatedAuthnRequest {
    my ( $self, $login, $idp ) = @_;

    eval { Lasso::Login::init_idp_initiated_authn_request( $login, $idp ); };

    return $self->checkLassoError($@);
}

## @method boolean buildAuthnRequestMsg(Lasso::Login login)
# Build authentication request message
# @param login Lasso::Login
# @return boolean result
sub buildAuthnRequestMsg {
    my ( $self, $login ) = @_;

    eval { Lasso::Login::build_authn_request_msg($login); };

    return $self->checkLassoError($@);
}

## @method boolean processAuthnRequestMsg(Lasso::Login login, string request)
# Process authentication request message
# @param login Lasso::Login object
# @param request SAML request
# @return result
sub processAuthnRequestMsg {
    my ( $self, $login, $request ) = @_;

    eval { Lasso::Login::process_authn_request_msg( $login, $request ); };

    return $self->checkLassoError($@);
}

## @method boolean validateRequestMsg(Lasso::Login login, boolean auth, boolean consent)
# Validate request message
# @param login Lasso::Login object
# @param auth is user authenticated?
# @param consent is consent obtained?
# @return result
sub validateRequestMsg {
    my ( $self, $login, $auth, $consent ) = @_;

    eval { Lasso::Login::validate_request_msg( $login, $auth, $consent ); };

    return $self->checkLassoError($@);
}

## @method boolean buildAuthnResponseMsg(Lasso::Login login)
# Build authentication response message
# @param login Lasso::Login object
# @return boolean result
sub buildAuthnResponseMsg {
    my ( $self, $login ) = @_;

    eval { Lasso::Login::build_authn_response_msg($login); };

    return $self->checkLassoError($@);
}

## @method boolean buildArtifactMsg(Lasso::Login login, int method)
# Build artifact message
# @param login Lasso::Login object
# @param method HTTP method
# @return boolean result
sub buildArtifactMsg {
    my ( $self, $login, $method ) = @_;

    eval { Lasso::Login::build_artifact_msg( $login, $method ); };

    return $self->checkLassoError($@);
}

## @method boolean buildAssertion(Lasso::Login login, string authn_context, int notOnOrAfterTimeout)
# Build assertion
# @param login Lasso::Login object
# @param authn_context SAML2 authentication context
# @param notOnOrAfterTimeout Timeout to apply to notOnOrAfter
# @return boolean result
sub buildAssertion {
    my ( $self, $req, $login, $authn_context, $notOnOrAfterTimeout ) = @_;
    $notOnOrAfterTimeout ||= $self->conf->{timeout};

    # Dates
    my $time                    = $req->sessionInfo->{_utime} || time();
    my $timeout                 = $time + $notOnOrAfterTimeout;
    my $authenticationInstant   = $self->timestamp2samldate($time);
    my $reauthenticateOnOrAfter = $self->timestamp2samldate($timeout);
    my $issued_time             = time;
    my $notBefore               = $self->timestamp2samldate($issued_time);
    my $notOnOrAfter =
      $self->timestamp2samldate( $issued_time + $notOnOrAfterTimeout );

    eval {
        Lasso::Login::build_assertion( $login, $authn_context,
            $authenticationInstant, $reauthenticateOnOrAfter, $notBefore,
            $notOnOrAfter );
    };

    return $self->checkLassoError($@);
}

## @method boolean processAuthnResponseMsg(Lasso::Login login, string response)
# Process authentication response message
# @param login Lasso::Login object
# @param response SAML response
# @return result
sub processAuthnResponseMsg {
    my ( $self, $login, $response ) = @_;

    eval { Lasso::Login::process_authn_response_msg( $login, $response ); };

    return $self->checkLassoError($@);
}

# UNUSED
### @method Lasso::Saml2NameID getNameIdentifer(Lasso::Profile profile)
## Get NameID from Lasso Profile
## @param profile Lasso::Profile object
## @return result or NULL if error
#sub getNameIdentifier {
#    my ( $self, $profile ) = @_;
#    my $nameid;
#
#    eval { $nameid = Lasso::Profile::get_nameIdentifier($profile); };
#
#    if ($@) {
#        $self->checkLassoError($@);
#        return;
#    }
#
#    return $nameid;
#}

# UNUSED
### @method Lasso::Identity createIdentity(string dump)
## Create Lasso::Identity object
## @param dump optional Identity dump
## @return Lasso::Identity object
#sub createIdentity {
#    my ( $self, $dump ) = @_;
#    my $identity;
#
#    if ($dump) {
#        eval { $identity = Lasso::Identity::new_from_dump($dump); };
#    }
#    else {
#        eval { $identity = Lasso::Identity->new(); };
#    }
#
#    if ($@) {
#        $self->checkLassoError($@);
#        return;
#    }
#
#    return $identity;
#}

## UNUSED
### @method Lasso::Session createSession(string dump)
## Create Lasso::Session object
## @param dump optional Session dump
## @return Lasso::Session object
#sub createSession {
#    my ( $self, $dump ) = @_;
#    my $session;
#
#    if ($dump) {
#        eval { $session = Lasso::Session::new_from_dump($dump); };
#    }
#    else {
#        eval { $session = Lasso::Session->new(); };
#    }
#
#    if ($@) {
#        $self->checkLassoError($@);
#        return;
#    }
#
#    return $session;
#}

## @method boolean acceptSSO(Lasso::Login login)
# Accept SSO from IDP
# @param login Lasso::Login object
# @return result
sub acceptSSO {
    my ( $self, $login ) = @_;

    eval { Lasso::Login::accept_sso($login); };

    return $self->checkLassoError($@);
}

## @method string storeRelayState(hashref infos)
# Store information in relayState database and return
# corresponding session_id
# @param infos HASH reference of information
sub storeRelayState {
    my ( $self, $req, @data ) = @_;

    # check if there are data to store
    my $infos;
    foreach (@data) {
        $infos->{$_} = $req->{$_} if $req->{$_};
    }
    return unless ($infos);

    # Session type
    $infos->{_type} = "relaystate";

    # Set _utime for session autoremove
    # Use default session timeout and relayState session timeout to compute it
    my $time    = time();
    my $timeout = $self->conf->{timeout};
    my $samlRelayStateTimeout =
      $self->conf->{samlRelayStateTimeout} || $timeout;

    $infos->{_utime} = $time + ( $samlRelayStateTimeout - $timeout );

    # Create relaystate session and store infos in relaystate session
    my $samlSessionInfo = $self->getSamlSession( undef, $infos )
      or return undef;

    # Session ID
    my $relaystate_id = $samlSessionInfo->id;

    # Return session ID
    return $relaystate_id;
}

## @method boolean extractRelayState(string relaystate, boolean relayStateURL)
# Extract RelayState information into $self
# @param relaystate Relay state value
# @param relayStateURL Allow Relay state value to be the redirection URL
# @return result
sub extractRelayState {
    my ( $self, $req, $relaystate, $relayStateURL ) = @_;

    return 0 unless $relaystate;
    if ( $relayStateURL and $relaystate =~ /^https?:\/\// ) {
        $self->logger->debug("RelayState is a redirection URL: $relaystate");
        $req->{urldc} = $relaystate;
        return 1;
    }
    else {

        # Open relaystate session
        my $samlSessionInfo = $self->getSamlSession($relaystate);

        return 0 unless $samlSessionInfo;

        # Push values in $self
        foreach ( keys %{ $samlSessionInfo->data } ) {
            next if $_ =~ /(type|_session_id|_utime)/;
            if ( $_ eq 'issuerUrldc' ) {
                $req->urldc( $samlSessionInfo->data->{$_} );
            }
            else {
                $req->{$_} = $samlSessionInfo->data->{$_};
            }
        }

        # delete relaystate session
        if ( $samlSessionInfo->remove ) {
            $self->logger->debug("Relaystate $relaystate was deleted");
        }
        else {
            $self->logger->error("Unable to delete relaystate $relaystate");
            $self->logger->error( $samlSessionInfo->error );
        }

    }

    return 1;
}

## @method Lasso::Node getAssertion(Lasso::Login login)
# Get assertion in Lasso::Login object
# @param login Lasso::Login object
# @return assertion Lasso::Node object
sub getAssertion {
    my ( $self, $login ) = @_;
    my $assertion;

    eval { $assertion = Lasso::Login::get_assertion($login); };

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $assertion;
}

## @method string getAttributeValue(string name, string format, string friendly_name, arrayref attributes, boolean force_utf8)
# Get SAML attribute value corresponding to name, format and friendly_name
# Multivaluated values are separated by multiValuesSeparator
# If force_utf8 flag is set, value is encoded in UTF-8
# @param name SAML attribute name
# @param format optional SAML attribute format
# @param friendly_name optional SAML attribute friendly name
# @param attributes Attributes
# @param force_utf8 optional flag to force value in UTF-8
# @return attribute value
sub getAttributeValue {
    my ( $self, $name, $format, $friendly_name, $attributes, $force_utf8 ) = @_;
    my $value;

    # Loop on attributes
    foreach (@$attributes) {
        my $attr_name   = $_->Name();
        my $attr_format = $_->NameFormat();
        my $attr_fname  = $_->FriendlyName();

        # Skip if name does not correspond to attribute name
        next if ( $name ne $attr_name );

        # Verify format and friendly name if given
        next if ( $format        and $format ne $attr_format );
        next if ( $friendly_name and $friendly_name ne $attr_fname );

        # Attribute is found, return its content
        my @attr_values = $_->AttributeValue();

        foreach (@attr_values) {
            my $xs      = XML::Simple->new();
            my $data    = $xs->XMLin( $_->dump() );
            my $content = $data->{content};
            $value .= $content . $self->conf->{multiValuesSeparator}
              if $content;
        }
        $value =~ s/$self->{conf}->{multiValuesSeparator}$// if $value;

        # Encode UTF-8 if force_utf8 flag
        $value = encode( "utf8", $value ) if $force_utf8;

    }

    return $value;
}

## @method boolean validateConditions(Lasso::Saml2::Assertion assertion, string entityID, boolean checkTime, boolean checkAudience)
# Validate conditions
# @param assertion SAML2 assertion
# @param entityID relying party entity ID
# @param checkTime Enable time conditions check
# @param checkAudience Enable audience conditions check
# @return result
sub validateConditions {
    my ( $self, $assertion, $entityID, $checkTime, $checkAudience ) = @_;
    my $tolerance = 10;
    my $status;
    $checkTime     = 1 unless defined $checkTime;
    $checkAudience = 1 unless defined $checkAudience;

    # Time
    if ($checkTime) {
        eval {
            $status = Lasso::Saml2Assertion::validate_time_checks( $assertion,
                $tolerance );
        };

        if ($@) {
            $self->checkLassoError($@);
            return 0;
        }

        unless ( $status eq Lasso::Constants::SAML2_ASSERTION_VALID ) {
            $self->logger->error("Time conditions validations result: $status");
            return 0;
        }

        $self->logger->debug("Time conditions validated");
    }
    else {
        $self->logger->debug("Time conditions not checked");
    }

    # Audience
    if ($checkAudience) {
        eval {
            $status =
              Lasso::Saml2Assertion::validate_audience( $assertion, $entityID );
        };

        if ($@) {
            $self->checkLassoError($@);
            return 0;
        }

        unless ( $status eq Lasso::Constants::SAML2_ASSERTION_VALID ) {
            $self->logger->error(
                "Audience conditions validations result: $status");
            return 0;
        }

        $self->logger->debug("Audience conditions validated");
    }
    else {
        $self->logger->debug("Audience conditions not checked");
    }

    return 1;
}

## @method Lasso::Logout createLogoutRequest(Lasso::Server server, string session_dump, int method, boolean signSLOMessage)
# Create logout request for selected entity
# @param server Lasso::Server object
# @param session_dump Lasso::Session dump
# @param method HTTP method
# @param signSLOMessage sign request
# @return Lasso::Login object
sub createLogoutRequest {
    my ( $self, $req, $server, $session_dump, $method, $signSLOMessage ) = @_;
    my $session;

    # Create Lasso Logout
    my $logout = $self->createLogout($server);

    unless ( $self->setSessionFromDump( $logout, $session_dump ) ) {
        $self->logger->error("Could not fill Lasso::Logout with session dump");
        return;
    }

    # Init logout request
    unless ( $self->initLogoutRequest( $logout, undef, $method ) ) {
        $self->logger->error("Could not initiate logout request");
        return;
    }

    # Set RelayState
    if ( my $relaystate = $self->storeRelayState( $req, 'urldc' ) ) {
        $logout->msg_relayState($relaystate);
        $self->logger->debug("Set $relaystate in RelayState");
    }

    # Signature
    if ( $signSLOMessage == 0 ) {
        $self->logger->debug("SLO request will not be signed");
        $self->disableSignature($logout);
    }
    elsif ( $signSLOMessage == 1 ) {
        $self->logger->debug("SLO request will be signed");
        $self->forceSignature($logout);
    }
    else {
        $self->logger->debug("SLO request signature according to metadata");
    }

    # Build logout request
    unless ( $self->buildLogoutRequestMsg($logout) ) {
        $self->logger->error("Could not build logout request");
        return;
    }

    return $logout;

}

## @method Lasso::Logout createLogout(Lasso::Server server, string dump)
# Create Lasso::Logout object
# @param server Lasso::Server object
# @param dump optional XML dump
# @return Lasso::Logout object
sub createLogout {
    my ( $self, $server, $dump ) = @_;
    my $logout;

    if ($dump) {
        eval { $logout = Lasso::Logout::new_from_dump( $server, $dump ); };
    }
    else {
        eval { $logout = Lasso::Logout->new($server); };
    }

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $logout;
}

## @method boolean initLogoutRequest(Lasso::Logout logout, string entityID, int method)
# Init logout request
# @param logout Lasso::Logout object
# @param entityID Entity ID
# @param method HTTP method
# @return result
sub initLogoutRequest {
    my ( $self, $logout, $entityID, $method ) = @_;

    eval { Lasso::Logout::init_request( $logout, $entityID, $method ); };

    return $self->checkLassoError($@);
}

## @method boolean buildLogoutRequestMsg(Lasso::Logout logout)
# Build logout request message
# @param logout Lasso::Logout object
# @return result
sub buildLogoutRequestMsg {
    my ( $self, $logout ) = @_;

    eval { Lasso::Logout::build_request_msg($logout); };

    return $self->checkLassoError($@);
}

## @method boolean setSessionFromDump(Lasso::Profile profile, string dump)
# Set session from dump in Lasso::Profile object
# @param profile Lasso::Profile object
# @param dump Lasso::Session XML dump
# @return result
sub setSessionFromDump {
    my ( $self, $profile, $dump ) = @_;

    $self->logger->debug("Loading Session dump: $dump");

    eval { Lasso::Profile::set_session_from_dump( $profile, $dump ); };

    return $self->checkLassoError($@);
}

## @method boolean setIdentityFromDump(Lasso::Profile profile, string dump)
# Set identity from dump in Lasso::Profile object
# @param profile Lasso::Profile object
# @param dump Lasso::Identity XML dump
# @return result
sub setIdentityFromDump {
    my ( $self, $profile, $dump ) = @_;

    eval { Lasso::Profile::set_identity_from_dump( $profile, $dump ); };

    return $self->checkLassoError($@);
}

## @method string getMetaDataURL(string key, int index)
# Get URL stored in a service metadata configuration key
# Replace #PORTAL# macro
# @param key Metadata configuration key
# @param index field index containing URL
# @param full Return full URL instead of path
# @return url
sub getMetaDataURL {
    my ( $self, $key, $index, $full ) = @_;
    $index = 3 unless defined $index;
    $full  = 0 unless defined $full;

    return '' unless defined $self->conf->{$key};

    my $url = ( split( /;/, $self->conf->{$key} ) )[$index] || '';

    # Get portal value
    my $portal = $self->conf->{portal};
    $portal =~ s/\/$//;

    # Replace #PORTAL# macro
    $url =~ s/#PORTAL#/$portal/g;

    # Return Full URL
    return $url if $full;

    # Return only path
    my $uri = URI->new($url);
    return $uri->path();
}

sub getRouteFromMetaDataURL {
    my ( $self, $key, $index, $sub ) = @_;
    my $uri = $self->getMetaDataURL( $key, $index, 0 );
    unless ( $uri =~ m#^/\w# ) {
        $self->logger->debug("$key has no index $index");
        return ();
    }
    my @t = grep /\w/, split( /\//, $uri );
    my $h = { pop(@t) => $sub };
    while ( my $s = pop @t ) {
        $h = { $s => $h };
    }
    return %$h;
}

sub addRouteFromMetaDataURL {
    my ( $self, @args ) = @_;
    $self->addAuthRouteFromMetaDataURL(@args);
    $self->addUnauthRouteFromMetaDataURL(@args);
}

sub addAuthRouteFromMetaDataURL {
    my ( $self, $key, $index, $sub, $methods ) = @_;
    my %route = $self->getRouteFromMetaDataURL( $key, $index, $sub );
    return unless (%route);
    $self->addAuthRoute( %route, $methods );
}

sub addUnauthRouteFromMetaDataURL {
    my ( $self, $key, $index, $sub, $methods ) = @_;
    my %route = $self->getRouteFromMetaDataURL( $key, $index, $sub );
    return unless (%route);
    $self->addUnauthRoute( %route, $methods );
}

## @method boolean processLogoutResponseMsg(Lasso::Logout logout, string response)
# Process logout response message
# @param logout Lasso::Logout object
# @param response SAML response
# @return result
sub processLogoutResponseMsg {
    my ( $self, $logout, $response ) = @_;

    eval { Lasso::Logout::process_response_msg( $logout, $response ); };

    return $self->checkLassoError($@);
}

## @method boolean processLogoutRequestMsg(Lasso::Logout logout, string request)
# Process logout request message
# @param logout Lasso::Logout object
# @param request SAML request
# @return result
sub processLogoutRequestMsg {
    my ( $self, $logout, $request ) = @_;

    # Process the request
    eval { Lasso::Logout::process_request_msg( $logout, $request ); };

    return 0 unless $self->checkLassoError($@);

    # Check NotOnOrAfter optional attribute
    my $notOnOrAfter;

    eval { $notOnOrAfter = $logout->request()->NotOnOrAfter(); };

    return 1 if ( $@ or !$notOnOrAfter );

    $self->logger->debug("Found NotOnOrAfter $notOnOrAfter in logout request");

    my $expirationTime = $self->samldate2timestamp($notOnOrAfter);

    return ( time < $expirationTime );
}

## @method boolean validateLogoutRequest(Lasso::Logout logout)
# Validate logout request
# @param logout Lasso::Logout object
# @return result
sub validateLogoutRequest {
    my ( $self, $logout ) = @_;

    eval { Lasso::Logout::validate_request($logout); };

    return $self->checkLassoError($@);
}

## @method boolean buildLogoutResponseMsg(Lasso::Logout logout)
# Build logout response message
# @param logout Lasso::Logout object
# @return boolean result
sub buildLogoutResponseMsg {
    my ( $self, $logout ) = @_;

    eval { Lasso::Logout::build_response_msg($logout); };

    return $self->checkLassoError($@);
}

## @method boolean storeReplayProtection(string samlID, string samlData)
# Store ID of an SAML message in Replay Protection base
# @param samlID ID of SAML message
# @param samlData Optional data to store
# @return result
sub storeReplayProtection {
    my ( $self, $samlID, $samlData ) = @_;
    my $infos = {
        type       => 'assertion',    # Session type
        _utime     => time(),         # Creation time
        _assert_id => $samlID,
    };

    if ( defined $samlData && $samlData ) {
        $infos->{data} = $samlData;
    }

    my $samlSessionInfo = $self->getSamlSession( undef, $infos );
    return 0 unless $samlSessionInfo;

    my $session_id = $samlSessionInfo->id;

    $self->logger->debug(
        "Keep request ID $samlID in assertion session $session_id");

    return 1;
}

## @method boolean replayProtection(string samlID)
# Check if SAML message do not correspond to a previously responded message
# @param samlID ID of initial SAML message
# @return result
sub replayProtection {
    my ( $self, $samlID ) = @_;

    unless ($samlID) {
        $self->userLogger->error(
            "Cannot verify replay because no SAML ID given");
        return 0;
    }

    my $sessions =
      Lemonldap::NG::Common::Apache::Session->searchOn( $self->amOpts,
        "_assert_id", $samlID );

    if (
        my @keys =
        grep { $sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$sessions
      )
    {

        # A session was found
        foreach (@keys) {
            next
              unless ( $sessions->{$_}->{_session_kind} eq $self->sessionKind );
            my $session = $_;
            my $result  = 1;

            # Delete it
            my $samlSessionInfo = $self->getSamlSession($_);

            return 0 unless $samlSessionInfo;

            if ( defined $samlSessionInfo->data->{data} ) {
                $result = $samlSessionInfo->data->{data};
            }

            if ( $samlSessionInfo->remove ) {
                $self->logger->debug(
"Assertion session $session (Message ID $samlID) was deleted"
                );
                return $result;
            }
            else {
                $self->logger->error(
"Unable to delete assertion session $session (Message ID $samlID)"
                );
                $self->logger->error( $samlSessionInfo->error );
                return 0;
            }
        }
    }

    return 0;
}

## @method string resolveArtifact(Lasso::Profile profile, string artifact, int method)
# Resolve artifact to get real SAML message
# @param profile Lasso::Profile object
# @param artifact Artifact message
# @param method HTTP method
# @return SAML message
sub resolveArtifact {
    my ( $self, $profile, $artifact, $method ) = @_;
    my $message;

    # Login profile
    if ( $profile->isa("Lasso::Login") ) {

        # Init request message
        eval { Lasso::Login::init_request( $profile, $artifact, $method ); };
        return unless $self->checkLassoError($@);

        # Build request message
        eval { Lasso::Login::build_request_msg($profile); };
        return unless $self->checkLassoError($@);

        unless ( $profile->msg_url ) {
            $self->logger->error("No artifact resolution URL found");
            return;
        }

        my $request = HTTP::Request->new( 'POST' => $profile->msg_url );
        $request->content_type('application/xml');
        $request->header( Accept => 'application/xml' );
        $request->content( $profile->msg_body );

        $self->logger->debug(
            "Send message " . $profile->msg_body . " to " . $profile->msg_url );

        # SOAP call
        my $soap_answer = $self->ua->request($request);
        if ( $soap_answer->code() == "200" ) {
            $message = $soap_answer->content();
            $self->logger->debug("Get message $message");
        }
    }

    return $message;
}

## @method boolean storeArtifact(string id, string message, string session_id)
# Store artifact
# @param id Artifact ID
# @param message Artifact content
# @param session_id Session ID
# @return result
sub storeArtifact {
    my ( $self, $id, $message, $session_id ) = @_;

    my $infos = {
        type    => 'artifact',    # Session type
        _utime  => time(),        # Creation time
        _art_id => $id,
        message => $message,
    };
    $infos->{_saml_id} = $session_id if $session_id;

    my $samlSessionInfo = $self->getSamlSession( undef, $infos ) or return 0;
    return 0 unless $samlSessionInfo;

    my $art_session_id = $samlSessionInfo->id;

    $self->logger->debug("Keep artifact $id in session $art_session_id");

    return 1;
}

## @method hashRef loadArtifact(string id)
# Load artifact
# @param id Artifact ID
# @return Artifact session content
sub loadArtifact {
    my ( $self, $id ) = @_;
    my $art_session;

    unless ($id) {
        $self->logger->error("Cannot load artifact because no id given");
        return;
    }

    my $sessions =
      Lemonldap::NG::Common::Apache::Session->searchOn( $self->amOpts,
        "_art_id", $id );

    if (
        my @keys =
        grep { $sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$sessions
      )
    {

        my $nb_sessions = $#keys + 1;

        $self->logger->debug("Found $nb_sessions sessions for artifact $id");

        # There should only be 1 result
        return if ( $nb_sessions != 1 );

        my $session_id = shift @keys;
        my $session    = $session_id;

        # Open session
        my $samlSessionInfo = $self->getSamlSession($session_id);

        return unless $samlSessionInfo;

        # Get session contents
        foreach ( keys %{ $samlSessionInfo->data } ) {
            $art_session->{$_} = $samlSessionInfo->data->{$_};
        }

        # Delete session
        if ( $samlSessionInfo->remove ) {
            $self->logger->debug(
                "Artifact session $session (ID $id) was deleted");

            return $art_session;
        }
        else {
            $self->logger->error(
                "Unable to delete artifact session $session (ID $id)");
            $self->logger->error( $samlSessionInfo->error );
            return;
        }
    }

    return;
}

## @method string createArtifactResponse(Lasso::Login login)
# Create artifact response
# @param login Lasso::Login object
# @return Artifact response
sub createArtifactResponse {
    my ( $self, $req, $login ) = @_;

    my $artifact_id = $login->assertionArtifact();

    # Load artifact message into login response
    my $art_session = $self->loadArtifact($artifact_id);
    utf8::decode( $art_session->{message} );
    eval { $login->set_artifact_message( $art_session->{message} ); };
    if ($@) {
        $self->checkLassoError($@);
        $self->logger->error("Cannot load artifact message");
        return;
    }

    $self->logger->debug("Response loaded");

    # Try to get Lasso session
    my $session_id = $art_session->{_saml_id};
    if ($session_id) {
        $self->logger->debug("Find session_id $session_id in artifact session");

        my $session = $self->p->getApacheSession($session_id);
        unless ($session) {
            $self->logger->error("Unable to open session $session_id");
            return;
        }

        my $lassoSession = $session->data->{ $self->lsDump };

        if ($lassoSession) {
            unless ( $self->setSessionFromDump( $login, $lassoSession ) ) {
                $self->logger->error("Unable to load Lasso Session");
                return;
            }
            $self->logger->debug("Lasso Session loaded");
        }

    }
    else {
        $self->logger->debug("No session_id in artifact session");
    }

    # Build artifact response
    eval { Lasso::Login::build_response_msg($login); };
    if ($@) {
        $self->checkLassoError($@);
        $self->logger->error("Cannot build artifact response");
        return;
    }
    $self->logger->debug("Artifact response built");

    # Store Lasso session if session opened
    if ( $session_id and $login->is_session_dirty ) {
        $self->logger->debug("Save Lasso session in session");
        $self->updateSession( $req,
            { $self->lsDump => $login->get_session->dump }, $session_id );
    }

    # Return artifact message
    return $login->msg_body;
}

## @method boolean processArtRequestMsg(Lasso::Profile profile, string request)
# Process artifact request message
# @param profile Lasso::Profile object
# @param request SAML request
# @return result
sub processArtRequestMsg {
    my ( $self, $profile, $request ) = @_;

    # Login profile
    if ( $profile->isa("Lasso::Login") ) {

        eval { Lasso::Login::process_request_msg( $profile, $request ); };
        return $self->checkLassoError($@);

    }

    return 0;
}

## @method boolean processArtResponseMsg(Lasso::Profile profile, string response)
# Process artifact response message
# @param profile Lasso::Profile object
# @param response SAML response
# @return result
sub processArtResponseMsg {
    my ( $self, $profile, $response ) = @_;

    # Login profile
    if ( $profile->isa("Lasso::Login") ) {

        eval { Lasso::Login::process_response_msg( $profile, $response ); };
        return $self->checkLassoError($@);

    }

    return 0;
}

## @method string sendSOAPMessage(string endpoint, string message)
# Send SOAP message and get response
# @param endpoint SOAP End Point
# @param message SOAP message
# @return SOAP response
sub sendSOAPMessage {
    my ( $self, $endpoint, $message ) = @_;
    my $response;

    my $request = HTTP::Request->new( 'POST' => $endpoint );
    $request->content_type('application/xml');
    $request->header( Accept => 'application/xml' );
    $request->content($message);

    $self->logger->debug("Send SOAP message $message to $endpoint");

    # SOAP call
    my $soap_answer = $self->ua()->request($request);
    if ( $soap_answer->code() == "200" ) {
        $response = $soap_answer->content();
        $self->logger->debug("Get response $response");
    }
    else {
        $self->logger->debug("No response to SOAP request");
        return;
    }

    return $response;
}

## @method Lasso::AssertionQuery createAssertionQuery(Lasso::Server server)
# Create a new assertion query
# @param server Lasso::Server object
# @return assertion query
sub createAssertionQuery {
    my ( $self, $server ) = @_;
    my $query;

    # Create assertion query
    eval { $query = Lasso::AssertionQuery->new($server); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $query;
}

## @method Lasso::AssertionQuery createAttributeRequest(Lasso::Server server, string idp, hashref attributes, Lasso::Saml2NameID nameid)
# Create an attribute request
# @param server Lasso::Server object
# @param idp IDP entityID
# @param attributes List of requested attributes
# @param nameid Subject NameID
# @return attribute request
sub createAttributeRequest {
    my ( $self, $server, $idp, $attributes, $nameid ) = @_;
    my $query;

    # Create assertion query
    return unless ( $query = $self->createAssertionQuery($server) );

    $self->logger->debug("Assertion query created");

    # Init request
    my $method = Lasso::Constants::HTTP_METHOD_SOAP;
    my $type   = Lasso::Constants::ASSERTION_QUERY_REQUEST_TYPE_ATTRIBUTE;
    eval {
        Lasso::AssertionQuery::init_request( $query, $idp, $method, $type );
    };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    $self->logger->debug("Assertion query request initiated");

    # Set NameID
    eval { $query->request()->Subject()->NameID($nameid); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    $self->logger->debug(
        "Set NameID " . $nameid->dump . " in assertion query" );

    # Store attributes in request
    my @requested_attributes;
    foreach ( keys %$attributes ) {

        # Create SAML2 Attribute
        my $attribute;

        eval { $attribute = Lasso::Saml2Attribute->new(); };
        if ($@) {
            $self->checkLassoError($@);
            return;
        }

        # Set attribute properties
        my ( $mandatory, $name, $format, $friendly_name ) =
          split( /;/, $attributes->{$_} );

        $attribute->Name($name)                  if defined $name;
        $attribute->NameFormat($format)          if defined $format;
        $attribute->FriendlyName($friendly_name) if defined $friendly_name;

        # Store attribute
        push @requested_attributes, $attribute;
    }

    # Set attributes in request
    eval { $query->request()->Attribute(@requested_attributes); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    # Build message
    eval { Lasso::AssertionQuery::build_request_msg($query); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    # Return query
    return $query;
}

## @method boolean validateAttributeRequest(Lasso::AssertionQuery query)
# Validate an attribute request
# @param query Lasso::AssertionQuery object
# @return result
sub validateAttributeRequest {
    my ( $self, $query ) = @_;

    eval { Lasso::AssertionQuery::validate_request($query); };

    return $self->checkLassoError($@);
}

## @method Lasso::AssertionQuery processAttributeRequest(Lasso::Server server, string request)
# Process an attribute request
# @param server Lasso::Server object
# @param request Request content
# @return assertion query
sub processAttributeRequest {
    my ( $self, $server, $request ) = @_;
    my $query;

    # Create assertion query
    return unless ( $query = $self->createAssertionQuery($server) );

    $self->logger->debug("Assertion query created");

    # Process response
    eval { Lasso::AssertionQuery::process_request_msg( $query, $request ); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    $self->logger->debug("Attribute request is valid");

    return $query;
}

## @method string buildAttributeResponse(Lasso::AssertionQuery query)
# Build attribute response
# @param query Lasso::AssertionQuery object
# @return attribute response
sub buildAttributeResponse {
    my ( $self, $query ) = @_;

    eval { Lasso::AssertionQuery::build_response_msg($query); };

    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $query->msg_body;
}

## @method Lasso::AssertionQuery processAttributeResponse(Lasso::Server server, string response)
# Process an attribute response
# @param server Lasso::Server object
# @param response Response content
# @return assertion query
sub processAttributeResponse {
    my ( $self, $server, $response ) = @_;
    my $query;

    # Create assertion query
    return unless ( $query = $self->createAssertionQuery($server) );

    $self->logger->debug("Assertion query created");

    # Process response
    eval { Lasso::AssertionQuery::process_response_msg( $query, $response ); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    $self->logger->debug("Attribute response is valid");

    return $query;
}

## @method string getNameIDFormat(string format)
# Convert configuration string into SAML2 NameIDFormat string
# @param format configuration string
# @return SAML2 NameIDFormat string
sub getNameIDFormat {
    my ( $self, $format ) = @_;

    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_UNSPECIFIED
      if ( $format =~ /unspecified/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_EMAIL
      if ( $format =~ /email/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_X509
      if ( $format =~ /x509/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_WINDOWS
      if ( $format =~ /windows/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_KERBEROS
      if ( $format =~ /kerberos/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_ENTITY
      if ( $format =~ /entity/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_PERSISTENT
      if ( $format =~ /persistent/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_TRANSIENT
      if ( $format =~ /transient/i );
    return Lasso::Constants::SAML2_NAME_IDENTIFIER_FORMAT_ENCRYPTED
      if ( $format =~ /encrypted/i );

    return;
}

## @method int getHttpMethod(string method)
# Convert configuration string into Lasso HTTP Method integer
# @param method configuration string
# @return Lasso HTTP Method integer
sub getHttpMethod {
    my ( $self, $method ) = @_;

    return Lasso::Constants::HTTP_METHOD_POST
      if ( $method =~ /^(http)?[-_]?post$/i );
    return Lasso::Constants::HTTP_METHOD_REDIRECT
      if ( $method =~ /^(http)?[-_]?redirect$/i );
    return Lasso::Constants::HTTP_METHOD_SOAP
      if ( $method =~ /^(http)?[-_]?soap$/i );
    return Lasso::Constants::HTTP_METHOD_ARTIFACT_GET
      if ( $method =~ /^(artifact)[-_]get$/i );
    return Lasso::Constants::HTTP_METHOD_ARTIFACT_POST
      if ( $method =~ /^(artifact)[-_]post$/i );

    return;
}

## @method int getHttpMethodString(int method)
# Convert configuration Lasso HTTP Method integer into string
# @param method Lasso HTTP Method
# @return method string
sub getHttpMethodString {
    my ( $self, $method ) = @_;

    return "POST" if ( $method == Lasso::Constants::HTTP_METHOD_POST );
    return "REDIRECT"
      if ( $method == Lasso::Constants::HTTP_METHOD_REDIRECT );
    return "SOAP" if ( $method == Lasso::Constants::HTTP_METHOD_SOAP );
    return "ARTIFACT GET"
      if ( $method == Lasso::Constants::HTTP_METHOD_ARTIFACT_GET );
    return "ARTIFACT POST"
      if ( $method == Lasso::Constants::HTTP_METHOD_ARTIFACT_POST );

    return "UNDEFINED";
}
## @method int getFirstHttpMethod(Lasso::Server server, string entityID, int protocolType)
# Find a suitable HTTP method for an entity with a given protocol
# @param server Lasso::Server object
# @param entityID entity ID
# @param protocolType Lasso protocol type
# @return Lasso HTTP Method
sub getFirstHttpMethod {
    my ( $self, $server, $entityID, $protocolType ) = @_;
    my $entity_provider;
    my $method;

    # Get Lasso::Provider object
    eval {
        $entity_provider = Lasso::Server::get_provider( $server, $entityID );
    };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    # Find HTTP method
    eval {
        $method =
          Lasso::Provider::get_first_http_method( $server, $entity_provider,
            $protocolType );
    };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    return $method;
}

## @method boolean disableSignature(Lasso::Profile profile)
# Modify Lasso signature hint to disable signature
# @param profile Lasso profile object
# @return result
sub disableSignature {
    my ( $self, $profile ) = @_;

    eval {
        Lasso::Profile::set_signature_hint( $profile,
            Lasso::Constants::PROFILE_SIGNATURE_HINT_FORBID );
    };

    return $self->checkLassoError($@);
}

## @method boolean forceSignature(Lasso::Profile profile)
# Modify Lasso signature hint to force signature
# @param profile Lasso profile object
# @return result
sub forceSignature {
    my ( $self, $profile ) = @_;

    eval {
        Lasso::Profile::set_signature_hint( $profile,
            Lasso::Constants::PROFILE_SIGNATURE_HINT_FORCE );
    };

    return $self->checkLassoError($@);
}

## @method boolean disableSignatureVerification(Lasso::Profile profile)
# Modify Lasso signature hint to disable signature verification
# @param profile Lasso profile object
# @return result
sub disableSignatureVerification {
    my ( $self, $profile ) = @_;

    eval {
        Lasso::Profile::set_signature_verify_hint( $profile,
            Lasso::Constants::PROFILE_SIGNATURE_VERIFY_HINT_IGNORE );
    };

    return $self->checkLassoError($@);
}

## @method boolean forceSignatureVerification(Lasso::Profile profile)
# Modify Lasso signature hint to force signature verification
# @param profile Lasso profile object
# @return result
sub forceSignatureVerification {
    my ( $self, $profile ) = @_;

    eval {
        Lasso::Profile::set_signature_verify_hint( $profile,
            Lasso::Constants::PROFILE_SIGNATURE_VERIFY_HINT_MAYBE );
    };

    return $self->checkLassoError($@);
}

## @method string getAuthnContext(string context)
# Convert configuration string into SAML2 AuthnContextClassRef string
# @param context configuration string
# @return SAML2 AuthnContextClassRef string
sub getAuthnContext {
    my ( $self, $context ) = @_;

    return Lasso::Constants::SAML2_AUTHN_CONTEXT_KERBEROS
      if ( $context =~ /^kerberos$/i );
    return Lasso::Constants::SAML2_AUTHN_CONTEXT_PASSWORD_PROTECTED_TRANSPORT
      if ( $context =~ /^password[-_ ]protected[-_ ]transport$/i );
    return Lasso::Constants::SAML2_AUTHN_CONTEXT_PASSWORD
      if ( $context =~ /^password$/i );
    return Lasso::Constants::SAML2_AUTHN_CONTEXT_X509
      if ( $context =~ /^x509$/i );
    return Lasso::Constants::SAML2_AUTHN_CONTEXT_TLS_CLIENT
      if ( $context =~ /^tls[-_ ]client$/i );
    return Lasso::Constants::SAML2_AUTHN_CONTEXT_UNSPECIFIED
      if ( $context =~ /^unspecified$/i );

    return;
}

## @method string timestamp2samldate(string timestamp)
# Convert timestamp into SAML2 date format
# @param timestamp UNIX timestamp
# @return SAML2 date
sub timestamp2samldate {
    my ( $self, $timestamp ) = @_;

    my @t = gmtime($timestamp);
    my $samldate = strftime( "%Y-%m-%dT%TZ", @t );

    $self->logger->debug(
        "Convert timestamp $timestamp in SAML2 date: $samldate");

    return $samldate;
}

## @method string samldate2timestamp(string samldate)
# Convert SAML2 date format into timestamp
# @param samldate SAML2 date format
# @return UNIX timestamp
sub samldate2timestamp {
    my ( $self, $samldate ) = @_;

    my ( $year, $mon, $mday, $hour, $min, $sec, $msec, $ztime ) = ( $samldate =~
          /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z)?/ );

    my $timestamp =
      timegm( $sec, $min, $hour, $mday, $mon - 1, $year - 1900, 0 );

    $self->logger->debug(
        "Convert SAML2 date $samldate in timestamp: $timestamp");

    return $timestamp;
}

## @pmethod int sendLogoutResponseToServiceProvider(Lasso::Logout $logout, int $method)
# Send logout response issue from a logout request.
# @param $logout Lasso Logout object
# @param $method Method to use
# @return boolean False if failed.
sub sendLogoutResponseToServiceProvider {
    my ( $self, $req, $logout, $method ) = @_;

    # Logout response
    unless ( $self->buildLogoutResponseMsg($logout) ) {
        $self->logger->warn( "Could not build a logout response for provider "
              . $logout->remote_providerID
              . ", staying on portal" );
        return $self->p->do( $req, [] );
    }

    # Send response depending on request method
    # HTTP-REDIRECT
    if ( $method == Lasso::Constants::HTTP_METHOD_REDIRECT ) {

        # Redirect user to response URL
        my $slo_url = $logout->msg_url;
        return [ 302, [ Location => $slo_url ], [] ];
    }

    # HTTP-POST
    elsif ( $method == Lasso::Constants::HTTP_METHOD_POST ) {

        # Use autosubmit form
        my $slo_url    = $logout->msg_url;
        my $slo_body   = $logout->msg_body;
        my $relaystate = $logout->msg_relayState;

        # TODO: insert postUrl in $req
        $req->postUrl($slo_url);
        $req->{postFields} = { 'SAMLResponse' => $slo_body };

        # RelayState
        $req->{postFields}->{'RelayState'} = $relaystate
          if ($relaystate);

        return $self->p->do( $req, ['autoPost'] );
    }
    elsif ( $method == Lasso::Constants::HTTP_METHOD_SOAP ) {
        return $self->sendSLOSoapErrorResponse( $req, $logout, $method );
    }
    return $self->p->sendError( $req,
        "Lasso method '$method' should not be handle here...", 400 );
}

## @pmethod int sendLogoutRequestToProvider(Lasso::Logout $logout, string $providerID, int $method, boolean $relay, string $relayState)
# Send a logout request to a provider
# If information have to be displayed to users, such as iframe to send
# HTTP-Redirect or HTTP-POST logout request, then $self->{_info} will be
# updated.
# @param $logout Lasso Logout object
# @param $providerID The concerned service provider
# @param $method The method used to send the logout request
# @param $relay If SOAP method, build a relay logout request
# @param $relayState Relay State for SLO status
# @return int Number of concerned providers.
sub sendLogoutRequestToProvider {
    my ( $self, $req, $logout, $providerID, $method, $relay, $relayState ) = @_;
    my $server = $self->lassoServer;
    my $info;

    # Test if provider is mentionned
    if ( !$providerID ) {
        return ( 0, undef, undef );
    }

    my $type = defined $self->spList->{$providerID} ? "SP" : "IDP";

    # Find EntityID in spList or idpList
    unless ( defined $self->{ lc($type) . 'List' }->{$providerID} ) {
        $self->logger->error("$providerID does not match any known $type");
        return ( 0, undef, undef );
    }

    # Get Provider Name and Conf Key from EntityID
    my $providerName =
      $self->{ lc($type) . 'List' }->{$providerID}->{name};
    my $confKey =
      $self->{ lc($type) . 'List' }->{$providerID}->{confKey};

    # Get first HTTP method
    my $protocolType = Lasso::Constants::MD_PROTOCOL_TYPE_SINGLE_LOGOUT;
    if ( !$method ) {
        $method =
          $self->getFirstHttpMethod( $server, $providerID, $protocolType );
    }

    # Fix a default value for the relay parameter
    $relay = 0 unless ( defined $relay );

    # Signature
    my $signSLOMessage =
      $self->conf->{ 'saml' . $type . 'MetaDataOptions' }->{$confKey}
      ->{ 'saml' . $type . 'MetaDataOptionsSignSLOMessage' };

    if ( $signSLOMessage == 0 ) {
        $self->logger->debug("SLO request will not be signed");
        $self->disableSignature($logout);
    }
    elsif ( $signSLOMessage == 1 ) {
        $self->logger->debug("SLO request will be signed");
        $self->forceSignature($logout);
    }
    else {
        $self->logger->debug("SLO request signature according to metadata");
    }

    # Relay State
    if ($relayState) {
        eval { $logout->msg_relayState($relayState); };
        if ($@) {
            $self->logger->error(
"Unable to set Relay State $relayState in SLO request for $confKey"
            );
            return ( 0, $method, undef );
        }
        $self->logger->debug('Relay state set');
    }

    # Build the request
    unless ( $logout->request() ) {

        $self->logger->debug("No logout request found, build it");

        # Initiate the logout request
        unless ( $self->initLogoutRequest( $logout, $providerID, $method ) ) {
            $self->logger->error(
                "Initiate logout request failed for $providerID");
            return ( 0, $method, undef );
        }

        # Build request message
        unless ( $self->buildLogoutRequestMsg($logout) ) {
            $self->logger->error("Build logout request failed for $providerID");
            return ( 0, $method, undef );
        }

        $self->logger->debug("Request built for $providerID");
    }

    # Keep message ID in memory to prevent replay
    my $samlID = $logout->request()->ID;
    unless ( $self->storeReplayProtection($samlID) ) {
        $self->logger->error("Unable to store message ID");
        return ( 0, $method, undef );
    }

    # Get portal value
    my $portal = $self->conf->{portal};
    $portal =~ s/\/$//;

    # Send logout request to the provider depending of the request method
    # HTTP-REDIRECT
    if ( $method == Lasso::Constants::HTTP_METHOD_REDIRECT ) {

        $self->logger->debug(
            "Send HTTP-REDIRECT logout request to $providerID");

        # Redirect user to response URL
        my $slo_url = $logout->msg_url;

        # Create iFrame
        $info .= $self->loadTemplate(
            $req,
            'samlSpLogout',
            params => {
                url  => $slo_url,
                name => $providerName,
            }
        );
    }

    # HTTP-POST
    elsif ( $method == Lasso::Constants::HTTP_METHOD_POST ) {

        $self->logger->debug("Build POST relay logout request to $providerID");

        my $infos;

        # Store infos
        $infos->{type}       = 'relay';
        $infos->{_utime}     = time;
        $infos->{url}        = $logout->msg_url;
        $infos->{body}       = $logout->msg_body;
        $infos->{relayState} = $logout->msg_relayState;

        # Create a new relay session
        my $relayInfos = $self->getSamlSession( undef, $infos );

        my $relayID = $relayInfos->id;

        # Build the URL that could be used to play this logout request
        my $slo_url =
            $portal
          . '/saml/relaySingleLogoutPOST?'
          . build_urlencoded( relay => $relayID );

        # Create iFrame
        $info .= $self->loadTemplate(
            $req,
            'samlSpLogout',
            params => {
                url  => $slo_url,
                name => $providerName,
            }
        );
    }

    # HTTP-SOAP
    elsif ( $method == Lasso::Constants::HTTP_METHOD_SOAP ) {

        # Build a relay request, to be used after SLO process is done
        if ($relay) {

            $self->logger->debug(
                "Build SOAP relay logout request for $providerID");

            my $infos;
            $infos->{type}            = 'relay';
            $infos->{_utime}          = time;
            $infos->{ $self->lsDump } = $req->sessionInfo->{ $self->lsDump };
            $infos->{ $self->liDump } = $req->sessionInfo->{ $self->liDump };
            $infos->{_providerID}     = $providerID;
            $infos->{_relayState}     = $logout->msg_relayState;

            # Create a new relay session
            my $relayInfos = $self->getSamlSession( undef, $infos );

            my $relayID = $relayInfos->id;

            # Build the URL that could be used to play this logout request
            my $slo_url =
                $portal
              . '/saml/relaySingleLogoutSOAP?'
              . build_urlencoded( relay => $relayID );

            # Display information to the user
            $info .= $self->loadTemplate(
                $req,
                'samlSpSoapLogout',
                params => {
                    imgUrl => $slo_url,
                    name   => $providerName,
                }
            );
        }

        # Send the request directly
        else {

            $self->logger->debug("Send SOAP logout request to $providerID");

            my $slo_url  = $logout->msg_url;
            my $slo_body = $logout->msg_body;

            # Send SOAP request and manage response
            my $sp_response = $self->sendSOAPMessage( $slo_url, $slo_body );

            unless ($sp_response) {
                $self->logger->error("No logout response to SOAP request");
                return ( 0, $method, undef );
            }

            # Process logout response
            my $sp_result =
              $self->processLogoutResponseMsg( $logout, $sp_response );

            unless ($sp_result) {
                $self->logger->error("Fail to process logout response");
                return ( 0, $method, undef );
            }

            # Store success status for this SLO request
            my $sloStatusSessionInfos = $self->getSamlSession($relayState);

            if ($sloStatusSessionInfos) {
                $sloStatusSessionInfos->update( { $confKey => 1 } );
                $self->logger->debug(
                    "Store SLO status for $confKey in session $relayState");
            }
            else {
                $self->logger->warn(
"Unable to store SLO status for $confKey in session $relayState"
                );
            }

            $self->logger->debug("Logout response is valid");

        }

    }

    return ( 1, $method, $info );

}

## @pmethod int sendLogoutRequestToProviders(Lasso::Logout logout, string relayState )
# Send logout response issue from a logout request to all other
# providers. If information have to be displayed to users, such as
# iframe to send HTTP-Redirect or HTTP-POST logout request, then
# $self->{_info} will be updated.
# @param logout Lasso Logout object
# @param relayState Relay State for SLO status
# @return int Number of concerned providers.
sub sendLogoutRequestToProviders {
    my ( $self, $req, $logout, $relayState ) = @_;
    my $server         = $self->lassoServer;
    my $providersCount = 0;
    my $content        = '';

    # Reset providerID into Lasso::Logout object
    $self->resetProviderIdIndex($logout);

    # Foreach SP found in session, get it from configuration, and send the
    # appropriate logout request (HTTP,POST,SOAP).
    while ( my $providerID = $self->getNextProviderId($logout) ) {

        # Send logout request
        my ( $rstatus, $rmethod, $rinfo ) =
          $self->sendLogoutRequestToProvider( $req, $logout, $providerID,
            undef, 1, $relayState );

        next unless ($rstatus);

        # Count providers that have to be request by HTTP redirect
        $providersCount++;

        # Add information if necessary
        if ($rinfo) {
            $content .= $rinfo;
        }

    }

    # Print some information to the user.
    $req->info(
        $self->loadTemplate(
            $req, 'samlSpsLogout', params => { content => $content }
        )
    ) if $providersCount;

    return $providersCount;
}

## @method boolean checkSignatureStatus(Lasso::Profile profile)
# Check signature status
# @param profile Lasso::Profile object
# @return result
sub checkSignatureStatus {
    my ( $self, $profile ) = @_;

    eval { Lasso::Profile::get_signature_status($profile); };

    return $self->checkLassoError($@);
}

## @method int authnContext2authnLevel(string authnContext)
# Return authentication level corresponding to authnContext
# @param authnContext SAML authentication context
# return authentication level
sub authnContext2authnLevel {
    my ( $self, $authnContext ) = @_;

    return $self->conf->{samlAuthnContextMapPassword}
      if ( $authnContext eq $self->getAuthnContext("password") );
    return $self->conf->{samlAuthnContextMapPasswordProtectedTransport}
      if (
        $authnContext eq $self->getAuthnContext("password-protected-transport")
      );
    return $self->conf->{samlAuthnContextMapKerberos}
      if ( $authnContext eq $self->getAuthnContext("kerberos") );
    return $self->conf->{samlAuthnContextMapTLSClient}
      if ( $authnContext eq $self->getAuthnContext("tls-client") );
    return 0;

}

## @method int authnLevel2authnContext(int authnLevel)
# Return SAML authentication context corresponding to authnLevel
# @param authnLevel internal authentication level
# return SAML authentication context
sub authnLevel2authnContext {
    my ( $self, $authnLevel ) = @_;

    return $self->getAuthnContext("password")
      if ( $authnLevel == $self->conf->{samlAuthnContextMapPassword} );
    return $self->getAuthnContext("password-protected-transport")
      if ( $authnLevel ==
        $self->conf->{samlAuthnContextMapPasswordProtectedTransport} );
    return $self->getAuthnContext("kerberos")
      if ( $authnLevel == $self->conf->{samlAuthnContextMapKerberos} );
    return $self->getAuthnContext("tls-client")
      if ( $authnLevel == $self->conf->{samlAuthnContextMapTLSClient} );
    return $self->getAuthnContext("unspecified");

}

## @method boolean checkDestination(Lasso::Node message, string url)
# If SAML Destination attribute is present, check it
# @param message SAML request or response
# @param url Requested URL
# @return Result
sub checkDestination {
    my ( $self, $message, $url ) = @_;
    my $destination;

    # Read Destination
    eval { $destination = $message->Destination(); };

    # Ok if no Destination
    if ( $@ or !$destination ) {
        $self->logger->debug("No Destination in SAML message");
        return 1;
    }

    $self->logger->debug("Destination $destination found in SAML message");

    # Retrieve full URL
    my $portal = $self->conf->{portal};
    $portal =~ s#^(https?://[^/]+)/.*#$1#;    # remove path of portal URL
    $url = $portal . $url;
    $url =~ s/\?.*//;

    # Compare Destination and URL
    if ( $destination eq $url ) {
        $self->logger->debug("Destination match URL $url");
        return 1;
    }

    $self->logger->error("Destination does not match URL $url");
    return 0;
}

## @method hashref getSamlSession(string id)
# Try to recover the SAML session corresponding to id and return session
# If id is set to undef, return a new session
# @param id session reference
# @return Lemonldap::NG::Common::Session object
sub getSamlSession {
    my ( $self, $id, $info ) = @_;

    my $samlSession = Lemonldap::NG::Common::Session->new( {
            storageModule        => $self->aModule,
            storageModuleOptions => $self->amOpts,
            cacheModule          => $self->conf->{localSessionStorage},
            cacheModuleOptions   => $self->conf->{localSessionStorageOptions},
            id                   => $id,
            kind                 => $self->sessionKind,
            ( $info ? ( info => $info ) : () ),
        }
    );

    if ( $samlSession->error ) {
        if ($id) {
            $self->userLogger->warn("SAML session $id isn't yet available");
        }
        else {
            $self->logger->error("Unable to create new SAML session");
            $self->logger->error( $samlSession->error );
        }
        return undef;
    }

    return $samlSession;
}

## @method Lasso::Saml2Attribute createAttribute(string name, string format, string friendly_name)
# Create a new SAML attribute
# @param name Attribute name
# @param format optional Attribute format
# @param friendly_name optional Attribute friendly name
# @return SAML attribute
sub createAttribute {
    my ( $self, $name, $format, $friendly_name ) = @_;
    my $attribute;

    # Name is required
    return unless defined $name;

    # SAML2 attribute
    eval { $attribute = Lasso::Saml2Attribute->new(); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    # Default values
    $friendly_name ||= $name;
    $format ||= Lasso::Constants::SAML2_ATTRIBUTE_NAME_FORMAT_BASIC;

    # Set attribute properties
    $attribute->Name($name);
    $attribute->NameFormat($format);
    $attribute->FriendlyName($friendly_name);

    return $attribute;
}

## @method Lasso::Saml2AttributeValue createAttributeValue(string value, boolean force_utf8)
# Create a new SAML attribute value
# @param value Value to store
# @param force_utf8 set to 1 to decode UTF8 value
# @return SAML attribute value
sub createAttributeValue {
    my ( $self, $value, $force_utf8 ) = @_;
    my $saml2value;
    $force_utf8 = 1 unless defined($force_utf8);

    # Value is required
    return unless defined $value;

    # Decode UTF-8
    $self->logger->debug("Decode UTF8 value $value") if $force_utf8;
    $value = decode( "utf8", $value ) if $force_utf8;
    $self->logger->debug("Create attribute value $value");

    # SAML2 attribute value
    eval { $saml2value = Lasso::Saml2AttributeValue->new(); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    my @any;

    # Text node
    my $textNode;
    eval { $textNode = Lasso::MiscTextNode->new(); };
    if ($@) {
        $self->checkLassoError($@);
        return;
    }

    $textNode->text_child(1);
    $textNode->content($value);

    push @any, $textNode;

    $saml2value->any(@any);

    return $saml2value;
}

## @method int getEncryptionMode(string encryption_mode)
# Return Lasso encryption mode
# @param encryption_mode Encryption mode string
# @return Lasso encryption mode
sub getEncryptionMode {
    my ( $self, $encryption_mode ) = @_;

    return Lasso::Constants::ENCRYPTION_MODE_NAMEID
      if ( $encryption_mode =~ /^nameid$/i );
    return Lasso::Constants::ENCRYPTION_MODE_ASSERTION
      if ( $encryption_mode =~ /^assertion$/i );
    return Lasso::Constants::ENCRYPTION_MODE_NONE;
}

## @method boolean setProviderEncryptionMode(Lasso::Provider provider, int encryption_mode)
# Set encryption mode on a provider
# @param provider Lasso::Provider object
# @param encryption_mode Lasso encryption mode
# @return result
sub setProviderEncryptionMode {
    my ( $self, $provider, $encryption_mode ) = @_;

    eval {
        Lasso::Provider::set_encryption_mode( $provider, $encryption_mode );
    };

    return $self->checkLassoError($@);

}

## @method boolean deleteSAMLSecondarySessions(string session_id)
# Find and delete SAML sessions bounded to a primary session
# @param session_id Primary session ID
# @return result
sub deleteSAMLSecondarySessions {
    my ( $self, $session_id ) = @_;
    my $result = 1;

    # Find SAML sessions
    my $saml_sessions =
      Lemonldap::NG::Common::Apache::Session->searchOn( $self->amOpts,
        "_saml_id", $session_id );

    if (
        my @saml_sessions_keys =
        grep { $saml_sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$saml_sessions
      )
    {

        foreach my $saml_session (@saml_sessions_keys) {

            # Get session
            $self->logger->debug("Retrieve SAML session $saml_session");

            my $samlSessionInfo = $self->getSamlSession($saml_session);

            # Delete session
            if ( $samlSessionInfo->remove ) {
                $self->logger->debug("SAML session $saml_session deleted");
            }
            else {
                $self->logger->error(
                    "Unable to delete SAML session $saml_session");
                $self->logger->error( $samlSessionInfo->error );
                $result = 0;
            }
        }
    }
    elsif ($session_id) {
        $self->logger->debug("No SAML session found for session $session_id");
    }

    return $result;
}

## @method void sendSLOErrorResponse(Lasso::Logout logout, string method)
# Send an SLO error response
# @param logout Lasso::Logout object
# @param method HTTP method
sub sendSLOErrorResponse {
    my ( $self, $req, $logout, $method ) = @_;

    # Load empty session
    my $session =
      '<Session xmlns="http://www.entrouvert.org/namespaces/lasso/0.0"/>';

    unless ( $self->setSessionFromDump( $logout, $session ) ) {
        return $self->p->sendError( $req,
            "Could not set empty session in logout object", 500 );
    }

    # Send unvalidated SLO response
    return $self->sendLogoutResponseToServiceProvider( $req, $logout, $method );
}

## @method void sendSLOSoapErrorResponse(Lasso::Logout logout, string method)
# Send an SLO error response
# @param logout Lasso::Logout object
# @param method HTTP method
# @return PSGI response
sub sendSLOSoapErrorResponse {
    my ( $self, $req, $logout, $method ) = @_;

    # Load empty session
    my $session =
      '<Session xmlns="http://www.entrouvert.org/namespaces/lasso/0.0"/>';

    unless ( $self->setSessionFromDump( $logout, $session ) ) {
        return $self->p->sendError( $req,
            "Could not set empty session in logout object" );
    }
    my $slo_body = $logout->msg_body;
    $self->logger->debug("SOAP response $slo_body");
    return [
        200,
        [
            'Content-Type'   => 'application/xml',
            'Content-Length' => length($slo_body)
        ],
        [$slo_body]
    ];
}

## @method string getQueryString()
# Return query string with or without CGI query_string() method
# @return query string
sub getQueryString {
    my ( $self, $req ) = @_;

    my $query_string;

    if ( $self->conf->{samlUseQueryStringSpecific} ) {
        my @pairs =
          split( /&/, $req->param('issuerQuery') || $req->query_string );
        $query_string = join( ';', @pairs );

    }
    else {
        # TODO: verify this
        $query_string = $req->param('issuerQuery') || $req->query_string;
    }

    return $query_string;
}

sub importRealSession {
    my ( $self, $req, $ssoSession ) = @_;
    $req->sessionInfo( $ssoSession->data );
    $req->id( $ssoSession->id );
    $req->user( $ssoSession->data->{ $self->conf->{whatToTrace} } );
}

sub metadata {
    my ( $self, $req ) = @_;
    my $type = $req->param('type') || 'all';
    require Lemonldap::NG::Common::Conf::SAML::Metadata;
    if ( my $metadata = Lemonldap::NG::Common::Conf::SAML::Metadata->new() ) {
        my $s = $metadata->serviceToXML( $self->conf, $type );
        return [
            200,
            [
                'Content-Type'   => 'application/xml',
                'Content-Length' => length($s),
            ],
            [$s]
        ];
    }
    return $self->p->sendError( $req, 'Unable to build Metadata', 500 );
}

## @method int getSignatureMethod(string signature_method)
# Return Lasso signature method
# @param signature_method Signature method string
# @return Lasso signature method
sub getSignatureMethod {
    my ( $self, $signature_method ) = @_;

    my $signature_method_rsa_sha1 =
      eval 'Lasso::Constants::SIGNATURE_METHOD_RSA_SHA1';
    my $signature_method_rsa_sha256 =
      eval 'Lasso::Constants::SIGNATURE_METHOD_RSA_SHA256';
    my $signature_method_none = eval 'Lasso::Constants::SIGNATURE_METHOD_NONE';

    return $signature_method_rsa_sha1
      if ( $signature_method =~ /^RSA_SHA1$/i );
    return $signature_method_rsa_sha256
      if ( $signature_method =~ /^RSA_SHA256$/i );
    return $signature_method_none;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Lib::SAML - Common SAML functions

=head1 SYNOPSIS

use Lemonldap::NG::Portal::Lib::SAML;

=head1 DESCRIPTION

This module contains common methods for SAML authentication
and user information loading

=head1 METHODS

=head2 loadLasso

Load Lasso module

=head2 loadService

Load SAML service by creating a Lasso::Server

=head2 loadIDPs

Load SAML identity providers

=head2 loadSPs

Load SAML service providers

=head2 checkMessage

Check SAML requests and responses

=head2 checkLassoError

Log Lasso error code and message if this is actually a Lasso::Error with code > 0

=head2 createServer

Load service metadata and create Lasso::Server object

=head2 addIDP

Add IDP to an existing Lasso::Server

=head2 addSP

Add SP to an existing Lasso::Server

=head2 addAA

Add Attribute Authority to an existing Lasso::Server

=head2 addProvider

Add provider to an existing Lasso::Server

=head2 getOrganizationName

Return name of organization picked up from metadata

=head2 createAuthnRequest

Create authentication request for selected IDP

=head2 createLogin

Create Lasso::Login object

=head2 initAuthnRequest

Init authentication request

=head2 initIdpInitiatedAuthnRequest

Init authentication request for IDP initiated

=head2 buildAuthnRequestMsg

Build authentication request message

=head2 processAuthnRequestMsg

Process authentication request message

=head2 validateRequestMsg

Validate request message

=head2 buildAuthnResponseMsg

Build authentication response message

=head2 buildArtifactMsg

Build artifact message

=head2 buildAssertion

Build assertion

=head2 processAuthnResponseMsg

Process authentication response message

=head2 getNameIdentifier

Get NameID from Lasso Profile

=head2 createIdentity

Create Lasso::Identity object

=head2 createSession

Create Lasso::Session object

=head2 acceptSSO

Accept SSO from IDP

=head2 storeRelayState

Store information in relayState database and return

=head2 extractRelayState

Extract RelayState information into $self

=head2 getAssertion

Get assertion in Lasso::Login object

=head2 getAttributeValue

Get SAML attribute value corresponding to name, format and friendly_name
Multivaluated values are separated by ';'

=head2 validateConditions

Validate conditions

=head2 createLogoutRequest

Create logout request for selected entity

=head2 createLogout

Create Lasso::Logout object

=head2 initLogoutRequest

Init logout request

=head2 buildLogoutRequestMsg

Build logout request message

=head2 setSessionFromDump

Set session from dump in Lasso::Profile object

=head2 setIdentityFromDump

Set identity from dump in Lasso::Profile object

=head2 getMetaDataURL

Get URL stored in a service metadata configuration key

=head2 processLogoutResponseMsg

Process logout response message

=head2 processLogoutRequestMsg

Process logout request message

=head2 validateLogoutRequest

Validate logout request

=head2 buildLogoutResponseMsg

Build logout response msg

=head2 storeReplayProtection

Store ID of an SAML message in Replay Protection base

=head2 replayProtection

Check if SAML message do not correspond to a previously responded message

=head2 resolveArtifact

Resolve artifact to get the real SAML message

=head2 storeArtifact

Store artifact

=head2 loadArtifact

Load artifact

=head2 createArtifactResponse

Create artifact response

=head2 processArtRequestMsg

Process artifact response message

=head2 processArtResponseMsg

Process artifact response message

=head2 sendSOAPMessage

Send SOAP message and get response

=head2 createAssertionQuery

Create a new assertion query

=head2 createAttributeRequest

Create an attribute request

=head2 validateAttributeRequest

Validate an attribute request

=head2 processAttributeRequest

Process an attribute request

=head2 buildAttributeResponse

Build attribute response

=head2 processAttributeResponse

Process an attribute response

=head2 getNameIDFormat

Convert configuration string into SAML2 NameIDFormat string

=head2 getHttpMethod

Convert configuration string into Lasso HTTP Method integer

=head2 getHttpMethodString

Convert configuration Lasso HTTP Method integer into string

=head2 getFirstHttpMethod

Find a suitable HTTP method for an entity with a given protocol

=head2 disableSignature

Modify Lasso signature hint to disable signature

=head2 forceSignature

Modify Lasso signature hint to force signature

=head2 disableSignatureVerification

Modify Lasso signature hint to disable signature verification

=head2 forceSignatureVerification

Modify Lasso signature hint to force signature verification

=head2 getAuthnContext

Convert configuration string into SAML2 AuthnContextClassRef string

=head2 timestamp2samldate

Convert timestamp into SAML2 date format

=head2 samldate2timestamp

Convert SAML2 date format into timestamp

=head2 sendLogoutResponseToServiceProvider

Send logout response issue from a logout request

=head2 sendLogoutRequestToProvider

Send logout request to a provider

=head2 sendLogoutRequestToProviders

Send logout response issue from a logout request to all other
providers. If information have to be displayed to users, such as
iframe to send HTTP-Redirect or HTTP-POST logout request, then
$self->{_info} will be updated.

=head2 checkSignatureStatus

Check signature status

=head2 authnContext2authnLevel

Return authentication level corresponding to authnContext

=head2 authnLevel2authnContext

Return SAML authentication context corresponding to authnLevel

=head2 checkDestination

If SAML Destination attribute is present, check it

=head2 getSamlSession

Try to recover the SAML session corresponding to id and return session data

=head2 createAttribute

Create a new SAML attribute

=head2 createAttributeValue

Create a new SAML attribute value

=head2 getEncryptionMode

Return Lasso encryption mode

=head2 setProviderEncryptionMode

Set encryption mode on a provider

=head2 deleteSAMLSecondarySessions

Find and delete SAML sessions bounded to a primary session

=head2 sendSLOErrorResponse

Send an SLO error response

=head2 getQueryString

Get query string with or without CGI query_string() method

=head2 getSignatureMethod

Return Lasso signature method

=head1 SEE ALSO

L<Lemonldap::NG::Portal::Auth::SAML>, L<Lemonldap::NG::Portal::UserDBSAML>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
