package Google::Cloud::Common::OperationMetadata;

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
Cixnb29nbGUvY2xvdWQvY29tbW9uL29wZXJhdGlvbl9tZXRhZGF0YS5wcm90bxITZ29vZ2xl
LmNsb3VkLmNvbW1vbhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLHAgoRT3BlcmF0aW9uTWV0YWRhdGESQAoLY3Jl
YXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0
ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdldBIXCgR2ZXJiGAQgASgJ
QgPgQQNSBHZlcmISKAoNc3RhdHVzX2RldGFpbBgFIAEoCUID4EEDUgxzdGF0dXNEZXRhaWwS
LgoQY2FuY2VsX3JlcXVlc3RlZBgGIAEoCEID4EEDUg9jYW5jZWxSZXF1ZXN0ZWQSJAoLYXBp
X3ZlcnNpb24YByABKAlCA+BBA1IKYXBpVmVyc2lvbkJWChdjb20uZ29vZ2xlLmNsb3VkLmNv
bW1vblABWjlnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2Nsb3VkL2Nv
bW1vbjtjb21tb25KvQ8KBhIEDgA0AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBIDFQBQCgkKAggLEgMV
AFAKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAwCgkKAggBEgMXADAKRAoCBAASBBoA
NAEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJh
dGlvbi4KCgoKAwQAARIDGggZCkAKBAQAAgASBBwCHTIaMiBPdXRwdXQgb25seS4gVGhlIHRp
bWUgdGhlIG9wZXJhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgAGEgMcAhsKDAoFBAACAAES
AxwcJwoMCgUEAAIAAxIDHCorCgwKBQQAAgAIEgMdBjEKDwoIBAACAAicCAASAx0HMApFCgQE
AAIBEgQgAiEyGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNo
ZWQgcnVubmluZy4KCgwKBQQAAgEGEgMgAhsKDAoFBAACAQESAyAcJAoMCgUEAAIBAxIDICco
CgwKBQQAAgEIEgMhBjEKDwoIBAACAQicCAASAyEHMApZCgQEAAICEgMkAkAaTCBPdXRwdXQg
b25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0
aGUgb3BlcmF0aW9uLgoKDAoFBAACAgUSAyQCCAoMCgUEAAICARIDJAkPCgwKBQQAAgIDEgMk
EhMKDAoFBAACAggSAyQUPwoPCggEAAICCJwIABIDJBU+CkcKBAQAAgMSAycCPho6IE91dHB1
dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoM
CgUEAAIDBRIDJwIICgwKBQQAAgMBEgMnCQ0KDAoFBAACAwMSAycQEQoMCgUEAAIDCBIDJxI9
Cg8KCAQAAgMInAgAEgMnEzwKSwoEBAACBBIDKgJHGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJl
YWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoMCgUEAAIEBRIDKgII
CgwKBQQAAgQBEgMqCRYKDAoFBAACBAMSAyoZGgoMCgUEAAIECBIDKhtGCg8KCAQAAgQInAgA
EgMqHEUKgwIKBAQAAgUSAzACSBr1ASBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVy
IHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9u
LiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQKIGhh
dmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3RhdHVz
LmNvZGVdW10gb2YgMSwKIGNvcnJlc3BvbmRpbmcgdG8gYENvZGUuQ0FOQ0VMTEVEYC4KCgwK
BQQAAgUFEgMwAgYKDAoFBAACBQESAzAHFwoMCgUEAAIFAxIDMBobCgwKBQQAAgUIEgMwHEcK
DwoIBAACBQicCAASAzAdRgpECgQEAAIGEgMzAkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNp
b24gdXNlZCB0byBzdGFydCB0aGUgb3BlcmF0aW9uLgoKDAoFBAACBgUSAzMCCAoMCgUEAAIG
ARIDMwkUCgwKBQQAAgYDEgMzFxgKDAoFBAACBggSAzMZRAoPCggEAAIGCJwIABIDMxpDYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Common::OperationMetadata::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_detail Type: 9 ()
    # Field: cancel_requested Type: 8 ()
    # Field: api_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Common::OperationMetadata - Compiled Protocol Buffers messages for google/cloud/common/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Common::OperationMetadata;

    my $msg = Google::Cloud::Common::OperationMetadata::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Common::OperationMetadata::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/common/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Common::OperationMetadata::OperationMetadata

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

=item * C<< $msg->status_detail() >> / C<< $msg->status_detail($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->cancel_requested() >> / C<< $msg->cancel_requested($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a [google.rpc.Status.code][] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Common::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
