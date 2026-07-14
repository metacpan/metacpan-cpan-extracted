package Google::Api::Label;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChZnb29nbGUvYXBpL2xhYmVsLnByb3RvEgpnb29nbGUuYXBpIrkBCg9MYWJlbERlc2NyaXB0
b3ISEAoDa2V5GAEgASgJUgNrZXkSRAoKdmFsdWVfdHlwZRgCIAEoDjIlLmdvb2dsZS5hcGku
TGFiZWxEZXNjcmlwdG9yLlZhbHVlVHlwZVIJdmFsdWVUeXBlEiAKC2Rlc2NyaXB0aW9uGAMg
ASgJUgtkZXNjcmlwdGlvbiIsCglWYWx1ZVR5cGUSCgoGU1RSSU5HEAASCAoEQk9PTBABEgkK
BUlOVDY0EAJCXAoOY29tLmdvb2dsZS5hcGlCCkxhYmVsUHJvdG9QAVo1Z29vZ2xlLmdvbGFu
Zy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hcGkvbGFiZWw7bGFiZWyiAgRHQVBJSs8KCgYS
BA4ALgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABMKCAoB
CBIDEgBMCgkKAggLEgMSAEwKCAoBCBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAArCgkKAggI
EgMUACsKCAoBCBIDFQAnCgkKAggBEgMVACcKCAoBCBIDFgAiCgkKAggkEgMWACIKJwoCBAAS
BBkALgEaGyBBIGRlc2NyaXB0aW9uIG9mIGEgbGFiZWwuCgoKCgMEAAESAxkIFwo9CgQEAAQA
EgQbAiQDGi8gVmFsdWUgdHlwZXMgdGhhdCBjYW4gYmUgdXNlZCBhcyBsYWJlbCB2YWx1ZXMu
CgoMCgUEAAQAARIDGwcQCj8KBgQABAACABIDHQQPGjAgQSB2YXJpYWJsZS1sZW5ndGggc3Ry
aW5nLiBUaGlzIGlzIHRoZSBkZWZhdWx0LgoKDgoHBAAEAAIAARIDHQQKCg4KBwQABAACAAIS
Ax0NDgooCgYEAAQAAgESAyAEDRoZIEJvb2xlYW47IHRydWUgb3IgZmFsc2UuCgoOCgcEAAQA
AgEBEgMgBAgKDgoHBAAEAAIBAhIDIAsMCikKBgQABAACAhIDIwQOGhogQSA2NC1iaXQgc2ln
bmVkIGludGVnZXIuCgoOCgcEAAQAAgIBEgMjBAkKDgoHBAAEAAICAhIDIwwNCh0KBAQAAgAS
AycCERoQIFRoZSBsYWJlbCBrZXkuCgoMCgUEAAIABRIDJwIICgwKBQQAAgABEgMnCQwKDAoF
BAACAAMSAycPEApCCgQEAAIBEgMqAhsaNSBUaGUgdHlwZSBvZiBkYXRhIHRoYXQgY2FuIGJl
IGFzc2lnbmVkIHRvIHRoZSBsYWJlbC4KCgwKBQQAAgEGEgMqAgsKDAoFBAACAQESAyoMFgoM
CgUEAAIBAxIDKhkaCjoKBAQAAgISAy0CGRotIEEgaHVtYW4tcmVhZGFibGUgZGVzY3JpcHRp
b24gZm9yIHRoZSBsYWJlbC4KCgwKBQQAAgIFEgMtAggKDAoFBAACAgESAy0JFAoMCgUEAAIC
AxIDLRcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Api::Label::LabelDescriptor ===
    # Fields for LabelDescriptor
    # Field: key Type: 9 ()
    # Field: value_type Type: 14 (.google.api.LabelDescriptor.ValueType)
    # Field: description Type: 9 ()

=pod

=head1 NAME

Google::Api::Label::LabelDescriptor - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Api::Label;

    my $msg = Google::Api::Label::LabelDescriptor->new(
        key => $value,
    );

=head1 FIELDS

=over 4

=item * B<key>

Type: String

=item * B<value_type>

Type: Enum (.google.api.LabelDescriptor.ValueType)

=item * B<description>

Type: String

=back

=cut

# Enum: LabelDescriptor::ValueType
our $LabelDescriptor_STRING = 0;
our $LabelDescriptor_BOOL = 1;
our $LabelDescriptor_INT64 = 2;

=pod

=head2 Enum: LabelDescriptor::ValueType

Values:

=over 4

=item * C<STRING> => 0

=item * C<BOOL> => 1

=item * C<INT64> => 2

=back

=cut

1;
