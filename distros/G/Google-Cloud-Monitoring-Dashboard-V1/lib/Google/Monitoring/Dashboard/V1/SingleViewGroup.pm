package Google::Monitoring::Dashboard::V1::SingleViewGroup;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvc2luZ2xlX3ZpZXdfZ3JvdXAucHJv
dG8SHmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MSIRCg9TaW5nbGVWaWV3R3JvdXBC
/QEKImNvbS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjFCFFNpbmdsZVZpZXdHcm91
cFByb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9kYXNoYm9hcmQvYXBp
djEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5E
YXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xEYXNoYm9hcmRcVjHqAihH
b29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpEYXNoYm9hcmQ6OlYxSqYHCgYSBA4AHRoKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgBBCgkK
AgglEgMSAEEKCAoBCBIDEwBdCgkKAggLEgMTAF0KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoB
CBIDFQA1CgkKAggIEgMVADUKCAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwBCCgkKAggp
EgMXAEIKCAoBCBIDGABBCgkKAggtEgMYAEEKswEKAgQAEgMdABoapwEgQSB3aWRnZXQgdGhh
dCBncm91cHMgdGhlIG90aGVyIHdpZGdldHMgYnkgdXNpbmcgYSBkcm9wZG93biBtZW51LiBB
bGwgd2lkZ2V0cwogdGhhdCBhcmUgd2l0aGluIHRoZSBhcmVhIHNwYW5uZWQgYnkgdGhlIGdy
b3VwaW5nIHdpZGdldCBhcmUgY29uc2lkZXJlZAogbWVtYmVyIHdpZGdldHMuCgoKCgMEAAES
Ax0IF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup ===
    # Fields for SingleViewGroup

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::SingleViewGroup - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/single_view_group.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::SingleViewGroup;

    my $msg = Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/single_view_group.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup

A widget that groups the other widgets by using a dropdown menu. All widgets
that are within the area spanned by the grouping widget are considered
member widgets.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::SingleViewGroup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
