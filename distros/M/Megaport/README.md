[![Build Status](https://travis-ci.org/ccakes/megaport-perl.svg?branch=master)](https://travis-ci.org/ccakes/megaport-perl) [![MetaCPAN Release](https://badge.fury.io/pl/Megaport.svg)](https://metacpan.org/release/Megaport)
Megaport - Simple access to the [Megaport](https://www.megaport.com) API

# SYNOPSIS

    use Megaport;

    # Using an existing session token
    my $mp = Megaport->new(token => 'your-session-token');

    # Using a username/password combo
    my $mp = Megaport->new(username => 'me@example.com', password => 's3cr3t');

    # Get a list of locations (on-net datacentres)
    my @locations = $mp->session->locations->list;

    # Get a partial list
    my @locations = $mp->session->locations->list(country => 'Australia');
    my @locations = $mp->session->locations->list(name => qr/^Digital Realty/);

    # Get a single entry
    my $global_switch = $mp->session->locations->get(id => 3);

    # Services
    my $services = $mp->session->services;
    $services->list(...);
    $services->get(...);

    # Other Megaports on the network
    my $ports = $mp->session->ports;
    $ports->list(...);

# DESCRIPTION

This module provides a Perl interface to the [Megaport](https://www.megaport.com) API. This is largely to fill my own requirements and for now is read only. Read/write functionality will be added over time to support service modification.

# METHODS

## new

    my $mp = Megaport->new(
      token => 'your-session-token',
      uri => 'https://api.megaport.com/v2',
      debug => 0,
      no_verify => 0
    );

The fields `token`, `username` and `password` are all auth relatated and should be fairly self explanatory. If you're unsure about token, take a look at the [Megaport docs](https://dev.megaport.com/#security).

`debug` enables extra output to STDERR during API calls. [Megaport::Client](https://metacpan.org/pod/Megaport::Client) by default will validate the token or user credentials by making a POST call to the Megaport API, set `no_verify` to stop this and speed things up.

As at this writing, the production Megaport API is at https://api.megaport.com with a test environment mentioned in the documentation at https://api-staging.megaport.com. If you wish to change environments, set `uri`.

## session

    my $session = $mp->session;

Returns a [Megaport::Session](https://metacpan.org/pod/Megaport::Session) object which contains an authenticated client ready to start making calls.

# TODO

- Module/helper for per-service type to make data access easier
    - Dig into VXCs/IX from top level service
    - Access pricing/cost estimate info per service
- Simple service modification, speed/VLAN etc
- Helper method to link partner ports and location to make searching by city/country/region easier
- Company object with access to users, invoices and outstanding balance

# AUTHOR

Cameron Daniel <cdaniel@cpan.org>
