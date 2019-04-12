# NAME

test-lib.pm - Test framework for LLNG portal

# SYNOPSIS

    use Test::More;
    use strict;
    use IO::String;
    
    require 't/test-lib.pm';
    
    my $res;
    
    my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel => 'error',
            #...
        }
      }
    );
    
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    count(1);
    expectOK($res);
    my $id = expectCookie($res);
    
    clean_sessions();
    done_testing( count() );

# DESCRIPTION

This test library permits to simulate browser navigation.

## Functions

In these functions, `$res` is the result of a `LLNG::Manager::Test::_get()` or
`LLNG::Manager::Test::_post()` call _(see below)_.

#### count($inc)

Returns number of tests done. Increment test number if an argument is given

#### explain( $result, $expected\_result )

Used to display error if test fails:

    ok( $res->[0] == 302, 'Get redirection' ) or
      explain( $res->[0], 302 );

#### clean\_sessions()

Clean sessions created during tests

#### expectRedirection( $res, $location )

Verify that request result is a redirection to $location. $location can be:

- a string: location must match exactly
- a regexp: location must match this regexp. In this case, the list of
matching strings are returned. Example:

        my( $uri, $query ) = expectRedirection( $res, qr#http://host(/[^\?]*)?(.*)$# );

#### expectAutoPost(@args)

Same behaviour as `expectForm()` but verify also that form method is post.

TODO: verify javascript

#### expectForm( $res, $hostRe, $uriRe, @requiredFields )

Verify form in HTML result and return ( $host, $uri, $query, $method ):

- verify that a GET/POST form exists
- if a $hostRe regexp is given, verify that form target matches and
populates $host. Skipped if $hostRe eq "#"
- if a $uriRe regexp is given, verify that form target matches and
populates $uri
- if @requiredFields exists, verify that each element is an input name
- build form-url-encoded string looking at parameters/values and store it
in $query

#### expectAuthenticatedAs($user)

Verify that result has a `Lm-Remote-User` header and value is $user

#### expectOK($res)

Verify that returned code is 200

#### expectBadRequest($res)

Verify that returned code is 400. Note that it works only for Ajax request
(see below).

#### expectReject( $res, $code )

Verify that returned code is 401 and JSON result contains `error:"$code"`.
Note that it works only for Ajax request (see below).

#### expectCookie( $res, $cookieName )

Check if a `Set-Cookie` exists and set a cookie named $cookieName. Return
its value.

#### exceptCspFormOK( $res, $host )

Verify that `Content-Security-Policy` header allows to connect to $host.

#### getCookies($res)

Returns an hash ref with names => values of cookies set by server.

#### getHeader( $res, $hname )

Returns value of first header named $hname in $res response.

#### getRedirection($res)

Returns value of `Location` header.

#### getUser($res)

Returns value of `Lm-Remote-User` header.

## LLNG::Manager::Test Class

### Accessors

- app: built application
- class: class to test (default Lemonldap::NG::Portal::Main)
- p: portal object
- ini: initialization parameters ($defaultIni values + given parameters)

### Methods

#### logout($id)

Launch a `/?logout=1` request an test:

- if response is 200
- if cookie 'lemonldap' and 'lemonldappdata' have no value
- if a GET request with previous cookie value _($i)_ is rejected

#### \_get( $path, %args )

Simulates a GET requests to $path. Accepted arguments:

- accept: accepted content, default to Ajax request. Use 'text/html'
to test content _(to launch a `expectForm()` for example)_.
- cookie: full cookie string
- custom: additional headers (hash ref only)
- ip: remote address. Default to 127.0.0.1
- method: default to GET. Only GET/DELETE values are acceptable
(use `_post()` if you want to launch a POST/PUT request)
- query: query string
- referer
- remote\_user: REMOTE\_USER header value

#### \_post( $path, $body, %args )

Same as `_get` except that a body is required. $body must be a file handle.
Example with IO::String:

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );

#### \_delete( $path, %args )

Call `_get()` with method set to DELETE.

#### \_put( $path, $body, %args )

Call `_post()` with method set to PUT
