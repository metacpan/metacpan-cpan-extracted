package Google::Cloud::Talent::V4::Job;

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
    eval { require Google::Cloud::Talent::V4::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2pvYi5wcm90bxIWZ29vZ2xlLmNsb3VkLnRhbGVu
dC52NBofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL3RhbGVudC92NC9jb21tb24ucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8inhMKA0pvYhISCgRuYW1lGAEgASgJUgRuYW1l
Ej0KB2NvbXBhbnkYAiABKAlCI+BBAvpBHQobam9icy5nb29nbGVhcGlzLmNvbS9Db21wYW55
Ugdjb21wYW55EioKDnJlcXVpc2l0aW9uX2lkGAMgASgJQgPgQQJSDXJlcXVpc2l0aW9uSWQS
GQoFdGl0bGUYBCABKAlCA+BBAlIFdGl0bGUSJQoLZGVzY3JpcHRpb24YBSABKAlCA+BBAlIL
ZGVzY3JpcHRpb24SHAoJYWRkcmVzc2VzGAYgAygJUglhZGRyZXNzZXMSVgoQYXBwbGljYXRp
b25faW5mbxgHIAEoCzIrLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iLkFwcGxpY2F0aW9u
SW5mb1IPYXBwbGljYXRpb25JbmZvEkUKDGpvYl9iZW5lZml0cxgIIAMoDjIiLmdvb2dsZS5j
bG91ZC50YWxlbnQudjQuSm9iQmVuZWZpdFILam9iQmVuZWZpdHMSVQoRY29tcGVuc2F0aW9u
X2luZm8YCSABKAsyKC5nb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBlbnNhdGlvbkluZm9S
EGNvbXBlbnNhdGlvbkluZm8SXgoRY3VzdG9tX2F0dHJpYnV0ZXMYCiADKAsyMS5nb29nbGUu
Y2xvdWQudGFsZW50LnY0LkpvYi5DdXN0b21BdHRyaWJ1dGVzRW50cnlSEGN1c3RvbUF0dHJp
YnV0ZXMSRQoMZGVncmVlX3R5cGVzGAsgAygOMiIuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5E
ZWdyZWVUeXBlUgtkZWdyZWVUeXBlcxIeCgpkZXBhcnRtZW50GAwgASgJUgpkZXBhcnRtZW50
ElEKEGVtcGxveW1lbnRfdHlwZXMYDSADKA4yJi5nb29nbGUuY2xvdWQudGFsZW50LnY0LkVt
cGxveW1lbnRUeXBlUg9lbXBsb3ltZW50VHlwZXMSHgoKaW5jZW50aXZlcxgOIAEoCVIKaW5j
ZW50aXZlcxIjCg1sYW5ndWFnZV9jb2RlGA8gASgJUgxsYW5ndWFnZUNvZGUSPQoJam9iX2xl
dmVsGBAgASgOMiAuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2JMZXZlbFIIam9iTGV2ZWwS
JwoPcHJvbW90aW9uX3ZhbHVlGBEgASgFUg5wcm9tb3Rpb25WYWx1ZRImCg5xdWFsaWZpY2F0
aW9ucxgSIAEoCVIOcXVhbGlmaWNhdGlvbnMSKgoQcmVzcG9uc2liaWxpdGllcxgTIAEoCVIQ
cmVzcG9uc2liaWxpdGllcxJMCg5wb3N0aW5nX3JlZ2lvbhgUIAEoDjIlLmdvb2dsZS5jbG91
ZC50YWxlbnQudjQuUG9zdGluZ1JlZ2lvblINcG9zdGluZ1JlZ2lvbhJGCgp2aXNpYmlsaXR5
GBUgASgOMiIuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5WaXNpYmlsaXR5QgIYAVIKdmlzaWJp
bGl0eRJACg5qb2Jfc3RhcnRfdGltZRgWIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSDGpvYlN0YXJ0VGltZRI8Cgxqb2JfZW5kX3RpbWUYFyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgpqb2JFbmRUaW1lEkwKFHBvc3RpbmdfcHVibGlzaF90aW1lGBggASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIScG9zdGluZ1B1Ymxpc2hUaW1lEkoKE3Bv
c3RpbmdfZXhwaXJlX3RpbWUYGSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhFw
b3N0aW5nRXhwaXJlVGltZRJPChNwb3N0aW5nX2NyZWF0ZV90aW1lGBogASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhFwb3N0aW5nQ3JlYXRlVGltZRJPChNwb3N0aW5n
X3VwZGF0ZV90aW1lGBsgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhFw
b3N0aW5nVXBkYXRlVGltZRI1ChRjb21wYW55X2Rpc3BsYXlfbmFtZRgcIAEoCUID4EEDUhJj
b21wYW55RGlzcGxheU5hbWUSTwoMZGVyaXZlZF9pbmZvGB0gASgLMicuZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NC5Kb2IuRGVyaXZlZEluZm9CA+BBA1ILZGVyaXZlZEluZm8SXAoScHJvY2Vz
c2luZ19vcHRpb25zGB4gASgLMi0uZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuUHJvY2Vz
c2luZ09wdGlvbnNSEXByb2Nlc3NpbmdPcHRpb25zGl8KD0FwcGxpY2F0aW9uSW5mbxIWCgZl
bWFpbHMYASADKAlSBmVtYWlscxIgCgtpbnN0cnVjdGlvbhgCIAEoCVILaW5zdHJ1Y3Rpb24S
EgoEdXJpcxgDIAMoCVIEdXJpcxqZAQoLRGVyaXZlZEluZm8SPgoJbG9jYXRpb25zGAEgAygL
MiAuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Mb2NhdGlvblIJbG9jYXRpb25zEkoKDmpvYl9j
YXRlZ29yaWVzGAMgAygOMiMuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2JDYXRlZ29yeVIN
am9iQ2F0ZWdvcmllcxq1AQoRUHJvY2Vzc2luZ09wdGlvbnMSSQohZGlzYWJsZV9zdHJlZXRf
YWRkcmVzc19yZXNvbHV0aW9uGAEgASgIUh5kaXNhYmxlU3RyZWV0QWRkcmVzc1Jlc29sdXRp
b24SVQoRaHRtbF9zYW5pdGl6YXRpb24YAiABKA4yKC5nb29nbGUuY2xvdWQudGFsZW50LnY0
Lkh0bWxTYW5pdGl6YXRpb25SEGh0bWxTYW5pdGl6YXRpb24abAoVQ3VzdG9tQXR0cmlidXRl
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5Ej0KBXZhbHVlGAIgASgLMicuZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NC5DdXN0b21BdHRyaWJ1dGVSBXZhbHVlOgI4ATpM6kFJChdqb2JzLmdvb2ds
ZWFwaXMuY29tL0pvYhIucHJvamVjdHMve3Byb2plY3R9L3RlbmFudHMve3RlbmFudH0vam9i
cy97am9ifUJiChpjb20uZ29vZ2xlLmNsb3VkLnRhbGVudC52NEIISm9iUHJvdG9QAVoyY2xv
dWQuZ29vZ2xlLmNvbS9nby90YWxlbnQvYXBpdjQvdGFsZW50cGI7dGFsZW50cGKiAgNDVFNK
k4ABCgcSBQ4A/QIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
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
EAAfCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAtCgkKAgMDEgMVACkKCAoBCBID
FwBJCgkKAggLEgMXAEkKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQApCgkKAggIEgMZ
ACkKCAoBCBIDGgAzCgkKAggBEgMaADMKCAoBCBIDGwAhCgkKAggkEgMbACEK6AEKAgQAEgUh
AP0CARraASBBIEpvYiByZXNvdXJjZSByZXByZXNlbnRzIGEgam9iIHBvc3RpbmcgKGFsc28g
cmVmZXJyZWQgdG8gYXMgYSAiam9iIGxpc3RpbmciCiBvciAiam9iIHJlcXVpc2l0aW9uIiku
IEEgam9iIGJlbG9uZ3MgdG8gYQogW0NvbXBhbnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjQu
Q29tcGFueV0sIHdoaWNoIGlzIHRoZSBoaXJpbmcgZW50aXR5CiByZXNwb25zaWJsZSBmb3Ig
dGhlIGpvYi4KCgoKAwQAARIDIQgLCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAo9CgQE
AAMAEgQoAj0DGi8gQXBwbGljYXRpb24gcmVsYXRlZCBkZXRhaWxzIG9mIGEgam9iIHBvc3Rp
bmcuCgoMCgUEAAMAARIDKAoZCq4BCgYEAAMAAgASAy0EHxqeASBVc2UgdGhpcyBmaWVsZCB0
byBzcGVjaWZ5IGVtYWlsIGFkZHJlc3MoZXMpIHRvIHdoaWNoIHJlc3VtZXMgb3IKIGFwcGxp
Y2F0aW9ucyBjYW4gYmUgc2VudC4KCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYWxsb3dlZCBj
aGFyYWN0ZXJzIGZvciBlYWNoIGVudHJ5IGlzIDI1NS4KCg4KBwQAAwACAAQSAy0EDAoOCgcE
AAMAAgAFEgMtDRMKDgoHBAADAAIAARIDLRQaCg4KBwQAAwACAAMSAy0dHgrGAgoGBAADAAIB
EgM2BBsatgIgVXNlIHRoaXMgZmllbGQgdG8gcHJvdmlkZSBpbnN0cnVjdGlvbnMsIHN1Y2gg
YXMgIk1haWwgeW91ciBhcHBsaWNhdGlvbgogdG8gLi4uIiwgdGhhdCBhIGNhbmRpZGF0ZSBj
YW4gZm9sbG93IHRvIGFwcGx5IGZvciB0aGUgam9iLgoKIFRoaXMgZmllbGQgYWNjZXB0cyBh
bmQgc2FuaXRpemVzIEhUTUwgaW5wdXQsIGFuZCBhbHNvIGFjY2VwdHMKIGJvbGQsIGl0YWxp
Yywgb3JkZXJlZCBsaXN0LCBhbmQgdW5vcmRlcmVkIGxpc3QgbWFya3VwIHRhZ3MuCgogVGhl
IG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAzLDAwMC4KCg4KBwQA
AwACAQUSAzYECgoOCgcEAAMAAgEBEgM2CxYKDgoHBAADAAIBAxIDNhkaCsEBCgYEAAMAAgIS
AzwEHRqxASBVc2UgdGhpcyBVUkkgZmllbGQgdG8gZGlyZWN0IGFuIGFwcGxpY2FudCB0byBh
IHdlYnNpdGUsIGZvciBleGFtcGxlIHRvCiBsaW5rIHRvIGFuIG9ubGluZSBhcHBsaWNhdGlv
biBmb3JtLgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMgZm9y
IGVhY2ggZW50cnkgaXMgMiwwMDAuCgoOCgcEAAMAAgIEEgM8BAwKDgoHBAADAAICBRIDPA0T
Cg4KBwQAAwACAgESAzwUGAoOCgcEAAMAAgIDEgM8GxwKNgoEBAADARIEQAJMAxooIERlcml2
ZWQgZGV0YWlscyBhYm91dCB0aGUgam9iIHBvc3RpbmcuCgoMCgUEAAMBARIDQAoVCpoCCgYE
AAMBAgASA0cEJBqKAiBTdHJ1Y3R1cmVkIGxvY2F0aW9ucyBvZiB0aGUgam9iLCByZXNvbHZl
ZCBmcm9tCiBbSm9iLmFkZHJlc3Nlc11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuYWRk
cmVzc2VzXS4KCiBbbG9jYXRpb25zXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5EZXJp
dmVkSW5mby5sb2NhdGlvbnNdIGFyZSBleGFjdGx5CiBtYXRjaGVkIHRvIFtKb2IuYWRkcmVz
c2VzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5hZGRyZXNzZXNdIGluIHRoZQogc2Ft
ZSBvcmRlci4KCg4KBwQAAwECAAQSA0cEDAoOCgcEAAMBAgAGEgNHDRUKDgoHBAADAQIAARID
RxYfCg4KBwQAAwECAAMSA0ciIwqbAQoGBAADAQIBEgNLBCwaiwEgSm9iIGNhdGVnb3JpZXMg
ZGVyaXZlZCBmcm9tIFtKb2IudGl0bGVdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iLnRp
dGxlXQogYW5kIFtKb2IuZGVzY3JpcHRpb25dW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9i
LmRlc2NyaXB0aW9uXS4KCg4KBwQAAwECAQQSA0sEDAoOCgcEAAMBAgEGEgNLDRgKDgoHBAAD
AQIBARIDSxknCg4KBwQAAwECAQMSA0sqKworCgQEAAMCEgRPAmIDGh0gT3B0aW9ucyBmb3Ig
am9iIHByb2Nlc3NpbmcuCgoMCgUEAAMCARIDTwobCm8KBgQAAwICABIDUgQvGmAgSWYgc2V0
IHRvIGB0cnVlYCwgdGhlIHNlcnZpY2UgZG9lcyBub3QgYXR0ZW1wdCB0byByZXNvbHZlIGEK
IG1vcmUgcHJlY2lzZSBhZGRyZXNzIGZvciB0aGUgam9iLgoKDgoHBAADAgIABRIDUgQICg4K
BwQAAwICAAESA1IJKgoOCgcEAAMCAgADEgNSLS4K+gIKBgQAAwICARIDYQQrGuoCIE9wdGlv
biBmb3Igam9iIEhUTUwgY29udGVudCBzYW5pdGl6YXRpb24uIEFwcGxpZWQgZmllbGRzIGFy
ZToKCiAqIGRlc2NyaXB0aW9uCiAqIGFwcGxpY2F0aW9uSW5mby5pbnN0cnVjdGlvbgogKiBp
bmNlbnRpdmVzCiAqIHF1YWxpZmljYXRpb25zCiAqIHJlc3BvbnNpYmlsaXRpZXMKCiBIVE1M
IHRhZ3MgaW4gdGhlc2UgZmllbGRzIG1heSBiZSBzdHJpcHBlZCBpZiBzYW5pdGlhemF0aW9u
IGlzbid0CiBkaXNhYmxlZC4KCiBEZWZhdWx0cyB0bwogW0h0bWxTYW5pdGl6YXRpb24uU0lN
UExFX0ZPUk1BVFRJTkdfT05MWV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5IdG1sU2FuaXRp
emF0aW9uLlNJTVBMRV9GT1JNQVRUSU5HX09OTFldLgoKDgoHBAADAgIBBhIDYQQUCg4KBwQA
AwICAQESA2EVJgoOCgcEAAMCAgEDEgNhKSoKrAMKBAQAAgASA3ACEhqeAyBSZXF1aXJlZCBk
dXJpbmcgam9iIHVwZGF0ZS4KCiBUaGUgcmVzb3VyY2UgbmFtZSBmb3IgdGhlIGpvYi4gVGhp
cyBpcyBnZW5lcmF0ZWQgYnkgdGhlIHNlcnZpY2Ugd2hlbiBhCiBqb2IgaXMgY3JlYXRlZC4K
CiBUaGUgZm9ybWF0IGlzCiAicHJvamVjdHMve3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFu
dF9pZH0vam9icy97am9iX2lkfSIuIEZvcgogZXhhbXBsZSwgInByb2plY3RzL2Zvby90ZW5h
bnRzL2Jhci9qb2JzL2JheiIuCgogVXNlIG9mIHRoaXMgZmllbGQgaW4gam9iIHF1ZXJpZXMg
YW5kIEFQSSBjYWxscyBpcyBwcmVmZXJyZWQgb3ZlciB0aGUgdXNlIG9mCiBbcmVxdWlzaXRp
b25faWRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iLnJlcXVpc2l0aW9uX2lkXSBzaW5j
ZSB0aGlzCiB2YWx1ZSBpcyB1bmlxdWUuCgoMCgUEAAIABRIDcAIICgwKBQQAAgABEgNwCQ0K
DAoFBAACAAMSA3AQEQrZAQoEBAACARIEdwJ6BBrKASBSZXF1aXJlZC4gVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIGNvbXBhbnkgbGlzdGluZyB0aGUgam9iLgoKIFRoZSBmb3JtYXQgaXMK
ICJwcm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50cy97dGVuYW50X2lkfS9jb21wYW5pZXMv
e2NvbXBhbnlfaWR9Ii4gRm9yCiBleGFtcGxlLCAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFy
L2NvbXBhbmllcy9iYXoiLgoKDAoFBAACAQUSA3cCCAoMCgUEAAIBARIDdwkQCgwKBQQAAgED
EgN3ExQKDQoFBAACAQgSBHcVegMKDwoIBAACAQicCAASA3gEKgoOCgcEAAIBCJ8IEgN5BE0K
iAQKBAQAAgISBIUBAkUa+QMgUmVxdWlyZWQuIFRoZSByZXF1aXNpdGlvbiBJRCwgYWxzbyBy
ZWZlcnJlZCB0byBhcyB0aGUgcG9zdGluZyBJRCwgaXMKIGFzc2lnbmVkIGJ5IHRoZSBjbGll
bnQgdG8gaWRlbnRpZnkgYSBqb2IuIFRoaXMgZmllbGQgaXMgaW50ZW5kZWQgdG8gYmUgdXNl
ZAogYnkgY2xpZW50cyBmb3IgY2xpZW50IGlkZW50aWZpY2F0aW9uIGFuZCB0cmFja2luZyBv
ZiBwb3N0aW5ncy4gQSBqb2IgaXNuJ3QKIGFsbG93ZWQgdG8gYmUgY3JlYXRlZCBpZiB0aGVy
ZSBpcyBhbm90aGVyIGpvYiB3aXRoIHRoZSBzYW1lCiBbY29tcGFueV1bZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NC5Kb2IubmFtZV0sCiBbbGFuZ3VhZ2VfY29kZV1bZ29vZ2xlLmNsb3VkLnRh
bGVudC52NC5Kb2IubGFuZ3VhZ2VfY29kZV0gYW5kCiBbcmVxdWlzaXRpb25faWRdW2dvb2ds
ZS5jbG91ZC50YWxlbnQudjQuSm9iLnJlcXVpc2l0aW9uX2lkXS4KCiBUaGUgbWF4aW11bSBu
dW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDI1NS4KCg0KBQQAAgIFEgSFAQIICg0K
BQQAAgIBEgSFAQkXCg0KBQQAAgIDEgSFARobCg0KBQQAAgIIEgSFARxEChAKCAQAAgIInAgA
EgSFAR1DCn4KBAQAAgMSBIoBAjwacCBSZXF1aXJlZC4gVGhlIHRpdGxlIG9mIHRoZSBqb2Is
IHN1Y2ggYXMgIlNvZnR3YXJlIEVuZ2luZWVyIgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBh
bGxvd2VkIGNoYXJhY3RlcnMgaXMgNTAwLgoKDQoFBAACAwUSBIoBAggKDQoFBAACAwESBIoB
CQ4KDQoFBAACAwMSBIoBERIKDQoFBAACAwgSBIoBEzsKEAoIBAACAwicCAASBIoBFDoKzwQK
BAQAAgQSBJcBAkIawAQgUmVxdWlyZWQuIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgam9iLCB3
aGljaCB0eXBpY2FsbHkgaW5jbHVkZXMgYQogbXVsdGktcGFyYWdyYXBoIGRlc2NyaXB0aW9u
IG9mIHRoZSBjb21wYW55IGFuZCByZWxhdGVkIGluZm9ybWF0aW9uLgogU2VwYXJhdGUgZmll
bGRzIGFyZSBwcm92aWRlZCBvbiB0aGUgam9iIG9iamVjdCBmb3IKIFtyZXNwb25zaWJpbGl0
aWVzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5yZXNwb25zaWJpbGl0aWVzXSwKIFtx
dWFsaWZpY2F0aW9uc11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IucXVhbGlmaWNhdGlv
bnNdLCBhbmQgb3RoZXIgam9iCiBjaGFyYWN0ZXJpc3RpY3MuIFVzZSBvZiB0aGVzZSBzZXBh
cmF0ZSBqb2IgZmllbGRzIGlzIHJlY29tbWVuZGVkLgoKIFRoaXMgZmllbGQgYWNjZXB0cyBh
bmQgc2FuaXRpemVzIEhUTUwgaW5wdXQsIGFuZCBhbHNvIGFjY2VwdHMKIGJvbGQsIGl0YWxp
Yywgb3JkZXJlZCBsaXN0LCBhbmQgdW5vcmRlcmVkIGxpc3QgbWFya3VwIHRhZ3MuCgogVGhl
IG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAxMDAsMDAwLgoKDQoF
BAACBAUSBJcBAggKDQoFBAACBAESBJcBCRQKDQoFBAACBAMSBJcBFxgKDQoFBAACBAgSBJcB
GUEKEAoIBAACBAicCAASBJcBGkAK3w0KBAQAAgUSBLoBAiAa0A0gU3Ryb25nbHkgcmVjb21t
ZW5kZWQgZm9yIHRoZSBiZXN0IHNlcnZpY2UgZXhwZXJpZW5jZS4KCiBMb2NhdGlvbihzKSB3
aGVyZSB0aGUgZW1wbG95ZXIgaXMgbG9va2luZyB0byBoaXJlIGZvciB0aGlzIGpvYiBwb3N0
aW5nLgoKIFNwZWNpZnlpbmcgdGhlIGZ1bGwgc3RyZWV0IGFkZHJlc3MoZXMpIG9mIHRoZSBo
aXJpbmcgbG9jYXRpb24gZW5hYmxlcwogYmV0dGVyIEFQSSByZXN1bHRzLCBlc3BlY2lhbGx5
IGpvYiBzZWFyY2hlcyBieSBjb21tdXRlIHRpbWUuCgogQXQgbW9zdCA1MCBsb2NhdGlvbnMg
YXJlIGFsbG93ZWQgZm9yIGJlc3Qgc2VhcmNoIHBlcmZvcm1hbmNlLiBJZiBhIGpvYiBoYXMK
IG1vcmUgbG9jYXRpb25zLCBpdCBpcyBzdWdnZXN0ZWQgdG8gc3BsaXQgaXQgaW50byBtdWx0
aXBsZSBqb2JzIHdpdGggdW5pcXVlCiBbcmVxdWlzaXRpb25faWRdW2dvb2dsZS5jbG91ZC50
YWxlbnQudjQuSm9iLnJlcXVpc2l0aW9uX2lkXXMgKGUuZy4gJ1JlcUEnCiBiZWNvbWVzICdS
ZXFBLTEnLCAnUmVxQS0yJywgYW5kIHNvIG9uLikgYXMgbXVsdGlwbGUgam9icyB3aXRoIHRo
ZSBzYW1lCiBbY29tcGFueV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuY29tcGFueV0s
CiBbbGFuZ3VhZ2VfY29kZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IubGFuZ3VhZ2Vf
Y29kZV0gYW5kCiBbcmVxdWlzaXRpb25faWRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9i
LnJlcXVpc2l0aW9uX2lkXSBhcmUgbm90CiBhbGxvd2VkLiBJZiB0aGUgb3JpZ2luYWwKIFty
ZXF1aXNpdGlvbl9pZF1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IucmVxdWlzaXRpb25f
aWRdIG11c3QgYmUKIHByZXNlcnZlZCwgYSBjdXN0b20gZmllbGQgc2hvdWxkIGJlIHVzZWQg
Zm9yIHN0b3JhZ2UuIEl0IGlzIGFsc28gc3VnZ2VzdGVkCiB0byBncm91cCB0aGUgbG9jYXRp
b25zIHRoYXQgY2xvc2UgdG8gZWFjaCBvdGhlciBpbiB0aGUgc2FtZSBqb2IgZm9yIGJldHRl
cgogc2VhcmNoIGV4cGVyaWVuY2UuCgogSm9icyB3aXRoIG11bHRpcGxlIGFkZHJlc3NlcyBt
dXN0IGhhdmUgdGhlaXIgYWRkcmVzc2VzIHdpdGggdGhlIHNhbWUKIFtMb2NhdGlvblR5cGVd
W2dvb2dsZS5jbG91ZC50YWxlbnQudjQuTG9jYXRpb24uTG9jYXRpb25UeXBlXSB0byBhbGxv
dwogbG9jYXRpb24gZmlsdGVyaW5nIHRvIHdvcmsgcHJvcGVybHkuIChGb3IgZXhhbXBsZSwg
YSBKb2Igd2l0aCBhZGRyZXNzZXMKICIxNjAwIEFtcGhpdGhlYXRyZSBQYXJrd2F5LCBNb3Vu
dGFpbiBWaWV3LCBDQSwgVVNBIiBhbmQgIkxvbmRvbiwgVUsiIG1heQogbm90IGhhdmUgbG9j
YXRpb24gZmlsdGVycyBhcHBsaWVkIGNvcnJlY3RseSBhdCBzZWFyY2ggdGltZSBzaW5jZSB0
aGUgZmlyc3QKIGlzIGEKIFtMb2NhdGlvblR5cGUuU1RSRUVUX0FERFJFU1NdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjQuTG9jYXRpb24uTG9jYXRpb25UeXBlLlNUUkVFVF9BRERSRVNTXQog
YW5kIHRoZSBzZWNvbmQgaXMgYQogW0xvY2F0aW9uVHlwZS5MT0NBTElUWV1bZ29vZ2xlLmNs
b3VkLnRhbGVudC52NC5Mb2NhdGlvbi5Mb2NhdGlvblR5cGUuTE9DQUxJVFldLikKIElmIGEg
am9iIG5lZWRzIHRvIGhhdmUgbXVsdGlwbGUgYWRkcmVzc2VzLCBpdCBpcyBzdWdnZXN0ZWQg
dG8gc3BsaXQgaXQgaW50bwogbXVsdGlwbGUgam9icyB3aXRoIHNhbWUgTG9jYXRpb25UeXBl
cy4KCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDUwMC4K
Cg0KBQQAAgUEEgS6AQIKCg0KBQQAAgUFEgS6AQsRCg0KBQQAAgUBEgS6ARIbCg0KBQQAAgUD
EgS6AR4fCiwKBAQAAgYSBL0BAicaHiBKb2IgYXBwbGljYXRpb24gaW5mb3JtYXRpb24uCgoN
CgUEAAIGBhIEvQECEQoNCgUEAAIGARIEvQESIgoNCgUEAAIGAxIEvQElJgozCgQEAAIHEgTA
AQInGiUgVGhlIGJlbmVmaXRzIGluY2x1ZGVkIHdpdGggdGhlIGpvYi4KCg0KBQQAAgcEEgTA
AQIKCg0KBQQAAgcGEgTAAQsVCg0KBQQAAgcBEgTAARYiCg0KBQQAAgcDEgTAASUmCngKBAQA
AggSBMQBAikaaiBKb2IgY29tcGVuc2F0aW9uIGluZm9ybWF0aW9uIChhLmsuYS4gInBheSBy
YXRlIikgaS5lLiwgdGhlIGNvbXBlbnNhdGlvbgogdGhhdCB3aWxsIHBhaWQgdG8gdGhlIGVt
cGxveWVlLgoKDQoFBAACCAYSBMQBAhIKDQoFBAACCAESBMQBEyQKDQoFBAACCAMSBMQBJygK
4QQKBAQAAgkSBNIBAjYa0gQgQSBtYXAgb2YgZmllbGRzIHRvIGhvbGQgYm90aCBmaWx0ZXJh
YmxlIGFuZCBub24tZmlsdGVyYWJsZSBjdXN0b20gam9iCiBhdHRyaWJ1dGVzIHRoYXQgYXJl
IG5vdCBjb3ZlcmVkIGJ5IHRoZSBwcm92aWRlZCBzdHJ1Y3R1cmVkIGZpZWxkcy4KCiBUaGUg
a2V5cyBvZiB0aGUgbWFwIGFyZSBzdHJpbmdzIHVwIHRvIDY0IGJ5dGVzIGFuZCBtdXN0IG1h
dGNoIHRoZQogcGF0dGVybjogYFthLXpBLVpdW2EtekEtWjAtOV9dKmAuIEZvciBleGFtcGxl
LCBrZXkwTGlrZVRoaXMgb3IKIEtFWV8xX0xJS0VfVEhJUy4KCiBBdCBtb3N0IDEwMCBmaWx0
ZXJhYmxlIGFuZCBhdCBtb3N0IDEwMCB1bmZpbHRlcmFibGUga2V5cyBhcmUgc3VwcG9ydGVk
LgogRm9yIGZpbHRlcmFibGUgYHN0cmluZ192YWx1ZXNgLCBhY3Jvc3MgYWxsIGtleXMgYXQg
bW9zdCAyMDAgdmFsdWVzIGFyZQogYWxsb3dlZCwgd2l0aCBlYWNoIHN0cmluZyBubyBtb3Jl
IHRoYW4gMjU1IGNoYXJhY3RlcnMuIEZvciB1bmZpbHRlcmFibGUKIGBzdHJpbmdfdmFsdWVz
YCwgdGhlIG1heGltdW0gdG90YWwgc2l6ZSBvZiBgc3RyaW5nX3ZhbHVlc2AgYWNyb3NzIGFs
bCBrZXlzCiBpcyA1MEtCLgoKDQoFBAACCQYSBNIBAh4KDQoFBAACCQESBNIBHzAKDQoFBAAC
CQMSBNIBMzUKVgoEBAACChIE1QECKBpIIFRoZSBkZXNpcmVkIGVkdWNhdGlvbiBkZWdyZWVz
IGZvciB0aGUgam9iLCBzdWNoIGFzIEJhY2hlbG9ycywgTWFzdGVycy4KCg0KBQQAAgoEEgTV
AQIKCg0KBQQAAgoGEgTVAQsVCg0KBQQAAgoBEgTVARYiCg0KBQQAAgoDEgTVASUnCpEBCgQE
AAILEgTbAQIZGoIBIFRoZSBkZXBhcnRtZW50IG9yIGZ1bmN0aW9uYWwgYXJlYSB3aXRoaW4g
dGhlIGNvbXBhbnkgd2l0aCB0aGUgb3BlbgogcG9zaXRpb24uCgogVGhlIG1heGltdW0gbnVt
YmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAyNTUuCgoNCgUEAAILBRIE2wECCAoNCgUE
AAILARIE2wEJEwoNCgUEAAILAxIE2wEWGAq+AQoEBAACDBIE4AECMBqvASBUaGUgZW1wbG95
bWVudCB0eXBlKHMpIG9mIGEgam9iLCBmb3IgZXhhbXBsZSwKIFtmdWxsIHRpbWVdW2dvb2ds
ZS5jbG91ZC50YWxlbnQudjQuRW1wbG95bWVudFR5cGUuRlVMTF9USU1FXSBvcgogW3BhcnQg
dGltZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5FbXBsb3ltZW50VHlwZS5QQVJUX1RJTUVd
LgoKDQoFBAACDAQSBOABAgoKDQoFBAACDAYSBOABCxkKDQoFBAACDAESBOABGioKDQoFBAAC
DAMSBOABLS8KwgEKBAQAAg0SBOYBAhkaswEgQSBkZXNjcmlwdGlvbiBvZiBib251cywgY29t
bWlzc2lvbiwgYW5kIG90aGVyIGNvbXBlbnNhdGlvbgogaW5jZW50aXZlcyBhc3NvY2lhdGVk
IHdpdGggdGhlIGpvYiBub3QgaW5jbHVkaW5nIHNhbGFyeSBvciBwYXkuCgogVGhlIG1heGlt
dW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAxMCwwMDAuCgoNCgUEAAINBRIE
5gECCAoNCgUEAAINARIE5gEJEwoNCgUEAAINAxIE5gEWGArMBAoEBAACDhIE9QECHBq9BCBU
aGUgbGFuZ3VhZ2Ugb2YgdGhlIHBvc3RpbmcuIFRoaXMgZmllbGQgaXMgZGlzdGluY3QgZnJv
bQogYW55IHJlcXVpcmVtZW50cyBmb3IgZmx1ZW5jeSB0aGF0IGFyZSBhc3NvY2lhdGVkIHdp
dGggdGhlIGpvYi4KCiBMYW5ndWFnZSBjb2RlcyBtdXN0IGJlIGluIEJDUC00NyBmb3JtYXQs
IHN1Y2ggYXMgImVuLVVTIiBvciAic3ItTGF0biIuCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwg
c2VlCiBbVGFncyBmb3IgSWRlbnRpZnlpbmcgTGFuZ3VhZ2VzXShodHRwczovL3Rvb2xzLmll
dGYub3JnL2h0bWwvYmNwNDcpezoKIGNsYXNzPSJleHRlcm5hbCIgdGFyZ2V0PSJfYmxhbmsi
IH0uCgogSWYgdGhpcyBmaWVsZCBpcyB1bnNwZWNpZmllZCBhbmQKIFtKb2IuZGVzY3JpcHRp
b25dW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9iLmRlc2NyaXB0aW9uXSBpcyBwcmVzZW50
LAogZGV0ZWN0ZWQgbGFuZ3VhZ2UgY29kZSBiYXNlZCBvbgogW0pvYi5kZXNjcmlwdGlvbl1b
Z29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuZGVzY3JpcHRpb25dIGlzIGFzc2lnbmVkLAog
b3RoZXJ3aXNlIGRlZmF1bHRzIHRvICdlbl9VUycuCgoNCgUEAAIOBRIE9QECCAoNCgUEAAIO
ARIE9QEJFgoNCgUEAAIOAxIE9QEZGwpUCgQEAAIPEgT4AQIaGkYgVGhlIGV4cGVyaWVuY2Ug
bGV2ZWwgYXNzb2NpYXRlZCB3aXRoIHRoZSBqb2IsIHN1Y2ggYXMgIkVudHJ5IExldmVsIi4K
Cg0KBQQAAg8GEgT4AQIKCg0KBQQAAg8BEgT4AQsUCg0KBQQAAg8DEgT4ARcZCq4DCgQEAAIQ
EgSBAgIdGp8DIEEgcHJvbW90aW9uIHZhbHVlIG9mIHRoZSBqb2IsIGFzIGRldGVybWluZWQg
YnkgdGhlIGNsaWVudC4KIFRoZSB2YWx1ZSBkZXRlcm1pbmVzIHRoZSBzb3J0IG9yZGVyIG9m
IHRoZSBqb2JzIHJldHVybmVkIHdoZW4gc2VhcmNoaW5nIGZvcgogam9icyB1c2luZyB0aGUg
ZmVhdHVyZWQgam9icyBzZWFyY2ggY2FsbCwgd2l0aCBoaWdoZXIgcHJvbW90aW9uYWwgdmFs
dWVzCiBiZWluZyByZXR1cm5lZCBmaXJzdCBhbmQgdGllcyBiZWluZyByZXNvbHZlZCBieSBy
ZWxldmFuY2Ugc29ydC4gT25seSB0aGUKIGpvYnMgd2l0aCBhIHByb21vdGlvblZhbHVlID4w
IGFyZSByZXR1cm5lZCBpbiBhIEZFQVRVUkVEX0pPQl9TRUFSQ0guCgogRGVmYXVsdCB2YWx1
ZSBpcyAwLCBhbmQgbmVnYXRpdmUgdmFsdWVzIGFyZSB0cmVhdGVkIGFzIDAuCgoNCgUEAAIQ
BRIEgQICBwoNCgUEAAIQARIEgQIIFwoNCgUEAAIQAxIEgQIaHAqVAwoEBAACERIEjAICHRqG
AyBBIGRlc2NyaXB0aW9uIG9mIHRoZSBxdWFsaWZpY2F0aW9ucyByZXF1aXJlZCB0byBwZXJm
b3JtIHRoZQogam9iLiBUaGUgdXNlIG9mIHRoaXMgZmllbGQgaXMgcmVjb21tZW5kZWQKIGFz
IGFuIGFsdGVybmF0aXZlIHRvIHVzaW5nIHRoZSBtb3JlIGdlbmVyYWwKIFtkZXNjcmlwdGlv
bl1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuZGVzY3JpcHRpb25dIGZpZWxkLgoKIFRo
aXMgZmllbGQgYWNjZXB0cyBhbmQgc2FuaXRpemVzIEhUTUwgaW5wdXQsIGFuZCBhbHNvIGFj
Y2VwdHMKIGJvbGQsIGl0YWxpYywgb3JkZXJlZCBsaXN0LCBhbmQgdW5vcmRlcmVkIGxpc3Qg
bWFya3VwIHRhZ3MuCgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVy
cyBpcyAxMCwwMDAuCgoNCgUEAAIRBRIEjAICCAoNCgUEAAIRARIEjAIJFwoNCgUEAAIRAxIE
jAIaHAr6AgoEBAACEhIElgICHxrrAiBBIGRlc2NyaXB0aW9uIG9mIGpvYiByZXNwb25zaWJp
bGl0aWVzLiBUaGUgdXNlIG9mIHRoaXMgZmllbGQgaXMKIHJlY29tbWVuZGVkIGFzIGFuIGFs
dGVybmF0aXZlIHRvIHVzaW5nIHRoZSBtb3JlIGdlbmVyYWwKIFtkZXNjcmlwdGlvbl1bZ29v
Z2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuZGVzY3JpcHRpb25dIGZpZWxkLgoKIFRoaXMgZmll
bGQgYWNjZXB0cyBhbmQgc2FuaXRpemVzIEhUTUwgaW5wdXQsIGFuZCBhbHNvIGFjY2VwdHMK
IGJvbGQsIGl0YWxpYywgb3JkZXJlZCBsaXN0LCBhbmQgdW5vcmRlcmVkIGxpc3QgbWFya3Vw
IHRhZ3MuCgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAx
MCwwMDAuCgoNCgUEAAISBRIElgICCAoNCgUEAAISARIElgIJGQoNCgUEAAISAxIElgIcHgqY
BQoEBAACExIEoQICJBqJBSBUaGUgam9iIFtQb3N0aW5nUmVnaW9uXVtnb29nbGUuY2xvdWQu
dGFsZW50LnY0LlBvc3RpbmdSZWdpb25dIChmb3IgZXhhbXBsZSwKIHN0YXRlLCBjb3VudHJ5
KSB0aHJvdWdob3V0IHdoaWNoIHRoZSBqb2IgaXMgYXZhaWxhYmxlLiBJZiB0aGlzIGZpZWxk
IGlzCiBzZXQsIGEgW0xvY2F0aW9uRmlsdGVyXVtnb29nbGUuY2xvdWQudGFsZW50LnY0Lkxv
Y2F0aW9uRmlsdGVyXSBpbiBhIHNlYXJjaAogcXVlcnkgd2l0aGluIHRoZSBqb2IgcmVnaW9u
IGZpbmRzIHRoaXMgam9iIHBvc3RpbmcgaWYgYW4gZXhhY3QgbG9jYXRpb24KIG1hdGNoIGlz
bid0IHNwZWNpZmllZC4gSWYgdGhpcyBmaWVsZCBpcyBzZXQgdG8KIFtQb3N0aW5nUmVnaW9u
Lk5BVElPTl1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Qb3N0aW5nUmVnaW9uLk5BVElPTl0g
b3IKIFtQb3N0aW5nUmVnaW9uLkFETUlOSVNUUkFUSVZFX0FSRUFdW2dvb2dsZS5jbG91ZC50
YWxlbnQudjQuUG9zdGluZ1JlZ2lvbi5BRE1JTklTVFJBVElWRV9BUkVBXSwKIHNldHRpbmcg
am9iIFtKb2IuYWRkcmVzc2VzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5hZGRyZXNz
ZXNdIHRvIHRoZQogc2FtZSBsb2NhdGlvbiBsZXZlbCBhcyB0aGlzIGZpZWxkIGlzIHN0cm9u
Z2x5IHJlY29tbWVuZGVkLgoKDQoFBAACEwYSBKECAg8KDQoFBAACEwESBKECEB4KDQoFBAAC
EwMSBKECISMKywEKBAQAAhQSBKoCAjEavAEgRGVwcmVjYXRlZC4gVGhlIGpvYiBpcyBvbmx5
IHZpc2libGUgdG8gdGhlIG93bmVyLgoKIFRoZSB2aXNpYmlsaXR5IG9mIHRoZSBqb2IuCgog
RGVmYXVsdHMgdG8KIFtWaXNpYmlsaXR5LkFDQ09VTlRfT05MWV1bZ29vZ2xlLmNsb3VkLnRh
bGVudC52NC5WaXNpYmlsaXR5LkFDQ09VTlRfT05MWV0KIGlmIG5vdCBzcGVjaWZpZWQuCgoN
CgUEAAIUBhIEqgICDAoNCgUEAAIUARIEqgINFwoNCgUEAAIUAxIEqgIaHAoNCgUEAAIUCBIE
qgIdMAoOCgYEAAIUCAMSBKoCHi8KnAEKBAQAAhUSBK4CAjAajQEgVGhlIHN0YXJ0IHRpbWVz
dGFtcCBvZiB0aGUgam9iIGluIFVUQyB0aW1lIHpvbmUuIFR5cGljYWxseSB0aGlzIGZpZWxk
CiBpcyB1c2VkIGZvciBjb250cmFjdGluZyBlbmdhZ2VtZW50cy4gSW52YWxpZCB0aW1lc3Rh
bXBzIGFyZSBpZ25vcmVkLgoKDQoFBAACFQYSBK4CAhsKDQoFBAACFQESBK4CHCoKDQoFBAAC
FQMSBK4CLS8KiAEKBAQAAhYSBLICAi4aeiBUaGUgZW5kIHRpbWVzdGFtcCBvZiB0aGUgam9i
LiBUeXBpY2FsbHkgdGhpcyBmaWVsZCBpcyB1c2VkIGZvciBjb250cmFjdGluZwogZW5nYWdl
bWVudHMuIEludmFsaWQgdGltZXN0YW1wcyBhcmUgaWdub3JlZC4KCg0KBQQAAhYGEgSyAgIb
Cg0KBQQAAhYBEgSyAhwoCg0KBQQAAhYDEgSyAistCq8BCgQEAAIXEgS3AgI2GqABIFRoZSB0
aW1lc3RhbXAgdGhpcyBqb2IgcG9zdGluZyB3YXMgbW9zdCByZWNlbnRseSBwdWJsaXNoZWQu
IFRoZSBkZWZhdWx0CiB2YWx1ZSBpcyB0aGUgdGltZSB0aGUgcmVxdWVzdCBhcnJpdmVzIGF0
IHRoZSBzZXJ2ZXIuIEludmFsaWQgdGltZXN0YW1wcyBhcmUKIGlnbm9yZWQuCgoNCgUEAAIX
BhIEtwICGwoNCgUEAAIXARIEtwIcMAoNCgUEAAIXAxIEtwIzNQqOFQoEBAACGBIE6wICNRr/
FCBTdHJvbmdseSByZWNvbW1lbmRlZCBmb3IgdGhlIGJlc3Qgc2VydmljZSBleHBlcmllbmNl
LgoKIFRoZSBleHBpcmF0aW9uIHRpbWVzdGFtcCBvZiB0aGUgam9iLiBBZnRlciB0aGlzIHRp
bWVzdGFtcCwgdGhlCiBqb2IgaXMgbWFya2VkIGFzIGV4cGlyZWQsIGFuZCBpdCBubyBsb25n
ZXIgYXBwZWFycyBpbiBzZWFyY2ggcmVzdWx0cy4gVGhlCiBleHBpcmVkIGpvYiBjYW4ndCBi
ZSBsaXN0ZWQgYnkgdGhlCiBbTGlzdEpvYnNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuSm9i
U2VydmljZS5MaXN0Sm9ic10gQVBJLCBidXQgaXQgY2FuIGJlCiByZXRyaWV2ZWQgd2l0aCB0
aGUgW0dldEpvYl1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2JTZXJ2aWNlLkdldEpvYl0g
QVBJCiBvciB1cGRhdGVkIHdpdGggdGhlCiBbVXBkYXRlSm9iXVtnb29nbGUuY2xvdWQudGFs
ZW50LnY0LkpvYlNlcnZpY2UuVXBkYXRlSm9iXSBBUEkgb3IgZGVsZXRlZAogd2l0aCB0aGUg
W0RlbGV0ZUpvYl1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2JTZXJ2aWNlLkRlbGV0ZUpv
Yl0gQVBJLiBBbgogZXhwaXJlZCBqb2IgY2FuIGJlIHVwZGF0ZWQgYW5kIG9wZW5lZCBhZ2Fp
biBieSB1c2luZyBhIGZ1dHVyZSBleHBpcmF0aW9uCiB0aW1lc3RhbXAuIFVwZGF0aW5nIGFu
IGV4cGlyZWQgam9iIGZhaWxzIGlmIHRoZXJlIGlzIGFub3RoZXIgZXhpc3Rpbmcgb3Blbgog
am9iIHdpdGggc2FtZSBbY29tcGFueV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IuY29t
cGFueV0sCiBbbGFuZ3VhZ2VfY29kZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IubGFu
Z3VhZ2VfY29kZV0gYW5kCiBbcmVxdWlzaXRpb25faWRdW2dvb2dsZS5jbG91ZC50YWxlbnQu
djQuSm9iLnJlcXVpc2l0aW9uX2lkXS4KCiBUaGUgZXhwaXJlZCBqb2JzIGFyZSByZXRhaW5l
ZCBpbiBvdXIgc3lzdGVtIGZvciA5MCBkYXlzLiBIb3dldmVyLCB0aGUKIG92ZXJhbGwgZXhw
aXJlZCBqb2IgY291bnQgY2Fubm90IGV4Y2VlZCAzIHRpbWVzIHRoZSBtYXhpbXVtIG51bWJl
ciBvZgogb3BlbiBqb2JzIG92ZXIgcHJldmlvdXMgNyBkYXlzLiBJZiB0aGlzIHRocmVzaG9s
ZCBpcyBleGNlZWRlZCwKIGV4cGlyZWQgam9icyBhcmUgY2xlYW5lZCBvdXQgaW4gb3JkZXIg
b2YgZWFybGllc3QgZXhwaXJlIHRpbWUuCiBFeHBpcmVkIGpvYnMgYXJlIG5vIGxvbmdlciBh
Y2Nlc3NpYmxlIGFmdGVyIHRoZXkgYXJlIGNsZWFuZWQKIG91dC4KCiBJbnZhbGlkIHRpbWVz
dGFtcHMgYXJlIGlnbm9yZWQsIGFuZCB0cmVhdGVkIGFzIGV4cGlyZSB0aW1lIG5vdCBwcm92
aWRlZC4KCiBJZiB0aGUgdGltZXN0YW1wIGlzIGJlZm9yZSB0aGUgaW5zdGFudCByZXF1ZXN0
IGlzIG1hZGUsIHRoZSBqb2IKIGlzIHRyZWF0ZWQgYXMgZXhwaXJlZCBpbW1lZGlhdGVseSBv
biBjcmVhdGlvbi4gVGhpcyBraW5kIG9mIGpvYiBjYW4KIG5vdCBiZSB1cGRhdGVkLiBBbmQg
d2hlbiBjcmVhdGluZyBhIGpvYiB3aXRoIHBhc3QgdGltZXN0YW1wLCB0aGUKIFtwb3N0aW5n
X3B1Ymxpc2hfdGltZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Kb2IucG9zdGluZ19wdWJs
aXNoX3RpbWVdCiBtdXN0IGJlIHNldCBiZWZvcmUKIFtwb3N0aW5nX2V4cGlyZV90aW1lXVtn
b29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5wb3N0aW5nX2V4cGlyZV90aW1lXS4gVGhlCiBw
dXJwb3NlIG9mIHRoaXMgZmVhdHVyZSBpcyB0byBhbGxvdyBvdGhlciBvYmplY3RzLCBzdWNo
IGFzCiBbQXBwbGljYXRpb25JbmZvXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkpvYi5BcHBs
aWNhdGlvbkluZm9dLCB0byByZWZlciBhCiBqb2IgdGhhdCBkaWRuJ3QgZXhpc3QgaW4gdGhl
IHN5c3RlbSBwcmlvciB0byBiZWNvbWluZyBleHBpcmVkLiBJZiB5b3Ugd2FudAogdG8gbW9k
aWZ5IGEgam9iIHRoYXQgd2FzIGV4cGlyZWQgb24gY3JlYXRpb24sIGRlbGV0ZSBpdCBhbmQg
Y3JlYXRlIGEgbmV3CiBvbmUuCgogSWYgdGhpcyB2YWx1ZSBpc24ndCBwcm92aWRlZCBhdCB0
aGUgdGltZSBvZiBqb2IgY3JlYXRpb24gb3IgaXMgaW52YWxpZCwKIHRoZSBqb2IgcG9zdGlu
ZyBleHBpcmVzIGFmdGVyIDMwIGRheXMgZnJvbSB0aGUgam9iJ3MgY3JlYXRpb24gdGltZS4g
Rm9yCiBleGFtcGxlLCBpZiB0aGUgam9iIHdhcyBjcmVhdGVkIG9uIDIwMTcvMDEvMDEgMTM6
MDBBTSBVVEMgd2l0aCBhbgogdW5zcGVjaWZpZWQgZXhwaXJhdGlvbiBkYXRlLCB0aGUgam9i
IGV4cGlyZXMgYWZ0ZXIgMjAxNy8wMS8zMSAxMzowMEFNIFVUQy4KCiBJZiB0aGlzIHZhbHVl
IGlzbid0IHByb3ZpZGVkIG9uIGpvYiB1cGRhdGUsIGl0IGRlcGVuZHMgb24gdGhlIGZpZWxk
IG1hc2tzCiBzZXQgYnkKIFtVcGRhdGVKb2JSZXF1ZXN0LnVwZGF0ZV9tYXNrXVtnb29nbGUu
Y2xvdWQudGFsZW50LnY0LlVwZGF0ZUpvYlJlcXVlc3QudXBkYXRlX21hc2tdLgogSWYgdGhl
IGZpZWxkIG1hc2tzIGluY2x1ZGUKIFtqb2JfZW5kX3RpbWVdW2dvb2dsZS5jbG91ZC50YWxl
bnQudjQuSm9iLmpvYl9lbmRfdGltZV0sIG9yIHRoZSBtYXNrcyBhcmUKIGVtcHR5IG1lYW5p
bmcgdGhhdCBldmVyeSBmaWVsZCBpcyB1cGRhdGVkLCB0aGUgam9iIHBvc3RpbmcgZXhwaXJl
cyBhZnRlciAzMAogZGF5cyBmcm9tIHRoZSBqb2IncyBsYXN0IHVwZGF0ZSB0aW1lLiBPdGhl
cndpc2UgdGhlIGV4cGlyYXRpb24gZGF0ZSBpc24ndAogdXBkYXRlZC4KCg0KBQQAAhgGEgTr
AgIbCg0KBQQAAhgBEgTrAhwvCg0KBQQAAhgDEgTrAjI0Ck8KBAQAAhkSBu4CAu8CMho/IE91
dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBqb2IgcG9zdGluZyB3YXMgY3Jl
YXRlZC4KCg0KBQQAAhkGEgTuAgIbCg0KBQQAAhkBEgTuAhwvCg0KBQQAAhkDEgTuAjI0Cg0K
BQQAAhkIEgTvAgYxChAKCAQAAhkInAgAEgTvAgcwClQKBAQAAhoSBvICAvMCMhpEIE91dHB1
dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBqb2IgcG9zdGluZyB3YXMgbGFzdCB1
cGRhdGVkLgoKDQoFBAACGgYSBPICAhsKDQoFBAACGgESBPICHC8KDQoFBAACGgMSBPICMjQK
DQoFBAACGggSBPMCBjEKEAoIBAACGgicCAASBPMCBzAKSQoEBAACGxIE9gICTxo7IE91dHB1
dCBvbmx5LiBEaXNwbGF5IG5hbWUgb2YgdGhlIGNvbXBhbnkgbGlzdGluZyB0aGUgam9iLgoK
DQoFBAACGwUSBPYCAggKDQoFBAACGwESBPYCCR0KDQoFBAACGwMSBPYCICIKDQoFBAACGwgS
BPYCI04KEAoIBAACGwicCAASBPYCJE0KQwoEBAACHBIE+QICTBo1IE91dHB1dCBvbmx5LiBE
ZXJpdmVkIGRldGFpbHMgYWJvdXQgdGhlIGpvYiBwb3N0aW5nLgoKDQoFBAACHAYSBPkCAg0K
DQoFBAACHAESBPkCDhoKDQoFBAACHAMSBPkCHR8KDQoFBAACHAgSBPkCIEsKEAoIBAACHAic
CAASBPkCIUoKKwoEBAACHRIE/AICLBodIE9wdGlvbnMgZm9yIGpvYiBwcm9jZXNzaW5nLgoK
DQoFBAACHQYSBPwCAhMKDQoFBAACHQESBPwCFCYKDQoFBAACHQMSBPwCKStiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::Job::Job ===
    # Fields for Job
    # Field: name Type: 9 ()
    # Field: company Type: 9 ()
    # Field: requisition_id Type: 9 ()
    # Field: title Type: 9 ()
    # Field: description Type: 9 ()
    # Field: addresses Type: 9 ()
    # Field: application_info Type: 11 (.google.cloud.talent.v4.Job.ApplicationInfo)
    # Field: job_benefits Type: 14 (.google.cloud.talent.v4.JobBenefit)
    # Field: compensation_info Type: 11 (.google.cloud.talent.v4.CompensationInfo)
    # Field: custom_attributes Type: 11 (.google.cloud.talent.v4.Job.CustomAttributesEntry)
    # Field: degree_types Type: 14 (.google.cloud.talent.v4.DegreeType)
    # Field: department Type: 9 ()
    # Field: employment_types Type: 14 (.google.cloud.talent.v4.EmploymentType)
    # Field: incentives Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: job_level Type: 14 (.google.cloud.talent.v4.JobLevel)
    # Field: promotion_value Type: 5 ()
    # Field: qualifications Type: 9 ()
    # Field: responsibilities Type: 9 ()
    # Field: posting_region Type: 14 (.google.cloud.talent.v4.PostingRegion)
    # Field: visibility Type: 14 (.google.cloud.talent.v4.Visibility)
    # Field: job_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: job_end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_publish_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: company_display_name Type: 9 ()
    # Field: derived_info Type: 11 (.google.cloud.talent.v4.Job.DerivedInfo)
    # Field: processing_options Type: 11 (.google.cloud.talent.v4.Job.ProcessingOptions)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::Job - Compiled Protocol Buffers messages for google/cloud/talent/v4/job.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::Job;

    my $msg = Google::Cloud::Talent::V4::Job::Job->new({
        name => $name,
        company => $company,
        requisition_id => $requisition_id,
        title => $title,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::Job::Job->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/job.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::Job::Job

A Job resource represents a job posting (also referred to as a "job listing"
or "job requisition"). A job belongs to a
[Company][google.cloud.talent.v4.Company], which is the hiring entity
responsible for the job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required during job update.

The resource name for the job. This is generated by the service when a
job is created.

The format is
"projects/{project_id}/tenants/{tenant_id}/jobs/{job_id}". For
example, "projects/foo/tenants/bar/jobs/baz".

Use of this field in job queries and API calls is preferred over the use of
[requisition_id][google.cloud.talent.v4.Job.requisition_id] since this
value is unique.

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<String>

Required. The resource name of the company listing the job.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}". For
example, "projects/foo/tenants/bar/companies/baz".

=item * C<< $msg->requisition_id() >> / C<< $msg->requisition_id($value) >>

Type: C<String>

Required. The requisition ID, also referred to as the posting ID, is
assigned by the client to identify a job. This field is intended to be used
by clients for client identification and tracking of postings. A job isn't
allowed to be created if there is another job with the same
[company][google.cloud.talent.v4.Job.name],
[language_code][google.cloud.talent.v4.Job.language_code] and
[requisition_id][google.cloud.talent.v4.Job.requisition_id].

The maximum number of allowed characters is 255.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Required. The title of the job, such as "Software Engineer"

The maximum number of allowed characters is 500.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. The description of the job, which typically includes a
multi-paragraph description of the company and related information.
Separate fields are provided on the job object for
[responsibilities][google.cloud.talent.v4.Job.responsibilities],
[qualifications][google.cloud.talent.v4.Job.qualifications], and other job
characteristics. Use of these separate job fields is recommended.

This field accepts and sanitizes HTML input, and also accepts
bold, italic, ordered list, and unordered list markup tags.

The maximum number of allowed characters is 100,000.

=item * C<< $msg->addresses() >> / C<< $msg->addresses($value) >>

Type: C<String>

Strongly recommended for the best service experience.

Location(s) where the employer is looking to hire for this job posting.

Specifying the full street address(es) of the hiring location enables
better API results, especially job searches by commute time.

At most 50 locations are allowed for best search performance. If a job has
more locations, it is suggested to split it into multiple jobs with unique
[requisition_id][google.cloud.talent.v4.Job.requisition_id]s (e.g. 'ReqA'
becomes 'ReqA-1', 'ReqA-2', and so on.) as multiple jobs with the same
[company][google.cloud.talent.v4.Job.company],
[language_code][google.cloud.talent.v4.Job.language_code] and
[requisition_id][google.cloud.talent.v4.Job.requisition_id] are not
allowed. If the original
[requisition_id][google.cloud.talent.v4.Job.requisition_id] must be
preserved, a custom field should be used for storage. It is also suggested
to group the locations that close to each other in the same job for better
search experience.

Jobs with multiple addresses must have their addresses with the same
[LocationType][google.cloud.talent.v4.Location.LocationType] to allow
location filtering to work properly. (For example, a Job with addresses
"1600 Amphitheatre Parkway, Mountain View, CA, USA" and "London, UK" may
not have location filters applied correctly at search time since the first
is a
[LocationType.STREET_ADDRESS][google.cloud.talent.v4.Location.LocationType.STREET_ADDRESS]
and the second is a
[LocationType.LOCALITY][google.cloud.talent.v4.Location.LocationType.LOCALITY].)
If a job needs to have multiple addresses, it is suggested to split it into
multiple jobs with same LocationTypes.

The maximum number of allowed characters is 500.

=item * C<< $msg->application_info() >> / C<< $msg->application_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Job::Job::ApplicationInfo>)

Job application information.

=item * C<< $msg->job_benefits() >> / C<< $msg->job_benefits($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::JobBenefit>)

The benefits included with the job.

=item * C<< $msg->compensation_info() >> / C<< $msg->compensation_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Common::CompensationInfo>)

Job compensation information (a.k.a. "pay rate") i.e., the compensation
that will paid to the employee.

=item * C<< $msg->custom_attributes() >> / C<< $msg->custom_attributes($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Job::Job::CustomAttributesEntry>)

A map of fields to hold both filterable and non-filterable custom job
attributes that are not covered by the provided structured fields.

The keys of the map are strings up to 64 bytes and must match the
pattern: `[a-zA-Z][a-zA-Z0-9_]*`. For example, key0LikeThis or
KEY_1_LIKE_THIS.

At most 100 filterable and at most 100 unfilterable keys are supported.
For filterable `string_values`, across all keys at most 200 values are
allowed, with each string no more than 255 characters. For unfilterable
`string_values`, the maximum total size of `string_values` across all keys
is 50KB.

=item * C<< $msg->degree_types() >> / C<< $msg->degree_types($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::DegreeType>)

The desired education degrees for the job, such as Bachelors, Masters.

=item * C<< $msg->department() >> / C<< $msg->department($value) >>

Type: C<String>

The department or functional area within the company with the open
position.

The maximum number of allowed characters is 255.

=item * C<< $msg->employment_types() >> / C<< $msg->employment_types($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::EmploymentType>)

The employment type(s) of a job, for example,
[full time][google.cloud.talent.v4.EmploymentType.FULL_TIME] or
[part time][google.cloud.talent.v4.EmploymentType.PART_TIME].

=item * C<< $msg->incentives() >> / C<< $msg->incentives($value) >>

Type: C<String>

A description of bonus, commission, and other compensation
incentives associated with the job not including salary or pay.

The maximum number of allowed characters is 10,000.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language of the posting. This field is distinct from
any requirements for fluency that are associated with the job.

Language codes must be in BCP-47 format, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47){:
class="external" target="_blank" }.

If this field is unspecified and
[Job.description][google.cloud.talent.v4.Job.description] is present,
detected language code based on
[Job.description][google.cloud.talent.v4.Job.description] is assigned,
otherwise defaults to 'en_US'.

=item * C<< $msg->job_level() >> / C<< $msg->job_level($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::JobLevel>)

The experience level associated with the job, such as "Entry Level".

=item * C<< $msg->promotion_value() >> / C<< $msg->promotion_value($value) >>

Type: C<Int32>

A promotion value of the job, as determined by the client.
The value determines the sort order of the jobs returned when searching for
jobs using the featured jobs search call, with higher promotional values
being returned first and ties being resolved by relevance sort. Only the
jobs with a promotionValue >0 are returned in a FEATURED_JOB_SEARCH.

Default value is 0, and negative values are treated as 0.

=item * C<< $msg->qualifications() >> / C<< $msg->qualifications($value) >>

Type: C<String>

A description of the qualifications required to perform the
job. The use of this field is recommended
as an alternative to using the more general
[description][google.cloud.talent.v4.Job.description] field.

This field accepts and sanitizes HTML input, and also accepts
bold, italic, ordered list, and unordered list markup tags.

The maximum number of allowed characters is 10,000.

=item * C<< $msg->responsibilities() >> / C<< $msg->responsibilities($value) >>

Type: C<String>

A description of job responsibilities. The use of this field is
recommended as an alternative to using the more general
[description][google.cloud.talent.v4.Job.description] field.

This field accepts and sanitizes HTML input, and also accepts
bold, italic, ordered list, and unordered list markup tags.

The maximum number of allowed characters is 10,000.

=item * C<< $msg->posting_region() >> / C<< $msg->posting_region($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::PostingRegion>)

The job [PostingRegion][google.cloud.talent.v4.PostingRegion] (for example,
state, country) throughout which the job is available. If this field is
set, a [LocationFilter][google.cloud.talent.v4.LocationFilter] in a search
query within the job region finds this job posting if an exact location
match isn't specified. If this field is set to
[PostingRegion.NATION][google.cloud.talent.v4.PostingRegion.NATION] or
[PostingRegion.ADMINISTRATIVE_AREA][google.cloud.talent.v4.PostingRegion.ADMINISTRATIVE_AREA],
setting job [Job.addresses][google.cloud.talent.v4.Job.addresses] to the
same location level as this field is strongly recommended.

=item * C<< $msg->visibility() >> / C<< $msg->visibility($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::Visibility>)

Deprecated. The job is only visible to the owner.

The visibility of the job.

Defaults to
[Visibility.ACCOUNT_ONLY][google.cloud.talent.v4.Visibility.ACCOUNT_ONLY]
if not specified.

=item * C<< $msg->job_start_time() >> / C<< $msg->job_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The start timestamp of the job in UTC time zone. Typically this field
is used for contracting engagements. Invalid timestamps are ignored.

=item * C<< $msg->job_end_time() >> / C<< $msg->job_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The end timestamp of the job. Typically this field is used for contracting
engagements. Invalid timestamps are ignored.

=item * C<< $msg->posting_publish_time() >> / C<< $msg->posting_publish_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp this job posting was most recently published. The default
value is the time the request arrives at the server. Invalid timestamps are
ignored.

=item * C<< $msg->posting_expire_time() >> / C<< $msg->posting_expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Strongly recommended for the best service experience.

The expiration timestamp of the job. After this timestamp, the
job is marked as expired, and it no longer appears in search results. The
expired job can't be listed by the
[ListJobs][google.cloud.talent.v4.JobService.ListJobs] API, but it can be
retrieved with the [GetJob][google.cloud.talent.v4.JobService.GetJob] API
or updated with the
[UpdateJob][google.cloud.talent.v4.JobService.UpdateJob] API or deleted
with the [DeleteJob][google.cloud.talent.v4.JobService.DeleteJob] API. An
expired job can be updated and opened again by using a future expiration
timestamp. Updating an expired job fails if there is another existing open
job with same [company][google.cloud.talent.v4.Job.company],
[language_code][google.cloud.talent.v4.Job.language_code] and
[requisition_id][google.cloud.talent.v4.Job.requisition_id].

The expired jobs are retained in our system for 90 days. However, the
overall expired job count cannot exceed 3 times the maximum number of
open jobs over previous 7 days. If this threshold is exceeded,
expired jobs are cleaned out in order of earliest expire time.
Expired jobs are no longer accessible after they are cleaned
out.

Invalid timestamps are ignored, and treated as expire time not provided.

If the timestamp is before the instant request is made, the job
is treated as expired immediately on creation. This kind of job can
not be updated. And when creating a job with past timestamp, the
[posting_publish_time][google.cloud.talent.v4.Job.posting_publish_time]
must be set before
[posting_expire_time][google.cloud.talent.v4.Job.posting_expire_time]. The
purpose of this feature is to allow other objects, such as
[ApplicationInfo][google.cloud.talent.v4.Job.ApplicationInfo], to refer a
job that didn't exist in the system prior to becoming expired. If you want
to modify a job that was expired on creation, delete it and create a new
one.

If this value isn't provided at the time of job creation or is invalid,
the job posting expires after 30 days from the job's creation time. For
example, if the job was created on 2017/01/01 13:00AM UTC with an
unspecified expiration date, the job expires after 2017/01/31 13:00AM UTC.

If this value isn't provided on job update, it depends on the field masks
set by
[UpdateJobRequest.update_mask][google.cloud.talent.v4.UpdateJobRequest.update_mask].
If the field masks include
[job_end_time][google.cloud.talent.v4.Job.job_end_time], or the masks are
empty meaning that every field is updated, the job posting expires after 30
days from the job's last update time. Otherwise the expiration date isn't
updated.

=item * C<< $msg->posting_create_time() >> / C<< $msg->posting_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this job posting was created.

=item * C<< $msg->posting_update_time() >> / C<< $msg->posting_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this job posting was last updated.

=item * C<< $msg->company_display_name() >> / C<< $msg->company_display_name($value) >>

Type: C<String>

Output only. Display name of the company listing the job.

=item * C<< $msg->derived_info() >> / C<< $msg->derived_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Job::Job::DerivedInfo>)

Output only. Derived details about the job posting.

=item * C<< $msg->processing_options() >> / C<< $msg->processing_options($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Job::Job::ProcessingOptions>)

Options for job processing.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::Job::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
