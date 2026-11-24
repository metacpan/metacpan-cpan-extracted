package Google::Cloud::Batch::V1alpha::Volume;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvYmF0Y2gvdjFhbHBoYS92b2x1bWUucHJvdG8SGmdvb2dsZS5jbG91
ZC5iYXRjaC52MWFscGhhIpkCCgZWb2x1bWUSMwoDbmZzGAEgASgLMh8uZ29vZ2xlLmNsb3Vk
LmJhdGNoLnYxYWxwaGEuTkZTSABSA25mcxI0CgJwZBgCIAEoCzIeLmdvb2dsZS5jbG91ZC5i
YXRjaC52MWFscGhhLlBEQgIYAUgAUgJwZBIzCgNnY3MYAyABKAsyHy5nb29nbGUuY2xvdWQu
YmF0Y2gudjFhbHBoYS5HQ1NIAFIDZ2NzEiEKC2RldmljZV9uYW1lGAYgASgJSABSCmRldmlj
ZU5hbWUSHQoKbW91bnRfcGF0aBgEIAEoCVIJbW91bnRQYXRoEiMKDW1vdW50X29wdGlvbnMY
BSADKAlSDG1vdW50T3B0aW9uc0IICgZzb3VyY2UiPgoDTkZTEhYKBnNlcnZlchgBIAEoCVIG
c2VydmVyEh8KC3JlbW90ZV9wYXRoGAIgASgJUgpyZW1vdGVQYXRoIlAKAlBEEhIKBGRpc2sY
ASABKAlSBGRpc2sSFgoGZGV2aWNlGAIgASgJUgZkZXZpY2USHgoIZXhpc3RpbmcYAyABKAhC
AhgBUghleGlzdGluZyImCgNHQ1MSHwoLcmVtb3RlX3BhdGgYASABKAlSCnJlbW90ZVBhdGhC
xQEKHmNvbS5nb29nbGUuY2xvdWQuYmF0Y2gudjFhbHBoYUILVm9sdW1lUHJvdG9QAVo0Y2xv
dWQuZ29vZ2xlLmNvbS9nby9iYXRjaC9hcGl2MWFscGhhL2JhdGNocGI7YmF0Y2hwYqICA0dD
QqoCGkdvb2dsZS5DbG91ZC5CYXRjaC5WMUFscGhhygIaR29vZ2xlXENsb3VkXEJhdGNoXFYx
YWxwaGHqAh1Hb29nbGU6OkNsb3VkOjpCYXRjaDo6VjFhbHBoYUqgGwoGEgQOAGEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCggKAQgSAxIANwoJCgII
JRIDEgA3CggKAQgSAxMASwoJCgIICxIDEwBLCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgS
AxUALAoJCgIICBIDFQAsCggKAQgSAxYANwoJCgIIARIDFgA3CggKAQgSAxcAIQoJCgIIJBID
FwAhCggKAQgSAxgANwoJCgIIKRIDGAA3CggKAQgSAxkANgoJCgIILRIDGQA2ClQKAgQAEgQc
AEIBGkggVm9sdW1lIGRlc2NyaWJlcyBhIHZvbHVtZSBhbmQgcGFyYW1ldGVycyBmb3IgaXQg
dG8gYmUgbW91bnRlZCB0byBhIFZNLgoKCgoDBAABEgMcCA4KKgoEBAAIABIEHgIvAxocIFRo
ZSBzb3VyY2UgZm9yIHRoZSB2b2x1bWUuCgoMCgUEAAgAARIDHggOClgKBAQAAgASAyEEEBpL
IEEgTmV0d29yayBGaWxlIFN5c3RlbSAoTkZTKSB2b2x1bWUuIEZvciBleGFtcGxlLCBhCiBG
aWxlc3RvcmUgZmlsZSBzaGFyZS4KCgwKBQQAAgAGEgMhBAcKDAoFBAACAAESAyEICwoMCgUE
AAIAAxIDIQ4PCjoKBAQAAgESAyQEIhotIERlcHJlY2F0ZWQ6IHBsZWFzZSB1c2UgZGV2aWNl
X25hbWUgaW5zdGVhZC4KCgwKBQQAAgEGEgMkBAYKDAoFBAACAQESAyQHCQoMCgUEAAIBAxID
JAwNCgwKBQQAAgEIEgMkDiEKDQoGBAACAQgDEgMkDyAKMwoEBAACAhIDJwQQGiYgQSBHb29n
bGUgQ2xvdWQgU3RvcmFnZSAoR0NTKSB2b2x1bWUuCgoMCgUEAAICBhIDJwQHCgwKBQQAAgIB
EgMnCAsKDAoFBAACAgMSAycODwqQAgoEBAACAxIDLgQbGoICIERldmljZSBuYW1lIG9mIGFu
IGF0dGFjaGVkIGRpc2sgdm9sdW1lLCB3aGljaCBzaG91bGQgYWxpZ24gd2l0aCBhCiBkZXZp
Y2VfbmFtZSBzcGVjaWZpZWQgYnkKIGpvYi5hbGxvY2F0aW9uX3BvbGljeS5pbnN0YW5jZXNb
MF0ucG9saWN5LmRpc2tzW2ldLmRldmljZV9uYW1lIG9yCiBkZWZpbmVkIGJ5IHRoZSBnaXZl
biBpbnN0YW5jZSB0ZW1wbGF0ZSBpbgogam9iLmFsbG9jYXRpb25fcG9saWN5Lmluc3RhbmNl
c1swXS5pbnN0YW5jZV90ZW1wbGF0ZS4KCgwKBQQAAgMFEgMuBAoKDAoFBAACAwESAy4LFgoM
CgUEAAIDAxIDLhkaCkQKBAQAAgQSAzICGBo3IFRoZSBtb3VudCBwYXRoIGZvciB0aGUgdm9s
dW1lLCBlLmcuIC9tbnQvZGlza3Mvc2hhcmUuCgoMCgUEAAIEBRIDMgIICgwKBQQAAgQBEgMy
CRMKDAoFBAACBAMSAzIWFwqWBQoEBAACBRIDQQIkGogFIE1vdW50IG9wdGlvbnMgdmFyeSBi
YXNlZCBvbiB0aGUgdHlwZSBvZiBzdG9yYWdlIHZvbHVtZToKCiAqIEZvciBhIENsb3VkIFN0
b3JhZ2UgYnVja2V0LCBhbGwgdGhlIG1vdW50IG9wdGlvbnMgcHJvdmlkZWQKIGJ5CiAgIHRo
ZSBbYGdjc2Z1c2VgIHRvb2xdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zdG9yYWdlL2Rv
Y3MvZ2NzZnVzZS1jbGkpCiAgIGFyZSBzdXBwb3J0ZWQuCiAqIEZvciBhbiBleGlzdGluZyBw
ZXJzaXN0ZW50IGRpc2ssIGFsbCBtb3VudCBvcHRpb25zIHByb3ZpZGVkIGJ5IHRoZQogICBb
YG1vdW50YCBjb21tYW5kXShodHRwczovL21hbjcub3JnL2xpbnV4L21hbi1wYWdlcy9tYW44
L21vdW50LjguaHRtbCkKICAgZXhjZXB0IHdyaXRpbmcgYXJlIHN1cHBvcnRlZC4gVGhpcyBp
cyBkdWUgdG8gcmVzdHJpY3Rpb25zIG9mCiAgIFttdWx0aS13cml0ZXIKICAgbW9kZV0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9kaXNrcy9zaGFyaW5nLWRpc2tz
LWJldHdlZW4tdm1zKS4KICogRm9yIGFueSBvdGhlciBkaXNrIG9yIGEgTmV0d29yayBGaWxl
IFN5c3RlbSAoTkZTKSwgYWxsIHRoZQogICBtb3VudCBvcHRpb25zIHByb3ZpZGVkIGJ5IHRo
ZSBgbW91bnRgIGNvbW1hbmQgYXJlIHN1cHBvcnRlZC4KCgwKBQQAAgUEEgNBAgoKDAoFBAAC
BQUSA0ELEQoMCgUEAAIFARIDQRIfCgwKBQQAAgUDEgNBIiMKJwoCBAESBEUASwEaGyBSZXBy
ZXNlbnRzIGFuIE5GUyB2b2x1bWUuCgoKCgMEAQESA0UICwopCgQEAQIAEgNHAhQaHCBUaGUg
SVAgYWRkcmVzcyBvZiB0aGUgTkZTLgoKDAoFBAECAAUSA0cCCAoMCgUEAQIAARIDRwkPCgwK
BQQBAgADEgNHEhMKSAoEBAECARIDSgIZGjsgUmVtb3RlIHNvdXJjZSBwYXRoIGV4cG9ydGVk
IGZyb20gdGhlIE5GUywgZS5nLiwgIi9zaGFyZSIuCgoMCgUEAQIBBRIDSgIICgwKBQQBAgEB
EgNKCRQKDAoFBAECAQMSA0oXGAo5CgIEAhIETgBaARotIERlcHJlY2F0ZWQ6IHBsZWFzZSB1
c2UgZGV2aWNlX25hbWUgaW5zdGVhZC4KCgoKAwQCARIDTggKCicKBAQCAgASA1ACEhoaIFBE
IGRpc2sgbmFtZSwgZS5nLiBwZC0xLgoKDAoFBAICAAUSA1ACCAoMCgUEAgIAARIDUAkNCgwK
BQQCAgADEgNQEBEKNgoEBAICARIDUwIUGikgUEQgZGV2aWNlIG5hbWUsIGUuZy4gcGVyc2lz
dGVudC1kaXNrLTEuCgoMCgUEAgIBBRIDUwIICgwKBQQCAgEBEgNTCQ8KDAoFBAICAQMSA1MS
Ewr1AQoEBAICAhIDWQIoGucBIFdoZXRoZXIgdGhpcyBpcyBhbiBleGlzdGluZyBQRC4gRGVm
YXVsdCBpcyBmYWxzZS4gSWYgZmFsc2UsIGkuZS4sIG5ldwogUEQsIHdlIHdpbGwgZm9ybWF0
IGl0IGludG8gZXh0NCBhbmQgbW91bnQgdG8gdGhlIGdpdmVuIHBhdGguIElmIHRydWUsIGku
ZS4sCiBleGlzdGluZyBQRCwgaXQgc2hvdWxkIGJlIGluIGV4dDQgZm9ybWF0IGFuZCB3ZSB3
aWxsIG1vdW50IGl0IHRvIHRoZSBnaXZlbgogcGF0aC4KCgwKBQQCAgIFEgNZAgYKDAoFBAIC
AgESA1kHDwoMCgUEAgICAxIDWRITCgwKBQQCAgIIEgNZFCcKDQoGBAICAggDEgNZFSYKNwoC
BAMSBF0AYQEaKyBSZXByZXNlbnRzIGEgR29vZ2xlIENsb3VkIFN0b3JhZ2Ugdm9sdW1lLgoK
CgoDBAMBEgNdCAsKfQoEBAMCABIDYAIZGnAgUmVtb3RlIHBhdGgsIGVpdGhlciBhIGJ1Y2tl
dCBuYW1lIG9yIGEgc3ViZGlyZWN0b3J5IG9mIGEgYnVja2V0LCBlLmcuOgogYnVja2V0X25h
bWUsIGJ1Y2tldF9uYW1lL3N1YmRpcmVjdG9yeS8KCgwKBQQDAgAFEgNgAggKDAoFBAMCAAES
A2AJFAoMCgUEAwIAAxIDYBcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Batch::V1alpha::Volume::Volume ===
    # Fields for Volume
    # Field: nfs Type: 11 (.google.cloud.batch.v1alpha.NFS)
    # Field: pd Type: 11 (.google.cloud.batch.v1alpha.PD)
    # Field: gcs Type: 11 (.google.cloud.batch.v1alpha.GCS)
    # Field: device_name Type: 9 ()
    # Field: mount_path Type: 9 ()
    # Field: mount_options Type: 9 ()

# === Message: Google::Cloud::Batch::V1alpha::Volume::NFS ===
    # Fields for NFS
    # Field: server Type: 9 ()
    # Field: remote_path Type: 9 ()

# === Message: Google::Cloud::Batch::V1alpha::Volume::PD ===
    # Fields for PD
    # Field: disk Type: 9 ()
    # Field: device Type: 9 ()
    # Field: existing Type: 8 ()

# === Message: Google::Cloud::Batch::V1alpha::Volume::GCS ===
    # Fields for GCS
    # Field: remote_path Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Batch::V1alpha::Volume - Compiled Protocol Buffers messages for google/cloud/batch/v1alpha/volume.proto

=head1 SYNOPSIS

    use Google::Cloud::Batch::V1alpha::Volume;

    my $msg = Google::Cloud::Batch::V1alpha::Volume::Volume->new({
        nfs => $nfs,
        pd => $pd,
        gcs => $gcs,
        device_name => $device_name,
    });

    # Read or update a field
    my $val = $msg->nfs();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Batch::V1alpha::Volume::Volume->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/batch/v1alpha/volume.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Batch::V1alpha::Volume::Volume

Volume describes a volume and parameters for it to be mounted to a VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nfs() >> / C<< $msg->nfs($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::Volume::NFS>)

A Network File System (NFS) volume. For example, a
Filestore file share.

=item * C<< $msg->pd() >> / C<< $msg->pd($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::Volume::PD>)

Deprecated: please use device_name instead.

=item * C<< $msg->gcs() >> / C<< $msg->gcs($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::Volume::GCS>)

A Google Cloud Storage (GCS) volume.

=item * C<< $msg->device_name() >> / C<< $msg->device_name($value) >>

Type: C<String>

Device name of an attached disk volume, which should align with a
device_name specified by
job.allocation_policy.instances[0].policy.disks[i].device_name or
defined by the given instance template in
job.allocation_policy.instances[0].instance_template.

=item * C<< $msg->mount_path() >> / C<< $msg->mount_path($value) >>

Type: C<String>

The mount path for the volume, e.g. /mnt/disks/share.

=item * C<< $msg->mount_options() >> / C<< $msg->mount_options($value) >>

Type: C<String>

Mount options vary based on the type of storage volume:

* For a Cloud Storage bucket, all the mount options provided
by
  the [`gcsfuse` tool](https://cloud.google.com/storage/docs/gcsfuse-cli)
  are supported.
* For an existing persistent disk, all mount options provided by the
  [`mount` command](https://man7.org/linux/man-pages/man8/mount.8.html)
  except writing are supported. This is due to restrictions of
  [multi-writer
  mode](https://cloud.google.com/compute/docs/disks/sharing-disks-between-vms).
* For any other disk or a Network File System (NFS), all the
  mount options provided by the `mount` command are supported.

=back

=head2 Google::Cloud::Batch::V1alpha::Volume::NFS

Represents an NFS volume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->server() >> / C<< $msg->server($value) >>

Type: C<String>

The IP address of the NFS.

=item * C<< $msg->remote_path() >> / C<< $msg->remote_path($value) >>

Type: C<String>

Remote source path exported from the NFS, e.g., "/share".

=back

=head2 Google::Cloud::Batch::V1alpha::Volume::PD

Deprecated: please use device_name instead.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disk() >> / C<< $msg->disk($value) >>

Type: C<String>

PD disk name, e.g. pd-1.

=item * C<< $msg->device() >> / C<< $msg->device($value) >>

Type: C<String>

PD device name, e.g. persistent-disk-1.

=item * C<< $msg->existing() >> / C<< $msg->existing($value) >>

Type: C<Bool>

Whether this is an existing PD. Default is false. If false, i.e., new
PD, we will format it into ext4 and mount to the given path. If true, i.e.,
existing PD, it should be in ext4 format and we will mount it to the given
path.

=back

=head2 Google::Cloud::Batch::V1alpha::Volume::GCS

Represents a Google Cloud Storage volume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->remote_path() >> / C<< $msg->remote_path($value) >>

Type: C<String>

Remote path, either a bucket name or a subdirectory of a bucket, e.g.:
bucket_name, bucket_name/subdirectory/

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Batch::V1alpha::Volume::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
