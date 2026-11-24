package Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions;

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
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvcGFydG5lcl9wZXJtaXNz
aW9ucy5wcm90bxIkZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Is8EChJQYXJ0bmVyUGVybWlzc2lvbnMSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEnQKE3Bh
cnRuZXJfcGVybWlzc2lvbnMYAiADKA4yQy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3Bh
cnRuZXIudjEuUGFydG5lclBlcm1pc3Npb25zLlBlcm1pc3Npb25SEnBhcnRuZXJQZXJtaXNz
aW9ucyL6AQoKUGVybWlzc2lvbhIaChZQRVJNSVNTSU9OX1VOU1BFQ0lGSUVEEAASMQotQUND
RVNTX1RSQU5TUEFSRU5DWV9BTkRfRU1FUkdFTkNZX0FDQ0VTU19MT0dTEAESIAocQVNTVVJF
RF9XT1JLTE9BRFNfTU9OSVRPUklORxACEhwKGEFDQ0VTU19BUFBST1ZBTF9SRVFVRVNUUxAD
EisKJ0FTU1VSRURfV09SS0xPQURTX0VLTV9DT05ORUNUSU9OX1NUQVRVUxAEEjAKLEFDQ0VT
U19UUkFOU1BBUkVOQ1lfTE9HU19TVVBQT1JUX0NBU0VfVklFV0VSEAU6rAHqQagBCjZjbG91
ZGNvbnRyb2xzcGFydG5lci5nb29nbGVhcGlzLmNvbS9QYXJ0bmVyUGVybWlzc2lvbnMSbm9y
Z2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY3VzdG9t
ZXJzL3tjdXN0b21lcn0vd29ya2xvYWRzL3t3b3JrbG9hZH0vcGFydG5lclBlcm1pc3Npb25z
InIKHEdldFBhcnRuZXJQZXJtaXNzaW9uc1JlcXVlc3QSUgoEbmFtZRgBIAEoCUI+4EEC+kE4
CjZjbG91ZGNvbnRyb2xzcGFydG5lci5nb29nbGVhcGlzLmNvbS9QYXJ0bmVyUGVybWlzc2lv
bnNSBG5hbWVCmwIKKGNvbS5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjFC
F1BhcnRuZXJQZXJtaXNzaW9uc1Byb3RvUAFaXGNsb3VkLmdvb2dsZS5jb20vZ28vY2xvdWRj
b250cm9sc3BhcnRuZXIvYXBpdjEvY2xvdWRjb250cm9sc3BhcnRuZXJwYjtjbG91ZGNvbnRy
b2xzcGFydG5lcnBiqgIkR29vZ2xlLkNsb3VkLkNsb3VkQ29udHJvbHNQYXJ0bmVyLlYxygIk
R29vZ2xlXENsb3VkXENsb3VkQ29udHJvbHNQYXJ0bmVyXFYx6gInR29vZ2xlOjpDbG91ZDo6
Q2xvdWRDb250cm9sc1BhcnRuZXI6OlYxSq4RCgYSBA4ASgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgS
AxUAQQoJCgIIJRIDFQBBCggKAQgSAxYAcwoJCgIICxIDFgBzCggKAQgSAxcAIgoJCgIIChID
FwAiCggKAQgSAxgAOAoJCgIICBIDGAA4CggKAQgSAxkAQQoJCgIIARIDGQBBCggKAQgSAxoA
QQoJCgIIKRIDGgBBCggKAQgSAxsAQAoJCgIILRIDGwBACkMKAgQAEgQeAD4BGjcgVGhlIHBl
cm1pc3Npb25zIGdyYW50ZWQgdG8gdGhlIHBhcnRuZXIgZm9yIGEgd29ya2xvYWQKCgoKAwQA
ARIDHggaCgsKAwQABxIEHwIiBAoNCgUEAAedCBIEHwIiBAoMCgQEAAQAEgQkAjYDCgwKBQQA
BAABEgMkBxEKLwoGBAAEAAIAEgMmBB8aICBVbnNwZWNpZmllZCBwYXJ0bmVyIHBlcm1pc3Np
b24KCg4KBwQABAACAAESAyYEGgoOCgcEAAQAAgACEgMmHR4KRgoGBAAEAAIBEgMpBDYaNyBQ
ZXJtaXNzaW9uIGZvciBBY2Nlc3MgVHJhbnNwYXJlbmN5IGFuZCBlbWVyZ2VuY3kgbG9ncwoK
DgoHBAAEAAIBARIDKQQxCg4KBwQABAACAQISAyk0NQpHCgYEAAQAAgISAywEJRo4IFBlcm1p
c3Npb24gZm9yIEFzc3VyZWQgV29ya2xvYWRzIG1vbml0b3JpbmcgdmlvbGF0aW9ucwoKDgoH
BAAEAAICARIDLAQgCg4KBwQABAACAgISAywjJAo4CgYEAAQAAgMSAy8EIRopIFBlcm1pc3Np
b24gZm9yIEFjY2VzcyBBcHByb3ZhbCByZXF1ZXN0cwoKDgoHBAAEAAIDARIDLwQcCg4KBwQA
BAACAwISAy8fIApGCgYEAAQAAgQSAzIEMBo3IFBlcm1pc3Npb24gZm9yIEV4dGVybmFsIEtl
eSBNYW5hZ2VyIGNvbm5lY3Rpb24gc3RhdHVzCgoOCgcEAAQAAgQBEgMyBCsKDgoHBAAEAAIE
AhIDMi4vClgKBgQABAACBRIDNQQ1GkkgUGVybWlzc2lvbiBmb3Igc3VwcG9ydCBjYXNlIGRl
dGFpbHMgZm9yIEFjY2VzcyBUcmFuc3BhcmVuY3kgbG9nIGVudHJpZXMKCg4KBwQABAACBQES
AzUEMAoOCgcEAAQAAgUCEgM1MzQKlQEKBAQAAgASAzoCPRqHASBJZGVudGlmaWVyLiBGb3Jt
YXQ6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jdXN0b21lcnMve2N1c3RvbWVyfS93b3JrbG9hZHMve3dvcmtsb2FkfS9wYXJ0bmVyUGVy
bWlzc2lvbnNgCgoMCgUEAAIABRIDOgIICgwKBQQAAgABEgM6CQ0KDAoFBAACAAMSAzoQEQoM
CgUEAAIACBIDOhI8Cg8KCAQAAgAInAgAEgM6EzsKPwoEBAACARIDPQIuGjIgVGhlIHBhcnRu
ZXIgcGVybWlzc2lvbnMgZ3JhbnRlZCBmb3IgdGhlIHdvcmtsb2FkCgoMCgUEAAIBBBIDPQIK
CgwKBQQAAgEGEgM9CxUKDAoFBAACAQESAz0WKQoMCgUEAAIBAxIDPSwtClAKAgQBEgRBAEoB
GkQgUmVxdWVzdCBmb3IgZ2V0dGluZyB0aGUgcGFydG5lciBwZXJtaXNzaW9ucyBncmFudGVk
IGZvciBhIHdvcmtsb2FkCgoKCgMEAQESA0EIJAq3AQoEBAECABIERAJJBBqoASBSZXF1aXJl
ZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UgdG8gZ2V0IGluIHRoZSBmb3JtYXQ6CiBgb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jdXN0b21lcnMv
e2N1c3RvbWVyfS93b3JrbG9hZHMve3dvcmtsb2FkfS9wYXJ0bmVyUGVybWlzc2lvbnNgCgoM
CgUEAQIABRIDRAIICgwKBQQBAgABEgNECQ0KDAoFBAECAAMSA0QQEQoNCgUEAQIACBIERBJJ
AwoPCggEAQIACJwIABIDRQQqCg8KBwQBAgAInwgSBEYESAViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions ===
    # Fields for PartnerPermissions
    # Field: name Type: 9 ()
    # Field: partner_permissions Type: 14 (.google.cloud.cloudcontrolspartner.v1.PartnerPermissions.Permission)

# Enum: PartnerPermissions::Permission
our $PartnerPermissions_PERMISSION_UNSPECIFIED = 0;
our $PartnerPermissions_ACCESS_TRANSPARENCY_AND_EMERGENCY_ACCESS_LOGS = 1;
our $PartnerPermissions_ASSURED_WORKLOADS_MONITORING = 2;
our $PartnerPermissions_ACCESS_APPROVAL_REQUESTS = 3;
our $PartnerPermissions_ASSURED_WORKLOADS_EKM_CONNECTION_STATUS = 4;
our $PartnerPermissions_ACCESS_TRANSPARENCY_LOGS_SUPPORT_CASE_VIEWER = 5;

# === Message: Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::GetPartnerPermissionsRequest ===
    # Fields for GetPartnerPermissionsRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/partner_permissions.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions->new({
        name => $name,
        partner_permissions => $partner_permissions,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/partner_permissions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions

The permissions granted to the partner for a workload

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/partnerPermissions`

=item * C<< $msg->partner_permissions() >> / C<< $msg->partner_permissions($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::Permission>)

The partner permissions granted for the workload

=back

=head3 Enum: PartnerPermissions::Permission

=over 4

=item * C<PERMISSION_UNSPECIFIED> => C<0>

=item * C<ACCESS_TRANSPARENCY_AND_EMERGENCY_ACCESS_LOGS> => C<1>

=item * C<ASSURED_WORKLOADS_MONITORING> => C<2>

=item * C<ACCESS_APPROVAL_REQUESTS> => C<3>

=item * C<ASSURED_WORKLOADS_EKM_CONNECTION_STATUS> => C<4>

=item * C<ACCESS_TRANSPARENCY_LOGS_SUPPORT_CASE_VIEWER> => C<5>

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::GetPartnerPermissionsRequest

Request for getting the partner permissions granted for a workload

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource to get in the format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/partnerPermissions`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
