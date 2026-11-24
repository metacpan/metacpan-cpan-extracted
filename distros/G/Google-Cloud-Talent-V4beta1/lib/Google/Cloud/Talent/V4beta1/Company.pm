package Google::Cloud::Talent::V4beta1::Company;

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
    eval { require Google::Cloud::Talent::V4beta1::Common };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvY29tcGFueS5wcm90bxIbZ29vZ2xlLmNs
b3VkLnRhbGVudC52NGJldGExGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEv
Y29tbW9uLnByb3RvIsoGCgdDb21wYW55EhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxh
eV9uYW1lGAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lEiQKC2V4dGVybmFsX2lkGAMgASgJQgPg
QQJSCmV4dGVybmFsSWQSPAoEc2l6ZRgEIAEoDjIoLmdvb2dsZS5jbG91ZC50YWxlbnQudjRi
ZXRhMS5Db21wYW55U2l6ZVIEc2l6ZRIxChRoZWFkcXVhcnRlcnNfYWRkcmVzcxgFIAEoCVIT
aGVhZHF1YXJ0ZXJzQWRkcmVzcxIjCg1oaXJpbmdfYWdlbmN5GAYgASgIUgxoaXJpbmdBZ2Vu
Y3kSGQoIZWVvX3RleHQYByABKAlSB2Vlb1RleHQSHwoLd2Vic2l0ZV91cmkYCCABKAlSCndl
YnNpdGVVcmkSJgoPY2FyZWVyX3NpdGVfdXJpGAkgASgJUg1jYXJlZXJTaXRlVXJpEhsKCWlt
YWdlX3VyaRgKIAEoCVIIaW1hZ2VVcmkSWgooa2V5d29yZF9zZWFyY2hhYmxlX2pvYl9jdXN0
b21fYXR0cmlidXRlcxgLIAMoCUICGAFSJGtleXdvcmRTZWFyY2hhYmxlSm9iQ3VzdG9tQXR0
cmlidXRlcxJYCgxkZXJpdmVkX2luZm8YDCABKAsyMC5nb29nbGUuY2xvdWQudGFsZW50LnY0
YmV0YTEuQ29tcGFueS5EZXJpdmVkSW5mb0ID4EEDUgtkZXJpdmVkSW5mbxIhCglzdXNwZW5k
ZWQYDSABKAhCA+BBA1IJc3VzcGVuZGVkGmkKC0Rlcml2ZWRJbmZvEloKFWhlYWRxdWFydGVy
c19sb2NhdGlvbhgBIAEoCzIlLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Mb2NhdGlv
blIUaGVhZHF1YXJ0ZXJzTG9jYXRpb246gQHqQX4KG2pvYnMuZ29vZ2xlYXBpcy5jb20vQ29t
cGFueRI3cHJvamVjdHMve3Byb2plY3R9L3RlbmFudHMve3RlbmFudH0vY29tcGFuaWVzL3tj
b21wYW55fRImcHJvamVjdHMve3Byb2plY3R9L2NvbXBhbmllcy97Y29tcGFueX1CeAofY29t
Lmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMUIUQ29tcGFueVJlc291cmNlUHJvdG9QAVo3
Y2xvdWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBpdjRiZXRhMS90YWxlbnRwYjt0YWxlbnRw
YqICA0NUU0qEJAoGEgQOAH4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAyCggKAQgSAxYATgoJ
CgIICxIDFgBOCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgANQoJCgIICBIDGAA1CggK
AQgSAxkAOAoJCgIIARIDGQA4CggKAQgSAxoAIQoJCgIIJBIDGgAhCs4BCgIEABIEHwB+ARrB
ASBBIENvbXBhbnkgcmVzb3VyY2UgcmVwcmVzZW50cyBhIGNvbXBhbnkgaW4gdGhlIHNlcnZp
Y2UuIEEgY29tcGFueSBpcyB0aGUKIGVudGl0eSB0aGF0IG93bnMgam9iIHBvc3RpbmdzLCB0
aGF0IGlzLCB0aGUgaGlyaW5nIGVudGl0eSByZXNwb25zaWJsZSBmb3IKIGVtcGxveWluZyBh
cHBsaWNhbnRzIGZvciB0aGUgam9iIHBvc2l0aW9uLgoKCgoDBAABEgMfCA8KCwoDBAAHEgQg
AiQECg0KBQQAB50IEgQgAiQECjIKBAQAAwASBCcCLAMaJCBEZXJpdmVkIGRldGFpbHMgYWJv
dXQgdGhlIGNvbXBhbnkuCgoMCgUEAAMAARIDJwoVCroBCgYEAAMAAgASAysEJxqqASBBIHN0
cnVjdHVyZWQgaGVhZHF1YXJ0ZXJzIGxvY2F0aW9uIG9mIHRoZSBjb21wYW55LCByZXNvbHZl
ZCBmcm9tCiBbQ29tcGFueS5oZWFkcXVhcnRlcnNfYWRkcmVzc11bZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkNvbXBhbnkuaGVhZHF1YXJ0ZXJzX2FkZHJlc3NdCiBpZiBwcm92aWRl
ZC4KCg4KBwQAAwACAAYSAysEDAoOCgcEAAMAAgABEgMrDSIKDgoHBAADAAIAAxIDKyUmCoMD
CgQEAAIAEgM5AhIa9QIgUmVxdWlyZWQgZHVyaW5nIGNvbXBhbnkgdXBkYXRlLgoKIFRoZSBy
ZXNvdXJjZSBuYW1lIGZvciBhIGNvbXBhbnkuIFRoaXMgaXMgZ2VuZXJhdGVkIGJ5IHRoZSBz
ZXJ2aWNlIHdoZW4gYQogY29tcGFueSBpcyBjcmVhdGVkLgoKIFRoZSBmb3JtYXQgaXMKICJw
cm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50cy97dGVuYW50X2lkfS9jb21wYW5pZXMve2Nv
bXBhbnlfaWR9IiwgZm9yCiBleGFtcGxlLCAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFyL2Nv
bXBhbmllcy9iYXoiLgoKIElmIHRlbmFudCBpZCBpcyB1bnNwZWNpZmllZCwgdGhlIGRlZmF1
bHQgdGVuYW50IGlzIHVzZWQuIEZvcgogZXhhbXBsZSwgInByb2plY3RzL2Zvby9jb21wYW5p
ZXMvYmFyIi4KCgwKBQQAAgAFEgM5AggKDAoFBAACAAESAzkJDQoMCgUEAAIAAxIDORARClQK
BAQAAgESAzwCQxpHIFJlcXVpcmVkLiBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBjb21wYW55
LCBmb3IgZXhhbXBsZSwgIkdvb2dsZSBMTEMiLgoKDAoFBAACAQUSAzwCCAoMCgUEAAIBARID
PAkVCgwKBQQAAgEDEgM8GBkKDAoFBAACAQgSAzwaQgoPCggEAAIBCJwIABIDPBtBCpQBCgQE
AAICEgNCAkIahgEgUmVxdWlyZWQuIENsaWVudCBzaWRlIGNvbXBhbnkgaWRlbnRpZmllciwg
dXNlZCB0byB1bmlxdWVseSBpZGVudGlmeSB0aGUKIGNvbXBhbnkuCgogVGhlIG1heGltdW0g
bnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAyNTUuCgoMCgUEAAICBRIDQgIICgwK
BQQAAgIBEgNCCRQKDAoFBAACAgMSA0IXGAoMCgUEAAICCBIDQhlBCg8KCAQAAgIInAgAEgNC
GkAKKwoEBAACAxIDRQIXGh4gVGhlIGVtcGxveWVyJ3MgY29tcGFueSBzaXplLgoKDAoFBAAC
AwYSA0UCDQoMCgUEAAIDARIDRQ4SCgwKBQQAAgMDEgNFFRYK2AIKBAQAAgQSA0wCIhrKAiBU
aGUgc3RyZWV0IGFkZHJlc3Mgb2YgdGhlIGNvbXBhbnkncyBtYWluIGhlYWRxdWFydGVycywg
d2hpY2ggbWF5IGJlCiBkaWZmZXJlbnQgZnJvbSB0aGUgam9iIGxvY2F0aW9uLiBUaGUgc2Vy
dmljZSBhdHRlbXB0cwogdG8gZ2VvbG9jYXRlIHRoZSBwcm92aWRlZCBhZGRyZXNzLCBhbmQg
cG9wdWxhdGVzIGEgbW9yZSBzcGVjaWZpYwogbG9jYXRpb24gd2hlcmV2ZXIgcG9zc2libGUg
aW4KIFtEZXJpdmVkSW5mby5oZWFkcXVhcnRlcnNfbG9jYXRpb25dW2dvb2dsZS5jbG91ZC50
YWxlbnQudjRiZXRhMS5Db21wYW55LkRlcml2ZWRJbmZvLmhlYWRxdWFydGVyc19sb2NhdGlv
bl0uCgoMCgUEAAIEBRIDTAIICgwKBQQAAgQBEgNMCR0KDAoFBAACBAMSA0wgIQp/CgQEAAIF
EgNSAhkaciBTZXQgdG8gdHJ1ZSBpZiBpdCBpcyB0aGUgaGlyaW5nIGFnZW5jeSB0aGF0IHBv
c3Qgam9icyBmb3Igb3RoZXIKIGVtcGxveWVycy4KCiBEZWZhdWx0cyB0byBmYWxzZSBpZiBu
b3QgcHJvdmlkZWQuCgoMCgUEAAIFBRIDUgIGCgwKBQQAAgUBEgNSBxQKDAoFBAACBQMSA1IX
GArDAQoEBAACBhIDWQIWGrUBIEVxdWFsIEVtcGxveW1lbnQgT3Bwb3J0dW5pdHkgbGVnYWwg
ZGlzY2xhaW1lciB0ZXh0IHRvIGJlCiBhc3NvY2lhdGVkIHdpdGggYWxsIGpvYnMsIGFuZCB0
eXBpY2FsbHkgdG8gYmUgZGlzcGxheWVkIGluIGFsbAogcm9sZXMuCgogVGhlIG1heGltdW0g
bnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyA1MDAuCgoMCgUEAAIGBRIDWQIICgwK
BQQAAgYBEgNZCREKDAoFBAACBgMSA1kUFQqsAQoEBAACBxIDXwIZGp4BIFRoZSBVUkkgcmVw
cmVzZW50aW5nIHRoZSBjb21wYW55J3MgcHJpbWFyeSB3ZWIgc2l0ZSBvciBob21lIHBhZ2Us
CiBmb3IgZXhhbXBsZSwgImh0dHBzOi8vd3d3Lmdvb2dsZS5jb20iLgoKIFRoZSBtYXhpbXVt
IG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMgaXMgMjU1LgoKDAoFBAACBwUSA18CCAoM
CgUEAAIHARIDXwkUCgwKBQQAAgcDEgNfFxgKiAEKBAQAAggSA2MCHRp7IFRoZSBVUkkgdG8g
ZW1wbG95ZXIncyBjYXJlZXIgc2l0ZSBvciBjYXJlZXJzIHBhZ2Ugb24gdGhlIGVtcGxveWVy
J3Mgd2ViCiBzaXRlLCBmb3IgZXhhbXBsZSwgImh0dHBzOi8vY2FyZWVycy5nb29nbGUuY29t
Ii4KCgwKBQQAAggFEgNjAggKDAoFBAACCAESA2MJGAoMCgUEAAIIAxIDYxscCjwKBAQAAgkS
A2YCGBovIEEgVVJJIHRoYXQgaG9zdHMgdGhlIGVtcGxveWVyJ3MgY29tcGFueSBsb2dvLgoK
DAoFBAACCQUSA2YCCAoMCgUEAAIJARIDZgkSCgwKBQQAAgkDEgNmFRcKggUKBAQAAgoSBHQC
dRoa8wQgVGhpcyBmaWVsZCBpcyBkZXByZWNhdGVkLiBQbGVhc2Ugc2V0IHRoZSBzZWFyY2hh
YmlsaXR5IG9mIHRoZSBjdXN0b20KIGF0dHJpYnV0ZSBpbiB0aGUKIFtKb2IuY3VzdG9tX2F0
dHJpYnV0ZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2IuY3VzdG9tX2F0dHJp
YnV0ZXNdCiBnb2luZyBmb3J3YXJkLgoKIEEgbGlzdCBvZiBrZXlzIG9mIGZpbHRlcmFibGUK
IFtKb2IuY3VzdG9tX2F0dHJpYnV0ZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5K
b2IuY3VzdG9tX2F0dHJpYnV0ZXNdLAogd2hvc2UgY29ycmVzcG9uZGluZyBgc3RyaW5nX3Zh
bHVlc2AgYXJlIHVzZWQgaW4ga2V5d29yZCBzZWFyY2hlcy4gSm9icyB3aXRoCiBgc3RyaW5n
X3ZhbHVlc2AgdW5kZXIgdGhlc2Ugc3BlY2lmaWVkIGZpZWxkIGtleXMgYXJlIHJldHVybmVk
IGlmIGFueQogb2YgdGhlIHZhbHVlcyBtYXRjaCB0aGUgc2VhcmNoIGtleXdvcmQuIEN1c3Rv
bSBmaWVsZCB2YWx1ZXMgd2l0aAogcGFyZW50aGVzaXMsIGJyYWNrZXRzIGFuZCBzcGVjaWFs
IHN5bWJvbHMgYXJlIG5vdCBzZWFyY2hhYmxlIGFzLWlzLAogYW5kIHRob3NlIGtleXdvcmQg
cXVlcmllcyBtdXN0IGJlIHN1cnJvdW5kZWQgYnkgcXVvdGVzLgoKDAoFBAACCgQSA3QCCgoM
CgUEAAIKBRIDdAsRCgwKBQQAAgoBEgN0EjoKDAoFBAACCgMSA3Q9PwoMCgUEAAIKCBIDdQYZ
Cg0KBgQAAgoIAxIDdQcYCj4KBAQAAgsSA3gCTBoxIE91dHB1dCBvbmx5LiBEZXJpdmVkIGRl
dGFpbHMgYWJvdXQgdGhlIGNvbXBhbnkuCgoMCgUEAAILBhIDeAINCgwKBQQAAgsBEgN4DhoK
DAoFBAACCwMSA3gdHwoMCgUEAAILCBIDeCBLCg8KCAQAAgsInAgAEgN4IUoKtgEKBAQAAgwS
A30CQhqoASBPdXRwdXQgb25seS4gSW5kaWNhdGVzIHdoZXRoZXIgYSBjb21wYW55IGlzIGZs
YWdnZWQgdG8gYmUgc3VzcGVuZGVkIGZyb20KIHB1YmxpYyBhdmFpbGFiaWxpdHkgYnkgdGhl
IHNlcnZpY2Ugd2hlbiBqb2IgY29udGVudCBhcHBlYXJzIHN1c3BpY2lvdXMsCiBhYnVzaXZl
LCBvciBzcGFtbXkuCgoMCgUEAAIMBRIDfQIGCgwKBQQAAgwBEgN9BxAKDAoFBAACDAMSA30T
FQoMCgUEAAIMCBIDfRZBCg8KCAQAAgwInAgAEgN9F0BiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::Company::Company ===
    # Fields for Company
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: external_id Type: 9 ()
    # Field: size Type: 14 (.google.cloud.talent.v4beta1.CompanySize)
    # Field: headquarters_address Type: 9 ()
    # Field: hiring_agency Type: 8 ()
    # Field: eeo_text Type: 9 ()
    # Field: website_uri Type: 9 ()
    # Field: career_site_uri Type: 9 ()
    # Field: image_uri Type: 9 ()
    # Field: keyword_searchable_job_custom_attributes Type: 9 ()
    # Field: derived_info Type: 11 (.google.cloud.talent.v4beta1.Company.DerivedInfo)
    # Field: suspended Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::Company - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/company.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::Company;

    my $msg = Google::Cloud::Talent::V4beta1::Company::Company->new({
        name => $name,
        display_name => $display_name,
        external_id => $external_id,
        size => $size,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::Company::Company->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/company.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::Company::Company

A Company resource represents a company in the service. A company is the
entity that owns job postings, that is, the hiring entity responsible for
employing applicants for the job position.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required during company update.

The resource name for a company. This is generated by the service when a
company is created.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/foo/tenants/bar/companies/baz".

If tenant id is unspecified, the default tenant is used. For
example, "projects/foo/companies/bar".

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the company, for example, "Google LLC".

=item * C<< $msg->external_id() >> / C<< $msg->external_id($value) >>

Type: C<String>

Required. Client side company identifier, used to uniquely identify the
company.

The maximum number of allowed characters is 255.

=item * C<< $msg->size() >> / C<< $msg->size($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::CompanySize>)

The employer's company size.

=item * C<< $msg->headquarters_address() >> / C<< $msg->headquarters_address($value) >>

Type: C<String>

The street address of the company's main headquarters, which may be
different from the job location. The service attempts
to geolocate the provided address, and populates a more specific
location wherever possible in
[DerivedInfo.headquarters_location][google.cloud.talent.v4beta1.Company.DerivedInfo.headquarters_location].

=item * C<< $msg->hiring_agency() >> / C<< $msg->hiring_agency($value) >>

Type: C<Bool>

Set to true if it is the hiring agency that post jobs for other
employers.

Defaults to false if not provided.

=item * C<< $msg->eeo_text() >> / C<< $msg->eeo_text($value) >>

Type: C<String>

Equal Employment Opportunity legal disclaimer text to be
associated with all jobs, and typically to be displayed in all
roles.

The maximum number of allowed characters is 500.

=item * C<< $msg->website_uri() >> / C<< $msg->website_uri($value) >>

Type: C<String>

The URI representing the company's primary web site or home page,
for example, "https://www.google.com".

The maximum number of allowed characters is 255.

=item * C<< $msg->career_site_uri() >> / C<< $msg->career_site_uri($value) >>

Type: C<String>

The URI to employer's career site or careers page on the employer's web
site, for example, "https://careers.google.com".

=item * C<< $msg->image_uri() >> / C<< $msg->image_uri($value) >>

Type: C<String>

A URI that hosts the employer's company logo.

=item * C<< $msg->keyword_searchable_job_custom_attributes() >> / C<< $msg->keyword_searchable_job_custom_attributes($value) >>

Type: C<String>

This field is deprecated. Please set the searchability of the custom
attribute in the
[Job.custom_attributes][google.cloud.talent.v4beta1.Job.custom_attributes]
going forward.

A list of keys of filterable
[Job.custom_attributes][google.cloud.talent.v4beta1.Job.custom_attributes],
whose corresponding `string_values` are used in keyword searches. Jobs with
`string_values` under these specified field keys are returned if any
of the values match the search keyword. Custom field values with
parenthesis, brackets and special symbols are not searchable as-is,
and those keyword queries must be surrounded by quotes.

=item * C<< $msg->derived_info() >> / C<< $msg->derived_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Company::Company::DerivedInfo>)

Output only. Derived details about the company.

=item * C<< $msg->suspended() >> / C<< $msg->suspended($value) >>

Type: C<Bool>

Output only. Indicates whether a company is flagged to be suspended from
public availability by the service when job content appears suspicious,
abusive, or spammy.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::Company::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
