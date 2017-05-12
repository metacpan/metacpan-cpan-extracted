use utf8;
package Etcd3;

# ABSTRACT: Provide access to the etcd v3 API.

use strict;
use warnings;

use Etcd3::Client;
use Data::Dumper;

use namespace::clean;

=encoding utf8

=head1 NAME

Etcd3

=head1 VERSION

Version 0.004

=cut

our $VERSION = '0.005';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Perl access to Etcd v3 API.

=head2 host

=cut

=head2 connect

    $etcd = Etcd3->connect(); # host: 127.0.0.1 port: 2379
    $etcd = Etcd3->connect($host);
    $etcd = Etcd3->connect($host, $options);

This function returns a L<Etcd3::Client> object.  The first parameter is the 
C<host> argument.  The second C<options> is a hashref.

=cut

sub connect {
    my ( $self, $host, $options ) = @_;
    $host ||= "127.0.0.1";
    $options ||= {};
    $options->{host} = $host;
    $options->{name} = $options->{user} if defined $options->{user};
    return Etcd3::Client->new($options);
}

=head1 AUTHOR

Sam Batschelet, <sbatschelet at mac.com>

=head1 ACKNOWLEDGEMENTS

The L<etcd> developers and community.

=head1 CAVEATS

The L<etcd> v3 API is in heavy development and can change at anytime please see
https://github.com/coreos/etcd/blob/master/Documentation/dev-guide/api_reference_v3.md
for latest details.


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Sam Batschelet (hexfusion).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

