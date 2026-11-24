package Google::Cloud::Dialogflow::V2beta1::Fulfillment;

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
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2Z1bGZpbGxtZW50LnByb3RvEh9n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVm
L2ZpZWxkX21hc2sucHJvdG8ipQcKC0Z1bGZpbGxtZW50EhcKBG5hbWUYASABKAlCA+BBAlIE
bmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEnAKE2dlbmVyaWNfd2Vi
X3NlcnZpY2UYAyABKAsyPi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkZ1bGZp
bGxtZW50LkdlbmVyaWNXZWJTZXJ2aWNlSABSEWdlbmVyaWNXZWJTZXJ2aWNlEhgKB2VuYWJs
ZWQYBCABKAhSB2VuYWJsZWQSUAoIZmVhdHVyZXMYBSADKAsyNC5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLkZ1bGZpbGxtZW50LkZlYXR1cmVSCGZlYXR1cmVzGtUCChFHZW5l
cmljV2ViU2VydmljZRIVCgN1cmkYASABKAlCA+BBAlIDdXJpEhoKCHVzZXJuYW1lGAIgASgJ
Ugh1c2VybmFtZRIaCghwYXNzd29yZBgDIAEoCVIIcGFzc3dvcmQSewoPcmVxdWVzdF9oZWFk
ZXJzGAQgAygLMlIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5GdWxmaWxsbWVu
dC5HZW5lcmljV2ViU2VydmljZS5SZXF1ZXN0SGVhZGVyc0VudHJ5Ug5yZXF1ZXN0SGVhZGVy
cxIxChFpc19jbG91ZF9mdW5jdGlvbhgFIAEoCEIFGAHgQQFSD2lzQ2xvdWRGdW5jdGlvbhpB
ChNSZXF1ZXN0SGVhZGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEahQEKB0ZlYXR1cmUSTQoEdHlwZRgBIAEoDjI5Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuRnVsZmlsbG1lbnQuRmVhdHVyZS5UeXBlUgR0eXBlIisKBFR5
cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEg0KCVNNQUxMVEFMSxABOowB6kGIAQolZGlhbG9n
Zmxvdy5nb29nbGVhcGlzLmNvbS9GdWxmaWxsbWVudBIkcHJvamVjdHMve3Byb2plY3R9L2Fn
ZW50L2Z1bGZpbGxtZW50Ejlwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYWdlbnQvZnVsZmlsbG1lbnRCDQoLZnVsZmlsbG1lbnQiWgoVR2V0RnVsZmlsbG1lbnRS
ZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNv
bS9GdWxmaWxsbWVudFIEbmFtZSKxAQoYVXBkYXRlRnVsZmlsbG1lbnRSZXF1ZXN0ElMKC2Z1
bGZpbGxtZW50GAEgASgLMiwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5GdWxm
aWxsbWVudEID4EECUgtmdWxmaWxsbWVudBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzazK5BQoMRnVsZmlsbG1lbnRz
Eu8BCg5HZXRGdWxmaWxsbWVudBI2Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
R2V0RnVsZmlsbG1lbnRSZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRh
MS5GdWxmaWxsbWVudCJ3gtPkkwJqEiwvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2FnZW50
L2Z1bGZpbGxtZW50fVo6EjgvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2FnZW50L2Z1bGZpbGxtZW50fdpBBG5hbWUSvAIKEVVwZGF0ZUZ1bGZpbGxtZW50EjkuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5VcGRhdGVGdWxmaWxsbWVudFJlcXVlc3Qa
LC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkZ1bGZpbGxtZW50Ir0BgtPkkwKc
ATI4L3YyYmV0YTEve2Z1bGZpbGxtZW50Lm5hbWU9cHJvamVjdHMvKi9hZ2VudC9mdWxmaWxs
bWVudH06C2Z1bGZpbGxtZW50WlMyRC92MmJldGExL3tmdWxmaWxsbWVudC5uYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovYWdlbnQvZnVsZmlsbG1lbnR9OgtmdWxmaWxsbWVudNpBF2Z1
bGZpbGxtZW50LHVwZGF0ZV9tYXNrGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZ
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCpQEKI2NvbS5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MmJldGExQhBGdWxmaWxsbWVudFByb3RvUAFaQ2Nsb3VkLmdvb2ds
ZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2MmJldGExL2RpYWxvZ2Zsb3dwYjtkaWFsb2dmbG93
cGKiAgJERqoCH0dvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYyQmV0YTFK0SoKBxIFDgC0AQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIA
JgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAqCggKAQgSAxgA
PAoJCgIIJRIDGAA8CggKAQgSAxkAWgoJCgIICxIDGQBaCggKAQgSAxoAIgoJCgIIChIDGgAi
CggKAQgSAxsAMQoJCgIICBIDGwAxCggKAQgSAxwAPAoJCgIIARIDHAA8CggKAQgSAx0AIAoJ
CgIIJBIDHQAgCmAKAgYAEgQhAD4BGlQgU2VydmljZSBmb3IgbWFuYWdpbmcKIFtGdWxmaWxs
bWVudHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRnVsZmlsbG1lbnRdLgoK
CgoDBgABEgMhCBQKCgoDBgADEgMiAkEKDAoFBgADmQgSAyICQQoLCgMGAAMSBCMCJTMKDQoF
BgADmggSBCMCJTMKKgoEBgACABIEKAIwAxocIFJldHJpZXZlcyB0aGUgZnVsZmlsbG1lbnQu
CgoMCgUGAAIAARIDKAYUCgwKBQYAAgACEgMoFSoKDAoFBgACAAMSAyg1QAoNCgUGAAIABBIE
KQQuBgoRCgkGAAIABLDKvCISBCkELgYKDAoFBgACAAQSAy8EMgoPCggGAAIABJsIABIDLwQy
CigKBAYAAgESBDMCPQMaGiBVcGRhdGVzIHRoZSBmdWxmaWxsbWVudC4KCgwKBQYAAgEBEgMz
BhcKDAoFBgACAQISAzMYMAoMCgUGAAIBAxIDMztGCg0KBQYAAgEEEgQ0BDsGChEKCQYAAgEE
sMq8IhIENAQ7BgoMCgUGAAIBBBIDPARFCg8KCAYAAgEEmwgAEgM8BEUKyQQKAgQAEgVKAJgB
ARq7BCBCeSBkZWZhdWx0LCB5b3VyIGFnZW50IHJlc3BvbmRzIHRvIGEgbWF0Y2hlZCBpbnRl
bnQgd2l0aCBhIHN0YXRpYyByZXNwb25zZS4KIEFzIGFuIGFsdGVybmF0aXZlLCB5b3UgY2Fu
IHByb3ZpZGUgYSBtb3JlIGR5bmFtaWMgcmVzcG9uc2UgYnkgdXNpbmcKIGZ1bGZpbGxtZW50
LiBXaGVuIHlvdSBlbmFibGUgZnVsZmlsbG1lbnQgZm9yIGFuIGludGVudCwgRGlhbG9nZmxv
dyByZXNwb25kcwogdG8gdGhhdCBpbnRlbnQgYnkgY2FsbGluZyBhIHNlcnZpY2UgdGhhdCB5
b3UgZGVmaW5lLiBGb3IgZXhhbXBsZSwgaWYgYW4KIGVuZC11c2VyIHdhbnRzIHRvIHNjaGVk
dWxlIGEgaGFpcmN1dCBvbiBGcmlkYXksIHlvdXIgc2VydmljZSBjYW4gY2hlY2sgeW91cgog
ZGF0YWJhc2UgYW5kIHJlc3BvbmQgdG8gdGhlIGVuZC11c2VyIHdpdGggYXZhaWxhYmlsaXR5
IGluZm9ybWF0aW9uIGZvcgogRnJpZGF5LgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUg
dGhlIFtmdWxmaWxsbWVudAogZ3VpZGVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFs
b2dmbG93L2RvY3MvZnVsZmlsbG1lbnQtb3ZlcnZpZXcpLgoKCgoDBAABEgNKCBMKCwoDBAAH
EgRLAk8ECg0KBQQAB50IEgRLAk8ECtMCCgQEAAMAEgRZAm4DGsQCIFJlcHJlc2VudHMgY29u
ZmlndXJhdGlvbiBmb3IgYSBnZW5lcmljIHdlYiBzZXJ2aWNlLgogRGlhbG9nZmxvdyBzdXBw
b3J0cyB0d28gbWVjaGFuaXNtcyBmb3IgYXV0aGVudGljYXRpb25zOgoKIC0gQmFzaWMgYXV0
aGVudGljYXRpb24gd2l0aCB1c2VybmFtZSBhbmQgcGFzc3dvcmQuCiAtIEF1dGhlbnRpY2F0
aW9uIHdpdGggYWRkaXRpb25hbCBhdXRoZW50aWNhdGlvbiBoZWFkZXJzLgoKIE1vcmUgaW5m
b3JtYXRpb24gY291bGQgYmUgZm91bmQgYXQ6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
ZGlhbG9nZmxvdy9kb2NzL2Z1bGZpbGxtZW50LWNvbmZpZ3VyZS4KCgwKBQQAAwABEgNZChsK
aAoGBAADAAIAEgNcBDwaWSBSZXF1aXJlZC4gVGhlIGZ1bGZpbGxtZW50IFVSSSBmb3IgcmVj
ZWl2aW5nIFBPU1QgcmVxdWVzdHMuCiBJdCBtdXN0IHVzZSBodHRwcyBwcm90b2NvbC4KCg4K
BwQAAwACAAUSA1wECgoOCgcEAAMAAgABEgNcCw4KDgoHBAADAAIAAxIDXBESCg4KBwQAAwAC
AAgSA1wTOwoRCgoEAAMAAgAInAgAEgNcFDoKPQoGBAADAAIBEgNfBBgaLiBUaGUgdXNlciBu
YW1lIGZvciBIVFRQIEJhc2ljIGF1dGhlbnRpY2F0aW9uLgoKDgoHBAADAAIBBRIDXwQKCg4K
BwQAAwACAQESA18LEwoOCgcEAAMAAgEDEgNfFhcKPAoGBAADAAICEgNiBBgaLSBUaGUgcGFz
c3dvcmQgZm9yIEhUVFAgQmFzaWMgYXV0aGVudGljYXRpb24uCgoOCgcEAAMAAgIFEgNiBAoK
DgoHBAADAAICARIDYgsTCg4KBwQAAwACAgMSA2IWFwpVCgYEAAMAAgMSA2UELBpGIFRoZSBI
VFRQIHJlcXVlc3QgaGVhZGVycyB0byBzZW5kIHRvZ2V0aGVyIHdpdGggZnVsZmlsbG1lbnQg
cmVxdWVzdHMuCgoOCgcEAAMAAgMGEgNlBBcKDgoHBAADAAIDARIDZRgnCg4KBwQAAwACAwMS
A2UqKwrwAQoGBAADAAIEEgRsBG1EGt8BIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaWYgZ2VuZXJp
YyB3ZWIgc2VydmljZSBpcyBjcmVhdGVkIHRocm91Z2ggQ2xvdWQKIEZ1bmN0aW9ucyBpbnRl
Z3JhdGlvbi4gRGVmYXVsdHMgdG8gZmFsc2UuCgogaXNfY2xvdWRfZnVuY3Rpb24gaXMgZGVw
cmVjYXRlZC4gQ2xvdWQgZnVuY3Rpb25zIGNhbiBiZSBjb25maWd1cmVkIGJ5CiBpdHMgdXJp
IGFzIGEgcmVndWxhciB3ZWIgc2VydmljZSBub3cuCgoOCgcEAAMAAgQFEgNsBAgKDgoHBAAD
AAIEARIDbAkaCg4KBwQAAwACBAMSA2wdHgoOCgcEAAMAAgQIEgNtCEMKDwoIBAADAAIECAMS
A20JGgoRCgoEAAMAAgQInAgAEgNtHEIKSAoEBAADARIEcQJ9Axo6IFdoZXRoZXIgZnVsZmls
bG1lbnQgaXMgZW5hYmxlZCBmb3IgdGhlIHNwZWNpZmljIGZlYXR1cmUuCgoMCgUEAAMBARID
cQoRCioKBgQAAwEEABIEcwR5BRoaIFRoZSB0eXBlIG9mIHRoZSBmZWF0dXJlLgoKDgoHBAAD
AQQAARIDcwkNCi4KCAQAAwEEAAIAEgN1BhsaHSBGZWF0dXJlIHR5cGUgbm90IHNwZWNpZmll
ZC4KChAKCQQAAwEEAAIAARIDdQYWChAKCQQAAwEEAAIAAhIDdRkaCjgKCAQAAwEEAAIBEgN4
BhQaJyBGdWxmaWxsbWVudCBpcyBlbmFibGVkIGZvciBTbWFsbFRhbGsuCgoQCgkEAAMBBAAC
AQESA3gGDwoQCgkEAAMBBAACAQISA3gSEwpGCgYEAAMBAgASA3wEEho3IFRoZSB0eXBlIG9m
IHRoZSBmZWF0dXJlIHRoYXQgZW5hYmxlZCBmb3IgZnVsZmlsbG1lbnQuCgoOCgcEAAMBAgAG
EgN8BAgKDgoHBAADAQIAARIDfAkNCg4KBwQAAwECAAMSA3wQEQqHAgoEBAACABIEhgECOxr4
ASBSZXF1aXJlZC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBmdWxmaWxsbWVudC4K
IFN1cHBvcnRlZCBmb3JtYXRzOgoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9m
dWxmaWxsbWVudGAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0
aW9uIElEPi9hZ2VudC9mdWxmaWxsbWVudGAKCiBUaGlzIGZpZWxkIGlzIG5vdCB1c2VkIGZv
ciBGdWxmaWxsbWVudCBpbiBhbiBFbnZpcm9ubWVudC4KCg0KBQQAAgAFEgSGAQIICg0KBQQA
AgABEgSGAQkNCg0KBQQAAgADEgSGARARCg0KBQQAAgAIEgSGARI6ChAKCAQAAgAInAgAEgSG
ARM5CpEBCgQEAAIBEgSLAQIaGoIBIFRoZSBodW1hbi1yZWFkYWJsZSBuYW1lIG9mIHRoZSBm
dWxmaWxsbWVudCwgdW5pcXVlIHdpdGhpbiB0aGUgYWdlbnQuCgogVGhpcyBmaWVsZCBpcyBu
b3QgdXNlZCBmb3IgRnVsZmlsbG1lbnQgaW4gYW4gRW52aXJvbm1lbnQuCgoNCgUEAAIBBRIE
iwECCAoNCgUEAAIBARIEiwEJFQoNCgUEAAIBAxIEiwEYGQo6CgQEAAgAEgaOAQKRAQMaKiBS
ZXF1aXJlZC4gVGhlIGZ1bGZpbGxtZW50IGNvbmZpZ3VyYXRpb24uCgoNCgUEAAgAARIEjgEI
Ewo4CgQEAAICEgSQAQQuGiogQ29uZmlndXJhdGlvbiBmb3IgYSBnZW5lcmljIHdlYiBzZXJ2
aWNlLgoKDQoFBAACAgYSBJABBBUKDQoFBAACAgESBJABFikKDQoFBAACAgMSBJABLC0KLwoE
BAACAxIElAECExohIFdoZXRoZXIgZnVsZmlsbG1lbnQgaXMgZW5hYmxlZC4KCg0KBQQAAgMF
EgSUAQIGCg0KBQQAAgMBEgSUAQcOCg0KBQQAAgMDEgSUARESCloKBAQAAgQSBJcBAiAaTCBU
aGUgZmllbGQgZGVmaW5lcyB3aGV0aGVyIHRoZSBmdWxmaWxsbWVudCBpcyBlbmFibGVkIGZv
ciBjZXJ0YWluIGZlYXR1cmVzLgoKDQoFBAACBAQSBJcBAgoKDQoFBAACBAYSBJcBCxIKDQoF
BAACBAESBJcBExsKDQoFBAACBAMSBJcBHh8KhAEKAgQBEgacAQCoAQEadiBUaGUgcmVxdWVz
dCBtZXNzYWdlIGZvcgogW0Z1bGZpbGxtZW50cy5HZXRGdWxmaWxsbWVudF1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5GdWxmaWxsbWVudHMuR2V0RnVsZmlsbG1lbnRdLgoK
CwoDBAEBEgScAQgdCsABCgQEAQIAEgaiAQKnAQQarwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBmdWxmaWxsbWVudC4KIFN1cHBvcnRlZCBmb3JtYXRzOgoKIC0gYHByb2plY3RzLzxQ
cm9qZWN0IElEPi9hZ2VudC9mdWxmaWxsbWVudGAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElE
Pi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2VudC9mdWxmaWxsbWVudGAKCg0KBQQBAgAF
EgSiAQIICg0KBQQBAgABEgSiAQkNCg0KBQQBAgADEgSiARARCg8KBQQBAgAIEgaiARKnAQMK
EAoIBAECAAicCAASBKMBBCoKEQoHBAECAAifCBIGpAEEpgEFCooBCgIEAhIGrAEAtAEBGnwg
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtGdWxmaWxsbWVudHMuVXBkYXRlRnVsZmlsbG1l
bnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRnVsZmlsbG1lbnRzLlVwZGF0
ZUZ1bGZpbGxtZW50XS4KCgsKAwQCARIErAEIIAo0CgQEAgIAEgSuAQJHGiYgUmVxdWlyZWQu
IFRoZSBmdWxmaWxsbWVudCB0byB1cGRhdGUuCgoNCgUEAgIABhIErgECDQoNCgUEAgIAARIE
rgEOGQoNCgUEAgIAAxIErgEcHQoNCgUEAgIACBIErgEeRgoQCggEAgIACJwIABIErgEfRQqC
AQoEBAICARIGsgECswEvGnIgUmVxdWlyZWQuIFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hpY2gg
ZmllbGRzIGdldCB1cGRhdGVkLiBJZiB0aGUgbWFzayBpcyBub3QKIHByZXNlbnQsIGFsbCBm
aWVsZHMgd2lsbCBiZSB1cGRhdGVkLgoKDQoFBAICAQYSBLIBAhsKDQoFBAICAQESBLIBHCcK
DQoFBAICAQMSBLIBKisKDQoFBAICAQgSBLMBBi4KEAoIBAICAQicCAASBLMBBy1iBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment ===
    # Fields for Fulfillment
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: generic_web_service Type: 11 (.google.cloud.dialogflow.v2beta1.Fulfillment.GenericWebService)
    # Field: enabled Type: 8 ()
    # Field: features Type: 11 (.google.cloud.dialogflow.v2beta1.Fulfillment.Feature)

# === Message: Google::Cloud::Dialogflow::V2beta1::Fulfillment::GetFulfillmentRequest ===
    # Fields for GetFulfillmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Fulfillment::UpdateFulfillmentRequest ===
    # Fields for UpdateFulfillmentRequest
    # Field: fulfillment Type: 11 (.google.cloud.dialogflow.v2beta1.Fulfillment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Dialogflow::V2beta1::Fulfillment::FulfillmentsClient ===
package Google::Cloud::Dialogflow::V2beta1::Fulfillment::FulfillmentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::Fulfillment::FulfillmentsClient

Client stub representing the remote C<Fulfillments> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub get_fulfillment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Fulfillment::GetFulfillmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Fulfillments',
        method         => 'GetFulfillment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment',
    });
}

sub update_fulfillment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Fulfillment::UpdateFulfillmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Fulfillments',
        method         => 'UpdateFulfillment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Fulfillment - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/fulfillment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Fulfillment;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment->new({
        name => $name,
        display_name => $display_name,
        generic_web_service => $generic_web_service,
        enabled => $enabled,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/fulfillment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment

By default, your agent responds to a matched intent with a static response.
As an alternative, you can provide a more dynamic response by using
fulfillment. When you enable fulfillment for an intent, Dialogflow responds
to that intent by calling a service that you define. For example, if an
end-user wants to schedule a haircut on Friday, your service can check your
database and respond to the end-user with availability information for
Friday.

For more information, see the [fulfillment
guide](https://cloud.google.com/dialogflow/docs/fulfillment-overview).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of the fulfillment.
Supported formats:

- `projects/<Project ID>/agent/fulfillment`
- `projects/<Project ID>/locations/<Location ID>/agent/fulfillment`

This field is not used for Fulfillment in an Environment.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human-readable name of the fulfillment, unique within the agent.

This field is not used for Fulfillment in an Environment.

=item * C<< $msg->generic_web_service() >> / C<< $msg->generic_web_service($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment::GenericWebService>)

Configuration for a generic web service.

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Whether fulfillment is enabled.

=item * C<< $msg->features() >> / C<< $msg->features($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment::Feature>)

The field defines whether the fulfillment is enabled for certain features.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Fulfillment::GetFulfillmentRequest

The request message for
[Fulfillments.GetFulfillment][google.cloud.dialogflow.v2beta1.Fulfillments.GetFulfillment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the fulfillment.
Supported formats:

- `projects/<Project ID>/agent/fulfillment`
- `projects/<Project ID>/locations/<Location ID>/agent/fulfillment`

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Fulfillment::UpdateFulfillmentRequest

The request message for
[Fulfillments.UpdateFulfillment][google.cloud.dialogflow.v2beta1.Fulfillments.UpdateFulfillment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fulfillment() >> / C<< $msg->fulfillment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment>)

Required. The fulfillment to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
