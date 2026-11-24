package Google::Cloud::Discoveryengine::V1alpha::Project;

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
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvcHJvamVjdC5wcm90bxIk
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIuEGCgdQcm9qZWN0EhcKBG5hbWUYASABKAlCA+BBA1IE
bmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRJbChlwcm92aXNpb25fY29tcGxldGlvbl90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhdwcm92aXNpb25Db21wbGV0aW9uVGlt
ZRJzChFzZXJ2aWNlX3Rlcm1zX21hcBgEIAMoCzJCLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5Qcm9qZWN0LlNlcnZpY2VUZXJtc01hcEVudHJ5QgPgQQNSD3NlcnZp
Y2VUZXJtc01hcBrnAgoMU2VydmljZVRlcm1zEg4KAmlkGAEgASgJUgJpZBIYCgd2ZXJzaW9u
GAIgASgJUgd2ZXJzaW9uElYKBXN0YXRlGAQgASgOMkAuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlByb2plY3QuU2VydmljZVRlcm1zLlN0YXRlUgVzdGF0ZRI7Cgth
Y2NlcHRfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmFjY2VwdFRp
bWUSPQoMZGVjbGluZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIL
ZGVjbGluZVRpbWUiWQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABISCg5URVJNU19B
Q0NFUFRFRBABEhEKDVRFUk1TX1BFTkRJTkcQAhISCg5URVJNU19ERUNMSU5FRBADGn4KFFNl
cnZpY2VUZXJtc01hcEVudHJ5EhAKA2tleRgBIAEoCVIDa2V5ElAKBXZhbHVlGAIgASgLMjou
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlByb2plY3QuU2VydmljZVRl
cm1zUgV2YWx1ZToCOAE6P+pBPAomZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1By
b2plY3QSEnByb2plY3RzL3twcm9qZWN0fUKYAgooY29tLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYUIMUHJvamVjdFByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28v
ZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5
ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5n
aW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidH
b29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFK0BsKBhIEDgBmAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAGkKCQoC
CAsSAxcAaQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC0KCQoCCAgSAxkALQoICgEI
EgMaAEEKCQoCCAESAxoAQQoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEIEgMcAEEKCQoCCCkS
AxwAQQoICgEIEgMdAEAKCQoCCC0SAx0AQApUCgIEABIEIABmARpIIE1ldGFkYXRhIGFuZCBj
b25maWd1cmF0aW9ucyBmb3IgYSBHb29nbGUgQ2xvdWQgcHJvamVjdCBpbiB0aGUgc2Vydmlj
ZS4KCgoKAwQAARIDIAgPCgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBAo0CgQEAAMAEgQn
AlADGiYgTWV0YWRhdGEgYWJvdXQgdGhlIHRlcm1zIG9mIHNlcnZpY2UuCgoMCgUEAAMAARID
JwoWCj0KBgQAAwAEABIEKQQ1BRotIFRoZSBhZ3JlZW1lbnQgc3RhdGVzIHRoaXMgdGVybXMg
b2Ygc2VydmljZS4KCg4KBwQAAwAEAAESAykJDgpSCggEAAMABAACABIDKwYcGkEgVGhlIGRl
ZmF1bHQgdmFsdWUgb2YgdGhlIGVudW0uIFRoaXMgdmFsdWUgaXMgbm90IGFjdHVhbGx5IHVz
ZWQuCgoQCgkEAAMABAACAAESAysGFwoQCgkEAAMABAACAAISAysaGwpJCggEAAMABAACARID
LgYZGjggVGhlIHByb2plY3QgaGFzIGdpdmVuIGNvbnNlbnQgdG8gdGhlIHRlcm1zIG9mIHNl
cnZpY2UuCgoQCgkEAAMABAACAQESAy4GFAoQCgkEAAMABAACAQISAy4XGApUCggEAAMABAAC
AhIDMQYYGkMgVGhlIHByb2plY3QgaXMgcGVuZGluZyB0byByZXZpZXcgYW5kIGFjY2VwdCB0
aGUgdGVybXMgb2Ygc2VydmljZS4KChAKCQQAAwAEAAICARIDMQYTChAKCQQAAwAEAAICAhID
MRYXClkKCAQAAwAEAAIDEgM0BhkaSCBUaGUgcHJvamVjdCBoYXMgZGVjbGluZWQgb3IgcmV2
b2tlZCB0aGUgYWdyZWVtZW50IHRvIHRlcm1zIG9mIHNlcnZpY2UuCgoQCgkEAAMABAACAwES
AzQGFAoQCgkEAAMABAACAwISAzQXGArHAgoGBAADAAIAEgM/BBIatwIgVGhlIHVuaXF1ZSBp
ZGVudGlmaWVyIG9mIHRoaXMgdGVybXMgb2Ygc2VydmljZS4KIEF2YWlsYWJsZSB0ZXJtczoK
CiAqIGBHQV9EQVRBX1VTRV9URVJNU2A6IFtUZXJtcyBmb3IgZGF0YQogdXNlXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RhdGEtdXNlLXRlcm1zKS4gV2hlbiB1c2luZyB0
aGlzIGFzCiBgaWRgLCB0aGUgYWNjZXB0YWJsZQogW3ZlcnNpb25dW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Qcm9qZWN0LlNlcnZpY2VUZXJtcy52ZXJzaW9uXQog
dG8gcHJvdmlkZSBpcyBgMjAyMi0xMS0yM2AuCgoOCgcEAAMAAgAFEgM/BAoKDgoHBAADAAIA
ARIDPwsNCg4KBwQAAwACAAMSAz8QEQq1AQoGBAADAAIBEgNEBBcapQEgVGhlIHZlcnNpb24g
c3RyaW5nIG9mIHRoZSB0ZXJtcyBvZiBzZXJ2aWNlLgogRm9yIGFjY2VwdGFibGUgdmFsdWVz
LCBzZWUgdGhlIGNvbW1lbnRzIGZvcgogW2lkXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuUHJvamVjdC5TZXJ2aWNlVGVybXMuaWRdIGFib3ZlLgoKDgoHBAADAAIB
BRIDRAQKCg4KBwQAAwACAQESA0QLEgoOCgcEAAMAAgEDEgNEFRYKZQoGBAADAAICEgNIBBQa
ViBXaGV0aGVyIHRoZSBwcm9qZWN0IGhhcyBhY2NlcHRlZC9yZWplY3RlZCB0aGUgc2Vydmlj
ZSB0ZXJtcyBvciBpdCBpcwogc3RpbGwgcGVuZGluZy4KCg4KBwQAAwACAgYSA0gECQoOCgcE
AAMAAgIBEgNICg8KDgoHBAADAAICAxIDSBITCk8KBgQAAwACAxIDSwQuGkAgVGhlIGxhc3Qg
dGltZSB3aGVuIHRoZSBwcm9qZWN0IGFncmVlZCB0byB0aGUgdGVybXMgb2Ygc2VydmljZS4K
Cg4KBwQAAwACAwYSA0sEHQoOCgcEAAMAAgMBEgNLHikKDgoHBAADAAIDAxIDSywtCmcKBgQA
AwACBBIDTwQvGlggVGhlIGxhc3QgdGltZSB3aGVuIHRoZSBwcm9qZWN0IGRlY2xpbmVkIG9y
IHJldm9rZWQgdGhlIGFncmVlbWVudCB0byB0ZXJtcwogb2Ygc2VydmljZS4KCg4KBwQAAwAC
BAYSA08EHQoOCgcEAAMAAgQBEgNPHioKDgoHBAADAAIEAxIDTy0uCvQBCgQEAAIAEgNWAj4a
5gEgT3V0cHV0IG9ubHkuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJvamVjdCwgZm9y
IGV4YW1wbGUKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9YC4KIE5vdGUgdGhhdCB3aGVu
IG1ha2luZyByZXF1ZXN0cywgcHJvamVjdCBudW1iZXIgYW5kIHByb2plY3QgaWQgYXJlIGJv
dGgKIGFjY2VwdGFibGUsIGJ1dCB0aGUgc2VydmVyIHdpbGwgYWx3YXlzIHJlc3BvbmQgaW4g
cHJvamVjdCBudW1iZXIuCgoMCgUEAAIABRIDVgIICgwKBQQAAgABEgNWCQ0KDAoFBAACAAMS
A1YQEQoMCgUEAAIACBIDVhI9Cg8KCAQAAgAInAgAEgNWEzwKSAoEBAACARIEWQJaMho6IE91
dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBwcm9qZWN0IGlzIGNyZWF0ZWQu
CgoMCgUEAAIBBhIDWQIbCgwKBQQAAgEBEgNZHCcKDAoFBAACAQMSA1kqKwoMCgUEAAIBCBID
WgYxCg8KCAQAAgEInAgAEgNaBzAKqwEKBAQAAgISBF8CYDIanAEgT3V0cHV0IG9ubHkuIFRo
ZSB0aW1lc3RhbXAgd2hlbiB0aGlzIHByb2plY3QgaXMgc3VjY2Vzc2Z1bGx5IHByb3Zpc2lv
bmVkLgogRW1wdHkgdmFsdWUgbWVhbnMgdGhpcyBwcm9qZWN0IGlzIHN0aWxsIHByb3Zpc2lv
bmluZyBhbmQgaXMgbm90IHJlYWR5IGZvcgogdXNlLgoKDAoFBAACAgYSA18CGwoMCgUEAAIC
ARIDXxw1CgwKBQQAAgIDEgNfODkKDAoFBAACAggSA2AGMQoPCggEAAICCJwIABIDYAcwCpwB
CgQEAAIDEgRkAmUyGo0BIE91dHB1dCBvbmx5LiBBIG1hcCBvZiB0ZXJtcyBvZiBzZXJ2aWNl
cy4gVGhlIGtleSBpcyB0aGUgYGlkYCBvZgogW1NlcnZpY2VUZXJtc11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlByb2plY3QuU2VydmljZVRlcm1zXS4KCgwKBQQA
AgMGEgNkAhsKDAoFBAACAwESA2QcLQoMCgUEAAIDAxIDZDAxCgwKBQQAAgMIEgNlBjEKDwoI
BAACAwicCAASA2UHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Project::Project ===
    # Fields for Project
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: provision_completion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: service_terms_map Type: 11 (.google.cloud.discoveryengine.v1alpha.Project.ServiceTermsMapEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Project - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/project.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Project;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Project::Project->new({
        name => $name,
        create_time => $create_time,
        provision_completion_time => $provision_completion_time,
        service_terms_map => $service_terms_map,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Project::Project->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/project.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Project::Project

Metadata and configurations for a Google Cloud project in the service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Full resource name of the project, for example
`projects/{project_number}`.
Note that when making requests, project number and project id are both
acceptable, but the server will always respond in project number.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this project is created.

=item * C<< $msg->provision_completion_time() >> / C<< $msg->provision_completion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this project is successfully provisioned.
Empty value means this project is still provisioning and is not ready for
use.

=item * C<< $msg->service_terms_map() >> / C<< $msg->service_terms_map($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Project::Project::ServiceTermsMapEntry>)

Output only. A map of terms of services. The key is the `id` of
[ServiceTerms][google.cloud.discoveryengine.v1alpha.Project.ServiceTerms].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Project::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
