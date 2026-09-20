package ForgeOps::Tracker::SpanBuffer;

use strict;
use warnings;
use POSIX qw(strftime);

# One trace's worth of spans (a request's own call tree), sharing a single trace id. Held in a
# plain package variable on ForgeOps::Tracker for the same one-process-per-worker reasoning its
# $current_user and @current_breadcrumbs document. Nesting comes from a stack of open span ids: a
# span opened while another is open becomes its child, and anything else parents under the root.
use constant MAX_SPANS => 500;

# The kinds the ingestion API accepts; anything else would fail validation for the whole trace,
# so an unknown kind is sent as "other" instead.
my %KINDS = map { $_ => 1 } qw(controller service database redis http job other);

sub new {
    my ($class, $configuration) = @_;
    return bless {
        configuration => $configuration,
        trace_id      => _random_hex(16),
        root_span_id  => _random_hex(8),
        spans         => [],
        open          => [],
    }, $class;
}

sub trace_id { $_[0]{trace_id} }

# Opens a span and returns its id; pair with finish().
sub open_span {
    my ($self) = @_;
    my $id = _random_hex(8);
    push @{ $self->{open} }, $id;
    return $id;
}

sub finish {
    my ($self, $id, $name, $kind, $started_at, $duration_ms, $data) = @_;
    my $parent = $self->_current_parent_without($id);
    $self->{open} = [ grep { $_ ne $id } @{ $self->{open} } ];
    $self->_record($id, $parent, $name, $kind, $started_at, $duration_ms, $data);
}

# Records an already-finished span as a child of whatever is currently open.
sub record_leaf {
    my ($self, $name, $kind, $started_at, $duration_ms, $data) = @_;
    $self->_record(_random_hex(8), $self->_current_parent, $name, $kind, $started_at, $duration_ms, $data);
}

sub _current_parent {
    my ($self) = @_;
    return @{ $self->{open} } ? $self->{open}[-1] : $self->{root_span_id};
}

# The parent of span $id: whatever is open just beneath it on the stack, or the root.
sub _current_parent_without {
    my ($self, $id) = @_;
    my @open = @{ $self->{open} };
    for my $i (reverse 0 .. $#open) {
        next unless $open[$i] eq $id;
        return $i > 0 ? $open[ $i - 1 ] : $self->{root_span_id};
    }
    return $self->{root_span_id};
}

sub _record {
    my ($self, $id, $parent, $name, $kind, $started_at, $duration_ms, $data) = @_;
    return if @{ $self->{spans} } >= MAX_SPANS - 1; # leave room for the root
    push @{ $self->{spans} }, $self->_build($id, $parent, $name, $kind, $started_at, $duration_ms, $data);
}

sub _build {
    my ($self, $id, $parent, $name, $kind, $started_at, $duration_ms, $data) = @_;
    my $config = $self->{configuration};
    return {
        span_id        => $id,
        parent_span_id => $parent,
        name           => $name,
        kind           => (defined $kind && $KINDS{$kind}) ? $kind : 'other',
        started_at     => _format_time($started_at),
        duration_ms    => 0 + sprintf('%.2f', $duration_ms),
        environment    => $config->{environment},
        release        => $config->{release},
        data           => $data || {},
    };
}

# The wire payload once the trace is over: the root span plus everything recorded beneath it, or
# undef when the root was faster than trace_capture_threshold (seconds).
sub finish_trace {
    my ($self, $root_name, $started_at, $duration_ms) = @_;
    return undef if $duration_ms < $self->{configuration}{trace_capture_threshold} * 1000;

    return {
        trace_id => $self->{trace_id},
        spans    => [
            $self->_build($self->{root_span_id}, undef, $root_name, 'controller', $started_at, $duration_ms, {}),
            @{ $self->{spans} },
        ],
    };
}

# ISO 8601 with milliseconds, UTC, from an epoch-seconds float.
sub _format_time {
    my ($epoch_seconds) = @_;
    my $whole = int($epoch_seconds);
    return strftime('%Y-%m-%dT%H:%M:%S', gmtime($whole)) . sprintf('.%03dZ', int(($epoch_seconds - $whole) * 1000));
}

sub _random_hex {
    my ($bytes) = @_;
    my $hex = '';
    if (open my $fh, '<:raw', '/dev/urandom') {
        read($fh, my $raw, $bytes);
        close $fh;
        $hex = unpack('H*', $raw) if defined $raw && length($raw) == $bytes;
    }
    # No /dev/urandom (Windows) or a short read: fall back to rand, which is fine for an id that
    # only has to be unique within one project's traces, not unpredictable.
    $hex = join('', map { sprintf('%02x', int(rand(256))) } 1 .. $bytes) unless length $hex;
    return $hex;
}

1;
