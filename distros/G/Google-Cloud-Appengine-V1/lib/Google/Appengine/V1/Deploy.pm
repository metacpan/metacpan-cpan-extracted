package Google::Appengine::V1::Deploy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvYXBwZW5naW5lL3YxL2RlcGxveS5wcm90bxITZ29vZ2xlLmFwcGVuZ2luZS52
MRoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIvECCgpEZXBsb3ltZW50EkAKBWZp
bGVzGAEgAygLMiouZ29vZ2xlLmFwcGVuZ2luZS52MS5EZXBsb3ltZW50LkZpbGVzRW50cnlS
BWZpbGVzEkAKCWNvbnRhaW5lchgCIAEoCzIiLmdvb2dsZS5hcHBlbmdpbmUudjEuQ29udGFp
bmVySW5mb1IJY29udGFpbmVyEi4KA3ppcBgDIAEoCzIcLmdvb2dsZS5hcHBlbmdpbmUudjEu
WmlwSW5mb1IDemlwElYKE2Nsb3VkX2J1aWxkX29wdGlvbnMYBiABKAsyJi5nb29nbGUuYXBw
ZW5naW5lLnYxLkNsb3VkQnVpbGRPcHRpb25zUhFjbG91ZEJ1aWxkT3B0aW9ucxpXCgpGaWxl
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjMKBXZhbHVlGAIgASgLMh0uZ29vZ2xlLmFwcGVu
Z2luZS52MS5GaWxlSW5mb1IFdmFsdWU6AjgBImEKCEZpbGVJbmZvEh0KCnNvdXJjZV91cmwY
ASABKAlSCXNvdXJjZVVybBIZCghzaGExX3N1bRgCIAEoCVIHc2hhMVN1bRIbCgltaW1lX3R5
cGUYAyABKAlSCG1pbWVUeXBlIiUKDUNvbnRhaW5lckluZm8SFAoFaW1hZ2UYASABKAlSBWlt
YWdlIoIBChFDbG91ZEJ1aWxkT3B0aW9ucxIiCg1hcHBfeWFtbF9wYXRoGAEgASgJUgthcHBZ
YW1sUGF0aBJJChNjbG91ZF9idWlsZF90aW1lb3V0GAIgASgLMhkuZ29vZ2xlLnByb3RvYnVm
LkR1cmF0aW9uUhFjbG91ZEJ1aWxkVGltZW91dCJJCgdaaXBJbmZvEh0KCnNvdXJjZV91cmwY
AyABKAlSCXNvdXJjZVVybBIfCgtmaWxlc19jb3VudBgEIAEoBVIKZmlsZXNDb3VudEK8AQoX
Y29tLmdvb2dsZS5hcHBlbmdpbmUudjFCC0RlcGxveVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5j
b20vZ28vYXBwZW5naW5lL2FwaXYxL2FwcGVuZ2luZXBiO2FwcGVuZ2luZXBiqgIZR29vZ2xl
LkNsb3VkLkFwcEVuZ2luZS5WMcoCGUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVcVjHqAhxHb29n
bGU6OkNsb3VkOjpBcHBFbmdpbmU6OlYxSrAfCgYSBA4AagEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKAoICgEIEgMUADYKCQoCCCUS
AxQANgoICgEIEgMVAFIKCQoCCAsSAxUAUgoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ACwKCQoCCAgSAxcALAoICgEIEgMYADAKCQoCCAESAxgAMAoICgEIEgMZADYKCQoCCCkSAxkA
NgoICgEIEgMaADUKCQoCCC0SAxoANQpUCgIEABIEHQAwARpIIENvZGUgYW5kIGFwcGxpY2F0
aW9uIGFydGlmYWN0cyB1c2VkIHRvIGRlcGxveSBhIHZlcnNpb24gdG8gQXBwIEVuZ2luZS4K
CgoKAwQAARIDHQgSCrsBCgQEAAIAEgMhAiIarQEgTWFuaWZlc3Qgb2YgdGhlIGZpbGVzIHN0
b3JlZCBpbiBHb29nbGUgQ2xvdWQgU3RvcmFnZSB0aGF0IGFyZSBpbmNsdWRlZAogYXMgcGFy
dCBvZiB0aGlzIHZlcnNpb24uIEFsbCBmaWxlcyBtdXN0IGJlIHJlYWRhYmxlIHVzaW5nIHRo
ZQogY3JlZGVudGlhbHMgc3VwcGxpZWQgd2l0aCB0aGlzIGNhbGwuCgoMCgUEAAIABhIDIQIX
CgwKBQQAAgABEgMhGB0KDAoFBAACAAMSAyEgIQqYAQoEBAACARIDJQIeGooBIFRoZSBEb2Nr
ZXIgaW1hZ2UgZm9yIHRoZSBjb250YWluZXIgdGhhdCBydW5zIHRoZSB2ZXJzaW9uLgogT25s
eSBhcHBsaWNhYmxlIGZvciBpbnN0YW5jZXMgcnVubmluZyBpbiB0aGUgQXBwIEVuZ2luZSBm
bGV4aWJsZSBlbnZpcm9ubWVudC4KCgwKBQQAAgEGEgMlAg8KDAoFBAACAQESAyUQGQoMCgUE
AAIBAxIDJRwdCk0KBAQAAgISAygCEhpAIFRoZSB6aXAgZmlsZSBmb3IgdGhpcyBkZXBsb3lt
ZW50LCBpZiB0aGlzIGlzIGEgemlwIGRlcGxveW1lbnQuCgoMCgUEAAICBhIDKAIJCgwKBQQA
AgIBEgMoCg0KDAoFBAACAgMSAygQEQrwAQoEBAACAxIDLwIsGuIBIE9wdGlvbnMgZm9yIGFu
eSBHb29nbGUgQ2xvdWQgQnVpbGQgYnVpbGRzIGNyZWF0ZWQgYXMgYSBwYXJ0IG9mIHRoaXMK
IGRlcGxveW1lbnQuCgogVGhlc2Ugb3B0aW9ucyB3aWxsIG9ubHkgYmUgdXNlZCBpZiBhIG5l
dyBidWlsZCBpcyBjcmVhdGVkLCBzdWNoIGFzIHdoZW4KIGRlcGxveWluZyB0byB0aGUgQXBw
IEVuZ2luZSBmbGV4aWJsZSBlbnZpcm9ubWVudCB1c2luZyBmaWxlcyBvciB6aXAuCgoMCgUE
AAIDBhIDLwITCgwKBQQAAgMBEgMvFCcKDAoFBAACAwMSAy8qKwqOAQoCBAESBDQAQQEagQEg
U2luZ2xlIHNvdXJjZSBmaWxlIHRoYXQgaXMgcGFydCBvZiB0aGUgdmVyc2lvbiB0byBiZSBk
ZXBsb3llZC4gRWFjaCBzb3VyY2UKIGZpbGUgdGhhdCBpcyBkZXBsb3llZCBtdXN0IGJlIHNw
ZWNpZmllZCBzZXBhcmF0ZWx5LgoKCgoDBAEBEgM0CBAKsQEKBAQBAgASAzgCGBqjASBVUkwg
c291cmNlIHRvIHVzZSB0byBmZXRjaCB0aGlzIGZpbGUuIE11c3QgYmUgYSBVUkwgdG8gYSBy
ZXNvdXJjZSBpbgogR29vZ2xlIENsb3VkIFN0b3JhZ2UgaW4gdGhlIGZvcm0KICdodHRwKHMp
Oi8vc3RvcmFnZS5nb29nbGVhcGlzLmNvbS9cPGJ1Y2tldFw+L1w8b2JqZWN0XD4nLgoKDAoF
BAECAAUSAzgCCAoMCgUEAQIAARIDOAkTCgwKBQQBAgADEgM4FhcKMQoEBAECARIDOwIWGiQg
VGhlIFNIQTEgaGFzaCBvZiB0aGUgZmlsZSwgaW4gaGV4LgoKDAoFBAECAQUSAzsCCAoMCgUE
AQIBARIDOwkRCgwKBQQBAgEDEgM7FBUKXAoEBAECAhIDQAIXGk8gVGhlIE1JTUUgdHlwZSBv
ZiB0aGUgZmlsZS4KCiBEZWZhdWx0cyB0byB0aGUgdmFsdWUgZnJvbSBHb29nbGUgQ2xvdWQg
U3RvcmFnZS4KCgwKBQQBAgIFEgNAAggKDAoFBAECAgESA0AJEgoMCgUEAQICAxIDQBUWCscB
CgIEAhIERgBLARq6ASBEb2NrZXIgaW1hZ2UgdGhhdCBpcyB1c2VkIHRvIGNyZWF0ZSBhIGNv
bnRhaW5lciBhbmQgc3RhcnQgYSBWTSBpbnN0YW5jZSBmb3IKIHRoZSB2ZXJzaW9uIHRoYXQg
eW91IGRlcGxveS4gT25seSBhcHBsaWNhYmxlIGZvciBpbnN0YW5jZXMgcnVubmluZyBpbiB0
aGUgQXBwCiBFbmdpbmUgZmxleGlibGUgZW52aXJvbm1lbnQuCgoKCgMEAgESA0YIFQraAQoE
BAICABIDSgITGswBIFVSSSB0byB0aGUgaG9zdGVkIGNvbnRhaW5lciBpbWFnZSBpbiBHb29n
bGUgQ29udGFpbmVyIFJlZ2lzdHJ5LiBUaGUgVVJJCiBtdXN0IGJlIGZ1bGx5IHF1YWxpZmll
ZCBhbmQgaW5jbHVkZSBhIHRhZyBvciBkaWdlc3QuCiBFeGFtcGxlczogImdjci5pby9teS1w
cm9qZWN0L2ltYWdlOnRhZyIgb3IgImdjci5pby9teS1wcm9qZWN0L2ltYWdlQGRpZ2VzdCIK
CgwKBQQCAgAFEgNKAggKDAoFBAICAAESA0oJDgoMCgUEAgIAAxIDShESCsgBCgIEAxIEUABd
ARq7ASBPcHRpb25zIGZvciB0aGUgYnVpbGQgb3BlcmF0aW9ucyBwZXJmb3JtZWQgYXMgYSBw
YXJ0IG9mIHRoZSB2ZXJzaW9uCiBkZXBsb3ltZW50LiBPbmx5IGFwcGxpY2FibGUgZm9yIEFw
cCBFbmdpbmUgZmxleGlibGUgZW52aXJvbm1lbnQgd2hlbiBjcmVhdGluZwogYSB2ZXJzaW9u
IHVzaW5nIHNvdXJjZSBjb2RlIGRpcmVjdGx5LgoKCgoDBAMBEgNQCBkK9gEKBAQDAgASA1gC
GxroASBQYXRoIHRvIHRoZSB5YW1sIGZpbGUgdXNlZCBpbiBkZXBsb3ltZW50LCB1c2VkIHRv
IGRldGVybWluZSBydW50aW1lCiBjb25maWd1cmF0aW9uIGRldGFpbHMuCgogUmVxdWlyZWQg
Zm9yIGZsZXhpYmxlIGVudmlyb25tZW50IGJ1aWxkcy4KCiBTZWUgaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi9jb25maWcvYXBwcmVm
CiBmb3IgbW9yZSBkZXRhaWxzLgoKDAoFBAMCAAUSA1gCCAoMCgUEAwIAARIDWAkWCgwKBQQD
AgADEgNYGRoKgwEKBAQDAgESA1wCMxp2IFRoZSBDbG91ZCBCdWlsZCB0aW1lb3V0IHVzZWQg
YXMgcGFydCBvZiBhbnkgZGVwZW5kZW50IGJ1aWxkcyBwZXJmb3JtZWQgYnkKIHZlcnNpb24g
Y3JlYXRpb24uIERlZmF1bHRzIHRvIDEwIG1pbnV0ZXMuCgoMCgUEAwIBBhIDXAIaCgwKBQQD
AgEBEgNcGy4KDAoFBAMCAQMSA1wxMgo8CgIEBBIEYABqARowIFRoZSB6aXAgZmlsZSBpbmZv
cm1hdGlvbiBmb3IgYSB6aXAgZGVwbG95bWVudC4KCgoKAwQEARIDYAgPCq8BCgQEBAIAEgNk
AhgaoQEgVVJMIG9mIHRoZSB6aXAgZmlsZSB0byBkZXBsb3kgZnJvbS4gTXVzdCBiZSBhIFVS
TCB0byBhIHJlc291cmNlIGluCiBHb29nbGUgQ2xvdWQgU3RvcmFnZSBpbiB0aGUgZm9ybQog
J2h0dHAocyk6Ly9zdG9yYWdlLmdvb2dsZWFwaXMuY29tL1w8YnVja2V0XD4vXDxvYmplY3Rc
PicuCgoMCgUEBAIABRIDZAIICgwKBQQEAgABEgNkCRMKDAoFBAQCAAMSA2QWFwriAQoEBAQC
ARIDaQIYGtQBIEFuIGVzdGltYXRlIG9mIHRoZSBudW1iZXIgb2YgZmlsZXMgaW4gYSB6aXAg
Zm9yIGEgemlwIGRlcGxveW1lbnQuCiBJZiBzZXQsIG11c3QgYmUgZ3JlYXRlciB0aGFuIG9y
IGVxdWFsIHRvIHRoZSBhY3R1YWwgbnVtYmVyIG9mIGZpbGVzLgogVXNlZCBmb3Igb3B0aW1p
emluZyBwZXJmb3JtYW5jZTsgaWYgbm90IHByb3ZpZGVkLCBkZXBsb3ltZW50IG1heSBiZSBz
bG93LgoKDAoFBAQCAQUSA2kCBwoMCgUEBAIBARIDaQgTCgwKBQQEAgEDEgNpFhdiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Deploy::Deployment ===
    # Fields for Deployment
    # Field: files Type: 11 (.google.appengine.v1.Deployment.FilesEntry)
    # Field: container Type: 11 (.google.appengine.v1.ContainerInfo)
    # Field: zip Type: 11 (.google.appengine.v1.ZipInfo)
    # Field: cloud_build_options Type: 11 (.google.appengine.v1.CloudBuildOptions)

# === Message: Google::Appengine::V1::Deploy::FileInfo ===
    # Fields for FileInfo
    # Field: source_url Type: 9 ()
    # Field: sha1_sum Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Appengine::V1::Deploy::ContainerInfo ===
    # Fields for ContainerInfo
    # Field: image Type: 9 ()

# === Message: Google::Appengine::V1::Deploy::CloudBuildOptions ===
    # Fields for CloudBuildOptions
    # Field: app_yaml_path Type: 9 ()
    # Field: cloud_build_timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Appengine::V1::Deploy::ZipInfo ===
    # Fields for ZipInfo
    # Field: source_url Type: 9 ()
    # Field: files_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Deploy - Compiled Protocol Buffers messages for google/appengine/v1/deploy.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Deploy;

    my $msg = Google::Appengine::V1::Deploy::Deployment->new({
        files => $files,
        container => $container,
        zip => $zip,
        cloud_build_options => $cloud_build_options,
    });

    # Read or update a field
    my $val = $msg->files();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Deploy::Deployment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/deploy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Deploy::Deployment

Code and application artifacts used to deploy a version to App Engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Appengine::V1::Deploy::Deployment::FilesEntry>)

Manifest of the files stored in Google Cloud Storage that are included
as part of this version. All files must be readable using the
credentials supplied with this call.

=item * C<< $msg->container() >> / C<< $msg->container($value) >>

Type: C<Message> (L<Google::Appengine::V1::Deploy::ContainerInfo>)

The Docker image for the container that runs the version.
Only applicable for instances running in the App Engine flexible environment.

=item * C<< $msg->zip() >> / C<< $msg->zip($value) >>

Type: C<Message> (L<Google::Appengine::V1::Deploy::ZipInfo>)

The zip file for this deployment, if this is a zip deployment.

=item * C<< $msg->cloud_build_options() >> / C<< $msg->cloud_build_options($value) >>

Type: C<Message> (L<Google::Appengine::V1::Deploy::CloudBuildOptions>)

Options for any Google Cloud Build builds created as a part of this
deployment.

These options will only be used if a new build is created, such as when
deploying to the App Engine flexible environment using files or zip.

=back

=head2 Google::Appengine::V1::Deploy::FileInfo

Single source file that is part of the version to be deployed. Each source
file that is deployed must be specified separately.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_url() >> / C<< $msg->source_url($value) >>

Type: C<String>

URL source to use to fetch this file. Must be a URL to a resource in
Google Cloud Storage in the form
'http(s)://storage.googleapis.com/\<bucket\>/\<object\>'.

=item * C<< $msg->sha1_sum() >> / C<< $msg->sha1_sum($value) >>

Type: C<String>

The SHA1 hash of the file, in hex.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

The MIME type of the file.

Defaults to the value from Google Cloud Storage.

=back

=head2 Google::Appengine::V1::Deploy::ContainerInfo

Docker image that is used to create a container and start a VM instance for
the version that you deploy. Only applicable for instances running in the App
Engine flexible environment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<String>

URI to the hosted container image in Google Container Registry. The URI
must be fully qualified and include a tag or digest.
Examples: "gcr.io/my-project/image:tag" or "gcr.io/my-project/image@digest"

=back

=head2 Google::Appengine::V1::Deploy::CloudBuildOptions

Options for the build operations performed as a part of the version
deployment. Only applicable for App Engine flexible environment when creating
a version using source code directly.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app_yaml_path() >> / C<< $msg->app_yaml_path($value) >>

Type: C<String>

Path to the yaml file used in deployment, used to determine runtime
configuration details.

Required for flexible environment builds.

See https://cloud.google.com/appengine/docs/standard/python/config/appref
for more details.

=item * C<< $msg->cloud_build_timeout() >> / C<< $msg->cloud_build_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The Cloud Build timeout used as part of any dependent builds performed by
version creation. Defaults to 10 minutes.

=back

=head2 Google::Appengine::V1::Deploy::ZipInfo

The zip file information for a zip deployment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_url() >> / C<< $msg->source_url($value) >>

Type: C<String>

URL of the zip file to deploy from. Must be a URL to a resource in
Google Cloud Storage in the form
'http(s)://storage.googleapis.com/\<bucket\>/\<object\>'.

=item * C<< $msg->files_count() >> / C<< $msg->files_count($value) >>

Type: C<Int32>

An estimate of the number of files in a zip for a zip deployment.
If set, must be greater than or equal to the actual number of files.
Used for optimizing performance; if not provided, deployment may be slow.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Deploy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
