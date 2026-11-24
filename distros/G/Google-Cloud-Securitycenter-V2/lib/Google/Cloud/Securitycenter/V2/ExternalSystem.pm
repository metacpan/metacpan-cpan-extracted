package Google::Cloud::Securitycenter::V2::ExternalSystem;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZXh0ZXJuYWxfc3lzdGVtLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ikwsKDkV4dGVybmFsU3lz
dGVtEhIKBG5hbWUYASABKAlSBG5hbWUSHAoJYXNzaWduZWVzGAIgAygJUglhc3NpZ25lZXMS
IQoMZXh0ZXJuYWxfdWlkGAMgASgJUgtleHRlcm5hbFVpZBIWCgZzdGF0dXMYBCABKAlSBnN0
YXR1cxJZChtleHRlcm5hbF9zeXN0ZW1fdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUhhleHRlcm5hbFN5c3RlbVVwZGF0ZVRpbWUSGQoIY2FzZV91cmkY
BiABKAlSB2Nhc2VVcmkSIwoNY2FzZV9wcmlvcml0eRgHIAEoCVIMY2FzZVByaW9yaXR5EjUK
CGNhc2Vfc2xhGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHY2FzZVNsYRJE
ChBjYXNlX2NyZWF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIO
Y2FzZUNyZWF0ZVRpbWUSQgoPY2FzZV9jbG9zZV90aW1lGAsgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFINY2FzZUNsb3NlVGltZRJaCgt0aWNrZXRfaW5mbxgIIAEoCzI5Lmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5FeHRlcm5hbFN5c3RlbS5UaWNrZXRJbmZv
Ugp0aWNrZXRJbmZvGsEBCgpUaWNrZXRJbmZvEg4KAmlkGAEgASgJUgJpZBIaCghhc3NpZ25l
ZRgCIAEoCVIIYXNzaWduZWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEhAK
A3VyaRgEIAEoCVIDdXJpEhYKBnN0YXR1cxgFIAEoCVIGc3RhdHVzEjsKC3VwZGF0ZV90aW1l
GAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZTqXBepBkwUK
LHNlY3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL0V4dGVybmFsU3lzdGVtEmFvcmdhbml6
YXRpb25zL3tvcmdhbml6YXRpb259L3NvdXJjZXMve3NvdXJjZX0vZmluZGluZ3Mve2ZpbmRp
bmd9L2V4dGVybmFsU3lzdGVtcy97ZXh0ZXJuYWxzeXN0ZW19EnZvcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb259L3NvdXJjZXMve3NvdXJjZX0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZmlu
ZGluZ3Mve2ZpbmRpbmd9L2V4dGVybmFsU3lzdGVtcy97ZXh0ZXJuYWxzeXN0ZW19ElVmb2xk
ZXJzL3tmb2xkZXJ9L3NvdXJjZXMve3NvdXJjZX0vZmluZGluZ3Mve2ZpbmRpbmd9L2V4dGVy
bmFsU3lzdGVtcy97ZXh0ZXJuYWxzeXN0ZW19Empmb2xkZXJzL3tmb2xkZXJ9L3NvdXJjZXMv
e3NvdXJjZX0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZmluZGluZ3Mve2ZpbmRpbmd9L2V4dGVy
bmFsU3lzdGVtcy97ZXh0ZXJuYWxzeXN0ZW19Eldwcm9qZWN0cy97cHJvamVjdH0vc291cmNl
cy97c291cmNlfS9maW5kaW5ncy97ZmluZGluZ30vZXh0ZXJuYWxTeXN0ZW1zL3tleHRlcm5h
bHN5c3RlbX0SbHByb2plY3RzL3twcm9qZWN0fS9zb3VyY2VzL3tzb3VyY2V9L2xvY2F0aW9u
cy97bG9jYXRpb259L2ZpbmRpbmdzL3tmaW5kaW5nfS9leHRlcm5hbFN5c3RlbXMve2V4dGVy
bmFsc3lzdGVtfULtAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkITRXh0
ZXJuYWxTeXN0ZW1Qcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVy
L2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91
ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoC
IUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMkrbHQoGEgQOAG8BCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACMKCQoCAwES
AxMAKQoICgEIEgMVADsKCQoCCCUSAxUAOwoICgEIEgMWAGEKCQoCCAsSAxYAYQoICgEIEgMX
ACIKCQoCCAoSAxcAIgoICgEIEgMYADQKCQoCCAgSAxgANAoICgEIEgMZADsKCQoCCAESAxkA
OwoICgEIEgMaADsKCQoCCCkSAxoAOwoICgEIEgMbADoKCQoCCC0SAxsAOgpICgIEABIEHgBv
ARo8IFJlcHJlc2VudGF0aW9uIG9mIHRoaXJkIHBhcnR5IFNJRU0vU09BUiBmaWVsZHMgd2l0
aGluIFNDQy4KCgoKAwQAARIDHggWCgsKAwQABxIEHwInBAoNCgUEAAedCBIEHwInBAqTAQoE
BAADABIEKwI+AxqEASBJbmZvcm1hdGlvbiBhYm91dCB0aGUgdGlja2V0LCBpZiBhbnksIHRo
YXQgaXMgYmVpbmcgdXNlZCB0byB0cmFjayB0aGUKIHJlc29sdXRpb24gb2YgdGhlIGlzc3Vl
IHRoYXQgaXMgaWRlbnRpZmllZCBieSB0aGlzIGZpbmRpbmcuCgoMCgUEAAMAARIDKwoUCkMK
BgQAAwACABIDLQQSGjQgVGhlIGlkZW50aWZpZXIgb2YgdGhlIHRpY2tldCBpbiB0aGUgdGlj
a2V0IHN5c3RlbS4KCg4KBwQAAwACAAUSAy0ECgoOCgcEAAMAAgABEgMtCw0KDgoHBAADAAIA
AxIDLRARCkEKBgQAAwACARIDMAQYGjIgVGhlIGFzc2lnbmVlIG9mIHRoZSB0aWNrZXQgaW4g
dGhlIHRpY2tldCBzeXN0ZW0uCgoOCgcEAAMAAgEFEgMwBAoKDgoHBAADAAIBARIDMAsTCg4K
BwQAAwACAQMSAzAWFwpECgYEAAMAAgISAzMEGxo1IFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUg
dGlja2V0IGluIHRoZSB0aWNrZXQgc3lzdGVtLgoKDgoHBAADAAICBRIDMwQKCg4KBwQAAwAC
AgESAzMLFgoOCgcEAAMAAgIDEgMzGRoKPQoGBAADAAIDEgM2BBMaLiBUaGUgbGluayB0byB0
aGUgdGlja2V0IGluIHRoZSB0aWNrZXQgc3lzdGVtLgoKDgoHBAADAAIDBRIDNgQKCg4KBwQA
AwACAwESAzYLDgoOCgcEAAMAAgMDEgM2ERIKUwoGBAADAAIEEgM5BBYaRCBUaGUgbGF0ZXN0
IHN0YXR1cyBvZiB0aGUgdGlja2V0LCBhcyByZXBvcnRlZCBieSB0aGUgdGlja2V0IHN5c3Rl
bS4KCg4KBwQAAwACBAUSAzkECgoOCgcEAAMAAgQBEgM5CxEKDgoHBAADAAIEAxIDORQVCl4K
BgQAAwACBRIDPQQuGk8gVGhlIHRpbWUgd2hlbiB0aGUgdGlja2V0IHdhcyBsYXN0IHVwZGF0
ZWQsIGFzIHJlcG9ydGVkIGJ5IHRoZSB0aWNrZXQKIHN5c3RlbS4KCg4KBwQAAwACBQYSAz0E
HQoOCgcEAAMAAgUBEgM9HikKDgoHBAADAAIFAxIDPSwtCrQECgQEAAIAEgNMAhIapgQgRnVs
bCByZXNvdXJjZSBuYW1lIG9mIHRoZSBleHRlcm5hbCBzeXN0ZW0uIFRoZSBmb2xsb3dpbmcg
bGlzdAogc2hvd3Mgc29tZSBleGFtcGxlczoKCiArIGBvcmdhbml6YXRpb25zLzEyMzQvc291
cmNlcy81Njc4L2ZpbmRpbmdzLzEyMzQ1Ni9leHRlcm5hbFN5c3RlbXMvamlyYWAKICsKIGBv
cmdhbml6YXRpb25zLzEyMzQvc291cmNlcy81Njc4L2xvY2F0aW9ucy91cy9maW5kaW5ncy8x
MjM0NTYvZXh0ZXJuYWxTeXN0ZW1zL2ppcmFgCiArIGBmb2xkZXJzLzEyMzQvc291cmNlcy81
Njc4L2ZpbmRpbmdzLzEyMzQ1Ni9leHRlcm5hbFN5c3RlbXMvamlyYWAKICsKIGBmb2xkZXJz
LzEyMzQvc291cmNlcy81Njc4L2xvY2F0aW9ucy91cy9maW5kaW5ncy8xMjM0NTYvZXh0ZXJu
YWxTeXN0ZW1zL2ppcmFgCiArIGBwcm9qZWN0cy8xMjM0L3NvdXJjZXMvNTY3OC9maW5kaW5n
cy8xMjM0NTYvZXh0ZXJuYWxTeXN0ZW1zL2ppcmFgCiArCiBgcHJvamVjdHMvMTIzNC9zb3Vy
Y2VzLzU2NzgvbG9jYXRpb25zL3VzL2ZpbmRpbmdzLzEyMzQ1Ni9leHRlcm5hbFN5c3RlbXMv
amlyYWAKCgwKBQQAAgAFEgNMAggKDAoFBAACAAESA0wJDQoMCgUEAAIAAxIDTBARClEKBAQA
AgESA08CIBpEIFJlZmVyZW5jZXMgcHJpbWFyeS9zZWNvbmRhcnkgZXRjIGFzc2lnbmVlcyBp
biB0aGUgZXh0ZXJuYWwgc3lzdGVtLgoKDAoFBAACAQQSA08CCgoMCgUEAAIBBRIDTwsRCgwK
BQQAAgEBEgNPEhsKDAoFBAACAQMSA08eHwpsCgQEAAICEgNTAhoaXyBUaGUgaWRlbnRpZmll
ciB0aGF0J3MgdXNlZCB0byB0cmFjayB0aGUgZmluZGluZydzIGNvcnJlc3BvbmRpbmcgY2Fz
ZSBpbiB0aGUKIGV4dGVybmFsIHN5c3RlbS4KCgwKBQQAAgIFEgNTAggKDAoFBAACAgESA1MJ
FQoMCgUEAAICAxIDUxgZCm8KBAQAAgMSA1cCFBpiIFRoZSBtb3N0IHJlY2VudCBzdGF0dXMg
b2YgdGhlIGZpbmRpbmcncyBjb3JyZXNwb25kaW5nIGNhc2UsIGFzIHJlcG9ydGVkIGJ5CiB0
aGUgZXh0ZXJuYWwgc3lzdGVtLgoKDAoFBAACAwUSA1cCCAoMCgUEAAIDARIDVwkPCgwKBQQA
AgMDEgNXEhMKXAoEBAACBBIDWwI8Gk8gVGhlIHRpbWUgd2hlbiB0aGUgY2FzZSB3YXMgbGFz
dCB1cGRhdGVkLCBhcyByZXBvcnRlZCBieSB0aGUgZXh0ZXJuYWwKIHN5c3RlbS4KCgwKBQQA
AgQGEgNbAhsKDAoFBAACBAESA1scNwoMCgUEAAIEAxIDWzo7ClMKBAQAAgUSA14CFhpGIFRo
ZSBsaW5rIHRvIHRoZSBmaW5kaW5nJ3MgY29ycmVzcG9uZGluZyBjYXNlIGluIHRoZSBleHRl
cm5hbCBzeXN0ZW0uCgoMCgUEAAIFBRIDXgIICgwKBQQAAgUBEgNeCREKDAoFBAACBQMSA14U
FQpXCgQEAAIGEgNhAhsaSiBUaGUgcHJpb3JpdHkgb2YgdGhlIGZpbmRpbmcncyBjb3JyZXNw
b25kaW5nIGNhc2UgaW4gdGhlIGV4dGVybmFsIHN5c3RlbS4KCgwKBQQAAgYFEgNhAggKDAoF
BAACBgESA2EJFgoMCgUEAAIGAxIDYRkaClIKBAQAAgcSA2QCKRpFIFRoZSBTTEEgb2YgdGhl
IGZpbmRpbmcncyBjb3JyZXNwb25kaW5nIGNhc2UgaW4gdGhlIGV4dGVybmFsIHN5c3RlbS4K
CgwKBQQAAgcGEgNkAhsKDAoFBAACBwESA2QcJAoMCgUEAAIHAxIDZCcoClYKBAQAAggSA2cC
MhpJIFRoZSB0aW1lIHdoZW4gdGhlIGNhc2Ugd2FzIGNyZWF0ZWQsIGFzIHJlcG9ydGVkIGJ5
IHRoZSBleHRlcm5hbCBzeXN0ZW0uCgoMCgUEAAIIBhIDZwIbCgwKBQQAAggBEgNnHCwKDAoF
BAACCAMSA2cvMQpVCgQEAAIJEgNqAjEaSCBUaGUgdGltZSB3aGVuIHRoZSBjYXNlIHdhcyBj
bG9zZWQsIGFzIHJlcG9ydGVkIGJ5IHRoZSBleHRlcm5hbCBzeXN0ZW0uCgoMCgUEAAIJBhID
agIbCgwKBQQAAgkBEgNqHCsKDAoFBAACCQMSA2ouMAqSAQoEBAACChIDbgIdGoQBIEluZm9y
bWF0aW9uIGFib3V0IHRoZSB0aWNrZXQsIGlmIGFueSwgdGhhdCBpcyBiZWluZyB1c2VkIHRv
IHRyYWNrIHRoZQogcmVzb2x1dGlvbiBvZiB0aGUgaXNzdWUgdGhhdCBpcyBpZGVudGlmaWVk
IGJ5IHRoaXMgZmluZGluZy4KCgwKBQQAAgoGEgNuAgwKDAoFBAACCgESA24NGAoMCgUEAAIK
AxIDbhscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::ExternalSystem::ExternalSystem ===
    # Fields for ExternalSystem
    # Field: name Type: 9 ()
    # Field: assignees Type: 9 ()
    # Field: external_uid Type: 9 ()
    # Field: status Type: 9 ()
    # Field: external_system_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: case_uri Type: 9 ()
    # Field: case_priority Type: 9 ()
    # Field: case_sla Type: 11 (.google.protobuf.Timestamp)
    # Field: case_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: case_close_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ticket_info Type: 11 (.google.cloud.securitycenter.v2.ExternalSystem.TicketInfo)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::ExternalSystem - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/external_system.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::ExternalSystem;

    my $msg = Google::Cloud::Securitycenter::V2::ExternalSystem::ExternalSystem->new({
        name => $name,
        assignees => $assignees,
        external_uid => $external_uid,
        status => $status,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::ExternalSystem::ExternalSystem->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/external_system.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::ExternalSystem::ExternalSystem

Representation of third party SIEM/SOAR fields within SCC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full resource name of the external system. The following list
shows some examples:

+ `organizations/1234/sources/5678/findings/123456/externalSystems/jira`
+
`organizations/1234/sources/5678/locations/us/findings/123456/externalSystems/jira`
+ `folders/1234/sources/5678/findings/123456/externalSystems/jira`
+
`folders/1234/sources/5678/locations/us/findings/123456/externalSystems/jira`
+ `projects/1234/sources/5678/findings/123456/externalSystems/jira`
+
`projects/1234/sources/5678/locations/us/findings/123456/externalSystems/jira`

=item * C<< $msg->assignees() >> / C<< $msg->assignees($value) >>

Type: C<String>

References primary/secondary etc assignees in the external system.

=item * C<< $msg->external_uid() >> / C<< $msg->external_uid($value) >>

Type: C<String>

The identifier that's used to track the finding's corresponding case in the
external system.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<String>

The most recent status of the finding's corresponding case, as reported by
the external system.

=item * C<< $msg->external_system_update_time() >> / C<< $msg->external_system_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the case was last updated, as reported by the external
system.

=item * C<< $msg->case_uri() >> / C<< $msg->case_uri($value) >>

Type: C<String>

The link to the finding's corresponding case in the external system.

=item * C<< $msg->case_priority() >> / C<< $msg->case_priority($value) >>

Type: C<String>

The priority of the finding's corresponding case in the external system.

=item * C<< $msg->case_sla() >> / C<< $msg->case_sla($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The SLA of the finding's corresponding case in the external system.

=item * C<< $msg->case_create_time() >> / C<< $msg->case_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the case was created, as reported by the external system.

=item * C<< $msg->case_close_time() >> / C<< $msg->case_close_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the case was closed, as reported by the external system.

=item * C<< $msg->ticket_info() >> / C<< $msg->ticket_info($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::ExternalSystem::ExternalSystem::TicketInfo>)

Information about the ticket, if any, that is being used to track the
resolution of the issue that is identified by this finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::ExternalSystem::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
