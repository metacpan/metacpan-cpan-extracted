package Google::Cloud::Securitycenter::V2::Network;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvbmV0d29yay5wcm90bxIeZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyIh0KB05ldHdvcmsSEgoEbmFtZRgBIAEoCVIEbmFt
ZULmAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkIMTmV0d29ya1Byb3Rv
UAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHlj
ZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVy
LlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6
U2VjdXJpdHlDZW50ZXI6OlYySoAICgYSBA4AHwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBhCgkK
AggLEgMTAGEKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAtCgkKAggIEgMVAC0KCAoB
CBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkKAggt
EgMYADoKUwoCBAASBBsAHwEaRyBDb250YWlucyBpbmZvcm1hdGlvbiBhYm91dCBhIFZQQyBu
ZXR3b3JrIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmluZGluZy4KCgoKAwQAARIDGwgPCo4BCgQE
AAIAEgMeAhIagAEgVGhlIG5hbWUgb2YgdGhlIFZQQyBuZXR3b3JrIHJlc291cmNlLCBmb3Ig
ZXhhbXBsZSwKIGAvL2NvbXB1dGUuZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMvbXktcHJvamVj
dC9nbG9iYWwvbmV0d29ya3MvbXktbmV0d29ya2AuCgoMCgUEAAIABRIDHgIICgwKBQQAAgAB
EgMeCQ0KDAoFBAACAAMSAx4QEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Network::Network ===
    # Fields for Network
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Network - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/network.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Network;

    my $msg = Google::Cloud::Securitycenter::V2::Network::Network->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Network::Network->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/network.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Network::Network

Contains information about a VPC network associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the VPC network resource, for example,
`//compute.googleapis.com/projects/my-project/global/networks/my-network`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Network::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
