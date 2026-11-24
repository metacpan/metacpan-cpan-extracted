package Google::Cloud::Ces::V1::OmnichannelService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvY2VzL3YxL29tbmljaGFubmVsX3NlcnZpY2UucHJvdG8SE2dvb2ds
ZS5jbG91ZC5jZXMudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IoQCChxPbW5pY2hhbm5lbE9wZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90
aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEioK
DnN0YXR1c19tZXNzYWdlGAMgASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVk
X2NhbmNlbGxhdGlvbhgEIAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb25CXwoXY29t
Lmdvb2dsZS5jbG91ZC5jZXMudjFCF09tbmljaGFubmVsU2VydmljZVByb3RvUAFaKWNsb3Vk
Lmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSo8LCgYSBA4ALQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAJgoJCgID
ARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgApCggKAQgSAxgAQAoJCgII
CxIDGABACggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAOAoJCgIICBIDGgA4CggKAQgS
AxsAMAoJCgIIARIDGwAwCkQKAgQAEgQeAC0BGjggUmVwcmVzZW50cyB0aGUgbWV0YWRhdGEg
b2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAAESAx4IJApACgQEAAIAEgQg
AiEyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQu
CgoMCgUEAAIABhIDIAIbCgwKBQQAAgABEgMgHCcKDAoFBAACAAMSAyAqKwoMCgUEAAIACBID
IQYxCg8KCAQAAgAInAgAEgMhBzAKRQoEBAACARIEJAIlMho3IE91dHB1dCBvbmx5LiBUaGUg
dGltZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoMCgUEAAIBBhIDJAIbCgwK
BQQAAgEBEgMkHCQKDAoFBAACAQMSAyQnKAoMCgUEAAIBCBIDJQYxCg8KCAQAAgEInAgAEgMl
BzAKSwoEBAACAhIDKAJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBv
ZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoMCgUEAAICBRIDKAIICgwKBQQAAgIBEgMoCRcK
DAoFBAACAgMSAygaGwoMCgUEAAICCBIDKBxHCg8KCAQAAgIInAgAEgMoHUYKZQoEBAACAxID
LAJOGlggT3V0cHV0IG9ubHkuIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNlciBoYXMgcmVx
dWVzdGVkIGNhbmNlbGxhdGlvbiBvZiB0aGUKIG9wZXJhdGlvbi4KCgwKBQQAAgMFEgMsAgYK
DAoFBAACAwESAywHHQoMCgUEAAIDAxIDLCAhCgwKBQQAAgMIEgMsIk0KDwoIBAACAwicCAAS
AywjTGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata ===
    # Fields for OmnichannelOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::OmnichannelService - Compiled Protocol Buffers messages for google/cloud/ces/v1/omnichannel_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::OmnichannelService;

    my $msg = Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        status_message => $status_message,
        requested_cancellation => $requested_cancellation,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/omnichannel_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata

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

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation of the
operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::OmnichannelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
