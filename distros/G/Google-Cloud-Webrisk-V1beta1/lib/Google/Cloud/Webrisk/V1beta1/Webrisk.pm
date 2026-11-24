package Google::Cloud::Webrisk::V1beta1::Webrisk;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvd2Vicmlzay92MWJldGExL3dlYnJpc2sucHJvdG8SHGdvb2dsZS5j
bG91ZC53ZWJyaXNrLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItQDChxDb21wdXRlVGhyZWF0TGlz
dERpZmZSZXF1ZXN0Ek4KC3RocmVhdF90eXBlGAEgASgOMiguZ29vZ2xlLmNsb3VkLndlYnJp
c2sudjFiZXRhMS5UaHJlYXRUeXBlQgPgQQJSCnRocmVhdFR5cGUSIwoNdmVyc2lvbl90b2tl
bhgCIAEoDFIMdmVyc2lvblRva2VuEm0KC2NvbnN0cmFpbnRzGAMgASgLMkYuZ29vZ2xlLmNs
b3VkLndlYnJpc2sudjFiZXRhMS5Db21wdXRlVGhyZWF0TGlzdERpZmZSZXF1ZXN0LkNvbnN0
cmFpbnRzQgPgQQJSC2NvbnN0cmFpbnRzGs8BCgtDb25zdHJhaW50cxIoChBtYXhfZGlmZl9l
bnRyaWVzGAEgASgFUg5tYXhEaWZmRW50cmllcxIwChRtYXhfZGF0YWJhc2VfZW50cmllcxgC
IAEoBVISbWF4RGF0YWJhc2VFbnRyaWVzEmQKFnN1cHBvcnRlZF9jb21wcmVzc2lvbnMYAyAD
KA4yLS5nb29nbGUuY2xvdWQud2Vicmlzay52MWJldGExLkNvbXByZXNzaW9uVHlwZVIVc3Vw
cG9ydGVkQ29tcHJlc3Npb25zIvUECh1Db21wdXRlVGhyZWF0TGlzdERpZmZSZXNwb25zZRJt
Cg1yZXNwb25zZV90eXBlGAQgASgOMkguZ29vZ2xlLmNsb3VkLndlYnJpc2sudjFiZXRhMS5D
b21wdXRlVGhyZWF0TGlzdERpZmZSZXNwb25zZS5SZXNwb25zZVR5cGVSDHJlc3BvbnNlVHlw
ZRJQCglhZGRpdGlvbnMYBSABKAsyMi5nb29nbGUuY2xvdWQud2Vicmlzay52MWJldGExLlRo
cmVhdEVudHJ5QWRkaXRpb25zUglhZGRpdGlvbnMSTQoIcmVtb3ZhbHMYBiABKAsyMS5nb29n
bGUuY2xvdWQud2Vicmlzay52MWJldGExLlRocmVhdEVudHJ5UmVtb3ZhbHNSCHJlbW92YWxz
EioKEW5ld192ZXJzaW9uX3Rva2VuGAcgASgMUg9uZXdWZXJzaW9uVG9rZW4SYAoIY2hlY2tz
dW0YCCABKAsyRC5nb29nbGUuY2xvdWQud2Vicmlzay52MWJldGExLkNvbXB1dGVUaHJlYXRM
aXN0RGlmZlJlc3BvbnNlLkNoZWNrc3VtUghjaGVja3N1bRJOChVyZWNvbW1lbmRlZF9uZXh0
X2RpZmYYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhNyZWNvbW1lbmRlZE5l
eHREaWZmGiIKCENoZWNrc3VtEhYKBnNoYTI1NhgBIAEoDFIGc2hhMjU2IkIKDFJlc3BvbnNl
VHlwZRIdChlSRVNQT05TRV9UWVBFX1VOU1BFQ0lGSUVEEAASCAoERElGRhABEgkKBVJFU0VU
EAIifAoRU2VhcmNoVXJpc1JlcXVlc3QSFQoDdXJpGAEgASgJQgPgQQJSA3VyaRJQCgx0aHJl
YXRfdHlwZXMYAiADKA4yKC5nb29nbGUuY2xvdWQud2Vicmlzay52MWJldGExLlRocmVhdFR5
cGVCA+BBAlILdGhyZWF0VHlwZXMigAIKElNlYXJjaFVyaXNSZXNwb25zZRJSCgZ0aHJlYXQY
ASABKAsyOi5nb29nbGUuY2xvdWQud2Vicmlzay52MWJldGExLlNlYXJjaFVyaXNSZXNwb25z
ZS5UaHJlYXRVcmlSBnRocmVhdBqVAQoJVGhyZWF0VXJpEksKDHRocmVhdF90eXBlcxgBIAMo
DjIoLmdvb2dsZS5jbG91ZC53ZWJyaXNrLnYxYmV0YTEuVGhyZWF0VHlwZVILdGhyZWF0VHlw
ZXMSOwoLZXhwaXJlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpl
eHBpcmVUaW1lIogBChNTZWFyY2hIYXNoZXNSZXF1ZXN0Eh8KC2hhc2hfcHJlZml4GAEgASgM
UgpoYXNoUHJlZml4ElAKDHRocmVhdF90eXBlcxgCIAMoDjIoLmdvb2dsZS5jbG91ZC53ZWJy
aXNrLnYxYmV0YTEuVGhyZWF0VHlwZUID4EECUgt0aHJlYXRUeXBlcyLqAgoUU2VhcmNoSGFz
aGVzUmVzcG9uc2USVwoHdGhyZWF0cxgBIAMoCzI9Lmdvb2dsZS5jbG91ZC53ZWJyaXNrLnYx
YmV0YTEuU2VhcmNoSGFzaGVzUmVzcG9uc2UuVGhyZWF0SGFzaFIHdGhyZWF0cxJMChRuZWdh
dGl2ZV9leHBpcmVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSEm5l
Z2F0aXZlRXhwaXJlVGltZRqqAQoKVGhyZWF0SGFzaBJLCgx0aHJlYXRfdHlwZXMYASADKA4y
KC5nb29nbGUuY2xvdWQud2Vicmlzay52MWJldGExLlRocmVhdFR5cGVSC3RocmVhdFR5cGVz
EhIKBGhhc2gYAiABKAxSBGhhc2gSOwoLZXhwaXJlX3RpbWUYAyABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUgpleHBpcmVUaW1lIrABChRUaHJlYXRFbnRyeUFkZGl0aW9ucxJG
CgpyYXdfaGFzaGVzGAEgAygLMicuZ29vZ2xlLmNsb3VkLndlYnJpc2sudjFiZXRhMS5SYXdI
YXNoZXNSCXJhd0hhc2hlcxJQCgtyaWNlX2hhc2hlcxgCIAEoCzIvLmdvb2dsZS5jbG91ZC53
ZWJyaXNrLnYxYmV0YTEuUmljZURlbHRhRW5jb2RpbmdSCnJpY2VIYXNoZXMitAEKE1RocmVh
dEVudHJ5UmVtb3ZhbHMSSQoLcmF3X2luZGljZXMYASABKAsyKC5nb29nbGUuY2xvdWQud2Vi
cmlzay52MWJldGExLlJhd0luZGljZXNSCnJhd0luZGljZXMSUgoMcmljZV9pbmRpY2VzGAIg
ASgLMi8uZ29vZ2xlLmNsb3VkLndlYnJpc2sudjFiZXRhMS5SaWNlRGVsdGFFbmNvZGluZ1IL
cmljZUluZGljZXMiJgoKUmF3SW5kaWNlcxIYCgdpbmRpY2VzGAEgAygFUgdpbmRpY2VzIksK
CVJhd0hhc2hlcxIfCgtwcmVmaXhfc2l6ZRgBIAEoBVIKcHJlZml4U2l6ZRIdCgpyYXdfaGFz
aGVzGAIgASgMUglyYXdIYXNoZXMinwEKEVJpY2VEZWx0YUVuY29kaW5nEh8KC2ZpcnN0X3Zh
bHVlGAEgASgDUgpmaXJzdFZhbHVlEiUKDnJpY2VfcGFyYW1ldGVyGAIgASgFUg1yaWNlUGFy
YW1ldGVyEh8KC2VudHJ5X2NvdW50GAMgASgFUgplbnRyeUNvdW50EiEKDGVuY29kZWRfZGF0
YRgEIAEoDFILZW5jb2RlZERhdGEqZQoKVGhyZWF0VHlwZRIbChdUSFJFQVRfVFlQRV9VTlNQ
RUNJRklFRBAAEgsKB01BTFdBUkUQARIWChJTT0NJQUxfRU5HSU5FRVJJTkcQAhIVChFVTldB
TlRFRF9TT0ZUV0FSRRADKkYKD0NvbXByZXNzaW9uVHlwZRIgChxDT01QUkVTU0lPTl9UWVBF
X1VOU1BFQ0lGSUVEEAASBwoDUkFXEAESCAoEUklDRRACMp4FChVXZWJSaXNrU2VydmljZVYx
QmV0YTES4gEKFUNvbXB1dGVUaHJlYXRMaXN0RGlmZhI6Lmdvb2dsZS5jbG91ZC53ZWJyaXNr
LnYxYmV0YTEuQ29tcHV0ZVRocmVhdExpc3REaWZmUmVxdWVzdBo7Lmdvb2dsZS5jbG91ZC53
ZWJyaXNrLnYxYmV0YTEuQ29tcHV0ZVRocmVhdExpc3REaWZmUmVzcG9uc2UiUILT5JMCIhIg
L3YxYmV0YTEvdGhyZWF0TGlzdHM6Y29tcHV0ZURpZmbaQSV0aHJlYXRfdHlwZSx2ZXJzaW9u
X3Rva2VuLGNvbnN0cmFpbnRzEqABCgpTZWFyY2hVcmlzEi8uZ29vZ2xlLmNsb3VkLndlYnJp
c2sudjFiZXRhMS5TZWFyY2hVcmlzUmVxdWVzdBowLmdvb2dsZS5jbG91ZC53ZWJyaXNrLnYx
YmV0YTEuU2VhcmNoVXJpc1Jlc3BvbnNlIi+C0+STAhYSFC92MWJldGExL3VyaXM6c2VhcmNo
2kEQdXJpLHRocmVhdF90eXBlcxKwAQoMU2VhcmNoSGFzaGVzEjEuZ29vZ2xlLmNsb3VkLndl
YnJpc2sudjFiZXRhMS5TZWFyY2hIYXNoZXNSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLndlYnJp
c2sudjFiZXRhMS5TZWFyY2hIYXNoZXNSZXNwb25zZSI5gtPkkwIYEhYvdjFiZXRhMS9oYXNo
ZXM6c2VhcmNo2kEYaGFzaF9wcmVmaXgsdGhyZWF0X3R5cGVzGkrKQRZ3ZWJyaXNrLmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybULPAQoaY29tLmdvb2dsZS53ZWJyaXNrLnYxYmV0YTFCDFdlYlJpc2tQcm90b1ABWjpj
bG91ZC5nb29nbGUuY29tL2dvL3dlYnJpc2svYXBpdjFiZXRhMS93ZWJyaXNrcGI7d2Vicmlz
a3BiogIER0NXUqoCHEdvb2dsZS5DbG91ZC5XZWJSaXNrLlYxQmV0YTHKAhxHb29nbGVcQ2xv
dWRcV2ViUmlza1xWMWJldGEx6gIfR29vZ2xlOjpDbG91ZDo6V2ViUmlzazo6VjFiZXRhMUqw
VgoHEgUPAK4CAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCgoICgECEgMR
ACUKCQoCAwASAxMAJgoJCgIDARIDFAAhCgkKAgMCEgMVACkKCQoCAwMSAxYAKQoICgEIEgMY
ADkKCQoCCCUSAxgAOQoICgEIEgMZAFEKCQoCCAsSAxkAUQoICgEIEgMaACIKCQoCCAoSAxoA
IgoICgEIEgMbAC0KCQoCCAgSAxsALQoICgEIEgMcADMKCQoCCAESAxwAMwoICgEIEgMdACIK
CQoCCCQSAx0AIgoICgEIEgMeADkKCQoCCCkSAx4AOQoICgEIEgMfADgKCQoCCC0SAx8AOAp9
CgIGABIEIwBCARpxIFdlYiBSaXNrIHYxYmV0YTEgQVBJIGRlZmluZXMgYW4gaW50ZXJmYWNl
IHRvIGRldGVjdCBtYWxpY2lvdXMgVVJMcyBvbiB5b3VyCiB3ZWJzaXRlIGFuZCBpbiBjbGll
bnQgYXBwbGljYXRpb25zLgoKCgoDBgABEgMjCB0KCgoDBgADEgMkAj4KDAoFBgADmQgSAyQC
PgoKCgMGAAMSAyUCVgoMCgUGAAOaCBIDJQJWCjcKBAYAAgASBCgCLQMaKSBHZXRzIHRoZSBt
b3N0IHJlY2VudCB0aHJlYXQgbGlzdCBkaWZmcy4KCgwKBQYAAgABEgMoBhsKDAoFBgACAAIS
AygcOAoMCgUGAAIAAxIDKENgCg0KBQYAAgAEEgQpBCsGChEKCQYAAgAEsMq8IhIEKQQrBgoM
CgUGAAIABBIDLARTCg8KCAYAAgAEmwgAEgMsBFMKVAoEBgACARIEMAI1AxpGIFRoaXMgbWV0
aG9kIGlzIHVzZWQgdG8gY2hlY2sgd2hldGhlciBhIFVSSSBpcyBvbiBhIGdpdmVuIHRocmVh
dExpc3QuCgoMCgUGAAIBARIDMAYQCgwKBQYAAgECEgMwESIKDAoFBgACAQMSAzAtPwoNCgUG
AAIBBBIEMQQzBgoRCgkGAAIBBLDKvCISBDEEMwYKDAoFBgACAQQSAzQEPgoPCggGAAIBBJsI
ABIDNAQ+CrUCCgQGAAICEgQ8AkEDGqYCIEdldHMgdGhlIGZ1bGwgaGFzaGVzIHRoYXQgbWF0
Y2ggdGhlIHJlcXVlc3RlZCBoYXNoIHByZWZpeC4KIFRoaXMgaXMgdXNlZCBhZnRlciBhIGhh
c2ggcHJlZml4IGlzIGxvb2tlZCB1cCBpbiBhIHRocmVhdExpc3QKIGFuZCB0aGVyZSBpcyBh
IG1hdGNoLiBUaGUgY2xpZW50IHNpZGUgdGhyZWF0TGlzdCBvbmx5IGhvbGRzIHBhcnRpYWwg
aGFzaGVzCiBzbyB0aGUgY2xpZW50IG11c3QgcXVlcnkgdGhpcyBtZXRob2QgdG8gZGV0ZXJt
aW5lIGlmIHRoZXJlIGlzIGEgZnVsbAogaGFzaCBtYXRjaCBvZiBhIHRocmVhdC4KCgwKBQYA
AgIBEgM8BhIKDAoFBgACAgISAzwTJgoMCgUGAAICAxIDPDFFCg0KBQYAAgIEEgQ9BD8GChEK
CQYAAgIEsMq8IhIEPQQ/BgoMCgUGAAICBBIDQARGCg8KCAYAAgIEmwgAEgNABEYKLAoCBAAS
BEUAXwEaICBEZXNjcmliZXMgYW4gQVBJIGRpZmYgcmVxdWVzdC4KCgoKAwQAARIDRQgkCi4K
BAQAAwASBEcCVAMaICBUaGUgY29uc3RyYWludHMgZm9yIHRoaXMgZGlmZi4KCgwKBQQAAwAB
EgNHChUKzQEKBgQAAwACABIDSwQfGr0BIFRoZSBtYXhpbXVtIHNpemUgaW4gbnVtYmVyIG9m
IGVudHJpZXMuIFRoZSBkaWZmIHdpbGwgbm90IGNvbnRhaW4gbW9yZQogZW50cmllcyB0aGFu
IHRoaXMgdmFsdWUuICBUaGlzIHNob3VsZCBiZSBhIHBvd2VyIG9mIDIgYmV0d2VlbiAyKiox
MCBhbmQKIDIqKjIwLiAgSWYgemVybywgbm8gZGlmZiBzaXplIGxpbWl0IGlzIHNldC4KCg4K
BwQAAwACAAUSA0sECQoOCgcEAAMAAgABEgNLChoKDgoHBAADAAIAAxIDSx0eCs0BCgYEAAMA
AgESA1AEIxq9ASBTZXRzIHRoZSBtYXhpbXVtIG51bWJlciBvZiBlbnRyaWVzIHRoYXQgdGhl
IGNsaWVudCBpcyB3aWxsaW5nIHRvIGhhdmUKIGluIHRoZSBsb2NhbCBkYXRhYmFzZS4gVGhp
cyBzaG91bGQgYmUgYSBwb3dlciBvZiAyIGJldHdlZW4gMioqMTAgYW5kCiAyKioyMC4gSWYg
emVybywgbm8gZGF0YWJhc2Ugc2l6ZSBsaW1pdCBpcyBzZXQuCgoOCgcEAAMAAgEFEgNQBAkK
DgoHBAADAAIBARIDUAoeCg4KBwQAAwACAQMSA1AhIgo/CgYEAAMAAgISA1MEOBowIFRoZSBj
b21wcmVzc2lvbiB0eXBlcyBzdXBwb3J0ZWQgYnkgdGhlIGNsaWVudC4KCg4KBwQAAwACAgQS
A1MEDAoOCgcEAAMAAgIGEgNTDRwKDgoHBAADAAICARIDUx0zCg4KBwQAAwACAgMSA1M2Nwoo
CgQEAAIAEgNXAkYaGyBUaGUgVGhyZWF0TGlzdCB0byB1cGRhdGUuCgoMCgUEAAIABhIDVwIM
CgwKBQQAAgABEgNXDRgKDAoFBAACAAMSA1cbHAoMCgUEAAIACBIDVx1FCg8KCAQAAgAInAgA
EgNXHkQKlQEKBAQAAgESA1sCGhqHASBUaGUgY3VycmVudCB2ZXJzaW9uIHRva2VuIG9mIHRo
ZSBjbGllbnQgZm9yIHRoZSByZXF1ZXN0ZWQgbGlzdCAodGhlCiBjbGllbnQgdmVyc2lvbiB0
aGF0IHdhcyByZWNlaXZlZCBmcm9tIHRoZSBsYXN0IHN1Y2Nlc3NmdWwgZGlmZikuCgoMCgUE
AAIBBRIDWwIHCgwKBQQAAgEBEgNbCBUKDAoFBAACAQMSA1sYGQpGCgQEAAICEgNeAkcaOSBS
ZXF1aXJlZC4gVGhlIGNvbnN0cmFpbnRzIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHJlcXVlc3Qu
CgoMCgUEAAICBhIDXgINCgwKBQQAAgIBEgNeDhkKDAoFBAACAgMSA14cHQoMCgUEAAICCBID
Xh5GCg8KCAQAAgIInAgAEgNeH0UKCwoCBAESBWEAkAEBCgoKAwQBARIDYQglCkAKBAQBAwAS
BGMCZwMaMiBUaGUgZXhwZWN0ZWQgc3RhdGUgb2YgYSBjbGllbnQncyBsb2NhbCBkYXRhYmFz
ZS4KCgwKBQQBAwABEgNjChIKeQoGBAEDAAIAEgNmBBUaaiBUaGUgU0hBMjU2IGhhc2ggb2Yg
dGhlIGNsaWVudCBzdGF0ZTsgdGhhdCBpcywgb2YgdGhlIHNvcnRlZCBsaXN0IG9mIGFsbAog
aGFzaGVzIHByZXNlbnQgaW4gdGhlIGRhdGFiYXNlLgoKDgoHBAEDAAIABRIDZgQJCg4KBwQB
AwACAAESA2YKEAoOCgcEAQMAAgADEgNmExQKOAoEBAEEABIEagJ1AxoqIFRoZSB0eXBlIG9m
IHJlc3BvbnNlIHNlbnQgdG8gdGhlIGNsaWVudC4KCgwKBQQBBAABEgNqBxMKGQoGBAEEAAIA
EgNsBCIaCiBVbmtub3duLgoKDgoHBAEEAAIAARIDbAQdCg4KBwQBBAACAAISA2wgIQpVCgYE
AQQAAgESA28EDRpGIFBhcnRpYWwgdXBkYXRlcyBhcmUgYXBwbGllZCB0byB0aGUgY2xpZW50
J3MgZXhpc3RpbmcgbG9jYWwgZGF0YWJhc2UuCgoOCgcEAQQAAgEBEgNvBAgKDgoHBAEEAAIB
AhIDbwsMCr8BCgYEAQQAAgISA3QEDhqvASBGdWxsIHVwZGF0ZXMgcmVzZXRzIHRoZSBjbGll
bnQncyBlbnRpcmUgbG9jYWwgZGF0YWJhc2UuIFRoaXMgbWVhbnMKIHRoYXQgZWl0aGVyIHRo
ZSBjbGllbnQgaGFkIG5vIHN0YXRlLCB3YXMgc2VyaW91c2x5IG91dC1vZi1kYXRlLAogb3Ig
dGhlIGNsaWVudCBpcyBiZWxpZXZlZCB0byBiZSBjb3JydXB0LgoKDgoHBAEEAAICARIDdAQJ
Cg4KBwQBBAACAgISA3QMDQqBAQoEBAECABIDeQIhGnQgVGhlIHR5cGUgb2YgcmVzcG9uc2Uu
IFRoaXMgbWF5IGluZGljYXRlIHRoYXQgYW4gYWN0aW9uIG11c3QgYmUgdGFrZW4gYnkgdGhl
CiBjbGllbnQgd2hlbiB0aGUgcmVzcG9uc2UgaXMgcmVjZWl2ZWQuCgoMCgUEAQIABhIDeQIO
CgwKBQQBAgABEgN5DxwKDAoFBAECAAMSA3kfIApFCgQEAQIBEgN8AiUaOCBBIHNldCBvZiBl
bnRyaWVzIHRvIGFkZCB0byBhIGxvY2FsIHRocmVhdCB0eXBlJ3MgbGlzdC4KCgwKBQQBAgEG
EgN8AhYKDAoFBAECAQESA3wXIAoMCgUEAQIBAxIDfCMkCmUKBAQBAgISBIABAiMaVyBBIHNl
dCBvZiBlbnRyaWVzIHRvIHJlbW92ZSBmcm9tIGEgbG9jYWwgdGhyZWF0IHR5cGUncyBsaXN0
LgogVGhpcyBmaWVsZCBtYXkgYmUgZW1wdHkuCgoNCgUEAQICBhIEgAECFQoNCgUEAQICARIE
gAEWHgoNCgUEAQICAxIEgAEhIgo0CgQEAQIDEgSDAQIeGiYgVGhlIG5ldyBvcGFxdWUgY2xp
ZW50IHZlcnNpb24gdG9rZW4uCgoNCgUEAQIDBRIEgwECBwoNCgUEAQIDARIEgwEIGQoNCgUE
AQIDAxIEgwEcHQqQAgoEBAECBBIEiQECGBqBAiBUaGUgZXhwZWN0ZWQgU0hBMjU2IGhhc2gg
b2YgdGhlIGNsaWVudCBzdGF0ZTsgdGhhdCBpcywgb2YgdGhlIHNvcnRlZCBsaXN0CiBvZiBh
bGwgaGFzaGVzIHByZXNlbnQgaW4gdGhlIGRhdGFiYXNlIGFmdGVyIGFwcGx5aW5nIHRoZSBw
cm92aWRlZCBkaWZmLgogSWYgdGhlIGNsaWVudCBzdGF0ZSBkb2Vzbid0IG1hdGNoIHRoZSBl
eHBlY3RlZCBzdGF0ZSwgdGhlIGNsaWVudCBtdXN0CiBkaXNyZWdhcmQgdGhpcyBkaWZmIGFu
ZCByZXRyeSBsYXRlci4KCg0KBQQBAgQGEgSJAQIKCg0KBQQBAgQBEgSJAQsTCg0KBQQBAgQD
EgSJARYXCooCCgQEAQIFEgSPAQI2GvsBIFRoZSBzb29uZXN0IHRoZSBjbGllbnQgc2hvdWxk
IHdhaXQgYmVmb3JlIGlzc3VpbmcgYW55IGRpZmYKIHJlcXVlc3QuIFF1ZXJ5aW5nIHNvb25l
ciBpcyB1bmxpa2VseSB0byBwcm9kdWNlIGEgbWVhbmluZ2Z1bCBkaWZmLgogV2FpdGluZyBs
b25nZXIgaXMgYWNjZXB0YWJsZSBjb25zaWRlcmluZyB0aGUgdXNlIGNhc2UuCiBJZiB0aGlz
IGZpZWxkIGlzIG5vdCBzZXQgY2xpZW50cyBtYXkgdXBkYXRlIGFzIHNvb24gYXMgdGhleSB3
YW50LgoKDQoFBAECBQYSBI8BAhsKDQoFBAECBQESBI8BHDEKDQoFBAECBQMSBI8BNDUKQQoC
BAISBpMBAJkBARozIFJlcXVlc3QgdG8gY2hlY2sgVVJJIGVudHJpZXMgYWdhaW5zdCB0aHJl
YXRMaXN0cy4KCgsKAwQCARIEkwEIGQo8CgQEAgIAEgSVAQI6Gi4gUmVxdWlyZWQuIFRoZSBV
UkkgdG8gYmUgY2hlY2tlZCBmb3IgbWF0Y2hlcy4KCg0KBQQCAgAFEgSVAQIICg0KBQQCAgAB
EgSVAQkMCg0KBQQCAgADEgSVAQ8QCg0KBQQCAgAIEgSVARE5ChAKCAQCAgAInAgAEgSVARI4
CjcKBAQCAgESBJgBAlAaKSBSZXF1aXJlZC4gVGhlIFRocmVhdExpc3RzIHRvIHNlYXJjaCBp
bi4KCg0KBQQCAgEEEgSYAQIKCg0KBQQCAgEGEgSYAQsVCg0KBQQCAgEBEgSYARYiCg0KBQQC
AgEDEgSYASUmCg0KBQQCAgEIEgSYASdPChAKCAQCAgEInAgAEgSYAShOCgwKAgQDEgabAQCo
AQEKCwoDBAMBEgSbAQgaCkAKBAQDAwASBp0BAqQBAxowIENvbnRhaW5zIHRocmVhdCBpbmZv
cm1hdGlvbiBvbiBhIG1hdGNoaW5nIHVyaS4KCg0KBQQDAwABEgSdAQoTCjgKBgQDAwACABIE
nwEEKRooIFRoZSBUaHJlYXRMaXN0IHRoaXMgdGhyZWF0IGJlbG9uZ3MgdG8uCgoPCgcEAwMA
AgAEEgSfAQQMCg8KBwQDAwACAAYSBJ8BDRcKDwoHBAMDAAIAARIEnwEYJAoPCgcEAwMAAgAD
EgSfAScoCpEBCgYEAwMAAgESBKMBBC4agAEgVGhlIGNhY2hlIGxpZmV0aW1lIGZvciB0aGUg
cmV0dXJuZWQgbWF0Y2guIENsaWVudHMgbXVzdCBub3QgY2FjaGUgdGhpcwogcmVzcG9uc2Ug
cGFzdCB0aGlzIHRpbWVzdGFtcCB0byBhdm9pZCBmYWxzZSBwb3NpdGl2ZXMuCgoPCgcEAwMA
AgEGEgSjAQQdCg8KBwQDAwACAQESBKMBHikKDwoHBAMDAAIBAxIEowEsLQpUCgQEAwIAEgSn
AQIXGkYgVGhlIHRocmVhdCBsaXN0IG1hdGNoZXMuIFRoaXMgbWF5IGJlIGVtcHR5IGlmIHRo
ZSBVUkkgaXMgb24gbm8gbGlzdC4KCg0KBQQDAgAGEgSnAQILCg0KBQQDAgABEgSnAQwSCg0K
BQQDAgADEgSnARUWClQKAgQEEgarAQCyAQEaRiBSZXF1ZXN0IHRvIHJldHVybiBmdWxsIGhh
c2hlcyBtYXRjaGVkIGJ5IHRoZSBwcm92aWRlZCBoYXNoIHByZWZpeGVzLgoKCwoDBAQBEgSr
AQgbCpEBCgQEBAIAEgSuAQIYGoIBIEEgaGFzaCBwcmVmaXgsIGNvbnNpc3Rpbmcgb2YgdGhl
IG1vc3Qgc2lnbmlmaWNhbnQgNC0zMiBieXRlcyBvZiBhIFNIQTI1NgogaGFzaC4gRm9yIEpT
T04gcmVxdWVzdHMsIHRoaXMgZmllbGQgaXMgYmFzZTY0LWVuY29kZWQuCgoNCgUEBAIABRIE
rgECBwoNCgUEBAIAARIErgEIEwoNCgUEBAIAAxIErgEWFwo3CgQEBAIBEgSxAQJQGikgUmVx
dWlyZWQuIFRoZSBUaHJlYXRMaXN0cyB0byBzZWFyY2ggaW4uCgoNCgUEBAIBBBIEsQECCgoN
CgUEBAIBBhIEsQELFQoNCgUEBAIBARIEsQEWIgoNCgUEBAIBAxIEsQElJgoNCgUEBAIBCBIE
sQEnTwoQCggEBAIBCJwIABIEsQEoTgoMCgIEBRIGtAEAywEBCgsKAwQFARIEtAEIHApBCgQE
BQMAEga2AQLCAQMaMSBDb250YWlucyB0aHJlYXQgaW5mb3JtYXRpb24gb24gYSBtYXRjaGlu
ZyBoYXNoLgoKDQoFBAUDAAESBLYBChQKXwoGBAUDAAIAEgS5AQQpGk8gVGhlIFRocmVhdExp
c3QgdGhpcyB0aHJlYXQgYmVsb25ncyB0by4KIFRoaXMgbXVzdCBjb250YWluIGF0IGxlYXN0
IG9uZSBlbnRyeS4KCg8KBwQFAwACAAQSBLkBBAwKDwoHBAUDAAIABhIEuQENFwoPCgcEBQMA
AgABEgS5ARgkCg8KBwQFAwACAAMSBLkBJygKdwoGBAUDAAIBEgS9AQQTGmcgQSAzMiBieXRl
IFNIQTI1NiBoYXNoLiBUaGlzIGZpZWxkIGlzIGluIGJpbmFyeSBmb3JtYXQuIEZvciBKU09O
CiByZXF1ZXN0cywgaGFzaGVzIGFyZSBiYXNlNjQtZW5jb2RlZC4KCg8KBwQFAwACAQUSBL0B
BAkKDwoHBAUDAAIBARIEvQEKDgoPCgcEBQMAAgEDEgS9ARESCpEBCgYEBQMAAgISBMEBBC4a
gAEgVGhlIGNhY2hlIGxpZmV0aW1lIGZvciB0aGUgcmV0dXJuZWQgbWF0Y2guIENsaWVudHMg
bXVzdCBub3QgY2FjaGUgdGhpcwogcmVzcG9uc2UgcGFzdCB0aGlzIHRpbWVzdGFtcCB0byBh
dm9pZCBmYWxzZSBwb3NpdGl2ZXMuCgoPCgcEBQMAAgIGEgTBAQQdCg8KBwQFAwACAgESBMEB
HikKDwoHBAUDAAICAxIEwQEsLQpsCgQEBQIAEgTGAQIiGl4gVGhlIGZ1bGwgaGFzaGVzIHRo
YXQgbWF0Y2hlZCB0aGUgcmVxdWVzdGVkIHByZWZpeGVzLgogVGhlIGhhc2ggd2lsbCBiZSBw
b3B1bGF0ZWQgaW4gdGhlIGtleS4KCg0KBQQFAgAEEgTGAQIKCg0KBQQFAgAGEgTGAQsVCg0K
BQQFAgABEgTGARYdCg0KBQQFAgADEgTGASAhCnEKBAQFAgESBMoBAjUaYyBGb3IgcmVxdWVz
dGVkIGVudGl0aWVzIHRoYXQgZGlkIG5vdCBtYXRjaCB0aGUgdGhyZWF0IGxpc3QsIGhvdyBs
b25nIHRvCiBjYWNoZSB0aGUgcmVzcG9uc2UgdW50aWwuCgoNCgUEBQIBBhIEygECGwoNCgUE
BQIBARIEygEcMAoNCgUEBQIBAxIEygEzNAqUAQoCBAYSBs8BANgBARqFASBDb250YWlucyB0
aGUgc2V0IG9mIGVudHJpZXMgdG8gYWRkIHRvIGEgbG9jYWwgZGF0YWJhc2UuCiBNYXkgY29u
dGFpbiBhIGNvbWJpbmF0aW9uIG9mIGNvbXByZXNzZWQgYW5kIHJhdyBkYXRhIGluIGEgc2lu
Z2xlIHJlc3BvbnNlLgoKCwoDBAYBEgTPAQgcCnoKBAQGAgASBNIBAiQabCBUaGUgcmF3IFNI
QTI1Ni1mb3JtYXR0ZWQgZW50cmllcy4KIFJlcGVhdGVkIHRvIGFsbG93IHJldHVybmluZyBz
ZXRzIG9mIGhhc2hlcyB3aXRoIGRpZmZlcmVudCBwcmVmaXggc2l6ZXMuCgoNCgUEBgIABBIE
0gECCgoNCgUEBgIABhIE0gELFAoNCgUEBgIAARIE0gEVHwoNCgUEBgIAAxIE0gEiIwrXAQoE
BAYCARIE1wECJBrIASBUaGUgZW5jb2RlZCA0LWJ5dGUgcHJlZml4ZXMgb2YgU0hBMjU2LWZv
cm1hdHRlZCBlbnRyaWVzLCB1c2luZyBhCiBHb2xvbWItUmljZSBlbmNvZGluZy4gVGhlIGhh
c2hlcyBhcmUgY29udmVydGVkIHRvIHVpbnQzMiwgc29ydGVkIGluCiBhc2NlbmRpbmcgb3Jk
ZXIsIHRoZW4gZGVsdGEgZW5jb2RlZCBhbmQgc3RvcmVkIGFzIGVuY29kZWRfZGF0YS4KCg0K
BQQGAgEGEgTXAQITCg0KBQQGAgEBEgTXARQfCg0KBQQGAgEDEgTXASIjCkwKAgQHEgbbAQDk
AQEaPiBDb250YWlucyB0aGUgc2V0IG9mIGVudHJpZXMgdG8gcmVtb3ZlIGZyb20gYSBsb2Nh
bCBkYXRhYmFzZS4KCgsKAwQHARIE2wEIGwo5CgQEBwIAEgTdAQIdGisgVGhlIHJhdyByZW1v
dmFsIGluZGljZXMgZm9yIGEgbG9jYWwgbGlzdC4KCg0KBQQHAgAGEgTdAQIMCg0KBQQHAgAB
EgTdAQ0YCg0KBQQHAgADEgTdARscCoMCCgQEBwIBEgTjAQIlGvQBIFRoZSBlbmNvZGVkIGxv
Y2FsLCBsZXhpY29ncmFwaGljYWxseS1zb3J0ZWQgbGlzdCBpbmRpY2VzLCB1c2luZyBhCiBH
b2xvbWItUmljZSBlbmNvZGluZy4gVXNlZCBmb3Igc2VuZGluZyBjb21wcmVzc2VkIHJlbW92
YWwgaW5kaWNlcy4gVGhlCiByZW1vdmFsIGluZGljZXMgKHVpbnQzMikgYXJlIHNvcnRlZCBp
biBhc2NlbmRpbmcgb3JkZXIsIHRoZW4gZGVsdGEgZW5jb2RlZAogYW5kIHN0b3JlZCBhcyBl
bmNvZGVkX2RhdGEuCgoNCgUEBwIBBhIE4wECEwoNCgUEBwIBARIE4wEUIAoNCgUEBwIBAxIE
4wEjJApjCgIFABIG6AEA9AEBGlUgVGhlIHR5cGUgb2YgdGhyZWF0LiBUaGlzIG1hcHMgZGly
cmVjdGx5IHRvIHRoZSB0aHJlYXQgbGlzdCBhIHRocmVhdCBtYXkKIGJlbG9uZyB0by4KCgsK
AwUAARIE6AEFDwoYCgQFAAIAEgTqAQIeGgogVW5rbm93bi4KCg0KBQUAAgABEgTqAQIZCg0K
BQUAAgACEgTqARwdCi8KBAUAAgESBO0BAg4aISBNYWx3YXJlIHRhcmdldGluZyBhbnkgcGxh
dGZvcm0uCgoNCgUFAAIBARIE7QECCQoNCgUFAAIBAhIE7QEMDQo6CgQFAAICEgTwAQIZGiwg
U29jaWFsIGVuZ2luZWVyaW5nIHRhcmdldGluZyBhbnkgcGxhdGZvcm0uCgoNCgUFAAICARIE
8AECFAoNCgUFAAICAhIE8AEXGAo5CgQFAAIDEgTzAQIYGisgVW53YW50ZWQgc29mdHdhcmUg
dGFyZ2V0aW5nIGFueSBwbGF0Zm9ybS4KCg0KBQUAAgMBEgTzAQITCg0KBQUAAgMCEgTzARYX
CkYKAgUBEgb3AQCAAgEaOCBUaGUgd2F5cyBpbiB3aGljaCB0aHJlYXQgZW50cnkgc2V0cyBj
YW4gYmUgY29tcHJlc3NlZC4KCgsKAwUBARIE9wEFFAoYCgQFAQIAEgT5AQIjGgogVW5rbm93
bi4KCg0KBQUBAgABEgT5AQIeCg0KBQUBAgACEgT5ASEiCicKBAUBAgESBPwBAgoaGSBSYXcs
IHVuY29tcHJlc3NlZCBkYXRhLgoKDQoFBQECAQESBPwBAgUKDQoFBQECAQISBPwBCAkKKQoE
BQECAhIE/wECCxobIFJpY2UtR29sb21iIGVuY29kZWQgZGF0YS4KCg0KBQUBAgIBEgT/AQIG
Cg0KBQUBAgICEgT/AQkKCkEKAgQIEgaDAgCGAgEaMyBBIHNldCBvZiByYXcgaW5kaWNlcyB0
byByZW1vdmUgZnJvbSBhIGxvY2FsIGxpc3QuCgoLCgMECAESBIMCCBIKUQoEBAgCABIEhQIC
HRpDIFRoZSBpbmRpY2VzIHRvIHJlbW92ZSBmcm9tIGEgbGV4aWNvZ3JhcGhpY2FsbHktc29y
dGVkIGxvY2FsIGxpc3QuCgoNCgUECAIABBIEhQICCgoNCgUECAIABRIEhQILEAoNCgUECAIA
ARIEhQIRGAoNCgUECAIAAxIEhQIbHAqCAwoCBAkSBpACAJkCARrzAiBUaGUgdW5jb21wcmVz
c2VkIHRocmVhdCBlbnRyaWVzIGluIGhhc2ggZm9ybWF0LgogSGFzaGVzIGNhbiBiZSBhbnl3
aGVyZSBmcm9tIDQgdG8gMzIgYnl0ZXMgaW4gc2l6ZS4gQSBsYXJnZSBtYWpvcml0eSBhcmUg
NAogYnl0ZXMsIGJ1dCBzb21lIGhhc2hlcyBhcmUgbGVuZ3RoZW5lZCBpZiB0aGV5IGNvbGxp
ZGUgd2l0aCB0aGUgaGFzaCBvZiBhCiBwb3B1bGFyIFVSSS4KCiBVc2VkIGZvciBzZW5kaW5n
IFRocmVhdEVudHJ5QWRkaXRvbnMgdG8gY2xpZW50cyB0aGF0IGRvIG5vdCBzdXBwb3J0CiBj
b21wcmVzc2lvbiwgb3Igd2hlbiBzZW5kaW5nIG5vbi00LWJ5dGUgaGFzaGVzIHRvIGNsaWVu
dHMgdGhhdCBkbyBzdXBwb3J0CiBjb21wcmVzc2lvbi4KCgsKAwQJARIEkAIIEQqTAQoEBAkC
ABIEkwICGBqEASBUaGUgbnVtYmVyIG9mIGJ5dGVzIGZvciBlYWNoIHByZWZpeCBlbmNvZGVk
IGJlbG93LiAgVGhpcyBmaWVsZCBjYW4gYmUKIGFueXdoZXJlIGZyb20gNCAoc2hvcnRlc3Qg
cHJlZml4KSB0byAzMiAoZnVsbCBTSEEyNTYgaGFzaCkuCgoNCgUECQIABRIEkwICBwoNCgUE
CQIAARIEkwIIEwoNCgUECQIAAxIEkwIWFwqsAQoEBAkCARIEmAICFxqdASBUaGUgaGFzaGVz
LCBpbiBiaW5hcnkgZm9ybWF0LCBjb25jYXRlbmF0ZWQgaW50byBvbmUgbG9uZyBzdHJpbmcu
IEhhc2hlcyBhcmUKIHNvcnRlZCBpbiBsZXhpY29ncmFwaGljIG9yZGVyLiBGb3IgSlNPTiBB
UEkgdXNlcnMsIGhhc2hlcyBhcmUKIGJhc2U2NC1lbmNvZGVkLgoKDQoFBAkCAQUSBJgCAgcK
DQoFBAkCAQESBJgCCBIKDQoFBAkCAQMSBJgCFRYKdwoCBAoSBp0CAK4CARppIFRoZSBSaWNl
LUdvbG9tYiBlbmNvZGVkIGRhdGEuIFVzZWQgZm9yIHNlbmRpbmcgY29tcHJlc3NlZCA0LWJ5
dGUgaGFzaGVzIG9yCiBjb21wcmVzc2VkIHJlbW92YWwgaW5kaWNlcy4KCgsKAwQKARIEnQII
GQq7AQoEBAoCABIEoQICGBqsASBUaGUgb2Zmc2V0IG9mIHRoZSBmaXJzdCBlbnRyeSBpbiB0
aGUgZW5jb2RlZCBkYXRhLCBvciwgaWYgb25seSBhIHNpbmdsZQogaW50ZWdlciB3YXMgZW5j
b2RlZCwgdGhhdCBzaW5nbGUgaW50ZWdlcidzIHZhbHVlLiBJZiB0aGUgZmllbGQgaXMgZW1w
dHkgb3IKIG1pc3NpbmcsIGFzc3VtZSB6ZXJvLgoKDQoFBAoCAAUSBKECAgcKDQoFBAoCAAES
BKECCBMKDQoFBAoCAAMSBKECFhcKkAEKBAQKAgESBKUCAhsagQEgVGhlIEdvbG9tYi1SaWNl
IHBhcmFtZXRlciwgd2hpY2ggaXMgYSBudW1iZXIgYmV0d2VlbiAyIGFuZCAyOC4gVGhpcyBm
aWVsZAogaXMgbWlzc2luZyAodGhhdCBpcywgemVybykgaWYgYG51bV9lbnRyaWVzYCBpcyB6
ZXJvLgoKDQoFBAoCAQUSBKUCAgcKDQoFBAoCAQESBKUCCBYKDQoFBAoCAQMSBKUCGRoKwgEK
BAQKAgISBKoCAhgaswEgVGhlIG51bWJlciBvZiBlbnRyaWVzIHRoYXQgYXJlIGRlbHRhIGVu
Y29kZWQgaW4gdGhlIGVuY29kZWQgZGF0YS4gSWYgb25seSBhCiBzaW5nbGUgaW50ZWdlciB3
YXMgZW5jb2RlZCwgdGhpcyB3aWxsIGJlIHplcm8gYW5kIHRoZSBzaW5nbGUgdmFsdWUgd2ls
bCBiZQogc3RvcmVkIGluIGBmaXJzdF92YWx1ZWAuCgoNCgUECgICBRIEqgICBwoNCgUECgIC
ARIEqgIIEwoNCgUECgICAxIEqgIWFwpQCgQECgIDEgStAgIZGkIgVGhlIGVuY29kZWQgZGVs
dGFzIHRoYXQgYXJlIGVuY29kZWQgdXNpbmcgdGhlIEdvbG9tYi1SaWNlIGNvZGVyLgoKDQoF
BAoCAwUSBK0CAgcKDQoFBAoCAwESBK0CCBQKDQoFBAoCAwMSBK0CFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest ===
    # Fields for ComputeThreatListDiffRequest
    # Field: threat_type Type: 14 (.google.cloud.webrisk.v1beta1.ThreatType)
    # Field: version_token Type: 12 ()
    # Field: constraints Type: 11 (.google.cloud.webrisk.v1beta1.ComputeThreatListDiffRequest.Constraints)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffResponse ===
    # Fields for ComputeThreatListDiffResponse
    # Field: response_type Type: 14 (.google.cloud.webrisk.v1beta1.ComputeThreatListDiffResponse.ResponseType)
    # Field: additions Type: 11 (.google.cloud.webrisk.v1beta1.ThreatEntryAdditions)
    # Field: removals Type: 11 (.google.cloud.webrisk.v1beta1.ThreatEntryRemovals)
    # Field: new_version_token Type: 12 ()
    # Field: checksum Type: 11 (.google.cloud.webrisk.v1beta1.ComputeThreatListDiffResponse.Checksum)
    # Field: recommended_next_diff Type: 11 (.google.protobuf.Timestamp)

# Enum: ComputeThreatListDiffResponse::ResponseType
our $ComputeThreatListDiffResponse_RESPONSE_TYPE_UNSPECIFIED = 0;
our $ComputeThreatListDiffResponse_DIFF = 1;
our $ComputeThreatListDiffResponse_RESET = 2;

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisRequest ===
    # Fields for SearchUrisRequest
    # Field: uri Type: 9 ()
    # Field: threat_types Type: 14 (.google.cloud.webrisk.v1beta1.ThreatType)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisResponse ===
    # Fields for SearchUrisResponse
    # Field: threat Type: 11 (.google.cloud.webrisk.v1beta1.SearchUrisResponse.ThreatUri)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesRequest ===
    # Fields for SearchHashesRequest
    # Field: hash_prefix Type: 12 ()
    # Field: threat_types Type: 14 (.google.cloud.webrisk.v1beta1.ThreatType)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesResponse ===
    # Fields for SearchHashesResponse
    # Field: threats Type: 11 (.google.cloud.webrisk.v1beta1.SearchHashesResponse.ThreatHash)
    # Field: negative_expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatEntryAdditions ===
    # Fields for ThreatEntryAdditions
    # Field: raw_hashes Type: 11 (.google.cloud.webrisk.v1beta1.RawHashes)
    # Field: rice_hashes Type: 11 (.google.cloud.webrisk.v1beta1.RiceDeltaEncoding)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatEntryRemovals ===
    # Fields for ThreatEntryRemovals
    # Field: raw_indices Type: 11 (.google.cloud.webrisk.v1beta1.RawIndices)
    # Field: rice_indices Type: 11 (.google.cloud.webrisk.v1beta1.RiceDeltaEncoding)

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::RawIndices ===
    # Fields for RawIndices
    # Field: indices Type: 5 ()

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::RawHashes ===
    # Fields for RawHashes
    # Field: prefix_size Type: 5 ()
    # Field: raw_hashes Type: 12 ()

# === Message: Google::Cloud::Webrisk::V1beta1::Webrisk::RiceDeltaEncoding ===
    # Fields for RiceDeltaEncoding
    # Field: first_value Type: 3 ()
    # Field: rice_parameter Type: 5 ()
    # Field: entry_count Type: 5 ()
    # Field: encoded_data Type: 12 ()

# === Service Client: Google::Cloud::Webrisk::V1beta1::Webrisk::WebRiskServiceV1Beta1Client ===
package Google::Cloud::Webrisk::V1beta1::Webrisk::WebRiskServiceV1Beta1Client;

=pod

=head2 Service Client: Google::Cloud::Webrisk::V1beta1::Webrisk::WebRiskServiceV1Beta1Client

Client stub representing the remote C<WebRiskServiceV1Beta1> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<webrisk.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'webrisk.googleapis.com:443' );

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

sub compute_threat_list_diff {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1',
        method         => 'ComputeThreatListDiff',
        request        => $req,
        response_class => 'Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffResponse',
    });
}

sub search_uris {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1',
        method         => 'SearchUris',
        request        => $req,
        response_class => 'Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisResponse',
    });
}

sub search_hashes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1',
        method         => 'SearchHashes',
        request        => $req,
        response_class => 'Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Webrisk::V1beta1::Webrisk - Compiled Protocol Buffers messages for google/cloud/webrisk/v1beta1/webrisk.proto

=head1 SYNOPSIS

    use Google::Cloud::Webrisk::V1beta1::Webrisk;

    my $msg = Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest->new({
        threat_type => $threat_type,
        version_token => $version_token,
        constraints => $constraints,
    });

    # Read or update a field
    my $val = $msg->threat_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/webrisk/v1beta1/webrisk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest

Describes an API diff request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->threat_type() >> / C<< $msg->threat_type($value) >>

Type: C<Enum> (L<Google::Cloud::Webrisk::V1beta1::ThreatType>)

The ThreatList to update.

=item * C<< $msg->version_token() >> / C<< $msg->version_token($value) >>

Type: C<Bytes>

The current version token of the client for the requested list (the
client version that was received from the last successful diff).

=item * C<< $msg->constraints() >> / C<< $msg->constraints($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest::Constraints>)

Required. The constraints associated with this request.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->response_type() >> / C<< $msg->response_type($value) >>

Type: C<Enum> (L<Google::Cloud::Webrisk::V1beta1::ComputeThreatListDiffResponse::ResponseType>)

The type of response. This may indicate that an action must be taken by the
client when the response is received.

=item * C<< $msg->additions() >> / C<< $msg->additions($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatEntryAdditions>)

A set of entries to add to a local threat type's list.

=item * C<< $msg->removals() >> / C<< $msg->removals($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatEntryRemovals>)

A set of entries to remove from a local threat type's list.
This field may be empty.

=item * C<< $msg->new_version_token() >> / C<< $msg->new_version_token($value) >>

Type: C<Bytes>

The new opaque client version token.

=item * C<< $msg->checksum() >> / C<< $msg->checksum($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffResponse::Checksum>)

The expected SHA256 hash of the client state; that is, of the sorted list
of all hashes present in the database after applying the provided diff.
If the client state doesn't match the expected state, the client must
disregard this diff and retry later.

=item * C<< $msg->recommended_next_diff() >> / C<< $msg->recommended_next_diff($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The soonest the client should wait before issuing any diff
request. Querying sooner is unlikely to produce a meaningful diff.
Waiting longer is acceptable considering the use case.
If this field is not set clients may update as soon as they want.

=back

=head3 Enum: ComputeThreatListDiffResponse::ResponseType

=over 4

=item * C<RESPONSE_TYPE_UNSPECIFIED> => C<0>

=item * C<DIFF> => C<1>

=item * C<RESET> => C<2>

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisRequest

Request to check URI entries against threatLists.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The URI to be checked for matches.

=item * C<< $msg->threat_types() >> / C<< $msg->threat_types($value) >>

Type: C<Enum> (L<Google::Cloud::Webrisk::V1beta1::ThreatType>)

Required. The ThreatLists to search in.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->threat() >> / C<< $msg->threat($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisResponse::ThreatUri>)

The threat list matches. This may be empty if the URI is on no list.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesRequest

Request to return full hashes matched by the provided hash prefixes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->hash_prefix() >> / C<< $msg->hash_prefix($value) >>

Type: C<Bytes>

A hash prefix, consisting of the most significant 4-32 bytes of a SHA256
hash. For JSON requests, this field is base64-encoded.

=item * C<< $msg->threat_types() >> / C<< $msg->threat_types($value) >>

Type: C<Enum> (L<Google::Cloud::Webrisk::V1beta1::ThreatType>)

Required. The ThreatLists to search in.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->threats() >> / C<< $msg->threats($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesResponse::ThreatHash>)

The full hashes that matched the requested prefixes.
The hash will be populated in the key.

=item * C<< $msg->negative_expire_time() >> / C<< $msg->negative_expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

For requested entities that did not match the threat list, how long to
cache the response until.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatEntryAdditions

Contains the set of entries to add to a local database.
May contain a combination of compressed and raw data in a single response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->raw_hashes() >> / C<< $msg->raw_hashes($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::RawHashes>)

The raw SHA256-formatted entries.
Repeated to allow returning sets of hashes with different prefix sizes.

=item * C<< $msg->rice_hashes() >> / C<< $msg->rice_hashes($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::RiceDeltaEncoding>)

The encoded 4-byte prefixes of SHA256-formatted entries, using a
Golomb-Rice encoding. The hashes are converted to uint32, sorted in
ascending order, then delta encoded and stored as encoded_data.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatEntryRemovals

Contains the set of entries to remove from a local database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->raw_indices() >> / C<< $msg->raw_indices($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::RawIndices>)

The raw removal indices for a local list.

=item * C<< $msg->rice_indices() >> / C<< $msg->rice_indices($value) >>

Type: C<Message> (L<Google::Cloud::Webrisk::V1beta1::Webrisk::RiceDeltaEncoding>)

The encoded local, lexicographically-sorted list indices, using a
Golomb-Rice encoding. Used for sending compressed removal indices. The
removal indices (uint32) are sorted in ascending order, then delta encoded
and stored as encoded_data.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::RawIndices

A set of raw indices to remove from a local list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->indices() >> / C<< $msg->indices($value) >>

Type: C<Int32>

The indices to remove from a lexicographically-sorted local list.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::RawHashes

The uncompressed threat entries in hash format.
Hashes can be anywhere from 4 to 32 bytes in size. A large majority are 4
bytes, but some hashes are lengthened if they collide with the hash of a
popular URI.

Used for sending ThreatEntryAdditons to clients that do not support
compression, or when sending non-4-byte hashes to clients that do support
compression.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->prefix_size() >> / C<< $msg->prefix_size($value) >>

Type: C<Int32>

The number of bytes for each prefix encoded below.  This field can be
anywhere from 4 (shortest prefix) to 32 (full SHA256 hash).

=item * C<< $msg->raw_hashes() >> / C<< $msg->raw_hashes($value) >>

Type: C<Bytes>

The hashes, in binary format, concatenated into one long string. Hashes are
sorted in lexicographic order. For JSON API users, hashes are
base64-encoded.

=back

=head2 Google::Cloud::Webrisk::V1beta1::Webrisk::RiceDeltaEncoding

The Rice-Golomb encoded data. Used for sending compressed 4-byte hashes or
compressed removal indices.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->first_value() >> / C<< $msg->first_value($value) >>

Type: C<Int64>

The offset of the first entry in the encoded data, or, if only a single
integer was encoded, that single integer's value. If the field is empty or
missing, assume zero.

=item * C<< $msg->rice_parameter() >> / C<< $msg->rice_parameter($value) >>

Type: C<Int32>

The Golomb-Rice parameter, which is a number between 2 and 28. This field
is missing (that is, zero) if `num_entries` is zero.

=item * C<< $msg->entry_count() >> / C<< $msg->entry_count($value) >>

Type: C<Int32>

The number of entries that are delta encoded in the encoded data. If only a
single integer was encoded, this will be zero and the single value will be
stored in `first_value`.

=item * C<< $msg->encoded_data() >> / C<< $msg->encoded_data($value) >>

Type: C<Bytes>

The encoded deltas that are encoded using the Golomb-Rice coder.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Webrisk::V1beta1::Webrisk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
