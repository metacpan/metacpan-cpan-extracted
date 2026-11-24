package Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb;

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
CjZnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2JhY2t1cHZhdWx0X2FsbG95ZGIucHJv
dG8SHGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLfAQoiQWxs
b3lEQkNsdXN0ZXJEYXRhU291cmNlUHJvcGVydGllcxI6CgRuYW1lGAEgASgJQibgQQP6QSAK
HmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlclIEbmFtZRJXCgxwaXRyX3dpbmRvd3MY
AiADKAsyLy5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkFsbG95RGJQaXRyV2luZG93
QgPgQQNSC3BpdHJXaW5kb3dzEiQKC2NsdXN0ZXJfdWlkGAMgASgJQgPgQQNSCmNsdXN0ZXJV
aWQiaQorQWxsb3lEQkNsdXN0ZXJEYXRhU291cmNlUmVmZXJlbmNlUHJvcGVydGllcxI6CgRu
YW1lGAEgASgJQibgQQP6QSAKHmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlclIEbmFt
ZSLCAQoRQWxsb3lEYlBpdHJXaW5kb3cSPgoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEjoKCGVuZF90aW1lGAIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEjEKEmxvZ19yZXRlbnRp
b25fZGF5cxgDIAEoA0ID4EEDUhBsb2dSZXRlbnRpb25EYXlzIs8BCh5BbGxveURiQ2x1c3Rl
ckJhY2t1cFByb3BlcnRpZXMSJQoLZGVzY3JpcHRpb24YASABKAlIAFILZGVzY3JpcHRpb26I
AQESJgoMc3RvcmVkX2J5dGVzGAIgASgDQgPgQQNSC3N0b3JlZEJ5dGVzEh4KCGNoYWluX2lk
GAMgASgJQgPgQQNSB2NoYWluSWQSLgoQZGF0YWJhc2VfdmVyc2lvbhgEIAEoCUID4EEDUg9k
YXRhYmFzZVZlcnNpb25CDgoMX2Rlc2NyaXB0aW9uIl0KLUFsbG95REJDbHVzdGVyQmFja3Vw
UGxhbkFzc29jaWF0aW9uUHJvcGVydGllcxIsCgtjbHVzdGVyX3VpZBgBIAEoCUIL4ozP1wgC
CAHgQQNSCmNsdXN0ZXJVaWRCzQIKIGNvbS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRh
QhdCYWNrdXB2YXVsdEFsbG95REJQcm90b1ABWjxjbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1
cGRyL2FwaXYxYmV0YS9iYWNrdXBkcnBiO2JhY2t1cGRycGKqAhxHb29nbGUuQ2xvdWQuQmFj
a3VwRFIuVjFCZXRhygIcR29vZ2xlXENsb3VkXEJhY2t1cERSXFYxYmV0YeoCH0dvb2dsZTo6
Q2xvdWQ6OkJhY2t1cERSOjpWMWJldGHqQW8KHmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20vQ2x1
c3RlchI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsdXN0ZXJz
L3tjbHVzdGVyfSoIY2x1c3RlcnMyB2NsdXN0ZXJK6RsKBhIEDgBvAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMTACUK
CQoCAwISAxQAIwoJCgIDAxIDFQApCggKAQgSAxcAOQoJCgIIJRIDFwA5CggKAQgSAxgAUwoJ
CgIICxIDGABTCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAOAoJCgIICBIDGgA4CggK
AQgSAxsAOQoJCgIIARIDGwA5CggKAQgSAxwAOQoJCgIIKRIDHAA5CggKAQgSAx0AOAoJCgII
LRIDHQA4CgkKAQgSBB4AIwIKDAoECJ0IABIEHgAjAgqQAQoCBAASBCgANwEagwEgQWxsb3lE
QkNsdXN0ZXJEYXRhU291cmNlUHJvcGVydGllcyByZXByZXNlbnRzIHRoZSBwcm9wZXJ0aWVz
IG9mIGEKIEFsbG95REIgY2x1c3RlciByZXNvdXJjZSB0aGF0IGFyZSBzdG9yZWQgaW4gdGhl
IERhdGFTb3VyY2UuCiAuCgoKCgMEAAESAygIKgpVCgQEAAIAEgQqAi0EGkcgT3V0cHV0IG9u
bHkuIE5hbWUgb2YgdGhlIEFsbG95REIgY2x1c3RlciBiYWNrZWQgdXAgYnkgdGhlIGRhdGFz
b3VyY2UuCgoMCgUEAAIABRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMSAyoQEQoNCgUE
AAIACBIEKhItAwoPCggEAAIACJwIABIDKwQtCg4KBwQAAgAInwgSAywEUAp0CgQEAAIBEgQx
AjIyGmYgT3V0cHV0IG9ubHkuIFBvaW50IGluIHRpbWUgcmVjb3Zlcnkgd2luZG93cy4KIFRo
ZSBvcmRlciBpcyBndWFyYW50ZWVkIHRvIGJlIGFzY2VuZGluZyBieSBzdGFydCB0aW1lLgoK
DAoFBAACAQQSAzECCgoMCgUEAAIBBhIDMQscCgwKBQQAAgEBEgMxHSkKDAoFBAACAQMSAzEs
LQoMCgUEAAIBCBIDMgYxCg8KCAQAAgEInAgAEgMyBzAKYAoEBAACAhIDNgJFGlMgT3V0cHV0
IG9ubHkuIFRoZSBjbHVzdGVyIFVJRCBvZiB0aGUgQWxsb3lEQiBjbHVzdGVyIGJhY2tlZCB1
cCBieSB0aGUKIGRhdGFzb3VyY2UuCgoMCgUEAAICBRIDNgIICgwKBQQAAgIBEgM2CRQKDAoF
BAACAgMSAzYXGAoMCgUEAAICCBIDNhlECg8KCAQAAgIInAgAEgM2GkMKlwEKAgQBEgQ7AEMB
GooBIEFsbG95REJDbHVzdGVyRGF0YVNvdXJjZVJlZmVyZW5jZVByb3BlcnRpZXMgcmVwcmVz
ZW50cyB0aGUgcHJvcGVydGllcyBvZiBhbgogQWxsb3lEQiBjbHVzdGVyIHRoYXQgYXJlIHN0
b3JlZCBpbiB0aGUgRGF0YVNvdXJjZVJlZmVyZW5jZS4KCgoKAwQBARIDOwgzCpsBCgQEAQIA
EgQ/AkIEGowBIE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBBbGxveURCIGNsdXN0ZXIgYmFj
a2VkIHVwIGJ5IHRoZSBkYXRhc291cmNlLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVzdGVyfQoKDAoFBAECAAUSAz8C
CAoMCgUEAQIAARIDPwkNCgwKBQQBAgADEgM/EBEKDQoFBAECAAgSBD8SQgMKDwoIBAECAAic
CAASA0AELQoOCgcEAQIACJ8IEgNBBFAKQwoCBAISBEYAUgEaNyBQb2ludCBpbiB0aW1lIHJl
Y292ZXJ5IHdpbmRvdyBmb3IgYW4gQWxsb3lEQiBjbHVzdGVyLgoKCgoDBAIBEgNGCBkKPwoE
BAICABIESAJJMhoxIE91dHB1dCBvbmx5LiBUaGUgc3RhcnQgdGltZSBvZiB0aGUgUElUUiB3
aW5kb3cuCgoMCgUEAgIABhIDSAIbCgwKBQQCAgABEgNIHCYKDAoFBAICAAMSA0gpKgoMCgUE
AgIACBIDSQYxCg8KCAQCAgAInAgAEgNJBzAKhAEKBAQCAgESBE0CTjIadiBPdXRwdXQgb25s
eS4gVGhlIGVuZCB0aW1lIG9mIHRoZSBQSVRSIHdpbmRvdy4gSXQgaXMgbm90IHNldCBpZiB0
aGUKIGNvcnJlc3BvbmRpbmcgQmFja3VwIFBsYW4gQXNzb2NpYXRpb24gaXMgYWN0aXZlLgoK
DAoFBAICAQYSA00CGwoMCgUEAgIBARIDTRwkCgwKBQQCAgEDEgNNJygKDAoFBAICAQgSA04G
MQoPCggEAgIBCJwIABIDTgcwCkMKBAQCAgISA1ECSxo2IE91dHB1dCBvbmx5LiBMb2cgcmV0
ZW50aW9uIGRheXMgZm9yIHRoZSBQSVRSIHdpbmRvdy4KCgwKBQQCAgIFEgNRAgcKDAoFBAIC
AgESA1EIGgoMCgUEAgICAxIDUR0eCgwKBQQCAgIIEgNRH0oKDwoIBAICAgicCAASA1EgSQpe
CgIEAxIEVwBmARpSIEFsbG95RGJDbHVzdGVyQmFja3VwUHJvcGVydGllcyByZXByZXNlbnRz
IEFsbG95REIgY2x1c3RlcgogYmFja3VwIHByb3BlcnRpZXMuCiAuCgoKCgMEAwESA1cIJgo7
CgQEAwIAEgNZAiIaLiBBbiBvcHRpb25hbCB0ZXh0IGRlc2NyaXB0aW9uIGZvciB0aGUgYmFj
a3VwLgoKDAoFBAMCAAQSA1kCCgoMCgUEAwIABRIDWQsRCgwKBQQDAgABEgNZEh0KDAoFBAMC
AAMSA1kgIQpDCgQEAwIBEgNcAkUaNiBPdXRwdXQgb25seS4gU3RvcmFnZSB1c2FnZSBvZiB0
aGlzIHBhcnRpY3VsYXIgYmFja3VwCgoMCgUEAwIBBRIDXAIHCgwKBQQDAgEBEgNcCBQKDAoF
BAMCAQMSA1wXGAoMCgUEAwIBCBIDXBlECg8KCAQDAgEInAgAEgNcGkMKtgEKBAQDAgISA2EC
QhqoASBPdXRwdXQgb25seS4gVGhlIGNoYWluIGlkIG9mIHRoaXMgYmFja3VwLiBCYWNrdXBz
IGJlbG9uZ2luZyB0byB0aGUgc2FtZQogY2hhaW4gYXJlIHNoYXJpbmcgdGhlIHNhbWUgY2hh
aW4gaWQuIFRoaXMgcHJvcGVydHkgaXMgY2FsY3VsYXRlZCBhbmQKIG1haW50YWluZWQgYnkg
QmFja3VwRFIuCgoMCgUEAwICBRIDYQIICgwKBQQDAgIBEgNhCREKDAoFBAMCAgMSA2EUFQoM
CgUEAwICCBIDYRZBCg8KCAQDAgIInAgAEgNhF0AKawoEBAMCAxIDZQJKGl4gT3V0cHV0IG9u
bHkuIFRoZSBQb3N0Z3JlU1FMIG1ham9yIHZlcnNpb24gb2YgdGhlIEFsbG95REIgY2x1c3Rl
ciB3aGVuIHRoZQogYmFja3VwIHdhcyB0YWtlbi4KCgwKBQQDAgMFEgNlAggKDAoFBAMCAwES
A2UJGQoMCgUEAwIDAxIDZRwdCgwKBQQDAgMIEgNlHkkKDwoIBAMCAwicCAASA2UfSApICgIE
BBIEaQBvARo8IFByb3BlcnRpZXMgZm9yIGFuIEFsbG95REIgY2x1c3RlciBiYWNrdXAgcGxh
biBhc3NvY2lhdGlvbi4KCgoKAwQEARIDaQg1CkQKBAQEAgASBGsCbgQaNiBPdXRwdXQgb25s
eS4gVGhlIGNsdXN0ZXIgVUlEIG9mIHRoZSBBbGxveURCIGNsdXN0ZXIuCgoMCgUEBAIABRID
awIICgwKBQQEAgABEgNrCRQKDAoFBAQCAAMSA2sXGAoNCgUEBAIACBIEaxluAwoSCgsEBAIA
CMzx+YoBARIDbAQqCg8KCAQEAgAInAgAEgNtBC1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties ===
    # Fields for AlloyDBClusterDataSourceProperties
    # Field: name Type: 9 ()
    # Field: pitr_windows Type: 11 (.google.cloud.backupdr.v1beta.AlloyDbPitrWindow)
    # Field: cluster_uid Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceReferenceProperties ===
    # Fields for AlloyDBClusterDataSourceReferenceProperties
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbPitrWindow ===
    # Fields for AlloyDbPitrWindow
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: log_retention_days Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbClusterBackupProperties ===
    # Fields for AlloyDbClusterBackupProperties
    # Field: description Type: 9 ()
    # Field: stored_bytes Type: 3 ()
    # Field: chain_id Type: 9 ()
    # Field: database_version Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties ===
    # Fields for AlloyDBClusterBackupPlanAssociationProperties
    # Field: cluster_uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/backupvault_alloydb.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb;

    my $msg = Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties->new({
        name => $name,
        pitr_windows => $pitr_windows,
        cluster_uid => $cluster_uid,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/backupvault_alloydb.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties

AlloyDBClusterDataSourceProperties represents the properties of a
AlloyDB cluster resource that are stored in the DataSource.
.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the AlloyDB cluster backed up by the datasource.

=item * C<< $msg->pitr_windows() >> / C<< $msg->pitr_windows($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbPitrWindow>)

Output only. Point in time recovery windows.
The order is guaranteed to be ascending by start time.

=item * C<< $msg->cluster_uid() >> / C<< $msg->cluster_uid($value) >>

Type: C<String>

Output only. The cluster UID of the AlloyDB cluster backed up by the
datasource.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceReferenceProperties

AlloyDBClusterDataSourceReferenceProperties represents the properties of an
AlloyDB cluster that are stored in the DataSourceReference.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the AlloyDB cluster backed up by the datasource.
Format:
projects/{project}/locations/{location}/clusters/{cluster}

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbPitrWindow

Point in time recovery window for an AlloyDB cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The start time of the PITR window.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The end time of the PITR window. It is not set if the
corresponding Backup Plan Association is active.

=item * C<< $msg->log_retention_days() >> / C<< $msg->log_retention_days($value) >>

Type: C<Int64>

Output only. Log retention days for the PITR window.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbClusterBackupProperties

AlloyDbClusterBackupProperties represents AlloyDB cluster
backup properties.
.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

An optional text description for the backup.

=item * C<< $msg->stored_bytes() >> / C<< $msg->stored_bytes($value) >>

Type: C<Int64>

Output only. Storage usage of this particular backup

=item * C<< $msg->chain_id() >> / C<< $msg->chain_id($value) >>

Type: C<String>

Output only. The chain id of this backup. Backups belonging to the same
chain are sharing the same chain id. This property is calculated and
maintained by BackupDR.

=item * C<< $msg->database_version() >> / C<< $msg->database_version($value) >>

Type: C<String>

Output only. The PostgreSQL major version of the AlloyDB cluster when the
backup was taken.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties

Properties for an AlloyDB cluster backup plan association.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster_uid() >> / C<< $msg->cluster_uid($value) >>

Type: C<String>

Output only. The cluster UID of the AlloyDB cluster.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
