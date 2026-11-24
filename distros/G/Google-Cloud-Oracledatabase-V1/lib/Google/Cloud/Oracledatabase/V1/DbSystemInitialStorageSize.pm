package Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize;

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
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGJfc3lzdGVtX2luaXRpYWxfc3Rv
cmFnZV9zaXplLnByb3RvEh5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i
gAMKGkRiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplEhcKBG5hbWUYAiABKAlCA+BBA1IEbmFt
ZRJpCgpwcm9wZXJ0aWVzGAMgASgLMkQuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYx
LkRiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplUHJvcGVydGllc0ID4EEDUgpwcm9wZXJ0aWVz
Ot0B6kHZAQo4b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vRGJTeXN0ZW1Jbml0aWFs
U3RvcmFnZVNpemUSZHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9k
YlN5c3RlbUluaXRpYWxTdG9yYWdlU2l6ZXMve2RiX3N5c3RlbV9pbml0aWFsX3N0b3JhZ2Vf
c2l6ZX0qG2RiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplczIaZGJTeXN0ZW1Jbml0aWFsU3Rv
cmFnZVNpemUipwUKJERiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplUHJvcGVydGllcxKKAQoS
c3RvcmFnZV9tYW5hZ2VtZW50GAEgASgOMlYuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNl
LnYxLkRiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplUHJvcGVydGllcy5TdG9yYWdlTWFuYWdl
bWVudEID4EEDUhFzdG9yYWdlTWFuYWdlbWVudBJyCgpzaGFwZV90eXBlGAIgASgOMk4uZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkRiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXpl
UHJvcGVydGllcy5TaGFwZVR5cGVCA+BBA1IJc2hhcGVUeXBlEmkKFHN0b3JhZ2Vfc2l6ZV9k
ZXRhaWxzGAMgAygLMjIuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLlN0b3JhZ2VT
aXplRGV0YWlsc0ID4EEDUhJzdG9yYWdlU2l6ZURldGFpbHMSjAEKJ2xhdW5jaF9mcm9tX2Jh
Y2t1cF9zdG9yYWdlX3NpemVfZGV0YWlscxgEIAMoCzIyLmdvb2dsZS5jbG91ZC5vcmFjbGVk
YXRhYmFzZS52MS5TdG9yYWdlU2l6ZURldGFpbHNCA+BBA1IibGF1bmNoRnJvbUJhY2t1cFN0
b3JhZ2VTaXplRGV0YWlscyJJChFTdG9yYWdlTWFuYWdlbWVudBIiCh5TVE9SQUdFX01BTkFH
RU1FTlRfVU5TUEVDSUZJRUQQABIHCgNBU00QARIHCgNMVk0QAiI5CglTaGFwZVR5cGUSGgoW
U0hBUEVfVFlQRV9VTlNQRUNJRklFRBAAEhAKDFNUQU5EQVJEX1g4NhABIo4BChJTdG9yYWdl
U2l6ZURldGFpbHMSOwoYZGF0YV9zdG9yYWdlX3NpemVfaW5fZ2JzGAEgASgFQgPgQQNSFGRh
dGFTdG9yYWdlU2l6ZUluR2JzEjsKGHJlY29fc3RvcmFnZV9zaXplX2luX2dicxgCIAEoBUID
4EEDUhRyZWNvU3RvcmFnZVNpemVJbkdicyLIAQomTGlzdERiU3lzdGVtSW5pdGlhbFN0b3Jh
Z2VTaXplc1JlcXVlc3QSWAoGcGFyZW50GAEgASgJQkDgQQL6QToSOG9yYWNsZWRhdGFiYXNl
Lmdvb2dsZWFwaXMuY29tL0RiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplUgZwYXJlbnQSIAoJ
cGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BB
AVIJcGFnZVRva2VuItQBCidMaXN0RGJTeXN0ZW1Jbml0aWFsU3RvcmFnZVNpemVzUmVzcG9u
c2USgAEKH2RiX3N5c3RlbV9pbml0aWFsX3N0b3JhZ2Vfc2l6ZXMYASADKAsyOi5nb29nbGUu
Y2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRGJTeXN0ZW1Jbml0aWFsU3RvcmFnZVNpemVSG2Ri
U3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW5C+QEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjFCH0Ri
U3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9v
cmFjbGVkYXRhYmFzZS9hcGl2MS9vcmFjbGVkYXRhYmFzZXBiO29yYWNsZWRhdGFiYXNlcGKq
Ah5Hb29nbGUuQ2xvdWQuT3JhY2xlRGF0YWJhc2UuVjHKAh5Hb29nbGVcQ2xvdWRcT3JhY2xl
RGF0YWJhc2VcVjHqAiFHb29nbGU6OkNsb3VkOjpPcmFjbGVEYXRhYmFzZTo6VjFKzh8KBxIF
DgCCAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoC
AwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAOwoJCgIIJRIDFQA7CggKAQgSAxYAYQoJCgII
CxIDFgBhCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAQAoJCgIICBIDGABACggKAQgS
AxkAOwoJCgIIARIDGQA7CggKAQgSAxoAOwoJCgIIKRIDGgA7CggKAQgSAxsAOgoJCgIILRID
GwA6CjsKAgQAEgQeACwBGi8gU3VtbWFyeSBvZiB0aGUgRGJTeXN0ZW0gaW5pdGlhbCBzdG9y
YWdlIHNpemUuCgoKCgMEAAESAx4IIgoLCgMEAAcSBB8CJAQKDQoFBAAHnQgSBB8CJAQKNQoE
BAACABIDJwI+GiggT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSByZXNvdXJjZS4KCgwK
BQQAAgAFEgMnAggKDAoFBAACAAESAycJDQoMCgUEAAIAAxIDJxARCgwKBQQAAgAIEgMnEj0K
DwoIBAACAAicCAASAycTPApZCgQEAAIBEgQqAisyGksgT3V0cHV0IG9ubHkuIFRoZSBwcm9w
ZXJ0aWVzIG9mIHRoZSBEYlN5c3RlbSBpbml0aWFsIHN0b3JhZ2Ugc2l6ZSBzdW1tYXJ5LgoK
DAoFBAACAQYSAyoCJgoMCgUEAAIBARIDKicxCgwKBQQAAgEDEgMqNDUKDAoFBAACAQgSAysG
MQoPCggEAAIBCJwIABIDKwcwCkgKAgQBEgQvAFQBGjwgVGhlIHByb3BlcnRpZXMgb2YgYSBE
YlN5c3RlbSBpbml0aWFsIHN0b3JhZ2Ugc2l6ZSBzdW1tYXJ5LgoKCgoDBAEBEgMvCCwKOQoE
BAEEABIEMQI6AxorIFRoZSBzdG9yYWdlIG9wdGlvbiB1c2VkIGluIHRoZSBEQiBzeXN0ZW0u
CgoMCgUEAQQAARIDMQcYCjAKBgQBBAACABIDMwQnGiEgVW5zcGVjaWZpZWQgc3RvcmFnZSBt
YW5hZ2VtZW50LgoKDgoHBAEEAAIAARIDMwQiCg4KBwQBBAACAAISAzMlJgouCgYEAQQAAgES
AzYEDBofIEF1dG9tYXRpYyBTdG9yYWdlIE1hbmFnZW1lbnQuCgoOCgcEAQQAAgEBEgM2BAcK
DgoHBAEEAAIBAhIDNgoLCisKBgQBBAACAhIDOQQMGhwgTG9naWNhbCBWb2x1bWUgTWFuYWdl
bWVudC4KCg4KBwQBBAACAgESAzkEBwoOCgcEAQQAAgICEgM5CgsKMAoEBAEEARIEPQJDAxoi
IFRoZSBzaGFwZSB0eXBlIG9mIHRoZSBEQiBzeXN0ZW0uCgoMCgUEAQQBARIDPQcQCigKBgQB
BAECABIDPwQfGhkgVW5zcGVjaWZpZWQgc2hhcGUgdHlwZS4KCg4KBwQBBAECAAESAz8EGgoO
CgcEAQQBAgACEgM/HR4KHgoGBAEEAQIBEgNCBBUaDyBTdGFuZGFyZCBYODYuCgoOCgcEAQQB
AgEBEgNCBBAKDgoHBAEEAQIBAhIDQhMUCkIKBAQBAgASBEYCRzIaNCBPdXRwdXQgb25seS4g
VGhlIHN0b3JhZ2Ugb3B0aW9uIHVzZWQgaW4gREIgc3lzdGVtLgoKDAoFBAECAAYSA0YCEwoM
CgUEAQIAARIDRhQmCgwKBQQBAgADEgNGKSoKDAoFBAECAAgSA0cGMQoPCggEAQIACJwIABID
RwcwCjIKBAQBAgESA0oCRxolIE91dHB1dCBvbmx5LiBWTSBzaGFwZSBwbGF0Zm9ybSB0eXBl
CgoMCgUEAQIBBhIDSgILCgwKBQQBAgEBEgNKDBYKDAoFBAECAQMSA0oZGgoMCgUEAQIBCBID
ShtGCg8KCAQBAgEInAgAEgNKHEUKOgoEBAECAhIETQJOMhosIE91dHB1dCBvbmx5LiBMaXN0
IG9mIHN0b3JhZ2UgZGlzayBkZXRhaWxzLgoKDAoFBAECAgQSA00CCgoMCgUEAQICBhIDTQsd
CgwKBQQBAgIBEgNNHjIKDAoFBAECAgMSA001NgoMCgUEAQICCBIDTgYxCg8KCAQBAgIInAgA
EgNOBzAKXgoEBAECAxIEUgJTMhpQIE91dHB1dCBvbmx5LiBMaXN0IG9mIHN0b3JhZ2UgZGlz
ayBkZXRhaWxzIGF2YWlsYWJsZSBmb3IgbGF1bmNoZXMgZnJvbQogYmFja3VwLgoKDAoFBAEC
AwQSA1ICCgoMCgUEAQIDBhIDUgsdCgwKBQQBAgMBEgNSHkUKDAoFBAECAwMSA1JISQoMCgUE
AQIDCBIDUwYxCg8KCAQBAgMInAgAEgNTBzAKZwoCBAISBFgAYgEaWyBUaGUgaW5pdGlhbCBz
dG9yYWdlIHNpemUsIGluIGdpZ2FieXRlcywgdGhhdCBpcyBhcHBsaWNhYmxlIGZvciB2aXJ0
dWFsCiBtYWNoaW5lIERCU3lzdGVtLgoKCgoDBAIBEgNYCBoKcwoEBAICABIEWwJcMhplIE91
dHB1dCBvbmx5LiBUaGUgZGF0YSBzdG9yYWdlIHNpemUsIGluIGdpZ2FieXRlcywgdGhhdCBp
cyBhcHBsaWNhYmxlIGZvcgogdmlydHVhbCBtYWNoaW5lIERCU3lzdGVtLgoKDAoFBAICAAUS
A1sCBwoMCgUEAgIAARIDWwggCgwKBQQCAgADEgNbIyQKDAoFBAICAAgSA1wGMQoPCggEAgIA
CJwIABIDXAcwCngKBAQCAgESBGACYTIaaiBPdXRwdXQgb25seS4gVGhlIFJFQ08vUkVETyBz
dG9yYWdlIHNpemUsIGluIGdpZ2FieXRlcywgdGhhdCBpcyBhcHBsaWNhYmxlCiBmb3Igdmly
dHVhbCBtYWNoaW5lIERCU3lzdGVtLgoKDAoFBAICAQUSA2ACBwoMCgUEAgIBARIDYAggCgwK
BQQCAgEDEgNgIyQKDAoFBAICAQgSA2EGMQoPCggEAgIBCJwIABIDYQcwCkEKAgQDEgRlAHkB
GjUgVGhlIHJlcXVlc3QgZm9yIGBEYlN5c3RlbUluaXRpYWxTdG9yYWdlU2l6ZXMuTGlzdGAu
CgoKCgMEAwESA2UILgqRAQoEBAMCABIEaAJtBBqCASBSZXF1aXJlZC4gVGhlIHBhcmVudCB2
YWx1ZSBmb3IgdGhlIERiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXplIHJlc291cmNlIHdpdGgK
IHRoZSBmb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufQoK
DAoFBAMCAAUSA2gCCAoMCgUEAwIAARIDaAkPCgwKBQQDAgADEgNoEhMKDQoFBAMCAAgSBGgU
bQMKDwoIBAMCAAicCAASA2kEKgoPCgcEAwIACJ8IEgRqBGwFCtUBCgQEAwIBEgNzAj8axwEg
T3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4uCiBJZiB1
bnNwZWNpZmllZCwgYSBtYXhpbXVtIG9mIDUwIERiU3lzdGVtSW5pdGlhbFN0b3JhZ2VTaXpl
cyB3aWxsIGJlCiByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVz
IGFib3ZlIDEwMDAgd2lsbCBiZSByZXNldCB0bwogMTAwMC4KCgwKBQQDAgEFEgNzAgcKDAoF
BAMCAQESA3MIEQoMCgUEAwIBAxIDcxQVCgwKBQQDAgEIEgNzFj4KDwoIBAMCAQicCAASA3MX
PQq9AQoEBAMCAhIDeAJBGq8BIE9wdGlvbmFsLiBBIHRva2VuIGlkZW50aWZ5aW5nIHRoZSBy
ZXF1ZXN0ZWQgcGFnZSBvZiByZXN1bHRzIHRvIHJldHVybi4gQWxsCiBmaWVsZHMgZXhjZXB0
IHRoZSBmaWx0ZXIgc2hvdWxkIHJlbWFpbiB0aGUgc2FtZSBhcyBpbiB0aGUgcmVxdWVzdCB0
aGF0CiBwcm92aWRlZCB0aGlzIHBhZ2UgdG9rZW4uCgoMCgUEAwICBRIDeAIICgwKBQQDAgIB
EgN4CRMKDAoFBAMCAgMSA3gWFwoMCgUEAwICCBIDeBhACg8KCAQDAgIInAgAEgN4GT8KQwoC
BAQSBXwAggEBGjYgVGhlIHJlc3BvbnNlIGZvciBgRGJTeXN0ZW1Jbml0aWFsU3RvcmFnZVNp
emVzLkxpc3RgLgoKCgoDBAQBEgN8CC8KNwoEBAQCABIDfgJKGiogVGhlIGxpc3Qgb2YgRGJT
eXN0ZW1Jbml0aWFsU3RvcmFnZVNpemVzLgoKDAoFBAQCAAQSA34CCgoMCgUEBAIABhIDfgsl
CgwKBQQEAgABEgN+JkUKDAoFBAQCAAMSA35ISQpPCgQEBAIBEgSBAQIdGkEgQSB0b2tlbiBp
ZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4u
CgoNCgUEBAIBBRIEgQECCAoNCgUEBAIBARIEgQEJGAoNCgUEBAIBAxIEgQEbHGIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize ===
    # Fields for DbSystemInitialStorageSize
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.DbSystemInitialStorageSizeProperties)

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSizeProperties ===
    # Fields for DbSystemInitialStorageSizeProperties
    # Field: storage_management Type: 14 (.google.cloud.oracledatabase.v1.DbSystemInitialStorageSizeProperties.StorageManagement)
    # Field: shape_type Type: 14 (.google.cloud.oracledatabase.v1.DbSystemInitialStorageSizeProperties.ShapeType)
    # Field: storage_size_details Type: 11 (.google.cloud.oracledatabase.v1.StorageSizeDetails)
    # Field: launch_from_backup_storage_size_details Type: 11 (.google.cloud.oracledatabase.v1.StorageSizeDetails)

# Enum: DbSystemInitialStorageSizeProperties::StorageManagement
our $DbSystemInitialStorageSizeProperties_STORAGE_MANAGEMENT_UNSPECIFIED = 0;
our $DbSystemInitialStorageSizeProperties_ASM = 1;
our $DbSystemInitialStorageSizeProperties_LVM = 2;

# Enum: DbSystemInitialStorageSizeProperties::ShapeType
our $DbSystemInitialStorageSizeProperties_SHAPE_TYPE_UNSPECIFIED = 0;
our $DbSystemInitialStorageSizeProperties_STANDARD_X86 = 1;

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails ===
    # Fields for StorageSizeDetails
    # Field: data_storage_size_in_gbs Type: 5 ()
    # Field: reco_storage_size_in_gbs Type: 5 ()

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesRequest ===
    # Fields for ListDbSystemInitialStorageSizesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesResponse ===
    # Fields for ListDbSystemInitialStorageSizesResponse
    # Field: db_system_initial_storage_sizes Type: 11 (.google.cloud.oracledatabase.v1.DbSystemInitialStorageSize)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/db_system_initial_storage_size.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize;

    my $msg = Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize->new({
        name => $name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/db_system_initial_storage_size.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize

Summary of the DbSystem initial storage size.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the resource.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSizeProperties>)

Output only. The properties of the DbSystem initial storage size summary.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSizeProperties

The properties of a DbSystem initial storage size summary.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->storage_management() >> / C<< $msg->storage_management($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSizeProperties::StorageManagement>)

Output only. The storage option used in DB system.

=item * C<< $msg->shape_type() >> / C<< $msg->shape_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSizeProperties::ShapeType>)

Output only. VM shape platform type

=item * C<< $msg->storage_size_details() >> / C<< $msg->storage_size_details($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails>)

Output only. List of storage disk details.

=item * C<< $msg->launch_from_backup_storage_size_details() >> / C<< $msg->launch_from_backup_storage_size_details($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails>)

Output only. List of storage disk details available for launches from
backup.

=back

=head3 Enum: DbSystemInitialStorageSizeProperties::StorageManagement

=over 4

=item * C<STORAGE_MANAGEMENT_UNSPECIFIED> => C<0>

=item * C<ASM> => C<1>

=item * C<LVM> => C<2>

=back

=head3 Enum: DbSystemInitialStorageSizeProperties::ShapeType

=over 4

=item * C<SHAPE_TYPE_UNSPECIFIED> => C<0>

=item * C<STANDARD_X86> => C<1>

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails

The initial storage size, in gigabytes, that is applicable for virtual
machine DBSystem.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_storage_size_in_gbs() >> / C<< $msg->data_storage_size_in_gbs($value) >>

Type: C<Int32>

Output only. The data storage size, in gigabytes, that is applicable for
virtual machine DBSystem.

=item * C<< $msg->reco_storage_size_in_gbs() >> / C<< $msg->reco_storage_size_in_gbs($value) >>

Type: C<Int32>

Output only. The RECO/REDO storage size, in gigabytes, that is applicable
for virtual machine DBSystem.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesRequest

The request for `DbSystemInitialStorageSizes.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the DbSystemInitialStorageSize resource with
the format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, a maximum of 50 DbSystemInitialStorageSizes will be
returned. The maximum value is 1000; values above 1000 will be reset to
1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the requested page of results to return. All
fields except the filter should remain the same as in the request that
provided this page token.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesResponse

The response for `DbSystemInitialStorageSizes.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->db_system_initial_storage_sizes() >> / C<< $msg->db_system_initial_storage_sizes($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize>)

The list of DbSystemInitialStorageSizes.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
