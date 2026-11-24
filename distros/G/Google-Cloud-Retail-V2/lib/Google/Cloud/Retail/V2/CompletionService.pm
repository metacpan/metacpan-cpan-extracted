package Google::Cloud::Retail::V2::CompletionService;

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
    eval { require Google::Cloud::Retail::V2::Common };
    eval { require Google::Cloud::Retail::V2::ImportConfig };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcmV0YWlsL3YyL2NvbXBsZXRpb25fc2VydmljZS5wcm90bxIWZ29v
Z2xlLmNsb3VkLnJldGFpbC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC9yZXRhaWwvdjIvY29t
bW9uLnByb3RvGipnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2ltcG9ydF9jb25maWcucHJvdG8a
I2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvIvYCChRDb21wbGV0ZVF1ZXJ5
UmVxdWVzdBI/CgdjYXRhbG9nGAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNv
bS9DYXRhbG9nUgdjYXRhbG9nEhkKBXF1ZXJ5GAIgASgJQgPgQQJSBXF1ZXJ5Eh0KCnZpc2l0
b3JfaWQYByABKAlSCXZpc2l0b3JJZBIlCg5sYW5ndWFnZV9jb2RlcxgDIAMoCVINbGFuZ3Vh
Z2VDb2RlcxIfCgtkZXZpY2VfdHlwZRgEIAEoCVIKZGV2aWNlVHlwZRIYCgdkYXRhc2V0GAYg
ASgJUgdkYXRhc2V0EicKD21heF9zdWdnZXN0aW9ucxgFIAEoBVIObWF4U3VnZ2VzdGlvbnMS
QAocZW5hYmxlX2F0dHJpYnV0ZV9zdWdnZXN0aW9ucxgJIAEoCFIaZW5hYmxlQXR0cmlidXRl
U3VnZ2VzdGlvbnMSFgoGZW50aXR5GAogASgJUgZlbnRpdHkipQcKFUNvbXBsZXRlUXVlcnlS
ZXNwb25zZRJtChJjb21wbGV0aW9uX3Jlc3VsdHMYASADKAsyPi5nb29nbGUuY2xvdWQucmV0
YWlsLnYyLkNvbXBsZXRlUXVlcnlSZXNwb25zZS5Db21wbGV0aW9uUmVzdWx0UhFjb21wbGV0
aW9uUmVzdWx0cxIrChFhdHRyaWJ1dGlvbl90b2tlbhgCIAEoCVIQYXR0cmlidXRpb25Ub2tl
bhJ4ChVyZWNlbnRfc2VhcmNoX3Jlc3VsdHMYAyADKAsyQC5nb29nbGUuY2xvdWQucmV0YWls
LnYyLkNvbXBsZXRlUXVlcnlSZXNwb25zZS5SZWNlbnRTZWFyY2hSZXN1bHRCAhgBUhNyZWNl
bnRTZWFyY2hSZXN1bHRzEnAKEWF0dHJpYnV0ZV9yZXN1bHRzGAQgAygLMkMuZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Db21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQXR0cmlidXRlUmVzdWx0c0Vu
dHJ5UhBhdHRyaWJ1dGVSZXN1bHRzGooCChBDb21wbGV0aW9uUmVzdWx0Eh4KCnN1Z2dlc3Rp
b24YASABKAlSCnN1Z2dlc3Rpb24SbgoKYXR0cmlidXRlcxgCIAMoCzJOLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjIuQ29tcGxldGVRdWVyeVJlc3BvbnNlLkNvbXBsZXRpb25SZXN1bHQuQXR0
cmlidXRlc0VudHJ5UgphdHRyaWJ1dGVzGmYKD0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRI9CgV2YWx1ZRgCIAEoCzInLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ3VzdG9t
QXR0cmlidXRlUgV2YWx1ZToCOAEaPQoSUmVjZW50U2VhcmNoUmVzdWx0EiMKDXJlY2VudF9z
ZWFyY2gYASABKAlSDHJlY2VudFNlYXJjaDoCGAEaMwoPQXR0cmlidXRlUmVzdWx0EiAKC3N1
Z2dlc3Rpb25zGAEgAygJUgtzdWdnZXN0aW9ucxqCAQoVQXR0cmlidXRlUmVzdWx0c0VudHJ5
EhAKA2tleRgBIAEoCVIDa2V5ElMKBXZhbHVlGAIgASgLMj0uZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5Db21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQXR0cmlidXRlUmVzdWx0UgV2YWx1ZToCOAEy
sgQKEUNvbXBsZXRpb25TZXJ2aWNlErMBCg1Db21wbGV0ZVF1ZXJ5EiwuZ29vZ2xlLmNsb3Vk
LnJldGFpbC52Mi5Db21wbGV0ZVF1ZXJ5UmVxdWVzdBotLmdvb2dsZS5jbG91ZC5yZXRhaWwu
djIuQ29tcGxldGVRdWVyeVJlc3BvbnNlIkWC0+STAj8SPS92Mi97Y2F0YWxvZz1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9OmNvbXBsZXRlUXVlcnkSmwIKFEltcG9ydENv
bXBsZXRpb25EYXRhEjMuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5JbXBvcnRDb21wbGV0aW9u
RGF0YVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIq4BgtPkkwJJIkQv
djIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L2NvbXBsZXRp
b25EYXRhOmltcG9ydDoBKspBXAozZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5JbXBvcnRDb21w
bGV0aW9uRGF0YVJlc3BvbnNlEiVnb29nbGUuY2xvdWQucmV0YWlsLnYyLkltcG9ydE1ldGFk
YXRhGknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQsEBChpjb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52
MkIWQ29tcGxldGlvblNlcnZpY2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3JldGFp
bC9hcGl2Mi9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCFkdvb2dsZS5DbG91ZC5SZXRh
aWwuVjLKAhZHb29nbGVcQ2xvdWRcUmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91ZDo6UmV0YWls
OjpWMkqmQwoHEgUOAPgBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAHwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkK
AgMEEgMWAC0KCQoCAwUSAxcANAoJCgIDBhIDGAAtCggKAQgSAxoAMwoJCgIIJRIDGgAzCggK
AQgSAxsASQoJCgIICxIDGwBJCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANwoJCgII
CBIDHQA3CggKAQgSAx4AMwoJCgIIARIDHgAzCggKAQgSAx8AJAoJCgIIJBIDHwAkCggKAQgS
AyAAMwoJCgIIKRIDIAAzCggKAQgSAyEAMgoJCgIILRIDIQAyCrwBCgIGABIEJwBKARqvASBB
dXRvY29tcGxldGUgc2VydmljZSBmb3IgcmV0YWlsLgoKIFRoaXMgZmVhdHVyZSBpcyBvbmx5
IGF2YWlsYWJsZSBmb3IgdXNlcnMgd2hvIGhhdmUgUmV0YWlsIFNlYXJjaCBlbmFibGVkLgog
RW5hYmxlIFJldGFpbCBTZWFyY2ggb24gQ2xvdWQgQ29uc29sZSBiZWZvcmUgdXNpbmcgdGhp
cyBmZWF0dXJlLgoKCgoDBgABEgMnCBkKCgoDBgADEgMoAj0KDAoFBgADmQgSAygCPQoLCgMG
AAMSBCkCKjcKDQoFBgADmggSBCkCKjcK1gEKBAYAAgASBDACNAMaxwEgQ29tcGxldGVzIHRo
ZSBzcGVjaWZpZWQgcHJlZml4IHdpdGgga2V5d29yZCBzdWdnZXN0aW9ucy4KCiBUaGlzIGZl
YXR1cmUgaXMgb25seSBhdmFpbGFibGUgZm9yIHVzZXJzIHdobyBoYXZlIFJldGFpbCBTZWFy
Y2ggZW5hYmxlZC4KIEVuYWJsZSBSZXRhaWwgU2VhcmNoIG9uIENsb3VkIENvbnNvbGUgYmVm
b3JlIHVzaW5nIHRoaXMgZmVhdHVyZS4KCgwKBQYAAgABEgMwBhMKDAoFBgACAAISAzAUKAoM
CgUGAAIAAxIDMDNICg0KBQYAAgAEEgQxBDMGChEKCQYAAgAEsMq8IhIEMQQzBgqqAwoEBgAC
ARIEPwJJAxqbAyBCdWxrIGltcG9ydCBvZiBwcm9jZXNzZWQgY29tcGxldGlvbiBkYXRhc2V0
LgoKIFJlcXVlc3QgcHJvY2Vzc2luZyBpcyBhc3luY2hyb25vdXMuIFBhcnRpYWwgdXBkYXRp
bmcgaXMgbm90IHN1cHBvcnRlZC4KCiBUaGUgb3BlcmF0aW9uIGlzIHN1Y2Nlc3NmdWxseSBm
aW5pc2hlZCBvbmx5IGFmdGVyIHRoZSBpbXBvcnRlZCBzdWdnZXN0aW9ucwogYXJlIGluZGV4
ZWQgc3VjY2Vzc2Z1bGx5IGFuZCByZWFkeSBmb3Igc2VydmluZy4gVGhlIHByb2Nlc3MgdGFr
ZXMgaG91cnMuCgogVGhpcyBmZWF0dXJlIGlzIG9ubHkgYXZhaWxhYmxlIGZvciB1c2VycyB3
aG8gaGF2ZSBSZXRhaWwgU2VhcmNoIGVuYWJsZWQuCiBFbmFibGUgUmV0YWlsIFNlYXJjaCBv
biBDbG91ZCBDb25zb2xlIGJlZm9yZSB1c2luZyB0aGlzIGZlYXR1cmUuCgoMCgUGAAIBARID
PwYaCgwKBQYAAgECEgM/GzYKDAoFBgACAQMSA0APKwoNCgUGAAIBBBIEQQREBgoRCgkGAAIB
BLDKvCISBEEERAYKDQoFBgACAQQSBEUESAYKDwoHBgACAQSZCBIERQRIBgonCgIEABIFTQCr
AQEaGiBBdXRvY29tcGxldGUgcGFyYW1ldGVycy4KCgoKAwQAARIDTQgcCqsBCgQEAAIAEgRS
AlUEGpwBIFJlcXVpcmVkLiBDYXRhbG9nIGZvciB3aGljaCB0aGUgY29tcGxldGlvbiBpcyBw
ZXJmb3JtZWQuCgogRnVsbCByZXNvdXJjZSBuYW1lIG9mIGNhdGFsb2csIHN1Y2ggYXMKIGBw
cm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9nYC4K
CgwKBQQAAgAFEgNSAggKDAoFBAACAAESA1IJEAoMCgUEAAIAAxIDUhMUCg0KBQQAAgAIEgRS
FVUDCg8KCAQAAgAInAgAEgNTBCoKDgoHBAACAAifCBIDVARPCnMKBAQAAgESA1oCPBpmIFJl
cXVpcmVkLiBUaGUgcXVlcnkgdXNlZCB0byBnZW5lcmF0ZSBzdWdnZXN0aW9ucy4KCiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDI1NS4KCgwKBQQAAgEF
EgNaAggKDAoFBAACAQESA1oJDgoMCgUEAAIBAxIDWhESCgwKBQQAAgEIEgNaEzsKDwoIBAAC
AQicCAASA1oUOgqwAwoEBAACAhIDYwIYGqIDIFJlY29tbWVuZGVkIGZpZWxkLiBBIHVuaXF1
ZSBpZGVudGlmaWVyIGZvciB0cmFja2luZyB2aXNpdG9ycy4gRm9yIGV4YW1wbGUsCiB0aGlz
IGNvdWxkIGJlIGltcGxlbWVudGVkIHdpdGggYW4gSFRUUCBjb29raWUsIHdoaWNoIHNob3Vs
ZCBiZSBhYmxlIHRvCiB1bmlxdWVseSBpZGVudGlmeSBhIHZpc2l0b3Igb24gYSBzaW5nbGUg
ZGV2aWNlLiBUaGlzIHVuaXF1ZSBpZGVudGlmaWVyCiBzaG91bGQgbm90IGNoYW5nZSBpZiB0
aGUgdmlzaXRvciBsb2dzIGluIG9yIG91dCBvZiB0aGUgd2Vic2l0ZS4KCiBUaGUgZmllbGQg
bXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2Yg
MTI4CiBjaGFyYWN0ZXJzLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3Ig
aXMgcmV0dXJuZWQuCgoMCgUEAAICBRIDYwIICgwKBQQAAgIBEgNjCRMKDAoFBAACAgMSA2MW
FwqlBAoEBAACAxIDbgIlGpcEIE5vdGUgdGhhdCB0aGlzIGZpZWxkIGFwcGxpZXMgZm9yIGB1
c2VyLWRhdGFgIGRhdGFzZXQgb25seS4gRm9yIHJlcXVlc3RzCiB3aXRoIGBjbG91ZC1yZXRh
aWxgIGRhdGFzZXQsIHNldHRpbmcgdGhpcyBmaWVsZCBoYXMgbm8gZWZmZWN0LgoKIFRoZSBs
YW5ndWFnZSBmaWx0ZXJzIGFwcGxpZWQgdG8gdGhlIG91dHB1dCBzdWdnZXN0aW9ucy4gSWYg
c2V0LCBpdCBzaG91bGQKIGNvbnRhaW4gdGhlIGxhbmd1YWdlIG9mIHRoZSBxdWVyeS4gSWYg
bm90IHNldCwgc3VnZ2VzdGlvbnMgYXJlIHJldHVybmVkCiB3aXRob3V0IGNvbnNpZGVyaW5n
IGxhbmd1YWdlIHJlc3RyaWN0aW9ucy4gVGhpcyBpcyB0aGUgQkNQLTQ3IGxhbmd1YWdlCiBj
b2RlLCBzdWNoIGFzICJlbi1VUyIgb3IgInNyLUxhdG4iLiBGb3IgbW9yZSBpbmZvcm1hdGlv
biwgc2VlIFtUYWdzIGZvcgogSWRlbnRpZnlpbmcgTGFuZ3VhZ2VzXShodHRwczovL3Rvb2xz
LmlldGYub3JnL2h0bWwvYmNwNDcpLiBUaGUgbWF4aW11bQogbnVtYmVyIG9mIGxhbmd1YWdl
IGNvZGVzIGlzIDMuCgoMCgUEAAIDBBIDbgIKCgwKBQQAAgMFEgNuCxEKDAoFBAACAwESA24S
IAoMCgUEAAIDAxIDbiMkCpkDCgQEAAIEEgSAAQIZGooDIFRoZSBkZXZpY2UgdHlwZSBjb250
ZXh0IGZvciBjb21wbGV0aW9uIHN1Z2dlc3Rpb25zLiBXZSByZWNvbW1lbmQgdGhhdCB5b3UK
IGxlYXZlIHRoaXMgZmllbGQgZW1wdHkuCgogSXQgY2FuIGFwcGx5IGRpZmZlcmVudCBzdWdn
ZXN0aW9ucyBvbiBkaWZmZXJlbnQgZGV2aWNlIHR5cGVzLCBlLmcuCiBgREVTS1RPUGAsIGBN
T0JJTEVgLiBJZiBpdCBpcyBlbXB0eSwgdGhlIHN1Z2dlc3Rpb25zIGFyZSBhY3Jvc3MgYWxs
IGRldmljZQogdHlwZXMuCgogU3VwcG9ydGVkIGZvcm1hdHM6CgogKiBgVU5LTk9XTl9ERVZJ
Q0VfVFlQRWAKCiAqIGBERVNLVE9QYAoKICogYE1PQklMRWAKCiAqIEEgY3VzdG9taXplZCBz
dHJpbmcgc3RhcnRzIHdpdGggYE9USEVSX2AsIGUuZy4gYE9USEVSX0lQSE9ORWAuCgoNCgUE
AAIEBRIEgAECCAoNCgUEAAIEARIEgAEJFAoNCgUEAAIEAxIEgAEXGArtBAoEBAACBRIEkAEC
FRreBCBEZXRlcm1pbmVzIHdoaWNoIGRhdGFzZXQgdG8gdXNlIGZvciBmZXRjaGluZyBjb21w
bGV0aW9uLiAidXNlci1kYXRhIiB3aWxsCiB1c2UgdGhlIGRhdGFzZXQgaW1wb3J0ZWQgdGhy
b3VnaAogW0NvbXBsZXRpb25TZXJ2aWNlLkltcG9ydENvbXBsZXRpb25EYXRhXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLkNvbXBsZXRpb25TZXJ2aWNlLkltcG9ydENvbXBsZXRpb25EYXRh
XS4KIGBjbG91ZC1yZXRhaWxgIHdpbGwgdXNlIHRoZSBkYXRhc2V0IGdlbmVyYXRlZCBieSBD
bG91ZCBSZXRhaWwgYmFzZWQgb24gdXNlcgogZXZlbnRzLiBJZiBsZWZ0IGVtcHR5LCBjb21w
bGV0aW9ucyB3aWxsIGJlIGZldGNoZWQgZnJvbSB0aGUgYHVzZXItZGF0YWAKIGRhdGFzZXQu
CgogQ3VycmVudCBzdXBwb3J0ZWQgdmFsdWVzOgoKICogdXNlci1kYXRhCgogKiBjbG91ZC1y
ZXRhaWw6CiAgIFRoaXMgb3B0aW9uIHJlcXVpcmVzIGVuYWJsaW5nIGF1dG8tbGVhcm5pbmcg
ZnVuY3Rpb24gZmlyc3QuIFNlZQogICBbZ3VpZGVsaW5lc10oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL3JldGFpbC9kb2NzL2NvbXBsZXRpb24tb3ZlcnZpZXcjZ2VuZXJhdGVkLWNvbXBs
ZXRpb24tZGF0YXNldCkuCgoNCgUEAAIFBRIEkAECCAoNCgUEAAIFARIEkAEJEAoNCgUEAAIF
AxIEkAETFAqtAgoEBAACBhIEmAECHBqeAiBDb21wbGV0aW9uIG1heCBzdWdnZXN0aW9ucy4g
SWYgbGVmdCB1bnNldCBvciBzZXQgdG8gMCwgdGhlbiB3aWxsIGZhbGxiYWNrCiB0byB0aGUg
Y29uZmlndXJlZCB2YWx1ZQogW0NvbXBsZXRpb25Db25maWcubWF4X3N1Z2dlc3Rpb25zXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyLkNvbXBsZXRpb25Db25maWcubWF4X3N1Z2dlc3Rpb25z
XS4KCiBUaGUgbWF4aW11bSBhbGxvd2VkIG1heCBzdWdnZXN0aW9ucyBpcyAyMC4gSWYgaXQg
aXMgc2V0IGhpZ2hlciwgaXQgd2lsbCBiZQogY2FwcGVkIGJ5IDIwLgoKDQoFBAACBgUSBJgB
AgcKDQoFBAACBgESBJgBCBcKDQoFBAACBgMSBJgBGhsKmAEKBAQAAgcSBJ0BAigaiQEgSWYg
dHJ1ZSwgYXR0cmlidXRlIHN1Z2dlc3Rpb25zIGFyZSBlbmFibGVkIGFuZCBwcm92aWRlZCBp
biB0aGUgcmVzcG9uc2UuCgogVGhpcyBmaWVsZCBpcyBvbmx5IGF2YWlsYWJsZSBmb3IgdGhl
IGBjbG91ZC1yZXRhaWxgIGRhdGFzZXQuCgoNCgUEAAIHBRIEnQECBgoNCgUEAAIHARIEnQEH
IwoNCgUEAAIHAxIEnQEmJwquBQoEBAACCBIEqgECFRqfBSBUaGUgZW50aXR5IGZvciBjdXN0
b21lcnMgd2hvIHJ1biBtdWx0aXBsZSBlbnRpdGllcywgZG9tYWlucywgc2l0ZXMsIG9yCiBy
ZWdpb25zLCBmb3IgZXhhbXBsZSwgYEdvb2dsZSBVU2AsIGBHb29nbGUgQWRzYCwgYFdheW1v
YCwKIGBnb29nbGUuY29tYCwgYHlvdXR1YmUuY29tYCwgZXRjLgogSWYgdGhpcyBpcyBzZXQs
IGl0IG11c3QgYmUgYW4gZXhhY3QgbWF0Y2ggd2l0aAogW1VzZXJFdmVudC5lbnRpdHldW2dv
b2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckV2ZW50LmVudGl0eV0gdG8gZ2V0CiBwZXItZW50
aXR5IGF1dG9jb21wbGV0ZSByZXN1bHRzLiBUaGlzIGZpZWxkIHdpbGwgYmUgYXBwbGllZCB0
bwogYGNvbXBsZXRpb25fcmVzdWx0c2Agb25seS4gSXQgaGFzIG5vIGVmZmVjdCBvbiB0aGUg
YGF0dHJpYnV0ZV9yZXN1bHRzYC4KIEFsc28sIHRoaXMgZW50aXR5IHNob3VsZCBiZSBsaW1p
dGVkIHRvIDI1NiBjaGFyYWN0ZXJzLCBpZiB0b28gbG9uZywgaXQgd2lsbAogYmUgdHJ1bmNh
dGVkIHRvIDI1NiBjaGFyYWN0ZXJzIGluIGJvdGggZ2VuZXJhdGlvbiBhbmQgc2VydmluZyB0
aW1lLCBhbmQgbWF5CiBsZWFkIHRvIG1pcy1tYXRjaC4gVG8gZW5zdXJlIGl0IHdvcmtzLCBw
bGVhc2Ugc2V0IHRoZSBlbnRpdHkgd2l0aCBzdHJpbmcKIHdpdGhpbiAyNTYgY2hhcmFjdGVy
cy4KCg0KBQQAAggFEgSqAQIICg0KBQQAAggBEgSqAQkPCg0KBQQAAggDEgSqARIUCjMKAgQB
EgauAQD4AQEaJSBSZXNwb25zZSBvZiB0aGUgYXV0b2NvbXBsZXRlIHF1ZXJ5LgoKCwoDBAEB
EgSuAQgdCj4KBAQBAwASBrABAr4BAxouIFJlc291cmNlIHRoYXQgcmVwcmVzZW50cyBjb21w
bGV0aW9uIHJlc3VsdHMuCgoNCgUEAQMAARIEsAEKGgovCgYEAQMAAgASBLIBBBoaHyBUaGUg
c3VnZ2VzdGlvbiBmb3IgdGhlIHF1ZXJ5LgoKDwoHBAEDAAIABRIEsgEECgoPCgcEAQMAAgAB
EgSyAQsVCg8KBwQBAwACAAMSBLIBGBkK6gIKBgQBAwACARIEvQEEMBrZAiBDdXN0b20gYXR0
cmlidXRlcyBmb3IgdGhlIHN1Z2dlc3Rpb24gdGVybS4KCiAqIEZvciBgdXNlci1kYXRhYCwg
dGhlIGF0dHJpYnV0ZXMgYXJlIGFkZGl0aW9uYWwgY3VzdG9tIGF0dHJpYnV0ZXMKIGluZ2Vz
dGVkIHRocm91Z2ggQmlnUXVlcnkuCgogKiBGb3IgYGNsb3VkLXJldGFpbGAsIHRoZSBhdHRy
aWJ1dGVzIGFyZSBwcm9kdWN0IGF0dHJpYnV0ZXMgZ2VuZXJhdGVkCiBieSBDbG91ZCBSZXRh
aWwuIEl0IHJlcXVpcmVzCiBbVXNlckV2ZW50LnByb2R1Y3RfZGV0YWlsc11bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Vc2VyRXZlbnQucHJvZHVjdF9kZXRhaWxzXQogaXMgaW1wb3J0ZWQg
cHJvcGVybHkuCgoPCgcEAQMAAgEGEgS9AQQgCg8KBwQBAwACAQESBL0BISsKDwoHBAEDAAIB
AxIEvQEuLwo5CgQEAQMBEgbBAQLGAQMaKSBEZXByZWNhdGVkOiBSZWNlbnQgc2VhcmNoIG9m
IHRoaXMgdXNlci4KCg0KBQQBAwEBEgTBAQocCg0KBQQBAwEHEgTCAQQdCg4KBgQBAwEHAxIE
wgEEHQoqCgYEAQMBAgASBMUBBB0aGiBUaGUgcmVjZW50IHNlYXJjaCBxdWVyeS4KCg8KBwQB
AwECAAUSBMUBBAoKDwoHBAEDAQIAARIExQELGAoPCgcEAQMBAgADEgTFARscCj0KBAQBAwIS
BskBAswBAxotIFJlc291cmNlIHRoYXQgcmVwcmVzZW50cyBhdHRyaWJ1dGUgcmVzdWx0cy4K
Cg0KBQQBAwIBEgTJAQoZCjwKBgQBAwICABIEywEEJBosIFRoZSBsaXN0IG9mIHN1Z2dlc3Rp
b25zIGZvciB0aGUgYXR0cmlidXRlLgoKDwoHBAEDAgIABBIEywEEDAoPCgcEAQMCAgAFEgTL
AQ0TCg8KBwQBAwICAAESBMsBFB8KDwoHBAEDAgIAAxIEywEiIwp4CgQEAQIAEgTQAQIzGmog
UmVzdWx0cyBvZiB0aGUgbWF0Y2hpbmcgc3VnZ2VzdGlvbnMuIFRoZSByZXN1bHQgbGlzdCBp
cyBvcmRlcmVkIGFuZCB0aGUKIGZpcnN0IHJlc3VsdCBpcyB0b3Agc3VnZ2VzdGlvbi4KCg0K
BQQBAgAEEgTQAQIKCg0KBQQBAgAGEgTQAQsbCg0KBQQBAgABEgTQARwuCg0KBQQBAgADEgTQ
ATEyCpECCgQEAQIBEgTWAQIfGoICIEEgdW5pcXVlIGNvbXBsZXRlIHRva2VuLiBUaGlzIHNo
b3VsZCBiZSBpbmNsdWRlZCBpbiB0aGUKIFtVc2VyRXZlbnQuY29tcGxldGlvbl9kZXRhaWxd
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXNlckV2ZW50LmNvbXBsZXRpb25fZGV0YWlsXQog
Zm9yIHNlYXJjaCBldmVudHMgcmVzdWx0aW5nIGZyb20gdGhpcyBjb21wbGV0aW9uLCB3aGlj
aCBlbmFibGVzIGFjY3VyYXRlCiBhdHRyaWJ1dGlvbiBvZiBjb21wbGV0ZSBtb2RlbCBwZXJm
b3JtYW5jZS4KCg0KBQQBAgEFEgTWAQIICg0KBQQBAgEBEgTWAQkaCg0KBQQBAgEDEgTWAR0e
CqMGCgQEAQICEgTtAQJMGpQGIERlcHJlY2F0ZWQuIE1hdGNoZWQgcmVjZW50IHNlYXJjaGVz
IG9mIHRoaXMgdXNlci4gVGhlIG1heGltdW0gbnVtYmVyIG9mCiByZWNlbnQgc2VhcmNoZXMg
aXMgMTAuIFRoaXMgZmllbGQgaXMgYSByZXN0cmljdGVkIGZlYXR1cmUuIElmIHlvdSB3YW50
IHRvCiBlbmFibGUgaXQsIGNvbnRhY3QgUmV0YWlsIFNlYXJjaCBzdXBwb3J0LgoKIFRoaXMg
ZmVhdHVyZSBpcyBvbmx5IGF2YWlsYWJsZSB3aGVuCiBbQ29tcGxldGVRdWVyeVJlcXVlc3Qu
dmlzaXRvcl9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0ZVF1ZXJ5UmVxdWVz
dC52aXNpdG9yX2lkXQogZmllbGQgaXMgc2V0IGFuZCBbVXNlckV2ZW50XVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyLlVzZXJFdmVudF0gaXMgaW1wb3J0ZWQuCiBUaGUgcmVjZW50IHNlYXJj
aGVzIHNhdGlzZnkgdGhlIGZvbGxvdyBydWxlczoKCiAgKiBUaGV5IGFyZSBvcmRlcmVkIGZy
b20gbGF0ZXN0IHRvIG9sZGVzdC4KCiAgKiBUaGV5IGFyZSBtYXRjaGVkIHdpdGgKICBbQ29t
cGxldGVRdWVyeVJlcXVlc3QucXVlcnldW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29tcGxl
dGVRdWVyeVJlcXVlc3QucXVlcnldCiAgY2FzZSBpbnNlbnNpdGl2ZWx5LgoKICAqIFRoZXkg
YXJlIHRyYW5zZm9ybWVkIHRvIGxvd2VyIGNhc2UuCgogICogVGhleSBhcmUgVVRGLTggc2Fm
ZS4KCiBSZWNlbnQgc2VhcmNoZXMgYXJlIGRlZHVwbGljYXRlZC4gTW9yZSByZWNlbnQgc2Vh
cmNoZXMgd2lsbCBiZSByZXNlcnZlZAogd2hlbiBkdXBsaWNhdGlvbiBoYXBwZW5zLgoKDQoF
BAECAgQSBO0BAgoKDQoFBAECAgYSBO0BCx0KDQoFBAECAgESBO0BHjMKDQoFBAECAgMSBO0B
NjcKDQoFBAECAggSBO0BOEsKDgoGBAECAggDEgTtATlKCqoBCgQEAQIDEgT3AQI1GpsBIEEg
bWFwIG9mIG1hdGNoZWQgYXR0cmlidXRlIHN1Z2dlc3Rpb25zLiBUaGlzIGZpZWxkIGlzIG9u
bHkgYXZhaWxhYmxlIGZvcgogYGNsb3VkLXJldGFpbGAgZGF0YXNldC4KCiBDdXJyZW50IHN1
cHBvcnRlZCBrZXlzOgoKICogYGJyYW5kc2AKCiAqIGBjYXRlZ29yaWVzYAoKDQoFBAECAwYS
BPcBAh4KDQoFBAECAwESBPcBHzAKDQoFBAECAwMSBPcBMzRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest ===
    # Fields for CompleteQueryRequest
    # Field: catalog Type: 9 ()
    # Field: query Type: 9 ()
    # Field: visitor_id Type: 9 ()
    # Field: language_codes Type: 9 ()
    # Field: device_type Type: 9 ()
    # Field: dataset Type: 9 ()
    # Field: max_suggestions Type: 5 ()
    # Field: enable_attribute_suggestions Type: 8 ()
    # Field: entity Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse ===
    # Fields for CompleteQueryResponse
    # Field: completion_results Type: 11 (.google.cloud.retail.v2.CompleteQueryResponse.CompletionResult)
    # Field: attribution_token Type: 9 ()
    # Field: recent_search_results Type: 11 (.google.cloud.retail.v2.CompleteQueryResponse.RecentSearchResult)
    # Field: attribute_results Type: 11 (.google.cloud.retail.v2.CompleteQueryResponse.AttributeResultsEntry)

# === Service Client: Google::Cloud::Retail::V2::CompletionService::CompletionServiceClient ===
package Google::Cloud::Retail::V2::CompletionService::CompletionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::CompletionService::CompletionServiceClient

Client stub representing the remote C<CompletionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub complete_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CompletionService',
        method         => 'CompleteQuery',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse',
    });
}

sub import_completion_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CompletionService',
        method         => 'ImportCompletionData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::CompletionService - Compiled Protocol Buffers messages for google/cloud/retail/v2/completion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::CompletionService;

    my $msg = Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest->new({
        catalog => $catalog,
        query => $query,
        visitor_id => $visitor_id,
        language_codes => $language_codes,
    });

    # Read or update a field
    my $val = $msg->catalog();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/completion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest

Autocomplete parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Catalog for which the completion is performed.

Full resource name of catalog, such as
`projects/*/locations/global/catalogs/default_catalog`.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. The query used to generate suggestions.

The maximum number of allowed characters is 255.

=item * C<< $msg->visitor_id() >> / C<< $msg->visitor_id($value) >>

Type: C<String>

Recommended field. A unique identifier for tracking visitors. For example,
this could be implemented with an HTTP cookie, which should be able to
uniquely identify a visitor on a single device. This unique identifier
should not change if the visitor logs in or out of the website.

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->language_codes() >> / C<< $msg->language_codes($value) >>

Type: C<String>

Note that this field applies for `user-data` dataset only. For requests
with `cloud-retail` dataset, setting this field has no effect.

The language filters applied to the output suggestions. If set, it should
contain the language of the query. If not set, suggestions are returned
without considering language restrictions. This is the BCP-47 language
code, such as "en-US" or "sr-Latn". For more information, see [Tags for
Identifying Languages](https://tools.ietf.org/html/bcp47). The maximum
number of language codes is 3.

=item * C<< $msg->device_type() >> / C<< $msg->device_type($value) >>

Type: C<String>

The device type context for completion suggestions. We recommend that you
leave this field empty.

It can apply different suggestions on different device types, e.g.
`DESKTOP`, `MOBILE`. If it is empty, the suggestions are across all device
types.

Supported formats:

* `UNKNOWN_DEVICE_TYPE`

* `DESKTOP`

* `MOBILE`

* A customized string starts with `OTHER_`, e.g. `OTHER_IPHONE`.

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Determines which dataset to use for fetching completion. "user-data" will
use the dataset imported through
[CompletionService.ImportCompletionData][google.cloud.retail.v2.CompletionService.ImportCompletionData].
`cloud-retail` will use the dataset generated by Cloud Retail based on user
events. If left empty, completions will be fetched from the `user-data`
dataset.

Current supported values:

* user-data

* cloud-retail:
  This option requires enabling auto-learning function first. See
  [guidelines](https://cloud.google.com/retail/docs/completion-overview#generated-completion-dataset).

=item * C<< $msg->max_suggestions() >> / C<< $msg->max_suggestions($value) >>

Type: C<Int32>

Completion max suggestions. If left unset or set to 0, then will fallback
to the configured value
[CompletionConfig.max_suggestions][google.cloud.retail.v2.CompletionConfig.max_suggestions].

The maximum allowed max suggestions is 20. If it is set higher, it will be
capped by 20.

=item * C<< $msg->enable_attribute_suggestions() >> / C<< $msg->enable_attribute_suggestions($value) >>

Type: C<Bool>

If true, attribute suggestions are enabled and provided in the response.

This field is only available for the `cloud-retail` dataset.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<String>

The entity for customers who run multiple entities, domains, sites, or
regions, for example, `Google US`, `Google Ads`, `Waymo`,
`google.com`, `youtube.com`, etc.
If this is set, it must be an exact match with
[UserEvent.entity][google.cloud.retail.v2.UserEvent.entity] to get
per-entity autocomplete results. This field will be applied to
`completion_results` only. It has no effect on the `attribute_results`.
Also, this entity should be limited to 256 characters, if too long, it will
be truncated to 256 characters in both generation and serving time, and may
lead to mis-match. To ensure it works, please set the entity with string
within 256 characters.

=back

=head2 Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse

Response of the autocomplete query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_results() >> / C<< $msg->completion_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult>)

Results of the matching suggestions. The result list is ordered and the
first result is top suggestion.

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique complete token. This should be included in the
[UserEvent.completion_detail][google.cloud.retail.v2.UserEvent.completion_detail]
for search events resulting from this completion, which enables accurate
attribution of complete model performance.

=item * C<< $msg->recent_search_results() >> / C<< $msg->recent_search_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::RecentSearchResult>)

Deprecated. Matched recent searches of this user. The maximum number of
recent searches is 10. This field is a restricted feature. If you want to
enable it, contact Retail Search support.

This feature is only available when
[CompleteQueryRequest.visitor_id][google.cloud.retail.v2.CompleteQueryRequest.visitor_id]
field is set and [UserEvent][google.cloud.retail.v2.UserEvent] is imported.
The recent searches satisfy the follow rules:

 * They are ordered from latest to oldest.

 * They are matched with
 [CompleteQueryRequest.query][google.cloud.retail.v2.CompleteQueryRequest.query]
 case insensitively.

 * They are transformed to lower case.

 * They are UTF-8 safe.

Recent searches are deduplicated. More recent searches will be reserved
when duplication happens.

=item * C<< $msg->attribute_results() >> / C<< $msg->attribute_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResultsEntry>)

A map of matched attribute suggestions. This field is only available for
`cloud-retail` dataset.

Current supported keys:

* `brands`

* `categories`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::CompletionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
