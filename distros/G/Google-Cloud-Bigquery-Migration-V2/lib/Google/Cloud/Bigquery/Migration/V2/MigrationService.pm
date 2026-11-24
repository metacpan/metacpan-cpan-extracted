package Google::Cloud::Bigquery::Migration::V2::MigrationService;

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
    eval { require Google::Cloud::Bigquery::Migration::V2::MigrationEntities };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL21pZ3JhdGlvbl9zZXJ2aWNl
LnByb3RvEiJnb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo7Z29v
Z2xlL2Nsb3VkL2JpZ3F1ZXJ5L21pZ3JhdGlvbi92Mi9taWdyYXRpb25fZW50aXRpZXMucHJv
dG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxk
X21hc2sucHJvdG8izgEKHkNyZWF0ZU1pZ3JhdGlvbldvcmtmbG93UmVxdWVzdBJBCgZwYXJl
bnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZw
YXJlbnQSaQoSbWlncmF0aW9uX3dvcmtmbG93GAIgASgLMjUuZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5Lm1pZ3JhdGlvbi52Mi5NaWdyYXRpb25Xb3JrZmxvd0ID4EECUhFtaWdyYXRpb25Xb3Jr
ZmxvdyKmAQobR2V0TWlncmF0aW9uV29ya2Zsb3dSZXF1ZXN0Ek4KBG5hbWUYASABKAlCOuBB
AvpBNAoyYmlncXVlcnltaWdyYXRpb24uZ29vZ2xlYXBpcy5jb20vTWlncmF0aW9uV29ya2Zs
b3dSBG5hbWUSNwoJcmVhZF9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a1IIcmVhZE1hc2si1wEKHUxpc3RNaWdyYXRpb25Xb3JrZmxvd3NSZXF1ZXN0EkEKBnBhcmVu
dBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBh
cmVudBI3CglyZWFkX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUghy
ZWFkTWFzaxIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBCAB
KAlSCXBhZ2VUb2tlbiKwAQoeTGlzdE1pZ3JhdGlvbldvcmtmbG93c1Jlc3BvbnNlEmYKE21p
Z3JhdGlvbl93b3JrZmxvd3MYASADKAsyNS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0
aW9uLnYyLk1pZ3JhdGlvbldvcmtmbG93UhJtaWdyYXRpb25Xb3JrZmxvd3MSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuInAKHkRlbGV0ZU1pZ3JhdGlvbldvcmtm
bG93UmVxdWVzdBJOCgRuYW1lGAEgASgJQjrgQQL6QTQKMmJpZ3F1ZXJ5bWlncmF0aW9uLmdv
b2dsZWFwaXMuY29tL01pZ3JhdGlvbldvcmtmbG93UgRuYW1lIm8KHVN0YXJ0TWlncmF0aW9u
V29ya2Zsb3dSZXF1ZXN0Ek4KBG5hbWUYASABKAlCOuBBAvpBNAoyYmlncXVlcnltaWdyYXRp
b24uZ29vZ2xlYXBpcy5jb20vTWlncmF0aW9uV29ya2Zsb3dSBG5hbWUiqQEKGkdldE1pZ3Jh
dGlvblN1YnRhc2tSZXF1ZXN0Ek0KBG5hbWUYASABKAlCOeBBAvpBMwoxYmlncXVlcnltaWdy
YXRpb24uZ29vZ2xlYXBpcy5jb20vTWlncmF0aW9uU3VidGFza1IEbmFtZRI8CglyZWFkX21h
c2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCHJlYWRNYXNrIpMC
ChxMaXN0TWlncmF0aW9uU3VidGFza3NSZXF1ZXN0ElIKBnBhcmVudBgBIAEoCUI64EEC+kE0
CjJiaWdxdWVyeW1pZ3JhdGlvbi5nb29nbGVhcGlzLmNvbS9NaWdyYXRpb25Xb3JrZmxvd1IG
cGFyZW50EjwKCXJlYWRfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tC
A+BBAVIIcmVhZE1hc2sSIAoJcGFnZV9zaXplGAMgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBh
Z2VfdG9rZW4YBCABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgFIAEoCUID4EEBUgZm
aWx0ZXIirAEKHUxpc3RNaWdyYXRpb25TdWJ0YXNrc1Jlc3BvbnNlEmMKEm1pZ3JhdGlvbl9z
dWJ0YXNrcxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuTWln
cmF0aW9uU3VidGFza1IRbWlncmF0aW9uU3VidGFza3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJUg1uZXh0UGFnZVRva2VuMssMChBNaWdyYXRpb25TZXJ2aWNlEvsBChdDcmVhdGVNaWdy
YXRpb25Xb3JrZmxvdxJCLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuQ3Jl
YXRlTWlncmF0aW9uV29ya2Zsb3dSZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1p
Z3JhdGlvbi52Mi5NaWdyYXRpb25Xb3JrZmxvdyJlgtPkkwJDIi0vdjIve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qfS93b3JrZmxvd3M6Em1pZ3JhdGlvbl93b3JrZmxvd9pBGXBh
cmVudCxtaWdyYXRpb25fd29ya2Zsb3cSzAEKFEdldE1pZ3JhdGlvbldvcmtmbG93Ej8uZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5HZXRNaWdyYXRpb25Xb3JrZmxvd1Jl
cXVlc3QaNS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLk1pZ3JhdGlvbldv
cmtmbG93IjyC0+STAi8SLS92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtm
bG93cy8qfdpBBG5hbWUS3wEKFkxpc3RNaWdyYXRpb25Xb3JrZmxvd3MSQS5nb29nbGUuY2xv
dWQuYmlncXVlcnkubWlncmF0aW9uLnYyLkxpc3RNaWdyYXRpb25Xb3JrZmxvd3NSZXF1ZXN0
GkIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5MaXN0TWlncmF0aW9uV29y
a2Zsb3dzUmVzcG9uc2UiPoLT5JMCLxItL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKn0vd29ya2Zsb3dz2kEGcGFyZW50ErMBChdEZWxldGVNaWdyYXRpb25Xb3JrZmxvdxJC
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuRGVsZXRlTWlncmF0aW9uV29y
a2Zsb3dSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IjyC0+STAi8qLS92Mi97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtmbG93cy8qfdpBBG5hbWUSugEKFlN0YXJ0
TWlncmF0aW9uV29ya2Zsb3cSQS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYy
LlN0YXJ0TWlncmF0aW9uV29ya2Zsb3dSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5
IkWC0+STAjgiMy92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtmbG93cy8q
fTpzdGFydDoBKtpBBG5hbWUS1AEKE0dldE1pZ3JhdGlvblN1YnRhc2sSPi5nb29nbGUuY2xv
dWQuYmlncXVlcnkubWlncmF0aW9uLnYyLkdldE1pZ3JhdGlvblN1YnRhc2tSZXF1ZXN0GjQu
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5NaWdyYXRpb25TdWJ0YXNrIkeC
0+STAjoSOC92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtmbG93cy8qL3N1
YnRhc2tzLyp92kEEbmFtZRLnAQoVTGlzdE1pZ3JhdGlvblN1YnRhc2tzEkAuZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5MaXN0TWlncmF0aW9uU3VidGFza3NSZXF1ZXN0
GkEuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5MaXN0TWlncmF0aW9uU3Vi
dGFza3NSZXNwb25zZSJJgtPkkwI6EjgvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3dvcmtmbG93cy8qfS9zdWJ0YXNrc9pBBnBhcmVudBpUykEgYmlncXVlcnltaWdyYXRp
b24uZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtQtEBCiZjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52
MkIVTWlncmF0aW9uU2VydmljZVByb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVl
cnkvbWlncmF0aW9uL2FwaXYyL21pZ3JhdGlvbnBiO21pZ3JhdGlvbnBiqgIiR29vZ2xlLkNs
b3VkLkJpZ1F1ZXJ5Lk1pZ3JhdGlvbi5WMsoCIkdvb2dsZVxDbG91ZFxCaWdRdWVyeVxNaWdy
YXRpb25cVjJKvjgKBxIFDgD/AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgBFCgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMaAD8KCQoCCCUSAxoA
PwoICgEIEgMbAFsKCQoCCAsSAxsAWwoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADYK
CQoCCAgSAx0ANgoICgEIEgMeAD8KCQoCCAESAx4APwoICgEIEgMfAEAKCQoCCCkSAx8AQAov
CgIGABIEIgBqARojIFNlcnZpY2UgdG8gaGFuZGxlIEVEVyBtaWdyYXRpb25zLgoKCgoDBgAB
EgMiCBgKCgoDBgADEgMjAkgKDAoFBgADmQgSAyMCSAoLCgMGAAMSBCQCJTcKDQoFBgADmggS
BCQCJTcKLQoEBgACABIEKAIvAxofIENyZWF0ZXMgYSBtaWdyYXRpb24gd29ya2Zsb3cuCgoM
CgUGAAIAARIDKAYdCgwKBQYAAgACEgMoHjwKDAoFBgACAAMSAykPIAoNCgUGAAIABBIEKgQt
BgoRCgkGAAIABLDKvCISBCoELQYKDAoFBgACAAQSAy4ERwoPCggGAAIABJsIABIDLgRHCj0K
BAYAAgESBDICOAMaLyBHZXRzIGEgcHJldmlvdXNseSBjcmVhdGVkIG1pZ3JhdGlvbiB3b3Jr
Zmxvdy4KCgwKBQYAAgEBEgMyBhoKDAoFBgACAQISAzIbNgoMCgUGAAIBAxIDMw8gCg0KBQYA
AgEEEgQ0BDYGChEKCQYAAgEEsMq8IhIENAQ2BgoMCgUGAAIBBBIDNwQyCg8KCAYAAgEEmwgA
EgM3BDIKPAoEBgACAhIEOwJBAxouIExpc3RzIHByZXZpb3VzbHkgY3JlYXRlZCBtaWdyYXRp
b24gd29ya2Zsb3cuCgoMCgUGAAICARIDOwYcCgwKBQYAAgICEgM7HToKDAoFBgACAgMSAzwP
LQoNCgUGAAICBBIEPQQ/BgoRCgkGAAICBLDKvCISBD0EPwYKDAoFBgACAgQSA0AENAoPCggG
AAICBJsIABIDQAQ0CjUKBAYAAgMSBEQCSgMaJyBEZWxldGVzIGEgbWlncmF0aW9uIHdvcmtm
bG93IGJ5IG5hbWUuCgoMCgUGAAIDARIDRAYdCgwKBQYAAgMCEgNEHjwKDAoFBgACAwMSA0UP
JAoNCgUGAAIDBBIERgRIBgoRCgkGAAIDBLDKvCISBEYESAYKDAoFBgACAwQSA0kEMgoPCggG
AAIDBJsIABIDSQQyCvcBCgQGAAIEEgRQAlcDGugBIFN0YXJ0cyBhIHByZXZpb3VzbHkgY3Jl
YXRlZCBtaWdyYXRpb24gd29ya2Zsb3cuIEkuZS4sIHRoZSBzdGF0ZSB0cmFuc2l0aW9ucwog
ZnJvbSBEUkFGVCB0byBSVU5OSU5HLiBUaGlzIGlzIGEgbm8tb3AgaWYgdGhlIHN0YXRlIGlz
IGFscmVhZHkgUlVOTklORy4KIEFuIGVycm9yIHdpbGwgYmUgc2lnbmFsZWQgaWYgdGhlIHN0
YXRlIGlzIGFueXRoaW5nIG90aGVyIHRoYW4gRFJBRlQgb3IKIFJVTk5JTkcuCgoMCgUGAAIE
ARIDUAYcCgwKBQYAAgQCEgNQHToKDAoFBgACBAMSA1EPJAoNCgUGAAIEBBIEUgRVBgoRCgkG
AAIEBLDKvCISBFIEVQYKDAoFBgACBAQSA1YEMgoPCggGAAIEBJsIABIDVgQyCjwKBAYAAgUS
BFoCYAMaLiBHZXRzIGEgcHJldmlvdXNseSBjcmVhdGVkIG1pZ3JhdGlvbiBzdWJ0YXNrLgoK
DAoFBgACBQESA1oGGQoMCgUGAAIFAhIDWho0CgwKBQYAAgUDEgNbDx8KDQoFBgACBQQSBFwE
XgYKEQoJBgACBQSwyrwiEgRcBF4GCgwKBQYAAgUEEgNfBDIKDwoIBgACBQSbCAASA18EMgo8
CgQGAAIGEgRjAmkDGi4gTGlzdHMgcHJldmlvdXNseSBjcmVhdGVkIG1pZ3JhdGlvbiBzdWJ0
YXNrcy4KCgwKBQYAAgYBEgNjBhsKDAoFBgACBgISA2McOAoMCgUGAAIGAxIDZA8sCg0KBQYA
AgYEEgRlBGcGChEKCQYAAgYEsMq8IhIEZQRnBgoMCgUGAAIGBBIDaAQ0Cg8KCAYAAgYEmwgA
EgNoBDQKPgoCBAASBG0AegEaMiBSZXF1ZXN0IHRvIGNyZWF0ZSBhIG1pZ3JhdGlvbiB3b3Jr
ZmxvdyByZXNvdXJjZS4KCgoKAwQAARIDbQgmCoIBCgQEAAIAEgRwAnUEGnQgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBwcm9qZWN0IHRvIHdoaWNoIHRoaXMgbWlncmF0aW9uIHdvcmtm
bG93IGJlbG9uZ3MuCiBFeGFtcGxlOiBgcHJvamVjdHMvZm9vL2xvY2F0aW9ucy9iYXJgCgoM
CgUEAAIABRIDcAIICgwKBQQAAgABEgNwCQ8KDAoFBAACAAMSA3ASEwoNCgUEAAIACBIEcBR1
AwoPCggEAAIACJwIABIDcQQqCg8KBwQAAgAInwgSBHIEdAUKOwoEBAACARIEeAJ5LxotIFJl
cXVpcmVkLiBUaGUgbWlncmF0aW9uIHdvcmtmbG93IHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgN4
AhMKDAoFBAACAQESA3gUJgoMCgUEAAIBAxIDeCkqCgwKBQQAAgEIEgN5Bi4KDwoIBAACAQic
CAASA3kHLQpICgIEARIFfQCJAQEaOyBBIHJlcXVlc3QgdG8gZ2V0IGEgcHJldmlvdXNseSBj
cmVhdGVkIG1pZ3JhdGlvbiB3b3JrZmxvdy4KCgoKAwQBARIDfQgjCoIBCgQEAQIAEgaAAQKF
AQQaciBSZXF1aXJlZC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUgbWlncmF0aW9u
IHdvcmtmbG93LgogRXhhbXBsZTogYHByb2plY3RzLzEyMy9sb2NhdGlvbnMvdXMvd29ya2Zs
b3dzLzEyMzRgCgoNCgUEAQIABRIEgAECCAoNCgUEAQIAARIEgAEJDQoNCgUEAQIAAxIEgAEQ
EQoPCgUEAQIACBIGgAEShQEDChAKCAQBAgAInAgAEgSBAQQqChEKBwQBAgAInwgSBoIBBIQB
BQozCgQEAQIBEgSIAQIqGiUgVGhlIGxpc3Qgb2YgZmllbGRzIHRvIGJlIHJldHJpZXZlZC4K
Cg0KBQQBAgEGEgSIAQIbCg0KBQQBAgEBEgSIARwlCg0KBQQBAgEDEgSIASgpCkkKAgQCEgaM
AQCjAQEaOyBBIHJlcXVlc3QgdG8gbGlzdCBwcmV2aW91c2x5IGNyZWF0ZWQgbWlncmF0aW9u
IHdvcmtmbG93cy4KCgsKAwQCARIEjAEIJQp+CgQEAgIAEgaPAQKUAQQabiBSZXF1aXJlZC4g
VGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIG9mIHRoZSBtaWdyYXRpb24gd29ya2Zsb3dzIHRv
IGxpc3QuCiBFeGFtcGxlOiBgcHJvamVjdHMvMTIzL2xvY2F0aW9ucy91c2AKCg0KBQQCAgAF
EgSPAQIICg0KBQQCAgABEgSPAQkPCg0KBQQCAgADEgSPARITCg8KBQQCAgAIEgaPARSUAQMK
EAoIBAICAAicCAASBJABBCoKEQoHBAICAAifCBIGkQEEkwEFCjMKBAQCAgESBJcBAioaJSBU
aGUgbGlzdCBvZiBmaWVsZHMgdG8gYmUgcmV0cmlldmVkLgoKDQoFBAICAQYSBJcBAhsKDQoF
BAICAQESBJcBHCUKDQoFBAICAQMSBJcBKCkKdAoEBAICAhIEmwECFhpmIFRoZSBtYXhpbXVt
IG51bWJlciBvZiBtaWdyYXRpb24gd29ya2Zsb3dzIHRvIHJldHVybi4gVGhlIHNlcnZpY2Ug
bWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIG51bWJlci4KCg0KBQQCAgIFEgSbAQIHCg0K
BQQCAgIBEgSbAQgRCg0KBQQCAgIDEgSbARQVCoMCCgQEAgIDEgSiAQIYGvQBIEEgcGFnZSB0
b2tlbiwgcmVjZWl2ZWQgZnJvbSBwcmV2aW91cyBgTGlzdE1pZ3JhdGlvbldvcmtmbG93c2Ag
Y2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoK
IFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExp
c3RNaWdyYXRpb25Xb3JrZmxvd3NgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlk
ZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEAgIDBRIEogECCAoNCgUEAgIDARIEogEJEwoNCgUE
AgIDAxIEogEWFwpECgIEAxIGpgEArQEBGjYgUmVzcG9uc2Ugb2JqZWN0IGZvciBhIGBMaXN0
TWlncmF0aW9uV29ya2Zsb3dzYCBjYWxsLgoKCwoDBAMBEgSmAQgmCk0KBAQDAgASBKgBAjUa
PyBUaGUgbWlncmF0aW9uIHdvcmtmbG93cyBmb3IgdGhlIHNwZWNpZmllZCBwcm9qZWN0IC8g
bG9jYXRpb24uCgoNCgUEAwIABBIEqAECCgoNCgUEAwIABhIEqAELHAoNCgUEAwIAARIEqAEd
MAoNCgUEAwIAAxIEqAEzNAqQAQoEBAMCARIErAECHRqBASBBIHRva2VuLCB3aGljaCBjYW4g
YmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElm
IHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMu
CgoNCgUEAwIBBRIErAECCAoNCgUEAwIBARIErAEJGAoNCgUEAwIBAxIErAEbHApMCgIEBBIG
sAEAuQEBGj4gQSByZXF1ZXN0IHRvIGRlbGV0ZSBhIHByZXZpb3VzbHkgY3JlYXRlZCBtaWdy
YXRpb24gd29ya2Zsb3cuCgoLCgMEBAESBLABCCYKggEKBAQEAgASBrMBArgBBBpyIFJlcXVp
cmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBtaWdyYXRpb24gd29ya2Zsb3cu
CiBFeGFtcGxlOiBgcHJvamVjdHMvMTIzL2xvY2F0aW9ucy91cy93b3JrZmxvd3MvMTIzNGAK
Cg0KBQQEAgAFEgSzAQIICg0KBQQEAgABEgSzAQkNCg0KBQQEAgADEgSzARARCg8KBQQEAgAI
EgazARK4AQMKEAoIBAQCAAicCAASBLQBBCoKEQoHBAQCAAifCBIGtQEEtwEFCksKAgQFEga8
AQDFAQEaPSBBIHJlcXVlc3QgdG8gc3RhcnQgYSBwcmV2aW91c2x5IGNyZWF0ZWQgbWlncmF0
aW9uIHdvcmtmbG93LgoKCwoDBAUBEgS8AQglCoIBCgQEBQIAEga/AQLEAQQaciBSZXF1aXJl
ZC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUgbWlncmF0aW9uIHdvcmtmbG93Lgog
RXhhbXBsZTogYHByb2plY3RzLzEyMy9sb2NhdGlvbnMvdXMvd29ya2Zsb3dzLzEyMzRgCgoN
CgUEBQIABRIEvwECCAoNCgUEBQIAARIEvwEJDQoNCgUEBQIAAxIEvwEQEQoPCgUEBQIACBIG
vwESxAEDChAKCAQFAgAInAgAEgTAAQQqChEKBwQFAgAInwgSBsEBBMMBBQpJCgIEBhIGyAEA
1QEBGjsgQSByZXF1ZXN0IHRvIGdldCBhIHByZXZpb3VzbHkgY3JlYXRlZCBtaWdyYXRpb24g
c3VidGFza3MuCgoLCgMEBgESBMgBCCIKjgEKBAQGAgASBssBAtABBBp+IFJlcXVpcmVkLiBU
aGUgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRoZSBtaWdyYXRpb24gc3VidGFzay4KIEV4YW1w
bGU6IGBwcm9qZWN0cy8xMjMvbG9jYXRpb25zL3VzL3dvcmtmbG93cy8xMjM0L3N1YnRhc2tz
LzU0M2AKCg0KBQQGAgAFEgTLAQIICg0KBQQGAgABEgTLAQkNCg0KBQQGAgADEgTLARARCg8K
BQQGAgAIEgbLARLQAQMKEAoIBAYCAAicCAASBMwBBCoKEQoHBAYCAAifCBIGzQEEzwEFCj8K
BAQGAgESBtMBAtQBLxovIE9wdGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gYmUgcmV0
cmlldmVkLgoKDQoFBAYCAQYSBNMBAhsKDQoFBAYCAQESBNMBHCUKDQoFBAYCAQMSBNMBKCkK
DQoFBAYCAQgSBNQBBi4KEAoIBAYCAQicCAASBNQBBy0KSAoCBAcSBtgBAPUBARo6IEEgcmVx
dWVzdCB0byBsaXN0IHByZXZpb3VzbHkgY3JlYXRlZCBtaWdyYXRpb24gc3VidGFza3MuCgoL
CgMEBwESBNgBCCQKfAoEBAcCABIG2wEC4AEEGmwgUmVxdWlyZWQuIFRoZSBtaWdyYXRpb24g
dGFzayBvZiB0aGUgc3VidGFza3MgdG8gbGlzdC4KIEV4YW1wbGU6IGBwcm9qZWN0cy8xMjMv
bG9jYXRpb25zL3VzL3dvcmtmbG93cy8xMjM0YAoKDQoFBAcCAAUSBNsBAggKDQoFBAcCAAES
BNsBCQ8KDQoFBAcCAAMSBNsBEhMKDwoFBAcCAAgSBtsBFOABAwoQCggEBwIACJwIABIE3AEE
KgoRCgcEBwIACJ8IEgbdAQTfAQUKPwoEBAcCARIG4wEC5AEvGi8gT3B0aW9uYWwuIFRoZSBs
aXN0IG9mIGZpZWxkcyB0byBiZSByZXRyaWV2ZWQuCgoNCgUEBwIBBhIE4wECGwoNCgUEBwIB
ARIE4wEcJQoNCgUEBwIBAxIE4wEoKQoNCgUEBwIBCBIE5AEGLgoQCggEBwIBCJwIABIE5AEH
LQp6CgQEBwICEgToAQI/GmwgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBtaWdy
YXRpb24gdGFza3MgdG8gcmV0dXJuLiBUaGUgc2VydmljZSBtYXkKIHJldHVybiBmZXdlciB0
aGFuIHRoaXMgbnVtYmVyLgoKDQoFBAcCAgUSBOgBAgcKDQoFBAcCAgESBOgBCBEKDQoFBAcC
AgMSBOgBFBUKDQoFBAcCAggSBOgBFj4KEAoIBAcCAgicCAASBOgBFz0KiwIKBAQHAgMSBO8B
AkEa/AEgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBwcmV2aW91cyBg
TGlzdE1pZ3JhdGlvblN1YnRhc2tzYAogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZl
IHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFy
YW1ldGVycyBwcm92aWRlZCB0byBgTGlzdE1pZ3JhdGlvblN1YnRhc2tzYAogbXVzdCBtYXRj
aCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAcCAwUSBO8B
AggKDQoFBAcCAwESBO8BCRMKDQoFBAcCAwMSBO8BFhcKDQoFBAcCAwgSBO8BGEAKEAoIBAcC
AwicCAASBO8BGT8K2QEKBAQHAgQSBPQBAj0aygEgT3B0aW9uYWwuIFRoZSBmaWx0ZXIgdG8g
YXBwbHkuIFRoaXMgY2FuIGJlIHVzZWQgdG8gZ2V0IHRoZSBzdWJ0YXNrcyBvZiBhCiBzcGVj
aWZpYyB0YXNrcyBpbiBhIHdvcmtmbG93LCBlLmcuIGBtaWdyYXRpb25fdGFzayA9ICJhYjAx
MiJgIHdoZXJlCiBgImFiMDEyImAgaXMgdGhlIHRhc2sgSUQgKG5vdCB0aGUgbmFtZSBpbiB0
aGUgbmFtZWQgbWFwKS4KCg0KBQQHAgQFEgT0AQIICg0KBQQHAgQBEgT0AQkPCg0KBQQHAgQD
EgT0ARITCg0KBQQHAgQIEgT0ARQ8ChAKCAQHAgQInAgAEgT0ARU7CkMKAgQIEgb4AQD/AQEa
NSBSZXNwb25zZSBvYmplY3QgZm9yIGEgYExpc3RNaWdyYXRpb25TdWJ0YXNrc2AgY2FsbC4K
CgsKAwQIARIE+AEIJQo+CgQECAIAEgT6AQIzGjAgVGhlIG1pZ3JhdGlvbiBzdWJ0YXNrcyBm
b3IgdGhlIHNwZWNpZmllZCB0YXNrLgoKDQoFBAgCAAQSBPoBAgoKDQoFBAgCAAYSBPoBCxsK
DQoFBAgCAAESBPoBHC4KDQoFBAgCAAMSBPoBMTIKkAEKBAQIAgESBP4BAh0agQEgQSB0b2tl
biwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJz
ZXF1ZW50IHBhZ2VzLgoKDQoFBAgCAQUSBP4BAggKDQoFBAgCAQESBP4BCRgKDQoFBAgCAQMS
BP4BGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest ===
    # Fields for CreateMigrationWorkflowRequest
    # Field: parent Type: 9 ()
    # Field: migration_workflow Type: 11 (.google.cloud.bigquery.migration.v2.MigrationWorkflow)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationWorkflowRequest ===
    # Fields for GetMigrationWorkflowRequest
    # Field: name Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsRequest ===
    # Fields for ListMigrationWorkflowsRequest
    # Field: parent Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsResponse ===
    # Fields for ListMigrationWorkflowsResponse
    # Field: migration_workflows Type: 11 (.google.cloud.bigquery.migration.v2.MigrationWorkflow)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::DeleteMigrationWorkflowRequest ===
    # Fields for DeleteMigrationWorkflowRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::StartMigrationWorkflowRequest ===
    # Fields for StartMigrationWorkflowRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationSubtaskRequest ===
    # Fields for GetMigrationSubtaskRequest
    # Field: name Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksRequest ===
    # Fields for ListMigrationSubtasksRequest
    # Field: parent Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksResponse ===
    # Fields for ListMigrationSubtasksResponse
    # Field: migration_subtasks Type: 11 (.google.cloud.bigquery.migration.v2.MigrationSubtask)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::Migration::V2::MigrationService::MigrationServiceClient ===
package Google::Cloud::Bigquery::Migration::V2::MigrationService::MigrationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Migration::V2::MigrationService::MigrationServiceClient

Client stub representing the remote C<MigrationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'CreateMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow',
    });
}

sub get_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'GetMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow',
    });
}

sub list_migration_workflows {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'ListMigrationWorkflows',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsResponse',
    });
}

sub delete_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::DeleteMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'DeleteMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub start_migration_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::StartMigrationWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'StartMigrationWorkflow',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_migration_subtask {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationSubtaskRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'GetMigrationSubtask',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationSubtask',
    });
}

sub list_migration_subtasks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2.MigrationService',
        method         => 'ListMigrationSubtasks',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::MigrationService - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/migration_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::MigrationService;

    my $msg = Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest->new({
        parent => $parent,
        migration_workflow => $migration_workflow,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/migration_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest

Request to create a migration workflow resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project to which this migration workflow belongs.
Example: `projects/foo/locations/bar`

=item * C<< $msg->migration_workflow() >> / C<< $msg->migration_workflow($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow>)

Required. The migration workflow to create.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationWorkflowRequest

A request to get a previously created migration workflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration workflow.
Example: `projects/123/locations/us/workflows/1234`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be retrieved.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsRequest

A request to list previously created migration workflows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location of the migration workflows to list.
Example: `projects/123/locations/us`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be retrieved.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of migration workflows to return. The service may return
fewer than this number.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from previous `ListMigrationWorkflows` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListMigrationWorkflows`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsResponse

Response object for a `ListMigrationWorkflows` call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->migration_workflows() >> / C<< $msg->migration_workflows($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow>)

The migration workflows for the specified project / location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::DeleteMigrationWorkflowRequest

A request to delete a previously created migration workflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration workflow.
Example: `projects/123/locations/us/workflows/1234`

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::StartMigrationWorkflowRequest

A request to start a previously created migration workflow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration workflow.
Example: `projects/123/locations/us/workflows/1234`

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationSubtaskRequest

A request to get a previously created migration subtasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the migration subtask.
Example: `projects/123/locations/us/workflows/1234/subtasks/543`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to be retrieved.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksRequest

A request to list previously created migration subtasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The migration task of the subtasks to list.
Example: `projects/123/locations/us/workflows/1234`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to be retrieved.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of migration tasks to return. The service may
return fewer than this number.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from previous `ListMigrationSubtasks`
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListMigrationSubtasks`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply. This can be used to get the subtasks of a
specific tasks in a workflow, e.g. `migration_task = "ab012"` where
`"ab012"` is the task ID (not the name in the named map).

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksResponse

Response object for a `ListMigrationSubtasks` call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->migration_subtasks() >> / C<< $msg->migration_subtasks($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationSubtask>)

The migration subtasks for the specified task.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::MigrationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
