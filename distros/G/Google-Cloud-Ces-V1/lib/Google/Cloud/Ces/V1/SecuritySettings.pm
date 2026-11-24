package Google::Cloud::Ces::V1::SecuritySettings;

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
Citnb29nbGUvY2xvdWQvY2VzL3YxL3NlY3VyaXR5X3NldHRpbmdzLnByb3RvEhNnb29nbGUu
Y2xvdWQuY2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrsD
ChBTZWN1cml0eVNldHRpbmdzEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJnChdlbmRwb2lu
dF9jb250cm9sX3BvbGljeRgCIAEoCzIqLmdvb2dsZS5jbG91ZC5jZXMudjEuRW5kcG9pbnRD
b250cm9sUG9saWN5QgPgQQFSFWVuZHBvaW50Q29udHJvbFBvbGljeRJACgtjcmVhdGVfdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJA
Cgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
dXBkYXRlVGltZRIXCgRldGFnGAUgASgJQgPgQQNSBGV0YWc6hwHqQYMBCiNjZXMuZ29vZ2xl
YXBpcy5jb20vU2VjdXJpdHlTZXR0aW5ncxI4cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L3NlY3VyaXR5U2V0dGluZ3MqEHNlY3VyaXR5U2V0dGluZ3MyEHNlY3Vy
aXR5U2V0dGluZ3MihwIKFUVuZHBvaW50Q29udHJvbFBvbGljeRJtChFlbmZvcmNlbWVudF9z
Y29wZRgBIAEoDjI7Lmdvb2dsZS5jbG91ZC5jZXMudjEuRW5kcG9pbnRDb250cm9sUG9saWN5
LkVuZm9yY2VtZW50U2NvcGVCA+BBAVIQZW5mb3JjZW1lbnRTY29wZRIsCg9hbGxvd2VkX29y
aWdpbnMYAiADKAlCA+BBAVIOYWxsb3dlZE9yaWdpbnMiUQoQRW5mb3JjZW1lbnRTY29wZRIh
Ch1FTkZPUkNFTUVOVF9TQ09QRV9VTlNQRUNJRklFRBAAEg4KClZQQ1NDX09OTFkQARIKCgZB
TFdBWVMQAkJdChdjb20uZ29vZ2xlLmNsb3VkLmNlcy52MUIVU2VjdXJpdHlTZXR0aW5nc1By
b3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSoUWCgYS
BA4AVAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoC
AwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBACgkKAggLEgMWAEAKCAoB
CBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA2CgkKAggIEgMYADYKCAoBCBIDGQAwCgkKAggB
EgMZADAKPwoCBAASBBwANgEaMyBQcm9qZWN0L0xvY2F0aW9uIGxldmVsIHNlY3VyaXR5IHNl
dHRpbmdzIGZvciBDRVMuCgoKCgMEAAESAxwIGAoLCgMEAAcSBB0CIgQKDQoFBAAHnQgSBB0C
IgQKjwEKBAQAAgASAyYCPRqBASBJZGVudGlmaWVyLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIg
b2YgdGhlIHNlY3VyaXR5IHNldHRpbmdzLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L3NlY3VyaXR5U2V0dGluZ3NgCgoMCgUEAAIABRIDJgII
CgwKBQQAAgABEgMmCQ0KDAoFBAACAAMSAyYQEQoMCgUEAAIACBIDJhI8Cg8KCAQAAgAInAgA
EgMmEzsKPAoEBAACARIEKQIqLxouIE9wdGlvbmFsLiBFbmRwb2ludCBjb250cm9sIHJlbGF0
ZWQgc2V0dGluZ3MuCgoMCgUEAAIBBhIDKQIXCgwKBQQAAgEBEgMpGC8KDAoFBAACAQMSAyky
MwoMCgUEAAIBCBIDKgYuCg8KCAQAAgEInAgAEgMqBy0KQgoEBAACAhIELQIuMho0IE91dHB1
dCBvbmx5LiBDcmVhdGUgdGltZSBvZiB0aGUgc2VjdXJpdHkgc2V0dGluZ3MuCgoMCgUEAAIC
BhIDLQIbCgwKBQQAAgIBEgMtHCcKDAoFBAACAgMSAy0qKwoMCgUEAAICCBIDLgYxCg8KCAQA
AgIInAgAEgMuBzAKRwoEBAACAxIEMQIyMho5IE91dHB1dCBvbmx5LiBMYXN0IHVwZGF0ZSB0
aW1lIG9mIHRoZSBzZWN1cml0eSBzZXR0aW5ncy4KCgwKBQQAAgMGEgMxAhsKDAoFBAACAwES
AzEcJwoMCgUEAAIDAxIDMSorCgwKBQQAAgMIEgMyBjEKDwoIBAACAwicCAASAzIHMAo6CgQE
AAIEEgM1Aj4aLSBPdXRwdXQgb25seS4gRXRhZyBvZiB0aGUgc2VjdXJpdHkgc2V0dGluZ3Mu
CgoMCgUEAAIEBRIDNQIICgwKBQQAAgQBEgM1CQ0KDAoFBAACBAMSAzUQEQoMCgUEAAIECBID
NRI9Cg8KCAQAAgQInAgAEgM1EzwKRQoCBAESBDkAVAEaOSBEZWZpbmVzIHByb2plY3QvbG9j
YXRpb24gbGV2ZWwgZW5kcG9pbnQgY29udHJvbCBwb2xpY3kuCgoKCgMEAQESAzkIHQpbCgQE
AQQAEgQ8AkUDGk0gRGVmaW5lcyB0aGUgc2NvcGUgaW4gd2hpY2ggdGhpcyBwb2xpY3kncyBh
bGxvd2VkX29yaWdpbnMgbGlzdCBpcwogZW5mb3JjZWQuCgoMCgUEAQQAARIDPAcXCkgKBgQB
BAACABIDPgQmGjkgVW5zcGVjaWZpZWQuIFRoaXMgcG9saWN5IHdpbGwgYmUgdHJlYXRlZCBh
cyBWUENTQ19PTkxZLgoKDgoHBAEEAAIAARIDPgQhCg4KBwQBBAACAAISAz4kJQpACgYEAQQA
AgESA0EEExoxIFRoaXMgcG9saWN5IGFwcGxpZXMgb25seSB3aGVuIFZQQy1TQyBpcyBhY3Rp
dmUuCgoOCgcEAQQAAgEBEgNBBA4KDgoHBAEEAAIBAhIDQRESCkkKBgQBBAACAhIDRAQPGjog
VGhpcyBwb2xpY3kgQUxXQVlTIGFwcGxpZXMsIHJlZ2FyZGxlc3Mgb2YgVlBDLVNDIHN0YXR1
cy4KCg4KBwQBBAACAgESA0QECgoOCgcEAQQAAgICEgNEDQ4KXQoEBAECABIESQJKLxpPIE9w
dGlvbmFsLiBUaGUgc2NvcGUgaW4gd2hpY2ggdGhpcyBwb2xpY3kncyBhbGxvd2VkX29yaWdp
bnMgbGlzdCBpcwogZW5mb3JjZWQuCgoMCgUEAQIABhIDSQISCgwKBQQBAgABEgNJEyQKDAoF
BAECAAMSA0knKAoMCgUEAQIACBIDSgYuCg8KCAQBAgAInAgAEgNKBy0K2QMKBAQBAgESA1MC
TxrLAyBPcHRpb25hbC4gVGhlIGFsbG93ZWQgSFRUUChzKSBvcmlnaW5zIHRoYXQgdG9vbHMg
aW4gdGhlIEFwcCBhcmUgYWJsZSB0bwogZGlyZWN0bHkgY2FsbC4gVGhlIGVuZm9yY2VtZW50
IGRlcGVuZHMgb24gdGhlIHZhbHVlIG9mCiBlbmZvcmNlbWVudF9zY29wZSBhbmQgdGhlIFZQ
Qy1TQyBzdGF0dXMgb2YgdGhlIHByb2plY3QuCiBJZiBhIHBvcnQgbnVtYmVyIGlzIG5vdCBw
cm92aWRlZCwgYWxsIHBvcnRzIHdpbGwgYmUgYWxsb3dlZC4gT3RoZXJ3aXNlLAogdGhlIHBv
cnQgbnVtYmVyIG11c3QgbWF0Y2ggZXhhY3RseS4gRm9yIGV4YW1wbGUsICJodHRwczovL2V4
YW1wbGUuY29tIgogd2lsbCBtYXRjaCAiaHR0cHM6Ly9leGFtcGxlLmNvbTo0NDMiIGFuZCBh
bnkgb3RoZXIgcG9ydC4KICJodHRwczovL2V4YW1wbGUuY29tOjQ0MyIgd2lsbCBvbmx5IG1h
dGNoICJodHRwczovL2V4YW1wbGUuY29tOjQ0MyIuCgoMCgUEAQIBBBIDUwIKCgwKBQQBAgEF
EgNTCxEKDAoFBAECAQESA1MSIQoMCgUEAQIBAxIDUyQlCgwKBQQBAgEIEgNTJk4KDwoIBAEC
AQicCAASA1MnTWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings ===
    # Fields for SecuritySettings
    # Field: name Type: 9 ()
    # Field: endpoint_control_policy Type: 11 (.google.cloud.ces.v1.EndpointControlPolicy)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Ces::V1::SecuritySettings::EndpointControlPolicy ===
    # Fields for EndpointControlPolicy
    # Field: enforcement_scope Type: 14 (.google.cloud.ces.v1.EndpointControlPolicy.EnforcementScope)
    # Field: allowed_origins Type: 9 ()

# Enum: EndpointControlPolicy::EnforcementScope
our $EndpointControlPolicy_ENFORCEMENT_SCOPE_UNSPECIFIED = 0;
our $EndpointControlPolicy_VPCSC_ONLY = 1;
our $EndpointControlPolicy_ALWAYS = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::SecuritySettings - Compiled Protocol Buffers messages for google/cloud/ces/v1/security_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::SecuritySettings;

    my $msg = Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings->new({
        name => $name,
        endpoint_control_policy => $endpoint_control_policy,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/security_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings

Project/Location level security settings for CES.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the security settings.
Format: `projects/{project}/locations/{location}/securitySettings`

=item * C<< $msg->endpoint_control_policy() >> / C<< $msg->endpoint_control_policy($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::SecuritySettings::EndpointControlPolicy>)

Optional. Endpoint control related settings.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the security settings.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Last update time of the security settings.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. Etag of the security settings.

=back

=head2 Google::Cloud::Ces::V1::SecuritySettings::EndpointControlPolicy

Defines project/location level endpoint control policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enforcement_scope() >> / C<< $msg->enforcement_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::EndpointControlPolicy::EnforcementScope>)

Optional. The scope in which this policy's allowed_origins list is
enforced.

=item * C<< $msg->allowed_origins() >> / C<< $msg->allowed_origins($value) >>

Type: C<String>

Optional. The allowed HTTP(s) origins that tools in the App are able to
directly call. The enforcement depends on the value of
enforcement_scope and the VPC-SC status of the project.
If a port number is not provided, all ports will be allowed. Otherwise,
the port number must match exactly. For example, "https://example.com"
will match "https://example.com:443" and any other port.
"https://example.com:443" will only match "https://example.com:443".

=back

=head3 Enum: EndpointControlPolicy::EnforcementScope

=over 4

=item * C<ENFORCEMENT_SCOPE_UNSPECIFIED> => C<0>

=item * C<VPCSC_ONLY> => C<1>

=item * C<ALWAYS> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::SecuritySettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
