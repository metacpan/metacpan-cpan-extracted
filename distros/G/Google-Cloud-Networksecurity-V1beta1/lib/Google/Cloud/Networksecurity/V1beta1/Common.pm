package Google::Cloud::Networksecurity::V1beta1::Common;

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
CjFnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvY29tbW9uLnByb3RvEiRn
b29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1QIKEU9w
ZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEoCUID4EED
UgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEioKDnN0YXR1c19tZXNzYWdlGAUg
ASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgGIAEo
CEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YByABKAlCA+BB
A1IKYXBpVmVyc2lvbkKFAgooY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFi
ZXRhMUILQ29tbW9uUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJp
dHkvYXBpdjFiZXRhMS9uZXR3b3Jrc2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCJEdv
b2dsZS5DbG91ZC5OZXR3b3JrU2VjdXJpdHkuVjFCZXRhMcoCJEdvb2dsZVxDbG91ZFxOZXR3
b3JrU2VjdXJpdHlcVjFiZXRhMeoCJ0dvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6
VjFiZXRhMUqoEAoGEgQOADkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVAEEKCQoCCCUSAxUAQQoI
CgEIEgMWAGkKCQoCCAsSAxYAaQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYACwKCQoC
CAgSAxgALAoICgEIEgMZAEEKCQoCCAESAxkAQQoICgEIEgMaAEEKCQoCCCkSAxoAQQoICgEI
EgMbAEAKCQoCCC0SAxsAQApECgIEABIEHgA5ARo4IFJlcHJlc2VudHMgdGhlIG1ldGFkYXRh
IG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uLgoKCgoDBAABEgMeCBkKQAoEBAACABIE
IAIhMhoyIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVk
LgoKDAoFBAACAAYSAyACGwoMCgUEAAIAARIDIBwnCgwKBQQAAgADEgMgKisKDAoFBAACAAgS
AyEGMQoPCggEAAIACJwIABIDIQcwCkUKBAQAAgESBCQCJTIaNyBPdXRwdXQgb25seS4gVGhl
IHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5nLgoKDAoFBAACAQYSAyQCGwoM
CgUEAAIBARIDJBwkCgwKBQQAAgEDEgMkJygKDAoFBAACAQgSAyUGMQoPCggEAAIBCJwIABID
JQcwClkKBAQAAgISAygCQBpMIE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJj
ZSBwYXRoIGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAAICBRIDKAII
CgwKBQQAAgIBEgMoCQ8KDAoFBAACAgMSAygSEwoMCgUEAAICCBIDKBQ/Cg8KCAQAAgIInAgA
EgMoFT4KRwoEBAACAxIDKwI+GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhl
Y3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgMFEgMrAggKDAoFBAACAwESAysJDQoM
CgUEAAIDAxIDKxARCgwKBQQAAgMIEgMrEj0KDwoIBAACAwicCAASAysTPApLCgQEAAIEEgMu
AkgaPiBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRp
b24sIGlmIGFueS4KCgwKBQQAAgQFEgMuAggKDAoFBAACBAESAy4JFwoMCgUEAAIEAxIDLhob
CgwKBQQAAgQIEgMuHEcKDwoIBAACBAicCAASAy4dRgqaAgoEBAACBRIDNQJOGowCIE91dHB1
dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5j
ZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nl
c3NmdWxseSBiZWVuIGNhbmNlbGxlZAogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtdIHZhbHVl
IHdpdGggYQogW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNv
ZGVdIG9mIDEsIGNvcnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoMCgUEAAIF
BRIDNQIGCgwKBQQAAgUBEgM1Bx0KDAoFBAACBQMSAzUgIQoMCgUEAAIFCBIDNSJNCg8KCAQA
AgUInAgAEgM1I0wKRAoEBAACBhIDOAJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVz
ZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgYFEgM4AggKDAoFBAACBgESAzgJ
FAoMCgUEAAIGAxIDOBcYCgwKBQQAAgYIEgM4GUQKDwoIBAACBgicCAASAzgaQ2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1beta1::Common::OperationMetadata ===
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

Google::Cloud::Networksecurity::V1beta1::Common - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1beta1::Common;

    my $msg = Google::Cloud::Networksecurity::V1beta1::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1beta1::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1beta1::Common::OperationMetadata

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
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
