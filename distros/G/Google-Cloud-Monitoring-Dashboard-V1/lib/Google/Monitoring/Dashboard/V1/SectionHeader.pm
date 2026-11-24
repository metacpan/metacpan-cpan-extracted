package Google::Monitoring::Dashboard::V1::SectionHeader;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvc2VjdGlvbl9oZWFkZXIucHJvdG8S
Hmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MSJQCg1TZWN0aW9uSGVhZGVyEhoKCHN1
YnRpdGxlGAEgASgJUghzdWJ0aXRsZRIjCg1kaXZpZGVyX2JlbG93GAIgASgIUgxkaXZpZGVy
QmVsb3dC+wEKImNvbS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjFCElNlY3Rpb25I
ZWFkZXJQcm90b1ABWkZjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvZGFzaGJvYXJk
L2FwaXYxL2Rhc2hib2FyZHBiO2Rhc2hib2FyZHBiqgIkR29vZ2xlLkNsb3VkLk1vbml0b3Jp
bmcuRGFzaGJvYXJkLlYxygIkR29vZ2xlXENsb3VkXE1vbml0b3JpbmdcRGFzaGJvYXJkXFYx
6gIoR29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6RGFzaGJvYXJkOjpWMUrdCAoGEgQOACIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCggKAQgSAxIA
QQoJCgIIJRIDEgBBCggKAQgSAxMAXQoJCgIICxIDEwBdCggKAQgSAxQAIgoJCgIIChIDFAAi
CggKAQgSAxUAMwoJCgIICBIDFQAzCggKAQgSAxYAOwoJCgIIARIDFgA7CggKAQgSAxcAQgoJ
CgIIKRIDFwBCCggKAQgSAxgAQQoJCgIILRIDGABBCpMBCgIEABIEHAAiARqGASBBIHdpZGdl
dCB0aGF0IGRlZmluZXMgYSBuZXcgc2VjdGlvbiBoZWFkZXIuIFNlY3Rpb25zIHBvcHVsYXRl
IGEgdGFibGUgb2YKIGNvbnRlbnRzIGFuZCBhbGxvdyBlYXNpZXIgbmF2aWdhdGlvbiBvZiBs
b25nLWZvcm0gY29udGVudC4KCgoKAwQAARIDHAgVCioKBAQAAgASAx4CFhodIFRoZSBzdWJ0
aXRsZSBvZiB0aGUgc2VjdGlvbgoKDAoFBAACAAUSAx4CCAoMCgUEAAIAARIDHgkRCgwKBQQA
AgADEgMeFBUKVQoEBAACARIDIQIZGkggV2hldGhlciB0byBpbnNlcnQgYSBkaXZpZGVyIGJl
bG93IHRoZSBzZWN0aW9uIGluIHRoZSB0YWJsZSBvZiBjb250ZW50cwoKDAoFBAACAQUSAyEC
BgoMCgUEAAIBARIDIQcUCgwKBQQAAgEDEgMhFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader ===
    # Fields for SectionHeader
    # Field: subtitle Type: 9 ()
    # Field: divider_below Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::SectionHeader - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/section_header.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::SectionHeader;

    my $msg = Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader->new({
        subtitle => $subtitle,
        divider_below => $divider_below,
    });

    # Read or update a field
    my $val = $msg->subtitle();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/section_header.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader

A widget that defines a new section header. Sections populate a table of
contents and allow easier navigation of long-form content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

The subtitle of the section

=item * C<< $msg->divider_below() >> / C<< $msg->divider_below($value) >>

Type: C<Bool>

Whether to insert a divider below the section in the table of contents

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::SectionHeader::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
