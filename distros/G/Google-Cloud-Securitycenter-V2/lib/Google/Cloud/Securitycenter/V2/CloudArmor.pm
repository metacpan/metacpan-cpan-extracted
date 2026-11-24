package Google::Cloud::Securitycenter::V2::CloudArmor;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvY2xvdWRfYXJtb3IucHJvdG8SHmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9u
LnByb3RvIqwDCgpDbG91ZEFybW9yElcKD3NlY3VyaXR5X3BvbGljeRgBIAEoCzIuLmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5TZWN1cml0eVBvbGljeVIOc2VjdXJpdHlQb2xp
Y3kSRAoIcmVxdWVzdHMYAiABKAsyKC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIu
UmVxdWVzdHNSCHJlcXVlc3RzEmMKE2FkYXB0aXZlX3Byb3RlY3Rpb24YAyABKAsyMi5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQWRhcHRpdmVQcm90ZWN0aW9uUhJhZGFwdGl2
ZVByb3RlY3Rpb24SPgoGYXR0YWNrGAQgASgLMiYuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2Vu
dGVyLnYyLkF0dGFja1IGYXR0YWNrEiMKDXRocmVhdF92ZWN0b3IYBSABKAlSDHRocmVhdFZl
Y3RvchI1CghkdXJhdGlvbhgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIIZHVy
YXRpb24iUgoOU2VjdXJpdHlQb2xpY3kSEgoEbmFtZRgBIAEoCVIEbmFtZRISCgR0eXBlGAIg
ASgJUgR0eXBlEhgKB3ByZXZpZXcYAyABKAhSB3ByZXZpZXcipAEKCFJlcXVlc3RzEhQKBXJh
dGlvGAEgASgBUgVyYXRpbxIsChJzaG9ydF90ZXJtX2FsbG93ZWQYAiABKAVSEHNob3J0VGVy
bUFsbG93ZWQSKgoRbG9uZ190ZXJtX2FsbG93ZWQYAyABKAVSD2xvbmdUZXJtQWxsb3dlZBIo
ChBsb25nX3Rlcm1fZGVuaWVkGAQgASgFUg5sb25nVGVybURlbmllZCI0ChJBZGFwdGl2ZVBy
b3RlY3Rpb24SHgoKY29uZmlkZW5jZRgBIAEoAVIKY29uZmlkZW5jZSLGAQoGQXR0YWNrEiYK
D3ZvbHVtZV9wcHNfbG9uZxgEIAEoA1INdm9sdW1lUHBzTG9uZxImCg92b2x1bWVfYnBzX2xv
bmcYBSABKANSDXZvbHVtZUJwc0xvbmcSJgoOY2xhc3NpZmljYXRpb24YAyABKAlSDmNsYXNz
aWZpY2F0aW9uEiEKCnZvbHVtZV9wcHMYASABKAVCAhgBUgl2b2x1bWVQcHMSIQoKdm9sdW1l
X2JwcxgCIAEoBUICGAFSCXZvbHVtZUJwc0LpAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0
eWNlbnRlci52MkIPQ2xvdWRBcm1vclByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2Vj
dXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIe
R29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5
Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySoMlCgYSBA4A
eQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
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
AxIAKAoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYADsKCQoCCAESAxgA
OwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgo8CgIEABIEHQA4
ARowIEZpZWxkcyByZWxhdGVkIHRvIEdvb2dsZSBDbG91ZCBBcm1vciBmaW5kaW5ncy4KCgoK
AwQAARIDHQgSCqMBCgQEAAIAEgMhAiUalQEgSW5mb3JtYXRpb24gYWJvdXQgdGhlIFtHb29n
bGUgQ2xvdWQgQXJtb3Igc2VjdXJpdHkKIHBvbGljeV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FybW9yL2RvY3Mvc2VjdXJpdHktcG9saWN5LW92ZXJ2aWV3KQogcmVsZXZhbnQgdG8g
dGhlIGZpbmRpbmcuCgoMCgUEAAIABhIDIQIQCgwKBQQAAgABEgMhESAKDAoFBAACAAMSAyEj
JAqoAQoEBAACARIDJgIYGpoBIEluZm9ybWF0aW9uIGFib3V0IGluY29taW5nIHJlcXVlc3Rz
IGV2YWx1YXRlZCBieSBbR29vZ2xlIENsb3VkIEFybW9yCiBzZWN1cml0eQogcG9saWNpZXNd
KGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcm1vci9kb2NzL3NlY3VyaXR5LXBvbGljeS1v
dmVydmlldykuCgoMCgUEAAIBBhIDJgIKCgwKBQQAAgEBEgMmCxMKDAoFBAACAQMSAyYWFwq8
AQoEBAACAhIDKwItGq4BIEluZm9ybWF0aW9uIGFib3V0IHBvdGVudGlhbCBMYXllciA3IERE
b1MgYXR0YWNrcyBpZGVudGlmaWVkIGJ5IFtHb29nbGUKIENsb3VkIEFybW9yIEFkYXB0aXZl
CiBQcm90ZWN0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXJtb3IvZG9jcy9hZGFw
dGl2ZS1wcm90ZWN0aW9uLW92ZXJ2aWV3KS4KCgwKBQQAAgIGEgMrAhQKDAoFBAACAgESAysV
KAoMCgUEAAICAxIDKyssCkcKBAQAAgMSAy4CFBo6IEluZm9ybWF0aW9uIGFib3V0IEREb1Mg
YXR0YWNrIHZvbHVtZSBhbmQgY2xhc3NpZmljYXRpb24uCgoMCgUEAAIDBhIDLgIICgwKBQQA
AgMBEgMuCQ8KDAoFBAACAwMSAy4SEwrDAQoEBAACBBIDMwIbGrUBIERpc3Rpbmd1aXNoIGJl
dHdlZW4gdm9sdW1ldHJpYyAmIHByb3RvY29sIEREb1MgYXR0YWNrIGFuZAogYXBwbGljYXRp
b24gbGF5ZXIgYXR0YWNrcy4gRm9yIGV4YW1wbGUsICJMM180IiBmb3IgTGF5ZXIgMyBhbmQg
TGF5ZXIgNCBERG9TCiBhdHRhY2tzLCBvciAiTF83IiBmb3IgTGF5ZXIgNyBERG9TIGF0dGFj
a3MuCgoMCgUEAAIEBRIDMwIICgwKBQQAAgQBEgMzCRYKDAoFBAACBAMSAzMZGgplCgQEAAIF
EgM3AigaWCBEdXJhdGlvbiBvZiBhdHRhY2sgZnJvbSB0aGUgc3RhcnQgdW50aWwgdGhlIGN1
cnJlbnQgbW9tZW50ICh1cGRhdGVkIGV2ZXJ5IDUKIG1pbnV0ZXMpLgoKDAoFBAACBQYSAzcC
GgoMCgUEAAIFARIDNxsjCgwKBQQAAgUDEgM3JicKogEKAgQBEgQ9AEkBGpUBIEluZm9ybWF0
aW9uIGFib3V0IHRoZSBbR29vZ2xlIENsb3VkIEFybW9yIHNlY3VyaXR5CiBwb2xpY3ldKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcm1vci9kb2NzL3NlY3VyaXR5LXBvbGljeS1vdmVy
dmlldykKIHJlbGV2YW50IHRvIHRoZSBmaW5kaW5nLgoKCgoDBAEBEgM9CBYKZgoEBAECABID
QAISGlkgVGhlIG5hbWUgb2YgdGhlIEdvb2dsZSBDbG91ZCBBcm1vciBzZWN1cml0eSBwb2xp
Y3ksIGZvciBleGFtcGxlLAogIm15LXNlY3VyaXR5LXBvbGljeSIuCgoMCgUEAQIABRIDQAII
CgwKBQQBAgABEgNACQ0KDAoFBAECAAMSA0AQEQrAAQoEBAECARIDRQISGrIBIFRoZSB0eXBl
IG9mIEdvb2dsZSBDbG91ZCBBcm1vciBzZWN1cml0eSBwb2xpY3kgZm9yIGV4YW1wbGUsICdi
YWNrZW5kCiBzZWN1cml0eSBwb2xpY3knLCAnZWRnZSBzZWN1cml0eSBwb2xpY3knLCAnbmV0
d29yayBlZGdlIHNlY3VyaXR5IHBvbGljeScsCiBvciAnYWx3YXlzLW9uIEREb1MgcHJvdGVj
dGlvbicuCgoMCgUEAQIBBRIDRQIICgwKBQQBAgEBEgNFCQ0KDAoFBAECAQMSA0UQEQpPCgQE
AQICEgNIAhMaQiBXaGV0aGVyIG9yIG5vdCB0aGUgYXNzb2NpYXRlZCBydWxlIG9yIHBvbGlj
eSBpcyBpbiBwcmV2aWV3IG1vZGUuCgoMCgUEAQICBRIDSAIGCgwKBQQBAgIBEgNIBw4KDAoF
BAECAgMSA0gREgpFCgIEAhIETABaARo5IEluZm9ybWF0aW9uIGFib3V0IHRoZSByZXF1ZXN0
cyByZWxldmFudCB0byB0aGUgZmluZGluZy4KCgoKAwQCARIDTAgQCusBCgQEAgIAEgNQAhMa
3QEgRm9yICdJbmNyZWFzaW5nIGRlbnkgcmF0aW8nLCB0aGUgcmF0aW8gaXMgdGhlIGRlbmll
ZCB0cmFmZmljIGRpdmlkZWQgYnkgdGhlCiBhbGxvd2VkIHRyYWZmaWMuIEZvciAnQWxsb3dl
ZCB0cmFmZmljIHNwaWtlJywgdGhlIHJhdGlvIGlzIHRoZSBhbGxvd2VkCiB0cmFmZmljIGlu
IHRoZSBzaG9ydCB0ZXJtIGRpdmlkZWQgYnkgYWxsb3dlZCB0cmFmZmljIGluIHRoZSBsb25n
IHRlcm0uCgoMCgUEAgIABRIDUAIICgwKBQQCAgABEgNQCQ4KDAoFBAICAAMSA1AREgpDCgQE
AgIBEgNTAh8aNiBBbGxvd2VkIFJQUyAocmVxdWVzdHMgcGVyIHNlY29uZCkgaW4gdGhlIHNo
b3J0IHRlcm0uCgoMCgUEAgIBBRIDUwIHCgwKBQQCAgEBEgNTCBoKDAoFBAICAQMSA1MdHgpE
CgQEAgICEgNWAh4aNyBBbGxvd2VkIFJQUyAocmVxdWVzdHMgcGVyIHNlY29uZCkgb3ZlciB0
aGUgbG9uZyB0ZXJtLgoKDAoFBAICAgUSA1YCBwoMCgUEAgICARIDVggZCgwKBQQCAgIDEgNW
HB0KQwoEBAICAxIDWQIdGjYgRGVuaWVkIFJQUyAocmVxdWVzdHMgcGVyIHNlY29uZCkgb3Zl
ciB0aGUgbG9uZyB0ZXJtLgoKDAoFBAICAwUSA1kCBwoMCgUEAgIDARIDWQgYCgwKBQQCAgMD
EgNZGxwKrAEKAgQDEgReAGUBGp8BIEluZm9ybWF0aW9uIGFib3V0IFtHb29nbGUgQ2xvdWQg
QXJtb3IgQWRhcHRpdmUKIFByb3RlY3Rpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9h
cm1vci9kb2NzL2Nsb3VkLWFybW9yLW92ZXJ2aWV3I2dvb2dsZS1jbG91ZC1hcm1vci1hZGFw
dGl2ZS1wcm90ZWN0aW9uKS4KCgoKAwQDARIDXggaCuUCCgQEAwIAEgNkAhga1wIgQSBzY29y
ZSBvZiAwIG1lYW5zIHRoYXQgdGhlcmUgaXMgbG93IGNvbmZpZGVuY2UgdGhhdCB0aGUgZGV0
ZWN0ZWQgZXZlbnQgaXMKIGFuIGFjdHVhbCBhdHRhY2suIEEgc2NvcmUgb2YgMSBtZWFucyB0
aGF0IHRoZXJlIGlzIGhpZ2ggY29uZmlkZW5jZSB0aGF0IHRoZQogZGV0ZWN0ZWQgZXZlbnQg
aXMgYW4gYXR0YWNrLiBTZWUgdGhlIFtBZGFwdGl2ZSBQcm90ZWN0aW9uCiBkb2N1bWVudGF0
aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXJtb3IvZG9jcy9hZGFwdGl2ZS1wcm90
ZWN0aW9uLW92ZXJ2aWV3I2NvbmZpZ3VyZS1hbGVydC10dW5pbmcpCiBmb3IgZnVydGhlciBl
eHBsYW5hdGlvbi4KCgwKBQQDAgAFEgNkAggKDAoFBAMCAAESA2QJEwoMCgUEAwIAAxIDZBYX
CkYKAgQEEgRoAHkBGjogSW5mb3JtYXRpb24gYWJvdXQgRERvUyBhdHRhY2sgdm9sdW1lIGFu
ZCBjbGFzc2lmaWNhdGlvbi4KCgoKAwQEARIDaAgOCj8KBAQEAgASA2oCHBoyIFRvdGFsIFBQ
UyAocGFja2V0cyBwZXIgc2Vjb25kKSB2b2x1bWUgb2YgYXR0YWNrLgoKDAoFBAQCAAUSA2oC
BwoMCgUEBAIAARIDaggXCgwKBQQEAgADEgNqGhsKPQoEBAQCARIDbQIcGjAgVG90YWwgQlBT
IChieXRlcyBwZXIgc2Vjb25kKSB2b2x1bWUgb2YgYXR0YWNrLgoKDAoFBAQCAQUSA20CBwoM
CgUEBAIBARIDbQgXCgwKBQQEAgEDEgNtGhsKVQoEBAQCAhIDcAIcGkggVHlwZSBvZiBhdHRh
Y2ssIGZvciBleGFtcGxlLCAnU1lOLWZsb29kJywgJ05UUC11ZHAnLCBvciAnQ0hBUkdFTi11
ZHAnLgoKDAoFBAQCAgUSA3ACCAoMCgUEBAICARIDcAkXCgwKBQQEAgIDEgNwGhsKbwoEBAQC
AxIDdAIrGmIgVG90YWwgUFBTIChwYWNrZXRzIHBlciBzZWNvbmQpIHZvbHVtZSBvZiBhdHRh
Y2suIERlcHJlY2F0ZWQgLSByZWZlciB0bwogdm9sdW1lX3Bwc19sb25nIGluc3RlYWQuCgoM
CgUEBAIDBRIDdAIHCgwKBQQEAgMBEgN0CBIKDAoFBAQCAwMSA3QVFgoMCgUEBAIDCBIDdBcq
Cg0KBgQEAgMIAxIDdBgpCm0KBAQEAgQSA3gCKxpgIFRvdGFsIEJQUyAoYnl0ZXMgcGVyIHNl
Y29uZCkgdm9sdW1lIG9mIGF0dGFjay4gRGVwcmVjYXRlZCAtIHJlZmVyIHRvCiB2b2x1bWVf
YnBzX2xvbmcgaW5zdGVhZC4KCgwKBQQEAgQFEgN4AgcKDAoFBAQCBAESA3gIEgoMCgUEBAIE
AxIDeBUWCgwKBQQEAgQIEgN4FyoKDQoGBAQCBAgDEgN4GCliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::CloudArmor::CloudArmor ===
    # Fields for CloudArmor
    # Field: security_policy Type: 11 (.google.cloud.securitycenter.v2.SecurityPolicy)
    # Field: requests Type: 11 (.google.cloud.securitycenter.v2.Requests)
    # Field: adaptive_protection Type: 11 (.google.cloud.securitycenter.v2.AdaptiveProtection)
    # Field: attack Type: 11 (.google.cloud.securitycenter.v2.Attack)
    # Field: threat_vector Type: 9 ()
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Securitycenter::V2::CloudArmor::SecurityPolicy ===
    # Fields for SecurityPolicy
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: preview Type: 8 ()

# === Message: Google::Cloud::Securitycenter::V2::CloudArmor::Requests ===
    # Fields for Requests
    # Field: ratio Type: 1 ()
    # Field: short_term_allowed Type: 5 ()
    # Field: long_term_allowed Type: 5 ()
    # Field: long_term_denied Type: 5 ()

# === Message: Google::Cloud::Securitycenter::V2::CloudArmor::AdaptiveProtection ===
    # Fields for AdaptiveProtection
    # Field: confidence Type: 1 ()

# === Message: Google::Cloud::Securitycenter::V2::CloudArmor::Attack ===
    # Fields for Attack
    # Field: volume_pps_long Type: 3 ()
    # Field: volume_bps_long Type: 3 ()
    # Field: classification Type: 9 ()
    # Field: volume_pps Type: 5 ()
    # Field: volume_bps Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::CloudArmor - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/cloud_armor.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::CloudArmor;

    my $msg = Google::Cloud::Securitycenter::V2::CloudArmor::CloudArmor->new({
        security_policy => $security_policy,
        requests => $requests,
        adaptive_protection => $adaptive_protection,
        attack => $attack,
    });

    # Read or update a field
    my $val = $msg->security_policy();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::CloudArmor::CloudArmor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/cloud_armor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::CloudArmor::CloudArmor

Fields related to Google Cloud Armor findings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security_policy() >> / C<< $msg->security_policy($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::CloudArmor::SecurityPolicy>)

Information about the [Google Cloud Armor security
policy](https://cloud.google.com/armor/docs/security-policy-overview)
relevant to the finding.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::CloudArmor::Requests>)

Information about incoming requests evaluated by [Google Cloud Armor
security
policies](https://cloud.google.com/armor/docs/security-policy-overview).

=item * C<< $msg->adaptive_protection() >> / C<< $msg->adaptive_protection($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::CloudArmor::AdaptiveProtection>)

Information about potential Layer 7 DDoS attacks identified by [Google
Cloud Armor Adaptive
Protection](https://cloud.google.com/armor/docs/adaptive-protection-overview).

=item * C<< $msg->attack() >> / C<< $msg->attack($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::CloudArmor::Attack>)

Information about DDoS attack volume and classification.

=item * C<< $msg->threat_vector() >> / C<< $msg->threat_vector($value) >>

Type: C<String>

Distinguish between volumetric & protocol DDoS attack and
application layer attacks. For example, "L3_4" for Layer 3 and Layer 4 DDoS
attacks, or "L_7" for Layer 7 DDoS attacks.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration of attack from the start until the current moment (updated every 5
minutes).

=back

=head2 Google::Cloud::Securitycenter::V2::CloudArmor::SecurityPolicy

Information about the [Google Cloud Armor security
policy](https://cloud.google.com/armor/docs/security-policy-overview)
relevant to the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the Google Cloud Armor security policy, for example,
"my-security-policy".

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of Google Cloud Armor security policy for example, 'backend
security policy', 'edge security policy', 'network edge security policy',
or 'always-on DDoS protection'.

=item * C<< $msg->preview() >> / C<< $msg->preview($value) >>

Type: C<Bool>

Whether or not the associated rule or policy is in preview mode.

=back

=head2 Google::Cloud::Securitycenter::V2::CloudArmor::Requests

Information about the requests relevant to the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ratio() >> / C<< $msg->ratio($value) >>

Type: C<Double>

For 'Increasing deny ratio', the ratio is the denied traffic divided by the
allowed traffic. For 'Allowed traffic spike', the ratio is the allowed
traffic in the short term divided by allowed traffic in the long term.

=item * C<< $msg->short_term_allowed() >> / C<< $msg->short_term_allowed($value) >>

Type: C<Int32>

Allowed RPS (requests per second) in the short term.

=item * C<< $msg->long_term_allowed() >> / C<< $msg->long_term_allowed($value) >>

Type: C<Int32>

Allowed RPS (requests per second) over the long term.

=item * C<< $msg->long_term_denied() >> / C<< $msg->long_term_denied($value) >>

Type: C<Int32>

Denied RPS (requests per second) over the long term.

=back

=head2 Google::Cloud::Securitycenter::V2::CloudArmor::AdaptiveProtection

Information about [Google Cloud Armor Adaptive
Protection](https://cloud.google.com/armor/docs/cloud-armor-overview#google-cloud-armor-adaptive-protection).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Double>

A score of 0 means that there is low confidence that the detected event is
an actual attack. A score of 1 means that there is high confidence that the
detected event is an attack. See the [Adaptive Protection
documentation](https://cloud.google.com/armor/docs/adaptive-protection-overview#configure-alert-tuning)
for further explanation.

=back

=head2 Google::Cloud::Securitycenter::V2::CloudArmor::Attack

Information about DDoS attack volume and classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volume_pps_long() >> / C<< $msg->volume_pps_long($value) >>

Type: C<Int64>

Total PPS (packets per second) volume of attack.

=item * C<< $msg->volume_bps_long() >> / C<< $msg->volume_bps_long($value) >>

Type: C<Int64>

Total BPS (bytes per second) volume of attack.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<String>

Type of attack, for example, 'SYN-flood', 'NTP-udp', or 'CHARGEN-udp'.

=item * C<< $msg->volume_pps() >> / C<< $msg->volume_pps($value) >>

Type: C<Int32>

Total PPS (packets per second) volume of attack. Deprecated - refer to
volume_pps_long instead.

=item * C<< $msg->volume_bps() >> / C<< $msg->volume_bps($value) >>

Type: C<Int32>

Total BPS (bytes per second) volume of attack. Deprecated - refer to
volume_bps_long instead.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::CloudArmor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
