package Google::Cloud::Dialogflow::V2::Context;

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
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9jb250ZXh0LnByb3RvEhpnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxog
Z29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1
Y3QucHJvdG8isAQKB0NvbnRleHQSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEioKDmxpZmVz
cGFuX2NvdW50GAIgASgFQgPgQQFSDWxpZmVzcGFuQ291bnQSPAoKcGFyYW1ldGVycxgDIAEo
CzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RCA+BBAVIKcGFyYW1ldGVyczqhA+pBnQMKIWRp
YWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29udGV4dBI+cHJvamVjdHMve3Byb2plY3R9L2Fn
ZW50L3Nlc3Npb25zL3tzZXNzaW9ufS9jb250ZXh0cy97Y29udGV4dH0SZnByb2plY3RzL3tw
cm9qZWN0fS9hZ2VudC9lbnZpcm9ubWVudHMve2Vudmlyb25tZW50fS91c2Vycy97dXNlcn0v
c2Vzc2lvbnMve3Nlc3Npb259L2NvbnRleHRzL3tjb250ZXh0fRJTcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50L3Nlc3Npb25zL3tzZXNzaW9ufS9jb250
ZXh0cy97Y29udGV4dH0Se3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hZ2VudC9lbnZpcm9ubWVudHMve2Vudmlyb25tZW50fS91c2Vycy97dXNlcn0vc2Vzc2lv
bnMve3Nlc3Npb259L2NvbnRleHRzL3tjb250ZXh0fSKeAQoTTGlzdENvbnRleHRzUmVxdWVz
dBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIxIhZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9D
b250ZXh0UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBh
Z2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIn8KFExpc3RDb250ZXh0c1Jlc3BvbnNl
Ej8KCGNvbnRleHRzGAEgAygLMiMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udGV4
dFIIY29udGV4dHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlIK
EUdldENvbnRleHRSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9Db250ZXh0UgRuYW1lIp0BChRDcmVhdGVDb250ZXh0UmVxdWVzdBJB
CgZwYXJlbnQYASABKAlCKeBBAvpBIxIhZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Db250
ZXh0UgZwYXJlbnQSQgoHY29udGV4dBgCIAEoCzIjLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyLkNvbnRleHRCA+BBAlIHY29udGV4dCKcAQoUVXBkYXRlQ29udGV4dFJlcXVlc3QSQgoH
Y29udGV4dBgBIAEoCzIjLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbnRleHRCA+BB
AlIHY29udGV4dBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVs
ZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJVChREZWxldGVDb250ZXh0UmVxdWVzdBI9CgRuYW1l
GAEgASgJQingQQL6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29udGV4dFIEbmFt
ZSJdChhEZWxldGVBbGxDb250ZXh0c1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMS
IWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29udGV4dFIGcGFyZW50MugUCghDb250ZXh0
cxKcAwoMTGlzdENvbnRleHRzEi8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuTGlzdENv
bnRleHRzUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkxpc3RDb250ZXh0
c1Jlc3BvbnNlIqgCgtPkkwKYAhIxL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9hZ2VudC9zZXNz
aW9ucy8qfS9jb250ZXh0c1pKEkgvdjIve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50L2Vudmly
b25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKn0vY29udGV4dHNaPxI9L3YyL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9zZXNzaW9ucy8qfS9jb250ZXh0c1pWElQv
djIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8q
L3VzZXJzLyovc2Vzc2lvbnMvKn0vY29udGV4dHPaQQZwYXJlbnQSiQMKCkdldENvbnRleHQS
LS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5HZXRDb250ZXh0UmVxdWVzdBojLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbnRleHQipgKC0+STApgCEjEvdjIve25hbWU9cHJv
amVjdHMvKi9hZ2VudC9zZXNzaW9ucy8qL2NvbnRleHRzLyp9WkoSSC92Mi97bmFtZT1wcm9q
ZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKi9jb250ZXh0
cy8qfVo/Ej0vdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9zZXNzaW9u
cy8qL2NvbnRleHRzLyp9WlYSVC92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Fn
ZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKi9jb250ZXh0cy8qfdpBBG5h
bWUSvQMKDUNyZWF0ZUNvbnRleHQSMC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5DcmVh
dGVDb250ZXh0UmVxdWVzdBojLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbnRleHQi
1AKC0+STArwCIjEvdjIve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50L3Nlc3Npb25zLyp9L2Nv
bnRleHRzOgdjb250ZXh0WlMiSC92Mi97cGFyZW50PXByb2plY3RzLyovYWdlbnQvZW52aXJv
bm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qfS9jb250ZXh0czoHY29udGV4dFpIIj0vdjIv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L3Nlc3Npb25zLyp9L2NvbnRl
eHRzOgdjb250ZXh0Wl8iVC92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdl
bnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qfS9jb250ZXh0czoHY29udGV4
dNpBDnBhcmVudCxjb250ZXh0EuIDCg1VcGRhdGVDb250ZXh0EjAuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuVXBkYXRlQ29udGV4dFJlcXVlc3QaIy5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52Mi5Db250ZXh0IvkCgtPkkwLcAjI5L3YyL3tjb250ZXh0Lm5hbWU9cHJvamVjdHMv
Ki9hZ2VudC9zZXNzaW9ucy8qL2NvbnRleHRzLyp9Ogdjb250ZXh0WlsyUC92Mi97Y29udGV4
dC5uYW1lPXByb2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9u
cy8qL2NvbnRleHRzLyp9Ogdjb250ZXh0WlAyRS92Mi97Y29udGV4dC5uYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovYWdlbnQvc2Vzc2lvbnMvKi9jb250ZXh0cy8qfToHY29udGV4dFpn
MlwvdjIve2NvbnRleHQubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L2Vudmly
b25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKi9jb250ZXh0cy8qfToHY29udGV4dNpBE2Nv
bnRleHQsdXBkYXRlX21hc2sSggMKDURlbGV0ZUNvbnRleHQSMC5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52Mi5EZWxldGVDb250ZXh0UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0
eSKmAoLT5JMCmAIqMS92Mi97bmFtZT1wcm9qZWN0cy8qL2FnZW50L3Nlc3Npb25zLyovY29u
dGV4dHMvKn1aSipIL3YyL3tuYW1lPXByb2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyov
dXNlcnMvKi9zZXNzaW9ucy8qL2NvbnRleHRzLyp9Wj8qPS92Mi97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2FnZW50L3Nlc3Npb25zLyovY29udGV4dHMvKn1aVipUL3YyL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9z
ZXNzaW9ucy8qL2NvbnRleHRzLyp92kEEbmFtZRKMAwoRRGVsZXRlQWxsQ29udGV4dHMSNC5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5EZWxldGVBbGxDb250ZXh0c1JlcXVlc3QaFi5n
b29nbGUucHJvdG9idWYuRW1wdHkiqAKC0+STApgCKjEvdjIve3BhcmVudD1wcm9qZWN0cy8q
L2FnZW50L3Nlc3Npb25zLyp9L2NvbnRleHRzWkoqSC92Mi97cGFyZW50PXByb2plY3RzLyov
YWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qfS9jb250ZXh0c1o/Kj0v
djIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L3Nlc3Npb25zLyp9L2Nv
bnRleHRzWlYqVC92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52
aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qfS9jb250ZXh0c9pBBnBhcmVudBp4ykEZ
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29t
L2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9k
aWFsb2dmbG93QpIBCh5jb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJCDENvbnRleHRQ
cm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjIvZGlhbG9nZmxv
d3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIaR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJKwkkK
BxIFDgDRAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMK
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAl
CgkKAgMFEgMXACoKCQoCAwYSAxgAJgoICgEIEgMaADcKCQoCCCUSAxoANwoICgEIEgMbAFUK
CQoCCAsSAxsAVQoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdAC0KCQoCCAgSAx0ALQoI
CgEIEgMeADcKCQoCCAESAx4ANwoICgEIEgMfACAKCQoCCCQSAx8AIApTCgIGABIFIgCYAQEa
RiBTZXJ2aWNlIGZvciBtYW5hZ2luZyBbQ29udGV4dHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyLkNvbnRleHRdLgoKCgoDBgABEgMiCBAKCgoDBgADEgMjAkEKDAoFBgADmQgSAyMC
QQoLCgMGAAMSBCQCJjMKDQoFBgADmggSBCQCJjMKSgoEBgACABIEKQI3Axo8IFJldHVybnMg
dGhlIGxpc3Qgb2YgYWxsIGNvbnRleHRzIGluIHRoZSBzcGVjaWZpZWQgc2Vzc2lvbi4KCgwK
BQYAAgABEgMpBhIKDAoFBgACAAISAykTJgoMCgUGAAIAAxIDKTFFCg0KBQYAAgAEEgQqBDUG
ChEKCQYAAgAEsMq8IhIEKgQ1BgoMCgUGAAIABBIDNgQ0Cg8KCAYAAgAEmwgAEgM2BDQKMAoE
BgACARIEOgJIAxoiIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIGNvbnRleHQuCgoMCgUGAAIB
ARIDOgYQCgwKBQYAAgECEgM6ESIKDAoFBgACAQMSAzotNAoNCgUGAAIBBBIEOwRGBgoRCgkG
AAIBBLDKvCISBDsERgYKDAoFBgACAQQSA0cEMgoPCggGAAIBBJsIABIDRwQyCmQKBAYAAgIS
BE0CXwMaViBDcmVhdGVzIGEgY29udGV4dC4KCiBJZiB0aGUgc3BlY2lmaWVkIGNvbnRleHQg
YWxyZWFkeSBleGlzdHMsIG92ZXJyaWRlcyB0aGUgY29udGV4dC4KCgwKBQYAAgIBEgNNBhMK
DAoFBgACAgISA00UKAoMCgUGAAICAxIDTTM6Cg0KBQYAAgIEEgROBF0GChEKCQYAAgIEsMq8
IhIETgRdBgoMCgUGAAICBBIDXgQ8Cg8KCAYAAgIEmwgAEgNeBDwKLgoEBgACAxIEYgJ0Axog
IFVwZGF0ZXMgdGhlIHNwZWNpZmllZCBjb250ZXh0LgoKDAoFBgACAwESA2IGEwoMCgUGAAID
AhIDYhQoCgwKBQYAAgMDEgNiMzoKDQoFBgACAwQSBGMEcgYKEQoJBgACAwSwyrwiEgRjBHIG
CgwKBQYAAgMEEgNzBEEKDwoIBgACAwSbCAASA3MEQQovCgQGAAIEEgV3AoUBAxogIERlbGV0
ZXMgdGhlIHNwZWNpZmllZCBjb250ZXh0LgoKDAoFBgACBAESA3cGEwoMCgUGAAIEAhIDdxQo
CgwKBQYAAgQDEgN3M0gKDgoFBgACBAQSBXgEgwEGChIKCQYAAgQEsMq8IhIFeASDAQYKDQoF
BgACBAQSBIQBBDIKEAoIBgACBASbCAASBIQBBDIKRwoEBgACBRIGiAEClwEDGjcgRGVsZXRl
cyBhbGwgYWN0aXZlIGNvbnRleHRzIGluIHRoZSBzcGVjaWZpZWQgc2Vzc2lvbi4KCg0KBQYA
AgUBEgSIAQYXCg0KBQYAAgUCEgSIARgwCg0KBQYAAgUDEgSJAQ8kCg8KBQYAAgUEEgaKAQSV
AQYKEwoJBgACBQSwyrwiEgaKAQSVAQYKDQoFBgACBQQSBJYBBDQKEAoIBgACBQSbCAASBJYB
BDQKhQcKAgQAEgapAQDbAQEa9gYgRGlhbG9nZmxvdyBjb250ZXh0cyBhcmUgc2ltaWxhciB0
byBuYXR1cmFsIGxhbmd1YWdlIGNvbnRleHQuIElmIGEgcGVyc29uIHNheXMKIHRvIHlvdSAi
dGhleSBhcmUgb3JhbmdlIiwgeW91IG5lZWQgY29udGV4dCBpbiBvcmRlciB0byB1bmRlcnN0
YW5kIHdoYXQgInRoZXkiCiBpcyByZWZlcnJpbmcgdG8uIFNpbWlsYXJseSwgZm9yIERpYWxv
Z2Zsb3cgdG8gaGFuZGxlIGFuIGVuZC11c2VyIGV4cHJlc3Npb24KIGxpa2UgdGhhdCwgaXQg
bmVlZHMgdG8gYmUgcHJvdmlkZWQgd2l0aCBjb250ZXh0IGluIG9yZGVyIHRvIGNvcnJlY3Rs
eSBtYXRjaAogYW4gaW50ZW50LgoKIFVzaW5nIGNvbnRleHRzLCB5b3UgY2FuIGNvbnRyb2wg
dGhlIGZsb3cgb2YgYSBjb252ZXJzYXRpb24uIFlvdSBjYW4gY29uZmlndXJlCiBjb250ZXh0
cyBmb3IgYW4gaW50ZW50IGJ5IHNldHRpbmcgaW5wdXQgYW5kIG91dHB1dCBjb250ZXh0cywg
d2hpY2ggYXJlCiBpZGVudGlmaWVkIGJ5IHN0cmluZyBuYW1lcy4gV2hlbiBhbiBpbnRlbnQg
aXMgbWF0Y2hlZCwgYW55IGNvbmZpZ3VyZWQgb3V0cHV0CiBjb250ZXh0cyBmb3IgdGhhdCBp
bnRlbnQgYmVjb21lIGFjdGl2ZS4gV2hpbGUgYW55IGNvbnRleHRzIGFyZSBhY3RpdmUsCiBE
aWFsb2dmbG93IGlzIG1vcmUgbGlrZWx5IHRvIG1hdGNoIGludGVudHMgdGhhdCBhcmUgY29u
ZmlndXJlZCB3aXRoIGlucHV0CiBjb250ZXh0cyB0aGF0IGNvcnJlc3BvbmQgdG8gdGhlIGN1
cnJlbnRseSBhY3RpdmUgY29udGV4dHMuCgogRm9yIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQg
Y29udGV4dCwgc2VlIHRoZQogW0NvbnRleHRzIGd1aWRlXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vZGlhbG9nZmxvdy9kb2NzL2NvbnRleHRzLW92ZXJ2aWV3KS4KCgsKAwQAARIEqQEI
DwoNCgMEAAcSBqoBArABBAoPCgUEAAedCBIGqgECsAEECoQGCgQEAAIAEgTDAQI7GvUFIFJl
cXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGNvbnRleHQuIEZvcm1hdDoK
IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2Nv
bnRleHRzLzxDb250ZXh0IElEPmAsCiBvciBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50
L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyCiBJRD4vc2Vzc2lv
bnMvPFNlc3Npb24gSUQ+L2NvbnRleHRzLzxDb250ZXh0IElEPmAuCgogVGhlIGBDb250ZXh0
IElEYCBpcyBhbHdheXMgY29udmVydGVkIHRvIGxvd2VyY2FzZSwgbWF5IG9ubHkgY29udGFp
bgogY2hhcmFjdGVycyBpbiBgYS16QS1aMC05Xy0lYCBhbmQgbWF5IGJlIGF0IG1vc3QgMjUw
IGJ5dGVzIGxvbmcuCgogSWYgYEVudmlyb25tZW50IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3
ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnCiBlbnZpcm9ubWVudC4gSWYgYFVzZXIgSURgIGlz
IG5vdCBzcGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICctJyB1c2VyLgoKIFRoZSBmb2xs
b3dpbmcgY29udGV4dCBuYW1lcyBhcmUgcmVzZXJ2ZWQgZm9yIGludGVybmFsIHVzZSBieSBE
aWFsb2dmbG93LgogWW91IHNob3VsZCBub3QgdXNlIHRoZXNlIGNvbnRleHRzIG9yIGNyZWF0
ZSBjb250ZXh0cyB3aXRoIHRoZXNlIG5hbWVzOgoKICogYF9fc3lzdGVtX2NvdW50ZXJzX19g
CiAqIGAqX2lkX2RpYWxvZ19jb250ZXh0YAogKiBgKl9kaWFsb2dfcGFyYW1zX3NpemVgCgoN
CgUEAAIABRIEwwECCAoNCgUEAAIAARIEwwEJDQoNCgUEAAIAAxIEwwEQEQoNCgUEAAIACBIE
wwESOgoQCggEAAIACJwIABIEwwETOQr/AQoEBAACARIEyQECRBrwASBPcHRpb25hbC4gVGhl
IG51bWJlciBvZiBjb252ZXJzYXRpb25hbCBxdWVyeSByZXF1ZXN0cyBhZnRlciB3aGljaCB0
aGUKIGNvbnRleHQgZXhwaXJlcy4gVGhlIGRlZmF1bHQgaXMgYDBgLiBJZiBzZXQgdG8gYDBg
LCB0aGUgY29udGV4dCBleHBpcmVzCiBpbW1lZGlhdGVseS4gQ29udGV4dHMgZXhwaXJlIGF1
dG9tYXRpY2FsbHkgYWZ0ZXIgMjAgbWludXRlcyBpZiB0aGVyZQogYXJlIG5vIG1hdGNoaW5n
IHF1ZXJpZXMuCgoNCgUEAAIBBRIEyQECBwoNCgUEAAIBARIEyQEIFgoNCgUEAAIBAxIEyQEZ
GgoNCgUEAAIBCBIEyQEbQwoQCggEAAIBCJwIABIEyQEcQgq7BQoEBAACAhIG2QEC2gEvGqoF
IE9wdGlvbmFsLiBUaGUgY29sbGVjdGlvbiBvZiBwYXJhbWV0ZXJzIGFzc29jaWF0ZWQgd2l0
aCB0aGlzIGNvbnRleHQuCgogRGVwZW5kaW5nIG9uIHlvdXIgcHJvdG9jb2wgb3IgY2xpZW50
IGxpYnJhcnkgbGFuZ3VhZ2UsIHRoaXMgaXMgYQogbWFwLCBhc3NvY2lhdGl2ZSBhcnJheSwg
c3ltYm9sIHRhYmxlLCBkaWN0aW9uYXJ5LCBvciBKU09OIG9iamVjdAogY29tcG9zZWQgb2Yg
YSBjb2xsZWN0aW9uIG9mIChNYXBLZXksIE1hcFZhbHVlKSBwYWlyczoKCiAqIE1hcEtleSB0
eXBlOiBzdHJpbmcKICogTWFwS2V5IHZhbHVlOiBwYXJhbWV0ZXIgbmFtZQogKiBNYXBWYWx1
ZSB0eXBlOiBJZiBwYXJhbWV0ZXIncyBlbnRpdHkgdHlwZSBpcyBhIGNvbXBvc2l0ZSBlbnRp
dHkgdGhlbiB1c2UKIG1hcCwgb3RoZXJ3aXNlLCBkZXBlbmRpbmcgb24gdGhlIHBhcmFtZXRl
ciB2YWx1ZSB0eXBlLCBpdCBjb3VsZCBiZSBvbmUgb2YKIHN0cmluZywgbnVtYmVyLCBib29s
ZWFuLCBudWxsLCBsaXN0IG9yIG1hcC4KICogTWFwVmFsdWUgdmFsdWU6IElmIHBhcmFtZXRl
cidzIGVudGl0eSB0eXBlIGlzIGEgY29tcG9zaXRlIGVudGl0eSB0aGVuIHVzZQogbWFwIGZy
b20gY29tcG9zaXRlIGVudGl0eSBwcm9wZXJ0eSBuYW1lcyB0byBwcm9wZXJ0eSB2YWx1ZXMs
IG90aGVyd2lzZSwKIHVzZSBwYXJhbWV0ZXIgdmFsdWUuCgoNCgUEAAICBhIE2QECGAoNCgUE
AAICARIE2QEZIwoNCgUEAAICAxIE2QEmJwoNCgUEAAICCBIE2gEGLgoQCggEAAICCJwIABIE
2gEHLQpzCgIEARIG3wEA8wEBGmUgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb250ZXh0
cy5MaXN0Q29udGV4dHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbnRleHRzLkxp
c3RDb250ZXh0c10uCgoLCgMEAQESBN8BCBsK8gIKBAQBAgASBuYBAusBBBrhAiBSZXF1aXJl
ZC4gVGhlIHNlc3Npb24gdG8gbGlzdCBhbGwgY29udGV4dHMgZnJvbS4KIEZvcm1hdDogYHBy
b2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9zZXNzaW9ucy88U2Vzc2lvbiBJRD5gIG9yCiBg
cHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQg
SUQ+L3VzZXJzLzxVc2VyCiBJRD4vc2Vzc2lvbnMvPFNlc3Npb24gSUQ+YC4KIElmIGBFbnZp
cm9ubWVudCBJRGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0
JwogZW52aXJvbm1lbnQuIElmIGBVc2VyIElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1
bWUgZGVmYXVsdCAnLScgdXNlci4KCg0KBQQBAgAFEgTmAQIICg0KBQQBAgABEgTmAQkPCg0K
BQQBAgADEgTmARITCg8KBQQBAgAIEgbmARTrAQMKEAoIBAECAAicCAASBOcBBCoKEQoHBAEC
AAifCBIG6AEE6gEFCnMKBAQBAgESBO8BAj8aZSBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVt
YmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeQogZGVmYXVsdCAx
MDAgYW5kIGF0IG1vc3QgMTAwMC4KCg0KBQQBAgEFEgTvAQIHCg0KBQQBAgEBEgTvAQgRCg0K
BQQBAgEDEgTvARQVCg0KBQQBAgEIEgTvARY+ChAKCAQBAgEInAgAEgTvARc9CloKBAQBAgIS
BPIBAkEaTCBPcHRpb25hbC4gVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBm
cm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAECAgUSBPIBAggKDQoFBAECAgES
BPIBCRMKDQoFBAECAgMSBPIBFhcKDQoFBAECAggSBPIBGEAKEAoIBAECAgicCAASBPIBGT8K
dAoCBAISBvcBAP8BARpmIFRoZSByZXNwb25zZSBtZXNzYWdlIGZvcgogW0NvbnRleHRzLkxp
c3RDb250ZXh0c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udGV4dHMuTGlzdENv
bnRleHRzXS4KCgsKAwQCARIE9wEIHAqEAQoEBAICABIE+gECIBp2IFRoZSBsaXN0IG9mIGNv
bnRleHRzLiBUaGVyZSB3aWxsIGJlIGEgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMKIHJldHVy
bmVkIGJhc2VkIG9uIHRoZSBwYWdlX3NpemUgZmllbGQgaW4gdGhlIHJlcXVlc3QuCgoNCgUE
AgIABBIE+gECCgoNCgUEAgIABhIE+gELEgoNCgUEAgIAARIE+gETGwoNCgUEAgIAAxIE+gEe
HwpvCgQEAgIBEgT+AQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiBy
ZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUg
bGlzdC4KCg0KBQQCAgEFEgT+AQIICg0KBQQCAgEBEgT+AQkYCg0KBQQCAgEDEgT+ARscCm8K
AgQDEgaDAgCQAgEaYSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0NvbnRleHRzLkdldENv
bnRleHRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbnRleHRzLkdldENvbnRleHRd
LgoKCwoDBAMBEgSDAggZCpADCgQEAwIAEgaKAgKPAgQa/wIgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBjb250ZXh0LiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50
L3Nlc3Npb25zLzxTZXNzaW9uIElEPi9jb250ZXh0cy88Q29udGV4dCBJRD5gCiBvciBgcHJv
amVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+
L3VzZXJzLzxVc2VyCiBJRD4vc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2NvbnRleHRzLzxDb250
ZXh0IElEPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFz
c3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LiBJZiBgVXNlciBJRGAgaXMgbm90
IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVzZXIuCgoNCgUEAwIABRIEigIC
CAoNCgUEAwIAARIEigIJDQoNCgUEAwIAAxIEigIQEQoPCgUEAwIACBIGigISjwIDChAKCAQD
AgAInAgAEgSLAgQqChEKBwQDAgAInwgSBowCBI4CBQp1CgIEBBIGlAIApAIBGmcgVGhlIHJl
cXVlc3QgbWVzc2FnZSBmb3IKIFtDb250ZXh0cy5DcmVhdGVDb250ZXh0XVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52Mi5Db250ZXh0cy5DcmVhdGVDb250ZXh0XS4KCgsKAwQEARIElAII
HArwAgoEBAQCABIGmwICoAIEGt8CIFJlcXVpcmVkLiBUaGUgc2Vzc2lvbiB0byBjcmVhdGUg
YSBjb250ZXh0IGZvci4KIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9z
ZXNzaW9ucy88U2Vzc2lvbiBJRD5gIG9yCiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50
L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyCiBJRD4vc2Vzc2lv
bnMvPFNlc3Npb24gSUQ+YC4KIElmIGBFbnZpcm9ubWVudCBJRGAgaXMgbm90IHNwZWNpZmll
ZCwgd2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JwogZW52aXJvbm1lbnQuIElmIGBVc2VyIElE
YCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnLScgdXNlci4KCg0KBQQE
AgAFEgSbAgIICg0KBQQEAgABEgSbAgkPCg0KBQQEAgADEgSbAhITCg8KBQQEAgAIEgabAhSg
AgMKEAoIBAQCAAicCAASBJwCBCoKEQoHBAQCAAifCBIGnQIEnwIFCjAKBAQEAgESBKMCAj8a
IiBSZXF1aXJlZC4gVGhlIGNvbnRleHQgdG8gY3JlYXRlLgoKDQoFBAQCAQYSBKMCAgkKDQoF
BAQCAQESBKMCChEKDQoFBAQCAQMSBKMCFBUKDQoFBAQCAQgSBKMCFj4KEAoIBAQCAQicCAAS
BKMCFz0KdQoCBAUSBqgCAK8CARpnIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ29udGV4
dHMuVXBkYXRlQ29udGV4dF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udGV4dHMu
VXBkYXRlQ29udGV4dF0uCgoLCgMEBQESBKgCCBwKMAoEBAUCABIEqgICPxoiIFJlcXVpcmVk
LiBUaGUgY29udGV4dCB0byB1cGRhdGUuCgoNCgUEBQIABhIEqgICCQoNCgUEBQIAARIEqgIK
EQoNCgUEBQIAAxIEqgIUFQoNCgUEBQIACBIEqgIWPgoQCggEBQIACJwIABIEqgIXPQpJCgQE
BQIBEgatAgKuAi8aOSBPcHRpb25hbC4gVGhlIG1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVs
ZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBQIBBhIErQICGwoNCgUEBQIBARIErQIcJwoNCgUEBQIB
AxIErQIqKwoNCgUEBQIBCBIErgIGLgoQCggEBQIBCJwIABIErgIHLQp1CgIEBhIGswIAwAIB
GmcgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb250ZXh0cy5EZWxldGVDb250ZXh0XVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db250ZXh0cy5EZWxldGVDb250ZXh0XS4KCgsK
AwQGARIEswIIHAqaAwoEBAYCABIGugICvwIEGokDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgY29udGV4dCB0byBkZWxldGUuIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdCBJRD4v
YWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2NvbnRleHRzLzxDb250ZXh0IElEPmAKIG9y
IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVu
dCBJRD4vdXNlcnMvPFVzZXIKIElEPi9zZXNzaW9ucy88U2Vzc2lvbiBJRD4vY29udGV4dHMv
PENvbnRleHQgSUQ+YC4KIElmIGBFbnZpcm9ubWVudCBJRGAgaXMgbm90IHNwZWNpZmllZCwg
d2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JwogZW52aXJvbm1lbnQuIElmIGBVc2VyIElEYCBp
cyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnLScgdXNlci4KCg0KBQQGAgAF
EgS6AgIICg0KBQQGAgABEgS6AgkNCg0KBQQGAgADEgS6AhARCg8KBQQGAgAIEga6AhK/AgMK
EAoIBAYCAAicCAASBLsCBCoKEQoHBAYCAAifCBIGvAIEvgIFCn0KAgQHEgbEAgDRAgEabyBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0NvbnRleHRzLkRlbGV0ZUFsbENvbnRleHRzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db250ZXh0cy5EZWxldGVBbGxDb250ZXh0c10u
CgoLCgMEBwESBMQCCCAK/wIKBAQHAgASBssCAtACBBruAiBSZXF1aXJlZC4gVGhlIG5hbWUg
b2YgdGhlIHNlc3Npb24gdG8gZGVsZXRlIGFsbCBjb250ZXh0cyBmcm9tLiBGb3JtYXQ6CiBg
cHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uIElEPmAgb3Ig
YHByb2plY3RzLzxQcm9qZWN0CiBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVu
dCBJRD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uCiBJRD5gLgogSWYgYEVu
dmlyb25tZW50IElEYCBpcyBub3Qgc3BlY2lmaWVkIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFm
dCcgZW52aXJvbm1lbnQuCiBJZiBgVXNlciBJRGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNz
dW1lIGRlZmF1bHQgJy0nIHVzZXIuCgoNCgUEBwIABRIEywICCAoNCgUEBwIAARIEywIJDwoN
CgUEBwIAAxIEywISEwoPCgUEBwIACBIGywIU0AIDChAKCAQHAgAInAgAEgTMAgQqChEKBwQH
AgAInwgSBs0CBM8CBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Context::Context ===
    # Fields for Context
    # Field: name Type: 9 ()
    # Field: lifespan_count Type: 5 ()
    # Field: parameters Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Dialogflow::V2::Context::ListContextsRequest ===
    # Fields for ListContextsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Context::ListContextsResponse ===
    # Fields for ListContextsResponse
    # Field: contexts Type: 11 (.google.cloud.dialogflow.v2.Context)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Context::GetContextRequest ===
    # Fields for GetContextRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Context::CreateContextRequest ===
    # Fields for CreateContextRequest
    # Field: parent Type: 9 ()
    # Field: context Type: 11 (.google.cloud.dialogflow.v2.Context)

# === Message: Google::Cloud::Dialogflow::V2::Context::UpdateContextRequest ===
    # Fields for UpdateContextRequest
    # Field: context Type: 11 (.google.cloud.dialogflow.v2.Context)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2::Context::DeleteContextRequest ===
    # Fields for DeleteContextRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Context::DeleteAllContextsRequest ===
    # Fields for DeleteAllContextsRequest
    # Field: parent Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2::Context::ContextsClient ===
package Google::Cloud::Dialogflow::V2::Context::ContextsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::Context::ContextsClient

Client stub representing the remote C<Contexts> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub list_contexts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Context::ListContextsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Contexts',
        method         => 'ListContexts',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Context::ListContextsResponse',
    });
}

sub get_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Context::GetContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Contexts',
        method         => 'GetContext',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Context::Context',
    });
}

sub create_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Context::CreateContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Contexts',
        method         => 'CreateContext',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Context::Context',
    });
}

sub update_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Context::UpdateContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Contexts',
        method         => 'UpdateContext',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Context::Context',
    });
}

sub delete_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Context::DeleteContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Contexts',
        method         => 'DeleteContext',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub delete_all_contexts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Context::DeleteAllContextsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Contexts',
        method         => 'DeleteAllContexts',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Context - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/context.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Context;

    my $msg = Google::Cloud::Dialogflow::V2::Context::Context->new({
        name => $name,
        lifespan_count => $lifespan_count,
        parameters => $parameters,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Context::Context->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Context::Context

Dialogflow contexts are similar to natural language context. If a person says
to you "they are orange", you need context in order to understand what "they"
is referring to. Similarly, for Dialogflow to handle an end-user expression
like that, it needs to be provided with context in order to correctly match
an intent.

Using contexts, you can control the flow of a conversation. You can configure
contexts for an intent by setting input and output contexts, which are
identified by string names. When an intent is matched, any configured output
contexts for that intent become active. While any contexts are active,
Dialogflow is more likely to match intents that are configured with input
contexts that correspond to the currently active contexts.

For more information about context, see the
[Contexts guide](https://cloud.google.com/dialogflow/docs/contexts-overview).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of the context. Format:
`projects/<Project ID>/agent/sessions/<Session ID>/contexts/<Context ID>`,
or `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
ID>/sessions/<Session ID>/contexts/<Context ID>`.

The `Context ID` is always converted to lowercase, may only contain
characters in `a-zA-Z0-9_-%` and may be at most 250 bytes long.

If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

The following context names are reserved for internal use by Dialogflow.
You should not use these contexts or create contexts with these names:

* `__system_counters__`
* `*_id_dialog_context`
* `*_dialog_params_size`

=item * C<< $msg->lifespan_count() >> / C<< $msg->lifespan_count($value) >>

Type: C<Int32>

Optional. The number of conversational query requests after which the
context expires. The default is `0`. If set to `0`, the context expires
immediately. Contexts expire automatically after 20 minutes if there
are no matching queries.

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The collection of parameters associated with this context.

Depending on your protocol or client library language, this is a
map, associative array, symbol table, dictionary, or JSON object
composed of a collection of (MapKey, MapValue) pairs:

* MapKey type: string
* MapKey value: parameter name
* MapValue type: If parameter's entity type is a composite entity then use
map, otherwise, depending on the parameter value type, it could be one of
string, number, boolean, null, list or map.
* MapValue value: If parameter's entity type is a composite entity then use
map from composite entity property names to property values, otherwise,
use parameter value.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::ListContextsRequest

The request message for
[Contexts.ListContexts][google.cloud.dialogflow.v2.Contexts.ListContexts].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to list all contexts from.
Format: `projects/<Project ID>/agent/sessions/<Session ID>` or
`projects/<Project ID>/agent/environments/<Environment ID>/users/<User
ID>/sessions/<Session ID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::ListContextsResponse

The response message for
[Contexts.ListContexts][google.cloud.dialogflow.v2.Contexts.ListContexts].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contexts() >> / C<< $msg->contexts($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Context::Context>)

The list of contexts. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::GetContextRequest

The request message for
[Contexts.GetContext][google.cloud.dialogflow.v2.Contexts.GetContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the context. Format:
`projects/<Project ID>/agent/sessions/<Session ID>/contexts/<Context ID>`
or `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
ID>/sessions/<Session ID>/contexts/<Context ID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::CreateContextRequest

The request message for
[Contexts.CreateContext][google.cloud.dialogflow.v2.Contexts.CreateContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to create a context for.
Format: `projects/<Project ID>/agent/sessions/<Session ID>` or
`projects/<Project ID>/agent/environments/<Environment ID>/users/<User
ID>/sessions/<Session ID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Context::Context>)

Required. The context to create.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::UpdateContextRequest

The request message for
[Contexts.UpdateContext][google.cloud.dialogflow.v2.Contexts.UpdateContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Context::Context>)

Required. The context to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::DeleteContextRequest

The request message for
[Contexts.DeleteContext][google.cloud.dialogflow.v2.Contexts.DeleteContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the context to delete. Format:
`projects/<Project ID>/agent/sessions/<Session ID>/contexts/<Context ID>`
or `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
ID>/sessions/<Session ID>/contexts/<Context ID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=back

=head2 Google::Cloud::Dialogflow::V2::Context::DeleteAllContextsRequest

The request message for
[Contexts.DeleteAllContexts][google.cloud.dialogflow.v2.Contexts.DeleteAllContexts].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the session to delete all contexts from. Format:
`projects/<Project ID>/agent/sessions/<Session ID>` or `projects/<Project
ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
ID>`.
If `Environment ID` is not specified we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Context::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
