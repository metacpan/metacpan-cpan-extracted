package Google::Cloud::Baremetalsolution::V2::SshKey;

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
Ci9nb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvc3NoX2tleS5wcm90bxIhZ29v
Z2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIqkBCgZTU0hLZXkSFwoEbmFt
ZRgBIAEoCUID4EEDUgRuYW1lEh0KCnB1YmxpY19rZXkYAiABKAlSCXB1YmxpY0tleTpn6kFk
CidiYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9Tc2hLZXkSOXByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zc2hLZXlzL3tzc2hfa2V5fSKTAQoSTGlz
dFNTSEtleXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29v
Z2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VT
aXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKDAQoTTGlzdFNTSEtleXNSZXNw
b25zZRJECghzc2hfa2V5cxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlv
bi52Mi5TU0hLZXlSB3NzaEtleXMSJgoPbmV4dF9wYWdlX3Rva2VuGFogASgJUg1uZXh0UGFn
ZVRva2VuIsQBChNDcmVhdGVTU0hLZXlSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEj
CiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBJHCgdzc2hfa2V5
GAIgASgLMikuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlNTSEtleUID4EEC
UgZzc2hLZXkSIQoKc3NoX2tleV9pZBgDIAEoCUID4EECUghzc2hLZXlJZCJaChNEZWxldGVT
U0hLZXlSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonYmFyZW1ldGFsc29sdXRpb24u
Z29vZ2xlYXBpcy5jb20vU3NoS2V5UgRuYW1lQvoBCiVjb20uZ29vZ2xlLmNsb3VkLmJhcmVt
ZXRhbHNvbHV0aW9uLnYyQgtTc2hLZXlQcm90b1ABWlNjbG91ZC5nb29nbGUuY29tL2dvL2Jh
cmVtZXRhbHNvbHV0aW9uL2FwaXYyL2JhcmVtZXRhbHNvbHV0aW9ucGI7YmFyZW1ldGFsc29s
dXRpb25wYqoCIUdvb2dsZS5DbG91ZC5CYXJlTWV0YWxTb2x1dGlvbi5WMsoCIUdvb2dsZVxD
bG91ZFxCYXJlTWV0YWxTb2x1dGlvblxWMuoCJEdvb2dsZTo6Q2xvdWQ6OkJhcmVNZXRhbFNv
bHV0aW9uOjpWMkqgFwoGEgQOAGcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAqCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAD4KCQoCCCUSAxUA
PgoICgEIEgMWAGoKCQoCCAsSAxYAagoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYACwK
CQoCCAgSAxgALAoICgEIEgMZAD4KCQoCCAESAxkAPgoICgEIEgMaAD4KCQoCCCkSAxoAPgoI
CgEIEgMbAD0KCQoCCC0SAxsAPQpbCgIEABIEHgAqARpPIEFuIFNTSCBrZXksIHVzZWQgZm9y
IGF1dGhvcml6aW5nIHdpdGggdGhlIGludGVyYWN0aXZlIHNlcmlhbCBjb25zb2xlIGZlYXR1
cmUuCgoKCgMEAAESAx4IDgoLCgMEAAcSBB8CIgQKDQoFBAAHnQgSBB8CIgQKdAoEBAACABID
JgI+GmcgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoaXMgU1NIIGtleS4KIEN1cnJlbnRs
eSwgdGhlIG9ubHkgdmFsaWQgdmFsdWUgZm9yIHRoZSBsb2NhdGlvbiBpcyAiZ2xvYmFsIi4K
CgwKBQQAAgAFEgMmAggKDAoFBAACAAESAyYJDQoMCgUEAAIAAxIDJhARCgwKBQQAAgAIEgMm
Ej0KDwoIBAACAAicCAASAyYTPApTCgQEAAIBEgMpAhgaRiBUaGUgcHVibGljIFNTSCBrZXku
IFRoaXMgbXVzdCBiZSBpbiBPcGVuU1NIIC5hdXRob3JpemVkX2tleXMgZm9ybWF0LgoKDAoF
BAACAQUSAykCCAoMCgUEAAIBARIDKQkTCgwKBQQAAgEDEgMpFhcKQwoCBAESBC0APAEaNyBN
ZXNzYWdlIGZvciBsaXN0aW5nIHRoZSBwdWJsaWMgU1NIIGtleXMgaW4gYSBwcm9qZWN0LgoK
CgoDBAEBEgMtCBoKfAoEBAECABIEMAI1BBpuIFJlcXVpcmVkLiBUaGUgcGFyZW50IGNvbnRh
aW5pbmcgdGhlIFNTSCBrZXlzLgogQ3VycmVudGx5LCB0aGUgb25seSB2YWxpZCB2YWx1ZSBm
b3IgdGhlIGxvY2F0aW9uIGlzICJnbG9iYWwiLgoKDAoFBAECAAUSAzACCAoMCgUEAQIAARID
MAkPCgwKBQQBAgADEgMwEhMKDQoFBAECAAgSBDAUNQMKDwoIBAECAAicCAASAzEEKgoPCgcE
AQIACJ8IEgQyBDQFCjUKBAQBAgESAzgCFhooIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVt
cyB0byByZXR1cm4uCgoMCgUEAQIBBRIDOAIHCgwKBQQBAgEBEgM4CBEKDAoFBAECAQMSAzgU
FQpXCgQEAQICEgM7AhgaSiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZy
b20gYSBwcmV2aW91cyBMaXN0IHJlcXVlc3QsIGlmIGFueS4KCgwKBQQBAgIFEgM7AggKDAoF
BAECAgESAzsJEwoMCgUEAQICAxIDOxYXCjIKAgQCEgQ/AEYBGiYgTWVzc2FnZSBmb3IgcmVz
cG9uc2Ugb2YgTGlzdFNTSEtleXMuCgoKCgMEAgESAz8IGwo2CgQEAgIAEgNBAh8aKSBUaGUg
U1NIIGtleXMgcmVnaXN0ZXJlZCBpbiB0aGUgcHJvamVjdC4KCgwKBQQCAgAEEgNBAgoKDAoF
BAICAAYSA0ELEQoMCgUEAgIAARIDQRIaCgwKBQQCAgADEgNBHR4KbgoEBAICARIDRQIeGmEg
VG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBp
ZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyBpbiB0aGUgbGlzdC4KCgwKBQQCAgEFEgNF
AggKDAoFBAICAQESA0UJGAoMCgUEAgIBAxIDRRsdCkQKAgQDEgRJAFsBGjggTWVzc2FnZSBm
b3IgcmVnaXN0ZXJpbmcgYSBwdWJsaWMgU1NIIGtleSBpbiBhIHByb2plY3QuCgoKCgMEAwES
A0kIGwo9CgQEAwIAEgRLAlAEGi8gUmVxdWlyZWQuIFRoZSBwYXJlbnQgY29udGFpbmluZyB0
aGUgU1NIIGtleXMuCgoMCgUEAwIABRIDSwIICgwKBQQDAgABEgNLCQ8KDAoFBAMCAAMSA0sS
EwoNCgUEAwIACBIESxRQAwoPCggEAwIACJwIABIDTAQqCg8KBwQDAgAInwgSBE0ETwUKMQoE
BAMCARIDUwI+GiQgUmVxdWlyZWQuIFRoZSBTU0gga2V5IHRvIHJlZ2lzdGVyLgoKDAoFBAMC
AQYSA1MCCAoMCgUEAwIBARIDUwkQCgwKBQQDAgEDEgNTExQKDAoFBAMCAQgSA1MVPQoPCggE
AwIBCJwIABIDUxY8CrQBCgQEAwICEgNaAkEapgEgUmVxdWlyZWQuIFRoZSBJRCB0byB1c2Ug
Zm9yIHRoZSBrZXksIHdoaWNoIHdpbGwgYmVjb21lIHRoZSBmaW5hbCBjb21wb25lbnQKIG9m
IHRoZSBrZXkncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgbXVzdCBtYXRjaCB0aGUg
cmVnZXg6CiAgIFthLXpBLVowLTlALlwtX117MSw2NH0KCgwKBQQDAgIFEgNaAggKDAoFBAMC
AgESA1oJEwoMCgUEAwICAxIDWhYXCgwKBQQDAgIIEgNaGEAKDwoIBAMCAgicCAASA1oZPwo9
CgIEBBIEXgBnARoxIE1lc3NhZ2UgZm9yIGRlbGV0aW5nIGFuIFNTSCBrZXkgZnJvbSBhIHBy
b2plY3QuCgoKCgMEBAESA14IGwp7CgQEBAIAEgRhAmYEGm0gUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBTU0gga2V5IHRvIGRlbGV0ZS4KIEN1cnJlbnRseSwgdGhlIG9ubHkgdmFsaWQg
dmFsdWUgZm9yIHRoZSBsb2NhdGlvbiBpcyAiZ2xvYmFsIi4KCgwKBQQEAgAFEgNhAggKDAoF
BAQCAAESA2EJDQoMCgUEBAIAAxIDYRARCg0KBQQEAgAIEgRhEmYDCg8KCAQEAgAInAgAEgNi
BCoKDwoHBAQCAAifCBIEYwRlBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey ===
    # Fields for SSHKey
    # Field: name Type: 9 ()
    # Field: public_key Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysRequest ===
    # Fields for ListSSHKeysRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysResponse ===
    # Fields for ListSSHKeysResponse
    # Field: ssh_keys Type: 11 (.google.cloud.baremetalsolution.v2.SSHKey)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::SshKey::CreateSSHKeyRequest ===
    # Fields for CreateSSHKeyRequest
    # Field: parent Type: 9 ()
    # Field: ssh_key Type: 11 (.google.cloud.baremetalsolution.v2.SSHKey)
    # Field: ssh_key_id Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::SshKey::DeleteSSHKeyRequest ===
    # Fields for DeleteSSHKeyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::SshKey - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/ssh_key.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::SshKey;

    my $msg = Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey->new({
        name => $name,
        public_key => $public_key,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/ssh_key.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey

An SSH key, used for authorizing with the interactive serial console feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of this SSH key.
Currently, the only valid value for the location is "global".

=item * C<< $msg->public_key() >> / C<< $msg->public_key($value) >>

Type: C<String>

The public SSH key. This must be in OpenSSH .authorized_keys format.

=back

=head2 Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysRequest

Message for listing the public SSH keys in a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent containing the SSH keys.
Currently, the only valid value for the location is "global".

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous List request, if any.

=back

=head2 Google::Cloud::Baremetalsolution::V2::SshKey::ListSSHKeysResponse

Message for response of ListSSHKeys.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ssh_keys() >> / C<< $msg->ssh_keys($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey>)

The SSH keys registered in the project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Baremetalsolution::V2::SshKey::CreateSSHKeyRequest

Message for registering a public SSH key in a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent containing the SSH keys.

=item * C<< $msg->ssh_key() >> / C<< $msg->ssh_key($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::SshKey::SSHKey>)

Required. The SSH key to register.

=item * C<< $msg->ssh_key_id() >> / C<< $msg->ssh_key_id($value) >>

Type: C<String>

Required. The ID to use for the key, which will become the final component
of the key's resource name.

This value must match the regex:
  [a-zA-Z0-9@.\-_]{1,64}

=back

=head2 Google::Cloud::Baremetalsolution::V2::SshKey::DeleteSSHKeyRequest

Message for deleting an SSH key from a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the SSH key to delete.
Currently, the only valid value for the location is "global".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::SshKey::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
