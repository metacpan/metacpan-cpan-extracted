package Google::Devtools::Artifactregistry::V1beta2::File;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL2ZpbGUucHJvdG8S
KGdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIaGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipQEKBEhh
c2gSSwoEdHlwZRgBIAEoDjI3Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYx
YmV0YTIuSGFzaC5IYXNoVHlwZVIEdHlwZRIUCgV2YWx1ZRgCIAEoDFIFdmFsdWUiOgoISGFz
aFR5cGUSGQoVSEFTSF9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGU0hBMjU2EAESBwoDTUQ1EAIi
jAMKBEZpbGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIdCgpzaXplX2J5dGVzGAMgASgDUglzaXpl
Qnl0ZXMSRgoGaGFzaGVzGAQgAygLMi4uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0
cnkudjFiZXRhMi5IYXNoUgZoYXNoZXMSOwoLY3JlYXRlX3RpbWUYBSABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAYgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZRIUCgVvd25lchgHIAEoCVIF
b3duZXI6eepBdgokYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9GaWxlEk5wcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBv
c2l0b3J5fS9maWxlcy97ZmlsZX0ifgoQTGlzdEZpbGVzUmVxdWVzdBIWCgZwYXJlbnQYASAB
KAlSBnBhcmVudBIWCgZmaWx0ZXIYBCABKAlSBmZpbHRlchIbCglwYWdlX3NpemUYAiABKAVS
CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKBAQoRTGlzdEZpbGVz
UmVzcG9uc2USRAoFZmlsZXMYASADKAsyLi5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdp
c3RyeS52MWJldGEyLkZpbGVSBWZpbGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiIkCg5HZXRGaWxlUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lQo0CCixj
b20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMkIJRmlsZVByb3Rv
UAFaVWNsb3VkLmdvb2dsZS5jb20vZ28vYXJ0aWZhY3RyZWdpc3RyeS9hcGl2MWJldGEyL2Fy
dGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiVHb29nbGUuQ2xvdWQuQXJ0
aWZhY3RSZWdpc3RyeS5WMUJldGEyygIlR29vZ2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlc
VjFiZXRhMuoCKEdvb2dsZTo6Q2xvdWQ6OkFydGlmYWN0UmVnaXN0cnk6OlYxYmV0YTJK7xsK
BhIEDgB3AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJ
CgIDABIDEgAjCgkKAgMBEgMTACkKCAoBCBIDFQBCCgkKAgglEgMVAEIKCAoBCBIDFgBsCgkK
AggLEgMWAGwKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAqCgkKAggIEgMYACoKCAoB
CBIDGQBFCgkKAggBEgMZAEUKCAoBCBIDGgBCCgkKAggpEgMaAEIKCAoBCBIDGwBBCgkKAggt
EgMbAEEKJQoCBAASBB4AMAEaGSBBIGhhc2ggb2YgZmlsZSBjb250ZW50LgoKCgoDBAABEgMe
CAwKNwoEBAAEABIEIAIpAxopIFRoZSBhbGdvcml0aG0gdXNlZCB0byBjb21wdXRlIHRoZSBo
YXNoLgoKDAoFBAAEAAESAyAHDwodCgYEAAQAAgASAyIEHhoOIFVuc3BlY2lmaWVkLgoKDgoH
BAAEAAIAARIDIgQZCg4KBwQABAACAAISAyIcHQodCgYEAAQAAgESAyUEDxoOIFNIQTI1NiBo
YXNoLgoKDgoHBAAEAAIBARIDJQQKCg4KBwQABAACAQISAyUNDgoaCgYEAAQAAgISAygEDBoL
IE1ENSBoYXNoLgoKDgoHBAAEAAICARIDKAQHCg4KBwQABAACAgISAygKCwo8CgQEAAIAEgMs
AhQaLyBUaGUgYWxnb3JpdGhtIHVzZWQgdG8gY29tcHV0ZSB0aGUgaGFzaCB2YWx1ZS4KCgwK
BQQAAgAGEgMsAgoKDAoFBAACAAESAywLDwoMCgUEAAIAAxIDLBITCh4KBAQAAgESAy8CEhoR
IFRoZSBoYXNoIHZhbHVlLgoKDAoFBAACAQUSAy8CBwoMCgUEAAIBARIDLwgNCgwKBQQAAgED
EgMvEBEKWwoCBAESBDMATAEaTyBGaWxlcyBzdG9yZSBjb250ZW50IHRoYXQgaXMgcG90ZW50
aWFsbHkgYXNzb2NpYXRlZCB3aXRoIFBhY2thZ2VzIG9yIFZlcnNpb25zLgoKCgoDBAEBEgMz
CAwKCwoDBAEHEgQ0AjcECg0KBQQBB50IEgQ0AjcECrgBCgQEAQIAEgM8AhIaqgEgVGhlIG5h
bWUgb2YgdGhlIGZpbGUsIGZvciBleGFtcGxlOgogInByb2plY3RzL3AxL2xvY2F0aW9ucy91
cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMvcmVwbzEvZmlsZXMvYSUyRmIlMkZjLnR4dCIuCiBJ
ZiB0aGUgZmlsZSBJRCBwYXJ0IGNvbnRhaW5zIHNsYXNoZXMsIHRoZXkgYXJlIGVzY2FwZWQu
CgoMCgUEAQIABRIDPAIICgwKBQQBAgABEgM8CQ0KDAoFBAECAAMSAzwQEQotCgQEAQIBEgM/
AhcaICBUaGUgc2l6ZSBvZiB0aGUgRmlsZSBpbiBieXRlcy4KCgwKBQQBAgEFEgM/AgcKDAoF
BAECAQESAz8IEgoMCgUEAQIBAxIDPxUWCi4KBAQBAgISA0ICGxohIFRoZSBoYXNoZXMgb2Yg
dGhlIGZpbGUgY29udGVudC4KCgwKBQQBAgIEEgNCAgoKDAoFBAECAgYSA0ILDwoMCgUEAQIC
ARIDQhAWCgwKBQQBAgIDEgNCGRoKMgoEBAECAxIDRQIsGiUgVGhlIHRpbWUgd2hlbiB0aGUg
RmlsZSB3YXMgY3JlYXRlZC4KCgwKBQQBAgMGEgNFAhsKDAoFBAECAwESA0UcJwoMCgUEAQID
AxIDRSorCjcKBAQBAgQSA0gCLBoqIFRoZSB0aW1lIHdoZW4gdGhlIEZpbGUgd2FzIGxhc3Qg
dXBkYXRlZC4KCgwKBQQBAgQGEgNIAhsKDAoFBAECBAESA0gcJwoMCgUEAQIEAxIDSCorCk4K
BAQBAgUSA0sCExpBIFRoZSBuYW1lIG9mIHRoZSBQYWNrYWdlIG9yIFZlcnNpb24gdGhhdCBv
d25zIHRoaXMgZmlsZSwgaWYgYW55LgoKDAoFBAECBQUSA0sCCAoMCgUEAQIFARIDSwkOCgwK
BQQBAgUDEgNLERIKKAoCBAISBE8AZwEaHCBUaGUgcmVxdWVzdCB0byBsaXN0IGZpbGVzLgoK
CgoDBAIBEgNPCBgKiQEKBAQCAgASA1ICFBp8IFRoZSBuYW1lIG9mIHRoZSByZXBvc2l0b3J5
IHdob3NlIGZpbGVzIHdpbGwgYmUgbGlzdGVkLiBGb3IgZXhhbXBsZToKICJwcm9qZWN0cy9w
MS9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcmVwb3NpdG9yaWVzL3JlcG8xCgoMCgUEAgIABRID
UgIICgwKBQQCAgABEgNSCQ8KDAoFBAICAAMSA1ISEwrlAwoEBAICARIDYAIUGtcDIEFuIGV4
cHJlc3Npb24gZm9yIGZpbHRlcmluZyB0aGUgcmVzdWx0cyBvZiB0aGUgcmVxdWVzdC4gRmls
dGVyIHJ1bGVzIGFyZQogY2FzZSBpbnNlbnNpdGl2ZS4gVGhlIGZpZWxkcyBlbGlnaWJsZSBm
b3IgZmlsdGVyaW5nIGFyZToKCiAgICogYG5hbWVgCiAgICogYG93bmVyYAoKICBBbiBleGFt
cGxlIG9mIHVzaW5nIGEgZmlsdGVyOgoKICAgKiBgbmFtZT0icHJvamVjdHMvcDEvbG9jYXRp
b25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBvMS9maWxlcy9hL2IvKiJgIC0tPiBG
aWxlcyB3aXRoIGFuCiAgIElEIHN0YXJ0aW5nIHdpdGggImEvYi8iLgogICAqIGBvd25lcj0i
cHJvamVjdHMvcDEvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBvMS9w
YWNrYWdlcy9wa2cxL3ZlcnNpb25zLzEuMCJgIC0tPgogICBGaWxlcyBvd25lZCBieSB0aGUg
dmVyc2lvbiBgMS4wYCBpbiBwYWNrYWdlIGBwa2cxYC4KCgwKBQQCAgEFEgNgAggKDAoFBAIC
AQESA2AJDwoMCgUEAgIBAxIDYBITCjUKBAQCAgISA2MCFhooIFRoZSBtYXhpbXVtIG51bWJl
ciBvZiBmaWxlcyB0byByZXR1cm4uCgoMCgUEAgICBRIDYwIHCgwKBQQCAgIBEgNjCBEKDAoF
BAICAgMSA2MUFQpXCgQEAgIDEgNmAhgaSiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJl
dHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QsIGlmIGFueS4KCgwKBQQCAgMF
EgNmAggKDAoFBAICAwESA2YJEwoMCgUEAgIDAxIDZhYXCi4KAgQDEgRqAHEBGiIgVGhlIHJl
c3BvbnNlIGZyb20gbGlzdGluZyBmaWxlcy4KCgoKAwQDARIDaggZCiIKBAQDAgASA2wCGhoV
IFRoZSBmaWxlcyByZXR1cm5lZC4KCgwKBQQDAgAEEgNsAgoKDAoFBAMCAAYSA2wLDwoMCgUE
AwIAARIDbBAVCgwKBQQDAgADEgNsGBkKbAoEBAMCARIDcAIdGl8gVGhlIHRva2VuIHRvIHJl
dHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgZmlsZXMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBu
bwogbW9yZSBmaWxlcyB0byByZXR1cm4uCgoMCgUEAwIBBRIDcAIICgwKBQQDAgEBEgNwCRgK
DAoFBAMCAQMSA3AbHAotCgIEBBIEdAB3ARohIFRoZSByZXF1ZXN0IHRvIHJldHJpZXZlIGEg
ZmlsZS4KCgoKAwQEARIDdAgWCjAKBAQEAgASA3YCEhojIFRoZSBuYW1lIG9mIHRoZSBmaWxl
IHRvIHJldHJpZXZlLgoKDAoFBAQCAAUSA3YCCAoMCgUEBAIAARIDdgkNCgwKBQQEAgADEgN2
EBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::File::Hash ===
    # Fields for Hash
    # Field: type Type: 14 (.google.devtools.artifactregistry.v1beta2.Hash.HashType)
    # Field: value Type: 12 ()

# Enum: Hash::HashType
our $Hash_HASH_TYPE_UNSPECIFIED = 0;
our $Hash_SHA256 = 1;
our $Hash_MD5 = 2;

# === Message: Google::Devtools::Artifactregistry::V1beta2::File::File ===
    # Fields for File
    # Field: name Type: 9 ()
    # Field: size_bytes Type: 3 ()
    # Field: hashes Type: 11 (.google.devtools.artifactregistry.v1beta2.Hash)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: owner Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::File::ListFilesRequest ===
    # Fields for ListFilesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::File::ListFilesResponse ===
    # Fields for ListFilesResponse
    # Field: files Type: 11 (.google.devtools.artifactregistry.v1beta2.File)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::File::GetFileRequest ===
    # Fields for GetFileRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::File - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/file.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::File;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::File::Hash->new({
        type => $type,
        value => $value,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::File::Hash->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::File::Hash

A hash of file content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::Hash::HashType>)

The algorithm used to compute the hash value.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Bytes>

The hash value.

=back

=head3 Enum: Hash::HashType

=over 4

=item * C<HASH_TYPE_UNSPECIFIED> => C<0>

=item * C<SHA256> => C<1>

=item * C<MD5> => C<2>

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::File::File

Files store content that is potentially associated with Packages or Versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the file, for example:
"projects/p1/locations/us-central1/repositories/repo1/files/a%2Fb%2Fc.txt".
If the file ID part contains slashes, they are escaped.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

The size of the File in bytes.

=item * C<< $msg->hashes() >> / C<< $msg->hashes($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::File::Hash>)

The hashes of the file content.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the File was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the File was last updated.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

The name of the Package or Version that owns this file, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::File::ListFilesRequest

The request to list files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the repository whose files will be listed. For example:
"projects/p1/locations/us-central1/repositories/repo1

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An expression for filtering the results of the request. Filter rules are
case insensitive. The fields eligible for filtering are:

  * `name`
  * `owner`

 An example of using a filter:

  * `name="projects/p1/locations/us-central1/repositories/repo1/files/a/b/*"` --> Files with an
  ID starting with "a/b/".
  * `owner="projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/versions/1.0"` -->
  Files owned by the version `1.0` in package `pkg1`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of files to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::File::ListFilesResponse

The response from listing files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::File::File>)

The files returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of files, or empty if there are no
more files to return.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::File::GetFileRequest

The request to retrieve a file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the file to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
