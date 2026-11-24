package Google::Cloud::Recommender::V1::RecommenderConfig;

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
CjRnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjEvcmVjb21tZW5kZXJfY29uZmlnLnByb3Rv
Ehtnb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9z
dHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8imQYKEVJlY29t
bWVuZGVyQ29uZmlnEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJ8Ch1yZWNvbW1lbmRlcl9n
ZW5lcmF0aW9uX2NvbmZpZxgCIAEoCzI4Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MS5S
ZWNvbW1lbmRlckdlbmVyYXRpb25Db25maWdSG3JlY29tbWVuZGVyR2VuZXJhdGlvbkNvbmZp
ZxISCgRldGFnGAMgASgJUgRldGFnEjsKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZRInCgtyZXZpc2lvbl9pZBgFIAEoCUIG4EEF
4EEDUgpyZXZpc2lvbklkEmEKC2Fubm90YXRpb25zGAYgAygLMj8uZ29vZ2xlLmNsb3VkLnJl
Y29tbWVuZGVyLnYxLlJlY29tbWVuZGVyQ29uZmlnLkFubm90YXRpb25zRW50cnlSC2Fubm90
YXRpb25zEiEKDGRpc3BsYXlfbmFtZRgHIAEoCVILZGlzcGxheU5hbWUaPgoQQW5ub3RhdGlv
bnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOqwC
6kGoAgoscmVjb21tZW5kZXIuZ29vZ2xlYXBpcy5jb20vUmVjb21tZW5kZXJDb25maWcSSXBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZWNvbW1lbmRlcnMve3Jl
Y29tbWVuZGVyfS9jb25maWcSU29yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcmVjb21tZW5kZXJzL3tyZWNvbW1lbmRlcn0vY29uZmlnElhiaWxs
aW5nQWNjb3VudHMve2JpbGxpbmdfYWNjb3VudH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVj
b21tZW5kZXJzL3tyZWNvbW1lbmRlcn0vY29uZmlnIk4KG1JlY29tbWVuZGVyR2VuZXJhdGlv
bkNvbmZpZxIvCgZwYXJhbXMYASABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgZwYXJh
bXNCowEKH2NvbS5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFCFlJlY29tbWVuZGVyQ29u
ZmlnUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9yZWNvbW1lbmRlci9hcGl2MS9yZWNv
bW1lbmRlcnBiO3JlY29tbWVuZGVycGKiAgRDUkVDqgIbR29vZ2xlLkNsb3VkLlJlY29tbWVu
ZGVyLlYxSrsVCgYSBA4AVQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACYKCQoCAwMSAxUAKQoI
CgEIEgMXADgKCQoCCCUSAxcAOAoICgEIEgMYAFgKCQoCCAsSAxgAWAoICgEIEgMZACIKCQoC
CAoSAxkAIgoICgEIEgMaADcKCQoCCAgSAxoANwoICgEIEgMbADgKCQoCCAESAxsAOAoICgEI
EgMcACIKCQoCCCQSAxwAIgouCgIEABIEHwBMARoiIENvbmZpZ3VyYXRpb24gZm9yIGEgUmVj
b21tZW5kZXIuCgoKCgMEAAESAx8IGQoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKkQEK
BAQAAgASAyoCPRqDASBJZGVudGlmaWVyLiBOYW1lIG9mIHJlY29tbWVuZGVyIGNvbmZpZy4K
IEVnLAogcHJvamVjdHMvW1BST0pFQ1RfTlVNQkVSXS9sb2NhdGlvbnMvW0xPQ0FUSU9OXS9y
ZWNvbW1lbmRlcnMvW1JFQ09NTUVOREVSX0lEXS9jb25maWcKCgwKBQQAAgAFEgMqAggKDAoF
BAACAAESAyoJDQoMCgUEAAIAAxIDKhARCgwKBQQAAgAIEgMqEjwKDwoIBAACAAicCAASAyoT
Owp0CgQEAAIBEgMuAkAaZyBSZWNvbW1lbmRlckdlbmVyYXRpb25Db25maWcgd2hpY2ggY29u
ZmlndXJlcyB0aGUgR2VuZXJhdGlvbiBvZgogcmVjb21tZW5kYXRpb25zIGZvciB0aGlzIHJl
Y29tbWVuZGVyLgoKDAoFBAACAQYSAy4CHQoMCgUEAAIBARIDLh47CgwKBQQAAgEDEgMuPj8K
YAoEBAACAhIDMgISGlMgRmluZ2VycHJpbnQgb2YgdGhlIFJlY29tbWVuZGVyQ29uZmlnLiBQ
cm92aWRlcyBvcHRpbWlzdGljIGxvY2tpbmcgd2hlbgogdXBkYXRpbmcuCgoMCgUEAAICBRID
MgIICgwKBQQAAgIBEgMyCQ0KDAoFBAACAgMSAzIQEQo1CgQEAAIDEgM1AiwaKCBMYXN0IHRp
bWUgd2hlbiB0aGUgY29uZmlnIHdhcyB1cGRhdGVkLgoKDAoFBAACAwYSAzUCGwoMCgUEAAID
ARIDNRwnCgwKBQQAAgMDEgM1KisKwQEKBAQAAgQSBDoCPQQasgEgT3V0cHV0IG9ubHkuIElt
bXV0YWJsZS4gVGhlIHJldmlzaW9uIElEIG9mIHRoZSBjb25maWcuCiBBIG5ldyByZXZpc2lv
biBpcyBjb21taXR0ZWQgd2hlbmV2ZXIgdGhlIGNvbmZpZyBpcyBjaGFuZ2VkIGluIGFueSB3
YXkuCiBUaGUgZm9ybWF0IGlzIGFuIDgtY2hhcmFjdGVyIGhleGFkZWNpbWFsIHN0cmluZy4K
CgwKBQQAAgQFEgM6AggKDAoFBAACBAESAzoJFAoMCgUEAAIEAxIDOhcYCg0KBQQAAgQIEgQ6
GT0DCg8KCAQAAgQInAgAEgM7BCsKDwoIBAACBAicCAESAzwELQrIAwoEBAACBRIDRwImGroD
IEFsbG93cyBjbGllbnRzIHRvIHN0b3JlIHNtYWxsIGFtb3VudHMgb2YgYXJiaXRyYXJ5IGRh
dGEuIEFubm90YXRpb25zIG11c3QKIGZvbGxvdyB0aGUgS3ViZXJuZXRlcyBzeW50YXguCiBU
aGUgdG90YWwgc2l6ZSBvZiBhbGwga2V5cyBhbmQgdmFsdWVzIGNvbWJpbmVkIGlzIGxpbWl0
ZWQgdG8gMjU2ay4KIEtleSBjYW4gaGF2ZSAyIHNlZ21lbnRzOiBwcmVmaXggKG9wdGlvbmFs
KSBhbmQgbmFtZSAocmVxdWlyZWQpLAogc2VwYXJhdGVkIGJ5IGEgc2xhc2ggKC8pLgogUHJl
Zml4IG11c3QgYmUgYSBETlMgc3ViZG9tYWluLgogTmFtZSBtdXN0IGJlIDYzIGNoYXJhY3Rl
cnMgb3IgbGVzcywgYmVnaW4gYW5kIGVuZCB3aXRoIGFscGhhbnVtZXJpY3MsCiB3aXRoIGRh
c2hlcyAoLSksIHVuZGVyc2NvcmVzIChfKSwgZG90cyAoLiksIGFuZCBhbHBoYW51bWVyaWNz
IGJldHdlZW4uCgoMCgUEAAIFBhIDRwIVCgwKBQQAAgUBEgNHFiEKDAoFBAACBQMSA0ckJQpl
CgQEAAIGEgNLAhoaWCBBIHVzZXItc2V0dGFibGUgZmllbGQgdG8gcHJvdmlkZSBhIGh1bWFu
LXJlYWRhYmxlIG5hbWUgdG8gYmUgdXNlZCBpbiB1c2VyCiBpbnRlcmZhY2VzLgoKDAoFBAAC
BgUSA0sCCAoMCgUEAAIGARIDSwkVCgwKBQQAAgYDEgNLGBkKoQEKAgQBEgRRAFUBGpQBIEEg
Q29uZmlndXJhdGlvbiB0byBjdXN0b21pemUgdGhlIGdlbmVyYXRpb24gb2YgcmVjb21tZW5k
YXRpb25zLgogRWcsIGN1c3RvbWl6aW5nIHRoZSBsb29rYmFjayBwZXJpb2QgY29uc2lkZXJl
ZCB3aGVuIGdlbmVyYXRpbmcgYQogcmVjb21tZW5kYXRpb24uCgoKCgMEAQESA1EIIwp9CgQE
AQIAEgNUAiQacCBQYXJhbWV0ZXJzIGZvciB0aGlzIFJlY29tbWVuZGVyR2VuZXJhdGlvbkNv
bmZpZy4gVGhlc2UgY29uZmlncyBjYW4gYmUgdXNlZAogYnkgb3IgYXJlIGFwcGxpZWQgdG8g
YWxsIHN1YnR5cGVzLgoKDAoFBAECAAYSA1QCGAoMCgUEAQIAARIDVBkfCgwKBQQBAgADEgNU
IiNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig ===
    # Fields for RecommenderConfig
    # Field: name Type: 9 ()
    # Field: recommender_generation_config Type: 11 (.google.cloud.recommender.v1.RecommenderGenerationConfig)
    # Field: etag Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: revision_id Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.recommender.v1.RecommenderConfig.AnnotationsEntry)
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderGenerationConfig ===
    # Fields for RecommenderGenerationConfig
    # Field: params Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1::RecommenderConfig - Compiled Protocol Buffers messages for google/cloud/recommender/v1/recommender_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1::RecommenderConfig;

    my $msg = Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig->new({
        name => $name,
        recommender_generation_config => $recommender_generation_config,
        etag => $etag,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1/recommender_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig

Configuration for a Recommender.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of recommender config.
Eg,
projects/[PROJECT_NUMBER]/locations/[LOCATION]/recommenders/[RECOMMENDER_ID]/config

=item * C<< $msg->recommender_generation_config() >> / C<< $msg->recommender_generation_config($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderGenerationConfig>)

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

Type: C<Message> (L<Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig::AnnotationsEntry>)

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

=head2 Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderGenerationConfig

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1::RecommenderConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
