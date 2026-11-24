package Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY3VzdG9tX3R1bmluZ19t
b2RlbC5wcm90bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqEIChFDdXN0b21UdW5pbmdNb2Rl
bBJMCgRuYW1lGAEgASgJQjjgQQL6QTIKMGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9DdXN0b21UdW5pbmdNb2RlbFIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3Bs
YXlOYW1lEiMKDW1vZGVsX3ZlcnNpb24YAyABKANSDG1vZGVsVmVyc2lvbhJjCgttb2RlbF9z
dGF0ZRgEIAEoDjJCLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DdXN0
b21UdW5pbmdNb2RlbC5Nb2RlbFN0YXRlUgptb2RlbFN0YXRlEj8KC2NyZWF0ZV90aW1lGAUg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEICGAFSCmNyZWF0ZVRpbWUSSgoTdHJh
aW5pbmdfc3RhcnRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSEXRy
YWluaW5nU3RhcnRUaW1lEl4KB21ldHJpY3MYByADKAsyRC5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuQ3VzdG9tVHVuaW5nTW9kZWwuTWV0cmljc0VudHJ5UgdtZXRy
aWNzGjoKDE1ldHJpY3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoAVIF
dmFsdWU6AjgBIsABCgpNb2RlbFN0YXRlEhsKF01PREVMX1NUQVRFX1VOU1BFQ0lGSUVEEAAS
EwoPVFJBSU5JTkdfUEFVU0VEEAESDAoIVFJBSU5JTkcQAhIVChFUUkFJTklOR19DT01QTEVU
RRADEhUKEVJFQURZX0ZPUl9TRVJWSU5HEAQSEwoPVFJBSU5JTkdfRkFJTEVEEAUSEgoOTk9f
SU1QUk9WRU1FTlQQBhIbChdJTlBVVF9WQUxJREFUSU9OX0ZBSUxFRBAHOqQC6kGgAgowZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0N1c3RvbVR1bmluZ01vZGVsEmhwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9y
ZX0vY3VzdG9tVHVuaW5nTW9kZWxzL3tjdXN0b21fdHVuaW5nX21vZGVsfRKBAXByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlv
bn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vY3VzdG9tVHVuaW5nTW9kZWxzL3tjdXN0b21f
dHVuaW5nX21vZGVsfUKiAgooY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYUIWQ3VzdG9tVHVuaW5nTW9kZWxQcm90b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL2Rp
c2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVu
Z2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2lu
ZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWFscGhh6gInR29v
Z2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhhSvgUCgYSBA4AXwEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBBCgkKAgglEgMWAEEKCAoBCBIDFwBpCgkKAggL
EgMXAGkKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA3CgkKAggIEgMZADcKCAoBCBID
GgBBCgkKAggBEgMaAEEKCAoBCBIDGwAtCgkKAggkEgMbAC0KCAoBCBIDHABBCgkKAggpEgMc
AEEKCAoBCBIDHQBACgkKAggtEgMdAEAKOwoCBAASBCAAXwEaLyBNZXRhZGF0YSB0aGF0IGRl
c2NyaWJlcyBhIGN1c3RvbSB0dW5lZCBtb2RlbC4KCgoKAwQAARIDIAgZCgsKAwQABxIEIQIl
BAoNCgUEAAedCBIEIQIlBAonCgQEAAQAEgQoAkADGhkgVGhlIHN0YXRlIG9mIHRoZSBtb2Rl
bC4KCgwKBQQABAABEgMoBxEKHwoGBAAEAAIAEgMqBCAaECBEZWZhdWx0IHZhbHVlLgoKDgoH
BAAEAAIAARIDKgQbCg4KBwQABAACAAISAyoeHwo5CgYEAAQAAgESAy0EGBoqIFRoZSBtb2Rl
bCBpcyBpbiBhIHBhdXNlZCB0cmFpbmluZyBzdGF0ZS4KCg4KBwQABAACAQESAy0EEwoOCgcE
AAQAAgECEgMtFhcKMQoGBAAEAAICEgMwBBEaIiBUaGUgbW9kZWwgaXMgY3VycmVudGx5IHRy
YWluaW5nLgoKDgoHBAAEAAICARIDMAQMCg4KBwQABAACAgISAzAPEAo/CgYEAAQAAgMSAzME
GhowIFRoZSBtb2RlbCBoYXMgc3VjY2Vzc2Z1bGx5IGNvbXBsZXRlZCB0cmFpbmluZy4KCg4K
BwQABAACAwESAzMEFQoOCgcEAAQAAgMCEgMzGBkKMAoGBAAEAAIEEgM2BBoaISBUaGUgbW9k
ZWwgaXMgcmVhZHkgZm9yIHNlcnZpbmcuCgoOCgcEAAQAAgQBEgM2BBUKDgoHBAAEAAIEAhID
NhgZCisKBgQABAACBRIDOQQYGhwgVGhlIG1vZGVsIHRyYWluaW5nIGZhaWxlZC4KCg4KBwQA
BAACBQESAzkEEwoOCgcEAAQAAgUCEgM5FhcKVgoGBAAEAAIGEgM8BBcaRyBUaGUgbW9kZWwg
dHJhaW5pbmcgZmluaXNoZWQgc3VjY2Vzc2Z1bGx5IGJ1dCBtZXRyaWNzIGRpZCBub3QgaW1w
cm92ZS4KCg4KBwQABAACBgESAzwEEgoOCgcEAAQAAgYCEgM8FRYKSwoGBAAEAAIHEgM/BCAa
PCBJbnB1dCBkYXRhIHZhbGlkYXRpb24gZmFpbGVkLiBNb2RlbCB0cmFpbmluZyBkaWRuJ3Qg
c3RhcnQuCgoOCgcEAAQAAgcBEgM/BBsKDgoHBAAEAAIHAhIDPx4fCqYCCgQEAAIAEgRHAkwE
GpcCIFJlcXVpcmVkLiBUaGUgZnVsbHkgcXVhbGlmaWVkIHJlc291cmNlIG5hbWUgb2YgdGhl
IG1vZGVsLgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9u
cy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRh
X3N0b3JlfS9jdXN0b21UdW5pbmdNb2RlbHMve2N1c3RvbV90dW5pbmdfbW9kZWx9YAogbW9k
ZWwgbXVzdCBiZSBhbiBhbHBoYS1udW1lcmljYWwgc3RyaW5nIHdpdGggbGltaXQgb2YgNDAg
Y2hhcmFjdGVycy4KCgwKBQQAAgAFEgNHAggKDAoFBAACAAESA0cJDQoMCgUEAAIAAxIDRxAR
Cg0KBQQAAgAIEgRHEkwDCg8KCAQAAgAInAgAEgNIBCoKDwoHBAACAAifCBIESQRLBQotCgQE
AAIBEgNPAhoaICBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBtb2RlbC4KCgwKBQQAAgEFEgNP
AggKDAoFBAACAQESA08JFQoMCgUEAAIBAxIDTxgZCigKBAQAAgISA1ICGhobIFRoZSB2ZXJz
aW9uIG9mIHRoZSBtb2RlbC4KCgwKBQQAAgIFEgNSAgcKDAoFBAACAgESA1IIFQoMCgUEAAIC
AxIDUhgZClQKBAQAAgMSA1UCHRpHIFRoZSBzdGF0ZSB0aGF0IHRoZSBtb2RlbCBpcyBpbiAo
ZS5nLmBUUkFJTklOR2Agb3IgYFRSQUlOSU5HX0ZBSUxFRGApLgoKDAoFBAACAwYSA1UCDAoM
CgUEAAIDARIDVQ0YCgwKBQQAAgMDEgNVGxwKMgoEBAACBBIDWAJAGiUgVGltZXN0YW1wIHRo
ZSBNb2RlbCB3YXMgY3JlYXRlZCBhdC4KCgwKBQQAAgQGEgNYAhsKDAoFBAACBAESA1gcJwoM
CgUEAAIEAxIDWCorCgwKBQQAAgQIEgNYLD8KDQoGBAACBAgDEgNYLT4KOgoEBAACBRIDWwI0
Gi0gVGltZXN0YW1wIHRoZSBtb2RlbCB0cmFpbmluZyB3YXMgaW5pdGlhdGVkLgoKDAoFBAAC
BQYSA1sCGwoMCgUEAAIFARIDWxwvCgwKBQQAAgUDEgNbMjMKMAoEBAACBhIDXgIiGiMgVGhl
IG1ldHJpY3Mgb2YgdGhlIHRyYWluZWQgbW9kZWwuCgoMCgUEAAIGBhIDXgIVCgwKBQQAAgYB
EgNeFh0KDAoFBAACBgMSA14gIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::CustomTuningModel ===
    # Fields for CustomTuningModel
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model_version Type: 3 ()
    # Field: model_state Type: 14 (.google.cloud.discoveryengine.v1alpha.CustomTuningModel.ModelState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: training_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: metrics Type: 11 (.google.cloud.discoveryengine.v1alpha.CustomTuningModel.MetricsEntry)

# Enum: CustomTuningModel::ModelState
our $CustomTuningModel_MODEL_STATE_UNSPECIFIED = 0;
our $CustomTuningModel_TRAINING_PAUSED = 1;
our $CustomTuningModel_TRAINING = 2;
our $CustomTuningModel_TRAINING_COMPLETE = 3;
our $CustomTuningModel_READY_FOR_SERVING = 4;
our $CustomTuningModel_TRAINING_FAILED = 5;
our $CustomTuningModel_NO_IMPROVEMENT = 6;
our $CustomTuningModel_INPUT_VALIDATION_FAILED = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/custom_tuning_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::CustomTuningModel->new({
        name => $name,
        display_name => $display_name,
        model_version => $model_version,
        model_state => $model_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::CustomTuningModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/custom_tuning_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::CustomTuningModel

Metadata that describes a custom tuned model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fully qualified resource name of the model.

Format:
`projects/{project_number}/locations/{location}/collections/{collection}/dataStores/{data_store}/customTuningModels/{custom_tuning_model}`
model must be an alpha-numerical string with limit of 40 characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the model.

=item * C<< $msg->model_version() >> / C<< $msg->model_version($value) >>

Type: C<Int64>

The version of the model.

=item * C<< $msg->model_state() >> / C<< $msg->model_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::ModelState>)

The state that the model is in (e.g.`TRAINING` or `TRAINING_FAILED`).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp the Model was created at.

=item * C<< $msg->training_start_time() >> / C<< $msg->training_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp the model training was initiated.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::CustomTuningModel::MetricsEntry>)

The metrics of the trained model.

=back

=head3 Enum: CustomTuningModel::ModelState

=over 4

=item * C<MODEL_STATE_UNSPECIFIED> => C<0>

=item * C<TRAINING_PAUSED> => C<1>

=item * C<TRAINING> => C<2>

=item * C<TRAINING_COMPLETE> => C<3>

=item * C<READY_FOR_SERVING> => C<4>

=item * C<TRAINING_FAILED> => C<5>

=item * C<NO_IMPROVEMENT> => C<6>

=item * C<INPUT_VALIDATION_FAILED> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
