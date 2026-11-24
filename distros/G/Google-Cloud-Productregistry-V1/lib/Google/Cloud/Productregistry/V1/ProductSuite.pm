package Google::Cloud::Productregistry::V1::ProductSuite;

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
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcHJvZHVjdHJlZ2lzdHJ5L3YxL3Byb2R1Y3Rfc3VpdGUucHJvdG8S
H2dvb2dsZS5jbG91ZC5wcm9kdWN0cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i5QIKDFByb2R1Y3RTdWl0
ZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSFAoFdGl0bGUYAiABKAlSBXRpdGxlEmUKEGxv
Z2ljYWxfcHJvZHVjdHMYAyADKAlCOuBBA/pBNAoyY2xvdWRwcm9kdWN0cmVnaXN0cnkuZ29v
Z2xlYXBpcy5jb20vTG9naWNhbFByb2R1Y3RSD2xvZ2ljYWxQcm9kdWN0cxIfCghyZXBsYWNl
ZBgEIAEoCEID4EEDUghyZXBsYWNlZBIrCgtyZXBsYWNlbWVudBgFIAEoCUIJ4EED+kEDCgEq
UgtyZXBsYWNlbWVudDpx6kFuCjBjbG91ZHByb2R1Y3RyZWdpc3RyeS5nb29nbGVhcGlzLmNv
bS9Qcm9kdWN0U3VpdGUSHXByb2R1Y3RTdWl0ZXMve3Byb2R1Y3Rfc3VpdGV9Kg1wcm9kdWN0
U3VpdGVzMgxwcm9kdWN0U3VpdGVC8gEKI2NvbS5nb29nbGUuY2xvdWQucHJvZHVjdHJlZ2lz
dHJ5LnYxQhFQcm9kdWN0U3VpdGVQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL3Byb2R1
Y3RyZWdpc3RyeS9hcGl2MS9wcm9kdWN0cmVnaXN0cnlwYjtwcm9kdWN0cmVnaXN0cnlwYqoC
H0dvb2dsZS5DbG91ZC5Qcm9kdWN0UmVnaXN0cnkuVjHKAh9Hb29nbGVcQ2xvdWRcUHJvZHVj
dFJlZ2lzdHJ5XFYx6gIiR29vZ2xlOjpDbG91ZDo6UHJvZHVjdFJlZ2lzdHJ5OjpWMUrBEAoG
EgQOAEUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADwKCQoCCCUSAxUAPAoICgEIEgMWAGQKCQoC
CAsSAxYAZAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADIKCQoCCAgSAxgAMgoICgEI
EgMZADwKCQoCCAESAxkAPAoICgEIEgMaADwKCQoCCCkSAxoAPAoICgEIEgMbADsKCQoCCC0S
AxsAOwpnCgIEABIEHwBFARpbIFJlcHJlc2VudHMgYSB1bmlmaWVkIGdyb3VwaW5nIG9mIHBy
b2R1Y3RzIHNoYXJpbmcgYSBjb21tb24gYnJhbmQgYW5kIG1hcmtldAogcG9zaXRpb25pbmcu
CgoKCgMEAAESAx8IFAoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKaAoEBAACABIDKQI9
GlsgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFByb2R1Y3RTdWl0ZS4K
IEZvcm1hdDogcHJvZHVjdFN1aXRlcy97cHJvZHVjdF9zdWl0ZX0KCgwKBQQAAgAFEgMpAggK
DAoFBAACAAESAykJDQoMCgUEAAIAAxIDKRARCgwKBQQAAgAIEgMpEjwKDwoIBAACAAicCAAS
AykTOwopCgQEAAIBEgMsAhMaHCBUaXRsZSBvZiB0aGUgUHJvZHVjdFN1aXRlLgoKDAoFBAAC
AQUSAywCCAoMCgUEAAIBARIDLAkOCgwKBQQAAgEDEgMsERIKaQoEBAACAhIEMAI1BBpbIE91
dHB1dCBvbmx5LiBMb2dpY2FsUHJvZHVjdHMgdW5kZXIgdGhpcyBzdWl0ZS4KIEZvcm1hdDog
bG9naWNhbFByb2R1Y3RzL3tsb2dpY2FsX3Byb2R1Y3R9CgoMCgUEAAICBBIDMAIKCgwKBQQA
AgIFEgMwCxEKDAoFBAACAgESAzASIgoMCgUEAAICAxIDMCUmCg0KBQQAAgIIEgQwJzUDCg8K
CAQAAgIInAgAEgMxBC0KDwoHBAACAgifCBIEMgQ0BQqLAgoEBAACAxIDOwJAGv0BIE91dHB1
dCBvbmx5LiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgcHJvZHVjdCBzdWl0ZSBoYXMgYmVlbiBy
ZXBsYWNlZC4gSWYKIGBmYWxzZWAsIHRoZSBwcm9kdWN0IHN1aXRlIGlzIGFjdGl2ZS4gSWYg
YHRydWVgLCB0aGUgcHJvZHVjdCBzdWl0ZSBoYXMgYmVlbgogcmVwbGFjZWQgYnkgYW5vdGhl
ciB0eXBlLCBhbmQgdGhlIGByZXBsYWNlbWVudGAgZmllbGQgY29udGFpbnMgdGhlIHJlc291
cmNlCiBuYW1lIG9mIHRoYXQgcmVwbGFjZW1lbnQuCgoMCgUEAAIDBRIDOwIGCgwKBQQAAgMB
EgM7Bw8KDAoFBAACAwMSAzsSEwoMCgUEAAIDCBIDOxQ/Cg8KCAQAAgMInAgAEgM7FT4KpgIK
BAQAAgQSBEECRAQalwIgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBM
b2dpY2FsIEVudGl0eSB0aGF0IHRoZSBwcm9kdWN0IHN1aXRlCiBpcyByZXBsYWNlZCBieS4g
VGhpcyBmaWVsZCBpcyBvbmx5IHBvcHVsYXRlZCB3aGVuIHRoaXMgcHJvZHVjdCBzdWl0ZSBp
cwogcmVwbGFjZWQgYnkgc29tZSBvdGhlciB0eXBlLiBFZzogbG9naWNhbFByb2R1Y3RzL3ts
b2dpY2FsX3Byb2R1Y3R9LAogbG9naWNhbFByb2R1Y3RzL3tsb2dpY2FsX3Byb2R1Y3R9L3Zh
cmlhbnRzL3t2YXJpYW50fSwgZXRjLgoKDAoFBAACBAUSA0ECCAoMCgUEAAIEARIDQQkUCgwK
BQQAAgQDEgNBFxgKDQoFBAACBAgSBEEZRAMKDwoIBAACBAicCAASA0IELQoOCgcEAAIECJ8I
EgNDBDNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite ===
    # Fields for ProductSuite
    # Field: name Type: 9 ()
    # Field: title Type: 9 ()
    # Field: logical_products Type: 9 ()
    # Field: replaced Type: 8 ()
    # Field: replacement Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Productregistry::V1::ProductSuite - Compiled Protocol Buffers messages for google/cloud/productregistry/v1/product_suite.proto

=head1 SYNOPSIS

    use Google::Cloud::Productregistry::V1::ProductSuite;

    my $msg = Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite->new({
        name => $name,
        title => $title,
        logical_products => $logical_products,
        replaced => $replaced,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/productregistry/v1/product_suite.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite

Represents a unified grouping of products sharing a common brand and market
positioning.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the ProductSuite.
Format: productSuites/{product_suite}

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Title of the ProductSuite.

=item * C<< $msg->logical_products() >> / C<< $msg->logical_products($value) >>

Type: C<String>

Output only. LogicalProducts under this suite.
Format: logicalProducts/{logical_product}

=item * C<< $msg->replaced() >> / C<< $msg->replaced($value) >>

Type: C<Bool>

Output only. Indicates whether the product suite has been replaced. If
`false`, the product suite is active. If `true`, the product suite has been
replaced by another type, and the `replacement` field contains the resource
name of that replacement.

=item * C<< $msg->replacement() >> / C<< $msg->replacement($value) >>

Type: C<String>

Output only. The resource name of the Logical Entity that the product suite
is replaced by. This field is only populated when this product suite is
replaced by some other type. Eg: logicalProducts/{logical_product},
logicalProducts/{logical_product}/variants/{variant}, etc.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Productregistry::V1::ProductSuite::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
