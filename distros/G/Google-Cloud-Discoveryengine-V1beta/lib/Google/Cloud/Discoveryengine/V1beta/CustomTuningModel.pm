package Google::Cloud::Discoveryengine::V1beta::CustomTuningModel;

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
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jdXN0b21fdHVuaW5nX21v
ZGVsLnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLECAoRQ3VzdG9tVHVuaW5nTW9kZWwS
TAoEbmFtZRgBIAEoCUI44EEC+kEyCjBkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
Q3VzdG9tVHVuaW5nTW9kZWxSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5
TmFtZRIjCg1tb2RlbF92ZXJzaW9uGAMgASgDUgxtb2RlbFZlcnNpb24SYgoLbW9kZWxfc3Rh
dGUYBCABKA4yQS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DdXN0b21U
dW5pbmdNb2RlbC5Nb2RlbFN0YXRlUgptb2RlbFN0YXRlEj8KC2NyZWF0ZV90aW1lGAUgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEICGAFSCmNyZWF0ZVRpbWUSSgoTdHJhaW5p
bmdfc3RhcnRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSEXRyYWlu
aW5nU3RhcnRUaW1lEl0KB21ldHJpY3MYByADKAsyQy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5DdXN0b21UdW5pbmdNb2RlbC5NZXRyaWNzRW50cnlSB21ldHJpY3MS
IwoNZXJyb3JfbWVzc2FnZRgIIAEoCVIMZXJyb3JNZXNzYWdlGjoKDE1ldHJpY3NFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoAVIFdmFsdWU6AjgBIsABCgpNb2RlbFN0
YXRlEhsKF01PREVMX1NUQVRFX1VOU1BFQ0lGSUVEEAASEwoPVFJBSU5JTkdfUEFVU0VEEAES
DAoIVFJBSU5JTkcQAhIVChFUUkFJTklOR19DT01QTEVURRADEhUKEVJFQURZX0ZPUl9TRVJW
SU5HEAQSEwoPVFJBSU5JTkdfRkFJTEVEEAUSEgoOTk9fSU1QUk9WRU1FTlQQBhIbChdJTlBV
VF9WQUxJREFUSU9OX0ZBSUxFRBAHOqQC6kGgAgowZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0N1c3RvbVR1bmluZ01vZGVsEmhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vY3VzdG9tVHVuaW5nTW9kZWxz
L3tjdXN0b21fdHVuaW5nX21vZGVsfRKBAXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9z
dG9yZX0vY3VzdG9tVHVuaW5nTW9kZWxzL3tjdXN0b21fdHVuaW5nX21vZGVsfUKdAgonY29t
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhQhZDdXN0b21UdW5pbmdNb2Rl
bFByb3RvUAFaUWNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYmV0
YS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lO
RaoCI0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFCZXRhygIjR29vZ2xlXENsb3Vk
XERpc2NvdmVyeUVuZ2luZVxWMWJldGHqAiZHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdp
bmU6OlYxYmV0YUqMFgoGEgQOAGQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYA
QAoJCgIIJRIDFgBACggKAQgSAxcAaAoJCgIICxIDFwBoCggKAQgSAxgAIgoJCgIIChIDGAAi
CggKAQgSAxkANwoJCgIICBIDGQA3CggKAQgSAxoAQAoJCgIIARIDGgBACggKAQgSAxsALQoJ
CgIIJBIDGwAtCggKAQgSAxwAQAoJCgIIKRIDHABACggKAQgSAx0APwoJCgIILRIDHQA/CjsK
AgQAEgQgAGQBGi8gTWV0YWRhdGEgdGhhdCBkZXNjcmliZXMgYSBjdXN0b20gdHVuZWQgbW9k
ZWwuCgoKCgMEAAESAyAIGQoLCgMEAAcSBCECJQQKDQoFBAAHnQgSBCECJQQKJwoEBAAEABIE
KAJAAxoZIFRoZSBzdGF0ZSBvZiB0aGUgbW9kZWwuCgoMCgUEAAQAARIDKAcRCh8KBgQABAAC
ABIDKgQgGhAgRGVmYXVsdCB2YWx1ZS4KCg4KBwQABAACAAESAyoEGwoOCgcEAAQAAgACEgMq
Hh8KOQoGBAAEAAIBEgMtBBgaKiBUaGUgbW9kZWwgaXMgaW4gYSBwYXVzZWQgdHJhaW5pbmcg
c3RhdGUuCgoOCgcEAAQAAgEBEgMtBBMKDgoHBAAEAAIBAhIDLRYXCjEKBgQABAACAhIDMAQR
GiIgVGhlIG1vZGVsIGlzIGN1cnJlbnRseSB0cmFpbmluZy4KCg4KBwQABAACAgESAzAEDAoO
CgcEAAQAAgICEgMwDxAKPwoGBAAEAAIDEgMzBBoaMCBUaGUgbW9kZWwgaGFzIHN1Y2Nlc3Nm
dWxseSBjb21wbGV0ZWQgdHJhaW5pbmcuCgoOCgcEAAQAAgMBEgMzBBUKDgoHBAAEAAIDAhID
MxgZCjAKBgQABAACBBIDNgQaGiEgVGhlIG1vZGVsIGlzIHJlYWR5IGZvciBzZXJ2aW5nLgoK
DgoHBAAEAAIEARIDNgQVCg4KBwQABAACBAISAzYYGQorCgYEAAQAAgUSAzkEGBocIFRoZSBt
b2RlbCB0cmFpbmluZyBmYWlsZWQuCgoOCgcEAAQAAgUBEgM5BBMKDgoHBAAEAAIFAhIDORYX
ClYKBgQABAACBhIDPAQXGkcgVGhlIG1vZGVsIHRyYWluaW5nIGZpbmlzaGVkIHN1Y2Nlc3Nm
dWxseSBidXQgbWV0cmljcyBkaWQgbm90IGltcHJvdmUuCgoOCgcEAAQAAgYBEgM8BBIKDgoH
BAAEAAIGAhIDPBUWCksKBgQABAACBxIDPwQgGjwgSW5wdXQgZGF0YSB2YWxpZGF0aW9uIGZh
aWxlZC4gTW9kZWwgdHJhaW5pbmcgZGlkbid0IHN0YXJ0LgoKDgoHBAAEAAIHARIDPwQbCg4K
BwQABAACBwISAz8eHwqhAgoEBAACABIESAJNBBqSAiBSZXF1aXJlZC4gVGhlIGZ1bGx5IHF1
YWxpZmllZCByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbC4KCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0
aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9jdXN0b21UdW5pbmdNb2RlbHMve2N1c3Rv
bV90dW5pbmdfbW9kZWx9YC4KCiBNb2RlbCBtdXN0IGJlIGFuIGFscGhhLW51bWVyaWNhbCBz
dHJpbmcgd2l0aCBsaW1pdCBvZiA0MCBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSA0gCCAoMCgUE
AAIAARIDSAkNCgwKBQQAAgADEgNIEBEKDQoFBAACAAgSBEgSTQMKDwoIBAACAAicCAASA0kE
KgoPCgcEAAIACJ8IEgRKBEwFCi0KBAQAAgESA1ACGhogIFRoZSBkaXNwbGF5IG5hbWUgb2Yg
dGhlIG1vZGVsLgoKDAoFBAACAQUSA1ACCAoMCgUEAAIBARIDUAkVCgwKBQQAAgEDEgNQGBkK
KAoEBAACAhIDUwIaGhsgVGhlIHZlcnNpb24gb2YgdGhlIG1vZGVsLgoKDAoFBAACAgUSA1MC
BwoMCgUEAAICARIDUwgVCgwKBQQAAgIDEgNTGBkKVAoEBAACAxIDVgIdGkcgVGhlIHN0YXRl
IHRoYXQgdGhlIG1vZGVsIGlzIGluIChlLmcuYFRSQUlOSU5HYCBvciBgVFJBSU5JTkdfRkFJ
TEVEYCkuCgoMCgUEAAIDBhIDVgIMCgwKBQQAAgMBEgNWDRgKDAoFBAACAwMSA1YbHAo+CgQE
AAIEEgNZAkAaMSBEZXByZWNhdGVkOiBUaW1lc3RhbXAgdGhlIE1vZGVsIHdhcyBjcmVhdGVk
IGF0LgoKDAoFBAACBAYSA1kCGwoMCgUEAAIEARIDWRwnCgwKBQQAAgQDEgNZKisKDAoFBAAC
BAgSA1ksPwoNCgYEAAIECAMSA1ktPgo6CgQEAAIFEgNcAjQaLSBUaW1lc3RhbXAgdGhlIG1v
ZGVsIHRyYWluaW5nIHdhcyBpbml0aWF0ZWQuCgoMCgUEAAIFBhIDXAIbCgwKBQQAAgUBEgNc
HC8KDAoFBAACBQMSA1wyMwowCgQEAAIGEgNfAiIaIyBUaGUgbWV0cmljcyBvZiB0aGUgdHJh
aW5lZCBtb2RlbC4KCgwKBQQAAgYGEgNfAhUKDAoFBAACBgESA18WHQoMCgUEAAIGAxIDXyAh
CmEKBAQAAgcSA2MCGxpUIEN1cnJlbnRseSB0aGlzIGlzIG9ubHkgcG9wdWxhdGVkIGlmIHRo
ZSBtb2RlbCBzdGF0ZSBpcwogYElOUFVUX1ZBTElEQVRJT05fRkFJTEVEYC4KCgwKBQQAAgcF
EgNjAggKDAoFBAACBwESA2MJFgoMCgUEAAIHAxIDYxkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel ===
    # Fields for CustomTuningModel
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model_version Type: 3 ()
    # Field: model_state Type: 14 (.google.cloud.discoveryengine.v1beta.CustomTuningModel.ModelState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: training_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: metrics Type: 11 (.google.cloud.discoveryengine.v1beta.CustomTuningModel.MetricsEntry)
    # Field: error_message Type: 9 ()

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

Google::Cloud::Discoveryengine::V1beta::CustomTuningModel - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/custom_tuning_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::CustomTuningModel;

    my $msg = Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel->new({
        name => $name,
        display_name => $display_name,
        model_version => $model_version,
        model_state => $model_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/custom_tuning_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel

Metadata that describes a custom tuned model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fully qualified resource name of the model.

Format:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/customTuningModels/{custom_tuning_model}`.

Model must be an alpha-numerical string with limit of 40 characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the model.

=item * C<< $msg->model_version() >> / C<< $msg->model_version($value) >>

Type: C<Int64>

The version of the model.

=item * C<< $msg->model_state() >> / C<< $msg->model_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::ModelState>)

The state that the model is in (e.g.`TRAINING` or `TRAINING_FAILED`).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Deprecated: Timestamp the Model was created at.

=item * C<< $msg->training_start_time() >> / C<< $msg->training_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp the model training was initiated.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel::MetricsEntry>)

The metrics of the trained model.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Currently this is only populated if the model state is
`INPUT_VALIDATION_FAILED`.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
