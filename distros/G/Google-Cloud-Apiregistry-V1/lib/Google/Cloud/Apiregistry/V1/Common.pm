package Google::Cloud::Apiregistry::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYXBpcmVnaXN0cnkvdjEvY29tbW9uLnByb3RvEhtnb29nbGUuY2xv
dWQuYXBpcmVnaXN0cnkudjEqOQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdF
TkFCTEVEEAESDAoIRElTQUJMRUQQAkLQAQofY29tLmdvb2dsZS5jbG91ZC5hcGlyZWdpc3Ry
eS52MUILQ29tbW9uUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9hcGlyZWdpc3RyeS9h
cGl2MS9hcGlyZWdpc3RyeXBiO2FwaXJlZ2lzdHJ5cGKqAhtHb29nbGUuQ2xvdWQuQXBpUmVn
aXN0cnkuVjHKAhtHb29nbGVcQ2xvdWRcQXBpUmVnaXN0cnlcVjHqAh5Hb29nbGU6OkNsb3Vk
OjpBcGlSZWdpc3RyeTo6VjFK/QcKBhIEDgAkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
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
TGljZW5zZS4KCggKAQISAxAAJAoICgEIEgMSADgKCQoCCCUSAxIAOAoICgEIEgMTAFgKCQoC
CAsSAxMAWAoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVACwKCQoCCAgSAxUALAoICgEI
EgMWADgKCQoCCAESAxYAOAoICgEIEgMXADgKCQoCCCkSAxcAOAoICgEIEgMYADcKCQoCCC0S
AxgANwouCgIFABIEGwAkARoiIFRoZSBzdGF0ZSBvZiBNY3BTZXJ2ZXIgcmVzb3VyY2UuCgoK
CgMFAAESAxsFCgoyCgQFAAIAEgMdAhgaJSBUaGUgTWNwU2VydmVyIHN0YXRlIGlzIHVuc3Bl
Y2lmaWVkLgoKDAoFBQACAAESAx0CEwoMCgUFAAIAAhIDHRYXCigKBAUAAgESAyACDhobIFRo
ZSBNY3BTZXJ2ZXIgaXMgZW5hYmxlZC4KCgwKBQUAAgEBEgMgAgkKDAoFBQACAQISAyAMDQop
CgQFAAICEgMjAg8aHCBUaGUgTWNwU2VydmVyIGlzIGRpc2FibGVkLgoKDAoFBQACAgESAyMC
CgoMCgUFAAICAhIDIw0OYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apiregistry::V1::Common - Compiled Protocol Buffers messages for google/cloud/apiregistry/v1/common.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apiregistry/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apiregistry::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
