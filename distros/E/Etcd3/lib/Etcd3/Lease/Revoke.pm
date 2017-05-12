use utf8;
package Etcd3::Lease::Revoke;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::Lease::Revoke

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

LeaseRevoke revokes a lease. All keys attached to the lease will expire and be deleted.

=head2 endpoint

/kv/lease/revoke

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/kv/lease/revoke'
);

=head2 ID

ID is the lease ID to revoke. When the ID is revoked, all associated keys will be deleted.

=cut

has ID => (
    is       => 'ro',
    isa      => Int,
    required => 1,
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
    $self->json_args;
    return $self;
}

1;
