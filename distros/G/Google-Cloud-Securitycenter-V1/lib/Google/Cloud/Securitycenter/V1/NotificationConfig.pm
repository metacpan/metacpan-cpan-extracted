package Google::Cloud::Securitycenter::V1::NotificationConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvbm90aWZpY2F0aW9uX2NvbmZpZy5w
cm90bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvItkFChJOb3RpZmlj
YXRpb25Db25maWcSEgoEbmFtZRgBIAEoCVIEbmFtZRIgCgtkZXNjcmlwdGlvbhgCIAEoCVIL
ZGVzY3JpcHRpb24SQwoMcHVic3ViX3RvcGljGAMgASgJQiD6QR0KG3B1YnN1Yi5nb29nbGVh
cGlzLmNvbS9Ub3BpY1ILcHVic3ViVG9waWMSLAoPc2VydmljZV9hY2NvdW50GAQgASgJQgPg
QQNSDnNlcnZpY2VBY2NvdW50Em8KEHN0cmVhbWluZ19jb25maWcYBSABKAsyQi5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjEuTm90aWZpY2F0aW9uQ29uZmlnLlN0cmVhbWluZ0Nv
bmZpZ0gAUg9zdHJlYW1pbmdDb25maWcSSQoeZGVsZXRpb25fbm90aWZpY2F0aW9uc19lbmFi
bGVkGAcgASgIQgPgQQFSHGRlbGV0aW9uTm90aWZpY2F0aW9uc0VuYWJsZWQaKQoPU3RyZWFt
aW5nQ29uZmlnEhYKBmZpbHRlchgBIAEoCVIGZmlsdGVyOqEC6kGdAgowc2VjdXJpdHljZW50
ZXIuZ29vZ2xlYXBpcy5jb20vTm90aWZpY2F0aW9uQ29uZmlnEkZvcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb259L25vdGlmaWNhdGlvbkNvbmZpZ3Mve25vdGlmaWNhdGlvbl9jb25maWd9
Ejpmb2xkZXJzL3tmb2xkZXJ9L25vdGlmaWNhdGlvbkNvbmZpZ3Mve25vdGlmaWNhdGlvbl9j
b25maWd9Ejxwcm9qZWN0cy97cHJvamVjdH0vbm90aWZpY2F0aW9uQ29uZmlncy97bm90aWZp
Y2F0aW9uX2NvbmZpZ30qE25vdGlmaWNhdGlvbkNvbmZpZ3MyEm5vdGlmaWNhdGlvbkNvbmZp
Z0IPCg1ub3RpZnlfY29uZmlnQrQCCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVy
LnYxQhdOb3RpZmljYXRpb25Db25maWdQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3Nl
Y3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoC
Hkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0
eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMepBQAobcHVi
c3ViLmdvb2dsZWFwaXMuY29tL1RvcGljEiFwcm9qZWN0cy97cHJvamVjdH0vdG9waWNzL3t0
b3BpY31KkBsKBhIEDgBqAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQA7CgkKAgglEgMVADsKCAoB
CBIDFgBhCgkKAggLEgMWAGEKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA4CgkKAggI
EgMYADgKCAoBCBIDGQA7CgkKAggBEgMZADsKCAoBCBIDGgA7CgkKAggpEgMaADsKCAoBCBID
GwA6CgkKAggtEgMbADoKCQoBCBIEHAAfAgoMCgQInQgAEgQcAB8CCusBCgIEABIEJQBqARre
ASBDbG91ZCBTZWN1cml0eSBDb21tYW5kIENlbnRlciAoQ2xvdWQgU0NDKSBub3RpZmljYXRp
b24gY29uZmlncy4KCiBBIG5vdGlmaWNhdGlvbiBjb25maWcgaXMgYSBDbG91ZCBTQ0MgcmVz
b3VyY2UgdGhhdCBjb250YWlucyB0aGUgY29uZmlndXJhdGlvbgogdG8gc2VuZCBub3RpZmlj
YXRpb25zIGZvciBjcmVhdGUvdXBkYXRlIGV2ZW50cyBvZiBmaW5kaW5ncywgYXNzZXRzIGFu
ZCBldGMuCgoKCgMEAAESAyUIGgoLCgMEAAcSBCYCLQQKDQoFBAAHnQgSBCYCLQQKbwoEBAAD
ABIEMQJIAxphIFRoZSBjb25maWcgZm9yIHN0cmVhbWluZy1iYXNlZCBub3RpZmljYXRpb25z
LCB3aGljaCBzZW5kIGVhY2ggZXZlbnQgYXMgc29vbgogYXMgaXQgaXMgZGV0ZWN0ZWQuCgoM
CgUEAAMAARIDMQoZCrEGCgYEAAMAAgASA0cEFhqhBiBFeHByZXNzaW9uIHRoYXQgZGVmaW5l
cyB0aGUgZmlsdGVyIHRvIGFwcGx5IGFjcm9zcyBjcmVhdGUvdXBkYXRlIGV2ZW50cwogb2Yg
YXNzZXRzIG9yIGZpbmRpbmdzIGFzIHNwZWNpZmllZCBieSB0aGUgZXZlbnQgdHlwZS4gVGhl
IGV4cHJlc3Npb24gaXMgYQogbGlzdCBvZiB6ZXJvIG9yIG1vcmUgcmVzdHJpY3Rpb25zIGNv
bWJpbmVkIHZpYSBsb2dpY2FsIG9wZXJhdG9ycyBgQU5EYAogYW5kIGBPUmAuIFBhcmVudGhl
c2VzIGFyZSBzdXBwb3J0ZWQsIGFuZCBgT1JgIGhhcyBoaWdoZXIgcHJlY2VkZW5jZSB0aGFu
CiBgQU5EYC4KCiBSZXN0cmljdGlvbnMgaGF2ZSB0aGUgZm9ybSBgPGZpZWxkPiA8b3BlcmF0
b3I+IDx2YWx1ZT5gIGFuZCBtYXkgaGF2ZSBhCiBgLWAgY2hhcmFjdGVyIGluIGZyb250IG9m
IHRoZW0gdG8gaW5kaWNhdGUgbmVnYXRpb24uIFRoZSBmaWVsZHMgbWFwIHRvCiB0aG9zZSBk
ZWZpbmVkIGluIHRoZSBjb3JyZXNwb25kaW5nIHJlc291cmNlLgoKIFRoZSBzdXBwb3J0ZWQg
b3BlcmF0b3JzIGFyZToKCiAqIGA9YCBmb3IgYWxsIHZhbHVlIHR5cGVzLgogKiBgPmAsIGA8
YCwgYD49YCwgYDw9YCBmb3IgaW50ZWdlciB2YWx1ZXMuCiAqIGA6YCwgbWVhbmluZyBzdWJz
dHJpbmcgbWF0Y2hpbmcsIGZvciBzdHJpbmdzLgoKIFRoZSBzdXBwb3J0ZWQgdmFsdWUgdHlw
ZXMgYXJlOgoKICogc3RyaW5nIGxpdGVyYWxzIGluIHF1b3Rlcy4KICogaW50ZWdlciBsaXRl
cmFscyB3aXRob3V0IHF1b3Rlcy4KICogYm9vbGVhbiBsaXRlcmFscyBgdHJ1ZWAgYW5kIGBm
YWxzZWAgd2l0aG91dCBxdW90ZXMuCgoOCgcEAAMAAgAFEgNHBAoKDgoHBAADAAIAARIDRwsR
Cg4KBwQAAwACAAMSA0cUFQr2AgoEBAACABIDUAISGugCIFRoZSByZWxhdGl2ZSByZXNvdXJj
ZSBuYW1lIG9mIHRoaXMgbm90aWZpY2F0aW9uIGNvbmZpZy4gU2VlOgogaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI3JlbGF0aXZlX3Jlc291
cmNlX25hbWUKIEV4YW1wbGU6CiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9u
b3RpZmljYXRpb25Db25maWdzL25vdGlmeV9wdWJsaWNfYnVja2V0IiwKICJmb2xkZXJzL3tm
b2xkZXJfaWR9L25vdGlmaWNhdGlvbkNvbmZpZ3Mvbm90aWZ5X3B1YmxpY19idWNrZXQiLAog
b3IgInByb2plY3RzL3twcm9qZWN0X2lkfS9ub3RpZmljYXRpb25Db25maWdzL25vdGlmeV9w
dWJsaWNfYnVja2V0Ii4KCgwKBQQAAgAFEgNQAggKDAoFBAACAAESA1AJDQoMCgUEAAIAAxID
UBARClMKBAQAAgESA1MCGRpGIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgbm90aWZpY2F0aW9u
IGNvbmZpZyAobWF4IG9mIDEwMjQgY2hhcmFjdGVycykuCgoMCgUEAAIBBRIDUwIICgwKBQQA
AgEBEgNTCRQKDAoFBAACAQMSA1MXGApyCgQEAAICEgRXAlkEGmQgVGhlIFB1Yi9TdWIgdG9w
aWMgdG8gc2VuZCBub3RpZmljYXRpb25zIHRvLiBJdHMgZm9ybWF0IGlzCiAicHJvamVjdHMv
W3Byb2plY3RfaWRdL3RvcGljcy9bdG9waWNdIi4KCgwKBQQAAgIFEgNXAggKDAoFBAACAgES
A1cJFQoMCgUEAAICAxIDVxgZCg0KBQQAAgIIEgRXGlkDCg4KBwQAAgIInwgSA1gETQp/CgQE
AAIDEgNdAkkaciBPdXRwdXQgb25seS4gVGhlIHNlcnZpY2UgYWNjb3VudCB0aGF0IG5lZWRz
ICJwdWJzdWIudG9waWNzLnB1Ymxpc2giCiBwZXJtaXNzaW9uIHRvIHB1Ymxpc2ggdG8gdGhl
IFB1Yi9TdWIgdG9waWMuCgoMCgUEAAIDBRIDXQIICgwKBQQAAgMBEgNdCRgKDAoFBAACAwMS
A10bHAoMCgUEAAIDCBIDXR1ICg8KCAQAAgMInAgAEgNdHkcKOAoEBAAIABIEYAJjAxoqIFRo
ZSBjb25maWcgZm9yIHRyaWdnZXJpbmcgbm90aWZpY2F0aW9ucy4KCgwKBQQACAABEgNgCBUK
RwoEBAACBBIDYgQpGjogVGhlIGNvbmZpZyBmb3IgdHJpZ2dlcmluZyBzdHJlYW1pbmctYmFz
ZWQgbm90aWZpY2F0aW9ucy4KCgwKBQQAAgQGEgNiBBMKDAoFBAACBAESA2IUJAoMCgUEAAIE
AxIDYicoCtQBCgQEAAIFEgRoAmkvGsUBIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0
aGUgbm90aWZpY2F0aW9ucyB3aWxsIGJlIHNlbnQgZm9yIGRlbGV0ZWQKIGZpbmRpbmdzLiBX
aGVuIGVuYWJsZWQsIHRoZSBmaWx0ZXIgZGVmaW5lZCBpbiB0aGUgc3RyZWFtaW5nIGNvbmZp
ZyBpcyBzdGlsbAogcmVzcGVjdGVkIHdoZW4gc2VuZGluZyBkZWxldGlvbiBub3RpZmljYXRp
b25zLgoKDAoFBAACBQUSA2gCBgoMCgUEAAIFARIDaAclCgwKBQQAAgUDEgNoKCkKDAoFBAAC
BQgSA2kGLgoPCggEAAIFCJwIABIDaQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig ===
    # Fields for NotificationConfig
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: pubsub_topic Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: streaming_config Type: 11 (.google.cloud.securitycenter.v1.NotificationConfig.StreamingConfig)
    # Field: deletion_notifications_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::NotificationConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/notification_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::NotificationConfig;

    my $msg = Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig->new({
        name => $name,
        description => $description,
        pubsub_topic => $pubsub_topic,
        service_account => $service_account,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/notification_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig

Cloud Security Command Center (Cloud SCC) notification configs.

A notification config is a Cloud SCC resource that contains the configuration
to send notifications for create/update events of findings, assets and etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this notification config. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/notificationConfigs/notify_public_bucket",
"folders/{folder_id}/notificationConfigs/notify_public_bucket",
or "projects/{project_id}/notificationConfigs/notify_public_bucket".

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the notification config (max of 1024 characters).

=item * C<< $msg->pubsub_topic() >> / C<< $msg->pubsub_topic($value) >>

Type: C<String>

The Pub/Sub topic to send notifications to. Its format is
"projects/[project_id]/topics/[topic]".

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Output only. The service account that needs "pubsub.topics.publish"
permission to publish to the Pub/Sub topic.

=item * C<< $msg->streaming_config() >> / C<< $msg->streaming_config($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig::StreamingConfig>)

The config for triggering streaming-based notifications.

=item * C<< $msg->deletion_notifications_enabled() >> / C<< $msg->deletion_notifications_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether the notifications will be sent for deleted
findings. When enabled, the filter defined in the streaming config is still
respected when sending deletion notifications.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::NotificationConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
