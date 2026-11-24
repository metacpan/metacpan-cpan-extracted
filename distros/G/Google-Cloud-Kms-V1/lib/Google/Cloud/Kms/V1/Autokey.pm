package Google::Cloud::Kms::V1::Autokey;

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
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQva21zL3YxL2F1dG9rZXkucHJvdG8SE2dvb2dsZS5jbG91ZC5rbXMu
djEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnBy
b3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90byLIAQoWQ3Jl
YXRlS2V5SGFuZGxlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25z
Lmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSJwoNa2V5X2hhbmRsZV9pZBgCIAEo
CUID4EEBUgtrZXlIYW5kbGVJZBJCCgprZXlfaGFuZGxlGAMgASgLMh4uZ29vZ2xlLmNsb3Vk
Lmttcy52MS5LZXlIYW5kbGVCA+BBAlIJa2V5SGFuZGxlIlQKE0dldEtleUhhbmRsZVJlcXVl
c3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9LZXlI
YW5kbGVSBG5hbWUiowIKCUtleUhhbmRsZRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSQgoH
a21zX2tleRgDIAEoCUIp4EED+kEjCiFjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9DcnlwdG9L
ZXlSBmttc0tleRI5ChZyZXNvdXJjZV90eXBlX3NlbGVjdG9yGAQgASgJQgPgQQJSFHJlc291
cmNlVHlwZVNlbGVjdG9yOn7qQXsKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0tleUhhbmRs
ZRI/cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2tleUhhbmRsZXMv
e2tleV9oYW5kbGV9KgprZXlIYW5kbGVzMglrZXlIYW5kbGUiGQoXQ3JlYXRlS2V5SGFuZGxl
TWV0YWRhdGEivQEKFUxpc3RLZXlIYW5kbGVzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBB
AvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSIAoJcGFn
ZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJ
cGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIigQEKFkxpc3RLZXlIYW5k
bGVzUmVzcG9uc2USPwoLa2V5X2hhbmRsZXMYASADKAsyHi5nb29nbGUuY2xvdWQua21zLnYx
LktleUhhbmRsZVIKa2V5SGFuZGxlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4ytAUKB0F1dG9rZXkS6wEKD0NyZWF0ZUtleUhhbmRsZRIrLmdvb2dsZS5jbG91
ZC5rbXMudjEuQ3JlYXRlS2V5SGFuZGxlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb24iiwGC0+STAjwiLi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
L2tleUhhbmRsZXM6CmtleV9oYW5kbGXaQR9wYXJlbnQsa2V5X2hhbmRsZSxrZXlfaGFuZGxl
X2lkykEkCglLZXlIYW5kbGUSF0NyZWF0ZUtleUhhbmRsZU1ldGFkYXRhEpcBCgxHZXRLZXlI
YW5kbGUSKC5nb29nbGUuY2xvdWQua21zLnYxLkdldEtleUhhbmRsZVJlcXVlc3QaHi5nb29n
bGUuY2xvdWQua21zLnYxLktleUhhbmRsZSI9gtPkkwIwEi4vdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9rZXlIYW5kbGVzLyp92kEEbmFtZRKqAQoOTGlzdEtleUhhbmRsZXMS
Ki5nb29nbGUuY2xvdWQua21zLnYxLkxpc3RLZXlIYW5kbGVzUmVxdWVzdBorLmdvb2dsZS5j
bG91ZC5rbXMudjEuTGlzdEtleUhhbmRsZXNSZXNwb25zZSI/gtPkkwIwEi4vdjEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9rZXlIYW5kbGVz2kEGcGFyZW50GnTKQRdjbG91
ZGttcy5nb29nbGVhcGlzLmNvbdJBV2h0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZGtt
c0JUChdjb20uZ29vZ2xlLmNsb3VkLmttcy52MUIMQXV0b2tleVByb3RvUAFaKWNsb3VkLmdv
b2dsZS5jb20vZ28va21zL2FwaXYxL2ttc3BiO2ttc3BiSvY8CgcSBQ4A1QEBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACYKCQoCAwES
AxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYALQoICgEIEgMYAEAKCQoCCAsS
AxgAQAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAC0KCQoCCAgSAxoALQoICgEIEgMb
ADAKCQoCCAESAxsAMArkCAoCBgASBC8AWAEa1wggUHJvdmlkZXMgaW50ZXJmYWNlcyBmb3Ig
dXNpbmcgW0Nsb3VkIEtNUwogQXV0b2tleV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2tt
cy9oZWxwL2F1dG9rZXkpIHRvIHByb3Zpc2lvbiBuZXcKIFtDcnlwdG9LZXlzXVtnb29nbGUu
Y2xvdWQua21zLnYxLkNyeXB0b0tleV0sIHJlYWR5IGZvciBDdXN0b21lciBNYW5hZ2VkCiBF
bmNyeXB0aW9uIEtleSAoQ01FSykgdXNlLCBvbi1kZW1hbmQuIFRvIHN1cHBvcnQgY2VydGFp
biBjbGllbnQgdG9vbGluZywgdGhpcwogZmVhdHVyZSBpcyBtb2RlbGVkIGFyb3VuZCBhIFtL
ZXlIYW5kbGVdW2dvb2dsZS5jbG91ZC5rbXMudjEuS2V5SGFuZGxlXQogcmVzb3VyY2U6IGNy
ZWF0aW5nIGEgW0tleUhhbmRsZV1bZ29vZ2xlLmNsb3VkLmttcy52MS5LZXlIYW5kbGVdIGlu
IGEgcmVzb3VyY2UKIHByb2plY3QgYW5kIGdpdmVuIGxvY2F0aW9uIHRyaWdnZXJzIENsb3Vk
IEtNUyBBdXRva2V5IHRvIHByb3Zpc2lvbiBhCiBbQ3J5cHRvS2V5XVtnb29nbGUuY2xvdWQu
a21zLnYxLkNyeXB0b0tleV0gaW4gdGhlIGNvbmZpZ3VyZWQga2V5IHByb2plY3QgYW5kCiB0
aGUgc2FtZSBsb2NhdGlvbi4KCiBQcmlvciB0byB1c2UgaW4gYSBnaXZlbiByZXNvdXJjZSBw
cm9qZWN0LAogW1VwZGF0ZUF1dG9rZXlDb25maWddW2dvb2dsZS5jbG91ZC5rbXMudjEuQXV0
b2tleUFkbWluLlVwZGF0ZUF1dG9rZXlDb25maWddCiBzaG91bGQgaGF2ZSBiZWVuIGNhbGxl
ZCBvbiBhbiBhbmNlc3RvciBmb2xkZXIsIHNldHRpbmcgdGhlIGtleSBwcm9qZWN0IHdoZXJl
CiBDbG91ZCBLTVMgQXV0b2tleSBzaG91bGQgY3JlYXRlIG5ldwogW0NyeXB0b0tleXNdW2dv
b2dsZS5jbG91ZC5rbXMudjEuQ3J5cHRvS2V5XS4gU2VlIGRvY3VtZW50YXRpb24gZm9yIGFk
ZGl0aW9uYWwKIHByZXJlcXVpc2l0ZXMuIFRvIGNoZWNrIHdoYXQga2V5IHByb2plY3QsIGlm
IGFueSwgaXMgY3VycmVudGx5IGNvbmZpZ3VyZWQgb24KIGEgcmVzb3VyY2UgcHJvamVjdCdz
IGFuY2VzdG9yIGZvbGRlciwgc2VlCiBbU2hvd0VmZmVjdGl2ZUF1dG9rZXlDb25maWddW2dv
b2dsZS5jbG91ZC5rbXMudjEuQXV0b2tleUFkbWluLlNob3dFZmZlY3RpdmVBdXRva2V5Q29u
ZmlnXS4KCgoKAwYAARIDLwgPCgoKAwYAAxIDMAI/CgwKBQYAA5kIEgMwAj8KCwoDBgADEgQx
AjMxCg0KBQYAA5oIEgQxAjMxCuoDCgQGAAIAEgQ8AkcDGtsDIENyZWF0ZXMgYSBuZXcgW0tl
eUhhbmRsZV1bZ29vZ2xlLmNsb3VkLmttcy52MS5LZXlIYW5kbGVdLCB0cmlnZ2VyaW5nIHRo
ZQogcHJvdmlzaW9uaW5nIG9mIGEgbmV3IFtDcnlwdG9LZXldW2dvb2dsZS5jbG91ZC5rbXMu
djEuQ3J5cHRvS2V5XSBmb3IgQ01FSwogdXNlIHdpdGggdGhlIGdpdmVuIHJlc291cmNlIHR5
cGUgaW4gdGhlIGNvbmZpZ3VyZWQga2V5IHByb2plY3QgYW5kIHRoZSBzYW1lCiBsb2NhdGlv
bi4gW0dldE9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMuR2V0T3Bl
cmF0aW9uXSBzaG91bGQKIGJlIHVzZWQgdG8gcmVzb2x2ZSB0aGUgcmVzdWx0aW5nIGxvbmct
cnVubmluZyBvcGVyYXRpb24gYW5kIGdldCB0aGUKIHJlc3VsdGluZyBbS2V5SGFuZGxlXVtn
b29nbGUuY2xvdWQua21zLnYxLktleUhhbmRsZV0gYW5kCiBbQ3J5cHRvS2V5XVtnb29nbGUu
Y2xvdWQua21zLnYxLkNyeXB0b0tleV0uCgoMCgUGAAIAARIDPAYVCgwKBQYAAgACEgM8FiwK
DAoFBgACAAMSAz0PKwoNCgUGAAIABBIEPgRBBgoRCgkGAAIABLDKvCISBD4EQQYKDAoFBgAC
AAQSA0IETQoPCggGAAIABJsIABIDQgRNCg0KBQYAAgAEEgRDBEYGCg8KBwYAAgAEmQgSBEME
RgYKRwoEBgACARIESgJPAxo5IFJldHVybnMgdGhlIFtLZXlIYW5kbGVdW2dvb2dsZS5jbG91
ZC5rbXMudjEuS2V5SGFuZGxlXS4KCgwKBQYAAgEBEgNKBhIKDAoFBgACAQISA0oTJgoMCgUG
AAIBAxIDSjE6Cg0KBQYAAgEEEgRLBE0GChEKCQYAAgEEsMq8IhIESwRNBgoMCgUGAAIBBBID
TgQyCg8KCAYAAgEEmwgAEgNOBDIKQgoEBgACAhIEUgJXAxo0IExpc3RzIFtLZXlIYW5kbGVz
XVtnb29nbGUuY2xvdWQua21zLnYxLktleUhhbmRsZV0uCgoMCgUGAAICARIDUgYUCgwKBQYA
AgICEgNSFSoKDAoFBgACAgMSA1I1SwoNCgUGAAICBBIEUwRVBgoRCgkGAAICBLDKvCISBFME
VQYKDAoFBgACAgQSA1YENAoPCggGAAICBJsIABIDVgQ0CmoKAgQAEgRcAG4BGl4gUmVxdWVz
dCBtZXNzYWdlIGZvcgogW0F1dG9rZXkuQ3JlYXRlS2V5SGFuZGxlXVtnb29nbGUuY2xvdWQu
a21zLnYxLkF1dG9rZXkuQ3JlYXRlS2V5SGFuZGxlXS4KCgoKAwQAARIDXAgeCrYBCgQEAAIA
EgRgAmUEGqcBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZSBwcm9qZWN0IGFuZCBs
b2NhdGlvbiB0byBjcmVhdGUgdGhlCiBbS2V5SGFuZGxlXVtnb29nbGUuY2xvdWQua21zLnYx
LktleUhhbmRsZV0gaW4sIGUuZy4KIGBwcm9qZWN0cy97UFJPSkVDVF9JRH0vbG9jYXRpb25z
L3tMT0NBVElPTn1gLgoKDAoFBAACAAUSA2ACCAoMCgUEAAIAARIDYAkPCgwKBQQAAgADEgNg
EhMKDQoFBAACAAgSBGAUZQMKDwoIBAACAAicCAASA2EEKgoPCgcEAAIACJ8IEgRiBGQFCrkB
CgQEAAIBEgNqAkQaqwEgT3B0aW9uYWwuIElkIG9mIHRoZSBbS2V5SGFuZGxlXVtnb29nbGUu
Y2xvdWQua21zLnYxLktleUhhbmRsZV0uIE11c3QgYmUKIHVuaXF1ZSB0byB0aGUgcmVzb3Vy
Y2UgcHJvamVjdCBhbmQgbG9jYXRpb24uIElmIG5vdCBwcm92aWRlZCBieSB0aGUgY2FsbGVy
LAogYSBuZXcgVVVJRCBpcyB1c2VkLgoKDAoFBAACAQUSA2oCCAoMCgUEAAIBARIDagkWCgwK
BQQAAgEDEgNqGRoKDAoFBAACAQgSA2obQwoPCggEAAIBCJwIABIDahxCCk4KBAQAAgISA20C
RBpBIFJlcXVpcmVkLiBbS2V5SGFuZGxlXVtnb29nbGUuY2xvdWQua21zLnYxLktleUhhbmRs
ZV0gdG8gY3JlYXRlLgoKDAoFBAACAgYSA20CCwoMCgUEAAICARIDbQwWCgwKBQQAAgIDEgNt
GRoKDAoFBAACAggSA20bQwoPCggEAAICCJwIABIDbRxCClsKAgQBEgRxAHsBGk8gUmVxdWVz
dCBtZXNzYWdlIGZvciBbR2V0S2V5SGFuZGxlXVtnb29nbGUuY2xvdWQua21zLnYxLkF1dG9r
ZXkuR2V0S2V5SGFuZGxlXS4KCgoKAwQBARIDcQgbCqsBCgQEAQIAEgR1AnoEGpwBIFJlcXVp
cmVkLiBOYW1lIG9mIHRoZSBbS2V5SGFuZGxlXVtnb29nbGUuY2xvdWQua21zLnYxLktleUhh
bmRsZV0gcmVzb3VyY2UsCiBlLmcuCiBgcHJvamVjdHMve1BST0pFQ1RfSUR9L2xvY2F0aW9u
cy97TE9DQVRJT059L2tleUhhbmRsZXMve0tFWV9IQU5ETEVfSUR9YC4KCgwKBQQBAgAFEgN1
AggKDAoFBAECAAESA3UJDQoMCgUEAQIAAxIDdRARCg0KBQQBAgAIEgR1EnoDCg8KCAQBAgAI
nAgAEgN2BCoKDwoHBAECAAifCBIEdwR5BQqjAQoCBAISBX8AowEBGpUBIFJlc291cmNlLW9y
aWVudGVkIHJlcHJlc2VudGF0aW9uIG9mIGEgcmVxdWVzdCB0byBDbG91ZCBLTVMgQXV0b2tl
eSBhbmQgdGhlCiByZXN1bHRpbmcgcHJvdmlzaW9uaW5nIG9mIGEgW0NyeXB0b0tleV1bZ29v
Z2xlLmNsb3VkLmttcy52MS5DcnlwdG9LZXldLgoKCgoDBAIBEgN/CBEKDQoDBAIHEgaAAQKF
AQQKDwoFBAIHnQgSBoABAoUBBAqtAQoEBAICABIEigECPRqeASBJZGVudGlmaWVyLiBOYW1l
IG9mIHRoZSBbS2V5SGFuZGxlXVtnb29nbGUuY2xvdWQua21zLnYxLktleUhhbmRsZV0KIHJl
c291cmNlLCBlLmcuCiBgcHJvamVjdHMve1BST0pFQ1RfSUR9L2xvY2F0aW9ucy97TE9DQVRJ
T059L2tleUhhbmRsZXMve0tFWV9IQU5ETEVfSUR9YC4KCg0KBQQCAgAFEgSKAQIICg0KBQQC
AgABEgSKAQkNCg0KBQQCAgADEgSKARARCg0KBQQCAgAIEgSKARI8ChAKCAQCAgAInAgAEgSK
ARM7CqcFCgQEAgIBEgaXAQKcAQQalgUgT3V0cHV0IG9ubHkuIE5hbWUgb2YgYSBbQ3J5cHRv
S2V5XVtnb29nbGUuY2xvdWQua21zLnYxLkNyeXB0b0tleV0gdGhhdCBoYXMKIGJlZW4gcHJv
dmlzaW9uZWQgZm9yIEN1c3RvbWVyIE1hbmFnZWQgRW5jcnlwdGlvbiBLZXkgKENNRUspIHVz
ZSBpbiB0aGUKIFtLZXlIYW5kbGVdW2dvb2dsZS5jbG91ZC5rbXMudjEuS2V5SGFuZGxlXSBw
cm9qZWN0IGFuZCBsb2NhdGlvbiBmb3IgdGhlCiByZXF1ZXN0ZWQgcmVzb3VyY2UgdHlwZS4g
VGhlIFtDcnlwdG9LZXldW2dvb2dsZS5jbG91ZC5rbXMudjEuQ3J5cHRvS2V5XQogcHJvamVj
dCB3aWxsIHJlZmxlY3QgdGhlIHZhbHVlIGNvbmZpZ3VyZWQgaW4gdGhlCiBbQXV0b2tleUNv
bmZpZ11bZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5Q29uZmlnXSBvbiB0aGUgcmVzb3Vy
Y2UKIHByb2plY3QncyBhbmNlc3RvciBmb2xkZXIgYXQgdGhlIHRpbWUgb2YgdGhlCiBbS2V5
SGFuZGxlXVtnb29nbGUuY2xvdWQua21zLnYxLktleUhhbmRsZV0gY3JlYXRpb24uIElmIG1v
cmUgdGhhbiBvbmUKIGFuY2VzdG9yIGZvbGRlciBoYXMgYSBjb25maWd1cmVkCiBbQXV0b2tl
eUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5Q29uZmlnXSwgdGhlIG5lYXJl
c3Qgb2YgdGhlc2UKIGNvbmZpZ3VyYXRpb25zIGlzIHVzZWQuCgoNCgUEAgIBBRIElwECCAoN
CgUEAgIBARIElwEJEAoNCgUEAgIBAxIElwETFAoPCgUEAgIBCBIGlwEVnAEDChAKCAQCAgEI
nAgAEgSYAQQtChEKBwQCAgEInwgSBpkBBJsBBQrkAQoEBAICAhIEogECTRrVASBSZXF1aXJl
ZC4gSW5kaWNhdGVzIHRoZSByZXNvdXJjZSB0eXBlIHRoYXQgdGhlIHJlc3VsdGluZwogW0Ny
eXB0b0tleV1bZ29vZ2xlLmNsb3VkLmttcy52MS5DcnlwdG9LZXldIGlzIG1lYW50IHRvIHBy
b3RlY3QsIGUuZy4KIGB7U0VSVklDRX0uZ29vZ2xlYXBpcy5jb20ve1RZUEV9YC4gU2VlIGRv
Y3VtZW50YXRpb24gZm9yIHN1cHBvcnRlZCByZXNvdXJjZQogdHlwZXMuCgoNCgUEAgICBRIE
ogECCAoNCgUEAgICARIEogEJHwoNCgUEAgICAxIEogEiIwoNCgUEAgICCBIEogEkTAoQCggE
AgICCJwIABIEogElSwqEAQoCBAMSBKgBACIaeCBNZXRhZGF0YSBtZXNzYWdlIGZvcgogW0Ny
ZWF0ZUtleUhhbmRsZV1bZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5LkNyZWF0ZUtleUhh
bmRsZV0gbG9uZy1ydW5uaW5nCiBvcGVyYXRpb24gcmVzcG9uc2UuCgoLCgMEAwESBKgBCB8K
agoCBAQSBqwBAMkBARpcIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtBdXRva2V5Lkxpc3RLZXlI
YW5kbGVzXVtnb29nbGUuY2xvdWQua21zLnYxLkF1dG9rZXkuTGlzdEtleUhhbmRsZXNdLgoK
CwoDBAQBEgSsAQgdCrsBCgQEBAIAEgawAQK1AQQaqgEgUmVxdWlyZWQuIE5hbWUgb2YgdGhl
IHJlc291cmNlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZyb20gd2hpY2ggdG8gbGlzdAogW0tl
eUhhbmRsZXNdW2dvb2dsZS5jbG91ZC5rbXMudjEuS2V5SGFuZGxlXSwgZS5nLgogYHByb2pl
Y3RzL3tQUk9KRUNUX0lEfS9sb2NhdGlvbnMve0xPQ0FUSU9OfWAuCgoNCgUEBAIABRIEsAEC
CAoNCgUEBAIAARIEsAEJDwoNCgUEBAIAAxIEsAESEwoPCgUEBAIACBIGsAEUtQEDChAKCAQE
AgAInAgAEgSxAQQqChEKBwQEAgAInwgSBrIBBLQBBQryAwoEBAQCARIEvwECPxrjAyBPcHRp
b25hbC4gT3B0aW9uYWwgbGltaXQgb24gdGhlIG51bWJlciBvZgogW0tleUhhbmRsZXNdW2dv
b2dsZS5jbG91ZC5rbXMudjEuS2V5SGFuZGxlXSB0byBpbmNsdWRlIGluIHRoZSByZXNwb25z
ZS4gVGhlCiBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBGdXJ0
aGVyCiBbS2V5SGFuZGxlc11bZ29vZ2xlLmNsb3VkLmttcy52MS5LZXlIYW5kbGVdIGNhbiBz
dWJzZXF1ZW50bHkgYmUgb2J0YWluZWQgYnkKIGluY2x1ZGluZyB0aGUKIFtMaXN0S2V5SGFu
ZGxlc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmttcy52MS5MaXN0
S2V5SGFuZGxlc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0KIGluIGEgc3Vic2VxdWVudCBy
ZXF1ZXN0LiAgSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgMTAwCiBbS2V5SGFuZGxlc11bZ29v
Z2xlLmNsb3VkLmttcy52MS5LZXlIYW5kbGVdIHdpbGwgYmUgcmV0dXJuZWQuCgoNCgUEBAIB
BRIEvwECBwoNCgUEBAIBARIEvwEIEQoNCgUEBAIBAxIEvwEUFQoNCgUEBAIBCBIEvwEWPgoQ
CggEBAIBCJwIABIEvwEXPQqxAQoEBAQCAhIEwwECQRqiASBPcHRpb25hbC4gT3B0aW9uYWwg
cGFnaW5hdGlvbiB0b2tlbiwgcmV0dXJuZWQgZWFybGllciB2aWEKIFtMaXN0S2V5SGFuZGxl
c1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmttcy52MS5MaXN0S2V5
SGFuZGxlc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0uCgoNCgUEBAICBRIEwwECCAoNCgUE
BAICARIEwwEJEwoNCgUEBAICAxIEwwEWFwoNCgUEBAICCBIEwwEYQAoQCggEBAICCJwIABIE
wwEZPwqnAQoEBAQCAxIEyAECPRqYASBPcHRpb25hbC4gRmlsdGVyIHRvIGFwcGx5IHdoZW4g
bGlzdGluZwogW0tleUhhbmRsZXNdW2dvb2dsZS5jbG91ZC5rbXMudjEuS2V5SGFuZGxlXSwg
ZS5nLgogYHJlc291cmNlX3R5cGVfc2VsZWN0b3I9IntTRVJWSUNFfS5nb29nbGVhcGlzLmNv
bS97VFlQRX0iYC4KCg0KBQQEAgMFEgTIAQIICg0KBQQEAgMBEgTIAQkPCg0KBQQEAgMDEgTI
ARITCg0KBQQEAgMIEgTIARQ8ChAKCAQEAgMInAgAEgTIARU7CmsKAgQFEgbNAQDVAQEaXSBS
ZXNwb25zZSBtZXNzYWdlIGZvcgogW0F1dG9rZXkuTGlzdEtleUhhbmRsZXNdW2dvb2dsZS5j
bG91ZC5rbXMudjEuQXV0b2tleS5MaXN0S2V5SGFuZGxlc10uCgoLCgMEBQESBM0BCB4KRgoE
BAUCABIEzwECJRo4IFJlc3VsdGluZyBbS2V5SGFuZGxlc11bZ29vZ2xlLmNsb3VkLmttcy52
MS5LZXlIYW5kbGVdLgoKDQoFBAUCAAQSBM8BAgoKDQoFBAUCAAYSBM8BCxQKDQoFBAUCAAES
BM8BFSAKDQoFBAUCAAMSBM8BIyQKzgEKBAQFAgESBNQBAh0avwEgQSB0b2tlbiB0byByZXRy
aWV2ZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4gUGFzcyB0aGlzIHZhbHVlIGluCiBbTGlzdEtl
eUhhbmRsZXNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5rbXMudjEuTGlzdEtl
eUhhbmRsZXNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdl
IG9mIHJlc3VsdHMuCgoNCgUEBQIBBRIE1AECCAoNCgUEBQIBARIE1AEJGAoNCgUEBQIBAxIE
1AEbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest ===
    # Fields for CreateKeyHandleRequest
    # Field: parent Type: 9 ()
    # Field: key_handle_id Type: 9 ()
    # Field: key_handle Type: 11 (.google.cloud.kms.v1.KeyHandle)

# === Message: Google::Cloud::Kms::V1::Autokey::GetKeyHandleRequest ===
    # Fields for GetKeyHandleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Kms::V1::Autokey::KeyHandle ===
    # Fields for KeyHandle
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()
    # Field: resource_type_selector Type: 9 ()

# === Message: Google::Cloud::Kms::V1::Autokey::CreateKeyHandleMetadata ===
    # Fields for CreateKeyHandleMetadata

# === Message: Google::Cloud::Kms::V1::Autokey::ListKeyHandlesRequest ===
    # Fields for ListKeyHandlesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Kms::V1::Autokey::ListKeyHandlesResponse ===
    # Fields for ListKeyHandlesResponse
    # Field: key_handles Type: 11 (.google.cloud.kms.v1.KeyHandle)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Kms::V1::Autokey::AutokeyClient ===
package Google::Cloud::Kms::V1::Autokey::AutokeyClient;

=pod

=head2 Service Client: Google::Cloud::Kms::V1::Autokey::AutokeyClient

Client stub representing the remote C<Autokey> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<kms.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'kms.googleapis.com:443' );

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

sub create_key_handle {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.v1.Autokey',
        method         => 'CreateKeyHandle',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_key_handle {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::V1::Autokey::GetKeyHandleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.v1.Autokey',
        method         => 'GetKeyHandle',
        request        => $req,
        response_class => 'Google::Cloud::Kms::V1::Autokey::KeyHandle',
    });
}

sub list_key_handles {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::V1::Autokey::ListKeyHandlesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.v1.Autokey',
        method         => 'ListKeyHandles',
        request        => $req,
        response_class => 'Google::Cloud::Kms::V1::Autokey::ListKeyHandlesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Kms::V1::Autokey - Compiled Protocol Buffers messages for google/cloud/kms/v1/autokey.proto

=head1 SYNOPSIS

    use Google::Cloud::Kms::V1::Autokey;

    my $msg = Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest->new({
        parent => $parent,
        key_handle_id => $key_handle_id,
        key_handle => $key_handle,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/kms/v1/autokey.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest

Request message for
[Autokey.CreateKeyHandle][google.cloud.kms.v1.Autokey.CreateKeyHandle].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the resource project and location to create the
[KeyHandle][google.cloud.kms.v1.KeyHandle] in, e.g.
`projects/{PROJECT_ID}/locations/{LOCATION}`.

=item * C<< $msg->key_handle_id() >> / C<< $msg->key_handle_id($value) >>

Type: C<String>

Optional. Id of the [KeyHandle][google.cloud.kms.v1.KeyHandle]. Must be
unique to the resource project and location. If not provided by the caller,
a new UUID is used.

=item * C<< $msg->key_handle() >> / C<< $msg->key_handle($value) >>

Type: C<Message> (L<Google::Cloud::Kms::V1::Autokey::KeyHandle>)

Required. [KeyHandle][google.cloud.kms.v1.KeyHandle] to create.

=back

=head2 Google::Cloud::Kms::V1::Autokey::GetKeyHandleRequest

Request message for [GetKeyHandle][google.cloud.kms.v1.Autokey.GetKeyHandle].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the [KeyHandle][google.cloud.kms.v1.KeyHandle] resource,
e.g.
`projects/{PROJECT_ID}/locations/{LOCATION}/keyHandles/{KEY_HANDLE_ID}`.

=back

=head2 Google::Cloud::Kms::V1::Autokey::KeyHandle

Resource-oriented representation of a request to Cloud KMS Autokey and the
resulting provisioning of a [CryptoKey][google.cloud.kms.v1.CryptoKey].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the [KeyHandle][google.cloud.kms.v1.KeyHandle]
resource, e.g.
`projects/{PROJECT_ID}/locations/{LOCATION}/keyHandles/{KEY_HANDLE_ID}`.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Output only. Name of a [CryptoKey][google.cloud.kms.v1.CryptoKey] that has
been provisioned for Customer Managed Encryption Key (CMEK) use in the
[KeyHandle][google.cloud.kms.v1.KeyHandle] project and location for the
requested resource type. The [CryptoKey][google.cloud.kms.v1.CryptoKey]
project will reflect the value configured in the
[AutokeyConfig][google.cloud.kms.v1.AutokeyConfig] on the resource
project's ancestor folder at the time of the
[KeyHandle][google.cloud.kms.v1.KeyHandle] creation. If more than one
ancestor folder has a configured
[AutokeyConfig][google.cloud.kms.v1.AutokeyConfig], the nearest of these
configurations is used.

=item * C<< $msg->resource_type_selector() >> / C<< $msg->resource_type_selector($value) >>

Type: C<String>

Required. Indicates the resource type that the resulting
[CryptoKey][google.cloud.kms.v1.CryptoKey] is meant to protect, e.g.
`{SERVICE}.googleapis.com/{TYPE}`. See documentation for supported resource
types.

=back

=head2 Google::Cloud::Kms::V1::Autokey::CreateKeyHandleMetadata

Metadata message for
[CreateKeyHandle][google.cloud.kms.v1.Autokey.CreateKeyHandle] long-running
operation response.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Kms::V1::Autokey::ListKeyHandlesRequest

Request message for
[Autokey.ListKeyHandles][google.cloud.kms.v1.Autokey.ListKeyHandles].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the resource project and location from which to list
[KeyHandles][google.cloud.kms.v1.KeyHandle], e.g.
`projects/{PROJECT_ID}/locations/{LOCATION}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Optional limit on the number of
[KeyHandles][google.cloud.kms.v1.KeyHandle] to include in the response. The
service may return fewer than this value. Further
[KeyHandles][google.cloud.kms.v1.KeyHandle] can subsequently be obtained by
including the
[ListKeyHandlesResponse.next_page_token][google.cloud.kms.v1.ListKeyHandlesResponse.next_page_token]
in a subsequent request.  If unspecified, at most 100
[KeyHandles][google.cloud.kms.v1.KeyHandle] will be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Optional pagination token, returned earlier via
[ListKeyHandlesResponse.next_page_token][google.cloud.kms.v1.ListKeyHandlesResponse.next_page_token].

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter to apply when listing
[KeyHandles][google.cloud.kms.v1.KeyHandle], e.g.
`resource_type_selector="{SERVICE}.googleapis.com/{TYPE}"`.

=back

=head2 Google::Cloud::Kms::V1::Autokey::ListKeyHandlesResponse

Response message for
[Autokey.ListKeyHandles][google.cloud.kms.v1.Autokey.ListKeyHandles].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key_handles() >> / C<< $msg->key_handles($value) >>

Type: C<Message> (L<Google::Cloud::Kms::V1::Autokey::KeyHandle>)

Resulting [KeyHandles][google.cloud.kms.v1.KeyHandle].

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve next page of results. Pass this value in
[ListKeyHandlesRequest.page_token][google.cloud.kms.v1.ListKeyHandlesRequest.page_token]
to retrieve the next page of results.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Kms::V1::Autokey::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
