package Google::Iam::V3beta::OperationMetadata;

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
Cipnb29nbGUvaWFtL3YzYmV0YS9vcGVyYXRpb25fbWV0YWRhdGEucHJvdG8SEWdvb2dsZS5p
YW0udjNiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvItUCChFPcGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVf
dGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGlt
ZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IH
ZW5kVGltZRIbCgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZlcmIYBCABKAlCA+BB
A1IEdmVyYhIqCg5zdGF0dXNfbWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0dXNNZXNzYWdlEjoK
FnJlcXVlc3RlZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0
aW9uEiQKC2FwaV92ZXJzaW9uGAcgASgJQgPgQQNSCmFwaVZlcnNpb25ClAEKFWNvbS5nb29n
bGUuaWFtLnYzYmV0YUIWT3BlcmF0aW9uTWV0YWRhdGFQcm90b1ABWi1jbG91ZC5nb29nbGUu
Y29tL2dvL2lhbS9hcGl2M2JldGEvaWFtcGI7aWFtcGKqAhdHb29nbGUuQ2xvdWQuSWFtLlYz
QmV0YcoCF0dvb2dsZVxDbG91ZFxJYW1cVjNiZXRhSogQCgYSBA4AOAEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABoKCQoCAwASAxIAKQoJCgIDARIDEwAp
CggKAQgSAxUANAoJCgIIJRIDFQA0CggKAQgSAxYARAoJCgIICxIDFgBECggKAQgSAxcAIgoJ
CgIIChIDFwAiCggKAQgSAxgANwoJCgIICBIDGAA3CggKAQgSAxkALgoJCgIIARIDGQAuCggK
AQgSAxoANAoJCgIIKRIDGgA0CkQKAgQAEgQdADgBGjggUmVwcmVzZW50cyB0aGUgbWV0YWRh
dGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAAESAx0IGQpACgQEAAIA
EgQfAiAyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0
ZWQuCgoMCgUEAAIABhIDHwIbCgwKBQQAAgABEgMfHCcKDAoFBAACAAMSAx8qKwoMCgUEAAIA
CBIDIAYxCg8KCAQAAgAInAgAEgMgBzAKRQoEBAACARIEIwIkMho3IE91dHB1dCBvbmx5LiBU
aGUgdGltZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoMCgUEAAIBBhIDIwIb
CgwKBQQAAgEBEgMjHCQKDAoFBAACAQMSAyMnKAoMCgUEAAIBCBIDJAYxCg8KCAQAAgEInAgA
EgMkBzAKTgoEBAACAhIDJwJAGkEgT3V0cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJlc291
cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQgb2YgdGhlCgoMCgUEAAICBRIDJwIICgwKBQQAAgIB
EgMnCQ8KDAoFBAACAgMSAycSEwoMCgUEAAICCBIDJxQ/Cg8KCAQAAgIInAgAEgMnFT4KRwoE
BAACAxIDKgI+GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkg
dGhlIG9wZXJhdGlvbi4KCgwKBQQAAgMFEgMqAggKDAoFBAACAwESAyoJDQoMCgUEAAIDAxID
KhARCgwKBQQAAgMIEgMqEj0KDwoIBAACAwicCAASAyoTPApLCgQEAAIEEgMtAkgaPiBPdXRw
dXQgb25seS4gSHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFu
eS4KCgwKBQQAAgQFEgMtAggKDAoFBAACBAESAy0JFwoMCgUEAAIEAxIDLRobCgwKBQQAAgQI
EgMtHEcKDwoIBAACBAicCAASAy0dRgqaAgoEBAACBRIDNAJOGowCIE91dHB1dCBvbmx5LiBJ
ZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24K
IG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBi
ZWVuIGNhbmNlbGxlZAogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtdIHZhbHVlIHdpdGggYQog
W2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEs
IGNvcnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoMCgUEAAIFBRIDNAIGCgwK
BQQAAgUBEgM0Bx0KDAoFBAACBQMSAzQgIQoMCgUEAAIFCBIDNCJNCg8KCAQAAgUInAgAEgM0
I0wKRAoEBAACBhIDNwJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3Rh
cnQgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgYFEgM3AggKDAoFBAACBgESAzcJFAoMCgUEAAIG
AxIDNxcYCgwKBQQAAgYIEgM3GUQKDwoIBAACBgicCAASAzcaQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::OperationMetadata::OperationMetadata ===
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

Google::Iam::V3beta::OperationMetadata - Compiled Protocol Buffers messages for google/iam/v3beta/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::OperationMetadata;

    my $msg = Google::Iam::V3beta::OperationMetadata::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::OperationMetadata::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::OperationMetadata::OperationMetadata

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
