package EventStore::Tiny;
use Mo qw(default);

use EventStore::Tiny::Logger;
use EventStore::Tiny::Event;
use EventStore::Tiny::DataEvent;
use EventStore::Tiny::EventStream;
use EventStore::Tiny::Snapshot;

use Clone qw(clone);
use Storable;
use Data::Compare; # exports Compare()

# enable handling of CODE refs (as event actions are code refs)
$Storable::Deparse  = 1;
$Storable::Eval     = 1;

our $VERSION = '0.2';

has registry    => {};
has events      => sub {EventStore::Tiny::EventStream->new(
                        logger => shift->logger)};
has init_data   => {};
has logger      => sub {EventStore::Tiny::Logger->log_cb};
has cache_size  => 0; # default: store snapshot every time. no caching: undef
has '_cached_snapshot';

# class method to construct
sub new_from_file {
    my (undef, $fn) = @_;
    return retrieve($fn);
}

{no warnings 'redefine';
sub store {
    my ($self, $fn) = @_;
    Storable::store($self, $fn);
}}

sub register_event {
    my ($self, $name, $transformation) = @_;

    $self->registry->{$name} = EventStore::Tiny::Event->new(
        name            => $name,
        transformation  => $transformation,
        logger          => $self->logger,
    );
}

sub event_names {
    my $self = shift;
    return [sort keys %{$self->registry}];
}

sub store_event {
    my ($self, $name, $data) = @_;

    # lookup template event
    my $template = $self->registry->{$name};
    die "Unknown event: $name!\n" unless defined $template;

    # specialize event with new data
    my $event = EventStore::Tiny::DataEvent->new_from_template(
        $template, $data
    );

    # done
    $self->events->add_event($event);
}

sub init_state {
    my $self = shift;

    # clone init data
    return clone($self->init_data);
}

sub snapshot {
    my ($self, $timestamp) = @_;
    my $state = $self->init_state;

    # work on latest timestamp if not specified
    $timestamp //= $self->events->last_timestamp;
    my $es = $self->events->until($timestamp);

    # check if the cached snapshot can be used
    my $cached_sn = $self->_cached_snapshot;
    if (defined $cached_sn and $cached_sn->timestamp <= $timestamp) {
        $state  = clone $cached_sn->state;
        $es     = $es->after($cached_sn->timestamp);
    }

    # calculate snapshot
    my $snapshot = EventStore::Tiny::Snapshot->new(
        state       => $es->apply_to($state, $self->logger),
        timestamp   => $es->last_timestamp,
    );

    # caching disabled: done
    return $snapshot unless defined $self->cache_size;

    # cache snapshot if no cache present yet, but neccessary
    $self->_cached_snapshot($snapshot)
        if not defined $self->_cached_snapshot and $es->length > 0;

    # cache snapshot if new event count > cache size
    $self->_cached_snapshot($snapshot)
        if @{$es->events} > $self->cache_size;

    # done
    return $snapshot;
}

sub is_correct_snapshot {
    my ($self, $snapshot) = @_;

    # replay events until snapshot time
    my $our_sn = $self->snapshot($snapshot->timestamp);

    # true iff the generated state looks the same
    return Compare($snapshot->state, $our_sn->state);
}

1;
__END__
