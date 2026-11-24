package Google::Cloud::Workstations::Logging::V1::PlatformLogs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvd29ya3N0YXRpb25zL2xvZ2dpbmcvdjEvcGxhdGZvcm1fbG9ncy5w
cm90bxIkZ29vZ2xlLmNsb3VkLndvcmtzdGF0aW9ucy5sb2dnaW5nLnYxIvwBChBXb3Jrc3Rh
dGlvbkV2ZW50EmkKE3ZtX2Fzc2lnbm1lbnRfZXZlbnQYASABKAsyNy5nb29nbGUuY2xvdWQu
d29ya3N0YXRpb25zLmxvZ2dpbmcudjEuVm1Bc3NpZ25tZW50RXZlbnRIAFIRdm1Bc3NpZ25t
ZW50RXZlbnQSbwoVZGlza19hc3NpZ25tZW50X2V2ZW50GAIgASgLMjkuZ29vZ2xlLmNsb3Vk
LndvcmtzdGF0aW9ucy5sb2dnaW5nLnYxLkRpc2tBc3NpZ25tZW50RXZlbnRIAFITZGlza0Fz
c2lnbm1lbnRFdmVudEIMCgpldmVudF90eXBlIiMKEVZtQXNzaWdubWVudEV2ZW50Eg4KAnZt
GAEgASgJUgJ2bSIpChNEaXNrQXNzaWdubWVudEV2ZW50EhIKBGRpc2sYASABKAlSBGRpc2tC
gwEKKGNvbS5nb29nbGUuY2xvdWQud29ya3N0YXRpb25zLmxvZ2dpbmcudjFCEVBsYXRmb3Jt
TG9nc1Byb3RvUAFaQmNsb3VkLmdvb2dsZS5jb20vZ28vd29ya3N0YXRpb25zL2xvZ2dpbmcv
YXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYkqMCgoGEgQOAC0BCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCggKAQgSAxIAWQoJCgIICxIDEgBZCggKAQgS
AxMAIgoJCgIIChIDEwAiCggKAQgSAxQAMgoJCgIICBIDFAAyCggKAQgSAxUAQQoJCgIIARID
FQBBCmsKAgQAEgQZACEBGl8gSlNPTiBwYXlsb2FkIGZvciB0aGUgQ2xvdWQgTG9nZ2luZyBl
dmVudDoKIGB3b3Jrc3RhdGlvbnMuZ29vZ2xlYXBpcy5jb20lMkZ3b3Jrc3RhdGlvbl9ldmVu
dHNgCgoKCgMEAAESAxkIGAoMCgQEAAgAEgQaAiADCgwKBQQACAABEgMaCBIKIwoEBAACABID
HAQuGhYgVm0gYXNzaWdubWVudCBldmVudC4KCgwKBQQAAgAGEgMcBBUKDAoFBAACAAESAxwW
KQoMCgUEAAIAAxIDHCwtCiUKBAQAAgESAx8EMhoYIERpc2sgYXNzaWdubWVudCBldmVudC4K
CgwKBQQAAgEGEgMfBBcKDAoFBAACAQESAx8YLQoMCgUEAAIBAxIDHzAxCiIKAgQBEgQkACcB
GhYgVm0gYXNzaWdubWVudCBldmVudC4KCgoKAwQBARIDJAgZCjsKBAQBAgASAyYCEBouIE5h
bWUgb2YgdGhlIFZNIGFzc2lnbmVkIHRvIHRoaXMgd29ya3N0YXRpb24uCgoMCgUEAQIABRID
JgIICgwKBQQBAgABEgMmCQsKDAoFBAECAAMSAyYODwokCgIEAhIEKgAtARoYIERpc2sgYXNz
aWdubWVudCBldmVudC4KCgoKAwQCARIDKggbCj0KBAQCAgASAywCEhowIE5hbWUgb2YgdGhl
IGRpc2sgYXNzaWduZWQgdG8gdGhpcyB3b3Jrc3RhdGlvbi4KCgwKBQQCAgAFEgMsAggKDAoF
BAICAAESAywJDQoMCgUEAgIAAxIDLBARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent ===
    # Fields for WorkstationEvent
    # Field: vm_assignment_event Type: 11 (.google.cloud.workstations.logging.v1.VmAssignmentEvent)
    # Field: disk_assignment_event Type: 11 (.google.cloud.workstations.logging.v1.DiskAssignmentEvent)

# === Message: Google::Cloud::Workstations::Logging::V1::PlatformLogs::VmAssignmentEvent ===
    # Fields for VmAssignmentEvent
    # Field: vm Type: 9 ()

# === Message: Google::Cloud::Workstations::Logging::V1::PlatformLogs::DiskAssignmentEvent ===
    # Fields for DiskAssignmentEvent
    # Field: disk Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Workstations::Logging::V1::PlatformLogs - Compiled Protocol Buffers messages for google/cloud/workstations/logging/v1/platform_logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Workstations::Logging::V1::PlatformLogs;

    my $msg = Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent->new({
        vm_assignment_event => $vm_assignment_event,
        disk_assignment_event => $disk_assignment_event,
    });

    # Read or update a field
    my $val = $msg->vm_assignment_event();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/workstations/logging/v1/platform_logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Workstations::Logging::V1::PlatformLogs::WorkstationEvent

JSON payload for the Cloud Logging event:
`workstations.googleapis.com%2Fworkstation_events`

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vm_assignment_event() >> / C<< $msg->vm_assignment_event($value) >>

Type: C<Message> (L<Google::Cloud::Workstations::Logging::V1::PlatformLogs::VmAssignmentEvent>)

Vm assignment event.

=item * C<< $msg->disk_assignment_event() >> / C<< $msg->disk_assignment_event($value) >>

Type: C<Message> (L<Google::Cloud::Workstations::Logging::V1::PlatformLogs::DiskAssignmentEvent>)

Disk assignment event.

=back

=head2 Google::Cloud::Workstations::Logging::V1::PlatformLogs::VmAssignmentEvent

Vm assignment event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vm() >> / C<< $msg->vm($value) >>

Type: C<String>

Name of the VM assigned to this workstation.

=back

=head2 Google::Cloud::Workstations::Logging::V1::PlatformLogs::DiskAssignmentEvent

Disk assignment event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disk() >> / C<< $msg->disk($value) >>

Type: C<String>

Name of the disk assigned to this workstation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Workstations::Logging::V1::PlatformLogs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
