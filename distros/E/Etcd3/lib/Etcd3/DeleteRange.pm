use utf8;
package Etcd3::DeleteRange;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::DeleteRange

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

DeleteRange deletes the given range from the key-value store. A delete request increments the
revision of the key-value store and generates a delete event in the event history for every
deleted key.

=head2 endpoint

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/kv/deleterange'
);

=head2 key

key is the first key to delete in the range.

=cut

has key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) }
);

=head2 range_end

range_end is the key following the last key to delete for the range [key, range_end). If range_end
is not given, the range is defined to contain only the key argument. If range_end is '\0', the range
is all keys greater than or equal to the key argument.

=cut

has range_end => (
    is     => 'ro',
    isa    => Str,
    coerce => sub { return encode_base64( $_[0], '' ) }
);

=head2 prev_key

If prev_kv is set, etcd gets the previous key-value pairs before deleting it. The previous key-value
pairs will be returned in the delete response.

=cut

has prev_key => (
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
        unless ( $key =~ /(?:_client|args|endpoint)$/ ) {
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
