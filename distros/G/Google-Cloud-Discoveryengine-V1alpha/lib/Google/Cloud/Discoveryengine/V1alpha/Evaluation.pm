package Google::Cloud::Discoveryengine::V1alpha::Evaluation;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::SearchService };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZXZhbHVhdGlvbi5wcm90
bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjlnb29nbGUv
Y2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2VhcmNoX3NlcnZpY2UucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3Rv
IuwICgpFdmFsdWF0aW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJtCg9ldmFsdWF0aW9u
X3NwZWMYAiABKAsyPy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZh
bHVhdGlvbi5FdmFsdWF0aW9uU3BlY0ID4EECUg5ldmFsdWF0aW9uU3BlYxJiCg9xdWFsaXR5
X21ldHJpY3MYAyABKAsyNC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
UXVhbGl0eU1ldHJpY3NCA+BBA1IOcXVhbGl0eU1ldHJpY3MSUQoFc3RhdGUYBCABKA4yNi5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvbi5TdGF0ZUID
4EEDUgVzdGF0ZRItCgVlcnJvchgFIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzQgPgQQNSBWVy
cm9yEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgdlbmRUaW1lEjwKDWVycm9yX3NhbXBsZXMYCCADKAsyEi5nb29nbGUu
cnBjLlN0YXR1c0ID4EEDUgxlcnJvclNhbXBsZXMa7AIKDkV2YWx1YXRpb25TcGVjEmEKDnNl
YXJjaF9yZXF1ZXN0GAIgASgLMjMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLlNlYXJjaFJlcXVlc3RCA+BBAkgAUg1zZWFyY2hSZXF1ZXN0EncKDnF1ZXJ5X3NldF9z
cGVjGAEgASgLMkwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkV2YWx1
YXRpb24uRXZhbHVhdGlvblNwZWMuUXVlcnlTZXRTcGVjQgPgQQJSDHF1ZXJ5U2V0U3BlYxpv
CgxRdWVyeVNldFNwZWMSXwoQc2FtcGxlX3F1ZXJ5X3NldBgBIAEoCUI14EEC+kEvCi1kaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vU2FtcGxlUXVlcnlTZXRSDnNhbXBsZVF1ZXJ5
U2V0Qg0KC3NlYXJjaF9zcGVjIlMKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoH
UEVORElORxABEgsKB1JVTk5JTkcQAhINCglTVUNDRUVERUQQAxIKCgZGQUlMRUQQBDpw6kFt
CilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRXZhbHVhdGlvbhJAcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2V2YWx1YXRpb25zL3tldmFsdWF0aW9u
fSLcBAoOUXVhbGl0eU1ldHJpY3MSXwoKZG9jX3JlY2FsbBgBIAEoCzJALmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5RdWFsaXR5TWV0cmljcy5Ub3BrTWV0cmljc1IJ
ZG9jUmVjYWxsEmUKDWRvY19wcmVjaXNpb24YAiABKAsyQC5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuUXVhbGl0eU1ldHJpY3MuVG9wa01ldHJpY3NSDGRvY1ByZWNp
c2lvbhJbCghkb2NfbmRjZxgDIAEoCzJALmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5RdWFsaXR5TWV0cmljcy5Ub3BrTWV0cmljc1IHZG9jTmRjZxJhCgtwYWdlX3Jl
Y2FsbBgEIAEoCzJALmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5RdWFs
aXR5TWV0cmljcy5Ub3BrTWV0cmljc1IKcGFnZVJlY2FsbBJdCglwYWdlX25kY2cYBSABKAsy
QC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuUXVhbGl0eU1ldHJpY3Mu
VG9wa01ldHJpY3NSCHBhZ2VOZGNnGmMKC1RvcGtNZXRyaWNzEhMKBXRvcF8xGAEgASgBUgR0
b3AxEhMKBXRvcF8zGAIgASgBUgR0b3AzEhMKBXRvcF81GAMgASgBUgR0b3A1EhUKBnRvcF8x
MBgEIAEoAVIFdG9wMTBCmwIKKGNvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGFCD0V2YWx1YXRpb25Qcm90b1ABWlJjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVy
eWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBi
ogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFs
cGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWFscGhh6gInR29vZ2xlOjpD
bG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhhSudACgcSBQ4A5wEBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFABDCgkKAgMDEgMVACkKCQoCAwQSAxYAIQoICgEIEgMYAEEKCQoCCCUSAxgA
QQoICgEIEgMZAGkKCQoCCAsSAxkAaQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADAK
CQoCCAgSAxsAMAoICgEIEgMcAEEKCQoCCAESAxwAQQoICgEIEgMdAC0KCQoCCCQSAx0ALQoI
CgEIEgMeAEEKCQoCCCkSAx4AQQoICgEIEgMfAEAKCQoCCC0SAx8AQAqbAQoCBAASBSMAigEB
Go0BIEFuIGV2YWx1YXRpb24gaXMgYSBzaW5nbGUgZXhlY3V0aW9uIChvciBydW4pIG9mIGFu
IGV2YWx1YXRpb24gcHJvY2Vzcy4gSXQKIGVuY2Fwc3VsYXRlcyB0aGUgc3RhdGUgb2YgdGhl
IGV2YWx1YXRpb24gYW5kIHRoZSByZXN1bHRpbmcgZGF0YS4KCgoKAwQAARIDIwgSCgsKAwQA
BxIEJAInBAoNCgUEAAedCBIEJAInBAo+CgQEAAMAEgQqAkwDGjAgRGVzY3JpYmVzIHRoZSBz
cGVjaWZpY2F0aW9uIG9mIHRoZSBldmFsdWF0aW9uLgoKDAoFBAADAAESAyoKGAo/CgYEAAMA
AwASBCwENwUaLyBEZXNjcmliZXMgdGhlIHNwZWNpZmljYXRpb24gb2YgdGhlIHF1ZXJ5IHNl
dC4KCg4KBwQAAwADAAESAywMGAr7AQoIBAADAAMAAgASBDEGNgga6AEgUmVxdWlyZWQuIFRo
ZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlCiBbU2FtcGxlUXVlcnlTZXRdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TYW1wbGVRdWVyeVNldF0KIHVzZWQgZm9y
IHRoZSBldmFsdWF0aW9uLCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L3NhbXBsZVF1ZXJ5U2V0cy97c2FtcGxlUXVlcnlTZXR9
YC4KChAKCQQAAwADAAIABRIDMQYMChAKCQQAAwADAAIAARIDMQ0dChAKCQQAAwADAAIAAxID
MSAhChEKCQQAAwADAAIACBIEMSI2BwoTCgwEAAMAAwACAAicCAASAzIILgoTCgsEAAMAAwAC
AAifCBIEMwg1CQorCgYEAAMACAASBDoESAUaGyBUaGUgc2VhcmNoIHNwZWNpZmljYXRpb24u
CgoOCgcEAAMACAABEgM6ChUKvAcKBgQAAwACABIDRwZQGqwHIFJlcXVpcmVkLiBUaGUgc2Vh
cmNoIHJlcXVlc3QgdGhhdCBpcyB1c2VkIHRvIHBlcmZvcm0gdGhlIGV2YWx1YXRpb24uCgog
T25seSB0aGUgZm9sbG93aW5nIGZpZWxkcyB3aXRoaW4gU2VhcmNoUmVxdWVzdCBhcmUgc3Vw
cG9ydGVkOyBpZiBhbnkKIG90aGVyIGZpZWxkcyBhcmUgcHJvdmlkZWQsIGFuIFVOU1VQUE9S
VEVEIGVycm9yIHdpbGwgYmUgcmV0dXJuZWQ6CgogKiBbU2VhcmNoUmVxdWVzdC5zZXJ2aW5n
X2NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFJl
cXVlc3Quc2VydmluZ19jb25maWddCiAqIFtTZWFyY2hSZXF1ZXN0LmJyYW5jaF1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFJlcXVlc3QuYnJhbmNoXQog
KiBbU2VhcmNoUmVxdWVzdC5jYW5vbmljYWxfZmlsdGVyXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuU2VhcmNoUmVxdWVzdC5jYW5vbmljYWxfZmlsdGVyXQogKiBb
U2VhcmNoUmVxdWVzdC5xdWVyeV9leHBhbnNpb25fc3BlY11bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFJlcXVlc3QucXVlcnlfZXhwYW5zaW9uX3NwZWNd
CiAqIFtTZWFyY2hSZXF1ZXN0LnNwZWxsX2NvcnJlY3Rpb25fc3BlY11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFJlcXVlc3Quc3BlbGxfY29ycmVjdGlv
bl9zcGVjXQogKiBbU2VhcmNoUmVxdWVzdC5jb250ZW50X3NlYXJjaF9zcGVjXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VhcmNoUmVxdWVzdC5jb250ZW50X3Nl
YXJjaF9zcGVjXQogKiBbU2VhcmNoUmVxdWVzdC51c2VyX3BzZXVkb19pZF1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFJlcXVlc3QudXNlcl9wc2V1ZG9f
aWRdCgoOCgcEAAMAAgAGEgNHBhMKDgoHBAADAAIAARIDRxQiCg4KBwQAAwACAAMSA0clJgoO
CgcEAAMAAgAIEgNHJ08KEQoKBAADAAIACJwIABIDRyhOCj4KBgQAAwACARIDSwRNGi8gUmVx
dWlyZWQuIFRoZSBzcGVjaWZpY2F0aW9uIG9mIHRoZSBxdWVyeSBzZXQuCgoOCgcEAAMAAgEG
EgNLBBAKDgoHBAADAAIBARIDSxEfCg4KBwQAAwACAQMSA0siIwoOCgcEAAMAAgEIEgNLJEwK
EQoKBAADAAIBCJwIABIDSyVLCjUKBAQABAASBE8CXgMaJyBEZXNjcmliZXMgdGhlIHN0YXRl
IG9mIGFuIGV2YWx1YXRpb24uCgoMCgUEAAQAARIDTwcMCi8KBgQABAACABIDUQQaGiAgVGhl
IGV2YWx1YXRpb24gaXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgNRBBUKDgoHBAAEAAIA
AhIDURgZCkAKBgQABAACARIDVAQQGjEgVGhlIHNlcnZpY2UgaXMgcHJlcGFyaW5nIHRvIHJ1
biB0aGUgZXZhbHVhdGlvbi4KCg4KBwQABAACAQESA1QECwoOCgcEAAQAAgECEgNUDg8KLwoG
BAAEAAICEgNXBBAaICBUaGUgZXZhbHVhdGlvbiBpcyBpbiBwcm9ncmVzcy4KCg4KBwQABAAC
AgESA1cECwoOCgcEAAQAAgICEgNXDg8KNwoGBAAEAAIDEgNaBBIaKCBUaGUgZXZhbHVhdGlv
biBjb21wbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDgoHBAAEAAIDARIDWgQNCg4KBwQABAACAwIS
A1oQEQonCgYEAAQAAgQSA10EDxoYIFRoZSBldmFsdWF0aW9uIGZhaWxlZC4KCg4KBwQABAAC
BAESA10ECgoOCgcEAAQAAgQCEgNdDQ4KpQIKBAQAAgASA2cCPRqXAiBJZGVudGlmaWVyLiBU
aGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZQogW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uXSwgaW4gdGhlCiBmb3JtYXQg
b2YKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZXZhbHVhdGlv
bnMve2V2YWx1YXRpb259YC4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVk
IHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEwMjQKIGNoYXJhY3RlcnMuCgoMCgUE
AAIABRIDZwIICgwKBQQAAgABEgNnCQ0KDAoFBAACAAMSA2cQEQoMCgUEAAIACBIDZxI8Cg8K
CAQAAgAInAgAEgNnEzsKPQoEBAACARIDagJOGjAgUmVxdWlyZWQuIFRoZSBzcGVjaWZpY2F0
aW9uIG9mIHRoZSBldmFsdWF0aW9uLgoKDAoFBAACAQYSA2oCEAoMCgUEAAIBARIDahEgCgwK
BQQAAgEDEgNqIyQKDAoFBAACAQgSA2olTQoPCggEAAIBCJwIABIDaiZMCqUCCgQEAAICEgRx
AnIyGpYCIE91dHB1dCBvbmx5LiBUaGUgbWV0cmljcyBwcm9kdWNlZCBieSB0aGUgZXZhbHVh
dGlvbiwgYXZlcmFnZWQgYWNyb3NzIGFsbAogW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldcyBpbiB0aGUKIFtTYW1wbGVR
dWVyeVNldF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1
ZXJ5U2V0XS4KCiBPbmx5IHBvcHVsYXRlZCB3aGVuIHRoZSBldmFsdWF0aW9uJ3Mgc3RhdGUg
aXMgU1VDQ0VFREVELgoKDAoFBAACAgYSA3ECEAoMCgUEAAICARIDcREgCgwKBQQAAgIDEgNx
IyQKDAoFBAACAggSA3IGMQoPCggEAAICCJwIABIDcgcwCjgKBAQAAgMSA3UCPhorIE91dHB1
dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIGV2YWx1YXRpb24uCgoMCgUEAAIDBhIDdQIHCgwK
BQQAAgMBEgN1CA0KDAoFBAACAwMSA3UQEQoMCgUEAAIDCBIDdRI9Cg8KCAQAAgMInAgAEgN1
EzwKfQoEBAACBBIDeQJKGnAgT3V0cHV0IG9ubHkuIFRoZSBlcnJvciB0aGF0IG9jY3VycmVk
IGR1cmluZyBldmFsdWF0aW9uLiBPbmx5IHBvcHVsYXRlZCB3aGVuCiB0aGUgZXZhbHVhdGlv
bidzIHN0YXRlIGlzIEZBSUxFRC4KCgwKBQQAAgQGEgN5AhMKDAoFBAACBAESA3kUGQoMCgUE
AAIEAxIDeRwdCgwKBQQAAgQIEgN5HkkKDwoIBAACBAicCAASA3kfSAp6CgQEAAIFEgR+An8y
GmwgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB0aGUKIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvbl0gd2FzIGNyZWF0ZWQKIGF0
LgoKDAoFBAACBQYSA34CGwoMCgUEAAIFARIDfhwnCgwKBQQAAgUDEgN+KisKDAoFBAACBQgS
A38GMQoPCggEAAIFCJwIABIDfwcwCn4KBAQAAgYSBoQBAoUBMhpuIE91dHB1dCBvbmx5LiBU
aW1lc3RhbXAgdGhlCiBbRXZhbHVhdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLkV2YWx1YXRpb25dIHdhcyBjb21wbGV0ZWQKIGF0LgoKDQoFBAACBgYSBIQB
AhsKDQoFBAACBgESBIQBHCQKDQoFBAACBgMSBIQBJygKDQoFBAACBggSBIUBBjEKEAoIBAAC
BgicCAASBIUBBzAKWwoEBAACBxIGiAECiQEyGksgT3V0cHV0IG9ubHkuIEEgc2FtcGxlIG9m
IGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSBwcm9jZXNzaW5nIHRoZSByZXF1ZXN0LgoKDQoF
BAACBwQSBIgBAgoKDQoFBAACBwYSBIgBCxwKDQoFBAACBwESBIgBHSoKDQoFBAACBwMSBIgB
LS4KDQoFBAACBwgSBIkBBjEKEAoIBAACBwicCAASBIkBBzAKQQoCBAESBo0BAOcBARozIERl
c2NyaWJlcyB0aGUgbWV0cmljcyBwcm9kdWNlZCBieSB0aGUgZXZhbHVhdGlvbi4KCgsKAwQB
ARIEjQEIFgpECgQEAQMAEgaPAQKbAQMaNCBTdG9yZXMgdGhlIG1ldHJpYyB2YWx1ZXMgYXQg
c3BlY2lmaWMgdG9wLWsgbGV2ZWxzLgoKDQoFBAEDAAESBI8BChUKIgoGBAEDAAIAEgSRAQQV
GhIgVGhlIHRvcC0xIHZhbHVlLgoKDwoHBAEDAAIABRIEkQEECgoPCgcEAQMAAgABEgSRAQsQ
Cg8KBwQBAwACAAMSBJEBExQKIgoGBAEDAAIBEgSUAQQVGhIgVGhlIHRvcC0zIHZhbHVlLgoK
DwoHBAEDAAIBBRIElAEECgoPCgcEAQMAAgEBEgSUAQsQCg8KBwQBAwACAQMSBJQBExQKIgoG
BAEDAAICEgSXAQQVGhIgVGhlIHRvcC01IHZhbHVlLgoKDwoHBAEDAAICBRIElwEECgoPCgcE
AQMAAgIBEgSXAQsQCg8KBwQBAwACAgMSBJcBExQKIwoGBAEDAAIDEgSaAQQWGhMgVGhlIHRv
cC0xMCB2YWx1ZS4KCg8KBwQBAwACAwUSBJoBBAoKDwoHBAEDAAIDARIEmgELEQoPCgcEAQMA
AgMDEgSaARQVCtkCCgQEAQIAEgSmAQIdGsoCIFJlY2FsbCBwZXIgZG9jdW1lbnQsIGF0IHZh
cmlvdXMgdG9wLWsgY3V0b2ZmIGxldmVscy4KCiBSZWNhbGwgaXMgdGhlIGZyYWN0aW9uIG9m
IHJlbGV2YW50IGRvY3VtZW50cyByZXRyaWV2ZWQgb3V0IG9mIGFsbAogcmVsZXZhbnQgZG9j
dW1lbnRzLgoKIEV4YW1wbGUgKHRvcC01KToKICAqIEZvciBhIHNpbmdsZQogIFtTYW1wbGVR
dWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5
XSwgSWYgMyBvdXQKICBvZiA1IHJlbGV2YW50IGRvY3VtZW50cyBhcmUgcmV0cmlldmVkIGlu
IHRoZSB0b3AtNSwgcmVjYWxsQDUgPSAzLzUgPSAwLjYKCg0KBQQBAgAGEgSmAQINCg0KBQQB
AgABEgSmAQ4YCg0KBQQBAgADEgSmARscCs4CCgQEAQIBEgSxAQIgGr8CIFByZWNpc2lvbiBw
ZXIgZG9jdW1lbnQsIGF0IHZhcmlvdXMgdG9wLWsgY3V0b2ZmIGxldmVscy4KCiBQcmVjaXNp
b24gaXMgdGhlIGZyYWN0aW9uIG9mIHJldHJpZXZlZCBkb2N1bWVudHMgdGhhdCBhcmUgcmVs
ZXZhbnQuCgogRXhhbXBsZSAodG9wLTUpOgogICogRm9yIGEgc2luZ2xlCiAgW1NhbXBsZVF1
ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnld
LCBJZiA0IG91dAogIG9mIDUgcmV0cmlldmVkIGRvY3VtZW50cyBpbiB0aGUgdG9wLTUgYXJl
IHJlbGV2YW50LCBwcmVjaXNpb25ANSA9IDQvNSA9CiAgMC44CgoNCgUEAQIBBhIEsQECDQoN
CgUEAQIBARIEsQEOGwoNCgUEAQIBAxIEsQEeHwreBQoEBAECAhIExgECGxrPBSBOb3JtYWxp
emVkIGRpc2NvdW50ZWQgY3VtdWxhdGl2ZSBnYWluIChORENHKSBwZXIgZG9jdW1lbnQsIGF0
IHZhcmlvdXMgdG9wLWsKIGN1dG9mZiBsZXZlbHMuCgogTkRDRyBtZWFzdXJlcyB0aGUgcmFu
a2luZyBxdWFsaXR5LCBnaXZpbmcgaGlnaGVyIHJlbGV2YW5jZSB0byB0b3AKIHJlc3VsdHMu
CgogRXhhbXBsZSAodG9wLTMpOgogIFN1cHBvc2UgW1NhbXBsZVF1ZXJ5XVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxlUXVlcnldCiAgd2l0aCB0aHJlZSBy
ZXRyaWV2ZWQgZG9jdW1lbnRzIChEMSwgRDIsIEQzKSBhbmQgYmluYXJ5IHJlbGV2YW5jZQog
IGp1ZGdlbWVudHMgKDEgZm9yIHJlbGV2YW50LCAwIGZvciBub3QgcmVsZXZhbnQpOgoKICAg
UmV0cmlldmVkOiAgW0QzICgwKSwgRDEgKDEpLCBEMiAoMSldCiAgIElkZWFsOiAgICAgIFtE
MSAoMSksIEQyICgxKSwgRDMgKDApXQoKICAgQ2FsY3VsYXRlIE5EQ0dAMyBmb3IgZWFjaAog
ICBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5T
YW1wbGVRdWVyeV06CiAgICAqIERDR0AzOiAwL2xvZzIoMSsxKSArIDEvbG9nMigyKzEpICsg
MS9sb2cyKDMrMSkgPSAxLjEzCiAgICAqIElkZWFsIERDR0AzOiAxL2xvZzIoMSsxKSArIDEv
bG9nMigyKzEpICsgMC9sb2cyKDMrMSkgPSAxLjYzCiAgICAqIE5EQ0dAMzogMS4xMy8xLjYz
ID0gMC42OTMKCg0KBQQBAgIGEgTGAQINCg0KBQQBAgIBEgTGAQ4WCg0KBQQBAgIDEgTGARka
CskCCgQEAQIDEgTRAQIeGroCIFJlY2FsbCBwZXIgcGFnZSwgYXQgdmFyaW91cyB0b3AtayBj
dXRvZmYgbGV2ZWxzLgoKIFJlY2FsbCBpcyB0aGUgZnJhY3Rpb24gb2YgcmVsZXZhbnQgcGFn
ZXMgcmV0cmlldmVkIG91dCBvZiBhbGwgcmVsZXZhbnQKIHBhZ2VzLgoKIEV4YW1wbGUgKHRv
cC01KToKICAqIEZvciBhIHNpbmdsZQogIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLlNhbXBsZVF1ZXJ5XSwgaWYgMyBvdXQKICBvZiA1IHJl
bGV2YW50IHBhZ2VzIGFyZSByZXRyaWV2ZWQgaW4gdGhlIHRvcC01LCByZWNhbGxANSA9IDMv
NSA9IDAuNgoKDQoFBAECAwYSBNEBAg0KDQoFBAECAwESBNEBDhkKDQoFBAECAwMSBNEBHB0K
0QUKBAQBAgQSBOYBAhwawgUgTm9ybWFsaXplZCBkaXNjb3VudGVkIGN1bXVsYXRpdmUgZ2Fp
biAoTkRDRykgcGVyIHBhZ2UsIGF0IHZhcmlvdXMgdG9wLWsKIGN1dG9mZiBsZXZlbHMuCgog
TkRDRyBtZWFzdXJlcyB0aGUgcmFua2luZyBxdWFsaXR5LCBnaXZpbmcgaGlnaGVyIHJlbGV2
YW5jZSB0byB0b3AKIHJlc3VsdHMuCgogRXhhbXBsZSAodG9wLTMpOgogIFN1cHBvc2UgW1Nh
bXBsZVF1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2FtcGxl
UXVlcnldCiAgd2l0aCB0aHJlZSByZXRyaWV2ZWQgcGFnZXMgKFAxLCBQMiwgUDMpIGFuZCBi
aW5hcnkgcmVsZXZhbmNlIGp1ZGdlbWVudHMgKDEKICBmb3IgcmVsZXZhbnQsIDAgZm9yIG5v
dCByZWxldmFudCk6CgogICBSZXRyaWV2ZWQ6ICBbUDMgKDApLCBQMSAoMSksIFAyICgxKV0K
ICAgSWRlYWw6ICAgICAgW1AxICgxKSwgUDIgKDEpLCBQMyAoMCldCgogICBDYWxjdWxhdGUg
TkRDR0AzIGZvcgogICBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5TYW1wbGVRdWVyeV06CiAgICAqIERDR0AzOiAwL2xvZzIoMSsxKSArIDEv
bG9nMigyKzEpICsgMS9sb2cyKDMrMSkgPSAxLjEzCiAgICAqIElkZWFsIERDR0AzOiAxL2xv
ZzIoMSsxKSArIDEvbG9nMigyKzEpICsgMC9sb2cyKDMrMSkgPSAxLjYzCiAgICAqIE5EQ0dA
MzogMS4xMy8xLjYzID0gMC42OTMKCg0KBQQBAgQGEgTmAQINCg0KBQQBAgQBEgTmAQ4XCg0K
BQQBAgQDEgTmARobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation ===
    # Fields for Evaluation
    # Field: name Type: 9 ()
    # Field: evaluation_spec Type: 11 (.google.cloud.discoveryengine.v1alpha.Evaluation.EvaluationSpec)
    # Field: quality_metrics Type: 11 (.google.cloud.discoveryengine.v1alpha.QualityMetrics)
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1alpha.Evaluation.State)
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: error_samples Type: 11 (.google.rpc.Status)

# Enum: Evaluation::State
our $Evaluation_STATE_UNSPECIFIED = 0;
our $Evaluation_PENDING = 1;
our $Evaluation_RUNNING = 2;
our $Evaluation_SUCCEEDED = 3;
our $Evaluation_FAILED = 4;

# === Message: Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics ===
    # Fields for QualityMetrics
    # Field: doc_recall Type: 11 (.google.cloud.discoveryengine.v1alpha.QualityMetrics.TopkMetrics)
    # Field: doc_precision Type: 11 (.google.cloud.discoveryengine.v1alpha.QualityMetrics.TopkMetrics)
    # Field: doc_ndcg Type: 11 (.google.cloud.discoveryengine.v1alpha.QualityMetrics.TopkMetrics)
    # Field: page_recall Type: 11 (.google.cloud.discoveryengine.v1alpha.QualityMetrics.TopkMetrics)
    # Field: page_ndcg Type: 11 (.google.cloud.discoveryengine.v1alpha.QualityMetrics.TopkMetrics)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Evaluation - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/evaluation.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Evaluation;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation->new({
        name => $name,
        evaluation_spec => $evaluation_spec,
        quality_metrics => $quality_metrics,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/evaluation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation

An evaluation is a single execution (or run) of an evaluation process. It
encapsulates the state of the evaluation and the resulting data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The full resource name of the
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation], in the
format of
`projects/{project}/locations/{location}/evaluations/{evaluation}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->evaluation_spec() >> / C<< $msg->evaluation_spec($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec>)

Required. The specification of the evaluation.

=item * C<< $msg->quality_metrics() >> / C<< $msg->quality_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics>)

Output only. The metrics produced by the evaluation, averaged across all
[SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]s in the
[SampleQuerySet][google.cloud.discoveryengine.v1alpha.SampleQuerySet].

Only populated when the evaluation's state is SUCCEEDED.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::State>)

Output only. The state of the evaluation.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The error that occurred during evaluation. Only populated when
the evaluation's state is FAILED.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation] was created
at.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation] was completed
at.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. A sample of errors encountered while processing the request.

=back

=head3 Enum: Evaluation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics

Describes the metrics produced by the evaluation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->doc_recall() >> / C<< $msg->doc_recall($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics>)

Recall per document, at various top-k cutoff levels.

Recall is the fraction of relevant documents retrieved out of all
relevant documents.

Example (top-5):
 * For a single
 [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], If 3 out
 of 5 relevant documents are retrieved in the top-5, recall@5 = 3/5 = 0.6

=item * C<< $msg->doc_precision() >> / C<< $msg->doc_precision($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics>)

Precision per document, at various top-k cutoff levels.

Precision is the fraction of retrieved documents that are relevant.

Example (top-5):
 * For a single
 [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], If 4 out
 of 5 retrieved documents in the top-5 are relevant, precision@5 = 4/5 =
 0.8

=item * C<< $msg->doc_ndcg() >> / C<< $msg->doc_ndcg($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics>)

Normalized discounted cumulative gain (NDCG) per document, at various top-k
cutoff levels.

NDCG measures the ranking quality, giving higher relevance to top
results.

Example (top-3):
 Suppose [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]
 with three retrieved documents (D1, D2, D3) and binary relevance
 judgements (1 for relevant, 0 for not relevant):

  Retrieved:  [D3 (0), D1 (1), D2 (1)]
  Ideal:      [D1 (1), D2 (1), D3 (0)]

  Calculate NDCG@3 for each
  [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]:
   * DCG@3: 0/log2(1+1) + 1/log2(2+1) + 1/log2(3+1) = 1.13
   * Ideal DCG@3: 1/log2(1+1) + 1/log2(2+1) + 0/log2(3+1) = 1.63
   * NDCG@3: 1.13/1.63 = 0.693

=item * C<< $msg->page_recall() >> / C<< $msg->page_recall($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics>)

Recall per page, at various top-k cutoff levels.

Recall is the fraction of relevant pages retrieved out of all relevant
pages.

Example (top-5):
 * For a single
 [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery], if 3 out
 of 5 relevant pages are retrieved in the top-5, recall@5 = 3/5 = 0.6

=item * C<< $msg->page_ndcg() >> / C<< $msg->page_ndcg($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics>)

Normalized discounted cumulative gain (NDCG) per page, at various top-k
cutoff levels.

NDCG measures the ranking quality, giving higher relevance to top
results.

Example (top-3):
 Suppose [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]
 with three retrieved pages (P1, P2, P3) and binary relevance judgements (1
 for relevant, 0 for not relevant):

  Retrieved:  [P3 (0), P1 (1), P2 (1)]
  Ideal:      [P1 (1), P2 (1), P3 (0)]

  Calculate NDCG@3 for
  [SampleQuery][google.cloud.discoveryengine.v1alpha.SampleQuery]:
   * DCG@3: 0/log2(1+1) + 1/log2(2+1) + 1/log2(3+1) = 1.13
   * Ideal DCG@3: 1/log2(1+1) + 1/log2(2+1) + 0/log2(3+1) = 1.63
   * NDCG@3: 1.13/1.63 = 0.693

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
