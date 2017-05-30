use utf8;
package Etcd3;
# ABSTRACT: [depricated] Please see Net::Etcd.

use strict;
use warnings;

use Moo;
use JSON;
use MIME::Base64;
use Etcd3::Auth;
use Etcd3::Config;
use Etcd3::Watch;
use Etcd3::Lease;
use Etcd3::User;
use Types::Standard qw(Str Int Bool HashRef);

with('Etcd3::KV');

use namespace::clean;

=encoding utf8

=head1 NAME

Etcd3

=cut

our $VERSION = '0.007';

=head1 SYNOPSIS

    Etcd v3.1.0 or greater is required.   To use the v3 API make sure to set environment
    variable ETCDCTL_API=3.  Precompiled binaries can be downloaded at https://github.com/coreos/etcd/releases.

    $etcd = Etcd3->new(); # host: 127.0.0.1 port: 2379
    $etcd = Etcd3->new({ host => $host, port => $port, ssl => 1 });

    # put key
    $result = $etcd->put({ key =>'foo1', value => 'bar' });

    # get single key
    $key = $etcd->range({ key =>'test0' });

    # return single key value or the first in a list.
    $key->get_value

    # get range of keys
    $range = $etcd->range({ key =>'test0', range_end => 'test100' });

    # return array { key => value } pairs from range request.
    my @users = $range->all

    # watch key range, streaming.
    $watch = $etcd->watch( { key => 'foo', range_end => 'fop'}, sub {
        my ($result) =  @_;
        print STDERR Dumper($result);
    })->create;

    # create/grant 20 second lease
    $etcd->lease( { ID => 7587821338341002662, TTL => 20 } )->grant;

    # attach lease to put
    $etcd->put( { key => 'foo2', value => 'bar2', lease => 7587821338341002662 } );

=head1 DESCRIPTION

This module has been superseded by L<Net::Etcd> and will be removed from CPAN on June 29th 2017


=head1 ACCESSORS

=head2 host

=cut

has host => (
    is      => 'ro',
    isa     => Str,
    default => '127.0.0.1'
);

=head2 port

=cut

has port => (
    is      => 'ro',
    isa     => Int,
    default => '2379'
);

=head2 username

=cut

has name => (
    is  => 'ro',
    isa => Str
);

=head2 password

=cut

has password => (
    is  => 'ro',
    isa => Str
);

=head2 ssl

=cut

has ssl => (
    is  => 'ro',
    isa => Bool,
);

=head2 api_root

=cut

has api_root => ( is => 'lazy' );

sub _build_api_root {
    my ($self) = @_;
    return
        ( $self->ssl ? 'https' : 'http' ) . '://'
      . $self->host . ':'
      . $self->port;
}

=head2 api_prefix

defaults to /v3alpha

=cut

has api_prefix => (
    is      => 'ro',
    isa     => Str,
    default => '/v3alpha'
);

=head2 api_path

=cut

has api_path => ( is => 'lazy' );

sub _build_api_path {
    my ($self) = @_;
    return $self->api_root . $self->api_prefix;
}

=head2 auth_token

=cut

has auth_token => ( is => 'lazy' );

sub _build_auth_token {
    my ($self) = @_;
    return Etcd3::Auth::Authenticate->new(
        etcd => $self,
        %$self
    )->token;
}

=head1 PUBLIC METHODS

=head2 watch

Returns a L<Etcd3::Watch> object.

    $etcd->watch({ key =>'foo', range_end => 'fop' })

=cut

sub watch {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Etcd3::Watch->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 role

Returns a L<Etcd3::Auth::Role> object.

    $etcd->role({ role => 'foo' });

=cut

sub role {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Etcd3::Auth::Role->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 user_role

Returns a L<Etcd3::User::Role> object.

    $etcd->user_role({ name => 'samba', role => 'foo' });

=cut

sub user_role {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Etcd3::User::Role->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 auth

Returns a L<Etcd3::Auth> object.

=cut

sub auth {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Etcd3::Auth->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 lease

Returns a L<Etcd3::Lease> object.

=cut

sub lease {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Etcd3::Lease->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 user

Returns a L<Etcd3::User> object.

=cut

sub user {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Etcd3::User->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 put

Returns a L<Etcd3::KV::Put> object.

=cut

=head2 range

Returns a L<Etcd3::KV::Range> object.

=cut

=head2 configuration

Initialize configuration checks to see it etcd is installed locally.

=cut

sub configuration {
    Etcd3::Config->configuration;
}

sub BUILD {
    my ( $self, $args ) = @_;
    if ( not -e $self->configuration->etcd ) {
        my $msg = "No etcd executable found\n";
        $msg .= ">> Please install etcd - https://coreos.com/etcd/docs/latest/";
        die $msg;
    }
}

=head1 AUTHOR

Sam Batschelet, <sbatschelet at mac.com>

=head1 ACKNOWLEDGEMENTS

The L<etcd|https://github.com/coreos/etcd> developers and community.

=head1 CAVEATS

The L<etcd|https://github.com/coreos/etcd> v3 API is in heavy development and can change at anytime please see
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
