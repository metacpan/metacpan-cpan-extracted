package Google::Type::Latlng;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Chhnb29nbGUvdHlwZS9sYXRsbmcucHJvdG8SC2dvb2dsZS50eXBlIkIKBkxhdExuZxIaCghs
YXRpdHVkZRgBIAEoAVIIbGF0aXR1ZGUSHAoJbG9uZ2l0dWRlGAIgASgBUglsb25naXR1ZGVC
YAoPY29tLmdvb2dsZS50eXBlQgtMYXRMbmdQcm90b1ABWjhnb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL3R5cGUvbGF0bG5nO2xhdGxuZ6ICA0dUUEqqCgoGEgQOACMB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAUCggKAQgSAxIA
TwoJCgIICxIDEgBPCggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgSAxQALAoJCgIICBIDFAAs
CggKAQgSAxUAKAoJCgIIARIDFQAoCggKAQgSAxYAIQoJCgIIJBIDFgAhCugCCgIEABIEHQAj
ARrbAiBBbiBvYmplY3QgdGhhdCByZXByZXNlbnRzIGEgbGF0aXR1ZGUvbG9uZ2l0dWRlIHBh
aXIuIFRoaXMgaXMgZXhwcmVzc2VkIGFzIGEKIHBhaXIgb2YgZG91YmxlcyB0byByZXByZXNl
bnQgZGVncmVlcyBsYXRpdHVkZSBhbmQgZGVncmVlcyBsb25naXR1ZGUuIFVubGVzcwogc3Bl
Y2lmaWVkIG90aGVyd2lzZSwgdGhpcyBvYmplY3QgbXVzdCBjb25mb3JtIHRvIHRoZQogPGEg
aHJlZj0iaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvV29ybGRfR2VvZGV0aWNfU3lz
dGVtIzE5ODRfdmVyc2lvbiI+CiBXR1M4NCBzdGFuZGFyZDwvYT4uIFZhbHVlcyBtdXN0IGJl
IHdpdGhpbiBub3JtYWxpemVkIHJhbmdlcy4KCgoKAwQAARIDHQgOCk8KBAQAAgASAx8CFhpC
IFRoZSBsYXRpdHVkZSBpbiBkZWdyZWVzLiBJdCBtdXN0IGJlIGluIHRoZSByYW5nZSBbLTkw
LjAsICs5MC4wXS4KCgwKBQQAAgAFEgMfAggKDAoFBAACAAESAx8JEQoMCgUEAAIAAxIDHxQV
ClIKBAQAAgESAyICFxpFIFRoZSBsb25naXR1ZGUgaW4gZGVncmVlcy4gSXQgbXVzdCBiZSBp
biB0aGUgcmFuZ2UgWy0xODAuMCwgKzE4MC4wXS4KCgwKBQQAAgEFEgMiAggKDAoFBAACAQES
AyIJEgoMCgUEAAIBAxIDIhUWYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Type::Latlng::LatLng ===
    # Fields for LatLng
    # Field: latitude Type: 1 ()
    # Field: longitude Type: 1 ()

=pod

=head1 NAME

Google::Type::Latlng::LatLng - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Type::Latlng;

    my $msg = Google::Type::Latlng::LatLng->new(
        latitude => $value,
    );

=head1 FIELDS

=over 4

=item * B<latitude>

Type: Double

=item * B<longitude>

Type: Double

=back

=cut

1;
