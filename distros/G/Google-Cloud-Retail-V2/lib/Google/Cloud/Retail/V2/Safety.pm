package Google::Cloud::Retail::V2::Safety;

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
CiNnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3NhZmV0eS5wcm90bxIWZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byLyAwoNU2FmZXR5U2V0
dGluZxJACghjYXRlZ29yeRgBIAEoDjIkLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuSGFybUNh
dGVnb3J5UghjYXRlZ29yeRJWCgl0aHJlc2hvbGQYAiABKA4yOC5nb29nbGUuY2xvdWQucmV0
YWlsLnYyLlNhZmV0eVNldHRpbmcuSGFybUJsb2NrVGhyZXNob2xkUgl0aHJlc2hvbGQSUgoG
bWV0aG9kGAMgASgOMjUuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TYWZldHlTZXR0aW5nLkhh
cm1CbG9ja01ldGhvZEID4EEBUgZtZXRob2QinQEKEkhhcm1CbG9ja1RocmVzaG9sZBIkCiBI
QVJNX0JMT0NLX1RIUkVTSE9MRF9VTlNQRUNJRklFRBAAEhcKE0JMT0NLX0xPV19BTkRfQUJP
VkUQARIaChZCTE9DS19NRURJVU1fQU5EX0FCT1ZFEAISEwoPQkxPQ0tfT05MWV9ISUdIEAMS
DgoKQkxPQ0tfTk9ORRAEEgcKA09GRhAFIlMKD0hhcm1CbG9ja01ldGhvZBIhCh1IQVJNX0JM
T0NLX01FVEhPRF9VTlNQRUNJRklFRBAAEgwKCFNFVkVSSVRZEAESDwoLUFJPQkFCSUxJVFkQ
AirXAQoMSGFybUNhdGVnb3J5Eh0KGUhBUk1fQ0FURUdPUllfVU5TUEVDSUZJRUQQABIdChlI
QVJNX0NBVEVHT1JZX0hBVEVfU1BFRUNIEAESIwofSEFSTV9DQVRFR09SWV9EQU5HRVJPVVNf
Q09OVEVOVBACEhwKGEhBUk1fQ0FURUdPUllfSEFSQVNTTUVOVBADEiMKH0hBUk1fQ0FURUdP
UllfU0VYVUFMTFlfRVhQTElDSVQQBBIhCh1IQVJNX0NBVEVHT1JZX0NJVklDX0lOVEVHUklU
WRAFQrYBChpjb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MkILU2FmZXR5UHJvdG9QAVoyY2xv
dWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjIvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRB
SUyqAhZHb29nbGUuQ2xvdWQuUmV0YWlsLlYyygIWR29vZ2xlXENsb3VkXFJldGFpbFxWMuoC
GUdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJKlxUKBhIEDgBeAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCggKAQgSAxQAMwoJCgII
JRIDFAAzCggKAQgSAxUASQoJCgIICxIDFQBJCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgS
AxcALAoJCgIICBIDFwAsCggKAQgSAxgAMwoJCgIIARIDGAAzCggKAQgSAxkAJAoJCgIIJBID
GQAkCggKAQgSAxoAMwoJCgIIKRIDGgAzCggKAQgSAxsAMgoJCgIILRIDGwAyCjoKAgUAEgQe
ADABGi4gSGFybSBjYXRlZ29yaWVzIHRoYXQgd2lsbCBibG9jayB0aGUgY29udGVudC4KCgoK
AwUAARIDHgURCjAKBAUAAgASAyACIBojIFRoZSBoYXJtIGNhdGVnb3J5IGlzIHVuc3BlY2lm
aWVkLgoKDAoFBQACAAESAyACGwoMCgUFAAIAAhIDIB4fCjAKBAUAAgESAyMCIBojIFRoZSBo
YXJtIGNhdGVnb3J5IGlzIGhhdGUgc3BlZWNoLgoKDAoFBQACAQESAyMCGwoMCgUFAAIBAhID
Ix4fCjYKBAUAAgISAyYCJhopIFRoZSBoYXJtIGNhdGVnb3J5IGlzIGRhbmdlcm91cyBjb250
ZW50LgoKDAoFBQACAgESAyYCIQoMCgUFAAICAhIDJiQlCi8KBAUAAgMSAykCHxoiIFRoZSBo
YXJtIGNhdGVnb3J5IGlzIGhhcmFzc21lbnQuCgoMCgUFAAIDARIDKQIaCgwKBQUAAgMCEgMp
HR4KPgoEBQACBBIDLAImGjEgVGhlIGhhcm0gY2F0ZWdvcnkgaXMgc2V4dWFsbHkgZXhwbGlj
aXQgY29udGVudC4KCgwKBQUAAgQBEgMsAiEKDAoFBQACBAISAywkJQo0CgQFAAIFEgMvAiQa
JyBUaGUgaGFybSBjYXRlZ29yeSBpcyBjaXZpYyBpbnRlZ3JpdHkuCgoMCgUFAAIFARIDLwIf
CgwKBQUAAgUCEgMvIiMKHgoCBAASBDMAXgEaEiBTYWZldHkgc2V0dGluZ3MuCgoKCgMEAAES
AzMIFQpBCgQEAAQAEgQ1AkcDGjMgUHJvYmFiaWxpdHkgYmFzZWQgdGhyZXNob2xkcyBsZXZl
bHMgZm9yIGJsb2NraW5nLgoKDAoFBAAEAAESAzUHGQoyCgYEAAQAAgASAzcEKRojIFVuc3Bl
Y2lmaWVkIGhhcm0gYmxvY2sgdGhyZXNob2xkLgoKDgoHBAAEAAIAARIDNwQkCg4KBwQABAAC
AAISAzcnKApBCgYEAAQAAgESAzoEHBoyIEJsb2NrIGxvdyB0aHJlc2hvbGQgYW5kIGFib3Zl
IChpLmUuIGJsb2NrIG1vcmUpLgoKDgoHBAAEAAIBARIDOgQXCg4KBwQABAACAQISAzoaGwoy
CgYEAAQAAgISAz0EHxojIEJsb2NrIG1lZGl1bSB0aHJlc2hvbGQgYW5kIGFib3ZlLgoKDgoH
BAAEAAICARIDPQQaCg4KBwQABAACAgISAz0dHgo9CgYEAAQAAgMSA0AEGBouIEJsb2NrIG9u
bHkgaGlnaCB0aHJlc2hvbGQgKGkuZS4gYmxvY2sgbGVzcykuCgoOCgcEAAQAAgMBEgNABBMK
DgoHBAAEAAIDAhIDQBYXChwKBgQABAACBBIDQwQTGg0gQmxvY2sgbm9uZS4KCg4KBwQABAAC
BAESA0MEDgoOCgcEAAQAAgQCEgNDERIKLAoGBAAEAAIFEgNGBAwaHSBUdXJuIG9mZiB0aGUg
c2FmZXR5IGZpbHRlci4KCg4KBwQABAACBQESA0YEBwoOCgcEAAQAAgUCEgNGCgsKKAoEBAAE
ARIESgJTAxoaIFByb2JhYmlsaXR5IHZzIHNldmVyaXR5LgoKDAoFBAAEAQESA0oHFgo2CgYE
AAQBAgASA0wEJhonIFRoZSBoYXJtIGJsb2NrIG1ldGhvZCBpcyB1bnNwZWNpZmllZC4KCg4K
BwQABAECAAESA0wEIQoOCgcEAAQBAgACEgNMJCUKUQoGBAAEAQIBEgNPBBEaQiBUaGUgaGFy
bSBibG9jayBtZXRob2QgdXNlcyBib3RoIHByb2JhYmlsaXR5IGFuZCBzZXZlcml0eSBzY29y
ZXMuCgoOCgcEAAQBAgEBEgNPBAwKDgoHBAAEAQIBAhIDTw8QCkIKBgQABAECAhIDUgQUGjMg
VGhlIGhhcm0gYmxvY2sgbWV0aG9kIHVzZXMgdGhlIHByb2JhYmlsaXR5IHNjb3JlLgoKDgoH
BAAEAQICARIDUgQPCg4KBwQABAECAgISA1ISEwodCgQEAAIAEgNWAhwaECBIYXJtIGNhdGVn
b3J5LgoKDAoFBAACAAYSA1YCDgoMCgUEAAIAARIDVg8XCgwKBQQAAgADEgNWGhsKKAoEBAAC
ARIDWQIjGhsgVGhlIGhhcm0gYmxvY2sgdGhyZXNob2xkLgoKDAoFBAACAQYSA1kCFAoMCgUE
AAIBARIDWRUeCgwKBQQAAgEDEgNZISIKnQEKBAQAAgISA10CRhqPASBPcHRpb25hbC4gU3Bl
Y2lmeSBpZiB0aGUgdGhyZXNob2xkIGlzIHVzZWQgZm9yIHByb2JhYmlsaXR5IG9yIHNldmVy
aXR5CiBzY29yZS4gSWYgbm90IHNwZWNpZmllZCwgdGhlIHRocmVzaG9sZCBpcyB1c2VkIGZv
ciBwcm9iYWJpbGl0eSBzY29yZS4KCgwKBQQAAgIGEgNdAhEKDAoFBAACAgESA10SGAoMCgUE
AAICAxIDXRscCgwKBQQAAgIIEgNdHUUKDwoIBAACAgicCAASA10eRGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::Safety::SafetySetting ===
    # Fields for SafetySetting
    # Field: category Type: 14 (.google.cloud.retail.v2.HarmCategory)
    # Field: threshold Type: 14 (.google.cloud.retail.v2.SafetySetting.HarmBlockThreshold)
    # Field: method Type: 14 (.google.cloud.retail.v2.SafetySetting.HarmBlockMethod)

# Enum: SafetySetting::HarmBlockThreshold
our $SafetySetting_HARM_BLOCK_THRESHOLD_UNSPECIFIED = 0;
our $SafetySetting_BLOCK_LOW_AND_ABOVE = 1;
our $SafetySetting_BLOCK_MEDIUM_AND_ABOVE = 2;
our $SafetySetting_BLOCK_ONLY_HIGH = 3;
our $SafetySetting_BLOCK_NONE = 4;
our $SafetySetting_OFF = 5;

# Enum: SafetySetting::HarmBlockMethod
our $SafetySetting_HARM_BLOCK_METHOD_UNSPECIFIED = 0;
our $SafetySetting_SEVERITY = 1;
our $SafetySetting_PROBABILITY = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::Safety - Compiled Protocol Buffers messages for google/cloud/retail/v2/safety.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::Safety;

    my $msg = Google::Cloud::Retail::V2::Safety::SafetySetting->new({
        category => $category,
        threshold => $threshold,
        method => $method,
    });

    # Read or update a field
    my $val = $msg->category();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::Safety::SafetySetting->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::Safety::SafetySetting

Safety settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::HarmCategory>)

Harm category.

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::SafetySetting::HarmBlockThreshold>)

The harm block threshold.

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::SafetySetting::HarmBlockMethod>)

Optional. Specify if the threshold is used for probability or severity
score. If not specified, the threshold is used for probability score.

=back

=head3 Enum: SafetySetting::HarmBlockThreshold

=over 4

=item * C<HARM_BLOCK_THRESHOLD_UNSPECIFIED> => C<0>

=item * C<BLOCK_LOW_AND_ABOVE> => C<1>

=item * C<BLOCK_MEDIUM_AND_ABOVE> => C<2>

=item * C<BLOCK_ONLY_HIGH> => C<3>

=item * C<BLOCK_NONE> => C<4>

=item * C<OFF> => C<5>

=back

=head3 Enum: SafetySetting::HarmBlockMethod

=over 4

=item * C<HARM_BLOCK_METHOD_UNSPECIFIED> => C<0>

=item * C<SEVERITY> => C<1>

=item * C<PROBABILITY> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
