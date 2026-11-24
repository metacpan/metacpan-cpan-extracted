package Google::Bigtable::V2::PeerInfo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvYmlndGFibGUvdjIvcGVlcl9pbmZvLnByb3RvEhJnb29nbGUuYmlndGFibGUu
djIiqwUKCFBlZXJJbmZvEiwKEmdvb2dsZV9mcm9udGVuZF9pZBgBIAEoA1IQZ29vZ2xlRnJv
bnRlbmRJZBI2ChdhcHBsaWNhdGlvbl9mcm9udGVuZF9pZBgCIAEoA1IVYXBwbGljYXRpb25G
cm9udGVuZElkEj4KG2FwcGxpY2F0aW9uX2Zyb250ZW5kX3JlZ2lvbhgGIAEoCVIZYXBwbGlj
YXRpb25Gcm9udGVuZFJlZ2lvbhI+ChlhcHBsaWNhdGlvbl9mcm9udGVuZF96b25lGAMgASgJ
QgIYAVIXYXBwbGljYXRpb25Gcm9udGVuZFpvbmUSQAocYXBwbGljYXRpb25fZnJvbnRlbmRf
c3Viem9uZRgEIAEoCVIaYXBwbGljYXRpb25Gcm9udGVuZFN1YnpvbmUSUQoOdHJhbnNwb3J0
X3R5cGUYBSABKA4yKi5nb29nbGUuYmlndGFibGUudjIuUGVlckluZm8uVHJhbnNwb3J0VHlw
ZVINdHJhbnNwb3J0VHlwZSKjAgoNVHJhbnNwb3J0VHlwZRIaChZUUkFOU1BPUlRfVFlQRV9V
TktOT1dOEAASGwoXVFJBTlNQT1JUX1RZUEVfRVhURVJOQUwQARIdChlUUkFOU1BPUlRfVFlQ
RV9DTE9VRF9QQVRIEAISIAocVFJBTlNQT1JUX1RZUEVfRElSRUNUX0FDQ0VTUxADEiIKHlRS
QU5TUE9SVF9UWVBFX1NFU1NJT05fVU5LTk9XThAEEiMKH1RSQU5TUE9SVF9UWVBFX1NFU1NJ
T05fRVhURVJOQUwQBRIlCiFUUkFOU1BPUlRfVFlQRV9TRVNTSU9OX0NMT1VEX1BBVEgQBhIo
CiRUUkFOU1BPUlRfVFlQRV9TRVNTSU9OX0RJUkVDVF9BQ0NFU1MQB0K3AQoWY29tLmdvb2ds
ZS5iaWd0YWJsZS52MkINUGVlckluZm9Qcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2Jp
Z3RhYmxlL2FwaXYyL2JpZ3RhYmxlcGI7YmlndGFibGVwYqoCGEdvb2dsZS5DbG91ZC5CaWd0
YWJsZS5WMsoCGEdvb2dsZVxDbG91ZFxCaWd0YWJsZVxWMuoCG0dvb2dsZTo6Q2xvdWQ6OkJp
Z3RhYmxlOjpWMkrmFQoGEgQOAFABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAbCggKAQgSAxIANQoJCgIIJRIDEgA1CggKAQgSAxMATwoJCgIICxIDEwBP
CggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUALgoJCgIICBIDFQAuCggKAQgSAxYALwoJ
CgIIARIDFgAvCggKAQgSAxcANQoJCgIIKRIDFwA1CggKAQgSAxgANAoJCgIILRIDGAA0Cl0K
AgQAEgQcAFABGlEgUGVlckluZm8gY29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHBl
ZXIgdGhhdCB0aGUgY2xpZW50IGlzCiBjb25uZWN0aW5nIHRvLgoKCgoDBAABEgMcCBAKUAoE
BAAEABIEHgI6AxpCIFRoZSB0cmFuc3BvcnQgdHlwZSB0aGF0IHRoZSBjbGllbnQgdXNlZCB0
byBjb25uZWN0IHRvIHRoaXMgcGVlci4KCgwKBQQABAABEgMeBxQKLwoGBAAEAAIAEgMgBB8a
ICBUaGUgdHJhbnNwb3J0IHR5cGUgaXMgdW5rbm93bi4KCg4KBwQABAACAAESAyAEGgoOCgcE
AAQAAgACEgMgHR4KaAoGBAAEAAIBEgMkBCAaWSBUaGUgY2xpZW50IGNvbm5lY3RlZCB0byB0
aGlzIHBlZXIgdmlhIGFuIGV4dGVybmFsIG5ldHdvcmsKIChlLmcuIG91dHNpZGUgR29vZ2xl
IENsb3VkKS4KCg4KBwQABAACAQESAyQEGwoOCgcEAAQAAgECEgMkHh8KQQoGBAAEAAICEgMn
BCIaMiBUaGUgY2xpZW50IGNvbm5lY3RlZCB0byB0aGlzIHBlZXIgdmlhIENsb3VkUGF0aC4K
Cg4KBwQABAACAgESAycEHQoOCgcEAAQAAgICEgMnICEKRAoGBAAEAAIDEgMqBCUaNSBUaGUg
Y2xpZW50IGNvbm5lY3RlZCB0byB0aGlzIHBlZXIgdmlhIERpcmVjdEFjY2Vzcy4KCg4KBwQA
BAACAwESAyoEIAoOCgcEAAQAAgMCEgMqIyQKagoGBAAEAAIEEgMuBCcaWyBUaGUgY2xpZW50
IGNvbm5lY3RlZCB0byB0aGlzIHBlZXIgdmlhIEJpZ3RhYmxlIFNlc3Npb25zIHVzaW5nIGFu
IHVua25vd24KIHRyYW5zcG9ydCB0eXBlLgoKDgoHBAAEAAIEARIDLgQiCg4KBwQABAACBAIS
Ay4lJgp9CgYEAAQAAgUSAzIEKBpuIFRoZSBjbGllbnQgY29ubmVjdGVkIHRvIHRoaXMgcGVl
ciB2aWEgQmlndGFibGUgU2Vzc2lvbnMgb24gYW4gZXh0ZXJuYWwKIG5ldHdvcmsgKGUuZy4g
b3V0c2lkZSBHb29nbGUgQ2xvdWQpLgoKDgoHBAAEAAIFARIDMgQjCg4KBwQABAACBQISAzIm
JwpZCgYEAAQAAgYSAzUEKhpKIFRoZSBjbGllbnQgY29ubmVjdGVkIHRvIHRoaXMgcGVlciB2
aWEgQmlndGFibGUgU2Vzc2lvbnMgdXNpbmcgQ2xvdWRQYXRoLgoKDgoHBAAEAAIGARIDNQQl
Cg4KBwQABAACBgISAzUoKQpdCgYEAAQAAgcSAzkELRpOIFRoZSBjbGllbnQgY29ubmVjdGVk
IHRvIHRoaXMgcGVlciB2aWEgQmlndGFibGUgU2Vzc2lvbnMgdXNpbmcKIERpcmVjdEFjY2Vz
cy4KCg4KBwQABAACBwESAzkEKAoOCgcEAAQAAgcCEgM5KywKfwoEBAACABIDPgIfGnIgQW4g
b3BhcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBHb29nbGUgRnJvbnRlbmQgd2hpY2ggc2Vydmlj
ZWQgdGhpcyByZXF1ZXN0LgogT25seSBzZXQgd2hlbiBub3QgdXNpbmcgRGlyZWN0QWNjZXNz
LgoKDAoFBAACAAUSAz4CBwoMCgUEAAIAARIDPggaCgwKBQQAAgADEgM+HR4KXgoEBAACARID
QgIkGlEgQW4gb3BhcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBhcHBsaWNhdGlvbiBmcm9udGVu
ZCB3aGljaCBzZXJ2aWNlZCB0aGlzCiByZXF1ZXN0LgoKDAoFBAACAQUSA0ICBwoMCgUEAAIB
ARIDQggfCgwKBQQAAgEDEgNCIiMKVQoEBAACAhIDRQIpGkggVGhlIENsb3VkIHJlZ2lvbiBv
ZiB0aGUgYXBwbGljYXRpb24gZnJvbnRlbmQgdGhhdCBzZXJ2ZWQgdGhpcyByZXF1ZXN0LgoK
DAoFBAACAgUSA0UCCAoMCgUEAAICARIDRQkkCgwKBQQAAgIDEgNFJygKUwoEBAACAxIDSAI7
GkYgVGhlIENsb3VkIHpvbmUgb2YgdGhlIGFwcGxpY2F0aW9uIGZyb250ZW5kIHRoYXQgc2Vy
dmVkIHRoaXMgcmVxdWVzdC4KCgwKBQQAAgMFEgNIAggKDAoFBAACAwESA0gJIgoMCgUEAAID
AxIDSCUmCgwKBQQAAgMIEgNIJzoKDQoGBAACAwgDEgNIKDkKuAEKBAQAAgQSA00CKhqqASBU
aGUgc3Viem9uZSBvZiB0aGUgYXBwbGljYXRpb24gZnJvbnRlbmQgdGhhdCBzZXJ2ZWQgdGhp
cyByZXF1ZXN0LCBlLmcuIGFuCiBpZGVudGlmaWVyIGZvciB3aGVyZSB3aXRoaW4gYSB6b25l
ICh3aXRoaW4gdGhlIHJlcG9ydGVkIHJlZ2lvbikgdGhlCiBhcHBsaWNhdGlvbiBmcm9udGVu
ZCBpcy4KCgwKBQQAAgQFEgNNAggKDAoFBAACBAESA00JJQoMCgUEAAIEAxIDTSgpCgsKBAQA
AgUSA08CIwoMCgUEAAIFBhIDTwIPCgwKBQQAAgUBEgNPEB4KDAoFBAACBQMSA08hImIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Bigtable::V2::PeerInfo::PeerInfo ===
    # Fields for PeerInfo
    # Field: google_frontend_id Type: 3 ()
    # Field: application_frontend_id Type: 3 ()
    # Field: application_frontend_region Type: 9 ()
    # Field: application_frontend_zone Type: 9 ()
    # Field: application_frontend_subzone Type: 9 ()
    # Field: transport_type Type: 14 (.google.bigtable.v2.PeerInfo.TransportType)

# Enum: PeerInfo::TransportType
our $PeerInfo_TRANSPORT_TYPE_UNKNOWN = 0;
our $PeerInfo_TRANSPORT_TYPE_EXTERNAL = 1;
our $PeerInfo_TRANSPORT_TYPE_CLOUD_PATH = 2;
our $PeerInfo_TRANSPORT_TYPE_DIRECT_ACCESS = 3;
our $PeerInfo_TRANSPORT_TYPE_SESSION_UNKNOWN = 4;
our $PeerInfo_TRANSPORT_TYPE_SESSION_EXTERNAL = 5;
our $PeerInfo_TRANSPORT_TYPE_SESSION_CLOUD_PATH = 6;
our $PeerInfo_TRANSPORT_TYPE_SESSION_DIRECT_ACCESS = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Bigtable::V2::PeerInfo - Compiled Protocol Buffers messages for google/bigtable/v2/peer_info.proto

=head1 SYNOPSIS

    use Google::Bigtable::V2::PeerInfo;

    my $msg = Google::Bigtable::V2::PeerInfo::PeerInfo->new({
        google_frontend_id => $google_frontend_id,
        application_frontend_id => $application_frontend_id,
        application_frontend_region => $application_frontend_region,
        application_frontend_zone => $application_frontend_zone,
    });

    # Read or update a field
    my $val = $msg->google_frontend_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Bigtable::V2::PeerInfo::PeerInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/bigtable/v2/peer_info.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Bigtable::V2::PeerInfo::PeerInfo

PeerInfo contains information about the peer that the client is
connecting to.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->google_frontend_id() >> / C<< $msg->google_frontend_id($value) >>

Type: C<Int64>

An opaque identifier for the Google Frontend which serviced this request.
Only set when not using DirectAccess.

=item * C<< $msg->application_frontend_id() >> / C<< $msg->application_frontend_id($value) >>

Type: C<Int64>

An opaque identifier for the application frontend which serviced this
request.

=item * C<< $msg->application_frontend_region() >> / C<< $msg->application_frontend_region($value) >>

Type: C<String>

The Cloud region of the application frontend that served this request.

=item * C<< $msg->application_frontend_zone() >> / C<< $msg->application_frontend_zone($value) >>

Type: C<String>

The Cloud zone of the application frontend that served this request.

=item * C<< $msg->application_frontend_subzone() >> / C<< $msg->application_frontend_subzone($value) >>

Type: C<String>

The subzone of the application frontend that served this request, e.g. an
identifier for where within a zone (within the reported region) the
application frontend is.

=item * C<< $msg->transport_type() >> / C<< $msg->transport_type($value) >>

Type: C<Enum> (L<Google::Bigtable::V2::PeerInfo::TransportType>)

=back

=head3 Enum: PeerInfo::TransportType

=over 4

=item * C<TRANSPORT_TYPE_UNKNOWN> => C<0>

=item * C<TRANSPORT_TYPE_EXTERNAL> => C<1>

=item * C<TRANSPORT_TYPE_CLOUD_PATH> => C<2>

=item * C<TRANSPORT_TYPE_DIRECT_ACCESS> => C<3>

=item * C<TRANSPORT_TYPE_SESSION_UNKNOWN> => C<4>

=item * C<TRANSPORT_TYPE_SESSION_EXTERNAL> => C<5>

=item * C<TRANSPORT_TYPE_SESSION_CLOUD_PATH> => C<6>

=item * C<TRANSPORT_TYPE_SESSION_DIRECT_ACCESS> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Bigtable::V2::PeerInfo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
