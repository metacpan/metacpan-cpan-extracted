package Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX2JhY2t1cF9jaGFu
bmVsLnByb3RvEiFnb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEi/wEKE0xvZ2dl
ZEJhY2t1cENoYW5uZWwSLwoTZGVzdGluYXRpb25fcHJvamVjdBgBIAEoCVISZGVzdGluYXRp
b25Qcm9qZWN0EloKBmxhYmVscxgCIAMoCzJCLmdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9n
Z2luZy52MS5Mb2dnZWRCYWNrdXBDaGFubmVsLkxhYmVsc0VudHJ5UgZsYWJlbHMSIAoLZGVz
Y3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFC9AEKJWNvbS5nb29nbGUuY2xvdWQu
Z2tlYmFja3VwLmxvZ2dpbmcudjFCGExvZ2dlZEJhY2t1cENoYW5uZWxQcm90b1ABWj9jbG91
ZC5nb29nbGUuY29tL2dvL2drZWJhY2t1cC9sb2dnaW5nL2FwaXYxL2xvZ2dpbmdwYjtsb2dn
aW5ncGKqAiFHb29nbGUuQ2xvdWQuR2tlQmFja3VwLkxvZ2dpbmcuVjHKAiFHb29nbGVcQ2xv
dWRcR2tlQmFja3VwXExvZ2dpbmdcVjHqAiVHb29nbGU6OkNsb3VkOjpHa2VCYWNrdXA6Okxv
Z2dpbmc6OlYxSsgKCgYSBA4AKAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQACoKCAoBCBIDEgA+CgkKAgglEgMSAD4KCAoBCBIDEwBWCgkKAggLEgMTAFYK
CAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA5CgkKAggIEgMVADkKCAoBCBIDFgA+CgkK
AggBEgMWAD4KCAoBCBIDFwA/CgkKAggpEgMXAD8KCAoBCBIDGAA+CgkKAggtEgMYAD4K6wEK
AgQAEgQeACgBGt4BIEEgQmFja3VwQ2hhbm5lbCBpbXBvc2VzIGNvbnN0cmFpbnRzIG9uIHdo
ZXJlIGNsdXN0ZXJzIGNhbiBiZSBiYWNrZWQgdXAuCiBUaGUgQmFja3VwQ2hhbm5lbCBzaG91
bGQgYmUgaW4gdGhlIHNhbWUgcHJvamVjdCBhbmQgcmVnaW9uCiBhcyB0aGUgY2x1c3RlciBi
ZWluZyBiYWNrZWQgdXAuCiBUaGUgYmFja3VwIGNhbiBiZSBjcmVhdGVkIG9ubHkgaW4gZGVz
dGluYXRpb25fcHJvamVjdC4KCgoKAwQAARIDHggbCmcKBAQAAgASAyECIRpaIFRoZSBwcm9q
ZWN0IHdoZXJlIEJhY2t1cHMgYXJlIGFsbG93ZWQgdG8gYmUgc3RvcmVkLgogVGhlIGZvcm1h
dCBpcyBgcHJvamVjdHMve3Byb2plY3R9YC4KCgwKBQQAAgAFEgMhAggKDAoFBAACAAESAyEJ
HAoMCgUEAAIAAxIDIR8gCjcKBAQAAgESAyQCIRoqIEEgc2V0IG9mIGN1c3RvbSBsYWJlbHMg
c3VwcGxpZWQgYnkgdXNlci4KCgwKBQQAAgEGEgMkAhUKDAoFBAACAQESAyQWHAoMCgUEAAIB
AxIDJB8gCkgKBAQAAgISAycCGRo7IFVzZXIgc3BlY2lmaWVkIGRlc2NyaXB0aXZlIHN0cmlu
ZyBmb3IgdGhpcyBCYWNrdXBDaGFubmVsLgoKDAoFBAACAgUSAycCCAoMCgUEAAICARIDJwkU
CgwKBQQAAgIDEgMnFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel ===
    # Fields for LoggedBackupChannel
    # Field: destination_project Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackupChannel.LabelsEntry)
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_backup_channel.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel->new({
        destination_project => $destination_project,
        labels => $labels,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->destination_project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_backup_channel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel

A BackupChannel imposes constraints on where clusters can be backed up.
The BackupChannel should be in the same project and region
as the cluster being backed up.
The backup can be created only in destination_project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->destination_project() >> / C<< $msg->destination_project($value) >>

Type: C<String>

The project where Backups are allowed to be stored.
The format is `projects/{project}`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel::LabelsEntry>)

A set of custom labels supplied by user.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified descriptive string for this BackupChannel.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
