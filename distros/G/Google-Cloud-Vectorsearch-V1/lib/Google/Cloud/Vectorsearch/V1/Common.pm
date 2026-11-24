package Google::Cloud::Vectorsearch::V1::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxL2NvbW1vbi5wcm90bxIcZ29vZ2xlLmNs
b3VkLnZlY3RvcnNlYXJjaC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bypX
Cg5EaXN0YW5jZU1ldHJpYxIfChtESVNUQU5DRV9NRVRSSUNfVU5TUEVDSUZJRUQQABIPCgtE
T1RfUFJPRFVDVBABEhMKD0NPU0lORV9ESVNUQU5DRRACQtcBCiBjb20uZ29vZ2xlLmNsb3Vk
LnZlY3RvcnNlYXJjaC52MUILQ29tbW9uUHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby92
ZWN0b3JzZWFyY2gvYXBpdjEvdmVjdG9yc2VhcmNocGI7dmVjdG9yc2VhcmNocGKqAhxHb29n
bGUuQ2xvdWQuVmVjdG9yU2VhcmNoLlYxygIcR29vZ2xlXENsb3VkXFZlY3RvclNlYXJjaFxW
MeoCH0dvb2dsZTo6Q2xvdWQ6OlZlY3RvclNlYXJjaDo6VjFKlwgKBhIEDgAmAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCggKAQgS
AxQAOQoJCgIIJRIDFAA5CggKAQgSAxUAWwoJCgIICxIDFQBbCggKAQgSAxYAIgoJCgIIChID
FgAiCggKAQgSAxcALAoJCgIICBIDFwAsCggKAQgSAxgAOQoJCgIIARIDGAA5CggKAQgSAxkA
OQoJCgIIKRIDGQA5CggKAQgSAxoAOAoJCgIILRIDGgA4CjAKAgUAEgQdACYBGiQgRGlzdGFu
Y2UgbWV0cmljIGZvciB2ZWN0b3Igc2VhcmNoLgoKCgoDBQABEgMdBRMKPwoEBQACABIDHwIi
GjIgRGVmYXVsdCB2YWx1ZSwgZGlzdGFuY2UgbWV0cmljIGlzIG5vdCBzcGVjaWZpZWQuCgoM
CgUFAAIAARIDHwIdCgwKBQUAAgACEgMfICEKKwoEBQACARIDIgISGh4gRG90IHByb2R1Y3Qg
ZGlzdGFuY2UgbWV0cmljLgoKDAoFBQACAQESAyICDQoMCgUFAAIBAhIDIhARCiYKBAUAAgIS
AyUCFhoZIENvc2luZSBkaXN0YW5jZSBtZXRyaWMuCgoMCgUFAAICARIDJQIRCgwKBQUAAgIC
EgMlFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1::Common - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1/common.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
