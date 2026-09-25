package ForgeOps::Tracker::TraceParent;

use strict;
use warnings;

# Reads and writes the W3C Trace Context `traceparent` header (https://www.w3.org/TR/trace-context/),
# the vendor-neutral format for carrying one trace across service boundaries:
# "00-<32 hex trace-id>-<16 hex parent-id>-<2 hex flags>". Used in both directions: the
# PSGI/Dancer2 performance integrations parse an incoming one so the request continues the
# caller's trace instead of starting its own, and ForgeOps::Tracker::http_span builds an outgoing
# one so the next service along continues this request's. Ported from gems/forge_ops_tracker's
# trace_parent.rb.
#
# Deliberately strict on the way in, the same posture the spec asks receivers to take: a malformed
# value, uppercase hex, the reserved version "ff", or an all-zero trace/parent id are all treated
# as "no usable header at all" (parse returns undef and the request starts a fresh trace). A
# version this client doesn't know yet is still accepted as long as its first four fields have
# version 00's shape, which is what the spec says a version-00 parser should do with a future
# version; version 00 itself must have exactly four fields.
use constant HEADER => 'traceparent';

# Always "01" (sampled) on the way out: whether a trace is actually sent is only decided once the
# request is over, long after this header has gone out on an outbound call, so there's no honest
# earlier answer than "this may be recorded."
my $SAMPLED_FLAGS = '01';

my $PATTERN = qr{\A([0-9a-f]{2})-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})(-.*)?\z}s;

# parse($value): { trace_id => ..., parent_span_id => ... } for a usable header, undef for
# anything else (absent, blank, malformed, or one of the explicitly invalid values above).
sub parse {
    my ($value) = @_;
    return undef if !defined $value || ref $value;

    (my $trimmed = $value) =~ s/\A\s+|\s+\z//g;
    my ($version, $trace_id, $parent_id, undef, $rest) = $trimmed =~ $PATTERN or return undef;
    return undef if $version eq 'ff';
    return undef if $version eq '00' && defined $rest;
    return undef if $trace_id eq '0' x 32 || $parent_id eq '0' x 16;

    return { trace_id => $trace_id, parent_span_id => $parent_id };
}

sub build {
    my ($trace_id, $span_id) = @_;
    return "00-$trace_id-$span_id-$SAMPLED_FLAGS";
}

# 32 lowercase hex characters, the W3C trace-id format; never all zeros.
sub generate_trace_id { _random_hex(16) }

# 16 lowercase hex characters, the W3C parent-id (span id) format; never all zeros.
sub generate_span_id { _random_hex(8) }

sub _random_hex {
    my ($bytes) = @_;
    my $hex;
    do {
        $hex = '';
        if (open my $fh, '<:raw', '/dev/urandom') {
            read($fh, my $raw, $bytes);
            close $fh;
            $hex = unpack('H*', $raw) if defined $raw && length($raw) == $bytes;
        }
        # No /dev/urandom (Windows) or a short read: fall back to rand, which is fine for an id
        # that only has to be unique within one project's traces, not unpredictable.
        $hex = join('', map { sprintf('%02x', int(rand(256))) } 1 .. $bytes) unless length $hex;
    } while ($hex !~ /[^0]/);
    return $hex;
}

1;
