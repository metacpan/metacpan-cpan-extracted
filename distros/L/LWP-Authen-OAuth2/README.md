# NAME

LWP::Authen::OAuth2 - Make requests to OAuth2 APIs.

# VERSION

version 0.20

# SYNOPSIS

OAuth 2 is a protocol that lets a _user_ tell a _service provider_ that a
_consumer_ has permission to use the _service provider_'s APIs to do things
that require access to the _user_'s account.  This module tries to make life
easier for someone who wants to write a _consumer_ in Perl.

Specifically it provides convenience methods for all of the requests that are
made to the _service provider_ as part of the permission handshake, and
after that will proxy off of [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) to let you send properly
authenticated requests to the API that you are trying to use.  When possible,
this will include transparent refresh/retry logic for access tokens
expiration.

For a full explanation of OAuth 2, common terminology, the requests that get
made, and the necessary tasks that this module does not address, please see
[LWP::Authen::OAuth2::Overview](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AOverview)

This module will not help with OAuth 1.  See the similarly named but
unrelated [LWP::Authen::OAuth](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth) for a module that can help with that.

Currently [LWP::Authen::OAuth2](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2) provides ready-to-use classes to use OAuth2 with

- Dwolla

    [LWP::Authen::OAuth2::ServiceProvider::Dwolla](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider%3A%3ADwolla)

    implemented by [Adi Fairbank](https://github.com/adifairbank)

- Google

    [LWP::Authen::OAuth2::ServiceProvider::Google](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider%3A%3AGoogle)

- Line

    [LWP::Authen::OAuth2::ServiceProvider::Line](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider%3A%3ALine)

    implemented by [Adam Millerchip](https://github.com/amillerchip)

- Strava

    [LWP::Authen::OAuth2::ServiceProvider::Strava](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider%3A%3AStrava)

    implemented by [Leon Wright](https://github.com/techman83)

- Withings

    [LWP::Authen::OAuth2::ServiceProvider::Withings](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider%3A%3AWithings)

    implemented by [Brian Foley](https://github.com/foleybri)

- Yahoo

    [LWP::Authen::OAuth2::ServiceProvider::Yahoo](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider%3A%3AYahoo)

    implemented by [Michael Stevens](https://github.com/michael-stevens)

You can also access any other OAuth2 service by setting up a plain `LWP::Authen::OAuth2` object. If you do, and the service provider might be of interest to other people, please submit a patch so we can include it in this distribution, or release it as a standalone package.

Here are examples of simple usage.

    use LWP::Authen::OAuth2;

    # Constructor
    my $oauth2 = LWP::Authen::OAuth2->new(
                     client_id => "Public from service provider",
                     client_secret => "s3cr3t fr0m svc prov",
                     service_provider => "Google",
                     redirect_uri => "https://your.url.com/",

                     # Optional hook, but recommended.
                     save_tokens => \&save_tokens,
                     save_tokens_args => [ $dbh ],

                     # This is for when you have tokens from last time.
                     token_string => $token_string.
                 );

    # URL for user to go to to start the process.
    my $url = $oauth2->authorization_url();

    # The authorization_url sends the user to the service provider to
    # say that you want to be authorized.  After the user confirms that
    # request, the service provider sends the user back to you with a
    # code.  This might be a CGI parameter, something that the user is
    # supposed to paste to you - that's between you and the service
    # provider.

    # Assuming that you have your code, get your tokens from the service
    # provider.
    $oauth2->request_tokens(code => $code);

    # Get your token as a string you can easily store, pass around, etc.
    # If you have a save_tokens callback, that gets passed this string
    # whenever the tokens change.
    #
    # This string bears a suspicious resemblance to serialized JSON.
    my $token_string = $oauth2->token_string,

    # Access the API.  Consult the service_provider's documentation for when
    # to use which type of request.  Note that argument processing is the
    # same as in LWP.  Thus the parameters array and headers hash are both
    # optional.
    $oauth2->get($url, %header);
    $oauth2->post($url, \@parameters, %header);
    $oauth2->put($url, %header);
    $oauth2->delete($url, %header);
    $oauth2->head($url, %header);

    # And if you need more flexibility, you can use LWP::UserAgent's request
    # method
    $oauth2->request($http_request, $content_file);

    # In some flows you can refresh tokens, in others you have to go through
    # the handshake yourself.  This method lets you know whether a refresh
    # looks possible.
    $oauth2->can_refresh_tokens();

    # This method lets you know when it is time to reauthorize so that you
    # can find out in a nicer way than failing an API call.
    $oauth2->should_refresh();

# CONSTRUCTOR

When you call `LWP::Authen::OAuth2->new(...)`, arguments are passed as a
key/value list.  They are processed in the following phases:

- Construct service provider
- Service provider collects arguments it wants
- [LWP::Authen::OAuth2](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2) overrides defaults from arguments
- Sanity check

Here are those phases in more detail.

- Construct service provider

    There are two ways to construct a service provider.

    - Prebuilt class

        To load a prebuilt class you just need one or two arguments.

        - `service_provider => $Foo,`

            In the above construct, `$Foo` identifies the base class for your service
            provider.  The actual class will be the first of the following two classes
            that can be loaded.  Failure to find either is an error.

                LWP::Authen::OAuth2::ServiceProvider $Foo
                $Foo

            A list of prebuilt service provider classes is in
            [LWP::Authen::OAuth2::ServiceProvider](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider) as well as instructions for making a
            new one.

        - `client_type => $name_of_client_type`

            Some service providers will keep track of your client type ("webserver"
            application, "installed" application, etc), and will treat them differently.
            A base service provider class can choose to accept a `client_type` parameter
            to let it know what to expect.

            Whether this is done, and the allowable values, are up to the service
            provider class.

    - Built on the fly

        The behavior of simple service providers can be described on the fly without
        needing a prebuilt class.  To do that, the following arguments can be filled
        with arguments from your service provider:

        - `authorization_endpoint => $auth_url,`

            This is the URL which the user is directed to in the authorization request.

        - `token_endpoint => $token_url,`

            This is the URL which the consumer goes to for tokens.

        - Various optional fields

            [LWP::Authen::OAuth2::ServiceProvider](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2%3A%3AServiceProvider) documents many methods that are
            available to customize the actual requests made, and defaults available.
            Simple service providers can likely get by without this, but here is a list
            of those methods that can be specified instead in the constructor:

                # Arrayrefs
                required_init
                optional_init
                authorization_required_params
                authorization_optional_params
                request_required_params
                request_optional_params
                refresh_required_params
                refresh_optional_params

                # Hashrefs
                authorization_default_params
                request_default_params
                refresh_default_params

    - Service provider collects arguments it wants

        In general, arguments passed into the constructor do not have to be passed
        into individual method calls.  Furthermore in order to be able to do the
        automatic token refresh for you, the constructor must include the arguments
        that will be required.

        By default you are required to pass your `client_id` and `client_secret`.
        And optionally can pass a `redirect_uri` and `scope`.  (The omission of
        `state` is a deliberate hint that if you use that field, you should be
        generating random values on the fly.  And not trying to go to some reasonable
        default.)

        However what is required is up to the service provider.

    - [LWP::Authen::OAuth2](https://metacpan.org/pod/LWP%3A%3AAuthen%3A%3AOAuth2) overrides defaults from arguments

        The following defaults are available to be overridden in the constructor, or
        can be overridden later.  In the unlikely event that there is a conflict with
        the service provider's arguments, these will have to be overridden later.

        - `error_handler => \&error_handler,`

            Specifies the function that will be called when errors happen.  The default
            is `Carp::croak`.

        - `is_strict => $bool,`

            Is strict mode on?  If it is, then excess parameters to requests that are
            part of the authorization process will trigger errors.  If it is not, then
            excess arguments are passed to the service provider as is, who
            according to the specification is supposed to ignore them.

            Strict mode is the default.

        - `early_refresh_time => $seconds,`

            How many seconds before the end of estimated access token expiration you
            will have `should_refresh` start returning true.

        - `prerefresh => \&prerefresh,`

            A handler to be called before attempting to refresh tokens.  It is passed the
            `$oauth2` object.  If it returns a token string, that will be used to
            generate tokens instead of going to the service provider.

            The purpose of this hook is so that, even if you have multiple processes
            accessing an API simultaneously, only one of them will try to refresh tokens
            with the service provider.  (Service providers may dislike having multiple
            refresh requests arrive at once from the same consumer for the same user.)

            By default this is not provided.

        - `save_tokens => \&save_tokens,`

            Whenever tokens are returned from the service provider, this callback will
            receive a token string that can be stored and then retrieved in another
            process that needs to construct a `$oauth2` object.

            By default this is not provided.  However if you intend to access the
            API multiple times from multiple processes, it is recommended.

        - `save_tokens_args => [ args ],`

            Additional arguments passed to the save\_tokens callback function after the
            token string. This can be used to pass things like database handles or
            other data to the callback along with the token string. Provide a reference
            to an array of arguments in the constructure. When the callback is
            called the arguments are passed to the callback as an array, so in the
            example below $arg1 will be "foo" and $arg2 will be "bar"

                ...
                save_tokens => \&save_tokens,
                save_tokens_args => [ "foo", "bar" ],
                ...

                sub save_tokens {
                    my ($token_string, $arg1, $arg2) = @_;

                    ...
                }

        - `token_string => $token_string,`

            Supply tokens generated in a previous request so that you don't have to ask
            the service provider for new ones.  Some service providers refuse to hand out
            tokens too quickly, so this can be important.

        - `user_agent => $ua,`

            What user agent gets used under the hood?  Defaults to a new
            [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) created on the fly.

    - Sanity check

        Any arguments that are left over are assumed to be mistakes and a fatal
        warning is generated.

# METHODS

Once you have an object, the following methods may be useful for writing a
consumer.

## `$oauth2->authorization_url(%opts)`

Generate a URL for the user to go to to request permissions.  By default the
`response_type` and `client_id` are defaulted, and all of `redirect_uri`,
`state` and `scope` are optional but not required.  However in practice
this all varies by service provider and client type, so look for
documentation on that for the actual list that you need.

## `$oauth2->request_tokens(%opts)`

Request tokens from the service provider (if possible).  By default the
`grant_type`, `client_id` and `client_secret` are defaulted, and the
`scope` is required.  However in practice this all varies by service
provider and client type, so look for documentation on that for the actual
list that you need.

## `$oauth2->get(...)`

Issue a `get` request to an OAuth 2 protected URL, just like you would
using [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) to a normal URL.

## `$oauth2->head(...)`

Issue a `head` request to an OAuth 2 protected URL, just like you would
using [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) to a normal URL.

## `$oauth2->post(...)`

Issue a `post` request to an OAuth 2 protected URL, just like you would
using [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) to a normal URL.

## `$oauth2->delete(...)`

Issue a `delete` request to an OAuth 2 protected URL, similar to the
previous examples.  (This shortcut is not by default available with
[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent).)

## `$oauth2->put(...)`

Issue a `put` request to an OAuth 2 protected URL, similar to the
previous examples.  (This shortcut is not by default available with
[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent).)

## `$oauth2->request(...)`

Issue any `request` that you could issue with [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent),
except that it will be properly signed to go to an OAuth 2 protected URL.

## `$oauth2->make_api_call($uri, $params, $headers)`

This is a convenience method which makes a call to an OAuth2 API endpoint
given by $uri, and returns the JSON response decoded to a hash.  If the
$params hashref arg is set, its contents will be JSON encoded and sent as
POST request content; otherwise it will make a GET request.
Optional $headers may be sent which will be passed through to
`$oauth->get()` or `$oauth->post()`.

If the call succeeds, it will return the response's JSON content decoded
as hash, or if no response body was returned, a value of 1 to indicate success.
On failure returns undef, and error message is available from
`$oauth2->api_call_error()`.

## `$oauth2->api_call_error()`

If an error occurred in `$oauth2->make_api_call()`, this method will
return it.  The error message comes from `HTTP::Response->error_as_HTML()`.

## `$oauth2->api_url_base()`

Returns the base URL of the service provider, which is sometimes useful to be
used in the content of OAuth2 API calls.

## `$oauth2->can_refresh_tokens`

Is sufficient information available to try to refresh tokens?

## `$oauth2->should_refresh()`

Is it time to refresh tokens?

## `$oauth2->set_early_refresh_time($seconds)`

Set how many seconds before the end of token expiration the method
`should_refresh` will start turning true.  Values over half the initial
expiration time of access tokens will be ignored to avoid refreshing too
often.  This defaults to 300.

## `$oauth2->expires_time()`

Returns the raw epoch expiration time of the current access token.
Typically this is 3600 seconds greater than the time of token creation.

## `$oauth2->set_is_strict($mode)`

Set strict mode on/off.  See the discussion of `is_strict` in the
constructor for an explanation of what it does.

## `$oauth2->set_error_handler(\&error_handler)`

Set the error handler.  See the discussion of `error_handler` in the
constructor for an explanation of what it does.

## `$oauth2->set_prerefresh(\&prerefresh)`

Set the prerefresh handler.  See the discussion of `prerefresh_handler` in
the constructor for an explanation of what it does.

## `$oauth2->set_save_tokens($ua)`

Set the save tokens handler.  See the discussion of `save_tokens` in the
constructor for an explanation of what it does.

## `$oauth2->set_user_agent($ua)`

Set the user agent.  This should respond to the same methods that a
[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) responds to.

## `$oauth2->user_agent()`

Get the user agent.  The default if none was explicitly set is a new
[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) object.

## Contributors

- [Leon Wright](https://github.com/techman83)
- [Thomas Klausner](https://github.com/domm)
- [Alex Dutton](https://github.com/alexdutton)
- [Chris](https://github.com/TheWatcher)
- [Adi Fairbank](https://github.com/adifairbank)
- [Adam Millerchip](https://github.com/amillerchip)
- [André Brás](https://github.com/whity)

# ACKNOWLEDGEMENTS

Thanks to [Rent.com](http://www.rent.com) for their generous support in
letting me develop and release this module.  My thanks also to Nick
Wellnhofer <wellnhofer@aevum.de> for Net::Google::Analytics::OAuth2 which
was very enlightening while I was trying to figure out the details of how to
connect to Google with OAuth2.

Thanks to

- [Thomas Klausner](https://github.com/domm) for reporting that client
type specific parameters were not available when the client type was properly
specified
- [Alex Dutton](https://github.com/alexdutton) for making
`ServiceProvider` work without requiring subclassing.
- [Leon Wright](https://github.com/techman83) for adding a [Strava ](https://metacpan.org/pod/%20http%3A#strava.com) Service Provider and various bug fixes
- [Adi Fairbank](https://github.com/adifairbank) for adding a [Dwolla ](https://metacpan.org/pod/%20https%3A#www.dwolla.com) Service Provider and some other improvements
- [Adam Millerchip](https://github.com/amillerchip) for adding a [Line ](https://metacpan.org/pod/%20https%3A#line.me) Service Provider and some refactoring
- [Michael Stevens](https://github.com/mstevens) for adding a `Yahoo | https://developer.yahoo.com` Service Provider and some dist cleanup
- Nick Morrott for fixing some documentation typos

# AUTHORS

- Ben Tilly, &lt;btilly at gmail.com>
- Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2022 by Ben Tilly, Rent.com, Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
