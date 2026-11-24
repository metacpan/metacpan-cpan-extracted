package Google::Devtools::Artifactregistry::V1beta2::Version;

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
    eval { require Google::Devtools::Artifactregistry::V1beta2::Tag };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3ZlcnNpb24ucHJv
dG8SKGdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdv
b2dsZS9kZXZ0b29scy9hcnRpZmFjdHJlZ2lzdHJ5L3YxYmV0YTIvdGFnLnByb3RvGhxnb29n
bGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvIt4DCgdWZXJzaW9uEhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAyAB
KAlSC2Rlc2NyaXB0aW9uEjsKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSUAoMcmVsYXRlZF90YWdzGAcgAygLMi0u
Z29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5UYWdSC3JlbGF0ZWRU
YWdzEjgKCG1ldGFkYXRhGAggASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEDUght
ZXRhZGF0YTqWAepBkgEKJ2FydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vVmVyc2lv
bhJncHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmll
cy97cmVwb3NpdG9yeX0vcGFja2FnZXMve3BhY2thZ2V9L3ZlcnNpb25zL3t2ZXJzaW9ufSLU
AQoTTGlzdFZlcnNpb25zUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglwYWdl
X3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhJJ
CgR2aWV3GAQgASgOMjUuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRh
Mi5WZXJzaW9uVmlld1IEdmlldxIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5Io0B
ChRMaXN0VmVyc2lvbnNSZXNwb25zZRJNCgh2ZXJzaW9ucxgBIAMoCzIxLmdvb2dsZS5kZXZ0
b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuVmVyc2lvblIIdmVyc2lvbnMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuInIKEUdldFZlcnNpb25SZXF1ZXN0
EhIKBG5hbWUYASABKAlSBG5hbWUSSQoEdmlldxgCIAEoDjI1Lmdvb2dsZS5kZXZ0b29scy5h
cnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuVmVyc2lvblZpZXdSBHZpZXciQAoURGVsZXRlVmVy
c2lvblJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIUCgVmb3JjZRgCIAEoCFIFZm9yY2Uq
QAoLVmVyc2lvblZpZXcSHAoYVkVSU0lPTl9WSUVXX1VOU1BFQ0lGSUVEEAASCQoFQkFTSUMQ
ARIICgRGVUxMEAJCkAIKLGNvbS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52
MWJldGEyQgxWZXJzaW9uUHJvdG9QAVpVY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJl
Z2lzdHJ5L2FwaXYxYmV0YTIvYXJ0aWZhY3RyZWdpc3RyeXBiO2FydGlmYWN0cmVnaXN0cnlw
YqoCJUdvb2dsZS5DbG91ZC5BcnRpZmFjdFJlZ2lzdHJ5LlYxQmV0YTLKAiVHb29nbGVcQ2xv
dWRcQXJ0aWZhY3RSZWdpc3RyeVxWMWJldGEy6gIoR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RS
ZWdpc3RyeTo6VjFiZXRhMkq3IAoGEgQOAH4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAxCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA8CgkK
AgMDEgMVACYKCQoCAwQSAxYAKQoICgEIEgMYAEIKCQoCCCUSAxgAQgoICgEIEgMZAGwKCQoC
CAsSAxkAbAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC0KCQoCCAgSAxsALQoICgEI
EgMcAEUKCQoCCAESAxwARQoICgEIEgMdAEIKCQoCCCkSAx0AQgoICgEIEgMeAEEKCQoCCC0S
Ax4AQQpdCgIFABIEIgAsARpRIFRoZSB2aWV3LCB3aGljaCBkZXRlcm1pbmVzIHdoYXQgdmVy
c2lvbiBpbmZvcm1hdGlvbiBpcyByZXR1cm5lZCBpbiBhCiByZXNwb25zZS4KCgoKAwUAARID
IgUQClIKBAUAAgASAyUCHxpFIFRoZSBkZWZhdWx0IC8gdW5zZXQgdmFsdWUuCiBUaGUgQVBJ
IHdpbGwgZGVmYXVsdCB0byB0aGUgQkFTSUMgdmlldy4KCgwKBQUAAgABEgMlAhoKDAoFBQAC
AAISAyUdHgpWCgQFAAIBEgMoAgwaSSBJbmNsdWRlcyBiYXNpYyBpbmZvcm1hdGlvbiBhYm91
dCB0aGUgdmVyc2lvbiwgYnV0IG5vdCBhbnkgcmVsYXRlZCB0YWdzLgoKDAoFBQACAQESAygC
BwoMCgUFAAIBAhIDKAoLCiIKBAUAAgISAysCCxoVIEluY2x1ZGUgZXZlcnl0aGluZy4KCgwK
BQUAAgIBEgMrAgYKDAoFBQACAgISAysJCgrNAQoCBAASBDEATwEawAEgVGhlIGJvZHkgb2Yg
YSB2ZXJzaW9uIHJlc291cmNlLiBBIHZlcnNpb24gcmVzb3VyY2UgcmVwcmVzZW50cyBhCiBj
b2xsZWN0aW9uIG9mIGNvbXBvbmVudHMsIHN1Y2ggYXMgZmlsZXMgYW5kIG90aGVyIGRhdGEu
IFRoaXMgbWF5IGNvcnJlc3BvbmQKIHRvIGEgdmVyc2lvbiBpbiBtYW55IHBhY2thZ2UgbWFu
YWdlbWVudCBzY2hlbWVzLgoKCgoDBAABEgMxCA8KCwoDBAAHEgQyAjUECg0KBQQAB50IEgQy
AjUECtkBCgQEAAIAEgM7AhIaywEgVGhlIG5hbWUgb2YgdGhlIHZlcnNpb24sIGZvciBleGFt
cGxlOgogInByb2plY3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMv
cmVwbzEvcGFja2FnZXMvcGtnMS92ZXJzaW9ucy9hcnQxIi4KIElmIHRoZSBwYWNrYWdlIG9y
IHZlcnNpb24gSUQgcGFydHMgY29udGFpbiBzbGFzaGVzLCB0aGUgc2xhc2hlcyBhcmUKIGVz
Y2FwZWQuCgoMCgUEAAIABRIDOwIICgwKBQQAAgABEgM7CQ0KDAoFBAACAAMSAzsQEQpSCgQE
AAIBEgM+AhkaRSBPcHRpb25hbC4gRGVzY3JpcHRpb24gb2YgdGhlIHZlcnNpb24sIGFzIHNw
ZWNpZmllZCBpbiBpdHMgbWV0YWRhdGEuCgoMCgUEAAIBBRIDPgIICgwKBQQAAgEBEgM+CRQK
DAoFBAACAQMSAz4XGAo1CgQEAAICEgNBAiwaKCBUaGUgdGltZSB3aGVuIHRoZSB2ZXJzaW9u
IHdhcyBjcmVhdGVkLgoKDAoFBAACAgYSA0ECGwoMCgUEAAICARIDQRwnCgwKBQQAAgIDEgNB
KisKOgoEBAACAxIDRAIsGi0gVGhlIHRpbWUgd2hlbiB0aGUgdmVyc2lvbiB3YXMgbGFzdCB1
cGRhdGVkLgoKDAoFBAACAwYSA0QCGwoMCgUEAAIDARIDRBwnCgwKBQQAAgMDEgNEKisKbQoE
BAACBBIDSAIgGmAgT3V0cHV0IG9ubHkuIEEgbGlzdCBvZiByZWxhdGVkIHRhZ3MuIFdpbGwg
Y29udGFpbiB1cCB0byAxMDAgdGFncyB0aGF0CiByZWZlcmVuY2UgdGhpcyB2ZXJzaW9uLgoK
DAoFBAACBAQSA0gCCgoMCgUEAAIEBhIDSAsOCgwKBQQAAgQBEgNIDxsKDAoFBAACBAMSA0ge
HwqPAgoEBAACBRIDTgJSGoECIE91dHB1dCBvbmx5LiBSZXBvc2l0b3J5LXNwZWNpZmljIE1l
dGFkYXRhIHN0b3JlZCBhZ2FpbnN0IHRoaXMgdmVyc2lvbi4KIFRoZSBmaWVsZHMgcmV0dXJu
ZWQgYXJlIGRlZmluZWQgYnkgdGhlIHVuZGVybHlpbmcgcmVwb3NpdG9yeS1zcGVjaWZpYwog
cmVzb3VyY2UuIEN1cnJlbnRseSwgdGhlIG9ubHkgcmVzb3VyY2UgaW4gdXNlIGlzCiBbRG9j
a2VySW1hZ2VdW2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLkRvY2tlcklt
YWdlXQoKDAoFBAACBQYSA04CGAoMCgUEAAIFARIDThkhCgwKBQQAAgUDEgNOJCUKDAoFBAAC
BQgSA04mUQoPCggEAAIFCJwIABIDTidQCisKAgQBEgRSAGEBGh8gVGhlIHJlcXVlc3QgdG8g
bGlzdCB2ZXJzaW9ucy4KCgoKAwQBARIDUggbCk0KBAQBAgASA1QCFBpAIFRoZSBuYW1lIG9m
IHRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hvc2UgdmVyc2lvbnMgd2lsbCBiZSBsaXN0ZWQuCgoM
CgUEAQIABRIDVAIICgwKBQQBAgABEgNUCQ8KDAoFBAECAAMSA1QSEwpUCgQEAQIBEgNXAhYa
RyBUaGUgbWF4aW11bSBudW1iZXIgb2YgdmVyc2lvbnMgdG8gcmV0dXJuLiBNYXhpbXVtIHBh
Z2Ugc2l6ZSBpcyAxLDAwMC4KCgwKBQQBAgEFEgNXAgcKDAoFBAECAQESA1cIEQoMCgUEAQIB
AxIDVxQVClcKBAQBAgISA1oCGBpKIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJu
ZWQgZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdCwgaWYgYW55LgoKDAoFBAECAgUSA1oC
CAoMCgUEAQICARIDWgkTCgwKBQQBAgIDEgNaFhcKQAoEBAECAxIDXQIXGjMgVGhlIHZpZXcg
dGhhdCBzaG91bGQgYmUgcmV0dXJuZWQgaW4gdGhlIHJlc3BvbnNlLgoKDAoFBAECAwYSA10C
DQoMCgUEAQIDARIDXQ4SCgwKBQQBAgMDEgNdFRYKOwoEBAECBBIDYAI/Gi4gT3B0aW9uYWwu
IFRoZSBmaWVsZCB0byBvcmRlciB0aGUgcmVzdWx0cyBieS4KCgwKBQQBAgQFEgNgAggKDAoF
BAECBAESA2AJEQoMCgUEAQIEAxIDYBQVCgwKBQQBAgQIEgNgFj4KDwoIBAECBAicCAASA2AX
PQoxCgIEAhIEZABrARolIFRoZSByZXNwb25zZSBmcm9tIGxpc3RpbmcgdmVyc2lvbnMuCgoK
CgMEAgESA2QIHAolCgQEAgIAEgNmAiAaGCBUaGUgdmVyc2lvbnMgcmV0dXJuZWQuCgoMCgUE
AgIABBIDZgIKCgwKBQQCAgAGEgNmCxIKDAoFBAICAAESA2YTGwoMCgUEAgIAAxIDZh4fCnIK
BAQCAgESA2oCHRplIFRoZSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHZl
cnNpb25zLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgdmVyc2lvbnMgdG8gcmV0
dXJuLgoKDAoFBAICAQUSA2oCCAoMCgUEAgIBARIDagkYCgwKBQQCAgEDEgNqGxwKMAoCBAMS
BG4AdAEaJCBUaGUgcmVxdWVzdCB0byByZXRyaWV2ZSBhIHZlcnNpb24uCgoKCgMEAwESA24I
GQozCgQEAwIAEgNwAhIaJiBUaGUgbmFtZSBvZiB0aGUgdmVyc2lvbiB0byByZXRyaWV2ZS4K
CgwKBQQDAgAFEgNwAggKDAoFBAMCAAESA3AJDQoMCgUEAwIAAxIDcBARCkAKBAQDAgESA3MC
FxozIFRoZSB2aWV3IHRoYXQgc2hvdWxkIGJlIHJldHVybmVkIGluIHRoZSByZXNwb25zZS4K
CgwKBQQDAgEGEgNzAg0KDAoFBAMCAQESA3MOEgoMCgUEAwIBAxIDcxUWCi4KAgQEEgR3AH4B
GiIgVGhlIHJlcXVlc3QgdG8gZGVsZXRlIGEgdmVyc2lvbi4KCgoKAwQEARIDdwgcCjEKBAQE
AgASA3kCEhokIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uIHRvIGRlbGV0ZS4KCgwKBQQEAgAF
EgN5AggKDAoFBAQCAAESA3kJDQoMCgUEBAIAAxIDeRARCpYBCgQEBAIBEgN9AhEaiAEgQnkg
ZGVmYXVsdCwgYSB2ZXJzaW9uIHRoYXQgaXMgdGFnZ2VkIG1heSBub3QgYmUgZGVsZXRlZC4g
SWYgZm9yY2U9dHJ1ZSwgdGhlCiB2ZXJzaW9uIGFuZCBhbnkgdGFncyBwb2ludGluZyB0byB0
aGUgdmVyc2lvbiBhcmUgZGVsZXRlZC4KCgwKBQQEAgEFEgN9AgYKDAoFBAQCAQESA30HDAoM
CgUEBAIBAxIDfQ8QYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: related_tags Type: 11 (.google.devtools.artifactregistry.v1beta2.Tag)
    # Field: metadata Type: 11 (.google.protobuf.Struct)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Version::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.devtools.artifactregistry.v1beta2.VersionView)
    # Field: order_by Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Version::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.devtools.artifactregistry.v1beta2.Version)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Version::GetVersionRequest ===
    # Fields for GetVersionRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.devtools.artifactregistry.v1beta2.VersionView)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Version::DeleteVersionRequest ===
    # Fields for DeleteVersionRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Version - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/version.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::Version;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::Version::Version->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::Version::Version->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::Version::Version

The body of a version resource. A version resource represents a
collection of components, such as files and other data. This may correspond
to a version in many package management schemes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the version, for example:
"projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/versions/art1".
If the package or version ID parts contain slashes, the slashes are
escaped.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the version, as specified in its metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the version was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the version was last updated.

=item * C<< $msg->related_tags() >> / C<< $msg->related_tags($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Tag::Tag>)

Output only. A list of related tags. Will contain up to 100 tags that
reference this version.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. Repository-specific Metadata stored against this version.
The fields returned are defined by the underlying repository-specific
resource. Currently, the only resource in use is
[DockerImage][google.devtools.artifactregistry.v1.DockerImage]

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Version::ListVersionsRequest

The request to list versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource whose versions will be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of versions to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::VersionView>)

The view that should be returned in the response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. The field to order the results by.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Version::ListVersionsResponse

The response from listing versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Version::Version>)

The versions returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of versions, or empty if there are no
more versions to return.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Version::GetVersionRequest

The request to retrieve a version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the version to retrieve.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::VersionView>)

The view that should be returned in the response.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Version::DeleteVersionRequest

The request to delete a version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the version to delete.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

By default, a version that is tagged may not be deleted. If force=true, the
version and any tags pointing to the version are deleted.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
