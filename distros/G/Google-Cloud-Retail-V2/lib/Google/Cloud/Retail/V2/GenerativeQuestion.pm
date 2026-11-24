package Google::Cloud::Retail::V2::GenerativeQuestion;

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
CjBnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2dlbmVyYXRpdmVfcXVlc3Rpb24ucHJvdG8SFmdv
b2dsZS5jbG91ZC5yZXRhaWwudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8i
nwEKIEdlbmVyYXRpdmVRdWVzdGlvbnNGZWF0dXJlQ29uZmlnEh0KB2NhdGFsb2cYASABKAlC
A+BBAlIHY2F0YWxvZxIsCg9mZWF0dXJlX2VuYWJsZWQYAiABKAhCA+BBAVIOZmVhdHVyZUVu
YWJsZWQSLgoQbWluaW11bV9wcm9kdWN0cxgDIAEoBUID4EEBUg9taW5pbXVtUHJvZHVjdHMi
wAIKGEdlbmVyYXRpdmVRdWVzdGlvbkNvbmZpZxIdCgdjYXRhbG9nGAEgASgJQgPgQQJSB2Nh
dGFsb2cSGQoFZmFjZXQYAiABKAlCA+BBAlIFZmFjZXQSMgoSZ2VuZXJhdGVkX3F1ZXN0aW9u
GAMgASgJQgPgQQNSEWdlbmVyYXRlZFF1ZXN0aW9uEioKDmZpbmFsX3F1ZXN0aW9uGAQgASgJ
QgPgQQFSDWZpbmFsUXVlc3Rpb24SKgoOZXhhbXBsZV92YWx1ZXMYBSADKAlCA+BBA1INZXhh
bXBsZVZhbHVlcxIhCglmcmVxdWVuY3kYBiABKAJCA+BBA1IJZnJlcXVlbmN5EjsKF2FsbG93
ZWRfaW5fY29udmVyc2F0aW9uGAcgASgIQgPgQQFSFWFsbG93ZWRJbkNvbnZlcnNhdGlvbkLC
AQoaY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJCF0dlbmVyYXRpdmVRdWVzdGlvblByb3Rv
UAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyL3JldGFpbHBiO3JldGFpbHBi
ogIGUkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFpbC5WMsoCFkdvb2dsZVxDbG91ZFxSZXRh
aWxcVjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyStYVCgYSBA4ARwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoICgEIEgMU
ADMKCQoCCCUSAxQAMwoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEIEgMWACIKCQoCCAoSAxYA
IgoICgEIEgMXADgKCQoCCAgSAxcAOAoICgEIEgMYADMKCQoCCAESAxgAMwoICgEIEgMZACQK
CQoCCCQSAxkAJAoICgEIEgMaADMKCQoCCCkSAxoAMwoICgEIEgMbADIKCQoCCC0SAxsAMgpK
CgIEABIEHgArARo+IENvbmZpZ3VyYXRpb24gZm9yIG92ZXJhbGwgZ2VuZXJhdGl2ZSBxdWVz
dGlvbiBmZWF0dXJlIHN0YXRlLgoKCgoDBAABEgMeCCgKgwEKBAQAAgASAyECPhp2IFJlcXVp
cmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBhZmZlY3RlZCBjYXRhbG9nLgogRm9ybWF0OiBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2F0YWxvZ3Mve2NhdGFs
b2d9CgoMCgUEAAIABRIDIQIICgwKBQQAAgABEgMhCRAKDAoFBAACAAMSAyETFAoMCgUEAAIA
CBIDIRU9Cg8KCAQAAgAInAgAEgMhFjwKqgEKBAQAAgESAyYCRBqcASBPcHRpb25hbC4gRGV0
ZXJtaW5lcyB3aGV0aGVyIHF1ZXN0aW9ucyB3aWxsIGJlIHVzZWQgYXQgc2VydmluZyB0aW1l
LgogTm90ZTogVGhpcyBmZWF0dXJlIGNhbm5vdCBiZSBlbmFibGVkIHVudGlsIGluaXRpYWwg
ZGF0YSByZXF1aXJlbWVudHMgYXJlCiBzYXRpc2ZpZWQuCgoMCgUEAAIBBRIDJgIGCgwKBQQA
AgEBEgMmBxYKDAoFBAACAQMSAyYZGgoMCgUEAAIBCBIDJhtDCg8KCAQAAgEInAgAEgMmHEIK
gQEKBAQAAgISAyoCRhp0IE9wdGlvbmFsLiBNaW5pbXVtIG51bWJlciBvZiBwcm9kdWN0cyBp
biB0aGUgcmVzcG9uc2UgdG8gdHJpZ2dlciBmb2xsb3ctdXAKIHF1ZXN0aW9ucy4gVmFsdWUg
bXVzdCBiZSAwIG9yIHBvc2l0aXZlLgoKDAoFBAACAgUSAyoCBwoMCgUEAAICARIDKggYCgwK
BQQAAgIDEgMqGxwKDAoFBAACAggSAyodRQoPCggEAAICCJwIABIDKh5ECjwKAgQBEgQuAEcB
GjAgQ29uZmlndXJhdGlvbiBmb3IgYSBzaW5nbGUgZ2VuZXJhdGVkIHF1ZXN0aW9uLgoKCgoD
BAEBEgMuCCAKegoEBAECABIDMQI+Gm0gUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhl
IGNhdGFsb2cuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9jYXRhbG9ncy97Y2F0YWxvZ30KCgwKBQQBAgAFEgMxAggKDAoFBAECAAESAzEJEAoM
CgUEAQIAAxIDMRMUCgwKBQQBAgAIEgMxFT0KDwoIBAECAAicCAASAzEWPApHCgQEAQIBEgM0
AjwaOiBSZXF1aXJlZC4gVGhlIGZhY2V0IHRvIHdoaWNoIHRoZSBxdWVzdGlvbiBpcyBhc3Nv
Y2lhdGVkLgoKDAoFBAECAQUSAzQCCAoMCgUEAQIBARIDNAkOCgwKBQQBAgEDEgM0ERIKDAoF
BAECAQgSAzQTOwoPCggEAQIBCJwIABIDNBQ6CjcKBAQBAgISAzcCTBoqIE91dHB1dCBvbmx5
LiBUaGUgTExNIGdlbmVyYXRlZCBxdWVzdGlvbi4KCgwKBQQBAgIFEgM3AggKDAoFBAECAgES
AzcJGwoMCgUEAQICAxIDNx4fCgwKBQQBAgIIEgM3IEsKDwoIBAECAgicCAASAzchSgqvAQoE
BAECAxIDPAJFGqEBIE9wdGlvbmFsLiBUaGUgcXVlc3Rpb24gdGhhdCB3aWxsIGJlIHVzZWQg
YXQgc2VydmluZyB0aW1lLgogUXVlc3Rpb24gY2FuIGhhdmUgYSBtYXggbGVuZ3RoIG9mIDMw
MCBieXRlcy4KIFdoZW4gbm90IHBvcHVsYXRlZCwgZ2VuZXJhdGVkX3F1ZXN0aW9uIHNob3Vs
ZCBiZSB1c2VkLgoKDAoFBAECAwUSAzwCCAoMCgUEAQIDARIDPAkXCgwKBQQBAgMDEgM8GhsK
DAoFBAECAwgSAzwcRAoPCggEAQIDCJwIABIDPB1DCkwKBAQBAgQSBD8CQDIaPiBPdXRwdXQg
b25seS4gVmFsdWVzIHRoYXQgY2FuIGJlIHVzZWQgdG8gYW5zd2VyIHRoZSBxdWVzdGlvbi4K
CgwKBQQBAgQEEgM/AgoKDAoFBAECBAUSAz8LEQoMCgUEAQIEARIDPxIgCgwKBQQBAgQDEgM/
IyQKDAoFBAECBAgSA0AGMQoPCggEAQIECJwIABIDQAcwCkgKBAQBAgUSA0MCQho7IE91dHB1
dCBvbmx5LiBUaGUgcmF0aW8gb2YgaG93IG9mdGVuIGEgcXVlc3Rpb24gd2FzIGFza2VkLgoK
DAoFBAECBQUSA0MCBwoMCgUEAQIFARIDQwgRCgwKBQQBAgUDEgNDFBUKDAoFBAECBQgSA0MW
QQoPCggEAQIFCJwIABIDQxdACkcKBAQBAgYSA0YCTBo6IE9wdGlvbmFsLiBXaGV0aGVyIHRo
ZSBxdWVzdGlvbiBpcyBhc2tlZCBhdCBzZXJ2aW5nIHRpbWUuCgoMCgUEAQIGBRIDRgIGCgwK
BQQBAgYBEgNGBx4KDAoFBAECBgMSA0YhIgoMCgUEAQIGCBIDRiNLCg8KCAQBAgYInAgAEgNG
JEpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig ===
    # Fields for GenerativeQuestionsFeatureConfig
    # Field: catalog Type: 9 ()
    # Field: feature_enabled Type: 8 ()
    # Field: minimum_products Type: 5 ()

# === Message: Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionConfig ===
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

Google::Cloud::Retail::V2::GenerativeQuestion - Compiled Protocol Buffers messages for google/cloud/retail/v2/generative_question.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::GenerativeQuestion;

    my $msg = Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig->new({
        catalog => $catalog,
        feature_enabled => $feature_enabled,
        minimum_products => $minimum_products,
    });

    # Read or update a field
    my $val = $msg->catalog();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/generative_question.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig

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

=head2 Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionConfig

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::GenerativeQuestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
