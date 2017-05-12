=pod

=head1 NAME

Shibboleth::SP - sample settings for a Shibboleth Service Provider with Apache2

=head1 DESCRIPTION

The Shibboleth System is a standards based software package for web single sign-on across or within organizational boundaries. It supports authorization and attribute exchange using the OASIS SAML protocol.

This document aims to describe how to set a B<service provider> with Apache2.

The good way to set a shibboleth service provider is to use HTTP and HTTPS for each VirtualHost.
You need to add all hostnames in the certificate with the X.509v3 subjectAltName extension.

You will find here how to use use only HTTP. This is B<LESS SECURE> but you don't need to change your certificates for each new application.

=head1 SYNOPSIS

We will use three virtualhost :

C<sp.univ.fr>: B<Service provider> with https access and X509 certificates
 used by the B<shibd daemon>.

C<www1.univ.fr>: jifty web application with fastcgi

C<www2.univ.fr>: other web application


=head2 Apache config

a virtualhost for a Jifty application with Apache2 and FastCgi.

For a Jifty application we only need to protect C</shibblogin> to catch shibboleth authentication.

    FastCgiServer /home/www/Uads/bin/jifty -initial-env JIFTY_COMMAND=fastcgi -processes 3
    <VirtualHost 160.160.160.57:80>
    ServerName www1.univ.fr
    
    .....
    
    # required for fastcgi
    <Location />
      AuthType shibboleth
      Require shibboleth
    </Location>
    
    # protected dir for www1 *applicationId*
    <Location /shibblogin>
      ShibRequestSetting applicationId www1
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>
    
    </VirtualHost>

=head2 Service provider

The B<shibd daemon> will set environnement variables for mod_shib.

Our service provider is "sp.univ.fr". It needs X509 certificates.

In shibboleth2.xml we define B<applicationId> an internal name and B<entityID> a public name.
B<entityID> looks like a web url but it doesn't need to be accessible.

=head3 shibboleth2.xml

    <RequestMapper type="Native">
        <RequestMap applicationId="default">
            <Host name="sp.univ.fr">
                <Path name="testshib" authType="shibboleth" requireSession="true"/>
            </Host>
  
             <Host name="www2.univ.fr" applicationId="www2" authType="shibboleth" requireSession="true"/>
             <Host name="www1.univ.fr" applicationId="www1" authType="shibboleth" requireSession="false"/>
  
        </RequestMap>
    </RequestMapper>
    
    .....
    <SessionInitiator type="Chaining" Location="/WAYF" id="WAYF" relayState="cookie" >
       <SessionInitiator type="SAML2" acsIndex="1" template="bindingTemplate.html"/>
       <SessionInitiator type="Shib1" acsIndex="5"/>
       <SessionInitiator type="WAYF" acsIndex="5" URL="http://www.univ.fr/simplewayf/"/>
    </SessionInitiator>
    .....
    
    <ApplicationDefaults id="default" policyId="default"
        entityID="https://sp.univ.fr/shibboleth"
        homeURL="https://sp.univ.fr"
        REMOTE_USER="eppn persistent-id targeted-id"
        signing="false" encryption="false"
        >
    
    .....
        <ApplicationOverride id="www2" entityID="http://www2.univ.fr/shibboleth" REMOTE_USER="eppn persistent-id targeted-id" signing="false" encryption="false" />
        <ApplicationOverride id="www1" entityID="http://www1.univ.fr/shibboleth" REMOTE_USER="eppn persistent-id targeted-id email" signing="false" encryption="false" />
  
    </ApplicationDefaults>

Note: B<REMOTE_USER> for C<www1> is override to ask C<email> attribute

=head3 attribute-map.xml

we will use the name B<eppn> instead of B<eduPersonPrincipalName>

    <Attribute name="urn:mace:dir:attribute-def:eduPersonPrincipalName" id="eppn">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
    </Attribute>
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.6" id="eppn">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
    </Attribute>


=head2 Federation Metadata


Each entityID can use our sp certificat. Location go back to our http application. Firefox sets a warning about changes from https to http.

define

  entityID="http://www1.univ.fr/shibboleth"
  ....
  <ds:X509SubjectName>CN=sp.univ.fr,OU=CRIUM,O=UNIVERSITE METZ,L=Metz,ST=fr,C=FR</ds:X509SubjectName>
  ....
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://www1.univ.fr/Shibboleth.sso/SLO/SOAP"/>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://www1.univ.fr/Shibboleth.sso/SLO/Redirect"/>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://www1.univ.fr/Shibboleth.sso/SLO/POST"/>
    <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="http://www1.univ.fr/Shibboleth.sso/SLO/Artifact"/>
    <md:ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://www1.univ.fr/Shibboleth.sso/NIM/SOAP"/>
    <md:ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://www1.univ.fr/Shibboleth.sso/NIM/Redirect"/>
    <md:ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://www1.univ.fr/Shibboleth.sso/NIM/POST"/>
    <md:ManageNameIDService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="http://www1.univ.fr/Shibboleth.sso/NIM/Artifact"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://www1.univ.fr/Shibboleth.sso/SAML2/POST" index="1"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST-SimpleSign" Location="http://www1.univ.fr/Shibboleth.sso/SAML2/POST-SimpleSign" index="2"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="http://www1.univ.fr/Shibboleth.sso/SAML2/Artifact" index="3"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:PAOS" Location="http://www1.univ.fr/Shibboleth.sso/SAML2/ECP" index="4"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:1.0:profiles:browser-post" Location="http://www1.univ.fr/Shibboleth.sso/SAML/POST" index="5"/>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:1.0:profiles:artifact-01" Location="http://www1.univ.fr/Shibboleth.sso/SAML/Artifact" index="6"/>
  ....

=head2 Identity provider

All B<Identity Provider> (idp) need to allow access, for each SP entityID, to required attributes in 
attribute-filter.xml

  ...
   <AttributeFilterPolicy id="groupeExemple1">
  
   <PolicyRequirementRule xsi:type="basic:OR">
      <basic:Rule xsi:type="basic:AttributeRequesterRegex" regex="https://.*\.univ\.fr/.*" />
      <basic:Rule xsi:type="basic:AttributeRequesterRegex" regex="http://.*\.univ\.fr/.*" />
      <basic:Rule xsi:type="basic:AttributeRequesterString" value="https://sp.univ.fr/shibboleth" />
      <basic:Rule xsi:type="basic:AttributeRequesterString" value="https://www.something.fr/workflow"/>
   </PolicyRequirementRule>
  
    <AttributeRule attributeID="displayName">
        <PermitValueRule xsi:type="basic:ANY"/>
    </AttributeRule>
  
    <AttributeRule attributeID="eduPersonPrincipalName">
        <PermitValueRule xsi:type="basic:ANY"/>
    </AttributeRule>
  
    <AttributeRule attributeID="mail">
        <PermitValueRule xsi:type="basic:ANY"/>
    </AttributeRule>
  
    <AttributeRule attributeID="eduPersonPrimaryAffiliation">
        <PermitValueRule xsi:type="basic:ANY"/>
    </AttributeRule>
  
  </AttributeFilterPolicy>
  ...

=head2 Simple WAYF

A simple B<Where Are Your From> with HTML::Mason

  <form method="post" action=""> 
      <select name="user_idp">
        <option value="" >Choose your organisation</option>
            <option value="urn:mace:cru.fr:fed:univ2.fr">University 2</option>
            <option value="https://idp.univ.fr/idp/shibboleth">University 1</option>
    </select>
  </form>
  
  <%args>
  $user_idp => ''
  </%args>
  
  <%init>
  use constant REDIRECT => 302;
  my %SHIB =  ( 'https://idp.univ.fr/idp/shibboleth' => 'https://idp.univ.fr/idp/profile/Shibboleth/SSO',
    'urn:mace:cru.fr:fed:univ2.fr' => 'https://idp.univ2.fr/idp/profile/Shibboleth/SSO' );
  if ($user_idp) {
    $r->headers_out->set("Location" => $SHIB{$user_idp}.'?'.$ENV{QUERY_STRING});
    $r->status(REDIRECT);
    return;
  };
  </%init>

In this example C<SHIB> keys look like Idp entityID.

The requests, with query string, are redirected to C<urn:mace:shibboleth:1.0:profiles:AuthnRequest> location.

=head1 LINKS

Understanding Shibboleth: L<https://spaces.internet2.edu/display/SHIB2/UnderstandingShibboleth>

Service Provider: L<https://spaces.internet2.edu/display/SHIB2/NativeSPApplication>

Single Logout: L<https://spaces.internet2.edu/display/SHIB2/SLOIssues>

=head1 AUTHOR

Yves Agostini

=cut

1;
