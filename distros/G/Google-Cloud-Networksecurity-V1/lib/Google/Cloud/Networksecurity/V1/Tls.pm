package Google::Cloud::Networksecurity::V1::Tls;

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
Cilnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL3Rscy5wcm90bxIfZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZWN1cml0eS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
byIyCgxHcnBjRW5kcG9pbnQSIgoKdGFyZ2V0X3VyaRgBIAEoCUID4EECUgl0YXJnZXRVcmki
8QEKDFZhbGlkYXRpb25DQRJUCg1ncnBjX2VuZHBvaW50GAIgASgLMi0uZ29vZ2xlLmNsb3Vk
Lm5ldHdvcmtzZWN1cml0eS52MS5HcnBjRW5kcG9pbnRIAFIMZ3JwY0VuZHBvaW50EoIBCh1j
ZXJ0aWZpY2F0ZV9wcm92aWRlcl9pbnN0YW5jZRgDIAEoCzI8Lmdvb2dsZS5jbG91ZC5uZXR3
b3Jrc2VjdXJpdHkudjEuQ2VydGlmaWNhdGVQcm92aWRlckluc3RhbmNlSABSG2NlcnRpZmlj
YXRlUHJvdmlkZXJJbnN0YW5jZUIGCgR0eXBlIksKG0NlcnRpZmljYXRlUHJvdmlkZXJJbnN0
YW5jZRIsCg9wbHVnaW5faW5zdGFuY2UYASABKAlCA+BBAlIOcGx1Z2luSW5zdGFuY2Ui+AEK
E0NlcnRpZmljYXRlUHJvdmlkZXISVAoNZ3JwY19lbmRwb2ludBgCIAEoCzItLmdvb2dsZS5j
bG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuR3JwY0VuZHBvaW50SABSDGdycGNFbmRwb2ludBKC
AQodY2VydGlmaWNhdGVfcHJvdmlkZXJfaW5zdGFuY2UYAyABKAsyPC5nb29nbGUuY2xvdWQu
bmV0d29ya3NlY3VyaXR5LnYxLkNlcnRpZmljYXRlUHJvdmlkZXJJbnN0YW5jZUgAUhtjZXJ0
aWZpY2F0ZVByb3ZpZGVySW5zdGFuY2VCBgoEdHlwZULpAQojY29tLmdvb2dsZS5jbG91ZC5u
ZXR3b3Jrc2VjdXJpdHkudjFCCFRsc1Byb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vbmV0
d29ya3NlY3VyaXR5L2FwaXYxL25ldHdvcmtzZWN1cml0eXBiO25ldHdvcmtzZWN1cml0eXBi
qgIfR29vZ2xlLkNsb3VkLk5ldHdvcmtTZWN1cml0eS5WMcoCH0dvb2dsZVxDbG91ZFxOZXR3
b3JrU2VjdXJpdHlcVjHqAiJHb29nbGU6OkNsb3VkOjpOZXR3b3JrU2VjdXJpdHk6OlYxStYW
CgYSBA4ATQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgK
CQoCAwASAxIAKQoICgEIEgMUADwKCQoCCCUSAxQAPAoICgEIEgMVAGQKCQoCCAsSAxUAZAoI
CgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACkKCQoCCAgSAxcAKQoICgEIEgMYADwKCQoC
CAESAxgAPAoICgEIEgMZADwKCQoCCCkSAxkAPAoICgEIEgMaADsKCQoCCC0SAxoAOwoxCgIE
ABIEHQAhARolIFNwZWNpZmljYXRpb24gb2YgdGhlIEdSUEMgRW5kcG9pbnQuCgoKCgMEAAES
Ax0IFAp5CgQEAAIAEgMgAkEabCBSZXF1aXJlZC4gVGhlIHRhcmdldCBVUkkgb2YgdGhlIGdS
UEMgZW5kcG9pbnQuIE9ubHkgVURTIHBhdGggaXMgc3VwcG9ydGVkLAogYW5kIHNob3VsZCBz
dGFydCB3aXRoICJ1bml4OiIuCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCRMKDAoFBAAC
AAMSAyAWFwoMCgUEAAIACBIDIBhACg8KCAQAAgAInAgAEgMgGT8KlgEKAgQBEgQlADEBGokB
IFNwZWNpZmljYXRpb24gb2YgVmFsaWRhdGlvbkNBLiBEZWZpbmVzIHRoZSBtZWNoYW5pc20g
dG8gb2J0YWluIHRoZQogQ2VydGlmaWNhdGUgQXV0aG9yaXR5IGNlcnRpZmljYXRlIHRvIHZh
bGlkYXRlIHRoZSBwZWVyIGNlcnRpZmljYXRlLgoKCgoDBAEBEgMlCBQKUwoEBAEIABIEJwIw
AxpFIFRoZSB0eXBlIG9mIGNlcnRpZmljYXRlIHByb3ZpZGVyIHdoaWNoIHByb3ZpZGVzIHRo
ZSBDQSBjZXJ0aWZpY2F0ZS4KCgwKBQQBCAABEgMnCAwKYwoEBAECABIDKgQjGlYgZ1JQQyBz
cGVjaWZpYyBjb25maWd1cmF0aW9uIHRvIGFjY2VzcyB0aGUgZ1JQQyBzZXJ2ZXIgdG8KIG9i
dGFpbiB0aGUgQ0EgY2VydGlmaWNhdGUuCgoMCgUEAQIABhIDKgQQCgwKBQQBAgABEgMqER4K
DAoFBAECAAMSAyohIgqlAQoEBAECARIDLwRCGpcBIFRoZSBjZXJ0aWZpY2F0ZSBwcm92aWRl
ciBpbnN0YW5jZSBzcGVjaWZpY2F0aW9uIHRoYXQgd2lsbCBiZSBwYXNzZWQgdG8KIHRoZSBk
YXRhIHBsYW5lLCB3aGljaCB3aWxsIGJlIHVzZWQgdG8gbG9hZCBuZWNlc3NhcnkgY3JlZGVu
dGlhbAogaW5mb3JtYXRpb24uCgoMCgUEAQIBBhIDLwQfCgwKBQQBAgEBEgMvID0KDAoFBAEC
AQMSAy9AQQrCAgoCBAISBDcAPAEatQIgU3BlY2lmaWNhdGlvbiBvZiBhIFRMUyBjZXJ0aWZp
Y2F0ZSBwcm92aWRlciBpbnN0YW5jZS4gV29ya2xvYWRzIG1heSBoYXZlIG9uZQogb3IgbW9y
ZSBDZXJ0aWZpY2F0ZVByb3ZpZGVyIGluc3RhbmNlcyAocGx1Z2lucykgYW5kIG9uZSBvZiB0
aGVtIGlzIGVuYWJsZWQKIGFuZCBjb25maWd1cmVkIGJ5IHNwZWNpZnlpbmcgdGhpcyBtZXNz
YWdlLiBXb3JrbG9hZHMgdXNlIHRoZSB2YWx1ZXMgZnJvbSB0aGlzCiBtZXNzYWdlIHRvIGxv
Y2F0ZSBhbmQgbG9hZCB0aGUgQ2VydGlmaWNhdGVQcm92aWRlciBpbnN0YW5jZSBjb25maWd1
cmF0aW9uLgoKCgoDBAIBEgM3CCMK3gEKBAQCAgASAzsCRhrQASBSZXF1aXJlZC4gUGx1Z2lu
IGluc3RhbmNlIG5hbWUsIHVzZWQgdG8gbG9jYXRlIGFuZCBsb2FkIENlcnRpZmljYXRlUHJv
dmlkZXIKIGluc3RhbmNlIGNvbmZpZ3VyYXRpb24uIFNldCB0byAiZ29vZ2xlX2Nsb3VkX3By
aXZhdGVfc3BpZmZlIiB0byB1c2UKIENlcnRpZmljYXRlIEF1dGhvcml0eSBTZXJ2aWNlIGNl
cnRpZmljYXRlIHByb3ZpZGVyIGluc3RhbmNlLgoKDAoFBAICAAUSAzsCCAoMCgUEAgIAARID
OwkYCgwKBQQCAgADEgM7GxwKDAoFBAICAAgSAzsdRQoPCggEAgIACJwIABIDOx5ECpcBCgIE
AxIEQABNARqKASBTcGVjaWZpY2F0aW9uIG9mIGNlcnRpZmljYXRlIHByb3ZpZGVyLiBEZWZp
bmVzIHRoZSBtZWNoYW5pc20gdG8gb2J0YWluIHRoZQogY2VydGlmaWNhdGUgYW5kIHByaXZh
dGUga2V5IGZvciBwZWVyIHRvIHBlZXIgYXV0aGVudGljYXRpb24uCgoKCgMEAwESA0AIGwpj
CgQEAwgAEgRDAkwDGlUgVGhlIHR5cGUgb2YgY2VydGlmaWNhdGUgcHJvdmlkZXIgd2hpY2gg
cHJvdmlkZXMgdGhlIGNlcnRpZmljYXRlcyBhbmQKIHByaXZhdGUga2V5cy4KCgwKBQQDCAAB
EgNDCAwKaQoEBAMCABIDRgQjGlwgZ1JQQyBzcGVjaWZpYyBjb25maWd1cmF0aW9uIHRvIGFj
Y2VzcyB0aGUgZ1JQQyBzZXJ2ZXIgdG8KIG9idGFpbiB0aGUgY2VydCBhbmQgcHJpdmF0ZSBr
ZXkuCgoMCgUEAwIABhIDRgQQCgwKBQQDAgABEgNGER4KDAoFBAMCAAMSA0YhIgqlAQoEBAMC
ARIDSwRCGpcBIFRoZSBjZXJ0aWZpY2F0ZSBwcm92aWRlciBpbnN0YW5jZSBzcGVjaWZpY2F0
aW9uIHRoYXQgd2lsbCBiZSBwYXNzZWQgdG8KIHRoZSBkYXRhIHBsYW5lLCB3aGljaCB3aWxs
IGJlIHVzZWQgdG8gbG9hZCBuZWNlc3NhcnkgY3JlZGVudGlhbAogaW5mb3JtYXRpb24uCgoM
CgUEAwIBBhIDSwQfCgwKBQQDAgEBEgNLID0KDAoFBAMCAQMSA0tAQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::Tls::GrpcEndpoint ===
    # Fields for GrpcEndpoint
    # Field: target_uri Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::Tls::GrpcEndpoint - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::Tls;

    my $msg = Google::Cloud::Networksecurity::V1::Tls::GrpcEndpoint->new(
        target_uri => $value,
    );

=head1 FIELDS

=over 4

=item * B<target_uri>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::Tls::ValidationCA ===
    # Fields for ValidationCA
    # Field: grpc_endpoint Type: 11 (.google.cloud.networksecurity.v1.GrpcEndpoint)
    # Field: certificate_provider_instance Type: 11 (.google.cloud.networksecurity.v1.CertificateProviderInstance)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::Tls::ValidationCA - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::Tls;

    my $msg = Google::Cloud::Networksecurity::V1::Tls::ValidationCA->new(
        grpc_endpoint => $value,
    );

=head1 FIELDS

=over 4

=item * B<grpc_endpoint>

Type: Message (.google.cloud.networksecurity.v1.GrpcEndpoint)

=item * B<certificate_provider_instance>

Type: Message (.google.cloud.networksecurity.v1.CertificateProviderInstance)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::Tls::CertificateProviderInstance ===
    # Fields for CertificateProviderInstance
    # Field: plugin_instance Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::Tls::CertificateProviderInstance - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::Tls;

    my $msg = Google::Cloud::Networksecurity::V1::Tls::CertificateProviderInstance->new(
        plugin_instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<plugin_instance>

Type: String

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::Tls::CertificateProvider ===
    # Fields for CertificateProvider
    # Field: grpc_endpoint Type: 11 (.google.cloud.networksecurity.v1.GrpcEndpoint)
    # Field: certificate_provider_instance Type: 11 (.google.cloud.networksecurity.v1.CertificateProviderInstance)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::Tls::CertificateProvider - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::Tls;

    my $msg = Google::Cloud::Networksecurity::V1::Tls::CertificateProvider->new(
        grpc_endpoint => $value,
    );

=head1 FIELDS

=over 4

=item * B<grpc_endpoint>

Type: Message (.google.cloud.networksecurity.v1.GrpcEndpoint)

=item * B<certificate_provider_instance>

Type: Message (.google.cloud.networksecurity.v1.CertificateProviderInstance)

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::Tls - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
