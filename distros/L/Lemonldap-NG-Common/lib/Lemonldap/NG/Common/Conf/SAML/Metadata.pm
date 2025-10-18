##@file
# SAML Metadata object for Lemonldap::NG

##@class
# SAML Metadata object for Lemonldap::NG
package Lemonldap::NG::Common::Conf::SAML::Metadata;

use strict;
use Mouse;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use HTML::Template;
use MIME::Base64;
use Safe;
use Encode;

our $VERSION = '2.22.0';

my $dataStart = tell(DATA);

## @method public string serviceToXML
# Return all SAML parameters in well formated XML format, corresponding to
# SAML 2 description.
# Supported options:
# * portal: override the portal URL
# * signing_keys: override the list of signing keys
# * encryption_keys override the list of encryption keys
# @return string
sub serviceToXML {
    my ( $self, $conf, $type, %options ) = @_;

    my $portal =
      $options{portal} || $conf->{portal} || "http://auth.example.com/";
    $portal =~ s/\/$//;

    seek DATA, $dataStart, 0;
    my $s = join '', <DATA>;
    my $template = HTML::Template->new(
        scalarref         => \$s,
        die_on_bad_params => 0,
        cache             => 0,
    );

    # Automatic parameters
    my @param_auto = qw(
      samlEntityID
      samlOrganizationName
      samlOrganizationDisplayName
      samlOrganizationURL
    );

    if ( $type and $type eq 'idp' ) {
        $template->param( 'hideSPMetadata', 1 );
    }

    if ( $type and $type eq 'sp' ) {
        $template->param( 'hideIDPMetadata', 1 );
    }

    foreach (@param_auto) {
        $template->param( $_, $self->_replacePortal( $conf->{$_}, $portal ) );
    }

  # When asked to provide only IDP metadata, take into account EntityID override
    if ( $type eq "idp" and $conf->{samlOverrideIDPEntityID} ) {
        $template->param( 'samlEntityID', $conf->{samlOverrideIDPEntityID} );
    }

    # Boolean parameters
    my @param_boolean = qw(
      samlSPSSODescriptorAuthnRequestsSigned
      samlSPSSODescriptorWantAssertionsSigned
      samlIDPSSODescriptorWantAuthnRequestsSigned
    );

    foreach (@param_boolean) {
        $template->param( $_,
            $self->_replacePortal( $conf->{$_}, $portal ) ? 'true' : 'false' );
    }

    my $signing_keys =
      $options{signing_keys} || [ $conf->{samlServicePublicKeySig} ];
    my $encryption_keys = $options{encryption_keys}
      || (
        $conf->{samlServicePublicKeyEnc}
        ? [ $conf->{samlServicePublicKeyEnc} ]
        : $signing_keys
      );

    # Keys
    $template->param( "signing_keys",
        [ map { { keyInfo => $self->_getKeyInfoFromPem($_) } } @$signing_keys ]
    );
    $template->param(
        "encryption_keys",
        [
            map { { keyInfo => $self->_getKeyInfoFromPem($_) } }
              @$encryption_keys
        ]
    );

    # Rebuilded parameters for SAML services
    # A samlService value is formated like the following:
    # "binding;location;responseLocation"
    # The last value, responseLocation, is optional.
    my @param_service = qw(
      samlSPSSODescriptorSingleLogoutServiceHTTPRedirect
      samlSPSSODescriptorSingleLogoutServiceHTTPPost
      samlSPSSODescriptorSingleLogoutServiceSOAP
      samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect
      samlIDPSSODescriptorSingleSignOnServiceHTTPPost
      samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact
      samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect
      samlIDPSSODescriptorSingleLogoutServiceHTTPPost
      samlIDPSSODescriptorSingleLogoutServiceSOAP
      samlAttributeAuthorityDescriptorAttributeServiceSOAP
    );

    foreach (@param_service) {
        my @_tab = split( /;/, $self->_replacePortal( $conf->{$_}, $portal ) );
        $template->param( $_ . 'Binding',          $_tab[0] );
        $template->param( $_ . 'Location',         $_tab[1] );
        $template->param( $_ . 'ResponseLocation', $_tab[2] );
    }

    # Rebuilded parameters for SAML assertions
    # A samlAssertion value is formated like the following:
    # "default;index;binding;location"
    my @param_assertion = qw(
      samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact
      samlSPSSODescriptorAssertionConsumerServiceHTTPPost
      samlSPSSODescriptorArtifactResolutionServiceArtifact
      samlIDPSSODescriptorArtifactResolutionServiceArtifact
    );

    my %indexed_endpoints;
    foreach (@param_assertion) {
        my @_tab = split( /;/, $self->_replacePortal( $conf->{$_}, $portal ) );
        $indexed_endpoints{ $_ . 'Default' }  = ( $_tab[0] ? 'true' : 'false' );
        $indexed_endpoints{ $_ . 'Index' }    = $_tab[1];
        $indexed_endpoints{ $_ . 'Binding' }  = $_tab[2];
        $indexed_endpoints{ $_ . 'Location' } = $_tab[3];
    }
    $template->param(%indexed_endpoints);

    if (
        $indexed_endpoints{samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactDefault}
        eq 'true'
      )
    {
        $template->param( "ACSArtifactDefault" => 1 );
    }

    # Return the XML metadata.
    return $template->output;
}

sub _getKeyInfoFromPem {
    my ( $self, $val ) = @_;

    my $str;

    if ( defined $val and ref($val) eq "HASH" and exists $val->{public} ) {
        $val = $val->{public};
    }
    if ( defined $val && length $val gt 0 ) {

        # Public Key ?
        if ( $val =~ /^-----BEGIN PUBLIC KEY-----/
            and my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($val) )
        {
            my @params = $rsa_pub->get_key_parameters();
            my $mod    = encode_base64( $params[0]->to_bin() );
            my $exp    = encode_base64( $params[1]->to_bin() );
            $str =
                '<ds:KeyValue>' . "\n\t"
              . '<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">'
              . "\n\t\t"
              . '<Modulus>'
              . $mod
              . '</Modulus>'
              . "\n\t\t"
              . '<Exponent>'
              . $exp
              . '</Exponent>' . "\n\t"
              . '</RSAKeyValue>' . "\n"
              . '</ds:KeyValue>';
        }

        # Certificate ?
        if ( $val =~ /^-----BEGIN CERTIFICATE-----/
            and my $certificate = Crypt::OpenSSL::X509->new_from_string($val) )
        {
            $certificate = $certificate->as_string();
            $certificate =~ s/^-----BEGIN CERTIFICATE-----\n?//g;
            $certificate =~ s/\n?-----END CERTIFICATE-----$//g;
            $str =
                '<ds:X509Data>' . "\n\t"
              . '<ds:X509Certificate>' . "\n\t"
              . $certificate
              . '</ds:X509Certificate>' . "\n"
              . '</ds:X509Data>';
        }
    }
    return $str;
}

# DEPRECATED, remove in 3.0
# Get the value for a metadata configuration key
# Replace #PORTAL# macro
# @param key Configuration key
# @param conf Configuration hash ref
# @return value
sub getValue {
    my ( $self, $key, $conf ) = @_;

    # Get portal value
    my $portal = $conf->{portal} || "http://auth.example.com/";
    $portal =~ s/\/$//;

    return $self->_replacePortal( $conf->{$key}, $portal );
}

#@method string replacePortal(string key, hashref conf)
# Get the value for a metadata configuration key
# Replace #PORTAL# macro
# @param key Configuration key
# @param conf Configuration hash ref
# @return value
sub _replacePortal {
    my ( $self, $value, $portal ) = @_;
    return unless $value;

    # Replace #PORTAL# macro
    $value =~ s/#PORTAL#/$portal/g;

    # Return value
    return $value;
}

1;
__DATA__
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    entityID="<TMPL_VAR NAME="samlEntityID">">

  <TMPL_UNLESS NAME="hideIDPMetadata">
  <IDPSSODescriptor
      WantAuthnRequestsSigned="<TMPL_VAR NAME="samlIDPSSODescriptorWantAuthnRequestsSigned">"
      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <TMPL_LOOP name="signing_keys"><KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="keyInfo">
      </ds:KeyInfo>
    </KeyDescriptor></TMPL_LOOP>
    <TMPL_LOOP name="encryption_keys"><KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="keyInfo">
      </ds:KeyInfo>
    </KeyDescriptor></TMPL_LOOP>
    <ArtifactResolutionService
      isDefault="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactDefault">"
      index="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactIndex">"
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactLocation">" />
    <TMPL_IF NAME="samlIDPSSODescriptorSingleLogoutServiceSOAPLocation">
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceSOAPBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceSOAPLocation">" />
    </TMPL_IF>
    <TMPL_IF NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectLocation">"
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">" />
    </TMPL_IF>
    <TMPL_IF NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostLocation">"
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">" />
    </TMPL_IF>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPRedirectBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPRedirectLocation">"
      <TMPL_IF NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPRedirectResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPRedirectResponseLocation">"
      </TMPL_IF>/>
    <SingleSignOnService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPPostLocation">"
      <TMPL_IF NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPPostResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPPostResponseLocation">"
      </TMPL_IF>/>
    <SingleSignOnService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPArtifactBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPArtifactLocation">"
      <TMPL_IF NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPArtifactResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceHTTPArtifactResponseLocation">"
      </TMPL_IF>/>
  </IDPSSODescriptor>
  </TMPL_UNLESS>

  <TMPL_UNLESS NAME="hideSPMetadata">
  <SPSSODescriptor
      AuthnRequestsSigned="<TMPL_VAR NAME="samlSPSSODescriptorAuthnRequestsSigned">"
      WantAssertionsSigned="<TMPL_VAR NAME="samlSPSSODescriptorWantAssertionsSigned">"
      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <TMPL_LOOP name="signing_keys"><KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="keyInfo">
      </ds:KeyInfo>
    </KeyDescriptor></TMPL_LOOP>
    <TMPL_LOOP name="encryption_keys"><KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="keyInfo">
      </ds:KeyInfo>
    </KeyDescriptor></TMPL_LOOP>
    <ArtifactResolutionService
      isDefault="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactDefault">"
      index="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactIndex">"
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactLocation">" />
    <TMPL_IF NAME="samlSPSSODescriptorSingleLogoutServiceSOAPLocation">
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceSOAPBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceSOAPLocation">" />
    </TMPL_IF>
    <TMPL_IF NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectLocation">"
      ResponseLocation="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">" />
    </TMPL_IF>
    <TMPL_IF NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostLocation">"
      ResponseLocation="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">" />
    </TMPL_IF>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <TMPL_IF ACSArtifactDefault>
    <AssertionConsumerService
      isDefault="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactDefault">"
      index="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactIndex">"
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactLocation">" />
    <AssertionConsumerService
      isDefault="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostDefault">"
      index="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostIndex">"
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostLocation">" />
    <TMPL_ELSE>
    <AssertionConsumerService
      isDefault="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostDefault">"
      index="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostIndex">"
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPPostLocation">" />
    <AssertionConsumerService
      isDefault="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactDefault">"
      index="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactIndex">"
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorAssertionConsumerServiceHTTPArtifactLocation">" />
    </TMPL_IF>
  </SPSSODescriptor>
  </TMPL_UNLESS>

  <TMPL_UNLESS NAME="hideIDPMetadata">
  <AttributeAuthorityDescriptor
    protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <TMPL_LOOP name="signing_keys"><KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="keyInfo">
      </ds:KeyInfo>
    </KeyDescriptor></TMPL_LOOP>
    <TMPL_LOOP name="encryption_keys"><KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="keyInfo">
      </ds:KeyInfo>
    </KeyDescriptor></TMPL_LOOP>
    <AttributeService
      Binding="<TMPL_VAR NAME="samlAttributeAuthorityDescriptorAttributeServiceSOAPBinding">"
      Location="<TMPL_VAR NAME="samlAttributeAuthorityDescriptorAttributeServiceSOAPLocation">"/>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  </TMPL_UNLESS>

  <Organization>
    <OrganizationName xml:lang="en"><TMPL_VAR NAME="samlOrganizationName"></OrganizationName>
    <OrganizationDisplayName xml:lang="en"><TMPL_VAR NAME="samlOrganizationDisplayName"></OrganizationDisplayName>
    <OrganizationURL xml:lang="en"><TMPL_VAR NAME="samlOrganizationURL"></OrganizationURL>
  </Organization>
</EntityDescriptor>

