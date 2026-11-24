package Google::Cloud::Retail::V2beta::GenerativeQuestion;

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
CjRnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9nZW5lcmF0aXZlX3F1ZXN0aW9uLnByb3Rv
Ehpnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90byKfAQogR2VuZXJhdGl2ZVF1ZXN0aW9uc0ZlYXR1cmVDb25maWcSHQoHY2F0YWxv
ZxgBIAEoCUID4EECUgdjYXRhbG9nEiwKD2ZlYXR1cmVfZW5hYmxlZBgCIAEoCEID4EEBUg5m
ZWF0dXJlRW5hYmxlZBIuChBtaW5pbXVtX3Byb2R1Y3RzGAMgASgFQgPgQQFSD21pbmltdW1Q
cm9kdWN0cyLAAgoYR2VuZXJhdGl2ZVF1ZXN0aW9uQ29uZmlnEh0KB2NhdGFsb2cYASABKAlC
A+BBAlIHY2F0YWxvZxIZCgVmYWNldBgCIAEoCUID4EECUgVmYWNldBIyChJnZW5lcmF0ZWRf
cXVlc3Rpb24YAyABKAlCA+BBA1IRZ2VuZXJhdGVkUXVlc3Rpb24SKgoOZmluYWxfcXVlc3Rp
b24YBCABKAlCA+BBAVINZmluYWxRdWVzdGlvbhIqCg5leGFtcGxlX3ZhbHVlcxgFIAMoCUID
4EEDUg1leGFtcGxlVmFsdWVzEiEKCWZyZXF1ZW5jeRgGIAEoAkID4EEDUglmcmVxdWVuY3kS
OwoXYWxsb3dlZF9pbl9jb252ZXJzYXRpb24YByABKAhCA+BBAVIVYWxsb3dlZEluQ29udmVy
c2F0aW9uQtYBCh5jb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGFCF0dlbmVyYXRpdmVR
dWVzdGlvblByb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYmV0YS9y
ZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCGkdvb2dsZS5DbG91ZC5SZXRhaWwuVjJCZXRh
ygIaR29vZ2xlXENsb3VkXFJldGFpbFxWMmJldGHqAh1Hb29nbGU6OkNsb3VkOjpSZXRhaWw6
OlYyYmV0YUrWFQoGEgQOAEcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
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
CAoBAhIDEAAjCgkKAgMAEgMSACkKCAoBCBIDFAA3CgkKAgglEgMUADcKCAoBCBIDFQBNCgkK
AggLEgMVAE0KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA4CgkKAggIEgMXADgKCAoB
CBIDGAA3CgkKAggBEgMYADcKCAoBCBIDGQAkCgkKAggkEgMZACQKCAoBCBIDGgA3CgkKAggp
EgMaADcKCAoBCBIDGwA2CgkKAggtEgMbADYKSgoCBAASBB4AKwEaPiBDb25maWd1cmF0aW9u
IGZvciBvdmVyYWxsIGdlbmVyYXRpdmUgcXVlc3Rpb24gZmVhdHVyZSBzdGF0ZS4KCgoKAwQA
ARIDHggoCoMBCgQEAAIAEgMhAj4adiBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUg
YWZmZWN0ZWQgY2F0YWxvZy4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfQoKDAoFBAACAAUSAyECCAoMCgUEAAIA
ARIDIQkQCgwKBQQAAgADEgMhExQKDAoFBAACAAgSAyEVPQoPCggEAAIACJwIABIDIRY8CqoB
CgQEAAIBEgMmAkQanAEgT3B0aW9uYWwuIERldGVybWluZXMgd2hldGhlciBxdWVzdGlvbnMg
d2lsbCBiZSB1c2VkIGF0IHNlcnZpbmcgdGltZS4KIE5vdGU6IFRoaXMgZmVhdHVyZSBjYW5u
b3QgYmUgZW5hYmxlZCB1bnRpbCBpbml0aWFsIGRhdGEgcmVxdWlyZW1lbnRzIGFyZQogc2F0
aXNmaWVkLgoKDAoFBAACAQUSAyYCBgoMCgUEAAIBARIDJgcWCgwKBQQAAgEDEgMmGRoKDAoF
BAACAQgSAyYbQwoPCggEAAIBCJwIABIDJhxCCoEBCgQEAAICEgMqAkYadCBPcHRpb25hbC4g
TWluaW11bSBudW1iZXIgb2YgcHJvZHVjdHMgaW4gdGhlIHJlc3BvbnNlIHRvIHRyaWdnZXIg
Zm9sbG93LXVwCiBxdWVzdGlvbnMuIFZhbHVlIG11c3QgYmUgMCBvciBwb3NpdGl2ZS4KCgwK
BQQAAgIFEgMqAgcKDAoFBAACAgESAyoIGAoMCgUEAAICAxIDKhscCgwKBQQAAgIIEgMqHUUK
DwoIBAACAgicCAASAyoeRAo8CgIEARIELgBHARowIENvbmZpZ3VyYXRpb24gZm9yIGEgc2lu
Z2xlIGdlbmVyYXRlZCBxdWVzdGlvbi4KCgoKAwQBARIDLgggCnoKBAQBAgASAzECPhptIFJl
cXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBjYXRhbG9nLgogRm9ybWF0OiBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2F0YWxvZ3Mve2NhdGFsb2d9CgoM
CgUEAQIABRIDMQIICgwKBQQBAgABEgMxCRAKDAoFBAECAAMSAzETFAoMCgUEAQIACBIDMRU9
Cg8KCAQBAgAInAgAEgMxFjwKRwoEBAECARIDNAI8GjogUmVxdWlyZWQuIFRoZSBmYWNldCB0
byB3aGljaCB0aGUgcXVlc3Rpb24gaXMgYXNzb2NpYXRlZC4KCgwKBQQBAgEFEgM0AggKDAoF
BAECAQESAzQJDgoMCgUEAQIBAxIDNBESCgwKBQQBAgEIEgM0EzsKDwoIBAECAQicCAASAzQU
Ogo3CgQEAQICEgM3AkwaKiBPdXRwdXQgb25seS4gVGhlIExMTSBnZW5lcmF0ZWQgcXVlc3Rp
b24uCgoMCgUEAQICBRIDNwIICgwKBQQBAgIBEgM3CRsKDAoFBAECAgMSAzceHwoMCgUEAQIC
CBIDNyBLCg8KCAQBAgIInAgAEgM3IUoKrwEKBAQBAgMSAzwCRRqhASBPcHRpb25hbC4gVGhl
IHF1ZXN0aW9uIHRoYXQgd2lsbCBiZSB1c2VkIGF0IHNlcnZpbmcgdGltZS4KIFF1ZXN0aW9u
IGNhbiBoYXZlIGEgbWF4IGxlbmd0aCBvZiAzMDAgYnl0ZXMuCiBXaGVuIG5vdCBwb3B1bGF0
ZWQsIGdlbmVyYXRlZF9xdWVzdGlvbiBzaG91bGQgYmUgdXNlZC4KCgwKBQQBAgMFEgM8AggK
DAoFBAECAwESAzwJFwoMCgUEAQIDAxIDPBobCgwKBQQBAgMIEgM8HEQKDwoIBAECAwicCAAS
AzwdQwpMCgQEAQIEEgQ/AkAyGj4gT3V0cHV0IG9ubHkuIFZhbHVlcyB0aGF0IGNhbiBiZSB1
c2VkIHRvIGFuc3dlciB0aGUgcXVlc3Rpb24uCgoMCgUEAQIEBBIDPwIKCgwKBQQBAgQFEgM/
CxEKDAoFBAECBAESAz8SIAoMCgUEAQIEAxIDPyMkCgwKBQQBAgQIEgNABjEKDwoIBAECBAic
CAASA0AHMApICgQEAQIFEgNDAkIaOyBPdXRwdXQgb25seS4gVGhlIHJhdGlvIG9mIGhvdyBv
ZnRlbiBhIHF1ZXN0aW9uIHdhcyBhc2tlZC4KCgwKBQQBAgUFEgNDAgcKDAoFBAECBQESA0MI
EQoMCgUEAQIFAxIDQxQVCgwKBQQBAgUIEgNDFkEKDwoIBAECBQicCAASA0MXQApHCgQEAQIG
EgNGAkwaOiBPcHRpb25hbC4gV2hldGhlciB0aGUgcXVlc3Rpb24gaXMgYXNrZWQgYXQgc2Vy
dmluZyB0aW1lLgoKDAoFBAECBgUSA0YCBgoMCgUEAQIGARIDRgceCgwKBQQBAgYDEgNGISIK
DAoFBAECBggSA0YjSwoPCggEAQIGCJwIABIDRiRKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig ===
    # Fields for GenerativeQuestionsFeatureConfig
    # Field: catalog Type: 9 ()
    # Field: feature_enabled Type: 8 ()
    # Field: minimum_products Type: 5 ()

# === Message: Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionConfig ===
    # Fields for GenerativeQuestionConfig
    # Field: catalog Type: 9 ()
    # Field: facet Type: 9 ()
    # Field: generated_question Type: 9 ()
    # Field: final_question Type: 9 ()
    # Field: example_values Type: 9 ()
    # Field: frequency Type: 2 ()
    # Field: allowed_in_conversation Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::GenerativeQuestion - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/generative_question.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::GenerativeQuestion;

    my $msg = Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig->new({
        catalog => $catalog,
        feature_enabled => $feature_enabled,
        minimum_products => $minimum_products,
    });

    # Read or update a field
    my $val = $msg->catalog();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/generative_question.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig

Configuration for overall generative question feature state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Resource name of the affected catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=item * C<< $msg->feature_enabled() >> / C<< $msg->feature_enabled($value) >>

Type: C<Bool>

Optional. Determines whether questions will be used at serving time.
Note: This feature cannot be enabled until initial data requirements are
satisfied.

=item * C<< $msg->minimum_products() >> / C<< $msg->minimum_products($value) >>

Type: C<Int32>

Optional. Minimum number of products in the response to trigger follow-up
questions. Value must be 0 or positive.

=back

=head2 Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionConfig

Configuration for a single generated question.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Resource name of the catalog.
Format: projects/{project}/locations/{location}/catalogs/{catalog}

=item * C<< $msg->facet() >> / C<< $msg->facet($value) >>

Type: C<String>

Required. The facet to which the question is associated.

=item * C<< $msg->generated_question() >> / C<< $msg->generated_question($value) >>

Type: C<String>

Output only. The LLM generated question.

=item * C<< $msg->final_question() >> / C<< $msg->final_question($value) >>

Type: C<String>

Optional. The question that will be used at serving time.
Question can have a max length of 300 bytes.
When not populated, generated_question should be used.

=item * C<< $msg->example_values() >> / C<< $msg->example_values($value) >>

Type: C<String>

Output only. Values that can be used to answer the question.

=item * C<< $msg->frequency() >> / C<< $msg->frequency($value) >>

Type: C<Float>

Output only. The ratio of how often a question was asked.

=item * C<< $msg->allowed_in_conversation() >> / C<< $msg->allowed_in_conversation($value) >>

Type: C<Bool>

Optional. Whether the question is asked at serving time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::GenerativeQuestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
