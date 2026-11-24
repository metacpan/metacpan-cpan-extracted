package Google::Cloud::Video::Stitcher::V1::Slates;

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
Citnb29nbGUvY2xvdWQvdmlkZW8vc3RpdGNoZXIvdjEvc2xhdGVzLnByb3RvEh5nb29nbGUu
Y2xvdWQudmlkZW8uc3RpdGNoZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iuwIKBVNsYXRlEhcKBG5hbWUYASABKAlC
A+BBA1IEbmFtZRIQCgN1cmkYAiABKAlSA3VyaRJLCglnYW1fc2xhdGUYAyABKAsyLi5nb29n
bGUuY2xvdWQudmlkZW8uc3RpdGNoZXIudjEuU2xhdGUuR2FtU2xhdGVSCGdhbVNsYXRlGlkK
CEdhbVNsYXRlEiYKDG5ldHdvcmtfY29kZRgBIAEoCUID4EECUgtuZXR3b3JrQ29kZRIlCgxn
YW1fc2xhdGVfaWQYAiABKANCA+BBA1IKZ2FtU2xhdGVJZDpf6kFcCiJ2aWRlb3N0aXRjaGVy
Lmdvb2dsZWFwaXMuY29tL1NsYXRlEjZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vc2xhdGVzL3tzbGF0ZX1CcwoiY29tLmdvb2dsZS5jbG91ZC52aWRlby5zdGl0
Y2hlci52MUILU2xhdGVzUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby92aWRlby9zdGl0
Y2hlci9hcGl2MS9zdGl0Y2hlcnBiO3N0aXRjaGVycGJKpg0KBhIEDgA1AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCAoBCBIDFQBVCgkKAggLEgMVAFUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAs
CgkKAggIEgMXACwKCAoBCBIDGAA7CgkKAggBEgMYADsKGgoCBAASBBsANQEaDiBTbGF0ZSBv
YmplY3QKCgoKAwQAARIDGwgNCgsKAwQABxIEHAIfBAoNCgUEAAedCBIEHAIfBApeCgQEAAMA
EgQjAikDGlAgR2FtU2xhdGUgb2JqZWN0IGhhcyBHb29nbGUgQWQgTWFuYWdlciAoR0FNKSBy
ZWxhdGVkIHByb3BlcnRpZXMgZm9yIHRoZQogc2xhdGUuCgoMCgUEAAMAARIDIwoSClUKBgQA
AwACABIDJQRFGkYgUmVxdWlyZWQuIEFkIE1hbmFnZXIgbmV0d29yayBjb2RlIHRvIGFzc29j
aWF0ZSB3aXRoIHRoZSBsaXZlIGNvbmZpZy4KCg4KBwQAAwACAAUSAyUECgoOCgcEAAMAAgAB
EgMlCxcKDgoHBAADAAIAAxIDJRobCg4KBwQAAwACAAgSAyUcRAoRCgoEAAMAAgAInAgAEgMl
HUMKTAoGBAADAAIBEgMoBEcaPSBPdXRwdXQgb25seS4gVGhlIGlkZW50aWZpZXIgZ2VuZXJh
dGVkIGZvciB0aGUgc2xhdGUgYnkgR0FNLgoKDgoHBAADAAIBBRIDKAQJCg4KBwQAAwACAQES
AygKFgoOCgcEAAMAAgEDEgMoGRoKDgoHBAADAAIBCBIDKBtGChEKCgQAAwACAQicCAASAygc
RQqAAQoEBAACABIDLQI+GnMgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBzbGF0ZSwg
aW4gdGhlIGZvcm0gb2YKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb259L3NsYXRlcy97aWR9YC4KCgwKBQQAAgAFEgMtAggKDAoFBAACAAESAy0JDQoM
CgUEAAIAAxIDLRARCgwKBQQAAgAIEgMtEj0KDwoIBAACAAicCAASAy0TPAqDAQoEBAACARID
MQIRGnYgVGhlIFVSSSB0byBmZXRjaCB0aGUgc291cmNlIGNvbnRlbnQgZm9yIHRoZSBzbGF0
ZS4gVGhpcyBVUkkgbXVzdCByZXR1cm4gYW4KIE1QNCB2aWRlbyB3aXRoIGF0IGxlYXN0IG9u
ZSBhdWRpbyB0cmFjay4KCgwKBQQAAgEFEgMxAggKDAoFBAACAQESAzEJDAoMCgUEAAIBAxID
MQ8QCkYKBAQAAgISAzQCGRo5IGdhbV9zbGF0ZSBoYXMgYWxsIHRoZSBHQU0tcmVsYXRlZCBh
dHRyaWJ1dGVzIG9mIHNsYXRlcy4KCgwKBQQAAgIGEgM0AgoKDAoFBAACAgESAzQLFAoMCgUE
AAICAxIDNBcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Video::Stitcher::V1::Slates::Slate ===
    # Fields for Slate
    # Field: name Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: gam_slate Type: 11 (.google.cloud.video.stitcher.v1.Slate.GamSlate)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Slates - Compiled Protocol Buffers messages for google/cloud/video/stitcher/v1/slates.proto

=head1 SYNOPSIS

    use Google::Cloud::Video::Stitcher::V1::Slates;

    my $msg = Google::Cloud::Video::Stitcher::V1::Slates::Slate->new({
        name => $name,
        uri => $uri,
        gam_slate => $gam_slate,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Video::Stitcher::V1::Slates::Slate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/video/stitcher/v1/slates.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Video::Stitcher::V1::Slates::Slate

Slate object

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the slate, in the form of
`projects/{project_number}/locations/{location}/slates/{id}`.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URI to fetch the source content for the slate. This URI must return an
MP4 video with at least one audio track.

=item * C<< $msg->gam_slate() >> / C<< $msg->gam_slate($value) >>

Type: C<Message> (L<Google::Cloud::Video::Stitcher::V1::Slates::Slate::GamSlate>)

gam_slate has all the GAM-related attributes of slates.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Video::Stitcher::V1::Slates::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
