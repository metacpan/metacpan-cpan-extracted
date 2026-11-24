package Google::Cloud::Discoveryengine::V1beta::Session;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Answer };
    eval { require Google::Cloud::Discoveryengine::V1beta::AssistAnswer };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zZXNzaW9uLnByb3RvEiNn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxowZ29vZ2xlL2Nsb3Vk
L2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvYW5zd2VyLnByb3RvGjdnb29nbGUvY2xvdWQvZGlz
Y292ZXJ5ZW5naW5lL3YxYmV0YS9hc3Npc3RfYW5zd2VyLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIuEMCgdTZXNzaW9uEhcKBG5hbWUYASABKAlCA+BBBVIEbmFt
ZRImCgxkaXNwbGF5X25hbWUYByABKAlCA+BBAVILZGlzcGxheU5hbWUSSAoFc3RhdGUYAiAB
KA4yMi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZXNzaW9uLlN0YXRl
UgVzdGF0ZRIkCg51c2VyX3BzZXVkb19pZBgDIAEoCVIMdXNlclBzZXVkb0lkEkcKBXR1cm5z
GAQgAygLMjEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2Vzc2lvbi5U
dXJuUgV0dXJucxIbCgZsYWJlbHMYCSADKAlCA+BBAVIGbGFiZWxzEj4KCnN0YXJ0X3RpbWUY
BSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRI6Cghl
bmRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGlt
ZRIgCglpc19waW5uZWQYCCABKAhCA+BBAVIIaXNQaW5uZWQSTQohcGVuZGluZ19hc3luY19h
c3Npc3Rfb3BlcmF0aW9uX2lkGBYgASgJQgPgQQNSHXBlbmRpbmdBc3luY0Fzc2lzdE9wZXJh
dGlvbklkGqIECgRUdXJuEkUKBXF1ZXJ5GAEgASgLMiouZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuUXVlcnlCA+BBAVIFcXVlcnkSRQoGYW5zd2VyGAIgASgJQi3gQQH6
QScKJWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9BbnN3ZXJSBmFuc3dlchJZCg9k
ZXRhaWxlZF9hbnN3ZXIYByABKAsyKy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5BbnN3ZXJCA+BBA1IOZGV0YWlsZWRBbnN3ZXISbAoWZGV0YWlsZWRfYXNzaXN0X2Fu
c3dlchgIIAEoCzIxLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkFzc2lz
dEFuc3dlckID4EEDUhRkZXRhaWxlZEFzc2lzdEFuc3dlchJqCgxxdWVyeV9jb25maWcYECAD
KAsyQi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZXNzaW9uLlR1cm4u
UXVlcnlDb25maWdFbnRyeUID4EEBUgtxdWVyeUNvbmZpZxIXCgRsaXZlGBQgASgIQgPgQQFS
BGxpdmUaPgoQUXVlcnlDb25maWdFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBIi8KBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDwoLSU5f
UFJPR1JFU1MQATr7A+pB9wMKJmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9TZXNz
aW9uElJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jl
cy97ZGF0YV9zdG9yZX0vc2Vzc2lvbnMve3Nlc3Npb259Emtwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9y
ZXMve2RhdGFfc3RvcmV9L3Nlc3Npb25zL3tzZXNzaW9ufRJkcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9lbmdpbmVz
L3tlbmdpbmV9L3Nlc3Npb25zL3tzZXNzaW9ufRKSAXByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5n
aW5lfS9jb2xsYWJvcmF0aXZlUHJvamVjdHMve2NvbGxhYm9yYXRpdmVfcHJvamVjdH0vc2Vz
c2lvbnMve3Nlc3Npb259KghzZXNzaW9uczIHc2Vzc2lvbiJICgVRdWVyeRIUCgR0ZXh0GAIg
ASgJSABSBHRleHQSHgoIcXVlcnlfaWQYASABKAlCA+BBA1IHcXVlcnlJZEIJCgdjb250ZW50
QpMCCidjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCDFNlc3Npb25Q
cm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEv
ZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWq
AiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxE
aXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5l
OjpWMWJldGFKoigKBxIFDgCZAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADoKCQoCAwMSAxUA
QQoJCgIDBBIDFgApCggKAQgSAxgAQAoJCgIIJRIDGABACggKAQgSAxkAaAoJCgIICxIDGQBo
CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAQAoJ
CgIIARIDHABACggKAQgSAx0ALQoJCgIIJBIDHQAtCggKAQgSAx4AQAoJCgIIKRIDHgBACggK
AQgSAx8APwoJCgIILRIDHwA/CjEKAgQAEgUiAI0BARokIEV4dGVybmFsIHNlc3Npb24gcHJv
dG8gZGVmaW5pdGlvbi4KCgoKAwQAARIDIggPCgsKAwQABxIEIwIrBAoNCgUEAAedCBIEIwIr
BApeCgQEAAMAEgQvAlkDGlAgUmVwcmVzZW50cyBhIHR1cm4sIGluY2x1ZGluZyBhIHF1ZXJ5
IGZyb20gdGhlIHVzZXIgYW5kIGEKIGFuc3dlciBmcm9tIHNlcnZpY2UuCgoMCgUEAAMAARID
LwoOCnwKBgQAAwACABIDMgQ9Gm0gT3B0aW9uYWwuIFRoZSB1c2VyIHF1ZXJ5LiBNYXkgbm90
IGJlIHNldCBpZiB0aGlzIHR1cm4gaXMgbWVyZWx5CiByZWdlbmVyYXRpbmcgYW4gYW5zd2Vy
IHRvIGEgZGlmZmVyZW50IHR1cm4KCg4KBwQAAwACAAYSAzIECQoOCgcEAAMAAgABEgMyCg8K
DgoHBAADAAIAAxIDMhITCg4KBwQAAwACAAgSAzIUPAoRCgoEAAMAAgAInAgAEgMyFTsKngEK
BgQAAwACARIEOAQ9BhqNASBPcHRpb25hbC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGFu
c3dlciB0byB0aGUgdXNlciBxdWVyeS4KCiBPbmx5IHNldCBpZiB0aGUgYW5zd2VyIGdlbmVy
YXRpb24gKC9hbnN3ZXIgQVBJIGNhbGwpIGhhcHBlbmVkIGluIHRoaXMKIHR1cm4uCgoOCgcE
AAMAAgEFEgM4BAoKDgoHBAADAAIBARIDOAsRCg4KBwQAAwACAQMSAzgUFQoPCgcEAAMAAgEI
EgQ4Fj0FChEKCgQAAwACAQicCAASAzkGLAoRCgkEAAMAAgEInwgSBDoGPAcK7AIKBgQAAwAC
AhIDRQRLGtwCIE91dHB1dCBvbmx5LiBJbgogW0NvbnZlcnNhdGlvbmFsU2VhcmNoU2Vydmlj
ZS5HZXRTZXNzaW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Db252
ZXJzYXRpb25hbFNlYXJjaFNlcnZpY2UuR2V0U2Vzc2lvbl0KIEFQSSwgaWYKIFtHZXRTZXNz
aW9uUmVxdWVzdC5pbmNsdWRlX2Fuc3dlcl9kZXRhaWxzXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5HZXRTZXNzaW9uUmVxdWVzdC5pbmNsdWRlX2Fuc3dlcl9kZXRh
aWxzXQogaXMgc2V0IHRvIHRydWUsIHRoaXMgZmllbGQgd2lsbCBiZSBwb3B1bGF0ZWQgd2hl
biBnZXR0aW5nIGFuc3dlciBxdWVyeQogc2Vzc2lvbi4KCg4KBwQAAwACAgYSA0UECgoOCgcE
AAMAAgIBEgNFCxoKDgoHBAADAAICAxIDRR0eCg4KBwQAAwACAggSA0UfSgoRCgoEAAMAAgII
nAgAEgNFIEkK6gIKBgQAAwACAxIETQRONBrZAiBPdXRwdXQgb25seS4gSW4KIFtDb252ZXJz
YXRpb25hbFNlYXJjaFNlcnZpY2UuR2V0U2Vzc2lvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuQ29udmVyc2F0aW9uYWxTZWFyY2hTZXJ2aWNlLkdldFNlc3Npb25d
CiBBUEksIGlmCiBbR2V0U2Vzc2lvblJlcXVlc3QuaW5jbHVkZV9hbnN3ZXJfZGV0YWlsc11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuR2V0U2Vzc2lvblJlcXVlc3Qu
aW5jbHVkZV9hbnN3ZXJfZGV0YWlsc10KIGlzIHNldCB0byB0cnVlLCB0aGlzIGZpZWxkIHdp
bGwgYmUgcG9wdWxhdGVkIHdoZW4gZ2V0dGluZyBhc3Npc3RhbnQKIHNlc3Npb24uCgoOCgcE
AAMAAgMGEgNNBBAKDgoHBAADAAIDARIDTREnCg4KBwQAAwACAwMSA00qKwoOCgcEAAMAAgMI
EgNOCDMKEQoKBAADAAIDCJwIABIDTgkyCvkBCgYEAAMAAgQSBFQEVTEa6AEgT3B0aW9uYWwu
IFJlcHJlc2VudHMgbWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcXVlcnkgY29uZmlnLCBmb3Ig
ZXhhbXBsZQogTExNIG1vZGVsIGFuZCB2ZXJzaW9uIHVzZWQsIG1vZGVsIHBhcmFtZXRlcnMg
KHRlbXBlcmF0dXJlLCBncm91bmRpbmcKIHBhcmFtZXRlcnMsIGV0Yy4pLiBUaGUgcHJlZml4
ICJnb29nbGUuIiBpcyByZXNlcnZlZCBmb3IgR29vZ2xlLWRldmVsb3BlZAogZnVuY3Rpb25h
bGl0eS4KCg4KBwQAAwACBAYSA1QEFwoOCgcEAAMAAgQBEgNUGCQKDgoHBAADAAIEAxIDVCcp
Cg4KBwQAAwACBAgSA1UIMAoRCgoEAAMAAgQInAgAEgNVCS8KRgoGBAADAAIFEgNYBDwaNyBP
cHRpb25hbC4gSW5kaWNhdGVzIHdoZXRoZXIgdGhpcyB0dXJuIGlzIGEgbGl2ZSB0dXJuLgoK
DgoHBAADAAIFBRIDWAQICg4KBwQAAwACBQESA1gJDQoOCgcEAAMAAgUDEgNYEBIKDgoHBAAD
AAIFCBIDWBM7ChEKCgQAAwACBQicCAASA1gUOgo4CgQEAAQAEgRcAmIDGiogRW51bWVyYXRp
b24gb2YgdGhlIHN0YXRlIG9mIHRoZSBzZXNzaW9uLgoKDAoFBAAEAAESA1wHDAomCgYEAAQA
AgASA14EGhoXIFN0YXRlIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDXgQVCg4KBwQA
BAACAAISA14YGQovCgYEAAQAAgESA2EEFBogIFRoZSBzZXNzaW9uIGlzIGN1cnJlbnRseSBv
cGVuLgoKDgoHBAAEAAIBARIDYQQPCg4KBwQABAACAQISA2ESEwqKAQoEBAACABIDZgI8Gn0g
SW1tdXRhYmxlLiBGdWxseSBxdWFsaWZpZWQgbmFtZQogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMvZ2xvYmFsL2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdp
bmV9L3Nlc3Npb25zLypgCgoMCgUEAAIABRIDZgIICgwKBQQAAgABEgNmCQ0KDAoFBAACAAMS
A2YQEQoMCgUEAAIACBIDZhI7Cg8KCAQAAgAInAgAEgNmEzoKvQEKBAQAAgESA2wCQxqvASBP
cHRpb25hbC4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgc2Vzc2lvbi4KCiBUaGlzIGZpZWxk
IGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIHNlc3Npb24gaW4gdGhlIFVJLgogQnkgZGVmYXVs
dCwgdGhlIGRpc3BsYXkgbmFtZSBpcyB0aGUgZmlyc3QgdHVybiBxdWVyeSB0ZXh0IGluIHRo
ZSBzZXNzaW9uLgoKDAoFBAACAQUSA2wCCAoMCgUEAAIBARIDbAkVCgwKBQQAAgEDEgNsGBkK
DAoFBAACAQgSA2waQgoPCggEAAIBCJwIABIDbBtBCigKBAQAAgISA28CEhobIFRoZSBzdGF0
ZSBvZiB0aGUgc2Vzc2lvbi4KCgwKBQQAAgIGEgNvAgcKDAoFBAACAgESA28IDQoMCgUEAAIC
AxIDbxARCjYKBAQAAgMSA3ICHBopIEEgdW5pcXVlIGlkZW50aWZpZXIgZm9yIHRyYWNraW5n
IHVzZXJzLgoKDAoFBAACAwUSA3ICCAoMCgUEAAIDARIDcgkXCgwKBQQAAgMDEgNyGhsKFQoE
BAACBBIDdQIaGgggVHVybnMuCgoMCgUEAAIEBBIDdQIKCgwKBQQAAgQGEgN1Cw8KDAoFBAAC
BAESA3UQFQoMCgUEAAIEAxIDdRgZCmIKBAQAAgUSA3kCRhpVIE9wdGlvbmFsLiBUaGUgbGFi
ZWxzIGZvciB0aGUgc2Vzc2lvbi4KIENhbiBiZSBzZXQgYXMgZmlsdGVyIGluIExpc3RTZXNz
aW9uc1JlcXVlc3QuCgoMCgUEAAIFBBIDeQIKCgwKBQQAAgUFEgN5CxEKDAoFBAACBQESA3kS
GAoMCgUEAAIFAxIDeRscCgwKBQQAAgUIEgN5HUUKDwoIBAACBQicCAASA3keRAo6CgQEAAIG
EgR8An0yGiwgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBzZXNzaW9uIHN0YXJ0ZWQuCgoM
CgUEAAIGBhIDfAIbCgwKBQQAAgYBEgN8HCYKDAoFBAACBgMSA3wpKgoMCgUEAAIGCBIDfQYx
Cg8KCAQAAgYInAgAEgN9BzAKPQoEBAACBxIGgAECgQEyGi0gT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHRoZSBzZXNzaW9uIGZpbmlzaGVkLgoKDQoFBAACBwYSBIABAhsKDQoFBAACBwESBIAB
HCQKDQoFBAACBwMSBIABJygKDQoFBAACBwgSBIEBBjEKEAoIBAACBwicCAASBIEBBzAKegoE
BAACCBIEhQECPhpsIE9wdGlvbmFsLiBXaGV0aGVyIHRoZSBzZXNzaW9uIGlzIHBpbm5lZCwg
cGlubmVkIHNlc3Npb24gd2lsbCBiZSBkaXNwbGF5ZWQKIG9uIHRoZSB0b3Agb2YgdGhlIHNl
c3Npb24gbGlzdC4KCg0KBQQAAggFEgSFAQIGCg0KBQQAAggBEgSFAQcQCg0KBQQAAggDEgSF
ARMUCg0KBQQAAggIEgSFARU9ChAKCAQAAggInAgAEgSFARY8CvoBCgQEAAIJEgaLAQKMATIa
6QEgT3V0cHV0IG9ubHkuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBhbiBpbi1wcm9ncmVzcyBB
c3luY0Fzc2lzdCBvcGVyYXRpb24gZm9yCiB0aGlzIHNlc3Npb24sIGUuZy4KIGBwcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qL3Nlc3Npb25zLyovb3Bl
cmF0aW9ucy8qYC4KIFNldCB3aGVuIHRoZSBvcGVyYXRpb24gc3RhcnRzIGFuZCBjbGVhcmVk
IHdoZW4gaXQgZmluaXNoZXMuCgoNCgUEAAIJBRIEiwECCAoNCgUEAAIJARIEiwEJKgoNCgUE
AAIJAxIEiwEtLwoNCgUEAAIJCBIEjAEGMQoQCggEAAIJCJwIABIEjAEHMAotCgIEARIGkAEA
mQEBGh8gRGVmaW5lcyBhIHVzZXIgaW5wdXRlZCBxdWVyeS4KCgsKAwQBARIEkAEIDQogCgQE
AQgAEgaSAQKVAQMaECBRdWVyeSBjb250ZW50LgoKDQoFBAEIAAESBJIBCA8KGwoEBAECABIE
lAEEFBoNIFBsYWluIHRleHQuCgoNCgUEAQIABRIElAEECgoNCgUEAQIAARIElAELDwoNCgUE
AQIAAxIElAESEwo1CgQEAQIBEgSYAQJCGicgT3V0cHV0IG9ubHkuIFVuaXF1ZSBJZCBmb3Ig
dGhlIHF1ZXJ5LgoKDQoFBAECAQUSBJgBAggKDQoFBAECAQESBJgBCREKDQoFBAECAQMSBJgB
FBUKDQoFBAECAQgSBJgBFkEKEAoIBAECAQicCAASBJgBF0BiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Session::Session ===
    # Fields for Session
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1beta.Session.State)
    # Field: user_pseudo_id Type: 9 ()
    # Field: turns Type: 11 (.google.cloud.discoveryengine.v1beta.Session.Turn)
    # Field: labels Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: is_pinned Type: 8 ()
    # Field: pending_async_assist_operation_id Type: 9 ()

# Enum: Session::State
our $Session_STATE_UNSPECIFIED = 0;
our $Session_IN_PROGRESS = 1;

# === Message: Google::Cloud::Discoveryengine::V1beta::Session::Query ===
    # Fields for Query
    # Field: text Type: 9 ()
    # Field: query_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Session - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/session.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Session;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Session::Session->new({
        name => $name,
        display_name => $display_name,
        state => $state,
        user_pseudo_id => $user_pseudo_id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Session::Session->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/session.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Session::Session

External session proto definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/{project}/locations/global/collections/{collection}/engines/{engine}/sessions/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the session.

This field is used to identify the session in the UI.
By default, the display name is the first turn query text in the session.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::Session::State>)

The state of the session.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking users.

=item * C<< $msg->turns() >> / C<< $msg->turns($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn>)

Turns.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Optional. The labels for the session.
Can be set as filter in ListSessionsRequest.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the session started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the session finished.

=item * C<< $msg->is_pinned() >> / C<< $msg->is_pinned($value) >>

Type: C<Bool>

Optional. Whether the session is pinned, pinned session will be displayed
on the top of the session list.

=item * C<< $msg->pending_async_assist_operation_id() >> / C<< $msg->pending_async_assist_operation_id($value) >>

Type: C<String>

Output only. Full resource name of an in-progress AsyncAssist operation for
this session, e.g.
`projects/*/locations/*/collections/*/engines/*/sessions/*/operations/*`.
Set when the operation starts and cleared when it finishes.

=back

=head3 Enum: Session::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Session::Query

Defines a user inputed query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Plain text.

=item * C<< $msg->query_id() >> / C<< $msg->query_id($value) >>

Type: C<String>

Output only. Unique Id for the query.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Session::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
