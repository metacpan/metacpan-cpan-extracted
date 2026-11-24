package Google::Cloud::Vectorsearch::V1beta::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxYmV0YS9jb21tb24ucHJvdG8SIGdvb2ds
ZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhKlcKDkRpc3RhbmNlTWV0cmljEh8KG0RJU1RB
TkNFX01FVFJJQ19VTlNQRUNJRklFRBAAEg8KC0RPVF9QUk9EVUNUEAESEwoPQ09TSU5FX0RJ
U1RBTkNFEAJC6wEKJGNvbS5nb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YUILQ29t
bW9uUHJvdG9QAVpIY2xvdWQuZ29vZ2xlLmNvbS9nby92ZWN0b3JzZWFyY2gvYXBpdjFiZXRh
L3ZlY3RvcnNlYXJjaHBiO3ZlY3RvcnNlYXJjaHBiqgIgR29vZ2xlLkNsb3VkLlZlY3RvclNl
YXJjaC5WMUJldGHKAiBHb29nbGVcQ2xvdWRcVmVjdG9yU2VhcmNoXFYxYmV0YeoCI0dvb2ds
ZTo6Q2xvdWQ6OlZlY3RvclNlYXJjaDo6VjFiZXRhSowICgYSBA4AJAEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCAoBCBIDEgA9CgkKAgglEgMSAD0K
CAoBCBIDEwBfCgkKAggLEgMTAF8KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAsCgkK
AggIEgMVACwKCAoBCBIDFgA9CgkKAggBEgMWAD0KCAoBCBIDFwA9CgkKAggpEgMXAD0KCAoB
CBIDGAA8CgkKAggtEgMYADwKMAoCBQASBBsAJAEaJCBEaXN0YW5jZSBtZXRyaWMgZm9yIHZl
Y3RvciBzZWFyY2guCgoKCgMFAAESAxsFEwo/CgQFAAIAEgMdAiIaMiBEZWZhdWx0IHZhbHVl
LCBkaXN0YW5jZSBtZXRyaWMgaXMgbm90IHNwZWNpZmllZC4KCgwKBQUAAgABEgMdAh0KDAoF
BQACAAISAx0gIQorCgQFAAIBEgMgAhIaHiBEb3QgcHJvZHVjdCBkaXN0YW5jZSBtZXRyaWMu
CgoMCgUFAAIBARIDIAINCgwKBQUAAgECEgMgEBEKJgoEBQACAhIDIwIWGhkgQ29zaW5lIGRp
c3RhbmNlIG1ldHJpYy4KCgwKBQUAAgIBEgMjAhEKDAoFBQACAgISAyMUFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::Common - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1beta/common.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1beta/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1beta::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
