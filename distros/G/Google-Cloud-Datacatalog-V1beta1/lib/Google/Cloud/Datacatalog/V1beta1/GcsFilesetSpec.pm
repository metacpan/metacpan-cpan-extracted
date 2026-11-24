package Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Datacatalog::V1beta1::Timestamps };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS9nY3NfZmlsZXNldF9zcGVjLnBy
b3RvEiBnb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoxZ29vZ2xlL2Nsb3VkL2RhdGFjYXRhbG9nL3YxYmV0YTEvdGlt
ZXN0YW1wcy5wcm90byKhAQoOR2NzRmlsZXNldFNwZWMSKAoNZmlsZV9wYXR0ZXJucxgBIAMo
CUID4EECUgxmaWxlUGF0dGVybnMSZQoVc2FtcGxlX2djc19maWxlX3NwZWNzGAIgAygLMi0u
Z29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuR2NzRmlsZVNwZWNCA+BBA1ISc2Ft
cGxlR2NzRmlsZVNwZWNzIrMBCgtHY3NGaWxlU3BlYxIgCglmaWxlX3BhdGgYASABKAlCA+BB
AlIIZmlsZVBhdGgSXgoOZ2NzX3RpbWVzdGFtcHMYAiABKAsyMi5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjFiZXRhMS5TeXN0ZW1UaW1lc3RhbXBzQgPgQQNSDWdjc1RpbWVzdGFtcHMS
IgoKc2l6ZV9ieXRlcxgEIAEoA0ID4EEDUglzaXplQnl0ZXNC3AEKJGNvbS5nb29nbGUuY2xv
dWQuZGF0YWNhdGFsb2cudjFiZXRhMVABWkZjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRh
bG9nL2FwaXYxYmV0YTEvZGF0YWNhdGFsb2dwYjtkYXRhY2F0YWxvZ3BiqgIgR29vZ2xlLkNs
b3VkLkRhdGFDYXRhbG9nLlYxQmV0YTHKAiBHb29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dcVjFi
ZXRhMeoCI0dvb2dsZTo6Q2xvdWQ6OkRhdGFDYXRhbG9nOjpWMWJldGExSogYCgYSBA4ATQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCQoCAwASAxIA
KQoJCgIDARIDEwA7CggKAQgSAxUAPQoJCgIIJRIDFQA9CggKAQgSAxYAXQoJCgIICxIDFgBd
CggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAPQoJCgIIARIDGAA9CggKAQgSAxkAPQoJ
CgIIKRIDGQA9CggKAQgSAxoAPAoJCgIILRIDGgA8CjYKAgQAEgQdAEABGiogRGVzY3JpYmVz
IGEgQ2xvdWQgU3RvcmFnZSBmaWxlc2V0IGVudHJ5LgoKCgoDBAABEgMdCBYKqQsKBAQAAgAS
AzoCTRqbCyBSZXF1aXJlZC4gUGF0dGVybnMgdG8gaWRlbnRpZnkgYSBzZXQgb2YgZmlsZXMg
aW4gR29vZ2xlIENsb3VkIFN0b3JhZ2UuCiBTZWUgW0Nsb3VkIFN0b3JhZ2UKIGRvY3VtZW50
YXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zdG9yYWdlL2RvY3Mvd2lsZGNhcmRz
KQogZm9yIG1vcmUgaW5mb3JtYXRpb24uIE5vdGUgdGhhdCBidWNrZXQgd2lsZGNhcmRzIGFy
ZSBjdXJyZW50bHkgbm90CiBzdXBwb3J0ZWQuCgogRXhhbXBsZXMgb2YgdmFsaWQgZmlsZV9w
YXR0ZXJuczoKCiAgKiBgZ3M6Ly9idWNrZXRfbmFtZS9kaXIvKmA6IG1hdGNoZXMgYWxsIGZp
bGVzIHdpdGhpbiBgYnVja2V0X25hbWUvZGlyYAogICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICBkaXJlY3RvcnkuCiAgKiBgZ3M6Ly9idWNrZXRfbmFtZS9kaXIvKipgOiBtYXRjaGVz
IGFsbCBmaWxlcyBpbiBgYnVja2V0X25hbWUvZGlyYAogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgc3Bhbm5pbmcgYWxsIHN1YmRpcmVjdG9yaWVzLgogICogYGdzOi8vYnVja2V0
X25hbWUvZmlsZSpgOiBtYXRjaGVzIGZpbGVzIHByZWZpeGVkIGJ5IGBmaWxlYCBpbgogICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICBgYnVja2V0X25hbWVgCiAgKiBgZ3M6Ly9idWNr
ZXRfbmFtZS8/Py50eHRgOiBtYXRjaGVzIGZpbGVzIHdpdGggdHdvIGNoYXJhY3RlcnMgZm9s
bG93ZWQgYnkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGAudHh0YCBpbiBgYnVj
a2V0X25hbWVgCiAgKiBgZ3M6Ly9idWNrZXRfbmFtZS9bYWVpb3VdLnR4dGA6IG1hdGNoZXMg
ZmlsZXMgdGhhdCBjb250YWluIGEgc2luZ2xlCiAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgIHZvd2VsIGNoYXJhY3RlciBmb2xsb3dlZCBieSBgLnR4dGAgaW4KICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYGJ1Y2tldF9uYW1lYAogICogYGdzOi8v
YnVja2V0X25hbWUvW2EtbV0udHh0YDogbWF0Y2hlcyBmaWxlcyB0aGF0IGNvbnRhaW4gYGFg
LCBgYmAsIC4uLgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb3IgYG1gIGZv
bGxvd2VkIGJ5IGAudHh0YCBpbiBgYnVja2V0X25hbWVgCiAgKiBgZ3M6Ly9idWNrZXRfbmFt
ZS9hLyovYmA6IG1hdGNoZXMgYWxsIGZpbGVzIGluIGBidWNrZXRfbmFtZWAgdGhhdCBtYXRj
aAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgYS8qL2JgIHBhdHRlcm4sIHN1Y2gg
YXMgYGEvYy9iYCwgYGEvZC9iYAogICogYGdzOi8vYW5vdGhlcl9idWNrZXQvYS50eHRgOiBt
YXRjaGVzIGBnczovL2Fub3RoZXJfYnVja2V0L2EudHh0YAoKIFlvdSBjYW4gY29tYmluZSB3
aWxkY2FyZHMgdG8gcHJvdmlkZSBtb3JlIHBvd2VyZnVsIG1hdGNoZXMsIGZvciBleGFtcGxl
OgoKICAqIGBnczovL2J1Y2tldF9uYW1lL1thLW1dPz8uaipnYAoKDAoFBAACAAQSAzoCCgoM
CgUEAAIABRIDOgsRCgwKBQQAAgABEgM6Eh8KDAoFBAACAAMSAzoiIwoMCgUEAAIACBIDOiRM
Cg8KCAQAAgAInAgAEgM6JUsKgwEKBAQAAgESBD4CPzIadSBPdXRwdXQgb25seS4gU2FtcGxl
IGZpbGVzIGNvbnRhaW5lZCBpbiB0aGlzIGZpbGVzZXQsIG5vdCBhbGwgZmlsZXMKIGNvbnRh
aW5lZCBpbiB0aGlzIGZpbGVzZXQgYXJlIHJlcHJlc2VudGVkIGhlcmUuCgoMCgUEAAIBBBID
PgIKCgwKBQQAAgEGEgM+CxYKDAoFBAACAQESAz4XLAoMCgUEAAIBAxIDPi8wCgwKBQQAAgEI
EgM/BjEKDwoIBAACAQicCAASAz8HMAo/CgIEARIEQwBNARozIFNwZWNpZmljYXRpb25zIG9m
IGEgc2luZ2xlIGZpbGUgaW4gQ2xvdWQgU3RvcmFnZS4KCgoKAwQBARIDQwgTClEKBAQBAgAS
A0UCQBpEIFJlcXVpcmVkLiBUaGUgZnVsbCBmaWxlIHBhdGguIEV4YW1wbGU6IGBnczovL2J1
Y2tldF9uYW1lL2EvYi50eHRgLgoKDAoFBAECAAUSA0UCCAoMCgUEAQIAARIDRQkSCgwKBQQB
AgADEgNFFRYKDAoFBAECAAgSA0UXPwoPCggEAQIACJwIABIDRRg+CkUKBAQBAgESBEgCSTIa
NyBPdXRwdXQgb25seS4gVGltZXN0YW1wcyBhYm91dCB0aGUgQ2xvdWQgU3RvcmFnZSBmaWxl
LgoKDAoFBAECAQYSA0gCEgoMCgUEAQIBARIDSBMhCgwKBQQBAgEDEgNIJCUKDAoFBAECAQgS
A0kGMQoPCggEAQIBCJwIABIDSQcwCjsKBAQBAgISA0wCQxouIE91dHB1dCBvbmx5LiBUaGUg
c2l6ZSBvZiB0aGUgZmlsZSwgaW4gYnl0ZXMuCgoMCgUEAQICBRIDTAIHCgwKBQQBAgIBEgNM
CBIKDAoFBAECAgMSA0wVFgoMCgUEAQICCBIDTBdCCg8KCAQBAgIInAgAEgNMGEFiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec ===
    # Fields for GcsFilesetSpec
    # Field: file_patterns Type: 9 ()
    # Field: sample_gcs_file_specs Type: 11 (.google.cloud.datacatalog.v1beta1.GcsFileSpec)

# === Message: Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFileSpec ===
    # Fields for GcsFileSpec
    # Field: file_path Type: 9 ()
    # Field: gcs_timestamps Type: 11 (.google.cloud.datacatalog.v1beta1.SystemTimestamps)
    # Field: size_bytes Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/gcs_fileset_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec;

    my $msg = Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec->new({
        file_patterns => $file_patterns,
        sample_gcs_file_specs => $sample_gcs_file_specs,
    });

    # Read or update a field
    my $val = $msg->file_patterns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/gcs_fileset_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec

Describes a Cloud Storage fileset entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_patterns() >> / C<< $msg->file_patterns($value) >>

Type: C<String>

Required. Patterns to identify a set of files in Google Cloud Storage.
See [Cloud Storage
documentation](https://cloud.google.com/storage/docs/wildcards)
for more information. Note that bucket wildcards are currently not
supported.

Examples of valid file_patterns:

 * `gs://bucket_name/dir/*`: matches all files within `bucket_name/dir`
                             directory.
 * `gs://bucket_name/dir/**`: matches all files in `bucket_name/dir`
                              spanning all subdirectories.
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
                             `a/*/b` pattern, such as `a/c/b`, `a/d/b`
 * `gs://another_bucket/a.txt`: matches `gs://another_bucket/a.txt`

You can combine wildcards to provide more powerful matches, for example:

 * `gs://bucket_name/[a-m]??.j*g`

=item * C<< $msg->sample_gcs_file_specs() >> / C<< $msg->sample_gcs_file_specs($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFileSpec>)

Output only. Sample files contained in this fileset, not all files
contained in this fileset are represented here.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFileSpec

Specifications of a single file in Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_path() >> / C<< $msg->file_path($value) >>

Type: C<String>

Required. The full file path. Example: `gs://bucket_name/a/b.txt`.

=item * C<< $msg->gcs_timestamps() >> / C<< $msg->gcs_timestamps($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Timestamps::SystemTimestamps>)

Output only. Timestamps about the Cloud Storage file.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

Output only. The size of the file, in bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
