package Google::Actions::Sdk::V2::Surface;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvYWN0aW9ucy9zZGsvdjIvc3VyZmFjZS5wcm90bxIVZ29vZ2xlLmFjdGlvbnMu
c2RrLnYyInYKE1N1cmZhY2VSZXF1aXJlbWVudHMSXwoUbWluaW11bV9yZXF1aXJlbWVudHMY
ASADKAsyLC5nb29nbGUuYWN0aW9ucy5zZGsudjIuQ2FwYWJpbGl0eVJlcXVpcmVtZW50UhNt
aW5pbXVtUmVxdWlyZW1lbnRzIsACChVDYXBhYmlsaXR5UmVxdWlyZW1lbnQSXgoKY2FwYWJp
bGl0eRgBIAEoDjI+Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5DYXBhYmlsaXR5UmVxdWlyZW1l
bnQuU3VyZmFjZUNhcGFiaWxpdHlSCmNhcGFiaWxpdHkixgEKEVN1cmZhY2VDYXBhYmlsaXR5
EiIKHlNVUkZBQ0VfQ0FQQUJJTElUWV9VTlNQRUNJRklFRBAAEhAKDEFVRElPX09VVFBVVBAB
EhEKDVNDUkVFTl9PVVRQVVQQAhIYChRNRURJQV9SRVNQT05TRV9BVURJTxADEg8KC1dFQl9C
Uk9XU0VSEAQSEwoPQUNDT1VOVF9MSU5LSU5HEAcSFgoSSU5URVJBQ1RJVkVfQ0FOVkFTEAgS
EAoMSE9NRV9TVE9SQUdFEAlCZQoZY29tLmdvb2dsZS5hY3Rpb25zLnNkay52MkIMU3VyZmFj
ZVByb3RvUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9u
cy9zZGsvdjI7c2RrSp4PCgYSBA4APwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQAB4KCAoBCBIDEgBPCgkKAggLEgMSAE8KCAoBCBIDEwAiCgkKAggKEgMT
ACIKCAoBCBIDFAAtCgkKAggIEgMUAC0KCAoBCBIDFQAyCgkKAggBEgMVADIKdQoCBAASBBkA
HgEaaSBDb250YWlucyBhIHNldCBvZiByZXF1aXJlbWVudHMgdGhhdCB0aGUgY2xpZW50IHN1
cmZhY2UgbXVzdCBzdXBwb3J0IHRvIGludm9rZQogQWN0aW9ucyBpbiB5b3VyIHByb2plY3Qu
CgoKCgMEAAESAxkIGwqpAQoEBAACABIDHQI6GpsBIFRoZSBtaW5pbXVtIHNldCBvZiBjYXBh
YmlsaXRpZXMgbmVlZGVkIHRvIGludm9rZSB0aGUgQWN0aW9ucyBpbiB5b3VyCiBwcm9qZWN0
LiBJZiB0aGUgc3VyZmFjZSBpcyBtaXNzaW5nIGFueSBvZiB0aGVzZSwgdGhlIEFjdGlvbiB3
aWxsIG5vdCBiZQogdHJpZ2dlcmVkLgoKDAoFBAACAAQSAx0CCgoMCgUEAAIABhIDHQsgCgwK
BQQAAgABEgMdITUKDAoFBAACAAMSAx04OQpUCgIEARIEIQA/ARpIIFJlcHJlc2VudHMgYSBy
ZXF1aXJlbWVudCBhYm91dCB0aGUgYXZhaWxhYmlsaXR5IG9mIGEgZ2l2ZW4gY2FwYWJpbGl0
eS4KCgoKAwQBARIDIQgdCjUKBAQBBAASBCMCOwMaJyBQb3NzaWJsZSBzZXQgb2Ygc3VyZmFj
ZSBjYXBhYmlsaXRpZXMuCgoMCgUEAQQAARIDIwcYCicKBgQBBAACABIDJQQnGhggVW5rbm93
biAvIFVuc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDJQQiCg4KBwQBBAACAAISAyUlJgovCgYE
AQQAAgESAygEFRogIFN1cmZhY2Ugc3VwcG9ydHMgYXVkaW8gb3V0cHV0LgoKDgoHBAEEAAIB
ARIDKAQQCg4KBwQBBAACAQISAygTFAo3CgYEAQQAAgISAysEFhooIFN1cmZhY2Ugc3VwcG9y
dHMgc2NyZWVuL3Zpc3VhbCBvdXRwdXQuCgoOCgcEAQQAAgIBEgMrBBEKDgoHBAEEAAICAhID
KxQVCjcKBgQBBAACAxIDLgQdGiggU3VyZmFjZSBzdXBwb3J0cyBtZWRpYSByZXNwb25zZSBh
dWRpby4KCg4KBwQBBAACAwESAy4EGAoOCgcEAQQAAgMCEgMuGxwKLwoGBAEEAAIEEgMxBBQa
ICBTdXJmYWNlIHN1cHBvcnRzIHdlYiBicm93c2Vycy4KCg4KBwQBBAACBAESAzEEDwoOCgcE
AQQAAgQCEgMxEhMKMgoGBAEEAAIFEgM0BBgaIyBTdXJmYWNlIHN1cHBvcnRzIGFjY291bnQg
bGlua2luZy4KCg4KBwQBBAACBQESAzQEEwoOCgcEAQQAAgUCEgM0FhcKNQoGBAEEAAIGEgM3
BBsaJiBTdXJmYWNlIHN1cHBvcnRzIEludGVyYWN0aXZlIENhbnZhcy4KCg4KBwQBBAACBgES
AzcEFgoOCgcEAQQAAgYCEgM3GRoKLwoGBAEEAAIHEgM6BBUaICBTdXJmYWNlIHN1cHBvcnRz
IGhvbWUgc3RvcmFnZS4KCg4KBwQBBAACBwESAzoEEAoOCgcEAQQAAgcCEgM6ExQKJgoEBAEC
ABIDPgIjGhkgVGhlIHR5cGUgb2YgY2FwYWJpbGl0eS4KCgwKBQQBAgAGEgM+AhMKDAoFBAEC
AAESAz4UHgoMCgUEAQIAAxIDPiEiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Surface::SurfaceRequirements ===
    # Fields for SurfaceRequirements
    # Field: minimum_requirements Type: 11 (.google.actions.sdk.v2.CapabilityRequirement)

# === Message: Google::Actions::Sdk::V2::Surface::CapabilityRequirement ===
    # Fields for CapabilityRequirement
    # Field: capability Type: 14 (.google.actions.sdk.v2.CapabilityRequirement.SurfaceCapability)

# Enum: CapabilityRequirement::SurfaceCapability
our $CapabilityRequirement_SURFACE_CAPABILITY_UNSPECIFIED = 0;
our $CapabilityRequirement_AUDIO_OUTPUT = 1;
our $CapabilityRequirement_SCREEN_OUTPUT = 2;
our $CapabilityRequirement_MEDIA_RESPONSE_AUDIO = 3;
our $CapabilityRequirement_WEB_BROWSER = 4;
our $CapabilityRequirement_ACCOUNT_LINKING = 7;
our $CapabilityRequirement_INTERACTIVE_CANVAS = 8;
our $CapabilityRequirement_HOME_STORAGE = 9;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Surface - Compiled Protocol Buffers messages for google/actions/sdk/v2/surface.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Surface;

    my $msg = Google::Actions::Sdk::V2::Surface::SurfaceRequirements->new({
        minimum_requirements => $minimum_requirements,
    });

    # Read or update a field
    my $val = $msg->minimum_requirements();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Surface::SurfaceRequirements->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/surface.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Surface::SurfaceRequirements

Contains a set of requirements that the client surface must support to invoke
Actions in your project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->minimum_requirements() >> / C<< $msg->minimum_requirements($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Surface::CapabilityRequirement>)

The minimum set of capabilities needed to invoke the Actions in your
project. If the surface is missing any of these, the Action will not be
triggered.

=back

=head2 Google::Actions::Sdk::V2::Surface::CapabilityRequirement

Represents a requirement about the availability of a given capability.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->capability() >> / C<< $msg->capability($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::CapabilityRequirement::SurfaceCapability>)

The type of capability.

=back

=head3 Enum: CapabilityRequirement::SurfaceCapability

=over 4

=item * C<SURFACE_CAPABILITY_UNSPECIFIED> => C<0>

=item * C<AUDIO_OUTPUT> => C<1>

=item * C<SCREEN_OUTPUT> => C<2>

=item * C<MEDIA_RESPONSE_AUDIO> => C<3>

=item * C<WEB_BROWSER> => C<4>

=item * C<ACCOUNT_LINKING> => C<7>

=item * C<INTERACTIVE_CANVAS> => C<8>

=item * C<HOME_STORAGE> => C<9>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Surface::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
