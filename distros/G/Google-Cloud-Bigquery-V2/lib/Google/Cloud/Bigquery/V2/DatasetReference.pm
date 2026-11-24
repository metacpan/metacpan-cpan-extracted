package Google::Cloud::Bigquery::V2::DatasetReference;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZGF0YXNldF9yZWZlcmVuY2UucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
byJaChBEYXRhc2V0UmVmZXJlbmNlEiIKCmRhdGFzZXRfaWQYASABKAlCA+BBAlIJZGF0YXNl
dElkEiIKCnByb2plY3RfaWQYAiABKAlCA+BBAVIJcHJvamVjdElkQnIKHGNvbS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkudjJCFURhdGFzZXRSZWZlcmVuY2VQcm90b1o7Y2xvdWQuZ29vZ2xl
LmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5cGJK+QgKBhIE
DgAhAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgID
ABIDEgApCggKAQgSAxQAUgoJCgIICxIDFABSCggKAQgSAxUANgoJCgIICBIDFQA2CggKAQgS
AxYANQoJCgIIARIDFgA1CicKAgQAEgQZACEBGhsgSWRlbnRpZmllciBmb3IgYSBkYXRhc2V0
LgoKCgoDBAABEgMZCBgKywEKBAQAAgASAx0CQRq9ASBSZXF1aXJlZC4gQSB1bmlxdWUgSUQg
Zm9yIHRoaXMgZGF0YXNldCwgd2l0aG91dCB0aGUgcHJvamVjdCBuYW1lLiBUaGUgSUQKIG11
c3QgY29udGFpbiBvbmx5IGxldHRlcnMgKGEteiwgQS1aKSwgbnVtYmVycyAoMC05KSwgb3Ig
dW5kZXJzY29yZXMgKF8pLgogVGhlIG1heGltdW0gbGVuZ3RoIGlzIDEsMDI0IGNoYXJhY3Rl
cnMuCgoMCgUEAAIABRIDHQIICgwKBQQAAgABEgMdCRMKDAoFBAACAAMSAx0WFwoMCgUEAAIA
CBIDHRhACg8KCAQAAgAInAgAEgMdGT8KRwoEBAACARIDIAJBGjogT3B0aW9uYWwuIFRoZSBJ
RCBvZiB0aGUgcHJvamVjdCBjb250YWluaW5nIHRoaXMgZGF0YXNldC4KCgwKBQQAAgEFEgMg
AggKDAoFBAACAQESAyAJEwoMCgUEAAIBAxIDIBYXCgwKBQQAAgEIEgMgGEAKDwoIBAACAQic
CAASAyAZP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference ===
    # Fields for DatasetReference
    # Field: dataset_id Type: 9 ()
    # Field: project_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::DatasetReference - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/dataset_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::DatasetReference;

    my $msg = Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference->new({
        dataset_id => $dataset_id,
        project_id => $project_id,
    });

    # Read or update a field
    my $val = $msg->dataset_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/dataset_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference

Identifier for a dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. A unique ID for this dataset, without the project name. The ID
must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_).
The maximum length is 1,024 characters.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Optional. The ID of the project containing this dataset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::DatasetReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
