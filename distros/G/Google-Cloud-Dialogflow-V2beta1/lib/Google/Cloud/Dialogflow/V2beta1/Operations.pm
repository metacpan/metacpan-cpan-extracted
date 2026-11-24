package Google::Cloud::Dialogflow::V2beta1::Operations;

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
CjBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL29wZXJhdGlvbnMucHJvdG8SH2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iXgokR2VuZXJhdG9yRXZhbHVh
dGlvbk9wZXJhdGlvbk1ldGFkYXRhEjYKFGdlbmVyYXRvcl9ldmFsdWF0aW9uGAEgASgJQgPg
QQNSE2dlbmVyYXRvckV2YWx1YXRpb25CpAEKI2NvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52MmJldGExQg9PcGVyYXRpb25zUHJvdG9QAVpDY2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFs
b2dmbG93L2FwaXYyYmV0YTEvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIfR29v
Z2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJCZXRhMUqmCQoGEgQOACQBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoI
CgEIEgMVADwKCQoCCCUSAxUAPAoICgEIEgMWAFoKCQoCCAsSAxYAWgoICgEIEgMXACIKCQoC
CAoSAxcAIgoICgEIEgMYADAKCQoCCAgSAxgAMAoICgEIEgMZADwKCQoCCAESAxkAPAoICgEI
EgMaACAKCQoCCCQSAxoAIAqrAQoCBAASBB8AJAEangEgTWV0YWRhdGEgZm9yIGEKIFtHZW5l
cmF0b3JFdmFsdWF0aW9ucy5DcmVhdGVHZW5lcmF0b3JFdmFsdWF0aW9uXVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MmJldGExLkdlbmVyYXRvckV2YWx1YXRpb25zLkNyZWF0ZUdlbmVy
YXRvckV2YWx1YXRpb25dCiBvcGVyYXRpb24uCgoKCgMEAAESAx8ILAq7AQoEBAACABIDIwJO
Gq0BIE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZ2VuZXJhdG9yIGV2
YWx1YXRpb24uIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxM
b2NhdGlvbgogSUQ+L2dlbmVyYXRvcnMvPEdlbmVyYXRvciBJRD4vZXZhbHVhdGlvbnMvPEV2
YWx1YXRpb24gSUQ+YAoKDAoFBAACAAUSAyMCCAoMCgUEAAIAARIDIwkdCgwKBQQAAgADEgMj
ICEKDAoFBAACAAgSAyMiTQoPCggEAAIACJwIABIDIyNMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata ===
    # Fields for GeneratorEvaluationOperationMetadata
    # Field: generator_evaluation Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Operations - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Operations;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata->new({
        generator_evaluation => $generator_evaluation,
    });

    # Read or update a field
    my $val = $msg->generator_evaluation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata

Metadata for a
[GeneratorEvaluations.CreateGeneratorEvaluation][google.cloud.dialogflow.v2beta1.GeneratorEvaluations.CreateGeneratorEvaluation]
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
