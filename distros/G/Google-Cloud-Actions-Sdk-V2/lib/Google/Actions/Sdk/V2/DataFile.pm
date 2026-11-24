package Google::Actions::Sdk::V2::DataFile;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvYWN0aW9ucy9zZGsvdjIvZGF0YV9maWxlLnByb3RvEhVnb29nbGUuYWN0aW9u
cy5zZGsudjIiSwoJRGF0YUZpbGVzEj4KCmRhdGFfZmlsZXMYASADKAsyHy5nb29nbGUuYWN0
aW9ucy5zZGsudjIuRGF0YUZpbGVSCWRhdGFGaWxlcyJkCghEYXRhRmlsZRIbCglmaWxlX3Bh
dGgYASABKAlSCGZpbGVQYXRoEiEKDGNvbnRlbnRfdHlwZRgCIAEoCVILY29udGVudFR5cGUS
GAoHcGF5bG9hZBgDIAEoDFIHcGF5bG9hZEJmChljb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYy
Qg1EYXRhRmlsZVByb3RvUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFw
aXMvYWN0aW9ucy9zZGsvdjI7c2RrSpgRCgYSBA4AOgEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQAB4KCAoBCBIDEgBPCgkKAggLEgMSAE8KCAoBCBIDEwAi
CgkKAggKEgMTACIKCAoBCBIDFAAuCgkKAggIEgMUAC4KCAoBCBIDFQAyCgkKAggBEgMVADIK
VgoCBAASBBgAGwEaSiBXcmFwcGVyIGZvciByZXBlYXRlZCBkYXRhIGZpbGUuIFJlcGVhdGVk
IGZpZWxkcyBjYW5ub3QgZXhpc3QgaW4gYSBvbmVvZi4KCgoKAwQAARIDGAgRCiMKBAQAAgAS
AxoCIxoWIE11bHRpcGxlIGRhdGEgZmlsZXMuCgoMCgUEAAIABBIDGgIKCgwKBQQAAgAGEgMa
CxMKDAoFBAACAAESAxoUHgoMCgUEAAIAAxIDGiEiCpUBCgIEARIEHwA6ARqIASBSZXByZXNl
bnRzIGEgc2luZ2xlIGZpbGUgd2hpY2ggY29udGFpbnMgdW5zdHJ1Y3R1cmVkIGRhdGEuIEV4
YW1wbGVzIGluY2x1ZGUKIGltYWdlIGZpbGVzLCBhdWRpbyBmaWxlcywgYW5kIGNsb3VkIGZ1
bmN0aW9uIHNvdXJjZSBjb2RlLgoKCgoDBAEBEgMfCBAK3wMKBAQBAgASAywCFxrRAyBSZWxh
dGl2ZSBwYXRoIG9mIHRoZSBkYXRhIGZpbGUgZnJvbSB0aGUgcHJvamVjdCByb290IGluIHRo
ZSBTREsgZmlsZQogc3RydWN0dXJlLgogQWxsb3dlZCBmaWxlIHBhdGhzOgogICAgIC0gSW1h
Z2VzOiBgcmVzb3VyY2VzL2ltYWdlcy97bXVsdGlwbGUKICAgICBkaXJlY3Rvcmllc30/L3tJ
bWFnZU5hbWV9LntleHRlbnNpb259YAogICAgIC0gQXVkaW86IGByZXNvdXJjZXMvYXVkaW8v
e211bHRpcGxlCiAgICAgZGlyZWN0b3JpZXN9Py97QXVkaW9GaWxlTmFtZX0ue2V4dGVuc2lv
bn1gCiAgICAgLSBJbmxpbmUgQ2xvdWQgRnVuY3Rpb24gQ29kZTogYHdlYmhvb2tzL3tXZWJo
b29rTmFtZX0uemlwYAogQWxsb3dlZCBleHRlbnNpb25zOgogICAgIC0gSW1hZ2VzOiBgcG5n
YCwgYGpwZ2AsIGBqcGVnYAogICAgIC0gQXVkaW86IGBtcDNgLCBgbXBlZ2AKICAgICAtIElu
bGluZSBDbG91ZCBGdW5jdGlvbnM6IGB6aXBgCgoMCgUEAQIABRIDLAIICgwKBQQBAgABEgMs
CRIKDAoFBAECAAMSAywVFgr6AgoEBAECARIDNAIaGuwCIFJlcXVpcmVkLiBUaGUgY29udGVu
dCB0eXBlIG9mIHRoaXMgYXNzZXQuIEV4YW1wbGU6IGB0ZXh0L2h0bWxgLiBUaGUgY29udGVu
dAogdHlwZSBtdXN0IGNvbXBseSB3aXRoIHRoZSBzcGVjaWZpY2F0aW9uCiAoaHR0cDovL3d3
dy53My5vcmcvUHJvdG9jb2xzL3JmYzEzNDEvNF9Db250ZW50LVR5cGUuaHRtbCkuCiBDbG91
ZCBmdW5jdGlvbnMgbXVzdCBiZSBpbiB6aXAgZm9ybWF0IGFuZCB0aGUgY29udGVudCB0eXBl
IHNob3VsZAogYmUgYGFwcGxpY2F0aW9uL3ppcDt6aXBfdHlwZT1jbG91ZF9mdW5jdGlvbmAu
IFRoZSB6aXBfdHlwZSBwYXJhbWV0ZXIKIGluZGljYXRlcyB0aGF0IHRoZSB6aXAgaXMgZm9y
IGEgY2xvdWQgZnVuY3Rpb24uCgoMCgUEAQIBBRIDNAIICgwKBQQBAgEBEgM0CRUKDAoFBAEC
AQMSAzQYGQquAQoEBAECAhIDOQIUGqABIENvbnRlbnQgb2YgdGhlIGRhdGEgZmlsZS4gRXhh
bXBsZXMgd291bGQgYmUgcmF3IGJ5dGVzIG9mIGltYWdlcywgYXVkaW8KIGZpbGVzLCBvciBj
bG91ZCBmdW5jdGlvbiB6aXAgZm9ybWF0LgogVGhlcmUgaXMgMTAgTUIgc3RyaWN0IGxpbWl0
IG9uIHRoZSBwYXlsb2FkIHNpemUuCgoMCgUEAQICBRIDOQIHCgwKBQQBAgIBEgM5CA8KDAoF
BAECAgMSAzkSE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::DataFile::DataFiles ===
    # Fields for DataFiles
    # Field: data_files Type: 11 (.google.actions.sdk.v2.DataFile)

# === Message: Google::Actions::Sdk::V2::DataFile::DataFile ===
    # Fields for DataFile
    # Field: file_path Type: 9 ()
    # Field: content_type Type: 9 ()
    # Field: payload Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::DataFile - Compiled Protocol Buffers messages for google/actions/sdk/v2/data_file.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::DataFile;

    my $msg = Google::Actions::Sdk::V2::DataFile::DataFiles->new({
        data_files => $data_files,
    });

    # Read or update a field
    my $val = $msg->data_files();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::DataFile::DataFiles->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/data_file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::DataFile::DataFiles

Wrapper for repeated data file. Repeated fields cannot exist in a oneof.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_files() >> / C<< $msg->data_files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::DataFile::DataFile>)

Multiple data files.

=back

=head2 Google::Actions::Sdk::V2::DataFile::DataFile

Represents a single file which contains unstructured data. Examples include
image files, audio files, and cloud function source code.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_path() >> / C<< $msg->file_path($value) >>

Type: C<String>

Relative path of the data file from the project root in the SDK file
structure.
Allowed file paths:
    - Images: `resources/images/{multiple
    directories}?/{ImageName}.{extension}`
    - Audio: `resources/audio/{multiple
    directories}?/{AudioFileName}.{extension}`
    - Inline Cloud Function Code: `webhooks/{WebhookName}.zip`
Allowed extensions:
    - Images: `png`, `jpg`, `jpeg`
    - Audio: `mp3`, `mpeg`
    - Inline Cloud Functions: `zip`

=item * C<< $msg->content_type() >> / C<< $msg->content_type($value) >>

Type: C<String>

Required. The content type of this asset. Example: `text/html`. The content
type must comply with the specification
(http://www.w3.org/Protocols/rfc1341/4_Content-Type.html).
Cloud functions must be in zip format and the content type should
be `application/zip;zip_type=cloud_function`. The zip_type parameter
indicates that the zip is for a cloud function.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

Content of the data file. Examples would be raw bytes of images, audio
files, or cloud function zip format.
There is 10 MB strict limit on the payload size.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::DataFile::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
