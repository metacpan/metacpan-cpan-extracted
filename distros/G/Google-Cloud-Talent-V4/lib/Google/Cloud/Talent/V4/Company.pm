package Google::Cloud::Talent::V4::Company;

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
    eval { require Google::Cloud::Talent::V4::Common };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2NvbXBhbnkucHJvdG8SFmdvb2dsZS5jbG91ZC50
YWxlbnQudjQaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC90YWxlbnQvdjQvY29tbW9uLnByb3RvIpIG
CgdDb21wYW55EhIKBG5hbWUYASABKAlSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPg
QQJSC2Rpc3BsYXlOYW1lEiQKC2V4dGVybmFsX2lkGAMgASgJQgPgQQJSCmV4dGVybmFsSWQS
NwoEc2l6ZRgEIAEoDjIjLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGFueVNpemVSBHNp
emUSMQoUaGVhZHF1YXJ0ZXJzX2FkZHJlc3MYBSABKAlSE2hlYWRxdWFydGVyc0FkZHJlc3MS
IwoNaGlyaW5nX2FnZW5jeRgGIAEoCFIMaGlyaW5nQWdlbmN5EhkKCGVlb190ZXh0GAcgASgJ
UgdlZW9UZXh0Eh8KC3dlYnNpdGVfdXJpGAggASgJUgp3ZWJzaXRlVXJpEiYKD2NhcmVlcl9z
aXRlX3VyaRgJIAEoCVINY2FyZWVyU2l0ZVVyaRIbCglpbWFnZV91cmkYCiABKAlSCGltYWdl
VXJpEloKKGtleXdvcmRfc2VhcmNoYWJsZV9qb2JfY3VzdG9tX2F0dHJpYnV0ZXMYCyADKAlC
AhgBUiRrZXl3b3JkU2VhcmNoYWJsZUpvYkN1c3RvbUF0dHJpYnV0ZXMSUwoMZGVyaXZlZF9p
bmZvGAwgASgLMisuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Db21wYW55LkRlcml2ZWRJbmZv
QgPgQQNSC2Rlcml2ZWRJbmZvEiEKCXN1c3BlbmRlZBgNIAEoCEID4EEDUglzdXNwZW5kZWQa
ZAoLRGVyaXZlZEluZm8SVQoVaGVhZHF1YXJ0ZXJzX2xvY2F0aW9uGAEgASgLMiAuZ29vZ2xl
LmNsb3VkLnRhbGVudC52NC5Mb2NhdGlvblIUaGVhZHF1YXJ0ZXJzTG9jYXRpb246WepBVgob
am9icy5nb29nbGVhcGlzLmNvbS9Db21wYW55Ejdwcm9qZWN0cy97cHJvamVjdH0vdGVuYW50
cy97dGVuYW50fS9jb21wYW5pZXMve2NvbXBhbnl9QmYKGmNvbS5nb29nbGUuY2xvdWQudGFs
ZW50LnY0QgxDb21wYW55UHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBp
djQvdGFsZW50cGI7dGFsZW50cGKiAgNDVFNKiSMKBhIEDgB6AQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQALQoICgEIEgMWAEkKCQoCCAsSAxYASQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEI
EgMYAC0KCQoCCAgSAxgALQoICgEIEgMZADMKCQoCCAESAxkAMwoICgEIEgMaACEKCQoCCCQS
AxoAIQrOAQoCBAASBB8AegEawQEgQSBDb21wYW55IHJlc291cmNlIHJlcHJlc2VudHMgYSBj
b21wYW55IGluIHRoZSBzZXJ2aWNlLiBBIGNvbXBhbnkgaXMgdGhlCiBlbnRpdHkgdGhhdCBv
d25zIGpvYiBwb3N0aW5ncywgdGhhdCBpcywgdGhlIGhpcmluZyBlbnRpdHkgcmVzcG9uc2li
bGUgZm9yCiBlbXBsb3lpbmcgYXBwbGljYW50cyBmb3IgdGhlIGpvYiBwb3NpdGlvbi4KCgoK
AwQAARIDHwgPCgsKAwQABxIEIAIjBAoNCgUEAAedCBIEIAIjBAoyCgQEAAMAEgQmAisDGiQg
RGVyaXZlZCBkZXRhaWxzIGFib3V0IHRoZSBjb21wYW55LgoKDAoFBAADAAESAyYKFQq1AQoG
BAADAAIAEgMqBCcapQEgQSBzdHJ1Y3R1cmVkIGhlYWRxdWFydGVycyBsb2NhdGlvbiBvZiB0
aGUgY29tcGFueSwgcmVzb2x2ZWQgZnJvbQogW0NvbXBhbnkuaGVhZHF1YXJ0ZXJzX2FkZHJl
c3NdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGFueS5oZWFkcXVhcnRlcnNfYWRkcmVz
c10KIGlmIHByb3ZpZGVkLgoKDgoHBAADAAIABhIDKgQMCg4KBwQAAwACAAESAyoNIgoOCgcE
AAMAAgADEgMqJSYKnAIKBAQAAgASAzUCEhqOAiBSZXF1aXJlZCBkdXJpbmcgY29tcGFueSB1
cGRhdGUuCgogVGhlIHJlc291cmNlIG5hbWUgZm9yIGEgY29tcGFueS4gVGhpcyBpcyBnZW5l
cmF0ZWQgYnkgdGhlIHNlcnZpY2Ugd2hlbiBhCiBjb21wYW55IGlzIGNyZWF0ZWQuCgogVGhl
IGZvcm1hdCBpcwogInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9
L2NvbXBhbmllcy97Y29tcGFueV9pZH0iLCBmb3IKIGV4YW1wbGUsICJwcm9qZWN0cy9mb28v
dGVuYW50cy9iYXIvY29tcGFuaWVzL2JheiIuCgoMCgUEAAIABRIDNQIICgwKBQQAAgABEgM1
CQ0KDAoFBAACAAMSAzUQEQpUCgQEAAIBEgM4AkMaRyBSZXF1aXJlZC4gVGhlIGRpc3BsYXkg
bmFtZSBvZiB0aGUgY29tcGFueSwgZm9yIGV4YW1wbGUsICJHb29nbGUgTExDIi4KCgwKBQQA
AgEFEgM4AggKDAoFBAACAQESAzgJFQoMCgUEAAIBAxIDOBgZCgwKBQQAAgEIEgM4GkIKDwoI
BAACAQicCAASAzgbQQqUAQoEBAACAhIDPgJCGoYBIFJlcXVpcmVkLiBDbGllbnQgc2lkZSBj
b21wYW55IGlkZW50aWZpZXIsIHVzZWQgdG8gdW5pcXVlbHkgaWRlbnRpZnkgdGhlCiBjb21w
YW55LgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMgaXMgMjU1
LgoKDAoFBAACAgUSAz4CCAoMCgUEAAICARIDPgkUCgwKBQQAAgIDEgM+FxgKDAoFBAACAggS
Az4ZQQoPCggEAAICCJwIABIDPhpACisKBAQAAgMSA0ECFxoeIFRoZSBlbXBsb3llcidzIGNv
bXBhbnkgc2l6ZS4KCgwKBQQAAgMGEgNBAg0KDAoFBAACAwESA0EOEgoMCgUEAAIDAxIDQRUW
CtMCCgQEAAIEEgNIAiIaxQIgVGhlIHN0cmVldCBhZGRyZXNzIG9mIHRoZSBjb21wYW55J3Mg
bWFpbiBoZWFkcXVhcnRlcnMsIHdoaWNoIG1heSBiZQogZGlmZmVyZW50IGZyb20gdGhlIGpv
YiBsb2NhdGlvbi4gVGhlIHNlcnZpY2UgYXR0ZW1wdHMKIHRvIGdlb2xvY2F0ZSB0aGUgcHJv
dmlkZWQgYWRkcmVzcywgYW5kIHBvcHVsYXRlcyBhIG1vcmUgc3BlY2lmaWMKIGxvY2F0aW9u
IHdoZXJldmVyIHBvc3NpYmxlIGluCiBbRGVyaXZlZEluZm8uaGVhZHF1YXJ0ZXJzX2xvY2F0
aW9uXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBhbnkuRGVyaXZlZEluZm8uaGVhZHF1
YXJ0ZXJzX2xvY2F0aW9uXS4KCgwKBQQAAgQFEgNIAggKDAoFBAACBAESA0gJHQoMCgUEAAIE
AxIDSCAhCn8KBAQAAgUSA04CGRpyIFNldCB0byB0cnVlIGlmIGl0IGlzIHRoZSBoaXJpbmcg
YWdlbmN5IHRoYXQgcG9zdCBqb2JzIGZvciBvdGhlcgogZW1wbG95ZXJzLgoKIERlZmF1bHRz
IHRvIGZhbHNlIGlmIG5vdCBwcm92aWRlZC4KCgwKBQQAAgUFEgNOAgYKDAoFBAACBQESA04H
FAoMCgUEAAIFAxIDThcYCsMBCgQEAAIGEgNVAhYatQEgRXF1YWwgRW1wbG95bWVudCBPcHBv
cnR1bml0eSBsZWdhbCBkaXNjbGFpbWVyIHRleHQgdG8gYmUKIGFzc29jaWF0ZWQgd2l0aCBh
bGwgam9icywgYW5kIHR5cGljYWxseSB0byBiZSBkaXNwbGF5ZWQgaW4gYWxsCiByb2xlcy4K
CiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDUwMC4KCgwK
BQQAAgYFEgNVAggKDAoFBAACBgESA1UJEQoMCgUEAAIGAxIDVRQVCqwBCgQEAAIHEgNbAhka
ngEgVGhlIFVSSSByZXByZXNlbnRpbmcgdGhlIGNvbXBhbnkncyBwcmltYXJ5IHdlYiBzaXRl
IG9yIGhvbWUgcGFnZSwKIGZvciBleGFtcGxlLCAiaHR0cHM6Ly93d3cuZ29vZ2xlLmNvbSIu
CgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAyNTUuCgoM
CgUEAAIHBRIDWwIICgwKBQQAAgcBEgNbCRQKDAoFBAACBwMSA1sXGAqIAQoEBAACCBIDXwId
GnsgVGhlIFVSSSB0byBlbXBsb3llcidzIGNhcmVlciBzaXRlIG9yIGNhcmVlcnMgcGFnZSBv
biB0aGUgZW1wbG95ZXIncyB3ZWIKIHNpdGUsIGZvciBleGFtcGxlLCAiaHR0cHM6Ly9jYXJl
ZXJzLmdvb2dsZS5jb20iLgoKDAoFBAACCAUSA18CCAoMCgUEAAIIARIDXwkYCgwKBQQAAggD
EgNfGxwKPAoEBAACCRIDYgIYGi8gQSBVUkkgdGhhdCBob3N0cyB0aGUgZW1wbG95ZXIncyBj
b21wYW55IGxvZ28uCgoMCgUEAAIJBRIDYgIICgwKBQQAAgkBEgNiCRIKDAoFBAACCQMSA2IV
Fwr4BAoEBAACChIEcAJxGhrpBCBUaGlzIGZpZWxkIGlzIGRlcHJlY2F0ZWQuIFBsZWFzZSBz
ZXQgdGhlIHNlYXJjaGFiaWxpdHkgb2YgdGhlIGN1c3RvbQogYXR0cmlidXRlIGluIHRoZQog
W0pvYi5jdXN0b21fYXR0cmlidXRlc11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuY3Vz
dG9tX2F0dHJpYnV0ZXNdIGdvaW5nCiBmb3J3YXJkLgoKIEEgbGlzdCBvZiBrZXlzIG9mIGZp
bHRlcmFibGUKIFtKb2IuY3VzdG9tX2F0dHJpYnV0ZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQu
djQuSm9iLmN1c3RvbV9hdHRyaWJ1dGVzXSwKIHdob3NlIGNvcnJlc3BvbmRpbmcgYHN0cmlu
Z192YWx1ZXNgIGFyZSB1c2VkIGluIGtleXdvcmQgc2VhcmNoZXMuIEpvYnMgd2l0aAogYHN0
cmluZ192YWx1ZXNgIHVuZGVyIHRoZXNlIHNwZWNpZmllZCBmaWVsZCBrZXlzIGFyZSByZXR1
cm5lZCBpZiBhbnkKIG9mIHRoZSB2YWx1ZXMgbWF0Y2ggdGhlIHNlYXJjaCBrZXl3b3JkLiBD
dXN0b20gZmllbGQgdmFsdWVzIHdpdGgKIHBhcmVudGhlc2lzLCBicmFja2V0cyBhbmQgc3Bl
Y2lhbCBzeW1ib2xzIGFyZSBub3Qgc2VhcmNoYWJsZSBhcy1pcywKIGFuZCB0aG9zZSBrZXl3
b3JkIHF1ZXJpZXMgbXVzdCBiZSBzdXJyb3VuZGVkIGJ5IHF1b3Rlcy4KCgwKBQQAAgoEEgNw
AgoKDAoFBAACCgUSA3ALEQoMCgUEAAIKARIDcBI6CgwKBQQAAgoDEgNwPT8KDAoFBAACCggS
A3EGGQoNCgYEAAIKCAMSA3EHGAo+CgQEAAILEgN0AkwaMSBPdXRwdXQgb25seS4gRGVyaXZl
ZCBkZXRhaWxzIGFib3V0IHRoZSBjb21wYW55LgoKDAoFBAACCwYSA3QCDQoMCgUEAAILARID
dA4aCgwKBQQAAgsDEgN0HR8KDAoFBAACCwgSA3QgSwoPCggEAAILCJwIABIDdCFKCrYBCgQE
AAIMEgN5AkIaqAEgT3V0cHV0IG9ubHkuIEluZGljYXRlcyB3aGV0aGVyIGEgY29tcGFueSBp
cyBmbGFnZ2VkIHRvIGJlIHN1c3BlbmRlZCBmcm9tCiBwdWJsaWMgYXZhaWxhYmlsaXR5IGJ5
IHRoZSBzZXJ2aWNlIHdoZW4gam9iIGNvbnRlbnQgYXBwZWFycyBzdXNwaWNpb3VzLAogYWJ1
c2l2ZSwgb3Igc3BhbW15LgoKDAoFBAACDAUSA3kCBgoMCgUEAAIMARIDeQcQCgwKBQQAAgwD
EgN5ExUKDAoFBAACDAgSA3kWQQoPCggEAAIMCJwIABIDeRdAYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::Company::Company ===
    # Fields for Company
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: external_id Type: 9 ()
    # Field: size Type: 14 (.google.cloud.talent.v4.CompanySize)
    # Field: headquarters_address Type: 9 ()
    # Field: hiring_agency Type: 8 ()
    # Field: eeo_text Type: 9 ()
    # Field: website_uri Type: 9 ()
    # Field: career_site_uri Type: 9 ()
    # Field: image_uri Type: 9 ()
    # Field: keyword_searchable_job_custom_attributes Type: 9 ()
    # Field: derived_info Type: 11 (.google.cloud.talent.v4.Company.DerivedInfo)
    # Field: suspended Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::Company - Compiled Protocol Buffers messages for google/cloud/talent/v4/company.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::Company;

    my $msg = Google::Cloud::Talent::V4::Company::Company->new({
        name => $name,
        display_name => $display_name,
        external_id => $external_id,
        size => $size,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::Company::Company->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/company.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::Company::Company

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

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the company, for example, "Google LLC".

=item * C<< $msg->external_id() >> / C<< $msg->external_id($value) >>

Type: C<String>

Required. Client side company identifier, used to uniquely identify the
company.

The maximum number of allowed characters is 255.

=item * C<< $msg->size() >> / C<< $msg->size($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CompanySize>)

The employer's company size.

=item * C<< $msg->headquarters_address() >> / C<< $msg->headquarters_address($value) >>

Type: C<String>

The street address of the company's main headquarters, which may be
different from the job location. The service attempts
to geolocate the provided address, and populates a more specific
location wherever possible in
[DerivedInfo.headquarters_location][google.cloud.talent.v4.Company.DerivedInfo.headquarters_location].

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
[Job.custom_attributes][google.cloud.talent.v4.Job.custom_attributes] going
forward.

A list of keys of filterable
[Job.custom_attributes][google.cloud.talent.v4.Job.custom_attributes],
whose corresponding `string_values` are used in keyword searches. Jobs with
`string_values` under these specified field keys are returned if any
of the values match the search keyword. Custom field values with
parenthesis, brackets and special symbols are not searchable as-is,
and those keyword queries must be surrounded by quotes.

=item * C<< $msg->derived_info() >> / C<< $msg->derived_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Company::Company::DerivedInfo>)

Output only. Derived details about the company.

=item * C<< $msg->suspended() >> / C<< $msg->suspended($value) >>

Type: C<Bool>

Output only. Indicates whether a company is flagged to be suspended from
public availability by the service when job content appears suspicious,
abusive, or spammy.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::Company::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
