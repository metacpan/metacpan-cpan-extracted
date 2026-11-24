package Google::Appengine::V1beta::Operation;

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
Cidnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9vcGVyYXRpb24ucHJvdG8SF2dvb2dsZS5hcHBl
bmdpbmUudjFiZXRhGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpsDChdPcGVy
YXRpb25NZXRhZGF0YVYxQmV0YRIWCgZtZXRob2QYASABKAlSBm1ldGhvZBI7CgtpbnNlcnRf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmluc2VydFRpbWUSNQoI
ZW5kX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdlbmRUaW1lEhIK
BHVzZXIYBCABKAlSBHVzZXISFgoGdGFyZ2V0GAUgASgJUgZ0YXJnZXQSKwoRZXBoZW1lcmFs
X21lc3NhZ2UYBiABKAlSEGVwaGVtZXJhbE1lc3NhZ2USGAoHd2FybmluZxgHIAMoCVIHd2Fy
bmluZxJuChdjcmVhdGVfdmVyc2lvbl9tZXRhZGF0YRgIIAEoCzI0Lmdvb2dsZS5hcHBlbmdp
bmUudjFiZXRhLkNyZWF0ZVZlcnNpb25NZXRhZGF0YVYxQmV0YUgAUhVjcmVhdGVWZXJzaW9u
TWV0YWRhdGFCEQoPbWV0aG9kX21ldGFkYXRhIkMKG0NyZWF0ZVZlcnNpb25NZXRhZGF0YVYx
QmV0YRIkCg5jbG91ZF9idWlsZF9pZBgBIAEoCVIMY2xvdWRCdWlsZElkQtQBChtjb20uZ29v
Z2xlLmFwcGVuZ2luZS52MWJldGFCDk9wZXJhdGlvblByb3RvUAFaQGdvb2dsZS5nb2xhbmcu
b3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBwZW5naW5lL3YxYmV0YTthcHBlbmdpbmWqAh1H
b29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxQmV0YcoCHUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVc
VjFiZXRh6gIgR29vZ2xlOjpDbG91ZDo6QXBwRW5naW5lOjpWMWJldGFKlBIKBhIEDgBOAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgAp
CggKAQgSAxQAOgoJCgIIJRIDFAA6CggKAQgSAxUAVwoJCgIICxIDFQBXCggKAQgSAxYAIgoJ
CgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgANAoJCgIIARIDGAA0CggK
AQgSAxkAOgoJCgIIKRIDGQA6CggKAQgSAxoAOQoJCgIILRIDGgA5CmIKAgQAEgQdAEYBGlYg
TWV0YWRhdGEgZm9yIHRoZSBnaXZlbiBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1b
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0uCgoKCgMEAAESAx0IHwqCAQoEBAACABID
IgIUGnUgQVBJIG1ldGhvZCB0aGF0IGluaXRpYXRlZCB0aGlzIG9wZXJhdGlvbi4gRXhhbXBs
ZToKIGBnb29nbGUuYXBwZW5naW5lLnYxYmV0YS5WZXJzaW9ucy5DcmVhdGVWZXJzaW9uYC4K
CiBAT3V0cHV0T25seQoKDAoFBAACAAUSAyICCAoMCgUEAAIAARIDIgkPCgwKBQQAAgADEgMi
EhMKQgoEBAACARIDJwIsGjUgVGltZSB0aGF0IHRoaXMgb3BlcmF0aW9uIHdhcyBjcmVhdGVk
LgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIBBhIDJwIbCgwKBQQAAgEBEgMnHCcKDAoFBAACAQMS
AycqKwpACgQEAAICEgMsAikaMyBUaW1lIHRoYXQgdGhpcyBvcGVyYXRpb24gY29tcGxldGVk
LgoKIEBPdXRwdXRPbmx5CgoMCgUEAAICBhIDLAIbCgwKBQQAAgIBEgMsHCQKDAoFBAACAgMS
AywnKAo/CgQEAAIDEgMxAhIaMiBVc2VyIHdobyByZXF1ZXN0ZWQgdGhpcyBvcGVyYXRpb24u
CgogQE91dHB1dE9ubHkKCgwKBQQAAgMFEgMxAggKDAoFBAACAwESAzEJDQoMCgUEAAIDAxID
MRARCnwKBAQAAgQSAzcCFBpvIE5hbWUgb2YgdGhlIHJlc291cmNlIHRoYXQgdGhpcyBvcGVy
YXRpb24gaXMgYWN0aW5nIG9uLiBFeGFtcGxlOgogYGFwcHMvbXlhcHAvc2VydmljZXMvZGVm
YXVsdGAuCgogQE91dHB1dE9ubHkKCgwKBQQAAgQFEgM3AggKDAoFBAACBAESAzcJDwoMCgUE
AAIEAxIDNxITCmEKBAQAAgUSAzsCHxpUIEVwaGVtZXJhbCBtZXNzYWdlIHRoYXQgbWF5IGNo
YW5nZSBldmVyeSB0aW1lIHRoZSBvcGVyYXRpb24gaXMgcG9sbGVkLgogQE91dHB1dE9ubHkK
CgwKBQQAAgUFEgM7AggKDAoFBAACBQESAzsJGgoMCgUEAAIFAxIDOx0eClIKBAQAAgYSAz8C
HhpFIER1cmFibGUgbWVzc2FnZXMgdGhhdCBwZXJzaXN0IG9uIGV2ZXJ5IG9wZXJhdGlvbiBw
b2xsLgogQE91dHB1dE9ubHkKCgwKBQQAAgYEEgM/AgoKDAoFBAACBgUSAz8LEQoMCgUEAAIG
ARIDPxIZCgwKBQQAAgYDEgM/HB0KVAoEBAAIABIEQwJFAxpGIE1ldGFkYXRhIHNwZWNpZmlj
IHRvIHRoZSB0eXBlIG9mIG9wZXJhdGlvbiBpbiBwcm9ncmVzcy4KIEBPdXRwdXRPbmx5CgoM
CgUEAAgAARIDQwgXCgsKBAQAAgcSA0QEPAoMCgUEAAIHBhIDRAQfCgwKBQQAAgcBEgNEIDcK
DAoFBAACBwMSA0Q6OwrKAQoCBAESBEoATgEavQEgTWV0YWRhdGEgZm9yIHRoZSBnaXZlbiBb
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbl0gZHVyaW5nIGEKIFtnb29nbGUuYXBwZW5naW5lLnYxYmV0YS5DcmVhdGVWZXJzaW9u
UmVxdWVzdF1bZ29vZ2xlLmFwcGVuZ2luZS52MWJldGEuQ3JlYXRlVmVyc2lvblJlcXVlc3Rd
LgoKCgoDBAEBEgNKCCMKYAoEBAECABIDTQIcGlMgVGhlIENsb3VkIEJ1aWxkIElEIGlmIG9u
ZSB3YXMgY3JlYXRlZCBhcyBwYXJ0IG9mIHRoZSB2ZXJzaW9uIGNyZWF0ZS4KIEBPdXRwdXRP
bmx5CgoMCgUEAQIABRIDTQIICgwKBQQBAgABEgNNCRcKDAoFBAECAAMSA00aG2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Operation::OperationMetadataV1Beta ===
    # Fields for OperationMetadataV1Beta
    # Field: method Type: 9 ()
    # Field: insert_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: user Type: 9 ()
    # Field: target Type: 9 ()
    # Field: ephemeral_message Type: 9 ()
    # Field: warning Type: 9 ()
    # Field: create_version_metadata Type: 11 (.google.appengine.v1beta.CreateVersionMetadataV1Beta)

# === Message: Google::Appengine::V1beta::Operation::CreateVersionMetadataV1Beta ===
    # Fields for CreateVersionMetadataV1Beta
    # Field: cloud_build_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Operation - Compiled Protocol Buffers messages for google/appengine/v1beta/operation.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Operation;

    my $msg = Google::Appengine::V1beta::Operation::OperationMetadataV1Beta->new({
        method => $method,
        insert_time => $insert_time,
        end_time => $end_time,
        user => $user,
    });

    # Read or update a field
    my $val = $msg->method();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Operation::OperationMetadataV1Beta->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/operation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Operation::OperationMetadataV1Beta

Metadata for the given [google.longrunning.Operation][google.longrunning.Operation].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<String>

API method that initiated this operation. Example:
`google.appengine.v1beta.Versions.CreateVersion`.

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

Type: C<Message> (L<Google::Appengine::V1beta::Operation::CreateVersionMetadataV1Beta>)

=back

=head2 Google::Appengine::V1beta::Operation::CreateVersionMetadataV1Beta

Metadata for the given [google.longrunning.Operation][google.longrunning.Operation] during a
[google.appengine.v1beta.CreateVersionRequest][google.appengine.v1beta.CreateVersionRequest].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_build_id() >> / C<< $msg->cloud_build_id($value) >>

Type: C<String>

The Cloud Build ID if one was created as part of the version create.
@OutputOnly

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Operation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
