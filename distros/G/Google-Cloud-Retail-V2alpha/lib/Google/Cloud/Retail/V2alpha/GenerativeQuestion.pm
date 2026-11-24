package Google::Cloud::Retail::V2alpha::GenerativeQuestion;

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
CjVnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvZ2VuZXJhdGl2ZV9xdWVzdGlvbi5wcm90
bxIbZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvIp8BCiBHZW5lcmF0aXZlUXVlc3Rpb25zRmVhdHVyZUNvbmZpZxIdCgdjYXRh
bG9nGAEgASgJQgPgQQJSB2NhdGFsb2cSLAoPZmVhdHVyZV9lbmFibGVkGAIgASgIQgPgQQFS
DmZlYXR1cmVFbmFibGVkEi4KEG1pbmltdW1fcHJvZHVjdHMYAyABKAVCA+BBAVIPbWluaW11
bVByb2R1Y3RzIsACChhHZW5lcmF0aXZlUXVlc3Rpb25Db25maWcSHQoHY2F0YWxvZxgBIAEo
CUID4EECUgdjYXRhbG9nEhkKBWZhY2V0GAIgASgJQgPgQQJSBWZhY2V0EjIKEmdlbmVyYXRl
ZF9xdWVzdGlvbhgDIAEoCUID4EEDUhFnZW5lcmF0ZWRRdWVzdGlvbhIqCg5maW5hbF9xdWVz
dGlvbhgEIAEoCUID4EEBUg1maW5hbFF1ZXN0aW9uEioKDmV4YW1wbGVfdmFsdWVzGAUgAygJ
QgPgQQNSDWV4YW1wbGVWYWx1ZXMSIQoJZnJlcXVlbmN5GAYgASgCQgPgQQNSCWZyZXF1ZW5j
eRI7ChdhbGxvd2VkX2luX2NvbnZlcnNhdGlvbhgHIAEoCEID4EEBUhVhbGxvd2VkSW5Db252
ZXJzYXRpb25C2wEKH2NvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGFCF0dlbmVyYXRp
dmVRdWVzdGlvblByb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxw
aGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYy
QWxwaGHKAhtHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpS
ZXRhaWw6OlYyYWxwaGFK1hUKBhIEDgBHAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgApCggKAQgSAxQAOAoJCgIIJRIDFAA4CggKAQgS
AxUATgoJCgIICxIDFQBOCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOAoJCgIICBID
FwA4CggKAQgSAxgAOAoJCgIIARIDGAA4CggKAQgSAxkAJAoJCgIIJBIDGQAkCggKAQgSAxoA
OAoJCgIIKRIDGgA4CggKAQgSAxsANwoJCgIILRIDGwA3CkoKAgQAEgQeACsBGj4gQ29uZmln
dXJhdGlvbiBmb3Igb3ZlcmFsbCBnZW5lcmF0aXZlIHF1ZXN0aW9uIGZlYXR1cmUgc3RhdGUu
CgoKCgMEAAESAx4IKAqDAQoEBAACABIDIQI+GnYgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUg
b2YgdGhlIGFmZmVjdGVkIGNhdGFsb2cuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9jYXRhbG9ncy97Y2F0YWxvZ30KCgwKBQQAAgAFEgMhAggK
DAoFBAACAAESAyEJEAoMCgUEAAIAAxIDIRMUCgwKBQQAAgAIEgMhFT0KDwoIBAACAAicCAAS
AyEWPAqqAQoEBAACARIDJgJEGpwBIE9wdGlvbmFsLiBEZXRlcm1pbmVzIHdoZXRoZXIgcXVl
c3Rpb25zIHdpbGwgYmUgdXNlZCBhdCBzZXJ2aW5nIHRpbWUuCiBOb3RlOiBUaGlzIGZlYXR1
cmUgY2Fubm90IGJlIGVuYWJsZWQgdW50aWwgaW5pdGlhbCBkYXRhIHJlcXVpcmVtZW50cyBh
cmUKIHNhdGlzZmllZC4KCgwKBQQAAgEFEgMmAgYKDAoFBAACAQESAyYHFgoMCgUEAAIBAxID
JhkaCgwKBQQAAgEIEgMmG0MKDwoIBAACAQicCAASAyYcQgqBAQoEBAACAhIDKgJGGnQgT3B0
aW9uYWwuIE1pbmltdW0gbnVtYmVyIG9mIHByb2R1Y3RzIGluIHRoZSByZXNwb25zZSB0byB0
cmlnZ2VyIGZvbGxvdy11cAogcXVlc3Rpb25zLiBWYWx1ZSBtdXN0IGJlIDAgb3IgcG9zaXRp
dmUuCgoMCgUEAAICBRIDKgIHCgwKBQQAAgIBEgMqCBgKDAoFBAACAgMSAyobHAoMCgUEAAIC
CBIDKh1FCg8KCAQAAgIInAgAEgMqHkQKPAoCBAESBC4ARwEaMCBDb25maWd1cmF0aW9uIGZv
ciBhIHNpbmdsZSBnZW5lcmF0ZWQgcXVlc3Rpb24uCgoKCgMEAQESAy4IIAp6CgQEAQIAEgMx
Aj4abSBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgY2F0YWxvZy4KIEZvcm1hdDog
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRh
bG9nfQoKDAoFBAECAAUSAzECCAoMCgUEAQIAARIDMQkQCgwKBQQBAgADEgMxExQKDAoFBAEC
AAgSAzEVPQoPCggEAQIACJwIABIDMRY8CkcKBAQBAgESAzQCPBo6IFJlcXVpcmVkLiBUaGUg
ZmFjZXQgdG8gd2hpY2ggdGhlIHF1ZXN0aW9uIGlzIGFzc29jaWF0ZWQuCgoMCgUEAQIBBRID
NAIICgwKBQQBAgEBEgM0CQ4KDAoFBAECAQMSAzQREgoMCgUEAQIBCBIDNBM7Cg8KCAQBAgEI
nAgAEgM0FDoKNwoEBAECAhIDNwJMGiogT3V0cHV0IG9ubHkuIFRoZSBMTE0gZ2VuZXJhdGVk
IHF1ZXN0aW9uLgoKDAoFBAECAgUSAzcCCAoMCgUEAQICARIDNwkbCgwKBQQBAgIDEgM3Hh8K
DAoFBAECAggSAzcgSwoPCggEAQICCJwIABIDNyFKCq8BCgQEAQIDEgM8AkUaoQEgT3B0aW9u
YWwuIFRoZSBxdWVzdGlvbiB0aGF0IHdpbGwgYmUgdXNlZCBhdCBzZXJ2aW5nIHRpbWUuCiBR
dWVzdGlvbiBjYW4gaGF2ZSBhIG1heCBsZW5ndGggb2YgMzAwIGJ5dGVzLgogV2hlbiBub3Qg
cG9wdWxhdGVkLCBnZW5lcmF0ZWRfcXVlc3Rpb24gc2hvdWxkIGJlIHVzZWQuCgoMCgUEAQID
BRIDPAIICgwKBQQBAgMBEgM8CRcKDAoFBAECAwMSAzwaGwoMCgUEAQIDCBIDPBxECg8KCAQB
AgMInAgAEgM8HUMKTAoEBAECBBIEPwJAMho+IE91dHB1dCBvbmx5LiBWYWx1ZXMgdGhhdCBj
YW4gYmUgdXNlZCB0byBhbnN3ZXIgdGhlIHF1ZXN0aW9uLgoKDAoFBAECBAQSAz8CCgoMCgUE
AQIEBRIDPwsRCgwKBQQBAgQBEgM/EiAKDAoFBAECBAMSAz8jJAoMCgUEAQIECBIDQAYxCg8K
CAQBAgQInAgAEgNABzAKSAoEBAECBRIDQwJCGjsgT3V0cHV0IG9ubHkuIFRoZSByYXRpbyBv
ZiBob3cgb2Z0ZW4gYSBxdWVzdGlvbiB3YXMgYXNrZWQuCgoMCgUEAQIFBRIDQwIHCgwKBQQB
AgUBEgNDCBEKDAoFBAECBQMSA0MUFQoMCgUEAQIFCBIDQxZBCg8KCAQBAgUInAgAEgNDF0AK
RwoEBAECBhIDRgJMGjogT3B0aW9uYWwuIFdoZXRoZXIgdGhlIHF1ZXN0aW9uIGlzIGFza2Vk
IGF0IHNlcnZpbmcgdGltZS4KCgwKBQQBAgYFEgNGAgYKDAoFBAECBgESA0YHHgoMCgUEAQIG
AxIDRiEiCgwKBQQBAgYIEgNGI0sKDwoIBAECBgicCAASA0YkSmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig ===
    # Fields for GenerativeQuestionsFeatureConfig
    # Field: catalog Type: 9 ()
    # Field: feature_enabled Type: 8 ()
    # Field: minimum_products Type: 5 ()

# === Message: Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig ===
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

Google::Cloud::Retail::V2alpha::GenerativeQuestion - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/generative_question.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::GenerativeQuestion;

    my $msg = Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig->new({
        catalog => $catalog,
        feature_enabled => $feature_enabled,
        minimum_products => $minimum_products,
    });

    # Read or update a field
    my $val = $msg->catalog();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/generative_question.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig

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

=head2 Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::GenerativeQuestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
