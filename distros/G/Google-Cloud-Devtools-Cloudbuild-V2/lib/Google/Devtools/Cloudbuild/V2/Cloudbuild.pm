package Google::Devtools::Cloudbuild::V2::Cloudbuild;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvZGV2dG9vbHMvY2xvdWRidWlsZC92Mi9jbG91ZGJ1aWxkLnByb3RvEh1nb29n
bGUuZGV2dG9vbHMuY2xvdWRidWlsZC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8i1QIKEU9wZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90
aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsK
BnRhcmdldBgDIAEoCUID4EEDUgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEioK
DnN0YXR1c19tZXNzYWdlGAUgASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVk
X2NhbmNlbGxhdGlvbhgGIAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBp
X3ZlcnNpb24YByABKAlCA+BBA1IKYXBpVmVyc2lvbiLnAgoiUnVuV29ya2Zsb3dDdXN0b21P
cGVyYXRpb25NZXRhZGF0YRJACgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGltZRIXCgR2ZXJiGAMgASgJQgPgQQNS
BHZlcmISOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgEIAEoCEID4EEDUhVyZXF1ZXN0ZWRD
YW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YBSABKAlCA+BBA1IKYXBpVmVyc2lvbhIbCgZ0
YXJnZXQYBiABKAlCA+BBA1IGdGFyZ2V0EisKD3BpcGVsaW5lX3J1bl9pZBgHIAEoCUID4EED
Ug1waXBlbGluZVJ1bklkQqMFChhjb20uZ29vZ2xlLmNsb3VkYnVpbGQudjJCD0Nsb3VkQnVp
bGRQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2Nsb3VkYnVpbGQvYXBpdjIvY2xvdWRi
dWlsZHBiO2Nsb3VkYnVpbGRwYqICA0dDQqoCGkdvb2dsZS5DbG91ZC5DbG91ZEJ1aWxkLlYy
ygIVR29vZ2xlXENsb3VkXEJ1aWxkXFYy6gIYR29vZ2xlOjpDbG91ZDo6QnVpbGQ6OlYy6kFO
Ch5jb21wdXRlLmdvb2dsZWFwaXMuY29tL05ldHdvcmsSLHByb2plY3RzL3twcm9qZWN0fS9n
bG9iYWwvbmV0d29ya3Mve25ldHdvcmt96kFZCiFpYW0uZ29vZ2xlYXBpcy5jb20vU2Vydmlj
ZUFjY291bnQSNHByb2plY3RzL3twcm9qZWN0fS9zZXJ2aWNlQWNjb3VudHMve3NlcnZpY2Vf
YWNjb3VudH3qQUoKI3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0EiNwcm9q
ZWN0cy97cHJvamVjdH0vc2VjcmV0cy97c2VjcmV0fepBZAoqc2VjcmV0bWFuYWdlci5nb29n
bGVhcGlzLmNvbS9TZWNyZXRWZXJzaW9uEjZwcm9qZWN0cy97cHJvamVjdH0vc2VjcmV0cy97
c2VjcmV0fS92ZXJzaW9ucy97dmVyc2lvbn3qQXwKMGNsb3VkYnVpbGQuZ29vZ2xlYXBpcy5j
b20vZ2l0aHViRW50ZXJwcmlzZUNvbmZpZxJIcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2dpdGh1YkVudGVycHJpc2VDb25maWdzL3tjb25maWd9SpscCgYSBA4A
bwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgApCggKAQgS
AxgANwoJCgIIJRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsAMAoJCgIICBIDGwAwCggKAQgSAxwAMQoJCgIIARIDHAAxCggKAQgSAx0A
IQoJCgIIJBIDHQAhCggKAQgSAx4AMgoJCgIIKRIDHgAyCggKAQgSAx8AMQoJCgIILRIDHwAx
CgkKAQgSBCAAIwIKDAoECJ0IABIEIAAjAgoJCgEIEgQkACcCCgwKBAidCAESBCQAJwIKCQoB
CBIEKAArAgoMCgQInQgCEgQoACsCCgkKAQgSBCwALwIKDAoECJ0IAxIELAAvAgoJCgEIEgQw
ADMCCgwKBAidCAQSBDAAMwIKRAoCBAASBDYAUQEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0
YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoKAwQAARIDNggZCkAKBAQAAgAS
BDgCOTIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3YXMgY3JlYXRl
ZC4KCgwKBQQAAgAGEgM4AhsKDAoFBAACAAESAzgcJwoMCgUEAAIAAxIDOCorCgwKBQQAAgAI
EgM5BjEKDwoIBAACAAicCAASAzkHMApFCgQEAAIBEgQ8Aj0yGjcgT3V0cHV0IG9ubHkuIFRo
ZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCgwKBQQAAgEGEgM8AhsK
DAoFBAACAQESAzwcJAoMCgUEAAIBAxIDPCcoCgwKBQQAAgEIEgM9BjEKDwoIBAACAQicCAAS
Az0HMApZCgQEAAICEgNAAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3Vy
Y2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAgUSA0AC
CAoMCgUEAAICARIDQAkPCgwKBQQAAgIDEgNAEhMKDAoFBAACAggSA0AUPwoPCggEAAICCJwI
ABIDQBU+CkcKBAQAAgMSA0MCPho6IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4
ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRIDQwIICgwKBQQAAgMBEgNDCQ0K
DAoFBAACAwMSA0MQEQoMCgUEAAIDCBIDQxI9Cg8KCAQAAgMInAgAEgNDEzwKSwoEBAACBBID
RgJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0
aW9uLCBpZiBhbnkuCgoMCgUEAAIEBRIDRgIICgwKBQQAAgQBEgNGCRcKDAoFBAACBAMSA0Ya
GwoMCgUEAAIECBIDRhxHCg8KCAQAAgQInAgAEgNGHUYKmgIKBAQAAgUSA00CThqMAiBPdXRw
dXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2Fu
Y2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNj
ZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQKIGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1
ZSB3aXRoIGEKIFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtnb29nbGUucnBjLlN0YXR1cy5j
b2RlXSBvZiAxLCBjb3JyZXNwb25kaW5nIHRvCiBgQ29kZS5DQU5DRUxMRURgLgoKDAoFBAAC
BQUSA00CBgoMCgUEAAIFARIDTQcdCgwKBQQAAgUDEgNNICEKDAoFBAACBQgSA00iTQoPCggE
AAIFCJwIABIDTSNMCkQKBAQAAgYSA1ACRRo3IE91dHB1dCBvbmx5LiBBUEkgdmVyc2lvbiB1
c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIGBRIDUAIICgwKBQQAAgYBEgNQ
CRQKDAoFBAACBgMSA1AXGAoMCgUEAAIGCBIDUBlECg8KCAQAAgYInAgAEgNQGkMKVwoCBAES
BFQAbwEaSyBSZXByZXNlbnRzIHRoZSBjdXN0b20gbWV0YWRhdGEgb2YgdGhlIFJ1bldvcmtm
bG93IGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAQESA1QIKgpACgQEAQIAEgRWAlcy
GjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoM
CgUEAQIABhIDVgIbCgwKBQQBAgABEgNWHCcKDAoFBAECAAMSA1YqKwoMCgUEAQIACBIDVwYx
Cg8KCAQBAgAInAgAEgNXBzAKRQoEBAECARIEWgJbMho3IE91dHB1dCBvbmx5LiBUaGUgdGlt
ZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoMCgUEAQIBBhIDWgIbCgwKBQQB
AgEBEgNaHCQKDAoFBAECAQMSA1onKAoMCgUEAQIBCBIDWwYxCg8KCAQBAgEInAgAEgNbBzAK
RwoEBAECAhIDXgI+GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQg
YnkgdGhlIG9wZXJhdGlvbi4KCgwKBQQBAgIFEgNeAggKDAoFBAECAgESA14JDQoMCgUEAQIC
AxIDXhARCgwKBQQBAgIIEgNeEj0KDwoIBAECAgicCAASA14TPAqaAgoEBAECAxIDZQJOGowC
IE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3Rl
ZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZl
IHN1Y2Nlc3NmdWxseSBiZWVuIGNhbmNlbGxlZAogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtd
IHZhbHVlIHdpdGggYQogW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3Rh
dHVzLmNvZGVdIG9mIDEsIGNvcnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoM
CgUEAQIDBRIDZQIGCgwKBQQBAgMBEgNlBx0KDAoFBAECAwMSA2UgIQoMCgUEAQIDCBIDZSJN
Cg8KCAQBAgMInAgAEgNlI0wKRAoEBAECBBIDaAJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJz
aW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCgwKBQQBAgQFEgNoAggKDAoFBAEC
BAESA2gJFAoMCgUEAQIEAxIDaBcYCgwKBQQBAgQIEgNoGUQKDwoIBAECBAicCAASA2gaQwpZ
CgQEAQIFEgNrAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0
aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAECBQUSA2sCCAoMCgUE
AQIFARIDawkPCgwKBQQBAgUDEgNrEhMKDAoFBAECBQgSA2sUPwoPCggEAQIFCJwIABIDaxU+
CkoKBAQBAgYSA24CSRo9IE91dHB1dCBvbmx5LiBJRCBvZiB0aGUgcGlwZWxpbmUgcnVuIGNy
ZWF0ZWQgYnkgUnVuV29ya2Zsb3cuCgoMCgUEAQIGBRIDbgIICgwKBQQBAgYBEgNuCRgKDAoF
BAECBgMSA24bHAoMCgUEAQIGCBIDbh1ICg8KCAQBAgYInAgAEgNuHkdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Devtools::Cloudbuild::V2::Cloudbuild::RunWorkflowCustomOperationMetadata ===
    # Fields for RunWorkflowCustomOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: target Type: 9 ()
    # Field: pipeline_run_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Cloudbuild::V2::Cloudbuild - Compiled Protocol Buffers messages for google/devtools/cloudbuild/v2/cloudbuild.proto

=head1 SYNOPSIS

    use Google::Devtools::Cloudbuild::V2::Cloudbuild;

    my $msg = Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/cloudbuild/v2/cloudbuild.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Devtools::Cloudbuild::V2::Cloudbuild::RunWorkflowCustomOperationMetadata

Represents the custom metadata of the RunWorkflow long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->pipeline_run_id() >> / C<< $msg->pipeline_run_id($value) >>

Type: C<String>

Output only. ID of the pipeline run created by RunWorkflow.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Cloudbuild::V2::Cloudbuild::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
