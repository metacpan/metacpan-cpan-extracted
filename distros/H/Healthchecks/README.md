# SYNOPSIS

    use Healthchecks;
    my $hc = Healthchecks->new(
      url      => 'http://hc.example.org',
      apikey   => 'secret_healthchecks_API_key',
      user     => 'http_user',
      password => 'http_password',
      proxy    => {
          http  => 'http://proxy.example.org',
          https => 'http://proxy.example.org'
      }
    );

    $hc->get_check('uuid_or_unique_key');

# DESCRIPTION

Client module for [Healthchecks](https://healthchecks.io/) [HTTP API](https://healthchecks.io/docs/api/).

# ATTRIBUTES

[Healthchecks](https://metacpan.org/pod/Healthchecks) implements the following attributes.

## url

    my $url = $hc->url;
    $hc     = $hc->url('http://hc.example.org');

MANDATORY. The Healthchecks URL, no default.

## apikey

    my $apikey = $hc->apikey;
    $hc        = $hc->apikey('secret_etherpad_API_key');

MANDATORY. Secret API key, no default

## ua

    my $ua = $hc->ua;
    $hc    = $hc->ua(Mojo::UserAgent->new);

OPTIONAL. User agent, default to a Mojo::UserAgent. Please, don't use anything other than a Mojo::Useragent.

## user

    my $user = $hc->user;
    $hc      = $hc->user('bender');

OPTIONAL. HTTP user, use it if your Healthchecks is protected by a HTTP authentication, no default.

## password

    my $password = $hc->password;
    $hc          = $hc->password('beer');

OPTIONAL. HTTP password, use it if your Healthchecks is protected by a HTTP authentication, no default.

## proxy

    my $proxy = $hc->proxy;
    $hc       = $hc->proxy({
      http  => 'http://proxy.example.org',
      https => 'http://proxy.example.org'
    });

OPTIONAL. Proxy settings. If set to { detect => 1 }, Healthchecks will check environment variables HTTP\_PROXY, http\_proxy, HTTPS\_PROXY, https\_proxy, NO\_PROXY and no\_proxy for proxy information. No default.

# METHODS

Healthchecks inherits all methods from Mojo::Base and implements the following new ones.

### get\_all\_checks

    Usage     : $hc->get_all_checks();
    Purpose   : Get all checks
    Returns   : An array of checks belonging to the user, optionally filtered by one or more tags.
    Argument  : None
    See       : https://healthchecks.io/docs/api/#list-checks

### get\_check

    Usage     : $hc->get_check('uuid_or_unique_key');
    Purpose   : Get details of a check
    Returns   : A hash, representation of a single check. 
    Argument  : Accepts either check's UUID or the unique_key (a field derived from UUID and returned by API responses when using the read-only API key) as argument.
                MANDATORY
    See       : https://healthchecks.io/docs/api/#get-check

### create\_check

    Usage     : $hc->({name => 'foobarbaz'});
    Purpose   : Create a check
    Returns   : A hash, representation of a single check. 
    Argument  : A hash of the check’s options (see API documentation)
                OPTIONAL
    See       : https://healthchecks.io/docs/api/#create-check

### update\_check

    Usage     : $hc->update_check('uuid', { name => 'quux' });
    Purpose   : Update the configuration of a check
    Returns   : A hash, representation of a single check.
    Argument  : The check's UUID (MANDATORY) and a hash of the check’s options (see API documentation)
                OPTIONAL
    See       : https://healthchecks.io/docs/api/#update-check

### pause\_check

    Usage     : $hc->pause_check('uuid');
    Purpose   : Disables monitoring for a check without removing it. The check goes into a "paused" state. You can resume monitoring of the check by pinging it.
    Returns   : A boolean : true if the check is paused, false otherwise.
    Argument  : The check's UUID
                MANDATORY
    See       : https://healthchecks.io/docs/api/#pause-check

### delete\_check

    Usage     : $hc->delete_check('uuid');
    Purpose   : Permanently deletes the check from the user's account.
    Returns   : A boolean : true if the check has been successfully deleted, false otherwise.
    Argument  : The check's UUID
                MANDATORY
    See       : https://healthchecks.io/docs/api/#delete-check

### get\_check\_pings

    Usage     : $hc->get_check_pings('uuid');
    Purpose   : Get the pings of a check.
    Returns   : An array of pings this check has received.
    Argument  : The check's UUID
                MANDATORY
    See       : https://healthchecks.io/docs/api/#list-pings

### get\_check\_flips

    Usage     : $hc->get_check_flips('uuid_or_unique_key', { seconds => 3, start => 1592214380, end => 1592217980});
    Purpose   : Get the "flips" of a check has experienced.
    Returns   : An array of the "flips" the check has experienced. A flip is a change of status (from "down" to "up," or from "up" to "down").
    Argument  : Accepts either check's UUID or the unique_key (a field derived from UUID and returned by API responses when using the read-only API key) as argument.
                MANDATORY
                You can specify an optional hash table to add parameters as query string (see API documentation)
    See       : https://healthchecks.io/docs/api/#list-flips

### get\_integrations

    Usage     : $hc->get_all_checks();
    Purpose   : Get a list of existing integrations
    Returns   : An array of integrations belonging to the project.
    Argument  : None
    See       : https://healthchecks.io/docs/api/#list-channels

### ping\_check

    Usage     : $hc->ping_check('uuid');
    Purpose   : Ping a check
    Returns   : A boolean : true if the check has been successfully pinged, false otherwise.
    Argument  : The check's UUID
                MANDATORY
    See       : This is not part of the Healthchecks API but a facility offered by this module

# INSTALL

After getting the tarball on https://metacpan.org/release/Healthchecks, untar it, go to the directory and:

    perl Makefile.PL
    make
    make test
    make install

If you are on a windows box you should use 'nmake' rather than 'make'.

# BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Healthchecks

Bugs and feature requests will be tracked on:

    https://framagit.org/fiat-tux/perl-modules/healthchecks/issues

The latest source code can be browsed and fetched at:

    https://framagit.org/fiat-tux/perl-modules/healthchecks
    git clone https://framagit.org/fiat-tux/perl-modules/healthchecks.git

Source code mirror:

    https://github.com/ldidry/etherpad

You can also look for information at:

    AnnoCPAN: Annotated CPAN documentation

    http://annocpan.org/dist/Healthchecks
    CPAN Ratings

    http://cpanratings.perl.org/d/Healthchecks
    Search CPAN

    http://search.cpan.org/dist/Healthchecks

# AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

# LICENSE

Copyright (C) Luc Didry.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
