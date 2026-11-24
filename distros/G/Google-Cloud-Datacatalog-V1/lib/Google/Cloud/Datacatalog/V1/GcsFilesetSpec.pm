package Google::Cloud::Datacatalog::V1::GcsFilesetSpec;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Datacatalog::V1::Timestamps };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvZ2NzX2ZpbGVzZXRfc3BlYy5wcm90bxIb
Z29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGixnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvdGltZXN0YW1wcy5wcm90byKc
AQoOR2NzRmlsZXNldFNwZWMSKAoNZmlsZV9wYXR0ZXJucxgBIAMoCUID4EECUgxmaWxlUGF0
dGVybnMSYAoVc2FtcGxlX2djc19maWxlX3NwZWNzGAIgAygLMiguZ29vZ2xlLmNsb3VkLmRh
dGFjYXRhbG9nLnYxLkdjc0ZpbGVTcGVjQgPgQQNSEnNhbXBsZUdjc0ZpbGVTcGVjcyKuAQoL
R2NzRmlsZVNwZWMSIAoJZmlsZV9wYXRoGAEgASgJQgPgQQJSCGZpbGVQYXRoElkKDmdjc190
aW1lc3RhbXBzGAIgASgLMi0uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlN5c3RlbVRp
bWVzdGFtcHNCA+BBA1INZ2NzVGltZXN0YW1wcxIiCgpzaXplX2J5dGVzGAQgASgDQgPgQQNS
CXNpemVCeXRlc0LDAQofY29tLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MVABWkFjbG91
ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRhbG9nL2FwaXYxL2RhdGFjYXRhbG9ncGI7ZGF0YWNh
dGFsb2dwYqoCG0dvb2dsZS5DbG91ZC5EYXRhQ2F0YWxvZy5WMcoCG0dvb2dsZVxDbG91ZFxE
YXRhQ2F0YWxvZ1xWMeoCHkdvb2dsZTo6Q2xvdWQ6OkRhdGFDYXRhbG9nOjpWMUqDGAoGEgQO
AE8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMA
EgMSACkKCQoCAwESAxMANgoICgEIEgMVADgKCQoCCCUSAxUAOAoICgEIEgMWAFgKCQoCCAsS
AxYAWAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADgKCQoCCAESAxgAOAoICgEIEgMZ
ADgKCQoCCCkSAxkAOAoICgEIEgMaADcKCQoCCC0SAxoANwo2CgIEABIEHQBBARoqIERlc2Ny
aWJlcyBhIENsb3VkIFN0b3JhZ2UgZmlsZXNldCBlbnRyeS4KCgoKAwQAARIDHQgWCpILCgQE
AAIAEgM7Ak0ahAsgUmVxdWlyZWQuIFBhdHRlcm5zIHRvIGlkZW50aWZ5IGEgc2V0IG9mIGZp
bGVzIGluIEdvb2dsZSBDbG91ZCBTdG9yYWdlLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBz
ZWUgW1dpbGRjYXJkIE5hbWVzXQogKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zdG9yYWdl
L2RvY3Mvd2lsZGNhcmRzKS4KCiBOb3RlOiBDdXJyZW50bHksIGJ1Y2tldCB3aWxkY2FyZHMg
YXJlIG5vdCBzdXBwb3J0ZWQuCgogRXhhbXBsZXMgb2YgdmFsaWQgYGZpbGVfcGF0dGVybnNg
OgoKICAqIGBnczovL2J1Y2tldF9uYW1lL2Rpci8qYDogbWF0Y2hlcyBhbGwgZmlsZXMgaW4g
YGJ1Y2tldF9uYW1lL2RpcmAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlyZWN0
b3J5CiAgKiBgZ3M6Ly9idWNrZXRfbmFtZS9kaXIvKipgOiBtYXRjaGVzIGFsbCBmaWxlcyBp
biBgYnVja2V0X25hbWUvZGlyYAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5k
IGFsbCBzdWJkaXJlY3RvcmllcwogICogYGdzOi8vYnVja2V0X25hbWUvZmlsZSpgOiBtYXRj
aGVzIGZpbGVzIHByZWZpeGVkIGJ5IGBmaWxlYCBpbgogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICBgYnVja2V0X25hbWVgCiAgKiBgZ3M6Ly9idWNrZXRfbmFtZS8/Py50eHRgOiBt
YXRjaGVzIGZpbGVzIHdpdGggdHdvIGNoYXJhY3RlcnMgZm9sbG93ZWQgYnkKICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgIGAudHh0YCBpbiBgYnVja2V0X25hbWVgCiAgKiBgZ3M6
Ly9idWNrZXRfbmFtZS9bYWVpb3VdLnR4dGA6IG1hdGNoZXMgZmlsZXMgdGhhdCBjb250YWlu
IGEgc2luZ2xlCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZvd2VsIGNo
YXJhY3RlciBmb2xsb3dlZCBieSBgLnR4dGAgaW4KICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgYGJ1Y2tldF9uYW1lYAogICogYGdzOi8vYnVja2V0X25hbWUvW2EtbV0u
dHh0YDogbWF0Y2hlcyBmaWxlcyB0aGF0IGNvbnRhaW4gYGFgLCBgYmAsIC4uLgogICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgb3IgYG1gIGZvbGxvd2VkIGJ5IGAudHh0YCBp
biBgYnVja2V0X25hbWVgCiAgKiBgZ3M6Ly9idWNrZXRfbmFtZS9hLyovYmA6IG1hdGNoZXMg
YWxsIGZpbGVzIGluIGBidWNrZXRfbmFtZWAgdGhhdCBtYXRjaAogICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICB0aGUgYGEvKi9iYCBwYXR0ZXJuLCBzdWNoIGFzIGBhL2MvYmAsIGBh
L2QvYmAKICAqIGBnczovL2Fub3RoZXJfYnVja2V0L2EudHh0YDogbWF0Y2hlcyBgZ3M6Ly9h
bm90aGVyX2J1Y2tldC9hLnR4dGAKCiBZb3UgY2FuIGNvbWJpbmUgd2lsZGNhcmRzIHRvIG1h
dGNoIGNvbXBsZXggc2V0cyBvZiBmaWxlcywgZm9yIGV4YW1wbGU6CgogYGdzOi8vYnVja2V0
X25hbWUvW2EtbV0/Py5qKmdgCgoMCgUEAAIABBIDOwIKCgwKBQQAAgAFEgM7CxEKDAoFBAAC
AAESAzsSHwoMCgUEAAIAAxIDOyIjCgwKBQQAAgAIEgM7JEwKDwoIBAACAAicCAASAzslSwqD
AQoEBAACARIEPwJAMhp1IE91dHB1dCBvbmx5LiBTYW1wbGUgZmlsZXMgY29udGFpbmVkIGlu
IHRoaXMgZmlsZXNldCwgbm90IGFsbCBmaWxlcwogY29udGFpbmVkIGluIHRoaXMgZmlsZXNl
dCBhcmUgcmVwcmVzZW50ZWQgaGVyZS4KCgwKBQQAAgEEEgM/AgoKDAoFBAACAQYSAz8LFgoM
CgUEAAIBARIDPxcsCgwKBQQAAgEDEgM/LzAKDAoFBAACAQgSA0AGMQoPCggEAAIBCJwIABID
QAcwCj4KAgQBEgREAE8BGjIgU3BlY2lmaWNhdGlvbiBvZiBhIHNpbmdsZSBmaWxlIGluIENs
b3VkIFN0b3JhZ2UuCgoKCgMEAQESA0QIEwpNCgQEAQIAEgNGAkAaQCBSZXF1aXJlZC4gRnVs
bCBmaWxlIHBhdGguIEV4YW1wbGU6IGBnczovL2J1Y2tldF9uYW1lL2EvYi50eHRgLgoKDAoF
BAECAAUSA0YCCAoMCgUEAQIAARIDRgkSCgwKBQQBAgADEgNGFRYKDAoFBAECAAgSA0YXPwoP
CggEAQIACJwIABIDRhg+CmgKBAQBAgESBEoCSzIaWiBPdXRwdXQgb25seS4gQ3JlYXRpb24s
IG1vZGlmaWNhdGlvbiwgYW5kIGV4cGlyYXRpb24gdGltZXN0YW1wcyBvZiBhIENsb3VkCiBT
dG9yYWdlIGZpbGUuCgoMCgUEAQIBBhIDSgISCgwKBQQBAgEBEgNKEyEKDAoFBAECAQMSA0ok
JQoMCgUEAQIBCBIDSwYxCg8KCAQBAgEInAgAEgNLBzAKLwoEBAECAhIDTgJDGiIgT3V0cHV0
IG9ubHkuIEZpbGUgc2l6ZSBpbiBieXRlcy4KCgwKBQQBAgIFEgNOAgcKDAoFBAECAgESA04I
EgoMCgUEAQICAxIDThUWCgwKBQQBAgIIEgNOF0IKDwoIBAECAgicCAASA04YQWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFilesetSpec ===
    # Fields for GcsFilesetSpec
    # Field: file_patterns Type: 9 ()
    # Field: sample_gcs_file_specs Type: 11 (.google.cloud.datacatalog.v1.GcsFileSpec)

# === Message: Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFileSpec ===
    # Fields for GcsFileSpec
    # Field: file_path Type: 9 ()
    # Field: gcs_timestamps Type: 11 (.google.cloud.datacatalog.v1.SystemTimestamps)
    # Field: size_bytes Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::GcsFilesetSpec - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/gcs_fileset_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::GcsFilesetSpec;

    my $msg = Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFilesetSpec->new({
        file_patterns => $file_patterns,
        sample_gcs_file_specs => $sample_gcs_file_specs,
    });

    # Read or update a field
    my $val = $msg->file_patterns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFilesetSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/gcs_fileset_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFilesetSpec

Describes a Cloud Storage fileset entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_patterns() >> / C<< $msg->file_patterns($value) >>

Type: C<String>

Required. Patterns to identify a set of files in Google Cloud Storage.

For more information, see [Wildcard Names]
(https://cloud.google.com/storage/docs/wildcards).

Note: Currently, bucket wildcards are not supported.

Examples of valid `file_patterns`:

 * `gs://bucket_name/dir/*`: matches all files in `bucket_name/dir`
                             directory
 * `gs://bucket_name/dir/**`: matches all files in `bucket_name/dir`
                              and all subdirectories
 * `gs://bucket_name/file*`: matches files prefixed by `file` in
                             `bucket_name`
 * `gs://bucket_name/??.txt`: matches files with two characters followed by
                              `.txt` in `bucket_name`
 * `gs://bucket_name/[aeiou].txt`: matches files that contain a single
                                   vowel character followed by `.txt` in
                                   `bucket_name`
 * `gs://bucket_name/[a-m].txt`: matches files that contain `a`, `b`, ...
                                 or `m` followed by `.txt` in `bucket_name`
 * `gs://bucket_name/a/*/b`: matches all files in `bucket_name` that match
                             the `a/*/b` pattern, such as `a/c/b`, `a/d/b`
 * `gs://another_bucket/a.txt`: matches `gs://another_bucket/a.txt`

You can combine wildcards to match complex sets of files, for example:

`gs://bucket_name/[a-m]??.j*g`

=item * C<< $msg->sample_gcs_file_specs() >> / C<< $msg->sample_gcs_file_specs($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFileSpec>)

Output only. Sample files contained in this fileset, not all files
contained in this fileset are represented here.

=back

=head2 Google::Cloud::Datacatalog::V1::GcsFilesetSpec::GcsFileSpec

Specification of a single file in Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_path() >> / C<< $msg->file_path($value) >>

Type: C<String>

Required. Full file path. Example: `gs://bucket_name/a/b.txt`.

=item * C<< $msg->gcs_timestamps() >> / C<< $msg->gcs_timestamps($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps>)

Output only. Creation, modification, and expiration timestamps of a Cloud
Storage file.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

Output only. File size in bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::GcsFilesetSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
