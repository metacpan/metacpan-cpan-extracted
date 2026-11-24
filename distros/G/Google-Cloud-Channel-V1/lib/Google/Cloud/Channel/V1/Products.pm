package Google::Cloud::Channel::V1::Products;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9wcm9kdWN0cy5wcm90bxIXZ29vZ2xlLmNsb3Vk
LmNoYW5uZWwudjEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iqgEKB1Byb2R1Y3QSEgoE
bmFtZRgBIAEoCVIEbmFtZRJNCg5tYXJrZXRpbmdfaW5mbxgCIAEoCzImLmdvb2dsZS5jbG91
ZC5jaGFubmVsLnYxLk1hcmtldGluZ0luZm9SDW1hcmtldGluZ0luZm86POpBOQojY2xvdWRj
aGFubmVsLmdvb2dsZWFwaXMuY29tL1Byb2R1Y3QSEnByb2R1Y3RzL3twcm9kdWN0fSLpAQoD
U2t1EhIKBG5hbWUYASABKAlSBG5hbWUSTQoObWFya2V0aW5nX2luZm8YAiABKAsyJi5nb29n
bGUuY2xvdWQuY2hhbm5lbC52MS5NYXJrZXRpbmdJbmZvUg1tYXJrZXRpbmdJbmZvEjoKB3By
b2R1Y3QYAyABKAsyIC5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5Qcm9kdWN0Ugdwcm9kdWN0
OkPqQUAKH2Nsb3VkY2hhbm5lbC5nb29nbGVhcGlzLmNvbS9Ta3USHXByb2R1Y3RzL3twcm9k
dWN0fS9za3VzL3tza3V9IpcBCg1NYXJrZXRpbmdJbmZvEiEKDGRpc3BsYXlfbmFtZRgBIAEo
CVILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEkEKDGRl
ZmF1bHRfbG9nbxgDIAEoCzIeLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLk1lZGlhUgtkZWZh
dWx0TG9nbyJvCgVNZWRpYRIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSGAoHY29udGVudBgCIAEo
CVIHY29udGVudBI2CgR0eXBlGAMgASgOMiIuZ29vZ2xlLmNsb3VkLmNoYW5uZWwudjEuTWVk
aWFUeXBlUgR0eXBlKj0KCU1lZGlhVHlwZRIaChZNRURJQV9UWVBFX1VOU1BFQ0lGSUVEEAAS
FAoQTUVESUFfVFlQRV9JTUFHRRABQmUKG2NvbS5nb29nbGUuY2xvdWQuY2hhbm5lbC52MUIN
UHJvZHVjdHNQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2NoYW5uZWwvYXBpdjEvY2hh
bm5lbHBiO2NoYW5uZWxwYkq8EwoGEgQOAF0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACMKCAoBCBIDFABMCgkKAggLEgMUAEwKCAoB
CBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAuCgkKAggIEgMWAC4KCAoBCBIDFwA0CgkKAggB
EgMXADQKIQoCBQASBBoAIAEaFSBUeXBlIG9mIG1lZGlhIHVzZWQuCgoKCgMFAAESAxoFDgoY
CgQFAAIAEgMcAh0aCyBOb3QgdXNlZC4KCgwKBQUAAgABEgMcAhgKDAoFBQACAAISAxwbHAod
CgQFAAIBEgMfAhcaECBUeXBlIG9mIGltYWdlLgoKDAoFBQACAQESAx8CEgoMCgUFAAIBAhID
HxUWCn8KAgQAEgQkADABGnMgQSBQcm9kdWN0IGlzIHRoZSBlbnRpdHkgYSBjdXN0b21lciB1
c2VzIHdoZW4gcGxhY2luZyBhbiBvcmRlci4gRm9yIGV4YW1wbGUsCiBHb29nbGUgV29ya3Nw
YWNlLCBHb29nbGUgVm9pY2UsIGV0Yy4KCgoKAwQAARIDJAgPCgsKAwQABxIEJQIoBAoNCgUE
AAedCBIEJQIoBApLCgQEAAIAEgMsAhIaPiBSZXNvdXJjZSBOYW1lIG9mIHRoZSBQcm9kdWN0
LgogRm9ybWF0OiBwcm9kdWN0cy97cHJvZHVjdF9pZH0KCgwKBQQAAgAFEgMsAggKDAoFBAAC
AAESAywJDQoMCgUEAAIAAxIDLBARCjUKBAQAAgESAy8CIxooIE1hcmtldGluZyBpbmZvcm1h
dGlvbiBmb3IgdGhlIHByb2R1Y3QuCgoMCgUEAAIBBhIDLwIPCgwKBQQAAgEBEgMvEB4KDAoF
BAACAQMSAy8hIgr8AQoCBAESBDYARQEa7wEgUmVwcmVzZW50cyBhIHByb2R1Y3QncyBwdXJj
aGFzYWJsZSBTdG9jayBLZWVwaW5nIFVuaXQgKFNLVSkuCiBTS1VzIHJlcHJlc2VudCB0aGUg
ZGlmZmVyZW50IHZhcmlhdGlvbnMgb2YgdGhlIHByb2R1Y3QuIEZvciBleGFtcGxlLCBHb29n
bGUKIFdvcmtzcGFjZSBCdXNpbmVzcyBTdGFuZGFyZCBhbmQgR29vZ2xlIFdvcmtzcGFjZSBC
dXNpbmVzcyBQbHVzIGFyZSBHb29nbGUKIFdvcmtzcGFjZSBwcm9kdWN0IFNLVXMuCgoKCgME
AQESAzYICwoLCgMEAQcSBDcCOgQKDQoFBAEHnQgSBDcCOgQKVQoEBAECABIDPgISGkggUmVz
b3VyY2UgTmFtZSBvZiB0aGUgU0tVLgogRm9ybWF0OiBwcm9kdWN0cy97cHJvZHVjdF9pZH0v
c2t1cy97c2t1X2lkfQoKDAoFBAECAAUSAz4CCAoMCgUEAQIAARIDPgkNCgwKBQQBAgADEgM+
EBEKMQoEBAECARIDQQIjGiQgTWFya2V0aW5nIGluZm9ybWF0aW9uIGZvciB0aGUgU0tVLgoK
DAoFBAECAQYSA0ECDwoMCgUEAQIBARIDQRAeCgwKBQQBAgEDEgNBISIKMgoEBAECAhIDRAIW
GiUgUHJvZHVjdCB0aGUgU0tVIGlzIGFzc29jaWF0ZWQgd2l0aC4KCgwKBQQBAgIGEgNEAgkK
DAoFBAECAgESA0QKEQoMCgUEAQICAxIDRBQVCk8KAgQCEgRIAFEBGkMgUmVwcmVzZW50cyB0
aGUgbWFya2V0aW5nIGluZm9ybWF0aW9uIGZvciBhIFByb2R1Y3QsIFNLVSBvciBPZmZlci4K
CgoKAwQCARIDSAgVCiMKBAQCAgASA0oCGhoWIEh1bWFuIHJlYWRhYmxlIG5hbWUuCgoMCgUE
AgIABRIDSgIICgwKBQQCAgABEgNKCRUKDAoFBAICAAMSA0oYGQpICgQEAgIBEgNNAhkaOyBI
dW1hbiByZWFkYWJsZSBkZXNjcmlwdGlvbi4gRGVzY3JpcHRpb24gY2FuIGNvbnRhaW4gSFRN
TC4KCgwKBQQCAgEFEgNNAggKDAoFBAICAQESA00JFAoMCgUEAgIBAxIDTRcYChwKBAQCAgIS
A1ACGRoPIERlZmF1bHQgbG9nby4KCgwKBQQCAgIGEgNQAgcKDAoFBAICAgESA1AIFAoMCgUE
AgICAxIDUBcYCisKAgQDEgRUAF0BGh8gUmVwcmVzZW50cyBtZWRpYSBpbmZvcm1hdGlvbi4K
CgoKAwQDARIDVAgNCiIKBAQDAgASA1YCExoVIFRpdGxlIG9mIHRoZSBtZWRpYS4KCgwKBQQD
AgAFEgNWAggKDAoFBAMCAAESA1YJDgoMCgUEAwIAAxIDVhESCiAKBAQDAgESA1kCFRoTIFVS
TCBvZiB0aGUgbWVkaWEuCgoMCgUEAwIBBRIDWQIICgwKBQQDAgEBEgNZCRAKDAoFBAMCAQMS
A1kTFAohCgQEAwICEgNcAhUaFCBUeXBlIG9mIHRoZSBtZWRpYS4KCgwKBQQDAgIGEgNcAgsK
DAoFBAMCAgESA1wMEAoMCgUEAwICAxIDXBMUYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::Products::Product ===
    # Fields for Product
    # Field: name Type: 9 ()
    # Field: marketing_info Type: 11 (.google.cloud.channel.v1.MarketingInfo)

# === Message: Google::Cloud::Channel::V1::Products::Sku ===
    # Fields for Sku
    # Field: name Type: 9 ()
    # Field: marketing_info Type: 11 (.google.cloud.channel.v1.MarketingInfo)
    # Field: product Type: 11 (.google.cloud.channel.v1.Product)

# === Message: Google::Cloud::Channel::V1::Products::MarketingInfo ===
    # Fields for MarketingInfo
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: default_logo Type: 11 (.google.cloud.channel.v1.Media)

# === Message: Google::Cloud::Channel::V1::Products::Media ===
    # Fields for Media
    # Field: title Type: 9 ()
    # Field: content Type: 9 ()
    # Field: type Type: 14 (.google.cloud.channel.v1.MediaType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::Products - Compiled Protocol Buffers messages for google/cloud/channel/v1/products.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::Products;

    my $msg = Google::Cloud::Channel::V1::Products::Product->new({
        name => $name,
        marketing_info => $marketing_info,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::Products::Product->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/products.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::Products::Product

A Product is the entity a customer uses when placing an order. For example,
Google Workspace, Google Voice, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource Name of the Product.
Format: products/{product_id}

=item * C<< $msg->marketing_info() >> / C<< $msg->marketing_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::MarketingInfo>)

Marketing information for the product.

=back

=head2 Google::Cloud::Channel::V1::Products::Sku

Represents a product's purchasable Stock Keeping Unit (SKU).
SKUs represent the different variations of the product. For example, Google
Workspace Business Standard and Google Workspace Business Plus are Google
Workspace product SKUs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource Name of the SKU.
Format: products/{product_id}/skus/{sku_id}

=item * C<< $msg->marketing_info() >> / C<< $msg->marketing_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::MarketingInfo>)

Marketing information for the SKU.

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::Product>)

Product the SKU is associated with.

=back

=head2 Google::Cloud::Channel::V1::Products::MarketingInfo

Represents the marketing information for a Product, SKU or Offer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Human readable name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Human readable description. Description can contain HTML.

=item * C<< $msg->default_logo() >> / C<< $msg->default_logo($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Products::Media>)

Default logo.

=back

=head2 Google::Cloud::Channel::V1::Products::Media

Represents media information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Title of the media.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

URL of the media.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::MediaType>)

Type of the media.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::Products::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
