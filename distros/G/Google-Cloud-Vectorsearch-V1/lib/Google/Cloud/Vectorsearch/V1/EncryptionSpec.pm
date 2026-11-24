package Google::Cloud::Vectorsearch::V1::EncryptionSpec;

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
CjJnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxL2VuY3J5cHRpb25fc3BlYy5wcm90bxIc
Z29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byJjCg5FbmNyeXB0aW9uU3BlYxJR
Cg9jcnlwdG9fa2V5X25hbWUYASABKAlCKeBBAvpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5j
b20vQ3J5cHRvS2V5Ug1jcnlwdG9LZXlOYW1lQtoCCiBjb20uZ29vZ2xlLmNsb3VkLnZlY3Rv
cnNlYXJjaC52MUITRW5jcnlwdGlvblNwZWNQcm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dv
L3ZlY3RvcnNlYXJjaC9hcGl2MS92ZWN0b3JzZWFyY2hwYjt2ZWN0b3JzZWFyY2hwYqoCHEdv
b2dsZS5DbG91ZC5WZWN0b3JTZWFyY2guVjHKAhxHb29nbGVcQ2xvdWRcVmVjdG9yU2VhcmNo
XFYx6gIfR29vZ2xlOjpDbG91ZDo6VmVjdG9yU2VhcmNoOjpWMepBeAohY2xvdWRrbXMuZ29v
Z2xlYXBpcy5jb20vQ3J5cHRvS2V5ElNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fUqH
CgoGEgQOAC8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAl
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADkKCQoCCCUSAxUAOQoICgEIEgMWAFsK
CQoCCAsSAxYAWwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADQKCQoCCAgSAxgANAoI
CgEIEgMZADkKCQoCCAESAxkAOQoICgEIEgMaADkKCQoCCCkSAxoAOQoICgEIEgMbADgKCQoC
CC0SAxsAOAoJCgEIEgQcAB8CCgwKBAidCAASBBwAHwIKfAoCBAASBCMALwEacCBSZXByZXNl
bnRzIGEgY3VzdG9tZXItbWFuYWdlZCBlbmNyeXB0aW9uIGtleSBzcGVjaWZpY2F0aW9uIHRo
YXQgY2FuIGJlCiBhcHBsaWVkIHRvIGEgVmVjdG9yIFNlYXJjaCBjb2xsZWN0aW9uLgoKCgoD
BAABEgMjCBYKjAIKBAQAAgASBCkCLgQa/QEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2Yg
dGhlIENsb3VkIEtNUyBrZXkgdXNlZCB0byBwcm90ZWN0IHRoZSByZXNvdXJjZS4KCiBUaGUg
Q2xvdWQgS01TIGtleSBtdXN0IGJlIGluIHRoZSBzYW1lIHJlZ2lvbiBhcyB0aGUgcmVzb3Vy
Y2UuIEl0IG11c3QgaGF2ZQogdGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jpbmd9L2NyeXB0b0tleXMve2NyeXB0
b19rZXl9YC4KCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJGAoMCgUEAAIAAxIDKRscCg0K
BQQAAgAIEgQpHS4DCg8KCAQAAgAInAgAEgMqBCoKDwoHBAACAAifCBIEKwQtBWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1::EncryptionSpec::EncryptionSpec ===
    # Fields for EncryptionSpec
    # Field: crypto_key_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1::EncryptionSpec - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1/encryption_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1::EncryptionSpec;

    my $msg = Google::Cloud::Vectorsearch::V1::EncryptionSpec::EncryptionSpec->new({
        crypto_key_name => $crypto_key_name,
    });

    # Read or update a field
    my $val = $msg->crypto_key_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1::EncryptionSpec::EncryptionSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1/encryption_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1::EncryptionSpec::EncryptionSpec

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1::EncryptionSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
