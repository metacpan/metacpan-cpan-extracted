package Google::Cloud::Ces::V1::Common;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvY2xvdWQvY2VzL3YxL2NvbW1vbi5wcm90bxITZ29vZ2xlLmNsb3VkLmNlcy52
MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGhxnb29nbGUvcHJvdG9i
dWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIssBCghD
YWxsYmFjaxImCgtweXRob25fY29kZRgBIAEoCUID4EECSABSCnB5dGhvbkNvZGUSJQoLZGVz
Y3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SHwoIZGlzYWJsZWQYAiABKAhCA+BB
AVIIZGlzYWJsZWQSQwobcHJvYWN0aXZlX2V4ZWN1dGlvbl9lbmFibGVkGAQgASgIQgPgQQFS
GXByb2FjdGl2ZUV4ZWN1dGlvbkVuYWJsZWRCCgoIY2FsbGJhY2siZgoNTW9kZWxTZXR0aW5n
cxIZCgVtb2RlbBgBIAEoCUID4EEBUgVtb2RlbBIqCgt0ZW1wZXJhdHVyZRgCIAEoAUID4EEB
SABSC3RlbXBlcmF0dXJliAEBQg4KDF90ZW1wZXJhdHVyZSL3BAoNVHJpZ2dlckFjdGlvbhJt
ChNyZXNwb25kX2ltbWVkaWF0ZWx5GAEgASgLMjUuZ29vZ2xlLmNsb3VkLmNlcy52MS5Ucmln
Z2VyQWN0aW9uLlJlc3BvbmRJbW1lZGlhdGVseUID4EEBSABSEnJlc3BvbmRJbW1lZGlhdGVs
eRJeCg50cmFuc2Zlcl9hZ2VudBgCIAEoCzIwLmdvb2dsZS5jbG91ZC5jZXMudjEuVHJpZ2dl
ckFjdGlvbi5UcmFuc2ZlckFnZW50QgPgQQFIAFINdHJhbnNmZXJBZ2VudBJnChFnZW5lcmF0
aXZlX2Fuc3dlchgDIAEoCzIzLmdvb2dsZS5jbG91ZC5jZXMudjEuVHJpZ2dlckFjdGlvbi5H
ZW5lcmF0aXZlQW5zd2VyQgPgQQFIAFIQZ2VuZXJhdGl2ZUFuc3dlchpECghSZXNwb25zZRIX
CgR0ZXh0GAEgASgJQgPgQQJSBHRleHQSHwoIZGlzYWJsZWQYAiABKAhCA+BBAVIIZGlzYWJs
ZWQaZAoSUmVzcG9uZEltbWVkaWF0ZWx5Ek4KCXJlc3BvbnNlcxgBIAMoCzIrLmdvb2dsZS5j
bG91ZC5jZXMudjEuVHJpZ2dlckFjdGlvbi5SZXNwb25zZUID4EECUglyZXNwb25zZXMaLwoQ
R2VuZXJhdGl2ZUFuc3dlchIbCgZwcm9tcHQYASABKAlCA+BBAlIGcHJvbXB0GkcKDVRyYW5z
ZmVyQWdlbnQSNgoFYWdlbnQYASABKAlCIOBBAvpBGgoYY2VzLmdvb2dsZWFwaXMuY29tL0Fn
ZW50UgVhZ2VudEIICgZhY3Rpb24inQEKCVRsc0NvbmZpZxJFCghjYV9jZXJ0cxgBIAMoCzIl
Lmdvb2dsZS5jbG91ZC5jZXMudjEuVGxzQ29uZmlnLkNhQ2VydEID4EECUgdjYUNlcnRzGkkK
BkNhQ2VydBImCgxkaXNwbGF5X25hbWUYASABKAlCA+BBAlILZGlzcGxheU5hbWUSFwoEY2Vy
dBgCIAEoDEID4EECUgRjZXJ0ImMKFlNlcnZpY2VEaXJlY3RvcnlDb25maWcSSQoHc2Vydmlj
ZRgBIAEoCUIv4EEC+kEpCidzZXJ2aWNlZGlyZWN0b3J5Lmdvb2dsZWFwaXMuY29tL1NlcnZp
Y2VSB3NlcnZpY2UiiRIKDkNoYW5uZWxQcm9maWxlEiIKCnByb2ZpbGVfaWQYASABKAlCA+BB
AVIJcHJvZmlsZUlkElcKDGNoYW5uZWxfdHlwZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC5jZXMu
djEuQ2hhbm5lbFByb2ZpbGUuQ2hhbm5lbFR5cGVCA+BBAVILY2hhbm5lbFR5cGUSYwoQcGVy
c29uYV9wcm9wZXJ0eRgCIAEoCzIzLmdvb2dsZS5jbG91ZC5jZXMudjEuQ2hhbm5lbFByb2Zp
bGUuUGVyc29uYVByb3BlcnR5QgPgQQFSD3BlcnNvbmFQcm9wZXJ0eRImCgxkaXNhYmxlX2R0
bWYYBCABKAhCA+BBAVILZGlzYWJsZUR0bWYSPAoYZGlzYWJsZV9iYXJnZV9pbl9jb250cm9s
GAUgASgIQgPgQQFSFWRpc2FibGVCYXJnZUluQ29udHJvbBJkChF3ZWJfd2lkZ2V0X2NvbmZp
ZxgHIAEoCzIzLmdvb2dsZS5jbG91ZC5jZXMudjEuQ2hhbm5lbFByb2ZpbGUuV2ViV2lkZ2V0
Q29uZmlnQgPgQQFSD3dlYldpZGdldENvbmZpZxI7Chdub2lzZV9zdXBwcmVzc2lvbl9sZXZl
bBgIIAEoCUID4EEBUhVub2lzZVN1cHByZXNzaW9uTGV2ZWwSYAoPd2hhdHNhcHBfY29uZmln
GAkgASgLMjIuZ29vZ2xlLmNsb3VkLmNlcy52MS5DaGFubmVsUHJvZmlsZS5XaGF0c0FwcENv
bmZpZ0ID4EEBUg53aGF0c2FwcENvbmZpZxJjChBpbnN0YWdyYW1fY29uZmlnGAogASgLMjMu
Z29vZ2xlLmNsb3VkLmNlcy52MS5DaGFubmVsUHJvZmlsZS5JbnN0YWdyYW1Db25maWdCA+BB
AVIPaW5zdGFncmFtQ29uZmlnGp4BCg9QZXJzb25hUHJvcGVydHkSWgoHcGVyc29uYRgBIAEo
DjI7Lmdvb2dsZS5jbG91ZC5jZXMudjEuQ2hhbm5lbFByb2ZpbGUuUGVyc29uYVByb3BlcnR5
LlBlcnNvbmFCA+BBAVIHcGVyc29uYSIvCgdQZXJzb25hEgsKB1VOS05PV04QABILCgdDT05D
SVNFEAESCgoGQ0hBVFRZEAIa9AUKD1dlYldpZGdldENvbmZpZxJdCghtb2RhbGl0eRgBIAEo
DjI8Lmdvb2dsZS5jbG91ZC5jZXMudjEuQ2hhbm5lbFByb2ZpbGUuV2ViV2lkZ2V0Q29uZmln
Lk1vZGFsaXR5QgPgQQFSCG1vZGFsaXR5ElQKBXRoZW1lGAIgASgOMjkuZ29vZ2xlLmNsb3Vk
LmNlcy52MS5DaGFubmVsUHJvZmlsZS5XZWJXaWRnZXRDb25maWcuVGhlbWVCA+BBAVIFdGhl
bWUSLQoQd2ViX3dpZGdldF90aXRsZRgDIAEoCUID4EEBUg53ZWJXaWRnZXRUaXRsZRJ2ChFz
ZWN1cml0eV9zZXR0aW5ncxgEIAEoCzJELmdvb2dsZS5jbG91ZC5jZXMudjEuQ2hhbm5lbFBy
b2ZpbGUuV2ViV2lkZ2V0Q29uZmlnLlNlY3VyaXR5U2V0dGluZ3NCA+BBAVIQc2VjdXJpdHlT
ZXR0aW5ncxrcAQoQU2VjdXJpdHlTZXR0aW5ncxI1ChRlbmFibGVfcHVibGljX2FjY2VzcxgB
IAEoCEID4EEBUhJlbmFibGVQdWJsaWNBY2Nlc3MSMwoTZW5hYmxlX29yaWdpbl9jaGVjaxgE
IAEoCEID4EEBUhFlbmFibGVPcmlnaW5DaGVjaxIsCg9hbGxvd2VkX29yaWdpbnMYAiADKAlC
A+BBAVIOYWxsb3dlZE9yaWdpbnMSLgoQZW5hYmxlX3JlY2FwdGNoYRgDIAEoCEID4EEBUg9l
bmFibGVSZWNhcHRjaGEicQoITW9kYWxpdHkSGAoUTU9EQUxJVFlfVU5TUEVDSUZJRUQQABIS
Cg5DSEFUX0FORF9WT0lDRRABEg4KClZPSUNFX09OTFkQAhINCglDSEFUX09OTFkQAxIYChRD
SEFUX1ZPSUNFX0FORF9WSURFTxAEIjMKBVRoZW1lEhUKEVRIRU1FX1VOU1BFQ0lGSUVEEAAS
CQoFTElHSFQQARIICgREQVJLEAIa/AEKDldoYXRzQXBwQ29uZmlnEhwKB3dhYmFfaWQYASAB
KAlCA+BBAlIGd2FiYUlkEisKD3Bob25lX251bWJlcl9pZBgCIAEoCUID4EECUg1waG9uZU51
bWJlcklkEiYKDHBob25lX251bWJlchgDIAEoCUID4EEBUgtwaG9uZU51bWJlchImCgxkaXNw
bGF5X25hbWUYBCABKAlCA+BBA1ILZGlzcGxheU5hbWUSKAoNdGh1bWJuYWlsX3VybBgFIAEo
CUID4EEDUgx0aHVtYm5haWxVcmwSJQoLZGVzY3JpcHRpb24YBiABKAlCA+BBA1ILZGVzY3Jp
cHRpb24awQEKD0luc3RhZ3JhbUNvbmZpZxI1ChRpbnN0YWdyYW1fYWNjb3VudF9pZBgBIAEo
CUID4EECUhJpbnN0YWdyYW1BY2NvdW50SWQSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQNS
C2Rpc3BsYXlOYW1lEigKDXRodW1ibmFpbF91cmwYAyABKAlCA+BBA1IMdGh1bWJuYWlsVXJs
EiUKC2Rlc2NyaXB0aW9uGAQgASgJQgPgQQNSC2Rlc2NyaXB0aW9uIukBCgtDaGFubmVsVHlw
ZRILCgdVTktOT1dOEAASCgoGV0VCX1VJEAISBwoDQVBJEAMSCgoGVFdJTElPEAQSHQoZR09P
R0xFX1RFTEVQSE9OWV9QTEFURk9STRAFEh8KG0NPTlRBQ1RfQ0VOVEVSX0FTX0FfU0VSVklD
RRAGEiQKIENPTlRBQ1RfQ0VOVEVSX0FTX0FfU0VSVklDRV9DSEFUEAsSCQoFRklWRTkQBxIe
ChpDT05UQUNUX0NFTlRFUl9JTlRFR1JBVElPThAIEgwKCFdIQVRTQVBQEAkSDQoJSU5TVEFH
UkFNEAoi1gIKBFNwYW4SFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEj4KCnN0YXJ0X3RpbWUY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRI6Cghl
bmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5kVGlt
ZRI6CghkdXJhdGlvbhgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EEDUghk
dXJhdGlvbhI8CgphdHRyaWJ1dGVzGAQgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID
4EEDUgphdHRyaWJ1dGVzEj8KC2NoaWxkX3NwYW5zGAUgAygLMhkuZ29vZ2xlLmNsb3VkLmNl
cy52MS5TcGFuQgPgQQNSCmNoaWxkU3BhbnMqUgoNRXhlY3V0aW9uVHlwZRIeChpFWEVDVVRJ
T05fVFlQRV9VTlNQRUNJRklFRBAAEg8KC1NZTkNIUk9OT1VTEAESEAoMQVNZTkNIUk9OT1VT
EAJC0gEKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQgtDb21tb25Qcm90b1ABWiljbG91ZC5n
b29nbGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYupBfAonc2VydmljZWRpcmVjdG9y
eS5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlElFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vbmFtZXNwYWNlcy97bmFtZXNwYWNlfS9zZXJ2aWNlcy97c2VydmljZX1K
6HkKBxIFDgCUAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACgKCQoCAwMSAxUAJgoJCgIDBBID
FgApCggKAQgSAxgAQAoJCgIICxIDGABACggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoA
LAoJCgIICBIDGgAsCggKAQgSAxsAMAoJCgIIARIDGwAwCgkKAQgSBBwAHwIKDAoECJ0IABIE
HAAfAgo4CgIFABIEIgAuARosIFRoZSBleGVjdXRpb24gdHlwZSBvZiB0aGUgdG9vbCBvciB0
b29sc2V0LgoKCgoDBQABEgMiBRIKXAoEBQACABIDJQIhGk8gVGhlIGV4ZWN1dGlvbiB0eXBl
IGlzIHVuc3BlY2lmaWVkLiBEZWZhdWx0cyB0byBgU1lOQ0hST05PVVNgIGlmCiB1bnNwZWNp
ZmllZC4KCgwKBQUAAgABEgMlAhwKDAoFBQACAAISAyUfIApiCgQFAAIBEgMpAhIaVSBUaGUg
dG9vbCBpcyBleGVjdXRlZCBzeW5jaHJvbm91c2x5LiBUaGUgc2Vzc2lvbiBpcyBibG9ja2Vk
CiB1bnRpbCB0aGUgdG9vbCByZXR1cm5zLgoKDAoFBQACAQESAykCDQoMCgUFAAIBAhIDKRAR
CmsKBAUAAgISAy0CExpeIFRoZSB0b29sIGlzIGV4ZWN1dGVkIGFzeW5jaHJvbm91c2x5LiBU
aGUgc2Vzc2lvbiB3aWxsCiBjb250aW51ZSB3aGlsZSB0aGUgdG9vbCBpcyBleGVjdXRpbmcu
CgoMCgUFAAICARIDLQIOCgwKBQUAAgICEgMtERIKaQoCBAASBDIARwEaXSBBIGNhbGxiYWNr
IGRlZmluZXMgdGhlIGN1c3RvbSBsb2dpYyB0byBiZSBleGVjdXRlZCBhdCB2YXJpb3VzIHN0
YWdlcyBvZgogYWdlbnQgaW50ZXJhY3Rpb24uCgoKCgMEAAESAzIIEAooCgQEAAgAEgQ0AjcD
GhogVGhlIGNhbGxiYWNrIHRvIGV4ZWN1dGUuCgoMCgUEAAgAARIDNAgQCkUKBAQAAgASAzYE
RBo4IFJlcXVpcmVkLiBUaGUgcHl0aG9uIGNvZGUgdG8gZXhlY3V0ZSBmb3IgdGhlIGNhbGxi
YWNrLgoKDAoFBAACAAUSAzYECgoMCgUEAAIAARIDNgsWCgwKBQQAAgADEgM2GRoKDAoFBAAC
AAgSAzYbQwoPCggEAAIACJwIABIDNhxCCkQKBAQAAgESAzoCQho3IE9wdGlvbmFsLiBIdW1h
bi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgY2FsbGJhY2suCgoMCgUEAAIBBRIDOgII
CgwKBQQAAgEBEgM6CRQKDAoFBAACAQMSAzoXGAoMCgUEAAIBCBIDOhlBCg8KCAQAAgEInAgA
EgM6GkAKaAoEBAACAhIDPgI9GlsgT3B0aW9uYWwuIFdoZXRoZXIgdGhlIGNhbGxiYWNrIGlz
IGRpc2FibGVkLiBEaXNhYmxlZCBjYWxsYmFja3MgYXJlIGlnbm9yZWQKIGJ5IHRoZSBhZ2Vu
dC4KCgwKBQQAAgIFEgM+AgYKDAoFBAACAgESAz4HDwoMCgUEAAICAxIDPhITCgwKBQQAAgII
EgM+FDwKDwoIBAACAgicCAASAz4VOwqgAwoEBAACAxIDRgJQGpIDIE9wdGlvbmFsLiBJZiBl
bmFibGVkLCB0aGUgY2FsbGJhY2sgd2lsbCBhbHNvIGJlIGV4ZWN1dGVkIG9uIGludGVybWVk
aWF0ZQogbW9kZWwgb3V0cHV0cy4gVGhpcyBzZXR0aW5nIG9ubHkgYWZmZWN0cyBhZnRlciBt
b2RlbCBjYWxsYmFjay4KICoqRU5BQkxFIFdJVEggQ0FVVElPTioqLiBUeXBpY2FsbHkgYWZ0
ZXIgbW9kZWwgY2FsbGJhY2sgb25seSBuZWVkcyB0byBiZQogZXhlY3V0ZWQgYWZ0ZXIgcmVj
ZWl2aW5nIGFsbCBtb2RlbCByZXNwb25zZXMuIEVuYWJsaW5nIHByb2FjdGl2ZSBleGVjdXRp
b24KIG1heSBoYXZlIG5lZ2F0aXZlIGltcGxpY2F0aW9uIG9uIHRoZSBleGVjdXRpb24gY29z
dCBhbmQgbGF0ZW5jeSwgYW5kCiBzaG91bGQgb25seSBiZSBlbmFibGVkIGluIHJhcmUgc2l0
dWF0aW9ucy4KCgwKBQQAAgMFEgNGAgYKDAoFBAACAwESA0YHIgoMCgUEAAIDAxIDRiUmCgwK
BQQAAgMIEgNGJ08KDwoIBAACAwicCAASA0YoTgpPCgIEARIESgBUARpDIE1vZGVsIHNldHRp
bmdzIGNvbnRhaW5zIHZhcmlvdXMgY29uZmlndXJhdGlvbnMgZm9yIHRoZSBMTE0gbW9kZWwu
CgoKCgMEAQESA0oIFQqGAQoEBAECABIDTQI8GnkgT3B0aW9uYWwuIFRoZSBMTE0gbW9kZWwg
dGhhdCB0aGUgYWdlbnQgc2hvdWxkIHVzZS4KIElmIG5vdCBzZXQsIHRoZSBhZ2VudCB3aWxs
IGluaGVyaXQgdGhlIG1vZGVsIGZyb20gaXRzIHBhcmVudCBhZ2VudC4KCgwKBQQBAgAFEgNN
AggKDAoFBAECAAESA00JDgoMCgUEAQIAAxIDTRESCgwKBQQBAgAIEgNNEzsKDwoIBAECAAic
CAASA00UOgqRAgoEBAECARIDUwJLGoMCIE9wdGlvbmFsLiBJZiBzZXQsIHRoaXMgdGVtcGVy
YXR1cmUgd2lsbCBiZSB1c2VkIGZvciB0aGUgTExNIG1vZGVsLgogVGVtcGVyYXR1cmUgY29u
dHJvbHMgdGhlIHJhbmRvbW5lc3Mgb2YgdGhlIG1vZGVsJ3MgcmVzcG9uc2VzLiBMb3dlcgog
dGVtcGVyYXR1cmVzIHByb2R1Y2UgcmVzcG9uc2VzIHRoYXQgYXJlIG1vcmUgcHJlZGljdGFi
bGUuIEhpZ2hlcgogdGVtcGVyYXR1cmVzIHByb2R1Y2UgcmVzcG9uc2VzIHRoYXQgYXJlIG1v
cmUgY3JlYXRpdmUuCgoMCgUEAQIBBBIDUwIKCgwKBQQBAgEFEgNTCxEKDAoFBAECAQESA1MS
HQoMCgUEAQIBAxIDUyAhCgwKBQQBAgEIEgNTIkoKDwoIBAECAQicCAASA1MjSQpHCgIEAhIF
VwCHAQEaOiBBY3Rpb24gdGhhdCBpcyB0YWtlbiB3aGVuIGEgY2VydGFpbiBwcmVjb25kaXRp
b24gaXMgbWV0LgoKCgoDBAIBEgNXCBUKNQoEBAIDABIEWQJgAxonIFJlcHJlc2VudHMgYSBy
ZXNwb25zZSBmcm9tIHRoZSBhZ2VudC4KCgwKBQQCAwABEgNZChIKPgoGBAIDAAIAEgNbBD0a
LyBSZXF1aXJlZC4gVGV4dCBmb3IgdGhlIGFnZW50IHRvIHJlc3BvbmQgd2l0aC4KCg4KBwQC
AwACAAUSA1sECgoOCgcEAgMAAgABEgNbCw8KDgoHBAIDAAIAAxIDWxITCg4KBwQCAwACAAgS
A1sUPAoRCgoEAgMAAgAInAgAEgNbFTsKawoGBAIDAAIBEgNfBD8aXCBPcHRpb25hbC4gV2hl
dGhlciB0aGUgcmVzcG9uc2UgaXMgZGlzYWJsZWQuIERpc2FibGVkIHJlc3BvbnNlcyBhcmUg
bm90CiB1c2VkIGJ5IHRoZSBhZ2VudC4KCg4KBwQCAwACAQUSA18ECAoOCgcEAgMAAgEBEgNf
CREKDgoHBAIDAAIBAxIDXxQVCg4KBwQCAwACAQgSA18WPgoRCgoEAgMAAgEInAgAEgNfFz0K
UQoEBAIDARIEYwJnAxpDIFRoZSBhZ2VudCB3aWxsIGltbWVkaWF0ZWx5IHJlc3BvbmQgd2l0
aCBhIHByZWNvbmZpZ3VyZWQgcmVzcG9uc2UuCgoMCgUEAgMBARIDYwocCm8KBgQCAwECABID
ZgRNGmAgUmVxdWlyZWQuIFRoZSBjYW5uZWQgcmVzcG9uc2VzIGZvciB0aGUgYWdlbnQgdG8g
Y2hvb3NlIGZyb20uIFRoZSByZXNwb25zZQogaXMgY2hvc2VuIHJhbmRvbWx5LgoKDgoHBAID
AQIABBIDZgQMCg4KBwQCAwECAAYSA2YNFQoOCgcEAgMBAgABEgNmFh8KDgoHBAIDAQIAAxID
ZiIjCg4KBwQCAwECAAgSA2YkTAoRCgoEAgMBAgAInAgAEgNmJUsKTAoEBAIDAhIEagJtAxo+
IFRoZSBhZ2VudCB3aWxsIGltbWVkaWF0ZWx5IHJlc3BvbmQgd2l0aCBhIGdlbmVyYXRpdmUg
YW5zd2VyLgoKDAoFBAIDAgESA2oKGgpHCgYEAgMCAgASA2wEPxo4IFJlcXVpcmVkLiBUaGUg
cHJvbXB0IHRvIHVzZSBmb3IgdGhlIGdlbmVyYXRpdmUgYW5zd2VyLgoKDgoHBAIDAgIABRID
bAQKCg4KBwQCAwICAAESA2wLEQoOCgcEAgMCAgADEgNsFBUKDgoHBAIDAgIACBIDbBY+ChEK
CgQCAwICAAicCAASA2wXPQpOCgQEAgMDEgRwAngDGkAgVGhlIGFnZW50IHdpbGwgdHJhbnNm
ZXIgdGhlIGNvbnZlcnNhdGlvbiB0byBhIGRpZmZlcmVudCBhZ2VudC4KCgwKBQQCAwMBEgNw
ChcK2QEKBgQCAwMCABIEdAR3BhrIASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGFnZW50
IHRvIHRyYW5zZmVyIHRoZSBjb252ZXJzYXRpb24gdG8uIFRoZQogYWdlbnQgbXVzdCBiZSBp
biB0aGUgc2FtZSBhcHAgYXMgdGhlIGN1cnJlbnQgYWdlbnQuIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9hZ2VudHMve2Fn
ZW50fWAKCg4KBwQCAwMCAAUSA3QECgoOCgcEAgMDAgABEgN0CxAKDgoHBAIDAwIAAxIDdBMU
Cg8KBwQCAwMCAAgSBHQVdwUKEQoKBAIDAwIACJwIABIDdQYsChAKCQQCAwMCAAifCBIDdgZM
CiQKBAQCCAASBXsChgEDGhUgVGhlIGFjdGlvbiB0byB0YWtlLgoKDAoFBAIIAAESA3sIDgpM
CgQEAgIAEgR9BH4xGj4gT3B0aW9uYWwuIEltbWVkaWF0ZWx5IHJlc3BvbmQgd2l0aCBhIHBy
ZWNvbmZpZ3VyZWQgcmVzcG9uc2UuCgoMCgUEAgIABhIDfQQWCgwKBQQCAgABEgN9FyoKDAoF
BAICAAMSA30tLgoMCgUEAgIACBIDfggwCg8KCAQCAgAInAgAEgN+CS8KSQoEBAICARIEgQEE
Tho7IE9wdGlvbmFsLiBUcmFuc2ZlciB0aGUgY29udmVyc2F0aW9uIHRvIGEgZGlmZmVyZW50
IGFnZW50LgoKDQoFBAICAQYSBIEBBBEKDQoFBAICAQESBIEBEiAKDQoFBAICAQMSBIEBIyQK
DQoFBAICAQgSBIEBJU0KEAoIBAICAQicCAASBIEBJkwKPQoEBAICAhIGhAEEhQExGi0gT3B0
aW9uYWwuIFJlc3BvbmQgd2l0aCBhIGdlbmVyYXRpdmUgYW5zd2VyLgoKDQoFBAICAgYSBIQB
BBQKDQoFBAICAgESBIQBFSYKDQoFBAICAgMSBIQBKSoKDQoFBAICAggSBIUBCDAKEAoIBAIC
AgicCAASBIUBCS8KJgoCBAMSBooBAKQBARoYIFRoZSBUTFMgY29uZmlndXJhdGlvbi4KCgsK
AwQDARIEigEIEQolCgQEAwMAEgaMAQKfAQMaFSBUaGUgQ0EgY2VydGlmaWNhdGUuCgoNCgUE
AwMAARIEjAEKEAqJAQoGBAMDAAIAEgSPAQRFGnkgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRo
ZSBhbGxvd2VkIGN1c3RvbSBDQSBjZXJ0aWZpY2F0ZXMuIFRoaXMKIGNhbiBiZSB1c2VkIHRv
IGRpc2FtYmlndWF0ZSB0aGUgY3VzdG9tIENBIGNlcnRpZmljYXRlcy4KCg8KBwQDAwACAAUS
BI8BBAoKDwoHBAMDAAIAARIEjwELFwoPCgcEAwMAAgADEgSPARobCg8KBwQDAwACAAgSBI8B
HEQKEgoKBAMDAAIACJwIABIEjwEdQwrYBAoGBAMDAAIBEgSeAQQ8GscEIFJlcXVpcmVkLiBU
aGUgYWxsb3dlZCBjdXN0b20gQ0EgY2VydGlmaWNhdGVzIChpbiBERVIgZm9ybWF0KSBmb3IK
IEhUVFBTIHZlcmlmaWNhdGlvbi4gVGhpcyBvdmVycmlkZXMgdGhlIGRlZmF1bHQgU1NMIHRy
dXN0IHN0b3JlLiBJZiB0aGlzCiBpcyBlbXB0eSBvciB1bnNwZWNpZmllZCwgQ0VTIHdpbGwg
dXNlIEdvb2dsZSdzIGRlZmF1bHQgdHJ1c3QKIHN0b3JlIHRvIHZlcmlmeSBjZXJ0aWZpY2F0
ZXMuIE4uQi4gTWFrZSBzdXJlIHRoZSBIVFRQUyBzZXJ2ZXIKIGNlcnRpZmljYXRlcyBhcmUg
c2lnbmVkIHdpdGggInN1YmplY3QgYWx0IG5hbWUiLiBGb3IgaW5zdGFuY2UgYQogY2VydGlm
aWNhdGUgY2FuIGJlIHNlbGYtc2lnbmVkIHVzaW5nIHRoZSBmb2xsb3dpbmcgY29tbWFuZDoK
CiBgYGAKICAgIG9wZW5zc2wgeDUwOSAtcmVxIC1kYXlzIDIwMCAtaW4gZXhhbXBsZS5jb20u
Y3NyIFwKICAgICAgLXNpZ25rZXkgZXhhbXBsZS5jb20ua2V5IFwKICAgICAgLW91dCBleGFt
cGxlLmNvbS5jcnQgXAogICAgICAtZXh0ZmlsZSA8KHByaW50ZiAiXG5zdWJqZWN0QWx0TmFt
ZT0nRE5TOnd3dy5leGFtcGxlLmNvbSciKQogYGBgCgoPCgcEAwMAAgEFEgSeAQQJCg8KBwQD
AwACAQESBJ4BCg4KDwoHBAMDAAIBAxIEngEREgoPCgcEAwMAAgEIEgSeARM7ChIKCgQDAwAC
AQicCAASBJ4BFDoKZQoEBAMCABIEowECSBpXIFJlcXVpcmVkLiBTcGVjaWZpZXMgYSBsaXN0
IG9mIGFsbG93ZWQgY3VzdG9tIENBIGNlcnRpZmljYXRlcyBmb3IgSFRUUFMKIHZlcmlmaWNh
dGlvbi4KCg0KBQQDAgAEEgSjAQIKCg0KBQQDAgAGEgSjAQsRCg0KBQQDAgABEgSjARIaCg0K
BQQDAgADEgSjAR0eCg0KBQQDAgAIEgSjAR9HChAKCAQDAgAInAgAEgSjASBGCkAKAgQEEgan
AQC0AQEaMiBDb25maWd1cmF0aW9uIGZvciB0b29scyB1c2luZyBTZXJ2aWNlIERpcmVjdG9y
eS4KCgsKAwQEARIEpwEIHgqiAgoEBAQCABIGrgECswEEGpECIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiBbU2VydmljZQogRGlyZWN0b3J5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc2Vy
dmljZS1kaXJlY3RvcnkpIHNlcnZpY2UuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L25hbWVzcGFjZXMve25hbWVzcGFjZX0vc2VydmljZXMv
e3NlcnZpY2V9YC4KIExvY2F0aW9uIG9mIHRoZSBzZXJ2aWNlIGRpcmVjdG9yeSBtdXN0IGJl
IHRoZSBzYW1lIGFzIHRoZSBsb2NhdGlvbiBvZiB0aGUKIGFwcC4KCg0KBQQEAgAFEgSuAQII
Cg0KBQQEAgABEgSuAQkQCg0KBQQEAgADEgSuARMUCg8KBQQEAgAIEgauARWzAQMKEAoIBAQC
AAicCAASBK8BBCoKEQoHBAQCAAifCBIGsAEEsgEFCoQBCgIEBRIGuAEA+wIBGnYgQSBDaGFu
bmVsUHJvZmlsZSBjb25maWd1cmVzIHRoZSBhZ2VudCdzIGJlaGF2aW9yIGZvciBhIHNwZWNp
ZmljIGNvbW11bmljYXRpb24KIGNoYW5uZWwsIHN1Y2ggYXMgd2ViIFVJIG9yIHRlbGVwaG9u
eS4KCgsKAwQFARIEuAEIFgo/CgQEBQMAEga6AQLJAQMaLyBSZXByZXNlbnRzIHRoZSBwZXJz
b25hIHByb3BlcnR5IG9mIGEgY2hhbm5lbC4KCg0KBQQFAwABEgS6AQoZCi8KBgQFAwAEABIG
vAEExQEFGh0gVGhlIHBlcnNvbmEgb2YgdGhlIGNoYW5uZWwuCgoPCgcEBQMABAABEgS8AQkQ
CiQKCAQFAwAEAAIAEgS+AQYSGhIgVU5LTk9XTiBwZXJzb25hLgoKEQoJBAUDAAQAAgABEgS+
AQYNChEKCQQFAwAEAAIAAhIEvgEQEQpKCggEBQMABAACARIEwQEGEho4IFRoZSBhZ2VudCBr
ZWVwcyB0aGUgcmVzcG9uc2VzIGNvbmNpc2UgYW5kIHRvIHRoZSBwb2ludAoKEQoJBAUDAAQA
AgEBEgTBAQYNChEKCQQFAwAEAAIBAhIEwQEQEQpUCggEBQMABAACAhIExAEGERpCIFRoZSBh
Z2VudCBwcm92aWRlcyBhZGRpdGlvbmFsIGNvbnRleHQsIGV4cGxhbmF0aW9ucywgYW5kIGRl
dGFpbHMKChEKCQQFAwAEAAICARIExAEGDAoRCgkEBQMABAACAgISBMQBDxAKNwoGBAUDAAIA
EgTIAQRBGicgT3B0aW9uYWwuIFRoZSBwZXJzb25hIG9mIHRoZSBjaGFubmVsLgoKDwoHBAUD
AAIABhIEyAEECwoPCgcEBQMAAgABEgTIAQwTCg8KBwQFAwACAAMSBMgBFhcKDwoHBAUDAAIA
CBIEyAEYQAoSCgoEBQMAAgAInAgAEgTIARk/Cj8KBAQFAwESBswBApECAxovIE1lc3NhZ2Ug
Zm9yIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSB3ZWIgd2lkZ2V0LgoKDQoFBAUDAQESBMwBChkK
OQoGBAUDAQMAEgbOAQTlAQUaJyBTZWN1cml0eSBzZXR0aW5ncyBmb3IgdGhlIHdlYiB3aWRn
ZXQuCgoPCgcEBQMBAwABEgTOAQwcCrQCCggEBQMBAwACABIE1AEGTRqhAiBPcHRpb25hbC4g
SW5kaWNhdGVzIHdoZXRoZXIgcHVibGljIGFjY2VzcyB0byB0aGUgd2ViIHdpZGdldCBpcyBl
bmFibGVkLgogSWYgYHRydWVgLCB0aGUgd2ViIHdpZGdldCB3aWxsIGJlIHB1YmxpY2x5IGFj
Y2Vzc2libGUuCiBJZiBgZmFsc2VgLCB0aGUgd2ViIHdpZGdldCBtdXN0IGJlIGludGVncmF0
ZWQgd2l0aCB5b3VyIG93bgogYXV0aGVudGljYXRpb24gYW5kIGF1dGhvcml6YXRpb24gc3lz
dGVtIHRvIHJldHVybiB2YWxpZCBjcmVkZW50aWFscyBmb3IKIGFjY2Vzc2luZyB0aGUgQ0VT
IGFnZW50LgoKEQoJBAUDAQMAAgAFEgTUAQYKChEKCQQFAwEDAAIAARIE1AELHwoRCgkEBQMB
AwACAAMSBNQBIiMKEQoJBAUDAQMAAgAIEgTUASRMChQKDAQFAwEDAAIACJwIABIE1AElSwqJ
AgoIBAUDAQMAAgESBNoBBkwa9gEgT3B0aW9uYWwuIEluZGljYXRlcyB3aGV0aGVyIG9yaWdp
biBjaGVjayBmb3IgdGhlIHdlYiB3aWRnZXQgaXMgZW5hYmxlZC4KIElmIGB0cnVlYCwgdGhl
IHdlYiB3aWRnZXQgd2lsbCBjaGVjayB0aGUgb3JpZ2luIG9mIHRoZSB3ZWJzaXRlIHRoYXQK
IGxvYWRzIHRoZSB3ZWIgd2lkZ2V0IGFuZCBvbmx5IGFsbG93IGl0IHRvIGJlIGxvYWRlZCBp
biB0aGUgc2FtZSBvcmlnaW4KIG9yIGFueSBvZiB0aGUgYWxsb3dlZCBvcmlnaW5zLgoKEQoJ
BAUDAQMAAgEFEgTaAQYKChEKCQQFAwEDAAIBARIE2gELHgoRCgkEBQMBAwACAQMSBNoBISIK
EQoJBAUDAQMAAgEIEgTaASNLChQKDAQFAwEDAAIBCJwIABIE2gEkSgrgAQoIBAUDAQMAAgIS
Bt8BBuABMxrLASBPcHRpb25hbC4gVGhlIG9yaWdpbnMgdGhhdCBhcmUgYWxsb3dlZCB0byBo
b3N0IHRoZSB3ZWIgd2lkZ2V0LiBBbgogb3JpZ2luIGlzIGRlZmluZWQgYnkgUkZDIDY0NTQu
IElmIGVtcHR5LCBhbGwgb3JpZ2lucyBhcmUgYWxsb3dlZC4gQQogbWF4aW11bSBvZiAxMDAg
b3JpZ2lucyBpcyBhbGxvd2VkLiBFeGFtcGxlOiAiaHR0cHM6Ly9leGFtcGxlLmNvbSIKChEK
CQQFAwEDAAICBBIE3wEGDgoRCgkEBQMBAwACAgUSBN8BDxUKEQoJBAUDAQMAAgIBEgTfARYl
ChEKCQQFAwEDAAICAxIE3wEoKQoRCgkEBQMBAwACAggSBOABCjIKFAoMBAUDAQMAAgIInAgA
EgTgAQsxCmYKCAQFAwEDAAIDEgTkAQZJGlQgT3B0aW9uYWwuIEluZGljYXRlcyB3aGV0aGVy
IHJlQ0FQVENIQSB2ZXJpZmljYXRpb24gZm9yIHRoZSB3ZWIgd2lkZ2V0CiBpcyBlbmFibGVk
LgoKEQoJBAUDAQMAAgMFEgTkAQYKChEKCQQFAwEDAAIDARIE5AELGwoRCgkEBQMBAwACAwMS
BOQBHh8KEQoJBAUDAQMAAgMIEgTkASBIChQKDAQFAwEDAAIDCJwIABIE5AEhRwovCgYEBQMB
BAASBugBBPcBBRodIE1vZGFsaXR5IG9mIHRoZSB3ZWIgd2lkZ2V0LgoKDwoHBAUDAQQAARIE
6AEJEQolCggEBQMBBAACABIE6gEGHxoTIFVua25vd24gbW9kYWxpdHkuCgoRCgkEBQMBBAAC
AAESBOoBBhoKEQoJBAUDAQQAAgACEgTqAR0eCj4KCAQFAwEEAAIBEgTtAQYZGiwgV2lkZ2V0
IHN1cHBvcnRzIGJvdGggY2hhdCBhbmQgdm9pY2UgaW5wdXQuCgoRCgkEBQMBBAACAQESBO0B
BhQKEQoJBAUDAQQAAgECEgTtARcYCjUKCAQFAwEEAAICEgTwAQYVGiMgV2lkZ2V0IHN1cHBv
cnRzIG9ubHkgdm9pY2UgaW5wdXQuCgoRCgkEBQMBBAACAgESBPABBhAKEQoJBAUDAQQAAgIC
EgTwARMUCjQKCAQFAwEEAAIDEgTzAQYUGiIgV2lkZ2V0IHN1cHBvcnRzIG9ubHkgY2hhdCBp
bnB1dC4KChEKCQQFAwEEAAIDARIE8wEGDwoRCgkEBQMBBAACAwISBPMBEhMKQQoIBAUDAQQA
AgQSBPYBBh8aLyBXaWRnZXQgc3VwcG9ydHMgY2hhdCwgdm9pY2UsIGFuZCB2aWRlbyBpbnB1
dC4KChEKCQQFAwEEAAIEARIE9gEGGgoRCgkEBQMBBAACBAISBPYBHR4KLAoGBAUDAQQBEgb6
AQSDAgUaGiBUaGVtZSBvZiB0aGUgd2ViIHdpZGdldC4KCg8KBwQFAwEEAQESBPoBCQ4KIgoI
BAUDAQQBAgASBPwBBhwaECBVbmtub3duIHRoZW1lLgoKEQoJBAUDAQQBAgABEgT8AQYXChEK
CQQFAwEEAQIAAhIE/AEaGwogCggEBQMBBAECARIE/wEGEBoOIExpZ2h0IHRoZW1lLgoKEQoJ
BAUDAQQBAgEBEgT/AQYLChEKCQQFAwEEAQIBAhIE/wEODwofCggEBQMBBAECAhIEggIGDxoN
IERhcmsgdGhlbWUuCgoRCgkEBQMBBAECAgESBIICBgoKEQoJBAUDAQQBAgICEgSCAg0OCjsK
BgQFAwECABIEhgIEQxorIE9wdGlvbmFsLiBUaGUgbW9kYWxpdHkgb2YgdGhlIHdlYiB3aWRn
ZXQuCgoPCgcEBQMBAgAGEgSGAgQMCg8KBwQFAwECAAESBIYCDRUKDwoHBAUDAQIAAxIEhgIY
GQoPCgcEBQMBAgAIEgSGAhpCChIKCgQFAwECAAicCAASBIYCG0EKOAoGBAUDAQIBEgSJAgQ9
GiggT3B0aW9uYWwuIFRoZSB0aGVtZSBvZiB0aGUgd2ViIHdpZGdldC4KCg8KBwQFAwECAQYS
BIkCBAkKDwoHBAUDAQIBARIEiQIKDwoPCgcEBQMBAgEDEgSJAhITCg8KBwQFAwECAQgSBIkC
FDwKEgoKBAUDAQIBCJwIABIEiQIVOwo4CgYEBQMBAgISBIwCBEkaKCBPcHRpb25hbC4gVGhl
IHRpdGxlIG9mIHRoZSB3ZWIgd2lkZ2V0LgoKDwoHBAUDAQICBRIEjAIECgoPCgcEBQMBAgIB
EgSMAgsbCg8KBwQFAwECAgMSBIwCHh8KDwoHBAUDAQICCBIEjAIgSAoSCgoEBQMBAgIInAgA
EgSMAiFHCkYKBgQFAwECAxIGjwIEkAIxGjQgT3B0aW9uYWwuIFRoZSBzZWN1cml0eSBzZXR0
aW5ncyBvZiB0aGUgd2ViIHdpZGdldC4KCg8KBwQFAwECAwYSBI8CBBQKDwoHBAUDAQIDARIE
jwIVJgoPCgcEBQMBAgMDEgSPAikqCg8KBwQFAwECAwgSBJACCDAKEgoKBAUDAQIDCJwIABIE
kAIJLwpBCgQEBQMCEgaUAgKmAgMaMSBDb25maWd1cmF0aW9uIHNwZWNpZmljIHRvIFdoYXRz
QXBwIGRlcGxveW1lbnRzLgoKDQoFBAUDAgESBJQCChgKPQoGBAUDAgIAEgSWAgRAGi0gUmVx
dWlyZWQuIFRoZSBXaGF0c0FwcCBCdXNpbmVzcyBBY2NvdW50IElELgoKDwoHBAUDAgIABRIE
lgIECgoPCgcEBQMCAgABEgSWAgsSCg8KBwQFAwICAAMSBJYCFRYKDwoHBAUDAgIACBIElgIX
PwoSCgoEBQMCAgAInAgAEgSWAhg+CjUKBgQFAwICARIEmQIESBolIFJlcXVpcmVkLiBUaGUg
TWV0YSBwaG9uZSBudW1iZXIgSUQuCgoPCgcEBQMCAgEFEgSZAgQKCg8KBwQFAwICAQESBJkC
CxoKDwoHBAUDAgIBAxIEmQIdHgoPCgcEBQMCAgEIEgSZAh9HChIKCgQFAwICAQicCAASBJkC
IEYKPQoGBAUDAgICEgScAgRFGi0gT3B0aW9uYWwuIFRoZSBwaG9uZSBudW1iZXIgaW4gRS4x
NjQgZm9ybWF0LgoKDwoHBAUDAgICBRIEnAIECgoPCgcEBQMCAgIBEgScAgsXCg8KBwQFAwIC
AgMSBJwCGhsKDwoHBAUDAgICCBIEnAIcRAoSCgoEBQMCAgIInAgAEgScAh1DCkMKBgQFAwIC
AxIEnwIESBozIE91dHB1dCBvbmx5LiBUaGUgZmV0Y2hlZCBNZXRhIGJ1c2luZXNzIHBhZ2Ug
bmFtZS4KCg8KBwQFAwICAwUSBJ8CBAoKDwoHBAUDAgIDARIEnwILFwoPCgcEBQMCAgMDEgSf
AhobCg8KBwQFAwICAwgSBJ8CHEcKEgoKBAUDAgIDCJwIABIEnwIdRgpPCgYEBQMCAgQSBKIC
BEkaPyBPdXRwdXQgb25seS4gVGhlIGZldGNoZWQgTWV0YSBidXNpbmVzcyBwcm9maWxlIHRo
dW1ibmFpbCBVUkwuCgoPCgcEBQMCAgQFEgSiAgQKCg8KBwQFAwICBAESBKICCxgKDwoHBAUD
AgIEAxIEogIbHAoPCgcEBQMCAgQIEgSiAh1IChIKCgQFAwICBAicCAASBKICHkcKVAoGBAUD
AgIFEgSlAgRHGkQgT3V0cHV0IG9ubHkuIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgTWV0YSBi
dXNpbmVzcyBwYWdlIG9yIHByb2ZpbGUuCgoPCgcEBQMCAgUFEgSlAgQKCg8KBwQFAwICBQES
BKUCCxYKDwoHBAUDAgIFAxIEpQIZGgoPCgcEBQMCAgUIEgSlAhtGChIKCgQFAwICBQicCAAS
BKUCHEUKQgoEBAUDAxIGqQICtQIDGjIgQ29uZmlndXJhdGlvbiBzcGVjaWZpYyB0byBJbnN0
YWdyYW0gZGVwbG95bWVudHMuCgoNCgUEBQMDARIEqQIKGQo1CgYEBQMDAgASBKsCBE0aJSBS
ZXF1aXJlZC4gVGhlIEluc3RhZ3JhbSBBY2NvdW50IElELgoKDwoHBAUDAwIABRIEqwIECgoP
CgcEBQMDAgABEgSrAgsfCg8KBwQFAwMCAAMSBKsCIiMKDwoHBAUDAwIACBIEqwIkTAoSCgoE
BQMDAgAInAgAEgSrAiVLCkMKBgQFAwMCARIErgIESBozIE91dHB1dCBvbmx5LiBUaGUgZmV0
Y2hlZCBNZXRhIGJ1c2luZXNzIHBhZ2UgbmFtZS4KCg8KBwQFAwMCAQUSBK4CBAoKDwoHBAUD
AwIBARIErgILFwoPCgcEBQMDAgEDEgSuAhobCg8KBwQFAwMCAQgSBK4CHEcKEgoKBAUDAwIB
CJwIABIErgIdRgpPCgYEBQMDAgISBLECBEkaPyBPdXRwdXQgb25seS4gVGhlIGZldGNoZWQg
TWV0YSBidXNpbmVzcyBwcm9maWxlIHRodW1ibmFpbCBVUkwuCgoPCgcEBQMDAgIFEgSxAgQK
Cg8KBwQFAwMCAgESBLECCxgKDwoHBAUDAwICAxIEsQIbHAoPCgcEBQMDAgIIEgSxAh1IChIK
CgQFAwMCAgicCAASBLECHkcKVAoGBAUDAwIDEgS0AgRHGkQgT3V0cHV0IG9ubHkuIFRoZSBk
ZXNjcmlwdGlvbiBvZiB0aGUgTWV0YSBidXNpbmVzcyBwYWdlIG9yIHByb2ZpbGUuCgoPCgcE
BQMDAgMFEgS0AgQKCg8KBwQFAwMCAwESBLQCCxYKDwoHBAUDAwIDAxIEtAIZGgoPCgcEBQMD
AgMIEgS0AhtGChIKCgQFAwMCAwicCAASBLQCHEUKMgoEBAUEABIGuAIC2QIDGiIgVGhlIHR5
cGUgb2YgdGhlIGNoYW5uZWwgcHJvZmlsZS4KCg0KBQQFBAABEgS4AgcSCicKBgQFBAACABIE
ugIEEBoXIFVua25vd24gY2hhbm5lbCB0eXBlLgoKDwoHBAUEAAIAARIEugIECwoPCgcEBQQA
AgACEgS6Ag4PCiEKBgQFBAACARIEvQIEDxoRIFdlYiBVSSBjaGFubmVsLgoKDwoHBAUEAAIB
ARIEvQIECgoPCgcEBQQAAgECEgS9Ag0OCh4KBgQFBAACAhIEwAIEDBoOIEFQSSBjaGFubmVs
LgoKDwoHBAUEAAICARIEwAIEBwoPCgcEBQQAAgICEgTAAgoLCiEKBgQFBAACAxIEwwIEDxoR
IFR3aWxpbyBjaGFubmVsLgoKDwoHBAUEAAIDARIEwwIECgoPCgcEBQQAAgMCEgTDAg0OCjQK
BgQFBAACBBIExgIEIhokIEdvb2dsZSBUZWxlcGhvbnkgUGxhdGZvcm0gY2hhbm5lbC4KCg8K
BwQFBAACBAESBMYCBB0KDwoHBAUEAAIEAhIExgIgIQo+CgYEBQQAAgUSBMkCBCQaLiBDb250
YWN0IENlbnRlciBhcyBhIFNlcnZpY2UgKENDYWFTKSBjaGFubmVsLgoKDwoHBAUEAAIFARIE
yQIEHwoPCgcEBQQAAgUCEgTJAiIjCkMKBgQFBAACBhIEzAIEKhozIENvbnRhY3QgQ2VudGVy
IGFzIGEgU2VydmljZSAoQ0NhYVMgQ2hhdCkgY2hhbm5lbC4KCg8KBwQFBAACBgESBMwCBCQK
DwoHBAUEAAIGAhIEzAInKQogCgYEBQQAAgcSBM8CBA4aECBGaXZlOSBjaGFubmVsLgoKDwoH
BAUEAAIHARIEzwIECQoPCgcEBQQAAgcCEgTPAgwNCkEKBgQFBAACCBIE0gIEIxoxIFRoaXJk
IHBhcnR5IGNvbnRhY3QgY2VudGVyIGludGVncmF0aW9uIGNoYW5uZWwuCgoPCgcEBQQAAggB
EgTSAgQeCg8KBwQFBAACCAISBNICISIKIwoGBAUEAAIJEgTVAgQRGhMgV2hhdHNBcHAgY2hh
bm5lbC4KCg8KBwQFBAACCQESBNUCBAwKDwoHBAUEAAIJAhIE1QIPEAokCgYEBQQAAgoSBNgC
BBMaFCBJbnN0YWdyYW0gY2hhbm5lbC4KCg8KBwQFBAACCgESBNgCBA0KDwoHBAUEAAIKAhIE
2AIQEgpHCgQEBQIAEgTcAgJBGjkgT3B0aW9uYWwuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBv
ZiB0aGUgY2hhbm5lbCBwcm9maWxlLgoKDQoFBAUCAAUSBNwCAggKDQoFBAUCAAESBNwCCRMK
DQoFBAUCAAMSBNwCFhcKDQoFBAUCAAgSBNwCGEAKEAoIBAUCAAicCAASBNwCGT8KOgoEBAUC
ARIE3wICSBosIE9wdGlvbmFsLiBUaGUgdHlwZSBvZiB0aGUgY2hhbm5lbCBwcm9maWxlLgoK
DQoFBAUCAQYSBN8CAg0KDQoFBAUCAQESBN8CDhoKDQoFBAUCAQMSBN8CHR4KDQoFBAUCAQgS
BN8CH0cKEAoIBAUCAQicCAASBN8CIEYKRgoEBAUCAhIE4gICUBo4IE9wdGlvbmFsLiBUaGUg
cGVyc29uYSBwcm9wZXJ0eSBvZiB0aGUgY2hhbm5lbCBwcm9maWxlLgoKDQoFBAUCAgYSBOIC
AhEKDQoFBAUCAgESBOICEiIKDQoFBAUCAgMSBOICJSYKDQoFBAUCAggSBOICJ08KEAoIBAUC
AgicCAASBOICKE4KTgoEBAUCAxIE5QICQRpAIE9wdGlvbmFsLiBXaGV0aGVyIHRvIGRpc2Fi
bGUgRFRNRiAoZHVhbC10b25lIG11bHRpLWZyZXF1ZW5jeSkuCgoNCgUEBQIDBRIE5QICBgoN
CgUEBQIDARIE5QIHEwoNCgUEBQIDAxIE5QIWFwoNCgUEBQIDCBIE5QIYQAoQCggEBQIDCJwI
ABIE5QIZPwr3AQoEBAUCBBIE6wICTRroASBPcHRpb25hbC4gV2hldGhlciB0byBkaXNhYmxl
IHVzZXIgYmFyZ2UtaW4gY29udHJvbCBpbiB0aGUgY29udmVyc2F0aW9uLgogLSAqKnRydWUq
KjogVXNlciBpbnRlcnJ1cHRpb25zIGFyZSBkaXNhYmxlZCB3aGlsZSB0aGUgYWdlbnQgaXMg
c3BlYWtpbmcuCiAtICoqZmFsc2UqKjogVGhlIGFnZW50IHJldGFpbnMgYXV0b21hdGljIGNv
bnRyb2wgb3ZlciB3aGVuIHRoZSB1c2VyIGNhbgogaW50ZXJydXB0LgoKDQoFBAUCBAUSBOsC
AgYKDQoFBAUCBAESBOsCBx8KDQoFBAUCBAMSBOsCIiMKDQoFBAUCBAgSBOsCJEwKEAoIBAUC
BAicCAASBOsCJUsKQQoEBAUCBRIG7gIC7wIvGjEgT3B0aW9uYWwuIFRoZSBjb25maWd1cmF0
aW9uIGZvciB0aGUgd2ViIHdpZGdldC4KCg0KBQQFAgUGEgTuAgIRCg0KBQQFAgUBEgTuAhIj
Cg0KBQQFAgUDEgTuAiYnCg0KBQQFAgUIEgTvAgYuChAKCAQFAgUInAgAEgTvAgctCosBCgQE
BQIGEgTzAgJOGn0gT3B0aW9uYWwuIFRoZSBub2lzZSBzdXBwcmVzc2lvbiBsZXZlbCBvZiB0
aGUgY2hhbm5lbCBwcm9maWxlLgogQXZhaWxhYmxlIHZhbHVlcyBhcmUgImxvdyIsICJtb2Rl
cmF0ZSIsICJoaWdoIiwgInZlcnlfaGlnaCIuCgoNCgUEBQIGBRIE8wICCAoNCgUEBQIGARIE
8wIJIAoNCgUEBQIGAxIE8wIjJAoNCgUEBQIGCBIE8wIlTQoQCggEBQIGCJwIABIE8wImTApJ
CgQEBQIHEgT2AgJOGjsgT3B0aW9uYWwuIENvbmZpZ3VyYXRpb24gc3BlY2lmaWMgdG8gV2hh
dHNBcHAgZGVwbG95bWVudHMuCgoNCgUEBQIHBhIE9gICEAoNCgUEBQIHARIE9gIRIAoNCgUE
BQIHAxIE9gIjJAoNCgUEBQIHCBIE9gIlTQoQCggEBQIHCJwIABIE9gImTApMCgQEBQIIEgb5
AgL6Ai8aPCBPcHRpb25hbC4gQ29uZmlndXJhdGlvbiBzcGVjaWZpYyB0byBJbnN0YWdyYW0g
ZGVwbG95bWVudHMuCgoNCgUEBQIIBhIE+QICEQoNCgUEBQIIARIE+QISIgoNCgUEBQIIAxIE
+QIlJwoNCgUEBQIICBIE+gIGLgoQCggEBQIICJwIABIE+gIHLQpdCgIEBhIG/gIAlAMBGk8g
QSBzcGFuIGlzIGEgdW5pdCBvZiB3b3JrIG9yIGEgc2luZ2xlIG9wZXJhdGlvbiBkdXJpbmcg
dGhlIHJlcXVlc3QgcHJvY2Vzc2luZy4KCgsKAwQGARIE/gIIDAoyCgQEBgIAEgSAAwI+GiQg
T3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBzcGFuLgoKDQoFBAYCAAUSBIADAggKDQoF
BAYCAAESBIADCQ0KDQoFBAYCAAMSBIADEBEKDQoFBAYCAAgSBIADEj0KEAoIBAYCAAicCAAS
BIADEzwKOgoEBAYCARIGgwMChAMyGiogT3V0cHV0IG9ubHkuIFRoZSBzdGFydCB0aW1lIG9m
IHRoZSBzcGFuLgoKDQoFBAYCAQYSBIMDAhsKDQoFBAYCAQESBIMDHCYKDQoFBAYCAQMSBIMD
KSoKDQoFBAYCAQgSBIQDBjEKEAoIBAYCAQicCAASBIQDBzAKOAoEBAYCAhIGhwMCiAMyGigg
T3V0cHV0IG9ubHkuIFRoZSBlbmQgdGltZSBvZiB0aGUgc3Bhbi4KCg0KBQQGAgIGEgSHAwIb
Cg0KBQQGAgIBEgSHAxwkCg0KBQQGAgIDEgSHAycoCg0KBQQGAgIIEgSIAwYxChAKCAQGAgII
nAgAEgSIAwcwCjgKBAQGAgMSBosDAowDMhooIE91dHB1dCBvbmx5LiBUaGUgZHVyYXRpb24g
b2YgdGhlIHNwYW4uCgoNCgUEBgIDBhIEiwMCGgoNCgUEBgIDARIEiwMbIwoNCgUEBgIDAxIE
iwMmJwoNCgUEBgIDCBIEjAMGMQoQCggEBgIDCJwIABIEjAMHMApNCgQEBgIEEgaPAwKQAzIa
PSBPdXRwdXQgb25seS4gS2V5LXZhbHVlIGF0dHJpYnV0ZXMgYXNzb2NpYXRlZCB3aXRoIHRo
ZSBzcGFuLgoKDQoFBAYCBAYSBI8DAhgKDQoFBAYCBAESBI8DGSMKDQoFBAYCBAMSBI8DJicK
DQoFBAYCBAgSBJADBjEKEAoIBAYCBAicCAASBJADBzAKTQoEBAYCBRIEkwMCTBo/IE91dHB1
dCBvbmx5LiBUaGUgY2hpbGQgc3BhbnMgdGhhdCBhcmUgbmVzdGVkIHVuZGVyIHRoaXMgc3Bh
bi4KCg0KBQQGAgUEEgSTAwIKCg0KBQQGAgUGEgSTAwsPCg0KBQQGAgUBEgSTAxAbCg0KBQQG
AgUDEgSTAx4fCg0KBQQGAgUIEgSTAyBLChAKCAQGAgUInAgAEgSTAyFKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Common::Callback ===
    # Fields for Callback
    # Field: python_code Type: 9 ()
    # Field: description Type: 9 ()
    # Field: disabled Type: 8 ()
    # Field: proactive_execution_enabled Type: 8 ()

# === Message: Google::Cloud::Ces::V1::Common::ModelSettings ===
    # Fields for ModelSettings
    # Field: model Type: 9 ()
    # Field: temperature Type: 1 ()

# === Message: Google::Cloud::Ces::V1::Common::TriggerAction ===
    # Fields for TriggerAction
    # Field: respond_immediately Type: 11 (.google.cloud.ces.v1.TriggerAction.RespondImmediately)
    # Field: transfer_agent Type: 11 (.google.cloud.ces.v1.TriggerAction.TransferAgent)
    # Field: generative_answer Type: 11 (.google.cloud.ces.v1.TriggerAction.GenerativeAnswer)

# === Message: Google::Cloud::Ces::V1::Common::TlsConfig ===
    # Fields for TlsConfig
    # Field: ca_certs Type: 11 (.google.cloud.ces.v1.TlsConfig.CaCert)

# === Message: Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig ===
    # Fields for ServiceDirectoryConfig
    # Field: service Type: 9 ()

# === Message: Google::Cloud::Ces::V1::Common::ChannelProfile ===
    # Fields for ChannelProfile
    # Field: profile_id Type: 9 ()
    # Field: channel_type Type: 14 (.google.cloud.ces.v1.ChannelProfile.ChannelType)
    # Field: persona_property Type: 11 (.google.cloud.ces.v1.ChannelProfile.PersonaProperty)
    # Field: disable_dtmf Type: 8 ()
    # Field: disable_barge_in_control Type: 8 ()
    # Field: web_widget_config Type: 11 (.google.cloud.ces.v1.ChannelProfile.WebWidgetConfig)
    # Field: noise_suppression_level Type: 9 ()
    # Field: whatsapp_config Type: 11 (.google.cloud.ces.v1.ChannelProfile.WhatsAppConfig)
    # Field: instagram_config Type: 11 (.google.cloud.ces.v1.ChannelProfile.InstagramConfig)

# Enum: ChannelProfile::ChannelType
our $ChannelProfile_UNKNOWN = 0;
our $ChannelProfile_WEB_UI = 2;
our $ChannelProfile_API = 3;
our $ChannelProfile_TWILIO = 4;
our $ChannelProfile_GOOGLE_TELEPHONY_PLATFORM = 5;
our $ChannelProfile_CONTACT_CENTER_AS_A_SERVICE = 6;
our $ChannelProfile_CONTACT_CENTER_AS_A_SERVICE_CHAT = 11;
our $ChannelProfile_FIVE9 = 7;
our $ChannelProfile_CONTACT_CENTER_INTEGRATION = 8;
our $ChannelProfile_WHATSAPP = 9;
our $ChannelProfile_INSTAGRAM = 10;

# === Message: Google::Cloud::Ces::V1::Common::Span ===
    # Fields for Span
    # Field: name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: attributes Type: 11 (.google.protobuf.Struct)
    # Field: child_spans Type: 11 (.google.cloud.ces.v1.Span)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Common - Compiled Protocol Buffers messages for google/cloud/ces/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Common;

    my $msg = Google::Cloud::Ces::V1::Common::Callback->new({
        python_code => $python_code,
        description => $description,
        disabled => $disabled,
        proactive_execution_enabled => $proactive_execution_enabled,
    });

    # Read or update a field
    my $val = $msg->python_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Common::Callback->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Common::Callback

A callback defines the custom logic to be executed at various stages of
agent interaction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->python_code() >> / C<< $msg->python_code($value) >>

Type: C<String>

Required. The python code to execute for the callback.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Human-readable description of the callback.

=item * C<< $msg->disabled() >> / C<< $msg->disabled($value) >>

Type: C<Bool>

Optional. Whether the callback is disabled. Disabled callbacks are ignored
by the agent.

=item * C<< $msg->proactive_execution_enabled() >> / C<< $msg->proactive_execution_enabled($value) >>

Type: C<Bool>

Optional. If enabled, the callback will also be executed on intermediate
model outputs. This setting only affects after model callback.
B<ENABLE WITH CAUTION>. Typically after model callback only needs to be
executed after receiving all model responses. Enabling proactive execution
may have negative implication on the execution cost and latency, and
should only be enabled in rare situations.

=back

=head2 Google::Cloud::Ces::V1::Common::ModelSettings

Model settings contains various configurations for the LLM model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Optional. The LLM model that the agent should use.
If not set, the agent will inherit the model from its parent agent.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Double>

Optional. If set, this temperature will be used for the LLM model.
Temperature controls the randomness of the model's responses. Lower
temperatures produce responses that are more predictable. Higher
temperatures produce responses that are more creative.

=back

=head2 Google::Cloud::Ces::V1::Common::TriggerAction

Action that is taken when a certain precondition is met.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->respond_immediately() >> / C<< $msg->respond_immediately($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TriggerAction::RespondImmediately>)

Optional. Immediately respond with a preconfigured response.

=item * C<< $msg->transfer_agent() >> / C<< $msg->transfer_agent($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TriggerAction::TransferAgent>)

Optional. Transfer the conversation to a different agent.

=item * C<< $msg->generative_answer() >> / C<< $msg->generative_answer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TriggerAction::GenerativeAnswer>)

Optional. Respond with a generative answer.

=back

=head2 Google::Cloud::Ces::V1::Common::TlsConfig

The TLS configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ca_certs() >> / C<< $msg->ca_certs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TlsConfig::CaCert>)

Required. Specifies a list of allowed custom CA certificates for HTTPS
verification.

=back

=head2 Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig

Configuration for tools using Service Directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Required. The name of [Service
Directory](https://cloud.google.com/service-directory) service.
Format:
`projects/{project}/locations/{location}/namespaces/{namespace}/services/{service}`.
Location of the service directory must be the same as the location of the
app.

=back

=head2 Google::Cloud::Ces::V1::Common::ChannelProfile

A ChannelProfile configures the agent's behavior for a specific communication
channel, such as web UI or telephony.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->profile_id() >> / C<< $msg->profile_id($value) >>

Type: C<String>

Optional. The unique identifier of the channel profile.

=item * C<< $msg->channel_type() >> / C<< $msg->channel_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::ChannelProfile::ChannelType>)

Optional. The type of the channel profile.

=item * C<< $msg->persona_property() >> / C<< $msg->persona_property($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ChannelProfile::PersonaProperty>)

Optional. The persona property of the channel profile.

=item * C<< $msg->disable_dtmf() >> / C<< $msg->disable_dtmf($value) >>

Type: C<Bool>

Optional. Whether to disable DTMF (dual-tone multi-frequency).

=item * C<< $msg->disable_barge_in_control() >> / C<< $msg->disable_barge_in_control($value) >>

Type: C<Bool>

Optional. Whether to disable user barge-in control in the conversation.
- B<true>: User interruptions are disabled while the agent is speaking.
- B<false>: The agent retains automatic control over when the user can
interrupt.

=item * C<< $msg->web_widget_config() >> / C<< $msg->web_widget_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig>)

Optional. The configuration for the web widget.

=item * C<< $msg->noise_suppression_level() >> / C<< $msg->noise_suppression_level($value) >>

Type: C<String>

Optional. The noise suppression level of the channel profile.
Available values are "low", "moderate", "high", "very_high".

=item * C<< $msg->whatsapp_config() >> / C<< $msg->whatsapp_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ChannelProfile::WhatsAppConfig>)

Optional. Configuration specific to WhatsApp deployments.

=item * C<< $msg->instagram_config() >> / C<< $msg->instagram_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ChannelProfile::InstagramConfig>)

Optional. Configuration specific to Instagram deployments.

=back

=head3 Enum: ChannelProfile::ChannelType

=over 4

=item * C<UNKNOWN> => C<0>

=item * C<WEB_UI> => C<2>

=item * C<API> => C<3>

=item * C<TWILIO> => C<4>

=item * C<GOOGLE_TELEPHONY_PLATFORM> => C<5>

=item * C<CONTACT_CENTER_AS_A_SERVICE> => C<6>

=item * C<CONTACT_CENTER_AS_A_SERVICE_CHAT> => C<11>

=item * C<FIVE9> => C<7>

=item * C<CONTACT_CENTER_INTEGRATION> => C<8>

=item * C<WHATSAPP> => C<9>

=item * C<INSTAGRAM> => C<10>

=back

=head2 Google::Cloud::Ces::V1::Common::Span

A span is a unit of work or a single operation during the request processing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the span.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The start time of the span.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The end time of the span.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. The duration of the span.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. Key-value attributes associated with the span.

=item * C<< $msg->child_spans() >> / C<< $msg->child_spans($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Span>)

Output only. The child spans that are nested under this span.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
