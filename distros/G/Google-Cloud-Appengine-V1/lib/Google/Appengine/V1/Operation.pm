package Google::Appengine::V1::Operation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvYXBwZW5naW5lL3YxL29wZXJhdGlvbi5wcm90bxITZ29vZ2xlLmFwcGVuZ2lu
ZS52MRofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKPAwoTT3BlcmF0aW9uTWV0
YWRhdGFWMRIWCgZtZXRob2QYASABKAlSBm1ldGhvZBI7CgtpbnNlcnRfdGltZRgCIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmluc2VydFRpbWUSNQoIZW5kX3RpbWUYAyAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdlbmRUaW1lEhIKBHVzZXIYBCABKAlS
BHVzZXISFgoGdGFyZ2V0GAUgASgJUgZ0YXJnZXQSKwoRZXBoZW1lcmFsX21lc3NhZ2UYBiAB
KAlSEGVwaGVtZXJhbE1lc3NhZ2USGAoHd2FybmluZxgHIAMoCVIHd2FybmluZxJmChdjcmVh
dGVfdmVyc2lvbl9tZXRhZGF0YRgIIAEoCzIsLmdvb2dsZS5hcHBlbmdpbmUudjEuQ3JlYXRl
VmVyc2lvbk1ldGFkYXRhVjFIAFIVY3JlYXRlVmVyc2lvbk1ldGFkYXRhQhEKD21ldGhvZF9t
ZXRhZGF0YSI/ChdDcmVhdGVWZXJzaW9uTWV0YWRhdGFWMRIkCg5jbG91ZF9idWlsZF9pZBgB
IAEoCVIMY2xvdWRCdWlsZElkQr8BChdjb20uZ29vZ2xlLmFwcGVuZ2luZS52MUIOT3BlcmF0
aW9uUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBlbmdpbmUvYXBpdjEvYXBwZW5n
aW5lcGI7YXBwZW5naW5lcGKqAhlHb29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxygIZR29vZ2xl
XENsb3VkXEFwcEVuZ2luZVxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFKhxIK
BhIEDgBOAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJ
CgIDABIDEgApCggKAQgSAxQANgoJCgIIJRIDFAA2CggKAQgSAxUAUgoJCgIICxIDFQBSCggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgAMAoJCgII
ARIDGAAwCggKAQgSAxkANgoJCgIIKRIDGQA2CggKAQgSAxoANQoJCgIILRIDGgA1CmIKAgQA
EgQdAEYBGlYgTWV0YWRhdGEgZm9yIHRoZSBnaXZlbiBbZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0uCgoKCgMEAAESAx0IGwp+
CgQEAAIAEgMiAhQacSBBUEkgbWV0aG9kIHRoYXQgaW5pdGlhdGVkIHRoaXMgb3BlcmF0aW9u
LiBFeGFtcGxlOgogYGdvb2dsZS5hcHBlbmdpbmUudjEuVmVyc2lvbnMuQ3JlYXRlVmVyc2lv
bmAuCgogQE91dHB1dE9ubHkKCgwKBQQAAgAFEgMiAggKDAoFBAACAAESAyIJDwoMCgUEAAIA
AxIDIhITCkIKBAQAAgESAycCLBo1IFRpbWUgdGhhdCB0aGlzIG9wZXJhdGlvbiB3YXMgY3Jl
YXRlZC4KCiBAT3V0cHV0T25seQoKDAoFBAACAQYSAycCGwoMCgUEAAIBARIDJxwnCgwKBQQA
AgEDEgMnKisKQAoEBAACAhIDLAIpGjMgVGltZSB0aGF0IHRoaXMgb3BlcmF0aW9uIGNvbXBs
ZXRlZC4KCiBAT3V0cHV0T25seQoKDAoFBAACAgYSAywCGwoMCgUEAAICARIDLBwkCgwKBQQA
AgIDEgMsJygKPwoEBAACAxIDMQISGjIgVXNlciB3aG8gcmVxdWVzdGVkIHRoaXMgb3BlcmF0
aW9uLgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIDBRIDMQIICgwKBQQAAgMBEgMxCQ0KDAoFBAAC
AwMSAzEQEQp8CgQEAAIEEgM3AhQabyBOYW1lIG9mIHRoZSByZXNvdXJjZSB0aGF0IHRoaXMg
b3BlcmF0aW9uIGlzIGFjdGluZyBvbi4gRXhhbXBsZToKIGBhcHBzL215YXBwL3NlcnZpY2Vz
L2RlZmF1bHRgLgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIEBRIDNwIICgwKBQQAAgQBEgM3CQ8K
DAoFBAACBAMSAzcSEwphCgQEAAIFEgM7Ah8aVCBFcGhlbWVyYWwgbWVzc2FnZSB0aGF0IG1h
eSBjaGFuZ2UgZXZlcnkgdGltZSB0aGUgb3BlcmF0aW9uIGlzIHBvbGxlZC4KIEBPdXRwdXRP
bmx5CgoMCgUEAAIFBRIDOwIICgwKBQQAAgUBEgM7CRoKDAoFBAACBQMSAzsdHgpSCgQEAAIG
EgM/Ah4aRSBEdXJhYmxlIG1lc3NhZ2VzIHRoYXQgcGVyc2lzdCBvbiBldmVyeSBvcGVyYXRp
b24gcG9sbC4KIEBPdXRwdXRPbmx5CgoMCgUEAAIGBBIDPwIKCgwKBQQAAgYFEgM/CxEKDAoF
BAACBgESAz8SGQoMCgUEAAIGAxIDPxwdClQKBAQACAASBEMCRQMaRiBNZXRhZGF0YSBzcGVj
aWZpYyB0byB0aGUgdHlwZSBvZiBvcGVyYXRpb24gaW4gcHJvZ3Jlc3MuCiBAT3V0cHV0T25s
eQoKDAoFBAAIAAESA0MIFwoLCgQEAAIHEgNEBDgKDAoFBAACBwYSA0QEGwoMCgUEAAIHARID
RBwzCgwKBQQAAgcDEgNENjcKwgEKAgQBEgRKAE4BGrUBIE1ldGFkYXRhIGZvciB0aGUgZ2l2
ZW4gW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25dW2dvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb25dIGR1cmluZyBhCiBbZ29vZ2xlLmFwcGVuZ2luZS52MS5DcmVhdGVWZXJzaW9u
UmVxdWVzdF1bZ29vZ2xlLmFwcGVuZ2luZS52MS5DcmVhdGVWZXJzaW9uUmVxdWVzdF0uCgoK
CgMEAQESA0oIHwpgCgQEAQIAEgNNAhwaUyBUaGUgQ2xvdWQgQnVpbGQgSUQgaWYgb25lIHdh
cyBjcmVhdGVkIGFzIHBhcnQgb2YgdGhlIHZlcnNpb24gY3JlYXRlLgogQE91dHB1dE9ubHkK
CgwKBQQBAgAFEgNNAggKDAoFBAECAAESA00JFwoMCgUEAQIAAxIDTRobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Operation::OperationMetadataV1 ===
    # Fields for OperationMetadataV1
    # Field: method Type: 9 ()
    # Field: insert_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: user Type: 9 ()
    # Field: target Type: 9 ()
    # Field: ephemeral_message Type: 9 ()
    # Field: warning Type: 9 ()
    # Field: create_version_metadata Type: 11 (.google.appengine.v1.CreateVersionMetadataV1)

# === Message: Google::Appengine::V1::Operation::CreateVersionMetadataV1 ===
    # Fields for CreateVersionMetadataV1
    # Field: cloud_build_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Operation - Compiled Protocol Buffers messages for google/appengine/v1/operation.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Operation;

    my $msg = Google::Appengine::V1::Operation::OperationMetadataV1->new({
        method => $method,
        insert_time => $insert_time,
        end_time => $end_time,
        user => $user,
    });

    # Read or update a field
    my $val = $msg->method();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Operation::OperationMetadataV1->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/operation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Operation::OperationMetadataV1

Metadata for the given [google.longrunning.Operation][google.longrunning.Operation].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<String>

API method that initiated this operation. Example:
`google.appengine.v1.Versions.CreateVersion`.

@OutputOnly

=item * C<< $msg->insert_time() >> / C<< $msg->insert_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time that this operation was created.

@OutputOnly

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time that this operation completed.

@OutputOnly

=item * C<< $msg->user() >> / C<< $msg->user($value) >>

Type: C<String>

User who requested this operation.

@OutputOnly

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Name of the resource that this operation is acting on. Example:
`apps/myapp/services/default`.

@OutputOnly

=item * C<< $msg->ephemeral_message() >> / C<< $msg->ephemeral_message($value) >>

Type: C<String>

Ephemeral message that may change every time the operation is polled.
@OutputOnly

=item * C<< $msg->warning() >> / C<< $msg->warning($value) >>

Type: C<String>

Durable messages that persist on every operation poll.
@OutputOnly

=item * C<< $msg->create_version_metadata() >> / C<< $msg->create_version_metadata($value) >>

Type: C<Message> (L<Google::Appengine::V1::Operation::CreateVersionMetadataV1>)

=back

=head2 Google::Appengine::V1::Operation::CreateVersionMetadataV1

Metadata for the given [google.longrunning.Operation][google.longrunning.Operation] during a
[google.appengine.v1.CreateVersionRequest][google.appengine.v1.CreateVersionRequest].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_build_id() >> / C<< $msg->cloud_build_id($value) >>

Type: C<String>

The Cloud Build ID if one was created as part of the version create.
@OutputOnly

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Operation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
