package Google::Cloud::Securitycenter::V1::NotificationMessage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Securitycenter::V1::Finding };
    eval { require Google::Cloud::Securitycenter::V1::Resource };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvbm90aWZpY2F0aW9uX21lc3NhZ2Uu
cHJvdG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MRosZ29vZ2xlL2Nsb3VkL3Nl
Y3VyaXR5Y2VudGVyL3YxL2ZpbmRpbmcucHJvdG8aLWdvb2dsZS9jbG91ZC9zZWN1cml0eWNl
bnRlci92MS9yZXNvdXJjZS5wcm90byKMAgoTTm90aWZpY2F0aW9uTWVzc2FnZRI4Chhub3Rp
ZmljYXRpb25fY29uZmlnX25hbWUYASABKAlSFm5vdGlmaWNhdGlvbkNvbmZpZ05hbWUSQwoH
ZmluZGluZxgCIAEoCzInLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5GaW5kaW5n
SABSB2ZpbmRpbmcSRAoIcmVzb3VyY2UYAyABKAsyKC5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjEuUmVzb3VyY2VSCHJlc291cmNlEicKD2RlbGV0ZWRfZmluZGluZxgFIAEoCFIO
ZGVsZXRlZEZpbmRpbmdCBwoFZXZlbnRC8gEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjFCGE5vdGlmaWNhdGlvbk1lc3NhZ2VQcm90b1ABWkpjbG91ZC5nb29nbGUuY29t
L2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50
ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxT
ZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUq8
CgoGEgQOAC4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAn
CgkKAgMAEgMSADYKCQoCAwESAxMANwoICgEIEgMVADsKCQoCCCUSAxUAOwoICgEIEgMWAGEK
CQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADkKCQoCCAgSAxgAOQoI
CgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoICgEIEgMbADoKCQoC
CC0SAxsAOgomCgIEABIEHgAuARoaIENsb3VkIFNDQydzIE5vdGlmaWNhdGlvbgoKCgoDBAAB
EgMeCBsKUwoEBAACABIDIAImGkYgTmFtZSBvZiB0aGUgbm90aWZpY2F0aW9uIGNvbmZpZyB0
aGF0IGdlbmVyYXRlZCBjdXJyZW50IG5vdGlmaWNhdGlvbi4KCgwKBQQAAgAFEgMgAggKDAoF
BAACAAESAyAJIQoMCgUEAAIAAxIDICQlCiMKBAQACAASBCMCJwMaFSBOb3RpZmljYXRpb24g
RXZlbnQuCgoMCgUEAAgAARIDIwgNCloKBAQAAgESAyYEGBpNIElmIGl0J3MgYSBGaW5kaW5n
IGJhc2VkIG5vdGlmaWNhdGlvbiBjb25maWcsIHRoaXMgZmllbGQgd2lsbCBiZQogcG9wdWxh
dGVkLgoKDAoFBAACAQYSAyYECwoMCgUEAAIBARIDJgwTCgwKBQQAAgEDEgMmFhcKRgoEBAAC
AhIDKgIYGjkgVGhlIENsb3VkIHJlc291cmNlIHRpZWQgdG8gdGhpcyBub3RpZmljYXRpb24n
cyBGaW5kaW5nLgoKDAoFBAACAgYSAyoCCgoMCgUEAAICARIDKgsTCgwKBQQAAgIDEgMqFhcK
OAoEBAACAxIDLQIbGisgSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGZpbmRpbmcgaXMgZGVsZXRl
ZC4KCgwKBQQAAgMFEgMtAgYKDAoFBAACAwESAy0HFgoMCgUEAAIDAxIDLRkaYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::NotificationMessage::NotificationMessage ===
    # Fields for NotificationMessage
    # Field: notification_config_name Type: 9 ()
    # Field: finding Type: 11 (.google.cloud.securitycenter.v1.Finding)
    # Field: resource Type: 11 (.google.cloud.securitycenter.v1.Resource)
    # Field: deleted_finding Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::NotificationMessage - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/notification_message.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::NotificationMessage;

    my $msg = Google::Cloud::Securitycenter::V1::NotificationMessage::NotificationMessage->new({
        notification_config_name => $notification_config_name,
        finding => $finding,
        resource => $resource,
        deleted_finding => $deleted_finding,
    });

    # Read or update a field
    my $val = $msg->notification_config_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::NotificationMessage::NotificationMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/notification_message.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::NotificationMessage::NotificationMessage

Cloud SCC's Notification

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->notification_config_name() >> / C<< $msg->notification_config_name($value) >>

Type: C<String>

Name of the notification config that generated current notification.

=item * C<< $msg->finding() >> / C<< $msg->finding($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Finding::Finding>)

If it's a Finding based notification config, this field will be
populated.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Resource::Resource>)

The Cloud resource tied to this notification's Finding.

=item * C<< $msg->deleted_finding() >> / C<< $msg->deleted_finding($value) >>

Type: C<Bool>

Indicates whether the finding is deleted.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::NotificationMessage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
