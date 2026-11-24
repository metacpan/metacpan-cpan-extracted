package Google::Cloud::Deploy::V1::ReleaseNotificationPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Deploy::V1::LogEnums };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGVwbG95L3YxL3JlbGVhc2Vfbm90aWZpY2F0aW9uX3BheWxvYWQu
cHJvdG8SFmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaJmdvb2dsZS9jbG91ZC9kZXBsb3kvdjEv
bG9nX2VudW1zLnByb3RvIsQBChhSZWxlYXNlTm90aWZpY2F0aW9uRXZlbnQSGAoHbWVzc2Fn
ZRgBIAEoCVIHbWVzc2FnZRIhCgxwaXBlbGluZV91aWQYBCABKAlSC3BpcGVsaW5lVWlkEh8K
C3JlbGVhc2VfdWlkGAUgASgJUgpyZWxlYXNlVWlkEhgKB3JlbGVhc2UYAiABKAlSB3JlbGVh
c2USMAoEdHlwZRgDIAEoDjIcLmdvb2dsZS5jbG91ZC5kZXBsb3kudjEuVHlwZVIEdHlwZUJz
Chpjb20uZ29vZ2xlLmNsb3VkLmRlcGxveS52MUIfUmVsZWFzZU5vdGlmaWNhdGlvblBheWxv
YWRQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2RlcGxveS9hcGl2MS9kZXBsb3lwYjtk
ZXBsb3lwYkrvCgoGEgQOACsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
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
CAoBAhIDEAAfCgkKAgMAEgMSADAKCAoBCBIDFABJCgkKAggLEgMUAEkKCAoBCBIDFQAiCgkK
AggKEgMVACIKCAoBCBIDFgBACgkKAggIEgMWAEAKCAoBCBIDFwAzCgkKAggBEgMXADMKtgEK
AgQAEgQcACsBGqkBIFBheWxvYWQgcHJvdG8gZm9yICJjbG91ZGRlcGxveS5nb29nbGVhcGlz
LmNvbS9yZWxlYXNlX25vdGlmaWNhdGlvbiIKIFBsYXRmb3JtIExvZyBldmVudCB0aGF0IGRl
c2NyaWJlcyB0aGUgZmFpbHVyZSB0byBzZW5kIHJlbGVhc2Ugc3RhdHVzIGNoYW5nZQogUHVi
L1N1YiBub3RpZmljYXRpb24uCgoKCgMEAAESAxwIIApDCgQEAAIAEgMeAhUaNiBEZWJ1ZyBt
ZXNzYWdlIGZvciB3aGVuIGEgbm90aWZpY2F0aW9uIGZhaWxzIHRvIHNlbmQuCgoMCgUEAAIA
BRIDHgIICgwKBQQAAgABEgMeCRAKDAoFBAACAAMSAx4TFAo7CgQEAAIBEgMhAhoaLiBVbmlx
dWUgaWRlbnRpZmllciBvZiB0aGUgYERlbGl2ZXJ5UGlwZWxpbmVgLgoKDAoFBAACAQUSAyEC
CAoMCgUEAAIBARIDIQkVCgwKBQQAAgEDEgMhGBkKMgoEBAACAhIDJAIZGiUgVW5pcXVlIGlk
ZW50aWZpZXIgb2YgdGhlIGBSZWxlYXNlYC4KCgwKBQQAAgIFEgMkAggKDAoFBAACAgESAyQJ
FAoMCgUEAAICAxIDJBcYCikKBAQAAgMSAycCFRocIFRoZSBuYW1lIG9mIHRoZSBgUmVsZWFz
ZWAuCgoMCgUEAAIDBRIDJwIICgwKBQQAAgMBEgMnCRAKDAoFBAACAwMSAycTFApFCgQEAAIE
EgMqAhAaOCBUeXBlIG9mIHRoaXMgbm90aWZpY2F0aW9uLCBlLmcuIGZvciBhIFB1Yi9TdWIg
ZmFpbHVyZS4KCgwKBQQAAgQGEgMqAgYKDAoFBAACBAESAyoHCwoMCgUEAAIEAxIDKg4PYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent ===
    # Fields for ReleaseNotificationEvent
    # Field: message Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: release_uid Type: 9 ()
    # Field: release Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::ReleaseNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/release_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::ReleaseNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent->new({
        message => $message,
        pipeline_uid => $pipeline_uid,
        release_uid => $release_uid,
        release => $release,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/release_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent

Payload proto for "clouddeploy.googleapis.com/release_notification"
Platform Log event that describes the failure to send release status change
Pub/Sub notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a notification fails to send.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `DeliveryPipeline`.

=item * C<< $msg->release_uid() >> / C<< $msg->release_uid($value) >>

Type: C<String>

Unique identifier of the `Release`.

=item * C<< $msg->release() >> / C<< $msg->release($value) >>

Type: C<String>

The name of the `Release`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::ReleaseNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
