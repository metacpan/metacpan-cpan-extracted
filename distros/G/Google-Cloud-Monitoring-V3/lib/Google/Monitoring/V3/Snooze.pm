package Google::Monitoring::V3::Snooze;

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
    eval { require Google::Monitoring::V3::Common };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvbW9uaXRvcmluZy92My9zbm9vemUucHJvdG8SFGdvb2dsZS5tb25pdG9yaW5n
LnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGiFnb29nbGUvbW9uaXRvcmluZy92My9jb21tb24ucHJvdG8ijgMKBlNub296
ZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSRgoIY3JpdGVyaWEYAyABKAsyJS5nb29nbGUu
bW9uaXRvcmluZy52My5Tbm9vemUuQ3JpdGVyaWFCA+BBAlIIY3JpdGVyaWESQwoIaW50ZXJ2
YWwYBCABKAsyIi5nb29nbGUubW9uaXRvcmluZy52My5UaW1lSW50ZXJ2YWxCA+BBAlIIaW50
ZXJ2YWwSJgoMZGlzcGxheV9uYW1lGAUgASgJQgPgQQJSC2Rpc3BsYXlOYW1lGmoKCENyaXRl
cmlhEkYKCHBvbGljaWVzGAEgAygJQir6QScKJW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20v
QWxlcnRQb2xpY3lSCHBvbGljaWVzEhYKBmZpbHRlchgCIAEoCVIGZmlsdGVyOkrqQUcKIG1v
bml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vU25vb3plEiNwcm9qZWN0cy97cHJvamVjdH0vc25v
b3plcy97c25vb3plfULGAQoYY29tLmdvb2dsZS5tb25pdG9yaW5nLnYzQgtTbm9vemVQcm90
b1ABWkFjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIvbW9uaXRvcmlu
Z3BiO21vbml0b3JpbmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYzygIaR29vZ2xl
XENsb3VkXE1vbml0b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpWM0rB
GwoGEgQOAF8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAd
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAArCggKAQgSAxYANwoJCgIIJRIDFgA3
CggKAQgSAxcAWAoJCgIICxIDFwBYCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALAoJ
CgIICBIDGQAsCggKAQgSAxoAMQoJCgIIARIDGgAxCggKAQgSAxsANwoJCgIIKRIDGwA3CggK
AQgSAxwANgoJCgIILRIDHAA2CpICCgIEABIEIgBfARqFAiBBIGBTbm9vemVgIHdpbGwgcHJl
dmVudCBhbnkgYWxlcnRzIGZyb20gYmVpbmcgb3BlbmVkLCBhbmQgY2xvc2UgYW55IHRoYXQK
IGFyZSBhbHJlYWR5IG9wZW4uIFRoZSBgU25vb3plYCB3aWxsIHdvcmsgb24gYWxlcnRzIHRo
YXQgbWF0Y2ggdGhlCiBjcml0ZXJpYSBkZWZpbmVkIGluIHRoZSBgU25vb3plYC4gVGhlIGBT
bm9vemVgIHdpbGwgYmUgYWN0aXZlIGZyb20KIGBpbnRlcnZhbC5zdGFydF90aW1lYCB0aHJv
dWdoIGBpbnRlcnZhbC5lbmRfdGltZWAuCgoKCgMEAAESAyIIDgoLCgMEAAcSBCMCJgQKDQoF
BAAHnQgSBCMCJgQKvgEKBAQAAwASBCsCSAMarwEgQ3JpdGVyaWEgc3BlY2lmaWMgdG8gdGhl
IGBBbGVydFBvbGljeWBzIHRoYXQgdGhpcyBgU25vb3plYCBhcHBsaWVzIHRvLiBUaGUKIGBT
bm9vemVgIHdpbGwgc3VwcHJlc3MgYWxlcnRzIHRoYXQgY29tZSBmcm9tIG9uZSBvZiB0aGUg
YEFsZXJ0UG9saWN5YHMKIHdob3NlIG5hbWVzIGFyZSBzdXBwbGllZC4KCgwKBQQAAwABEgMr
ChIK1gIKBgQAAwACABIENQQ3BxrFAiBUaGUgc3BlY2lmaWMgYEFsZXJ0UG9saWN5YCBuYW1l
cyBmb3IgdGhlIGFsZXJ0IHRoYXQgc2hvdWxkIGJlIHNub296ZWQuCiBUaGUgZm9ybWF0IGlz
OgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL2FsZXJ0UG9saWNpZXMv
W1BPTElDWV9JRF0KCiBUaGVyZSBpcyBhIGxpbWl0IG9mIDE2IHBvbGljaWVzIHBlciBzbm9v
emUuIFRoaXMgbGltaXQgaXMgY2hlY2tlZCBkdXJpbmcKIHNub296ZSBjcmVhdGlvbi4KIEV4
YWN0bHkgMSBhbGVydCBwb2xpY3kgaXMgcmVxdWlyZWQgaWYgYGZpbHRlcmAgaXMgc3BlY2lm
aWVkIGF0IHRoZSBzYW1lCiB0aW1lLgoKDgoHBAADAAIABBIDNQQMCg4KBwQAAwACAAUSAzUN
EwoOCgcEAAMAAgABEgM1FBwKDgoHBAADAAIAAxIDNR8gCg8KBwQAAwACAAgSBDUhNwYKEQoJ
BAADAAIACJ8IEgQ1IjcFCuoFCgYEAAMAAgESA0cEFhraBSBPcHRpb25hbC4gVGhlIGZpbHRl
ciBzdHJpbmcgdG8gbWF0Y2ggb24gQWxlcnQgZmllbGRzIHdoZW4gc2lsZW5jaW5nIHRoZQog
YWxlcnRzLiBJdCBmb2xsb3dzIHRoZSBzdGFuZGFyZCBodHRwczovL2dvb2dsZS5haXAuZGV2
LzE2MCBzeW50YXguCiBBIGZpbHRlciBzdHJpbmcgdXNlZCB0byBhcHBseSB0aGUgc25vb3pl
IHRvIHNwZWNpZmljIGluY2lkZW50cwogdGhhdCBoYXZlIG1hdGNoaW5nIGZpbHRlciB2YWx1
ZXMuCiBGaWx0ZXJzIGNhbiBiZSBkZWZpbmVkIGZvciBzbm9vemVzIHRoYXQgYXBwbHkgdG8g
b25lIGFsZXJ0aW5nCiBwb2xpY3kuCiBGaWx0ZXJzIG11c3QgYmUgYSBzdHJpbmcgZm9ybWF0
dGVkIGFzIG9uZSBvciBtb3JlIHJlc291cmNlIGxhYmVscyB3aXRoCiBzcGVjaWZpYyBsYWJl
bCB2YWx1ZXMuIElmIG11bHRpcGxlIHJlc291cmNlIGxhYmVscyBhcmUgdXNlZCwgdGhlbiB0
aGV5CiBtdXN0IGJlIGNvbm5lY3RlZCB3aXRoIGFuIEFORCBvcGVyYXRvci4gRm9yIGV4YW1w
bGUsIHRoZSBmb2xsb3dpbmcgZmlsdGVyCiBhcHBsaWVzIHRoZSBzbm9vemUgdG8gaW5jaWRl
bnRzIHRoYXQgaGF2ZSBhbiBpbnN0YW5jZSBJRCBvZgogYDEyMzQ1Njc4OTBgIGFuZCBhIHpv
bmUgb2YgYHVzLWNlbnRyYWwxLWFgOgoKICAgICByZXNvdXJjZS5sYWJlbHMuaW5zdGFuY2Vf
aWQ9IjEyMzQ1Njc4OTAiIEFORAogICAgIHJlc291cmNlLmxhYmVscy56b25lPSJ1cy1jZW50
cmFsMS1hIgoKDgoHBAADAAIBBRIDRwQKCg4KBwQAAwACAQESA0cLEQoOCgcEAAMAAgEDEgNH
FBUKwgEKBAQAAgASA08CPRq0ASBSZXF1aXJlZC4gSWRlbnRpZmllci4gVGhlIG5hbWUgb2Yg
dGhlIGBTbm9vemVgLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9J
RF9PUl9OVU1CRVJdL3Nub296ZXMvW1NOT09aRV9JRF0KCiBUaGUgSUQgb2YgdGhlIGBTbm9v
emVgIHdpbGwgYmUgZ2VuZXJhdGVkIGJ5IHRoZSBzeXN0ZW0uCgoMCgUEAAIABRIDTwIICgwK
BQQAAgABEgNPCQ0KDAoFBAACAAMSA08QEQoMCgUEAAIACBIDTxI8Cg8KCAQAAgAInAgAEgNP
EzsKcwoEBAACARIDUwJBGmYgUmVxdWlyZWQuIFRoaXMgZGVmaW5lcyB0aGUgY3JpdGVyaWEg
Zm9yIGFwcGx5aW5nIHRoZSBgU25vb3plYC4gU2VlCiBgQ3JpdGVyaWFgIGZvciBtb3JlIGlu
Zm9ybWF0aW9uLgoKDAoFBAACAQYSA1MCCgoMCgUEAAIBARIDUwsTCgwKBQQAAgEDEgNTFhcK
DAoFBAACAQgSA1MYQAoPCggEAAIBCJwIABIDUxk/CosCCgQEAAICEgNaAkUa/QEgUmVxdWly
ZWQuIFRoZSBgU25vb3plYCB3aWxsIGJlIGFjdGl2ZSBmcm9tIGBpbnRlcnZhbC5zdGFydF90
aW1lYCB0aHJvdWdoCiBgaW50ZXJ2YWwuZW5kX3RpbWVgLgogYGludGVydmFsLnN0YXJ0X3Rp
bWVgIGNhbm5vdCBiZSBpbiB0aGUgcGFzdC4gVGhlcmUgaXMgYSAxNSBzZWNvbmQgY2xvY2sK
IHNrZXcgdG8gYWNjb3VudCBmb3IgdGhlIHRpbWUgaXQgdGFrZXMgZm9yIGEgcmVxdWVzdCB0
byByZWFjaCB0aGUgQVBJIGZyb20KIHRoZSBVSS4KCgwKBQQAAgIGEgNaAg4KDAoFBAACAgES
A1oPFwoMCgUEAAICAxIDWhobCgwKBQQAAgIIEgNaHEQKDwoIBAACAgicCAASA1odQwpoCgQE
AAIDEgNeAkMaWyBSZXF1aXJlZC4gQSBkaXNwbGF5IG5hbWUgZm9yIHRoZSBgU25vb3plYC4g
VGhpcyBjYW4gYmUsIGF0IG1vc3QsIDUxMgogdW5pY29kZSBjaGFyYWN0ZXJzLgoKDAoFBAAC
AwUSA14CCAoMCgUEAAIDARIDXgkVCgwKBQQAAgMDEgNeGBkKDAoFBAACAwgSA14aQgoPCggE
AAIDCJwIABIDXhtBYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::Snooze::Snooze ===
    # Fields for Snooze
    # Field: name Type: 9 ()
    # Field: criteria Type: 11 (.google.monitoring.v3.Snooze.Criteria)
    # Field: interval Type: 11 (.google.monitoring.v3.TimeInterval)
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::Snooze - Compiled Protocol Buffers messages for google/monitoring/v3/snooze.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::Snooze;

    my $msg = Google::Monitoring::V3::Snooze::Snooze->new({
        name => $name,
        criteria => $criteria,
        interval => $interval,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::Snooze::Snooze->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/snooze.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::Snooze::Snooze

A `Snooze` will prevent any alerts from being opened, and close any that
are already open. The `Snooze` will work on alerts that match the
criteria defined in the `Snooze`. The `Snooze` will be active from
`interval.start_time` through `interval.end_time`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Identifier. The name of the `Snooze`. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/snoozes/[SNOOZE_ID]

The ID of the `Snooze` will be generated by the system.

=item * C<< $msg->criteria() >> / C<< $msg->criteria($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Snooze::Snooze::Criteria>)

Required. This defines the criteria for applying the `Snooze`. See
`Criteria` for more information.

=item * C<< $msg->interval() >> / C<< $msg->interval($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Common::TimeInterval>)

Required. The `Snooze` will be active from `interval.start_time` through
`interval.end_time`.
`interval.start_time` cannot be in the past. There is a 15 second clock
skew to account for the time it takes for a request to reach the API from
the UI.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. A display name for the `Snooze`. This can be, at most, 512
unicode characters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::Snooze::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
