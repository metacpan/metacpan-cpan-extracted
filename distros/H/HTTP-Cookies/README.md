# NAME

HTTP::Cookies - HTTP cookie jars

# VERSION

version 6.10

# SYNOPSIS

    use HTTP::Cookies;
    $cookie_jar = HTTP::Cookies->new(
      file => "$ENV{'HOME'}/lwp_cookies.dat",
      autosave => 1,
    );

    use LWP;
    my $browser = LWP::UserAgent->new;
    $browser->cookie_jar($cookie_jar);

Or for an empty and temporary cookie jar:

    use LWP;
    my $browser = LWP::UserAgent->new;
    $browser->cookie_jar( {} );

# DESCRIPTION

This class is for objects that represent a "cookie jar" -- that is, a
database of all the HTTP cookies that a given LWP::UserAgent object
knows about.

Cookies are a general mechanism which server side connections can use
to both store and retrieve information on the client side of the
connection.  For more information about cookies refer to
[Cookie Spec](http://curl.haxx.se/rfc/cookie_spec.html) and
[Cookie Central](http://www.cookiecentral.com).  This module also implements the
new style cookies described in [RFC 2965](https://tools.ietf.org/html/rfc2965).
The two variants of cookies are supposed to be able to coexist happily.

Instances of the class _HTTP::Cookies_ are able to store a collection
of Set-Cookie2: and Set-Cookie: headers and are able to use this
information to initialize Cookie-headers in _HTTP::Request_ objects.
The state of a _HTTP::Cookies_ object can be saved in and restored from
files.

# LIMITATIONS

This module does not support [Public Suffix](https://publicsuffix.org/) encouraged by a more recent standard, [RFC
6265](https://tools.ietf.org/html/rfc6265).

This module's shortcomings mean that a malicious Web site can set
cookies to track your user agent across all sites under a top level
domain.  See `t/publicsuffix.t` in this module's distribution for
details.

[HTTP::CookieJar::LWP](https://metacpan.org/pod/HTTP%3A%3ACookieJar%3A%3ALWP) supports Public Suffix, but only provides a
limited subset of this module's functionality and [does not
support](https://metacpan.org/pod/HTTP%3A%3ACookieJar#LIMITATIONS-AND-CAVEATS) standards older than
_RFC 6265_.

# METHODS

The following methods are provided:

- $cookie\_jar = HTTP::Cookies->new

    The constructor takes hash style parameters.  The following
    parameters are recognized:

        file:            name of the file to restore cookies from and save cookies to
        autosave:        save during destruction (bool)
        ignore_discard:  save even cookies that are requested to be discarded (bool)
        hide_cookie2:    do not add Cookie2 header to requests

    Future parameters might include (not yet implemented):

        max_cookies               300
        max_cookies_per_domain    20
        max_cookie_size           4096

        no_cookies   list of domain names that we never return cookies to

- $cookie\_jar->get\_cookies( $url\_or\_domain )
- $cookie\_jar->get\_cookies( $url\_or\_domain, $cookie\_key,... )

    Returns a hash of the cookies that applies to the given URL. If a
    domainname is given as argument, then a prefix of "https://" is assumed.

    If one or more $cookie\_key parameters are provided return the given values,
    or `undef` if the cookie isn't available.

- $cookie\_jar->add\_cookie\_header( $request )

    The add\_cookie\_header() method will set the appropriate Cookie:-header
    for the _HTTP::Request_ object given as argument.  The $request must
    have a valid url attribute before this method is called.

- $cookie\_jar->extract\_cookies( $response )

    The extract\_cookies() method will look for Set-Cookie: and
    Set-Cookie2: headers in the _HTTP::Response_ object passed as
    argument.  Any of these headers that are found are used to update
    the state of the $cookie\_jar.

- $cookie\_jar->set\_cookie( $version, $key, $val, $path, $domain, $port, $path\_spec, $secure, $maxage, $discard, \\%rest )

    The set\_cookie() method updates the state of the $cookie\_jar.  The
    $key, $val, $domain, $port and $path arguments are strings.  The
    $path\_spec, $secure, $discard arguments are boolean values. The $maxage
    value is a number indicating number of seconds that this cookie will
    live.  A value of $maxage <= 0 will delete this cookie.  The $version argument
    sets the version of the cookie; the default value is 0 ( original Netscape
    spec ).  Setting $version to another value indicates the RFC to which the
    cookie conforms (e.g. version 1 for RFC 2109).  %rest defines various other
    attributes like "Comment" and "CommentURL".

- $cookie\_jar->save
- $cookie\_jar->save( $file )
- $cookie\_jar->save( file => $file, ignore\_discard => $ignore\_discard )

    This method file saves the state of the $cookie\_jar to a file.
    The state can then be restored later using the load() method.  If a
    filename is not specified we will use the name specified during
    construction.  If the $ignore\_discard value is true (or not specified,
    but attribute _ignore\_discard_ was set at cookie jar construction),
    then we will even save cookies that are marked to be discarded.

    The default is to save a sequence of "Set-Cookie3" lines.
    "Set-Cookie3" is a proprietary LWP format, not known to be compatible
    with any browser.  The _HTTP::Cookies::Netscape_ sub-class can
    be used to save in a format compatible with Netscape.

- $cookie\_jar->load
- $cookie\_jar->load( $file )

    This method reads the cookies from the file and adds them to the
    $cookie\_jar.  The file must be in the format written by the save()
    method.

- $cookie\_jar->revert

    This method empties the $cookie\_jar and re-loads the $cookie\_jar
    from the last save file.

- $cookie\_jar->clear
- $cookie\_jar->clear( $domain )
- $cookie\_jar->clear( $domain, $path )
- $cookie\_jar->clear( $domain, $path, $key )

    Invoking this method without arguments will empty the whole
    $cookie\_jar.  If given a single argument only cookies belonging to
    that domain will be removed.  If given two arguments, cookies
    belonging to the specified path within that domain are removed.  If
    given three arguments, then the cookie with the specified key, path
    and domain is removed.

- $cookie\_jar->clear\_temporary\_cookies

    Discard all temporary cookies. Scans for all cookies in the jar
    with either no expire field or a true `discard` flag. To be
    called when the user agent shuts down according to RFC 2965.

- $cookie\_jar->scan( \\&callback )

    The argument is a subroutine that will be invoked for each cookie
    stored in the $cookie\_jar.  The subroutine will be invoked with
    the following arguments:

         0  version
         1  key
         2  val
         3  path
         4  domain
         5  port
         6  path_spec
         7  secure
         8  expires
         9  discard
        10  hash

- $cookie\_jar->as\_string
- $cookie\_jar->as\_string( $skip\_discardables )

    The as\_string() method will return the state of the $cookie\_jar
    represented as a sequence of "Set-Cookie3" header lines separated by
    "\\n".  If $skip\_discardables is TRUE, it will not return lines for
    cookies with the _Discard_ attribute.

# SEE ALSO

[HTTP::Cookies::Netscape](https://metacpan.org/pod/HTTP%3A%3ACookies%3A%3ANetscape), [HTTP::Cookies::Microsoft](https://metacpan.org/pod/HTTP%3A%3ACookies%3A%3AMicrosoft)

# AUTHOR

Gisle Aas <gisle@activestate.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
