package Google::Monitoring::Dashboard::V1::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvc2VydmljZS5wcm90bxIeZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxQv8BCiJjb20uZ29vZ2xlLm1vbml0b3JpbmcuZGFz
aGJvYXJkLnYxQhZTZXJ2aWNlTW9uaXRvcmluZ1Byb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20v
Z28vbW9uaXRvcmluZy9kYXNoYm9hcmQvYXBpdjEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKq
AiRHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5EYXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRc
TW9uaXRvcmluZ1xEYXNoYm9hcmRcVjHqAihHb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpE
YXNoYm9hcmQ6OlYxSuQFCgYSBA4AGEEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACcKCAoBCBIDEgBBCgkKAgglEgMSAEEKCAoBCBIDEwBdCgkKAggLEgMT
AF0KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA3CgkKAggIEgMVADcKCAoBCBIDFgA7
CgkKAggBEgMWADsKCAoBCBIDFwBCCgkKAggpEgMXAEIKCAoBCBIDGABBCgkKAggtEgMYAEFi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Service - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
