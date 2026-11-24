package Google::Cloud::Integrations::V1alpha::Product;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvcHJvZHVjdC5wcm90bxIhZ29v
Z2xlLmNsb3VkLmludGVncmF0aW9ucy52MWFscGhhKkQKB1Byb2R1Y3QSFwoTUFJPRFVDVF9V
TlNQRUNJRklFRBAAEgYKAklQEAESCgoGQVBJR0VFEAISDAoIU0VDVVJJVFkQA0KCAQolY29t
Lmdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYUIMUHJvZHVjdFByb3RvUAFaSWNs
b3VkLmdvb2dsZS5jb20vZ28vaW50ZWdyYXRpb25zL2FwaXYxYWxwaGEvaW50ZWdyYXRpb25z
cGI7aW50ZWdyYXRpb25zcGJKxAcKBhIEDgAkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKgoICgEIEgMSAGAKCQoCCAsSAxIAYAoICgEIEgMTACIKCQoC
CAoSAxMAIgoICgEIEgMUAC0KCQoCCAgSAxQALQoICgEIEgMVAD4KCQoCCAESAxUAPgobCgIF
ABIEGAAkARoPIEVudW0gUHJvZHVjdC4KCgoKAwUAARIDGAUMCh0KBAUAAgASAxoCGhoQIERl
ZmF1bHQgdmFsdWUuCgoMCgUFAAIAARIDGgIVCgwKBQUAAgACEgMaGBkKJAoEBQACARIDHQIJ
GhcgSW50ZWdyYXRpb24gUGxhdGZvcm0uCgoMCgUFAAIBARIDHQIECgwKBQUAAgECEgMdBwgK
FgoEBQACAhIDIAINGgkgQXBpZ2VlLgoKDAoFBQACAgESAyACCAoMCgUFAAICAhIDIAsMCicK
BAUAAgMSAyMCDxoaIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyLgoKDAoFBQACAwESAyMCCgoM
CgUFAAIDAhIDIw0OYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::Product - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/product.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/product.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::Product::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
