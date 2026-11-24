package Google::Cloud::Video::Stitcher::V1::AdTagDetails;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvYWRfdGFnX2RldGFpbHMucHJvdG8S
Hmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGhxnb29nbGUvcHJvdG9idWYv
c3RydWN0LnByb3RvIpECCg9MaXZlQWRUYWdEZXRhaWwSEgoEbmFtZRgBIAEoCVIEbmFtZRJK
CgthZF9yZXF1ZXN0cxgCIAMoCzIpLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5B
ZFJlcXVlc3RSCmFkUmVxdWVzdHM6nQHqQZkBCix2aWRlb3N0aXRjaGVyLmdvb2dsZWFwaXMu
Y29tL0xpdmVBZFRhZ0RldGFpbBJpcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2xpdmVTZXNzaW9ucy97bGl2ZV9zZXNzaW9ufS9saXZlQWRUYWdEZXRhaWxzL3ts
aXZlX2FkX3RhZ19kZXRhaWx9IosCCg5Wb2RBZFRhZ0RldGFpbBISCgRuYW1lGAEgASgJUgRu
YW1lEkoKC2FkX3JlcXVlc3RzGAIgAygLMikuZ29vZ2xlLmNsb3VkLnZpZGVvLnN0aXRjaGVy
LnYxLkFkUmVxdWVzdFIKYWRSZXF1ZXN0czqYAepBlAEKK3ZpZGVvc3RpdGNoZXIuZ29vZ2xl
YXBpcy5jb20vVm9kQWRUYWdEZXRhaWwSZXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS92b2RTZXNzaW9ucy97dm9kX3Nlc3Npb259L3ZvZEFkVGFnRGV0YWlscy97
dm9kX2FkX3RhZ19kZXRhaWx9ItgBCglBZFJlcXVlc3QSEAoDdXJpGAEgASgJUgN1cmkSWgoQ
cmVxdWVzdF9tZXRhZGF0YRgCIAEoCzIvLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52
MS5SZXF1ZXN0TWV0YWRhdGFSD3JlcXVlc3RNZXRhZGF0YRJdChFyZXNwb25zZV9tZXRhZGF0
YRgDIAEoCzIwLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0Y2hlci52MS5SZXNwb25zZU1ldGFk
YXRhUhByZXNwb25zZU1ldGFkYXRhIkQKD1JlcXVlc3RNZXRhZGF0YRIxCgdoZWFkZXJzGAEg
ASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIHaGVhZGVycyLmAQoQUmVzcG9uc2VNZXRh
ZGF0YRIUCgVlcnJvchgBIAEoCVIFZXJyb3ISMQoHaGVhZGVycxgCIAEoCzIXLmdvb2dsZS5w
cm90b2J1Zi5TdHJ1Y3RSB2hlYWRlcnMSHwoLc3RhdHVzX2NvZGUYAyABKAlSCnN0YXR1c0Nv
ZGUSHQoKc2l6ZV9ieXRlcxgEIAEoBVIJc2l6ZUJ5dGVzEjUKCGR1cmF0aW9uGAUgASgLMhku
Z29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJhdGlvbhISCgRib2R5GAYgASgJUgRib2R5
QnkKImNvbS5nb29nbGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjFCEUFkVGFnRGV0YWlsc1By
b3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vdmlkZW8vc3RpdGNoZXIvYXBpdjEvc3RpdGNo
ZXJwYjtzdGl0Y2hlcnBiSusWCgYSBA4AYgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIwoJCgIDARIDEwAoCgkKAgMCEgMUACYKCAoB
CBIDFgBVCgkKAggLEgMWAFUKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAyCgkKAggI
EgMYADIKCAoBCBIDGQA7CgkKAggBEgMZADsKqwEKAgQAEgQeACoBGp4BIEluZm9ybWF0aW9u
IHJlbGF0ZWQgdG8gdGhlIGRldGFpbHMgZm9yIG9uZSBhZCB0YWcuIFRoaXMgcmVzb3VyY2Ug
aXMgb25seQogYXZhaWxhYmxlIGZvciBsaXZlIHNlc3Npb25zIHRoYXQgZG8gbm90IGltcGxl
bWVudCBHb29nbGUgQWQgTWFuYWdlciBhZAogaW5zZXJ0aW9uLgoKCgoDBAABEgMeCBcKCwoD
BAAHEgQfAiIECg0KBQQAB50IEgQfAiIECo4BCgQEAAIAEgMmAhIagAEgVGhlIHJlc291cmNl
IG5hbWUgaW4gdGhlIGZvcm0gb2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vbGl2ZVNlc3Npb25zL3tsaXZlX3Nlc3Npb259L2xpdmVBZFRhZ0RldGFpbHMv
e2lkfWAuCgoMCgUEAAIABRIDJgIICgwKBQQAAgABEgMmCQ0KDAoFBAACAAMSAyYQEQolCgQE
AAIBEgMpAiUaGCBBIGxpc3Qgb2YgYWQgcmVxdWVzdHMuCgoMCgUEAAIBBBIDKQIKCgwKBQQA
AgEGEgMpCxQKDAoFBAACAQESAykVIAoMCgUEAAIBAxIDKSMkCqoBCgIEARIELwA7ARqdASBJ
bmZvcm1hdGlvbiByZWxhdGVkIHRvIHRoZSBkZXRhaWxzIGZvciBvbmUgYWQgdGFnLiBUaGlz
IHJlc291cmNlIGlzIG9ubHkKIGF2YWlsYWJsZSBmb3IgVk9EIHNlc3Npb25zIHRoYXQgZG8g
bm90IGltcGxlbWVudCBHb29nbGUgQWQgTWFuYWdlciBhZAogaW5zZXJ0aW9uLgoKCgoDBAEB
EgMvCBYKCwoDBAEHEgQwAjMECg0KBQQBB50IEgQwAjMECrkBCgQEAQIAEgM3AhIaqwEgVGhl
IG5hbWUgb2YgdGhlIGFkIHRhZyBkZXRhaWwgZm9yIHRoZSBzcGVjaWZpZWQgVk9EIHNlc3Np
b24sIGluIHRoZSBmb3JtIG9mCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L3ZvZFNlc3Npb25zL3t2b2Rfc2Vzc2lvbl9pZH0vdm9kQWRUYWdEZXRhaWxzL3tp
ZH1gLgoKDAoFBAECAAUSAzcCCAoMCgUEAQIAARIDNwkNCgwKBQQBAgADEgM3EBEKNAoEBAEC
ARIDOgIlGicgQSBsaXN0IG9mIGFkIHJlcXVlc3RzIGZvciBvbmUgYWQgdGFnLgoKDAoFBAEC
AQQSAzoCCgoMCgUEAQIBBhIDOgsUCgwKBQQBAgEBEgM6FSAKDAoFBAECAQMSAzojJAo3CgIE
AhIEPgBHARorIERldGFpbHMgb2YgYW4gYWQgcmVxdWVzdCB0byBhbiBhZCBzZXJ2ZXIuCgoK
CgMEAgESAz4IEQo/CgQEAgIAEgNAAhEaMiBUaGUgYWQgdGFnIFVSSSBwcm9jZXNzZWQgd2l0
aCBpbnRlZ3JhdGVkIG1hY3Jvcy4KCgwKBQQCAgAFEgNAAggKDAoFBAICAAESA0AJDAoMCgUE
AgIAAxIDQA8QCkAKBAQCAgESA0MCJxozIFRoZSByZXF1ZXN0IG1ldGFkYXRhIHVzZWQgdG8g
bWFrZSB0aGUgYWQgcmVxdWVzdC4KCgwKBQQCAgEGEgNDAhEKDAoFBAICAQESA0MSIgoMCgUE
AgIBAxIDQyUmCkIKBAQCAgISA0YCKRo1IFRoZSByZXNwb25zZSBtZXRhZGF0YSByZWNlaXZl
ZCBmcm9tIHRoZSBhZCByZXF1ZXN0LgoKDAoFBAICAgYSA0YCEgoMCgUEAgICARIDRhMkCgwK
BQQCAgIDEgNGJygKKQoCBAMSBEoATQEaHSBNZXRhZGF0YSBmb3IgYW4gYWQgcmVxdWVzdC4K
CgoKAwQDARIDSggXCjIKBAQDAgASA0wCJRolIFRoZSBIVFRQIGhlYWRlcnMgb2YgdGhlIGFk
IHJlcXVlc3QuCgoMCgUEAwIABhIDTAIYCgwKBQQDAgABEgNMGSAKDAoFBAMCAAMSA0wjJAo5
CgIEBBIEUABiARotIE1ldGFkYXRhIGZvciB0aGUgcmVzcG9uc2Ugb2YgYW4gYWQgcmVxdWVz
dC4KCgoKAwQEARIDUAgYCkEKBAQEAgASA1ICExo0IEVycm9yIG1lc3NhZ2UgcmVjZWl2ZWQg
d2hlbiBtYWtpbmcgdGhlIGFkIHJlcXVlc3QuCgoMCgUEBAIABRIDUgIICgwKBQQEAgABEgNS
CQ4KDAoFBAQCAAMSA1IREgopCgQEBAIBEgNVAiUaHCBIZWFkZXJzIGZyb20gdGhlIHJlc3Bv
bnNlLgoKDAoFBAQCAQYSA1UCGAoMCgUEBAIBARIDVRkgCgwKBQQEAgEDEgNVIyQKLAoEBAQC
AhIDWAIZGh8gU3RhdHVzIGNvZGUgZm9yIHRoZSByZXNwb25zZS4KCgwKBQQEAgIFEgNYAggK
DAoFBAQCAgESA1gJFAoMCgUEBAICAxIDWBcYCi0KBAQEAgMSA1sCFxogIFNpemUgaW4gYnl0
ZXMgb2YgdGhlIHJlc3BvbnNlLgoKDAoFBAQCAwUSA1sCBwoMCgUEBAIDARIDWwgSCgwKBQQE
AgMDEgNbFRYKMwoEBAQCBBIDXgIoGiYgVG90YWwgdGltZSBlbGFwc2VkIGZvciB0aGUgcmVz
cG9uc2UuCgoMCgUEBAIEBhIDXgIaCgwKBQQEAgQBEgNeGyMKDAoFBAQCBAMSA14mJwooCgQE
BAIFEgNhAhIaGyBUaGUgYm9keSBvZiB0aGUgcmVzcG9uc2UuCgoMCgUEBAIFBRIDYQIICgwK
BQQEAgUBEgNhCQ0KDAoFBAQCBQMSA2EQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail ===
    # Fields for LiveAdTagDetail
    # Field: name Type: 9 ()
    # Field: ad_requests Type: 11 (.google.cloud.video.stitcher.v1.AdRequest)

# === Message: Google::Cloud::Video::Stitcher::V1::AdTagDetails::VodAdTagDetail ===
    # Fields for VodAdTagDetail
    # Field: name Type: 9 ()
    # Field: ad_requests Type: 11 (.google.cloud.video.stitcher.v1.AdRequest)

# === Message: Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest ===
    # Fields for AdRequest
    # Field: uri Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.video.stitcher.v1.RequestMetadata)
    # Field: response_metadata Type: 11 (.google.cloud.video.stitcher.v1.ResponseMetadata)

# === Message: Google::Cloud::Video::Stitcher::V1::AdTagDetails::RequestMetadata ===
    # Fields for RequestMetadata
    # Field: headers Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Video::Stitcher::V1::AdTagDetails::ResponseMetadata ===
    # Fields for ResponseMetadata
    # Field: error Type: 9 ()
    # Field: headers Type: 11 (.google.protobuf.Struct)
    # Field: status_code Type: 9 ()
    # Field: size_bytes Type: 5 ()
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: body Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::AdTagDetails - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/ad_tag_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::AdTagDetails;

    my $msg = Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail->new({
        name => $name,
        ad_requests => $ad_requests,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/ad_tag_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail

Information related to the details for one ad tag. This resource is only
available for live sessions that do not implement Google Ad Manager ad
insertion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name in the form of
`projects/{project}/locations/{location}/liveSessions/{live_session}/liveAdTagDetails/{id}`.

=item * C<< $msg->ad_requests() >> / C<< $msg->ad_requests($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest>)

A list of ad requests.

=back

=head2 Google::Cloud::Video::Stitcher::V1::AdTagDetails::VodAdTagDetail

Information related to the details for one ad tag. This resource is only
available for VOD sessions that do not implement Google Ad Manager ad
insertion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the ad tag detail for the specified VOD session, in the form of
`projects/{project}/locations/{location}/vodSessions/{vod_session_id}/vodAdTagDetails/{id}`.

=item * C<< $msg->ad_requests() >> / C<< $msg->ad_requests($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest>)

A list of ad requests for one ad tag.

=back

=head2 Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest

Details of an ad request to an ad server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The ad tag URI processed with integrated macros.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::AdTagDetails::RequestMetadata>)

The request metadata used to make the ad request.

=item * C<< $msg->response_metadata() >> / C<< $msg->response_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::AdTagDetails::ResponseMetadata>)

The response metadata received from the ad request.

=back

=head2 Google::Cloud::Video::Stitcher::V1::AdTagDetails::RequestMetadata

Metadata for an ad request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The HTTP headers of the ad request.

=back

=head2 Google::Cloud::Video::Stitcher::V1::AdTagDetails::ResponseMetadata

Metadata for the response of an ad request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<String>

Error message received when making the ad request.

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Headers from the response.

=item * C<< $msg->status_code() >> / C<< $msg->status_code($value) >>

Type: C<String>

Status code for the response.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int32>

Size in bytes of the response.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Total time elapsed for the response.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

The body of the response.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::AdTagDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
