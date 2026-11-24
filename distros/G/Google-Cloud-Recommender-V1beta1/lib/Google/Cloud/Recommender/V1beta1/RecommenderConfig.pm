package Google::Cloud::Recommender::V1beta1::RecommenderConfig;

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
Cjlnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjFiZXRhMS9yZWNvbW1lbmRlcl9jb25maWcu
cHJvdG8SIGdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUv
cHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IsUFChFSZWNvbW1lbmRlckNvbmZpZxISCgRuYW1lGAEgASgJUgRuYW1lEoEBCh1yZWNvbW1l
bmRlcl9nZW5lcmF0aW9uX2NvbmZpZxgCIAEoCzI9Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRl
ci52MWJldGExLlJlY29tbWVuZGVyR2VuZXJhdGlvbkNvbmZpZ1IbcmVjb21tZW5kZXJHZW5l
cmF0aW9uQ29uZmlnEhIKBGV0YWcYAyABKAlSBGV0YWcSOwoLdXBkYXRlX3RpbWUYBCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEicKC3JldmlzaW9uX2lk
GAUgASgJQgbgQQXgQQNSCnJldmlzaW9uSWQSZgoLYW5ub3RhdGlvbnMYBiADKAsyRC5nb29n
bGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMS5SZWNvbW1lbmRlckNvbmZpZy5Bbm5vdGF0
aW9uc0VudHJ5Ugthbm5vdGF0aW9ucxIhCgxkaXNwbGF5X25hbWUYByABKAlSC2Rpc3BsYXlO
YW1lGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ATrSAepBzgEKLHJlY29tbWVuZGVyLmdvb2dsZWFwaXMuY29tL1JlY29t
bWVuZGVyQ29uZmlnEklwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cmVjb21tZW5kZXJzL3tyZWNvbW1lbmRlcn0vY29uZmlnElNvcmdhbml6YXRpb25zL3tvcmdh
bml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVycy97cmVjb21tZW5k
ZXJ9L2NvbmZpZyJOChtSZWNvbW1lbmRlckdlbmVyYXRpb25Db25maWcSLwoGcGFyYW1zGAEg
ASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIGcGFyYW1zQrIBCiRjb20uZ29vZ2xlLmNs
b3VkLnJlY29tbWVuZGVyLnYxYmV0YTFCFlJlY29tbWVuZGVyQ29uZmlnUHJvdG9QAVpGY2xv
dWQuZ29vZ2xlLmNvbS9nby9yZWNvbW1lbmRlci9hcGl2MWJldGExL3JlY29tbWVuZGVycGI7
cmVjb21tZW5kZXJwYqICBENSRUOqAiBHb29nbGUuQ2xvdWQuUmVjb21tZW5kZXIuVjFCZXRh
MUqPFQoGEgQOAFQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAApCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAmCgkKAgMDEgMVACkKCAoBCBID
FwA9CgkKAgglEgMXAD0KCAoBCBIDGABdCgkKAggLEgMYAF0KCAoBCBIDGQAiCgkKAggKEgMZ
ACIKCAoBCBIDGgA3CgkKAggIEgMaADcKCAoBCBIDGwA9CgkKAggBEgMbAD0KCAoBCBIDHAAi
CgkKAggkEgMcACIKLgoCBAASBB8ASwEaIiBDb25maWd1cmF0aW9uIGZvciBhIFJlY29tbWVu
ZGVyLgoKCgoDBAABEgMfCBkKCwoDBAAHEgQgAiQECg0KBQQAB50IEgQgAiQECoQBCgQEAAIA
EgMpAhIadyBOYW1lIG9mIHJlY29tbWVuZGVyIGNvbmZpZy4KIEVnLAogcHJvamVjdHMvW1BS
T0pFQ1RfTlVNQkVSXS9sb2NhdGlvbnMvW0xPQ0FUSU9OXS9yZWNvbW1lbmRlcnMvW1JFQ09N
TUVOREVSX0lEXS9jb25maWcKCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJDQoMCgUEAAIA
AxIDKRARCnQKBAQAAgESAy0CQBpnIFJlY29tbWVuZGVyR2VuZXJhdGlvbkNvbmZpZyB3aGlj
aCBjb25maWd1cmVzIHRoZSBHZW5lcmF0aW9uIG9mCiByZWNvbW1lbmRhdGlvbnMgZm9yIHRo
aXMgcmVjb21tZW5kZXIuCgoMCgUEAAIBBhIDLQIdCgwKBQQAAgEBEgMtHjsKDAoFBAACAQMS
Ay0+PwpgCgQEAAICEgMxAhIaUyBGaW5nZXJwcmludCBvZiB0aGUgUmVjb21tZW5kZXJDb25m
aWcuIFByb3ZpZGVzIG9wdGltaXN0aWMgbG9ja2luZyB3aGVuCiB1cGRhdGluZy4KCgwKBQQA
AgIFEgMxAggKDAoFBAACAgESAzEJDQoMCgUEAAICAxIDMRARCjUKBAQAAgMSAzQCLBooIExh
c3QgdGltZSB3aGVuIHRoZSBjb25maWcgd2FzIHVwZGF0ZWQuCgoMCgUEAAIDBhIDNAIbCgwK
BQQAAgMBEgM0HCcKDAoFBAACAwMSAzQqKwrBAQoEBAACBBIEOQI8BBqyASBPdXRwdXQgb25s
eS4gSW1tdXRhYmxlLiBUaGUgcmV2aXNpb24gSUQgb2YgdGhlIGNvbmZpZy4KIEEgbmV3IHJl
dmlzaW9uIGlzIGNvbW1pdHRlZCB3aGVuZXZlciB0aGUgY29uZmlnIGlzIGNoYW5nZWQgaW4g
YW55IHdheS4KIFRoZSBmb3JtYXQgaXMgYW4gOC1jaGFyYWN0ZXIgaGV4YWRlY2ltYWwgc3Ry
aW5nLgoKDAoFBAACBAUSAzkCCAoMCgUEAAIEARIDOQkUCgwKBQQAAgQDEgM5FxgKDQoFBAAC
BAgSBDkZPAMKDwoIBAACBAicCAASAzoEKwoPCggEAAIECJwIARIDOwQtCsgDCgQEAAIFEgNG
AiYaugMgQWxsb3dzIGNsaWVudHMgdG8gc3RvcmUgc21hbGwgYW1vdW50cyBvZiBhcmJpdHJh
cnkgZGF0YS4gQW5ub3RhdGlvbnMgbXVzdAogZm9sbG93IHRoZSBLdWJlcm5ldGVzIHN5bnRh
eC4KIFRoZSB0b3RhbCBzaXplIG9mIGFsbCBrZXlzIGFuZCB2YWx1ZXMgY29tYmluZWQgaXMg
bGltaXRlZCB0byAyNTZrLgogS2V5IGNhbiBoYXZlIDIgc2VnbWVudHM6IHByZWZpeCAob3B0
aW9uYWwpIGFuZCBuYW1lIChyZXF1aXJlZCksCiBzZXBhcmF0ZWQgYnkgYSBzbGFzaCAoLyku
CiBQcmVmaXggbXVzdCBiZSBhIEROUyBzdWJkb21haW4uCiBOYW1lIG11c3QgYmUgNjMgY2hh
cmFjdGVycyBvciBsZXNzLCBiZWdpbiBhbmQgZW5kIHdpdGggYWxwaGFudW1lcmljcywKIHdp
dGggZGFzaGVzICgtKSwgdW5kZXJzY29yZXMgKF8pLCBkb3RzICguKSwgYW5kIGFscGhhbnVt
ZXJpY3MgYmV0d2Vlbi4KCgwKBQQAAgUGEgNGAhUKDAoFBAACBQESA0YWIQoMCgUEAAIFAxID
RiQlCmUKBAQAAgYSA0oCGhpYIEEgdXNlci1zZXR0YWJsZSBmaWVsZCB0byBwcm92aWRlIGEg
aHVtYW4tcmVhZGFibGUgbmFtZSB0byBiZSB1c2VkIGluIHVzZXIKIGludGVyZmFjZXMuCgoM
CgUEAAIGBRIDSgIICgwKBQQAAgYBEgNKCRUKDAoFBAACBgMSA0oYGQqhAQoCBAESBFAAVAEa
lAEgQSBDb25maWd1cmF0aW9uIHRvIGN1c3RvbWl6ZSB0aGUgZ2VuZXJhdGlvbiBvZiByZWNv
bW1lbmRhdGlvbnMuCiBFZywgY3VzdG9taXppbmcgdGhlIGxvb2tiYWNrIHBlcmlvZCBjb25z
aWRlcmVkIHdoZW4gZ2VuZXJhdGluZyBhCiByZWNvbW1lbmRhdGlvbi4KCgoKAwQBARIDUAgj
Cn0KBAQBAgASA1MCJBpwIFBhcmFtZXRlcnMgZm9yIHRoaXMgUmVjb21tZW5kZXJHZW5lcmF0
aW9uQ29uZmlnLiBUaGVzZSBjb25maWdzIGNhbiBiZSB1c2VkCiBieSBvciBhcmUgYXBwbGll
ZCB0byBhbGwgc3VidHlwZXMuCgoMCgUEAQIABhIDUwIYCgwKBQQBAgABEgNTGR8KDAoFBAEC
AAMSA1MiI2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig ===
    # Fields for RecommenderConfig
    # Field: name Type: 9 ()
    # Field: recommender_generation_config Type: 11 (.google.cloud.recommender.v1beta1.RecommenderGenerationConfig)
    # Field: etag Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: revision_id Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.recommender.v1beta1.RecommenderConfig.AnnotationsEntry)
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderGenerationConfig ===
    # Fields for RecommenderGenerationConfig
    # Field: params Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1beta1::RecommenderConfig - Compiled Protocol Buffers messages for google/cloud/recommender/v1beta1/recommender_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1beta1::RecommenderConfig;

    my $msg = Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig->new({
        name => $name,
        recommender_generation_config => $recommender_generation_config,
        etag => $etag,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1beta1/recommender_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig

Configuration for a Recommender.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of recommender config.
Eg,
projects/[PROJECT_NUMBER]/locations/[LOCATION]/recommenders/[RECOMMENDER_ID]/config

=item * C<< $msg->recommender_generation_config() >> / C<< $msg->recommender_generation_config($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderGenerationConfig>)

RecommenderGenerationConfig which configures the Generation of
recommendations for this recommender.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Fingerprint of the RecommenderConfig. Provides optimistic locking when
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

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig::AnnotationsEntry>)

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

=head2 Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderGenerationConfig

A Configuration to customize the generation of recommendations.
Eg, customizing the lookback period considered when generating a
recommendation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Parameters for this RecommenderGenerationConfig. These configs can be used
by or are applied to all subtypes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1beta1::RecommenderConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
