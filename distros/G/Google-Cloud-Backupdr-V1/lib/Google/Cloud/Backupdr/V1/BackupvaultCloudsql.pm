package Google::Cloud::Backupdr::V1::BackupvaultCloudsql;

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
CjNnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYmFja3VwdmF1bHRfY2xvdWRzcWwucHJvdG8S
GGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byKkAgokQ2xvdWRTcWxJbnN0YW5jZURhdGFTb3VyY2VQcm9wZXJ0aWVzEjwK
BG5hbWUYASABKAlCKOBBA/pBIgogc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VS
BG5hbWUSQQoaZGF0YWJhc2VfaW5zdGFsbGVkX3ZlcnNpb24YAiABKAlCA+BBA1IYZGF0YWJh
c2VJbnN0YWxsZWRWZXJzaW9uElEKFGluc3RhbmNlX2NyZWF0ZV90aW1lGAMgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhJpbnN0YW5jZUNyZWF0ZVRpbWUSKAoNaW5z
dGFuY2VfdGllchgFIAEoCUID4EEDUgxpbnN0YW5jZVRpZXIisAMKIENsb3VkU3FsSW5zdGFu
Y2VCYWNrdXBQcm9wZXJ0aWVzEkEKGmRhdGFiYXNlX2luc3RhbGxlZF92ZXJzaW9uGAIgASgJ
QgPgQQNSGGRhdGFiYXNlSW5zdGFsbGVkVmVyc2lvbhImCgxmaW5hbF9iYWNrdXAYAyABKAhC
A+BBA1ILZmluYWxCYWNrdXASUQoPc291cmNlX2luc3RhbmNlGAQgASgJQijgQQP6QSIKIHNx
bGFkbWluLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUg5zb3VyY2VJbnN0YW5jZRJRChRpbnN0
YW5jZV9jcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1ISaW5zdGFuY2VDcmVhdGVUaW1lEigKDWluc3RhbmNlX3RpZXIYBiABKAlCA+BBA1IMaW5z
dGFuY2VUaWVyElEKFGluc3RhbmNlX2RlbGV0ZV90aW1lGAggASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUhJpbnN0YW5jZURlbGV0ZVRpbWUirQIKLUNsb3VkU3FsSW5z
dGFuY2VEYXRhU291cmNlUmVmZXJlbmNlUHJvcGVydGllcxI8CgRuYW1lGAEgASgJQijgQQP6
QSIKIHNxbGFkbWluLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgRuYW1lEkEKGmRhdGFiYXNl
X2luc3RhbGxlZF92ZXJzaW9uGAIgASgJQgPgQQNSGGRhdGFiYXNlSW5zdGFsbGVkVmVyc2lv
bhJRChRpbnN0YW5jZV9jcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1ISaW5zdGFuY2VDcmVhdGVUaW1lEigKDWluc3RhbmNlX3RpZXIYBSABKAlC
A+BBA1IMaW5zdGFuY2VUaWVyItYBCiRDbG91ZFNxbEluc3RhbmNlSW5pdGlhbGl6YXRpb25D
b25maWcSZQoHZWRpdGlvbhgBIAEoDjJGLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5DbG91
ZFNxbEluc3RhbmNlSW5pdGlhbGl6YXRpb25Db25maWcuRWRpdGlvbkID4EECUgdlZGl0aW9u
IkcKB0VkaXRpb24SFwoTRURJVElPTl9VTlNQRUNJRklFRBAAEg4KCkVOVEVSUFJJU0UQARIT
Cg9FTlRFUlBSSVNFX1BMVVMQAiKEAQovQ2xvdWRTcWxJbnN0YW5jZUJhY2t1cFBsYW5Bc3Nv
Y2lhdGlvblByb3BlcnRpZXMSUQoUaW5zdGFuY2VfY3JlYXRlX3RpbWUYASABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSEmluc3RhbmNlQ3JlYXRlVGltZUKWAgocY29t
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MUIYQmFja3VwdmF1bHRDbG91ZFNxbFByb3RvUAFa
OGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjEvYmFja3VwZHJwYjtiYWNrdXBk
cnBiqgIYR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYxygIYR29vZ2xlXENsb3VkXEJhY2t1cERS
XFYx6gIbR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6OlYx6kFLCiBzcWxhZG1pbi5nb29nbGVh
cGlzLmNvbS9JbnN0YW5jZRIncHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFu
Y2V9Sv0iCgcSBQ4AkQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYANQoJCgII
JRIDFgA1CggKAQgSAxcATwoJCgIICxIDFwBPCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgS
AxkAOQoJCgIICBIDGQA5CggKAQgSAxoANQoJCgIIARIDGgA1CggKAQgSAxsANQoJCgIIKRID
GwA1CggKAQgSAxwANAoJCgIILRIDHAA0CgkKAQgSBB0AIAIKDAoECJ0IABIEHQAgAgqIAQoC
BAASBCQAOgEafCBDbG91ZFNxbEluc3RhbmNlRGF0YVNvdXJjZVByb3BlcnRpZXMgcmVwcmVz
ZW50cyB0aGUgcHJvcGVydGllcyBvZiBhCiBDbG91ZCBTUUwgcmVzb3VyY2UgdGhhdCBhcmUg
c3RvcmVkIGluIHRoZSBEYXRhU291cmNlLgoKCgoDBAABEgMkCCwKigEKBAQAAgASBCgCLQQa
fCBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlIGJhY2tlZCB1
cCBieSB0aGUgZGF0YXNvdXJjZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9pbnN0
YW5jZXMve2luc3RhbmNlfQoKDAoFBAACAAUSAygCCAoMCgUEAAIAARIDKAkNCgwKBQQAAgAD
EgMoEBEKDQoFBAACAAgSBCgSLQMKDwoIBAACAAicCAASAykELQoPCgcEAAIACJ8IEgQqBCwF
ClYKBAQAAgESBDACMTIaSCBPdXRwdXQgb25seS4gVGhlIGluc3RhbGxlZCBkYXRhYmFzZSB2
ZXJzaW9uIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoMCgUEAAIBBRIDMAIICgwKBQQA
AgEBEgMwCSMKDAoFBAACAQMSAzAmJwoMCgUEAAIBCBIDMQYxCg8KCAQAAgEInAgAEgMxBzAK
PQoEBAACAhIENAI1MhovIE91dHB1dCBvbmx5LiBUaGUgaW5zdGFuY2UgY3JlYXRpb24gdGlt
ZXN0YW1wLgoKDAoFBAACAgYSAzQCGwoMCgUEAAICARIDNBwwCgwKBQQAAgIDEgM0MzQKDAoF
BAACAggSAzUGMQoPCggEAAICCJwIABIDNQcwCmYKBAQAAgMSAzkCRxpZIE91dHB1dCBvbmx5
LiBUaGUgdGllciAob3IgbWFjaGluZSB0eXBlKSBmb3IgdGhpcyBpbnN0YW5jZS4gRXhhbXBs
ZToKIGBkYi1jdXN0b20tMS0zODQwYAoKDAoFBAACAwUSAzkCCAoMCgUEAAIDARIDOQkWCgwK
BQQAAgMDEgM5GRoKDAoFBAACAwgSAzkbRgoPCggEAAIDCJwIABIDORxFCmAKAgQBEgQ+AFwB
GlQgQ2xvdWRTcWxJbnN0YW5jZUJhY2t1cFByb3BlcnRpZXMgcmVwcmVzZW50cyBDbG91ZCBT
UUwgSW5zdGFuY2UKIEJhY2t1cCBwcm9wZXJ0aWVzLgoKCgoDBAEBEgM+CCgKcQoEBAECABIE
QQJCMhpjIE91dHB1dCBvbmx5LiBUaGUgaW5zdGFsbGVkIGRhdGFiYXNlIHZlcnNpb24gb2Yg
dGhlIENsb3VkIFNRTCBpbnN0YW5jZQogd2hlbiB0aGUgYmFja3VwIHdhcyB0YWtlbi4KCgwK
BQQBAgAFEgNBAggKDAoFBAECAAESA0EJIwoMCgUEAQIAAxIDQSYnCgwKBQQBAgAIEgNCBjEK
DwoIBAECAAicCAASA0IHMApBCgQEAQIBEgNFAkQaNCBPdXRwdXQgb25seS4gV2hldGhlciB0
aGUgYmFja3VwIGlzIGEgZmluYWwgYmFja3VwLgoKDAoFBAECAQUSA0UCBgoMCgUEAQIBARID
RQcTCgwKBQQBAgEDEgNFFhcKDAoFBAECAQgSA0UYQwoPCggEAQIBCJwIABIDRRlCCnEKBAQB
AgISBEoCTwQaYyBPdXRwdXQgb25seS4gVGhlIHNvdXJjZSBpbnN0YW5jZSBvZiB0aGUgYmFj
a3VwLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9
CgoMCgUEAQICBRIDSgIICgwKBQQBAgIBEgNKCRgKDAoFBAECAgMSA0obHAoNCgUEAQICCBIE
Sh1PAwoPCggEAQICCJwIABIDSwQtCg8KBwQBAgIInwgSBEwETgUKPQoEBAECAxIEUgJTMhov
IE91dHB1dCBvbmx5LiBUaGUgaW5zdGFuY2UgY3JlYXRpb24gdGltZXN0YW1wLgoKDAoFBAEC
AwYSA1ICGwoMCgUEAQIDARIDUhwwCgwKBQQBAgMDEgNSMzQKDAoFBAECAwgSA1MGMQoPCggE
AQIDCJwIABIDUwcwCmYKBAQBAgQSA1cCRxpZIE91dHB1dCBvbmx5LiBUaGUgdGllciAob3Ig
bWFjaGluZSB0eXBlKSBmb3IgdGhpcyBpbnN0YW5jZS4gRXhhbXBsZToKIGBkYi1jdXN0b20t
MS0zODQwYAoKDAoFBAECBAUSA1cCCAoMCgUEAQIEARIDVwkWCgwKBQQBAgQDEgNXGRoKDAoF
BAECBAgSA1cbRgoPCggEAQIECJwIABIDVxxFCjsKBAQBAgUSBFoCWzIaLSBPdXRwdXQgb25s
eS4gVGhlIGluc3RhbmNlIGRlbGV0ZSB0aW1lc3RhbXAuCgoMCgUEAQIFBhIDWgIbCgwKBQQB
AgUBEgNaHDAKDAoFBAECBQMSA1ozNAoMCgUEAQIFCBIDWwYxCg8KCAQBAgUInAgAEgNbBzAK
mwEKAgQCEgRgAHYBGo4BIENsb3VkU3FsSW5zdGFuY2VEYXRhU291cmNlUmVmZXJlbmNlUHJv
cGVydGllcyByZXByZXNlbnRzIHRoZSBwcm9wZXJ0aWVzIG9mIGEKIENsb3VkIFNRTCByZXNv
dXJjZSB0aGF0IGFyZSBzdG9yZWQgaW4gdGhlIERhdGFTb3VyY2VSZWZlcmVuY2UuCgoKCgME
AgESA2AINQqKAQoEBAICABIEZAJpBBp8IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBDbG91
ZCBTUUwgaW5zdGFuY2UgYmFja2VkIHVwIGJ5IHRoZSBkYXRhc291cmNlLgogRm9ybWF0Ogog
cHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9CgoMCgUEAgIABRIDZAII
CgwKBQQCAgABEgNkCQ0KDAoFBAICAAMSA2QQEQoNCgUEAgIACBIEZBJpAwoPCggEAgIACJwI
ABIDZQQtCg8KBwQCAgAInwgSBGYEaAUKVgoEBAICARIEbAJtMhpIIE91dHB1dCBvbmx5LiBU
aGUgaW5zdGFsbGVkIGRhdGFiYXNlIHZlcnNpb24gb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5j
ZS4KCgwKBQQCAgEFEgNsAggKDAoFBAICAQESA2wJIwoMCgUEAgIBAxIDbCYnCgwKBQQCAgEI
EgNtBjEKDwoIBAICAQicCAASA20HMAo9CgQEAgICEgRwAnEyGi8gT3V0cHV0IG9ubHkuIFRo
ZSBpbnN0YW5jZSBjcmVhdGlvbiB0aW1lc3RhbXAuCgoMCgUEAgICBhIDcAIbCgwKBQQCAgIB
EgNwHDAKDAoFBAICAgMSA3AzNAoMCgUEAgICCBIDcQYxCg8KCAQCAgIInAgAEgNxBzAKZgoE
BAICAxIDdQJHGlkgT3V0cHV0IG9ubHkuIFRoZSB0aWVyIChvciBtYWNoaW5lIHR5cGUpIGZv
ciB0aGlzIGluc3RhbmNlLiBFeGFtcGxlOgogYGRiLWN1c3RvbS0xLTM4NDBgCgoMCgUEAgID
BRIDdQIICgwKBQQCAgMBEgN1CRYKDAoFBAICAwMSA3UZGgoMCgUEAgIDCBIDdRtGCg8KCAQC
AgMInAgAEgN1HEUKdgoCBAMSBXoAigEBGmkgQ2xvdWRTcWxJbnN0YW5jZUluaXRpYWxpemF0
aW9uQ29uZmlnIGNvbnRhaW5zIHRoZSBjb25maWd1cmF0aW9uIGZvcgogaW5pdGlhbGl6aW5n
IGEgQ2xvdWQgU1FMIGluc3RhbmNlLgoKCgoDBAMBEgN6CCwKewoEBAMEABIFfQKGAQMabCBU
aGUgZWRpdGlvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLiBGb3IgZGV0YWlscywgc2Vl
CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3FsL2RvY3MvZWRpdGlvbnMtaW50cm8uCgoM
CgUEAwQAARIDfQcOCiUKBgQDBAACABIDfwQcGhYgVW5zcGVjaWZpZWQgZWRpdGlvbi4KCg4K
BwQDBAACAAESA38EFwoOCgcEAwQAAgACEgN/GhsKJQoGBAMEAAIBEgSCAQQTGhUgRW50ZXJw
cmlzZSBlZGl0aW9uLgoKDwoHBAMEAAIBARIEggEEDgoPCgcEAwQAAgECEgSCARESCioKBgQD
BAACAhIEhQEEGBoaIEVudGVycHJpc2UgUGx1cyBlZGl0aW9uLgoKDwoHBAMEAAICARIEhQEE
EwoPCgcEAwQAAgICEgSFARYXCkAKBAQDAgASBIkBAj8aMiBSZXF1aXJlZC4gVGhlIGVkaXRp
b24gb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5jZS4KCg0KBQQDAgAGEgSJAQIJCg0KBQQDAgAB
EgSJAQoRCg0KBQQDAgADEgSJARQVCg0KBQQDAgAIEgSJARY+ChAKCAQDAgAInAgAEgSJARc9
CjQKAgQEEgaNAQCRAQEaJiBDbG91ZCBTUUwgaW5zdGFuY2UncyBCUEEgcHJvcGVydGllcy4K
CgsKAwQEARIEjQEINwpGCgQEBAIAEgaPAQKQATIaNiBPdXRwdXQgb25seS4gVGhlIHRpbWUg
d2hlbiB0aGUgaW5zdGFuY2Ugd2FzIGNyZWF0ZWQuCgoNCgUEBAIABhIEjwECGwoNCgUEBAIA
ARIEjwEcMAoNCgUEBAIAAxIEjwEzNAoNCgUEBAIACBIEkAEGMQoQCggEBAIACJwIABIEkAEH
MGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties ===
    # Fields for CloudSqlInstanceDataSourceProperties
    # Field: name Type: 9 ()
    # Field: database_installed_version Type: 9 ()
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_tier Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupProperties ===
    # Fields for CloudSqlInstanceBackupProperties
    # Field: database_installed_version Type: 9 ()
    # Field: final_backup Type: 8 ()
    # Field: source_instance Type: 9 ()
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_tier Type: 9 ()
    # Field: instance_delete_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties ===
    # Fields for CloudSqlInstanceDataSourceReferenceProperties
    # Field: name Type: 9 ()
    # Field: database_installed_version Type: 9 ()
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_tier Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig ===
    # Fields for CloudSqlInstanceInitializationConfig
    # Field: edition Type: 14 (.google.cloud.backupdr.v1.CloudSqlInstanceInitializationConfig.Edition)

# Enum: CloudSqlInstanceInitializationConfig::Edition
our $CloudSqlInstanceInitializationConfig_EDITION_UNSPECIFIED = 0;
our $CloudSqlInstanceInitializationConfig_ENTERPRISE = 1;
our $CloudSqlInstanceInitializationConfig_ENTERPRISE_PLUS = 2;

# === Message: Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties ===
    # Fields for CloudSqlInstanceBackupPlanAssociationProperties
    # Field: instance_create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::BackupvaultCloudsql - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/backupvault_cloudsql.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::BackupvaultCloudsql;

    my $msg = Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties->new({
        name => $name,
        database_installed_version => $database_installed_version,
        instance_create_time => $instance_create_time,
        instance_tier => $instance_tier,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/backupvault_cloudsql.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties

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

=head2 Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupProperties

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

=head2 Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties

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

=head2 Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig

CloudSqlInstanceInitializationConfig contains the configuration for
initializing a Cloud SQL instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->edition() >> / C<< $msg->edition($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::CloudSqlInstanceInitializationConfig::Edition>)

Required. The edition of the Cloud SQL instance.

=back

=head3 Enum: CloudSqlInstanceInitializationConfig::Edition

=over 4

=item * C<EDITION_UNSPECIFIED> => C<0>

=item * C<ENTERPRISE> => C<1>

=item * C<ENTERPRISE_PLUS> => C<2>

=back

=head2 Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties

Cloud SQL instance's BPA properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_create_time() >> / C<< $msg->instance_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the instance was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::BackupvaultCloudsql::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
