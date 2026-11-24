package Google::Cloud::Oracledatabase::V1::MinorVersion;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvbWlub3JfdmVyc2lvbi5wcm90bxIe
Z29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIp4CCgxNaW5vclZlcnNpb24S
FwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEicKDWdyaWRfaW1hZ2VfaWQYAiABKAlCA+BBAVIL
Z3JpZEltYWdlSWQSHQoHdmVyc2lvbhgDIAEoCUID4EEBUgd2ZXJzaW9uOqwB6kGoAQoqb3Jh
Y2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vTWlub3JWZXJzaW9uEl1wcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZ2lWZXJzaW9ucy97Z2lfdmVyc2lvbn0vbWlu
b3JWZXJzaW9ucy97bWlub3JfdmVyc2lvbn0qDW1pbm9yVmVyc2lvbnMyDG1pbm9yVmVyc2lv
biLJAQoYTGlzdE1pbm9yVmVyc2lvbnNSZXF1ZXN0EkoKBnBhcmVudBgBIAEoCUIy4EEC+kEs
EipvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9NaW5vclZlcnNpb25SBnBhcmVudBIg
CglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID
4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlciKYAQoZTGlzdE1p
bm9yVmVyc2lvbnNSZXNwb25zZRJTCg5taW5vcl92ZXJzaW9ucxgBIAMoCzIsLmdvb2dsZS5j
bG91ZC5vcmFjbGVkYXRhYmFzZS52MS5NaW5vclZlcnNpb25SDW1pbm9yVmVyc2lvbnMSJgoP
bmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuQusBCiJjb20uZ29vZ2xlLmNs
b3VkLm9yYWNsZWRhdGFiYXNlLnYxQhFNaW5vclZlcnNpb25Qcm90b1ABWkpjbG91ZC5nb29n
bGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xl
ZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxD
bG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNl
OjpWMUqOFwoGEgQOAFUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADsKCQoCCCUSAxUAOwoICgEI
EgMWAGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADIKCQoCCAgS
AxgAMgoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoICgEIEgMb
ADoKCQoCCC0SAxsAOgqVAQoCBAASBB8AMAEaiAEgTWlub3JWZXJzaW9uIHJlcHJlc2VudHMg
YSBtaW5vciB2ZXJzaW9uIG9mIGEgR0kuCiBodHRwczovL2RvY3Mub3JhY2xlLmNvbS9lbi11
cy9pYWFzL2FwaS8jL2VuL2RhdGFiYXNlLzIwMTYwOTE4L0dpTWlub3JWZXJzaW9uU3VtbWFy
eS8KCgoKAwQAARIDHwgUCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBAqvAQoEBAACABID
KQI9GqEBIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBNaW5vclZlcnNpb24gcmVzb3Vy
Y2Ugd2l0aCB0aGUgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97cmVn
aW9ufS9naVZlcnNpb25zL3tnaV92ZXJzaW9ufS9taW5vclZlcnNpb25zL3ttaW5vcl92ZXJz
aW9ufQoKDAoFBAACAAUSAykCCAoMCgUEAAIAARIDKQkNCgwKBQQAAgADEgMpEBEKDAoFBAAC
AAgSAykSPAoPCggEAAIACJwIABIDKRM7CjIKBAQAAgESAywCRBolIE9wdGlvbmFsLiBUaGUg
SUQgb2YgdGhlIEdyaWQgSW1hZ2UuCgoMCgUEAAIBBRIDLAIICgwKBQQAAgEBEgMsCRYKDAoF
BAACAQMSAywZGgoMCgUEAAIBCBIDLBtDCg8KCAQAAgEInAgAEgMsHEIKTwoEBAACAhIDLwI+
GkIgT3B0aW9uYWwuIFRoZSB2YWxpZCBPcmFjbGUgZ3JpZCBpbmZyYXN0cnVjdHVyZSBzb2Z0
d2FyZSB2ZXJzaW9uLgoKDAoFBAACAgUSAy8CCAoMCgUEAAICARIDLwkQCgwKBQQAAgIDEgMv
ExQKDAoFBAACAggSAy8VPQoPCggEAAICCJwIABIDLxY8CjIKAgQBEgQzAEwBGiYgVGhlIHJl
cXVlc3QgZm9yIGBNaW5vclZlcnNpb24uTGlzdGAuCgoKCgMEAQESAzMIIAqbAQoEBAECABIE
NgI7BBqMASBSZXF1aXJlZC4gVGhlIHBhcmVudCB2YWx1ZSBmb3IgdGhlIE1pbm9yVmVyc2lv
biByZXNvdXJjZSB3aXRoIHRoZSBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vZ2lWZXJzaW9ucy97Z2lfdmVyc2lvbn0KCgwKBQQBAgAFEgM2AggK
DAoFBAECAAESAzYJDwoMCgUEAQIAAxIDNhITCg0KBQQBAgAIEgQ2FDsDCg8KCAQBAgAInAgA
EgM3BCoKDwoHBAECAAifCBIEOAQ6BQrIAQoEBAECARIDQAI/GroBIE9wdGlvbmFsLiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgogSWYgdW5zcGVjaWZpZWQsIGEg
bWF4aW11bSBvZiA1MCBTeXN0ZW0gVmVyc2lvbnMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBt
YXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgcmVzZXQg
dG8gMTAwMC4KCgwKBQQBAgEFEgNAAgcKDAoFBAECAQESA0AIEQoMCgUEAQIBAxIDQBQVCgwK
BQQBAgEIEgNAFj4KDwoIBAECAQicCAASA0AXPQq9AQoEBAECAhIDRQJBGq8BIE9wdGlvbmFs
LiBBIHRva2VuIGlkZW50aWZ5aW5nIHRoZSByZXF1ZXN0ZWQgcGFnZSBvZiByZXN1bHRzIHRv
IHJldHVybi4gQWxsCiBmaWVsZHMgZXhjZXB0IHRoZSBmaWx0ZXIgc2hvdWxkIHJlbWFpbiB0
aGUgc2FtZSBhcyBpbiB0aGUgcmVxdWVzdCB0aGF0CiBwcm92aWRlZCB0aGlzIHBhZ2UgdG9r
ZW4uCgoMCgUEAQICBRIDRQIICgwKBQQBAgIBEgNFCRMKDAoFBAECAgMSA0UWFwoMCgUEAQIC
CBIDRRhACg8KCAQBAgIInAgAEgNFGT8KggIKBAQBAgMSA0sCPRr0ASBPcHRpb25hbC4gQW4g
ZXhwcmVzc2lvbiBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LiBP
bmx5IHRoZQogYHNoYXBlX2ZhbWlseWAgYW5kIGBnY3Bfb3JhY2xlX3pvbmVfaWRgIGZpZWxk
cyBhcmUgc3VwcG9ydGVkIGluIHRoZQogZm9sbG93aW5nIGZvcm1hdDogYHNoYXBlX2ZhbWls
eT0ie3NoYXBlX2ZhbWlseX0iIEFORAogZ2NwX29yYWNsZV96b25lX2lkPSJ7Z2NwX29yYWNs
ZV96b25lX2lkfSJgLgoKDAoFBAECAwUSA0sCCAoMCgUEAQIDARIDSwkPCgwKBQQBAgMDEgNL
EhMKDAoFBAECAwgSA0sUPAoPCggEAQIDCJwIABIDSxU7CjMKAgQCEgRPAFUBGicgVGhlIHJl
c3BvbnNlIGZvciBgTWlub3JWZXJzaW9uLkxpc3RgLgoKCgoDBAIBEgNPCCEKKQoEBAICABID
UQIrGhwgVGhlIGxpc3Qgb2YgTWlub3JWZXJzaW9ucy4KCgwKBQQCAgAEEgNRAgoKDAoFBAIC
AAYSA1ELFwoMCgUEAgIAARIDURgmCgwKBQQCAgADEgNRKSoKTgoEBAICARIDVAIdGkEgQSB0
b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCBy
ZXR1cm4uCgoMCgUEAgIBBRIDVAIICgwKBQQCAgEBEgNUCRgKDAoFBAICAQMSA1QbHGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion ===
    # Fields for MinorVersion
    # Field: name Type: 9 ()
    # Field: grid_image_id Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsRequest ===
    # Fields for ListMinorVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsResponse ===
    # Fields for ListMinorVersionsResponse
    # Field: minor_versions Type: 11 (.google.cloud.oracledatabase.v1.MinorVersion)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::MinorVersion - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/minor_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::MinorVersion;

    my $msg = Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion->new({
        name => $name,
        grid_image_id => $grid_image_id,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/minor_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion

MinorVersion represents a minor version of a GI.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/GiMinorVersionSummary/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the MinorVersion resource with the format:
projects/{project}/locations/{region}/giVersions/{gi_version}/minorVersions/{minor_version}

=item * C<< $msg->grid_image_id() >> / C<< $msg->grid_image_id($value) >>

Type: C<String>

Optional. The ID of the Grid Image.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. The valid Oracle grid infrastructure software version.

=back

=head2 Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsRequest

The request for `MinorVersion.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the MinorVersion resource with the format:
projects/{project}/locations/{location}/giVersions/{gi_version}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, a maximum of 50 System Versions will be returned.
The maximum value is 1000; values above 1000 will be reset to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the requested page of results to return. All
fields except the filter should remain the same as in the request that
provided this page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Only the
`shape_family` and `gcp_oracle_zone_id` fields are supported in the
following format: `shape_family="{shape_family}" AND
gcp_oracle_zone_id="{gcp_oracle_zone_id}"`.

=back

=head2 Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsResponse

The response for `MinorVersion.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->minor_versions() >> / C<< $msg->minor_versions($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion>)

The list of MinorVersions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::MinorVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
