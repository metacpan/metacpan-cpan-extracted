package Google::Cloud::Discoveryengine::V1beta::Safety;

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
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zYWZldHkucHJvdG8SI2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvIqUFCgxTYWZldHlSYXRpbmcSUgoIY2F0ZWdvcnkYASABKA4yMS5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5IYXJtQ2F0ZWdvcnlCA+BBA1IIY2F0
ZWdvcnkSaAoLcHJvYmFiaWxpdHkYAiABKA4yQS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5TYWZldHlSYXRpbmcuSGFybVByb2JhYmlsaXR5QgPgQQNSC3Byb2JhYmls
aXR5EjAKEXByb2JhYmlsaXR5X3Njb3JlGAUgASgCQgPgQQNSEHByb2JhYmlsaXR5U2NvcmUS
XwoIc2V2ZXJpdHkYBiABKA4yPi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5TYWZldHlSYXRpbmcuSGFybVNldmVyaXR5QgPgQQNSCHNldmVyaXR5EioKDnNldmVyaXR5
X3Njb3JlGAcgASgCQgPgQQNSDXNldmVyaXR5U2NvcmUSHQoHYmxvY2tlZBgDIAEoCEID4EED
UgdibG9ja2VkImIKD0hhcm1Qcm9iYWJpbGl0eRIgChxIQVJNX1BST0JBQklMSVRZX1VOU1BF
Q0lGSUVEEAASDgoKTkVHTElHSUJMRRABEgcKA0xPVxACEgoKBk1FRElVTRADEggKBEhJR0gQ
BCKUAQoMSGFybVNldmVyaXR5Eh0KGUhBUk1fU0VWRVJJVFlfVU5TUEVDSUZJRUQQABIcChhI
QVJNX1NFVkVSSVRZX05FR0xJR0lCTEUQARIVChFIQVJNX1NFVkVSSVRZX0xPVxACEhgKFEhB
Uk1fU0VWRVJJVFlfTUVESVVNEAMSFgoSSEFSTV9TRVZFUklUWV9ISUdIEAQq1wEKDEhhcm1D
YXRlZ29yeRIdChlIQVJNX0NBVEVHT1JZX1VOU1BFQ0lGSUVEEAASHQoZSEFSTV9DQVRFR09S
WV9IQVRFX1NQRUVDSBABEiMKH0hBUk1fQ0FURUdPUllfREFOR0VST1VTX0NPTlRFTlQQAhIc
ChhIQVJNX0NBVEVHT1JZX0hBUkFTU01FTlQQAxIjCh9IQVJNX0NBVEVHT1JZX1NFWFVBTExZ
X0VYUExJQ0lUEAQSIQodSEFSTV9DQVRFR09SWV9DSVZJQ19JTlRFR1JJVFkQBUKSAgonY29t
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQgtTYWZldHlQcm90b1ABWlFj
bG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5
ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUu
Q2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlF
bmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFK
uBgKBhIEDgBqAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
LAoJCgIDABIDEgApCggKAQgSAxQAQAoJCgIIJRIDFABACggKAQgSAxUAaAoJCgIICxIDFQBo
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALAoJCgIICBIDFwAsCggKAQgSAxgAQAoJ
CgIIARIDGABACggKAQgSAxkALQoJCgIIJBIDGQAtCggKAQgSAxoAQAoJCgIIKRIDGgBACggK
AQgSAxsAPwoJCgIILRIDGwA/CjoKAgUAEgQeADABGi4gSGFybSBjYXRlZ29yaWVzIHRoYXQg
d2lsbCBibG9jayB0aGUgY29udGVudC4KCgoKAwUAARIDHgURCjAKBAUAAgASAyACIBojIFRo
ZSBoYXJtIGNhdGVnb3J5IGlzIHVuc3BlY2lmaWVkLgoKDAoFBQACAAESAyACGwoMCgUFAAIA
AhIDIB4fCjAKBAUAAgESAyMCIBojIFRoZSBoYXJtIGNhdGVnb3J5IGlzIGhhdGUgc3BlZWNo
LgoKDAoFBQACAQESAyMCGwoMCgUFAAIBAhIDIx4fCjYKBAUAAgISAyYCJhopIFRoZSBoYXJt
IGNhdGVnb3J5IGlzIGRhbmdlcm91cyBjb250ZW50LgoKDAoFBQACAgESAyYCIQoMCgUFAAIC
AhIDJiQlCi8KBAUAAgMSAykCHxoiIFRoZSBoYXJtIGNhdGVnb3J5IGlzIGhhcmFzc21lbnQu
CgoMCgUFAAIDARIDKQIaCgwKBQUAAgMCEgMpHR4KPgoEBQACBBIDLAImGjEgVGhlIGhhcm0g
Y2F0ZWdvcnkgaXMgc2V4dWFsbHkgZXhwbGljaXQgY29udGVudC4KCgwKBQUAAgQBEgMsAiEK
DAoFBQACBAISAywkJQo0CgQFAAIFEgMvAiQaJyBUaGUgaGFybSBjYXRlZ29yeSBpcyBjaXZp
YyBpbnRlZ3JpdHkuCgoMCgUFAAIFARIDLwIfCgwKBQUAAgUCEgMvIiMKQwoCBAASBDMAagEa
NyBTYWZldHkgcmF0aW5nIGNvcnJlc3BvbmRpbmcgdG8gdGhlIGdlbmVyYXRlZCBjb250ZW50
LgoKCgoDBAABEgMzCBQKNwoEBAAEABIENQJEAxopIEhhcm0gcHJvYmFiaWxpdHkgbGV2ZWxz
IGluIHRoZSBjb250ZW50LgoKDAoFBAAEAAESAzUHFgouCgYEAAQAAgASAzcEJRofIEhhcm0g
cHJvYmFiaWxpdHkgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgM3BCAKDgoHBAAEAAIAAhID
NyMkCioKBgQABAACARIDOgQTGhsgTmVnbGlnaWJsZSBsZXZlbCBvZiBoYXJtLgoKDgoHBAAE
AAIBARIDOgQOCg4KBwQABAACAQISAzoREgojCgYEAAQAAgISAz0EDBoUIExvdyBsZXZlbCBv
ZiBoYXJtLgoKDgoHBAAEAAICARIDPQQHCg4KBwQABAACAgISAz0KCwomCgYEAAQAAgMSA0AE
DxoXIE1lZGl1bSBsZXZlbCBvZiBoYXJtLgoKDgoHBAAEAAIDARIDQAQKCg4KBwQABAACAwIS
A0ANDgokCgYEAAQAAgQSA0MEDRoVIEhpZ2ggbGV2ZWwgb2YgaGFybS4KCg4KBwQABAACBAES
A0MECAoOCgcEAAQAAgQCEgNDCwwKJQoEBAAEARIERwJWAxoXIEhhcm0gc2V2ZXJpdHkgbGV2
ZWxzLgoKDAoFBAAEAQESA0cHEworCgYEAAQBAgASA0kEIhocIEhhcm0gc2V2ZXJpdHkgdW5z
cGVjaWZpZWQuCgoOCgcEAAQBAgABEgNJBB0KDgoHBAAEAQIAAhIDSSAhCjMKBgQABAECARID
TAQhGiQgTmVnbGlnaWJsZSBsZXZlbCBvZiBoYXJtIHNldmVyaXR5LgoKDgoHBAAEAQIBARID
TAQcCg4KBwQABAECAQISA0wfIAosCgYEAAQBAgISA08EGhodIExvdyBsZXZlbCBvZiBoYXJt
IHNldmVyaXR5LgoKDgoHBAAEAQICARIDTwQVCg4KBwQABAECAgISA08YGQovCgYEAAQBAgMS
A1IEHRogIE1lZGl1bSBsZXZlbCBvZiBoYXJtIHNldmVyaXR5LgoKDgoHBAAEAQIDARIDUgQY
Cg4KBwQABAECAwISA1IbHAotCgYEAAQBAgQSA1UEGxoeIEhpZ2ggbGV2ZWwgb2YgaGFybSBz
ZXZlcml0eS4KCg4KBwQABAECBAESA1UEFgoOCgcEAAQBAgQCEgNVGRoKKgoEBAACABIDWQJI
Gh0gT3V0cHV0IG9ubHkuIEhhcm0gY2F0ZWdvcnkuCgoMCgUEAAIABhIDWQIOCgwKBQQAAgAB
EgNZDxcKDAoFBAACAAMSA1kaGwoMCgUEAAIACBIDWRxHCg8KCAQAAgAInAgAEgNZHUYKQwoE
BAACARIDXAJOGjYgT3V0cHV0IG9ubHkuIEhhcm0gcHJvYmFiaWxpdHkgbGV2ZWxzIGluIHRo
ZSBjb250ZW50LgoKDAoFBAACAQYSA1wCEQoMCgUEAAIBARIDXBIdCgwKBQQAAgEDEgNcICEK
DAoFBAACAQgSA1wiTQoPCggEAAIBCJwIABIDXCNMCjMKBAQAAgISA18CShomIE91dHB1dCBv
bmx5LiBIYXJtIHByb2JhYmlsaXR5IHNjb3JlLgoKDAoFBAACAgUSA18CBwoMCgUEAAICARID
XwgZCgwKBQQAAgIDEgNfHB0KDAoFBAACAggSA18eSQoPCggEAAICCJwIABIDXx9ICkAKBAQA
AgMSA2ICSBozIE91dHB1dCBvbmx5LiBIYXJtIHNldmVyaXR5IGxldmVscyBpbiB0aGUgY29u
dGVudC4KCgwKBQQAAgMGEgNiAg4KDAoFBAACAwESA2IPFwoMCgUEAAIDAxIDYhobCgwKBQQA
AgMIEgNiHEcKDwoIBAACAwicCAASA2IdRgowCgQEAAIEEgNlAkcaIyBPdXRwdXQgb25seS4g
SGFybSBzZXZlcml0eSBzY29yZS4KCgwKBQQAAgQFEgNlAgcKDAoFBAACBAESA2UIFgoMCgUE
AAIEAxIDZRkaCgwKBQQAAgQIEgNlG0YKDwoIBAACBAicCAASA2UcRQpjCgQEAAIFEgNpAj8a
ViBPdXRwdXQgb25seS4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGNvbnRlbnQgd2FzIGZpbHRl
cmVkIG91dCBiZWNhdXNlIG9mIHRoaXMKIHJhdGluZy4KCgwKBQQAAgUFEgNpAgYKDAoFBAAC
BQESA2kHDgoMCgUEAAIFAxIDaRESCgwKBQQAAgUIEgNpEz4KDwoIBAACBQicCAASA2kUPWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating ===
    # Fields for SafetyRating
    # Field: category Type: 14 (.google.cloud.discoveryengine.v1beta.HarmCategory)
    # Field: probability Type: 14 (.google.cloud.discoveryengine.v1beta.SafetyRating.HarmProbability)
    # Field: probability_score Type: 2 ()
    # Field: severity Type: 14 (.google.cloud.discoveryengine.v1beta.SafetyRating.HarmSeverity)
    # Field: severity_score Type: 2 ()
    # Field: blocked Type: 8 ()

# Enum: SafetyRating::HarmProbability
our $SafetyRating_HARM_PROBABILITY_UNSPECIFIED = 0;
our $SafetyRating_NEGLIGIBLE = 1;
our $SafetyRating_LOW = 2;
our $SafetyRating_MEDIUM = 3;
our $SafetyRating_HIGH = 4;

# Enum: SafetyRating::HarmSeverity
our $SafetyRating_HARM_SEVERITY_UNSPECIFIED = 0;
our $SafetyRating_HARM_SEVERITY_NEGLIGIBLE = 1;
our $SafetyRating_HARM_SEVERITY_LOW = 2;
our $SafetyRating_HARM_SEVERITY_MEDIUM = 3;
our $SafetyRating_HARM_SEVERITY_HIGH = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Safety - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/safety.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Safety;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating->new({
        category => $category,
        probability => $probability,
        probability_score => $probability_score,
        severity => $severity,
    });

    # Read or update a field
    my $val = $msg->category();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating

Safety rating corresponding to the generated content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::HarmCategory>)

Output only. Harm category.

=item * C<< $msg->probability() >> / C<< $msg->probability($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::SafetyRating::HarmProbability>)

Output only. Harm probability levels in the content.

=item * C<< $msg->probability_score() >> / C<< $msg->probability_score($value) >>

Type: C<Float>

Output only. Harm probability score.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::SafetyRating::HarmSeverity>)

Output only. Harm severity levels in the content.

=item * C<< $msg->severity_score() >> / C<< $msg->severity_score($value) >>

Type: C<Float>

Output only. Harm severity score.

=item * C<< $msg->blocked() >> / C<< $msg->blocked($value) >>

Type: C<Bool>

Output only. Indicates whether the content was filtered out because of this
rating.

=back

=head3 Enum: SafetyRating::HarmProbability

=over 4

=item * C<HARM_PROBABILITY_UNSPECIFIED> => C<0>

=item * C<NEGLIGIBLE> => C<1>

=item * C<LOW> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<HIGH> => C<4>

=back

=head3 Enum: SafetyRating::HarmSeverity

=over 4

=item * C<HARM_SEVERITY_UNSPECIFIED> => C<0>

=item * C<HARM_SEVERITY_NEGLIGIBLE> => C<1>

=item * C<HARM_SEVERITY_LOW> => C<2>

=item * C<HARM_SEVERITY_MEDIUM> => C<3>

=item * C<HARM_SEVERITY_HIGH> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
