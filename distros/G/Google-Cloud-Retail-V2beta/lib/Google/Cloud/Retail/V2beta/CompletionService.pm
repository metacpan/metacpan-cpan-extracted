package Google::Cloud::Retail::V2beta::CompletionService;

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
    eval { require Google::Cloud::Retail::V2beta::Common };
    eval { require Google::Cloud::Retail::V2beta::ImportConfig };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9jb21wbGV0aW9uX3NlcnZpY2UucHJvdG8S
Gmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL3JldGFp
bC92MmJldGEvY29tbW9uLnByb3RvGi5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9pbXBv
cnRfY29uZmlnLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90byL2
AgoUQ29tcGxldGVRdWVyeVJlcXVlc3QSPwoHY2F0YWxvZxgBIAEoCUIl4EEC+kEfCh1yZXRh
aWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IHY2F0YWxvZxIZCgVxdWVyeRgCIAEoCUID4EEC
UgVxdWVyeRIdCgp2aXNpdG9yX2lkGAcgASgJUgl2aXNpdG9ySWQSJQoObGFuZ3VhZ2VfY29k
ZXMYAyADKAlSDWxhbmd1YWdlQ29kZXMSHwoLZGV2aWNlX3R5cGUYBCABKAlSCmRldmljZVR5
cGUSGAoHZGF0YXNldBgGIAEoCVIHZGF0YXNldBInCg9tYXhfc3VnZ2VzdGlvbnMYBSABKAVS
Dm1heFN1Z2dlc3Rpb25zEkAKHGVuYWJsZV9hdHRyaWJ1dGVfc3VnZ2VzdGlvbnMYCSABKAhS
GmVuYWJsZUF0dHJpYnV0ZVN1Z2dlc3Rpb25zEhYKBmVudGl0eRgKIAEoCVIGZW50aXR5Ir0H
ChVDb21wbGV0ZVF1ZXJ5UmVzcG9uc2UScQoSY29tcGxldGlvbl9yZXN1bHRzGAEgAygLMkIu
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29tcGxldGVRdWVyeVJlc3BvbnNlLkNvbXBs
ZXRpb25SZXN1bHRSEWNvbXBsZXRpb25SZXN1bHRzEisKEWF0dHJpYnV0aW9uX3Rva2VuGAIg
ASgJUhBhdHRyaWJ1dGlvblRva2VuEnwKFXJlY2VudF9zZWFyY2hfcmVzdWx0cxgDIAMoCzJE
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkNvbXBsZXRlUXVlcnlSZXNwb25zZS5SZWNl
bnRTZWFyY2hSZXN1bHRCAhgBUhNyZWNlbnRTZWFyY2hSZXN1bHRzEnQKEWF0dHJpYnV0ZV9y
ZXN1bHRzGAQgAygLMkcuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29tcGxldGVRdWVy
eVJlc3BvbnNlLkF0dHJpYnV0ZVJlc3VsdHNFbnRyeVIQYXR0cmlidXRlUmVzdWx0cxqSAgoQ
Q29tcGxldGlvblJlc3VsdBIeCgpzdWdnZXN0aW9uGAEgASgJUgpzdWdnZXN0aW9uEnIKCmF0
dHJpYnV0ZXMYAiADKAsyUi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Db21wbGV0ZVF1
ZXJ5UmVzcG9uc2UuQ29tcGxldGlvblJlc3VsdC5BdHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0
ZXMaagoPQXR0cmlidXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkEKBXZhbHVlGAIgASgL
MisuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ3VzdG9tQXR0cmlidXRlUgV2YWx1ZToC
OAEaPQoSUmVjZW50U2VhcmNoUmVzdWx0EiMKDXJlY2VudF9zZWFyY2gYASABKAlSDHJlY2Vu
dFNlYXJjaDoCGAEaMwoPQXR0cmlidXRlUmVzdWx0EiAKC3N1Z2dlc3Rpb25zGAEgAygJUgtz
dWdnZXN0aW9ucxqGAQoVQXR0cmlidXRlUmVzdWx0c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
ElcKBXZhbHVlGAIgASgLMkEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29tcGxldGVR
dWVyeVJlc3BvbnNlLkF0dHJpYnV0ZVJlc3VsdFIFdmFsdWU6AjgBMs4EChFDb21wbGV0aW9u
U2VydmljZRK/AQoNQ29tcGxldGVRdWVyeRIwLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRh
LkNvbXBsZXRlUXVlcnlSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29t
cGxldGVRdWVyeVJlc3BvbnNlIkmC0+STAkMSQS92MmJldGEve2NhdGFsb2c9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfTpjb21wbGV0ZVF1ZXJ5EqsCChRJbXBvcnRDb21w
bGV0aW9uRGF0YRI3Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkltcG9ydENvbXBsZXRp
b25EYXRhUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iugGC0+STAk0i
SC92MmJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L2Nv
bXBsZXRpb25EYXRhOmltcG9ydDoBKspBZAo3Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEu
SW1wb3J0Q29tcGxldGlvbkRhdGFSZXNwb25zZRIpZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuSW1wb3J0TWV0YWRhdGEaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C1QEKHmNvbS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YUIWQ29tcGxldGlvblNlcnZpY2VQcm90b1ABWjZjbG91ZC5n
b29nbGUuY29tL2dvL3JldGFpbC9hcGl2MmJldGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRB
SUyqAhpHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQmV0YcoCGkdvb2dsZVxDbG91ZFxSZXRhaWxc
VjJiZXRh6gIdR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMmJldGFKxkMKBxIFDgD4AQEKvAQK
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
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAJgoJ
CgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAxCgkKAgMFEgMXADgK
CQoCAwYSAxgALQoICgEIEgMaADcKCQoCCCUSAxoANwoICgEIEgMbAE0KCQoCCAsSAxsATQoI
CgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADcKCQoCCAgSAx0ANwoICgEIEgMeADcKCQoC
CAESAx4ANwoICgEIEgMfACQKCQoCCCQSAx8AJAoICgEIEgMgADcKCQoCCCkSAyAANwoICgEI
EgMhADYKCQoCCC0SAyEANgq8AQoCBgASBCcASgEarwEgQXV0b2NvbXBsZXRlIHNlcnZpY2Ug
Zm9yIHJldGFpbC4KCiBUaGlzIGZlYXR1cmUgaXMgb25seSBhdmFpbGFibGUgZm9yIHVzZXJz
IHdobyBoYXZlIFJldGFpbCBTZWFyY2ggZW5hYmxlZC4KIEVuYWJsZSBSZXRhaWwgU2VhcmNo
IG9uIENsb3VkIENvbnNvbGUgYmVmb3JlIHVzaW5nIHRoaXMgZmVhdHVyZS4KCgoKAwYAARID
JwgZCgoKAwYAAxIDKAI9CgwKBQYAA5kIEgMoAj0KCwoDBgADEgQpAio3Cg0KBQYAA5oIEgQp
Aio3CtYBCgQGAAIAEgQwAjQDGscBIENvbXBsZXRlcyB0aGUgc3BlY2lmaWVkIHByZWZpeCB3
aXRoIGtleXdvcmQgc3VnZ2VzdGlvbnMuCgogVGhpcyBmZWF0dXJlIGlzIG9ubHkgYXZhaWxh
YmxlIGZvciB1c2VycyB3aG8gaGF2ZSBSZXRhaWwgU2VhcmNoIGVuYWJsZWQuCiBFbmFibGUg
UmV0YWlsIFNlYXJjaCBvbiBDbG91ZCBDb25zb2xlIGJlZm9yZSB1c2luZyB0aGlzIGZlYXR1
cmUuCgoMCgUGAAIAARIDMAYTCgwKBQYAAgACEgMwFCgKDAoFBgACAAMSAzAzSAoNCgUGAAIA
BBIEMQQzBgoRCgkGAAIABLDKvCISBDEEMwYKqgMKBAYAAgESBD8CSQMamwMgQnVsayBpbXBv
cnQgb2YgcHJvY2Vzc2VkIGNvbXBsZXRpb24gZGF0YXNldC4KCiBSZXF1ZXN0IHByb2Nlc3Np
bmcgaXMgYXN5bmNocm9ub3VzLiBQYXJ0aWFsIHVwZGF0aW5nIGlzIG5vdCBzdXBwb3J0ZWQu
CgogVGhlIG9wZXJhdGlvbiBpcyBzdWNjZXNzZnVsbHkgZmluaXNoZWQgb25seSBhZnRlciB0
aGUgaW1wb3J0ZWQgc3VnZ2VzdGlvbnMKIGFyZSBpbmRleGVkIHN1Y2Nlc3NmdWxseSBhbmQg
cmVhZHkgZm9yIHNlcnZpbmcuIFRoZSBwcm9jZXNzIHRha2VzIGhvdXJzLgoKIFRoaXMgZmVh
dHVyZSBpcyBvbmx5IGF2YWlsYWJsZSBmb3IgdXNlcnMgd2hvIGhhdmUgUmV0YWlsIFNlYXJj
aCBlbmFibGVkLgogRW5hYmxlIFJldGFpbCBTZWFyY2ggb24gQ2xvdWQgQ29uc29sZSBiZWZv
cmUgdXNpbmcgdGhpcyBmZWF0dXJlLgoKDAoFBgACAQESAz8GGgoMCgUGAAIBAhIDPxs2CgwK
BQYAAgEDEgNADysKDQoFBgACAQQSBEEERAYKEQoJBgACAQSwyrwiEgRBBEQGCg0KBQYAAgEE
EgRFBEgGCg8KBwYAAgEEmQgSBEUESAYKJwoCBAASBU0AqwEBGhogQXV0b2NvbXBsZXRlIHBh
cmFtZXRlcnMuCgoKCgMEAAESA00IHAqrAQoEBAACABIEUgJVBBqcASBSZXF1aXJlZC4gQ2F0
YWxvZyBmb3Igd2hpY2ggdGhlIGNvbXBsZXRpb24gaXMgcGVyZm9ybWVkLgoKIEZ1bGwgcmVz
b3VyY2UgbmFtZSBvZiBjYXRhbG9nLCBzdWNoIGFzCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMv
Z2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxvZ2AuCgoMCgUEAAIABRIDUgIICgwKBQQA
AgABEgNSCRAKDAoFBAACAAMSA1ITFAoNCgUEAAIACBIEUhVVAwoPCggEAAIACJwIABIDUwQq
Cg4KBwQAAgAInwgSA1QETwpzCgQEAAIBEgNaAjwaZiBSZXF1aXJlZC4gVGhlIHF1ZXJ5IHVz
ZWQgdG8gZ2VuZXJhdGUgc3VnZ2VzdGlvbnMuCgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFs
bG93ZWQgY2hhcmFjdGVycyBpcyAyNTUuCgoMCgUEAAIBBRIDWgIICgwKBQQAAgEBEgNaCQ4K
DAoFBAACAQMSA1oREgoMCgUEAAIBCBIDWhM7Cg8KCAQAAgEInAgAEgNaFDoKsAMKBAQAAgIS
A2MCGBqiAyBSZWNvbW1lbmRlZCBmaWVsZC4gQSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdHJh
Y2tpbmcgdmlzaXRvcnMuIEZvciBleGFtcGxlLAogdGhpcyBjb3VsZCBiZSBpbXBsZW1lbnRl
ZCB3aXRoIGFuIEhUVFAgY29va2llLCB3aGljaCBzaG91bGQgYmUgYWJsZSB0bwogdW5pcXVl
bHkgaWRlbnRpZnkgYSB2aXNpdG9yIG9uIGEgc2luZ2xlIGRldmljZS4gVGhpcyB1bmlxdWUg
aWRlbnRpZmllcgogc2hvdWxkIG5vdCBjaGFuZ2UgaWYgdGhlIHZpc2l0b3IgbG9ncyBpbiBv
ciBvdXQgb2YgdGhlIHdlYnNpdGUuCgogVGhlIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNv
ZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3Ro
ZXJ3aXNlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDAoFBAAC
AgUSA2MCCAoMCgUEAAICARIDYwkTCgwKBQQAAgIDEgNjFhcKpQQKBAQAAgMSA24CJRqXBCBO
b3RlIHRoYXQgdGhpcyBmaWVsZCBhcHBsaWVzIGZvciBgdXNlci1kYXRhYCBkYXRhc2V0IG9u
bHkuIEZvciByZXF1ZXN0cwogd2l0aCBgY2xvdWQtcmV0YWlsYCBkYXRhc2V0LCBzZXR0aW5n
IHRoaXMgZmllbGQgaGFzIG5vIGVmZmVjdC4KCiBUaGUgbGFuZ3VhZ2UgZmlsdGVycyBhcHBs
aWVkIHRvIHRoZSBvdXRwdXQgc3VnZ2VzdGlvbnMuIElmIHNldCwgaXQgc2hvdWxkCiBjb250
YWluIHRoZSBsYW5ndWFnZSBvZiB0aGUgcXVlcnkuIElmIG5vdCBzZXQsIHN1Z2dlc3Rpb25z
IGFyZSByZXR1cm5lZAogd2l0aG91dCBjb25zaWRlcmluZyBsYW5ndWFnZSByZXN0cmljdGlv
bnMuIFRoaXMgaXMgdGhlIEJDUC00NyBsYW5ndWFnZQogY29kZSwgc3VjaCBhcyAiZW4tVVMi
IG9yICJzci1MYXRuIi4gRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSBbVGFncyBmb3IKIElk
ZW50aWZ5aW5nIExhbmd1YWdlc10oaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL2JjcDQ3
KS4gVGhlIG1heGltdW0KIG51bWJlciBvZiBsYW5ndWFnZSBjb2RlcyBpcyAzLgoKDAoFBAAC
AwQSA24CCgoMCgUEAAIDBRIDbgsRCgwKBQQAAgMBEgNuEiAKDAoFBAACAwMSA24jJAqZAwoE
BAACBBIEgAECGRqKAyBUaGUgZGV2aWNlIHR5cGUgY29udGV4dCBmb3IgY29tcGxldGlvbiBz
dWdnZXN0aW9ucy4gV2UgcmVjb21tZW5kIHRoYXQgeW91CiBsZWF2ZSB0aGlzIGZpZWxkIGVt
cHR5LgoKIEl0IGNhbiBhcHBseSBkaWZmZXJlbnQgc3VnZ2VzdGlvbnMgb24gZGlmZmVyZW50
IGRldmljZSB0eXBlcywgZS5nLgogYERFU0tUT1BgLCBgTU9CSUxFYC4gSWYgaXQgaXMgZW1w
dHksIHRoZSBzdWdnZXN0aW9ucyBhcmUgYWNyb3NzIGFsbCBkZXZpY2UKIHR5cGVzLgoKIFN1
cHBvcnRlZCBmb3JtYXRzOgoKICogYFVOS05PV05fREVWSUNFX1RZUEVgCgogKiBgREVTS1RP
UGAKCiAqIGBNT0JJTEVgCgogKiBBIGN1c3RvbWl6ZWQgc3RyaW5nIHN0YXJ0cyB3aXRoIGBP
VEhFUl9gLCBlLmcuIGBPVEhFUl9JUEhPTkVgLgoKDQoFBAACBAUSBIABAggKDQoFBAACBAES
BIABCRQKDQoFBAACBAMSBIABFxgK8QQKBAQAAgUSBJABAhUa4gQgRGV0ZXJtaW5lcyB3aGlj
aCBkYXRhc2V0IHRvIHVzZSBmb3IgZmV0Y2hpbmcgY29tcGxldGlvbi4gInVzZXItZGF0YSIg
d2lsbAogdXNlIHRoZSBkYXRhc2V0IGltcG9ydGVkIHRocm91Z2gKIFtDb21wbGV0aW9uU2Vy
dmljZS5JbXBvcnRDb21wbGV0aW9uRGF0YV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEu
Q29tcGxldGlvblNlcnZpY2UuSW1wb3J0Q29tcGxldGlvbkRhdGFdLgogYGNsb3VkLXJldGFp
bGAgd2lsbCB1c2UgdGhlIGRhdGFzZXQgZ2VuZXJhdGVkIGJ5IENsb3VkIFJldGFpbCBiYXNl
ZCBvbiB1c2VyCiBldmVudHMuIElmIGxlZnQgZW1wdHksIGNvbXBsZXRpb25zIHdpbGwgYmUg
ZmV0Y2hlZCBmcm9tIHRoZSBgdXNlci1kYXRhYAogZGF0YXNldC4KCiBDdXJyZW50IHN1cHBv
cnRlZCB2YWx1ZXM6CgogKiB1c2VyLWRhdGEKCiAqIGNsb3VkLXJldGFpbDoKICAgVGhpcyBv
cHRpb24gcmVxdWlyZXMgZW5hYmxpbmcgYXV0by1sZWFybmluZyBmdW5jdGlvbiBmaXJzdC4g
U2VlCiAgIFtndWlkZWxpbmVzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2Rv
Y3MvY29tcGxldGlvbi1vdmVydmlldyNnZW5lcmF0ZWQtY29tcGxldGlvbi1kYXRhc2V0KS4K
Cg0KBQQAAgUFEgSQAQIICg0KBQQAAgUBEgSQAQkQCg0KBQQAAgUDEgSQARMUCrECCgQEAAIG
EgSYAQIcGqICIENvbXBsZXRpb24gbWF4IHN1Z2dlc3Rpb25zLiBJZiBsZWZ0IHVuc2V0IG9y
IHNldCB0byAwLCB0aGVuIHdpbGwgZmFsbGJhY2sKIHRvIHRoZSBjb25maWd1cmVkIHZhbHVl
CiBbQ29tcGxldGlvbkNvbmZpZy5tYXhfc3VnZ2VzdGlvbnNdW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLkNvbXBsZXRpb25Db25maWcubWF4X3N1Z2dlc3Rpb25zXS4KCiBUaGUgbWF4
aW11bSBhbGxvd2VkIG1heCBzdWdnZXN0aW9ucyBpcyAyMC4gSWYgaXQgaXMgc2V0IGhpZ2hl
ciwgaXQgd2lsbCBiZQogY2FwcGVkIGJ5IDIwLgoKDQoFBAACBgUSBJgBAgcKDQoFBAACBgES
BJgBCBcKDQoFBAACBgMSBJgBGhsKmAEKBAQAAgcSBJ0BAigaiQEgSWYgdHJ1ZSwgYXR0cmli
dXRlIHN1Z2dlc3Rpb25zIGFyZSBlbmFibGVkIGFuZCBwcm92aWRlZCBpbiB0aGUgcmVzcG9u
c2UuCgogVGhpcyBmaWVsZCBpcyBvbmx5IGF2YWlsYWJsZSBmb3IgdGhlIGBjbG91ZC1yZXRh
aWxgIGRhdGFzZXQuCgoNCgUEAAIHBRIEnQECBgoNCgUEAAIHARIEnQEHIwoNCgUEAAIHAxIE
nQEmJwqyBQoEBAACCBIEqgECFRqjBSBUaGUgZW50aXR5IGZvciBjdXN0b21lcnMgd2hvIHJ1
biBtdWx0aXBsZSBlbnRpdGllcywgZG9tYWlucywgc2l0ZXMsIG9yCiByZWdpb25zLCBmb3Ig
ZXhhbXBsZSwgYEdvb2dsZSBVU2AsIGBHb29nbGUgQWRzYCwgYFdheW1vYCwKIGBnb29nbGUu
Y29tYCwgYHlvdXR1YmUuY29tYCwgZXRjLgogSWYgdGhpcyBpcyBzZXQsIGl0IG11c3QgYmUg
YW4gZXhhY3QgbWF0Y2ggd2l0aAogW1VzZXJFdmVudC5lbnRpdHldW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJiZXRhLlVzZXJFdmVudC5lbnRpdHldIHRvIGdldAogcGVyLWVudGl0eSBhdXRv
Y29tcGxldGUgcmVzdWx0cy4gVGhpcyBmaWVsZCB3aWxsIGJlIGFwcGxpZWQgdG8KIGBjb21w
bGV0aW9uX3Jlc3VsdHNgIG9ubHkuIEl0IGhhcyBubyBlZmZlY3Qgb24gdGhlIGBhdHRyaWJ1
dGVfcmVzdWx0c2AuCiBBbHNvLCB0aGlzIGVudGl0eSBzaG91bGQgYmUgbGltaXRlZCB0byAy
NTYgY2hhcmFjdGVycywgaWYgdG9vIGxvbmcsIGl0IHdpbGwKIGJlIHRydW5jYXRlZCB0byAy
NTYgY2hhcmFjdGVycyBpbiBib3RoIGdlbmVyYXRpb24gYW5kIHNlcnZpbmcgdGltZSwgYW5k
IG1heQogbGVhZCB0byBtaXMtbWF0Y2guIFRvIGVuc3VyZSBpdCB3b3JrcywgcGxlYXNlIHNl
dCB0aGUgZW50aXR5IHdpdGggc3RyaW5nCiB3aXRoaW4gMjU2IGNoYXJhY3RlcnMuCgoNCgUE
AAIIBRIEqgECCAoNCgUEAAIIARIEqgEJDwoNCgUEAAIIAxIEqgESFAozCgIEARIGrgEA+AEB
GiUgUmVzcG9uc2Ugb2YgdGhlIGF1dG9jb21wbGV0ZSBxdWVyeS4KCgsKAwQBARIErgEIHQo+
CgQEAQMAEgawAQK+AQMaLiBSZXNvdXJjZSB0aGF0IHJlcHJlc2VudHMgY29tcGxldGlvbiBy
ZXN1bHRzLgoKDQoFBAEDAAESBLABChoKLwoGBAEDAAIAEgSyAQQaGh8gVGhlIHN1Z2dlc3Rp
b24gZm9yIHRoZSBxdWVyeS4KCg8KBwQBAwACAAUSBLIBBAoKDwoHBAEDAAIAARIEsgELFQoP
CgcEAQMAAgADEgSyARgZCu4CCgYEAQMAAgESBL0BBDAa3QIgQ3VzdG9tIGF0dHJpYnV0ZXMg
Zm9yIHRoZSBzdWdnZXN0aW9uIHRlcm0uCgogKiBGb3IgYHVzZXItZGF0YWAsIHRoZSBhdHRy
aWJ1dGVzIGFyZSBhZGRpdGlvbmFsIGN1c3RvbSBhdHRyaWJ1dGVzCiBpbmdlc3RlZCB0aHJv
dWdoIEJpZ1F1ZXJ5LgoKICogRm9yIGBjbG91ZC1yZXRhaWxgLCB0aGUgYXR0cmlidXRlcyBh
cmUgcHJvZHVjdCBhdHRyaWJ1dGVzIGdlbmVyYXRlZAogYnkgQ2xvdWQgUmV0YWlsLiBJdCBy
ZXF1aXJlcwogW1VzZXJFdmVudC5wcm9kdWN0X2RldGFpbHNdW2dvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLlVzZXJFdmVudC5wcm9kdWN0X2RldGFpbHNdCiBpcyBpbXBvcnRlZCBwcm9w
ZXJseS4KCg8KBwQBAwACAQYSBL0BBCAKDwoHBAEDAAIBARIEvQEhKwoPCgcEAQMAAgEDEgS9
AS4vCjkKBAQBAwESBsEBAsYBAxopIERlcHJlY2F0ZWQ6IFJlY2VudCBzZWFyY2ggb2YgdGhp
cyB1c2VyLgoKDQoFBAEDAQESBMEBChwKDQoFBAEDAQcSBMIBBB0KDgoGBAEDAQcDEgTCAQQd
CioKBgQBAwECABIExQEEHRoaIFRoZSByZWNlbnQgc2VhcmNoIHF1ZXJ5LgoKDwoHBAEDAQIA
BRIExQEECgoPCgcEAQMBAgABEgTFAQsYCg8KBwQBAwECAAMSBMUBGxwKPQoEBAEDAhIGyQEC
zAEDGi0gUmVzb3VyY2UgdGhhdCByZXByZXNlbnRzIGF0dHJpYnV0ZSByZXN1bHRzLgoKDQoF
BAEDAgESBMkBChkKPAoGBAEDAgIAEgTLAQQkGiwgVGhlIGxpc3Qgb2Ygc3VnZ2VzdGlvbnMg
Zm9yIHRoZSBhdHRyaWJ1dGUuCgoPCgcEAQMCAgAEEgTLAQQMCg8KBwQBAwICAAUSBMsBDRMK
DwoHBAEDAgIAARIEywEUHwoPCgcEAQMCAgADEgTLASIjCngKBAQBAgASBNABAjMaaiBSZXN1
bHRzIG9mIHRoZSBtYXRjaGluZyBzdWdnZXN0aW9ucy4gVGhlIHJlc3VsdCBsaXN0IGlzIG9y
ZGVyZWQgYW5kIHRoZQogZmlyc3QgcmVzdWx0IGlzIHRvcCBzdWdnZXN0aW9uLgoKDQoFBAEC
AAQSBNABAgoKDQoFBAECAAYSBNABCxsKDQoFBAECAAESBNABHC4KDQoFBAECAAMSBNABMTIK
lQIKBAQBAgESBNYBAh8ahgIgQSB1bmlxdWUgY29tcGxldGUgdG9rZW4uIFRoaXMgc2hvdWxk
IGJlIGluY2x1ZGVkIGluIHRoZQogW1VzZXJFdmVudC5jb21wbGV0aW9uX2RldGFpbF1bZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEuVXNlckV2ZW50LmNvbXBsZXRpb25fZGV0YWlsXQog
Zm9yIHNlYXJjaCBldmVudHMgcmVzdWx0aW5nIGZyb20gdGhpcyBjb21wbGV0aW9uLCB3aGlj
aCBlbmFibGVzIGFjY3VyYXRlCiBhdHRyaWJ1dGlvbiBvZiBjb21wbGV0ZSBtb2RlbCBwZXJm
b3JtYW5jZS4KCg0KBQQBAgEFEgTWAQIICg0KBQQBAgEBEgTWAQkaCg0KBQQBAgEDEgTWAR0e
Cq8GCgQEAQICEgTtAQJMGqAGIERlcHJlY2F0ZWQuIE1hdGNoZWQgcmVjZW50IHNlYXJjaGVz
IG9mIHRoaXMgdXNlci4gVGhlIG1heGltdW0gbnVtYmVyIG9mCiByZWNlbnQgc2VhcmNoZXMg
aXMgMTAuIFRoaXMgZmllbGQgaXMgYSByZXN0cmljdGVkIGZlYXR1cmUuIElmIHlvdSB3YW50
IHRvCiBlbmFibGUgaXQsIGNvbnRhY3QgUmV0YWlsIFNlYXJjaCBzdXBwb3J0LgoKIFRoaXMg
ZmVhdHVyZSBpcyBvbmx5IGF2YWlsYWJsZSB3aGVuCiBbQ29tcGxldGVRdWVyeVJlcXVlc3Qu
dmlzaXRvcl9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQ29tcGxldGVRdWVyeVJl
cXVlc3QudmlzaXRvcl9pZF0KIGZpZWxkIGlzIHNldCBhbmQgW1VzZXJFdmVudF1bZ29vZ2xl
LmNsb3VkLnJldGFpbC52MmJldGEuVXNlckV2ZW50XSBpcwogaW1wb3J0ZWQuIFRoZSByZWNl
bnQgc2VhcmNoZXMgc2F0aXNmeSB0aGUgZm9sbG93IHJ1bGVzOgoKICAqIFRoZXkgYXJlIG9y
ZGVyZWQgZnJvbSBsYXRlc3QgdG8gb2xkZXN0LgoKICAqIFRoZXkgYXJlIG1hdGNoZWQgd2l0
aAogIFtDb21wbGV0ZVF1ZXJ5UmVxdWVzdC5xdWVyeV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuQ29tcGxldGVRdWVyeVJlcXVlc3QucXVlcnldCiAgY2FzZSBpbnNlbnNpdGl2ZWx5
LgoKICAqIFRoZXkgYXJlIHRyYW5zZm9ybWVkIHRvIGxvd2VyIGNhc2UuCgogICogVGhleSBh
cmUgVVRGLTggc2FmZS4KCiBSZWNlbnQgc2VhcmNoZXMgYXJlIGRlZHVwbGljYXRlZC4gTW9y
ZSByZWNlbnQgc2VhcmNoZXMgd2lsbCBiZSByZXNlcnZlZAogd2hlbiBkdXBsaWNhdGlvbiBo
YXBwZW5zLgoKDQoFBAECAgQSBO0BAgoKDQoFBAECAgYSBO0BCx0KDQoFBAECAgESBO0BHjMK
DQoFBAECAgMSBO0BNjcKDQoFBAECAggSBO0BOEsKDgoGBAECAggDEgTtATlKCqoBCgQEAQID
EgT3AQI1GpsBIEEgbWFwIG9mIG1hdGNoZWQgYXR0cmlidXRlIHN1Z2dlc3Rpb25zLiBUaGlz
IGZpZWxkIGlzIG9ubHkgYXZhaWxhYmxlIGZvcgogYGNsb3VkLXJldGFpbGAgZGF0YXNldC4K
CiBDdXJyZW50IHN1cHBvcnRlZCBrZXlzOgoKICogYGJyYW5kc2AKCiAqIGBjYXRlZ29yaWVz
YAoKDQoFBAECAwYSBPcBAh4KDQoFBAECAwESBPcBHzAKDQoFBAECAwMSBPcBMzRiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest ===
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

# === Message: Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse ===
    # Fields for CompleteQueryResponse
    # Field: completion_results Type: 11 (.google.cloud.retail.v2beta.CompleteQueryResponse.CompletionResult)
    # Field: attribution_token Type: 9 ()
    # Field: recent_search_results Type: 11 (.google.cloud.retail.v2beta.CompleteQueryResponse.RecentSearchResult)
    # Field: attribute_results Type: 11 (.google.cloud.retail.v2beta.CompleteQueryResponse.AttributeResultsEntry)

# === Service Client: Google::Cloud::Retail::V2beta::CompletionService::CompletionServiceClient ===
package Google::Cloud::Retail::V2beta::CompletionService::CompletionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::CompletionService::CompletionServiceClient

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
        ? Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.CompletionService',
        method         => 'CompleteQuery',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse',
    });
}

sub import_completion_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ImportConfig::ImportCompletionDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.CompletionService',
        method         => 'ImportCompletionData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::CompletionService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/completion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::CompletionService;

    my $msg = Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest->new({
        catalog => $catalog,
        query => $query,
        visitor_id => $visitor_id,
        language_codes => $language_codes,
    });

    # Read or update a field
    my $val = $msg->catalog();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/completion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest

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
[CompletionService.ImportCompletionData][google.cloud.retail.v2beta.CompletionService.ImportCompletionData].
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
[CompletionConfig.max_suggestions][google.cloud.retail.v2beta.CompletionConfig.max_suggestions].

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
[UserEvent.entity][google.cloud.retail.v2beta.UserEvent.entity] to get
per-entity autocomplete results. This field will be applied to
`completion_results` only. It has no effect on the `attribute_results`.
Also, this entity should be limited to 256 characters, if too long, it will
be truncated to 256 characters in both generation and serving time, and may
lead to mis-match. To ensure it works, please set the entity with string
within 256 characters.

=back

=head2 Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse

Response of the autocomplete query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_results() >> / C<< $msg->completion_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse::CompletionResult>)

Results of the matching suggestions. The result list is ordered and the
first result is top suggestion.

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique complete token. This should be included in the
[UserEvent.completion_detail][google.cloud.retail.v2beta.UserEvent.completion_detail]
for search events resulting from this completion, which enables accurate
attribution of complete model performance.

=item * C<< $msg->recent_search_results() >> / C<< $msg->recent_search_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse::RecentSearchResult>)

Deprecated. Matched recent searches of this user. The maximum number of
recent searches is 10. This field is a restricted feature. If you want to
enable it, contact Retail Search support.

This feature is only available when
[CompleteQueryRequest.visitor_id][google.cloud.retail.v2beta.CompleteQueryRequest.visitor_id]
field is set and [UserEvent][google.cloud.retail.v2beta.UserEvent] is
imported. The recent searches satisfy the follow rules:

 * They are ordered from latest to oldest.

 * They are matched with
 [CompleteQueryRequest.query][google.cloud.retail.v2beta.CompleteQueryRequest.query]
 case insensitively.

 * They are transformed to lower case.

 * They are UTF-8 safe.

Recent searches are deduplicated. More recent searches will be reserved
when duplication happens.

=item * C<< $msg->attribute_results() >> / C<< $msg->attribute_results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse::AttributeResultsEntry>)

A map of matched attribute suggestions. This field is only available for
`cloud-retail` dataset.

Current supported keys:

* `brands`

* `categories`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::CompletionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
