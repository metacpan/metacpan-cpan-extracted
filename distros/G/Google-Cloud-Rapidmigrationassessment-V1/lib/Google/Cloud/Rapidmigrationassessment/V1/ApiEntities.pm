package Google::Cloud::Rapidmigrationassessment::V1::ApiEntities;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvcmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50L3YxL2FwaV9lbnRpdGll
cy5wcm90bxIoZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MRofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byIuCgtHdWVzdE9zU2NhbhIfCgtj
b3JlX3NvdXJjZRgBIAEoCVIKY29yZVNvdXJjZSIuCgtWU3BoZXJlU2NhbhIfCgtjb3JlX3Nv
dXJjZRgBIAEoCVIKY29yZVNvdXJjZSK7CQoJQ29sbGVjdG9yEhIKBG5hbWUYASABKAlSBG5h
bWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSVwoGbGFiZWxzGAQgAygLMj8uZ29vZ2xlLmNs
b3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MS5Db2xsZWN0b3IuTGFiZWxzRW50cnlS
BmxhYmVscxIhCgxkaXNwbGF5X25hbWUYBSABKAlSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0
aW9uGAYgASgJUgtkZXNjcmlwdGlvbhInCg9zZXJ2aWNlX2FjY291bnQYByABKAlSDnNlcnZp
Y2VBY2NvdW50EhsKBmJ1Y2tldBgIIAEoCUID4EEDUgZidWNrZXQSMAoUZXhwZWN0ZWRfYXNz
ZXRfY291bnQYCSABKANSEmV4cGVjdGVkQXNzZXRDb3VudBJUCgVzdGF0ZRgKIAEoDjI5Lmdv
b2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjEuQ29sbGVjdG9yLlN0YXRl
QgPgQQNSBXN0YXRlEioKDmNsaWVudF92ZXJzaW9uGAsgASgJQgPgQQNSDWNsaWVudFZlcnNp
b24SXgoNZ3Vlc3Rfb3Nfc2NhbhgMIAEoCzI1Lmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlv
bmFzc2Vzc21lbnQudjEuR3Vlc3RPc1NjYW5CA+BBA1ILZ3Vlc3RPc1NjYW4SXQoMdnNwaGVy
ZV9zY2FuGA0gASgLMjUuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52
MS5WU3BoZXJlU2NhbkID4EEDUgt2c3BoZXJlU2NhbhInCg9jb2xsZWN0aW9uX2RheXMYDiAB
KAVSDmNvbGxlY3Rpb25EYXlzEhkKCGV1bGFfdXJpGA8gASgJUgdldWxhVXJpGjkKC0xhYmVs
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEixwEK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASFgoSU1RBVEVfSU5JVElBTElaSU5HEAES
FgoSU1RBVEVfUkVBRFlfVE9fVVNFEAISFAoQU1RBVEVfUkVHSVNURVJFRBADEhAKDFNUQVRF
X0FDVElWRRAEEhAKDFNUQVRFX1BBVVNFRBAFEhIKDlNUQVRFX0RFTEVUSU5HEAYSGAoUU1RB
VEVfREVDT01NSVNTSU9ORUQQBxIPCgtTVEFURV9FUlJPUhAIOnbqQXMKMXJhcGlkbWlncmF0
aW9uYXNzZXNzbWVudC5nb29nbGVhcGlzLmNvbS9Db2xsZWN0b3ISPnByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0b3JzL3tjb2xsZWN0b3J9ItMECgpB
bm5vdGF0aW9uEhIKBG5hbWUYASABKAlSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
WAoGbGFiZWxzGAQgAygLMkAuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVu
dC52MS5Bbm5vdGF0aW9uLkxhYmVsc0VudHJ5UgZsYWJlbHMSTQoEdHlwZRgFIAEoDjI5Lmdv
b2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjEuQW5ub3RhdGlvbi5UeXBl
UgR0eXBlGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEiTgoEVHlwZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASHgoaVFlQRV9MRUdB
Q1lfRVhQT1JUX0NPTlNFTlQQARIQCgxUWVBFX1FXSUtMQUIQAjp56kF2CjJyYXBpZG1pZ3Jh
dGlvbmFzc2Vzc21lbnQuZ29vZ2xlYXBpcy5jb20vQW5ub3RhdGlvbhJAcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fubm90YXRpb25zL3thbm5vdGF0aW9ufUKw
AgosY29tLmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjFCEEFwaUVu
dGl0aWVzUHJvdG9QAVpoY2xvdWQuZ29vZ2xlLmNvbS9nby9yYXBpZG1pZ3JhdGlvbmFzc2Vz
c21lbnQvYXBpdjEvcmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50cGI7cmFwaWRtaWdyYXRpb25h
c3Nlc3NtZW50cGKqAihHb29nbGUuQ2xvdWQuUmFwaWRNaWdyYXRpb25Bc3Nlc3NtZW50LlYx
ygIoR29vZ2xlXENsb3VkXFJhcGlkTWlncmF0aW9uQXNzZXNzbWVudFxWMeoCK0dvb2dsZTo6
Q2xvdWQ6OlJhcGlkTWlncmF0aW9uQXNzZXNzbWVudDo6VjFK1CgKBxIFDgCqAQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADEKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgBFCgkKAgglEgMWAEUKCAoBCBIDFwB/CgkKAggL
EgMXAH8KCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAxCgkKAggIEgMZADEKCAoBCBID
GgBFCgkKAggBEgMaAEUKCAoBCBIDGwBFCgkKAggpEgMbAEUKCAoBCBIDHABECgkKAggtEgMc
AEQKQwoCBAASBB8AIgEaNyBNZXNzYWdlIGRlc2NyaWJpbmcgYSBNQyBTb3VyY2Ugb2YgdHlw
ZSBHdWVzdCBPUyBTY2FuLgoKCgoDBAABEgMfCBMKSQoEBAACABIDIQIZGjwgcmVmZXJlbmNl
IHRvIHRoZSBjb3JyZXNwb25kaW5nIEd1ZXN0IE9TIFNjYW4gaW4gTUMgU291cmNlLgoKDAoF
BAACAAUSAyECCAoMCgUEAAIAARIDIQkUCgwKBQQAAgADEgMhFxgKQgoCBAESBCUAKAEaNiBN
ZXNzYWdlIGRlc2NyaWJpbmcgYSBNQyBTb3VyY2Ugb2YgdHlwZSBWU3BoZXJlIFNjYW4uCgoK
CgMEAQESAyUIEwpICgQEAQIAEgMnAhkaOyByZWZlcmVuY2UgdG8gdGhlIGNvcnJlc3BvbmRp
bmcgVlNwaGVyZSBTY2FuIGluIE1DIFNvdXJjZS4KCgwKBQQBAgAFEgMnAggKDAoFBAECAAES
AycJFAoMCgUEAQIAAxIDJxcYCjMKAgQCEgUrAIUBARomIE1lc3NhZ2UgZGVzY3JpYmluZyBD
b2xsZWN0b3Igb2JqZWN0LgoKCgoDBAIBEgMrCBEKCwoDBAIHEgQsAi8ECg0KBQQCB50IEgQs
Ai8ECr0CCgQEAgQAEgQ3AlQDGq4CIC0tIFVzaW5nIHN1Z2dlc3Rpb24gZnJvbSBBUEkgTGlu
dGVyIEFuYWx5emVyIGZvciBuZXN0aW5nIGVudW0gLS0KIC0tIGh0dHBzOi8vbGludGVyLmFp
cC5kZXYvMjE2L25lc3RpbmcgLS0KIFN0YXRlIG9mIGEgQ29sbGVjdG9yIChzZXJ2ZXJfc2lk
ZSkuCiBTdGF0ZXMgYXJlIHVzZWQgZm9yIGludGVybmFsIHB1cnBvc2VzIGFuZCBuYW1lZCB0
byBrZWVwCiBjb252ZW50aW9uIG9mIGxlZ2FjeSBwcm9kdWN0OgogaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL21pZ3JhdGUvc3RyYXRvem9uZS9kb2NzL2Fib3V0LXN0cmF0b3Byb2JlLgoK
DAoFBAIEAAESAzcHDAozCgYEAgQAAgASAzkEGhokIENvbGxlY3RvciBzdGF0ZSBpcyBub3Qg
cmVjb2duaXplZC4KCg4KBwQCBAACAAESAzkEFQoOCgcEAgQAAgACEgM5GBkKcwoGBAIEAAIB
EgM9BBsaZCBDb2xsZWN0b3Igc3RhcnRlZCB0byBjcmVhdGUsIGJ1dCBoYXNuJ3QgYmVlbiBj
b21wbGV0ZWQgTUMgc291cmNlIGNyZWF0aW9uCiBhbmQgZGIgb2JqZWN0IGNyZWF0aW9uLgoK
DgoHBAIEAAIBARIDPQQWCg4KBwQCBAACAQISAz0ZGgpiCgYEAgQAAgISA0EEGxpTIENvbGxl
Y3RvciBoYXMgYmVlbiBjcmVhdGVkLCBNQyBzb3VyY2UgY3JlYXRpb24gYW5kIGRiIG9iamVj
dCBjcmVhdGlvbgogY29tcGxldGVkLgoKDgoHBAIEAAICARIDQQQWCg4KBwQCBAACAgISA0EZ
GgpCCgYEAgQAAgMSA0QEGRozIENvbGxlY3RvciBjbGllbnQgaGFzIGJlZW4gcmVnaXN0ZXJl
ZCB3aXRoIGNsaWVudC4KCg4KBwQCBAACAwESA0QEFAoOCgcEAgQAAgMCEgNEFxgKNwoGBAIE
AAIEEgNHBBUaKCBDb2xsZWN0b3IgY2xpZW50IGlzIGFjdGl2ZWx5IHNjYW5uaW5nLgoKDgoH
BAIEAAIEARIDRwQQCg4KBwQCBAACBAISA0cTFAo0CgYEAgQAAgUSA0oEFRolIENvbGxlY3Rv
ciBpcyBub3QgYWN0aXZlbHkgc2Nhbm5pbmcuCgoOCgcEAgQAAgUBEgNKBBAKDgoHBAIEAAIF
AhIDShMUCkMKBgQCBAACBhIDTQQXGjQgQ29sbGVjdG9yIGlzIHN0YXJ0aW5nIGJhY2tncm91
bmQgam9iIGZvciBkZWxldGlvbi4KCg4KBwQCBAACBgESA00EEgoOCgcEAgQAAgYCEgNNFRYK
PAoGBAIEAAIHEgNQBB0aLSBDb2xsZWN0b3IgY29tcGxldGVkIGFsbCB0YXNrcyBmb3IgZGVs
ZXRpb24uCgoOCgcEAgQAAgcBEgNQBBgKDgoHBAIEAAIHAhIDUBscCi0KBgQCBAACCBIDUwQU
Gh4gQ29sbGVjdG9yIGlzIGluIGVycm9yIHN0YXRlLgoKDgoHBAIEAAIIARIDUwQPCg4KBwQC
BAACCAISA1MSEwogCgQEAgIAEgNXAhIaEyBuYW1lIG9mIHJlc291cmNlLgoKDAoFBAICAAUS
A1cCCAoMCgUEAgIAARIDVwkNCgwKBQQCAgADEgNXEBEKLwoEBAICARIEWgJbMhohIE91dHB1
dCBvbmx5LiBDcmVhdGUgdGltZSBzdGFtcC4KCgwKBQQCAgEGEgNaAhsKDAoFBAICAQESA1oc
JwoMCgUEAgIBAxIDWiorCgwKBQQCAgEIEgNbBjEKDwoIBAICAQicCAASA1sHMAovCgQEAgIC
EgReAl8yGiEgT3V0cHV0IG9ubHkuIFVwZGF0ZSB0aW1lIHN0YW1wLgoKDAoFBAICAgYSA14C
GwoMCgUEAgICARIDXhwnCgwKBQQCAgIDEgNeKisKDAoFBAICAggSA18GMQoPCggEAgICCJwI
ABIDXwcwCikKBAQCAgMSA2ICIRocIExhYmVscyBhcyBrZXkgdmFsdWUgcGFpcnMuCgoMCgUE
AgIDBhIDYgIVCgwKBQQCAgMBEgNiFhwKDAoFBAICAwMSA2IfIAo0CgQEAgIEEgNlAhoaJyBV
c2VyIHNwZWNpZmllZCBuYW1lIG9mIHRoZSBDb2xsZWN0b3IuCgoMCgUEAgIEBRIDZQIICgwK
BQQCAgQBEgNlCRUKDAoFBAICBAMSA2UYGQo7CgQEAgIFEgNoAhkaLiBVc2VyIHNwZWNpZmll
ZCBkZXNjcmlwdGlvbiBvZiB0aGUgQ29sbGVjdG9yLgoKDAoFBAICBQUSA2gCCAoMCgUEAgIF
ARIDaAkUCgwKBQQCAgUDEgNoFxgKSwoEBAICBhIDawIdGj4gU2VydmljZSBBY2NvdW50IGVt
YWlsIHVzZWQgdG8gaW5nZXN0IGRhdGEgdG8gdGhpcyBDb2xsZWN0b3IuCgoMCgUEAgIGBRID
awIICgwKBQQCAgYBEgNrCRgKDAoFBAICBgMSA2sbHAprCgQEAgIHEgNvAkAaXiBPdXRwdXQg
b25seS4gU3RvcmUgY2xvdWQgc3RvcmFnZSBidWNrZXQgbmFtZSAod2hpY2ggaXMgYSBndWlk
KSBjcmVhdGVkIHdpdGgKIHRoaXMgQ29sbGVjdG9yLgoKDAoFBAICBwUSA28CCAoMCgUEAgIH
ARIDbwkPCgwKBQQCAgcDEgNvEhMKDAoFBAICBwgSA28UPwoPCggEAgIHCJwIABIDbxU+CjMK
BAQCAggSA3ICIRomIFVzZXIgc3BlY2lmaWVkIGV4cGVjdGVkIGFzc2V0IGNvdW50LgoKDAoF
BAICCAUSA3ICBwoMCgUEAgIIARIDcggcCgwKBQQCAggDEgNyHyAKMwoEBAICCRIDdQI/GiYg
T3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBDb2xsZWN0b3IuCgoMCgUEAgIJBhIDdQIHCgwK
BQQCAgkBEgN1CA0KDAoFBAICCQMSA3UQEgoMCgUEAgIJCBIDdRM+Cg8KCAQCAgkInAgAEgN1
FD0KKwoEBAICChIDeAJJGh4gT3V0cHV0IG9ubHkuIENsaWVudCB2ZXJzaW9uLgoKDAoFBAIC
CgUSA3gCCAoMCgUEAgIKARIDeAkXCgwKBQQCAgoDEgN4GhwKDAoFBAICCggSA3gdSAoPCggE
AgIKCJwIABIDeB5HCkEKBAQCAgsSA3sCTRo0IE91dHB1dCBvbmx5LiBSZWZlcmVuY2UgdG8g
TUMgU291cmNlIEd1ZXN0IE9zIFNjYW4uCgoMCgUEAgILBhIDewINCgwKBQQCAgsBEgN7DhsK
DAoFBAICCwMSA3seIAoMCgUEAgILCBIDeyFMCg8KCAQCAgsInAgAEgN7IksKQAoEBAICDBID
fgJMGjMgT3V0cHV0IG9ubHkuIFJlZmVyZW5jZSB0byBNQyBTb3VyY2UgdnNwaGVyZV9zY2Fu
LgoKDAoFBAICDAYSA34CDQoMCgUEAgIMARIDfg4aCgwKBQQCAgwDEgN+HR8KDAoFBAICDAgS
A34gSwoPCggEAgIMCJwIABIDfiFKCi4KBAQCAg0SBIEBAh0aICBIb3cgbWFueSBkYXlzIHRv
IGNvbGxlY3QgZGF0YS4KCg0KBQQCAg0FEgSBAQIHCg0KBQQCAg0BEgSBAQgXCg0KBQQCAg0D
EgSBARocCkgKBAQCAg4SBIQBAhcaOiBVcmkgZm9yIEVVTEEgKEVuZCBVc2VyIExpY2Vuc2Ug
QWdyZWVtZW50KSBmcm9tIGN1c3RvbWVyLgoKDQoFBAICDgUSBIQBAggKDQoFBAICDgESBIQB
CREKDQoFBAICDgMSBIQBFBYKMAoCBAMSBogBAKoBARoiIE1lc3NhZ2UgZGVzY3JpYmluZyBh
biBBbm5vdGF0aW9uCgoLCgMEAwESBIgBCBIKDQoDBAMHEgaJAQKMAQQKDwoFBAMHnQgSBokB
AowBBAoyCgQEAwQAEgaPAQKYAQMaIiBUeXBlcyBmb3IgcHJvamVjdCBsZXZlbCBzZXR0aW5n
LgoKDQoFBAMEAAESBI8BBwsKHgoGBAMEAAIAEgSRAQQZGg4gVW5rbm93biB0eXBlCgoPCgcE
AwQAAgABEgSRAQQUCg8KBwQDBAACAAISBJEBFxgKTwoGBAMEAAIBEgSUAQQjGj8gSW5kaWNh
dGVzIHRoYXQgdGhpcyBwcm9qZWN0IGhhcyBvcHRlZCBpbnRvIFN0cmF0b1pvbmUgZXhwb3J0
LgoKDwoHBAMEAAIBARIElAEEHgoPCgcEAwQAAgECEgSUASEiCkQKBgQDBAACAhIElwEEFRo0
IEluZGljYXRlcyB0aGF0IHRoaXMgcHJvamVjdCBpcyBjcmVhdGVkIGJ5IFF3aWtsYWIuCgoP
CgcEAwQAAgIBEgSXAQQQCg8KBwQDBAACAgISBJcBExQKIQoEBAMCABIEmwECEhoTIG5hbWUg
b2YgcmVzb3VyY2UuCgoNCgUEAwIABRIEmwECCAoNCgUEAwIAARIEmwEJDQoNCgUEAwIAAxIE
mwEQEQoxCgQEAwIBEgaeAQKfATIaISBPdXRwdXQgb25seS4gQ3JlYXRlIHRpbWUgc3RhbXAu
CgoNCgUEAwIBBhIEngECGwoNCgUEAwIBARIEngEcJwoNCgUEAwIBAxIEngEqKwoNCgUEAwIB
CBIEnwEGMQoQCggEAwIBCJwIABIEnwEHMAoxCgQEAwICEgaiAQKjATIaISBPdXRwdXQgb25s
eS4gVXBkYXRlIHRpbWUgc3RhbXAuCgoNCgUEAwICBhIEogECGwoNCgUEAwICARIEogEcJwoN
CgUEAwICAxIEogEqKwoNCgUEAwICCBIEowEGMQoQCggEAwICCJwIABIEowEHMAoqCgQEAwID
EgSmAQIhGhwgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycy4KCg0KBQQDAgMGEgSmAQIVCg0K
BQQDAgMBEgSmARYcCg0KBQQDAgMDEgSmAR8gCiYKBAQDAgQSBKkBAhAaGCBUeXBlIG9mIGFu
IGFubm90YXRpb24uCgoNCgUEAwIEBhIEqQECBgoNCgUEAwIEARIEqQEHCwoNCgUEAwIEAxIE
qQEOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan ===
    # Fields for GuestOsScan
    # Field: core_source Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::VSphereScan ===
    # Fields for VSphereScan
    # Field: core_source Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector ===
    # Fields for Collector
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.rapidmigrationassessment.v1.Collector.LabelsEntry)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: bucket Type: 9 ()
    # Field: expected_asset_count Type: 3 ()
    # Field: state Type: 14 (.google.cloud.rapidmigrationassessment.v1.Collector.State)
    # Field: client_version Type: 9 ()
    # Field: guest_os_scan Type: 11 (.google.cloud.rapidmigrationassessment.v1.GuestOsScan)
    # Field: vsphere_scan Type: 11 (.google.cloud.rapidmigrationassessment.v1.VSphereScan)
    # Field: collection_days Type: 5 ()
    # Field: eula_uri Type: 9 ()

# Enum: Collector::State
our $Collector_STATE_UNSPECIFIED = 0;
our $Collector_STATE_INITIALIZING = 1;
our $Collector_STATE_READY_TO_USE = 2;
our $Collector_STATE_REGISTERED = 3;
our $Collector_STATE_ACTIVE = 4;
our $Collector_STATE_PAUSED = 5;
our $Collector_STATE_DELETING = 6;
our $Collector_STATE_DECOMMISSIONED = 7;
our $Collector_STATE_ERROR = 8;

# === Message: Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation ===
    # Fields for Annotation
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.rapidmigrationassessment.v1.Annotation.LabelsEntry)
    # Field: type Type: 14 (.google.cloud.rapidmigrationassessment.v1.Annotation.Type)

# Enum: Annotation::Type
our $Annotation_TYPE_UNSPECIFIED = 0;
our $Annotation_TYPE_LEGACY_EXPORT_CONSENT = 1;
our $Annotation_TYPE_QWIKLAB = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Rapidmigrationassessment::V1::ApiEntities - Compiled Protocol Buffers messages for google/cloud/rapidmigrationassessment/v1/api_entities.proto

=head1 SYNOPSIS

    use Google::Cloud::Rapidmigrationassessment::V1::ApiEntities;

    my $msg = Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan->new({
        core_source => $core_source,
    });

    # Read or update a field
    my $val = $msg->core_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/rapidmigrationassessment/v1/api_entities.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan

Message describing a MC Source of type Guest OS Scan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->core_source() >> / C<< $msg->core_source($value) >>

Type: C<String>

reference to the corresponding Guest OS Scan in MC Source.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::VSphereScan

Message describing a MC Source of type VSphere Scan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->core_source() >> / C<< $msg->core_source($value) >>

Type: C<String>

reference to the corresponding VSphere Scan in MC Source.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector

Message describing Collector object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

name of resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time stamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time stamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

User specified name of the Collector.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified description of the Collector.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Service Account email used to ingest data to this Collector.

=item * C<< $msg->bucket() >> / C<< $msg->bucket($value) >>

Type: C<String>

Output only. Store cloud storage bucket name (which is a guid) created with
this Collector.

=item * C<< $msg->expected_asset_count() >> / C<< $msg->expected_asset_count($value) >>

Type: C<Int64>

User specified expected asset count.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Rapidmigrationassessment::V1::Collector::State>)

Output only. State of the Collector.

=item * C<< $msg->client_version() >> / C<< $msg->client_version($value) >>

Type: C<String>

Output only. Client version.

=item * C<< $msg->guest_os_scan() >> / C<< $msg->guest_os_scan($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::GuestOsScan>)

Output only. Reference to MC Source Guest Os Scan.

=item * C<< $msg->vsphere_scan() >> / C<< $msg->vsphere_scan($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::VSphereScan>)

Output only. Reference to MC Source vsphere_scan.

=item * C<< $msg->collection_days() >> / C<< $msg->collection_days($value) >>

Type: C<Int32>

How many days to collect data.

=item * C<< $msg->eula_uri() >> / C<< $msg->eula_uri($value) >>

Type: C<String>

Uri for EULA (End User License Agreement) from customer.

=back

=head3 Enum: Collector::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STATE_INITIALIZING> => C<1>

=item * C<STATE_READY_TO_USE> => C<2>

=item * C<STATE_REGISTERED> => C<3>

=item * C<STATE_ACTIVE> => C<4>

=item * C<STATE_PAUSED> => C<5>

=item * C<STATE_DELETING> => C<6>

=item * C<STATE_DECOMMISSIONED> => C<7>

=item * C<STATE_ERROR> => C<8>

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation

Message describing an Annotation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

name of resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time stamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time stamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Rapidmigrationassessment::V1::Annotation::Type>)

Type of an annotation.

=back

=head3 Enum: Annotation::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<TYPE_LEGACY_EXPORT_CONSENT> => C<1>

=item * C<TYPE_QWIKLAB> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
