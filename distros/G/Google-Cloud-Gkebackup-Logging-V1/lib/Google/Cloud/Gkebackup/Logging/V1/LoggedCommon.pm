package Google::Cloud::Gkebackup::Logging::V1::LoggedCommon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX2NvbW1vbi5wcm90
bxIhZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxIiwKCk5hbWVzcGFjZXMSHgoK
bmFtZXNwYWNlcxgBIAMoCVIKbmFtZXNwYWNlcyJCCg5OYW1lc3BhY2VkTmFtZRIcCgluYW1l
c3BhY2UYASABKAlSCW5hbWVzcGFjZRISCgRuYW1lGAIgASgJUgRuYW1lIm8KD05hbWVzcGFj
ZWROYW1lcxJcChBuYW1lc3BhY2VkX25hbWVzGAEgAygLMjEuZ29vZ2xlLmNsb3VkLmdrZWJh
Y2t1cC5sb2dnaW5nLnYxLk5hbWVzcGFjZWROYW1lUg9uYW1lc3BhY2VkTmFtZXMiRAoNRW5j
cnlwdGlvbktleRIzChZnY3Bfa21zX2VuY3J5cHRpb25fa2V5GAEgASgJUhNnY3BLbXNFbmNy
eXB0aW9uS2V5QukBCiFnb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjFCEUxvZ2dl
ZENvbW1vblByb3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3VwL2xvZ2dpbmcv
YXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoCIUdvb2dsZS5DbG91ZC5Ha2VCYWNrdXAuTG9n
Z2luZy5WMcoCIUdvb2dsZVxDbG91ZFxHa2VCYWNrdXBcTG9nZ2luZ1xWMeoCJUdvb2dsZTo6
Q2xvdWQ6OkdrZUJhY2t1cDo6TG9nZ2luZzo6VjFKlgwKBhIEDgA1AQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoICgEIEgMSAD4KCQoCCCUSAxIAPgoI
CgEIEgMTAFYKCQoCCAsSAxMAVgoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADIKCQoC
CAgSAxUAMgoICgEIEgMWADoKCQoCCAESAxYAOgoICgEIEgMXAD8KCQoCCCkSAxcAPwoICgEI
EgMYAD4KCQoCCC0SAxgAPgosCgIEABIEGwAeARogIE5hbWVzcGFjZXMsIGxpc3Qgb2YgbmFt
ZXNwYWNlcwoKCgoDBAABEgMbCBIKGQoEBAACABIDHQIhGgwgbmFtZXNwYWNlcwoKDAoFBAAC
AAQSAx0CCgoMCgUEAAIABRIDHQsRCgwKBQQAAgABEgMdEhwKDAoFBAACAAMSAx0fIAocCgIE
ARIEIQAnARoQIE5hbWVzcGFjZWROYW1lCgoKCgMEAQESAyEIFgo6CgQEAQIAEgMjAhcaLSB0
aGUgbmFtZXNwYWNlIG9mIHRoZSByZXNvdXJjZSBpbiBLdWJlcm5ldGVzCgoMCgUEAQIABRID
IwIICgwKBQQBAgABEgMjCRIKDAoFBAECAAMSAyMVFgo1CgQEAQIBEgMmAhIaKCB0aGUgbmFt
ZSBvZiB0aGUgcmVzb3VyY2UgaW4gS3ViZXJuZXRlcwoKDAoFBAECAQUSAyYCCAoMCgUEAQIB
ARIDJgkNCgwKBQQBAgEDEgMmEBEKHQoCBAISBCoALQEaESBOYW1lc3BhY2VkTmFtZXMKCgoK
AwQCARIDKggXCjcKBAQCAgASAywCLxoqIGEgbGlzdCBvZiBuYW1lc3BhY2VkIG5hbWVzIGlu
IEt1YmVybmV0ZXMKCgwKBQQCAgAEEgMsAgoKDAoFBAICAAYSAywLGQoMCgUEAgIAARIDLBoq
CgwKBQQCAgADEgMsLS4KWAoCBAMSBDEANQEaTCBFbmNyeXB0aW9uIGtleS4KIFRoaXMgb25s
eSBjb250YWlucyB0aGUga2V5IG1ldGFkYXRhLCBhbmQgbm8ga2V5IG1hdGVyaWFsLgoKCgoD
BAMBEgMxCBUKhQEKBAQDAgASAzQCJBp4IEdvb2dsZSBLTVMgZW5jcnlwdGlvbiBrZXkgaW4g
dGhlIGZvcm1hdDoKIHByb2plY3RzLzxwcm9qZWN0Pi9sb2NhdGlvbnMvPGxvY2F0aW9uPi9r
ZXlSaW5ncy88a2V5LXJpbmc+L2NyeXB0b0tleXMvPGtleT4KCgwKBQQDAgAFEgM0AggKDAoF
BAMCAAESAzQJHwoMCgUEAwIAAxIDNCIjYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces ===
    # Fields for Namespaces
    # Field: namespaces Type: 9 ()

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedName ===
    # Fields for NamespacedName
    # Field: namespace Type: 9 ()
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedNames ===
    # Fields for NamespacedNames
    # Field: namespaced_names Type: 11 (.google.cloud.gkebackup.logging.v1.NamespacedName)

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::EncryptionKey ===
    # Fields for EncryptionKey
    # Field: gcp_kms_encryption_key Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedCommon - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedCommon;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces->new({
        namespaces => $namespaces,
    });

    # Read or update a field
    my $val = $msg->namespaces();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces

Namespaces, list of namespaces

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespaces() >> / C<< $msg->namespaces($value) >>

Type: C<String>

namespaces

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedName

NamespacedName

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespace() >> / C<< $msg->namespace($value) >>

Type: C<String>

the namespace of the resource in Kubernetes

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

the name of the resource in Kubernetes

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedNames

NamespacedNames

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespaced_names() >> / C<< $msg->namespaced_names($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedName>)

a list of namespaced names in Kubernetes

=back

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::EncryptionKey

Encryption key.
This only contains the key metadata, and no key material.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcp_kms_encryption_key() >> / C<< $msg->gcp_kms_encryption_key($value) >>

Type: C<String>

Google KMS encryption key in the format:
projects/<project>/locations/<location>/keyRings/<key-ring>/cryptoKeys/<key>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
