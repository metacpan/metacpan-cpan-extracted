package Google::Type::LocalizedText;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvdHlwZS9sb2NhbGl6ZWRfdGV4dC5wcm90bxILZ29vZ2xlLnR5cGUiSAoNTG9j
YWxpemVkVGV4dBISCgR0ZXh0GAEgASgJUgR0ZXh0EiMKDWxhbmd1YWdlX2NvZGUYAiABKAlS
DGxhbmd1YWdlQ29kZUJ3Cg9jb20uZ29vZ2xlLnR5cGVCEkxvY2FsaXplZFRleHRQcm90b1AB
Wkhnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL3R5cGUvbG9jYWxpemVk
X3RleHQ7bG9jYWxpemVkX3RleHSiAgNHVFBKkQkKBhIEDgAjAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAFAoICgEIEgMSAF8KCQoCCAsSAxIAXwoICgEI
EgMTACIKCQoCCAoSAxMAIgoICgEIEgMUADMKCQoCCAgSAxQAMwoICgEIEgMVACgKCQoCCAES
AxUAKAoICgEIEgMWACEKCQoCCCQSAxYAIQpDCgIEABIEGQAjARo3IExvY2FsaXplZCB2YXJp
YW50IG9mIGEgdGV4dCBpbiBhIHBhcnRpY3VsYXIgbGFuZ3VhZ2UuCgoKCgMEAAESAxkIFQqB
AQoEBAACABIDHAISGnQgTG9jYWxpemVkIHN0cmluZyBpbiB0aGUgbGFuZ3VhZ2UgY29ycmVz
cG9uZGluZyB0bwogW2xhbmd1YWdlX2NvZGVdW2dvb2dsZS50eXBlLkxvY2FsaXplZFRleHQu
bGFuZ3VhZ2VfY29kZV0gYmVsb3cuCgoMCgUEAAIABRIDHAIICgwKBQQAAgABEgMcCQ0KDAoF
BAACAAMSAxwQEQqrAQoEBAACARIDIgIbGp0BIFRoZSB0ZXh0J3MgQkNQLTQ3IGxhbmd1YWdl
IGNvZGUsIHN1Y2ggYXMgImVuLVVTIiBvciAic3ItTGF0biIuCgogRm9yIG1vcmUgaW5mb3Jt
YXRpb24sIHNlZQogaHR0cDovL3d3dy51bmljb2RlLm9yZy9yZXBvcnRzL3RyMzUvI1VuaWNv
ZGVfbG9jYWxlX2lkZW50aWZpZXIuCgoMCgUEAAIBBRIDIgIICgwKBQQAAgEBEgMiCRYKDAoF
BAACAQMSAyIZGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Type::LocalizedText::LocalizedText ===
    # Fields for LocalizedText
    # Field: text Type: 9 ()
    # Field: language_code Type: 9 ()

=pod

=head1 NAME

Google::Type::LocalizedText::LocalizedText - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Type::LocalizedText;

    my $msg = Google::Type::LocalizedText::LocalizedText->new(
        text => $value,
    );

=head1 FIELDS

=over 4

=item * B<text>

Type: String

=item * B<language_code>

Type: String

=back

=cut

1;
