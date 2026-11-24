package Google::Monitoring::Dashboard::V1::IncidentList;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::MonitoredResource };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvaW5jaWRlbnRfbGlzdC5wcm90bxIe
Z29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGiNnb29nbGUvYXBpL21vbml0b3JlZF9yZXNvdXJjZS5wcm90byKLAQoMSW5j
aWRlbnRMaXN0ElMKE21vbml0b3JlZF9yZXNvdXJjZXMYASADKAsyHS5nb29nbGUuYXBpLk1v
bml0b3JlZFJlc291cmNlQgPgQQFSEm1vbml0b3JlZFJlc291cmNlcxImCgxwb2xpY3lfbmFt
ZXMYAiADKAlCA+BBAVILcG9saWN5TmFtZXNC+gEKImNvbS5nb29nbGUubW9uaXRvcmluZy5k
YXNoYm9hcmQudjFCEUluY2lkZW50TGlzdFByb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28v
bW9uaXRvcmluZy9kYXNoYm9hcmQvYXBpdjEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRH
b29nbGUuQ2xvdWQuTW9uaXRvcmluZy5EYXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9u
aXRvcmluZ1xEYXNoYm9hcmRcVjHqAihHb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpEYXNo
Ym9hcmQ6OlYxSrkLCgYSBA4AKgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAtCggKAQgSAxUAQQoJCgIIJRIDFQBB
CggKAQgSAxYAXQoJCgIICxIDFgBdCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAMgoJ
CgIICBIDGAAyCggKAQgSAxkAOwoJCgIIARIDGQA7CggKAQgSAxoAQgoJCgIIKRIDGgBCCggK
AQgSAxsAQQoJCgIILRIDGwBBCjUKAgQAEgQeACoBGikgQSB3aWRnZXQgdGhhdCBkaXNwbGF5
cyBhIGxpc3Qgb2YgYWxlcnRzCgoKCgMEAAESAx4IFAqNAgoEBAACABIEIwIkLxr+ASBPcHRp
b25hbC4gVGhlIG1vbml0b3JlZCByZXNvdXJjZSBmb3Igd2hpY2ggYWxlcnRzIGFyZSBsaXN0
ZWQuCiBUaGUgcmVzb3VyY2UgZG9lc24ndCBuZWVkIHRvIGJlIGZ1bGx5IHNwZWNpZmllZC4g
VGhhdCBpcywgeW91IGNhbiBzcGVjaWZ5CiB0aGUgcmVzb3VyY2UgdHlwZSBidXQgbm90IHRo
ZSB2YWx1ZXMgb2YgdGhlIHJlc291cmNlIGxhYmVscy4KIFRoZSByZXNvdXJjZSB0eXBlIGFu
ZCBsYWJlbHMgYXJlIHVzZWQgZm9yIGZpbHRlcmluZy4KCgwKBQQAAgAEEgMjAgoKDAoFBAAC
AAYSAyMLJwoMCgUEAAIAARIDIyg7CgwKBQQAAgADEgMjPj8KDAoFBAACAAgSAyQGLgoPCggE
AAIACJwIABIDJActCrsBCgQEAAIBEgMpAkwarQEgT3B0aW9uYWwuIEEgbGlzdCBvZiBhbGVy
dCBwb2xpY3kgbmFtZXMgdG8gZmlsdGVyIHRoZSBhbGVydCBsaXN0IGJ5LgogRG9uJ3QgaW5j
bHVkZSB0aGUgcHJvamVjdCBJRCBwcmVmaXggaW4gdGhlIHBvbGljeSBuYW1lLiBGb3IKIGV4
YW1wbGUsIHVzZSBgYWxlcnRQb2xpY2llcy91dGlsaXphdGlvbmAuCgoMCgUEAAIBBBIDKQIK
CgwKBQQAAgEFEgMpCxEKDAoFBAACAQESAykSHgoMCgUEAAIBAxIDKSEiCgwKBQQAAgEIEgMp
I0sKDwoIBAACAQicCAASAykkSmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::IncidentList::IncidentList ===
    # Fields for IncidentList
    # Field: monitored_resources Type: 11 (.google.api.MonitoredResource)
    # Field: policy_names Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::IncidentList - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/incident_list.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::IncidentList;

    my $msg = Google::Monitoring::Dashboard::V1::IncidentList::IncidentList->new({
        monitored_resources => $monitored_resources,
        policy_names => $policy_names,
    });

    # Read or update a field
    my $val = $msg->monitored_resources();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::IncidentList::IncidentList->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/incident_list.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::IncidentList::IncidentList

A widget that displays a list of alerts

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->monitored_resources() >> / C<< $msg->monitored_resources($value) >>

Type: C<Message> (L<Google::Api::MonitoredResource::MonitoredResource>)

Optional. The monitored resource for which alerts are listed.
The resource doesn't need to be fully specified. That is, you can specify
the resource type but not the values of the resource labels.
The resource type and labels are used for filtering.

=item * C<< $msg->policy_names() >> / C<< $msg->policy_names($value) >>

Type: C<String>

Optional. A list of alert policy names to filter the alert list by.
Don't include the project ID prefix in the policy name. For
example, use `alertPolicies/utilization`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::IncidentList::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
