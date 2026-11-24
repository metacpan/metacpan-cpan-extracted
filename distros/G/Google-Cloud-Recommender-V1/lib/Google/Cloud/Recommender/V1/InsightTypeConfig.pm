package Google::Cloud::Recommender::V1::InsightTypeConfig;

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
CjVnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjEvaW5zaWdodF90eXBlX2NvbmZpZy5wcm90
bxIbZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYv
c3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIp0GChFJbnNp
Z2h0VHlwZUNvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSfQoeaW5zaWdodF90eXBl
X2dlbmVyYXRpb25fY29uZmlnGAIgASgLMjguZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYx
Lkluc2lnaHRUeXBlR2VuZXJhdGlvbkNvbmZpZ1IbaW5zaWdodFR5cGVHZW5lcmF0aW9uQ29u
ZmlnEhIKBGV0YWcYAyABKAlSBGV0YWcSOwoLdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEicKC3JldmlzaW9uX2lkGAUgASgJQgbg
QQXgQQNSCnJldmlzaW9uSWQSYQoLYW5ub3RhdGlvbnMYBiADKAsyPy5nb29nbGUuY2xvdWQu
cmVjb21tZW5kZXIudjEuSW5zaWdodFR5cGVDb25maWcuQW5ub3RhdGlvbnNFbnRyeVILYW5u
b3RhdGlvbnMSIQoMZGlzcGxheV9uYW1lGAcgASgJUgtkaXNwbGF5TmFtZRo+ChBBbm5vdGF0
aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6
rwLqQasCCixyZWNvbW1lbmRlci5nb29nbGVhcGlzLmNvbS9JbnNpZ2h0VHlwZUNvbmZpZxJK
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc2lnaHRUeXBlcy97
aW5zaWdodF90eXBlfS9jb25maWcSVG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vaW5zaWdodFR5cGVzL3tpbnNpZ2h0X3R5cGV9L2NvbmZpZxJZ
YmlsbGluZ0FjY291bnRzL3tiaWxsaW5nX2FjY291bnR9L2xvY2F0aW9ucy97bG9jYXRpb259
L2luc2lnaHRUeXBlcy97aW5zaWdodF90eXBlfS9jb25maWciTgobSW5zaWdodFR5cGVHZW5l
cmF0aW9uQ29uZmlnEi8KBnBhcmFtcxgBIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RS
BnBhcmFtc0KjAQofY29tLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MUIWSW5zaWdodFR5
cGVDb25maWdQcm90b1ABWkFjbG91ZC5nb29nbGUuY29tL2dvL3JlY29tbWVuZGVyL2FwaXYx
L3JlY29tbWVuZGVycGI7cmVjb21tZW5kZXJwYqICBENSRUOqAhtHb29nbGUuQ2xvdWQuUmVj
b21tZW5kZXIuVjFKqhUKBhIEDgBVAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAJAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgIDAxID
FQApCggKAQgSAxcAOAoJCgIIJRIDFwA4CggKAQgSAxgAWAoJCgIICxIDGABYCggKAQgSAxkA
IgoJCgIIChIDGQAiCggKAQgSAxoANwoJCgIICBIDGgA3CggKAQgSAxsAOAoJCgIIARIDGwA4
CggKAQgSAxwAIgoJCgIIJBIDHAAiCi8KAgQAEgQfAEwBGiMgQ29uZmlndXJhdGlvbiBmb3Ig
YW4gSW5zaWdodFR5cGUuCgoKCgMEAAESAx8IGQoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCAC
JQQKkwEKBAQAAgASAyoCPRqFASBJZGVudGlmaWVyLiBOYW1lIG9mIGluc2lnaHQgdHlwZSBj
b25maWcuCiBFZywKIHByb2plY3RzL1tQUk9KRUNUX05VTUJFUl0vbG9jYXRpb25zL1tMT0NB
VElPTl0vaW5zaWdodFR5cGVzL1tJTlNJR0hUX1RZUEVfSURdL2NvbmZpZwoKDAoFBAACAAUS
AyoCCAoMCgUEAAIAARIDKgkNCgwKBQQAAgADEgMqEBEKDAoFBAACAAgSAyoSPAoPCggEAAIA
CJwIABIDKhM7Cm4KBAQAAgESAy4CQRphIEluc2lnaHRUeXBlR2VuZXJhdGlvbkNvbmZpZyB3
aGljaCBjb25maWd1cmVzIHRoZSBnZW5lcmF0aW9uIG9mCiBpbnNpZ2h0cyBmb3IgdGhpcyBp
bnNpZ2h0IHR5cGUuCgoMCgUEAAIBBhIDLgIdCgwKBQQAAgEBEgMuHjwKDAoFBAACAQMSAy4/
QApgCgQEAAICEgMyAhIaUyBGaW5nZXJwcmludCBvZiB0aGUgSW5zaWdodFR5cGVDb25maWcu
IFByb3ZpZGVzIG9wdGltaXN0aWMgbG9ja2luZyB3aGVuCiB1cGRhdGluZy4KCgwKBQQAAgIF
EgMyAggKDAoFBAACAgESAzIJDQoMCgUEAAICAxIDMhARCjUKBAQAAgMSAzUCLBooIExhc3Qg
dGltZSB3aGVuIHRoZSBjb25maWcgd2FzIHVwZGF0ZWQuCgoMCgUEAAIDBhIDNQIbCgwKBQQA
AgMBEgM1HCcKDAoFBAACAwMSAzUqKwrBAQoEBAACBBIEOgI9BBqyASBPdXRwdXQgb25seS4g
SW1tdXRhYmxlLiBUaGUgcmV2aXNpb24gSUQgb2YgdGhlIGNvbmZpZy4KIEEgbmV3IHJldmlz
aW9uIGlzIGNvbW1pdHRlZCB3aGVuZXZlciB0aGUgY29uZmlnIGlzIGNoYW5nZWQgaW4gYW55
IHdheS4KIFRoZSBmb3JtYXQgaXMgYW4gOC1jaGFyYWN0ZXIgaGV4YWRlY2ltYWwgc3RyaW5n
LgoKDAoFBAACBAUSAzoCCAoMCgUEAAIEARIDOgkUCgwKBQQAAgQDEgM6FxgKDQoFBAACBAgS
BDoZPQMKDwoIBAACBAicCAASAzsEKwoPCggEAAIECJwIARIDPAQtCsgDCgQEAAIFEgNHAiYa
ugMgQWxsb3dzIGNsaWVudHMgdG8gc3RvcmUgc21hbGwgYW1vdW50cyBvZiBhcmJpdHJhcnkg
ZGF0YS4gQW5ub3RhdGlvbnMgbXVzdAogZm9sbG93IHRoZSBLdWJlcm5ldGVzIHN5bnRheC4K
IFRoZSB0b3RhbCBzaXplIG9mIGFsbCBrZXlzIGFuZCB2YWx1ZXMgY29tYmluZWQgaXMgbGlt
aXRlZCB0byAyNTZrLgogS2V5IGNhbiBoYXZlIDIgc2VnbWVudHM6IHByZWZpeCAob3B0aW9u
YWwpIGFuZCBuYW1lIChyZXF1aXJlZCksCiBzZXBhcmF0ZWQgYnkgYSBzbGFzaCAoLykuCiBQ
cmVmaXggbXVzdCBiZSBhIEROUyBzdWJkb21haW4uCiBOYW1lIG11c3QgYmUgNjMgY2hhcmFj
dGVycyBvciBsZXNzLCBiZWdpbiBhbmQgZW5kIHdpdGggYWxwaGFudW1lcmljcywKIHdpdGgg
ZGFzaGVzICgtKSwgdW5kZXJzY29yZXMgKF8pLCBkb3RzICguKSwgYW5kIGFscGhhbnVtZXJp
Y3MgYmV0d2Vlbi4KCgwKBQQAAgUGEgNHAhUKDAoFBAACBQESA0cWIQoMCgUEAAIFAxIDRyQl
CmUKBAQAAgYSA0sCGhpYIEEgdXNlci1zZXR0YWJsZSBmaWVsZCB0byBwcm92aWRlIGEgaHVt
YW4tcmVhZGFibGUgbmFtZSB0byBiZSB1c2VkIGluIHVzZXIKIGludGVyZmFjZXMuCgoMCgUE
AAIGBRIDSwIICgwKBQQAAgYBEgNLCRUKDAoFBAACBgMSA0sYGQqTAQoCBAESBFEAVQEahgEg
QSBjb25maWd1cmF0aW9uIHRvIGN1c3RvbWl6ZSB0aGUgZ2VuZXJhdGlvbiBvZiBpbnNpZ2h0
cy4KIEVnLCBjdXN0b21pemluZyB0aGUgbG9va2JhY2sgcGVyaW9kIGNvbnNpZGVyZWQgd2hl
biBnZW5lcmF0aW5nIGEKIGluc2lnaHQuCgoKCgMEAQESA1EIIwp9CgQEAQIAEgNUAiQacCBQ
YXJhbWV0ZXJzIGZvciB0aGlzIEluc2lnaHRUeXBlR2VuZXJhdGlvbkNvbmZpZy4gVGhlc2Ug
Y29uZmlncyBjYW4gYmUgdXNlZAogYnkgb3IgYXJlIGFwcGxpZWQgdG8gYWxsIHN1YnR5cGVz
LgoKDAoFBAECAAYSA1QCGAoMCgUEAQIAARIDVBkfCgwKBQQBAgADEgNUIiNiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig ===
    # Fields for InsightTypeConfig
    # Field: name Type: 9 ()
    # Field: insight_type_generation_config Type: 11 (.google.cloud.recommender.v1.InsightTypeGenerationConfig)
    # Field: etag Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: revision_id Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.recommender.v1.InsightTypeConfig.AnnotationsEntry)
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeGenerationConfig ===
    # Fields for InsightTypeGenerationConfig
    # Field: params Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1::InsightTypeConfig - Compiled Protocol Buffers messages for google/cloud/recommender/v1/insight_type_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1::InsightTypeConfig;

    my $msg = Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig->new({
        name => $name,
        insight_type_generation_config => $insight_type_generation_config,
        etag => $etag,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1/insight_type_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig

Configuration for an InsightType.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of insight type config.
Eg,
projects/[PROJECT_NUMBER]/locations/[LOCATION]/insightTypes/[INSIGHT_TYPE_ID]/config

=item * C<< $msg->insight_type_generation_config() >> / C<< $msg->insight_type_generation_config($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeGenerationConfig>)

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

Type: C<Message> (L<Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig::AnnotationsEntry>)

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

=head2 Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeGenerationConfig

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1::InsightTypeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
