package Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cklnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL3NlY3VyaXR5X3Byb2ZpbGVfZ3Jv
dXBfdXJsZmlsdGVyaW5nLnByb3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYx
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvImcKE1VybEZpbHRlcmluZ1Byb2Zp
bGUSUAoLdXJsX2ZpbHRlcnMYASADKAsyKi5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5
LnYxLlVybEZpbHRlckID4EEBUgp1cmxGaWx0ZXJzIpcCCglVcmxGaWx0ZXISbQoQZmlsdGVy
aW5nX2FjdGlvbhgBIAEoDjI9Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuVXJs
RmlsdGVyLlVybEZpbHRlcmluZ0FjdGlvbkID4EECUg9maWx0ZXJpbmdBY3Rpb24SFwoEdXJs
cxgCIAMoCUID4EECUgR1cmxzEiQKCHByaW9yaXR5GAMgASgFQgPgQQJIAFIIcHJpb3JpdHmI
AQEiTwoSVXJsRmlsdGVyaW5nQWN0aW9uEiQKIFVSTF9GSUxURVJJTkdfQUNUSU9OX1VOU1BF
Q0lGSUVEEAASCQoFQUxMT1cQARIICgRERU5ZEAJCCwoJX3ByaW9yaXR5QoYCCiNjb20uZ29v
Z2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MUIlU2VjdXJpdHlQcm9maWxlR3JvdXBVcmxG
aWx0ZXJpbmdQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZWN1cml0eS9h
cGl2MS9uZXR3b3Jrc2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCH0dvb2dsZS5DbG91
ZC5OZXR3b3JrU2VjdXJpdHkuVjHKAh9Hb29nbGVcQ2xvdWRcTmV0d29ya1NlY3VyaXR5XFYx
6gIiR29vZ2xlOjpDbG91ZDo6TmV0d29ya1NlY3VyaXR5OjpWMUrYEAoGEgQOAD0BCrwECgEM
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
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCAoB
CBIDFAA8CgkKAgglEgMUADwKCAoBCBIDFQBkCgkKAggLEgMVAGQKCAoBCBIDFgAiCgkKAggK
EgMWACIKCAoBCBIDFwBGCgkKAggIEgMXAEYKCAoBCBIDGAA8CgkKAggBEgMYADwKCAoBCBID
GQA8CgkKAggpEgMZADwKCAoBCBIDGgA7CgkKAggtEgMaADsKPwoCBAASBB0AIQEaMyBVcmxG
aWx0ZXJpbmdQcm9maWxlIGRlZmluZXMgZmlsdGVycyBiYXNlZCBvbiBVUkwuCgoKCgMEAAES
Ax0IGwp6CgQEAAIAEgMgAk4abSBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgZmlsdGVyaW5nIGNv
bmZpZ3MgaW4gd2hpY2ggZWFjaCBjb25maWcgZGVmaW5lcyBhbgogYWN0aW9uIHRvIHRha2Ug
Zm9yIHNvbWUgVVJMIG1hdGNoLgoKDAoFBAACAAQSAyACCgoMCgUEAAIABhIDIAsUCgwKBQQA
AgABEgMgFSAKDAoFBAACAAMSAyAjJAoMCgUEAAIACBIDICVNCg8KCAQAAgAInAgAEgMgJkwK
SAoCBAESBCQAPQEaPCBBIFVSTCBmaWx0ZXIgZGVmaW5lcyBhbiBhY3Rpb24gdG8gdGFrZSBm
b3Igc29tZSBVUkwgbWF0Y2guCgoKCgMEAQESAyQIEQo/CgQEAQQAEgQmAi8DGjEgQWN0aW9u
IHRvIGJlIHRha2VuIHdoZW4gYSBVUkwgbWF0Y2hlcyBhIGZpbHRlci4KCgwKBQQBBAABEgMm
BxkKMAoGBAEEAAIAEgMoBCkaISBGaWx0ZXJpbmcgYWN0aW9uIG5vdCBzcGVjaWZpZWQuCgoO
CgcEAQQAAgABEgMoBCQKDgoHBAEEAAIAAhIDKCcoClEKBgQBBAACARIDKwQOGkIgVGhlIGNv
bm5lY3Rpb24gbWF0Y2hpbmcgdGhpcyBmaWx0ZXIgd2lsbCBiZSBhbGxvd2VkIHRvIHRyYW5z
bWl0LgoKDgoHBAEEAAIBARIDKwQJCg4KBwQBBAACAQISAysMDQpFCgYEAQQAAgISAy4EDRo2
IFRoZSBjb25uZWN0aW9uIG1hdGNoaW5nIHRoaXMgZmlsdGVyIHdpbGwgYmUgZHJvcHBlZC4K
Cg4KBwQBBAACAgESAy4ECAoOCgcEAQQAAgICEgMuCwwKRwoEBAECABIEMgIzLxo5IFJlcXVp
cmVkLiBUaGUgYWN0aW9uIHRha2VuIHdoZW4gdGhpcyBmaWx0ZXIgaXMgYXBwbGllZC4KCgwK
BQQBAgAGEgMyAhQKDAoFBAECAAESAzIVJQoMCgUEAQIAAxIDMigpCgwKBQQBAgAIEgMzBi4K
DwoIBAECAAicCAASAzMHLQpnCgQEAQIBEgM3AkQaWiBSZXF1aXJlZC4gVGhlIGxpc3Qgb2Yg
c3RyaW5ncyB0aGF0IGEgVVJMIG11c3QgbWF0Y2ggd2l0aCBmb3IgdGhpcyBmaWx0ZXIgdG8K
IGJlIGFwcGxpZWQuCgoMCgUEAQIBBBIDNwIKCgwKBQQBAgEFEgM3CxEKDAoFBAECAQESAzcS
FgoMCgUEAQIBAxIDNxkaCgwKBQQBAgEIEgM3G0MKDwoIBAECAQicCAASAzccQgrMAQoEBAEC
AhIDPAJHGr4BIFJlcXVpcmVkLiBUaGUgcHJpb3JpdHkgb2YgdGhpcyBmaWx0ZXIgd2l0aGlu
IHRoZSBVUkwgRmlsdGVyaW5nIFByb2ZpbGUuCiBMb3dlciBpbnRlZ2VycyBpbmRpY2F0ZSBo
aWdoZXIgcHJpb3JpdGllcy4gVGhlIHByaW9yaXR5IG9mIGEgZmlsdGVyIG11c3QgYmUKIHVu
aXF1ZSB3aXRoaW4gYSBVUkwgRmlsdGVyaW5nIFByb2ZpbGUuCgoMCgUEAQICBBIDPAIKCgwK
BQQBAgIFEgM8CxAKDAoFBAECAgESAzwRGQoMCgUEAQICAxIDPBwdCgwKBQQBAgIIEgM8HkYK
DwoIBAECAgicCAASAzwfRWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilteringProfile ===
    # Fields for UrlFilteringProfile
    # Field: url_filters Type: 11 (.google.cloud.networksecurity.v1.UrlFilter)

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilteringProfile - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering;

    my $msg = Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilteringProfile->new(
        url_filters => $value,
    );

=head1 FIELDS

=over 4

=item * B<url_filters>

Type: Message (.google.cloud.networksecurity.v1.UrlFilter)

=back

=cut

# === Message: Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilter ===
    # Fields for UrlFilter
    # Field: filtering_action Type: 14 (.google.cloud.networksecurity.v1.UrlFilter.UrlFilteringAction)
    # Field: urls Type: 9 ()
    # Field: priority Type: 5 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilter - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering;

    my $msg = Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilter->new(
        filtering_action => $value,
    );

=head1 FIELDS

=over 4

=item * B<filtering_action>

Type: Enum (.google.cloud.networksecurity.v1.UrlFilter.UrlFilteringAction)

=item * B<urls>

Type: String

=item * B<priority>

Type: Int32

=back

=cut

# Enum: UrlFilter::UrlFilteringAction
our $UrlFilter_URL_FILTERING_ACTION_UNSPECIFIED = 0;
our $UrlFilter_ALLOW = 1;
our $UrlFilter_DENY = 2;

=pod

=head2 Enum: UrlFilter::UrlFilteringAction

Values:

=over 4

=item * C<URL_FILTERING_ACTION_UNSPECIFIED> => 0

=item * C<ALLOW> => 1

=item * C<DENY> => 2

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
