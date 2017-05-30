use utf8;
package Etcd3::KV;

use strict;
use warnings;

=encoding utf8

=cut
use Moo::Role;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use Etcd3::KV::Put;
use Etcd3::KV::Range;

with 'Etcd3::Role::Actions';
use namespace::clean;

=head1 NAME

Etcd3::KV

=cut

our $VERSION = '0.007';

=head1 DESCRIPTION

Key Value role providing easy access to Put and Range classes

=cut

=head1 PUBLIC METHODS

=head2 range

Range gets the keys in the range from the key-value store.

    $etcd->range({key =>'test0', range_end => 'test100'})

=cut

sub range {
    my ( $self, $options ) = @_;
	my $cb = pop if ref $_[-1] eq 'CODE';
    my $range = Etcd3::KV::Range->new(
        %$self,
        endpoint => '/kv/range',
        etcd     => $self,
		cb       => $cb,
        ( $options ? %$options : () ),
    );
    $range->request;
    return $range;
}

=head2 put

Put puts the given key into the key-value store. A put request increments
the revision of the key-value store and generates one event in the event
history.

    $etcd->range({key =>'test0', range_end => 'test100'})

=cut

sub put {
    my ( $self, $options ) = @_;
	my $cb = pop if ref $_[-1] eq 'CODE';
    my $range = Etcd3::KV::Put->new(
        %$self,
        endpoint => '/kv/put',
        etcd     => $self,
		cb       => $cb,
        ( $options ? %$options : () ),
    );
    $range->request;
    return $range;
}

1;
