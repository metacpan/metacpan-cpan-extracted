package Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy;

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
    eval { require Google::Cloud::Backupdr::V1::Autoprotectionpolicy };
    eval { require Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYXBwbGllZGF1dG9wcm90ZWN0aW9ucG9saWN5
LnByb3RvEhhnb29nbGUuY2xvdWQuYmFja3VwZHIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aM2dvb2dsZS9jbG91ZC9i
YWNrdXBkci92MS9hdXRvcHJvdGVjdGlvbnBvbGljeS5wcm90bxo6Z29vZ2xlL2Nsb3VkL2Jh
Y2t1cGRyL3YxL2F1dG9wcm90ZWN0aW9ucG9saWN5YmluZGluZy5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byLHBwobQXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWN5
EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJiCg5zb3VyY2VfYmluZGluZxgCIAEoCUI74EED
+kE1CjNiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9BdXRvUHJvdGVjdGlvblBvbGljeUJpbmRp
bmdSDXNvdXJjZUJpbmRpbmcSQwoIY3JpdGVyaWEYAyABKAsyIi5nb29nbGUuY2xvdWQuYmFj
a3VwZHIudjEuQ3JpdGVyaWFCA+BBA1IIY3JpdGVyaWESXwoTYmFja3VwX3BsYW5fZGV0YWls
cxgEIAMoCzIqLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5CYWNrdXBQbGFuRGV0YWlsQgPg
QQNSEWJhY2t1cFBsYW5EZXRhaWxzEkAKC3VwZGF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkAKC2NyZWF0ZV90aW1lGAYgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEnUKGmJpbmRp
bmdfZXZhbHVhdGlvbl9zdW1tYXJ5GAcgASgLMjIuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYx
LkJpbmRpbmdFdmFsdWF0aW9uU3VtbWFyeUID4EEDUhhiaW5kaW5nRXZhbHVhdGlvblN1bW1h
cnkSWAoGc3RhdHVzGAggASgOMjsuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLkFwcGxpZWRB
dXRvUHJvdGVjdGlvblBvbGljeS5TdGF0ZUID4EEDUgZzdGF0dXMiUAoFU3RhdGUSFQoRU1RB
VEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEhYKEkRFTEVUSU9O
X0lOSVRJQVRFRBADOt0B6kHZAQozYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXBwbGllZEF1
dG9Qcm90ZWN0aW9uUG9saWN5EmZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vYXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWNpZXMve2FwcGxpZWRfYXV0b19wcm90
ZWN0aW9uX3BvbGljeX0qHWFwcGxpZWRBdXRvUHJvdGVjdGlvblBvbGljaWVzMhthcHBsaWVk
QXV0b1Byb3RlY3Rpb25Qb2xpY3ki8AEKKExpc3RBcHBsaWVkQXV0b1Byb3RlY3Rpb25Qb2xp
Y2llc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVh
cGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdl
U2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCAB
KAlCA+BBAVIGZmlsdGVyEh4KCG9yZGVyX2J5GAUgASgJQgPgQQFSB29yZGVyQnki+gEKKUxp
c3RBcHBsaWVkQXV0b1Byb3RlY3Rpb25Qb2xpY2llc1Jlc3BvbnNlEn4KIGFwcGxpZWRfYXV0
b19wcm90ZWN0aW9uX3BvbGljaWVzGAEgAygLMjUuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYx
LkFwcGxpZWRBdXRvUHJvdGVjdGlvblBvbGljeVIdYXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9s
aWNpZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiUKC3VucmVh
Y2hhYmxlGAMgAygJQgPgQQZSC3VucmVhY2hhYmxlQtABChxjb20uZ29vZ2xlLmNsb3VkLmJh
Y2t1cGRyLnYxQiBBcHBsaWVkQXV0b1Byb3RlY3Rpb25Qb2xpY3lQcm90b1ABWjhjbG91ZC5n
b29nbGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCGEdv
b2dsZS5DbG91ZC5CYWNrdXBEUi5WMcoCGEdvb2dsZVxDbG91ZFxCYWNrdXBEUlxWMeoCG0dv
b2dsZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMUrOJgoHEgUOAIwBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQAPQoJCgIDAxIDFQBECgkKAgMEEgMWACkKCAoBCBIDGAA1CgkKAgglEgMYADUKCAoB
CBIDGQBPCgkKAggLEgMZAE8KCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwBBCgkKAggI
EgMbAEEKCAoBCBIDHAA1CgkKAggBEgMcADUKCAoBCBIDHQA1CgkKAggpEgMdADUKCAoBCBID
HgA0CgkKAggtEgMeADQKqgEKAgQAEgQjAGIBGp0BIEFwcGxpZWRBdXRvUHJvdGVjdGlvblBv
bGljeSBpcyBhIHJlYWQtb25seSB2aWV3IG9mIEF1dG9Qcm90ZWN0aW9uUG9saWN5CiBhbmQg
QXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nIHJlc291cmNlcyB0aGF0IGFwcGx5IHRvIGEg
Z2l2ZW4gd29ya2xvYWQKIHByb2plY3QuCgoKCgMEAAESAyMIIwoLCgMEAAcSBCQCKQQKDQoF
BAAHnQgSBCQCKQQKWgoEBAAEABIELAI4AxpMIFJlcHJlc2VudHMgdGhlIHZhcmlvdXMgc3Rh
dGVzIGFuIGFwcGxpZWQgYXV0byBwcm90ZWN0aW9uIHBvbGljeSBjYW4gYmUgaW4uCgoMCgUE
AAQAARIDLAcMCigKBgQABAACABIDLgQaGhkgU3RhdGUgaXMgbm90IHNwZWNpZmllZC4KCg4K
BwQABAACAAESAy4EFQoOCgcEAAQAAgACEgMuGBkKPwoGBAAEAAIBEgMxBBEaMCBUaGUgcG9s
aWN5IGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIGFwcGxpZWQuCgoOCgcEAAQAAgEBEgMx
BAwKDgoHBAAEAAIBAhIDMQ8QCjsKBgQABAACAhIDNAQPGiwgVGhlIHBvbGljeSBoYXMgYmVl
biBhcHBsaWVkIGFuZCBpcyBhY3RpdmUuCgoOCgcEAAQAAgIBEgM0BAoKDgoHBAAEAAICAhID
NA0OCj8KBgQABAACAxIDNwQbGjAgVGhlIHBvbGljeSBpcyBpbiB0aGUgcHJvY2VzcyBvZiBi
ZWluZyByZW1vdmVkLgoKDgoHBAAEAAIDARIDNwQWCg4KBwQABAACAwISAzcZGgqaAQoEBAAC
ABIDPQI9GowBIElkZW50aWZpZXIuIENhbm9uaWNhbCByZXNvdXJjZSBuYW1lLgogRm9ybWF0
OgogcHJvamVjdHMve3dvcmtsb2FkLXByb2plY3QtbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9hcHBsaWVkQXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97aWR9LgoKDAoFBAACAAUSAz0C
CAoMCgUEAAIAARIDPQkNCgwKBQQAAgADEgM9EBEKDAoFBAACAAgSAz0SPAoPCggEAAIACJwI
ABIDPRM7CqYCCgQEAAIBEgRCAkcEGpcCIE91dHB1dCBvbmx5LiBUaGUgZnVsbCByZXNvdXJj
ZSBuYW1lIG9mIHRoZSBBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmcgdGhhdAogYXBwbGll
cyB0aGUgc291cmNlIHBvbGljeSB0byBhIHNjb3BlIGluY2x1ZGluZyB0aGlzIHdvcmtsb2Fk
IHByb2plY3QuIGUuZy4sCiBwcm9qZWN0cy97YWRtaW4tcHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vYXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97cG9saWN5X2lkfS9hdXRvUHJvdGVj
dGlvblBvbGljeUJpbmRpbmdzL3tiaW5kaW5nX2lkfS4KCgwKBQQAAgEFEgNCAggKDAoFBAAC
AQESA0IJFwoMCgUEAAIBAxIDQhobCg0KBQQAAgEIEgRCHEcDCg8KCAQAAgEInAgAEgNDBC0K
DwoHBAACAQifCBIERARGBQp5CgQEAAICEgNLAkQabCBPdXRwdXQgb25seS4gVGhlIGNyaXRl
cmlhIHJlc291cmNlcyBtdXN0IG1lZXQgZm9yIHRoaXMgcnVsZSB0byBhcHBseS4gRnJvbQog
QXV0b1Byb3RlY3Rpb25Qb2xpY3kuY3JpdGVyaWEuCgoMCgUEAAICBhIDSwIKCgwKBQQAAgIB
EgNLCxMKDAoFBAACAgMSA0sWFwoMCgUEAAICCBIDSxhDCg8KCAQAAgIInAgAEgNLGUIKzgEK
BAQAAgMSBFACUTIavwEgT3V0cHV0IG9ubHkuIFRoZSBzZXQgb2YgYmFja3VwIHBsYW4gY29u
ZmlndXJhdGlvbnMsIG1pcnJvcmluZyB0aGUKIGJhY2t1cF9wbGFuX2RldGFpbHMgZnJvbSB0
aGUgc291cmNlIEF1dG9Qcm90ZWN0aW9uUG9saWN5LiBFYWNoIGVsZW1lbnQKIHNwZWNpZmll
cyBhIGJhY2t1cCBwbGFuIGZvciBhIGdpdmVuIHJlc291cmNlIHR5cGUuCgoMCgUEAAIDBBID
UAIKCgwKBQQAAgMGEgNQCxsKDAoFBAACAwESA1AcLwoMCgUEAAIDAxIDUDIzCgwKBQQAAgMI
EgNRBjEKDwoIBAACAwicCAASA1EHMApVCgQEAAIEEgRUAlUyGkcgT3V0cHV0IG9ubHkuIFRp
bWVzdGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIGJpbmRpbmcgd2FzIGxhc3QgbW9kaWZpZWQu
CgoMCgUEAAIEBhIDVAIbCgwKBQQAAgQBEgNUHCcKDAoFBAACBAMSA1QqKwoMCgUEAAIECBID
VQYxCg8KCAQAAgQInAgAEgNVBzAKVAoEBAACBRIEWAJZMhpGIE91dHB1dCBvbmx5LiBUaW1l
c3RhbXAgaW5kaWNhdGluZyB3aGVuIHRoZSBiaW5kaW5nIHdhcyBsYXN0IGNyZWF0ZWQuCgoM
CgUEAAIFBhIDWAIbCgwKBQQAAgUBEgNYHCcKDAoFBAACBQMSA1gqKwoMCgUEAAIFCBIDWQYx
Cg8KCAQAAgUInAgAEgNZBzAKXgoEBAACBhIEXQJeMhpQIE91dHB1dCBvbmx5LiBUaGUgc3Vt
bWFyeSBvZiB0aGUgbGFzdCBwb2xpY3kgYXBwbGljYXRpb24gd2hlbiB0aGUgam9iIGhhcwog
cnVuLgoKDAoFBAACBgYSA10CGgoMCgUEAAIGARIDXRs1CgwKBQQAAgYDEgNdODkKDAoFBAAC
BggSA14GMQoPCggEAAIGCJwIABIDXgcwCk0KBAQAAgcSA2ECPxpAIE91dHB1dCBvbmx5LiBU
aGUgc3RhdHVzIG9mIHRoZSBhcHBsaWVkIGF1dG8gcHJvdGVjdGlvbiBwb2xpY3kuCgoMCgUE
AAIHBhIDYQIHCgwKBQQAAgcBEgNhCA4KDAoFBAACBwMSA2EREgoMCgUEAAIHCBIDYRM+Cg8K
CAQAAgcInAgAEgNhFD0KSAoCBAESBGUAfgEaPCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGxpc3Rp
bmcgQXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWNpZXMuCgoKCgMEAQESA2UIMAqYAQoEBAEC
ABIEaAJtBBqJASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZvciB3aGlj
aCB0byByZXRyaWV2ZSB0aGUgbGlzdCBvZgogYXBwbGllZCBwb2xpY2llcy4gRm9ybWF0OiBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQBAgAFEgNoAggK
DAoFBAECAAESA2gJDwoMCgUEAQIAAxIDaBITCg0KBQQBAgAIEgRoFG0DCg8KCAQBAgAInAgA
EgNpBCoKDwoHBAECAAifCBIEagRsBQrpAQoEBAECARIDcgI/GtsBIE9wdGlvbmFsLiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgYXBwbGllZCBwb2xpY2llcyB0byByZXR1cm4gaW4gYSBzaW5n
bGUKIHBhZ2UuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAw
IHdpbGwgYmUgY29lcmNlZCB0bwogMTAwMC4gSWYgdW5zcGVjaWZpZWQgb3Igc2V0IHRvIDAs
IGEgZGVmYXVsdCBwYWdlIHNpemUgb2YgNTAwIHdpbGwgYmUgdXNlZC4KCgwKBQQBAgEFEgNy
AgcKDAoFBAECAQESA3IIEQoMCgUEAQIBAxIDchQVCgwKBQQBAgEIEgNyFj4KDwoIBAECAQic
CAASA3IXPQpqCgQEAQICEgN2AkEaXSBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZl
ZCBmcm9tIGEgcHJldmlvdXMKIGBMaXN0QXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWNpZXNg
IGNhbGwuCgoMCgUEAQICBRIDdgIICgwKBQQBAgIBEgN2CRMKDAoFBAECAgMSA3YWFwoMCgUE
AQICCBIDdhhACg8KCAQBAgIInAgAEgN2GT8KXAoEBAECAxIDegI9Gk8gT3B0aW9uYWwuIEEg
ZmlsdGVyIGV4cHJlc3Npb24gdGhhdCBmaWx0ZXJzIHJlc291cmNlcyBsaXN0ZWQgaW4gdGhl
CiByZXNwb25zZS4KCgwKBQQBAgMFEgN6AggKDAoFBAECAwESA3oJDwoMCgUEAQIDAxIDehIT
CgwKBQQBAgMIEgN6FDwKDwoIBAECAwicCAASA3oVOwpOCgQEAQIEEgN9Aj8aQSBPcHRpb25h
bC4gQW4gZXhwcmVzc2lvbiB0aGF0IHNvcnRzIHRoZSByZXN1bHRzIGluIHRoZSByZXNwb25z
ZS4KCgwKBQQBAgQFEgN9AggKDAoFBAECBAESA30JEQoMCgUEAQIEAxIDfRQVCgwKBQQBAgQI
EgN9Fj4KDwoIBAECBAicCAASA30XPQpHCgIEAhIGgQEAjAEBGjkgUmVzcG9uc2UgbWVzc2Fn
ZSBmb3IgTGlzdEFwcGxpZWRBdXRvUHJvdGVjdGlvblBvbGljaWVzLgoKCwoDBAIBEgSBAQgx
CkoKBAQCAgASBIMBAkwaPCBBIGxpc3Qgb2YgdGhlIEFwcGxpZWRBdXRvUHJvdGVjdGlvblBv
bGljeSByZXNvdXJjZXMgZm91bmQuCgoNCgUEAgIABBIEgwECCgoNCgUEAgIABhIEgwELJgoN
CgUEAgIAARIEgwEnRwoNCgUEAgIAAxIEgwFKSwpTCgQEAgIBEgSGAQIdGkUgQSB0b2tlbiB0
aGF0IGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBw
YWdlLgoKDQoFBAICAQUSBIYBAggKDQoFBAICAQESBIYBCRgKDQoFBAICAQMSBIYBGxwKfwoE
BAICAhIGigECiwE1Gm8gVW5vcmRlcmVkIGxpc3QuIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5v
dCBiZSByZWFjaGVkLiBGb3IgZXhhbXBsZSwKICJwcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0
aW9ucy91cy1lYXN0MSJdLgoKDQoFBAICAgQSBIoBAgoKDQoFBAICAgUSBIoBCxEKDQoFBAIC
AgESBIoBEh0KDQoFBAICAgMSBIoBICEKDQoFBAICAggSBIsBBjQKEAoIBAICAgicCAASBIsB
BzNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy ===
    # Fields for AppliedAutoProtectionPolicy
    # Field: name Type: 9 ()
    # Field: source_binding Type: 9 ()
    # Field: criteria Type: 11 (.google.cloud.backupdr.v1.Criteria)
    # Field: backup_plan_details Type: 11 (.google.cloud.backupdr.v1.BackupPlanDetail)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: binding_evaluation_summary Type: 11 (.google.cloud.backupdr.v1.BindingEvaluationSummary)
    # Field: status Type: 14 (.google.cloud.backupdr.v1.AppliedAutoProtectionPolicy.State)

# Enum: AppliedAutoProtectionPolicy::State
our $AppliedAutoProtectionPolicy_STATE_UNSPECIFIED = 0;
our $AppliedAutoProtectionPolicy_CREATING = 1;
our $AppliedAutoProtectionPolicy_ACTIVE = 2;
our $AppliedAutoProtectionPolicy_DELETION_INITIATED = 3;

# === Message: Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest ===
    # Fields for ListAppliedAutoProtectionPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse ===
    # Fields for ListAppliedAutoProtectionPoliciesResponse
    # Field: applied_auto_protection_policies Type: 11 (.google.cloud.backupdr.v1.AppliedAutoProtectionPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/appliedautoprotectionpolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy;

    my $msg = Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy->new({
        name => $name,
        source_binding => $source_binding,
        criteria => $criteria,
        backup_plan_details => $backup_plan_details,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/appliedautoprotectionpolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy

AppliedAutoProtectionPolicy is a read-only view of AutoProtectionPolicy
and AutoProtectionPolicyBinding resources that apply to a given workload
project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Canonical resource name.
Format:
projects/{workload-project-number}/locations/{location}/appliedAutoProtectionPolicies/{id}.

=item * C<< $msg->source_binding() >> / C<< $msg->source_binding($value) >>

Type: C<String>

Output only. The full resource name of the AutoProtectionPolicyBinding that
applies the source policy to a scope including this workload project. e.g.,
projects/{admin-project}/locations/{location}/autoProtectionPolicies/{policy_id}/autoProtectionPolicyBindings/{binding_id}.

=item * C<< $msg->criteria() >> / C<< $msg->criteria($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria>)

Output only. The criteria resources must meet for this rule to apply. From
AutoProtectionPolicy.criteria.

=item * C<< $msg->backup_plan_details() >> / C<< $msg->backup_plan_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail>)

Output only. The set of backup plan configurations, mirroring the
backup_plan_details from the source AutoProtectionPolicy. Each element
specifies a backup plan for a given resource type.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp indicating when the binding was last modified.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp indicating when the binding was last created.

=item * C<< $msg->binding_evaluation_summary() >> / C<< $msg->binding_evaluation_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Autoprotectionpolicybinding::BindingEvaluationSummary>)

Output only. The summary of the last policy application when the job has
run.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::AppliedAutoProtectionPolicy::State>)

Output only. The status of the applied auto protection policy.

=back

=head3 Enum: AppliedAutoProtectionPolicy::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETION_INITIATED> => C<3>

=back

=head2 Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest

Request message for listing AppliedAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve the list of
applied policies. Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of applied policies to return in a single
page. The maximum value is 1000; values above 1000 will be coerced to
1000. If unspecified or set to 0, a default page size of 500 will be used.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAppliedAutoProtectionPolicies` call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression that sorts the results in the response.

=back

=head2 Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse

Response message for ListAppliedAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->applied_auto_protection_policies() >> / C<< $msg->applied_auto_protection_policies($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy>)

A list of the AppliedAutoProtectionPolicy resources found.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached. For example,
"projects/my-project/locations/us-east1"].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
