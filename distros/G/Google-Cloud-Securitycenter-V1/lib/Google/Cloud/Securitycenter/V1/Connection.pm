package Google::Cloud::Securitycenter::V1::Connection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvY29ubmVjdGlvbi5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIsECCgpDb25uZWN0aW9uEiUKDmRlc3RpbmF0
aW9uX2lwGAEgASgJUg1kZXN0aW5hdGlvbklwEikKEGRlc3RpbmF0aW9uX3BvcnQYAiABKAVS
D2Rlc3RpbmF0aW9uUG9ydBIbCglzb3VyY2VfaXAYAyABKAlSCHNvdXJjZUlwEh8KC3NvdXJj
ZV9wb3J0GAQgASgFUgpzb3VyY2VQb3J0Ek8KCHByb3RvY29sGAUgASgOMjMuZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYxLkNvbm5lY3Rpb24uUHJvdG9jb2xSCHByb3RvY29sIlIK
CFByb3RvY29sEhgKFFBST1RPQ09MX1VOU1BFQ0lGSUVEEAASCAoESUNNUBABEgcKA1RDUBAG
EgcKA1VEUBAREgcKA0dSRRAvEgcKA0VTUBAyQukBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3Vy
aXR5Y2VudGVyLnYxQg9Db25uZWN0aW9uUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9z
ZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKq
Ah5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJp
dHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFKpg8KBhIE
DgBBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoICgEI
EgMSADsKCQoCCCUSAxIAOwoICgEIEgMTAGEKCQoCCAsSAxMAYQoICgEIEgMUACIKCQoCCAoS
AxQAIgoICgEIEgMVADAKCQoCCAgSAxUAMAoICgEIEgMWADsKCQoCCAESAxYAOwoICgEIEgMX
ADsKCQoCCCkSAxcAOwoICgEIEgMYADoKCQoCCC0SAxgAOgpXCgIEABIEGwBBARpLIENvbnRh
aW5zIGluZm9ybWF0aW9uIGFib3V0IHRoZSBJUCBjb25uZWN0aW9uIGFzc29jaWF0ZWQgd2l0
aCB0aGUgZmluZGluZy4KCgoKAwQAARIDGwgSCkkKBAQABAASBB0CLwMaOyBJQU5BIEludGVy
bmV0IFByb3RvY29sIE51bWJlciBzdWNoIGFzIFRDUCg2KSBhbmQgVURQKDE3KS4KCgwKBQQA
BAABEgMdBw8KMwoGBAAEAAIAEgMfBB0aJCBVbnNwZWNpZmllZCBwcm90b2NvbCAobm90IEhP
UE9QVCkuCgoOCgcEAAQAAgABEgMfBBgKDgoHBAAEAAIAAhIDHxscCjMKBgQABAACARIDIgQN
GiQgSW50ZXJuZXQgQ29udHJvbCBNZXNzYWdlIFByb3RvY29sLgoKDgoHBAAEAAIBARIDIgQI
Cg4KBwQABAACAQISAyILDAovCgYEAAQAAgISAyUEDBogIFRyYW5zbWlzc2lvbiBDb250cm9s
IFByb3RvY29sLgoKDgoHBAAEAAICARIDJQQHCg4KBwQABAACAgISAyUKCwooCgYEAAQAAgMS
AygEDRoZIFVzZXIgRGF0YWdyYW0gUHJvdG9jb2wuCgoOCgcEAAQAAgMBEgMoBAcKDgoHBAAE
AAIDAhIDKAoMCi8KBgQABAACBBIDKwQNGiAgR2VuZXJpYyBSb3V0aW5nIEVuY2Fwc3VsYXRp
b24uCgoOCgcEAAQAAgQBEgMrBAcKDgoHBAAEAAIEAhIDKwoMCigKBgQABAACBRIDLgQNGhkg
RW5jYXAgU2VjdXJpdHkgUGF5bG9hZC4KCg4KBwQABAACBQESAy4EBwoOCgcEAAQAAgUCEgMu
CgwKZQoEBAACABIDMwIcGlggRGVzdGluYXRpb24gSVAgYWRkcmVzcy4gTm90IHByZXNlbnQg
Zm9yIHNvY2tldHMgdGhhdCBhcmUgbGlzdGVuaW5nIGFuZCBub3QKIGNvbm5lY3RlZC4KCgwK
BQQAAgAFEgMzAggKDAoFBAACAAESAzMJFwoMCgUEAAIAAxIDMxobCl8KBAQAAgESAzcCHRpS
IERlc3RpbmF0aW9uIHBvcnQuIE5vdCBwcmVzZW50IGZvciBzb2NrZXRzIHRoYXQgYXJlIGxp
c3RlbmluZyBhbmQgbm90CiBjb25uZWN0ZWQuCgoMCgUEAAIBBRIDNwIHCgwKBQQAAgEBEgM3
CBgKDAoFBAACAQMSAzcbHAohCgQEAAICEgM6AhcaFCBTb3VyY2UgSVAgYWRkcmVzcy4KCgwK
BQQAAgIFEgM6AggKDAoFBAACAgESAzoJEgoMCgUEAAICAxIDOhUWChsKBAQAAgMSAz0CGBoO
IFNvdXJjZSBwb3J0LgoKDAoFBAACAwUSAz0CBwoMCgUEAAIDARIDPQgTCgwKBQQAAgMDEgM9
FhcKSAoEBAACBBIDQAIYGjsgSUFOQSBJbnRlcm5ldCBQcm90b2NvbCBOdW1iZXIgc3VjaCBh
cyBUQ1AoNikgYW5kIFVEUCgxNykuCgoMCgUEAAIEBhIDQAIKCgwKBQQAAgQBEgNACxMKDAoF
BAACBAMSA0AWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Connection::Connection ===
    # Fields for Connection
    # Field: destination_ip Type: 9 ()
    # Field: destination_port Type: 5 ()
    # Field: source_ip Type: 9 ()
    # Field: source_port Type: 5 ()
    # Field: protocol Type: 14 (.google.cloud.securitycenter.v1.Connection.Protocol)

# Enum: Connection::Protocol
our $Connection_PROTOCOL_UNSPECIFIED = 0;
our $Connection_ICMP = 1;
our $Connection_TCP = 6;
our $Connection_UDP = 17;
our $Connection_GRE = 47;
our $Connection_ESP = 50;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Connection - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/connection.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Connection;

    my $msg = Google::Cloud::Securitycenter::V1::Connection::Connection->new({
        destination_ip => $destination_ip,
        destination_port => $destination_port,
        source_ip => $source_ip,
        source_port => $source_port,
    });

    # Read or update a field
    my $val = $msg->destination_ip();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Connection::Connection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/connection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Connection::Connection

Contains information about the IP connection associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->destination_ip() >> / C<< $msg->destination_ip($value) >>

Type: C<String>

Destination IP address. Not present for sockets that are listening and not
connected.

=item * C<< $msg->destination_port() >> / C<< $msg->destination_port($value) >>

Type: C<Int32>

Destination port. Not present for sockets that are listening and not
connected.

=item * C<< $msg->source_ip() >> / C<< $msg->source_ip($value) >>

Type: C<String>

Source IP address.

=item * C<< $msg->source_port() >> / C<< $msg->source_port($value) >>

Type: C<Int32>

Source port.

=item * C<< $msg->protocol() >> / C<< $msg->protocol($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::Connection::Protocol>)

IANA Internet Protocol Number such as TCP(6) and UDP(17).

=back

=head3 Enum: Connection::Protocol

=over 4

=item * C<PROTOCOL_UNSPECIFIED> => C<0>

=item * C<ICMP> => C<1>

=item * C<TCP> => C<6>

=item * C<UDP> => C<17>

=item * C<GRE> => C<47>

=item * C<ESP> => C<50>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Connection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
