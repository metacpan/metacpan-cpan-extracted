package Google::Cloud::Chronicle::V1::FeaturedContentMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL2ZlYXR1cmVkX2NvbnRlbnRfbWV0YWRhdGEu
cHJvdG8SGWdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ihgUKF0ZlYXR1
cmVkQ29udGVudE1ldGFkYXRhEhMKAmlkGAEgASgJQgPgQQJSAmlkEiYKDGRpc3BsYXlfbmFt
ZRgCIAEoCUID4EEDUgtkaXNwbGF5TmFtZRJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgE
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIbCgZh
dXRob3IYBSABKAlCA+BBA1IGYXV0aG9yEiEKCWNlcnRpZmllZBgGIAEoCEID4EEDUgljZXJ0
aWZpZWQSJQoLZGVzY3JpcHRpb24YByABKAlCA+BBA1ILZGVzY3JpcHRpb24SIwoKY2F0ZWdv
cmllcxgIIAMoCUID4EEDUgpjYXRlZ29yaWVzEh0KB3ZlcnNpb24YCSABKAlCA+BBA1IHdmVy
c2lvbhIkCgh2ZXJpZmllZBgKIAEoCEID4EEDSABSCHZlcmlmaWVkiAEBEmoKC3NvdXJjZV90
eXBlGAsgASgOMkQuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5GZWF0dXJlZENvbnRlbnRN
ZXRhZGF0YS5Db250ZW50U291cmNlVHlwZUID4EEDUgpzb3VyY2VUeXBlImAKEUNvbnRlbnRT
b3VyY2VUeXBlEiMKH0NPTlRFTlRfU09VUkNFX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZHT09H
TEUQARINCglDT01NVU5JVFkQAhILCgdQQVJUTkVSEANCCwoJX3ZlcmlmaWVkQtMBCh1jb20u
Z29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MUIcRmVhdHVyZWRDb250ZW50TWV0YWRhdGFQcm90
b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2Nocm9uaWNsZS9hcGl2MS9jaHJvbmljbGVwYjtj
aHJvbmljbGVwYqoCGUdvb2dsZS5DbG91ZC5DaHJvbmljbGUuVjHKAhlHb29nbGVcQ2xvdWRc
Q2hyb25pY2xlXFYx6gIcR29vZ2xlOjpDbG91ZDo6Q2hyb25pY2xlOjpWMUqWFwoGEgQOAFMB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMS
ACkKCQoCAwESAxMAKQoICgEIEgMVADYKCQoCCCUSAxUANgoICgEIEgMWAFIKCQoCCAsSAxYA
UgoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAD0KCQoCCAgSAxgAPQoICgEIEgMZADYK
CQoCCAESAxkANgoICgEIEgMaADYKCQoCCCkSAxoANgoICgEIEgMbADUKCQoCCC0SAxsANQpQ
CgIEABIEHgBTARpEIEZlYXR1cmVkQ29udGVudE1ldGFkYXRhIGhvbGRzIG1ldGFkYXRhIGFi
b3V0IHRoZSBGZWF0dXJlZCBDb250ZW50LgoKCgoDBAABEgMeCB8KSQoEBAAEABIEIAIsAxo7
IENvbnRlbnRTb3VyY2VUeXBlIHNwZWNpZnlpbmcgdGhlIGNvbnRlbnQgc291cmNlIG9mIG9y
aWdpbgoKDAoFBAAEAAESAyAHGAowCgYEAAQAAgASAyIEKBohIFVuc3BlY2lmaWVkIGNvbnRl
bnQgc291cmNlIHR5cGUKCg4KBwQABAACAAESAyIEIwoOCgcEAAQAAgACEgMiJicKNQoGBAAE
AAIBEgMlBA8aJiBDZXJ0aWZpZWQgR29vZ2xlIGNvbnRlbnQgc291cmNlIHR5cGUKCg4KBwQA
BAACAQESAyUECgoOCgcEAAQAAgECEgMlDQ4KLgoGBAAEAAICEgMoBBIaHyBDb21tdW5pdHkg
Y29udGVudCBzb3VyY2UgdHlwZQoKDgoHBAAEAAICARIDKAQNCg4KBwQABAACAgISAygQEQos
CgYEAAQAAgMSAysEEBodIFBhcnRuZXIgY29udGVudCBzb3VyY2UgdHlwZQoKDgoHBAAEAAID
ARIDKwQLCg4KBwQABAACAwISAysODwpDCgQEAAIAEgMvAjkaNiBSZXF1aXJlZC4gVW5pcXVl
IGlkZW50aWZpZXIgb2YgdGhlIGZlYXR1cmVkIGNvbnRlbnQuCgoMCgUEAAIABRIDLwIICgwK
BQQAAgABEgMvCQsKDAoFBAACAAMSAy8ODwoMCgUEAAIACBIDLxA4Cg8KCAQAAgAInAgAEgMv
ETcKRQoEBAACARIDMgJGGjggT3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhl
IGZlYXR1cmVkIGNvbnRlbnQuCgoMCgUEAAIBBRIDMgIICgwKBQQAAgEBEgMyCRUKDAoFBAAC
AQMSAzIYGQoMCgUEAAIBCBIDMhpFCg8KCAQAAgEInAgAEgMyG0QKTAoEBAACAhIENQI2Mho+
IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgaW5kaWNhdGluZyB3aGVuIHRoZSBpdGVtIHdhcyBj
cmVhdGVkLgoKDAoFBAACAgYSAzUCGwoMCgUEAAICARIDNRwnCgwKBQQAAgIDEgM1KisKDAoF
BAACAggSAzYGMQoPCggEAAICCJwIABIDNgcwCkwKBAQAAgMSBDkCOjIaPiBPdXRwdXQgb25s
eS4gVGltZXN0YW1wIGluZGljYXRpbmcgd2hlbiB0aGUgaXRlbSB3YXMgdXBkYXRlZC4KCgwK
BQQAAgMGEgM5AhsKDAoFBAACAwESAzkcJwoMCgUEAAIDAxIDOSorCgwKBQQAAgMIEgM6BjEK
DwoIBAACAwicCAASAzoHMAo6CgQEAAIEEgM9AkAaLSBPdXRwdXQgb25seS4gQ29udGVudCBp
dGVtIGF1dGhvciBmdWxsIG5hbWUuCgoMCgUEAAIEBRIDPQIICgwKBQQAAgQBEgM9CQ8KDAoF
BAACBAMSAz0SEwoMCgUEAAIECBIDPRQ/Cg8KCAQAAgQInAgAEgM9FT4KegoEBAACBRIDQQJB
Gm0gT3V0cHV0IG9ubHkuIERldGVybWluZSBpZiB0aGlzIGNvbnRlbnQgaXRlbSBpcyBvZmZp
Y2lhbGx5IGNlcnRpZmllZCBieQogR29vZ2xlIG9yIGNyZWF0ZWQgYnkgdGhlIGNvbW11bml0
eS4KCgwKBQQAAgUFEgNBAgYKDAoFBAACBQESA0EHEAoMCgUEAAIFAxIDQRMUCgwKBQQAAgUI
EgNBFUAKDwoIBAACBQicCAASA0EWPwpACgQEAAIGEgNEAkUaMyBPdXRwdXQgb25seS4gVGhl
IGRlc2NyaXB0aW9uIG9mIHRoZSBjb250ZW50IGl0ZW0uCgoMCgUEAAIGBRIDRAIICgwKBQQA
AgYBEgNECRQKDAoFBAACBgMSA0QXGAoMCgUEAAIGCBIDRBlECg8KCAQAAgYInAgAEgNEGkMK
RgoEBAACBxIDRwJNGjkgT3V0cHV0IG9ubHkuIENhdGVnb3JpZXMgdGhlIGNvbnRlbnQgaXMg
YXNzb2NpYXRlZCB3aXRoLgoKDAoFBAACBwQSA0cCCgoMCgUEAAIHBRIDRwsRCgwKBQQAAgcB
EgNHEhwKDAoFBAACBwMSA0cfIAoMCgUEAAIHCBIDRyFMCg8KCAQAAgcInAgAEgNHIksKSQoE
BAACCBIDSgJBGjwgT3V0cHV0IG9ubHkuIEZlYXR1cmVkIGNvbnRlbnQgdmVyc2lvbiAoTWFq
b3IuTWlub3IuUGF0Y2gpLgoKDAoFBAACCAUSA0oCCAoMCgUEAAIIARIDSgkQCgwKBQQAAggD
EgNKExQKDAoFBAACCAgSA0oVQAoPCggEAAIICJwIABIDShY/CmoKBAQAAgkSA04CShpdIE91
dHB1dCBvbmx5LiBXaGV0aGVyIHRoZSBjb250ZW50IGlzIHZlcmlmaWVkIGJ5IEdvb2dsZSAo
YXBwbGljYWJsZSBmb3IgM3JkCiBwYXJ0eSBjb250ZW50KS4KCgwKBQQAAgkEEgNOAgoKDAoF
BAACCQUSA04LDwoMCgUEAAIJARIDThAYCgwKBQQAAgkDEgNOGx0KDAoFBAACCQgSA04eSQoP
CggEAAIJCJwIABIDTh9ICjwKBAQAAgoSBFECUjIaLiBPdXRwdXQgb25seS4gVGhlIHNvdXJj
ZSB0eXBlIG9mIHRoZSBjb250ZW50LgoKDAoFBAACCgYSA1ECEwoMCgUEAAIKARIDURQfCgwK
BQQAAgoDEgNRIiQKDAoFBAACCggSA1IGMQoPCggEAAIKCJwIABIDUgcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata ===
    # Fields for FeaturedContentMetadata
    # Field: id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: author Type: 9 ()
    # Field: certified Type: 8 ()
    # Field: description Type: 9 ()
    # Field: categories Type: 9 ()
    # Field: version Type: 9 ()
    # Field: verified Type: 8 ()
    # Field: source_type Type: 14 (.google.cloud.chronicle.v1.FeaturedContentMetadata.ContentSourceType)

# Enum: FeaturedContentMetadata::ContentSourceType
our $FeaturedContentMetadata_CONTENT_SOURCE_TYPE_UNSPECIFIED = 0;
our $FeaturedContentMetadata_GOOGLE = 1;
our $FeaturedContentMetadata_COMMUNITY = 2;
our $FeaturedContentMetadata_PARTNER = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::FeaturedContentMetadata - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/featured_content_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::FeaturedContentMetadata;

    my $msg = Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata->new({
        id => $id,
        display_name => $display_name,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/featured_content_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata

FeaturedContentMetadata holds metadata about the Featured Content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. Unique identifier of the featured content.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the featured content.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp indicating when the item was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp indicating when the item was updated.

=item * C<< $msg->author() >> / C<< $msg->author($value) >>

Type: C<String>

Output only. Content item author full name.

=item * C<< $msg->certified() >> / C<< $msg->certified($value) >>

Type: C<Bool>

Output only. Determine if this content item is officially certified by
Google or created by the community.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the content item.

=item * C<< $msg->categories() >> / C<< $msg->categories($value) >>

Type: C<String>

Output only. Categories the content is associated with.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Output only. Featured content version (Major.Minor.Patch).

=item * C<< $msg->verified() >> / C<< $msg->verified($value) >>

Type: C<Bool>

Output only. Whether the content is verified by Google (applicable for 3rd
party content).

=item * C<< $msg->source_type() >> / C<< $msg->source_type($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::FeaturedContentMetadata::ContentSourceType>)

Output only. The source type of the content.

=back

=head3 Enum: FeaturedContentMetadata::ContentSourceType

=over 4

=item * C<CONTENT_SOURCE_TYPE_UNSPECIFIED> => C<0>

=item * C<GOOGLE> => C<1>

=item * C<COMMUNITY> => C<2>

=item * C<PARTNER> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::FeaturedContentMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
