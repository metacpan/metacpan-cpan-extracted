package Google::Type::Money;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Chdnb29nbGUvdHlwZS9tb25leS5wcm90bxILZ29vZ2xlLnR5cGUiWAoFTW9uZXkSIwoNY3Vy
cmVuY3lfY29kZRgBIAEoCVIMY3VycmVuY3lDb2RlEhQKBXVuaXRzGAIgASgDUgV1bml0cxIU
CgVuYW5vcxgDIAEoBVIFbmFub3NCXQoPY29tLmdvb2dsZS50eXBlQgpNb25leVByb3RvUAFa
Nmdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvdHlwZS9tb25leTttb25l
eaICA0dUUErJCwoGEgQOACgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAUCggKAQgSAxIATQoJCgIICxIDEgBNCggKAQgSAxMAIgoJCgIIChIDEwAiCggK
AQgSAxQAKwoJCgIICBIDFAArCggKAQgSAxUAKAoJCgIIARIDFQAoCggKAQgSAxYAIQoJCgII
JBIDFgAhCkMKAgQAEgQZACgBGjcgUmVwcmVzZW50cyBhbiBhbW91bnQgb2YgbW9uZXkgd2l0
aCBpdHMgY3VycmVuY3kgdHlwZS4KCgoKAwQAARIDGQgNCkIKBAQAAgASAxsCGxo1IFRoZSB0
aHJlZS1sZXR0ZXIgY3VycmVuY3kgY29kZSBkZWZpbmVkIGluIElTTyA0MjE3LgoKDAoFBAAC
AAUSAxsCCAoMCgUEAAIAARIDGwkWCgwKBQQAAgADEgMbGRoKdgoEBAACARIDHwISGmkgVGhl
IHdob2xlIHVuaXRzIG9mIHRoZSBhbW91bnQuCiBGb3IgZXhhbXBsZSBpZiBgY3VycmVuY3lD
b2RlYCBpcyBgIlVTRCJgLCB0aGVuIDEgdW5pdCBpcyBvbmUgVVMgZG9sbGFyLgoKDAoFBAAC
AQUSAx8CBwoMCgUEAAIBARIDHwgNCgwKBQQAAgEDEgMfEBEKgQMKBAQAAgISAycCEhrzAiBO
dW1iZXIgb2YgbmFubyAoMTBeLTkpIHVuaXRzIG9mIHRoZSBhbW91bnQuCiBUaGUgdmFsdWUg
bXVzdCBiZSBiZXR3ZWVuIC05OTksOTk5LDk5OSBhbmQgKzk5OSw5OTksOTk5IGluY2x1c2l2
ZS4KIElmIGB1bml0c2AgaXMgcG9zaXRpdmUsIGBuYW5vc2AgbXVzdCBiZSBwb3NpdGl2ZSBv
ciB6ZXJvLgogSWYgYHVuaXRzYCBpcyB6ZXJvLCBgbmFub3NgIGNhbiBiZSBwb3NpdGl2ZSwg
emVybywgb3IgbmVnYXRpdmUuCiBJZiBgdW5pdHNgIGlzIG5lZ2F0aXZlLCBgbmFub3NgIG11
c3QgYmUgbmVnYXRpdmUgb3IgemVyby4KIEZvciBleGFtcGxlICQtMS43NSBpcyByZXByZXNl
bnRlZCBhcyBgdW5pdHNgPS0xIGFuZCBgbmFub3NgPS03NTAsMDAwLDAwMC4KCgwKBQQAAgIF
EgMnAgcKDAoFBAACAgESAycIDQoMCgUEAAICAxIDJxARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Type::Money::Money ===
    # Fields for Money
    # Field: currency_code Type: 9 ()
    # Field: units Type: 3 ()
    # Field: nanos Type: 5 ()

=pod

=head1 NAME

Google::Type::Money::Money - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Type::Money;

    my $msg = Google::Type::Money::Money->new(
        currency_code => $value,
    );

=head1 FIELDS

=over 4

=item * B<currency_code>

Type: String

=item * B<units>

Type: Int64

=item * B<nanos>

Type: Int32

=back

=cut

1;
