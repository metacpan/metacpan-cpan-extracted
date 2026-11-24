package Google::Datastore::V1beta3::Datastore;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Datastore::V1beta3::Entity };
    eval { require Google::Datastore::V1beta3::Query };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvZGF0YXN0b3JlL3YxYmV0YTMvZGF0YXN0b3JlLnByb3RvEhhnb29nbGUuZGF0
YXN0b3JlLnYxYmV0YTMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aJWdvb2dsZS9k
YXRhc3RvcmUvdjFiZXRhMy9lbnRpdHkucHJvdG8aJGdvb2dsZS9kYXRhc3RvcmUvdjFiZXRh
My9xdWVyeS5wcm90byKrAQoNTG9va3VwUmVxdWVzdBIdCgpwcm9qZWN0X2lkGAggASgJUglw
cm9qZWN0SWQSSAoMcmVhZF9vcHRpb25zGAEgASgLMiUuZ29vZ2xlLmRhdGFzdG9yZS52MWJl
dGEzLlJlYWRPcHRpb25zUgtyZWFkT3B0aW9ucxIxCgRrZXlzGAMgAygLMh0uZ29vZ2xlLmRh
dGFzdG9yZS52MWJldGEzLktleVIEa2V5cyLLAQoOTG9va3VwUmVzcG9uc2USPAoFZm91bmQY
ASADKAsyJi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRW50aXR5UmVzdWx0UgVmb3VuZBJA
CgdtaXNzaW5nGAIgAygLMiYuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkVudGl0eVJlc3Vs
dFIHbWlzc2luZxI5CghkZWZlcnJlZBgDIAMoCzIdLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRh
My5LZXlSCGRlZmVycmVkIs4CCg9SdW5RdWVyeVJlcXVlc3QSHQoKcHJvamVjdF9pZBgIIAEo
CVIJcHJvamVjdElkEkgKDHBhcnRpdGlvbl9pZBgCIAEoCzIlLmdvb2dsZS5kYXRhc3RvcmUu
djFiZXRhMy5QYXJ0aXRpb25JZFILcGFydGl0aW9uSWQSSAoMcmVhZF9vcHRpb25zGAEgASgL
MiUuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLlJlYWRPcHRpb25zUgtyZWFkT3B0aW9ucxI3
CgVxdWVyeRgDIAEoCzIfLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5RdWVyeUgAUgVxdWVy
eRJBCglncWxfcXVlcnkYByABKAsyIi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuR3FsUXVl
cnlIAFIIZ3FsUXVlcnlCDAoKcXVlcnlfdHlwZSKLAQoQUnVuUXVlcnlSZXNwb25zZRJACgVi
YXRjaBgBIAEoCzIqLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5RdWVyeVJlc3VsdEJhdGNo
UgViYXRjaBI1CgVxdWVyeRgCIAEoCzIfLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5RdWVy
eVIFcXVlcnkilwEKF0JlZ2luVHJhbnNhY3Rpb25SZXF1ZXN0Eh0KCnByb2plY3RfaWQYCCAB
KAlSCXByb2plY3RJZBJdChN0cmFuc2FjdGlvbl9vcHRpb25zGAogASgLMiwuZ29vZ2xlLmRh
dGFzdG9yZS52MWJldGEzLlRyYW5zYWN0aW9uT3B0aW9uc1ISdHJhbnNhY3Rpb25PcHRpb25z
IjwKGEJlZ2luVHJhbnNhY3Rpb25SZXNwb25zZRIgCgt0cmFuc2FjdGlvbhgBIAEoDFILdHJh
bnNhY3Rpb24iUgoPUm9sbGJhY2tSZXF1ZXN0Eh0KCnByb2plY3RfaWQYCCABKAlSCXByb2pl
Y3RJZBIgCgt0cmFuc2FjdGlvbhgBIAEoDFILdHJhbnNhY3Rpb24iEgoQUm9sbGJhY2tSZXNw
b25zZSK2AgoNQ29tbWl0UmVxdWVzdBIdCgpwcm9qZWN0X2lkGAggASgJUglwcm9qZWN0SWQS
QAoEbW9kZRgFIAEoDjIsLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5Db21taXRSZXF1ZXN0
Lk1vZGVSBG1vZGUSIgoLdHJhbnNhY3Rpb24YASABKAxIAFILdHJhbnNhY3Rpb24SQAoJbXV0
YXRpb25zGAYgAygLMiIuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLk11dGF0aW9uUgltdXRh
dGlvbnMiRgoETW9kZRIUChBNT0RFX1VOU1BFQ0lGSUVEEAASEQoNVFJBTlNBQ1RJT05BTBAB
EhUKEU5PTl9UUkFOU0FDVElPTkFMEAJCFgoUdHJhbnNhY3Rpb25fc2VsZWN0b3IiigEKDkNv
bW1pdFJlc3BvbnNlElMKEG11dGF0aW9uX3Jlc3VsdHMYAyADKAsyKC5nb29nbGUuZGF0YXN0
b3JlLnYxYmV0YTMuTXV0YXRpb25SZXN1bHRSD211dGF0aW9uUmVzdWx0cxIjCg1pbmRleF91
cGRhdGVzGAQgASgFUgxpbmRleFVwZGF0ZXMiZgoSQWxsb2NhdGVJZHNSZXF1ZXN0Eh0KCnBy
b2plY3RfaWQYCCABKAlSCXByb2plY3RJZBIxCgRrZXlzGAEgAygLMh0uZ29vZ2xlLmRhdGFz
dG9yZS52MWJldGEzLktleVIEa2V5cyJIChNBbGxvY2F0ZUlkc1Jlc3BvbnNlEjEKBGtleXMY
ASADKAsyHS5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuS2V5UgRrZXlzIoYBChFSZXNlcnZl
SWRzUmVxdWVzdBIdCgpwcm9qZWN0X2lkGAggASgJUglwcm9qZWN0SWQSHwoLZGF0YWJhc2Vf
aWQYCSABKAlSCmRhdGFiYXNlSWQSMQoEa2V5cxgBIAMoCzIdLmdvb2dsZS5kYXRhc3RvcmUu
djFiZXRhMy5LZXlSBGtleXMiFAoSUmVzZXJ2ZUlkc1Jlc3BvbnNlIsgCCghNdXRhdGlvbhI6
CgZpbnNlcnQYBCABKAsyIC5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRW50aXR5SABSBmlu
c2VydBI6CgZ1cGRhdGUYBSABKAsyIC5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRW50aXR5
SABSBnVwZGF0ZRI6CgZ1cHNlcnQYBiABKAsyIC5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMu
RW50aXR5SABSBnVwc2VydBI3CgZkZWxldGUYByABKAsyHS5nb29nbGUuZGF0YXN0b3JlLnYx
YmV0YTMuS2V5SABSBmRlbGV0ZRIjCgxiYXNlX3ZlcnNpb24YCCABKANIAVILYmFzZVZlcnNp
b25CCwoJb3BlcmF0aW9uQh0KG2NvbmZsaWN0X2RldGVjdGlvbl9zdHJhdGVneSKIAQoOTXV0
YXRpb25SZXN1bHQSLwoDa2V5GAMgASgLMh0uZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLktl
eVIDa2V5EhgKB3ZlcnNpb24YBCABKANSB3ZlcnNpb24SKwoRY29uZmxpY3RfZGV0ZWN0ZWQY
BSABKAhSEGNvbmZsaWN0RGV0ZWN0ZWQi+AEKC1JlYWRPcHRpb25zEmIKEHJlYWRfY29uc2lz
dGVuY3kYASABKA4yNS5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuUmVhZE9wdGlvbnMuUmVh
ZENvbnNpc3RlbmN5SABSD3JlYWRDb25zaXN0ZW5jeRIiCgt0cmFuc2FjdGlvbhgCIAEoDEgA
Ugt0cmFuc2FjdGlvbiJNCg9SZWFkQ29uc2lzdGVuY3kSIAocUkVBRF9DT05TSVNURU5DWV9V
TlNQRUNJRklFRBAAEgoKBlNUUk9ORxABEgwKCEVWRU5UVUFMEAJCEgoQY29uc2lzdGVuY3lf
dHlwZSKXAgoSVHJhbnNhY3Rpb25PcHRpb25zElcKCnJlYWRfd3JpdGUYASABKAsyNi5nb29n
bGUuZGF0YXN0b3JlLnYxYmV0YTMuVHJhbnNhY3Rpb25PcHRpb25zLlJlYWRXcml0ZUgAUgly
ZWFkV3JpdGUSVAoJcmVhZF9vbmx5GAIgASgLMjUuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEz
LlRyYW5zYWN0aW9uT3B0aW9ucy5SZWFkT25seUgAUghyZWFkT25seRo+CglSZWFkV3JpdGUS
MQoUcHJldmlvdXNfdHJhbnNhY3Rpb24YASABKAxSE3ByZXZpb3VzVHJhbnNhY3Rpb24aCgoI
UmVhZE9ubHlCBgoEbW9kZTLXCAoJRGF0YXN0b3JlEo0BCgZMb29rdXASJy5nb29nbGUuZGF0
YXN0b3JlLnYxYmV0YTMuTG9va3VwUmVxdWVzdBooLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRh
My5Mb29rdXBSZXNwb25zZSIwgtPkkwIqIiUvdjFiZXRhMy9wcm9qZWN0cy97cHJvamVjdF9p
ZH06bG9va3VwOgEqEpUBCghSdW5RdWVyeRIpLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5S
dW5RdWVyeVJlcXVlc3QaKi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuUnVuUXVlcnlSZXNw
b25zZSIygtPkkwIsIicvdjFiZXRhMy9wcm9qZWN0cy97cHJvamVjdF9pZH06cnVuUXVlcnk6
ASoStQEKEEJlZ2luVHJhbnNhY3Rpb24SMS5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuQmVn
aW5UcmFuc2FjdGlvblJlcXVlc3QaMi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuQmVnaW5U
cmFuc2FjdGlvblJlc3BvbnNlIjqC0+STAjQiLy92MWJldGEzL3Byb2plY3RzL3twcm9qZWN0
X2lkfTpiZWdpblRyYW5zYWN0aW9uOgEqEo0BCgZDb21taXQSJy5nb29nbGUuZGF0YXN0b3Jl
LnYxYmV0YTMuQ29tbWl0UmVxdWVzdBooLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5Db21t
aXRSZXNwb25zZSIwgtPkkwIqIiUvdjFiZXRhMy9wcm9qZWN0cy97cHJvamVjdF9pZH06Y29t
bWl0OgEqEpUBCghSb2xsYmFjaxIpLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5Sb2xsYmFj
a1JlcXVlc3QaKi5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuUm9sbGJhY2tSZXNwb25zZSIy
gtPkkwIsIicvdjFiZXRhMy9wcm9qZWN0cy97cHJvamVjdF9pZH06cm9sbGJhY2s6ASoSoQEK
C0FsbG9jYXRlSWRzEiwuZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkFsbG9jYXRlSWRzUmVx
dWVzdBotLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5BbGxvY2F0ZUlkc1Jlc3BvbnNlIjWC
0+STAi8iKi92MWJldGEzL3Byb2plY3RzL3twcm9qZWN0X2lkfTphbGxvY2F0ZUlkczoBKhKd
AQoKUmVzZXJ2ZUlkcxIrLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5SZXNlcnZlSWRzUmVx
dWVzdBosLmdvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5SZXNlcnZlSWRzUmVzcG9uc2UiNILT
5JMCLiIpL3YxYmV0YTMvcHJvamVjdHMve3Byb2plY3RfaWR9OnJlc2VydmVJZHM6ASpC2AEK
HGNvbS5nb29nbGUuZGF0YXN0b3JlLnYxYmV0YTNCDkRhdGFzdG9yZVByb3RvUAFaQGNsb3Vk
Lmdvb2dsZS5jb20vZ28vZGF0YXN0b3JlL2FwaXYxYmV0YTMvZGF0YXN0b3JlcGI7ZGF0YXN0
b3JlcGKqAh5Hb29nbGUuQ2xvdWQuRGF0YXN0b3JlLlYxQmV0YTPKAh5Hb29nbGVcQ2xvdWRc
RGF0YXN0b3JlXFYxYmV0YTPqAiFHb29nbGU6OkNsb3VkOjpEYXRhc3RvcmU6OlYxYmV0YTNK
zGoKBxIFDgCWAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACEKCQoCAwASAxIAJgoJCgIDARIDEwAvCgkKAgMCEgMUAC4KCAoBCBIDFgA7CgkKAgglEgMW
ADsKCAoBCBIDFwBXCgkKAggLEgMXAFcKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAv
CgkKAggIEgMZAC8KCAoBCBIDGgA1CgkKAggBEgMaADUKCAoBCBIDGwA7CgkKAggpEgMbADsK
CAoBCBIDHAA6CgkKAggtEgMcADoKlQMKAgYAEgQlAGEBGogDIEVhY2ggUlBDIG5vcm1hbGl6
ZXMgdGhlIHBhcnRpdGlvbiBJRHMgb2YgdGhlIGtleXMgaW4gaXRzIGlucHV0IGVudGl0aWVz
LAogYW5kIGFsd2F5cyByZXR1cm5zIGVudGl0aWVzIHdpdGgga2V5cyB3aXRoIG5vcm1hbGl6
ZWQgcGFydGl0aW9uIElEcy4KIFRoaXMgYXBwbGllcyB0byBhbGwga2V5cyBhbmQgZW50aXRp
ZXMsIGluY2x1ZGluZyB0aG9zZSBpbiB2YWx1ZXMsIGV4Y2VwdCBrZXlzCiB3aXRoIGJvdGgg
YW4gZW1wdHkgcGF0aCBhbmQgYW4gZW1wdHkgb3IgdW5zZXQgcGFydGl0aW9uIElELiBOb3Jt
YWxpemF0aW9uIG9mCiBpbnB1dCBrZXlzIHNldHMgdGhlIHByb2plY3QgSUQgKGlmIG5vdCBh
bHJlYWR5IHNldCkgdG8gdGhlIHByb2plY3QgSUQgZnJvbQogdGhlIHJlcXVlc3QuCgoKCgoD
BgABEgMlCBEKKQoEBgACABIEJwIsAxobIExvb2tzIHVwIGVudGl0aWVzIGJ5IGtleS4KCgwK
BQYAAgABEgMnBgwKDAoFBgACAAISAycNGgoMCgUGAAIAAxIDJyUzCg0KBQYAAgAEEgQoBCsG
ChEKCQYAAgAEsMq8IhIEKAQrBgolCgQGAAIBEgQvAjQDGhcgUXVlcmllcyBmb3IgZW50aXRp
ZXMuCgoMCgUGAAIBARIDLwYOCgwKBQYAAgECEgMvDx4KDAoFBgACAQMSAy8pOQoNCgUGAAIB
BBIEMAQzBgoRCgkGAAIBBLDKvCISBDAEMwYKKQoEBgACAhIENwI9AxobIEJlZ2lucyBhIG5l
dyB0cmFuc2FjdGlvbi4KCgwKBQYAAgIBEgM3BhYKDAoFBgACAgISAzcXLgoMCgUGAAICAxID
OA8nCg0KBQYAAgIEEgQ5BDwGChEKCQYAAgIEsMq8IhIEOQQ8BgphCgQGAAIDEgRBAkYDGlMg
Q29tbWl0cyBhIHRyYW5zYWN0aW9uLCBvcHRpb25hbGx5IGNyZWF0aW5nLCBkZWxldGluZyBv
ciBtb2RpZnlpbmcgc29tZQogZW50aXRpZXMuCgoMCgUGAAIDARIDQQYMCgwKBQYAAgMCEgNB
DRoKDAoFBgACAwMSA0ElMwoNCgUGAAIDBBIEQgRFBgoRCgkGAAIDBLDKvCISBEIERQYKKQoE
BgACBBIESQJOAxobIFJvbGxzIGJhY2sgYSB0cmFuc2FjdGlvbi4KCgwKBQYAAgQBEgNJBg4K
DAoFBgACBAISA0kPHgoMCgUGAAIEAxIDSSk5Cg0KBQYAAgQEEgRKBE0GChEKCQYAAgQEsMq8
IhIESgRNBgpzCgQGAAIFEgRSAlcDGmUgQWxsb2NhdGVzIElEcyBmb3IgdGhlIGdpdmVuIGtl
eXMsIHdoaWNoIGlzIHVzZWZ1bCBmb3IgcmVmZXJlbmNpbmcgYW4gZW50aXR5CiBiZWZvcmUg
aXQgaXMgaW5zZXJ0ZWQuCgoMCgUGAAIFARIDUgYRCgwKBQYAAgUCEgNSEiQKDAoFBgACBQMS
A1IvQgoNCgUGAAIFBBIEUwRWBgoRCgkGAAIFBLDKvCISBFMEVgYKXgoEBgACBhIEWwJgAxpQ
IFByZXZlbnRzIHRoZSBzdXBwbGllZCBrZXlzJyBJRHMgZnJvbSBiZWluZyBhdXRvLWFsbG9j
YXRlZCBieSBDbG91ZAogRGF0YXN0b3JlLgoKDAoFBgACBgESA1sGEAoMCgUGAAIGAhIDWxEi
CgwKBQYAAgYDEgNbLT8KDQoFBgACBgQSBFwEXwYKEQoJBgACBgSwyrwiEgRcBF8GCl0KAgQA
EgRlAG4BGlEgVGhlIHJlcXVlc3QgZm9yCiBbRGF0YXN0b3JlLkxvb2t1cF1bZ29vZ2xlLmRh
dGFzdG9yZS52MWJldGEzLkRhdGFzdG9yZS5Mb29rdXBdLgoKCgoDBAABEgNlCBUKRwoEBAAC
ABIDZwIYGjogVGhlIElEIG9mIHRoZSBwcm9qZWN0IGFnYWluc3Qgd2hpY2ggdG8gbWFrZSB0
aGUgcmVxdWVzdC4KCgwKBQQAAgAFEgNnAggKDAoFBAACAAESA2cJEwoMCgUEAAIAAxIDZxYX
CjMKBAQAAgESA2oCHxomIFRoZSBvcHRpb25zIGZvciB0aGlzIGxvb2t1cCByZXF1ZXN0LgoK
DAoFBAACAQYSA2oCDQoMCgUEAAIBARIDag4aCgwKBQQAAgEDEgNqHR4KKwoEBAACAhIDbQIY
Gh4gS2V5cyBvZiBlbnRpdGllcyB0byBsb29rIHVwLgoKDAoFBAACAgQSA20CCgoMCgUEAAIC
BhIDbQsOCgwKBQQAAgIBEgNtDxMKDAoFBAACAgMSA20WFwpfCgIEARIFcgCBAQEaUiBUaGUg
cmVzcG9uc2UgZm9yCiBbRGF0YXN0b3JlLkxvb2t1cF1bZ29vZ2xlLmRhdGFzdG9yZS52MWJl
dGEzLkRhdGFzdG9yZS5Mb29rdXBdLgoKCgoDBAEBEgNyCBYKqgEKBAQBAgASA3YCIhqcASBF
bnRpdGllcyBmb3VuZCBhcyBgUmVzdWx0VHlwZS5GVUxMYCBlbnRpdGllcy4gVGhlIG9yZGVy
IG9mIHJlc3VsdHMgaW4gdGhpcwogZmllbGQgaXMgdW5kZWZpbmVkIGFuZCBoYXMgbm8gcmVs
YXRpb24gdG8gdGhlIG9yZGVyIG9mIHRoZSBrZXlzIGluIHRoZQogaW5wdXQuCgoMCgUEAQIA
BBIDdgIKCgwKBQQBAgAGEgN2CxcKDAoFBAECAAESA3YYHQoMCgUEAQIAAxIDdiAhCrIBCgQE
AQIBEgN7AiQapAEgRW50aXRpZXMgbm90IGZvdW5kIGFzIGBSZXN1bHRUeXBlLktFWV9PTkxZ
YCBlbnRpdGllcy4gVGhlIG9yZGVyIG9mIHJlc3VsdHMKIGluIHRoaXMgZmllbGQgaXMgdW5k
ZWZpbmVkIGFuZCBoYXMgbm8gcmVsYXRpb24gdG8gdGhlIG9yZGVyIG9mIHRoZSBrZXlzCiBp
biB0aGUgaW5wdXQuCgoMCgUEAQIBBBIDewIKCgwKBQQBAgEGEgN7CxcKDAoFBAECAQESA3sY
HwoMCgUEAQIBAxIDeyIjCsEBCgQEAQICEgSAAQIcGrIBIEEgbGlzdCBvZiBrZXlzIHRoYXQg
d2VyZSBub3QgbG9va2VkIHVwIGR1ZSB0byByZXNvdXJjZSBjb25zdHJhaW50cy4gVGhlCiBv
cmRlciBvZiByZXN1bHRzIGluIHRoaXMgZmllbGQgaXMgdW5kZWZpbmVkIGFuZCBoYXMgbm8g
cmVsYXRpb24gdG8gdGhlCiBvcmRlciBvZiB0aGUga2V5cyBpbiB0aGUgaW5wdXQuCgoNCgUE
AQICBBIEgAECCgoNCgUEAQICBhIEgAELDgoNCgUEAQICARIEgAEPFwoNCgUEAQICAxIEgAEa
GwpjCgIEAhIGhQEAmgEBGlUgVGhlIHJlcXVlc3QgZm9yCiBbRGF0YXN0b3JlLlJ1blF1ZXJ5
XVtnb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRGF0YXN0b3JlLlJ1blF1ZXJ5XS4KCgsKAwQC
ARIEhQEIFwpICgQEAgIAEgSHAQIYGjogVGhlIElEIG9mIHRoZSBwcm9qZWN0IGFnYWluc3Qg
d2hpY2ggdG8gbWFrZSB0aGUgcmVxdWVzdC4KCg0KBQQCAgAFEgSHAQIICg0KBQQCAgABEgSH
AQkTCg0KBQQCAgADEgSHARYXCtIBCgQEAgIBEgSNAQIfGsMBIEVudGl0aWVzIGFyZSBwYXJ0
aXRpb25lZCBpbnRvIHN1YnNldHMsIGlkZW50aWZpZWQgYnkgYSBwYXJ0aXRpb24gSUQuCiBR
dWVyaWVzIGFyZSBzY29wZWQgdG8gYSBzaW5nbGUgcGFydGl0aW9uLgogVGhpcyBwYXJ0aXRp
b24gSUQgaXMgbm9ybWFsaXplZCB3aXRoIHRoZSBzdGFuZGFyZCBkZWZhdWx0IGNvbnRleHQK
IHBhcnRpdGlvbiBJRC4KCg0KBQQCAgEGEgSNAQINCg0KBQQCAgEBEgSNAQ4aCg0KBQQCAgED
EgSNAR0eCisKBAQCAgISBJABAh8aHSBUaGUgb3B0aW9ucyBmb3IgdGhpcyBxdWVyeS4KCg0K
BQQCAgIGEgSQAQINCg0KBQQCAgIBEgSQAQ4aCg0KBQQCAgIDEgSQAR0eCiQKBAQCCAASBpMB
ApkBAxoUIFRoZSB0eXBlIG9mIHF1ZXJ5LgoKDQoFBAIIAAESBJMBCBIKIQoEBAICAxIElQEE
FBoTIFRoZSBxdWVyeSB0byBydW4uCgoNCgUEAgIDBhIElQEECQoNCgUEAgIDARIElQEKDwoN
CgUEAgIDAxIElQESEwolCgQEAgIEEgSYAQQbGhcgVGhlIEdRTCBxdWVyeSB0byBydW4uCgoN
CgUEAgIEBhIEmAEEDAoNCgUEAgIEARIEmAENFgoNCgUEAgIEAxIEmAEZGgpkCgIEAxIGngEA
pAEBGlYgVGhlIHJlc3BvbnNlIGZvcgogW0RhdGFzdG9yZS5SdW5RdWVyeV1bZ29vZ2xlLmRh
dGFzdG9yZS52MWJldGEzLkRhdGFzdG9yZS5SdW5RdWVyeV0uCgoLCgMEAwESBJ4BCBgKOgoE
BAMCABIEoAECHRosIEEgYmF0Y2ggb2YgcXVlcnkgcmVzdWx0cyAoYWx3YXlzIHByZXNlbnQp
LgoKDQoFBAMCAAYSBKABAhIKDQoFBAMCAAESBKABExgKDQoFBAMCAAMSBKABGxwKUgoEBAMC
ARIEowECEhpEIFRoZSBwYXJzZWQgZm9ybSBvZiB0aGUgYEdxbFF1ZXJ5YCBmcm9tIHRoZSBy
ZXF1ZXN0LCBpZiBpdCB3YXMgc2V0LgoKDQoFBAMCAQYSBKMBAgcKDQoFBAMCAQESBKMBCA0K
DQoFBAMCAQMSBKMBEBEKcwoCBAQSBqgBAK4BARplIFRoZSByZXF1ZXN0IGZvcgogW0RhdGFz
dG9yZS5CZWdpblRyYW5zYWN0aW9uXVtnb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRGF0YXN0
b3JlLkJlZ2luVHJhbnNhY3Rpb25dLgoKCwoDBAQBEgSoAQgfCkgKBAQEAgASBKoBAhgaOiBU
aGUgSUQgb2YgdGhlIHByb2plY3QgYWdhaW5zdCB3aGljaCB0byBtYWtlIHRoZSByZXF1ZXN0
LgoKDQoFBAQCAAUSBKoBAggKDQoFBAQCAAESBKoBCRMKDQoFBAQCAAMSBKoBFhcKLgoEBAQC
ARIErQECLhogIE9wdGlvbnMgZm9yIGEgbmV3IHRyYW5zYWN0aW9uLgoKDQoFBAQCAQYSBK0B
AhQKDQoFBAQCAQESBK0BFSgKDQoFBAQCAQMSBK0BKy0KdAoCBAUSBrIBALUBARpmIFRoZSBy
ZXNwb25zZSBmb3IKIFtEYXRhc3RvcmUuQmVnaW5UcmFuc2FjdGlvbl1bZ29vZ2xlLmRhdGFz
dG9yZS52MWJldGEzLkRhdGFzdG9yZS5CZWdpblRyYW5zYWN0aW9uXS4KCgsKAwQFARIEsgEI
IAo8CgQEBQIAEgS0AQIYGi4gVGhlIHRyYW5zYWN0aW9uIGlkZW50aWZpZXIgKGFsd2F5cyBw
cmVzZW50KS4KCg0KBQQFAgAFEgS0AQIHCg0KBQQFAgABEgS0AQgTCg0KBQQFAgADEgS0ARYX
CmMKAgQGEga5AQDAAQEaVSBUaGUgcmVxdWVzdCBmb3IKIFtEYXRhc3RvcmUuUm9sbGJhY2td
W2dvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5EYXRhc3RvcmUuUm9sbGJhY2tdLgoKCwoDBAYB
EgS5AQgXCkgKBAQGAgASBLsBAhgaOiBUaGUgSUQgb2YgdGhlIHByb2plY3QgYWdhaW5zdCB3
aGljaCB0byBtYWtlIHRoZSByZXF1ZXN0LgoKDQoFBAYCAAUSBLsBAggKDQoFBAYCAAESBLsB
CRMKDQoFBAYCAAMSBLsBFhcKlgEKBAQGAgESBL8BAhgahwEgVGhlIHRyYW5zYWN0aW9uIGlk
ZW50aWZpZXIsIHJldHVybmVkIGJ5IGEgY2FsbCB0bwogW0RhdGFzdG9yZS5CZWdpblRyYW5z
YWN0aW9uXVtnb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRGF0YXN0b3JlLkJlZ2luVHJhbnNh
Y3Rpb25dLgoKDQoFBAYCAQUSBL8BAgcKDQoFBAYCAQESBL8BCBMKDQoFBAYCAQMSBL8BFhcK
dwoCBAcSBMUBABsaayBUaGUgcmVzcG9uc2UgZm9yCiBbRGF0YXN0b3JlLlJvbGxiYWNrXVtn
b29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRGF0YXN0b3JlLlJvbGxiYWNrXS4gKGFuIGVtcHR5
CiBtZXNzYWdlKS4KCgsKAwQHARIExQEIGApfCgIECBIGyQEA9AEBGlEgVGhlIHJlcXVlc3Qg
Zm9yCiBbRGF0YXN0b3JlLkNvbW1pdF1bZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkRhdGFz
dG9yZS5Db21taXRdLgoKCwoDBAgBEgTJAQgVCjIKBAQIBAASBssBAtYBAxoiIFRoZSBtb2Rl
cyBhdmFpbGFibGUgZm9yIGNvbW1pdHMuCgoNCgUECAQAARIEywEHCwo7CgYECAQAAgASBM0B
BBkaKyBVbnNwZWNpZmllZC4gVGhpcyB2YWx1ZSBtdXN0IG5vdCBiZSB1c2VkLgoKDwoHBAgE
AAIAARIEzQEEFAoPCgcECAQAAgACEgTNARcYCr4BCgYECAQAAgESBNIBBBYarQEgVHJhbnNh
Y3Rpb25hbDogVGhlIG11dGF0aW9ucyBhcmUgZWl0aGVyIGFsbCBhcHBsaWVkLCBvciBub25l
IGFyZSBhcHBsaWVkLgogTGVhcm4gYWJvdXQgdHJhbnNhY3Rpb25zCiBbaGVyZV0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2RhdGFzdG9yZS9kb2NzL2NvbmNlcHRzL3RyYW5zYWN0aW9u
cykuCgoPCgcECAQAAgEBEgTSAQQRCg8KBwQIBAACAQISBNIBFBUKUAoGBAgEAAICEgTVAQQa
GkAgTm9uLXRyYW5zYWN0aW9uYWw6IFRoZSBtdXRhdGlvbnMgbWF5IG5vdCBhcHBseSBhcyBh
bGwgb3Igbm9uZS4KCg8KBwQIBAACAgESBNUBBBUKDwoHBAgEAAICAhIE1QEYGQpICgQECAIA
EgTZAQIYGjogVGhlIElEIG9mIHRoZSBwcm9qZWN0IGFnYWluc3Qgd2hpY2ggdG8gbWFrZSB0
aGUgcmVxdWVzdC4KCg0KBQQIAgAFEgTZAQIICg0KBQQIAgABEgTZAQkTCg0KBQQIAgADEgTZ
ARYXCksKBAQIAgESBNwBAhAaPSBUaGUgdHlwZSBvZiBjb21taXQgdG8gcGVyZm9ybS4gRGVm
YXVsdHMgdG8gYFRSQU5TQUNUSU9OQUxgLgoKDQoFBAgCAQYSBNwBAgYKDQoFBAgCAQESBNwB
BwsKDQoFBAgCAQMSBNwBDg8KOwoEBAgIABIG3wEC5AEDGisgTXVzdCBiZSBzZXQgd2hlbiBt
b2RlIGlzIGBUUkFOU0FDVElPTkFMYC4KCg0KBQQICAABEgTfAQgcCtUBCgQECAICEgTjAQQa
GsYBIFRoZSBpZGVudGlmaWVyIG9mIHRoZSB0cmFuc2FjdGlvbiBhc3NvY2lhdGVkIHdpdGgg
dGhlIGNvbW1pdC4gQQogdHJhbnNhY3Rpb24gaWRlbnRpZmllciBpcyByZXR1cm5lZCBieSBh
IGNhbGwgdG8KIFtEYXRhc3RvcmUuQmVnaW5UcmFuc2FjdGlvbl1bZ29vZ2xlLmRhdGFzdG9y
ZS52MWJldGEzLkRhdGFzdG9yZS5CZWdpblRyYW5zYWN0aW9uXS4KCg0KBQQIAgIFEgTjAQQJ
Cg0KBQQIAgIBEgTjAQoVCg0KBQQIAgIDEgTjARgZCswDCgQECAIDEgTzAQIiGr0DIFRoZSBt
dXRhdGlvbnMgdG8gcGVyZm9ybS4KCiBXaGVuIG1vZGUgaXMgYFRSQU5TQUNUSU9OQUxgLCBt
dXRhdGlvbnMgYWZmZWN0aW5nIGEgc2luZ2xlIGVudGl0eSBhcmUKIGFwcGxpZWQgaW4gb3Jk
ZXIuIFRoZSBmb2xsb3dpbmcgc2VxdWVuY2VzIG9mIG11dGF0aW9ucyBhZmZlY3RpbmcgYSBz
aW5nbGUKIGVudGl0eSBhcmUgbm90IHBlcm1pdHRlZCBpbiBhIHNpbmdsZSBgQ29tbWl0YCBy
ZXF1ZXN0OgoKIC0gYGluc2VydGAgZm9sbG93ZWQgYnkgYGluc2VydGAKIC0gYHVwZGF0ZWAg
Zm9sbG93ZWQgYnkgYGluc2VydGAKIC0gYHVwc2VydGAgZm9sbG93ZWQgYnkgYGluc2VydGAK
IC0gYGRlbGV0ZWAgZm9sbG93ZWQgYnkgYHVwZGF0ZWAKCiBXaGVuIG1vZGUgaXMgYE5PTl9U
UkFOU0FDVElPTkFMYCwgbm8gdHdvIG11dGF0aW9ucyBtYXkgYWZmZWN0IGEgc2luZ2xlCiBl
bnRpdHkuCgoNCgUECAIDBBIE8wECCgoNCgUECAIDBhIE8wELEwoNCgUECAIDARIE8wEUHQoN
CgUECAIDAxIE8wEgIQpgCgIECRIG+AEAgAIBGlIgVGhlIHJlc3BvbnNlIGZvcgogW0RhdGFz
dG9yZS5Db21taXRdW2dvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5EYXRhc3RvcmUuQ29tbWl0
XS4KCgsKAwQJARIE+AEIFgqCAQoEBAkCABIE+wECLxp0IFRoZSByZXN1bHQgb2YgcGVyZm9y
bWluZyB0aGUgbXV0YXRpb25zLgogVGhlIGktdGggbXV0YXRpb24gcmVzdWx0IGNvcnJlc3Bv
bmRzIHRvIHRoZSBpLXRoIG11dGF0aW9uIGluIHRoZSByZXF1ZXN0LgoKDQoFBAkCAAQSBPsB
AgoKDQoFBAkCAAYSBPsBCxkKDQoFBAkCAAESBPsBGioKDQoFBAkCAAMSBPsBLS4KZQoEBAkC
ARIE/wECGhpXIFRoZSBudW1iZXIgb2YgaW5kZXggZW50cmllcyB1cGRhdGVkIGR1cmluZyB0
aGUgY29tbWl0LCBvciB6ZXJvIGlmIG5vbmUgd2VyZQogdXBkYXRlZC4KCg0KBQQJAgEFEgT/
AQIHCg0KBQQJAgEBEgT/AQgVCg0KBQQJAgEDEgT/ARgZCmkKAgQKEgaEAgCLAgEaWyBUaGUg
cmVxdWVzdCBmb3IKIFtEYXRhc3RvcmUuQWxsb2NhdGVJZHNdW2dvb2dsZS5kYXRhc3RvcmUu
djFiZXRhMy5EYXRhc3RvcmUuQWxsb2NhdGVJZHNdLgoKCwoDBAoBEgSEAggaCkgKBAQKAgAS
BIYCAhgaOiBUaGUgSUQgb2YgdGhlIHByb2plY3QgYWdhaW5zdCB3aGljaCB0byBtYWtlIHRo
ZSByZXF1ZXN0LgoKDQoFBAoCAAUSBIYCAggKDQoFBAoCAAESBIYCCRMKDQoFBAoCAAMSBIYC
FhcKdgoEBAoCARIEigICGBpoIEEgbGlzdCBvZiBrZXlzIHdpdGggaW5jb21wbGV0ZSBrZXkg
cGF0aHMgZm9yIHdoaWNoIHRvIGFsbG9jYXRlIElEcy4KIE5vIGtleSBtYXkgYmUgcmVzZXJ2
ZWQvcmVhZC1vbmx5LgoKDQoFBAoCAQQSBIoCAgoKDQoFBAoCAQYSBIoCCw4KDQoFBAoCAQES
BIoCDxMKDQoFBAoCAQMSBIoCFhcKagoCBAsSBo8CAJMCARpcIFRoZSByZXNwb25zZSBmb3IK
IFtEYXRhc3RvcmUuQWxsb2NhdGVJZHNdW2dvb2dsZS5kYXRhc3RvcmUudjFiZXRhMy5EYXRh
c3RvcmUuQWxsb2NhdGVJZHNdLgoKCwoDBAsBEgSPAggbCoMBCgQECwIAEgSSAgIYGnUgVGhl
IGtleXMgc3BlY2lmaWVkIGluIHRoZSByZXF1ZXN0IChpbiB0aGUgc2FtZSBvcmRlciksIGVh
Y2ggd2l0aAogaXRzIGtleSBwYXRoIGNvbXBsZXRlZCB3aXRoIGEgbmV3bHkgYWxsb2NhdGVk
IElELgoKDQoFBAsCAAQSBJICAgoKDQoFBAsCAAYSBJICCw4KDQoFBAsCAAESBJICDxMKDQoF
BAsCAAMSBJICFhcKZwoCBAwSBpcCAKECARpZIFRoZSByZXF1ZXN0IGZvcgogW0RhdGFzdG9y
ZS5SZXNlcnZlSWRzXVtnb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRGF0YXN0b3JlLlJlc2Vy
dmVJZHNdLgoKCwoDBAwBEgSXAggZCkgKBAQMAgASBJkCAhgaOiBUaGUgSUQgb2YgdGhlIHBy
b2plY3QgYWdhaW5zdCB3aGljaCB0byBtYWtlIHRoZSByZXF1ZXN0LgoKDQoFBAwCAAUSBJkC
AggKDQoFBAwCAAESBJkCCRMKDQoFBAwCAAMSBJkCFhcKVwoEBAwCARIEnAICGRpJIElmIG5v
dCBlbXB0eSwgdGhlIElEIG9mIHRoZSBkYXRhYmFzZSBhZ2FpbnN0IHdoaWNoIHRvIG1ha2Ug
dGhlIHJlcXVlc3QuCgoNCgUEDAIBBRIEnAICCAoNCgUEDAIBARIEnAIJFAoNCgUEDAIBAxIE
nAIXGApnCgQEDAICEgSgAgIYGlkgQSBsaXN0IG9mIGtleXMgd2l0aCBjb21wbGV0ZSBrZXkg
cGF0aHMgd2hvc2UgbnVtZXJpYyBJRHMgc2hvdWxkIG5vdCBiZQogYXV0by1hbGxvY2F0ZWQu
CgoNCgUEDAICBBIEoAICCgoNCgUEDAICBhIEoAILDgoNCgUEDAICARIEoAIPEwoNCgUEDAIC
AxIEoAIWFwpmCgIEDRIEpQIAHRpaIFRoZSByZXNwb25zZSBmb3IKIFtEYXRhc3RvcmUuUmVz
ZXJ2ZUlkc11bZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEzLkRhdGFzdG9yZS5SZXNlcnZlSWRz
XS4KCgsKAwQNARIEpQIIGgoxCgIEDhIGqAIAywIBGiMgQSBtdXRhdGlvbiB0byBhcHBseSB0
byBhbiBlbnRpdHkuCgoLCgMEDgESBKgCCBAKzwIKBAQOCAASBrECAsECAxq+AiBUaGUgbXV0
YXRpb24gb3BlcmF0aW9uLgoKIEZvciBgaW5zZXJ0YCwgYHVwZGF0ZWAsIGFuZCBgdXBzZXJ0
YDoKIC0gVGhlIGVudGl0eSdzIGtleSBtdXN0IG5vdCBiZSByZXNlcnZlZC9yZWFkLW9ubHku
CiAtIE5vIHByb3BlcnR5IGluIHRoZSBlbnRpdHkgbWF5IGhhdmUgYSByZXNlcnZlZCBuYW1l
LAogICBub3QgZXZlbiBhIHByb3BlcnR5IGluIGFuIGVudGl0eSBpbiBhIHZhbHVlLgogLSBO
byB2YWx1ZSBpbiB0aGUgZW50aXR5IG1heSBoYXZlIG1lYW5pbmcgMTgsCiAgIG5vdCBldmVu
IGEgdmFsdWUgaW4gYW4gZW50aXR5IGluIGFub3RoZXIgdmFsdWUuCgoNCgUEDggAARIEsQII
EQqAAQoEBA4CABIEtAIEFhpyIFRoZSBlbnRpdHkgdG8gaW5zZXJ0LiBUaGUgZW50aXR5IG11
c3Qgbm90IGFscmVhZHkgZXhpc3QuCiBUaGUgZW50aXR5IGtleSdzIGZpbmFsIHBhdGggZWxl
bWVudCBtYXkgYmUgaW5jb21wbGV0ZS4KCg0KBQQOAgAGEgS0AgQKCg0KBQQOAgABEgS0AgsR
Cg0KBQQOAgADEgS0AhQVCmQKBAQOAgESBLgCBBYaViBUaGUgZW50aXR5IHRvIHVwZGF0ZS4g
VGhlIGVudGl0eSBtdXN0IGFscmVhZHkgZXhpc3QuCiBNdXN0IGhhdmUgYSBjb21wbGV0ZSBr
ZXkgcGF0aC4KCg0KBQQOAgEGEgS4AgQKCg0KBQQOAgEBEgS4AgsRCg0KBQQOAgEDEgS4AhQV
CoYBCgQEDgICEgS8AgQWGnggVGhlIGVudGl0eSB0byB1cHNlcnQuIFRoZSBlbnRpdHkgbWF5
IG9yIG1heSBub3QgYWxyZWFkeSBleGlzdC4KIFRoZSBlbnRpdHkga2V5J3MgZmluYWwgcGF0
aCBlbGVtZW50IG1heSBiZSBpbmNvbXBsZXRlLgoKDQoFBA4CAgYSBLwCBAoKDQoFBA4CAgES
BLwCCxEKDQoFBA4CAgMSBLwCFBUKnQEKBAQOAgMSBMACBBMajgEgVGhlIGtleSBvZiB0aGUg
ZW50aXR5IHRvIGRlbGV0ZS4gVGhlIGVudGl0eSBtYXkgb3IgbWF5IG5vdCBhbHJlYWR5IGV4
aXN0LgogTXVzdCBoYXZlIGEgY29tcGxldGUga2V5IHBhdGggYW5kIG11c3Qgbm90IGJlIHJl
c2VydmVkL3JlYWQtb25seS4KCg0KBQQOAgMGEgTAAgQHCg0KBQQOAgMBEgTAAggOCg0KBQQO
AgMDEgTAAhESCuMBCgQEDggBEgbGAgLKAgMa0gEgV2hlbiBzZXQsIHRoZSBzZXJ2ZXIgd2ls
bCBkZXRlY3Qgd2hldGhlciBvciBub3QgdGhpcyBtdXRhdGlvbiBjb25mbGljdHMKIHdpdGgg
dGhlIGN1cnJlbnQgdmVyc2lvbiBvZiB0aGUgZW50aXR5IG9uIHRoZSBzZXJ2ZXIuIENvbmZs
aWN0aW5nIG11dGF0aW9ucwogYXJlIG5vdCBhcHBsaWVkLCBhbmQgYXJlIG1hcmtlZCBhcyBz
dWNoIGluIE11dGF0aW9uUmVzdWx0LgoKDQoFBA4IAQESBMYCCCMKpQEKBAQOAgQSBMkCBBsa
lgEgVGhlIHZlcnNpb24gb2YgdGhlIGVudGl0eSB0aGF0IHRoaXMgbXV0YXRpb24gaXMgYmVp
bmcgYXBwbGllZCB0by4gSWYgdGhpcwogZG9lcyBub3QgbWF0Y2ggdGhlIGN1cnJlbnQgdmVy
c2lvbiBvbiB0aGUgc2VydmVyLCB0aGUgbXV0YXRpb24gY29uZmxpY3RzLgoKDQoFBA4CBAUS
BMkCBAkKDQoFBA4CBAESBMkCChYKDQoFBA4CBAMSBMkCGRoKMgoCBA8SBs4CAN0CARokIFRo
ZSByZXN1bHQgb2YgYXBwbHlpbmcgYSBtdXRhdGlvbi4KCgsKAwQPARIEzgIIFgpdCgQEDwIA
EgTRAgIOGk8gVGhlIGF1dG9tYXRpY2FsbHkgYWxsb2NhdGVkIGtleS4KIFNldCBvbmx5IHdo
ZW4gdGhlIG11dGF0aW9uIGFsbG9jYXRlZCBhIGtleS4KCg0KBQQPAgAGEgTRAgIFCg0KBQQP
AgABEgTRAgYJCg0KBQQPAgADEgTRAgwNCu4CCgQEDwIBEgTYAgIUGt8CIFRoZSB2ZXJzaW9u
IG9mIHRoZSBlbnRpdHkgb24gdGhlIHNlcnZlciBhZnRlciBwcm9jZXNzaW5nIHRoZSBtdXRh
dGlvbi4gSWYKIHRoZSBtdXRhdGlvbiBkb2Vzbid0IGNoYW5nZSBhbnl0aGluZyBvbiB0aGUg
c2VydmVyLCB0aGVuIHRoZSB2ZXJzaW9uIHdpbGwKIGJlIHRoZSB2ZXJzaW9uIG9mIHRoZSBj
dXJyZW50IGVudGl0eSBvciwgaWYgbm8gZW50aXR5IGlzIHByZXNlbnQsIGEgdmVyc2lvbgog
dGhhdCBpcyBzdHJpY3RseSBncmVhdGVyIHRoYW4gdGhlIHZlcnNpb24gb2YgYW55IHByZXZp
b3VzIGVudGl0eSBhbmQgbGVzcwogdGhhbiB0aGUgdmVyc2lvbiBvZiBhbnkgcG9zc2libGUg
ZnV0dXJlIGVudGl0eS4KCg0KBQQPAgEFEgTYAgIHCg0KBQQPAgEBEgTYAggPCg0KBQQPAgED
EgTYAhITCpYBCgQEDwICEgTcAgIdGocBIFdoZXRoZXIgYSBjb25mbGljdCB3YXMgZGV0ZWN0
ZWQgZm9yIHRoaXMgbXV0YXRpb24uIEFsd2F5cyBmYWxzZSB3aGVuIGEKIGNvbmZsaWN0IGRl
dGVjdGlvbiBzdHJhdGVneSBmaWVsZCBpcyBub3Qgc2V0IGluIHRoZSBtdXRhdGlvbi4KCg0K
BQQPAgIFEgTcAgIGCg0KBQQPAgIBEgTcAgcYCg0KBQQPAgIDEgTcAhscCjQKAgQQEgbgAgD6
AgEaJiBUaGUgb3B0aW9ucyBzaGFyZWQgYnkgcmVhZCByZXF1ZXN0cy4KCgsKAwQQARIE4AII
Ewo9CgQEEAQAEgbiAgLrAgMaLSBUaGUgcG9zc2libGUgdmFsdWVzIGZvciByZWFkIGNvbnNp
c3RlbmNpZXMuCgoNCgUEEAQAARIE4gIHFgo7CgYEEAQAAgASBOQCBCUaKyBVbnNwZWNpZmll
ZC4gVGhpcyB2YWx1ZSBtdXN0IG5vdCBiZSB1c2VkLgoKDwoHBBAEAAIAARIE5AIEIAoPCgcE
EAQAAgACEgTkAiMkCiUKBgQQBAACARIE5wIEDxoVIFN0cm9uZyBjb25zaXN0ZW5jeS4KCg8K
BwQQBAACAQESBOcCBAoKDwoHBBAEAAIBAhIE5wINDgonCgYEEAQAAgISBOoCBBEaFyBFdmVu
dHVhbCBjb25zaXN0ZW5jeS4KCg8KBwQQBAACAgESBOoCBAwKDwoHBBAEAAICAhIE6gIPEAqk
AQoEBBAIABIG8AIC+QIDGpMBIElmIG5vdCBzcGVjaWZpZWQsIGxvb2t1cHMgYW5kIGFuY2Vz
dG9yIHF1ZXJpZXMgZGVmYXVsdCB0bwogYHJlYWRfY29uc2lzdGVuY3lgPWBTVFJPTkdgLCBn
bG9iYWwgcXVlcmllcyBkZWZhdWx0IHRvCiBgcmVhZF9jb25zaXN0ZW5jeWA9YEVWRU5UVUFM
YC4KCg0KBQQQCAABEgTwAggYCm0KBAQQAgASBPMCBCkaXyBUaGUgbm9uLXRyYW5zYWN0aW9u
YWwgcmVhZCBjb25zaXN0ZW5jeSB0byB1c2UuCiBDYW5ub3QgYmUgc2V0IHRvIGBTVFJPTkdg
IGZvciBnbG9iYWwgcXVlcmllcy4KCg0KBQQQAgAGEgTzAgQTCg0KBQQQAgABEgTzAhQkCg0K
BQQQAgADEgTzAicoCssBCgQEEAIBEgT4AgQaGrwBIFRoZSBpZGVudGlmaWVyIG9mIHRoZSB0
cmFuc2FjdGlvbiBpbiB3aGljaCB0byByZWFkLiBBCiB0cmFuc2FjdGlvbiBpZGVudGlmaWVy
IGlzIHJldHVybmVkIGJ5IGEgY2FsbCB0bwogW0RhdGFzdG9yZS5CZWdpblRyYW5zYWN0aW9u
XVtnb29nbGUuZGF0YXN0b3JlLnYxYmV0YTMuRGF0YXN0b3JlLkJlZ2luVHJhbnNhY3Rpb25d
LgoKDQoFBBACAQUSBPgCBAkKDQoFBBACAQESBPgCChUKDQoFBBACAQMSBPgCGBkKxQIKAgQR
EgaDAwCWAwEatgIgT3B0aW9ucyBmb3IgYmVnaW5uaW5nIGEgbmV3IHRyYW5zYWN0aW9uLgoK
IFRyYW5zYWN0aW9ucyBjYW4gYmUgY3JlYXRlZCBleHBsaWNpdGx5IHdpdGggY2FsbHMgdG8K
IFtEYXRhc3RvcmUuQmVnaW5UcmFuc2FjdGlvbl1bZ29vZ2xlLmRhdGFzdG9yZS52MWJldGEz
LkRhdGFzdG9yZS5CZWdpblRyYW5zYWN0aW9uXQogb3IgaW1wbGljaXRseSBieSBzZXR0aW5n
CiBbUmVhZE9wdGlvbnMubmV3X3RyYW5zYWN0aW9uXVtnb29nbGUuZGF0YXN0b3JlLnYxYmV0
YTMuUmVhZE9wdGlvbnMubmV3X3RyYW5zYWN0aW9uXQogaW4gcmVhZCByZXF1ZXN0cy4KCgsK
AwQRARIEgwMIGgpACgQEEQMAEgaFAwKIAwMaMCBPcHRpb25zIHNwZWNpZmljIHRvIHJlYWQg
LyB3cml0ZSB0cmFuc2FjdGlvbnMuCgoNCgUEEQMAARIEhQMKEwpOCgYEEQMAAgASBIcDBCMa
PiBUaGUgdHJhbnNhY3Rpb24gaWRlbnRpZmllciBvZiB0aGUgdHJhbnNhY3Rpb24gYmVpbmcg
cmV0cmllZC4KCg8KBwQRAwACAAUSBIcDBAkKDwoHBBEDAAIAARIEhwMKHgoPCgcEEQMAAgAD
EgSHAyEiCjsKBAQRAwESBIsDAhUaLSBPcHRpb25zIHNwZWNpZmljIHRvIHJlYWQtb25seSB0
cmFuc2FjdGlvbnMuCgoNCgUEEQMBARIEiwMKEgpkCgQEEQgAEgaPAwKVAwMaVCBUaGUgYG1v
ZGVgIG9mIHRoZSB0cmFuc2FjdGlvbiwgaW5kaWNhdGluZyB3aGV0aGVyIHdyaXRlIG9wZXJh
dGlvbnMgYXJlCiBzdXBwb3J0ZWQuCgoNCgUEEQgAARIEjwMIDApDCgQEEQIAEgSRAwQdGjUg
VGhlIHRyYW5zYWN0aW9uIHNob3VsZCBhbGxvdyBib3RoIHJlYWRzIGFuZCB3cml0ZXMuCgoN
CgUEEQIABhIEkQMEDQoNCgUEEQIAARIEkQMOGAoNCgUEEQIAAxIEkQMbHAo4CgQEEQIBEgSU
AwQbGiogVGhlIHRyYW5zYWN0aW9uIHNob3VsZCBvbmx5IGFsbG93IHJlYWRzLgoKDQoFBBEC
AQYSBJQDBAwKDQoFBBECAQESBJQDDRYKDQoFBBECAQMSBJQDGRpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::V1beta3::Datastore::LookupRequest ===
    # Fields for LookupRequest
    # Field: project_id Type: 9 ()
    # Field: read_options Type: 11 (.google.datastore.v1beta3.ReadOptions)
    # Field: keys Type: 11 (.google.datastore.v1beta3.Key)

# === Message: Google::Datastore::V1beta3::Datastore::LookupResponse ===
    # Fields for LookupResponse
    # Field: found Type: 11 (.google.datastore.v1beta3.EntityResult)
    # Field: missing Type: 11 (.google.datastore.v1beta3.EntityResult)
    # Field: deferred Type: 11 (.google.datastore.v1beta3.Key)

# === Message: Google::Datastore::V1beta3::Datastore::RunQueryRequest ===
    # Fields for RunQueryRequest
    # Field: project_id Type: 9 ()
    # Field: partition_id Type: 11 (.google.datastore.v1beta3.PartitionId)
    # Field: read_options Type: 11 (.google.datastore.v1beta3.ReadOptions)
    # Field: query Type: 11 (.google.datastore.v1beta3.Query)
    # Field: gql_query Type: 11 (.google.datastore.v1beta3.GqlQuery)

# === Message: Google::Datastore::V1beta3::Datastore::RunQueryResponse ===
    # Fields for RunQueryResponse
    # Field: batch Type: 11 (.google.datastore.v1beta3.QueryResultBatch)
    # Field: query Type: 11 (.google.datastore.v1beta3.Query)

# === Message: Google::Datastore::V1beta3::Datastore::BeginTransactionRequest ===
    # Fields for BeginTransactionRequest
    # Field: project_id Type: 9 ()
    # Field: transaction_options Type: 11 (.google.datastore.v1beta3.TransactionOptions)

# === Message: Google::Datastore::V1beta3::Datastore::BeginTransactionResponse ===
    # Fields for BeginTransactionResponse
    # Field: transaction Type: 12 ()

# === Message: Google::Datastore::V1beta3::Datastore::RollbackRequest ===
    # Fields for RollbackRequest
    # Field: project_id Type: 9 ()
    # Field: transaction Type: 12 ()

# === Message: Google::Datastore::V1beta3::Datastore::RollbackResponse ===
    # Fields for RollbackResponse

# === Message: Google::Datastore::V1beta3::Datastore::CommitRequest ===
    # Fields for CommitRequest
    # Field: project_id Type: 9 ()
    # Field: mode Type: 14 (.google.datastore.v1beta3.CommitRequest.Mode)
    # Field: transaction Type: 12 ()
    # Field: mutations Type: 11 (.google.datastore.v1beta3.Mutation)

# Enum: CommitRequest::Mode
our $CommitRequest_MODE_UNSPECIFIED = 0;
our $CommitRequest_TRANSACTIONAL = 1;
our $CommitRequest_NON_TRANSACTIONAL = 2;

# === Message: Google::Datastore::V1beta3::Datastore::CommitResponse ===
    # Fields for CommitResponse
    # Field: mutation_results Type: 11 (.google.datastore.v1beta3.MutationResult)
    # Field: index_updates Type: 5 ()

# === Message: Google::Datastore::V1beta3::Datastore::AllocateIdsRequest ===
    # Fields for AllocateIdsRequest
    # Field: project_id Type: 9 ()
    # Field: keys Type: 11 (.google.datastore.v1beta3.Key)

# === Message: Google::Datastore::V1beta3::Datastore::AllocateIdsResponse ===
    # Fields for AllocateIdsResponse
    # Field: keys Type: 11 (.google.datastore.v1beta3.Key)

# === Message: Google::Datastore::V1beta3::Datastore::ReserveIdsRequest ===
    # Fields for ReserveIdsRequest
    # Field: project_id Type: 9 ()
    # Field: database_id Type: 9 ()
    # Field: keys Type: 11 (.google.datastore.v1beta3.Key)

# === Message: Google::Datastore::V1beta3::Datastore::ReserveIdsResponse ===
    # Fields for ReserveIdsResponse

# === Message: Google::Datastore::V1beta3::Datastore::Mutation ===
    # Fields for Mutation
    # Field: insert Type: 11 (.google.datastore.v1beta3.Entity)
    # Field: update Type: 11 (.google.datastore.v1beta3.Entity)
    # Field: upsert Type: 11 (.google.datastore.v1beta3.Entity)
    # Field: delete Type: 11 (.google.datastore.v1beta3.Key)
    # Field: base_version Type: 3 ()

# === Message: Google::Datastore::V1beta3::Datastore::MutationResult ===
    # Fields for MutationResult
    # Field: key Type: 11 (.google.datastore.v1beta3.Key)
    # Field: version Type: 3 ()
    # Field: conflict_detected Type: 8 ()

# === Message: Google::Datastore::V1beta3::Datastore::ReadOptions ===
    # Fields for ReadOptions
    # Field: read_consistency Type: 14 (.google.datastore.v1beta3.ReadOptions.ReadConsistency)
    # Field: transaction Type: 12 ()

# Enum: ReadOptions::ReadConsistency
our $ReadOptions_READ_CONSISTENCY_UNSPECIFIED = 0;
our $ReadOptions_STRONG = 1;
our $ReadOptions_EVENTUAL = 2;

# === Message: Google::Datastore::V1beta3::Datastore::TransactionOptions ===
    # Fields for TransactionOptions
    # Field: read_write Type: 11 (.google.datastore.v1beta3.TransactionOptions.ReadWrite)
    # Field: read_only Type: 11 (.google.datastore.v1beta3.TransactionOptions.ReadOnly)

# === Service Client: Google::Datastore::V1beta3::Datastore::DatastoreClient ===
package Google::Datastore::V1beta3::Datastore::DatastoreClient;

=pod

=head2 Service Client: Google::Datastore::V1beta3::Datastore::DatastoreClient

Client stub representing the remote C<Datastore> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<datastore.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'datastore.googleapis.com:443' );

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

sub lookup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::LookupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'Lookup',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::LookupResponse',
    });
}

sub run_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::RunQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'RunQuery',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::RunQueryResponse',
    });
}

sub begin_transaction {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::BeginTransactionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'BeginTransaction',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::BeginTransactionResponse',
    });
}

sub commit {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::CommitRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'Commit',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::CommitResponse',
    });
}

sub rollback {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::RollbackRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'Rollback',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::RollbackResponse',
    });
}

sub allocate_ids {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::AllocateIdsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'AllocateIds',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::AllocateIdsResponse',
    });
}

sub reserve_ids {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Datastore::V1beta3::Datastore::ReserveIdsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.datastore.v1beta3.Datastore',
        method         => 'ReserveIds',
        request        => $req,
        response_class => 'Google::Datastore::V1beta3::Datastore::ReserveIdsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::V1beta3::Datastore - Compiled Protocol Buffers messages for google/datastore/v1beta3/datastore.proto

=head1 SYNOPSIS

    use Google::Datastore::V1beta3::Datastore;

    my $msg = Google::Datastore::V1beta3::Datastore::LookupRequest->new({
        project_id => $project_id,
        read_options => $read_options,
        keys => $keys,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::V1beta3::Datastore::LookupRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/v1beta3/datastore.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::V1beta3::Datastore::LookupRequest

The request for
[Datastore.Lookup][google.datastore.v1beta3.Datastore.Lookup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->read_options() >> / C<< $msg->read_options($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::ReadOptions>)

The options for this lookup request.

=item * C<< $msg->keys() >> / C<< $msg->keys($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

Keys of entities to look up.

=back

=head2 Google::Datastore::V1beta3::Datastore::LookupResponse

The response for
[Datastore.Lookup][google.datastore.v1beta3.Datastore.Lookup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->found() >> / C<< $msg->found($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::EntityResult>)

Entities found as `ResultType.FULL` entities. The order of results in this
field is undefined and has no relation to the order of the keys in the
input.

=item * C<< $msg->missing() >> / C<< $msg->missing($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::EntityResult>)

Entities not found as `ResultType.KEY_ONLY` entities. The order of results
in this field is undefined and has no relation to the order of the keys
in the input.

=item * C<< $msg->deferred() >> / C<< $msg->deferred($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

A list of keys that were not looked up due to resource constraints. The
order of results in this field is undefined and has no relation to the
order of the keys in the input.

=back

=head2 Google::Datastore::V1beta3::Datastore::RunQueryRequest

The request for
[Datastore.RunQuery][google.datastore.v1beta3.Datastore.RunQuery].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->partition_id() >> / C<< $msg->partition_id($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::PartitionId>)

Entities are partitioned into subsets, identified by a partition ID.
Queries are scoped to a single partition.
This partition ID is normalized with the standard default context
partition ID.

=item * C<< $msg->read_options() >> / C<< $msg->read_options($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::ReadOptions>)

The options for this query.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::Query>)

The query to run.

=item * C<< $msg->gql_query() >> / C<< $msg->gql_query($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::GqlQuery>)

The GQL query to run.

=back

=head2 Google::Datastore::V1beta3::Datastore::RunQueryResponse

The response for
[Datastore.RunQuery][google.datastore.v1beta3.Datastore.RunQuery].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->batch() >> / C<< $msg->batch($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::QueryResultBatch>)

A batch of query results (always present).

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Query::Query>)

The parsed form of the `GqlQuery` from the request, if it was set.

=back

=head2 Google::Datastore::V1beta3::Datastore::BeginTransactionRequest

The request for
[Datastore.BeginTransaction][google.datastore.v1beta3.Datastore.BeginTransaction].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->transaction_options() >> / C<< $msg->transaction_options($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::TransactionOptions>)

Options for a new transaction.

=back

=head2 Google::Datastore::V1beta3::Datastore::BeginTransactionResponse

The response for
[Datastore.BeginTransaction][google.datastore.v1beta3.Datastore.BeginTransaction].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transaction() >> / C<< $msg->transaction($value) >>

Type: C<Bytes>

The transaction identifier (always present).

=back

=head2 Google::Datastore::V1beta3::Datastore::RollbackRequest

The request for
[Datastore.Rollback][google.datastore.v1beta3.Datastore.Rollback].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->transaction() >> / C<< $msg->transaction($value) >>

Type: C<Bytes>

The transaction identifier, returned by a call to
[Datastore.BeginTransaction][google.datastore.v1beta3.Datastore.BeginTransaction].

=back

=head2 Google::Datastore::V1beta3::Datastore::RollbackResponse

The response for
[Datastore.Rollback][google.datastore.v1beta3.Datastore.Rollback]. (an empty
message).

Inherits from L<Protobuf::Message>.

=head2 Google::Datastore::V1beta3::Datastore::CommitRequest

The request for
[Datastore.Commit][google.datastore.v1beta3.Datastore.Commit].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::CommitRequest::Mode>)

The type of commit to perform. Defaults to `TRANSACTIONAL`.

=item * C<< $msg->transaction() >> / C<< $msg->transaction($value) >>

Type: C<Bytes>

The identifier of the transaction associated with the commit. A
transaction identifier is returned by a call to
[Datastore.BeginTransaction][google.datastore.v1beta3.Datastore.BeginTransaction].

=item * C<< $msg->mutations() >> / C<< $msg->mutations($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::Mutation>)

The mutations to perform.

When mode is `TRANSACTIONAL`, mutations affecting a single entity are
applied in order. The following sequences of mutations affecting a single
entity are not permitted in a single `Commit` request:

- `insert` followed by `insert`
- `update` followed by `insert`
- `upsert` followed by `insert`
- `delete` followed by `update`

When mode is `NON_TRANSACTIONAL`, no two mutations may affect a single
entity.

=back

=head3 Enum: CommitRequest::Mode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<TRANSACTIONAL> => C<1>

=item * C<NON_TRANSACTIONAL> => C<2>

=back

=head2 Google::Datastore::V1beta3::Datastore::CommitResponse

The response for
[Datastore.Commit][google.datastore.v1beta3.Datastore.Commit].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mutation_results() >> / C<< $msg->mutation_results($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::MutationResult>)

The result of performing the mutations.
The i-th mutation result corresponds to the i-th mutation in the request.

=item * C<< $msg->index_updates() >> / C<< $msg->index_updates($value) >>

Type: C<Int32>

The number of index entries updated during the commit, or zero if none were
updated.

=back

=head2 Google::Datastore::V1beta3::Datastore::AllocateIdsRequest

The request for
[Datastore.AllocateIds][google.datastore.v1beta3.Datastore.AllocateIds].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->keys() >> / C<< $msg->keys($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

A list of keys with incomplete key paths for which to allocate IDs.
No key may be reserved/read-only.

=back

=head2 Google::Datastore::V1beta3::Datastore::AllocateIdsResponse

The response for
[Datastore.AllocateIds][google.datastore.v1beta3.Datastore.AllocateIds].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->keys() >> / C<< $msg->keys($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

The keys specified in the request (in the same order), each with
its key path completed with a newly allocated ID.

=back

=head2 Google::Datastore::V1beta3::Datastore::ReserveIdsRequest

The request for
[Datastore.ReserveIds][google.datastore.v1beta3.Datastore.ReserveIds].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project against which to make the request.

=item * C<< $msg->database_id() >> / C<< $msg->database_id($value) >>

Type: C<String>

If not empty, the ID of the database against which to make the request.

=item * C<< $msg->keys() >> / C<< $msg->keys($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

A list of keys with complete key paths whose numeric IDs should not be
auto-allocated.

=back

=head2 Google::Datastore::V1beta3::Datastore::ReserveIdsResponse

The response for
[Datastore.ReserveIds][google.datastore.v1beta3.Datastore.ReserveIds].

Inherits from L<Protobuf::Message>.

=head2 Google::Datastore::V1beta3::Datastore::Mutation

A mutation to apply to an entity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->insert() >> / C<< $msg->insert($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Entity>)

The entity to insert. The entity must not already exist.
The entity key's final path element may be incomplete.

=item * C<< $msg->update() >> / C<< $msg->update($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Entity>)

The entity to update. The entity must already exist.
Must have a complete key path.

=item * C<< $msg->upsert() >> / C<< $msg->upsert($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Entity>)

The entity to upsert. The entity may or may not already exist.
The entity key's final path element may be incomplete.

=item * C<< $msg->delete() >> / C<< $msg->delete($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

The key of the entity to delete. The entity may or may not already exist.
Must have a complete key path and must not be reserved/read-only.

=item * C<< $msg->base_version() >> / C<< $msg->base_version($value) >>

Type: C<Int64>

The version of the entity that this mutation is being applied to. If this
does not match the current version on the server, the mutation conflicts.

=back

=head2 Google::Datastore::V1beta3::Datastore::MutationResult

The result of applying a mutation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Entity::Key>)

The automatically allocated key.
Set only when the mutation allocated a key.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Int64>

The version of the entity on the server after processing the mutation. If
the mutation doesn't change anything on the server, then the version will
be the version of the current entity or, if no entity is present, a version
that is strictly greater than the version of any previous entity and less
than the version of any possible future entity.

=item * C<< $msg->conflict_detected() >> / C<< $msg->conflict_detected($value) >>

Type: C<Bool>

Whether a conflict was detected for this mutation. Always false when a
conflict detection strategy field is not set in the mutation.

=back

=head2 Google::Datastore::V1beta3::Datastore::ReadOptions

The options shared by read requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->read_consistency() >> / C<< $msg->read_consistency($value) >>

Type: C<Enum> (L<Google::Datastore::V1beta3::ReadOptions::ReadConsistency>)

The non-transactional read consistency to use.
Cannot be set to `STRONG` for global queries.

=item * C<< $msg->transaction() >> / C<< $msg->transaction($value) >>

Type: C<Bytes>

The identifier of the transaction in which to read. A
transaction identifier is returned by a call to
[Datastore.BeginTransaction][google.datastore.v1beta3.Datastore.BeginTransaction].

=back

=head3 Enum: ReadOptions::ReadConsistency

=over 4

=item * C<READ_CONSISTENCY_UNSPECIFIED> => C<0>

=item * C<STRONG> => C<1>

=item * C<EVENTUAL> => C<2>

=back

=head2 Google::Datastore::V1beta3::Datastore::TransactionOptions

Options for beginning a new transaction.

Transactions can be created explicitly with calls to
[Datastore.BeginTransaction][google.datastore.v1beta3.Datastore.BeginTransaction]
or implicitly by setting
[ReadOptions.new_transaction][google.datastore.v1beta3.ReadOptions.new_transaction]
in read requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->read_write() >> / C<< $msg->read_write($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::TransactionOptions::ReadWrite>)

The transaction should allow both reads and writes.

=item * C<< $msg->read_only() >> / C<< $msg->read_only($value) >>

Type: C<Message> (L<Google::Datastore::V1beta3::Datastore::TransactionOptions::ReadOnly>)

The transaction should only allow reads.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::V1beta3::Datastore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
