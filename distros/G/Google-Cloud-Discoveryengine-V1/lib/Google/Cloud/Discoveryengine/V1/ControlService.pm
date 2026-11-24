package Google::Cloud::Discoveryengine::V1::ControlService;

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
    eval { require Google::Cloud::Discoveryengine::V1::Control };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NvbnRyb2xfc2VydmljZS5wcm90
bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9jbG91
ZC9kaXNjb3ZlcnllbmdpbmUvdjEvY29udHJvbC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2Vt
cHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byLLAQoUQ3JlYXRl
Q29udHJvbFJlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgSJmRpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9Db250cm9sUgZwYXJlbnQSRwoHY29udHJvbBgCIAEoCzIoLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29udHJvbEID4EECUgdjb250cm9sEiIK
CmNvbnRyb2xfaWQYAyABKAlCA+BBAlIJY29udHJvbElkIqEBChRVcGRhdGVDb250cm9sUmVx
dWVzdBJHCgdjb250cm9sGAEgASgLMiguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5Db250cm9sQgPgQQJSB2NvbnRyb2wSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siWgoURGVsZXRlQ29udHJvbFJl
cXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC+kEoCiZkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb20vQ29udHJvbFIEbmFtZSJXChFHZXRDb250cm9sUmVxdWVzdBJCCgRuYW1lGAEgASgJ
Qi7gQQL6QSgKJmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db250cm9sUgRuYW1l
IsABChNMaXN0Q29udHJvbHNSZXF1ZXN0EkYKBnBhcmVudBgBIAEoCUIu4EEC+kEoEiZkaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29udHJvbFIGcGFyZW50EiAKCXBhZ2Vfc2l6
ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VU
b2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIoQBChRMaXN0Q29udHJvbHNSZXNw
b25zZRJECghjb250cm9scxgBIAMoCzIoLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuQ29udHJvbFIIY29udHJvbHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuMuMPCg5Db250cm9sU2VydmljZRL/AgoNQ3JlYXRlQ29udHJvbBI1Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ3JlYXRlQ29udHJvbFJlcXVlc3QaKC5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNvbnRyb2wijAKC0+STAukBIjkvdjEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vY29udHJvbHM6B2NvbnRy
b2xaUiJHL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8q
L2RhdGFTdG9yZXMvKn0vY29udHJvbHM6B2NvbnRyb2xaTyJEL3YxL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKn0vY29udHJvbHM6B2Nv
bnRyb2zaQRlwYXJlbnQsY29udHJvbCxjb250cm9sX2lkEr0CCg1EZWxldGVDb250cm9sEjUu
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EZWxldGVDb250cm9sUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eSLcAYLT5JMCzgEqOS92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9jb250cm9scy8qfVpJKkcvdjEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9jb250cm9s
cy8qfVpGKkQvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8q
L2VuZ2luZXMvKi9jb250cm9scy8qfdpBBG5hbWUSkQMKDVVwZGF0ZUNvbnRyb2wSNS5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVwZGF0ZUNvbnRyb2xSZXF1ZXN0GiguZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db250cm9sIp4CgtPkkwKBAjJBL3YxL3tj
b250cm9sLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovY29udHJv
bHMvKn06B2NvbnRyb2xaWjJPL3YxL3tjb250cm9sLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9jb250cm9scy8qfToHY29udHJvbFpX
MkwvdjEve2NvbnRyb2wubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25z
LyovZW5naW5lcy8qL2NvbnRyb2xzLyp9Ogdjb250cm9s2kETY29udHJvbCx1cGRhdGVfbWFz
axLJAgoKR2V0Q29udHJvbBIyLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuR2V0
Q29udHJvbFJlcXVlc3QaKC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNvbnRy
b2wi3AGC0+STAs4BEjkvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3Rv
cmVzLyovY29udHJvbHMvKn1aSRJHL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
Y29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovY29udHJvbHMvKn1aRhJEL3YxL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovY29udHJvbHMv
Kn3aQQRuYW1lEtwCCgxMaXN0Q29udHJvbHMSNC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkxpc3RDb250cm9sc1JlcXVlc3QaNS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkxpc3RDb250cm9sc1Jlc3BvbnNlIt4BgtPkkwLOARI5L3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L2NvbnRyb2xzWkkSRy92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9
L2NvbnRyb2xzWkYSRC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVj
dGlvbnMvKi9lbmdpbmVzLyp9L2NvbnRyb2xz2kEGcGFyZW50Gs8BykEeZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zl
cnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlz
Y292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQoYCCiNjb20uZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MUITQ29udHJvbFNlcnZpY2VQcm90b1ABWk1jbG91ZC5nb29nbGUu
Y29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3Zl
cnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlF
bmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpD
bG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUqmMAoHEgUOAO0BAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADcKCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggK
AQgSAxoAPAoJCgIIJRIDGgA8CggKAQgSAxsAZAoJCgIICxIDGwBkCggKAQgSAxwAIgoJCgII
ChIDHAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4APAoJCgIIARIDHgA8CggKAQgS
Ax8ALQoJCgIIJBIDHwAtCggKAQgSAyAAPAoJCgIIKRIDIAA8CggKAQgSAyEAOwoJCgIILRID
IQA7CuEBCgIGABIFJwCGAQEa0wEgU2VydmljZSBmb3IgcGVyZm9ybWluZyBDUlVEIG9wZXJh
dGlvbnMgb24gQ29udHJvbHMuCiBDb250cm9scyBhbGxvdyBmb3IgY3VzdG9tIGxvZ2ljIHRv
IGJlIGltcGxlbWVudGVkIGluIHRoZSBzZXJ2aW5nIHBhdGguCiBDb250cm9scyBuZWVkIHRv
IGJlIGF0dGFjaGVkIHRvIGEgU2VydmluZyBDb25maWcgdG8gYmUgY29uc2lkZXJlZCBkdXJp
bmcgYQogcmVxdWVzdC4KCgoKAwYAARIDJwgWCgoKAwYAAxIDKAJGCgwKBQYAA5kIEgMoAkYK
CwoDBgADEgQpAixKCg0KBQYAA5oIEgQpAixKCokCCgQGAAIAEgQ0AkIDGvoBIENyZWF0ZXMg
YSBDb250cm9sLgoKIEJ5IGRlZmF1bHQgMTAwMCBjb250cm9scyBhcmUgYWxsb3dlZCBmb3Ig
YSBkYXRhIHN0b3JlLgogQSByZXF1ZXN0IGNhbiBiZSBzdWJtaXR0ZWQgdG8gYWRqdXN0IHRo
aXMgbGltaXQuCiBJZiB0aGUgW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuQ29udHJvbF0gdG8gY3JlYXRlIGFscmVhZHkKIGV4aXN0cywgYW4gQUxSRUFEWV9F
WElTVFMgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAIAARIDNAYTCgwKBQYAAgACEgM0FCgK
DAoFBgACAAMSAzQzOgoNCgUGAAIABBIENQRABgoRCgkGAAIABLDKvCISBDUEQAYKDAoFBgAC
AAQSA0EERwoPCggGAAIABJsIABIDQQRHCpkBCgQGAAIBEgRIAlMDGooBIERlbGV0ZXMgYSBD
b250cm9sLgoKIElmIHRoZSBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5Db250cm9sXSB0byBkZWxldGUgZG9lcwogbm90IGV4aXN0LCBhIE5PVF9GT1VORCBl
cnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgEBEgNIBhMKDAoFBgACAQISA0gUKAoMCgUGAAIB
AxIDSDNICg0KBQYAAgEEEgRJBFEGChEKCQYAAgEEsMq8IhIESQRRBgoMCgUGAAIBBBIDUgQy
Cg8KCAYAAgEEmwgAEgNSBDIK7AEKBAYAAgISBFoCaAMa3QEgVXBkYXRlcyBhIENvbnRyb2wu
CgogW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29udHJvbF0g
YWN0aW9uIHR5cGUgY2Fubm90IGJlCiBjaGFuZ2VkLiBJZiB0aGUgW0NvbnRyb2xdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQ29udHJvbF0gdG8KIHVwZGF0ZSBkb2VzIG5v
dCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAICARIDWgYT
CgwKBQYAAgICEgNaFCgKDAoFBgACAgMSA1ozOgoNCgUGAAICBBIEWwRmBgoRCgkGAAICBLDK
vCISBFsEZgYKDAoFBgACAgQSA2cEQQoPCggGAAICBJsIABIDZwRBCh8KBAYAAgMSBGsCdgMa
ESBHZXRzIGEgQ29udHJvbC4KCgwKBQYAAgMBEgNrBhAKDAoFBgACAwISA2sRIgoMCgUGAAID
AxIDay00Cg0KBQYAAgMEEgRsBHQGChEKCQYAAgMEsMq8IhIEbAR0BgoMCgUGAAIDBBIDdQQy
Cg8KCAYAAgMEmwgAEgN1BDIKbAoEBgACBBIFegKFAQMaXSBMaXN0cyBhbGwgQ29udHJvbHMg
YnkgdGhlaXIgcGFyZW50CiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkRhdGFTdG9yZV0uCgoMCgUGAAIEARIDegYSCgwKBQYAAgQCEgN6EyYKDAoFBgAC
BAMSA3oxRQoOCgUGAAIEBBIFewSDAQYKEgoJBgACBASwyrwiEgV7BIMBBgoNCgUGAAIEBBIE
hAEENAoQCggGAAIEBJsIABIEhAEENAoxCgIEABIGiQEAngEBGiMgUmVxdWVzdCBmb3IgQ3Jl
YXRlQ29udHJvbCBtZXRob2QuCgoLCgMEAAESBIkBCBwKjwIKBAQAAgASBo4BApMBBBr+ASBS
ZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mIHBhcmVudCBkYXRhIHN0b3JlLiBGb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rp
b25zL3tjb2xsZWN0aW9uX2lkfS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlX2lkfWAKIG9yCiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tj
b2xsZWN0aW9uX2lkfS9lbmdpbmVzL3tlbmdpbmVfaWR9YC4KCg0KBQQAAgAFEgSOAQIICg0K
BQQAAgABEgSOAQkPCg0KBQQAAgADEgSOARITCg8KBQQAAgAIEgaOARSTAQMKEAoIBAACAAic
CAASBI8BBCoKEQoHBAACAAifCBIGkAEEkgEFCjAKBAQAAgESBJYBAj8aIiBSZXF1aXJlZC4g
VGhlIENvbnRyb2wgdG8gY3JlYXRlLgoKDQoFBAACAQYSBJYBAgkKDQoFBAACAQESBJYBChEK
DQoFBAACAQMSBJYBFBUKDQoFBAACAQgSBJYBFj4KEAoIBAACAQicCAASBJYBFz0K0wEKBAQA
AgISBJ0BAkEaxAEgUmVxdWlyZWQuIFRoZSBJRCB0byB1c2UgZm9yIHRoZSBDb250cm9sLCB3
aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgQ29udHJvbCdz
IHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBtdXN0IGJlIHdpdGhpbiAxLTYzIGNoYXJh
Y3RlcnMuCiBWYWxpZCBjaGFyYWN0ZXJzIGFyZSAvW2Etel1bMC05XS1fLy4KCg0KBQQAAgIF
EgSdAQIICg0KBQQAAgIBEgSdAQkTCg0KBQQAAgIDEgSdARYXCg0KBQQAAgIIEgSdARhAChAK
CAQAAgIInAgAEgSdARk/CjEKAgQBEgahAQCvAQEaIyBSZXF1ZXN0IGZvciBVcGRhdGVDb250
cm9sIG1ldGhvZC4KCgsKAwQBARIEoQEIHAowCgQEAQIAEgSjAQI/GiIgUmVxdWlyZWQuIFRo
ZSBDb250cm9sIHRvIHVwZGF0ZS4KCg0KBQQBAgAGEgSjAQIJCg0KBQQBAgABEgSjAQoRCg0K
BQQBAgADEgSjARQVCg0KBQQBAgAIEgSjARY+ChAKCAQBAgAInAgAEgSjARc9CvACCgQEAQIB
EgatAQKuAS8a3wIgT3B0aW9uYWwuIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHBy
b3ZpZGVkCiBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db250
cm9sXSB0byB1cGRhdGUuIFRoZSBmb2xsb3dpbmcKIGFyZSBOT1Qgc3VwcG9ydGVkOgoKICog
W0NvbnRyb2wubmFtZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db250cm9s
Lm5hbWVdCiAqIFtDb250cm9sLnNvbHV0aW9uX3R5cGVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuQ29udHJvbC5zb2x1dGlvbl90eXBlXQoKIElmIG5vdCBzZXQgb3IgZW1w
dHksIGFsbCBzdXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoFBAECAQYSBK0BAhsK
DQoFBAECAQESBK0BHCcKDQoFBAECAQMSBK0BKisKDQoFBAECAQgSBK4BBi4KEAoIBAECAQic
CAASBK4BBy0KMQoCBAISBrIBALsBARojIFJlcXVlc3QgZm9yIERlbGV0ZUNvbnRyb2wgbWV0
aG9kLgoKCwoDBAIBEgSyAQgcCsgBCgQEAgIAEga1AQK6AQQatwEgUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBDb250cm9sIHRvIGRlbGV0ZS4gRm9ybWF0OgogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVj
dGlvbl9pZH0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZV9pZH0vY29udHJvbHMve2NvbnRyb2xf
aWR9YAoKDQoFBAICAAUSBLUBAggKDQoFBAICAAESBLUBCQ0KDQoFBAICAAMSBLUBEBEKDwoF
BAICAAgSBrUBEroBAwoQCggEAgIACJwIABIEtgEEKgoRCgcEAgIACJ8IEga3AQS5AQUKLgoC
BAMSBr4BAMcBARogIFJlcXVlc3QgZm9yIEdldENvbnRyb2wgbWV0aG9kLgoKCwoDBAMBEgS+
AQgZCsUBCgQEAwIAEgbBAQLGAQQatAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBDb250cm9sIHRvIGdldC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZGF0YVN0b3Jl
cy97ZGF0YV9zdG9yZV9pZH0vY29udHJvbHMve2NvbnRyb2xfaWR9YAoKDQoFBAMCAAUSBMEB
AggKDQoFBAMCAAESBMEBCQ0KDQoFBAMCAAMSBMEBEBEKDwoFBAMCAAgSBsEBEsYBAwoQCggE
AwIACJwIABIEwgEEKgoRCgcEAwIACJ8IEgbDAQTFAQUKMAoCBAQSBsoBAOQBARoiIFJlcXVl
c3QgZm9yIExpc3RDb250cm9scyBtZXRob2QuCgoLCgMEBAESBMoBCBsKhAIKBAQEAgASBs8B
AtQBBBrzASBSZXF1aXJlZC4gVGhlIGRhdGEgc3RvcmUgcmVzb3VyY2UgbmFtZS4gRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9u
cy97Y29sbGVjdGlvbl9pZH0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZV9pZH1gCiBvcgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29s
bGVjdGlvbl9pZH0vZW5naW5lcy97ZW5naW5lX2lkfWAuCgoNCgUEBAIABRIEzwECCAoNCgUE
BAIAARIEzwEJDwoNCgUEBAIAAxIEzwESEwoPCgUEBAIACBIGzwEU1AEDChAKCAQEAgAInAgA
EgTQAQQqChEKBwQEAgAInwgSBtEBBNMBBQp6CgQEBAIBEgTYAQI/GmwgT3B0aW9uYWwuIE1h
eGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwgZGVm
YXVsdHMKIHRvIDUwLiBNYXggYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLgoKDQoFBAQCAQUSBNgB
AgcKDQoFBAQCAQESBNgBCBEKDQoFBAQCAQMSBNgBFBUKDQoFBAQCAQgSBNgBFj4KEAoIBAQC
AQicCAASBNgBFz0KhAEKBAQEAgISBNwBAkEadiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCBy
ZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RDb250cm9sc2AgY2FsbC4KIFByb3ZpZGUg
dGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBAQCAgUSBNwBAggK
DQoFBAQCAgESBNwBCRMKDQoFBAQCAgMSBNwBFhcKDQoFBAQCAggSBNwBGEAKEAoIBAQCAgic
CAASBNwBGT8KgAIKBAQEAgMSBOMBAj0a8QEgT3B0aW9uYWwuIEEgZmlsdGVyIHRvIGFwcGx5
IG9uIHRoZSBsaXN0IHJlc3VsdHMuIFN1cHBvcnRlZCBmZWF0dXJlczoKCiAqIExpc3QgYWxs
IHRoZSBwcm9kdWN0cyB1bmRlciB0aGUgcGFyZW50IGJyYW5jaCBpZgogW2ZpbHRlcl1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0Q29udHJvbHNSZXF1ZXN0LmZpbHRl
cl0gaXMKIHVuc2V0LiBDdXJyZW50bHkgdGhpcyBmaWVsZCBpcyB1bnN1cHBvcnRlZC4KCg0K
BQQEAgMFEgTjAQIICg0KBQQEAgMBEgTjAQkPCg0KBQQEAgMDEgTjARITCg0KBQQEAgMIEgTj
ARQ8ChAKCAQEAgMInAgAEgTjARU7CjEKAgQFEgbnAQDtAQEaIyBSZXNwb25zZSBmb3IgTGlz
dENvbnRyb2xzIG1ldGhvZC4KCgsKAwQFARIE5wEIHAo4CgQEBQIAEgTpAQIgGiogQWxsIHRo
ZSBDb250cm9scyBmb3IgYSBnaXZlbiBkYXRhIHN0b3JlLgoKDQoFBAUCAAQSBOkBAgoKDQoF
BAUCAAYSBOkBCxIKDQoFBAUCAAESBOkBExsKDQoFBAUCAAMSBOkBHh8KSgoEBAUCARIE7AEC
HRo8IFBhZ2luYXRpb24gdG9rZW4sIGlmIG5vdCByZXR1cm5lZCBpbmRpY2F0ZXMgdGhlIGxh
c3QgcGFnZS4KCg0KBQQFAgEFEgTsAQIICg0KBQQFAgEBEgTsAQkYCg0KBQQFAgEDEgTsARsc
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest ===
    # Fields for CreateControlRequest
    # Field: parent Type: 9 ()
    # Field: control Type: 11 (.google.cloud.discoveryengine.v1.Control)
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ControlService::UpdateControlRequest ===
    # Fields for UpdateControlRequest
    # Field: control Type: 11 (.google.cloud.discoveryengine.v1.Control)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1::ControlService::DeleteControlRequest ===
    # Fields for DeleteControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ControlService::GetControlRequest ===
    # Fields for GetControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ControlService::ListControlsRequest ===
    # Fields for ListControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::ControlService::ListControlsResponse ===
    # Fields for ListControlsResponse
    # Field: controls Type: 11 (.google.cloud.discoveryengine.v1.Control)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1::ControlService::ControlServiceClient ===
package Google::Cloud::Discoveryengine::V1::ControlService::ControlServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::ControlService::ControlServiceClient

Client stub representing the remote C<ControlService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub create_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ControlService',
        method         => 'CreateControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Control::Control',
    });
}

sub delete_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ControlService::DeleteControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ControlService',
        method         => 'DeleteControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ControlService::UpdateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ControlService',
        method         => 'UpdateControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Control::Control',
    });
}

sub get_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ControlService::GetControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ControlService',
        method         => 'GetControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::Control::Control',
    });
}

sub list_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::ControlService::ListControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.ControlService',
        method         => 'ListControls',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::ControlService::ListControlsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::ControlService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/control_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::ControlService;

    my $msg = Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest->new({
        parent => $parent,
        control => $control,
        control_id => $control_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/control_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest

Request for CreateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent data store. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`
or
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Control::Control>)

Required. The Control to create.

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The ID to use for the Control, which will become the final
component of the Control's resource name.

This value must be within 1-63 characters.
Valid characters are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Discoveryengine::V1::ControlService::UpdateControlRequest

Request for UpdateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Control::Control>)

Required. The Control to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[Control][google.cloud.discoveryengine.v1.Control] to update. The following
are NOT supported:

* [Control.name][google.cloud.discoveryengine.v1.Control.name]
* [Control.solution_type][google.cloud.discoveryengine.v1.Control.solution_type]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Discoveryengine::V1::ControlService::DeleteControlRequest

Request for DeleteControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to delete. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1::ControlService::GetControlRequest

Request for GetControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to get. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1::ControlService::ListControlsRequest

Request for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The data store resource name. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`
or
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 50. Max allowed value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListControls` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter to apply on the list results. Supported features:

* List all the products under the parent branch if
[filter][google.cloud.discoveryengine.v1.ListControlsRequest.filter] is
unset. Currently this field is unsupported.

=back

=head2 Google::Cloud::Discoveryengine::V1::ControlService::ListControlsResponse

Response for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->controls() >> / C<< $msg->controls($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Control::Control>)

All the Controls for a given data store.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::ControlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
