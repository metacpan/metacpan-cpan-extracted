package Google::Iam::V3::OperationMetadata;

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
CiZnb29nbGUvaWFtL3YzL29wZXJhdGlvbl9tZXRhZGF0YS5wcm90bxINZ29vZ2xlLmlhbS52
MxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byLVAgoRT3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5k
X3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUS
GwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmIS
KgoOc3RhdHVzX21lc3NhZ2UYBSABKAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0
ZWRfY2FuY2VsbGF0aW9uGAYgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgth
cGlfdmVyc2lvbhgHIAEoCUID4EEDUgphcGlWZXJzaW9uQoQBChFjb20uZ29vZ2xlLmlhbS52
M0IWT3BlcmF0aW9uTWV0YWRhdGFQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2lhbS9h
cGl2My9pYW1wYjtpYW1wYqoCE0dvb2dsZS5DbG91ZC5JYW0uVjPKAhNHb29nbGVcQ2xvdWRc
SWFtXFYzSogQCgYSBA4AOAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQABYKCQoCAwASAxIAKQoJCgIDARIDEwApCggKAQgSAxUAMAoJCgIIJRIDFQAwCggK
AQgSAxYAQAoJCgIICxIDFgBACggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgANwoJCgII
CBIDGAA3CggKAQgSAxkAKgoJCgIIARIDGQAqCggKAQgSAxoAMAoJCgIIKRIDGgAwCkQKAgQA
EgQdADgBGjggUmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBv
cGVyYXRpb24uCgoKCgMEAAESAx0IGQpACgQEAAIAEgQfAiAyGjIgT3V0cHV0IG9ubHkuIFRo
ZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoMCgUEAAIABhIDHwIbCgwKBQQA
AgABEgMfHCcKDAoFBAACAAMSAx8qKwoMCgUEAAIACBIDIAYxCg8KCAQAAgAInAgAEgMgBzAK
RQoEBAACARIEIwIkMho3IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIGZp
bmlzaGVkIHJ1bm5pbmcuCgoMCgUEAAIBBhIDIwIbCgwKBQQAAgEBEgMjHCQKDAoFBAACAQMS
AyMnKAoMCgUEAAIBCBIDJAYxCg8KCAQAAgEInAgAEgMkBzAKTgoEBAACAhIDJwJAGkEgT3V0
cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJlc291cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQg
b2YgdGhlCgoMCgUEAAICBRIDJwIICgwKBQQAAgIBEgMnCQ8KDAoFBAACAgMSAycSEwoMCgUE
AAICCBIDJxQ/Cg8KCAQAAgIInAgAEgMnFT4KRwoEBAACAxIDKgI+GjogT3V0cHV0IG9ubHku
IE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgMF
EgMqAggKDAoFBAACAwESAyoJDQoMCgUEAAIDAxIDKhARCgwKBQQAAgMIEgMqEj0KDwoIBAAC
AwicCAASAyoTPApLCgQEAAIEEgMtAkgaPiBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFibGUg
c3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCgwKBQQAAgQFEgMtAggKDAoFBAAC
BAESAy0JFwoMCgUEAAIEAxIDLRobCgwKBQQAAgQIEgMtHEcKDwoIBAACBAicCAASAy0dRgqa
AgoEBAACBRIDNAJOGowCIE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVz
ZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJh
dGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVuIGNhbmNlbGxlZAogaGF2ZSBbT3Bl
cmF0aW9uLmVycm9yXVtdIHZhbHVlIHdpdGggYQogW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVd
W2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsIGNvcnJlc3BvbmRpbmcgdG8KIGBDb2Rl
LkNBTkNFTExFRGAuCgoMCgUEAAIFBRIDNAIGCgwKBQQAAgUBEgM0Bx0KDAoFBAACBQMSAzQg
IQoMCgUEAAIFCBIDNCJNCg8KCAQAAgUInAgAEgM0I0wKRAoEBAACBhIDNwJFGjcgT3V0cHV0
IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCgwKBQQA
AgYFEgM3AggKDAoFBAACBgESAzcJFAoMCgUEAAIGAxIDNxcYCgwKBQQAAgYIEgM3GUQKDwoI
BAACBgicCAASAzcaQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::OperationMetadata::OperationMetadata ===
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

Google::Iam::V3::OperationMetadata - Compiled Protocol Buffers messages for google/iam/v3/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Iam::V3::OperationMetadata;

    my $msg = Google::Iam::V3::OperationMetadata::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::OperationMetadata::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::OperationMetadata::OperationMetadata

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

Output only. Server-defined resource path for the target of the

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
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
