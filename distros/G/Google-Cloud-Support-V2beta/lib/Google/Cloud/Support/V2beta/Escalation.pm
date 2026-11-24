package Google::Cloud::Support::V2beta::Escalation;

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
Cixnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvZXNjYWxhdGlvbi5wcm90bxIbZ29vZ2xl
LmNsb3VkLnN1cHBvcnQudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
IukBCgpFc2NhbGF0aW9uEksKBnJlYXNvbhgEIAEoDjIuLmdvb2dsZS5jbG91ZC5zdXBwb3J0
LnYyYmV0YS5Fc2NhbGF0aW9uLlJlYXNvbkID4EECUgZyZWFzb24SKQoNanVzdGlmaWNhdGlv
bhgFIAEoCUID4EECUg1qdXN0aWZpY2F0aW9uImMKBlJlYXNvbhIWChJSRUFTT05fVU5TUEVD
SUZJRUQQABITCg9SRVNPTFVUSU9OX1RJTUUQARIXChNURUNITklDQUxfRVhQRVJUSVNFEAIS
EwoPQlVTSU5FU1NfSU1QQUNUEANCzAEKH2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJl
dGFCD0VzY2FsYXRpb25Qcm90b1ABWjljbG91ZC5nb29nbGUuY29tL2dvL3N1cHBvcnQvYXBp
djJiZXRhL3N1cHBvcnRwYjtzdXBwb3J0cGKqAhtHb29nbGUuQ2xvdWQuU3VwcG9ydC5WMkJl
dGHKAhtHb29nbGVcQ2xvdWRcU3VwcG9ydFxWMmJldGHqAh5Hb29nbGU6OkNsb3VkOjpTdXBw
b3J0OjpWMmJldGFKxA0KBhIEDgA0AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
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
ZS4KCggKAQISAxAAJAoJCgIDABIDEgApCggKAQgSAxQAOAoJCgIIJRIDFAA4CggKAQgSAxUA
UAoJCgIICxIDFQBQCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMAoJCgIICBIDFwAw
CggKAQgSAxgAOAoJCgIIARIDGAA4CggKAQgSAxkAOAoJCgIIKRIDGQA4CggKAQgSAxoANwoJ
CgIILRIDGgA3Ci4KAgQAEgQdADQBGiIgQW4gZXNjYWxhdGlvbiBvZiBhIHN1cHBvcnQgY2Fz
ZS4KCgoKAwQAARIDHQgSCk8KBAQABAASBB8CLAMaQSBBbiBlbnVtIGRldGFpbGluZyB0aGUg
cG9zc2libGUgcmVhc29ucyBhIGNhc2UgbWF5IGJlIGVzY2FsYXRlZC4KCgwKBQQABAABEgMf
Bw0KWAoGBAAEAAIAEgMhBBsaSSBUaGUgZXNjYWxhdGlvbiByZWFzb24gaXMgaW4gYW4gdW5r
bm93biBzdGF0ZSBvciBoYXMgbm90IGJlZW4gc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDIQQW
Cg4KBwQABAACAAISAyEZGgo4CgYEAAQAAgESAyQEGBopIFRoZSBjYXNlIGlzIHRha2luZyB0
b28gbG9uZyB0byByZXNvbHZlLgoKDgoHBAAEAAIBARIDJAQTCg4KBwQABAACAQISAyQWFwpr
CgYEAAQAAgISAygEHBpcIFRoZSBzdXBwb3J0IGFnZW50IGRvZXMgbm90IGhhdmUgdGhlIGV4
cGVydGlzZSByZXF1aXJlZCB0byBzdWNjZXNzZnVsbHkKIHJlc29sdmUgdGhlIGlzc3VlLgoK
DgoHBAAEAAICARIDKAQXCg4KBwQABAACAgISAygaGwpDCgYEAAQAAgMSAysEGBo0IFRoZSBp
c3N1ZSBpcyBoYXZpbmcgYSBzaWduaWZpY2FudCBidXNpbmVzcyBpbXBhY3QuCgoOCgcEAAQA
AgMBEgMrBBMKDgoHBAAEAAIDAhIDKxYXCkQKBAQAAgASAy8CPRo3IFJlcXVpcmVkLiBUaGUg
cmVhc29uIHdoeSB0aGUgQ2FzZSBpcyBiZWluZyBlc2NhbGF0ZWQuCgoMCgUEAAIABhIDLwII
CgwKBQQAAgABEgMvCQ8KDAoFBAACAAMSAy8SEwoMCgUEAAIACBIDLxQ8Cg8KCAQAAgAInAgA
EgMvFTsKmQEKBAQAAgESAzMCRBqLASBSZXF1aXJlZC4gQSBmcmVlIHRleHQgZGVzY3JpcHRp
b24gdG8gYWNjb21wYW55IHRoZSBgcmVhc29uYCBmaWVsZCBhYm92ZS4KIFByb3ZpZGVzIGFk
ZGl0aW9uYWwgY29udGV4dCBvbiB3aHkgdGhlIGNhc2UgaXMgYmVpbmcgZXNjYWxhdGVkLgoK
DAoFBAACAQUSAzMCCAoMCgUEAAIBARIDMwkWCgwKBQQAAgEDEgMzGRoKDAoFBAACAQgSAzMb
QwoPCggEAAIBCJwIABIDMxxCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::Escalation::Escalation ===
    # Fields for Escalation
    # Field: reason Type: 14 (.google.cloud.support.v2beta.Escalation.Reason)
    # Field: justification Type: 9 ()

# Enum: Escalation::Reason
our $Escalation_REASON_UNSPECIFIED = 0;
our $Escalation_RESOLUTION_TIME = 1;
our $Escalation_TECHNICAL_EXPERTISE = 2;
our $Escalation_BUSINESS_IMPACT = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::Escalation - Compiled Protocol Buffers messages for google/cloud/support/v2beta/escalation.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::Escalation;

    my $msg = Google::Cloud::Support::V2beta::Escalation::Escalation->new({
        reason => $reason,
        justification => $justification,
    });

    # Read or update a field
    my $val = $msg->reason();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::Escalation::Escalation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/escalation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::Escalation::Escalation

An escalation of a support case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::Escalation::Reason>)

Required. The reason why the Case is being escalated.

=item * C<< $msg->justification() >> / C<< $msg->justification($value) >>

Type: C<String>

Required. A free text description to accompany the `reason` field above.
Provides additional context on why the case is being escalated.

=back

=head3 Enum: Escalation::Reason

=over 4

=item * C<REASON_UNSPECIFIED> => C<0>

=item * C<RESOLUTION_TIME> => C<1>

=item * C<TECHNICAL_EXPERTISE> => C<2>

=item * C<BUSINESS_IMPACT> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::Escalation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
