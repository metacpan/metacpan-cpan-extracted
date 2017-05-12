use utf8;
package Etcd3::Client;

use strict;
use warnings;

use Moo;
use JSON;
use HTTP::Tiny;
use MIME::Base64;
use Etcd3::Auth::Authenticate;
use Etcd3::Auth::Enable;
use Etcd3::Auth::UserAdd;
use Etcd3::Auth::UserDelete;
use Etcd3::Auth::RoleAdd;
use Etcd3::Auth::RoleDelete;
use Etcd3::Auth::UserGrantRole;
use Etcd3::Auth::UserRevokeRole;
use Etcd3::Config;
use Etcd3::Range;
use Etcd3::DeleteRange;
use Etcd3::Put;
use Etcd3::Watch;
use Etcd3::Lease;
use Types::Standard qw(Str Int Bool HashRef);
use Data::Dumper;

use namespace::clean;

=encoding utf8

=head1 NAME

Etcd3::Client

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

Client data for etcd connection

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

has username => (
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

=head2 auth

=cut

has auth => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_auth {
    my ($self) = @_;
    return 1 if ( $self->username and $self->password );
    return;
}

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

base endpoint for api call, refers to api version.

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
        _client => $self,
        %$self
    )->token;
}

=head2 headers

=cut

has headers => ( is => 'lazy' );

sub _build_headers {
    my ($self) = @_;
    my $headers;
    my $auth_token = $self->auth_token if $self->auth;
    $headers->{'Content-Type'} = 'application/json';
    $headers->{'authorization'} = 'Bearer ' . encode_base64( $auth_token, "" ) if $auth_token;
    return $headers;
}

=head2 watch

returns a Etcd3::Watch object.

$etcd->watch({ key =>'foo', range_end => 'fop' })

=cut

sub watch {
    my ( $self, $options ) = @_;
    return Etcd3::Watch->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 user_add

$etcd->user_add({ name =>'foo' password => 'bar' })

=cut

sub user_add {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::UserAdd->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 user_delete

$etcd->user_delete({ name =>'foo' })

=cut

sub user_delete {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::UserDelete->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 role_add

name is the name of the role to add to the authentication system.

$etcd->role_add({ name =>'foo' })

=cut

sub role_add {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::RoleAdd->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 role_delete

$etcd->role_delete({ name =>'foo' })

=cut

sub role_delete {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::RoleDelete->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}


=head2 grant_role

=cut

sub grant_role {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::UserGrantRole->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 revoke_role

=cut

sub revoke_role {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::UserRevokeRole->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 auth_enable

=cut

sub auth_enable {
    my ( $self, $options ) = @_;
    my $auth = Etcd3::Auth::Enable->new( _client => $self )->init;
    return $auth->request;
}

=head2 delete_range

$etcd->delete_range({ key =>'test0', range_end => 'test100', prev_key => 1 })

=cut

sub delete_range {
    my ( $self, $options ) = @_;
    return Etcd3::DeleteRange->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 put

returns a Etcd3::Put object.

=cut

sub put {
    my ( $self, $options ) = @_;
    return Etcd3::Put->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 range

returns a Etcd3::Range object

$etcd->range({ key =>'test0', range_end => 'test100', serializable => 1 })

=cut

sub range {
    my ( $self, $options ) = @_;
    return Etcd3::Range->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head1 LEASE

=head2 lease_grant 

returns a Etcd3::Lease::Grant object
If ID is set to 0, the lessor chooses an ID.

$etcd->lease_grant({ TTL => 20, ID => 7587821338341002662 })

=cut

sub lease_grant {
    my ( $self, $options ) = @_;
    return Etcd3::Lease::Grant->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 lease_revoke 

returns a Etcd3::Lease::Revoke object

$etcd->lease_revoke({ ID => 7587821338341002662 })

=cut

sub lease_revoke {
    my ( $self, $options ) = @_;
    return Etcd3::Lease::Revoke->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 lease_keep_alive 

returns a Etcd3::Lease::KeepAlive object

$etcd->lease_keep_alive({ ID => 7587821338341002662 })

=cut

sub lease_keep_alive {
    my ( $self, $options ) = @_;
    return Etcd3::Lease::KeepAlive->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 lease_ttl 

returns a Etcd3::Lease::TimeToLive object

$etcd->lease_ttl({ ID => 7587821338341002662, keys => 1 })

=cut

sub lease_ttl {
    my ( $self, $options ) = @_;
    return Etcd3::Lease::TimeToLive->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

=head2 configuration

Initialize configuration checks to see it etcd is installed locally.

=cut

sub configuration {
    Etcd3::Config->configuration;
}

sub BUILD {
    my ( $self, $args ) = @_;
    $self->headers;
    if ( not -e $self->configuration->etcd ) {
        my $msg = "No etcd executable found\n";
        $msg .= ">> Please install etcd - https://coreos.com/etcd/docs/latest/";
        die $msg;
    }
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

