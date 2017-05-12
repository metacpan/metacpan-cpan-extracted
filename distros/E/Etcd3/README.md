[![Build Status](https://api.travis-ci.org/hexfusion/perl-etcd3.svg?branch=master)](https://travis-ci.org/hexfusion/perl-etcd3)

# NAME

Etcd3

# VERSION

Version 0.005

# SYNOPSIS

    Etcd v3.1.0-alpha.0 or greater is required.   To use the v3 API make sure to set environment
    variable ETCDCTL_API=3.  Precompiled binaries can be downloaded at https://github.com/coreos/etcd/releases.

    $etcd = Etcd3->connect(); # host: 127.0.0.1 port: 2379
    $etcd = Etcd3->connect( $host, { username => 'HeMan', password =>'GreySkuLz', ssl => '1'});

    # put key
    $result = $etcd->put({ key =>'foo1', value => 'bar' });

    # get single key
    $key = $etcd->range({ key =>'test0' });

    [or]

    $key = $etcd->get({ key =>'test0' });

    # return single key value or the first in a list.
    $key->get_value

    # get range of keys
    $range = $etcd->range({ key =>'test0', range_end => 'test100' });

    # return array { key => value } pairs from range request.
    my @users = $range->all

    # watch key
    $etcd->range({ key =>'foo', range_end => 'fop' });

# DESCRIPTION

Perl access to Etcd v3 API.

## host

## connect

    $etcd = Etcd3->connect(); # host: 127.0.0.1 port: 2379
    $etcd = Etcd3->connect($host);
    $etcd = Etcd3->connect($host, $options);

This function returns a [Etcd3::Client](https://metacpan.org/pod/Etcd3::Client) object.  The first parameter is the 
`host` argument.  The second `options` is a hashref.

# AUTHOR

Sam Batschelet, &lt;sbatschelet at mac.com>

# ACKNOWLEDGEMENTS

The [etcd](https://metacpan.org/pod/etcd) developers and community.

# CAVEATS

The [etcd](https://metacpan.org/pod/etcd) v3 API is in heavy development and can change at anytime please see
https://github.com/coreos/etcd/blob/master/Documentation/dev-guide/api\_reference\_v3.md
for latest details.

# LICENSE AND COPYRIGHT

Copyright 2017 Sam Batschelet (hexfusion).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
