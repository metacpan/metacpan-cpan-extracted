package Google::Cloud::Video::Stitcher::V1::Companions;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Video::Stitcher::V1::Events };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvY29tcGFuaW9ucy5wcm90bxIeZ29v
Z2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxGitnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNo
ZXIvdjEvZXZlbnRzLnByb3RvIqICCgxDb21wYW5pb25BZHMScAoTZGlzcGxheV9yZXF1aXJl
bWVudBgBIAEoDjI/Lmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5Db21wYW5pb25B
ZHMuRGlzcGxheVJlcXVpcmVtZW50UhJkaXNwbGF5UmVxdWlyZW1lbnQSSQoKY29tcGFuaW9u
cxgCIAMoCzIpLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5Db21wYW5pb25SCmNv
bXBhbmlvbnMiVQoSRGlzcGxheVJlcXVpcmVtZW50EiMKH0RJU1BMQVlfUkVRVUlSRU1FTlRf
VU5TUEVDSUZJRUQQABIHCgNBTEwQARIHCgNBTlkQAhIICgROT05FEAMinAUKCUNvbXBhbmlv
bhJgChJpZnJhbWVfYWRfcmVzb3VyY2UYCiABKAsyMC5nb29nbGUuY2xvdWQudmlkZW8uc3Rp
dGNoZXIudjEuSWZyYW1lQWRSZXNvdXJjZUgAUhBpZnJhbWVBZFJlc291cmNlEmAKEnN0YXRp
Y19hZF9yZXNvdXJjZRgLIAEoCzIwLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5T
dGF0aWNBZFJlc291cmNlSABSEHN0YXRpY0FkUmVzb3VyY2USWgoQaHRtbF9hZF9yZXNvdXJj
ZRgMIAEoCzIuLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5IdG1sQWRSZXNvdXJj
ZUgAUg5odG1sQWRSZXNvdXJjZRIjCg1hcGlfZnJhbWV3b3JrGAEgASgJUgxhcGlGcmFtZXdv
cmsSGwoJaGVpZ2h0X3B4GAIgASgFUghoZWlnaHRQeBIZCgh3aWR0aF9weBgDIAEoBVIHd2lk
dGhQeBImCg9hc3NldF9oZWlnaHRfcHgYBCABKAVSDWFzc2V0SGVpZ2h0UHgSLAoSZXhwYW5k
ZWRfaGVpZ2h0X3B4GAUgASgFUhBleHBhbmRlZEhlaWdodFB4EiQKDmFzc2V0X3dpZHRoX3B4
GAYgASgFUgxhc3NldFdpZHRoUHgSKgoRZXhwYW5kZWRfd2lkdGhfcHgYByABKAVSD2V4cGFu
ZGVkV2lkdGhQeBIcCgphZF9zbG90X2lkGAggASgJUghhZFNsb3RJZBI9CgZldmVudHMYCSAD
KAsyJS5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuRXZlbnRSBmV2ZW50c0INCgth
ZF9yZXNvdXJjZSIxCg5IdG1sQWRSZXNvdXJjZRIfCgtodG1sX3NvdXJjZRgBIAEoCVIKaHRt
bFNvdXJjZSIkChBJZnJhbWVBZFJlc291cmNlEhAKA3VyaRgBIAEoCVIDdXJpIkkKEFN0YXRp
Y0FkUmVzb3VyY2USEAoDdXJpGAEgASgJUgN1cmkSIwoNY3JlYXRpdmVfdHlwZRgCIAEoCVIM
Y3JlYXRpdmVUeXBlQncKImNvbS5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjFCD0Nv
bXBhbmlvbnNQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL3ZpZGVvL3N0aXRjaGVyL2Fw
aXYxL3N0aXRjaGVycGI7c3RpdGNoZXJwYkrLHAoGEgQOAHABCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSADUKCAoBCBIDFABVCgkKAggL
EgMUAFUKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgAwCgkKAggIEgMWADAKCAoBCBID
FwA7CgkKAggBEgMXADsKKQoCBAASBBoALwEaHSBNZXRhZGF0YSBmb3IgY29tcGFuaW9uIGFk
cy4KCgoKAwQAARIDGggUClUKBAQABAASBBwCKAMaRyBJbmRpY2F0ZXMgaG93IG1hbnkgb2Yg
dGhlIGNvbXBhbmlvbnMgc2hvdWxkIGJlIGRpc3BsYXllZCB3aXRoIHRoZSBhZC4KCgwKBQQA
BAABEgMcBxkKSwoGBAAEAAIAEgMeBCgaPCBSZXF1aXJlZCBjb21wYW5pb25zIGFyZSBub3Qg
c3BlY2lmaWVkLiBUaGUgZGVmYXVsdCBpcyBBTEwuCgoOCgcEAAQAAgABEgMeBCMKDgoHBAAE
AAIAAhIDHiYnCj0KBgQABAACARIDIQQMGi4gQWxsIGNvbXBhbmlvbnMgYXJlIHJlcXVpcmVk
IHRvIGJlIGRpc3BsYXllZC4KCg4KBwQABAACAQESAyEEBwoOCgcEAAQAAgECEgMhCgsKQgoG
BAAEAAICEgMkBAwaMyBBdCBsZWFzdCBvbmUgb2YgY29tcGFuaW9ucyBuZWVkcyB0byBiZSBk
aXNwbGF5ZWQuCgoOCgcEAAQAAgIBEgMkBAcKDgoHBAAEAAICAhIDJAoLCjkKBgQABAACAxID
JwQNGiogQWxsIGNvbXBhbmlvbnMgYXJlIG9wdGlvbmFsIGZvciBkaXNwbGF5LgoKDgoHBAAE
AAIDARIDJwQICg4KBwQABAACAwISAycLDApUCgQEAAIAEgMrAi0aRyBJbmRpY2F0ZXMgaG93
IG1hbnkgb2YgdGhlIGNvbXBhbmlvbnMgc2hvdWxkIGJlIGRpc3BsYXllZCB3aXRoIHRoZSBh
ZC4KCgwKBQQAAgAGEgMrAhQKDAoFBAACAAESAysVKAoMCgUEAAIAAxIDKyssCiUKBAQAAgES
Ay4CJBoYIExpc3Qgb2YgY29tcGFuaW9uIGFkcy4KCgwKBQQAAgEEEgMuAgoKDAoFBAACAQYS
Ay4LFAoMCgUEAAIBARIDLhUfCgwKBQQAAgEDEgMuIiMKJwoCBAESBDIAWwEaGyBNZXRhZGF0
YSBmb3IgYSBjb21wYW5pb24uCgoKCgMEAQESAzIIEQo9CgQEAQgAEgQ0Aj0DGi8gQWQgcmVz
b3VyY2UgYXNzb2NpYXRlZCB3aXRoIHRoZSBjb21wYW5pb24gYWQuCgoMCgUEAQgAARIDNAgT
CkcKBAQBAgASAzYELRo6IFRoZSBJRnJhbWUgYWQgcmVzb3VyY2UgYXNzb2NpYXRlZCB3aXRo
IHRoZSBjb21wYW5pb24gYWQuCgoMCgUEAQIABhIDNgQUCgwKBQQBAgABEgM2FScKDAoFBAEC
AAMSAzYqLApHCgQEAQIBEgM5BC0aOiBUaGUgc3RhdGljIGFkIHJlc291cmNlIGFzc29jaWF0
ZWQgd2l0aCB0aGUgY29tcGFuaW9uIGFkLgoKDAoFBAECAQYSAzkEFAoMCgUEAQIBARIDORUn
CgwKBQQBAgEDEgM5KiwKRQoEBAECAhIDPAQpGjggVGhlIEhUTUwgYWQgcmVzb3VyY2UgYXNz
b2NpYXRlZCB3aXRoIHRoZSBjb21wYW5pb24gYWQuCgoMCgUEAQICBhIDPAQSCgwKBQQBAgIB
EgM8EyMKDAoFBAECAgMSAzwmKApPCgQEAQIDEgNAAhsaQiBUaGUgQVBJIG5lY2Vzc2FyeSB0
byBjb21tdW5pY2F0ZSB3aXRoIHRoZSBjcmVhdGl2ZSBpZiBhdmFpbGFibGUuCgoMCgUEAQID
BRIDQAIICgwKBQQBAgMBEgNACRYKDAoFBAECAwMSA0AZGgpQCgQEAQIEEgNDAhYaQyBUaGUg
cGl4ZWwgaGVpZ2h0IG9mIHRoZSBwbGFjZW1lbnQgc2xvdCBmb3IgdGhlIGludGVuZGVkIGNy
ZWF0aXZlLgoKDAoFBAECBAUSA0MCBwoMCgUEAQIEARIDQwgRCgwKBQQBAgQDEgNDFBUKTwoE
BAECBRIDRgIVGkIgVGhlIHBpeGVsIHdpZHRoIG9mIHRoZSBwbGFjZW1lbnQgc2xvdCBmb3Ig
dGhlIGludGVuZGVkIGNyZWF0aXZlLgoKDAoFBAECBQUSA0YCBwoMCgUEAQIFARIDRggQCgwK
BQQBAgUDEgNGExQKMAoEBAECBhIDSQIcGiMgVGhlIHBpeGVsIGhlaWdodCBvZiB0aGUgY3Jl
YXRpdmUuCgoMCgUEAQIGBRIDSQIHCgwKBQQBAgYBEgNJCBcKDAoFBAECBgMSA0kaGwpOCgQE
AQIHEgNMAh8aQSBUaGUgbWF4aW11bSBwaXhlbCBoZWlnaHQgb2YgdGhlIGNyZWF0aXZlIGlu
IGl0cyBleHBhbmRlZCBzdGF0ZS4KCgwKBQQBAgcFEgNMAgcKDAoFBAECBwESA0wIGgoMCgUE
AQIHAxIDTB0eCi8KBAQBAggSA08CGxoiIFRoZSBwaXhlbCB3aWR0aCBvZiB0aGUgY3JlYXRp
dmUuCgoMCgUEAQIIBRIDTwIHCgwKBQQBAggBEgNPCBYKDAoFBAECCAMSA08ZGgpNCgQEAQIJ
EgNSAh4aQCBUaGUgbWF4aW11bSBwaXhlbCB3aWR0aCBvZiB0aGUgY3JlYXRpdmUgaW4gaXRz
IGV4cGFuZGVkIHN0YXRlLgoKDAoFBAECCQUSA1ICBwoMCgUEAQIJARIDUggZCgwKBQQBAgkD
EgNSHB0KoAEKBAQBAgoSA1cCGBqSASBUaGUgSUQgdXNlZCB0byBpZGVudGlmeSB0aGUgZGVz
aXJlZCBwbGFjZW1lbnQgb24gYSBwdWJsaXNoZXIncyBwYWdlLgogVmFsdWVzIHRvIGJlIHVz
ZWQgc2hvdWxkIGJlIGRpc2N1c3NlZCBiZXR3ZWVuIHB1Ymxpc2hlcnMgYW5kCiBhZHZlcnRp
c2Vycy4KCgwKBQQBAgoFEgNXAggKDAoFBAECCgESA1cJEwoMCgUEAQIKAxIDVxYXCj0KBAQB
AgsSA1oCHBowIFRoZSBsaXN0IG9mIHRyYWNraW5nIGV2ZW50cyBmb3IgdGhlIGNvbXBhbmlv
bi4KCgwKBQQBAgsEEgNaAgoKDAoFBAECCwYSA1oLEAoMCgUEAQILARIDWhEXCgwKBQQBAgsD
EgNaGhsKLwoCBAISBF4AYQEaIyBNZXRhZGF0YSBmb3IgYW4gSFRNTCBhZCByZXNvdXJjZS4K
CgoKAwQCARIDXggWCjcKBAQCAgASA2ACGRoqIFRoZSBIVE1MIHRvIGRpc3BsYXkgZm9yIHRo
ZSBhZCByZXNvdXJjZS4KCgwKBQQCAgAFEgNgAggKDAoFBAICAAESA2AJFAoMCgUEAgIAAxID
YBcYCjEKAgQDEgRkAGcBGiUgTWV0YWRhdGEgZm9yIGFuIElGcmFtZSBhZCByZXNvdXJjZS4K
CgoKAwQDARIDZAgYCkcKBAQDAgASA2YCERo6IFVSSSBzb3VyY2UgZm9yIGFuIElGcmFtZSB0
byBkaXNwbGF5IGZvciB0aGUgYWQgcmVzb3VyY2UuCgoMCgUEAwIABRIDZgIICgwKBQQDAgAB
EgNmCQwKDAoFBAMCAAMSA2YPEAowCgIEBBIEagBwARokIE1ldGFkYXRhIGZvciBhIHN0YXRp
YyBhZCByZXNvdXJjZS4KCgoKAwQEARIDaggYCjoKBAQEAgASA2wCERotIFVSSSB0byB0aGUg
c3RhdGljIGZpbGUgZm9yIHRoZSBhZCByZXNvdXJjZS4KCgwKBQQEAgAFEgNsAggKDAoFBAQC
AAESA2wJDAoMCgUEBAIAAxIDbA8QCjoKBAQEAgESA28CGxotIERlc2NyaWJlcyB0aGUgTUlN
RSB0eXBlIG9mIHRoZSBhZCByZXNvdXJjZS4KCgwKBQQEAgEFEgNvAggKDAoFBAQCAQESA28J
FgoMCgUEBAIBAxIDbxkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds ===
    # Fields for CompanionAds
    # Field: display_requirement Type: 14 (.google.cloud.video.stitcher.v1.CompanionAds.DisplayRequirement)
    # Field: companions Type: 11 (.google.cloud.video.stitcher.v1.Companion)

# Enum: CompanionAds::DisplayRequirement
our $CompanionAds_DISPLAY_REQUIREMENT_UNSPECIFIED = 0;
our $CompanionAds_ALL = 1;
our $CompanionAds_ANY = 2;
our $CompanionAds_NONE = 3;

# === Message: Google::Cloud::Video::Stitcher::V1::Companions::Companion ===
    # Fields for Companion
    # Field: iframe_ad_resource Type: 11 (.google.cloud.video.stitcher.v1.IframeAdResource)
    # Field: static_ad_resource Type: 11 (.google.cloud.video.stitcher.v1.StaticAdResource)
    # Field: html_ad_resource Type: 11 (.google.cloud.video.stitcher.v1.HtmlAdResource)
    # Field: api_framework Type: 9 ()
    # Field: height_px Type: 5 ()
    # Field: width_px Type: 5 ()
    # Field: asset_height_px Type: 5 ()
    # Field: expanded_height_px Type: 5 ()
    # Field: asset_width_px Type: 5 ()
    # Field: expanded_width_px Type: 5 ()
    # Field: ad_slot_id Type: 9 ()
    # Field: events Type: 11 (.google.cloud.video.stitcher.v1.Event)

# === Message: Google::Cloud::Video::Stitcher::V1::Companions::HtmlAdResource ===
    # Fields for HtmlAdResource
    # Field: html_source Type: 9 ()

# === Message: Google::Cloud::Video::Stitcher::V1::Companions::IframeAdResource ===
    # Fields for IframeAdResource
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Video::Stitcher::V1::Companions::StaticAdResource ===
    # Fields for StaticAdResource
    # Field: uri Type: 9 ()
    # Field: creative_type Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Companions - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/companions.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::Companions;

    my $msg = Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds->new({
        display_requirement => $display_requirement,
        companions => $companions,
    });

    # Read or update a field
    my $val = $msg->display_requirement();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/companions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds

Metadata for companion ads.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_requirement() >> / C<< $msg->display_requirement($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::CompanionAds::DisplayRequirement>)

Indicates how many of the companions should be displayed with the ad.

=item * C<< $msg->companions() >> / C<< $msg->companions($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Companions::Companion>)

List of companion ads.

=back

=head3 Enum: CompanionAds::DisplayRequirement

=over 4

=item * C<DISPLAY_REQUIREMENT_UNSPECIFIED> => C<0>

=item * C<ALL> => C<1>

=item * C<ANY> => C<2>

=item * C<NONE> => C<3>

=back

=head2 Google::Cloud::Video::Stitcher::V1::Companions::Companion

Metadata for a companion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->iframe_ad_resource() >> / C<< $msg->iframe_ad_resource($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Companions::IframeAdResource>)

The IFrame ad resource associated with the companion ad.

=item * C<< $msg->static_ad_resource() >> / C<< $msg->static_ad_resource($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Companions::StaticAdResource>)

The static ad resource associated with the companion ad.

=item * C<< $msg->html_ad_resource() >> / C<< $msg->html_ad_resource($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Companions::HtmlAdResource>)

The HTML ad resource associated with the companion ad.

=item * C<< $msg->api_framework() >> / C<< $msg->api_framework($value) >>

Type: C<String>

The API necessary to communicate with the creative if available.

=item * C<< $msg->height_px() >> / C<< $msg->height_px($value) >>

Type: C<Int32>

The pixel height of the placement slot for the intended creative.

=item * C<< $msg->width_px() >> / C<< $msg->width_px($value) >>

Type: C<Int32>

The pixel width of the placement slot for the intended creative.

=item * C<< $msg->asset_height_px() >> / C<< $msg->asset_height_px($value) >>

Type: C<Int32>

The pixel height of the creative.

=item * C<< $msg->expanded_height_px() >> / C<< $msg->expanded_height_px($value) >>

Type: C<Int32>

The maximum pixel height of the creative in its expanded state.

=item * C<< $msg->asset_width_px() >> / C<< $msg->asset_width_px($value) >>

Type: C<Int32>

The pixel width of the creative.

=item * C<< $msg->expanded_width_px() >> / C<< $msg->expanded_width_px($value) >>

Type: C<Int32>

The maximum pixel width of the creative in its expanded state.

=item * C<< $msg->ad_slot_id() >> / C<< $msg->ad_slot_id($value) >>

Type: C<String>

The ID used to identify the desired placement on a publisher's page.
Values to be used should be discussed between publishers and
advertisers.

=item * C<< $msg->events() >> / C<< $msg->events($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Events::Event>)

The list of tracking events for the companion.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Companions::HtmlAdResource

Metadata for an HTML ad resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->html_source() >> / C<< $msg->html_source($value) >>

Type: C<String>

The HTML to display for the ad resource.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Companions::IframeAdResource

Metadata for an IFrame ad resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

URI source for an IFrame to display for the ad resource.

=back

=head2 Google::Cloud::Video::Stitcher::V1::Companions::StaticAdResource

Metadata for a static ad resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

URI to the static file for the ad resource.

=item * C<< $msg->creative_type() >> / C<< $msg->creative_type($value) >>

Type: C<String>

Describes the MIME type of the ad resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::Companions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
