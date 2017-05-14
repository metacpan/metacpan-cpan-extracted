## @file
# UserDB SAML module

## @class
# UserDB SAML module
package Lemonldap::NG::Portal::UserDBSAML;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_SAML;
use Encode;
our @ISA = qw(Lemonldap::NG::Portal::_SAML);

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Check if authentication module is SAML
# @return Lemonldap::NG::Portal error code
sub userDBInit {
    my $self = shift;
    if ( $self->get_module('auth') =~ /^SAML/ ) {
        return PE_OK;
    }
    else {
        $self->lmLog( "SAML user module require SAML authentication", 'error' );
        return PE_SAML_ERROR;
    }
}

## @apmethod int getUser()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub getUser {
    PE_OK;
}

## @apmethod int setSessionInfo()
# Get all required attributes
# @return Lemonldap::NG::Portal error code
sub setSessionInfo {
    my $self       = shift;
    my $idp        = $self->{_idp};
    my $idpConfKey = $self->{_idpConfKey};
    my $nameid     = $self->{_nameID};

    my $exportedAttr;

    # Force UTF-8
    my $force_utf8 =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsForceUTF8};

    # Get all required attributes, not already set
    # in setAuthSessionInfo()
    foreach (
        keys %{ $self->{samlIDPMetaDataExportedAttributes}->{$idpConfKey} } )
    {

        # Extract fields from exportedAttr value
        my ( $mandatory, $name, $format, $friendly_name ) =
          split( /;/,
            $self->{samlIDPMetaDataExportedAttributes}->{$idpConfKey}->{$_} );

        # Keep mandatory attributes not sent in authentication response
        if ( $mandatory and not defined $self->{sessionInfo}->{$_} ) {
            $exportedAttr->{$_} =
              $self->{samlIDPMetaDataExportedAttributes}->{$idpConfKey}->{$_};
            $self->lmLog( "Attribute $_ will be requested to $idpConfKey",
                'debug' );
        }
    }

    unless ( keys %$exportedAttr ) {
        $self->lmLog(
            "All mandatory attributes were present in authentication response",
            'debug'
        );
        return PE_OK;
    }

    # Save current Lasso::Server object, and get a new one
    my $current_server = $self->{_lassoServer};
    $self->loadService(1);
    my $server = $self->{_lassoServer};

    unless ($server) {
        $self->lmLog( "Unable to create service for attribute request",
            'error' );
        return PE_SAML_LOAD_SERVICE_ERROR;
    }

    $self->lmLog( "Service for attribute request created", 'debug' );

    # Add current IDP as Attribute Authority
    my $idp_metadata =
      $self->{samlIDPMetaDataXML}->{$idpConfKey}->{samlIDPMetaDataXML};

    if ( $self->{samlMetadataForceUTF8} ) {
        $idp_metadata = encode( "utf8", $idp_metadata );
    }

    # Add this IDP to Lasso::Server as AA
    unless ( $self->addAA( $server, $idp_metadata ) ) {
        $self->lmLog(
            "Fail to use IDP $idpConfKey Metadata as Attribute Authority",
            'error' );
        return PE_SAML_LOAD_IDP_ERROR;
    }

    # Build Attribute Request
    my $query =
      $self->createAttributeRequest( $server, $idp, $exportedAttr, $nameid );

    unless ($query) {
        $self->lmLog( "Unable to build attribute request for $idpConfKey",
            'error' );
        return PE_SAML_ATTR_ERROR;
    }

    # Use SOAP to send request and get response
    my $query_url  = $query->msg_url;
    my $query_body = $query->msg_body;

    # Send SOAP request and manage response
    my $response = $self->sendSOAPMessage( $query_url, $query_body );

    unless ($response) {
        $self->lmLog( "No attribute response to SOAP request", 'error' );
        return PE_SAML_ATTR_ERROR;
    }

    # Manage Attribute Response
    my $result = $self->processAttributeResponse( $server, $response );

    unless ($result) {
        $self->lmLog( "Fail to process attribute response", 'error' );
        return PE_SAML_ATTR_ERROR;
    }

    # Attributes in response
    my @response_attributes;
    eval {
        @response_attributes =
          $result->response()->Assertion()->AttributeStatement()->Attribute();
    };
    if ($@) {
        $self->lmLog( "No attributes defined in attribute response", 'error' );
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
            $self->lmLog(
"Attribute $_ is mandatory, but was not delivered by $idpConfKey",
                'error'
            );
            return PE_SAML_ATTR_ERROR;
        }

        $self->lmLog( "Get value $value for attribute $_", 'debug' );

        # Store value in sessionInfo
        $self->{sessionInfo}->{$_} = $value;
    }

    # Restore current Lasso::Server
    $self->{_lassoServer} = $current_server;

    return PE_OK;

}

## @apmethod int setGroups()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub setGroups {
    PE_OK;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::UserDBSAML - SAML User backend

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::UserDBSAML;

=head1 DESCRIPTION

Collect all required attributes trough SAML Attribute Requests

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::AuthSAML>, L<Lemonldap::NG::Portal::_SAML>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2009-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2009-2015 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2010 by Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

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
