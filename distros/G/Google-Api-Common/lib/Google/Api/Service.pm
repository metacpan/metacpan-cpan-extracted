package Google::Api::Service;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Auth };
    eval { require Google::Api::Backend };
    eval { require Google::Api::Billing };
    eval { require Google::Api::Client };
    eval { require Google::Api::Context };
    eval { require Google::Api::Control };
    eval { require Google::Api::Documentation };
    eval { require Google::Api::Endpoint };
    eval { require Google::Api::Http };
    eval { require Google::Api::Log };
    eval { require Google::Api::Logging };
    eval { require Google::Api::Metric };
    eval { require Google::Api::MonitoredResource };
    eval { require Google::Api::Monitoring };
    eval { require Google::Api::Quota };
    eval { require Google::Api::SourceInfo };
    eval { require Google::Api::SystemParameter };
    eval { require Google::Api::Usage };
    eval { require Google::Protobuf::Api };
    eval { require Google::Protobuf::Type };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Chhnb29nbGUvYXBpL3NlcnZpY2UucHJvdG8SCmdvb2dsZS5hcGkaFWdvb2dsZS9hcGkvYXV0
aC5wcm90bxoYZ29vZ2xlL2FwaS9iYWNrZW5kLnByb3RvGhhnb29nbGUvYXBpL2JpbGxpbmcu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGhhnb29nbGUvYXBpL2NvbnRleHQucHJv
dG8aGGdvb2dsZS9hcGkvY29udHJvbC5wcm90bxoeZ29vZ2xlL2FwaS9kb2N1bWVudGF0aW9u
LnByb3RvGhlnb29nbGUvYXBpL2VuZHBvaW50LnByb3RvGhVnb29nbGUvYXBpL2h0dHAucHJv
dG8aFGdvb2dsZS9hcGkvbG9nLnByb3RvGhhnb29nbGUvYXBpL2xvZ2dpbmcucHJvdG8aF2dv
b2dsZS9hcGkvbWV0cmljLnByb3RvGiNnb29nbGUvYXBpL21vbml0b3JlZF9yZXNvdXJjZS5w
cm90bxobZ29vZ2xlL2FwaS9tb25pdG9yaW5nLnByb3RvGhZnb29nbGUvYXBpL3F1b3RhLnBy
b3RvGhxnb29nbGUvYXBpL3NvdXJjZV9pbmZvLnByb3RvGiFnb29nbGUvYXBpL3N5c3RlbV9w
YXJhbWV0ZXIucHJvdG8aFmdvb2dsZS9hcGkvdXNhZ2UucHJvdG8aGWdvb2dsZS9wcm90b2J1
Zi9hcGkucHJvdG8aGmdvb2dsZS9wcm90b2J1Zi90eXBlLnByb3RvGh5nb29nbGUvcHJvdG9i
dWYvd3JhcHBlcnMucHJvdG8ijQoKB1NlcnZpY2USEgoEbmFtZRgBIAEoCVIEbmFtZRIUCgV0
aXRsZRgCIAEoCVIFdGl0bGUSLgoTcHJvZHVjZXJfcHJvamVjdF9pZBgWIAEoCVIRcHJvZHVj
ZXJQcm9qZWN0SWQSDgoCaWQYISABKAlSAmlkEigKBGFwaXMYAyADKAsyFC5nb29nbGUucHJv
dG9idWYuQXBpUgRhcGlzEisKBXR5cGVzGAQgAygLMhUuZ29vZ2xlLnByb3RvYnVmLlR5cGVS
BXR5cGVzEisKBWVudW1zGAUgAygLMhUuZ29vZ2xlLnByb3RvYnVmLkVudW1SBWVudW1zEj8K
DWRvY3VtZW50YXRpb24YBiABKAsyGS5nb29nbGUuYXBpLkRvY3VtZW50YXRpb25SDWRvY3Vt
ZW50YXRpb24SLQoHYmFja2VuZBgIIAEoCzITLmdvb2dsZS5hcGkuQmFja2VuZFIHYmFja2Vu
ZBIkCgRodHRwGAkgASgLMhAuZ29vZ2xlLmFwaS5IdHRwUgRodHRwEicKBXF1b3RhGAogASgL
MhEuZ29vZ2xlLmFwaS5RdW90YVIFcXVvdGESQgoOYXV0aGVudGljYXRpb24YCyABKAsyGi5n
b29nbGUuYXBpLkF1dGhlbnRpY2F0aW9uUg5hdXRoZW50aWNhdGlvbhItCgdjb250ZXh0GAwg
ASgLMhMuZ29vZ2xlLmFwaS5Db250ZXh0Ugdjb250ZXh0EicKBXVzYWdlGA8gASgLMhEuZ29v
Z2xlLmFwaS5Vc2FnZVIFdXNhZ2USMgoJZW5kcG9pbnRzGBIgAygLMhQuZ29vZ2xlLmFwaS5F
bmRwb2ludFIJZW5kcG9pbnRzEi0KB2NvbnRyb2wYFSABKAsyEy5nb29nbGUuYXBpLkNvbnRy
b2xSB2NvbnRyb2wSLQoEbG9ncxgXIAMoCzIZLmdvb2dsZS5hcGkuTG9nRGVzY3JpcHRvclIE
bG9ncxI2CgdtZXRyaWNzGBggAygLMhwuZ29vZ2xlLmFwaS5NZXRyaWNEZXNjcmlwdG9yUgdt
ZXRyaWNzElgKE21vbml0b3JlZF9yZXNvdXJjZXMYGSADKAsyJy5nb29nbGUuYXBpLk1vbml0
b3JlZFJlc291cmNlRGVzY3JpcHRvclISbW9uaXRvcmVkUmVzb3VyY2VzEi0KB2JpbGxpbmcY
GiABKAsyEy5nb29nbGUuYXBpLkJpbGxpbmdSB2JpbGxpbmcSLQoHbG9nZ2luZxgbIAEoCzIT
Lmdvb2dsZS5hcGkuTG9nZ2luZ1IHbG9nZ2luZxI2Cgptb25pdG9yaW5nGBwgASgLMhYuZ29v
Z2xlLmFwaS5Nb25pdG9yaW5nUgptb25pdG9yaW5nEkkKEXN5c3RlbV9wYXJhbWV0ZXJzGB0g
ASgLMhwuZ29vZ2xlLmFwaS5TeXN0ZW1QYXJhbWV0ZXJzUhBzeXN0ZW1QYXJhbWV0ZXJzEjcK
C3NvdXJjZV9pbmZvGCUgASgLMhYuZ29vZ2xlLmFwaS5Tb3VyY2VJbmZvUgpzb3VyY2VJbmZv
EjYKCnB1Ymxpc2hpbmcYLSABKAsyFi5nb29nbGUuYXBpLlB1Ymxpc2hpbmdSCnB1Ymxpc2hp
bmcSQwoOY29uZmlnX3ZlcnNpb24YFCABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFs
dWVSDWNvbmZpZ1ZlcnNpb25CbgoOY29tLmdvb2dsZS5hcGlCDFNlcnZpY2VQcm90b1ABWkVn
b29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FwaS9zZXJ2aWNlY29uZmln
O3NlcnZpY2Vjb25maWeiAgRHQVBJSvEyCgcSBQ4AvQEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAATCgkKAgMAEgMSAB8KCQoCAwESAxMAIgoJCgIDAhID
FAAiCgkKAgMDEgMVACEKCQoCAwQSAxYAIgoJCgIDBRIDFwAiCgkKAgMGEgMYACgKCQoCAwcS
AxkAIwoJCgIDCBIDGgAfCgkKAgMJEgMbAB4KCQoCAwoSAxwAIgoJCgIDCxIDHQAhCgkKAgMM
EgMeAC0KCQoCAw0SAx8AJQoJCgIDDhIDIAAgCgkKAgMPEgMhACYKCQoCAxASAyIAKwoJCgID
ERIDIwAgCgkKAgMSEgMkACMKCQoCAxMSAyUAJAoJCgIDFBIDJgAoCggKAQgSAygAXAoJCgII
CxIDKABcCggKAQgSAykAIgoJCgIIChIDKQAiCggKAQgSAyoALQoJCgIICBIDKgAtCggKAQgS
AysAJwoJCgIIARIDKwAnCggKAQgSAywAIgoJCgIIJBIDLAAiCswICgIEABIFTwC9AQEavggg
YFNlcnZpY2VgIGlzIHRoZSByb290IG9iamVjdCBvZiBHb29nbGUgQVBJIHNlcnZpY2UgY29u
ZmlndXJhdGlvbiAoc2VydmljZQogY29uZmlnKS4gSXQgZGVzY3JpYmVzIHRoZSBiYXNpYyBp
bmZvcm1hdGlvbiBhYm91dCBhIGxvZ2ljYWwgc2VydmljZSwKIHN1Y2ggYXMgdGhlIHNlcnZp
Y2UgbmFtZSBhbmQgdGhlIHVzZXItZmFjaW5nIHRpdGxlLCBhbmQgZGVsZWdhdGVzIG90aGVy
CiBhc3BlY3RzIHRvIHN1Yi1zZWN0aW9ucy4gRWFjaCBzdWItc2VjdGlvbiBpcyBlaXRoZXIg
YSBwcm90byBtZXNzYWdlIG9yIGEKIHJlcGVhdGVkIHByb3RvIG1lc3NhZ2UgdGhhdCBjb25m
aWd1cmVzIGEgc3BlY2lmaWMgYXNwZWN0LCBzdWNoIGFzIGF1dGguCiBGb3IgbW9yZSBpbmZv
cm1hdGlvbiwgc2VlIGVhY2ggcHJvdG8gbWVzc2FnZSBkZWZpbml0aW9uLgoKIEV4YW1wbGU6
CgogICAgIHR5cGU6IGdvb2dsZS5hcGkuU2VydmljZQogICAgIG5hbWU6IGNhbGVuZGFyLmdv
b2dsZWFwaXMuY29tCiAgICAgdGl0bGU6IEdvb2dsZSBDYWxlbmRhciBBUEkKICAgICBhcGlz
OgogICAgIC0gbmFtZTogZ29vZ2xlLmNhbGVuZGFyLnYzLkNhbGVuZGFyCgogICAgIHZpc2li
aWxpdHk6CiAgICAgICBydWxlczoKICAgICAgIC0gc2VsZWN0b3I6ICJnb29nbGUuY2FsZW5k
YXIudjMuKiIKICAgICAgICAgcmVzdHJpY3Rpb246IFBSRVZJRVcKICAgICBiYWNrZW5kOgog
ICAgICAgcnVsZXM6CiAgICAgICAtIHNlbGVjdG9yOiAiZ29vZ2xlLmNhbGVuZGFyLnYzLioi
CiAgICAgICAgIGFkZHJlc3M6IGNhbGVuZGFyLmV4YW1wbGUuY29tCgogICAgIGF1dGhlbnRp
Y2F0aW9uOgogICAgICAgcHJvdmlkZXJzOgogICAgICAgLSBpZDogZ29vZ2xlX2NhbGVuZGFy
X2F1dGgKICAgICAgICAgandrc191cmk6IGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL29h
dXRoMi92MS9jZXJ0cwogICAgICAgICBpc3N1ZXI6IGh0dHBzOi8vc2VjdXJldG9rZW4uZ29v
Z2xlLmNvbQogICAgICAgcnVsZXM6CiAgICAgICAtIHNlbGVjdG9yOiAiKiIKICAgICAgICAg
cmVxdWlyZW1lbnRzOgogICAgICAgICAgIHByb3ZpZGVyX2lkOiBnb29nbGVfY2FsZW5kYXJf
YXV0aAoKCgoDBAABEgNPCA8K9gEKBAQAAgASA1QCEhroASBUaGUgc2VydmljZSBuYW1lLCB3
aGljaCBpcyBhIEROUy1saWtlIGxvZ2ljYWwgaWRlbnRpZmllciBmb3IgdGhlCiBzZXJ2aWNl
LCBzdWNoIGFzIGBjYWxlbmRhci5nb29nbGVhcGlzLmNvbWAuIFRoZSBzZXJ2aWNlIG5hbWUK
IHR5cGljYWxseSBnb2VzIHRocm91Z2ggRE5TIHZlcmlmaWNhdGlvbiB0byBtYWtlIHN1cmUg
dGhlIG93bmVyCiBvZiB0aGUgc2VydmljZSBhbHNvIG93bnMgdGhlIEROUyBuYW1lLgoKDAoF
BAACAAUSA1QCCAoMCgUEAAIAARIDVAkNCgwKBQQAAgADEgNUEBEKZQoEBAACARIDWAITGlgg
VGhlIHByb2R1Y3QgdGl0bGUgZm9yIHRoaXMgc2VydmljZSwgaXQgaXMgdGhlIG5hbWUgZGlz
cGxheWVkIGluIEdvb2dsZQogQ2xvdWQgQ29uc29sZS4KCgwKBQQAAgEFEgNYAggKDAoFBAAC
AQESA1gJDgoMCgUEAAIBAxIDWBESCjkKBAQAAgISA1sCIhosIFRoZSBHb29nbGUgcHJvamVj
dCB0aGF0IG93bnMgdGhpcyBzZXJ2aWNlLgoKDAoFBAACAgUSA1sCCAoMCgUEAAICARIDWwkc
CgwKBQQAAgIDEgNbHyEKnwIKBAQAAgMSA2ECERqRAiBBIHVuaXF1ZSBJRCBmb3IgYSBzcGVj
aWZpYyBpbnN0YW5jZSBvZiB0aGlzIG1lc3NhZ2UsIHR5cGljYWxseSBhc3NpZ25lZAogYnkg
dGhlIGNsaWVudCBmb3IgdHJhY2tpbmcgcHVycG9zZS4gTXVzdCBiZSBubyBsb25nZXIgdGhh
biA2MyBjaGFyYWN0ZXJzCiBhbmQgb25seSBsb3dlciBjYXNlIGxldHRlcnMsIGRpZ2l0cywg
Jy4nLCAnXycgYW5kICctJyBhcmUgYWxsb3dlZC4gSWYKIGVtcHR5LCB0aGUgc2VydmVyIG1h
eSBjaG9vc2UgdG8gZ2VuZXJhdGUgb25lIGluc3RlYWQuCgoMCgUEAAIDBRIDYQIICgwKBQQA
AgMBEgNhCQsKDAoFBAACAwMSA2EOEAqCAwoEBAACBBIDaAIoGvQCIEEgbGlzdCBvZiBBUEkg
aW50ZXJmYWNlcyBleHBvcnRlZCBieSB0aGlzIHNlcnZpY2UuIE9ubHkgdGhlIGBuYW1lYCBm
aWVsZAogb2YgdGhlIFtnb29nbGUucHJvdG9idWYuQXBpXVtnb29nbGUucHJvdG9idWYuQXBp
XSBuZWVkcyB0byBiZSBwcm92aWRlZCBieQogdGhlIGNvbmZpZ3VyYXRpb24gYXV0aG9yLCBh
cyB0aGUgcmVtYWluaW5nIGZpZWxkcyB3aWxsIGJlIGRlcml2ZWQgZnJvbSB0aGUKIElETCBk
dXJpbmcgdGhlIG5vcm1hbGl6YXRpb24gcHJvY2Vzcy4gSXQgaXMgYW4gZXJyb3IgdG8gc3Bl
Y2lmeSBhbiBBUEkKIGludGVyZmFjZSBoZXJlIHdoaWNoIGNhbm5vdCBiZSByZXNvbHZlZCBh
Z2FpbnN0IHRoZSBhc3NvY2lhdGVkIElETCBmaWxlcy4KCgwKBQQAAgQEEgNoAgoKDAoFBAAC
BAYSA2gLHgoMCgUEAAIEARIDaB8jCgwKBQQAAgQDEgNoJicKiQMKBAQAAgUSA3ICKhr7AiBB
IGxpc3Qgb2YgYWxsIHByb3RvIG1lc3NhZ2UgdHlwZXMgaW5jbHVkZWQgaW4gdGhpcyBBUEkg
c2VydmljZS4KIFR5cGVzIHJlZmVyZW5jZWQgZGlyZWN0bHkgb3IgaW5kaXJlY3RseSBieSB0
aGUgYGFwaXNgIGFyZSBhdXRvbWF0aWNhbGx5CiBpbmNsdWRlZC4gIE1lc3NhZ2VzIHdoaWNo
IGFyZSBub3QgcmVmZXJlbmNlZCBidXQgc2hhbGwgYmUgaW5jbHVkZWQsIHN1Y2ggYXMKIHR5
cGVzIHVzZWQgYnkgdGhlIGBnb29nbGUucHJvdG9idWYuQW55YCB0eXBlLCBzaG91bGQgYmUg
bGlzdGVkIGhlcmUgYnkKIG5hbWUgYnkgdGhlIGNvbmZpZ3VyYXRpb24gYXV0aG9yLiBFeGFt
cGxlOgoKICAgICB0eXBlczoKICAgICAtIG5hbWU6IGdvb2dsZS5wcm90b2J1Zi5JbnQzMgoK
DAoFBAACBQQSA3ICCgoMCgUEAAIFBhIDcgsfCgwKBQQAAgUBEgNyICUKDAoFBAACBQMSA3Io
KQrLAgoEBAACBhIDewIqGr0CIEEgbGlzdCBvZiBhbGwgZW51bSB0eXBlcyBpbmNsdWRlZCBp
biB0aGlzIEFQSSBzZXJ2aWNlLiAgRW51bXMgcmVmZXJlbmNlZAogZGlyZWN0bHkgb3IgaW5k
aXJlY3RseSBieSB0aGUgYGFwaXNgIGFyZSBhdXRvbWF0aWNhbGx5IGluY2x1ZGVkLiAgRW51
bXMKIHdoaWNoIGFyZSBub3QgcmVmZXJlbmNlZCBidXQgc2hhbGwgYmUgaW5jbHVkZWQgc2hv
dWxkIGJlIGxpc3RlZCBoZXJlIGJ5CiBuYW1lIGJ5IHRoZSBjb25maWd1cmF0aW9uIGF1dGhv
ci4gRXhhbXBsZToKCiAgICAgZW51bXM6CiAgICAgLSBuYW1lOiBnb29nbGUuc29tZWFwaS52
MS5Tb21lRW51bQoKDAoFBAACBgQSA3sCCgoMCgUEAAIGBhIDewsfCgwKBQQAAgYBEgN7ICUK
DAoFBAACBgMSA3soKQosCgQEAAIHEgN+AiIaHyBBZGRpdGlvbmFsIEFQSSBkb2N1bWVudGF0
aW9uLgoKDAoFBAACBwYSA34CDwoMCgUEAAIHARIDfhAdCgwKBQQAAgcDEgN+ICEKKgoEBAAC
CBIEgQECFhocIEFQSSBiYWNrZW5kIGNvbmZpZ3VyYXRpb24uCgoNCgUEAAIIBhIEgQECCQoN
CgUEAAIIARIEgQEKEQoNCgUEAAIIAxIEgQEUFQojCgQEAAIJEgSEAQIQGhUgSFRUUCBjb25m
aWd1cmF0aW9uLgoKDQoFBAACCQYSBIQBAgYKDQoFBAACCQESBIQBBwsKDQoFBAACCQMSBIQB
Dg8KJAoEBAACChIEhwECExoWIFF1b3RhIGNvbmZpZ3VyYXRpb24uCgoNCgUEAAIKBhIEhwEC
BwoNCgUEAAIKARIEhwEIDQoNCgUEAAIKAxIEhwEQEgojCgQEAAILEgSKAQIlGhUgQXV0aCBj
b25maWd1cmF0aW9uLgoKDQoFBAACCwYSBIoBAhAKDQoFBAACCwESBIoBER8KDQoFBAACCwMS
BIoBIiQKJgoEBAACDBIEjQECFxoYIENvbnRleHQgY29uZmlndXJhdGlvbi4KCg0KBQQAAgwG
EgSNAQIJCg0KBQQAAgwBEgSNAQoRCg0KBQQAAgwDEgSNARQWCkAKBAQAAg0SBJABAhMaMiBD
b25maWd1cmF0aW9uIGNvbnRyb2xsaW5nIHVzYWdlIG9mIHRoaXMgc2VydmljZS4KCg0KBQQA
Ag0GEgSQAQIHCg0KBQQAAg0BEgSQAQgNCg0KBQQAAg0DEgSQARASCrUBCgQEAAIOEgSVAQIj
GqYBIENvbmZpZ3VyYXRpb24gZm9yIG5ldHdvcmsgZW5kcG9pbnRzLiAgSWYgdGhpcyBpcyBl
bXB0eSwgdGhlbiBhbiBlbmRwb2ludAogd2l0aCB0aGUgc2FtZSBuYW1lIGFzIHRoZSBzZXJ2
aWNlIGlzIGF1dG9tYXRpY2FsbHkgZ2VuZXJhdGVkIHRvIHNlcnZpY2UgYWxsCiBkZWZpbmVk
IEFQSXMuCgoNCgUEAAIOBBIElQECCgoNCgUEAAIOBhIElQELEwoNCgUEAAIOARIElQEUHQoN
CgUEAAIOAxIElQEgIgo8CgQEAAIPEgSYAQIXGi4gQ29uZmlndXJhdGlvbiBmb3IgdGhlIHNl
cnZpY2UgY29udHJvbCBwbGFuZS4KCg0KBQQAAg8GEgSYAQIJCg0KBQQAAg8BEgSYAQoRCg0K
BQQAAg8DEgSYARQWCjYKBAQAAhASBJsBAiMaKCBEZWZpbmVzIHRoZSBsb2dzIHVzZWQgYnkg
dGhpcyBzZXJ2aWNlLgoKDQoFBAACEAQSBJsBAgoKDQoFBAACEAYSBJsBCxgKDQoFBAACEAES
BJsBGR0KDQoFBAACEAMSBJsBICIKOQoEBAACERIEngECKRorIERlZmluZXMgdGhlIG1ldHJp
Y3MgdXNlZCBieSB0aGlzIHNlcnZpY2UuCgoNCgUEAAIRBBIEngECCgoNCgUEAAIRBhIEngEL
GwoNCgUEAAIRARIEngEcIwoNCgUEAAIRAxIEngEmKAqaAQoEBAACEhIEogECQBqLASBEZWZp
bmVzIHRoZSBtb25pdG9yZWQgcmVzb3VyY2VzIHVzZWQgYnkgdGhpcyBzZXJ2aWNlLiBUaGlz
IGlzIHJlcXVpcmVkCiBieSB0aGUgYFNlcnZpY2UubW9uaXRvcmluZ2AgYW5kIGBTZXJ2aWNl
LmxvZ2dpbmdgIGNvbmZpZ3VyYXRpb25zLgoKDQoFBAACEgQSBKIBAgoKDQoFBAACEgYSBKIB
CyYKDQoFBAACEgESBKIBJzoKDQoFBAACEgMSBKIBPT8KJgoEBAACExIEpQECFxoYIEJpbGxp
bmcgY29uZmlndXJhdGlvbi4KCg0KBQQAAhMGEgSlAQIJCg0KBQQAAhMBEgSlAQoRCg0KBQQA
AhMDEgSlARQWCiYKBAQAAhQSBKgBAhcaGCBMb2dnaW5nIGNvbmZpZ3VyYXRpb24uCgoNCgUE
AAIUBhIEqAECCQoNCgUEAAIUARIEqAEKEQoNCgUEAAIUAxIEqAEUFgopCgQEAAIVEgSrAQId
GhsgTW9uaXRvcmluZyBjb25maWd1cmF0aW9uLgoKDQoFBAACFQYSBKsBAgwKDQoFBAACFQES
BKsBDRcKDQoFBAACFQMSBKsBGhwKLwoEBAACFhIErgECKhohIFN5c3RlbSBwYXJhbWV0ZXIg
Y29uZmlndXJhdGlvbi4KCg0KBQQAAhYGEgSuAQISCg0KBQQAAhYBEgSuARMkCg0KBQQAAhYD
EgSuAScpClgKBAQAAhcSBLEBAh4aSiBPdXRwdXQgb25seS4gVGhlIHNvdXJjZSBpbmZvcm1h
dGlvbiBmb3IgdGhpcyBjb25maWd1cmF0aW9uIGlmIGF2YWlsYWJsZS4KCg0KBQQAAhcGEgSx
AQIMCg0KBQQAAhcBEgSxAQ0YCg0KBQQAAhcDEgSxARsdCqsBCgQEAAIYEgS2AQIdGpwBIFNl
dHRpbmdzIGZvciBbR29vZ2xlIENsb3VkIENsaWVudAogbGlicmFyaWVzXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vYXBpcy9kb2NzL2Nsb3VkLWNsaWVudC1saWJyYXJpZXMpCiBnZW5l
cmF0ZWQgZnJvbSBBUElzIGRlZmluZWQgYXMgcHJvdG9jb2wgYnVmZmVycy4KCg0KBQQAAhgG
EgS2AQIMCg0KBQQAAhgBEgS2AQ0XCg0KBQQAAhgDEgS2ARocCocBCgQEAAIZEgS8AQIyGnkg
T2Jzb2xldGUuIERvIG5vdCB1c2UuCgogVGhpcyBmaWVsZCBoYXMgbm8gc2VtYW50aWMgbWVh
bmluZy4gVGhlIHNlcnZpY2UgY29uZmlnIGNvbXBpbGVyIGFsd2F5cwogc2V0cyB0aGlzIGZp
ZWxkIHRvIGAzYC4KCg0KBQQAAhkGEgS8AQIdCg0KBQQAAhkBEgS8AR4sCg0KBQQAAhkDEgS8
AS8xYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Api::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: title Type: 9 ()
    # Field: producer_project_id Type: 9 ()
    # Field: id Type: 9 ()
    # Field: apis Type: 11 (.google.protobuf.Api)
    # Field: types Type: 11 (.google.protobuf.Type)
    # Field: enums Type: 11 (.google.protobuf.Enum)
    # Field: documentation Type: 11 (.google.api.Documentation)
    # Field: backend Type: 11 (.google.api.Backend)
    # Field: http Type: 11 (.google.api.Http)
    # Field: quota Type: 11 (.google.api.Quota)
    # Field: authentication Type: 11 (.google.api.Authentication)
    # Field: context Type: 11 (.google.api.Context)
    # Field: usage Type: 11 (.google.api.Usage)
    # Field: endpoints Type: 11 (.google.api.Endpoint)
    # Field: control Type: 11 (.google.api.Control)
    # Field: logs Type: 11 (.google.api.LogDescriptor)
    # Field: metrics Type: 11 (.google.api.MetricDescriptor)
    # Field: monitored_resources Type: 11 (.google.api.MonitoredResourceDescriptor)
    # Field: billing Type: 11 (.google.api.Billing)
    # Field: logging Type: 11 (.google.api.Logging)
    # Field: monitoring Type: 11 (.google.api.Monitoring)
    # Field: system_parameters Type: 11 (.google.api.SystemParameters)
    # Field: source_info Type: 11 (.google.api.SourceInfo)
    # Field: publishing Type: 11 (.google.api.Publishing)
    # Field: config_version Type: 11 (.google.protobuf.UInt32Value)

=pod

=head1 NAME

Google::Api::Service::Service - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Api::Service;

    my $msg = Google::Api::Service::Service->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<title>

Type: String

=item * B<producer_project_id>

Type: String

=item * B<id>

Type: String

=item * B<apis>

Type: Message (.google.protobuf.Api)

=item * B<types>

Type: Message (.google.protobuf.Type)

=item * B<enums>

Type: Message (.google.protobuf.Enum)

=item * B<documentation>

Type: Message (.google.api.Documentation)

=item * B<backend>

Type: Message (.google.api.Backend)

=item * B<http>

Type: Message (.google.api.Http)

=item * B<quota>

Type: Message (.google.api.Quota)

=item * B<authentication>

Type: Message (.google.api.Authentication)

=item * B<context>

Type: Message (.google.api.Context)

=item * B<usage>

Type: Message (.google.api.Usage)

=item * B<endpoints>

Type: Message (.google.api.Endpoint)

=item * B<control>

Type: Message (.google.api.Control)

=item * B<logs>

Type: Message (.google.api.LogDescriptor)

=item * B<metrics>

Type: Message (.google.api.MetricDescriptor)

=item * B<monitored_resources>

Type: Message (.google.api.MonitoredResourceDescriptor)

=item * B<billing>

Type: Message (.google.api.Billing)

=item * B<logging>

Type: Message (.google.api.Logging)

=item * B<monitoring>

Type: Message (.google.api.Monitoring)

=item * B<system_parameters>

Type: Message (.google.api.SystemParameters)

=item * B<source_info>

Type: Message (.google.api.SourceInfo)

=item * B<publishing>

Type: Message (.google.api.Publishing)

=item * B<config_version>

Type: Message (.google.protobuf.UInt32Value)

=back

=cut

1;
