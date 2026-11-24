package Google::Cloud::Vectorsearch::V1beta::DataObject;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxYmV0YS9kYXRhX29iamVjdC5wcm90bxIg
Z29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90b2J1
Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iggUKCkRh
dGFPYmplY3QSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEikKDmRhdGFfb2JqZWN0X2lkGAIg
ASgJQgPgQQNSDGRhdGFPYmplY3RJZBJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIwCgRkYXRh
GAYgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBUgRkYXRhElgKB3ZlY3RvcnMY
ByADKAsyOS5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YS5EYXRhT2JqZWN0LlZl
Y3RvcnNFbnRyeUID4EEBUgd2ZWN0b3JzEhcKBGV0YWcYCCABKAlCA+BBAVIEZXRhZxpkCgxW
ZWN0b3JzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSPgoFdmFsdWUYAiABKAsyKC5nb29nbGUu
Y2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YS5WZWN0b3JSBXZhbHVlOgI4ATqgAepBnAEKJnZl
Y3RvcnNlYXJjaC5nb29nbGVhcGlzLmNvbS9EYXRhT2JqZWN0Ellwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFP
YmplY3RzL3tkYXRhT2JqZWN0fSoLZGF0YU9iamVjdHMyCmRhdGFPYmplY3QixAEKBlZlY3Rv
chJFCgVkZW5zZRgCIAEoCzItLmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhLkRl
bnNlVmVjdG9ySABSBWRlbnNlEkgKBnNwYXJzZRgDIAEoCzIuLmdvb2dsZS5jbG91ZC52ZWN0
b3JzZWFyY2gudjFiZXRhLlNwYXJzZVZlY3RvckgAUgZzcGFyc2USGgoGdmFsdWVzGAEgAygC
QgIYAVIGdmFsdWVzQg0KC3ZlY3Rvcl90eXBlIioKC0RlbnNlVmVjdG9yEhsKBnZhbHVlcxgB
IAMoAkID4EECUgZ2YWx1ZXMiSgoMU3BhcnNlVmVjdG9yEhsKBnZhbHVlcxgBIAMoAkID4EEC
UgZ2YWx1ZXMSHQoHaW5kaWNlcxgCIAMoBUID4EECUgdpbmRpY2VzQu8BCiRjb20uZ29vZ2xl
LmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGFCD0RhdGFPYmplY3RQcm90b1ABWkhjbG91ZC5n
b29nbGUuY29tL2dvL3ZlY3RvcnNlYXJjaC9hcGl2MWJldGEvdmVjdG9yc2VhcmNocGI7dmVj
dG9yc2VhcmNocGKqAiBHb29nbGUuQ2xvdWQuVmVjdG9yU2VhcmNoLlYxQmV0YcoCIEdvb2ds
ZVxDbG91ZFxWZWN0b3JTZWFyY2hcVjFiZXRh6gIjR29vZ2xlOjpDbG91ZDo6VmVjdG9yU2Vh
cmNoOjpWMWJldGFKuxcKBhIEDgBhAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAKQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgIDAxID
FQApCggKAQgSAxcAPQoJCgIIJRIDFwA9CggKAQgSAxgAXwoJCgIICxIDGABfCggKAQgSAxkA
IgoJCgIIChIDGQAiCggKAQgSAxoAMAoJCgIICBIDGgAwCggKAQgSAxsAPQoJCgIIARIDGwA9
CggKAQgSAxwAPQoJCgIIKRIDHAA9CggKAQgSAx0APAoJCgIILRIDHQA8CjUKAgQAEgQgAEMB
GikgQSBkYXRhT2JqZWN0IHJlc291cmNlIGluIFZlY3RvciBTZWFyY2guCgoKCgMEAAESAyAI
EgoLCgMEAAcSBCECJgQKDQoFBAAHnQgSBCECJgQKrwIKBAQAAgASAy4CPRqhAiBJZGVudGlm
aWVyLiBUaGUgZnVsbHkgcXVhbGlmaWVkIHJlc291cmNlIG5hbWUgb2YgdGhlIGRhdGFPYmpl
Y3QuCgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YU9iamVjdHMve2RhdGFfb2JqZWN0X2lk
fWAKIFRoZSBkYXRhX29iamVjdF9pZCBtdXN0IGJlIDEtNjMgY2hhcmFjdGVycwogbG9uZywg
YW5kIGNvbXBseSB3aXRoIFtSRkMxMDM1XShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMvcmZj
MTAzNS50eHQpLgoKDAoFBAACAAUSAy4CCAoMCgUEAAIAARIDLgkNCgwKBQQAAgADEgMuEBEK
DAoFBAACAAgSAy4SPAoPCggEAAIACJwIABIDLhM7CjUKBAQAAgESAzECSBooIE91dHB1dCBv
bmx5LiBUaGUgaWQgb2YgdGhlIGRhdGFPYmplY3QuCgoMCgUEAAIBBRIDMQIICgwKBQQAAgEB
EgMxCRcKDAoFBAACAQMSAzEaGwoMCgUEAAIBCBIDMRxHCg8KCAQAAgEInAgAEgMxHUYKRQoE
BAACAhIENAI1Mho3IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgdGhlIGRhdGFPYmplY3Qgd2Fz
IGNyZWF0ZWQgYXQuCgoMCgUEAAICBhIDNAIbCgwKBQQAAgIBEgM0HCcKDAoFBAACAgMSAzQq
KwoMCgUEAAICCBIDNQYxCg8KCAQAAgIInAgAEgM1BzAKRwoEBAACAxIEOAI5Mho5IE91dHB1
dCBvbmx5LiBUaW1lc3RhbXAgdGhlIGRhdGFPYmplY3Qgd2FzIGxhc3QgdXBkYXRlZC4KCgwK
BQQAAgMGEgM4AhsKDAoFBAACAwESAzgcJwoMCgUEAAIDAxIDOCorCgwKBQQAAgMIEgM5BjEK
DwoIBAACAwicCAASAzkHMAo0CgQEAAIEEgM8AksaJyBPcHRpb25hbC4gVGhlIGRhdGEgb2Yg
dGhlIGRhdGFPYmplY3QuCgoMCgUEAAIEBhIDPAIYCgwKBQQAAgQBEgM8GR0KDAoFBAACBAMS
AzwgIQoMCgUEAAIECBIDPCJKCg8KCAQAAgQInAgAEgM8I0kKNwoEBAACBRIDPwJLGiogT3B0
aW9uYWwuIFRoZSB2ZWN0b3JzIG9mIHRoZSBkYXRhT2JqZWN0LgoKDAoFBAACBQYSAz8CFQoM
CgUEAAIFARIDPxYdCgwKBQQAAgUDEgM/ICEKDAoFBAACBQgSAz8iSgoPCggEAAIFCJwIABID
PyNJCjQKBAQAAgYSA0ICOxonIE9wdGlvbmFsLiBUaGUgZXRhZyBvZiB0aGUgZGF0YU9iamVj
dC4KCgwKBQQAAgYFEgNCAggKDAoFBAACBgESA0IJDQoMCgUEAAIGAxIDQhARCgwKBQQAAgYI
EgNCEjoKDwoIBAACBgicCAASA0ITOQo7CgIEARIERgBSARovIEEgdmVjdG9yIHdoaWNoIGNh
biBiZSBlaXRoZXIgZGVuc2Ugb3Igc3BhcnNlLgoKCgoDBAEBEgNGCA4KJwoEBAEIABIESAJO
AxoZIFRoZSB0eXBlIG9mIHRoZSB2ZWN0b3IuCgoMCgUEAQgAARIDSAgTCh4KBAQBAgASA0oE
GhoRIEEgZGVuc2UgdmVjdG9yLgoKDAoFBAECAAYSA0oEDwoMCgUEAQIAARIDShAVCgwKBQQB
AgADEgNKGBkKHwoEBAECARIDTQQcGhIgQSBzcGFyc2UgdmVjdG9yLgoKDAoFBAECAQYSA00E
EAoMCgUEAQIBARIDTREXCgwKBQQBAgEDEgNNGhsKOwoEBAECAhIDUQIwGi4gRGVwcmVjYXRl
ZDogVXNlIGBkZW5zZWAgb3IgYHNwYXJzZWAgaW5zdGVhZC4KCgwKBQQBAgIEEgNRAgoKDAoF
BAECAgUSA1ELEAoMCgUEAQICARIDUREXCgwKBQQBAgIDEgNRGhsKDAoFBAECAggSA1EcLwoN
CgYEAQICCAMSA1EdLgodCgIEAhIEVQBYARoRIEEgZGVuc2UgdmVjdG9yLgoKCgoDBAIBEgNV
CBMKMgoEBAICABIDVwJFGiUgUmVxdWlyZWQuIFRoZSB2YWx1ZXMgb2YgdGhlIHZlY3Rvci4K
CgwKBQQCAgAEEgNXAgoKDAoFBAICAAUSA1cLEAoMCgUEAgIAARIDVxEXCgwKBQQCAgADEgNX
GhsKDAoFBAICAAgSA1ccRAoPCggEAgIACJwIABIDVx1DCh4KAgQDEgRbAGEBGhIgQSBzcGFy
c2UgdmVjdG9yLgoKCgoDBAMBEgNbCBQKMgoEBAMCABIDXQJFGiUgUmVxdWlyZWQuIFRoZSB2
YWx1ZXMgb2YgdGhlIHZlY3Rvci4KCgwKBQQDAgAEEgNdAgoKDAoFBAMCAAUSA10LEAoMCgUE
AwIAARIDXREXCgwKBQQDAgADEgNdGhsKDAoFBAMCAAgSA10cRAoPCggEAwIACJwIABIDXR1D
CkIKBAQDAgESA2ACRho1IFJlcXVpcmVkLiBUaGUgY29ycmVzcG9uZGluZyBpbmRpY2VzIGZv
ciB0aGUgdmFsdWVzLgoKDAoFBAMCAQQSA2ACCgoMCgUEAwIBBRIDYAsQCgwKBQQDAgEBEgNg
ERgKDAoFBAMCAQMSA2AbHAoMCgUEAwIBCBIDYB1FCg8KCAQDAgEInAgAEgNgHkRiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject ===
    # Fields for DataObject
    # Field: name Type: 9 ()
    # Field: data_object_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data Type: 11 (.google.protobuf.Struct)
    # Field: vectors Type: 11 (.google.cloud.vectorsearch.v1beta.DataObject.VectorsEntry)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObject::Vector ===
    # Fields for Vector
    # Field: dense Type: 11 (.google.cloud.vectorsearch.v1beta.DenseVector)
    # Field: sparse Type: 11 (.google.cloud.vectorsearch.v1beta.SparseVector)
    # Field: values Type: 2 ()

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObject::DenseVector ===
    # Fields for DenseVector
    # Field: values Type: 2 ()

# === Message: Google::Cloud::Vectorsearch::V1beta::DataObject::SparseVector ===
    # Fields for SparseVector
    # Field: values Type: 2 ()
    # Field: indices Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::DataObject - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1beta/data_object.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1beta::DataObject;

    my $msg = Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject->new({
        name => $name,
        data_object_id => $data_object_id,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1beta/data_object.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject

A dataObject resource in Vector Search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The fully qualified resource name of the dataObject.

Format:
`projects/{project}/locations/{location}/collections/{collection}/dataObjects/{data_object_id}`
The data_object_id must be 1-63 characters
long, and comply with [RFC1035](https://www.ietf.org/rfc/rfc1035.txt).

=item * C<< $msg->data_object_id() >> / C<< $msg->data_object_id($value) >>

Type: C<String>

Output only. The id of the dataObject.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the dataObject was created at.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the dataObject was last updated.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The data of the dataObject.

=item * C<< $msg->vectors() >> / C<< $msg->vectors($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject::VectorsEntry>)

Optional. The vectors of the dataObject.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag of the dataObject.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObject::Vector

A vector which can be either dense or sparse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dense() >> / C<< $msg->dense($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObject::DenseVector>)

A dense vector.

=item * C<< $msg->sparse() >> / C<< $msg->sparse($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1beta::DataObject::SparseVector>)

A sparse vector.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Float>

Deprecated: Use `dense` or `sparse` instead.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObject::DenseVector

A dense vector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Float>

Required. The values of the vector.

=back

=head2 Google::Cloud::Vectorsearch::V1beta::DataObject::SparseVector

A sparse vector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Float>

Required. The values of the vector.

=item * C<< $msg->indices() >> / C<< $msg->indices($value) >>

Type: C<Int32>

Required. The corresponding indices for the values.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1beta::DataObject::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
