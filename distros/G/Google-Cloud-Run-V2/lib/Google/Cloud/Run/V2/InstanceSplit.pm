package Google::Cloud::Run::V2::InstanceSplit;

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
Cihnb29nbGUvY2xvdWQvcnVuL3YyL2luc3RhbmNlX3NwbGl0LnByb3RvEhNnb29nbGUuY2xv
dWQucnVuLnYyGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIq0BCg1JbnN0YW5jZVNwbGl0
EkQKBHR5cGUYASABKA4yMC5nb29nbGUuY2xvdWQucnVuLnYyLkluc3RhbmNlU3BsaXRBbGxv
Y2F0aW9uVHlwZVIEdHlwZRI8CghyZXZpc2lvbhgCIAEoCUIg+kEdChtydW4uZ29vZ2xlYXBp
cy5jb20vUmV2aXNpb25SCHJldmlzaW9uEhgKB3BlcmNlbnQYAyABKAVSB3BlcmNlbnQiswEK
E0luc3RhbmNlU3BsaXRTdGF0dXMSRAoEdHlwZRgBIAEoDjIwLmdvb2dsZS5jbG91ZC5ydW4u
djIuSW5zdGFuY2VTcGxpdEFsbG9jYXRpb25UeXBlUgR0eXBlEjwKCHJldmlzaW9uGAIgASgJ
QiD6QR0KG3J1bi5nb29nbGVhcGlzLmNvbS9SZXZpc2lvblIIcmV2aXNpb24SGAoHcGVyY2Vu
dBgDIAEoBVIHcGVyY2VudCqlAQobSW5zdGFuY2VTcGxpdEFsbG9jYXRpb25UeXBlEi4KKklO
U1RBTkNFX1NQTElUX0FMTE9DQVRJT05fVFlQRV9VTlNQRUNJRklFRBAAEikKJUlOU1RBTkNF
X1NQTElUX0FMTE9DQVRJT05fVFlQRV9MQVRFU1QQARIrCidJTlNUQU5DRV9TUExJVF9BTExP
Q0FUSU9OX1RZUEVfUkVWSVNJT04QAkJaChdjb20uZ29vZ2xlLmNsb3VkLnJ1bi52MkISSW5z
dGFuY2VTcGxpdFByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vcnVuL2FwaXYyL3J1bnBi
O3J1bnBiSrAQCgYSBA4AQgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
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
CAoSAxUAIgoICgEIEgMWADMKCQoCCAgSAxYAMwoICgEIEgMXADAKCQoCCAESAxcAMAqiAQoC
BAASBBsAKAEalQEgSG9sZHMgYSBzaW5nbGUgaW5zdGFuY2Ugc3BsaXQgZW50cnkgZm9yIHRo
ZSBXb3JrZXIuIEFsbG9jYXRpb25zIGNhbiBiZSBkb25lCiB0byBhIHNwZWNpZmljIFJldmlz
aW9uIG5hbWUsIG9yIHBvaW50aW5nIHRvIHRoZSBsYXRlc3QgUmVhZHkgUmV2aXNpb24uCgoK
CgMEAAESAxsIFQo7CgQEAAIAEgMdAicaLiBUaGUgYWxsb2NhdGlvbiB0eXBlIGZvciB0aGlz
IGluc3RhbmNlIHNwbGl0LgoKDAoFBAACAAYSAx0CHQoMCgUEAAIAARIDHR4iCgwKBQQAAgAD
EgMdJSYKawoEBAACARIEIQIjBBpdIFJldmlzaW9uIHRvIHdoaWNoIHRvIGFzc2lnbiB0aGlz
IHBvcnRpb24gb2YgaW5zdGFuY2VzLCBpZiBzcGxpdCBhbGxvY2F0aW9uCiBpcyBieSByZXZp
c2lvbi4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJEQoMCgUEAAIBAxIDIRQVCg0KBQQA
AgEIEgQhFiMDCg4KBwQAAgEInwgSAyIETQpvCgQEAAICEgMnAhQaYiBTcGVjaWZpZXMgcGVy
Y2VudCBvZiB0aGUgaW5zdGFuY2Ugc3BsaXQgdG8gdGhpcyBSZXZpc2lvbi4KIFRoaXMgZGVm
YXVsdHMgdG8gemVybyBpZiB1bnNwZWNpZmllZC4KCgwKBQQAAgIFEgMnAgcKDAoFBAACAgES
AycIDwoMCgUEAAICAxIDJxITCk4KAgQBEgQrADYBGkIgUmVwcmVzZW50cyB0aGUgb2JzZXJ2
ZWQgc3RhdGUgb2YgYSBzaW5nbGUgYEluc3RhbmNlU3BsaXRgIGVudHJ5LgoKCgoDBAEBEgMr
CBsKOwoEBAECABIDLQInGi4gVGhlIGFsbG9jYXRpb24gdHlwZSBmb3IgdGhpcyBpbnN0YW5j
ZSBzcGxpdC4KCgwKBQQBAgAGEgMtAh0KDAoFBAECAAESAy0eIgoMCgUEAQIAAxIDLSUmCkIK
BAQBAgESBDACMgQaNCBSZXZpc2lvbiB0byB3aGljaCB0aGlzIGluc3RhbmNlIHNwbGl0IGlz
IGFzc2lnbmVkLgoKDAoFBAECAQUSAzACCAoMCgUEAQIBARIDMAkRCgwKBQQBAgEDEgMwFBUK
DQoFBAECAQgSBDAWMgMKDgoHBAECAQifCBIDMQRNCkgKBAQBAgISAzUCFBo7IFNwZWNpZmll
cyBwZXJjZW50IG9mIHRoZSBpbnN0YW5jZSBzcGxpdCB0byB0aGlzIFJldmlzaW9uLgoKDAoF
BAECAgUSAzUCBwoMCgUEAQICARIDNQgPCgwKBQQBAgIDEgM1EhMKNAoCBQASBDkAQgEaKCBU
aGUgdHlwZSBvZiBpbnN0YW5jZSBzcGxpdCBhbGxvY2F0aW9uLgoKCgoDBQABEgM5BSAKNAoE
BQACABIDOwIxGicgVW5zcGVjaWZpZWQgaW5zdGFuY2UgYWxsb2NhdGlvbiB0eXBlLgoKDAoF
BQACAAESAzsCLAoMCgUFAAIAAhIDOy8wCkoKBAUAAgESAz4CLBo9IEFsbG9jYXRlcyBpbnN0
YW5jZXMgdG8gdGhlIFNlcnZpY2UncyBsYXRlc3QgcmVhZHkgUmV2aXNpb24uCgoMCgUFAAIB
ARIDPgInCgwKBQUAAgECEgM+KisKOQoEBQACAhIDQQIuGiwgQWxsb2NhdGVzIGluc3RhbmNl
cyB0byBhIFJldmlzaW9uIGJ5IG5hbWUuCgoMCgUFAAICARIDQQIpCgwKBQUAAgICEgNBLC1i
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::InstanceSplit::InstanceSplit ===
    # Fields for InstanceSplit
    # Field: type Type: 14 (.google.cloud.run.v2.InstanceSplitAllocationType)
    # Field: revision Type: 9 ()
    # Field: percent Type: 5 ()

# === Message: Google::Cloud::Run::V2::InstanceSplit::InstanceSplitStatus ===
    # Fields for InstanceSplitStatus
    # Field: type Type: 14 (.google.cloud.run.v2.InstanceSplitAllocationType)
    # Field: revision Type: 9 ()
    # Field: percent Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::InstanceSplit - Compiled Protocol Buffers messages for google/cloud/run/v2/instance_split.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::InstanceSplit;

    my $msg = Google::Cloud::Run::V2::InstanceSplit::InstanceSplit->new({
        type => $type,
        revision => $revision,
        percent => $percent,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::InstanceSplit::InstanceSplit->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/instance_split.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::InstanceSplit::InstanceSplit

Holds a single instance split entry for the Worker. Allocations can be done
to a specific Revision name, or pointing to the latest Ready Revision.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::InstanceSplitAllocationType>)

The allocation type for this instance split.

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

Revision to which to assign this portion of instances, if split allocation
is by revision.

=item * C<< $msg->percent() >> / C<< $msg->percent($value) >>

Type: C<Int32>

Specifies percent of the instance split to this Revision.
This defaults to zero if unspecified.

=back

=head2 Google::Cloud::Run::V2::InstanceSplit::InstanceSplitStatus

Represents the observed state of a single `InstanceSplit` entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::InstanceSplitAllocationType>)

The allocation type for this instance split.

=item * C<< $msg->revision() >> / C<< $msg->revision($value) >>

Type: C<String>

Revision to which this instance split is assigned.

=item * C<< $msg->percent() >> / C<< $msg->percent($value) >>

Type: C<Int32>

Specifies percent of the instance split to this Revision.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::InstanceSplit::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
