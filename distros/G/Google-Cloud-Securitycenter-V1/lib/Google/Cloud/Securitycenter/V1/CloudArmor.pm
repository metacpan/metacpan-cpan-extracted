package Google::Cloud::Securitycenter::V1::CloudArmor;

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
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvY2xvdWRfYXJtb3IucHJvdG8SHmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MRoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9u
LnByb3RvIqwDCgpDbG91ZEFybW9yElcKD3NlY3VyaXR5X3BvbGljeRgBIAEoCzIuLmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5TZWN1cml0eVBvbGljeVIOc2VjdXJpdHlQb2xp
Y3kSRAoIcmVxdWVzdHMYAiABKAsyKC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEu
UmVxdWVzdHNSCHJlcXVlc3RzEmMKE2FkYXB0aXZlX3Byb3RlY3Rpb24YAyABKAsyMi5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQWRhcHRpdmVQcm90ZWN0aW9uUhJhZGFwdGl2
ZVByb3RlY3Rpb24SPgoGYXR0YWNrGAQgASgLMiYuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2Vu
dGVyLnYxLkF0dGFja1IGYXR0YWNrEiMKDXRocmVhdF92ZWN0b3IYBSABKAlSDHRocmVhdFZl
Y3RvchI1CghkdXJhdGlvbhgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIIZHVy
YXRpb24iUgoOU2VjdXJpdHlQb2xpY3kSEgoEbmFtZRgBIAEoCVIEbmFtZRISCgR0eXBlGAIg
ASgJUgR0eXBlEhgKB3ByZXZpZXcYAyABKAhSB3ByZXZpZXcipAEKCFJlcXVlc3RzEhQKBXJh
dGlvGAEgASgBUgVyYXRpbxIsChJzaG9ydF90ZXJtX2FsbG93ZWQYAiABKAVSEHNob3J0VGVy
bUFsbG93ZWQSKgoRbG9uZ190ZXJtX2FsbG93ZWQYAyABKAVSD2xvbmdUZXJtQWxsb3dlZBIo
ChBsb25nX3Rlcm1fZGVuaWVkGAQgASgFUg5sb25nVGVybURlbmllZCI0ChJBZGFwdGl2ZVBy
b3RlY3Rpb24SHgoKY29uZmlkZW5jZRgBIAEoAVIKY29uZmlkZW5jZSJuCgZBdHRhY2sSHQoK
dm9sdW1lX3BwcxgBIAEoBVIJdm9sdW1lUHBzEh0KCnZvbHVtZV9icHMYAiABKAVSCXZvbHVt
ZUJwcxImCg5jbGFzc2lmaWNhdGlvbhgDIAEoCVIOY2xhc3NpZmljYXRpb25C6QEKImNvbS5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCD0Nsb3VkQXJtb3JQcm90b1ABWkpjbG91
ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7
c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdv
b2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5
Q2VudGVyOjpWMUqVIgoGEgQOAHEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACgKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBh
CgkKAggLEgMVAGEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAwCgkKAggIEgMXADAK
CAoBCBIDGAA7CgkKAggBEgMYADsKCAoBCBIDGQA7CgkKAggpEgMZADsKCAoBCBIDGgA6CgkK
AggtEgMaADoKPAoCBAASBB0AOAEaMCBGaWVsZHMgcmVsYXRlZCB0byBHb29nbGUgQ2xvdWQg
QXJtb3IgZmluZGluZ3MuCgoKCgMEAAESAx0IEgqjAQoEBAACABIDIQIlGpUBIEluZm9ybWF0
aW9uIGFib3V0IHRoZSBbR29vZ2xlIENsb3VkIEFybW9yIHNlY3VyaXR5CiBwb2xpY3ldKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcm1vci9kb2NzL3NlY3VyaXR5LXBvbGljeS1vdmVy
dmlldykKIHJlbGV2YW50IHRvIHRoZSBmaW5kaW5nLgoKDAoFBAACAAYSAyECEAoMCgUEAAIA
ARIDIREgCgwKBQQAAgADEgMhIyQKqAEKBAQAAgESAyYCGBqaASBJbmZvcm1hdGlvbiBhYm91
dCBpbmNvbWluZyByZXF1ZXN0cyBldmFsdWF0ZWQgYnkgW0dvb2dsZSBDbG91ZCBBcm1vcgog
c2VjdXJpdHkKIHBvbGljaWVzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXJtb3IvZG9j
cy9zZWN1cml0eS1wb2xpY3ktb3ZlcnZpZXcpLgoKDAoFBAACAQYSAyYCCgoMCgUEAAIBARID
JgsTCgwKBQQAAgEDEgMmFhcKvAEKBAQAAgISAysCLRquASBJbmZvcm1hdGlvbiBhYm91dCBw
b3RlbnRpYWwgTGF5ZXIgNyBERG9TIGF0dGFja3MgaWRlbnRpZmllZCBieSBbR29vZ2xlCiBD
bG91ZCBBcm1vciBBZGFwdGl2ZQogUHJvdGVjdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FybW9yL2RvY3MvYWRhcHRpdmUtcHJvdGVjdGlvbi1vdmVydmlldykuCgoMCgUEAAIC
BhIDKwIUCgwKBQQAAgIBEgMrFSgKDAoFBAACAgMSAysrLApHCgQEAAIDEgMuAhQaOiBJbmZv
cm1hdGlvbiBhYm91dCBERG9TIGF0dGFjayB2b2x1bWUgYW5kIGNsYXNzaWZpY2F0aW9uLgoK
DAoFBAACAwYSAy4CCAoMCgUEAAIDARIDLgkPCgwKBQQAAgMDEgMuEhMKwwEKBAQAAgQSAzMC
Gxq1ASBEaXN0aW5ndWlzaCBiZXR3ZWVuIHZvbHVtZXRyaWMgJiBwcm90b2NvbCBERG9TIGF0
dGFjayBhbmQKIGFwcGxpY2F0aW9uIGxheWVyIGF0dGFja3MuIEZvciBleGFtcGxlLCAiTDNf
NCIgZm9yIExheWVyIDMgYW5kIExheWVyIDQgRERvUwogYXR0YWNrcywgb3IgIkxfNyIgZm9y
IExheWVyIDcgRERvUyBhdHRhY2tzLgoKDAoFBAACBAUSAzMCCAoMCgUEAAIEARIDMwkWCgwK
BQQAAgQDEgMzGRoKZQoEBAACBRIDNwIoGlggRHVyYXRpb24gb2YgYXR0YWNrIGZyb20gdGhl
IHN0YXJ0IHVudGlsIHRoZSBjdXJyZW50IG1vbWVudCAodXBkYXRlZCBldmVyeSA1CiBtaW51
dGVzKS4KCgwKBQQAAgUGEgM3AhoKDAoFBAACBQESAzcbIwoMCgUEAAIFAxIDNyYnCqIBCgIE
ARIEPQBJARqVASBJbmZvcm1hdGlvbiBhYm91dCB0aGUgW0dvb2dsZSBDbG91ZCBBcm1vciBz
ZWN1cml0eQogcG9saWN5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXJtb3IvZG9jcy9z
ZWN1cml0eS1wb2xpY3ktb3ZlcnZpZXcpCiByZWxldmFudCB0byB0aGUgZmluZGluZy4KCgoK
AwQBARIDPQgWCmYKBAQBAgASA0ACEhpZIFRoZSBuYW1lIG9mIHRoZSBHb29nbGUgQ2xvdWQg
QXJtb3Igc2VjdXJpdHkgcG9saWN5LCBmb3IgZXhhbXBsZSwKICJteS1zZWN1cml0eS1wb2xp
Y3kiLgoKDAoFBAECAAUSA0ACCAoMCgUEAQIAARIDQAkNCgwKBQQBAgADEgNAEBEKwAEKBAQB
AgESA0UCEhqyASBUaGUgdHlwZSBvZiBHb29nbGUgQ2xvdWQgQXJtb3Igc2VjdXJpdHkgcG9s
aWN5IGZvciBleGFtcGxlLCAnYmFja2VuZAogc2VjdXJpdHkgcG9saWN5JywgJ2VkZ2Ugc2Vj
dXJpdHkgcG9saWN5JywgJ25ldHdvcmsgZWRnZSBzZWN1cml0eSBwb2xpY3knLAogb3IgJ2Fs
d2F5cy1vbiBERG9TIHByb3RlY3Rpb24nLgoKDAoFBAECAQUSA0UCCAoMCgUEAQIBARIDRQkN
CgwKBQQBAgEDEgNFEBEKTwoEBAECAhIDSAITGkIgV2hldGhlciBvciBub3QgdGhlIGFzc29j
aWF0ZWQgcnVsZSBvciBwb2xpY3kgaXMgaW4gcHJldmlldyBtb2RlLgoKDAoFBAECAgUSA0gC
BgoMCgUEAQICARIDSAcOCgwKBQQBAgIDEgNIERIKRQoCBAISBEwAWgEaOSBJbmZvcm1hdGlv
biBhYm91dCB0aGUgcmVxdWVzdHMgcmVsZXZhbnQgdG8gdGhlIGZpbmRpbmcuCgoKCgMEAgES
A0wIEArrAQoEBAICABIDUAITGt0BIEZvciAnSW5jcmVhc2luZyBkZW55IHJhdGlvJywgdGhl
IHJhdGlvIGlzIHRoZSBkZW5pZWQgdHJhZmZpYyBkaXZpZGVkIGJ5IHRoZQogYWxsb3dlZCB0
cmFmZmljLiBGb3IgJ0FsbG93ZWQgdHJhZmZpYyBzcGlrZScsIHRoZSByYXRpbyBpcyB0aGUg
YWxsb3dlZAogdHJhZmZpYyBpbiB0aGUgc2hvcnQgdGVybSBkaXZpZGVkIGJ5IGFsbG93ZWQg
dHJhZmZpYyBpbiB0aGUgbG9uZyB0ZXJtLgoKDAoFBAICAAUSA1ACCAoMCgUEAgIAARIDUAkO
CgwKBQQCAgADEgNQERIKQwoEBAICARIDUwIfGjYgQWxsb3dlZCBSUFMgKHJlcXVlc3RzIHBl
ciBzZWNvbmQpIGluIHRoZSBzaG9ydCB0ZXJtLgoKDAoFBAICAQUSA1MCBwoMCgUEAgIBARID
UwgaCgwKBQQCAgEDEgNTHR4KRAoEBAICAhIDVgIeGjcgQWxsb3dlZCBSUFMgKHJlcXVlc3Rz
IHBlciBzZWNvbmQpIG92ZXIgdGhlIGxvbmcgdGVybS4KCgwKBQQCAgIFEgNWAgcKDAoFBAIC
AgESA1YIGQoMCgUEAgICAxIDVhwdCkMKBAQCAgMSA1kCHRo2IERlbmllZCBSUFMgKHJlcXVl
c3RzIHBlciBzZWNvbmQpIG92ZXIgdGhlIGxvbmcgdGVybS4KCgwKBQQCAgMFEgNZAgcKDAoF
BAICAwESA1kIGAoMCgUEAgIDAxIDWRscCqwBCgIEAxIEXgBlARqfASBJbmZvcm1hdGlvbiBh
Ym91dCBbR29vZ2xlIENsb3VkIEFybW9yIEFkYXB0aXZlCiBQcm90ZWN0aW9uXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vYXJtb3IvZG9jcy9jbG91ZC1hcm1vci1vdmVydmlldyNnb29n
bGUtY2xvdWQtYXJtb3ItYWRhcHRpdmUtcHJvdGVjdGlvbikuCgoKCgMEAwESA14IGgrlAgoE
BAMCABIDZAIYGtcCIEEgc2NvcmUgb2YgMCBtZWFucyB0aGF0IHRoZXJlIGlzIGxvdyBjb25m
aWRlbmNlIHRoYXQgdGhlIGRldGVjdGVkIGV2ZW50IGlzCiBhbiBhY3R1YWwgYXR0YWNrLiBB
IHNjb3JlIG9mIDEgbWVhbnMgdGhhdCB0aGVyZSBpcyBoaWdoIGNvbmZpZGVuY2UgdGhhdCB0
aGUKIGRldGVjdGVkIGV2ZW50IGlzIGFuIGF0dGFjay4gU2VlIHRoZSBbQWRhcHRpdmUgUHJv
dGVjdGlvbgogZG9jdW1lbnRhdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FybW9y
L2RvY3MvYWRhcHRpdmUtcHJvdGVjdGlvbi1vdmVydmlldyNjb25maWd1cmUtYWxlcnQtdHVu
aW5nKQogZm9yIGZ1cnRoZXIgZXhwbGFuYXRpb24uCgoMCgUEAwIABRIDZAIICgwKBQQDAgAB
EgNkCRMKDAoFBAMCAAMSA2QWFwpGCgIEBBIEaABxARo6IEluZm9ybWF0aW9uIGFib3V0IERE
b1MgYXR0YWNrIHZvbHVtZSBhbmQgY2xhc3NpZmljYXRpb24uCgoKCgMEBAESA2gIDgo/CgQE
BAIAEgNqAhcaMiBUb3RhbCBQUFMgKHBhY2tldHMgcGVyIHNlY29uZCkgdm9sdW1lIG9mIGF0
dGFjay4KCgwKBQQEAgAFEgNqAgcKDAoFBAQCAAESA2oIEgoMCgUEBAIAAxIDahUWCj0KBAQE
AgESA20CFxowIFRvdGFsIEJQUyAoYnl0ZXMgcGVyIHNlY29uZCkgdm9sdW1lIG9mIGF0dGFj
ay4KCgwKBQQEAgEFEgNtAgcKDAoFBAQCAQESA20IEgoMCgUEBAIBAxIDbRUWClUKBAQEAgIS
A3ACHBpIIFR5cGUgb2YgYXR0YWNrLCBmb3IgZXhhbXBsZSwgJ1NZTi1mbG9vZCcsICdOVFAt
dWRwJywgb3IgJ0NIQVJHRU4tdWRwJy4KCgwKBQQEAgIFEgNwAggKDAoFBAQCAgESA3AJFwoM
CgUEBAICAxIDcBobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor ===
    # Fields for CloudArmor
    # Field: security_policy Type: 11 (.google.cloud.securitycenter.v1.SecurityPolicy)
    # Field: requests Type: 11 (.google.cloud.securitycenter.v1.Requests)
    # Field: adaptive_protection Type: 11 (.google.cloud.securitycenter.v1.AdaptiveProtection)
    # Field: attack Type: 11 (.google.cloud.securitycenter.v1.Attack)
    # Field: threat_vector Type: 9 ()
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Securitycenter::V1::CloudArmor::SecurityPolicy ===
    # Fields for SecurityPolicy
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: preview Type: 8 ()

# === Message: Google::Cloud::Securitycenter::V1::CloudArmor::Requests ===
    # Fields for Requests
    # Field: ratio Type: 1 ()
    # Field: short_term_allowed Type: 5 ()
    # Field: long_term_allowed Type: 5 ()
    # Field: long_term_denied Type: 5 ()

# === Message: Google::Cloud::Securitycenter::V1::CloudArmor::AdaptiveProtection ===
    # Fields for AdaptiveProtection
    # Field: confidence Type: 1 ()

# === Message: Google::Cloud::Securitycenter::V1::CloudArmor::Attack ===
    # Fields for Attack
    # Field: volume_pps Type: 5 ()
    # Field: volume_bps Type: 5 ()
    # Field: classification Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::CloudArmor - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/cloud_armor.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::CloudArmor;

    my $msg = Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor->new({
        security_policy => $security_policy,
        requests => $requests,
        adaptive_protection => $adaptive_protection,
        attack => $attack,
    });

    # Read or update a field
    my $val = $msg->security_policy();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/cloud_armor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor

Fields related to Google Cloud Armor findings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->security_policy() >> / C<< $msg->security_policy($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::CloudArmor::SecurityPolicy>)

Information about the [Google Cloud Armor security
policy](https://cloud.google.com/armor/docs/security-policy-overview)
relevant to the finding.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::CloudArmor::Requests>)

Information about incoming requests evaluated by [Google Cloud Armor
security
policies](https://cloud.google.com/armor/docs/security-policy-overview).

=item * C<< $msg->adaptive_protection() >> / C<< $msg->adaptive_protection($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::CloudArmor::AdaptiveProtection>)

Information about potential Layer 7 DDoS attacks identified by [Google
Cloud Armor Adaptive
Protection](https://cloud.google.com/armor/docs/adaptive-protection-overview).

=item * C<< $msg->attack() >> / C<< $msg->attack($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::CloudArmor::Attack>)

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

=head2 Google::Cloud::Securitycenter::V1::CloudArmor::SecurityPolicy

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

=head2 Google::Cloud::Securitycenter::V1::CloudArmor::Requests

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

=head2 Google::Cloud::Securitycenter::V1::CloudArmor::AdaptiveProtection

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

=head2 Google::Cloud::Securitycenter::V1::CloudArmor::Attack

Information about DDoS attack volume and classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volume_pps() >> / C<< $msg->volume_pps($value) >>

Type: C<Int32>

Total PPS (packets per second) volume of attack.

=item * C<< $msg->volume_bps() >> / C<< $msg->volume_bps($value) >>

Type: C<Int32>

Total BPS (bytes per second) volume of attack.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<String>

Type of attack, for example, 'SYN-flood', 'NTP-udp', or 'CHARGEN-udp'.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::CloudArmor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
