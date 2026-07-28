package Google::Cloud::Bigquery::Storage::V1::Protobuf;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Descriptor };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MS9wcm90b2J1Zi5wcm90bxIgZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjEaIGdvb2dsZS9wcm90b2J1Zi9kZXNjcmlw
dG9yLnByb3RvIloKC1Byb3RvU2NoZW1hEksKEHByb3RvX2Rlc2NyaXB0b3IYASABKAsyIC5n
b29nbGUucHJvdG9idWYuRGVzY3JpcHRvclByb3RvUg9wcm90b0Rlc2NyaXB0b3IiNAoJUHJv
dG9Sb3dzEicKD3NlcmlhbGl6ZWRfcm93cxgBIAMoDFIOc2VyaWFsaXplZFJvd3NCvQEKJGNv
bS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MUINUHJvdG9CdWZQcm90b1ABWj5j
bG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3N0b3JhZ2UvYXBpdjEvc3RvcmFnZXBiO3N0
b3JhZ2VwYqoCIEdvb2dsZS5DbG91ZC5CaWdRdWVyeS5TdG9yYWdlLlYxygIgR29vZ2xlXENs
b3VkXEJpZ1F1ZXJ5XFN0b3JhZ2VcVjFKoQ0KBhIEDgAvAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAqCggKAQgSAxQAPQoJCgIIJRID
FAA9CggKAQgSAxUAVQoJCgIICxIDFQBVCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcA
LgoJCgIICBIDFwAuCggKAQgSAxgAPQoJCgIIARIDGAA9CggKAQgSAxkAPgoJCgIIKRIDGQA+
ClsKAgQAEgQcACcBGk8gUHJvdG9TY2hlbWEgZGVzY3JpYmVzIHRoZSBzY2hlbWEgb2YgdGhl
IHNlcmlhbGl6ZWQgcHJvdG9jb2wgYnVmZmVyIGRhdGEgcm93cy4KCgoKAwQAARIDHAgTCqUE
CgQEAAIAEgMmAjcalwQgRGVzY3JpcHRvciBmb3IgaW5wdXQgbWVzc2FnZS4gIFRoZSBwcm92
aWRlZCBkZXNjcmlwdG9yIG11c3QgYmUgc2VsZgogY29udGFpbmVkLCBzdWNoIHRoYXQgZGF0
YSByb3dzIHNlbnQgY2FuIGJlIGZ1bGx5IGRlY29kZWQgdXNpbmcgb25seSB0aGUKIHNpbmds
ZSBkZXNjcmlwdG9yLiAgRm9yIGRhdGEgcm93cyB0aGF0IGFyZSBjb21wb3NpdGlvbnMgb2Yg
bXVsdGlwbGUKIGluZGVwZW5kZW50IG1lc3NhZ2VzLCB0aGlzIG1lYW5zIHRoZSBkZXNjcmlw
dG9yIG1heSBuZWVkIHRvIGJlIHRyYW5zZm9ybWVkCiB0byBvbmx5IHVzZSBuZXN0ZWQgdHlw
ZXM6CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2Rv
Y3MvcHJvdG8jbmVzdGVkCgogRm9yIGFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZm9yIGhvdyBw
cm90byB0eXBlcyBhbmQgdmFsdWVzIG1hcCBvbnRvIEJpZ1F1ZXJ5CiBzZWU6IGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL3dyaXRlLWFwaSNkYXRhX3R5cGVfY29u
dmVyc2lvbnMKCgwKBQQAAgAGEgMmAiEKDAoFBAACAAESAyYiMgoMCgUEAAIAAxIDJjU2CgoK
AgQBEgQpAC8BCgoKAwQBARIDKQgRCrkBCgQEAQIAEgMuAiUaqwEgQSBzZXF1ZW5jZSBvZiBy
b3dzIHNlcmlhbGl6ZWQgYXMgYSBQcm90b2NvbCBCdWZmZXIuCgogU2VlIGh0dHBzOi8vZGV2
ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9vdmVydmlldyBmb3Ig
bW9yZQogaW5mb3JtYXRpb24gb24gZGVzZXJpYWxpemluZyB0aGlzIGZpZWxkLgoKDAoFBAEC
AAQSAy4CCgoMCgUEAQIABRIDLgsQCgwKBQQBAgABEgMuESAKDAoFBAECAAMSAy4jJGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoSchema ===
    # Fields for ProtoSchema
    # Field: proto_descriptor Type: 11 (.google.protobuf.DescriptorProto)

=pod

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoSchema - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Protobuf;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoSchema->new(
        proto_descriptor => $value,
    );

=head1 FIELDS

=over 4

=item * B<proto_descriptor>

Type: Message (.google.protobuf.DescriptorProto)

=back

=cut

# === Message: Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoRows ===
    # Fields for ProtoRows
    # Field: serialized_rows Type: 12 ()

=pod

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoRows - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Protobuf;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoRows->new(
        serialized_rows => $value,
    );

=head1 FIELDS

=over 4

=item * B<serialized_rows>

Type: Bytes

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Protobuf - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
