package Lemonldap::NG::Portal::UserDB::SAML;

use strict;
use Encode;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SAML_ATTR_ERROR
  PE_SAML_LOAD_IDP_ERROR
  PE_SAML_LOAD_SERVICE_ERROR
);

our $VERSION = '2.0.12';

extends qw(
  Lemonldap::NG::Common::Module
  Lemonldap::NG::Portal::Lib::SAML
);

# INITIALIZATION

sub init {
    my ($self) = @_;

    # SAML service has been already loaded
    $self->lassoServer(
        $self->p->loadedModules->{'Lemonldap::NG::Portal::Auth::SAML'}
          ->lassoServer );

    return 1;
}

# RUNNING METHODS

# Does nothing
sub getUser {
    return PE_OK;
}

sub findUser {
    return PE_OK;
}

# Get all required attributes
sub setSessionInfo {
    my ( $self, $req ) = @_;
    my $idp        = $req->data->{_idp};
    my $idpConfKey = $req->data->{_idpConfKey};
    my $nameid     = $req->data->{_nameID};

    my $exportedAttr;

    # Force UTF-8
    my $force_utf8 =
      $self->idpOptions->{$idpConfKey}->{samlIDPMetaDataOptionsForceUTF8}
      if $idpConfKey;

    # Get all required attributes, not already set
    # in setAuthSessionInfo()
    if ($idpConfKey) {
        foreach ( keys %{ $self->idpAttributes->{$idp} } ) {

            # Extract fields from exportedAttr value
            my ( $mandatory, $name, $format, $friendly_name ) =
              split( /;/, $self->idpAttributes->{$idp}->{$_} );

            # Keep mandatory attributes not sent in authentication response
            if ( $mandatory and not defined $req->{sessionInfo}->{$_} ) {
                $exportedAttr->{$_} =
                  $self->idpAttributes->{$idp}->{$_};
                $self->logger->debug(
                    "Attribute $_ will be requested to $idpConfKey");
            }
        }
    }

    unless ( keys %$exportedAttr ) {
        $self->logger->debug(
            "All mandatory attributes were present in authentication response");
        return PE_OK;
    }

    # Save current Lasso::Server object, and get a new one
    my $current_server = $self->lassoServer;
    $self->loadService(1);
    my $server = $self->lassoServer;

    unless ($server) {
        $self->logger->error('Unable to create service for attribute request');
        return PE_SAML_LOAD_SERVICE_ERROR;
    }

    $self->logger->debug("Service for attribute request created");

    # Add current IDP as Attribute Authority
    my $idp_metadata =
      $self->conf->{samlIDPMetaDataXML}->{$idpConfKey}->{samlIDPMetaDataXML};

    if ( $self->conf->{samlMetadataForceUTF8} ) {
        $idp_metadata = encode( "utf8", $idp_metadata );
    }

    # Add this IDP to Lasso::Server as AA
    unless ( $self->addAA( $server, $idp_metadata ) ) {
        $self->logger->error(
            "Fail to use IDP $idpConfKey Metadata as Attribute Authority");
        return PE_SAML_LOAD_IDP_ERROR;
    }

    # Build Attribute Request
    my $query =
      $self->createAttributeRequest( $server, $idp, $exportedAttr, $nameid );

    unless ($query) {
        $self->logger->error(
            "Unable to build attribute request for $idpConfKey");
        return PE_SAML_ATTR_ERROR;
    }

    # Use SOAP to send request and get response
    my $query_url  = $query->msg_url;
    my $query_body = $query->msg_body;

    # Send SOAP request and manage response
    my $response = $self->sendSOAPMessage( $query_url, $query_body );

    unless ($response) {
        $self->logger->error("No attribute response to SOAP request");
        return PE_SAML_ATTR_ERROR;
    }

    # Manage Attribute Response
    my $result = $self->processAttributeResponse( $server, $response );

    unless ($result) {
        $self->logger->error("Fail to process attribute response");
        return PE_SAML_ATTR_ERROR;
    }

    # Attributes in response
    my @response_attributes;
    eval {
        @response_attributes =
          $result->response()->Assertion()->AttributeStatement()->Attribute();
    };
    if ($@) {
        $self->logger->error("No attributes defined in attribute response");
        return PE_SAML_ATTR_ERROR;
    }

    # Check we have all required attributes
    foreach ( keys %$exportedAttr ) {

        # Extract fields from exportedAttr value
        my ( $mandatory, $name, $format, $friendly_name ) =
          split( /;/, $exportedAttr->{$_} );

        # Try to get value
        my $value = $self->getAttributeValue( $name, $format, $friendly_name,
            \@response_attributes, $force_utf8 );

        unless ($value) {
            $self->logger->error(
"Attribute $_ is mandatory, but was not delivered by $idpConfKey"
            );
            return PE_SAML_ATTR_ERROR;
        }

        $self->logger->debug("Get value $value for attribute $_");

        # Store value in sessionInfo
        $req->{sessionInfo}->{$_} = $value;
    }

    # Restore current Lasso::Server
    $self->lassoServer = $current_server;

    return PE_OK;
}

# Does nothing
sub setGroups {
    return PE_OK;
}

1;
