# NAME

Google::Client::Collection - Collection of modules to talk with Googles REST API

# SYNOPSIS

    use Google::Client::Collection;

    my $google = Google::Client::Collection->new(
        cache => CHI::Driver->new(), # ... or anything with a 'get($cache_key)' method
    );

    # then before calling a google clients method, set the key to fetch the access_token from in the cache:
    $google->set_cache_key('user-10-access-token');

    # eg: use a Google::Client::Files client:
    my $json = $google->files->list(); # lists all files available by calling: GET https://www.googleapis.com/drive/v3/files

# DESCRIPTION

A compilation of Google::Client::\* clients used to connect to the many resources of [Googles REST API](https://developers.google.com/google-apps/products).
All such clients can be found in CPAN under the 'Google::Client' namespace (eg [Google::Client::Files](https://metacpan.org/pod/Google::Client::Files)).
Each client uses the same constructor arguments, so they can be used separately if desired.

You should only ever have to instantiate `Google::Client::Collection`, which will give you access to all the available REST clients (pull requests welcome to add more!).

Requests to Googles API require authentication, which can be handled via [Google::OAuth2::Client::Simple](https://metacpan.org/pod/Google::OAuth2::Client::Simple).

Also, make sure you request the right scopes from the user during authentication before using a client, as you will get unauthorized errors from Google (intended behaviour).

# CONSTRUCTOR ARGS

## cache

Required constructor argument. The cache can be any object
that provides a `get($cache_key)` method to retrieve
the access token. It'll be responsible for eventually
expiring the access token so it's known when to
request a new one.

# METHODS

## cache\_key

The key to lookup the access token in the cache. Should be set
before calling any method in a Google Client. It's a good
idea to make this unique (per user maybe?).

## files

A [Google::Client::Files](https://metacpan.org/pod/Google::Client::Files) client.

# AUTHOR

Ali Zia, `<ziali088@gmail.com>`

# REPOSITORY

[https://github.com/ziali088/googleapi-client](https://github.com/ziali088/googleapi-client)

# COPYRIGHT AND LICENSE

This is free software. You may use it and distribute it under the same terms as Perl itself.
Copyright (C) 2016 - Ali Zia

# TODO

- Catch known Google API errors instead of giving that responsibility to the user of module
- Add more clients
