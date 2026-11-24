package Google::Devtools::Artifactregistry::V1::AptArtifact;

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
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9hcHRfYXJ0aWZhY3QucHJv
dG8SI2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhdnb29nbGUv
cnBjL3N0YXR1cy5wcm90byKABAoLQXB0QXJ0aWZhY3QSFwoEbmFtZRgBIAEoCUID4EEDUgRu
YW1lEiYKDHBhY2thZ2VfbmFtZRgCIAEoCUID4EEDUgtwYWNrYWdlTmFtZRJkCgxwYWNrYWdl
X3R5cGUYAyABKA4yPC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5BcHRB
cnRpZmFjdC5QYWNrYWdlVHlwZUID4EEDUgtwYWNrYWdlVHlwZRInCgxhcmNoaXRlY3R1cmUY
BCABKAlCA+BBA1IMYXJjaGl0ZWN0dXJlEiEKCWNvbXBvbmVudBgFIAEoCUID4EEDUgljb21w
b25lbnQSJgoMY29udHJvbF9maWxlGAYgASgMQgPgQQNSC2NvbnRyb2xGaWxlIkMKC1BhY2th
Z2VUeXBlEhwKGFBBQ0tBR0VfVFlQRV9VTlNQRUNJRklFRBAAEgoKBkJJTkFSWRABEgoKBlNP
VVJDRRACOpAB6kGMAQorYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9BcHRBcnRp
ZmFjdBJdcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRv
cmllcy97cmVwb3NpdG9yeX0vYXB0QXJ0aWZhY3RzL3thcHRfYXJ0aWZhY3R9IlYKG0ltcG9y
dEFwdEFydGlmYWN0c0djc1NvdXJjZRISCgR1cmlzGAEgAygJUgR1cmlzEiMKDXVzZV93aWxk
Y2FyZHMYAiABKAhSDHVzZVdpbGRjYXJkcyKgAQoZSW1wb3J0QXB0QXJ0aWZhY3RzUmVxdWVz
dBJhCgpnY3Nfc291cmNlGAIgASgLMkAuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0
cnkudjEuSW1wb3J0QXB0QXJ0aWZhY3RzR2NzU291cmNlSABSCWdjc1NvdXJjZRIWCgZwYXJl
bnQYASABKAlSBnBhcmVudEIICgZzb3VyY2UitAEKG0ltcG9ydEFwdEFydGlmYWN0c0Vycm9y
SW5mbxJhCgpnY3Nfc291cmNlGAEgASgLMkAuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVn
aXN0cnkudjEuSW1wb3J0QXB0QXJ0aWZhY3RzR2NzU291cmNlSABSCWdjc1NvdXJjZRIoCgVl
cnJvchgCIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgVlcnJvckIICgZzb3VyY2UizQEKGklt
cG9ydEFwdEFydGlmYWN0c1Jlc3BvbnNlElUKDWFwdF9hcnRpZmFjdHMYASADKAsyMC5nb29n
bGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5BcHRBcnRpZmFjdFIMYXB0QXJ0aWZh
Y3RzElgKBmVycm9ycxgCIAMoCzJALmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5
LnYxLkltcG9ydEFwdEFydGlmYWN0c0Vycm9ySW5mb1IGZXJyb3JzIhwKGkltcG9ydEFwdEFy
dGlmYWN0c01ldGFkYXRhQvsBCidjb20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0
cnkudjFCEEFwdEFydGlmYWN0UHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFj
dHJlZ2lzdHJ5L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKq
AiBHb29nbGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRp
ZmFjdFJlZ2lzdHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFK
vxwKBhIEDgBxJQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
LAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAIQoICgEIEgMWAD0KCQoCCCUSAxYA
PQoICgEIEgMXAGcKCQoCCAsSAxcAZwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADEK
CQoCCAgSAxkAMQoICgEIEgMaAEAKCQoCCAESAxoAQAoICgEIEgMbAD0KCQoCCCkSAxsAPQoI
CgEIEgMcADwKCQoCCC0SAxwAPArHAQoCBAASBCEARAEaugEgQSBkZXRhaWxlZCByZXByZXNl
bnRhdGlvbiBvZiBhbiBBcHQgYXJ0aWZhY3QuIEluZm9ybWF0aW9uIGluIHRoZSByZWNvcmQK
IGlzIGRlcml2ZWQgZnJvbSB0aGUgYXJjaGl2ZSdzIGNvbnRyb2wgZmlsZS4KIFNlZSBodHRw
czovL3d3dy5kZWJpYW4ub3JnL2RvYy9kZWJpYW4tcG9saWN5L2NoLWNvbnRyb2xmaWVsZHMu
aHRtbAoKCgoDBAABEgMhCBMKCwoDBAAHEgQiAiUECg0KBQQAB50IEgQiAiUECjgKBAQABAAS
BCgCMQMaKiBQYWNrYWdlIHR5cGUgaXMgZWl0aGVyIGJpbmFyeSBvciBzb3VyY2UuCgoMCgUE
AAQAARIDKAcSCi8KBgQABAACABIDKgQhGiAgUGFja2FnZSB0eXBlIGlzIG5vdCBzcGVjaWZp
ZWQuCgoOCgcEAAQAAgABEgMqBBwKDgoHBAAEAAIAAhIDKh8gCiAKBgQABAACARIDLQQPGhEg
QmluYXJ5IHBhY2thZ2UuCgoOCgcEAAQAAgEBEgMtBAoKDgoHBAAEAAIBAhIDLQ0OCiAKBgQA
BAACAhIDMAQPGhEgU291cmNlIHBhY2thZ2UuCgoOCgcEAAQAAgIBEgMwBAoKDgoHBAAEAAIC
AhIDMA0OClAKBAQAAgASAzQCPhpDIE91dHB1dCBvbmx5LiBUaGUgQXJ0aWZhY3QgUmVnaXN0
cnkgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYXJ0aWZhY3QuCgoMCgUEAAIABRIDNAIICgwKBQQA
AgABEgM0CQ0KDAoFBAACAAMSAzQQEQoMCgUEAAIACBIDNBI9Cg8KCAQAAgAInAgAEgM0EzwK
QQoEBAACARIDNwJGGjQgT3V0cHV0IG9ubHkuIFRoZSBBcHQgcGFja2FnZSBuYW1lIG9mIHRo
ZSBhcnRpZmFjdC4KCgwKBQQAAgEFEgM3AggKDAoFBAACAQESAzcJFQoMCgUEAAIBAxIDNxgZ
CgwKBQQAAgEIEgM3GkUKDwoIBAACAQicCAASAzcbRApGCgQEAAICEgM6AksaOSBPdXRwdXQg
b25seS4gQW4gYXJ0aWZhY3QgaXMgYSBiaW5hcnkgb3Igc291cmNlIHBhY2thZ2UuCgoMCgUE
AAICBhIDOgINCgwKBQQAAgIBEgM6DhoKDAoFBAACAgMSAzodHgoMCgUEAAICCBIDOh9KCg8K
CAQAAgIInAgAEgM6IEkKSgoEBAACAxIDPQJGGj0gT3V0cHV0IG9ubHkuIE9wZXJhdGluZyBz
eXN0ZW0gYXJjaGl0ZWN0dXJlIG9mIHRoZSBhcnRpZmFjdC4KCgwKBQQAAgMFEgM9AggKDAoF
BAACAwESAz0JFQoMCgUEAAIDAxIDPRgZCgwKBQQAAgMIEgM9GkUKDwoIBAACAwicCAASAz0b
RApBCgQEAAIEEgNAAkMaNCBPdXRwdXQgb25seS4gUmVwb3NpdG9yeSBjb21wb25lbnQgb2Yg
dGhlIGFydGlmYWN0LgoKDAoFBAACBAUSA0ACCAoMCgUEAAIEARIDQAkSCgwKBQQAAgQDEgNA
FRYKDAoFBAACBAgSA0AXQgoPCggEAAIECJwIABIDQBhBCk0KBAQAAgUSA0MCRRpAIE91dHB1
dCBvbmx5LiBDb250ZW50cyBvZiB0aGUgYXJ0aWZhY3QncyBjb250cm9sIG1ldGFkYXRhIGZp
bGUuCgoMCgUEAAIFBRIDQwIHCgwKBQQAAgUBEgNDCBQKDAoFBAACBQMSA0MXGAoMCgUEAAIF
CBIDQxlECg8KCAQAAgUInAgAEgNDGkMKUQoCBAESBEcATQEaRSBHb29nbGUgQ2xvdWQgU3Rv
cmFnZSBsb2NhdGlvbiB3aGVyZSB0aGUgYXJ0aWZhY3RzIGN1cnJlbnRseSByZXNpZGUuCgoK
CgMEAQESA0cIIwpJCgQEAQIAEgNJAhsaPCBDbG91ZCBTdG9yYWdlIHBhdGhzIFVSSSAoZS5n
LiwgZ3M6Ly9teV9idWNrZXQvL215X29iamVjdCkuCgoMCgUEAQIABBIDSQIKCgwKBQQBAgAF
EgNJCxEKDAoFBAECAAESA0kSFgoMCgUEAQIAAxIDSRkaClYKBAQBAgESA0wCGRpJIFN1cHBv
cnRzIFVSSSB3aWxkY2FyZHMgZm9yIG1hdGNoaW5nIG11bHRpcGxlIG9iamVjdHMgZnJvbSBh
IHNpbmdsZSBVUkkuCgoMCgUEAQIBBRIDTAIGCgwKBQQBAgEBEgNMBxQKDAoFBAECAQMSA0wX
GAo2CgIEAhIEUABZARoqIFRoZSByZXF1ZXN0IHRvIGltcG9ydCBuZXcgYXB0IGFydGlmYWN0
cy4KCgoKAwQCARIDUAghCjwKBAQCCAASBFICVQMaLiBUaGUgc291cmNlIGxvY2F0aW9uIG9m
IHRoZSBwYWNrYWdlIGJpbmFyaWVzLgoKDAoFBAIIAAESA1IIDgpMCgQEAgIAEgNUBC8aPyBH
b29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiB3aGVyZSBpbnB1dCBjb250ZW50IGlzIGxv
Y2F0ZWQuCgoMCgUEAgIABhIDVAQfCgwKBQQCAgABEgNUICoKDAoFBAICAAMSA1QtLgpUCgQE
AgIBEgNYAhQaRyBUaGUgbmFtZSBvZiB0aGUgcGFyZW50IHJlc291cmNlIHdoZXJlIHRoZSBh
cnRpZmFjdHMgd2lsbCBiZSBpbXBvcnRlZC4KCgwKBQQCAgEFEgNYAggKDAoFBAICAQESA1gJ
DwoMCgUEAgIBAxIDWBITCkoKAgQDEgRcAGUBGj4gRXJyb3IgaW5mb3JtYXRpb24gZXhwbGFp
bmluZyB3aHkgYSBwYWNrYWdlIHdhcyBub3QgaW1wb3J0ZWQuCgoKCgMEAwESA1wIIwoxCgQE
AwgAEgReAmEDGiMgVGhlIHNvdXJjZSB0aGF0IHdhcyBub3QgaW1wb3J0ZWQuCgoMCgUEAwgA
ARIDXggOCjcKBAQDAgASA2AELxoqIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGxvY2F0aW9uIHJl
cXVlc3RlZC4KCgwKBQQDAgAGEgNgBB8KDAoFBAMCAAESA2AgKgoMCgUEAwIAAxIDYC0uCikK
BAQDAgESA2QCHhocIFRoZSBkZXRhaWxlZCBlcnJvciBzdGF0dXMuCgoMCgUEAwIBBhIDZAIT
CgwKBQQDAgEBEgNkFBkKDAoFBAMCAQMSA2QcHQpACgIEBBIEaABuARo0IFRoZSByZXNwb25z
ZSBtZXNzYWdlIGZyb20gaW1wb3J0aW5nIEFQVCBhcnRpZmFjdHMuCgoKCgMEBAESA2gIIgoq
CgQEBAIAEgNqAikaHSBUaGUgQXB0IGFydGlmYWN0cyBpbXBvcnRlZC4KCgwKBQQEAgAEEgNq
AgoKDAoFBAQCAAYSA2oLFgoMCgUEBAIAARIDahckCgwKBQQEAgADEgNqJygKRwoEBAQCARID
bQIyGjogRGV0YWlsZWQgZXJyb3IgaW5mbyBmb3IgcGFja2FnZXMgdGhhdCB3ZXJlIG5vdCBp
bXBvcnRlZC4KCgwKBQQEAgEEEgNtAgoKDAoFBAQCAQYSA20LJgoMCgUEBAIBARIDbSctCgwK
BQQEAgEDEgNtMDEKPAoCBAUSA3EAJRoxIFRoZSBvcGVyYXRpb24gbWV0YWRhdGEgZm9yIGlt
cG9ydGluZyBhcnRpZmFjdHMuCgoKCgMEBQESA3EIImIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact ===
    # Fields for AptArtifact
    # Field: name Type: 9 ()
    # Field: package_name Type: 9 ()
    # Field: package_type Type: 14 (.google.devtools.artifactregistry.v1.AptArtifact.PackageType)
    # Field: architecture Type: 9 ()
    # Field: component Type: 9 ()
    # Field: control_file Type: 12 ()

# Enum: AptArtifact::PackageType
our $AptArtifact_PACKAGE_TYPE_UNSPECIFIED = 0;
our $AptArtifact_BINARY = 1;
our $AptArtifact_SOURCE = 2;

# === Message: Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource ===
    # Fields for ImportAptArtifactsGcsSource
    # Field: uris Type: 9 ()
    # Field: use_wildcards Type: 8 ()

# === Message: Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsRequest ===
    # Fields for ImportAptArtifactsRequest
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1.ImportAptArtifactsGcsSource)
    # Field: parent Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsErrorInfo ===
    # Fields for ImportAptArtifactsErrorInfo
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1.ImportAptArtifactsGcsSource)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsResponse ===
    # Fields for ImportAptArtifactsResponse
    # Field: apt_artifacts Type: 11 (.google.devtools.artifactregistry.v1.AptArtifact)
    # Field: errors Type: 11 (.google.devtools.artifactregistry.v1.ImportAptArtifactsErrorInfo)

# === Message: Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsMetadata ===
    # Fields for ImportAptArtifactsMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::AptArtifact - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/apt_artifact.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::AptArtifact;

    my $msg = Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact->new({
        name => $name,
        package_name => $package_name,
        package_type => $package_type,
        architecture => $architecture,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/apt_artifact.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact

A detailed representation of an Apt artifact. Information in the record
is derived from the archive's control file.
See https://www.debian.org/doc/debian-policy/ch-controlfields.html

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The Artifact Registry resource name of the artifact.

=item * C<< $msg->package_name() >> / C<< $msg->package_name($value) >>

Type: C<String>

Output only. The Apt package name of the artifact.

=item * C<< $msg->package_type() >> / C<< $msg->package_type($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::AptArtifact::PackageType>)

Output only. An artifact is a binary or source package.

=item * C<< $msg->architecture() >> / C<< $msg->architecture($value) >>

Type: C<String>

Output only. Operating system architecture of the artifact.

=item * C<< $msg->component() >> / C<< $msg->component($value) >>

Type: C<String>

Output only. Repository component of the artifact.

=item * C<< $msg->control_file() >> / C<< $msg->control_file($value) >>

Type: C<Bytes>

Output only. Contents of the artifact's control metadata file.

=back

=head3 Enum: AptArtifact::PackageType

=over 4

=item * C<PACKAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<BINARY> => C<1>

=item * C<SOURCE> => C<2>

=back

=head2 Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource

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

=head2 Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsRequest

The request to import new apt artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource>)

Google Cloud Storage location where input content is located.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource where the artifacts will be imported.

=back

=head2 Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsErrorInfo

Error information explaining why a package was not imported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource>)

Google Cloud Storage location requested.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The detailed error status.

=back

=head2 Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsResponse

The response message from importing APT artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->apt_artifacts() >> / C<< $msg->apt_artifacts($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact>)

The Apt artifacts imported.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsErrorInfo>)

Detailed error info for packages that were not imported.

=back

=head2 Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsMetadata

The operation metadata for importing artifacts.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::AptArtifact::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
