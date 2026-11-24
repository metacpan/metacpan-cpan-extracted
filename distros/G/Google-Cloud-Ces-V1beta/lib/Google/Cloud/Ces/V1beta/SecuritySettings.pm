package Google::Cloud::Ces::V1beta::SecuritySettings;

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
Ci9nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9zZWN1cml0eV9zZXR0aW5ncy5wcm90bxIXZ29v
Z2xlLmNsb3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8ivwMKEFNlY3VyaXR5U2V0dGluZ3MSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEmsK
F2VuZHBvaW50X2NvbnRyb2xfcG9saWN5GAIgASgLMi4uZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuRW5kcG9pbnRDb250cm9sUG9saWN5QgPgQQFSFWVuZHBvaW50Q29udHJvbFBvbGljeRJA
CgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKdXBkYXRlVGltZRIXCgRldGFnGAUgASgJQgPgQQNSBGV0YWc6hwHqQYMB
CiNjZXMuZ29vZ2xlYXBpcy5jb20vU2VjdXJpdHlTZXR0aW5ncxI4cHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NlY3VyaXR5U2V0dGluZ3MqEHNlY3VyaXR5U2V0
dGluZ3MyEHNlY3VyaXR5U2V0dGluZ3MiiwIKFUVuZHBvaW50Q29udHJvbFBvbGljeRJxChFl
bmZvcmNlbWVudF9zY29wZRgBIAEoDjI/Lmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkVuZHBv
aW50Q29udHJvbFBvbGljeS5FbmZvcmNlbWVudFNjb3BlQgPgQQFSEGVuZm9yY2VtZW50U2Nv
cGUSLAoPYWxsb3dlZF9vcmlnaW5zGAIgAygJQgPgQQFSDmFsbG93ZWRPcmlnaW5zIlEKEEVu
Zm9yY2VtZW50U2NvcGUSIQodRU5GT1JDRU1FTlRfU0NPUEVfVU5TUEVDSUZJRUQQABIOCgpW
UENTQ19PTkxZEAESCgoGQUxXQVlTEAJCZQobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
QhVTZWN1cml0eVNldHRpbmdzUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBp
djFiZXRhL2Nlc3BiO2Nlc3BiSoUWCgYSBA4AVAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkK
CAoBCBIDFgBECgkKAggLEgMWAEQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA2CgkK
AggIEgMYADYKCAoBCBIDGQA0CgkKAggBEgMZADQKPwoCBAASBBwANgEaMyBQcm9qZWN0L0xv
Y2F0aW9uIGxldmVsIHNlY3VyaXR5IHNldHRpbmdzIGZvciBDRVMuCgoKCgMEAAESAxwIGAoL
CgMEAAcSBB0CIgQKDQoFBAAHnQgSBB0CIgQKjwEKBAQAAgASAyYCPRqBASBJZGVudGlmaWVy
LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIHNlY3VyaXR5IHNldHRpbmdzLgogRm9y
bWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NlY3VyaXR5
U2V0dGluZ3NgCgoMCgUEAAIABRIDJgIICgwKBQQAAgABEgMmCQ0KDAoFBAACAAMSAyYQEQoM
CgUEAAIACBIDJhI8Cg8KCAQAAgAInAgAEgMmEzsKPAoEBAACARIEKQIqLxouIE9wdGlvbmFs
LiBFbmRwb2ludCBjb250cm9sIHJlbGF0ZWQgc2V0dGluZ3MuCgoMCgUEAAIBBhIDKQIXCgwK
BQQAAgEBEgMpGC8KDAoFBAACAQMSAykyMwoMCgUEAAIBCBIDKgYuCg8KCAQAAgEInAgAEgMq
By0KQgoEBAACAhIELQIuMho0IE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZSBvZiB0aGUgc2Vj
dXJpdHkgc2V0dGluZ3MuCgoMCgUEAAICBhIDLQIbCgwKBQQAAgIBEgMtHCcKDAoFBAACAgMS
Ay0qKwoMCgUEAAICCBIDLgYxCg8KCAQAAgIInAgAEgMuBzAKRwoEBAACAxIEMQIyMho5IE91
dHB1dCBvbmx5LiBMYXN0IHVwZGF0ZSB0aW1lIG9mIHRoZSBzZWN1cml0eSBzZXR0aW5ncy4K
CgwKBQQAAgMGEgMxAhsKDAoFBAACAwESAzEcJwoMCgUEAAIDAxIDMSorCgwKBQQAAgMIEgMy
BjEKDwoIBAACAwicCAASAzIHMAo6CgQEAAIEEgM1Aj4aLSBPdXRwdXQgb25seS4gRXRhZyBv
ZiB0aGUgc2VjdXJpdHkgc2V0dGluZ3MuCgoMCgUEAAIEBRIDNQIICgwKBQQAAgQBEgM1CQ0K
DAoFBAACBAMSAzUQEQoMCgUEAAIECBIDNRI9Cg8KCAQAAgQInAgAEgM1EzwKRQoCBAESBDkA
VAEaOSBEZWZpbmVzIHByb2plY3QvbG9jYXRpb24gbGV2ZWwgZW5kcG9pbnQgY29udHJvbCBw
b2xpY3kuCgoKCgMEAQESAzkIHQpbCgQEAQQAEgQ8AkUDGk0gRGVmaW5lcyB0aGUgc2NvcGUg
aW4gd2hpY2ggdGhpcyBwb2xpY3kncyBhbGxvd2VkX29yaWdpbnMgbGlzdCBpcwogZW5mb3Jj
ZWQuCgoMCgUEAQQAARIDPAcXCkgKBgQBBAACABIDPgQmGjkgVW5zcGVjaWZpZWQuIFRoaXMg
cG9saWN5IHdpbGwgYmUgdHJlYXRlZCBhcyBWUENTQ19PTkxZLgoKDgoHBAEEAAIAARIDPgQh
Cg4KBwQBBAACAAISAz4kJQpACgYEAQQAAgESA0EEExoxIFRoaXMgcG9saWN5IGFwcGxpZXMg
b25seSB3aGVuIFZQQy1TQyBpcyBhY3RpdmUuCgoOCgcEAQQAAgEBEgNBBA4KDgoHBAEEAAIB
AhIDQRESCkkKBgQBBAACAhIDRAQPGjogVGhpcyBwb2xpY3kgQUxXQVlTIGFwcGxpZXMsIHJl
Z2FyZGxlc3Mgb2YgVlBDLVNDIHN0YXR1cy4KCg4KBwQBBAACAgESA0QECgoOCgcEAQQAAgIC
EgNEDQ4KXQoEBAECABIESQJKLxpPIE9wdGlvbmFsLiBUaGUgc2NvcGUgaW4gd2hpY2ggdGhp
cyBwb2xpY3kncyBhbGxvd2VkX29yaWdpbnMgbGlzdCBpcwogZW5mb3JjZWQuCgoMCgUEAQIA
BhIDSQISCgwKBQQBAgABEgNJEyQKDAoFBAECAAMSA0knKAoMCgUEAQIACBIDSgYuCg8KCAQB
AgAInAgAEgNKBy0K2QMKBAQBAgESA1MCTxrLAyBPcHRpb25hbC4gVGhlIGFsbG93ZWQgSFRU
UChzKSBvcmlnaW5zIHRoYXQgdG9vbHMgaW4gdGhlIEFwcCBhcmUgYWJsZSB0bwogZGlyZWN0
bHkgY2FsbC4gVGhlIGVuZm9yY2VtZW50IGRlcGVuZHMgb24gdGhlIHZhbHVlIG9mCiBlbmZv
cmNlbWVudF9zY29wZSBhbmQgdGhlIFZQQy1TQyBzdGF0dXMgb2YgdGhlIHByb2plY3QuCiBJ
ZiBhIHBvcnQgbnVtYmVyIGlzIG5vdCBwcm92aWRlZCwgYWxsIHBvcnRzIHdpbGwgYmUgYWxs
b3dlZC4gT3RoZXJ3aXNlLAogdGhlIHBvcnQgbnVtYmVyIG11c3QgbWF0Y2ggZXhhY3RseS4g
Rm9yIGV4YW1wbGUsICJodHRwczovL2V4YW1wbGUuY29tIgogd2lsbCBtYXRjaCAiaHR0cHM6
Ly9leGFtcGxlLmNvbTo0NDMiIGFuZCBhbnkgb3RoZXIgcG9ydC4KICJodHRwczovL2V4YW1w
bGUuY29tOjQ0MyIgd2lsbCBvbmx5IG1hdGNoICJodHRwczovL2V4YW1wbGUuY29tOjQ0MyIu
CgoMCgUEAQIBBBIDUwIKCgwKBQQBAgEFEgNTCxEKDAoFBAECAQESA1MSIQoMCgUEAQIBAxID
UyQlCgwKBQQBAgEIEgNTJk4KDwoIBAECAQicCAASA1MnTWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::SecuritySettings::SecuritySettings ===
    # Fields for SecuritySettings
    # Field: name Type: 9 ()
    # Field: endpoint_control_policy Type: 11 (.google.cloud.ces.v1beta.EndpointControlPolicy)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::SecuritySettings::EndpointControlPolicy ===
    # Fields for EndpointControlPolicy
    # Field: enforcement_scope Type: 14 (.google.cloud.ces.v1beta.EndpointControlPolicy.EnforcementScope)
    # Field: allowed_origins Type: 9 ()

# Enum: EndpointControlPolicy::EnforcementScope
our $EndpointControlPolicy_ENFORCEMENT_SCOPE_UNSPECIFIED = 0;
our $EndpointControlPolicy_VPCSC_ONLY = 1;
our $EndpointControlPolicy_ALWAYS = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::SecuritySettings - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/security_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::SecuritySettings;

    my $msg = Google::Cloud::Ces::V1beta::SecuritySettings::SecuritySettings->new({
        name => $name,
        endpoint_control_policy => $endpoint_control_policy,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::SecuritySettings::SecuritySettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/security_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::SecuritySettings::SecuritySettings

Project/Location level security settings for CES.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the security settings.
Format: `projects/{project}/locations/{location}/securitySettings`

=item * C<< $msg->endpoint_control_policy() >> / C<< $msg->endpoint_control_policy($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::SecuritySettings::EndpointControlPolicy>)

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

=head2 Google::Cloud::Ces::V1beta::SecuritySettings::EndpointControlPolicy

Defines project/location level endpoint control policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enforcement_scope() >> / C<< $msg->enforcement_scope($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::EndpointControlPolicy::EnforcementScope>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::SecuritySettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
