package Google::Cloud::Discoveryengine::V1::CustomTuningModel;

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
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2N1c3RvbV90dW5pbmdfbW9kZWwu
cHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8ivAgKEUN1c3RvbVR1bmluZ01vZGVsEkwKBG5hbWUY
ASABKAlCOOBBAvpBMgowZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0N1c3RvbVR1
bmluZ01vZGVsUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSIwoN
bW9kZWxfdmVyc2lvbhgDIAEoA1IMbW9kZWxWZXJzaW9uEl4KC21vZGVsX3N0YXRlGAQgASgO
Mj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5DdXN0b21UdW5pbmdNb2RlbC5N
b2RlbFN0YXRlUgptb2RlbFN0YXRlEj8KC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEICGAFSCmNyZWF0ZVRpbWUSSgoTdHJhaW5pbmdfc3RhcnRfdGlt
ZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSEXRyYWluaW5nU3RhcnRUaW1l
ElkKB21ldHJpY3MYByADKAsyPy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkN1
c3RvbVR1bmluZ01vZGVsLk1ldHJpY3NFbnRyeVIHbWV0cmljcxIjCg1lcnJvcl9tZXNzYWdl
GAggASgJUgxlcnJvck1lc3NhZ2UaOgoMTWV0cmljc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgBUgV2YWx1ZToCOAEiwAEKCk1vZGVsU3RhdGUSGwoXTU9ERUxfU1RB
VEVfVU5TUEVDSUZJRUQQABITCg9UUkFJTklOR19QQVVTRUQQARIMCghUUkFJTklORxACEhUK
EVRSQUlOSU5HX0NPTVBMRVRFEAMSFQoRUkVBRFlfRk9SX1NFUlZJTkcQBBITCg9UUkFJTklO
R19GQUlMRUQQBRISCg5OT19JTVBST1ZFTUVOVBAGEhsKF0lOUFVUX1ZBTElEQVRJT05fRkFJ
TEVEEAc6pALqQaACCjBkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ3VzdG9tVHVu
aW5nTW9kZWwSaHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRh
U3RvcmVzL3tkYXRhX3N0b3JlfS9jdXN0b21UdW5pbmdNb2RlbHMve2N1c3RvbV90dW5pbmdf
bW9kZWx9EoEBcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxl
Y3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9jdXN0b21UdW5p
bmdNb2RlbHMve2N1c3RvbV90dW5pbmdfbW9kZWx9QokCCiNjb20uZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MUIWQ3VzdG9tVHVuaW5nTW9kZWxQcm90b1ABWk1jbG91ZC5nb29n
bGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNj
b3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3Zl
cnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xl
OjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUqMFgoGEgQOAGQBCrwECgEMEgMOABIysQQg
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
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJ
CgIDAhIDFAApCggKAQgSAxYAPAoJCgIIJRIDFgA8CggKAQgSAxcAZAoJCgIICxIDFwBkCggK
AQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkANwoJCgIICBIDGQA3CggKAQgSAxoAPAoJCgII
ARIDGgA8CggKAQgSAxsALQoJCgIIJBIDGwAtCggKAQgSAxwAPAoJCgIIKRIDHAA8CggKAQgS
Ax0AOwoJCgIILRIDHQA7CjsKAgQAEgQgAGQBGi8gTWV0YWRhdGEgdGhhdCBkZXNjcmliZXMg
YSBjdXN0b20gdHVuZWQgbW9kZWwuCgoKCgMEAAESAyAIGQoLCgMEAAcSBCECJQQKDQoFBAAH
nQgSBCECJQQKJwoEBAAEABIEKAJAAxoZIFRoZSBzdGF0ZSBvZiB0aGUgbW9kZWwuCgoMCgUE
AAQAARIDKAcRCh8KBgQABAACABIDKgQgGhAgRGVmYXVsdCB2YWx1ZS4KCg4KBwQABAACAAES
AyoEGwoOCgcEAAQAAgACEgMqHh8KOQoGBAAEAAIBEgMtBBgaKiBUaGUgbW9kZWwgaXMgaW4g
YSBwYXVzZWQgdHJhaW5pbmcgc3RhdGUuCgoOCgcEAAQAAgEBEgMtBBMKDgoHBAAEAAIBAhID
LRYXCjEKBgQABAACAhIDMAQRGiIgVGhlIG1vZGVsIGlzIGN1cnJlbnRseSB0cmFpbmluZy4K
Cg4KBwQABAACAgESAzAEDAoOCgcEAAQAAgICEgMwDxAKPwoGBAAEAAIDEgMzBBoaMCBUaGUg
bW9kZWwgaGFzIHN1Y2Nlc3NmdWxseSBjb21wbGV0ZWQgdHJhaW5pbmcuCgoOCgcEAAQAAgMB
EgMzBBUKDgoHBAAEAAIDAhIDMxgZCjAKBgQABAACBBIDNgQaGiEgVGhlIG1vZGVsIGlzIHJl
YWR5IGZvciBzZXJ2aW5nLgoKDgoHBAAEAAIEARIDNgQVCg4KBwQABAACBAISAzYYGQorCgYE
AAQAAgUSAzkEGBocIFRoZSBtb2RlbCB0cmFpbmluZyBmYWlsZWQuCgoOCgcEAAQAAgUBEgM5
BBMKDgoHBAAEAAIFAhIDORYXClYKBgQABAACBhIDPAQXGkcgVGhlIG1vZGVsIHRyYWluaW5n
IGZpbmlzaGVkIHN1Y2Nlc3NmdWxseSBidXQgbWV0cmljcyBkaWQgbm90IGltcHJvdmUuCgoO
CgcEAAQAAgYBEgM8BBIKDgoHBAAEAAIGAhIDPBUWCksKBgQABAACBxIDPwQgGjwgSW5wdXQg
ZGF0YSB2YWxpZGF0aW9uIGZhaWxlZC4gTW9kZWwgdHJhaW5pbmcgZGlkbid0IHN0YXJ0LgoK
DgoHBAAEAAIHARIDPwQbCg4KBwQABAACBwISAz8eHwqhAgoEBAACABIESAJNBBqSAiBSZXF1
aXJlZC4gVGhlIGZ1bGx5IHF1YWxpZmllZCByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbC4K
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nv
bGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9jdXN0b21U
dW5pbmdNb2RlbHMve2N1c3RvbV90dW5pbmdfbW9kZWx9YC4KCiBNb2RlbCBtdXN0IGJlIGFu
IGFscGhhLW51bWVyaWNhbCBzdHJpbmcgd2l0aCBsaW1pdCBvZiA0MCBjaGFyYWN0ZXJzLgoK
DAoFBAACAAUSA0gCCAoMCgUEAAIAARIDSAkNCgwKBQQAAgADEgNIEBEKDQoFBAACAAgSBEgS
TQMKDwoIBAACAAicCAASA0kEKgoPCgcEAAIACJ8IEgRKBEwFCi0KBAQAAgESA1ACGhogIFRo
ZSBkaXNwbGF5IG5hbWUgb2YgdGhlIG1vZGVsLgoKDAoFBAACAQUSA1ACCAoMCgUEAAIBARID
UAkVCgwKBQQAAgEDEgNQGBkKKAoEBAACAhIDUwIaGhsgVGhlIHZlcnNpb24gb2YgdGhlIG1v
ZGVsLgoKDAoFBAACAgUSA1MCBwoMCgUEAAICARIDUwgVCgwKBQQAAgIDEgNTGBkKVAoEBAAC
AxIDVgIdGkcgVGhlIHN0YXRlIHRoYXQgdGhlIG1vZGVsIGlzIGluIChlLmcuYFRSQUlOSU5H
YCBvciBgVFJBSU5JTkdfRkFJTEVEYCkuCgoMCgUEAAIDBhIDVgIMCgwKBQQAAgMBEgNWDRgK
DAoFBAACAwMSA1YbHAo+CgQEAAIEEgNZAkAaMSBEZXByZWNhdGVkOiBUaW1lc3RhbXAgdGhl
IE1vZGVsIHdhcyBjcmVhdGVkIGF0LgoKDAoFBAACBAYSA1kCGwoMCgUEAAIEARIDWRwnCgwK
BQQAAgQDEgNZKisKDAoFBAACBAgSA1ksPwoNCgYEAAIECAMSA1ktPgo6CgQEAAIFEgNcAjQa
LSBUaW1lc3RhbXAgdGhlIG1vZGVsIHRyYWluaW5nIHdhcyBpbml0aWF0ZWQuCgoMCgUEAAIF
BhIDXAIbCgwKBQQAAgUBEgNcHC8KDAoFBAACBQMSA1wyMwowCgQEAAIGEgNfAiIaIyBUaGUg
bWV0cmljcyBvZiB0aGUgdHJhaW5lZCBtb2RlbC4KCgwKBQQAAgYGEgNfAhUKDAoFBAACBgES
A18WHQoMCgUEAAIGAxIDXyAhCmEKBAQAAgcSA2MCGxpUIEN1cnJlbnRseSB0aGlzIGlzIG9u
bHkgcG9wdWxhdGVkIGlmIHRoZSBtb2RlbCBzdGF0ZSBpcwogYElOUFVUX1ZBTElEQVRJT05f
RkFJTEVEYC4KCgwKBQQAAgcFEgNjAggKDAoFBAACBwESA2MJFgoMCgUEAAIHAxIDYxkaYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::CustomTuningModel::CustomTuningModel ===
    # Fields for CustomTuningModel
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model_version Type: 3 ()
    # Field: model_state Type: 14 (.google.cloud.discoveryengine.v1.CustomTuningModel.ModelState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: training_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: metrics Type: 11 (.google.cloud.discoveryengine.v1.CustomTuningModel.MetricsEntry)
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

Google::Cloud::Discoveryengine::V1::CustomTuningModel - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/custom_tuning_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::CustomTuningModel;

    my $msg = Google::Cloud::Discoveryengine::V1::CustomTuningModel::CustomTuningModel->new({
        name => $name,
        display_name => $display_name,
        model_version => $model_version,
        model_state => $model_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::CustomTuningModel::CustomTuningModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/custom_tuning_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::CustomTuningModel::CustomTuningModel

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::CustomTuningModel::ModelState>)

The state that the model is in (e.g.`TRAINING` or `TRAINING_FAILED`).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Deprecated: Timestamp the Model was created at.

=item * C<< $msg->training_start_time() >> / C<< $msg->training_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp the model training was initiated.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::CustomTuningModel::CustomTuningModel::MetricsEntry>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::CustomTuningModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
