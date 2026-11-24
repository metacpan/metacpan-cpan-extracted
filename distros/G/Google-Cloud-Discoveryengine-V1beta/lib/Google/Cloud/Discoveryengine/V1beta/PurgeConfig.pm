package Google::Cloud::Discoveryengine::V1beta::PurgeConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::ImportConfig };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9wdXJnZV9jb25maWcucHJv
dG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjdnb29nbGUv
Y2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9pbXBvcnRfY29uZmlnLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byKV
AQoWUHVyZ2VVc2VyRXZlbnRzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50EhsKBmZpbHRl
chgCIAEoCUID4EECUgZmaWx0ZXISFAoFZm9yY2UYAyABKAhSBWZvcmNlIjoKF1B1cmdlVXNl
ckV2ZW50c1Jlc3BvbnNlEh8KC3B1cmdlX2NvdW50GAEgASgDUgpwdXJnZUNvdW50It0BChdQ
dXJnZVVzZXJFdmVudHNNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEiMKDXN1Y2Nlc3NfY291bnQY
AyABKANSDHN1Y2Nlc3NDb3VudBIjCg1mYWlsdXJlX2NvdW50GAQgASgDUgxmYWlsdXJlQ291
bnQiQgoQUHVyZ2VFcnJvckNvbmZpZxIfCgpnY3NfcHJlZml4GAEgASgJSABSCWdjc1ByZWZp
eEINCgtkZXN0aW5hdGlvbiKVBAoVUHVyZ2VEb2N1bWVudHNSZXF1ZXN0Ek8KCmdjc19zb3Vy
Y2UYBSABKAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5HY3NTb3Vy
Y2VIAFIJZ2NzU291cmNlEm4KDWlubGluZV9zb3VyY2UYBiABKAsyRy5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5QdXJnZURvY3VtZW50c1JlcXVlc3QuSW5saW5lU291
cmNlSABSDGlubGluZVNvdXJjZRJFCgZwYXJlbnQYASABKAlCLeBBAvpBJwolZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL0JyYW5jaFIGcGFyZW50EhsKBmZpbHRlchgCIAEoCUID
4EECUgZmaWx0ZXISWAoMZXJyb3JfY29uZmlnGAcgASgLMjUuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuUHVyZ2VFcnJvckNvbmZpZ1ILZXJyb3JDb25maWcSFAoFZm9y
Y2UYAyABKAhSBWZvcmNlGl0KDElubGluZVNvdXJjZRJNCglkb2N1bWVudHMYASADKAlCL+BB
AvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50Uglkb2N1bWVu
dHNCCAoGc291cmNlIooBChZQdXJnZURvY3VtZW50c1Jlc3BvbnNlEh8KC3B1cmdlX2NvdW50
GAEgASgDUgpwdXJnZUNvdW50Ek8KDHB1cmdlX3NhbXBsZRgCIAMoCUIs+kEpCidkaXNjb3Zl
cnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnRSC3B1cmdlU2FtcGxlIoECChZQdXJn
ZURvY3VtZW50c01ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSIwoNc3VjY2Vzc19jb3VudBgDIAEo
A1IMc3VjY2Vzc0NvdW50EiMKDWZhaWx1cmVfY291bnQYBCABKANSDGZhaWx1cmVDb3VudBIj
Cg1pZ25vcmVkX2NvdW50GAUgASgDUgxpZ25vcmVkQ291bnQicQolUHVyZ2VTdWdnZXN0aW9u
RGVueUxpc3RFbnRyaWVzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50IoIBCiZQdXJnZVN1
Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNSZXNwb25zZRIfCgtwdXJnZV9jb3VudBgBIAEoA1IK
cHVyZ2VDb3VudBI3Cg1lcnJvcl9zYW1wbGVzGAIgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNS
DGVycm9yU2FtcGxlcyKiAQomUHVyZ2VTdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzTWV0YWRh
dGESOwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpj
cmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKdXBkYXRlVGltZSJtCiFQdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc1JlcXVlc3QS
SAoGcGFyZW50GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9EYXRhU3RvcmVSBnBhcmVudCKGAQoiUHVyZ2VDb21wbGV0aW9uU3VnZ2VzdGlvbnNSZXNw
b25zZRInCg9wdXJnZV9zdWNjZWVkZWQYASABKAhSDnB1cmdlU3VjY2VlZGVkEjcKDWVycm9y
X3NhbXBsZXMYAiADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVzIp4BCiJQ
dXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc01ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGlt
ZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWVClwIKJ2Nv
bS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIQUHVyZ2VDb25maWdQcm90
b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlz
Y292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNH
b29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNj
b3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpW
MWJldGFKoVAKBxIFDgCdAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAEEKCQoCAwMSAxUAKQoJ
CgIDBBIDFgAhCggKAQgSAxgAQAoJCgIIJRIDGABACggKAQgSAxkAaAoJCgIICxIDGQBoCggK
AQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMQoJCgIICBIDGwAxCggKAQgSAxwAQAoJCgII
ARIDHABACggKAQgSAx0ALQoJCgIIJBIDHQAtCggKAQgSAx4AQAoJCgIIKRIDHgBACggKAQgS
Ax8APwoJCgIILRIDHwA/CjkKAgQAEgQiAFMBGi0gUmVxdWVzdCBtZXNzYWdlIGZvciBQdXJn
ZVVzZXJFdmVudHMgbWV0aG9kLgoKCgoDBAABEgMiCB4KxgEKBAQAAgASBCYCKwQatwEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjYXRhbG9nIHVuZGVyIHdoaWNoIHRo
ZSBldmVudHMgYXJlCiBjcmVhdGVkLiBUaGUgZm9ybWF0IGlzCiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9y
ZXMve2RhdGFTdG9yZX1gLgoKDAoFBAACAAUSAyYCCAoMCgUEAAIAARIDJgkPCgwKBQQAAgAD
EgMmEhMKDQoFBAACAAgSBCYUKwMKDwoIBAACAAicCAASAycEKgoPCgcEAAIACJ8IEgQoBCoF
Cq0JCgQEAAIBEgNKAj0anwkgUmVxdWlyZWQuIFRoZSBmaWx0ZXIgc3RyaW5nIHRvIHNwZWNp
ZnkgdGhlIGV2ZW50cyB0byBiZSBkZWxldGVkIHdpdGggYQogbGVuZ3RoIGxpbWl0IG9mIDUs
MDAwIGNoYXJhY3RlcnMuIFRoZSBlbGlnaWJsZSBmaWVsZHMgZm9yIGZpbHRlcmluZyBhcmU6
CgogKiBgZXZlbnRUeXBlYDogRG91YmxlIHF1b3RlZAogW1VzZXJFdmVudC5ldmVudF90eXBl
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2VyRXZlbnQuZXZlbnRf
dHlwZV0KIHN0cmluZy4KICogYGV2ZW50VGltZWA6IGluIElTTyA4NjAxICJ6dWx1IiBmb3Jt
YXQuCiAqIGB1c2VyUHNldWRvSWRgOiBEb3VibGUgcXVvdGVkIHN0cmluZy4gU3BlY2lmeWlu
ZyB0aGlzIHdpbGwgZGVsZXRlIGFsbAogICBldmVudHMgYXNzb2NpYXRlZCB3aXRoIGEgdmlz
aXRvci4KICogYHVzZXJJZGA6IERvdWJsZSBxdW90ZWQgc3RyaW5nLiBTcGVjaWZ5aW5nIHRo
aXMgd2lsbCBkZWxldGUgYWxsIGV2ZW50cwogICBhc3NvY2lhdGVkIHdpdGggYSB1c2VyLgoK
IE5vdGU6IFRoaXMgQVBJIG9ubHkgc3VwcG9ydHMgcHVyZ2luZyBhIG1heCByYW5nZSBvZiAz
MCBkYXlzLgoKIEV4YW1wbGVzOgoKICogRGVsZXRpbmcgYWxsIGV2ZW50cyBpbiBhIHRpbWUg
cmFuZ2U6CiAgIGBldmVudFRpbWUgPiAiMjAxMi0wNC0yM1QxODoyNTo0My41MTFaIgogICBl
dmVudFRpbWUgPCAiMjAxMi0wNC0yM1QxODozMDo0My41MTFaImAKICogRGVsZXRpbmcgc3Bl
Y2lmaWMgZXZlbnRUeXBlIGluIGEgdGltZSByYW5nZToKICAgYGV2ZW50VGltZSA+ICIyMDEy
LTA0LTIzVDE4OjI1OjQzLjUxMVoiCiAgIGV2ZW50VGltZSA8ICIyMDEyLTA0LTIzVDE4OjMw
OjQzLjUxMVoiIGV2ZW50VHlwZSA9ICJzZWFyY2giYAogKiBEZWxldGluZyBhbGwgZXZlbnRz
IGZvciBhIHNwZWNpZmljIHZpc2l0b3IgaW4gYSB0aW1lIHJhbmdlOgogICBgZXZlbnRUaW1l
ID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTExWiIKICAgZXZlbnRUaW1lIDwgIjIwMTItMDQt
MjNUMTg6MzA6NDMuNTExWiIgdXNlclBzZXVkb0lkID0gInZpc2l0b3IxMDI0ImAKICogRGVs
ZXRpbmcgdGhlIHBhc3QgMzAgZGF5cyBvZiBldmVudHMgaW5zaWRlIGEgRGF0YVN0b3JlOgog
ICBgKmAKCiBUaGUgZmlsdGVyaW5nIGZpZWxkcyBhcmUgYXNzdW1lZCB0byBoYXZlIGFuIGlt
cGxpY2l0IEFORC4KCgwKBQQAAgEFEgNKAggKDAoFBAACAQESA0oJDwoMCgUEAAIBAxIDShIT
CgwKBQQAAgEIEgNKFDwKDwoIBAACAQicCAASA0oVOwrbAgoEBAACAhIDUgIRGs0CIFRoZSBg
Zm9yY2VgIGZpZWxkIGlzIGN1cnJlbnRseSBub3Qgc3VwcG9ydGVkLiBQdXJnZSB1c2VyIGV2
ZW50IHJlcXVlc3RzCiB3aWxsIHBlcm1hbmVudGx5IGRlbGV0ZSBhbGwgcHVyZ2VhYmxlIGV2
ZW50cy4gT25jZSB0aGUgZGV2ZWxvcG1lbnQgaXMKIGNvbXBsZXRlOgogSWYgYGZvcmNlYCBp
cyBzZXQgdG8gZmFsc2UsIHRoZSBtZXRob2Qgd2lsbCByZXR1cm4gdGhlIGV4cGVjdGVkCiBw
dXJnZSBjb3VudCB3aXRob3V0IGRlbGV0aW5nIGFueSB1c2VyIGV2ZW50cy4gVGhpcyBmaWVs
ZCB3aWxsIGRlZmF1bHQgdG8KIGZhbHNlIGlmIG5vdCBpbmNsdWRlZCBpbiB0aGUgcmVxdWVz
dC4KCgwKBQQAAgIFEgNSAgYKDAoFBAACAgESA1IHDAoMCgUEAAICAxIDUg8QCr8BCgIEARIE
WABbARqyASBSZXNwb25zZSBvZiB0aGUgUHVyZ2VVc2VyRXZlbnRzUmVxdWVzdC4gSWYgdGhl
IGxvbmcgcnVubmluZyBvcGVyYXRpb24gaXMKIHN1Y2Nlc3NmdWxseSBkb25lLCB0aGVuIHRo
aXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0aGUKIGdvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb25zLnJlc3BvbnNlIGZpZWxkLgoKCgoDBAEBEgNYCB8KTQoEBAECABIDWgIYGkAgVGhl
IHRvdGFsIGNvdW50IG9mIGV2ZW50cyBwdXJnZWQgYXMgYSByZXN1bHQgb2YgdGhlIG9wZXJh
dGlvbi4KCgwKBQQBAgAFEgNaAgcKDAoFBAECAAESA1oIEwoMCgUEAQIAAxIDWhYXCpwBCgIE
AhIEXwBsARqPASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUgUHVy
Z2VVc2VyRXZlbnRzIG9wZXJhdGlvbi4KIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUg
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YSBmaWVsZC4KCgoKAwQCARID
XwgfCiUKBAQCAgASA2ECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCgwKBQQCAgAGEgNh
AhsKDAoFBAICAAESA2EcJwoMCgUEAgIAAxIDYSorCmMKBAQCAgESA2UCLBpWIE9wZXJhdGlv
biBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMg
YWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDAoFBAICAQYSA2UCGwoMCgUEAgIBARIDZRwnCgwK
BQQCAgEDEgNlKisKPwoEBAICAhIDaAIaGjIgQ291bnQgb2YgZW50cmllcyB0aGF0IHdlcmUg
ZGVsZXRlZCBzdWNjZXNzZnVsbHkuCgoMCgUEAgICBRIDaAIHCgwKBQQCAgIBEgNoCBUKDAoF
BAICAgMSA2gYGQpJCgQEAgIDEgNrAhoaPCBDb3VudCBvZiBlbnRyaWVzIHRoYXQgZW5jb3Vu
dGVyZWQgZXJyb3JzIHdoaWxlIHByb2Nlc3NpbmcuCgoMCgUEAgIDBRIDawIHCgwKBQQCAgMB
EgNrCBUKDAoFBAICAwMSA2sYGQpECgIEAxIEbwB4ARo4IENvbmZpZ3VyYXRpb24gb2YgZGVz
dGluYXRpb24gZm9yIFB1cmdlIHJlbGF0ZWQgZXJyb3JzLgoKCgoDBAMBEgNvCBgKLQoEBAMI
ABIEcQJ3AxofIFJlcXVpcmVkLiBFcnJvcnMgZGVzdGluYXRpb24uCgoMCgUEAwgAARIDcQgT
CuwBCgQEAwIAEgN2BBoa3gEgQ2xvdWQgU3RvcmFnZSBwcmVmaXggZm9yIHB1cmdlIGVycm9y
cy4gVGhpcyBtdXN0IGJlIGFuIGVtcHR5LAogZXhpc3RpbmcgQ2xvdWQgU3RvcmFnZSBkaXJl
Y3RvcnkuIFB1cmdlIGVycm9ycyBhcmUgd3JpdHRlbiB0bwogc2hhcmRlZCBmaWxlcyBpbiB0
aGlzIGRpcmVjdG9yeSwgb25lIHBlciBsaW5lLCBhcyBhIEpTT04tZW5jb2RlZAogYGdvb2ds
ZS5ycGMuU3RhdHVzYCBtZXNzYWdlLgoKDAoFBAMCAAUSA3YECgoMCgUEAwIAARIDdgsVCgwK
BQQDAgADEgN2GBkKkgEKAgQEEgV9AK4BARqEASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRG9j
dW1lbnRTZXJ2aWNlLlB1cmdlRG9jdW1lbnRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5Eb2N1bWVudFNlcnZpY2UuUHVyZ2VEb2N1bWVudHNdCiBtZXRob2QuCgoK
CgMEBAESA30IHQqsAQoEBAQDABIGgQECjAEDGpsBIFRoZSBpbmxpbmUgc291cmNlIGZvciB0
aGUgaW5wdXQgY29uZmlnIGZvcgogW0RvY3VtZW50U2VydmljZS5QdXJnZURvY3VtZW50c11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRTZXJ2aWNlLlB1
cmdlRG9jdW1lbnRzXQogbWV0aG9kLgoKDQoFBAQDAAESBIEBChYKzQEKBgQEAwACABIGhgEE
iwEGGroBIFJlcXVpcmVkLiBBIGxpc3Qgb2YgZnVsbCByZXNvdXJjZSBuYW1lIG9mIGRvY3Vt
ZW50cyB0byBwdXJnZS4gSW4gdGhlCiBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL2JyYW5jaGVzLyovZG9jdW1lbnRzLypgLgog
UmVjb21tZW5kZWQgbWF4IG9mIDEwMCBpdGVtcy4KCg8KBwQEAwACAAQSBIYBBAwKDwoHBAQD
AAIABRIEhgENEwoPCgcEBAMAAgABEgSGARQdCg8KBwQEAwACAAMSBIYBICEKEQoHBAQDAAIA
CBIGhgEiiwEFChIKCgQEAwACAAicCAASBIcBBiwKEwoJBAQDAAIACJ8IEgaIAQaKAQcKWwoE
BAQIABIGjwECmAEDGksgVGhlIGRlc2lyZWQgaW5wdXQgc291cmNlIGZvciB0aGUgcHVyZ2lu
ZyBkb2N1bWVudHMgYmFzZWQgb24gZG9jdW1lbnQgSURzLgoKDQoFBAQIAAESBI8BCA4KvgEK
BAQEAgASBJQBBB0arwEgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiBmb3IgdGhlIGlucHV0IGNv
bnRlbnQuCiBTdXBwb3J0ZWQgYGRhdGFfc2NoZW1hYDoKICogYGRvY3VtZW50X2lkYDogT25l
IHZhbGlkCiBbRG9jdW1lbnQuaWRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkRvY3VtZW50LmlkXSBwZXIgbGluZS4KCg0KBQQEAgAGEgSUAQQNCg0KBQQEAgABEgSU
AQ4YCg0KBQQEAgADEgSUARscCj4KBAQEAgESBJcBBCMaMCBJbmxpbmUgc291cmNlIGZvciB0
aGUgaW5wdXQgY29udGVudCBmb3IgcHVyZ2UuCgoNCgUEBAIBBhIElwEEEAoNCgUEBAIBARIE
lwERHgoNCgUEBAIBAxIElwEhIgqtAQoEBAQCAhIGnAECoQEEGpwBIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMv
e2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9YC4KCg0KBQQEAgIFEgScAQIICg0KBQQE
AgIBEgScAQkPCg0KBQQEAgIDEgScARITCg8KBQQEAgIIEgacARShAQMKEAoIBAQCAgicCAAS
BJ0BBCoKEQoHBAQCAgifCBIGngEEoAEFCnIKBAQEAgMSBKYBAj0aZCBSZXF1aXJlZC4gRmls
dGVyIG1hdGNoaW5nIGRvY3VtZW50cyB0byBwdXJnZS4gT25seSBjdXJyZW50bHkgc3VwcG9y
dGVkCiB2YWx1ZSBpcwogYCpgIChhbGwgaXRlbXMpLgoKDQoFBAQCAwUSBKYBAggKDQoFBAQC
AwESBKYBCQ8KDQoFBAQCAwMSBKYBEhMKDQoFBAQCAwgSBKYBFDwKEAoIBAQCAwicCAASBKYB
FTsKSQoEBAQCBBIEqQECJBo7IFRoZSBkZXNpcmVkIGxvY2F0aW9uIG9mIGVycm9ycyBpbmN1
cnJlZCBkdXJpbmcgdGhlIHB1cmdlLgoKDQoFBAQCBAYSBKkBAhIKDQoFBAQCBAESBKkBEx8K
DQoFBAQCBAMSBKkBIiMKiQEKBAQEAgUSBK0BAhEaeyBBY3R1YWxseSBwZXJmb3JtcyB0aGUg
cHVyZ2UuIElmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLCByZXR1cm4gdGhlCiBleHBlY3Rl
ZCBwdXJnZSBjb3VudCB3aXRob3V0IGRlbGV0aW5nIGFueSBkb2N1bWVudHMuCgoNCgUEBAIF
BRIErQECBgoNCgUEBAIFARIErQEHDAoNCgUEBAIFAxIErQEPEAqcAgoCBAUSBrQBAL4BARqN
AiBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0RvY3VtZW50U2VydmljZS5QdXJnZURvY3VtZW50
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRTZXJ2aWNl
LlB1cmdlRG9jdW1lbnRzXQogbWV0aG9kLiBJZiB0aGUgbG9uZyBydW5uaW5nIG9wZXJhdGlv
biBpcyBzdWNjZXNzZnVsbHkgZG9uZSwgdGhlbiB0aGlzIG1lc3NhZ2UKIGlzIHJldHVybmVk
IGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVsZC4K
CgsKAwQFARIEtAEIHgpRCgQEBQIAEgS2AQIYGkMgVGhlIHRvdGFsIGNvdW50IG9mIGRvY3Vt
ZW50cyBwdXJnZWQgYXMgYSByZXN1bHQgb2YgdGhlIG9wZXJhdGlvbi4KCg0KBQQFAgAFEgS2
AQIHCg0KBQQFAgABEgS2AQgTCg0KBQQFAgADEgS2ARYXCrgBCgQEBQIBEga7AQK9AQUapwEg
QSBzYW1wbGUgb2YgZG9jdW1lbnQgbmFtZXMgdGhhdCB3aWxsIGJlIGRlbGV0ZWQuIE9ubHkg
cG9wdWxhdGVkIGlmIGBmb3JjZWAKIGlzIHNldCB0byBmYWxzZS4gQSBtYXggb2YgMTAwIG5h
bWVzIHdpbGwgYmUgcmV0dXJuZWQgYW5kIHRoZSBuYW1lcyBhcmUKIGNob3NlbiBhdCByYW5k
b20uCgoNCgUEBQIBBBIEuwECCgoNCgUEBQIBBRIEuwELEQoNCgUEBQIBARIEuwESHgoNCgUE
BQIBAxIEuwEhIgoPCgUEBQIBCBIGuwEjvQEEChEKBwQFAgEInwgSBrsBJL0BAwqdAQoCBAYS
BsIBANIBARqOASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUgUHVy
Z2VEb2N1bWVudHMgb3BlcmF0aW9uLgogVGhpcyB3aWxsIGJlIHJldHVybmVkIGJ5IHRoZSBn
b29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhIGZpZWxkLgoKCwoDBAYBEgTC
AQgeCiYKBAQGAgASBMQBAiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEBgIABhIE
xAECGwoNCgUEBgIAARIExAEcJwoNCgUEBgIAAxIExAEqKwpkCgQEBgIBEgTIAQIsGlYgT3Bl
cmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhp
cyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoNCgUEBgIBBhIEyAECGwoNCgUEBgIBARIE
yAEcJwoNCgUEBgIBAxIEyAEqKwpACgQEBgICEgTLAQIaGjIgQ291bnQgb2YgZW50cmllcyB0
aGF0IHdlcmUgZGVsZXRlZCBzdWNjZXNzZnVsbHkuCgoNCgUEBgICBRIEywECBwoNCgUEBgIC
ARIEywEIFQoNCgUEBgICAxIEywEYGQpKCgQEBgIDEgTOAQIaGjwgQ291bnQgb2YgZW50cmll
cyB0aGF0IGVuY291bnRlcmVkIGVycm9ycyB3aGlsZSBwcm9jZXNzaW5nLgoKDQoFBAYCAwUS
BM4BAgcKDQoFBAYCAwESBM4BCBUKDQoFBAYCAwMSBM4BGBkKTQoEBAYCBBIE0QECGho/IENv
dW50IG9mIGVudHJpZXMgdGhhdCB3ZXJlIGlnbm9yZWQgYXMgZW50cmllcyB3ZXJlIG5vdCBm
b3VuZC4KCg0KBQQGAgQFEgTRAQIHCg0KBQQGAgQBEgTRAQgVCg0KBQQGAgQDEgTRARgZCrcB
CgIEBxIG1wEA4AEBGqgBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb21wbGV0aW9uU2Vydmlj
ZS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkNvbXBsZXRpb25TZXJ2aWNlLlB1cmdlU3VnZ2VzdGlvbkRlbnlM
aXN0RW50cmllc10KIG1ldGhvZC4KCgsKAwQHARIE1wEILQqqAQoEBAcCABIG2gEC3wEEGpkB
IFJlcXVpcmVkLiBUaGUgcGFyZW50IGRhdGEgc3RvcmUgcmVzb3VyY2UgbmFtZSBmb3Igd2hp
Y2ggdG8gaW1wb3J0IGRlbnlsaXN0CiBlbnRyaWVzLiBGb2xsb3dzIHBhdHRlcm4gcHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi4KCg0KBQQHAgAF
EgTaAQIICg0KBQQHAgABEgTaAQkPCg0KBQQHAgADEgTaARITCg8KBQQHAgAIEgbaARTfAQMK
EAoIBAcCAAicCAASBNsBBCoKEQoHBAcCAAifCBIG3AEE3gEFCrgBCgIECBIG5QEA6wEBGqkB
IFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbQ29tcGxldGlvblNlcnZpY2UuUHVyZ2VTdWdnZXN0
aW9uRGVueUxpc3RFbnRyaWVzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5Db21wbGV0aW9uU2VydmljZS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNdCiBt
ZXRob2QuCgoLCgMECAESBOUBCC4KPgoEBAgCABIE5wECGBowIE51bWJlciBvZiBzdWdnZXN0
aW9uIGRlbnkgbGlzdCBlbnRyaWVzIHB1cmdlZC4KCg0KBQQIAgAFEgTnAQIHCg0KBQQIAgAB
EgTnAQgTCg0KBQQIAgADEgTnARYXCkwKBAQIAgESBOoBAi8aPiBBIHNhbXBsZSBvZiBlcnJv
cnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVzdC4KCg0KBQQIAgEE
EgTqAQIKCg0KBQQIAgEGEgTqAQscCg0KBQQIAgEBEgTqAR0qCg0KBQQIAgEDEgTqAS0uCqkB
CgIECRIG8AEA9wEBGpoBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRo
ZSBQdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXMKIG9wZXJhdGlvbi4gVGhpcyBpcyBy
ZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQog
ZmllbGQuCgoLCgMECQESBPABCC4KJgoEBAkCABIE8gECLBoYIE9wZXJhdGlvbiBjcmVhdGUg
dGltZS4KCg0KBQQJAgAGEgTyAQIbCg0KBQQJAgABEgTyARwnCg0KBQQJAgADEgTyASorCmQK
BAQJAgESBPYBAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJh
dGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQJAgEG
EgT2AQIbCg0KBQQJAgEBEgT2ARwnCg0KBQQJAgEDEgT2ASorCq8BCgIEChIG/AEAhgIBGqAB
IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb21wbGV0aW9uU2VydmljZS5QdXJnZUNvbXBsZXRp
b25TdWdnZXN0aW9uc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ29t
cGxldGlvblNlcnZpY2UuUHVyZ2VDb21wbGV0aW9uU3VnZ2VzdGlvbnNdCiBtZXRob2QuCgoL
CgMECgESBPwBCCkKsAEKBAQKAgASBoACAoUCBBqfASBSZXF1aXJlZC4gVGhlIHBhcmVudCBk
YXRhIHN0b3JlIHJlc291cmNlIG5hbWUgZm9yIHdoaWNoIHRvIHB1cmdlIGNvbXBsZXRpb24K
IHN1Z2dlc3Rpb25zLiBGb2xsb3dzIHBhdHRlcm4KIHByb2plY3RzLyovbG9jYXRpb25zLyov
Y29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyouCgoNCgUECgIABRIEgAICCAoNCgUECgIAARIE
gAIJDwoNCgUECgIAAxIEgAISEwoPCgUECgIACBIGgAIUhQIDChAKCAQKAgAInAgAEgSBAgQq
ChEKBwQKAgAInwgSBoICBIQCBQqwAQoCBAsSBosCAJECARqhASBSZXNwb25zZSBtZXNzYWdl
IGZvcgogW0NvbXBsZXRpb25TZXJ2aWNlLlB1cmdlQ29tcGxldGlvblN1Z2dlc3Rpb25zXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Db21wbGV0aW9uU2VydmljZS5Q
dXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc10KIG1ldGhvZC4KCgsKAwQLARIEiwIIKgpMCgQE
CwIAEgSNAgIbGj4gV2hldGhlciB0aGUgY29tcGxldGlvbiBzdWdnZXN0aW9ucyB3ZXJlIHN1
Y2Nlc3NmdWxseSBwdXJnZWQuCgoNCgUECwIABRIEjQICBgoNCgUECwIAARIEjQIHFgoNCgUE
CwIAAxIEjQIZGgpMCgQECwIBEgSQAgIvGj4gQSBzYW1wbGUgb2YgZXJyb3JzIGVuY291bnRl
cmVkIHdoaWxlIHByb2Nlc3NpbmcgdGhlIHJlcXVlc3QuCgoNCgUECwIBBBIEkAICCgoNCgUE
CwIBBhIEkAILHAoNCgUECwIBARIEkAIdKgoNCgUECwIBAxIEkAItLgqlAQoCBAwSBpYCAJ0C
ARqWASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUgUHVyZ2VDb21w
bGV0aW9uU3VnZ2VzdGlvbnMKIG9wZXJhdGlvbi4gVGhpcyBpcyByZXR1cm5lZCBieSB0aGUg
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMEDAES
BJYCCCoKJgoEBAwCABIEmAICLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQMAgAG
EgSYAgIbCg0KBQQMAgABEgSYAhwnCg0KBQQMAgADEgSYAiorCmQKBAQMAgESBJwCAiwaViBP
cGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0
aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQMAgEGEgScAgIbCg0KBQQMAgEB
EgScAhwnCg0KBQQMAgEDEgScAiorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsRequest ===
    # Fields for PurgeUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsResponse ===
    # Fields for PurgeUserEventsResponse
    # Field: purge_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsMetadata ===
    # Fields for PurgeUserEventsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeErrorConfig ===
    # Fields for PurgeErrorConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsRequest ===
    # Fields for PurgeDocumentsRequest
    # Field: gcs_source Type: 11 (.google.cloud.discoveryengine.v1beta.GcsSource)
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1beta.PurgeDocumentsRequest.InlineSource)
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1beta.PurgeErrorConfig)
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsResponse ===
    # Fields for PurgeDocumentsResponse
    # Field: purge_count Type: 3 ()
    # Field: purge_sample Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsMetadata ===
    # Fields for PurgeDocumentsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: ignored_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeSuggestionDenyListEntriesRequest ===
    # Fields for PurgeSuggestionDenyListEntriesRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeSuggestionDenyListEntriesResponse ===
    # Fields for PurgeSuggestionDenyListEntriesResponse
    # Field: purge_count Type: 3 ()
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata ===
    # Fields for PurgeSuggestionDenyListEntriesMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeCompletionSuggestionsRequest ===
    # Fields for PurgeCompletionSuggestionsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeCompletionSuggestionsResponse ===
    # Fields for PurgeCompletionSuggestionsResponse
    # Field: purge_succeeded Type: 8 ()
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeCompletionSuggestionsMetadata ===
    # Fields for PurgeCompletionSuggestionsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::PurgeConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/purge_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::PurgeConfig;

    my $msg = Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsRequest->new({
        parent => $parent,
        filter => $filter,
        force => $force,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/purge_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsRequest

Request message for PurgeUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the catalog under which the events are
created. The format is
`projects/{project}/locations/global/collections/{collection}/dataStores/{dataStore}`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the events to be deleted with a
length limit of 5,000 characters. The eligible fields for filtering are:

* `eventType`: Double quoted
[UserEvent.event_type][google.cloud.discoveryengine.v1beta.UserEvent.event_type]
string.
* `eventTime`: in ISO 8601 "zulu" format.
* `userPseudoId`: Double quoted string. Specifying this will delete all
  events associated with a visitor.
* `userId`: Double quoted string. Specifying this will delete all events
  associated with a user.

Note: This API only supports purging a max range of 30 days.

Examples:

* Deleting all events in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z"`
* Deleting specific eventType in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z" eventType = "search"`
* Deleting all events for a specific visitor in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z" userPseudoId = "visitor1024"`
* Deleting the past 30 days of events inside a DataStore:
  `*`

The filtering fields are assumed to have an implicit AND.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

The `force` field is currently not supported. Purge user event requests
will permanently delete all purgeable events. Once the development is
complete:
If `force` is set to false, the method will return the expected
purge count without deleting any user events. This field will default to
false if not included in the request.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsResponse

Response of the PurgeUserEventsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of events purged as a result of the operation.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeUserEventsMetadata

Metadata related to the progress of the PurgeUserEvents operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeErrorConfig

Configuration of destination for Purge related errors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<String>

Cloud Storage prefix for purge errors. This must be an empty,
existing Cloud Storage directory. Purge errors are written to
sharded files in this directory, one per line, as a JSON-encoded
`google.rpc.Status` message.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsRequest

Request message for
[DocumentService.PurgeDocuments][google.cloud.discoveryengine.v1beta.DocumentService.PurgeDocuments]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::ImportConfig::GcsSource>)

Cloud Storage location for the input content.
Supported `data_schema`:
* `document_id`: One valid
[Document.id][google.cloud.discoveryengine.v1beta.Document.id] per line.

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsRequest::InlineSource>)

Inline source for the input content for purge.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. Filter matching documents to purge. Only currently supported
value is
`*` (all items).

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeErrorConfig>)

The desired location of errors incurred during the purge.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually performs the purge. If `force` is set to false, return the
expected purge count without deleting any documents.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsResponse

Response message for
[DocumentService.PurgeDocuments][google.cloud.discoveryengine.v1beta.DocumentService.PurgeDocuments]
method. If the long running operation is successfully done, then this message
is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of documents purged as a result of the operation.

=item * C<< $msg->purge_sample() >> / C<< $msg->purge_sample($value) >>

Type: C<String>

A sample of document names that will be deleted. Only populated if `force`
is set to false. A max of 100 names will be returned and the names are
chosen at random.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeDocumentsMetadata

Metadata related to the progress of the PurgeDocuments operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=item * C<< $msg->ignored_count() >> / C<< $msg->ignored_count($value) >>

Type: C<Int64>

Count of entries that were ignored as entries were not found.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeSuggestionDenyListEntriesRequest

Request message for
[CompletionService.PurgeSuggestionDenyListEntries][google.cloud.discoveryengine.v1beta.CompletionService.PurgeSuggestionDenyListEntries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name for which to import denylist
entries. Follows pattern projects/*/locations/*/collections/*/dataStores/*.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeSuggestionDenyListEntriesResponse

Response message for
[CompletionService.PurgeSuggestionDenyListEntries][google.cloud.discoveryengine.v1beta.CompletionService.PurgeSuggestionDenyListEntries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

Number of suggestion deny list entries purged.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata

Metadata related to the progress of the PurgeSuggestionDenyListEntries
operation. This is returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeCompletionSuggestionsRequest

Request message for
[CompletionService.PurgeCompletionSuggestions][google.cloud.discoveryengine.v1beta.CompletionService.PurgeCompletionSuggestions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name for which to purge completion
suggestions. Follows pattern
projects/*/locations/*/collections/*/dataStores/*.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeCompletionSuggestionsResponse

Response message for
[CompletionService.PurgeCompletionSuggestions][google.cloud.discoveryengine.v1beta.CompletionService.PurgeCompletionSuggestions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_succeeded() >> / C<< $msg->purge_succeeded($value) >>

Type: C<Bool>

Whether the completion suggestions were successfully purged.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::PurgeConfig::PurgeCompletionSuggestionsMetadata

Metadata related to the progress of the PurgeCompletionSuggestions
operation. This is returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::PurgeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
