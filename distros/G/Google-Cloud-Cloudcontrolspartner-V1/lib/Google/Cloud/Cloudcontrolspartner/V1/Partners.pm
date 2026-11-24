package Google::Cloud::Cloudcontrolspartner::V1::Partners;

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
CjNnb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvcGFydG5lcnMucHJvdG8S
JGdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byKXBAoHUGFydG5lchIXCgRuYW1lGAEgASgJQgPgQQhS
BG5hbWUSPQoEc2t1cxgDIAMoCzIpLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5l
ci52MS5Ta3VSBHNrdXMSVgoNZWttX3NvbHV0aW9ucxgEIAMoCzIxLmdvb2dsZS5jbG91ZC5j
bG91ZGNvbnRyb2xzcGFydG5lci52MS5Fa21NZXRhZGF0YVIMZWttU29sdXRpb25zEjQKFm9w
ZXJhdGVkX2Nsb3VkX3JlZ2lvbnMYBSADKAlSFG9wZXJhdGVkQ2xvdWRSZWdpb25zEiwKEnBh
cnRuZXJfcHJvamVjdF9pZBgHIAEoCVIQcGFydG5lclByb2plY3RJZBJACgtjcmVhdGVfdGlt
ZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJA
Cgt1cGRhdGVfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
dXBkYXRlVGltZTp06kFxCitjbG91ZGNvbnRyb2xzcGFydG5lci5nb29nbGVhcGlzLmNvbS9Q
YXJ0bmVyEjlvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRp
b259L3BhcnRuZXIyB3BhcnRuZXIiXAoRR2V0UGFydG5lclJlcXVlc3QSRwoEbmFtZRgBIAEo
CUIz4EEC+kEtCitjbG91ZGNvbnRyb2xzcGFydG5lci5nb29nbGVhcGlzLmNvbS9QYXJ0bmVy
UgRuYW1lIjgKA1NrdRIOCgJpZBgBIAEoCVICaWQSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtk
aXNwbGF5TmFtZSL9AQoLRWttTWV0YWRhdGESYAoMZWttX3NvbHV0aW9uGAEgASgOMj0uZ29v
Z2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLkVrbU1ldGFkYXRhLkVrbVNvbHV0
aW9uUgtla21Tb2x1dGlvbhIoChBla21fZW5kcG9pbnRfdXJpGAIgASgJUg5la21FbmRwb2lu
dFVyaSJiCgtFa21Tb2x1dGlvbhIcChhFS01fU09MVVRJT05fVU5TUEVDSUZJRUQQABIMCghG
T1JUQU5JWBABEgsKB0ZVVFVSRVgQAhIKCgZUSEFMRVMQAxIOCgZWSVJUUlUQBBoCCAFCkQIK
KGNvbS5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjFCDVBhcnRuZXJzUHJv
dG9QAVpcY2xvdWQuZ29vZ2xlLmNvbS9nby9jbG91ZGNvbnRyb2xzcGFydG5lci9hcGl2MS9j
bG91ZGNvbnRyb2xzcGFydG5lcnBiO2Nsb3VkY29udHJvbHNwYXJ0bmVycGKqAiRHb29nbGUu
Q2xvdWQuQ2xvdWRDb250cm9sc1BhcnRuZXIuVjHKAiRHb29nbGVcQ2xvdWRcQ2xvdWRDb250
cm9sc1BhcnRuZXJcVjHqAidHb29nbGU6OkNsb3VkOjpDbG91ZENvbnRyb2xzUGFydG5lcjo6
VjFK4B0KBhIEDgB4AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEEKCQoCCCUS
AxYAQQoICgEIEgMXAHMKCQoCCAsSAxcAcwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZ
AC4KCQoCCAgSAxkALgoICgEIEgMaAEEKCQoCCAESAxoAQQoICgEIEgMbAEEKCQoCCCkSAxsA
QQoICgEIEgMcAEAKCQoCCC0SAxwAQAoxCgIEABIEHwBBARolIE1lc3NhZ2UgZGVzY3JpYmlu
ZyBQYXJ0bmVyIHJlc291cmNlCgoKCgMEAAESAx8IDwoLCgMEAAcSBCACJAQKDQoFBAAHnQgS
BCACJAQKwQEKBAQAAgASAykCPRqzASBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgcGFydG5lci4KIEZvcm1hdDogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vcGFydG5lcmAKIEV4YW1wbGU6ICJvcmdhbml6YXRpb25z
LzEyMzQ1Ni9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcGFydG5lciIKCgwKBQQAAgAFEgMpAggK
DAoFBAACAAESAykJDQoMCgUEAAIAAxIDKRARCgwKBQQAAgAIEgMpEjwKDwoIBAACAAicCAAS
AykTOwozCgQEAAIBEgMsAhgaJiBMaXN0IG9mIFNLVXMgdGhlIHBhcnRuZXIgaXMgb2ZmZXJp
bmcKCgwKBQQAAgEEEgMsAgoKDAoFBAACAQYSAywLDgoMCgUEAAIBARIDLA8TCgwKBQQAAgED
EgMsFhcKUwoEBAACAhIDLwIpGkYgTGlzdCBvZiBHb29nbGUgQ2xvdWQgc3VwcG9ydGVkIEVL
TSBwYXJ0bmVycyBzdXBwb3J0ZWQgYnkgdGhlIHBhcnRuZXIKCgwKBQQAAgIEEgMvAgoKDAoF
BAACAgYSAy8LFgoMCgUEAAICARIDLxckCgwKBQQAAgIDEgMvJygKtwEKBAQAAgMSAzQCLRqp
ASBMaXN0IG9mIEdvb2dsZSBDbG91ZCByZWdpb25zIHRoYXQgdGhlIHBhcnRuZXIgc2VsbHMg
c2VydmljZXMgdG8gY3VzdG9tZXJzLgogVmFsaWQgR29vZ2xlIENsb3VkIHJlZ2lvbnMgZm91
bmQgaGVyZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3MvcmVnaW9u
cy16b25lcwoKDAoFBAACAwQSAzQCCgoMCgUEAAIDBRIDNAsRCgwKBQQAAgMBEgM0EigKDAoF
BAACAwMSAzQrLAp8CgQEAAIEEgM4AiAabyBHb29nbGUgQ2xvdWQgcHJvamVjdCBJRCBpbiB0
aGUgcGFydG5lcidzIEdvb2dsZSBDbG91ZCBvcmdhbml6YXRpb24gZm9yCiByZWNlaXZpbmcg
ZW5oYW5jZWQgTG9ncyBmb3IgUGFydG5lcnMuCgoMCgUEAAIEBRIDOAIICgwKBQQAAgQBEgM4
CRsKDAoFBAACBAMSAzgeHwo6CgQEAAIFEgQ7AjwyGiwgT3V0cHV0IG9ubHkuIFRpbWUgdGhl
IHJlc291cmNlIHdhcyBjcmVhdGVkCgoMCgUEAAIFBhIDOwIbCgwKBQQAAgUBEgM7HCcKDAoF
BAACBQMSAzsqKwoMCgUEAAIFCBIDPAYxCg8KCAQAAgUInAgAEgM8BzAKQwoEBAACBhIEPwJA
Mho1IE91dHB1dCBvbmx5LiBUaGUgbGFzdCB0aW1lIHRoZSByZXNvdXJjZSB3YXMgdXBkYXRl
ZAoKDAoFBAACBgYSAz8CGwoMCgUEAAIGARIDPxwnCgwKBQQAAgYDEgM/KiwKDAoFBAACBggS
A0AGMQoPCggEAAIGCJwIABIDQAcwCisKAgQBEgREAE0BGh8gTWVzc2FnZSBmb3IgZ2V0dGlu
ZyBhIFBhcnRuZXIKCgoKAwQBARIDRAgZCl4KBAQBAgASBEcCTAQaUCBSZXF1aXJlZC4gRm9y
bWF0OgogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcGFydG5lcmAKCgwKBQQBAgAFEgNHAggKDAoFBAECAAESA0cJDQoMCgUEAQIAAxIDRxAR
Cg0KBQQBAgAIEgRHEkwDCg8KCAQBAgAInAgAEgNIBCoKDwoHBAECAAifCBIESQRLBQpZCgIE
AhIEUABaARpNIFJlcHJlc2VudHMgdGhlIFNLVSBhIHBhcnRuZXIgb3ducyBpbnNpZGUgR29v
Z2xlIENsb3VkIHRvIHNlbGwgdG8gY3VzdG9tZXJzLgoKCgoDBAIBEgNQCAsKxgEKBAQCAgAS
A1QCEBq4ASBBcmdlbnR1bSBwcm9kdWN0IFNLVSwgdGhhdCBpcyBhc3NvY2lhdGVkIHdpdGgg
dGhlIHBhcnRuZXIgb2ZmZXJpbmdzIHRvCiBjdXN0b21lcnMgdXNlZCBieSBTeW50cm8gZm9y
IGJpbGxpbmcgcHVycG9zZXMuIFNLVXMgY2FuIHJlcHJlc2VudCByZXNvbGQKIEdvb2dsZSBw
cm9kdWN0cyBvciBzdXBwb3J0IHNlcnZpY2VzLgoKDAoFBAICAAUSA1QCCAoMCgUEAgIAARID
VAkLCgwKBQQCAgADEgNUDg8KsgEKBAQCAgESA1kCGhqkASBEaXNwbGF5IG5hbWUgb2YgdGhl
IHByb2R1Y3QgaWRlbnRpZmllZCBieSB0aGUgU0tVLiBBIHBhcnRuZXIgbWF5IHdhbnQgdG8K
IHNob3cgcGFydG5lciBicmFuZGVkIG5hbWVzIGZvciB0aGVpciBvZmZlcmluZ3Mgc3VjaCBh
cyBsb2NhbCBzb3ZlcmVpZ24KIGNsb3VkIHNvbHV0aW9ucy4KCgwKBQQCAgEFEgNZAggKDAoF
BAICAQESA1kJFQoMCgUEAgIBAxIDWRgZClQKAgQDEgRdAHgBGkggSG9sZHMgaW5mb3JtYXRp
b24gbmVlZGVkIGJ5IE11ZGJyYXkgdG8gdXNlIHBhcnRuZXIgRUtNcyBmb3Igd29ya2xvYWRz
LgoKCgoDBAMBEgNdCBMKsQEKBAQDBAASBGECcAMaogEgUmVwcmVzZW50cyBHb29nbGUgQ2xv
dWQgc3VwcG9ydGVkIGV4dGVybmFsIGtleSBtYW5hZ2VtZW50IHBhcnRuZXJzCiBbR29vZ2xl
IENsb3VkIEVLTSBwYXJ0bmVycwogZG9jc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2tt
cy9kb2NzL2VrbSNzdXBwb3J0ZWRfcGFydG5lcnMpLgoKDAoFBAMEAAESA2EHEgopCgYEAwQA
AgASA2MEIRoaIFVuc3BlY2lmaWVkIEVLTSBzb2x1dGlvbgoKDgoHBAMEAAIAARIDYwQcCg4K
BwQDBAACAAISA2MfIAolCgYEAwQAAgESA2YEERoWIEVLTSBQYXJ0bmVyIEZvcnRhbml4CgoO
CgcEAwQAAgEBEgNmBAwKDgoHBAMEAAIBAhIDZg8QCiQKBgQDBAACAhIDaQQQGhUgRUtNIFBh
cnRuZXIgRnV0dXJlWAoKDgoHBAMEAAICARIDaQQLCg4KBwQDBAACAgISA2kODwojCgYEAwQA
AgMSA2wEDxoUIEVLTSBQYXJ0bmVyIFRoYWxlcwoKDgoHBAMEAAIDARIDbAQKCg4KBwQDBAAC
AwISA2wNDgovCgYEAwQAAgQSA28EIxogIFRoaXMgZW51bSB2YWx1ZSBpcyBuZXZlciB1c2Vk
LgoKDgoHBAMEAAIEARIDbwQKCg4KBwQDBAACBAISA28NDgoOCgcEAwQAAgQDEgNvDyIKDwoI
BAMEAAIEAwESA28QIQolCgQEAwIAEgNzAh8aGCBUaGUgQ2xvdWQgRUtNIHBhcnRuZXIuCgoM
CgUEAwIABhIDcwINCgwKBQQDAgABEgNzDhoKDAoFBAMCAAMSA3MdHgpvCgQEAwIBEgN3Ah4a
YiBFbmRwb2ludCBmb3Igc2VuZGluZyByZXF1ZXN0cyB0byB0aGUgRUtNIGZvciBrZXkgcHJv
dmlzaW9uaW5nIGR1cmluZwogQXNzdXJlZCBXb3JrbG9hZCBjcmVhdGlvbi4KCgwKBQQDAgEF
EgN3AggKDAoFBAMCAQESA3cJGQoMCgUEAwIBAxIDdxwdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner ===
    # Fields for Partner
    # Field: name Type: 9 ()
    # Field: skus Type: 11 (.google.cloud.cloudcontrolspartner.v1.Sku)
    # Field: ekm_solutions Type: 11 (.google.cloud.cloudcontrolspartner.v1.EkmMetadata)
    # Field: operated_cloud_regions Type: 9 ()
    # Field: partner_project_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Partners::GetPartnerRequest ===
    # Fields for GetPartnerRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Partners::Sku ===
    # Fields for Sku
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::Partners::EkmMetadata ===
    # Fields for EkmMetadata
    # Field: ekm_solution Type: 14 (.google.cloud.cloudcontrolspartner.v1.EkmMetadata.EkmSolution)
    # Field: ekm_endpoint_uri Type: 9 ()

# Enum: EkmMetadata::EkmSolution
our $EkmMetadata_EKM_SOLUTION_UNSPECIFIED = 0;
our $EkmMetadata_FORTANIX = 1;
our $EkmMetadata_FUTUREX = 2;
our $EkmMetadata_THALES = 3;
our $EkmMetadata_VIRTRU = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Partners - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/partners.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::Partners;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner->new({
        name => $name,
        skus => $skus,
        ekm_solutions => $ekm_solutions,
        operated_cloud_regions => $operated_cloud_regions,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/partners.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner

Message describing Partner resource

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the partner.
Format: `organizations/{organization}/locations/{location}/partner`
Example: "organizations/123456/locations/us-central1/partner"

=item * C<< $msg->skus() >> / C<< $msg->skus($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Partners::Sku>)

List of SKUs the partner is offering

=item * C<< $msg->ekm_solutions() >> / C<< $msg->ekm_solutions($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::Partners::EkmMetadata>)

List of Google Cloud supported EKM partners supported by the partner

=item * C<< $msg->operated_cloud_regions() >> / C<< $msg->operated_cloud_regions($value) >>

Type: C<String>

List of Google Cloud regions that the partner sells services to customers.
Valid Google Cloud regions found here:
https://cloud.google.com/compute/docs/regions-zones

=item * C<< $msg->partner_project_id() >> / C<< $msg->partner_project_id($value) >>

Type: C<String>

Google Cloud project ID in the partner's Google Cloud organization for
receiving enhanced Logs for Partners.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the resource was created

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time the resource was updated

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Partners::GetPartnerRequest

Message for getting a Partner

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`organizations/{organization}/locations/{location}/partner`

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Partners::Sku

Represents the SKU a partner owns inside Google Cloud to sell to customers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Argentum product SKU, that is associated with the partner offerings to
customers used by Syntro for billing purposes. SKUs can represent resold
Google products or support services.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name of the product identified by the SKU. A partner may want to
show partner branded names for their offerings such as local sovereign
cloud solutions.

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::Partners::EkmMetadata

Holds information needed by Mudbray to use partner EKMs for workloads.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ekm_solution() >> / C<< $msg->ekm_solution($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::EkmMetadata::EkmSolution>)

The Cloud EKM partner.

=item * C<< $msg->ekm_endpoint_uri() >> / C<< $msg->ekm_endpoint_uri($value) >>

Type: C<String>

Endpoint for sending requests to the EKM for key provisioning during
Assured Workload creation.

=back

=head3 Enum: EkmMetadata::EkmSolution

=over 4

=item * C<EKM_SOLUTION_UNSPECIFIED> => C<0>

=item * C<FORTANIX> => C<1>

=item * C<FUTUREX> => C<2>

=item * C<THALES> => C<3>

=item * C<VIRTRU> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::Partners::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
