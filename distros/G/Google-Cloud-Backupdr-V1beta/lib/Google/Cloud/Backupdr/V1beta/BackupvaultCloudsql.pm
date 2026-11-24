package Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql;

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
Cjdnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2JhY2t1cHZhdWx0X2Nsb3Vkc3FsLnBy
b3RvEhxnb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIqQCCiRDbG91ZFNxbEluc3RhbmNlRGF0YVNvdXJjZVByb3Bl
cnRpZXMSPAoEbmFtZRgBIAEoCUIo4EED+kEiCiBzcWxhZG1pbi5nb29nbGVhcGlzLmNvbS9J
bnN0YW5jZVIEbmFtZRJBChpkYXRhYmFzZV9pbnN0YWxsZWRfdmVyc2lvbhgCIAEoCUID4EED
UhhkYXRhYmFzZUluc3RhbGxlZFZlcnNpb24SUQoUaW5zdGFuY2VfY3JlYXRlX3RpbWUYAyAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSEmluc3RhbmNlQ3JlYXRlVGlt
ZRIoCg1pbnN0YW5jZV90aWVyGAUgASgJQgPgQQNSDGluc3RhbmNlVGllciKwAwogQ2xvdWRT
cWxJbnN0YW5jZUJhY2t1cFByb3BlcnRpZXMSQQoaZGF0YWJhc2VfaW5zdGFsbGVkX3ZlcnNp
b24YAiABKAlCA+BBA1IYZGF0YWJhc2VJbnN0YWxsZWRWZXJzaW9uEiYKDGZpbmFsX2JhY2t1
cBgDIAEoCEID4EEDUgtmaW5hbEJhY2t1cBJRCg9zb3VyY2VfaW5zdGFuY2UYBCABKAlCKOBB
A/pBIgogc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSDnNvdXJjZUluc3RhbmNl
ElEKFGluc3RhbmNlX2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUhJpbnN0YW5jZUNyZWF0ZVRpbWUSKAoNaW5zdGFuY2VfdGllchgGIAEoCUID
4EEDUgxpbnN0YW5jZVRpZXISUQoUaW5zdGFuY2VfZGVsZXRlX3RpbWUYCCABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSEmluc3RhbmNlRGVsZXRlVGltZSKtAgotQ2xv
dWRTcWxJbnN0YW5jZURhdGFTb3VyY2VSZWZlcmVuY2VQcm9wZXJ0aWVzEjwKBG5hbWUYASAB
KAlCKOBBA/pBIgogc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBG5hbWUSQQoa
ZGF0YWJhc2VfaW5zdGFsbGVkX3ZlcnNpb24YAiABKAlCA+BBA1IYZGF0YWJhc2VJbnN0YWxs
ZWRWZXJzaW9uElEKFGluc3RhbmNlX2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUhJpbnN0YW5jZUNyZWF0ZVRpbWUSKAoNaW5zdGFuY2VfdGll
chgFIAEoCUID4EEDUgxpbnN0YW5jZVRpZXIi2gEKJENsb3VkU3FsSW5zdGFuY2VJbml0aWFs
aXphdGlvbkNvbmZpZxJpCgdlZGl0aW9uGAEgASgOMkouZ29vZ2xlLmNsb3VkLmJhY2t1cGRy
LnYxYmV0YS5DbG91ZFNxbEluc3RhbmNlSW5pdGlhbGl6YXRpb25Db25maWcuRWRpdGlvbkID
4EECUgdlZGl0aW9uIkcKB0VkaXRpb24SFwoTRURJVElPTl9VTlNQRUNJRklFRBAAEg4KCkVO
VEVSUFJJU0UQARITCg9FTlRFUlBSSVNFX1BMVVMQAiKEAQovQ2xvdWRTcWxJbnN0YW5jZUJh
Y2t1cFBsYW5Bc3NvY2lhdGlvblByb3BlcnRpZXMSUQoUaW5zdGFuY2VfY3JlYXRlX3RpbWUY
ASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSEmluc3RhbmNlQ3JlYXRl
VGltZUKqAgogY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGFCGEJhY2t1cHZhdWx0
Q2xvdWRTcWxQcm90b1ABWjxjbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxYmV0
YS9iYWNrdXBkcnBiO2JhY2t1cGRycGKqAhxHb29nbGUuQ2xvdWQuQmFja3VwRFIuVjFCZXRh
ygIcR29vZ2xlXENsb3VkXEJhY2t1cERSXFYxYmV0YeoCH0dvb2dsZTo6Q2xvdWQ6OkJhY2t1
cERSOjpWMWJldGHqQUsKIHNxbGFkbWluLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlEidwcm9q
ZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX1K/SIKBxIFDgCRAQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA5CgkKAgglEgMWADkKCAoBCBIDFwBTCgkKAggL
EgMXAFMKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQA5CgkKAggIEgMZADkKCAoBCBID
GgA5CgkKAggBEgMaADkKCAoBCBIDGwA5CgkKAggpEgMbADkKCAoBCBIDHAA4CgkKAggtEgMc
ADgKCQoBCBIEHQAgAgoMCgQInQgAEgQdACACCogBCgIEABIEJAA6ARp8IENsb3VkU3FsSW5z
dGFuY2VEYXRhU291cmNlUHJvcGVydGllcyByZXByZXNlbnRzIHRoZSBwcm9wZXJ0aWVzIG9m
IGEKIENsb3VkIFNRTCByZXNvdXJjZSB0aGF0IGFyZSBzdG9yZWQgaW4gdGhlIERhdGFTb3Vy
Y2UuCgoKCgMEAAESAyQILAqKAQoEBAACABIEKAItBBp8IE91dHB1dCBvbmx5LiBOYW1lIG9m
IHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UgYmFja2VkIHVwIGJ5IHRoZSBkYXRhc291cmNlLgog
Rm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9CgoMCgUE
AAIABRIDKAIICgwKBQQAAgABEgMoCQ0KDAoFBAACAAMSAygQEQoNCgUEAAIACBIEKBItAwoP
CggEAAIACJwIABIDKQQtCg8KBwQAAgAInwgSBCoELAUKVgoEBAACARIEMAIxMhpIIE91dHB1
dCBvbmx5LiBUaGUgaW5zdGFsbGVkIGRhdGFiYXNlIHZlcnNpb24gb2YgdGhlIENsb3VkIFNR
TCBpbnN0YW5jZS4KCgwKBQQAAgEFEgMwAggKDAoFBAACAQESAzAJIwoMCgUEAAIBAxIDMCYn
CgwKBQQAAgEIEgMxBjEKDwoIBAACAQicCAASAzEHMAo9CgQEAAICEgQ0AjUyGi8gT3V0cHV0
IG9ubHkuIFRoZSBpbnN0YW5jZSBjcmVhdGlvbiB0aW1lc3RhbXAuCgoMCgUEAAICBhIDNAIb
CgwKBQQAAgIBEgM0HDAKDAoFBAACAgMSAzQzNAoMCgUEAAICCBIDNQYxCg8KCAQAAgIInAgA
EgM1BzAKZgoEBAACAxIDOQJHGlkgT3V0cHV0IG9ubHkuIFRoZSB0aWVyIChvciBtYWNoaW5l
IHR5cGUpIGZvciB0aGlzIGluc3RhbmNlLiBFeGFtcGxlOgogYGRiLWN1c3RvbS0xLTM4NDBg
CgoMCgUEAAIDBRIDOQIICgwKBQQAAgMBEgM5CRYKDAoFBAACAwMSAzkZGgoMCgUEAAIDCBID
ORtGCg8KCAQAAgMInAgAEgM5HEUKYAoCBAESBD4AXAEaVCBDbG91ZFNxbEluc3RhbmNlQmFj
a3VwUHJvcGVydGllcyByZXByZXNlbnRzIENsb3VkIFNRTCBJbnN0YW5jZQogQmFja3VwIHBy
b3BlcnRpZXMuCgoKCgMEAQESAz4IKApxCgQEAQIAEgRBAkIyGmMgT3V0cHV0IG9ubHkuIFRo
ZSBpbnN0YWxsZWQgZGF0YWJhc2UgdmVyc2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNl
CiB3aGVuIHRoZSBiYWNrdXAgd2FzIHRha2VuLgoKDAoFBAECAAUSA0ECCAoMCgUEAQIAARID
QQkjCgwKBQQBAgADEgNBJicKDAoFBAECAAgSA0IGMQoPCggEAQIACJwIABIDQgcwCkEKBAQB
AgESA0UCRBo0IE91dHB1dCBvbmx5LiBXaGV0aGVyIHRoZSBiYWNrdXAgaXMgYSBmaW5hbCBi
YWNrdXAuCgoMCgUEAQIBBRIDRQIGCgwKBQQBAgEBEgNFBxMKDAoFBAECAQMSA0UWFwoMCgUE
AQIBCBIDRRhDCg8KCAQBAgEInAgAEgNFGUIKcQoEBAECAhIESgJPBBpjIE91dHB1dCBvbmx5
LiBUaGUgc291cmNlIGluc3RhbmNlIG9mIHRoZSBiYWNrdXAuCiBGb3JtYXQ6CiBwcm9qZWN0
cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX0KCgwKBQQBAgIFEgNKAggKDAoFBAEC
AgESA0oJGAoMCgUEAQICAxIDShscCg0KBQQBAgIIEgRKHU8DCg8KCAQBAgIInAgAEgNLBC0K
DwoHBAECAgifCBIETAROBQo9CgQEAQIDEgRSAlMyGi8gT3V0cHV0IG9ubHkuIFRoZSBpbnN0
YW5jZSBjcmVhdGlvbiB0aW1lc3RhbXAuCgoMCgUEAQIDBhIDUgIbCgwKBQQBAgMBEgNSHDAK
DAoFBAECAwMSA1IzNAoMCgUEAQIDCBIDUwYxCg8KCAQBAgMInAgAEgNTBzAKZgoEBAECBBID
VwJHGlkgT3V0cHV0IG9ubHkuIFRoZSB0aWVyIChvciBtYWNoaW5lIHR5cGUpIGZvciB0aGlz
IGluc3RhbmNlLiBFeGFtcGxlOgogYGRiLWN1c3RvbS0xLTM4NDBgCgoMCgUEAQIEBRIDVwII
CgwKBQQBAgQBEgNXCRYKDAoFBAECBAMSA1cZGgoMCgUEAQIECBIDVxtGCg8KCAQBAgQInAgA
EgNXHEUKOwoEBAECBRIEWgJbMhotIE91dHB1dCBvbmx5LiBUaGUgaW5zdGFuY2UgZGVsZXRl
IHRpbWVzdGFtcC4KCgwKBQQBAgUGEgNaAhsKDAoFBAECBQESA1ocMAoMCgUEAQIFAxIDWjM0
CgwKBQQBAgUIEgNbBjEKDwoIBAECBQicCAASA1sHMAqbAQoCBAISBGAAdgEajgEgQ2xvdWRT
cWxJbnN0YW5jZURhdGFTb3VyY2VSZWZlcmVuY2VQcm9wZXJ0aWVzIHJlcHJlc2VudHMgdGhl
IHByb3BlcnRpZXMgb2YgYQogQ2xvdWQgU1FMIHJlc291cmNlIHRoYXQgYXJlIHN0b3JlZCBp
biB0aGUgRGF0YVNvdXJjZVJlZmVyZW5jZS4KCgoKAwQCARIDYAg1CooBCgQEAgIAEgRkAmkE
GnwgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5jZSBiYWNrZWQg
dXAgYnkgdGhlIGRhdGFzb3VyY2UuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vaW5z
dGFuY2VzL3tpbnN0YW5jZX0KCgwKBQQCAgAFEgNkAggKDAoFBAICAAESA2QJDQoMCgUEAgIA
AxIDZBARCg0KBQQCAgAIEgRkEmkDCg8KCAQCAgAInAgAEgNlBC0KDwoHBAICAAifCBIEZgRo
BQpWCgQEAgIBEgRsAm0yGkggT3V0cHV0IG9ubHkuIFRoZSBpbnN0YWxsZWQgZGF0YWJhc2Ug
dmVyc2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBAICAQUSA2wCCAoMCgUE
AgIBARIDbAkjCgwKBQQCAgEDEgNsJicKDAoFBAICAQgSA20GMQoPCggEAgIBCJwIABIDbQcw
Cj0KBAQCAgISBHACcTIaLyBPdXRwdXQgb25seS4gVGhlIGluc3RhbmNlIGNyZWF0aW9uIHRp
bWVzdGFtcC4KCgwKBQQCAgIGEgNwAhsKDAoFBAICAgESA3AcMAoMCgUEAgICAxIDcDM0CgwK
BQQCAgIIEgNxBjEKDwoIBAICAgicCAASA3EHMApmCgQEAgIDEgN1AkcaWSBPdXRwdXQgb25s
eS4gVGhlIHRpZXIgKG9yIG1hY2hpbmUgdHlwZSkgZm9yIHRoaXMgaW5zdGFuY2UuIEV4YW1w
bGU6CiBgZGItY3VzdG9tLTEtMzg0MGAKCgwKBQQCAgMFEgN1AggKDAoFBAICAwESA3UJFgoM
CgUEAgIDAxIDdRkaCgwKBQQCAgMIEgN1G0YKDwoIBAICAwicCAASA3UcRQp2CgIEAxIFegCK
AQEaaSBDbG91ZFNxbEluc3RhbmNlSW5pdGlhbGl6YXRpb25Db25maWcgY29udGFpbnMgdGhl
IGNvbmZpZ3VyYXRpb24gZm9yCiBpbml0aWFsaXppbmcgYSBDbG91ZCBTUUwgaW5zdGFuY2Uu
CgoKCgMEAwESA3oILAp7CgQEAwQAEgV9AoYBAxpsIFRoZSBlZGl0aW9uIG9mIHRoZSBDbG91
ZCBTUUwgaW5zdGFuY2UuIEZvciBkZXRhaWxzLCBzZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9zcWwvZG9jcy9lZGl0aW9ucy1pbnRyby4KCgwKBQQDBAABEgN9Bw4KJQoGBAMEAAIA
EgN/BBwaFiBVbnNwZWNpZmllZCBlZGl0aW9uLgoKDgoHBAMEAAIAARIDfwQXCg4KBwQDBAAC
AAISA38aGwolCgYEAwQAAgESBIIBBBMaFSBFbnRlcnByaXNlIGVkaXRpb24uCgoPCgcEAwQA
AgEBEgSCAQQOCg8KBwQDBAACAQISBIIBERIKKgoGBAMEAAICEgSFAQQYGhogRW50ZXJwcmlz
ZSBQbHVzIGVkaXRpb24uCgoPCgcEAwQAAgIBEgSFAQQTCg8KBwQDBAACAgISBIUBFhcKQAoE
BAMCABIEiQECPxoyIFJlcXVpcmVkLiBUaGUgZWRpdGlvbiBvZiB0aGUgQ2xvdWQgU1FMIGlu
c3RhbmNlLgoKDQoFBAMCAAYSBIkBAgkKDQoFBAMCAAESBIkBChEKDQoFBAMCAAMSBIkBFBUK
DQoFBAMCAAgSBIkBFj4KEAoIBAMCAAicCAASBIkBFz0KNAoCBAQSBo0BAJEBARomIENsb3Vk
IFNRTCBpbnN0YW5jZSdzIEJQQSBwcm9wZXJ0aWVzLgoKCwoDBAQBEgSNAQg3CkYKBAQEAgAS
Bo8BApABMho2IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBpbnN0YW5jZSB3YXMg
Y3JlYXRlZC4KCg0KBQQEAgAGEgSPAQIbCg0KBQQEAgABEgSPARwwCg0KBQQEAgADEgSPATM0
Cg0KBQQEAgAIEgSQAQYxChAKCAQEAgAInAgAEgSQAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties ===
    # Fields for CloudSqlInstanceDataSourceProperties
    # Field: name Type: 9 ()
    # Field: database_installed_version Type: 9 ()
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_tier Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceBackupProperties ===
    # Fields for CloudSqlInstanceBackupProperties
    # Field: database_installed_version Type: 9 ()
    # Field: final_backup Type: 8 ()
    # Field: source_instance Type: 9 ()
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_tier Type: 9 ()
    # Field: instance_delete_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties ===
    # Fields for CloudSqlInstanceDataSourceReferenceProperties
    # Field: name Type: 9 ()
    # Field: database_installed_version Type: 9 ()
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_tier Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig ===
    # Fields for CloudSqlInstanceInitializationConfig
    # Field: edition Type: 14 (.google.cloud.backupdr.v1beta.CloudSqlInstanceInitializationConfig.Edition)

# Enum: CloudSqlInstanceInitializationConfig::Edition
our $CloudSqlInstanceInitializationConfig_EDITION_UNSPECIFIED = 0;
our $CloudSqlInstanceInitializationConfig_ENTERPRISE = 1;
our $CloudSqlInstanceInitializationConfig_ENTERPRISE_PLUS = 2;

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties ===
    # Fields for CloudSqlInstanceBackupPlanAssociationProperties
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/backupvault_cloudsql.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql;

    my $msg = Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties->new({
        name => $name,
        database_installed_version => $database_installed_version,
        instance_create_time => $instance_create_time,
        instance_tier => $instance_tier,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/backupvault_cloudsql.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties

CloudSqlInstanceDataSourceProperties represents the properties of a
Cloud SQL resource that are stored in the DataSource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the Cloud SQL instance backed up by the datasource.
Format:
projects/{project}/instances/{instance}

=item * C<< $msg->database_installed_version() >> / C<< $msg->database_installed_version($value) >>

Type: C<String>

Output only. The installed database version of the Cloud SQL instance.

=item * C<< $msg->instance_create_time() >> / C<< $msg->instance_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The instance creation timestamp.

=item * C<< $msg->instance_tier() >> / C<< $msg->instance_tier($value) >>

Type: C<String>

Output only. The tier (or machine type) for this instance. Example:
`db-custom-1-3840`

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceBackupProperties

CloudSqlInstanceBackupProperties represents Cloud SQL Instance
Backup properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->database_installed_version() >> / C<< $msg->database_installed_version($value) >>

Type: C<String>

Output only. The installed database version of the Cloud SQL instance
when the backup was taken.

=item * C<< $msg->final_backup() >> / C<< $msg->final_backup($value) >>

Type: C<Bool>

Output only. Whether the backup is a final backup.

=item * C<< $msg->source_instance() >> / C<< $msg->source_instance($value) >>

Type: C<String>

Output only. The source instance of the backup.
Format:
projects/{project}/instances/{instance}

=item * C<< $msg->instance_create_time() >> / C<< $msg->instance_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The instance creation timestamp.

=item * C<< $msg->instance_tier() >> / C<< $msg->instance_tier($value) >>

Type: C<String>

Output only. The tier (or machine type) for this instance. Example:
`db-custom-1-3840`

=item * C<< $msg->instance_delete_time() >> / C<< $msg->instance_delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The instance delete timestamp.

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties

CloudSqlInstanceDataSourceReferenceProperties represents the properties of a
Cloud SQL resource that are stored in the DataSourceReference.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the Cloud SQL instance backed up by the datasource.
Format:
projects/{project}/instances/{instance}

=item * C<< $msg->database_installed_version() >> / C<< $msg->database_installed_version($value) >>

Type: C<String>

Output only. The installed database version of the Cloud SQL instance.

=item * C<< $msg->instance_create_time() >> / C<< $msg->instance_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The instance creation timestamp.

=item * C<< $msg->instance_tier() >> / C<< $msg->instance_tier($value) >>

Type: C<String>

Output only. The tier (or machine type) for this instance. Example:
`db-custom-1-3840`

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig

CloudSqlInstanceInitializationConfig contains the configuration for
initializing a Cloud SQL instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->edition() >> / C<< $msg->edition($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::CloudSqlInstanceInitializationConfig::Edition>)

Required. The edition of the Cloud SQL instance.

=back

=head3 Enum: CloudSqlInstanceInitializationConfig::Edition

=over 4

=item * C<EDITION_UNSPECIFIED> => C<0>

=item * C<ENTERPRISE> => C<1>

=item * C<ENTERPRISE_PLUS> => C<2>

=back

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties

Cloud SQL instance's BPA properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_create_time() >> / C<< $msg->instance_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the instance was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
