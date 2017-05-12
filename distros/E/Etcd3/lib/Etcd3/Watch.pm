use utf8;
package Etcd3::Watch;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::Range

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

Watch watches for events happening or that have happened. Both input and output are streams;
the input stream is for creating and canceling watchers and the output stream sends events.
One watch RPC can watch on multiple key ranges, streaming events for several watches at once.
The entire event history can be watched starting from the last compaction revision.

=head2 endpoint

=cut

has endpoint => (
    is      => 'ro',
    isa     => Str,
    default => '/watch'
);

=head2 key

key is the first key for the range. If range_end is not given, the request only looks up key.
the key is encoded with base64.  type bytes

=cut

has key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) }
);

=head2 range_end

range_end is the end of the range [key, range_end) to watch. If range_end is not given, only
the key argument is watched. If range_end is equal to '\0', all keys greater than or equal to
the key argument are watched.

=cut

has range_end => (
    is     => 'ro',
    isa    => Str,
    coerce => sub { return encode_base64( $_[0], '' ) }
);

=head2 limit

=cut

has limit => (
    is  => 'ro',
    isa => Int,
);

=head2 progress_notify

progress_notify is set so that the etcd server will periodically send a WatchResponse with no
events to the new watcher if there are no recent events. It is useful when clients wish to recover
a disconnected watcher starting from a recent known revision. The etcd server may decide how often
it will send notifications based on current load.

=cut

has progress_notify => (
    is     => 'ro',
    isa    => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);

=head2 prev_key

If prev_kv is set, created watcher gets the previous KV before the event happens. If the previous
KV is already compacted, nothing will be returned.

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
        unless ( $key =~ /(?:_client|json_args|endpoint)$/ ) {
            $args->{$key} = $self->{$key};
        }
    }
    return to_json( { create_request => $args } );
}

=head2 init

=cut

sub init {
    my ($self) = @_;
    $self->json_args;
    return $self;
}

1;
