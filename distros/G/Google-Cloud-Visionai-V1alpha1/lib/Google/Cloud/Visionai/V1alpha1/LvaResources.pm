package Google::Cloud::Visionai::V1alpha1::LvaResources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Visionai::V1alpha1::Lva };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvbHZhX3Jlc291cmNlcy5wcm90bxIe
Z29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvdmlz
aW9uYWkvdjFhbHBoYTEvbHZhLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvIokHCghBbmFseXNpcxISCgRuYW1lGAEgASgJUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3Vw
ZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRh
dGVUaW1lEkwKBmxhYmVscxgEIAMoCzI0Lmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhh
MS5BbmFseXNpcy5MYWJlbHNFbnRyeVIGbGFiZWxzEmMKE2FuYWx5c2lzX2RlZmluaXRpb24Y
BSABKAsyMi5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQW5hbHlzaXNEZWZpbml0
aW9uUhJhbmFseXNpc0RlZmluaXRpb24SdQoVaW5wdXRfc3RyZWFtc19tYXBwaW5nGAYgAygL
MkEuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLkFuYWx5c2lzLklucHV0U3RyZWFt
c01hcHBpbmdFbnRyeVITaW5wdXRTdHJlYW1zTWFwcGluZxJ4ChZvdXRwdXRfc3RyZWFtc19t
YXBwaW5nGAcgAygLMkIuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLkFuYWx5c2lz
Lk91dHB1dFN0cmVhbXNNYXBwaW5nRW50cnlSFG91dHB1dFN0cmVhbXNNYXBwaW5nGjkKC0xh
YmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEa
RgoYSW5wdXRTdHJlYW1zTWFwcGluZ0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgJUgV2YWx1ZToCOAEaRwoZT3V0cHV0U3RyZWFtc01hcHBpbmdFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOnXqQXIKIHZpc2lvbmFpLmdv
b2dsZWFwaXMuY29tL0FuYWx5c2lzEk5wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vY2x1c3RlcnMve2NsdXN0ZXJ9L2FuYWx5c2VzL3thbmFseXNpc31C3wEKImNv
bS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTFCEUx2YVJlc291cmNlc1Byb3RvUAFa
PmNsb3VkLmdvb2dsZS5jb20vZ28vdmlzaW9uYWkvYXBpdjFhbHBoYTEvdmlzaW9uYWlwYjt2
aXNpb25haXBiqgIeR29vZ2xlLkNsb3VkLlZpc2lvbkFJLlYxQWxwaGExygIeR29vZ2xlXENs
b3VkXFZpc2lvbkFJXFYxYWxwaGEx6gIhR29vZ2xlOjpDbG91ZDo6VmlzaW9uQUk6OlYxYWxw
aGExSsQPCgYSBA4AQAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADIKCQoCAwMSAxUAKQoICgEI
EgMXADsKCQoCCCUSAxcAOwoICgEIEgMYAFUKCQoCCAsSAxgAVQoICgEIEgMZACIKCQoCCAoS
AxkAIgoICgEIEgMaADIKCQoCCAgSAxoAMgoICgEIEgMbADsKCQoCCAESAxsAOwoICgEIEgMc
ADsKCQoCCCkSAxwAOwoICgEIEgMdADoKCQoCCC0SAx0AOgo1CgIEABIEIABAARopIE1lc3Nh
Z2UgZGVzY3JpYmluZyB0aGUgQW5hbHlzaXMgb2JqZWN0LgoKCgoDBAABEgMgCBAKCwoDBAAH
EgQhAiQECg0KBQQAB50IEgQhAiQECiQKBAQAAgASAycCEhoXIFRoZSBuYW1lIG9mIHJlc291
cmNlLgoKDAoFBAACAAUSAycCCAoMCgUEAAIAARIDJwkNCgwKBQQAAgADEgMnEBEKMQoEBAAC
ARIDKgJYGiQgT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGUgdGltZXN0YW1wLgoKDAoFBAACAQYS
AyoCGwoMCgUEAAIBARIDKhwnCgwKBQQAAgEDEgMqKisKDAoFBAACAQgSAyosVwoPCggEAAIB
CJwIABIDKi1WCjEKBAQAAgISAy0CWBokIE91dHB1dCBvbmx5LiBUaGUgdXBkYXRlIHRpbWVz
dGFtcC4KCgwKBQQAAgIGEgMtAhsKDAoFBAACAgESAy0cJwoMCgUEAAICAxIDLSorCgwKBQQA
AgIIEgMtLFcKDwoIBAACAgicCAASAy0tVgopCgQEAAIDEgMwAiEaHCBMYWJlbHMgYXMga2V5
IHZhbHVlIHBhaXJzLgoKDAoFBAACAwYSAzACFQoMCgUEAAIDARIDMBYcCgwKBQQAAgMDEgMw
HyAKLgoEBAACBBIDMwItGiEgVGhlIGRlZmluaXRpb24gb2YgdGhlIGFuYWx5c2lzLgoKDAoF
BAACBAYSAzMCFAoMCgUEAAIEARIDMxUoCgwKBQQAAgQDEgMzKywKhAIKBAQAAgUSAzkCMBr2
ASBNYXAgZnJvbSB0aGUgaW5wdXQgcGFyYW1ldGVyIGluIHRoZSBkZWZpbml0aW9uIHRvIHRo
ZSByZWFsIHN0cmVhbS4KIEUuZy4sIHN1cHBvc2UgeW91IGhhZCBhIHN0cmVhbSBzb3VyY2Ug
b3BlcmF0b3IgbmFtZWQgImlucHV0LTAiIGFuZCB5b3UgdHJ5CiB0byByZWNlaXZlIGZyb20g
dGhlIHJlYWwgc3RyZWFtICJzdHJlYW0tMCIuIFlvdSBjYW4gYWRkIHRoZSBmb2xsb3dpbmcK
IG1hcHBpbmc6IFtpbnB1dC0wOiBzdHJlYW0tMF0uCgoMCgUEAAIFBhIDOQIVCgwKBQQAAgUB
EgM5FisKDAoFBAACBQMSAzkuLwqAAgoEBAACBhIDPwIxGvIBIE1hcCBmcm9tIHRoZSBvdXRw
dXQgcGFyYW1ldGVyIGluIHRoZSBkZWZpbml0aW9uIHRvIHRoZSByZWFsIHN0cmVhbS4KIEUu
Zy4sIHN1cHBvc2UgeW91IGhhZCBhIHN0cmVhbSBzaW5rIG9wZXJhdG9yIG5hbWVkICJvdXRw
dXQtMCIgYW5kIHlvdSB0cnkKIHRvIHNlbmQgdG8gdGhlIHJlYWwgc3RyZWFtICJzdHJlYW0t
MCIuIFlvdSBjYW4gYWRkIHRoZSBmb2xsb3dpbmcKIG1hcHBpbmc6IFtvdXRwdXQtMDogc3Ry
ZWFtLTBdLgoKDAoFBAACBgYSAz8CFQoMCgUEAAIGARIDPxYsCgwKBQQAAgYDEgM/LzBiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis ===
    # Fields for Analysis
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1alpha1.Analysis.LabelsEntry)
    # Field: analysis_definition Type: 11 (.google.cloud.visionai.v1alpha1.AnalysisDefinition)
    # Field: input_streams_mapping Type: 11 (.google.cloud.visionai.v1alpha1.Analysis.InputStreamsMappingEntry)
    # Field: output_streams_mapping Type: 11 (.google.cloud.visionai.v1alpha1.Analysis.OutputStreamsMappingEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::LvaResources - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/lva_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::LvaResources;

    my $msg = Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/lva_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis

Message describing the Analysis object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->analysis_definition() >> / C<< $msg->analysis_definition($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Lva::AnalysisDefinition>)

The definition of the analysis.

=item * C<< $msg->input_streams_mapping() >> / C<< $msg->input_streams_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::InputStreamsMappingEntry>)

Map from the input parameter in the definition to the real stream.
E.g., suppose you had a stream source operator named "input-0" and you try
to receive from the real stream "stream-0". You can add the following
mapping: [input-0: stream-0].

=item * C<< $msg->output_streams_mapping() >> / C<< $msg->output_streams_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::OutputStreamsMappingEntry>)

Map from the output parameter in the definition to the real stream.
E.g., suppose you had a stream sink operator named "output-0" and you try
to send to the real stream "stream-0". You can add the following
mapping: [output-0: stream-0].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::LvaResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
