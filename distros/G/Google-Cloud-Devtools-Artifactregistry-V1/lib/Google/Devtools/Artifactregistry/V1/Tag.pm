package Google::Devtools::Artifactregistry::V1::Tag;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS90YWcucHJvdG8SI2dvb2ds
ZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byLAAQoDVGFnEhIKBG5hbWUY
ASABKAlSBG5hbWUSGAoHdmVyc2lvbhgCIAEoCVIHdmVyc2lvbjqKAepBhgEKI2FydGlmYWN0
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vVGFnEl9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBvc2l0b3J5fS9wYWNrYWdlcy97cGFj
a2FnZX0vdGFncy97dGFnfSJ9Cg9MaXN0VGFnc1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZw
YXJlbnQSFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXISGwoJcGFnZV9zaXplGAIgASgFUghwYWdl
U2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4ieAoQTGlzdFRhZ3NSZXNwb25z
ZRI8CgR0YWdzGAEgAygLMiguZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEu
VGFnUgR0YWdzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiIjCg1H
ZXRUYWdSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUifQoQQ3JlYXRlVGFnUmVxdWVzdBIW
CgZwYXJlbnQYASABKAlSBnBhcmVudBIVCgZ0YWdfaWQYAiABKAlSBXRhZ0lkEjoKA3RhZxgD
IAEoCzIoLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLlRhZ1IDdGFnIosB
ChBVcGRhdGVUYWdSZXF1ZXN0EjoKA3RhZxgBIAEoCzIoLmdvb2dsZS5kZXZ0b29scy5hcnRp
ZmFjdHJlZ2lzdHJ5LnYxLlRhZ1IDdGFnEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayImChBEZWxldGVUYWdSZXF1ZXN0EhIK
BG5hbWUYASABKAlSBG5hbWVC8wEKJ2NvbS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdp
c3RyeS52MUIIVGFnUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJlZ2lz
dHJ5L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiBHb29n
bGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRpZmFjdFJl
Z2lzdHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFK4CQKBxIF
DgCJAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoC
AwASAxIAIwoJCgIDARIDEwAqCggKAQgSAxUAPQoJCgIIJRIDFQA9CggKAQgSAxYAZwoJCgII
CxIDFgBnCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAKQoJCgIICBIDGAApCggKAQgS
AxkAQAoJCgIIARIDGQBACggKAQgSAxoAPQoJCgIIKRIDGgA9CggKAQgSAxsAPAoJCgIILRID
GwA8CnAKAgQAEgQfADEBGmQgVGFncyBwb2ludCB0byBhIHZlcnNpb24gYW5kIHJlcHJlc2Vu
dCBhbiBhbHRlcm5hdGl2ZSBuYW1lIHRoYXQgY2FuIGJlIHVzZWQKIHRvIGFjY2VzcyB0aGUg
dmVyc2lvbi4KCgoKAwQAARIDHwgLCgsKAwQABxIEIAIjBAoNCgUEAAedCBIEIAIjBAqkAgoE
BAACABIDKgISGpYCIFRoZSBuYW1lIG9mIHRoZSB0YWcsIGZvciBleGFtcGxlOgogInByb2pl
Y3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMvcmVwbzEvcGFja2Fn
ZXMvcGtnMS90YWdzL3RhZzEiLgogSWYgdGhlIHBhY2thZ2UgcGFydCBjb250YWlucyBzbGFz
aGVzLCB0aGUgc2xhc2hlcyBhcmUgZXNjYXBlZC4KIFRoZSB0YWcgcGFydCBjYW4gb25seSBo
YXZlIGNoYXJhY3RlcnMgaW4gW2EtekEtWjAtOVwtLl9+OkBdLCBhbnl0aGluZyBlbHNlCiBt
dXN0IGJlIFVSTCBlbmNvZGVkLgoKDAoFBAACAAUSAyoCCAoMCgUEAAIAARIDKgkNCgwKBQQA
AgADEgMqEBEK9AEKBAQAAgESAzACFRrmASBUaGUgbmFtZSBvZiB0aGUgdmVyc2lvbiB0aGUg
dGFnIHJlZmVycyB0bywgZm9yIGV4YW1wbGU6CiBgcHJvamVjdHMvcDEvbG9jYXRpb25zL3Vz
LWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBvMS9wYWNrYWdlcy9wa2cxL3ZlcnNpb25zL3No
YTI1Njo1MjQzODExYAogSWYgdGhlIHBhY2thZ2Ugb3IgdmVyc2lvbiBJRCBwYXJ0cyBjb250
YWluIHNsYXNoZXMsIHRoZSBzbGFzaGVzIGFyZQogZXNjYXBlZC4KCgwKBQQAAgEFEgMwAggK
DAoFBAACAQESAzAJEAoMCgUEAAIBAxIDMBMUCicKAgQBEgQ0AFwBGhsgVGhlIHJlcXVlc3Qg
dG8gbGlzdCB0YWdzLgoKCgoDBAEBEgM0CBcKngEKBAQBAgASAzgCFBqQASBUaGUgbmFtZSBv
ZiB0aGUgcGFyZW50IHBhY2thZ2Ugd2hvc2UgdGFncyB3aWxsIGJlIGxpc3RlZC4KIEZvciBl
eGFtcGxlOgogYHByb2plY3RzL3AxL2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3Jp
ZXMvcmVwbzEvcGFja2FnZXMvcGtnMWAuCgoMCgUEAQIABRIDOAIICgwKBQQBAgABEgM4CQ8K
DAoFBAECAAMSAzgSEwrXCQoEBAECARIDVQIUGskJIEFuIGV4cHJlc3Npb24gZm9yIGZpbHRl
cmluZyB0aGUgcmVzdWx0cyBvZiB0aGUgcmVxdWVzdC4gRmlsdGVyIHJ1bGVzIGFyZQogY2Fz
ZSBpbnNlbnNpdGl2ZS4gVGhlIGZpZWxkcyBlbGlnaWJsZSBmb3IgZmlsdGVyaW5nIGFyZToK
CiAgICogYG5hbWVgCiAgICogYHZlcnNpb25gCgogIEV4YW1wbGVzIG9mIHVzaW5nIGEgZmls
dGVyOgoKICBUbyBmaWx0ZXIgdGhlIHJlc3VsdHMgb2YgeW91ciByZXF1ZXN0IHRvIHRhZ3Mg
d2l0aCB0aGUgbmFtZSBgbXktdGFnYCBpbgogIHBhY2thZ2UgYG15LXBhY2thZ2VgIGluIHJl
cG9zaXRvcnkgYG15LXJlcG9gIGluIHByb2plY3QgImB5LXByb2plY3RgIGluCiAgdGhlIHVz
LWNlbnRyYWwgcmVnaW9uLCBhcHBlbmQgdGhlIGZvbGxvd2luZyBmaWx0ZXIgZXhwcmVzc2lv
biB0byB5b3VyCiAgcmVxdWVzdDoKCiAgICogYG5hbWU9InByb2plY3RzL215LXByb2plY3Qv
bG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9teS1yZXBvL3BhY2thZ2VzL215
LXBhY2thZ2UvdGFncy9teS10YWciYAoKICBZb3UgY2FuIGFsc28gdXNlIHdpbGRjYXJkcyB0
byBtYXRjaCBhbnkgbnVtYmVyIG9mIGNoYXJhY3RlcnMgYmVmb3JlIG9yCiAgYWZ0ZXIgdGhl
IHZhbHVlOgoKICAgKiBgbmFtZT0icHJvamVjdHMvbXktcHJvamVjdC9sb2NhdGlvbnMvdXMt
Y2VudHJhbDEvcmVwb3NpdG9yaWVzL215LXJlcG8vcGFja2FnZXMvbXktcGFja2FnZS90YWdz
L215KiJgCiAgICogYG5hbWU9InByb2plY3RzL215LXByb2plY3QvbG9jYXRpb25zL3VzLWNl
bnRyYWwxL3JlcG9zaXRvcmllcy9teS1yZXBvL3BhY2thZ2VzL215LXBhY2thZ2UvdGFncy8q
dGFnImAKICAgKiBgbmFtZT0icHJvamVjdHMvbXktcHJvamVjdC9sb2NhdGlvbnMvdXMtY2Vu
dHJhbDEvcmVwb3NpdG9yaWVzL215LXJlcG8vcGFja2FnZXMvbXktcGFja2FnZS90YWdzLyp0
YWcqImAKCiAgVG8gZmlsdGVyIHRoZSByZXN1bHRzIG9mIHlvdXIgcmVxdWVzdCB0byB0YWdz
IGFwcGxpZWQgdG8gdGhlIHZlcnNpb24KICBgMS4wYCBpbiBwYWNrYWdlIGBteS1wYWNrYWdl
YCwgYXBwZW5kIHRoZSBmb2xsb3dpbmcgZmlsdGVyIGV4cHJlc3Npb24gdG8KICB5b3VyIHJl
cXVlc3Q6CgogICAqIGB2ZXJzaW9uPSJwcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9ucy91
cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMvbXktcmVwby9wYWNrYWdlcy9teS1wYWNrYWdlL3Zl
cnNpb25zLzEuMCJgCgoMCgUEAQIBBRIDVQIICgwKBQQBAgEBEgNVCQ8KDAoFBAECAQMSA1US
EwpQCgQEAQICEgNYAhYaQyBUaGUgbWF4aW11bSBudW1iZXIgb2YgdGFncyB0byByZXR1cm4u
IE1heGltdW0gcGFnZSBzaXplIGlzIDEsMDAwLgoKDAoFBAECAgUSA1gCBwoMCgUEAQICARID
WAgRCgwKBQQBAgIDEgNYFBUKVwoEBAECAxIDWwIYGkogVGhlIG5leHRfcGFnZV90b2tlbiB2
YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBhbnkuCgoM
CgUEAQIDBRIDWwIICgwKBQQBAgMBEgNbCRMKDAoFBAECAwMSA1sWFwotCgIEAhIEXwBmARoh
IFRoZSByZXNwb25zZSBmcm9tIGxpc3RpbmcgdGFncy4KCgoKAwQCARIDXwgYCiEKBAQCAgAS
A2ECGBoUIFRoZSB0YWdzIHJldHVybmVkLgoKDAoFBAICAAQSA2ECCgoMCgUEAgIABhIDYQsO
CgwKBQQCAgABEgNhDxMKDAoFBAICAAMSA2EWFwpqCgQEAgIBEgNlAh0aXSBUaGUgdG9rZW4g
dG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiB0YWdzLCBvciBlbXB0eSBpZiB0aGVyZSBh
cmUgbm8KIG1vcmUgdGFncyB0byByZXR1cm4uCgoMCgUEAgIBBRIDZQIICgwKBQQCAgEBEgNl
CRgKDAoFBAICAQMSA2UbHAosCgIEAxIEaQBsARogIFRoZSByZXF1ZXN0IHRvIHJldHJpZXZl
IGEgdGFnLgoKCgoDBAMBEgNpCBUKLwoEBAMCABIDawISGiIgVGhlIG5hbWUgb2YgdGhlIHRh
ZyB0byByZXRyaWV2ZS4KCgwKBQQDAgAFEgNrAggKDAoFBAMCAAESA2sJDQoMCgUEAwIAAxID
axARCi4KAgQEEgRvAHgBGiIgVGhlIHJlcXVlc3QgdG8gY3JlYXRlIGEgbmV3IHRhZy4KCgoK
AwQEARIDbwgYCk0KBAQEAgASA3ECFBpAIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQgcmVzb3Vy
Y2Ugd2hlcmUgdGhlIHRhZyB3aWxsIGJlIGNyZWF0ZWQuCgoMCgUEBAIABRIDcQIICgwKBQQE
AgABEgNxCQ8KDAoFBAQCAAMSA3ESEwo1CgQEBAIBEgN0AhQaKCBUaGUgdGFnIGlkIHRvIHVz
ZSBmb3IgdGhpcyByZXBvc2l0b3J5LgoKDAoFBAQCAQUSA3QCCAoMCgUEBAIBARIDdAkPCgwK
BQQEAgEDEgN0EhMKJQoEBAQCAhIDdwIOGhggVGhlIHRhZyB0byBiZSBjcmVhdGVkLgoKDAoF
BAQCAgYSA3cCBQoMCgUEBAICARIDdwYJCgwKBQQEAgIDEgN3DA0KNQoCBAUSBXsAgwEBGigg
VGhlIHJlcXVlc3QgdG8gY3JlYXRlIG9yIHVwZGF0ZSBhIHRhZy4KCgoKAwQFARIDewgYCkAK
BAQFAgASA30CDhozIFRoZSB0YWcgdGhhdCByZXBsYWNlcyB0aGUgcmVzb3VyY2Ugb24gdGhl
IHNlcnZlci4KCgwKBQQFAgAGEgN9AgUKDAoFBAUCAAESA30GCQoMCgUEBQIAAxIDfQwNCrcB
CgQEBQIBEgSCAQIsGqgBIFRoZSB1cGRhdGUgbWFzayBhcHBsaWVzIHRvIHRoZSByZXNvdXJj
ZS4gRm9yIHRoZSBgRmllbGRNYXNrYCBkZWZpbml0aW9uLAogc2VlCiBodHRwczovL2RldmVs
b3BlcnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2ds
ZS5wcm90b2J1ZiNmaWVsZG1hc2sKCg0KBQQFAgEGEgSCAQIbCg0KBQQFAgEBEgSCARwnCg0K
BQQFAgEDEgSCASorCiwKAgQGEgaGAQCJAQEaHiBUaGUgcmVxdWVzdCB0byBkZWxldGUgYSB0
YWcuCgoLCgMEBgESBIYBCBgKLgoEBAYCABIEiAECEhogIFRoZSBuYW1lIG9mIHRoZSB0YWcg
dG8gZGVsZXRlLgoKDQoFBAYCAAUSBIgBAggKDQoFBAYCAAESBIgBCQ0KDQoFBAYCAAMSBIgB
EBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Tag::Tag ===
    # Fields for Tag
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Tag::ListTagsRequest ===
    # Fields for ListTagsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Tag::ListTagsResponse ===
    # Fields for ListTagsResponse
    # Field: tags Type: 11 (.google.devtools.artifactregistry.v1.Tag)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Tag::GetTagRequest ===
    # Fields for GetTagRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Tag::CreateTagRequest ===
    # Fields for CreateTagRequest
    # Field: parent Type: 9 ()
    # Field: tag_id Type: 9 ()
    # Field: tag Type: 11 (.google.devtools.artifactregistry.v1.Tag)

# === Message: Google::Devtools::Artifactregistry::V1::Tag::UpdateTagRequest ===
    # Fields for UpdateTagRequest
    # Field: tag Type: 11 (.google.devtools.artifactregistry.v1.Tag)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Devtools::Artifactregistry::V1::Tag::DeleteTagRequest ===
    # Fields for DeleteTagRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Tag - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/tag.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Tag;

    my $msg = Google::Devtools::Artifactregistry::V1::Tag::Tag->new({
        name => $name,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Tag::Tag->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/tag.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Tag::Tag

Tags point to a version and represent an alternative name that can be used
to access the version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the tag, for example:
"projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/tags/tag1".
If the package part contains slashes, the slashes are escaped.
The tag part can only have characters in [a-zA-Z0-9\-._~:@], anything else
must be URL encoded.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The name of the version the tag refers to, for example:
`projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/versions/sha256:5243811`
If the package or version ID parts contain slashes, the slashes are
escaped.

=back

=head2 Google::Devtools::Artifactregistry::V1::Tag::ListTagsRequest

The request to list tags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent package whose tags will be listed.
For example:
`projects/p1/locations/us-central1/repositories/repo1/packages/pkg1`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An expression for filtering the results of the request. Filter rules are
case insensitive. The fields eligible for filtering are:

  * `name`
  * `version`

 Examples of using a filter:

 To filter the results of your request to tags with the name `my-tag` in
 package `my-package` in repository `my-repo` in project "`y-project` in
 the us-central region, append the following filter expression to your
 request:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/tags/my-tag"`

 You can also use wildcards to match any number of characters before or
 after the value:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/tags/my*"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/tags/*tag"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/tags/*tag*"`

 To filter the results of your request to tags applied to the version
 `1.0` in package `my-package`, append the following filter expression to
 your request:

  * `version="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/versions/1.0"`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of tags to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1::Tag::ListTagsResponse

The response from listing tags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Tag::Tag>)

The tags returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of tags, or empty if there are no
more tags to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Tag::GetTagRequest

The request to retrieve a tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the tag to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1::Tag::CreateTagRequest

The request to create a new tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource where the tag will be created.

=item * C<< $msg->tag_id() >> / C<< $msg->tag_id($value) >>

Type: C<String>

The tag id to use for this repository.

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Tag::Tag>)

The tag to be created.

=back

=head2 Google::Devtools::Artifactregistry::V1::Tag::UpdateTagRequest

The request to create or update a tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Tag::Tag>)

The tag that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Devtools::Artifactregistry::V1::Tag::DeleteTagRequest

The request to delete a tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the tag to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Tag::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
