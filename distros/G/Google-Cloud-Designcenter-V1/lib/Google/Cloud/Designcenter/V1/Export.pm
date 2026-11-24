package Google::Cloud::Designcenter::V1::Export;

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
    eval { require Google::Cloud::Designcenter::V1::Enums };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2V4cG9ydC5wcm90bxIcZ29vZ2xlLmNs
b3VkLmRlc2lnbmNlbnRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL2Rlc2lnbmNlbnRlci92
MS9lbnVtcy5wcm90byLJAQoQQXJ0aWZhY3RMb2NhdGlvbhKIAQofZGV2ZWxvcGVyX2Nvbm5l
Y3RfZXhwb3J0X2NvbmZpZxgBIAEoCzI6Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEu
RGV2ZWxvcGVyQ29ubmVjdEV4cG9ydENvbmZpZ0ID4EEBSABSHGRldmVsb3BlckNvbm5lY3RF
eHBvcnRDb25maWcSHgoHZ2NzX3VyaRgCIAEoCUID4EEBSABSBmdjc1VyaUIKCghsb2NhdGlv
biLuAQocRGV2ZWxvcGVyQ29ubmVjdEV4cG9ydENvbmZpZxJ2ChpkZXZlbG9wZXJfY29ubmVj
dF9yZXBvX3VyaRgBIAEoCUI54EEC+kEzCjFkZXZlbG9wZXJjb25uZWN0Lmdvb2dsZWFwaXMu
Y29tL0dpdFJlcG9zaXRvcnlMaW5rUhdkZXZlbG9wZXJDb25uZWN0UmVwb1VyaRIbCgZicmFu
Y2gYAiABKAlCA+BBAVIGYnJhbmNoEhUKA2RpchgDIAEoCUID4EECUgNkaXISIgoKY29tbWl0
X3NoYRgEIAEoCUID4EEDUgljb21taXRTaGEiwwEKD0V4cG9ydElhQ0NvbmZpZxJRCgl0Zl9j
b25maWcYAiABKAsyLS5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlRlcnJhZm9ybUNv
bmZpZ0ID4EEBSABSCHRmQ29uZmlnEksKCmlhY19mb3JtYXQYASABKA4yJy5nb29nbGUuY2xv
dWQuZGVzaWduY2VudGVyLnYxLklBQ0Zvcm1hdEID4EEBUglpYWNGb3JtYXRCEAoOY29uZmln
X3BheWxvYWQidQoPVGVycmFmb3JtQ29uZmlnEmIKEHRmX21vZHVsZV9jb25maWcYASABKAsy
My5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlRlcnJhZm9ybU1vZHVsZUNvbmZpZ0ID
4EEBUg50Zk1vZHVsZUNvbmZpZyKeAQoVVGVycmFmb3JtTW9kdWxlQ29uZmlnEjEKEWdpdF9w
cm94eV9lbmFibGVkGAEgASgIQgPgQQFIAFIPZ2l0UHJveHlFbmFibGVkEj8KGGxvY2FsX3Jl
ZmVyZW5jZXNfZW5hYmxlZBgCIAEoCEID4EEBSABSFmxvY2FsUmVmZXJlbmNlc0VuYWJsZWRC
EQoPc291cmNlX292ZXJyaWRlQtcBCiBjb20uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52
MUILRXhwb3J0UHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9kZXNpZ25jZW50ZXIvYXBp
djEvZGVzaWduY2VudGVycGI7ZGVzaWduY2VudGVycGKqAhxHb29nbGUuQ2xvdWQuRGVzaWdu
Q2VudGVyLlYxygIcR29vZ2xlXENsb3VkXERlc2lnbkNlbnRlclxWMeoCH0dvb2dsZTo6Q2xv
dWQ6OkRlc2lnbkNlbnRlcjo6VjFKiiAKBhIEDgBtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQA
MgoICgEIEgMWADkKCQoCCCUSAxYAOQoICgEIEgMXAFsKCQoCCAsSAxcAWwoICgEIEgMYACIK
CQoCCAoSAxgAIgoICgEIEgMZACwKCQoCCAgSAxkALAoICgEIEgMaADkKCQoCCAESAxoAOQoI
CgEIEgMbADkKCQoCCCkSAxsAOQoICgEIEgMcADgKCQoCCC0SAxwAOApSCgIEABIEHwArARpG
IERlZmluZXMgdGhlIGxvY2F0aW9uIGZvciBzdG9yaW5nIGFuIGFydGlmYWN0LCBzdWNoIGFz
IGdlbmVyYXRlZCBJYUMuCgoKCgMEAAESAx8IGApDCgQEAAgAEgQhAioDGjUgU3BlY2lmaWVz
IHRoZSB0eXBlIG9mIGRlc3RpbmF0aW9uIGZvciB0aGUgYXJ0aWZhY3QuCgoMCgUEAAgAARID
IQgQCtkBCgQEAAIAEgQlBCYxGsoBIE9wdGlvbmFsLiBTb3VyY2UgQ29kZSBNYW5hZ2VtZW50
KFNDTSkgY29uZmlnIGZvciBzdG9yaW5nIHRoZSBjb250ZW50LAogc3VjaCBhcyBnZW5lcmF0
ZWQgSWFDLiBTdXBwb3J0cyBzb3VyY2VzIGludGVncmF0ZWQgd2l0aCBEZXZlbG9wZXIgQ29u
bmVjdAogbGlrZSBHaXRIdWIsIEdpdEh1YiBFbnRlcnByaXNlLCBHaXRMYWIsIGFuZCBCaXRi
dWNrZXQuCgoMCgUEAAIABhIDJQQgCgwKBQQAAgABEgMlIUAKDAoFBAACAAMSAyVDRAoMCgUE
AAIACBIDJggwCg8KCAQAAgAInAgAEgMmCS8KTQoEBAACARIDKQRAGkAgT3B0aW9uYWwuIFRo
ZSBDbG91ZCBTdG9yYWdlIFVSSSBmb3Igc3RvcmluZyB0aGUgZ2VuZXJhdGVkIElhQy4KCgwK
BQQAAgEFEgMpBAoKDAoFBAACAQESAykLEgoMCgUEAAIBAxIDKRUWCgwKBQQAAgEIEgMpFz8K
DwoIBAACAQicCAASAykYPgp6CgIEARIELwBHARpuIFRocm91Z2ggRGV2ZWxvcGVyIENvbm5l
Y3QsIGRlZmluZXMgYSBsb2NhdGlvbiB3aGVyZSBjb250ZW50IHN1Y2ggYXMKIEluZnJhc3Ry
dWN0dXJlIGFzIENvZGUgKElhQykgaXMgc3RvcmVkLgoKCgoDBAEBEgMvCCQKkAEKBAQBAgAS
BDICNwQagQEgUmVxdWlyZWQuIFRoZSBEZXZlbG9wZXIgQ29ubmVjdCBHaXQgcmVwb3NpdG9y
eSBsaW5rLCBmb3JtYXR0ZWQgYXMKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3Rp
b25zLyovZ2l0UmVwb3NpdG9yeUxpbmtzLypgLgoKDAoFBAECAAUSAzICCAoMCgUEAQIAARID
MgkjCgwKBQQBAgADEgMyJicKDQoFBAECAAgSBDIoNwMKDwoIBAECAAicCAASAzMEKgoPCgcE
AQIACJ8IEgQ0BDYFCs0BCgQEAQIBEgM8Aj0avwEgT3B0aW9uYWwuIFRoZSBicmFuY2ggaW4g
cmVwbyB0byB3aGljaCB0aGUgY29udGVudCBzdWNoIGFzIEluZnJhc3RydWN0dXJlIGFzCiBD
b2RlIChJYUMpIHNob3VsZCBiZSB3cml0dGVuIHRvLiBJZiBlbXB0eSwgQXBwbGljYXRpb24g
RGVzaWduIENlbnRlciB3aWxsCiBjcmVhdGUgYSBicmFuY2ggYW5kIHB1c2ggdGhlIGNoYW5n
ZXMuCgoMCgUEAQIBBRIDPAIICgwKBQQBAgEBEgM8CQ8KDAoFBAECAQMSAzwSEwoMCgUEAQIB
CBIDPBQ8Cg8KCAQBAgEInAgAEgM8FTsKkgIKBAQBAgISA0ICOhqEAiBSZXF1aXJlZC4gRGly
ZWN0b3J5LCByZWxhdGl2ZSB0byB0aGUgc291cmNlIHJlcG8sIHdoZXJlIGNvbnRlbnQgc3Vj
aCBhcwogSW5mcmFzdHJ1Y3R1cmUgYXMgQ29kZSAoSWFDKSB3aWxsIGJlIHN0b3JlZC4KIFRo
aXMgbXVzdCBiZSBhIHJlbGF0aXZlIHBhdGguVG8gc3BlY2lmeSB0aGUgcm9vdCBkaXJlY3Rv
cnksIHVzZSAnLycuCiBJZiB0aGUgcGF0aCBvciBhbnkgc3ViZGlyZWN0b3JpZXMgZG8gbm90
IGV4aXN0LCB0aGV5IHdpbGwgYmUgY3JlYXRlZC4KCgwKBQQBAgIFEgNCAggKDAoFBAECAgES
A0IJDAoMCgUEAQICAxIDQg8QCgwKBQQBAgIIEgNCETkKDwoIBAECAgicCAASA0ISOAp/CgQE
AQIDEgNGAkQaciBPdXRwdXQgb25seS4gVGhlIFNIQSBvZiB0aGUgR2l0IGNvbW1pdCB0aGF0
IGNvbnRhaW5zIHRoZSBleHBvcnRlZCBjb250ZW50CiBzdWNoIGFzIEluZnJhc3RydWN0dXJl
IGFzIENvZGUgKElhQykuCgoMCgUEAQIDBRIDRgIICgwKBQQBAgMBEgNGCRMKDAoFBAECAwMS
A0YWFwoMCgUEAQIDCBIDRhhDCg8KCAQBAgMInAgAEgNGGUIKPAoCBAISBEoAUwEaMCBDb25m
aWd1cmF0aW9uIGZvciBleHBvcnRpbmcgYSByZXNvdXJjZSBhcyBJQUMuCgoKCgMEAgESA0oI
FwpFCgQEAggAEgRMAk8DGjcgQ29uZmlndXJhdGlvbiBmb3IgdGhlIGV4cG9ydCBiYXNlZCBv
biB0aGUgSWFDIGZvcm1hdC4KCgwKBQQCCAABEgNMCBYKTQoEBAICABIDTgRLGkAgT3B0aW9u
YWwuIENvbmZpZ3VyYXRpb24gb24gaG93IHRvIGhhbmRsZSB0ZXJyYWZvcm0gSWFDIGV4cG9y
dC4KCgwKBQQCAgAGEgNOBBMKDAoFBAICAAESA04UHQoMCgUEAgIAAxIDTiAhCgwKBQQCAgAI
EgNOIkoKDwoIBAICAAicCAASA04jSQpUCgQEAgIBEgNSAkQaRyBPcHRpb25hbC4gSWFDIGZv
cm1hdCBvZiB0aGUgZXhwb3J0LiBEZWZhdWx0IGlzIFtJQUNGb3JtYXQuVEVSUkFGT1JNXS4K
CgwKBQQCAgEGEgNSAgsKDAoFBAICAQESA1IMFgoMCgUEAgIBAxIDUhkaCgwKBQQCAgEIEgNS
G0MKDwoIBAICAQicCAASA1IcQgpGCgIEAxIEVgBbARo6IENvbmZpZ3VyYXRpb24gZm9yIGV4
cG9ydGluZyBhIHJlc291cmNlIGFzIFRlcnJhZm9ybSBJQUMuCgoKCgMEAwESA1YIFwphCgQE
AwIAEgRZAlovGlMgT3B0aW9uYWwuIENvbmZpZ3VyYXRpb24gb24gaG93IHRlcnJhZm9ybSBt
b2R1bGUgc2hvdWxkIGJlIGhhbmRsZWQgZHVyaW5nCiBleHBvcnQuCgoMCgUEAwIABhIDWQIX
CgwKBQQDAgABEgNZGCgKDAoFBAMCAAMSA1krLAoMCgUEAwIACBIDWgYuCg8KCAQDAgAInAgA
EgNaBy0KVQoCBAQSBF8AbQEaSSBDb25maWd1cmF0aW9uIG9uIGhvdyB0ZXJyYWZvcm0gbW9k
dWxlIHNob3VsZCBiZSBoYW5kbGVkIGR1cmluZwogZXhwb3J0LgoKCgoDBAQBEgNfCB0KpwEK
BAQECAASBGMCbAMamAEgU3BlY2lmaWVzIGFuIG92ZXJyaWRlIGZvciB0aGUgZGVmYXVsdCBt
b2R1bGUgc291cmNlIGhhbmRsaW5nLgogSWYgbm8gb3ZlcnJpZGUgaXMgc2V0LCB0aGUgZGVm
YXVsdCBiZWhhdmlvciBpcyB0byBrZWVwIHRoZSBvcmlnaW5hbAogbW9kdWxlIHJlZmVyZW5j
ZXMuCgoMCgUEBAgAARIDYwgXCtQBCgQEBAIAEgNnBEgaxgEgT3B0aW9uYWwuIFRoaXMgaXMg
dHlwaWNhbGx5IG9ubHkgdmFsaWQgZm9yIDNQIGNvbXBvbmVudHMgaWYgaW5nZXN0ZWQgdmlh
CiBkZXZjb25uZWN0IFVSSS4gVHlwaWNhbGx5LCBmb3IgMVAgY29tcG9uZW50cywgc2luY2Ug
dGhleSBhcmUgc291cmNlZCBmcm9tCiBwdWJsaWMgZ2l0IHJlcG9zLCB0aGlzIGZpZWxkIGlz
IG5vdCBhcHBsaWNhYmxlLgoKDAoFBAQCAAUSA2cECAoMCgUEBAIAARIDZwkaCgwKBQQEAgAD
EgNnHR4KDAoFBAQCAAgSA2cfRwoPCggEBAIACJwIABIDZyBGCoEBCgQEBAIBEgNrBE8adCBP
cHRpb25hbC4gSWYgc2V0LCBhbGwgdGhlIGRlcGVuZGVudCBtb2R1bGVzIHdpbGwgYmUgZG93
bmxvYWRlZCBmcm9tIHRoZQogdGFyZ2V0IHJlcG9zaXRvcnkgYW5kIHJlZmVyZW5jZWQgbG9j
YWxseS4KCgwKBQQEAgEFEgNrBAgKDAoFBAQCAQESA2sJIQoMCgUEBAIBAxIDayQlCgwKBQQE
AgEIEgNrJk4KDwoIBAQCAQicCAASA2snTWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::Export::ArtifactLocation ===
    # Fields for ArtifactLocation
    # Field: developer_connect_export_config Type: 11 (.google.cloud.designcenter.v1.DeveloperConnectExportConfig)
    # Field: gcs_uri Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Export::DeveloperConnectExportConfig ===
    # Fields for DeveloperConnectExportConfig
    # Field: developer_connect_repo_uri Type: 9 ()
    # Field: branch Type: 9 ()
    # Field: dir Type: 9 ()
    # Field: commit_sha Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::Export::ExportIaCConfig ===
    # Fields for ExportIaCConfig
    # Field: tf_config Type: 11 (.google.cloud.designcenter.v1.TerraformConfig)
    # Field: iac_format Type: 14 (.google.cloud.designcenter.v1.IACFormat)

# === Message: Google::Cloud::Designcenter::V1::Export::TerraformConfig ===
    # Fields for TerraformConfig
    # Field: tf_module_config Type: 11 (.google.cloud.designcenter.v1.TerraformModuleConfig)

# === Message: Google::Cloud::Designcenter::V1::Export::TerraformModuleConfig ===
    # Fields for TerraformModuleConfig
    # Field: git_proxy_enabled Type: 8 ()
    # Field: local_references_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::Export - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/export.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::Export;

    my $msg = Google::Cloud::Designcenter::V1::Export::ArtifactLocation->new({
        developer_connect_export_config => $developer_connect_export_config,
        gcs_uri => $gcs_uri,
    });

    # Read or update a field
    my $val = $msg->developer_connect_export_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::Export::ArtifactLocation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::Export::ArtifactLocation

Defines the location for storing an artifact, such as generated IaC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->developer_connect_export_config() >> / C<< $msg->developer_connect_export_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Export::DeveloperConnectExportConfig>)

Optional. Source Code Management(SCM) config for storing the content,
such as generated IaC. Supports sources integrated with Developer Connect
like GitHub, GitHub Enterprise, GitLab, and Bitbucket.

=item * C<< $msg->gcs_uri() >> / C<< $msg->gcs_uri($value) >>

Type: C<String>

Optional. The Cloud Storage URI for storing the generated IaC.

=back

=head2 Google::Cloud::Designcenter::V1::Export::DeveloperConnectExportConfig

Through Developer Connect, defines a location where content such as
Infrastructure as Code (IaC) is stored.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->developer_connect_repo_uri() >> / C<< $msg->developer_connect_repo_uri($value) >>

Type: C<String>

Required. The Developer Connect Git repository link, formatted as
`projects/*/locations/*/connections/*/gitRepositoryLinks/*`.

=item * C<< $msg->branch() >> / C<< $msg->branch($value) >>

Type: C<String>

Optional. The branch in repo to which the content such as Infrastructure as
Code (IaC) should be written to. If empty, Application Design Center will
create a branch and push the changes.

=item * C<< $msg->dir() >> / C<< $msg->dir($value) >>

Type: C<String>

Required. Directory, relative to the source repo, where content such as
Infrastructure as Code (IaC) will be stored.
This must be a relative path.To specify the root directory, use '/'.
If the path or any subdirectories do not exist, they will be created.

=item * C<< $msg->commit_sha() >> / C<< $msg->commit_sha($value) >>

Type: C<String>

Output only. The SHA of the Git commit that contains the exported content
such as Infrastructure as Code (IaC).

=back

=head2 Google::Cloud::Designcenter::V1::Export::ExportIaCConfig

Configuration for exporting a resource as IAC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tf_config() >> / C<< $msg->tf_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Export::TerraformConfig>)

Optional. Configuration on how to handle terraform IaC export.

=item * C<< $msg->iac_format() >> / C<< $msg->iac_format($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::IACFormat>)

Optional. IaC format of the export. Default is [IACFormat.TERRAFORM].

=back

=head2 Google::Cloud::Designcenter::V1::Export::TerraformConfig

Configuration for exporting a resource as Terraform IAC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tf_module_config() >> / C<< $msg->tf_module_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Export::TerraformModuleConfig>)

Optional. Configuration on how terraform module should be handled during
export.

=back

=head2 Google::Cloud::Designcenter::V1::Export::TerraformModuleConfig

Configuration on how terraform module should be handled during
export.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->git_proxy_enabled() >> / C<< $msg->git_proxy_enabled($value) >>

Type: C<Bool>

Optional. This is typically only valid for 3P components if ingested via
devconnect URI. Typically, for 1P components, since they are sourced from
public git repos, this field is not applicable.

=item * C<< $msg->local_references_enabled() >> / C<< $msg->local_references_enabled($value) >>

Type: C<Bool>

Optional. If set, all the dependent modules will be downloaded from the
target repository and referenced locally.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::Export::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
