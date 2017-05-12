<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    entityID="<TMPL_VAR NAME="samlEntityID">">

  <IDPSSODescriptor
      WantAuthnRequestsSigned="<TMPL_VAR NAME="samlIDPSSODescriptorWantAuthnRequestsSigned">"
      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="samlServicePublicKeySig">
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="samlServicePublicKeyEnc">
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService
      isDefault="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactDefault">"
      index="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactIndex">"
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorArtifactResolutionServiceArtifactLocation">" />
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceSOAPBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceSOAPLocation">" />
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectLocation">"
      <TMPL_IF NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">"
      </TMPL_IF>/>
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostLocation">"
      <TMPL_IF NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlIDPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">"
      </TMPL_IF>/>
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
    <SingleSignOnService
      Binding="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceSOAPBinding">"
      Location="<TMPL_VAR NAME="samlIDPSSODescriptorSingleSignOnServiceSOAPLocation">" />
  </IDPSSODescriptor>

  <SPSSODescriptor
      AuthnRequestsSigned="<TMPL_VAR NAME="samlSPSSODescriptorAuthnRequestsSigned">"
      WantAssertionsSigned="<TMPL_VAR NAME="samlSPSSODescriptorWantAssertionsSigned">"
      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="samlServicePublicKeySig">
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="samlServicePublicKeyEnc">
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService
      isDefault="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactDefault">"
      index="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactIndex">"
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorArtifactResolutionServiceArtifactLocation">" />
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceSOAPBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceSOAPLocation">" />
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectLocation">"
      <TMPL_IF NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPRedirectResponseLocation">"
      </TMPL_IF>/>
    <SingleLogoutService
      Binding="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostBinding">"
      Location="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostLocation">"
      <TMPL_IF NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">
      ResponseLocation="<TMPL_VAR NAME="samlSPSSODescriptorSingleLogoutServiceHTTPPostResponseLocation">"
      </TMPL_IF>/>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
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
  </SPSSODescriptor>

  <AttributeAuthorityDescriptor
    protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="samlServicePublicKeySig">
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <TMPL_VAR NAME="samlServicePublicKeyEnc">
      </ds:KeyInfo>
    </KeyDescriptor>
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
  
  <Organization>
    <OrganizationName xml:lang="en"><TMPL_VAR NAME="samlOrganizationName"></OrganizationName>
    <OrganizationDisplayName xml:lang="en"><TMPL_VAR NAME="samlOrganizationDisplayName"></OrganizationDisplayName>
    <OrganizationURL xml:lang="en"><TMPL_VAR NAME="samlOrganizationURL"></OrganizationURL>
  </Organization>

</EntityDescriptor>
