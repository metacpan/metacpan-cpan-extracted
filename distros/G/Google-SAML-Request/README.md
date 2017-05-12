# NAME

Google::SAML::Request - Create or parse Google's SAML requests

# VERSION

You are currently reading the documentation for version 0.05

# DESCRIPTION

Google::SAML::Request will parse (and, for the sake of completeness, create)
SAML requests as used by Google. __Please note__ that Google::SAML::Request is by
no means a full implementation of the SAML 2.0 standard. But if you want to
talk to Google to authenticate users, you should be fine.

In fact, if you want to talk to Google about SSO, just use
[Google::SAML::Response](https://metacpan.org/pod/Google::SAML::Response)
and you should be fine.

# SYNOPSIS

Create a new request object by taking the request ouf of the CGI environment:

    use Google::SAML::Request;
    my $req = Google::SAML::Request->new_from_cgi();
    if ( $req->ProviderName() eq 'google.com'
       && $req->AssertionConsumerServiceURL() eq 'https://www.google.com/hosted/psosamldemo.net/acs' ) {

       processRequest();
    }
    else {
        print "go talk to someone else\n";
    }

Or use a request string that you get from somewhere else (but make sure that it is no longer
URI-escaped):

    use Google::SAML::Request;
    my $req = Google::SAML::Request->new_from_string( $request_string );
    if ( $req->ProviderName() eq 'google.com'
       && $req->AssertionConsumerServiceURL() eq 'https://www.google.com/hosted/psosamldemo.net/acs' ) {

       processRequest();
    }
    else {
        print "go talk to someone else\n";
    }

Or, finally, create a request from scratch and send that to somebody else:

    use Google::SAML::Request;
    my $req = Google::SAML::Request->new(
               {
                   ProviderName => 'me.but.invalid',
                   AssertionConsumerServiceURL => 'http://send.your.users.here.invalid/script',
               }
              );

# PREREQUISITES

You will need the following modules installed:

- [MIME::Base64](https://metacpan.org/pod/MIME::Base64)
- [Compress::Zlib](https://metacpan.org/pod/Compress::Zlib)
- [Date::Format](https://metacpan.org/pod/Date::Format)
- [XML::Simple](https://metacpan.org/pod/XML::Simple)
- [URI::Escape](https://metacpan.org/pod/URI::Escape)
- [CGI](https://metacpan.org/pod/CGI) (if you are going to use the 'new\_from\_cgi' constructor)

# METHODS

## new

Create a new Google::SAML::Request object from scratch.

You have to provide the needed parameters here. Some parameters
are optional and defaults are used if they are not supplied.

The parameters need to be passed in in a hash reference as
key value pairs.

### Required parameters

- ProviderName

    Your name, e.g. 'google.com'

- AssertionConsumerServiceURL

    The URL the user used to contact you. E.g. 'https://www.google.com/hosted/psosamldemo.net/acs'

### Optional parameters

- IssueInstant

    The time stamp for the Request. Default is _now_.

- ID

    If you need to create the ID yourself, use this option. Otherwise the ID is
    generated from the current time and a pseudo-random number.

## new\_from\_cgi

Create a new Google::SAML::Request object by fishing it out of the CGI
environment.

If you provide a hash-ref with the key 'param\_name' you can determine
which cgi parameter to use. The default is 'SAMLRequest'.

## new\_from\_string

Pass in a (uri\_unescaped!) string that contains the request string. The string
will be base64-unencoded, inflated and parsed. You'll get back a fresh
Google::SAML::Response object if the string can be parsed.

## get\_xml

Returns the XML representation of the request.

## get\_get\_param

No, that's not a typo. This method will return the request in a form
suitable to be used as a GET parameter. In other words, this method
will take the XML representation, compress it, base64-encode the result
and, finally, URI-escape that.

### Accessor methods (read-only)

All of the following accessor methods return the value of the
attribute with the same name

## AssertionConsumerServiceURL

## ID

## IssueInstant

## ProtocolBinding

## ProviderName

## Version

# SOURCE CODE

This module has a repository on github. Pull requests are welcome.

    https://github.com/mannih/Google-SAML-Request/

# AUTHOR

Manni Heumann (saml at lxxi dot org)

# LICENSE

Copyright (c) 2008 Manni Heumann. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
