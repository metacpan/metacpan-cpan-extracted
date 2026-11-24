package Google::Cloud::Vectorsearch::V1::DataObject;

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
Ci5nb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxL2RhdGFfb2JqZWN0LnByb3RvEhxnb29n
bGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIvoECgpEYXRhT2JqZWN0
EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIpCg5kYXRhX29iamVjdF9pZBgCIAEoCUID4EED
UgxkYXRhT2JqZWN0SWQSQAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSMAoEZGF0YRgGIAEoCzIX
Lmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RCA+BBAVIEZGF0YRJUCgd2ZWN0b3JzGAcgAygLMjUu
Z29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MS5EYXRhT2JqZWN0LlZlY3RvcnNFbnRyeUID
4EEBUgd2ZWN0b3JzEhcKBGV0YWcYCCABKAlCA+BBAVIEZXRhZxpgCgxWZWN0b3JzRW50cnkS
EAoDa2V5GAEgASgJUgNrZXkSOgoFdmFsdWUYAiABKAsyJC5nb29nbGUuY2xvdWQudmVjdG9y
c2VhcmNoLnYxLlZlY3RvclIFdmFsdWU6AjgBOqAB6kGcAQomdmVjdG9yc2VhcmNoLmdvb2ds
ZWFwaXMuY29tL0RhdGFPYmplY3QSWXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YU9iamVjdHMve2RhdGFPYmpl
Y3R9KgtkYXRhT2JqZWN0czIKZGF0YU9iamVjdCKgAQoGVmVjdG9yEkEKBWRlbnNlGAIgASgL
MikuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MS5EZW5zZVZlY3RvckgAUgVkZW5zZRJE
CgZzcGFyc2UYAyABKAsyKi5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxLlNwYXJzZVZl
Y3RvckgAUgZzcGFyc2VCDQoLdmVjdG9yX3R5cGUiKgoLRGVuc2VWZWN0b3ISGwoGdmFsdWVz
GAEgAygCQgPgQQJSBnZhbHVlcyJKCgxTcGFyc2VWZWN0b3ISGwoGdmFsdWVzGAEgAygCQgPg
QQJSBnZhbHVlcxIdCgdpbmRpY2VzGAIgAygFQgPgQQJSB2luZGljZXNC2wEKIGNvbS5nb29n
bGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxQg9EYXRhT2JqZWN0UHJvdG9QAVpEY2xvdWQuZ29v
Z2xlLmNvbS9nby92ZWN0b3JzZWFyY2gvYXBpdjEvdmVjdG9yc2VhcmNocGI7dmVjdG9yc2Vh
cmNocGKqAhxHb29nbGUuQ2xvdWQuVmVjdG9yU2VhcmNoLlYxygIcR29vZ2xlXENsb3VkXFZl
Y3RvclNlYXJjaFxWMeoCH0dvb2dsZTo6Q2xvdWQ6OlZlY3RvclNlYXJjaDo6VjFKqRYKBhIE
DgBeAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgIDAxIDFQApCggKAQgSAxcAOQoJCgII
JRIDFwA5CggKAQgSAxgAWwoJCgIICxIDGABbCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgS
AxoAMAoJCgIICBIDGgAwCggKAQgSAxsAOQoJCgIIARIDGwA5CggKAQgSAxwAOQoJCgIIKRID
HAA5CggKAQgSAx0AOAoJCgIILRIDHQA4CjUKAgQAEgQgAEMBGikgQSBkYXRhT2JqZWN0IHJl
c291cmNlIGluIFZlY3RvciBTZWFyY2guCgoKCgMEAAESAyAIEgoLCgMEAAcSBCECJgQKDQoF
BAAHnQgSBCECJgQKrwIKBAQAAgASAy4CPRqhAiBJZGVudGlmaWVyLiBUaGUgZnVsbHkgcXVh
bGlmaWVkIHJlc291cmNlIG5hbWUgb2YgdGhlIGRhdGFPYmplY3QuCgogRm9ybWF0OgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29s
bGVjdGlvbn0vZGF0YU9iamVjdHMve2RhdGFfb2JqZWN0X2lkfWAKIFRoZSBkYXRhX29iamVj
dF9pZCBtdXN0IGJlIDEtNjMgY2hhcmFjdGVycwogbG9uZywgYW5kIGNvbXBseSB3aXRoIFtS
RkMxMDM1XShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMvcmZjMTAzNS50eHQpLgoKDAoFBAAC
AAUSAy4CCAoMCgUEAAIAARIDLgkNCgwKBQQAAgADEgMuEBEKDAoFBAACAAgSAy4SPAoPCggE
AAIACJwIABIDLhM7CjUKBAQAAgESAzECSBooIE91dHB1dCBvbmx5LiBUaGUgaWQgb2YgdGhl
IGRhdGFPYmplY3QuCgoMCgUEAAIBBRIDMQIICgwKBQQAAgEBEgMxCRcKDAoFBAACAQMSAzEa
GwoMCgUEAAIBCBIDMRxHCg8KCAQAAgEInAgAEgMxHUYKRQoEBAACAhIENAI1Mho3IE91dHB1
dCBvbmx5LiBUaW1lc3RhbXAgdGhlIGRhdGFPYmplY3Qgd2FzIGNyZWF0ZWQgYXQuCgoMCgUE
AAICBhIDNAIbCgwKBQQAAgIBEgM0HCcKDAoFBAACAgMSAzQqKwoMCgUEAAICCBIDNQYxCg8K
CAQAAgIInAgAEgM1BzAKRwoEBAACAxIEOAI5Mho5IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAg
dGhlIGRhdGFPYmplY3Qgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgMGEgM4AhsKDAoFBAAC
AwESAzgcJwoMCgUEAAIDAxIDOCorCgwKBQQAAgMIEgM5BjEKDwoIBAACAwicCAASAzkHMAo0
CgQEAAIEEgM8AksaJyBPcHRpb25hbC4gVGhlIGRhdGEgb2YgdGhlIGRhdGFPYmplY3QuCgoM
CgUEAAIEBhIDPAIYCgwKBQQAAgQBEgM8GR0KDAoFBAACBAMSAzwgIQoMCgUEAAIECBIDPCJK
Cg8KCAQAAgQInAgAEgM8I0kKNwoEBAACBRIDPwJLGiogT3B0aW9uYWwuIFRoZSB2ZWN0b3Jz
IG9mIHRoZSBkYXRhT2JqZWN0LgoKDAoFBAACBQYSAz8CFQoMCgUEAAIFARIDPxYdCgwKBQQA
AgUDEgM/ICEKDAoFBAACBQgSAz8iSgoPCggEAAIFCJwIABIDPyNJCjQKBAQAAgYSA0ICOxon
IE9wdGlvbmFsLiBUaGUgZXRhZyBvZiB0aGUgZGF0YU9iamVjdC4KCgwKBQQAAgYFEgNCAggK
DAoFBAACBgESA0IJDQoMCgUEAAIGAxIDQhARCgwKBQQAAgYIEgNCEjoKDwoIBAACBgicCAAS
A0ITOQo7CgIEARIERgBPARovIEEgdmVjdG9yIHdoaWNoIGNhbiBiZSBlaXRoZXIgZGVuc2Ug
b3Igc3BhcnNlLgoKCgoDBAEBEgNGCA4KJwoEBAEIABIESAJOAxoZIFRoZSB0eXBlIG9mIHRo
ZSB2ZWN0b3IuCgoMCgUEAQgAARIDSAgTCh4KBAQBAgASA0oEGhoRIEEgZGVuc2UgdmVjdG9y
LgoKDAoFBAECAAYSA0oEDwoMCgUEAQIAARIDShAVCgwKBQQBAgADEgNKGBkKHwoEBAECARID
TQQcGhIgQSBzcGFyc2UgdmVjdG9yLgoKDAoFBAECAQYSA00EEAoMCgUEAQIBARIDTREXCgwK
BQQBAgEDEgNNGhsKHQoCBAISBFIAVQEaESBBIGRlbnNlIHZlY3Rvci4KCgoKAwQCARIDUggT
CjIKBAQCAgASA1QCRRolIFJlcXVpcmVkLiBUaGUgdmFsdWVzIG9mIHRoZSB2ZWN0b3IuCgoM
CgUEAgIABBIDVAIKCgwKBQQCAgAFEgNUCxAKDAoFBAICAAESA1QRFwoMCgUEAgIAAxIDVBob
CgwKBQQCAgAIEgNUHEQKDwoIBAICAAicCAASA1QdQwoeCgIEAxIEWABeARoSIEEgc3BhcnNl
IHZlY3Rvci4KCgoKAwQDARIDWAgUCjIKBAQDAgASA1oCRRolIFJlcXVpcmVkLiBUaGUgdmFs
dWVzIG9mIHRoZSB2ZWN0b3IuCgoMCgUEAwIABBIDWgIKCgwKBQQDAgAFEgNaCxAKDAoFBAMC
AAESA1oRFwoMCgUEAwIAAxIDWhobCgwKBQQDAgAIEgNaHEQKDwoIBAMCAAicCAASA1odQwpC
CgQEAwIBEgNdAkYaNSBSZXF1aXJlZC4gVGhlIGNvcnJlc3BvbmRpbmcgaW5kaWNlcyBmb3Ig
dGhlIHZhbHVlcy4KCgwKBQQDAgEEEgNdAgoKDAoFBAMCAQUSA10LEAoMCgUEAwIBARIDXREY
CgwKBQQDAgEDEgNdGxwKDAoFBAMCAQgSA10dRQoPCggEAwIBCJwIABIDXR5EYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1::DataObject::DataObject ===
    # Fields for DataObject
    # Field: name Type: 9 ()
    # Field: data_object_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data Type: 11 (.google.protobuf.Struct)
    # Field: vectors Type: 11 (.google.cloud.vectorsearch.v1.DataObject.VectorsEntry)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Vectorsearch::V1::DataObject::Vector ===
    # Fields for Vector
    # Field: dense Type: 11 (.google.cloud.vectorsearch.v1.DenseVector)
    # Field: sparse Type: 11 (.google.cloud.vectorsearch.v1.SparseVector)

# === Message: Google::Cloud::Vectorsearch::V1::DataObject::DenseVector ===
    # Fields for DenseVector
    # Field: values Type: 2 ()

# === Message: Google::Cloud::Vectorsearch::V1::DataObject::SparseVector ===
    # Fields for SparseVector
    # Field: values Type: 2 ()
    # Field: indices Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1::DataObject - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1/data_object.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1::DataObject;

    my $msg = Google::Cloud::Vectorsearch::V1::DataObject::DataObject->new({
        name => $name,
        data_object_id => $data_object_id,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1::DataObject::DataObject->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1/data_object.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1::DataObject::DataObject

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

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObject::DataObject::VectorsEntry>)

Optional. The vectors of the dataObject.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag of the dataObject.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObject::Vector

A vector which can be either dense or sparse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dense() >> / C<< $msg->dense($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObject::DenseVector>)

A dense vector.

=item * C<< $msg->sparse() >> / C<< $msg->sparse($value) >>

Type: C<Message> (L<Google::Cloud::Vectorsearch::V1::DataObject::SparseVector>)

A sparse vector.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObject::DenseVector

A dense vector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Float>

Required. The values of the vector.

=back

=head2 Google::Cloud::Vectorsearch::V1::DataObject::SparseVector

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1::DataObject::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
