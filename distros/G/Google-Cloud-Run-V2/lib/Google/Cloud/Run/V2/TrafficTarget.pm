package Google::Cloud::Run::V2::TrafficTarget;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvcnVuL3YyL3RyYWZmaWNfdGFyZ2V0LnByb3RvEhNnb29nbGUuY2xv
dWQucnVuLnYyGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIr8BCg1UcmFmZmljVGFyZ2V0
EkQKBHR5cGUYASABKA4yMC5nb29nbGUuY2xvdWQucnVuLnYyLlRyYWZmaWNUYXJnZXRBbGxv
Y2F0aW9uVHlwZVIEdHlwZRI8CghyZXZpc2lvbhgCIAEoCUIg+kEdChtydW4uZ29vZ2xlYXBp
cy5jb20vUmV2aXNpb25SCHJldmlzaW9uEhgKB3BlcmNlbnQYAyABKAVSB3BlcmNlbnQSEAoD
dGFnGAQgASgJUgN0YWci1wEKE1RyYWZmaWNUYXJnZXRTdGF0dXMSRAoEdHlwZRgBIAEoDjIw
Lmdvb2dsZS5jbG91ZC5ydW4udjIuVHJhZmZpY1RhcmdldEFsbG9jYXRpb25UeXBlUgR0eXBl
EjwKCHJldmlzaW9uGAIgASgJQiD6QR0KG3J1bi5nb29nbGVhcGlzLmNvbS9SZXZpc2lvblII
cmV2aXNpb24SGAoHcGVyY2VudBgDIAEoBVIHcGVyY2VudBIQCgN0YWcYBCABKAlSA3RhZxIQ
CgN1cmkYBSABKAlSA3VyaSqlAQobVHJhZmZpY1RhcmdldEFsbG9jYXRpb25UeXBlEi4KKlRS
QUZGSUNfVEFSR0VUX0FMTE9DQVRJT05fVFlQRV9VTlNQRUNJRklFRBAAEikKJVRSQUZGSUNf
VEFSR0VUX0FMTE9DQVRJT05fVFlQRV9MQVRFU1QQARIrCidUUkFGRklDX1RBUkdFVF9BTExP
Q0FUSU9OX1RZUEVfUkVWSVNJT04QAkJaChdjb20uZ29vZ2xlLmNsb3VkLnJ1bi52MkISVHJh
ZmZpY1RhcmdldFByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vcnVuL2FwaXYyL3J1bnBi
O3J1bnBiSvMSCgYSBA4ATAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQABwKCQoCAwASAxIAIwoICgEIEgMUAEAKCQoCCAsSAxQAQAoICgEIEgMVACIKCQoC
CAoSAxUAIgoICgEIEgMWADMKCQoCCAgSAxYAMwoICgEIEgMXADAKCQoCCAESAxcAMAqkAQoC
BAASBBsALAEalwEgSG9sZHMgYSBzaW5nbGUgdHJhZmZpYyByb3V0aW5nIGVudHJ5IGZvciB0
aGUgU2VydmljZS4gQWxsb2NhdGlvbnMgY2FuIGJlIGRvbmUKIHRvIGEgc3BlY2lmaWMgUmV2
aXNpb24gbmFtZSwgb3IgcG9pbnRpbmcgdG8gdGhlIGxhdGVzdCBSZWFkeSBSZXZpc2lvbi4K
CgoKAwQAARIDGwgVCjsKBAQAAgASAx0CJxouIFRoZSBhbGxvY2F0aW9uIHR5cGUgZm9yIHRo
aXMgdHJhZmZpYyB0YXJnZXQuCgoMCgUEAAIABhIDHQIdCgwKBQQAAgABEgMdHiIKDAoFBAAC
AAMSAx0lJgppCgQEAAIBEgQhAiMEGlsgUmV2aXNpb24gdG8gd2hpY2ggdG8gc2VuZCB0aGlz
IHBvcnRpb24gb2YgdHJhZmZpYywgaWYgdHJhZmZpYyBhbGxvY2F0aW9uIGlzCiBieSByZXZp
c2lvbi4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJEQoMCgUEAAIBAxIDIRQVCg0KBQQA
AgEIEgQhFiMDCg4KBwQAAgEInwgSAyIETQpoCgQEAAICEgMnAhQaWyBTcGVjaWZpZXMgcGVy
Y2VudCBvZiB0aGUgdHJhZmZpYyB0byB0aGlzIFJldmlzaW9uLgogVGhpcyBkZWZhdWx0cyB0
byB6ZXJvIGlmIHVuc3BlY2lmaWVkLgoKDAoFBAACAgUSAycCBwoMCgUEAAICARIDJwgPCgwK
BQQAAgIDEgMnEhMKXgoEBAACAxIDKwIRGlEgSW5kaWNhdGVzIGEgc3RyaW5nIHRvIGJlIHBh
cnQgb2YgdGhlIFVSSSB0byBleGNsdXNpdmVseSByZWZlcmVuY2UgdGhpcwogdGFyZ2V0LgoK
DAoFBAACAwUSAysCCAoMCgUEAAIDARIDKwkMCgwKBQQAAgMDEgMrDxAKTgoCBAESBC8AQAEa
QiBSZXByZXNlbnRzIHRoZSBvYnNlcnZlZCBzdGF0ZSBvZiBhIHNpbmdsZSBgVHJhZmZpY1Rh
cmdldGAgZW50cnkuCgoKCgMEAQESAy8IGwo7CgQEAQIAEgMxAicaLiBUaGUgYWxsb2NhdGlv
biB0eXBlIGZvciB0aGlzIHRyYWZmaWMgdGFyZ2V0LgoKDAoFBAECAAYSAzECHQoMCgUEAQIA
ARIDMR4iCgwKBQQBAgADEgMxJSYKNwoEBAECARIENAI2BBopIFJldmlzaW9uIHRvIHdoaWNo
IHRoaXMgdHJhZmZpYyBpcyBzZW50LgoKDAoFBAECAQUSAzQCCAoMCgUEAQIBARIDNAkRCgwK
BQQBAgEDEgM0FBUKDQoFBAECAQgSBDQWNgMKDgoHBAECAQifCBIDNQRNCkEKBAQBAgISAzkC
FBo0IFNwZWNpZmllcyBwZXJjZW50IG9mIHRoZSB0cmFmZmljIHRvIHRoaXMgUmV2aXNpb24u
CgoMCgUEAQICBRIDOQIHCgwKBQQBAgIBEgM5CA8KDAoFBAECAgMSAzkSEwpZCgQEAQIDEgM8
AhEaTCBJbmRpY2F0ZXMgdGhlIHN0cmluZyB1c2VkIGluIHRoZSBVUkkgdG8gZXhjbHVzaXZl
bHkgcmVmZXJlbmNlIHRoaXMgdGFyZ2V0LgoKDAoFBAECAwUSAzwCCAoMCgUEAQIDARIDPAkM
CgwKBQQBAgMDEgM8DxAKJwoEBAECBBIDPwIRGhogRGlzcGxheXMgdGhlIHRhcmdldCBVUkku
CgoMCgUEAQIEBRIDPwIICgwKBQQBAgQBEgM/CQwKDAoFBAECBAMSAz8PEAouCgIFABIEQwBM
ARoiIFRoZSB0eXBlIG9mIGluc3RhbmNlIGFsbG9jYXRpb24uCgoKCgMFAAESA0MFIAo0CgQF
AAIAEgNFAjEaJyBVbnNwZWNpZmllZCBpbnN0YW5jZSBhbGxvY2F0aW9uIHR5cGUuCgoMCgUF
AAIAARIDRQIsCgwKBQUAAgACEgNFLzAKSgoEBQACARIDSAIsGj0gQWxsb2NhdGVzIGluc3Rh
bmNlcyB0byB0aGUgU2VydmljZSdzIGxhdGVzdCByZWFkeSBSZXZpc2lvbi4KCgwKBQUAAgEB
EgNIAicKDAoFBQACAQISA0gqKwo5CgQFAAICEgNLAi4aLCBBbGxvY2F0ZXMgaW5zdGFuY2Vz
IHRvIGEgUmV2aXNpb24gYnkgbmFtZS4KCgwKBQUAAgIBEgNLAikKDAoFBQACAgISA0ssLWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::TrafficTarget::TrafficTarget ===
    # Fields for TrafficTarget
    # Field: type Type: 14 (.google.cloud.run.v2.TrafficTargetAllocationType)
    # Field: revision Type: 9 ()
    # Field: percent Type: 5 ()
    # Field: tag Type: 9 ()

# === Message: Google::Cloud::Run::V2::TrafficTarget::TrafficTargetStatus ===
    # Fields for TrafficTargetStatus
    # Field: type Type: 14 (.google.cloud.run.v2.TrafficTargetAllocationType)
    # Field: revision Type: 9 ()
    # Field: percent Type: 5 ()
    # Field: tag Type: 9 ()
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::TrafficTarget - Compiled Protocol Buffers messages for google/cloud/run/v2/traffic_target.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::TrafficTarget;

    my $msg = Google::Cloud::Run::V2::TrafficTarget::TrafficTarget->new({
        type => $type,
        revision => $revision,
        percent => $percent,
        tag => $tag,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::TrafficTarget::TrafficTarget->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/traffic_target.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::TrafficTarget::TrafficTarget

Holds a single traffic routing entry for the Service. Allocations can be done
to a specific Revision name, or pointing to the latest Ready Revision.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::TrafficTargetAllocationType>)

The allocation type for this traffic target.

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

Revision to which to send this portion of traffic, if traffic allocation is
by revision.

=item * C<< $msg->percent() >> / C<< $msg->percent($value) >>

Type: C<Int32>

Specifies percent of the traffic to this Revision.
This defaults to zero if unspecified.

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

Indicates a string to be part of the URI to exclusively reference this
target.

=back

=head2 Google::Cloud::Run::V2::TrafficTarget::TrafficTargetStatus

Represents the observed state of a single `TrafficTarget` entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::TrafficTargetAllocationType>)

The allocation type for this traffic target.

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

Revision to which this traffic is sent.

=item * C<< $msg->percent() >> / C<< $msg->percent($value) >>

Type: C<Int32>

Specifies percent of the traffic to this Revision.

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

Indicates the string used in the URI to exclusively reference this target.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Displays the target URI.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::TrafficTarget::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
