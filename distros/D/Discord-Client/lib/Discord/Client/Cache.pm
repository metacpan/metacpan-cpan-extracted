package Discord::Client::Cache;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use JSON::PP ();
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Bound both serialized data size and entry count; expiry uses monotonic time.
    my $self = bless {
        entries => {},
        bytes => 0,
        access_sequence => 0,
        counters => {},
        max_items => $args{max_items} // 1000,
        max_bytes => $args{max_bytes} // 8 * 1024 * 1024,
        max_entry_bytes => $args{max_entry_bytes} // 262144,
        ttl => $args{ttl} // 300,
        clock => $args{clock} // sub { clock_gettime(CLOCK_MONOTONIC) },
        json => JSON::PP->new->utf8
    }, $class;

    # Reject invalid limits before any caller data can enter the cache.
    for my $key (qw(max_items max_bytes max_entry_bytes ttl)) {
        croak "$key must be a positive integer" unless !ref( $self->{$key} ) && $self->{$key} =~ /\A[1-9]\d*\z/;
    }
    croak 'clock must be a code reference' unless ref( $self->{clock} ) eq 'CODE';

    # Cache only explicitly supported resource snapshots, without automatic fetches.
    my $types = $args{types} // [qw(guild channel user message)];
    croak 'types must be an array reference' unless ref($types) eq 'ARRAY';
    for my $type (@$types) {
        croak 'Unknown cache type'
            unless defined($type) && !ref($type) && $type =~ /\A(?:guild|channel|user|message)\z/;
        $self->{types}{$type} = 1;
    }
    return $self;
}

sub _key {
    my ( $type, $id ) = @_;

    # Include the resource type so equal IDs in different collections remain distinct.
    croak 'Invalid cache type or ID'
        unless defined($type)
        && !ref($type)
        && $type =~ /\A(?:guild|channel|user|message)\z/
        && defined($id)
        && !ref($id)
        && $id =~ /\A\d{1,20}\z/;
    return "$type:$id";
}

sub _remove {
    my ( $self, $key ) = @_;

    # Keep serialized-byte accounting correct for deletion and replacement alike.
    my $old = delete $self->{entries}{$key};
    $self->{bytes} -= $old->{size} if $old;
    return !!$old;
}

sub _expire {
    my ($self) = @_;

    # Expiry is lazy and does not require another event-loop timer.
    my $now = $self->{clock}->();
    for my $key ( keys %{ $self->{entries} } ) {
        next if $self->{entries}{$key}{expires} > $now;
        $self->_remove($key);
        ++$self->{counters}{expired};
    }
}

sub put {
    my ( $self, $type, $data, %args ) = @_;

    # Validate identity before inspecting existing data or mutating storage.
    croak 'Cached data must be a hash reference' unless ref($data) eq 'HASH';
    my $key = _key( $type, $data->{id} );
    return 0 unless $self->{types}{$type};

    # Merge partial events only with live snapshots, including explicit null fields.
    $self->_expire;
    my $old = $self->{entries}{$key};
    my $merged = $args{merge} && $old ? { %{ $old->{data} }, %$data } : {%$data};
    my $encoded = eval { $self->{json}->encode($merged) };
    croak 'Cache data must be JSON encodable' if $@;

    # An oversized replacement invalidates the old snapshot instead of leaving stale data.
    if ( length($encoded) > $self->{max_entry_bytes} || length($encoded) > $self->{max_bytes} ) {
        ++$self->{counters}{oversized};
        $self->_remove($key);
        return 0;
    }
    $self->_remove($key);

    # Evict before committing a detached JSON snapshot and its fresh expiry time.
    $self->_make_room( length($encoded) );
    $self->{entries}{$key} = {
        data => $self->{json}->decode($encoded),
        size => length($encoded),
        expires => $self->{clock}->() + $self->{ttl},
        last_access_sequence => ++$self->{access_sequence},
        type => $type,
    };
    $self->{bytes} += length($encoded);
    ++$self->{counters}{stored};
    return 1;
}

sub _make_room {
    my ( $self, $incoming_size ) = @_;

    # Access sequence numbers order reads and writes even when the clock has not advanced.
    # Remove the oldest accesses until both capacity bounds can admit the incoming snapshot.
    while ( keys( %{ $self->{entries} } ) >= $self->{max_items}
        || $self->{bytes} + $incoming_size > $self->{max_bytes} )
    {
        my ($least_recent_key) =
            sort { $self->{entries}{$a}{last_access_sequence} <=> $self->{entries}{$b}{last_access_sequence} }
            keys %{ $self->{entries} };
        $self->_remove($least_recent_key);
        ++$self->{counters}{evicted};
    }
}

sub get {
    my ( $self, $type, $id ) = @_;

    # Expired entries are misses; reads update recency but not the write-based TTL.
    my $key = _key( $type, $id );
    $self->_expire;
    my $entry = $self->{entries}{$key};
    unless ($entry) {
        ++$self->{counters}{misses};
        return undef;
    }
    ++$self->{counters}{hits};
    $entry->{last_access_sequence} = ++$self->{access_sequence};

    # Return a detached copy so caller mutations cannot corrupt the cache.
    return $self->{json}->decode( $self->{json}->encode( $entry->{data} ) );
}

sub remove {
    my ( $self, $type, $id ) = @_;
    return $self->_remove( _key( $type, $id ) );
}

sub clear {
    my ($self) = @_;

    # Clear accounting together with snapshots so capacity is immediately reusable.
    $self->{entries} = {};
    $self->{bytes} = 0;
    return;
}

sub stats {
    my ($self) = @_;
    $self->_expire;
    return { %{ $self->{counters} }, items => scalar( keys %{ $self->{entries} } ), bytes => $self->{bytes} };
}

sub _remove_related {
    my ( $self, $field, $id ) = @_;

    # Delete observed dependants using explicit guild or channel references.
    for my $key ( keys %{ $self->{entries} } ) {
        my $data = $self->{entries}{$key}{data};
        $self->_remove($key) if defined( $data->{$field} ) && !ref( $data->{$field} ) && $data->{$field} eq $id;
    }
}

sub _store_observed {
    my ( $self, $type, $data, %options ) = @_;

    # Ignore event fragments without a valid resource identity.
    return
        unless ref($data) eq 'HASH' && defined( $data->{id} ) && !ref( $data->{id} ) && $data->{id} =~ /\A\d{1,20}\z/;
    $self->put( $type, $data, %options );
}

sub apply {
    my ( $self, $event, $data ) = @_;
    return unless ref($data) eq 'HASH';

    # Apply Gateway snapshots and deletions without fetching missing resources.
    if ( $event eq 'READY' ) {
        $self->_store_observed( user => $data->{user} );
        my $guilds = ref( $data->{guilds} ) eq 'ARRAY' ? $data->{guilds} : [];
        $self->_store_observed( guild => $_, merge => 1 ) for @$guilds;
    }
    elsif ( $event eq 'GUILD_CREATE' || $event eq 'GUILD_UPDATE' ) {
        $self->_store_guild_event( $event, $data );
    }
    elsif ( $event eq 'GUILD_DELETE' && defined( $data->{id} ) ) {

        # A temporary guild outage retains snapshots; a true departure removes dependants.
        if ( $data->{unavailable} ) {
            $self->_store_observed( guild => $data, merge => 1 );
        }
        else {
            $self->_remove_related( guild_id => $data->{id} );
            $self->remove( guild => $data->{id} );
        }
    }
    elsif ( $event =~ /\A(?:CHANNEL|THREAD)_(CREATE|UPDATE)\z/ ) {
        $self->_store_observed( channel => $data, merge => $1 eq 'UPDATE' );
    }
    elsif ( $event =~ /\A(?:CHANNEL|THREAD)_DELETE\z/ && defined( $data->{id} ) ) {
        $self->_remove_related( channel_id => $data->{id} );
        $self->remove( channel => $data->{id} );
    }
    elsif ( $event eq 'MESSAGE_CREATE' || $event eq 'MESSAGE_UPDATE' ) {
        $self->_store_observed( message => $data, merge => $event eq 'MESSAGE_UPDATE' );
        $self->_store_observed( user => $data->{author}, merge => 1 );
    }
    elsif ( $event eq 'MESSAGE_DELETE' && defined( $data->{id} ) ) {
        $self->remove( message => $data->{id} );
    }
    elsif ( $event eq 'MESSAGE_DELETE_BULK' && ref( $data->{ids} ) eq 'ARRAY' ) {
        $self->remove( message => $_ ) for @{ $data->{ids} };
    }
    elsif ( $event eq 'USER_UPDATE' ) {
        $self->_store_observed( user => $data, merge => 1 );
    }
    return;
}

sub _store_guild_event {
    my ( $self, $event, $data ) = @_;

    # Keep large member/presence collections out of the lightweight guild snapshot.
    my %guild = %$data;
    delete @guild{qw(members presences voice_states channels threads)};
    $guild{unavailable} //= JSON::PP::false if $event eq 'GUILD_CREATE';
    $self->_store_observed( guild => \%guild, merge => 1 );
    return unless $event eq 'GUILD_CREATE';

    # Channels and threads are independent entries with an explicit guild reference.
    for my $field (qw(channels threads)) {
        next unless ref( $data->{$field} ) eq 'ARRAY';
        for my $channel ( @{ $data->{$field} } ) {
            next unless ref($channel) eq 'HASH';
            $self->_store_observed( channel => { %$channel, guild_id => $data->{id} } );
        }
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Cache - Bounded resource snapshots

=head1 SYNOPSIS

    use Discord::Client::Cache;

    # Store bounded snapshots without network I/O.
    my $cache = Discord::Client::Cache->new(
        types => ['channel', 'message'], max_items => 1000, ttl => 300,
    );
    $cache->put(message => $data);
    my $message = $cache->get(message => $message_id);

=head1 DESCRIPTION

Optional in-memory snapshots of observed resources. All methods are synchronous
and perform no requests. In L<Discord::Client>, enable caching with C<cache =E<gt> 1>,
an options hash or an existing Cache object. It is off by default.

The client applies Gateway events before calling application handlers.
Snapshots may be partial, stale or missing. REST fetches do not automatically
populate the cache. Client shutdown leaves snapshots until cleared or expired.
A supplied cache can be shared by clients on the same loop.

=head1 METHODS

=head2 new

Returns an empty cache. C<types> accepts an arrayref of C<guild>, C<channel>,
C<user> and C<message>; omitting it selects all four. Invalid options throw.
C<clock> can supply a monotonic clock callback for testing.

=over 4

=item C<max_items>

Maximum entries; default 1000.

=item C<ttl>

Seconds since the last write; default 300.

=item C<max_bytes>

Total serialized JSON bytes; default 8388608.

=item C<max_entry_bytes>

Serialized bytes per entry; default 262144.

=back

Reads refresh least-recently-used order. Total limits evict the least recently
used entries. Oversized entries are rejected and remove any older snapshot.
Perl object overhead is not included in byte counts. Expiry runs on reads,
writes and stats; there are no background timers.

=head2 put

C<put(type, hashref, merge =E<gt> 1)> stores copied JSON data with an ID.
Returns true when stored, false for disabled types or oversized entries.
Invalid IDs, types or data throw. C<merge> combines top-level fields with an
existing entry, including explicit nulls; otherwise data is replaced.
Unknown fields are preserved.

=head2 get

C<get(type, id)> returns a copied hashref or undef when absent or expired.
IDs are decimal strings.

=head2 remove

C<remove(type, id)> removes an entry and returns whether it existed.

=head2 apply

C<apply(event_name, payload_hash)> updates observed objects from a Gateway event.
Returns no value. Deletes remove related entries; guild outages retain
snapshots marked C<unavailable> until expiry.

Guild snapshots omit members, presences, voice states, channels and threads.
Observed channels and threads have separate entries. There are no guild/member
scans, presence or voice-state caches.

=head2 clear

Removes all entries and returns no value.

=head2 stats

Expires old entries and returns a hashref of counters, entry count and
serialized-byte usage.

=head1 LICENSE

Apache License 2.0.

=cut
