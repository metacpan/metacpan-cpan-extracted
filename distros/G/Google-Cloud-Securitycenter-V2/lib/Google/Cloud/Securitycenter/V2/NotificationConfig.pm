package Google::Cloud::Securitycenter::V2::NotificationConfig;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvbm90aWZpY2F0aW9uX2NvbmZpZy5w
cm90bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIt8GChJOb3RpZmljYXRpb25Db25maWcSFwoEbmFtZRgB
IAEoCUID4EEIUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhJDCgxw
dWJzdWJfdG9waWMYAyABKAlCIPpBHQobcHVic3ViLmdvb2dsZWFwaXMuY29tL1RvcGljUgtw
dWJzdWJUb3BpYxIsCg9zZXJ2aWNlX2FjY291bnQYBCABKAlCA+BBA1IOc2VydmljZUFjY291
bnQSbwoQc3RyZWFtaW5nX2NvbmZpZxgFIAEoCzJCLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52Mi5Ob3RpZmljYXRpb25Db25maWcuU3RyZWFtaW5nQ29uZmlnSABSD3N0cmVhbWlu
Z0NvbmZpZxJACgt1cGRhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKdXBkYXRlVGltZRJJCh5kZWxldGlvbl9ub3RpZmljYXRpb25zX2VuYWJsZWQY
CSABKAhCA+BBAVIcZGVsZXRpb25Ob3RpZmljYXRpb25zRW5hYmxlZBopCg9TdHJlYW1pbmdD
b25maWcSFgoGZmlsdGVyGAEgASgJUgZmaWx0ZXI64ALqQdwCCjBzZWN1cml0eWNlbnRlci5n
b29nbGVhcGlzLmNvbS9Ob3RpZmljYXRpb25Db25maWcSW29yZ2FuaXphdGlvbnMve29yZ2Fu
aXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbm90aWZpY2F0aW9uQ29uZmlncy97bm90
aWZpY2F0aW9uX2NvbmZpZ30ST2ZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vbm90aWZpY2F0aW9uQ29uZmlncy97bm90aWZpY2F0aW9uX2NvbmZpZ30SUXByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9ub3RpZmljYXRpb25Db25maWdzL3tu
b3RpZmljYXRpb25fY29uZmlnfSoTbm90aWZpY2F0aW9uQ29uZmlnczISbm90aWZpY2F0aW9u
Q29uZmlnQg8KDW5vdGlmeV9jb25maWdCtAIKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjJCF05vdGlmaWNhdGlvbkNvbmZpZ1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20v
Z28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRl
cnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNl
Y3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYy6kFA
ChtwdWJzdWIuZ29vZ2xlYXBpcy5jb20vVG9waWMSIXByb2plY3RzL3twcm9qZWN0fS90b3Bp
Y3Mve3RvcGljfUrYHQoGEgQOAHMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYA
OwoJCgIIJRIDFgA7CggKAQgSAxcAYQoJCgIICxIDFwBhCggKAQgSAxgAIgoJCgIIChIDGAAi
CggKAQgSAxkAOAoJCgIICBIDGQA4CggKAQgSAxoAOwoJCgIIARIDGgA7CggKAQgSAxsAOwoJ
CgIIKRIDGwA7CggKAQgSAxwAOgoJCgIILRIDHAA6CgkKAQgSBB0AIAIKDAoECJ0IABIEHQAg
AgrrAQoCBAASBCYAcwEa3gEgQ2xvdWQgU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIgKENsb3Vk
IFNDQykgbm90aWZpY2F0aW9uIGNvbmZpZ3MuCgogQSBub3RpZmljYXRpb24gY29uZmlnIGlz
IGEgQ2xvdWQgU0NDIHJlc291cmNlIHRoYXQgY29udGFpbnMgdGhlIGNvbmZpZ3VyYXRpb24K
IHRvIHNlbmQgbm90aWZpY2F0aW9ucyBmb3IgY3JlYXRlL3VwZGF0ZSBldmVudHMgb2YgZmlu
ZGluZ3MsIGFzc2V0cyBhbmQgZXRjLgoKCgoDBAABEgMmCBoKCwoDBAAHEgQnAi4ECg0KBQQA
B50IEgQnAi4ECm8KBAQAAwASBDICSQMaYSBUaGUgY29uZmlnIGZvciBzdHJlYW1pbmctYmFz
ZWQgbm90aWZpY2F0aW9ucywgd2hpY2ggc2VuZCBlYWNoIGV2ZW50IGFzIHNvb24KIGFzIGl0
IGlzIGRldGVjdGVkLgoKDAoFBAADAAESAzIKGQqxBgoGBAADAAIAEgNIBBYaoQYgRXhwcmVz
c2lvbiB0aGF0IGRlZmluZXMgdGhlIGZpbHRlciB0byBhcHBseSBhY3Jvc3MgY3JlYXRlL3Vw
ZGF0ZSBldmVudHMKIG9mIGFzc2V0cyBvciBmaW5kaW5ncyBhcyBzcGVjaWZpZWQgYnkgdGhl
IGV2ZW50IHR5cGUuIFRoZSBleHByZXNzaW9uIGlzIGEKIGxpc3Qgb2YgemVybyBvciBtb3Jl
IHJlc3RyaWN0aW9ucyBjb21iaW5lZCB2aWEgbG9naWNhbCBvcGVyYXRvcnMgYEFORGAKIGFu
ZCBgT1JgLiBQYXJlbnRoZXNlcyBhcmUgc3VwcG9ydGVkLCBhbmQgYE9SYCBoYXMgaGlnaGVy
IHByZWNlZGVuY2UgdGhhbgogYEFORGAuCgogUmVzdHJpY3Rpb25zIGhhdmUgdGhlIGZvcm0g
YDxmaWVsZD4gPG9wZXJhdG9yPiA8dmFsdWU+YCBhbmQgbWF5IGhhdmUgYQogYC1gIGNoYXJh
Y3RlciBpbiBmcm9udCBvZiB0aGVtIHRvIGluZGljYXRlIG5lZ2F0aW9uLiBUaGUgZmllbGRz
IG1hcCB0bwogdGhvc2UgZGVmaW5lZCBpbiB0aGUgY29ycmVzcG9uZGluZyByZXNvdXJjZS4K
CiBUaGUgc3VwcG9ydGVkIG9wZXJhdG9ycyBhcmU6CgogKiBgPWAgZm9yIGFsbCB2YWx1ZSB0
eXBlcy4KICogYD5gLCBgPGAsIGA+PWAsIGA8PWAgZm9yIGludGVnZXIgdmFsdWVzLgogKiBg
OmAsIG1lYW5pbmcgc3Vic3RyaW5nIG1hdGNoaW5nLCBmb3Igc3RyaW5ncy4KCiBUaGUgc3Vw
cG9ydGVkIHZhbHVlIHR5cGVzIGFyZToKCiAqIHN0cmluZyBsaXRlcmFscyBpbiBxdW90ZXMu
CiAqIGludGVnZXIgbGl0ZXJhbHMgd2l0aG91dCBxdW90ZXMuCiAqIGJvb2xlYW4gbGl0ZXJh
bHMgYHRydWVgIGFuZCBgZmFsc2VgIHdpdGhvdXQgcXVvdGVzLgoKDgoHBAADAAIABRIDSAQK
Cg4KBwQAAwACAAESA0gLEQoOCgcEAAMAAgADEgNIFBUK7AMKBAQAAgASA1QCPRreAyBJZGVu
dGlmaWVyLiBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGlzIG5vdGlmaWNhdGlv
biBjb25maWcuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9y
ZXNvdXJjZV9uYW1lcyNyZWxhdGl2ZV9yZXNvdXJjZV9uYW1lCiBUaGUgZm9sbG93aW5nIGxp
c3Qgc2hvd3Mgc29tZSBleGFtcGxlczoKICsKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRp
b25faWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L25vdGlmaWNhdGlvbkNvbmZpZ3Mvbm90
aWZ5X3B1YmxpY19idWNrZXRgCiArCiBgZm9sZGVycy97Zm9sZGVyX2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9uX2lkfS9ub3RpZmljYXRpb25Db25maWdzL25vdGlmeV9wdWJsaWNfYnVja2V0
YAogKwogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9u
b3RpZmljYXRpb25Db25maWdzL25vdGlmeV9wdWJsaWNfYnVja2V0YAoKDAoFBAACAAUSA1QC
CAoMCgUEAAIAARIDVAkNCgwKBQQAAgADEgNUEBEKDAoFBAACAAgSA1QSPAoPCggEAAIACJwI
ABIDVBM7ClMKBAQAAgESA1cCGRpGIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgbm90aWZpY2F0
aW9uIGNvbmZpZyAobWF4IG9mIDEwMjQgY2hhcmFjdGVycykuCgoMCgUEAAIBBRIDVwIICgwK
BQQAAgEBEgNXCRQKDAoFBAACAQMSA1cXGApyCgQEAAICEgRbAl0EGmQgVGhlIFB1Yi9TdWIg
dG9waWMgdG8gc2VuZCBub3RpZmljYXRpb25zIHRvLiBJdHMgZm9ybWF0IGlzCiAicHJvamVj
dHMvW3Byb2plY3RfaWRdL3RvcGljcy9bdG9waWNdIi4KCgwKBQQAAgIFEgNbAggKDAoFBAAC
AgESA1sJFQoMCgUEAAICAxIDWxgZCg0KBQQAAgIIEgRbGl0DCg4KBwQAAgIInwgSA1wETQp/
CgQEAAIDEgNhAkkaciBPdXRwdXQgb25seS4gVGhlIHNlcnZpY2UgYWNjb3VudCB0aGF0IG5l
ZWRzICJwdWJzdWIudG9waWNzLnB1Ymxpc2giCiBwZXJtaXNzaW9uIHRvIHB1Ymxpc2ggdG8g
dGhlIFB1Yi9TdWIgdG9waWMuCgoMCgUEAAIDBRIDYQIICgwKBQQAAgMBEgNhCRgKDAoFBAAC
AwMSA2EbHAoMCgUEAAIDCBIDYR1ICg8KCAQAAgMInAgAEgNhHkcKOAoEBAAIABIEZAJnAxoq
IFRoZSBjb25maWcgZm9yIHRyaWdnZXJpbmcgbm90aWZpY2F0aW9ucy4KCgwKBQQACAABEgNk
CBUKRwoEBAACBBIDZgQpGjogVGhlIGNvbmZpZyBmb3IgdHJpZ2dlcmluZyBzdHJlYW1pbmct
YmFzZWQgbm90aWZpY2F0aW9ucy4KCgwKBQQAAgQGEgNmBBMKDAoFBAACBAESA2YUJAoMCgUE
AAIEAxIDZicoCl0KBAQAAgUSBGsCbDIaTyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCBv
ZiB3aGVuIHRoZSBub3RpZmljYXRpb24gY29uZmlnIHdhcyBsYXN0CiB1cGRhdGVkLgoKDAoF
BAACBQYSA2sCGwoMCgUEAAIFARIDaxwnCgwKBQQAAgUDEgNrKisKDAoFBAACBQgSA2wGMQoP
CggEAAIFCJwIABIDbAcwCtQBCgQEAAIGEgRxAnIvGsUBIE9wdGlvbmFsLiBJbmRpY2F0ZXMg
d2hldGhlciB0aGUgbm90aWZpY2F0aW9ucyB3aWxsIGJlIHNlbnQgZm9yIGRlbGV0ZWQKIGZp
bmRpbmdzLiBXaGVuIGVuYWJsZWQsIHRoZSBmaWx0ZXIgZGVmaW5lZCBpbiB0aGUgc3RyZWFt
aW5nIGNvbmZpZyBpcyBzdGlsbAogcmVzcGVjdGVkIHdoZW4gc2VuZGluZyBkZWxldGlvbiBu
b3RpZmljYXRpb25zLgoKDAoFBAACBgUSA3ECBgoMCgUEAAIGARIDcQclCgwKBQQAAgYDEgNx
KCkKDAoFBAACBggSA3IGLgoPCggEAAIGCJwIABIDcgctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig ===
    # Fields for NotificationConfig
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: pubsub_topic Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: streaming_config Type: 11 (.google.cloud.securitycenter.v2.NotificationConfig.StreamingConfig)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: deletion_notifications_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::NotificationConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/notification_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::NotificationConfig;

    my $msg = Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig->new({
        name => $name,
        description => $description,
        pubsub_topic => $pubsub_topic,
        service_account => $service_account,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/notification_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig

Cloud Security Command Center (Cloud SCC) notification configs.

A notification config is a Cloud SCC resource that contains the configuration
to send notifications for create/update events of findings, assets and etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The relative resource name of this notification config. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
The following list shows some examples:
+
`organizations/{organization_id}/locations/{location_id}/notificationConfigs/notify_public_bucket`
+
`folders/{folder_id}/locations/{location_id}/notificationConfigs/notify_public_bucket`
+
`projects/{project_id}/locations/{location_id}/notificationConfigs/notify_public_bucket`

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::NotificationConfig::NotificationConfig::StreamingConfig>)

The config for triggering streaming-based notifications.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of when the notification config was last
updated.

=item * C<< $msg->deletion_notifications_enabled() >> / C<< $msg->deletion_notifications_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether the notifications will be sent for deleted
findings. When enabled, the filter defined in the streaming config is still
respected when sending deletion notifications.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::NotificationConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
