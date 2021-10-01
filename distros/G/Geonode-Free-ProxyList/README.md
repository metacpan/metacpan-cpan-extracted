[![Actions Status](https://github.com/juliodcs/Geonode-Free-ProxyList/workflows/tests/badge.svg)](https://github.com/juliodcs/Geonode-Free-ProxyList/actions)

# NAME

Geonode::Free::ProxyList - Get Free Geonode Proxies by using some filters

# VERSION

Version 0.0.5

# SYNOPSIS

Get Geonode's free proxy list and apply some filters. You can later choose them by random.

    my $proxy_list = Geonode::Free::ProxyList->new();

    $list->set_filter_google('true');
    $list->set_filter_port(3128);
    $list->set_filter_limit(200);
    
    $list->add_proxies; # Add proxies to the list for current filters    
    
    $list->set_filter_google('false');
    $list->set_filter_port();  # reset filter
    $list->set_filter_limit(); # reset filter
    $list->set_filter_protocol_list( [ 'socks4', 'socks5' ] );
    $list->set_filter_speed('fast');
    
    $list->add_proxies; # Add proxies to the list for current filters
    
    # List of proxies is shuffled
    
    my $some_proxy = $list->get_next;  # Repeats when list is exhausted
    my $other_proxy = $list->get_next; # Repeats when list is exhausted
    
    my $random_proxy = $list->get_random_proxy;  # Can repeat
    
    $some_proxy->get_methods();  # [ 'http', 'socks5' ]
    
    Geonode::Free::Proxy::prefer_socks(); # Will use socks for url, if available
    
    $some_proxy->get_url(); # 'socks://127.0.0.1:3128';
    
    Geonode::Free::Proxy::prefer_http(); # Will use http url, if available
    
    $some_proxy->get_url(); # 'http://127.0.0.1:3128';
    
    $some_proxy->can_use_http();  # 1
    $some_proxy->can_use_socks(); # 1

    $other_proxy->can_use_socks(); # q()
    $other_proxy->can_use_http();  # 1

    Geonode::Free::Proxy::prefer_socks(); # Will use socks for url, if available

    $some_proxy->get_url(); # 'http://foo.bar.proxy:1234';

# Geonode::Free::ProxyList SUBROUTINES/METHODS

## new

Instantiate Geonode::Free::ProxyList object

## reset\_proxy\_list

Clears proxy list

## reset\_filters

Reset filtering options

## set\_filter\_country

Set country filter. Requires a two character uppercase string or undef to reset the filter

## set\_filter\_google

Set google filter. Allowed values are 'true'/'false'. You can use undef to reset the filter

## set\_filter\_port

Set port filter. Allowed values are numbers that does not start by zero. You can use undef to reset the filter

## set\_filter\_protocol\_list

Set protocol list filter. Allowed values are http, https, socks4, socks5. You can use an scalar or a list of values. By using undef you can reset the filter

## set\_filter\_anonymity\_list

Set anonimity list filter. Allowed values are http, https, socks4, socks5. You can use an scalar or a list of values. By using undef you can reset the filter

## set\_filter\_speed

Set speed filter. Allowed values are: fast, medium, slow. You can use undef to reset the filter

## set\_filter\_org

Set organization filter. Requires some non empty string. You can use undef to reset the filter

## set\_filter\_uptime

Set uptime filter. Allowed values are: 0-100 in 10% increments. You can use undef to reset the filter

## set\_filter\_last\_checked

Set last checked filter. Allowed values are: 1-9 and 20-60 in 10% increments. You can use undef to reset the filter

## set\_filter\_limit

Set speed filter. Allowed values are numbers greater than 0. You can use undef to reset the filter

## set\_env\_proxy

Use proxy based on environment variables

See: https://metacpan.org/pod/LWP::UserAgent#env\_proxy

Example:

$proxy\_list->set\_env\_proxy();

## set\_proxy

Exposes LWP::UserAgent's proxy method to configure proxy server

See: https://metacpan.org/pod/LWP::UserAgent#proxy

Example:

$proxy\_list->proxy(\['http', 'ftp'\], 'http://proxy.sn.no:8001/');

## set\_timeout

Set petition timeout. Exposes LWP::UserAgent's timeout method

See: https://metacpan.org/pod/LWP::UserAgent#timeout

Example:

$proxy\_list->timeout(10);

## add\_proxies

Add proxy list according to stored filters

## get\_all\_proxies

Return the whole proxy list

## get\_random\_proxy

Returns a proxy from the list at random (with repetition)

## get\_next

Returns next proxy from the shuffled list (no repetition until list is exhausted)

# Geonode::Free::Proxy SUBROUTINES/METHODS

## new

Instantiate Geonode::Free::Proxy object

## prefer\_socks

Sets preferred method to socks. This is used when getting the full proxy url.

Preferred method is set up \*globally\*.

## prefer\_http

Sets preferred method to http. This is used when getting the full proxy url.

Preferred method is set up \*globally\*.

## get\_preferred\_method

Gets preferred method

## get\_id

Gets proxy id

## get\_host

Gets host

## get\_port

Gets port

## get\_methods

Gets methods

## can\_use\_socks

Returns truthy if proxy can use socks method

## can\_use\_http

Returns truthy if proxy can use http method

## get\_url

Gets proxy url

# AUTHOR

Julio de Castro, `<julio.dcs at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-geonode-free-proxylist at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geonode-Free-ProxyList](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geonode-Free-ProxyList).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geonode::Free::ProxyList

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geonode-Free-ProxyList](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geonode-Free-ProxyList)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Geonode-Free-ProxyList](https://cpanratings.perl.org/d/Geonode-Free-ProxyList)

- Search CPAN

    [https://metacpan.org/release/Geonode-Free-ProxyList](https://metacpan.org/release/Geonode-Free-ProxyList)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Julio de Castro.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
