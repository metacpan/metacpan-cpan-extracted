package Google::Cloud::Securitycenter::V1::ExternalSystem;

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
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZXh0ZXJuYWxfc3lzdGVtLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i4ggKDkV4dGVybmFsU3lz
dGVtEhIKBG5hbWUYASABKAlSBG5hbWUSHAoJYXNzaWduZWVzGAIgAygJUglhc3NpZ25lZXMS
IQoMZXh0ZXJuYWxfdWlkGAMgASgJUgtleHRlcm5hbFVpZBIWCgZzdGF0dXMYBCABKAlSBnN0
YXR1cxJZChtleHRlcm5hbF9zeXN0ZW1fdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUhhleHRlcm5hbFN5c3RlbVVwZGF0ZVRpbWUSGQoIY2FzZV91cmkY
BiABKAlSB2Nhc2VVcmkSIwoNY2FzZV9wcmlvcml0eRgHIAEoCVIMY2FzZVByaW9yaXR5EjUK
CGNhc2Vfc2xhGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHY2FzZVNsYRJE
ChBjYXNlX2NyZWF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIO
Y2FzZUNyZWF0ZVRpbWUSQgoPY2FzZV9jbG9zZV90aW1lGAsgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFINY2FzZUNsb3NlVGltZRJaCgt0aWNrZXRfaW5mbxgIIAEoCzI5Lmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5FeHRlcm5hbFN5c3RlbS5UaWNrZXRJbmZv
Ugp0aWNrZXRJbmZvGsEBCgpUaWNrZXRJbmZvEg4KAmlkGAEgASgJUgJpZBIaCghhc3NpZ25l
ZRgCIAEoCVIIYXNzaWduZWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEhAK
A3VyaRgEIAEoCVIDdXJpEhYKBnN0YXR1cxgFIAEoCVIGc3RhdHVzEjsKC3VwZGF0ZV90aW1l
GAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZTrmAupB4gIK
LHNlY3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL0V4dGVybmFsU3lzdGVtEmFvcmdhbml6
YXRpb25zL3tvcmdhbml6YXRpb259L3NvdXJjZXMve3NvdXJjZX0vZmluZGluZ3Mve2ZpbmRp
bmd9L2V4dGVybmFsU3lzdGVtcy97ZXh0ZXJuYWxzeXN0ZW19ElVmb2xkZXJzL3tmb2xkZXJ9
L3NvdXJjZXMve3NvdXJjZX0vZmluZGluZ3Mve2ZpbmRpbmd9L2V4dGVybmFsU3lzdGVtcy97
ZXh0ZXJuYWxzeXN0ZW19Eldwcm9qZWN0cy97cHJvamVjdH0vc291cmNlcy97c291cmNlfS9m
aW5kaW5ncy97ZmluZGluZ30vZXh0ZXJuYWxTeXN0ZW1zL3tleHRlcm5hbHN5c3RlbX0qD2V4
dGVybmFsU3lzdGVtczIOZXh0ZXJuYWxTeXN0ZW1C7QEKImNvbS5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjFCE0V4dGVybmFsU3lzdGVtUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNv
bS9nby9zZWN1cml0eWNlbnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2Vu
dGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRc
U2VjdXJpdHlDZW50ZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFK
vRsKBhIEDgBmAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JwoJCgIDABIDEgAjCgkKAgMBEgMTACkKCAoBCBIDFQA7CgkKAgglEgMVADsKCAoBCBIDFgBh
CgkKAggLEgMWAGEKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA0CgkKAggIEgMYADQK
CAoBCBIDGQA7CgkKAggBEgMZADsKCAoBCBIDGgA7CgkKAggpEgMaADsKCAoBCBIDGwA6CgkK
AggtEgMbADoKSAoCBAASBB4AZgEaPCBSZXByZXNlbnRhdGlvbiBvZiB0aGlyZCBwYXJ0eSBT
SUVNL1NPQVIgZmllbGRzIHdpdGhpbiBTQ0MuCgoKCgMEAAESAx4IFgoLCgMEAAcSBB8CJgQK
DQoFBAAHnQgSBB8CJgQKkwEKBAQAAwASBCoCPQMahAEgSW5mb3JtYXRpb24gYWJvdXQgdGhl
IHRpY2tldCwgaWYgYW55LCB0aGF0IGlzIGJlaW5nIHVzZWQgdG8gdHJhY2sgdGhlCiByZXNv
bHV0aW9uIG9mIHRoZSBpc3N1ZSB0aGF0IGlzIGlkZW50aWZpZWQgYnkgdGhpcyBmaW5kaW5n
LgoKDAoFBAADAAESAyoKFApDCgYEAAMAAgASAywEEho0IFRoZSBpZGVudGlmaWVyIG9mIHRo
ZSB0aWNrZXQgaW4gdGhlIHRpY2tldCBzeXN0ZW0uCgoOCgcEAAMAAgAFEgMsBAoKDgoHBAAD
AAIAARIDLAsNCg4KBwQAAwACAAMSAywQEQpBCgYEAAMAAgESAy8EGBoyIFRoZSBhc3NpZ25l
ZSBvZiB0aGUgdGlja2V0IGluIHRoZSB0aWNrZXQgc3lzdGVtLgoKDgoHBAADAAIBBRIDLwQK
Cg4KBwQAAwACAQESAy8LEwoOCgcEAAMAAgEDEgMvFhcKRAoGBAADAAICEgMyBBsaNSBUaGUg
ZGVzY3JpcHRpb24gb2YgdGhlIHRpY2tldCBpbiB0aGUgdGlja2V0IHN5c3RlbS4KCg4KBwQA
AwACAgUSAzIECgoOCgcEAAMAAgIBEgMyCxYKDgoHBAADAAICAxIDMhkaCj0KBgQAAwACAxID
NQQTGi4gVGhlIGxpbmsgdG8gdGhlIHRpY2tldCBpbiB0aGUgdGlja2V0IHN5c3RlbS4KCg4K
BwQAAwACAwUSAzUECgoOCgcEAAMAAgMBEgM1Cw4KDgoHBAADAAIDAxIDNRESClMKBgQAAwAC
BBIDOAQWGkQgVGhlIGxhdGVzdCBzdGF0dXMgb2YgdGhlIHRpY2tldCwgYXMgcmVwb3J0ZWQg
YnkgdGhlIHRpY2tldCBzeXN0ZW0uCgoOCgcEAAMAAgQFEgM4BAoKDgoHBAADAAIEARIDOAsR
Cg4KBwQAAwACBAMSAzgUFQpeCgYEAAMAAgUSAzwELhpPIFRoZSB0aW1lIHdoZW4gdGhlIHRp
Y2tldCB3YXMgbGFzdCB1cGRhdGVkLCBhcyByZXBvcnRlZCBieSB0aGUgdGlja2V0CiBzeXN0
ZW0uCgoOCgcEAAMAAgUGEgM8BB0KDgoHBAADAAIFARIDPB4pCg4KBwQAAwACBQMSAzwsLQqW
AgoEBAACABIDQwISGogCIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZXh0ZXJuYWwgc3lz
dGVtLCBmb3IgZXhhbXBsZToKICJvcmdhbml6YXRpb25zLzEyMzQvc291cmNlcy81Njc4L2Zp
bmRpbmdzLzEyMzQ1Ni9leHRlcm5hbFN5c3RlbXMvamlyYSIsCiAiZm9sZGVycy8xMjM0L3Nv
dXJjZXMvNTY3OC9maW5kaW5ncy8xMjM0NTYvZXh0ZXJuYWxTeXN0ZW1zL2ppcmEiLAogInBy
b2plY3RzLzEyMzQvc291cmNlcy81Njc4L2ZpbmRpbmdzLzEyMzQ1Ni9leHRlcm5hbFN5c3Rl
bXMvamlyYSIKCgwKBQQAAgAFEgNDAggKDAoFBAACAAESA0MJDQoMCgUEAAIAAxIDQxARClEK
BAQAAgESA0YCIBpEIFJlZmVyZW5jZXMgcHJpbWFyeS9zZWNvbmRhcnkgZXRjIGFzc2lnbmVl
cyBpbiB0aGUgZXh0ZXJuYWwgc3lzdGVtLgoKDAoFBAACAQQSA0YCCgoMCgUEAAIBBRIDRgsR
CgwKBQQAAgEBEgNGEhsKDAoFBAACAQMSA0YeHwpsCgQEAAICEgNKAhoaXyBUaGUgaWRlbnRp
ZmllciB0aGF0J3MgdXNlZCB0byB0cmFjayB0aGUgZmluZGluZydzIGNvcnJlc3BvbmRpbmcg
Y2FzZSBpbiB0aGUKIGV4dGVybmFsIHN5c3RlbS4KCgwKBQQAAgIFEgNKAggKDAoFBAACAgES
A0oJFQoMCgUEAAICAxIDShgZCm8KBAQAAgMSA04CFBpiIFRoZSBtb3N0IHJlY2VudCBzdGF0
dXMgb2YgdGhlIGZpbmRpbmcncyBjb3JyZXNwb25kaW5nIGNhc2UsIGFzIHJlcG9ydGVkIGJ5
CiB0aGUgZXh0ZXJuYWwgc3lzdGVtLgoKDAoFBAACAwUSA04CCAoMCgUEAAIDARIDTgkPCgwK
BQQAAgMDEgNOEhMKXAoEBAACBBIDUgI8Gk8gVGhlIHRpbWUgd2hlbiB0aGUgY2FzZSB3YXMg
bGFzdCB1cGRhdGVkLCBhcyByZXBvcnRlZCBieSB0aGUgZXh0ZXJuYWwKIHN5c3RlbS4KCgwK
BQQAAgQGEgNSAhsKDAoFBAACBAESA1IcNwoMCgUEAAIEAxIDUjo7ClMKBAQAAgUSA1UCFhpG
IFRoZSBsaW5rIHRvIHRoZSBmaW5kaW5nJ3MgY29ycmVzcG9uZGluZyBjYXNlIGluIHRoZSBl
eHRlcm5hbCBzeXN0ZW0uCgoMCgUEAAIFBRIDVQIICgwKBQQAAgUBEgNVCREKDAoFBAACBQMS
A1UUFQpXCgQEAAIGEgNYAhsaSiBUaGUgcHJpb3JpdHkgb2YgdGhlIGZpbmRpbmcncyBjb3Jy
ZXNwb25kaW5nIGNhc2UgaW4gdGhlIGV4dGVybmFsIHN5c3RlbS4KCgwKBQQAAgYFEgNYAggK
DAoFBAACBgESA1gJFgoMCgUEAAIGAxIDWBkaClIKBAQAAgcSA1sCKRpFIFRoZSBTTEEgb2Yg
dGhlIGZpbmRpbmcncyBjb3JyZXNwb25kaW5nIGNhc2UgaW4gdGhlIGV4dGVybmFsIHN5c3Rl
bS4KCgwKBQQAAgcGEgNbAhsKDAoFBAACBwESA1scJAoMCgUEAAIHAxIDWycoClYKBAQAAggS
A14CMhpJIFRoZSB0aW1lIHdoZW4gdGhlIGNhc2Ugd2FzIGNyZWF0ZWQsIGFzIHJlcG9ydGVk
IGJ5IHRoZSBleHRlcm5hbCBzeXN0ZW0uCgoMCgUEAAIIBhIDXgIbCgwKBQQAAggBEgNeHCwK
DAoFBAACCAMSA14vMQpVCgQEAAIJEgNhAjEaSCBUaGUgdGltZSB3aGVuIHRoZSBjYXNlIHdh
cyBjbG9zZWQsIGFzIHJlcG9ydGVkIGJ5IHRoZSBleHRlcm5hbCBzeXN0ZW0uCgoMCgUEAAIJ
BhIDYQIbCgwKBQQAAgkBEgNhHCsKDAoFBAACCQMSA2EuMAqSAQoEBAACChIDZQIdGoQBIElu
Zm9ybWF0aW9uIGFib3V0IHRoZSB0aWNrZXQsIGlmIGFueSwgdGhhdCBpcyBiZWluZyB1c2Vk
IHRvIHRyYWNrIHRoZQogcmVzb2x1dGlvbiBvZiB0aGUgaXNzdWUgdGhhdCBpcyBpZGVudGlm
aWVkIGJ5IHRoaXMgZmluZGluZy4KCgwKBQQAAgoGEgNlAgwKDAoFBAACCgESA2UNGAoMCgUE
AAIKAxIDZRscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem ===
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
    # Field: ticket_info Type: 11 (.google.cloud.securitycenter.v1.ExternalSystem.TicketInfo)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::ExternalSystem - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/external_system.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::ExternalSystem;

    my $msg = Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem->new({
        name => $name,
        assignees => $assignees,
        external_uid => $external_uid,
        status => $status,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/external_system.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem

Representation of third party SIEM/SOAR fields within SCC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full resource name of the external system, for example:
"organizations/1234/sources/5678/findings/123456/externalSystems/jira",
"folders/1234/sources/5678/findings/123456/externalSystems/jira",
"projects/1234/sources/5678/findings/123456/externalSystems/jira"

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem::TicketInfo>)

Information about the ticket, if any, that is being used to track the
resolution of the issue that is identified by this finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::ExternalSystem::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
