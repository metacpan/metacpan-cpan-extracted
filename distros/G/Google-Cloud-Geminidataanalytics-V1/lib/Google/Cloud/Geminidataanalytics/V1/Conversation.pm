package Google::Cloud::Geminidataanalytics::V1::Conversation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MS9jb252ZXJzYXRpb24ucHJv
dG8SI2dvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIvIECgxDb252ZXJzYXRpb24SGgoE
bmFtZRgBIAEoCUIG4EEB4EEIUgRuYW1lEhsKBmFnZW50cxgCIAMoCUID4EECUgZhZ2VudHMS
QAoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmNyZWF0ZVRpbWUSRQoObGFzdF91c2VkX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSDGxhc3RVc2VkVGltZRJaCgZsYWJlbHMYCSADKAsyPS5nb29nbGUu
Y2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MS5Db252ZXJzYXRpb24uTGFiZWxzRW50cnlC
A+BBAVIGbGFiZWxzEhkKBXRpdGxlGAYgASgJQgPgQQFSBXRpdGxlEkcKB2ttc19rZXkYCiAB
KAlCKeBBAfpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5SABSBmttc0tl
eYgBARo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBOpgB6kGUAQovZ2VtaW5pZGF0YWFuYWx5dGljcy5nb29nbGVhcGlzLmNvbS9D
b252ZXJzYXRpb24SRHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259Kg1jb252ZXJzYXRpb25zMgxjb252ZXJzYXRp
b25CCgoIX2ttc19rZXkiogIKGUNyZWF0ZUNvbnZlcnNhdGlvblJlcXVlc3QSTwoGcGFyZW50
GAEgASgJQjfgQQL6QTESL2dlbWluaWRhdGFhbmFseXRpY3MuZ29vZ2xlYXBpcy5jb20vQ29u
dmVyc2F0aW9uUgZwYXJlbnQSLAoPY29udmVyc2F0aW9uX2lkGAIgASgJQgPgQQFSDmNvbnZl
cnNhdGlvbklkEloKDGNvbnZlcnNhdGlvbhgDIAEoCzIxLmdvb2dsZS5jbG91ZC5nZW1pbmlk
YXRhYW5hbHl0aWNzLnYxLkNvbnZlcnNhdGlvbkID4EECUgxjb252ZXJzYXRpb24SKgoKcmVx
dWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCLlAQoZVXBkYXRlQ29udmVy
c2F0aW9uUmVxdWVzdBJaCgxjb252ZXJzYXRpb24YASABKAsyMS5nb29nbGUuY2xvdWQuZ2Vt
aW5pZGF0YWFuYWx5dGljcy52MS5Db252ZXJzYXRpb25CA+BBAlIMY29udmVyc2F0aW9uEkAK
C3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1
cGRhdGVNYXNrEioKCnJlcXVlc3RfaWQYAyABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQi
ZQoWR2V0Q29udmVyc2F0aW9uUmVxdWVzdBJLCgRuYW1lGAEgASgJQjfgQQL6QTEKL2dlbWlu
aWRhdGFhbmFseXRpY3MuZ29vZ2xlYXBpcy5jb20vQ29udmVyc2F0aW9uUgRuYW1lIs4BChhM
aXN0Q29udmVyc2F0aW9uc1JlcXVlc3QSTwoGcGFyZW50GAEgASgJQjfgQQL6QTESL2dlbWlu
aWRhdGFhbmFseXRpY3MuZ29vZ2xlYXBpcy5jb20vQ29udmVyc2F0aW9uUgZwYXJlbnQSIAoJ
cGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BB
AVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIinAEKGUxpc3RDb252
ZXJzYXRpb25zUmVzcG9uc2USVwoNY29udmVyc2F0aW9ucxgBIAMoCzIxLmdvb2dsZS5jbG91
ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxLkNvbnZlcnNhdGlvblINY29udmVyc2F0aW9ucxIm
Cg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iaAoZRGVsZXRlQ29udmVy
c2F0aW9uUmVxdWVzdBJLCgRuYW1lGAEgASgJQjfgQQL6QTEKL2dlbWluaWRhdGFhbmFseXRp
Y3MuZ29vZ2xlYXBpcy5jb20vQ29udmVyc2F0aW9uUgRuYW1lQqEDCidjb20uZ29vZ2xlLmNs
b3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFCEUNvbnZlcnNhdGlvblByb3RvUAFaWWNsb3Vk
Lmdvb2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MS9nZW1pbmlkYXRhYW5h
bHl0aWNzcGI7Z2VtaW5pZGF0YWFuYWx5dGljc3BiqgIjR29vZ2xlLkNsb3VkLkdlbWluaURh
dGFBbmFseXRpY3MuVjHKAiNHb29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMeoC
Jkdvb2dsZTo6Q2xvdWQ6OkdlbWluaURhdGFBbmFseXRpY3M6OlYx6kGPAQohY2xvdWRrbXMu
Z29vZ2xlYXBpcy5jb20vQ3J5cHRvS2V5ElNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5
fSoKY3J5cHRvS2V5czIJY3J5cHRvS2V5SvU4CgcSBQ4A1wEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAJQoJCgID
AhIDFAAjCgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYAEAKCQoCCCUSAxgAQAoICgEI
EgMZAHAKCQoCCAsSAxkAcAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADIKCQoCCAgS
AxsAMgoICgEIEgMcAEAKCQoCCAESAxwAQAoICgEIEgMdAEAKCQoCCCkSAx0AQAoICgEIEgMe
AD8KCQoCCC0SAx4APwoJCgEIEgQfACQCCgwKBAidCAASBB8AJAIKKQoCBAASBCcAYgEaHSBN
ZXNzYWdlIGZvciBhIGNvbnZlcnNhdGlvbi4KCgoKAwQAARIDJwgUCgsKAwQABxIEKAItBAoN
CgUEAAedCBIEKAItBArSBAoEBAACABIEOwI+BBrDBCBPcHRpb25hbC4gSWRlbnRpZmllci4g
VGhlIHVuaXF1ZSByZXNvdXJjZSBuYW1lIG9mIGEgY29udmVyc2F0aW9uLiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbnZlcnNhdGlvbnMv
e2NvbnZlcnNhdGlvbl9pZH1gCiBge2NvbnZlcnNhdGlvbl9pZH1gIGlzIHRoZSByZXNvdXJj
ZSBpZCBhbmQgc2hvdWxkIGJlIDYzIGNoYXJhY3RlcnMgb3IgbGVzcwogYW5kIG11c3QgbWF0
Y2ggdGhlIGZvcm1hdCBkZXNjcmliZWQgaW4KIGh0dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTIy
I3Jlc291cmNlLWlkLXNlZ21lbnRzCgogRXhhbXBsZToKIGBwcm9qZWN0cy8xMjM0NTY3ODkw
L2xvY2F0aW9ucy9nbG9iYWwvY29udmVyc2F0aW9ucy9teS1jb252ZXJzYXRpb25gLgoKIEl0
IGlzIHJlY29tbWVuZGVkIHRvIHNraXAgc2V0dGluZyB0aGlzIGZpZWxkIGR1cmluZyBjb252
ZXJzYXRpb24gY3JlYXRpb24KIGFzIGl0IHdpbGwgYmUgaW5mZXJyZWQgYXV0b21hdGljYWxs
eSBhbmQgb3ZlcndyaXR0ZW4gd2l0aCB0aGUKIHtwYXJlbnR9L2NvbnZlcnNhdGlvbnMve2Nv
bnZlcnNhdGlvbl9pZH0uCgoMCgUEAAIABRIDOwIICgwKBQQAAgABEgM7CQ0KDAoFBAACAAMS
AzsQEQoNCgUEAAIACBIEOxI+AwoPCggEAAIACJwIABIDPAQqCg8KCAQAAgAInAgBEgM9BCwK
gAIKBAQAAgESA0QCRhryASBSZXF1aXJlZC4gQWdlbnQocykgaW4gdGhlIGNvbnZlcnNhdGlv
bi4KIEN1cnJlbnRseSwgb25seSBvbmUgYWdlbnQgaXMgc3VwcG9ydGVkLiBUaGlzIGZpZWxk
IGlzIHJlcGVhdGVkIHRvIGFsbG93CiBmb3IgZnV0dXJlIHN1cHBvcnQgb2YgbXVsdGlwbGUg
YWdlbnRzIGluIGEgY29udmVyc2F0aW9uLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFBZ2VudHMve2FnZW50fWAKCgwKBQQAAgEEEgNE
AgoKDAoFBAACAQUSA0QLEQoMCgUEAAIBARIDRBIYCgwKBQQAAgEDEgNEGxwKDAoFBAACAQgS
A0QdRQoPCggEAAIBCJwIABIDRB5ECjAKBAQAAgISBEcCSDIaIiBPdXRwdXQgb25seS4gQ3Jl
YXRpb24gdGltZXN0YW1wLgoKDAoFBAACAgYSA0cCGwoMCgUEAAICARIDRxwnCgwKBQQAAgID
EgNHKisKDAoFBAACAggSA0gGMQoPCggEAAICCJwIABIDSAcwCkUKBAQAAgMSBEsCTDIaNyBP
dXRwdXQgb25seS4gVGltZXN0YW1wIG9mIHRoZSBsYXN0IHVzZWQgY29udmVyc2F0aW9uLgoK
DAoFBAACAwYSA0sCGwoMCgUEAAIDARIDSxwqCgwKBQQAAgMDEgNLLS4KDAoFBAACAwgSA0wG
MQoPCggEAAIDCJwIABIDTAcwCrEBCgQEAAIEEgNRAkoaowEgT3B0aW9uYWwuIE9wZW4tZW5k
ZWQgYW5kIHVzZXItZGVmaW5lZCBsYWJlbHMgdGhhdCBjYW4gYmUgc2V0IGJ5IHRoZSBjbGll
bnQKIHRvIHRhZyBhIGNvbnZlcnNhdGlvbiAoZS5nLiB0byBmaWx0ZXIgY29udmVyc2F0aW9u
cyBmb3Igc3BlY2lmaWMKIHN1cmZhY2VzL3Byb2R1Y3RzKS4KCgwKBQQAAgQGEgNRAhUKDAoF
BAACBAESA1EWHAoMCgUEAAIEAxIDUR8gCgwKBQQAAgQIEgNRIUkKDwoIBAACBAicCAASA1Ei
SApOCgQEAAIFEgNUAjwaQSBPcHRpb25hbC4gVGhlIGRpc3BsYXkgbmFtZSBmb3IgdGhlIGNv
bnZlcnNhdGlvbiAobWF4IDYzIGNoYXJzKS4KCgwKBQQAAgUFEgNUAggKDAoFBAACBQESA1QJ
DgoMCgUEAAIFAxIDVBESCgwKBQQAAgUIEgNUEzsKDwoIBAACBQicCAASA1QUOgqlAgoEBAAC
BhIEXAJhBBqWAiBPcHRpb25hbC4gQ3VzdG9tZXIgbWFuYWdlZCBlbmNyeXB0aW9uIGtleSAo
Q01FSykgdG8gdXNlIGZvciBlbmNyeXB0aW5nIHRoZQogQ29udmVyc2F0aW9uIHJlc291cmNl
cy4gRW5jcnlwdGlvbiB3aWxsIGhhcHBlbiBhdCBUaXRhbiBsYXllciwgd2Ugd2lsbCBwYXNz
CiB0aGUgS01TIGtleSB0byBUaXRhbi4KCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdF9p
ZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nX25hbWV9L2NyeXB0
b0tleXMve2tleV9uYW1lfS4KCgwKBQQAAgYEEgNcAgoKDAoFBAACBgUSA1wLEQoMCgUEAAIG
ARIDXBIZCgwKBQQAAgYDEgNcHB4KDQoFBAACBggSBFwfYQMKDwoIBAACBgicCAASA10EKgoP
CgcEAAIGCJ8IEgReBGAFCjMKAgQBEgVlAIABARomIFJlcXVlc3QgZm9yIGNyZWF0aW5nIGEg
Y29udmVyc2F0aW9uLgoKCgoDBAEBEgNlCCEKeAoEBAECABIEaAJtBBpqIFJlcXVpcmVkLiBQ
YXJlbnQgdmFsdWUgZm9yIENyZWF0ZUNvbnZlcnNhdGlvblJlcXVlc3QuCiBGb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gCgoMCgUEAQIABRIDaAII
CgwKBQQBAgABEgNoCQ8KDAoFBAECAAMSA2gSEwoNCgUEAQIACBIEaBRtAwoPCggEAQIACJwI
ABIDaQQqCg8KBwQBAgAInwgSBGoEbAUK8AEKBAQBAgESA3MCRhriASBPcHRpb25hbC4gVGhl
IGNvbnZlcnNhdGlvbiBpZCBvZiB0aGUgY29udmVyc2F0aW9uIHRvIGNyZWF0ZS4KIE11c3Qg
YmUgdW5pcXVlIHdpdGhpbiB0aGUgcGFyZW50LgogVGhlIGFsbG93ZWQgZm9ybWF0IGlzOiBg
XlthLXpdKFthLXowLTktXXswLDYxfVthLXowLTldKT8kYC4KIElmIG5vdCBwcm92aWRlZCwg
dGhlIHNlcnZlciB3aWxsIGF1dG8tZ2VuZXJhdGUgYSB2YWx1ZSBmb3IgdGhlIGlkLgoKDAoF
BAECAQUSA3MCCAoMCgUEAQIBARIDcwkYCgwKBQQBAgEDEgNzGxwKDAoFBAECAQgSA3MdRQoP
CggEAQIBCJwIABIDcx5ECjQKBAQBAgISA3YCSRonIFJlcXVpcmVkLiBUaGUgY29udmVyc2F0
aW9uIHRvIGNyZWF0ZS4KCgwKBQQBAgIGEgN2Ag4KDAoFBAECAgESA3YPGwoMCgUEAQICAxID
dh4fCgwKBQQBAgIIEgN2IEgKDwoIBAECAgicCAASA3YhRwqrAgoEBAECAxIEfAJ/BBqcAiBP
cHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4g
U3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5
IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVx
dWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxs
CiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmly
c3QgcmVxdWVzdC4KCgwKBQQBAgMFEgN8AggKDAoFBAECAwESA3wJEwoMCgUEAQIDAxIDfBYX
Cg0KBQQBAgMIEgR8GH8DChIKCwQBAgMIzPH5igEBEgN9BCoKDwoIBAECAwicCAASA34EKgo0
CgIEAhIGgwEAmQEBGiYgUmVxdWVzdCBmb3IgdXBkYXRpbmcgYSBjb252ZXJzYXRpb24uCgoL
CgMEAgESBIMBCCEKNQoEBAICABIEhQECSRonIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgYmVp
bmcgdXBkYXRlZC4KCg0KBQQCAgAGEgSFAQIOCg0KBQQCAgABEgSFAQ8bCg0KBQQCAgADEgSF
AR4fCg0KBQQCAgAIEgSFASBIChAKCAQCAgAInAgAEgSFASFHCs8DCgQEAgIBEgaOAQKPAS8a
vgMgT3B0aW9uYWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMg
dG8gYmUgb3ZlcndyaXR0ZW4gaW4gdGhlCiBDb252ZXJzYXRpb24gcmVzb3VyY2UgYnkgdGhl
IHVwZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUg
cmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmll
bGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgdGhlCiB1
c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZpZWxkcyB3aXRoIG5vbi1k
ZWZhdWx0IHZhbHVlcwogcHJlc2VudCBpbiB0aGUgcmVxdWVzdCB3aWxsIGJlIG92ZXJ3cml0
dGVuLiBJZiBhIHdpbGRjYXJkIG1hc2sgaXMgcHJvdmlkZWQsCiBhbGwgZmllbGRzIHdpbGwg
YmUgb3ZlcndyaXR0ZW4uCgoNCgUEAgIBBhIEjgECGwoNCgUEAgIBARIEjgEcJwoNCgUEAgIB
AxIEjgEqKwoNCgUEAgIBCBIEjwEGLgoQCggEAgIBCJwIABIEjwEHLQqtAgoEBAICAhIGlQEC
mAEEGpwCIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJl
cXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11
c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3Jl
IHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2Vy
dmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNl
IHRoZSBmaXJzdCByZXF1ZXN0LgoKDQoFBAICAgUSBJUBAggKDQoFBAICAgESBJUBCRMKDQoF
BAICAgMSBJUBFhcKDwoFBAICAggSBpUBGJgBAwoTCgsEAgICCMzx+YoBARIElgEEKgoQCggE
AgICCJwIABIElwEEKgpXCgIEAxIGnAEApgEBGkkgUmVxdWVzdCBmb3IgZ2V0dGluZyBhIGNv
bnZlcnNhdGlvbiBiYXNlZCBvbiBwYXJlbnQgYW5kIGNvbnZlcnNhdGlvbiBpZC4KCgsKAwQD
ARIEnAEIHgqCAQoEBAMCABIGoAECpQEEGnIgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHJlc291
cmNlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jb252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259YAoKDQoFBAMCAAUSBKABAggKDQoFBAMC
AAESBKABCQ0KDQoFBAMCAAMSBKABEBEKDwoFBAMCAAgSBqABEqUBAwoQCggEAwIACJwIABIE
oQEEKgoRCgcEAwIACJ8IEgaiAQSkAQUKQgoCBAQSBqkBAMEBARo0IFJlcXVlc3QgZm9yIGxp
c3RpbmcgY29udmVyc2F0aW9ucyBiYXNlZCBvbiBwYXJlbnQuCgoLCgMEBAESBKkBCCAKeQoE
BAQCABIGrAECsQEEGmkgUmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3IgTGlzdENvbnZlcnNh
dGlvbnNSZXF1ZXN0LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259YAoKDQoFBAQCAAUSBKwBAggKDQoFBAQCAAESBKwBCQ8KDQoFBAQCAAMSBKwB
EhMKDwoFBAQCAAgSBqwBFLEBAwoQCggEBAIACJwIABIErQEEKgoRCgcEBAIACJ8IEgauAQSw
AQUK7QEKBAQEAgESBLcBAj8a3gEgT3B0aW9uYWwuIFJlcXVlc3RlZCBwYWdlIHNpemUuIFNl
cnZlciBtYXkgcmV0dXJuIGZld2VyIGl0ZW1zIHRoYW4KIHJlcXVlc3RlZC4gVGhlIG1heCBw
YWdlIHNpemUgaXMgYDEwMGAuIEFsbCBsYXJnZXIgcGFnZSBzaXplcyB3aWxsIGJlCiBjb2Vy
Y2VkIHRvIGAxMDBgLiBJZiB1bnNwZWNpZmllZCwgc2VydmVyIHdpbGwgcGljayBgNTBgIGFz
IGFuIGFwcHJvcHJpYXRlCiBkZWZhdWx0LgoKDQoFBAQCAQUSBLcBAgcKDQoFBAQCAQESBLcB
CBEKDQoFBAQCAQMSBLcBFBUKDQoFBAQCAQgSBLcBFj4KEAoIBAQCAQicCAASBLcBFz0KWQoE
BAQCAhIEugECQRpLIE9wdGlvbmFsLiBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiBy
ZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQEAgIFEgS6AQIICg0KBQQE
AgIBEgS6AQkTCg0KBQQEAgIDEgS6ARYXCg0KBQQEAgIIEgS6ARhAChAKCAQEAgIInAgAEgS6
ARk/CqABCgQEBAIDEgTAAQI9GpEBIE9wdGlvbmFsLiBSZXR1cm5lZCBjb252ZXJzYXRpb25z
IHdpbGwgbWF0Y2ggY3JpdGVyaWEgc3BlY2lmaWVkIHdpdGhpbiB0aGUKIGZpbHRlci4gTGlz
dENvbnZlcnNhdGlvbnMgYWxsb3dzIGZpbHRlcmluZyBieToKICAqIGFnZW50cwogICogbGFi
ZWxzCgoNCgUEBAIDBRIEwAECCAoNCgUEBAIDARIEwAEJDwoNCgUEBAIDAxIEwAESEwoNCgUE
BAIDCBIEwAEUPAoQCggEBAIDCJwIABIEwAEVOwo+CgIEBRIGxAEAygEBGjAgTWVzc2FnZSBm
b3IgcmVzcG9uc2UgdG8gbGlzdGluZyBjb252ZXJzYXRpb25zLgoKCwoDBAUBEgTEAQghCioK
BAQFAgASBMYBAioaHCBUaGUgbGlzdCBvZiBjb252ZXJzYXRpb25zLgoKDQoFBAUCAAQSBMYB
AgoKDQoFBAUCAAYSBMYBCxcKDQoFBAUCAAESBMYBGCUKDQoFBAUCAAMSBMYBKCkKTwoEBAUC
ARIEyQECHRpBIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNl
cnZlciBzaG91bGQgcmV0dXJuLgoKDQoFBAUCAQUSBMkBAggKDQoFBAUCAQESBMkBCRgKDQoF
BAUCAQMSBMkBGxwKWAoCBAYSBs0BANcBARpKIFJlcXVlc3QgZm9yIGRlbGV0aW5nIGEgY29u
dmVyc2F0aW9uIGJhc2VkIG9uIHBhcmVudCBhbmQgY29udmVyc2F0aW9uIGlkLgoKCwoDBAYB
EgTNAQghCoIBCgQEBgIAEgbRAQLWAQQaciBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3Vy
Y2UuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NvbnZlcnNhdGlvbnMve2NvbnZlcnNhdGlvbn1gCgoNCgUEBgIABRIE0QECCAoNCgUEBgIA
ARIE0QEJDQoNCgUEBgIAAxIE0QEQEQoPCgUEBgIACBIG0QES1gEDChAKCAQGAgAInAgAEgTS
AQQqChEKBwQGAgAInwgSBtMBBNUBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: agents Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_used_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.geminidataanalytics.v1.Conversation.LabelsEntry)
    # Field: title Type: 9 ()
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::CreateConversationRequest ===
    # Fields for CreateConversationRequest
    # Field: parent Type: 9 ()
    # Field: conversation_id Type: 9 ()
    # Field: conversation Type: 11 (.google.cloud.geminidataanalytics.v1.Conversation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::UpdateConversationRequest ===
    # Fields for UpdateConversationRequest
    # Field: conversation Type: 11 (.google.cloud.geminidataanalytics.v1.Conversation)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::GetConversationRequest ===
    # Fields for GetConversationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::ListConversationsRequest ===
    # Fields for ListConversationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::ListConversationsResponse ===
    # Fields for ListConversationsResponse
    # Field: conversations Type: 11 (.google.cloud.geminidataanalytics.v1.Conversation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Geminidataanalytics::V1::Conversation::DeleteConversationRequest ===
    # Fields for DeleteConversationRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::Conversation - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1::Conversation;

    my $msg = Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation->new({
        name => $name,
        agents => $agents,
        create_time => $create_time,
        last_used_time => $last_used_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation

Message for a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Identifier. The unique resource name of a conversation. Format:
`projects/{project}/locations/{location}/conversations/{conversation_id}`
`{conversation_id}` is the resource id and should be 63 characters or less
and must match the format described in
https://google.aip.dev/122#resource-id-segments

Example:
`projects/1234567890/locations/global/conversations/my-conversation`.

It is recommended to skip setting this field during conversation creation
as it will be inferred automatically and overwritten with the
{parent}/conversations/{conversation_id}.

=item * C<< $msg->agents() >> / C<< $msg->agents($value) >>

Type: C<String>

Required. Agent(s) in the conversation.
Currently, only one agent is supported. This field is repeated to allow
for future support of multiple agents in a conversation.
Format: `projects/{project}/locations/{location}/dataAgents/{agent}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation timestamp.

=item * C<< $msg->last_used_time() >> / C<< $msg->last_used_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the last used conversation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation::LabelsEntry>)

Optional. Open-ended and user-defined labels that can be set by the client
to tag a conversation (e.g. to filter conversations for specific
surfaces/products).

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The display name for the conversation (max 63 chars).

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Optional. Customer managed encryption key (CMEK) to use for encrypting the
Conversation resources. Encryption will happen at Titan layer, we will pass
the KMS key to Titan.

Format:
projects/{project_id}/locations/{location}/keyRings/{key_ring_name}/cryptoKeys/{key_name}.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::CreateConversationRequest

Request for creating a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for CreateConversationRequest.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->conversation_id() >> / C<< $msg->conversation_id($value) >>

Type: C<String>

Optional. The conversation id of the conversation to create.
Must be unique within the parent.
The allowed format is: `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$`.
If not provided, the server will auto-generate a value for the id.

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation>)

Required. The conversation to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::UpdateConversationRequest

Request for updating a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation>)

Required. The resource being updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Conversation resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields with non-default values
present in the request will be overwritten. If a wildcard mask is provided,
all fields will be overwritten.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::GetConversationRequest

Request for getting a conversation based on parent and conversation id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.
Format:
`projects/{project}/locations/{location}/conversations/{conversation}`

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::ListConversationsRequest

Request for listing conversations based on parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListConversationsRequest.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. The max page size is `100`. All larger page sizes will be
coerced to `100`. If unspecified, server will pick `50` as an appropriate
default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Returned conversations will match criteria specified within the
filter. ListConversations allows filtering by:
 * agents
 * labels

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::ListConversationsResponse

Message for response to listing conversations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversations() >> / C<< $msg->conversations($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1::Conversation::Conversation>)

The list of conversations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head2 Google::Cloud::Geminidataanalytics::V1::Conversation::DeleteConversationRequest

Request for deleting a conversation based on parent and conversation id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.
Format:
`projects/{project}/locations/{location}/conversations/{conversation}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
