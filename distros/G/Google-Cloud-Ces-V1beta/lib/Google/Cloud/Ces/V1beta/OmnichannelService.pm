package Google::Cloud::Ces::V1beta::OmnichannelService;

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
CjFnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9vbW5pY2hhbm5lbF9zZXJ2aWNlLnByb3RvEhdn
b29nbGUuY2xvdWQuY2VzLnYxYmV0YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8ihAIKHE9tbmljaGFubmVsT3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3Rp
bWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUS
OgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2Vu
ZFRpbWUSKgoOc3RhdHVzX21lc3NhZ2UYAyABKAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZy
ZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAQgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlv
bkJnChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCF09tbmljaGFubmVsU2VydmljZVBy
b3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNwYkqP
CwoGEgQOAC0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAg
CgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYA
KQoICgEIEgMYAEQKCQoCCAsSAxgARAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADgK
CQoCCAgSAxoAOAoICgEIEgMbADQKCQoCCAESAxsANApECgIEABIEHgAtARo4IFJlcHJlc2Vu
dHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgoKCgoDBAAB
EgMeCCQKQAoEBAACABIEIAIhMhoyIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgb3BlcmF0
aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAAYSAyACGwoMCgUEAAIAARIDIBwnCgwKBQQAAgAD
EgMgKisKDAoFBAACAAgSAyEGMQoPCggEAAIACJwIABIDIQcwCkUKBAQAAgESBCQCJTIaNyBP
dXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5nLgoK
DAoFBAACAQYSAyQCGwoMCgUEAAIBARIDJBwkCgwKBQQAAgEDEgMkJygKDAoFBAACAQgSAyUG
MQoPCggEAAIBCJwIABIDJQcwCksKBAQAAgISAygCSBo+IE91dHB1dCBvbmx5LiBIdW1hbi1y
ZWFkYWJsZSBzdGF0dXMgb2YgdGhlIG9wZXJhdGlvbiwgaWYgYW55LgoKDAoFBAACAgUSAygC
CAoMCgUEAAICARIDKAkXCgwKBQQAAgIDEgMoGhsKDAoFBAACAggSAygcRwoPCggEAAICCJwI
ABIDKB1GCmUKBAQAAgMSAywCThpYIE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIg
dGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24gb2YgdGhlCiBvcGVyYXRpb24u
CgoMCgUEAAIDBRIDLAIGCgwKBQQAAgMBEgMsBx0KDAoFBAACAwMSAywgIQoMCgUEAAIDCBID
LCJNCg8KCAQAAgMInAgAEgMsI0xiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::OmnichannelService::OmnichannelOperationMetadata ===
    # Fields for OmnichannelOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::OmnichannelService - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/omnichannel_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::OmnichannelService;

    my $msg = Google::Cloud::Ces::V1beta::OmnichannelService::OmnichannelOperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        status_message => $status_message,
        requested_cancellation => $requested_cancellation,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::OmnichannelService::OmnichannelOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/omnichannel_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::OmnichannelService::OmnichannelOperationMetadata

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::OmnichannelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
