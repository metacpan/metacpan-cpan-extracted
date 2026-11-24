package Google::Devtools::Artifactregistry::V1beta2::YumArtifact;

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
Cjtnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3l1bV9hcnRpZmFj
dC5wcm90bxIoZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMhofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8iugMKC1l1bUFydGlmYWN0EhcKBG5hbWUYASAB
KAlCA+BBA1IEbmFtZRImCgxwYWNrYWdlX25hbWUYAiABKAlCA+BBA1ILcGFja2FnZU5hbWUS
aQoMcGFja2FnZV90eXBlGAMgASgOMkEuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0
cnkudjFiZXRhMi5ZdW1BcnRpZmFjdC5QYWNrYWdlVHlwZUID4EEDUgtwYWNrYWdlVHlwZRIn
CgxhcmNoaXRlY3R1cmUYBCABKAlCA+BBA1IMYXJjaGl0ZWN0dXJlIkMKC1BhY2thZ2VUeXBl
EhwKGFBBQ0tBR0VfVFlQRV9VTlNQRUNJRklFRBAAEgoKBkJJTkFSWRABEgoKBlNPVVJDRRAC
OpAB6kGMAQorYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9ZdW1BcnRpZmFjdBJd
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmllcy97
cmVwb3NpdG9yeX0veXVtQXJ0aWZhY3RzL3t5dW1fYXJ0aWZhY3R9IlYKG0ltcG9ydFl1bUFy
dGlmYWN0c0djc1NvdXJjZRISCgR1cmlzGAEgAygJUgR1cmlzEiMKDXVzZV93aWxkY2FyZHMY
AiABKAhSDHVzZVdpbGRjYXJkcyKlAQoZSW1wb3J0WXVtQXJ0aWZhY3RzUmVxdWVzdBJmCgpn
Y3Nfc291cmNlGAIgASgLMkUuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFi
ZXRhMi5JbXBvcnRZdW1BcnRpZmFjdHNHY3NTb3VyY2VIAFIJZ2NzU291cmNlEhYKBnBhcmVu
dBgBIAEoCVIGcGFyZW50QggKBnNvdXJjZSK5AQobSW1wb3J0WXVtQXJ0aWZhY3RzRXJyb3JJ
bmZvEmYKCmdjc19zb3VyY2UYASABKAsyRS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdp
c3RyeS52MWJldGEyLkltcG9ydFl1bUFydGlmYWN0c0djc1NvdXJjZUgAUglnY3NTb3VyY2US
KAoFZXJyb3IYAiABKAsyEi5nb29nbGUucnBjLlN0YXR1c1IFZXJyb3JCCAoGc291cmNlItcB
ChpJbXBvcnRZdW1BcnRpZmFjdHNSZXNwb25zZRJaCg15dW1fYXJ0aWZhY3RzGAEgAygLMjUu
Z29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5ZdW1BcnRpZmFjdFIM
eXVtQXJ0aWZhY3RzEl0KBmVycm9ycxgCIAMoCzJFLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFj
dHJlZ2lzdHJ5LnYxYmV0YTIuSW1wb3J0WXVtQXJ0aWZhY3RzRXJyb3JJbmZvUgZlcnJvcnMi
HAoaSW1wb3J0WXVtQXJ0aWZhY3RzTWV0YWRhdGFClAIKLGNvbS5nb29nbGUuZGV2dG9vbHMu
YXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyQhBZdW1BcnRpZmFjdFByb3RvUAFaVWNsb3VkLmdv
b2dsZS5jb20vZ28vYXJ0aWZhY3RyZWdpc3RyeS9hcGl2MWJldGEyL2FydGlmYWN0cmVnaXN0
cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiVHb29nbGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3Ry
eS5WMUJldGEyygIlR29vZ2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlcVjFiZXRhMuoCKEdv
b2dsZTo6Q2xvdWQ6OkFydGlmYWN0UmVnaXN0cnk6OlYxYmV0YTJKnhkKBhIEDgBqAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAIQoICgEIEgMWAEIKCQoCCCUSAxYAQgoICgEIEgMXAGwKCQoC
CAsSAxcAbAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADEKCQoCCAgSAxkAMQoICgEI
EgMaAEUKCQoCCAESAxoARQoICgEIEgMbAEIKCQoCCCkSAxsAQgoICgEIEgMcAEEKCQoCCC0S
AxwAQQo6CgIEABIEHwA8ARouIEEgZGV0YWlsZWQgcmVwcmVzZW50YXRpb24gb2YgYSBZdW0g
YXJ0aWZhY3QuCgoKCgMEAAESAx8IEwoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKOAoE
BAAEABIEJgIvAxoqIFBhY2thZ2UgdHlwZSBpcyBlaXRoZXIgYmluYXJ5IG9yIHNvdXJjZS4K
CgwKBQQABAABEgMmBxIKLwoGBAAEAAIAEgMoBCEaICBQYWNrYWdlIHR5cGUgaXMgbm90IHNw
ZWNpZmllZC4KCg4KBwQABAACAAESAygEHAoOCgcEAAQAAgACEgMoHyAKJwoGBAAEAAIBEgMr
BA8aGCBCaW5hcnkgcGFja2FnZSAoLnJwbSkuCgoOCgcEAAQAAgEBEgMrBAoKDgoHBAAEAAIB
AhIDKw0OCigKBgQABAACAhIDLgQPGhkgU291cmNlIHBhY2thZ2UgKC5zcnBtKS4KCg4KBwQA
BAACAgESAy4ECgoOCgcEAAQAAgICEgMuDQ4KUAoEBAACABIDMgI+GkMgT3V0cHV0IG9ubHku
IFRoZSBBcnRpZmFjdCBSZWdpc3RyeSByZXNvdXJjZSBuYW1lIG9mIHRoZSBhcnRpZmFjdC4K
CgwKBQQAAgAFEgMyAggKDAoFBAACAAESAzIJDQoMCgUEAAIAAxIDMhARCgwKBQQAAgAIEgMy
Ej0KDwoIBAACAAicCAASAzITPApBCgQEAAIBEgM1AkYaNCBPdXRwdXQgb25seS4gVGhlIHl1
bSBwYWNrYWdlIG5hbWUgb2YgdGhlIGFydGlmYWN0LgoKDAoFBAACAQUSAzUCCAoMCgUEAAIB
ARIDNQkVCgwKBQQAAgEDEgM1GBkKDAoFBAACAQgSAzUaRQoPCggEAAIBCJwIABIDNRtECkYK
BAQAAgISAzgCSxo5IE91dHB1dCBvbmx5LiBBbiBhcnRpZmFjdCBpcyBhIGJpbmFyeSBvciBz
b3VyY2UgcGFja2FnZS4KCgwKBQQAAgIGEgM4Ag0KDAoFBAACAgESAzgOGgoMCgUEAAICAxID
OB0eCgwKBQQAAgIIEgM4H0oKDwoIBAACAgicCAASAzggSQpKCgQEAAIDEgM7AkYaPSBPdXRw
dXQgb25seS4gT3BlcmF0aW5nIHN5c3RlbSBhcmNoaXRlY3R1cmUgb2YgdGhlIGFydGlmYWN0
LgoKDAoFBAACAwUSAzsCCAoMCgUEAAIDARIDOwkVCgwKBQQAAgMDEgM7GBkKDAoFBAACAwgS
AzsaRQoPCggEAAIDCJwIABIDOxtEClEKAgQBEgQ/AEUBGkUgR29vZ2xlIENsb3VkIFN0b3Jh
Z2UgbG9jYXRpb24gd2hlcmUgdGhlIGFydGlmYWN0cyBjdXJyZW50bHkgcmVzaWRlLgoKCgoD
BAEBEgM/CCMKSQoEBAECABIDQQIbGjwgQ2xvdWQgU3RvcmFnZSBwYXRocyBVUkkgKGUuZy4s
IGdzOi8vbXlfYnVja2V0Ly9teV9vYmplY3QpLgoKDAoFBAECAAQSA0ECCgoMCgUEAQIABRID
QQsRCgwKBQQBAgABEgNBEhYKDAoFBAECAAMSA0EZGgpWCgQEAQIBEgNEAhkaSSBTdXBwb3J0
cyBVUkkgd2lsZGNhcmRzIGZvciBtYXRjaGluZyBtdWx0aXBsZSBvYmplY3RzIGZyb20gYSBz
aW5nbGUgVVJJLgoKDAoFBAECAQUSA0QCBgoMCgUEAQIBARIDRAcUCgwKBQQBAgEDEgNEFxgK
NgoCBAISBEgAUQEaKiBUaGUgcmVxdWVzdCB0byBpbXBvcnQgbmV3IHl1bSBhcnRpZmFjdHMu
CgoKCgMEAgESA0gIIQo8CgQEAggAEgRKAk0DGi4gVGhlIHNvdXJjZSBsb2NhdGlvbiBvZiB0
aGUgcGFja2FnZSBiaW5hcmllcy4KCgwKBQQCCAABEgNKCA4KTAoEBAICABIDTAQvGj8gR29v
Z2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gd2hlcmUgaW5wdXQgY29udGVudCBpcyBsb2Nh
dGVkLgoKDAoFBAICAAYSA0wEHwoMCgUEAgIAARIDTCAqCgwKBQQCAgADEgNMLS4KVAoEBAIC
ARIDUAIUGkcgVGhlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZSB3aGVyZSB0aGUgYXJ0
aWZhY3RzIHdpbGwgYmUgaW1wb3J0ZWQuCgoMCgUEAgIBBRIDUAIICgwKBQQCAgEBEgNQCQ8K
DAoFBAICAQMSA1ASEwpKCgIEAxIEVABdARo+IEVycm9yIGluZm9ybWF0aW9uIGV4cGxhaW5p
bmcgd2h5IGEgcGFja2FnZSB3YXMgbm90IGltcG9ydGVkLgoKCgoDBAMBEgNUCCMKMQoEBAMI
ABIEVgJZAxojIFRoZSBzb3VyY2UgdGhhdCB3YXMgbm90IGltcG9ydGVkLgoKDAoFBAMIAAES
A1YIDgo3CgQEAwIAEgNYBC8aKiBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiByZXF1
ZXN0ZWQuCgoMCgUEAwIABhIDWAQfCgwKBQQDAgABEgNYICoKDAoFBAMCAAMSA1gtLgopCgQE
AwIBEgNcAh4aHCBUaGUgZGV0YWlsZWQgZXJyb3Igc3RhdHVzLgoKDAoFBAMCAQYSA1wCEwoM
CgUEAwIBARIDXBQZCgwKBQQDAgEDEgNcHB0KQAoCBAQSBGAAZgEaNCBUaGUgcmVzcG9uc2Ug
bWVzc2FnZSBmcm9tIGltcG9ydGluZyBZVU0gYXJ0aWZhY3RzLgoKCgoDBAQBEgNgCCIKKgoE
BAQCABIDYgIpGh0gVGhlIHl1bSBhcnRpZmFjdHMgaW1wb3J0ZWQuCgoMCgUEBAIABBIDYgIK
CgwKBQQEAgAGEgNiCxYKDAoFBAQCAAESA2IXJAoMCgUEBAIAAxIDYicoCkgKBAQEAgESA2UC
Mho7IERldGFpbGVkIGVycm9yIGluZm8gZm9yIGFydGlmYWN0cyB0aGF0IHdlcmUgbm90IGlt
cG9ydGVkLgoKDAoFBAQCAQQSA2UCCgoMCgUEBAIBBhIDZQsmCgwKBQQEAgEBEgNlJy0KDAoF
BAQCAQMSA2UwMQo9CgIEBRIEaQBqARoxIFRoZSBvcGVyYXRpb24gbWV0YWRhdGEgZm9yIGlt
cG9ydGluZyBhcnRpZmFjdHMuCgoKCgMEBQESA2kIImIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::YumArtifact::YumArtifact ===
    # Fields for YumArtifact
    # Field: name Type: 9 ()
    # Field: package_name Type: 9 ()
    # Field: package_type Type: 14 (.google.devtools.artifactregistry.v1beta2.YumArtifact.PackageType)
    # Field: architecture Type: 9 ()

# Enum: YumArtifact::PackageType
our $YumArtifact_PACKAGE_TYPE_UNSPECIFIED = 0;
our $YumArtifact_BINARY = 1;
our $YumArtifact_SOURCE = 2;

# === Message: Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsGcsSource ===
    # Fields for ImportYumArtifactsGcsSource
    # Field: uris Type: 9 ()
    # Field: use_wildcards Type: 8 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsRequest ===
    # Fields for ImportYumArtifactsRequest
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1beta2.ImportYumArtifactsGcsSource)
    # Field: parent Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsErrorInfo ===
    # Fields for ImportYumArtifactsErrorInfo
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1beta2.ImportYumArtifactsGcsSource)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsResponse ===
    # Fields for ImportYumArtifactsResponse
    # Field: yum_artifacts Type: 11 (.google.devtools.artifactregistry.v1beta2.YumArtifact)
    # Field: errors Type: 11 (.google.devtools.artifactregistry.v1beta2.ImportYumArtifactsErrorInfo)

# === Message: Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsMetadata ===
    # Fields for ImportYumArtifactsMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::YumArtifact - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/yum_artifact.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::YumArtifact;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::YumArtifact::YumArtifact->new({
        name => $name,
        package_name => $package_name,
        package_type => $package_type,
        architecture => $architecture,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::YumArtifact::YumArtifact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/yum_artifact.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::YumArtifact::YumArtifact

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

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::YumArtifact::PackageType>)

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

=head2 Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsGcsSource

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

=head2 Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsRequest

The request to import new yum artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsGcsSource>)

Google Cloud Storage location where input content is located.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource where the artifacts will be imported.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsErrorInfo

Error information explaining why a package was not imported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsGcsSource>)

Google Cloud Storage location requested.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The detailed error status.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsResponse

The response message from importing YUM artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->yum_artifacts() >> / C<< $msg->yum_artifacts($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::YumArtifact::YumArtifact>)

The yum artifacts imported.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsErrorInfo>)

Detailed error info for artifacts that were not imported.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsMetadata

The operation metadata for importing artifacts.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::YumArtifact::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
