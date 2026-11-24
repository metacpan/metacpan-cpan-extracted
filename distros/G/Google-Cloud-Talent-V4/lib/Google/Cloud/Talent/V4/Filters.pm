package Google::Cloud::Talent::V4::Filters;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Talent::V4::Common };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Type::Latlng };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2ZpbHRlcnMucHJvdG8SFmdvb2dsZS5jbG91ZC50
YWxlbnQudjQaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aI2dvb2dsZS9jbG91
ZC90YWxlbnQvdjQvY29tbW9uLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJv
dG8aGGdvb2dsZS90eXBlL2xhdGxuZy5wcm90bxobZ29vZ2xlL3R5cGUvdGltZW9mZGF5LnBy
b3RvIskGCghKb2JRdWVyeRIUCgVxdWVyeRgBIAEoCVIFcXVlcnkSLgoTcXVlcnlfbGFuZ3Vh
Z2VfY29kZRgOIAEoCVIRcXVlcnlMYW5ndWFnZUNvZGUSHAoJY29tcGFuaWVzGAIgAygJUglj
b21wYW5pZXMSUQoQbG9jYXRpb25fZmlsdGVycxgDIAMoCzImLmdvb2dsZS5jbG91ZC50YWxl
bnQudjQuTG9jYXRpb25GaWx0ZXJSD2xvY2F0aW9uRmlsdGVycxJKCg5qb2JfY2F0ZWdvcmll
cxgEIAMoDjIjLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iQ2F0ZWdvcnlSDWpvYkNhdGVn
b3JpZXMSTAoOY29tbXV0ZV9maWx0ZXIYBSABKAsyJS5nb29nbGUuY2xvdWQudGFsZW50LnY0
LkNvbW11dGVGaWx0ZXJSDWNvbW11dGVGaWx0ZXISMgoVY29tcGFueV9kaXNwbGF5X25hbWVz
GAYgAygJUhNjb21wYW55RGlzcGxheU5hbWVzElsKE2NvbXBlbnNhdGlvbl9maWx0ZXIYByAB
KAsyKi5nb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBlbnNhdGlvbkZpbHRlclISY29tcGVu
c2F0aW9uRmlsdGVyEjYKF2N1c3RvbV9hdHRyaWJ1dGVfZmlsdGVyGAggASgJUhVjdXN0b21B
dHRyaWJ1dGVGaWx0ZXISLgoTZGlzYWJsZV9zcGVsbF9jaGVjaxgJIAEoCFIRZGlzYWJsZVNw
ZWxsQ2hlY2sSUQoQZW1wbG95bWVudF90eXBlcxgKIAMoDjImLmdvb2dsZS5jbG91ZC50YWxl
bnQudjQuRW1wbG95bWVudFR5cGVSD2VtcGxveW1lbnRUeXBlcxIlCg5sYW5ndWFnZV9jb2Rl
cxgLIAMoCVINbGFuZ3VhZ2VDb2RlcxJUChJwdWJsaXNoX3RpbWVfcmFuZ2UYDCABKAsyJi5n
b29nbGUuY2xvdWQudGFsZW50LnY0LlRpbWVzdGFtcFJhbmdlUhBwdWJsaXNoVGltZVJhbmdl
EiMKDWV4Y2x1ZGVkX2pvYnMYDSADKAlSDGV4Y2x1ZGVkSm9icyKyAwoOTG9jYXRpb25GaWx0
ZXISGAoHYWRkcmVzcxgBIAEoCVIHYWRkcmVzcxIfCgtyZWdpb25fY29kZRgCIAEoCVIKcmVn
aW9uQ29kZRIsCgdsYXRfbG5nGAMgASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5nUgZsYXRMbmcS
KgoRZGlzdGFuY2VfaW5fbWlsZXMYBCABKAFSD2Rpc3RhbmNlSW5NaWxlcxJzChZ0ZWxlY29t
bXV0ZV9wcmVmZXJlbmNlGAUgASgOMjwuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Mb2NhdGlv
bkZpbHRlci5UZWxlY29tbXV0ZVByZWZlcmVuY2VSFXRlbGVjb21tdXRlUHJlZmVyZW5jZSKV
AQoVVGVsZWNvbW11dGVQcmVmZXJlbmNlEiYKIlRFTEVDT01NVVRFX1BSRUZFUkVOQ0VfVU5T
UEVDSUZJRUQQABIcChRURUxFQ09NTVVURV9FWENMVURFRBABGgIIARIXChNURUxFQ09NTVVU
RV9BTExPV0VEEAISHQoZVEVMRUNPTU1VVEVfSk9CU19FWENMVURFRBADIvwDChJDb21wZW5z
YXRpb25GaWx0ZXISTgoEdHlwZRgBIAEoDjI1Lmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29t
cGVuc2F0aW9uRmlsdGVyLkZpbHRlclR5cGVCA+BBAlIEdHlwZRJUCgV1bml0cxgCIAMoDjI5
Lmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGVuc2F0aW9uSW5mby5Db21wZW5zYXRpb25V
bml0QgPgQQJSBXVuaXRzElAKBXJhbmdlGAMgASgLMjouZ29vZ2xlLmNsb3VkLnRhbGVudC52
NC5Db21wZW5zYXRpb25JbmZvLkNvbXBlbnNhdGlvblJhbmdlUgVyYW5nZRJlCjBpbmNsdWRl
X2pvYnNfd2l0aF91bnNwZWNpZmllZF9jb21wZW5zYXRpb25fcmFuZ2UYBCABKAhSK2luY2x1
ZGVKb2JzV2l0aFVuc3BlY2lmaWVkQ29tcGVuc2F0aW9uUmFuZ2UihgEKCkZpbHRlclR5cGUS
GwoXRklMVEVSX1RZUEVfVU5TUEVDSUZJRUQQABINCglVTklUX09OTFkQARITCg9VTklUX0FO
RF9BTU9VTlQQAhIaChZBTk5VQUxJWkVEX0JBU0VfQU1PVU5UEAMSGwoXQU5OVUFMSVpFRF9U
T1RBTF9BTU9VTlQQBCKnBAoNQ29tbXV0ZUZpbHRlchJRCg5jb21tdXRlX21ldGhvZBgBIAEo
DjIlLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tbXV0ZU1ldGhvZEID4EECUg1jb21tdXRl
TWV0aG9kEkUKEXN0YXJ0X2Nvb3JkaW5hdGVzGAIgASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5n
QgPgQQJSEHN0YXJ0Q29vcmRpbmF0ZXMSRwoPdHJhdmVsX2R1cmF0aW9uGAMgASgLMhkuZ29v
Z2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQJSDnRyYXZlbER1cmF0aW9uEjoKGWFsbG93X2lt
cHJlY2lzZV9hZGRyZXNzZXMYBCABKAhSF2FsbG93SW1wcmVjaXNlQWRkcmVzc2VzElYKDHJv
YWRfdHJhZmZpYxgFIAEoDjIxLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tbXV0ZUZpbHRl
ci5Sb2FkVHJhZmZpY0gAUgtyb2FkVHJhZmZpYxI/Cg5kZXBhcnR1cmVfdGltZRgGIAEoCzIW
Lmdvb2dsZS50eXBlLlRpbWVPZkRheUgAUg1kZXBhcnR1cmVUaW1lIkwKC1JvYWRUcmFmZmlj
EhwKGFJPQURfVFJBRkZJQ19VTlNQRUNJRklFRBAAEhAKDFRSQUZGSUNfRlJFRRABEg0KCUJV
U1lfSE9VUhACQhAKDnRyYWZmaWNfb3B0aW9uQmYKGmNvbS5nb29nbGUuY2xvdWQudGFsZW50
LnY0QgxGaWx0ZXJzUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBpdjQv
dGFsZW50cGI7dGFsZW50cGKiAgNDVFNKxHsKBxIFDgCAAwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAtCgkKAgMC
EgMUACgKCQoCAwMSAxUAIgoJCgIDBBIDFgAlCggKAQgSAxgASQoJCgIICxIDGABJCggKAQgS
AxkAIgoJCgIIChIDGQAiCggKAQgSAxoALQoJCgIICBIDGgAtCggKAQgSAxsAMwoJCgIIARID
GwAzCggKAQgSAxwAIQoJCgIIJBIDHAAhCjwKAgQAEgUfAMcBARovIFRoZSBxdWVyeSByZXF1
aXJlZCB0byBwZXJmb3JtIGEgc2VhcmNoIHF1ZXJ5LgoKCgoDBAABEgMfCBAKmgEKBAQAAgAS
AyQCExqMASBUaGUgcXVlcnkgc3RyaW5nIHRoYXQgbWF0Y2hlcyBhZ2FpbnN0IHRoZSBqb2Ig
dGl0bGUsIGRlc2NyaXB0aW9uLCBhbmQKIGxvY2F0aW9uIGZpZWxkcy4KCiBUaGUgbWF4aW11
bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDI1NS4KCgwKBQQAAgAFEgMkAggK
DAoFBAACAAESAyQJDgoMCgUEAAIAAxIDJBESCrMDCgQEAAIBEgMvAiIapQMgVGhlIGxhbmd1
YWdlIGNvZGUgb2YgW3F1ZXJ5XVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYlF1ZXJ5LnF1
ZXJ5XS4gRm9yCiBleGFtcGxlLCAiZW4tVVMiLiBUaGlzIGZpZWxkIGhlbHBzIHRvIGJldHRl
ciBpbnRlcnByZXQgdGhlIHF1ZXJ5LgoKIElmIGEgdmFsdWUgaXNuJ3Qgc3BlY2lmaWVkLCB0
aGUgcXVlcnkgbGFuZ3VhZ2UgY29kZSBpcyBhdXRvbWF0aWNhbGx5CiBkZXRlY3RlZCwgd2hp
Y2ggbWF5IG5vdCBiZSBhY2N1cmF0ZS4KCiBMYW5ndWFnZSBjb2RlIHNob3VsZCBiZSBpbiBC
Q1AtNDcgZm9ybWF0LCBzdWNoIGFzICJlbi1VUyIgb3IgInNyLUxhdG4iLgogRm9yIG1vcmUg
aW5mb3JtYXRpb24sIHNlZQogW1RhZ3MgZm9yIElkZW50aWZ5aW5nIExhbmd1YWdlc10oaHR0
cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL2JjcDQ3KS4KCgwKBQQAAgEFEgMvAggKDAoFBAAC
AQESAy8JHAoMCgUEAAIBAxIDLx8hCqgDCgQEAAICEgM+AiAamgMgVGhpcyBmaWx0ZXIgc3Bl
Y2lmaWVzIHRoZSBjb21wYW55IGVudGl0aWVzIHRvIHNlYXJjaCBhZ2FpbnN0LgoKIElmIGEg
dmFsdWUgaXNuJ3Qgc3BlY2lmaWVkLCBqb2JzIGFyZSBzZWFyY2hlZCBmb3IgYWdhaW5zdCBh
bGwKIGNvbXBhbmllcy4KCiBJZiBtdWx0aXBsZSB2YWx1ZXMgYXJlIHNwZWNpZmllZCwgam9i
cyBhcmUgc2VhcmNoZWQgYWdhaW5zdCB0aGUKIGNvbXBhbmllcyBzcGVjaWZpZWQuCgogVGhl
IGZvcm1hdCBpcwogInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9
L2NvbXBhbmllcy97Y29tcGFueV9pZH0iLiBGb3IKIGV4YW1wbGUsICJwcm9qZWN0cy9mb28v
dGVuYW50cy9iYXIvY29tcGFuaWVzL2JheiIuCgogQXQgbW9zdCAyMCBjb21wYW55IGZpbHRl
cnMgYXJlIGFsbG93ZWQuCgoMCgUEAAICBBIDPgIKCgwKBQQAAgIFEgM+CxEKDAoFBAACAgES
Az4SGwoMCgUEAAICAxIDPh4fCokFCgQEAAIDEgNNAi8a+wQgVGhlIGxvY2F0aW9uIGZpbHRl
ciBzcGVjaWZpZXMgZ2VvLXJlZ2lvbnMgY29udGFpbmluZyB0aGUgam9icyB0bwogc2VhcmNo
IGFnYWluc3QuIFNlZSBbTG9jYXRpb25GaWx0ZXJdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQu
TG9jYXRpb25GaWx0ZXJdCiBmb3IgbW9yZSBpbmZvcm1hdGlvbi4KCiBJZiBhIGxvY2F0aW9u
IHZhbHVlIGlzbid0IHNwZWNpZmllZCwgam9icyBmaXR0aW5nIHRoZSBvdGhlciBzZWFyY2gK
IGNyaXRlcmlhIGFyZSByZXRyaWV2ZWQgcmVnYXJkbGVzcyBvZiB3aGVyZSB0aGV5J3JlIGxv
Y2F0ZWQuCgogSWYgbXVsdGlwbGUgdmFsdWVzIGFyZSBzcGVjaWZpZWQsIGpvYnMgYXJlIHJl
dHJpZXZlZCBmcm9tIGFueSBvZiB0aGUKIHNwZWNpZmllZCBsb2NhdGlvbnMuIElmIGRpZmZl
cmVudCB2YWx1ZXMgYXJlIHNwZWNpZmllZCBmb3IgdGhlCiBbTG9jYXRpb25GaWx0ZXIuZGlz
dGFuY2VfaW5fbWlsZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuTG9jYXRpb25GaWx0ZXIu
ZGlzdGFuY2VfaW5fbWlsZXNdCiBwYXJhbWV0ZXIsIHRoZSBtYXhpbXVtIHByb3ZpZGVkIGRp
c3RhbmNlIGlzIHVzZWQgZm9yIGFsbCBsb2NhdGlvbnMuCgogQXQgbW9zdCA1IGxvY2F0aW9u
IGZpbHRlcnMgYXJlIGFsbG93ZWQuCgoMCgUEAAIDBBIDTQIKCgwKBQQAAgMGEgNNCxkKDAoF
BAACAwESA00aKgoMCgUEAAIDAxIDTS0uCtQCCgQEAAIEEgNWAioaxgIgVGhlIGNhdGVnb3J5
IGZpbHRlciBzcGVjaWZpZXMgdGhlIGNhdGVnb3JpZXMgb2Ygam9icyB0byBzZWFyY2ggYWdh
aW5zdC4KIFNlZSBbSm9iQ2F0ZWdvcnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iQ2F0
ZWdvcnldIGZvciBtb3JlIGluZm9ybWF0aW9uLgoKIElmIGEgdmFsdWUgaXNuJ3Qgc3BlY2lm
aWVkLCBqb2JzIGZyb20gYW55IGNhdGVnb3J5IGFyZSBzZWFyY2hlZCBhZ2FpbnN0LgoKIElm
IG11bHRpcGxlIHZhbHVlcyBhcmUgc3BlY2lmaWVkLCBqb2JzIGZyb20gYW55IG9mIHRoZSBz
cGVjaWZpZWQKIGNhdGVnb3JpZXMgYXJlIHNlYXJjaGVkIGFnYWluc3QuCgoMCgUEAAIEBBID
VgIKCgwKBQQAAgQGEgNWCxYKDAoFBAACBAESA1YXJQoMCgUEAAIEAxIDVigpCvoCCgQEAAIF
EgNhAiMa7AIgQWxsb3dzIGZpbHRlcmluZyBqb2JzIGJ5IGNvbW11dGUgdGltZSB3aXRoIGRp
ZmZlcmVudCB0cmF2ZWwgbWV0aG9kcyAoZm9yCiAgZXhhbXBsZSwgZHJpdmluZyBvciBwdWJs
aWMgdHJhbnNpdCkuCgogTm90ZTogVGhpcyBvbmx5IHdvcmtzIHdoZW4geW91IHNwZWNpZnkg
YQogW0NvbW11dGVNZXRob2RdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tbXV0ZU1ldGhv
ZF0uIEluIHRoaXMgY2FzZSwKIFtsb2NhdGlvbl9maWx0ZXJzXVtnb29nbGUuY2xvdWQudGFs
ZW50LnY0LkpvYlF1ZXJ5LmxvY2F0aW9uX2ZpbHRlcnNdIGlzCiBpZ25vcmVkLgoKICBDdXJy
ZW50bHkgd2UgZG9uJ3Qgc3VwcG9ydCBzb3J0aW5nIGJ5IGNvbW11dGUgdGltZS4KCgwKBQQA
AgUGEgNhAg8KDAoFBAACBQESA2EQHgoMCgUEAAIFAxIDYSEiCu4HCgQEAAIGEgN9Aiwa4Acg
VGhpcyBmaWx0ZXIgc3BlY2lmaWVzIHRoZSBjb21wYW55CiBbQ29tcGFueS5kaXNwbGF5X25h
bWVdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGFueS5kaXNwbGF5X25hbWVdIG9mIHRo
ZQogam9icyB0byBzZWFyY2ggYWdhaW5zdC4gVGhlIGNvbXBhbnkgbmFtZSBtdXN0IG1hdGNo
IHRoZSB2YWx1ZSBleGFjdGx5LgoKIEFsdGVybmF0aXZlbHksIHRoZSB2YWx1ZSBiZWluZyBz
ZWFyY2hlZCBmb3IgY2FuIGJlIHdyYXBwZWQgaW4gZGlmZmVyZW50CiBtYXRjaCBvcGVyYXRv
cnMuCiBgU1VCU1RSSU5HX01BVENIKFt2YWx1ZV0pYAogVGhlIGNvbXBhbnkgbmFtZSBtdXN0
IGNvbnRhaW4gYSBjYXNlIGluc2Vuc2l0aXZlIHN1YnN0cmluZyBtYXRjaCBvZiB0aGUKIHZh
bHVlLiBVc2luZyB0aGlzIGZ1bmN0aW9uIG1heSBpbmNyZWFzZSBsYXRlbmN5LgoKIFNhbXBs
ZSBWYWx1ZTogYFNVQlNUUklOR19NQVRDSChnb29nbGUpYAoKIGBNVUxUSV9XT1JEX1RPS0VO
X01BVENIKFt2YWx1ZV0pYAogVGhlIHZhbHVlIHdpbGwgYmUgdHJlYXRlZCBhcyBhIG11bHRp
IHdvcmQgdG9rZW4gYW5kIHRoZSBjb21wYW55IG5hbWUgbXVzdAogY29udGFpbiBhIGNhc2Ug
aW5zZW5zaXRpdmUgbWF0Y2ggb2YgdGhlIHZhbHVlLiBVc2luZyB0aGlzIGZ1bmN0aW9uIG1h
eQogaW5jcmVhc2UgbGF0ZW5jeS4KCiBTYW1wbGUgVmFsdWU6IGBNVUxUSV9XT1JEX1RPS0VO
X01BVENIKGdvb2dsZSlgCgogSWYgYSB2YWx1ZSBpc24ndCBzcGVjaWZpZWQsIGpvYnMgd2l0
aGluIHRoZSBzZWFyY2ggcmVzdWx0cyBhcmUKIGFzc29jaWF0ZWQgd2l0aCBhbnkgY29tcGFu
eS4KCiBJZiBtdWx0aXBsZSB2YWx1ZXMgYXJlIHNwZWNpZmllZCwgam9icyB3aXRoaW4gdGhl
IHNlYXJjaCByZXN1bHRzIG1heSBiZQogYXNzb2NpYXRlZCB3aXRoIGFueSBvZiB0aGUgc3Bl
Y2lmaWVkIGNvbXBhbmllcy4KCiBBdCBtb3N0IDIwIGNvbXBhbnkgZGlzcGxheSBuYW1lIGZp
bHRlcnMgYXJlIGFsbG93ZWQuCgoMCgUEAAIGBBIDfQIKCgwKBQQAAgYFEgN9CxEKDAoFBAAC
BgESA30SJwoMCgUEAAIGAxIDfSorCsECCgQEAAIHEgSEAQItGrICIFRoaXMgc2VhcmNoIGZp
bHRlciBpcyBhcHBsaWVkIG9ubHkgdG8KIFtKb2IuY29tcGVuc2F0aW9uX2luZm9dW2dvb2ds
ZS5jbG91ZC50YWxlbnQudjQuSm9iLmNvbXBlbnNhdGlvbl9pbmZvXS4gRm9yCiBleGFtcGxl
LCBpZiB0aGUgZmlsdGVyIGlzIHNwZWNpZmllZCBhcyAiSG91cmx5IGpvYiB3aXRoIHBlci1o
b3VyCiBjb21wZW5zYXRpb24gPiAkMTUiLCBvbmx5IGpvYnMgbWVldGluZyB0aGVzZSBjcml0
ZXJpYSBhcmUgc2VhcmNoZWQuIElmIGEKIGZpbHRlciBpc24ndCBkZWZpbmVkLCBhbGwgb3Bl
biBqb2JzIGFyZSBzZWFyY2hlZC4KCg0KBQQAAgcGEgSEAQIUCg0KBQQAAgcBEgSEARUoCg0K
BQQAAgcDEgSEASssCtUHCgQEAAIIEgSdAQIlGsYHIFRoaXMgZmlsdGVyIHNwZWNpZmllcyBh
IHN0cnVjdHVyZWQgc3ludGF4IHRvIG1hdGNoIGFnYWluc3QgdGhlCiBbSm9iLmN1c3RvbV9h
dHRyaWJ1dGVzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5jdXN0b21fYXR0cmlidXRl
c10KIG1hcmtlZCBhcyBgZmlsdGVyYWJsZWAuCgogVGhlIHN5bnRheCBmb3IgdGhpcyBleHBy
ZXNzaW9uIGlzIGEgc3Vic2V0IG9mIFNRTCBzeW50YXguCgogU3VwcG9ydGVkIG9wZXJhdG9y
cyBhcmU6IGA9YCwgYCE9YCwgYDxgLCBgPD1gLCBgPmAsIGFuZCBgPj1gIHdoZXJlIHRoZQog
bGVmdCBvZiB0aGUgb3BlcmF0b3IgaXMgYSBjdXN0b20gZmllbGQga2V5IGFuZCB0aGUgcmln
aHQgb2YgdGhlIG9wZXJhdG9yCiBpcyBhIG51bWJlciBvciBhIHF1b3RlZCBzdHJpbmcuIFlv
dSBtdXN0IGVzY2FwZSBiYWNrc2xhc2ggKFxcKSBhbmQKIHF1b3RlIChcIikgY2hhcmFjdGVy
cy4KCiBTdXBwb3J0ZWQgZnVuY3Rpb25zIGFyZSBgTE9XRVIoW2ZpZWxkX25hbWVdKWAgdG8K
IHBlcmZvcm0gYSBjYXNlIGluc2Vuc2l0aXZlIG1hdGNoIGFuZCBgRU1QVFkoW2ZpZWxkX25h
bWVdKWAgdG8gZmlsdGVyIG9uIHRoZQogZXhpc3RlbmNlIG9mIGEga2V5LgoKIEJvb2xlYW4g
ZXhwcmVzc2lvbnMgKEFORC9PUi9OT1QpIGFyZSBzdXBwb3J0ZWQgdXAgdG8gMyBsZXZlbHMg
b2YKIG5lc3RpbmcgKGZvciBleGFtcGxlLCAiKChBIEFORCBCIEFORCBDKSBPUiBOT1QgRCkg
QU5EIEUiKSwgYSBtYXhpbXVtIG9mIDEwMAogY29tcGFyaXNvbnMgb3IgZnVuY3Rpb25zIGFy
ZSBhbGxvd2VkIGluIHRoZSBleHByZXNzaW9uLiBUaGUgZXhwcmVzc2lvbgogbXVzdCBiZSA8
IDEwMDAwIGJ5dGVzIGluIGxlbmd0aC4KCiBTYW1wbGUgUXVlcnk6CiBgKExPV0VSKGRyaXZp
bmdfbGljZW5zZSk9ImNsYXNzIFwiYVwiIiBPUiBFTVBUWShkcml2aW5nX2xpY2Vuc2UpKSBB
TkQKIGRyaXZpbmdfeWVhcnMgPiAxMGAKCg0KBQQAAggFEgSdAQIICg0KBQQAAggBEgSdAQkg
Cg0KBQQAAggDEgSdASMkCuABCgQEAAIJEgSkAQIfGtEBIFRoaXMgZmxhZyBjb250cm9scyB0
aGUgc3BlbGwtY2hlY2sgZmVhdHVyZS4gSWYgZmFsc2UsIHRoZQogc2VydmljZSBhdHRlbXB0
cyB0byBjb3JyZWN0IGEgbWlzc3BlbGxlZCBxdWVyeSwKIGZvciBleGFtcGxlLCAiZW5naW5l
ZSIgaXMgY29ycmVjdGVkIHRvICJlbmdpbmVlciIuCgogRGVmYXVsdHMgdG8gZmFsc2U6IGEg
c3BlbGwgY2hlY2sgaXMgcGVyZm9ybWVkLgoKDQoFBAACCQUSBKQBAgYKDQoFBAACCQESBKQB
BxoKDQoFBAACCQMSBKQBHR4KggMKBAQAAgoSBK8BAjAa8wIgVGhlIGVtcGxveW1lbnQgdHlw
ZSBmaWx0ZXIgc3BlY2lmaWVzIHRoZSBlbXBsb3ltZW50IHR5cGUgb2Ygam9icyB0bwogc2Vh
cmNoIGFnYWluc3QsIHN1Y2ggYXMKIFtFbXBsb3ltZW50VHlwZS5GVUxMX1RJTUVdW2dvb2ds
ZS5jbG91ZC50YWxlbnQudjQuRW1wbG95bWVudFR5cGUuRlVMTF9USU1FXS4KCiBJZiBhIHZh
bHVlIGlzbid0IHNwZWNpZmllZCwgam9icyBpbiB0aGUgc2VhcmNoIHJlc3VsdHMgaW5jbHVk
ZXMgYW55CiBlbXBsb3ltZW50IHR5cGUuCgogSWYgbXVsdGlwbGUgdmFsdWVzIGFyZSBzcGVj
aWZpZWQsIGpvYnMgaW4gdGhlIHNlYXJjaCByZXN1bHRzIGluY2x1ZGUKIGFueSBvZiB0aGUg
c3BlY2lmaWVkIGVtcGxveW1lbnQgdHlwZXMuCgoNCgUEAAIKBBIErwECCgoNCgUEAAIKBhIE
rwELGQoNCgUEAAIKARIErwEaKgoNCgUEAAIKAxIErwEtLwqSAwoEBAACCxIEvQECJhqDAyBU
aGlzIGZpbHRlciBzcGVjaWZpZXMgdGhlIGxvY2FsZSBvZiBqb2JzIHRvIHNlYXJjaCBhZ2Fp
bnN0LAogZm9yIGV4YW1wbGUsICJlbi1VUyIuCgogSWYgYSB2YWx1ZSBpc24ndCBzcGVjaWZp
ZWQsIHRoZSBzZWFyY2ggcmVzdWx0cyBjYW4gY29udGFpbiBqb2JzIGluIGFueQogbG9jYWxl
LgoKCiBMYW5ndWFnZSBjb2RlcyBzaG91bGQgYmUgaW4gQkNQLTQ3IGZvcm1hdCwgc3VjaCBh
cyAiZW4tVVMiIG9yICJzci1MYXRuIi4KIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtU
YWdzIGZvciBJZGVudGlmeWluZyBMYW5ndWFnZXNdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcv
aHRtbC9iY3A0NykuCgogQXQgbW9zdCAxMCBsYW5ndWFnZSBjb2RlIGZpbHRlcnMgYXJlIGFs
bG93ZWQuCgoNCgUEAAILBBIEvQECCgoNCgUEAAILBRIEvQELEQoNCgUEAAILARIEvQESIAoN
CgUEAAILAxIEvQEjJQpdCgQEAAIMEgTBAQIpGk8gSm9icyBwdWJsaXNoZWQgd2l0aGluIGEg
cmFuZ2Ugc3BlY2lmaWVkIGJ5IHRoaXMgZmlsdGVyIGFyZSBzZWFyY2hlZAogYWdhaW5zdC4K
Cg0KBQQAAgwGEgTBAQIQCg0KBQQAAgwBEgTBAREjCg0KBQQAAgwDEgTBASYoCoUBCgQEAAIN
EgTGAQIlGncgVGhpcyBmaWx0ZXIgc3BlY2lmaWVzIGEgbGlzdCBvZiBqb2IgbmFtZXMgdG8g
YmUgZXhjbHVkZWQgZHVyaW5nIHNlYXJjaC4KCiBBdCBtb3N0IDQwMCBleGNsdWRlZCBqb2Ig
bmFtZXMgYXJlIGFsbG93ZWQuCgoNCgUEAAINBBIExgECCgoNCgUEAAINBRIExgELEQoNCgUE
AAINARIExgESHwoNCgUEAAINAxIExgEiJAowCgIEARIGygEAkwIBGiIgR2VvZ3JhcGhpYyBy
ZWdpb24gb2YgdGhlIHNlYXJjaC4KCgsKAwQBARIEygEIFgo+CgQEAQQAEgbMAQLZAQMaLiBT
cGVjaWZ5IHdoZXRoZXIgdG8gaW5jbHVkZSB0ZWxlY29tbXV0ZSBqb2JzLgoKDQoFBAEEAAES
BMwBBxwKTgoGBAEEAAIAEgTOAQQrGj4gRGVmYXVsdCB2YWx1ZSBpZiB0aGUgdGVsZWNvbW11
dGUgcHJlZmVyZW5jZSBpc24ndCBzcGVjaWZpZWQuCgoPCgcEAQQAAgABEgTOAQQmCg8KBwQB
BAACAAISBM4BKSoKhAEKBgQBBAACARIE0gEEMRp0IERlcHJlY2F0ZWQ6IElnbm9yZSB0ZWxl
Y29tbXV0ZSBzdGF0dXMgb2Ygam9icy4gVXNlCiBURUxFQ09NTVVURV9KT0JTX0VYQ0xVREVE
IGlmIHdhbnQgdG8gZXhjbHVkZSB0ZWxlY29tbXV0ZSBqb2JzLgoKDwoHBAEEAAIBARIE0gEE
GAoPCgcEAQQAAgECEgTSARscCg8KBwQBBAACAQMSBNIBHTAKEAoIBAEEAAIBAwESBNIBHi8K
KQoGBAEEAAICEgTVAQQcGhkgQWxsb3cgdGVsZWNvbW11dGUgam9icy4KCg8KBwQBBAACAgES
BNUBBBcKDwoHBAEEAAICAhIE1QEaGworCgYEAQQAAgMSBNgBBCIaGyBFeGNsdWRlIHRlbGVj
b21tdXRlIGpvYnMuCgoPCgcEAQQAAgMBEgTYAQQdCg8KBwQBBAACAwISBNgBICEKSAoEBAEC
ABIE3AECFRo6IFRoZSBhZGRyZXNzIG5hbWUsIHN1Y2ggYXMgIk1vdW50YWluIFZpZXciIG9y
ICJCYXkgQXJlYSIuCgoNCgUEAQIABRIE3AECCAoNCgUEAQIAARIE3AEJEAoNCgUEAQIAAxIE
3AETFAq8BgoEBAECARIE7QECGRqtBiBDTERSIHJlZ2lvbiBjb2RlIG9mIHRoZSBjb3VudHJ5
L3JlZ2lvbi4gVGhpcyBmaWVsZCBtYXkgYmUgdXNlZCBpbiB0d28gd2F5czoKCiAxKSBJZiB0
ZWxlY29tbXV0ZSBwcmVmZXJlbmNlIGlzIG5vdCBzZXQsIHRoaXMgZmllbGQgaXMgdXNlZCBh
ZGRyZXNzCiBhbWJpZ3VpdHkgb2YgdGhlIHVzZXItaW5wdXQgYWRkcmVzcy4gRm9yIGV4YW1w
bGUsICJMaXZlcnBvb2wiIG1heSByZWZlciB0bwogIkxpdmVycG9vbCwgTlksIFVTIiBvciAi
TGl2ZXJwb29sLCBVSyIuIFRoaXMgcmVnaW9uIGNvZGUgYmlhc2VzIHRoZQogYWRkcmVzcyBy
ZXNvbHV0aW9uIHRvd2FyZCBhIHNwZWNpZmljIGNvdW50cnkgb3IgdGVycml0b3J5LiBJZiB0
aGlzIGZpZWxkIGlzCiBub3Qgc2V0LCBhZGRyZXNzIHJlc29sdXRpb24gaXMgYmlhc2VkIHRv
d2FyZCB0aGUgVW5pdGVkIFN0YXRlcyBieSBkZWZhdWx0LgoKIDIpIElmIHRlbGVjb21tdXRl
IHByZWZlcmVuY2UgaXMgc2V0IHRvIFRFTEVDT01NVVRFX0FMTE9XRUQsIHRoZQogdGVsZWNv
bW11dGUgbG9jYXRpb24gZmlsdGVyIHdpbGwgYmUgbGltaXRlZCB0byB0aGUgcmVnaW9uIHNw
ZWNpZmllZCBpbiB0aGlzCiBmaWVsZC4gSWYgdGhpcyBmaWVsZCBpcyBub3Qgc2V0LCB0aGUg
dGVsZWNvbW11dGUgam9iIGxvY2F0aW9ucyB3aWxsIG5vdCBiZQoKIFNlZQogaHR0cHM6Ly91
bmljb2RlLW9yZy5naXRodWIuaW8vY2xkci1zdGFnaW5nL2NoYXJ0cy9sYXRlc3Qvc3VwcGxl
bWVudGFsL3RlcnJpdG9yeV9pbmZvcm1hdGlvbi5odG1sCiBmb3IgZGV0YWlscy4gRXhhbXBs
ZTogIkNIIiBmb3IgU3dpdHplcmxhbmQuCgoNCgUEAQIBBRIE7QECCAoNCgUEAQIBARIE7QEJ
FAoNCgUEAQIBAxIE7QEXGAqEAQoEBAECAhIE8QECIRp2IFRoZSBsYXRpdHVkZSBhbmQgbG9u
Z2l0dWRlIG9mIHRoZSBnZW9ncmFwaGljIGNlbnRlciB0byBzZWFyY2ggZnJvbS4gVGhpcwog
ZmllbGQgaXMgaWdub3JlZCBpZiBgYWRkcmVzc2AgaXMgcHJvdmlkZWQuCgoNCgUEAQICBhIE
8QECFAoNCgUEAQICARIE8QEVHAoNCgUEAQICAxIE8QEfIArLAQoEBAECAxIE9gECHxq8ASBU
aGUgZGlzdGFuY2VfaW5fbWlsZXMgaXMgYXBwbGllZCB3aGVuIHRoZSBsb2NhdGlvbiBiZWlu
ZyBzZWFyY2hlZCBmb3IgaXMKIGlkZW50aWZpZWQgYXMgYSBjaXR5IG9yIHNtYWxsZXIuIFRo
aXMgZmllbGQgaXMgaWdub3JlZCBpZiB0aGUgbG9jYXRpb24KIGJlaW5nIHNlYXJjaGVkIGZv
ciBpcyBhIHN0YXRlIG9yIGxhcmdlci4KCg0KBQQBAgMFEgT2AQIICg0KBQQBAgMBEgT2AQka
Cg0KBQQBAgMDEgT2AR0eCrgMCgQEAQIEEgSSAgIzGqkMIEFsbG93cyB0aGUgY2xpZW50IHRv
IHJldHVybiBqb2JzIHdpdGhvdXQgYQogc2V0IGxvY2F0aW9uLCBzcGVjaWZpY2FsbHksIHRl
bGVjb21tdXRpbmcgam9icyAodGVsZWNvbW11dGluZyBpcyBjb25zaWRlcmVkCiBieSB0aGUg
c2VydmljZSBhcyBhIHNwZWNpYWwgbG9jYXRpb24pLgogW0pvYi5wb3N0aW5nX3JlZ2lvbl1b
Z29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IucG9zdGluZ19yZWdpb25dIGluZGljYXRlcwog
aWYgYSBqb2IgcGVybWl0cyB0ZWxlY29tbXV0aW5nLiBJZiB0aGlzIGZpZWxkIGlzIHNldCB0
bwogW1RlbGVjb21tdXRlUHJlZmVyZW5jZS5URUxFQ09NTVVURV9BTExPV0VEXVtnb29nbGUu
Y2xvdWQudGFsZW50LnY0LkxvY2F0aW9uRmlsdGVyLlRlbGVjb21tdXRlUHJlZmVyZW5jZS5U
RUxFQ09NTVVURV9BTExPV0VEXSwKIHRlbGVjb21tdXRpbmcgam9icyBhcmUgc2VhcmNoZWQs
IGFuZAogW2FkZHJlc3NdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuTG9jYXRpb25GaWx0ZXIu
YWRkcmVzc10gYW5kCiBbbGF0X2xuZ11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Mb2NhdGlv
bkZpbHRlci5sYXRfbG5nXSBhcmUgaWdub3JlZC4gSWYKIG5vdCBzZXQgb3Igc2V0IHRvCiBb
VGVsZWNvbW11dGVQcmVmZXJlbmNlLlRFTEVDT01NVVRFX0VYQ0xVREVEXVtnb29nbGUuY2xv
dWQudGFsZW50LnY0LkxvY2F0aW9uRmlsdGVyLlRlbGVjb21tdXRlUHJlZmVyZW5jZS5URUxF
Q09NTVVURV9FWENMVURFRF0sCiB0aGUgdGVsZWNvbW11dGUgc3RhdHVzIG9mIHRoZSBqb2Jz
IGlzIGlnbm9yZWQuIEpvYnMgdGhhdCBoYXZlCiBbUG9zdGluZ1JlZ2lvbi5URUxFQ09NTVVU
RV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Qb3N0aW5nUmVnaW9uLlRFTEVDT01NVVRFXQog
YW5kIGhhdmUgYWRkaXRpb25hbCBbSm9iLmFkZHJlc3Nlc11bZ29vZ2xlLmNsb3VkLnRhbGVu
dC52NC5Kb2IuYWRkcmVzc2VzXQogbWF5IHN0aWxsIGJlIG1hdGNoZWQgYmFzZWQgb24gb3Ro
ZXIgbG9jYXRpb24gZmlsdGVycyB1c2luZwogW2FkZHJlc3NdW2dvb2dsZS5jbG91ZC50YWxl
bnQudjQuTG9jYXRpb25GaWx0ZXIuYWRkcmVzc10gb3IKIFtsYXRfbG5nXVtnb29nbGUuY2xv
dWQudGFsZW50LnY0LkxvY2F0aW9uRmlsdGVyLmxhdF9sbmddLgoKIFRoaXMgZmlsdGVyIGNh
biBiZSB1c2VkIGJ5IGl0c2VsZiB0byBzZWFyY2ggZXhjbHVzaXZlbHkgZm9yIHRlbGVjb21t
dXRpbmcKIGpvYnMsIG9yIGl0IGNhbiBiZSBjb21iaW5lZCB3aXRoIGFub3RoZXIgbG9jYXRp
b24KIGZpbHRlciB0byBzZWFyY2ggZm9yIGEgY29tYmluYXRpb24gb2Ygam9iIGxvY2F0aW9u
cywKIHN1Y2ggYXMgIk1vdW50YWluIFZpZXciIG9yICJ0ZWxlY29tbXV0aW5nIiBqb2JzLiBI
b3dldmVyLCB3aGVuIHVzZWQgaW4KIGNvbWJpbmF0aW9uIHdpdGggb3RoZXIgbG9jYXRpb24g
ZmlsdGVycywgdGVsZWNvbW11dGluZyBqb2JzIGNhbiBiZQogdHJlYXRlZCBhcyBsZXNzIHJl
bGV2YW50IHRoYW4gb3RoZXIgam9icyBpbiB0aGUgc2VhcmNoIHJlc3BvbnNlLgoKIFRoaXMg
ZmllbGQgaXMgb25seSB1c2VkIGZvciBqb2Igc2VhcmNoIHJlcXVlc3RzLgoKDQoFBAECBAYS
BJICAhcKDQoFBAECBAESBJICGC4KDQoFBAECBAMSBJICMTIKOwoCBAISBpYCANECARotIEZp
bHRlciBvbiBqb2IgY29tcGVuc2F0aW9uIHR5cGUgYW5kIGFtb3VudC4KCgsKAwQCARIElgII
GgowCgQEAgQAEgaYAgLBAgMaICBTcGVjaWZ5IHRoZSB0eXBlIG9mIGZpbHRlcmluZy4KCg0K
BQQCBAABEgSYAgcRCloKBgQCBAACABIEmgIEIBpKIEZpbHRlciB0eXBlIHVuc3BlY2lmaWVk
LiBQb3NpdGlvbiBob2xkZXIsIElOVkFMSUQsIHNob3VsZCBuZXZlciBiZSB1c2VkLgoKDwoH
BAIEAAIAARIEmgIEGwoPCgcEAgQAAgACEgSaAh4fCt8DCgYEAgQAAgESBKUCBBIazgMgRmls
dGVyIGJ5IGBiYXNlIGNvbXBlbnNhdGlvbiBlbnRyeSdzYCB1bml0LiBBIGpvYiBpcyBhIG1h
dGNoIGlmIGFuZAogb25seSBpZiB0aGUgam9iIGNvbnRhaW5zIGEgYmFzZSBDb21wZW5zYXRp
b25FbnRyeSBhbmQgdGhlIGJhc2UKIENvbXBlbnNhdGlvbkVudHJ5J3MgdW5pdCBtYXRjaGVz
IHByb3ZpZGVkCiBbdW5pdHNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGVuc2F0aW9u
RmlsdGVyLnVuaXRzXS4gUG9wdWxhdGUgb25lIG9yCiBtb3JlIFt1bml0c11bZ29vZ2xlLmNs
b3VkLnRhbGVudC52NC5Db21wZW5zYXRpb25GaWx0ZXIudW5pdHNdLgoKIFNlZQogW0NvbXBl
bnNhdGlvbkluZm8uQ29tcGVuc2F0aW9uRW50cnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjQu
Q29tcGVuc2F0aW9uSW5mby5Db21wZW5zYXRpb25FbnRyeV0KIGZvciBkZWZpbml0aW9uIG9m
IGJhc2UgY29tcGVuc2F0aW9uIGVudHJ5LgoKDwoHBAIEAAIBARIEpQIEDQoPCgcEAgQAAgEC
EgSlAhARCroFCgYEAgQAAgISBLQCBBgaqQUgRmlsdGVyIGJ5IGBiYXNlIGNvbXBlbnNhdGlv
biBlbnRyeSdzYCB1bml0IGFuZCBhbW91bnQgLyByYW5nZS4gQSBqb2IKIGlzIGEgbWF0Y2gg
aWYgYW5kIG9ubHkgaWYgdGhlIGpvYiBjb250YWlucyBhIGJhc2UgQ29tcGVuc2F0aW9uRW50
cnksIGFuZAogdGhlIGJhc2UgZW50cnkncyB1bml0IG1hdGNoZXMgcHJvdmlkZWQKIFtDb21w
ZW5zYXRpb25Vbml0XVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBlbnNhdGlvbkluZm8u
Q29tcGVuc2F0aW9uVW5pdF0KIGFuZCBhbW91bnQgb3IgcmFuZ2Ugb3ZlcmxhcHMgd2l0aCBw
cm92aWRlZAogW0NvbXBlbnNhdGlvblJhbmdlXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkNv
bXBlbnNhdGlvbkluZm8uQ29tcGVuc2F0aW9uUmFuZ2VdLgoKIFNlZQogW0NvbXBlbnNhdGlv
bkluZm8uQ29tcGVuc2F0aW9uRW50cnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGVu
c2F0aW9uSW5mby5Db21wZW5zYXRpb25FbnRyeV0KIGZvciBkZWZpbml0aW9uIG9mIGJhc2Ug
Y29tcGVuc2F0aW9uIGVudHJ5LgoKIFNldCBleGFjdGx5IG9uZSBbdW5pdHNdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjQuQ29tcGVuc2F0aW9uRmlsdGVyLnVuaXRzXQogYW5kIHBvcHVsYXRl
IFtyYW5nZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Db21wZW5zYXRpb25GaWx0ZXIucmFu
Z2VdLgoKDwoHBAIEAAICARIEtAIEEwoPCgcEAgQAAgICEgS0AhYXCvYBCgYEAgQAAgMSBLoC
BB8a5QEgRmlsdGVyIGJ5IGFubnVhbGl6ZWQgYmFzZSBjb21wZW5zYXRpb24gYW1vdW50IGFu
ZCBgYmFzZSBjb21wZW5zYXRpb24KIGVudHJ5J3NgIHVuaXQuIFBvcHVsYXRlCiBbcmFuZ2Vd
W2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGVuc2F0aW9uRmlsdGVyLnJhbmdlXSBhbmQg
emVybyBvciBtb3JlCiBbdW5pdHNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGVuc2F0
aW9uRmlsdGVyLnVuaXRzXS4KCg8KBwQCBAACAwESBLoCBBoKDwoHBAIEAAIDAhIEugIdHgr4
AQoGBAIEAAIEEgTAAgQgGucBIEZpbHRlciBieSBhbm51YWxpemVkIHRvdGFsIGNvbXBlbnNh
dGlvbiBhbW91bnQgYW5kIGBiYXNlIGNvbXBlbnNhdGlvbgogZW50cnknc2AgdW5pdCAuIFBv
cHVsYXRlCiBbcmFuZ2VdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGVuc2F0aW9uRmls
dGVyLnJhbmdlXSBhbmQgemVybyBvciBtb3JlCiBbdW5pdHNdW2dvb2dsZS5jbG91ZC50YWxl
bnQudjQuQ29tcGVuc2F0aW9uRmlsdGVyLnVuaXRzXS4KCg8KBwQCBAACBAESBMACBBsKDwoH
BAIEAAIEAhIEwAIeHwopCgQEAgIAEgTEAgI/GhsgUmVxdWlyZWQuIFR5cGUgb2YgZmlsdGVy
LgoKDQoFBAICAAYSBMQCAgwKDQoFBAICAAESBMQCDREKDQoFBAICAAMSBMQCFBUKDQoFBAIC
AAgSBMQCFj4KEAoIBAICAAicCAASBMQCFz0KqAEKBAQCAgESBsgCAskCLxqXASBSZXF1aXJl
ZC4gU3BlY2lmeSBkZXNpcmVkIGBiYXNlIGNvbXBlbnNhdGlvbiBlbnRyeSdzYAogW0NvbXBl
bnNhdGlvbkluZm8uQ29tcGVuc2F0aW9uVW5pdF1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5D
b21wZW5zYXRpb25JbmZvLkNvbXBlbnNhdGlvblVuaXRdLgoKDQoFBAICAQQSBMgCAgoKDQoF
BAICAQYSBMgCCywKDQoFBAICAQESBMgCLTIKDQoFBAICAQMSBMgCNTYKDQoFBAICAQgSBMkC
Bi4KEAoIBAICAQicCAASBMkCBy0KIwoEBAICAhIEzAICLxoVIENvbXBlbnNhdGlvbiByYW5n
ZS4KCg0KBQQCAgIGEgTMAgIkCg0KBQQCAgIBEgTMAiUqCg0KBQQCAgIDEgTMAi0uCl4KBAQC
AgMSBNACAjwaUCBJZiBzZXQgdG8gdHJ1ZSwgam9icyB3aXRoIHVuc3BlY2lmaWVkIGNvbXBl
bnNhdGlvbiByYW5nZSBmaWVsZHMgYXJlCiBpbmNsdWRlZC4KCg0KBQQCAgMFEgTQAgIGCg0K
BQQCAgMBEgTQAgc3Cg0KBQQCAgMDEgTQAjo7CjUKAgQDEgbUAgCAAwEaJyBQYXJhbWV0ZXJz
IG5lZWRlZCBmb3IgY29tbXV0ZSBzZWFyY2guCgoLCgMEAwESBNQCCBUKSwoEBAMEABIG1gIC
3wIDGjsgVGhlIHRyYWZmaWMgZGVuc2l0eSB0byB1c2Ugd2hlbiBjYWxjdWxhdGluZyBjb21t
dXRlIHRpbWUuCgoNCgUEAwQAARIE1gIHEgo5CgYEAwQAAgASBNgCBCEaKSBSb2FkIHRyYWZm
aWMgc2l0dWF0aW9uIGlzbid0IHNwZWNpZmllZC4KCg8KBwQDBAACAAESBNgCBBwKDwoHBAME
AAIAAhIE2AIfIApOCgYEAwQAAgESBNsCBBUaPiBPcHRpbWFsIGNvbW11dGUgdGltZSB3aXRo
b3V0IGNvbnNpZGVyaW5nIGFueSB0cmFmZmljIGltcGFjdC4KCg8KBwQDBAACAQESBNsCBBAK
DwoHBAMEAAIBAhIE2wITFApUCgYEAwQAAgISBN4CBBIaRCBDb21tdXRlIHRpbWUgY2FsY3Vs
YXRpb24gdGFrZXMgaW4gYWNjb3VudCB0aGUgcGVhayB0cmFmZmljIGltcGFjdC4KCg8KBwQD
BAACAgESBN4CBA0KDwoHBAMEAAICAhIE3gIQEQpZCgQEAwIAEgTiAgJMGksgUmVxdWlyZWQu
IFRoZSBtZXRob2Qgb2YgdHJhbnNwb3J0YXRpb24gdG8gY2FsY3VsYXRlIHRoZSBjb21tdXRl
IHRpbWUgZm9yLgoKDQoFBAMCAAYSBOICAg8KDQoFBAMCAAESBOICEB4KDQoFBAMCAAMSBOIC
ISIKDQoFBAMCAAgSBOICI0sKEAoIBAMCAAicCAASBOICJEoKawoEBAMCARIG5gIC5wIvGlsg
UmVxdWlyZWQuIFRoZSBsYXRpdHVkZSBhbmQgbG9uZ2l0dWRlIG9mIHRoZSBsb2NhdGlvbiB0
byBjYWxjdWxhdGUgdGhlCiBjb21tdXRlIHRpbWUgZnJvbS4KCg0KBQQDAgEGEgTmAgIUCg0K
BQQDAgEBEgTmAhUmCg0KBQQDAgEDEgTmAikqCg0KBQQDAgEIEgTnAgYuChAKCAQDAgEInAgA
EgTnAgctCoMBCgQEAwICEgbrAgLsAi8acyBSZXF1aXJlZC4gVGhlIG1heGltdW0gdHJhdmVs
IHRpbWUgaW4gc2Vjb25kcy4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcwogYDM2MDBz
YCAob25lIGhvdXIpLiBGb3JtYXQgaXMgYDEyM3NgLgoKDQoFBAMCAgYSBOsCAhoKDQoFBAMC
AgESBOsCGyoKDQoFBAMCAgMSBOsCLS4KDQoFBAMCAggSBOwCBi4KEAoIBAMCAgicCAASBOwC
By0K0AIKBAQDAgMSBPMCAiUawQIgSWYgYHRydWVgLCBqb2JzIHdpdGhvdXQgc3RyZWV0IGxl
dmVsIGFkZHJlc3NlcyBtYXkgYWxzbyBiZSByZXR1cm5lZC4KIEZvciBjaXR5IGxldmVsIGFk
ZHJlc3NlcywgdGhlIGNpdHkgY2VudGVyIGlzIHVzZWQuIEZvciBzdGF0ZSBhbmQgY29hcnNl
cgogbGV2ZWwgYWRkcmVzc2VzLCB0ZXh0IG1hdGNoaW5nIGlzIHVzZWQuCiBJZiB0aGlzIGZp
ZWxkIGlzIHNldCB0byBgZmFsc2VgIG9yIGlzbid0IHNwZWNpZmllZCwgb25seSBqb2JzIHRo
YXQgaW5jbHVkZQogc3RyZWV0IGxldmVsIGFkZHJlc3NlcyB3aWxsIGJlIHJldHVybmVkIGJ5
IGNvbW11dGUgc2VhcmNoLgoKDQoFBAMCAwUSBPMCAgYKDQoFBAMCAwESBPMCByAKDQoFBAMC
AwMSBPMCIyQKUQoEBAMIABIG9gIC/wIDGkEgVHJhZmZpYyBmYWN0b3IgdG8gdGFrZSBpbnRv
IGFjY291bnQgd2hpbGUgc2VhcmNoaW5nIGJ5IGNvbW11dGUuCgoNCgUEAwgAARIE9gIIFgpT
CgQEAwIEEgT4AgQhGkUgU3BlY2lmaWVzIHRoZSB0cmFmZmljIGRlbnNpdHkgdG8gdXNlIHdo
ZW4gY2FsY3VsYXRpbmcgY29tbXV0ZSB0aW1lLgoKDQoFBAMCBAYSBPgCBA8KDQoFBAMCBAES
BPgCEBwKDQoFBAMCBAMSBPgCHyAK2gEKBAQDAgUSBP4CBC0aywEgVGhlIGRlcGFydHVyZSB0
aW1lIHVzZWQgdG8gY2FsY3VsYXRlIHRyYWZmaWMgaW1wYWN0LCByZXByZXNlbnRlZCBhcwog
W2dvb2dsZS50eXBlLlRpbWVPZkRheV1bZ29vZ2xlLnR5cGUuVGltZU9mRGF5XSBpbiBsb2Nh
bCB0aW1lIHpvbmUuCgogQ3VycmVudGx5IHRyYWZmaWMgbW9kZWwgaXMgcmVzdHJpY3RlZCB0
byBob3VyIGxldmVsIHJlc29sdXRpb24uCgoNCgUEAwIFBhIE/gIEGQoNCgUEAwIFARIE/gIa
KAoNCgUEAwIFAxIE/gIrLGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::Filters::JobQuery ===
    # Fields for JobQuery
    # Field: query Type: 9 ()
    # Field: query_language_code Type: 9 ()
    # Field: companies Type: 9 ()
    # Field: location_filters Type: 11 (.google.cloud.talent.v4.LocationFilter)
    # Field: job_categories Type: 14 (.google.cloud.talent.v4.JobCategory)
    # Field: commute_filter Type: 11 (.google.cloud.talent.v4.CommuteFilter)
    # Field: company_display_names Type: 9 ()
    # Field: compensation_filter Type: 11 (.google.cloud.talent.v4.CompensationFilter)
    # Field: custom_attribute_filter Type: 9 ()
    # Field: disable_spell_check Type: 8 ()
    # Field: employment_types Type: 14 (.google.cloud.talent.v4.EmploymentType)
    # Field: language_codes Type: 9 ()
    # Field: publish_time_range Type: 11 (.google.cloud.talent.v4.TimestampRange)
    # Field: excluded_jobs Type: 9 ()

# === Message: Google::Cloud::Talent::V4::Filters::LocationFilter ===
    # Fields for LocationFilter
    # Field: address Type: 9 ()
    # Field: region_code Type: 9 ()
    # Field: lat_lng Type: 11 (.google.type.LatLng)
    # Field: distance_in_miles Type: 1 ()
    # Field: telecommute_preference Type: 14 (.google.cloud.talent.v4.LocationFilter.TelecommutePreference)

# Enum: LocationFilter::TelecommutePreference
our $LocationFilter_TELECOMMUTE_PREFERENCE_UNSPECIFIED = 0;
our $LocationFilter_TELECOMMUTE_EXCLUDED = 1;
our $LocationFilter_TELECOMMUTE_ALLOWED = 2;
our $LocationFilter_TELECOMMUTE_JOBS_EXCLUDED = 3;

# === Message: Google::Cloud::Talent::V4::Filters::CompensationFilter ===
    # Fields for CompensationFilter
    # Field: type Type: 14 (.google.cloud.talent.v4.CompensationFilter.FilterType)
    # Field: units Type: 14 (.google.cloud.talent.v4.CompensationInfo.CompensationUnit)
    # Field: range Type: 11 (.google.cloud.talent.v4.CompensationInfo.CompensationRange)
    # Field: include_jobs_with_unspecified_compensation_range Type: 8 ()

# Enum: CompensationFilter::FilterType
our $CompensationFilter_FILTER_TYPE_UNSPECIFIED = 0;
our $CompensationFilter_UNIT_ONLY = 1;
our $CompensationFilter_UNIT_AND_AMOUNT = 2;
our $CompensationFilter_ANNUALIZED_BASE_AMOUNT = 3;
our $CompensationFilter_ANNUALIZED_TOTAL_AMOUNT = 4;

# === Message: Google::Cloud::Talent::V4::Filters::CommuteFilter ===
    # Fields for CommuteFilter
    # Field: commute_method Type: 14 (.google.cloud.talent.v4.CommuteMethod)
    # Field: start_coordinates Type: 11 (.google.type.LatLng)
    # Field: travel_duration Type: 11 (.google.protobuf.Duration)
    # Field: allow_imprecise_addresses Type: 8 ()
    # Field: road_traffic Type: 14 (.google.cloud.talent.v4.CommuteFilter.RoadTraffic)
    # Field: departure_time Type: 11 (.google.type.TimeOfDay)

# Enum: CommuteFilter::RoadTraffic
our $CommuteFilter_ROAD_TRAFFIC_UNSPECIFIED = 0;
our $CommuteFilter_TRAFFIC_FREE = 1;
our $CommuteFilter_BUSY_HOUR = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::Filters - Compiled Protocol Buffers messages for google/cloud/talent/v4/filters.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::Filters;

    my $msg = Google::Cloud::Talent::V4::Filters::JobQuery->new({
        query => $query,
        query_language_code => $query_language_code,
        companies => $companies,
        location_filters => $location_filters,
    });

    # Read or update a field
    my $val = $msg->query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::Filters::JobQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/filters.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::Filters::JobQuery

The query required to perform a search query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

The query string that matches against the job title, description, and
location fields.

The maximum number of allowed characters is 255.

=item * C<< $msg->query_language_code() >> / C<< $msg->query_language_code($value) >>

Type: C<String>

The language code of [query][google.cloud.talent.v4.JobQuery.query]. For
example, "en-US". This field helps to better interpret the query.

If a value isn't specified, the query language code is automatically
detected, which may not be accurate.

Language code should be in BCP-47 format, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47).

=item * C<< $msg->companies() >> / C<< $msg->companies($value) >>

Type: C<String>

This filter specifies the company entities to search against.

If a value isn't specified, jobs are searched for against all
companies.

If multiple values are specified, jobs are searched against the
companies specified.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}". For
example, "projects/foo/tenants/bar/companies/baz".

At most 20 company filters are allowed.

=item * C<< $msg->location_filters() >> / C<< $msg->location_filters($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Filters::LocationFilter>)

The location filter specifies geo-regions containing the jobs to
search against. See [LocationFilter][google.cloud.talent.v4.LocationFilter]
for more information.

If a location value isn't specified, jobs fitting the other search
criteria are retrieved regardless of where they're located.

If multiple values are specified, jobs are retrieved from any of the
specified locations. If different values are specified for the
[LocationFilter.distance_in_miles][google.cloud.talent.v4.LocationFilter.distance_in_miles]
parameter, the maximum provided distance is used for all locations.

At most 5 location filters are allowed.

=item * C<< $msg->job_categories() >> / C<< $msg->job_categories($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::JobCategory>)

The category filter specifies the categories of jobs to search against.
See [JobCategory][google.cloud.talent.v4.JobCategory] for more information.

If a value isn't specified, jobs from any category are searched against.

If multiple values are specified, jobs from any of the specified
categories are searched against.

=item * C<< $msg->commute_filter() >> / C<< $msg->commute_filter($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Filters::CommuteFilter>)

Allows filtering jobs by commute time with different travel methods (for
 example, driving or public transit).

Note: This only works when you specify a
[CommuteMethod][google.cloud.talent.v4.CommuteMethod]. In this case,
[location_filters][google.cloud.talent.v4.JobQuery.location_filters] is
ignored.

 Currently we don't support sorting by commute time.

=item * C<< $msg->company_display_names() >> / C<< $msg->company_display_names($value) >>

Type: C<String>

This filter specifies the company
[Company.display_name][google.cloud.talent.v4.Company.display_name] of the
jobs to search against. The company name must match the value exactly.

Alternatively, the value being searched for can be wrapped in different
match operators.
`SUBSTRING_MATCH([value])`
The company name must contain a case insensitive substring match of the
value. Using this function may increase latency.

Sample Value: `SUBSTRING_MATCH(google)`

`MULTI_WORD_TOKEN_MATCH([value])`
The value will be treated as a multi word token and the company name must
contain a case insensitive match of the value. Using this function may
increase latency.

Sample Value: `MULTI_WORD_TOKEN_MATCH(google)`

If a value isn't specified, jobs within the search results are
associated with any company.

If multiple values are specified, jobs within the search results may be
associated with any of the specified companies.

At most 20 company display name filters are allowed.

=item * C<< $msg->compensation_filter() >> / C<< $msg->compensation_filter($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Filters::CompensationFilter>)

This search filter is applied only to
[Job.compensation_info][google.cloud.talent.v4.Job.compensation_info]. For
example, if the filter is specified as "Hourly job with per-hour
compensation > $15", only jobs meeting these criteria are searched. If a
filter isn't defined, all open jobs are searched.

=item * C<< $msg->custom_attribute_filter() >> / C<< $msg->custom_attribute_filter($value) >>

Type: C<String>

This filter specifies a structured syntax to match against the
[Job.custom_attributes][google.cloud.talent.v4.Job.custom_attributes]
marked as `filterable`.

The syntax for this expression is a subset of SQL syntax.

Supported operators are: `=`, `!=`, `<`, `<=`, `>`, and `>=` where the
left of the operator is a custom field key and the right of the operator
is a number or a quoted string. You must escape backslash (\\) and
quote (\") characters.

Supported functions are `LOWER([field_name])` to
perform a case insensitive match and `EMPTY([field_name])` to filter on the
existence of a key.

Boolean expressions (AND/OR/NOT) are supported up to 3 levels of
nesting (for example, "((A AND B AND C) OR NOT D) AND E"), a maximum of 100
comparisons or functions are allowed in the expression. The expression
must be < 10000 bytes in length.

Sample Query:
`(LOWER(driving_license)="class \"a\"" OR EMPTY(driving_license)) AND
driving_years > 10`

=item * C<< $msg->disable_spell_check() >> / C<< $msg->disable_spell_check($value) >>

Type: C<Bool>

This flag controls the spell-check feature. If false, the
service attempts to correct a misspelled query,
for example, "enginee" is corrected to "engineer".

Defaults to false: a spell check is performed.

=item * C<< $msg->employment_types() >> / C<< $msg->employment_types($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::EmploymentType>)

The employment type filter specifies the employment type of jobs to
search against, such as
[EmploymentType.FULL_TIME][google.cloud.talent.v4.EmploymentType.FULL_TIME].

If a value isn't specified, jobs in the search results includes any
employment type.

If multiple values are specified, jobs in the search results include
any of the specified employment types.

=item * C<< $msg->language_codes() >> / C<< $msg->language_codes($value) >>

Type: C<String>

This filter specifies the locale of jobs to search against,
for example, "en-US".

If a value isn't specified, the search results can contain jobs in any
locale.


Language codes should be in BCP-47 format, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47).

At most 10 language code filters are allowed.

=item * C<< $msg->publish_time_range() >> / C<< $msg->publish_time_range($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Common::TimestampRange>)

Jobs published within a range specified by this filter are searched
against.

=item * C<< $msg->excluded_jobs() >> / C<< $msg->excluded_jobs($value) >>

Type: C<String>

This filter specifies a list of job names to be excluded during search.

At most 400 excluded job names are allowed.

=back

=head2 Google::Cloud::Talent::V4::Filters::LocationFilter

Geographic region of the search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->address() >> / C<< $msg->address($value) >>

Type: C<String>

The address name, such as "Mountain View" or "Bay Area".

=item * C<< $msg->region_code() >> / C<< $msg->region_code($value) >>

Type: C<String>

CLDR region code of the country/region. This field may be used in two ways:

1) If telecommute preference is not set, this field is used address
ambiguity of the user-input address. For example, "Liverpool" may refer to
"Liverpool, NY, US" or "Liverpool, UK". This region code biases the
address resolution toward a specific country or territory. If this field is
not set, address resolution is biased toward the United States by default.

2) If telecommute preference is set to TELECOMMUTE_ALLOWED, the
telecommute location filter will be limited to the region specified in this
field. If this field is not set, the telecommute job locations will not be

See
https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/territory_information.html
for details. Example: "CH" for Switzerland.

=item * C<< $msg->lat_lng() >> / C<< $msg->lat_lng($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

The latitude and longitude of the geographic center to search from. This
field is ignored if `address` is provided.

=item * C<< $msg->distance_in_miles() >> / C<< $msg->distance_in_miles($value) >>

Type: C<Double>

The distance_in_miles is applied when the location being searched for is
identified as a city or smaller. This field is ignored if the location
being searched for is a state or larger.

=item * C<< $msg->telecommute_preference() >> / C<< $msg->telecommute_preference($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::LocationFilter::TelecommutePreference>)

Allows the client to return jobs without a
set location, specifically, telecommuting jobs (telecommuting is considered
by the service as a special location).
[Job.posting_region][google.cloud.talent.v4.Job.posting_region] indicates
if a job permits telecommuting. If this field is set to
[TelecommutePreference.TELECOMMUTE_ALLOWED][google.cloud.talent.v4.LocationFilter.TelecommutePreference.TELECOMMUTE_ALLOWED],
telecommuting jobs are searched, and
[address][google.cloud.talent.v4.LocationFilter.address] and
[lat_lng][google.cloud.talent.v4.LocationFilter.lat_lng] are ignored. If
not set or set to
[TelecommutePreference.TELECOMMUTE_EXCLUDED][google.cloud.talent.v4.LocationFilter.TelecommutePreference.TELECOMMUTE_EXCLUDED],
the telecommute status of the jobs is ignored. Jobs that have
[PostingRegion.TELECOMMUTE][google.cloud.talent.v4.PostingRegion.TELECOMMUTE]
and have additional [Job.addresses][google.cloud.talent.v4.Job.addresses]
may still be matched based on other location filters using
[address][google.cloud.talent.v4.LocationFilter.address] or
[lat_lng][google.cloud.talent.v4.LocationFilter.lat_lng].

This filter can be used by itself to search exclusively for telecommuting
jobs, or it can be combined with another location
filter to search for a combination of job locations,
such as "Mountain View" or "telecommuting" jobs. However, when used in
combination with other location filters, telecommuting jobs can be
treated as less relevant than other jobs in the search response.

This field is only used for job search requests.

=back

=head3 Enum: LocationFilter::TelecommutePreference

=over 4

=item * C<TELECOMMUTE_PREFERENCE_UNSPECIFIED> => C<0>

=item * C<TELECOMMUTE_EXCLUDED> => C<1>

=item * C<TELECOMMUTE_ALLOWED> => C<2>

=item * C<TELECOMMUTE_JOBS_EXCLUDED> => C<3>

=back

=head2 Google::Cloud::Talent::V4::Filters::CompensationFilter

Filter on job compensation type and amount.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CompensationFilter::FilterType>)

Required. Type of filter.

=item * C<< $msg->units() >> / C<< $msg->units($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CompensationInfo::CompensationUnit>)

Required. Specify desired `base compensation entry's`
[CompensationInfo.CompensationUnit][google.cloud.talent.v4.CompensationInfo.CompensationUnit].

=item * C<< $msg->range() >> / C<< $msg->range($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Common::CompensationInfo::CompensationRange>)

Compensation range.

=item * C<< $msg->include_jobs_with_unspecified_compensation_range() >> / C<< $msg->include_jobs_with_unspecified_compensation_range($value) >>

Type: C<Bool>

If set to true, jobs with unspecified compensation range fields are
included.

=back

=head3 Enum: CompensationFilter::FilterType

=over 4

=item * C<FILTER_TYPE_UNSPECIFIED> => C<0>

=item * C<UNIT_ONLY> => C<1>

=item * C<UNIT_AND_AMOUNT> => C<2>

=item * C<ANNUALIZED_BASE_AMOUNT> => C<3>

=item * C<ANNUALIZED_TOTAL_AMOUNT> => C<4>

=back

=head2 Google::Cloud::Talent::V4::Filters::CommuteFilter

Parameters needed for commute search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->commute_method() >> / C<< $msg->commute_method($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CommuteMethod>)

Required. The method of transportation to calculate the commute time for.

=item * C<< $msg->start_coordinates() >> / C<< $msg->start_coordinates($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

Required. The latitude and longitude of the location to calculate the
commute time from.

=item * C<< $msg->travel_duration() >> / C<< $msg->travel_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The maximum travel time in seconds. The maximum allowed value is
`3600s` (one hour). Format is `123s`.

=item * C<< $msg->allow_imprecise_addresses() >> / C<< $msg->allow_imprecise_addresses($value) >>

Type: C<Bool>

If `true`, jobs without street level addresses may also be returned.
For city level addresses, the city center is used. For state and coarser
level addresses, text matching is used.
If this field is set to `false` or isn't specified, only jobs that include
street level addresses will be returned by commute search.

=item * C<< $msg->road_traffic() >> / C<< $msg->road_traffic($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CommuteFilter::RoadTraffic>)

Specifies the traffic density to use when calculating commute time.

=item * C<< $msg->departure_time() >> / C<< $msg->departure_time($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

The departure time used to calculate traffic impact, represented as
[google.type.TimeOfDay][google.type.TimeOfDay] in local time zone.

Currently traffic model is restricted to hour level resolution.

=back

=head3 Enum: CommuteFilter::RoadTraffic

=over 4

=item * C<ROAD_TRAFFIC_UNSPECIFIED> => C<0>

=item * C<TRAFFIC_FREE> => C<1>

=item * C<BUSY_HOUR> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::Filters::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
