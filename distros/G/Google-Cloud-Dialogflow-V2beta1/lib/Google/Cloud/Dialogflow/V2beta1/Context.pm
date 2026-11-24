package Google::Cloud::Dialogflow::V2beta1::Context;

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
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2NvbnRleHQucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGhxnb29nbGUvcHJv
dG9idWYvc3RydWN0LnByb3RvIqEECgdDb250ZXh0EhIKBG5hbWUYASABKAlSBG5hbWUSJQoO
bGlmZXNwYW5fY291bnQYAiABKAVSDWxpZmVzcGFuQ291bnQSNwoKcGFyYW1ldGVycxgDIAEo
CzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCnBhcmFtZXRlcnM6oQPqQZ0DCiFkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL0NvbnRleHQSPnByb2plY3RzL3twcm9qZWN0fS9hZ2VudC9z
ZXNzaW9ucy97c2Vzc2lvbn0vY29udGV4dHMve2NvbnRleHR9EmZwcm9qZWN0cy97cHJvamVj
dH0vYWdlbnQvZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVudH0vdXNlcnMve3VzZXJ9L3Nlc3Np
b25zL3tzZXNzaW9ufS9jb250ZXh0cy97Y29udGV4dH0SU3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9hZ2VudC9zZXNzaW9ucy97c2Vzc2lvbn0vY29udGV4dHMv
e2NvbnRleHR9Entwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdl
bnQvZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVudH0vdXNlcnMve3VzZXJ9L3Nlc3Npb25zL3tz
ZXNzaW9ufS9jb250ZXh0cy97Y29udGV4dH0ilAEKE0xpc3RDb250ZXh0c1JlcXVlc3QSQQoG
cGFyZW50GAEgASgJQingQQL6QSMSIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29udGV4
dFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuIoQBChRMaXN0Q29udGV4dHNSZXNwb25zZRJECghjb250ZXh0cxgB
IAMoCzIoLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ29udGV4dFIIY29udGV4
dHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlIKEUdldENvbnRl
eHRSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9Db250ZXh0UgRuYW1lIqIBChRDcmVhdGVDb250ZXh0UmVxdWVzdBJBCgZwYXJlbnQY
ASABKAlCKeBBAvpBIxIhZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Db250ZXh0UgZwYXJl
bnQSRwoHY29udGV4dBgCIAEoCzIoLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
Q29udGV4dEID4EECUgdjb250ZXh0IqEBChRVcGRhdGVDb250ZXh0UmVxdWVzdBJHCgdjb250
ZXh0GAEgASgLMiguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db250ZXh0QgPg
QQJSB2NvbnRleHQSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmll
bGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siVQoURGVsZXRlQ29udGV4dFJlcXVlc3QSPQoEbmFt
ZRgBIAEoCUIp4EEC+kEjCiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbnRleHRSBG5h
bWUiXQoYRGVsZXRlQWxsQ29udGV4dHNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEj
EiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbnRleHRSBnBhcmVudDKcFgoIQ29udGV4
dHMSugMKDExpc3RDb250ZXh0cxI0Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
TGlzdENvbnRleHRzUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
TGlzdENvbnRleHRzUmVzcG9uc2UivAKC0+STAqwCEjYvdjJiZXRhMS97cGFyZW50PXByb2pl
Y3RzLyovYWdlbnQvc2Vzc2lvbnMvKn0vY29udGV4dHNaTxJNL3YyYmV0YTEve3BhcmVudD1w
cm9qZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKn0vY29u
dGV4dHNaRBJCL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50
L3Nlc3Npb25zLyp9L2NvbnRleHRzWlsSWS92MmJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25zLyp9L2Nv
bnRleHRz2kEGcGFyZW50EqcDCgpHZXRDb250ZXh0EjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjJiZXRhMS5HZXRDb250ZXh0UmVxdWVzdBooLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyYmV0YTEuQ29udGV4dCK6AoLT5JMCrAISNi92MmJldGExL3tuYW1lPXByb2plY3RzLyov
YWdlbnQvc2Vzc2lvbnMvKi9jb250ZXh0cy8qfVpPEk0vdjJiZXRhMS97bmFtZT1wcm9qZWN0
cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKi9jb250ZXh0cy8q
fVpEEkIvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L3Nlc3Np
b25zLyovY29udGV4dHMvKn1aWxJZL3YyYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25zLyovY29udGV4dHMv
Kn3aQQRuYW1lEtsDCg1DcmVhdGVDb250ZXh0EjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMS5DcmVhdGVDb250ZXh0UmVxdWVzdBooLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyYmV0YTEuQ29udGV4dCLoAoLT5JMC0AIiNi92MmJldGExL3twYXJlbnQ9cHJvamVjdHMv
Ki9hZ2VudC9zZXNzaW9ucy8qfS9jb250ZXh0czoHY29udGV4dFpYIk0vdjJiZXRhMS97cGFy
ZW50PXByb2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8q
fS9jb250ZXh0czoHY29udGV4dFpNIkIvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyovYWdlbnQvc2Vzc2lvbnMvKn0vY29udGV4dHM6B2NvbnRleHRaZCJZL3YyYmV0
YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8q
L3VzZXJzLyovc2Vzc2lvbnMvKn0vY29udGV4dHM6B2NvbnRleHTaQQ5wYXJlbnQsY29udGV4
dBKKBAoNVXBkYXRlQ29udGV4dBI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
VXBkYXRlQ29udGV4dFJlcXVlc3QaKC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LkNvbnRleHQilwOC0+STAvACMj4vdjJiZXRhMS97Y29udGV4dC5uYW1lPXByb2plY3RzLyov
YWdlbnQvc2Vzc2lvbnMvKi9jb250ZXh0cy8qfToHY29udGV4dFpgMlUvdjJiZXRhMS97Y29u
dGV4dC5uYW1lPXByb2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNz
aW9ucy8qL2NvbnRleHRzLyp9Ogdjb250ZXh0WlUySi92MmJldGExL3tjb250ZXh0Lm5hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9zZXNzaW9ucy8qL2NvbnRleHRzLyp9Ogdj
b250ZXh0WmwyYS92MmJldGExL3tjb250ZXh0Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25zLyovY29udGV4dHMvKn06
B2NvbnRleHTaQRNjb250ZXh0LHVwZGF0ZV9tYXNr2kEHY29udGV4dBKbAwoNRGVsZXRlQ29u
dGV4dBI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRGVsZXRlQ29udGV4dFJl
cXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiugKC0+STAqwCKjYvdjJiZXRhMS97bmFt
ZT1wcm9qZWN0cy8qL2FnZW50L3Nlc3Npb25zLyovY29udGV4dHMvKn1aTypNL3YyYmV0YTEv
e25hbWU9cHJvamVjdHMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25z
LyovY29udGV4dHMvKn1aRCpCL3YyYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9hZ2VudC9zZXNzaW9ucy8qL2NvbnRleHRzLyp9WlsqWS92MmJldGExL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9u
cy8qL2NvbnRleHRzLyp92kEEbmFtZRKlAwoRRGVsZXRlQWxsQ29udGV4dHMSOS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkRlbGV0ZUFsbENvbnRleHRzUmVxdWVzdBoWLmdv
b2dsZS5wcm90b2J1Zi5FbXB0eSK8AoLT5JMCrAIqNi92MmJldGExL3twYXJlbnQ9cHJvamVj
dHMvKi9hZ2VudC9zZXNzaW9ucy8qfS9jb250ZXh0c1pPKk0vdjJiZXRhMS97cGFyZW50PXBy
b2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qfS9jb250
ZXh0c1pEKkIvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQv
c2Vzc2lvbnMvKn0vY29udGV4dHNaWypZL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKn0vY29u
dGV4dHPaQQZwYXJlbnQaeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KhAQojY29tLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTFCDENvbnRleHRQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2Rp
YWxvZ2Zsb3cvYXBpdjJiZXRhMS9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAh9H
b29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkJldGExSqpXCgcSBQ4A/QIBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAJQoJCgIDBRIDFwAqCgkKAgMGEgMY
ACYKCAoBCBIDGgA8CgkKAgglEgMaADwKCAoBCBIDGwBaCgkKAggLEgMbAFoKCAoBCBIDHAAi
CgkKAggKEgMcACIKCAoBCBIDHQAtCgkKAggIEgMdAC0KCAoBCBIDHgA8CgkKAggBEgMeADwK
CAoBCBIDHwAgCgkKAggkEgMfACAKWAoCBgASBSIAmQEBGksgU2VydmljZSBmb3IgbWFuYWdp
bmcgW0NvbnRleHRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbnRleHRd
LgoKCgoDBgABEgMiCBAKCgoDBgADEgMjAkEKDAoFBgADmQgSAyMCQQoLCgMGAAMSBCQCJjMK
DQoFBgADmggSBCQCJjMKSgoEBgACABIEKQI3Axo8IFJldHVybnMgdGhlIGxpc3Qgb2YgYWxs
IGNvbnRleHRzIGluIHRoZSBzcGVjaWZpZWQgc2Vzc2lvbi4KCgwKBQYAAgABEgMpBhIKDAoF
BgACAAISAykTJgoMCgUGAAIAAxIDKTFFCg0KBQYAAgAEEgQqBDUGChEKCQYAAgAEsMq8IhIE
KgQ1BgoMCgUGAAIABBIDNgQ0Cg8KCAYAAgAEmwgAEgM2BDQKMAoEBgACARIEOgJIAxoiIFJl
dHJpZXZlcyB0aGUgc3BlY2lmaWVkIGNvbnRleHQuCgoMCgUGAAIBARIDOgYQCgwKBQYAAgEC
EgM6ESIKDAoFBgACAQMSAzotNAoNCgUGAAIBBBIEOwRGBgoRCgkGAAIBBLDKvCISBDsERgYK
DAoFBgACAQQSA0cEMgoPCggGAAIBBJsIABIDRwQyCmQKBAYAAgISBE0CXwMaViBDcmVhdGVz
IGEgY29udGV4dC4KCiBJZiB0aGUgc3BlY2lmaWVkIGNvbnRleHQgYWxyZWFkeSBleGlzdHMs
IG92ZXJyaWRlcyB0aGUgY29udGV4dC4KCgwKBQYAAgIBEgNNBhMKDAoFBgACAgISA00UKAoM
CgUGAAICAxIDTTM6Cg0KBQYAAgIEEgROBF0GChEKCQYAAgIEsMq8IhIETgRdBgoMCgUGAAIC
BBIDXgQ8Cg8KCAYAAgIEmwgAEgNeBDwKLgoEBgACAxIEYgJ1AxogIFVwZGF0ZXMgdGhlIHNw
ZWNpZmllZCBjb250ZXh0LgoKDAoFBgACAwESA2IGEwoMCgUGAAIDAhIDYhQoCgwKBQYAAgMD
EgNiMzoKDQoFBgACAwQSBGMEcgYKEQoJBgACAwSwyrwiEgRjBHIGCgwKBQYAAgMEEgNzBEEK
DwoIBgACAwSbCAASA3MEQQoMCgUGAAIDBBIDdAQ1Cg8KCAYAAgMEmwgBEgN0BDUKLwoEBgAC
BBIFeAKGAQMaICBEZWxldGVzIHRoZSBzcGVjaWZpZWQgY29udGV4dC4KCgwKBQYAAgQBEgN4
BhMKDAoFBgACBAISA3gUKAoMCgUGAAIEAxIDeDNICg4KBQYAAgQEEgV5BIQBBgoSCgkGAAIE
BLDKvCISBXkEhAEGCg0KBQYAAgQEEgSFAQQyChAKCAYAAgQEmwgAEgSFAQQyCkcKBAYAAgUS
BokBApgBAxo3IERlbGV0ZXMgYWxsIGFjdGl2ZSBjb250ZXh0cyBpbiB0aGUgc3BlY2lmaWVk
IHNlc3Npb24uCgoNCgUGAAIFARIEiQEGFwoNCgUGAAIFAhIEiQEYMAoNCgUGAAIFAxIEigEP
JAoPCgUGAAIFBBIGiwEElgEGChMKCQYAAgUEsMq8IhIGiwEElgEGCg0KBQYAAgUEEgSXAQQ0
ChAKCAYAAgUEmwgAEgSXAQQ0CoUHCgIEABIGqgEA4QEBGvYGIERpYWxvZ2Zsb3cgY29udGV4
dHMgYXJlIHNpbWlsYXIgdG8gbmF0dXJhbCBsYW5ndWFnZSBjb250ZXh0LiBJZiBhIHBlcnNv
biBzYXlzCiB0byB5b3UgInRoZXkgYXJlIG9yYW5nZSIsIHlvdSBuZWVkIGNvbnRleHQgaW4g
b3JkZXIgdG8gdW5kZXJzdGFuZCB3aGF0ICJ0aGV5IgogaXMgcmVmZXJyaW5nIHRvLiBTaW1p
bGFybHksIGZvciBEaWFsb2dmbG93IHRvIGhhbmRsZSBhbiBlbmQtdXNlciBleHByZXNzaW9u
CiBsaWtlIHRoYXQsIGl0IG5lZWRzIHRvIGJlIHByb3ZpZGVkIHdpdGggY29udGV4dCBpbiBv
cmRlciB0byBjb3JyZWN0bHkgbWF0Y2gKIGFuIGludGVudC4KCiBVc2luZyBjb250ZXh0cywg
eW91IGNhbiBjb250cm9sIHRoZSBmbG93IG9mIGEgY29udmVyc2F0aW9uLiBZb3UgY2FuIGNv
bmZpZ3VyZQogY29udGV4dHMgZm9yIGFuIGludGVudCBieSBzZXR0aW5nIGlucHV0IGFuZCBv
dXRwdXQgY29udGV4dHMsIHdoaWNoIGFyZQogaWRlbnRpZmllZCBieSBzdHJpbmcgbmFtZXMu
IFdoZW4gYW4gaW50ZW50IGlzIG1hdGNoZWQsIGFueSBjb25maWd1cmVkIG91dHB1dAogY29u
dGV4dHMgZm9yIHRoYXQgaW50ZW50IGJlY29tZSBhY3RpdmUuIFdoaWxlIGFueSBjb250ZXh0
cyBhcmUgYWN0aXZlLAogRGlhbG9nZmxvdyBpcyBtb3JlIGxpa2VseSB0byBtYXRjaCBpbnRl
bnRzIHRoYXQgYXJlIGNvbmZpZ3VyZWQgd2l0aCBpbnB1dAogY29udGV4dHMgdGhhdCBjb3Jy
ZXNwb25kIHRvIHRoZSBjdXJyZW50bHkgYWN0aXZlIGNvbnRleHRzLgoKIEZvciBtb3JlIGlu
Zm9ybWF0aW9uIGFib3V0IGNvbnRleHQsIHNlZSB0aGUKIFtDb250ZXh0cyBndWlkZV0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvZG9jcy9jb250ZXh0cy1vdmVydmll
dykuCgoLCgMEAAESBKoBCA8KDQoDBAAHEgarAQKxAQQKDwoFBAAHnQgSBqsBArEBBAqYCAoE
BAACABIEygECEhqJCCBSZXF1aXJlZC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBj
b250ZXh0LiBTdXBwb3J0ZWQgZm9ybWF0czoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9h
Z2VudC9zZXNzaW9ucy88U2Vzc2lvbiBJRD4vY29udGV4dHMvPENvbnRleHQKICAgSUQ+YCwK
IC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2Vu
dC9zZXNzaW9ucy88U2Vzc2lvbgogICBJRD4vY29udGV4dHMvPENvbnRleHQgSUQ+YCwKIC0g
YHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50
IElEPi91c2Vycy88VXNlcgogICBJRD4vc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2NvbnRleHRz
LzxDb250ZXh0IElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxM
b2NhdGlvbgogICBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNl
cnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPi9jb250ZXh0cy88Q29udGV4
dCBJRD5gLAoKIFRoZSBgQ29udGV4dCBJRGAgaXMgYWx3YXlzIGNvbnZlcnRlZCB0byBsb3dl
cmNhc2UsIG1heSBvbmx5IGNvbnRhaW4KIGNoYXJhY3RlcnMgaW4gYGEtekEtWjAtOV8tJWAg
YW5kIG1heSBiZSBhdCBtb3N0IDI1MCBieXRlcyBsb25nLgoKIElmIGBFbnZpcm9ubWVudCBJ
RGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JwogZW52aXJv
bm1lbnQuIElmIGBVc2VyIElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVs
dCAnLScgdXNlci4KCiBUaGUgZm9sbG93aW5nIGNvbnRleHQgbmFtZXMgYXJlIHJlc2VydmVk
IGZvciBpbnRlcm5hbCB1c2UgYnkgRGlhbG9nZmxvdy4KIFlvdSBzaG91bGQgbm90IHVzZSB0
aGVzZSBjb250ZXh0cyBvciBjcmVhdGUgY29udGV4dHMgd2l0aCB0aGVzZSBuYW1lczoKCiAq
IGBfX3N5c3RlbV9jb3VudGVyc19fYAogKiBgKl9pZF9kaWFsb2dfY29udGV4dGAKICogYCpf
ZGlhbG9nX3BhcmFtc19zaXplYAoKDQoFBAACAAUSBMoBAggKDQoFBAACAAESBMoBCQ0KDQoF
BAACAAMSBMoBEBEK/wEKBAQAAgESBNABAhsa8AEgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2Yg
Y29udmVyc2F0aW9uYWwgcXVlcnkgcmVxdWVzdHMgYWZ0ZXIgd2hpY2ggdGhlCiBjb250ZXh0
IGV4cGlyZXMuIFRoZSBkZWZhdWx0IGlzIGAwYC4gSWYgc2V0IHRvIGAwYCwgdGhlIGNvbnRl
eHQgZXhwaXJlcwogaW1tZWRpYXRlbHkuIENvbnRleHRzIGV4cGlyZSBhdXRvbWF0aWNhbGx5
IGFmdGVyIDIwIG1pbnV0ZXMgaWYgdGhlcmUKIGFyZSBubyBtYXRjaGluZyBxdWVyaWVzLgoK
DQoFBAACAQUSBNABAgcKDQoFBAACAQESBNABCBYKDQoFBAACAQMSBNABGRoKuQUKBAQAAgIS
BOABAigaqgUgT3B0aW9uYWwuIFRoZSBjb2xsZWN0aW9uIG9mIHBhcmFtZXRlcnMgYXNzb2Np
YXRlZCB3aXRoIHRoaXMgY29udGV4dC4KCiBEZXBlbmRpbmcgb24geW91ciBwcm90b2NvbCBv
ciBjbGllbnQgbGlicmFyeSBsYW5ndWFnZSwgdGhpcyBpcyBhCiBtYXAsIGFzc29jaWF0aXZl
IGFycmF5LCBzeW1ib2wgdGFibGUsIGRpY3Rpb25hcnksIG9yIEpTT04gb2JqZWN0CiBjb21w
b3NlZCBvZiBhIGNvbGxlY3Rpb24gb2YgKE1hcEtleSwgTWFwVmFsdWUpIHBhaXJzOgoKICog
TWFwS2V5IHR5cGU6IHN0cmluZwogKiBNYXBLZXkgdmFsdWU6IHBhcmFtZXRlciBuYW1lCiAq
IE1hcFZhbHVlIHR5cGU6IElmIHBhcmFtZXRlcidzIGVudGl0eSB0eXBlIGlzIGEgY29tcG9z
aXRlIGVudGl0eSB0aGVuIHVzZQogbWFwLCBvdGhlcndpc2UsIGRlcGVuZGluZyBvbiB0aGUg
cGFyYW1ldGVyIHZhbHVlIHR5cGUsIGl0IGNvdWxkIGJlIG9uZSBvZgogc3RyaW5nLCBudW1i
ZXIsIGJvb2xlYW4sIG51bGwsIGxpc3Qgb3IgbWFwLgogKiBNYXBWYWx1ZSB2YWx1ZTogSWYg
cGFyYW1ldGVyJ3MgZW50aXR5IHR5cGUgaXMgYSBjb21wb3NpdGUgZW50aXR5IHRoZW4gdXNl
CiBtYXAgZnJvbSBjb21wb3NpdGUgZW50aXR5IHByb3BlcnR5IG5hbWVzIHRvIHByb3BlcnR5
IHZhbHVlcywgb3RoZXJ3aXNlLAogdXNlIHBhcmFtZXRlciB2YWx1ZS4KCg0KBQQAAgIGEgTg
AQIYCg0KBQQAAgIBEgTgARkjCg0KBQQAAgIDEgTgASYnCngKAgQBEgblAQCAAgEaaiBUaGUg
cmVxdWVzdCBtZXNzYWdlIGZvcgogW0NvbnRleHRzLkxpc3RDb250ZXh0c11bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db250ZXh0cy5MaXN0Q29udGV4dHNdLgoKCwoDBAEB
EgTlAQgbCpwFCgQEAQIAEgbzAQL4AQQaiwUgUmVxdWlyZWQuIFRoZSBzZXNzaW9uIHRvIGxp
c3QgYWxsIGNvbnRleHRzIGZyb20uIFN1cHBvcnRlZCBmb3JtYXRzOgogLSBgcHJvamVjdHMv
PFByb2plY3QgSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uIElEPiwKIC0gYHByb2plY3Rz
LzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2VudC9zZXNzaW9ucy88
U2Vzc2lvbgogICBJRD5gLAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmly
b25tZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyCiAgIElEPi9zZXNzaW9ucy88
U2Vzc2lvbiBJRD5gLAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9j
YXRpb24KICAgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJz
LzxVc2VyIElEPi9zZXNzaW9ucy88U2Vzc2lvbgogICBJRD5gLAoKIElmIGBMb2NhdGlvbiBJ
RGAgaXMgbm90IHNwZWNpZmllZCB3ZSBhc3N1bWUgZGVmYXVsdCAndXMnIGxvY2F0aW9uLiBJ
ZgogYEVudmlyb25tZW50IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVs
dCAnZHJhZnQnIGVudmlyb25tZW50LgogSWYgYFVzZXIgSURgIGlzIG5vdCBzcGVjaWZpZWQs
IHdlIGFzc3VtZSBkZWZhdWx0ICctJyB1c2VyLgoKDQoFBAECAAUSBPMBAggKDQoFBAECAAES
BPMBCQ8KDQoFBAECAAMSBPMBEhMKDwoFBAECAAgSBvMBFPgBAwoQCggEAQIACJwIABIE9AEE
KgoRCgcEAQIACJ8IEgb1AQT3AQUKcwoEBAECARIE/AECFhplIE9wdGlvbmFsLiBUaGUgbWF4
aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHBhZ2UuIEJ5CiBk
ZWZhdWx0IDEwMCBhbmQgYXQgbW9zdCAxMDAwLgoKDQoFBAECAQUSBPwBAgcKDQoFBAECAQES
BPwBCBEKDQoFBAECAQMSBPwBFBUKWgoEBAECAhIE/wECGBpMIE9wdGlvbmFsLiBUaGUgbmV4
dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVl
c3QuCgoNCgUEAQICBRIE/wECCAoNCgUEAQICARIE/wEJEwoNCgUEAQICAxIE/wEWFwp5CgIE
AhIGhAIAjAIBGmsgVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbQ29udGV4dHMuTGlzdENv
bnRleHRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbnRleHRzLkxpc3RD
b250ZXh0c10uCgoLCgMEAgESBIQCCBwKhAEKBAQCAgASBIcCAiAadiBUaGUgbGlzdCBvZiBj
b250ZXh0cy4gVGhlcmUgd2lsbCBiZSBhIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zCiByZXR1
cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGluIHRoZSByZXF1ZXN0LgoKDQoF
BAICAAQSBIcCAgoKDQoFBAICAAYSBIcCCxIKDQoFBAICAAESBIcCExsKDQoFBAICAAMSBIcC
Hh8KbwoEBAICARIEiwICHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2Yg
cmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3JlIHJlc3VsdHMgaW4gdGhl
IGxpc3QuCgoNCgUEAgIBBRIEiwICCAoNCgUEAgIBARIEiwIJGAoNCgUEAgIBAxIEiwIbHAp0
CgIEAxIGkAIApQIBGmYgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb250ZXh0cy5HZXRD
b250ZXh0XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbnRleHRzLkdldENv
bnRleHRdLgoKCwoDBAMBEgSQAggZCuoFCgQEAwIAEgafAgKkAgQa2QUgUmVxdWlyZWQuIFRo
ZSBuYW1lIG9mIHRoZSBjb250ZXh0LiBTdXBwb3J0ZWQgZm9ybWF0czoKIC0gYHByb2plY3Rz
LzxQcm9qZWN0IElEPi9hZ2VudC9zZXNzaW9ucy88U2Vzc2lvbiBJRD4vY29udGV4dHMvPENv
bnRleHQKICAgSUQ+YCwKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExv
Y2F0aW9uIElEPi9hZ2VudC9zZXNzaW9ucy88U2Vzc2lvbgogICBJRD4vY29udGV4dHMvPENv
bnRleHQgSUQ+YCwKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9lbnZpcm9ubWVu
dHMvPEVudmlyb25tZW50IElEPi91c2Vycy88VXNlcgogICBJRD4vc2Vzc2lvbnMvPFNlc3Np
b24gSUQ+L2NvbnRleHRzLzxDb250ZXh0IElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vbG9jYXRpb25zLzxMb2NhdGlvbgogICBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZp
cm9ubWVudCBJRD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPi9j
b250ZXh0cy88Q29udGV4dCBJRD5gLAoKIElmIGBMb2NhdGlvbiBJRGAgaXMgbm90IHNwZWNp
ZmllZCB3ZSBhc3N1bWUgZGVmYXVsdCAndXMnIGxvY2F0aW9uLiBJZgogYEVudmlyb25tZW50
IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnIGVudmly
b25tZW50LgogSWYgYFVzZXIgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZh
dWx0ICctJyB1c2VyLgoKDQoFBAMCAAUSBJ8CAggKDQoFBAMCAAESBJ8CCQ0KDQoFBAMCAAMS
BJ8CEBEKDwoFBAMCAAgSBp8CEqQCAwoQCggEAwIACJwIABIEoAIEKgoRCgcEAwIACJ8IEgah
AgSjAgUKegoCBAQSBqkCAMACARpsIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ29udGV4
dHMuQ3JlYXRlQ29udGV4dF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db250
ZXh0cy5DcmVhdGVDb250ZXh0XS4KCgsKAwQEARIEqQIIHAqaBQoEBAQCABIGtwICvAIEGokF
IFJlcXVpcmVkLiBUaGUgc2Vzc2lvbiB0byBjcmVhdGUgYSBjb250ZXh0IGZvci4gU3VwcG9y
dGVkIGZvcm1hdHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMv
PFNlc3Npb24gSUQ+LAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9j
YXRpb24gSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPmAsCiAtIGBwcm9qZWN0
cy88UHJvamVjdCBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNl
cnMvPFVzZXIKICAgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uIElEPmAsCiAtIGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgogICBJRD4vYWdlbnQvZW52aXJvbm1l
bnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9u
CiAgIElEPmAsCgogSWYgYExvY2F0aW9uIElEYCBpcyBub3Qgc3BlY2lmaWVkIHdlIGFzc3Vt
ZSBkZWZhdWx0ICd1cycgbG9jYXRpb24uIElmCiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBz
cGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcgZW52aXJvbm1lbnQuCiBJZiBg
VXNlciBJRGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVzZXIu
CgoNCgUEBAIABRIEtwICCAoNCgUEBAIAARIEtwIJDwoNCgUEBAIAAxIEtwISEwoPCgUEBAIA
CBIGtwIUvAIDChAKCAQEAgAInAgAEgS4AgQqChEKBwQEAgAInwgSBrkCBLsCBQowCgQEBAIB
EgS/AgI/GiIgUmVxdWlyZWQuIFRoZSBjb250ZXh0IHRvIGNyZWF0ZS4KCg0KBQQEAgEGEgS/
AgIJCg0KBQQEAgEBEgS/AgoRCg0KBQQEAgEDEgS/AhQVCg0KBQQEAgEIEgS/AhY+ChAKCAQE
AgEInAgAEgS/Ahc9CnoKAgQFEgbEAgDLAgEabCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgog
W0NvbnRleHRzLlVwZGF0ZUNvbnRleHRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0
YTEuQ29udGV4dHMuVXBkYXRlQ29udGV4dF0uCgoLCgMEBQESBMQCCBwKMAoEBAUCABIExgIC
PxoiIFJlcXVpcmVkLiBUaGUgY29udGV4dCB0byB1cGRhdGUuCgoNCgUEBQIABhIExgICCQoN
CgUEBQIAARIExgIKEQoNCgUEBQIAAxIExgIUFQoNCgUEBQIACBIExgIWPgoQCggEBQIACJwI
ABIExgIXPQpJCgQEBQIBEgbJAgLKAi8aOSBPcHRpb25hbC4gVGhlIG1hc2sgdG8gY29udHJv
bCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBQIBBhIEyQICGwoNCgUEBQIBARIE
yQIcJwoNCgUEBQIBAxIEyQIqKwoNCgUEBQIBCBIEygIGLgoQCggEBQIBCJwIABIEygIHLQp6
CgIEBhIGzwIA5AIBGmwgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb250ZXh0cy5EZWxl
dGVDb250ZXh0XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkNvbnRleHRzLkRl
bGV0ZUNvbnRleHRdLgoKCwoDBAYBEgTPAggcCvQFCgQEBgIAEgbeAgLjAgQa4wUgUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBjb250ZXh0IHRvIGRlbGV0ZS4gU3VwcG9ydGVkIGZvcm1h
dHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24g
SUQ+L2NvbnRleHRzLzxDb250ZXh0CiAgIElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24KICAg
SUQ+L2NvbnRleHRzLzxDb250ZXh0IElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4v
YWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIKICAgSUQ+
L3Nlc3Npb25zLzxTZXNzaW9uIElEPi9jb250ZXh0cy88Q29udGV4dCBJRD5gLAogLSBgcHJv
amVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24KICAgSUQ+L2FnZW50L2Vu
dmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyIElEPi9zZXNzaW9ucy88
U2Vzc2lvbgogICBJRD4vY29udGV4dHMvPENvbnRleHQgSUQ+YCwKCiBJZiBgTG9jYXRpb24g
SURgIGlzIG5vdCBzcGVjaWZpZWQgd2UgYXNzdW1lIGRlZmF1bHQgJ3VzJyBsb2NhdGlvbi4g
SWYKIGBFbnZpcm9ubWVudCBJRGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1
bHQgJ2RyYWZ0JyBlbnZpcm9ubWVudC4KIElmIGBVc2VyIElEYCBpcyBub3Qgc3BlY2lmaWVk
LCB3ZSBhc3N1bWUgZGVmYXVsdCAnLScgdXNlci4KCg0KBQQGAgAFEgTeAgIICg0KBQQGAgAB
EgTeAgkNCg0KBQQGAgADEgTeAhARCg8KBQQGAgAIEgbeAhLjAgMKEAoIBAYCAAicCAASBN8C
BCoKEQoHBAYCAAifCBIG4AIE4gIFCoIBCgIEBxIG6AIA/QIBGnQgVGhlIHJlcXVlc3QgbWVz
c2FnZSBmb3IKIFtDb250ZXh0cy5EZWxldGVBbGxDb250ZXh0c11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjJiZXRhMS5Db250ZXh0cy5EZWxldGVBbGxDb250ZXh0c10uCgoLCgMEBwES
BOgCCCAKqgUKBAQHAgASBvcCAvwCBBqZBSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNl
c3Npb24gdG8gZGVsZXRlIGFsbCBjb250ZXh0cyBmcm9tLiBTdXBwb3J0ZWQKIGZvcm1hdHM6
CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+
LAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+L2Fn
ZW50L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIKICAg
SUQ+L3Nlc3Npb25zLzxTZXNzaW9uIElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4v
bG9jYXRpb25zLzxMb2NhdGlvbgogICBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9u
bWVudCBJRD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPmAsCgog
SWYgYExvY2F0aW9uIElEYCBpcyBub3Qgc3BlY2lmaWVkIHdlIGFzc3VtZSBkZWZhdWx0ICd1
cycgbG9jYXRpb24uIElmCiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQgd2Ug
YXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JyBlbnZpcm9ubWVudC4gSWYKIGBVc2VyIElEYCBpcyBu
b3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnLScgdXNlci4KCg0KBQQHAgAFEgT3
AgIICg0KBQQHAgABEgT3AgkPCg0KBQQHAgADEgT3AhITCg8KBQQHAgAIEgb3AhT8AgMKEAoI
BAcCAAicCAASBPgCBCoKEQoHBAcCAAifCBIG+QIE+wIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::Context ===
    # Fields for Context
    # Field: name Type: 9 ()
    # Field: lifespan_count Type: 5 ()
    # Field: parameters Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest ===
    # Fields for ListContextsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse ===
    # Fields for ListContextsResponse
    # Field: contexts Type: 11 (.google.cloud.dialogflow.v2beta1.Context)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::GetContextRequest ===
    # Fields for GetContextRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::CreateContextRequest ===
    # Fields for CreateContextRequest
    # Field: parent Type: 9 ()
    # Field: context Type: 11 (.google.cloud.dialogflow.v2beta1.Context)

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::UpdateContextRequest ===
    # Fields for UpdateContextRequest
    # Field: context Type: 11 (.google.cloud.dialogflow.v2beta1.Context)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::DeleteContextRequest ===
    # Fields for DeleteContextRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Context::DeleteAllContextsRequest ===
    # Fields for DeleteAllContextsRequest
    # Field: parent Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2beta1::Context::ContextsClient ===
package Google::Cloud::Dialogflow::V2beta1::Context::ContextsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::Context::ContextsClient

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
        ? Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'ListContexts',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse',
    });
}

sub get_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Context::GetContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'GetContext',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Context::Context',
    });
}

sub create_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Context::CreateContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'CreateContext',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Context::Context',
    });
}

sub update_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Context::UpdateContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'UpdateContext',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Context::Context',
    });
}

sub delete_context {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Context::DeleteContextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'DeleteContext',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub delete_all_contexts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Context::DeleteAllContextsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'DeleteAllContexts',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Context - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/context.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Context;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Context::Context->new({
        name => $name,
        lifespan_count => $lifespan_count,
        parameters => $parameters,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Context::Context->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Context::Context

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

Required. The unique identifier of the context. Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>/contexts/<Context
  ID>`,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>/contexts/<Context ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>/contexts/<Context ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>/contexts/<Context ID>`,

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

=head2 Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest

The request message for
[Contexts.ListContexts][google.cloud.dialogflow.v2beta1.Contexts.ListContexts].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to list all contexts from. Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse

The response message for
[Contexts.ListContexts][google.cloud.dialogflow.v2beta1.Contexts.ListContexts].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contexts() >> / C<< $msg->contexts($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Context::Context>)

The list of contexts. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Context::GetContextRequest

The request message for
[Contexts.GetContext][google.cloud.dialogflow.v2beta1.Contexts.GetContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the context. Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>/contexts/<Context
  ID>`,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>/contexts/<Context ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>/contexts/<Context ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>/contexts/<Context ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Context::CreateContextRequest

The request message for
[Contexts.CreateContext][google.cloud.dialogflow.v2beta1.Contexts.CreateContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to create a context for. Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Context::Context>)

Required. The context to create.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Context::UpdateContextRequest

The request message for
[Contexts.UpdateContext][google.cloud.dialogflow.v2beta1.Contexts.UpdateContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Context::Context>)

Required. The context to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Context::DeleteContextRequest

The request message for
[Contexts.DeleteContext][google.cloud.dialogflow.v2beta1.Contexts.DeleteContext].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the context to delete. Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>/contexts/<Context
  ID>`,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>/contexts/<Context ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>/contexts/<Context ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>/contexts/<Context ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Context::DeleteAllContextsRequest

The request message for
[Contexts.DeleteAllContexts][google.cloud.dialogflow.v2beta1.Contexts.DeleteAllContexts].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the session to delete all contexts from. Supported
formats:
- `projects/<Project ID>/agent/sessions/<Session ID>,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified we assume default 'draft' environment. If
`User ID` is not specified, we assume default '-' user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Context::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
