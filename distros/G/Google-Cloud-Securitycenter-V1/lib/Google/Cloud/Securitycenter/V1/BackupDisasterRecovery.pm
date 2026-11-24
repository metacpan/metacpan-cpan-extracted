package Google::Cloud::Securitycenter::V1::BackupDisasterRecovery;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYmFja3VwX2Rpc2FzdGVyX3JlY292
ZXJ5LnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8iggMKFkJhY2t1cERpc2FzdGVyUmVjb3ZlcnkSJwoPYmFj
a3VwX3RlbXBsYXRlGAEgASgJUg5iYWNrdXBUZW1wbGF0ZRIaCghwb2xpY2llcxgCIAMoCVII
cG9saWNpZXMSEgoEaG9zdBgDIAEoCVIEaG9zdBIiCgxhcHBsaWNhdGlvbnMYBCADKAlSDGFw
cGxpY2F0aW9ucxIhCgxzdG9yYWdlX3Bvb2wYBSABKAlSC3N0b3JhZ2VQb29sEiUKDnBvbGlj
eV9vcHRpb25zGAYgAygJUg1wb2xpY3lPcHRpb25zEhgKB3Byb2ZpbGUYByABKAlSB3Byb2Zp
bGUSHAoJYXBwbGlhbmNlGAggASgJUglhcHBsaWFuY2USHwoLYmFja3VwX3R5cGUYCSABKAlS
CmJhY2t1cFR5cGUSSAoSYmFja3VwX2NyZWF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFIQYmFja3VwQ3JlYXRlVGltZUL1AQoiY29tLmdvb2dsZS5jbG91ZC5z
ZWN1cml0eWNlbnRlci52MUIbQmFja3VwRGlzYXN0ZXJSZWNvdmVyeVByb3RvUAFaSmNsb3Vk
Lmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtz
ZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29v
Z2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlD
ZW50ZXI6OlYxSoweCgYSBA4AVwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQACcKCQoCAwASAxIAKQoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEK
CQoCCAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADwKCQoCCAgSAxcAPAoI
CgEIEgMYADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoC
CC0SAxoAOgpRCgIEABIEHQBXARpFIEluZm9ybWF0aW9uIHJlbGF0ZWQgdG8gR29vZ2xlIENs
b3VkIEJhY2t1cCBhbmQgRFIgU2VydmljZSBmaW5kaW5ncy4KCgoKAwQAARIDHQgeCooCCgQE
AAIAEgMiAh0a/AEgVGhlIG5hbWUgb2YgYSBCYWNrdXAgYW5kIERSIHRlbXBsYXRlIHdoaWNo
IGNvbXByaXNlcyBvbmUgb3IgbW9yZSBiYWNrdXAKIHBvbGljaWVzLiBTZWUgdGhlIFtCYWNr
dXAgYW5kIERSCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmFj
a3VwLWRpc2FzdGVyLXJlY292ZXJ5L2RvY3MvY29uY2VwdHMvYmFja3VwLXBsYW4jdGVtcCkK
IGZvciBtb3JlIGluZm9ybWF0aW9uLiBGb3IgZXhhbXBsZSwgYHNuYXAtb3ZgLgoKDAoFBAAC
AAUSAyICCAoMCgUEAAIAARIDIgkYCgwKBQQAAgADEgMiGxwK4QEKBAQAAgESAycCHxrTASBU
aGUgbmFtZXMgb2YgQmFja3VwIGFuZCBEUiBwb2xpY2llcyB0aGF0IGFyZSBhc3NvY2lhdGVk
IHdpdGggYSB0ZW1wbGF0ZQogYW5kIHRoYXQgZGVmaW5lIHdoZW4gdG8gcnVuIGEgYmFja3Vw
LCBob3cgZnJlcXVlbnRseSB0byBydW4gYSBiYWNrdXAsIGFuZAogaG93IGxvbmcgdG8gcmV0
YWluIHRoZSBiYWNrdXAgaW1hZ2UuIEZvciBleGFtcGxlLCBgb252YXVsdHNgLgoKDAoFBAAC
AQQSAycCCgoMCgUEAAIBBRIDJwsRCgwKBQQAAgEBEgMnEhoKDAoFBAACAQMSAycdHgrkAwoE
BAACAhIDMAISGtYDIFRoZSBuYW1lIG9mIGEgQmFja3VwIGFuZCBEUiBob3N0LCB3aGljaCBp
cyBtYW5hZ2VkIGJ5IHRoZSBiYWNrdXAgYW5kCiByZWNvdmVyeSBhcHBsaWFuY2UgYW5kIGtu
b3duIHRvIHRoZSBtYW5hZ2VtZW50IGNvbnNvbGUuIFRoZSBob3N0IGNhbiBiZSBvZgogdHlw
ZSBHZW5lcmljIChmb3IgZXhhbXBsZSwgQ29tcHV0ZSBFbmdpbmUsIFNRTCBTZXJ2ZXIsIE9y
YWNsZSBEQiwgU01CIGZpbGUKIHN5c3RlbSwgZXRjLiksIHZDZW50ZXIsIG9yIGFuIEVTWCBz
ZXJ2ZXIuIFNlZSB0aGUgW0JhY2t1cCBhbmQgRFIKIGRvY3VtZW50YXRpb24gb24KIGhvc3Rz
XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmFja3VwLWRpc2FzdGVyLXJlY292ZXJ5L2Rv
Y3MvY29uZmlndXJhdGlvbi9tYW5hZ2UtaG9zdHMtYW5kLXRoZWlyLWFwcGxpY2F0aW9ucykK
IGZvciBtb3JlIGluZm9ybWF0aW9uLiBGb3IgZXhhbXBsZSwgYGNlbnRvczctMDFgLgoKDAoF
BAACAgUSAzACCAoMCgUEAAICARIDMAkNCgwKBQQAAgIDEgMwEBEK9QEKBAQAAgMSAzYCIxrn
ASBUaGUgbmFtZXMgb2YgQmFja3VwIGFuZCBEUiBhcHBsaWNhdGlvbnMuIEFuIGFwcGxpY2F0
aW9uIGlzIGEgVk0sIGRhdGFiYXNlLAogb3IgZmlsZSBzeXN0ZW0gb24gYSBtYW5hZ2VkIGhv
c3QgbW9uaXRvcmVkIGJ5IGEgYmFja3VwIGFuZCByZWNvdmVyeQogYXBwbGlhbmNlLiBGb3Ig
ZXhhbXBsZSwgYGNlbnRvczctMDEtdm9sMDBgLCBgY2VudG9zNy0wMS12b2wwMWAsCiBgY2Vu
dG9zNy0wMS12b2wwMmAuCgoMCgUEAAIDBBIDNgIKCgwKBQQAAgMFEgM2CxEKDAoFBAACAwES
AzYSHgoMCgUEAAIDAxIDNiEiCuUCCgQEAAIEEgM+Ahoa1wIgVGhlIG5hbWUgb2YgdGhlIEJh
Y2t1cCBhbmQgRFIgc3RvcmFnZSBwb29sIHRoYXQgdGhlIGJhY2t1cCBhbmQgcmVjb3ZlcnkK
IGFwcGxpYW5jZSBpcyBzdG9yaW5nIGRhdGEgaW4uIFRoZSBzdG9yYWdlIHBvb2wgY291bGQg
YmUgb2YgdHlwZSBDbG91ZCwKIFByaW1hcnksIFNuYXBzaG90LCBvciBPblZhdWx0LiBTZWUg
dGhlIFtCYWNrdXAgYW5kIERSIGRvY3VtZW50YXRpb24gb24KIHN0b3JhZ2UKIHBvb2xzXSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmFja3VwLWRpc2FzdGVyLXJlY292ZXJ5L2RvY3Mv
Y29uY2VwdHMvc3RvcmFnZS1wb29scykuCiBGb3IgZXhhbXBsZSwgYERpc2tQb29sT25lYC4K
CgwKBQQAAgQFEgM+AggKDAoFBAACBAESAz4JFQoMCgUEAAIEAxIDPhgZCqsCCgQEAAIFEgNE
AiUanQIgVGhlIG5hbWVzIG9mIEJhY2t1cCBhbmQgRFIgYWR2YW5jZWQgcG9saWN5IG9wdGlv
bnMgb2YgYSBwb2xpY3kgYXBwbHlpbmcgdG8KIGFuIGFwcGxpY2F0aW9uLiBTZWUgdGhlIFtC
YWNrdXAgYW5kIERSIGRvY3VtZW50YXRpb24gb24gcG9saWN5CiBvcHRpb25zXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vYmFja3VwLWRpc2FzdGVyLXJlY292ZXJ5L2RvY3MvY3JlYXRl
LXBsYW4vcG9saWN5LXNldHRpbmdzKS4KIEZvciBleGFtcGxlLCBgc2tpcG9mZmxpbmVhcHBz
aW5jb25ncnAsIG5vdW5tYXBgLgoKDAoFBAACBQQSA0QCCgoMCgUEAAIFBRIDRAsRCgwKBQQA
AgUBEgNEEiAKDAoFBAACBQMSA0QjJAqnAgoEBAACBhIDSwIVGpkCIFRoZSBuYW1lIG9mIHRo
ZSBCYWNrdXAgYW5kIERSIHJlc291cmNlIHByb2ZpbGUgdGhhdCBzcGVjaWZpZXMgdGhlIHN0
b3JhZ2UKIG1lZGlhIGZvciBiYWNrdXBzIG9mIGFwcGxpY2F0aW9uIGFuZCBWTSBkYXRhLiBT
ZWUgdGhlIFtCYWNrdXAgYW5kIERSCiBkb2N1bWVudGF0aW9uIG9uCiBwcm9maWxlc10oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JhY2t1cC1kaXNhc3Rlci1yZWNvdmVyeS9kb2NzL2Nv
bmNlcHRzL2JhY2t1cC1wbGFuI3Byb2ZpbGUpLgogRm9yIGV4YW1wbGUsIGBHQ1BgLgoKDAoF
BAACBgUSA0sCCAoMCgUEAAIGARIDSwkQCgwKBQQAAgYDEgNLExQKnAEKBAQAAgcSA08CFxqO
ASBUaGUgbmFtZSBvZiB0aGUgQmFja3VwIGFuZCBEUiBhcHBsaWFuY2UgdGhhdCBjYXB0dXJl
cywgbW92ZXMsIGFuZCBtYW5hZ2VzCiB0aGUgbGlmZWN5Y2xlIG9mIGJhY2t1cCBkYXRhLiBG
b3IgZXhhbXBsZSwgYGJhY2t1cC1zZXJ2ZXItNTcxMzdgLgoKDAoFBAACBwUSA08CCAoMCgUE
AAIHARIDTwkSCgwKBQQAAgcDEgNPFRYKcgoEBAACCBIDUwIZGmUgVGhlIGJhY2t1cCB0eXBl
IG9mIHRoZSBCYWNrdXAgYW5kIERSIGltYWdlLgogRm9yIGV4YW1wbGUsIGBTbmFwc2hvdGAs
IGBSZW1vdGUgU25hcHNob3RgLCBgT25WYXVsdGAuCgoMCgUEAAIIBRIDUwIICgwKBQQAAggB
EgNTCRQKDAoFBAACCAMSA1MXGApLCgQEAAIJEgNWAjQaPiBUaGUgdGltZXN0YW1wIGF0IHdo
aWNoIHRoZSBCYWNrdXAgYW5kIERSIGJhY2t1cCB3YXMgY3JlYXRlZC4KCgwKBQQAAgkGEgNW
AhsKDAoFBAACCQESA1YcLgoMCgUEAAIJAxIDVjEzYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::BackupDisasterRecovery::BackupDisasterRecovery ===
    # Fields for BackupDisasterRecovery
    # Field: backup_template Type: 9 ()
    # Field: policies Type: 9 ()
    # Field: host Type: 9 ()
    # Field: applications Type: 9 ()
    # Field: storage_pool Type: 9 ()
    # Field: policy_options Type: 9 ()
    # Field: profile Type: 9 ()
    # Field: appliance Type: 9 ()
    # Field: backup_type Type: 9 ()
    # Field: backup_create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::BackupDisasterRecovery - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/backup_disaster_recovery.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::BackupDisasterRecovery;

    my $msg = Google::Cloud::Securitycenter::V1::BackupDisasterRecovery::BackupDisasterRecovery->new({
        backup_template => $backup_template,
        policies => $policies,
        host => $host,
        applications => $applications,
    });

    # Read or update a field
    my $val = $msg->backup_template();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::BackupDisasterRecovery::BackupDisasterRecovery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/backup_disaster_recovery.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::BackupDisasterRecovery::BackupDisasterRecovery

Information related to Google Cloud Backup and DR Service findings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_template() >> / C<< $msg->backup_template($value) >>

Type: C<String>

The name of a Backup and DR template which comprises one or more backup
policies. See the [Backup and DR
documentation](https://cloud.google.com/backup-disaster-recovery/docs/concepts/backup-plan#temp)
for more information. For example, `snap-ov`.

=item * C<< $msg->policies() >> / C<< $msg->policies($value) >>

Type: C<String>

The names of Backup and DR policies that are associated with a template
and that define when to run a backup, how frequently to run a backup, and
how long to retain the backup image. For example, `onvaults`.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

The name of a Backup and DR host, which is managed by the backup and
recovery appliance and known to the management console. The host can be of
type Generic (for example, Compute Engine, SQL Server, Oracle DB, SMB file
system, etc.), vCenter, or an ESX server. See the [Backup and DR
documentation on
hosts](https://cloud.google.com/backup-disaster-recovery/docs/configuration/manage-hosts-and-their-applications)
for more information. For example, `centos7-01`.

=item * C<< $msg->applications() >> / C<< $msg->applications($value) >>

Type: C<String>

The names of Backup and DR applications. An application is a VM, database,
or file system on a managed host monitored by a backup and recovery
appliance. For example, `centos7-01-vol00`, `centos7-01-vol01`,
`centos7-01-vol02`.

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<String>

The name of the Backup and DR storage pool that the backup and recovery
appliance is storing data in. The storage pool could be of type Cloud,
Primary, Snapshot, or OnVault. See the [Backup and DR documentation on
storage
pools](https://cloud.google.com/backup-disaster-recovery/docs/concepts/storage-pools).
For example, `DiskPoolOne`.

=item * C<< $msg->policy_options() >> / C<< $msg->policy_options($value) >>

Type: C<String>

The names of Backup and DR advanced policy options of a policy applying to
an application. See the [Backup and DR documentation on policy
options](https://cloud.google.com/backup-disaster-recovery/docs/create-plan/policy-settings).
For example, `skipofflineappsincongrp, nounmap`.

=item * C<< $msg->profile() >> / C<< $msg->profile($value) >>

Type: C<String>

The name of the Backup and DR resource profile that specifies the storage
media for backups of application and VM data. See the [Backup and DR
documentation on
profiles](https://cloud.google.com/backup-disaster-recovery/docs/concepts/backup-plan#profile).
For example, `GCP`.

=item * C<< $msg->appliance() >> / C<< $msg->appliance($value) >>

Type: C<String>

The name of the Backup and DR appliance that captures, moves, and manages
the lifecycle of backup data. For example, `backup-server-57137`.

=item * C<< $msg->backup_type() >> / C<< $msg->backup_type($value) >>

Type: C<String>

The backup type of the Backup and DR image.
For example, `Snapshot`, `Remote Snapshot`, `OnVault`.

=item * C<< $msg->backup_create_time() >> / C<< $msg->backup_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp at which the Backup and DR backup was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::BackupDisasterRecovery::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
