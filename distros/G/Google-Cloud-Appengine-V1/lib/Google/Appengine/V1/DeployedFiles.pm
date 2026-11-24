package Google::Appengine::V1::DeployedFiles;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvYXBwZW5naW5lL3YxL2RlcGxveWVkX2ZpbGVzLnByb3RvEhNnb29nbGUuYXBw
ZW5naW5lLnYxQsMBChdjb20uZ29vZ2xlLmFwcGVuZ2luZS52MUISRGVwbG95ZWRGaWxlc1By
b3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vYXBwZW5naW5lL2FwaXYxL2FwcGVuZ2luZXBi
O2FwcGVuZ2luZXBiqgIZR29vZ2xlLkNsb3VkLkFwcEVuZ2luZS5WMcoCGUdvb2dsZVxDbG91
ZFxBcHBFbmdpbmVcVjHqAhxHb29nbGU6OkNsb3VkOjpBcHBFbmdpbmU6OlYxSuQFCgYSBA4A
GDUKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCAoBCBID
EgA2CgkKAgglEgMSADYKCAoBCBIDEwBSCgkKAggLEgMTAFIKCAoBCBIDFAAiCgkKAggKEgMU
ACIKCAoBCBIDFQAzCgkKAggIEgMVADMKCAoBCBIDFgAwCgkKAggBEgMWADAKCAoBCBIDFwA2
CgkKAggpEgMXADYKCAoBCBIDGAA1CgkKAggtEgMYADViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::DeployedFiles - Compiled Protocol Buffers messages for google/appengine/v1/deployed_files.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/deployed_files.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::DeployedFiles::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
