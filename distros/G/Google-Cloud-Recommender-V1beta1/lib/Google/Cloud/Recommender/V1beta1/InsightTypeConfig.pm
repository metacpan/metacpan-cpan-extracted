package Google::Cloud::Recommender::V1beta1::InsightTypeConfig;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjFiZXRhMS9pbnNpZ2h0X3R5cGVfY29uZmln
LnByb3RvEiBnb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxocZ29vZ2xl
L3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
byLIBQoRSW5zaWdodFR5cGVDb25maWcSEgoEbmFtZRgBIAEoCVIEbmFtZRKCAQoeaW5zaWdo
dF90eXBlX2dlbmVyYXRpb25fY29uZmlnGAIgASgLMj0uZ29vZ2xlLmNsb3VkLnJlY29tbWVu
ZGVyLnYxYmV0YTEuSW5zaWdodFR5cGVHZW5lcmF0aW9uQ29uZmlnUhtpbnNpZ2h0VHlwZUdl
bmVyYXRpb25Db25maWcSEgoEZXRhZxgDIAEoCVIEZXRhZxI7Cgt1cGRhdGVfdGltZRgEIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSJwoLcmV2aXNpb25f
aWQYBSABKAlCBuBBBeBBA1IKcmV2aXNpb25JZBJmCgthbm5vdGF0aW9ucxgGIAMoCzJELmdv
b2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLkluc2lnaHRUeXBlQ29uZmlnLkFubm90
YXRpb25zRW50cnlSC2Fubm90YXRpb25zEiEKDGRpc3BsYXlfbmFtZRgHIAEoCVILZGlzcGxh
eU5hbWUaPgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBOtQB6kHQAQoscmVjb21tZW5kZXIuZ29vZ2xlYXBpcy5jb20vSW5z
aWdodFR5cGVDb25maWcSSnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9pbnNpZ2h0VHlwZXMve2luc2lnaHRfdHlwZX0vY29uZmlnElRvcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2luc2lnaHRUeXBlcy97aW5zaWdo
dF90eXBlfS9jb25maWciTgobSW5zaWdodFR5cGVHZW5lcmF0aW9uQ29uZmlnEi8KBnBhcmFt
cxgBIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSBnBhcmFtc0KyAQokY29tLmdvb2ds
ZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExQhZJbnNpZ2h0VHlwZUNvbmZpZ1Byb3RvUAFa
RmNsb3VkLmdvb2dsZS5jb20vZ28vcmVjb21tZW5kZXIvYXBpdjFiZXRhMS9yZWNvbW1lbmRl
cnBiO3JlY29tbWVuZGVycGKiAgRDUkVDqgIgR29vZ2xlLkNsb3VkLlJlY29tbWVuZGVyLlYx
QmV0YTFK/hQKBhIEDgBUAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAAKQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgIDAxIDFQApCggK
AQgSAxcAPQoJCgIIJRIDFwA9CggKAQgSAxgAXQoJCgIICxIDGABdCggKAQgSAxkAIgoJCgII
ChIDGQAiCggKAQgSAxoANwoJCgIICBIDGgA3CggKAQgSAxsAPQoJCgIIARIDGwA9CggKAQgS
AxwAIgoJCgIIJBIDHAAiCi8KAgQAEgQfAEsBGiMgQ29uZmlndXJhdGlvbiBmb3IgYW4gSW5z
aWdodFR5cGUuCgoKCgMEAAESAx8IGQoLCgMEAAcSBCACJAQKDQoFBAAHnQgSBCACJAQKhgEK
BAQAAgASAykCEhp5IE5hbWUgb2YgaW5zaWdodCB0eXBlIGNvbmZpZy4KIEVnLAogcHJvamVj
dHMvW1BST0pFQ1RfTlVNQkVSXS9sb2NhdGlvbnMvW0xPQ0FUSU9OXS9pbnNpZ2h0VHlwZXMv
W0lOU0lHSFRfVFlQRV9JRF0vY29uZmlnCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCQ0K
DAoFBAACAAMSAykQEQpuCgQEAAIBEgMtAkEaYSBJbnNpZ2h0VHlwZUdlbmVyYXRpb25Db25m
aWcgd2hpY2ggY29uZmlndXJlcyB0aGUgZ2VuZXJhdGlvbiBvZgogaW5zaWdodHMgZm9yIHRo
aXMgaW5zaWdodCB0eXBlLgoKDAoFBAACAQYSAy0CHQoMCgUEAAIBARIDLR48CgwKBQQAAgED
EgMtP0AKYAoEBAACAhIDMQISGlMgRmluZ2VycHJpbnQgb2YgdGhlIEluc2lnaHRUeXBlQ29u
ZmlnLiBQcm92aWRlcyBvcHRpbWlzdGljIGxvY2tpbmcgd2hlbgogdXBkYXRpbmcuCgoMCgUE
AAICBRIDMQIICgwKBQQAAgIBEgMxCQ0KDAoFBAACAgMSAzEQEQo1CgQEAAIDEgM0AiwaKCBM
YXN0IHRpbWUgd2hlbiB0aGUgY29uZmlnIHdhcyB1cGRhdGVkLgoKDAoFBAACAwYSAzQCGwoM
CgUEAAIDARIDNBwnCgwKBQQAAgMDEgM0KisKwQEKBAQAAgQSBDkCPAQasgEgT3V0cHV0IG9u
bHkuIEltbXV0YWJsZS4gVGhlIHJldmlzaW9uIElEIG9mIHRoZSBjb25maWcuCiBBIG5ldyBy
ZXZpc2lvbiBpcyBjb21taXR0ZWQgd2hlbmV2ZXIgdGhlIGNvbmZpZyBpcyBjaGFuZ2VkIGlu
IGFueSB3YXkuCiBUaGUgZm9ybWF0IGlzIGFuIDgtY2hhcmFjdGVyIGhleGFkZWNpbWFsIHN0
cmluZy4KCgwKBQQAAgQFEgM5AggKDAoFBAACBAESAzkJFAoMCgUEAAIEAxIDORcYCg0KBQQA
AgQIEgQ5GTwDCg8KCAQAAgQInAgAEgM6BCsKDwoIBAACBAicCAESAzsELQrIAwoEBAACBRID
RgImGroDIEFsbG93cyBjbGllbnRzIHRvIHN0b3JlIHNtYWxsIGFtb3VudHMgb2YgYXJiaXRy
YXJ5IGRhdGEuIEFubm90YXRpb25zIG11c3QKIGZvbGxvdyB0aGUgS3ViZXJuZXRlcyBzeW50
YXguCiBUaGUgdG90YWwgc2l6ZSBvZiBhbGwga2V5cyBhbmQgdmFsdWVzIGNvbWJpbmVkIGlz
IGxpbWl0ZWQgdG8gMjU2ay4KIEtleSBjYW4gaGF2ZSAyIHNlZ21lbnRzOiBwcmVmaXggKG9w
dGlvbmFsKSBhbmQgbmFtZSAocmVxdWlyZWQpLAogc2VwYXJhdGVkIGJ5IGEgc2xhc2ggKC8p
LgogUHJlZml4IG11c3QgYmUgYSBETlMgc3ViZG9tYWluLgogTmFtZSBtdXN0IGJlIDYzIGNo
YXJhY3RlcnMgb3IgbGVzcywgYmVnaW4gYW5kIGVuZCB3aXRoIGFscGhhbnVtZXJpY3MsCiB3
aXRoIGRhc2hlcyAoLSksIHVuZGVyc2NvcmVzIChfKSwgZG90cyAoLiksIGFuZCBhbHBoYW51
bWVyaWNzIGJldHdlZW4uCgoMCgUEAAIFBhIDRgIVCgwKBQQAAgUBEgNGFiEKDAoFBAACBQMS
A0YkJQplCgQEAAIGEgNKAhoaWCBBIHVzZXItc2V0dGFibGUgZmllbGQgdG8gcHJvdmlkZSBh
IGh1bWFuLXJlYWRhYmxlIG5hbWUgdG8gYmUgdXNlZCBpbiB1c2VyCiBpbnRlcmZhY2VzLgoK
DAoFBAACBgUSA0oCCAoMCgUEAAIGARIDSgkVCgwKBQQAAgYDEgNKGBkKkwEKAgQBEgRQAFQB
GoYBIEEgY29uZmlndXJhdGlvbiB0byBjdXN0b21pemUgdGhlIGdlbmVyYXRpb24gb2YgaW5z
aWdodHMuCiBFZywgY3VzdG9taXppbmcgdGhlIGxvb2tiYWNrIHBlcmlvZCBjb25zaWRlcmVk
IHdoZW4gZ2VuZXJhdGluZyBhCiBpbnNpZ2h0LgoKCgoDBAEBEgNQCCMKfQoEBAECABIDUwIk
GnAgUGFyYW1ldGVycyBmb3IgdGhpcyBJbnNpZ2h0VHlwZUdlbmVyYXRpb25Db25maWcuIFRo
ZXNlIGNvbmZpZ3MgY2FuIGJlIHVzZWQKIGJ5IG9yIGFyZSBhcHBsaWVkIHRvIGFsbCBzdWJ0
eXBlcy4KCgwKBQQBAgAGEgNTAhgKDAoFBAECAAESA1MZHwoMCgUEAQIAAxIDUyIjYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeConfig ===
    # Fields for InsightTypeConfig
    # Field: name Type: 9 ()
    # Field: insight_type_generation_config Type: 11 (.google.cloud.recommender.v1beta1.InsightTypeGenerationConfig)
    # Field: etag Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: revision_id Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.recommender.v1beta1.InsightTypeConfig.AnnotationsEntry)
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeGenerationConfig ===
    # Fields for InsightTypeGenerationConfig
    # Field: params Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1beta1::InsightTypeConfig - Compiled Protocol Buffers messages for google/cloud/recommender/v1beta1/insight_type_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1beta1::InsightTypeConfig;

    my $msg = Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeConfig->new({
        name => $name,
        insight_type_generation_config => $insight_type_generation_config,
        etag => $etag,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1beta1/insight_type_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeConfig

Configuration for an InsightType.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of insight type config.
Eg,
projects/[PROJECT_NUMBER]/locations/[LOCATION]/insightTypes/[INSIGHT_TYPE_ID]/config

=item * C<< $msg->insight_type_generation_config() >> / C<< $msg->insight_type_generation_config($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeGenerationConfig>)

InsightTypeGenerationConfig which configures the generation of
insights for this insight type.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Fingerprint of the InsightTypeConfig. Provides optimistic locking when
updating.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Last time when the config was updated.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Output only. Immutable. The revision ID of the config.
A new revision is committed whenever the config is changed in any way.
The format is an 8-character hexadecimal string.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeConfig::AnnotationsEntry>)

Allows clients to store small amounts of arbitrary data. Annotations must
follow the Kubernetes syntax.
The total size of all keys and values combined is limited to 256k.
Key can have 2 segments: prefix (optional) and name (required),
separated by a slash (/).
Prefix must be a DNS subdomain.
Name must be 63 characters or less, begin and end with alphanumerics,
with dashes (-), underscores (_), dots (.), and alphanumerics between.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A user-settable field to provide a human-readable name to be used in user
interfaces.

=back

=head2 Google::Cloud::Recommender::V1beta1::InsightTypeConfig::InsightTypeGenerationConfig

A configuration to customize the generation of insights.
Eg, customizing the lookback period considered when generating a
insight.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Parameters for this InsightTypeGenerationConfig. These configs can be used
by or are applied to all subtypes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1beta1::InsightTypeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
