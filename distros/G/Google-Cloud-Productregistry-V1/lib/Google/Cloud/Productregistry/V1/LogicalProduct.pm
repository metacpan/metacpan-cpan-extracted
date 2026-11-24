package Google::Cloud::Productregistry::V1::LogicalProduct;

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
    eval { require Google::Cloud::Productregistry::V1::LifecycleState };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvcHJvZHVjdHJlZ2lzdHJ5L3YxL2xvZ2ljYWxfcHJvZHVjdC5wcm90
bxIfZ29vZ2xlLmNsb3VkLnByb2R1Y3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo1Z29vZ2xlL2Nsb3Vk
L3Byb2R1Y3RyZWdpc3RyeS92MS9saWZlY3ljbGVfc3RhdGUucHJvdG8ipAQKDkxvZ2ljYWxQ
cm9kdWN0EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIUCgV0aXRsZRgCIAEoCVIFdGl0bGUS
WgoNcHJvZHVjdF9zdWl0ZRgDIAEoCUI1+kEyCjBjbG91ZHByb2R1Y3RyZWdpc3RyeS5nb29n
bGVhcGlzLmNvbS9Qcm9kdWN0U3VpdGVSDHByb2R1Y3RTdWl0ZRJdCgh2YXJpYW50cxgEIAMo
CUJB4EED+kE7CjljbG91ZHByb2R1Y3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9Mb2dpY2Fs
UHJvZHVjdFZhcmlhbnRSCHZhcmlhbnRzEl0KD2xpZmVjeWNsZV9zdGF0ZRgFIAEoDjIvLmdv
b2dsZS5jbG91ZC5wcm9kdWN0cmVnaXN0cnkudjEuTGlmZWN5Y2xlU3RhdGVCA+BBA1IObGlm
ZWN5Y2xlU3RhdGUSHwoIcmVwbGFjZWQYBiABKAhCA+BBA1IIcmVwbGFjZWQSKwoLcmVwbGFj
ZW1lbnQYByABKAlCCeBBA/pBAwoBKlILcmVwbGFjZW1lbnQ6e+pBeAoyY2xvdWRwcm9kdWN0
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vTG9naWNhbFByb2R1Y3QSIWxvZ2ljYWxQcm9kdWN0
cy97bG9naWNhbF9wcm9kdWN0fSoPbG9naWNhbFByb2R1Y3RzMg5sb2dpY2FsUHJvZHVjdEL0
AQojY29tLmdvb2dsZS5jbG91ZC5wcm9kdWN0cmVnaXN0cnkudjFCE0xvZ2ljYWxQcm9kdWN0
UHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9wcm9kdWN0cmVnaXN0cnkvYXBpdjEvcHJv
ZHVjdHJlZ2lzdHJ5cGI7cHJvZHVjdHJlZ2lzdHJ5cGKqAh9Hb29nbGUuQ2xvdWQuUHJvZHVj
dFJlZ2lzdHJ5LlYxygIfR29vZ2xlXENsb3VkXFByb2R1Y3RSZWdpc3RyeVxWMeoCIkdvb2ds
ZTo6Q2xvdWQ6OlByb2R1Y3RSZWdpc3RyeTo6VjFKrRMKBhIEDgBRAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQAPwoICgEIEgMWADwKCQoCCCUSAxYAPAoICgEIEgMXAGQKCQoCCAsSAxcAZAoI
CgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADQKCQoCCAgSAxkANAoICgEIEgMaADwKCQoC
CAESAxoAPAoICgEIEgMbADwKCQoCCCkSAxsAPAoICgEIEgMcADsKCQoCCC0SAxwAOwpgCgIE
ABIEIABRARpUIFJlcHJlc2VudHMgYW4gaW5kZXBlbmRlbnQgc2VydmljZSBvZmZlcmluZyB0
aGF0IGNhbiBiZQogcHJvdmlzaW9uZWQgYnkgYSBjdXN0b21lci4KCgoKAwQAARIDIAgWCgsK
AwQABxIEIQImBAoNCgUEAAedCBIEIQImBApvCgQEAAIAEgMqAj0aYiBJZGVudGlmaWVyLiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgTG9naWNhbFByb2R1Y3QuCiBGb3JtYXQ6IGxvZ2lj
YWxQcm9kdWN0cy97bG9naWNhbF9wcm9kdWN0fS4KCgwKBQQAAgAFEgMqAggKDAoFBAACAAES
AyoJDQoMCgUEAAIAAxIDKhARCgwKBQQAAgAIEgMqEjwKDwoIBAACAAicCAASAyoTOwoyCgQE
AAIBEgMtAhMaJSBEaXNwbGF5IG5hbWUgb2YgdGhlIExvZ2ljYWxQcm9kdWN0LgoKDAoFBAAC
AQUSAy0CCAoMCgUEAAIBARIDLQkOCgwKBQQAAgEDEgMtERIKagoEBAACAhIEMQIzBRpcIFBy
b2R1Y3Qgc3VpdGUgYXNzb2NpYXRlZCB3aXRoIHRoZSBsb2dpY2FsIHByb2R1Y3QuCiBGb3Jt
YXQ6IHByb2R1Y3RTdWl0ZXMve3Byb2R1Y3Rfc3VpdGV9LgoKDAoFBAACAgUSAzECCAoMCgUE
AAICARIDMQkWCgwKBQQAAgIDEgMxGRoKDQoFBAACAggSBDEbMwQKDwoHBAACAgifCBIEMRwz
Awp9CgQEAAIDEgQ3AjwEGm8gT3V0cHV0IG9ubHkuIENoaWxkIHZhcmlhbnQgcmVzb3VyY2Ug
cmVmZXJlbmNlcy4KIEZvcm1hdDogbG9naWNhbFByb2R1Y3RzL3tsb2dpY2FsX3Byb2R1Y3R9
L3ZhcmlhbnRzL3t2YXJpYW50fQoKDAoFBAACAwQSAzcCCgoMCgUEAAIDBRIDNwsRCgwKBQQA
AgMBEgM3EhoKDAoFBAACAwMSAzcdHgoNCgUEAAIDCBIENx88AwoPCggEAAIDCJwIABIDOAQt
Cg8KBwQAAgMInwgSBDkEOwUKTAoEBAACBBIEPwJAMho+IE91dHB1dCBvbmx5LiBDdXJyZW50
IExpZmVjeWNsZSBzdGF0ZSBvZiB0aGUgbG9naWNhbCBwcm9kdWN0LgoKDAoFBAACBAYSAz8C
EAoMCgUEAAIEARIDPxEgCgwKBQQAAgQDEgM/IyQKDAoFBAACBAgSA0AGMQoPCggEAAIECJwI
ABIDQAcwCoECCgQEAAIFEgNGAkAa8wEgT3V0cHV0IG9ubHkuIEluZGljYXRlcyB3aGV0aGVy
IHRoZSBsb2dpY2FsIHByb2R1Y3QgaGFzIGJlZW4gcmVwbGFjZWQuIElmCiBgZmFsc2VgLCB0
aGUgcHJvZHVjdCBpcyBhY3RpdmUuIElmIGB0cnVlYCwgdGhlIHByb2R1Y3QgaGFzIGJlZW4g
cmVwbGFjZWQgYnkKIGFub3RoZXIgdHlwZSwgYW5kIHRoZSBgcmVwbGFjZW1lbnRgIGZpZWxk
IGNvbnRhaW5zIHRoZSByZXNvdXJjZSBuYW1lIG9mCiB0aGF0IHJlcGxhY2VtZW50LgoKDAoF
BAACBQUSA0YCBgoMCgUEAAIFARIDRgcPCgwKBQQAAgUDEgNGEhMKDAoFBAACBQgSA0YUPwoP
CggEAAIFCJwIABIDRhU+CqcCCgQEAAIGEgRNAlAEGpgCIE91dHB1dCBvbmx5LiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgTG9naWNhbCBFbnRpdHkgdGhhdCB0aGUgbG9naWNhbAogcHJv
ZHVjdCBpcyByZXBsYWNlZCBieS4gVGhpcyBmaWVsZCBpcyBvbmx5IHBvcHVsYXRlZCB3aGVu
IHRoaXMgbG9naWNhbAogcHJvZHVjdCBpcyByZXBsYWNlZCBieSBzb21lIG90aGVyIHR5cGUu
IEVnOgogbG9naWNhbFByb2R1Y3RzL3tsb2dpY2FsX3Byb2R1Y3R9L3ZhcmlhbnRzL3t2YXJp
YW50fSwKIHByb2R1Y3RTdWl0ZXMve3Byb2R1Y3Rfc3VpdGV9LCBldGMuCgoMCgUEAAIGBRID
TQIICgwKBQQAAgYBEgNNCRQKDAoFBAACBgMSA00XGAoNCgUEAAIGCBIETRlQAwoPCggEAAIG
CJwIABIDTgQtCg4KBwQAAgYInwgSA08EM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct ===
    # Fields for LogicalProduct
    # Field: name Type: 9 ()
    # Field: title Type: 9 ()
    # Field: product_suite Type: 9 ()
    # Field: variants Type: 9 ()
    # Field: lifecycle_state Type: 14 (.google.cloud.productregistry.v1.LifecycleState)
    # Field: replaced Type: 8 ()
    # Field: replacement Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Productregistry::V1::LogicalProduct - Compiled Protocol Buffers messages for google/cloud/productregistry/v1/logical_product.proto

=head1 SYNOPSIS

    use Google::Cloud::Productregistry::V1::LogicalProduct;

    my $msg = Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct->new({
        name => $name,
        title => $title,
        product_suite => $product_suite,
        variants => $variants,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/productregistry/v1/logical_product.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct

Represents an independent service offering that can be
provisioned by a customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the LogicalProduct.
Format: logicalProducts/{logical_product}.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Display name of the LogicalProduct.

=item * C<< $msg->product_suite() >> / C<< $msg->product_suite($value) >>

Type: C<String>

Product suite associated with the logical product.
Format: productSuites/{product_suite}.

=item * C<< $msg->variants() >> / C<< $msg->variants($value) >>

Type: C<String>

Output only. Child variant resource references.
Format: logicalProducts/{logical_product}/variants/{variant}

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Productregistry::V1::LifecycleState>)

Output only. Current Lifecycle state of the logical product.

=item * C<< $msg->replaced() >> / C<< $msg->replaced($value) >>

Type: C<Bool>

Output only. Indicates whether the logical product has been replaced. If
`false`, the product is active. If `true`, the product has been replaced by
another type, and the `replacement` field contains the resource name of
that replacement.

=item * C<< $msg->replacement() >> / C<< $msg->replacement($value) >>

Type: C<String>

Output only. The resource name of the Logical Entity that the logical
product is replaced by. This field is only populated when this logical
product is replaced by some other type. Eg:
logicalProducts/{logical_product}/variants/{variant},
productSuites/{product_suite}, etc.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Productregistry::V1::LogicalProduct::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
