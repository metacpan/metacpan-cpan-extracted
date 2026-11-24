package Google::Cloud::Discoveryengine::V1::Safety;

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
Cixnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NhZmV0eS5wcm90bxIfZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90byKZBQoMU2FmZXR5UmF0aW5nEk4KCGNhdGVnb3J5GAEgASgOMi0uZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5IYXJtQ2F0ZWdvcnlCA+BBA1IIY2F0ZWdvcnkSZAoLcHJv
YmFiaWxpdHkYAiABKA4yPS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNhZmV0
eVJhdGluZy5IYXJtUHJvYmFiaWxpdHlCA+BBA1ILcHJvYmFiaWxpdHkSMAoRcHJvYmFiaWxp
dHlfc2NvcmUYBSABKAJCA+BBA1IQcHJvYmFiaWxpdHlTY29yZRJbCghzZXZlcml0eRgGIAEo
DjI6Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2FmZXR5UmF0aW5nLkhhcm1T
ZXZlcml0eUID4EEDUghzZXZlcml0eRIqCg5zZXZlcml0eV9zY29yZRgHIAEoAkID4EEDUg1z
ZXZlcml0eVNjb3JlEh0KB2Jsb2NrZWQYAyABKAhCA+BBA1IHYmxvY2tlZCJiCg9IYXJtUHJv
YmFiaWxpdHkSIAocSEFSTV9QUk9CQUJJTElUWV9VTlNQRUNJRklFRBAAEg4KCk5FR0xJR0lC
TEUQARIHCgNMT1cQAhIKCgZNRURJVU0QAxIICgRISUdIEAQilAEKDEhhcm1TZXZlcml0eRId
ChlIQVJNX1NFVkVSSVRZX1VOU1BFQ0lGSUVEEAASHAoYSEFSTV9TRVZFUklUWV9ORUdMSUdJ
QkxFEAESFQoRSEFSTV9TRVZFUklUWV9MT1cQAhIYChRIQVJNX1NFVkVSSVRZX01FRElVTRAD
EhYKEkhBUk1fU0VWRVJJVFlfSElHSBAEKtcBCgxIYXJtQ2F0ZWdvcnkSHQoZSEFSTV9DQVRF
R09SWV9VTlNQRUNJRklFRBAAEh0KGUhBUk1fQ0FURUdPUllfSEFURV9TUEVFQ0gQARIjCh9I
QVJNX0NBVEVHT1JZX0RBTkdFUk9VU19DT05URU5UEAISHAoYSEFSTV9DQVRFR09SWV9IQVJB
U1NNRU5UEAMSIwofSEFSTV9DQVRFR09SWV9TRVhVQUxMWV9FWFBMSUNJVBAEEiEKHUhBUk1f
Q0FURUdPUllfQ0lWSUNfSU5URUdSSVRZEAVC/gEKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxQgtTYWZldHlQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2Nv
dmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqIC
D0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9H
b29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292
ZXJ5RW5naW5lOjpWMUq4GAoGEgQOAGoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCAoBCBIDFAA8CgkKAgglEgMUADwKCAoBCBID
FQBkCgkKAggLEgMVAGQKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAsCgkKAggIEgMX
ACwKCAoBCBIDGAA8CgkKAggBEgMYADwKCAoBCBIDGQAtCgkKAggkEgMZAC0KCAoBCBIDGgA8
CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKOgoCBQASBB4AMAEaLiBIYXJtIGNh
dGVnb3JpZXMgdGhhdCB3aWxsIGJsb2NrIHRoZSBjb250ZW50LgoKCgoDBQABEgMeBREKMAoE
BQACABIDIAIgGiMgVGhlIGhhcm0gY2F0ZWdvcnkgaXMgdW5zcGVjaWZpZWQuCgoMCgUFAAIA
ARIDIAIbCgwKBQUAAgACEgMgHh8KMAoEBQACARIDIwIgGiMgVGhlIGhhcm0gY2F0ZWdvcnkg
aXMgaGF0ZSBzcGVlY2guCgoMCgUFAAIBARIDIwIbCgwKBQUAAgECEgMjHh8KNgoEBQACAhID
JgImGikgVGhlIGhhcm0gY2F0ZWdvcnkgaXMgZGFuZ2Vyb3VzIGNvbnRlbnQuCgoMCgUFAAIC
ARIDJgIhCgwKBQUAAgICEgMmJCUKLwoEBQACAxIDKQIfGiIgVGhlIGhhcm0gY2F0ZWdvcnkg
aXMgaGFyYXNzbWVudC4KCgwKBQUAAgMBEgMpAhoKDAoFBQACAwISAykdHgo+CgQFAAIEEgMs
AiYaMSBUaGUgaGFybSBjYXRlZ29yeSBpcyBzZXh1YWxseSBleHBsaWNpdCBjb250ZW50LgoK
DAoFBQACBAESAywCIQoMCgUFAAIEAhIDLCQlCjQKBAUAAgUSAy8CJBonIFRoZSBoYXJtIGNh
dGVnb3J5IGlzIGNpdmljIGludGVncml0eS4KCgwKBQUAAgUBEgMvAh8KDAoFBQACBQISAy8i
IwpDCgIEABIEMwBqARo3IFNhZmV0eSByYXRpbmcgY29ycmVzcG9uZGluZyB0byB0aGUgZ2Vu
ZXJhdGVkIGNvbnRlbnQuCgoKCgMEAAESAzMIFAo3CgQEAAQAEgQ1AkQDGikgSGFybSBwcm9i
YWJpbGl0eSBsZXZlbHMgaW4gdGhlIGNvbnRlbnQuCgoMCgUEAAQAARIDNQcWCi4KBgQABAAC
ABIDNwQlGh8gSGFybSBwcm9iYWJpbGl0eSB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAzcE
IAoOCgcEAAQAAgACEgM3IyQKKgoGBAAEAAIBEgM6BBMaGyBOZWdsaWdpYmxlIGxldmVsIG9m
IGhhcm0uCgoOCgcEAAQAAgEBEgM6BA4KDgoHBAAEAAIBAhIDOhESCiMKBgQABAACAhIDPQQM
GhQgTG93IGxldmVsIG9mIGhhcm0uCgoOCgcEAAQAAgIBEgM9BAcKDgoHBAAEAAICAhIDPQoL
CiYKBgQABAACAxIDQAQPGhcgTWVkaXVtIGxldmVsIG9mIGhhcm0uCgoOCgcEAAQAAgMBEgNA
BAoKDgoHBAAEAAIDAhIDQA0OCiQKBgQABAACBBIDQwQNGhUgSGlnaCBsZXZlbCBvZiBoYXJt
LgoKDgoHBAAEAAIEARIDQwQICg4KBwQABAACBAISA0MLDAolCgQEAAQBEgRHAlYDGhcgSGFy
bSBzZXZlcml0eSBsZXZlbHMuCgoMCgUEAAQBARIDRwcTCisKBgQABAECABIDSQQiGhwgSGFy
bSBzZXZlcml0eSB1bnNwZWNpZmllZC4KCg4KBwQABAECAAESA0kEHQoOCgcEAAQBAgACEgNJ
ICEKMwoGBAAEAQIBEgNMBCEaJCBOZWdsaWdpYmxlIGxldmVsIG9mIGhhcm0gc2V2ZXJpdHku
CgoOCgcEAAQBAgEBEgNMBBwKDgoHBAAEAQIBAhIDTB8gCiwKBgQABAECAhIDTwQaGh0gTG93
IGxldmVsIG9mIGhhcm0gc2V2ZXJpdHkuCgoOCgcEAAQBAgIBEgNPBBUKDgoHBAAEAQICAhID
TxgZCi8KBgQABAECAxIDUgQdGiAgTWVkaXVtIGxldmVsIG9mIGhhcm0gc2V2ZXJpdHkuCgoO
CgcEAAQBAgMBEgNSBBgKDgoHBAAEAQIDAhIDUhscCi0KBgQABAECBBIDVQQbGh4gSGlnaCBs
ZXZlbCBvZiBoYXJtIHNldmVyaXR5LgoKDgoHBAAEAQIEARIDVQQWCg4KBwQABAECBAISA1UZ
GgoqCgQEAAIAEgNZAkgaHSBPdXRwdXQgb25seS4gSGFybSBjYXRlZ29yeS4KCgwKBQQAAgAG
EgNZAg4KDAoFBAACAAESA1kPFwoMCgUEAAIAAxIDWRobCgwKBQQAAgAIEgNZHEcKDwoIBAAC
AAicCAASA1kdRgpDCgQEAAIBEgNcAk4aNiBPdXRwdXQgb25seS4gSGFybSBwcm9iYWJpbGl0
eSBsZXZlbHMgaW4gdGhlIGNvbnRlbnQuCgoMCgUEAAIBBhIDXAIRCgwKBQQAAgEBEgNcEh0K
DAoFBAACAQMSA1wgIQoMCgUEAAIBCBIDXCJNCg8KCAQAAgEInAgAEgNcI0wKMwoEBAACAhID
XwJKGiYgT3V0cHV0IG9ubHkuIEhhcm0gcHJvYmFiaWxpdHkgc2NvcmUuCgoMCgUEAAICBRID
XwIHCgwKBQQAAgIBEgNfCBkKDAoFBAACAgMSA18cHQoMCgUEAAICCBIDXx5JCg8KCAQAAgII
nAgAEgNfH0gKQAoEBAACAxIDYgJIGjMgT3V0cHV0IG9ubHkuIEhhcm0gc2V2ZXJpdHkgbGV2
ZWxzIGluIHRoZSBjb250ZW50LgoKDAoFBAACAwYSA2ICDgoMCgUEAAIDARIDYg8XCgwKBQQA
AgMDEgNiGhsKDAoFBAACAwgSA2IcRwoPCggEAAIDCJwIABIDYh1GCjAKBAQAAgQSA2UCRxoj
IE91dHB1dCBvbmx5LiBIYXJtIHNldmVyaXR5IHNjb3JlLgoKDAoFBAACBAUSA2UCBwoMCgUE
AAIEARIDZQgWCgwKBQQAAgQDEgNlGRoKDAoFBAACBAgSA2UbRgoPCggEAAIECJwIABIDZRxF
CmMKBAQAAgUSA2kCPxpWIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgY29u
dGVudCB3YXMgZmlsdGVyZWQgb3V0IGJlY2F1c2Ugb2YgdGhpcwogcmF0aW5nLgoKDAoFBAAC
BQUSA2kCBgoMCgUEAAIFARIDaQcOCgwKBQQAAgUDEgNpERIKDAoFBAACBQgSA2kTPgoPCggE
AAIFCJwIABIDaRQ9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Safety::SafetyRating ===
    # Fields for SafetyRating
    # Field: category Type: 14 (.google.cloud.discoveryengine.v1.HarmCategory)
    # Field: probability Type: 14 (.google.cloud.discoveryengine.v1.SafetyRating.HarmProbability)
    # Field: probability_score Type: 2 ()
    # Field: severity Type: 14 (.google.cloud.discoveryengine.v1.SafetyRating.HarmSeverity)
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

Google::Cloud::Discoveryengine::V1::Safety - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/safety.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Safety;

    my $msg = Google::Cloud::Discoveryengine::V1::Safety::SafetyRating->new({
        category => $category,
        probability => $probability,
        probability_score => $probability_score,
        severity => $severity,
    });

    # Read or update a field
    my $val = $msg->category();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Safety::SafetyRating->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Safety::SafetyRating

Safety rating corresponding to the generated content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::HarmCategory>)

Output only. Harm category.

=item * C<< $msg->probability() >> / C<< $msg->probability($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::SafetyRating::HarmProbability>)

Output only. Harm probability levels in the content.

=item * C<< $msg->probability_score() >> / C<< $msg->probability_score($value) >>

Type: C<Float>

Output only. Harm probability score.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::SafetyRating::HarmSeverity>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
