package Google::Cloud::Channel::V1::Operations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9vcGVyYXRpb25zLnByb3RvEhdnb29nbGUuY2xv
dWQuY2hhbm5lbC52MSLFAwoRT3BlcmF0aW9uTWV0YWRhdGESXwoOb3BlcmF0aW9uX3R5cGUY
ASABKA4yOC5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5PcGVyYXRpb25NZXRhZGF0YS5PcGVy
YXRpb25UeXBlUg1vcGVyYXRpb25UeXBlIs4CCg1PcGVyYXRpb25UeXBlEh4KGk9QRVJBVElP
Tl9UWVBFX1VOU1BFQ0lGSUVEEAASFgoSQ1JFQVRFX0VOVElUTEVNRU5UEAESGwoXQ0hBTkdF
X1JFTkVXQUxfU0VUVElOR1MQAxIWChJTVEFSVF9QQUlEX1NFUlZJQ0UQBRIYChRBQ1RJVkFU
RV9FTlRJVExFTUVOVBAHEhcKE1NVU1BFTkRfRU5USVRMRU1FTlQQCBIWChJDQU5DRUxfRU5U
SVRMRU1FTlQQCRIZChVUUkFOU0ZFUl9FTlRJVExFTUVOVFMQChIjCh9UUkFOU0ZFUl9FTlRJ
VExFTUVOVFNfVE9fR09PR0xFEAsSEAoMQ0hBTkdFX09GRkVSEA4SFQoRQ0hBTkdFX1BBUkFN
RVRFUlMQDxIcChhQUk9WSVNJT05fQ0xPVURfSURFTlRJVFkQEEJnChtjb20uZ29vZ2xlLmNs
b3VkLmNoYW5uZWwudjFCD09wZXJhdGlvbnNQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dv
L2NoYW5uZWwvYXBpdjEvY2hhbm5lbHBiO2NoYW5uZWxwYkrcEQoGEgQOAEMBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCggKAQgSAxIATAoJCgIICxID
EgBMCggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQAMAoJCgIICBIDFAAwCggKAQgSAxUA
NAoJCgIIARIDFQA0CnQKAgQAEgQZAEMBGmggUHJvdmlkZXMgY29udGV4dHVhbCBpbmZvcm1h
dGlvbiBhYm91dCBhCiBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1bZ29vZ2xlLmxv
bmdydW5uaW5nLk9wZXJhdGlvbl0uCgoKCgMEAAESAxkIGQo6CgQEAAQAEgQbAj8DGiwgUlBD
cyB0aGF0IHJldHVybiBhIExvbmcgUnVubmluZyBPcGVyYXRpb24uCgoMCgUEAAQAARIDGwcU
ChoKBgQABAACABIDHQQjGgsgTm90IHVzZWQuCgoOCgcEAAQAAgABEgMdBB4KDgoHBAAEAAIA
AhIDHSEiCksKBgQABAACARIDIAQbGjwgTG9uZyBSdW5uaW5nIE9wZXJhdGlvbiB3YXMgdHJp
Z2dlcmVkIGJ5IENyZWF0ZUVudGl0bGVtZW50LgoKDgoHBAAEAAIBARIDIAQWCg4KBwQABAAC
AQISAyAZGgpPCgYEAAQAAgISAyMEIBpAIExvbmcgUnVubmluZyBPcGVyYXRpb24gd2FzIHRy
aWdnZXJlZCBieSBDaGFuZ2VSZW5ld2FsU2V0dGluZ3MuCgoOCgcEAAQAAgIBEgMjBBsKDgoH
BAAEAAICAhIDIx4fCkoKBgQABAACAxIDJgQbGjsgTG9uZyBSdW5uaW5nIE9wZXJhdGlvbiB3
YXMgdHJpZ2dlcmVkIGJ5IFN0YXJ0UGFpZFNlcnZpY2UuCgoOCgcEAAQAAgMBEgMmBBYKDgoH
BAAEAAIDAhIDJhkaCk0KBgQABAACBBIDKQQdGj4gTG9uZyBSdW5uaW5nIE9wZXJhdGlvbiB3
YXMgdHJpZ2dlcmVkIGJ5IEFjdGl2YXRlRW50aXRsZW1lbnQuCgoOCgcEAAQAAgQBEgMpBBgK
DgoHBAAEAAIEAhIDKRscCkwKBgQABAACBRIDLAQcGj0gTG9uZyBSdW5uaW5nIE9wZXJhdGlv
biB3YXMgdHJpZ2dlcmVkIGJ5IFN1c3BlbmRFbnRpdGxlbWVudC4KCg4KBwQABAACBQESAywE
FwoOCgcEAAQAAgUCEgMsGhsKSwoGBAAEAAIGEgMvBBsaPCBMb25nIFJ1bm5pbmcgT3BlcmF0
aW9uIHdhcyB0cmlnZ2VyZWQgYnkgQ2FuY2VsRW50aXRsZW1lbnQuCgoOCgcEAAQAAgYBEgMv
BBYKDgoHBAAEAAIGAhIDLxkaCk4KBgQABAACBxIDMgQfGj8gTG9uZyBSdW5uaW5nIE9wZXJh
dGlvbiB3YXMgdHJpZ2dlcmVkIGJ5IFRyYW5zZmVyRW50aXRsZW1lbnRzLgoKDgoHBAAEAAIH
ARIDMgQZCg4KBwQABAACBwISAzIcHgpWCgYEAAQAAggSAzUEKRpHIExvbmcgUnVubmluZyBP
cGVyYXRpb24gd2FzIHRyaWdnZXJlZCBieSBUcmFuc2ZlckVudGl0bGVtZW50c1RvR29vZ2xl
LgoKDgoHBAAEAAIIARIDNQQjCg4KBwQABAACCAISAzUmKApFCgYEAAQAAgkSAzgEFho2IExv
bmcgUnVubmluZyBPcGVyYXRpb24gd2FzIHRyaWdnZXJlZCBieSBDaGFuZ2VPZmZlci4KCg4K
BwQABAACCQESAzgEEAoOCgcEAAQAAgkCEgM4ExUKSgoGBAAEAAIKEgM7BBsaOyBMb25nIFJ1
bm5pbmcgT3BlcmF0aW9uIHdhcyB0cmlnZ2VyZWQgYnkgQ2hhbmdlUGFyYW1ldGVycy4KCg4K
BwQABAACCgESAzsEFQoOCgcEAAQAAgoCEgM7GBoKUAoGBAAEAAILEgM+BCIaQSBMb25nIFJ1
bm5pbmcgT3BlcmF0aW9uIHdhcyB0cmlnZ2VyZWQgYnkgUHJvdmlzaW9uQ2xvdWRJZGVudGl0
eS4KCg4KBwQABAACCwESAz4EHAoOCgcEAAQAAgsCEgM+HyEKQgoEBAACABIDQgIjGjUgVGhl
IFJQQyB0aGF0IGluaXRpYXRlZCB0aGlzIExvbmcgUnVubmluZyBPcGVyYXRpb24uCgoMCgUE
AAIABhIDQgIPCgwKBQQAAgABEgNCEB4KDAoFBAACAAMSA0IhImIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Operations::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: operation_type Type: 14 (.google.cloud.channel.v1.OperationMetadata.OperationType)

# Enum: OperationMetadata::OperationType
our $OperationMetadata_OPERATION_TYPE_UNSPECIFIED = 0;
our $OperationMetadata_CREATE_ENTITLEMENT = 1;
our $OperationMetadata_CHANGE_RENEWAL_SETTINGS = 3;
our $OperationMetadata_START_PAID_SERVICE = 5;
our $OperationMetadata_ACTIVATE_ENTITLEMENT = 7;
our $OperationMetadata_SUSPEND_ENTITLEMENT = 8;
our $OperationMetadata_CANCEL_ENTITLEMENT = 9;
our $OperationMetadata_TRANSFER_ENTITLEMENTS = 10;
our $OperationMetadata_TRANSFER_ENTITLEMENTS_TO_GOOGLE = 11;
our $OperationMetadata_CHANGE_OFFER = 14;
our $OperationMetadata_CHANGE_PARAMETERS = 15;
our $OperationMetadata_PROVISION_CLOUD_IDENTITY = 16;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Operations - Compiled Protocol Buffers messages for google/cloud/channel/v1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Operations;

    my $msg = Google::Cloud::Channel::V1::Operations::OperationMetadata->new({
        operation_type => $operation_type,
    });

    # Read or update a field
    my $val = $msg->operation_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Operations::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Operations::OperationMetadata

Provides contextual information about a
[google.longrunning.Operation][google.longrunning.Operation].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::OperationMetadata::OperationType>)

The RPC that initiated this Long Running Operation.

=back

=head3 Enum: OperationMetadata::OperationType

=over 4

=item * C<OPERATION_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE_ENTITLEMENT> => C<1>

=item * C<CHANGE_RENEWAL_SETTINGS> => C<3>

=item * C<START_PAID_SERVICE> => C<5>

=item * C<ACTIVATE_ENTITLEMENT> => C<7>

=item * C<SUSPEND_ENTITLEMENT> => C<8>

=item * C<CANCEL_ENTITLEMENT> => C<9>

=item * C<TRANSFER_ENTITLEMENTS> => C<10>

=item * C<TRANSFER_ENTITLEMENTS_TO_GOOGLE> => C<11>

=item * C<CHANGE_OFFER> => C<14>

=item * C<CHANGE_PARAMETERS> => C<15>

=item * C<PROVISION_CLOUD_IDENTITY> => C<16>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
