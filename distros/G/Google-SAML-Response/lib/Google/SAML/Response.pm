#  Copyright (c) 2013 Manni Heumann. All rights reserved.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#

package Google::SAML::Response;

=head1 NAME

Google::SAML::Response - Generate signed XML documents as SAML responses for
Google's SSO implementation

=head1 VERSION

You are currently reading the documentation for version 0.15

=head1 DESCRIPTION

Google::SAML::Response can be used to generate a signed XML document that is
needed for logging your users into Google using SSO.

You have some sort of web application that can identify and authenticate users.
You want users to be able to use some sort of Google service such as Google mail.

When using SSO with your Google partner account, your users will send a request
to a Google URL. If the user isn't already logged in to Google, Google will
redirect him to a URL that you can define. Behind this URL, you need to have
a script that authenticates users in your original framework and generates a
SAML response for Google that you send back to the user whose browser will  then
submit it back to Google. If everything works, users will then be logged into
their Google account and they don't even have to know their usernames or
passwords.

=head1 SYNOPSIS

 use Google::SAML::Response;
 use CGI;

 # get SAMLRequest parameter:
 my $req = CGI->new->param('SAMLRequest');

 # authenticate user
 ...

 # find our user's login for Google
 ...

 # Generate SAML response
 my $saml = Google::SAML::Response->new( { 
                key     => $key, 
                login   => $login, 
                request => $req 
            } );
 my $xml  = $saml->get_response_xml;

 # Alternatively, send a HTML page to the client that will redirect
 # her to Google. You have to extract the RelayState param from the
 # cgi environment first.

 print $saml->get_google_form( $relayState );

=head1 PREREQUISITES

You will need the following modules installed:

=over

=item * L<Crypt::OpenSSL::RSA|Crypt::OpenSSL::RSA>

=item * L<Crypt::OpenSSL::Bignum|Crypt::OpenSSL::Bignum>

=item * L<XML::Canonical or XML::CanonicalizeXML|XML::Canonical or XML::CanonicalizeXML>

=item * L<Digest::SHA|Digest::SHA>

=item * L<Date::Format|Date::Format>

=item * L<Google::SAML::Request|Google::SAML::Request>

=back

=head1 RESOURCES

=over

=item XML-Signature Syntax and Processing

L<http://www.w3.org/TR/xmldsig-core/>

=item Google-Documentation on SSO and SAML

L<https://developers.google.com/google-apps/sso/saml_reference_implementation>

=item XML Security Library

L<http://www.aleksey.com/xmlsec/>

=back

=head1 METHODS

=cut

use strict;
use warnings;

use Crypt::OpenSSL::RSA;
use MIME::Base64;
use Digest::SHA qw/ sha1 /;
use Date::Format;
use Compress::Zlib;
use Google::SAML::Request;
use Carp;
use HTML::Entities;


our $VERSION = '0.15';

=head2 new

Creates a new object and needs to have all parameters needed to generate
the signed xml later on. Parameters are passed in as a hash-reference.

=head3 Required parameters

=over

=item * request

The SAML request, base64-encoded and all, just as retrieved from the GET
request your user contacted you with (make sure that it's not url-encoded, though)

=item * key

The path to your private key that will be used to sign the response. Currently,
only RSA and DSA keys without pass phrases are supported. B<NOTE>: To handle DSA keys,
the module L<Crypt::OpenSSL::DSA|Crypt::OpenSSL::DSA> needs to be installed. However,
it is not listed as a requirement in the Makefile for Google::SAML::Response, so make
sure it really is installed before using DSA keys.

=item * login

Your user's login name with Google

=back

=head3 Optional parameters

=over

=item * ttl

Time to live: Number of seconds your response should be valid. Default is two minutes.

=item * canonicalizer

The name of the module that will be used to canonicalize parts of our xml. Currently,
L<XML::Canonical|XML::Canonical> and L<XML::CanonicalizeXML|XML::CanonicalizeXML> are
supported. L<XML::CanonicalizeXML|XML::CanonicalizeXML> is the default.

=back

=cut


sub new {
    my $class  = shift;
    my $params = shift;

    my $self = bless {}, $class;

    foreach my $required ( qw/ request key login / ) {
        if ( exists $params->{ $required } ) {
            $self->{ $required } = $params->{ $required };
        }
        else {
            confess "You need to provide the $required parameter!";
        }
    }

    my $request = Google::SAML::Request->new_from_string( $self->{ request } );

    if ( $request && $self->_load_key ) {
        $self->{ service_url }   = $request->AssertionConsumerServiceURL;
        $self->{ request_id }    = $request->ID;
        $self->{ ttl }           = ( exists $params->{ ttl } ) ? $params->{ ttl } : 60*2;
        $self->{ canonicalizer } = exists $params->{ canonicalizer }
                                    ? $params->{ canonicalizer }
                                    : 'XML::CanonicalizeXML';

        return $self;
    }
    else {
        return;
    }
}


sub _load_dsa_key {
    my $self     = shift;
    my $key_text = shift;

    eval {
        require Crypt::OpenSSL::DSA;
    };

    confess 'Crypt::OpenSSL::DSA needs to be installed so that we can handle DSA keys.' if $@;

    my $dsa_key = Crypt::OpenSSL::DSA->read_priv_key_str( $key_text );

    if ( $dsa_key ) {
        $self->{ key_obj } = $dsa_key;
        my $g = encode_base64( $dsa_key->get_g, '' );
        my $p = encode_base64( $dsa_key->get_p, '' );
        my $q = encode_base64( $dsa_key->get_q, '' );
        my $y = encode_base64( $dsa_key->get_pub_key, '' );

        $self->{ KeyInfo }  = "<KeyInfo><KeyValue><DSAKeyValue><P>$p</P><Q>$q</Q><G>$g</G><Y>$y</Y></DSAKeyValue></KeyValue></KeyInfo>";
        $self->{ key_type } = 'dsa';
    }
    else {
        confess 'did not get a new Crypt::OpenSSL::RSA object';
    }
}


sub _load_rsa_key {
    my $self     = shift;
    my $key_text = shift;

    my $rsa_key = Crypt::OpenSSL::RSA->new_private_key( $key_text );

    if ( $rsa_key ) {
        $self->{ key_obj } = $rsa_key;

        my $big_num = ( $rsa_key->get_key_parameters )[ 1 ];
        my $bin = $big_num->to_bin;
        my $exp = encode_base64( $bin, '' );

        $big_num = ( $rsa_key->get_key_parameters )[ 0 ];
        $bin = $big_num->to_bin;
        my $mod = encode_base64( $bin, '' );
        $self->{ KeyInfo }  = "<KeyInfo><KeyValue><RSAKeyValue><Modulus>$mod</Modulus><Exponent>$exp</Exponent></RSAKeyValue></KeyValue></KeyInfo>";
        $self->{ key_type } = 'rsa';
    }
    else {
        confess 'did not get a new Crypt::OpenSSL::RSA object';
    }
}


sub _load_key {
    my $self = shift;

    my $file = $self->{ key };

    if ( open my $KEY, '<', $file ) {
        my $text = '';
        local $/ = undef;
        $text = <$KEY>;
        close $KEY;

        if ( $text =~ m/BEGIN ([DR]SA) PRIVATE KEY/ ) {
            my $key_used = $1;

            if ( $key_used eq 'RSA' ) {
                $self->_load_rsa_key( $text );
            }
            else {
                $self->_load_dsa_key( $text );
            }

            return 1;
        }
        else {
            confess "Could not detect type of key $file.";
        }
    }
    else {
        confess "Could not load key $file: $!";
    }

    return;
}


=head2 get_response_xml

Generate the signed response xml and return it as a string

The method does what the w3c tells us to do (L<http://www.w3.org/TR/xmldsig-core/#sec-CoreGeneration>):

=over

3.1.1 Reference Generation

For each data object being signed:

1. Apply the Transforms, as determined by the application, to the data object.

2. Calculate the digest value over the resulting data object.

3. Create a Reference element, including the (optional) identification of the data object, any (optional) transform elements, the digest algorithm and the DigestValue. (Note, it is the canonical form of these references that are signed in 3.1.2 and validated in 3.2.1 .)

3.1.2 Signature Generation

1. Create SignedInfo element with SignatureMethod, CanonicalizationMethod and Reference(s).

2. Canonicalize and then calculate the SignatureValue over SignedInfo based on algorithms specified in SignedInfo.

3. Construct the Signature element that includes SignedInfo, Object(s) (if desired, encoding may be different than that used for signing), KeyInfo (if required), and SignatureValue.

=back

=cut

sub get_response_xml {
    my $self = shift;

    # This is the xml response without any signatures or digests:
    my $xml           = $self->_response_xml;

    # We now calculate the SHA1 digest of the canoncial response xml
    my $canonical     = $self->_canonicalize_xml( $xml );

    my $bin_digest    = sha1( $canonical );
    my $digest        = encode_base64( $bin_digest, '' );

    # Create a xml fragment containing the digest:
    my $digest_xml    = $self->_reference_xml( $digest );

    # create a xml fragment consisting of the SignedInfo element
    my $signed_info   = $self->_signedinfo_xml( $digest_xml );

    # We now calculate a signature over the canonical SignedInfo element

    $canonical        = $self->_canonicalize_xml( $signed_info );
    my $signature;

    if ( $self->{ key_type } eq 'dsa' ) {
        my $sig = $self->{ key_obj }->do_sign( sha1( $canonical ) );
        $signature = encode_base64( $sig->get_r . $sig->get_s );
    }
    else {
        my $bin_signature = $self->{ key_obj }->sign( $canonical );
        $signature = encode_base64( $bin_signature, "\n" );
    }

    # With the signature value and the signedinfo element, we create
    # a Signature element:
    my $signature_xml = $self->_signature_xml( $signed_info, $signature );

    # Now insert the signature xml into our response xml
    $xml =~ s/<samlp:Status>/$signature_xml<samlp:Status>/;

    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" . $xml;
}


sub _signature_xml {
    my $self            = shift;
    my $signed_info     = shift;
    my $signature_value = shift;

    return qq|<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
        $signed_info
        <SignatureValue>$signature_value</SignatureValue>
        $self->{ KeyInfo }
    </Signature>|;
}


sub _signedinfo_xml {
    my $self       = shift;
    my $digest_xml = shift;

    return qq|<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments" />
                <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#$self->{ key_type }-sha1" />
                $digest_xml
            </SignedInfo>|;
}


sub _reference_xml {
    my $self   = shift;
    my $digest = shift;

    return qq|<Reference URI="">
                        <Transforms>
                            <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
                        </Transforms>
                        <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
                        <DigestValue>$digest</DigestValue>
                    </Reference>|;
}


sub _canonicalize_xml {
    my $self = shift;
    my $xml  = shift;

    if ( $self->{ canonicalizer } eq 'XML::Canonical' ) {
        require XML::Canonical;
        my $xmlcanon = XML::Canonical->new( comments => 1 );
        return $xmlcanon->canonicalize_string( $xml );
    }
    elsif ( $self->{ canonicalizer } eq 'XML::CanonicalizeXML' ) {
        require XML::CanonicalizeXML;
        my $xpath = '<XPath>(//. | //@* | //namespace::*)</XPath>';
        return XML::CanonicalizeXML::canonicalize( $xml, $xpath, [], 0, 0 );
    }
    else {
        confess 'Unknown XML canonicalizer module.';
    }
}


sub _response_xml {
    my $self = shift;

    # A 160-bit string containing a set of randomly generated characters.
    # The ID MUST start with a character
    my $response_id = sprintf 'GOSAML%0d%04d', time, rand( 10000 );

    # A timestamp indicating the date and time that the SAML response was generated
    # Bsp: 2006-08-17T10:05:29Z
    # All SAML time values have the type xs:dateTime, which is built in to the W3C XML Schema Datatypes
    # specification [Schema2], and MUST be expressed in UTC form, with no time zone component.
    my $issue_instant = time2str( "%Y-%m-%dT%XZ", time, 'UTC' );

    # A 160-bit string containing a set of randomly generated characters.
    my $assertion_id = sprintf 'GOSAML%010d%04d', time, rand( 10000 );

    # The acs url
    my $assertion_url = $self->{ service_url };

    # The username for the authenticated user.
    my $username      = $self->{ login };

    # A timestamp identifying the date and time after which the SAML response is deemed invalid.
    my $best_before   = time2str( '%Y-%m-%dT%XZ', time + $self->{ ttl }, 'UTC' );

    # A timestamp indicating the date and time that you authenticated the user.
    my $authn_instant = $issue_instant;

    my $request_id    = $self->{ request_id };

    return
        qq|<samlp:Response xmlns="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" ID="$response_id" IssueInstant="$issue_instant" Version="2.0">
        <samlp:Status>
           <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"></samlp:StatusCode>
        </samlp:Status>
        <Assertion ID="$assertion_id" IssueInstant="$issue_instant" Version="2.0">
           <Issuer>https://www.opensaml.org/IDP</Issuer>
           <Subject>
              <NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">$username</NameID>
              <SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
                 <SubjectConfirmationData
                    Recipient="$assertion_url"
                    NotOnOrAfter="$best_before"
                    InResponseTo="$request_id"
                 />
              </SubjectConfirmation>
           </Subject>
           <Conditions NotBefore="$issue_instant" NotOnOrAfter="$best_before">
             <AudienceRestriction>
               <Audience>$assertion_url</Audience>
             </AudienceRestriction>
           </Conditions>
           <AuthnStatement AuthnInstant="$authn_instant">
              <AuthnContext>
                 <AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</AuthnContextClassRef>
              </AuthnContext>
           </AuthnStatement>
        </Assertion>
    </samlp:Response>
|;
}


=head2 get_google_form

This function will give you a complete HTML page that you can send to clients
to have them redirected to Google. Note that former versions of this module
also included a Content-Type HTTP header. Fortunately, this is no longer the
case and you will have to send a "Content-Type: text/html" yourself using
whatever method your framework provides.

After all the hi-tec stuff Google wants us to do to parse their request and
generate a response, this is where it gets low-tec and messy. We are supposed
to give clients a html page that contains a hidden form that uses Javascript
to post that form to Google. Ugly, but it works. The form will contain a textarea
containing the response xml and a textarea containing the relay state.

Hence the only required argument: the RelayState parameter from the user's GET request

=cut

sub get_google_form {
    my $self = shift;
    my $rs   = shift;

    my $url    = $self->{ service_url };
    my $output = "<!DOCTYPE html>\n";
    $output .= "<html><head></head><body onload='javascript:document.acsForm.submit()'>\n";

    my $xml        = $self->get_response_xml;
    my $encoded_rs = encode_entities( $rs );

    $output .= qq|
        <div style="display: none;">
        <form name="acsForm" action="$url" method="post">
            <textarea name="SAMLResponse">$xml</textarea>
            <textarea name="RelayState">$encoded_rs</textarea>
            <input type="submit" value="Submit SAML Response" />
        </form>
        </div>
    |;

    $output .= "</body></html>\n";

    return $output;
}


1;

__END__

=head1 REMARKS

Coming up with a valid response for a SAML-request is quite tricky. The simplest
way to go is to use the xmlsec1 program distributed with the XML Security Library.
Google seems to use that program itself. However, I wanted to have a perlish way
of creating the response. Testing your computed response is best done
against xmlsec1: If your response is stored in the file test.xml, you can simply do:

 xmlsec1 --verify --store-references --store-signatures test.xml > debug.txt

This will give you a file debug.txt with lots of information, most importantly it
will give you the canonical xml versions of your response and the 'References'
element. If your canonical xml of these two elements isn't exactly like the one
in debug.txt, your response will not be valid.

This brings us to another issue: XML-canonicalization. There are currently two
modules on CPAN that promise to do the work for you:
L<XML::CanonicalizeXML|XML::CanonicalizeXML> and L<XML::Canonical|XML::Canonical>.
Both can be used with Google::SAML::Response, however the default is to use the former
because it is much easier to install. However, the latter's interface is much
cleaner and Perl-like than the interface of the former.

L<XML::Canonical|XML::Canonical> uses L<XML::GDOME|XML::GDOME> which has a
Makefile.PL that begs to be hacked because it insists on using the version
of gdome that was available when Makefile.PL was written (2003) and then it still doesn't
install without force. L<XML::CanonicalizeXML|XML::CanonicalizeXML> is much easier
to install, you just have to have the libxml development files installed so it will
compile.

=head1 TODO

=over

=item * Add support for encrypted keys

=back

=head1 SOURCE CODE

This module has a github repository:

  https://github.com/mannih/Google-SAML-Response/

=head1 AUTHOR

Manni Heumann (saml at lxxi dot org)

with the help of Jeremy Smith and Thiago Damasceno. Thank you!

=head1 LICENSE

Copyright (c) 2008-2025 Manni Heumann. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
