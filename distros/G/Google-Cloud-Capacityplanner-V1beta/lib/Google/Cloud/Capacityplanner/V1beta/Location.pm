package Google::Cloud::Capacityplanner::V1beta::Location;

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
CjJnb29nbGUvY2xvdWQvY2FwYWNpdHlwbGFubmVyL3YxYmV0YS9sb2NhdGlvbi5wcm90bxIj
Z29vZ2xlLmNsb3VkLmNhcGFjaXR5cGxhbm5lci52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8iqQMKEkxvY2F0aW9uSWRlbnRpZmllchJZCg5sb2NhdGlvbl9sZXZl
bBgBIAEoDjIyLmdvb2dsZS5jbG91ZC5jYXBhY2l0eXBsYW5uZXIudjFiZXRhLkxvY2F0aW9u
TGV2ZWxSDWxvY2F0aW9uTGV2ZWwSGwoGc291cmNlGAIgASgJQgPgQQJSBnNvdXJjZRJ2ChBs
aW5rZWRfbG9jYXRpb25zGAMgAygLMkYuZ29vZ2xlLmNsb3VkLmNhcGFjaXR5cGxhbm5lci52
MWJldGEuTG9jYXRpb25JZGVudGlmaWVyLkxpbmtlZExvY2F0aW9uQgPgQQFSD2xpbmtlZExv
Y2F0aW9ucxqiAQoOTGlua2VkTG9jYXRpb24SWQoObG9jYXRpb25fbGV2ZWwYASABKA4yMi5n
b29nbGUuY2xvdWQuY2FwYWNpdHlwbGFubmVyLnYxYmV0YS5Mb2NhdGlvbkxldmVsUg1sb2Nh
dGlvbkxldmVsEh8KCGxvY2F0aW9uGAIgASgJQgPgQQJSCGxvY2F0aW9uEhQKBWxhYmVsGAMg
ASgJUgVsYWJlbCp/Cg1Mb2NhdGlvbkxldmVsEh4KGkxPQ0FUSU9OX0xFVkVMX1VOU1BFQ0lG
SUVEEAASCgoGUkVHSU9OEAESCAoEWk9ORRACEgoKBkdMT0JBTBADEgkKBU1FVFJPEAQSDwoL
RFVBTF9SRUdJT04QBRIQCgxNVUxUSV9SRUdJT04QBkKCAgonY29tLmdvb2dsZS5jbG91ZC5j
YXBhY2l0eXBsYW5uZXIudjFiZXRhQg1Mb2NhdGlvblByb3RvUAFaUWNsb3VkLmdvb2dsZS5j
b20vZ28vY2FwYWNpdHlwbGFubmVyL2FwaXYxYmV0YS9jYXBhY2l0eXBsYW5uZXJwYjtjYXBh
Y2l0eXBsYW5uZXJwYqoCI0dvb2dsZS5DbG91ZC5DYXBhY2l0eVBsYW5uZXIuVjFCZXRhygIj
R29vZ2xlXENsb3VkXENhcGFjaXR5UGxhbm5lclxWMWJldGHqAiZHb29nbGU6OkNsb3VkOjpD
YXBhY2l0eVBsYW5uZXI6OlYxYmV0YUqtEAoGEgQOAEoBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCAoBCBIDFABACgkKAgglEgMU
AEAKCAoBCBIDFQBoCgkKAggLEgMVAGgKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAu
CgkKAggIEgMXAC4KCAoBCBIDGABACgkKAggBEgMYAEAKCAoBCBIDGQBACgkKAggpEgMZAEAK
CAoBCBIDGgA/CgkKAggtEgMaAD8KPgoCBQASBB0AMgEaMiBUaGUgbGV2ZWwgb2YgdGhlIEdv
b2dsZSBDbG91ZCBQbGF0Zm9ybSBsb2NhdGlvbi4KCgoKAwUAARIDHQUSCi0KBAUAAgASAx8C
IRogIExvY2F0aW9uIGxldmVsIGlzIHVuc3BlY2lmaWVkLgoKDAoFBQACAAESAx8CHAoMCgUF
AAIAAhIDHx8gChwKBAUAAgESAyICDRoPIENsb3VkIHJlZ2lvbi4KCgwKBQUAAgEBEgMiAggK
DAoFBQACAQISAyILDAoaCgQFAAICEgMlAgsaDSBDbG91ZCB6b25lLgoKDAoFBQACAgESAyUC
BgoMCgUFAAICAhIDJQkKChgKBAUAAgMSAygCDRoLIEdsb2JhbGx5LgoKDAoFBQACAwESAygC
CAoMCgUFAAIDAhIDKAsMChcKBAUAAgQSAysCDBoKIEEgbWV0cm8uCgoMCgUFAAIEARIDKwIH
CgwKBQUAAgQCEgMrCgsKIAoEBQACBRIDLgISGhMgRHVhbCByZWdpb24gcGFpci4KCgwKBQUA
AgUBEgMuAg0KDAoFBQACBQISAy4QEQogCgQFAAIGEgMxAhMaEyBNdWx0aXBsZSByZWdpb25z
LgoKDAoFBQACBgESAzECDgoMCgUFAAIGAhIDMRESCj4KAgQAEgQ1AEoBGjIgSWRlbnRpZmll
ciBmb3IgYSBHb29nbGUgQ2xvdWQgUGxhdGZvcm0gbG9jYXRpb24uCgoKCgMEAAESAzUIGgoM
CgQEAAMAEgQ2Aj4DCgwKBQQAAwABEgM2ChgKNQoGBAADAAIAEgM4BCUaJiBUaGUgbG9jYXRp
b24gbGV2ZWwgc3VjaCBhcyBhIHJlZ2lvbi4KCg4KBwQAAwACAAYSAzgEEQoOCgcEAAMAAgAB
EgM4EiAKDgoHBAADAAIAAxIDOCMkCjUKBgQAAwACARIDOwRBGiYgUmVxdWlyZWQuIFRoZSBs
aW5rZWQgY2xvdWQgbG9jYXRpb24uCgoOCgcEAAMAAgEFEgM7BAoKDgoHBAADAAIBARIDOwsT
Cg4KBwQAAwACAQMSAzsWFwoOCgcEAAMAAgEIEgM7GEAKEQoKBAADAAIBCJwIABIDOxk/Cg0K
BgQAAwACAhIDPQQVCg4KBwQAAwACAgUSAz0ECgoOCgcEAAMAAgIBEgM9CxAKDgoHBAADAAIC
AxIDPRMUCjMKBAQAAgASA0ECIxomIFRoZSBsb2NhdGlvbiBsZXZlbCBzdWNoIGFzIGEgcmVn
aW9uLgoKDAoFBAACAAYSA0ECDwoMCgUEAAIAARIDQRAeCgwKBQQAAgADEgNBISIKgQEKBAQA
AgESA0UCPRp0IFJlcXVpcmVkLiBMb2NhdGlvbiB3aGVyZSByZXNvdXJjZSBpcyBzb3VyY2Vk
LiBGb3IgQ2xvdWQgU3RvcmFnZSwgdGhlCiBhbHBoYWJldGljYWxseSBmaXJzdCBsb2NhdGlv
biBpcyB0aGUgc291cmNlLgoKDAoFBAACAQUSA0UCCAoMCgUEAAIBARIDRQkPCgwKBQQAAgED
EgNFEhMKDAoFBAACAQgSA0UUPAoPCggEAAIBCJwIABIDRRU7CjEKBAQAAgISBEgCSS8aIyBP
cHRpb25hbC4gT3RoZXIgbGlua2VkIGxvY2F0aW9ucy4KCgwKBQQAAgIEEgNIAgoKDAoFBAAC
AgYSA0gLGQoMCgUEAAICARIDSBoqCgwKBQQAAgIDEgNILS4KDAoFBAACAggSA0kGLgoPCggE
AAICCJwIABIDSQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier ===
    # Fields for LocationIdentifier
    # Field: location_level Type: 14 (.google.cloud.capacityplanner.v1beta.LocationLevel)
    # Field: source Type: 9 ()
    # Field: linked_locations Type: 11 (.google.cloud.capacityplanner.v1beta.LocationIdentifier.LinkedLocation)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::Location - Compiled Protocol Buffers messages for google/cloud/capacityplanner/v1beta/location.proto

=head1 SYNOPSIS

    use Google::Cloud::Capacityplanner::V1beta::Location;

    my $msg = Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier->new({
        location_level => $location_level,
        source => $source,
        linked_locations => $linked_locations,
    });

    # Read or update a field
    my $val = $msg->location_level();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/capacityplanner/v1beta/location.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier

Identifier for a Google Cloud Platform location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location_level() >> / C<< $msg->location_level($value) >>

Type: C<Enum> (L<Google::Cloud::Capacityplanner::V1beta::LocationLevel>)

The location level such as a region.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Required. Location where resource is sourced. For Cloud Storage, the
alphabetically first location is the source.

=item * C<< $msg->linked_locations() >> / C<< $msg->linked_locations($value) >>

Type: C<Message> (L<Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier::LinkedLocation>)

Optional. Other linked locations.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Capacityplanner::V1beta::Location::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
