package Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Rpc::Http };
    my $descriptor_b64 = <<'EOF';
Ckhnb29nbGUvZGV2aWNlc2FuZHNlcnZpY2VzL2hlYWx0aC92NC93ZWJob29rX25vdGlmaWNh
dGlvbl9jbG91ZF9sb2cucHJvdG8SI2dvb2dsZS5kZXZpY2VzYW5kc2VydmljZXMuaGVhbHRo
LnY0Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhVnb29nbGUvcnBjL2h0dHAu
cHJvdG8iYQobV2ViaG9va05vdGlmaWNhdGlvbkNsb3VkTG9nEkIKDWh0dHBfcmVzcG9uc2UY
ASABKAsyGC5nb29nbGUucnBjLkh0dHBSZXNwb25zZUID4EECUgxodHRwUmVzcG9uc2VCkgIK
J2NvbS5nb29nbGUuZGV2aWNlc2FuZHNlcnZpY2VzLmhlYWx0aC52NEIgV2ViaG9va05vdGlm
aWNhdGlvbkNsb3VkTG9nUHJvdG9QAVpOZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29v
Z2xlYXBpcy9kZXZpY2VzYW5kc2VydmljZXMvaGVhbHRoL2FwaXY0O2hlYWx0aHBiqgIjR29v
Z2xlLkRldmljZXNBbmRTZXJ2aWNlcy5IZWFsdGguVjTKAiNHb29nbGVcRGV2aWNlc0FuZFNl
cnZpY2VzXEhlYWx0aFxWNOoCJkdvb2dsZTo6RGV2aWNlc0FuZFNlcnZpY2VzOjpIZWFsdGg6
OlY0Sv0ICgYSBA4AJAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAfCggKAQgSAxUAQAoJCgIIJRIDFQBACggKAQgS
AxYAZQoJCgIICxIDFgBlCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAQQoJCgIICBID
GABBCggKAQgSAxkAQAoJCgIIARIDGQBACggKAQgSAxoAQAoJCgIIKRIDGgBACggKAQgSAxsA
PwoJCgIILRIDGwA/CqcBCgIEABIEHwAkARqaASBMb2cgbWVzc2FnZSBmb3IgYSB3ZWJob29r
IG5vdGlmaWNhdGlvbiBzZW50IGJ5IHRoZSBHb29nbGUgSGVhbHRoIEFQSSB0byBhCiBzdWJz
Y3JpYmVyJ3MgZW5kcG9pbnQuIEluY2x1ZGVzIHRoZSBIVFRQIHJlc3BvbnNlIHJlY2VpdmVk
IGZyb20gdGhlIGVuZHBvaW50LgoKCgoDBAABEgMfCCMKgQEKBAQAAgASBCICIy8acyBSZXF1
aXJlZC4gUmVwcmVzZW50cyB0aGUgSFRUUCByZXNwb25zZS4KIFRoaXMgbWVzc2FnZSBpbmNs
dWRlcyB0aGUgc3RhdHVzIGNvZGUsIHJlYXNvbiBwaHJhc2UsIGhlYWRlcnMsIGFuZCBib2R5
LgoKDAoFBAACAAYSAyICGQoMCgUEAAIAARIDIhonCgwKBQQAAgADEgMiKisKDAoFBAACAAgS
AyMGLgoPCggEAAIACJwIABIDIwctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog ===
    # Fields for WebhookNotificationCloudLog
    # Field: http_response Type: 11 (.google.rpc.HttpResponse)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog - Compiled Protocol Buffers messages for google/devicesandservices/health/v4/webhook_notification_cloud_log.proto

=head1 SYNOPSIS

    use Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog;

    my $msg = Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog->new({
        http_response => $http_response,
    });

    # Read or update a field
    my $val = $msg->http_response();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devicesandservices/health/v4/webhook_notification_cloud_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog

Log message for a webhook notification sent by the Google Health API to a
subscriber's endpoint. Includes the HTTP response received from the endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->http_response() >> / C<< $msg->http_response($value) >>

Type: C<Message> (L<Google::Rpc::Http::HttpResponse>)

Required. Represents the HTTP response.
This message includes the status code, reason phrase, headers, and body.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
