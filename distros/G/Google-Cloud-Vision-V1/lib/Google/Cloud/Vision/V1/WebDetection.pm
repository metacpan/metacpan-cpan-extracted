package Google::Cloud::Vision::V1::WebDetection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvdmlzaW9uL3YxL3dlYl9kZXRlY3Rpb24ucHJvdG8SFmdvb2dsZS5j
bG91ZC52aXNpb24udjEizggKDFdlYkRldGVjdGlvbhJRCgx3ZWJfZW50aXRpZXMYASADKAsy
Li5nb29nbGUuY2xvdWQudmlzaW9uLnYxLldlYkRldGVjdGlvbi5XZWJFbnRpdHlSC3dlYkVu
dGl0aWVzEl8KFGZ1bGxfbWF0Y2hpbmdfaW1hZ2VzGAIgAygLMi0uZ29vZ2xlLmNsb3VkLnZp
c2lvbi52MS5XZWJEZXRlY3Rpb24uV2ViSW1hZ2VSEmZ1bGxNYXRjaGluZ0ltYWdlcxJlChdw
YXJ0aWFsX21hdGNoaW5nX2ltYWdlcxgDIAMoCzItLmdvb2dsZS5jbG91ZC52aXNpb24udjEu
V2ViRGV0ZWN0aW9uLldlYkltYWdlUhVwYXJ0aWFsTWF0Y2hpbmdJbWFnZXMSaQoacGFnZXNf
d2l0aF9tYXRjaGluZ19pbWFnZXMYBCADKAsyLC5nb29nbGUuY2xvdWQudmlzaW9uLnYxLldl
YkRldGVjdGlvbi5XZWJQYWdlUhdwYWdlc1dpdGhNYXRjaGluZ0ltYWdlcxJlChd2aXN1YWxs
eV9zaW1pbGFyX2ltYWdlcxgGIAMoCzItLmdvb2dsZS5jbG91ZC52aXNpb24udjEuV2ViRGV0
ZWN0aW9uLldlYkltYWdlUhV2aXN1YWxseVNpbWlsYXJJbWFnZXMSWQoRYmVzdF9ndWVzc19s
YWJlbHMYCCADKAsyLS5nb29nbGUuY2xvdWQudmlzaW9uLnYxLldlYkRldGVjdGlvbi5XZWJM
YWJlbFIPYmVzdEd1ZXNzTGFiZWxzGmAKCVdlYkVudGl0eRIbCgllbnRpdHlfaWQYASABKAlS
CGVudGl0eUlkEhQKBXNjb3JlGAIgASgCUgVzY29yZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVIL
ZGVzY3JpcHRpb24aMgoIV2ViSW1hZ2USEAoDdXJsGAEgASgJUgN1cmwSFAoFc2NvcmUYAiAB
KAJSBXNjb3JlGpgCCgdXZWJQYWdlEhAKA3VybBgBIAEoCVIDdXJsEhQKBXNjb3JlGAIgASgC
UgVzY29yZRIdCgpwYWdlX3RpdGxlGAMgASgJUglwYWdlVGl0bGUSXwoUZnVsbF9tYXRjaGlu
Z19pbWFnZXMYBCADKAsyLS5nb29nbGUuY2xvdWQudmlzaW9uLnYxLldlYkRldGVjdGlvbi5X
ZWJJbWFnZVISZnVsbE1hdGNoaW5nSW1hZ2VzEmUKF3BhcnRpYWxfbWF0Y2hpbmdfaW1hZ2Vz
GAUgAygLMi0uZ29vZ2xlLmNsb3VkLnZpc2lvbi52MS5XZWJEZXRlY3Rpb24uV2ViSW1hZ2VS
FXBhcnRpYWxNYXRjaGluZ0ltYWdlcxpFCghXZWJMYWJlbBIUCgVsYWJlbBgBIAEoCVIFbGFi
ZWwSIwoNbGFuZ3VhZ2VfY29kZRgCIAEoCVIMbGFuZ3VhZ2VDb2RlQnIKGmNvbS5nb29nbGUu
Y2xvdWQudmlzaW9uLnYxQhFXZWJEZXRlY3Rpb25Qcm90b1ABWjVjbG91ZC5nb29nbGUuY29t
L2dvL3Zpc2lvbi92Mi9hcGl2MS92aXNpb25wYjt2aXNpb25wYvgBAaICBEdDVk5KhB0KBhIE
DgBnAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoICgEI
EgMSAB8KCQoCCB8SAxIAHwoICgEIEgMTAEwKCQoCCAsSAxMATAoICgEIEgMUACIKCQoCCAoS
AxQAIgoICgEIEgMVADIKCQoCCAgSAxUAMgoICgEIEgMWADMKCQoCCAESAxYAMwoICgEIEgMX
ACIKCQoCCCQSAxcAIgpDCgIEABIEGgBnARo3IFJlbGV2YW50IGluZm9ybWF0aW9uIGZvciB0
aGUgaW1hZ2UgZnJvbSB0aGUgSW50ZXJuZXQuCgoKCgMEAAESAxoIFApDCgQEAAMAEgQcAiYD
GjUgRW50aXR5IGRlZHVjZWQgZnJvbSBzaW1pbGFyIGltYWdlcyBvbiB0aGUgSW50ZXJuZXQu
CgoMCgUEAAMAARIDHAoTCiIKBgQAAwACABIDHgQZGhMgT3BhcXVlIGVudGl0eSBJRC4KCg4K
BwQAAwACAAUSAx4ECgoOCgcEAAMAAgABEgMeCxQKDgoHBAADAAIAAxIDHhcYCnsKBgQAAwAC
ARIDIgQUGmwgT3ZlcmFsbCByZWxldmFuY3kgc2NvcmUgZm9yIHRoZSBlbnRpdHkuCiBOb3Qg
bm9ybWFsaXplZCBhbmQgbm90IGNvbXBhcmFibGUgYWNyb3NzIGRpZmZlcmVudCBpbWFnZSBx
dWVyaWVzLgoKDgoHBAADAAIBBRIDIgQJCg4KBwQAAwACAQESAyIKDwoOCgcEAAMAAgEDEgMi
EhMKQQoGBAADAAICEgMlBBsaMiBDYW5vbmljYWwgZGVzY3JpcHRpb24gb2YgdGhlIGVudGl0
eSwgaW4gRW5nbGlzaC4KCg4KBwQAAwACAgUSAyUECgoOCgcEAAMAAgIBEgMlCxYKDgoHBAAD
AAICAxIDJRkaCisKBAQAAwESBCkCLwMaHSBNZXRhZGF0YSBmb3Igb25saW5lIGltYWdlcy4K
CgwKBQQAAwEBEgMpChIKJgoGBAADAQIAEgMrBBMaFyBUaGUgcmVzdWx0IGltYWdlIFVSTC4K
Cg4KBwQAAwECAAUSAysECgoOCgcEAAMBAgABEgMrCw4KDgoHBAADAQIAAxIDKxESCkQKBgQA
AwECARIDLgQUGjUgKERlcHJlY2F0ZWQpIE92ZXJhbGwgcmVsZXZhbmN5IHNjb3JlIGZvciB0
aGUgaW1hZ2UuCgoOCgcEAAMBAgEFEgMuBAkKDgoHBAADAQIBARIDLgoPCg4KBwQAAwECAQMS
Ay4SEwonCgQEAAMCEgQyAkUDGhkgTWV0YWRhdGEgZm9yIHdlYiBwYWdlcy4KCgwKBQQAAwIB
EgMyChEKKQoGBAADAgIAEgM0BBMaGiBUaGUgcmVzdWx0IHdlYiBwYWdlIFVSTC4KCg4KBwQA
AwICAAUSAzQECgoOCgcEAAMCAgABEgM0Cw4KDgoHBAADAgIAAxIDNBESCkcKBgQAAwICARID
NwQUGjggKERlcHJlY2F0ZWQpIE92ZXJhbGwgcmVsZXZhbmN5IHNjb3JlIGZvciB0aGUgd2Vi
IHBhZ2UuCgoOCgcEAAMCAgEFEgM3BAkKDgoHBAADAgIBARIDNwoPCg4KBwQAAwICAQMSAzcS
EwpCCgYEAAMCAgISAzoEGhozIFRpdGxlIGZvciB0aGUgd2ViIHBhZ2UsIG1heSBjb250YWlu
IEhUTUwgbWFya3Vwcy4KCg4KBwQAAwICAgUSAzoECgoOCgcEAAMCAgIBEgM6CxUKDgoHBAAD
AgICAxIDOhgZCmMKBgQAAwICAxIDPgQvGlQgRnVsbHkgbWF0Y2hpbmcgaW1hZ2VzIG9uIHRo
ZSBwYWdlLgogQ2FuIGluY2x1ZGUgcmVzaXplZCBjb3BpZXMgb2YgdGhlIHF1ZXJ5IGltYWdl
LgoKDgoHBAADAgIDBBIDPgQMCg4KBwQAAwICAwYSAz4NFQoOCgcEAAMCAgMBEgM+FioKDgoH
BAADAgIDAxIDPi0uCsoBCgYEAAMCAgQSA0QEMhq6ASBQYXJ0aWFsIG1hdGNoaW5nIGltYWdl
cyBvbiB0aGUgcGFnZS4KIFRob3NlIGltYWdlcyBhcmUgc2ltaWxhciBlbm91Z2ggdG8gc2hh
cmUgc29tZSBrZXktcG9pbnQgZmVhdHVyZXMuIEZvcgogZXhhbXBsZSBhbiBvcmlnaW5hbCBp
bWFnZSB3aWxsIGxpa2VseSBoYXZlIHBhcnRpYWwgbWF0Y2hpbmcgZm9yIGl0cwogY3JvcHMu
CgoOCgcEAAMCAgQEEgNEBAwKDgoHBAADAgIEBhIDRA0VCg4KBwQAAwICBAESA0QWLQoOCgcE
AAMCAgQDEgNEMDEKRgoEBAADAxIESAJQAxo4IExhYmVsIHRvIHByb3ZpZGUgZXh0cmEgbWV0
YWRhdGEgZm9yIHRoZSB3ZWIgZGV0ZWN0aW9uLgoKDAoFBAADAwESA0gKEgoqCgYEAAMDAgAS
A0oEFRobIExhYmVsIGZvciBleHRyYSBtZXRhZGF0YS4KCg4KBwQAAwMCAAUSA0oECgoOCgcE
AAMDAgABEgNKCxAKDgoHBAADAwIAAxIDShMUCrEBCgYEAAMDAgESA08EHRqhASBUaGUgQkNQ
LTQ3IGxhbmd1YWdlIGNvZGUgZm9yIGBsYWJlbGAsIHN1Y2ggYXMgImVuLVVTIiBvciAic3It
TGF0biIuCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlCiBodHRwOi8vd3d3LnVuaWNvZGUu
b3JnL3JlcG9ydHMvdHIzNS8jVW5pY29kZV9sb2NhbGVfaWRlbnRpZmllci4KCg4KBwQAAwMC
AQUSA08ECgoOCgcEAAMDAgEBEgNPCxgKDgoHBAADAwIBAxIDTxscCkQKBAQAAgASA1MCJho3
IERlZHVjZWQgZW50aXRpZXMgZnJvbSBzaW1pbGFyIGltYWdlcyBvbiB0aGUgSW50ZXJuZXQu
CgoMCgUEAAIABBIDUwIKCgwKBQQAAgAGEgNTCxQKDAoFBAACAAESA1MVIQoMCgUEAAIAAxID
UyQlCmcKBAQAAgESA1cCLRpaIEZ1bGx5IG1hdGNoaW5nIGltYWdlcyBmcm9tIHRoZSBJbnRl
cm5ldC4KIENhbiBpbmNsdWRlIHJlc2l6ZWQgY29waWVzIG9mIHRoZSBxdWVyeSBpbWFnZS4K
CgwKBQQAAgEEEgNXAgoKDAoFBAACAQYSA1cLEwoMCgUEAAIBARIDVxQoCgwKBQQAAgEDEgNX
KywKzQEKBAQAAgISA1wCMBq/ASBQYXJ0aWFsIG1hdGNoaW5nIGltYWdlcyBmcm9tIHRoZSBJ
bnRlcm5ldC4KIFRob3NlIGltYWdlcyBhcmUgc2ltaWxhciBlbm91Z2ggdG8gc2hhcmUgc29t
ZSBrZXktcG9pbnQgZmVhdHVyZXMuIEZvcgogZXhhbXBsZSBhbiBvcmlnaW5hbCBpbWFnZSB3
aWxsIGxpa2VseSBoYXZlIHBhcnRpYWwgbWF0Y2hpbmcgZm9yIGl0cyBjcm9wcy4KCgwKBQQA
AgIEEgNcAgoKDAoFBAACAgYSA1wLEwoMCgUEAAICARIDXBQrCgwKBQQAAgIDEgNcLi8KSgoE
BAACAxIDXwIyGj0gV2ViIHBhZ2VzIGNvbnRhaW5pbmcgdGhlIG1hdGNoaW5nIGltYWdlcyBm
cm9tIHRoZSBJbnRlcm5ldC4KCgwKBQQAAgMEEgNfAgoKDAoFBAACAwYSA18LEgoMCgUEAAID
ARIDXxMtCgwKBQQAAgMDEgNfMDEKMgoEBAACBBIDYgIwGiUgVGhlIHZpc3VhbGx5IHNpbWls
YXIgaW1hZ2UgcmVzdWx0cy4KCgwKBQQAAgQEEgNiAgoKDAoFBAACBAYSA2ILEwoMCgUEAAIE
ARIDYhQrCgwKBQQAAgQDEgNiLi8KfAoEBAACBRIDZgIqGm8gVGhlIHNlcnZpY2UncyBiZXN0
IGd1ZXNzIGFzIHRvIHRoZSB0b3BpYyBvZiB0aGUgcmVxdWVzdCBpbWFnZS4KIEluZmVycmVk
IGZyb20gc2ltaWxhciBpbWFnZXMgb24gdGhlIG9wZW4gd2ViLgoKDAoFBAACBQQSA2YCCgoM
CgUEAAIFBhIDZgsTCgwKBQQAAgUBEgNmFCUKDAoFBAACBQMSA2YoKWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vision::V1::WebDetection::WebDetection ===
    # Fields for WebDetection
    # Field: web_entities Type: 11 (.google.cloud.vision.v1.WebDetection.WebEntity)
    # Field: full_matching_images Type: 11 (.google.cloud.vision.v1.WebDetection.WebImage)
    # Field: partial_matching_images Type: 11 (.google.cloud.vision.v1.WebDetection.WebImage)
    # Field: pages_with_matching_images Type: 11 (.google.cloud.vision.v1.WebDetection.WebPage)
    # Field: visually_similar_images Type: 11 (.google.cloud.vision.v1.WebDetection.WebImage)
    # Field: best_guess_labels Type: 11 (.google.cloud.vision.v1.WebDetection.WebLabel)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vision::V1::WebDetection - Compiled Protocol Buffers messages for google/cloud/vision/v1/web_detection.proto

=head1 SYNOPSIS

    use Google::Cloud::Vision::V1::WebDetection;

    my $msg = Google::Cloud::Vision::V1::WebDetection::WebDetection->new({
        web_entities => $web_entities,
        full_matching_images => $full_matching_images,
        partial_matching_images => $partial_matching_images,
        pages_with_matching_images => $pages_with_matching_images,
    });

    # Read or update a field
    my $val = $msg->web_entities();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vision::V1::WebDetection::WebDetection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vision/v1/web_detection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vision::V1::WebDetection::WebDetection

Relevant information for the image from the Internet.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->web_entities() >> / C<< $msg->web_entities($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::WebDetection::WebDetection::WebEntity>)

Deduced entities from similar images on the Internet.

=item * C<< $msg->full_matching_images() >> / C<< $msg->full_matching_images($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::WebDetection::WebDetection::WebImage>)

Fully matching images from the Internet.
Can include resized copies of the query image.

=item * C<< $msg->partial_matching_images() >> / C<< $msg->partial_matching_images($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::WebDetection::WebDetection::WebImage>)

Partial matching images from the Internet.
Those images are similar enough to share some key-point features. For
example an original image will likely have partial matching for its crops.

=item * C<< $msg->pages_with_matching_images() >> / C<< $msg->pages_with_matching_images($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::WebDetection::WebDetection::WebPage>)

Web pages containing the matching images from the Internet.

=item * C<< $msg->visually_similar_images() >> / C<< $msg->visually_similar_images($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::WebDetection::WebDetection::WebImage>)

The visually similar image results.

=item * C<< $msg->best_guess_labels() >> / C<< $msg->best_guess_labels($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::WebDetection::WebDetection::WebLabel>)

The service's best guess as to the topic of the request image.
Inferred from similar images on the open web.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vision::V1::WebDetection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
