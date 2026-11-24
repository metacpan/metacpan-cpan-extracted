package Google::Actions::Sdk::V2::AccountLinkingSecret;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvYWN0aW9ucy9zZGsvdjIvYWNjb3VudF9saW5raW5nX3NlY3JldC5wcm90bxIV
Z29vZ2xlLmFjdGlvbnMuc2RrLnYyIoQBChRBY2NvdW50TGlua2luZ1NlY3JldBI2ChdlbmNy
eXB0ZWRfY2xpZW50X3NlY3JldBgBIAEoDFIVZW5jcnlwdGVkQ2xpZW50U2VjcmV0EjQKFmVu
Y3J5cHRpb25fa2V5X3ZlcnNpb24YAiABKAlSFGVuY3J5cHRpb25LZXlWZXJzaW9uQnIKGWNv
bS5nb29nbGUuYWN0aW9ucy5zZGsudjJCGUFjY291bnRMaW5raW5nU2VjcmV0UHJvdG9QAVo4
Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mjtz
ZGtK+wgKBhIEDgAiAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAHgoICgEIEgMSAE8KCQoCCAsSAxIATwoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMU
ADoKCQoCCAgSAxQAOgoICgEIEgMVADIKCQoCCAESAxUAMgp8CgIEABIEGQAiARpwIEluZm9y
bWF0aW9uIGFib3V0IHRoZSBlbmNyeXB0ZWQgT0F1dGggY2xpZW50IHNlY3JldCB1c2VkIGlu
IGFjY291bnQgbGlua2luZwogZmxvd3MgKGZvciBBVVRIX0NPREUgZ3JhbnQgdHlwZSkuCgoK
CgMEAAESAxkIHApCCgQEAAIAEgMbAiQaNSBFbmNyeXB0ZWQgYWNjb3VudCBsaW5raW5nIGNs
aWVudCBzZWNyZXQgY2lwaGVydGV4dC4KCgwKBQQAAgAFEgMbAgcKDAoFBAACAAESAxsIHwoM
CgUEAAIAAxIDGyIjCrEBCgQEAAIBEgMhAiQaowEgVGhlIHZlcnNpb24gb2YgdGhlIGNyeXB0
byBrZXkgdXNlZCB0byBlbmNyeXB0IHRoZSBhY2NvdW50IGxpbmtpbmcgY2xpZW50CiBzZWNy
ZXQuCiBOb3RlIHRoYXQgdGhpcyBmaWVsZCBpcyBpZ25vcmVkIGluIHB1c2gsIHByZXZpZXcs
IGFuZCB2ZXJzaW9uIGNyZWF0aW9uCiBmbG93cy4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQES
AyEJHwoMCgUEAAIBAxIDISIjYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret ===
    # Fields for AccountLinkingSecret
    # Field: encrypted_client_secret Type: 12 ()
    # Field: encryption_key_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::AccountLinkingSecret - Compiled Protocol Buffers messages for google/actions/sdk/v2/account_linking_secret.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::AccountLinkingSecret;

    my $msg = Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret->new({
        encrypted_client_secret => $encrypted_client_secret,
        encryption_key_version => $encryption_key_version,
    });

    # Read or update a field
    my $val = $msg->encrypted_client_secret();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/account_linking_secret.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret

Information about the encrypted OAuth client secret used in account linking
flows (for AUTH_CODE grant type).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encrypted_client_secret() >> / C<< $msg->encrypted_client_secret($value) >>

Type: C<Bytes>

Encrypted account linking client secret ciphertext.

=item * C<< $msg->encryption_key_version() >> / C<< $msg->encryption_key_version($value) >>

Type: C<String>

The version of the crypto key used to encrypt the account linking client
secret.
Note that this field is ignored in push, preview, and version creation
flows.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::AccountLinkingSecret::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
