package Google::Cloud::Retail::V2alpha::ControlService;

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
    eval { require Google::Cloud::Retail::V2alpha::Control };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvY29udHJvbF9zZXJ2aWNlLnByb3RvEhtn
b29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGilnb29nbGUvY2xvdWQvcmV0YWls
L3YyYWxwaGEvY29udHJvbC5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBn
b29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byK+AQoUQ3JlYXRlQ29udHJvbFJlcXVl
c3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRh
bG9nUgZwYXJlbnQSQwoHY29udHJvbBgCIAEoCzIkLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5Db250cm9sQgPgQQJSB2NvbnRyb2wSIgoKY29udHJvbF9pZBgDIAEoCUID4EECUglj
b250cm9sSWQimAEKFFVwZGF0ZUNvbnRyb2xSZXF1ZXN0EkMKB2NvbnRyb2wYASABKAsyJC5n
b29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29udHJvbEID4EECUgdjb250cm9sEjsKC3Vw
ZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFz
ayJRChREZWxldGVDb250cm9sUmVxdWVzdBI5CgRuYW1lGAEgASgJQiXgQQL6QR8KHXJldGFp
bC5nb29nbGVhcGlzLmNvbS9Db250cm9sUgRuYW1lIk4KEUdldENvbnRyb2xSZXF1ZXN0EjkK
BG5hbWUYASABKAlCJeBBAvpBHwodcmV0YWlsLmdvb2dsZWFwaXMuY29tL0NvbnRyb2xSBG5h
bWUitwEKE0xpc3RDb250cm9sc1JlcXVlc3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJl
dGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9nUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgF
QgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsK
BmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIigAEKFExpc3RDb250cm9sc1Jlc3BvbnNlEkAK
CGNvbnRyb2xzGAEgAygLMiQuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNvbnRyb2xS
CGNvbnRyb2xzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbjKqCAoO
Q29udHJvbFNlcnZpY2US0wEKDUNyZWF0ZUNvbnRyb2wSMS5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuQ3JlYXRlQ29udHJvbFJlcXVlc3QaJC5nb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuQ29udHJvbCJpgtPkkwJHIjwvdjJhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyovY2F0YWxvZ3MvKn0vY29udHJvbHM6B2NvbnRyb2zaQRlwYXJlbnQsY29udHJv
bCxjb250cm9sX2lkEqcBCg1EZWxldGVDb250cm9sEjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmFscGhhLkRlbGV0ZUNvbnRyb2xSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkuC
0+STAj4qPC92MmFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3Mv
Ki9jb250cm9scy8qfdpBBG5hbWUS1QEKDVVwZGF0ZUNvbnRyb2wSMS5nb29nbGUuY2xvdWQu
cmV0YWlsLnYyYWxwaGEuVXBkYXRlQ29udHJvbFJlcXVlc3QaJC5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuQ29udHJvbCJrgtPkkwJPMkQvdjJhbHBoYS97Y29udHJvbC5uYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKi9jb250cm9scy8qfToHY29udHJvbNpB
E2NvbnRyb2wsdXBkYXRlX21hc2sSrwEKCkdldENvbnRyb2wSLi5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGEuR2V0Q29udHJvbFJlcXVlc3QaJC5nb29nbGUuY2xvdWQucmV0YWlsLnYy
YWxwaGEuQ29udHJvbCJLgtPkkwI+EjwvdjJhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NhdGFsb2dzLyovY29udHJvbHMvKn3aQQRuYW1lEsIBCgxMaXN0Q29udHJvbHMS
MC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuTGlzdENvbnRyb2xzUmVxdWVzdBoxLmdv
b2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5MaXN0Q29udHJvbHNSZXNwb25zZSJNgtPkkwI+
EjwvdjJhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0v
Y29udHJvbHPaQQZwYXJlbnQaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C1wEKH2NvbS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGFCE0NvbnRyb2xTZXJ2aWNlUHJvdG9QAVo3Y2xvdWQuZ29v
Z2xlLmNvbS9nby9yZXRhaWwvYXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJ
TKoCG0dvb2dsZS5DbG91ZC5SZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91ZFxSZXRhaWxc
VjJhbHBoYeoCHkdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUqGKwoHEgUOALgBAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAm
CgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADMKCQoCAwUSAxcA
JQoJCgIDBhIDGAAqCggKAQgSAxoAOAoJCgIIJRIDGgA4CggKAQgSAxsATgoJCgIICxIDGwBO
CggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4AOAoJ
CgIIARIDHgA4CggKAQgSAx8AJAoJCgIIJBIDHwAkCggKAQgSAyAAOAoJCgIIKRIDIAA4CggK
AQgSAyEANwoJCgIILRIDIQA3CiwKAgYAEgQkAF4BGiAgU2VydmljZSBmb3IgbW9kaWZ5aW5n
IENvbnRyb2wuCgoKCgMGAAESAyQIFgoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsKAwYA
AxIEJgInNwoNCgUGAAOaCBIEJgInNwqbAQoEBgACABIELQIzAxqMASBDcmVhdGVzIGEgQ29u
dHJvbC4KCiBJZiB0aGUgW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5D
b250cm9sXSB0byBjcmVhdGUgYWxyZWFkeQogZXhpc3RzLCBhbiBBTFJFQURZX0VYSVNUUyBl
cnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgABEgMtBhMKDAoFBgACAAISAy0UKAoMCgUGAAIA
AxIDLTM6Cg0KBQYAAgAEEgQuBDEGChEKCQYAAgAEsMq8IhIELgQxBgoMCgUGAAIABBIDMgRH
Cg8KCAYAAgAEmwgAEgMyBEcKlQEKBAYAAgESBDkCPgMahgEgRGVsZXRlcyBhIENvbnRyb2wu
CgogSWYgdGhlIFtDb250cm9sXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29udHJv
bF0gdG8gZGVsZXRlIGRvZXMgbm90CiBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0
dXJuZWQuCgoMCgUGAAIBARIDOQYTCgwKBQYAAgECEgM5FCgKDAoFBgACAQMSAzkzSAoNCgUG
AAIBBBIEOgQ8BgoRCgkGAAIBBLDKvCISBDoEPAYKDAoFBgACAQQSAz0EMgoPCggGAAIBBJsI
ABIDPQQyCpcCCgQGAAICEgRGAkwDGogCIFVwZGF0ZXMgYSBDb250cm9sLgoKIFtDb250cm9s
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29udHJvbF0gY2Fubm90IGJlIHNldCB0
byBhIGRpZmZlcmVudAogb25lb2YgZmllbGQsIGlmIHNvIGFuIElOVkFMSURfQVJHVU1FTlQg
aXMgcmV0dXJuZWQuIElmIHRoZQogW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJh
bHBoYS5Db250cm9sXSB0byB1cGRhdGUgZG9lcyBub3QgZXhpc3QsIGEKIE5PVF9GT1VORCBl
cnJvciBpcyByZXR1cm5lZC4KCgwKBQYAAgIBEgNGBhMKDAoFBgACAgISA0YUKAoMCgUGAAIC
AxIDRjM6Cg0KBQYAAgIEEgRHBEoGChEKCQYAAgIEsMq8IhIERwRKBgoMCgUGAAICBBIDSwRB
Cg8KCAYAAgIEmwgAEgNLBEEKHwoEBgACAxIETwJUAxoRIEdldHMgYSBDb250cm9sLgoKDAoF
BgACAwESA08GEAoMCgUGAAIDAhIDTxEiCgwKBQYAAgMDEgNPLTQKDQoFBgACAwQSBFAEUgYK
EQoJBgACAwSwyrwiEgRQBFIGCgwKBQYAAgMEEgNTBDIKDwoIBgACAwSbCAASA1MEMgpjCgQG
AAIEEgRYAl0DGlUgTGlzdHMgYWxsIENvbnRyb2xzIGJ5IHRoZWlyIHBhcmVudAogW0NhdGFs
b2ddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5DYXRhbG9nXS4KCgwKBQYAAgQBEgNY
BhIKDAoFBgACBAISA1gTJgoMCgUGAAIEAxIDWDFFCg0KBQYAAgQEEgRZBFsGChEKCQYAAgQE
sMq8IhIEWQRbBgoMCgUGAAIEBBIDXAQ0Cg8KCAYAAgQEmwgAEgNcBDQKLwoCBAASBGEAcgEa
IyBSZXF1ZXN0IGZvciBDcmVhdGVDb250cm9sIG1ldGhvZC4KCgoKAwQAARIDYQgcCpMBCgQE
AAIAEgRkAmcEGoQBIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUgb2YgcGFyZW50IGNh
dGFsb2cuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97
bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfWAKCgwKBQQAAgAFEgNkAggKDAoF
BAACAAESA2QJDwoMCgUEAAIAAxIDZBITCg0KBQQAAgAIEgRkFGcDCg8KCAQAAgAInAgAEgNl
BCoKDgoHBAACAAifCBIDZgRPCi8KBAQAAgESA2oCPxoiIFJlcXVpcmVkLiBUaGUgQ29udHJv
bCB0byBjcmVhdGUuCgoMCgUEAAIBBhIDagIJCgwKBQQAAgEBEgNqChEKDAoFBAACAQMSA2oU
FQoMCgUEAAIBCBIDahY+Cg8KCAQAAgEInAgAEgNqFz0K0QEKBAQAAgISA3ECQRrDASBSZXF1
aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIENvbnRyb2wsIHdoaWNoIHdpbGwgYmVjb21l
IHRoZSBmaW5hbAogY29tcG9uZW50IG9mIHRoZSBDb250cm9sJ3MgcmVzb3VyY2UgbmFtZS4K
CiBUaGlzIHZhbHVlIHNob3VsZCBiZSA0LTYzIGNoYXJhY3RlcnMsIGFuZCB2YWxpZCBjaGFy
YWN0ZXJzCiBhcmUgL1thLXpdWzAtOV0tXy8uCgoMCgUEAAICBRIDcQIICgwKBQQAAgIBEgNx
CRMKDAoFBAACAgMSA3EWFwoMCgUEAAICCBIDcRhACg8KCAQAAgIInAgAEgNxGT8KMAoCBAES
BXUAgQEBGiMgUmVxdWVzdCBmb3IgVXBkYXRlQ29udHJvbCBtZXRob2QuCgoKCgMEAQESA3UI
HAovCgQEAQIAEgN3Aj8aIiBSZXF1aXJlZC4gVGhlIENvbnRyb2wgdG8gdXBkYXRlLgoKDAoF
BAECAAYSA3cCCQoMCgUEAQIAARIDdwoRCgwKBQQBAgADEgN3FBUKDAoFBAECAAgSA3cWPgoP
CggEAQIACJwIABIDdxc9CooCCgQEAQIBEgSAAQIsGvsBIEluZGljYXRlcyB3aGljaCBmaWVs
ZHMgaW4gdGhlIHByb3ZpZGVkCiBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkNvbnRyb2xdIHRvIHVwZGF0ZS4gVGhlIGZvbGxvd2luZyBhcmUKIE5PVCBzdXBwb3J0
ZWQ6CgogKiBbQ29udHJvbC5uYW1lXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ29u
dHJvbC5uYW1lXQoKIElmIG5vdCBzZXQgb3IgZW1wdHksIGFsbCBzdXBwb3J0ZWQgZmllbGRz
IGFyZSB1cGRhdGVkLgoKDQoFBAECAQYSBIABAhsKDQoFBAECAQESBIABHCcKDQoFBAECAQMS
BIABKisKMQoCBAISBoQBAIsBARojIFJlcXVlc3QgZm9yIERlbGV0ZUNvbnRyb2wgbWV0aG9k
LgoKCwoDBAIBEgSEAQgcCrEBCgQEAgIAEgaHAQKKAQQaoAEgUmVxdWlyZWQuIFRoZSByZXNv
dXJjZSBuYW1lIG9mIHRoZSBDb250cm9sIHRvIGRlbGV0ZS4gRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2Nh
dGFsb2dfaWR9L2NvbnRyb2xzL3tjb250cm9sX2lkfWAKCg0KBQQCAgAFEgSHAQIICg0KBQQC
AgABEgSHAQkNCg0KBQQCAgADEgSHARARCg8KBQQCAgAIEgaHARKKAQMKEAoIBAICAAicCAAS
BIgBBCoKDwoHBAICAAifCBIEiQEETwouCgIEAxIGjgEAlQEBGiAgUmVxdWVzdCBmb3IgR2V0
Q29udHJvbCBtZXRob2QuCgoLCgMEAwESBI4BCBkKrgEKBAQDAgASBpEBApQBBBqdASBSZXF1
aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIENvbnRyb2wgdG8gZ2V0LiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9j
YXRhbG9ncy97Y2F0YWxvZ19pZH0vY29udHJvbHMve2NvbnRyb2xfaWR9YAoKDQoFBAMCAAUS
BJEBAggKDQoFBAMCAAESBJEBCQ0KDQoFBAMCAAMSBJEBEBEKDwoFBAMCAAgSBpEBEpQBAwoQ
CggEAwIACJwIABIEkgEEKgoPCgcEAwIACJ8IEgSTAQRPCjAKAgQEEgaYAQCvAQEaIiBSZXF1
ZXN0IGZvciBMaXN0Q29udHJvbHMgbWV0aG9kLgoKCwoDBAQBEgSYAQgbCokBCgQEBAIAEgab
AQKeAQQaeSBSZXF1aXJlZC4gVGhlIGNhdGFsb2cgcmVzb3VyY2UgbmFtZS4gRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0
YWxvZ3Mve2NhdGFsb2dfaWR9YAoKDQoFBAQCAAUSBJsBAggKDQoFBAQCAAESBJsBCQ8KDQoF
BAQCAAMSBJsBEhMKDwoFBAQCAAgSBpsBFJ4BAwoQCggEBAIACJwIABIEnAEEKgoPCgcEBAIA
CJ8IEgSdAQRPCnoKBAQEAgESBKIBAj8abCBPcHRpb25hbC4gTWF4aW11bSBudW1iZXIgb2Yg
cmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8gNTAuIE1h
eCBhbGxvd2VkIHZhbHVlIGlzIDEwMDAuCgoNCgUEBAIBBRIEogECBwoNCgUEBAIBARIEogEI
EQoNCgUEBAIBAxIEogEUFQoNCgUEBAIBCBIEogEWPgoQCggEBAIBCJwIABIEogEXPQqEAQoE
BAQCAhIEpgECQRp2IE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBw
cmV2aW91cyBgTGlzdENvbnRyb2xzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZl
IHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoNCgUEBAICBRIEpgECCAoNCgUEBAICARIEpgEJEwoN
CgUEBAICAxIEpgEWFwoNCgUEBAICCBIEpgEYQAoQCggEBAICCJwIABIEpgEZPwrAAgoEBAQC
AxIErgECPRqxAiBPcHRpb25hbC4gQSBmaWx0ZXIgdG8gYXBwbHkgb24gdGhlIGxpc3QgcmVz
dWx0cy4gU3VwcG9ydGVkIGZlYXR1cmVzOgoKICogTGlzdCBhbGwgdGhlIHByb2R1Y3RzIHVu
ZGVyIHRoZSBwYXJlbnQgYnJhbmNoIGlmCiBbZmlsdGVyXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuTGlzdENvbnRyb2xzUmVxdWVzdC5maWx0ZXJdIGlzIHVuc2V0LgogKiBMaXN0
IGNvbnRyb2xzIHRoYXQgYXJlIHVzZWQgaW4gYSBzaW5nbGUgU2VydmluZ0NvbmZpZzoKICAg
ICAnc2VydmluZ19jb25maWcgPSAiYm9vc3RlZF9ob21lX3BhZ2VfY3ZyIicKCg0KBQQEAgMF
EgSuAQIICg0KBQQEAgMBEgSuAQkPCg0KBQQEAgMDEgSuARITCg0KBQQEAgMIEgSuARQ8ChAK
CAQEAgMInAgAEgSuARU7CjEKAgQFEgayAQC4AQEaIyBSZXNwb25zZSBmb3IgTGlzdENvbnRy
b2xzIG1ldGhvZC4KCgsKAwQFARIEsgEIHAo1CgQEBQIAEgS0AQIgGicgQWxsIHRoZSBDb250
cm9scyBmb3IgYSBnaXZlbiBjYXRhbG9nLgoKDQoFBAUCAAQSBLQBAgoKDQoFBAUCAAYSBLQB
CxIKDQoFBAUCAAESBLQBExsKDQoFBAUCAAMSBLQBHh8KSgoEBAUCARIEtwECHRo8IFBhZ2lu
YXRpb24gdG9rZW4sIGlmIG5vdCByZXR1cm5lZCBpbmRpY2F0ZXMgdGhlIGxhc3QgcGFnZS4K
Cg0KBQQFAgEFEgS3AQIICg0KBQQFAgEBEgS3AQkYCg0KBQQFAgEDEgS3ARscYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest ===
    # Fields for CreateControlRequest
    # Field: parent Type: 9 ()
    # Field: control Type: 11 (.google.cloud.retail.v2alpha.Control)
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ControlService::UpdateControlRequest ===
    # Fields for UpdateControlRequest
    # Field: control Type: 11 (.google.cloud.retail.v2alpha.Control)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2alpha::ControlService::DeleteControlRequest ===
    # Fields for DeleteControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ControlService::GetControlRequest ===
    # Fields for GetControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ControlService::ListControlsRequest ===
    # Fields for ListControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ControlService::ListControlsResponse ===
    # Fields for ListControlsResponse
    # Field: controls Type: 11 (.google.cloud.retail.v2alpha.Control)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2alpha::ControlService::ControlServiceClient ===
package Google::Cloud::Retail::V2alpha::ControlService::ControlServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::ControlService::ControlServiceClient

Client stub representing the remote C<ControlService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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
        ? Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ControlService',
        method         => 'CreateControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Control::Control',
    });
}

sub delete_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ControlService::DeleteControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ControlService',
        method         => 'DeleteControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ControlService::UpdateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ControlService',
        method         => 'UpdateControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Control::Control',
    });
}

sub get_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ControlService::GetControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ControlService',
        method         => 'GetControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::Control::Control',
    });
}

sub list_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ControlService::ListControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.ControlService',
        method         => 'ListControls',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::ControlService::ListControlsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::ControlService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/control_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::ControlService;

    my $msg = Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest->new({
        parent => $parent,
        control => $control,
        control_id => $control_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/control_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest

Request for CreateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent catalog. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Control::Control>)

Required. The Control to create.

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The ID to use for the Control, which will become the final
component of the Control's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Retail::V2alpha::ControlService::UpdateControlRequest

Request for UpdateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Control::Control>)

Required. The Control to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Control][google.cloud.retail.v2alpha.Control] to update. The following are
NOT supported:

* [Control.name][google.cloud.retail.v2alpha.Control.name]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2alpha::ControlService::DeleteControlRequest

Request for DeleteControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ControlService::GetControlRequest

Request for GetControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Retail::V2alpha::ControlService::ListControlsRequest

Request for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The catalog resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

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
[filter][google.cloud.retail.v2alpha.ListControlsRequest.filter] is unset.
* List controls that are used in a single ServingConfig:
    'serving_config = "boosted_home_page_cvr"'

=back

=head2 Google::Cloud::Retail::V2alpha::ControlService::ListControlsResponse

Response for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->controls() >> / C<< $msg->controls($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Control::Control>)

All the Controls for a given catalog.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::ControlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
