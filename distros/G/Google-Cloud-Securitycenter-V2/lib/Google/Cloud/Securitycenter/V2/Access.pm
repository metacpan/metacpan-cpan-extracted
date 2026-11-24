package Google::Cloud::Securitycenter::V2::Access;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvYWNjZXNzLnByb3RvEh5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjIitwQKBkFjY2VzcxInCg9wcmluY2lwYWxfZW1haWwY
ASABKAlSDnByaW5jaXBhbEVtYWlsEhsKCWNhbGxlcl9pcBgCIAEoCVIIY2FsbGVySXASTwoN
Y2FsbGVyX2lwX2dlbxgDIAEoCzIrLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5H
ZW9sb2NhdGlvblILY2FsbGVySXBHZW8SKgoRdXNlcl9hZ2VudF9mYW1pbHkYBCABKAlSD3Vz
ZXJBZ2VudEZhbWlseRIdCgp1c2VyX2FnZW50GAUgASgJUgl1c2VyQWdlbnQSIQoMc2Vydmlj
ZV9uYW1lGAYgASgJUgtzZXJ2aWNlTmFtZRIfCgttZXRob2RfbmFtZRgHIAEoCVIKbWV0aG9k
TmFtZRIrChFwcmluY2lwYWxfc3ViamVjdBgIIAEoCVIQcHJpbmNpcGFsU3ViamVjdBI3Chhz
ZXJ2aWNlX2FjY291bnRfa2V5X25hbWUYCSABKAlSFXNlcnZpY2VBY2NvdW50S2V5TmFtZRKD
AQofc2VydmljZV9hY2NvdW50X2RlbGVnYXRpb25faW5mbxgKIAMoCzI8Lmdvb2dsZS5jbG91
ZC5zZWN1cml0eWNlbnRlci52Mi5TZXJ2aWNlQWNjb3VudERlbGVnYXRpb25JbmZvUhxzZXJ2
aWNlQWNjb3VudERlbGVnYXRpb25JbmZvEhsKCXVzZXJfbmFtZRgLIAEoCVIIdXNlck5hbWUi
dAocU2VydmljZUFjY291bnREZWxlZ2F0aW9uSW5mbxInCg9wcmluY2lwYWxfZW1haWwYASAB
KAlSDnByaW5jaXBhbEVtYWlsEisKEXByaW5jaXBhbF9zdWJqZWN0GAIgASgJUhBwcmluY2lw
YWxTdWJqZWN0Ii4KC0dlb2xvY2F0aW9uEh8KC3JlZ2lvbl9jb2RlGAEgASgJUgpyZWdpb25D
b2RlQuUBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyQgtBY2Nlc3NQcm90
b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5
Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRl
ci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6
OlNlY3VyaXR5Q2VudGVyOjpWMkr2JAoGEgQOAG4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIAOwoJCgIIJRIDEgA7CggKAQgSAxMAYQoJ
CgIICxIDEwBhCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUALAoJCgIICBIDFQAsCggK
AQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAOwoJCgIIKRIDFwA7CggKAQgSAxgAOgoJCgII
LRIDGAA6CikKAgQAEgQbAFkBGh0gUmVwcmVzZW50cyBhbiBhY2Nlc3MgZXZlbnQuCgoKCgME
AAESAxsIDgrhAwoEBAACABIDJAIdGtMDIEFzc29jaWF0ZWQgZW1haWwsIHN1Y2ggYXMgImZv
b0Bnb29nbGUuY29tIi4KCiBUaGUgZW1haWwgYWRkcmVzcyBvZiB0aGUgYXV0aGVudGljYXRl
ZCB1c2VyIG9yIGEgc2VydmljZSBhY2NvdW50IGFjdGluZyBvbgogYmVoYWxmIG9mIGEgdGhp
cmQgcGFydHkgcHJpbmNpcGFsIG1ha2luZyB0aGUgcmVxdWVzdC4gRm9yIHRoaXJkIHBhcnR5
CiBpZGVudGl0eSBjYWxsZXJzLCB0aGUgYHByaW5jaXBhbF9zdWJqZWN0YCBmaWVsZCBpcyBw
b3B1bGF0ZWQgaW5zdGVhZCBvZgogdGhpcyBmaWVsZC4gRm9yIHByaXZhY3kgcmVhc29ucywg
dGhlIHByaW5jaXBhbCBlbWFpbCBhZGRyZXNzIGlzIHNvbWV0aW1lcwogcmVkYWN0ZWQuIEZv
ciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgW0NhbGxlciBpZGVudGl0aWVzIGluIGF1ZGl0CiBs
b2dzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbG9nZ2luZy9kb2NzL2F1ZGl0I3VzZXIt
aWQpLgoKDAoFBAACAAUSAyQCCAoMCgUEAAIAARIDJAkYCgwKBQQAAgADEgMkGxwKNgoEBAAC
ARIDJwIXGikgQ2FsbGVyJ3MgSVAgYWRkcmVzcywgc3VjaCBhcyAiMS4xLjEuMSIuCgoMCgUE
AAIBBRIDJwIICgwKBQQAAgEBEgMnCRIKDAoFBAACAQMSAycVFgpWCgQEAAICEgMqAiAaSSBU
aGUgY2FsbGVyIElQJ3MgZ2VvbG9jYXRpb24sIHdoaWNoIGlkZW50aWZpZXMgd2hlcmUgdGhl
IGNhbGwgY2FtZSBmcm9tLgoKDAoFBAACAgYSAyoCDQoMCgUEAAICARIDKg4bCgwKBQQAAgID
EgMqHh8KkQEKBAQAAgMSAy4CHxqDASBUeXBlIG9mIHVzZXIgYWdlbnQgYXNzb2NpYXRlZCB3
aXRoIHRoZSBmaW5kaW5nLiBGb3IgZXhhbXBsZSwgYW4gb3BlcmF0aW5nCiBzeXN0ZW0gc2hl
bGwgb3IgYW4gZW1iZWRkZWQgb3Igc3RhbmRhbG9uZSBhcHBsaWNhdGlvbi4KCgwKBQQAAgMF
EgMuAggKDAoFBAACAwESAy4JGgoMCgUEAAIDAxIDLh0eCkoKBAQAAgQSAzECGBo9IFRoZSBj
YWxsZXIncyB1c2VyIGFnZW50IHN0cmluZyBhc3NvY2lhdGVkIHdpdGggdGhlIGZpbmRpbmcu
CgoMCgUEAAIEBRIDMQIICgwKBQQAAgQBEgMxCRMKDAoFBAACBAMSAzEWFwpqCgQEAAIFEgM1
AhoaXSBUaGlzIGlzIHRoZSBBUEkgc2VydmljZSB0aGF0IHRoZSBzZXJ2aWNlIGFjY291bnQg
bWFkZSBhIGNhbGwgdG8sIGUuZy4KICJpYW0uZ29vZ2xlYXBpcy5jb20iCgoMCgUEAAIFBRID
NQIICgwKBQQAAgUBEgM1CRUKDAoFBAACBQMSAzUYGQpPCgQEAAIGEgM4AhkaQiBUaGUgbWV0
aG9kIHRoYXQgdGhlIHNlcnZpY2UgYWNjb3VudCBjYWxsZWQsIGUuZy4gIlNldElhbVBvbGlj
eSIuCgoMCgUEAAIGBRIDOAIICgwKBQQAAgYBEgM4CRQKDAoFBAACBgMSAzgXGAr/AwoEBAAC
BxIDQgIfGvEDIEEgc3RyaW5nIHRoYXQgcmVwcmVzZW50cyB0aGUgcHJpbmNpcGFsX3N1Ympl
Y3QgdGhhdCBpcyBhc3NvY2lhdGVkIHdpdGggdGhlCiBpZGVudGl0eS4gVW5saWtlIGBwcmlu
Y2lwYWxfZW1haWxgLCBgcHJpbmNpcGFsX3N1YmplY3RgIHN1cHBvcnRzIHByaW5jaXBhbHMK
IHRoYXQgYXJlbid0IGFzc29jaWF0ZWQgd2l0aCBlbWFpbCBhZGRyZXNzZXMsIHN1Y2ggYXMg
dGhpcmQgcGFydHkKIHByaW5jaXBhbHMuIEZvciBtb3N0IGlkZW50aXRpZXMsIHRoZSBmb3Jt
YXQgaXMKIGBwcmluY2lwYWw6Ly9pYW0uZ29vZ2xlYXBpcy5jb20ve2lkZW50aXR5IHBvb2wg
bmFtZX0vc3ViamVjdC97c3ViamVjdH1gLgogU29tZSBHS0UgaWRlbnRpdGllcywgc3VjaCBh
cyBHS0VfV09SS0xPQUQsIEZSRUVGT1JNLCBhbmQgR0tFX0hVQl9XT1JLTE9BRCwKIHN0aWxs
IHVzZSB0aGUgbGVnYWN5IGZvcm1hdCBgc2VydmljZUFjY291bnQ6e2lkZW50aXR5IHBvb2wK
IG5hbWV9W3tzdWJqZWN0fV1gLgoKDAoFBAACBwUSA0ICCAoMCgUEAAIHARIDQgkaCgwKBQQA
AgcDEgNCHR4KtQIKBAQAAggSA0oCJhqnAiBUaGUgbmFtZSBvZiB0aGUgc2VydmljZSBhY2Nv
dW50IGtleSB0aGF0IHdhcyB1c2VkIHRvIGNyZWF0ZSBvciBleGNoYW5nZQogY3JlZGVudGlh
bHMgd2hlbiBhdXRoZW50aWNhdGluZyB0aGUgc2VydmljZSBhY2NvdW50IHRoYXQgbWFkZSB0
aGUgcmVxdWVzdC4KIFRoaXMgaXMgYSBzY2hlbWUtbGVzcyBVUkkgZnVsbCByZXNvdXJjZSBu
YW1lLiBGb3IgZXhhbXBsZToKCiAiLy9pYW0uZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMve1BS
T0pFQ1RfSUR9L3NlcnZpY2VBY2NvdW50cy97QUNDT1VOVH0va2V5cy97a2V5fSIuCgoKDAoF
BAACCAUSA0oCCAoMCgUEAAIIARIDSgkhCgwKBQQAAggDEgNKJCUKowMKBAQAAgkSA1ICTRqV
AyBUaGUgaWRlbnRpdHkgZGVsZWdhdGlvbiBoaXN0b3J5IG9mIGFuIGF1dGhlbnRpY2F0ZWQg
c2VydmljZSBhY2NvdW50IHRoYXQKIG1hZGUgdGhlIHJlcXVlc3QuIFRoZSBgc2VydmljZUFj
Y291bnREZWxlZ2F0aW9uSW5mb1tdYCBvYmplY3QgY29udGFpbnMKIGluZm9ybWF0aW9uIGFi
b3V0IHRoZSByZWFsIGF1dGhvcml0aWVzIHRoYXQgdHJ5IHRvIGFjY2VzcyBHb29nbGUgQ2xv
dWQKIHJlc291cmNlcyBieSBkZWxlZ2F0aW5nIG9uIGEgc2VydmljZSBhY2NvdW50LiBXaGVu
IG11bHRpcGxlIGF1dGhvcml0aWVzIGFyZQogcHJlc2VudCwgdGhleSBhcmUgZ3VhcmFudGVl
ZCB0byBiZSBzb3J0ZWQgYmFzZWQgb24gdGhlIG9yaWdpbmFsIG9yZGVyaW5nIG9mCiB0aGUg
aWRlbnRpdHkgZGVsZWdhdGlvbiBldmVudHMuCgoMCgUEAAIJBBIDUgIKCgwKBQQAAgkGEgNS
CycKDAoFBAACCQESA1IoRwoMCgUEAAIJAxIDUkpMCpsCCgQEAAIKEgNYAhgajQIgQSBzdHJp
bmcgdGhhdCByZXByZXNlbnRzIGEgdXNlcm5hbWUuIFRoZSB1c2VybmFtZSBwcm92aWRlZCBk
ZXBlbmRzIG9uIHRoZQogdHlwZSBvZiB0aGUgZmluZGluZyBhbmQgaXMgbGlrZWx5IG5vdCBh
biBJQU0gcHJpbmNpcGFsLiBGb3IgZXhhbXBsZSwgdGhpcwogY2FuIGJlIGEgc3lzdGVtIHVz
ZXJuYW1lIGlmIHRoZSBmaW5kaW5nIGlzIHJlbGF0ZWQgdG8gYSB2aXJ0dWFsIG1hY2hpbmUs
IG9yCiBpdCBjYW4gYmUgYW4gYXBwbGljYXRpb24gbG9naW4gdXNlcm5hbWUuCgoMCgUEAAIK
BRIDWAIICgwKBQQAAgoBEgNYCRIKDAoFBAACCgMSA1gVFwpOCgIEARIEXABoARpCIElkZW50
aXR5IGRlbGVnYXRpb24gaGlzdG9yeSBvZiBhbiBhdXRoZW50aWNhdGVkIHNlcnZpY2UgYWNj
b3VudC4KCgoKAwQBARIDXAgkCjUKBAQBAgASA14CHRooIFRoZSBlbWFpbCBhZGRyZXNzIG9m
IGEgR29vZ2xlIGFjY291bnQuCgoMCgUEAQIABRIDXgIICgwKBQQBAgABEgNeCRgKDAoFBAEC
AAMSA14bHAryAwoEBAECARIDZwIfGuQDIEEgc3RyaW5nIHJlcHJlc2VudGluZyB0aGUgcHJp
bmNpcGFsX3N1YmplY3QgYXNzb2NpYXRlZCB3aXRoIHRoZSBpZGVudGl0eS4KIEFzIGNvbXBh
cmVkIHRvIGBwcmluY2lwYWxfZW1haWxgLCBzdXBwb3J0cyBwcmluY2lwYWxzIHRoYXQgYXJl
bid0CiBhc3NvY2lhdGVkIHdpdGggZW1haWwgYWRkcmVzc2VzLCBzdWNoIGFzIHRoaXJkIHBh
cnR5IHByaW5jaXBhbHMuIEZvciBtb3N0CiBpZGVudGl0aWVzLCB0aGUgZm9ybWF0IHdpbGwg
YmUgYHByaW5jaXBhbDovL2lhbS5nb29nbGVhcGlzLmNvbS97aWRlbnRpdHkKIHBvb2wgbmFt
ZX0vc3ViamVjdHMve3N1YmplY3R9YCBleGNlcHQgZm9yIHNvbWUgR0tFIGlkZW50aXRpZXMK
IChHS0VfV09SS0xPQUQsIEZSRUVGT1JNLCBHS0VfSFVCX1dPUktMT0FEKSB0aGF0IGFyZSBz
dGlsbCBpbiB0aGUgbGVnYWN5CiBmb3JtYXQgYHNlcnZpY2VBY2NvdW50OntpZGVudGl0eSBw
b29sIG5hbWV9W3tzdWJqZWN0fV1gCgoMCgUEAQIBBRIDZwIICgwKBQQBAgEBEgNnCRoKDAoF
BAECAQMSA2cdHgpECgIEAhIEawBuARo4IFJlcHJlc2VudHMgYSBnZW9ncmFwaGljYWwgbG9j
YXRpb24gZm9yIGEgZ2l2ZW4gYWNjZXNzLgoKCgoDBAIBEgNrCBMKFgoEBAICABIDbQIZGgkg
QSBDTERSLgoKDAoFBAICAAUSA20CCAoMCgUEAgIAARIDbQkUCgwKBQQCAgADEgNtFxhiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Access::Access ===
    # Fields for Access
    # Field: principal_email Type: 9 ()
    # Field: caller_ip Type: 9 ()
    # Field: caller_ip_geo Type: 11 (.google.cloud.securitycenter.v2.Geolocation)
    # Field: user_agent_family Type: 9 ()
    # Field: user_agent Type: 9 ()
    # Field: service_name Type: 9 ()
    # Field: method_name Type: 9 ()
    # Field: principal_subject Type: 9 ()
    # Field: service_account_key_name Type: 9 ()
    # Field: service_account_delegation_info Type: 11 (.google.cloud.securitycenter.v2.ServiceAccountDelegationInfo)
    # Field: user_name Type: 9 ()

# === Message: Google::Cloud::Securitycenter::V2::Access::ServiceAccountDelegationInfo ===
    # Fields for ServiceAccountDelegationInfo
    # Field: principal_email Type: 9 ()
    # Field: principal_subject Type: 9 ()

# === Message: Google::Cloud::Securitycenter::V2::Access::Geolocation ===
    # Fields for Geolocation
    # Field: region_code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Access - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/access.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Access;

    my $msg = Google::Cloud::Securitycenter::V2::Access::Access->new({
        principal_email => $principal_email,
        caller_ip => $caller_ip,
        caller_ip_geo => $caller_ip_geo,
        user_agent_family => $user_agent_family,
    });

    # Read or update a field
    my $val = $msg->principal_email();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Access::Access->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/access.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Access::Access

Represents an access event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal_email() >> / C<< $msg->principal_email($value) >>

Type: C<String>

Associated email, such as "foo@google.com".

The email address of the authenticated user or a service account acting on
behalf of a third party principal making the request. For third party
identity callers, the `principal_subject` field is populated instead of
this field. For privacy reasons, the principal email address is sometimes
redacted. For more information, see [Caller identities in audit
logs](https://cloud.google.com/logging/docs/audit#user-id).

=item * C<< $msg->caller_ip() >> / C<< $msg->caller_ip($value) >>

Type: C<String>

Caller's IP address, such as "1.1.1.1".

=item * C<< $msg->caller_ip_geo() >> / C<< $msg->caller_ip_geo($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Access::Geolocation>)

The caller IP's geolocation, which identifies where the call came from.

=item * C<< $msg->user_agent_family() >> / C<< $msg->user_agent_family($value) >>

Type: C<String>

Type of user agent associated with the finding. For example, an operating
system shell or an embedded or standalone application.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<String>

The caller's user agent string associated with the finding.

=item * C<< $msg->service_name() >> / C<< $msg->service_name($value) >>

Type: C<String>

This is the API service that the service account made a call to, e.g.
"iam.googleapis.com"

=item * C<< $msg->method_name() >> / C<< $msg->method_name($value) >>

Type: C<String>

The method that the service account called, e.g. "SetIamPolicy".

=item * C<< $msg->principal_subject() >> / C<< $msg->principal_subject($value) >>

Type: C<String>

A string that represents the principal_subject that is associated with the
identity. Unlike `principal_email`, `principal_subject` supports principals
that aren't associated with email addresses, such as third party
principals. For most identities, the format is
`principal://iam.googleapis.com/{identity pool name}/subject/{subject}`.
Some GKE identities, such as GKE_WORKLOAD, FREEFORM, and GKE_HUB_WORKLOAD,
still use the legacy format `serviceAccount:{identity pool
name}[{subject}]`.

=item * C<< $msg->service_account_key_name() >> / C<< $msg->service_account_key_name($value) >>

Type: C<String>

The name of the service account key that was used to create or exchange
credentials when authenticating the service account that made the request.
This is a scheme-less URI full resource name. For example:

"//iam.googleapis.com/projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT}/keys/{key}".


=item * C<< $msg->service_account_delegation_info() >> / C<< $msg->service_account_delegation_info($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Access::ServiceAccountDelegationInfo>)

The identity delegation history of an authenticated service account that
made the request. The `serviceAccountDelegationInfo[]` object contains
information about the real authorities that try to access Google Cloud
resources by delegating on a service account. When multiple authorities are
present, they are guaranteed to be sorted based on the original ordering of
the identity delegation events.

=item * C<< $msg->user_name() >> / C<< $msg->user_name($value) >>

Type: C<String>

A string that represents a username. The username provided depends on the
type of the finding and is likely not an IAM principal. For example, this
can be a system username if the finding is related to a virtual machine, or
it can be an application login username.

=back

=head2 Google::Cloud::Securitycenter::V2::Access::ServiceAccountDelegationInfo

Identity delegation history of an authenticated service account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->principal_email() >> / C<< $msg->principal_email($value) >>

Type: C<String>

The email address of a Google account.

=item * C<< $msg->principal_subject() >> / C<< $msg->principal_subject($value) >>

Type: C<String>

A string representing the principal_subject associated with the identity.
As compared to `principal_email`, supports principals that aren't
associated with email addresses, such as third party principals. For most
identities, the format will be `principal://iam.googleapis.com/{identity
pool name}/subjects/{subject}` except for some GKE identities
(GKE_WORKLOAD, FREEFORM, GKE_HUB_WORKLOAD) that are still in the legacy
format `serviceAccount:{identity pool name}[{subject}]`

=back

=head2 Google::Cloud::Securitycenter::V2::Access::Geolocation

Represents a geographical location for a given access.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->region_code() >> / C<< $msg->region_code($value) >>

Type: C<String>

A CLDR.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Access::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
