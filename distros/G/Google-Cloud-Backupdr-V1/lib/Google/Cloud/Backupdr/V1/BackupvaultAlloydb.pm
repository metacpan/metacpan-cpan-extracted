package Google::Cloud::Backupdr::V1::BackupvaultAlloydb;

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
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYmFja3VwdmF1bHRfYWxsb3lkYi5wcm90bxIY
Z29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8iYAoiQWxsb3lEQkNsdXN0ZXJEYXRhU291cmNlUHJvcGVydGllcxI6CgRuYW1lGAEg
ASgJQibgQQP6QSAKHmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlclIEbmFtZSLPAQoe
QWxsb3lEYkNsdXN0ZXJCYWNrdXBQcm9wZXJ0aWVzEiUKC2Rlc2NyaXB0aW9uGAEgASgJSABS
C2Rlc2NyaXB0aW9uiAEBEiYKDHN0b3JlZF9ieXRlcxgCIAEoA0ID4EEDUgtzdG9yZWRCeXRl
cxIeCghjaGFpbl9pZBgDIAEoCUID4EEDUgdjaGFpbklkEi4KEGRhdGFiYXNlX3ZlcnNpb24Y
BCABKAlCA+BBA1IPZGF0YWJhc2VWZXJzaW9uQg4KDF9kZXNjcmlwdGlvbiJdCi1BbGxveURC
Q2x1c3RlckJhY2t1cFBsYW5Bc3NvY2lhdGlvblByb3BlcnRpZXMSLAoLY2x1c3Rlcl91aWQY
ASABKAlCC+KMz9cIAggB4EEDUgpjbHVzdGVyVWlkQqYCChxjb20uZ29vZ2xlLmNsb3VkLmJh
Y2t1cGRyLnYxQhdCYWNrdXB2YXVsdEFsbG95REJQcm90b1ABWjhjbG91ZC5nb29nbGUuY29t
L2dvL2JhY2t1cGRyL2FwaXYxL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCGEdvb2dsZS5DbG91
ZC5CYWNrdXBEUi5WMcoCGEdvb2dsZVxDbG91ZFxCYWNrdXBEUlxWMeoCG0dvb2dsZTo6Q2xv
dWQ6OkJhY2t1cERSOjpWMepBXAoeYWxsb3lkYi5nb29nbGVhcGlzLmNvbS9DbHVzdGVyEjpw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2x1c3RlcnMve2NsdXN0
ZXJ9So8RCgYSBA4ASAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCAoBCBIDFgA1CgkKAggl
EgMWADUKCAoBCBIDFwBPCgkKAggLEgMXAE8KCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBID
GQA4CgkKAggIEgMZADgKCAoBCBIDGgA1CgkKAggBEgMaADUKCAoBCBIDGwA1CgkKAggpEgMb
ADUKCAoBCBIDHAA0CgkKAggtEgMcADQKCQoBCBIEHQAgAgoMCgQInQgAEgQdACACCpABCgIE
ABIEJQArARqDASBBbGxveURCQ2x1c3RlckRhdGFTb3VyY2VQcm9wZXJ0aWVzIHJlcHJlc2Vu
dHMgdGhlIHByb3BlcnRpZXMgb2YgYQogQWxsb3lEQiBjbHVzdGVyIHJlc291cmNlIHRoYXQg
YXJlIHN0b3JlZCBpbiB0aGUgRGF0YVNvdXJjZS4KIC4KCgoKAwQAARIDJQgqClUKBAQAAgAS
BCcCKgQaRyBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgQWxsb3lEQiBjbHVzdGVyIGJhY2tl
ZCB1cCBieSB0aGUgZGF0YXNvdXJjZS4KCgwKBQQAAgAFEgMnAggKDAoFBAACAAESAycJDQoM
CgUEAAIAAxIDJxARCg0KBQQAAgAIEgQnEioDCg8KCAQAAgAInAgAEgMoBC0KDgoHBAACAAif
CBIDKQRQCl4KAgQBEgQwAD8BGlIgQWxsb3lEYkNsdXN0ZXJCYWNrdXBQcm9wZXJ0aWVzIHJl
cHJlc2VudHMgQWxsb3lEQiBjbHVzdGVyCiBiYWNrdXAgcHJvcGVydGllcy4KIC4KCgoKAwQB
ARIDMAgmCjsKBAQBAgASAzICIhouIEFuIG9wdGlvbmFsIHRleHQgZGVzY3JpcHRpb24gZm9y
IHRoZSBiYWNrdXAuCgoMCgUEAQIABBIDMgIKCgwKBQQBAgAFEgMyCxEKDAoFBAECAAESAzIS
HQoMCgUEAQIAAxIDMiAhCkMKBAQBAgESAzUCRRo2IE91dHB1dCBvbmx5LiBTdG9yYWdlIHVz
YWdlIG9mIHRoaXMgcGFydGljdWxhciBiYWNrdXAKCgwKBQQBAgEFEgM1AgcKDAoFBAECAQES
AzUIFAoMCgUEAQIBAxIDNRcYCgwKBQQBAgEIEgM1GUQKDwoIBAECAQicCAASAzUaQwq2AQoE
BAECAhIDOgJCGqgBIE91dHB1dCBvbmx5LiBUaGUgY2hhaW4gaWQgb2YgdGhpcyBiYWNrdXAu
IEJhY2t1cHMgYmVsb25naW5nIHRvIHRoZSBzYW1lCiBjaGFpbiBhcmUgc2hhcmluZyB0aGUg
c2FtZSBjaGFpbiBpZC4gVGhpcyBwcm9wZXJ0eSBpcyBjYWxjdWxhdGVkIGFuZAogbWFpbnRh
aW5lZCBieSBCYWNrdXBEUi4KCgwKBQQBAgIFEgM6AggKDAoFBAECAgESAzoJEQoMCgUEAQIC
AxIDOhQVCgwKBQQBAgIIEgM6FkEKDwoIBAECAgicCAASAzoXQAprCgQEAQIDEgM+AkoaXiBP
dXRwdXQgb25seS4gVGhlIFBvc3RncmVTUUwgbWFqb3IgdmVyc2lvbiBvZiB0aGUgQWxsb3lE
QiBjbHVzdGVyIHdoZW4gdGhlCiBiYWNrdXAgd2FzIHRha2VuLgoKDAoFBAECAwUSAz4CCAoM
CgUEAQIDARIDPgkZCgwKBQQBAgMDEgM+HB0KDAoFBAECAwgSAz4eSQoPCggEAQIDCJwIABID
Ph9ICkgKAgQCEgRCAEgBGjwgUHJvcGVydGllcyBmb3IgYW4gQWxsb3lEQiBjbHVzdGVyIGJh
Y2t1cCBwbGFuIGFzc29jaWF0aW9uLgoKCgoDBAIBEgNCCDUKRAoEBAICABIERAJHBBo2IE91
dHB1dCBvbmx5LiBUaGUgY2x1c3RlciBVSUQgb2YgdGhlIEFsbG95REIgY2x1c3Rlci4KCgwK
BQQCAgAFEgNEAggKDAoFBAICAAESA0QJFAoMCgUEAgIAAxIDRBcYCg0KBQQCAgAIEgREGUcD
ChIKCwQCAgAIzPH5igEBEgNFBCoKDwoIBAICAAicCAASA0YELWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties ===
    # Fields for AlloyDBClusterDataSourceProperties
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDbClusterBackupProperties ===
    # Fields for AlloyDbClusterBackupProperties
    # Field: description Type: 9 ()
    # Field: stored_bytes Type: 3 ()
    # Field: chain_id Type: 9 ()
    # Field: database_version Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties ===
    # Fields for AlloyDBClusterBackupPlanAssociationProperties
    # Field: cluster_uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::BackupvaultAlloydb - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/backupvault_alloydb.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::BackupvaultAlloydb;

    my $msg = Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/backupvault_alloydb.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties

AlloyDBClusterDataSourceProperties represents the properties of a
AlloyDB cluster resource that are stored in the DataSource.
.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the AlloyDB cluster backed up by the datasource.

=back

=head2 Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDbClusterBackupProperties

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

=head2 Google::Cloud::Backupdr::V1::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties

Properties for an AlloyDB cluster backup plan association.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster_uid() >> / C<< $msg->cluster_uid($value) >>

Type: C<String>

Output only. The cluster UID of the AlloyDB cluster.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::BackupvaultAlloydb::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
