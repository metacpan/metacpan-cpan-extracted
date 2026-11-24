package Google::Devtools::Artifactregistry::V1::YumArtifact;

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
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS95dW1fYXJ0aWZhY3QucHJv
dG8SI2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhdnb29nbGUv
cnBjL3N0YXR1cy5wcm90byK1AwoLWXVtQXJ0aWZhY3QSFwoEbmFtZRgBIAEoCUID4EEDUgRu
YW1lEiYKDHBhY2thZ2VfbmFtZRgCIAEoCUID4EEDUgtwYWNrYWdlTmFtZRJkCgxwYWNrYWdl
X3R5cGUYAyABKA4yPC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5ZdW1B
cnRpZmFjdC5QYWNrYWdlVHlwZUID4EEDUgtwYWNrYWdlVHlwZRInCgxhcmNoaXRlY3R1cmUY
BCABKAlCA+BBA1IMYXJjaGl0ZWN0dXJlIkMKC1BhY2thZ2VUeXBlEhwKGFBBQ0tBR0VfVFlQ
RV9VTlNQRUNJRklFRBAAEgoKBkJJTkFSWRABEgoKBlNPVVJDRRACOpAB6kGMAQorYXJ0aWZh
Y3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9ZdW1BcnRpZmFjdBJdcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmllcy97cmVwb3NpdG9yeX0veXVt
QXJ0aWZhY3RzL3t5dW1fYXJ0aWZhY3R9IlYKG0ltcG9ydFl1bUFydGlmYWN0c0djc1NvdXJj
ZRISCgR1cmlzGAEgAygJUgR1cmlzEiMKDXVzZV93aWxkY2FyZHMYAiABKAhSDHVzZVdpbGRj
YXJkcyKgAQoZSW1wb3J0WXVtQXJ0aWZhY3RzUmVxdWVzdBJhCgpnY3Nfc291cmNlGAIgASgL
MkAuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEuSW1wb3J0WXVtQXJ0aWZh
Y3RzR2NzU291cmNlSABSCWdjc1NvdXJjZRIWCgZwYXJlbnQYASABKAlSBnBhcmVudEIICgZz
b3VyY2UitAEKG0ltcG9ydFl1bUFydGlmYWN0c0Vycm9ySW5mbxJhCgpnY3Nfc291cmNlGAEg
ASgLMkAuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEuSW1wb3J0WXVtQXJ0
aWZhY3RzR2NzU291cmNlSABSCWdjc1NvdXJjZRIoCgVlcnJvchgCIAEoCzISLmdvb2dsZS5y
cGMuU3RhdHVzUgVlcnJvckIICgZzb3VyY2UizQEKGkltcG9ydFl1bUFydGlmYWN0c1Jlc3Bv
bnNlElUKDXl1bV9hcnRpZmFjdHMYASADKAsyMC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3Ry
ZWdpc3RyeS52MS5ZdW1BcnRpZmFjdFIMeXVtQXJ0aWZhY3RzElgKBmVycm9ycxgCIAMoCzJA
Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLkltcG9ydFl1bUFydGlmYWN0
c0Vycm9ySW5mb1IGZXJyb3JzIhwKGkltcG9ydFl1bUFydGlmYWN0c01ldGFkYXRhQvsBCidj
b20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFCEFl1bUFydGlmYWN0UHJv
dG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJlZ2lzdHJ5L2FwaXYxL2FydGlm
YWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiBHb29nbGUuQ2xvdWQuQXJ0aWZh
Y3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRpZmFjdFJlZ2lzdHJ5XFYx6gIjR29v
Z2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFKnBkKBhIEDgBpJQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAIQoICgEIEgMWAD0KCQoCCCUSAxYAPQoICgEIEgMXAGcKCQoCCAsSAxcA
ZwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADEKCQoCCAgSAxkAMQoICgEIEgMaAEAK
CQoCCAESAxoAQAoICgEIEgMbAD0KCQoCCCkSAxsAPQoICgEIEgMcADwKCQoCCC0SAxwAPAo6
CgIEABIEHwA8ARouIEEgZGV0YWlsZWQgcmVwcmVzZW50YXRpb24gb2YgYSBZdW0gYXJ0aWZh
Y3QuCgoKCgMEAAESAx8IEwoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKOAoEBAAEABIE
JgIvAxoqIFBhY2thZ2UgdHlwZSBpcyBlaXRoZXIgYmluYXJ5IG9yIHNvdXJjZS4KCgwKBQQA
BAABEgMmBxIKLwoGBAAEAAIAEgMoBCEaICBQYWNrYWdlIHR5cGUgaXMgbm90IHNwZWNpZmll
ZC4KCg4KBwQABAACAAESAygEHAoOCgcEAAQAAgACEgMoHyAKJwoGBAAEAAIBEgMrBA8aGCBC
aW5hcnkgcGFja2FnZSAoLnJwbSkuCgoOCgcEAAQAAgEBEgMrBAoKDgoHBAAEAAIBAhIDKw0O
CigKBgQABAACAhIDLgQPGhkgU291cmNlIHBhY2thZ2UgKC5zcnBtKS4KCg4KBwQABAACAgES
Ay4ECgoOCgcEAAQAAgICEgMuDQ4KUAoEBAACABIDMgI+GkMgT3V0cHV0IG9ubHkuIFRoZSBB
cnRpZmFjdCBSZWdpc3RyeSByZXNvdXJjZSBuYW1lIG9mIHRoZSBhcnRpZmFjdC4KCgwKBQQA
AgAFEgMyAggKDAoFBAACAAESAzIJDQoMCgUEAAIAAxIDMhARCgwKBQQAAgAIEgMyEj0KDwoI
BAACAAicCAASAzITPApBCgQEAAIBEgM1AkYaNCBPdXRwdXQgb25seS4gVGhlIHl1bSBwYWNr
YWdlIG5hbWUgb2YgdGhlIGFydGlmYWN0LgoKDAoFBAACAQUSAzUCCAoMCgUEAAIBARIDNQkV
CgwKBQQAAgEDEgM1GBkKDAoFBAACAQgSAzUaRQoPCggEAAIBCJwIABIDNRtECkYKBAQAAgIS
AzgCSxo5IE91dHB1dCBvbmx5LiBBbiBhcnRpZmFjdCBpcyBhIGJpbmFyeSBvciBzb3VyY2Ug
cGFja2FnZS4KCgwKBQQAAgIGEgM4Ag0KDAoFBAACAgESAzgOGgoMCgUEAAICAxIDOB0eCgwK
BQQAAgIIEgM4H0oKDwoIBAACAgicCAASAzggSQpKCgQEAAIDEgM7AkYaPSBPdXRwdXQgb25s
eS4gT3BlcmF0aW5nIHN5c3RlbSBhcmNoaXRlY3R1cmUgb2YgdGhlIGFydGlmYWN0LgoKDAoF
BAACAwUSAzsCCAoMCgUEAAIDARIDOwkVCgwKBQQAAgMDEgM7GBkKDAoFBAACAwgSAzsaRQoP
CggEAAIDCJwIABIDOxtEClEKAgQBEgQ/AEUBGkUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9j
YXRpb24gd2hlcmUgdGhlIGFydGlmYWN0cyBjdXJyZW50bHkgcmVzaWRlLgoKCgoDBAEBEgM/
CCMKSQoEBAECABIDQQIbGjwgQ2xvdWQgU3RvcmFnZSBwYXRocyBVUkkgKGUuZy4sIGdzOi8v
bXlfYnVja2V0Ly9teV9vYmplY3QpLgoKDAoFBAECAAQSA0ECCgoMCgUEAQIABRIDQQsRCgwK
BQQBAgABEgNBEhYKDAoFBAECAAMSA0EZGgpWCgQEAQIBEgNEAhkaSSBTdXBwb3J0cyBVUkkg
d2lsZGNhcmRzIGZvciBtYXRjaGluZyBtdWx0aXBsZSBvYmplY3RzIGZyb20gYSBzaW5nbGUg
VVJJLgoKDAoFBAECAQUSA0QCBgoMCgUEAQIBARIDRAcUCgwKBQQBAgEDEgNEFxgKNgoCBAIS
BEgAUQEaKiBUaGUgcmVxdWVzdCB0byBpbXBvcnQgbmV3IHl1bSBhcnRpZmFjdHMuCgoKCgME
AgESA0gIIQo8CgQEAggAEgRKAk0DGi4gVGhlIHNvdXJjZSBsb2NhdGlvbiBvZiB0aGUgcGFj
a2FnZSBiaW5hcmllcy4KCgwKBQQCCAABEgNKCA4KTAoEBAICABIDTAQvGj8gR29vZ2xlIENs
b3VkIFN0b3JhZ2UgbG9jYXRpb24gd2hlcmUgaW5wdXQgY29udGVudCBpcyBsb2NhdGVkLgoK
DAoFBAICAAYSA0wEHwoMCgUEAgIAARIDTCAqCgwKBQQCAgADEgNMLS4KVAoEBAICARIDUAIU
GkcgVGhlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZSB3aGVyZSB0aGUgYXJ0aWZhY3Rz
IHdpbGwgYmUgaW1wb3J0ZWQuCgoMCgUEAgIBBRIDUAIICgwKBQQCAgEBEgNQCQ8KDAoFBAIC
AQMSA1ASEwpKCgIEAxIEVABdARo+IEVycm9yIGluZm9ybWF0aW9uIGV4cGxhaW5pbmcgd2h5
IGEgcGFja2FnZSB3YXMgbm90IGltcG9ydGVkLgoKCgoDBAMBEgNUCCMKMQoEBAMIABIEVgJZ
AxojIFRoZSBzb3VyY2UgdGhhdCB3YXMgbm90IGltcG9ydGVkLgoKDAoFBAMIAAESA1YIDgo3
CgQEAwIAEgNYBC8aKiBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiByZXF1ZXN0ZWQu
CgoMCgUEAwIABhIDWAQfCgwKBQQDAgABEgNYICoKDAoFBAMCAAMSA1gtLgopCgQEAwIBEgNc
Ah4aHCBUaGUgZGV0YWlsZWQgZXJyb3Igc3RhdHVzLgoKDAoFBAMCAQYSA1wCEwoMCgUEAwIB
ARIDXBQZCgwKBQQDAgEDEgNcHB0KQAoCBAQSBGAAZgEaNCBUaGUgcmVzcG9uc2UgbWVzc2Fn
ZSBmcm9tIGltcG9ydGluZyBZVU0gYXJ0aWZhY3RzLgoKCgoDBAQBEgNgCCIKKgoEBAQCABID
YgIpGh0gVGhlIHl1bSBhcnRpZmFjdHMgaW1wb3J0ZWQuCgoMCgUEBAIABBIDYgIKCgwKBQQE
AgAGEgNiCxYKDAoFBAQCAAESA2IXJAoMCgUEBAIAAxIDYicoCkcKBAQEAgESA2UCMho6IERl
dGFpbGVkIGVycm9yIGluZm8gZm9yIHBhY2thZ2VzIHRoYXQgd2VyZSBub3QgaW1wb3J0ZWQu
CgoMCgUEBAIBBBIDZQIKCgwKBQQEAgEGEgNlCyYKDAoFBAQCAQESA2UnLQoMCgUEBAIBAxID
ZTAxCjwKAgQFEgNpACUaMSBUaGUgb3BlcmF0aW9uIG1ldGFkYXRhIGZvciBpbXBvcnRpbmcg
YXJ0aWZhY3RzLgoKCgoDBAUBEgNpCCJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact ===
    # Fields for YumArtifact
    # Field: name Type: 9 ()
    # Field: package_name Type: 9 ()
    # Field: package_type Type: 14 (.google.devtools.artifactregistry.v1.YumArtifact.PackageType)
    # Field: architecture Type: 9 ()

# Enum: YumArtifact::PackageType
our $YumArtifact_PACKAGE_TYPE_UNSPECIFIED = 0;
our $YumArtifact_BINARY = 1;
our $YumArtifact_SOURCE = 2;

# === Message: Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource ===
    # Fields for ImportYumArtifactsGcsSource
    # Field: uris Type: 9 ()
    # Field: use_wildcards Type: 8 ()

# === Message: Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsRequest ===
    # Fields for ImportYumArtifactsRequest
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1.ImportYumArtifactsGcsSource)
    # Field: parent Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsErrorInfo ===
    # Fields for ImportYumArtifactsErrorInfo
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1.ImportYumArtifactsGcsSource)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsResponse ===
    # Fields for ImportYumArtifactsResponse
    # Field: yum_artifacts Type: 11 (.google.devtools.artifactregistry.v1.YumArtifact)
    # Field: errors Type: 11 (.google.devtools.artifactregistry.v1.ImportYumArtifactsErrorInfo)

# === Message: Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsMetadata ===
    # Fields for ImportYumArtifactsMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::YumArtifact - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/yum_artifact.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::YumArtifact;

    my $msg = Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact->new({
        name => $name,
        package_name => $package_name,
        package_type => $package_type,
        architecture => $architecture,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/yum_artifact.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact

A detailed representation of a Yum artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The Artifact Registry resource name of the artifact.

=item * C<< $msg->package_name() >> / C<< $msg->package_name($value) >>

Type: C<String>

Output only. The yum package name of the artifact.

=item * C<< $msg->package_type() >> / C<< $msg->package_type($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::YumArtifact::PackageType>)

Output only. An artifact is a binary or source package.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<String>

Output only. Operating system architecture of the artifact.

=back

=head3 Enum: YumArtifact::PackageType

=over 4

=item * C<PACKAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<BINARY> => C<1>

=item * C<SOURCE> => C<2>

=back

=head2 Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource

Google Cloud Storage location where the artifacts currently reside.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uris() >> / C<< $msg->uris($value) >>

Type: C<String>

Cloud Storage paths URI (e.g., gs://my_bucket//my_object).

=item * C<< $msg->use_wildcards() >> / C<< $msg->use_wildcards($value) >>

Type: C<Bool>

Supports URI wildcards for matching multiple objects from a single URI.

=back

=head2 Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsRequest

The request to import new yum artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource>)

Google Cloud Storage location where input content is located.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource where the artifacts will be imported.

=back

=head2 Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsErrorInfo

Error information explaining why a package was not imported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource>)

Google Cloud Storage location requested.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The detailed error status.

=back

=head2 Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsResponse

The response message from importing YUM artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->yum_artifacts() >> / C<< $msg->yum_artifacts($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact>)

The yum artifacts imported.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsErrorInfo>)

Detailed error info for packages that were not imported.

=back

=head2 Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsMetadata

The operation metadata for importing artifacts.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::YumArtifact::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
