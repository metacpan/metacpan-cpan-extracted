package Google::Monitoring::V3::NotificationService;

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
    eval { require Google::Monitoring::V3::Notification };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvbW9uaXRvcmluZy92My9ub3RpZmljYXRpb25fc2VydmljZS5wcm90bxIUZ29v
Z2xlLm1vbml0b3JpbmcudjMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2ds
ZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvbW9uaXRvcmluZy92My9ub3RpZmlj
YXRpb24ucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3Rv
YnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
vAEKKUxpc3ROb3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRvcnNSZXF1ZXN0ElMKBG5hbWUY
BCABKAlCP+BBAvpBORI3bW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbS9Ob3RpZmljYXRpb25D
aGFubmVsRGVzY3JpcHRvclIEbmFtZRIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0K
CnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiK6AQoqTGlzdE5vdGlmaWNhdGlvbkNoYW5u
ZWxEZXNjcmlwdG9yc1Jlc3BvbnNlEmQKE2NoYW5uZWxfZGVzY3JpcHRvcnMYASADKAsyMy5n
b29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRvclISY2hh
bm5lbERlc2NyaXB0b3JzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
biJ+CidHZXROb3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRvclJlcXVlc3QSUwoEbmFtZRgD
IAEoCUI/4EEC+kE5Cjdtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL05vdGlmaWNhdGlvbkNo
YW5uZWxEZXNjcmlwdG9yUgRuYW1lItABCiBDcmVhdGVOb3RpZmljYXRpb25DaGFubmVsUmVx
dWVzdBJJCgRuYW1lGAMgASgJQjXgQQL6QS8SLW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20v
Tm90aWZpY2F0aW9uQ2hhbm5lbFIEbmFtZRJhChRub3RpZmljYXRpb25fY2hhbm5lbBgCIAEo
CzIpLmdvb2dsZS5tb25pdG9yaW5nLnYzLk5vdGlmaWNhdGlvbkNoYW5uZWxCA+BBAlITbm90
aWZpY2F0aW9uQ2hhbm5lbCLvAQofTGlzdE5vdGlmaWNhdGlvbkNoYW5uZWxzUmVxdWVzdBJJ
CgRuYW1lGAUgASgJQjXgQQL6QS8SLW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vTm90aWZp
Y2F0aW9uQ2hhbm5lbFIEbmFtZRIbCgZmaWx0ZXIYBiABKAlCA+BBAVIGZmlsdGVyEh4KCG9y
ZGVyX2J5GAcgASgJQgPgQQFSB29yZGVyQnkSIAoJcGFnZV9zaXplGAMgASgFQgPgQQFSCHBh
Z2VTaXplEiIKCnBhZ2VfdG9rZW4YBCABKAlCA+BBAVIJcGFnZVRva2VuIskBCiBMaXN0Tm90
aWZpY2F0aW9uQ2hhbm5lbHNSZXNwb25zZRJeChVub3RpZmljYXRpb25fY2hhbm5lbHMYAyAD
KAsyKS5nb29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVsUhRub3RpZmlj
YXRpb25DaGFubmVscxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4S
HQoKdG90YWxfc2l6ZRgEIAEoBVIJdG90YWxTaXplImoKHUdldE5vdGlmaWNhdGlvbkNoYW5u
ZWxSZXF1ZXN0EkkKBG5hbWUYAyABKAlCNeBBAvpBLwotbW9uaXRvcmluZy5nb29nbGVhcGlz
LmNvbS9Ob3RpZmljYXRpb25DaGFubmVsUgRuYW1lIscBCiBVcGRhdGVOb3RpZmljYXRpb25D
aGFubmVsUmVxdWVzdBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJhChRub3RpZmljYXRpb25fY2hhbm5lbBgDIAEo
CzIpLmdvb2dsZS5tb25pdG9yaW5nLnYzLk5vdGlmaWNhdGlvbkNoYW5uZWxCA+BBAlITbm90
aWZpY2F0aW9uQ2hhbm5lbCKDAQogRGVsZXRlTm90aWZpY2F0aW9uQ2hhbm5lbFJlcXVlc3QS
SQoEbmFtZRgDIAEoCUI14EEC+kEvCi1tb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL05vdGlm
aWNhdGlvbkNoYW5uZWxSBG5hbWUSFAoFZm9yY2UYBSABKAhSBWZvcmNlInsKLlNlbmROb3Rp
ZmljYXRpb25DaGFubmVsVmVyaWZpY2F0aW9uQ29kZVJlcXVlc3QSSQoEbmFtZRgBIAEoCUI1
4EEC+kEvCi1tb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL05vdGlmaWNhdGlvbkNoYW5uZWxS
BG5hbWUitwEKLUdldE5vdGlmaWNhdGlvbkNoYW5uZWxWZXJpZmljYXRpb25Db2RlUmVxdWVz
dBJJCgRuYW1lGAEgASgJQjXgQQL6QS8KLW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vTm90
aWZpY2F0aW9uQ2hhbm5lbFIEbmFtZRI7CgtleHBpcmVfdGltZRgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCmV4cGlyZVRpbWUigQEKLkdldE5vdGlmaWNhdGlvbkNoYW5u
ZWxWZXJpZmljYXRpb25Db2RlUmVzcG9uc2USEgoEY29kZRgBIAEoCVIEY29kZRI7CgtleHBp
cmVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmV4cGlyZVRpbWUi
hgEKIFZlcmlmeU5vdGlmaWNhdGlvbkNoYW5uZWxSZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBB
AvpBLwotbW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbS9Ob3RpZmljYXRpb25DaGFubmVsUgRu
YW1lEhcKBGNvZGUYAiABKAlCA+BBAlIEY29kZTLqEgoaTm90aWZpY2F0aW9uQ2hhbm5lbFNl
cnZpY2US7AEKIkxpc3ROb3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRvcnMSPy5nb29nbGUu
bW9uaXRvcmluZy52My5MaXN0Tm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3JzUmVxdWVz
dBpALmdvb2dsZS5tb25pdG9yaW5nLnYzLkxpc3ROb3RpZmljYXRpb25DaGFubmVsRGVzY3Jp
cHRvcnNSZXNwb25zZSJDgtPkkwI2EjQvdjMve25hbWU9cHJvamVjdHMvKn0vbm90aWZpY2F0
aW9uQ2hhbm5lbERlc2NyaXB0b3Jz2kEEbmFtZRLdAQogR2V0Tm90aWZpY2F0aW9uQ2hhbm5l
bERlc2NyaXB0b3ISPS5nb29nbGUubW9uaXRvcmluZy52My5HZXROb3RpZmljYXRpb25DaGFu
bmVsRGVzY3JpcHRvclJlcXVlc3QaMy5nb29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRp
b25DaGFubmVsRGVzY3JpcHRvciJFgtPkkwI4EjYvdjMve25hbWU9cHJvamVjdHMvKi9ub3Rp
ZmljYXRpb25DaGFubmVsRGVzY3JpcHRvcnMvKn3aQQRuYW1lEsQBChhMaXN0Tm90aWZpY2F0
aW9uQ2hhbm5lbHMSNS5nb29nbGUubW9uaXRvcmluZy52My5MaXN0Tm90aWZpY2F0aW9uQ2hh
bm5lbHNSZXF1ZXN0GjYuZ29vZ2xlLm1vbml0b3JpbmcudjMuTGlzdE5vdGlmaWNhdGlvbkNo
YW5uZWxzUmVzcG9uc2UiOYLT5JMCLBIqL3YzL3tuYW1lPXByb2plY3RzLyp9L25vdGlmaWNh
dGlvbkNoYW5uZWxz2kEEbmFtZRK1AQoWR2V0Tm90aWZpY2F0aW9uQ2hhbm5lbBIzLmdvb2ds
ZS5tb25pdG9yaW5nLnYzLkdldE5vdGlmaWNhdGlvbkNoYW5uZWxSZXF1ZXN0GikuZ29vZ2xl
Lm1vbml0b3JpbmcudjMuTm90aWZpY2F0aW9uQ2hhbm5lbCI7gtPkkwIuEiwvdjMve25hbWU9
cHJvamVjdHMvKi9ub3RpZmljYXRpb25DaGFubmVscy8qfdpBBG5hbWUS5AEKGUNyZWF0ZU5v
dGlmaWNhdGlvbkNoYW5uZWwSNi5nb29nbGUubW9uaXRvcmluZy52My5DcmVhdGVOb3RpZmlj
YXRpb25DaGFubmVsUmVxdWVzdBopLmdvb2dsZS5tb25pdG9yaW5nLnYzLk5vdGlmaWNhdGlv
bkNoYW5uZWwiZILT5JMCQiIqL3YzL3tuYW1lPXByb2plY3RzLyp9L25vdGlmaWNhdGlvbkNo
YW5uZWxzOhRub3RpZmljYXRpb25fY2hhbm5lbNpBGW5hbWUsbm90aWZpY2F0aW9uX2NoYW5u
ZWwSgwIKGVVwZGF0ZU5vdGlmaWNhdGlvbkNoYW5uZWwSNi5nb29nbGUubW9uaXRvcmluZy52
My5VcGRhdGVOb3RpZmljYXRpb25DaGFubmVsUmVxdWVzdBopLmdvb2dsZS5tb25pdG9yaW5n
LnYzLk5vdGlmaWNhdGlvbkNoYW5uZWwiggGC0+STAlkyQS92My97bm90aWZpY2F0aW9uX2No
YW5uZWwubmFtZT1wcm9qZWN0cy8qL25vdGlmaWNhdGlvbkNoYW5uZWxzLyp9OhRub3RpZmlj
YXRpb25fY2hhbm5lbNpBIHVwZGF0ZV9tYXNrLG5vdGlmaWNhdGlvbl9jaGFubmVsEq4BChlE
ZWxldGVOb3RpZmljYXRpb25DaGFubmVsEjYuZ29vZ2xlLm1vbml0b3JpbmcudjMuRGVsZXRl
Tm90aWZpY2F0aW9uQ2hhbm5lbFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiQYLT
5JMCLiosL3YzL3tuYW1lPXByb2plY3RzLyovbm90aWZpY2F0aW9uQ2hhbm5lbHMvKn3aQQpu
YW1lLGZvcmNlEtwBCidTZW5kTm90aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNhdGlvbkNvZGUS
RC5nb29nbGUubW9uaXRvcmluZy52My5TZW5kTm90aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNh
dGlvbkNvZGVSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IlOC0+STAkYiQS92My97
bmFtZT1wcm9qZWN0cy8qL25vdGlmaWNhdGlvbkNoYW5uZWxzLyp9OnNlbmRWZXJpZmljYXRp
b25Db2RlOgEq2kEEbmFtZRKHAgomR2V0Tm90aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNhdGlv
bkNvZGUSQy5nb29nbGUubW9uaXRvcmluZy52My5HZXROb3RpZmljYXRpb25DaGFubmVsVmVy
aWZpY2F0aW9uQ29kZVJlcXVlc3QaRC5nb29nbGUubW9uaXRvcmluZy52My5HZXROb3RpZmlj
YXRpb25DaGFubmVsVmVyaWZpY2F0aW9uQ29kZVJlc3BvbnNlIlKC0+STAkUiQC92My97bmFt
ZT1wcm9qZWN0cy8qL25vdGlmaWNhdGlvbkNoYW5uZWxzLyp9OmdldFZlcmlmaWNhdGlvbkNv
ZGU6ASraQQRuYW1lEsoBChlWZXJpZnlOb3RpZmljYXRpb25DaGFubmVsEjYuZ29vZ2xlLm1v
bml0b3JpbmcudjMuVmVyaWZ5Tm90aWZpY2F0aW9uQ2hhbm5lbFJlcXVlc3QaKS5nb29nbGUu
bW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVsIkqC0+STAjgiMy92My97bmFtZT1w
cm9qZWN0cy8qL25vdGlmaWNhdGlvbkNoYW5uZWxzLyp9OnZlcmlmeToBKtpBCW5hbWUsY29k
ZRqpAcpBGW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb23SQYkBaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL21vbml0b3JpbmcsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9tb25p
dG9yaW5nLnJlYWRC0wEKGGNvbS5nb29nbGUubW9uaXRvcmluZy52M0IYTm90aWZpY2F0aW9u
U2VydmljZVByb3RvUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9hcGl2My92
Mi9tb25pdG9yaW5ncGI7bW9uaXRvcmluZ3BiqgIaR29vZ2xlLkNsb3VkLk1vbml0b3Jpbmcu
VjPKAhpHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xWM+oCHUdvb2dsZTo6Q2xvdWQ6Ok1vbml0
b3Jpbmc6OlYzSsp5CgcSBQ4AwAMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAdCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ACMKCQoCAwQSAxYAMQoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCQoCAwcSAxkAKQoICgEIEgMb
ADcKCQoCCCUSAxsANwoICgEIEgMcAFgKCQoCCAsSAxwAWAoICgEIEgMdACIKCQoCCAoSAx0A
IgoICgEIEgMeADkKCQoCCAgSAx4AOQoICgEIEgMfADEKCQoCCAESAx8AMQoICgEIEgMgADcK
CQoCCCkSAyAANwoICgEIEgMhADYKCQoCCC0SAyEANgqHAQoCBgASBSUAvQEBGnogVGhlIE5v
dGlmaWNhdGlvbiBDaGFubmVsIEFQSSBwcm92aWRlcyBhY2Nlc3MgdG8gY29uZmlndXJhdGlv
biB0aGF0CiBjb250cm9scyBob3cgbWVzc2FnZXMgcmVsYXRlZCB0byBpbmNpZGVudHMgYXJl
IHNlbnQuCgoKCgMGAAESAyUIIgoKCgMGAAMSAyYCQQoMCgUGAAOZCBIDJgJBCgsKAwYAAxIE
JwIqOAoNCgUGAAOaCBIEJwIqOAqcAQoEBgACABIELgI1AxqNASBMaXN0cyB0aGUgZGVzY3Jp
cHRvcnMgZm9yIHN1cHBvcnRlZCBjaGFubmVsIHR5cGVzLiBUaGUgdXNlIG9mIGRlc2NyaXB0
b3JzCiBtYWtlcyBpdCBwb3NzaWJsZSBmb3IgbmV3IGNoYW5uZWwgdHlwZXMgdG8gYmUgZHlu
YW1pY2FsbHkgYWRkZWQuCgoMCgUGAAIAARIDLgYoCgwKBQYAAgACEgMvBi8KDAoFBgACAAMS
AzAPOQoNCgUGAAIABBIEMQQzBgoRCgkGAAIABLDKvCISBDEEMwYKDAoFBgACAAQSAzQEMgoP
CggGAAIABJsIABIDNAQyCqABCgQGAAIBEgQ5Aj8DGpEBIEdldHMgYSBzaW5nbGUgY2hhbm5l
bCBkZXNjcmlwdG9yLiBUaGUgZGVzY3JpcHRvciBpbmRpY2F0ZXMgd2hpY2ggZmllbGRzCiBh
cmUgZXhwZWN0ZWQgLyBwZXJtaXR0ZWQgZm9yIGEgbm90aWZpY2F0aW9uIGNoYW5uZWwgb2Yg
dGhlIGdpdmVuIHR5cGUuCgoMCgUGAAIBARIDOQYmCgwKBQYAAgECEgM5J04KDAoFBgACAQMS
AzoPLAoNCgUGAAIBBBIEOwQ9BgoRCgkGAAIBBLDKvCISBDsEPQYKDAoFBgACAQQSAz4EMgoP
CggGAAIBBJsIABIDPgQyCs4BCgQGAAICEgREAkoDGr8BIExpc3RzIHRoZSBub3RpZmljYXRp
b24gY2hhbm5lbHMgdGhhdCBoYXZlIGJlZW4gY3JlYXRlZCBmb3IgdGhlIHByb2plY3QuCiBU
byBsaXN0IHRoZSB0eXBlcyBvZiBub3RpZmljYXRpb24gY2hhbm5lbHMgdGhhdCBhcmUgc3Vw
cG9ydGVkLCB1c2UKIHRoZSBgTGlzdE5vdGlmaWNhdGlvbkNoYW5uZWxEZXNjcmlwdG9yc2Ag
bWV0aG9kLgoKDAoFBgACAgESA0QGHgoMCgUGAAICAhIDRB8+CgwKBQYAAgIDEgNFDy8KDQoF
BgACAgQSBEYESAYKEQoJBgACAgSwyrwiEgRGBEgGCgwKBQYAAgIEEgNJBDIKDwoIBgACAgSb
CAASA0kEMgrnAgoEBgACAxIEUQJXAxrYAiBHZXRzIGEgc2luZ2xlIG5vdGlmaWNhdGlvbiBj
aGFubmVsLiBUaGUgY2hhbm5lbCBpbmNsdWRlcyB0aGUgcmVsZXZhbnQKIGNvbmZpZ3VyYXRp
b24gZGV0YWlscyB3aXRoIHdoaWNoIHRoZSBjaGFubmVsIHdhcyBjcmVhdGVkLiBIb3dldmVy
LCB0aGUKIHJlc3BvbnNlIG1heSB0cnVuY2F0ZSBvciBvbWl0IHBhc3N3b3JkcywgQVBJIGtl
eXMsIG9yIG90aGVyIHByaXZhdGUga2V5CiBtYXR0ZXIgYW5kIHRodXMgdGhlIHJlc3BvbnNl
IG1heSBub3QgYmUgMTAwJSBpZGVudGljYWwgdG8gdGhlIGluZm9ybWF0aW9uCiB0aGF0IHdh
cyBzdXBwbGllZCBpbiB0aGUgY2FsbCB0byB0aGUgY3JlYXRlIG1ldGhvZC4KCgwKBQYAAgMB
EgNRBhwKDAoFBgACAwISA1EdOgoMCgUGAAIDAxIDUg8iCg0KBQYAAgMEEgRTBFUGChEKCQYA
AgMEsMq8IhIEUwRVBgoMCgUGAAIDBBIDVgQyCg8KCAYAAgMEmwgAEgNWBDIKhAMKBAYAAgQS
BGACZwMa9QIgQ3JlYXRlcyBhIG5ldyBub3RpZmljYXRpb24gY2hhbm5lbCwgcmVwcmVzZW50
aW5nIGEgc2luZ2xlIG5vdGlmaWNhdGlvbgogZW5kcG9pbnQgc3VjaCBhcyBhbiBlbWFpbCBh
ZGRyZXNzLCBTTVMgbnVtYmVyLCBvciBQYWdlckR1dHkgc2VydmljZS4KCiBEZXNpZ24geW91
ciBhcHBsaWNhdGlvbiB0byBzaW5nbGUtdGhyZWFkIEFQSSBjYWxscyB0aGF0IG1vZGlmeSB0
aGUgc3RhdGUgb2YKIG5vdGlmaWNhdGlvbiBjaGFubmVscyBpbiBhIHNpbmdsZSBwcm9qZWN0
LiBUaGlzIGluY2x1ZGVzIGNhbGxzIHRvCiBDcmVhdGVOb3RpZmljYXRpb25DaGFubmVsLCBE
ZWxldGVOb3RpZmljYXRpb25DaGFubmVsIGFuZAogVXBkYXRlTm90aWZpY2F0aW9uQ2hhbm5l
bC4KCgwKBQYAAgQBEgNgBh8KDAoFBgACBAISA2AgQAoMCgUGAAIEAxIDYQ8iCg0KBQYAAgQE
EgRiBGUGChEKCQYAAgQEsMq8IhIEYgRlBgoMCgUGAAIEBBIDZgRHCg8KCAYAAgQEmwgAEgNm
BEcK0QIKBAYAAgUSBHACdwMawgIgVXBkYXRlcyBhIG5vdGlmaWNhdGlvbiBjaGFubmVsLiBG
aWVsZHMgbm90IHNwZWNpZmllZCBpbiB0aGUgZmllbGQgbWFzawogcmVtYWluIHVuY2hhbmdl
ZC4KCiBEZXNpZ24geW91ciBhcHBsaWNhdGlvbiB0byBzaW5nbGUtdGhyZWFkIEFQSSBjYWxs
cyB0aGF0IG1vZGlmeSB0aGUgc3RhdGUgb2YKIG5vdGlmaWNhdGlvbiBjaGFubmVscyBpbiBh
IHNpbmdsZSBwcm9qZWN0LiBUaGlzIGluY2x1ZGVzIGNhbGxzIHRvCiBDcmVhdGVOb3RpZmlj
YXRpb25DaGFubmVsLCBEZWxldGVOb3RpZmljYXRpb25DaGFubmVsIGFuZAogVXBkYXRlTm90
aWZpY2F0aW9uQ2hhbm5lbC4KCgwKBQYAAgUBEgNwBh8KDAoFBgACBQISA3AgQAoMCgUGAAIF
AxIDcQ8iCg0KBQYAAgUEEgRyBHUGChEKCQYAAgUEsMq8IhIEcgR1BgoMCgUGAAIFBBIDdgRO
Cg8KCAYAAgUEmwgAEgN2BE4KmAIKBAYAAgYSBX8ChQEDGogCIERlbGV0ZXMgYSBub3RpZmlj
YXRpb24gY2hhbm5lbC4KCiBEZXNpZ24geW91ciBhcHBsaWNhdGlvbiB0byBzaW5nbGUtdGhy
ZWFkIEFQSSBjYWxscyB0aGF0IG1vZGlmeSB0aGUgc3RhdGUgb2YKIG5vdGlmaWNhdGlvbiBj
aGFubmVscyBpbiBhIHNpbmdsZSBwcm9qZWN0LiBUaGlzIGluY2x1ZGVzIGNhbGxzIHRvCiBD
cmVhdGVOb3RpZmljYXRpb25DaGFubmVsLCBEZWxldGVOb3RpZmljYXRpb25DaGFubmVsIGFu
ZAogVXBkYXRlTm90aWZpY2F0aW9uQ2hhbm5lbC4KCgwKBQYAAgYBEgN/Bh8KDAoFBgACBgIS
A38gQAoNCgUGAAIGAxIEgAEPJAoPCgUGAAIGBBIGgQEEgwEGChMKCQYAAgYEsMq8IhIGgQEE
gwEGCg0KBQYAAgYEEgSEAQQ4ChAKCAYAAgYEmwgAEgSEAQQ4CqIBCgQGAAIHEgaJAQKRAQMa
kQEgQ2F1c2VzIGEgdmVyaWZpY2F0aW9uIGNvZGUgdG8gYmUgZGVsaXZlcmVkIHRvIHRoZSBj
aGFubmVsLiBUaGUgY29kZQogY2FuIHRoZW4gYmUgc3VwcGxpZWQgaW4gYFZlcmlmeU5vdGlm
aWNhdGlvbkNoYW5uZWxgIHRvIHZlcmlmeSB0aGUgY2hhbm5lbC4KCg0KBQYAAgcBEgSJAQYt
Cg0KBQYAAgcCEgSKAQY0Cg0KBQYAAgcDEgSLAQ8kCg8KBQYAAgcEEgaMAQSPAQYKEwoJBgAC
BwSwyrwiEgaMAQSPAQYKDQoFBgACBwQSBJABBDIKEAoIBgACBwSbCAASBJABBDIKugoKBAYA
AggSBqgBArABAxqpCiBSZXF1ZXN0cyBhIHZlcmlmaWNhdGlvbiBjb2RlIGZvciBhbiBhbHJl
YWR5IHZlcmlmaWVkIGNoYW5uZWwgdGhhdCBjYW4gdGhlbgogYmUgdXNlZCBpbiBhIGNhbGwg
dG8gVmVyaWZ5Tm90aWZpY2F0aW9uQ2hhbm5lbCgpIG9uIGEgZGlmZmVyZW50IGNoYW5uZWwK
IHdpdGggYW4gZXF1aXZhbGVudCBpZGVudGl0eSBpbiB0aGUgc2FtZSBvciBpbiBhIGRpZmZl
cmVudCBwcm9qZWN0LiBUaGlzCiBtYWtlcyBpdCBwb3NzaWJsZSB0byBjb3B5IGEgY2hhbm5l
bCBiZXR3ZWVuIHByb2plY3RzIHdpdGhvdXQgcmVxdWlyaW5nCiBtYW51YWwgcmV2ZXJpZmlj
YXRpb24gb2YgdGhlIGNoYW5uZWwuIElmIHRoZSBjaGFubmVsIGlzIG5vdCBpbiB0aGUKIHZl
cmlmaWVkIHN0YXRlLCB0aGlzIG1ldGhvZCB3aWxsIGZhaWwgKGluIG90aGVyIHdvcmRzLCB0
aGlzIG1heSBvbmx5IGJlCiB1c2VkIGlmIHRoZSBTZW5kTm90aWZpY2F0aW9uQ2hhbm5lbFZl
cmlmaWNhdGlvbkNvZGUgYW5kCiBWZXJpZnlOb3RpZmljYXRpb25DaGFubmVsIHBhdGhzIGhh
dmUgYWxyZWFkeSBiZWVuIHVzZWQgdG8gcHV0IHRoZSBnaXZlbgogY2hhbm5lbCBpbnRvIHRo
ZSB2ZXJpZmllZCBzdGF0ZSkuCgogVGhlcmUgaXMgbm8gZ3VhcmFudGVlIHRoYXQgdGhlIHZl
cmlmaWNhdGlvbiBjb2RlcyByZXR1cm5lZCBieSB0aGlzIG1ldGhvZAogd2lsbCBiZSBvZiBh
IHNpbWlsYXIgc3RydWN0dXJlIG9yIGZvcm0gYXMgdGhlIG9uZXMgdGhhdCBhcmUgZGVsaXZl
cmVkCiB0byB0aGUgY2hhbm5lbCB2aWEgU2VuZE5vdGlmaWNhdGlvbkNoYW5uZWxWZXJpZmlj
YXRpb25Db2RlOyB3aGlsZQogVmVyaWZ5Tm90aWZpY2F0aW9uQ2hhbm5lbCgpIHdpbGwgcmVj
b2duaXplIGJvdGggdGhlIGNvZGVzIGRlbGl2ZXJlZCB2aWEKIFNlbmROb3RpZmljYXRpb25D
aGFubmVsVmVyaWZpY2F0aW9uQ29kZSgpIGFuZCByZXR1cm5lZCBmcm9tCiBHZXROb3RpZmlj
YXRpb25DaGFubmVsVmVyaWZpY2F0aW9uQ29kZSgpLCBpdCBpcyB0eXBpY2FsbHkgdGhlIGNh
c2UgdGhhdAogdGhlIHZlcmlmaWNhdGlvbiBjb2RlcyBkZWxpdmVyZWQgdmlhCiBTZW5kTm90
aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNhdGlvbkNvZGUoKSB3aWxsIGJlIHNob3J0ZXIgYW5k
IGFsc28KIGhhdmUgYSBzaG9ydGVyIGV4cGlyYXRpb24gKGUuZy4gY29kZXMgc3VjaCBhcyAi
Ry0xMjM0NTYiKSB3aGVyZWFzCiBHZXRWZXJpZmljYXRpb25Db2RlKCkgd2lsbCB0eXBpY2Fs
bHkgcmV0dXJuIGEgbXVjaCBsb25nZXIsIHdlYnNhZmUgYmFzZQogNjQgZW5jb2RlZCBzdHJp
bmcgdGhhdCBoYXMgYSBsb25nZXIgZXhwaXJhdGlvbiB0aW1lLgoKDQoFBgACCAESBKgBBiwK
DQoFBgACCAISBKkBBjMKDQoFBgACCAMSBKoBDz0KDwoFBgACCAQSBqsBBK4BBgoTCgkGAAII
BLDKvCISBqsBBK4BBgoNCgUGAAIIBBIErwEEMgoQCggGAAIIBJsIABIErwEEMgqvAQoEBgAC
CRIGtQECvAEDGp4BIFZlcmlmaWVzIGEgYE5vdGlmaWNhdGlvbkNoYW5uZWxgIGJ5IHByb3Zp
bmcgcmVjZWlwdCBvZiB0aGUgY29kZQogZGVsaXZlcmVkIHRvIHRoZSBjaGFubmVsIGFzIGEg
cmVzdWx0IG9mIGNhbGxpbmcKIGBTZW5kTm90aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNhdGlv
bkNvZGVgLgoKDQoFBgACCQESBLUBBh8KDQoFBgACCQISBLUBIEAKDQoFBgACCQMSBLYBDyIK
DwoFBgACCQQSBrcBBLoBBgoTCgkGAAIJBLDKvCISBrcBBLoBBgoNCgUGAAIJBBIEuwEENwoQ
CggGAAIJBJsIABIEuwEENwpBCgIEABIGwAEA3AEBGjMgVGhlIGBMaXN0Tm90aWZpY2F0aW9u
Q2hhbm5lbERlc2NyaXB0b3JzYCByZXF1ZXN0LgoKCwoDBAABEgTAAQgxCokECgQEAAIAEgbM
AQLRAQQa+AMgUmVxdWlyZWQuIFRoZSBSRVNUIHJlc291cmNlIG5hbWUgb2YgdGhlIHBhcmVu
dCBmcm9tIHdoaWNoIHRvIHJldHJpZXZlCiB0aGUgbm90aWZpY2F0aW9uIGNoYW5uZWwgZGVz
Y3JpcHRvcnMuIFRoZSBleHBlY3RlZCBzeW50YXggaXM6CgogICAgIHByb2plY3RzL1tQUk9K
RUNUX0lEX09SX05VTUJFUl0KCiBOb3RlIHRoYXQgdGhpcwogW25hbWVzXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vbW9uaXRvcmluZy9hcGkvdjMjcHJvamVjdF9uYW1lKSB0aGUgcGFy
ZW50CiBjb250YWluZXIgaW4gd2hpY2ggdG8gbG9vayBmb3IgdGhlIGRlc2NyaXB0b3JzOyB0
byByZXRyaWV2ZSBhIHNpbmdsZQogZGVzY3JpcHRvciBieSBuYW1lLCB1c2UgdGhlCiBbR2V0
Tm90aWZpY2F0aW9uQ2hhbm5lbERlc2NyaXB0b3JdW2dvb2dsZS5tb25pdG9yaW5nLnYzLk5v
dGlmaWNhdGlvbkNoYW5uZWxTZXJ2aWNlLkdldE5vdGlmaWNhdGlvbkNoYW5uZWxEZXNjcmlw
dG9yXQogb3BlcmF0aW9uLCBpbnN0ZWFkLgoKDQoFBAACAAUSBMwBAggKDQoFBAACAAESBMwB
CQ0KDQoFBAACAAMSBMwBEBEKDwoFBAACAAgSBswBEtEBAwoQCggEAAIACJwIABIEzQEEKgoR
CgcEAAIACJ8IEgbOAQTQAQUKowEKBAQAAgESBNYBAhYalAEgVGhlIG1heGltdW0gbnVtYmVy
IG9mIHJlc3VsdHMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHJlc3BvbnNlLiBJZgogbm90IHNl
dCB0byBhIHBvc2l0aXZlIG51bWJlciwgYSByZWFzb25hYmxlIHZhbHVlIHdpbGwgYmUgY2hv
c2VuIGJ5IHRoZQogc2VydmljZS4KCg0KBQQAAgEFEgTWAQIHCg0KBQQAAgEBEgTWAQgRCg0K
BQQAAgEDEgTWARQVCp8BCgQEAAICEgTbAQIYGpABIElmIG5vbi1lbXB0eSwgYHBhZ2VfdG9r
ZW5gIG11c3QgY29udGFpbiBhIHZhbHVlIHJldHVybmVkIGFzIHRoZQogYG5leHRfcGFnZV90
b2tlbmAgaW4gYSBwcmV2aW91cyByZXNwb25zZSB0byByZXF1ZXN0IHRoZSBuZXh0IHNldAog
b2YgcmVzdWx0cy4KCg0KBQQAAgIFEgTbAQIICg0KBQQAAgIBEgTbAQkTCg0KBQQAAgIDEgTb
ARYXCkIKAgQBEgbfAQDpAQEaNCBUaGUgYExpc3ROb3RpZmljYXRpb25DaGFubmVsRGVzY3Jp
cHRvcnNgIHJlc3BvbnNlLgoKCwoDBAEBEgTfAQgyCm0KBAQBAgASBOIBAkEaXyBUaGUgbW9u
aXRvcmVkIHJlc291cmNlIGRlc2NyaXB0b3JzIHN1cHBvcnRlZCBmb3IgdGhlIHNwZWNpZmll
ZAogcHJvamVjdCwgb3B0aW9uYWxseSBmaWx0ZXJlZC4KCg0KBQQBAgAEEgTiAQIKCg0KBQQB
AgAGEgTiAQsoCg0KBQQBAgABEgTiASk8Cg0KBQQBAgADEgTiAT9ACu4BCgQEAQIBEgToAQId
Gt8BIElmIG5vdCBlbXB0eSwgaW5kaWNhdGVzIHRoYXQgdGhlcmUgbWF5IGJlIG1vcmUgcmVz
dWx0cyB0aGF0IG1hdGNoCiB0aGUgcmVxdWVzdC4gVXNlIHRoZSB2YWx1ZSBpbiB0aGUgYHBh
Z2VfdG9rZW5gIGZpZWxkIGluIGEKIHN1YnNlcXVlbnQgcmVxdWVzdCB0byBmZXRjaCB0aGUg
bmV4dCBzZXQgb2YgcmVzdWx0cy4gSWYgZW1wdHksCiBhbGwgcmVzdWx0cyBoYXZlIGJlZW4g
cmV0dXJuZWQuCgoNCgUEAQIBBRIE6AECCAoNCgUEAQIBARIE6AEJGAoNCgUEAQIBAxIE6AEb
HApACgIEAhIG7AEA9gEBGjIgVGhlIGBHZXROb3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRv
cmAgcmVzcG9uc2UuCgoLCgMEAgESBOwBCC8KsgEKBAQCAgASBvABAvUBBBqhASBSZXF1aXJl
ZC4gVGhlIGNoYW5uZWwgdHlwZSBmb3Igd2hpY2ggdG8gZXhlY3V0ZSB0aGUgcmVxdWVzdC4g
VGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXS9u
b3RpZmljYXRpb25DaGFubmVsRGVzY3JpcHRvcnMvW0NIQU5ORUxfVFlQRV0KCg0KBQQCAgAF
EgTwAQIICg0KBQQCAgABEgTwAQkNCg0KBQQCAgADEgTwARARCg8KBQQCAgAIEgbwARL1AQMK
EAoIBAICAAicCAASBPEBBCoKEQoHBAICAAifCBIG8gEE9AEFCjgKAgQDEgb5AQCOAgEaKiBU
aGUgYENyZWF0ZU5vdGlmaWNhdGlvbkNoYW5uZWxgIHJlcXVlc3QuCgoLCgMEAwESBPkBCCgK
0QMKBAQDAgASBoQCAokCBBrAAyBSZXF1aXJlZC4gVGhlCiBbcHJvamVjdF0oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3YzI3Byb2plY3RfbmFtZSkgb24gd2hp
Y2gKIHRvIGV4ZWN1dGUgdGhlIHJlcXVlc3QuIFRoZSBmb3JtYXQgaXM6CgogICAgIHByb2pl
Y3RzL1tQUk9KRUNUX0lEX09SX05VTUJFUl0KCiBUaGlzIG5hbWVzIHRoZSBjb250YWluZXIg
aW50byB3aGljaCB0aGUgY2hhbm5lbCB3aWxsIGJlCiB3cml0dGVuLCB0aGlzIGRvZXMgbm90
IG5hbWUgdGhlIG5ld2x5IGNyZWF0ZWQgY2hhbm5lbC4gVGhlIHJlc3VsdGluZwogY2hhbm5l
bCdzIG5hbWUgd2lsbCBoYXZlIGEgbm9ybWFsaXplZCB2ZXJzaW9uIG9mIHRoaXMgZmllbGQg
YXMgYSBwcmVmaXgsCiBidXQgd2lsbCBhZGQgYC9ub3RpZmljYXRpb25DaGFubmVscy9bQ0hB
Tk5FTF9JRF1gIHRvIGlkZW50aWZ5IHRoZSBjaGFubmVsLgoKDQoFBAMCAAUSBIQCAggKDQoF
BAMCAAESBIQCCQ0KDQoFBAMCAAMSBIQCEBEKDwoFBAMCAAgSBoQCEokCAwoQCggEAwIACJwI
ABIEhQIEKgoRCgcEAwIACJ8IEgaGAgSIAgUKUgoEBAMCARIGjAICjQIvGkIgUmVxdWlyZWQu
IFRoZSBkZWZpbml0aW9uIG9mIHRoZSBgTm90aWZpY2F0aW9uQ2hhbm5lbGAgdG8gY3JlYXRl
LgoKDQoFBAMCAQYSBIwCAhUKDQoFBAMCAQESBIwCFioKDQoFBAMCAQMSBIwCLS4KDQoFBAMC
AQgSBI0CBi4KEAoIBAMCAQicCAASBI0CBy0KNwoCBAQSBpECAL0CARopIFRoZSBgTGlzdE5v
dGlmaWNhdGlvbkNoYW5uZWxzYCByZXF1ZXN0LgoKCwoDBAQBEgSRAggnCtkDCgQEBAIAEgae
AgKjAgQayAMgUmVxdWlyZWQuIFRoZQogW3Byb2plY3RdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9tb25pdG9yaW5nL2FwaS92MyNwcm9qZWN0X25hbWUpIG9uIHdoaWNoCiB0byBleGVj
dXRlIHRoZSByZXF1ZXN0LiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVD
VF9JRF9PUl9OVU1CRVJdCgogVGhpcyBuYW1lcyB0aGUgY29udGFpbmVyCiBpbiB3aGljaCB0
byBsb29rIGZvciB0aGUgbm90aWZpY2F0aW9uIGNoYW5uZWxzOyBpdCBkb2VzIG5vdCBuYW1l
IGEKIHNwZWNpZmljIGNoYW5uZWwuIFRvIHF1ZXJ5IGEgc3BlY2lmaWMgY2hhbm5lbCBieSBS
RVNUIHJlc291cmNlIG5hbWUsIHVzZQogdGhlCiBbYEdldE5vdGlmaWNhdGlvbkNoYW5uZWxg
XVtnb29nbGUubW9uaXRvcmluZy52My5Ob3RpZmljYXRpb25DaGFubmVsU2VydmljZS5HZXRO
b3RpZmljYXRpb25DaGFubmVsXQogb3BlcmF0aW9uLgoKDQoFBAQCAAUSBJ4CAggKDQoFBAQC
AAESBJ4CCQ0KDQoFBAQCAAMSBJ4CEBEKDwoFBAQCAAgSBp4CEqMCAwoQCggEBAIACJwIABIE
nwIEKgoRCgcEBAIACJ8IEgagAgSiAgUKiAIKBAQEAgESBKoCAj0a+QEgT3B0aW9uYWwuIElm
IHByb3ZpZGVkLCB0aGlzIGZpZWxkIHNwZWNpZmllcyB0aGUgY3JpdGVyaWEgdGhhdCBtdXN0
IGJlIG1ldAogYnkgbm90aWZpY2F0aW9uIGNoYW5uZWxzIHRvIGJlIGluY2x1ZGVkIGluIHRo
ZSByZXNwb25zZS4KCiBGb3IgbW9yZSBkZXRhaWxzLCBzZWUgW3NvcnRpbmcgYW5kCiBmaWx0
ZXJpbmddKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9tb25pdG9yaW5nL2FwaS92My9zb3J0
aW5nLWFuZC1maWx0ZXJpbmcpLgoKDQoFBAQCAQUSBKoCAggKDQoFBAQCAQESBKoCCQ8KDQoF
BAQCAQMSBKoCEhMKDQoFBAQCAQgSBKoCFDwKEAoIBAQCAQicCAASBKoCFTsK2wIKBAQEAgIS
BLICAj8azAIgT3B0aW9uYWwuIEEgY29tbWEtc2VwYXJhdGVkIGxpc3Qgb2YgZmllbGRzIGJ5
IHdoaWNoIHRvIHNvcnQgdGhlIHJlc3VsdC4KIFN1cHBvcnRzIHRoZSBzYW1lIHNldCBvZiBm
aWVsZHMgYXMgaW4gYGZpbHRlcmAuIEVudHJpZXMgY2FuIGJlIHByZWZpeGVkCiB3aXRoIGEg
bWludXMgc2lnbiB0byBzb3J0IGluIGRlc2NlbmRpbmcgcmF0aGVyIHRoYW4gYXNjZW5kaW5n
IG9yZGVyLgoKIEZvciBtb3JlIGRldGFpbHMsIHNlZSBbc29ydGluZyBhbmQKIGZpbHRlcmlu
Z10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3YzL3NvcnRpbmct
YW5kLWZpbHRlcmluZykuCgoNCgUEBAICBRIEsgICCAoNCgUEBAICARIEsgIJEQoNCgUEBAIC
AxIEsgIUFQoNCgUEBAICCBIEsgIWPgoQCggEBAICCJwIABIEsgIXPQqtAQoEBAQCAxIEtwIC
PxqeASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJu
IGluIGEgc2luZ2xlIHJlc3BvbnNlLiBJZgogbm90IHNldCB0byBhIHBvc2l0aXZlIG51bWJl
ciwgYSByZWFzb25hYmxlIHZhbHVlIHdpbGwgYmUgY2hvc2VuIGJ5IHRoZQogc2VydmljZS4K
Cg0KBQQEAgMFEgS3AgIHCg0KBQQEAgMBEgS3AggRCg0KBQQEAgMDEgS3AhQVCg0KBQQEAgMI
EgS3AhY+ChAKCAQEAgMInAgAEgS3Ahc9CqkBCgQEBAIEEgS8AgJBGpoBIE9wdGlvbmFsLiBJ
ZiBub24tZW1wdHksIGBwYWdlX3Rva2VuYCBtdXN0IGNvbnRhaW4gYSB2YWx1ZSByZXR1cm5l
ZCBhcyB0aGUKIGBuZXh0X3BhZ2VfdG9rZW5gIGluIGEgcHJldmlvdXMgcmVzcG9uc2UgdG8g
cmVxdWVzdCB0aGUgbmV4dCBzZXQKIG9mIHJlc3VsdHMuCgoNCgUEBAIEBRIEvAICCAoNCgUE
BAIEARIEvAIJEwoNCgUEBAIEAxIEvAIWFwoNCgUEBAIECBIEvAIYQAoQCggEBAIECJwIABIE
vAIZPwo4CgIEBRIGwAIAzQIBGiogVGhlIGBMaXN0Tm90aWZpY2F0aW9uQ2hhbm5lbHNgIHJl
c3BvbnNlLgoKCwoDBAUBEgTAAggoCkwKBAQFAgASBMICAjkaPiBUaGUgbm90aWZpY2F0aW9u
IGNoYW5uZWxzIGRlZmluZWQgZm9yIHRoZSBzcGVjaWZpZWQgcHJvamVjdC4KCg0KBQQFAgAE
EgTCAgIKCg0KBQQFAgAGEgTCAgseCg0KBQQFAgABEgTCAh80Cg0KBQQFAgADEgTCAjc4Cu4B
CgQEBQIBEgTIAgIdGt8BIElmIG5vdCBlbXB0eSwgaW5kaWNhdGVzIHRoYXQgdGhlcmUgbWF5
IGJlIG1vcmUgcmVzdWx0cyB0aGF0IG1hdGNoCiB0aGUgcmVxdWVzdC4gVXNlIHRoZSB2YWx1
ZSBpbiB0aGUgYHBhZ2VfdG9rZW5gIGZpZWxkIGluIGEKIHN1YnNlcXVlbnQgcmVxdWVzdCB0
byBmZXRjaCB0aGUgbmV4dCBzZXQgb2YgcmVzdWx0cy4gSWYgZW1wdHksCiBhbGwgcmVzdWx0
cyBoYXZlIGJlZW4gcmV0dXJuZWQuCgoNCgUEBQIBBRIEyAICCAoNCgUEBQIBARIEyAIJGAoN
CgUEBQIBAxIEyAIbHAqiAQoEBAUCAhIEzAICFxqTASBUaGUgdG90YWwgbnVtYmVyIG9mIG5v
dGlmaWNhdGlvbiBjaGFubmVscyBpbiBhbGwgcGFnZXMuIFRoaXMgbnVtYmVyIGlzIG9ubHkK
IGFuIGVzdGltYXRlLCBhbmQgbWF5IGNoYW5nZSBpbiBzdWJzZXF1ZW50IHBhZ2VzLiBodHRw
czovL2FpcC5kZXYvMTU4CgoNCgUEBQICBRIEzAICBwoNCgUEBQICARIEzAIIEgoNCgUEBQIC
AxIEzAIVFgo1CgIEBhIG0AIA2gIBGicgVGhlIGBHZXROb3RpZmljYXRpb25DaGFubmVsYCBy
ZXF1ZXN0LgoKCwoDBAYBEgTQAgglCqEBCgQEBgIAEgbUAgLZAgQakAEgUmVxdWlyZWQuIFRo
ZSBjaGFubmVsIGZvciB3aGljaCB0byBleGVjdXRlIHRoZSByZXF1ZXN0LiBUaGUgZm9ybWF0
IGlzOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL25vdGlmaWNhdGlv
bkNoYW5uZWxzL1tDSEFOTkVMX0lEXQoKDQoFBAYCAAUSBNQCAggKDQoFBAYCAAESBNQCCQ0K
DQoFBAYCAAMSBNQCEBEKDwoFBAYCAAgSBtQCEtkCAwoQCggEBgIACJwIABIE1QIEKgoRCgcE
BgIACJ8IEgbWAgTYAgUKOAoCBAcSBt0CAOgCARoqIFRoZSBgVXBkYXRlTm90aWZpY2F0aW9u
Q2hhbm5lbGAgcmVxdWVzdC4KCgsKAwQHARIE3QIIKAoxCgQEBwIAEgbfAgLgAi8aISBPcHRp
b25hbC4gVGhlIGZpZWxkcyB0byB1cGRhdGUuCgoNCgUEBwIABhIE3wICGwoNCgUEBwIAARIE
3wIcJwoNCgUEBwIAAxIE3wIqKwoNCgUEBwIACBIE4AIGLgoQCggEBwIACJwIABIE4AIHLQr9
AQoEBAcCARIG5gIC5wIvGuwBIFJlcXVpcmVkLiBBIGRlc2NyaXB0aW9uIG9mIHRoZSBjaGFu
Z2VzIHRvIGJlIGFwcGxpZWQgdG8gdGhlIHNwZWNpZmllZAogbm90aWZpY2F0aW9uIGNoYW5u
ZWwuIFRoZSBkZXNjcmlwdGlvbiBtdXN0IHByb3ZpZGUgYSBkZWZpbml0aW9uIGZvcgogZmll
bGRzIHRvIGJlIHVwZGF0ZWQ7IHRoZSBuYW1lcyBvZiB0aGVzZSBmaWVsZHMgc2hvdWxkIGFs
c28gYmUKIGluY2x1ZGVkIGluIHRoZSBgdXBkYXRlX21hc2tgLgoKDQoFBAcCAQYSBOYCAhUK
DQoFBAcCAQESBOYCFioKDQoFBAcCAQMSBOYCLS4KDQoFBAcCAQgSBOcCBi4KEAoIBAcCAQic
CAASBOcCBy0KOAoCBAgSBusCAPsCARoqIFRoZSBgRGVsZXRlTm90aWZpY2F0aW9uQ2hhbm5l
bGAgcmVxdWVzdC4KCgsKAwQIARIE6wIIKAqhAQoEBAgCABIG7wIC9AIEGpABIFJlcXVpcmVk
LiBUaGUgY2hhbm5lbCBmb3Igd2hpY2ggdG8gZXhlY3V0ZSB0aGUgcmVxdWVzdC4gVGhlIGZv
cm1hdCBpczoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXS9ub3RpZmlj
YXRpb25DaGFubmVscy9bQ0hBTk5FTF9JRF0KCg0KBQQIAgAFEgTvAgIICg0KBQQIAgABEgTv
AgkNCg0KBQQIAgADEgTvAhARCg8KBQQIAgAIEgbvAhL0AgMKEAoIBAgCAAicCAASBPACBCoK
EQoHBAgCAAifCBIG8QIE8wIFCo8CCgQECAIBEgT6AgIRGoACIElmIHRydWUsIHRoZSBub3Rp
ZmljYXRpb24gY2hhbm5lbCB3aWxsIGJlIGRlbGV0ZWQgcmVnYXJkbGVzcyBvZiBpdHMKIHVz
ZSBpbiBhbGVydCBwb2xpY2llcyAodGhlIHBvbGljaWVzIHdpbGwgYmUgdXBkYXRlZCB0byBy
ZW1vdmUgdGhlCiBjaGFubmVsKS4gSWYgZmFsc2UsIHRoaXMgb3BlcmF0aW9uIHdpbGwgZmFp
bCBpZiB0aGUgbm90aWZpY2F0aW9uIGNoYW5uZWwKIGlzIHJlZmVyZW5jZWQgYnkgZXhpc3Rp
bmcgYWxlcnRpbmcgcG9saWNpZXMuCgoNCgUECAIBBRIE+gICBgoNCgUECAIBARIE+gIHDAoN
CgUECAIBAxIE+gIPEApGCgIECRIG/gIAhgMBGjggVGhlIGBTZW5kTm90aWZpY2F0aW9uQ2hh
bm5lbFZlcmlmaWNhdGlvbkNvZGVgIHJlcXVlc3QuCgoLCgMECQESBP4CCDYKWgoEBAkCABIG
gAMChQMEGkogUmVxdWlyZWQuIFRoZSBub3RpZmljYXRpb24gY2hhbm5lbCB0byB3aGljaCB0
byBzZW5kIGEgdmVyaWZpY2F0aW9uIGNvZGUuCgoNCgUECQIABRIEgAMCCAoNCgUECQIAARIE
gAMJDQoNCgUECQIAAxIEgAMQEQoPCgUECQIACBIGgAMShQMDChAKCAQJAgAInAgAEgSBAwQq
ChEKBwQJAgAInwgSBoIDBIQDBQpFCgIEChIGiQMAngMBGjcgVGhlIGBHZXROb3RpZmljYXRp
b25DaGFubmVsVmVyaWZpY2F0aW9uQ29kZWAgcmVxdWVzdC4KCgsKAwQKARIEiQMINQrrAQoE
BAoCABIGjQMCkgMEGtoBIFJlcXVpcmVkLiBUaGUgbm90aWZpY2F0aW9uIGNoYW5uZWwgZm9y
IHdoaWNoIGEgdmVyaWZpY2F0aW9uIGNvZGUgaXMgdG8gYmUKIGdlbmVyYXRlZCBhbmQgcmV0
cmlldmVkLiBUaGlzIG11c3QgbmFtZSBhIGNoYW5uZWwgdGhhdCBpcyBhbHJlYWR5IHZlcmlm
aWVkOwogaWYgdGhlIHNwZWNpZmllZCBjaGFubmVsIGlzIG5vdCB2ZXJpZmllZCwgdGhlIHJl
cXVlc3Qgd2lsbCBmYWlsLgoKDQoFBAoCAAUSBI0DAggKDQoFBAoCAAESBI0DCQ0KDQoFBAoC
AAMSBI0DEBEKDwoFBAoCAAgSBo0DEpIDAwoQCggECgIACJwIABIEjgMEKgoRCgcECgIACJ8I
EgaPAwSRAwUKggUKBAQKAgESBJ0DAiwa8wQgVGhlIGRlc2lyZWQgZXhwaXJhdGlvbiB0aW1l
LiBJZiBzcGVjaWZpZWQsIHRoZSBBUEkgd2lsbCBndWFyYW50ZWUgdGhhdAogdGhlIHJldHVy
bmVkIGNvZGUgd2lsbCBub3QgYmUgdmFsaWQgYWZ0ZXIgdGhlIHNwZWNpZmllZCB0aW1lc3Rh
bXA7CiBob3dldmVyLCB0aGUgQVBJIGNhbm5vdCBndWFyYW50ZWUgdGhhdCB0aGUgcmV0dXJu
ZWQgY29kZSB3aWxsIGJlCiB2YWxpZCBmb3IgYXQgbGVhc3QgYXMgbG9uZyBhcyB0aGUgcmVx
dWVzdGVkIHRpbWUgKHRoZSBBUEkgcHV0cyBhbiB1cHBlcgogYm91bmQgb24gdGhlIGFtb3Vu
dCBvZiB0aW1lIGZvciB3aGljaCBhIGNvZGUgbWF5IGJlIHZhbGlkKS4gSWYgb21pdHRlZCwK
IGEgZGVmYXVsdCBleHBpcmF0aW9uIHdpbGwgYmUgdXNlZCwgd2hpY2ggbWF5IGJlIGxlc3Mg
dGhhbiB0aGUgbWF4CiBwZXJtaXNzaWJsZSBleHBpcmF0aW9uIChzbyBzcGVjaWZ5aW5nIGFu
IGV4cGlyYXRpb24gbWF5IGV4dGVuZCB0aGUKIGNvZGUncyBsaWZldGltZSBvdmVyIG9taXR0
aW5nIGFuIGV4cGlyYXRpb24sIGV2ZW4gdGhvdWdoIHRoZSBBUEkgZG9lcwogaW1wb3NlIGFu
IHVwcGVyIGxpbWl0IG9uIHRoZSBtYXhpbXVtIGV4cGlyYXRpb24gdGhhdCBpcyBwZXJtaXR0
ZWQpLgoKDQoFBAoCAQYSBJ0DAhsKDQoFBAoCAQESBJ0DHCcKDQoFBAoCAQMSBJ0DKisKRQoC
BAsSBqEDAKwDARo3IFRoZSBgR2V0Tm90aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNhdGlvbkNv
ZGVgIHJlcXVlc3QuCgoLCgMECwESBKEDCDYKnAIKBAQLAgASBKYDAhIajQIgVGhlIHZlcmlm
aWNhdGlvbiBjb2RlLCB3aGljaCBtYXkgYmUgdXNlZCB0byB2ZXJpZnkgb3RoZXIgY2hhbm5l
bHMKIHRoYXQgaGF2ZSBhbiBlcXVpdmFsZW50IGlkZW50aXR5IChpLmUuIG90aGVyIGNoYW5u
ZWxzIG9mIHRoZSBzYW1lCiB0eXBlIHdpdGggdGhlIHNhbWUgZmluZ2VycHJpbnQgc3VjaCBh
cyBvdGhlciBlbWFpbCBjaGFubmVscyB3aXRoCiB0aGUgc2FtZSBlbWFpbCBhZGRyZXNzIG9y
IG90aGVyIHNtcyBjaGFubmVscyB3aXRoIHRoZSBzYW1lIG51bWJlcikuCgoNCgUECwIABRIE
pgMCCAoNCgUECwIAARIEpgMJDQoNCgUECwIAAxIEpgMQEQrhAQoEBAsCARIEqwMCLBrSASBU
aGUgZXhwaXJhdGlvbiB0aW1lIGFzc29jaWF0ZWQgd2l0aCB0aGUgY29kZSB0aGF0IHdhcyBy
ZXR1cm5lZC4gSWYKIGFuIGV4cGlyYXRpb24gd2FzIHByb3ZpZGVkIGluIHRoZSByZXF1ZXN0
LCB0aGlzIGlzIHRoZSBtaW5pbXVtIG9mIHRoZQogcmVxdWVzdGVkIGV4cGlyYXRpb24gaW4g
dGhlIHJlcXVlc3QgYW5kIHRoZSBtYXggcGVybWl0dGVkIGV4cGlyYXRpb24uCgoNCgUECwIB
BhIEqwMCGwoNCgUECwIBARIEqwMcJwoNCgUECwIBAxIEqwMqKwo4CgIEDBIGrwMAwAMBGiog
VGhlIGBWZXJpZnlOb3RpZmljYXRpb25DaGFubmVsYCByZXF1ZXN0LgoKCwoDBAwBEgSvAwgo
Cj8KBAQMAgASBrEDArYDBBovIFJlcXVpcmVkLiBUaGUgbm90aWZpY2F0aW9uIGNoYW5uZWwg
dG8gdmVyaWZ5LgoKDQoFBAwCAAUSBLEDAggKDQoFBAwCAAESBLEDCQ0KDQoFBAwCAAMSBLED
EBEKDwoFBAwCAAgSBrEDErYDAwoQCggEDAIACJwIABIEsgMEKgoRCgcEDAIACJ8IEgazAwS1
AwUK3wMKBAQMAgESBL8DAjsa0AMgUmVxdWlyZWQuIFRoZSB2ZXJpZmljYXRpb24gY29kZSB0
aGF0IHdhcyBkZWxpdmVyZWQgdG8gdGhlIGNoYW5uZWwgYXMKIGEgcmVzdWx0IG9mIGludm9r
aW5nIHRoZSBgU2VuZE5vdGlmaWNhdGlvbkNoYW5uZWxWZXJpZmljYXRpb25Db2RlYCBBUEkK
IG1ldGhvZCBvciB0aGF0IHdhcyByZXRyaWV2ZWQgZnJvbSBhIHZlcmlmaWVkIGNoYW5uZWwg
dmlhCiBgR2V0Tm90aWZpY2F0aW9uQ2hhbm5lbFZlcmlmaWNhdGlvbkNvZGVgLiBGb3IgZXhh
bXBsZSwgb25lIG1pZ2h0IGhhdmUKICJHLTEyMzQ1NiIgb3IgIlRLTlpHaGhkMkV5TjNJMU1u
Um5NalJ2IiAoaW4gZ2VuZXJhbCwgb25lIGlzIG9ubHkKIGd1YXJhbnRlZWQgdGhhdCB0aGUg
Y29kZSBpcyB2YWxpZCBVVEYtODsgb25lIHNob3VsZCBub3QKIG1ha2UgYW55IGFzc3VtcHRp
b25zIHJlZ2FyZGluZyB0aGUgc3RydWN0dXJlIG9yIGZvcm1hdCBvZiB0aGUgY29kZSkuCgoN
CgUEDAIBBRIEvwMCCAoNCgUEDAIBARIEvwMJDQoNCgUEDAIBAxIEvwMQEQoNCgUEDAIBCBIE
vwMSOgoQCggEDAIBCJwIABIEvwMTOWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest ===
    # Fields for ListNotificationChannelDescriptorsRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse ===
    # Fields for ListNotificationChannelDescriptorsResponse
    # Field: channel_descriptors Type: 11 (.google.monitoring.v3.NotificationChannelDescriptor)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Monitoring::V3::NotificationService::GetNotificationChannelDescriptorRequest ===
    # Fields for GetNotificationChannelDescriptorRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::NotificationService::CreateNotificationChannelRequest ===
    # Fields for CreateNotificationChannelRequest
    # Field: name Type: 9 ()
    # Field: notification_channel Type: 11 (.google.monitoring.v3.NotificationChannel)

# === Message: Google::Monitoring::V3::NotificationService::ListNotificationChannelsRequest ===
    # Fields for ListNotificationChannelsRequest
    # Field: name Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::NotificationService::ListNotificationChannelsResponse ===
    # Fields for ListNotificationChannelsResponse
    # Field: notification_channels Type: 11 (.google.monitoring.v3.NotificationChannel)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Monitoring::V3::NotificationService::GetNotificationChannelRequest ===
    # Fields for GetNotificationChannelRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::NotificationService::UpdateNotificationChannelRequest ===
    # Fields for UpdateNotificationChannelRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: notification_channel Type: 11 (.google.monitoring.v3.NotificationChannel)

# === Message: Google::Monitoring::V3::NotificationService::DeleteNotificationChannelRequest ===
    # Fields for DeleteNotificationChannelRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Monitoring::V3::NotificationService::SendNotificationChannelVerificationCodeRequest ===
    # Fields for SendNotificationChannelVerificationCodeRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeRequest ===
    # Fields for GetNotificationChannelVerificationCodeRequest
    # Field: name Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeResponse ===
    # Fields for GetNotificationChannelVerificationCodeResponse
    # Field: code Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Monitoring::V3::NotificationService::VerifyNotificationChannelRequest ===
    # Fields for VerifyNotificationChannelRequest
    # Field: name Type: 9 ()
    # Field: code Type: 9 ()

# === Service Client: Google::Monitoring::V3::NotificationService::NotificationChannelServiceClient ===
package Google::Monitoring::V3::NotificationService::NotificationChannelServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::NotificationService::NotificationChannelServiceClient

Client stub representing the remote C<NotificationChannelService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub list_notification_channel_descriptors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'ListNotificationChannelDescriptors',
        request        => $req,
        response_class => 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse',
    });
}

sub get_notification_channel_descriptor {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::GetNotificationChannelDescriptorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'GetNotificationChannelDescriptor',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Notification::NotificationChannelDescriptor',
    });
}

sub list_notification_channels {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::ListNotificationChannelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'ListNotificationChannels',
        request        => $req,
        response_class => 'Google::Monitoring::V3::NotificationService::ListNotificationChannelsResponse',
    });
}

sub get_notification_channel {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::GetNotificationChannelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'GetNotificationChannel',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Notification::NotificationChannel',
    });
}

sub create_notification_channel {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::CreateNotificationChannelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'CreateNotificationChannel',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Notification::NotificationChannel',
    });
}

sub update_notification_channel {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::UpdateNotificationChannelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'UpdateNotificationChannel',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Notification::NotificationChannel',
    });
}

sub delete_notification_channel {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::DeleteNotificationChannelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'DeleteNotificationChannel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub send_notification_channel_verification_code {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::SendNotificationChannelVerificationCodeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'SendNotificationChannelVerificationCode',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_notification_channel_verification_code {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'GetNotificationChannelVerificationCode',
        request        => $req,
        response_class => 'Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeResponse',
    });
}

sub verify_notification_channel {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::NotificationService::VerifyNotificationChannelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'VerifyNotificationChannel',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Notification::NotificationChannel',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::NotificationService - Compiled Protocol Buffers messages for google/monitoring/v3/notification_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::NotificationService;

    my $msg = Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest->new({
        name => $name,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/notification_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest

The `ListNotificationChannelDescriptors` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The REST resource name of the parent from which to retrieve
the notification channel descriptors. The expected syntax is:

    projects/[PROJECT_ID_OR_NUMBER]

Note that this
[names](https://cloud.google.com/monitoring/api/v3#project_name) the parent
container in which to look for the descriptors; to retrieve a single
descriptor by name, use the
[GetNotificationChannelDescriptor][google.monitoring.v3.NotificationChannelService.GetNotificationChannelDescriptor]
operation, instead.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results to return in a single response. If
not set to a positive number, a reasonable value will be chosen by the
service.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If non-empty, `page_token` must contain a value returned as the
`next_page_token` in a previous response to request the next set
of results.

=back

=head2 Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse

The `ListNotificationChannelDescriptors` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->channel_descriptors() >> / C<< $msg->channel_descriptors($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Notification::NotificationChannelDescriptor>)

The monitored resource descriptors supported for the specified
project, optionally filtered.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more results that match
the request. Use the value in the `page_token` field in a
subsequent request to fetch the next set of results. If empty,
all results have been returned.

=back

=head2 Google::Monitoring::V3::NotificationService::GetNotificationChannelDescriptorRequest

The `GetNotificationChannelDescriptor` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The channel type for which to execute the request. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/notificationChannelDescriptors/[CHANNEL_TYPE]

=back

=head2 Google::Monitoring::V3::NotificationService::CreateNotificationChannelRequest

The `CreateNotificationChannel` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) on which
to execute the request. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

This names the container into which the channel will be
written, this does not name the newly created channel. The resulting
channel's name will have a normalized version of this field as a prefix,
but will add `/notificationChannels/[CHANNEL_ID]` to identify the channel.

=item * C<< $msg->notification_channel() >> / C<< $msg->notification_channel($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Notification::NotificationChannel>)

Required. The definition of the `NotificationChannel` to create.

=back

=head2 Google::Monitoring::V3::NotificationService::ListNotificationChannelsRequest

The `ListNotificationChannels` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) on which
to execute the request. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

This names the container
in which to look for the notification channels; it does not name a
specific channel. To query a specific channel by REST resource name, use
the
[`GetNotificationChannel`][google.monitoring.v3.NotificationChannelService.GetNotificationChannel]
operation.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. If provided, this field specifies the criteria that must be met
by notification channels to be included in the response.

For more details, see [sorting and
filtering](https://cloud.google.com/monitoring/api/v3/sorting-and-filtering).

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A comma-separated list of fields by which to sort the result.
Supports the same set of fields as in `filter`. Entries can be prefixed
with a minus sign to sort in descending rather than ascending order.

For more details, see [sorting and
filtering](https://cloud.google.com/monitoring/api/v3/sorting-and-filtering).

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return in a single response. If
not set to a positive number, a reasonable value will be chosen by the
service.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If non-empty, `page_token` must contain a value returned as the
`next_page_token` in a previous response to request the next set
of results.

=back

=head2 Google::Monitoring::V3::NotificationService::ListNotificationChannelsResponse

The `ListNotificationChannels` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->notification_channels() >> / C<< $msg->notification_channels($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Notification::NotificationChannel>)

The notification channels defined for the specified project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more results that match
the request. Use the value in the `page_token` field in a
subsequent request to fetch the next set of results. If empty,
all results have been returned.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

The total number of notification channels in all pages. This number is only
an estimate, and may change in subsequent pages. https://aip.dev/158

=back

=head2 Google::Monitoring::V3::NotificationService::GetNotificationChannelRequest

The `GetNotificationChannel` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The channel for which to execute the request. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/notificationChannels/[CHANNEL_ID]

=back

=head2 Google::Monitoring::V3::NotificationService::UpdateNotificationChannelRequest

The `UpdateNotificationChannel` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The fields to update.

=item * C<< $msg->notification_channel() >> / C<< $msg->notification_channel($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Notification::NotificationChannel>)

Required. A description of the changes to be applied to the specified
notification channel. The description must provide a definition for
fields to be updated; the names of these fields should also be
included in the `update_mask`.

=back

=head2 Google::Monitoring::V3::NotificationService::DeleteNotificationChannelRequest

The `DeleteNotificationChannel` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The channel for which to execute the request. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/notificationChannels/[CHANNEL_ID]

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If true, the notification channel will be deleted regardless of its
use in alert policies (the policies will be updated to remove the
channel). If false, this operation will fail if the notification channel
is referenced by existing alerting policies.

=back

=head2 Google::Monitoring::V3::NotificationService::SendNotificationChannelVerificationCodeRequest

The `SendNotificationChannelVerificationCode` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The notification channel to which to send a verification code.

=back

=head2 Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeRequest

The `GetNotificationChannelVerificationCode` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The notification channel for which a verification code is to be
generated and retrieved. This must name a channel that is already verified;
if the specified channel is not verified, the request will fail.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The desired expiration time. If specified, the API will guarantee that
the returned code will not be valid after the specified timestamp;
however, the API cannot guarantee that the returned code will be
valid for at least as long as the requested time (the API puts an upper
bound on the amount of time for which a code may be valid). If omitted,
a default expiration will be used, which may be less than the max
permissible expiration (so specifying an expiration may extend the
code's lifetime over omitting an expiration, even though the API does
impose an upper limit on the maximum expiration that is permitted).

=back

=head2 Google::Monitoring::V3::NotificationService::GetNotificationChannelVerificationCodeResponse

The `GetNotificationChannelVerificationCode` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

The verification code, which may be used to verify other channels
that have an equivalent identity (i.e. other channels of the same
type with the same fingerprint such as other email channels with
the same email address or other sms channels with the same number).

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The expiration time associated with the code that was returned. If
an expiration was provided in the request, this is the minimum of the
requested expiration in the request and the max permitted expiration.

=back

=head2 Google::Monitoring::V3::NotificationService::VerifyNotificationChannelRequest

The `VerifyNotificationChannel` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The notification channel to verify.

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

Required. The verification code that was delivered to the channel as
a result of invoking the `SendNotificationChannelVerificationCode` API
method or that was retrieved from a verified channel via
`GetNotificationChannelVerificationCode`. For example, one might have
"G-123456" or "TKNZGhhd2EyN3I1MnRnMjRv" (in general, one is only
guaranteed that the code is valid UTF-8; one should not
make any assumptions regarding the structure or format of the code).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::NotificationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
