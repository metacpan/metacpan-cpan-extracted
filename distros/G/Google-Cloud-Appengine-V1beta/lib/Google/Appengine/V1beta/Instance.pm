package Google::Appengine::V1beta::Instance;

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
CiZnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9pbnN0YW5jZS5wcm90bxIXZ29vZ2xlLmFwcGVu
Z2luZS52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ihQgK
CEluc3RhbmNlEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRITCgJpZBgCIAEoCUID4EEDUgJp
ZBIxChJhcHBfZW5naW5lX3JlbGVhc2UYAyABKAlCA+BBA1IQYXBwRW5naW5lUmVsZWFzZRJX
CgxhdmFpbGFiaWxpdHkYBCABKA4yLi5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5JbnN0YW5j
ZS5BdmFpbGFiaWxpdHlCA+BBA1IMYXZhaWxhYmlsaXR5EhwKB3ZtX25hbWUYBSABKAlCA+BB
A1IGdm1OYW1lEiUKDHZtX3pvbmVfbmFtZRgGIAEoCUID4EEDUgp2bVpvbmVOYW1lEhgKBXZt
X2lkGAcgASgJQgPgQQNSBHZtSWQSPgoKc3RhcnRfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEh8KCHJlcXVlc3RzGAkgASgFQgPgQQNS
CHJlcXVlc3RzEhsKBmVycm9ycxgKIAEoBUID4EEDUgZlcnJvcnMSFQoDcXBzGAsgASgCQgPg
QQNSA3FwcxIsCg9hdmVyYWdlX2xhdGVuY3kYDCABKAVCA+BBA1IOYXZlcmFnZUxhdGVuY3kS
JgoMbWVtb3J5X3VzYWdlGA0gASgDQgPgQQNSC21lbW9yeVVzYWdlEiAKCXZtX3N0YXR1cxgO
IAEoCUID4EEDUgh2bVN0YXR1cxItChB2bV9kZWJ1Z19lbmFibGVkGA8gASgIQgPgQQNSDnZt
RGVidWdFbmFibGVkEhgKBXZtX2lwGBAgASgJQgPgQQNSBHZtSXASXgoLdm1fbGl2ZW5lc3MY
ESABKA4yOC5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5JbnN0YW5jZS5MaXZlbmVzcy5MaXZl
bmVzc1N0YXRlQgPgQQNSCnZtTGl2ZW5lc3MafwoITGl2ZW5lc3MicwoNTGl2ZW5lc3NTdGF0
ZRIeChpMSVZFTkVTU19TVEFURV9VTlNQRUNJRklFRBAAEgsKB1VOS05PV04QARILCgdIRUFM
VEhZEAISDQoJVU5IRUFMVEhZEAMSDAoIRFJBSU5JTkcQBBILCgdUSU1FT1VUEAUiOgoMQXZh
aWxhYmlsaXR5Eg8KC1VOU1BFQ0lGSUVEEAASDAoIUkVTSURFTlQQARILCgdEWU5BTUlDEAI6
bepBagohYXBwZW5naW5lLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlEkVhcHBzL3thcHB9L3Nl
cnZpY2VzL3tzZXJ2aWNlfS92ZXJzaW9ucy97dmVyc2lvbn0vaW5zdGFuY2VzL3tpbnN0YW5j
ZX1C0wEKG2NvbS5nb29nbGUuYXBwZW5naW5lLnYxYmV0YUINSW5zdGFuY2VQcm90b1ABWkBn
b29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FwcGVuZ2luZS92MWJldGE7
YXBwZW5naW5lqgIdR29vZ2xlLkNsb3VkLkFwcEVuZ2luZS5WMUJldGHKAh1Hb29nbGVcQ2xv
dWRcQXBwRW5naW5lXFYxYmV0YeoCIEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFiZXRh
So8rCgcSBQ4AjgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAOgoJCgIIJRID
FgA6CggKAQgSAxcAVwoJCgIICxIDFwBXCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkA
LgoJCgIICBIDGQAuCggKAQgSAxoANAoJCgIIARIDGgA0CggKAQgSAxsAOgoJCgIIKRIDGwA6
CggKAQgSAxwAOQoJCgIILRIDHAA5CnYKAgQAEgUgAI4BARppIEFuIEluc3RhbmNlIHJlc291
cmNlIGlzIHRoZSBjb21wdXRpbmcgdW5pdCB0aGF0IEFwcCBFbmdpbmUgdXNlcyB0bwogYXV0
b21hdGljYWxseSBzY2FsZSBhbiBhcHBsaWNhdGlvbi4KCgoKAwQAARIDIAgQCgsKAwQABxIE
IQIkBAoNCgUEAAedCBIEIQIkBAovCgQEAAMAEgQnAkYDGiEgV3JhcHBlciBmb3IgTGl2ZW5l
c3NTdGF0ZSBlbnVtLgoKDAoFBAADAAESAycKEgpCCgYEAAMABAASBCkEQwUaMiBMaXZlbmVz
cyBoZWFsdGggY2hlY2sgc3RhdHVzIGZvciBGbGV4IGluc3RhbmNlcy4KCg4KBwQAAwAEAAES
AykJFgqJAQoIBAADAAQAAgASAywGJRp4IFRoZXJlIGlzIG5vIGxpdmVuZXNzIGhlYWx0aCBj
aGVjayBmb3IgdGhlIGluc3RhbmNlLiBPbmx5IGFwcGxpY2FibGUgZm9yCiBpbnN0YW5jZXMg
aW4gQXBwIEVuZ2luZSBzdGFuZGFyZCBlbnZpcm9ubWVudC4KChAKCQQAAwAEAAIAARIDLAYg
ChAKCQQAAwAEAAIAAhIDLCMkCnIKCAQAAwAEAAIBEgMwBhIaYSBUaGUgaGVhbHRoIGNoZWNr
aW5nIHN5c3RlbSBpcyBhd2FyZSBvZiB0aGUgaW5zdGFuY2UgYnV0IGl0cyBoZWFsdGggaXMK
IG5vdCBrbm93biBhdCB0aGUgbW9tZW50LgoKEAoJBAADAAQAAgEBEgMwBg0KEAoJBAADAAQA
AgECEgMwEBEKvwEKCAQAAwAEAAICEgM1BhIarQEgVGhlIGluc3RhbmNlIGlzIHJlYWNoYWJs
ZSBpLmUuIGEgY29ubmVjdGlvbiB0byB0aGUgYXBwbGljYXRpb24gaGVhbHRoCiBjaGVja2lu
ZyBlbmRwb2ludCBjYW4gYmUgZXN0YWJsaXNoZWQsIGFuZCBjb25mb3JtcyB0byB0aGUgcmVx
dWlyZW1lbnRzCiBkZWZpbmVkIGJ5IHRoZSBoZWFsdGggY2hlY2suCgoQCgkEAAMABAACAgES
AzUGDQoQCgkEAAMABAACAgISAzUQEQp0CggEAAMABAACAxIDOQYUGmMgVGhlIGluc3RhbmNl
IGlzIHJlYWNoYWJsZSwgYnV0IGRvZXMgbm90IGNvbmZvcm0gdG8gdGhlIHJlcXVpcmVtZW50
cwogZGVmaW5lZCBieSB0aGUgaGVhbHRoIGNoZWNrLgoKEAoJBAADAAQAAgMBEgM5Bg8KEAoJ
BAADAAQAAgMCEgM5EhMKlwEKCAQAAwAEAAIEEgM9BhMahQEgVGhlIGluc3RhbmNlIGlzIGJl
aW5nIGRyYWluZWQuIFRoZSBleGlzdGluZyBjb25uZWN0aW9ucyB0byB0aGUgaW5zdGFuY2UK
IGhhdmUgdGltZSB0byBjb21wbGV0ZSwgYnV0IHRoZSBuZXcgb25lcyBhcmUgYmVpbmcgcmVm
dXNlZC4KChAKCQQAAwAEAAIEARIDPQYOChAKCQQAAwAEAAIEAhIDPRESCsMBCggEAAMABAAC
BRIDQgYSGrEBIFRoZSBpbnN0YW5jZSBpcyB1bnJlYWNoYWJsZSBpLmUuIGEgY29ubmVjdGlv
biB0byB0aGUgYXBwbGljYXRpb24gaGVhbHRoCiBjaGVja2luZyBlbmRwb2ludCBjYW5ub3Qg
YmUgZXN0YWJsaXNoZWQsIG9yIHRoZSBzZXJ2ZXIgZG9lcyBub3QgcmVzcG9uZAogd2l0aGlu
IHRoZSBzcGVjaWZpZWQgdGltZW91dC4KChAKCQQAAwAEAAIFARIDQgYNChAKCQQAAwAEAAIF
AhIDQhARCi0KBAQABAASBEkCTwMaHyBBdmFpbGFiaWxpdHkgb2YgdGhlIGluc3RhbmNlLgoK
DAoFBAAEAAESA0kHEwoNCgYEAAQAAgASA0oEFAoOCgcEAAQAAgABEgNKBA8KDgoHBAAEAAIA
AhIDShITCg0KBgQABAACARIDTAQRCg4KBwQABAACAQESA0wEDAoOCgcEAAQAAgECEgNMDxAK
DQoGBAAEAAICEgNOBBAKDgoHBAAEAAICARIDTgQLCg4KBwQABAACAgISA04ODwqVAQoEBAAC
ABIDUwI+GocBIE91dHB1dCBvbmx5LiBGdWxsIHBhdGggdG8gdGhlIEluc3RhbmNlIHJlc291
cmNlIGluIHRoZSBBUEkuCiBFeGFtcGxlOiBgYXBwcy9teWFwcC9zZXJ2aWNlcy9kZWZhdWx0
L3ZlcnNpb25zL3YxL2luc3RhbmNlcy9pbnN0YW5jZS0xYC4KCgwKBQQAAgAFEgNTAggKDAoF
BAACAAESA1MJDQoMCgUEAAIAAxIDUxARCgwKBQQAAgAIEgNTEj0KDwoIBAACAAicCAASA1MT
PAplCgQEAAIBEgNXAjwaWCBPdXRwdXQgb25seS4gUmVsYXRpdmUgbmFtZSBvZiB0aGUgaW5z
dGFuY2Ugd2l0aGluIHRoZSB2ZXJzaW9uLgogRXhhbXBsZTogYGluc3RhbmNlLTFgLgoKDAoF
BAACAQUSA1cCCAoMCgUEAAIBARIDVwkLCgwKBQQAAgEDEgNXDg8KDAoFBAACAQgSA1cQOwoP
CggEAAIBCJwIABIDVxE6CksKBAQAAgISA1oCTBo+IE91dHB1dCBvbmx5LiBBcHAgRW5naW5l
IHJlbGVhc2UgdGhpcyBpbnN0YW5jZSBpcyBydW5uaW5nIG9uLgoKDAoFBAACAgUSA1oCCAoM
CgUEAAICARIDWgkbCgwKBQQAAgIDEgNaHh8KDAoFBAACAggSA1ogSwoPCggEAAICCJwIABID
WiFKCjkKBAQAAgMSA10CTBosIE91dHB1dCBvbmx5LiBBdmFpbGFiaWxpdHkgb2YgdGhlIGlu
c3RhbmNlLgoKDAoFBAACAwYSA10CDgoMCgUEAAIDARIDXQ8bCgwKBQQAAgMDEgNdHh8KDAoF
BAACAwgSA10gSwoPCggEAAIDCJwIABIDXSFKCpYBCgQEAAIEEgNhAkEaiAEgT3V0cHV0IG9u
bHkuIE5hbWUgb2YgdGhlIHZpcnR1YWwgbWFjaGluZSB3aGVyZSB0aGlzIGluc3RhbmNlIGxp
dmVzLiBPbmx5IGFwcGxpY2FibGUKIGZvciBpbnN0YW5jZXMgaW4gQXBwIEVuZ2luZSBmbGV4
aWJsZSBlbnZpcm9ubWVudC4KCgwKBQQAAgQFEgNhAggKDAoFBAACBAESA2EJEAoMCgUEAAIE
AxIDYRMUCgwKBQQAAgQIEgNhFUAKDwoIBAACBAicCAASA2EWPwqJAQoEBAACBRIDZQJGGnwg
T3V0cHV0IG9ubHkuIFpvbmUgd2hlcmUgdGhlIHZpcnR1YWwgbWFjaGluZSBpcyBsb2NhdGVk
LiBPbmx5IGFwcGxpY2FibGUgZm9yIGluc3RhbmNlcwogaW4gQXBwIEVuZ2luZSBmbGV4aWJs
ZSBlbnZpcm9ubWVudC4KCgwKBQQAAgUFEgNlAggKDAoFBAACBQESA2UJFQoMCgUEAAIFAxID
ZRgZCgwKBQQAAgUIEgNlGkUKDwoIBAACBQicCAASA2UbRAqDAQoEBAACBhIDaQI/GnYgT3V0
cHV0IG9ubHkuIFZpcnR1YWwgbWFjaGluZSBJRCBvZiB0aGlzIGluc3RhbmNlLiBPbmx5IGFw
cGxpY2FibGUgZm9yIGluc3RhbmNlcyBpbgogQXBwIEVuZ2luZSBmbGV4aWJsZSBlbnZpcm9u
bWVudC4KCgwKBQQAAgYFEgNpAggKDAoFBAACBgESA2kJDgoMCgUEAAIGAxIDaRESCgwKBQQA
AgYIEgNpEz4KDwoIBAACBgicCAASA2kUPQpOCgQEAAIHEgNuAlcaQSBPdXRwdXQgb25seS4g
VGltZSB0aGF0IHRoaXMgaW5zdGFuY2Ugd2FzIHN0YXJ0ZWQuCgogQE91dHB1dE9ubHkKCgwK
BQQAAgcGEgNuAhsKDAoFBAACBwESA24cJgoMCgUEAAIHAxIDbikqCgwKBQQAAgcIEgNuK1YK
DwoIBAACBwicCAASA24sVQpPCgQEAAIIEgNxAkEaQiBPdXRwdXQgb25seS4gTnVtYmVyIG9m
IHJlcXVlc3RzIHNpbmNlIHRoaXMgaW5zdGFuY2Ugd2FzIHN0YXJ0ZWQuCgoMCgUEAAIIBRID
cQIHCgwKBQQAAggBEgNxCBAKDAoFBAACCAMSA3ETFAoMCgUEAAIICBIDcRVACg8KCAQAAggI
nAgAEgNxFj8KTQoEBAACCRIDdAJAGkAgT3V0cHV0IG9ubHkuIE51bWJlciBvZiBlcnJvcnMg
c2luY2UgdGhpcyBpbnN0YW5jZSB3YXMgc3RhcnRlZC4KCgwKBQQAAgkFEgN0AgcKDAoFBAAC
CQESA3QIDgoMCgUEAAIJAxIDdBETCgwKBQQAAgkIEgN0FD8KDwoIBAACCQicCAASA3QVPgpS
CgQEAAIKEgN3Aj0aRSBPdXRwdXQgb25seS4gQXZlcmFnZSBxdWVyaWVzIHBlciBzZWNvbmQg
KFFQUykgb3ZlciB0aGUgbGFzdCBtaW51dGUuCgoMCgUEAAIKBRIDdwIHCgwKBQQAAgoBEgN3
CAsKDAoFBAACCgMSA3cOEAoMCgUEAAIKCBIDdxE8Cg8KCAQAAgoInAgAEgN3EjsKRgoEBAAC
CxIDegJJGjkgT3V0cHV0IG9ubHkuIEF2ZXJhZ2UgbGF0ZW5jeSAobXMpIG92ZXIgdGhlIGxh
c3QgbWludXRlLgoKDAoFBAACCwUSA3oCBwoMCgUEAAILARIDeggXCgwKBQQAAgsDEgN6GhwK
DAoFBAACCwgSA3odSAoPCggEAAILCJwIABIDeh5HCjgKBAQAAgwSA30CRhorIE91dHB1dCBv
bmx5LiBUb3RhbCBtZW1vcnkgaW4gdXNlIChieXRlcykuCgoMCgUEAAIMBRIDfQIHCgwKBQQA
AgwBEgN9CBQKDAoFBAACDAMSA30XGQoMCgUEAAIMCBIDfRpFCg8KCAQAAgwInAgAEgN9G0QK
mQEKBAQAAg0SBIEBAkQaigEgT3V0cHV0IG9ubHkuIFN0YXR1cyBvZiB0aGUgdmlydHVhbCBt
YWNoaW5lIHdoZXJlIHRoaXMgaW5zdGFuY2UgbGl2ZXMuIE9ubHkgYXBwbGljYWJsZQogZm9y
IGluc3RhbmNlcyBpbiBBcHAgRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKDQoFBAAC
DQUSBIEBAggKDQoFBAACDQESBIEBCRIKDQoFBAACDQMSBIEBFRcKDQoFBAACDQgSBIEBGEMK
EAoIBAACDQicCAASBIEBGUIKhwEKBAQAAg4SBIUBAkkaeSBPdXRwdXQgb25seS4gV2hldGhl
ciB0aGlzIGluc3RhbmNlIGlzIGluIGRlYnVnIG1vZGUuIE9ubHkgYXBwbGljYWJsZSBmb3Ig
aW5zdGFuY2VzIGluCiBBcHAgRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKDQoFBAAC
DgUSBIUBAgYKDQoFBAACDgESBIUBBxcKDQoFBAACDgMSBIUBGhwKDQoFBAACDggSBIUBHUgK
EAoIBAACDgicCAASBIUBHkcKgAEKBAQAAg8SBIkBAkAaciBPdXRwdXQgb25seS4gVGhlIElQ
IGFkZHJlc3Mgb2YgdGhpcyBpbnN0YW5jZS4gT25seSBhcHBsaWNhYmxlIGZvciBpbnN0YW5j
ZXMgaW4gQXBwCiBFbmdpbmUgZmxleGlibGUgZW52aXJvbm1lbnQuCgoNCgUEAAIPBRIEiQEC
CAoNCgUEAAIPARIEiQEJDgoNCgUEAAIPAxIEiQEREwoNCgUEAAIPCBIEiQEUPwoQCggEAAIP
CJwIABIEiQEVPgqLAQoEBAACEBIEjQECVhp9IE91dHB1dCBvbmx5LiBUaGUgbGl2ZW5lc3Mg
aGVhbHRoIGNoZWNrIG9mIHRoaXMgaW5zdGFuY2UuIE9ubHkgYXBwbGljYWJsZSBmb3IgaW5z
dGFuY2VzCiBpbiBBcHAgRW5naW5lIGZsZXhpYmxlIGVudmlyb25tZW50LgoKDQoFBAACEAYS
BI0BAhgKDQoFBAACEAESBI0BGSQKDQoFBAACEAMSBI0BJykKDQoFBAACEAgSBI0BKlUKEAoI
BAACEAicCAASBI0BK1RiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: app_engine_release Type: 9 ()
    # Field: availability Type: 14 (.google.appengine.v1beta.Instance.Availability)
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
    # Field: vm_liveness Type: 14 (.google.appengine.v1beta.Instance.Liveness.LivenessState)

# Enum: Instance::Availability
our $Instance_UNSPECIFIED = 0;
our $Instance_RESIDENT = 1;
our $Instance_DYNAMIC = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Instance - Compiled Protocol Buffers messages for google/appengine/v1beta/instance.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Instance;

    my $msg = Google::Appengine::V1beta::Instance::Instance->new({
        name => $name,
        id => $id,
        app_engine_release => $app_engine_release,
        availability => $availability,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Instance::Instance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Instance::Instance

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

Type: C<Enum> (L<Google::Appengine::V1beta::Instance::Availability>)

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

Type: C<Enum> (L<Google::Appengine::V1beta::Instance::Liveness::LivenessState>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
