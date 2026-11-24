package Google::Cloud::Dataplex::V1::Security;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvZGF0YXBsZXgvdjEvc2VjdXJpdHkucHJvdG8SGGdvb2dsZS5jbG91
ZC5kYXRhcGxleC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byJvChJSZXNv
dXJjZUFjY2Vzc1NwZWMSHQoHcmVhZGVycxgBIAMoCUID4EEBUgdyZWFkZXJzEh0KB3dyaXRl
cnMYAiADKAlCA+BBAVIHd3JpdGVycxIbCgZvd25lcnMYAyADKAlCA+BBAVIGb3duZXJzIi8K
DkRhdGFBY2Nlc3NTcGVjEh0KB3JlYWRlcnMYASADKAlCA+BBAVIHcmVhZGVyc0JpChxjb20u
Z29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxQg1TZWN1cml0eVByb3RvUAFaOGNsb3VkLmdvb2ds
ZS5jb20vZ28vZGF0YXBsZXgvYXBpdjEvZGF0YXBsZXhwYjtkYXRhcGxleHBiSssRCgYSBA4A
NAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwAS
AxIAKQoICgEIEgMUAE8KCQoCCAsSAxQATwoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMW
AC4KCQoCCAgSAxYALgoICgEIEgMXADUKCQoCCAESAxcANQqwAQoCBAASBBwAJwEaowEgUmVz
b3VyY2VBY2Nlc3NTcGVjIGhvbGRzIHRoZSBhY2Nlc3MgY29udHJvbCBjb25maWd1cmF0aW9u
IHRvIGJlIGVuZm9yY2VkCiBvbiB0aGUgcmVzb3VyY2VzLCBmb3IgZXhhbXBsZSwgQ2xvdWQg
U3RvcmFnZSBidWNrZXQsIEJpZ1F1ZXJ5IGRhdGFzZXQsCiBCaWdRdWVyeSB0YWJsZS4KCgoK
AwQAARIDHAgaCtsBCgQEAAIAEgMgAkcazQEgT3B0aW9uYWwuIFRoZSBmb3JtYXQgb2Ygc3Ry
aW5ncyBmb2xsb3dzIHRoZSBwYXR0ZXJuIGZvbGxvd2VkIGJ5IElBTSBpbiB0aGUKIGJpbmRp
bmdzLiB1c2VyOntlbWFpbH0sIHNlcnZpY2VBY2NvdW50OntlbWFpbH0gZ3JvdXA6e2VtYWls
fS4KIFRoZSBzZXQgb2YgcHJpbmNpcGFscyB0byBiZSBncmFudGVkIHJlYWRlciByb2xlIG9u
IHRoZSByZXNvdXJjZS4KCgwKBQQAAgAEEgMgAgoKDAoFBAACAAUSAyALEQoMCgUEAAIAARID
IBIZCgwKBQQAAgADEgMgHB0KDAoFBAACAAgSAyAeRgoPCggEAAIACJwIABIDIB9FClkKBAQA
AgESAyMCRxpMIE9wdGlvbmFsLiBUaGUgc2V0IG9mIHByaW5jaXBhbHMgdG8gYmUgZ3JhbnRl
ZCB3cml0ZXIgcm9sZSBvbiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIBBBIDIwIKCgwKBQQAAgEF
EgMjCxEKDAoFBAACAQESAyMSGQoMCgUEAAIBAxIDIxwdCgwKBQQAAgEIEgMjHkYKDwoIBAAC
AQicCAASAyMfRQpYCgQEAAICEgMmAkYaSyBPcHRpb25hbC4gVGhlIHNldCBvZiBwcmluY2lw
YWxzIHRvIGJlIGdyYW50ZWQgb3duZXIgcm9sZSBvbiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIC
BBIDJgIKCgwKBQQAAgIFEgMmCxEKDAoFBAACAgESAyYSGAoMCgUEAAICAxIDJhscCgwKBQQA
AgIIEgMmHUUKDwoIBAACAgicCAASAyYeRArvAgoCBAESBC4ANAEa4gIgRGF0YUFjY2Vzc1Nw
ZWMgaG9sZHMgdGhlIGFjY2VzcyBjb250cm9sIGNvbmZpZ3VyYXRpb24gdG8gYmUgZW5mb3Jj
ZWQgb24gZGF0YQogc3RvcmVkIHdpdGhpbiByZXNvdXJjZXMgKGVnOiByb3dzLCBjb2x1bW5z
IGluIEJpZ1F1ZXJ5IFRhYmxlcykuIFdoZW4KIGFzc29jaWF0ZWQgd2l0aCBkYXRhLCB0aGUg
ZGF0YSBpcyBvbmx5IGFjY2Vzc2libGUgdG8KIHByaW5jaXBhbHMgZXhwbGljaXRseSBncmFu
dGVkIGFjY2VzcyB0aHJvdWdoIHRoZSBEYXRhQWNjZXNzU3BlYy4gUHJpbmNpcGFscwogd2l0
aCBhY2Nlc3MgdG8gdGhlIGNvbnRhaW5pbmcgcmVzb3VyY2UgYXJlIG5vdCBpbXBsaWNpdGx5
IGdyYW50ZWQgYWNjZXNzLgoKCgoDBAEBEgMuCBYK7AEKBAQBAgASAzMCRxreASBPcHRpb25h
bC4gVGhlIGZvcm1hdCBvZiBzdHJpbmdzIGZvbGxvd3MgdGhlIHBhdHRlcm4gZm9sbG93ZWQg
YnkgSUFNIGluIHRoZQogYmluZGluZ3MuIHVzZXI6e2VtYWlsfSwgc2VydmljZUFjY291bnQ6
e2VtYWlsfSBncm91cDp7ZW1haWx9LgogVGhlIHNldCBvZiBwcmluY2lwYWxzIHRvIGJlIGdy
YW50ZWQgcmVhZGVyIHJvbGUgb24gZGF0YQogc3RvcmVkIHdpdGhpbiByZXNvdXJjZXMuCgoM
CgUEAQIABBIDMwIKCgwKBQQBAgAFEgMzCxEKDAoFBAECAAESAzMSGQoMCgUEAQIAAxIDMxwd
CgwKBQQBAgAIEgMzHkYKDwoIBAECAAicCAASAzMfRWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec ===
    # Fields for ResourceAccessSpec
    # Field: readers Type: 9 ()
    # Field: writers Type: 9 ()
    # Field: owners Type: 9 ()

# === Message: Google::Cloud::Dataplex::V1::Security::DataAccessSpec ===
    # Fields for DataAccessSpec
    # Field: readers Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataplex::V1::Security - Compiled Protocol Buffers messages for google/cloud/dataplex/v1/security.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Security;

    my $msg = Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec->new({
        readers => $readers,
        writers => $writers,
        owners => $owners,
    });

    # Read or update a field
    my $val = $msg->readers();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataplex/v1/security.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec

ResourceAccessSpec holds the access control configuration to be enforced
on the resources, for example, Cloud Storage bucket, BigQuery dataset,
BigQuery table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->readers() >> / C<< $msg->readers($value) >>

Type: C<String>

Optional. The format of strings follows the pattern followed by IAM in the
bindings. user:{email}, serviceAccount:{email} group:{email}.
The set of principals to be granted reader role on the resource.

=item * C<< $msg->writers() >> / C<< $msg->writers($value) >>

Type: C<String>

Optional. The set of principals to be granted writer role on the resource.

=item * C<< $msg->owners() >> / C<< $msg->owners($value) >>

Type: C<String>

Optional. The set of principals to be granted owner role on the resource.

=back

=head2 Google::Cloud::Dataplex::V1::Security::DataAccessSpec

DataAccessSpec holds the access control configuration to be enforced on data
stored within resources (eg: rows, columns in BigQuery Tables). When
associated with data, the data is only accessible to
principals explicitly granted access through the DataAccessSpec. Principals
with access to the containing resource are not implicitly granted access.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->readers() >> / C<< $msg->readers($value) >>

Type: C<String>

Optional. The format of strings follows the pattern followed by IAM in the
bindings. user:{email}, serviceAccount:{email} group:{email}.
The set of principals to be granted reader role on data
stored within resources.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataplex::V1::Security::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
