package Google::Cloud::Securitycenter::V2::ResourceValueConfig;

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
    eval { require Google::Cloud::Securitycenter::V2::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvcmVzb3VyY2VfdmFsdWVfY29uZmln
LnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9j
bG91ZC9zZWN1cml0eWNlbnRlci92Mi9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byLaCgoTUmVzb3VyY2VWYWx1ZUNvbmZpZxIXCgRuYW1lGAEgASgJ
QgPgQQhSBG5hbWUSVAoOcmVzb3VyY2VfdmFsdWUYAiABKA4yLS5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjIuUmVzb3VyY2VWYWx1ZVINcmVzb3VyY2VWYWx1ZRIdCgp0YWdfdmFs
dWVzGAMgAygJUgl0YWdWYWx1ZXMSIwoNcmVzb3VyY2VfdHlwZRgEIAEoCVIMcmVzb3VyY2VU
eXBlEhQKBXNjb3BlGAUgASgJUgVzY29wZRKJAQoYcmVzb3VyY2VfbGFiZWxzX3NlbGVjdG9y
GAYgAygLMk8uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLlJlc291cmNlVmFsdWVD
b25maWcuUmVzb3VyY2VMYWJlbHNTZWxlY3RvckVudHJ5UhZyZXNvdXJjZUxhYmVsc1NlbGVj
dG9yEiAKC2Rlc2NyaXB0aW9uGAcgASgJUgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgI
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1
cGRhdGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBk
YXRlVGltZRJUCg5jbG91ZF9wcm92aWRlchgKIAEoDjItLmdvb2dsZS5jbG91ZC5zZWN1cml0
eWNlbnRlci52Mi5DbG91ZFByb3ZpZGVyUg1jbG91ZFByb3ZpZGVyEp0BCiFzZW5zaXRpdmVf
ZGF0YV9wcm90ZWN0aW9uX21hcHBpbmcYCyABKAsyUi5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjIuUmVzb3VyY2VWYWx1ZUNvbmZpZy5TZW5zaXRpdmVEYXRhUHJvdGVjdGlvbk1h
cHBpbmdSHnNlbnNpdGl2ZURhdGFQcm90ZWN0aW9uTWFwcGluZxr2AQoeU2Vuc2l0aXZlRGF0
YVByb3RlY3Rpb25NYXBwaW5nEmcKGGhpZ2hfc2Vuc2l0aXZpdHlfbWFwcGluZxgBIAEoDjIt
Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5SZXNvdXJjZVZhbHVlUhZoaWdoU2Vu
c2l0aXZpdHlNYXBwaW5nEmsKGm1lZGl1bV9zZW5zaXRpdml0eV9tYXBwaW5nGAIgASgOMi0u
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLlJlc291cmNlVmFsdWVSGG1lZGl1bVNl
bnNpdGl2aXR5TWFwcGluZxpJChtSZXNvdXJjZUxhYmVsc1NlbGVjdG9yRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATqNAupBiQIKMXNlY3VyaXR5
Y2VudGVyLmdvb2dsZWFwaXMuY29tL1Jlc291cmNlVmFsdWVDb25maWcSSW9yZ2FuaXphdGlv
bnMve29yZ2FuaXphdGlvbn0vcmVzb3VyY2VWYWx1ZUNvbmZpZ3Mve3Jlc291cmNlX3ZhbHVl
X2NvbmZpZ30SXm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vcmVzb3VyY2VWYWx1ZUNvbmZpZ3Mve3Jlc291cmNlX3ZhbHVlX2NvbmZpZ30qFHJl
c291cmNlVmFsdWVDb25maWdzMhNyZXNvdXJjZVZhbHVlQ29uZmlnKlgKDVJlc291cmNlVmFs
dWUSHgoaUkVTT1VSQ0VfVkFMVUVfVU5TUEVDSUZJRUQQABIICgRISUdIEAESCgoGTUVESVVN
EAISBwoDTE9XEAMSCAoETk9ORRAEQvIBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2Vu
dGVyLnYyQhhSZXNvdXJjZVZhbHVlQ29uZmlnUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9n
by9zZWN1cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVy
cGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50ZXIuVjLKAh5Hb29nbGVcQ2xvdWRcU2Vj
dXJpdHlDZW50ZXJcVjLqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjJKiiIK
BhIEDgB9AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANwoJCgIDAxIDFQApCggKAQgSAxcAOwoJ
CgIIJRIDFwA7CggKAQgSAxgAYQoJCgIICxIDGABhCggKAQgSAxkAIgoJCgIIChIDGQAiCggK
AQgSAxoAOQoJCgIICBIDGgA5CggKAQgSAxsAOwoJCgIIARIDGwA7CggKAQgSAxwAOwoJCgII
KRIDHAA7CggKAQgSAx0AOgoJCgIILRIDHQA6CpgBCgIEABIEIQBrARqLASBBIHJlc291cmNl
IHZhbHVlIGNvbmZpZ3VyYXRpb24gKFJWQykgaXMgYSBtYXBwaW5nIGNvbmZpZ3VyYXRpb24g
b2YgdXNlcidzCiByZXNvdXJjZXMgdG8gcmVzb3VyY2UgdmFsdWVzLiBVc2VkIGluIEF0dGFj
ayBwYXRoIHNpbXVsYXRpb25zLgoKCgoDBAABEgMhCBsKCwoDBAAHEgQiAigECg0KBQQAB50I
EgQiAigECuIBCgQEAAMAEgQtAjUDGtMBIFJlc291cmNlIHZhbHVlIG1hcHBpbmcgZm9yIFNl
bnNpdGl2ZSBEYXRhIFByb3RlY3Rpb24gZmluZGluZ3MKIElmIGFueSBvZiB0aGVzZSBtYXBw
aW5ncyBoYXZlIGEgcmVzb3VyY2UgdmFsdWUgdGhhdCBpcyBub3QgdW5zcGVjaWZpZWQsCiB0
aGUgcmVzb3VyY2VfdmFsdWUgZmllbGQgd2lsbCBiZSBpZ25vcmVkIHdoZW4gcmVhZGluZyB0
aGlzIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAMAARIDLQooCmAKBgQAAwACABIDMAQvGlEgUmVz
b3VyY2UgdmFsdWUgbWFwcGluZyBmb3IgaGlnaC1zZW5zaXRpdml0eSBTZW5zaXRpdmUgRGF0
YSBQcm90ZWN0aW9uCiBmaW5kaW5ncwoKDgoHBAADAAIABhIDMAQRCg4KBwQAAwACAAESAzAS
KgoOCgcEAAMAAgADEgMwLS4KYgoGBAADAAIBEgM0BDEaUyBSZXNvdXJjZSB2YWx1ZSBtYXBw
aW5nIGZvciBtZWRpdW0tc2Vuc2l0aXZpdHkgU2Vuc2l0aXZlIERhdGEgUHJvdGVjdGlvbgog
ZmluZGluZ3MKCg4KBwQAAwACAQYSAzQEEQoOCgcEAAMAAgEBEgM0EiwKDgoHBAADAAIBAxID
NC8wCkQKBAQAAgASAzgCPRo3IElkZW50aWZpZXIuIE5hbWUgZm9yIHRoZSByZXNvdXJjZSB2
YWx1ZSBjb25maWd1cmF0aW9uCgoMCgUEAAIABRIDOAIICgwKBQQAAgABEgM4CQ0KDAoFBAAC
AAMSAzgQEQoMCgUEAAIACBIDOBI8Cg8KCAQAAgAInAgAEgM4EzsKkQEKBAQAAgESAz0CIxqD
ASBSZXNvdXJjZSB2YWx1ZSBsZXZlbCB0aGlzIGV4cHJlc3Npb24gcmVwcmVzZW50cwogT25s
eSByZXF1aXJlZCB3aGVuIHRoZXJlIGlzIG5vIFNlbnNpdGl2ZSBEYXRhIFByb3RlY3Rpb24g
bWFwcGluZyBpbiB0aGUKIHJlcXVlc3QKCgwKBQQAAgEGEgM9Ag8KDAoFBAACAQESAz0QHgoM
CgUEAAIBAxIDPSEiCqcCCgQEAAICEgNEAiEamQIgVGFnIHZhbHVlcyBjb21iaW5lZCB3aXRo
IGBBTkRgIHRvIGNoZWNrIGFnYWluc3QuCiBGb3IgR29vZ2xlIENsb3VkIHJlc291cmNlcywg
dGhleSBhcmUgdGFnIHZhbHVlIElEcyBpbiB0aGUgZm9ybSBvZgogInRhZ1ZhbHVlcy8xMjMi
LiBFeGFtcGxlOiBgWyAidGFnVmFsdWVzLzEyMyIsICJ0YWdWYWx1ZXMvNDU2IiwKICJ0YWdW
YWx1ZXMvNzg5IiBdYAogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFn
ZXIvZG9jcy90YWdzL3RhZ3MtY3JlYXRpbmctYW5kLW1hbmFnaW5nCgoMCgUEAAICBBIDRAIK
CgwKBQQAAgIFEgNECxEKDAoFBAACAgESA0QSHAoMCgUEAAICAxIDRB8gCqMCCgQEAAIDEgNK
AhsalQIgQXBwbHkgcmVzb3VyY2VfdmFsdWUgb25seSB0byByZXNvdXJjZXMgdGhhdCBtYXRj
aCByZXNvdXJjZV90eXBlLgogcmVzb3VyY2VfdHlwZSB3aWxsIGJlIGNoZWNrZWQgd2l0aCBg
QU5EYCBvZiBvdGhlciByZXNvdXJjZXMuCiBGb3IgZXhhbXBsZSwgInN0b3JhZ2UuZ29vZ2xl
YXBpcy5jb20vQnVja2V0IiB3aXRoIHJlc291cmNlX3ZhbHVlICJISUdIIgogd2lsbCBhcHBs
eSAiSElHSCIgdmFsdWUgb25seSB0byAic3RvcmFnZS5nb29nbGVhcGlzLmNvbS9CdWNrZXQi
IHJlc291cmNlcy4KCgwKBQQAAgMFEgNKAggKDAoFBAACAwESA0oJFgoMCgUEAAIDAxIDShka
CtkBCgQEAAIEEgNPAhMaywEgUHJvamVjdCBvciBmb2xkZXIgdG8gc2NvcGUgdGhpcyBjb25m
aWd1cmF0aW9uIHRvLgogRm9yIGV4YW1wbGUsICJwcm9qZWN0LzQ1NiIgd291bGQgYXBwbHkg
dGhpcyBjb25maWd1cmF0aW9uIG9ubHkgdG8gcmVzb3VyY2VzCiBpbiAicHJvamVjdC80NTYi
IHNjb3BlIGFuZCB3aWxsIGJlIGNoZWNrZWQgd2l0aCBgQU5EYCBvZiBvdGhlciByZXNvdXJj
ZXMuCgoMCgUEAAIEBRIDTwIICgwKBQQAAgQBEgNPCQ4KDAoFBAACBAMSA08REgqlAgoEBAAC
BRIDVgIzGpcCIExpc3Qgb2YgcmVzb3VyY2UgbGFiZWxzIHRvIHNlYXJjaCBmb3IsIGV2YWx1
YXRlZCB3aXRoIGBBTkRgLgogRm9yIGV4YW1wbGUsICJyZXNvdXJjZV9sYWJlbHNfc2VsZWN0
b3IiOiB7ImtleSI6ICJ2YWx1ZSIsICJlbnYiOiAicHJvZCJ9CiB3aWxsIG1hdGNoIHJlc291
cmNlcyB3aXRoIGxhYmVscyAia2V5IjogInZhbHVlIiBgQU5EYCAiZW52IjoKICJwcm9kIgog
aHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGlu
Zy1tYW5hZ2luZy1sYWJlbHMKCgwKBQQAAgUGEgNWAhUKDAoFBAACBQESA1YWLgoMCgUEAAIF
AxIDVjEyCj8KBAQAAgYSA1kCGRoyIERlc2NyaXB0aW9uIG9mIHRoZSByZXNvdXJjZSB2YWx1
ZSBjb25maWd1cmF0aW9uLgoKDAoFBAACBgUSA1kCCAoMCgUEAAIGARIDWQkUCgwKBQQAAgYD
EgNZFxgKVQoEBAACBxIEXAJdMhpHIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgdGhpcyByZXNv
dXJjZSB2YWx1ZSBjb25maWd1cmF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACBwYSA1wCGwoM
CgUEAAIHARIDXBwnCgwKBQQAAgcDEgNcKisKDAoFBAACBwgSA10GMQoPCggEAAIHCJwIABID
XQcwCloKBAQAAggSBGACYTIaTCBPdXRwdXQgb25seS4gVGltZXN0YW1wIHRoaXMgcmVzb3Vy
Y2UgdmFsdWUgY29uZmlndXJhdGlvbiB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACCAYSA2AC
GwoMCgUEAAIIARIDYBwnCgwKBQQAAggDEgNgKisKDAoFBAACCAgSA2EGMQoPCggEAAIICJwI
ABIDYQcwCjsKBAQAAgkSA2QCJBouIENsb3VkIHByb3ZpZGVyIHRoaXMgY29uZmlndXJhdGlv
biBhcHBsaWVzIHRvCgoMCgUEAAIJBhIDZAIPCgwKBQQAAgkBEgNkEB4KDAoFBAACCQMSA2Qh
IwrvAQoEBAACChIDagJIGuEBIEEgbWFwcGluZyBvZiB0aGUgc2Vuc2l0aXZpdHkgb24gU2Vu
c2l0aXZlIERhdGEgUHJvdGVjdGlvbiBmaW5kaW5nIHRvCiByZXNvdXJjZSB2YWx1ZXMuIFRo
aXMgbWFwcGluZyBjYW4gb25seSBiZSB1c2VkIGluIGNvbWJpbmF0aW9uIHdpdGggYQogcmVz
b3VyY2VfdHlwZSB0aGF0IGlzIHJlbGF0ZWQgdG8gQmlnUXVlcnksIGUuZy4KICJiaWdxdWVy
eS5nb29nbGVhcGlzLmNvbS9EYXRhc2V0Ii4KCgwKBQQAAgoGEgNqAiAKDAoFBAACCgESA2oh
QgoMCgUEAAIKAxIDakVHCi0KAgUAEgRuAH0BGiEgVmFsdWUgZW51bSB0byBtYXAgdG8gYSBy
ZXNvdXJjZQoKCgoDBQABEgNuBRIKHwoEBQACABIDcAIhGhIgVW5zcGVjaWZpYyB2YWx1ZQoK
DAoFBQACAAESA3ACHAoMCgUFAAIAAhIDcB8gCiIKBAUAAgESA3MCCxoVIEhpZ2ggcmVzb3Vy
Y2UgdmFsdWUKCgwKBQUAAgEBEgNzAgYKDAoFBQACAQISA3MJCgokCgQFAAICEgN2Ag0aFyBN
ZWRpdW0gcmVzb3VyY2UgdmFsdWUKCgwKBQUAAgIBEgN2AggKDAoFBQACAgISA3YLDAohCgQF
AAIDEgN5AgoaFCBMb3cgcmVzb3VyY2UgdmFsdWUKCgwKBQUAAgMBEgN5AgUKDAoFBQACAwIS
A3kICQo9CgQFAAIEEgN8AgsaMCBObyByZXNvdXJjZSB2YWx1ZSwgZS5nLiBpZ25vcmUgdGhl
c2UgcmVzb3VyY2VzCgoMCgUFAAIEARIDfAIGCgwKBQUAAgQCEgN8CQpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::ResourceValueConfig::ResourceValueConfig ===
    # Fields for ResourceValueConfig
    # Field: name Type: 9 ()
    # Field: resource_value Type: 14 (.google.cloud.securitycenter.v2.ResourceValue)
    # Field: tag_values Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: scope Type: 9 ()
    # Field: resource_labels_selector Type: 11 (.google.cloud.securitycenter.v2.ResourceValueConfig.ResourceLabelsSelectorEntry)
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: cloud_provider Type: 14 (.google.cloud.securitycenter.v2.CloudProvider)
    # Field: sensitive_data_protection_mapping Type: 11 (.google.cloud.securitycenter.v2.ResourceValueConfig.SensitiveDataProtectionMapping)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::ResourceValueConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/resource_value_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::ResourceValueConfig;

    my $msg = Google::Cloud::Securitycenter::V2::ResourceValueConfig::ResourceValueConfig->new({
        name => $name,
        resource_value => $resource_value,
        tag_values => $tag_values,
        resource_type => $resource_type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::ResourceValueConfig::ResourceValueConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/resource_value_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::ResourceValueConfig::ResourceValueConfig

A resource value configuration (RVC) is a mapping configuration of user's
resources to resource values. Used in Attack path simulations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name for the resource value configuration

=item * C<< $msg->resource_value() >> / C<< $msg->resource_value($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::ResourceValue>)

Resource value level this expression represents
Only required when there is no Sensitive Data Protection mapping in the
request

=item * C<< $msg->tag_values() >> / C<< $msg->tag_values($value) >>

Type: C<String>

Tag values combined with `AND` to check against.
For Google Cloud resources, they are tag value IDs in the form of
"tagValues/123". Example: `[ "tagValues/123", "tagValues/456",
"tagValues/789" ]`
https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Apply resource_value only to resources that match resource_type.
resource_type will be checked with `AND` of other resources.
For example, "storage.googleapis.com/Bucket" with resource_value "HIGH"
will apply "HIGH" value only to "storage.googleapis.com/Bucket" resources.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Project or folder to scope this configuration to.
For example, "project/456" would apply this configuration only to resources
in "project/456" scope and will be checked with `AND` of other resources.

=item * C<< $msg->resource_labels_selector() >> / C<< $msg->resource_labels_selector($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::ResourceValueConfig::ResourceValueConfig::ResourceLabelsSelectorEntry>)

List of resource labels to search for, evaluated with `AND`.
For example, "resource_labels_selector": {"key": "value", "env": "prod"}
will match resources with labels "key": "value" `AND` "env":
"prod"
https://cloud.google.com/resource-manager/docs/creating-managing-labels

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the resource value configuration.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp this resource value configuration was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp this resource value configuration was last updated.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::CloudProvider>)

Cloud provider this configuration applies to

=item * C<< $msg->sensitive_data_protection_mapping() >> / C<< $msg->sensitive_data_protection_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::ResourceValueConfig::ResourceValueConfig::SensitiveDataProtectionMapping>)

A mapping of the sensitivity on Sensitive Data Protection finding to
resource values. This mapping can only be used in combination with a
resource_type that is related to BigQuery, e.g.
"bigquery.googleapis.com/Dataset".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::ResourceValueConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
