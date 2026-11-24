package Google::Cloud::Retail::V2beta::UserEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Retail::V2beta::Common };
    eval { require Google::Cloud::Retail::V2beta::Product };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS91c2VyX2V2ZW50LnByb3RvEhpnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxon
Z29vZ2xlL2Nsb3VkL3JldGFpbC92MmJldGEvY29tbW9uLnByb3RvGihnb29nbGUvY2xvdWQv
cmV0YWlsL3YyYmV0YS9wcm9kdWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvGh5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8iuQgKCVVzZXJFdmVudBIi
CgpldmVudF90eXBlGAEgASgJQgPgQQJSCWV2ZW50VHlwZRIiCgp2aXNpdG9yX2lkGAIgASgJ
QgPgQQJSCXZpc2l0b3JJZBIdCgpzZXNzaW9uX2lkGBUgASgJUglzZXNzaW9uSWQSOQoKZXZl
bnRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWV2ZW50VGltZRIl
Cg5leHBlcmltZW50X2lkcxgEIAMoCVINZXhwZXJpbWVudElkcxIrChFhdHRyaWJ1dGlvbl90
b2tlbhgFIAEoCVIQYXR0cmlidXRpb25Ub2tlbhJSCg9wcm9kdWN0X2RldGFpbHMYBiADKAsy
KS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Qcm9kdWN0RGV0YWlsUg5wcm9kdWN0RGV0
YWlscxJZChFjb21wbGV0aW9uX2RldGFpbBgWIAEoCzIsLmdvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLkNvbXBsZXRpb25EZXRhaWxSEGNvbXBsZXRpb25EZXRhaWwSVQoKYXR0cmlidXRl
cxgHIAMoCzI1Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVzZXJFdmVudC5BdHRyaWJ1
dGVzRW50cnlSCmF0dHJpYnV0ZXMSFwoHY2FydF9pZBgIIAEoCVIGY2FydElkEmIKFHB1cmNo
YXNlX3RyYW5zYWN0aW9uGAkgASgLMi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHVy
Y2hhc2VUcmFuc2FjdGlvblITcHVyY2hhc2VUcmFuc2FjdGlvbhIhCgxzZWFyY2hfcXVlcnkY
CiABKAlSC3NlYXJjaFF1ZXJ5EhYKBmZpbHRlchgQIAEoCVIGZmlsdGVyEhkKCG9yZGVyX2J5
GBEgASgJUgdvcmRlckJ5EhYKBm9mZnNldBgSIAEoBVIGb2Zmc2V0EicKD3BhZ2VfY2F0ZWdv
cmllcxgLIAMoCVIOcGFnZUNhdGVnb3JpZXMSQQoJdXNlcl9pbmZvGAwgASgLMiQuZ29vZ2xl
LmNsb3VkLnJldGFpbC52MmJldGEuVXNlckluZm9SCHVzZXJJbmZvEhAKA3VyaRgNIAEoCVID
dXJpEiEKDHJlZmVycmVyX3VyaRgOIAEoCVILcmVmZXJyZXJVcmkSIAoMcGFnZV92aWV3X2lk
GA8gASgJUgpwYWdlVmlld0lkEhYKBmVudGl0eRgXIAEoCVIGZW50aXR5GmoKD0F0dHJpYnV0
ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJBCgV2YWx1ZRgCIAEoCzIrLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJiZXRhLkN1c3RvbUF0dHJpYnV0ZVIFdmFsdWU6AjgBIowBCg1Qcm9kdWN0
RGV0YWlsEkIKB3Byb2R1Y3QYASABKAsyIy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Q
cm9kdWN0QgPgQQJSB3Byb2R1Y3QSNwoIcXVhbnRpdHkYAiABKAsyGy5nb29nbGUucHJvdG9i
dWYuSW50MzJWYWx1ZVIIcXVhbnRpdHkisgEKEENvbXBsZXRpb25EZXRhaWwSQAocY29tcGxl
dGlvbl9hdHRyaWJ1dGlvbl90b2tlbhgBIAEoCVIaY29tcGxldGlvbkF0dHJpYnV0aW9uVG9r
ZW4SLwoTc2VsZWN0ZWRfc3VnZ2VzdGlvbhgCIAEoCVISc2VsZWN0ZWRTdWdnZXN0aW9uEisK
EXNlbGVjdGVkX3Bvc2l0aW9uGAMgASgFUhBzZWxlY3RlZFBvc2l0aW9uIpQBChNQdXJjaGFz
ZVRyYW5zYWN0aW9uEg4KAmlkGAEgASgJUgJpZBIdCgdyZXZlbnVlGAIgASgCQgPgQQJSB3Jl
dmVudWUSEAoDdGF4GAMgASgCUgN0YXgSEgoEY29zdBgEIAEoAlIEY29zdBIoCg1jdXJyZW5j
eV9jb2RlGAUgASgJQgPgQQJSDGN1cnJlbmN5Q29kZULNAQoeY29tLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjJiZXRhQg5Vc2VyRXZlbnRQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL3Jl
dGFpbC9hcGl2MmJldGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhpHb29nbGUuQ2xv
dWQuUmV0YWlsLlYyQmV0YcoCGkdvb2dsZVxDbG91ZFxSZXRhaWxcVjJiZXRh6gIdR29vZ2xl
OjpDbG91ZDo6UmV0YWlsOjpWMmJldGFKiXQKBxIFDgDeAgEKvAQKAQwSAw4AEjKxBCBDb3B5
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
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAxCgkKAgMC
EgMUADIKCQoCAwMSAxUAKQoJCgIDBBIDFgAoCggKAQgSAxgANwoJCgIIJRIDGAA3CggKAQgS
AxkATQoJCgIICxIDGQBNCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALwoJCgIICBID
GwAvCggKAQgSAxwANwoJCgIIARIDHAA3CggKAQgSAx0AJAoJCgIIJBIDHQAkCggKAQgSAx4A
NwoJCgIIKRIDHgA3CggKAQgSAx8ANgoJCgIILRIDHwA2CooBCgIEABIFIwCUAgEafSBVc2Vy
RXZlbnQgY2FwdHVyZXMgYWxsIG1ldGFkYXRhIGluZm9ybWF0aW9uIFJldGFpbCBBUEkgbmVl
ZHMgdG8ga25vdyBhYm91dAogaG93IGVuZCB1c2VycyBpbnRlcmFjdCB3aXRoIGN1c3RvbWVy
cycgd2Vic2l0ZS4KCgoKAwQAARIDIwgRCuADCgQEAAIAEgMvAkEa0gMgUmVxdWlyZWQuIFVz
ZXIgZXZlbnQgdHlwZS4gQWxsb3dlZCB2YWx1ZXMgYXJlOgoKICogYGFkZC10by1jYXJ0YDog
UHJvZHVjdHMgYmVpbmcgYWRkZWQgdG8gY2FydC4KICogYHJlbW92ZS1mcm9tLWNhcnRgOiBQ
cm9kdWN0cyBiZWluZyByZW1vdmVkIGZyb20gY2FydC4KICogYGNhdGVnb3J5LXBhZ2Utdmll
d2A6IFNwZWNpYWwgcGFnZXMgc3VjaCBhcyBzYWxlIG9yIHByb21vdGlvbiBwYWdlcwogICB2
aWV3ZWQuCiAqIGBkZXRhaWwtcGFnZS12aWV3YDogUHJvZHVjdHMgZGV0YWlsIHBhZ2Ugdmll
d2VkLgogKiBgaG9tZS1wYWdlLXZpZXdgOiBIb21lcGFnZSB2aWV3ZWQuCiAqIGBwdXJjaGFz
ZS1jb21wbGV0ZWA6IFVzZXIgZmluaXNoaW5nIGEgcHVyY2hhc2UuCiAqIGBzZWFyY2hgOiBQ
cm9kdWN0IHNlYXJjaC4KICogYHNob3BwaW5nLWNhcnQtcGFnZS12aWV3YDogVXNlciB2aWV3
aW5nIGEgc2hvcHBpbmcgY2FydC4KCgwKBQQAAgAFEgMvAggKDAoFBAACAAESAy8JEwoMCgUE
AAIAAxIDLxYXCgwKBQQAAgAIEgMvGEAKDwoIBAACAAicCAASAy8ZPwqdBgoEBAACARIDQgJB
Go8GIFJlcXVpcmVkLiBBIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0cmFja2luZyB2aXNpdG9y
cy4KCiBGb3IgZXhhbXBsZSwgdGhpcyBjb3VsZCBiZSBpbXBsZW1lbnRlZCB3aXRoIGFuIEhU
VFAgY29va2llLCB3aGljaCBzaG91bGQgYmUKIGFibGUgdG8gdW5pcXVlbHkgaWRlbnRpZnkg
YSB2aXNpdG9yIG9uIGEgc2luZ2xlIGRldmljZS4gVGhpcyB1bmlxdWUKIGlkZW50aWZpZXIg
c2hvdWxkIG5vdCBjaGFuZ2UgaWYgdGhlIHZpc2l0b3IgbG9nIGluL291dCBvZiB0aGUgd2Vi
c2l0ZS4KCiBEb24ndCBzZXQgdGhlIGZpZWxkIHRvIHRoZSBzYW1lIGZpeGVkIElEIGZvciBk
aWZmZXJlbnQgdXNlcnMuIFRoaXMgbWl4ZXMKIHRoZSBldmVudCBoaXN0b3J5IG9mIHRob3Nl
IHVzZXJzIHRvZ2V0aGVyLCB3aGljaCByZXN1bHRzIGluIGRlZ3JhZGVkIG1vZGVsCiBxdWFs
aXR5LgoKIFRoZSBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBh
IGxlbmd0aCBsaW1pdCBvZiAxMjgKIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gSU5WQUxJ
RF9BUkdVTUVOVCBlcnJvciBpcyByZXR1cm5lZC4KCiBUaGUgZmllbGQgc2hvdWxkIG5vdCBj
b250YWluIFBJSSBvciB1c2VyLWRhdGEuIFdlIHJlY29tbWVuZCB0byB1c2UgR29vZ2xlCiBB
bmFseXRpY3MgW0NsaWVudAogSURdKGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL2Fu
YWx5dGljcy9kZXZndWlkZXMvY29sbGVjdGlvbi9hbmFseXRpY3Nqcy9maWVsZC1yZWZlcmVu
Y2UjY2xpZW50SWQpCiBmb3IgdGhpcyBmaWVsZC4KCgwKBQQAAgEFEgNCAggKDAoFBAACAQES
A0IJEwoMCgUEAAIBAxIDQhYXCgwKBQQAAgEIEgNCGEAKDwoIBAACAQicCAASA0IZPwqJAwoE
BAACAhIDTAIZGvsCIEEgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRyYWNraW5nIGEgdmlzaXRv
ciBzZXNzaW9uIHdpdGggYSBsZW5ndGggbGltaXQgb2YKIDEyOCBieXRlcy4gQSBzZXNzaW9u
IGlzIGFuIGFnZ3JlZ2F0aW9uIG9mIGFuIGVuZCB1c2VyIGJlaGF2aW9yIGluIGEgdGltZQog
c3Bhbi4KCiBBIGdlbmVyYWwgZ3VpZGVsaW5lIHRvIHBvcHVsYXRlIHRoZSBzZXNpb25faWQ6
CiAxLiBJZiB1c2VyIGhhcyBubyBhY3Rpdml0eSBmb3IgMzAgbWluLCBhIG5ldyBzZXNzaW9u
X2lkIHNob3VsZCBiZSBhc3NpZ25lZC4KIDIuIFRoZSBzZXNzaW9uX2lkIHNob3VsZCBiZSB1
bmlxdWUgYWNyb3NzIHVzZXJzLCBzdWdnZXN0IHVzZSB1dWlkIG9yIGFkZAogdmlzaXRvcl9p
ZCBhcyBwcmVmaXguCgoMCgUEAAICBRIDTAIICgwKBQQAAgIBEgNMCRMKDAoFBAACAgMSA0wW
GAq4AQoEBAACAxIDUQIrGqoBIE9ubHkgcmVxdWlyZWQgZm9yCiBbVXNlckV2ZW50U2Vydmlj
ZS5JbXBvcnRVc2VyRXZlbnRzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Vc2VyRXZl
bnRTZXJ2aWNlLkltcG9ydFVzZXJFdmVudHNdCiBtZXRob2QuIFRpbWVzdGFtcCBvZiB3aGVu
IHRoZSB1c2VyIGV2ZW50IGhhcHBlbmVkLgoKDAoFBAACAwYSA1ECGwoMCgUEAAIDARIDURwm
CgwKBQQAAgMDEgNRKSoKhgIKBAQAAgQSA1cCJRr4ASBBIGxpc3Qgb2YgaWRlbnRpZmllcnMg
Zm9yIHRoZSBpbmRlcGVuZGVudCBleHBlcmltZW50IGdyb3VwcyB0aGlzIHVzZXIgZXZlbnQK
IGJlbG9uZ3MgdG8uIFRoaXMgaXMgdXNlZCB0byBkaXN0aW5ndWlzaCBiZXR3ZWVuIHVzZXIg
ZXZlbnRzIGFzc29jaWF0ZWQgd2l0aAogZGlmZmVyZW50IGV4cGVyaW1lbnQgc2V0dXBzIChl
LmcuIHVzaW5nIFJldGFpbCBBUEksIHVzaW5nIGRpZmZlcmVudAogcmVjb21tZW5kYXRpb24g
bW9kZWxzKS4KCgwKBQQAAgQEEgNXAgoKDAoFBAACBAUSA1cLEQoMCgUEAAIEARIDVxIgCgwK
BQQAAgQDEgNXIyQK8gkKBAQAAgUSA3ACHxrkCSBIaWdobHkgcmVjb21tZW5kZWQgZm9yIHVz
ZXIgZXZlbnRzIHRoYXQgYXJlIHRoZSByZXN1bHQgb2YKIFtQcmVkaWN0aW9uU2VydmljZS5Q
cmVkaWN0XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5QcmVkaWN0aW9uU2VydmljZS5Q
cmVkaWN0XS4KIFRoaXMgZmllbGQgZW5hYmxlcyBhY2N1cmF0ZSBhdHRyaWJ1dGlvbiBvZiBy
ZWNvbW1lbmRhdGlvbiBtb2RlbAogcGVyZm9ybWFuY2UuCgogVGhlIHZhbHVlIG11c3QgYmUg
YSB2YWxpZAogW1ByZWRpY3RSZXNwb25zZS5hdHRyaWJ1dGlvbl90b2tlbl1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmJldGEuUHJlZGljdFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2VuXQog
Zm9yIHVzZXIgZXZlbnRzIHRoYXQgYXJlIHRoZSByZXN1bHQgb2YKIFtQcmVkaWN0aW9uU2Vy
dmljZS5QcmVkaWN0XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5QcmVkaWN0aW9uU2Vy
dmljZS5QcmVkaWN0XS4KIFRoZSB2YWx1ZSBtdXN0IGJlIGEgdmFsaWQKIFtTZWFyY2hSZXNw
b25zZS5hdHRyaWJ1dGlvbl90b2tlbl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2Vh
cmNoUmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dCiBmb3IgdXNlciBldmVudHMgdGhhdCBh
cmUgdGhlIHJlc3VsdCBvZgogW1NlYXJjaFNlcnZpY2UuU2VhcmNoXVtnb29nbGUuY2xvdWQu
cmV0YWlsLnYyYmV0YS5TZWFyY2hTZXJ2aWNlLlNlYXJjaF0uCgogVGhpcyB0b2tlbiBlbmFi
bGVzIHVzIHRvIGFjY3VyYXRlbHkgYXR0cmlidXRlIHBhZ2UgdmlldyBvciBwdXJjaGFzZSBi
YWNrIHRvCiB0aGUgZXZlbnQgYW5kIHRoZSBwYXJ0aWN1bGFyIHByZWRpY3QgcmVzcG9uc2Ug
Y29udGFpbmluZyB0aGlzCiBjbGlja2VkL3B1cmNoYXNlZCBwcm9kdWN0LiBJZiB1c2VyIGNs
aWNrcyBvbiBwcm9kdWN0IEsgaW4gdGhlCiByZWNvbW1lbmRhdGlvbiByZXN1bHRzLCBwYXNz
CiBbUHJlZGljdFJlc3BvbnNlLmF0dHJpYnV0aW9uX3Rva2VuXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyYmV0YS5QcmVkaWN0UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dCiBhcyBhIFVS
TCBwYXJhbWV0ZXIgdG8gcHJvZHVjdCBLJ3MgcGFnZS4gV2hlbiByZWNvcmRpbmcgZXZlbnRz
IG9uIHByb2R1Y3QKIEsncyBwYWdlLCBsb2cgdGhlCiBbUHJlZGljdFJlc3BvbnNlLmF0dHJp
YnV0aW9uX3Rva2VuXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5QcmVkaWN0UmVzcG9u
c2UuYXR0cmlidXRpb25fdG9rZW5dCiB0byB0aGlzIGZpZWxkLgoKDAoFBAACBQUSA3ACCAoM
CgUEAAIFARIDcAkaCgwKBQQAAgUDEgNwHR4KjgUKBAQAAgYSBIEBAi0a/wQgVGhlIG1haW4g
cHJvZHVjdCBkZXRhaWxzIHJlbGF0ZWQgdG8gdGhlIGV2ZW50LgoKIFRoaXMgZmllbGQgaXMg
b3B0aW9uYWwgZXhjZXB0IGZvciB0aGUgZm9sbG93aW5nIGV2ZW50IHR5cGVzOgoKICogYGFk
ZC10by1jYXJ0YAogKiBgZGV0YWlsLXBhZ2Utdmlld2AKICogYHB1cmNoYXNlLWNvbXBsZXRl
YAoKIEluIGEgYHNlYXJjaGAgZXZlbnQsIHRoaXMgZmllbGQgcmVwcmVzZW50cyB0aGUgcHJv
ZHVjdHMgcmV0dXJuZWQgdG8gdGhlIGVuZAogdXNlciBvbiB0aGUgY3VycmVudCBwYWdlICh0
aGUgZW5kIHVzZXIgbWF5IGhhdmUgbm90IGZpbmlzaGVkIGJyb3dzaW5nIHRoZQogd2hvbGUg
cGFnZSB5ZXQpLiBXaGVuIGEgbmV3IHBhZ2UgaXMgcmV0dXJuZWQgdG8gdGhlIGVuZCB1c2Vy
LCBhZnRlcgogcGFnaW5hdGlvbi9maWx0ZXJpbmcvb3JkZXJpbmcgZXZlbiBmb3IgdGhlIHNh
bWUgcXVlcnksIGEgbmV3IGBzZWFyY2hgIGV2ZW50CiB3aXRoIGRpZmZlcmVudAogW3Byb2R1
Y3RfZGV0YWlsc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuVXNlckV2ZW50LnByb2R1
Y3RfZGV0YWlsc10gaXMKIGRlc2lyZWQuIFRoZSBlbmQgdXNlciBtYXkgaGF2ZSBub3QgZmlu
aXNoZWQgYnJvd3NpbmcgdGhlIHdob2xlIHBhZ2UgeWV0LgoKDQoFBAACBgQSBIEBAgoKDQoF
BAACBgYSBIEBCxgKDQoFBAACBgESBIEBGSgKDQoFBAACBgMSBIEBKywKyQEKBAQAAgcSBIcB
AioaugEgVGhlIG1haW4gYXV0by1jb21wbGV0aW9uIGRldGFpbHMgcmVsYXRlZCB0byB0aGUg
ZXZlbnQuCgogVGhpcyBmaWVsZCBzaG91bGQgYmUgc2V0IGZvciBgc2VhcmNoYCBldmVudCB3
aGVuIGF1dG9jb21wbGV0ZSBmdW5jdGlvbiBpcwogZW5hYmxlZCBhbmQgdGhlIHVzZXIgY2xp
Y2tzIGEgc3VnZ2VzdGlvbiBmb3Igc2VhcmNoLgoKDQoFBAACBwYSBIcBAhIKDQoFBAACBwES
BIcBEyQKDQoFBAACBwMSBIcBJykK+ggKBAQAAggSBKABAi4a6wggRXh0cmEgdXNlciBldmVu
dCBmZWF0dXJlcyB0byBpbmNsdWRlIGluIHRoZSByZWNvbW1lbmRhdGlvbiBtb2RlbC4KCiBJ
ZiB5b3UgcHJvdmlkZSBjdXN0b20gYXR0cmlidXRlcyBmb3IgaW5nZXN0ZWQgdXNlciBldmVu
dHMsIGFsc28gaW5jbHVkZQogdGhlbSBpbiB0aGUgdXNlciBldmVudHMgdGhhdCB5b3UgYXNz
b2NpYXRlIHdpdGggcHJlZGljdGlvbiByZXF1ZXN0cy4gQ3VzdG9tCiBhdHRyaWJ1dGUgZm9y
bWF0dGluZyBtdXN0IGJlIGNvbnNpc3RlbnQgYmV0d2VlbiBpbXBvcnRlZCBldmVudHMgYW5k
IGV2ZW50cwogcHJvdmlkZWQgd2l0aCBwcmVkaWN0aW9uIHJlcXVlc3RzLiBUaGlzIGxldHMg
dGhlIFJldGFpbCBBUEkgdXNlCiB0aG9zZSBjdXN0b20gYXR0cmlidXRlcyB3aGVuIHRyYWlu
aW5nIG1vZGVscyBhbmQgc2VydmluZyBwcmVkaWN0aW9ucywgd2hpY2gKIGhlbHBzIGltcHJv
dmUgcmVjb21tZW5kYXRpb24gcXVhbGl0eS4KCiBUaGlzIGZpZWxkIG5lZWRzIHRvIHBhc3Mg
YWxsIGJlbG93IGNyaXRlcmlhLCBvdGhlcndpc2UgYW4gSU5WQUxJRF9BUkdVTUVOVAogZXJy
b3IgaXMgcmV0dXJuZWQ6CgogKiBUaGUga2V5IG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0
cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDUsMDAwCiAgIGNoYXJhY3RlcnMuCiAqIEZv
ciB0ZXh0IGF0dHJpYnV0ZXMsIGF0IG1vc3QgNDAwIHZhbHVlcyBhcmUgYWxsb3dlZC4gRW1w
dHkgdmFsdWVzIGFyZSBub3QKICAgYWxsb3dlZC4gRWFjaCB2YWx1ZSBtdXN0IGJlIGEgVVRG
LTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZgogICAyNTYgY2hhcmFj
dGVycy4KICogRm9yIG51bWJlciBhdHRyaWJ1dGVzLCBhdCBtb3N0IDQwMCB2YWx1ZXMgYXJl
IGFsbG93ZWQuCgogRm9yIHByb2R1Y3QgcmVjb21tZW5kYXRpb25zLCBhbiBleGFtcGxlIG9m
IGV4dHJhIHVzZXIgaW5mb3JtYXRpb24gaXMKIHRyYWZmaWNfY2hhbm5lbCwgd2hpY2ggaXMg
aG93IGEgdXNlciBhcnJpdmVzIGF0IHRoZSBzaXRlLiBVc2VycyBjYW4gYXJyaXZlCiBhdCB0
aGUgc2l0ZSBieSBjb21pbmcgdG8gdGhlIHNpdGUgZGlyZWN0bHksIGNvbWluZyB0aHJvdWdo
IEdvb2dsZQogc2VhcmNoLCBvciBpbiBvdGhlciB3YXlzLgoKDQoFBAACCAYSBKABAh4KDQoF
BAACCAESBKABHykKDQoFBAACCAMSBKABLC0KgAIKBAQAAgkSBKcBAhUa8QEgVGhlIElEIG9y
IG5hbWUgb2YgdGhlIGFzc29jaWF0ZWQgc2hvcHBpbmcgY2FydC4gVGhpcyBJRCBpcyB1c2Vk
CiB0byBhc3NvY2lhdGUgbXVsdGlwbGUgaXRlbXMgYWRkZWQgb3IgcHJlc2VudCBpbiB0aGUg
Y2FydCBiZWZvcmUgcHVyY2hhc2UuCgogVGhpcyBjYW4gb25seSBiZSBzZXQgZm9yIGBhZGQt
dG8tY2FydGAsIGBwdXJjaGFzZS1jb21wbGV0ZWAsIG9yCiBgc2hvcHBpbmctY2FydC1wYWdl
LXZpZXdgIGV2ZW50cy4KCg0KBQQAAgkFEgSnAQIICg0KBQQAAgkBEgSnAQkQCg0KBQQAAgkD
EgSnARMUCtUBCgQEAAIKEgStAQIvGsYBIEEgdHJhbnNhY3Rpb24gcmVwcmVzZW50cyB0aGUg
ZW50aXJlIHB1cmNoYXNlIHRyYW5zYWN0aW9uLgoKIFJlcXVpcmVkIGZvciBgcHVyY2hhc2Ut
Y29tcGxldGVgIGV2ZW50cy4gT3RoZXIgZXZlbnQgdHlwZXMgc2hvdWxkIG5vdCBzZXQKIHRo
aXMgZmllbGQuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1
cm5lZC4KCg0KBQQAAgoGEgStAQIVCg0KBQQAAgoBEgStARYqCg0KBQQAAgoDEgStAS0uCrAE
CgQEAAILEgS8AQIbGqEEIFRoZSB1c2VyJ3Mgc2VhcmNoIHF1ZXJ5LgoKIFNlZSBbU2VhcmNo
UmVxdWVzdC5xdWVyeV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VhcmNoUmVxdWVz
dC5xdWVyeV0KIGZvciBkZWZpbml0aW9uLgoKIFRoZSB2YWx1ZSBtdXN0IGJlIGEgVVRGLTgg
ZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiA1LDAwMAogY2hhcmFjdGVy
cy4gT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoK
IEF0IGxlYXN0IG9uZSBvZgogW3NlYXJjaF9xdWVyeV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuVXNlckV2ZW50LnNlYXJjaF9xdWVyeV0gb3IKIFtwYWdlX2NhdGVnb3JpZXNdW2dv
b2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVzZXJFdmVudC5wYWdlX2NhdGVnb3JpZXNdIGlz
CiByZXF1aXJlZCBmb3IgYHNlYXJjaGAgZXZlbnRzLiBPdGhlciBldmVudCB0eXBlcyBzaG91
bGQgbm90IHNldCB0aGlzIGZpZWxkLgogT3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5U
IGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACCwUSBLwBAggKDQoFBAACCwESBLwBCRUKDQoF
BAACCwMSBLwBGBoKjAMKBAQAAgwSBMYBAhUa/QIgVGhlIGZpbHRlciBzeW50YXggY29uc2lz
dHMgb2YgYW4gZXhwcmVzc2lvbiBsYW5ndWFnZSBmb3IgY29uc3RydWN0aW5nIGEKIHByZWRp
Y2F0ZSBmcm9tIG9uZSBvciBtb3JlIGZpZWxkcyBvZiB0aGUgcHJvZHVjdHMgYmVpbmcgZmls
dGVyZWQuCgogU2VlIFtTZWFyY2hSZXF1ZXN0LmZpbHRlcl1bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmJldGEuU2VhcmNoUmVxdWVzdC5maWx0ZXJdCiBmb3IgZGVmaW5pdGlvbiBhbmQgc3lu
dGF4LgoKIFRoZSB2YWx1ZSBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBh
IGxlbmd0aCBsaW1pdCBvZiAxLDAwMAogY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbiBJTlZB
TElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACDAUSBMYBAggKDQoFBAAC
DAESBMYBCQ8KDQoFBAACDAMSBMYBEhQKvAMKBAQAAg0SBNMBAhcarQMgVGhlIG9yZGVyIGlu
IHdoaWNoIHByb2R1Y3RzIGFyZSByZXR1cm5lZC4KCiBTZWUKIFtTZWFyY2hSZXF1ZXN0Lm9y
ZGVyX2J5XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZWFyY2hSZXF1ZXN0Lm9yZGVy
X2J5XQogZm9yIGRlZmluaXRpb24gYW5kIHN5bnRheC4KCiBUaGUgdmFsdWUgbXVzdCBiZSBh
IFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMSwwMDAKIGNo
YXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1
cm5lZC4KCiBUaGlzIGNhbiBvbmx5IGJlIHNldCBmb3IgYHNlYXJjaGAgZXZlbnRzLiBPdGhl
ciBldmVudCB0eXBlcyBzaG91bGQgbm90IHNldAogdGhpcyBmaWVsZC4gT3RoZXJ3aXNlLCBh
biBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACDQUSBNMBAggK
DQoFBAACDQESBNMBCREKDQoFBAACDQMSBNMBFBYKzQMKBAQAAg4SBN8BAhQavgMgQW4gaW50
ZWdlciB0aGF0IHNwZWNpZmllcyB0aGUgY3VycmVudCBvZmZzZXQgZm9yIHBhZ2luYXRpb24g
KHRoZSAwLWluZGV4ZWQKIHN0YXJ0aW5nIGxvY2F0aW9uLCBhbW9uZ3N0IHRoZSBwcm9kdWN0
cyBkZWVtZWQgYnkgdGhlIEFQSSBhcyByZWxldmFudCkuCgogU2VlIFtTZWFyY2hSZXF1ZXN0
Lm9mZnNldF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VhcmNoUmVxdWVzdC5vZmZz
ZXRdCiBmb3IgZGVmaW5pdGlvbi4KCiBJZiB0aGlzIGZpZWxkIGlzIG5lZ2F0aXZlLCBhbiBJ
TlZBTElEX0FSR1VNRU5UIGlzIHJldHVybmVkLgoKIFRoaXMgY2FuIG9ubHkgYmUgc2V0IGZv
ciBgc2VhcmNoYCBldmVudHMuIE90aGVyIGV2ZW50IHR5cGVzIHNob3VsZCBub3Qgc2V0CiB0
aGlzIGZpZWxkLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0
dXJuZWQuCgoNCgUEAAIOBRIE3wECBwoNCgUEAAIOARIE3wEIDgoNCgUEAAIOAxIE3wEREwrv
BQoEBAACDxIE8AECJxrgBSBUaGUgY2F0ZWdvcmllcyBhc3NvY2lhdGVkIHdpdGggYSBjYXRl
Z29yeSBwYWdlLgoKIFRvIHJlcHJlc2VudCBmdWxsIHBhdGggb2YgY2F0ZWdvcnksIHVzZSAn
Picgc2lnbiB0byBzZXBhcmF0ZSBkaWZmZXJlbnQKIGhpZXJhcmNoaWVzLiBJZiAnPicgaXMg
cGFydCBvZiB0aGUgY2F0ZWdvcnkgbmFtZSwgcmVwbGFjZSBpdCB3aXRoCiBvdGhlciBjaGFy
YWN0ZXIocykuCgogQ2F0ZWdvcnkgcGFnZXMgaW5jbHVkZSBzcGVjaWFsIHBhZ2VzIHN1Y2gg
YXMgc2FsZXMgb3IgcHJvbW90aW9ucy4gRm9yCiBpbnN0YW5jZSwgYSBzcGVjaWFsIHNhbGUg
cGFnZSBtYXkgaGF2ZSB0aGUgY2F0ZWdvcnkgaGllcmFyY2h5OgogInBhZ2VDYXRlZ29yaWVz
IiA6IFsiU2FsZXMgPiAyMDE3IEJsYWNrIEZyaWRheSBEZWFscyJdLgoKIFJlcXVpcmVkIGZv
ciBgY2F0ZWdvcnktcGFnZS12aWV3YCBldmVudHMuIEF0IGxlYXN0IG9uZSBvZgogW3NlYXJj
aF9xdWVyeV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuVXNlckV2ZW50LnNlYXJjaF9x
dWVyeV0gb3IKIFtwYWdlX2NhdGVnb3JpZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LlVzZXJFdmVudC5wYWdlX2NhdGVnb3JpZXNdIGlzCiByZXF1aXJlZCBmb3IgYHNlYXJjaGAg
ZXZlbnRzLiBPdGhlciBldmVudCB0eXBlcyBzaG91bGQgbm90IHNldCB0aGlzIGZpZWxkLgog
T3RoZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoF
BAACDwQSBPABAgoKDQoFBAACDwUSBPABCxEKDQoFBAACDwESBPABEiEKDQoFBAACDwMSBPAB
JCYKIQoEBAACEBIE8wECGhoTIFVzZXIgaW5mb3JtYXRpb24uCgoNCgUEAAIQBhIE8wECCgoN
CgUEAAIQARIE8wELFAoNCgUEAAIQAxIE8wEXGQr1AQoEBAACERIE+gECEhrmASBDb21wbGV0
ZSBVUkwgKHdpbmRvdy5sb2NhdGlvbi5ocmVmKSBvZiB0aGUgdXNlcidzIGN1cnJlbnQgcGFn
ZS4KCiBXaGVuIHVzaW5nIHRoZSBjbGllbnQgc2lkZSBldmVudCByZXBvcnRpbmcgd2l0aCBK
YXZhU2NyaXB0IHBpeGVsIGFuZCBHb29nbGUKIFRhZyBNYW5hZ2VyLCB0aGlzIHZhbHVlIGlz
IGZpbGxlZCBpbiBhdXRvbWF0aWNhbGx5LiBNYXhpbXVtIGxlbmd0aCA1LDAwMAogY2hhcmFj
dGVycy4KCg0KBQQAAhEFEgT6AQIICg0KBQQAAhEBEgT6AQkMCg0KBQQAAhEDEgT6AQ8RCrkB
CgQEAAISEgSAAgIbGqoBIFRoZSByZWZlcnJlciBVUkwgb2YgdGhlIGN1cnJlbnQgcGFnZS4K
CiBXaGVuIHVzaW5nIHRoZSBjbGllbnQgc2lkZSBldmVudCByZXBvcnRpbmcgd2l0aCBKYXZh
U2NyaXB0IHBpeGVsIGFuZCBHb29nbGUKIFRhZyBNYW5hZ2VyLCB0aGlzIHZhbHVlIGlzIGZp
bGxlZCBpbiBhdXRvbWF0aWNhbGx5LgoKDQoFBAACEgUSBIACAggKDQoFBAACEgESBIACCRUK
DQoFBAACEgMSBIACGBoK6AMKBAQAAhMSBIwCAhsa2QMgQSB1bmlxdWUgSUQgb2YgYSB3ZWIg
cGFnZSB2aWV3LgoKIFRoaXMgc2hvdWxkIGJlIGtlcHQgdGhlIHNhbWUgZm9yIGFsbCB1c2Vy
IGV2ZW50cyB0cmlnZ2VyZWQgZnJvbSB0aGUgc2FtZQogcGFnZXZpZXcuIEZvciBleGFtcGxl
LCBhbiBpdGVtIGRldGFpbCBwYWdlIHZpZXcgY291bGQgdHJpZ2dlciBtdWx0aXBsZQogZXZl
bnRzIGFzIHRoZSB1c2VyIGlzIGJyb3dzaW5nIHRoZSBwYWdlLiBUaGUgYHBhZ2VWaWV3SWRg
IHByb3BlcnR5IHNob3VsZAogYmUga2VwdCB0aGUgc2FtZSBmb3IgYWxsIHRoZXNlIGV2ZW50
cyBzbyB0aGF0IHRoZXkgY2FuIGJlIGdyb3VwZWQgdG9nZXRoZXIKIHByb3Blcmx5LgoKIFdo
ZW4gdXNpbmcgdGhlIGNsaWVudCBzaWRlIGV2ZW50IHJlcG9ydGluZyB3aXRoIEphdmFTY3Jp
cHQgcGl4ZWwgYW5kIEdvb2dsZQogVGFnIE1hbmFnZXIsIHRoaXMgdmFsdWUgaXMgZmlsbGVk
IGluIGF1dG9tYXRpY2FsbHkuCgoNCgUEAAITBRIEjAICCAoNCgUEAAITARIEjAIJFQoNCgUE
AAITAxIEjAIYGgqvAgoEBAACFBIEkwICFRqgAiBUaGUgZW50aXR5IGZvciBjdXN0b21lcnMg
dGhhdCBtYXkgcnVuIG11bHRpcGxlIGRpZmZlcmVudCBlbnRpdGllcywgZG9tYWlucywKIHNp
dGVzIG9yIHJlZ2lvbnMsIGZvciBleGFtcGxlLCBgR29vZ2xlIFVTYCwgYEdvb2dsZSBBZHNg
LCBgV2F5bW9gLAogYGdvb2dsZS5jb21gLCBgeW91dHViZS5jb21gLCBldGMuCiBXZSByZWNv
bW1lbmQgdGhhdCB5b3Ugc2V0IHRoaXMgZmllbGQgdG8gZ2V0IGJldHRlciBwZXItZW50aXR5
IHNlYXJjaCwKIGNvbXBsZXRpb24sIGFuZCBwcmVkaWN0aW9uIHJlc3VsdHMuCgoNCgUEAAIU
BRIEkwICCAoNCgUEAAIUARIEkwIJDwoNCgUEAAIUAxIEkwISFApKCgIEARIGlwIAsQIBGjwg
RGV0YWlsZWQgcHJvZHVjdCBpbmZvcm1hdGlvbiBhc3NvY2lhdGVkIHdpdGggYSB1c2VyIGV2
ZW50LgoKCwoDBAEBEgSXAggVCtYECgQEAQIAEgSpAgI/GscEIFJlcXVpcmVkLiBbUHJvZHVj
dF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUHJvZHVjdF0gaW5mb3JtYXRpb24uCgog
UmVxdWlyZWQgZmllbGQocyk6CgogKiBbUHJvZHVjdC5pZF1bZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmJldGEuUHJvZHVjdC5pZF0KCiBPcHRpb25hbCBvdmVycmlkZSBmaWVsZChzKToKCiAq
IFtQcm9kdWN0LnByaWNlX2luZm9dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlByb2R1
Y3QucHJpY2VfaW5mb10KCiBJZiBhbnkgc3VwcG9ydGVkIG9wdGlvbmFsIGZpZWxkcyBhcmUg
cHJvdmlkZWQsIHdlIHdpbGwgdHJlYXQgdGhlbSBhcyBhIGZ1bGwKIG92ZXJyaWRlIHdoZW4g
bG9va2luZyB1cCBwcm9kdWN0IGluZm9ybWF0aW9uIGZyb20gdGhlIGNhdGFsb2cuIFRodXMs
IGl0IGlzCiBpbXBvcnRhbnQgdG8gZW5zdXJlIHRoYXQgdGhlIG92ZXJyaWRpbmcgZmllbGRz
IGFyZSBhY2N1cmF0ZSBhbmQKIGNvbXBsZXRlLgoKIEFsbCBvdGhlciBwcm9kdWN0IGZpZWxk
cyBhcmUgaWdub3JlZCBhbmQgaW5zdGVhZCBwb3B1bGF0ZWQgdmlhIGNhdGFsb2cKIGxvb2t1
cCBhZnRlciBldmVudCBpbmdlc3Rpb24uCgoNCgUEAQIABhIEqQICCQoNCgUEAQIAARIEqQIK
EQoNCgUEAQIAAxIEqQIUFQoNCgUEAQIACBIEqQIWPgoQCggEAQIACJwIABIEqQIXPQr8AQoE
BAECARIEsAICKhrtASBRdWFudGl0eSBvZiB0aGUgcHJvZHVjdCBhc3NvY2lhdGVkIHdpdGgg
dGhlIHVzZXIgZXZlbnQuCgogRm9yIGV4YW1wbGUsIHRoaXMgZmllbGQgd2lsbCBiZSAyIGlm
IHR3byBwcm9kdWN0cyBhcmUgYWRkZWQgdG8gdGhlIHNob3BwaW5nCiBjYXJ0IGZvciBgcHVy
Y2hhc2UtY29tcGxldGVgIGV2ZW50LiBSZXF1aXJlZCBmb3IgYGFkZC10by1jYXJ0YCBhbmQK
IGBwdXJjaGFzZS1jb21wbGV0ZWAgZXZlbnQgdHlwZXMuCgoNCgUEAQIBBhIEsAICHAoNCgUE
AQIBARIEsAIdJQoNCgUEAQIBAxIEsAIoKQp0CgIEAhIGtQIAwgIBGmYgRGV0YWlsZWQgY29t
cGxldGlvbiBpbmZvcm1hdGlvbiBpbmNsdWRpbmcgY29tcGxldGlvbiBhdHRyaWJ1dGlvbiB0
b2tlbiBhbmQKIGNsaWNrZWQgY29tcGxldGlvbiBpbmZvLgoKCwoDBAIBEgS1AggYCqABCgQE
AgIAEgS4AgIqGpEBIENvbXBsZXRpb24gYXR0cmlidXRpb24gdG9rZW4gaW4KIFtDb21wbGV0
ZVF1ZXJ5UmVzcG9uc2UuYXR0cmlidXRpb25fdG9rZW5dW2dvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLkNvbXBsZXRlUXVlcnlSZXNwb25zZS5hdHRyaWJ1dGlvbl90b2tlbl0uCgoNCgUE
AgIABRIEuAICCAoNCgUEAgIAARIEuAIJJQoNCgUEAgIAAxIEuAIoKQqmAQoEBAICARIEvAIC
IRqXASBFbmQgdXNlciBzZWxlY3RlZAogW0NvbXBsZXRlUXVlcnlSZXNwb25zZS5Db21wbGV0
aW9uUmVzdWx0LnN1Z2dlc3Rpb25dW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkNvbXBs
ZXRlUXVlcnlSZXNwb25zZS5Db21wbGV0aW9uUmVzdWx0LnN1Z2dlc3Rpb25dLgoKDQoFBAIC
AQUSBLwCAggKDQoFBAICAQESBLwCCRwKDQoFBAICAQMSBLwCHyAKwQEKBAQCAgISBMECAh4a
sgEgRW5kIHVzZXIgc2VsZWN0ZWQKIFtDb21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQ29tcGxldGlv
blJlc3VsdC5zdWdnZXN0aW9uXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Db21wbGV0
ZVF1ZXJ5UmVzcG9uc2UuQ29tcGxldGlvblJlc3VsdC5zdWdnZXN0aW9uXQogcG9zaXRpb24s
IHN0YXJ0aW5nIGZyb20gMC4KCg0KBQQCAgIFEgTBAgIHCg0KBQQCAgIBEgTBAggZCg0KBQQC
AgIDEgTBAhwdCkkKAgQDEgbFAgDeAgEaOyBBIHRyYW5zYWN0aW9uIHJlcHJlc2VudHMgdGhl
IGVudGlyZSBwdXJjaGFzZSB0cmFuc2FjdGlvbi4KCgsKAwQDARIExQIIGwpJCgQEAwIAEgTH
AgIQGjsgVGhlIHRyYW5zYWN0aW9uIElEIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTI4IGNo
YXJhY3RlcnMuCgoNCgUEAwIABRIExwICCAoNCgUEAwIAARIExwIJCwoNCgUEAwIAAxIExwIO
DwrrAQoEBAMCARIEzQICPRrcASBSZXF1aXJlZC4gVG90YWwgbm9uLXplcm8gcmV2ZW51ZSBv
ciBncmFuZCB0b3RhbCBhc3NvY2lhdGVkIHdpdGggdGhlCiB0cmFuc2FjdGlvbi4gVGhpcyB2
YWx1ZSBpbmNsdWRlIHNoaXBwaW5nLCB0YXgsIG9yIG90aGVyIGFkanVzdG1lbnRzIHRvCiB0
b3RhbCByZXZlbnVlIHRoYXQgeW91IHdhbnQgdG8gaW5jbHVkZSBhcyBwYXJ0IG9mIHlvdXIg
cmV2ZW51ZQogY2FsY3VsYXRpb25zLgoKDQoFBAMCAQUSBM0CAgcKDQoFBAMCAQESBM0CCA8K
DQoFBAMCAQMSBM0CEhMKDQoFBAMCAQgSBM0CFDwKEAoIBAMCAQicCAASBM0CFTsKPgoEBAMC
AhIE0AICEBowIEFsbCB0aGUgdGF4ZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSB0cmFuc2FjdGlv
bi4KCg0KBQQDAgIFEgTQAgIHCg0KBQQDAgIBEgTQAggLCg0KBQQDAgIDEgTQAg4PCvgCCgQE
AwIDEgTaAgIRGukCIEFsbCB0aGUgY29zdHMgYXNzb2NpYXRlZCB3aXRoIHRoZSBwcm9kdWN0
cy4gVGhlc2UgY2FuIGJlIG1hbnVmYWN0dXJpbmcKIGNvc3RzLCBzaGlwcGluZyBleHBlbnNl
cyBub3QgYm9ybmUgYnkgdGhlIGVuZCB1c2VyLCBvciBhbnkgb3RoZXIgY29zdHMsCiBzdWNo
IHRoYXQ6CgogKiBQcm9maXQgPQogW3JldmVudWVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJi
ZXRhLlB1cmNoYXNlVHJhbnNhY3Rpb24ucmV2ZW51ZV0gLQogW3RheF1bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmJldGEuUHVyY2hhc2VUcmFuc2FjdGlvbi50YXhdIC0KIFtjb3N0XVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YS5QdXJjaGFzZVRyYW5zYWN0aW9uLmNvc3RdCgoNCgUE
AwIDBRIE2gICBwoNCgUEAwIDARIE2gIIDAoNCgUEAwIDAxIE2gIPEApLCgQEAwIEEgTdAgJE
Gj0gUmVxdWlyZWQuIEN1cnJlbmN5IGNvZGUuIFVzZSB0aHJlZS1jaGFyYWN0ZXIgSVNPLTQy
MTcgY29kZS4KCg0KBQQDAgQFEgTdAgIICg0KBQQDAgQBEgTdAgkWCg0KBQQDAgQDEgTdAhka
Cg0KBQQDAgQIEgTdAhtDChAKCAQDAgQInAgAEgTdAhxCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::UserEvent::UserEvent ===
    # Fields for UserEvent
    # Field: event_type Type: 9 ()
    # Field: visitor_id Type: 9 ()
    # Field: session_id Type: 9 ()
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: experiment_ids Type: 9 ()
    # Field: attribution_token Type: 9 ()
    # Field: product_details Type: 11 (.google.cloud.retail.v2beta.ProductDetail)
    # Field: completion_detail Type: 11 (.google.cloud.retail.v2beta.CompletionDetail)
    # Field: attributes Type: 11 (.google.cloud.retail.v2beta.UserEvent.AttributesEntry)
    # Field: cart_id Type: 9 ()
    # Field: purchase_transaction Type: 11 (.google.cloud.retail.v2beta.PurchaseTransaction)
    # Field: search_query Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: offset Type: 5 ()
    # Field: page_categories Type: 9 ()
    # Field: user_info Type: 11 (.google.cloud.retail.v2beta.UserInfo)
    # Field: uri Type: 9 ()
    # Field: referrer_uri Type: 9 ()
    # Field: page_view_id Type: 9 ()
    # Field: entity Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::UserEvent::ProductDetail ===
    # Fields for ProductDetail
    # Field: product Type: 11 (.google.cloud.retail.v2beta.Product)
    # Field: quantity Type: 11 (.google.protobuf.Int32Value)

# === Message: Google::Cloud::Retail::V2beta::UserEvent::CompletionDetail ===
    # Fields for CompletionDetail
    # Field: completion_attribution_token Type: 9 ()
    # Field: selected_suggestion Type: 9 ()
    # Field: selected_position Type: 5 ()

# === Message: Google::Cloud::Retail::V2beta::UserEvent::PurchaseTransaction ===
    # Fields for PurchaseTransaction
    # Field: id Type: 9 ()
    # Field: revenue Type: 2 ()
    # Field: tax Type: 2 ()
    # Field: cost Type: 2 ()
    # Field: currency_code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::UserEvent - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/user_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::UserEvent;

    my $msg = Google::Cloud::Retail::V2beta::UserEvent::UserEvent->new({
        event_type => $event_type,
        visitor_id => $visitor_id,
        session_id => $session_id,
        event_time => $event_time,
    });

    # Read or update a field
    my $val = $msg->event_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::UserEvent::UserEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/user_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::UserEvent::UserEvent

UserEvent captures all metadata information Retail API needs to know about
how end users interact with customers' website.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<String>

Required. User event type. Allowed values are:

* `add-to-cart`: Products being added to cart.
* `remove-from-cart`: Products being removed from cart.
* `category-page-view`: Special pages such as sale or promotion pages
  viewed.
* `detail-page-view`: Products detail page viewed.
* `home-page-view`: Homepage viewed.
* `purchase-complete`: User finishing a purchase.
* `search`: Product search.
* `shopping-cart-page-view`: User viewing a shopping cart.

=item * C<< $msg->visitor_id() >> / C<< $msg->visitor_id($value) >>

Type: C<String>

Required. A unique identifier for tracking visitors.

For example, this could be implemented with an HTTP cookie, which should be
able to uniquely identify a visitor on a single device. This unique
identifier should not change if the visitor log in/out of the website.

Don't set the field to the same fixed ID for different users. This mixes
the event history of those users together, which results in degraded model
quality.

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

The field should not contain PII or user-data. We recommend to use Google
Analytics [Client
ID](https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#clientId)
for this field.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

A unique identifier for tracking a visitor session with a length limit of
128 bytes. A session is an aggregation of an end user behavior in a time
span.

A general guideline to populate the sesion_id:
1. If user has no activity for 30 min, a new session_id should be assigned.
2. The session_id should be unique across users, suggest use uuid or add
visitor_id as prefix.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Only required for
[UserEventService.ImportUserEvents][google.cloud.retail.v2beta.UserEventService.ImportUserEvents]
method. Timestamp of when the user event happened.

=item * C<< $msg->experiment_ids() >> / C<< $msg->experiment_ids($value) >>

Type: C<String>

A list of identifiers for the independent experiment groups this user event
belongs to. This is used to distinguish between user events associated with
different experiment setups (e.g. using Retail API, using different
recommendation models).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

Highly recommended for user events that are the result of
[PredictionService.Predict][google.cloud.retail.v2beta.PredictionService.Predict].
This field enables accurate attribution of recommendation model
performance.

The value must be a valid
[PredictResponse.attribution_token][google.cloud.retail.v2beta.PredictResponse.attribution_token]
for user events that are the result of
[PredictionService.Predict][google.cloud.retail.v2beta.PredictionService.Predict].
The value must be a valid
[SearchResponse.attribution_token][google.cloud.retail.v2beta.SearchResponse.attribution_token]
for user events that are the result of
[SearchService.Search][google.cloud.retail.v2beta.SearchService.Search].

This token enables us to accurately attribute page view or purchase back to
the event and the particular predict response containing this
clicked/purchased product. If user clicks on product K in the
recommendation results, pass
[PredictResponse.attribution_token][google.cloud.retail.v2beta.PredictResponse.attribution_token]
as a URL parameter to product K's page. When recording events on product
K's page, log the
[PredictResponse.attribution_token][google.cloud.retail.v2beta.PredictResponse.attribution_token]
to this field.

=item * C<< $msg->product_details() >> / C<< $msg->product_details($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::ProductDetail>)

The main product details related to the event.

This field is optional except for the following event types:

* `add-to-cart`
* `detail-page-view`
* `purchase-complete`

In a `search` event, this field represents the products returned to the end
user on the current page (the end user may have not finished browsing the
whole page yet). When a new page is returned to the end user, after
pagination/filtering/ordering even for the same query, a new `search` event
with different
[product_details][google.cloud.retail.v2beta.UserEvent.product_details] is
desired. The end user may have not finished browsing the whole page yet.

=item * C<< $msg->completion_detail() >> / C<< $msg->completion_detail($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::CompletionDetail>)

The main auto-completion details related to the event.

This field should be set for `search` event when autocomplete function is
enabled and the user clicks a suggestion for search.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent::AttributesEntry>)

Extra user event features to include in the recommendation model.

If you provide custom attributes for ingested user events, also include
them in the user events that you associate with prediction requests. Custom
attribute formatting must be consistent between imported events and events
provided with prediction requests. This lets the Retail API use
those custom attributes when training models and serving predictions, which
helps improve recommendation quality.

This field needs to pass all below criteria, otherwise an INVALID_ARGUMENT
error is returned:

* The key must be a UTF-8 encoded string with a length limit of 5,000
  characters.
* For text attributes, at most 400 values are allowed. Empty values are not
  allowed. Each value must be a UTF-8 encoded string with a length limit of
  256 characters.
* For number attributes, at most 400 values are allowed.

For product recommendations, an example of extra user information is
traffic_channel, which is how a user arrives at the site. Users can arrive
at the site by coming to the site directly, coming through Google
search, or in other ways.

=item * C<< $msg->cart_id() >> / C<< $msg->cart_id($value) >>

Type: C<String>

The ID or name of the associated shopping cart. This ID is used
to associate multiple items added or present in the cart before purchase.

This can only be set for `add-to-cart`, `purchase-complete`, or
`shopping-cart-page-view` events.

=item * C<< $msg->purchase_transaction() >> / C<< $msg->purchase_transaction($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::UserEvent::PurchaseTransaction>)

A transaction represents the entire purchase transaction.

Required for `purchase-complete` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->search_query() >> / C<< $msg->search_query($value) >>

Type: C<String>

The user's search query.

See [SearchRequest.query][google.cloud.retail.v2beta.SearchRequest.query]
for definition.

The value must be a UTF-8 encoded string with a length limit of 5,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

At least one of
[search_query][google.cloud.retail.v2beta.UserEvent.search_query] or
[page_categories][google.cloud.retail.v2beta.UserEvent.page_categories] is
required for `search` events. Other event types should not set this field.
Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter syntax consists of an expression language for constructing a
predicate from one or more fields of the products being filtered.

See [SearchRequest.filter][google.cloud.retail.v2beta.SearchRequest.filter]
for definition and syntax.

The value must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

The order in which products are returned.

See
[SearchRequest.order_by][google.cloud.retail.v2beta.SearchRequest.order_by]
for definition and syntax.

The value must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

This can only be set for `search` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int32>

An integer that specifies the current offset for pagination (the 0-indexed
starting location, amongst the products deemed by the API as relevant).

See [SearchRequest.offset][google.cloud.retail.v2beta.SearchRequest.offset]
for definition.

If this field is negative, an INVALID_ARGUMENT is returned.

This can only be set for `search` events. Other event types should not set
this field. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->page_categories() >> / C<< $msg->page_categories($value) >>

Type: C<String>

The categories associated with a category page.

To represent full path of category, use '>' sign to separate different
hierarchies. If '>' is part of the category name, replace it with
other character(s).

Category pages include special pages such as sales or promotions. For
instance, a special sale page may have the category hierarchy:
"pageCategories" : ["Sales > 2017 Black Friday Deals"].

Required for `category-page-view` events. At least one of
[search_query][google.cloud.retail.v2beta.UserEvent.search_query] or
[page_categories][google.cloud.retail.v2beta.UserEvent.page_categories] is
required for `search` events. Other event types should not set this field.
Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->user_info() >> / C<< $msg->user_info($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Common::UserInfo>)

User information.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Complete URL (window.location.href) of the user's current page.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically. Maximum length 5,000
characters.

=item * C<< $msg->referrer_uri() >> / C<< $msg->referrer_uri($value) >>

Type: C<String>

The referrer URL of the current page.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically.

=item * C<< $msg->page_view_id() >> / C<< $msg->page_view_id($value) >>

Type: C<String>

A unique ID of a web page view.

This should be kept the same for all user events triggered from the same
pageview. For example, an item detail page view could trigger multiple
events as the user is browsing the page. The `pageViewId` property should
be kept the same for all these events so that they can be grouped together
properly.

When using the client side event reporting with JavaScript pixel and Google
Tag Manager, this value is filled in automatically.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<String>

The entity for customers that may run multiple different entities, domains,
sites or regions, for example, `Google US`, `Google Ads`, `Waymo`,
`google.com`, `youtube.com`, etc.
We recommend that you set this field to get better per-entity search,
completion, and prediction results.

=back

=head2 Google::Cloud::Retail::V2beta::UserEvent::ProductDetail

Detailed product information associated with a user event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Product::Product>)

Required. [Product][google.cloud.retail.v2beta.Product] information.

Required field(s):

* [Product.id][google.cloud.retail.v2beta.Product.id]

Optional override field(s):

* [Product.price_info][google.cloud.retail.v2beta.Product.price_info]

If any supported optional fields are provided, we will treat them as a full
override when looking up product information from the catalog. Thus, it is
important to ensure that the overriding fields are accurate and
complete.

All other product fields are ignored and instead populated via catalog
lookup after event ingestion.

=item * C<< $msg->quantity() >> / C<< $msg->quantity($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::Int32Value>)

Quantity of the product associated with the user event.

For example, this field will be 2 if two products are added to the shopping
cart for `purchase-complete` event. Required for `add-to-cart` and
`purchase-complete` event types.

=back

=head2 Google::Cloud::Retail::V2beta::UserEvent::CompletionDetail

Detailed completion information including completion attribution token and
clicked completion info.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_attribution_token() >> / C<< $msg->completion_attribution_token($value) >>

Type: C<String>

Completion attribution token in
[CompleteQueryResponse.attribution_token][google.cloud.retail.v2beta.CompleteQueryResponse.attribution_token].

=item * C<< $msg->selected_suggestion() >> / C<< $msg->selected_suggestion($value) >>

Type: C<String>

End user selected
[CompleteQueryResponse.CompletionResult.suggestion][google.cloud.retail.v2beta.CompleteQueryResponse.CompletionResult.suggestion].

=item * C<< $msg->selected_position() >> / C<< $msg->selected_position($value) >>

Type: C<Int32>

End user selected
[CompleteQueryResponse.CompletionResult.suggestion][google.cloud.retail.v2beta.CompleteQueryResponse.CompletionResult.suggestion]
position, starting from 0.

=back

=head2 Google::Cloud::Retail::V2beta::UserEvent::PurchaseTransaction

A transaction represents the entire purchase transaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The transaction ID with a length limit of 128 characters.

=item * C<< $msg->revenue() >> / C<< $msg->revenue($value) >>

Type: C<Float>

Required. Total non-zero revenue or grand total associated with the
transaction. This value include shipping, tax, or other adjustments to
total revenue that you want to include as part of your revenue
calculations.

=item * C<< $msg->tax() >> / C<< $msg->tax($value) >>

Type: C<Float>

All the taxes associated with the transaction.

=item * C<< $msg->cost() >> / C<< $msg->cost($value) >>

Type: C<Float>

All the costs associated with the products. These can be manufacturing
costs, shipping expenses not borne by the end user, or any other costs,
such that:

* Profit =
[revenue][google.cloud.retail.v2beta.PurchaseTransaction.revenue] -
[tax][google.cloud.retail.v2beta.PurchaseTransaction.tax] -
[cost][google.cloud.retail.v2beta.PurchaseTransaction.cost]

=item * C<< $msg->currency_code() >> / C<< $msg->currency_code($value) >>

Type: C<String>

Required. Currency code. Use three-character ISO-4217 code.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::UserEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
