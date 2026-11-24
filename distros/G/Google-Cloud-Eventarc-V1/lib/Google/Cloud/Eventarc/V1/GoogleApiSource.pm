package Google::Cloud::Eventarc::V1::GoogleApiSource;

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
    eval { require Google::Cloud::Eventarc::V1::LoggingConfig };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvZ29vZ2xlX2FwaV9zb3VyY2UucHJvdG8SGGdv
b2dsZS5jbG91ZC5ldmVudGFyYy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGi1nb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvbG9nZ2luZ19jb25maWcucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i4woKD0dvb2dsZUFwaVNvdXJjZRIXCgRu
YW1lGAEgASgJQgPgQQhSBG5hbWUSHQoDdWlkGAIgASgJQgvijM/XCAIIAeBBA1IDdWlkEhcK
BGV0YWcYAyABKAlCA+BBA1IEZXRhZxJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJSCgZsYWJl
bHMYBiADKAsyNS5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuR29vZ2xlQXBpU291cmNlLkxh
YmVsc0VudHJ5QgPgQQFSBmxhYmVscxJhCgthbm5vdGF0aW9ucxgHIAMoCzI6Lmdvb2dsZS5j
bG91ZC5ldmVudGFyYy52MS5Hb29nbGVBcGlTb3VyY2UuQW5ub3RhdGlvbnNFbnRyeUID4EEB
Ugthbm5vdGF0aW9ucxImCgxkaXNwbGF5X25hbWUYCCABKAlCA+BBAVILZGlzcGxheU5hbWUS
TAoLZGVzdGluYXRpb24YCSABKAlCKuBBAvpBJAoiZXZlbnRhcmMuZ29vZ2xlYXBpcy5jb20v
TWVzc2FnZUJ1c1ILZGVzdGluYXRpb24SUQoPY3J5cHRvX2tleV9uYW1lGAogASgJQingQQH6
QSMKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleVINY3J5cHRvS2V5TmFtZRJT
Cg5sb2dnaW5nX2NvbmZpZxgLIAEoCzInLmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MS5Mb2dn
aW5nQ29uZmlnQgPgQQFSDWxvZ2dpbmdDb25maWcShgEKGW9yZ2FuaXphdGlvbl9zdWJzY3Jp
cHRpb24YDCABKAsyQi5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuR29vZ2xlQXBpU291cmNl
Lk9yZ2FuaXphdGlvblN1YnNjcmlwdGlvbkID4EEBSABSGG9yZ2FuaXphdGlvblN1YnNjcmlw
dGlvbhJ6ChVwcm9qZWN0X3N1YnNjcmlwdGlvbnMYDSABKAsyPi5nb29nbGUuY2xvdWQuZXZl
bnRhcmMudjEuR29vZ2xlQXBpU291cmNlLlByb2plY3RTdWJzY3JpcHRpb25zQgPgQQFIAFIU
cHJvamVjdFN1YnNjcmlwdGlvbnMaLwoUUHJvamVjdFN1YnNjcmlwdGlvbnMSFwoEbGlzdBgB
IAMoCUID4EECUgRsaXN0GjkKGE9yZ2FuaXphdGlvblN1YnNjcmlwdGlvbhIdCgdlbmFibGVk
GAEgASgIQgPgQQJSB2VuYWJsZWQaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARo+ChBBbm5vdGF0aW9uc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6ngHqQZoBCidldmVudGFyYy5n
b29nbGVhcGlzLmNvbS9Hb29nbGVBcGlTb3VyY2USTHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9nb29nbGVBcGlTb3VyY2VzL3tnb29nbGVfYXBpX3NvdXJjZX0q
EGdvb2dsZUFwaVNvdXJjZXMyD2dvb2dsZUFwaVNvdXJjZUIZChd3aWRlX3Njb3BlX3N1YnNj
cmlwdGlvbkLEAQocY29tLmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MUIUR29vZ2xlQXBpU291
cmNlUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby9ldmVudGFyYy9hcGl2MS9ldmVudGFy
Y3BiO2V2ZW50YXJjcGKqAhhHb29nbGUuQ2xvdWQuRXZlbnRhcmMuVjHKAhhHb29nbGVcQ2xv
dWRcRXZlbnRhcmNcVjHqAhtHb29nbGU6OkNsb3VkOjpFdmVudGFyYzo6VjFKyCMKBxIFDgCH
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwAS
AxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUANwoJCgIDBBIDFgApCggKAQgS
AxgANQoJCgIIJRIDGAA1CggKAQgSAxkATwoJCgIICxIDGQBPCggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsANQoJCgIICBIDGwA1CggKAQgSAxwANQoJCgIIARIDHAA1CggKAQgSAx0A
NQoJCgIIKRIDHQA1CggKAQgSAx4ANAoJCgIILRIDHgA0CloKAgQAEgUhAIcBARpNIEEgR29v
Z2xlQXBpU291cmNlIHJlcHJlc2VudHMgYSBzdWJzY3JpcHRpb24gb2YgMVAgZXZlbnRzIGZy
b20gYSBNZXNzYWdlQnVzLgoKCgoDBAABEgMhCBcKCwoDBAAHEgQiAicECg0KBQQAB50IEgQi
AicEClMKBAQAAwASBCoCMgMaRSBDb25maWcgdG8gZW5hYmxlIHN1YnNjcmliaW5nIHRvIGFs
bCBldmVudHMgZnJvbSBhIGxpc3Qgb2YgcHJvamVjdHMuCgoMCgUEAAMAARIDKgoeCsMCCgYE
AAMAAgASAzEERhqzAiBSZXF1aXJlZC4gQSBsaXN0IG9mIHByb2plY3RzIHRvIHJlY2VpdmUg
ZXZlbnRzIGZyb20uCgogQWxsIHRoZSBwcm9qZWN0cyBtdXN0IGJlIGluIHRoZSBzYW1lIG9y
Zy4gVGhlIGxpc3RlZCBwcm9qZWN0cyBzaG91bGQgaGF2ZQogdGhlIGZvcm1hdCBwcm9qZWN0
L3tpZGVudGlmaWVyfSB3aGVyZSBpZGVudGlmaWVyIGNhbiBiZSBlaXRoZXIgdGhlCiBwcm9q
ZWN0IGlkIGZvciBwcm9qZWN0IG51bWJlci4gQSBzaW5nbGUgbGlzdCBtYXkgY29udGFpbiBi
b3RoIGZvcm1hdHMuIEF0CiBtb3N0IDEwMCBwcm9qZWN0cyBjYW4gYmUgbGlzdGVkLgoKDgoH
BAADAAIABBIDMQQMCg4KBwQAAwACAAUSAzENEwoOCgcEAAMAAgABEgMxFBgKDgoHBAADAAIA
AxIDMRscCg4KBwQAAwACAAgSAzEdRQoRCgoEAAMAAgAInAgAEgMxHkQKVwoEBAADARIENQI4
AxpJIENvbmZpZyB0byBlbmFibGVkIHN1YnNjcmliaW5nIHRvIGV2ZW50cyBmcm9tIG90aGVy
IHByb2plY3RzIGluIHRoZSBvcmcuCgoMCgUEAAMBARIDNQoiCjkKBgQAAwECABIDNwQ+Giog
UmVxdWlyZWQuIEVuYWJsZSBvcmcgbGV2ZWwgc3Vic2NyaXB0aW9uLgoKDgoHBAADAQIABRID
NwQICg4KBwQAAwECAAESAzcJEAoOCgcEAAMBAgADEgM3ExQKDgoHBAADAQIACBIDNxU9ChEK
CgQAAwECAAicCAASAzcWPAqCAQoEBAACABIDPAI9GnUgSWRlbnRpZmllci4gUmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZm9ybQogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2dvb2dsZUFwaVNvdXJjZXMve2dvb2dsZV9hcGlfc291cmNlfQoKDAoFBAACAAUSAzwC
CAoMCgUEAAIAARIDPAkNCgwKBQQAAgADEgM8EBEKDAoFBAACAAgSAzwSPAoPCggEAAIACJwI
ABIDPBM7CrABCgQEAAIBEgRBAkQEGqEBIE91dHB1dCBvbmx5LiBTZXJ2ZXIgYXNzaWduZWQg
dW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBjaGFubmVsLiBUaGUgdmFsdWUKIGlzIGEgVVVJ
RDQgc3RyaW5nIGFuZCBndWFyYW50ZWVkIHRvIHJlbWFpbiB1bmNoYW5nZWQgdW50aWwgdGhl
IHJlc291cmNlIGlzCiBkZWxldGVkLgoKDAoFBAACAQUSA0ECCAoMCgUEAAIBARIDQQkMCgwK
BQQAAgEDEgNBDxAKDQoFBAACAQgSBEERRAMKEgoLBAACAQjM8fmKAQESA0IEKgoPCggEAAIB
CJwIABIDQwQtCuQBCgQEAAICEgNJAj4a1gEgT3V0cHV0IG9ubHkuIFRoaXMgY2hlY2tzdW0g
aXMgY29tcHV0ZWQgYnkgdGhlIHNlcnZlciBiYXNlZCBvbiB0aGUgdmFsdWUgb2YKIG90aGVy
IGZpZWxkcywgYW5kIG1pZ2h0IGJlIHNlbnQgb25seSBvbiB1cGRhdGUgYW5kIGRlbGV0ZSBy
ZXF1ZXN0cyB0bwogZW5zdXJlIHRoYXQgdGhlIGNsaWVudCBoYXMgYW4gdXAtdG8tZGF0ZSB2
YWx1ZSBiZWZvcmUgcHJvY2VlZGluZy4KCgwKBQQAAgIFEgNJAggKDAoFBAACAgESA0kJDQoM
CgUEAAICAxIDSRARCgwKBQQAAgIIEgNJEj0KDwoIBAACAgicCAASA0kTPAovCgQEAAIDEgRM
Ak0yGiEgT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGlvbiB0aW1lLgoKDAoFBAACAwYSA0wCGwoM
CgUEAAIDARIDTBwnCgwKBQQAAgMDEgNMKisKDAoFBAACAwgSA00GMQoPCggEAAIDCJwIABID
TQcwCjQKBAQAAgQSBFACUTIaJiBPdXRwdXQgb25seS4gVGhlIGxhc3QtbW9kaWZpZWQgdGlt
ZS4KCgwKBQQAAgQGEgNQAhsKDAoFBAACBAESA1AcJwoMCgUEAAIEAxIDUCorCgwKBQQAAgQI
EgNRBjEKDwoIBAACBAicCAASA1EHMAopCgQEAAIFEgNUAkoaHCBPcHRpb25hbC4gUmVzb3Vy
Y2UgbGFiZWxzLgoKDAoFBAACBQYSA1QCFQoMCgUEAAIFARIDVBYcCgwKBQQAAgUDEgNUHyAK
DAoFBAACBQgSA1QhSQoPCggEAAIFCJwIABIDVCJICi4KBAQAAgYSA1cCTxohIE9wdGlvbmFs
LiBSZXNvdXJjZSBhbm5vdGF0aW9ucy4KCgwKBQQAAgYGEgNXAhUKDAoFBAACBgESA1cWIQoM
CgUEAAIGAxIDVyQlCgwKBQQAAgYIEgNXJk4KDwoIBAACBgicCAASA1cnTQovCgQEAAIHEgNa
AkMaIiBPcHRpb25hbC4gUmVzb3VyY2UgZGlzcGxheSBuYW1lLgoKDAoFBAACBwUSA1oCCAoM
CgUEAAIHARIDWgkVCgwKBQQAAgcDEgNaGBkKDAoFBAACBwgSA1oaQgoPCggEAAIHCJwIABID
WhtBCvQBCgQEAAIIEgRgAmUEGuUBIFJlcXVpcmVkLiBEZXN0aW5hdGlvbiBpcyB0aGUgbWVz
c2FnZSBidXMgdGhhdCB0aGUgR29vZ2xlQXBpU291cmNlIGlzCiBkZWxpdmVyaW5nIHRvLiBJ
dCBtdXN0IGJlIHBvaW50IHRvIHRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgYSBNZXNzYWdl
QnVzLgogRm9ybWF0OgogInByb2plY3RzL3tQUk9KRUNUX0lEfS9sb2NhdGlvbnMve3JlZ2lv
bn0vbWVzc2FnZXNCdXNlcy97TUVTU0FHRV9CVVNfSUQpCgoMCgUEAAIIBRIDYAIICgwKBQQA
AggBEgNgCRQKDAoFBAACCAMSA2AXGAoNCgUEAAIICBIEYBllAwoPCggEAAIICJwIABIDYQQq
Cg8KBwQAAggInwgSBGIEZAUKzAEKBAQAAgkSBGwCcQQavQEgT3B0aW9uYWwuIFJlc291cmNl
IG5hbWUgb2YgYSBLTVMgY3J5cHRvIGtleSAobWFuYWdlZCBieSB0aGUgdXNlcikgdXNlZCB0
bwogZW5jcnlwdC9kZWNyeXB0IHRoZWlyIGV2ZW50IGRhdGEuCgogSXQgbXVzdCBtYXRjaCB0
aGUgcGF0dGVybgogYHByb2plY3RzLyovbG9jYXRpb25zLyova2V5UmluZ3MvKi9jcnlwdG9L
ZXlzLypgLgoKDAoFBAACCQUSA2wCCAoMCgUEAAIJARIDbAkYCgwKBQQAAgkDEgNsGx0KDQoF
BAACCQgSBGwecQMKDwoIBAACCQicCAASA20EKgoPCgcEAAIJCJ8IEgRuBHAFClQKBAQAAgoS
A3QCTRpHIE9wdGlvbmFsLiBDb25maWcgdG8gY29udHJvbCBQbGF0Zm9ybSBsb2dnaW5nIGZv
ciB0aGUgR29vZ2xlQXBpU291cmNlLgoKDAoFBAACCgYSA3QCDwoMCgUEAAIKARIDdBAeCgwK
BQQAAgoDEgN0ISMKDAoFBAACCggSA3QkTAoPCggEAAIKCJwIABIDdCVLCtsBCgQEAAgAEgV6
AoYBAxrLASBDb25maWcgdG8gZW5hYmxlZCBzdWJzY3JpYmluZyB0byBldmVudHMgZnJvbSBv
dGhlciBwcm9qZWN0cyBpbiB0aGUgb3JnLgoKIFVzZXJzIG5lZWQgdGhlIGV2ZW50YXJjLmdv
b2dsZUFwaVNvdXJjZS5jcmVhdGUgcGVybWlzc2lvbiBvbiB0aGUgZW50aXJlIG9yZwogaW4g
b3JkZXIgdG8gY3JlYXRlIGEgcmVzb3VyY2Ugd2l0aCB0aGVzZSBzZXR0aW5ncy4KCgwKBQQA
CAABEgN6CB8KcQoEBAACCxIEfQR+MRpjIE9wdGlvbmFsLiBDb25maWcgdG8gZW5hYmxlIHN1
YnNjcmliaW5nIHRvIGV2ZW50cyBmcm9tIGFsbCBwcm9qZWN0cyBpbiB0aGUKIEdvb2dsZUFw
aVNvdXJjZSdzIG9yZy4KCgwKBQQAAgsGEgN9BBwKDAoFBAACCwESA30dNgoMCgUEAAILAxID
fTk7CgwKBQQAAgsIEgN+CDAKDwoIBAACCwicCAASA34JLwqkAQoEBAACDBIGhAEEhQExGpMB
IE9wdGlvbmFsLiBDb25maWcgdG8gZW5hYmxlIHN1YnNjcmliaW5nIHRvIGFsbCBldmVudHMg
ZnJvbSBhIGxpc3Qgb2YKIHByb2plY3RzLgoKIEFsbCB0aGUgcHJvamVjdHMgbXVzdCBiZSBp
biB0aGUgc2FtZSBvcmcgYXMgdGhlIEdvb2dsZUFwaVNvdXJjZS4KCg0KBQQAAgwGEgSEAQQY
Cg0KBQQAAgwBEgSEARkuCg0KBQQAAgwDEgSEATEzCg0KBQQAAgwIEgSFAQgwChAKCAQAAgwI
nAgAEgSFAQkvYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource ===
    # Fields for GoogleApiSource
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.GoogleApiSource.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.eventarc.v1.GoogleApiSource.AnnotationsEntry)
    # Field: display_name Type: 9 ()
    # Field: destination Type: 9 ()
    # Field: crypto_key_name Type: 9 ()
    # Field: logging_config Type: 11 (.google.cloud.eventarc.v1.LoggingConfig)
    # Field: organization_subscription Type: 11 (.google.cloud.eventarc.v1.GoogleApiSource.OrganizationSubscription)
    # Field: project_subscriptions Type: 11 (.google.cloud.eventarc.v1.GoogleApiSource.ProjectSubscriptions)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::GoogleApiSource - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/google_api_source.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::GoogleApiSource;

    my $msg = Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/google_api_source.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource

A GoogleApiSource represents a subscription of 1P events from a MessageBus.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the form
projects/{project}/locations/{location}/googleApiSources/{google_api_source}

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the channel. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. This checksum is computed by the server based on the value of
other fields, and might be sent only on update and delete requests to
ensure that the client has an up-to-date value before proceeding.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::LabelsEntry>)

Optional. Resource labels.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::AnnotationsEntry>)

Optional. Resource annotations.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Resource display name.

=item * C<< $msg->destination() >> / C<< $msg->destination($value) >>

Type: C<String>

Required. Destination is the message bus that the GoogleApiSource is
delivering to. It must be point to the full resource name of a MessageBus.
Format:
"projects/{PROJECT_ID}/locations/{region}/messagesBuses/{MESSAGE_BUS_ID)

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Optional. Resource name of a KMS crypto key (managed by the user) used to
encrypt/decrypt their event data.

It must match the pattern
`projects/*/locations/*/keyRings/*/cryptoKeys/*`.

=item * C<< $msg->logging_config() >> / C<< $msg->logging_config($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig>)

Optional. Config to control Platform logging for the GoogleApiSource.

=item * C<< $msg->organization_subscription() >> / C<< $msg->organization_subscription($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::OrganizationSubscription>)

Optional. Config to enable subscribing to events from all projects in the
GoogleApiSource's org.

=item * C<< $msg->project_subscriptions() >> / C<< $msg->project_subscriptions($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::ProjectSubscriptions>)

Optional. Config to enable subscribing to all events from a list of
projects.

All the projects must be in the same org as the GoogleApiSource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::GoogleApiSource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
