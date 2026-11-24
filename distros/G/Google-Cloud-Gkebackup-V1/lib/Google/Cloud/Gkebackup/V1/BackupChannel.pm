package Google::Cloud::Gkebackup::V1::BackupChannel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL2JhY2t1cF9jaGFubmVsLnByb3RvEhlnb29n
bGUuY2xvdWQuZ2tlYmFja3VwLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipAUKDUJhY2t1cENoYW5uZWwS
FwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEjcKE2Rlc3RpbmF0aW9uX3Byb2plY3QYAiABKAlC
BuBBBeBBAlISZGVzdGluYXRpb25Qcm9qZWN0Eh0KA3VpZBgDIAEoCUIL4ozP1wgCCAHgQQNS
A3VpZBJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJRCgZsYWJlbHMYBiADKAsyNC5nb29nbGUu
Y2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1cENoYW5uZWwuTGFiZWxzRW50cnlCA+BBAVIGbGFi
ZWxzEiUKC2Rlc2NyaXB0aW9uGAcgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEhcKBGV0YWcYCCAB
KAlCA+BBA1IEZXRhZxI5ChZkZXN0aW5hdGlvbl9wcm9qZWN0X2lkGAkgASgJQgPgQQNSFGRl
c3RpbmF0aW9uUHJvamVjdElkGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6lAHqQZABCiZna2ViYWNrdXAuZ29vZ2xlYXBpcy5j
b20vQmFja3VwQ2hhbm5lbBJHcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2JhY2t1cENoYW5uZWxzL3tiYWNrdXBfY2hhbm5lbH0qDmJhY2t1cENoYW5uZWxzMg1i
YWNrdXBDaGFubmVsQskBCh1jb20uZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MUISQmFja3Vw
Q2hhbm5lbFByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3VwL2FwaXYxL2dr
ZWJhY2t1cHBiO2drZWJhY2t1cHBiqgIZR29vZ2xlLkNsb3VkLkdrZUJhY2t1cC5WMcoCGUdv
b2dsZVxDbG91ZFxHa2VCYWNrdXBcVjHqAhxHb29nbGU6OkNsb3VkOjpHa2VCYWNrdXA6OlYx
SoUaCgYSBA4AXAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACIKCQoCAwASAxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKQoICgEIEgMX
ADYKCQoCCCUSAxcANgoICgEIEgMYAFIKCQoCCAsSAxgAUgoICgEIEgMZACIKCQoCCAoSAxkA
IgoICgEIEgMaADMKCQoCCAgSAxoAMwoICgEIEgMbADYKCQoCCAESAxsANgoICgEIEgMcADYK
CQoCCCkSAxwANgoICgEIEgMdADUKCQoCCC0SAx0ANQrrAQoCBAASBCMAXAEa3gEgQSBCYWNr
dXBDaGFubmVsIGltcG9zZXMgY29uc3RyYWludHMgb24gd2hlcmUgY2x1c3RlcnMgY2FuIGJl
IGJhY2tlZCB1cC4KIFRoZSBCYWNrdXBDaGFubmVsIHNob3VsZCBiZSBpbiB0aGUgc2FtZSBw
cm9qZWN0IGFuZCByZWdpb24KIGFzIHRoZSBjbHVzdGVyIGJlaW5nIGJhY2tlZCB1cC4KIFRo
ZSBiYWNrdXAgY2FuIGJlIGNyZWF0ZWQgb25seSBpbiBkZXN0aW5hdGlvbl9wcm9qZWN0LgoK
CgoDBAABEgMjCBUKCwoDBAAHEgQkAikECg0KBQQAB50IEgQkAikECnQKBAQAAgASAy0CPRpn
IElkZW50aWZpZXIuIFRoZSBmdWxseSBxdWFsaWZpZWQgbmFtZSBvZiB0aGUgQmFja3VwQ2hh
bm5lbC4KIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2JhY2t1cENoYW5uZWxzLypgCgoMCgUE
AAIABRIDLQIICgwKBQQAAgABEgMtCQ0KDAoFBAACAAMSAy0QEQoMCgUEAAIACBIDLRI8Cg8K
CAQAAgAInAgAEgMtEzsKngEKBAQAAgESBDECNAQajwEgUmVxdWlyZWQuIEltbXV0YWJsZS4g
VGhlIHByb2plY3Qgd2hlcmUgQmFja3VwcyBhcmUgYWxsb3dlZCB0byBiZSBzdG9yZWQuCiBU
aGUgZm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdElkfWAgb3IgYHByb2plY3RzL3twcm9q
ZWN0TnVtYmVyfWAuCgoMCgUEAAIBBRIDMQIICgwKBQQAAgEBEgMxCRwKDAoFBAACAQMSAzEf
IAoNCgUEAAIBCBIEMSE0AwoPCggEAAIBCJwIABIDMgQrCg8KCAQAAgEInAgBEgMzBCoKlwEK
BAQAAgISBDgCOwQaiAEgT3V0cHV0IG9ubHkuIFNlcnZlciBnZW5lcmF0ZWQgZ2xvYmFsIHVu
aXF1ZSBpZGVudGlmaWVyIG9mCiBbVVVJRF0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dp
a2kvVW5pdmVyc2FsbHlfdW5pcXVlX2lkZW50aWZpZXIpIGZvcm1hdC4KCgwKBQQAAgIFEgM4
AggKDAoFBAACAgESAzgJDAoMCgUEAAICAxIDOA8QCg0KBQQAAgIIEgQ4ETsDChIKCwQAAgII
zPH5igEBEgM5BCoKDwoIBAACAgicCAASAzoELQpYCgQEAAIDEgQ+Aj8yGkogT3V0cHV0IG9u
bHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIEJhY2t1cENoYW5uZWwgcmVzb3VyY2Ugd2Fz
IGNyZWF0ZWQuCgoMCgUEAAIDBhIDPgIbCgwKBQQAAgMBEgM+HCcKDAoFBAACAwMSAz4qKwoM
CgUEAAIDCBIDPwYxCg8KCAQAAgMInAgAEgM/BzAKXgoEBAACBBIEQwJEMhpQIE91dHB1dCBv
bmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBCYWNrdXBDaGFubmVsIHJlc291cmNlIHdh
cyBsYXN0CiB1cGRhdGVkLgoKDAoFBAACBAYSA0MCGwoMCgUEAAIEARIDQxwnCgwKBQQAAgQD
EgNDKisKDAoFBAACBAgSA0QGMQoPCggEAAIECJwIABIDRAcwCkEKBAQAAgUSA0cCSho0IE9w
dGlvbmFsLiBBIHNldCBvZiBjdXN0b20gbGFiZWxzIHN1cHBsaWVkIGJ5IHVzZXIuCgoMCgUE
AAIFBhIDRwIVCgwKBQQAAgUBEgNHFhwKDAoFBAACBQMSA0cfIAoMCgUEAAIFCBIDRyFJCg8K
CAQAAgUInAgAEgNHIkgKUgoEBAACBhIDSgJCGkUgT3B0aW9uYWwuIFVzZXIgc3BlY2lmaWVk
IGRlc2NyaXB0aXZlIHN0cmluZyBmb3IgdGhpcyBCYWNrdXBDaGFubmVsLgoKDAoFBAACBgUS
A0oCCAoMCgUEAAIGARIDSgkUCgwKBQQAAgYDEgNKFxgKDAoFBAACBggSA0oZQQoPCggEAAIG
CJwIABIDShpACs0ECgQEAAIHEgNVAj4avwQgT3V0cHV0IG9ubHkuIGBldGFnYCBpcyB1c2Vk
IGZvciBvcHRpbWlzdGljIGNvbmN1cnJlbmN5IGNvbnRyb2wgYXMgYSB3YXkgdG8KIGhlbHAg
cHJldmVudCBzaW11bHRhbmVvdXMgdXBkYXRlcyBvZiBhIEJhY2t1cENoYW5uZWwgZnJvbSBv
dmVyd3JpdGluZyBlYWNoCiBvdGhlci4gSXQgaXMgc3Ryb25nbHkgc3VnZ2VzdGVkIHRoYXQg
c3lzdGVtcyBtYWtlIHVzZSBvZiB0aGUgJ2V0YWcnIGluIHRoZQogcmVhZC1tb2RpZnktd3Jp
dGUgY3ljbGUgdG8gcGVyZm9ybSBCYWNrdXBDaGFubmVsIHVwZGF0ZXMgaW4gb3JkZXIgdG8K
IGF2b2lkIHJhY2UgY29uZGl0aW9uczogQW4gYGV0YWdgIGlzIHJldHVybmVkIGluIHRoZSBy
ZXNwb25zZSB0bwogYEdldEJhY2t1cENoYW5uZWxgLCBhbmQgc3lzdGVtcyBhcmUgZXhwZWN0
ZWQgdG8gcHV0IHRoYXQgZXRhZyBpbiB0aGUKIHJlcXVlc3QgdG8gYFVwZGF0ZUJhY2t1cENo
YW5uZWxgIG9yIGBEZWxldGVCYWNrdXBDaGFubmVsYCB0bwogZW5zdXJlIHRoYXQgdGhlaXIg
Y2hhbmdlIHdpbGwgYmUgYXBwbGllZCB0byB0aGUgc2FtZSB2ZXJzaW9uIG9mIHRoZQogcmVz
b3VyY2UuCgoMCgUEAAIHBRIDVQIICgwKBQQAAgcBEgNVCQ0KDAoFBAACBwMSA1UQEQoMCgUE
AAIHCBIDVRI9Cg8KCAQAAgcInAgAEgNVEzwK0gEKBAQAAggSA1sCUBrEASBPdXRwdXQgb25s
eS4gVGhlIHByb2plY3RfaWQgd2hlcmUgQmFja3VwcyBhcmUgYWxsb3dlZCB0byBiZSBzdG9y
ZWQuCiBFeGFtcGxlIFByb2plY3QgSUQ6ICJteS1wcm9qZWN0LWlkIi4KIFRoaXMgd2lsbCBi
ZSBhbiBPVVRQVVRfT05MWSBmaWVsZCB0byByZXR1cm4gdGhlIHByb2plY3RfaWQgb2YgdGhl
CiBkZXN0aW5hdGlvbiBwcm9qZWN0LgoKDAoFBAACCAUSA1sCCAoMCgUEAAIIARIDWwkfCgwK
BQQAAggDEgNbIiMKDAoFBAACCAgSA1skTwoPCggEAAIICJwIABIDWyVOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel ===
    # Fields for BackupChannel
    # Field: name Type: 9 ()
    # Field: destination_project Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.gkebackup.v1.BackupChannel.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: destination_project_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::BackupChannel - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/backup_channel.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::BackupChannel;

    my $msg = Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel->new({
        name => $name,
        destination_project => $destination_project,
        uid => $uid,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/backup_channel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel

A BackupChannel imposes constraints on where clusters can be backed up.
The BackupChannel should be in the same project and region
as the cluster being backed up.
The backup can be created only in destination_project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The fully qualified name of the BackupChannel.
`projects/*/locations/*/backupChannels/*`

=item * C<< $msg->destination_project() >> / C<< $msg->destination_project($value) >>

Type: C<String>

Required. Immutable. The project where Backups are allowed to be stored.
The format is `projects/{projectId}` or `projects/{projectNumber}`.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this BackupChannel resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this BackupChannel resource was last
updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel::LabelsEntry>)

Optional. A set of custom labels supplied by user.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User specified descriptive string for this BackupChannel.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a BackupChannel from overwriting each
other. It is strongly suggested that systems make use of the 'etag' in the
read-modify-write cycle to perform BackupChannel updates in order to
avoid race conditions: An `etag` is returned in the response to
`GetBackupChannel`, and systems are expected to put that etag in the
request to `UpdateBackupChannel` or `DeleteBackupChannel` to
ensure that their change will be applied to the same version of the
resource.

=item * C<< $msg->destination_project_id() >> / C<< $msg->destination_project_id($value) >>

Type: C<String>

Output only. The project_id where Backups are allowed to be stored.
Example Project ID: "my-project-id".
This will be an OUTPUT_ONLY field to return the project_id of the
destination project.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::BackupChannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
