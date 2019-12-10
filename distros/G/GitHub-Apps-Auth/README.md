# NAME

GitHub::Apps::Auth - The fetcher that get a token for GitHub Apps

# SYNOPSIS

    use GitHub::Apps::Auth;
    my $auth = GitHub::Apps::Auth->new(
        private_key     => "<filename>", # when read private key from file
        private_key     => \$pk,         # when read private key from variable
        app_id          => <app_id>,
        login           => <organization or user>
    );
    # This method returns the cached token inside an object.
    # However, refresh expired token automatically.
    my $token  = $auth->issued_token;

    # If you want to use with Pithub
    use Pithub;
    # GitHub::Apps::Auth object behaves like a string.
    # This object calls the `issued_token` method
    # each time it evaluates as a string.
    my $ph = Pithub->new(token => $auth, ...);

# DESCRIPTION

GitHub::Apps::Auth is the fetcher for getting a GitHub token of GitHub Apps.

This module provides a way to get a token that need to be updated regularly for GitHub API.

# CONSTRUCTOR

## new

    my $auth = GitHub::Apps::Auth->new(
        private_key     => "<filename>",
        app_id          => <app_id>,
        installation_id => <installation_id>
    );

Constructs an instance of `GitHub::Apps::Auth` from credentials.

### parameters

#### private\_key

**Required: true**

This parameter is a private key of the GitHub Apps.

This must be a filename or string in the pem format. You can get a private key from Settings page of GitHub Apps. See [Generating a private key](https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps/#generating-a-private-key).

#### app\_id

**Required: true**

This parameter is the App ID of your GitHub Apps. Use the `App ID` in the About section of your GitHub Apps page.

#### installation\_id

**Required: exclusive to** `login`

A `installation_id` is an identifier of installation Organizations or repositories in GitHub Apps. This value is can be obtained from a webhook that is fired during installation. Also can be obtained from webhook's `Recent Deliveries` of GitHub apps settings.

#### login

**Required: exclusive to** `installation_id`

`login` is used for detecting installation\_id. If not set `installation_id` and set `login`, search `installation_id` from the list of installations.

# METHODS

## issued\_token

    my $token  = $auth->issued_token;

`issued_token` returns a API token in string. This token is cached while valid.

When calling this method with condition that expired token, this method refreshes a token automatically.

## token

This method returns an API token. Unlike `issued_token`, this method not refresh an expired token.

## expires

This returns the token expiration date in the epoch.

# OPERATOR OVERLOADS

`GitHub::Apps::Auth` is overloaded so that `issued_token` is called when evaluated as a string. So probably be usable in GitHub client that use raw string API token. Ex [Pithub](https://metacpan.org/pod/Pithub).

# SEE ALSO

[Authenticating with GitHub Apps](https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps)

# LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mackee <macopy123@gmail.com>
