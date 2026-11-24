package Google::Cloud::Securitycenter::V2::Disk;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZGlzay5wcm90bxIeZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYyIhoKBERpc2sSEgoEbmFtZRgBIAEoCVIEbmFtZULjAQoi
Y29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkIJRGlza1Byb3RvUAFaSmNsb3Vk
Lmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtz
ZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29v
Z2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlD
ZW50ZXI6OlYySv8HCgYSBA4AHwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBhCgkKAggLEgMTAGEK
CAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAqCgkKAggIEgMVACoKCAoBCBIDFgA7CgkK
AggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkKAggtEgMYADoKTgoC
BAASBBsAHwEaQiBDb250YWlucyBpbmZvcm1hdGlvbiBhYm91dCB0aGUgZGlzayBhc3NvY2lh
dGVkIHdpdGggdGhlIGZpbmRpbmcuCgoKCgMEAAESAxsIDAqSAQoEBAACABIDHgISGoQBIFRo
ZSBuYW1lIG9mIHRoZSBkaXNrLCBmb3IgZXhhbXBsZSwKICJodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9jb21wdXRlL3YxL3Byb2plY3RzL3twcm9qZWN0LWlkfS96b25lcy97em9uZS1p
ZH0vZGlza3Mve2Rpc2staWR9Ii4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JDQoMCgUE
AAIAAxIDHhARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Disk::Disk ===
    # Fields for Disk
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Disk - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/disk.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Disk;

    my $msg = Google::Cloud::Securitycenter::V2::Disk::Disk->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Disk::Disk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/disk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Disk::Disk

Contains information about the disk associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the disk, for example,
"https://www.googleapis.com/compute/v1/projects/{project-id}/zones/{zone-id}/disks/{disk-id}".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Disk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
