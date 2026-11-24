package Google::Devtools::Resultstore::V2::Invocation;

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
    eval { require Google::Devtools::Resultstore::V2::Common };
    eval { require Google::Devtools::Resultstore::V2::Coverage };
    eval { require Google::Devtools::Resultstore::V2::CoverageSummary };
    eval { require Google::Devtools::Resultstore::V2::File };
    eval { require Google::Devtools::Resultstore::V2::FileProcessingError };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvaW52b2NhdGlvbi5wcm90bxIeZ29v
Z2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGitnb29nbGUvZGV2dG9vbHMvcmVz
dWx0c3RvcmUvdjIvY29tbW9uLnByb3RvGi1nb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUv
djIvY292ZXJhZ2UucHJvdG8aNWdvb2dsZS9kZXZ0b29scy9yZXN1bHRzdG9yZS92Mi9jb3Zl
cmFnZV9zdW1tYXJ5LnByb3RvGilnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvZmls
ZS5wcm90bxo6Z29vZ2xlL2RldnRvb2xzL3Jlc3VsdHN0b3JlL3YyL2ZpbGVfcHJvY2Vzc2lu
Z19lcnJvci5wcm90byLsBwoKSW52b2NhdGlvbhISCgRuYW1lGAEgASgJUgRuYW1lEj0KAmlk
GAIgASgLMi0uZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkludm9jYXRpb24uSWRS
AmlkEl0KEXN0YXR1c19hdHRyaWJ1dGVzGAMgASgLMjAuZ29vZ2xlLmRldnRvb2xzLnJlc3Vs
dHN0b3JlLnYyLlN0YXR1c0F0dHJpYnV0ZXNSEHN0YXR1c0F0dHJpYnV0ZXMSPgoGdGltaW5n
GAQgASgLMiYuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlRpbWluZ1IGdGltaW5n
EmkKFWludm9jYXRpb25fYXR0cmlidXRlcxgFIAEoCzI0Lmdvb2dsZS5kZXZ0b29scy5yZXN1
bHRzdG9yZS52Mi5JbnZvY2F0aW9uQXR0cmlidXRlc1IUaW52b2NhdGlvbkF0dHJpYnV0ZXMS
VAoOd29ya3NwYWNlX2luZm8YBiABKAsyLS5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUu
djIuV29ya3NwYWNlSW5mb1INd29ya3NwYWNlSW5mbxJICgpwcm9wZXJ0aWVzGAcgAygLMigu
Z29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlByb3BlcnR5Ugpwcm9wZXJ0aWVzEjoK
BWZpbGVzGAggAygLMiQuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkZpbGVSBWZp
bGVzEmYKEmNvdmVyYWdlX3N1bW1hcmllcxgJIAMoCzI3Lmdvb2dsZS5kZXZ0b29scy5yZXN1
bHRzdG9yZS52Mi5MYW5ndWFnZUNvdmVyYWdlU3VtbWFyeVIRY292ZXJhZ2VTdW1tYXJpZXMS
YAoSYWdncmVnYXRlX2NvdmVyYWdlGAogASgLMjEuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0
b3JlLnYyLkFnZ3JlZ2F0ZUNvdmVyYWdlUhFhZ2dyZWdhdGVDb3ZlcmFnZRJqChZmaWxlX3By
b2Nlc3NpbmdfZXJyb3JzGAsgAygLMjQuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYy
LkZpbGVQcm9jZXNzaW5nRXJyb3JzUhRmaWxlUHJvY2Vzc2luZ0Vycm9ycxopCgJJZBIjCg1p
bnZvY2F0aW9uX2lkGAEgASgJUgxpbnZvY2F0aW9uSWQ6ROpBQQolcmVzdWx0c3RvcmUuZ29v
Z2xlYXBpcy5jb20vSW52b2NhdGlvbhIYaW52b2NhdGlvbnMve2ludm9jYXRpb259IhIKEFdv
cmtzcGFjZUNvbnRleHQipAIKDVdvcmtzcGFjZUluZm8SXQoRd29ya3NwYWNlX2NvbnRleHQY
ASABKAsyMC5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuV29ya3NwYWNlQ29udGV4
dFIQd29ya3NwYWNlQ29udGV4dBIaCghob3N0bmFtZRgDIAEoCVIIaG9zdG5hbWUSKwoRd29y
a2luZ19kaXJlY3RvcnkYBCABKAlSEHdvcmtpbmdEaXJlY3RvcnkSGQoIdG9vbF90YWcYBSAB
KAlSB3Rvb2xUYWcSUAoNY29tbWFuZF9saW5lcxgHIAMoCzIrLmdvb2dsZS5kZXZ0b29scy5y
ZXN1bHRzdG9yZS52Mi5Db21tYW5kTGluZVIMY29tbWFuZExpbmVzImUKC0NvbW1hbmRMaW5l
EhQKBWxhYmVsGAEgASgJUgVsYWJlbBISCgR0b29sGAIgASgJUgR0b29sEhIKBGFyZ3MYAyAD
KAlSBGFyZ3MSGAoHY29tbWFuZBgEIAEoCVIHY29tbWFuZCKLAgoUSW52b2NhdGlvbkF0dHJp
YnV0ZXMSIgoKcHJvamVjdF9pZBgBIAEoCUID4EEFUglwcm9qZWN0SWQSFAoFdXNlcnMYAiAD
KAlSBXVzZXJzEhYKBmxhYmVscxgDIAMoCVIGbGFiZWxzEiAKC2Rlc2NyaXB0aW9uGAQgASgJ
UgtkZXNjcmlwdGlvbhJiChNpbnZvY2F0aW9uX2NvbnRleHRzGAYgAygLMjEuZ29vZ2xlLmRl
dnRvb2xzLnJlc3VsdHN0b3JlLnYyLkludm9jYXRpb25Db250ZXh0UhJpbnZvY2F0aW9uQ29u
dGV4dHMSGwoJZXhpdF9jb2RlGAcgASgFUghleGl0Q29kZSJIChFJbnZvY2F0aW9uQ29udGV4
dBIhCgxkaXNwbGF5X25hbWUYASABKAlSC2Rpc3BsYXlOYW1lEhAKA3VybBgCIAEoCVIDdXJs
QoIBCiJjb20uZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyQg9JbnZvY2F0aW9uUHJv
dG9QAVpJZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9y
ZXN1bHRzdG9yZS92MjtyZXN1bHRzdG9yZUrJPwoHEgUOAMQBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQANQoJCgIDAxIDFQA3CgkKAgMEEgMWAD8KCQoCAwUSAxcAMwoJCgIDBhIDGABECggK
AQgSAxoAYAoJCgIICxIDGgBgCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAMAoJCgII
CBIDHAAwCggKAQgSAx0AOwoJCgIIARIDHQA7Cs8BCgIEABIEIgBnARrCASBBbiBJbnZvY2F0
aW9uIHR5cGljYWxseSByZXByZXNlbnRzIHRoZSByZXN1bHQgb2YgcnVubmluZyBhIHRvb2wu
IEVhY2ggaGFzIGEKIHVuaXF1ZSBJRCwgdHlwaWNhbGx5IGdlbmVyYXRlZCBieSB0aGUgc2Vy
dmVyLiBUYXJnZXQgcmVzb3VyY2VzIHVuZGVyIGVhY2gKIEludm9jYXRpb24gY29udGFpbiB0
aGUgYnVsayBvZiB0aGUgZGF0YS4KCgoKAwQAARIDIggSCgsKAwQABxIEIwImBAoNCgUEAAed
CBIEIwImBApICgQEAAMAEgQpAiwDGjogVGhlIHJlc291cmNlIElEIGNvbXBvbmVudHMgdGhh
dCBpZGVudGlmeSB0aGUgSW52b2NhdGlvbi4KCgwKBQQAAwABEgMpCgwKIwoGBAADAAIAEgMr
BB0aFCBUaGUgSW52b2NhdGlvbiBJRC4KCg4KBwQAAwACAAUSAysECgoOCgcEAAMAAgABEgMr
CxgKDgoHBAADAAIAAxIDKxscClQKBAQAAgASAzACEhpHIFRoZSByZXNvdXJjZSBuYW1lLiAg
SXRzIGZvcm1hdCBtdXN0IGJlOgogaW52b2NhdGlvbnMvJHtJTlZPQ0FUSU9OX0lEfQoKDAoF
BAACAAUSAzACCAoMCgUEAAIAARIDMAkNCgwKBQQAAgADEgMwEBEKgQEKBAQAAgESAzQCDBp0
IFRoZSByZXNvdXJjZSBJRCBjb21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIEludm9jYXRp
b24uIFRoZXkgbXVzdCBtYXRjaAogdGhlIHJlc291cmNlIG5hbWUgYWZ0ZXIgcHJvcGVyIGVu
Y29kaW5nLgoKDAoFBAACAQYSAzQCBAoMCgUEAAIBARIDNAUHCgwKBQQAAgEDEgM0CgsKNgoE
BAACAhIDNwIpGikgVGhlIGFnZ3JlZ2F0ZSBzdGF0dXMgb2YgdGhlIGludm9jYXRpb24uCgoM
CgUEAAICBhIDNwISCgwKBQQAAgIBEgM3EyQKDAoFBAACAgMSAzcnKAo9CgQEAAIDEgM6AhQa
MCBXaGVuIHRoaXMgaW52b2NhdGlvbiBzdGFydGVkIGFuZCBpdHMgZHVyYXRpb24uCgoMCgUE
AAIDBhIDOgIICgwKBQQAAgMBEgM6CQ8KDAoFBAACAwMSAzoSEwotCgQEAAIEEgM9AjEaICBB
dHRyaWJ1dGVzIG9mIHRoaXMgaW52b2NhdGlvbi4KCgwKBQQAAgQGEgM9AhYKDAoFBAACBAES
Az0XLAoMCgUEAAIEAxIDPS8wCjEKBAQAAgUSA0ACIxokIFRoZSB3b3Jrc3BhY2UgdGhlIHRv
b2wgd2FzIHJ1biBpbi4KCgwKBQQAAgUGEgNAAg8KDAoFBAACBQESA0AQHgoMCgUEAAIFAxID
QCEiCsEBCgQEAAIGEgNFAiMaswEgQXJiaXRyYXJ5IG5hbWUtdmFsdWUgcGFpcnMuCiBUaGlz
IGlzIGltcGxlbWVudGVkIGFzIGEgbXVsdGktbWFwLiBNdWx0aXBsZSBwcm9wZXJ0aWVzIGFy
ZSBhbGxvd2VkIHdpdGgKIHRoZSBzYW1lIGtleS4gUHJvcGVydGllcyB3aWxsIGJlIHJldHVy
bmVkIGluIGxleGljb2dyYXBoaWNhbCBvcmRlciBieSBrZXkuCgoMCgUEAAIGBBIDRQIKCgwK
BQQAAgYGEgNFCxMKDAoFBAACBgESA0UUHgoMCgUEAAIGAxIDRSEiCuYECgQEAAIHEgNSAhoa
2AQgQSBsaXN0IG9mIGZpbGUgcmVmZXJlbmNlcyBmb3IgaW52b2NhdGlvbiBsZXZlbCBmaWxl
cy4KIFRoZSBmaWxlIElEcyBtdXN0IGJlIHVuaXF1ZSB3aXRoaW4gdGhpcyBsaXN0LiBEdXBs
aWNhdGUgZmlsZSBJRHMgd2lsbAogcmVzdWx0IGluIGFuIGVycm9yLiBGaWxlcyB3aWxsIGJl
IHJldHVybmVkIGluIGxleGljb2dyYXBoaWNhbCBvcmRlciBieSBJRC4KIFVzZSB0aGlzIGZp
ZWxkIHRvIHNwZWNpZnkgYnVpbGQgbG9ncywgYW5kIG90aGVyIGludm9jYXRpb24gbGV2ZWwg
bG9ncy4KCiBGaWxlcyB3aXRoIHRoZSBmb2xsb3dpbmcgcmVzZXJ2ZWQgZmlsZSBJRHMgY2F1
c2Ugc3BlY2lmaWMgcG9zdC1wcm9jZXNzaW5nCiBvciBoYXZlIHNwZWNpYWwgaGFuZGxpbmcu
IFRoZXNlIGZpbGVzIG11c3QgYmUgaW1tZWRpYXRlbHkgYXZhaWxhYmxlIHRvCiBSZXN1bHRT
dG9yZSBmb3IgcHJvY2Vzc2luZyB3aGVuIHRoZSByZWZlcmVuY2UgaXMgdXBsb2FkZWQuCgog
YnVpbGQubG9nOiBUaGUgcHJpbWFyeSBsb2cgZm9yIHRoZSBJbnZvY2F0aW9uLgogY292ZXJh
Z2VfcmVwb3J0Lmxjb3Y6IEFnZ3JlZ2F0ZSBjb3ZlcmFnZSByZXBvcnQgZm9yIHRoZSBpbnZv
Y2F0aW9uLgoKDAoFBAACBwQSA1ICCgoMCgUEAAIHBhIDUgsPCgwKBQQAAgcBEgNSEBUKDAoF
BAACBwMSA1IYGQr7AQoEBAACCBIDWAI6Gu0BIFN1bW1hcnkgb2YgYWdncmVnYXRlIGNvdmVy
YWdlIGFjcm9zcyBhbGwgQWN0aW9ucyBpbiB0aGlzIEludm9jYXRpb24uCiBJZiBtaXNzaW5n
LCB0aGlzIGRhdGEgd2lsbCBiZSBwb3B1bGF0ZWQgYnkgdGhlIHNlcnZlciBmcm9tIHRoZQog
Y292ZXJhZ2VfcmVwb3J0Lmxjb3YgZmlsZSBvciB0aGUgdW5pb24gb2YgYWxsIEFjdGlvbkNv
dmVyYWdlcyB1bmRlciB0aGlzCiBpbnZvY2F0aW9uIChpbiB0aGF0IG9yZGVyKS4KCgwKBQQA
AggEEgNYAgoKDAoFBAACCAYSA1gLIgoMCgUEAAIIARIDWCM1CgwKBQQAAggDEgNYODkKhQIK
BAQAAgkSA14CLBr3ASBBZ2dyZWdhdGUgY29kZSBjb3ZlcmFnZSBmb3IgYWxsIGJ1aWxkIGFu
ZCB0ZXN0IEFjdGlvbnMgd2l0aGluIHRoaXMKIEludm9jYXRpb24uIElmIG1pc3NpbmcsIHRo
aXMgZGF0YSB3aWxsIGJlIHBvcHVsYXRlZCBieSB0aGUgc2VydmVyCiBmcm9tIHRoZSBjb3Zl
cmFnZV9yZXBvcnQubGNvdiBmaWxlIG9yIHRoZSB1bmlvbiBvZiBhbGwgQWN0aW9uQ292ZXJh
Z2VzCiB1bmRlciB0aGlzIGludm9jYXRpb24gKGluIHRoYXQgb3JkZXIpLgoKDAoFBAACCQYS
A14CEwoMCgUEAAIJARIDXhQmCgwKBQQAAgkDEgNeKSsKyAIKBAQAAgoSA2YCPBq6AiBOT1Qg
SU1QTEVNRU5URUQuCiBSZXN1bHRTdG9yZSB3aWxsIHJlYWQgYW5kIHBhcnNlIEZpbGVzIHdp
dGggcmVzZXJ2ZWQgSURzIGxpc3RlZCBhYm92ZS4gUmVhZAogYW5kIHBhcnNlIGVycm9ycyBm
b3IgYWxsIHRoZXNlIEZpbGVzIGFyZSByZXBvcnRlZCBoZXJlLgogVGhpcyBpcyBpbXBsZW1l
bnRlZCBhcyBhIG1hcCwgd2l0aCBvbmUgRmlsZVByb2Nlc3NpbmdFcnJvcnMgZm9yIGVhY2gg
ZmlsZS4KIFR5cGljYWxseSBwcm9kdWNlZCB3aGVuIHBhcnNpbmcgRmlsZXMsIGJ1dCBtYXkg
YWxzbyBiZSBwcm92aWRlZCBkaXJlY3RseQogYnkgY2xpZW50cy4KCgwKBQQAAgoEEgNmAgoK
DAoFBAACCgYSA2YLHwoMCgUEAAIKARIDZiA2CgwKBQQAAgoDEgNmOTsKTwoCBAESA2oAGxpE
IElmIGtub3duLCByZXByZXNlbnRzIHRoZSBzdGF0ZSBvZiB0aGUgdXNlci9idWlsZC1zeXN0
ZW0gd29ya3NwYWNlLgoKCgoDBAEBEgNqCBgKtQEKAgQCEgVvAIABARqnASBEZXNjcmliZXMg
dGhlIHdvcmtzcGFjZSB1bmRlciB3aGljaCB0aGUgdG9vbCB3YXMgaW52b2tlZCwgdGhpcyBp
bmNsdWRlcwogaW5mb3JtYXRpb24gdGhhdCB3YXMgZmVkIGludG8gdGhlIGNvbW1hbmQsIHRo
ZSBzb3VyY2UgY29kZSByZWZlcmVuY2VkLCBhbmQKIHRoZSB0b29sIGl0c2VsZi4KCgoKAwQC
ARIDbwgVCksKBAQCAgASA3ECKRo+IERhdGEgYWJvdXQgdGhlIHdvcmtzcGFjZSB0aGF0IG1p
Z2h0IGJlIHVzZWZ1bCBmb3IgZGVidWdnaW5nLgoKDAoFBAICAAYSA3ECEgoMCgUEAgIAARID
cRMkCgwKBQQCAgADEgNxJygKKQoEBAICARIDdAIWGhwgV2hlcmUgdGhlIHRvb2wgd2FzIGlu
dm9rZWQKCgwKBQQCAgEFEgN0AggKDAoFBAICAQESA3QJEQoMCgUEAgIBAxIDdBQVClAKBAQC
AgISA3cCHxpDIFRoZSBjbGllbnQncyB3b3JraW5nIGRpcmVjdG9yeSB3aGVyZSB0aGUgYnVp
bGQvdGVzdCB3YXMgcnVuIGZyb20uCgoMCgUEAgICBRIDdwIICgwKBQQCAgIBEgN3CRoKDAoF
BAICAgMSA3cdHgpNCgQEAgIDEgN6AhYaQCBUb29scyBzaG91bGQgc2V0IHRvb2xfdGFnIHRv
IHRoZSBuYW1lIG9mIHRoZSB0b29sIG9yIHVzZSBjYXNlLgoKDAoFBAICAwUSA3oCCAoMCgUE
AgIDARIDegkRCgwKBQQCAgMDEgN6FBUKrwEKBAQCAgQSA38CKRqhASBUaGUgY29tbWFuZCBs
aW5lcyBpbnZva2VkLiBUaGUgZmlyc3QgY29tbWFuZCBsaW5lIGlzIHRoZSBvbmUgdHlwZWQg
YnkgdGhlCiB1c2VyLCB0aGVuIGVhY2ggb25lIGFmdGVyIHRoYXQgc2hvdWxkIGJlIGFuIGV4
cGFuc2lvbiBvZiB0aGUgcHJldmlvdXMKIGNvbW1hbmQgbGluZS4KCgwKBQQCAgQEEgN/AgoK
DAoFBAICBAYSA38LFgoMCgUEAgIEARIDfxckCgwKBQQCAgQDEgN/JygKSAoCBAMSBoMBAJIB
ARo6IFRoZSBjb21tYW5kIGFuZCBhcmd1bWVudHMgdGhhdCBwcm9kdWNlZCB0aGlzIEludm9j
YXRpb24uCgoLCgMEAwESBIMBCBMKNQoEBAMCABIEhQECExonIEEgbGFiZWwgZGVzY3JpYmlu
ZyB0aGlzIGNvbW1hbmQgbGluZS4KCg0KBQQDAgAFEgSFAQIICg0KBQQDAgABEgSFAQkOCg0K
BQQDAgADEgSFARESCjsKBAQDAgESBIgBAhIaLSBUaGUgY29tbWFuZC1saW5lIHRvb2wgdGhh
dCBpcyBydW46IGFyZ3ZbMF0uCgoNCgUEAwIBBRIEiAECCAoNCgUEAwIBARIEiAEJDQoNCgUE
AwIBAxIEiAEQEQpDCgQEAwICEgSLAQIbGjUgVGhlIGFyZ3VtZW50cyB0byB0aGUgYWJvdmUg
dG9vbDogYXJndlsxXS4uLmFyZ3ZbTl0uCgoNCgUEAwICBBIEiwECCgoNCgUEAwICBRIEiwEL
EQoNCgUEAwICARIEiwESFgoNCgUEAwICAxIEiwEZGgqTAgoEBAMCAxIEkQECFRqEAiBUaGUg
c3ViY29tbWFuZCB0aGF0IHdhcyBydW4gd2l0aCB0aGUgdG9vbCwgdXN1YWxseSAiYnVpbGQi
IG9yICJ0ZXN0Ii4KIEZvciBleGFtcGxlLCBpbiB0aGUgQmF6ZWwgY29tbWFuZCAiYmF6ZWwg
YnVpbGQgLy9mb28iLCB0aGlzIHdvdWxkIGJlIHNldAogdG8gImJ1aWxkIi4gT21pdCBpZiB0
aGUgdG9vbCBkb2Vzbid0IGFjY2VwdCBhIHN1YmNvbW1hbmQuICBUaGlzIGlzIG11c3QKIGJl
IGEgcmVmZXJlbmNlIHRvIG9uZSBvZiB2YWx1ZXMgaW4gYXJncy4KCg0KBQQDAgMFEgSRAQII
Cg0KBQQDAgMBEgSRAQkQCg0KBQQDAgMDEgSRARMUCjkKAgQEEgaVAQC7AQEaKyBBdHRyaWJ1
dGVzIHRoYXQgYXBwbHkgdG8gYWxsIGludm9jYXRpb25zLgoKCwoDBAQBEgSVAQgcCroDCgQE
BAIAEgScAQJCGqsDIEltbXV0YWJsZS4gVGhlIENsb3VkIFByb2plY3QgdGhhdCBvd25zIHRo
aXMgaW52b2NhdGlvbiAodGhpcyBpcyBkaWZmZXJlbnQKIHRoYW4gdGhlIENvbnN1bWVyIENs
b3VkIFByb2plY3QgdGhhdCBjYWxscyB0aGlzIEFQSSkuIFRoaXMgbXVzdCBiZSBzZXQgaW4K
IHRoZSBDcmVhdGVJbnZvY2F0aW9uIGNhbGwsIGFuZCBjYW4ndCBiZSBjaGFuZ2VkLiBBcyBp
bnB1dCwgY2FsbGVycyBjYW4gc2V0CiB0aGlzIGZpZWxkIHRvIGEgcHJvamVjdCBpZCAoc3Ry
aW5nKSBvciBhIHN0cmluZ2lmaWVkIGludDY0IHByb2plY3QgbnVtYmVyLgogQXMgb3V0cHV0
LCB0aGUgQVBJIHBvcHVsYXRlcyB0aGlzIGZpZWxkIHdpdGggdGhlIHN0cmluZ2lmaWVkIGlu
dDY0IHByb2plY3QKIG51bWJlciAocGVyIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvY2xvdWQv
MjUxMCkuCgoNCgUEBAIABRIEnAECCAoNCgUEBAIAARIEnAEJEwoNCgUEBAIAAxIEnAEWFwoN
CgUEBAIACBIEnAEYQQoQCggEBAIACJwIABIEnAEZQAr7AgoEBAQCARIEowECHBrsAiBUaGUg
bGlzdCBvZiB1c2VycyBpbiB0aGUgY29tbWFuZCBjaGFpbi4gIFRoZSBmaXJzdCB1c2VyIGlu
IHRoaXMgc2VxdWVuY2UKIGlzIHRoZSBvbmUgd2hvIGluc3RpZ2F0ZWQgdGhlIGZpcnN0IGNv
bW1hbmQgaW4gdGhlIGNoYWluLiBGb3IgZXhhbXBsZSwKIHRoaXMgbWlnaHQgY29udGFpbiBq
dXN0IHRoZSB1c2VyIHRoYXQgcmFuIGEgQmF6ZWwgY29tbWFuZCwgb3IgYSByb2JvdAogdGhh
dCB0ZXN0ZWQgYSBjaGFuZ2UgYXMgcGFydCBvZiBhIENJIHN5c3RlbS4gSXQgY291bGQgYWxz
byBjb250YWluIHRoZSB1c2VyCiB0aGF0IG1hbnVhbGx5IHRyaWdnZXJlZCBhIENJIHRlc3Qs
IHRoZW4gdGhlIHJvYm90IHRoYXQgcmFuIHRoZSB0ZXN0LgoKDQoFBAQCAQQSBKMBAgoKDQoF
BAQCAQUSBKMBCxEKDQoFBAQCAQESBKMBEhcKDQoFBAQCAQMSBKMBGhsK3wMKBAQEAgISBKwB
Ah0a0AMgTGFiZWxzIHRvIGNhdGVnb3JpemUgdGhpcyBpbnZvY2F0aW9uLgogVGhpcyBpcyBp
bXBsZW1lbnRlZCBhcyBhIHNldC4gQWxsIGxhYmVscyB3aWxsIGJlIHVuaXF1ZS4gQW55IGR1
cGxpY2F0ZQogbGFiZWxzIGFkZGVkIHdpbGwgYmUgaWdub3JlZC4gTGFiZWxzIHdpbGwgYmUg
cmV0dXJuZWQgaW4gbGV4aWNvZ3JhcGhpY2FsCiBvcmRlci4gTGFiZWxzIHNob3VsZCBiZSBh
IGxpc3Qgb2Ygd29yZHMgZGVzY3JpYmluZyB0aGUgSW52b2NhdGlvbi4gTGFiZWxzCiBzaG91
bGQgYmUgc2hvcnQsIGVhc3kgdG8gcmVhZCwgYW5kIHlvdSBzaG91bGRuJ3QgaGF2ZSBtb3Jl
IHRoYW4gYSBoYW5kZnVsLgogTGFiZWxzIHNob3VsZCBub3QgYmUgdXNlZCBmb3IgdW5pcXVl
IHByb3BlcnRpZXMgc3VjaCBhcyB1bmlxdWUgSURzLiBVc2UKIHByb3BlcnRpZXMgaW4gY2Fz
ZXMgdGhhdCBkb24ndCBtZWV0IHRoZXNlIGNvbmRpdGlvbnMuCgoNCgUEBAICBBIErAECCgoN
CgUEBAICBRIErAELEQoNCgUEBAICARIErAESGAoNCgUEBAICAxIErAEbHAq9AQoEBAQCAxIE
sQECGRquASBUaGlzIGZpZWxkIGRlc2NyaWJlcyB0aGUgb3ZlcmFsbCBjb250ZXh0IG9yIHB1
cnBvc2Ugb2YgdGhpcyBpbnZvY2F0aW9uLgogSXQgd2lsbCBiZSB1c2VkIGluIHRoZSBVSSB0
byBnaXZlIHVzZXJzIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQKIGhvdyBvciB3aHkgdGhpcyBp
bnZvY2F0aW9uIHdhcyBydW4uCgoNCgUEBAIDBRIEsQECCAoNCgUEBAIDARIEsQEJFAoNCgUE
BAIDAxIEsQEXGArDAQoEBAQCBBIEtgECNRq0ASBJZiB0aGlzIEludm9jYXRpb24gd2FzIHJ1
biBpbiB0aGUgY29udGV4dCBvZiBhIGxhcmdlciBDb250aW51b3VzCiBJbnRlZ3JhdGlvbiBi
dWlsZCBvciBvdGhlciBhdXRvbWF0ZWQgc3lzdGVtLCB0aGlzIGZpZWxkIG1heSBjb250YWlu
IG1vcmUKIGluZm9ybWF0aW9uIGFib3V0IHRoZSBncmVhdGVyIGNvbnRleHQuCgoNCgUEBAIE
BBIEtgECCgoNCgUEBAIEBhIEtgELHAoNCgUEBAIEARIEtgEdMAoNCgUEBAIEAxIEtgEzNAqZ
AQoEBAQCBRIEugECFhqKASBFeGl0IGNvZGUgb2YgdGhlIHByb2Nlc3MgdGhhdCByYW4gdGhl
IGludm9jYXRpb24uIEEgbm9uLXplcm8gdmFsdWUKIG1lYW5zIGZhaWx1cmUuIEZvciBleGFt
cGxlLCB0aGUgZXhpdCBjb2RlIG9mIGEgImJhemVsIHRlc3QiIGNvbW1hbmQuCgoNCgUEBAIF
BRIEugECBwoNCgUEBAIFARIEugEIEQoNCgUEBAIFAxIEugEUFQpXCgIEBRIGvgEAxAEBGkkg
RGVzY3JpYmVzIHRoZSBpbnZvY2F0aW9uIGNvbnRleHQgd2hpY2ggaW5jbHVkZXMgYSBkaXNw
bGF5IG5hbWUgYW5kIFVSTC4KCgsKAwQFARIEvgEIGQpaCgQEBQIAEgTAAQIaGkwgQSBodW1h
biByZWFkYWJsZSBuYW1lIGZvciB0aGUgY29udGV4dCB1bmRlciB3aGljaCB0aGlzIEludm9j
YXRpb24gd2FzIHJ1bi4KCg0KBQQFAgAFEgTAAQIICg0KBQQFAgABEgTAAQkVCg0KBQQFAgAD
EgTAARgZCkIKBAQFAgESBMMBAhEaNCBBIFVSTCBwb2ludGluZyB0byBhIFVJIGNvbnRhaW5p
bmcgbW9yZSBpbmZvcm1hdGlvbgoKDQoFBAUCAQUSBMMBAggKDQoFBAUCAQESBMMBCQwKDQoF
BAUCAQMSBMMBDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::Invocation::Invocation ===
    # Fields for Invocation
    # Field: name Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.Invocation.Id)
    # Field: status_attributes Type: 11 (.google.devtools.resultstore.v2.StatusAttributes)
    # Field: timing Type: 11 (.google.devtools.resultstore.v2.Timing)
    # Field: invocation_attributes Type: 11 (.google.devtools.resultstore.v2.InvocationAttributes)
    # Field: workspace_info Type: 11 (.google.devtools.resultstore.v2.WorkspaceInfo)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)
    # Field: coverage_summaries Type: 11 (.google.devtools.resultstore.v2.LanguageCoverageSummary)
    # Field: aggregate_coverage Type: 11 (.google.devtools.resultstore.v2.AggregateCoverage)
    # Field: file_processing_errors Type: 11 (.google.devtools.resultstore.v2.FileProcessingErrors)

# === Message: Google::Devtools::Resultstore::V2::Invocation::WorkspaceContext ===
    # Fields for WorkspaceContext

# === Message: Google::Devtools::Resultstore::V2::Invocation::WorkspaceInfo ===
    # Fields for WorkspaceInfo
    # Field: workspace_context Type: 11 (.google.devtools.resultstore.v2.WorkspaceContext)
    # Field: hostname Type: 9 ()
    # Field: working_directory Type: 9 ()
    # Field: tool_tag Type: 9 ()
    # Field: command_lines Type: 11 (.google.devtools.resultstore.v2.CommandLine)

# === Message: Google::Devtools::Resultstore::V2::Invocation::CommandLine ===
    # Fields for CommandLine
    # Field: label Type: 9 ()
    # Field: tool Type: 9 ()
    # Field: args Type: 9 ()
    # Field: command Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::Invocation::InvocationAttributes ===
    # Fields for InvocationAttributes
    # Field: project_id Type: 9 ()
    # Field: users Type: 9 ()
    # Field: labels Type: 9 ()
    # Field: description Type: 9 ()
    # Field: invocation_contexts Type: 11 (.google.devtools.resultstore.v2.InvocationContext)
    # Field: exit_code Type: 5 ()

# === Message: Google::Devtools::Resultstore::V2::Invocation::InvocationContext ===
    # Fields for InvocationContext
    # Field: display_name Type: 9 ()
    # Field: url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::Invocation - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/invocation.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::Invocation;

    my $msg = Google::Devtools::Resultstore::V2::Invocation::Invocation->new({
        name => $name,
        id => $id,
        status_attributes => $status_attributes,
        timing => $timing,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::Invocation::Invocation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/invocation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::Invocation::Invocation

An Invocation typically represents the result of running a tool. Each has a
unique ID, typically generated by the server. Target resources under each
Invocation contain the bulk of the data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name.  Its format must be:
invocations/${INVOCATION_ID}

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Invocation::Invocation::Id>)

The resource ID components that identify the Invocation. They must match
the resource name after proper encoding.

=item * C<< $msg->status_attributes() >> / C<< $msg->status_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::StatusAttributes>)

The aggregate status of the invocation.

=item * C<< $msg->timing() >> / C<< $msg->timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Timing>)

When this invocation started and its duration.

=item * C<< $msg->invocation_attributes() >> / C<< $msg->invocation_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Invocation::InvocationAttributes>)

Attributes of this invocation.

=item * C<< $msg->workspace_info() >> / C<< $msg->workspace_info($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Invocation::WorkspaceInfo>)

The workspace the tool was run in.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs.
This is implemented as a multi-map. Multiple properties are allowed with
the same key. Properties will be returned in lexicographical order by key.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

A list of file references for invocation level files.
The file IDs must be unique within this list. Duplicate file IDs will
result in an error. Files will be returned in lexicographical order by ID.
Use this field to specify build logs, and other invocation level logs.

Files with the following reserved file IDs cause specific post-processing
or have special handling. These files must be immediately available to
ResultStore for processing when the reference is uploaded.

build.log: The primary log for the Invocation.
coverage_report.lcov: Aggregate coverage report for the invocation.

=item * C<< $msg->coverage_summaries() >> / C<< $msg->coverage_summaries($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::CoverageSummary::LanguageCoverageSummary>)

Summary of aggregate coverage across all Actions in this Invocation.
If missing, this data will be populated by the server from the
coverage_report.lcov file or the union of all ActionCoverages under this
invocation (in that order).

=item * C<< $msg->aggregate_coverage() >> / C<< $msg->aggregate_coverage($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Coverage::AggregateCoverage>)

Aggregate code coverage for all build and test Actions within this
Invocation. If missing, this data will be populated by the server
from the coverage_report.lcov file or the union of all ActionCoverages
under this invocation (in that order).

=item * C<< $msg->file_processing_errors() >> / C<< $msg->file_processing_errors($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors>)

NOT IMPLEMENTED.
ResultStore will read and parse Files with reserved IDs listed above. Read
and parse errors for all these Files are reported here.
This is implemented as a map, with one FileProcessingErrors for each file.
Typically produced when parsing Files, but may also be provided directly
by clients.

=back

=head2 Google::Devtools::Resultstore::V2::Invocation::WorkspaceContext

If known, represents the state of the user/build-system workspace.

Inherits from L<Protobuf::Message>.

=head2 Google::Devtools::Resultstore::V2::Invocation::WorkspaceInfo

Describes the workspace under which the tool was invoked, this includes
information that was fed into the command, the source code referenced, and
the tool itself.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workspace_context() >> / C<< $msg->workspace_context($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Invocation::WorkspaceContext>)

Data about the workspace that might be useful for debugging.

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

Where the tool was invoked

=item * C<< $msg->working_directory() >> / C<< $msg->working_directory($value) >>

Type: C<String>

The client's working directory where the build/test was run from.

=item * C<< $msg->tool_tag() >> / C<< $msg->tool_tag($value) >>

Type: C<String>

Tools should set tool_tag to the name of the tool or use case.

=item * C<< $msg->command_lines() >> / C<< $msg->command_lines($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Invocation::CommandLine>)

The command lines invoked. The first command line is the one typed by the
user, then each one after that should be an expansion of the previous
command line.

=back

=head2 Google::Devtools::Resultstore::V2::Invocation::CommandLine

The command and arguments that produced this Invocation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

A label describing this command line.

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The command-line tool that is run: argv[0].

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<String>

The arguments to the above tool: argv[1]...argv[N].

=item * C<< $msg->command() >> / C<< $msg->command($value) >>

Type: C<String>

The subcommand that was run with the tool, usually "build" or "test".
For example, in the Bazel command "bazel build //foo", this would be set
to "build". Omit if the tool doesn't accept a subcommand.  This is must
be a reference to one of values in args.

=back

=head2 Google::Devtools::Resultstore::V2::Invocation::InvocationAttributes

Attributes that apply to all invocations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Immutable. The Cloud Project that owns this invocation (this is different
than the Consumer Cloud Project that calls this API). This must be set in
the CreateInvocation call, and can't be changed. As input, callers can set
this field to a project id (string) or a stringified int64 project number.
As output, the API populates this field with the stringified int64 project
number (per https://google.aip.dev/cloud/2510).

=item * C<< $msg->users() >> / C<< $msg->users($value) >>

Type: C<String>

The list of users in the command chain.  The first user in this sequence
is the one who instigated the first command in the chain. For example,
this might contain just the user that ran a Bazel command, or a robot
that tested a change as part of a CI system. It could also contain the user
that manually triggered a CI test, then the robot that ran the test.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Labels to categorize this invocation.
This is implemented as a set. All labels will be unique. Any duplicate
labels added will be ignored. Labels will be returned in lexicographical
order. Labels should be a list of words describing the Invocation. Labels
should be short, easy to read, and you shouldn't have more than a handful.
Labels should not be used for unique properties such as unique IDs. Use
properties in cases that don't meet these conditions.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

This field describes the overall context or purpose of this invocation.
It will be used in the UI to give users more information about
how or why this invocation was run.

=item * C<< $msg->invocation_contexts() >> / C<< $msg->invocation_contexts($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Invocation::InvocationContext>)

If this Invocation was run in the context of a larger Continuous
Integration build or other automated system, this field may contain more
information about the greater context.

=item * C<< $msg->exit_code() >> / C<< $msg->exit_code($value) >>

Type: C<Int32>

Exit code of the process that ran the invocation. A non-zero value
means failure. For example, the exit code of a "bazel test" command.

=back

=head2 Google::Devtools::Resultstore::V2::Invocation::InvocationContext

Describes the invocation context which includes a display name and URL.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A human readable name for the context under which this Invocation was run.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

A URL pointing to a UI containing more information

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::Invocation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
