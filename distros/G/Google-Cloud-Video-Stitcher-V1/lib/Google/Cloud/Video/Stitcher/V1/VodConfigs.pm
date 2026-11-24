package Google::Cloud::Video::Stitcher::V1::VodConfigs;

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
    eval { require Google::Cloud::Video::Stitcher::V1::FetchOptions };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvdm9kX2NvbmZpZ3MucHJvdG8SHmdv
b2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoyZ29vZ2xlL2Nsb3VkL3ZpZGVv
L3N0aXRjaGVyL3YxL2ZldGNoX29wdGlvbnMucHJvdG8ipQQKCVZvZENvbmZpZxIXCgRuYW1l
GAEgASgJQgPgQQNSBG5hbWUSIgoKc291cmNlX3VyaRgCIAEoCUID4EECUglzb3VyY2VVcmkS
IQoKYWRfdGFnX3VyaRgDIAEoCUID4EECUghhZFRhZ1VyaRJXCg5nYW1fdm9kX2NvbmZpZxgE
IAEoCzIsLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5HYW1Wb2RDb25maWdCA+BB
AVIMZ2FtVm9kQ29uZmlnEkoKBXN0YXRlGAUgASgOMi8uZ29vZ2xlLmNsb3VkLnZpZGVvLnN0
aXRjaGVyLnYxLlZvZENvbmZpZy5TdGF0ZUID4EEDUgVzdGF0ZRJeChRzb3VyY2VfZmV0Y2hf
b3B0aW9ucxgIIAEoCzIsLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5GZXRjaE9w
dGlvbnNSEnNvdXJjZUZldGNoT3B0aW9ucyJFCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEgwKCENSRUFUSU5HEAESCQoFUkVBRFkQAhIMCghERUxFVElORxADOmzqQWkKJnZpZGVv
c3RpdGNoZXIuZ29vZ2xlYXBpcy5jb20vVm9kQ29uZmlnEj9wcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vdm9kQ29uZmlncy97dm9kX2NvbmZpZ30iNgoMR2FtVm9k
Q29uZmlnEiYKDG5ldHdvcmtfY29kZRgBIAEoCUID4EECUgtuZXR3b3JrQ29kZUJ3CiJjb20u
Z29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVyLnYxQg9Wb2RDb25maWdzUHJvdG9QAVo+Y2xv
dWQuZ29vZ2xlLmNvbS9nby92aWRlby9zdGl0Y2hlci9hcGl2MS9zdGl0Y2hlcnBiO3N0aXRj
aGVycGJK5REKBhIEDgBJAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAPAoICgEIEgMWAFUKCQoC
CAsSAxYAVQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoCCAgSAxgAMAoICgEI
EgMZADsKCQoCCAESAxkAOwo0CgIEABIEHABDARooIE1ldGFkYXRhIHVzZWQgdG8gcmVnaXN0
ZXIgVk9EIGNvbmZpZ3MuCgoKCgMEAAESAxwIEQoLCgMEAAcSBB0CIAQKDQoFBAAHnQgSBB0C
IAQKKAoEBAAEABIEIwIvAxoaIFN0YXRlIG9mIHRoZSBWT0QgY29uZmlnLgoKDAoFBAAEAAES
AyMHDAooCgYEAAQAAgASAyUEGhoZIFN0YXRlIGlzIG5vdCBzcGVjaWZpZWQuCgoOCgcEAAQA
AgABEgMlBBUKDgoHBAAEAAIAAhIDJRgZCi0KBgQABAACARIDKAQRGh4gVk9EIGNvbmZpZyBp
cyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDKAQMCg4KBwQABAACAQISAygPEAotCgYE
AAQAAgISAysEDhoeIFZPRCBjb25maWcgaXMgcmVhZHkgZm9yIHVzZS4KCg4KBwQABAACAgES
AysECQoOCgcEAAQAAgICEgMrDA0KNgoGBAAEAAIDEgMuBBEaJyBWT0QgY29uZmlnIGlzIHF1
ZXVlZCB1cCBmb3IgZGVsZXRpb24uCgoOCgcEAAQAAgMBEgMuBAwKDgoHBAAEAAIDAhIDLg8Q
CosBCgQEAAIAEgMzAj4afiBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IFZPRCBjb25maWcsIGluIHRoZSBmb3JtIG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L3ZvZENvbmZpZ3Mve2lkfWAuCgoMCgUEAAIABRIDMwIICgwKBQQA
AgABEgMzCQ0KDAoFBAACAAMSAzMQEQoMCgUEAAIACBIDMxI9Cg8KCAQAAgAInAgAEgMzEzwK
QAoEBAACARIDNgJBGjMgUmVxdWlyZWQuIFNvdXJjZSBVUkkgZm9yIHRoZSBWT0Qgc3RyZWFt
IG1hbmlmZXN0LgoKDAoFBAACAQUSAzYCCAoMCgUEAAIBARIDNgkTCgwKBQQAAgEDEgM2FhcK
DAoFBAACAQgSAzYYQAoPCggEAAIBCJwIABIDNhk/CkwKBAQAAgISAzkCQRo/IFJlcXVpcmVk
LiBUaGUgZGVmYXVsdCBhZCB0YWcgYXNzb2NpYXRlZCB3aXRoIHRoaXMgVk9EIGNvbmZpZy4K
CgwKBQQAAgIFEgM5AggKDAoFBAACAgESAzkJEwoMCgUEAAICAxIDORYXCgwKBQQAAgIIEgM5
GEAKDwoIBAACAgicCAASAzkZPwo6CgQEAAIDEgM8AksaLSBPcHRpb25hbC4gR29vZ2xlIEFk
IE1hbmFnZXIgKEdBTSkgbWV0YWRhdGEuCgoMCgUEAAIDBhIDPAIOCgwKBQQAAgMBEgM8Dx0K
DAoFBAACAwMSAzwgIQoMCgUEAAIDCBIDPCJKCg8KCAQAAgMInAgAEgM8I0kKNAoEBAACBBID
PwI+GicgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBWT0QgY29uZmlnLgoKDAoFBAACBAYS
Az8CBwoMCgUEAAIEARIDPwgNCgwKBQQAAgQDEgM/EBEKDAoFBAACBAgSAz8SPQoPCggEAAIE
CJwIABIDPxM8CkIKBAQAAgUSA0ICKBo1IE9wdGlvbnMgZm9yIGZldGNoaW5nIHNvdXJjZSBt
YW5pZmVzdHMgYW5kIHNlZ21lbnRzLgoKDAoFBAACBQYSA0ICDgoMCgUEAAIFARIDQg8jCgwK
BQQAAgUDEgNCJicKMwoCBAESBEYASQEaJyBNZXRhZGF0YSB1c2VkIGZvciBHQU0gYWQgZGVj
aXNpb25pbmcuCgoKCgMEAQESA0YIFApSCgQEAQIAEgNIAkMaRSBSZXF1aXJlZC4gQWQgTWFu
YWdlciBuZXR3b3JrIGNvZGUgdG8gYXNzb2NpYXRlIHdpdGggdGhlIFZPRCBjb25maWcuCgoM
CgUEAQIABRIDSAIICgwKBQQBAgABEgNICRUKDAoFBAECAAMSA0gYGQoMCgUEAQIACBIDSBpC
Cg8KCAQBAgAInAgAEgNIG0FiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig ===
    # Fields for VodConfig
    # Field: name Type: 9 ()
    # Field: source_uri Type: 9 ()
    # Field: ad_tag_uri Type: 9 ()
    # Field: gam_vod_config Type: 11 (.google.cloud.video.stitcher.v1.GamVodConfig)
    # Field: state Type: 14 (.google.cloud.video.stitcher.v1.VodConfig.State)
    # Field: source_fetch_options Type: 11 (.google.cloud.video.stitcher.v1.FetchOptions)

# Enum: VodConfig::State
our $VodConfig_STATE_UNSPECIFIED = 0;
our $VodConfig_CREATING = 1;
our $VodConfig_READY = 2;
our $VodConfig_DELETING = 3;

# === Message: Google::Cloud::Video::Stitcher::V1::VodConfigs::GamVodConfig ===
    # Fields for GamVodConfig
    # Field: network_code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::VodConfigs - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/vod_configs.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::VodConfigs;

    my $msg = Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig->new({
        name => $name,
        source_uri => $source_uri,
        ad_tag_uri => $ad_tag_uri,
        gam_vod_config => $gam_vod_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/vod_configs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig

Metadata used to register VOD configs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the VOD config, in the form of
`projects/{project}/locations/{location}/vodConfigs/{id}`.

=item * C<< $msg->source_uri() >> / C<< $msg->source_uri($value) >>

Type: C<String>

Required. Source URI for the VOD stream manifest.

=item * C<< $msg->ad_tag_uri() >> / C<< $msg->ad_tag_uri($value) >>

Type: C<String>

Required. The default ad tag associated with this VOD config.

=item * C<< $msg->gam_vod_config() >> / C<< $msg->gam_vod_config($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::VodConfigs::GamVodConfig>)

Optional. Google Ad Manager (GAM) metadata.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Video::Stitcher::V1::VodConfig::State>)

Output only. State of the VOD config.

=item * C<< $msg->source_fetch_options() >> / C<< $msg->source_fetch_options($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions>)

Options for fetching source manifests and segments.

=back

=head3 Enum: VodConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=back

=head2 Google::Cloud::Video::Stitcher::V1::VodConfigs::GamVodConfig

Metadata used for GAM ad decisioning.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network_code() >> / C<< $msg->network_code($value) >>

Type: C<String>

Required. Ad Manager network code to associate with the VOD config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::VodConfigs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
