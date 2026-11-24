package Google::Cloud::Networkconnectivity::V1alpha1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvbmV0d29ya2Nvbm5lY3Rpdml0eS92MWFscGhhMS9jb21tb24ucHJv
dG8SKWdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYWxwaGExGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvItUCChFPcGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6CghlbmRfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGltZRIbCgZ0YXJnZXQY
AyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZlcmIYBCABKAlCA+BBA1IEdmVyYhIqCg5zdGF0dXNf
bWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0dXNNZXNzYWdlEjoKFnJlcXVlc3RlZF9jYW5jZWxs
YXRpb24YBiABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9u
GAcgASgJQgPgQQNSCmFwaVZlcnNpb25CpgIKLWNvbS5nb29nbGUuY2xvdWQubmV0d29ya2Nv
bm5lY3Rpdml0eS52MWFscGhhMUILQ29tbW9uUHJvdG9QAVpfY2xvdWQuZ29vZ2xlLmNvbS9n
by9uZXR3b3JrY29ubmVjdGl2aXR5L2FwaXYxYWxwaGExL25ldHdvcmtjb25uZWN0aXZpdHlw
YjtuZXR3b3JrY29ubmVjdGl2aXR5cGKqAilHb29nbGUuQ2xvdWQuTmV0d29ya0Nvbm5lY3Rp
dml0eS5WMUFscGhhMcoCKUdvb2dsZVxDbG91ZFxOZXR3b3JrQ29ubmVjdGl2aXR5XFYxYWxw
aGEx6gIsR29vZ2xlOjpDbG91ZDo6TmV0d29ya0Nvbm5lY3Rpdml0eTo6VjFhbHBoYTFKpRAK
BhIEDgA2AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMgoJ
CgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBIDFQBGCgkKAgglEgMVAEYKCAoBCBIDFgB2CgkK
AggLEgMWAHYKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAsCgkKAggIEgMYACwKCAoB
CBIDGQBGCgkKAggBEgMZAEYKCAoBCBIDGgBGCgkKAggpEgMaAEYKCAoBCBIDGwBFCgkKAggt
EgMbAEUKRAoCBAASBB4ANgEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9u
Zy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQAARIDHggZCj8KBAQAAgASAyACWBoyIE91dHB1
dCBvbmx5LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAAYS
AyACGwoMCgUEAAIAARIDIBwnCgwKBQQAAgADEgMgKisKDAoFBAACAAgSAyAsVwoPCggEAAIA
CJwIABIDIC1WCkQKBAQAAgESAyMCVRo3IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgb3Bl
cmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoMCgUEAAIBBhIDIwIbCgwKBQQAAgEBEgMjHCQK
DAoFBAACAQMSAyMnKAoMCgUEAAIBCBIDIylUCg8KCAQAAgEInAgAEgMjKlMKWQoEBAACAhID
JgJAGkwgT3V0cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJlc291cmNlIHBhdGggZm9yIHRo
ZSB0YXJnZXQgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgIFEgMmAggKDAoFBAACAgESAyYJ
DwoMCgUEAAICAxIDJhITCgwKBQQAAgIIEgMmFD8KDwoIBAACAgicCAASAyYVPgpHCgQEAAID
EgMpAj4aOiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgdmVyYiBleGVjdXRlZCBieSB0aGUg
b3BlcmF0aW9uLgoKDAoFBAACAwUSAykCCAoMCgUEAAIDARIDKQkNCgwKBQQAAgMDEgMpEBEK
DAoFBAACAwgSAykSPQoPCggEAAIDCJwIABIDKRM8CksKBAQAAgQSAywCSBo+IE91dHB1dCBv
bmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMgb2YgdGhlIG9wZXJhdGlvbiwgaWYgYW55LgoK
DAoFBAACBAUSAywCCAoMCgUEAAIEARIDLAkXCgwKBQQAAgQDEgMsGhsKDAoFBAACBAgSAywc
RwoPCggEAAIECJwIABIDLB1GCpkCCgQEAAIFEgMyAk4aiwIgT3V0cHV0IG9ubHkuIElkZW50
aWZpZXMgd2hldGhlciB0aGUgdXNlciBoYXMgcmVxdWVzdGVkIGNhbmNlbGxhdGlvbgogb2Yg
dGhlIG9wZXJhdGlvbi4gT3BlcmF0aW9ucyB0aGF0IGhhdmUgc3VjY2Vzc2Z1bGx5IGJlZW4g
Y2FuY2VsbGVkCiBoYXZlIFtPcGVyYXRpb24uZXJyb3JdW10gdmFsdWUgd2l0aCBhIFtnb29n
bGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiAxLAogY29y
cmVzcG9uZGluZyB0byBgQ29kZS5DQU5DRUxMRURgLgoKDAoFBAACBQUSAzICBgoMCgUEAAIF
ARIDMgcdCgwKBQQAAgUDEgMyICEKDAoFBAACBQgSAzIiTQoPCggEAAIFCJwIABIDMiNMCkQK
BAQAAgYSAzUCRRo3IE91dHB1dCBvbmx5LiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0YXJ0IHRo
ZSBvcGVyYXRpb24uCgoMCgUEAAIGBRIDNQIICgwKBQQAAgYBEgM1CRQKDAoFBAACBgMSAzUX
GAoMCgUEAAIGCBIDNRlECg8KCAQAAgYInAgAEgM1GkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkconnectivity::V1alpha1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkconnectivity::V1alpha1::Common - Compiled Protocol Buffers messages for google/cloud/networkconnectivity/v1alpha1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkconnectivity::V1alpha1::Common;

    my $msg = Google::Cloud::Networkconnectivity::V1alpha1::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkconnectivity::V1alpha1::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkconnectivity/v1alpha1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkconnectivity::V1alpha1::Common::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkconnectivity::V1alpha1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
