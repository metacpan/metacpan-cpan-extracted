package Google::Cloud::Sql::V1beta4::CloudSqlConnect;

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
    eval { require Google::Cloud::Sql::V1beta4::CloudSqlResources };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX2Nvbm5lY3QucHJvdG8SGGdv
b2dsZS5jbG91ZC5zcWwudjFiZXRhNBocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aMmdvb2dsZS9jbG91ZC9zcWwvdjFiZXRhNC9jbG91ZF9zcWxfcmVzb3VyY2VzLnByb3Rv
Gh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8ijwEKGUdldENvbm5lY3RTZXR0aW5nc1JlcXVlc3QSGgoIaW5zdGFuY2UY
ASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSPAoJcmVhZF90aW1l
GAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUghyZWFkVGltZSJgCh1S
ZXNvbHZlQ29ubmVjdFNldHRpbmdzUmVxdWVzdBIeCghkbnNfbmFtZRgBIAEoCUID4EECUgdk
bnNOYW1lEh8KCGxvY2F0aW9uGAIgASgJQgPgQQJSCGxvY2F0aW9uIrILCg9Db25uZWN0U2V0
dGluZ3MSEgoEa2luZBgBIAEoCVIEa2luZBJHCg5zZXJ2ZXJfY2FfY2VydBgCIAEoCzIhLmdv
b2dsZS5jbG91ZC5zcWwudjFiZXRhNC5Tc2xDZXJ0UgxzZXJ2ZXJDYUNlcnQSRgoMaXBfYWRk
cmVzc2VzGAMgAygLMiMuZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LklwTWFwcGluZ1ILaXBB
ZGRyZXNzZXMSFgoGcmVnaW9uGAQgASgJUgZyZWdpb24SVwoQZGF0YWJhc2VfdmVyc2lvbhgf
IAEoDjIsLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5TcWxEYXRhYmFzZVZlcnNpb25SD2Rh
dGFiYXNlVmVyc2lvbhJLCgxiYWNrZW5kX3R5cGUYICABKA4yKC5nb29nbGUuY2xvdWQuc3Fs
LnYxYmV0YTQuU3FsQmFja2VuZFR5cGVSC2JhY2tlbmRUeXBlEh8KC3BzY19lbmFibGVkGCEg
ASgIUgpwc2NFbmFibGVkEhkKCGRuc19uYW1lGCIgASgJUgdkbnNOYW1lElYKDnNlcnZlcl9j
YV9tb2RlGCMgASgOMjAuZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LkNvbm5lY3RTZXR0aW5n
cy5DYU1vZGVSDHNlcnZlckNhTW9kZRJHCiBjdXN0b21fc3ViamVjdF9hbHRlcm5hdGl2ZV9u
YW1lcxglIAMoCVIdY3VzdG9tU3ViamVjdEFsdGVybmF0aXZlTmFtZXMSSgoJZG5zX25hbWVz
GCYgAygLMiguZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LkRuc05hbWVNYXBwaW5nQgPgQQNS
CGRuc05hbWVzEiIKCm5vZGVfY291bnQYPyABKAVIAFIJbm9kZUNvdW50iAEBEloKBW5vZGVz
GEAgAygLMj8uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LkNvbm5lY3RTZXR0aW5ncy5Db25u
ZWN0UG9vbE5vZGVDb25maWdCA+BBA1IFbm9kZXMSdgoUbWR4X3Byb3RvY29sX3N1cHBvcnQY
JyADKA4yPC5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuQ29ubmVjdFNldHRpbmdzLk1keFBy
b3RvY29sU3VwcG9ydEIG4EED4EEBUhJtZHhQcm90b2NvbFN1cHBvcnQSLwoPY29ubmVjdGlv
bl9uYW1lGCggASgJQgbgQQPgQQFSDmNvbm5lY3Rpb25OYW1lGokCChVDb25uZWN0UG9vbE5v
ZGVDb25maWcSHAoEbmFtZRgBIAEoCUID4EEDSABSBG5hbWWIAQESSwoMaXBfYWRkcmVzc2Vz
GAIgAygLMiMuZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LklwTWFwcGluZ0ID4EEDUgtpcEFk
ZHJlc3NlcxIjCghkbnNfbmFtZRgDIAEoCUID4EEDSAFSB2Ruc05hbWWIAQESSgoJZG5zX25h
bWVzGAQgAygLMiguZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LkRuc05hbWVNYXBwaW5nQgPg
QQNSCGRuc05hbWVzQgcKBV9uYW1lQgsKCV9kbnNfbmFtZSJ5CgZDYU1vZGUSFwoTQ0FfTU9E
RV9VTlNQRUNJRklFRBAAEh4KGkdPT0dMRV9NQU5BR0VEX0lOVEVSTkFMX0NBEAESGQoVR09P
R0xFX01BTkFHRURfQ0FTX0NBEAISGwoXQ1VTVE9NRVJfTUFOQUdFRF9DQVNfQ0EQAyJUChJN
ZHhQcm90b2NvbFN1cHBvcnQSJAogTURYX1BST1RPQ09MX1NVUFBPUlRfVU5TUEVDSUZJRUQQ
ABIYChRDTElFTlRfUFJPVE9DT0xfVFlQRRABQg0KC19ub2RlX2NvdW50IqICChxHZW5lcmF0
ZUVwaGVtZXJhbENlcnRSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5jZRIYCgdw
cm9qZWN0GAIgASgJUgdwcm9qZWN0Eh4KCnB1YmxpY19rZXkYAyABKAlSCnB1YmxpY19rZXkS
JwoMYWNjZXNzX3Rva2VuGAQgASgJQgPgQQFSDGFjY2Vzc190b2tlbhI8CglyZWFkX3RpbWUY
ByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQFSCHJlYWRUaW1lEkUKDnZh
bGlkX2R1cmF0aW9uGAwgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFSDXZh
bGlkRHVyYXRpb24iaQodR2VuZXJhdGVFcGhlbWVyYWxDZXJ0UmVzcG9uc2USSAoOZXBoZW1l
cmFsX2NlcnQYASABKAsyIS5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuU3NsQ2VydFINZXBo
ZW1lcmFsQ2VydDKIBgoRU3FsQ29ubmVjdFNlcnZpY2USwgEKEkdldENvbm5lY3RTZXR0aW5n
cxIzLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5HZXRDb25uZWN0U2V0dGluZ3NSZXF1ZXN0
GikuZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LkNvbm5lY3RTZXR0aW5ncyJMgtPkkwJGEkQv
c3FsL3YxYmV0YTQvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2Nv
bm5lY3RTZXR0aW5ncxLNAQoWUmVzb2x2ZUNvbm5lY3RTZXR0aW5ncxI3Lmdvb2dsZS5jbG91
ZC5zcWwudjFiZXRhNC5SZXNvbHZlQ29ubmVjdFNldHRpbmdzUmVxdWVzdBopLmdvb2dsZS5j
bG91ZC5zcWwudjFiZXRhNC5Db25uZWN0U2V0dGluZ3MiT4LT5JMCSRJHL3NxbC92MWJldGE0
L2xvY2F0aW9ucy97bG9jYXRpb259L2Rucy97ZG5zX25hbWV9OnJlc29sdmVDb25uZWN0U2V0
dGluZ3MS3wEKFUdlbmVyYXRlRXBoZW1lcmFsQ2VydBI2Lmdvb2dsZS5jbG91ZC5zcWwudjFi
ZXRhNC5HZW5lcmF0ZUVwaGVtZXJhbENlcnRSZXF1ZXN0GjcuZ29vZ2xlLmNsb3VkLnNxbC52
MWJldGE0LkdlbmVyYXRlRXBoZW1lcmFsQ2VydFJlc3BvbnNlIlWC0+STAk8iSi9zcWwvdjFi
ZXRhNC9wcm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX06Z2VuZXJhdGVF
cGhlbWVyYWxDZXJ0OgEqGnzKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbdJBX2h0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9zcWxzZXJ2aWNlLmFkbWluQmYKHGNvbS5nb29nbGUuY2xvdWQu
c3FsLnYxYmV0YTRCFENsb3VkU3FsQ29ubmVjdFByb3RvUAFaLmNsb3VkLmdvb2dsZS5jb20v
Z28vc3FsL2FwaXYxYmV0YTQvc3FscGI7c3FscGJKzEEKBxIFDgDxAQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAh
CgkKAgMCEgMUACkKCQoCAwMSAxUAPAoJCgIDBBIDFgAoCgkKAgMFEgMXACkKCAoBCBIDGQBF
CgkKAggLEgMZAEUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA1CgkKAggIEgMbADUK
CAoBCBIDHAA1CgkKAggBEgMcADUKKAoCBgASBB8AQAEaHCBDbG91ZCBTUUwgY29ubmVjdCBz
ZXJ2aWNlLgoKCgoDBgABEgMfCBkKCgoDBgADEgMgAj8KDAoFBgADmQgSAyACPwoLCgMGAAMS
BCECIzkKDQoFBgADmggSBCECIzkKRgoEBgACABIEJgIqAxo4IFJldHJpZXZlcyBjb25uZWN0
IHNldHRpbmdzIGFib3V0IGEgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBgACAAESAyYGGAoM
CgUGAAIAAhIDJhkyCgwKBQYAAgADEgMmPUwKDQoFBgACAAQSBCcEKQYKEQoJBgACAASwyrwi
EgQnBCkGCmMKBAYAAgESBC4CMwMaVSBSZXRyaWV2ZXMgY29ubmVjdCBzZXR0aW5ncyBhYm91
dCBhIENsb3VkIFNRTCBpbnN0YW5jZSB1c2luZyB0aGUgaW5zdGFuY2UKIEROUyBuYW1lLgoK
DAoFBgACAQESAy4GHAoMCgUGAAIBAhIDLh06CgwKBQYAAgEDEgMvDx4KDQoFBgACAQQSBDAE
MgYKEQoJBgACAQSwyrwiEgQwBDIGCvkBCgQGAAICEgQ5Aj8DGuoBIEdlbmVyYXRlcyBhIHNo
b3J0LWxpdmVkIFg1MDkgY2VydGlmaWNhdGUgY29udGFpbmluZyB0aGUgcHJvdmlkZWQgcHVi
bGljIGtleQogYW5kIHNpZ25lZCBieSBhIHByaXZhdGUga2V5IHNwZWNpZmljIHRvIHRoZSB0
YXJnZXQgaW5zdGFuY2UuIFVzZXJzIG1heSB1c2UKIHRoZSBjZXJ0aWZpY2F0ZSB0byBhdXRo
ZW50aWNhdGUgYXMgdGhlbXNlbHZlcyB3aGVuIGNvbm5lY3RpbmcgdG8gdGhlCiBkYXRhYmFz
ZS4KCgwKBQYAAgIBEgM5BhsKDAoFBgACAgISAzkcOAoMCgUGAAICAxIDOg8sCg0KBQYAAgIE
EgQ7BD4GChEKCQYAAgIEsMq8IhIEOwQ+BgoxCgIEABIEQwBOARolIENvbm5lY3Qgc2V0dGlu
Z3MgcmV0cmlldmFsIHJlcXVlc3QuCgoKCgMEAAESA0MIIQpLCgQEAAIAEgNFAhYaPiBDbG91
ZCBTUUwgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJ
RC4KCgwKBQQAAgAFEgNFAggKDAoFBAACAAESA0UJEQoMCgUEAAIAAxIDRRQVCkQKBAQAAgES
A0gCFRo3IFByb2plY3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5z
dGFuY2UuCgoMCgUEAAIBBRIDSAIICgwKBQQAAgEBEgNICRAKDAoFBAACAQMSA0gTFApfCgQE
AAICEgRMAk0vGlEgT3B0aW9uYWwuIE9wdGlvbmFsIHNuYXBzaG90IHJlYWQgdGltZXN0YW1w
IHRvIHRyYWRlIGZyZXNobmVzcyBmb3IKIHBlcmZvcm1hbmNlLgoKDAoFBAACAgYSA0wCGwoM
CgUEAAICARIDTBwlCgwKBQQAAgIDEgNMKCkKDAoFBAACAggSA00GLgoPCggEAAICCJwIABID
TQctCjEKAgQBEgRRAFcBGiUgQ29ubmVjdCBzZXR0aW5ncyByZXRyaWV2YWwgcmVxdWVzdC4K
CgoKAwQBARIDUQglClUKBAQBAgASA1MCPxpIIFJlcXVpcmVkLiBDbG91ZCBTUUwgaW5zdGFu
Y2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCgwKBQQBAgAF
EgNTAggKDAoFBAECAAESA1MJEQoMCgUEAQIAAxIDUxQVCgwKBQQBAgAIEgNTFj4KDwoIBAEC
AAicCAASA1MXPQo0CgQEAQIBEgNWAj8aJyBSZXF1aXJlZC4gVGhlIHJlZ2lvbiBvZiB0aGUg
aW5zdGFuY2UuCgoMCgUEAQIBBRIDVgIICgwKBQQBAgEBEgNWCREKDAoFBAECAQMSA1YUFQoM
CgUEAQIBCBIDVhY+Cg8KCAQBAgEInAgAEgNWFz0KMwoCBAISBVoA0gEBGiYgQ29ubmVjdCBz
ZXR0aW5ncyByZXRyaWV2YWwgcmVzcG9uc2UuCgoKCgMEAgESA1oIFwpRCgQEAgQAEgRcAmsD
GkMgVmFyaW91cyBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgKENBKSBtb2RlcyBmb3IgY2VydGlm
aWNhdGUgc2lnbmluZy4KCgwKBQQCBAABEgNcBw0KZQoGBAIEAAIAEgNfBBwaViBDQSBtb2Rl
IGlzIHVuc3BlY2lmaWVkLiBJdCBpcyBlZmZlY3RpdmVseSB0aGUgc2FtZSBhcwogYEdPT0dM
RV9NQU5BR0VEX0lOVEVSTkFMX0NBYC4KCg4KBwQCBAACAAESA18EFwoOCgcEAgQAAgACEgNf
GhsKOAoGBAIEAAIBEgNiBCMaKSBHb29nbGUtbWFuYWdlZCBzZWxmLXNpZ25lZCBpbnRlcm5h
bCBDQS4KCg4KBwQCBAACAQESA2IEHgoOCgcEAgQAAgECEgNiISIKhAEKBgQCBAACAhIDZgQe
GnUgR29vZ2xlLW1hbmFnZWQgcmVnaW9uYWwgQ0EgcGFydCBvZiByb290IENBIGhpZXJhcmNo
eSBob3N0ZWQgb24gR29vZ2xlCiBDbG91ZCdzIENlcnRpZmljYXRlIEF1dGhvcml0eSBTZXJ2
aWNlIChDQVMpLgoKDgoHBAIEAAICARIDZgQZCg4KBwQCBAACAgISA2YcHQpjCgYEAgQAAgMS
A2oEIBpUIEN1c3RvbWVyLW1hbmFnZWQgQ0EgaG9zdGVkIG9uIEdvb2dsZSBDbG91ZCdzIENl
cnRpZmljYXRlIEF1dGhvcml0eQogU2VydmljZSAoQ0FTKS4KCg4KBwQCBAACAwESA2oEGwoO
CgcEAgQAAgMCEgNqHh8KQgoEBAIDABIEbgJ+Axo0IERldGFpbHMgb2YgYSBzaW5nbGUgcmVh
ZCBwb29sIG5vZGUgb2YgYSByZWFkIHBvb2wuCgoMCgUEAgMAARIDbgofCl4KBgQCAwACABID
cQRJGk8gT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSByZWFkIHBvb2wgbm9kZS4gRG9l
c24ndCBpbmNsdWRlIHRoZSBwcm9qZWN0CiBJRC4KCg4KBwQCAwACAAQSA3EEDAoOCgcEAgMA
AgAFEgNxDRMKDgoHBAIDAAIAARIDcRQYCg4KBwQCAwACAAMSA3EbHAoOCgcEAgMAAgAIEgNx
HUgKEQoKBAIDAAIACJwIABIDcR5HCnMKBgQCAwACARIEdQR2NBpjIE91dHB1dCBvbmx5LiBN
YXBwaW5ncyBjb250YWluaW5nIElQIGFkZHJlc3NlcyB0aGF0IGNhbiBiZSB1c2VkIHRvIGNv
bm5lY3QKIHRvIHRoZSByZWFkIHBvb2wgbm9kZS4KCg4KBwQCAwACAQQSA3UEDAoOCgcEAgMA
AgEGEgN1DRYKDgoHBAIDAAIBARIDdRcjCg4KBwQCAwACAQMSA3UmJwoOCgcEAgMAAgEIEgN2
CDMKEQoKBAIDAAIBCJwIABIDdgkyCkEKBgQCAwACAhIDeQRNGjIgT3V0cHV0IG9ubHkuIFRo
ZSBETlMgbmFtZSBvZiB0aGUgcmVhZCBwb29sIG5vZGUuCgoOCgcEAgMAAgIEEgN5BAwKDgoH
BAIDAAICBRIDeQ0TCg4KBwQCAwACAgESA3kUHAoOCgcEAgMAAgIDEgN5HyAKDgoHBAIDAAIC
CBIDeSFMChEKCgQCAwACAgicCAASA3kiSwpRCgYEAgMAAgMSBHwEfTQaQSBPdXRwdXQgb25s
eS4gVGhlIGxpc3Qgb2YgRE5TIG5hbWVzIHVzZWQgYnkgdGhpcyByZWFkIHBvb2wgbm9kZS4K
Cg4KBwQCAwACAwQSA3wEDAoOCgcEAgMAAgMGEgN8DRsKDgoHBAIDAAIDARIDfBwlCg4KBwQC
AwACAwMSA3woKQoOCgcEAgMAAgMIEgN9CDMKEQoKBAIDAAIDCJwIABIDfQkyCmUKBAQCBAES
BoIBAogBAxpVIE1keFByb3RvY29sU3VwcG9ydCBkZXNjcmliZXMgcGFydHMgb2YgdGhlIE1E
WCBwcm90b2NvbCBzdXBwb3J0ZWQgYnkgdGhpcwogaW5zdGFuY2UuCgoNCgUEAgQBARIEggEH
GQogCgYEAgQBAgASBIQBBCkaECBOb3Qgc3BlY2lmaWVkLgoKDwoHBAIEAQIAARIEhAEEJAoP
CgcEAgQBAgACEgSEAScoClEKBgQCBAECARIEhwEEHRpBIENsaWVudCBzaG91bGQgc2VuZCB0
aGUgY2xpZW50IHByb3RvY29sIHR5cGUgaW4gdGhlIE1EWCByZXF1ZXN0LgoKDwoHBAIEAQIB
ARIEhwEEGAoPCgcEAgQBAgECEgSHARscCjUKBAQCAgASBIsBAhIaJyBUaGlzIGlzIGFsd2F5
cyBgc3FsI2Nvbm5lY3RTZXR0aW5nc2AuCgoNCgUEAgIABRIEiwECCAoNCgUEAgIAARIEiwEJ
DQoNCgUEAgIAAxIEiwEQEQoiCgQEAgIBEgSOAQIdGhQgU1NMIGNvbmZpZ3VyYXRpb24uCgoN
CgUEAgIBBhIEjgECCQoNCgUEAgIBARIEjgEKGAoNCgUEAgIBAxIEjgEbHAo7CgQEAgICEgSR
AQImGi0gVGhlIGFzc2lnbmVkIElQIGFkZHJlc3NlcyBmb3IgdGhlIGluc3RhbmNlLgoKDQoF
BAICAgQSBJEBAgoKDQoFBAICAgYSBJEBCxQKDQoFBAICAgESBJEBFSEKDQoFBAICAgMSBJEB
JCUKjQEKBAQCAgMSBJUBAhQafyBUaGUgY2xvdWQgcmVnaW9uIGZvciB0aGUgaW5zdGFuY2Uu
IGUuZy4gYHVzLWNlbnRyYWwxYCwgYGV1cm9wZS13ZXN0MWAuCiBUaGUgcmVnaW9uIGNhbm5v
dCBiZSBjaGFuZ2VkIGFmdGVyIGluc3RhbmNlIGNyZWF0aW9uLgoKDQoFBAICAwUSBJUBAggK
DQoFBAICAwESBJUBCQ8KDQoFBAICAwMSBJUBEhMKxQQKBAQCAgQSBKIBAisatgQgVGhlIGRh
dGFiYXNlIGVuZ2luZSB0eXBlIGFuZCB2ZXJzaW9uLiBUaGUgYGRhdGFiYXNlVmVyc2lvbmAK
IGZpZWxkIGNhbm5vdCBiZSBjaGFuZ2VkIGFmdGVyIGluc3RhbmNlIGNyZWF0aW9uLgogICBN
eVNRTCBpbnN0YW5jZXM6IGBNWVNRTF84XzBgLCBgTVlTUUxfNV83YCAoZGVmYXVsdCksCiBv
ciBgTVlTUUxfNV82YC4KICAgUG9zdGdyZVNRTCBpbnN0YW5jZXM6IGBQT1NUR1JFU185XzZg
LCBgUE9TVEdSRVNfMTBgLAogYFBPU1RHUkVTXzExYCBvciBgUE9TVEdSRVNfMTJgIChkZWZh
dWx0KSwgYFBPU1RHUkVTXzEzYCwgb3IgYFBPU1RHUkVTXzE0YC4KICAgU1FMIFNlcnZlciBp
bnN0YW5jZXM6IGBTUUxTRVJWRVJfMjAxN19TVEFOREFSRGAgKGRlZmF1bHQpLAogYFNRTFNF
UlZFUl8yMDE3X0VOVEVSUFJJU0VgLCBgU1FMU0VSVkVSXzIwMTdfRVhQUkVTU2AsCiBgU1FM
U0VSVkVSXzIwMTdfV0VCYCwgYFNRTFNFUlZFUl8yMDE5X1NUQU5EQVJEYCwKIGBTUUxTRVJW
RVJfMjAxOV9FTlRFUlBSSVNFYCwgYFNRTFNFUlZFUl8yMDE5X0VYUFJFU1NgLCBvcgogYFNR
TFNFUlZFUl8yMDE5X1dFQmAuCgoNCgUEAgIEBhIEogECFAoNCgUEAgIEARIEogEVJQoNCgUE
AgIEAxIEogEoKgroAQoEBAICBRIEqAECIxrZASBgU0VDT05EX0dFTmA6IENsb3VkIFNRTCBk
YXRhYmFzZSBpbnN0YW5jZS4KIGBFWFRFUk5BTGA6IEEgZGF0YWJhc2Ugc2VydmVyIHRoYXQg
aXMgbm90IG1hbmFnZWQgYnkgR29vZ2xlLgogVGhpcyBwcm9wZXJ0eSBpcyByZWFkLW9ubHk7
IHVzZSB0aGUgYHRpZXJgIHByb3BlcnR5IGluIHRoZSBgc2V0dGluZ3NgCiBvYmplY3QgdG8g
ZGV0ZXJtaW5lIHRoZSBkYXRhYmFzZSB0eXBlLgoKDQoFBAICBQYSBKgBAhAKDQoFBAICBQES
BKgBER0KDQoFBAICBQMSBKgBICIKRgoEBAICBhIEqwECGBo4IFdoZXRoZXIgUFNDIGNvbm5l
Y3Rpdml0eSBpcyBlbmFibGVkIGZvciB0aGlzIGluc3RhbmNlLgoKDQoFBAICBgUSBKsBAgYK
DQoFBAICBgESBKsBBxIKDQoFBAICBgMSBKsBFRcKLQoEBAICBxIErgECFxofIFRoZSBkbnMg
bmFtZSBvZiB0aGUgaW5zdGFuY2UuCgoNCgUEAgIHBRIErgECCAoNCgUEAgIHARIErgEJEQoN
CgUEAgIHAxIErgEUFgpLCgQEAgIIEgSxAQIdGj0gU3BlY2lmeSB3aGF0IHR5cGUgb2YgQ0Eg
aXMgdXNlZCBmb3IgdGhlIHNlcnZlciBjZXJ0aWZpY2F0ZS4KCg0KBQQCAggGEgSxAQIICg0K
BQQCAggBEgSxAQkXCg0KBQQCAggDEgSxARocCkwKBAQCAgkSBLQBAjgaPiBDdXN0b20gc3Vi
amVjdCBhbHRlcm5hdGl2ZSBuYW1lcyBmb3IgdGhlIHNlcnZlciBjZXJ0aWZpY2F0ZS4KCg0K
BQQCAgkEEgS0AQIKCg0KBQQCAgkFEgS0AQsRCg0KBQQCAgkBEgS0ARIyCg0KBQQCAgkDEgS0
ATU3CksKBAQCAgoSBrcBArgBMho7IE91dHB1dCBvbmx5LiBUaGUgbGlzdCBvZiBETlMgbmFt
ZXMgdXNlZCBieSB0aGlzIGluc3RhbmNlLgoKDQoFBAICCgQSBLcBAgoKDQoFBAICCgYSBLcB
CxkKDQoFBAICCgESBLcBGiMKDQoFBAICCgMSBLcBJigKDQoFBAICCggSBLgBBjEKEAoIBAIC
CgicCAASBLgBBzAKPQoEBAICCxIEuwECIRovIFRoZSBudW1iZXIgb2YgcmVhZCBwb29sIG5v
ZGVzIGluIGEgcmVhZCBwb29sLgoKDQoFBAICCwQSBLsBAgoKDQoFBAICCwUSBLsBCxAKDQoF
BAICCwESBLsBERsKDQoFBAICCwMSBLsBHiAKagoEBAICDBIGvwECwAEyGlogT3V0cHV0IG9u
bHkuIEVudHJpZXMgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBlYWNoIHJlYWQgcG9v
bCBub2RlIG9mCiB0aGUgcmVhZCBwb29sLgoKDQoFBAICDAQSBL8BAgoKDQoFBAICDAYSBL8B
CyAKDQoFBAICDAESBL8BISYKDQoFBAICDAMSBL8BKSsKDQoFBAICDAgSBMABBjEKEAoIBAIC
DAicCAASBMABBzAK8gIKBAQCAg0SBscBAsoBBBrhAiBPcHRpb25hbC4gT3V0cHV0IG9ubHku
IG1keF9wcm90b2NvbF9zdXBwb3J0IGNvbnRyb2xzIGhvdyB0aGUgY2xpZW50IHVzZXMKIG1l
dGFkYXRhIGV4Y2hhbmdlIHdoZW4gY29ubmVjdGluZyB0byB0aGUgaW5zdGFuY2UuIFRoZSB2
YWx1ZXMgaW4gdGhlIGxpc3QKIHJlcHJlc2VudGluZyBwYXJ0cyBvZiB0aGUgTURYIHByb3Rv
Y29sIHRoYXQgYXJlIHN1cHBvcnRlZCBieSB0aGlzIGluc3RhbmNlLgogV2hlbiB0aGUgbGlz
dCBpcyBlbXB0eSwgdGhlIGluc3RhbmNlIGRvZXMgbm90IHN1cHBvcnQgTURYLCBzbyB0aGUg
Y2xpZW50CiBtdXN0IG5vdCBzZW5kIGFuIE1EWCByZXF1ZXN0LiBUaGUgZGVmYXVsdCBpcyBl
bXB0eS4KCg0KBQQCAg0EEgTHAQIKCg0KBQQCAg0GEgTHAQsdCg0KBQQCAg0BEgTHAR4yCg0K
BQQCAg0DEgTHATU3Cg8KBQQCAg0IEgbHATjKAQMKEAoIBAICDQicCAASBMgBBC0KEAoIBAIC
DQicCAESBMkBBCoKlwEKBAQCAg4SBs4BAtEBBBqGASBPcHRpb25hbC4gT3V0cHV0IG9ubHku
IENvbm5lY3Rpb24gbmFtZSBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlIHVzZWQgaW4KIGNv
bm5lY3Rpb24gc3RyaW5ncywgaW4gdGhlIGZvcm1hdCBwcm9qZWN0OnJlZ2lvbjppbnN0YW5j
ZS4KCg0KBQQCAg4FEgTOAQIICg0KBQQCAg4BEgTOAQkYCg0KBQQCAg4DEgTOARsdCg8KBQQC
Ag4IEgbOAR7RAQMKEAoIBAICDgicCAASBM8BBC0KEAoIBAICDgicCAESBNABBCoKNwoCBAMS
BtUBAOsBARopIEVwaGVtZXJhbCBjZXJ0aWZpY2F0ZSBjcmVhdGlvbiByZXF1ZXN0LgoKCwoD
BAMBEgTVAQgkCkwKBAQDAgASBNcBAhYaPiBDbG91ZCBTUUwgaW5zdGFuY2UgSUQuIFRoaXMg
ZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCg0KBQQDAgAFEgTXAQIICg0KBQQD
AgABEgTXAQkRCg0KBQQDAgADEgTXARQVCkUKBAQDAgESBNoBAhUaNyBQcm9qZWN0IElEIG9m
IHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDQoFBAMCAQUSBNoB
AggKDQoFBAMCAQESBNoBCRAKDQoFBAMCAQMSBNoBExQKTAoEBAMCAhIE3QECMxo+IFBFTSBl
bmNvZGVkIHB1YmxpYyBrZXkgdG8gaW5jbHVkZSBpbiB0aGUgc2lnbmVkIGNlcnRpZmljYXRl
LgoKDQoFBAMCAgUSBN0BAggKDQoFBAMCAgESBN0BCRMKDQoFBAMCAgMSBN0BFhcKDQoFBAMC
AggSBN0BGDIKDQoFBAMCAgoSBN0BGTEKDQoFBAMCAgoSBN0BJTEKTgoEBAMCAxIG4AEC4QFL
Gj4gT3B0aW9uYWwuIEFjY2VzcyB0b2tlbiB0byBpbmNsdWRlIGluIHRoZSBzaWduZWQgY2Vy
dGlmaWNhdGUuCgoNCgUEAwIDBRIE4AECCAoNCgUEAwIDARIE4AEJFQoNCgUEAwIDAxIE4AEY
GQoNCgUEAwIDCBIE4QEGSgoNCgUEAwIDChIE4QEHIQoNCgUEAwIDChIE4QETIQoQCggEAwID
CJwIABIE4QEjSQphCgQEAwIEEgblAQLmAS8aUSBPcHRpb25hbC4gT3B0aW9uYWwgc25hcHNo
b3QgcmVhZCB0aW1lc3RhbXAgdG8gdHJhZGUgZnJlc2huZXNzIGZvcgogcGVyZm9ybWFuY2Uu
CgoNCgUEAwIEBhIE5QECGwoNCgUEAwIEARIE5QEcJQoNCgUEAwIEAxIE5QEoKQoNCgUEAwIE
CBIE5gEGLgoQCggEAwIECJwIABIE5gEHLQpMCgQEAwIFEgbpAQLqAS8aPCBPcHRpb25hbC4g
SWYgc2V0LCBpdCB3aWxsIGNvbnRhaW4gdGhlIGNlcnQgdmFsaWQgZHVyYXRpb24uCgoNCgUE
AwIFBhIE6QECGgoNCgUEAwIFARIE6QEbKQoNCgUEAwIFAxIE6QEsLgoNCgUEAwIFCBIE6gEG
LgoQCggEAwIFCJwIABIE6gEHLQo3CgIEBBIG7gEA8QEBGikgRXBoZW1lcmFsIGNlcnRpZmlj
YXRlIGNyZWF0aW9uIHJlcXVlc3QuCgoLCgMEBAESBO4BCCUKHgoEBAQCABIE8AECHRoQIEdl
bmVyYXRlZCBjZXJ0CgoNCgUEBAIABhIE8AECCQoNCgUEBAIAARIE8AEKGAoNCgUEBAIAAxIE
8AEbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest ===
    # Fields for GetConnectSettingsRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlConnect::ResolveConnectSettingsRequest ===
    # Fields for ResolveConnectSettingsRequest
    # Field: dns_name Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings ===
    # Fields for ConnectSettings
    # Field: kind Type: 9 ()
    # Field: server_ca_cert Type: 11 (.google.cloud.sql.v1beta4.SslCert)
    # Field: ip_addresses Type: 11 (.google.cloud.sql.v1beta4.IpMapping)
    # Field: region Type: 9 ()
    # Field: database_version Type: 14 (.google.cloud.sql.v1beta4.SqlDatabaseVersion)
    # Field: backend_type Type: 14 (.google.cloud.sql.v1beta4.SqlBackendType)
    # Field: psc_enabled Type: 8 ()
    # Field: dns_name Type: 9 ()
    # Field: server_ca_mode Type: 14 (.google.cloud.sql.v1beta4.ConnectSettings.CaMode)
    # Field: custom_subject_alternative_names Type: 9 ()
    # Field: dns_names Type: 11 (.google.cloud.sql.v1beta4.DnsNameMapping)
    # Field: node_count Type: 5 ()
    # Field: nodes Type: 11 (.google.cloud.sql.v1beta4.ConnectSettings.ConnectPoolNodeConfig)
    # Field: mdx_protocol_support Type: 14 (.google.cloud.sql.v1beta4.ConnectSettings.MdxProtocolSupport)
    # Field: connection_name Type: 9 ()

# Enum: ConnectSettings::CaMode
our $ConnectSettings_CA_MODE_UNSPECIFIED = 0;
our $ConnectSettings_GOOGLE_MANAGED_INTERNAL_CA = 1;
our $ConnectSettings_GOOGLE_MANAGED_CAS_CA = 2;
our $ConnectSettings_CUSTOMER_MANAGED_CAS_CA = 3;

# Enum: ConnectSettings::MdxProtocolSupport
our $ConnectSettings_MDX_PROTOCOL_SUPPORT_UNSPECIFIED = 0;
our $ConnectSettings_CLIENT_PROTOCOL_TYPE = 1;

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertRequest ===
    # Fields for GenerateEphemeralCertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: public_key Type: 9 ()
    # Field: access_token Type: 9 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)
    # Field: valid_duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertResponse ===
    # Fields for GenerateEphemeralCertResponse
    # Field: ephemeral_cert Type: 11 (.google.cloud.sql.v1beta4.SslCert)

# === Service Client: Google::Cloud::Sql::V1beta4::CloudSqlConnect::SqlConnectServiceClient ===
package Google::Cloud::Sql::V1beta4::CloudSqlConnect::SqlConnectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1beta4::CloudSqlConnect::SqlConnectServiceClient

Client stub representing the remote C<SqlConnectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

sub get_connect_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlConnectService',
        method         => 'GetConnectSettings',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings',
    });
}

sub resolve_connect_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlConnect::ResolveConnectSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlConnectService',
        method         => 'ResolveConnectSettings',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings',
    });
}

sub generate_ephemeral_cert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlConnectService',
        method         => 'GenerateEphemeralCert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlConnect - Compiled Protocol Buffers messages for google/cloud/sql/v1beta4/cloud_sql_connect.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4::CloudSqlConnect;

    my $msg = Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest->new({
        instance => $instance,
        project => $project,
        read_time => $read_time,
    });

    # Read or update a field
    my $val = $msg->instance();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1beta4/cloud_sql_connect.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest

Connect settings retrieval request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Optional snapshot read timestamp to trade freshness for
performance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlConnect::ResolveConnectSettingsRequest

Connect settings retrieval request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dns_name() >> / C<< $msg->dns_name($value) >>

Type: C<String>

Required. Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. The region of the instance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings

Connect settings retrieval response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#connectSettings`.

=item * C<< $msg->server_ca_cert() >> / C<< $msg->server_ca_cert($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert>)

SSL configuration.

=item * C<< $msg->ip_addresses() >> / C<< $msg->ip_addresses($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::IpMapping>)

The assigned IP addresses for the instance.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

The cloud region for the instance. e.g. `us-central1`, `europe-west1`.
The region cannot be changed after instance creation.

=item * C<< $msg->database_version() >> / C<< $msg->database_version($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::SqlDatabaseVersion>)

The database engine type and version. The `databaseVersion`
field cannot be changed after instance creation.
  MySQL instances: `MYSQL_8_0`, `MYSQL_5_7` (default),
or `MYSQL_5_6`.
  PostgreSQL instances: `POSTGRES_9_6`, `POSTGRES_10`,
`POSTGRES_11` or `POSTGRES_12` (default), `POSTGRES_13`, or `POSTGRES_14`.
  SQL Server instances: `SQLSERVER_2017_STANDARD` (default),
`SQLSERVER_2017_ENTERPRISE`, `SQLSERVER_2017_EXPRESS`,
`SQLSERVER_2017_WEB`, `SQLSERVER_2019_STANDARD`,
`SQLSERVER_2019_ENTERPRISE`, `SQLSERVER_2019_EXPRESS`, or
`SQLSERVER_2019_WEB`.

=item * C<< $msg->backend_type() >> / C<< $msg->backend_type($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::SqlBackendType>)

`SECOND_GEN`: Cloud SQL database instance.
`EXTERNAL`: A database server that is not managed by Google.
This property is read-only; use the `tier` property in the `settings`
object to determine the database type.

=item * C<< $msg->psc_enabled() >> / C<< $msg->psc_enabled($value) >>

Type: C<Bool>

Whether PSC connectivity is enabled for this instance.

=item * C<< $msg->dns_name() >> / C<< $msg->dns_name($value) >>

Type: C<String>

The dns name of the instance.

=item * C<< $msg->server_ca_mode() >> / C<< $msg->server_ca_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::ConnectSettings::CaMode>)

Specify what type of CA is used for the server certificate.

=item * C<< $msg->custom_subject_alternative_names() >> / C<< $msg->custom_subject_alternative_names($value) >>

Type: C<String>

Custom subject alternative names for the server certificate.

=item * C<< $msg->dns_names() >> / C<< $msg->dns_names($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::DnsNameMapping>)

Output only. The list of DNS names used by this instance.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Int32>

The number of read pool nodes in a read pool.

=item * C<< $msg->nodes() >> / C<< $msg->nodes($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings::ConnectPoolNodeConfig>)

Output only. Entries containing information about each read pool node of
the read pool.

=item * C<< $msg->mdx_protocol_support() >> / C<< $msg->mdx_protocol_support($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::ConnectSettings::MdxProtocolSupport>)

Optional. Output only. mdx_protocol_support controls how the client uses
metadata exchange when connecting to the instance. The values in the list
representing parts of the MDX protocol that are supported by this instance.
When the list is empty, the instance does not support MDX, so the client
must not send an MDX request. The default is empty.

=item * C<< $msg->connection_name() >> / C<< $msg->connection_name($value) >>

Type: C<String>

Optional. Output only. Connection name of the Cloud SQL instance used in
connection strings, in the format project:region:instance.

=back

=head3 Enum: ConnectSettings::CaMode

=over 4

=item * C<CA_MODE_UNSPECIFIED> => C<0>

=item * C<GOOGLE_MANAGED_INTERNAL_CA> => C<1>

=item * C<GOOGLE_MANAGED_CAS_CA> => C<2>

=item * C<CUSTOMER_MANAGED_CAS_CA> => C<3>

=back

=head3 Enum: ConnectSettings::MdxProtocolSupport

=over 4

=item * C<MDX_PROTOCOL_SUPPORT_UNSPECIFIED> => C<0>

=item * C<CLIENT_PROTOCOL_TYPE> => C<1>

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertRequest

Ephemeral certificate creation request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Cloud SQL instance ID. This does not include the project ID.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->public_key() >> / C<< $msg->public_key($value) >>

Type: C<String>

PEM encoded public key to include in the signed certificate.

=item * C<< $msg->access_token() >> / C<< $msg->access_token($value) >>

Type: C<String>

Optional. Access token to include in the signed certificate.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Optional snapshot read timestamp to trade freshness for
performance.

=item * C<< $msg->valid_duration() >> / C<< $msg->valid_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. If set, it will contain the cert valid duration.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertResponse

Ephemeral certificate creation request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ephemeral_cert() >> / C<< $msg->ephemeral_cert($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert>)

Generated cert

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
