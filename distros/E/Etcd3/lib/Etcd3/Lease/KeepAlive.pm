use utf8;
package Etcd3::Lease::KeepAlive;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::Lease::KeepAlive

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

LeaseKeepAlive keeps the lease alive by streaming keep alive requests from the client
to the server and streaming keep alive responses from the server to the client."

=head2 endpoint

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/lease/keepalive'
);

=head2 ID

ID is the lease ID for the lease to keep alive.

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
