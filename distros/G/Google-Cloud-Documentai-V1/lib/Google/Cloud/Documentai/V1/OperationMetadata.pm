package Google::Cloud::Documentai::V1::OperationMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9vcGVyYXRpb25fbWV0YWRhdGEucHJvdG8S
Gmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIowDChdDb21tb25PcGVyYXRpb25NZXRhZGF0YRJPCgVzdGF0ZRgBIAEoDjI5Lmdv
b2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxLkNvbW1vbk9wZXJhdGlvbk1ldGFkYXRhLlN0YXRl
UgVzdGF0ZRIjCg1zdGF0ZV9tZXNzYWdlGAIgASgJUgxzdGF0ZU1lc3NhZ2USGgoIcmVzb3Vy
Y2UYBSABKAlSCHJlc291cmNlEjsKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUiZQoFU3RhdGUSFQoRU1RBVEVfVU5T
UEVDSUZJRUQQABILCgdSVU5OSU5HEAESDgoKQ0FOQ0VMTElORxACEg0KCVNVQ0NFRURFRBAD
EgoKBkZBSUxFRBAEEg0KCUNBTkNFTExFRBAFQtQBCh5jb20uZ29vZ2xlLmNsb3VkLmRvY3Vt
ZW50YWkudjFCFk9wZXJhdGlvbk1ldGFkYXRhUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9n
by9kb2N1bWVudGFpL2FwaXYxL2RvY3VtZW50YWlwYjtkb2N1bWVudGFpcGKqAhpHb29nbGUu
Q2xvdWQuRG9jdW1lbnRBSS5WMcoCGkdvb2dsZVxDbG91ZFxEb2N1bWVudEFJXFYx6gIdR29v
Z2xlOjpDbG91ZDo6RG9jdW1lbnRBSTo6VjFKrQ4KBhIEDgBBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgApCggKAQgSAxQANwoJCgII
JRIDFAA3CggKAQgSAxUAVQoJCgIICxIDFQBVCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgS
AxcANwoJCgIICBIDFwA3CggKAQgSAxgANwoJCgIIARIDGAA3CggKAQgSAxkANwoJCgIIKRID
GQA3CggKAQgSAxoANgoJCgIILRIDGgA2Cj4KAgQAEgQdAEEBGjIgVGhlIGNvbW1vbiBtZXRh
ZGF0YSBmb3IgbG9uZyBydW5uaW5nIG9wZXJhdGlvbnMuCgoKCgMEAAESAx0IHwozCgQEAAQA
EgQfAjEDGiUgU3RhdGUgb2YgdGhlIGxvbmdydW5uaW5nIG9wZXJhdGlvbi4KCgwKBQQABAAB
EgMfBwwKIwoGBAAEAAIAEgMhBBoaFCBVbnNwZWNpZmllZCBzdGF0ZS4KCg4KBwQABAACAAES
AyEEFQoOCgcEAAQAAgACEgMhGBkKLAoGBAAEAAIBEgMkBBAaHSBPcGVyYXRpb24gaXMgc3Rp
bGwgcnVubmluZy4KCg4KBwQABAACAQESAyQECwoOCgcEAAQAAgECEgMkDg8KLgoGBAAEAAIC
EgMnBBMaHyBPcGVyYXRpb24gaXMgYmVpbmcgY2FuY2VsbGVkLgoKDgoHBAAEAAICARIDJwQO
Cg4KBwQABAACAgISAycREgolCgYEAAQAAgMSAyoEEhoWIE9wZXJhdGlvbiBzdWNjZWVkZWQu
CgoOCgcEAAQAAgMBEgMqBA0KDgoHBAAEAAIDAhIDKhARCiIKBgQABAACBBIDLQQPGhMgT3Bl
cmF0aW9uIGZhaWxlZC4KCg4KBwQABAACBAESAy0ECgoOCgcEAAQAAgQCEgMtDQ4KKAoGBAAE
AAIFEgMwBBIaGSBPcGVyYXRpb24gaXMgY2FuY2VsbGVkLgoKDgoHBAAEAAIFARIDMAQNCg4K
BwQABAACBQISAzAQEQoqCgQEAAIAEgM0AhIaHSBUaGUgc3RhdGUgb2YgdGhlIG9wZXJhdGlv
bi4KCgwKBQQAAgAGEgM0AgcKDAoFBAACAAESAzQIDQoMCgUEAAIAAxIDNBARClYKBAQAAgES
AzcCGxpJIEEgbWVzc2FnZSBwcm92aWRpbmcgbW9yZSBkZXRhaWxzIGFib3V0IHRoZSBjdXJy
ZW50IHN0YXRlIG9mIHByb2Nlc3NpbmcuCgoMCgUEAAIBBRIDNwIICgwKBQQAAgEBEgM3CRYK
DAoFBAACAQMSAzcZGgo0CgQEAAICEgM6AhYaJyBBIHJlbGF0ZWQgcmVzb3VyY2UgdG8gdGhp
cyBvcGVyYXRpb24uCgoMCgUEAAICBRIDOgIICgwKBQQAAgIBEgM6CREKDAoFBAACAgMSAzoU
FQoyCgQEAAIDEgM9AiwaJSBUaGUgY3JlYXRpb24gdGltZSBvZiB0aGUgb3BlcmF0aW9uLgoK
DAoFBAACAwYSAz0CGwoMCgUEAAIDARIDPRwnCgwKBQQAAgMDEgM9KisKNQoEBAACBBIDQAIs
GiggVGhlIGxhc3QgdXBkYXRlIHRpbWUgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgQGEgNA
AhsKDAoFBAACBAESA0AcJwoMCgUEAAIEAxIDQCorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata ===
    # Fields for CommonOperationMetadata
    # Field: state Type: 14 (.google.cloud.documentai.v1.CommonOperationMetadata.State)
    # Field: state_message Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: CommonOperationMetadata::State
our $CommonOperationMetadata_STATE_UNSPECIFIED = 0;
our $CommonOperationMetadata_RUNNING = 1;
our $CommonOperationMetadata_CANCELLING = 2;
our $CommonOperationMetadata_SUCCEEDED = 3;
our $CommonOperationMetadata_FAILED = 4;
our $CommonOperationMetadata_CANCELLED = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1::OperationMetadata - Compiled Protocol Buffers messages for google/cloud/documentai/v1/operation_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1::OperationMetadata;

    my $msg = Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata->new({
        state => $state,
        state_message => $state_message,
        resource => $resource,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->state();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1/operation_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata

The common metadata for long running operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1::CommonOperationMetadata::State>)

The state of the operation.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

A message providing more details about the current state of processing.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

A related resource to this operation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The creation time of the operation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last update time of the operation.

=back

=head3 Enum: CommonOperationMetadata::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<CANCELLING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<CANCELLED> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1::OperationMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
