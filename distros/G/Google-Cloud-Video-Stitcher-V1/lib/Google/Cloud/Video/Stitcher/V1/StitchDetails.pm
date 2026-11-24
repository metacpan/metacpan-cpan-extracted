package Google::Cloud::Video::Stitcher::V1::StitchDetails;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvc3RpdGNoX2RldGFpbHMucHJvdG8S
Hmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVm
L2R1cmF0aW9uLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIp4CCg9Wb2RT
dGl0Y2hEZXRhaWwSEgoEbmFtZRgBIAEoCVIEbmFtZRJaChFhZF9zdGl0Y2hfZGV0YWlscxgD
IAMoCzIuLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5BZFN0aXRjaERldGFpbFIP
YWRTdGl0Y2hEZXRhaWxzOpoB6kGWAQosdmlkZW9zdGl0Y2hlci5nb29nbGVhcGlzLmNvbS9W
b2RTdGl0Y2hEZXRhaWwSZnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS92b2RTZXNzaW9ucy97dm9kX3Nlc3Npb259L3ZvZFN0aXRjaERldGFpbHMve3ZvZF9zdGl0
Y2hfZGV0YWlsfSLjAgoOQWRTdGl0Y2hEZXRhaWwSIwoLYWRfYnJlYWtfaWQYASABKAlCA+BB
AlIJYWRCcmVha0lkEhgKBWFkX2lkGAIgASgJQgPgQQJSBGFkSWQSRAoOYWRfdGltZV9vZmZz
ZXQYAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBAlIMYWRUaW1lT2Zmc2V0
EiQKC3NraXBfcmVhc29uGAQgASgJQgPgQQFSCnNraXBSZWFzb24SVAoFbWVkaWEYBSADKAsy
OS5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuQWRTdGl0Y2hEZXRhaWwuTWVkaWFF
bnRyeUID4EEBUgVtZWRpYRpQCgpNZWRpYUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EiwKBXZh
bHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZToCOAFCegoiY29tLmdv
b2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MUISU3RpdGNoRGV0YWlsc1Byb3RvUAFaPmNs
b3VkLmdvb2dsZS5jb20vZ28vdmlkZW8vc3RpdGNoZXIvYXBpdjEvc3RpdGNoZXJwYjtzdGl0
Y2hlcnBiSo0QCgYSBA4APwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACgKCQoCAwMSAxUAJgoI
CgEIEgMXAFUKCQoCCAsSAxcAVQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADMKCQoC
CAgSAxkAMwoICgEIEgMaADsKCQoCCAESAxoAOwqxAQoCBAASBB8AKwEapAEgSW5mb3JtYXRp
b24gcmVsYXRlZCB0byB0aGUgaW50ZXJzdGl0aWFsIG9mIGEgVk9EIHNlc3Npb24uIFRoaXMg
cmVzb3VyY2UgaXMKIG9ubHkgYXZhaWxhYmxlIGZvciBWT0Qgc2Vzc2lvbnMgdGhhdCBkbyBu
b3QgaW1wbGVtZW50IEdvb2dsZSBBZCBNYW5hZ2VyIGFkCiBpbnNlcnRpb24uCgoKCgMEAAES
Ax8IFwoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKuQEKBAQAAgASAycCEhqrASBUaGUg
bmFtZSBvZiB0aGUgc3RpdGNoIGRldGFpbCBpbiB0aGUgc3BlY2lmaWVkIFZPRCBzZXNzaW9u
LCBpbiB0aGUgZm9ybSBvZgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS92b2RTZXNzaW9ucy97dm9kX3Nlc3Npb25faWR9L3ZvZFN0aXRjaERldGFpbHMve2lk
fWAuCgoMCgUEAAIABRIDJwIICgwKBQQAAgABEgMnCQ0KDAoFBAACAAMSAycQEQpLCgQEAAIB
EgMqAjAaPiBBIGxpc3Qgb2YgYWQgcHJvY2Vzc2luZyBkZXRhaWxzIGZvciB0aGUgZmV0Y2hl
ZCBhZCBwbGF5bGlzdC4KCgwKBQQAAgEEEgMqAgoKDAoFBAACAQYSAyoLGQoMCgUEAAIBARID
KhorCgwKBQQAAgEDEgMqLi8KKQoCBAESBC4APwEaHSBNZXRhZGF0YSBmb3IgYSBzdGl0Y2hl
ZCBhZC4KCgoKAwQBARIDLggWCj0KBAQBAgASAzACQhowIFJlcXVpcmVkLiBUaGUgYWQgYnJl
YWsgSUQgb2YgdGhlIHByb2Nlc3NlZCBhZC4KCgwKBQQBAgAFEgMwAggKDAoFBAECAAESAzAJ
FAoMCgUEAQIAAxIDMBcYCgwKBQQBAgAIEgMwGUEKDwoIBAECAAicCAASAzAaQAo3CgQEAQIB
EgMzAjwaKiBSZXF1aXJlZC4gVGhlIGFkIElEIG9mIHRoZSBwcm9jZXNzZWQgYWQuCgoMCgUE
AQIBBRIDMwIICgwKBQQBAgEBEgMzCQ4KDAoFBAECAQMSAzMREgoMCgUEAQIBCBIDMxM7Cg8K
CAQBAgEInAgAEgMzFDoKPgoEBAECAhIENgI3LxowIFJlcXVpcmVkLiBUaGUgdGltZSBvZmZz
ZXQgb2YgdGhlIHByb2Nlc3NlZCBhZC4KCgwKBQQBAgIGEgM2AhoKDAoFBAECAgESAzYbKQoM
CgUEAQICAxIDNiwtCgwKBQQBAgIIEgM3Bi4KDwoIBAECAgicCAASAzcHLQpKCgQEAQIDEgM6
AkIaPSBPcHRpb25hbC4gSW5kaWNhdGVzIHRoZSByZWFzb24gd2h5IHRoZSBhZCBoYXMgYmVl
biBza2lwcGVkLgoKDAoFBAECAwUSAzoCCAoMCgUEAQIDARIDOgkUCgwKBQQBAgMDEgM6FxgK
DAoFBAECAwgSAzoZQQoPCggEAQIDCJwIABIDOhpACksKBAQBAgQSBD0CPi8aPSBPcHRpb25h
bC4gVGhlIG1ldGFkYXRhIG9mIHRoZSBjaG9zZW4gbWVkaWEgZmlsZSBmb3IgdGhlIGFkLgoK
DAoFBAECBAYSAz0CJAoMCgUEAQIEARIDPSUqCgwKBQQBAgQDEgM9LS4KDAoFBAECBAgSAz4G
LgoPCggEAQIECJwIABIDPgctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail ===
    # Fields for VodStitchDetail
    # Field: name Type: 9 ()
    # Field: ad_stitch_details Type: 11 (.google.cloud.video.stitcher.v1.AdStitchDetail)

# === Message: Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail ===
    # Fields for AdStitchDetail
    # Field: ad_break_id Type: 9 ()
    # Field: ad_id Type: 9 ()
    # Field: ad_time_offset Type: 11 (.google.protobuf.Duration)
    # Field: skip_reason Type: 9 ()
    # Field: media Type: 11 (.google.cloud.video.stitcher.v1.AdStitchDetail.MediaEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::StitchDetails - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/stitch_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::StitchDetails;

    my $msg = Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail->new({
        name => $name,
        ad_stitch_details => $ad_stitch_details,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/stitch_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail

Information related to the interstitial of a VOD session. This resource is
only available for VOD sessions that do not implement Google Ad Manager ad
insertion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the stitch detail in the specified VOD session, in the form of
`projects/{project}/locations/{location}/vodSessions/{vod_session_id}/vodStitchDetails/{id}`.

=item * C<< $msg->ad_stitch_details() >> / C<< $msg->ad_stitch_details($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail>)

A list of ad processing details for the fetched ad playlist.

=back

=head2 Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail

Metadata for a stitched ad.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ad_break_id() >> / C<< $msg->ad_break_id($value) >>

Type: C<String>

Required. The ad break ID of the processed ad.

=item * C<< $msg->ad_id() >> / C<< $msg->ad_id($value) >>

Type: C<String>

Required. The ad ID of the processed ad.

=item * C<< $msg->ad_time_offset() >> / C<< $msg->ad_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The time offset of the processed ad.

=item * C<< $msg->skip_reason() >> / C<< $msg->skip_reason($value) >>

Type: C<String>

Optional. Indicates the reason why the ad has been skipped.

=item * C<< $msg->media() >> / C<< $msg->media($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail::MediaEntry>)

Optional. The metadata of the chosen media file for the ad.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::StitchDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
