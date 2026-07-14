package Google::Api::Control;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Policy };
    my $descriptor_b64 = <<'EOF';
Chhnb29nbGUvYXBpL2NvbnRyb2wucHJvdG8SCmdvb2dsZS5hcGkaF2dvb2dsZS9hcGkvcG9s
aWN5LnByb3RvIm4KB0NvbnRyb2wSIAoLZW52aXJvbm1lbnQYASABKAlSC2Vudmlyb25tZW50
EkEKD21ldGhvZF9wb2xpY2llcxgEIAMoCzIYLmdvb2dsZS5hcGkuTWV0aG9kUG9saWN5Ug5t
ZXRob2RQb2xpY2llc0JuCg5jb20uZ29vZ2xlLmFwaUIMQ29udHJvbFByb3RvUAFaRWdvb2ds
ZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBpL3NlcnZpY2Vjb25maWc7c2Vy
dmljZWNvbmZpZ6ICBEdBUElK9wkKBhIEDgAoAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAEwoJCgIDABIDEgAhCggKAQgSAxQAXAoJCgIICxIDFABcCggK
AQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYALQoJCgIICBIDFgAtCggKAQgSAxcAJwoJCgII
ARIDFwAnCggKAQgSAxgAIgoJCgIIJBIDGAAiCp0BCgIEABIEIAAoARqQASBTZWxlY3RzIGFu
ZCBjb25maWd1cmVzIHRoZSBzZXJ2aWNlIGNvbnRyb2xsZXIgdXNlZCBieSB0aGUgc2Vydmlj
ZS4KCiBFeGFtcGxlOgoKICAgICBjb250cm9sOgogICAgICAgZW52aXJvbm1lbnQ6IHNlcnZp
Y2Vjb250cm9sLmdvb2dsZWFwaXMuY29tCgoKCgMEAAESAyAIDwrUAQoEBAACABIDJAIZGsYB
IFRoZSBzZXJ2aWNlIGNvbnRyb2xsZXIgZW52aXJvbm1lbnQgdG8gdXNlLiBJZiBlbXB0eSwg
bm8gY29udHJvbCBwbGFuZQogZmVhdHVyZXMgKGxpa2UgcXVvdGEgYW5kIGJpbGxpbmcpIHdp
bGwgYmUgZW5hYmxlZC4gVGhlIHJlY29tbWVuZGVkIHZhbHVlCiBmb3IgbW9zdCBzZXJ2aWNl
cyBpcyBzZXJ2aWNlY29udHJvbC5nb29nbGVhcGlzLmNvbS4KCgwKBQQAAgAFEgMkAggKDAoF
BAACAAESAyQJFAoMCgUEAAIAAxIDJBcYCksKBAQAAgESAycCLBo+IERlZmluZXMgcG9saWNp
ZXMgYXBwbHlpbmcgdG8gdGhlIEFQSSBtZXRob2RzIG9mIHRoZSBzZXJ2aWNlLgoKDAoFBAAC
AQQSAycCCgoMCgUEAAIBBhIDJwsXCgwKBQQAAgEBEgMnGCcKDAoFBAACAQMSAycqK2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Api::Control::Control ===
    # Fields for Control
    # Field: environment Type: 9 ()
    # Field: method_policies Type: 11 (.google.api.MethodPolicy)

=pod

=head1 NAME

Google::Api::Control::Control - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Api::Control;

    my $msg = Google::Api::Control::Control->new(
        environment => $value,
    );

=head1 FIELDS

=over 4

=item * B<environment>

Type: String

=item * B<method_policies>

Type: Message (.google.api.MethodPolicy)

=back

=cut

1;
