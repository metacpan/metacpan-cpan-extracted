package Google::Cloud::Securitycenter::V1::AttackExposure;

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
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYXR0YWNrX2V4cG9zdXJlLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8ipgQKDkF0dGFja0V4cG9zdXJlEhQKBXNjb3JlGAEgASgBUgVzY29yZRJS
ChdsYXRlc3RfY2FsY3VsYXRpb25fdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSFWxhdGVzdENhbGN1bGF0aW9uVGltZRI0ChZhdHRhY2tfZXhwb3N1cmVfcmVzdWx0
GAMgASgJUhRhdHRhY2tFeHBvc3VyZVJlc3VsdBJKCgVzdGF0ZRgEIAEoDjI0Lmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MS5BdHRhY2tFeHBvc3VyZS5TdGF0ZVIFc3RhdGUSSgoi
ZXhwb3NlZF9oaWdoX3ZhbHVlX3Jlc291cmNlc19jb3VudBgFIAEoBVIeZXhwb3NlZEhpZ2hW
YWx1ZVJlc291cmNlc0NvdW50Ek4KJGV4cG9zZWRfbWVkaXVtX3ZhbHVlX3Jlc291cmNlc19j
b3VudBgGIAEoBVIgZXhwb3NlZE1lZGl1bVZhbHVlUmVzb3VyY2VzQ291bnQSSAohZXhwb3Nl
ZF9sb3dfdmFsdWVfcmVzb3VyY2VzX2NvdW50GAcgASgFUh1leHBvc2VkTG93VmFsdWVSZXNv
dXJjZXNDb3VudCJCCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg4KCkNBTENVTEFU
RUQQARISCg5OT1RfQ0FMQ1VMQVRFRBACQu0BCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYxQhNBdHRhY2tFeHBvc3VyZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28v
c2VjdXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBi
qgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3Vy
aXR5Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSvASCgYS
BA4ARgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoC
AwASAxIAKQoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEI
EgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADQKCQoCCAgSAxcANAoICgEIEgMYADsKCQoCCAES
AxgAOwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgpXCgIEABIE
HQBGARpLIEFuIGF0dGFjayBleHBvc3VyZSBjb250YWlucyB0aGUgcmVzdWx0cyBvZiBhbiBh
dHRhY2sgcGF0aCBzaW11bGF0aW9uIHJ1bi4KCgoKAwQAARIDHQgWClEKBAQABAASBB8CKAMa
QyBUaGlzIGVudW0gZGVmaW5lcyB0aGUgdmFyaW91cyBzdGF0ZXMgYW4gQXR0YWNrRXhwb3N1
cmUgY2FuIGJlIGluLgoKDAoFBAAEAAESAx8HDAosCgYEAAQAAgASAyEEGhodIFRoZSBzdGF0
ZSBpcyBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDIQQVCg4KBwQABAACAAISAyEYGQo5
CgYEAAQAAgESAyQEExoqIFRoZSBhdHRhY2sgZXhwb3N1cmUgaGFzIGJlZW4gY2FsY3VsYXRl
ZC4KCg4KBwQABAACAQESAyQEDgoOCgcEAAQAAgECEgMkERIKPQoGBAAEAAICEgMnBBcaLiBU
aGUgYXR0YWNrIGV4cG9zdXJlIGhhcyBub3QgYmVlbiBjYWxjdWxhdGVkLgoKDgoHBAAEAAIC
ARIDJwQSCg4KBwQABAACAgISAycVFgq2AQoEBAACABIDLQITGqgBIEEgbnVtYmVyIGJldHdl
ZW4gMCAoaW5jbHVzaXZlKSBhbmQgaW5maW5pdHkgdGhhdCByZXByZXNlbnRzIGhvdyBpbXBv
cnRhbnQKIHRoaXMgZmluZGluZyBpcyB0byByZW1lZGlhdGUuIFRoZSBoaWdoZXIgdGhlIHNj
b3JlLCB0aGUgbW9yZSBpbXBvcnRhbnQgaXQKIGlzIHRvIHJlbWVkaWF0ZS4KCgwKBQQAAgAF
EgMtAggKDAoFBAACAAESAy0JDgoMCgUEAAIAAxIDLRESClQKBAQAAgESAzACOBpHIFRoZSBt
b3N0IHJlY2VudCB0aW1lIHRoZSBhdHRhY2sgZXhwb3N1cmUgd2FzIHVwZGF0ZWQgb24gdGhp
cyBmaW5kaW5nLgoKDAoFBAACAQYSAzACGwoMCgUEAAIBARIDMBwzCgwKBQQAAgEDEgMwNjcK
zwEKBAQAAgISAzUCJBrBASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYXR0YWNrIHBhdGgg
c2ltdWxhdGlvbiByZXN1bHQgdGhhdCBjb250YWlucyB0aGUKIGRldGFpbHMgcmVnYXJkaW5n
IHRoaXMgYXR0YWNrIGV4cG9zdXJlIHNjb3JlLgogRXhhbXBsZTogYG9yZ2FuaXphdGlvbnMv
MTIzL3NpbXVsYXRpb25zLzQ1Ni9hdHRhY2tFeHBvc3VyZVJlc3VsdHMvNzg5YAoKDAoFBAAC
AgUSAzUCCAoMCgUEAAICARIDNQkfCgwKBQQAAgIDEgM1IiMKgQEKBAQAAgMSAzkCEhp0IFdo
YXQgc3RhdGUgdGhpcyBBdHRhY2tFeHBvc3VyZSBpcyBpbi4gVGhpcyBjYXB0dXJlcyB3aGV0
aGVyIG9yIG5vdCBhbgogYXR0YWNrIGV4cG9zdXJlIGhhcyBiZWVuIGNhbGN1bGF0ZWQgb3Ig
bm90LgoKDAoFBAACAwYSAzkCBwoMCgUEAAIDARIDOQgNCgwKBQQAAgMDEgM5EBEKYAoEBAAC
BBIDPQIvGlMgVGhlIG51bWJlciBvZiBoaWdoIHZhbHVlIHJlc291cmNlcyB0aGF0IGFyZSBl
eHBvc2VkIGFzIGEgcmVzdWx0IG9mIHRoaXMKIGZpbmRpbmcuCgoMCgUEAAIEBRIDPQIHCgwK
BQQAAgQBEgM9CCoKDAoFBAACBAMSAz0tLgpiCgQEAAIFEgNBAjEaVSBUaGUgbnVtYmVyIG9m
IG1lZGl1bSB2YWx1ZSByZXNvdXJjZXMgdGhhdCBhcmUgZXhwb3NlZCBhcyBhIHJlc3VsdCBv
ZiB0aGlzCiBmaW5kaW5nLgoKDAoFBAACBQUSA0ECBwoMCgUEAAIFARIDQQgsCgwKBQQAAgUD
EgNBLzAKYAoEBAACBhIDRQIuGlMgVGhlIG51bWJlciBvZiBoaWdoIHZhbHVlIHJlc291cmNl
cyB0aGF0IGFyZSBleHBvc2VkIGFzIGEgcmVzdWx0IG9mIHRoaXMKIGZpbmRpbmcuCgoMCgUE
AAIGBRIDRQIHCgwKBQQAAgYBEgNFCCkKDAoFBAACBgMSA0UsLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure ===
    # Fields for AttackExposure
    # Field: score Type: 1 ()
    # Field: latest_calculation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: attack_exposure_result Type: 9 ()
    # Field: state Type: 14 (.google.cloud.securitycenter.v1.AttackExposure.State)
    # Field: exposed_high_value_resources_count Type: 5 ()
    # Field: exposed_medium_value_resources_count Type: 5 ()
    # Field: exposed_low_value_resources_count Type: 5 ()

# Enum: AttackExposure::State
our $AttackExposure_STATE_UNSPECIFIED = 0;
our $AttackExposure_CALCULATED = 1;
our $AttackExposure_NOT_CALCULATED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::AttackExposure - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/attack_exposure.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::AttackExposure;

    my $msg = Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure->new({
        score => $score,
        latest_calculation_time => $latest_calculation_time,
        attack_exposure_result => $attack_exposure_result,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->score();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/attack_exposure.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure

An attack exposure contains the results of an attack path simulation run.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Double>

A number between 0 (inclusive) and infinity that represents how important
this finding is to remediate. The higher the score, the more important it
is to remediate.

=item * C<< $msg->latest_calculation_time() >> / C<< $msg->latest_calculation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The most recent time the attack exposure was updated on this finding.

=item * C<< $msg->attack_exposure_result() >> / C<< $msg->attack_exposure_result($value) >>

Type: C<String>

The resource name of the attack path simulation result that contains the
details regarding this attack exposure score.
Example: `organizations/123/simulations/456/attackExposureResults/789`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::AttackExposure::State>)

What state this AttackExposure is in. This captures whether or not an
attack exposure has been calculated or not.

=item * C<< $msg->exposed_high_value_resources_count() >> / C<< $msg->exposed_high_value_resources_count($value) >>

Type: C<Int32>

The number of high value resources that are exposed as a result of this
finding.

=item * C<< $msg->exposed_medium_value_resources_count() >> / C<< $msg->exposed_medium_value_resources_count($value) >>

Type: C<Int32>

The number of medium value resources that are exposed as a result of this
finding.

=item * C<< $msg->exposed_low_value_resources_count() >> / C<< $msg->exposed_low_value_resources_count($value) >>

Type: C<Int32>

The number of high value resources that are exposed as a result of this
finding.

=back

=head3 Enum: AttackExposure::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CALCULATED> => C<1>

=item * C<NOT_CALCULATED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::AttackExposure::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
