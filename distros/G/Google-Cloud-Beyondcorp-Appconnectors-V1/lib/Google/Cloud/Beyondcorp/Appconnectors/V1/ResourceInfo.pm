package Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvYmV5b25kY29ycC9hcHBjb25uZWN0b3JzL3YxL3Jlc291cmNlX2lu
Zm8ucHJvdG8SKGdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmFwcGNvbm5lY3RvcnMudjEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8inwIKDFJlc291cmNlSW5mbxIT
CgJpZBgBIAEoCUID4EECUgJpZBJOCgZzdGF0dXMYAiABKA4yNi5nb29nbGUuY2xvdWQuYmV5
b25kY29ycC5hcHBjb25uZWN0b3JzLnYxLkhlYWx0aFN0YXR1c1IGc3RhdHVzEjAKCHJlc291
cmNlGAMgASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueVIIcmVzb3VyY2USLgoEdGltZRgEIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBHRpbWUSSAoDc3ViGAUgAygLMjYuZ29v
Z2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwY29ubmVjdG9ycy52MS5SZXNvdXJjZUluZm9SA3N1
YiLlAgoWQ29udGFpbmVySGVhbHRoRGV0YWlscxI2ChdleHBlY3RlZF9jb25maWdfdmVyc2lv
bhgBIAEoCVIVZXhwZWN0ZWRDb25maWdWZXJzaW9uEjQKFmN1cnJlbnRfY29uZmlnX3ZlcnNp
b24YAiABKAlSFGN1cnJlbnRDb25maWdWZXJzaW9uEn0KD2V4dGVuZGVkX3N0YXR1cxgDIAMo
CzJULmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmFwcGNvbm5lY3RvcnMudjEuQ29udGFpbmVy
SGVhbHRoRGV0YWlscy5FeHRlbmRlZFN0YXR1c0VudHJ5Ug5leHRlbmRlZFN0YXR1cxIbCgll
cnJvcl9tc2cYBCABKAlSCGVycm9yTXNnGkEKE0V4dGVuZGVkU3RhdHVzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASIUChJSZW1vdGVBZ2VudERl
dGFpbHMqaQoMSGVhbHRoU3RhdHVzEh0KGUhFQUxUSF9TVEFUVVNfVU5TUEVDSUZJRUQQABIL
CgdIRUFMVEhZEAESDQoJVU5IRUFMVEhZEAISEAoMVU5SRVNQT05TSVZFEAMSDAoIREVHUkFE
RUQQBEKcAgosY29tLmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmFwcGNvbm5lY3RvcnMudjFC
EVJlc291cmNlSW5mb1Byb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vYmV5b25kY29ycC9h
cHBjb25uZWN0b3JzL2FwaXYxL2FwcGNvbm5lY3RvcnNwYjthcHBjb25uZWN0b3JzcGKqAihH
b29nbGUuQ2xvdWQuQmV5b25kQ29ycC5BcHBDb25uZWN0b3JzLlYxygIoR29vZ2xlXENsb3Vk
XEJleW9uZENvcnBcQXBwQ29ubmVjdG9yc1xWMeoCLEdvb2dsZTo6Q2xvdWQ6OkJleW9uZENv
cnA6OkFwcENvbm5lY3RvcnM6OlYxSpkWCgYSBA4AWB0KvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQADEKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMU
ACkKCAoBCBIDFgBFCgkKAgglEgMWAEUKCAoBCBIDFwBpCgkKAggLEgMXAGkKCAoBCBIDGAAi
CgkKAggKEgMYACIKCAoBCBIDGQAyCgkKAggIEgMZADIKCAoBCBIDGgBFCgkKAggBEgMaAEUK
CAoBCBIDGwBGCgkKAggpEgMbAEYKCAoBCBIDHABFCgkKAggtEgMcAEUKOAoCBQASBB8ALgEa
LCBIZWFsdGhTdGF0dXMgcmVwcmVzZW50cyB0aGUgaGVhbHRoIHN0YXR1cy4KCgoKAwUAARID
HwURCk8KBAUAAgASAyECIBpCIEhlYWx0aCBzdGF0dXMgaXMgdW5rbm93bjogbm90IGluaXRp
YWxpemVkIG9yIGZhaWxlZCB0byByZXRyaWV2ZS4KCgwKBQUAAgABEgMhAhsKDAoFBQACAAIS
AyEeHwonCgQFAAIBEgMkAg4aGiBUaGUgcmVzb3VyY2UgaXMgaGVhbHRoeS4KCgwKBQUAAgEB
EgMkAgkKDAoFBQACAQISAyQMDQopCgQFAAICEgMnAhAaHCBUaGUgcmVzb3VyY2UgaXMgdW5o
ZWFsdGh5LgoKDAoFBQACAgESAycCCwoMCgUFAAICAhIDJw4PCiwKBAUAAgMSAyoCExofIFRo
ZSByZXNvdXJjZSBpcyB1bnJlc3BvbnNpdmUuCgoMCgUFAAIDARIDKgIOCgwKBQUAAgMCEgMq
ERIKMAoEBQACBBIDLQIPGiMgU29tZSBzdWItcmVzb3VyY2VzIGFyZSBVTkhFQUxUSFkuCgoM
CgUFAAIEARIDLQIKCgwKBQUAAgQCEgMtDQ4KyQIKAgQAEgQ1AEYBGrwCIFJlc291cmNlSW5m
byByZXByZXNlbnRzIHRoZSBpbmZvcm1hdGlvbiBvciBzdGF0dXMgb2YgYW4gYXBwIGNvbm5l
Y3RvcgogcmVzb3VyY2UgY29tcG9uZW50IHRoYXQncyB1c2VkIHRvIHJlcG9ydCBvbiB2YXJp
b3VzIHBhcnRzIG9mIHRoZSBzeXN0ZW0uIEZvcgogZXhhbXBsZSwgUmVzb3VyY2VJbmZvIGNh
biBiZSB1c2VkIHRvIGNvbnZleSB0aGUgc3RhdHVzIG9mIGEgcmVtb3RlX2FnZW50LAogaW5j
bHVkaW5nIHRoZSBzdGF0dXMgb2YgYW4gYXBwZ2F0ZXdheSBmb3IgYW4gcnVudGltZSBlbnZp
cm9ubWVudCBpbiBhCiBjb250YWluZXIgaW5zdGFuY2UuCgoKCgMEAAESAzUIFAo0CgQEAAIA
EgM3AjkaJyBSZXF1aXJlZC4gVW5pcXVlIElkIGZvciB0aGUgcmVzb3VyY2UuCgoMCgUEAAIA
BRIDNwIICgwKBQQAAgABEgM3CQsKDAoFBAACAAMSAzcODwoMCgUEAAIACBIDNxA4Cg8KCAQA
AgAInAgAEgM3ETcKcQoEBAACARIDOwIaGmQgT3ZlcmFsbCBoZWFsdGggc3RhdHVzLiBPdmVy
YWxsIHN0YXR1cyBpcyBkZXJpdmVkIGJhc2VkIG9uIHRoZSBzdGF0dXMgb2YKIGVhY2ggc3Vi
IGxldmVsIHJlc291cmNlcy4KCgwKBQQAAgEGEgM7Ag4KDAoFBAACAQESAzsPFQoMCgUEAAIB
AxIDOxgZClAKBAQAAgISAz4CIxpDIFNwZWNpZmljIGRldGFpbHMgZm9yIHRoZSByZXNvdXJj
ZS4gVGhpcyBpcyBmb3IgaW50ZXJuYWwgdXNlIG9ubHkuCgoMCgUEAAICBhIDPgIVCgwKBQQA
AgIBEgM+Fh4KDAoFBAACAgMSAz4hIgpwCgQEAAIDEgNCAiUaYyBUaGUgdGltZXN0YW1wIHRv
IGNvbGxlY3QgdGhlIGluZm8uIEl0IGlzIHN1Z2dlc3RlZCB0byBiZSBzZXQgYnkKIHRoZSB0
b3Btb3N0IGxldmVsIHJlc291cmNlIG9ubHkuCgoMCgUEAAIDBhIDQgIbCgwKBQQAAgMBEgNC
HCAKDAoFBAACAwMSA0IjJAo4CgQEAAIEEgNFAiAaKyBMaXN0IG9mIEluZm8gZm9yIHRoZSBz
dWIgbGV2ZWwgcmVzb3VyY2VzLgoKDAoFBAACBAQSA0UCCgoMCgUEAAIEBhIDRQsXCgwKBQQA
AgQBEgNFGBsKDAoFBAACBAMSA0UeHwpQCgIEARIESQBVARpEIENvbnRhaW5lckhlYWx0aERl
dGFpbHMgcmVmbGVjdHMgdGhlIGhlYWx0aCBkZXRhaWxzIG9mIGEgY29udGFpbmVyLgoKCgoD
BAEBEgNJCB4KMgoEBAECABIDSwIlGiUgVGhlIHZlcnNpb24gb2YgdGhlIGV4cGVjdGVkIGNv
bmZpZy4KCgwKBQQBAgAFEgNLAggKDAoFBAECAAESA0sJIAoMCgUEAQIAAxIDSyMkCjEKBAQB
AgESA04CJBokIFRoZSB2ZXJzaW9uIG9mIHRoZSBjdXJyZW50IGNvbmZpZy4KCgwKBQQBAgEF
EgNOAggKDAoFBAECAQESA04JHwoMCgUEAQIBAxIDTiIjClEKBAQBAgISA1ECKhpEIFRoZSBl
eHRlbmRlZCBzdGF0dXMuIFN1Y2ggYXMgRXhpdENvZGUsIFN0YXJ0ZWRBdCwgRmluaXNoZWRB
dCwgZXRjLgoKDAoFBAECAgYSA1ECFQoMCgUEAQICARIDURYlCgwKBQQBAgIDEgNRKCkKKAoE
BAECAxIDVAIXGhsgVGhlIGxhdGVzdCBlcnJvciBtZXNzYWdlLgoKDAoFBAECAwUSA1QCCAoM
CgUEAQIDARIDVAkSCgwKBQQBAgMDEgNUFRYKRwoCBAISA1gAHRo8IFJlbW90ZUFnZW50RGV0
YWlscyByZWZsZWN0cyB0aGUgZGV0YWlscyBvZiBhIHJlbW90ZSBhZ2VudC4KCgoKAwQCARID
WAgaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo ===
    # Fields for ResourceInfo
    # Field: id Type: 9 ()
    # Field: status Type: 14 (.google.cloud.beyondcorp.appconnectors.v1.HealthStatus)
    # Field: resource Type: 11 (.google.protobuf.Any)
    # Field: time Type: 11 (.google.protobuf.Timestamp)
    # Field: sub Type: 11 (.google.cloud.beyondcorp.appconnectors.v1.ResourceInfo)

# === Message: Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails ===
    # Fields for ContainerHealthDetails
    # Field: expected_config_version Type: 9 ()
    # Field: current_config_version Type: 9 ()
    # Field: extended_status Type: 11 (.google.cloud.beyondcorp.appconnectors.v1.ContainerHealthDetails.ExtendedStatusEntry)
    # Field: error_msg Type: 9 ()

# === Message: Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::RemoteAgentDetails ===
    # Fields for RemoteAgentDetails

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo - Compiled Protocol Buffers messages for google/cloud/beyondcorp/appconnectors/v1/resource_info.proto

=head1 SYNOPSIS

    use Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo;

    my $msg = Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo->new({
        id => $id,
        status => $status,
        resource => $resource,
        time => $time,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/beyondcorp/appconnectors/v1/resource_info.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo

ResourceInfo represents the information or status of an app connector
resource component that's used to report on various parts of the system. For
example, ResourceInfo can be used to convey the status of a remote_agent,
including the status of an appgateway for an runtime environment in a
container instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. Unique Id for the resource.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Beyondcorp::Appconnectors::V1::HealthStatus>)

Overall health status. Overall status is derived based on the status of
each sub level resources.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Specific details for the resource. This is for internal use only.

=item * C<< $msg->time() >> / C<< $msg->time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp to collect the info. It is suggested to be set by
the topmost level resource only.

=item * C<< $msg->sub() >> / C<< $msg->sub($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo>)

List of Info for the sub level resources.

=back

=head2 Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails

ContainerHealthDetails reflects the health details of a container.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expected_config_version() >> / C<< $msg->expected_config_version($value) >>

Type: C<String>

The version of the expected config.

=item * C<< $msg->current_config_version() >> / C<< $msg->current_config_version($value) >>

Type: C<String>

The version of the current config.

=item * C<< $msg->extended_status() >> / C<< $msg->extended_status($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails::ExtendedStatusEntry>)

The extended status. Such as ExitCode, StartedAt, FinishedAt, etc.

=item * C<< $msg->error_msg() >> / C<< $msg->error_msg($value) >>

Type: C<String>

The latest error message.

=back

=head2 Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::RemoteAgentDetails

RemoteAgentDetails reflects the details of a remote agent.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
