package Google::Appengine::V1::Instance;

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
CiJnb29nbGUvYXBwZW5naW5lL3YxL2luc3RhbmNlLnByb3RvEhNnb29nbGUuYXBwZW5naW5l
LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIv0HCghJbnN0YW5j
ZRIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSEwoCaWQYAiABKAlCA+BBA1ICaWQSMQoSYXBw
X2VuZ2luZV9yZWxlYXNlGAMgASgJQgPgQQNSEGFwcEVuZ2luZVJlbGVhc2USUwoMYXZhaWxh
YmlsaXR5GAQgASgOMiouZ29vZ2xlLmFwcGVuZ2luZS52MS5JbnN0YW5jZS5BdmFpbGFiaWxp
dHlCA+BBA1IMYXZhaWxhYmlsaXR5EhwKB3ZtX25hbWUYBSABKAlCA+BBA1IGdm1OYW1lEiUK
DHZtX3pvbmVfbmFtZRgGIAEoCUID4EEDUgp2bVpvbmVOYW1lEhgKBXZtX2lkGAcgASgJQgPg
QQNSBHZtSWQSPgoKc3RhcnRfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IJc3RhcnRUaW1lEh8KCHJlcXVlc3RzGAkgASgFQgPgQQNSCHJlcXVlc3RzEhsK
BmVycm9ycxgKIAEoBUID4EEDUgZlcnJvcnMSFQoDcXBzGAsgASgCQgPgQQNSA3FwcxIsCg9h
dmVyYWdlX2xhdGVuY3kYDCABKAVCA+BBA1IOYXZlcmFnZUxhdGVuY3kSJgoMbWVtb3J5X3Vz
YWdlGA0gASgDQgPgQQNSC21lbW9yeVVzYWdlEiAKCXZtX3N0YXR1cxgOIAEoCUID4EEDUgh2
bVN0YXR1cxItChB2bV9kZWJ1Z19lbmFibGVkGA8gASgIQgPgQQNSDnZtRGVidWdFbmFibGVk
EhgKBXZtX2lwGBAgASgJQgPgQQNSBHZtSXASWgoLdm1fbGl2ZW5lc3MYESABKA4yNC5nb29n
bGUuYXBwZW5naW5lLnYxLkluc3RhbmNlLkxpdmVuZXNzLkxpdmVuZXNzU3RhdGVCA+BBA1IK
dm1MaXZlbmVzcxp/CghMaXZlbmVzcyJzCg1MaXZlbmVzc1N0YXRlEh4KGkxJVkVORVNTX1NU
QVRFX1VOU1BFQ0lGSUVEEAASCwoHVU5LTk9XThABEgsKB0hFQUxUSFkQAhINCglVTkhFQUxU
SFkQAxIMCghEUkFJTklORxAEEgsKB1RJTUVPVVQQBSI6CgxBdmFpbGFiaWxpdHkSDwoLVU5T
UEVDSUZJRUQQABIMCghSRVNJREVOVBABEgsKB0RZTkFNSUMQAjpt6kFqCiFhcHBlbmdpbmUu
Z29vZ2xlYXBpcy5jb20vSW5zdGFuY2USRWFwcHMve2FwcH0vc2VydmljZXMve3NlcnZpY2V9
L3ZlcnNpb25zL3t2ZXJzaW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfUK+AQoXY29tLmdvb2ds
ZS5hcHBlbmdpbmUudjFCDUluc3RhbmNlUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9h
cHBlbmdpbmUvYXBpdjEvYXBwZW5naW5lcGI7YXBwZW5naW5lcGKqAhlHb29nbGUuQ2xvdWQu
QXBwRW5naW5lLlYxygIZR29vZ2xlXENsb3VkXEFwcEVuZ2luZVxWMeoCHEdvb2dsZTo6Q2xv
dWQ6OkFwcEVuZ2luZTo6VjFKjysKBxIFDgCOAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkK
CAoBCBIDFgA2CgkKAgglEgMWADYKCAoBCBIDFwBSCgkKAggLEgMXAFIKCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAuCgkKAggIEgMZAC4KCAoBCBIDGgAwCgkKAggBEgMaADAKCAoB
CBIDGwA2CgkKAggpEgMbADYKCAoBCBIDHAA1CgkKAggtEgMcADUKdgoCBAASBSAAjgEBGmkg
QW4gSW5zdGFuY2UgcmVzb3VyY2UgaXMgdGhlIGNvbXB1dGluZyB1bml0IHRoYXQgQXBwIEVu
Z2luZSB1c2VzIHRvCiBhdXRvbWF0aWNhbGx5IHNjYWxlIGFuIGFwcGxpY2F0aW9uLgoKCgoD
BAABEgMgCBAKCwoDBAAHEgQhAiQECg0KBQQAB50IEgQhAiQECi0KBAQABAASBCcCLQMaHyBB
dmFpbGFiaWxpdHkgb2YgdGhlIGluc3RhbmNlLgoKDAoFBAAEAAESAycHEwoNCgYEAAQAAgAS
AygEFAoOCgcEAAQAAgABEgMoBA8KDgoHBAAEAAIAAhIDKBITCg0KBgQABAACARIDKgQRCg4K
BwQABAACAQESAyoEDAoOCgcEAAQAAgECEgMqDxAKDQoGBAAEAAICEgMsBBAKDgoHBAAEAAIC
ARIDLAQLCg4KBwQABAACAgISAywODwovCgQEAAMAEgQwAk8DGiEgV3JhcHBlciBmb3IgTGl2
ZW5lc3NTdGF0ZSBlbnVtLgoKDAoFBAADAAESAzAKEgpCCgYEAAMABAASBDIETAUaMiBMaXZl
bmVzcyBoZWFsdGggY2hlY2sgc3RhdHVzIGZvciBGbGV4IGluc3RhbmNlcy4KCg4KBwQAAwAE
AAESAzIJFgqJAQoIBAADAAQAAgASAzUGJRp4IFRoZXJlIGlzIG5vIGxpdmVuZXNzIGhlYWx0
aCBjaGVjayBmb3IgdGhlIGluc3RhbmNlLiBPbmx5IGFwcGxpY2FibGUgZm9yCiBpbnN0YW5j
ZXMgaW4gQXBwIEVuZ2luZSBzdGFuZGFyZCBlbnZpcm9ubWVudC4KChAKCQQAAwAEAAIAARID
NQYgChAKCQQAAwAEAAIAAhIDNSMkCnIKCAQAAwAEAAIBEgM5BhIaYSBUaGUgaGVhbHRoIGNo
ZWNraW5nIHN5c3RlbSBpcyBhd2FyZSBvZiB0aGUgaW5zdGFuY2UgYnV0IGl0cyBoZWFsdGgg
aXMKIG5vdCBrbm93biBhdCB0aGUgbW9tZW50LgoKEAoJBAADAAQAAgEBEgM5Bg0KEAoJBAAD
AAQAAgECEgM5EBEKvwEKCAQAAwAEAAICEgM+BhIarQEgVGhlIGluc3RhbmNlIGlzIHJlYWNo
YWJsZSBpLmUuIGEgY29ubmVjdGlvbiB0byB0aGUgYXBwbGljYXRpb24gaGVhbHRoCiBjaGVj
a2luZyBlbmRwb2ludCBjYW4gYmUgZXN0YWJsaXNoZWQsIGFuZCBjb25mb3JtcyB0byB0aGUg
cmVxdWlyZW1lbnRzCiBkZWZpbmVkIGJ5IHRoZSBoZWFsdGggY2hlY2suCgoQCgkEAAMABAAC
AgESAz4GDQoQCgkEAAMABAACAgISAz4QEQp0CggEAAMABAACAxIDQgYUGmMgVGhlIGluc3Rh
bmNlIGlzIHJlYWNoYWJsZSwgYnV0IGRvZXMgbm90IGNvbmZvcm0gdG8gdGhlIHJlcXVpcmVt
ZW50cwogZGVmaW5lZCBieSB0aGUgaGVhbHRoIGNoZWNrLgoKEAoJBAADAAQAAgMBEgNCBg8K
EAoJBAADAAQAAgMCEgNCEhMKlwEKCAQAAwAEAAIEEgNGBhMahQEgVGhlIGluc3RhbmNlIGlz
IGJlaW5nIGRyYWluZWQuIFRoZSBleGlzdGluZyBjb25uZWN0aW9ucyB0byB0aGUgaW5zdGFu
Y2UKIGhhdmUgdGltZSB0byBjb21wbGV0ZSwgYnV0IHRoZSBuZXcgb25lcyBhcmUgYmVpbmcg
cmVmdXNlZC4KChAKCQQAAwAEAAIEARIDRgYOChAKCQQAAwAEAAIEAhIDRhESCsMBCggEAAMA
BAACBRIDSwYSGrEBIFRoZSBpbnN0YW5jZSBpcyB1bnJlYWNoYWJsZSBpLmUuIGEgY29ubmVj
dGlvbiB0byB0aGUgYXBwbGljYXRpb24gaGVhbHRoCiBjaGVja2luZyBlbmRwb2ludCBjYW5u
b3QgYmUgZXN0YWJsaXNoZWQsIG9yIHRoZSBzZXJ2ZXIgZG9lcyBub3QgcmVzcG9uZAogd2l0
aGluIHRoZSBzcGVjaWZpZWQgdGltZW91dC4KChAKCQQAAwAEAAIFARIDSwYNChAKCQQAAwAE
AAIFAhIDSxARCpUBCgQEAAIAEgNTAj4ahwEgT3V0cHV0IG9ubHkuIEZ1bGwgcGF0aCB0byB0
aGUgSW5zdGFuY2UgcmVzb3VyY2UgaW4gdGhlIEFQSS4KIEV4YW1wbGU6IGBhcHBzL215YXBw
L3NlcnZpY2VzL2RlZmF1bHQvdmVyc2lvbnMvdjEvaW5zdGFuY2VzL2luc3RhbmNlLTFgLgoK
DAoFBAACAAUSA1MCCAoMCgUEAAIAARIDUwkNCgwKBQQAAgADEgNTEBEKDAoFBAACAAgSA1MS
PQoPCggEAAIACJwIABIDUxM8CmUKBAQAAgESA1cCPBpYIE91dHB1dCBvbmx5LiBSZWxhdGl2
ZSBuYW1lIG9mIHRoZSBpbnN0YW5jZSB3aXRoaW4gdGhlIHZlcnNpb24uCiBFeGFtcGxlOiBg
aW5zdGFuY2UtMWAuCgoMCgUEAAIBBRIDVwIICgwKBQQAAgEBEgNXCQsKDAoFBAACAQMSA1cO
DwoMCgUEAAIBCBIDVxA7Cg8KCAQAAgEInAgAEgNXEToKSwoEBAACAhIDWgJMGj4gT3V0cHV0
IG9ubHkuIEFwcCBFbmdpbmUgcmVsZWFzZSB0aGlzIGluc3RhbmNlIGlzIHJ1bm5pbmcgb24u
CgoMCgUEAAICBRIDWgIICgwKBQQAAgIBEgNaCRsKDAoFBAACAgMSA1oeHwoMCgUEAAICCBID
WiBLCg8KCAQAAgIInAgAEgNaIUoKOQoEBAACAxIDXQJMGiwgT3V0cHV0IG9ubHkuIEF2YWls
YWJpbGl0eSBvZiB0aGUgaW5zdGFuY2UuCgoMCgUEAAIDBhIDXQIOCgwKBQQAAgMBEgNdDxsK
DAoFBAACAwMSA10eHwoMCgUEAAIDCBIDXSBLCg8KCAQAAgMInAgAEgNdIUoKlgEKBAQAAgQS
A2ECQRqIASBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgdmlydHVhbCBtYWNoaW5lIHdoZXJl
IHRoaXMgaW5zdGFuY2UgbGl2ZXMuIE9ubHkgYXBwbGljYWJsZQogZm9yIGluc3RhbmNlcyBp
biBBcHAgRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKDAoFBAACBAUSA2ECCAoMCgUE
AAIEARIDYQkQCgwKBQQAAgQDEgNhExQKDAoFBAACBAgSA2EVQAoPCggEAAIECJwIABIDYRY/
CokBCgQEAAIFEgNlAkYafCBPdXRwdXQgb25seS4gWm9uZSB3aGVyZSB0aGUgdmlydHVhbCBt
YWNoaW5lIGlzIGxvY2F0ZWQuIE9ubHkgYXBwbGljYWJsZSBmb3IgaW5zdGFuY2VzCiBpbiBB
cHAgRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKDAoFBAACBQUSA2UCCAoMCgUEAAIF
ARIDZQkVCgwKBQQAAgUDEgNlGBkKDAoFBAACBQgSA2UaRQoPCggEAAIFCJwIABIDZRtECoMB
CgQEAAIGEgNpAj8adiBPdXRwdXQgb25seS4gVmlydHVhbCBtYWNoaW5lIElEIG9mIHRoaXMg
aW5zdGFuY2UuIE9ubHkgYXBwbGljYWJsZSBmb3IgaW5zdGFuY2VzIGluCiBBcHAgRW5naW5l
IGZsZXhpYmxlIGVudmlyb25tZW50LgoKDAoFBAACBgUSA2kCCAoMCgUEAAIGARIDaQkOCgwK
BQQAAgYDEgNpERIKDAoFBAACBggSA2kTPgoPCggEAAIGCJwIABIDaRQ9Ck4KBAQAAgcSA24C
VxpBIE91dHB1dCBvbmx5LiBUaW1lIHRoYXQgdGhpcyBpbnN0YW5jZSB3YXMgc3RhcnRlZC4K
CiBAT3V0cHV0T25seQoKDAoFBAACBwYSA24CGwoMCgUEAAIHARIDbhwmCgwKBQQAAgcDEgNu
KSoKDAoFBAACBwgSA24rVgoPCggEAAIHCJwIABIDbixVCk8KBAQAAggSA3ECQRpCIE91dHB1
dCBvbmx5LiBOdW1iZXIgb2YgcmVxdWVzdHMgc2luY2UgdGhpcyBpbnN0YW5jZSB3YXMgc3Rh
cnRlZC4KCgwKBQQAAggFEgNxAgcKDAoFBAACCAESA3EIEAoMCgUEAAIIAxIDcRMUCgwKBQQA
AggIEgNxFUAKDwoIBAACCAicCAASA3EWPwpNCgQEAAIJEgN0AkAaQCBPdXRwdXQgb25seS4g
TnVtYmVyIG9mIGVycm9ycyBzaW5jZSB0aGlzIGluc3RhbmNlIHdhcyBzdGFydGVkLgoKDAoF
BAACCQUSA3QCBwoMCgUEAAIJARIDdAgOCgwKBQQAAgkDEgN0ERMKDAoFBAACCQgSA3QUPwoP
CggEAAIJCJwIABIDdBU+ClIKBAQAAgoSA3cCPRpFIE91dHB1dCBvbmx5LiBBdmVyYWdlIHF1
ZXJpZXMgcGVyIHNlY29uZCAoUVBTKSBvdmVyIHRoZSBsYXN0IG1pbnV0ZS4KCgwKBQQAAgoF
EgN3AgcKDAoFBAACCgESA3cICwoMCgUEAAIKAxIDdw4QCgwKBQQAAgoIEgN3ETwKDwoIBAAC
CgicCAASA3cSOwpGCgQEAAILEgN6AkkaOSBPdXRwdXQgb25seS4gQXZlcmFnZSBsYXRlbmN5
IChtcykgb3ZlciB0aGUgbGFzdCBtaW51dGUuCgoMCgUEAAILBRIDegIHCgwKBQQAAgsBEgN6
CBcKDAoFBAACCwMSA3oaHAoMCgUEAAILCBIDeh1ICg8KCAQAAgsInAgAEgN6HkcKOAoEBAAC
DBIDfQJGGisgT3V0cHV0IG9ubHkuIFRvdGFsIG1lbW9yeSBpbiB1c2UgKGJ5dGVzKS4KCgwK
BQQAAgwFEgN9AgcKDAoFBAACDAESA30IFAoMCgUEAAIMAxIDfRcZCgwKBQQAAgwIEgN9GkUK
DwoIBAACDAicCAASA30bRAqZAQoEBAACDRIEgQECRBqKASBPdXRwdXQgb25seS4gU3RhdHVz
IG9mIHRoZSB2aXJ0dWFsIG1hY2hpbmUgd2hlcmUgdGhpcyBpbnN0YW5jZSBsaXZlcy4gT25s
eSBhcHBsaWNhYmxlCiBmb3IgaW5zdGFuY2VzIGluIEFwcCBFbmdpbmUgZmxleGlibGUgZW52
aXJvbm1lbnQuCgoNCgUEAAINBRIEgQECCAoNCgUEAAINARIEgQEJEgoNCgUEAAINAxIEgQEV
FwoNCgUEAAINCBIEgQEYQwoQCggEAAINCJwIABIEgQEZQgqHAQoEBAACDhIEhQECSRp5IE91
dHB1dCBvbmx5LiBXaGV0aGVyIHRoaXMgaW5zdGFuY2UgaXMgaW4gZGVidWcgbW9kZS4gT25s
eSBhcHBsaWNhYmxlIGZvciBpbnN0YW5jZXMgaW4KIEFwcCBFbmdpbmUgZmxleGlibGUgZW52
aXJvbm1lbnQuCgoNCgUEAAIOBRIEhQECBgoNCgUEAAIOARIEhQEHFwoNCgUEAAIOAxIEhQEa
HAoNCgUEAAIOCBIEhQEdSAoQCggEAAIOCJwIABIEhQEeRwqAAQoEBAACDxIEiQECQBpyIE91
dHB1dCBvbmx5LiBUaGUgSVAgYWRkcmVzcyBvZiB0aGlzIGluc3RhbmNlLiBPbmx5IGFwcGxp
Y2FibGUgZm9yIGluc3RhbmNlcyBpbiBBcHAKIEVuZ2luZSBmbGV4aWJsZSBlbnZpcm9ubWVu
dC4KCg0KBQQAAg8FEgSJAQIICg0KBQQAAg8BEgSJAQkOCg0KBQQAAg8DEgSJARETCg0KBQQA
Ag8IEgSJARQ/ChAKCAQAAg8InAgAEgSJARU+CosBCgQEAAIQEgSNAQJWGn0gT3V0cHV0IG9u
bHkuIFRoZSBsaXZlbmVzcyBoZWFsdGggY2hlY2sgb2YgdGhpcyBpbnN0YW5jZS4gT25seSBh
cHBsaWNhYmxlIGZvciBpbnN0YW5jZXMKIGluIEFwcCBFbmdpbmUgZmxleGlibGUgZW52aXJv
bm1lbnQuCgoNCgUEAAIQBhIEjQECGAoNCgUEAAIQARIEjQEZJAoNCgUEAAIQAxIEjQEnKQoN
CgUEAAIQCBIEjQEqVQoQCggEAAIQCJwIABIEjQErVGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: app_engine_release Type: 9 ()
    # Field: availability Type: 14 (.google.appengine.v1.Instance.Availability)
    # Field: vm_name Type: 9 ()
    # Field: vm_zone_name Type: 9 ()
    # Field: vm_id Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: requests Type: 5 ()
    # Field: errors Type: 5 ()
    # Field: qps Type: 2 ()
    # Field: average_latency Type: 5 ()
    # Field: memory_usage Type: 3 ()
    # Field: vm_status Type: 9 ()
    # Field: vm_debug_enabled Type: 8 ()
    # Field: vm_ip Type: 9 ()
    # Field: vm_liveness Type: 14 (.google.appengine.v1.Instance.Liveness.LivenessState)

# Enum: Instance::Availability
our $Instance_UNSPECIFIED = 0;
our $Instance_RESIDENT = 1;
our $Instance_DYNAMIC = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Instance - Compiled Protocol Buffers messages for google/appengine/v1/instance.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Instance;

    my $msg = Google::Appengine::V1::Instance::Instance->new({
        name => $name,
        id => $id,
        app_engine_release => $app_engine_release,
        availability => $availability,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Instance::Instance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Instance::Instance

An Instance resource is the computing unit that App Engine uses to
automatically scale an application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Full path to the Instance resource in the API.
Example: `apps/myapp/services/default/versions/v1/instances/instance-1`.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. Relative name of the instance within the version.
Example: `instance-1`.

=item * C<< $msg->app_engine_release() >> / C<< $msg->app_engine_release($value) >>

Type: C<String>

Output only. App Engine release this instance is running on.

=item * C<< $msg->availability() >> / C<< $msg->availability($value) >>

Type: C<Enum> (L<Google::Appengine::V1::Instance::Availability>)

Output only. Availability of the instance.

=item * C<< $msg->vm_name() >> / C<< $msg->vm_name($value) >>

Type: C<String>

Output only. Name of the virtual machine where this instance lives. Only applicable
for instances in App Engine flexible environment.

=item * C<< $msg->vm_zone_name() >> / C<< $msg->vm_zone_name($value) >>

Type: C<String>

Output only. Zone where the virtual machine is located. Only applicable for instances
in App Engine flexible environment.

=item * C<< $msg->vm_id() >> / C<< $msg->vm_id($value) >>

Type: C<String>

Output only. Virtual machine ID of this instance. Only applicable for instances in
App Engine flexible environment.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time that this instance was started.

@OutputOnly

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Int32>

Output only. Number of requests since this instance was started.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Int32>

Output only. Number of errors since this instance was started.

=item * C<< $msg->qps() >> / C<< $msg->qps($value) >>

Type: C<Float>

Output only. Average queries per second (QPS) over the last minute.

=item * C<< $msg->average_latency() >> / C<< $msg->average_latency($value) >>

Type: C<Int32>

Output only. Average latency (ms) over the last minute.

=item * C<< $msg->memory_usage() >> / C<< $msg->memory_usage($value) >>

Type: C<Int64>

Output only. Total memory in use (bytes).

=item * C<< $msg->vm_status() >> / C<< $msg->vm_status($value) >>

Type: C<String>

Output only. Status of the virtual machine where this instance lives. Only applicable
for instances in App Engine flexible environment.

=item * C<< $msg->vm_debug_enabled() >> / C<< $msg->vm_debug_enabled($value) >>

Type: C<Bool>

Output only. Whether this instance is in debug mode. Only applicable for instances in
App Engine flexible environment.

=item * C<< $msg->vm_ip() >> / C<< $msg->vm_ip($value) >>

Type: C<String>

Output only. The IP address of this instance. Only applicable for instances in App
Engine flexible environment.

=item * C<< $msg->vm_liveness() >> / C<< $msg->vm_liveness($value) >>

Type: C<Enum> (L<Google::Appengine::V1::Instance::Liveness::LivenessState>)

Output only. The liveness health check of this instance. Only applicable for instances
in App Engine flexible environment.

=back

=head3 Enum: Instance::Availability

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<RESIDENT> => C<1>

=item * C<DYNAMIC> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
