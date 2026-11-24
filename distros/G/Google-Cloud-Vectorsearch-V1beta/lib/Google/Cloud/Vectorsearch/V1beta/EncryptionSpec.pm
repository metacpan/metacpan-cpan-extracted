package Google::Cloud::Vectorsearch::V1beta::EncryptionSpec;

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
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxYmV0YS9lbmNyeXB0aW9uX3NwZWMucHJv
dG8SIGdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvImMKDkVuY3J5cHRp
b25TcGVjElEKD2NyeXB0b19rZXlfbmFtZRgBIAEoCUIp4EEC+kEjCiFjbG91ZGttcy5nb29n
bGVhcGlzLmNvbS9DcnlwdG9LZXlSDWNyeXB0b0tleU5hbWVC7gIKJGNvbS5nb29nbGUuY2xv
dWQudmVjdG9yc2VhcmNoLnYxYmV0YUITRW5jcnlwdGlvblNwZWNQcm90b1ABWkhjbG91ZC5n
b29nbGUuY29tL2dvL3ZlY3RvcnNlYXJjaC9hcGl2MWJldGEvdmVjdG9yc2VhcmNocGI7dmVj
dG9yc2VhcmNocGKqAiBHb29nbGUuQ2xvdWQuVmVjdG9yU2VhcmNoLlYxQmV0YcoCIEdvb2ds
ZVxDbG91ZFxWZWN0b3JTZWFyY2hcVjFiZXRh6gIjR29vZ2xlOjpDbG91ZDo6VmVjdG9yU2Vh
cmNoOjpWMWJldGHqQXgKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleRJTcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleVJpbmdzL3trZXlfcmlu
Z30vY3J5cHRvS2V5cy97Y3J5cHRvX2tleX1KhwoKBhIEDgAvAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoB
CBIDFQA9CgkKAgglEgMVAD0KCAoBCBIDFgBfCgkKAggLEgMWAF8KCAoBCBIDFwAiCgkKAggK
EgMXACIKCAoBCBIDGAA0CgkKAggIEgMYADQKCAoBCBIDGQA9CgkKAggBEgMZAD0KCAoBCBID
GgA9CgkKAggpEgMaAD0KCAoBCBIDGwA8CgkKAggtEgMbADwKCQoBCBIEHAAfAgoMCgQInQgA
EgQcAB8CCnwKAgQAEgQjAC8BGnAgUmVwcmVzZW50cyBhIGN1c3RvbWVyLW1hbmFnZWQgZW5j
cnlwdGlvbiBrZXkgc3BlY2lmaWNhdGlvbiB0aGF0IGNhbiBiZQogYXBwbGllZCB0byBhIFZl
Y3RvciBTZWFyY2ggY29sbGVjdGlvbi4KCgoKAwQAARIDIwgWCowCCgQEAAIAEgQpAi4EGv0B
IFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBDbG91ZCBLTVMga2V5IHVzZWQgdG8g
cHJvdGVjdCB0aGUgcmVzb3VyY2UuCgogVGhlIENsb3VkIEtNUyBrZXkgbXVzdCBiZSBpbiB0
aGUgc2FtZSByZWdpb24gYXMgdGhlIHJlc291cmNlLiBJdCBtdXN0IGhhdmUKIHRoZSBmb3Jt
YXQKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mv
e2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fWAuCgoMCgUEAAIABRIDKQIICgwK
BQQAAgABEgMpCRgKDAoFBAACAAMSAykbHAoNCgUEAAIACBIEKR0uAwoPCggEAAIACJwIABID
KgQqCg8KBwQAAgAInwgSBCsELQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec ===
    # Fields for EncryptionSpec
    # Field: crypto_key_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::EncryptionSpec - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1beta/encryption_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1beta::EncryptionSpec;

    my $msg = Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec->new({
        crypto_key_name => $crypto_key_name,
    });

    # Read or update a field
    my $val = $msg->crypto_key_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1beta/encryption_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::EncryptionSpec

Represents a customer-managed encryption key specification that can be
applied to a Vector Search collection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Required. Resource name of the Cloud KMS key used to protect the resource.

The Cloud KMS key must be in the same region as the resource. It must have
the format
`projects/{project}/locations/{location}/keyRings/{key_ring}/cryptoKeys/{crypto_key}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1beta::EncryptionSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
