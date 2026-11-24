package Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY29tcHV0ZS9sb2dnaW5nL2RyL3YxL2Rpc2FzdGVyX3JlY292ZXJ5X2V2ZW50
LnByb3RvEhxnb29nbGUuY29tcHV0ZS5sb2dnaW5nLmRyLnYxIosCChVEaXNhc3RlclJlY292
ZXJ5RXZlbnQSXQoIc2V2ZXJpdHkYASABKA4yPC5nb29nbGUuY29tcHV0ZS5sb2dnaW5nLmRy
LnYxLkRpc2FzdGVyUmVjb3ZlcnlFdmVudC5TZXZlcml0eUgAUghzZXZlcml0eYgBARIdCgdk
ZXRhaWxzGAIgASgJSAFSB2RldGFpbHOIAQEiWwoIU2V2ZXJpdHkSGAoUU0VWRVJJVFlfVU5T
UEVDSUZJRUQQABITCg9BQ1RJT05fUkVRVUlSRUQQARIUChBBQ1RJT05fU1VHR0VTVEVEEAIS
CgoGTk9USUNFEANCCwoJX3NldmVyaXR5QgoKCF9kZXRhaWxzQuEBCiBjb20uZ29vZ2xlLmNv
bXB1dGUubG9nZ2luZy5kci52MUIaRGlzYXN0ZXJSZWNvdmVyeUV2ZW50UHJvdG9QAVo+Z29v
Z2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9jb21wdXRlL2xvZ2dpbmcvZHIv
djE7ZHKqAhxHb29nbGUuQ29tcHV0ZS5Mb2dnaW5nLkRyLlYxygIcR29vZ2xlXENvbXB1dGVc
TG9nZ2luZ1xEclxWMeoCIEdvb2dsZTo6Q29tcHV0ZTo6TG9nZ2luZzo6RHI6OlYxSuENCgYS
BA4ANQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCAoB
CBIDEgBVCgkKAggLEgMSAFUKCAoBCBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAA7CgkKAggI
EgMUADsKCAoBCBIDFQA5CgkKAggBEgMVADkKCAoBCBIDFgA5CgkKAgglEgMWADkKCAoBCBID
FwA6CgkKAggpEgMXADoKCAoBCBIDGAA5CgkKAggtEgMYADkKYgoCBAASBBwANQEaViBBbiBl
dmVudCBzaWduaWZ5aW5nIGEgQ29tcHV0ZSBFbmdpbmUgcmVzb3VyY2UgaXMgaW1wYWN0ZWQg
YnkgdGhlIGRpc2FzdGVyCiByZWNvdmVyeS4KCgoKAwQAARIDHAgdCjwKBAQABAASBB4CLQMa
LiBUaGUgc2V2ZXJpdHkgb2YgdGhlIGRpc2FzdGVyIHJlY292ZXJ5IGV2ZW50LgoKDAoFBAAE
AAESAx4HDwodCgYEAAQAAgASAyAEHRoOIFVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDIAQY
Cg4KBwQABAACAAISAyAbHApVCgYEAAQAAgESAyMEGBpGIFRoZSBDb21wdXRlIEVuZ2luZSBy
ZXNvdXJjZSBpcyBicm9rZW4uIEEgcGVyc29uIG11c3QgdGFrZSBhbiBhY3Rpb24uCgoOCgcE
AAQAAgEBEgMjBBMKDgoHBAAEAAIBAhIDIxYXCsQBCgYEAAQAAgISAygEGRq0ASBUaGUgQ29t
cHV0ZSBFbmdpbmUgcmVzb3VyY2UgaXMgZnVuY3Rpb25pbmcuIEEgY2hhbmdlIHdhcyBhcHBs
aWVkIHRvIHRoZQogcmVzb3VyY2UgZHVyaW5nIGRpc2FzdGVyIHJlY292ZXJ5LiBQbGVhc2Ug
dGFrZSBhY3Rpb24gdG8gcmV2aWV3CiB0aGUgY2hhbmdlIHRvIGF2b2lkIHVuZXhwZWN0ZWQg
cHJvYmxlbXMuCgoOCgcEAAQAAgIBEgMoBBQKDgoHBAAEAAICAhIDKBcYCmYKBgQABAACAxID
LAQPGlcgTm9ybWFsIG1haW50ZW5hbmNlIG9wZWFydGlvbnMgZHVyaW5nIGRpc2FzdGVyIHJl
Y292ZXJ5LCBzdWNoIGFzIHN0YXJ0IHVwLAogc2h1dCBkb3duLgoKDgoHBAAEAAIDARIDLAQK
Cg4KBwQABAACAwISAywNDgoiCgQEAAIAEgMwAiEaFSBUaGUgc2V2ZXJpdHkgbGV2ZWwuCgoM
CgUEAAIABBIDMAIKCgwKBQQAAgAGEgMwCxMKDAoFBAACAAESAzAUHAoMCgUEAAIAAxIDMB8g
CoUBCgQEAAIBEgM0Ah4aeCBEZXRhaWxzIGFib3V0IHRoZSBpbXBhY3Qgb24gdGhlIENvbXB1
dGUgRW5naW5lIHJlc291cmNlLCBlLmcuICJ0aGUgcmVzb3VyY2UKIGlzIGRlbGV0ZWQgZHVy
aW5nIHRoZSBkaXNhc3RlciByZWNvdmVyeSIuCgoMCgUEAAIBBBIDNAIKCgwKBQQAAgEFEgM0
CxEKDAoFBAACAQESAzQSGQoMCgUEAAIBAxIDNBwdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent ===
    # Fields for DisasterRecoveryEvent
    # Field: severity Type: 14 (.google.compute.logging.dr.v1.DisasterRecoveryEvent.Severity)
    # Field: details Type: 9 ()

# Enum: DisasterRecoveryEvent::Severity
our $DisasterRecoveryEvent_SEVERITY_UNSPECIFIED = 0;
our $DisasterRecoveryEvent_ACTION_REQUIRED = 1;
our $DisasterRecoveryEvent_ACTION_SUGGESTED = 2;
our $DisasterRecoveryEvent_NOTICE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent - Compiled Protocol Buffers messages for google/compute/logging/dr/v1/disaster_recovery_event.proto

=head1 SYNOPSIS

    use Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent;

    my $msg = Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent->new({
        severity => $severity,
        details => $details,
    });

    # Read or update a field
    my $val = $msg->severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/compute/logging/dr/v1/disaster_recovery_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::DisasterRecoveryEvent

An event signifying a Compute Engine resource is impacted by the disaster
recovery.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::Severity>)

The severity level.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<String>

Details about the impact on the Compute Engine resource, e.g. "the resource
is deleted during the disaster recovery".

=back

=head3 Enum: DisasterRecoveryEvent::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<ACTION_REQUIRED> => C<1>

=item * C<ACTION_SUGGESTED> => C<2>

=item * C<NOTICE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Compute::Logging::Dr::V1::DisasterRecoveryEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
