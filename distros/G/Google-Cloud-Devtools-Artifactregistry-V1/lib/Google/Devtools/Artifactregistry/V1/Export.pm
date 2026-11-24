package Google::Devtools::Artifactregistry::V1::Export;

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
    eval { require Google::Devtools::Artifactregistry::V1::File };
    eval { require Google::Devtools::Artifactregistry::V1::Version };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9leHBvcnQucHJvdG8SI2dv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvZGV2dG9v
bHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9maWxlLnByb3RvGjFnb29nbGUvZGV2dG9vbHMvYXJ0
aWZhY3RyZWdpc3RyeS92MS92ZXJzaW9uLnByb3RvIswCChVFeHBvcnRBcnRpZmFjdFJlcXVl
c3QSVQoOc291cmNlX3ZlcnNpb24YAiABKAlCLPpBKQonYXJ0aWZhY3RyZWdpc3RyeS5nb29n
bGVhcGlzLmNvbS9WZXJzaW9uSABSDXNvdXJjZVZlcnNpb24SSQoKc291cmNlX3RhZxgEIAEo
CUIo+kElCiNhcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1RhZ0gAUglzb3VyY2VU
YWcSGwoIZ2NzX3BhdGgYAyABKAlIAVIHZ2NzUGF0aBJSCgpyZXBvc2l0b3J5GAEgASgJQjLg
QQL6QSwKKmFydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vUmVwb3NpdG9yeVIKcmVw
b3NpdG9yeUIRCg9zb3VyY2VfYXJ0aWZhY3RCDQoLZGVzdGluYXRpb24icQoWRXhwb3J0QXJ0
aWZhY3RSZXNwb25zZRJXChBleHBvcnRlZF92ZXJzaW9uGAEgASgLMiwuZ29vZ2xlLmRldnRv
b2xzLmFydGlmYWN0cmVnaXN0cnkudjEuVmVyc2lvblIPZXhwb3J0ZWRWZXJzaW9uItUCChZF
eHBvcnRBcnRpZmFjdE1ldGFkYXRhEm8KDmV4cG9ydGVkX2ZpbGVzGAEgAygLMkguZ29vZ2xl
LmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEuRXhwb3J0QXJ0aWZhY3RNZXRhZGF0YS5F
eHBvcnRlZEZpbGVSDWV4cG9ydGVkRmlsZXMayQEKDEV4cG9ydGVkRmlsZRIoCg9nY3Nfb2Jq
ZWN0X3BhdGgYAiABKAlIAFINZ2NzT2JqZWN0UGF0aBI9CgRuYW1lGAEgASgJQin6QSYKJGFy
dGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vRmlsZVIEbmFtZRJBCgZoYXNoZXMYAyAD
KAsyKS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5IYXNoUgZoYXNoZXNC
DQoLZGVzdGluYXRpb25C9gEKJ2NvbS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3Ry
eS52MUILRXhwb3J0UHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJlZ2lz
dHJ5L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiBHb29n
bGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRpZmFjdFJl
Z2lzdHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFK1hcKBhIE
DgBiAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOAoJCgIDAxIDFQA7CggKAQgSAxcAPQoJCgII
JRIDFwA9CggKAQgSAxgAZwoJCgIICxIDGABnCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgS
AxoALAoJCgIICBIDGgAsCggKAQgSAxsAQAoJCgIIARIDGwBACggKAQgSAxwAPQoJCgIIKRID
HAA9CggKAQgSAx0APAoJCgIILRIDHQA8CkUKAgQAEgQgAEIBGjkgVGhlIHJlcXVlc3QgZm9y
IGV4cG9ydGluZyBhbiBhcnRpZmFjdCB0byBhIGRlc3RpbmF0aW9uLgoKCgoDBAABEgMgCB0K
LAoEBAAIABIEIgIvAxoeIFRoZSBhcnRpZmFjdCB0byBiZSBleHBvcnRlZC4KCgwKBQQACAAB
EgMiCBcKogEKBAQAAgASBCYEKAcakwEgVGhlIGFydGlmYWN0IHZlcnNpb24gdG8gZXhwb3J0
LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
cG9zaXRvcmllcy97cmVwb3NpdG9yeX0vcGFja2FnZXMve3BhY2thZ2V9L3ZlcnNpb25zL3t2
ZXJzaW9ufQoKDAoFBAACAAUSAyYECgoMCgUEAAIAARIDJgsZCgwKBQQAAgADEgMmHB0KDQoF
BAACAAgSBCYeKAYKDwoHBAACAAifCBIEJh8oBQqUAQoEBAACARIELAQuBxqFASBUaGUgYXJ0
aWZhY3QgdGFnIHRvIGV4cG9ydC4KIEZvcm1hdDpwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBvc2l0b3J5fS9wYWNrYWdlcy97cGFj
a2FnZX0vdGFncy97dGFnfQoKDAoFBAACAQUSAywECgoMCgUEAAIBARIDLAsVCgwKBQQAAgED
EgMsGBkKDQoFBAACAQgSBCwaLgYKDwoHBAACAQifCBIELBsuBQo6CgQEAAgBEgQyAjgDGiwg
VGhlIGRlc3RpbmF0aW9uIHRvIGV4cG9ydCB0aGUgYXJ0aWZhY3QgdG8uCgoMCgUEAAgBARID
MggTCvQBCgQEAAICEgM3BBga5gEgVGhlIENsb3VkIFN0b3JhZ2UgcGF0aCB0byBleHBvcnQg
dGhlIGFydGlmYWN0IHRvLiBTaG91bGQgc3RhcnQgd2l0aCB0aGUKIGJ1Y2tldCBuYW1lLCBh
bmQgb3B0aW9uYWxseSBoYXZlIGEgZGlyZWN0b3J5IHBhdGguIEV4YW1wbGVzOgogYGRzdF9i
dWNrZXRgLCBgZHN0X2J1Y2tldC9zdWJfZGlyYC4KIEV4aXN0aW5nIG9iamVjdHMgd2l0aCB0
aGUgc2FtZSBwYXRoIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoMCgUEAAICBRIDNwQKCgwKBQQA
AgIBEgM3CxMKDAoFBAACAgMSAzcWFwqPAQoEBAACAxIEPAJBBBqAASBSZXF1aXJlZC4gVGhl
IHJlcG9zaXRvcnkgb2YgdGhlIGFydGlmYWN0IHRvIGV4cG9ydC4KIEZvcm1hdDogcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmllcy97cmVwb3Np
dG9yeX0KCgwKBQQAAgMFEgM8AggKDAoFBAACAwESAzwJEwoMCgUEAAIDAxIDPBYXCg0KBQQA
AgMIEgQ8GEEDCg8KCAQAAgMInAgAEgM9BCoKDwoHBAACAwifCBIEPgRABQpGCgIEARIERQBJ
ARo6IFRoZSByZXNwb25zZSBmb3IgZXhwb3J0aW5nIGFuIGFydGlmYWN0IHRvIGEgZGVzdGlu
YXRpb24uCgoKCgMEAQESA0UIHgpvCgQEAQIAEgNIAh8aYiBUaGUgZXhwb3J0ZWQgdmVyc2lv
bi4gU2hvdWxkIGJlIHRoZSBzYW1lIGFzIHRoZSByZXF1ZXN0IHZlcnNpb24gd2l0aAogZmlu
Z2VycHJpbnQgcmVzb3VyY2UgbmFtZS4KCgwKBQQBAgAGEgNIAgkKDAoFBAECAAESA0gKGgoM
CgUEAQIAAxIDSB0eCjkKAgQCEgRMAGIBGi0gVGhlIExSTyBtZXRhZGF0YSBmb3IgZXhwb3J0
aW5nIGFuIGFydGlmYWN0LgoKCgoDBAIBEgNMCB4KKwoEBAIDABIETgJeAxodIFRoZSBleHBv
cnRlZCBhcnRpZmFjdCBmaWxlLgoKDAoFBAIDAAESA04KFgo7CgYEAgMACAASBFAEVAUaKyBU
aGUgZGVzdGluYXRpb24gdGhlIGZpbGUgd2FzIGV4cG9ydGVkIHRvLgoKDgoHBAIDAAgAARID
UAoVCnoKBgQCAwACABIDUwYhGmsgQ2xvdWQgU3RvcmFnZSBPYmplY3QgcGF0aCBvZiB0aGUg
ZXhwb3J0ZWQgZmlsZS4gRXhhbXBsZXM6CiBgZHN0X2J1Y2tldC9maWxlMWAsIGBkc3RfYnVj
a2V0L3N1Yl9kaXIvZmlsZTFgCgoOCgcEAgMAAgAFEgNTBgwKDgoHBAIDAAIAARIDUw0cCg4K
BwQCAwACAAMSA1MfIAp4CgYEAgMAAgESBFgEWgcaaCBOYW1lIG9mIHRoZSBleHBvcnRlZCBh
cnRpZmFjdCBmaWxlLgogRm9ybWF0OiBgcHJvamVjdHMvcDEvbG9jYXRpb25zL3VzL3JlcG9z
aXRvcmllcy9yZXBvMS9maWxlcy9maWxlMWAKCg4KBwQCAwACAQUSA1gECgoOCgcEAgMAAgEB
EgNYCw8KDgoHBAIDAAIBAxIDWBITCg8KBwQCAwACAQgSBFgUWgYKEQoJBAIDAAIBCJ8IEgRY
FVoFCjAKBgQCAwACAhIDXQQdGiEgVGhlIGhhc2hlcyBvZiB0aGUgZmlsZSBjb250ZW50LgoK
DgoHBAIDAAICBBIDXQQMCg4KBwQCAwACAgYSA10NEQoOCgcEAgMAAgIBEgNdEhgKDgoHBAID
AAICAxIDXRscCisKBAQCAgASA2ECKxoeIFRoZSBleHBvcnRlZCBhcnRpZmFjdCBmaWxlcy4K
CgwKBQQCAgAEEgNhAgoKDAoFBAICAAYSA2ELFwoMCgUEAgIAARIDYRgmCgwKBQQCAgADEgNh
KSpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest ===
    # Fields for ExportArtifactRequest
    # Field: source_version Type: 9 ()
    # Field: source_tag Type: 9 ()
    # Field: gcs_path Type: 9 ()
    # Field: repository Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Export::ExportArtifactResponse ===
    # Fields for ExportArtifactResponse
    # Field: exported_version Type: 11 (.google.devtools.artifactregistry.v1.Version)

# === Message: Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata ===
    # Fields for ExportArtifactMetadata
    # Field: exported_files Type: 11 (.google.devtools.artifactregistry.v1.ExportArtifactMetadata.ExportedFile)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Export - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/export.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Export;

    my $msg = Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest->new({
        source_version => $source_version,
        source_tag => $source_tag,
        gcs_path => $gcs_path,
        repository => $repository,
    });

    # Read or update a field
    my $val = $msg->source_version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest

The request for exporting an artifact to a destination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_version() >> / C<< $msg->source_version($value) >>

Type: C<String>

The artifact version to export.
Format:
projects/{project}/locations/{location}/repositories/{repository}/packages/{package}/versions/{version}

=item * C<< $msg->source_tag() >> / C<< $msg->source_tag($value) >>

Type: C<String>

The artifact tag to export.
Format:projects/{project}/locations/{location}/repositories/{repository}/packages/{package}/tags/{tag}

=item * C<< $msg->gcs_path() >> / C<< $msg->gcs_path($value) >>

Type: C<String>

The Cloud Storage path to export the artifact to. Should start with the
bucket name, and optionally have a directory path. Examples:
`dst_bucket`, `dst_bucket/sub_dir`.
Existing objects with the same path will be overwritten.

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<String>

Required. The repository of the artifact to export.
Format: projects/{project}/locations/{location}/repositories/{repository}

=back

=head2 Google::Devtools::Artifactregistry::V1::Export::ExportArtifactResponse

The response for exporting an artifact to a destination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exported_version() >> / C<< $msg->exported_version($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Version::Version>)

The exported version. Should be the same as the request version with
fingerprint resource name.

=back

=head2 Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata

The LRO metadata for exporting an artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exported_files() >> / C<< $msg->exported_files($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata::ExportedFile>)

The exported artifact files.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Export::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
