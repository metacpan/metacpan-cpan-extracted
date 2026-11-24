package Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvZ2tlaHViL3BvbGljeWNvbnRyb2xsZXIvdjFiZXRhL3BvbGljeWNv
bnRyb2xsZXIucHJvdG8SK2dvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52
MWJldGEiqwUKD01lbWJlcnNoaXBTdGF0ZRJ8ChBjb21wb25lbnRfc3RhdGVzGAMgAygLMlEu
Z29vZ2xlLmNsb3VkLmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5NZW1iZXJzaGlw
U3RhdGUuQ29tcG9uZW50U3RhdGVzRW50cnlSD2NvbXBvbmVudFN0YXRlcxJhCgVzdGF0ZRgE
IAEoDjJLLmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGEuTWVt
YmVyc2hpcFN0YXRlLkxpZmVjeWNsZVN0YXRlUgVzdGF0ZRJxChRwb2xpY3lfY29udGVudF9z
dGF0ZRgGIAEoCzI/Lmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJl
dGEuUG9saWN5Q29udGVudFN0YXRlUhJwb2xpY3lDb250ZW50U3RhdGUafwoUQ29tcG9uZW50
U3RhdGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSUQoFdmFsdWUYAiABKAsyOy5nb29nbGUu
Y2xvdWQuZ2tlaHViLnBvbGljeWNvbnRyb2xsZXIudjFiZXRhLk9uQ2x1c3RlclN0YXRlUgV2
YWx1ZToCOAEiwgEKDkxpZmVjeWNsZVN0YXRlEh8KG0xJRkVDWUNMRV9TVEFURV9VTlNQRUNJ
RklFRBAAEhEKDU5PVF9JTlNUQUxMRUQQARIOCgpJTlNUQUxMSU5HEAISCgoGQUNUSVZFEAMS
DAoIVVBEQVRJTkcQBBITCg9ERUNPTU1JU1NJT05JTkcQBRIRCg1DTFVTVEVSX0VSUk9SEAYS
DQoJSFVCX0VSUk9SEAcSDQoJU1VTUEVOREVEEAgSDAoIREVUQUNIRUQQCSL9AwoSUG9saWN5
Q29udGVudFN0YXRlEnEKFnRlbXBsYXRlX2xpYnJhcnlfc3RhdGUYASABKAsyOy5nb29nbGUu
Y2xvdWQuZ2tlaHViLnBvbGljeWNvbnRyb2xsZXIudjFiZXRhLk9uQ2x1c3RlclN0YXRlUhR0
ZW1wbGF0ZUxpYnJhcnlTdGF0ZRJ2Cg1idW5kbGVfc3RhdGVzGAIgAygLMlEuZ29vZ2xlLmNs
b3VkLmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5Qb2xpY3lDb250ZW50U3RhdGUu
QnVuZGxlU3RhdGVzRW50cnlSDGJ1bmRsZVN0YXRlcxJ+Ch1yZWZlcmVudGlhbF9zeW5jX2Nv
bmZpZ19zdGF0ZRgDIAEoCzI7Lmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxl
ci52MWJldGEuT25DbHVzdGVyU3RhdGVSGnJlZmVyZW50aWFsU3luY0NvbmZpZ1N0YXRlGnwK
EUJ1bmRsZVN0YXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5ElEKBXZhbHVlGAIgASgLMjsu
Z29vZ2xlLmNsb3VkLmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5PbkNsdXN0ZXJT
dGF0ZVIFdmFsdWU6AjgBIqMBCg5NZW1iZXJzaGlwU3BlYxJ3Chxwb2xpY3lfY29udHJvbGxl
cl9odWJfY29uZmlnGAEgASgLMjYuZ29vZ2xlLmNsb3VkLmdrZWh1Yi5wb2xpY3ljb250cm9s
bGVyLnYxYmV0YS5IdWJDb25maWdSGXBvbGljeUNvbnRyb2xsZXJIdWJDb25maWcSGAoHdmVy
c2lvbhgCIAEoCVIHdmVyc2lvbiKZCQoJSHViQ29uZmlnEmUKDGluc3RhbGxfc3BlYxgBIAEo
DjJCLmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGEuSHViQ29u
ZmlnLkluc3RhbGxTcGVjUgtpbnN0YWxsU3BlYxI5ChZhdWRpdF9pbnRlcnZhbF9zZWNvbmRz
GAIgASgDSABSFGF1ZGl0SW50ZXJ2YWxTZWNvbmRziAEBEjMKFWV4ZW1wdGFibGVfbmFtZXNw
YWNlcxgDIAMoCVIUZXhlbXB0YWJsZU5hbWVzcGFjZXMSOgoZcmVmZXJlbnRpYWxfcnVsZXNf
ZW5hYmxlZBgEIAEoCFIXcmVmZXJlbnRpYWxSdWxlc0VuYWJsZWQSLAoSbG9nX2Rlbmllc19l
bmFibGVkGAUgASgIUhBsb2dEZW5pZXNFbmFibGVkEikKEG11dGF0aW9uX2VuYWJsZWQYBiAB
KAhSD211dGF0aW9uRW5hYmxlZBJiCgptb25pdG9yaW5nGAggASgLMj0uZ29vZ2xlLmNsb3Vk
LmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5Nb25pdG9yaW5nQ29uZmlnSAFSCm1v
bml0b3JpbmeIAQESagoOcG9saWN5X2NvbnRlbnQYCSABKAsyPi5nb29nbGUuY2xvdWQuZ2tl
aHViLnBvbGljeWNvbnRyb2xsZXIudjFiZXRhLlBvbGljeUNvbnRlbnRTcGVjSAJSDXBvbGlj
eUNvbnRlbnSIAQESQQoaY29uc3RyYWludF92aW9sYXRpb25fbGltaXQYCiABKANIA1IYY29u
c3RyYWludFZpb2xhdGlvbkxpbWl0iAEBEnwKEmRlcGxveW1lbnRfY29uZmlncxgLIAMoCzJN
Lmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGEuSHViQ29uZmln
LkRlcGxveW1lbnRDb25maWdzRW50cnlSEWRlcGxveW1lbnRDb25maWdzGpMBChZEZXBsb3lt
ZW50Q29uZmlnc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EmMKBXZhbHVlGAIgASgLMk0uZ29v
Z2xlLmNsb3VkLmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5Qb2xpY3lDb250cm9s
bGVyRGVwbG95bWVudENvbmZpZ1IFdmFsdWU6AjgBIpwBCgtJbnN0YWxsU3BlYxIcChhJTlNU
QUxMX1NQRUNfVU5TUEVDSUZJRUQQABIeChpJTlNUQUxMX1NQRUNfTk9UX0lOU1RBTExFRBAB
EhgKFElOU1RBTExfU1BFQ19FTkFCTEVEEAISGgoWSU5TVEFMTF9TUEVDX1NVU1BFTkRFRBAD
EhkKFUlOU1RBTExfU1BFQ19ERVRBQ0hFRBAEQhkKF19hdWRpdF9pbnRlcnZhbF9zZWNvbmRz
Qg0KC19tb25pdG9yaW5nQhEKD19wb2xpY3lfY29udGVudEIdChtfY29uc3RyYWludF92aW9s
YXRpb25fbGltaXQirAYKIFBvbGljeUNvbnRyb2xsZXJEZXBsb3ltZW50Q29uZmlnEigKDXJl
cGxpY2FfY291bnQYASABKANIAFIMcmVwbGljYUNvdW50iAEBEncKE2NvbnRhaW5lcl9yZXNv
dXJjZXMYAiABKAsyQS5nb29nbGUuY2xvdWQuZ2tlaHViLnBvbGljeWNvbnRyb2xsZXIudjFi
ZXRhLlJlc291cmNlUmVxdWlyZW1lbnRzSAFSEmNvbnRhaW5lclJlc291cmNlc4gBARIzChFw
b2RfYW50aV9hZmZpbml0eRgDIAEoCEICGAFIAlIPcG9kQW50aUFmZmluaXR5iAEBEoEBCg9w
b2RfdG9sZXJhdGlvbnMYBCADKAsyWC5nb29nbGUuY2xvdWQuZ2tlaHViLnBvbGljeWNvbnRy
b2xsZXIudjFiZXRhLlBvbGljeUNvbnRyb2xsZXJEZXBsb3ltZW50Q29uZmlnLlRvbGVyYXRp
b25SDnBvZFRvbGVyYXRpb25zEnkKDHBvZF9hZmZpbml0eRgFIAEoDjJWLmdvb2dsZS5jbG91
ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGEuUG9saWN5Q29udHJvbGxlckRlcGxv
eW1lbnRDb25maWcuQWZmaW5pdHlSC3BvZEFmZmluaXR5GqYBCgpUb2xlcmF0aW9uEhUKA2tl
eRgBIAEoCUgAUgNrZXmIAQESHwoIb3BlcmF0b3IYAiABKAlIAVIIb3BlcmF0b3KIAQESGQoF
dmFsdWUYAyABKAlIAlIFdmFsdWWIAQESGwoGZWZmZWN0GAQgASgJSANSBmVmZmVjdIgBAUIG
CgRfa2V5QgsKCV9vcGVyYXRvckIICgZfdmFsdWVCCQoHX2VmZmVjdCJICghBZmZpbml0eRIY
ChRBRkZJTklUWV9VTlNQRUNJRklFRBAAEg8KC05PX0FGRklOSVRZEAESEQoNQU5USV9BRkZJ
TklUWRACQhAKDl9yZXBsaWNhX2NvdW50QhYKFF9jb250YWluZXJfcmVzb3VyY2VzQhQKEl9w
b2RfYW50aV9hZmZpbml0eSLiAQoUUmVzb3VyY2VSZXF1aXJlbWVudHMSVgoGbGltaXRzGAEg
ASgLMjkuZ29vZ2xlLmNsb3VkLmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5SZXNv
dXJjZUxpc3RIAFIGbGltaXRziAEBEloKCHJlcXVlc3RzGAIgASgLMjkuZ29vZ2xlLmNsb3Vk
LmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5SZXNvdXJjZUxpc3RIAVIIcmVxdWVz
dHOIAQFCCQoHX2xpbWl0c0ILCglfcmVxdWVzdHMiVQoMUmVzb3VyY2VMaXN0EhsKBm1lbW9y
eRgBIAEoCUgAUgZtZW1vcnmIAQESFQoDY3B1GAIgASgJSAFSA2NwdYgBAUIJCgdfbWVtb3J5
QgYKBF9jcHUi1gEKFVRlbXBsYXRlTGlicmFyeUNvbmZpZxJzCgxpbnN0YWxsYXRpb24YAiAB
KA4yTy5nb29nbGUuY2xvdWQuZ2tlaHViLnBvbGljeWNvbnRyb2xsZXIudjFiZXRhLlRlbXBs
YXRlTGlicmFyeUNvbmZpZy5JbnN0YWxsYXRpb25SDGluc3RhbGxhdGlvbiJICgxJbnN0YWxs
YXRpb24SHAoYSU5TVEFMTEFUSU9OX1VOU1BFQ0lGSUVEEAASEQoNTk9UX0lOU1RBTExFRBAB
EgcKA0FMTBACIt4BChBNb25pdG9yaW5nQ29uZmlnEmsKCGJhY2tlbmRzGAEgAygOMk8uZ29v
Z2xlLmNsb3VkLmdrZWh1Yi5wb2xpY3ljb250cm9sbGVyLnYxYmV0YS5Nb25pdG9yaW5nQ29u
ZmlnLk1vbml0b3JpbmdCYWNrZW5kUghiYWNrZW5kcyJdChFNb25pdG9yaW5nQmFja2VuZBIi
Ch5NT05JVE9SSU5HX0JBQ0tFTkRfVU5TUEVDSUZJRUQQABIOCgpQUk9NRVRIRVVTEAESFAoQ
Q0xPVURfTU9OSVRPUklORxACIo0BCg5PbkNsdXN0ZXJTdGF0ZRJhCgVzdGF0ZRgBIAEoDjJL
Lmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGEuTWVtYmVyc2hp
cFN0YXRlLkxpZmVjeWNsZVN0YXRlUgVzdGF0ZRIYCgdkZXRhaWxzGAIgASgJUgdkZXRhaWxz
IkQKEUJ1bmRsZUluc3RhbGxTcGVjEi8KE2V4ZW1wdGVkX25hbWVzcGFjZXMYAiADKAlSEmV4
ZW1wdGVkTmFtZXNwYWNlcyLlAgoRUG9saWN5Q29udGVudFNwZWMSZQoHYnVuZGxlcxgBIAMo
CzJLLmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGEuUG9saWN5
Q29udGVudFNwZWMuQnVuZGxlc0VudHJ5UgdidW5kbGVzEm0KEHRlbXBsYXRlX2xpYnJhcnkY
AiABKAsyQi5nb29nbGUuY2xvdWQuZ2tlaHViLnBvbGljeWNvbnRyb2xsZXIudjFiZXRhLlRl
bXBsYXRlTGlicmFyeUNvbmZpZ1IPdGVtcGxhdGVMaWJyYXJ5GnoKDEJ1bmRsZXNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRJUCgV2YWx1ZRgCIAEoCzI+Lmdvb2dsZS5jbG91ZC5na2VodWIu
cG9saWN5Y29udHJvbGxlci52MWJldGEuQnVuZGxlSW5zdGFsbFNwZWNSBXZhbHVlOgI4AUK1
AgovY29tLmdvb2dsZS5jbG91ZC5na2VodWIucG9saWN5Y29udHJvbGxlci52MWJldGFCFVBv
bGljeUNvbnRyb2xsZXJQcm90b1ABWltjbG91ZC5nb29nbGUuY29tL2dvL2drZWh1Yi9wb2xp
Y3ljb250cm9sbGVyL2FwaXYxYmV0YS9wb2xpY3ljb250cm9sbGVycGI7cG9saWN5Y29udHJv
bGxlcnBiqgIrR29vZ2xlLkNsb3VkLkdrZUh1Yi5Qb2xpY3lDb250cm9sbGVyLlYxQmV0YcoC
K0dvb2dsZVxDbG91ZFxHa2VIdWJcUG9saWN5Q29udHJvbGxlclxWMWJldGHqAi9Hb29nbGU6
OkNsb3VkOjpHa2VIdWI6OlBvbGljeUNvbnRyb2xsZXI6OlYxYmV0YUrGYQoHEgUOAMkCAQq8
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
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAANAoICgEIEgMSAEgK
CQoCCCUSAxIASAoICgEIEgMTAHIKCQoCCAsSAxMAcgoICgEIEgMUACIKCQoCCAoSAxQAIgoI
CgEIEgMVADYKCQoCCAgSAxUANgoICgEIEgMWAEgKCQoCCAESAxYASAoICgEIEgMXAEkKCQoC
CCkSAxcASQoICgEIEgMYAEgKCQoCCC0SAxgASApACgIEABIEGwBpARo0ICoqUG9saWN5IENv
bnRyb2xsZXIqKjogU3RhdGUgZm9yIGEgc2luZ2xlIGNsdXN0ZXIuCgoKCgMEAAESAxsIFwpB
CgQEAAQAEgQdAlsDGjMgVGhlIHNldCBvZiBzdGF0ZXMgUG9saWN5IENvbnRyb2xsZXIgY2Fu
IGV4aXN0IGluLgoKDAoFBAAEAAESAx0HFQo0CgYEAAQAAgASAx8EJBolIFRoZSBsaWZlY3lj
bGUgc3RhdGUgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMfBB8KDgoHBAAEAAIAAhID
HyIjCswBCgYEAAQAAgESAyQEFhq8ASBUaGUgUEMgZG9lcyBub3QgZXhpc3Qgb24gdGhlIGdp
dmVuIGNsdXN0ZXIsIGFuZCBubyBrOHMgcmVzb3VyY2VzIG9mIGFueQogdHlwZSB0aGF0IGFy
ZSBhc3NvY2lhdGVkIHdpdGggdGhlIFBDIHNob3VsZCBleGlzdCB0aGVyZS4gVGhlIGNsdXN0
ZXIKIGRvZXMgbm90IHBvc3Nlc3MgYSBtZW1iZXJzaGlwIHdpdGggdGhlIFBDSC4KCg4KBwQA
BAACAQESAyQEEQoOCgcEAAQAAgECEgMkFBUKxwEKBgQABAACAhIDKgQTGrcBIFRoZSBQQ0gg
cG9zc2Vzc2VzIGEgTWVtYmVyc2hpcCwgaG93ZXZlciB0aGUgUEMgaXMgbm90IGZ1bGx5IGlu
c3RhbGxlZAogb24gdGhlIGNsdXN0ZXIuCiBJbiB0aGlzIHN0YXRlIHRoZSBodWIgY2FuIGJl
IGV4cGVjdGVkIHRvIGJlIHRha2luZyBhY3Rpb25zIHRvCiBpbnN0YWxsIHRoZSBQQyBvbiB0
aGUgY2x1c3Rlci4KCg4KBwQABAACAgESAyoEDgoOCgcEAAQAAgICEgMqERIK9AIKBgQABAAC
AxIDMgQPGuQCIFRoZSBQQyBpcyBmdWxseSBpbnN0YWxsZWQgb24gdGhlIGNsdXN0ZXIgYW5k
IGluIGFuIG9wZXJhdGlvbmFsIG1vZGUuCiBJbiB0aGlzIHN0YXRlIFBDSCB3aWxsIGJlIHJl
Y29uY2lsaW5nIHN0YXRlIHdpdGggdGhlIFBDLCBhbmQKIHRoZSBQQyB3aWxsIGJlIHBlcmZv
cm1pbmcgaXQncyBvcGVyYXRpb25hbCB0YXNrcyBwZXIgdGhhdCBzb2Z0d2FyZS4KIEVudGVy
aW5nIGEgUkVBRFkgc3RhdGUgcmVxdWlyZXMgdGhhdCB0aGUgaHViIGhhcyBjb25maXJtZWQg
dGhlIFBDIGlzCiBpbnN0YWxsZWQgYW5kIGl0cyBwb2RzIGFyZSBvcGVyYXRpb25hbCB3aXRo
IHRoZSB2ZXJzaW9uIG9mCiB0aGUgUEMgdGhlIFBDSCBleHBlY3RzLgoKDgoHBAAEAAIDARID
MgQKCg4KBwQABAACAwISAzINDgqGAwoGBAAEAAIEEgM6BBEa9gIgVGhlIFBDIGlzIGZ1bGx5
IGluc3RhbGxlZCwgYnV0IGluIHRoZSBwcm9jZXNzIG9mIGNoYW5naW5nIHRoZQogY29uZmln
dXJhdGlvbiAoaW5jbHVkaW5nIGNoYW5naW5nIHRoZSB2ZXJzaW9uIG9mIFBDIGVpdGhlciB1
cCBhbmQgZG93biwKIG9yIG1vZGlmeWluZyB0aGUgbWFuaWZlc3RzIG9mIFBDKSBvZiB0aGUg
cmVzb3VyY2VzIHJ1bm5pbmcgb24gdGhlCiBjbHVzdGVyLiBUaGUgUENIIGhhcyBhIE1lbWJl
cnNoaXAsIGlzIGF3YXJlIG9mIHRoZSB2ZXJzaW9uIHRoZSBjbHVzdGVyCiBzaG91bGQgYmUg
cnVubmluZyBpbiwgYnV0IGhhcyBub3QgY29uZmlybWVkIGZvciBpdHNlbGYgdGhhdCB0aGUg
UEMgaXMKIHJ1bm5pbmcgd2l0aCB0aGF0IHZlcnNpb24uCgoOCgcEAAQAAgQBEgM6BAwKDgoH
BAAEAAIEAhIDOg8QCoYBCgYEAAQAAgUSAz8EGBp3IFRoZSBQQyBtYXkgaGF2ZSByZXNvdXJj
ZXMgb24gdGhlIGNsdXN0ZXIsCiBidXQgdGhlIFBDSCB3aXNoZXMgdG8gcmVtb3ZlIHRoZSBN
ZW1iZXJzaGlwLgogVGhlIE1lbWJlcnNoaXAgc3RpbGwgZXhpc3RzLgoKDgoHBAAEAAIFARID
PwQTCg4KBwQABAACBQISAz8WFwqOAwoGBAAEAAIGEgNIBBYa/gIgVGhlIFBDIGlzIG5vdCBv
cGVyYXRpb25hbCwgYW5kIHRoZSBQQ0ggaXMgdW5hYmxlIHRvIGFjdCB0byBtYWtlIGl0CiBv
cGVyYXRpb25hbC4KIEVudGVyaW5nIGEgQ0xVU1RFUl9FUlJPUiBzdGF0ZSBoYXBwZW5zIGF1
dG9tYXRpY2FsbHkgd2hlbiB0aGUgUENICiBkZXRlcm1pbmVzIHRoYXQgYSBQQyBpbnN0YWxs
ZWQgb24gdGhlIGNsdXN0ZXIgaXMgbm9uLW9wZXJhdGl2ZSBvcgogdGhhdCB0aGUgY2x1c3Rl
ciBkb2VzIG5vdCBtZWV0IHJlcXVpcmVtZW50cyBzZXQgZm9yIHRoZSBQQ0ggdG8KIGFkbWlu
aXN0ZXIgdGhlIGNsdXN0ZXIgYnV0IGhhcyBuZXZlcnRoZWxlc3MgYmVlbiBnaXZlbiBhbiBp
bnN0cnVjdGlvbiB0bwogZG8gc28gKHN1Y2ggYXMgJ2luc3RhbGwnKS4KCg4KBwQABAACBgES
A0gEEQoOCgcEAAQAAgYCEgNIFBUKlAMKBgQABAACBxIDUQQSGoQDIEluIHRoaXMgc3RhdGUs
IHRoZSBQQyBtYXkgc3RpbGwgYmUgb3BlcmF0aW9uYWwsCiBhbmQgb25seSB0aGUgUENIIGlz
IHVuYWJsZSB0byBhY3QuCiBUaGUgaHViIHNob3VsZCBub3QgaXNzdWUgaW5zdHJ1Y3Rpb25z
IHRvIGNoYW5nZSB0aGUgUEMgc3RhdGUsCiBvciBvdGhlcndpc2UgaW50ZXJmZXJlIHdpdGgg
dGhlIG9uLWNsdXN0ZXIgcmVzb3VyY2VzLgogRW50ZXJpbmcgYSBIVUJfRVJST1Igc3RhdGUg
aGFwcGVucyBhdXRvbWF0aWNhbGx5IHdoZW4gdGhlIFBDSCBkZXRlcm1pbmVzCiB0aGUgaHVi
IGlzIGluIGFuIHVuaGVhbHRoeSBzdGF0ZSBhbmQgaXQgd2lzaGVzIHRvICd0YWtlIGhhbmRz
IG9mZicgdG8KIGF2b2lkIGNvcnJ1cHRpbmcgdGhlIFBDIG9yIG90aGVyIGRhdGEuCgoOCgcE
AAQAAgcBEgNRBA0KDgoHBAAEAAIHAhIDURARCqgBCgYEAAQAAggSA1YEEhqYASBQb2xpY3kg
Q29udHJvbGxlciAoUEMpIGlzIGluc3RhbGxlZCBidXQgc3VzcGVuZGVkLiBUaGlzIG1lYW5z
IHRoYXQgdGhlCiBwb2xpY2llcyBhcmUgbm90IGVuZm9yY2VkLCBidXQgdmlvbGF0aW9ucyBh
cmUgc3RpbGwgcmVjb3JkZWQgKHRocm91Z2gKIGF1ZGl0KS4KCg4KBwQABAACCAESA1YEDQoO
CgcEAAQAAggCEgNWEBEKkQEKBgQABAACCRIDWgQRGoEBIFBvQ28gSHViIGlzIG5vdCB0YWtp
bmcgYW55IGFjdGlvbiB0byByZWNvbmNpbGUgY2x1c3RlciBvYmplY3RzLiAgQ2hhbmdlcwog
dG8gdGhvc2Ugb2JqZWN0cyB3aWxsIG5vdCBiZSBvdmVyd3JpdHRlbiBieSBQb0NvIEh1Yi4K
Cg4KBwQABAACCQESA1oEDAoOCgcEAAQAAgkCEgNaDxAKbQoEBAACABIDYQIzGmAgQ3VycmVu
dGx5IHRoZXNlIGluY2x1ZGUgKGFsc28gc2VydmluZyBhcyBtYXAga2V5cyk6CiAxLiAiYWRt
aXNzaW9uIgogMi4gImF1ZGl0IgogMy4gIm11dGF0aW9uIgoKDAoFBAACAAYSA2ECHQoMCgUE
AAIAARIDYR4uCgwKBQQAAgADEgNhMTIKZQoEBAACARIDZQIbGlggVGhlIG92ZXJhbGwgUG9s
aWN5IENvbnRyb2xsZXIgbGlmZWN5Y2xlIHN0YXRlIG9ic2VydmVkIGJ5IHRoZSBIdWIgRmVh
dHVyZQogY29udHJvbGxlci4KCgwKBQQAAgEGEgNlAhAKDAoFBAACAQESA2URFgoMCgUEAAIB
AxIDZRkaClAKBAQAAgISA2gCLhpDIFRoZSBvdmVyYWxsIGNvbnRlbnQgc3RhdGUgb2JzZXJ2
ZWQgYnkgdGhlIEh1YiBGZWF0dXJlIGNvbnRyb2xsZXIuCgoMCgUEAAICBhIDaAIUCgwKBQQA
AgIBEgNoFSkKDAoFBAACAgMSA2gsLQo/CgIEARIEbAB4ARozIFRoZSBzdGF0ZSBvZiB0aGUg
cG9saWN5IGNvbnRyb2xsZXIgcG9saWN5IGNvbnRlbnQKCgoKAwQBARIDbAgaCjAKBAQBAgAS
A24CLBojIFRoZSBzdGF0ZSBvZiB0aGUgdGVtcGxhdGUgbGlicmFyeQoKDAoFBAECAAYSA24C
EAoMCgUEAQIAARIDbhEnCgwKBQQBAgADEgNuKisKWwoEBAECARIDcgIwGk4gVGhlIHN0YXRl
IG9mIHRoZSBhbnkgYnVuZGxlcyBpbmNsdWRlZCBpbiB0aGUgY2hvc2VuCiB2ZXJzaW9uIG9m
IHRoZSBtYW5pZmVzdAoKDAoFBAECAQYSA3ICHQoMCgUEAQIBARIDch4rCgwKBQQBAgEDEgNy
Li8K1gEKBAQBAgISA3cCMxrIASBUaGUgc3RhdGUgb2YgdGhlIHJlZmVyZW50aWFsIGRhdGEg
c3luYyBjb25maWd1cmF0aW9uLiAgVGhpcyBjb3VsZAogcmVwcmVzZW50IHRoZSBzdGF0ZSBv
ZiBlaXRoZXIgdGhlIHN5bmNTZXQgb2JqZWN0KHMpIG9yIHRoZSBjb25maWcKIG9iamVjdCwg
ZGVwZW5kaW5nIG9uIHRoZSB2ZXJzaW9uIG9mIFBvQ28gY29uZmlndXJlZCBieSB0aGUgdXNl
ci4KCgwKBQQBAgIGEgN3AhAKDAoFBAECAgESA3cRLgoMCgUEAQICAxIDdzEyCngKAgQCEgV8
AIIBARprICoqUG9saWN5IENvbnRyb2xsZXIqKjogQ29uZmlndXJhdGlvbiBmb3IgYSBzaW5n
bGUgY2x1c3Rlci4KIEludGVuZGVkIHRvIHBhcmFsbGVsIHRoZSBQb2xpY3lDb250cm9sbGVy
IENSLgoKCgoDBAIBEgN8CBYKPwoEBAICABIDfgItGjIgUG9saWN5IENvbnRyb2xsZXIgY29u
ZmlndXJhdGlvbiBmb3IgdGhlIGNsdXN0ZXIuCgoMCgUEAgIABhIDfgILCgwKBQQCAgABEgN+
DCgKDAoFBAICAAMSA34rLAo3CgQEAgIBEgSBAQIVGikgVmVyc2lvbiBvZiBQb2xpY3kgQ29u
dHJvbGxlciBpbnN0YWxsZWQuCgoNCgUEAgIBBRIEgQECCAoNCgUEAgIBARIEgQEJEAoNCgUE
AgIBAxIEgQETFAozCgIEAxIGhQEAwgEBGiUgQ29uZmlndXJhdGlvbiBmb3IgUG9saWN5IENv
bnRyb2xsZXIKCgsKAwQDARIEhQEIEQpdCgQEAwQAEgaIAQKaAQMaTSBUaGUgc2V0IG9mIGlu
c3RhbGxhdGlvbiBzcGVjcyB0aGF0IHRoZSBIdWIgRmVhdHVyZSBjb250cm9sbGVyIG1heQog
YWN0dWF0ZS4KCg0KBQQDBAABEgSIAQcSCiIKBgQDBAACABIEigEEIRoSIFNwZWMgaXMgdW5r
bm93bi4KCg8KBwQDBAACAAESBIoBBBwKDwoHBAMEAAIAAhIEigEfIAo5CgYEAwQAAgESBI0B
BCMaKSBSZXF1ZXN0IHRvIHVuaW5zdGFsbCBQb2xpY3kgQ29udHJvbGxlci4KCg8KBwQDBAAC
AQESBI0BBB4KDwoHBAMEAAIBAhIEjQEhIgpCCgYEAwQAAgISBJABBB0aMiBSZXF1ZXN0IHRv
IGluc3RhbGwgYW5kIGVuYWJsZSBQb2xpY3kgQ29udHJvbGxlci4KCg8KBwQDBAACAgESBJAB
BBgKDwoHBAMEAAICAhIEkAEbHAqWAQoGBAMEAAIDEgSUAQQfGoUBIFJlcXVlc3QgdG8gc3Vz
cGVuZCBQb2xpY3kgQ29udHJvbGxlciBpLmUuIGl0cyB3ZWJob29rcy4gSWYgUG9saWN5CiBD
b250cm9sbGVyIGlzIG5vdCBpbnN0YWxsZWQsIGl0IHdpbGwgYmUgaW5zdGFsbGVkIGJ1dCBz
dXNwZW5kZWQuCgoPCgcEAwQAAgMBEgSUAQQaCg8KBwQDBAACAwISBJQBHR4KqQEKBgQDBAAC
BBIEmQEEHhqYASBSZXF1ZXN0IHRvIHN0b3AgYWxsIHJlY29uY2lsaWF0aW9uIGFjdGlvbnMg
YnkgUG9DbyBIdWIgY29udHJvbGxlci4KIFRoaXMgaXMgYSBicmVha2dsYXNzIG1lY2hhbmlz
bSB0byBzdG9wIFBvQ28gSHViIGZyb20gYWZmZWN0aW5nCiBjbHVzdGVyIHJlc291cmNlcy4K
Cg8KBwQDBAACBAESBJkBBBkKDwoHBAMEAAIEAhIEmQEcHQqHAgoEBAMCABIEoQECHxr4ASBU
aGUgaW5zdGFsbF9zcGVjIHJlcHJlc2VudHMgdGhlIGludGVuZGVkIHN0YXRlIHNwZWNpZmll
ZCBieSB0aGUKIGxhdGVzdCByZXF1ZXN0IHRoYXQgbXV0YXRlZCBpbnN0YWxsX3NwZWMgaW4g
dGhlIGZlYXR1cmUgc3BlYywKIG5vdCB0aGUgbGlmZWN5Y2xlIHN0YXRlIG9mIHRoZQogZmVh
dHVyZSBvYnNlcnZlZCBieSB0aGUgSHViIGZlYXR1cmUgY29udHJvbGxlcgogdGhhdCBpcyBy
ZXBvcnRlZCBpbiB0aGUgZmVhdHVyZSBzdGF0ZS4KCg0KBQQDAgAGEgShAQINCg0KBQQDAgAB
EgShAQ4aCg0KBQQDAgADEgShAR0eCpABCgQEAwIBEgSlAQIsGoEBIFNldHMgdGhlIGludGVy
dmFsIGZvciBQb2xpY3kgQ29udHJvbGxlciBBdWRpdCBTY2FucyAoaW4gc2Vjb25kcykuCiBX
aGVuIHNldCB0byAwLCB0aGlzIGRpc2FibGVzIGF1ZGl0IGZ1bmN0aW9uYWxpdHkgYWx0b2dl
dGhlci4KCg0KBQQDAgEEEgSlAQIKCg0KBQQDAgEFEgSlAQsQCg0KBQQDAgEBEgSlAREnCg0K
BQQDAgEDEgSlASorCpIBCgQEAwICEgSpAQIsGoMBIFRoZSBzZXQgb2YgbmFtZXNwYWNlcyB0
aGF0IGFyZSBleGNsdWRlZCBmcm9tIFBvbGljeSBDb250cm9sbGVyIGNoZWNrcy4KIE5hbWVz
cGFjZXMgZG8gbm90IG5lZWQgdG8gY3VycmVudGx5IGV4aXN0IG9uIHRoZSBjbHVzdGVyLgoK
DQoFBAMCAgQSBKkBAgoKDQoFBAMCAgUSBKkBCxEKDQoFBAMCAgESBKkBEicKDQoFBAMCAgMS
BKkBKisKiwEKBAQDAgMSBK0BAiUafSBFbmFibGVzIHRoZSBhYmlsaXR5IHRvIHVzZSBDb25z
dHJhaW50IFRlbXBsYXRlcyB0aGF0IHJlZmVyZW5jZSB0byBvYmplY3RzCiBvdGhlciB0aGFu
IHRoZSBvYmplY3QgY3VycmVudGx5IGJlaW5nIGV2YWx1YXRlZC4KCg0KBQQDAgMFEgStAQIG
Cg0KBQQDAgMBEgStAQcgCg0KBQQDAgMDEgStASMkCjUKBAQDAgQSBLABAh4aJyBMb2dzIGFs
bCBkZW5pZXMgYW5kIGRyeSBydW4gZmFpbHVyZXMuCgoNCgUEAwIEBRIEsAECBgoNCgUEAwIE
ARIEsAEHGQoNCgUEAwIEAxIEsAEcHQpQCgQEAwIFEgSzAQIcGkIgRW5hYmxlcyB0aGUgYWJp
bGl0eSB0byBtdXRhdGUgcmVzb3VyY2VzIHVzaW5nIFBvbGljeSBDb250cm9sbGVyLgoKDQoF
BAMCBQUSBLMBAgYKDQoFBAMCBQESBLMBBxcKDQoFBAMCBQMSBLMBGhsKRQoEBAMCBhIEtgEC
Kxo3IE1vbml0b3Jpbmcgc3BlY2lmaWVzIHRoZSBjb25maWd1cmF0aW9uIG9mIG1vbml0b3Jp
bmcuCgoNCgUEAwIGBBIEtgECCgoNCgUEAwIGBhIEtgELGwoNCgUEAwIGARIEtgEcJgoNCgUE
AwIGAxIEtgEpKgpDCgQEAwIHEgS5AQIwGjUgU3BlY2lmaWVzIHRoZSBkZXNpcmVkIHBvbGlj
eSBjb250ZW50IG9uIHRoZSBjbHVzdGVyCgoNCgUEAwIHBBIEuQECCgoNCgUEAwIHBhIEuQEL
HAoNCgUEAwIHARIEuQEdKwoNCgUEAwIHAxIEuQEuLwqUAQoEBAMCCBIEvQECMRqFASBUaGUg
bWF4aW11bSBudW1iZXIgb2YgYXVkaXQgdmlvbGF0aW9ucyB0byBiZSBzdG9yZWQgaW4gYSBj
b25zdHJhaW50LgogSWYgbm90IHNldCwgdGhlIGludGVybmFsIGRlZmF1bHQgKGN1cnJlbnRs
eSAyMCkgd2lsbCBiZSB1c2VkLgoKDQoFBAMCCAQSBL0BAgoKDQoFBAMCCAUSBL0BCxAKDQoF
BAMCCAESBL0BESsKDQoFBAMCCAMSBL0BLjAKXQoEBAMCCRIEwQECSBpPIE1hcCBvZiBkZXBs
b3ltZW50IGNvbmZpZ3MgdG8gZGVwbG95bWVudHMgKCJhZG1pc3Npb24iLCAiYXVkaXQiLAog
Im11dGF0aW9uJykuCgoNCgUEAwIJBhIEwQECLwoNCgUEAwIJARIEwQEwQgoNCgUEAwIJAxIE
wQFFRwoyCgIEBBIGxQEA8AEBGiQgRGVwbG95bWVudC1zcGVjaWZpYyBjb25maWd1cmF0aW9u
LgoKCwoDBAQBEgTFAQgoCi0KBAQEAwASBscBAtMBAxodIFRvbGVyYXRpb24gb2YgYSBub2Rl
IHRhaW50LgoKDQoFBAQDAAESBMcBChQKPwoGBAQDAAIAEgTJAQQcGi8gTWF0Y2hlcyBhIHRh
aW50IGtleSAobm90IG5lY2Vzc2FyaWx5IHVuaXF1ZSkuCgoPCgcEBAMAAgAEEgTJAQQMCg8K
BwQEAwACAAUSBMkBDRMKDwoHBAQDAAIAARIEyQEUFwoPCgcEBAMAAgADEgTJARobCisKBgQE
AwACARIEzAEEIRobIE1hdGNoZXMgYSB0YWludCBvcGVyYXRvci4KCg8KBwQEAwACAQQSBMwB
BAwKDwoHBAQDAAIBBRIEzAENEwoPCgcEBAMAAgEBEgTMARQcCg8KBwQEAwACAQMSBMwBHyAK
KAoGBAQDAAICEgTPAQQeGhggTWF0Y2hlcyBhIHRhaW50IHZhbHVlLgoKDwoHBAQDAAICBBIE
zwEEDAoPCgcEBAMAAgIFEgTPAQ0TCg8KBwQEAwACAgESBM8BFBkKDwoHBAQDAAICAxIEzwEc
HQopCgYEBAMAAgMSBNIBBB8aGSBNYXRjaGVzIGEgdGFpbnQgZWZmZWN0LgoKDwoHBAQDAAID
BBIE0gEEDAoPCgcEBAMAAgMFEgTSAQ0TCg8KBwQEAwACAwESBNIBFBoKDwoHBAQDAAIDAxIE
0gEdHgpGCgQEBAQAEgbWAQLgAQMaNiBUaGUgcG9kIGFmZmluaXR5IGNvbmZpZ3VyYXRpb24g
dXNlZCBieSBhIGRlcGxveW1lbnQuCgoNCgUEBAQAARIE1gEHDwo/CgYEBAQAAgASBNgBBB0a
LyBObyBhZmZpbml0eSBjb25maWd1cmF0aW9uIGhhcyBiZWVuIHNwZWNpZmllZC4KCg8KBwQE
BAACAAESBNgBBBgKDwoHBAQEAAIAAhIE2AEbHApOCgYEBAQAAgESBNsBBBQaPiBBZmZpbml0
eSBjb25maWd1cmF0aW9ucyB3aWxsIGJlIHJlbW92ZWQgZnJvbSB0aGUgZGVwbG95bWVudC4K
Cg8KBwQEBAACAQESBNsBBA8KDwoHBAQEAAIBAhIE2wESEwp1CgYEBAQAAgISBN8BBBYaZSBB
bnRpLWFmZmluaXR5IGNvbmZpZ3VyYXRpb24gd2lsbCBiZSBhcHBsaWVkIHRvIHRoaXMgZGVw
bG95bWVudC4KIERlZmF1bHQgZm9yIGFkbWlzc2lvbnMgZGVwbG95bWVudC4KCg8KBwQEBAAC
AgESBN8BBBEKDwoHBAQEAAICAhIE3wEUFQoiCgQEBAIAEgTjAQIjGhQgUG9kIHJlcGxpY2Eg
Y291bnQuCgoNCgUEBAIABBIE4wECCgoNCgUEBAIABRIE4wELEAoNCgUEBAIAARIE4wERHgoN
CgUEBAIAAxIE4wEhIgowCgQEBAIBEgTmAQI4GiIgQ29udGFpbmVyIHJlc291cmNlIHJlcXVp
cmVtZW50cy4KCg0KBQQEAgEEEgTmAQIKCg0KBQQEAgEGEgTmAQsfCg0KBQQEAgEBEgTmASAz
Cg0KBQQEAgEDEgTmATY3ClUKBAQEAgISBOkBAjoaRyBQb2QgYW50aS1hZmZpbml0eSBlbmFi
bGVtZW50LiBEZXByZWNhdGVkOiB1c2UgYHBvZF9hZmZpbml0eWAgaW5zdGVhZC4KCg0KBQQE
AgIEEgTpAQIKCg0KBQQEAgIFEgTpAQsPCg0KBQQEAgIBEgTpARAhCg0KBQQEAgIDEgTpASQl
Cg0KBQQEAgIIEgTpASY5Cg4KBgQEAgIIAxIE6QEnOAovCgQEBAIDEgTsAQIqGiEgUG9kIHRv
bGVyYXRpb25zIG9mIG5vZGUgdGFpbnRzLgoKDQoFBAQCAwQSBOwBAgoKDQoFBAQCAwYSBOwB
CxUKDQoFBAQCAwESBOwBFiUKDQoFBAQCAwMSBOwBKCkKKwoEBAQCBBIE7wECHBodIFBvZCBh
ZmZpbml0eSBjb25maWd1cmF0aW9uLgoKDQoFBAQCBAYSBO8BAgoKDQoFBAQCBAESBO8BCxcK
DQoFBAQCBAMSBO8BGhsKUQoCBAUSBvMBAPsBARpDIFJlc291cmNlUmVxdWlyZW1lbnRzIGRl
c2NyaWJlcyB0aGUgY29tcHV0ZSByZXNvdXJjZSByZXF1aXJlbWVudHMuCgoLCgMEBQESBPMB
CBwKcwoEBAUCABIE9gECIxplIExpbWl0cyBkZXNjcmliZXMgdGhlIG1heGltdW0gYW1vdW50
IG9mIGNvbXB1dGUgcmVzb3VyY2VzIGFsbG93ZWQgZm9yIHVzZSBieQogdGhlIHJ1bm5pbmcg
Y29udGFpbmVyLgoKDQoFBAUCAAQSBPYBAgoKDQoFBAUCAAYSBPYBCxcKDQoFBAUCAAESBPYB
GB4KDQoFBAUCAAMSBPYBISIKdQoEBAUCARIE+gECJRpnIFJlcXVlc3RzIGRlc2NyaWJlcyB0
aGUgYW1vdW50IG9mIGNvbXB1dGUgcmVzb3VyY2VzIHJlc2VydmVkIGZvciB0aGUKIGNvbnRh
aW5lciBieSB0aGUga3ViZS1zY2hlZHVsZXIuCgoNCgUEBQIBBBIE+gECCgoNCgUEBQIBBhIE
+gELFwoNCgUEBQIBARIE+gEYIAoNCgUEBQIBAxIE+gEjJApGCgIEBhIG/gEAhAIBGjggUmVz
b3VyY2VMaXN0IGNvbnRhaW5zIGNvbnRhaW5lciByZXNvdXJjZSByZXF1aXJlbWVudHMuCgoL
CgMEBgESBP4BCBQKSgoEBAYCABIEgAICHRo8IE1lbW9yeSByZXF1aXJlbWVudCBleHByZXNz
ZWQgaW4gS3ViZXJuZXRlcyByZXNvdXJjZSB1bml0cy4KCg0KBQQGAgAEEgSAAgIKCg0KBQQG
AgAFEgSAAgsRCg0KBQQGAgABEgSAAhIYCg0KBQQGAgADEgSAAhscCkcKBAQGAgESBIMCAhoa
OSBDUFUgcmVxdWlyZW1lbnQgZXhwcmVzc2VkIGluIEt1YmVybmV0ZXMgcmVzb3VyY2UgdW5p
dHMuCgoNCgUEBgIBBBIEgwICCgoNCgUEBgIBBRIEgwILEQoNCgUEBgIBARIEgwISFQoNCgUE
BgIBAxIEgwIYGQpRCgIEBxIGhwIAlwIBGkMgVGhlIGNvbmZpZyBzcGVjaWZ5aW5nIHdoaWNo
IGRlZmF1bHQgbGlicmFyeSB0ZW1wbGF0ZXMgdG8gaW5zdGFsbC4KCgsKAwQHARIEhwIIHQo+
CgQEBwQAEgaJAgKSAgMaLiBIb3cgdGhlIHRlbXBsYXRlIGxpYnJhcnkgc2hvdWxkIGJlIGlu
c3RhbGxlZAoKDQoFBAcEAAESBIkCBxMKPgoGBAcEAAIAEgSLAgQhGi4gTm8gaW5zdGFsbGF0
aW9uIHN0cmF0ZWd5IGhhcyBiZWVuIHNwZWNpZmllZC4KCg8KBwQHBAACAAESBIsCBBwKDwoH
BAcEAAIAAhIEiwIfIAo2CgYEBwQAAgESBI4CBBYaJiBEbyBub3QgaW5zdGFsbCB0aGUgdGVt
cGxhdGUgbGlicmFyeS4KCg8KBwQHBAACAQESBI4CBBEKDwoHBAcEAAIBAhIEjgIUFQo2CgYE
BwQAAgISBJECBAwaJiBJbnN0YWxsIHRoZSBlbnRpcmUgdGVtcGxhdGUgbGlicmFyeS4KCg8K
BwQHBAACAgESBJECBAcKDwoHBAcEAAICAhIEkQIKCwphCgQEBwIAEgSWAgIgGlMgQ29uZmln
dXJlcyB0aGUgbWFubmVyIGluIHdoaWNoIHRoZSB0ZW1wbGF0ZSBsaWJyYXJ5IGlzIGluc3Rh
bGxlZCBvbiB0aGUKIGNsdXN0ZXIuCgoNCgUEBwIABhIElgICDgoNCgUEBwIAARIElgIPGwoN
CgUEBwIAAxIElgIeHwryAQoCBAgSBp0CAK0CARrjASBNb25pdG9yaW5nQ29uZmlnIHNwZWNp
ZmllcyB0aGUgYmFja2VuZHMgUG9saWN5IENvbnRyb2xsZXIgc2hvdWxkCiBleHBvcnQgbWV0
cmljcyB0by4gRm9yIGV4YW1wbGUsIHRvIHNwZWNpZnkgbWV0cmljcyBzaG91bGQgYmUgZXhw
b3J0ZWQgdG8KIENsb3VkIE1vbml0b3JpbmcgYW5kIFByb21ldGhldXMsIHNwZWNpZnkKIGJh
Y2tlbmRzOiBbImNsb3VkbW9uaXRvcmluZyIsICJwcm9tZXRoZXVzIl0KCgsKAwQIARIEnQII
GAo6CgQECAQAEgafAgKoAgMaKiBTdXBwb3J0ZWQgYmFja2VuZCBvcHRpb25zIGZvciBtb25p
dG9yaW5nCgoNCgUECAQAARIEnwIHGAouCgYECAQAAgASBKECBCcaHiBCYWNrZW5kIGNhbm5v
dCBiZSBkZXRlcm1pbmVkCgoPCgcECAQAAgABEgShAgQiCg8KBwQIBAACAAISBKECJSYKMwoG
BAgEAAIBEgSkAgQTGiMgUHJvbWV0aGV1cyBiYWNrZW5kIGZvciBtb25pdG9yaW5nCgoPCgcE
CAQAAgEBEgSkAgQOCg8KBwQIBAACAQISBKQCERIKRQoGBAgEAAICEgSnAgQZGjUgU3RhY2tk
cml2ZXIvQ2xvdWQgTW9uaXRvcmluZyBiYWNrZW5kIGZvciBtb25pdG9yaW5nCgoPCgcECAQA
AgIBEgSnAgQUCg8KBwQIBAACAgISBKcCFxgKiQEKBAQIAgASBKwCAioaeyBTcGVjaWZpZXMg
dGhlIGxpc3Qgb2YgYmFja2VuZHMgUG9saWN5IENvbnRyb2xsZXIgd2lsbCBleHBvcnQgdG8u
CiBBbiBlbXB0eSBsaXN0IHdvdWxkIGVmZmVjdGl2ZWx5IGRpc2FibGUgbWV0cmljcyBleHBv
cnQuCgoNCgUECAIABBIErAICCgoNCgUECAIABhIErAILHAoNCgUECAIAARIErAIdJQoNCgUE
CAIAAxIErAIoKQpcCgIECRIGsAIAtgIBGk4gT25DbHVzdGVyU3RhdGUgcmVwcmVzZW50cyB0
aGUgc3RhdGUgb2YgYSBzdWItY29tcG9uZW50IG9mIFBvbGljeSBDb250cm9sbGVyLgoKCwoD
BAkBEgSwAggWCjYKBAQJAgASBLICAisaKCBUaGUgbGlmZWN5Y2xlIHN0YXRlIG9mIHRoaXMg
Y29tcG9uZW50LgoKDQoFBAkCAAYSBLICAiAKDQoFBAkCAAESBLICISYKDQoFBAkCAAMSBLIC
KSoKPQoEBAkCARIEtQICFRovIFN1cmZhY2UgcG90ZW50aWFsIGVycm9ycyBvciBpbmZvcm1h
dGlvbiBsb2dzLgoKDQoFBAkCAQUSBLUCAggKDQoFBAkCAQESBLUCCRAKDQoFBAkCAQMSBLUC
ExQKYgoCBAoSBroCAL0CARpUIEJ1bmRsZUluc3RhbGxTcGVjIGlzIHRoZSBzcGVjaWZpY2F0
aW9uIGNvbmZpZ3VyYXRpb24gZm9yIGEgc2luZ2xlIG1hbmFnZWQKIGJ1bmRsZS4KCgsKAwQK
ARIEugIIGQpFCgQECgIAEgS8AgIqGjcgVGhlIHNldCBvZiBuYW1lc3BhY2VzIHRvIGJlIGV4
ZW1wdGVkIGZyb20gdGhlIGJ1bmRsZS4KCg0KBQQKAgAEEgS8AgIKCg0KBQQKAgAFEgS8AgsR
Cg0KBQQKAgABEgS8AhIlCg0KBQQKAgADEgS8AigpCmMKAgQLEgbBAgDJAgEaVSBQb2xpY3lD
b250ZW50U3BlYyBkZWZpbmVzIHRoZSB1c2VyJ3MgZGVzaXJlZCBjb250ZW50IGNvbmZpZ3Vy
YXRpb24gb24gdGhlCiBjbHVzdGVyLgoKCwoDBAsBEgTBAggZCrQBCgQECwIAEgTFAgItGqUB
IG1hcCBvZiBidW5kbGUgbmFtZSB0byBCdW5kbGVJbnN0YWxsU3BlYy4gVGhlIGJ1bmRsZSBu
YW1lIG1hcHMgdG8gdGhlCiBgYnVuZGxlTmFtZWAga2V5IGluIHRoZSBgcG9saWN5Y29udHJv
bGxlci5na2UuaW8vY29uc3RyYWludERhdGFgIGFubm90YXRpb24KIG9uIGEgY29uc3RyYWlu
dC4KCg0KBQQLAgAGEgTFAgIgCg0KBQQLAgABEgTFAiEoCg0KBQQLAgADEgTFAissCkQKBAQL
AgESBMgCAi0aNiBDb25maWd1cmVzIHRoZSBpbnN0YWxsYXRpb24gb2YgdGhlIFRlbXBsYXRl
IExpYnJhcnkuCgoNCgUECwIBBhIEyAICFwoNCgUECwIBARIEyAIYKAoNCgUECwIBAxIEyAIr
LGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState ===
    # Fields for MembershipState
    # Field: component_states Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.MembershipState.ComponentStatesEntry)
    # Field: state Type: 14 (.google.cloud.gkehub.policycontroller.v1beta.MembershipState.LifecycleState)
    # Field: policy_content_state Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.PolicyContentState)

# Enum: MembershipState::LifecycleState
our $MembershipState_LIFECYCLE_STATE_UNSPECIFIED = 0;
our $MembershipState_NOT_INSTALLED = 1;
our $MembershipState_INSTALLING = 2;
our $MembershipState_ACTIVE = 3;
our $MembershipState_UPDATING = 4;
our $MembershipState_DECOMMISSIONING = 5;
our $MembershipState_CLUSTER_ERROR = 6;
our $MembershipState_HUB_ERROR = 7;
our $MembershipState_SUSPENDED = 8;
our $MembershipState_DETACHED = 9;

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState ===
    # Fields for PolicyContentState
    # Field: template_library_state Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.OnClusterState)
    # Field: bundle_states Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.PolicyContentState.BundleStatesEntry)
    # Field: referential_sync_config_state Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.OnClusterState)

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipSpec ===
    # Fields for MembershipSpec
    # Field: policy_controller_hub_config Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.HubConfig)
    # Field: version Type: 9 ()

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig ===
    # Fields for HubConfig
    # Field: install_spec Type: 14 (.google.cloud.gkehub.policycontroller.v1beta.HubConfig.InstallSpec)
    # Field: audit_interval_seconds Type: 3 ()
    # Field: exemptable_namespaces Type: 9 ()
    # Field: referential_rules_enabled Type: 8 ()
    # Field: log_denies_enabled Type: 8 ()
    # Field: mutation_enabled Type: 8 ()
    # Field: monitoring Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.MonitoringConfig)
    # Field: policy_content Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.PolicyContentSpec)
    # Field: constraint_violation_limit Type: 3 ()
    # Field: deployment_configs Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.HubConfig.DeploymentConfigsEntry)

# Enum: HubConfig::InstallSpec
our $HubConfig_INSTALL_SPEC_UNSPECIFIED = 0;
our $HubConfig_INSTALL_SPEC_NOT_INSTALLED = 1;
our $HubConfig_INSTALL_SPEC_ENABLED = 2;
our $HubConfig_INSTALL_SPEC_SUSPENDED = 3;
our $HubConfig_INSTALL_SPEC_DETACHED = 4;

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig ===
    # Fields for PolicyControllerDeploymentConfig
    # Field: replica_count Type: 3 ()
    # Field: container_resources Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.ResourceRequirements)
    # Field: pod_anti_affinity Type: 8 ()
    # Field: pod_tolerations Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.PolicyControllerDeploymentConfig.Toleration)
    # Field: pod_affinity Type: 14 (.google.cloud.gkehub.policycontroller.v1beta.PolicyControllerDeploymentConfig.Affinity)

# Enum: PolicyControllerDeploymentConfig::Affinity
our $PolicyControllerDeploymentConfig_AFFINITY_UNSPECIFIED = 0;
our $PolicyControllerDeploymentConfig_NO_AFFINITY = 1;
our $PolicyControllerDeploymentConfig_ANTI_AFFINITY = 2;

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceRequirements ===
    # Fields for ResourceRequirements
    # Field: limits Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.ResourceList)
    # Field: requests Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.ResourceList)

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList ===
    # Fields for ResourceList
    # Field: memory Type: 9 ()
    # Field: cpu Type: 9 ()

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::TemplateLibraryConfig ===
    # Fields for TemplateLibraryConfig
    # Field: installation Type: 14 (.google.cloud.gkehub.policycontroller.v1beta.TemplateLibraryConfig.Installation)

# Enum: TemplateLibraryConfig::Installation
our $TemplateLibraryConfig_INSTALLATION_UNSPECIFIED = 0;
our $TemplateLibraryConfig_NOT_INSTALLED = 1;
our $TemplateLibraryConfig_ALL = 2;

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MonitoringConfig ===
    # Fields for MonitoringConfig
    # Field: backends Type: 14 (.google.cloud.gkehub.policycontroller.v1beta.MonitoringConfig.MonitoringBackend)

# Enum: MonitoringConfig::MonitoringBackend
our $MonitoringConfig_MONITORING_BACKEND_UNSPECIFIED = 0;
our $MonitoringConfig_PROMETHEUS = 1;
our $MonitoringConfig_CLOUD_MONITORING = 2;

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState ===
    # Fields for OnClusterState
    # Field: state Type: 14 (.google.cloud.gkehub.policycontroller.v1beta.MembershipState.LifecycleState)
    # Field: details Type: 9 ()

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::BundleInstallSpec ===
    # Fields for BundleInstallSpec
    # Field: exempted_namespaces Type: 9 ()

# === Message: Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec ===
    # Fields for PolicyContentSpec
    # Field: bundles Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.PolicyContentSpec.BundlesEntry)
    # Field: template_library Type: 11 (.google.cloud.gkehub.policycontroller.v1beta.TemplateLibraryConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller - Compiled Protocol Buffers messages for google/cloud/gkehub/policycontroller/v1beta/policycontroller.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller;

    my $msg = Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState->new({
        component_states => $component_states,
        state => $state,
        policy_content_state => $policy_content_state,
    });

    # Read or update a field
    my $val = $msg->component_states();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/policycontroller/v1beta/policycontroller.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState

B<Policy Controller>: State for a single cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->component_states() >> / C<< $msg->component_states($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState::ComponentStatesEntry>)

Currently these include (also serving as map keys):
1. "admission"
2. "audit"
3. "mutation"

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::MembershipState::LifecycleState>)

The overall Policy Controller lifecycle state observed by the Hub Feature
controller.

=item * C<< $msg->policy_content_state() >> / C<< $msg->policy_content_state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState>)

The overall content state observed by the Hub Feature controller.

=back

=head3 Enum: MembershipState::LifecycleState

=over 4

=item * C<LIFECYCLE_STATE_UNSPECIFIED> => C<0>

=item * C<NOT_INSTALLED> => C<1>

=item * C<INSTALLING> => C<2>

=item * C<ACTIVE> => C<3>

=item * C<UPDATING> => C<4>

=item * C<DECOMMISSIONING> => C<5>

=item * C<CLUSTER_ERROR> => C<6>

=item * C<HUB_ERROR> => C<7>

=item * C<SUSPENDED> => C<8>

=item * C<DETACHED> => C<9>

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState

The state of the policy controller policy content

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->template_library_state() >> / C<< $msg->template_library_state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState>)

The state of the template library

=item * C<< $msg->bundle_states() >> / C<< $msg->bundle_states($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState::BundleStatesEntry>)

The state of the any bundles included in the chosen
version of the manifest

=item * C<< $msg->referential_sync_config_state() >> / C<< $msg->referential_sync_config_state($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState>)

The state of the referential data sync configuration.  This could
represent the state of either the syncSet object(s) or the config
object, depending on the version of PoCo configured by the user.

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipSpec

B<Policy Controller>: Configuration for a single cluster.
Intended to parallel the PolicyController CR.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_controller_hub_config() >> / C<< $msg->policy_controller_hub_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig>)

Policy Controller configuration for the cluster.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Version of Policy Controller installed.

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig

Configuration for Policy Controller

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->install_spec() >> / C<< $msg->install_spec($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::HubConfig::InstallSpec>)

The install_spec represents the intended state specified by the
latest request that mutated install_spec in the feature spec,
not the lifecycle state of the
feature observed by the Hub feature controller
that is reported in the feature state.

=item * C<< $msg->audit_interval_seconds() >> / C<< $msg->audit_interval_seconds($value) >>

Type: C<Int64>

Sets the interval for Policy Controller Audit Scans (in seconds).
When set to 0, this disables audit functionality altogether.

=item * C<< $msg->exemptable_namespaces() >> / C<< $msg->exemptable_namespaces($value) >>

Type: C<String>

The set of namespaces that are excluded from Policy Controller checks.
Namespaces do not need to currently exist on the cluster.

=item * C<< $msg->referential_rules_enabled() >> / C<< $msg->referential_rules_enabled($value) >>

Type: C<Bool>

Enables the ability to use Constraint Templates that reference to objects
other than the object currently being evaluated.

=item * C<< $msg->log_denies_enabled() >> / C<< $msg->log_denies_enabled($value) >>

Type: C<Bool>

Logs all denies and dry run failures.

=item * C<< $msg->mutation_enabled() >> / C<< $msg->mutation_enabled($value) >>

Type: C<Bool>

Enables the ability to mutate resources using Policy Controller.

=item * C<< $msg->monitoring() >> / C<< $msg->monitoring($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MonitoringConfig>)

Monitoring specifies the configuration of monitoring.

=item * C<< $msg->policy_content() >> / C<< $msg->policy_content($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec>)

Specifies the desired policy content on the cluster

=item * C<< $msg->constraint_violation_limit() >> / C<< $msg->constraint_violation_limit($value) >>

Type: C<Int64>

The maximum number of audit violations to be stored in a constraint.
If not set, the internal default (currently 20) will be used.

=item * C<< $msg->deployment_configs() >> / C<< $msg->deployment_configs($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig::DeploymentConfigsEntry>)

Map of deployment configs to deployments ("admission", "audit",
"mutation').

=back

=head3 Enum: HubConfig::InstallSpec

=over 4

=item * C<INSTALL_SPEC_UNSPECIFIED> => C<0>

=item * C<INSTALL_SPEC_NOT_INSTALLED> => C<1>

=item * C<INSTALL_SPEC_ENABLED> => C<2>

=item * C<INSTALL_SPEC_SUSPENDED> => C<3>

=item * C<INSTALL_SPEC_DETACHED> => C<4>

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig

Deployment-specific configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->replica_count() >> / C<< $msg->replica_count($value) >>

Type: C<Int64>

Pod replica count.

=item * C<< $msg->container_resources() >> / C<< $msg->container_resources($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceRequirements>)

Container resource requirements.

=item * C<< $msg->pod_anti_affinity() >> / C<< $msg->pod_anti_affinity($value) >>

Type: C<Bool>

Pod anti-affinity enablement. Deprecated: use `pod_affinity` instead.

=item * C<< $msg->pod_tolerations() >> / C<< $msg->pod_tolerations($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig::Toleration>)

Pod tolerations of node taints.

=item * C<< $msg->pod_affinity() >> / C<< $msg->pod_affinity($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::PolicyControllerDeploymentConfig::Affinity>)

Pod affinity configuration.

=back

=head3 Enum: PolicyControllerDeploymentConfig::Affinity

=over 4

=item * C<AFFINITY_UNSPECIFIED> => C<0>

=item * C<NO_AFFINITY> => C<1>

=item * C<ANTI_AFFINITY> => C<2>

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceRequirements

ResourceRequirements describes the compute resource requirements.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->limits() >> / C<< $msg->limits($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList>)

Limits describes the maximum amount of compute resources allowed for use by
the running container.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList>)

Requests describes the amount of compute resources reserved for the
container by the kube-scheduler.

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList

ResourceList contains container resource requirements.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->memory() >> / C<< $msg->memory($value) >>

Type: C<String>

Memory requirement expressed in Kubernetes resource units.

=item * C<< $msg->cpu() >> / C<< $msg->cpu($value) >>

Type: C<String>

CPU requirement expressed in Kubernetes resource units.

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::TemplateLibraryConfig

The config specifying which default library templates to install.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->installation() >> / C<< $msg->installation($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::TemplateLibraryConfig::Installation>)

Configures the manner in which the template library is installed on the
cluster.

=back

=head3 Enum: TemplateLibraryConfig::Installation

=over 4

=item * C<INSTALLATION_UNSPECIFIED> => C<0>

=item * C<NOT_INSTALLED> => C<1>

=item * C<ALL> => C<2>

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MonitoringConfig

MonitoringConfig specifies the backends Policy Controller should
export metrics to. For example, to specify metrics should be exported to
Cloud Monitoring and Prometheus, specify
backends: ["cloudmonitoring", "prometheus"]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backends() >> / C<< $msg->backends($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::MonitoringConfig::MonitoringBackend>)

Specifies the list of backends Policy Controller will export to.
An empty list would effectively disable metrics export.

=back

=head3 Enum: MonitoringConfig::MonitoringBackend

=over 4

=item * C<MONITORING_BACKEND_UNSPECIFIED> => C<0>

=item * C<PROMETHEUS> => C<1>

=item * C<CLOUD_MONITORING> => C<2>

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState

OnClusterState represents the state of a sub-component of Policy Controller.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::MembershipState::LifecycleState>)

The lifecycle state of this component.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<String>

Surface potential errors or information logs.

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::BundleInstallSpec

BundleInstallSpec is the specification configuration for a single managed
bundle.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exempted_namespaces() >> / C<< $msg->exempted_namespaces($value) >>

Type: C<String>

The set of namespaces to be exempted from the bundle.

=back

=head2 Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec

PolicyContentSpec defines the user's desired content configuration on the
cluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bundles() >> / C<< $msg->bundles($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec::BundlesEntry>)

map of bundle name to BundleInstallSpec. The bundle name maps to the
`bundleName` key in the `policycontroller.gke.io/constraintData` annotation
on a constraint.

=item * C<< $msg->template_library() >> / C<< $msg->template_library($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::TemplateLibraryConfig>)

Configures the installation of the Template Library.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
