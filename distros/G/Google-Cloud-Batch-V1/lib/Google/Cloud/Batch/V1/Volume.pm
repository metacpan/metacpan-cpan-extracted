package Google::Cloud::Batch::V1::Volume;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvYmF0Y2gvdjEvdm9sdW1lLnByb3RvEhVnb29nbGUuY2xvdWQuYmF0
Y2gudjEi2QEKBlZvbHVtZRIuCgNuZnMYASABKAsyGi5nb29nbGUuY2xvdWQuYmF0Y2gudjEu
TkZTSABSA25mcxIuCgNnY3MYAyABKAsyGi5nb29nbGUuY2xvdWQuYmF0Y2gudjEuR0NTSABS
A2djcxIhCgtkZXZpY2VfbmFtZRgGIAEoCUgAUgpkZXZpY2VOYW1lEh0KCm1vdW50X3BhdGgY
BCABKAlSCW1vdW50UGF0aBIjCg1tb3VudF9vcHRpb25zGAUgAygJUgxtb3VudE9wdGlvbnNC
CAoGc291cmNlIj4KA05GUxIWCgZzZXJ2ZXIYASABKAlSBnNlcnZlchIfCgtyZW1vdGVfcGF0
aBgCIAEoCVIKcmVtb3RlUGF0aCImCgNHQ1MSHwoLcmVtb3RlX3BhdGgYASABKAlSCnJlbW90
ZVBhdGhCrAEKGWNvbS5nb29nbGUuY2xvdWQuYmF0Y2gudjFCC1ZvbHVtZVByb3RvUAFaL2Ns
b3VkLmdvb2dsZS5jb20vZ28vYmF0Y2gvYXBpdjEvYmF0Y2hwYjtiYXRjaHBiogIDR0NCqgIV
R29vZ2xlLkNsb3VkLkJhdGNoLlYxygIVR29vZ2xlXENsb3VkXEJhdGNoXFYx6gIYR29vZ2xl
OjpDbG91ZDo6QmF0Y2g6OlYxSuIVCgYSBA4ATwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQAB4KCAoBCBIDEgAyCgkKAgglEgMSADIKCAoBCBIDEwBGCgkK
AggLEgMTAEYKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAsCgkKAggIEgMVACwKCAoB
CBIDFgAyCgkKAggBEgMWADIKCAoBCBIDFwAhCgkKAggkEgMXACEKCAoBCBIDGAAyCgkKAggp
EgMYADIKCAoBCBIDGQAxCgkKAggtEgMZADEKVAoCBAASBBwAPwEaSCBWb2x1bWUgZGVzY3Jp
YmVzIGEgdm9sdW1lIGFuZCBwYXJhbWV0ZXJzIGZvciBpdCB0byBiZSBtb3VudGVkIHRvIGEg
Vk0uCgoKCgMEAAESAxwIDgoqCgQEAAgAEgQeAiwDGhwgVGhlIHNvdXJjZSBmb3IgdGhlIHZv
bHVtZS4KCgwKBQQACAABEgMeCA4KWAoEBAACABIDIQQQGksgQSBOZXR3b3JrIEZpbGUgU3lz
dGVtIChORlMpIHZvbHVtZS4gRm9yIGV4YW1wbGUsIGEKIEZpbGVzdG9yZSBmaWxlIHNoYXJl
LgoKDAoFBAACAAYSAyEEBwoMCgUEAAIAARIDIQgLCgwKBQQAAgADEgMhDg8KMwoEBAACARID
JAQQGiYgQSBHb29nbGUgQ2xvdWQgU3RvcmFnZSAoR0NTKSB2b2x1bWUuCgoMCgUEAAIBBhID
JAQHCgwKBQQAAgEBEgMkCAsKDAoFBAACAQMSAyQODwqQAgoEBAACAhIDKwQbGoICIERldmlj
ZSBuYW1lIG9mIGFuIGF0dGFjaGVkIGRpc2sgdm9sdW1lLCB3aGljaCBzaG91bGQgYWxpZ24g
d2l0aCBhCiBkZXZpY2VfbmFtZSBzcGVjaWZpZWQgYnkKIGpvYi5hbGxvY2F0aW9uX3BvbGlj
eS5pbnN0YW5jZXNbMF0ucG9saWN5LmRpc2tzW2ldLmRldmljZV9uYW1lIG9yCiBkZWZpbmVk
IGJ5IHRoZSBnaXZlbiBpbnN0YW5jZSB0ZW1wbGF0ZSBpbgogam9iLmFsbG9jYXRpb25fcG9s
aWN5Lmluc3RhbmNlc1swXS5pbnN0YW5jZV90ZW1wbGF0ZS4KCgwKBQQAAgIFEgMrBAoKDAoF
BAACAgESAysLFgoMCgUEAAICAxIDKxkaCkQKBAQAAgMSAy8CGBo3IFRoZSBtb3VudCBwYXRo
IGZvciB0aGUgdm9sdW1lLCBlLmcuIC9tbnQvZGlza3Mvc2hhcmUuCgoMCgUEAAIDBRIDLwII
CgwKBQQAAgMBEgMvCRMKDAoFBAACAwMSAy8WFwqWBQoEBAACBBIDPgIkGogFIE1vdW50IG9w
dGlvbnMgdmFyeSBiYXNlZCBvbiB0aGUgdHlwZSBvZiBzdG9yYWdlIHZvbHVtZToKCiAqIEZv
ciBhIENsb3VkIFN0b3JhZ2UgYnVja2V0LCBhbGwgdGhlIG1vdW50IG9wdGlvbnMgcHJvdmlk
ZWQKIGJ5CiAgIHRoZSBbYGdjc2Z1c2VgIHRvb2xdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9zdG9yYWdlL2RvY3MvZ2NzZnVzZS1jbGkpCiAgIGFyZSBzdXBwb3J0ZWQuCiAqIEZvciBh
biBleGlzdGluZyBwZXJzaXN0ZW50IGRpc2ssIGFsbCBtb3VudCBvcHRpb25zIHByb3ZpZGVk
IGJ5IHRoZQogICBbYG1vdW50YCBjb21tYW5kXShodHRwczovL21hbjcub3JnL2xpbnV4L21h
bi1wYWdlcy9tYW44L21vdW50LjguaHRtbCkKICAgZXhjZXB0IHdyaXRpbmcgYXJlIHN1cHBv
cnRlZC4gVGhpcyBpcyBkdWUgdG8gcmVzdHJpY3Rpb25zIG9mCiAgIFttdWx0aS13cml0ZXIK
ICAgbW9kZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9kaXNrcy9z
aGFyaW5nLWRpc2tzLWJldHdlZW4tdm1zKS4KICogRm9yIGFueSBvdGhlciBkaXNrIG9yIGEg
TmV0d29yayBGaWxlIFN5c3RlbSAoTkZTKSwgYWxsIHRoZQogICBtb3VudCBvcHRpb25zIHBy
b3ZpZGVkIGJ5IHRoZSBgbW91bnRgIGNvbW1hbmQgYXJlIHN1cHBvcnRlZC4KCgwKBQQAAgQE
EgM+AgoKDAoFBAACBAUSAz4LEQoMCgUEAAIEARIDPhIfCgwKBQQAAgQDEgM+IiMKJwoCBAES
BEIASAEaGyBSZXByZXNlbnRzIGFuIE5GUyB2b2x1bWUuCgoKCgMEAQESA0IICwopCgQEAQIA
EgNEAhQaHCBUaGUgSVAgYWRkcmVzcyBvZiB0aGUgTkZTLgoKDAoFBAECAAUSA0QCCAoMCgUE
AQIAARIDRAkPCgwKBQQBAgADEgNEEhMKSAoEBAECARIDRwIZGjsgUmVtb3RlIHNvdXJjZSBw
YXRoIGV4cG9ydGVkIGZyb20gdGhlIE5GUywgZS5nLiwgIi9zaGFyZSIuCgoMCgUEAQIBBRID
RwIICgwKBQQBAgEBEgNHCRQKDAoFBAECAQMSA0cXGAo3CgIEAhIESwBPARorIFJlcHJlc2Vu
dHMgYSBHb29nbGUgQ2xvdWQgU3RvcmFnZSB2b2x1bWUuCgoKCgMEAgESA0sICwp9CgQEAgIA
EgNOAhkacCBSZW1vdGUgcGF0aCwgZWl0aGVyIGEgYnVja2V0IG5hbWUgb3IgYSBzdWJkaXJl
Y3Rvcnkgb2YgYSBidWNrZXQsIGUuZy46CiBidWNrZXRfbmFtZSwgYnVja2V0X25hbWUvc3Vi
ZGlyZWN0b3J5LwoKDAoFBAICAAUSA04CCAoMCgUEAgIAARIDTgkUCgwKBQQCAgADEgNOFxhi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Batch::V1::Volume::Volume ===
    # Fields for Volume
    # Field: nfs Type: 11 (.google.cloud.batch.v1.NFS)
    # Field: gcs Type: 11 (.google.cloud.batch.v1.GCS)
    # Field: device_name Type: 9 ()
    # Field: mount_path Type: 9 ()
    # Field: mount_options Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Volume::NFS ===
    # Fields for NFS
    # Field: server Type: 9 ()
    # Field: remote_path Type: 9 ()

# === Message: Google::Cloud::Batch::V1::Volume::GCS ===
    # Fields for GCS
    # Field: remote_path Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Batch::V1::Volume - Compiled Protocol Buffers messages for google/cloud/batch/v1/volume.proto

=head1 SYNOPSIS

    use Google::Cloud::Batch::V1::Volume;

    my $msg = Google::Cloud::Batch::V1::Volume::Volume->new({
        nfs => $nfs,
        gcs => $gcs,
        device_name => $device_name,
        mount_path => $mount_path,
    });

    # Read or update a field
    my $val = $msg->nfs();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Batch::V1::Volume::Volume->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/batch/v1/volume.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Batch::V1::Volume::Volume

Volume describes a volume and parameters for it to be mounted to a VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->nfs() >> / C<< $msg->nfs($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1::Volume::NFS>)

A Network File System (NFS) volume. For example, a
Filestore file share.

=item * C<< $msg->gcs() >> / C<< $msg->gcs($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1::Volume::GCS>)

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

=head2 Google::Cloud::Batch::V1::Volume::NFS

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

=head2 Google::Cloud::Batch::V1::Volume::GCS

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Batch::V1::Volume::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
