package Google::Cloud::Recommender::Logging::V1beta1::ActionLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Recommender::V1beta1::Insight };
    eval { require Google::Cloud::Recommender::V1beta1::Recommendation };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvbG9nZ2luZy92MWJldGExL2FjdGlvbl9sb2cu
cHJvdG8SKGdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci5sb2dnaW5nLnYxYmV0YTEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aLmdvb2dsZS9jbG91ZC9yZWNvbW1lbmRlci92
MWJldGExL2luc2lnaHQucHJvdG8aNWdvb2dsZS9jbG91ZC9yZWNvbW1lbmRlci92MWJldGEx
L3JlY29tbWVuZGF0aW9uLnByb3RvItoCCglBY3Rpb25Mb2cSFAoFYWN0b3IYASABKAlSBWFj
dG9yElUKBXN0YXRlGAIgASgOMj8uZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxYmV0YTEu
UmVjb21tZW5kYXRpb25TdGF0ZUluZm8uU3RhdGVSBXN0YXRlEm0KDnN0YXRlX21ldGFkYXRh
GAMgAygLMkYuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLmxvZ2dpbmcudjFiZXRhMS5BY3Rp
b25Mb2cuU3RhdGVNZXRhZGF0YUVudHJ5Ug1zdGF0ZU1ldGFkYXRhEi8KE3JlY29tbWVuZGF0
aW9uX25hbWUYBCABKAlSEnJlY29tbWVuZGF0aW9uTmFtZRpAChJTdGF0ZU1ldGFkYXRhRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASLeAgoQSW5z
aWdodEFjdGlvbkxvZxIZCgVhY3RvchgBIAEoCUID4EECUgVhY3RvchJTCgVzdGF0ZRgCIAEo
DjI4Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLkluc2lnaHRTdGF0ZUluZm8u
U3RhdGVCA+BBAlIFc3RhdGUSeQoOc3RhdGVfbWV0YWRhdGEYAyADKAsyTS5nb29nbGUuY2xv
dWQucmVjb21tZW5kZXIubG9nZ2luZy52MWJldGExLkluc2lnaHRBY3Rpb25Mb2cuU3RhdGVN
ZXRhZGF0YUVudHJ5QgPgQQFSDXN0YXRlTWV0YWRhdGESHQoHaW5zaWdodBgEIAEoCUID4EEC
UgdpbnNpZ2h0GkAKElN0YXRlTWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2
YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQogBCixjb20uZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVy
LmxvZ2dpbmcudjFiZXRhMUIOQWN0aW9uTG9nUHJvdG9QAVpGY2xvdWQuZ29vZ2xlLmNvbS9n
by9yZWNvbW1lbmRlci9sb2dnaW5nL2FwaXYxYmV0YTEvbG9nZ2luZ3BiO2xvZ2dpbmdwYkrn
EAoGEgQOADkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAx
CgkKAgMAEgMSACkKCQoCAwESAxMAOAoJCgIDAhIDFAA/CggKAQgSAxYAXQoJCgIICxIDFgBd
CggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALwoJCgIICBIDGAAvCggKAQgSAxkARQoJ
CgIIARIDGQBFClgKAgQAEgQcACkBGkwgTG9nIGNvbnRlbnQgb2YgYW4gYWN0aW9uIG9uIGEg
cmVjb21tZW5kYXRpb24uIFRoaXMgaW5jbHVkZXMgTWFyayogYWN0aW9ucy4KCgoKAwQAARID
HAgRCkoKBAQAAgASAx4CExo9IFJlcXVpcmVkLiBVc2VyIHRoYXQgZXhlY3V0ZWQgdGhpcyBh
Y3Rpb24uIEVnLCBmb29AZ21haWwuY29tCgoMCgUEAAIABRIDHgIICgwKBQQAAgABEgMeCQ4K
DAoFBAACAAMSAx4REgpQCgQEAAIBEgMhAksaQyBSZXF1aXJlZC4gU3RhdGUgY2hhbmdlIHRo
YXQgd2FzIG1hZGUgYnkgdGhlIGFjdG9yLiBFZywgU1VDQ0VFREVELgoKDAoFBAACAQYSAyEC
QAoMCgUEAAIBARIDIUFGCgwKBQQAAgEDEgMhSUoKUwoEBAACAhIDJAIpGkYgT3B0aW9uYWwu
IE1ldGFkYXRhIHRoYXQgd2FzIGluY2x1ZGVkIHdpdGggdGhlIGFjdGlvbiB0aGF0IHdhcyB0
YWtlbi4KCgwKBQQAAgIGEgMkAhUKDAoFBAACAgESAyQWJAoMCgUEAAICAxIDJCcoCpgBCgQE
AAIDEgMoAiEaigEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHJlY29tbWVuZGF0aW9uIHdoaWNo
IHdhcyBhY3RlZCBvbi4gRWcsIDoKICdwcm9qZWN0cy9mb28vbG9jYXRpb25zL2dsb2JhbC9y
ZWNvbW1lbmRlcnMvcm9sZVJlY28vcmVjb21tZW5kYXRpb25zL3IxJwoKDAoFBAACAwUSAygC
CAoMCgUEAAIDARIDKAkcCgwKBQQAAgMDEgMoHyAKUgoCBAESBCwAOQEaRiBMb2cgY29udGVu
dCBvZiBhbiBhY3Rpb24gb24gYW4gaW5zaWdodC4gVGhpcyBpbmNsdWRlcyBNYXJrKiBhY3Rp
b25zLgoKCgoDBAEBEgMsCBgKSgoEBAECABIDLgI8Gj0gUmVxdWlyZWQuIFVzZXIgdGhhdCBl
eGVjdXRlZCB0aGlzIGFjdGlvbi4gRWcsIGZvb0BnbWFpbC5jb20KCgwKBQQBAgAFEgMuAggK
DAoFBAECAAESAy4JDgoMCgUEAQIAAxIDLhESCgwKBQQBAgAIEgMuEzsKDwoIBAECAAicCAAS
Ay4UOgpPCgQEAQIBEgMxAm0aQiBSZXF1aXJlZC4gU3RhdGUgY2hhbmdlIHRoYXQgd2FzIG1h
ZGUgYnkgdGhlIGFjdG9yLiBFZywgQUNDRVBURUQuCgoMCgUEAQIBBhIDMQI5CgwKBQQBAgEB
EgMxOj8KDAoFBAECAQMSAzFCQwoMCgUEAQIBCBIDMURsCg8KCAQBAgEInAgAEgMxRWsKUwoE
BAECAhIDNAJSGkYgT3B0aW9uYWwuIE1ldGFkYXRhIHRoYXQgd2FzIGluY2x1ZGVkIHdpdGgg
dGhlIGFjdGlvbiB0aGF0IHdhcyB0YWtlbi4KCgwKBQQBAgIGEgM0AhUKDAoFBAECAgESAzQW
JAoMCgUEAQICAxIDNCcoCgwKBQQBAgIIEgM0KVEKDwoIBAECAgicCAASAzQqUAqMAQoEBAEC
AxIDOAI+Gn8gUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGluc2lnaHQgd2hpY2ggd2FzIGFjdGVk
IG9uLiBFZywgOgogJ3Byb2plY3RzL2Zvby9sb2NhdGlvbnMvZ2xvYmFsL2luc2lnaHRUeXBl
cy9yb2xlSW5zaWdodC9pbnNpZ2h0cy9pMScKCgwKBQQBAgMFEgM4AggKDAoFBAECAwESAzgJ
EAoMCgUEAQIDAxIDOBMUCgwKBQQBAgMIEgM4FT0KDwoIBAECAwicCAASAzgWPGIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog ===
    # Fields for ActionLog
    # Field: actor Type: 9 ()
    # Field: state Type: 14 (.google.cloud.recommender.v1beta1.RecommendationStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.logging.v1beta1.ActionLog.StateMetadataEntry)
    # Field: recommendation_name Type: 9 ()

# === Message: Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog ===
    # Fields for InsightActionLog
    # Field: actor Type: 9 ()
    # Field: state Type: 14 (.google.cloud.recommender.v1beta1.InsightStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.logging.v1beta1.InsightActionLog.StateMetadataEntry)
    # Field: insight Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::Logging::V1beta1::ActionLog - Compiled Protocol Buffers messages for google/cloud/recommender/logging/v1beta1/action_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::Logging::V1beta1::ActionLog;

    my $msg = Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog->new({
        actor => $actor,
        state => $state,
        state_metadata => $state_metadata,
        recommendation_name => $recommendation_name,
    });

    # Read or update a field
    my $val = $msg->actor();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/logging/v1beta1/action_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog

Log content of an action on a recommendation. This includes Mark* actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->actor() >> / C<< $msg->actor($value) >>

Type: C<String>

Required. User that executed this action. Eg, foo@gmail.com

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::RecommendationStateInfo::State>)

Required. State change that was made by the actor. Eg, SUCCEEDED.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog::StateMetadataEntry>)

Optional. Metadata that was included with the action that was taken.

=item * C<< $msg->recommendation_name() >> / C<< $msg->recommendation_name($value) >>

Type: C<String>

Required. Name of the recommendation which was acted on. Eg, :
'projects/foo/locations/global/recommenders/roleReco/recommendations/r1'

=back

=head2 Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog

Log content of an action on an insight. This includes Mark* actions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->actor() >> / C<< $msg->actor($value) >>

Type: C<String>

Required. User that executed this action. Eg, foo@gmail.com

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::InsightStateInfo::State>)

Required. State change that was made by the actor. Eg, ACCEPTED.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog::StateMetadataEntry>)

Optional. Metadata that was included with the action that was taken.

=item * C<< $msg->insight() >> / C<< $msg->insight($value) >>

Type: C<String>

Required. Name of the insight which was acted on. Eg, :
'projects/foo/locations/global/insightTypes/roleInsight/insights/i1'

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::Logging::V1beta1::ActionLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
