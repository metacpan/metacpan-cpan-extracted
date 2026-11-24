package Google::Cloud::Recommender::Logging::V1::ActionLog;

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
    eval { require Google::Cloud::Recommender::V1::Insight };
    eval { require Google::Cloud::Recommender::V1::Recommendation };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvbG9nZ2luZy92MS9hY3Rpb25fbG9nLnByb3Rv
EiNnb29nbGUuY2xvdWQucmVjb21tZW5kZXIubG9nZ2luZy52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxopZ29vZ2xlL2Ns
b3VkL3JlY29tbWVuZGVyL3YxL2luc2lnaHQucHJvdG8aMGdvb2dsZS9jbG91ZC9yZWNvbW1l
bmRlci92MS9yZWNvbW1lbmRhdGlvbi5wcm90byLQAgoJQWN0aW9uTG9nEhQKBWFjdG9yGAEg
ASgJUgVhY3RvchJQCgVzdGF0ZRgCIAEoDjI6Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52
MS5SZWNvbW1lbmRhdGlvblN0YXRlSW5mby5TdGF0ZVIFc3RhdGUSaAoOc3RhdGVfbWV0YWRh
dGEYAyADKAsyQS5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIubG9nZ2luZy52MS5BY3Rpb25M
b2cuU3RhdGVNZXRhZGF0YUVudHJ5Ug1zdGF0ZU1ldGFkYXRhEi8KE3JlY29tbWVuZGF0aW9u
X25hbWUYBCABKAlSEnJlY29tbWVuZGF0aW9uTmFtZRpAChJTdGF0ZU1ldGFkYXRhRW50cnkS
EAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASL7AgoQSW5zaWdo
dEFjdGlvbkxvZxIZCgVhY3RvchgBIAEoCUID4EECUgVhY3RvchJOCgVzdGF0ZRgCIAEoDjIz
Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MS5JbnNpZ2h0U3RhdGVJbmZvLlN0YXRlQgPg
QQJSBXN0YXRlEnQKDnN0YXRlX21ldGFkYXRhGAMgAygLMkguZ29vZ2xlLmNsb3VkLnJlY29t
bWVuZGVyLmxvZ2dpbmcudjEuSW5zaWdodEFjdGlvbkxvZy5TdGF0ZU1ldGFkYXRhRW50cnlC
A+BBAVINc3RhdGVNZXRhZGF0YRJECgdpbnNpZ2h0GAQgASgJQirgQQL6QSQKInJlY29tbWVu
ZGVyLmdvb2dsZWFwaXMuY29tL0luc2lnaHRSB2luc2lnaHQaQAoSU3RhdGVNZXRhZGF0YUVu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCfgonY29t
Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci5sb2dnaW5nLnYxQg5BY3Rpb25Mb2dQcm90b1AB
WkFjbG91ZC5nb29nbGUuY29tL2dvL3JlY29tbWVuZGVyL2xvZ2dpbmcvYXBpdjEvbG9nZ2lu
Z3BiO2xvZ2dpbmdwYkqFEQoGEgQOAD8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAzCgkKAgMD
EgMVADoKCAoBCBIDFwBYCgkKAggLEgMXAFgKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBID
GQAvCgkKAggIEgMZAC8KCAoBCBIDGgBACgkKAggBEgMaAEAKWAoCBAASBB0AKgEaTCBMb2cg
Y29udGVudCBvZiBhbiBhY3Rpb24gb24gYSByZWNvbW1lbmRhdGlvbi4gVGhpcyBpbmNsdWRl
cyBNYXJrKiBhY3Rpb25zLgoKCgoDBAABEgMdCBEKSgoEBAACABIDHwITGj0gUmVxdWlyZWQu
IFVzZXIgdGhhdCBleGVjdXRlZCB0aGlzIGFjdGlvbi4gRWcsIGZvb0BnbWFpbC5jb20KCgwK
BQQAAgAFEgMfAggKDAoFBAACAAESAx8JDgoMCgUEAAIAAxIDHxESClAKBAQAAgESAyICRhpD
IFJlcXVpcmVkLiBTdGF0ZSBjaGFuZ2UgdGhhdCB3YXMgbWFkZSBieSB0aGUgYWN0b3IuIEVn
LCBTVUNDRUVERUQuCgoMCgUEAAIBBhIDIgI7CgwKBQQAAgEBEgMiPEEKDAoFBAACAQMSAyJE
RQpTCgQEAAICEgMlAikaRiBPcHRpb25hbC4gTWV0YWRhdGEgdGhhdCB3YXMgaW5jbHVkZWQg
d2l0aCB0aGUgYWN0aW9uIHRoYXQgd2FzIHRha2VuLgoKDAoFBAACAgYSAyUCFQoMCgUEAAIC
ARIDJRYkCgwKBQQAAgIDEgMlJygKmAEKBAQAAgMSAykCIRqKASBSZXF1aXJlZC4gTmFtZSBv
ZiB0aGUgcmVjb21tZW5kYXRpb24gd2hpY2ggd2FzIGFjdGVkIG9uLiBFZywgOgogJ3Byb2pl
Y3RzLzEyMy9sb2NhdGlvbnMvZ2xvYmFsL3JlY29tbWVuZGVycy9yb2xlUmVjby9yZWNvbW1l
bmRhdGlvbnMvcjEnCgoMCgUEAAIDBRIDKQIICgwKBQQAAgMBEgMpCRwKDAoFBAACAwMSAykf
IApSCgIEARIELQA/ARpGIExvZyBjb250ZW50IG9mIGFuIGFjdGlvbiBvbiBhbiBpbnNpZ2h0
LiBUaGlzIGluY2x1ZGVzIE1hcmsqIGFjdGlvbnMuCgoKCgMEAQESAy0IGApKCgQEAQIAEgMv
AjwaPSBSZXF1aXJlZC4gVXNlciB0aGF0IGV4ZWN1dGVkIHRoaXMgYWN0aW9uLiBFZywgZm9v
QGdtYWlsLmNvbQoKDAoFBAECAAUSAy8CCAoMCgUEAQIAARIDLwkOCgwKBQQBAgADEgMvERIK
DAoFBAECAAgSAy8TOwoPCggEAQIACJwIABIDLxQ6Ck8KBAQBAgESAzICaBpCIFJlcXVpcmVk
LiBTdGF0ZSBjaGFuZ2UgdGhhdCB3YXMgbWFkZSBieSB0aGUgYWN0b3IuIEVnLCBBQ0NFUFRF
RC4KCgwKBQQBAgEGEgMyAjQKDAoFBAECAQESAzI1OgoMCgUEAQIBAxIDMj0+CgwKBQQBAgEI
EgMyP2cKDwoIBAECAQicCAASAzJAZgpTCgQEAQICEgM1AlIaRiBPcHRpb25hbC4gTWV0YWRh
dGEgdGhhdCB3YXMgaW5jbHVkZWQgd2l0aCB0aGUgYWN0aW9uIHRoYXQgd2FzIHRha2VuLgoK
DAoFBAECAgYSAzUCFQoMCgUEAQICARIDNRYkCgwKBQQBAgIDEgM1JygKDAoFBAECAggSAzUp
UQoPCggEAQICCJwIABIDNSpQCo0BCgQEAQIDEgQ5Aj4EGn8gUmVxdWlyZWQuIE5hbWUgb2Yg
dGhlIGluc2lnaHQgd2hpY2ggd2FzIGFjdGVkIG9uLiBFZywgOgogJ3Byb2plY3RzLzEyMy9s
b2NhdGlvbnMvZ2xvYmFsL2luc2lnaHRUeXBlcy9yb2xlSW5zaWdodC9pbnNpZ2h0cy9pMScK
CgwKBQQBAgMFEgM5AggKDAoFBAECAwESAzkJEAoMCgUEAQIDAxIDORMUCg0KBQQBAgMIEgQ5
FT4DCg8KCAQBAgMInAgAEgM6BCoKDwoHBAECAwifCBIEOwQ9BWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::Logging::V1::ActionLog::ActionLog ===
    # Fields for ActionLog
    # Field: actor Type: 9 ()
    # Field: state Type: 14 (.google.cloud.recommender.v1.RecommendationStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.logging.v1.ActionLog.StateMetadataEntry)
    # Field: recommendation_name Type: 9 ()

# === Message: Google::Cloud::Recommender::Logging::V1::ActionLog::InsightActionLog ===
    # Fields for InsightActionLog
    # Field: actor Type: 9 ()
    # Field: state Type: 14 (.google.cloud.recommender.v1.InsightStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.logging.v1.InsightActionLog.StateMetadataEntry)
    # Field: insight Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::Logging::V1::ActionLog - Compiled Protocol Buffers messages for google/cloud/recommender/logging/v1/action_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::Logging::V1::ActionLog;

    my $msg = Google::Cloud::Recommender::Logging::V1::ActionLog::ActionLog->new({
        actor => $actor,
        state => $state,
        state_metadata => $state_metadata,
        recommendation_name => $recommendation_name,
    });

    # Read or update a field
    my $val = $msg->actor();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::Logging::V1::ActionLog::ActionLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/logging/v1/action_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::Logging::V1::ActionLog::ActionLog

Log content of an action on a recommendation. This includes Mark* actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->actor() >> / C<< $msg->actor($value) >>

Type: C<String>

Required. User that executed this action. Eg, foo@gmail.com

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::RecommendationStateInfo::State>)

Required. State change that was made by the actor. Eg, SUCCEEDED.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::Logging::V1::ActionLog::ActionLog::StateMetadataEntry>)

Optional. Metadata that was included with the action that was taken.

=item * C<< $msg->recommendation_name() >> / C<< $msg->recommendation_name($value) >>

Type: C<String>

Required. Name of the recommendation which was acted on. Eg, :
'projects/123/locations/global/recommenders/roleReco/recommendations/r1'

=back

=head2 Google::Cloud::Recommender::Logging::V1::ActionLog::InsightActionLog

Log content of an action on an insight. This includes Mark* actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->actor() >> / C<< $msg->actor($value) >>

Type: C<String>

Required. User that executed this action. Eg, foo@gmail.com

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1::InsightStateInfo::State>)

Required. State change that was made by the actor. Eg, ACCEPTED.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::Logging::V1::ActionLog::InsightActionLog::StateMetadataEntry>)

Optional. Metadata that was included with the action that was taken.

=item * C<< $msg->insight() >> / C<< $msg->insight($value) >>

Type: C<String>

Required. Name of the insight which was acted on. Eg, :
'projects/123/locations/global/insightTypes/roleInsight/insights/i1'

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::Logging::V1::ActionLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
