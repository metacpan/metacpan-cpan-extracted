package Google::Cloud::Agentregistry::V1::SkillEncryptionSpec;

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
Cjlnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9za2lsbF9lbmNyeXB0aW9uX3NwZWMu
cHJvdG8SHWdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIqYDChNTa2lsbEVuY3J5cHRpb25TcGVjEhcKBG5hbWUY
ASABKAlCA+BBCFIEbmFtZRJRCg9jcnlwdG9fa2V5X25hbWUYAiABKAlCKeBBAvpBIwohY2xv
dWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5Ug1jcnlwdG9LZXlOYW1lEkAKC2NyZWF0
ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVU
aW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgp1cGRhdGVUaW1lOp4B6kGaAQowYWdlbnRyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9T
a2lsbEVuY3J5cHRpb25TcGVjEjtwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vc2tpbGxFbmNyeXB0aW9uU3BlYyoUc2tpbGxFbmNyeXB0aW9uU3BlY3MyE3NraWxs
RW5jcnlwdGlvblNwZWNC5gIKIWNvbS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MUIY
U2tpbGxFbmNyeXB0aW9uU3BlY1Byb3RvUAFaR2Nsb3VkLmdvb2dsZS5jb20vZ28vYWdlbnRy
ZWdpc3RyeS9hcGl2MS9hZ2VudHJlZ2lzdHJ5cGI7YWdlbnRyZWdpc3RyeXBiqgIdR29vZ2xl
LkNsb3VkLkFnZW50UmVnaXN0cnkuVjHKAh1Hb29nbGVcQ2xvdWRcQWdlbnRSZWdpc3RyeVxW
MeoCIEdvb2dsZTo6Q2xvdWQ6OkFnZW50UmVnaXN0cnk6OlYx6kF4CiFjbG91ZGttcy5nb29n
bGVhcGlzLmNvbS9DcnlwdG9LZXkSU3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jpbmd9L2NyeXB0b0tleXMve2NyeXB0b19rZXl9SsUQ
CgYSBA4ASQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA6CgkKAgglEgMWADoK
CAoBCBIDFwBeCgkKAggLEgMXAF4KCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA5CgkK
AggIEgMZADkKCAoBCBIDGgA6CgkKAggBEgMaADoKCAoBCBIDGwA6CgkKAggpEgMbADoKCAoB
CBIDHAA5CgkKAggtEgMcADkKCQoBCBIEHQAgAgoMCgQInQgAEgQdACACCqYCCgIEABIEKABJ
ARqZAiBPbmNlIHRoZSBTa2lsbEVuY3J5cHRpb25TcGVjIGlzIGNvbmZpZ3VyZWQsIG5ldyBT
a2lsbCBwYXlsb2FkcyBhcmUgcHJvdGVjdGVkCiB1c2luZyB0aGUgcHJvdmlkZWQgY3VzdG9t
ZXItbWFuYWdlZCBlbmNyeXB0aW9uIGtleSBpbnN0ZWFkIG9mIGEKIEdvb2dsZS1tYW5hZ2Vk
IGVuY3J5cHRpb24ga2V5LgoKIFNraWxsRW5jcnlwdGlvblNwZWMgY2Fubm90IGJlIHNldCBp
ZiBhbnkgU2tpbGxzIGhhdmUgYWxyZWFkeSBiZWVuIGNyZWF0ZWQKIGluIHRoZSBwcm9qZWN0
IGFuZCBsb2NhdGlvbi4KCgoKAwQAARIDKAgbCgsKAwQABxIEKQIuBAoNCgUEAAedCBIEKQIu
BAqLAQoEBAACABIDMgI9Gn4gSWRlbnRpZmllci4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgU2tp
bGxFbmNyeXB0aW9uU3BlYy4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9za2lsbEVuY3J5cHRpb25TcGVjYAoKDAoFBAACAAUSAzICCAoMCgUE
AAIAARIDMgkNCgwKBQQAAgADEgMyEBEKDAoFBAACAAgSAzISPAoPCggEAAIACJwIABIDMhM7
CqEDCgQEAAIBEgQ7AkAEGpIDIFJlcXVpcmVkLiBUaGUgQ2xvdWQgS01TIENyeXB0b0tleSBy
ZXNvdXJjZSBuYW1lIHVzZWQgdG8gcHJvdGVjdCBTa2lsbAogcGF5bG9hZHMgaW4gdGhpcyBw
cm9qZWN0IGFuZCBsb2NhdGlvbi4KIFRoaXMgZmllbGQgY2FuIGJlIHNldCBvciB1cGRhdGVk
IG9ubHkgd2hlbiBubyBTa2lsbHMgZXhpc3QgaW4gdGhlIHRhcmdldAogcHJvamVjdCBhbmQg
bG9jYXRpb24uIE9uY2UgYW55IFNraWxsIGV4aXN0cyBpbiB0aGUgbG9jYXRpb24sIHVwZGF0
aW5nIHRoaXMKIGZpZWxkIGlzIHJlamVjdGVkIHdpdGggYEZBSUxFRF9QUkVDT05ESVRJT05g
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9r
ZXlSaW5ncy97a2V5UmluZ30vY3J5cHRvS2V5cy97Y3J5cHRvS2V5fWAKCgwKBQQAAgEFEgM7
AggKDAoFBAACAQESAzsJGAoMCgUEAAIBAxIDOxscCg0KBQQAAgEIEgQ7HUADCg8KCAQAAgEI
nAgAEgM8BCoKDwoHBAACAQifCBIEPQQ/BQowCgQEAAICEgRDAkQyGiIgT3V0cHV0IG9ubHku
IENyZWF0aW9uIHRpbWVzdGFtcC4KCgwKBQQAAgIGEgNDAhsKDAoFBAACAgESA0McJwoMCgUE
AAICAxIDQyorCgwKBQQAAgIIEgNEBjEKDwoIBAACAgicCAASA0QHMAo6CgQEAAIDEgRHAkgy
GiwgT3V0cHV0IG9ubHkuIE1vc3QgcmVjZW50IHVwZGF0ZSB0aW1lc3RhbXAuCgoMCgUEAAID
BhIDRwIbCgwKBQQAAgMBEgNHHCcKDAoFBAACAwMSA0cqKwoMCgUEAAIDCBIDSAYxCg8KCAQA
AgMInAgAEgNIBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec ===
    # Fields for SkillEncryptionSpec
    # Field: name Type: 9 ()
    # Field: crypto_key_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::SkillEncryptionSpec - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/skill_encryption_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::SkillEncryptionSpec;

    my $msg = Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec->new({
        name => $name,
        crypto_key_name => $crypto_key_name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/skill_encryption_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::SkillEncryptionSpec

Once the SkillEncryptionSpec is configured, new Skill payloads are protected
using the provided customer-managed encryption key instead of a
Google-managed encryption key.

SkillEncryptionSpec cannot be set if any Skills have already been created
in the project and location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the SkillEncryptionSpec.
Format: `projects/{project}/locations/{location}/skillEncryptionSpec`

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Required. The Cloud KMS CryptoKey resource name used to protect Skill
payloads in this project and location.
This field can be set or updated only when no Skills exist in the target
project and location. Once any Skill exists in the location, updating this
field is rejected with `FAILED_PRECONDITION`.
Format:
`projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{cryptoKey}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Most recent update timestamp.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::SkillEncryptionSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
