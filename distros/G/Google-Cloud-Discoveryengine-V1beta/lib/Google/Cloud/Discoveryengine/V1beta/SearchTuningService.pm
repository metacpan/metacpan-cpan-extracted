package Google::Cloud::Discoveryengine::V1beta::SearchTuningService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Discoveryengine::V1beta::CustomTuningModel };
    eval { require Google::Cloud::Discoveryengine::V1beta::ImportConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zZWFyY2hfdHVuaW5nX3Nl
cnZpY2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29n
bGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxo9Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvY3VzdG9tX3R1bmluZ19t
b2RlbC5wcm90bxo3Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvaW1wb3J0
X2NvbmZpZy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3Rv
ImoKF0xpc3RDdXN0b21Nb2RlbHNSZXF1ZXN0Ek8KCmRhdGFfc3RvcmUYASABKAlCMOBBAvpB
KgooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIJZGF0YVN0b3Jl
ImoKGExpc3RDdXN0b21Nb2RlbHNSZXNwb25zZRJOCgZtb2RlbHMYASADKAsyNi5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DdXN0b21UdW5pbmdNb2RlbFIGbW9kZWxz
IsUEChdUcmFpbkN1c3RvbU1vZGVsUmVxdWVzdBJ9ChJnY3NfdHJhaW5pbmdfaW5wdXQYAiAB
KAsyTS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5UcmFpbkN1c3RvbU1v
ZGVsUmVxdWVzdC5HY3NUcmFpbmluZ0lucHV0SABSEGdjc1RyYWluaW5nSW5wdXQSTwoKZGF0
YV9zdG9yZRgBIAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
RGF0YVN0b3JlUglkYXRhU3RvcmUSHQoKbW9kZWxfdHlwZRgDIAEoCVIJbW9kZWxUeXBlElkK
DGVycm9yX2NvbmZpZxgEIAEoCzI2Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkltcG9ydEVycm9yQ29uZmlnUgtlcnJvckNvbmZpZxIZCghtb2RlbF9pZBgFIAEoCVIH
bW9kZWxJZBqyAQoQR2NzVHJhaW5pbmdJbnB1dBIoChBjb3JwdXNfZGF0YV9wYXRoGAEgASgJ
Ug5jb3JwdXNEYXRhUGF0aBImCg9xdWVyeV9kYXRhX3BhdGgYAiABKAlSDXF1ZXJ5RGF0YVBh
dGgSJgoPdHJhaW5fZGF0YV9wYXRoGAMgASgJUg10cmFpbkRhdGFQYXRoEiQKDnRlc3RfZGF0
YV9wYXRoGAQgASgJUgx0ZXN0RGF0YVBhdGhCEAoOdHJhaW5pbmdfaW5wdXQikgMKGFRyYWlu
Q3VzdG9tTW9kZWxSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIuZ29vZ2xlLnJw
Yy5TdGF0dXNSDGVycm9yU2FtcGxlcxJZCgxlcnJvcl9jb25maWcYAiABKAsyNi5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JbXBvcnRFcnJvckNvbmZpZ1ILZXJyb3JD
b25maWcSIQoMbW9kZWxfc3RhdHVzGAMgASgJUgttb2RlbFN0YXR1cxJkCgdtZXRyaWNzGAQg
AygLMkouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVHJhaW5DdXN0b21N
b2RlbFJlc3BvbnNlLk1ldHJpY3NFbnRyeVIHbWV0cmljcxIdCgptb2RlbF9uYW1lGAUgASgJ
Ugltb2RlbE5hbWUaOgoMTWV0cmljc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgBUgV2YWx1ZToCOAEilAEKGFRyYWluQ3VzdG9tTW9kZWxNZXRhZGF0YRI7CgtjcmVh
dGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUS
OwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRh
dGVUaW1lMqwGChNTZWFyY2hUdW5pbmdTZXJ2aWNlEtMCChBUcmFpbkN1c3RvbU1vZGVsEjwu
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVHJhaW5DdXN0b21Nb2RlbFJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIuEBgtPkkwJcIlcvdjFiZXRh
L3tkYXRhX3N0b3JlPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRh
U3RvcmVzLyp9OnRyYWluQ3VzdG9tTW9kZWw6ASrKQXwKPGdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLlRyYWluQ3VzdG9tTW9kZWxSZXNwb25zZRI8Z29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVHJhaW5DdXN0b21Nb2RlbE1ldGFkYXRhEuwBChBM
aXN0Q3VzdG9tTW9kZWxzEjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
TGlzdEN1c3RvbU1vZGVsc1JlcXVlc3QaPS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5MaXN0Q3VzdG9tTW9kZWxzUmVzcG9uc2UiW4LT5JMCVRJTL3YxYmV0YS97ZGF0
YV9zdG9yZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jl
cy8qfS9jdXN0b21Nb2RlbHMazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23S
QaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUs
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2Vydmlu
Zy5yZWFkd3JpdGVCnwIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YUIYU2VhcmNoVHVuaW5nU2VydmljZVByb3RvUAFaUWNsb3VkLmdvb2dsZS5jb20vZ28vZGlz
Y292ZXJ5ZW5naW5lL2FwaXYxYmV0YS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3Zlcnllbmdp
bmVwYqICD0RJU0NPVkVSWUVOR0lORaoCI0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUu
VjFCZXRhygIjR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWJldGHqAiZHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYmV0YUqfMQoHEgUOAMUBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEcKCQoCAwUSAxcAQQoJCgIDBhID
GAAtCgkKAgMHEgMZACkKCQoCAwgSAxoAIQoICgEIEgMcAEAKCQoCCCUSAxwAQAoICgEIEgMd
AGgKCQoCCAsSAx0AaAoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADkKCQoCCAgSAx8A
OQoICgEIEgMgAEAKCQoCCAESAyAAQAoICgEIEgMhAC0KCQoCCCQSAyEALQoICgEIEgMiAEAK
CQoCCCkSAyIAQAoICgEIEgMjAD8KCQoCCC0SAyMAPwooCgIGABIEJgBBARocIFNlcnZpY2Ug
Zm9yIHNlYXJjaCB0dW5pbmcuCgoKCgMGAAESAyYIGwoKCgMGAAMSAycCRgoMCgUGAAOZCBID
JwJGCgsKAwYAAxIEKAIrSgoNCgUGAAOaCBIEKAIrSgomCgQGAAIAEgQuAjgDGhggVHJhaW5z
IGEgY3VzdG9tIG1vZGVsLgoKDAoFBgACAAESAy4GFgoMCgUGAAIAAhIDLhcuCgwKBQYAAgAD
EgMvDysKDQoFBgACAAQSBDAEMwYKEQoJBgACAASwyrwiEgQwBDMGCg0KBQYAAgAEEgQ0BDcG
Cg8KBwYAAgAEmQgSBDQENwYKNQoEBgACARIEOwJAAxonIEdldHMgYSBsaXN0IG9mIGFsbCB0
aGUgY3VzdG9tIG1vZGVscy4KCgwKBQYAAgEBEgM7BhYKDAoFBgACAQISAzsXLgoMCgUGAAIB
AxIDPA8nCg0KBQYAAgEEEgQ9BD8GChEKCQYAAgEEsMq8IhIEPQQ/BgqdAQoCBAASBEYAUQEa
kAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NlYXJjaFR1bmluZ1NlcnZpY2UuTGlzdEN1c3Rv
bU1vZGVsc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2VhcmNoVHVu
aW5nU2VydmljZS5MaXN0Q3VzdG9tTW9kZWxzXQogbWV0aG9kLgoKCgoDBAABEgNGCB8K+wEK
BAQAAgASBEsCUAQa7AEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXJl
bnQgRGF0YSBTdG9yZSwgc3VjaCBhcwogYHByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9j
b2xsZWN0aW9ucy9kZWZhdWx0X2NvbGxlY3Rpb24vZGF0YVN0b3Jlcy9kZWZhdWx0X2RhdGFf
c3RvcmVgLgogVGhpcyBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRoZSBkYXRhIHN0b3Jl
IHdoZXJlIHRvIGZldGNoIHRoZSBtb2RlbHMKIGZyb20uCgoMCgUEAAIABRIDSwIICgwKBQQA
AgABEgNLCRMKDAoFBAACAAMSA0sWFwoNCgUEAAIACBIESxhQAwoPCggEAAIACJwIABIDTAQq
Cg8KBwQAAgAInwgSBE0ETwUKngEKAgQBEgRWAFkBGpEBIFJlc3BvbnNlIG1lc3NhZ2UgZm9y
CiBbU2VhcmNoVHVuaW5nU2VydmljZS5MaXN0Q3VzdG9tTW9kZWxzXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hUdW5pbmdTZXJ2aWNlLkxpc3RDdXN0b21N
b2RlbHNdCiBtZXRob2QuCgoKCgMEAQESA1YIIAosCgQEAQIAEgNYAigaHyBMaXN0IG9mIGN1
c3RvbSB0dW5pbmcgbW9kZWxzLgoKDAoFBAECAAQSA1gCCgoMCgUEAQIABhIDWAscCgwKBQQB
AgABEgNYHSMKDAoFBAECAAMSA1gmJwqeAQoCBAISBV4AngEBGpABIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtTZWFyY2hUdW5pbmdTZXJ2aWNlLlRyYWluQ3VzdG9tTW9kZWxdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlNlYXJjaFR1bmluZ1NlcnZpY2UuVHJhaW5D
dXN0b21Nb2RlbF0KIG1ldGhvZC4KCgoKAwQCARIDXggfCjMKBAQCAwASBWACgQEDGiQgQ2xv
dWQgU3RvcmFnZSB0cmFpbmluZyBkYXRhIGlucHV0LgoKDAoFBAIDAAESA2AKGgrbAgoGBAID
AAIAEgNoBCAaywIgVGhlIENsb3VkIFN0b3JhZ2UgY29ycHVzIGRhdGEgd2hpY2ggY291bGQg
YmUgYXNzb2NpYXRlZCBpbiB0cmFpbiBkYXRhLgogVGhlIGRhdGEgcGF0aCBmb3JtYXQgaXMg
YGdzOi8vPGJ1Y2tldF90b19kYXRhPi88anNvbmxfZmlsZV9uYW1lPmAuCiBBIG5ld2xpbmUg
ZGVsaW1pdGVkIGpzb25sL25kanNvbiBmaWxlLgoKIEZvciBzZWFyY2gtdHVuaW5nIG1vZGVs
LCBlYWNoIGxpbmUgc2hvdWxkIGhhdmUgdGhlIF9pZCwgdGl0bGUKIGFuZCB0ZXh0LiBFeGFt
cGxlOgogYHsiX2lkIjogImRvYzEiLCB0aXRsZTogInJlbGV2YW50IGRvYyIsICJ0ZXh0Ijog
InJlbGV2YW50IHRleHQifWAKCg4KBwQCAwACAAUSA2gECgoOCgcEAgMAAgABEgNoCxsKDgoH
BAIDAAIAAxIDaB4fCrICCgYEAgMAAgESA3AEHxqiAiBUaGUgZ2NzIHF1ZXJ5IGRhdGEgd2hp
Y2ggY291bGQgYmUgYXNzb2NpYXRlZCBpbiB0cmFpbiBkYXRhLgogVGhlIGRhdGEgcGF0aCBm
b3JtYXQgaXMgYGdzOi8vPGJ1Y2tldF90b19kYXRhPi88anNvbmxfZmlsZV9uYW1lPmAuCiBB
IG5ld2xpbmUgZGVsaW1pdGVkIGpzb25sL25kanNvbiBmaWxlLgoKIEZvciBzZWFyY2gtdHVu
aW5nIG1vZGVsLCBlYWNoIGxpbmUgc2hvdWxkIGhhdmUgdGhlIF9pZAogYW5kIHRleHQuIEV4
YW1wbGU6IHsiX2lkIjogInF1ZXJ5MSIsICAidGV4dCI6ICJleGFtcGxlIHF1ZXJ5In0KCg4K
BwQCAwACAQUSA3AECgoOCgcEAgMAAgEBEgNwCxoKDgoHBAIDAAIBAxIDcB0eCtoDCgYEAgMA
AgISA3wEHxrKAyBDbG91ZCBTdG9yYWdlIHRyYWluaW5nIGRhdGEgcGF0aCB3aG9zZSBmb3Jt
YXQgc2hvdWxkIGJlCiBgZ3M6Ly88YnVja2V0X3RvX2RhdGE+Lzx0c3ZfZmlsZV9uYW1lPmAu
IFRoZSBmaWxlIHNob3VsZCBiZSBpbiB0c3YKIGZvcm1hdC4gRWFjaCBsaW5lIHNob3VsZCBo
YXZlIHRoZSBkb2NfaWQgYW5kIHF1ZXJ5X2lkIGFuZCBzY29yZSAobnVtYmVyKS4KCiBGb3Ig
c2VhcmNoLXR1bmluZyBtb2RlbCwgaXQgc2hvdWxkIGhhdmUgdGhlIHF1ZXJ5LWlkIGNvcnB1
cy1pZAogc2NvcmUgYXMgdHN2IGZpbGUgaGVhZGVyLiBUaGUgc2NvcmUgc2hvdWxkIGJlIGEg
bnVtYmVyIGluIGBbMCwgaW5mKylgLgogVGhlIGxhcmdlciB0aGUgbnVtYmVyIGlzLCB0aGUg
bW9yZSByZWxldmFudCB0aGUgcGFpciBpcy4gRXhhbXBsZToKCiAqIGBxdWVyeS1pZFx0Y29y
cHVzLWlkXHRzY29yZWAKICogYHF1ZXJ5MVx0ZG9jMVx0MWAKCg4KBwQCAwACAgUSA3wECgoO
CgcEAgMAAgIBEgN8CxoKDgoHBAIDAAICAxIDfB0eCqMBCgYEAgMAAgMSBIABBB4akgEgQ2xv
dWQgU3RvcmFnZSB0ZXN0IGRhdGEuIFNhbWUgZm9ybWF0IGFzIHRyYWluX2RhdGFfcGF0aC4g
SWYgbm90IHByb3ZpZGVkLAogYSByYW5kb20gODAvMjAgdHJhaW4vdGVzdCBzcGxpdCB3aWxs
IGJlIHBlcmZvcm1lZCBvbiB0cmFpbl9kYXRhX3BhdGguCgoPCgcEAgMAAgMFEgSAAQQKCg8K
BwQCAwACAwESBIABCxkKDwoHBAIDAAIDAxIEgAEcHQonCgQEAggAEgaEAQKHAQMaFyBNb2Rl
bCB0cmFpbmluZyBpbnB1dC4KCg0KBQQCCAABEgSEAQgWCi0KBAQCAgASBIYBBCwaHyBDbG91
ZCBTdG9yYWdlIHRyYWluaW5nIGlucHV0LgoKDQoFBAICAAYSBIYBBBQKDQoFBAICAAESBIYB
FScKDQoFBAICAAMSBIYBKisK8AEKBAQCAgESBowBApEBBBrfASBSZXF1aXJlZC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIERhdGEgU3RvcmUsIHN1Y2ggYXMKIGBwcm9qZWN0cy8qL2xv
Y2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvZGVmYXVsdF9jb2xsZWN0aW9uL2RhdGFTdG9y
ZXMvZGVmYXVsdF9kYXRhX3N0b3JlYC4KIFRoaXMgZmllbGQgaXMgdXNlZCB0byBpZGVudGlm
eSB0aGUgZGF0YSBzdG9yZSB3aGVyZSB0byB0cmFpbiB0aGUgbW9kZWxzLgoKDQoFBAICAQUS
BIwBAggKDQoFBAICAQESBIwBCRMKDQoFBAICAQMSBIwBFhcKDwoFBAICAQgSBowBGJEBAwoQ
CggEAgIBCJwIABIEjQEEKgoRCgcEAgIBCJ8IEgaOAQSQAQUKiAEKBAQCAgISBJYBAhgaeiBN
b2RlbCB0byBiZSB0cmFpbmVkLiBTdXBwb3J0ZWQgdmFsdWVzIGFyZToKCiAgKiAqKnNlYXJj
aC10dW5pbmcqKjogRmluZSB0dW5pbmcgdGhlIHNlYXJjaCBzeXN0ZW0gYmFzZWQgb24gZGF0
YSBwcm92aWRlZC4KCg0KBQQCAgIFEgSWAQIICg0KBQQCAgIBEgSWAQkTCg0KBQQCAgIDEgSW
ARYXCmAKBAQCAgMSBJoBAiUaUiBUaGUgZGVzaXJlZCBsb2NhdGlvbiBvZiBlcnJvcnMgaW5j
dXJyZWQgZHVyaW5nIHRoZSBkYXRhIGluZ2VzdGlvbiBhbmQKIHRyYWluaW5nLgoKDQoFBAIC
AwYSBJoBAhMKDQoFBAICAwESBJoBFCAKDQoFBAICAwMSBJoBIyQKOgoEBAICBBIEnQECFhos
IElmIG5vdCBwcm92aWRlZCwgYSBVVUlEIHdpbGwgYmUgZ2VuZXJhdGVkLgoKDQoFBAICBAUS
BJ0BAggKDQoFBAICBAESBJ0BCREKDQoFBAICBAMSBJ0BFBUKyAEKAgQDEgajAQC6AQEauQEg
UmVzcG9uc2Ugb2YgdGhlCiBbVHJhaW5DdXN0b21Nb2RlbFJlcXVlc3RdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlRyYWluQ3VzdG9tTW9kZWxSZXF1ZXN0XS4KIFRo
aXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbnMucmVzcG9uc2UgZmllbGQuCgoLCgMEAwESBKMBCCAKSQoEBAMCABIEpQECLxo7IEEg
c2FtcGxlIG9mIGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSBwcm9jZXNzaW5nIHRoZSBkYXRh
LgoKDQoFBAMCAAQSBKUBAgoKDQoFBAMCAAYSBKUBCxwKDQoFBAMCAAESBKUBHSoKDQoFBAMC
AAMSBKUBLS4KVQoEBAMCARIEqAECJRpHIEVjaG9lcyB0aGUgZGVzdGluYXRpb24gZm9yIHRo
ZSBjb21wbGV0ZSBlcnJvcnMgaW4gdGhlIHJlcXVlc3QgaWYgc2V0LgoKDQoFBAMCAQYSBKgB
AhMKDQoFBAMCAQESBKgBFCAKDQoFBAMCAQMSBKgBIyQK0gMKBAQDAgISBLMBAhoawwMgVGhl
IHRyYWluZWQgbW9kZWwgc3RhdHVzLiBQb3NzaWJsZSB2YWx1ZXMgYXJlOgoKICAqICoqYmFk
LWRhdGEqKjogVGhlIHRyYWluaW5nIGRhdGEgcXVhbGl0eSBpcyBiYWQuCiAgKiAqKm5vLWlt
cHJvdmVtZW50Kio6IFR1bmluZyBkaWRuJ3QgaW1wcm92ZSBwZXJmb3JtYW5jZS4gV29uJ3Qg
ZGVwbG95LgogICogKippbi1wcm9ncmVzcyoqOiBNb2RlbCB0cmFpbmluZyBqb2IgY3JlYXRp
b24gaXMgaW4gcHJvZ3Jlc3MuCiAgKiAqKnRyYWluaW5nKio6IE1vZGVsIGlzIGFjdGl2ZWx5
IHRyYWluaW5nLgogICogKipldmFsdWF0aW5nKio6IFRoZSBtb2RlbCBpcyBldmFsdWF0aW5n
IHRyYWluZWQgbWV0cmljcy4KICAqICoqaW5kZXhpbmcqKjogVGhlIG1vZGVsIHRyYWluZWQg
bWV0cmljcyBhcmUgaW5kZXhpbmcuCiAgKiAqKnJlYWR5Kio6IFRoZSBtb2RlbCBpcyByZWFk
eSBmb3Igc2VydmluZy4KCg0KBQQDAgIFEgSzAQIICg0KBQQDAgIBEgSzAQkVCg0KBQQDAgID
EgSzARgZCjEKBAQDAgMSBLYBAiIaIyBUaGUgbWV0cmljcyBvZiB0aGUgdHJhaW5lZCBtb2Rl
bC4KCg0KBQQDAgMGEgS2AQIVCg0KBQQDAgMBEgS2ARYdCg0KBQQDAgMDEgS2ASAhCj4KBAQD
AgQSBLkBAhgaMCBGdWxseSBxdWFsaWZpZWQgbmFtZSBvZiB0aGUgQ3VzdG9tVHVuaW5nTW9k
ZWwuCgoNCgUEAwIEBRIEuQECCAoNCgUEAwIEARIEuQEJEwoNCgUEAwIEAxIEuQEWFwqaAQoC
BAQSBr4BAMUBARqLASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUg
VHJhaW5DdXN0b21Nb2RlbCBvcGVyYXRpb24uIFRoaXMgaXMKIHJldHVybmVkIGJ5IHRoZSBn
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhIGZpZWxkLgoKCwoDBAQBEgS+
AQggCiYKBAQEAgASBMABAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEBAIABhIE
wAECGwoNCgUEBAIAARIEwAEcJwoNCgUEBAIAAxIEwAEqKwpkCgQEBAIBEgTEAQIsGlYgT3Bl
cmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhp
cyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoNCgUEBAIBBhIExAECGwoNCgUEBAIBARIE
xAEcJwoNCgUEBAIBAxIExAEqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest ===
    # Fields for ListCustomModelsRequest
    # Field: data_store Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsResponse ===
    # Fields for ListCustomModelsResponse
    # Field: models Type: 11 (.google.cloud.discoveryengine.v1beta.CustomTuningModel)

# === Message: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest ===
    # Fields for TrainCustomModelRequest
    # Field: gcs_training_input Type: 11 (.google.cloud.discoveryengine.v1beta.TrainCustomModelRequest.GcsTrainingInput)
    # Field: data_store Type: 9 ()
    # Field: model_type Type: 9 ()
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1beta.ImportErrorConfig)
    # Field: model_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse ===
    # Fields for TrainCustomModelResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1beta.ImportErrorConfig)
    # Field: model_status Type: 9 ()
    # Field: metrics Type: 11 (.google.cloud.discoveryengine.v1beta.TrainCustomModelResponse.MetricsEntry)
    # Field: model_name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelMetadata ===
    # Fields for TrainCustomModelMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::SearchTuningServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::SearchTuningService::SearchTuningServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::SearchTuningService::SearchTuningServiceClient

Client stub representing the remote C<SearchTuningService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub train_custom_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SearchTuningService',
        method         => 'TrainCustomModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_custom_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.SearchTuningService',
        method         => 'ListCustomModels',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SearchTuningService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/search_tuning_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SearchTuningService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest->new({
        data_store => $data_store,
    });

    # Read or update a field
    my $val = $msg->data_store();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/search_tuning_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest

Request message for
[SearchTuningService.ListCustomModels][google.cloud.discoveryengine.v1beta.SearchTuningService.ListCustomModels]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The resource name of the parent Data Store, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.
This field is used to identify the data store where to fetch the models
from.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsResponse

Response message for
[SearchTuningService.ListCustomModels][google.cloud.discoveryengine.v1beta.SearchTuningService.ListCustomModels]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel>)

List of custom tuning models.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest

Request message for
[SearchTuningService.TrainCustomModel][google.cloud.discoveryengine.v1beta.SearchTuningService.TrainCustomModel]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_training_input() >> / C<< $msg->gcs_training_input($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest::GcsTrainingInput>)

Cloud Storage training input.

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The resource name of the Data Store, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.
This field is used to identify the data store where to train the models.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Model to be trained. Supported values are:

 * B<search-tuning>: Fine tuning the search system based on data provided.

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportErrorConfig>)

The desired location of errors incurred during the data ingestion and
training.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

If not provided, a UUID will be generated.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse

Response of the
[TrainCustomModelRequest][google.cloud.discoveryengine.v1beta.TrainCustomModelRequest].
This message is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the data.

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportErrorConfig>)

Echoes the destination for the complete errors in the request if set.

=item * C<< $msg->model_status() >> / C<< $msg->model_status($value) >>

Type: C<String>

The trained model status. Possible values are:

 * B<bad-data>: The training data quality is bad.
 * B<no-improvement>: Tuning didn't improve performance. Won't deploy.
 * B<in-progress>: Model training job creation is in progress.
 * B<training>: Model is actively training.
 * B<evaluating>: The model is evaluating trained metrics.
 * B<indexing>: The model trained metrics are indexing.
 * B<ready>: The model is ready for serving.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse::MetricsEntry>)

The metrics of the trained model.

=item * C<< $msg->model_name() >> / C<< $msg->model_name($value) >>

Type: C<String>

Fully qualified name of the CustomTuningModel.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelMetadata

Metadata related to the progress of the TrainCustomModel operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::SearchTuningService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
