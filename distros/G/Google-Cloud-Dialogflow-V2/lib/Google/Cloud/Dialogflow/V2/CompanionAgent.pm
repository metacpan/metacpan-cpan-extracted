package Google::Cloud::Dialogflow::V2::CompanionAgent;

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
    eval { require Google::Cloud::Dialogflow::V2::CesTool };
    eval { require Google::Cloud::Dialogflow::V2::Toolset };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9jb21wYW5pb25fYWdlbnQucHJvdG8SGmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxopZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zs
b3cvdjIvY2VzX3Rvb2wucHJvdG8aKGdvb2dsZS9jbG91ZC9kaWFsb2dmbG93L3YyL3Rvb2xz
ZXQucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVm
L2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i9AEK
G0NyZWF0ZUNvbXBhbmlvbkFnZW50UmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKhIo
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Db21wYW5pb25BZ2VudFIGcGFyZW50ElgKD2Nv
bXBhbmlvbl9hZ2VudBgCIAEoCzIqLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbXBh
bmlvbkFnZW50QgPgQQJSDmNvbXBhbmlvbkFnZW50EjEKEmNvbXBhbmlvbl9hZ2VudF9pZBgD
IAEoCUID4EEBUhBjb21wYW5pb25BZ2VudElkImAKGEdldENvbXBhbmlvbkFnZW50UmVxdWVz
dBJECgRuYW1lGAEgASgJQjDgQQL6QSoKKGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29t
cGFuaW9uQWdlbnRSBG5hbWUirAEKGkxpc3RDb21wYW5pb25BZ2VudHNSZXF1ZXN0EkgKBnBh
cmVudBgBIAEoCUIw4EEC+kEqEihkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbXBhbmlv
bkFnZW50UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBh
Z2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpwBChtMaXN0Q29tcGFuaW9uQWdlbnRz
UmVzcG9uc2USVQoQY29tcGFuaW9uX2FnZW50cxgBIAMoCzIqLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLkNvbXBhbmlvbkFnZW50Ug9jb21wYW5pb25BZ2VudHMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrkBChtVcGRhdGVDb21wYW5pb25BZ2VudFJl
cXVlc3QSWAoPY29tcGFuaW9uX2FnZW50GAEgASgLMiouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjIuQ29tcGFuaW9uQWdlbnRCA+BBAlIOY29tcGFuaW9uQWdlbnQSQAoLdXBkYXRlX21h
c2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2si
YwobRGVsZXRlQ29tcGFuaW9uQWdlbnRSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgoo
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Db21wYW5pb25BZ2VudFIEbmFtZSK2AwoTR3Vp
ZGFuY2VJbnN0cnVjdGlvbhImCgxkaXNwbGF5X25hbWUYASABKAlCA+BBAVILZGlzcGxheU5h
bWUSLAoPZGlzcGxheV9kZXRhaWxzGAIgASgJQgPgQQFSDmRpc3BsYXlEZXRhaWxzEiEKCWNv
bmRpdGlvbhgDIAEoCUID4EEBUgljb25kaXRpb24SVQoHYWN0aW9ucxgEIAMoCzI2Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLkd1aWRhbmNlSW5zdHJ1Y3Rpb24uQWN0aW9uQgPgQQFS
B2FjdGlvbnMSYQoNdHJpZ2dlcl9ldmVudBgGIAEoDjI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyLkNvbXBhbmlvbkFnZW50LlRyaWdnZXJFdmVudEID4EEBUgx0cmlnZ2VyRXZlbnQS
OwoXZGlzYWJsZV9zdWdnZXN0ZWRfcmVwbHkYByABKAhCA+BBAVIVZGlzYWJsZVN1Z2dlc3Rl
ZFJlcGx5Gi8KBkFjdGlvbhIlCgtkZXNjcmlwdGlvbhgBIAEoCUID4EECUgtkZXNjcmlwdGlv
biLuDQoOQ29tcGFuaW9uQWdlbnQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEkAKC2NyZWF0
ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVU
aW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgp1cGRhdGVUaW1lElEKDXRvb2xzZXRfdG9vbHMYBCADKAsyJy5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5Ub29sc2V0VG9vbEID4EEBUgx0b29sc2V0VG9vbHMSUgoOY2VzX3Rv
b2xfc3BlY3MYBSADKAsyJy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5DZXNUb29sU3Bl
Y0ID4EEBUgxjZXNUb29sU3BlY3MSJgoMZGlzcGxheV9uYW1lGAggASgJQgPgQQFSC2Rpc3Bs
YXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAkgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEmAKDXNraWxs
X2NvbmZpZ3MYByADKAsyNi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db21wYW5pb25B
Z2VudC5Ta2lsbENvbmZpZ0ID4EEBUgxza2lsbENvbmZpZ3MalgQKC1NraWxsQ29uZmlnEnkK
FWd1aWRhbmNlX3NraWxsX2NvbmZpZxgCIAEoCzI+Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyLkNvbXBhbmlvbkFnZW50Lkd1aWRhbmNlU2tpbGxDb25maWdCA+BBAUgAUhNndWlkYW5j
ZVNraWxsQ29uZmlnEoIBChh0cmFuc2xhdGlvbl9za2lsbF9jb25maWcYAyABKAsyQS5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db21wYW5pb25BZ2VudC5UcmFuc2xhdGlvblNraWxs
Q29uZmlnQgPgQQFIAFIWdHJhbnNsYXRpb25Ta2lsbENvbmZpZxKDAQoWc2tpbGxfdHJpZ2dl
cmluZ19ldmVudBgBIAEoDjJILmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbXBhbmlv
bkFnZW50LlNraWxsQ29uZmlnLlNraWxsVHJpZ2dlckV2ZW50QgPgQQFSFHNraWxsVHJpZ2dl
cmluZ0V2ZW50IncKEVNraWxsVHJpZ2dlckV2ZW50EiMKH1NLSUxMX1RSSUdHRVJfRVZFTlRf
VU5TUEVDSUZJRUQQABIUChBFTkRfT0ZfVVRURVJBTkNFEAESFAoQQ1VTVE9NRVJfTUVTU0FH
RRACEhEKDUFHRU5UX01FU1NBR0UQA0IICgZjb25maWcapAIKE0d1aWRhbmNlU2tpbGxDb25m
aWcSaQoVZ3VpZGFuY2VfaW5zdHJ1Y3Rpb25zGAIgAygLMi8uZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjIuR3VpZGFuY2VJbnN0cnVjdGlvbkID4EEBUhRndWlkYW5jZUluc3RydWN0aW9u
cxI2ChRvdmVyYXJjaGluZ19ndWlkYW5jZRgDIAEoCUID4EEBUhNvdmVyYXJjaGluZ0d1aWRh
bmNlEmoKEGtub3dsZWRnZV9zb3VyY2UYBSABKAsyOi5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5Db21wYW5pb25BZ2VudC5Lbm93bGVkZ2VTb3VyY2VCA+BBAVIPa25vd2xlZGdlU291
cmNlGhEKD0tub3dsZWRnZVNvdXJjZRqIAQoWVHJhbnNsYXRpb25Ta2lsbENvbmZpZxIzChNh
Z2VudF9sYW5ndWFnZV9jb2RlGAEgASgJQgPgQQFSEWFnZW50TGFuZ3VhZ2VDb2RlEjkKFmN1
c3RvbWVyX2xhbmd1YWdlX2NvZGUYAiABKAlCA+BBAVIUY3VzdG9tZXJMYW5ndWFnZUNvZGUi
bAoMVHJpZ2dlckV2ZW50Eh0KGVRSSUdHRVJfRVZFTlRfVU5TUEVDSUZJRUQQABIUChBFTkRf
T0ZfVVRURVJBTkNFEAESFAoQQ1VTVE9NRVJfTUVTU0FHRRACEhEKDUFHRU5UX01FU1NBR0UQ
AzqaAepBlgEKKGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29tcGFuaW9uQWdlbnQSSXBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb21wYW5pb25BZ2VudHMv
e2NvbXBhbmlvbl9hZ2VudH0qD2NvbXBhbmlvbkFnZW50czIOY29tcGFuaW9uQWdlbnQytgkK
D0NvbXBhbmlvbkFnZW50cxL1AQoUQ3JlYXRlQ29tcGFuaW9uQWdlbnQSNy5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52Mi5DcmVhdGVDb21wYW5pb25BZ2VudFJlcXVlc3QaKi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5Db21wYW5pb25BZ2VudCJ4gtPkkwJGIjMvdjIve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jb21wYW5pb25BZ2VudHM6D2NvbXBhbmlvbl9h
Z2VudNpBKXBhcmVudCxjb21wYW5pb25fYWdlbnQsY29tcGFuaW9uX2FnZW50X2lkErkBChFH
ZXRDb21wYW5pb25BZ2VudBI0Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkdldENvbXBh
bmlvbkFnZW50UmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbXBhbmlv
bkFnZW50IkKC0+STAjUSMy92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbXBh
bmlvbkFnZW50cy8qfdpBBG5hbWUS9wEKFFVwZGF0ZUNvbXBhbmlvbkFnZW50EjcuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuVXBkYXRlQ29tcGFuaW9uQWdlbnRSZXF1ZXN0GiouZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29tcGFuaW9uQWdlbnQieoLT5JMCVjJDL3YyL3tj
b21wYW5pb25fYWdlbnQubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbXBhbmlvbkFn
ZW50cy8qfToPY29tcGFuaW9uX2FnZW502kEbY29tcGFuaW9uX2FnZW50LHVwZGF0ZV9tYXNr
EqsBChREZWxldGVDb21wYW5pb25BZ2VudBI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
LkRlbGV0ZUNvbXBhbmlvbkFnZW50UmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJC
gtPkkwI1KjMvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb21wYW5pb25BZ2Vu
dHMvKn3aQQRuYW1lEswBChNMaXN0Q29tcGFuaW9uQWdlbnRzEjYuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuTGlzdENvbXBhbmlvbkFnZW50c1JlcXVlc3QaNy5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5MaXN0Q29tcGFuaW9uQWdlbnRzUmVzcG9uc2UiRILT5JMCNRIzL3Yy
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY29tcGFuaW9uQWdlbnRz2kEGcGFy
ZW50GnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2RpYWxvZ2Zsb3dCmQEKHmNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MkIT
Q29tcGFuaW9uQWdlbnRQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cv
YXBpdjIvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIaR29vZ2xlLkNsb3VkLkRp
YWxvZ2Zsb3cuVjJK6VQKBxIFDgDRAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACMKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMS
AxUAIwoJCgIDBBIDFgAzCgkKAgMFEgMXADIKCQoCAwYSAxgAJQoJCgIDBxIDGQAqCgkKAgMI
EgMaACkKCAoBCBIDHAA3CgkKAgglEgMcADcKCAoBCBIDHQBVCgkKAggLEgMdAFUKCAoBCBID
HgAiCgkKAggKEgMeACIKCAoBCBIDHwA0CgkKAggIEgMfADQKCAoBCBIDIAA3CgkKAggBEgMg
ADcKCAoBCBIDIQAgCgkKAggkEgMhACAKNAoCBgASBCQAWAEaKCBTZXJ2aWNlIGZvciBtYW5h
Z2luZyBjb21wYW5pb24gYWdlbnRzLgoKCgoDBgABEgMkCBcKCgoDBgADEgMlAkEKDAoFBgAD
mQgSAyUCQQoLCgMGAAMSBCYCKDMKDQoFBgADmggSBCYCKDMKKgoEBgACABIEKwIzAxocIENy
ZWF0ZXMgYSBjb21wYW5pb24gYWdlbnQuCgoMCgUGAAIAARIDKwYaCgwKBQYAAgACEgMrGzYK
DAoFBgACAAMSAywPHQoNCgUGAAIABBIELQQwBgoRCgkGAAIABLDKvCISBC0EMAYKDQoFBgAC
AAQSBDEEMjQKEAoIBgACAASbCAASBDEEMjQKJwoEBgACARIENgI7AxoZIEdldHMgYSBjb21w
YW5pb24gYWdlbnQuCgoMCgUGAAIBARIDNgYXCgwKBQYAAgECEgM2GDAKDAoFBgACAQMSAzY7
SQoNCgUGAAIBBBIENwQ5BgoRCgkGAAIBBLDKvCISBDcEOQYKDAoFBgACAQQSAzoEMgoPCggG
AAIBBJsIABIDOgQyCioKBAYAAgISBD4CRQMaHCBVcGRhdGVzIGEgY29tcGFuaW9uIGFnZW50
LgoKDAoFBgACAgESAz4GGgoMCgUGAAICAhIDPhs2CgwKBQYAAgIDEgM/Dx0KDQoFBgACAgQS
BEAEQwYKEQoJBgACAgSwyrwiEgRABEMGCgwKBQYAAgIEEgNEBEkKDwoIBgACAgSbCAASA0QE
SQoqCgQGAAIDEgRIAk4DGhwgRGVsZXRlcyBhIGNvbXBhbmlvbiBhZ2VudC4KCgwKBQYAAgMB
EgNIBhoKDAoFBgACAwISA0gbNgoMCgUGAAIDAxIDSQ8kCg0KBQYAAgMEEgRKBEwGChEKCQYA
AgMEsMq8IhIESgRMBgoMCgUGAAIDBBIDTQQyCg8KCAYAAgMEmwgAEgNNBDIKJwoEBgACBBIE
UQJXAxoZIExpc3RzIGNvbXBhbmlvbiBhZ2VudHMuCgoMCgUGAAIEARIDUQYZCgwKBQYAAgQC
EgNRGjQKDAoFBgACBAMSA1IPKgoNCgUGAAIEBBIEUwRVBgoRCgkGAAIEBLDKvCISBFMEVQYK
DAoFBgACBAQSA1YENAoPCggGAAIEBJsIABIDVgQ0Ci4KAgQAEgRbAGsBGiIgUmVxdWVzdCBv
ZiBDcmVhdGVDb21wYW5pb25BZ2VudC4KCgoKAwQAARIDWwgjCo0BCgQEAAIAEgReAmMEGn8g
UmVxdWlyZWQuIFJlc291cmNlIGlkZW50aWZpZXIgb2YgdGhlIHByb2plY3QgY3JlYXRpbmcg
dGhlIGNvbXBhbmlvbiBhZ2VudC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufWAKCgwKBQQAAgAFEgNeAggKDAoFBAACAAESA14JDwoMCgUEAAIA
AxIDXhITCg0KBQQAAgAIEgReFGMDCg8KCAQAAgAInAgAEgNfBCoKDwoHBAACAAifCBIEYARi
BQo3CgQEAAIBEgNmAk4aKiBSZXF1aXJlZC4gVGhlIGNvbXBhbmlvbiBhZ2VudCB0byBjcmVh
dGUuCgoMCgUEAAIBBhIDZgIQCgwKBQQAAgEBEgNmESAKDAoFBAACAQMSA2YjJAoMCgUEAAIB
CBIDZiVNCg8KCAQAAgEInAgAEgNmJkwKiQEKBAQAAgISA2oCSRp8IE9wdGlvbmFsLiBUaGUg
cmVzb3VyY2UgSUQgb2YgdGhlIGNvbXBhbmlvbiBhZ2VudCB0byBjcmVhdGUuIElmIG5vdAog
cHJvdmlkZWQsIHRoZSBzZXJ2ZXIgd2lsbCBhdXRvLWdlbmVyYXRlIGEgcmVzb3VyY2UgSUQu
CgoMCgUEAAICBRIDagIICgwKBQQAAgIBEgNqCRsKDAoFBAACAgMSA2oeHwoMCgUEAAICCBID
aiBICg8KCAQAAgIInAgAEgNqIUcKNAoCBAESBG4AegEaKCBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IEdldENvbXBhbmlvbkFnZW50LgoKCgoDBAEBEgNuCCAKlQIKBAQBAgASBHQCeQQahgIgUmVx
dWlyZWQuIFRoZSB1bmlxdWUgcmVzb3VyY2UgaWRlbnRpZmllciBvZiB0aGUgQ29tcGFuaW9u
QWdlbnQgdG8gZ2V0IGFsbAogaW5mb3JtYXRpb24gZm9yLiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbXBhbmlvbkFnZW50cy97Y29tcGFu
aW9uX2FnZW50fWAuCiBDb250YWlucyB0aGUgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHtwcm9q
ZWN0fSwge2xvY2F0aW9ufSwgYW5kCiB7Y29tcGFuaW9uX2FnZW50fS4KCgwKBQQBAgAFEgN0
AggKDAoFBAECAAESA3QJDQoMCgUEAQIAAxIDdBARCg0KBQQBAgAIEgR0EnkDCg8KCAQBAgAI
nAgAEgN1BCoKDwoHBAECAAifCBIEdgR4BQo3CgIEAhIFfQCNAQEaKiBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIExpc3RDb21wYW5pb25BZ2VudHMuCgoKCgMEAgESA30IIgqJAQoEBAICABIGgAEC
hQEEGnkgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSB0byBsaXN0IHRoZSBj
b21wYW5pb24gYWdlbnRzIGZvci4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufWAKCg0KBQQCAgAFEgSAAQIICg0KBQQCAgABEgSAAQkPCg0KBQQC
AgADEgSAARITCg8KBQQCAgAIEgaAARSFAQMKEAoIBAICAAicCAASBIEBBCoKEQoHBAICAAif
CBIGggEEhAEFCnoKBAQCAgESBIkBAj8abCBPcHRpb25hbC4gTWF4aW11bSBudW1iZXIgb2Yg
Y29tcGFuaW9uIGFnZW50cyB0byByZXR1cm4gaW4gYSBzaW5nbGUgcGFnZS4KIEJ5IGRlZmF1
bHQgMTAwIGFuZCBhdCBtb3N0IDEwMDAuCgoNCgUEAgIBBRIEiQECBwoNCgUEAgIBARIEiQEI
EQoNCgUEAgIBAxIEiQEUFQoNCgUEAgIBCBIEiQEWPgoQCggEAgIBCJwIABIEiQEXPQpICgQE
AgICEgSMAQJBGjogT3B0aW9uYWwuIFRoZSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEg
cHJldmlvdXMgY2FsbC4KCg0KBQQCAgIFEgSMAQIICg0KBQQCAgIBEgSMAQkTCg0KBQQCAgID
EgSMARYXCg0KBQQCAgIIEgSMARhAChAKCAQCAgIInAgAEgSMARk/CjkKAgQDEgaQAQCXAQEa
KyBSZXNwb25zZSBtZXNzYWdlIGZvciBMaXN0Q29tcGFuaW9uQWdlbnRzLgoKCwoDBAMBEgSQ
AQgjCi0KBAQDAgASBJIBAi8aHyBUaGUgbGlzdCBvZiBjb21wYW5pb24gYWdlbnRzLgoKDQoF
BAMCAAQSBJIBAgoKDQoFBAMCAAYSBJIBCxkKDQoFBAMCAAESBJIBGioKDQoFBAMCAAMSBJIB
LS4KbwoEBAMCARIElgECHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2Yg
cmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3JlIHJlc3VsdHMgaW4gdGhl
IGxpc3QuCgoNCgUEAwIBBRIElgECCAoNCgUEAwIBARIElgEJGAoNCgUEAwIBAxIElgEbHAo5
CgIEBBIGmgEAoQEBGisgUmVxdWVzdCBtZXNzYWdlIGZvciBVcGRhdGVDb21wYW5pb25BZ2Vu
dC4KCgsKAwQEARIEmgEIIwo4CgQEBAIAEgScAQJOGiogUmVxdWlyZWQuIFRoZSBDb21wYW5p
b24gQWdlbnQgdG8gdXBkYXRlLgoKDQoFBAQCAAYSBJwBAhAKDQoFBAQCAAESBJwBESAKDQoF
BAQCAAMSBJwBIyQKDQoFBAQCAAgSBJwBJU0KEAoIBAQCAAicCAASBJwBJkwKPAoEBAQCARIG
nwECoAEvGiwgT3B0aW9uYWwuIFVwZGF0ZSBtYXNrIGZvciBDb21wYW5pb24gQWdlbnQuCgoN
CgUEBAIBBhIEnwECGwoNCgUEBAIBARIEnwEcJwoNCgUEBAIBAxIEnwEqKwoNCgUEBAIBCBIE
oAEGLgoQCggEBAIBCJwIABIEoAEHLQo5CgIEBRIGpAEArgEBGisgUmVxdWVzdCBtZXNzYWdl
IGZvciBEZWxldGVDb21wYW5pb25BZ2VudC4KCgsKAwQFARIEpAEIIwqzAQoEBAUCABIGqAEC
rQEEGqIBIFJlcXVpcmVkLiBUaGUgdW5pcXVlIHJlc291cmNlIGlkZW50aWZpZXIgb2YgdGhl
IENvbXBhbmlvbkFnZW50IHRvIGRlbGV0ZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29tcGFuaW9uQWdlbnRzL3tjb21wYW5pb25fYWdl
bnR9YC4KCg0KBQQFAgAFEgSoAQIICg0KBQQFAgABEgSoAQkNCg0KBQQFAgADEgSoARARCg8K
BQQFAgAIEgaoARKtAQMKEAoIBAUCAAicCAASBKkBBCoKEQoHBAUCAAifCBIGqgEErAEFCj0K
AgQGEgaxAQDUAQEaLyBHdWlkYW5jZSBpbnN0cnVjdGlvbiBmb3IgdGhlIGNvbXBhbmlvbiBh
Z2VudC4KCgsKAwQGARIEsQEIGwpZCgQEBgMAEgazAQK4AQMaSSBBY3Rpb25zIHRvIHRha2Us
IGluY2x1ZGluZyBhZ2VudCBhY3Rpb24gYW5kIHN5c3RlbSBhY3Rpb24gKGF1dG9tYXRpb24p
LgoKDQoFBAYDAAESBLMBChAK4wEKBgQGAwACABIEtwEERBrSASBSZXF1aXJlZC4gRGVzY3Jp
cHRpb24gb2YgYWN0aW9uIGl0ZW0uIEl0IGNhbiBiZSBhIGFnZW50IGFjdGlvbiAoZS5nLgog
IlNlbmQgYSBtZXNzYWdlIHRvIHRoZSBjdXN0b21lciIsICJncmVldCB0aGUgY3VzdG9tZXIi
KSBvciBzeXN0ZW0gYWN0aW9uCiAoZS5nLiAiVXBkYXRlIHRoZSB0aWNrZXQiLCAiQ3JlYXRl
IGEgdGFzayIsICJjYW5jZWwgdGhlIG9yZGVyIikuCgoPCgcEBgMAAgAFEgS3AQQKCg8KBwQG
AwACAAESBLcBCxYKDwoHBAYDAAIAAxIEtwEZGgoPCgcEBgMAAgAIEgS3ARtDChIKCgQGAwAC
AAicCAASBLcBHEIKcwoEBAYCABIEvAECQxplIE9wdGlvbmFsLiBEaXNwbGF5IG5hbWUgZm9y
IHRoZSBpbnN0cnVjdGlvbi4gVGhpcyBuYW1lIHNob3VsZCBiZSB1bmlxdWUKIHdpdGhpbiB0
aGUgY29tcGFuaW9uIGFnZW50LgoKDQoFBAYCAAUSBLwBAggKDQoFBAYCAAESBLwBCRUKDQoF
BAYCAAMSBLwBGBkKDQoFBAYCAAgSBLwBGkIKEAoIBAYCAAicCAASBLwBG0EKRwoEBAYCARIE
vwECRho5IE9wdGlvbmFsLiBUaGUgZGV0YWlsZWQgZGVzY3JpcHRpb24gb2YgdGhpcyBpbnN0
cnVjdGlvbi4KCg0KBQQGAgEFEgS/AQIICg0KBQQGAgEBEgS/AQkYCg0KBQQGAgEDEgS/ARsc
Cg0KBQQGAgEIEgS/AR1FChAKCAQGAgEInAgAEgS/AR5ECtQBCgQEBgICEgTEAQJAGsUBIE9w
dGlvbmFsLiBUaGUgY29uZGl0aW9uIG9mIHRoZSBpbnN0cnVjdGlvbi4gRm9yIGV4YW1wbGUs
ICJ0aGUgY3VzdG9tZXIKIHdhbnRzIHRvIGNhbmNlbCBhbiBvcmRlciIuICBJZiB0aGUgdXNl
cnMgd2FudCB0aGUgaW5zdHJ1Y3Rpb24gdG8gYmUKIHRyaWdnZXJlZCB1bmNvbmRpdGlvbmFs
bHksIHRoZSBjb25kaXRpb24gY2FuIGJlIGVtcHR5LgoKDQoFBAYCAgUSBMQBAggKDQoFBAYC
AgESBMQBCRIKDQoFBAYCAgMSBMQBFRYKDQoFBAYCAggSBMQBFz8KEAoIBAYCAgicCAASBMQB
GD4KQQoEBAYCAxIExwECRxozIE9wdGlvbmFsLiBUaGUgYWN0aW9uIGl0ZW1zIHRoYXQgY2Fu
IGJlIHByb2Nlc3NlZC4KCg0KBQQGAgMEEgTHAQIKCg0KBQQGAgMGEgTHAQsRCg0KBQQGAgMB
EgTHARIZCg0KBQQGAgMDEgTHARwdCg0KBQQGAgMIEgTHAR5GChAKCAQGAgMInAgAEgTHAR9F
Cq8BCgQEBgIEEgbMAQLNAS8angEgT3B0aW9uYWwuIEV2ZW50IHRoYXQgdHJpZ2dlcnMgdGhl
IGd1aWRhbmNlIGluc3RydWN0aW9uLgogSWYgVU5TUEVDSUZJRUQsIHRoZSBpbnN0cnVjdGlv
biB0cmlnZ2VyaW5nIHdpbGwgYmUgdGhlIHNhbWUgYXMgdGhlIHNraWxsJ3MKIHNraWxsX3Ry
aWdnZXJpbmdfZXZlbnQuCgoNCgUEBgIEBhIEzAECHQoNCgUEBgIEARIEzAEeKwoNCgUEBgIE
AxIEzAEuLwoNCgUEBgIECBIEzQEGLgoQCggEBgIECJwIABIEzQEHLQrwAQoEBAYCBRIE0wEC
TBrhASBPcHRpb25hbC4gV2hldGhlciB0byBkaXNhYmxlIHN1Z2dlc3RlZCByZXBseSBnZW5l
cmF0aW9uIGZvciB0aGlzCiBpbnN0cnVjdGlvbi4gV2hlbiBzZXQgdG8gYHRydWVgLCBndWlk
YW5jZSBnZW5lcmF0ZWQgZnJvbSB0aGlzIGluc3RydWN0aW9uCiB3aWxsIG5vdCBpbmNsdWRl
IGEgc3VnZ2VzdGVkIHJlcGx5LiBEZWZhdWx0IGlzIGBmYWxzZWAgKHN1Z2dlc3RlZCByZXBs
eQogZW5hYmxlZCkuCgoNCgUEBgIFBRIE0wECBgoNCgUEBgIFARIE0wEHHgoNCgUEBgIFAxIE
0wEhIgoNCgUEBgIFCBIE0wEjSwoQCggEBgIFCJwIABIE0wEkSgogCgIEBxIG1wEA0QIBGhIg
Q29tcGFuaW9uIGFnZW50LgoKCwoDBAcBEgTXAQgWCg0KAwQHBxIG2AEC3QEECg8KBQQHB50I
EgbYAQLdAQQKVwoEBAcEABIG4AEC7wEDGkcgRXZlbnQgdGhhdCB0cmlnZ2VycyBjb21wYW5p
b24gYWdlbnQgc2tpbGxzIGFuZCBndWlkYW5jZSBpbnN0cnVjdGlvbnMuCgoNCgUEBwQAARIE
4AEHEwrWAQoGBAcEAAIAEgTlAQQiGsUBIERlZmF1bHQgdmFsdWUgZm9yIFRyaWdnZXJFdmVu
dC4KIEZvciBza2lsbF90cmlnZ2VyaW5nX2V2ZW50LCBVTlNQRUNJRklFRCBkZWZhdWx0cyB0
byBDVVNUT01FUl9NRVNTQUdFLgogRm9yIGluc3RydWN0aW9uIHRyaWdnZXJfZXZlbnQsIFVO
U1BFQ0lGSUVEIGRlZmF1bHRzIHRvIHRoZSBza2lsbCdzCiBza2lsbF90cmlnZ2VyaW5nX2V2
ZW50LgoKDwoHBAcEAAIAARIE5QEEHQoPCgcEBwQAAgACEgTlASAhCkoKBgQHBAACARIE6AEE
GRo6IFRyaWdnZXJzIHdoZW4gZWFjaCBjaGF0IG1lc3NhZ2Ugb3Igdm9pY2UgdXR0ZXJhbmNl
IGVuZHMuCgoPCgcEBwQAAgEBEgToAQQUCg8KBwQHBAACAQISBOgBFxgKNwoGBAcEAAICEgTr
AQQZGicgVHJpZ2dlcnMgYWZ0ZXIgZWFjaCBjdXN0b21lciBtZXNzYWdlLgoKDwoHBAcEAAIC
ARIE6wEEFAoPCgcEBwQAAgICEgTrARcYCjQKBgQHBAACAxIE7gEEFhokIFRyaWdnZXJzIGFm
dGVyIGVhY2ggYWdlbnQgbWVzc2FnZS4KCg8KBwQHBAACAwESBO4BBBEKDwoHBAcEAAIDAhIE
7gEUFQo+CgQEBwMAEgbyAQKQAgMaLiBTa2lsbCBjb25maWd1cmF0aW9uIGZvciB0aGUgY29t
cGFuaW9uIGFnZW50LgoKDQoFBAcDAAESBPIBChUKPAoGBAcDAAQAEgb0AQSAAgUaKiBUaGUg
ZXZlbnQgdGhhdCBzaG91bGQgdHJpZ2dlciB0aGUgc2tpbGwuCgoPCgcEBwMABAABEgT0AQka
CjgKCAQHAwAEAAIAEgT2AQYqGiYgRGVmYXVsdCB2YWx1ZSBmb3IgU2tpbGxUcmlnZ2VyRXZl
bnQuCgoRCgkEBwMABAACAAESBPYBBiUKEQoJBAcDAAQAAgACEgT2ASgpCkwKCAQHAwAEAAIB
EgT5AQYbGjogVHJpZ2dlcnMgd2hlbiBlYWNoIGNoYXQgbWVzc2FnZSBvciB2b2ljZSB1dHRl
cmFuY2UgZW5kcy4KChEKCQQHAwAEAAIBARIE+QEGFgoRCgkEBwMABAACAQISBPkBGRoKOQoI
BAcDAAQAAgISBPwBBhsaJyBUcmlnZ2VycyBhZnRlciBlYWNoIGN1c3RvbWVyIG1lc3NhZ2Uu
CgoRCgkEBwMABAACAgESBPwBBhYKEQoJBAcDAAQAAgICEgT8ARkaCjYKCAQHAwAEAAIDEgT/
AQYYGiQgVHJpZ2dlcnMgYWZ0ZXIgZWFjaCBhZ2VudCBtZXNzYWdlLgoKEQoJBAcDAAQAAgMB
EgT/AQYTChEKCQQHAwAEAAIDAhIE/wEWFwpZCgYEBwMACAASBoMCBIsCBRpHIEVhY2ggU2tp
bGxDb25maWcgd2lsbCBiZSBvbmUgb2YgdGhlIGZvbGxvd2luZyBzcGVjaWZpYyBza2lsbCBj
b25maWdzLgoKDwoHBAcDAAgAARIEgwIKEAo7CgYEBwMAAgASBoUCBoYCMxopIE9wdGlvbmFs
LiBHdWlkYW5jZSBza2lsbCBjb25maWd1cmF0aW9uLgoKDwoHBAcDAAIABhIEhQIGGQoPCgcE
BwMAAgABEgSFAhovCg8KBwQHAwACAAMSBIUCMjMKDwoHBAcDAAIACBIEhgIKMgoSCgoEBwMA
AgAInAgAEgSGAgsxCj4KBgQHAwACARIGiQIGigIzGiwgT3B0aW9uYWwuIFRyYW5zbGF0aW9u
IHNraWxsIGNvbmZpZ3VyYXRpb24uCgoPCgcEBwMAAgEGEgSJAgYcCg8KBwQHAwACAQESBIkC
HTUKDwoHBAcDAAIBAxIEiQI4OQoPCgcEBwMAAgEIEgSKAgoyChIKCgQHAwACAQicCAASBIoC
CzEKRgoGBAcDAAICEgaOAgSPAjEaNCBPcHRpb25hbC4gVGhlIGV2ZW50IHRoYXQgc2hvdWxk
IHRyaWdnZXIgdGhlIHNraWxsLgoKDwoHBAcDAAICBhIEjgIEFQoPCgcEBwMAAgIBEgSOAhYs
Cg8KBwQHAwACAgMSBI4CLzAKDwoHBAcDAAICCBIEjwIIMAoSCgoEBwMAAgIInAgAEgSPAgkv
Ci8KBAQHAwESBpMCAp8CAxofIEd1aWRhbmNlIHNraWxsIGNvbmZpZ3VyYXRpb24uCgoNCgUE
BwMBARIEkwIKHQpDCgYEBwMBAgASBpUCBJYCMRoxIE9wdGlvbmFsLiBDdXN0b21pemVkIGlu
c3RydWN0aW9ucyBmb3IgZ3VpZGFuY2UuCgoPCgcEBwMBAgAEEgSVAgQMCg8KBwQHAwECAAYS
BJUCDSAKDwoHBAcDAQIAARIElQIhNgoPCgcEBwMBAgADEgSVAjk6Cg8KBwQHAwECAAgSBJYC
CDAKEgoKBAcDAQIACJwIABIElgIJLwpiCgYEBwMBAgESBJoCBE0aUiBPcHRpb25hbC4gVGhp
cyBpcyBzcGVjaWZpYyBhZGRpdGlvbmFsIGd1aWRhbmNlIHRoYXQgY2FuIGNvbmZpZ3VyZWQg
YnkgdGhlCiB1c2VyLgoKDwoHBAcDAQIBBRIEmgIECgoPCgcEBwMBAgEBEgSaAgsfCg8KBwQH
AwECAQMSBJoCIiMKDwoHBAcDAQIBCBIEmgIkTAoSCgoEBwMBAgEInAgAEgSaAiVLCkoKBgQH
AwECAhIGnQIEngIxGjggT3B0aW9uYWwuIEtub3dsZWRnZSBzb3VyY2UgY29uZmlndXJhdGlv
biBmb3IgZ3VpZGFuY2UuCgoPCgcEBwMBAgIGEgSdAgQTCg8KBwQHAwECAgESBJ0CFCQKDwoH
BAcDAQICAxIEnQInKAoPCgcEBwMBAgIIEgSeAggwChIKCgQHAwECAgicCAASBJ4CCS8KRwoE
BAcDAhIEogICHBo5IEtub3dsZWRnZSBzb3VyY2UgY29uZmlndXJhdGlvbiBmb3Iga25vd2xl
ZGdlIHJldHJpZXZhbC4KCg0KBQQHAwIBEgSiAgoZCkoKBAQHAwMSBqUCAq0CAxo6IFRyYW5z
bGF0aW9uIHNraWxsIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSBjb21wYW5pb24gYWdlbnQuCgoN
CgUEBwMDARIEpQIKIApnCgYEBwMDAgASBKgCBEwaVyBPcHRpb25hbC4gVGFyZ2V0IGxhbmd1
YWdlIGNvZGUgZm9yIHRoZSBhZ2VudCwgaW4gSUVURiBCQ1AtNDcgZm9ybWF0CiAoZS5nLiwg
ImVuLVVTIikuCgoPCgcEBwMDAgAFEgSoAgQKCg8KBwQHAwMCAAESBKgCCx4KDwoHBAcDAwIA
AxIEqAIhIgoPCgcEBwMDAgAIEgSoAiNLChIKCgQHAwMCAAicCAASBKgCJEoKZwoGBAcDAwIB
EgSsAgRPGlcgT3B0aW9uYWwuIFRhcmdldCBsYW5ndWFnZSBjb2RlIGZvciB0aGUgY3VzdG9t
ZXIsIGluIElFVEYgQkNQLTQ3IGZvcm1hdAogKGUuZy4sICJlcyIpLgoKDwoHBAcDAwIBBRIE
rAIECgoPCgcEBwMDAgEBEgSsAgshCg8KBwQHAwMCAQMSBKwCJCUKDwoHBAcDAwIBCBIErAIm
TgoSCgoEBwMDAgEInAgAEgSsAidNCqABCgQEBwIAEgSyAgI9GpEBIElkZW50aWZpZXIuIFRo
ZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgY29tcGFuaW9uIGFnZW50LgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb21wYW5pb25BZ2Vu
dHMve2NvbXBhbmlvbl9hZ2VudH1gCgoNCgUEBwIABRIEsgICCAoNCgUEBwIAARIEsgIJDQoN
CgUEBwIAAxIEsgIQEQoNCgUEBwIACBIEsgISPAoQCggEBwIACJwIABIEsgITOwpFCgQEBwIB
Ega1AgK2AjIaNSBPdXRwdXQgb25seS4gQ3JlYXRpb24gdGltZSBvZiB0aGlzIGNvbXBhbmlv
biBhZ2VudC4KCg0KBQQHAgEGEgS1AgIbCg0KBQQHAgEBEgS1AhwnCg0KBQQHAgEDEgS1Aior
Cg0KBQQHAgEIEgS2AgYxChAKCAQHAgEInAgAEgS2AgcwCkMKBAQHAgISBrkCAroCMhozIE91
dHB1dCBvbmx5LiBVcGRhdGUgdGltZSBvZiB0aGlzIGNvbXBhbmlvbiBhZ2VudC4KCg0KBQQH
AgIGEgS5AgIbCg0KBQQHAgIBEgS5AhwnCg0KBQQHAgIDEgS5AiorCg0KBQQHAgIIEgS6AgYx
ChAKCAQHAgIInAgAEgS6AgcwCmAKBAQHAgMSBr4CAr8CLxpQIE9wdGlvbmFsLiBMaXN0IG9m
IENFUyB0b29sc2V0IHNwZWNzIHRoYXQgdGhlIGNvbXBhbmlvbiBhZ2VudCBjYW4gY2hvb3Nl
CiBmcm9tLgoKDQoFBAcCAwQSBL4CAgoKDQoFBAcCAwYSBL4CCxYKDQoFBAcCAwESBL4CFyQK
DQoFBAcCAwMSBL4CJygKDQoFBAcCAwgSBL8CBi4KEAoIBAcCAwicCAASBL8CBy0KXAoEBAcC
BBIGwgICwwIvGkwgT3B0aW9uYWwuIExpc3Qgb2YgQ0VTIHRvb2wgc3BlY3MgdGhhdCB0aGUg
Y29tcGFuaW9uIGFnZW50IGNhbiBjaG9vc2UgZnJvbS4KCg0KBQQHAgQEEgTCAgIKCg0KBQQH
AgQGEgTCAgsWCg0KBQQHAgQBEgTCAhclCg0KBQQHAgQDEgTCAigpCg0KBQQHAgQIEgTDAgYu
ChAKCAQHAgQInAgAEgTDAgctClcKBAQHAgUSBMcCAkMaSSBPcHRpb25hbC4gRGlzcGxheSBu
YW1lIGZvciB0aGUgY29tcGFuaW9uIGFnZW50LgogQ2hhcmFjdGVyIGxpbWl0IGlzIDYzLgoK
DQoFBAcCBQUSBMcCAggKDQoFBAcCBQESBMcCCRUKDQoFBAcCBQMSBMcCGBkKDQoFBAcCBQgS
BMcCGkIKEAoIBAcCBQicCAASBMcCG0EKPgoEBAcCBhIEygICQhowIE9wdGlvbmFsLiBEZXNj
cmlwdGlvbiBmb3IgdGhlIGNvbXBhbmlvbiBhZ2VudC4KCg0KBQQHAgYFEgTKAgIICg0KBQQH
AgYBEgTKAgkUCg0KBQQHAgYDEgTKAhcYCg0KBQQHAgYIEgTKAhlBChAKCAQHAgYInAgAEgTK
AhpACrwBCgQEBwIHEgbPAgLQAi8aqwEgT3B0aW9uYWwuIExpc3Qgb2Ygc2tpbGwgY29uZmln
cyBmb3IgdGhlIGNvbXBhbmlvbiBhZ2VudC4KIEFsbG93cyBhdCBtb3N0IG9uZSBpbnN0YW5j
ZSBvZiBlYWNoCiBbU2tpbGxDb25maWddW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNv
bXBhbmlvbkFnZW50LlNraWxsQ29uZmlnXSB0eXBlLgoKDQoFBAcCBwQSBM8CAgoKDQoFBAcC
BwYSBM8CCxYKDQoFBAcCBwESBM8CFyQKDQoFBAcCBwMSBM8CJygKDQoFBAcCBwgSBNACBi4K
EAoIBAcCBwicCAASBNACBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest ===
    # Fields for CreateCompanionAgentRequest
    # Field: parent Type: 9 ()
    # Field: companion_agent Type: 11 (.google.cloud.dialogflow.v2.CompanionAgent)
    # Field: companion_agent_id Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::GetCompanionAgentRequest ===
    # Fields for GetCompanionAgentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsRequest ===
    # Fields for ListCompanionAgentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsResponse ===
    # Fields for ListCompanionAgentsResponse
    # Field: companion_agents Type: 11 (.google.cloud.dialogflow.v2.CompanionAgent)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::UpdateCompanionAgentRequest ===
    # Fields for UpdateCompanionAgentRequest
    # Field: companion_agent Type: 11 (.google.cloud.dialogflow.v2.CompanionAgent)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::DeleteCompanionAgentRequest ===
    # Fields for DeleteCompanionAgentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction ===
    # Fields for GuidanceInstruction
    # Field: display_name Type: 9 ()
    # Field: display_details Type: 9 ()
    # Field: condition Type: 9 ()
    # Field: actions Type: 11 (.google.cloud.dialogflow.v2.GuidanceInstruction.Action)
    # Field: trigger_event Type: 14 (.google.cloud.dialogflow.v2.CompanionAgent.TriggerEvent)
    # Field: disable_suggested_reply Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent ===
    # Fields for CompanionAgent
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: toolset_tools Type: 11 (.google.cloud.dialogflow.v2.ToolsetTool)
    # Field: ces_tool_specs Type: 11 (.google.cloud.dialogflow.v2.CesToolSpec)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: skill_configs Type: 11 (.google.cloud.dialogflow.v2.CompanionAgent.SkillConfig)

# Enum: CompanionAgent::TriggerEvent
our $CompanionAgent_TRIGGER_EVENT_UNSPECIFIED = 0;
our $CompanionAgent_END_OF_UTTERANCE = 1;
our $CompanionAgent_CUSTOMER_MESSAGE = 2;
our $CompanionAgent_AGENT_MESSAGE = 3;

# === Service Client: Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgentsClient ===
package Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgentsClient

Client stub representing the remote C<CompanionAgents> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.CompanionAgents',
        method         => 'CreateCompanionAgent',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent',
    });
}

sub get_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::CompanionAgent::GetCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.CompanionAgents',
        method         => 'GetCompanionAgent',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent',
    });
}

sub update_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::CompanionAgent::UpdateCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.CompanionAgents',
        method         => 'UpdateCompanionAgent',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent',
    });
}

sub delete_companion_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::CompanionAgent::DeleteCompanionAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.CompanionAgents',
        method         => 'DeleteCompanionAgent',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_companion_agents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.CompanionAgents',
        method         => 'ListCompanionAgents',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::CompanionAgent - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/companion_agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::CompanionAgent;

    my $msg = Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest->new({
        parent => $parent,
        companion_agent => $companion_agent,
        companion_agent_id => $companion_agent_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/companion_agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest

Request of CreateCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource identifier of the project creating the companion agent.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->companion_agent() >> / C<< $msg->companion_agent($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent>)

Required. The companion agent to create.

=item * C<< $msg->companion_agent_id() >> / C<< $msg->companion_agent_id($value) >>

Type: C<String>

Optional. The resource ID of the companion agent to create. If not
provided, the server will auto-generate a resource ID.

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::GetCompanionAgentRequest

Request message for GetCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique resource identifier of the CompanionAgent to get all
information for. Format:
`projects/{project}/locations/{location}/companionAgents/{companion_agent}`.
Contains the information about the {project}, {location}, and
{companion_agent}.

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsRequest

Request message for ListCompanionAgents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name to list the companion agents for.
Format: `projects/{project}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of companion agents to return in a single page.
By default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The page token, received from a previous call.

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsResponse

Response message for ListCompanionAgents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->companion_agents() >> / C<< $msg->companion_agents($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent>)

The list of companion agents.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::UpdateCompanionAgentRequest

Request message for UpdateCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->companion_agent() >> / C<< $msg->companion_agent($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent>)

Required. The Companion Agent to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Update mask for Companion Agent.

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::DeleteCompanionAgentRequest

Request message for DeleteCompanionAgent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique resource identifier of the CompanionAgent to delete.
Format:
`projects/{project}/locations/{location}/companionAgents/{companion_agent}`.

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction

Guidance instruction for the companion agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name for the instruction. This name should be unique
within the companion agent.

=item * C<< $msg->display_details() >> / C<< $msg->display_details($value) >>

Type: C<String>

Optional. The detailed description of this instruction.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Optional. The condition of the instruction. For example, "the customer
wants to cancel an order".  If the users want the instruction to be
triggered unconditionally, the condition can be empty.

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction::Action>)

Optional. The action items that can be processed.

=item * C<< $msg->trigger_event() >> / C<< $msg->trigger_event($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::CompanionAgent::TriggerEvent>)

Optional. Event that triggers the guidance instruction.
If UNSPECIFIED, the instruction triggering will be the same as the skill's
skill_triggering_event.

=item * C<< $msg->disable_suggested_reply() >> / C<< $msg->disable_suggested_reply($value) >>

Type: C<Bool>

Optional. Whether to disable suggested reply generation for this
instruction. When set to `true`, guidance generated from this instruction
will not include a suggested reply. Default is `false` (suggested reply
enabled).

=back

=head2 Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent

Companion agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the companion agent.
Format:
`projects/{project}/locations/{location}/companionAgents/{companion_agent}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of this companion agent.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time of this companion agent.

=item * C<< $msg->toolset_tools() >> / C<< $msg->toolset_tools($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Toolset::ToolsetTool>)

Optional. List of CES toolset specs that the companion agent can choose
from.

=item * C<< $msg->ces_tool_specs() >> / C<< $msg->ces_tool_specs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec>)

Optional. List of CES tool specs that the companion agent can choose from.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name for the companion agent.
Character limit is 63.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description for the companion agent.

=item * C<< $msg->skill_configs() >> / C<< $msg->skill_configs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::SkillConfig>)

Optional. List of skill configs for the companion agent.
Allows at most one instance of each
[SkillConfig][google.cloud.dialogflow.v2.CompanionAgent.SkillConfig] type.

=back

=head3 Enum: CompanionAgent::TriggerEvent

=over 4

=item * C<TRIGGER_EVENT_UNSPECIFIED> => C<0>

=item * C<END_OF_UTTERANCE> => C<1>

=item * C<CUSTOMER_MESSAGE> => C<2>

=item * C<AGENT_MESSAGE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::CompanionAgent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
