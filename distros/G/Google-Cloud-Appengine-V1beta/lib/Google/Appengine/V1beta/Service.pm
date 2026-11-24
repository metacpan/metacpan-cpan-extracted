package Google::Appengine::V1beta::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Appengine::V1beta::NetworkSettings };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9zZXJ2aWNlLnByb3RvEhdnb29nbGUuYXBwZW5n
aW5lLnYxYmV0YRouZ29vZ2xlL2FwcGVuZ2luZS92MWJldGEvbmV0d29ya19zZXR0aW5ncy5w
cm90byK/AQoHU2VydmljZRISCgRuYW1lGAEgASgJUgRuYW1lEg4KAmlkGAIgASgJUgJpZBI7
CgVzcGxpdBgDIAEoCzIlLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLlRyYWZmaWNTcGxpdFIF
c3BsaXQSUwoQbmV0d29ya19zZXR0aW5ncxgGIAEoCzIoLmdvb2dsZS5hcHBlbmdpbmUudjFi
ZXRhLk5ldHdvcmtTZXR0aW5nc1IPbmV0d29ya1NldHRpbmdzIq4CCgxUcmFmZmljU3BsaXQS
SAoIc2hhcmRfYnkYASABKA4yLS5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5UcmFmZmljU3Bs
aXQuU2hhcmRCeVIHc2hhcmRCeRJYCgthbGxvY2F0aW9ucxgCIAMoCzI2Lmdvb2dsZS5hcHBl
bmdpbmUudjFiZXRhLlRyYWZmaWNTcGxpdC5BbGxvY2F0aW9uc0VudHJ5UgthbGxvY2F0aW9u
cxo+ChBBbGxvY2F0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgB
UgV2YWx1ZToCOAEiOgoHU2hhcmRCeRIPCgtVTlNQRUNJRklFRBAAEgoKBkNPT0tJRRABEgYK
AklQEAISCgoGUkFORE9NEANC0gEKG2NvbS5nb29nbGUuYXBwZW5naW5lLnYxYmV0YUIMU2Vy
dmljZVByb3RvUAFaQGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBw
ZW5naW5lL3YxYmV0YTthcHBlbmdpbmWqAh1Hb29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxQmV0
YcoCHUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVcVjFiZXRh6gIgR29vZ2xlOjpDbG91ZDo6QXBw
RW5naW5lOjpWMWJldGFKqhsKBhIEDgBcAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgA4CggKAQgSAxQAOgoJCgIIJRIDFAA6CggKAQgS
AxUAVwoJCgIICxIDFQBXCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALQoJCgIICBID
FwAtCggKAQgSAxgANAoJCgIIARIDGAA0CggKAQgSAxkAOgoJCgIIKRIDGQA6CggKAQgSAxoA
OQoJCgIILRIDGgA5Cs4DCgIEABIEIwA2ARrBAyBBIFNlcnZpY2UgcmVzb3VyY2UgaXMgYSBs
b2dpY2FsIGNvbXBvbmVudCBvZiBhbiBhcHBsaWNhdGlvbiB0aGF0IGNhbiBzaGFyZQogc3Rh
dGUgYW5kIGNvbW11bmljYXRlIGluIGEgc2VjdXJlIGZhc2hpb24gd2l0aCBvdGhlciBzZXJ2
aWNlcy4KIEZvciBleGFtcGxlLCBhbiBhcHBsaWNhdGlvbiB0aGF0IGhhbmRsZXMgY3VzdG9t
ZXIgcmVxdWVzdHMgbWlnaHQKIGluY2x1ZGUgc2VwYXJhdGUgc2VydmljZXMgdG8gaGFuZGxl
IHRhc2tzIHN1Y2ggYXMgYmFja2VuZCBkYXRhCiBhbmFseXNpcyBvciBBUEkgcmVxdWVzdHMg
ZnJvbSBtb2JpbGUgZGV2aWNlcy4gRWFjaCBzZXJ2aWNlIGhhcyBhCiBjb2xsZWN0aW9uIG9m
IHZlcnNpb25zIHRoYXQgZGVmaW5lIGEgc3BlY2lmaWMgc2V0IG9mIGNvZGUgdXNlZCB0bwog
aW1wbGVtZW50IHRoZSBmdW5jdGlvbmFsaXR5IG9mIHRoYXQgc2VydmljZS4KCgoKAwQAARID
IwgPCnMKBAQAAgASAygCEhpmIEZ1bGwgcGF0aCB0byB0aGUgU2VydmljZSByZXNvdXJjZSBp
biB0aGUgQVBJLgogRXhhbXBsZTogYGFwcHMvbXlhcHAvc2VydmljZXMvZGVmYXVsdGAuCgog
QE91dHB1dE9ubHkKCgwKBQQAAgAFEgMoAggKDAoFBAACAAESAygJDQoMCgUEAAIAAxIDKBAR
CmYKBAQAAgESAy4CEBpZIFJlbGF0aXZlIG5hbWUgb2YgdGhlIHNlcnZpY2Ugd2l0aGluIHRo
ZSBhcHBsaWNhdGlvbi4KIEV4YW1wbGU6IGBkZWZhdWx0YC4KCiBAT3V0cHV0T25seQoKDAoF
BAACAQUSAy4CCAoMCgUEAAIBARIDLgkLCgwKBQQAAgEDEgMuDg8KcAoEBAACAhIDMgIZGmMg
TWFwcGluZyB0aGF0IGRlZmluZXMgZnJhY3Rpb25hbCBIVFRQIHRyYWZmaWMgZGl2ZXJzaW9u
IHRvCiBkaWZmZXJlbnQgdmVyc2lvbnMgd2l0aGluIHRoZSBzZXJ2aWNlLgoKDAoFBAACAgYS
AzICDgoMCgUEAAICARIDMg8UCgwKBQQAAgIDEgMyFxgKTQoEBAACAxIDNQInGkAgSW5ncmVz
cyBzZXR0aW5ncyBmb3IgdGhpcyBzZXJ2aWNlLiBXaWxsIGFwcGx5IHRvIGFsbCB2ZXJzaW9u
cy4KCgwKBQQAAgMGEgM1AhEKDAoFBAACAwESAzUSIgoMCgUEAAIDAxIDNSUmCqYBCgIEARIE
OgBcARqZASBUcmFmZmljIHJvdXRpbmcgY29uZmlndXJhdGlvbiBmb3IgdmVyc2lvbnMgd2l0
aGluIGEgc2luZ2xlIHNlcnZpY2UuIFRyYWZmaWMKIHNwbGl0cyBkZWZpbmUgaG93IHRyYWZm
aWMgZGlyZWN0ZWQgdG8gdGhlIHNlcnZpY2UgaXMgYXNzaWduZWQgdG8gdmVyc2lvbnMuCgoK
CgMEAQESAzoIFAouCgQEAQQAEgQ8AkwDGiAgQXZhaWxhYmxlIHNoYXJkaW5nIG1lY2hhbmlz
bXMuCgoMCgUEAQQAARIDPAcOCi4KBgQBBAACABIDPgQUGh8gRGl2ZXJzaW9uIG1ldGhvZCB1
bnNwZWNpZmllZC4KCg4KBwQBBAACAAESAz4EDwoOCgcEAQQAAgACEgM+EhMKmgEKBgQBBAAC
ARIDQgQPGooBIERpdmVyc2lvbiBiYXNlZCBvbiBhIHNwZWNpYWxseSBuYW1lZCBjb29raWUs
ICJHT09HQVBQVUlELiIgVGhlIGNvb2tpZQogbXVzdCBiZSBzZXQgYnkgdGhlIGFwcGxpY2F0
aW9uIGl0c2VsZiBvciBubyBkaXZlcnNpb24gd2lsbCBvY2N1ci4KCg4KBwQBBAACAQESA0IE
CgoOCgcEAQQAAgECEgNCDQ4KZwoGBAEEAAICEgNGBAsaWCBEaXZlcnNpb24gYmFzZWQgb24g
YXBwbHlpbmcgdGhlIG1vZHVsdXMgb3BlcmF0aW9uIHRvIGEgZmluZ2VycHJpbnQKIG9mIHRo
ZSBJUCBhZGRyZXNzLgoKDgoHBAEEAAICARIDRgQGCg4KBwQBBAACAgISA0YJCgrKAQoGBAEE
AAIDEgNLBA8augEgRGl2ZXJzaW9uIGJhc2VkIG9uIHdlaWdodGVkIHJhbmRvbSBhc3NpZ25t
ZW50LiBBbiBpbmNvbWluZyByZXF1ZXN0IGlzCiByYW5kb21seSByb3V0ZWQgdG8gYSB2ZXJz
aW9uIGluIHRoZSB0cmFmZmljIHNwbGl0LCB3aXRoIHByb2JhYmlsaXR5CiBwcm9wb3J0aW9u
YWwgdG8gdGhlIHZlcnNpb24ncyB0cmFmZmljIHNoYXJlLgoKDgoHBAEEAAIDARIDSwQKCg4K
BwQBBAACAwISA0sNDgqvAQoEBAECABIDUQIXGqEBIE1lY2hhbmlzbSB1c2VkIHRvIGRldGVy
bWluZSB3aGljaCB2ZXJzaW9uIGEgcmVxdWVzdCBpcyBzZW50IHRvLgogVGhlIHRyYWZmaWMg
c2VsZWN0aW9uIGFsZ29yaXRobSB3aWxsCiBiZSBzdGFibGUgZm9yIGVpdGhlciB0eXBlIHVu
dGlsIGFsbG9jYXRpb25zIGFyZSBjaGFuZ2VkLgoKDAoFBAECAAYSA1ECCQoMCgUEAQIAARID
UQoSCgwKBQQBAgADEgNRFRYKmQQKBAQBAgESA1sCJhqLBCBNYXBwaW5nIGZyb20gdmVyc2lv
biBJRHMgd2l0aGluIHRoZSBzZXJ2aWNlIHRvIGZyYWN0aW9uYWwKICgwLjAwMCwgMV0gYWxs
b2NhdGlvbnMgb2YgdHJhZmZpYyBmb3IgdGhhdCB2ZXJzaW9uLiBFYWNoIHZlcnNpb24gY2Fu
CiBiZSBzcGVjaWZpZWQgb25seSBvbmNlLCBidXQgc29tZSB2ZXJzaW9ucyBpbiB0aGUgc2Vy
dmljZSBtYXkgbm90CiBoYXZlIGFueSB0cmFmZmljIGFsbG9jYXRpb24uIFNlcnZpY2VzIHRo
YXQgaGF2ZSB0cmFmZmljIGFsbG9jYXRlZAogY2Fubm90IGJlIGRlbGV0ZWQgdW50aWwgZWl0
aGVyIHRoZSBzZXJ2aWNlIGlzIGRlbGV0ZWQgb3IKIHRoZWlyIHRyYWZmaWMgYWxsb2NhdGlv
biBpcyByZW1vdmVkLiBBbGxvY2F0aW9ucyBtdXN0IHN1bSB0byAxLgogVXAgdG8gdHdvIGRl
Y2ltYWwgcGxhY2UgcHJlY2lzaW9uIGlzIHN1cHBvcnRlZCBmb3IgSVAtYmFzZWQgc3BsaXRz
IGFuZAogdXAgdG8gdGhyZWUgZGVjaW1hbCBwbGFjZXMgaXMgc3VwcG9ydGVkIGZvciBjb29r
aWUtYmFzZWQgc3BsaXRzLgoKDAoFBAECAQYSA1sCFQoMCgUEAQIBARIDWxYhCgwKBQQBAgED
EgNbJCViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: split Type: 11 (.google.appengine.v1beta.TrafficSplit)
    # Field: network_settings Type: 11 (.google.appengine.v1beta.NetworkSettings)

# === Message: Google::Appengine::V1beta::Service::TrafficSplit ===
    # Fields for TrafficSplit
    # Field: shard_by Type: 14 (.google.appengine.v1beta.TrafficSplit.ShardBy)
    # Field: allocations Type: 11 (.google.appengine.v1beta.TrafficSplit.AllocationsEntry)

# Enum: TrafficSplit::ShardBy
our $TrafficSplit_UNSPECIFIED = 0;
our $TrafficSplit_COOKIE = 1;
our $TrafficSplit_IP = 2;
our $TrafficSplit_RANDOM = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Service - Compiled Protocol Buffers messages for google/appengine/v1beta/service.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Service;

    my $msg = Google::Appengine::V1beta::Service::Service->new({
        name => $name,
        id => $id,
        split => $split,
        network_settings => $network_settings,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Service::Service

A Service resource is a logical component of an application that can share
state and communicate in a secure fashion with other services.
For example, an application that handles customer requests might
include separate services to handle tasks such as backend data
analysis or API requests from mobile devices. Each service has a
collection of versions that define a specific set of code used to
implement the functionality of that service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the Service resource in the API.
Example: `apps/myapp/services/default`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Relative name of the service within the application.
Example: `default`.

@OutputOnly

=item * C<< $msg->split() >> / C<< $msg->split($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Service::TrafficSplit>)

Mapping that defines fractional HTTP traffic diversion to
different versions within the service.

=item * C<< $msg->network_settings() >> / C<< $msg->network_settings($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::NetworkSettings::NetworkSettings>)

Ingress settings for this service. Will apply to all versions.

=back

=head2 Google::Appengine::V1beta::Service::TrafficSplit

Traffic routing configuration for versions within a single service. Traffic
splits define how traffic directed to the service is assigned to versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->shard_by() >> / C<< $msg->shard_by($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::TrafficSplit::ShardBy>)

Mechanism used to determine which version a request is sent to.
The traffic selection algorithm will
be stable for either type until allocations are changed.

=item * C<< $msg->allocations() >> / C<< $msg->allocations($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Service::TrafficSplit::AllocationsEntry>)

Mapping from version IDs within the service to fractional
(0.000, 1] allocations of traffic for that version. Each version can
be specified only once, but some versions in the service may not
have any traffic allocation. Services that have traffic allocated
cannot be deleted until either the service is deleted or
their traffic allocation is removed. Allocations must sum to 1.
Up to two decimal place precision is supported for IP-based splits and
up to three decimal places is supported for cookie-based splits.

=back

=head3 Enum: TrafficSplit::ShardBy

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<COOKIE> => C<1>

=item * C<IP> => C<2>

=item * C<RANDOM> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
