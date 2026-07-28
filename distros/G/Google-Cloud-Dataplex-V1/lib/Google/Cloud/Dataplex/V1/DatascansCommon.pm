package Google::Cloud::Dataplex::V1::DatascansCommon;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGF0YXBsZXgvdjEvZGF0YXNjYW5zX2NvbW1vbi5wcm90bxIYZ29v
Z2xlLmNsb3VkLmRhdGFwbGV4LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
IsUBCh9EYXRhU2NhbkNhdGFsb2dQdWJsaXNoaW5nU3RhdHVzEloKBXN0YXRlGAEgASgOMj8u
Z29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkRhdGFTY2FuQ2F0YWxvZ1B1Ymxpc2hpbmdTdGF0
dXMuU3RhdGVCA+BBA1IFc3RhdGUiRgoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIN
CglTVUNDRUVERUQQARIKCgZGQUlMRUQQAhILCgdTS0lQUEVEEANCcAocY29tLmdvb2dsZS5j
bG91ZC5kYXRhcGxleC52MUIURGF0YVNjYW5zQ29tbW9uUHJvdG9QAVo4Y2xvdWQuZ29vZ2xl
LmNvbS9nby9kYXRhcGxleC9hcGl2MS9kYXRhcGxleHBiO2RhdGFwbGV4cGJKyQsKBhIEDgAu
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABID
EgApCggKAQgSAxQATwoJCgIICxIDFABPCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYA
NQoJCgIICBIDFgA1CggKAQgSAxcANQoJCgIIARIDFwA1CugBCgIEABIEHAAuARrbASBUaGUg
c3RhdHVzIG9mIHB1Ymxpc2hpbmcgdGhlIGRhdGEgc2NhbiByZXN1bHQgYXMgRGF0YXBsZXgg
VW5pdmVyc2FsIENhdGFsb2cKIG1ldGFkYXRhLiBNdWx0aXBsZSBEYXRhU2NhbiBsb2cgZXZl
bnRzIG1heSBleGlzdCwgZWFjaCB3aXRoIGRpZmZlcmVudAogcHVibGlzaGluZyBpbmZvcm1h
dGlvbiBkZXBlbmRpbmcgb24gdGhlIHR5cGUgb2YgcHVibGlzaGluZyB0cmlnZ2VyZWQuCgoK
CgMEAAESAxwIJwozCgQEAAQAEgQeAioDGiUgRXhlY3V0aW9uIHN0YXRlIGZvciB0aGUgcHVi
bGlzaGluZy4KCgwKBQQABAABEgMeBwwKNQoGBAAEAAIAEgMgBBoaJiBUaGUgcHVibGlzaGlu
ZyBzdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAyAEFQoOCgcEAAQAAgACEgMg
GBkKPgoGBAAEAAIBEgMjBBIaLyBQdWJsaXNoaW5nIHRvIGNhdGFsb2cgY29tcGxldGVkIHN1
Y2Nlc3NmdWxseS4KCg4KBwQABAACAQESAyMEDQoOCgcEAAQAAgECEgMjEBEKKwoGBAAEAAIC
EgMmBA8aHCBQdWJsaXNoIHRvIGNhdGFsb2cgZmFpbGVkLgoKDgoHBAAEAAICARIDJgQKCg4K
BwQABAACAgISAyYNDgozCgYEAAQAAgMSAykEEBokIFB1Ymxpc2hpbmcgdG8gY2F0YWxvZyB3
YXMgc2tpcHBlZC4KCg4KBwQABAACAwESAykECwoOCgcEAAQAAgMCEgMpDg8KOwoEBAACABID
LQI+Gi4gT3V0cHV0IG9ubHkuIEV4ZWN1dGlvbiBzdGF0ZSBmb3IgcHVibGlzaGluZy4KCgwK
BQQAAgAGEgMtAgcKDAoFBAACAAESAy0IDQoMCgUEAAIAAxIDLRARCgwKBQQAAgAIEgMtEj0K
DwoIBAACAAicCAASAy0TPGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataplex::V1::DatascansCommon::DataScanCatalogPublishingStatus ===
    # Fields for DataScanCatalogPublishingStatus
    # Field: state Type: 14 (.google.cloud.dataplex.v1.DataScanCatalogPublishingStatus.State)

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::DatascansCommon::DataScanCatalogPublishingStatus - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::DatascansCommon;

    my $msg = Google::Cloud::Dataplex::V1::DatascansCommon::DataScanCatalogPublishingStatus->new(
        state => $value,
    );

=head1 FIELDS

=over 4

=item * B<state>

Type: Enum (.google.cloud.dataplex.v1.DataScanCatalogPublishingStatus.State)

=back

=cut

# Enum: DataScanCatalogPublishingStatus::State
our $DataScanCatalogPublishingStatus_STATE_UNSPECIFIED = 0;
our $DataScanCatalogPublishingStatus_SUCCEEDED = 1;
our $DataScanCatalogPublishingStatus_FAILED = 2;
our $DataScanCatalogPublishingStatus_SKIPPED = 3;

=pod

=head2 Enum: DataScanCatalogPublishingStatus::State

Values:

=over 4

=item * C<STATE_UNSPECIFIED> => 0

=item * C<SUCCEEDED> => 1

=item * C<FAILED> => 2

=item * C<SKIPPED> => 3

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DatascansCommon - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
