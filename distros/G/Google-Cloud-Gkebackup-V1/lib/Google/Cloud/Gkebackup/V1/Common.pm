package Google::Cloud::Gkebackup::V1::Common;

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
CiZnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL2NvbW1vbi5wcm90bxIZZ29vZ2xlLmNsb3Vk
LmdrZWJhY2t1cC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90byIxCgpOYW1lc3BhY2VzEiMKCm5hbWVzcGFjZXMYASADKAlC
A+BBAVIKbmFtZXNwYWNlcyJMCg5OYW1lc3BhY2VkTmFtZRIhCgluYW1lc3BhY2UYASABKAlC
A+BBAVIJbmFtZXNwYWNlEhcKBG5hbWUYAiABKAlCA+BBAVIEbmFtZSJsCg9OYW1lc3BhY2Vk
TmFtZXMSWQoQbmFtZXNwYWNlZF9uYW1lcxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5na2ViYWNr
dXAudjEuTmFtZXNwYWNlZE5hbWVCA+BBAVIPbmFtZXNwYWNlZE5hbWVzIm8KDUVuY3J5cHRp
b25LZXkSXgoWZ2NwX2ttc19lbmNyeXB0aW9uX2tleRgBIAEoCUIp4EEB+kEjCiFjbG91ZGtt
cy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXlSE2djcEttc0VuY3J5cHRpb25LZXkiVAoOVm9s
dW1lVHlwZUVudW0iQgoKVm9sdW1lVHlwZRIbChdWT0xVTUVfVFlQRV9VTlNQRUNJRklFRBAA
EhcKE0dDRV9QRVJTSVNURU5UX0RJU0sQAULCAQodY29tLmdvb2dsZS5jbG91ZC5na2ViYWNr
dXAudjFCC0NvbW1vblByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3VwL2Fw
aXYxL2drZWJhY2t1cHBiO2drZWJhY2t1cHBiqgIZR29vZ2xlLkNsb3VkLkdrZUJhY2t1cC5W
McoCGUdvb2dsZVxDbG91ZFxHa2VCYWNrdXBcVjHqAhxHb29nbGU6OkNsb3VkOjpHa2VCYWNr
dXA6OlYxSuEQCgYSBA4ASgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACIKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUANgoJCgIIJRIDFQA2CggK
AQgSAxYAUgoJCgIICxIDFgBSCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALAoJCgII
CBIDGAAsCggKAQgSAxkANgoJCgIIARIDGQA2CggKAQgSAxoANgoJCgIIKRIDGgA2CggKAQgS
AxsANQoJCgIILRIDGwA1Ci4KAgQAEgQeACEBGiIgQSBsaXN0IG9mIEt1YmVybmV0ZXMgTmFt
ZXNwYWNlcy4KCgoKAwQAARIDHggSCjkKBAQAAgASAyACShosIE9wdGlvbmFsLiBBIGxpc3Qg
b2YgS3ViZXJuZXRlcyBOYW1lc3BhY2VzLgoKDAoFBAACAAQSAyACCgoMCgUEAAIABRIDIAsR
CgwKBQQAAgABEgMgEhwKDAoFBAACAAMSAyAfIAoMCgUEAAIACBIDICFJCg8KCAQAAgAInAgA
EgMgIkgKQQoCBAESBCQAKgEaNSBBIHJlZmVyZW5jZSB0byBhIG5hbWVzcGFjZWQgcmVzb3Vy
Y2UgaW4gS3ViZXJuZXRlcy4KCgoKAwQBARIDJAgWCkIKBAQBAgASAyYCQBo1IE9wdGlvbmFs
LiBUaGUgTmFtZXNwYWNlIG9mIHRoZSBLdWJlcm5ldGVzIHJlc291cmNlLgoKDAoFBAECAAUS
AyYCCAoMCgUEAQIAARIDJgkSCgwKBQQBAgADEgMmFRYKDAoFBAECAAgSAyYXPwoPCggEAQIA
CJwIABIDJhg+Cj0KBAQBAgESAykCOxowIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgS3Vi
ZXJuZXRlcyByZXNvdXJjZS4KCgwKBQQBAgEFEgMpAggKDAoFBAECAQESAykJDQoMCgUEAQIB
AxIDKRARCgwKBQQBAgEIEgMpEjoKDwoIBAECAQicCAASAykTOQo4CgIEAhIELQAxARosIEEg
bGlzdCBvZiBuYW1lc3BhY2VkIEt1YmVybmV0ZXMgcmVzb3VyY2VzLgoKCgoDBAIBEgMtCBcK
RAoEBAICABIELwIwLxo2IE9wdGlvbmFsLiBBIGxpc3Qgb2YgbmFtZXNwYWNlZCBLdWJlcm5l
dGVzIHJlc291cmNlcy4KCgwKBQQCAgAEEgMvAgoKDAoFBAICAAYSAy8LGQoMCgUEAgIAARID
LxoqCgwKBQQCAgADEgMvLS4KDAoFBAICAAgSAzAGLgoPCggEAgIACJwIABIDMActCmcKAgQD
EgQ1AD4BGlsgRGVmaW5lZCBhIGN1c3RvbWVyIG1hbmFnZWQgZW5jcnlwdGlvbiBrZXkgdGhh
dCB3aWxsIGJlIHVzZWQgdG8gZW5jcnlwdCBCYWNrdXAKIGFydGlmYWN0cy4KCgoKAwQDARID
NQgVCnQKBAQDAgASBDgCPQQaZiBPcHRpb25hbC4gR29vZ2xlIENsb3VkIEtNUyBlbmNyeXB0
aW9uIGtleS4gRm9ybWF0OgogYHByb2plY3RzLyovbG9jYXRpb25zLyova2V5UmluZ3MvKi9j
cnlwdG9LZXlzLypgCgoMCgUEAwIABRIDOAIICgwKBQQDAgABEgM4CR8KDAoFBAMCAAMSAzgi
IwoNCgUEAwIACBIEOCQ9AwoPCggEAwIACJwIABIDOQQqCg8KBwQDAgAInwgSBDoEPAUKNQoC
BAQSBEEASgEaKSBNZXNzYWdlIHRvIGVuY2Fwc3VsYXRlIFZvbHVtZVR5cGUgZW51bS4KCgoK
AwQEARIDQQgWCicKBAQEBAASBEMCSQMaGSBTdXBwb3J0ZWQgdm9sdW1lIHR5cGVzLgoKDAoF
BAQEAAESA0MHEQoYCgYEBAQAAgASA0UEIBoJIERlZmF1bHQKCg4KBwQEBAACAAESA0UEGwoO
CgcEBAQAAgACEgNFHh8KNgoGBAQEAAIBEgNIBBwaJyBDb21wdXRlIEVuZ2luZSBQZXJzaXN0
ZW50IERpc2sgdm9sdW1lCgoOCgcEBAQAAgEBEgNIBBcKDgoHBAQEAAIBAhIDSBobYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::Common::Namespaces ===
    # Fields for Namespaces
    # Field: namespaces Type: 9 ()

# === Message: Google::Cloud::Gkebackup::V1::Common::NamespacedName ===
    # Fields for NamespacedName
    # Field: namespace Type: 9 ()
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Gkebackup::V1::Common::NamespacedNames ===
    # Fields for NamespacedNames
    # Field: namespaced_names Type: 11 (.google.cloud.gkebackup.v1.NamespacedName)

# === Message: Google::Cloud::Gkebackup::V1::Common::EncryptionKey ===
    # Fields for EncryptionKey
    # Field: gcp_kms_encryption_key Type: 9 ()

# === Message: Google::Cloud::Gkebackup::V1::Common::VolumeTypeEnum ===
    # Fields for VolumeTypeEnum

# Enum: VolumeTypeEnum::VolumeType
our $VolumeTypeEnum_VOLUME_TYPE_UNSPECIFIED = 0;
our $VolumeTypeEnum_GCE_PERSISTENT_DISK = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::Common - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::Common;

    my $msg = Google::Cloud::Gkebackup::V1::Common::Namespaces->new({
        namespaces => $namespaces,
    });

    # Read or update a field
    my $val = $msg->namespaces();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::Common::Namespaces->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::Common::Namespaces

A list of Kubernetes Namespaces.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespaces() >> / C<< $msg->namespaces($value) >>

Type: C<String>

Optional. A list of Kubernetes Namespaces.

=back

=head2 Google::Cloud::Gkebackup::V1::Common::NamespacedName

A reference to a namespaced resource in Kubernetes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespace() >> / C<< $msg->namespace($value) >>

Type: C<String>

Optional. The Namespace of the Kubernetes resource.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the Kubernetes resource.

=back

=head2 Google::Cloud::Gkebackup::V1::Common::NamespacedNames

A list of namespaced Kubernetes resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespaced_names() >> / C<< $msg->namespaced_names($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::Common::NamespacedName>)

Optional. A list of namespaced Kubernetes resources.

=back

=head2 Google::Cloud::Gkebackup::V1::Common::EncryptionKey

Defined a customer managed encryption key that will be used to encrypt Backup
artifacts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcp_kms_encryption_key() >> / C<< $msg->gcp_kms_encryption_key($value) >>

Type: C<String>

Optional. Google Cloud KMS encryption key. Format:
`projects/*/locations/*/keyRings/*/cryptoKeys/*`

=back

=head2 Google::Cloud::Gkebackup::V1::Common::VolumeTypeEnum

Message to encapsulate VolumeType enum.

Inherits from L<Protobuf::Message>.

=head3 Enum: VolumeTypeEnum::VolumeType

=over 4

=item * C<VOLUME_TYPE_UNSPECIFIED> => C<0>

=item * C<GCE_PERSISTENT_DISK> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
