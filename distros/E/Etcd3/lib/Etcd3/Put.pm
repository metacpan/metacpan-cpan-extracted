use utf8;
package Etcd3::Put;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::Put

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

Put puts the given key into the key-value store. A put request increments
the revision of the key-value store and generates one event in the event
history.

=head2 endpoint

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/kv/put'
);

=head2 key

key is the key, in bytes, to put into the key-value store.

=cut

has key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) },
);

=head2 value

value is the value, in bytes, to associate with the key in the key-value store.

=cut

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) },
);

=head2 lease

lease is the lease ID to associate with the key in the key-value store. A lease
value of 0 indicates no lease.

=cut

has lease => (
    is  => 'ro',
    isa => Int,
);

=head2 prev_kv

If prev_kv is set, etcd gets the previous key-value pair before changing it.
The previous key-value pair will be returned in the put response.

=cut

has prev_kv => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);

=head2 json_args

arguments that will be sent to the api

=cut

has json_args => ( is => 'lazy', );

sub _build_json_args {
    my ($self) = @_;
    my $args;
    for my $key ( keys %{$self} ) {
        unless ( $key =~ /(?:_client|json_args|endpoint)$/ ) {
            $args->{$key} = $self->{$key};
        }
    }
    return to_json($args);
}

=head2 init

=cut

sub init {
    my ($self) = @_;
    my $init = $self->json_args;
    $init or return;
    return $self;
}

1;
