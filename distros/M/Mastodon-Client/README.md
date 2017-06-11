# NAME

Mastodon::Client - Talk to a Mastodon server

# SYNOPSIS

    use Mastodon::Client;

    my $client = Mastodon::Client->new(
      instance        => 'mastodon.social',
      name            => 'PerlBot',
      client_id       => $client_id,
      client_secret   => $client_secret,
      access_token    => $access_token,
      coerce_entities => 1,
    );

    $client->post_status('Posted to a Mastodon server!');
    $client->post_status('And now in secret...',
      { visibility => 'unlisted ' }
    )

    # Streaming interface might change!
    my $listener = $client->stream( 'public' );
    $listener->on( update => sub {
      my ($listener, $status) = @_;
      printf "%s said: %s\n",
        $status->account->display_name,
        $status->content;
    });
    $listener->start;

# DESCRIPTION

Mastodon::Client lets you talk to a Mastodon server to obtain authentication
credentials, read posts from timelines in both static or streaming mode, and
perform all the other operations exposed by the Mastodon API.

Most of these are available through the convenience methods listed below, which
validate input parameters and are likely to provide more meaningful feedback in
case of errors.

Alternatively, this distribution can be used via the low-level request methods
(**post**, **get**, etc), which allow direct access to the API endpoints. All
other methods call one of these at some point.

# ATTRIBUTES

- **instance**

    A Mastodon::Entity::Instance object representing the instance to which this
    client will speak. Defaults to `mastodon.social`.

- **api\_version**

    An integer specifying the version of the API endpoints to use. Defaults to `1`.

- **redirect\_uri**

    The URI to which authorization codes should be forwarded as part of the OAuth2
    flow. Defaults to `urn:ietf:wg:oauth:2.0:oob` (meaning no redirection).

- **user\_agent**

    The user agent to use for the requests. Defaults to an instance of
    [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent). It is expected to have a `request` method that accepts
    instances of [HTTP::Request](https://metacpan.org/pod/HTTP::Request) objects.

- **coerce\_entities**

    A boolean value. Set to true if you want Mastodon::Client to internally coerce
    all response entities to objects. This adds a level of validation, and can
    make the objects easier to use.

    Although this does require some additional processing, the coercion is done by
    [Type::Tiny](https://metacpan.org/pod/Type::Tiny), so the impact is negligible.

    For now, it defaults to **false** (but this will likely change, so I recommend
    you use it).

- **access\_token**

    The access token of your client. This is provided by the Mastodon API and is
    used for the OAuth2 authentication required for most API calls.

    You can get this by calling **authorize** with either an access code or your
    account's username and password.

- **authorized**

    Boolean. False is the client has no defined access\_token. When an access token
    is set, this is set to true or to a [DateTime](https://metacpan.org/pod/DateTime) object representing the time of
    authorization if possible (as received from the server).

- **client\_id**
- **client\_secret**

    The client ID and secret are provided by the Mastodon API when you register
    your client using the **register** method. They are used to identify where your
    calls are coming from, and are required before you can use the **authorize**
    method to get the access token.

- **name**

    Your client's name. This is required when registering, but is otherwise seldom
    used. If you are using the **authorization\_url** to get an access code from your
    users, then they will see this name when they go to that page.

- **account**

    Holds the authenticated account. It is set internally by the **get\_account**
    method.

- **scopes**

    This array reference holds the scopes set by you for the client. These are
    required when registering your client with the Mastodon instance. Defaults to
    `read`.

    Mastodon::Client will internally make sure that the scopes you were provided
    when calling **authorize** match those that you requested. If this is not the
    case, it will helpfully die.

- **website**

    The URL of a human-readable website for the client. If made available, it
    appears as a link in the "authorized applications" tab of the user preferences
    in the default Mastodon web GUI. Defaults to the empty string.

# METHODS

## Authorizing an application

Although not all of the API methods require authentication to be used, most of
them do. The authentication process involves a) registering an application with
a Mastodon server to obtain a client secret and ID; b) authorizing the
application by either providing a user's credentials, or by using an
authentication URL.

The methods facilitating this process are detailed below:

- **register()**
- **register($data)**

    Obtain a client secret and ID from a given mastodon instance. Takes a single
    hash reference as an argument, with the following possible keys:

    - **redirect\_uris**

        The URL to which authorization codes should be forwarded after authorized by
        the user. Defaults to the value of the **redirect\_uri** attribute.

    - **scopes**

        The scopes requested by this client. Defaults to the value of the **scopes**
        attribute.

    - **website**

        The client's website. Defaults to the value of the `website` attribute.

    When successful, sets the `client_secret` and `client_id` attributes of
    the Mastodon::Client object and returns the modified object.

    This should be called **once** per client and its contents cached locally.

- **authorization\_url()**

    Generate an authorization URL for the given application. Accessing this URL
    via a browser by a logged in user will allow that user to grant this
    application access to the requested scopes. The scopes used are the ones in the
    **scopes** attribute at the time this method is called.

- **authorize()**
- **authorize( %data )**

    Grant the application access to the requested scopes for a given user. This
    method takes a hash with either an access code or a user's login credentials to
    grant authorization. Valid keys are:

    - **access\_code**

        The access code obtained by visiting the URL generated by **authorization\_url**.

    - **username**
    - **password**

        The user's login credentials.

    When successful, the method automatically sets the client's **authorized**
    attribute to a true value and caches the **access\_token** for all future calls.

The remaining methods listed here follow the order of those in the official API
documentation.

## Accounts

- **get\_account()**
- **get\_account($id)**
- **get\_account($params)**
- **get\_account($id, $params)**

    Fetches an account by ID. If no ID is provided, this defaults to the current
    authenticated account. Global GET parameters are available for this method.

    Depending on the value of `coerce_entities`, it returns a
    Mastodon::Entity::Account object, or a plain hash reference.

- **update\_account($params)**

    Make changes to the authenticated account. Takes a hash reference with the
    following possible keys:

    - **display\_name**
    - **note**

        Strings

    - **avatar**
    - **header**

        A base64 encoded image, or the name of a file to be encoded.

    Depending on the value of `coerce_entities`, returns the modified
    Mastodon::Entity::Account object, or a plain hash reference.

- **followers()**
- **followers($id)**
- **followers($params)**
- **followers($id, $params)**

    Get the list of followers of an account by ID. If no ID is provided, the one
    for the current authenticated account is used. Global GET parameters are
    available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

- **following()**
- **following($id)**
- **following($params)**
- **following($id, $params)**

    Get the list of accounts followed by the account specified by ID. If no ID is
    provided, the one for the current authenticated account is used. Global GET
    parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

- **statuses()**
- **statuses($id)**
- **statuses($params)**
- **statuses($id, $params)**

    Get a list of statuses from the account specified by ID. If no ID is
    provided, the one for the current authenticated account is used.

    In addition to the global GET parameters, this method accepts the following
    parameters:

    - **only\_media**
    - **exclude\_replies**

        Both boolean.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Status objects, or a plain array reference.

- **follow($id)**
- **unfollow($id)**

    Follow or unfollow an account specified by ID. The ID argument is mandatory.

    Depending on the value of `coerce_entities`, returns the new
    Mastodon::Entity::Relationship object, or a plain hash reference.

- **block($id)**
- **unblock($id)**

    Block or unblock an account specified by ID. The ID argument is mandatory.

    Depending on the value of `coerce_entities`, returns the new
    Mastodon::Entity::Relationship object, or a plain hash reference.

- **mute($id)**
- **unmute($id)**

    Mute or unmute an account specified by ID. The ID argument is mandatory.

    Depending on the value of `coerce_entities`, returns the new
    Mastodon::Entity::Relationship object, or a plain hash reference.

- **relationships(@ids)**
- **relationships(@ids, $params)**

    Get the list of relationships of the current authenticated user with the
    accounts specified by ID. At least one ID is required, but more can be passed
    at once. Global GET parameters are available for this method, and can be passed
    as an additional hash reference as a final argument.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Relationship objects, or a plain array reference.

- **search\_accounts($query)**
- **search\_accounts($query, $params)**

    Search for accounts. Takes a mandatory string argument to use as the search
    query. If the search query is of the form `username@domain`, the accounts
    will be searched remotely.

    In addition to the global GET parameters, this method accepts the following
    parameters:

    - **limit**

        The maximum number of matches. Defaults to 40.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

    This method does not require authentication.

## Blocks

- **blocks()**
- **blocks($params)**

    Get the list of accounts blocked by the authenticated user. Global GET
    parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

## Favourites

- **favourites()**
- **favourites($params)**

    Get the list of statuses favourited by the authenticated user. Global GET
    parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Status objects, or a plain array reference.

## Follow requests

- **follow\_requests()**
- **follow\_requests($params)**

    Get the list of accounts requesting to follow the the authenticated user.
    Global GET parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

- **authorize\_follow($id)**
- **reject\_follow($id)**

    Accept or reject the follow request by the account of the specified ID. The ID
    argument is mandatory.

    Returns an empty object.

## Follows

- **remote\_follow($acct)**

    Follow a remote user by account string (ie. `username@domain`). The argument
    is mandatory.

    Depending on the value of `coerce_entities`, returns an
    Mastodon::Entity::Account object, or a plain hash reference with the local
    representation of the specified account.

## Instances

- **fetch\_instance()**

    Fetches the latest information for the current instance the client is talking
    to. When successful, this method updates the value of the `instance`
    attribute.

    Depending on the value of `coerce_entities`, returns an
    Mastodon::Entity::Instance object, or a plain hash reference.

    This method does not require authentication.

## Media

- **upload\_media($file)**

    Upload a file as an attachment. Takes a single argument with the name of a
    local file to encode and upload. The argument is mandatory.

    Depending on the value of `coerce_entities`, returns an
    Mastodon::Entity::Attachment object, or a plain hash reference.

    The returned object's ID can be passed to the **post\_status** to post it to a
    timeline.

## Mutes

- **mutes()**
- **mutes($params)**

    Get the list of accounts muted by the authenticated user. Global GET
    parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

## Notifications

- **notifications()**
- **notifications($params)**

    Get the list of notifications for the authenticated user. Global GET
    parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Notification objects, or a plain array reference.

- **get\_notification($id)**

    Get a notification by ID. The argument is mandatory.

    Depending on the value of `coerce_entities`, returns an
    Mastodon::Entity::Notification object, or a plain hash reference.

- **clear\_notifications()**

    Clears all notifications for the authenticated user.

    This method takes no arguments and returns an empty object.

## Reports

- **reports()**
- **reports($params)**

    Get a list of reports made by the authenticated user. Global GET
    parameters are available for this method.

    Depending on the value of `coerce_entities`, returns an array reference of
    Mastodon::Entity::Report objects, or a plain array reference.

- **report($params)**

    Report a user or status. Takes a mandatory hash with the following keys:

    - **account\_id**

        The ID of a single account to report.

    - **status\_ids**

        The ID of a single status to report, or an array reference of statuses to
        report.

    - **comment**

        An optional string.

    While the comment is always optional, either the **account\_id** or the list of
    **status\_ids** must be present.

    Depending on the value of `coerce_entities`, returns the new
    Mastodon::Entity::Report object, or a plain hash reference.

## Search

- **search($query)**
- **search($query, $params)**

    Search for content. Takes a mandatory string argument to use as the search
    query. If the search query is a URL, Mastodon will attempt to fetch the
    provided account or status. Otherwise, it will do a local account and hashtag
    search.

    In addition to the global GET parameters, this method accepts the following
    parameters:

    - **resolve**

        Whether to resolve non-local accounts.

## Statuses

- **get\_status($id)**
- **get\_status($id, $params)**

    Fetches a status by ID. The ID argument is mandatory. Global GET parameters are available for this method as an additional hash reference.

    Depending on the value of `coerce_entities`, it returns a
    Mastodon::Entity::Status object, or a plain hash reference.

    This method does not require authentication.

- **get\_status\_context($id)**
- **get\_status\_context($id, $params)**

    Fetches the context of a status by ID. The ID argument is mandatory. Global GET parameters are available for this method as an additional hash reference.

    Depending on the value of `coerce_entities`, it returns a
    Mastodon::Entity::Context object, or a plain hash reference.

    This method does not require authentication.

- **get\_status\_card($id)**
- **get\_status\_card($id, $params)**

    Fetches a card associated to a status by ID. The ID argument is mandatory.
    Global GET parameters are available for this method as an additional hash
    reference.

    Depending on the value of `coerce_entities`, it returns a
    Mastodon::Entity::Card object, or a plain hash reference.

    This method does not require authentication.

- **get\_status\_reblogs($id)**
- **get\_status\_reblogs($id, $params)**
- **get\_status\_favourites($id)**
- **get\_status\_favourites($id, $params)**

    Fetches a list of accounts who have reblogged or favourited a status by ID.
    The ID argument is mandatory. Global GET parameters are available for this
    method as an additional hash reference.

    Depending on the value of `coerce_entities`, it returns an array reference of
    Mastodon::Entity::Account objects, or a plain array reference.

    This method does not require authentication.

- **post\_status($text)**
- **post\_status($text, $params)**

    Posts a new status. Takes a mandatory string as the content of the status
    (which can be the empty string), and an optional hash reference with the
    following additional parameters:

    - **status**

        The content of the status, as a string. Since this is already provided as the
        first argument of the method, this is not necessary. But if provided, this
        value will overwrite that of the first argument.

    - **in\_reply\_to\_id**

        The optional ID of a status to reply to.

    - **media\_ids**

        An array reference of up to four media IDs. These can be obtained as the result
        of a call to **upload\_media()**.

    - **sensitive**

        Boolean, to mark status content as NSFW.

    - **spoiler\_text**

        A string, to be shown as a warning before the actual content.

    - **visibility**

        A string; one of `direct`, `private`, `unlisted`, or `public`.

    Depending on the value of `coerce_entities`, it returns the new
    Mastodon::Entity::Status object, or a plain hash reference.

- **delete\_status($id)**

    Delete a status by ID. The ID is mandatory. Returns an empty object.

- **reblog($id)**
- **unreblog($id)**
- **favourite($id)**
- **unfavourite($id)**

    Reblog or favourite a status by ID, or revert this action. The ID argument is
    mandatory.

    Depending on the value of `coerce_entities`, it returns the specified
    Mastodon::Entity::Status object, or a plain hash reference.

## Timelines

- **timeline($query)**
- **timeline($query, $params)**

    Retrieves a timeline. The first argument defines either the name of a timeline
    (which can be one of `home` or `public`), or a hashtag (if it begins with the
    `#` character). This argument is mandatory.

    In addition to the global GET parameters, this method accepts the following
    parameters:

    Accessing the public and tag timelines does not require authentication.

    - **local**

        Boolean. If true, limits results only to those originating from the current
        instance. Only applies to public and tag timelines.

    Depending on the value of `coerce_entities`, it returns an array of
    Mastodon::Entity::Status objects, or a plain array reference. The more recent
    statuses come first.

# STREAMING RESULTS

Alternatively, it is possible to use the streaming API to get a constant stream
of updates. To do this, there is the **stream()** method.

- **stream($query)**

    Creates a Mastodon::Listener object which will fetch a stream for the
    specified query. Possible values for the query are either `user`, for events
    that are relevant to the authorized user; `public`, for all public statuses;
    or a tag (if it begins with the `#` character), for all public statuses for
    the particular tag.

    For more details on how to use this object, see the documentation for
    [Mastodon::Listener](https://metacpan.org/pod/Mastodon::Listener).

    Accessing streaming public timeline does not require authentication.

# REQUEST METHODS

Mastodon::Client uses four lower-level request methods to contact the API
with GET, POST, PATCH, and DELETE requests. These are left available in case
one of the higher-level convenience methods are unsuitable or undesirable, but
you use them at your own risk.

They all take a URL as their first parameter, which can be a string with the
API endpoint to contact, or a [URI](https://metacpan.org/pod/URI) object, which will be used as-is.

If passed as a string, the methods expect one that contains only the variable
parts of the endpoint (ie. not including the `HOST/api/v1` part). The
remaining parts will be filled-in appropriately internally.

- **delete($url)**
- **get($url)**
- **get($url, $params)**

    Query parameters can be passed as part of the [URI](https://metacpan.org/pod/URI) object, but it is not
    recommended you do so, since Mastodon has expectations for array parameters
    that do not meet those of eg. [URI::QueryParam](https://metacpan.org/pod/URI::QueryParam). It will be easier and safer
    if any additional parameters are passed as a hash reference, which will be
    added to the URL before the request is sent.

- **post($url)**
- **post($url, $data)**
- **patch($url)**
- **patch($url, $data)**

    the `post` and `patch` methods work similarly to `get` and `delete`, but
    the optional hash reference is sent in as form data, instead of processed as
    query parameters. The Mastodon API does not use query parameters on POST or
    PATCH endpoints.

# CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
[GitLab](https://gitlab.com/jjatria/Mastodon-Client), which is where patches
and bug reports are mainly tracked. The repository is also mirrored on
[Github](https://github.com/jjatria/Mastodon-Client), in case that platform
makes it easier to post contributions.

If none of the above is acceptable, bug reports can also be sent through the
CPAN RT system, or by mail directly to the developers at the address below,
although these will not be as closely tracked.

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>

# CONTRIBUTORS

- Lance Wicks <lancew@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
