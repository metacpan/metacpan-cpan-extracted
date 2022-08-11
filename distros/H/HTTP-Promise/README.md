SYNOPSIS
========

        use HTTP::Promise;
        my $p = HTTP::Promise->new(
            agent => 'MyBot/1.0'
            accept_language => [qw( fr-FR fr en-GB en ja-JP )],
            auto_switch_https => 1,
            # For example, and Cookie::Jar object
            cookie_jar => $cookie_jar,
            dnt => 1,
            # 2Mb. Any data to be sent being bigger than this will trigger a Continue conditional query
            expect_threshold => 2048000,
            # Have the file extension reflect the encoding, if any
            ext_vary => 1,
            # 100Kb. Anything bigger than this will be automatically saved on file rather than memory
            max_body_in_memory_size => 102400,
            # 8Kb
            max_headers_size => 8192,
            max_redirect => 3,
            proxy => 'https://proxy.example.org:8080',
            # Can also be cbor or storable
            serialiser => 'sereal',
            # You can also use decimals with Time::HiRes
            timeout => 15,
            # force the use of files to store the response content
            use_content_file => 1,
            # The serialiser to use for the promise in Promise::Me
            # Defaults to storable, but can also be cbor and sereal
            serialiser => 'sereal',
        );
        my $prom = $p->get( 'https://www.example.org', $hash_of_query_params )->then(sub
        {
            my $resp = shift( @_ ); # get the HTTP::Promise::Response object
        })->catch(sub
        {
            my $ex = shift( @_ ); # get a HTTP::Promise::Exception object
            say "Exception code is: ", $ex->code;
        });
        # or using hash reference of options to prepare the request
        my $req = HTTP::Promise::Request->new( get => 'https://www.example.org' ) ||
            die( HTTP::Promise::Request->error );
        my $prom = $p->request( $req )->then(sub{ #... })->catch(sub{ # ... });

VERSION
=======

        v0.1.4

DESCRIPTION
===========

[HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module}
provides with a fast and powerful yet memory-friendly API to make true
asynchronous HTTP requests using fork using
[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}.

It is based on the design of
[HTTP::Message](https://metacpan.org/pod/HTTP::Message){.perl-module},
but with a much cleaner interface to make requests and manage HTTP
entity bodies.

Here are the key features:

-   Support for HTTP/1.0 and HTTP/1.1
-   Handles gracefully very large files by reading and sending them in
    chunks.
-   Supports `Continue` conditional requests
-   Support redirects
-   Reads data in chunks of bytes and not line by line.
-   Easy-to-use interface to encode and decode with
    [HTTP::Promise::Stream](https://metacpan.org/pod/HTTP::Promise::Stream){.perl-module}
-   Multi-lingual and complete HTTP Status codes with
    [HTTP::Promise::Status](https://metacpan.org/pod/HTTP::Promise::Status){.perl-module}
-   MIME guessing module with
    [HTTP::Promise::MIME](https://metacpan.org/pod/HTTP::Promise::MIME){.perl-module}
-   Powerful HTTP parser with
    [HTTP::Promise::Parser](https://metacpan.org/pod/HTTP::Promise::Parser){.perl-module}
    supporting complex `multipart` HTTP messages.
-   Has thorough documentation

Here is how it is organised in overall:

        +-------------------------+    +--------------------------+    
        |                         |    |                          |    
        | HTTP::Promise::Request  |    | HTTP::Promise::Response  |    
        |                         |    |                          |    
        +------------|------------+    +-------------|------------+    
                     |                               |                 
                     |                               |                 
                     |                               |                 
                     |  +------------------------+   |                 
                     |  |                        |   |                 
                     +--- HTTP::Promise::Message |---+                 
                        |                        |                     
                        +------------|-----------+                     
                                     |                                 
                                     |                                 
                        +------------|-----------+                     
                        |                        |                     
                        | HTTP::Promise::Entity  |                     
                        |                        |                     
                        +------------|-----------+                     
                                     |                                 
                                     |                                 
                        +------------|-----------+                     
                        |                        |                     
                        | HTTP::Promise::Body    |                     
                        |                        |                     
                        +------------------------+                     

It differentiates from other modules by using several XS modules for
speed, and has a notion of HTTP
[entity](https://metacpan.org/pod/HTTP::Promise::Entity){.perl-module}
and [body](https://metacpan.org/pod/HTTP::Promise::Body){.perl-module}
stored either on file or in memory.

It also have modules to make it really super easy to create
`x-www-form-urlencoded` requests with
[HTTP::Promise::Body::Form](https://metacpan.org/pod/HTTP::Promise::Body::Form){.perl-module},
or `multipart` ones with
[HTTP::Promise::Body::Form::Data](https://metacpan.org/pod/HTTP::Promise::Body::Form::Data){.perl-module}

Thus, you can either have a fine granularity by creating your own
request using
[HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module},
or you can use the high level methods provided by
[HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module},
which are: [\"delete\"](#delete){.perl-module},
[\"get\"](#get){.perl-module}, [\"head\"](#head){.perl-module},
[\"options\"](#options){.perl-module},
[\"patch\"](#patch){.perl-module}, [\"post\"](#post){.perl-module},
[\"put\"](#put){.perl-module} and each will occur asynchronously.

Each of those method returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which
means you can chain the results using a chainable
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module} for
errors.

You can also wait for all of them to finish using
[await](https://metacpan.org/pod/Promise::Me#await){.perl-module}, which
is exported by default by
[HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module}
and [all](https://metacpan.org/pod/Promise::Me#all){.perl-module} or
[race](https://metacpan.org/pod/Promise::Me#|race){.perl-module}.

        my @results = await( $p1, $p2 );
        my @results = HTTP::Promise->all( $p1, $p2 );
        # First promise that is resolved or rejected makes this super promise resolved and
        # return the result
        my @results = HTTP::Promise->race( $p1, $p2 );

You can also share variables using `share`, such as:

        my $data : shared = {};
        # or
        my( $name, @first_names, %preferences );
        share( $name, @first_names, %preferences );

See [Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}
for more information.

It calls
[resolve](https://metacpan.org/pod/Promise::Me#resolve){.perl-module}
when the request has been completed and sends a
[HTTP::Promise::Response](https://metacpan.org/pod/HTTP::Promise::Response){.perl-module}
object whose API is similar to that of
[HTTP::Response](https://metacpan.org/pod/HTTP::Response){.perl-module}.

When an error occurs, it is caught and sent by calling [\"reject\" in
Promise::XS](https://metacpan.org/pod/Promise::XS#reject){.perl-module}
with an
[HTTP::Promise::Exception](https://metacpan.org/pod/HTTP::Promise::Exception){.perl-module}
object.

Cookies are automatically and transparently managed with
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module} which
can load and store cookies to a json file you specify. You can create a
[cookie object](https://metacpan.org/pod/Cookie::Jar){.perl-module} and
pass it to the constructor with the `cookie_jar` option.

CONSTRUCTOR
===========

new
---

Provided with some optional parameters, and this instantiate a new
[HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module}
objects and returns it. If an error occurred, it will return `undef` and
the error can be retrieved using
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
method.

It accepts the following parameters. Each of those options have a
corresponding method, so you can get or change its value later:

-   `agent`

    String. Set the user agent, i.e. the way this interface identifies
    itself when communicating with an HTTP server. By default, it uses
    something like `HTTP-Promise/v0.1.0`

-   `cookie_jar`

    Object. Set the class handling the cookie jar. By default it uses
    [Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module}

-   `default_headers`

    [HTTP::Promise::Headers](https://metacpan.org/pod/HTTP::Promise::Headers){.perl-module},
    or
    [HTTP::Headers](https://metacpan.org/pod/HTTP::Headers){.perl-module}
    Object. Sets the headers object containing the default headers to
    use.

-   `local_address`

    String. An IP address or local host name to use when establishing
    TCP/IP connections.

-   `max_redirect`

    Integer. This is the maximum number of redirect
    [HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module}
    will follow until it gives up. Default value is `7`

-   `max_size`

    Integer. Set the size limit for response content. If the response
    content exceeds the value set here, the request will be aborted and
    a `Client-Aborted` header will be added to the response object
    returned. Default value is `undef`, i.e. no limit.

    See also the `threshold` option.

-   `no_proxy`

    Array reference. Do not proxy requests to the given domains.

-   `proxy`

    The url of the proxy to use for the HTTP requests.

-   `requests_redirectable`

    Array reference. This sets the list of http methods that are allowed
    to be redirected. Default to empty, which means that all methods can
    be redirected.

-   `serialiser`

    String. Specify the serialiser to use for
    [Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}.
    Possible values are:
    [cbor](https://metacpan.org/pod/CBOR::XS){.perl-module},
    [sereal](https://metacpan.org/pod/Sereal){.perl-module} or
    [storable](https://metacpan.org/pod/Storable::Improved){.perl-module}

    By default it uses the value set in the global variable
    `$SERIALISER`, which is a copy of the `$SERIALISER` in
    [Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module},
    which should be by default `storable`

-   `ssl_opts`

    Hash reference. Sets an hash reference of ssl options. The default
    values are set as follows:

    1\. `verify_hostname`

    :   When enabled, this ensures it connects to servers that have a
        valid certificate matching the expected hostname.

        1.1. If environment variable `PERL_LWP_SSL_VERIFY_HOSTNAME` is set, the ssl option property `verify_hostname` takes its value.

        :   

        1.2. If environment variable `HTTPS_CA_FILE` or `HTTPS_CA_DIR` are set to a true value, then the ssl option property `verify_hostname` is set to `0` and option property `SSL_verify_mode` is set to `1`

        :   

        1.3 If none of the above applies, it defaults `verify_hostname` to `1`

        :   

    2\. `SSL_ca_file`

    :   This is the path to a file containing the Certificate Authority
        certificates.

        If environment variable `PERL_LWP_SSL_CA_FILE` or
        `HTTPS_CA_FILE` is set, then the ssl option property
        `SSL_ca_file` takes its value.

    3\. `SSL_ca_path`

    :   This is the path to a directory of files containing Certificate
        Authority certificates.

        If environment variable `PERL_LWP_SSL_CA_PATH` or `HTTPS_CA_DIR`
        is set, then the ssl option property `SSL_ca_path` takes its
        value.

    Other options can be set and are processed directly by the SSL
    Socket implementation in use. See
    [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL){.perl-module}
    or [Net::SSL](https://metacpan.org/pod/Net::SSL){.perl-module} for
    details.

-   `threshold`

    Integer. Sets the content length threshold beyond which, the
    response content will be stored to a locale file. It can then be
    fetch with [\"file\"](#file){.perl-module}. Default to global
    variable `$CONTENT_SIZE_THRESHOLD`, which is `undef` by default.

    See also the `max_size` option.

-   `timeout`

    Integer. Sets the timeout value. Defaults to 180 seconds, i.e. 3
    minutes.

-   `use_content_file`

    Boolean. Enables the use of a temporary local file to store the
    response content, no matter the size o the response content.

METHODS
=======

The following methods are available. You can also access the same
methods implemented in
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent){.perl-module}
even if they are not listed here.

accept\_language
----------------

An array of acceptable language. This will be used to set the
`Accept-Language` header.

See also
[HTTP::Promise::Header::AcceptLanguage](https://metacpan.org/pod/HTTP::Promise::Header::AcceptLanguage){.perl-module}

agent
-----

This is a string.

Sets or gets the agent id used to identify when making the server
connection.

It defaults to `HTTP-Promise/v0.1.0`

        my $p = HTTP::Promise->new( agent => 'MyBot/1.0' );
        $p->agent( 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:99.0) Gecko/20100101 Firefox/99.0' );

The `User-Agent` header field is only set to this provided value if it
is not already set.

accept\_language
----------------

Sets or gets an array of acceptable response content languages.

For example:

        $http->accept_language( [qw( fr-FR ja-JP en-GB en )] );

Would result into an `Accept-Language` header set to
`fr-FR;q=0.9,ja-JP;q=0.8,en-GB;q=0.7,en;q=0.6`

The `Accept-Language` header would only be set if it is not set already.

auto\_switch\_https
-------------------

Boolean. If set to a true value, or if left to `undef` (default value),
this will set the `Upgrade-Insecure-Requests` header field to `1`

buffer\_size
------------

The size of the buffer to use when reading data from the filehandle or
socket.

connection\_header
------------------

Sets or gets the value for the header `Connection`. It can be `close` or
`keep-alive`

If it is let `undef`, this module will try to guess the proper value
based on the [\"protocol\" in
HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request#protocol){.perl-module}
and [\"version\" in
HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request#version){.perl-module}
used.

For protocol `HTTP/1.0`, `Connection` value would be `close`, but above
`HTTP/1.1` the connection can be set to `keep-alive` and thus be
re-used.

cookie\_jar
-----------

Sets or gets the Cookie jar class object to use. This is typically
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module} or
maybe
[HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies){.perl-module}

This defaults to
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module}

        use Cookie::Jar;
        my $jar = Cookie::Jar->new;
        my $p = HTTP::Promise->new( cookie_jar => $jar );
        $p->cookie_jar( $jar );

```{=pod::coverage}
decodable
```
decodable
---------

This calls [\"decodable\" in
HTTP::Promise::Stream](https://metacpan.org/pod/HTTP::Promise::Stream#decodable){.perl-module}
passing it whatever arguments that were provided.

default\_header
---------------

Sets one more default headers. This is a shortcut to
`$p->default_headers->header`

        $p->default_header( $field );
        $p->default_header( $field => $value );
        $p->default_header( 'Accept-Encoding' => scalar( HTTP::Promise->decodable ) );
        $p->default_header( 'Accept-Language' => 'fr, en, ja' );

default\_headers
----------------

Sets or gets the [default header
object](https://metacpan.org/pod/HTTP::Promise::Headers){.perl-module},
which is set to `undef` by default.

This can be either an
[HTTP::Promise::Headers](https://metacpan.org/pod/HTTP::Promise::Headers){.perl-module}
or [HTTP::Headers](https://metacpan.org/pod/HTTP::Headers){.perl-module}
object.

        use HTTP::Promise::Headers;
        my $headers = HTTP::Promise::Headers->new(
            'Accept-Encoding' => scalar( HTTP::Promise->decodable ),
            'Accept-Language' => 'fr, en, ja',
        );
        my $p = HTTP::Promise->new( default_headers => $headers );

default\_protocol
-----------------

Sets or gets the default protocol to use. For example: `HTTP/1.1`

delete
------

Provided with an `uri` and an optional hash of header name/value pairs,
and this will issue a `DELETE` http request to the given `uri`.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->delete( $uri, $field1 => $value1, $field2 => $value2 )
        $p->delete( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

dnt
---

Boolean. If set to a true value, this will set the `DNT` header to `1`

expect\_threshold
-----------------

Sets or gets the body size threshold beyond which, this module will
issue a conditional `Expect` HTTP header in order to ensure the remote
HTTP server is ok.

ext\_vary
---------

Boolean. When this is set to a true value, this will have the files use
extensions that reflect not just their content, but also their encoding
when applicable.

For example, if an HTTP response HTML content is gzip encoded into a
file, the file extensions will be `html.gz`

Default set to `$EXTENSION_VARY`, which by default is true.

file
----

If a temporary file has been set, the response content file can be
retrieved with this method.

        my $p = HTTP::Promise->new( threshold => 512000 ); # 500kb
        # If the response payload exceeds 500kb, HTTP::Promise will save the content to a 
        # temporary file
        # or
        my $p = HTTP::Promise->new( use_content_file => 1 ); # always use a temporary file
        # Returns a Module::Generic::File object
        my $f = $p->file;

from
----

\"the email address for the human user who controls the requesting user
agent. The address should be machine-usable, as defined in
[RFC2822](https://tools.ietf.org/html/rfc2822){.perl-module}. The `from`
value is sent as the `From` header in the requests\" (Excerpt taken from
LWP::UserAgent documentation)

The default value is `undef`, so no `From` field is set by default.

        my $p = HTTP::Promise->new( from => 'john.doe@example.com' );
        $p->from( 'john.doe@example.com' );

get
---

Provided with an `uri` and an optional hash of header name/value pairs,
and this will issue a `GET` http request to the given `uri`.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->get( $uri, $field1 => $value1, $field2 => $value2 )
        $p->get( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

head
----

Provided with an `uri` and an optional hash of header name/value pairs,
and this will issue a `HEAD` http request to the given `uri`.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->head( $uri, $field1 => $value1, $field2 => $value2 )
        $p->head( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

inactivity\_timeout
-------------------

Sets or gets the inactivity timeout in seconds. If timeout is reached,
the connection is closed.

is\_protocol\_supported
-----------------------

Provided with a protocol, such as `http`, or `https`, and this returns
true if the protocol is supported or false otherwise.

This basically returns true if the protocol is either `http` or `https`
and false otherwise, because `HTTP::Promise` supports only HTTP
protocol.

languages
---------

This is an alias for
[\"accept\_language\"](#accept_language){.perl-module}

local\_address
--------------

\"Get/set the local interface to bind to for network connections. The
interface can be specified as a hostname or an IP address. This value is
passed as the `LocalAddr` argument to
[IO::Socket::INET](https://metacpan.org/pod/IO::Socket::INET){.perl-module}.\"
(Excerpt taken from LWP::UserAgent documentation)

The default value is `undef`.

        my $p = HTTP::Promise->new( local_address => 'localhost' );
        $p->local_address( '127.0.0.1' );

max\_body\_in\_memory\_size
---------------------------

Sets or gets the maximum HTTP response body size beyond which the data
will automatically be saved in a temporary file.

max\_headers\_size
------------------

Sets or gets the maximum HTTP response headers size, beyond which an
error is triggered.

max\_redirect
-------------

An integer. Sets or gets the maximum number of allowed redirection
possible. Default is 7.

        my $p = HTTP::Promise->new( max_redirect => 5 );
        $p->max_redirect(12);
        my $max = $p->max_redirect;

max\_size
---------

\"Get/set the size limit for response content. The default is `undef`,
which means that there is no limit. If the returned response content is
only partial, because the size limit was exceeded, then a
`Client-Aborted` header will be added to the response. The content might
end up longer than `max_size` as we abort once appending a chunk of data
makes the length exceed the limit. The `Content-Length` header, if
present, will indicate the length of the full content and will normally
not be the same as `length( $resp->content )`\" (Excerpt taken from
LWP::UserAgent documentation)

        my $p = HTTP::Promise->max_size(512000); # 512kb
        $p->max_size(512000);
        my $max = $p->max_size;

mirror
------

Provided with an `uri` and a `filepath` and this will issue a
conditional request to the remote server to return the remote content if
it has been modified since the last modification time of the `filepath`.
Of course, if that file does not exists, then it is downloaded. If the
remote resource has been changed since last time, it is downloaded again
and its content stored into the `filepath`

Just like other http methods, this returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module} object.

It can then be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        $p->mirror( $uri => '/some/where/file.txt' )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

no\_proxy
---------

Sets or gets a list of domain names for which the proxy will not apply.
By default this is empty.

This returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}

        my $p = HTTP::Promise->new( no_proxy => [qw( example.com www2.example.net )] );
        $p->no_proxy( [qw( localhost example.net )] );
        my $ar = $p->no_proxy;
        say $ar->length, " proxy exception(s) set.";

options
-------

Provided with an `uri`, and this will issue an `OPTIONS` http request to
the given `uri`.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->head( $uri, $field1 => $value1, $field2 => $value2 )
        $p->options( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

patch
-----

Provided with an `uri` and an optional hash of form data, followed by an
hash of header name/value pairs and this will issue a `PATCH` http
request to the given `uri`.

If a special header name `Content` is provided, its value will be used
to create the key-value pairs form data.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->patch( $uri, \@form, $field1 => $value1, $field2 => $value2 )
        # or $p->patch( $uri, \%form, $field1 => $value1, $field2 => $value2 )
        # or $p->patch( $uri, $field1 => $value1, $field2 => $value2 )
        # or $p->patch( $uri, $field1 => $value1, $field2 => $value2, Content => \@form )
        # or $p->patch( $uri, $field1 => $value1, $field2 => $value2, Content => \%form )
        $p->patch( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

post
----

Provided with an `uri` and an optional hash of form data, followed by an
hash of header name/value pairs and this will issue a `POST` http
request to the given `uri`.

If a special header name `Content` is provided, its value will be used
to create the key-value pairs form data. THat `Content` value can either
be an array reference, or an hash reference of key-value pairs. If if is
just a string, it will be used as-is as the request body.

How the form data is formatted depends on the `Content-Type` set in the
headers passed. If the `Content-Type` header is `form-data` or
`multipart/form-data`, the form data will be formatted as a
`multipart/form-data` post, otherwise they will be formatted as a
`application/x-www-form-urlencoded` post.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->post( $uri, \@form, $field1 => $value1, $field2 => $value2 )
        # or $p->post( $uri, \%form, $field1 => $value1, $field2 => $value2 )
        # or $p->post( $uri, $field1 => $value1, $field2 => $value2 )
        # or $p->post( $uri, $field1 => $value1, $field2 => $value2, Content => \@form )
        # or $p->post( $uri, $field1 => $value1, $field2 => $value2, Content => \%form )
        # or $p->post( $uri, $field1 => $value1, $field2 => $value2, Content => $content )
        $p->post( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

prepare\_headers
----------------

Provided with an
[HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module}
object, and this will set the following request headers, if they are not
set already.

You can override this method if you create a module of your own that
inherits from
[HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module}.

It returns the
[HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module}
received, or upon error, it sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
and returns `undef`

Headers set, if not set already are:

-   `Accept`

    This uses the values set with [\"accept\"](#accept){.perl-module}

-   `Accept-Language`

    This uses the values set with
    [\"accept\_language\"](#accept_language){.perl-module} or
    [\"languages\"](#languages){.perl-module}

-   `Accept-Encoding`

    This uses the value returned from [\"decodable\" in
    HTTP::Promise::Stream](https://metacpan.org/pod/HTTP::Promise::Stream#decodable){.perl-module}
    to find out the encoding installed and supported on your system.

-   `DNT`

    This uses the value set with [\"dnt\"](#dnt){.perl-module}

-   `Upgrade-Insecure-Requests`

    This uses the value set with
    [\"auto\_switch\_https\"](#auto_switch_https){.perl-module} or
    [\"upgrade\_insecure\_requests\"](#upgrade_insecure_requests){.perl-module}

-   `User-Agent`

    This uses the value set with [\"agent\"](#agent){.perl-module}

proxy
-----

Array reference. This sets the scheme and their proxy or proxies.
Default to `undef`. For example:

        my $p = HTTP::Promise->new( proxy => [ [qw( http ftp )] => 'https://proxy.example.com:8001' ] );
        my $p = HTTP::Promise->new( proxy => [ http => 'https://proxy.example.com:8001' ] );
        my $p = HTTP::Promise->new( proxy => [ ftp => 'http://ftp.example.com:8001/', 
                                               [qw( http https )] => 'https://proxy.example.com:8001' ] );
        my $proxy = $p->proxy( 'https' );

proxy\_authorization
--------------------

Sets or gets the proxy authorization string. This is computed
automatically when you set a user and a password to the proxy URI by
setting the value to [\"proxy\"](#proxy){.perl-module}

put
---

Provided with an `uri` and an optional hash of form data, followed by an
hash of header name/value pairs and this will issue a `PUT` http request
to the given `uri`.

If a special header name `Content` is provided, its value will be used
to create the key-value pairs form data. THat `Content` value can either
be an array reference, or an hash reference of key-value pairs. If if is
just a string, it will be used as-is as the request body.

How the form data is formatted depends on the `Content-Type` set in the
headers passed. If the `Content-Type` header is `form-data` or
`multipart/form-data`, the form data will be formatted as a
`multipart/form-data` post, otherwise they will be formatted as a
`application/x-www-form-urlencoded` put.

It returns a
[promise](https://metacpan.org/pod/Promise::Me){.perl-module}, which can
be used to call one or more
[then](https://metacpan.org/pod/Promise::Me#then){.perl-module} and
[catch](https://metacpan.org/pod/Promise::Me#catch){.perl-module}

        # or $p->put( $uri, \@form, $field1 => $value1, $field2 => $value2 )
        # or $p->put( $uri, \%form, $field1 => $value1, $field2 => $value2 )
        # or $p->put( $uri, $field1 => $value1, $field2 => $value2 )
        # or $p->put( $uri, $field1 => $value1, $field2 => $value2, Content => \@form )
        # or $p->put( $uri, $field1 => $value1, $field2 => $value2, Content => \%form )
        # or $p->put( $uri, $field1 => $value1, $field2 => $value2, Content => $content )
        $p->put( $uri )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # an HTTP::Promise::Response is returned
            my $resp = shift( @_ );
            # Do something with the $resp object
        })->catch(sub
        {
            my $ex = shift( @_ );
            # An HTTP::Promise::Exception object is passed with an error code
            say( "Error code; ", $ex->code, " and message: ", $ex->message );
        });

request
-------

This method will issue the propre request in accordance with the request
object provided. It will process redirects and authentication responses
transparently. This means it may end up sending multiple request, up to
the limit set with the object option
[\"max\_redirect\"](#max_redirect){.perl-module}

This method takes the following parameters:

1\. a [request object](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module}, which is typically [HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module}, or [HTTP::Request](https://metacpan.org/pod/HTTP::Request){.perl-module}, but any class that implements a similar interface is acceptable

:   

2\. an optional hash or hash reference of parameters:

:   

    `read_size`

    :   Integer. If provided, this will instruct to read the response by
        that much bytes at a time.

    `use_content_file`

    :   Boolean. If true, this will instruct the use of a temporary file
        to store the response content. That file may then be retrieved
        with the method [\"file\"](#file){.perl-module}.

        You can also control the use of a temporary file to store the
        response content with the
        [\"threshold\"](#threshold){.perl-module} object option.

It returns a [promise
object](https://metacpan.org/pod/Promise::Me){.perl-module} just like
other methods.

For example:

        use HTTP::Promise::Request;
        my $req = HTTP::Promise::Request->new( get => 'https://example.com' );
        my $p = HTTP::Promise->new;
        my $prom = $p->request( $req )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # Get the HTTP::Promise::Response object
            my $resp = shift( @_ );
            # Do something with the response object
        })->catch(sub
        {
            # Get a HTTP::Promise::Exception object
            my $ex = shift( @_ );
            say "Got an error code ", $ex->code, " with message: ", $ex->message;
        });

requests\_redirectable
----------------------

Array reference. Sets or gets the list of http method that are allowed
to be redirected. By default this is an empty list, i.e. all http
methods are allowed to be redirected. Defaults to `GET` and `HEAD` as
per [rfc 2616](https://tools.ietf.org/html/rfc2616){.perl-module}

This returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}

        my $p = HTTP::Promise->new( requests_redirectable => [qw( HEAD GET POST )] );
        $p->requests_redirectable( [qw( HEAD GET POST )] );
        my $ok_redir = $p->requests_redirectable;
        # Add put
        $ok_redir->push( 'PUT' );
        # Remove POST we just added
        $ok_redir->remove( 'POST' );

send
----

Provided with an
[HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module},
and an optional hash or hash reference of options and this will attempt
to connect to the specified
[uri](https://metacpan.org/pod/HTTP::Promise::Request#uri){.perl-module}

Supported options:

-   `expect_threshold`

    A number specifying the request body size threshold beyond which,
    this will issue a conditional `Expect` HTTP header.

-   `total_attempts`

    Total number of attempts. This is a value that is decreased for each
    redirected requests it receives until the maximum is reached. The
    maximum is specified with
    [\"max\_redirect\"](#max_redirect){.perl-module}

    After connected to the remote server, it will send the request using
    [\"print\" in
    HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request#print){.perl-module},
    and reads the HTTP response, possibly `chunked`.

    It returns a new
    [HTTP::Promise::Response](https://metacpan.org/pod/HTTP::Promise::Response){.perl-module}
    object, or upon error, this sets an
    [error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
    and returns `undef`

send\_te
--------

Boolean. Enables or disables the `TE` http header. Defaults to true. If
true, the `TE` will be added to the outgoing http request.

        my $p = HTTP::Promise->new( send_te => 1 );
        $p->send_te(1);
        my $bool = $p->send_te;

serialiser
----------

String. Sets or gets the serialiser to use for
[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}.
Possible values are:
[cbor](https://metacpan.org/pod/CBOR::XS){.perl-module},
[sereal](https://metacpan.org/pod/Sereal){.perl-module} or
[storable](https://metacpan.org/pod/Storable::Improved){.perl-module}

By default, the value is set to the global variable `$SERIALISER`, which
is a copy of the `$SERIALISER` in
[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}, which
should be by default `storable`

simple\_request
---------------

This method takes the same parameters as
[\"request\"](#request){.perl-module} and differs in that it will not
try to handle redirects or authentication.

It returns a [promise
object](https://metacpan.org/pod/Promise::Me){.perl-module} just like
other methods.

For example:

        use HTTP::Promise::Request;
        my $req = HTTP::Promise::Request->new( get => 'https://example.com' );
        my $p = HTTP::Promise->new;
        my $prom = $p->simple_request( $req )->then(sub
        {
            my( $resolve, $reject ) = @$_;
            # Get the HTTP::Promise::Response object
            my $resp = shift( @_ );
            # Do something with the response object
        })->catch(sub
        {
            # Get a HTTP::Promise::Exception object
            my $ex = shift( @_ );
            say "Got an error code ", $ex->code, " with message: ", $ex->message;
        });

ssl\_opts
---------

[Hash reference
object](https://metacpan.org/pod/Module::Generic::Hash){.perl-module}.
Sets or gets the ssl options properties used when making requests over
ssl. The default values are set as follows:

1\. `verify_hostname`

:   When enabled, this ensures it connects to servers that have a valid
    certificate matching the expected hostname.

    1.1. If environment variable `PERL_LWP_SSL_VERIFY_HOSTNAME` is set, the ssl option property `verify_hostname` takes its value.

    :   

    1.2. If environment variable `HTTPS_CA_FILE` or `HTTPS_CA_DIR` are set to a true value, then the ssl option property `verify_hostname` is set to `0` and option property `SSL_verify_mode` is set to `1`

    :   

    1.3 If none of the above applies, it defaults `verify_hostname` to `1`

    :   

2\. `SSL_ca_file`

:   This is the path to a file containing the Certificate Authority
    certificates.

    If environment variable `PERL_LWP_SSL_CA_FILE` or `HTTPS_CA_FILE` is
    set, then the ssl option property `SSL_ca_file` takes its value.

3\. `SSL_ca_path`

:   This is the path to a directory of files containing Certificate
    Authority certificates.

    If environment variable `PERL_LWP_SSL_CA_PATH` or `HTTPS_CA_DIR` is
    set, then the ssl option property `SSL_ca_path` takes its value.

Other options can be set and are processed directly by the SSL Socket
implementation in use. See
[IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL){.perl-module}
or [Net::SSL](https://metacpan.org/pod/Net::SSL){.perl-module} for
details.

stop\_if
--------

Sets or gets a callback code reference (reference to a perl subroutine
or an anonymous subroutine) that will be used to determine if we should
keep trying upon reading data from the filehandle and an `EINTR` error
occurs.

If the callback returns true, further attempts will stop and return an
error. The default is to continue trying.

threshold
---------

Integer. Sets the content length threshold beyond which, the response
content will be stored to a locale file. It can then be fetch with
[\"file\"](#file){.perl-module}. Default to global variable
`$CONTENT_SIZE_THRESHOLD`, which is `undef` by default.

See also the [\"max\_size\"](#max_size){.perl-module} option.

        my $p = HTTP::Promise->new( threshold => 512000 );
        $p->threshold(512000);
        my $limit = $p->threshold;

timeout
-------

Integer. Sets the timeout value. Defaults to 180 seconds, i.e. 3
minutes.

The request is aborted if no activity on the connection to the server is
observed for `timeout` seconds. When a request times out, a [response
object](https://metacpan.org/pod/HTTP::Promise::Response){.perl-module}
is still returned. The response object will have a standard http status
code of `500`, i.e. server error. This response will have the
`Client-Warning` header set to the value of `Internal response`.

Returns a [number
object](https://metacpan.org/pod/Module::Generic::Number){.perl-module}

        my $p = HTTP::Promise->new( timeout => 10 );
        $p->timeout(10);
        my $timeout = $p->timeout;

upgrade\_insecure\_requests
---------------------------

This is an alias for
[\"auto\_switch\_https\"](#auto_switch_https){.perl-module}

uri\_escape
-----------

URI-escape the given string using [\"uri\_escape\" in
URI::Escape::XS](https://metacpan.org/pod/URI::Escape::XS#uri_escape){.perl-module}

uri\_unescape
-------------

URI-unescape the given string using [\"uri\_unescape\" in
URI::Escape::XS](https://metacpan.org/pod/URI::Escape::XS#uri_unescape){.perl-module}

use\_content\_file
------------------

Boolean. Enables or disables the use of a temporary file to store the
response content. Defaults to false.

When true, the response content will be stored into a temporary file,
whose object is a
[Module::Generic::File](https://metacpan.org/pod/Module::Generic::File){.perl-module}
object and can be retrieved with [\"file\"](#file){.perl-module}.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55748b07a818)"}\>

CREDITS
=======

This module is inspired by the design and workflow of Gisle Aas and his
implementation of
[HTTP::Message](https://metacpan.org/pod/HTTP::Message){.perl-module},
but built completely differently.

[HTTP::Promise::Entity](https://metacpan.org/pod/HTTP::Promise::Entity){.perl-module}
and
[HTTP::Promise::Body](https://metacpan.org/pod/HTTP::Promise::Body){.perl-module}
have been inspired by Erik Dorfman (a.k.a. Eryq) and Dianne Skoll\'s
implementation of
[MIME::Entity](https://metacpan.org/pod/MIME::Entity){.perl-module}

BUGS
====

You can report bugs at
\<https://gitlab.com/jackdeguest/HTTP-Promise/issues\>

SEE ALSO
========

[HTTP::Promise](https://metacpan.org/pod/HTTP::Promise){.perl-module},
[HTTP::Promise::Request](https://metacpan.org/pod/HTTP::Promise::Request){.perl-module},
[HTTP::Promise::Response](https://metacpan.org/pod/HTTP::Promise::Response){.perl-module},
[HTTP::Promise::Message](https://metacpan.org/pod/HTTP::Promise::Message){.perl-module},
[HTTP::Promise::Entity](https://metacpan.org/pod/HTTP::Promise::Entity){.perl-module},
[HTTP::Promise::Headers](https://metacpan.org/pod/HTTP::Promise::Headers){.perl-module},
[HTTP::Promise::Body](https://metacpan.org/pod/HTTP::Promise::Body){.perl-module},
[HTTP::Promise::Body::Form](https://metacpan.org/pod/HTTP::Promise::Body::Form){.perl-module},
[HTTP::Promise::Body::Form::Data](https://metacpan.org/pod/HTTP::Promise::Body::Form::Data){.perl-module},
[HTTP::Promise::Body::Form::Field](https://metacpan.org/pod/HTTP::Promise::Body::Form::Field){.perl-module},
[HTTP::Promise::Status](https://metacpan.org/pod/HTTP::Promise::Status){.perl-module},
[HTTP::Promise::MIME](https://metacpan.org/pod/HTTP::Promise::MIME){.perl-module},
[HTTP::Promise::Parser](https://metacpan.org/pod/HTTP::Promise::Parser){.perl-module},
[HTTP::Promise::IO](https://metacpan.org/pod/HTTP::Promise::IO){.perl-module},
[HTTP::Promise::Stream](https://metacpan.org/pod/HTTP::Promise::Stream){.perl-module},
[HTTP::Promise::Exception](https://metacpan.org/pod/HTTP::Promise::Exception){.perl-module}

[Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module},
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module},
[Module::Generic::File](https://metacpan.org/pod/Module::Generic::File){.perl-module},
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module},
[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}

[HTTP::XSHeaders](https://metacpan.org/pod/HTTP::XSHeaders){.perl-module},
[File::MMagic::XS](https://metacpan.org/pod/File::MMagic::XS){.perl-module},
[CryptX](https://metacpan.org/pod/CryptX){.perl-module},
[HTTP::Parser2::XS](https://metacpan.org/pod/HTTP::Parser2::XS){.perl-module},
[URI::Encode::XS](https://metacpan.org/pod/URI::Encode::XS){.perl-module},
[URI::Escape::XS](https://metacpan.org/pod/URI::Escape::XS){.perl-module},
[URL::Encode::XS](https://metacpan.org/pod/URL::Encode::XS){.perl-module}

[IO::Compress::Bzip2](https://metacpan.org/pod/IO::Compress::Bzip2){.perl-module},
[IO::Compress::Deflate](https://metacpan.org/pod/IO::Compress::Deflate){.perl-module},
[IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip){.perl-module},
[IO::Compress::Lzf](https://metacpan.org/pod/IO::Compress::Lzf){.perl-module},
[IO::Compress::Lzip](https://metacpan.org/pod/IO::Compress::Lzip){.perl-module},
[IO::Compress::Lzma](https://metacpan.org/pod/IO::Compress::Lzma){.perl-module},
[IO::Compress::Lzop](https://metacpan.org/pod/IO::Compress::Lzop){.perl-module},
[IO::Compress::RawDeflate](https://metacpan.org/pod/IO::Compress::RawDeflate){.perl-module},
[IO::Compress::Xz](https://metacpan.org/pod/IO::Compress::Xz){.perl-module},
[IO::Compress::Zip](https://metacpan.org/pod/IO::Compress::Zip){.perl-module},
[IO::Compress::Zstd](https://metacpan.org/pod/IO::Compress::Zstd){.perl-module}

[rfc6266 on
Content-Disposition](https://datatracker.ietf.org/doc/html/rfc6266){.perl-module},
[rfc7230 on Message Syntax and
Routing](https://tools.ietf.org/html/rfc7230){.perl-module}, [rfc7231 on
Semantics and
Content](https://tools.ietf.org/html/rfc7231){.perl-module}, [rfc7232 on
Conditional
Requests](https://tools.ietf.org/html/rfc7232){.perl-module}, [rfc7233
on Range Requests](https://tools.ietf.org/html/rfc7233){.perl-module},
[rfc7234 on Caching](https://tools.ietf.org/html/rfc7234){.perl-module},
[rfc7235 on
Authentication](https://tools.ietf.org/html/rfc7235){.perl-module},
[rfc7578 on
multipart/form-data](https://tools.ietf.org/html/rfc7578){.perl-module},
[rfc7540 on HTTP/2.0](https://tools.ietf.org/html/rfc7540){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
