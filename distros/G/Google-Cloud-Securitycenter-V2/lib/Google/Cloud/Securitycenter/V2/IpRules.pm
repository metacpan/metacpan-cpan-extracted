package Google::Cloud::Securitycenter::V2::IpRules;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvaXBfcnVsZXMucHJvdG8SHmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90byK0AwoHSXBSdWxlcxJPCglkaXJlY3Rpb24YASABKA4yMS5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjIuSXBSdWxlcy5EaXJlY3Rpb25SCWRpcmVjdGlvbhJDCgdhbGxvd2Vk
GAIgASgLMicuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLkFsbG93ZWRIAFIHYWxs
b3dlZBJACgZkZW5pZWQYAyABKAsyJi5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIu
RGVuaWVkSABSBmRlbmllZBIoChBzb3VyY2VfaXBfcmFuZ2VzGAQgAygJUg5zb3VyY2VJcFJh
bmdlcxIyChVkZXN0aW5hdGlvbl9pcF9yYW5nZXMYBSADKAlSE2Rlc3RpbmF0aW9uSXBSYW5n
ZXMSKQoQZXhwb3NlZF9zZXJ2aWNlcxgGIAMoCVIPZXhwb3NlZFNlcnZpY2VzIj8KCURpcmVj
dGlvbhIZChVESVJFQ1RJT05fVU5TUEVDSUZJRUQQABILCgdJTkdSRVNTEAESCgoGRUdSRVNT
EAJCBwoFcnVsZXMirQEKBklwUnVsZRIaCghwcm90b2NvbBgBIAEoCVIIcHJvdG9jb2wSVgoL
cG9ydF9yYW5nZXMYAiADKAsyMC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuSXBS
dWxlLlBvcnRSYW5nZUID4EEBUgpwb3J0UmFuZ2VzGi8KCVBvcnRSYW5nZRIQCgNtaW4YASAB
KANSA21pbhIQCgNtYXgYAiABKANSA21heCJRCgdBbGxvd2VkEkYKCGlwX3J1bGVzGAEgAygL
MiYuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLklwUnVsZUID4EEBUgdpcFJ1bGVz
IlAKBkRlbmllZBJGCghpcF9ydWxlcxgBIAMoCzImLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52Mi5JcFJ1bGVCA+BBAVIHaXBSdWxlc0LmAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1
cml0eWNlbnRlci52MkIMSXBSdWxlc1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2Vj
dXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIe
R29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5
Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySu8eCgYSBA4A
awEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwAS
AxIAKQoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEIEgMYADsKCQoCCAESAxgA
OwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgozCgIEABIEHQBG
ARonIElQIHJ1bGVzIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmluZGluZy4KCgoKAwQAARIDHQgP
CogBCgQEAAQAEgQgAikDGnogVGhlIHR5cGUgb2YgZGlyZWN0aW9uIHRoYXQgdGhlIHJ1bGUg
aXMgYXBwbGljYWJsZSB0bywgb25lIG9mIGluZ3Jlc3Mgb3IKIGVncmVzcy4gTm90IGFwcGxp
Y2FibGUgdG8gT1BFTl9YX1BPUlQgZmluZGluZ3MuCgoMCgUEAAQAARIDIAcQCi0KBgQABAAC
ABIDIgQeGh4gVW5zcGVjaWZpZWQgZGlyZWN0aW9uIHZhbHVlLgoKDgoHBAAEAAIAARIDIgQZ
Cg4KBwQABAACAAISAyIcHQopCgYEAAQAAgESAyUEEBoaIEluZ3Jlc3MgZGlyZWN0aW9uIHZh
bHVlLgoKDgoHBAAEAAIBARIDJQQLCg4KBwQABAACAQISAyUODwooCgYEAAQAAgISAygEDxoZ
IEVncmVzcyBkaXJlY3Rpb24gdmFsdWUuCgoOCgcEAAQAAgIBEgMoBAoKDgoHBAAEAAICAhID
KA0OClYKBAQAAgASAywCGhpJIFRoZSBkaXJlY3Rpb24gdGhhdCB0aGUgcnVsZSBpcyBhcHBs
aWNhYmxlIHRvLCBvbmUgb2YgaW5ncmVzcyBvciBlZ3Jlc3MuCgoMCgUEAAIABhIDLAILCgwK
BQQAAgABEgMsDBUKDAoFBAACAAMSAywYGQqgAQoEBAAIABIEMAI2AxqRASBUaGUgbGlzdCBv
ZiBhbGxvdyBydWxlcyBzcGVjaWZpZWQgYnkgdGhpcyBmaXJld2FsbC4gRWFjaCBydWxlIHNw
ZWNpZmllcyBhCiBwcm90b2NvbCBhbmQgcG9ydC1yYW5nZSB0dXBsZSB0aGF0IGRlc2NyaWJl
cyBhIHBlcm1pdHRlZCBjb25uZWN0aW9uLgoKDAoFBAAIAAESAzAIDQooCgQEAAIBEgMyBBga
GyBUdXBsZSB3aXRoIGFsbG93ZWQgcnVsZXMuCgoMCgUEAAIBBhIDMgQLCgwKBQQAAgEBEgMy
DBMKDAoFBAACAQMSAzIWFwonCgQEAAICEgM1BBYaGiBUdXBsZSB3aXRoIGRlbmllZCBydWxl
cy4KCgwKBQQAAgIGEgM1BAoKDAoFBAACAgESAzULEQoMCgUEAAICAxIDNRQVCs8BCgQEAAID
EgM7AicawQEgSWYgc291cmNlIElQIHJhbmdlcyBhcmUgc3BlY2lmaWVkLCB0aGUgZmlyZXdh
bGwgcnVsZSBhcHBsaWVzIG9ubHkgdG8KIHRyYWZmaWMgdGhhdCBoYXMgYSBzb3VyY2UgSVAg
YWRkcmVzcyBpbiB0aGVzZSByYW5nZXMuIFRoZXNlIHJhbmdlcyBtdXN0IGJlCiBleHByZXNz
ZWQgaW4gQ0lEUiBmb3JtYXQuIE9ubHkgc3VwcG9ydHMgSVB2NC4KCgwKBQQAAgMEEgM7AgoK
DAoFBAACAwUSAzsLEQoMCgUEAAIDARIDOxIiCgwKBQQAAgMDEgM7JSYK2QEKBAQAAgQSA0AC
LBrLASBJZiBkZXN0aW5hdGlvbiBJUCByYW5nZXMgYXJlIHNwZWNpZmllZCwgdGhlIGZpcmV3
YWxsIHJ1bGUgYXBwbGllcyBvbmx5IHRvCiB0cmFmZmljIHRoYXQgaGFzIGEgZGVzdGluYXRp
b24gSVAgYWRkcmVzcyBpbiB0aGVzZSByYW5nZXMuIFRoZXNlIHJhbmdlcwogbXVzdCBiZSBl
eHByZXNzZWQgaW4gQ0lEUiBmb3JtYXQuIE9ubHkgc3VwcG9ydHMgSVB2NC4KCgwKBQQAAgQE
EgNAAgoKDAoFBAACBAUSA0ALEQoMCgUEAAIEARIDQBInCgwKBQQAAgQDEgNAKisK8AEKBAQA
AgUSA0UCJxriASBOYW1lIG9mIHRoZSBuZXR3b3JrIHByb3RvY29sIHNlcnZpY2UsIHN1Y2gg
YXMgRlRQLCB0aGF0IGlzIGV4cG9zZWQgYnkgdGhlCiBvcGVuIHBvcnQuIEZvbGxvd3MgdGhl
IG5hbWluZyBjb252ZW50aW9uIGF2YWlsYWJsZSBhdDoKIGh0dHBzOi8vd3d3LmlhbmEub3Jn
L2Fzc2lnbm1lbnRzL3NlcnZpY2UtbmFtZXMtcG9ydC1udW1iZXJzL3NlcnZpY2UtbmFtZXMt
cG9ydC1udW1iZXJzLnhodG1sLgoKDAoFBAACBQQSA0UCCgoMCgUEAAIFBRIDRQsRCgwKBQQA
AgUBEgNFEiIKDAoFBAACBQMSA0UlJgoiCgIEARIESQBfARoWIElQIHJ1bGUgaW5mb3JtYXRp
b24uCgoKCgMEAQESA0kIDgrwAQoEBAEDABIETgJUAxrhASBBIHBvcnQgcmFuZ2Ugd2hpY2gg
aXMgaW5jbHVzaXZlIG9mIHRoZSBtaW4gYW5kIG1heCB2YWx1ZXMuCiBWYWx1ZXMgYXJlIGJl
dHdlZW4gMCBhbmQgMl4xNi0xLiBUaGUgbWF4IGNhbiBiZSBlcXVhbCAvIG11c3QgYmUgbm90
IHNtYWxsZXIKIHRoYW4gdGhlIG1pbiB2YWx1ZS4gSWYgbWluIGFuZCBtYXggYXJlIGVxdWFs
IHRoaXMgaW5kaWNhdGVzIHRoYXQgaXQgaXMgYQogc2luZ2xlIHBvcnQuCgoMCgUEAQMAARID
TgoTCiQKBgQBAwACABIDUAQSGhUgTWluaW11bSBwb3J0IHZhbHVlLgoKDgoHBAEDAAIABRID
UAQJCg4KBwQBAwACAAESA1AKDQoOCgcEAQMAAgADEgNQEBEKJAoGBAEDAAIBEgNTBBIaFSBN
YXhpbXVtIHBvcnQgdmFsdWUuCgoOCgcEAQMAAgEFEgNTBAkKDgoHBAEDAAIBARIDUwoNCg4K
BwQBAwACAQMSA1MQEQrYAQoEBAECABIDWQIWGsoBIFRoZSBJUCBwcm90b2NvbCB0aGlzIHJ1
bGUgYXBwbGllcyB0by4gVGhpcyB2YWx1ZSBjYW4gZWl0aGVyIGJlIG9uZSBvZiB0aGUKIGZv
bGxvd2luZyB3ZWxsIGtub3duIHByb3RvY29sIHN0cmluZ3MgKFRDUCwgVURQLCBJQ01QLCBF
U1AsIEFILCBJUElQLAogU0NUUCkgb3IgYSBzdHJpbmcgcmVwcmVzZW50YXRpb24gb2YgdGhl
IGludGVnZXIgdmFsdWUuCgoMCgUEAQIABRIDWQIICgwKBQQBAgABEgNZCREKDAoFBAECAAMS
A1kUFQrlAQoEBAECARIDXgJOGtcBIE9wdGlvbmFsLiBBbiBvcHRpb25hbCBsaXN0IG9mIHBv
cnRzIHRvIHdoaWNoIHRoaXMgcnVsZSBhcHBsaWVzLiBUaGlzIGZpZWxkCiBpcyBvbmx5IGFw
cGxpY2FibGUgZm9yIHRoZSBVRFAgb3IgKFMpVENQIHByb3RvY29scy4gRWFjaCBlbnRyeSBt
dXN0IGJlCiBlaXRoZXIgYW4gaW50ZWdlciBvciBhIHJhbmdlIGluY2x1ZGluZyBhIG1pbiBh
bmQgbWF4IHBvcnQgbnVtYmVyLgoKDAoFBAECAQQSA14CCgoMCgUEAQIBBhIDXgsUCgwKBQQB
AgEBEgNeFSAKDAoFBAECAQMSA14jJAoMCgUEAQIBCBIDXiVNCg8KCAQBAgEInAgAEgNeJkwK
HgoCBAISBGIAZQEaEiBBbGxvd2VkIElQIHJ1bGUuCgoKCgMEAgESA2IIDwo7CgQEAgIAEgNk
AkgaLiBPcHRpb25hbC4gT3B0aW9uYWwgbGlzdCBvZiBhbGxvd2VkIElQIHJ1bGVzLgoKDAoF
BAICAAQSA2QCCgoMCgUEAgIABhIDZAsRCgwKBQQCAgABEgNkEhoKDAoFBAICAAMSA2QdHgoM
CgUEAgIACBIDZB9HCg8KCAQCAgAInAgAEgNkIEYKHQoCBAMSBGgAawEaESBEZW5pZWQgSVAg
cnVsZS4KCgoKAwQDARIDaAgOCjoKBAQDAgASA2oCSBotIE9wdGlvbmFsLiBPcHRpb25hbCBs
aXN0IG9mIGRlbmllZCBJUCBydWxlcy4KCgwKBQQDAgAEEgNqAgoKDAoFBAMCAAYSA2oLEQoM
CgUEAwIAARIDahIaCgwKBQQDAgADEgNqHR4KDAoFBAMCAAgSA2ofRwoPCggEAwIACJwIABID
aiBGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::IpRules::IpRules ===
    # Fields for IpRules
    # Field: direction Type: 14 (.google.cloud.securitycenter.v2.IpRules.Direction)
    # Field: allowed Type: 11 (.google.cloud.securitycenter.v2.Allowed)
    # Field: denied Type: 11 (.google.cloud.securitycenter.v2.Denied)
    # Field: source_ip_ranges Type: 9 ()
    # Field: destination_ip_ranges Type: 9 ()
    # Field: exposed_services Type: 9 ()

# Enum: IpRules::Direction
our $IpRules_DIRECTION_UNSPECIFIED = 0;
our $IpRules_INGRESS = 1;
our $IpRules_EGRESS = 2;

# === Message: Google::Cloud::Securitycenter::V2::IpRules::IpRule ===
    # Fields for IpRule
    # Field: protocol Type: 9 ()
    # Field: port_ranges Type: 11 (.google.cloud.securitycenter.v2.IpRule.PortRange)

# === Message: Google::Cloud::Securitycenter::V2::IpRules::Allowed ===
    # Fields for Allowed
    # Field: ip_rules Type: 11 (.google.cloud.securitycenter.v2.IpRule)

# === Message: Google::Cloud::Securitycenter::V2::IpRules::Denied ===
    # Fields for Denied
    # Field: ip_rules Type: 11 (.google.cloud.securitycenter.v2.IpRule)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::IpRules - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/ip_rules.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::IpRules;

    my $msg = Google::Cloud::Securitycenter::V2::IpRules::IpRules->new({
        direction => $direction,
        allowed => $allowed,
        denied => $denied,
        source_ip_ranges => $source_ip_ranges,
    });

    # Read or update a field
    my $val = $msg->direction();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::IpRules::IpRules->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/ip_rules.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::IpRules::IpRules

IP rules associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::IpRules::Direction>)

The direction that the rule is applicable to, one of ingress or egress.

=item * C<< $msg->allowed() >> / C<< $msg->allowed($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::IpRules::Allowed>)

Tuple with allowed rules.

=item * C<< $msg->denied() >> / C<< $msg->denied($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::IpRules::Denied>)

Tuple with denied rules.

=item * C<< $msg->source_ip_ranges() >> / C<< $msg->source_ip_ranges($value) >>

Type: C<String>

If source IP ranges are specified, the firewall rule applies only to
traffic that has a source IP address in these ranges. These ranges must be
expressed in CIDR format. Only supports IPv4.

=item * C<< $msg->destination_ip_ranges() >> / C<< $msg->destination_ip_ranges($value) >>

Type: C<String>

If destination IP ranges are specified, the firewall rule applies only to
traffic that has a destination IP address in these ranges. These ranges
must be expressed in CIDR format. Only supports IPv4.

=item * C<< $msg->exposed_services() >> / C<< $msg->exposed_services($value) >>

Type: C<String>

Name of the network protocol service, such as FTP, that is exposed by the
open port. Follows the naming convention available at:
https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml.

=back

=head3 Enum: IpRules::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<INGRESS> => C<1>

=item * C<EGRESS> => C<2>

=back

=head2 Google::Cloud::Securitycenter::V2::IpRules::IpRule

IP rule information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->protocol() >> / C<< $msg->protocol($value) >>

Type: C<String>

The IP protocol this rule applies to. This value can either be one of the
following well known protocol strings (TCP, UDP, ICMP, ESP, AH, IPIP,
SCTP) or a string representation of the integer value.

=item * C<< $msg->port_ranges() >> / C<< $msg->port_ranges($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::IpRules::IpRule::PortRange>)

Optional. An optional list of ports to which this rule applies. This field
is only applicable for the UDP or (S)TCP protocols. Each entry must be
either an integer or a range including a min and max port number.

=back

=head2 Google::Cloud::Securitycenter::V2::IpRules::Allowed

Allowed IP rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ip_rules() >> / C<< $msg->ip_rules($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::IpRules::IpRule>)

Optional. Optional list of allowed IP rules.

=back

=head2 Google::Cloud::Securitycenter::V2::IpRules::Denied

Denied IP rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ip_rules() >> / C<< $msg->ip_rules($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::IpRules::IpRule>)

Optional. Optional list of denied IP rules.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::IpRules::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
