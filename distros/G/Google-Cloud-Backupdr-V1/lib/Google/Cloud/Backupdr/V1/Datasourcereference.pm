package Google::Cloud::Backupdr::V1::Datasourcereference;

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
    eval { require Google::Cloud::Backupdr::V1::Backupvault };
    eval { require Google::Cloud::Backupdr::V1::BackupvaultCloudsql };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvZGF0YXNvdXJjZXJlZmVyZW5jZS5wcm90bxIY
Z29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGipnb29nbGUvY2xvdWQvYmFja3VwZHIv
djEvYmFja3VwdmF1bHQucHJvdG8aM2dvb2dsZS9jbG91ZC9iYWNrdXBkci92MS9iYWNrdXB2
YXVsdF9jbG91ZHNxbC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLy
BgoTRGF0YVNvdXJjZVJlZmVyZW5jZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSSwoLZGF0
YV9zb3VyY2UYAiABKAlCKuBBA/pBJAoiYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vRGF0YVNv
dXJjZVIKZGF0YVNvdXJjZRJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJ2Ch9kYXRhX3NvdXJjZV9iYWNrdXBfY29u
ZmlnX3N0YXRlGAQgASgOMisuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkJhY2t1cENvbmZp
Z1N0YXRlQgPgQQNSG2RhdGFTb3VyY2VCYWNrdXBDb25maWdTdGF0ZRI8ChhkYXRhX3NvdXJj
ZV9iYWNrdXBfY291bnQYBSABKANCA+BBA1IVZGF0YVNvdXJjZUJhY2t1cENvdW50En0KHmRh
dGFfc291cmNlX2JhY2t1cF9jb25maWdfaW5mbxgGIAEoCzI0Lmdvb2dsZS5jbG91ZC5iYWNr
dXBkci52MS5EYXRhU291cmNlQmFja3VwQ29uZmlnSW5mb0ID4EEDUhpkYXRhU291cmNlQmFj
a3VwQ29uZmlnSW5mbxJ6Ch1kYXRhX3NvdXJjZV9nY3BfcmVzb3VyY2VfaW5mbxgHIAEoCzIz
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5EYXRhU291cmNlR2NwUmVzb3VyY2VJbmZvQgPg
QQNSGWRhdGFTb3VyY2VHY3BSZXNvdXJjZUluZm8SNgoSdG90YWxfc3RvcmVkX2J5dGVzGAgg
ASgDQgPgQQNIAFIQdG90YWxTdG9yZWRCeXRlc4gBATqyAepBrgEKK2JhY2t1cGRyLmdvb2ds
ZWFwaXMuY29tL0RhdGFTb3VyY2VSZWZlcmVuY2USVHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9kYXRhU291cmNlUmVmZXJlbmNlcy97ZGF0YV9zb3VyY2VfcmVm
ZXJlbmNlfSoUZGF0YVNvdXJjZVJlZmVyZW5jZXMyE2RhdGFTb3VyY2VSZWZlcmVuY2VCFQoT
X3RvdGFsX3N0b3JlZF9ieXRlcyKAAgoaRGF0YVNvdXJjZUJhY2t1cENvbmZpZ0luZm8SawoR
bGFzdF9iYWNrdXBfc3RhdGUYASABKA4yOi5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuQmFj
a3VwQ29uZmlnSW5mby5MYXN0QmFja3VwU3RhdGVCA+BBA1IPbGFzdEJhY2t1cFN0YXRlEnUK
J2xhc3Rfc3VjY2Vzc2Z1bF9iYWNrdXBfY29uc2lzdGVuY3lfdGltZRgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IjbGFzdFN1Y2Nlc3NmdWxCYWNrdXBDb25zaXN0
ZW5jeVRpbWUisAIKGURhdGFTb3VyY2VHY3BSZXNvdXJjZUluZm8SLgoQZ2NwX3Jlc291cmNl
bmFtZRgBIAEoCUID4EEDUg9nY3BSZXNvdXJjZW5hbWUSFwoEdHlwZRgCIAEoCUID4EEDUgR0
eXBlEh8KCGxvY2F0aW9uGAMgASgJQgPgQQNSCGxvY2F0aW9uEpEBCh1jbG91ZF9zcWxfaW5z
dGFuY2VfcHJvcGVydGllcxgEIAEoCzJHLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5DbG91
ZFNxbEluc3RhbmNlRGF0YVNvdXJjZVJlZmVyZW5jZVByb3BlcnRpZXNCA+BBA0gAUhpjbG91
ZFNxbEluc3RhbmNlUHJvcGVydGllc0IVChNyZXNvdXJjZV9wcm9wZXJ0aWVzImgKHUdldERh
dGFTb3VyY2VSZWZlcmVuY2VSZXF1ZXN0EkcKBG5hbWUYASABKAlCM+BBAvpBLQorYmFja3Vw
ZHIuZ29vZ2xlYXBpcy5jb20vRGF0YVNvdXJjZVJlZmVyZW5jZVIEbmFtZSLxAQofTGlzdERh
dGFTb3VyY2VSZWZlcmVuY2VzUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLRIrYmFj
a3VwZHIuZ29vZ2xlYXBpcy5jb20vRGF0YVNvdXJjZVJlZmVyZW5jZVIGcGFyZW50EiAKCXBh
Z2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFS
CXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4KCG9yZGVyX2J5GAUg
ASgJQgPgQQFSB29yZGVyQnki0QEKIExpc3REYXRhU291cmNlUmVmZXJlbmNlc1Jlc3BvbnNl
EmMKFmRhdGFfc291cmNlX3JlZmVyZW5jZXMYASADKAsyLS5nb29nbGUuY2xvdWQuYmFja3Vw
ZHIudjEuRGF0YVNvdXJjZVJlZmVyZW5jZVIUZGF0YVNvdXJjZVJlZmVyZW5jZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJ
Ugt1bnJlYWNoYWJsZSKrAgovRmV0Y2hEYXRhU291cmNlUmVmZXJlbmNlc0ZvclJlc291cmNl
VHlwZVJlcXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0SK2JhY2t1cGRyLmdvb2dsZWFw
aXMuY29tL0RhdGFTb3VyY2VSZWZlcmVuY2VSBnBhcmVudBIoCg1yZXNvdXJjZV90eXBlGAIg
ASgJQgPgQQJSDHJlc291cmNlVHlwZRIgCglwYWdlX3NpemUYAyABKAVCA+BBAVIIcGFnZVNp
emUSIgoKcGFnZV90b2tlbhgEIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAUgASgJ
QgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgGIAEoCUID4EEBUgdvcmRlckJ5Ir8BCjBGZXRj
aERhdGFTb3VyY2VSZWZlcmVuY2VzRm9yUmVzb3VyY2VUeXBlUmVzcG9uc2USYwoWZGF0YV9z
b3VyY2VfcmVmZXJlbmNlcxgBIAMoCzItLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5EYXRh
U291cmNlUmVmZXJlbmNlUhRkYXRhU291cmNlUmVmZXJlbmNlcxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW5CyAEKHGNvbS5nb29nbGUuY2xvdWQuYmFja3VwZHIu
djFCGERhdGFTb3VyY2VSZWZlcmVuY2VQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2Jh
Y2t1cGRyL2FwaXYxL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCGEdvb2dsZS5DbG91ZC5CYWNr
dXBEUi5WMcoCGEdvb2dsZVxDbG91ZFxCYWNrdXBEUlxWMeoCG0dvb2dsZTo6Q2xvdWQ6OkJh
Y2t1cERSOjpWMUqERQoHEgUOAPgBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAIQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANAoJCgIDAxID
FQA9CgkKAgMEEgMWACkKCAoBCBIDGAA1CgkKAgglEgMYADUKCAoBCBIDGQBPCgkKAggLEgMZ
AE8KCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA5CgkKAggIEgMbADkKCAoBCBIDHAA1
CgkKAggBEgMcADUKCAoBCBIDHQA1CgkKAggpEgMdADUKCAoBCBIDHgA0CgkKAggtEgMeADQK
SgoCBAASBCEAUAEaPiBEYXRhU291cmNlUmVmZXJlbmNlIGlzIGEgcmVmZXJlbmNlIHRvIGEg
RGF0YVNvdXJjZSByZXNvdXJjZS4KCgoKAwQAARIDIQgbCgsKAwQABxIEIgInBAoNCgUEAAed
CBIEIgInBAqoAQoEBAACABIDLAI9GpoBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSBEYXRhU291cmNlUmVmZXJlbmNlLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFTb3VyY2VSZWZlcmVuY2VzL3tkYXRhX3Nv
dXJjZV9yZWZlcmVuY2V9CgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMsCQ0KDAoFBAACAAMS
AywQEQoMCgUEAAIACBIDLBI8Cg8KCAQAAgAInAgAEgMsEzsKqAEKBAQAAgESBDECNgQamQEg
T3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBEYXRhU291cmNlLgogRm9y
bWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cFZh
dWx0cy97YmFja3VwVmF1bHR9L2RhdGFTb3VyY2VzL3tkYXRhU291cmNlfQoKDAoFBAACAQUS
AzECCAoMCgUEAAIBARIDMQkUCgwKBQQAAgEDEgMxFxgKDQoFBAACAQgSBDEZNgMKDwoIBAAC
AQicCAASAzIELQoPCgcEAAIBCJ8IEgQzBDUFCk8KBAQAAgISBDkCOjIaQSBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgd2hlbiB0aGUgRGF0YVNvdXJjZVJlZmVyZW5jZSB3YXMgY3JlYXRlZC4K
CgwKBQQAAgIGEgM5AhsKDAoFBAACAgESAzkcJwoMCgUEAAICAxIDOSorCgwKBQQAAgIIEgM6
BjEKDwoIBAACAgicCAASAzoHMApOCgQEAAIDEgQ9Aj4yGkAgT3V0cHV0IG9ubHkuIFRoZSBi
YWNrdXAgY29uZmlndXJhdGlvbiBzdGF0ZSBvZiB0aGUgRGF0YVNvdXJjZS4KCgwKBQQAAgMG
EgM9AhMKDAoFBAACAwESAz0UMwoMCgUEAAIDAxIDPTY3CgwKBQQAAgMIEgM+BjEKDwoIBAAC
AwicCAASAz4HMApBCgQEAAIEEgRBAkIyGjMgT3V0cHV0IG9ubHkuIE51bWJlciBvZiBiYWNr
dXBzIGluIHRoZSBEYXRhU291cmNlLgoKDAoFBAACBAUSA0ECBwoMCgUEAAIEARIDQQggCgwK
BQQAAgQDEgNBIyQKDAoFBAACBAgSA0IGMQoPCggEAAIECJwIABIDQgcwClMKBAQAAgUSBEUC
RjIaRSBPdXRwdXQgb25seS4gSW5mb3JtYXRpb24gb2YgYmFja3VwIGNvbmZpZ3VyYXRpb24g
b24gdGhlIERhdGFTb3VyY2UuCgoMCgUEAAIFBhIDRQIcCgwKBQQAAgUBEgNFHTsKDAoFBAAC
BQMSA0U+PwoMCgUEAAIFCBIDRgYxCg8KCAQAAgUInAgAEgNGBzAKVQoEBAACBhIESQJKMhpH
IE91dHB1dCBvbmx5LiBUaGUgR0NQIHJlc291cmNlIHRoYXQgdGhlIERhdGFTb3VyY2UgaXMg
YXNzb2NpYXRlZCB3aXRoLgoKDAoFBAACBgYSA0kCGwoMCgUEAAIGARIDSRw5CgwKBQQAAgYD
EgNJPD0KDAoFBAACBggSA0oGMQoPCggEAAIGCJwIABIDSgcwCnMKBAQAAgcSBE4CTzIaZSBP
dXRwdXQgb25seS4gVG90YWwgc2l6ZSBvZiB0aGUgc3RvcmFnZSB1c2VkIGJ5IGFsbCBiYWNr
dXAgcmVzb3VyY2VzIGZvciB0aGUKIHJlZmVyZW5jZWQgZGF0YXNvdXJjZS4KCgwKBQQAAgcE
EgNOAgoKDAoFBAACBwUSA04LEAoMCgUEAAIHARIDThEjCgwKBQQAAgcDEgNOJicKDAoFBAAC
BwgSA08GMQoPCggEAAIHCJwIABIDTwcwCkQKAgQBEgRTAFsBGjggSW5mb3JtYXRpb24gb2Yg
YmFja3VwIGNvbmZpZ3VyYXRpb24gb24gdGhlIERhdGFTb3VyY2UuCgoKCgMEAQESA1MIIgpN
CgQEAQIAEgRVAlYyGj8gT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhlIGxhc3QgYmFj
a3VwIGluIHRoaXMgRGF0YVNvdXJjZQoKDAoFBAECAAYSA1UCIgoMCgUEAQIAARIDVSM0CgwK
BQQBAgADEgNVNzgKDAoFBAECAAgSA1YGMQoPCggEAQIACJwIABIDVgcwClgKBAQBAgESBFkC
WjIaSiBPdXRwdXQgb25seS4gVGltZXN0YW1wIG9mIHRoZSBsYXN0IHN1Y2Nlc3NmdWwgYmFj
a3VwIHRvIHRoaXMgRGF0YVNvdXJjZS4KCgwKBQQBAgEGEgNZAhsKDAoFBAECAQESA1kcQwoM
CgUEAQIBAxIDWUZHCgwKBQQBAgEIEgNaBjEKDwoIBAECAQicCAASA1oHMApGCgIEAhIEXgBy
ARo6IFRoZSBHQ1AgcmVzb3VyY2UgdGhhdCB0aGUgRGF0YVNvdXJjZSBpcyBhc3NvY2lhdGVk
IHdpdGguCgoKCgMEAgESA14IIQp8CgQEAgIAEgNhAkoabyBPdXRwdXQgb25seS4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIEdDUCByZXNvdXJjZS4KIEV4OiBwcm9qZWN0cy97cHJvamVj
dH0vem9uZXMve3pvbmV9L2luc3RhbmNlcy97aW5zdGFuY2V9CgoMCgUEAgIABRIDYQIICgwK
BQQCAgABEgNhCRkKDAoFBAICAAMSA2EcHQoMCgUEAgIACBIDYR5JCg8KCAQCAgAInAgAEgNh
H0gKXgoEBAICARIDZQI+GlEgT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSBHQ1AgcmVz
b3VyY2UuCiBFeDogY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZQoKDAoFBAICAQUS
A2UCCAoMCgUEAgIBARIDZQkNCgwKBQQCAgEDEgNlEBEKDAoFBAICAQgSA2USPQoPCggEAgIB
CJwIABIDZRM8CmkKBAQCAgISA2kCQhpcIE91dHB1dCBvbmx5LiBUaGUgbG9jYXRpb24gb2Yg
dGhlIEdDUCByZXNvdXJjZS4KIEV4OiA8cmVnaW9uPi88em9uZT4vImdsb2JhbCIvInVuc3Bl
Y2lmaWVkIgoKDAoFBAICAgUSA2kCCAoMCgUEAgICARIDaQkRCgwKBQQCAgIDEgNpFBUKDAoF
BAICAggSA2kWQQoPCggEAgICCJwIABIDaRdACjMKBAQCCAASBGwCcQMaJSBUaGUgcHJvcGVy
dGllcyBvZiB0aGUgR0NQIHJlc291cmNlLgoKDAoFBAIIAAESA2wIGwpGCgQEAgIDEgRuBHA0
GjggT3V0cHV0IG9ubHkuIFRoZSBwcm9wZXJ0aWVzIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFu
Y2UuCgoMCgUEAgIDBhIDbgQxCgwKBQQCAgMBEgNvCCUKDAoFBAICAwMSA28oKQoMCgUEAgID
CBIDcAgzCg8KCAQCAgMInAgAEgNwCTIKPAoCBAMSBHUAfwEaMCBSZXF1ZXN0IGZvciB0aGUg
R2V0RGF0YVNvdXJjZVJlZmVyZW5jZSBtZXRob2QuCgoKCgMEAwESA3UIJQqqAQoEBAMCABIE
eQJ+BBqbASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIERhdGFTb3VyY2VSZWZlcmVuY2Ug
dG8gcmV0cmlldmUuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vZGF0YVNvdXJjZVJlZmVyZW5jZXMve2RhdGFfc291cmNlX3JlZmVyZW5jZX0K
CgwKBQQDAgAFEgN5AggKDAoFBAMCAAESA3kJDQoMCgUEAwIAAxIDeRARCg0KBQQDAgAIEgR5
En4DCg8KCAQDAgAInAgAEgN6BCoKDwoHBAMCAAifCBIEewR9BQpACgIEBBIGggEArAEBGjIg
UmVxdWVzdCBmb3IgdGhlIExpc3REYXRhU291cmNlUmVmZXJlbmNlcyBtZXRob2QuCgoLCgME
BAESBIIBCCcKZgoEBAQCABIGhQECigEEGlYgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3Vy
Y2UgbmFtZS4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259CgoNCgUEBAIABRIEhQECCAoNCgUEBAIAARIEhQEJDwoNCgUEBAIAAxIEhQESEwoPCgUE
BAIACBIGhQEUigEDChAKCAQEAgAInAgAEgSGAQQqChEKBwQEAgAInwgSBocBBIkBBQqGAgoE
BAQCARIEkAECPxr3ASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIERhdGFTb3Vy
Y2VSZWZlcmVuY2VzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UKIG1heSByZXR1cm4gZmV3ZXIg
dGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MAogRGF0YVNvdXJj
ZVJlZmVyZW5jZXMgd2lsbCBiZSByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAw
OyB2YWx1ZXMKIGFib3ZlIDEwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwLgoKDQoFBAQCAQUS
BJABAgcKDQoFBAQCAQESBJABCBEKDQoFBAQCAQMSBJABFBUKDQoFBAQCAQgSBJABFj4KEAoI
BAQCAQicCAASBJABFz0KlAIKBAQEAgISBJgBAkEahQIgT3B0aW9uYWwuIEEgcGFnZSB0b2tl
biwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0RGF0YVNvdXJjZVJlZmVyZW5jZXNg
CiBjYWxsLiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4K
CiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBg
TGlzdERhdGFTb3VyY2VSZWZlcmVuY2VzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJv
dmlkZWQgdGhlIHBhZ2UKIHRva2VuLgoKDQoFBAQCAgUSBJgBAggKDQoFBAQCAgESBJgBCRMK
DQoFBAQCAgMSBJgBFhcKDQoFBAQCAggSBJgBGEAKEAoIBAQCAgicCAASBJgBGT8KjAMKBAQE
AgMSBKIBAj0a/QIgT3B0aW9uYWwuIEEgZmlsdGVyIGV4cHJlc3Npb24gdGhhdCBmaWx0ZXJz
IHRoZSByZXN1bHRzIGxpc3RlZCBpbiB0aGUKIHJlc3BvbnNlLiBUaGUgZXhwcmVzc2lvbiBt
dXN0IHNwZWNpZnkgdGhlIGZpZWxkIG5hbWUsIGEgY29tcGFyaXNvbgogb3BlcmF0b3IsIGFu
ZCB0aGUgdmFsdWUgdGhhdCB5b3Ugd2FudCB0byB1c2UgZm9yIGZpbHRlcmluZy4KCiBUaGUg
Zm9sbG93aW5nIGZpZWxkIGFuZCBvcGVyYXRvciBjb21iaW5hdGlvbnMgYXJlIHN1cHBvcnRl
ZDoKCiAqIGRhdGFfc291cmNlX2djcF9yZXNvdXJjZV9pbmZvLmdjcF9yZXNvdXJjZW5hbWUg
d2l0aCBgPWAsIGAhPWAKICogZGF0YV9zb3VyY2VfZ2NwX3Jlc291cmNlX2luZm8udHlwZSB3
aXRoIGA9YCwgYCE9YAoKDQoFBAQCAwUSBKIBAggKDQoFBAQCAwESBKIBCQ8KDQoFBAQCAwMS
BKIBEhMKDQoFBAQCAwgSBKIBFDwKEAoIBAQCAwicCAASBKIBFTsK6AEKBAQEAgQSBKsBAj8a
2QEgT3B0aW9uYWwuIEEgY29tbWEtc2VwYXJhdGVkIGxpc3Qgb2YgZmllbGRzIHRvIG9yZGVy
IGJ5LCBzb3J0ZWQgaW4gYXNjZW5kaW5nCiBvcmRlci4gVXNlICJkZXNjIiBhZnRlciBhIGZp
ZWxkIG5hbWUgZm9yIGRlc2NlbmRpbmcuCgogU3VwcG9ydGVkIGZpZWxkczoKCiAqIGRhdGFf
c291cmNlCiAqIGRhdGFfc291cmNlX2djcF9yZXNvdXJjZV9pbmZvLmdjcF9yZXNvdXJjZW5h
bWUKCg0KBQQEAgQFEgSrAQIICg0KBQQEAgQBEgSrAQkRCg0KBQQEAgQDEgSrARQVCg0KBQQE
AgQIEgSrARY+ChAKCAQEAgQInAgAEgSrARc9CkEKAgQFEgavAQC5AQEaMyBSZXNwb25zZSBm
b3IgdGhlIExpc3REYXRhU291cmNlUmVmZXJlbmNlcyBtZXRob2QuCgoLCgMEBQESBK8BCCgK
QwoEBAUCABIEsQECOho1IFRoZSBEYXRhU291cmNlUmVmZXJlbmNlcyBmcm9tIHRoZSBzcGVj
aWZpZWQgcGFyZW50LgoKDQoFBAUCAAQSBLEBAgoKDQoFBAUCAAYSBLEBCx4KDQoFBAUCAAES
BLEBHzUKDQoFBAUCAAMSBLEBODkKkAEKBAQFAgESBLUBAh0agQEgQSB0b2tlbiwgd2hpY2gg
Y2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Uu
CiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBh
Z2VzLgoKDQoFBAUCAQUSBLUBAggKDQoFBAUCAQESBLUBCRgKDQoFBAUCAQMSBLUBGxwKNAoE
BAUCAhIEuAECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoF
BAUCAgQSBLgBAgoKDQoFBAUCAgUSBLgBCxEKDQoFBAUCAgESBLgBEh0KDQoFBAUCAgMSBLgB
ICEKUAoCBAYSBrwBAO4BARpCIFJlcXVlc3QgZm9yIHRoZSBGZXRjaERhdGFTb3VyY2VSZWZl
cmVuY2VzRm9yUmVzb3VyY2VUeXBlIG1ldGhvZC4KCgsKAwQGARIEvAEINwpmCgQEBgIAEga/
AQLEAQQaViBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLgogRm9ybWF0OiBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCg0KBQQGAgAFEgS/AQII
Cg0KBQQGAgABEgS/AQkPCg0KBQQGAgADEgS/ARITCg8KBQQGAgAIEga/ARTEAQMKEAoIBAYC
AAicCAASBMABBCoKEQoHBAYCAAifCBIGwQEEwwEFClgKBAQGAgESBMgBAkQaSiBSZXF1aXJl
ZC4gVGhlIHR5cGUgb2YgdGhlIEdDUCByZXNvdXJjZS4KIEV4OiBzcWwuZ29vZ2xlYXBpcy5j
b20vSW5zdGFuY2UKCg0KBQQGAgEFEgTIAQIICg0KBQQGAgEBEgTIAQkWCg0KBQQGAgEDEgTI
ARkaCg0KBQQGAgEIEgTIARtDChAKCAQGAgEInAgAEgTIARxCCoYCCgQEBgICEgTOAQI/GvcB
IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgRGF0YVNvdXJjZVJlZmVyZW5jZXMg
dG8gcmV0dXJuLiBUaGUgc2VydmljZQogbWF5IHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFs
dWUuIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwCiBEYXRhU291cmNlUmVmZXJlbmNlcyB3
aWxsIGJlIHJldHVybmVkLiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDA7IHZhbHVlcwogYWJv
dmUgMTAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAuCgoNCgUEBgICBRIEzgECBwoNCgUEBgIC
ARIEzgEIEQoNCgUEBgICAxIEzgEUFQoNCgUEBgICCBIEzgEWPgoQCggEBgICCJwIABIEzgEX
PQq4AgoEBAYCAxIE1wECQRqpAiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBm
cm9tIGEgcHJldmlvdXMgY2FsbCBvZgogYEZldGNoRGF0YVNvdXJjZVJlZmVyZW5jZXNGb3JS
ZXNvdXJjZVR5cGVgLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50
IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRl
ZCB0bwogYEZldGNoRGF0YVNvdXJjZVJlZmVyZW5jZXNGb3JSZXNvdXJjZVR5cGVgIG11c3Qg
bWF0Y2gKIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEBgID
BRIE1wECCAoNCgUEBgIDARIE1wEJEwoNCgUEBgIDAxIE1wEWFwoNCgUEBgIDCBIE1wEYQAoQ
CggEBgIDCJwIABIE1wEZPwr0BAoEBAYCBBIE5gECPRrlBCBPcHRpb25hbC4gQSBmaWx0ZXIg
ZXhwcmVzc2lvbiB0aGF0IGZpbHRlcnMgdGhlIHJlc3VsdHMgZmV0Y2hlZCBpbiB0aGUKIHJl
c3BvbnNlLiBUaGUgZXhwcmVzc2lvbiBtdXN0IHNwZWNpZnkgdGhlIGZpZWxkIG5hbWUsIGEg
Y29tcGFyaXNvbgogb3BlcmF0b3IsIGFuZCB0aGUgdmFsdWUgdGhhdCB5b3Ugd2FudCB0byB1
c2UgZm9yIGZpbHRlcmluZy4gU3VwcG9ydGVkCiBmaWVsZHM6CiAqIGRhdGFfc291cmNlCiAq
IGRhdGFfc291cmNlX2djcF9yZXNvdXJjZV9pbmZvLmdjcF9yZXNvdXJjZW5hbWUKICogZGF0
YV9zb3VyY2VfYmFja3VwX2NvbmZpZ19zdGF0ZQogKiBkYXRhX3NvdXJjZV9iYWNrdXBfY291
bnQKICogZGF0YV9zb3VyY2VfYmFja3VwX2NvbmZpZ19pbmZvLmxhc3RfYmFja3VwX3N0YXRl
CiAqIGRhdGFfc291cmNlX2djcF9yZXNvdXJjZV9pbmZvLmdjcF9yZXNvdXJjZW5hbWUKICog
ZGF0YV9zb3VyY2VfZ2NwX3Jlc291cmNlX2luZm8udHlwZQogKiBkYXRhX3NvdXJjZV9nY3Bf
cmVzb3VyY2VfaW5mby5sb2NhdGlvbgogKiBkYXRhX3NvdXJjZV9nY3BfcmVzb3VyY2VfaW5m
by5jbG91ZF9zcWxfaW5zdGFuY2VfcHJvcGVydGllcy5pbnN0YW5jZV9jcmVhdGVfdGltZQoK
DQoFBAYCBAUSBOYBAggKDQoFBAYCBAESBOYBCQ8KDQoFBAYCBAMSBOYBEhMKDQoFBAYCBAgS
BOYBFDwKEAoIBAYCBAicCAASBOYBFTsKrgEKBAQGAgUSBO0BAj8anwEgT3B0aW9uYWwuIEEg
Y29tbWEtc2VwYXJhdGVkIGxpc3Qgb2YgZmllbGRzIHRvIG9yZGVyIGJ5LCBzb3J0ZWQgaW4g
YXNjZW5kaW5nCiBvcmRlci4gVXNlICJkZXNjIiBhZnRlciBhIGZpZWxkIG5hbWUgZm9yIGRl
c2NlbmRpbmcuCgogU3VwcG9ydGVkIGZpZWxkczoKICogbmFtZQoKDQoFBAYCBQUSBO0BAggK
DQoFBAYCBQESBO0BCREKDQoFBAYCBQMSBO0BFBUKDQoFBAYCBQgSBO0BFj4KEAoIBAYCBQic
CAASBO0BFz0KUQoCBAcSBvEBAPgBARpDIFJlc3BvbnNlIGZvciB0aGUgRmV0Y2hEYXRhU291
cmNlUmVmZXJlbmNlc0ZvclJlc291cmNlVHlwZSBtZXRob2QuCgoLCgMEBwESBPEBCDgKQwoE
BAcCABIE8wECOho1IFRoZSBEYXRhU291cmNlUmVmZXJlbmNlcyBmcm9tIHRoZSBzcGVjaWZp
ZWQgcGFyZW50LgoKDQoFBAcCAAQSBPMBAgoKDQoFBAcCAAYSBPMBCx4KDQoFBAcCAAESBPMB
HzUKDQoFBAcCAAMSBPMBODkKkAEKBAQHAgESBPcBAh0agQEgQSB0b2tlbiwgd2hpY2ggY2Fu
IGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJ
ZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2Vz
LgoKDQoFBAcCAQUSBPcBAggKDQoFBAcCAQESBPcBCRgKDQoFBAcCAQMSBPcBGxxiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceReference ===
    # Fields for DataSourceReference
    # Field: name Type: 9 ()
    # Field: data_source Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_source_backup_config_state Type: 14 (.google.cloud.backupdr.v1.BackupConfigState)
    # Field: data_source_backup_count Type: 3 ()
    # Field: data_source_backup_config_info Type: 11 (.google.cloud.backupdr.v1.DataSourceBackupConfigInfo)
    # Field: data_source_gcp_resource_info Type: 11 (.google.cloud.backupdr.v1.DataSourceGcpResourceInfo)
    # Field: total_stored_bytes Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceBackupConfigInfo ===
    # Fields for DataSourceBackupConfigInfo
    # Field: last_backup_state Type: 14 (.google.cloud.backupdr.v1.BackupConfigInfo.LastBackupState)
    # Field: last_successful_backup_consistency_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceGcpResourceInfo ===
    # Fields for DataSourceGcpResourceInfo
    # Field: gcp_resourcename Type: 9 ()
    # Field: type Type: 9 ()
    # Field: location Type: 9 ()
    # Field: cloud_sql_instance_properties Type: 11 (.google.cloud.backupdr.v1.CloudSqlInstanceDataSourceReferenceProperties)

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::GetDataSourceReferenceRequest ===
    # Fields for GetDataSourceReferenceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::ListDataSourceReferencesRequest ===
    # Fields for ListDataSourceReferencesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::ListDataSourceReferencesResponse ===
    # Fields for ListDataSourceReferencesResponse
    # Field: data_source_references Type: 11 (.google.cloud.backupdr.v1.DataSourceReference)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest ===
    # Fields for FetchDataSourceReferencesForResourceTypeRequest
    # Field: parent Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse ===
    # Fields for FetchDataSourceReferencesForResourceTypeResponse
    # Field: data_source_references Type: 11 (.google.cloud.backupdr.v1.DataSourceReference)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::Datasourcereference - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/datasourcereference.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::Datasourcereference;

    my $msg = Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceReference->new({
        name => $name,
        data_source => $data_source,
        create_time => $create_time,
        data_source_backup_config_state => $data_source_backup_config_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/datasourcereference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceReference

DataSourceReference is a reference to a DataSource resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the DataSourceReference.
Format:
projects/{project}/locations/{location}/dataSourceReferences/{data_source_reference}

=item * C<< $msg->data_source() >> / C<< $msg->data_source($value) >>

Type: C<String>

Output only. The resource name of the DataSource.
Format:
projects/{project}/locations/{location}/backupVaults/{backupVault}/dataSources/{dataSource}

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the DataSourceReference was created.

=item * C<< $msg->data_source_backup_config_state() >> / C<< $msg->data_source_backup_config_state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::BackupConfigState>)

Output only. The backup configuration state of the DataSource.

=item * C<< $msg->data_source_backup_count() >> / C<< $msg->data_source_backup_count($value) >>

Type: C<Int64>

Output only. Number of backups in the DataSource.

=item * C<< $msg->data_source_backup_config_info() >> / C<< $msg->data_source_backup_config_info($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceBackupConfigInfo>)

Output only. Information of backup configuration on the DataSource.

=item * C<< $msg->data_source_gcp_resource_info() >> / C<< $msg->data_source_gcp_resource_info($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceGcpResourceInfo>)

Output only. The GCP resource that the DataSource is associated with.

=item * C<< $msg->total_stored_bytes() >> / C<< $msg->total_stored_bytes($value) >>

Type: C<Int64>

Output only. Total size of the storage used by all backup resources for the
referenced datasource.

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceBackupConfigInfo

Information of backup configuration on the DataSource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_backup_state() >> / C<< $msg->last_backup_state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::BackupConfigInfo::LastBackupState>)

Output only. The status of the last backup in this DataSource

=item * C<< $msg->last_successful_backup_consistency_time() >> / C<< $msg->last_successful_backup_consistency_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the last successful backup to this DataSource.

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceGcpResourceInfo

The GCP resource that the DataSource is associated with.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcp_resourcename() >> / C<< $msg->gcp_resourcename($value) >>

Type: C<String>

Output only. The resource name of the GCP resource.
Ex: projects/{project}/zones/{zone}/instances/{instance}

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Output only. The type of the GCP resource.
Ex: compute.googleapis.com/Instance

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Output only. The location of the GCP resource.
Ex: <region>/<zone>/"global"/"unspecified"

=item * C<< $msg->cloud_sql_instance_properties() >> / C<< $msg->cloud_sql_instance_properties($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties>)

Output only. The properties of the Cloud SQL instance.

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::GetDataSourceReferenceRequest

Request for the GetDataSourceReference method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DataSourceReference to retrieve.
Format:
projects/{project}/locations/{location}/dataSourceReferences/{data_source_reference}

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::ListDataSourceReferencesRequest

Request for the ListDataSourceReferences method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of DataSourceReferences to return. The service
may return fewer than this value. If unspecified, at most 50
DataSourceReferences will be returned. The maximum value is 100; values
above 100 will be coerced to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListDataSourceReferences`
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`ListDataSourceReferences` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters the results listed in the
response. The expression must specify the field name, a comparison
operator, and the value that you want to use for filtering.

The following field and operator combinations are supported:

* data_source_gcp_resource_info.gcp_resourcename with `=`, `!=`
* data_source_gcp_resource_info.type with `=`, `!=`

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields to order by, sorted in ascending
order. Use "desc" after a field name for descending.

Supported fields:

* data_source
* data_source_gcp_resource_info.gcp_resourcename

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::ListDataSourceReferencesResponse

Response for the ListDataSourceReferences method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_source_references() >> / C<< $msg->data_source_references($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceReference>)

The DataSourceReferences from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest

Request for the FetchDataSourceReferencesForResourceType method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
Format: projects/{project}/locations/{location}

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. The type of the GCP resource.
Ex: sql.googleapis.com/Instance

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of DataSourceReferences to return. The service
may return fewer than this value. If unspecified, at most 50
DataSourceReferences will be returned. The maximum value is 100; values
above 100 will be coerced to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous call of
`FetchDataSourceReferencesForResourceType`.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`FetchDataSourceReferencesForResourceType` must match
the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters the results fetched in the
response. The expression must specify the field name, a comparison
operator, and the value that you want to use for filtering. Supported
fields:
* data_source
* data_source_gcp_resource_info.gcp_resourcename
* data_source_backup_config_state
* data_source_backup_count
* data_source_backup_config_info.last_backup_state
* data_source_gcp_resource_info.gcp_resourcename
* data_source_gcp_resource_info.type
* data_source_gcp_resource_info.location
* data_source_gcp_resource_info.cloud_sql_instance_properties.instance_create_time

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields to order by, sorted in ascending
order. Use "desc" after a field name for descending.

Supported fields:
* name

=back

=head2 Google::Cloud::Backupdr::V1::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse

Response for the FetchDataSourceReferencesForResourceType method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_source_references() >> / C<< $msg->data_source_references($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Datasourcereference::DataSourceReference>)

The DataSourceReferences from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::Datasourcereference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
