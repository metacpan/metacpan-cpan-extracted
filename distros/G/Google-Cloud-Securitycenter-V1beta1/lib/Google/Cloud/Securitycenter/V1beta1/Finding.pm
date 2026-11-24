package Google::Cloud::Securitycenter::V1beta1::Finding;

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
    eval { require Google::Cloud::Securitycenter::V1beta1::SecurityMarks };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjFiZXRhMS9maW5kaW5nLnByb3RvEiNn
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo4Z29vZ2xlL2Nsb3Vk
L3NlY3VyaXR5Y2VudGVyL3YxYmV0YTEvc2VjdXJpdHlfbWFya3MucHJvdG8aHGdvb2dsZS9w
cm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
tgYKB0ZpbmRpbmcSEgoEbmFtZRgBIAEoCVIEbmFtZRIbCgZwYXJlbnQYAiABKAlCA+BBBVIG
cGFyZW50EiMKDXJlc291cmNlX25hbWUYAyABKAlSDHJlc291cmNlTmFtZRJICgVzdGF0ZRgE
IAEoDjIyLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExLkZpbmRpbmcuU3Rh
dGVSBXN0YXRlEhoKCGNhdGVnb3J5GAUgASgJUghjYXRlZ29yeRIhCgxleHRlcm5hbF91cmkY
BiABKAlSC2V4dGVybmFsVXJpEm8KEXNvdXJjZV9wcm9wZXJ0aWVzGAcgAygLMkIuZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxYmV0YTEuRmluZGluZy5Tb3VyY2VQcm9wZXJ0aWVz
RW50cnlSEHNvdXJjZVByb3BlcnRpZXMSXgoOc2VjdXJpdHlfbWFya3MYCCABKAsyMi5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFiZXRhMS5TZWN1cml0eU1hcmtzQgPgQQNSDXNl
Y3VyaXR5TWFya3MSOQoKZXZlbnRfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCWV2ZW50VGltZRI7CgtjcmVhdGVfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUaWwoVU291cmNlUHJvcGVydGllc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2
YWx1ZToCOAEiOAoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZBQ1RJVkUQARIM
CghJTkFDVElWRRACOmzqQWkKJXNlY3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL0ZpbmRp
bmcSQG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vc291cmNlcy97c291cmNlfS9maW5k
aW5ncy97ZmluZGluZ31CfAonY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJl
dGExUAFaT2Nsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjFiZXRhMS9z
ZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGJK6iAKBhIEDgBsAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAQgoJCgIDAxIDFQAmCgkKAgMEEgMWACkKCAoBCBIDGABmCgkKAggLEgMY
AGYKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgBACgkKAggBEgMaAEAKvwIKAgQAEgQi
AGwBGrICIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyIGZpbmRpbmcuCgogQSBmaW5kaW5nIGlz
IGEgcmVjb3JkIG9mIGFzc2Vzc21lbnQgZGF0YSAoc2VjdXJpdHksIHJpc2ssIGhlYWx0aCBv
ciBwcml2YWN5KQogaW5nZXN0ZWQgaW50byBTZWN1cml0eSBDb21tYW5kIENlbnRlciBmb3Ig
cHJlc2VudGF0aW9uLCBub3RpZmljYXRpb24sCiBhbmFseXNpcywgcG9saWN5IHRlc3Rpbmcs
IGFuZCBlbmZvcmNlbWVudC4gRm9yIGV4YW1wbGUsIGFuIFhTUyB2dWxuZXJhYmlsaXR5CiBp
biBhbiBBcHAgRW5naW5lIGFwcGxpY2F0aW9uIGlzIGEgZmluZGluZy4KCgoKAwQAARIDIggP
CgsKAwQABxIEIwImBAoNCgUEAAedCBIEIwImBAopCgQEAAQAEgQpAjMDGhsgVGhlIHN0YXRl
IG9mIHRoZSBmaW5kaW5nLgoKDAoFBAAEAAESAykHDAojCgYEAAQAAgASAysEGhoUIFVuc3Bl
Y2lmaWVkIHN0YXRlLgoKDgoHBAAEAAIAARIDKwQVCg4KBwQABAACAAISAysYGQpPCgYEAAQA
AgESAy4EDxpAIFRoZSBmaW5kaW5nIHJlcXVpcmVzIGF0dGVudGlvbiBhbmQgaGFzIG5vdCBi
ZWVuIGFkZHJlc3NlZCB5ZXQuCgoOCgcEAAQAAgEBEgMuBAoKDgoHBAAEAAIBAhIDLg0OCnQK
BgQABAACAhIDMgQRGmUgVGhlIGZpbmRpbmcgaGFzIGJlZW4gZml4ZWQsIHRyaWFnZWQgYXMg
YSBub24taXNzdWUgb3Igb3RoZXJ3aXNlIGFkZHJlc3NlZAogYW5kIGlzIG5vIGxvbmdlciBh
Y3RpdmUuCgoOCgcEAAQAAgIBEgMyBAwKDgoHBAAEAAICAhIDMg8QCuMBCgQEAAIAEgM5AhIa
1QEgVGhlIHJlbGF0aXZlIHJlc291cmNlIG5hbWUgb2YgdGhpcyBmaW5kaW5nLiBTZWU6CiBo
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjcmVs
YXRpdmVfcmVzb3VyY2VfbmFtZQogRXhhbXBsZToKICJvcmdhbml6YXRpb25zL3tvcmdhbml6
YXRpb25faWR9L3NvdXJjZXMve3NvdXJjZV9pZH0vZmluZGluZ3Mve2ZpbmRpbmdfaWR9IgoK
DAoFBAACAAUSAzkCCAoMCgUEAAIAARIDOQkNCgwKBQQAAgADEgM5EBEKoAIKBAQAAgESA0EC
PhqSAiBJbW11dGFibGUuIFRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBzb3Vy
Y2UgdGhlIGZpbmRpbmcgYmVsb25ncyB0by4KIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNyZWxhdGl2ZV9yZXNvdXJjZV9uYW1l
CiBUaGlzIGZpZWxkIGlzIGltbXV0YWJsZSBhZnRlciBjcmVhdGlvbiB0aW1lLgogRm9yIGV4
YW1wbGU6CiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9zb3VyY2VzL3tzb3Vy
Y2VfaWR9IgoKDAoFBAACAQUSA0ECCAoMCgUEAAIBARIDQQkPCgwKBQQAAgEDEgNBEhMKDAoF
BAACAQgSA0EUPQoPCggEAAIBCJwIABIDQRU8CvECCgQEAAICEgNJAhsa4wIgRm9yIGZpbmRp
bmdzIG9uIEdvb2dsZSBDbG91ZCByZXNvdXJjZXMsIHRoZSBmdWxsIHJlc291cmNlCiBuYW1l
IG9mIHRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgdGhpcyBmaW5kaW5nIGlzIGZvci4gU2Vl
OgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVz
I2Z1bGxfcmVzb3VyY2VfbmFtZQogV2hlbiB0aGUgZmluZGluZyBpcyBmb3IgYSBub24tR29v
Z2xlIENsb3VkIHJlc291cmNlLCB0aGUgcmVzb3VyY2VOYW1lIGNhbgogYmUgYSBjdXN0b21l
ciBvciBwYXJ0bmVyIGRlZmluZWQgc3RyaW5nLiBUaGlzIGZpZWxkIGlzIGltbXV0YWJsZSBh
ZnRlcgogY3JlYXRpb24gdGltZS4KCgwKBQQAAgIFEgNJAggKDAoFBAACAgESA0kJFgoMCgUE
AAICAxIDSRkaCigKBAQAAgMSA0wCEhobIFRoZSBzdGF0ZSBvZiB0aGUgZmluZGluZy4KCgwK
BQQAAgMGEgNMAgcKDAoFBAACAwESA0wIDQoMCgUEAAIDAxIDTBARCqABCgQEAAIEEgNRAhYa
kgEgVGhlIGFkZGl0aW9uYWwgdGF4b25vbXkgZ3JvdXAgd2l0aGluIGZpbmRpbmdzIGZyb20g
YSBnaXZlbiBzb3VyY2UuCiBUaGlzIGZpZWxkIGlzIGltbXV0YWJsZSBhZnRlciBjcmVhdGlv
biB0aW1lLgogRXhhbXBsZTogIlhTU19GTEFTSF9JTkpFQ1RJT04iCgoMCgUEAAIEBRIDUQII
CgwKBQQAAgQBEgNRCREKDAoFBAACBAMSA1EUFQrkAQoEBAACBRIDVgIaGtYBIFRoZSBVUkkg
dGhhdCwgaWYgYXZhaWxhYmxlLCBwb2ludHMgdG8gYSB3ZWIgcGFnZSBvdXRzaWRlIG9mIFNl
Y3VyaXR5CiBDb21tYW5kIENlbnRlciB3aGVyZSBhZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFi
b3V0IHRoZSBmaW5kaW5nIGNhbiBiZSBmb3VuZC4KIFRoaXMgZmllbGQgaXMgZ3VhcmFudGVl
ZCB0byBiZSBlaXRoZXIgZW1wdHkgb3IgYSB3ZWxsIGZvcm1lZCBVUkwuCgoMCgUEAAIFBRID
VgIICgwKBQQAAgUBEgNWCRUKDAoFBAACBQMSA1YYGQqZAgoEBAACBhIDXAI7GosCIFNvdXJj
ZSBzcGVjaWZpYyBwcm9wZXJ0aWVzLiBUaGVzZSBwcm9wZXJ0aWVzIGFyZSBtYW5hZ2VkIGJ5
IHRoZSBzb3VyY2UKIHRoYXQgd3JpdGVzIHRoZSBmaW5kaW5nLiBUaGUga2V5IG5hbWVzIGlu
IHRoZSBzb3VyY2VfcHJvcGVydGllcyBtYXAgbXVzdCBiZQogYmV0d2VlbiAxIGFuZCAyNTUg
Y2hhcmFjdGVycywgYW5kIG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBhbmQgY29udGFpbgog
YWxwaGFudW1lcmljIGNoYXJhY3RlcnMgb3IgdW5kZXJzY29yZXMgb25seS4KCgwKBQQAAgYG
EgNcAiQKDAoFBAACBgESA1wlNgoMCgUEAAIGAxIDXDk6CrABCgQEAAIHEgNhAk8aogEgT3V0
cHV0IG9ubHkuIFVzZXIgc3BlY2lmaWVkIHNlY3VyaXR5IG1hcmtzLiBUaGVzZSBtYXJrcyBh
cmUgZW50aXJlbHkKIG1hbmFnZWQgYnkgdGhlIHVzZXIgYW5kIGNvbWUgZnJvbSB0aGUgU2Vj
dXJpdHlNYXJrcyByZXNvdXJjZSB0aGF0IGJlbG9uZ3MKIHRvIHRoZSBmaW5kaW5nLgoKDAoF
BAACBwYSA2ECDwoMCgUEAAIHARIDYRAeCgwKBQQAAgcDEgNhISIKDAoFBAACBwgSA2EjTgoP
CggEAAIHCJwIABIDYSRNCvkCCgQEAAIIEgNoAisa6wIgVGhlIHRpbWUgYXQgd2hpY2ggdGhl
IGV2ZW50IHRvb2sgcGxhY2UsIG9yIHdoZW4gYW4gdXBkYXRlIHRvIHRoZSBmaW5kaW5nCiBv
Y2N1cnJlZC4gRm9yIGV4YW1wbGUsIGlmIHRoZSBmaW5kaW5nIHJlcHJlc2VudHMgYW4gb3Bl
biBmaXJld2FsbCBpdCB3b3VsZAogY2FwdHVyZSB0aGUgdGltZSB0aGUgZGV0ZWN0b3IgYmVs
aWV2ZXMgdGhlIGZpcmV3YWxsIGJlY2FtZSBvcGVuLiBUaGUKIGFjY3VyYWN5IGlzIGRldGVy
bWluZWQgYnkgdGhlIGRldGVjdG9yLiBJZiB0aGUgZmluZGluZyB3ZXJlIHRvIGJlIHJlc29s
dmVkCiBhZnRlcndhcmQsIHRoaXMgdGltZSB3b3VsZCByZWZsZWN0IHdoZW4gdGhlIGZpbmRp
bmcgd2FzIHJlc29sdmVkLgoKDAoFBAACCAYSA2gCGwoMCgUEAAIIARIDaBwmCgwKBQQAAggD
EgNoKSoKVAoEBAACCRIDawItGkcgVGhlIHRpbWUgYXQgd2hpY2ggdGhlIGZpbmRpbmcgd2Fz
IGNyZWF0ZWQgaW4gU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIuCgoMCgUEAAIJBhIDawIbCgwK
BQQAAgkBEgNrHCcKDAoFBAACCQMSA2sqLGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1beta1::Finding::Finding ===
    # Fields for Finding
    # Field: name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: resource_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.securitycenter.v1beta1.Finding.State)
    # Field: category Type: 9 ()
    # Field: external_uri Type: 9 ()
    # Field: source_properties Type: 11 (.google.cloud.securitycenter.v1beta1.Finding.SourcePropertiesEntry)
    # Field: security_marks Type: 11 (.google.cloud.securitycenter.v1beta1.SecurityMarks)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Finding::State
our $Finding_STATE_UNSPECIFIED = 0;
our $Finding_ACTIVE = 1;
our $Finding_INACTIVE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::Finding - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1beta1/finding.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::Finding;

    my $msg = Google::Cloud::Securitycenter::V1beta1::Finding::Finding->new({
        name => $name,
        parent => $parent,
        resource_name => $resource_name,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1beta1::Finding::Finding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1beta1/finding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1beta1::Finding::Finding

Security Command Center finding.

A finding is a record of assessment data (security, risk, health or privacy)
ingested into Security Command Center for presentation, notification,
analysis, policy testing, and enforcement. For example, an XSS vulnerability
in an App Engine application is a finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this finding. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/sources/{source_id}/findings/{finding_id}"

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Immutable. The relative resource name of the source the finding belongs to.
See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
This field is immutable after creation time.
For example:
"organizations/{organization_id}/sources/{source_id}"

=item * C<< $msg->resource_name() >> / C<< $msg->resource_name($value) >>

Type: C<String>

For findings on Google Cloud resources, the full resource
name of the Google Cloud resource this finding is for. See:
https://cloud.google.com/apis/design/resource_names#full_resource_name
When the finding is for a non-Google Cloud resource, the resourceName can
be a customer or partner defined string. This field is immutable after
creation time.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1beta1::Finding::State>)

The state of the finding.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

The additional taxonomy group within findings from a given source.
This field is immutable after creation time.
Example: "XSS_FLASH_INJECTION"

=item * C<< $msg->external_uri() >> / C<< $msg->external_uri($value) >>

Type: C<String>

The URI that, if available, points to a web page outside of Security
Command Center where additional information about the finding can be found.
This field is guaranteed to be either empty or a well formed URL.

=item * C<< $msg->source_properties() >> / C<< $msg->source_properties($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::Finding::Finding::SourcePropertiesEntry>)

Source specific properties. These properties are managed by the source
that writes the finding. The key names in the source_properties map must be
between 1 and 255 characters, and must start with a letter and contain
alphanumeric characters or underscores only.

=item * C<< $msg->security_marks() >> / C<< $msg->security_marks($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks>)

Output only. User specified security marks. These marks are entirely
managed by the user and come from the SecurityMarks resource that belongs
to the finding.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the event took place, or when an update to the finding
occurred. For example, if the finding represents an open firewall it would
capture the time the detector believes the firewall became open. The
accuracy is determined by the detector. If the finding were to be resolved
afterward, this time would reflect when the finding was resolved.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the finding was created in Security Command Center.

=back

=head3 Enum: Finding::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<INACTIVE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1beta1::Finding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
