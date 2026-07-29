package Google::Cloud::Kms::V1::AutokeyAdmin;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQva21zL3YxL2F1dG9rZXlfYWRtaW4ucHJvdG8SE2dvb2dsZS5jbG91
ZC5rbXMudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xp
ZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKuAQoa
VXBkYXRlQXV0b2tleUNvbmZpZ1JlcXVlc3QSTgoOYXV0b2tleV9jb25maWcYASABKAsyIi5n
b29nbGUuY2xvdWQua21zLnYxLkF1dG9rZXlDb25maWdCA+BBAlINYXV0b2tleUNvbmZpZxJA
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIK
dXBkYXRlTWFzayJcChdHZXRBdXRva2V5Q29uZmlnUmVxdWVzdBJBCgRuYW1lGAEgASgJQi3g
QQL6QScKJWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0F1dG9rZXlDb25maWdSBG5hbWUiwAUK
DUF1dG9rZXlDb25maWcSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiQKC2tleV9wcm9qZWN0
GAIgASgJQgPgQQFSCmtleVByb2plY3QSQwoFc3RhdGUYBCABKA4yKC5nb29nbGUuY2xvdWQu
a21zLnYxLkF1dG9rZXlDb25maWcuU3RhdGVCA+BBA1IFc3RhdGUSFwoEZXRhZxgGIAEoCUID
4EEBUgRldGFnEn8KG2tleV9wcm9qZWN0X3Jlc29sdXRpb25fbW9kZRgIIAEoDjI7Lmdvb2ds
ZS5jbG91ZC5rbXMudjEuQXV0b2tleUNvbmZpZy5LZXlQcm9qZWN0UmVzb2x1dGlvbk1vZGVC
A+BBAVIYa2V5UHJvamVjdFJlc29sdXRpb25Nb2RlInkKBVN0YXRlEhUKEVNUQVRFX1VOU1BF
Q0lGSUVEEAASCgoGQUNUSVZFEAESFwoTS0VZX1BST0pFQ1RfREVMRVRFRBACEhEKDVVOSU5J
VElBTElaRUQQAxIhCh1LRVlfUFJPSkVDVF9QRVJNSVNTSU9OX0RFTklFRBAEIoYBChhLZXlQ
cm9qZWN0UmVzb2x1dGlvbk1vZGUSKwonS0VZX1BST0pFQ1RfUkVTT0xVVElPTl9NT0RFX1VO
U1BFQ0lGSUVEEAASGQoVREVESUNBVEVEX0tFWV9QUk9KRUNUEAESFAoQUkVTT1VSQ0VfUFJP
SkVDVBACEgwKCERJU0FCTEVEEAM6jAHqQYgBCiVjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9B
dXRva2V5Q29uZmlnEh5mb2xkZXJzL3tmb2xkZXJ9L2F1dG9rZXlDb25maWcSIHByb2plY3Rz
L3twcm9qZWN0fS9hdXRva2V5Q29uZmlnKg5hdXRva2V5Q29uZmlnczINYXV0b2tleUNvbmZp
ZyJwCiFTaG93RWZmZWN0aXZlQXV0b2tleUNvbmZpZ1JlcXVlc3QSSwoGcGFyZW50GAEgASgJ
QjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2plY3RS
BnBhcmVudCJFCiJTaG93RWZmZWN0aXZlQXV0b2tleUNvbmZpZ1Jlc3BvbnNlEh8KC2tleV9w
cm9qZWN0GAEgASgJUgprZXlQcm9qZWN0MrcGCgxBdXRva2V5QWRtaW4SmgIKE1VwZGF0ZUF1
dG9rZXlDb25maWcSLy5nb29nbGUuY2xvdWQua21zLnYxLlVwZGF0ZUF1dG9rZXlDb25maWdS
ZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5Q29uZmlnIq0BgtPkkwKJATIx
L3YxL3thdXRva2V5X2NvbmZpZy5uYW1lPWZvbGRlcnMvKi9hdXRva2V5Q29uZmlnfToOYXV0
b2tleV9jb25maWdaRDIyL3YxL3thdXRva2V5X2NvbmZpZy5uYW1lPXByb2plY3RzLyovYXV0
b2tleUNvbmZpZ306DmF1dG9rZXlfY29uZmln2kEaYXV0b2tleV9jb25maWcsdXBkYXRlX21h
c2sSvgEKEEdldEF1dG9rZXlDb25maWcSLC5nb29nbGUuY2xvdWQua21zLnYxLkdldEF1dG9r
ZXlDb25maWdSZXF1ZXN0GiIuZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5Q29uZmlnIliC
0+STAksSIi92MS97bmFtZT1mb2xkZXJzLyovYXV0b2tleUNvbmZpZ31aJRIjL3YxL3tuYW1l
PXByb2plY3RzLyovYXV0b2tleUNvbmZpZ33aQQRuYW1lEtIBChpTaG93RWZmZWN0aXZlQXV0
b2tleUNvbmZpZxI2Lmdvb2dsZS5jbG91ZC5rbXMudjEuU2hvd0VmZmVjdGl2ZUF1dG9rZXlD
b25maWdSZXF1ZXN0GjcuZ29vZ2xlLmNsb3VkLmttcy52MS5TaG93RWZmZWN0aXZlQXV0b2tl
eUNvbmZpZ1Jlc3BvbnNlIkOC0+STAjQSMi92MS97cGFyZW50PXByb2plY3RzLyp9OnNob3dF
ZmZlY3RpdmVBdXRva2V5Q29uZmln2kEGcGFyZW50GnTKQRdjbG91ZGttcy5nb29nbGVhcGlz
LmNvbdJBV2h0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0s
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZGttc0JZChdjb20uZ29vZ2xl
LmNsb3VkLmttcy52MUIRQXV0b2tleUFkbWluUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9n
by9rbXMvYXBpdjEva21zcGI7a21zcGJK0kAKBxIFDgDjAQEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAqCggKAQgSAxgAQAoJCgIICxIDGABACggKAQgS
AxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMgoJCgIICBIDGgAyCggKAQgSAxsAMAoJCgIIARID
GwAwCskFCgIGABIEJwBSARq8BSBQcm92aWRlcyBpbnRlcmZhY2VzIGZvciBtYW5hZ2luZyBb
Q2xvdWQgS01TCiBBdXRva2V5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20va21zL2hlbHAv
YXV0b2tleSkgZm9sZGVyLWxldmVsIG9yCiBwcm9qZWN0LWxldmVsIGNvbmZpZ3VyYXRpb25z
LiBBIGNvbmZpZ3VyYXRpb24gaXMgaW5oZXJpdGVkIGJ5IGFsbCBkZXNjZW5kZW50CiBmb2xk
ZXJzIGFuZCBwcm9qZWN0cy4gQSBjb25maWd1cmF0aW9uIGF0IGEgZm9sZGVyIG9yIHByb2pl
Y3Qgb3ZlcnJpZGVzIGFueQogb3RoZXIgY29uZmlndXJhdGlvbnMgaW4gaXRzIGFuY2VzdHJ5
LiBTZXR0aW5nIGEgY29uZmlndXJhdGlvbiBvbiBhIGZvbGRlciBpcwogYSBwcmVyZXF1aXNp
dGUgZm9yIENsb3VkIEtNUyBBdXRva2V5LCBzbyB0aGF0IHVzZXJzIHdvcmtpbmcgaW4gYSBk
ZXNjZW5kYW50CiBwcm9qZWN0IGNhbiByZXF1ZXN0IHByb3Zpc2lvbmVkIFtDcnlwdG9LZXlz
XVtnb29nbGUuY2xvdWQua21zLnYxLkNyeXB0b0tleV0sCiByZWFkeSBmb3IgQ3VzdG9tZXIg
TWFuYWdlZCBFbmNyeXB0aW9uIEtleSAoQ01FSykgdXNlLCBvbi1kZW1hbmQgd2hlbiB1c2lu
ZwogdGhlIGRlZGljYXRlZCBrZXkgcHJvamVjdCBtb2RlLiBUaGlzIGlzIG5vdCByZXF1aXJl
ZCB3aGVuIHVzaW5nIHRoZSBkZWxlZ2F0ZWQKIGtleSBtYW5hZ2VtZW50IG1vZGUgZm9yIHNh
bWUtcHJvamVjdCBrZXlzLgoKCgoDBgABEgMnCBQKCgoDBgADEgMoAj8KDAoFBgADmQgSAygC
PwoLCgMGAAMSBCkCKzEKDQoFBgADmggSBCkCKzEK5wMKBAYAAgASBDQCPgMa2AMgVXBkYXRl
cyB0aGUgW0F1dG9rZXlDb25maWddW2dvb2dsZS5jbG91ZC5rbXMudjEuQXV0b2tleUNvbmZp
Z10gZm9yIGEgZm9sZGVyCiBvciBhIHByb2plY3QuIFRoZSBjYWxsZXIgbXVzdCBoYXZlIGJv
dGggYGNsb3Vka21zLmF1dG9rZXlDb25maWdzLnVwZGF0ZWAKIHBlcm1pc3Npb24gb24gdGhl
IHBhcmVudCBmb2xkZXIgYW5kIGBjbG91ZGttcy5jcnlwdG9LZXlzLnNldElhbVBvbGljeWAK
IHBlcm1pc3Npb24gb24gdGhlIHByb3ZpZGVkIGtleSBwcm9qZWN0LiBBCiBbS2V5SGFuZGxl
XVtnb29nbGUuY2xvdWQua21zLnYxLktleUhhbmRsZV0gY3JlYXRpb24gaW4gdGhlIGZvbGRl
cidzCiBkZXNjZW5kYW50IHByb2plY3RzIHdpbGwgdXNlIHRoaXMgY29uZmlndXJhdGlvbiB0
byBkZXRlcm1pbmUgd2hlcmUgdG8KIGNyZWF0ZSB0aGUgcmVzdWx0aW5nIFtDcnlwdG9LZXld
W2dvb2dsZS5jbG91ZC5rbXMudjEuQ3J5cHRvS2V5XS4KCgwKBQYAAgABEgM0BhkKDAoFBgAC
AAISAzQaNAoMCgUGAAIAAxIDND9MCg0KBQYAAgAEEgQ1BDwGChEKCQYAAgAEsMq8IhIENQQ8
BgoMCgUGAAIABBIDPQRICg8KCAYAAgAEmwgAEgM9BEgKaAoEBgACARIEQgJIAxpaIFJldHVy
bnMgdGhlIFtBdXRva2V5Q29uZmlnXVtnb29nbGUuY2xvdWQua21zLnYxLkF1dG9rZXlDb25m
aWddIGZvciBhIGZvbGRlcgogb3IgcHJvamVjdC4KCgwKBQYAAgEBEgNCBhYKDAoFBgACAQIS
A0IXLgoMCgUGAAIBAxIDQjlGCg0KBQYAAgEEEgRDBEYGChEKCQYAAgEEsMq8IhIEQwRGBgoM
CgUGAAIBBBIDRwQyCg8KCAYAAgEEmwgAEgNHBDIKWgoEBgACAhIESwJRAxpMIFJldHVybnMg
dGhlIGVmZmVjdGl2ZSBDbG91ZCBLTVMgQXV0b2tleSBjb25maWd1cmF0aW9uIGZvciBhIGdp
dmVuIHByb2plY3QuCgoMCgUGAAICARIDSwYgCgwKBQYAAgICEgNLIUIKDAoFBgACAgMSA0wP
MQoNCgUGAAICBBIETQRPBgoRCgkGAAICBLDKvCISBE0ETwYKDAoFBgACAgQSA1AENAoPCggG
AAICBJsIABIDUAQ0Cm8KAgQAEgRWAGABGmMgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1VwZGF0
ZUF1dG9rZXlDb25maWddW2dvb2dsZS5jbG91ZC5rbXMudjEuQXV0b2tleUFkbWluLlVwZGF0
ZUF1dG9rZXlDb25maWddLgoKCgoDBAABEgNWCCIKYwoEBAACABIDWQJMGlYgUmVxdWlyZWQu
IFtBdXRva2V5Q29uZmlnXVtnb29nbGUuY2xvdWQua21zLnYxLkF1dG9rZXlDb25maWddIHdp
dGggdmFsdWVzIHRvCiB1cGRhdGUuCgoMCgUEAAIABhIDWQIPCgwKBQQAAgABEgNZEB4KDAoF
BAACAAMSA1khIgoMCgUEAAIACBIDWSNLCg8KCAQAAgAInAgAEgNZJEoKhgEKBAQAAgESBF4C
Xy8aeCBSZXF1aXJlZC4gTWFza3Mgd2hpY2ggZmllbGRzIG9mIHRoZQogW0F1dG9rZXlDb25m
aWddW2dvb2dsZS5jbG91ZC5rbXMudjEuQXV0b2tleUNvbmZpZ10gdG8gdXBkYXRlLCBlLmcu
CiBga2V5UHJvamVjdGAuCgoMCgUEAAIBBhIDXgIbCgwKBQQAAgEBEgNeHCcKDAoFBAACAQMS
A14qKwoMCgUEAAIBCBIDXwYuCg8KCAQAAgEInAgAEgNfBy0KaQoCBAESBGQAbgEaXSBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbR2V0QXV0b2tleUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmttcy52
MS5BdXRva2V5QWRtaW4uR2V0QXV0b2tleUNvbmZpZ10uCgoKCgMEAQESA2QIHwrAAQoEBAEC
ABIEaAJtBBqxASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgW0F1dG9rZXlDb25maWddW2dvb2ds
ZS5jbG91ZC5rbXMudjEuQXV0b2tleUNvbmZpZ10KIHJlc291cmNlLCBlLmcuIGBmb2xkZXJz
L3tGT0xERVJfTlVNQkVSfS9hdXRva2V5Q29uZmlnYCBvcgogYHByb2plY3RzL3tQUk9KRUNU
X05VTUJFUn0vYXV0b2tleUNvbmZpZ2AuCgoMCgUEAQIABRIDaAIICgwKBQQBAgABEgNoCQ0K
DAoFBAECAAMSA2gQEQoNCgUEAQIACBIEaBJtAwoPCggEAQIACJwIABIDaQQqCg8KBwQBAgAI
nwgSBGoEbAUKPAoCBAISBXEAzQEBGi8gQ2xvdWQgS01TIEF1dG9rZXkgY29uZmlndXJhdGlv
biBmb3IgYSBmb2xkZXIuCgoKCgMEAgESA3EIFQoLCgMEAgcSBHICeAQKDQoFBAIHnQgSBHIC
eAQKNAoEBAIEABIFewKNAQMaJSBUaGUgc3RhdGVzIEF1dG9rZXlDb25maWcgY2FuIGJlIGlu
LgoKDAoFBAIEAAESA3sHDAo/CgYEAgQAAgASA30EGhowIFRoZSBzdGF0ZSBvZiB0aGUgQXV0
b2tleUNvbmZpZyBpcyB1bnNwZWNpZmllZC4KCg4KBwQCBAACAAESA30EFQoOCgcEAgQAAgAC
EgN9GBkKOAoGBAIEAAIBEgSAAQQPGiggVGhlIEF1dG9rZXlDb25maWcgaXMgY3VycmVudGx5
IGFjdGl2ZS4KCg8KBwQCBAACAQESBIABBAoKDwoHBAIEAAIBAhIEgAENDgpyCgYEAgQAAgIS
BIQBBBwaYiBBIHByZXZpb3VzbHkgY29uZmlndXJlZCBrZXkgcHJvamVjdCBoYXMgYmVlbiBk
ZWxldGVkIGFuZCB0aGUgY3VycmVudAogQXV0b2tleUNvbmZpZyBpcyB1bnVzYWJsZS4KCg8K
BwQCBAACAgESBIQBBBcKDwoHBAIEAAICAhIEhAEaGwpxCgYEAgQAAgMSBIgBBBYaYSBUaGUg
QXV0b2tleUNvbmZpZyBpcyBub3QgeWV0IGluaXRpYWxpemVkIG9yIGhhcyBiZWVuIHJlc2V0
IHRvIGl0cyBkZWZhdWx0CiB1bmluaXRpYWxpemVkIHN0YXRlLgoKDwoHBAIEAAIDARIEiAEE
EQoPCgcEAgQAAgMCEgSIARQVCm8KBgQCBAACBBIEjAEEJhpfIFRoZSBzZXJ2aWNlIGFjY291
bnQgbGFja3MgdGhlIG5lY2Vzc2FyeSBwZXJtaXNzaW9ucyBpbiB0aGUga2V5IHByb2plY3Qg
dG8KIGNvbmZpZ3VyZSBBdXRva2V5LgoKDwoHBAIEAAIEARIEjAEEIQoPCgcEAgQAAgQCEgSM
ASQlCsIDCgQEAgQBEgaXAQKrAQMasQMgRGVmaW5lcyB0aGUgcmVzb2x1dGlvbiBtb2RlIGVu
dW0gZm9yIHRoZSBrZXkgcHJvamVjdC4KIFRoZQogW0tleVByb2plY3RSZXNvbHV0aW9uTW9k
ZV1bZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5Q29uZmlnLktleVByb2plY3RSZXNvbHV0
aW9uTW9kZV0KIGRldGVybWluZXMgdGhlIG1lY2hhbmlzbSBieSB3aGljaAogW0F1dG9rZXlD
b25maWddW2dvb2dsZS5jbG91ZC5rbXMudjEuQXV0b2tleUNvbmZpZ10gaWRlbnRpZmllcyBh
CiBba2V5X3Byb2plY3RdW2dvb2dsZS5jbG91ZC5rbXMudjEuQXV0b2tleUNvbmZpZy5rZXlf
cHJvamVjdF0gYXQgaXRzCiBzcGVjaWZpYyBjb25maWd1cmF0aW9uIG5vZGUuIFRoaXMgcGFy
YW1ldGVyIGFsc28gZGV0ZXJtaW5lcyBpZiBBdXRva2V5IGNhbgogYmUgdXNlZCB3aXRoaW4g
dGhpcyBwcm9qZWN0IG9yIGZvbGRlci4KCg0KBQQCBAEBEgSXAQcfCnIKBgQCBAECABIEmgEE
MBpiIERlZmF1bHQgdmFsdWUuIEtleVByb2plY3RSZXNvbHV0aW9uTW9kZSB3aGVuIG5vdCBz
cGVjaWZpZWQgd2lsbCBhY3QgYXMKIGBERURJQ0FURURfS0VZX1BST0pFQ1RgLgoKDwoHBAIE
AQIAARIEmgEEKwoPCgcEAgQBAgACEgSaAS4vClUKBgQCBAECARIEnQEEHhpFIEtleXMgYXJl
IGNyZWF0ZWQgaW4gYSBkZWRpY2F0ZWQgcHJvamVjdCBzcGVjaWZpZWQgYnkgYGtleV9wcm9q
ZWN0YC4KCg8KBwQCBAECAQESBJ0BBBkKDwoHBAIEAQIBAhIEnQEcHQqWAQoGBAIEAQICEgSh
AQQZGoUBIEtleXMgYXJlIGNyZWF0ZWQgaW4gdGhlIHNhbWUgcHJvamVjdCBhcyB0aGUgcmVz
b3VyY2UgcmVxdWVzdGluZyB0aGUga2V5LgogVGhlIGBrZXlfcHJvamVjdGAgbXVzdCBub3Qg
YmUgc2V0IHdoZW4gdGhpcyBtb2RlIGlzIHVzZWQuCgoPCgcEAgQBAgIBEgShAQQUCg8KBwQC
BAECAgISBKEBFxgK0gMKBgQCBAECAxIEqgEEERrBAyBEaXNhYmxlcyB0aGUgQXV0b2tleUNv
bmZpZy4gV2hlbiB0aGlzIG1vZGUgaXMgc2V0LCBhbnkgQXV0b2tleUNvbmZpZwogZnJvbSBo
aWdoZXIgbGV2ZWxzIGluIHRoZSByZXNvdXJjZSBoaWVyYXJjaHkgYXJlIGlnbm9yZWQgZm9y
IHRoaXMKIHJlc291cmNlIGFuZCBpdHMgZGVzY2VuZGFudHMuIFRoaXMgc2V0dGluZyBjYW4g
YmUgb3ZlcnJpZGRlbgogYnkgYSBtb3JlIHNwZWNpZmljIGNvbmZpZ3VyYXRpb24gYXQgYSBs
b3dlciBsZXZlbC4gRm9yIGV4YW1wbGUsCiBpZiBBdXRva2V5IGlzIGRpc2FibGVkIG9uIGEg
Zm9sZGVyLCBpdCBjYW4gYmUgcmUtZW5hYmxlZCBvbiBhIHN1Yi1mb2xkZXIKIG9yIHByb2pl
Y3Qgd2l0aGluIHRoYXQgZm9sZGVyIGJ5IHNldHRpbmcgYSBkaWZmZXJlbnQgbW9kZSAoZS5n
LiwKIERFRElDQVRFRF9LRVlfUFJPSkVDVCBvciBSRVNPVVJDRV9QUk9KRUNUKS4KCg8KBwQC
BAECAwESBKoBBAwKDwoHBAIEAQIDAhIEqgEPEArCAQoEBAICABIEsAECPRqzASBJZGVudGlm
aWVyLiBOYW1lIG9mIHRoZSBbQXV0b2tleUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmttcy52MS5B
dXRva2V5Q29uZmlnXQogcmVzb3VyY2UsIGUuZy4gYGZvbGRlcnMve0ZPTERFUl9OVU1CRVJ9
L2F1dG9rZXlDb25maWdgIG9yCiBgcHJvamVjdHMve1BST0pFQ1RfTlVNQkVSfS9hdXRva2V5
Q29uZmlnYC4KCg0KBQQCAgAFEgSwAQIICg0KBQQCAgABEgSwAQkNCg0KBQQCAgADEgSwARAR
Cg0KBQQCAgAIEgSwARI8ChAKCAQCAgAInAgAEgSwARM7CvIFCgQEAgIBEgS9AQJCGuMFIE9w
dGlvbmFsLiBOYW1lIG9mIHRoZSBrZXkgcHJvamVjdCwgZS5nLiBgcHJvamVjdHMve1BST0pF
Q1RfSUR9YCBvcgogYHByb2plY3RzL3tQUk9KRUNUX05VTUJFUn1gLCB3aGVyZSBDbG91ZCBL
TVMgQXV0b2tleSB3aWxsIHByb3Zpc2lvbiBhIG5ldwogW0NyeXB0b0tleV1bZ29vZ2xlLmNs
b3VkLmttcy52MS5DcnlwdG9LZXldIHdoZW4gYQogW0tleUhhbmRsZV1bZ29vZ2xlLmNsb3Vk
Lmttcy52MS5LZXlIYW5kbGVdIGlzIGNyZWF0ZWQuIE9uCiBbVXBkYXRlQXV0b2tleUNvbmZp
Z11bZ29vZ2xlLmNsb3VkLmttcy52MS5BdXRva2V5QWRtaW4uVXBkYXRlQXV0b2tleUNvbmZp
Z10sCiB0aGUgY2FsbGVyIHdpbGwgcmVxdWlyZSBgY2xvdWRrbXMuY3J5cHRvS2V5cy5zZXRJ
YW1Qb2xpY3lgIHBlcm1pc3Npb24gb24KIHRoaXMga2V5IHByb2plY3QuIE9uY2UgY29uZmln
dXJlZCwgZm9yIENsb3VkIEtNUyBBdXRva2V5IHRvIGZ1bmN0aW9uCiBwcm9wZXJseSwgdGhp
cyBrZXkgcHJvamVjdCBtdXN0IGhhdmUgdGhlIENsb3VkIEtNUyBBUEkgYWN0aXZhdGVkIGFu
ZCB0aGUKIENsb3VkIEtNUyBTZXJ2aWNlIEFnZW50IGZvciB0aGlzIGtleSBwcm9qZWN0IG11
c3QgYmUgZ3JhbnRlZCB0aGUKIGBjbG91ZGttcy5hZG1pbmAgcm9sZSAob3IgcGVydGluZW50
IHBlcm1pc3Npb25zKS4gQSByZXF1ZXN0IHdpdGggYW4gZW1wdHkKIGtleSBwcm9qZWN0IGZp
ZWxkIHdpbGwgY2xlYXIgdGhlIGNvbmZpZ3VyYXRpb24uCgoNCgUEAgIBBRIEvQECCAoNCgUE
AgIBARIEvQEJFAoNCgUEAgIBAxIEvQEXGAoNCgUEAgIBCBIEvQEZQQoQCggEAgIBCJwIABIE
vQEaQAo9CgQEAgICEgTAAQI+Gi8gT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBmb3IgdGhlIEF1
dG9rZXlDb25maWcuCgoNCgUEAgICBhIEwAECBwoNCgUEAgICARIEwAEIDQoNCgUEAgICAxIE
wAEQEQoNCgUEAgICCBIEwAESPQoQCggEAgICCJwIABIEwAETPAqVAgoEBAICAxIExgECOxqG
AiBPcHRpb25hbC4gQSBjaGVja3N1bSBjb21wdXRlZCBieSB0aGUgc2VydmVyIGJhc2VkIG9u
IHRoZSB2YWx1ZSBvZiBvdGhlcgogZmllbGRzLiBUaGlzIG1heSBiZSBzZW50IG9uIHVwZGF0
ZSByZXF1ZXN0cyB0byBlbnN1cmUgdGhhdCB0aGUgY2xpZW50IGhhcwogYW4gdXAtdG8tZGF0
ZSB2YWx1ZSBiZWZvcmUgcHJvY2VlZGluZy4gVGhlIHJlcXVlc3Qgd2lsbCBiZSByZWplY3Rl
ZCB3aXRoIGFuCiBBQk9SVEVEIGVycm9yIG9uIGEgbWlzbWF0Y2hlZCBldGFnLgoKDQoFBAIC
AwUSBMYBAggKDQoFBAICAwESBMYBCQ0KDQoFBAICAwMSBMYBEBEKDQoFBAICAwgSBMYBEjoK
EAoIBAICAwicCAASBMYBEzkKmwEKBAQCAgQSBssBAswBLxqKASBPcHRpb25hbC4gS2V5UHJv
amVjdFJlc29sdXRpb25Nb2RlIGZvciB0aGUgQXV0b2tleUNvbmZpZy4KIFZhbGlkIHZhbHVl
cyBhcmUgYERFRElDQVRFRF9LRVlfUFJPSkVDVGAsIGBSRVNPVVJDRV9QUk9KRUNUYCwgb3IK
IGBESVNBQkxFRGAuCgoNCgUEAgIEBhIEywECGgoNCgUEAgIEARIEywEbNgoNCgUEAgIEAxIE
ywE5OgoNCgUEAgIECBIEzAEGLgoQCggEAgIECJwIABIEzAEHLQp/CgIEAxIG0QEA2wEBGnEg
UmVxdWVzdCBtZXNzYWdlIGZvcgogW1Nob3dFZmZlY3RpdmVBdXRva2V5Q29uZmlnXVtnb29n
bGUuY2xvdWQua21zLnYxLkF1dG9rZXlBZG1pbi5TaG93RWZmZWN0aXZlQXV0b2tleUNvbmZp
Z10uCgoLCgMEAwESBNEBCCkK5AEKBAQDAgASBtUBAtoBBBrTASBSZXF1aXJlZC4gTmFtZSBv
ZiB0aGUgcmVzb3VyY2UgcHJvamVjdCB0byB0aGUgc2hvdyBlZmZlY3RpdmUgQ2xvdWQgS01T
CiBBdXRva2V5IGNvbmZpZ3VyYXRpb24gZm9yLiBUaGlzIG1heSBiZSBoZWxwZnVsIGZvciBp
bnRlcnJvZ2F0aW5nIHRoZSBlZmZlY3QKIG9mIG5lc3RlZCBmb2xkZXIgY29uZmlndXJhdGlv
bnMgb24gYSBnaXZlbiByZXNvdXJjZSBwcm9qZWN0LgoKDQoFBAMCAAUSBNUBAggKDQoFBAMC
AAESBNUBCQ8KDQoFBAMCAAMSBNUBEhMKDwoFBAMCAAgSBtUBFNoBAwoQCggEAwIACJwIABIE
1gEEKgoRCgcEAwIACJ8IEgbXAQTZAQUKgAEKAgQEEgbfAQDjAQEaciBSZXNwb25zZSBtZXNz
YWdlIGZvcgogW1Nob3dFZmZlY3RpdmVBdXRva2V5Q29uZmlnXVtnb29nbGUuY2xvdWQua21z
LnYxLkF1dG9rZXlBZG1pbi5TaG93RWZmZWN0aXZlQXV0b2tleUNvbmZpZ10uCgoLCgMEBAES
BN8BCCoKXgoEBAQCABIE4gECGRpQIE5hbWUgb2YgdGhlIGtleSBwcm9qZWN0IGNvbmZpZ3Vy
ZWQgaW4gdGhlIHJlc291cmNlIHByb2plY3QncyBmb2xkZXIKIGFuY2VzdHJ5LgoKDQoFBAQC
AAUSBOIBAggKDQoFBAQCAAESBOIBCRQKDQoFBAQCAAMSBOIBFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest ===
    # Fields for UpdateAutokeyConfigRequest
    # Field: autokey_config Type: 11 (.google.cloud.kms.v1.AutokeyConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

=pod

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Kms::V1::AutokeyAdmin;

    my $msg = Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest->new(
        autokey_config => $value,
    );

=head1 FIELDS

=over 4

=item * B<autokey_config>

Type: Message (.google.cloud.kms.v1.AutokeyConfig)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=back

=cut

# === Message: Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest ===
    # Fields for GetAutokeyConfigRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Kms::V1::AutokeyAdmin;

    my $msg = Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig ===
    # Fields for AutokeyConfig
    # Field: name Type: 9 ()
    # Field: key_project Type: 9 ()
    # Field: state Type: 14 (.google.cloud.kms.v1.AutokeyConfig.State)
    # Field: etag Type: 9 ()
    # Field: key_project_resolution_mode Type: 14 (.google.cloud.kms.v1.AutokeyConfig.KeyProjectResolutionMode)

=pod

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Kms::V1::AutokeyAdmin;

    my $msg = Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<key_project>

Type: String

=item * B<state>

Type: Enum (.google.cloud.kms.v1.AutokeyConfig.State)

=item * B<etag>

Type: String

=item * B<key_project_resolution_mode>

Type: Enum (.google.cloud.kms.v1.AutokeyConfig.KeyProjectResolutionMode)

=back

=cut

# Enum: AutokeyConfig::State
our $AutokeyConfig_STATE_UNSPECIFIED = 0;
our $AutokeyConfig_ACTIVE = 1;
our $AutokeyConfig_KEY_PROJECT_DELETED = 2;
our $AutokeyConfig_UNINITIALIZED = 3;
our $AutokeyConfig_KEY_PROJECT_PERMISSION_DENIED = 4;

=pod

=head2 Enum: AutokeyConfig::State

Values:

=over 4

=item * C<STATE_UNSPECIFIED> => 0

=item * C<ACTIVE> => 1

=item * C<KEY_PROJECT_DELETED> => 2

=item * C<UNINITIALIZED> => 3

=item * C<KEY_PROJECT_PERMISSION_DENIED> => 4

=back

=cut

# Enum: AutokeyConfig::KeyProjectResolutionMode
our $AutokeyConfig_KEY_PROJECT_RESOLUTION_MODE_UNSPECIFIED = 0;
our $AutokeyConfig_DEDICATED_KEY_PROJECT = 1;
our $AutokeyConfig_RESOURCE_PROJECT = 2;
our $AutokeyConfig_DISABLED = 3;

=pod

=head2 Enum: AutokeyConfig::KeyProjectResolutionMode

Values:

=over 4

=item * C<KEY_PROJECT_RESOLUTION_MODE_UNSPECIFIED> => 0

=item * C<DEDICATED_KEY_PROJECT> => 1

=item * C<RESOURCE_PROJECT> => 2

=item * C<DISABLED> => 3

=back

=cut

# === Message: Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest ===
    # Fields for ShowEffectiveAutokeyConfigRequest
    # Field: parent Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Kms::V1::AutokeyAdmin;

    my $msg = Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=back

=cut

# === Message: Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse ===
    # Fields for ShowEffectiveAutokeyConfigResponse
    # Field: key_project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Kms::V1::AutokeyAdmin;

    my $msg = Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse->new(
        key_project => $value,
    );

=head1 FIELDS

=over 4

=item * B<key_project>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyAdminClient ===
package Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyAdminClient;

=pod

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyAdminClient - Client stub representing the remote AutokeyAdmin service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<kms.googleapis.com:443>.

=head2 credentials

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

sub update_autokey_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.v1.AutokeyAdmin',
        method         => 'UpdateAutokeyConfig',
        request        => $req,
        response_class => 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig',
    });
}

sub get_autokey_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.v1.AutokeyAdmin',
        method         => 'GetAutokeyConfig',
        request        => $req,
        response_class => 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig',
    });
}

sub show_effective_autokey_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.kms.v1.AutokeyAdmin',
        method         => 'ShowEffectiveAutokeyConfig',
        request        => $req,
        response_class => 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
