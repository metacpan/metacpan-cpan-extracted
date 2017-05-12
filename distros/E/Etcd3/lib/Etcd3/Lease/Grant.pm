use utf8;
package Etcd3::Lease::Grant;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use Data::Dumper;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::Lease::Grant

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

LeaseGrant creates a lease which expires if the server does not receive a keepAlive within
a given time to live period. All keys attached to the lease will be expired and deleted if
the lease expires. Each expired key generates a delete event in the event history.

=head2 endpoint

/lease/grant

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/lease/grant'
);

=head2 TTL

TTL is the advisory time-to-live in seconds.

=cut

has TTL => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 ID

ID is the requested ID for the lease. If ID is set to 0, the lessor chooses an ID.

=cut

has ID => (
    is       => 'ro',
    required => 1,
    coerce   => sub { return $_[0]; },
);

=head2 json_args

arguments that will be sent to the api

=cut

has json_args => ( is => 'lazy', );

sub _build_json_args {
    my ($self) = @_;
#    print STDERR Dumper($self);
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
