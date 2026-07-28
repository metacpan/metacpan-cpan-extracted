package Google::Cloud::Dataplex::V1::Security;

use strict;
use warnings;

our $VERSION = '0.11';

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

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Security;

    my $msg = Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec->new(
        readers => $value,
    );

=head1 FIELDS

=over 4

=item * B<readers>

Type: String

=item * B<writers>

Type: String

=item * B<owners>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Security::DataAccessSpec ===
    # Fields for DataAccessSpec
    # Field: readers Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Security::DataAccessSpec - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Security;

    my $msg = Google::Cloud::Dataplex::V1::Security::DataAccessSpec->new(
        readers => $value,
    );

=head1 FIELDS

=over 4

=item * B<readers>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Security - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
