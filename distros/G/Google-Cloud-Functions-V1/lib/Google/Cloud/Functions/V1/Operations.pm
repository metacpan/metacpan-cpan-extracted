package Google::Cloud::Functions::V1::Operations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvZnVuY3Rpb25zL3YxL29wZXJhdGlvbnMucHJvdG8SGWdvb2dsZS5j
bG91ZC5mdW5jdGlvbnMudjEaGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1AIKE09wZXJhdGlvbk1ldGFkYXRhVjESFgoGdGFy
Z2V0GAEgASgJUgZ0YXJnZXQSPAoEdHlwZRgCIAEoDjIoLmdvb2dsZS5jbG91ZC5mdW5jdGlv
bnMudjEuT3BlcmF0aW9uVHlwZVIEdHlwZRIuCgdyZXF1ZXN0GAMgASgLMhQuZ29vZ2xlLnBy
b3RvYnVmLkFueVIHcmVxdWVzdBIdCgp2ZXJzaW9uX2lkGAQgASgDUgl2ZXJzaW9uSWQSOwoL
dXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVU
aW1lEhkKCGJ1aWxkX2lkGAYgASgJUgdidWlsZElkEiEKDHNvdXJjZV90b2tlbhgHIAEoCVIL
c291cmNlVG9rZW4SHQoKYnVpbGRfbmFtZRgIIAEoCVIJYnVpbGROYW1lKmkKDU9wZXJhdGlv
blR5cGUSGQoVT1BFUkFUSU9OX1VOU1BFQ0lGSUVEEAASEwoPQ1JFQVRFX0ZVTkNUSU9OEAES
EwoPVVBEQVRFX0ZVTkNUSU9OEAISEwoPREVMRVRFX0ZVTkNUSU9OEANCeAodY29tLmdvb2ds
ZS5jbG91ZC5mdW5jdGlvbnMudjFCGEZ1bmN0aW9uc09wZXJhdGlvbnNQcm90b1ABWjtjbG91
ZC5nb29nbGUuY29tL2dvL2Z1bmN0aW9ucy9hcGl2MS9mdW5jdGlvbnNwYjtmdW5jdGlvbnNw
YkrSEgoGEgQOAEgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAiCgkKAgMAEgMSACMKCQoCAwESAxMAKQoICgEIEgMVAFIKCQoCCAsSAxUAUgoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADkKCQoCCAgSAxcAOQoICgEIEgMYADYKCQoCCAESAxgA
NgolCgIFABIEGwAnARoZIEEgdHlwZSBvZiBhbiBvcGVyYXRpb24uCgoKCgMFAAESAxsFEgom
CgQFAAIAEgMdAhwaGSBVbmtub3duIG9wZXJhdGlvbiB0eXBlLgoKDAoFBQACAAESAx0CFwoM
CgUFAAIAAhIDHRobCi8KBAUAAgESAyACFhoiIFRyaWdnZXJlZCBieSBDcmVhdGVGdW5jdGlv
biBjYWxsCgoMCgUFAAIBARIDIAIRCgwKBQUAAgECEgMgFBUKLwoEBQACAhIDIwIWGiIgVHJp
Z2dlcmVkIGJ5IFVwZGF0ZUZ1bmN0aW9uIGNhbGwKCgwKBQUAAgIBEgMjAhEKDAoFBQACAgIS
AyMUFQowCgQFAAIDEgMmAhYaIyBUcmlnZ2VyZWQgYnkgRGVsZXRlRnVuY3Rpb24gY2FsbC4K
CgwKBQUAAgMBEgMmAhEKDAoFBQACAwISAyYUFQpOCgIEABIEKgBIARpCIE1ldGFkYXRhIGRl
c2NyaWJpbmcgYW4gW09wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0K
CgoKAwQAARIDKggbCnIKBAQAAgASAy0CFBplIFRhcmdldCBvZiB0aGUgb3BlcmF0aW9uIC0g
Zm9yIGV4YW1wbGUKIGBwcm9qZWN0cy9wcm9qZWN0LTEvbG9jYXRpb25zL3JlZ2lvbi0xL2Z1
bmN0aW9ucy9mdW5jdGlvbi0xYAoKDAoFBAACAAUSAy0CCAoMCgUEAAIAARIDLQkPCgwKBQQA
AgADEgMtEhMKIQoEBAACARIDMAIZGhQgVHlwZSBvZiBvcGVyYXRpb24uCgoMCgUEAAIBBhID
MAIPCgwKBQQAAgEBEgMwEBQKDAoFBAACAQMSAzAXGAo/CgQEAAICEgMzAiIaMiBUaGUgb3Jp
Z2luYWwgcmVxdWVzdCB0aGF0IHN0YXJ0ZWQgdGhlIG9wZXJhdGlvbi4KCgwKBQQAAgIGEgMz
AhUKDAoFBAACAgESAzMWHQoMCgUEAAICAxIDMyAhCowBCgQEAAIDEgM3AhcafyBWZXJzaW9u
IGlkIG9mIHRoZSBmdW5jdGlvbiBjcmVhdGVkIG9yIHVwZGF0ZWQgYnkgYW4gQVBJIGNhbGwu
CiBUaGlzIGZpZWxkIGlzIG9ubHkgcG9wdWxhdGVkIGZvciBDcmVhdGUgYW5kIFVwZGF0ZSBv
cGVyYXRpb25zLgoKDAoFBAACAwUSAzcCBwoMCgUEAAIDARIDNwgSCgwKBQQAAgMDEgM3FRYK
OgoEBAACBBIDOgIsGi0gVGhlIGxhc3QgdXBkYXRlIHRpbWVzdGFtcCBvZiB0aGUgb3BlcmF0
aW9uLgoKDAoFBAACBAYSAzoCGwoMCgUEAAIEARIDOhwnCgwKBQQAAgQDEgM6KisKlQEKBAQA
AgUSAz4CFhqHASBUaGUgQ2xvdWQgQnVpbGQgSUQgb2YgdGhlIGZ1bmN0aW9uIGNyZWF0ZWQg
b3IgdXBkYXRlZCBieSBhbiBBUEkgY2FsbC4KIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0
ZWQgZm9yIENyZWF0ZSBhbmQgVXBkYXRlIG9wZXJhdGlvbnMuCgoMCgUEAAIFBRIDPgIICgwK
BQQAAgUBEgM+CREKDAoFBAACBQMSAz4UFQqIAQoEBAACBhIDQgIaGnsgQW4gaWRlbnRpZmll
ciBmb3IgRmlyZWJhc2UgZnVuY3Rpb24gc291cmNlcy4gRGlzY2xhaW1lcjogVGhpcyBmaWVs
ZCBpcyBvbmx5CiBzdXBwb3J0ZWQgZm9yIEZpcmViYXNlIGZ1bmN0aW9uIGRlcGxveW1lbnRz
LgoKDAoFBAACBgUSA0ICCAoMCgUEAAIGARIDQgkVCgwKBQQAAgYDEgNCGBkKwwEKBAQAAgcS
A0cCGBq1ASBUaGUgQ2xvdWQgQnVpbGQgTmFtZSBvZiB0aGUgZnVuY3Rpb24gZGVwbG95bWVu
dC4KIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQgZm9yIENyZWF0ZSBhbmQgVXBkYXRl
IG9wZXJhdGlvbnMuCiBgcHJvamVjdHMvPHByb2plY3QtbnVtYmVyPi9sb2NhdGlvbnMvPHJl
Z2lvbj4vYnVpbGRzLzxidWlsZC1pZD5gLgoKDAoFBAACBwUSA0cCCAoMCgUEAAIHARIDRwkT
CgwKBQQAAgcDEgNHFhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Functions::V1::Operations::OperationMetadataV1 ===
    # Fields for OperationMetadataV1
    # Field: target Type: 9 ()
    # Field: type Type: 14 (.google.cloud.functions.v1.OperationType)
    # Field: request Type: 11 (.google.protobuf.Any)
    # Field: version_id Type: 3 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: build_id Type: 9 ()
    # Field: source_token Type: 9 ()
    # Field: build_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Functions::V1::Operations - Compiled Protocol Buffers messages for google/cloud/functions/v1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Functions::V1::Operations;

    my $msg = Google::Cloud::Functions::V1::Operations::OperationMetadataV1->new({
        target => $target,
        type => $type,
        request => $request,
        version_id => $version_id,
    });

    # Read or update a field
    my $val = $msg->target();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Functions::V1::Operations::OperationMetadataV1->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/functions/v1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Functions::V1::Operations::OperationMetadataV1

Metadata describing an [Operation][google.longrunning.Operation]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Target of the operation - for example
`projects/project-1/locations/region-1/functions/function-1`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Functions::V1::OperationType>)

Type of operation.

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The original request that started the operation.

=item * C<< $msg->version_id() >> / C<< $msg->version_id($value) >>

Type: C<Int64>

Version id of the function created or updated by an API call.
This field is only populated for Create and Update operations.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last update timestamp of the operation.

=item * C<< $msg->build_id() >> / C<< $msg->build_id($value) >>

Type: C<String>

The Cloud Build ID of the function created or updated by an API call.
This field is only populated for Create and Update operations.

=item * C<< $msg->source_token() >> / C<< $msg->source_token($value) >>

Type: C<String>

An identifier for Firebase function sources. Disclaimer: This field is only
supported for Firebase function deployments.

=item * C<< $msg->build_name() >> / C<< $msg->build_name($value) >>

Type: C<String>

The Cloud Build Name of the function deployment.
This field is only populated for Create and Update operations.
`projects/<project-number>/locations/<region>/builds/<build-id>`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Functions::V1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
