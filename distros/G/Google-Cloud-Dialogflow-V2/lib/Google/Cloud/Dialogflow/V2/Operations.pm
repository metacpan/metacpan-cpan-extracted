package Google::Cloud::Dialogflow::V2::Operations;

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
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9vcGVyYXRpb25zLnByb3RvEhpnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byJeCiRHZW5lcmF0b3JFdmFsdWF0aW9uT3BlcmF0
aW9uTWV0YWRhdGESNgoUZ2VuZXJhdG9yX2V2YWx1YXRpb24YASABKAlCA+BBA1ITZ2VuZXJh
dG9yRXZhbHVhdGlvbkKVAQoeY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyQg9PcGVy
YXRpb25zUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2FwaXYyL2Rp
YWxvZ2Zsb3dwYjtkaWFsb2dmbG93cGKiAgJERqoCGkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93
LlYySqEJCgYSBA4AJAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
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
EgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUANwoJCgIIJRIDFQA3CggKAQgS
AxYAVQoJCgIICxIDFgBVCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAMAoJCgIICBID
GAAwCggKAQgSAxkANwoJCgIIARIDGQA3CggKAQgSAxoAIAoJCgIIJBIDGgAgCqYBCgIEABIE
HwAkARqZASBNZXRhZGF0YSBmb3IgYQogW0dlbmVyYXRvckV2YWx1YXRpb25zLkNyZWF0ZUdl
bmVyYXRvckV2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkdlbmVyYXRv
ckV2YWx1YXRpb25zLkNyZWF0ZUdlbmVyYXRvckV2YWx1YXRpb25dCiBvcGVyYXRpb24uCgoK
CgMEAAESAx8ILAq7AQoEBAACABIDIwJOGq0BIE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZ2VuZXJhdG9yIGV2YWx1YXRpb24uIEZvcm1hdDoKIGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgogSUQ+L2dlbmVyYXRvcnMvPEdlbmVy
YXRvciBJRD4vZXZhbHVhdGlvbnMvPEV2YWx1YXRpb24gSUQ+YAoKDAoFBAACAAUSAyMCCAoM
CgUEAAIAARIDIwkdCgwKBQQAAgADEgMjICEKDAoFBAACAAgSAyMiTQoPCggEAAIACJwIABID
IyNMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Operations::GeneratorEvaluationOperationMetadata ===
    # Fields for GeneratorEvaluationOperationMetadata
    # Field: generator_evaluation Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Operations - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Operations;

    my $msg = Google::Cloud::Dialogflow::V2::Operations::GeneratorEvaluationOperationMetadata->new({
        generator_evaluation => $generator_evaluation,
    });

    # Read or update a field
    my $val = $msg->generator_evaluation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Operations::GeneratorEvaluationOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Operations::GeneratorEvaluationOperationMetadata

Metadata for a
[GeneratorEvaluations.CreateGeneratorEvaluation][google.cloud.dialogflow.v2.GeneratorEvaluations.CreateGeneratorEvaluation]
operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generator_evaluation() >> / C<< $msg->generator_evaluation($value) >>

Type: C<String>

Output only. The resource name of the generator evaluation. Format:
`projects/<Project ID>/locations/<Location
ID>/generators/<Generator ID>/evaluations/<Evaluation ID>`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
