package Google::Devtools::Artifactregistry::V1beta2::AptArtifact;

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
Cjtnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL2FwdF9hcnRpZmFj
dC5wcm90bxIoZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMhofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8ihQQKC0FwdEFydGlmYWN0EhcKBG5hbWUYASAB
KAlCA+BBA1IEbmFtZRImCgxwYWNrYWdlX25hbWUYAiABKAlCA+BBA1ILcGFja2FnZU5hbWUS
aQoMcGFja2FnZV90eXBlGAMgASgOMkEuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0
cnkudjFiZXRhMi5BcHRBcnRpZmFjdC5QYWNrYWdlVHlwZUID4EEDUgtwYWNrYWdlVHlwZRIn
CgxhcmNoaXRlY3R1cmUYBCABKAlCA+BBA1IMYXJjaGl0ZWN0dXJlEiEKCWNvbXBvbmVudBgF
IAEoCUID4EEDUgljb21wb25lbnQSJgoMY29udHJvbF9maWxlGAYgASgMQgPgQQNSC2NvbnRy
b2xGaWxlIkMKC1BhY2thZ2VUeXBlEhwKGFBBQ0tBR0VfVFlQRV9VTlNQRUNJRklFRBAAEgoK
BkJJTkFSWRABEgoKBlNPVVJDRRACOpAB6kGMAQorYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVh
cGlzLmNvbS9BcHRBcnRpZmFjdBJdcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L3JlcG9zaXRvcmllcy97cmVwb3NpdG9yeX0vYXB0QXJ0aWZhY3RzL3thcHRfYXJ0
aWZhY3R9IlYKG0ltcG9ydEFwdEFydGlmYWN0c0djc1NvdXJjZRISCgR1cmlzGAEgAygJUgR1
cmlzEiMKDXVzZV93aWxkY2FyZHMYAiABKAhSDHVzZVdpbGRjYXJkcyKlAQoZSW1wb3J0QXB0
QXJ0aWZhY3RzUmVxdWVzdBJmCgpnY3Nfc291cmNlGAIgASgLMkUuZ29vZ2xlLmRldnRvb2xz
LmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5JbXBvcnRBcHRBcnRpZmFjdHNHY3NTb3VyY2VI
AFIJZ2NzU291cmNlEhYKBnBhcmVudBgBIAEoCVIGcGFyZW50QggKBnNvdXJjZSK5AQobSW1w
b3J0QXB0QXJ0aWZhY3RzRXJyb3JJbmZvEmYKCmdjc19zb3VyY2UYASABKAsyRS5nb29nbGUu
ZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkltcG9ydEFwdEFydGlmYWN0c0dj
c1NvdXJjZUgAUglnY3NTb3VyY2USKAoFZXJyb3IYAiABKAsyEi5nb29nbGUucnBjLlN0YXR1
c1IFZXJyb3JCCAoGc291cmNlItcBChpJbXBvcnRBcHRBcnRpZmFjdHNSZXNwb25zZRJaCg1h
cHRfYXJ0aWZhY3RzGAEgAygLMjUuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnku
djFiZXRhMi5BcHRBcnRpZmFjdFIMYXB0QXJ0aWZhY3RzEl0KBmVycm9ycxgCIAMoCzJFLmdv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuSW1wb3J0QXB0QXJ0aWZh
Y3RzRXJyb3JJbmZvUgZlcnJvcnMiHAoaSW1wb3J0QXB0QXJ0aWZhY3RzTWV0YWRhdGFClAIK
LGNvbS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyQhBBcHRBcnRp
ZmFjdFByb3RvUAFaVWNsb3VkLmdvb2dsZS5jb20vZ28vYXJ0aWZhY3RyZWdpc3RyeS9hcGl2
MWJldGEyL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiVHb29nbGUu
Q2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMUJldGEyygIlR29vZ2xlXENsb3VkXEFydGlmYWN0
UmVnaXN0cnlcVjFiZXRhMuoCKEdvb2dsZTo6Q2xvdWQ6OkFydGlmYWN0UmVnaXN0cnk6OlYx
YmV0YTJKwRwKBhIEDgByAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAAMQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAIQoICgEIEgMWAEIKCQoC
CCUSAxYAQgoICgEIEgMXAGwKCQoCCAsSAxcAbAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZADEKCQoCCAgSAxkAMQoICgEIEgMaAEUKCQoCCAESAxoARQoICgEIEgMbAEIKCQoCCCkS
AxsAQgoICgEIEgMcAEEKCQoCCC0SAxwAQQrHAQoCBAASBCEARAEaugEgQSBkZXRhaWxlZCBy
ZXByZXNlbnRhdGlvbiBvZiBhbiBBcHQgYXJ0aWZhY3QuIEluZm9ybWF0aW9uIGluIHRoZSBy
ZWNvcmQKIGlzIGRlcml2ZWQgZnJvbSB0aGUgYXJjaGl2ZSdzIGNvbnRyb2wgZmlsZS4KIFNl
ZSBodHRwczovL3d3dy5kZWJpYW4ub3JnL2RvYy9kZWJpYW4tcG9saWN5L2NoLWNvbnRyb2xm
aWVsZHMuaHRtbAoKCgoDBAABEgMhCBMKCwoDBAAHEgQiAiUECg0KBQQAB50IEgQiAiUECjgK
BAQABAASBCgCMQMaKiBQYWNrYWdlIHR5cGUgaXMgZWl0aGVyIGJpbmFyeSBvciBzb3VyY2Uu
CgoMCgUEAAQAARIDKAcSCi8KBgQABAACABIDKgQhGiAgUGFja2FnZSB0eXBlIGlzIG5vdCBz
cGVjaWZpZWQuCgoOCgcEAAQAAgABEgMqBBwKDgoHBAAEAAIAAhIDKh8gCiAKBgQABAACARID
LQQPGhEgQmluYXJ5IHBhY2thZ2UuCgoOCgcEAAQAAgEBEgMtBAoKDgoHBAAEAAIBAhIDLQ0O
CiAKBgQABAACAhIDMAQPGhEgU291cmNlIHBhY2thZ2UuCgoOCgcEAAQAAgIBEgMwBAoKDgoH
BAAEAAICAhIDMA0OClAKBAQAAgASAzQCPhpDIE91dHB1dCBvbmx5LiBUaGUgQXJ0aWZhY3Qg
UmVnaXN0cnkgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYXJ0aWZhY3QuCgoMCgUEAAIABRIDNAII
CgwKBQQAAgABEgM0CQ0KDAoFBAACAAMSAzQQEQoMCgUEAAIACBIDNBI9Cg8KCAQAAgAInAgA
EgM0EzwKQQoEBAACARIDNwJGGjQgT3V0cHV0IG9ubHkuIFRoZSBBcHQgcGFja2FnZSBuYW1l
IG9mIHRoZSBhcnRpZmFjdC4KCgwKBQQAAgEFEgM3AggKDAoFBAACAQESAzcJFQoMCgUEAAIB
AxIDNxgZCgwKBQQAAgEIEgM3GkUKDwoIBAACAQicCAASAzcbRApGCgQEAAICEgM6AksaOSBP
dXRwdXQgb25seS4gQW4gYXJ0aWZhY3QgaXMgYSBiaW5hcnkgb3Igc291cmNlIHBhY2thZ2Uu
CgoMCgUEAAICBhIDOgINCgwKBQQAAgIBEgM6DhoKDAoFBAACAgMSAzodHgoMCgUEAAICCBID
Oh9KCg8KCAQAAgIInAgAEgM6IEkKSgoEBAACAxIDPQJGGj0gT3V0cHV0IG9ubHkuIE9wZXJh
dGluZyBzeXN0ZW0gYXJjaGl0ZWN0dXJlIG9mIHRoZSBhcnRpZmFjdC4KCgwKBQQAAgMFEgM9
AggKDAoFBAACAwESAz0JFQoMCgUEAAIDAxIDPRgZCgwKBQQAAgMIEgM9GkUKDwoIBAACAwic
CAASAz0bRApBCgQEAAIEEgNAAkMaNCBPdXRwdXQgb25seS4gUmVwb3NpdG9yeSBjb21wb25l
bnQgb2YgdGhlIGFydGlmYWN0LgoKDAoFBAACBAUSA0ACCAoMCgUEAAIEARIDQAkSCgwKBQQA
AgQDEgNAFRYKDAoFBAACBAgSA0AXQgoPCggEAAIECJwIABIDQBhBCk0KBAQAAgUSA0MCRRpA
IE91dHB1dCBvbmx5LiBDb250ZW50cyBvZiB0aGUgYXJ0aWZhY3QncyBjb250cm9sIG1ldGFk
YXRhIGZpbGUuCgoMCgUEAAIFBRIDQwIHCgwKBQQAAgUBEgNDCBQKDAoFBAACBQMSA0MXGAoM
CgUEAAIFCBIDQxlECg8KCAQAAgUInAgAEgNDGkMKUQoCBAESBEcATQEaRSBHb29nbGUgQ2xv
dWQgU3RvcmFnZSBsb2NhdGlvbiB3aGVyZSB0aGUgYXJ0aWZhY3RzIGN1cnJlbnRseSByZXNp
ZGUuCgoKCgMEAQESA0cIIwpJCgQEAQIAEgNJAhsaPCBDbG91ZCBTdG9yYWdlIHBhdGhzIFVS
SSAoZS5nLiwgZ3M6Ly9teV9idWNrZXQvL215X29iamVjdCkuCgoMCgUEAQIABBIDSQIKCgwK
BQQBAgAFEgNJCxEKDAoFBAECAAESA0kSFgoMCgUEAQIAAxIDSRkaClYKBAQBAgESA0wCGRpJ
IFN1cHBvcnRzIFVSSSB3aWxkY2FyZHMgZm9yIG1hdGNoaW5nIG11bHRpcGxlIG9iamVjdHMg
ZnJvbSBhIHNpbmdsZSBVUkkuCgoMCgUEAQIBBRIDTAIGCgwKBQQBAgEBEgNMBxQKDAoFBAEC
AQMSA0wXGAo2CgIEAhIEUABZARoqIFRoZSByZXF1ZXN0IHRvIGltcG9ydCBuZXcgYXB0IGFy
dGlmYWN0cy4KCgoKAwQCARIDUAghCjwKBAQCCAASBFICVQMaLiBUaGUgc291cmNlIGxvY2F0
aW9uIG9mIHRoZSBwYWNrYWdlIGJpbmFyaWVzLgoKDAoFBAIIAAESA1IIDgpMCgQEAgIAEgNU
BC8aPyBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiB3aGVyZSBpbnB1dCBjb250ZW50
IGlzIGxvY2F0ZWQuCgoMCgUEAgIABhIDVAQfCgwKBQQCAgABEgNUICoKDAoFBAICAAMSA1Qt
LgpUCgQEAgIBEgNYAhQaRyBUaGUgbmFtZSBvZiB0aGUgcGFyZW50IHJlc291cmNlIHdoZXJl
IHRoZSBhcnRpZmFjdHMgd2lsbCBiZSBpbXBvcnRlZC4KCgwKBQQCAgEFEgNYAggKDAoFBAIC
AQESA1gJDwoMCgUEAgIBAxIDWBITCkoKAgQDEgRcAGUBGj4gRXJyb3IgaW5mb3JtYXRpb24g
ZXhwbGFpbmluZyB3aHkgYSBwYWNrYWdlIHdhcyBub3QgaW1wb3J0ZWQuCgoKCgMEAwESA1wI
IwoxCgQEAwgAEgReAmEDGiMgVGhlIHNvdXJjZSB0aGF0IHdhcyBub3QgaW1wb3J0ZWQuCgoM
CgUEAwgAARIDXggOCjcKBAQDAgASA2AELxoqIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGxvY2F0
aW9uIHJlcXVlc3RlZC4KCgwKBQQDAgAGEgNgBB8KDAoFBAMCAAESA2AgKgoMCgUEAwIAAxID
YC0uCikKBAQDAgESA2QCHhocIFRoZSBkZXRhaWxlZCBlcnJvciBzdGF0dXMuCgoMCgUEAwIB
BhIDZAITCgwKBQQDAgEBEgNkFBkKDAoFBAMCAQMSA2QcHQpACgIEBBIEaABuARo0IFRoZSBy
ZXNwb25zZSBtZXNzYWdlIGZyb20gaW1wb3J0aW5nIEFQVCBhcnRpZmFjdHMuCgoKCgMEBAES
A2gIIgoqCgQEBAIAEgNqAikaHSBUaGUgQXB0IGFydGlmYWN0cyBpbXBvcnRlZC4KCgwKBQQE
AgAEEgNqAgoKDAoFBAQCAAYSA2oLFgoMCgUEBAIAARIDahckCgwKBQQEAgADEgNqJygKSAoE
BAQCARIDbQIyGjsgRGV0YWlsZWQgZXJyb3IgaW5mbyBmb3IgYXJ0aWZhY3RzIHRoYXQgd2Vy
ZSBub3QgaW1wb3J0ZWQuCgoMCgUEBAIBBBIDbQIKCgwKBQQEAgEGEgNtCyYKDAoFBAQCAQES
A20nLQoMCgUEBAIBAxIDbTAxCj0KAgQFEgRxAHIBGjEgVGhlIG9wZXJhdGlvbiBtZXRhZGF0
YSBmb3IgaW1wb3J0aW5nIGFydGlmYWN0cy4KCgoKAwQFARIDcQgiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::AptArtifact::AptArtifact ===
    # Fields for AptArtifact
    # Field: name Type: 9 ()
    # Field: package_name Type: 9 ()
    # Field: package_type Type: 14 (.google.devtools.artifactregistry.v1beta2.AptArtifact.PackageType)
    # Field: architecture Type: 9 ()
    # Field: component Type: 9 ()
    # Field: control_file Type: 12 ()

# Enum: AptArtifact::PackageType
our $AptArtifact_PACKAGE_TYPE_UNSPECIFIED = 0;
our $AptArtifact_BINARY = 1;
our $AptArtifact_SOURCE = 2;

# === Message: Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsGcsSource ===
    # Fields for ImportAptArtifactsGcsSource
    # Field: uris Type: 9 ()
    # Field: use_wildcards Type: 8 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsRequest ===
    # Fields for ImportAptArtifactsRequest
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1beta2.ImportAptArtifactsGcsSource)
    # Field: parent Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsErrorInfo ===
    # Fields for ImportAptArtifactsErrorInfo
    # Field: gcs_source Type: 11 (.google.devtools.artifactregistry.v1beta2.ImportAptArtifactsGcsSource)
    # Field: error Type: 11 (.google.rpc.Status)

# === Message: Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsResponse ===
    # Fields for ImportAptArtifactsResponse
    # Field: apt_artifacts Type: 11 (.google.devtools.artifactregistry.v1beta2.AptArtifact)
    # Field: errors Type: 11 (.google.devtools.artifactregistry.v1beta2.ImportAptArtifactsErrorInfo)

# === Message: Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsMetadata ===
    # Fields for ImportAptArtifactsMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::AptArtifact - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/apt_artifact.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::AptArtifact;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::AptArtifact::AptArtifact->new({
        name => $name,
        package_name => $package_name,
        package_type => $package_type,
        architecture => $architecture,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::AptArtifact::AptArtifact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/apt_artifact.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::AptArtifact::AptArtifact

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

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::AptArtifact::PackageType>)

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

=head2 Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsGcsSource

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

=head2 Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsRequest

The request to import new apt artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsGcsSource>)

Google Cloud Storage location where input content is located.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource where the artifacts will be imported.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsErrorInfo

Error information explaining why a package was not imported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsGcsSource>)

Google Cloud Storage location requested.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The detailed error status.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsResponse

The response message from importing APT artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->apt_artifacts() >> / C<< $msg->apt_artifacts($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::AptArtifact::AptArtifact>)

The Apt artifacts imported.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsErrorInfo>)

Detailed error info for artifacts that were not imported.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsMetadata

The operation metadata for importing artifacts.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::AptArtifact::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
