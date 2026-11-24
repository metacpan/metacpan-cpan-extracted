package Google::Cloud::Apiregistry::V1beta::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXBpcmVnaXN0cnkvdjFiZXRhL2NvbW1vbi5wcm90bxIfZ29vZ2xl
LmNsb3VkLmFwaXJlZ2lzdHJ5LnYxYmV0YSo5CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEgsKB0VOQUJMRUQQARIMCghESVNBQkxFRBACQuQBCiNjb20uZ29vZ2xlLmNsb3VkLmFw
aXJlZ2lzdHJ5LnYxYmV0YUILQ29tbW9uUHJvdG9QAVpFY2xvdWQuZ29vZ2xlLmNvbS9nby9h
cGlyZWdpc3RyeS9hcGl2MWJldGEvYXBpcmVnaXN0cnlwYjthcGlyZWdpc3RyeXBiqgIfR29v
Z2xlLkNsb3VkLkFwaVJlZ2lzdHJ5LlYxQmV0YcoCH0dvb2dsZVxDbG91ZFxBcGlSZWdpc3Ry
eVxWMWJldGHqAiJHb29nbGU6OkNsb3VkOjpBcGlSZWdpc3RyeTo6VjFiZXRhSv0HCgYSBA4A
JAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCAoBCBID
EgA8CgkKAgglEgMSADwKCAoBCBIDEwBcCgkKAggLEgMTAFwKCAoBCBIDFAAiCgkKAggKEgMU
ACIKCAoBCBIDFQAsCgkKAggIEgMVACwKCAoBCBIDFgA8CgkKAggBEgMWADwKCAoBCBIDFwA8
CgkKAggpEgMXADwKCAoBCBIDGAA7CgkKAggtEgMYADsKLgoCBQASBBsAJAEaIiBUaGUgc3Rh
dGUgb2YgTWNwU2VydmVyIHJlc291cmNlLgoKCgoDBQABEgMbBQoKMgoEBQACABIDHQIYGiUg
VGhlIE1jcFNlcnZlciBzdGF0ZSBpcyB1bnNwZWNpZmllZC4KCgwKBQUAAgABEgMdAhMKDAoF
BQACAAISAx0WFwooCgQFAAIBEgMgAg4aGyBUaGUgTWNwU2VydmVyIGlzIGVuYWJsZWQuCgoM
CgUFAAIBARIDIAIJCgwKBQUAAgECEgMgDA0KKQoEBQACAhIDIwIPGhwgVGhlIE1jcFNlcnZl
ciBpcyBkaXNhYmxlZC4KCgwKBQUAAgIBEgMjAgoKDAoFBQACAgISAyMNDmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apiregistry::V1beta::Common - Compiled Protocol Buffers messages for google/cloud/apiregistry/v1beta/common.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apiregistry/v1beta/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apiregistry::V1beta::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
