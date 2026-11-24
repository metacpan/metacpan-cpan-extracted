package Google::Cloud::Networkconnectivity::V1beta::Common;

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
CjRnb29nbGUvY2xvdWQvbmV0d29ya2Nvbm5lY3Rpdml0eS92MWJldGEvY29tbW9uLnByb3Rv
Eidnb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MWJldGEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1QIKEU9wZXJhdGlvbk1ldGFkYXRhEkAKC2Ny
ZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEoCUID4EEDUgZ0YXJnZXQSFwoEdmVyYhgEIAEo
CUID4EEDUgR2ZXJiEioKDnN0YXR1c19tZXNzYWdlGAUgASgJQgPgQQNSDXN0YXR1c01lc3Nh
Z2USOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlvbhgGIAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5j
ZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YByABKAlCA+BBA1IKYXBpVmVyc2lvbkLMBQorY29t
Lmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0YUILQ29tbW9uUHJvdG9Q
AVpdY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3JrY29ubmVjdGl2aXR5L2FwaXYxYmV0YS9u
ZXR3b3JrY29ubmVjdGl2aXR5cGI7bmV0d29ya2Nvbm5lY3Rpdml0eXBiqgInR29vZ2xlLkNs
b3VkLk5ldHdvcmtDb25uZWN0aXZpdHkuVjFCZXRhygInR29vZ2xlXENsb3VkXE5ldHdvcmtD
b25uZWN0aXZpdHlcVjFiZXRh6gIqR29vZ2xlOjpDbG91ZDo6TmV0d29ya0Nvbm5lY3Rpdml0
eTo6VjFiZXRh6kF6Ci1jb21wdXRlLmdvb2dsZWFwaXMuY29tL0ludGVyY29ubmVjdEF0dGFj
aG1lbnQSSXByb2plY3RzL3twcm9qZWN0fS9yZWdpb25zL3tyZWdpb259L2ludGVyY29ubmVj
dEF0dGFjaG1lbnRzL3tyZXNvdXJjZV9pZH3qQVIKHmNvbXB1dGUuZ29vZ2xlYXBpcy5jb20v
TmV0d29yaxIwcHJvamVjdHMve3Byb2plY3R9L2dsb2JhbC9uZXR3b3Jrcy97cmVzb3VyY2Vf
aWR96kFhCiFjb21wdXRlLmdvb2dsZWFwaXMuY29tL1N1Ym5ldHdvcmsSPHByb2plY3RzL3tw
cm9qZWN0fS9yZWdpb25zL3tyZWdpb259L3N1Ym5ldHdvcmtzL3tzdWJuZXR3b3JrfepBdwoo
Y29tcHV0ZS5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlQXR0YWNobWVudBJLcHJvamVjdHMve3By
b2plY3R9L3JlZ2lvbnMve3JlZ2lvbn0vc2VydmljZUF0dGFjaG1lbnRzL3tzZXJ2aWNlX2F0
dGFjaG1lbnR9Ss0RCgYSBA4ASwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQADAKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBE
CgkKAgglEgMWAEQKCAoBCBIDFwB0CgkKAggLEgMXAHQKCAoBCBIDGAAiCgkKAggKEgMYACIK
CAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgBECgkKAggBEgMaAEQKCAoBCBIDGwBECgkK
AggpEgMbAEQKCAoBCBIDHABDCgkKAggtEgMcAEMKCQoBCBIEHQAgAgoMCgQInQgAEgQdACAC
CgkKAQgSBCEAJAIKDAoECJ0IARIEIQAkAgoJCgEIEgQlACgCCgwKBAidCAISBCUAKAIKCQoB
CBIEKQAsAgoMCgQInQgDEgQpACwCCkQKAgQAEgQvAEsBGjggUmVwcmVzZW50cyB0aGUgbWV0
YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAAESAy8IGQpACgQE
AAIAEgQxAjIyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNy
ZWF0ZWQuCgoMCgUEAAIABhIDMQIbCgwKBQQAAgABEgMxHCcKDAoFBAACAAMSAzEqKwoMCgUE
AAIACBIDMgYxCg8KCAQAAgAInAgAEgMyBzAKRQoEBAACARIENQI2Mho3IE91dHB1dCBvbmx5
LiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVkIHJ1bm5pbmcuCgoMCgUEAAIBBhID
NQIbCgwKBQQAAgEBEgM1HCQKDAoFBAACAQMSAzUnKAoMCgUEAAIBCBIDNgYxCg8KCAQAAgEI
nAgAEgM2BzAKWQoEBAACAhIDOQJAGkwgT3V0cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJl
c291cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgIF
EgM5AggKDAoFBAACAgESAzkJDwoMCgUEAAICAxIDORITCgwKBQQAAgIIEgM5FD8KDwoIBAAC
AgicCAASAzkVPgpHCgQEAAIDEgM8Aj4aOiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgdmVy
YiBleGVjdXRlZCBieSB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAwUSAzwCCAoMCgUEAAIDARID
PAkNCgwKBQQAAgMDEgM8EBEKDAoFBAACAwgSAzwSPQoPCggEAAIDCJwIABIDPBM8CksKBAQA
AgQSAz8CSBo+IE91dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMgb2YgdGhlIG9w
ZXJhdGlvbiwgaWYgYW55LgoKDAoFBAACBAUSAz8CCAoMCgUEAAIEARIDPwkXCgwKBQQAAgQD
EgM/GhsKDAoFBAACBAgSAz8cRwoPCggEAAIECJwIABIDPx1GCtACCgQEAAIFEgNHAk4awgIg
T3V0cHV0IG9ubHkuIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNlciBoYXMgcmVxdWVzdGVk
IGNhbmNlbGxhdGlvbgogb2YgdGhlIG9wZXJhdGlvbi4gT3BlcmF0aW9ucyB0aGF0IGhhdmUg
YmVlbiBjYW5jZWxsZWQgc3VjY2Vzc2Z1bGx5CiBoYXZlCiBbZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbi5lcnJvcl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5lcnJvcl0K
IHZhbHVlIHdpdGggYSBbZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV1bZ29vZ2xlLnJwYy5TdGF0
dXMuY29kZV0gb2YgMSwKIGNvcnJlc3BvbmRpbmcgdG8gYENvZGUuQ0FOQ0VMTEVEYC4KCgwK
BQQAAgUFEgNHAgYKDAoFBAACBQESA0cHHQoMCgUEAAIFAxIDRyAhCgwKBQQAAgUIEgNHIk0K
DwoIBAACBQicCAASA0cjTApECgQEAAIGEgNKAkUaNyBPdXRwdXQgb25seS4gQVBJIHZlcnNp
b24gdXNlZCB0byBzdGFydCB0aGUgb3BlcmF0aW9uLgoKDAoFBAACBgUSA0oCCAoMCgUEAAIG
ARIDSgkUCgwKBQQAAgYDEgNKFxgKDAoFBAACBggSA0oZRAoPCggEAAIGCJwIABIDShpDYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkconnectivity::V1beta::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkconnectivity::V1beta::Common - Compiled Protocol Buffers messages for google/cloud/networkconnectivity/v1beta/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkconnectivity::V1beta::Common;

    my $msg = Google::Cloud::Networkconnectivity::V1beta::Common::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkconnectivity::V1beta::Common::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkconnectivity/v1beta/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkconnectivity::V1beta::Common::OperationMetadata

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
of the operation. Operations that have been cancelled successfully
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkconnectivity::V1beta::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
