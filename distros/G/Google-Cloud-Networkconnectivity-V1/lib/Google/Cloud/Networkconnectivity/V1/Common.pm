package Google::Cloud::Networkconnectivity::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvbmV0d29ya2Nvbm5lY3Rpdml0eS92MS9jb21tb24ucHJvdG8SI2dv
b2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvItUCChFPcGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVfdGlt
ZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6
CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5k
VGltZRIbCgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZlcmIYBCABKAlCA+BBA1IE
dmVyYhIqCg5zdGF0dXNfbWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0dXNNZXNzYWdlEjoKFnJl
cXVlc3RlZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9u
EiQKC2FwaV92ZXJzaW9uGAcgASgJQgPgQQNSCmFwaVZlcnNpb25CuAUKJ2NvbS5nb29nbGUu
Y2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MUILQ29tbW9uUHJvdG9QAVpZY2xvdWQuZ29v
Z2xlLmNvbS9nby9uZXR3b3JrY29ubmVjdGl2aXR5L2FwaXYxL25ldHdvcmtjb25uZWN0aXZp
dHlwYjtuZXR3b3JrY29ubmVjdGl2aXR5cGKqAiNHb29nbGUuQ2xvdWQuTmV0d29ya0Nvbm5l
Y3Rpdml0eS5WMcoCI0dvb2dsZVxDbG91ZFxOZXR3b3JrQ29ubmVjdGl2aXR5XFYx6gImR29v
Z2xlOjpDbG91ZDo6TmV0d29ya0Nvbm5lY3Rpdml0eTo6VjHqQXoKLWNvbXB1dGUuZ29vZ2xl
YXBpcy5jb20vSW50ZXJjb25uZWN0QXR0YWNobWVudBJJcHJvamVjdHMve3Byb2plY3R9L3Jl
Z2lvbnMve3JlZ2lvbn0vaW50ZXJjb25uZWN0QXR0YWNobWVudHMve3Jlc291cmNlX2lkfepB
UgoeY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9OZXR3b3JrEjBwcm9qZWN0cy97cHJvamVjdH0v
Z2xvYmFsL25ldHdvcmtzL3tyZXNvdXJjZV9pZH3qQWEKIWNvbXB1dGUuZ29vZ2xlYXBpcy5j
b20vU3VibmV0d29yaxI8cHJvamVjdHMve3Byb2plY3R9L3JlZ2lvbnMve3JlZ2lvbn0vc3Vi
bmV0d29ya3Mve3N1Ym5ldHdvcmt96kF3Cihjb21wdXRlLmdvb2dsZWFwaXMuY29tL1NlcnZp
Y2VBdHRhY2htZW50Ektwcm9qZWN0cy97cHJvamVjdH0vcmVnaW9ucy97cmVnaW9ufS9zZXJ2
aWNlQXR0YWNobWVudHMve3NlcnZpY2VfYXR0YWNobWVudH1KzREKBhIEDgBLAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMB
EgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEAKCQoCCCUSAxYAQAoICgEIEgMXAHAKCQoCCAsS
AxcAcAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZACwKCQoCCAgSAxkALAoICgEIEgMa
AEAKCQoCCAESAxoAQAoICgEIEgMbAEAKCQoCCCkSAxsAQAoICgEIEgMcAD8KCQoCCC0SAxwA
PwoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKCQoBCBIEIQAkAgoMCgQInQgBEgQhACQCCgkK
AQgSBCUAKAIKDAoECJ0IAhIEJQAoAgoJCgEIEgQpACwCCgwKBAidCAMSBCkALAIKRAoCBAAS
BC8ASwEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9w
ZXJhdGlvbi4KCgoKAwQAARIDLwgZCkAKBAQAAgASBDECMjIaMiBPdXRwdXQgb25seS4gVGhl
IHRpbWUgdGhlIG9wZXJhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgAGEgMxAhsKDAoFBAAC
AAESAzEcJwoMCgUEAAIAAxIDMSorCgwKBQQAAgAIEgMyBjEKDwoIBAACAAicCAASAzIHMApF
CgQEAAIBEgQ1AjYyGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmlu
aXNoZWQgcnVubmluZy4KCgwKBQQAAgEGEgM1AhsKDAoFBAACAQESAzUcJAoMCgUEAAIBAxID
NScoCgwKBQQAAgEIEgM2BjEKDwoIBAACAQicCAASAzYHMApZCgQEAAICEgM5AkAaTCBPdXRw
dXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBv
ZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAgUSAzkCCAoMCgUEAAICARIDOQkPCgwKBQQAAgID
EgM5EhMKDAoFBAACAggSAzkUPwoPCggEAAICCJwIABIDORU+CkcKBAQAAgMSAzwCPho6IE91
dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24u
CgoMCgUEAAIDBRIDPAIICgwKBQQAAgMBEgM8CQ0KDAoFBAACAwMSAzwQEQoMCgUEAAIDCBID
PBI9Cg8KCAQAAgMInAgAEgM8EzwKSwoEBAACBBIDPwJIGj4gT3V0cHV0IG9ubHkuIEh1bWFu
LXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoMCgUEAAIEBRID
PwIICgwKBQQAAgQBEgM/CRcKDAoFBAACBAMSAz8aGwoMCgUEAAIECBIDPxxHCg8KCAQAAgQI
nAgAEgM/HUYK0AIKBAQAAgUSA0cCThrCAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0
aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0
aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBiZWVuIGNhbmNlbGxlZCBzdWNjZXNzZnVsbHkK
IGhhdmUKIFtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXVtnb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uLmVycm9yXQogdmFsdWUgd2l0aCBhIFtnb29nbGUucnBjLlN0
YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiAxLAogY29ycmVzcG9uZGlu
ZyB0byBgQ29kZS5DQU5DRUxMRURgLgoKDAoFBAACBQUSA0cCBgoMCgUEAAIFARIDRwcdCgwK
BQQAAgUDEgNHICEKDAoFBAACBQgSA0ciTQoPCggEAAIFCJwIABIDRyNMCkQKBAQAAgYSA0oC
RRo3IE91dHB1dCBvbmx5LiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRp
b24uCgoMCgUEAAIGBRIDSgIICgwKBQQAAgYBEgNKCRQKDAoFBAACBgMSA0oXGAoMCgUEAAIG
CBIDShlECg8KCAQAAgYInAgAEgNKGkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkconnectivity::V1::Common::OperationMetadata ===
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

Google::Cloud::Networkconnectivity::V1::Common - Compiled Protocol Buffers messages for google/cloud/networkconnectivity/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkconnectivity::V1::Common;

    my $msg = Google::Cloud::Networkconnectivity::V1::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkconnectivity::V1::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkconnectivity/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkconnectivity::V1::Common::OperationMetadata

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
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkconnectivity::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
