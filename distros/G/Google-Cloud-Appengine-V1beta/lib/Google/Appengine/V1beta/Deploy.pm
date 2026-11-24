package Google::Appengine::V1beta::Deploy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9kZXBsb3kucHJvdG8SF2dvb2dsZS5hcHBlbmdp
bmUudjFiZXRhGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8ivwMKCkRlcGxveW1l
bnQSRAoFZmlsZXMYASADKAsyLi5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5EZXBsb3ltZW50
LkZpbGVzRW50cnlSBWZpbGVzEkQKCWNvbnRhaW5lchgCIAEoCzImLmdvb2dsZS5hcHBlbmdp
bmUudjFiZXRhLkNvbnRhaW5lckluZm9SCWNvbnRhaW5lchIyCgN6aXAYAyABKAsyIC5nb29n
bGUuYXBwZW5naW5lLnYxYmV0YS5aaXBJbmZvUgN6aXASOAoFYnVpbGQYBSABKAsyIi5nb29n
bGUuYXBwZW5naW5lLnYxYmV0YS5CdWlsZEluZm9SBWJ1aWxkEloKE2Nsb3VkX2J1aWxkX29w
dGlvbnMYBiABKAsyKi5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5DbG91ZEJ1aWxkT3B0aW9u
c1IRY2xvdWRCdWlsZE9wdGlvbnMaWwoKRmlsZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI3
CgV2YWx1ZRgCIAEoCzIhLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLkZpbGVJbmZvUgV2YWx1
ZToCOAEiYQoIRmlsZUluZm8SHQoKc291cmNlX3VybBgBIAEoCVIJc291cmNlVXJsEhkKCHNo
YTFfc3VtGAIgASgJUgdzaGExU3VtEhsKCW1pbWVfdHlwZRgDIAEoCVIIbWltZVR5cGUiJQoN
Q29udGFpbmVySW5mbxIUCgVpbWFnZRgBIAEoCVIFaW1hZ2UiMQoJQnVpbGRJbmZvEiQKDmNs
b3VkX2J1aWxkX2lkGAEgASgJUgxjbG91ZEJ1aWxkSWQiggEKEUNsb3VkQnVpbGRPcHRpb25z
EiIKDWFwcF95YW1sX3BhdGgYASABKAlSC2FwcFlhbWxQYXRoEkkKE2Nsb3VkX2J1aWxkX3Rp
bWVvdXQYAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SEWNsb3VkQnVpbGRUaW1l
b3V0IkkKB1ppcEluZm8SHQoKc291cmNlX3VybBgDIAEoCVIJc291cmNlVXJsEh8KC2ZpbGVz
X2NvdW50GAQgASgFUgpmaWxlc0NvdW50QtEBChtjb20uZ29vZ2xlLmFwcGVuZ2luZS52MWJl
dGFCC0RlcGxveVByb3RvUAFaQGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFw
aXMvYXBwZW5naW5lL3YxYmV0YTthcHBlbmdpbmWqAh1Hb29nbGUuQ2xvdWQuQXBwRW5naW5l
LlYxQmV0YcoCHUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVcVjFiZXRh6gIgR29vZ2xlOjpDbG91
ZDo6QXBwRW5naW5lOjpWMWJldGFKoSIKBhIEDgB1AQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgAoCggKAQgSAxQAOgoJCgIIJRIDFAA6
CggKAQgSAxUAVwoJCgIICxIDFQBXCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALAoJ
CgIICBIDFwAsCggKAQgSAxgANAoJCgIIARIDGAA0CggKAQgSAxkAOgoJCgIIKRIDGQA6CggK
AQgSAxoAOQoJCgIILRIDGgA5ClQKAgQAEgQdADQBGkggQ29kZSBhbmQgYXBwbGljYXRpb24g
YXJ0aWZhY3RzIHVzZWQgdG8gZGVwbG95IGEgdmVyc2lvbiB0byBBcHAgRW5naW5lLgoKCgoD
BAABEgMdCBIKuwEKBAQAAgASAyECIhqtASBNYW5pZmVzdCBvZiB0aGUgZmlsZXMgc3RvcmVk
IGluIEdvb2dsZSBDbG91ZCBTdG9yYWdlIHRoYXQgYXJlIGluY2x1ZGVkCiBhcyBwYXJ0IG9m
IHRoaXMgdmVyc2lvbi4gQWxsIGZpbGVzIG11c3QgYmUgcmVhZGFibGUgdXNpbmcgdGhlCiBj
cmVkZW50aWFscyBzdXBwbGllZCB3aXRoIHRoaXMgY2FsbC4KCgwKBQQAAgAGEgMhAhcKDAoF
BAACAAESAyEYHQoMCgUEAAIAAxIDISAhCpgBCgQEAAIBEgMlAh4aigEgVGhlIERvY2tlciBp
bWFnZSBmb3IgdGhlIGNvbnRhaW5lciB0aGF0IHJ1bnMgdGhlIHZlcnNpb24uCiBPbmx5IGFw
cGxpY2FibGUgZm9yIGluc3RhbmNlcyBydW5uaW5nIGluIHRoZSBBcHAgRW5naW5lIGZsZXhp
YmxlIGVudmlyb25tZW50LgoKDAoFBAACAQYSAyUCDwoMCgUEAAIBARIDJRAZCgwKBQQAAgED
EgMlHB0KTQoEBAACAhIDKAISGkAgVGhlIHppcCBmaWxlIGZvciB0aGlzIGRlcGxveW1lbnQs
IGlmIHRoaXMgaXMgYSB6aXAgZGVwbG95bWVudC4KCgwKBQQAAgIGEgMoAgkKDAoFBAACAgES
AygKDQoMCgUEAAICAxIDKBARCoMBCgQEAAIDEgMsAhYadiBHb29nbGUgQ2xvdWQgQnVpbGQg
YnVpbGQgaW5mb3JtYXRpb24uIE9ubHkgYXBwbGljYWJsZSBmb3IgaW5zdGFuY2VzIHJ1bm5p
bmcKIGluIHRoZSBBcHAgRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKDAoFBAACAwYS
AywCCwoMCgUEAAIDARIDLAwRCgwKBQQAAgMDEgMsFBUK8AEKBAQAAgQSAzMCLBriASBPcHRp
b25zIGZvciBhbnkgR29vZ2xlIENsb3VkIEJ1aWxkIGJ1aWxkcyBjcmVhdGVkIGFzIGEgcGFy
dCBvZiB0aGlzCiBkZXBsb3ltZW50LgoKIFRoZXNlIG9wdGlvbnMgd2lsbCBvbmx5IGJlIHVz
ZWQgaWYgYSBuZXcgYnVpbGQgaXMgY3JlYXRlZCwgc3VjaCBhcyB3aGVuCiBkZXBsb3lpbmcg
dG8gdGhlIEFwcCBFbmdpbmUgZmxleGlibGUgZW52aXJvbm1lbnQgdXNpbmcgZmlsZXMgb3Ig
emlwLgoKDAoFBAACBAYSAzMCEwoMCgUEAAIEARIDMxQnCgwKBQQAAgQDEgMzKisKjgEKAgQB
EgQ4AEUBGoEBIFNpbmdsZSBzb3VyY2UgZmlsZSB0aGF0IGlzIHBhcnQgb2YgdGhlIHZlcnNp
b24gdG8gYmUgZGVwbG95ZWQuIEVhY2ggc291cmNlCiBmaWxlIHRoYXQgaXMgZGVwbG95ZWQg
bXVzdCBiZSBzcGVjaWZpZWQgc2VwYXJhdGVseS4KCgoKAwQBARIDOAgQCrEBCgQEAQIAEgM8
AhgaowEgVVJMIHNvdXJjZSB0byB1c2UgdG8gZmV0Y2ggdGhpcyBmaWxlLiBNdXN0IGJlIGEg
VVJMIHRvIGEgcmVzb3VyY2UgaW4KIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGluIHRoZSBmb3Jt
CiAnaHR0cChzKTovL3N0b3JhZ2UuZ29vZ2xlYXBpcy5jb20vXDxidWNrZXRcPi9cPG9iamVj
dFw+Jy4KCgwKBQQBAgAFEgM8AggKDAoFBAECAAESAzwJEwoMCgUEAQIAAxIDPBYXCjEKBAQB
AgESAz8CFhokIFRoZSBTSEExIGhhc2ggb2YgdGhlIGZpbGUsIGluIGhleC4KCgwKBQQBAgEF
EgM/AggKDAoFBAECAQESAz8JEQoMCgUEAQIBAxIDPxQVClwKBAQBAgISA0QCFxpPIFRoZSBN
SU1FIHR5cGUgb2YgdGhlIGZpbGUuCgogRGVmYXVsdHMgdG8gdGhlIHZhbHVlIGZyb20gR29v
Z2xlIENsb3VkIFN0b3JhZ2UuCgoMCgUEAQICBRIDRAIICgwKBQQBAgIBEgNECRIKDAoFBAEC
AgMSA0QVFgrHAQoCBAISBEoATwEaugEgRG9ja2VyIGltYWdlIHRoYXQgaXMgdXNlZCB0byBj
cmVhdGUgYSBjb250YWluZXIgYW5kIHN0YXJ0IGEgVk0gaW5zdGFuY2UgZm9yCiB0aGUgdmVy
c2lvbiB0aGF0IHlvdSBkZXBsb3kuIE9ubHkgYXBwbGljYWJsZSBmb3IgaW5zdGFuY2VzIHJ1
bm5pbmcgaW4gdGhlIEFwcAogRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKCgoDBAIB
EgNKCBUK2gEKBAQCAgASA04CExrMASBVUkkgdG8gdGhlIGhvc3RlZCBjb250YWluZXIgaW1h
Z2UgaW4gR29vZ2xlIENvbnRhaW5lciBSZWdpc3RyeS4gVGhlIFVSSQogbXVzdCBiZSBmdWxs
eSBxdWFsaWZpZWQgYW5kIGluY2x1ZGUgYSB0YWcgb3IgZGlnZXN0LgogRXhhbXBsZXM6ICJn
Y3IuaW8vbXktcHJvamVjdC9pbWFnZTp0YWciIG9yICJnY3IuaW8vbXktcHJvamVjdC9pbWFn
ZUBkaWdlc3QiCgoMCgUEAgIABRIDTgIICgwKBQQCAgABEgNOCQ4KDAoFBAICAAMSA04REgot
CgIEAxIEUgBWARohIEdvb2dsZSBDbG91ZCBCdWlsZCBpbmZvcm1hdGlvbi4KCgoKAwQDARID
UggRCloKBAQDAgASA1UCHBpNIFRoZSBHb29nbGUgQ2xvdWQgQnVpbGQgaWQuCiBFeGFtcGxl
OiAiZjk2NjA2OGYtMDhiMi00MmM4LWJkZmUtNzQxMzdkZmYyYmY5IgoKDAoFBAMCAAUSA1UC
CAoMCgUEAwIAARIDVQkXCgwKBQQDAgADEgNVGhsKyAEKAgQEEgRbAGgBGrsBIE9wdGlvbnMg
Zm9yIHRoZSBidWlsZCBvcGVyYXRpb25zIHBlcmZvcm1lZCBhcyBhIHBhcnQgb2YgdGhlIHZl
cnNpb24KIGRlcGxveW1lbnQuIE9ubHkgYXBwbGljYWJsZSBmb3IgQXBwIEVuZ2luZSBmbGV4
aWJsZSBlbnZpcm9ubWVudCB3aGVuIGNyZWF0aW5nCiBhIHZlcnNpb24gdXNpbmcgc291cmNl
IGNvZGUgZGlyZWN0bHkuCgoKCgMEBAESA1sIGQr2AQoEBAQCABIDYwIbGugBIFBhdGggdG8g
dGhlIHlhbWwgZmlsZSB1c2VkIGluIGRlcGxveW1lbnQsIHVzZWQgdG8gZGV0ZXJtaW5lIHJ1
bnRpbWUKIGNvbmZpZ3VyYXRpb24gZGV0YWlscy4KCiBSZXF1aXJlZCBmb3IgZmxleGlibGUg
ZW52aXJvbm1lbnQgYnVpbGRzLgoKIFNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBw
ZW5naW5lL2RvY3Mvc3RhbmRhcmQvcHl0aG9uL2NvbmZpZy9hcHByZWYKIGZvciBtb3JlIGRl
dGFpbHMuCgoMCgUEBAIABRIDYwIICgwKBQQEAgABEgNjCRYKDAoFBAQCAAMSA2MZGgqDAQoE
BAQCARIDZwIzGnYgVGhlIENsb3VkIEJ1aWxkIHRpbWVvdXQgdXNlZCBhcyBwYXJ0IG9mIGFu
eSBkZXBlbmRlbnQgYnVpbGRzIHBlcmZvcm1lZCBieQogdmVyc2lvbiBjcmVhdGlvbi4gRGVm
YXVsdHMgdG8gMTAgbWludXRlcy4KCgwKBQQEAgEGEgNnAhoKDAoFBAQCAQESA2cbLgoMCgUE
BAIBAxIDZzEyCjwKAgQFEgRrAHUBGjAgVGhlIHppcCBmaWxlIGluZm9ybWF0aW9uIGZvciBh
IHppcCBkZXBsb3ltZW50LgoKCgoDBAUBEgNrCA8KrwEKBAQFAgASA28CGBqhASBVUkwgb2Yg
dGhlIHppcCBmaWxlIHRvIGRlcGxveSBmcm9tLiBNdXN0IGJlIGEgVVJMIHRvIGEgcmVzb3Vy
Y2UgaW4KIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGluIHRoZSBmb3JtCiAnaHR0cChzKTovL3N0
b3JhZ2UuZ29vZ2xlYXBpcy5jb20vXDxidWNrZXRcPi9cPG9iamVjdFw+Jy4KCgwKBQQFAgAF
EgNvAggKDAoFBAUCAAESA28JEwoMCgUEBQIAAxIDbxYXCuIBCgQEBQIBEgN0Ahga1AEgQW4g
ZXN0aW1hdGUgb2YgdGhlIG51bWJlciBvZiBmaWxlcyBpbiBhIHppcCBmb3IgYSB6aXAgZGVw
bG95bWVudC4KIElmIHNldCwgbXVzdCBiZSBncmVhdGVyIHRoYW4gb3IgZXF1YWwgdG8gdGhl
IGFjdHVhbCBudW1iZXIgb2YgZmlsZXMuCiBVc2VkIGZvciBvcHRpbWl6aW5nIHBlcmZvcm1h
bmNlOyBpZiBub3QgcHJvdmlkZWQsIGRlcGxveW1lbnQgbWF5IGJlIHNsb3cuCgoMCgUEBQIB
BRIDdAIHCgwKBQQFAgEBEgN0CBMKDAoFBAUCAQMSA3QWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Deploy::Deployment ===
    # Fields for Deployment
    # Field: files Type: 11 (.google.appengine.v1beta.Deployment.FilesEntry)
    # Field: container Type: 11 (.google.appengine.v1beta.ContainerInfo)
    # Field: zip Type: 11 (.google.appengine.v1beta.ZipInfo)
    # Field: build Type: 11 (.google.appengine.v1beta.BuildInfo)
    # Field: cloud_build_options Type: 11 (.google.appengine.v1beta.CloudBuildOptions)

# === Message: Google::Appengine::V1beta::Deploy::FileInfo ===
    # Fields for FileInfo
    # Field: source_url Type: 9 ()
    # Field: sha1_sum Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Appengine::V1beta::Deploy::ContainerInfo ===
    # Fields for ContainerInfo
    # Field: image Type: 9 ()

# === Message: Google::Appengine::V1beta::Deploy::BuildInfo ===
    # Fields for BuildInfo
    # Field: cloud_build_id Type: 9 ()

# === Message: Google::Appengine::V1beta::Deploy::CloudBuildOptions ===
    # Fields for CloudBuildOptions
    # Field: app_yaml_path Type: 9 ()
    # Field: cloud_build_timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1beta::Deploy::ZipInfo ===
    # Fields for ZipInfo
    # Field: source_url Type: 9 ()
    # Field: files_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Deploy - Compiled Protocol Buffers messages for google/appengine/v1beta/deploy.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Deploy;

    my $msg = Google::Appengine::V1beta::Deploy::Deployment->new({
        files => $files,
        container => $container,
        zip => $zip,
        build => $build,
    });

    # Read or update a field
    my $val = $msg->files();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Deploy::Deployment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/deploy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Deploy::Deployment

Code and application artifacts used to deploy a version to App Engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Deploy::Deployment::FilesEntry>)

Manifest of the files stored in Google Cloud Storage that are included
as part of this version. All files must be readable using the
credentials supplied with this call.

=item * C<< $msg->container() >> / C<< $msg->container($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Deploy::ContainerInfo>)

The Docker image for the container that runs the version.
Only applicable for instances running in the App Engine flexible environment.

=item * C<< $msg->zip() >> / C<< $msg->zip($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Deploy::ZipInfo>)

The zip file for this deployment, if this is a zip deployment.

=item * C<< $msg->build() >> / C<< $msg->build($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Deploy::BuildInfo>)

Google Cloud Build build information. Only applicable for instances running
in the App Engine flexible environment.

=item * C<< $msg->cloud_build_options() >> / C<< $msg->cloud_build_options($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Deploy::CloudBuildOptions>)

Options for any Google Cloud Build builds created as a part of this
deployment.

These options will only be used if a new build is created, such as when
deploying to the App Engine flexible environment using files or zip.

=back

=head2 Google::Appengine::V1beta::Deploy::FileInfo

Single source file that is part of the version to be deployed. Each source
file that is deployed must be specified separately.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_url() >> / C<< $msg->source_url($value) >>

Type: C<String>

URL source to use to fetch this file. Must be a URL to a resource in
Google Cloud Storage in the form
'http(s)://storage.googleapis.com/\<bucket\>/\<object\>'.

=item * C<< $msg->sha1_sum() >> / C<< $msg->sha1_sum($value) >>

Type: C<String>

The SHA1 hash of the file, in hex.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

The MIME type of the file.

Defaults to the value from Google Cloud Storage.

=back

=head2 Google::Appengine::V1beta::Deploy::ContainerInfo

Docker image that is used to create a container and start a VM instance for
the version that you deploy. Only applicable for instances running in the App
Engine flexible environment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<String>

URI to the hosted container image in Google Container Registry. The URI
must be fully qualified and include a tag or digest.
Examples: "gcr.io/my-project/image:tag" or "gcr.io/my-project/image@digest"

=back

=head2 Google::Appengine::V1beta::Deploy::BuildInfo

Google Cloud Build information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_build_id() >> / C<< $msg->cloud_build_id($value) >>

Type: C<String>

The Google Cloud Build id.
Example: "f966068f-08b2-42c8-bdfe-74137dff2bf9"

=back

=head2 Google::Appengine::V1beta::Deploy::CloudBuildOptions

Options for the build operations performed as a part of the version
deployment. Only applicable for App Engine flexible environment when creating
a version using source code directly.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app_yaml_path() >> / C<< $msg->app_yaml_path($value) >>

Type: C<String>

Path to the yaml file used in deployment, used to determine runtime
configuration details.

Required for flexible environment builds.

See https://cloud.google.com/appengine/docs/standard/python/config/appref
for more details.

=item * C<< $msg->cloud_build_timeout() >> / C<< $msg->cloud_build_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The Cloud Build timeout used as part of any dependent builds performed by
version creation. Defaults to 10 minutes.

=back

=head2 Google::Appengine::V1beta::Deploy::ZipInfo

The zip file information for a zip deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_url() >> / C<< $msg->source_url($value) >>

Type: C<String>

URL of the zip file to deploy from. Must be a URL to a resource in
Google Cloud Storage in the form
'http(s)://storage.googleapis.com/\<bucket\>/\<object\>'.

=item * C<< $msg->files_count() >> / C<< $msg->files_count($value) >>

Type: C<Int32>

An estimate of the number of files in a zip for a zip deployment.
If set, must be greater than or equal to the actual number of files.
Used for optimizing performance; if not provided, deployment may be slow.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Deploy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
