package Google::Cloud::Batch::V1alpha::Notification;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYmF0Y2gvdjFhbHBoYS9ub3RpZmljYXRpb24ucHJvdG8SGmdvb2ds
ZS5jbG91ZC5iYXRjaC52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
IjYKDE5vdGlmaWNhdGlvbhImCgxwdWJzdWJfdG9waWMYASABKAlCA+BBAlILcHVic3ViVG9w
aWNCywEKHmNvbS5nb29nbGUuY2xvdWQuYmF0Y2gudjFhbHBoYUIRTm90aWZpY2F0aW9uUHJv
dG9QAVo0Y2xvdWQuZ29vZ2xlLmNvbS9nby9iYXRjaC9hcGl2MWFscGhhL2JhdGNocGI7YmF0
Y2hwYqICA0dDQqoCGkdvb2dsZS5DbG91ZC5CYXRjaC5WMUFscGhhygIaR29vZ2xlXENsb3Vk
XEJhdGNoXFYxYWxwaGHqAh1Hb29nbGU6OkNsb3VkOjpCYXRjaDo6VjFhbHBoYUrbCQoGEgQO
ACUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMA
EgMSACkKCAoBCBIDFAA3CgkKAgglEgMUADcKCAoBCBIDFQBLCgkKAggLEgMVAEsKCAoBCBID
FgAiCgkKAggKEgMWACIKCAoBCBIDFwAyCgkKAggIEgMXADIKCAoBCBIDGAA3CgkKAggBEgMY
ADcKCAoBCBIDGQAhCgkKAggkEgMZACEKCAoBCBIDGgA3CgkKAggpEgMaADcKCAoBCBIDGwA2
CgkKAggtEgMbADYKNAoCBAASBB4AJQEaKCBOb3RpZmljYXRpb24gb24gcmVzb3VyY2Ugc3Rh
dGUgY2hhbmdlLgoKCgoDBAABEgMeCBQKyQIKBAQAAgASAyQCQxq7AiBSZXF1aXJlZC4gVGhl
IFB1Yi9TdWIgdG9waWMgd2hlcmUgbm90aWZpY2F0aW9ucyBsaWtlIHRoZSByZXNvdXJjZSBh
bGxvd2FuY2UKIHN0YXRlIGNoYW5nZXMgd2lsbCBiZSBwdWJsaXNoZWQuIFRoZSB0b3BpYyBt
dXN0IGV4aXN0IGluIHRoZSBzYW1lIHByb2plY3QKIGFzIHRoZSBqb2IgYW5kIGJpbGxpbmdz
IHdpbGwgYmUgY2hhcmdlZCB0byB0aGlzIHByb2plY3QuIElmIG5vdCBzcGVjaWZpZWQsCiBu
byBQdWIvU3ViIG1lc3NhZ2VzIHdpbGwgYmUgc2VudC4gVG9waWMgZm9ybWF0OgogYHByb2pl
Y3RzL3twcm9qZWN0fS90b3BpY3Mve3RvcGljfWAuCgoMCgUEAAIABRIDJAIICgwKBQQAAgAB
EgMkCRUKDAoFBAACAAMSAyQYGQoMCgUEAAIACBIDJBpCCg8KCAQAAgAInAgAEgMkG0FiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Batch::V1alpha::Notification::Notification ===
    # Fields for Notification
    # Field: pubsub_topic Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Batch::V1alpha::Notification - Compiled Protocol Buffers messages for google/cloud/batch/v1alpha/notification.proto

=head1 SYNOPSIS

    use Google::Cloud::Batch::V1alpha::Notification;

    my $msg = Google::Cloud::Batch::V1alpha::Notification::Notification->new({
        pubsub_topic => $pubsub_topic,
    });

    # Read or update a field
    my $val = $msg->pubsub_topic();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Batch::V1alpha::Notification::Notification->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/batch/v1alpha/notification.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Batch::V1alpha::Notification::Notification

Notification on resource state change.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pubsub_topic() >> / C<< $msg->pubsub_topic($value) >>

Type: C<String>

Required. The Pub/Sub topic where notifications like the resource allowance
state changes will be published. The topic must exist in the same project
as the job and billings will be charged to this project. If not specified,
no Pub/Sub messages will be sent. Topic format:
`projects/{project}/topics/{topic}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Batch::V1alpha::Notification::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
