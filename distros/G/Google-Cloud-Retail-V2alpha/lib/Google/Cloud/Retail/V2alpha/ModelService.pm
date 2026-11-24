package Google::Cloud::Retail::V2alpha::ModelService;

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
    eval { require Google::Cloud::Retail::V2alpha::Model };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvbW9kZWxfc2VydmljZS5wcm90bxIbZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL3JldGFpbC92
MmFscGhhL21vZGVsLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90byKwAQoSQ3JlYXRlTW9kZWxSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC
+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50Ej0KBW1vZGVsGAIg
ASgLMiIuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLk1vZGVsQgPgQQJSBW1vZGVsEhwK
B2RyeV9ydW4YAyABKAhCA+BBAVIGZHJ5UnVuIpUBChJVcGRhdGVNb2RlbFJlcXVlc3QSPQoF
bW9kZWwYASABKAsyIi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTW9kZWxCA+BBAlIF
bW9kZWwSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNr
QgPgQQFSCnVwZGF0ZU1hc2siSgoPR2V0TW9kZWxSZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BB
AvpBHQobcmV0YWlsLmdvb2dsZWFwaXMuY29tL01vZGVsUgRuYW1lIkwKEVBhdXNlTW9kZWxS
ZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobcmV0YWlsLmdvb2dsZWFwaXMuY29tL01v
ZGVsUgRuYW1lIi0KElJlc3VtZU1vZGVsUmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5h
bWUimAEKEUxpc3RNb2RlbHNSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1yZXRh
aWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID
4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiJNChJE
ZWxldGVNb2RlbFJlcXVlc3QSNwoEbmFtZRgBIAEoCUIj4EEC+kEdChtyZXRhaWwuZ29vZ2xl
YXBpcy5jb20vTW9kZWxSBG5hbWUieAoSTGlzdE1vZGVsc1Jlc3BvbnNlEjoKBm1vZGVscxgB
IAMoCzIiLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Nb2RlbFIGbW9kZWxzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJLChBUdW5lTW9kZWxSZXF1ZXN0
EjcKBG5hbWUYASABKAlCI+BBAvpBHQobcmV0YWlsLmdvb2dsZWFwaXMuY29tL01vZGVsUgRu
YW1lIisKE0NyZWF0ZU1vZGVsTWV0YWRhdGESFAoFbW9kZWwYASABKAlSBW1vZGVsIikKEVR1
bmVNb2RlbE1ldGFkYXRhEhQKBW1vZGVsGAEgASgJUgVtb2RlbCITChFUdW5lTW9kZWxSZXNw
b25zZTLCDQoMTW9kZWxTZXJ2aWNlEo8CCgtDcmVhdGVNb2RlbBIvLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYS5DcmVhdGVNb2RlbFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uIq8BgtPkkwJDIjovdjJhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovY2F0YWxvZ3MvKn0vbW9kZWxzOgVtb2RlbNpBDHBhcmVudCxtb2RlbMpBVAohZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLk1vZGVsEi9nb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuQ3JlYXRlTW9kZWxNZXRhZGF0YRKnAQoIR2V0TW9kZWwSLC5nb29nbGUuY2xvdWQu
cmV0YWlsLnYyYWxwaGEuR2V0TW9kZWxSZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmFscGhhLk1vZGVsIkmC0+STAjwSOi92MmFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovY2F0YWxvZ3MvKi9tb2RlbHMvKn3aQQRuYW1lErQBCgpQYXVzZU1vZGVsEi4uZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlBhdXNlTW9kZWxSZXF1ZXN0GiIuZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhLk1vZGVsIlKC0+STAkUiQC92MmFscGhhL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKi9tb2RlbHMvKn06cGF1c2U6ASraQQRuYW1l
ErcBCgtSZXN1bWVNb2RlbBIvLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5SZXN1bWVN
b2RlbFJlcXVlc3QaIi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTW9kZWwiU4LT5JMC
RiJBL3YyYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL21v
ZGVscy8qfTpyZXN1bWU6ASraQQRuYW1lEqEBCgtEZWxldGVNb2RlbBIvLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJhbHBoYS5EZWxldGVNb2RlbFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHkiSYLT5JMCPCo6L3YyYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9j
YXRhbG9ncy8qL21vZGVscy8qfdpBBG5hbWUSugEKCkxpc3RNb2RlbHMSLi5nb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEuTGlzdE1vZGVsc1JlcXVlc3QaLy5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuTGlzdE1vZGVsc1Jlc3BvbnNlIkuC0+STAjwSOi92MmFscGhhL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9tb2RlbHPaQQZwYXJlbnQS
xwEKC1VwZGF0ZU1vZGVsEi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlVwZGF0ZU1v
ZGVsUmVxdWVzdBoiLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Nb2RlbCJjgtPkkwJJ
MkAvdjJhbHBoYS97bW9kZWwubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dz
LyovbW9kZWxzLyp9OgVtb2RlbNpBEW1vZGVsLHVwZGF0ZV9tYXNrEo4CCglUdW5lTW9kZWwS
LS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuVHVuZU1vZGVsUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24isgGC0+STAkQiPy92MmFscGhhL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKi9tb2RlbHMvKn06dHVuZToBKtpBBG5hbWXK
QV4KLWdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5UdW5lTW9kZWxSZXNwb25zZRItZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlR1bmVNb2RlbE1ldGFkYXRhGknKQRVyZXRhaWwu
Z29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3Vk
LXBsYXRmb3JtQtUBCh9jb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhQhFNb2RlbFNl
cnZpY2VQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2MmFscGhhL3Jl
dGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIbR29vZ2xlLkNsb3VkLlJldGFpbC5WMkFscGhh
ygIbR29vZ2xlXENsb3VkXFJldGFpbFxWMmFscGhh6gIeR29vZ2xlOjpDbG91ZDo6UmV0YWls
OjpWMmFscGhhSo87CgcSBQ4AhgIcCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAkCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYAMQoJCgIDBRIDFwAtCgkKAgMGEgMYACUKCQoCAwcSAxkAKgoICgEIEgMb
ADgKCQoCCCUSAxsAOAoICgEIEgMcAE4KCQoCCAsSAxwATgoICgEIEgMdACIKCQoCCAoSAx0A
IgoICgEIEgMeADIKCQoCCAgSAx4AMgoICgEIEgMfADgKCQoCCAESAx8AOAoICgEIEgMgACQK
CQoCCCQSAyAAJAoICgEIEgMhADgKCQoCCCkSAyEAOAoICgEIEgMiADcKCQoCCC0SAyIANwqd
BAoCBgASBTAAhAEBGo8EIFNlcnZpY2UgZm9yIHBlcmZvcm1pbmcgQ1JVRCBvcGVyYXRpb25z
IG9uIG1vZGVscy4KIFJlY29tbWVuZGF0aW9uIG1vZGVscyBjb250YWluIGFsbCB0aGUgbWV0
YWRhdGEgbmVjZXNzYXJ5IHRvIGdlbmVyYXRlIGEgc2V0IG9mCiBtb2RlbHMgZm9yIHRoZSBg
UHJlZGljdCgpYCBBUEkuIEEgbW9kZWwgaXMgcXVlcmllZAogaW5kaXJlY3RseSB2aWEgYSBT
ZXJ2aW5nQ29uZmlnLCB3aGljaCBhc3NvY2lhdGVzIGEgbW9kZWwgd2l0aCBhCiBnaXZlbiBQ
bGFjZW1lbnQgKGUuZy4gRnJlcXVlbnRseSBCb3VnaHQgVG9nZXRoZXIgb24gSG9tZSBQYWdl
KS4KCiBUaGlzIHNlcnZpY2UgYWxsb3dzIHlvdSB0byBkbyB0aGUgZm9sbG93aW5nOgoKICog
SW5pdGlhdGUgdHJhaW5pbmcgb2YgYSBtb2RlbC4KICogUGF1c2UgdHJhaW5pbmcgb2YgYW4g
ZXhpc3RpbmcgbW9kZWwuCiAqIExpc3QgYWxsIHRoZSBhdmFpbGFibGUgbW9kZWxzIGFsb25n
IHdpdGggdGhlaXIgbWV0YWRhdGEuCiAqIENvbnRyb2wgdGhlaXIgdHVuaW5nIHNjaGVkdWxl
LgoKCgoDBgABEgMwCBQKCgoDBgADEgMxAj0KDAoFBgADmQgSAzECPQoLCgMGAAMSBDICMzcK
DQoFBgADmggSBDICMzcKJAoEBgACABIENgJAAxoWIENyZWF0ZXMgYSBuZXcgbW9kZWwuCgoM
CgUGAAIAARIDNgYRCgwKBQYAAgACEgM2EiQKDAoFBgACAAMSAzYvSwoNCgUGAAIABBIENwQ6
BgoRCgkGAAIABLDKvCISBDcEOgYKDAoFBgACAAQSAzsEOgoPCggGAAIABJsIABIDOwQ6Cg0K
BQYAAgAEEgQ8BD8GCg8KBwYAAgAEmQgSBDwEPwYKHQoEBgACARIEQwJIAxoPIEdldHMgYSBt
b2RlbC4KCgwKBQYAAgEBEgNDBg4KDAoFBgACAQISA0MPHgoMCgUGAAIBAxIDQykuCg0KBQYA
AgEEEgREBEYGChEKCQYAAgEEsMq8IhIERARGBgoMCgUGAAIBBBIDRwQyCg8KCAYAAgEEmwgA
EgNHBDIKOQoEBgACAhIESwJRAxorIFBhdXNlcyB0aGUgdHJhaW5pbmcgb2YgYW4gZXhpc3Rp
bmcgbW9kZWwuCgoMCgUGAAICARIDSwYQCgwKBQYAAgICEgNLESIKDAoFBgACAgMSA0stMgoN
CgUGAAICBBIETARPBgoRCgkGAAICBLDKvCISBEwETwYKDAoFBgACAgQSA1AEMgoPCggGAAIC
BJsIABIDUAQyCjoKBAYAAgMSBFQCWgMaLCBSZXN1bWVzIHRoZSB0cmFpbmluZyBvZiBhbiBl
eGlzdGluZyBtb2RlbC4KCgwKBQYAAgMBEgNUBhEKDAoFBgACAwISA1QSJAoMCgUGAAIDAxID
VC80Cg0KBQYAAgMEEgRVBFgGChEKCQYAAgMEsMq8IhIEVQRYBgoMCgUGAAIDBBIDWQQyCg8K
CAYAAgMEmwgAEgNZBDIKKgoEBgACBBIEXQJiAxocIERlbGV0ZXMgYW4gZXhpc3RpbmcgbW9k
ZWwuCgoMCgUGAAIEARIDXQYRCgwKBQYAAgQCEgNdEiQKDAoFBgACBAMSA10vRAoNCgUGAAIE
BBIEXgRgBgoRCgkGAAIEBLDKvCISBF4EYAYKDAoFBgACBAQSA2EEMgoPCggGAAIEBJsIABID
YQQyCkAKBAYAAgUSBGUCagMaMiBMaXN0cyBhbGwgdGhlIG1vZGVscyBsaW5rZWQgdG8gdGhp
cyBldmVudCBzdG9yZS4KCgwKBQYAAgUBEgNlBhAKDAoFBgACBQISA2URIgoMCgUGAAIFAxID
ZS0/Cg0KBQYAAgUEEgRmBGgGChEKCQYAAgUEsMq8IhIEZgRoBgoMCgUGAAIFBBIDaQQ0Cg8K
CAYAAgUEmwgAEgNpBDQKyAEKBAYAAgYSBHACdgMauQEgVXBkYXRlIG9mIG1vZGVsIG1ldGFk
YXRhLiBPbmx5IGZpZWxkcyB0aGF0CiBjdXJyZW50bHkgY2FuIGJlIHVwZGF0ZWQgYXJlOiBg
ZmlsdGVyaW5nX29wdGlvbmAgYW5kCiBgcGVyaW9kaWNfdHVuaW5nX3N0YXRlYC4KIElmIG90
aGVyIHZhbHVlcyBhcmUgcHJvdmlkZWQsIHRoaXMgQVBJIG1ldGhvZCBpZ25vcmVzIHRoZW0u
CgoMCgUGAAIGARIDcAYRCgwKBQYAAgYCEgNwEiQKDAoFBgACBgMSA3AvNAoNCgUGAAIGBBIE
cQR0BgoRCgkGAAIGBLDKvCISBHEEdAYKDAoFBgACBgQSA3UEPwoPCggGAAIGBJsIABIDdQQ/
CikKBAYAAgcSBXkCgwEDGhogVHVuZXMgYW4gZXhpc3RpbmcgbW9kZWwuCgoMCgUGAAIHARID
eQYPCgwKBQYAAgcCEgN5ECAKDAoFBgACBwMSA3krRwoNCgUGAAIHBBIEegR9BgoRCgkGAAIH
BLDKvCISBHoEfQYKDAoFBgACBwQSA34EMgoPCggGAAIHBJsIABIDfgQyCg4KBQYAAgcEEgV/
BIIBBgoQCgcGAAIHBJkIEgV/BIIBBgotCgIEABIGhwEAlgEBGh8gUmVxdWVzdCBmb3IgY3Jl
YXRpbmcgYSBtb2RlbC4KCgsKAwQAARIEhwEIGgqkAQoEBAACABIGigECjQEEGpMBIFJlcXVp
cmVkLiBUaGUgcGFyZW50IHJlc291cmNlIHVuZGVyIHdoaWNoIHRvIGNyZWF0ZSB0aGUgbW9k
ZWwuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9j
YXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfWAKCg0KBQQAAgAFEgSKAQIICg0KBQQA
AgABEgSKAQkPCg0KBQQAAgADEgSKARITCg8KBQQAAgAIEgaKARSNAQMKEAoIBAACAAicCAAS
BIsBBCoKDwoHBAACAAifCBIEjAEETwpkCgQEAAIBEgSRAQI7GlYgUmVxdWlyZWQuIFRoZSBw
YXlsb2FkIG9mIHRoZSBbTW9kZWxdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Nb2Rl
bF0gIHRvCiBjcmVhdGUuCgoNCgUEAAIBBhIEkQECBwoNCgUEAAIBARIEkQEIDQoNCgUEAAIB
AxIEkQEQEQoNCgUEAAIBCBIEkQESOgoQCggEAAIBCJwIABIEkQETOQpyCgQEAAICEgSVAQI8
GmQgT3B0aW9uYWwuIFdoZXRoZXIgdG8gcnVuIGEgZHJ5IHJ1biB0byB2YWxpZGF0ZSB0aGUg
cmVxdWVzdCAod2l0aG91dAogYWN0dWFsbHkgY3JlYXRpbmcgdGhlIG1vZGVsKS4KCg0KBQQA
AgIFEgSVAQIGCg0KBQQAAgIBEgSVAQcOCg0KBQQAAgIDEgSVARESCg0KBQQAAgIIEgSVARM7
ChAKCAQAAgIInAgAEgSVARQ6CjcKAgQBEgaZAQCiAQEaKSBSZXF1ZXN0IGZvciB1cGRhdGlu
ZyBhbiBleGlzdGluZyBtb2RlbC4KCgsKAwQBARIEmQEIGgpeCgQEAQIAEgScAQI7GlAgUmVx
dWlyZWQuIFRoZSBib2R5IG9mIHRoZSB1cGRhdGVkCiBbTW9kZWxdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJhbHBoYS5Nb2RlbF0uCgoNCgUEAQIABhIEnAECBwoNCgUEAQIAARIEnAEIDQoN
CgUEAQIAAxIEnAEQEQoNCgUEAQIACBIEnAESOgoQCggEAQIACJwIABIEnAETOQqBAQoEBAEC
ARIGoAECoQEvGnEgT3B0aW9uYWwuIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHBy
b3ZpZGVkICdtb2RlbCcgdG8KIHVwZGF0ZS4gSWYgbm90IHNldCwgYnkgZGVmYXVsdCB1cGRh
dGVzIGFsbCBmaWVsZHMuCgoNCgUEAQIBBhIEoAECGwoNCgUEAQIBARIEoAEcJwoNCgUEAQIB
AxIEoAEqKwoNCgUEAQIBCBIEoQEGLgoQCggEAQIBCJwIABIEoQEHLQosCgIEAhIGpQEArQEB
Gh4gUmVxdWVzdCBmb3IgZ2V0dGluZyBhIG1vZGVsLgoKCwoDBAIBEgSlAQgXCssBCgQEAgIA
EgapAQKsAQQaugEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZQogW01vZGVs
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTW9kZWxdIHRvIGdldC4gRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0
YWxvZ3Mve2NhdGFsb2d9L21vZGVscy97bW9kZWxfaWR9YAoKDQoFBAICAAUSBKkBAggKDQoF
BAICAAESBKkBCQ0KDQoFBAICAAMSBKkBEBEKDwoFBAICAAgSBqkBEqwBAwoQCggEAgIACJwI
ABIEqgEEKgoPCgcEAgIACJ8IEgSrAQRNCjgKAgQDEgawAQC4AQEaKiBSZXF1ZXN0IGZvciBw
YXVzaW5nIHRyYWluaW5nIG9mIGEgbW9kZWwuCgoLCgMEAwESBLABCBkKogEKBAQDAgASBrQB
ArcBBBqRASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG1vZGVsIHRvIHBhdXNlLgogRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9p
ZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97bW9kZWxfaWR9YAoKDQoFBAMCAAUS
BLQBAggKDQoFBAMCAAESBLQBCQ0KDQoFBAMCAAMSBLQBEBEKDwoFBAMCAAgSBrQBErcBAwoQ
CggEAwIACJwIABIEtQEEKgoPCgcEAwIACJ8IEgS2AQRNCjkKAgQEEga7AQDAAQEaKyBSZXF1
ZXN0IGZvciByZXN1bWluZyB0cmFpbmluZyBvZiBhIG1vZGVsLgoKCwoDBAQBEgS7AQgaCqEB
CgQEBAIAEgS/AQI7GpIBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgbW9kZWwgdG8gcmVz
dW1lLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97bW9kZWxfaWR9YAoK
DQoFBAQCAAUSBL8BAggKDQoFBAQCAAESBL8BCQ0KDQoFBAQCAAMSBL8BEBEKDQoFBAQCAAgS
BL8BEjoKEAoIBAQCAAicCAASBL8BEzkKRgoCBAUSBsMBANMBARo4IFJlcXVlc3QgZm9yIGxp
c3RpbmcgbW9kZWxzIGFzc29jaWF0ZWQgd2l0aCBhIHJlc291cmNlLgoKCwoDBAUBEgTDAQgZ
CpUBCgQEBQIAEgbHAQLKAQQahAEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgZm9yIHdoaWNoIHRv
IGxpc3QgbW9kZWxzLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9j
YXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9YAoKDQoFBAUCAAUS
BMcBAggKDQoFBAUCAAESBMcBCQ8KDQoFBAUCAAMSBMcBEhMKDwoFBAUCAAgSBscBFMoBAwoQ
CggEBQIACJwIABIEyAEEKgoPCgcEBQIACJ8IEgTJAQRPCnoKBAQFAgESBM4BAj8abCBPcHRp
b25hbC4gTWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lm
aWVkLCBkZWZhdWx0cwogdG8gNTAuIE1heCBhbGxvd2VkIHZhbHVlIGlzIDEwMDAuCgoNCgUE
BQIBBRIEzgECBwoNCgUEBQIBARIEzgEIEQoNCgUEBQIBAxIEzgEUFQoNCgUEBQIBCBIEzgEW
PgoQCggEBQIBCJwIABIEzgEXPQqCAQoEBAUCAhIE0gECQRp0IE9wdGlvbmFsLiBBIHBhZ2Ug
dG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdE1vZGVsc2AKIGNhbGwuIFBy
b3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBAUCAgUS
BNIBAggKDQoFBAUCAgESBNIBCRMKDQoFBAUCAgMSBNIBFhcKDQoFBAUCAggSBNIBGEAKEAoI
BAUCAgicCAASBNIBGT8KLQoCBAYSBtYBAN4BARofIFJlcXVlc3QgZm9yIGRlbGV0aW5nIGEg
bW9kZWwuCgoLCgMEBgESBNYBCBoK0QEKBAQGAgASBtoBAt0BBBrAASBSZXF1aXJlZC4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlCiBbTW9kZWxdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5Nb2RlbF0gdG8gZGVsZXRlLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVt
YmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vbW9k
ZWxzL3ttb2RlbF9pZH1gCgoNCgUEBgIABRIE2gECCAoNCgUEBgIAARIE2gEJDQoNCgUEBgIA
AxIE2gEQEQoPCgUEBgIACBIG2gES3QEDChAKCAQGAgAInAgAEgTbAQQqCg8KBwQGAgAInwgS
BNwBBE0KLwoCBAcSBuEBAOcBARohIFJlc3BvbnNlIHRvIGEgTGlzdE1vZGVsUmVxdWVzdC4K
CgsKAwQHARIE4QEIGgofCgQEBwIAEgTjAQIcGhEgTGlzdCBvZiBNb2RlbHMuCgoNCgUEBwIA
BBIE4wECCgoNCgUEBwIABhIE4wELEAoNCgUEBwIAARIE4wERFwoNCgUEBwIAAxIE4wEaGwpK
CgQEBwIBEgTmAQIdGjwgUGFnaW5hdGlvbiB0b2tlbiwgaWYgbm90IHJldHVybmVkIGluZGlj
YXRlcyB0aGUgbGFzdCBwYWdlLgoKDQoFBAcCAQUSBOYBAggKDQoFBAcCAQESBOYBCRgKDQoF
BAcCAQMSBOYBGxwKhQEKAgQIEgbrAQDzAQEadyBSZXF1ZXN0IHRvIG1hbnVhbGx5IHN0YXJ0
IGEgdHVuaW5nIHByb2Nlc3Mgbm93IChpbnN0ZWFkIG9mIHdhaXRpbmcgZm9yCiB0aGUgcGVy
aW9kaWNhbGx5IHNjaGVkdWxlZCB0dW5pbmcgdG8gaGFwcGVuKS4KCgsKAwQIARIE6wEIGAqq
AQoEBAgCABIG7wEC8gEEGpkBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
bW9kZWwgdG8gdHVuZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xv
Y2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfS9tb2RlbHMve21v
ZGVsX2lkfWAKCg0KBQQIAgAFEgTvAQIICg0KBQQIAgABEgTvAQkNCg0KBQQIAgADEgTvARAR
Cg8KBQQIAgAIEgbvARLyAQMKEAoIBAgCAAicCAASBPABBCoKDwoHBAgCAAifCBIE8QEETQo8
CgIECRIG9gEA+wEBGi4gTWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIGEgY3JlYXRlIG9wZXJh
dGlvbi4KCgsKAwQJARIE9gEIGwqyAQoEBAkCABIE+gECExqjASBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgbW9kZWwgdGhhdCB0aGlzIGNyZWF0ZSBhcHBsaWVzIHRvLgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0
YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97bW9kZWxfaWR9YAoKDQoFBAkCAAUSBPoBAggK
DQoFBAkCAAESBPoBCQ4KDQoFBAkCAAMSBPoBERIKOgoCBAoSBv4BAIMCARosIE1ldGFkYXRh
IGFzc29jaWF0ZWQgd2l0aCBhIHR1bmUgb3BlcmF0aW9uLgoKCwoDBAoBEgT+AQgZCrABCgQE
CgIAEgSCAgITGqEBIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbCB0aGF0IHRoaXMg
dHVuZSBhcHBsaWVzIHRvLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0v
bG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97
bW9kZWxfaWR9YAoKDQoFBAoCAAUSBIICAggKDQoFBAoCAAESBIICCQ4KDQoFBAoCAAMSBIIC
ERIKOAoCBAsSBIYCABwaLCBSZXNwb25zZSBhc3NvY2lhdGVkIHdpdGggYSB0dW5lIG9wZXJh
dGlvbi4KCgsKAwQLARIEhgIIGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest ===
    # Fields for CreateModelRequest
    # Field: parent Type: 9 ()
    # Field: model Type: 11 (.google.cloud.retail.v2alpha.Model)
    # Field: dry_run Type: 8 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::UpdateModelRequest ===
    # Fields for UpdateModelRequest
    # Field: model Type: 11 (.google.cloud.retail.v2alpha.Model)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2alpha::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::PauseModelRequest ===
    # Fields for PauseModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::ResumeModelRequest ===
    # Fields for ResumeModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::DeleteModelRequest ===
    # Fields for DeleteModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.cloud.retail.v2alpha.Model)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::TuneModelRequest ===
    # Fields for TuneModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::CreateModelMetadata ===
    # Fields for CreateModelMetadata
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::TuneModelMetadata ===
    # Fields for TuneModelMetadata
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ModelService::TuneModelResponse ===
    # Fields for TuneModelResponse

# === Service Client: Google::Cloud::Retail::V2alpha::ModelService::ModelServiceClient ===
package Google::Cloud::Retail::V2alpha::ModelService::ModelServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::ModelService::ModelServiceClient

Client stub representing the remote C<ModelService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub create_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'CreateModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Model::Model',
    });
}

sub pause_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::PauseModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'PauseModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Model::Model',
    });
}

sub resume_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::ResumeModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'ResumeModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Model::Model',
    });
}

sub delete_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::DeleteModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'DeleteModel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ModelService::ListModelsResponse',
    });
}

sub update_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::UpdateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'UpdateModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Model::Model',
    });
}

sub tune_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ModelService::TuneModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ModelService',
        method         => 'TuneModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::ModelService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/model_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::ModelService;

    my $msg = Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest->new({
        parent => $parent,
        model => $model,
        dry_run => $dry_run,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/model_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest

Request for creating a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource under which to create the model. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Model::Model>)

Required. The payload of the [Model][google.cloud.retail.v2alpha.Model]  to
create.

=item * C<< $msg->dry_run() >> / C<< $msg->dry_run($value) >>

Type: C<Bool>

Optional. Whether to run a dry run to validate the request (without
actually creating the model).

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::UpdateModelRequest

Request for updating an existing model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Model::Model>)

Required. The body of the updated
[Model][google.cloud.retail.v2alpha.Model].

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided 'model' to
update. If not set, by default updates all fields.

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::GetModelRequest

Request for getting a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Model][google.cloud.retail.v2alpha.Model] to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::PauseModelRequest

Request for pausing training of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the model to pause.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::ResumeModelRequest

Request for resuming training of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the model to resume.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::ListModelsRequest

Request for listing models associated with a resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent for which to list models.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 50. Max allowed value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListModels`
call. Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::DeleteModelRequest

Request for deleting a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Model][google.cloud.retail.v2alpha.Model] to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::ListModelsResponse

Response to a ListModelRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Model::Model>)

List of Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::TuneModelRequest

Request to manually start a tuning process now (instead of waiting for
the periodically scheduled tuning to happen).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the model to tune.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::CreateModelMetadata

Metadata associated with a create operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The resource name of the model that this create applies to.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::TuneModelMetadata

Metadata associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The resource name of the model that this tune applies to.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ModelService::TuneModelResponse

Response associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::ModelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
