# NAME

Google::SAML::Response - Generate signed XML documents as SAML responses for
Google's SSO implementation

# VERSION

You are currently reading the documentation for version 0.15

# DESCRIPTION

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

# SYNOPSIS

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

# PREREQUISITES

You will need the following modules installed:

- [Crypt::OpenSSL::RSA](https://metacpan.org/pod/Crypt%3A%3AOpenSSL%3A%3ARSA)
- [Crypt::OpenSSL::Bignum](https://metacpan.org/pod/Crypt%3A%3AOpenSSL%3A%3ABignum)
- [XML::Canonical or XML::CanonicalizeXML](https://metacpan.org/pod/XML%3A%3ACanonical%20or%20XML%3A%3ACanonicalizeXML)
- [Digest::SHA](https://metacpan.org/pod/Digest%3A%3ASHA)
- [Date::Format](https://metacpan.org/pod/Date%3A%3AFormat)
- [Google::SAML::Request](https://metacpan.org/pod/Google%3A%3ASAML%3A%3ARequest)

# RESOURCES

- XML-Signature Syntax and Processing

    [http://www.w3.org/TR/xmldsig-core/](http://www.w3.org/TR/xmldsig-core/)

- Google-Documentation on SSO and SAML

    [https://developers.google.com/google-apps/sso/saml\_reference\_implementation](https://developers.google.com/google-apps/sso/saml_reference_implementation)

- XML Security Library

    [http://www.aleksey.com/xmlsec/](http://www.aleksey.com/xmlsec/)

# METHODS

## new

Creates a new object and needs to have all parameters needed to generate
the signed xml later on. Parameters are passed in as a hash-reference.

### Required parameters

- request

    The SAML request, base64-encoded and all, just as retrieved from the GET
    request your user contacted you with (make sure that it's not url-encoded, though)

- key

    The path to your private key that will be used to sign the response. Currently,
    only RSA and DSA keys without pass phrases are supported. **NOTE**: To handle DSA keys,
    the module [Crypt::OpenSSL::DSA](https://metacpan.org/pod/Crypt%3A%3AOpenSSL%3A%3ADSA) needs to be installed. However,
    it is not listed as a requirement in the Makefile for Google::SAML::Response, so make
    sure it really is installed before using DSA keys.

- login

    Your user's login name with Google

### Optional parameters

- ttl

    Time to live: Number of seconds your response should be valid. Default is two minutes.

- canonicalizer

    The name of the module that will be used to canonicalize parts of our xml. Currently,
    [XML::Canonical](https://metacpan.org/pod/XML%3A%3ACanonical) and [XML::CanonicalizeXML](https://metacpan.org/pod/XML%3A%3ACanonicalizeXML) are
    supported. [XML::CanonicalizeXML](https://metacpan.org/pod/XML%3A%3ACanonicalizeXML) is the default.

## get\_response\_xml

Generate the signed response xml and return it as a string

The method does what the w3c tells us to do ([http://www.w3.org/TR/xmldsig-core/#sec-CoreGeneration](http://www.w3.org/TR/xmldsig-core/#sec-CoreGeneration)):

> 3.1.1 Reference Generation
>
> For each data object being signed:
>
> 1\. Apply the Transforms, as determined by the application, to the data object.
>
> 2\. Calculate the digest value over the resulting data object.
>
> 3\. Create a Reference element, including the (optional) identification of the data object, any (optional) transform elements, the digest algorithm and the DigestValue. (Note, it is the canonical form of these references that are signed in 3.1.2 and validated in 3.2.1 .)
>
> 3.1.2 Signature Generation
>
> 1\. Create SignedInfo element with SignatureMethod, CanonicalizationMethod and Reference(s).
>
> 2\. Canonicalize and then calculate the SignatureValue over SignedInfo based on algorithms specified in SignedInfo.
>
> 3\. Construct the Signature element that includes SignedInfo, Object(s) (if desired, encoding may be different than that used for signing), KeyInfo (if required), and SignatureValue.

## get\_google\_form

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

# REMARKS

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
[XML::CanonicalizeXML](https://metacpan.org/pod/XML%3A%3ACanonicalizeXML) and [XML::Canonical](https://metacpan.org/pod/XML%3A%3ACanonical).
Both can be used with Google::SAML::Response, however the default is to use the former
because it is much easier to install. However, the latter's interface is much
cleaner and Perl-like than the interface of the former.

[XML::Canonical](https://metacpan.org/pod/XML%3A%3ACanonical) uses [XML::GDOME](https://metacpan.org/pod/XML%3A%3AGDOME) which has a
Makefile.PL that begs to be hacked because it insists on using the version
of gdome that was available when Makefile.PL was written (2003) and then it still doesn't
install without force. [XML::CanonicalizeXML](https://metacpan.org/pod/XML%3A%3ACanonicalizeXML) is much easier
to install, you just have to have the libxml development files installed so it will
compile.

# TODO

- Add support for encrypted keys

# SOURCE CODE

This module has a github repository:

    https://github.com/mannih/Google-SAML-Response/

# AUTHOR

Manni Heumann (saml at lxxi dot org)

with the help of Jeremy Smith and Thiago Damasceno. Thank you!

# LICENSE

Copyright (c) 2008-2025 Manni Heumann. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
