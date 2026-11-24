package Google::Cloud::Video::Stitcher::V1::CdnKeys;

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
Ci1nb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvY2RuX2tleXMucHJvdG8SHmdvb2ds
ZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKuAwoGQ2RuS2V5ElQKDmdvb2dsZV9j
ZG5fa2V5GAUgASgLMiwuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxLkdvb2dsZUNk
bktleUgAUgxnb29nbGVDZG5LZXkSVAoOYWthbWFpX2Nkbl9rZXkYBiABKAsyLC5nb29nbGUu
Y2xvdWQudmlkZW8uc3RpdGNoZXIudjEuQWthbWFpQ2RuS2V5SABSDGFrYW1haUNkbktleRJR
Cg1tZWRpYV9jZG5fa2V5GAggASgLMisuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYx
Lk1lZGlhQ2RuS2V5SABSC21lZGlhQ2RuS2V5EhIKBG5hbWUYASABKAlSBG5hbWUSGgoIaG9z
dG5hbWUYBCABKAlSCGhvc3RuYW1lOmPqQWAKI3ZpZGVvc3RpdGNoZXIuZ29vZ2xlYXBpcy5j
b20vQ2RuS2V5Ejlwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2Ru
S2V5cy97Y2RuX2tleX1CEAoOY2RuX2tleV9jb25maWciTwoMR29vZ2xlQ2RuS2V5EiQKC3By
aXZhdGVfa2V5GAEgASgMQgPgQQRSCnByaXZhdGVLZXkSGQoIa2V5X25hbWUYAiABKAlSB2tl
eU5hbWUiMAoMQWthbWFpQ2RuS2V5EiAKCXRva2VuX2tleRgBIAEoDEID4EEEUgh0b2tlbktl
eSLsAQoLTWVkaWFDZG5LZXkSJAoLcHJpdmF0ZV9rZXkYASABKAxCA+BBBFIKcHJpdmF0ZUtl
eRIZCghrZXlfbmFtZRgCIAEoCVIHa2V5TmFtZRJfCgx0b2tlbl9jb25maWcYAyABKAsyNy5n
b29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuTWVkaWFDZG5LZXkuVG9rZW5Db25maWdC
A+BBAVILdG9rZW5Db25maWcaOwoLVG9rZW5Db25maWcSLAoPcXVlcnlfcGFyYW1ldGVyGAEg
ASgJQgPgQQFSDnF1ZXJ5UGFyYW1ldGVyQnQKImNvbS5nb29nbGUuY2xvdWQudmlkZW8uc3Rp
dGNoZXIudjFCDENkbktleXNQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL3ZpZGVvL3N0
aXRjaGVyL2FwaXYxL3N0aXRjaGVycGI7c3RpdGNoZXJwYkrAGAoGEgQOAF8BCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwES
AxMAIwoICgEIEgMVAFUKCQoCCAsSAxUAVQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
AC0KCQoCCAgSAxcALQoICgEIEgMYADsKCQoCCAESAxgAOwqbAQoCBAASBB0ANgEajgEgQ29u
ZmlndXJhdGlvbiBmb3IgYSBDRE4ga2V5LiBVc2VkIGJ5IHRoZSBWaWRlbyBTdGl0Y2hlcgog
dG8gc2lnbiBVUklzIGZvciBmZXRjaGluZyB2aWRlbyBtYW5pZmVzdHMgYW5kIHNpZ25pbmcK
IG1lZGlhIHNlZ21lbnRzIGZvciBwbGF5YmFjay4KCgoKAwQAARIDHQgOCgsKAwQABxIEHgIh
BAoNCgUEAAedCBIEHgIhBAo6CgQEAAgAEgQkAi0DGiwgQ29uZmlndXJhdGlvbiBhc3NvY2lh
dGVkIHdpdGggdGhlIENETiBrZXkuCgoMCgUEAAgAARIDJAgWCjwKBAQAAgASAyYEJBovIFRo
ZSBjb25maWd1cmF0aW9uIGZvciBhIEdvb2dsZSBDbG91ZCBDRE4ga2V5LgoKDAoFBAACAAYS
AyYEEAoMCgUEAAIAARIDJhEfCgwKBQQAAgADEgMmIiMKNwoEBAACARIDKQQkGiogVGhlIGNv
bmZpZ3VyYXRpb24gZm9yIGFuIEFrYW1haSBDRE4ga2V5LgoKDAoFBAACAQYSAykEEAoMCgUE
AAIBARIDKREfCgwKBQQAAgEDEgMpIiMKNQoEBAACAhIDLAQiGiggVGhlIGNvbmZpZ3VyYXRp
b24gZm9yIGEgTWVkaWEgQ0ROIGtleS4KCgwKBQQAAgIGEgMsBA8KDAoFBAACAgESAywQHQoM
CgUEAAICAxIDLCAhCqcBCgQEAAIDEgMyAhIamQEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IENETiBrZXksIGluIHRoZSBmb3JtIG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2NkbktleXMve2lkfWAuCiBUaGUgbmFtZSBpcyBpZ25vcmVkIHdoZW4g
Y3JlYXRpbmcgYSBDRE4ga2V5LgoKDAoFBAACAwUSAzICCAoMCgUEAAIDARIDMgkNCgwKBQQA
AgMDEgMyEBEKMAoEBAACBBIDNQIWGiMgVGhlIGhvc3RuYW1lIHRoaXMga2V5IGFwcGxpZXMg
dG8uCgoMCgUEAAIEBRIDNQIICgwKBQQAAgQBEgM1CREKDAoFBAACBAMSAzUUFQo3CgIEARIE
OQA/ARorIENvbmZpZ3VyYXRpb24gZm9yIGEgR29vZ2xlIENsb3VkIENETiBrZXkuCgoKCgME
AQESAzkIFApACgQEAQIAEgM7AkMaMyBJbnB1dCBvbmx5LiBTZWNyZXQgZm9yIHRoaXMgR29v
Z2xlIENsb3VkIENETiBrZXkuCgoMCgUEAQIABRIDOwIHCgwKBQQBAgABEgM7CBMKDAoFBAEC
AAMSAzsWFwoMCgUEAQIACBIDOxhCCg8KCAQBAgAInAgAEgM7GUEKOwoEBAECARIDPgIWGi4g
VGhlIHB1YmxpYyBuYW1lIG9mIHRoZSBHb29nbGUgQ2xvdWQgQ0ROIGtleS4KCgwKBQQBAgEF
EgM+AggKDAoFBAECAQESAz4JEQoMCgUEAQIBAxIDPhQVCjIKAgQCEgRCAEUBGiYgQ29uZmln
dXJhdGlvbiBmb3IgYW4gQWthbWFpIENETiBrZXkuCgoKCgMEAgESA0IIFApLCgQEAgIAEgNE
AkEaPiBJbnB1dCBvbmx5LiBUb2tlbiBrZXkgZm9yIHRoZSBBa2FtYWkgQ0ROIGVkZ2UgY29u
ZmlndXJhdGlvbi4KCgwKBQQCAgAFEgNEAgcKDAoFBAICAAESA0QIEQoMCgUEAgIAAxIDRBQV
CgwKBQQCAgAIEgNEFkAKDwoIBAICAAicCAASA0QXPwowCgIEAxIESABfARokIENvbmZpZ3Vy
YXRpb24gZm9yIGEgTWVkaWEgQ0ROIGtleS4KCgoKAwQDARIDSAgTCjQKBAQDAwASBEoCVAMa
JiBDb25maWd1cmF0aW9uIGZvciBhIE1lZGlhIENETiB0b2tlbi4KCgwKBQQDAwABEgNKChUK
0AIKBgQDAwACABIDUwRIGsACIE9wdGlvbmFsLiBUaGUgcXVlcnkgcGFyYW1ldGVyIGluIHdo
aWNoIHRvIGZpbmQgdGhlIHRva2VuLgoKIFRoZSBuYW1lIG11c3QgYmUgMS02NCBjaGFyYWN0
ZXJzIGxvbmcgYW5kIG1hdGNoCiB0aGUgcmVndWxhciBleHByZXNzaW9uIGBbYS16QS1aXShb
YS16QS1aMC05Xy1dKSpgIHdoaWNoIG1lYW5zIHRoZQogZmlyc3QgY2hhcmFjdGVyIG11c3Qg
YmUgYSBsZXR0ZXIsIGFuZCBhbGwgZm9sbG93aW5nIGNoYXJhY3RlcnMKIG11c3QgYmUgYSBk
YXNoLCB1bmRlcnNjb3JlLCBsZXR0ZXIgb3IgZGlnaXQuCgogRGVmYXVsdHMgdG8gYGVkZ2Ut
Y2FjaGUtdG9rZW5gLgoKDgoHBAMDAAIABRIDUwQKCg4KBwQDAwACAAESA1MLGgoOCgcEAwMA
AgADEgNTHR4KDgoHBAMDAAIACBIDUx9HChEKCgQDAwACAAicCAASA1MgRgpOCgQEAwIAEgNX
AkMaQSBJbnB1dCBvbmx5LiA2NC1ieXRlIGVkMjU1MTkgcHJpdmF0ZSBrZXkgZm9yIHRoaXMg
TWVkaWEgQ0ROIGtleS4KCgwKBQQDAgAFEgNXAgcKDAoFBAMCAAESA1cIEwoMCgUEAwIAAxID
VxYXCgwKBQQDAgAIEgNXGEIKDwoIBAMCAAicCAASA1cZQQo0CgQEAwIBEgNaAhYaJyBUaGUg
a2V5c2V0IG5hbWUgb2YgdGhlIE1lZGlhIENETiBrZXkuCgoMCgUEAwIBBRIDWgIICgwKBQQD
AgEBEgNaCREKDAoFBAMCAQMSA1oUFQqfAQoEBAMCAhIDXgJIGpEBIE9wdGlvbmFsLiBJZiBz
ZXQsIHRoZSBVUkwgd2lsbCBiZSBzaWduZWQgdXNpbmcgdGhlIE1lZGlhIENETiB0b2tlbi4K
IE90aGVyd2lzZSwgdGhlIFVSTCB3b3VsZCBiZSBzaWduZWQgdXNpbmcgdGhlIHN0YW5kYXJk
IE1lZGlhIENETiBzaWduYXR1cmUuCgoMCgUEAwICBhIDXgINCgwKBQQDAgIBEgNeDhoKDAoF
BAMCAgMSA14dHgoMCgUEAwICCBIDXh9HCg8KCAQDAgIInAgAEgNeIEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey ===
    # Fields for CdnKey
    # Field: google_cdn_key Type: 11 (.google.cloud.video.stitcher.v1.GoogleCdnKey)
    # Field: akamai_cdn_key Type: 11 (.google.cloud.video.stitcher.v1.AkamaiCdnKey)
    # Field: media_cdn_key Type: 11 (.google.cloud.video.stitcher.v1.MediaCdnKey)
    # Field: name Type: 9 ()
    # Field: hostname Type: 9 ()

# === Message: Google::Cloud::Video::Stitcher::V1::CdnKeys::GoogleCdnKey ===
    # Fields for GoogleCdnKey
    # Field: private_key Type: 12 ()
    # Field: key_name Type: 9 ()

# === Message: Google::Cloud::Video::Stitcher::V1::CdnKeys::AkamaiCdnKey ===
    # Fields for AkamaiCdnKey
    # Field: token_key Type: 12 ()

# === Message: Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey ===
    # Fields for MediaCdnKey
    # Field: private_key Type: 12 ()
    # Field: key_name Type: 9 ()
    # Field: token_config Type: 11 (.google.cloud.video.stitcher.v1.MediaCdnKey.TokenConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::CdnKeys - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/cdn_keys.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::CdnKeys;

    my $msg = Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey->new({
        google_cdn_key => $google_cdn_key,
        akamai_cdn_key => $akamai_cdn_key,
        media_cdn_key => $media_cdn_key,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->google_cdn_key();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/cdn_keys.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey

Configuration for a CDN key. Used by the Video Stitcher
to sign URIs for fetching video manifests and signing
media segments for playback.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->google_cdn_key() >> / C<< $msg->google_cdn_key($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::CdnKeys::GoogleCdnKey>)

The configuration for a Google Cloud CDN key.

=item * C<< $msg->akamai_cdn_key() >> / C<< $msg->akamai_cdn_key($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::CdnKeys::AkamaiCdnKey>)

The configuration for an Akamai CDN key.

=item * C<< $msg->media_cdn_key() >> / C<< $msg->media_cdn_key($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey>)

The configuration for a Media CDN key.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the CDN key, in the form of
`projects/{project}/locations/{location}/cdnKeys/{id}`.
The name is ignored when creating a CDN key.

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

The hostname this key applies to.

=back

=head2 Google::Cloud::Video::Stitcher::V1::CdnKeys::GoogleCdnKey

Configuration for a Google Cloud CDN key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->private_key() >> / C<< $msg->private_key($value) >>

Type: C<Bytes>

Input only. Secret for this Google Cloud CDN key.

=item * C<< $msg->key_name() >> / C<< $msg->key_name($value) >>

Type: C<String>

The public name of the Google Cloud CDN key.

=back

=head2 Google::Cloud::Video::Stitcher::V1::CdnKeys::AkamaiCdnKey

Configuration for an Akamai CDN key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->token_key() >> / C<< $msg->token_key($value) >>

Type: C<Bytes>

Input only. Token key for the Akamai CDN edge configuration.

=back

=head2 Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey

Configuration for a Media CDN key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->private_key() >> / C<< $msg->private_key($value) >>

Type: C<Bytes>

Input only. 64-byte ed25519 private key for this Media CDN key.

=item * C<< $msg->key_name() >> / C<< $msg->key_name($value) >>

Type: C<String>

The keyset name of the Media CDN key.

=item * C<< $msg->token_config() >> / C<< $msg->token_config($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey::TokenConfig>)

Optional. If set, the URL will be signed using the Media CDN token.
Otherwise, the URL would be signed using the standard Media CDN signature.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::CdnKeys::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
