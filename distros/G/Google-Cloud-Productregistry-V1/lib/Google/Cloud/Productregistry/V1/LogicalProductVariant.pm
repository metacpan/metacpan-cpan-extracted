package Google::Cloud::Productregistry::V1::LogicalProductVariant;

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
Cj1nb29nbGUvY2xvdWQvcHJvZHVjdHJlZ2lzdHJ5L3YxL2xvZ2ljYWxfcHJvZHVjdF92YXJp
YW50LnByb3RvEh9nb29nbGUuY2xvdWQucHJvZHVjdHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjVnb29n
bGUvY2xvdWQvcHJvZHVjdHJlZ2lzdHJ5L3YxL2xpZmVjeWNsZV9zdGF0ZS5wcm90byKaAwoV
TG9naWNhbFByb2R1Y3RWYXJpYW50EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIUCgV0aXRs
ZRgCIAEoCVIFdGl0bGUSXQoPbGlmZWN5Y2xlX3N0YXRlGAMgASgOMi8uZ29vZ2xlLmNsb3Vk
LnByb2R1Y3RyZWdpc3RyeS52MS5MaWZlY3ljbGVTdGF0ZUID4EEDUg5saWZlY3ljbGVTdGF0
ZRIfCghyZXBsYWNlZBgEIAEoCEID4EEDUghyZXBsYWNlZBIrCgtyZXBsYWNlbWVudBgFIAEo
CUIJ4EED+kEDCgEqUgtyZXBsYWNlbWVudDqkAepBoAEKOWNsb3VkcHJvZHVjdHJlZ2lzdHJ5
Lmdvb2dsZWFwaXMuY29tL0xvZ2ljYWxQcm9kdWN0VmFyaWFudBI0bG9naWNhbFByb2R1Y3Rz
L3tsb2dpY2FsX3Byb2R1Y3R9L3ZhcmlhbnRzL3t2YXJpYW50fSoWbG9naWNhbFByb2R1Y3RW
YXJpYW50czIVbG9naWNhbFByb2R1Y3RWYXJpYW50QvsBCiNjb20uZ29vZ2xlLmNsb3VkLnBy
b2R1Y3RyZWdpc3RyeS52MUIaTG9naWNhbFByb2R1Y3RWYXJpYW50UHJvdG9QAVpNY2xvdWQu
Z29vZ2xlLmNvbS9nby9wcm9kdWN0cmVnaXN0cnkvYXBpdjEvcHJvZHVjdHJlZ2lzdHJ5cGI7
cHJvZHVjdHJlZ2lzdHJ5cGKqAh9Hb29nbGUuQ2xvdWQuUHJvZHVjdFJlZ2lzdHJ5LlYxygIf
R29vZ2xlXENsb3VkXFByb2R1Y3RSZWdpc3RyeVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OlByb2R1
Y3RSZWdpc3RyeTo6VjFKjREKBhIEDgBDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAPwoICgEI
EgMWADwKCQoCCCUSAxYAPAoICgEIEgMXAGQKCQoCCAsSAxcAZAoICgEIEgMYACIKCQoCCAoS
AxgAIgoICgEIEgMZADsKCQoCCAgSAxkAOwoICgEIEgMaADwKCQoCCAESAxoAPAoICgEIEgMb
ADwKCQoCCCkSAxsAPAoICgEIEgMcADsKCQoCCC0SAxwAOwqvAQoCBAASBCEAQwEaogEgUmVw
cmVzZW50cyBhIGRpc3RpbmN0IG9mZmVyaW5nIGRlcml2ZWQgZnJvbSBhIHByaW1hcnkgcHJv
ZHVjdCB0aGF0IHJldGFpbnMKIGNvcmUgZnVuY3Rpb25hbGl0aWVzIGJ1dCBvZmZlcnMgc3Bl
Y2lhbGl6ZWQgZmVhdHVyZXMgZm9yIGEgc3BlY2lmaWMgbWFya2V0CiBzZWdtZW50LgoKCgoD
BAABEgMhCB0KCwoDBAAHEgQiAicECg0KBQQAB50IEgQiAicECokBCgQEAAIAEgMsAj0afCBJ
ZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgTG9naWNhbFByb2R1Y3RWYXJp
YW50LgogRm9ybWF0OgogbG9naWNhbFByb2R1Y3RzL3tsb2dpY2FsX3Byb2R1Y3R9L3Zhcmlh
bnRzL3t2YXJpYW50fQoKDAoFBAACAAUSAywCCAoMCgUEAAIAARIDLAkNCgwKBQQAAgADEgMs
EBEKDAoFBAACAAgSAywSPAoPCggEAAIACJwIABIDLBM7CjkKBAQAAgESAy8CExosIERpc3Bs
YXkgbmFtZSBvZiB0aGUgTG9naWNhbFByb2R1Y3RWYXJpYW50LgoKDAoFBAACAQUSAy8CCAoM
CgUEAAIBARIDLwkOCgwKBQQAAgEDEgMvERIKVAoEBAACAhIEMgIzMhpGIE91dHB1dCBvbmx5
LiBDdXJyZW50IExpZmVjeWNsZSBzdGF0ZSBvZiB0aGUgbG9naWNhbCBwcm9kdWN0IHZhcmlh
bnQuCgoMCgUEAAICBhIDMgIQCgwKBQQAAgIBEgMyESAKDAoFBAACAgMSAzIjJAoMCgUEAAIC
CBIDMwYxCg8KCAQAAgIInAgAEgMzBzAKiQIKBAQAAgMSAzkCQBr7ASBPdXRwdXQgb25seS4g
SW5kaWNhdGVzIHdoZXRoZXIgdGhlIGxvZ2ljYWwgcHJvZHVjdCB2YXJpYW50IGhhcyBiZWVu
CiByZXBsYWNlZC4gSWYgYGZhbHNlYCwgdGhlIHZhcmlhbnQgaXMgYWN0aXZlLiBJZiBgdHJ1
ZWAsIHRoZSB2YXJpYW50IGhhcwogYmVlbiByZXBsYWNlZCBieSBhbm90aGVyIHR5cGUsIGFu
ZCB0aGUgYHJlcGxhY2VtZW50YCBmaWVsZCBjb250YWlucyB0aGUKIHJlc291cmNlIG5hbWUg
b2YgdGhhdCByZXBsYWNlbWVudC4KCgwKBQQAAgMFEgM5AgYKDAoFBAACAwESAzkHDwoMCgUE
AAIDAxIDORITCgwKBQQAAgMIEgM5FD8KDwoIBAACAwicCAASAzkVPgqjAgoEBAACBBIEPwJC
BBqUAiBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIExvZ2ljYWwgRW50
aXR5IHRoYXQgdGhlIGxvZ2ljYWwKIHByb2R1Y3QgdmFyaWFudCBpcyByZXBsYWNlZCBieS4g
VGhpcyBmaWVsZCBpcyBvbmx5IHBvcHVsYXRlZCB3aGVuIHRoaXMKIGxvZ2ljYWwgcHJvZHVj
dCB2YXJpYW50IGlzIHJlcGxhY2VkIGJ5IHNvbWUgb3RoZXIgdHlwZS4gRWc6CiBsb2dpY2Fs
UHJvZHVjdHMve2xvZ2ljYWxfcHJvZHVjdH0sIHByb2R1Y3RTdWl0ZXMve3Byb2R1Y3Rfc3Vp
dGV9LCBldGMuCgoMCgUEAAIEBRIDPwIICgwKBQQAAgQBEgM/CRQKDAoFBAACBAMSAz8XGAoN
CgUEAAIECBIEPxlCAwoPCggEAAIECJwIABIDQAQtCg4KBwQAAgQInwgSA0EEM2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant ===
    # Fields for LogicalProductVariant
    # Field: name Type: 9 ()
    # Field: title Type: 9 ()
    # Field: lifecycle_state Type: 14 (.google.cloud.productregistry.v1.LifecycleState)
    # Field: replaced Type: 8 ()
    # Field: replacement Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Productregistry::V1::LogicalProductVariant - Compiled Protocol Buffers messages for google/cloud/productregistry/v1/logical_product_variant.proto

=head1 SYNOPSIS

    use Google::Cloud::Productregistry::V1::LogicalProductVariant;

    my $msg = Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant->new({
        name => $name,
        title => $title,
        lifecycle_state => $lifecycle_state,
        replaced => $replaced,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/productregistry/v1/logical_product_variant.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant

Represents a distinct offering derived from a primary product that retains
core functionalities but offers specialized features for a specific market
segment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the LogicalProductVariant.
Format:
logicalProducts/{logical_product}/variants/{variant}

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Display name of the LogicalProductVariant.

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Productregistry::V1::LifecycleState>)

Output only. Current Lifecycle state of the logical product variant.

=item * C<< $msg->replaced() >> / C<< $msg->replaced($value) >>

Type: C<Bool>

Output only. Indicates whether the logical product variant has been
replaced. If `false`, the variant is active. If `true`, the variant has
been replaced by another type, and the `replacement` field contains the
resource name of that replacement.

=item * C<< $msg->replacement() >> / C<< $msg->replacement($value) >>

Type: C<String>

Output only. The resource name of the Logical Entity that the logical
product variant is replaced by. This field is only populated when this
logical product variant is replaced by some other type. Eg:
logicalProducts/{logical_product}, productSuites/{product_suite}, etc.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Productregistry::V1::LogicalProductVariant::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
