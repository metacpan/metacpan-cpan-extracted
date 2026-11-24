package Google::Cloud::Discoveryengine::V1alpha::Control;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29udHJvbC5wcm90bxIk
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUvY2xv
dWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tbW9uLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIo8DCglDb25kaXRpb24SWgoLcXVlcnlfdGVybXMYAiADKAsy
OS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29uZGl0aW9uLlF1ZXJ5
VGVybVIKcXVlcnlUZXJtcxJlChFhY3RpdmVfdGltZV9yYW5nZRgDIAMoCzI5Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db25kaXRpb24uVGltZVJhbmdlUg9hY3Rp
dmVUaW1lUmFuZ2UaQAoJUXVlcnlUZXJtEhQKBXZhbHVlGAEgASgJUgV2YWx1ZRIdCgpmdWxs
X21hdGNoGAIgASgIUglmdWxsTWF0Y2gafQoJVGltZVJhbmdlEjkKCnN0YXJ0X3RpbWUYASAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFydFRpbWUSNQoIZW5kX3RpbWUY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdlbmRUaW1lIooMCgdDb250cm9s
El4KDGJvb3N0X2FjdGlvbhgGIAEoCzI5Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5Db250cm9sLkJvb3N0QWN0aW9uSABSC2Jvb3N0QWN0aW9uEmEKDWZpbHRlcl9h
Y3Rpb24YByABKAsyOi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29u
dHJvbC5GaWx0ZXJBY3Rpb25IAFIMZmlsdGVyQWN0aW9uEmcKD3JlZGlyZWN0X2FjdGlvbhgJ
IAEoCzI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db250cm9sLlJl
ZGlyZWN0QWN0aW9uSABSDnJlZGlyZWN0QWN0aW9uEmcKD3N5bm9ueW1zX2FjdGlvbhgKIAEo
CzI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db250cm9sLlN5bm9u
eW1zQWN0aW9uSABSDnN5bm9ueW1zQWN0aW9uEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRIm
CgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSRgodYXNzb2NpYXRlZF9z
ZXJ2aW5nX2NvbmZpZ19pZHMYAyADKAlCA+BBA1IaYXNzb2NpYXRlZFNlcnZpbmdDb25maWdJ
ZHMSXwoNc29sdXRpb25fdHlwZRgEIAEoDjIyLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5Tb2x1dGlvblR5cGVCBuBBAuBBBVIMc29sdXRpb25UeXBlElAKCXVzZV9j
YXNlcxgIIAMoDjIzLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZWFy
Y2hVc2VDYXNlUgh1c2VDYXNlcxJPCgpjb25kaXRpb25zGAUgAygLMi8uZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNvbmRpdGlvblIKY29uZGl0aW9ucxqWAQoLQm9v
c3RBY3Rpb24SGQoFYm9vc3QYASABKAJCA+BBAlIFYm9vc3QSGwoGZmlsdGVyGAIgASgJQgPg
QQJSBmZpbHRlchJPCgpkYXRhX3N0b3JlGAMgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSCWRhdGFTdG9yZRp8CgxGaWx0ZXJBY3Rpb24S
GwoGZmlsdGVyGAEgASgJQgPgQQJSBmZpbHRlchJPCgpkYXRhX3N0b3JlGAIgASgJQjDgQQL6
QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSCWRhdGFTdG9y
ZRo4Cg5SZWRpcmVjdEFjdGlvbhImCgxyZWRpcmVjdF91cmkYASABKAlCA+BBAlILcmVkaXJl
Y3RVcmkaLAoOU3lub255bXNBY3Rpb24SGgoIc3lub255bXMYASADKAlSCHN5bm9ueW1zOtMC
6kHPAgomZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NvbnRyb2wSUnByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3Jl
fS9jb250cm9scy97Y29udHJvbH0Sa3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9y
ZX0vY29udHJvbHMve2NvbnRyb2x9EmRwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2VuZ2luZXMve2VuZ2luZX0vY29u
dHJvbHMve2NvbnRyb2x9QggKBmFjdGlvbkKYAgooY29tLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYUIMQ29udHJvbFByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28v
ZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5
ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5n
aW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidH
b29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFK4DcKBxIFDgDYAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoCAwASAxIAKQoJ
CgIDARIDEwAjCgkKAgMCEgMUADsKCQoCAwMSAxUAKQoICgEIEgMXAEEKCQoCCCUSAxcAQQoI
CgEIEgMYAGkKCQoCCAsSAxgAaQoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAC0KCQoC
CAgSAxoALQoICgEIEgMbAEEKCQoCCAESAxsAQQoICgEIEgMcAC0KCQoCCCQSAxwALQoICgEI
EgMdAEEKCQoCCCkSAx0AQQoICgEIEgMeAEAKCQoCCC0SAx4AQApMCgIEABIEIQBIARpAIERl
ZmluZXMgY2lyY3Vtc3RhbmNlcyB0byBiZSBjaGVja2VkIGJlZm9yZSBhbGxvd2luZyBhIGJl
aGF2aW9yCgoKCgMEAAESAyEIEQowCgQEAAMAEgQjAi4DGiIgTWF0Y2hlciBmb3Igc2VhcmNo
IHJlcXVlc3QgcXVlcnkKCgwKBQQAAwABEgMjChMK4AEKBgQAAwACABIDKgQVGtABIFRoZSBz
cGVjaWZpYyBxdWVyeSB2YWx1ZSB0byBtYXRjaCBhZ2FpbnN0CgogTXVzdCBiZSBsb3dlcmNh
c2UsIG11c3QgYmUgVVRGLTguCiBDYW4gaGF2ZSBhdCBtb3N0IDMgc3BhY2Ugc2VwYXJhdGVk
IHRlcm1zIGlmIGZ1bGxfbWF0Y2ggaXMgdHJ1ZS4KIENhbm5vdCBiZSBhbiBlbXB0eSBzdHJp
bmcuCiBNYXhpbXVtIGxlbmd0aCBvZiA1MDAwIGNoYXJhY3RlcnMuCgoOCgcEAAMAAgAFEgMq
BAoKDgoHBAADAAIAARIDKgsQCg4KBwQAAwACAAMSAyoTFApQCgYEAAMAAgESAy0EGBpBIFdo
ZXRoZXIgdGhlIHNlYXJjaCBxdWVyeSBuZWVkcyB0byBleGFjdGx5IG1hdGNoIHRoZSBxdWVy
eSB0ZXJtLgoKDgoHBAADAAIBBRIDLQQICg4KBwQAAwACAQESAy0JEwoOCgcEAAMAAgEDEgMt
FhcKMwoEBAADARIEMQI8AxolIFVzZWQgZm9yIHRpbWUtZGVwZW5kZW50IGNvbmRpdGlvbnMu
CgoMCgUEAAMBARIDMQoTCjsKBgQAAwECABIDNQQtGiwgU3RhcnQgb2YgdGltZSByYW5nZS4K
CiBSYW5nZSBpcyBpbmNsdXNpdmUuCgoOCgcEAAMBAgAGEgM1BB0KDgoHBAADAQIAARIDNR4o
Cg4KBwQAAwECAAMSAzUrLApRCgYEAAMBAgESAzsEKxpCIEVuZCBvZiB0aW1lIHJhbmdlLgoK
IFJhbmdlIGlzIGluY2x1c2l2ZS4KIE11c3QgYmUgaW4gdGhlIGZ1dHVyZS4KCg4KBwQAAwEC
AQYSAzsEHQoOCgcEAAMBAgEBEgM7HiYKDgoHBAADAQIBAxIDOykqCl8KBAQAAgASA0ICJRpS
IFNlYXJjaCBvbmx5CiBBIGxpc3Qgb2YgdGVybXMgdG8gbWF0Y2ggdGhlIHF1ZXJ5IG9uLgoK
IE1heGltdW0gb2YgMTAgcXVlcnkgdGVybXMuCgoMCgUEAAIABBIDQgIKCgwKBQQAAgAGEgNC
CxQKDAoFBAACAAESA0IVIAoMCgUEAAIAAxIDQiMkCmEKBAQAAgESA0cCKxpUIFJhbmdlIG9m
IHRpbWUocykgc3BlY2lmeWluZyB3aGVuIGNvbmRpdGlvbiBpcyBhY3RpdmUuCgogTWF4aW11
bSBvZiAxMCB0aW1lIHJhbmdlcy4KCgwKBQQAAgEEEgNHAgoKDAoFBAACAQYSA0cLFAoMCgUE
AAIBARIDRxUmCgwKBQQAAgEDEgNHKSoK9gEKAgQBEgVOANgBARroASBEZWZpbmVzIGEgY29u
ZGl0aW9uZWQgYmVoYXZpb3IgdG8gZW1wbG95IGR1cmluZyBzZXJ2aW5nLgogTXVzdCBiZSBh
dHRhY2hlZCB0byBhCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlNlcnZpbmdDb25maWddIHRvIGJlCiBjb25zaWRlcmVkIGF0IHNlcnZp
bmcgdGltZS4gUGVybWl0dGVkIGFjdGlvbnMgZGVwZW5kZW50IG9uIGBTb2x1dGlvblR5cGVg
LgoKCgoDBAEBEgNOCA8KCwoDBAEHEgRPAlQECg0KBQQBB50IEgRPAlQECjsKBAQBAwASBFcC
bgMaLSBBZGp1c3RzIG9yZGVyIG9mIHByb2R1Y3RzIGluIHJldHVybmVkIGxpc3QuCgoMCgUE
AQMAARIDVwoVCoUBCgYEAQMAAgASA1oEPRp2IFJlcXVpcmVkLiBTdHJlbmd0aCBvZiB0aGUg
Ym9vc3QsIHdoaWNoIHNob3VsZCBiZSBpbiBbLTEsIDFdLiBOZWdhdGl2ZQogYm9vc3QgbWVh
bnMgZGVtb3Rpb24uIERlZmF1bHQgaXMgMC4wIChOby1vcCkuCgoOCgcEAQMAAgAFEgNaBAkK
DgoHBAEDAAIAARIDWgoPCg4KBwQBAwACAAMSA1oSEwoOCgcEAQMAAgAIEgNaFDwKEQoKBAED
AAIACJwIABIDWhU7Cq4CCgYEAQMAAgESA2MEPxqeAiBSZXF1aXJlZC4gU3BlY2lmaWVzIHdo
aWNoIHByb2R1Y3RzIHRvIGFwcGx5IHRoZSBib29zdCB0by4KCiBJZiBubyBmaWx0ZXIgaXMg
cHJvdmlkZWQgYWxsIHByb2R1Y3RzIHdpbGwgYmUgYm9vc3RlZCAoTm8tb3ApLgogU3ludGF4
IGRvY3VtZW50YXRpb246CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RvY3Mv
ZmlsdGVyLWFuZC1vcmRlcgogTWF4aW11bSBsZW5ndGggaXMgNTAwMCBjaGFyYWN0ZXJzLgog
T3RoZXJ3aXNlIGFuIElOVkFMSUQgQVJHVU1FTlQgZXJyb3IgaXMgdGhyb3duLgoKDgoHBAED
AAIBBRIDYwQKCg4KBwQBAwACAQESA2MLEQoOCgcEAQMAAgEDEgNjFBUKDgoHBAEDAAIBCBID
YxY+ChEKCgQBAwACAQicCAASA2MXPQraAQoGBAEDAAICEgRoBG0GGskBIFJlcXVpcmVkLiBT
cGVjaWZpZXMgd2hpY2ggZGF0YSBzdG9yZSdzIGRvY3VtZW50cyBjYW4gYmUgYm9vc3RlZCBi
eSB0aGlzCiBjb250cm9sLiBGdWxsIGRhdGEgc3RvcmUgbmFtZSBlLmcuCiBwcm9qZWN0cy8x
MjMvbG9jYXRpb25zL2dsb2JhbC9jb2xsZWN0aW9ucy9kZWZhdWx0X2NvbGxlY3Rpb24vZGF0
YVN0b3Jlcy9kZWZhdWx0X2RhdGFfc3RvcmUKCg4KBwQBAwACAgUSA2gECgoOCgcEAQMAAgIB
EgNoCxUKDgoHBAEDAAICAxIDaBgZCg8KBwQBAwACAggSBGgabQUKEQoKBAEDAAICCJwIABID
aQYsChEKCQQBAwACAgifCBIEagZsBwphCgQEAQMBEgVyAoUBAxpSIFNwZWNpZmllZCB3aGlj
aCBwcm9kdWN0cyBtYXkgYmUgaW5jbHVkZWQgaW4gcmVzdWx0cy4KIFVzZXMgc2FtZSBmaWx0
ZXIgYXMgYm9vc3QuCgoMCgUEAQMBARIDcgoWCv0BCgYEAQMBAgASA3oEPxrtASBSZXF1aXJl
ZC4gQSBmaWx0ZXIgdG8gYXBwbHkgb24gdGhlIG1hdGNoaW5nIGNvbmRpdGlvbiByZXN1bHRz
LgoKIFJlcXVpcmVkCiBTeW50YXggZG9jdW1lbnRhdGlvbjoKIGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9yZXRhaWwvZG9jcy9maWx0ZXItYW5kLW9yZGVyCiBNYXhpbXVtIGxlbmd0aCBp
cyA1MDAwIGNoYXJhY3RlcnMuIE90aGVyd2lzZSBhbiBJTlZBTElECiBBUkdVTUVOVCBlcnJv
ciBpcyB0aHJvd24uCgoOCgcEAQMBAgAFEgN6BAoKDgoHBAEDAQIAARIDegsRCg4KBwQBAwEC
AAMSA3oUFQoOCgcEAQMBAgAIEgN6Fj4KEQoKBAEDAQIACJwIABIDehc9CtwBCgYEAQMBAgES
BX8EhAEGGsoBIFJlcXVpcmVkLiBTcGVjaWZpZXMgd2hpY2ggZGF0YSBzdG9yZSdzIGRvY3Vt
ZW50cyBjYW4gYmUgZmlsdGVyZWQgYnkgdGhpcwogY29udHJvbC4gRnVsbCBkYXRhIHN0b3Jl
IG5hbWUgZS5nLgogcHJvamVjdHMvMTIzL2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMv
ZGVmYXVsdF9jb2xsZWN0aW9uL2RhdGFTdG9yZXMvZGVmYXVsdF9kYXRhX3N0b3JlCgoOCgcE
AQMBAgEFEgN/BAoKDgoHBAEDAQIBARIDfwsVCg4KBwQBAwECAQMSA38YGQoQCgcEAQMBAgEI
EgV/GoQBBQoSCgoEAQMBAgEInAgAEgSAAQYsChMKCQQBAwECAQifCBIGgQEGgwEHCjoKBAQB
AwISBogBAo8BAxoqIFJlZGlyZWN0cyBhIHNob3BwZXIgdG8gdGhlIHByb3ZpZGVkIFVSSS4K
Cg0KBQQBAwIBEgSIAQoYCsMBCgYEAQMCAgASBI4BBEUasgEgUmVxdWlyZWQuIFRoZSBVUkkg
dG8gd2hpY2ggdGhlIHNob3BwZXIgd2lsbCBiZSByZWRpcmVjdGVkLgoKIFJlcXVpcmVkLgog
VVJJIG11c3QgaGF2ZSBsZW5ndGggZXF1YWwgb3IgbGVzcyB0aGFuIDIwMDAgY2hhcmFjdGVy
cy4KIE90aGVyd2lzZSBhbiBJTlZBTElEIEFSR1VNRU5UIGVycm9yIGlzIHRocm93bi4KCg8K
BwQBAwICAAUSBI4BBAoKDwoHBAEDAgIAARIEjgELFwoPCgcEAQMCAgADEgSOARobCg8KBwQB
AwICAAgSBI4BHEQKEgoKBAEDAgIACJwIABIEjgEdQwq1AQoEBAEDAxIGlQECmwEDGqQBIENy
ZWF0ZXMgYSBzZXQgb2YgdGVybXMgdGhhdCB3aWxsIGFjdCBhcyBzeW5vbnltcyBvZiBvbmUg
YW5vdGhlci4KCiBFeGFtcGxlOiAiaGFwcHkiIHdpbGwgYWxzbyBiZSBjb25zaWRlcmVkIGFz
ICJnbGFkIiwgImdsYWQiIHdpbGwgYWxzbyBiZQogY29uc2lkZXJlZCBhcyAiaGFwcHkiLgoK
DQoFBAEDAwESBJUBChgKoQEKBgQBAwMCABIEmgEEIRqQASBEZWZpbmVzIGEgc2V0IG9mIHN5
bm9ueW1zLgogQ2FuIHNwZWNpZnkgdXAgdG8gMTAwIHN5bm9ueW1zLgogTXVzdCBzcGVjaWZ5
IGF0IGxlYXN0IDIgc3lub255bXMuIE90aGVyd2lzZSBhbiBJTlZBTElEIEFSR1VNRU5UIGVy
cm9yIGlzCiB0aHJvd24uCgoPCgcEAQMDAgAEEgSaAQQMCg8KBwQBAwMCAAUSBJoBDRMKDwoH
BAEDAwIAARIEmgEUHAoPCgcEAQMDAgADEgSaAR8gCk0KBAQBCAASBqABAq0BAxo9IEFjdGlv
bnMgYXJlIHJlc3RyaWN0ZWQgYnkgVmVydGljYWwgYW5kIFNvbHV0aW9uCgogUmVxdWlyZWQu
CgoNCgUEAQgAARIEoAEIDgosCgQEAQIAEgSiAQQhGh4gRGVmaW5lcyBhIGJvb3N0LXR5cGUg
Y29udHJvbAoKDQoFBAECAAYSBKIBBA8KDQoFBAECAAESBKIBEBwKDQoFBAECAAMSBKIBHyAK
WAoEBAECARIEpgEEIxpKIERlZmluZXMgYSBmaWx0ZXItdHlwZSBjb250cm9sCiBDdXJyZW50
bHkgbm90IHN1cHBvcnRlZCBieSBSZWNvbW1lbmRhdGlvbgoKDQoFBAECAQYSBKYBBBAKDQoF
BAECAQESBKYBER4KDQoFBAECAQMSBKYBISIKMAoEBAECAhIEqQEEJxoiIERlZmluZXMgYSBy
ZWRpcmVjdC10eXBlIGNvbnRyb2wuCgoNCgUEAQICBhIEqQEEEgoNCgUEAQICARIEqQETIgoN
CgUEAQICAxIEqQElJgpDCgQEAQIDEgSsAQQoGjUgVHJlYXRzIGEgZ3JvdXAgb2YgdGVybXMg
YXMgc3lub255bXMgb2Ygb25lIGFub3RoZXIuCgoNCgUEAQIDBhIErAEEEgoNCgUEAQIDARIE
rAETIgoNCgUEAQIDAxIErAElJwplCgQEAQIEEgSxAQI8GlcgSW1tdXRhYmxlLiBGdWxseSBx
dWFsaWZpZWQgbmFtZQogYHByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9kYXRhU3RvcmUv
Ki9jb250cm9scy8qYAoKDQoFBAECBAUSBLEBAggKDQoFBAECBAESBLEBCQ0KDQoFBAECBAMS
BLEBEBEKDQoFBAECBAgSBLEBEjsKEAoIBAECBAicCAASBLEBEzoKwAEKBAQBAgUSBLcBAkMa
sQEgUmVxdWlyZWQuIEh1bWFuIHJlYWRhYmxlIG5hbWUuIFRoZSBpZGVudGlmaWVyIHVzZWQg
aW4gVUkgdmlld3MuCgogTXVzdCBiZSBVVEYtOCBlbmNvZGVkIHN0cmluZy4gTGVuZ3RoIGxp
bWl0IGlzIDEyOCBjaGFyYWN0ZXJzLgogT3RoZXJ3aXNlIGFuIElOVkFMSUQgQVJHVU1FTlQg
ZXJyb3IgaXMgdGhyb3duLgoKDQoFBAECBQUSBLcBAggKDQoFBAECBQESBLcBCRUKDQoFBAEC
BQMSBLcBGBkKDQoFBAECBQgSBLcBGkIKEAoIBAECBQicCAASBLcBG0EKxgEKBAQBAgYSBr0B
Ar4BMhq1ASBPdXRwdXQgb25seS4gTGlzdCBvZiBhbGwKIFtTZXJ2aW5nQ29uZmlnXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VydmluZ0NvbmZpZ10gSURzCiB0
aGlzIGNvbnRyb2wgaXMgYXR0YWNoZWQgdG8uIE1heSB0YWtlIHVwIHRvIDEwIG1pbnV0ZXMg
dG8gdXBkYXRlIGFmdGVyCiBjaGFuZ2VzLgoKDQoFBAECBgQSBL0BAgoKDQoFBAECBgUSBL0B
CxEKDQoFBAECBgESBL0BEi8KDQoFBAECBgMSBL0BMjMKDQoFBAECBggSBL4BBjEKEAoIBAEC
BgicCAASBL4BBzAKrQEKBAQBAgcSBsQBAscBBBqcASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBX
aGF0IHNvbHV0aW9uIHRoZSBjb250cm9sIGJlbG9uZ3MgdG8uCgogTXVzdCBiZSBjb21wYXRp
YmxlIHdpdGggdmVydGljYWwgb2YgcmVzb3VyY2UuCiBPdGhlcndpc2UgYW4gSU5WQUxJRCBB
UkdVTUVOVCBlcnJvciBpcyB0aHJvd24uCgoNCgUEAQIHBhIExAECDgoNCgUEAQIHARIExAEP
HAoNCgUEAQIHAxIExAEfIAoPCgUEAQIHCBIGxAEhxwEDChAKCAQBAgcInAgAEgTFAQQqChAK
CAQBAgcInAgBEgTGAQQrCpYDCgQEAQIIEgTQAQInGocDIFNwZWNpZmllcyB0aGUgdXNlIGNh
c2UgZm9yIHRoZSBjb250cm9sLgogQWZmZWN0cyB3aGF0IGNvbmRpdGlvbiBmaWVsZHMgY2Fu
IGJlIHNldC4KIE9ubHkgYXBwbGllcyB0bwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9O
X1RZUEVfU0VBUkNIXS4KIEN1cnJlbnRseSBvbmx5IGFsbG93IG9uZSB1c2UgY2FzZSBwZXIg
Y29udHJvbC4KIE11c3QgYmUgc2V0IHdoZW4gc29sdXRpb25fdHlwZSBpcwogW1NvbHV0aW9u
VHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoNCgUEAQII
BBIE0AECCgoNCgUEAQIIBhIE0AELGAoNCgUEAQIIARIE0AEZIgoNCgUEAQIIAxIE0AElJgrM
AQoEBAECCRIE1wECJBq9ASBEZXRlcm1pbmVzIHdoZW4gdGhlIGFzc29jaWF0ZWQgYWN0aW9u
IHdpbGwgdHJpZ2dlci4KCiBPbWl0IHRvIGFsd2F5cyBhcHBseSB0aGUgYWN0aW9uLgogQ3Vy
cmVudGx5IG9ubHkgYSBzaW5nbGUgY29uZGl0aW9uIG1heSBiZSBzcGVjaWZpZWQuCiBPdGhl
cndpc2UgYW4gSU5WQUxJRCBBUkdVTUVOVCBlcnJvciBpcyB0aHJvd24uCgoNCgUEAQIJBBIE
1wECCgoNCgUEAQIJBhIE1wELFAoNCgUEAQIJARIE1wEVHwoNCgUEAQIJAxIE1wEiI2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Control::Condition ===
    # Fields for Condition
    # Field: query_terms Type: 11 (.google.cloud.discoveryengine.v1alpha.Condition.QueryTerm)
    # Field: active_time_range Type: 11 (.google.cloud.discoveryengine.v1alpha.Condition.TimeRange)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Control::Control ===
    # Fields for Control
    # Field: boost_action Type: 11 (.google.cloud.discoveryengine.v1alpha.Control.BoostAction)
    # Field: filter_action Type: 11 (.google.cloud.discoveryengine.v1alpha.Control.FilterAction)
    # Field: redirect_action Type: 11 (.google.cloud.discoveryengine.v1alpha.Control.RedirectAction)
    # Field: synonyms_action Type: 11 (.google.cloud.discoveryengine.v1alpha.Control.SynonymsAction)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: associated_serving_config_ids Type: 9 ()
    # Field: solution_type Type: 14 (.google.cloud.discoveryengine.v1alpha.SolutionType)
    # Field: use_cases Type: 14 (.google.cloud.discoveryengine.v1alpha.SearchUseCase)
    # Field: conditions Type: 11 (.google.cloud.discoveryengine.v1alpha.Condition)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Control - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/control.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Control;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Control::Condition->new({
        query_terms => $query_terms,
        active_time_range => $active_time_range,
    });

    # Read or update a field
    my $val = $msg->query_terms();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Control::Condition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/control.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Control::Condition

Defines circumstances to be checked before allowing a behavior

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query_terms() >> / C<< $msg->query_terms($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Condition::QueryTerm>)

Search only
A list of terms to match the query on.

Maximum of 10 query terms.

=item * C<< $msg->active_time_range() >> / C<< $msg->active_time_range($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Condition::TimeRange>)

Range of time(s) specifying when condition is active.

Maximum of 10 time ranges.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Control::Control

Defines a conditioned behavior to employ during serving.
Must be attached to a
[ServingConfig][google.cloud.discoveryengine.v1alpha.ServingConfig] to be
considered at serving time. Permitted actions dependent on `SolutionType`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->boost_action() >> / C<< $msg->boost_action($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control::BoostAction>)

Defines a boost-type control

=item * C<< $msg->filter_action() >> / C<< $msg->filter_action($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control::FilterAction>)

Defines a filter-type control
Currently not supported by Recommendation

=item * C<< $msg->redirect_action() >> / C<< $msg->redirect_action($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control::RedirectAction>)

Defines a redirect-type control.

=item * C<< $msg->synonyms_action() >> / C<< $msg->synonyms_action($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Control::SynonymsAction>)

Treats a group of terms as synonyms of one another.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/*/locations/global/dataStore/*/controls/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Human readable name. The identifier used in UI views.

Must be UTF-8 encoded string. Length limit is 128 characters.
Otherwise an INVALID ARGUMENT error is thrown.

=item * C<< $msg->associated_serving_config_ids() >> / C<< $msg->associated_serving_config_ids($value) >>

Type: C<String>

Output only. List of all
[ServingConfig][google.cloud.discoveryengine.v1alpha.ServingConfig] IDs
this control is attached to. May take up to 10 minutes to update after
changes.

=item * C<< $msg->solution_type() >> / C<< $msg->solution_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::SolutionType>)

Required. Immutable. What solution the control belongs to.

Must be compatible with vertical of resource.
Otherwise an INVALID ARGUMENT error is thrown.

=item * C<< $msg->use_cases() >> / C<< $msg->use_cases($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::SearchUseCase>)

Specifies the use case for the control.
Affects what condition fields can be set.
Only applies to
[SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].
Currently only allow one use case per control.
Must be set when solution_type is
[SolutionType.SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Control::Condition>)

Determines when the associated action will trigger.

Omit to always apply the action.
Currently only a single condition may be specified.
Otherwise an INVALID ARGUMENT error is thrown.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Control::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
