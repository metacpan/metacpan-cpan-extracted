package Google::Cloud::Backupdr::V1beta::Datasourcereference;

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
    eval { require Google::Cloud::Backupdr::V1beta::Backupvault };
    eval { require Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb };
    eval { require Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2RhdGFzb3VyY2VyZWZlcmVuY2UucHJv
dG8SHGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLmdvb2dsZS9jbG91ZC9i
YWNrdXBkci92MWJldGEvYmFja3VwdmF1bHQucHJvdG8aNmdvb2dsZS9jbG91ZC9iYWNrdXBk
ci92MWJldGEvYmFja3VwdmF1bHRfYWxsb3lkYi5wcm90bxo3Z29vZ2xlL2Nsb3VkL2JhY2t1
cGRyL3YxYmV0YS9iYWNrdXB2YXVsdF9jbG91ZHNxbC5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byL/BgoTRGF0YVNvdXJjZVJlZmVyZW5jZRIXCgRuYW1lGAEgASgJ
QgPgQQhSBG5hbWUSSwoLZGF0YV9zb3VyY2UYAiABKAlCKuBBA/pBJAoiYmFja3VwZHIuZ29v
Z2xlYXBpcy5jb20vRGF0YVNvdXJjZVIKZGF0YVNvdXJjZRJACgtjcmVhdGVfdGltZRgDIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJ6Ch9kYXRh
X3NvdXJjZV9iYWNrdXBfY29uZmlnX3N0YXRlGAQgASgOMi8uZ29vZ2xlLmNsb3VkLmJhY2t1
cGRyLnYxYmV0YS5CYWNrdXBDb25maWdTdGF0ZUID4EEDUhtkYXRhU291cmNlQmFja3VwQ29u
ZmlnU3RhdGUSPAoYZGF0YV9zb3VyY2VfYmFja3VwX2NvdW50GAUgASgDQgPgQQNSFWRhdGFT
b3VyY2VCYWNrdXBDb3VudBKBAQoeZGF0YV9zb3VyY2VfYmFja3VwX2NvbmZpZ19pbmZvGAYg
ASgLMjguZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5EYXRhU291cmNlQmFja3VwQ29u
ZmlnSW5mb0ID4EEDUhpkYXRhU291cmNlQmFja3VwQ29uZmlnSW5mbxJ+Ch1kYXRhX3NvdXJj
ZV9nY3BfcmVzb3VyY2VfaW5mbxgHIAEoCzI3Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJl
dGEuRGF0YVNvdXJjZUdjcFJlc291cmNlSW5mb0ID4EEDUhlkYXRhU291cmNlR2NwUmVzb3Vy
Y2VJbmZvEjYKEnRvdGFsX3N0b3JlZF9ieXRlcxgIIAEoA0ID4EEDSABSEHRvdGFsU3RvcmVk
Qnl0ZXOIAQE6sgHqQa4BCitiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9EYXRhU291cmNlUmVm
ZXJlbmNlElRwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVNv
dXJjZVJlZmVyZW5jZXMve2RhdGFfc291cmNlX3JlZmVyZW5jZX0qFGRhdGFTb3VyY2VSZWZl
cmVuY2VzMhNkYXRhU291cmNlUmVmZXJlbmNlQhUKE190b3RhbF9zdG9yZWRfYnl0ZXMihAIK
GkRhdGFTb3VyY2VCYWNrdXBDb25maWdJbmZvEm8KEWxhc3RfYmFja3VwX3N0YXRlGAEgASgO
Mj4uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5CYWNrdXBDb25maWdJbmZvLkxhc3RC
YWNrdXBTdGF0ZUID4EEDUg9sYXN0QmFja3VwU3RhdGUSdQonbGFzdF9zdWNjZXNzZnVsX2Jh
Y2t1cF9jb25zaXN0ZW5jeV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUiNsYXN0U3VjY2Vzc2Z1bEJhY2t1cENvbnNpc3RlbmN5VGltZSLGAwoZRGF0YVNv
dXJjZUdjcFJlc291cmNlSW5mbxKVAQodY2xvdWRfc3FsX2luc3RhbmNlX3Byb3BlcnRpZXMY
BCABKAsySy5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkNsb3VkU3FsSW5zdGFuY2VE
YXRhU291cmNlUmVmZXJlbmNlUHJvcGVydGllc0ID4EEDSABSGmNsb3VkU3FsSW5zdGFuY2VQ
cm9wZXJ0aWVzEo8BChthbGxveV9kYl9jbHVzdGVyX3Byb3BlcnRpZXMYBiABKAsySS5nb29n
bGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkFsbG95REJDbHVzdGVyRGF0YVNvdXJjZVJlZmVy
ZW5jZVByb3BlcnRpZXNCA+BBA0gAUhhhbGxveURiQ2x1c3RlclByb3BlcnRpZXMSLgoQZ2Nw
X3Jlc291cmNlbmFtZRgBIAEoCUID4EEDUg9nY3BSZXNvdXJjZW5hbWUSFwoEdHlwZRgCIAEo
CUID4EEDUgR0eXBlEh8KCGxvY2F0aW9uGAMgASgJQgPgQQNSCGxvY2F0aW9uQhUKE3Jlc291
cmNlX3Byb3BlcnRpZXMiaAodR2V0RGF0YVNvdXJjZVJlZmVyZW5jZVJlcXVlc3QSRwoEbmFt
ZRgBIAEoCUIz4EEC+kEtCitiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9EYXRhU291cmNlUmVm
ZXJlbmNlUgRuYW1lIvEBCh9MaXN0RGF0YVNvdXJjZVJlZmVyZW5jZXNSZXF1ZXN0EksKBnBh
cmVudBgBIAEoCUIz4EEC+kEtEitiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9EYXRhU291cmNl
UmVmZXJlbmNlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIK
CnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEB
UgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLVAQogTGlzdERhdGFT
b3VyY2VSZWZlcmVuY2VzUmVzcG9uc2USZwoWZGF0YV9zb3VyY2VfcmVmZXJlbmNlcxgBIAMo
CzIxLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuRGF0YVNvdXJjZVJlZmVyZW5jZVIU
ZGF0YVNvdXJjZVJlZmVyZW5jZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSKrAgovRmV0Y2hEYXRh
U291cmNlUmVmZXJlbmNlc0ZvclJlc291cmNlVHlwZVJlcXVlc3QSSwoGcGFyZW50GAEgASgJ
QjPgQQL6QS0SK2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0RhdGFTb3VyY2VSZWZlcmVuY2VS
BnBhcmVudBIoCg1yZXNvdXJjZV90eXBlGAIgASgJQgPgQQJSDHJlc291cmNlVHlwZRIgCglw
YWdlX3NpemUYAyABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgEIAEoCUID4EEB
UglwYWdlVG9rZW4SGwoGZmlsdGVyGAUgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgG
IAEoCUID4EEBUgdvcmRlckJ5IsMBCjBGZXRjaERhdGFTb3VyY2VSZWZlcmVuY2VzRm9yUmVz
b3VyY2VUeXBlUmVzcG9uc2USZwoWZGF0YV9zb3VyY2VfcmVmZXJlbmNlcxgBIAMoCzIxLmdv
b2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuRGF0YVNvdXJjZVJlZmVyZW5jZVIUZGF0YVNv
dXJjZVJlZmVyZW5jZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
QtwBCiBjb20uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YUIYRGF0YVNvdXJjZVJlZmVy
ZW5jZVByb3RvUAFaPGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjFiZXRhL2Jh
Y2t1cGRycGI7YmFja3VwZHJwYqoCHEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5WMUJldGHKAhxH
b29nbGVcQ2xvdWRcQmFja3VwRFJcVjFiZXRh6gIfR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6
OlYxYmV0YUrkRgoHEgUOAP4BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOAoJCgIDAxIDFQBA
CgkKAgMEEgMWAEEKCQoCAwUSAxcAKQoICgEIEgMZADkKCQoCCCUSAxkAOQoICgEIEgMaAFMK
CQoCCAsSAxoAUwoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADkKCQoCCAgSAxwAOQoI
CgEIEgMdADkKCQoCCAESAx0AOQoICgEIEgMeADkKCQoCCCkSAx4AOQoICgEIEgMfADgKCQoC
CC0SAx8AOApKCgIEABIEIgBSARo+IERhdGFTb3VyY2VSZWZlcmVuY2UgaXMgYSByZWZlcmVu
Y2UgdG8gYSBEYXRhU291cmNlIHJlc291cmNlLgoKCgoDBAABEgMiCBsKCwoDBAAHEgQjAigE
Cg0KBQQAB50IEgQjAigECqgBCgQEAAIAEgMtAj0amgEgSWRlbnRpZmllci4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIERhdGFTb3VyY2VSZWZlcmVuY2UuCiBGb3JtYXQ6CiBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVNvdXJjZVJlZmVyZW5jZXMv
e2RhdGFfc291cmNlX3JlZmVyZW5jZX0KCgwKBQQAAgAFEgMtAggKDAoFBAACAAESAy0JDQoM
CgUEAAIAAxIDLRARCgwKBQQAAgAIEgMtEjwKDwoIBAACAAicCAASAy0TOwqoAQoEBAACARIE
MgI3BBqZASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIERhdGFTb3Vy
Y2UuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
YmFja3VwVmF1bHRzL3tiYWNrdXBWYXVsdH0vZGF0YVNvdXJjZXMve2RhdGFTb3VyY2V9CgoM
CgUEAAIBBRIDMgIICgwKBQQAAgEBEgMyCRQKDAoFBAACAQMSAzIXGAoNCgUEAAIBCBIEMhk3
AwoPCggEAAIBCJwIABIDMwQtCg8KBwQAAgEInwgSBDQENgUKTwoEBAACAhIEOgI7MhpBIE91
dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBEYXRhU291cmNlUmVmZXJlbmNlIHdhcyBj
cmVhdGVkLgoKDAoFBAACAgYSAzoCGwoMCgUEAAICARIDOhwnCgwKBQQAAgIDEgM6KisKDAoF
BAACAggSAzsGMQoPCggEAAICCJwIABIDOwcwCk4KBAQAAgMSBD4CPzIaQCBPdXRwdXQgb25s
eS4gVGhlIGJhY2t1cCBjb25maWd1cmF0aW9uIHN0YXRlIG9mIHRoZSBEYXRhU291cmNlLgoK
DAoFBAACAwYSAz4CEwoMCgUEAAIDARIDPhQzCgwKBQQAAgMDEgM+NjcKDAoFBAACAwgSAz8G
MQoPCggEAAIDCJwIABIDPwcwCkEKBAQAAgQSBEICQzIaMyBPdXRwdXQgb25seS4gTnVtYmVy
IG9mIGJhY2t1cHMgaW4gdGhlIERhdGFTb3VyY2UuCgoMCgUEAAIEBRIDQgIHCgwKBQQAAgQB
EgNCCCAKDAoFBAACBAMSA0IjJAoMCgUEAAIECBIDQwYxCg8KCAQAAgQInAgAEgNDBzAKUwoE
BAACBRIERgJHMhpFIE91dHB1dCBvbmx5LiBJbmZvcm1hdGlvbiBvZiBiYWNrdXAgY29uZmln
dXJhdGlvbiBvbiB0aGUgRGF0YVNvdXJjZS4KCgwKBQQAAgUGEgNGAhwKDAoFBAACBQESA0Yd
OwoMCgUEAAIFAxIDRj4/CgwKBQQAAgUIEgNHBjEKDwoIBAACBQicCAASA0cHMApfCgQEAAIG
EgRLAkwyGlEgT3V0cHV0IG9ubHkuIFRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgdGhhdCB0
aGUgRGF0YVNvdXJjZSBpcyBhc3NvY2lhdGVkCiB3aXRoLgoKDAoFBAACBgYSA0sCGwoMCgUE
AAIGARIDSxw5CgwKBQQAAgYDEgNLPD0KDAoFBAACBggSA0wGMQoPCggEAAIGCJwIABIDTAcw
CnMKBAQAAgcSBFACUTIaZSBPdXRwdXQgb25seS4gVG90YWwgc2l6ZSBvZiB0aGUgc3RvcmFn
ZSB1c2VkIGJ5IGFsbCBiYWNrdXAgcmVzb3VyY2VzIGZvciB0aGUKIHJlZmVyZW5jZWQgZGF0
YXNvdXJjZS4KCgwKBQQAAgcEEgNQAgoKDAoFBAACBwUSA1ALEAoMCgUEAAIHARIDUBEjCgwK
BQQAAgcDEgNQJicKDAoFBAACBwgSA1EGMQoPCggEAAIHCJwIABIDUQcwCkQKAgQBEgRVAF0B
GjggSW5mb3JtYXRpb24gb2YgYmFja3VwIGNvbmZpZ3VyYXRpb24gb24gdGhlIERhdGFTb3Vy
Y2UuCgoKCgMEAQESA1UIIgpNCgQEAQIAEgRXAlgyGj8gT3V0cHV0IG9ubHkuIFRoZSBzdGF0
dXMgb2YgdGhlIGxhc3QgYmFja3VwIGluIHRoaXMgRGF0YVNvdXJjZQoKDAoFBAECAAYSA1cC
IgoMCgUEAQIAARIDVyM0CgwKBQQBAgADEgNXNzgKDAoFBAECAAgSA1gGMQoPCggEAQIACJwI
ABIDWAcwClgKBAQBAgESBFsCXDIaSiBPdXRwdXQgb25seS4gVGltZXN0YW1wIG9mIHRoZSBs
YXN0IHN1Y2Nlc3NmdWwgYmFja3VwIHRvIHRoaXMgRGF0YVNvdXJjZS4KCgwKBQQBAgEGEgNb
AhsKDAoFBAECAQESA1scQwoMCgUEAQIBAxIDW0ZHCgwKBQQBAgEIEgNcBjEKDwoIBAECAQic
CAASA1wHMApPCgIEAhIEYAB4ARpDIFRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgdGhhdCB0
aGUgRGF0YVNvdXJjZSBpcyBhc3NvY2lhdGVkIHdpdGguCgoKCgMEAgESA2AIIQo8CgQEAggA
EgRiAmsDGi4gVGhlIHByb3BlcnRpZXMgb2YgdGhlIEdvb2dsZSBDbG91ZCByZXNvdXJjZS4K
CgwKBQQCCAABEgNiCBsKRgoEBAICABIEZARmNBo4IE91dHB1dCBvbmx5LiBUaGUgcHJvcGVy
dGllcyBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBAICAAYSA2QEMQoMCgUEAgIA
ARIDZQglCgwKBQQCAgADEgNlKCkKDAoFBAICAAgSA2YIMwoPCggEAgIACJwIABIDZgkyCkMK
BAQCAgESBGkEajQaNSBPdXRwdXQgb25seS4gVGhlIHByb3BlcnRpZXMgb2YgdGhlIEFsbG95
REIgY2x1c3Rlci4KCgwKBQQCAgEGEgNpBC8KDAoFBAICAQESA2kwSwoMCgUEAgIBAxIDaU5P
CgwKBQQCAgEIEgNqCDMKDwoIBAICAQicCAASA2oJMgqFAQoEBAICAhIDbwJKGnggT3V0cHV0
IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2Uu
CiBFeDogcHJvamVjdHMve3Byb2plY3R9L3pvbmVzL3t6b25lfS9pbnN0YW5jZXMve2luc3Rh
bmNlfQoKDAoFBAICAgUSA28CCAoMCgUEAgICARIDbwkZCgwKBQQCAgIDEgNvHB0KDAoFBAIC
AggSA28eSQoPCggEAgICCJwIABIDbx9ICmcKBAQCAgMSA3MCPhpaIE91dHB1dCBvbmx5LiBU
aGUgdHlwZSBvZiB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlLgogRXg6IGNvbXB1dGUuZ29v
Z2xlYXBpcy5jb20vSW5zdGFuY2UKCgwKBQQCAgMFEgNzAggKDAoFBAICAwESA3MJDQoMCgUE
AgIDAxIDcxARCgwKBQQCAgMIEgNzEj0KDwoIBAICAwicCAASA3MTPApyCgQEAgIEEgN3AkIa
ZSBPdXRwdXQgb25seS4gVGhlIGxvY2F0aW9uIG9mIHRoZSBHb29nbGUgQ2xvdWQgcmVzb3Vy
Y2UuCiBFeDogPHJlZ2lvbj4vPHpvbmU+LyJnbG9iYWwiLyJ1bnNwZWNpZmllZCIKCgwKBQQC
AgQFEgN3AggKDAoFBAICBAESA3cJEQoMCgUEAgIEAxIDdxQVCgwKBQQCAgQIEgN3FkEKDwoI
BAICBAicCAASA3cXQAo9CgIEAxIFewCFAQEaMCBSZXF1ZXN0IGZvciB0aGUgR2V0RGF0YVNv
dXJjZVJlZmVyZW5jZSBtZXRob2QuCgoKCgMEAwESA3sIJQqrAQoEBAMCABIFfwKEAQQamwEg
UmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBEYXRhU291cmNlUmVmZXJlbmNlIHRvIHJldHJp
ZXZlLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2RhdGFTb3VyY2VSZWZlcmVuY2VzL3tkYXRhX3NvdXJjZV9yZWZlcmVuY2V9CgoMCgUEAwIA
BRIDfwIICgwKBQQDAgABEgN/CQ0KDAoFBAMCAAMSA38QEQoOCgUEAwIACBIFfxKEAQMKEAoI
BAMCAAicCAASBIABBCoKEQoHBAMCAAifCBIGgQEEgwEFCkAKAgQEEgaIAQCyAQEaMiBSZXF1
ZXN0IGZvciB0aGUgTGlzdERhdGFTb3VyY2VSZWZlcmVuY2VzIG1ldGhvZC4KCgsKAwQEARIE
iAEIJwpmCgQEBAIAEgaLAQKQAQQaViBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBu
YW1lLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0K
Cg0KBQQEAgAFEgSLAQIICg0KBQQEAgABEgSLAQkPCg0KBQQEAgADEgSLARITCg8KBQQEAgAI
EgaLARSQAQMKEAoIBAQCAAicCAASBIwBBCoKEQoHBAQCAAifCBIGjQEEjwEFCoYCCgQEBAIB
EgSWAQI/GvcBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgRGF0YVNvdXJjZVJl
ZmVyZW5jZXMgdG8gcmV0dXJuLiBUaGUgc2VydmljZQogbWF5IHJldHVybiBmZXdlciB0aGFu
IHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwCiBEYXRhU291cmNlUmVm
ZXJlbmNlcyB3aWxsIGJlIHJldHVybmVkLiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDA7IHZh
bHVlcwogYWJvdmUgMTAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAuCgoNCgUEBAIBBRIElgEC
BwoNCgUEBAIBARIElgEIEQoNCgUEBAIBAxIElgEUFQoNCgUEBAIBCBIElgEWPgoQCggEBAIB
CJwIABIElgEXPQqUAgoEBAQCAhIEngECQRqFAiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCBy
ZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3REYXRhU291cmNlUmVmZXJlbmNlc2AKIGNh
bGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdo
ZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8KIGBMaXN0
RGF0YVNvdXJjZVJlZmVyZW5jZXNgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRl
ZCB0aGUgcGFnZQogdG9rZW4uCgoNCgUEBAICBRIEngECCAoNCgUEBAICARIEngEJEwoNCgUE
BAICAxIEngEWFwoNCgUEBAICCBIEngEYQAoQCggEBAICCJwIABIEngEZPwqMAwoEBAQCAxIE
qAECPRr9AiBPcHRpb25hbC4gQSBmaWx0ZXIgZXhwcmVzc2lvbiB0aGF0IGZpbHRlcnMgdGhl
IHJlc3VsdHMgbGlzdGVkIGluIHRoZQogcmVzcG9uc2UuIFRoZSBleHByZXNzaW9uIG11c3Qg
c3BlY2lmeSB0aGUgZmllbGQgbmFtZSwgYSBjb21wYXJpc29uCiBvcGVyYXRvciwgYW5kIHRo
ZSB2YWx1ZSB0aGF0IHlvdSB3YW50IHRvIHVzZSBmb3IgZmlsdGVyaW5nLgoKIFRoZSBmb2xs
b3dpbmcgZmllbGQgYW5kIG9wZXJhdG9yIGNvbWJpbmF0aW9ucyBhcmUgc3VwcG9ydGVkOgoK
ICogZGF0YV9zb3VyY2VfZ2NwX3Jlc291cmNlX2luZm8uZ2NwX3Jlc291cmNlbmFtZSB3aXRo
IGA9YCwgYCE9YAogKiBkYXRhX3NvdXJjZV9nY3BfcmVzb3VyY2VfaW5mby50eXBlIHdpdGgg
YD1gLCBgIT1gCgoNCgUEBAIDBRIEqAECCAoNCgUEBAIDARIEqAEJDwoNCgUEBAIDAxIEqAES
EwoNCgUEBAIDCBIEqAEUPAoQCggEBAIDCJwIABIEqAEVOwroAQoEBAQCBBIEsQECPxrZASBP
cHRpb25hbC4gQSBjb21tYS1zZXBhcmF0ZWQgbGlzdCBvZiBmaWVsZHMgdG8gb3JkZXIgYnks
IHNvcnRlZCBpbiBhc2NlbmRpbmcKIG9yZGVyLiBVc2UgImRlc2MiIGFmdGVyIGEgZmllbGQg
bmFtZSBmb3IgZGVzY2VuZGluZy4KCiBTdXBwb3J0ZWQgZmllbGRzOgoKICogZGF0YV9zb3Vy
Y2UKICogZGF0YV9zb3VyY2VfZ2NwX3Jlc291cmNlX2luZm8uZ2NwX3Jlc291cmNlbmFtZQoK
DQoFBAQCBAUSBLEBAggKDQoFBAQCBAESBLEBCREKDQoFBAQCBAMSBLEBFBUKDQoFBAQCBAgS
BLEBFj4KEAoIBAQCBAicCAASBLEBFz0KQQoCBAUSBrUBAL8BARozIFJlc3BvbnNlIGZvciB0
aGUgTGlzdERhdGFTb3VyY2VSZWZlcmVuY2VzIG1ldGhvZC4KCgsKAwQFARIEtQEIKApDCgQE
BQIAEgS3AQI6GjUgVGhlIERhdGFTb3VyY2VSZWZlcmVuY2VzIGZyb20gdGhlIHNwZWNpZmll
ZCBwYXJlbnQuCgoNCgUEBQIABBIEtwECCgoNCgUEBQIABhIEtwELHgoNCgUEBQIAARIEtwEf
NQoNCgUEBQIAAxIEtwE4OQqQAQoEBAUCARIEuwECHRqBASBBIHRva2VuLCB3aGljaCBjYW4g
YmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElm
IHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMu
CgoNCgUEBQIBBRIEuwECCAoNCgUEBQIBARIEuwEJGAoNCgUEBQIBAxIEuwEbHAo0CgQEBQIC
EgS+AQIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEBQIC
BBIEvgECCgoNCgUEBQICBRIEvgELEQoNCgUEBQICARIEvgESHQoNCgUEBQICAxIEvgEgIQpQ
CgIEBhIGwgEA9AEBGkIgUmVxdWVzdCBmb3IgdGhlIEZldGNoRGF0YVNvdXJjZVJlZmVyZW5j
ZXNGb3JSZXNvdXJjZVR5cGUgbWV0aG9kLgoKCwoDBAYBEgTCAQg3CmYKBAQGAgASBsUBAsoB
BBpWIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUuCiBGb3JtYXQ6IHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufQoKDQoFBAYCAAUSBMUBAggKDQoF
BAYCAAESBMUBCQ8KDQoFBAYCAAMSBMUBEhMKDwoFBAYCAAgSBsUBFMoBAwoQCggEBgIACJwI
ABIExgEEKgoRCgcEBgIACJ8IEgbHAQTJAQUKYQoEBAYCARIEzgECRBpTIFJlcXVpcmVkLiBU
aGUgdHlwZSBvZiB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlLgogRXg6IHNxbC5nb29nbGVh
cGlzLmNvbS9JbnN0YW5jZQoKDQoFBAYCAQUSBM4BAggKDQoFBAYCAQESBM4BCRYKDQoFBAYC
AQMSBM4BGRoKDQoFBAYCAQgSBM4BG0MKEAoIBAYCAQicCAASBM4BHEIKhgIKBAQGAgISBNQB
Aj8a9wEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBEYXRhU291cmNlUmVmZXJl
bmNlcyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlCiBtYXkgcmV0dXJuIGZld2VyIHRoYW4gdGhp
cyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgNTAKIERhdGFTb3VyY2VSZWZlcmVu
Y2VzIHdpbGwgYmUgcmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDsgdmFsdWVz
CiBhYm92ZSAxMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMC4KCg0KBQQGAgIFEgTUAQIHCg0K
BQQGAgIBEgTUAQgRCg0KBQQGAgIDEgTUARQVCg0KBQQGAgIIEgTUARY+ChAKCAQGAgIInAgA
EgTUARc9CrgCCgQEBgIDEgTdAQJBGqkCIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2Vp
dmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIG9mCiBgRmV0Y2hEYXRhU291cmNlUmVmZXJlbmNl
c0ZvclJlc291cmNlVHlwZWAuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNl
cXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHBy
b3ZpZGVkIHRvCiBgRmV0Y2hEYXRhU291cmNlUmVmZXJlbmNlc0ZvclJlc291cmNlVHlwZWAg
bXVzdCBtYXRjaAogdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0K
BQQGAgMFEgTdAQIICg0KBQQGAgMBEgTdAQkTCg0KBQQGAgMDEgTdARYXCg0KBQQGAgMIEgTd
ARhAChAKCAQGAgMInAgAEgTdARk/CvQECgQEBgIEEgTsAQI9GuUEIE9wdGlvbmFsLiBBIGZp
bHRlciBleHByZXNzaW9uIHRoYXQgZmlsdGVycyB0aGUgcmVzdWx0cyBmZXRjaGVkIGluIHRo
ZQogcmVzcG9uc2UuIFRoZSBleHByZXNzaW9uIG11c3Qgc3BlY2lmeSB0aGUgZmllbGQgbmFt
ZSwgYSBjb21wYXJpc29uCiBvcGVyYXRvciwgYW5kIHRoZSB2YWx1ZSB0aGF0IHlvdSB3YW50
IHRvIHVzZSBmb3IgZmlsdGVyaW5nLiBTdXBwb3J0ZWQKIGZpZWxkczoKICogZGF0YV9zb3Vy
Y2UKICogZGF0YV9zb3VyY2VfZ2NwX3Jlc291cmNlX2luZm8uZ2NwX3Jlc291cmNlbmFtZQog
KiBkYXRhX3NvdXJjZV9iYWNrdXBfY29uZmlnX3N0YXRlCiAqIGRhdGFfc291cmNlX2JhY2t1
cF9jb3VudAogKiBkYXRhX3NvdXJjZV9iYWNrdXBfY29uZmlnX2luZm8ubGFzdF9iYWNrdXBf
c3RhdGUKICogZGF0YV9zb3VyY2VfZ2NwX3Jlc291cmNlX2luZm8uZ2NwX3Jlc291cmNlbmFt
ZQogKiBkYXRhX3NvdXJjZV9nY3BfcmVzb3VyY2VfaW5mby50eXBlCiAqIGRhdGFfc291cmNl
X2djcF9yZXNvdXJjZV9pbmZvLmxvY2F0aW9uCiAqIGRhdGFfc291cmNlX2djcF9yZXNvdXJj
ZV9pbmZvLmNsb3VkX3NxbF9pbnN0YW5jZV9wcm9wZXJ0aWVzLmluc3RhbmNlX2NyZWF0ZV90
aW1lCgoNCgUEBgIEBRIE7AECCAoNCgUEBgIEARIE7AEJDwoNCgUEBgIEAxIE7AESEwoNCgUE
BgIECBIE7AEUPAoQCggEBgIECJwIABIE7AEVOwquAQoEBAYCBRIE8wECPxqfASBPcHRpb25h
bC4gQSBjb21tYS1zZXBhcmF0ZWQgbGlzdCBvZiBmaWVsZHMgdG8gb3JkZXIgYnksIHNvcnRl
ZCBpbiBhc2NlbmRpbmcKIG9yZGVyLiBVc2UgImRlc2MiIGFmdGVyIGEgZmllbGQgbmFtZSBm
b3IgZGVzY2VuZGluZy4KCiBTdXBwb3J0ZWQgZmllbGRzOgogKiBuYW1lCgoNCgUEBgIFBRIE
8wECCAoNCgUEBgIFARIE8wEJEQoNCgUEBgIFAxIE8wEUFQoNCgUEBgIFCBIE8wEWPgoQCggE
BgIFCJwIABIE8wEXPQpRCgIEBxIG9wEA/gEBGkMgUmVzcG9uc2UgZm9yIHRoZSBGZXRjaERh
dGFTb3VyY2VSZWZlcmVuY2VzRm9yUmVzb3VyY2VUeXBlIG1ldGhvZC4KCgsKAwQHARIE9wEI
OApDCgQEBwIAEgT5AQI6GjUgVGhlIERhdGFTb3VyY2VSZWZlcmVuY2VzIGZyb20gdGhlIHNw
ZWNpZmllZCBwYXJlbnQuCgoNCgUEBwIABBIE+QECCgoNCgUEBwIABhIE+QELHgoNCgUEBwIA
ARIE+QEfNQoNCgUEBwIAAxIE+QE4OQqQAQoEBAcCARIE/QECHRqBASBBIHRva2VuLCB3aGlj
aCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQg
cGFnZXMuCgoNCgUEBwIBBRIE/QECCAoNCgUEBwIBARIE/QEJGAoNCgUEBwIBAxIE/QEbHGIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference ===
    # Fields for DataSourceReference
    # Field: name Type: 9 ()
    # Field: data_source Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_source_backup_config_state Type: 14 (.google.cloud.backupdr.v1beta.BackupConfigState)
    # Field: data_source_backup_count Type: 3 ()
    # Field: data_source_backup_config_info Type: 11 (.google.cloud.backupdr.v1beta.DataSourceBackupConfigInfo)
    # Field: data_source_gcp_resource_info Type: 11 (.google.cloud.backupdr.v1beta.DataSourceGcpResourceInfo)
    # Field: total_stored_bytes Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceBackupConfigInfo ===
    # Fields for DataSourceBackupConfigInfo
    # Field: last_backup_state Type: 14 (.google.cloud.backupdr.v1beta.BackupConfigInfo.LastBackupState)
    # Field: last_successful_backup_consistency_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceGcpResourceInfo ===
    # Fields for DataSourceGcpResourceInfo
    # Field: cloud_sql_instance_properties Type: 11 (.google.cloud.backupdr.v1beta.CloudSqlInstanceDataSourceReferenceProperties)
    # Field: alloy_db_cluster_properties Type: 11 (.google.cloud.backupdr.v1beta.AlloyDBClusterDataSourceReferenceProperties)
    # Field: gcp_resourcename Type: 9 ()
    # Field: type Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::GetDataSourceReferenceRequest ===
    # Fields for GetDataSourceReferenceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesRequest ===
    # Fields for ListDataSourceReferencesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesResponse ===
    # Fields for ListDataSourceReferencesResponse
    # Field: data_source_references Type: 11 (.google.cloud.backupdr.v1beta.DataSourceReference)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest ===
    # Fields for FetchDataSourceReferencesForResourceTypeRequest
    # Field: parent Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse ===
    # Fields for FetchDataSourceReferencesForResourceTypeResponse
    # Field: data_source_references Type: 11 (.google.cloud.backupdr.v1beta.DataSourceReference)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::Datasourcereference - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/datasourcereference.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::Datasourcereference;

    my $msg = Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference->new({
        name => $name,
        data_source => $data_source,
        create_time => $create_time,
        data_source_backup_config_state => $data_source_backup_config_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/datasourcereference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference

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

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::BackupConfigState>)

Output only. The backup configuration state of the DataSource.

=item * C<< $msg->data_source_backup_count() >> / C<< $msg->data_source_backup_count($value) >>

Type: C<Int64>

Output only. Number of backups in the DataSource.

=item * C<< $msg->data_source_backup_config_info() >> / C<< $msg->data_source_backup_config_info($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceBackupConfigInfo>)

Output only. Information of backup configuration on the DataSource.

=item * C<< $msg->data_source_gcp_resource_info() >> / C<< $msg->data_source_gcp_resource_info($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceGcpResourceInfo>)

Output only. The Google Cloud resource that the DataSource is associated
with.

=item * C<< $msg->total_stored_bytes() >> / C<< $msg->total_stored_bytes($value) >>

Type: C<Int64>

Output only. Total size of the storage used by all backup resources for the
referenced datasource.

=back

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceBackupConfigInfo

Information of backup configuration on the DataSource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_backup_state() >> / C<< $msg->last_backup_state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::BackupConfigInfo::LastBackupState>)

Output only. The status of the last backup in this DataSource

=item * C<< $msg->last_successful_backup_consistency_time() >> / C<< $msg->last_successful_backup_consistency_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the last successful backup to this DataSource.

=back

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceGcpResourceInfo

The Google Cloud resource that the DataSource is associated with.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_sql_instance_properties() >> / C<< $msg->cloud_sql_instance_properties($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties>)

Output only. The properties of the Cloud SQL instance.

=item * C<< $msg->alloy_db_cluster_properties() >> / C<< $msg->alloy_db_cluster_properties($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceReferenceProperties>)

Output only. The properties of the AlloyDB cluster.

=item * C<< $msg->gcp_resourcename() >> / C<< $msg->gcp_resourcename($value) >>

Type: C<String>

Output only. The resource name of the Google Cloud resource.
Ex: projects/{project}/zones/{zone}/instances/{instance}

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Output only. The type of the Google Cloud resource.
Ex: compute.googleapis.com/Instance

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Output only. The location of the Google Cloud resource.
Ex: <region>/<zone>/"global"/"unspecified"

=back

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::GetDataSourceReferenceRequest

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

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesRequest

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

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesResponse

Response for the ListDataSourceReferences method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_source_references() >> / C<< $msg->data_source_references($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference>)

The DataSourceReferences from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest

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

Required. The type of the Google Cloud resource.
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

=head2 Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse

Response for the FetchDataSourceReferencesForResourceType method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_source_references() >> / C<< $msg->data_source_references($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference>)

The DataSourceReferences from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::Datasourcereference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
