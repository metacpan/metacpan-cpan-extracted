package Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2FtcGxlX3F1ZXJ5X3Nl
dC5wcm90bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrUCCg5TYW1wbGVRdWVyeVNldBIXCgRu
YW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rpc3Bs
YXlOYW1lEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgpjcmVhdGVUaW1lEiAKC2Rlc2NyaXB0aW9uGAQgASgJUgtkZXNjcmlwdGlvbjp+
6kF7Ci1kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxlUXVlcnlTZXQSSnBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zYW1wbGVRdWVyeVNldHMv
e3NhbXBsZV9xdWVyeV9zZXR9Qp8CCihjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhQhNTYW1wbGVRdWVyeVNldFByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28v
ZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5
ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5n
aW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidH
b29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFKlQ8KBhIEDgA/AQq8BAoB
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
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAGkKCQoC
CAsSAxcAaQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADQKCQoCCAgSAxkANAoICgEI
EgMaAEEKCQoCCAESAxoAQQoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEIEgMcAEEKCQoCCCkS
AxwAQQoICgEIEgMdAEAKCQoCCC0SAx0AQAqKAQoCBAASBCEAPwEafiBBIFNhbXBsZVF1ZXJ5
U2V0IGlzIHRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgU2FtcGxlUXVlcnksIGFuZCBjb250YWlu
cyB0aGUKIGNvbmZpZ3VyYXRpb25zIHNoYXJlZCBieSBhbGwgU2FtcGxlUXVlcnkgdW5kZXIg
aXQuCgoKCgMEAAESAyEIFgoLCgMEAAcSBCICJQQKDQoFBAAHnQgSBCICJQQKtwIKBAQAAgAS
Ay4CPRqpAiBJZGVudGlmaWVyLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZQogW1Nh
bXBsZVF1ZXJ5U2V0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2Ft
cGxlUXVlcnlTZXRdLCBpbgogdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9zYW1wbGVRdWVyeVNldHMve3NhbXBsZV9xdWVyeV9zZXR9
YC4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEg
bGVuZ3RoIGxpbWl0IG9mIDEwMjQKIGNoYXJhY3RlcnMuCgoMCgUEAAIABRIDLgIICgwKBQQA
AgABEgMuCQ0KDAoFBAACAAMSAy4QEQoMCgUEAAIACBIDLhI8Cg8KCAQAAgAInAgAEgMuEzsK
kAEKBAQAAgESAzQCQxqCASBSZXF1aXJlZC4gVGhlIHNhbXBsZSBxdWVyeSBzZXQgZGlzcGxh
eSBuYW1lLgoKIFRoaXMgZmllbGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdp
dGggYSBsZW5ndGggbGltaXQgb2YgMTI4CiBjaGFyYWN0ZXJzLgoKDAoFBAACAQUSAzQCCAoM
CgUEAAIBARIDNAkVCgwKBQQAAgEDEgM0GBkKDAoFBAACAQgSAzQaQgoPCggEAAIBCJwIABID
NBtBCoIBCgQEAAICEgQ5AjoyGnQgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB0aGUKIFtTYW1w
bGVRdWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBs
ZVF1ZXJ5U2V0XSB3YXMKIGNyZWF0ZWQgYXQuCgoMCgUEAAICBhIDOQIbCgwKBQQAAgIBEgM5
HCcKDAoFBAACAgMSAzkqKwoMCgUEAAICCBIDOgYxCg8KCAQAAgIInAgAEgM6BzAKbQoEBAAC
AxIDPgIZGmAgVGhlIGRlc2NyaXB0aW9uIG9mIHRoZQogW1NhbXBsZVF1ZXJ5U2V0XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnlTZXRdLgoKDAoF
BAACAwUSAz4CCAoMCgUEAAIDARIDPgkUCgwKBQQAAgMDEgM+FxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet ===
    # Fields for SampleQuerySet
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/sample_query_set.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/sample_query_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet

A SampleQuerySet is the parent resource of SampleQuery, and contains the
configurations shared by all SampleQuery under it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The full resource name of the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet], in
the format of
`projects/{project}/locations/{location}/sampleQuerySets/{sample_query_set}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The sample query set display name.

This field must be a UTF-8 encoded string with a length limit of 128
characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet] was
created at.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
