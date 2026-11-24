package Google::Cloud::Datacatalog::V1::DataSource;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvZGF0YV9zb3VyY2UucHJvdG8SG2dvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
byLPAgoKRGF0YVNvdXJjZRJJCgdzZXJ2aWNlGAEgASgOMi8uZ29vZ2xlLmNsb3VkLmRhdGFj
YXRhbG9nLnYxLkRhdGFTb3VyY2UuU2VydmljZVIHc2VydmljZRIaCghyZXNvdXJjZRgCIAEo
CVIIcmVzb3VyY2USJgoMc291cmNlX2VudHJ5GAMgASgJQgPgQQNSC3NvdXJjZUVudHJ5El8K
EnN0b3JhZ2VfcHJvcGVydGllcxgEIAEoCzIuLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52
MS5TdG9yYWdlUHJvcGVydGllc0gAUhFzdG9yYWdlUHJvcGVydGllcyJDCgdTZXJ2aWNlEhcK
E1NFUlZJQ0VfVU5TUEVDSUZJRUQQABIRCg1DTE9VRF9TVE9SQUdFEAESDAoIQklHUVVFUlkQ
AkIMCgpwcm9wZXJ0aWVzIlMKEVN0b3JhZ2VQcm9wZXJ0aWVzEiEKDGZpbGVfcGF0dGVybhgB
IAMoCVILZmlsZVBhdHRlcm4SGwoJZmlsZV90eXBlGAIgASgJUghmaWxlVHlwZULUAQofY29t
Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MUIPRGF0YVNvdXJjZVByb3RvUAFaQWNsb3Vk
Lmdvb2dsZS5jb20vZ28vZGF0YWNhdGFsb2cvYXBpdjEvZGF0YWNhdGFsb2dwYjtkYXRhY2F0
YWxvZ3BiqgIbR29vZ2xlLkNsb3VkLkRhdGFDYXRhbG9nLlYxygIbR29vZ2xlXENsb3VkXERh
dGFDYXRhbG9nXFYx6gIeR29vZ2xlOjpDbG91ZDo6RGF0YUNhdGFsb2c6OlYxSr0YCgYSBA4A
VQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwAS
AxIAKQoICgEIEgMUADgKCQoCCCUSAxQAOAoICgEIEgMVAFgKCQoCCAsSAxUAWAoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYADgKCQoCCAESAxgA
OAoICgEIEgMZADgKCQoCCCkSAxkAOAoICgEIEgMaADcKCQoCCC0SAxoANwosCgIEABIEHQA5
ARogIFBoeXNpY2FsIGxvY2F0aW9uIG9mIGFuIGVudHJ5LgoKCgoDBAABEgMdCBIKNwoEBAAE
ABIEHwIoAxopIE5hbWUgb2YgYSBzZXJ2aWNlIHRoYXQgc3RvcmVzIHRoZSBkYXRhLgoKDAoF
BAAEAAESAx8HDgopCgYEAAQAAgASAyEEHBoaIERlZmF1bHQgdW5rbm93biBzZXJ2aWNlLgoK
DgoHBAAEAAIAARIDIQQXCg4KBwQABAACAAISAyEaGwouCgYEAAQAAgESAyQEFhofIEdvb2ds
ZSBDbG91ZCBTdG9yYWdlIHNlcnZpY2UuCgoOCgcEAAQAAgEBEgMkBBEKDgoHBAAEAAIBAhID
JBQVCiIKBgQABAACAhIDJwQRGhMgQmlnUXVlcnkgc2VydmljZS4KCg4KBwQABAACAgESAycE
DAoOCgcEAAQAAgICEgMnDxAKNwoEBAACABIDKwIWGiogU2VydmljZSB0aGF0IHBoeXNpY2Fs
bHkgc3RvcmVzIHRoZSBkYXRhLgoKDAoFBAACAAYSAysCCQoMCgUEAAIAARIDKwoRCgwKBQQA
AgADEgMrFBUKwAEKBAQAAgESAzACFhqyASBGdWxsIG5hbWUgb2YgYSByZXNvdXJjZSBhcyBk
ZWZpbmVkIGJ5IHRoZSBzZXJ2aWNlLiBGb3IgZXhhbXBsZToKCiBgLy9iaWdxdWVyeS5nb29n
bGVhcGlzLmNvbS9wcm9qZWN0cy97UFJPSkVDVF9JRH0vbG9jYXRpb25zL3tMT0NBVElPTn0v
ZGF0YXNldHMve0RBVEFTRVRfSUR9L3RhYmxlcy97VEFCTEVfSUR9YAoKDAoFBAACAQUSAzAC
CAoMCgUEAAIBARIDMAkRCgwKBQQAAgEDEgMwFBUKQwoEBAACAhIDMwJGGjYgT3V0cHV0IG9u
bHkuIERhdGEgQ2F0YWxvZyBlbnRyeSBuYW1lLCBpZiBhcHBsaWNhYmxlLgoKDAoFBAACAgUS
AzMCCAoMCgUEAAICARIDMwkVCgwKBQQAAgIDEgMzGBkKDAoFBAACAggSAzMaRQoPCggEAAIC
CJwIABIDMxtECgwKBAQACAASBDUCOAMKDAoFBAAIAAESAzUIEgo9CgQEAAIDEgM3BC0aMCBE
ZXRhaWxlZCBwcm9wZXJ0aWVzIG9mIHRoZSB1bmRlcmx5aW5nIHN0b3JhZ2UuCgoMCgUEAAID
BhIDNwQVCgwKBQQAAgMBEgM3FigKDAoFBAACAwMSAzcrLAo/CgIEARIEPABVARozIERldGFp
bHMgdGhlIHByb3BlcnRpZXMgb2YgdGhlIHVuZGVybHlpbmcgc3RvcmFnZS4KCgoKAwQBARID
PAgZCpQJCgQEAQIAEgNRAiMahgkgUGF0dGVybnMgdG8gaWRlbnRpZnkgYSBzZXQgb2YgZmls
ZXMgZm9yIHRoaXMgZmlsZXNldC4KCiBFeGFtcGxlcyBvZiBhIHZhbGlkIGBmaWxlX3BhdHRl
cm5gOgoKICAqIGBnczovL2J1Y2tldF9uYW1lL2Rpci8qYDogbWF0Y2hlcyBhbGwgZmlsZXMg
aW4gdGhlIGBidWNrZXRfbmFtZS9kaXJgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
IGRpcmVjdG9yeQogICogYGdzOi8vYnVja2V0X25hbWUvZGlyLyoqYDogbWF0Y2hlcyBhbGwg
ZmlsZXMgaW4gdGhlIGBidWNrZXRfbmFtZS9kaXJgCiAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICBhbmQgYWxsIHN1YmRpcmVjdG9yaWVzIHJlY3Vyc2l2ZWx5CiAgKiBgZ3M6Ly9i
dWNrZXRfbmFtZS9maWxlKmA6IG1hdGNoZXMgZmlsZXMgcHJlZml4ZWQgYnkgYGZpbGVgIGlu
CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGBidWNrZXRfbmFtZWAKICAqIGBnczov
L2J1Y2tldF9uYW1lLz8/LnR4dGA6IG1hdGNoZXMgZmlsZXMgd2l0aCB0d28gY2hhcmFjdGVy
cyBmb2xsb3dlZCBieQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYC50eHRgIGlu
IGBidWNrZXRfbmFtZWAKICAqIGBnczovL2J1Y2tldF9uYW1lL1thZWlvdV0udHh0YDogbWF0
Y2hlcyBmaWxlcyB0aGF0IGNvbnRhaW4gYSBzaW5nbGUKICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgdm93ZWwgY2hhcmFjdGVyIGZvbGxvd2VkIGJ5IGAudHh0YCBpbgog
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgYnVja2V0X25hbWVgCiAgKiBg
Z3M6Ly9idWNrZXRfbmFtZS9bYS1tXS50eHRgOiBtYXRjaGVzIGZpbGVzIHRoYXQgY29udGFp
biBgYWAsIGBiYCwgLi4uCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvciBg
bWAgZm9sbG93ZWQgYnkgYC50eHRgIGluIGBidWNrZXRfbmFtZWAKICAqIGBnczovL2J1Y2tl
dF9uYW1lL2EvKi9iYDogbWF0Y2hlcyBhbGwgZmlsZXMgaW4gYGJ1Y2tldF9uYW1lYCB0aGF0
IG1hdGNoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRoZSBgYS8qL2JgIHBhdHRl
cm4sIHN1Y2ggYXMgYGEvYy9iYCwgYGEvZC9iYAogICogYGdzOi8vYW5vdGhlcl9idWNrZXQv
YS50eHRgOiBtYXRjaGVzIGBnczovL2Fub3RoZXJfYnVja2V0L2EudHh0YAoKDAoFBAECAAQS
A1ECCgoMCgUEAQIABRIDUQsRCgwKBQQBAgABEgNREh4KDAoFBAECAAMSA1EhIgpDCgQEAQIB
EgNUAhcaNiBGaWxlIHR5cGUgaW4gTUlNRSBmb3JtYXQsIGZvciBleGFtcGxlLCBgdGV4dC9w
bGFpbmAuCgoMCgUEAQIBBRIDVAIICgwKBQQBAgEBEgNUCRIKDAoFBAECAQMSA1QVFmIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::DataSource::DataSource ===
    # Fields for DataSource
    # Field: service Type: 14 (.google.cloud.datacatalog.v1.DataSource.Service)
    # Field: resource Type: 9 ()
    # Field: source_entry Type: 9 ()
    # Field: storage_properties Type: 11 (.google.cloud.datacatalog.v1.StorageProperties)

# Enum: DataSource::Service
our $DataSource_SERVICE_UNSPECIFIED = 0;
our $DataSource_CLOUD_STORAGE = 1;
our $DataSource_BIGQUERY = 2;

# === Message: Google::Cloud::Datacatalog::V1::DataSource::StorageProperties ===
    # Fields for StorageProperties
    # Field: file_pattern Type: 9 ()
    # Field: file_type Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::DataSource - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/data_source.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::DataSource;

    my $msg = Google::Cloud::Datacatalog::V1::DataSource::DataSource->new({
        service => $service,
        resource => $resource,
        source_entry => $source_entry,
        storage_properties => $storage_properties,
    });

    # Read or update a field
    my $val = $msg->service();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::DataSource::DataSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/data_source.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::DataSource::DataSource

Physical location of an entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::DataSource::Service>)

Service that physically stores the data.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Full name of a resource as defined by the service. For example:

`//bigquery.googleapis.com/projects/{PROJECT_ID}/locations/{LOCATION}/datasets/{DATASET_ID}/tables/{TABLE_ID}`

=item * C<< $msg->source_entry() >> / C<< $msg->source_entry($value) >>

Type: C<String>

Output only. Data Catalog entry name, if applicable.

=item * C<< $msg->storage_properties() >> / C<< $msg->storage_properties($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::DataSource::StorageProperties>)

Detailed properties of the underlying storage.

=back

=head3 Enum: DataSource::Service

=over 4

=item * C<SERVICE_UNSPECIFIED> => C<0>

=item * C<CLOUD_STORAGE> => C<1>

=item * C<BIGQUERY> => C<2>

=back

=head2 Google::Cloud::Datacatalog::V1::DataSource::StorageProperties

Details the properties of the underlying storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_pattern() >> / C<< $msg->file_pattern($value) >>

Type: C<String>

Patterns to identify a set of files for this fileset.

Examples of a valid `file_pattern`:

 * `gs://bucket_name/dir/*`: matches all files in the `bucket_name/dir`
                             directory
 * `gs://bucket_name/dir/**`: matches all files in the `bucket_name/dir`
                              and all subdirectories recursively
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

=item * C<< $msg->file_type() >> / C<< $msg->file_type($value) >>

Type: C<String>

File type in MIME format, for example, `text/plain`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::DataSource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
