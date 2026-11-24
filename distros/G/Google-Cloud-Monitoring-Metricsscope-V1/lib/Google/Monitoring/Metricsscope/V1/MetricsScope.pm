package Google::Monitoring::Metricsscope::V1::MetricsScope;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvbW9uaXRvcmluZy9tZXRyaWNzc2NvcGUvdjEvbWV0cmljc19zY29wZS5wcm90
bxIhZ29vZ2xlLm1vbml0b3JpbmcubWV0cmljc3Njb3BlLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIvACCgxNZXRyaWNzU2NvcGUSFwoEbmFtZRgBIAEoCUID
4EEFUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEmcKEm1vbml0b3JlZF9wcm9qZWN0
cxgEIAMoCzIzLmdvb2dsZS5tb25pdG9yaW5nLm1ldHJpY3NzY29wZS52MS5Nb25pdG9yZWRQ
cm9qZWN0QgPgQQNSEW1vbml0b3JlZFByb2plY3RzOlrqQVcKJm1vbml0b3JpbmcuZ29vZ2xl
YXBpcy5jb20vTWV0cmljc1Njb3BlEi1sb2NhdGlvbnMvZ2xvYmFsL21ldHJpY3NTY29wZS97
bWV0cmljc19zY29wZX0i4QEKEE1vbml0b3JlZFByb2plY3QSFwoEbmFtZRgBIAEoCUID4EEF
UgRuYW1lEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgpjcmVhdGVUaW1lOnLqQW8KKm1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vTW9u
aXRvcmVkUHJvamVjdBJBbG9jYXRpb25zL2dsb2JhbC9tZXRyaWNzU2NvcGVzL3ttZXRyaWNz
X3Njb3BlfS9wcm9qZWN0cy97cHJvamVjdH1CjwIKJWNvbS5nb29nbGUubW9uaXRvcmluZy5t
ZXRyaWNzc2NvcGUudjFCEU1ldHJpY3NTY29wZVByb3RvUAFaT2Nsb3VkLmdvb2dsZS5jb20v
Z28vbW9uaXRvcmluZy9tZXRyaWNzc2NvcGUvYXBpdjEvbWV0cmljc3Njb3BlcGI7bWV0cmlj
c3Njb3BlcGKqAidHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5NZXRyaWNzU2NvcGUuVjHKAidH
b29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xNZXRyaWNzU2NvcGVcVjHqAitHb29nbGU6OkNsb3Vk
OjpNb25pdG9yaW5nOjpNZXRyaWNzU2NvcGU6OlYxSuIUCgYSBA4ATAEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUACkKCAoBCBIDFgBmCgkKAggLEgMWAGYKCAoBCBIDFwAiCgkKAggKEgMXACIK
CAoBCBIDGAAyCgkKAggIEgMYADIKCAoBCBIDGQA+CgkKAggBEgMZAD4KCAoBCBIDGgBECgkK
AgglEgMaAEQKCAoBCBIDGwBFCgkKAggpEgMbAEUKCAoBCBIDHABECgkKAggtEgMcAEQK3gEK
AgQAEgQiADgBGtEBIFJlcHJlc2VudHMgYSBbTWV0cmljcwogU2NvcGVdKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9tb25pdG9yaW5nL3NldHRpbmdzI2NvbmNlcHQtc2NvcGUpIGluIENs
b3VkCiBNb25pdG9yaW5nLCB3aGljaCBzcGVjaWZpZXMgb25lIG9yIG1vcmUgR29vZ2xlIHBy
b2plY3RzIGFuZCB6ZXJvIG9yIG1vcmUgQVdTCiBhY2NvdW50cyB0byBtb25pdG9yIHRvZ2V0
aGVyLgoKCgoDBAABEgMiCBQKCwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYECroCCgQEAAIA
EgMuAjwarAIgSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgTW9uaXRvcmlu
ZyBNZXRyaWNzIFNjb3BlLgogT24gaW5wdXQsIHRoZSByZXNvdXJjZSBuYW1lIGNhbiBiZSBz
cGVjaWZpZWQgd2l0aCB0aGUKIHNjb3BpbmcgcHJvamVjdCBJRCBvciBudW1iZXIuIE9uIG91
dHB1dCwgdGhlIHJlc291cmNlIG5hbWUgaXMKIHNwZWNpZmllZCB3aXRoIHRoZSBzY29waW5n
IHByb2plY3QgbnVtYmVyLgogRXhhbXBsZToKIGBsb2NhdGlvbnMvZ2xvYmFsL21ldHJpY3NT
Y29wZXMve1NDT1BJTkdfUFJPSkVDVF9JRF9PUl9OVU1CRVJ9YAoKDAoFBAACAAUSAy4CCAoM
CgUEAAIAARIDLgkNCgwKBQQAAgADEgMuEBEKDAoFBAACAAgSAy4SOwoPCggEAAIACJwIABID
LhM6CksKBAQAAgESAzECWBo+IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoaXMgYE1l
dHJpY3MgU2NvcGVgIHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAzECGwoMCgUEAAIBARIDMRwn
CgwKBQQAAgEDEgMxKisKDAoFBAACAQgSAzEsVwoPCggEAAIBCJwIABIDMS1WClcKBAQAAgIS
AzQCWBpKIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoaXMgYE1ldHJpY3MgU2NvcGVg
IHJlY29yZCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACAgYSAzQCGwoMCgUEAAICARIDNBwn
CgwKBQQAAgIDEgM0KisKDAoFBAACAggSAzQsVwoPCggEAAICCJwIABIDNC1WClMKBAQAAgMS
AzcCXxpGIE91dHB1dCBvbmx5LiBUaGUgbGlzdCBvZiBwcm9qZWN0cyBtb25pdG9yZWQgYnkg
dGhpcyBgTWV0cmljcyBTY29wZWAuCgoMCgUEAAIDBBIDNwIKCgwKBQQAAgMGEgM3CxsKDAoF
BAACAwESAzccLgoMCgUEAAIDAxIDNzEyCgwKBQQAAgMIEgM3M14KDwoIBAACAwicCAASAzc0
XQqPAQoCBAESBD0ATAEaggEgQSBbcHJvamVjdCBiZWluZwogbW9uaXRvcmVkXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vbW9uaXRvcmluZy9zZXR0aW5ncy9tdWx0aXBsZS1wcm9qZWN0
cyNjcmVhdGUtbXVsdGkpCiBieSBhIGBNZXRyaWNzIFNjb3BlYC4KCgoKAwQBARIDPQgYCgsK
AwQBBxIEPgJBBAoNCgUEAQedCBIEPgJBBArLAgoEBAECABIDSAI8Gr0CIEltbXV0YWJsZS4g
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGBNb25pdG9yZWRQcm9qZWN0YC4gT24gaW5wdXQs
IHRoZSByZXNvdXJjZSBuYW1lCiBpbmNsdWRlcyB0aGUgc2NvcGluZyBwcm9qZWN0IElEIGFu
ZCBtb25pdG9yZWQgcHJvamVjdCBJRC4gT24gb3V0cHV0LCBpdAogY29udGFpbnMgdGhlIGVx
dWl2YWxlbnQgcHJvamVjdCBudW1iZXJzLgogRXhhbXBsZToKIGBsb2NhdGlvbnMvZ2xvYmFs
L21ldHJpY3NTY29wZXMve1NDT1BJTkdfUFJPSkVDVF9JRF9PUl9OVU1CRVJ9L3Byb2plY3Rz
L3tNT05JVE9SRURfUFJPSkVDVF9JRF9PUl9OVU1CRVJ9YAoKDAoFBAECAAUSA0gCCAoMCgUE
AQIAARIDSAkNCgwKBQQBAgADEgNIEBEKDAoFBAECAAgSA0gSOwoPCggEAQIACJwIABIDSBM6
Ck4KBAQBAgESA0sCWBpBIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoaXMgYE1vbml0
b3JlZFByb2plY3RgIHdhcyBjcmVhdGVkLgoKDAoFBAECAQYSA0sCGwoMCgUEAQIBARIDSxwn
CgwKBQQBAgEDEgNLKisKDAoFBAECAQgSA0ssVwoPCggEAQIBCJwIABIDSy1WYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope ===
    # Fields for MetricsScope
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: monitored_projects Type: 11 (.google.monitoring.metricsscope.v1.MonitoredProject)

# === Message: Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject ===
    # Fields for MonitoredProject
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Metricsscope::V1::MetricsScope - Compiled Protocol Buffers messages for google/monitoring/metricsscope/v1/metrics_scope.proto

=head1 SYNOPSIS

    use Google::Monitoring::Metricsscope::V1::MetricsScope;

    my $msg = Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        monitored_projects => $monitored_projects,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/metricsscope/v1/metrics_scope.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope

Represents a [Metrics
Scope](https://cloud.google.com/monitoring/settings#concept-scope) in Cloud
Monitoring, which specifies one or more Google projects and zero or more AWS
accounts to monitor together.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the Monitoring Metrics Scope.
On input, the resource name can be specified with the
scoping project ID or number. On output, the resource name is
specified with the scoping project number.
Example:
`locations/global/metricsScopes/{SCOPING_PROJECT_ID_OR_NUMBER}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this `Metrics Scope` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this `Metrics Scope` record was last updated.

=item * C<< $msg->monitored_projects() >> / C<< $msg->monitored_projects($value) >>

Type: C<Message> (L<Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject>)

Output only. The list of projects monitored by this `Metrics Scope`.

=back

=head2 Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject

A [project being
monitored](https://cloud.google.com/monitoring/settings/multiple-projects#create-multi)
by a `Metrics Scope`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the `MonitoredProject`. On input, the resource name
includes the scoping project ID and monitored project ID. On output, it
contains the equivalent project numbers.
Example:
`locations/global/metricsScopes/{SCOPING_PROJECT_ID_OR_NUMBER}/projects/{MONITORED_PROJECT_ID_OR_NUMBER}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this `MonitoredProject` was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Metricsscope::V1::MetricsScope::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
