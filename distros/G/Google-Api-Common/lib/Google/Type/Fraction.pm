package Google::Type::Fraction;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Chpnb29nbGUvdHlwZS9mcmFjdGlvbi5wcm90bxILZ29vZ2xlLnR5cGUiSgoIRnJhY3Rpb24S
HAoJbnVtZXJhdG9yGAEgASgDUgludW1lcmF0b3ISIAoLZGVub21pbmF0b3IYAiABKANSC2Rl
bm9taW5hdG9yQmYKD2NvbS5nb29nbGUudHlwZUINRnJhY3Rpb25Qcm90b1ABWjxnb29nbGUu
Z29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL3R5cGUvZnJhY3Rpb247ZnJhY3Rpb26i
AgNHVFBKjggKBhIEDgAgAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAFAoICgEIEgMSAFMKCQoCCAsSAxIAUwoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEI
EgMUAC4KCQoCCAgSAxQALgoICgEIEgMVACgKCQoCCAESAxUAKAoICgEIEgMWACEKCQoCCCQS
AxYAIQpVCgIEABIEGQAgARpJIFJlcHJlc2VudHMgYSBmcmFjdGlvbiBpbiB0ZXJtcyBvZiBh
IG51bWVyYXRvciBkaXZpZGVkIGJ5IGEgZGVub21pbmF0b3IuCgoKCgMEAAESAxkIEAo8CgQE
AAIAEgMbAhYaLyBUaGUgbnVtZXJhdG9yIGluIHRoZSBmcmFjdGlvbiwgZS5nLiAyIGluIDIv
My4KCgwKBQQAAgAFEgMbAgcKDAoFBAACAAESAxsIEQoMCgUEAAIAAxIDGxQVCl0KBAQAAgES
Ax8CGBpQIFRoZSB2YWx1ZSBieSB3aGljaCB0aGUgbnVtZXJhdG9yIGlzIGRpdmlkZWQsIGUu
Zy4gMyBpbiAyLzMuIE11c3QgYmUKIHBvc2l0aXZlLgoKDAoFBAACAQUSAx8CBwoMCgUEAAIB
ARIDHwgTCgwKBQQAAgEDEgMfFhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Type::Fraction::Fraction ===
    # Fields for Fraction
    # Field: numerator Type: 3 ()
    # Field: denominator Type: 3 ()

=pod

=head1 NAME

Google::Type::Fraction::Fraction - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Type::Fraction;

    my $msg = Google::Type::Fraction::Fraction->new(
        numerator => $value,
    );

=head1 FIELDS

=over 4

=item * B<numerator>

Type: Int64

=item * B<denominator>

Type: Int64

=back

=cut

1;
