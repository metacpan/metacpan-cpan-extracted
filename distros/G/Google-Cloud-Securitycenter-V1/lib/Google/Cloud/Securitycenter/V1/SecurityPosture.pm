package Google::Cloud::Securitycenter::V1::SecurityPosture;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc2VjdXJpdHlfcG9zdHVyZS5wcm90
bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIoMECg9TZWN1cml0eVBvc3R1cmUS
EgoEbmFtZRgBIAEoCVIEbmFtZRIfCgtyZXZpc2lvbl9pZBgCIAEoCVIKcmV2aXNpb25JZBI+
Chtwb3N0dXJlX2RlcGxveW1lbnRfcmVzb3VyY2UYAyABKAlSGXBvc3R1cmVEZXBsb3ltZW50
UmVzb3VyY2USLQoScG9zdHVyZV9kZXBsb3ltZW50GAQgASgJUhFwb3N0dXJlRGVwbG95bWVu
dBIlCg5jaGFuZ2VkX3BvbGljeRgFIAEoCVINY2hhbmdlZFBvbGljeRIdCgpwb2xpY3lfc2V0
GAYgASgJUglwb2xpY3lTZXQSFgoGcG9saWN5GAcgASgJUgZwb2xpY3kSdAoUcG9saWN5X2Ry
aWZ0X2RldGFpbHMYCCADKAsyQi5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuU2Vj
dXJpdHlQb3N0dXJlLlBvbGljeURyaWZ0RGV0YWlsc1IScG9saWN5RHJpZnREZXRhaWxzGngK
ElBvbGljeURyaWZ0RGV0YWlscxIUCgVmaWVsZBgBIAEoCVIFZmllbGQSJQoOZXhwZWN0ZWRf
dmFsdWUYAiABKAlSDWV4cGVjdGVkVmFsdWUSJQoOZGV0ZWN0ZWRfdmFsdWUYAyABKAlSDWRl
dGVjdGVkVmFsdWVC7gEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCFFNl
Y3VyaXR5UG9zdHVyZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50
ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNs
b3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx
6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSvQVCgYSBA4ASwEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAggl
EgMSADsKCAoBCBIDEwBhCgkKAggLEgMTAGEKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBID
FQA1CgkKAggIEgMVADUKCAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMX
ADsKCAoBCBIDGAA6CgkKAggtEgMYADoKiQIKAgQAEgQfAEsBGvwBIFJlcHJlc2VudHMgYSBw
b3N0dXJlIHRoYXQgaXMgZGVwbG95ZWQgb24gR29vZ2xlIENsb3VkIGJ5IHRoZQogU2VjdXJp
dHkgQ29tbWFuZCBDZW50ZXIgUG9zdHVyZSBNYW5hZ2VtZW50IHNlcnZpY2UuCiBBIHBvc3R1
cmUgY29udGFpbnMgb25lIG9yIG1vcmUgcG9saWN5IHNldHMuIEEgcG9saWN5IHNldCBpcyBh
CiBncm91cCBvZiBwb2xpY2llcyB0aGF0IGVuZm9yY2UgYSBzZXQgb2Ygc2VjdXJpdHkgcnVs
ZXMgb24gR29vZ2xlCiBDbG91ZC4KCgoKAwQAARIDHwgXCmoKBAQAAwASBCICLgMaXCBUaGUg
cG9saWN5IGZpZWxkIHRoYXQgdmlvbGF0ZXMgdGhlIGRlcGxveWVkIHBvc3R1cmUgYW5kIGl0
cyBleHBlY3RlZCBhbmQKIGRldGVjdGVkIHZhbHVlcy4KCgwKBQQAAwABEgMiChwKbgoGBAAD
AAIAEgMlBBUaXyBUaGUgbmFtZSBvZiB0aGUgdXBkYXRlZCBmaWVsZCwgZm9yIGV4YW1wbGUK
IGNvbnN0cmFpbnQuaW1wbGVtZW50YXRpb24ucG9saWN5X3J1bGVzWzBdLmVuZm9yY2UKCg4K
BwQAAwACAAUSAyUECgoOCgcEAAMAAgABEgMlCxAKDgoHBAADAAIAAxIDJRMUCooBCgYEAAMA
AgESAykEHhp7IFRoZSB2YWx1ZSBvZiB0aGlzIGZpZWxkIHRoYXQgd2FzIGNvbmZpZ3VyZWQg
aW4gYSBwb3N0dXJlLCBmb3IgZXhhbXBsZSwKIGB0cnVlYCBvciBgYWxsb3dlZF92YWx1ZXM9
eyJwcm9qZWN0cy8yOTgzMTg5MiJ9YC4KCg4KBwQAAwACAQUSAykECgoOCgcEAAMAAgEBEgMp
CxkKDgoHBAADAAIBAxIDKRwdCogBCgYEAAMAAgISAy0EHhp5IFRoZSBkZXRlY3RlZCB2YWx1
ZSB0aGF0IHZpb2xhdGVzIHRoZSBkZXBsb3llZCBwb3N0dXJlLCBmb3IgZXhhbXBsZSwKIGBm
YWxzZWAgb3IgYGFsbG93ZWRfdmFsdWVzPXsicHJvamVjdHMvMjI4MzE4OTIifWAuCgoOCgcE
AAMAAgIFEgMtBAoKDgoHBAADAAICARIDLQsZCg4KBwQAAwACAgMSAy0cHQo/CgQEAAIAEgMx
AhIaMiBOYW1lIG9mIHRoZSBwb3N0dXJlLCBmb3IgZXhhbXBsZSwgYENJUy1Qb3N0dXJlYC4K
CgwKBQQAAgAFEgMxAggKDAoFBAACAAESAzEJDQoMCgUEAAIAAxIDMRARCkMKBAQAAgESAzQC
GRo2IFRoZSB2ZXJzaW9uIG9mIHRoZSBwb3N0dXJlLCBmb3IgZXhhbXBsZSwgYGM3Y2ZhMmE4
YC4KCgwKBQQAAgEFEgM0AggKDAoFBAACAQESAzQJFAoMCgUEAAIBAxIDNBcYCoABCgQEAAIC
EgM4AikacyBUaGUgcHJvamVjdCwgZm9sZGVyLCBvciBvcmdhbml6YXRpb24gb24gd2hpY2gg
dGhlIHBvc3R1cmUgaXMgZGVwbG95ZWQsCiBmb3IgZXhhbXBsZSwgYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn1gLgoKDAoFBAACAgUSAzgCCAoMCgUEAAICARIDOAkkCgwKBQQAAgIDEgM4
JygKhQEKBAQAAgMSAzwCIBp4IFRoZSBuYW1lIG9mIHRoZSBwb3N0dXJlIGRlcGxveW1lbnQs
IGZvciBleGFtcGxlLAogYG9yZ2FuaXphdGlvbnMve29yZ19pZH0vcG9zdHVyZWRlcGxveW1l
bnRzL3twb3N0dXJlX2RlcGxveW1lbnRfaWR9YC4KCgwKBQQAAgMFEgM8AggKDAoFBAACAwES
AzwJGwoMCgUEAAIDAxIDPB4fCnAKBAQAAgQSA0ACHBpjIFRoZSBuYW1lIG9mIHRoZSB1cGRh
dGVkIHBvbGljeSwgZm9yIGV4YW1wbGUsCiBgcHJvamVjdHMve3Byb2plY3RfaWR9L3BvbGlj
aWVzL3tjb25zdHJhaW50X25hbWV9YC4KCgwKBQQAAgQFEgNAAggKDAoFBAACBAESA0AJFwoM
CgUEAAIEAxIDQBobCk8KBAQAAgUSA0MCGBpCIFRoZSBuYW1lIG9mIHRoZSB1cGRhdGVkIHBv
bGljeXNldCwgZm9yIGV4YW1wbGUsIGBjaXMtcG9saWN5c2V0YC4KCgwKBQQAAgUFEgNDAggK
DAoFBAACBQESA0MJEwoMCgUEAAIFAxIDQxYXCk0KBAQAAgYSA0YCFBpAIFRoZSBJRCBvZiB0
aGUgdXBkYXRlZCBwb2xpY3ksIGZvciBleGFtcGxlLCBgY29tcHV0ZS1wb2xpY3ktMWAuCgoM
CgUEAAIGBRIDRgIICgwKBQQAAgYBEgNGCQ8KDAoFBAACBgMSA0YSEwpjCgQEAAIHEgNKAjca
ViBUaGUgZGV0YWlscyBhYm91dCBhIGNoYW5nZSBpbiBhbiB1cGRhdGVkIHBvbGljeSB0aGF0
IHZpb2xhdGVzIHRoZSBkZXBsb3llZAogcG9zdHVyZS4KCgwKBQQAAgcEEgNKAgoKDAoFBAAC
BwYSA0oLHQoMCgUEAAIHARIDSh4yCgwKBQQAAgcDEgNKNTZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::SecurityPosture::SecurityPosture ===
    # Fields for SecurityPosture
    # Field: name Type: 9 ()
    # Field: revision_id Type: 9 ()
    # Field: posture_deployment_resource Type: 9 ()
    # Field: posture_deployment Type: 9 ()
    # Field: changed_policy Type: 9 ()
    # Field: policy_set Type: 9 ()
    # Field: policy Type: 9 ()
    # Field: policy_drift_details Type: 11 (.google.cloud.securitycenter.v1.SecurityPosture.PolicyDriftDetails)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::SecurityPosture - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/security_posture.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::SecurityPosture;

    my $msg = Google::Cloud::Securitycenter::V1::SecurityPosture::SecurityPosture->new({
        name => $name,
        revision_id => $revision_id,
        posture_deployment_resource => $posture_deployment_resource,
        posture_deployment => $posture_deployment,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::SecurityPosture::SecurityPosture->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/security_posture.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::SecurityPosture::SecurityPosture

Represents a posture that is deployed on Google Cloud by the
Security Command Center Posture Management service.
A posture contains one or more policy sets. A policy set is a
group of policies that enforce a set of security rules on Google
Cloud.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the posture, for example, `CIS-Posture`.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

The version of the posture, for example, `c7cfa2a8`.

=item * C<< $msg->posture_deployment_resource() >> / C<< $msg->posture_deployment_resource($value) >>

Type: C<String>

The project, folder, or organization on which the posture is deployed,
for example, `projects/{project_number}`.

=item * C<< $msg->posture_deployment() >> / C<< $msg->posture_deployment($value) >>

Type: C<String>

The name of the posture deployment, for example,
`organizations/{org_id}/posturedeployments/{posture_deployment_id}`.

=item * C<< $msg->changed_policy() >> / C<< $msg->changed_policy($value) >>

Type: C<String>

The name of the updated policy, for example,
`projects/{project_id}/policies/{constraint_name}`.

=item * C<< $msg->policy_set() >> / C<< $msg->policy_set($value) >>

Type: C<String>

The name of the updated policyset, for example, `cis-policyset`.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<String>

The ID of the updated policy, for example, `compute-policy-1`.

=item * C<< $msg->policy_drift_details() >> / C<< $msg->policy_drift_details($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityPosture::SecurityPosture::PolicyDriftDetails>)

The details about a change in an updated policy that violates the deployed
posture.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::SecurityPosture::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
