package Google::Spanner::Admin::Database::V1::Common;

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
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvc3Bhbm5lci9hZG1pbi9kYXRhYmFzZS92MS9jb21tb24ucHJvdG8SIGdvb2ds
ZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byKwAQoRT3BlcmF0aW9uUHJv
Z3Jlc3MSKQoQcHJvZ3Jlc3NfcGVyY2VudBgBIAEoBVIPcHJvZ3Jlc3NQZXJjZW50EjkKCnN0
YXJ0X3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFydFRpbWUS
NQoIZW5kX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdlbmRUaW1l
IqgBChBFbmNyeXB0aW9uQ29uZmlnEkgKDGttc19rZXlfbmFtZRgCIAEoCUIm+kEjCiFjbG91
ZGttcy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXlSCmttc0tleU5hbWUSSgoNa21zX2tleV9u
YW1lcxgDIAMoCUIm+kEjCiFjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXlSC2tt
c0tleU5hbWVzIvMCCg5FbmNyeXB0aW9uSW5mbxJjCg9lbmNyeXB0aW9uX3R5cGUYAyABKA4y
NS5nb29nbGUuc3Bhbm5lci5hZG1pbi5kYXRhYmFzZS52MS5FbmNyeXB0aW9uSW5mby5UeXBl
QgPgQQNSDmVuY3J5cHRpb25UeXBlEkQKEWVuY3J5cHRpb25fc3RhdHVzGAQgASgLMhIuZ29v
Z2xlLnJwYy5TdGF0dXNCA+BBA1IQZW5jcnlwdGlvblN0YXR1cxJYCg9rbXNfa2V5X3ZlcnNp
b24YAiABKAlCMOBBA/pBKgooY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5VmVy
c2lvblINa21zS2V5VmVyc2lvbiJcCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIdChlH
T09HTEVfREVGQVVMVF9FTkNSWVBUSU9OEAESHwobQ1VTVE9NRVJfTUFOQUdFRF9FTkNSWVBU
SU9OEAIqXAoPRGF0YWJhc2VEaWFsZWN0EiAKHERBVEFCQVNFX0RJQUxFQ1RfVU5TUEVDSUZJ
RUQQABIXChNHT09HTEVfU1RBTkRBUkRfU1FMEAESDgoKUE9TVEdSRVNRTBACQqIECiRjb20u
Z29vZ2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2UudjFCC0NvbW1vblByb3RvUAFaRmNsb3Vk
Lmdvb2dsZS5jb20vZ28vc3Bhbm5lci9hZG1pbi9kYXRhYmFzZS9hcGl2MS9kYXRhYmFzZXBi
O2RhdGFiYXNlcGKqAiZHb29nbGUuQ2xvdWQuU3Bhbm5lci5BZG1pbi5EYXRhYmFzZS5WMcoC
Jkdvb2dsZVxDbG91ZFxTcGFubmVyXEFkbWluXERhdGFiYXNlXFYx6gIrR29vZ2xlOjpDbG91
ZDo6U3Bhbm5lcjo6QWRtaW46OkRhdGFiYXNlOjpWMepBeAohY2xvdWRrbXMuZ29vZ2xlYXBp
cy5jb20vQ3J5cHRvS2V5ElNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fepBpgEKKGNs
b3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleVZlcnNpb24SenByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jpbmd9L2NyeXB0b0tl
eXMve2NyeXB0b19rZXl9L2NyeXB0b0tleVZlcnNpb25zL3tjcnlwdG9fa2V5X3ZlcnNpb259
SsMhCgcSBQ4AgwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAApCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCgkKAgMDEgMVACEKCAoBCBID
FwBDCgkKAgglEgMXAEMKCAoBCBIDGABdCgkKAggLEgMYAF0KCAoBCBIDGQAiCgkKAggKEgMZ
ACIKCAoBCBIDGgAsCgkKAggIEgMaACwKCAoBCBIDGwA9CgkKAggBEgMbAD0KCAoBCBIDHABF
CgkKAggpEgMcAEUKCAoBCBIDHQBECgkKAggtEgMdAEQKCQoBCBIEHgAhAgoMCgQInQgAEgQe
ACECCgkKAQgSBCIAJQIKDAoECJ0IARIEIgAlAgpkCgIEABIEKQA0ARpYIEVuY2Fwc3VsYXRl
cyBwcm9ncmVzcyByZWxhdGVkIGluZm9ybWF0aW9uIGZvciBhIENsb3VkIFNwYW5uZXIgbG9u
ZwogcnVubmluZyBvcGVyYXRpb24uCgoKCgMEAAESAykIGQpcCgQEAAIAEgMsAh0aTyBQZXJj
ZW50IGNvbXBsZXRpb24gb2YgdGhlIG9wZXJhdGlvbi4KIFZhbHVlcyBhcmUgYmV0d2VlbiAw
IGFuZCAxMDAgaW5jbHVzaXZlLgoKDAoFBAACAAUSAywCBwoMCgUEAAIAARIDLAgYCgwKBQQA
AgADEgMsGxwKLQoEBAACARIDLwIrGiAgVGltZSB0aGUgcmVxdWVzdCB3YXMgcmVjZWl2ZWQu
CgoMCgUEAAIBBhIDLwIbCgwKBQQAAgEBEgMvHCYKDAoFBAACAQMSAy8pKgpeCgQEAAICEgMz
AikaUSBJZiBzZXQsIHRoZSB0aW1lIGF0IHdoaWNoIHRoaXMgb3BlcmF0aW9uIGZhaWxlZCBv
ciB3YXMgY29tcGxldGVkCiBzdWNjZXNzZnVsbHkuCgoMCgUEAAICBhIDMwIbCgwKBQQAAgIB
EgMzHCQKDAoFBAACAgMSAzMnKApECgIEARIENwBRARo4IEVuY3J5cHRpb24gY29uZmlndXJh
dGlvbiBmb3IgYSBDbG91ZCBTcGFubmVyIGRhdGFiYXNlLgoKCgoDBAEBEgM3CBgKywEKBAQB
AgASBDsCPQUavAEgVGhlIENsb3VkIEtNUyBrZXkgdG8gYmUgdXNlZCBmb3IgZW5jcnlwdGlu
ZyBhbmQgZGVjcnlwdGluZwogdGhlIGRhdGFiYXNlLiBWYWx1ZXMgYXJlIG9mIHRoZSBmb3Jt
CiBgcHJvamVjdHMvPHByb2plY3Q+L2xvY2F0aW9ucy88bG9jYXRpb24+L2tleVJpbmdzLzxr
ZXlfcmluZz4vY3J5cHRvS2V5cy88a21zX2tleV9uYW1lPmAuCgoMCgUEAQIABRIDOwIICgwK
BQQBAgABEgM7CRUKDAoFBAECAAMSAzsYGQoNCgUEAQIACBIEOxo9BAoPCgcEAQIACJ8IEgQ7
Gz0DCvAGCgQEAQIBEgROAlAFGuEGIFNwZWNpZmllcyB0aGUgS01TIGNvbmZpZ3VyYXRpb24g
Zm9yIHRoZSBvbmUgb3IgbW9yZSBrZXlzIHVzZWQgdG8gZW5jcnlwdAogdGhlIGRhdGFiYXNl
LiBWYWx1ZXMgYXJlIG9mIHRoZSBmb3JtCiBgcHJvamVjdHMvPHByb2plY3Q+L2xvY2F0aW9u
cy88bG9jYXRpb24+L2tleVJpbmdzLzxrZXlfcmluZz4vY3J5cHRvS2V5cy88a21zX2tleV9u
YW1lPmAuCgogVGhlIGtleXMgcmVmZXJlbmNlZCBieSBrbXNfa2V5X25hbWVzIG11c3QgZnVs
bHkgY292ZXIgYWxsCiByZWdpb25zIG9mIHRoZSBkYXRhYmFzZSBpbnN0YW5jZSBjb25maWd1
cmF0aW9uLiBTb21lIGV4YW1wbGVzOgogKiBGb3Igc2luZ2xlIHJlZ2lvbiBkYXRhYmFzZSBp
bnN0YW5jZSBjb25maWdzLCBzcGVjaWZ5IGEgc2luZ2xlIHJlZ2lvbmFsCiBsb2NhdGlvbiBL
TVMga2V5LgogKiBGb3IgbXVsdGktcmVnaW9uYWwgZGF0YWJhc2UgaW5zdGFuY2UgY29uZmln
cyBvZiB0eXBlIEdPT0dMRV9NQU5BR0VELAogZWl0aGVyIHNwZWNpZnkgYSBtdWx0aS1yZWdp
b25hbCBsb2NhdGlvbiBLTVMga2V5IG9yIG11bHRpcGxlIHJlZ2lvbmFsCiBsb2NhdGlvbiBL
TVMga2V5cyB0aGF0IGNvdmVyIGFsbCByZWdpb25zIGluIHRoZSBpbnN0YW5jZSBjb25maWcu
CiAqIEZvciBhIGRhdGFiYXNlIGluc3RhbmNlIGNvbmZpZyBvZiB0eXBlIFVTRVJfTUFOQUdF
RCwgcGxlYXNlIHNwZWNpZnkgb25seQogcmVnaW9uYWwgbG9jYXRpb24gS01TIGtleXMgdG8g
Y292ZXIgZWFjaCByZWdpb24gaW4gdGhlIGluc3RhbmNlIGNvbmZpZy4KIE11bHRpLXJlZ2lv
bmFsIGxvY2F0aW9uIEtNUyBrZXlzIGFyZSBub3Qgc3VwcG9ydGVkIGZvciBVU0VSX01BTkFH
RUQKIGluc3RhbmNlIGNvbmZpZ3MuCgoMCgUEAQIBBBIDTgIKCgwKBQQBAgEFEgNOCxEKDAoF
BAECAQESA04SHwoMCgUEAQIBAxIDTiIjCg0KBQQBAgEIEgROJFAECg8KBwQBAgEInwgSBE4l
UAMKTAoCBAISBFQAdgEaQCBFbmNyeXB0aW9uIGluZm9ybWF0aW9uIGZvciBhIENsb3VkIFNw
YW5uZXIgZGF0YWJhc2Ugb3IgYmFja3VwLgoKCgoDBAIBEgNUCBYKKgoEBAIEABIEVgJjAxoc
IFBvc3NpYmxlIGVuY3J5cHRpb24gdHlwZXMuCgoMCgUEAgQAARIDVgcLCloKBgQCBAACABID
WAQZGksgRW5jcnlwdGlvbiB0eXBlIHdhcyBub3Qgc3BlY2lmaWVkLCB0aG91Z2ggZGF0YSBh
dCByZXN0IHJlbWFpbnMgZW5jcnlwdGVkLgoKDgoHBAIEAAIAARIDWAQUCg4KBwQCBAACAAIS
A1gXGAqkAQoGBAIEAAIBEgNdBCIalAEgVGhlIGRhdGEgaXMgZW5jcnlwdGVkIGF0IHJlc3Qg
d2l0aCBhIGtleSB0aGF0IGlzCiBmdWxseSBtYW5hZ2VkIGJ5IEdvb2dsZS4gTm8ga2V5IHZl
cnNpb24gb3Igc3RhdHVzIHdpbGwgYmUgcG9wdWxhdGVkLgogVGhpcyBpcyB0aGUgZGVmYXVs
dCBzdGF0ZS4KCg4KBwQCBAACAQESA10EHQoOCgcEAgQAAgECEgNdICEKywEKBgQCBAACAhID
YgQkGrsBIFRoZSBkYXRhIGlzIGVuY3J5cHRlZCBhdCByZXN0IHdpdGggYSBrZXkgdGhhdCBp
cwogbWFuYWdlZCBieSB0aGUgY3VzdG9tZXIuIFRoZSBhY3RpdmUgdmVyc2lvbiBvZiB0aGUg
a2V5LiBga21zX2tleV92ZXJzaW9uYAogd2lsbCBiZSBwb3B1bGF0ZWQsIGFuZCBgZW5jcnlw
dGlvbl9zdGF0dXNgIG1heSBiZSBwb3B1bGF0ZWQuCgoOCgcEAgQAAgIBEgNiBB8KDgoHBAIE
AAICAhIDYiIjCjMKBAQCAgASA2YCRxomIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiBlbmNy
eXB0aW9uLgoKDAoFBAICAAYSA2YCBgoMCgUEAgIAARIDZgcWCgwKBQQCAgADEgNmGRoKDAoF
BAICAAgSA2YbRgoPCggEAgIACJwIABIDZhxFCr8BCgQEAgIBEgRrAmwyGrABIE91dHB1dCBv
bmx5LiBJZiBwcmVzZW50LCB0aGUgc3RhdHVzIG9mIGEgcmVjZW50IGVuY3J5cHQvZGVjcnlw
dCBjYWxsIG9uCiB1bmRlcmx5aW5nIGRhdGEgZm9yIHRoaXMgZGF0YWJhc2Ugb3IgYmFja3Vw
LiBSZWdhcmRsZXNzIG9mIHN0YXR1cywgZGF0YSBpcwogYWx3YXlzIGVuY3J5cHRlZCBhdCBy
ZXN0LgoKDAoFBAICAQYSA2sCEwoMCgUEAgIBARIDaxQlCgwKBQQCAgEDEgNrKCkKDAoFBAIC
AQgSA2wGMQoPCggEAgIBCJwIABIDbAcwCmsKBAQCAgISBHACdQQaXSBPdXRwdXQgb25seS4g
QSBDbG91ZCBLTVMga2V5IHZlcnNpb24gdGhhdCBpcyBiZWluZyB1c2VkIHRvIHByb3RlY3Qg
dGhlCiBkYXRhYmFzZSBvciBiYWNrdXAuCgoMCgUEAgICBRIDcAIICgwKBQQCAgIBEgNwCRgK
DAoFBAICAgMSA3AbHAoNCgUEAgICCBIEcB11AwoPCggEAgICCJwIABIDcQQtCg8KBwQCAgII
nwgSBHIEdAUKOAoCBQASBXkAgwEBGisgSW5kaWNhdGVzIHRoZSBkaWFsZWN0IHR5cGUgb2Yg
YSBkYXRhYmFzZS4KCgoKAwUAARIDeQUUCmYKBAUAAgASA3wCIxpZIERlZmF1bHQgdmFsdWUu
IFRoaXMgdmFsdWUgd2lsbCBjcmVhdGUgYSBkYXRhYmFzZSB3aXRoIHRoZQogR09PR0xFX1NU
QU5EQVJEX1NRTCBkaWFsZWN0LgoKDAoFBQACAAESA3wCHgoMCgUFAAIAAhIDfCEiCicKBAUA
AgESA38CGhoaIEdvb2dsZVNRTCBzdXBwb3J0ZWQgU1FMLgoKDAoFBQACAQESA38CFQoMCgUF
AAIBAhIDfxgZCikKBAUAAgISBIIBAhEaGyBQb3N0Z3JlU1FMIHN1cHBvcnRlZCBTUUwuCgoN
CgUFAAICARIEggECDAoNCgUFAAICAhIEggEPEGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::Admin::Database::V1::Common::OperationProgress ===
    # Fields for OperationProgress
    # Field: progress_percent Type: 5 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Spanner::Admin::Database::V1::Common::EncryptionConfig ===
    # Fields for EncryptionConfig
    # Field: kms_key_name Type: 9 ()
    # Field: kms_key_names Type: 9 ()

# === Message: Google::Spanner::Admin::Database::V1::Common::EncryptionInfo ===
    # Fields for EncryptionInfo
    # Field: encryption_type Type: 14 (.google.spanner.admin.database.v1.EncryptionInfo.Type)
    # Field: encryption_status Type: 11 (.google.rpc.Status)
    # Field: kms_key_version Type: 9 ()

# Enum: EncryptionInfo::Type
our $EncryptionInfo_TYPE_UNSPECIFIED = 0;
our $EncryptionInfo_GOOGLE_DEFAULT_ENCRYPTION = 1;
our $EncryptionInfo_CUSTOMER_MANAGED_ENCRYPTION = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::Admin::Database::V1::Common - Compiled Protocol Buffers messages for google/spanner/admin/database/v1/common.proto

=head1 SYNOPSIS

    use Google::Spanner::Admin::Database::V1::Common;

    my $msg = Google::Spanner::Admin::Database::V1::Common::OperationProgress->new({
        progress_percent => $progress_percent,
        start_time => $start_time,
        end_time => $end_time,
    });

    # Read or update a field
    my $val = $msg->progress_percent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::Admin::Database::V1::Common::OperationProgress->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/admin/database/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::Admin::Database::V1::Common::OperationProgress

Encapsulates progress related information for a Cloud Spanner long
running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Percent completion of the operation.
Values are between 0 and 100 inclusive.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the request was received.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If set, the time at which this operation failed or was completed
successfully.

=back

=head2 Google::Spanner::Admin::Database::V1::Common::EncryptionConfig

Encryption configuration for a Cloud Spanner database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kms_key_name() >> / C<< $msg->kms_key_name($value) >>

Type: C<String>

The Cloud KMS key to be used for encrypting and decrypting
the database. Values are of the form
`projects/<project>/locations/<location>/keyRings/<key_ring>/cryptoKeys/<kms_key_name>`.

=item * C<< $msg->kms_key_names() >> / C<< $msg->kms_key_names($value) >>

Type: C<String>

Specifies the KMS configuration for the one or more keys used to encrypt
the database. Values are of the form
`projects/<project>/locations/<location>/keyRings/<key_ring>/cryptoKeys/<kms_key_name>`.

The keys referenced by kms_key_names must fully cover all
regions of the database instance configuration. Some examples:
* For single region database instance configs, specify a single regional
location KMS key.
* For multi-regional database instance configs of type GOOGLE_MANAGED,
either specify a multi-regional location KMS key or multiple regional
location KMS keys that cover all regions in the instance config.
* For a database instance config of type USER_MANAGED, please specify only
regional location KMS keys to cover each region in the instance config.
Multi-regional location KMS keys are not supported for USER_MANAGED
instance configs.

=back

=head2 Google::Spanner::Admin::Database::V1::Common::EncryptionInfo

Encryption information for a Cloud Spanner database or backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encryption_type() >> / C<< $msg->encryption_type($value) >>

Type: C<Enum> (L<Google::Spanner::Admin::Database::V1::EncryptionInfo::Type>)

Output only. The type of encryption.

=item * C<< $msg->encryption_status() >> / C<< $msg->encryption_status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. If present, the status of a recent encrypt/decrypt call on
underlying data for this database or backup. Regardless of status, data is
always encrypted at rest.

=item * C<< $msg->kms_key_version() >> / C<< $msg->kms_key_version($value) >>

Type: C<String>

Output only. A Cloud KMS key version that is being used to protect the
database or backup.

=back

=head3 Enum: EncryptionInfo::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<GOOGLE_DEFAULT_ENCRYPTION> => C<1>

=item * C<CUSTOMER_MANAGED_ENCRYPTION> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::Admin::Database::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
