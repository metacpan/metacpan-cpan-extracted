package Google::Cloud::Networksecurity::V1::UrlList;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL3VybF9saXN0LnByb3RvEh9nb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmll
bGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLUAgoHVXJs
TGlzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
JQoLZGVzY3JpcHRpb24YBCABKAlCA+BBAVILZGVzY3JpcHRpb24SGwoGdmFsdWVzGAUgAygJ
QgPgQQJSBnZhbHVlczpo6kFlCiZuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vVXJs
TGlzdBI7cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3VybExpc3Rz
L3t1cmxfbGlzdH0ilAEKE0xpc3RVcmxMaXN0c1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQing
QQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBh
Z2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu
IqcBChRMaXN0VXJsTGlzdHNSZXNwb25zZRJFCgl1cmxfbGlzdHMYASADKAsyKC5nb29nbGUu
Y2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLlVybExpc3RSCHVybExpc3RzEiYKD25leHRfcGFn
ZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5y
ZWFjaGFibGUiVwoRR2V0VXJsTGlzdFJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZu
ZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vVXJsTGlzdFIEbmFtZSLNAQoUQ3JlYXRl
VXJsTGlzdFJlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgSJm5ldHdvcmtzZWN1cml0
eS5nb29nbGVhcGlzLmNvbS9VcmxMaXN0UgZwYXJlbnQSIwoLdXJsX2xpc3RfaWQYAiABKAlC
A+BBAlIJdXJsTGlzdElkEkgKCHVybF9saXN0GAMgASgLMiguZ29vZ2xlLmNsb3VkLm5ldHdv
cmtzZWN1cml0eS52MS5VcmxMaXN0QgPgQQJSB3VybExpc3QiogEKFFVwZGF0ZVVybExpc3RS
ZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a0ID4EEBUgp1cGRhdGVNYXNrEkgKCHVybF9saXN0GAIgASgLMiguZ29vZ2xlLmNsb3VkLm5l
dHdvcmtzZWN1cml0eS52MS5VcmxMaXN0QgPgQQJSB3VybExpc3QiWgoURGVsZXRlVXJsTGlz
dFJlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xl
YXBpcy5jb20vVXJsTGlzdFIEbmFtZULtAQojY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2Vj
dXJpdHkudjFCDFVybExpc3RQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtz
ZWN1cml0eS9hcGl2MS9uZXR3b3Jrc2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCH0dv
b2dsZS5DbG91ZC5OZXR3b3JrU2VjdXJpdHkuVjHKAh9Hb29nbGVcQ2xvdWRcTmV0d29ya1Nl
Y3VyaXR5XFYx6gIiR29vZ2xlOjpDbG91ZDo6TmV0d29ya1NlY3VyaXR5OjpWMUr3JgoHEgUO
AJoBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKgoJCgIDAxIDFQApCggKAQgSAxcAPAoJCgII
JRIDFwA8CggKAQgSAxgAZAoJCgIICxIDGABkCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgS
AxoALQoJCgIICBIDGgAtCggKAQgSAxsAPAoJCgIIARIDGwA8CggKAQgSAxwAPAoJCgIIKRID
HAA8CggKAQgSAx0AOwoJCgIILRIDHQA7CoUBCgIEABIEIQA7ARp5IFVybExpc3QgcHJvdG8g
aGVscHMgdXNlcnMgdG8gc2V0IHJldXNhYmxlLCBpbmRlcGVuZGVudGx5IG1hbmFnZWFibGUg
bGlzdHMKIG9mIGhvc3RzLCBob3N0IHBhdHRlcm5zLCBVUkxzLCBVUkwgcGF0dGVybnMuCgoK
CgMEAAESAyEIDwoLCgMEAAcSBCICJQQKDQoFBAAHnQgSBCICJQQK3wEKBAQAAgASAywCOxrR
ASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UgcHJvdmlkZWQgYnkgdGhlIHVzZXIu
CiBOYW1lIGlzIG9mIHRoZSBmb3JtCiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vdXJsTGlzdHMve3VybF9saXN0fQogdXJsX2xpc3Qgc2hvdWxkIG1hdGNoIHRo
ZQogcGF0dGVybjooXlthLXpdKFthLXowLTktXXswLDYxfVthLXowLTldKT8kKS4KCgwKBQQA
AgAFEgMsAggKDAoFBAACAAESAywJDQoMCgUEAAIAAxIDLBARCgwKBQQAAgAIEgMsEjoKDwoI
BAACAAicCAASAywTOQpHCgQEAAIBEgQvAjAyGjkgT3V0cHV0IG9ubHkuIFRpbWUgd2hlbiB0
aGUgc2VjdXJpdHkgcG9saWN5IHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAy8CGwoMCgUEAAIB
ARIDLxwnCgwKBQQAAgEDEgMvKisKDAoFBAACAQgSAzAGMQoPCggEAAIBCJwIABIDMAcwCkcK
BAQAAgISBDMCNDIaOSBPdXRwdXQgb25seS4gVGltZSB3aGVuIHRoZSBzZWN1cml0eSBwb2xp
Y3kgd2FzIHVwZGF0ZWQuCgoMCgUEAAICBhIDMwIbCgwKBQQAAgIBEgMzHCcKDAoFBAACAgMS
AzMqKwoMCgUEAAICCBIDNAYxCg8KCAQAAgIInAgAEgM0BzAKPwoEBAACAxIDNwJCGjIgT3B0
aW9uYWwuIEZyZWUtdGV4dCBkZXNjcmlwdGlvbiBvZiB0aGUgcmVzb3VyY2UuCgoMCgUEAAID
BRIDNwIICgwKBQQAAgMBEgM3CRQKDAoFBAACAwMSAzcXGAoMCgUEAAIDCBIDNxlBCg8KCAQA
AgMInAgAEgM3GkAKKAoEBAACBBIDOgJGGhsgUmVxdWlyZWQuIEZRRE5zIGFuZCBVUkxzLgoK
DAoFBAACBAQSAzoCCgoMCgUEAAIEBRIDOgsRCgwKBQQAAgQBEgM6EhgKDAoFBAACBAMSAzob
HAoMCgUEAAIECBIDOh1FCg8KCAQAAgQInAgAEgM6HkQKNQoCBAESBD4AUQEaKSBSZXF1ZXN0
IHVzZWQgYnkgdGhlIExpc3RVcmxMaXN0IG1ldGhvZC4KCgoKAwQBARIDPggbCqIBCgQEAQIA
EgRCAkcEGpMBIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3aGlj
aCB0aGUgVXJsTGlzdHMgc2hvdWxkCiBiZSBsaXN0ZWQsIHNwZWNpZmllZCBpbiB0aGUgZm9y
bWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCgwKBQQB
AgAFEgNCAggKDAoFBAECAAESA0IJDwoMCgUEAQIAAxIDQhITCg0KBQQBAgAIEgRCFEcDCg8K
CAQBAgAInAgAEgNDBCoKDwoHBAECAAifCBIERARGBQo9CgQEAQIBEgNKAhYaMCBNYXhpbXVt
IG51bWJlciBvZiBVcmxMaXN0cyB0byByZXR1cm4gcGVyIGNhbGwuCgoMCgUEAQIBBRIDSgIH
CgwKBQQBAgEBEgNKCBEKDAoFBAECAQMSA0oUFQrHAQoEBAECAhIDUAIYGrkBIFRoZSB2YWx1
ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBgTGlzdFVybExpc3RzUmVzcG9uc2VgCiBJbmRpY2F0
ZXMgdGhhdCB0aGlzIGlzIGEgY29udGludWF0aW9uIG9mIGEgcHJpb3IKIGBMaXN0VXJsTGlz
dHNgIGNhbGwsIGFuZCB0aGF0IHRoZSBzeXN0ZW0KIHNob3VsZCByZXR1cm4gdGhlIG5leHQg
cGFnZSBvZiBkYXRhLgoKDAoFBAECAgUSA1ACCAoMCgUEAQICARIDUAkTCgwKBQQBAgIDEgNQ
FhcKOwoCBAISBFQAXwEaLyBSZXNwb25zZSByZXR1cm5lZCBieSB0aGUgTGlzdFVybExpc3Rz
IG1ldGhvZC4KCgoKAwQCARIDVAgcCikKBAQCAgASA1YCIRocIExpc3Qgb2YgVXJsTGlzdCBy
ZXNvdXJjZXMuCgoMCgUEAgIABBIDVgIKCgwKBQQCAgAGEgNWCxIKDAoFBAICAAESA1YTHAoM
CgUEAgIAAxIDVh8gCugBCgQEAgIBEgNbAh0a2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSBy
ZXN1bHRzIHRoYW4gdGhvc2UgYXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIGBu
ZXh0X3BhZ2VfdG9rZW5gIGlzIGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJl
c3VsdHMsIGNhbGwgdGhpcwogbWV0aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBgbmV4
dF9wYWdlX3Rva2VuYCBhcyBgcGFnZV90b2tlbmAuCgoMCgUEAgIBBRIDWwIICgwKBQQCAgEB
EgNbCRgKDAoFBAICAQMSA1sbHAozCgQEAgICEgNeAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3Vs
ZCBub3QgYmUgcmVhY2hlZC4KCgwKBQQCAgIEEgNeAgoKDAoFBAICAgUSA14LEQoMCgUEAgIC
ARIDXhIdCgwKBQQCAgIDEgNeICEKNAoCBAMSBGIAawEaKCBSZXF1ZXN0IHVzZWQgYnkgdGhl
IEdldFVybExpc3QgbWV0aG9kLgoKCgoDBAMBEgNiCBkKfAoEBAMCABIEZQJqBBpuIFJlcXVp
cmVkLiBBIG5hbWUgb2YgdGhlIFVybExpc3QgdG8gZ2V0LiBNdXN0IGJlIGluIHRoZSBmb3Jt
YXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy97bG9jYXRpb259L3VybExpc3RzLypgLgoKDAoF
BAMCAAUSA2UCCAoMCgUEAwIAARIDZQkNCgwKBQQDAgADEgNlEBEKDQoFBAMCAAgSBGUSagMK
DwoIBAMCAAicCAASA2YEKgoPCgcEAwIACJ8IEgRnBGkFCjcKAgQEEgRuAH8BGisgUmVxdWVz
dCB1c2VkIGJ5IHRoZSBDcmVhdGVVcmxMaXN0IG1ldGhvZC4KCgoKAwQEARIDbggcCncKBAQE
AgASBHECdgQaaSBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBvZiB0aGUgVXJsTGlz
dC4gTXVzdCBiZSBpbgogdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMve2xvY2F0
aW9ufWAuCgoMCgUEBAIABRIDcQIICgwKBQQEAgABEgNxCQ8KDAoFBAQCAAMSA3ESEwoNCgUE
BAIACBIEcRR2AwoPCggEBAIACJwIABIDcgQqCg8KBwQEAgAInwgSBHMEdQUK6QEKBAQEAgES
A3sCQhrbASBSZXF1aXJlZC4gU2hvcnQgbmFtZSBvZiB0aGUgVXJsTGlzdCByZXNvdXJjZSB0
byBiZSBjcmVhdGVkLiBUaGlzIHZhbHVlCiBzaG91bGQgYmUgMS02MyBjaGFyYWN0ZXJzIGxv
bmcsIGNvbnRhaW5pbmcgb25seSBsZXR0ZXJzLCBudW1iZXJzLCBoeXBoZW5zLAogYW5kIHVu
ZGVyc2NvcmVzLCBhbmQgc2hvdWxkIG5vdCBzdGFydCB3aXRoIGEgbnVtYmVyLiBFLmcuICJ1
cmxfbGlzdCIuCgoMCgUEBAIBBRIDewIICgwKBQQEAgEBEgN7CRQKDAoFBAQCAQMSA3sXGAoM
CgUEBAIBCBIDexlBCg8KCAQEAgEInAgAEgN7GkAKOAoEBAQCAhIDfgJAGisgUmVxdWlyZWQu
IFVybExpc3QgcmVzb3VyY2UgdG8gYmUgY3JlYXRlZC4KCgwKBQQEAgIGEgN+AgkKDAoFBAQC
AgESA34KEgoMCgUEBAICAxIDfhUWCgwKBQQEAgIIEgN+Fz8KDwoIBAQCAgicCAASA34YPgo1
CgIEBRIGggEAjgEBGicgUmVxdWVzdCB1c2VkIGJ5IFVwZGF0ZVVybExpc3QgbWV0aG9kLgoK
CwoDBAUBEgSCAQgcCtsCCgQEBQIAEgaJAQKKAS8aygIgT3B0aW9uYWwuIEZpZWxkIG1hc2sg
aXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4gdGhl
CiBVcmxMaXN0IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuICBUaGUgZmllbGRzCiBzcGVjaWZp
ZWQgaW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5v
dAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0
IGlzIGluIHRoZQogbWFzay4gSWYgdGhlIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sg
dGhlbiBhbGwgZmllbGRzIHdpbGwgYmUKIG92ZXJ3cml0dGVuLgoKDQoFBAUCAAYSBIkBAhsK
DQoFBAUCAAESBIkBHCcKDQoFBAUCAAMSBIkBKisKDQoFBAUCAAgSBIoBBi4KEAoIBAUCAAic
CAASBIoBBy0KMwoEBAUCARIEjQECQBolIFJlcXVpcmVkLiBVcGRhdGVkIFVybExpc3QgcmVz
b3VyY2UuCgoNCgUEBQIBBhIEjQECCQoNCgUEBQIBARIEjQEKEgoNCgUEBQIBAxIEjQEVFgoN
CgUEBQIBCBIEjQEXPwoQCggEBQIBCJwIABIEjQEYPgo5CgIEBhIGkQEAmgEBGisgUmVxdWVz
dCB1c2VkIGJ5IHRoZSBEZWxldGVVcmxMaXN0IG1ldGhvZC4KCgsKAwQGARIEkQEIHAqBAQoE
BAYCABIGlAECmQEEGnEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgVXJsTGlzdCB0byBkZWxl
dGUuIE11c3QgYmUgaW4KIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zL3tsb2Nh
dGlvbn0vdXJsTGlzdHMvKmAuCgoNCgUEBgIABRIElAECCAoNCgUEBgIAARIElAEJDQoNCgUE
BgIAAxIElAEQEQoPCgUEBgIACBIGlAESmQEDChAKCAQGAgAInAgAEgSVAQQqChEKBwQGAgAI
nwgSBpYBBJgBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::UrlList::UrlList ===
    # Fields for UrlList
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsRequest ===
    # Fields for ListUrlListsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsResponse ===
    # Fields for ListUrlListsResponse
    # Field: url_lists Type: 11 (.google.cloud.networksecurity.v1.UrlList)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::UrlList::GetUrlListRequest ===
    # Fields for GetUrlListRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::UrlList::CreateUrlListRequest ===
    # Fields for CreateUrlListRequest
    # Field: parent Type: 9 ()
    # Field: url_list_id Type: 9 ()
    # Field: url_list Type: 11 (.google.cloud.networksecurity.v1.UrlList)

# === Message: Google::Cloud::Networksecurity::V1::UrlList::UpdateUrlListRequest ===
    # Fields for UpdateUrlListRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: url_list Type: 11 (.google.cloud.networksecurity.v1.UrlList)

# === Message: Google::Cloud::Networksecurity::V1::UrlList::DeleteUrlListRequest ===
    # Fields for DeleteUrlListRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1::UrlList - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1/url_list.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::UrlList;

    my $msg = Google::Cloud::Networksecurity::V1::UrlList::UrlList->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1::UrlList::UrlList->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1/url_list.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1::UrlList::UrlList

UrlList proto helps users to set reusable, independently manageable lists
of hosts, host patterns, URLs, URL patterns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource provided by the user.
Name is of the form
projects/{project}/locations/{location}/urlLists/{url_list}
url_list should match the
pattern:(^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the security policy was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the security policy was updated.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. FQDNs and URLs.

=back

=head2 Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsRequest

Request used by the ListUrlList method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the UrlLists should
be listed, specified in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of UrlLists to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListUrlListsResponse`
Indicates that this is a continuation of a prior
`ListUrlLists` call, and that the system
should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsResponse

Response returned by the ListUrlLists method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url_lists() >> / C<< $msg->url_lists($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::UrlList::UrlList>)

List of UrlList resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Networksecurity::V1::UrlList::GetUrlListRequest

Request used by the GetUrlList method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the UrlList to get. Must be in the format
`projects/*/locations/{location}/urlLists/*`.

=back

=head2 Google::Cloud::Networksecurity::V1::UrlList::CreateUrlListRequest

Request used by the CreateUrlList method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the UrlList. Must be in
the format `projects/*/locations/{location}`.

=item * C<< $msg->url_list_id() >> / C<< $msg->url_list_id($value) >>

Type: C<String>

Required. Short name of the UrlList resource to be created. This value
should be 1-63 characters long, containing only letters, numbers, hyphens,
and underscores, and should not start with a number. E.g. "url_list".

=item * C<< $msg->url_list() >> / C<< $msg->url_list($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::UrlList::UrlList>)

Required. UrlList resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1::UrlList::UpdateUrlListRequest

Request used by UpdateUrlList method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
UrlList resource by the update.  The fields
specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the
mask. If the user does not provide a mask then all fields will be
overwritten.

=item * C<< $msg->url_list() >> / C<< $msg->url_list($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::UrlList::UrlList>)

Required. Updated UrlList resource.

=back

=head2 Google::Cloud::Networksecurity::V1::UrlList::DeleteUrlListRequest

Request used by the DeleteUrlList method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the UrlList to delete. Must be in
the format `projects/*/locations/{location}/urlLists/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1::UrlList::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
