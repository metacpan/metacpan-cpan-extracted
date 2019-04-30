[![Build Status](https://travis-ci.org/oklahomer/p5-Facebook-OpenGraph.svg?branch=master)](https://travis-ci.org/oklahomer/p5-Facebook-OpenGraph) [![Coverage Status](https://img.shields.io/coveralls/oklahomer/p5-Facebook-OpenGraph/master.svg?style=flat)](https://coveralls.io/r/oklahomer/p5-Facebook-OpenGraph?branch=master)
# NAME

Facebook::OpenGraph - Simple way to handle Facebook's Graph API.

# VERSION

This is Facebook::OpenGraph version 1.25

# SYNOPSIS

    use Facebook::OpenGraph;

    # fetching public information about given objects
    my $fb = Facebook::OpenGraph->new;
    my $user = $fb->fetch('zuck');
    my $page = $fb->fetch('oklahomer.docs');
    my $objs = $fb->bulk_fetch([qw/zuck oklahomer.docs/]);

    # get access_token for application
    my $token_ref = Facebook::OpenGraph->new(+{
        app_id => 12345,
        secret => 'FooBarBuzz',
    })->get_app_token;

    # user authorization
    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 12345,
        secret       => 'FooBarBuzz',
        namespace    => 'my_app_namespace',
        redirect_uri => 'https://sample.com/auth_callback',
    });
    my $auth_url = $fb->auth_uri(+{
        scope => [qw/email publish_actions/],
    });
    $c->redirect($auth_url);

    my $req = Plack::Request->new($env);
    my $token_ref = $fb->get_user_token_by_code($req->query_param('code'));
    $fb->set_access_token($token_ref->{access_token});

    # publish photo
    $fb->publish('/me/photos', +{
        source  => '/path/to/pic.png',
        message => 'Hello world!',
    });

    # publish Open Graph Action
    $fb->publish_action($action_type, +{$object_type => $object_url});

# DESCRIPTION

Facebook::OpenGraph is a Perl interface to handle Facebook's Graph API.
This module is inspired by [Facebook::Graph](https://metacpan.org/pod/Facebook::Graph), but mainly focuses on simplicity
and customizability because we must be able to keep up with frequently changing
API specification.

This module does **NOT** provide ways to set and validate parameters for each
API endpoint like Facebook::Graph does with Any::Moose. Instead it provides
some basic methods for HTTP request. It also provides some handy methods that
wrap `request()` for you to easily utilize most of Graph API's functionalities
including:

- API versioning that was introduced at f8, 2014.
- Acquiring user, app and/or page token and refreshing user token for
long lived one.
- Batch Request
- FQL
- FQL with Multi-Query
- Field Expansion
- Etag
- Wall Posting with Photo or Video
- Creating Test Users
- Checking and Updating Open Graph Object or Web Page with OGP
- Publishing Open Graph Action
- Deleting Open Graph Object
- Posting Staging Resource for Open Graph Object

In most cases you can specify endpoints and request parameters by yourself and
pass them to request() so it should be easier to test latest API specs. Other
requesting methods merely wrap request() method for convinience.

# METHODS

## Class Methods

### `Facebook::OpenGraph->new(\%args)`

Creates and returns a new Facebook::OpenGraph object.

_%args_ can contain...

- app\_id

    Facebook application ID. app\_id and secret are required to get application
    access token. Your app\_id should be obtained from
    [https://developers.facebook.com/apps/](https://developers.facebook.com/apps/).

- secret

    Facebook application secret. It should be obtained from
    [https://developers.facebook.com/apps/](https://developers.facebook.com/apps/).

- version

    This declares Facebook Platform version. From 2014-04-30 they support versioning
    and migrations. Default value is undef because unversioned API access is also
    allowed. This value is prepended to the end point on `request()` unless
    you specify one in requesting path.

        my $fb = Facebook::OpenGraph->new(+{version => 'v2.0'});
        $fb->get('/zuck');      # Use version 2.0 by accessing /v2.0/zuck
        $fb->get('/v1.0/zuck'); # Ignore the default version and use version 1.0

        my $fb = Facebook::OpenGraph->new();
        $fb->get('/zuck'); # Unversioned API access since version is not specified
                           # on initialisation or reqeust.

    As of 2015-03-29, the latest version is v2.3. Detailed information should be
    found at [https://developers.facebook.com/docs/apps/versions](https://developers.facebook.com/docs/apps/versions) and
    [https://developers.facebook.com/docs/apps/migrations](https://developers.facebook.com/docs/apps/migrations).

- ua

    This should be [Furl::HTTP](https://metacpan.org/pod/Furl::HTTP) object or similar object that provides same
    interface. Default is equivalent to Furl::HTTP->new(capture\_request => 1).
    You **SHOULD** install 2.10 or later version of Furl to enable capture\_request
    option. Or you can specify keep\_request option for same purpose if you have Furl
    2.09. Setting capture\_request option is **strongly** recommended since it gives
    you the request headers and content when `request()` fails.

        my $fb = Facebook::OpenGraph->new;
        $fb->post('/me/feed', +{message => 'Hello, world!'});
        #2500:- OAuthException:An active access token must be used to query information about the current user.
        #POST /me/feed HTTP/1.1
        #Connection: keep-alive
        #User-Agent: Furl::HTTP/2.15
        #Content-Type: application/x-www-form-urlencoded
        #Content-Length: 27
        #Host: graph.facebook.com
        #
        #message=Hello%2C%20world%21

- namespace

    Facebook application namespace. This is used when you publish Open Graph Action
    via `publish_action()`.

- access\_token

    Access token for user, application or Facebook Page.

- redirect\_uri

    The URL to be used for authorization. User will be redirected to this URL after
    login dialog. Detail should be found at
    [https://developers.facebook.com/docs/reference/dialogs/oauth/](https://developers.facebook.com/docs/reference/dialogs/oauth/).

    You must keep in mind that "The URL you specify must be a URL with the same
    base domain specified in your app's settings, a Canvas URL of the form
    https://apps.facebook.com/YOUR\_APP\_NAMESPACE or a Page Tab URL of the form
    https://www.facebook.com/PAGE\_USERNAME/app\_YOUR\_APP\_ID"

- batch\_limit

    The maximum number of queries that can be set within a single batch request.
    If the number of given queries exceeds this, then queries are divided into
    multiple batch requests, and responses are combined so it seems just like a
    single request.

    Default value is 50 as API documentation says. Official documentation is
    located at [https://developers.facebook.com/docs/graph-api/making-multiple-requests/](https://developers.facebook.com/docs/graph-api/making-multiple-requests/)

    You must be aware that "each call within the batch is counted separately for
    the purposes of calculating API call limits and resource limits."
    See [https://developers.facebook.com/docs/reference/ads-api/api-rate-limiting/](https://developers.facebook.com/docs/reference/ads-api/api-rate-limiting/).

- is\_beta

    Weather to use beta tier. See the official documentation for details.
    [https://developers.facebook.com/support/beta-tier/](https://developers.facebook.com/support/beta-tier/).

- json

    JSON object that handles request parameters and API response. Default is
    equivalent to JSON->new->utf8.

- use\_appsecret\_proof

    Whether to use appsecret\_proof parameter or not. Default is 0.
    Long-desired official document is now provided at
    [https://developers.facebook.com/docs/graph-api/securing-requests/](https://developers.facebook.com/docs/graph-api/securing-requests/)

    You must specify access\_token and application secret to utilize this.

    my $fb = Facebook::OpenGraph->new(+{
        app_id              => 123456,
        secret              => 'FooBarBuzz',
        ua                  => Furl::HTTP->new(capture_request => 1),
        namespace           => 'fb-app-namespace', # for Open Graph Action
        access_token        => '', # will be appended to request header in request()
        redirect_uri        => 'https://sample.com/auth_callback', # for OAuth
        batch_limit         => 50,
        json                => JSON->new->utf8,
        is_beta             => 0,
        use_appsecret_proof => 1,
        use_post_method     => 0,
        version             => undef,
    })

## Instance Methods

### `$fb->app_id`

Accessor method that returns application id.

### `$fb->secret`

Accessor method that returns application secret.

### `$fb->ua`

Accessor method that returns [Furl::HTTP](https://metacpan.org/pod/Furl::HTTP) object.

### `$fb->namespace`

Accessor method that returns application namespace.

### `$fb->access_token`

Accessor method that returns access token.

### `$fb->redirect_uri`

Accessor method that returns URL that is used for user authorization.

### `$fb->batch_limit`

Accessor method that returns the maximum number of queries that can be set
within a single batch request. If the number of given queries exceeds this,
then queries are divided into multiple batch requests, and responses are
combined so it just seems like a single batch request. Default value is 50 as
API documentation says.

### `$fb->is_beta`

Accessor method that returns whether to use Beta tier or not.

### `$fb->json`

Accessor method that returns JSON object. This object will be passed to
Facebook::OpenGraph::Response via `create_response()`.

### `$fb->use_appsecret_proof`

Accessor method that returns whether to send appsecret\_proof parameter on API
call. Official document is not provided yet, but PHP SDK has this option and
you can activate this option from App Setting > Advanced > Security.

### `$fb->use_post_method`

Accessor method that returns whether to use POST method for every API call and
alternatively set method=(GET|POST|DELETE) query parameter. PHP SDK works this
way. This might work well when you use multi-query or some other functions that use GET method while query string can be very long and you have to worry about
the maximum length of it.

### `$fb->version`

Accessor method that returns Facebook Platform version. This can be undef
unless you explicitly on initialisation.

### `$fb->uri($path, \%query_param)`

Returns URI object with specified path and query parameter. If is\_beta returns
true, the base url is https://graph.beta.facebook.com/ . Otherwise its base url
is https://graph.facebook.com/ . `request()` automatically determines if it
should use `uri()` or `video_uri()` based on target path and parameters so
you won't use `uri()` or `video_uri()` directly as long as you are using
requesting methods that are provided in this module.

### `$fb->video_uri($path, \%query_param)`

Returns URI object with specified path and query parameter. This should only be
used when posting a video.

### `$fb->site_uri($path, \%query_param)`

Returns URI object with specified path and query parameter. It is mainly used to
generate URL for Auth dialog, but you can still use this when redirecting users
to your Facebook page, App's Canvas page or any location on facebook.com.

    my $fb = Facebook::OpenGraph->new(+{is_beta => 1});
    $c->redirect($fb->site_uri($path_to_canvas));
    # https://www.beta.facebook.com/$path_to_canvas

### `$fb->parse_signed_request($signed_request_str)`

It parses signed\_request that Facebook Platform gives to you on various
situations. situations may include

- Given as a URL fragment on callback endpoint after login flow is done
with Login Dialog
- POSTed when Page Tab App is loaded
- Set in a form of cookie by JS SDK

Fields in returning value are introduced at
[https://developers.facebook.com/docs/reference/login/signed-request/](https://developers.facebook.com/docs/reference/login/signed-request/).

    my $req = Plack::Request->new($env);
    my $val = $fb->parse_signed_request($req->query_param('signed_request'));

### `$fb->auth_uri(\%args)`

Returns URL for Facebook OAuth dialog. You can redirect your user to this
URL for authorization purpose.

If Facebook Platform version is set on initialisation, that value is
prepended to the path.
[https://developers.facebook.com/docs/apps/versions#dialogs](https://developers.facebook.com/docs/apps/versions#dialogs).

See the detailed flow at [https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow](https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow).
Optional values are shown at [https://developers.facebook.com/docs/reference/dialogs/oauth/](https://developers.facebook.com/docs/reference/dialogs/oauth/).

    my $auth_url = $fb->auth_uri(+{
        display       => 'page', # Dialog's display type. Default value is 'page.'
        response_type => 'code',
        scope         => [qw/email publish_actions/],
    });
    $c->redirect($auth_url);

### `$fb->set_access_token($access_token)`

Set $access\_token as the access token to be used on `request()`. `access_token()`
returns this value.

### `$fb->get_app_token`

Obtain an access token for application. Give the returning value to
`set_access_token()` and you can make request on behalf of your application.
This access token never expires unless you reset application secret key on App
Dashboard so you might want to store this value within your process like
below...

    package MyApp::OpenGraph;
    use parent 'Facebook::OpenGraph';

    sub get_app_token {
        my $self = shift;
        return $self->{__app_access_token__}
            ||= $self->SUPER::get_app_token->{access_token};
    }

Or you might want to use [Cache::Memory::Simple](https://metacpan.org/pod/Cache::Memory::Simple) or something similar to
refetch token at an interval of your choice. Maybe you want to store token on
DB and override this method to return the stored value.

### `$fb->get_user_token_by_code($given_code)`

Obtain an access token for user based on `$code`. `$code` should be obtained
on your callback endpoint which is specified on `eredirect_uri`. Give the
returning access token to `set_access_token()` and you can act on behalf of
the user.

FYI: _expires_ or _expires\_in_ is **NOT** returned on some edge cases. The
detail and reproductive scenario should be found at
[https://developers.facebook.com/bugs/597779113651383/](https://developers.facebook.com/bugs/597779113651383/).

    # On OAuth callback page which you specified on $fb->redirect_uri.
    my $req          = Plack::Request->new($env);
    my $token_ref    = $fb->get_user_token_by_code($req->query_param('code'));
    my $access_token = $token_ref->{access_token};
    my $expires      = $token_ref->{expires}; # named expires_in as of v2.3

### `$fb->get_user_token_by_cookie($cookie_value)`

Obtain user access token based on the cookie value that is set by JS SDK.
Cookie name should be determined with `js_cookie_name()`.

FYI: _expires_ or _expires\_in_ is **NOT** returned on some edge cases. The
detail and reproductive schenario should be found at
[https://developers.facebook.com/bugs/597779113651383/](https://developers.facebook.com/bugs/597779113651383/).

    if (my $cookie = $c->req->cookie( $fb->js_cookie_name )) {
      # User is not logged in yet, but cookie is set by JS SDK on previous visit.
      my $token_ref = $fb->get_user_token_by_cookie($cookie);
      # {
      #     "access_token" : "new_token_string_qwerty",
      #     "expires" : 5752 # named expires_in as of v2.3
      # };
    }
    else {
      return $c->redirect( $fb->auth_uri );
    }

### `$fb->exchange_token($short_term_token)`

Exchange short lived access token for long lived one. Short lived tokens are
ones that you obtain with `get_user_token_by_code()`. Usually long lived
tokens live about 60 days while short lived ones live about 2 hours.

FYI: _expires_ or _expires\_in_ is **NOT** returned on some edge cases. The
detail and reproductive schenario should be found at
[https://developers.facebook.com/bugs/597779113651383/](https://developers.facebook.com/bugs/597779113651383/).

    my $extended_token_ref = $fb->exchange_token($token_ref->{access_token});
    my $access_token       = $extended_token_ref->{access_token};
    my $expires            = $extended_token_ref->{expires};
                             # named expires_in as of v2.3

If you loved the way old offline\_access permission worked, and are looking for a
substitute you might want to try this.

### `$fb->get($path, \%param, \@headers)`

Alias to `request()` that sends `GET` request.

    my $path = 'zuck'; # should be ID or username
    my $user = $fb->get($path);
    #{
    #    name   => 'Mark Zuckerberg',
    #    id     => 4,
    #    locale => 'en_US',
    #}

### `$fb->post($path, \%param, \@headers)`

Alias to `request()` that sends `POST` request.

    my $res = $fb->publish('/me/photos', +{source => '/path/to/pic.png'});
    #{
    #    id      => 123456,
    #    post_id => '123456_987654',
    #
    #}

### `$fb->fetch($path, \%param, \@headers)`

Alias to `get()` for those who got used to [Facebook::Graph](https://metacpan.org/pod/Facebook::Graph)

### `$fb->publish($path, \%param, \@headers)`

Alias to `post()` for those who got used to [Facebook::Graph](https://metacpan.org/pod/Facebook::Graph)

### `$fb->fetch_with_etag($path, \%param, $etag_value)`

Alias to `request()` that sends `GET` request with given ETag value. Returns
undef if requesting data is not modified. Otherwise it returns modified data.

    my $user = $fb->fetch_with_etag('/zuck', +{fields => 'email'}, $etag);

### `$fb->bulk_fetch(\@paths)`

Request batch request and returns an array reference.

    my $data = $fb->bulk_fetch([qw/zuck go.hagiwara/]);
    #[
    #    {
    #        link => 'http://www.facebook.com/zuck',
    #        name => 'Mark Zuckerberg',
    #    },
    #    {
    #        link => 'http://www.facebook.com/go.hagiwara',
    #        name => 'Go Hagiwara',
    #    }
    #]

### `$fb->batch(\@requests)`

Request batch request and returns an array reference of response objects. It
sets `$fb-`access\_token> as top level access token, but other than that you
can specify indivisual access token for each request. The document says
"The Batch API is flexible and allows individual requests to specify their own
access tokens as a query string or form post parameter. In that case the top
level access token is considered a fallback token and is used if an individual
request has not explicitly specified an access token."

    my $data = $fb->batch([
        +{method => 'GET', relative_url => 'zuck'},
        +{method => 'GET', relative_url => 'oklahomer.docs'},
    ]);

### `$fb->batch_fast(\@requests)`

Request batch request and returns results as array reference, but it doesn't
create [Facebook::OpenGraph::Response](https://metacpan.org/pod/Facebook::OpenGraph::Response) to handle each response.

    my $data = $fb->batch_fast([
        +{method => 'GET', relative_url => 'zuck'},
        +{method => 'GET', relative_url => 'oklahomer.docs'},
    ]);
    #[
    #    [
    #        {
    #            body    => {id => 4, name => 'Mark Zuckerberg', .....},
    #            headers => [ .... ],
    #            code    => 200,
    #        },
    #        {
    #            body    => {id => 204277149587596, name => 'Oklahomer', .....},
    #            headers => [ .... ],
    #            code    => 200,
    #        },
    #    ]
    #]

You can specify access token for each query within a single batch request.
See [https://developers.facebook.com/docs/graph-api/making-multiple-requests/](https://developers.facebook.com/docs/graph-api/making-multiple-requests/)
for detail.

### `$fb->fql($fql_query)`

Alias to `request()` that optimizes query parameter for FQL query and sends
`GET` request.

    my $res = $fb->fql('SELECT display_name FROM application WHERE app_id = 12345');
    #{
    #    data => [{
    #        display_name => 'app',
    #    }],
    #}

### `$fb->bulk_fql(\%fql_queries)`

Alias to `fql()` to request multiple FQL query at once.

    my $res = $fb->bulk_fql(+{
        'all friends' => 'SELECT uid2 FROM friend WHERE uid1 = me()',
        'my name'     => 'SELECT name FROM user WHERE uid = me()',
    });
    #{
    #    data => [
    #        {
    #            fql_result_set => [
    #                {uid2 => 12345},
    #                {uid2 => 67890},
    #            ],
    #            name => 'all friends',
    #        },
    #        {
    #            fql_result_set => [
    #                name => 'Michael Corleone'
    #            ],
    #            name => 'my name',
    #        },
    #    ],
    #}

### `$fb->delete($path, \%param)`

Alias to `request()` that sends DELETE request to delete object on Facebook's
social graph. It sends POST request with method=delete query parameter when
DELETE request fails. I know it's weird, but sometimes DELETE fails and POST
with method=delete works.

    $fb->delete($object_id);

### `$fb->request($request_method, $path, \%param, \@headers)`

Sends request to Facebook Platform and returns [Facebook::Graph::Response](https://metacpan.org/pod/Facebook::Graph::Response)
object.

### `$fb->gen_appsecret_proof`

Generates signature for appsecret\_proof parameter. This method is called in
`request()` if `$self-`use\_appsecret\_proof> is set. See
[http://facebook-docs.oklahome.net/archives/52097348.html](http://facebook-docs.oklahome.net/archives/52097348.html) for Japanese Info.

### `$fb->js_cookie_name`

Generates and returns the name of cookie that is set by JS SDK on client side
login. This value can be parsed as signed request and the parsed data structure
contains 'code' to exchange for acess token. See `get_user_token_by_cookie()`
for detail.

### `$fb->create_response($http_status_code, $http_status_message, \@response_headers, $response_content)`

Creates and returns [Facebook::OpenGraph::Response](https://metacpan.org/pod/Facebook::OpenGraph::Response). If you wish to use
customized response class, then override this method to return
MyApp::Better::Response.

### `$fb->prep_param(\%param)`

Handles sending parameters and format them in the way Graph API spec states.
This method is called in `request()` so you don't usually use this method
directly.

### `$fb->prep_fields_recursive(\@fields)`

Handles fields parameter and format it in the way Graph API spec states.
The main purpose of this method is to deal with Field Expansion
([https://developers.facebook.com/docs/graph-api/using-graph-api/#fieldexpansion](https://developers.facebook.com/docs/graph-api/using-graph-api/#fieldexpansion)).
This method is called in `prep_param` which is called in `request()` so you
don't usually use this method directly.

    # simple fields
    $fb->prep_fields_recursive([qw/name email albums/]); # name,email,albums

    # use field expansion
    $fb->prep_fields_recursive([
        'name',
        'email',
        +{
            albums => +{
                fields => [
                    'name',
                    +{
                        photos => +{
                            fields => [
                                'name',
                                'picture',
                                +{
                                    tags => +{
                                        limit => 2,
                                    },
                                }
                            ],
                            limit => 3,
                        }
                    }
                ],
                limit => 5,
            }
        }
    ]);
    # 'name,email,albums.fields(name,photos.fields(name,picture,tags.limit(2)).limit(3)).limit(5)'

### `$fb->publish_action($action_type, \%param)`

Alias to `request()` that optimizes body content and endpoint to send `POST`
request to publish Open Graph Action.

    my $res = $fb->publish_action('give', +{crap => 'https://sample.com/poop/'});
    #{id => 123456}

### `$fb->create_test_users(\@settings)`

    my $res = $fb->create_test_users([
        +{
            permissions => [qw/publish_actions/],
            locale      => 'en_US',
            installed   => 'true',
        },
        +{
            permissions => [qw/publish_actions email read_stream/],
            locale      => 'ja_JP',
            installed   => 'true',
        }
    ])
    #[
    #    +{
    #        id           => 123456789,
    #        access_token => '5678uiop',
    #        login_url    => 'https://www.facebook.com/........',
    #        email        => '.....@tfbnw.net',
    #        password     => '.......',
    #    },
    #    +{
    #        id           => 1234567890,
    #        access_token => '5678uiopasadfasdfa',
    #        login_url    => 'https://www.facebook.com/........',
    #        email        => '.....@tfbnw.net',
    #        password     => '.......',
    #    },
    #];

Alias to `request()` that optimizes to create test users for your application.

### `$fb->publish_staging_resource($file_path)`

Alias to `request()` that optimizes body content to send `POST` request to upload image to Object API's staging environment.

    my $fb = Facebook::OpenGraph->new(+{
        access_token => $USER_ACCESS_TOKEN,
    });
    my $res = $fb->publish_staging_resource('/path/to/file');
    #{
    #  uri => 'fbstaging://graph.facebook.com/staging_resources/MDExMzc3MDU0MDg1ODQ3OTY2OjE5MDU4NTM1MzQ=',
    #};

### `$fb->check_object($object_id_or_url)`

Alias to `request()` that sends `POST` request to Facebook Debugger to
check/update object.

    $fb->check_object('https://sample.com/object/');
    $fb->check_object($object_id);

# AUTHOR

Oklahomer <hagiwara dot go at gmail dot com>

# SUPPORT

- Repository

    [https://github.com/oklahomer/p5-Facebook-OpenGraph/](https://github.com/oklahomer/p5-Facebook-OpenGraph/)

- Bug Reports

    [https://github.com/oklahomer/p5-Facebook-OpenGraph/issues](https://github.com/oklahomer/p5-Facebook-OpenGraph/issues)

# SEE ALSO

[Facebook::Graph](https://metacpan.org/pod/Facebook::Graph)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
