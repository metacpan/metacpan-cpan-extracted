package Google::Cloud::Sql::V1beta4::CloudSqlData;

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
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX2RhdGEucHJvdG8SGGdvb2ds
ZS5jbG91ZC5zcWwudjFiZXRhNBocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIuAD
ChRTdHJlYW1TcWxEYXRhUmVxdWVzdBI0CgNhY2sYBCABKAsyHS5nb29nbGUuY2xvdWQuc3Fs
LnYxYmV0YTQuQWNrQgPgQQFSA2FjaxJNCg1zdGFydF9zZXNzaW9uGAUgASgLMiYuZ29vZ2xl
LmNsb3VkLnNxbC52MWJldGE0LlN0YXJ0U2Vzc2lvbkgAUgxzdGFydFNlc3Npb24SVgoQY29u
dGludWVfc2Vzc2lvbhgGIAEoCzIpLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5Db250aW51
ZVNlc3Npb25IAFIPY29udGludWVTZXNzaW9uEjoKBGRhdGEYByABKAsyJC5nb29nbGUuY2xv
dWQuc3FsLnYxYmV0YTQuRGF0YVBhY2tldEgAUgRkYXRhElkKEXRlcm1pbmF0ZV9zZXNzaW9u
GAggASgLMiouZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlRlcm1pbmF0ZVNlc3Npb25IAFIQ
dGVybWluYXRlU2Vzc2lvbhJJCgtpbnN0YW5jZV9pZBgJIAEoCUIo4EEB+kEiCiBjbG91ZHNx
bC5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIKaW5zdGFuY2VJZEIJCgdtZXNzYWdlIqMBCgxT
dGFydFNlc3Npb24SJAoLbG9jYXRpb25faWQYASABKAlCA+BBAlIKbG9jYXRpb25JZBJJCgtp
bnN0YW5jZV9pZBgCIAEoCUIo4EEC+kEiCiBjbG91ZHNxbC5nb29nbGVhcGlzLmNvbS9JbnN0
YW5jZVIKaW5zdGFuY2VJZBIiCgpzZXNzaW9uX2lkGAMgASgJQgPgQQFSCXNlc3Npb25JZCKm
AQoPQ29udGludWVTZXNzaW9uEiQKC2xvY2F0aW9uX2lkGAEgASgJQgPgQQJSCmxvY2F0aW9u
SWQSSQoLaW5zdGFuY2VfaWQYAiABKAlCKOBBAvpBIgogY2xvdWRzcWwuZ29vZ2xlYXBpcy5j
b20vSW5zdGFuY2VSCmluc3RhbmNlSWQSIgoKc2Vzc2lvbl9pZBgDIAEoCUID4EECUglzZXNz
aW9uSWQiwgIKFVN0cmVhbVNxbERhdGFSZXNwb25zZRIvCgNhY2sYAiABKAsyHS5nb29nbGUu
Y2xvdWQuc3FsLnYxYmV0YTQuQWNrUgNhY2sSVgoQc2Vzc2lvbl9tZXRhZGF0YRgDIAEoCzIp
Lmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5TZXNzaW9uTWV0YWRhdGFIAFIPc2Vzc2lvbk1l
dGFkYXRhEjoKBGRhdGEYBCABKAsyJC5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuRGF0YVBh
Y2tldEgAUgRkYXRhElkKEXRlcm1pbmF0ZV9zZXNzaW9uGAUgASgLMiouZ29vZ2xlLmNsb3Vk
LnNxbC52MWJldGE0LlRlcm1pbmF0ZVNlc3Npb25IAFIQdGVybWluYXRlU2Vzc2lvbkIJCgdt
ZXNzYWdlImoKD1Nlc3Npb25NZXRhZGF0YRJXChJzdXBwb3J0ZWRfZmVhdHVyZXMYASADKA4y
KC5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuU3FsRGF0YUZlYXR1cmVSEXN1cHBvcnRlZEZl
YXR1cmVzIlYKCkRhdGFQYWNrZXQSLwoRZmlyc3RfYnl0ZV9vZmZzZXQYASABKANCA+BBAVIP
Zmlyc3RCeXRlT2Zmc2V0EhcKBGRhdGEYAiABKAxCA+BBAlIEZGF0YSIzCgNBY2sSLAoPcmVj
ZWl2ZWRfb2Zmc2V0GAEgASgDQgPgQQJSDnJlY2VpdmVkT2Zmc2V0IkMKEFRlcm1pbmF0ZVNl
c3Npb24SLwoGc3RhdHVzGAEgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNCA+BBAlIGc3RhdHVz
KlIKDlNxbERhdGFGZWF0dXJlEiAKHFNRTF9EQVRBX0ZFQVRVUkVfVU5TUEVDSUZJRUQQABIe
ChpTUUxfREFUQV9GRUFUVVJFX1JFQ09OTkVDVBABMoYCCg5TcWxEYXRhU2VydmljZRJ2Cg1T
dHJlYW1TcWxEYXRhEi4uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlN0cmVhbVNxbERhdGFS
ZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlN0cmVhbVNxbERhdGFSZXNwb25z
ZSIAKAEwARp8ykEXc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb23SQV9odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvc3Fsc2VydmljZS5hZG1pbkJjChxjb20uZ29vZ2xlLmNsb3VkLnNxbC52MWJl
dGE0QhFDbG91ZFNxbERhdGFQcm90b1ABWi5jbG91ZC5nb29nbGUuY29tL2dvL3NxbC9hcGl2
MWJldGE0L3NxbHBiO3NxbHBiSt0/CgcSBQ4A3AEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYAIQoICgEIEgMYAEUKCQoCCAsSAxgARQoICgEIEgMZACIK
CQoCCAoSAxkAIgoICgEIEgMaADIKCQoCCAgSAxoAMgoICgEIEgMbADUKCQoCCAESAxsANQpJ
CgIGABIEHgBKARo9IFNlcnZpY2UgZm9yIHN0cmVhbWluZyBkYXRhIHRvIGFuZCBmcm9tIENs
b3VkIFNRTCBpbnN0YW5jZXMuCgoKCgMGAAESAx4IFgoKCgMGAAMSAx8CPwoMCgUGAAOZCBID
HwI/CgsKAwYAAxIEIAIiOQoNCgUGAAOaCBIEIAIiOQqTDAoEBgACABIESAJJLxqEDCBgU3Ry
ZWFtU3FsRGF0YWAgZXN0YWJsaXNoZXMgYSBiaWRpcmVjdGlvbmFsIHN0cmVhbSB0byBhIENs
b3VkIFNRTCBpbnN0YW5jZSwKIGFuZCB0aGVuIHN0cmVhbXMgZGF0YSB0byBhbmQgZnJvbSB0
aGUgaW5zdGFuY2UuCgogVGhlIGZpcnN0IG1lc3NhZ2UgZnJvbSB0aGUgY2xpZW50IE1VU1Qg
YmUgYSBgU3RyZWFtU3FsRGF0YVJlcXVlc3RgIHJlcXVlc3QKIHdpdGggY29uZmlndXJhdGlv
biBzZXR0aW5ncywgaW5jbHVkaW5nIHJlcXVpcmVkIHZhbHVlcyBmb3IgdGhlCiBgY29ubmVj
dGlvbl9zZXR0aW5nc2AgZmllbGQuIFN1YnNlcXVlbnQgbWVzc2FnZXMgZnJvbSB0aGUgY2xp
ZW50IG1heQogY29udGFpbiB0aGUgYHBheWxvYWRgIGZpZWxkLgoKIE1lc3NhZ2VzIGZyb20g
dGhlIHNlcnZlciBtYXkgY29udGFpbiB0aGUgYHBheWxvYWRgIGZpZWxkLgoKIFRoZSBgcGF5
bG9hZGAgZmllbGRzIG9mIHRoZSByZXF1ZXN0IGFuZCByZXNwb25zZSBzdHJlYW1zIGNvbnRh
aW4gdGhlIHJhdwogZGF0YSBvZiB0aGUgZGF0YWJhc2UncyBuYXRpdmUgd2lyZSBwcm90b2Nv
bCAoZS5nLiwgUG9zdGdyZVNRTCB3aXJlCiBwcm90b2NvbCkuIFRoZSBkYXRhYmFzZSBjbGll
bnQgaXMgcmVzcG9uc2libGUgZm9yIGdlbmVyYXRpbmcgYW5kIHBhcnNpbmcKIHRoaXMgZGF0
YS4KCiBBbnkgZXJyb3JzIG9uIGluaXRpYWwgY29ubmVjdGlvbiAoZS5nLiwgY29ubmVjdGlv
biBmYWlsdXJlLCBhdXRob3JpemF0aW9uCiBpc3N1ZXMsIG5ldHdvcmsgcHJvYmxlbXMpIHdp
bGwgcmVzdWx0IGluIHRoZSBzdHJlYW0gYmVpbmcgdGVybWluYXRlZCB3aXRoCiBhbiBhcHBy
b3ByaWF0ZSBSUEMgc3RhdHVzIGV4Y2VwdGlvbi4KCiBBZnRlciBhIHN1Y2Nlc3NmdWwgY29u
bmVjdGlvbiBpcyBtYWRlLCBpZiBhbiBlcnJvciBvY2N1cnMsIHRoZW4gdGhlIHNlcnZlcgog
dGVybWluYXRlcyBjb25uZWN0aW9uIGFuZCByZXR1cm5zIHRoZSBhcHByb3ByaWF0ZSBSUEMg
c3RhdHVzIGV4Y2VwdGlvbi4KCiBBZGQgdGhlIHJlcXVlc3QgcGFyYW1zIGhlYWRlcnMgdG8g
dGhlIHJlcXVlc3QgdG8gZW5zdXJlIHRoYXQKIHRoZSBzdHJlYW1pbmcgcmVxdWVzdCBpcyBy
b3V0ZWQgdG8gdGhlIGNvcnJlY3Qgc2VydmljZSBmb3IgeW91ciBkYXRhYmFzZS4KCiBVc2Ug
dGhpcyBmb3JtYXQgZm9yIHRoZSByZXF1ZXN0IHBhcmFtcyBoZWFkZXI6CgogICAgYHgtZ29v
Zy1yZXF1ZXN0LXBhcmFtc2A6CiAgICAgICAgbG9jYXRpb25faWQ9e2xvY2F0aW9uX3BhdGh9
Jmluc3RhbmNlX2lkPXtpbnN0YW5jZV9wYXRofWAKCiAgYGxvY2F0aW9uX3BhdGhgIGlzIGBs
b2NhdGlvbnMve2xvY2F0aW9uX25hbWV9YAogIGBpbnN0YW5jZV9wYXRoYCBpcyBgcHJvamVj
dHMve3Byb2plY3RfbmFtZX0vaW5zdGFuY2VzL3tpbnN0YW5jZV9uYW1lfWAKCiBmb3IgZXhh
bXBsZToKICAgICBgeC1nb29nLXJlcXVlc3QtcGFyYW1zYDoKICAgICBgbG9jYXRpb25faWQ9
bG9jYXRpb25zL3VzLWNlbnRyYWwxJmluc3RhbmNlX2lkPXByb2plY3RzL215cHJvamVjdC9p
bnN0YW5jZXMvaW5zdGFuY2VuYW1lYAoKDAoFBgACAAESA0gGEwoMCgUGAAIABRIDSBQaCgwK
BQYAAgACEgNIGy8KDAoFBgACAAYSA0kPFQoMCgUGAAIAAxIDSRYrCj8KAgQAEgRNAGwBGjMg
TWVzc2FnZSBzZW50IGZyb20gdGhlIGNsaWVudCB0byBgU3FsRGF0YVNlcnZpY2VgLgoKCgoD
BAABEgNNCBwKQgoEBAACABIDTwI3GjUgT3B0aW9uYWwuIEFja25vd2xlZGdlcyBkYXRhIHJl
Y2VpdmVkIGJ5IHRoZSBjbGllbnQuCgoMCgUEAAIABhIDTwIFCgwKBQQAAgABEgNPBgkKDAoF
BAACAAMSA08MDQoMCgUEAAIACBIDTw42Cg8KCAQAAgAInAgAEgNPDzUKKgoEBAAIABIEUgJg
AxocIFRoZSBtZXNzYWdlIHRvIHRoZSBzZXJ2ZXIuCgoMCgUEAAgAARIDUggPCm4KBAQAAgES
A1UEIxphIFN0YXJ0cyBhIG5ldyBzZXNzaW9uLiBXaGVuIHN0YXJ0aW5nIGEgbmV3IHNlc3Np
b24sIHRoaXMgaXMgdGhlIGZpcnN0CiBtZXNzYWdlIHRoZSBjbGllbnQgc2VuZHMuCgoMCgUE
AAIBBhIDVQQQCgwKBQQAAgEBEgNVER4KDAoFBAACAQMSA1UhIgp/CgQEAAICEgNZBCkaciBD
b250aW51ZXMgYW4gZXhpc3Rpbmcgc2Vzc2lvbi4gV2hlbiBjb250aW51aW5nIGFuIGV4aXN0
aW5nIHNlc3Npb24sIHRoaXMKIGlzIHRoZSBmaXJzdCBtZXNzYWdlIHRoZSBjbGllbnQgc2Vu
ZHMuCgoMCgUEAAICBhIDWQQTCgwKBQQAAgIBEgNZFCQKDAoFBAACAgMSA1knKAodCgQEAAID
EgNcBBgaECBEYXRhYmFzZSBkYXRhLgoKDAoFBAACAwYSA1wEDgoMCgUEAAIDARIDXA8TCgwK
BQQAAgMDEgNcFhcKUgoEBAACBBIDXwQrGkUgVGVybWluYXRlcyB0aGUgc2Vzc2lvbi4gVGhp
cyBjbG9zZXMgdGhlIGNvbm5lY3Rpb24gdG8gdGhlIGRhdGFiYXNlLgoKDAoFBAACBAYSA18E
FAoMCgUEAAIEARIDXxUmCgwKBQQAAgQDEgNfKSoK2QEKBAQAAgUSBGYCawQaygEgT3B0aW9u
YWwuIERlcHJlY2F0ZWQ6IFVzZSBgU3RhcnRTZXNzaW9uLmluc3RhbmNlX2lkYCBvcgogYENv
bnRpbnVlU2Vzc2lvbi5pbnN0YW5jZV9pZGAgaW5zdGVhZC4KIFRoZSBDbG91ZCBTUUwgaW5z
dGFuY2UgcmVzb3VyY2UgbmFtZSwgZm9yIGV4YW1wbGU6CiBwcm9qZWN0cy9leGFtcGxlLXBy
b2plY3QvaW5zdGFuY2VzL2V4YW1wbGUtaW5zdGFuY2UKCgwKBQQAAgUFEgNmAggKDAoFBAAC
BQESA2YJFAoMCgUEAAIFAxIDZhcYCg0KBQQAAgUIEgRmGWsDCg8KCAQAAgUInAgAEgNnBCoK
DwoHBAACBQifCBIEaARqBQrWAQoCBAESBXEAhQEBGsgBIFN0YXJ0IGEgbmV3IHNlc3Npb24u
IFRoZSBjbGllbnQgbXVzdCBzZW5kIHRoaXMgYXMgdGhlIGZpcnN0IG1lc3NhZ2UgdG8gdGhl
CiBzZXJ2ZXIgdG8gc3RhcnQgYSBuZXcgc2Vzc2lvbi4gVGhlIGNsaWVudCBtYXkgaW1tZWRp
YXRlbHkgc2VuZCBEYXRhIG1lc3NhZ2VzCiB3aXRob3V0IHdhaXRpbmcgZm9yIGEgcmVwbHkg
ZnJvbSB0aGUgc2VydmVyLgoKCgoDBAEBEgNxCBQK5QEKBAQBAgASA3YCQhrXASBSZXF1aXJl
ZC4gYGxvY2F0aW9uX2lkYCBpcyB1c2VkIHRvIHJvdXRlIHRoZQogcmVxdWVzdCB0byBhIHNw
ZWNpZmljIHJlZ2lvbi4gVXNlIHRoZSBzYW1lIHJlZ2lvbiB3aGljaCB3YXMgdXNlZCB0byBj
cmVhdGUKIHRoZSBpbnN0YW5jZS4gVXNlIHRoZSBmb3JtYXQgYGxvY2F0aW9ucy97bG9jYXRp
b259YCwgZm9yIGV4YW1wbGU6CiBgbG9jYXRpb25zL3VzLWNlbnRyYWwxYC4KCgwKBQQBAgAF
EgN2AggKDAoFBAECAAESA3YJFAoMCgUEAQIAAxIDdhcYCgwKBQQBAgAIEgN2GUEKDwoIBAEC
AAicCAASA3YaQAqBAQoEBAECARIEegJ/BBpzIFJlcXVpcmVkLiBUaGUgQ2xvdWQgU1FMIGlu
c3RhbmNlIHJlc291cmNlIG5hbWUsIGZvciBleGFtcGxlOgogcHJvamVjdHMvZXhhbXBsZS1w
cm9qZWN0L2luc3RhbmNlcy9leGFtcGxlLWluc3RhbmNlCgoMCgUEAQIBBRIDegIICgwKBQQB
AgEBEgN6CRQKDAoFBAECAQMSA3oXGAoNCgUEAQIBCBIEehl/AwoPCggEAQIBCJwIABIDewQq
Cg8KBwQBAgEInwgSBHwEfgUKywEKBAQBAgISBIQBAkEavAEgT3B0aW9uYWwuIFRoZSBzZXNz
aW9uIGlkLCBjaG9zZW4gYnkgdGhlIGNsaWVudC4gVGhpcyBzaG91bGQgYmUgYW4KIHVuZ3Vl
c3NhYmxlIHN0cmluZy4gSWYgdGhlIGNsaWVudCBkb2VzIG5vdCBpbnRlbmQgdG8gcmVjb25u
ZWN0IHRvIHRoaXMKIHNlc3Npb24sIHRoZSBjbGllbnQgbWF5IGxlYXZlIHNlc3Npb25faWQg
dW5zZXQuCgoNCgUEAQICBRIEhAECCAoNCgUEAQICARIEhAEJEwoNCgUEAQICAxIEhAEWFwoN
CgUEAQICCBIEhAEYQAoQCggEAQICCJwIABIEhAEZPwryAQoCBAISBooBAJwBARrjASBSZWNv
bm5lY3RzIHRvIGFuIGV4aXN0aW5nIHNlc3Npb24uIFRoZSBjbGllbnQgbXVzdCBzZW5kIHRo
aXMgYXMgdGhlIGZpcnN0CiBtZXNzYWdlIHRvIHRoZSBzZXJ2ZXIgdG8gcmVjb25uZWN0IHRv
IGFuIGV4aXN0aW5nIHNlc3Npb24uIFRoZSBjbGllbnQgbWF5CiBpbW1lZGlhdGVseSBzZW5k
IERhdGEgbWVzc2FnZXMgd2l0aG91dCB3YWl0aW5nIGZvciBhIHJlcGx5IGZyb20gdGhlIHNl
cnZlci4KCgsKAwQCARIEigEIFwrmAQoEBAICABIEjwECQhrXASBSZXF1aXJlZC4gYGxvY2F0
aW9uX2lkYCBpcyB1c2VkIHRvIHJvdXRlIHRoZQogcmVxdWVzdCB0byBhIHNwZWNpZmljIHJl
Z2lvbi4gVXNlIHRoZSBzYW1lIHJlZ2lvbiB3aGljaCB3YXMgdXNlZCB0byBjcmVhdGUKIHRo
ZSBpbnN0YW5jZS4gVXNlIHRoZSBmb3JtYXQgYGxvY2F0aW9ucy97bG9jYXRpb259YCwgZm9y
IGV4YW1wbGU6CiBgbG9jYXRpb25zL3VzLWNlbnRyYWwxYC4KCg0KBQQCAgAFEgSPAQIICg0K
BQQCAgABEgSPAQkUCg0KBQQCAgADEgSPARcYCg0KBQQCAgAIEgSPARlBChAKCAQCAgAInAgA
EgSPARpACoMBCgQEAgIBEgaTAQKYAQQacyBSZXF1aXJlZC4gVGhlIENsb3VkIFNRTCBpbnN0
YW5jZSByZXNvdXJjZSBuYW1lLCBmb3IgZXhhbXBsZToKIHByb2plY3RzL2V4YW1wbGUtcHJv
amVjdC9pbnN0YW5jZXMvZXhhbXBsZS1pbnN0YW5jZQoKDQoFBAICAQUSBJMBAggKDQoFBAIC
AQESBJMBCRQKDQoFBAICAQMSBJMBFxgKDwoFBAICAQgSBpMBGZgBAwoQCggEAgIBCJwIABIE
lAEEKgoRCgcEAgIBCJ8IEgaVAQSXAQUKPQoEBAICAhIEmwECQRovIFJlcXVpcmVkLiBUaGUg
aWQgb2YgdGhlIHNlc3Npb24gdG8gcmVjb25uZWN0LgoKDQoFBAICAgUSBJsBAggKDQoFBAIC
AgESBJsBCRMKDQoFBAICAgMSBJsBFhcKDQoFBAICAggSBJsBGEAKEAoIBAICAgicCAASBJsB
GT8KRAoCBAMSBp8BALEBARo2IE1lc3NhZ2Ugc2VudCBmcm9tIFNxbERhdGFTZXJ2aWNlIGJh
Y2sgdG8gdGhlIGNsaWVudC4KCgsKAwQDARIEnwEIHQo5CgQEAwIAEgShAQIOGisgQWNrbm93
bGVkZ2VzIGRhdGEgcmVjZWl2ZWQgYnkgdGhlIHNlcnZlci4KCg0KBQQDAgAGEgShAQIFCg0K
BQQDAgABEgShAQYJCg0KBQQDAgADEgShAQwNCjoKBAQDCAASBqQBArABAxoqIEEgbWVzc2Fn
ZSBmcm9tIHRoZSBzZXJ2ZXIgdG8gdGhlIGNsaWVudC4KCg0KBQQDCAABEgSkAQgPCmkKBAQD
AgESBKcBBCkaWyBUaGUgZmlyc3QgbWVzc2FnZSBmcm9tIHRoZSBzZXJ2ZXIgdG8gdGhlIGNs
aWVudCwgY29udGFpbmluZyBtZXRhZGF0YQogYWJvdXQgdGhpcyBzZXNzaW9uLgoKDQoFBAMC
AQYSBKcBBBMKDQoFBAMCAQESBKcBFCQKDQoFBAMCAQMSBKcBJygKJwoEBAMCAhIEqgEEGBoZ
IERhdGEgZnJvbSB0aGUgZGF0YWJhc2UuCgoNCgUEAwICBhIEqgEEDgoNCgUEAwICARIEqgEP
EwoNCgUEAwICAxIEqgEWFwqsAQoEBAMCAxIErwEEKxqdASBUZXJtaW5hdGVzIHRoZSBzZXNz
aW9uLiBUaGlzIGluZGljYXRlcyB0aGF0IHRoZSBkYXRhYmFzZSBjb25uZWN0aW9uCiBpcyBj
bG9zZWQuIFdoZW4gdGhlIGNsaWVudCByZWNlaXZlcyB0aGlzIG1lc3NhZ2UsIGl0IHNob3Vs
ZCBub3QKIGF0dGVtcHQgdG8gcmVjb25uZWN0LgoKDQoFBAMCAwYSBK8BBBQKDQoFBAMCAwES
BK8BFSYKDQoFBAMCAwMSBK8BKSoKgAEKAgQEEga1AQC6AQEaciBNZXRhZGF0YSBmcm9tIHRo
ZSBzZXJ2ZXIgdG8gdGhlIGNsaWVudCBhYm91dCB0aGUgc2Vzc2lvbi4gVGhlIHNlcnZlciB3
aWxsCiBhbHdheXMgc2VuZCB0aGlzIGFzIHRoZSBmaXJzdCBtZXNzYWdlCgoLCgMEBAESBLUB
CBcK2gEKBAQEAgASBLkBAjEaywEgVGhlIGZlYXR1cmVzIHN1cHBvcnRlZCBieSB0aGUgc2Vy
dmVyIGZvciB0aGlzIHNlc3Npb24uIFRoaXMgZmllbGQgaXMgdXNlZAogYnkgdGhlIGNsaWVu
dCB0byBkZXRlcm1pbmUgd2hpY2ggZmVhdHVyZXMgYXJlIGF2YWlsYWJsZSBvbiB0aGUgc2Vy
dmVyLgogVGhlIGZlYXR1cmVzIHN1cHBvcnRlZCBieSB0aGUgc2VydmVyIGZvciB0aGlzIHNl
c3Npb24uCgoNCgUEBAIABBIEuQECCgoNCgUEBAIABhIEuQELGQoNCgUEBAIAARIEuQEaLAoN
CgUEBAIAAxIEuQEvMApFCgIEBRIGvQEAxQEBGjcgQ29udGFpbnMgZGF0YSBiZWluZyBzZW50
IG9yIHJlY2VpdmVkIGJ5IHRoZSBkYXRhYmFzZS4KCgsKAwQFARIEvQEIEgrPAQoEBAUCABIE
wQECRxrAASBPcHRpb25hbC4gVGhlIGFic29sdXRlIGJ5dGUgb2Zmc2V0IG9mIHRoZSBmaXJz
dCBieXRlIGluIHRoaXMgcGF5bG9hZC4KIDAgZm9yIG5ldyBjb25uZWN0aW9ucyBvciByZXN1
bWVkIGNvbm5lY3Rpb25zIHRoYXQgaGFzbid0IGFja2VkIGFueSBieXRlcwogZnJvbSBzZXJ2
ZXIuIE5vbi16ZXJvIGZvciByZXN1bWVkIGNvbm5lY3Rpb25zCgoNCgUEBQIABRIEwQECBwoN
CgUEBQIAARIEwQEIGQoNCgUEBQIAAxIEwQEcHQoNCgUEBQIACBIEwQEeRgoQCggEBQIACJwI
ABIEwQEfRQpKCgQEBQIBEgTEAQI6GjwgUmVxdWlyZWQuIFJhdyBkYXRhIGJlaW5nIHNlbnQg
b3IgcmVjZWl2ZWQgYnkgdGhlIGRhdGFiYXNlLgoKDQoFBAUCAQUSBMQBAgcKDQoFBAUCAQES
BMQBCAwKDQoFBAUCAQMSBMQBDxAKDQoFBAUCAQgSBMQBETkKEAoIBAUCAQicCAASBMQBEjgK
QwoCBAYSBsgBAMsBARo1IEFja25vd2xlZGdlcyBkYXRhIHJlY2VpdmVkIGJ5IHRoZSBjbGll
bnQgb3Igc2VydmVyLgoKCwoDBAYBEgTIAQgLClAKBAQGAgASBMoBAkUaQiBSZXF1aXJlZC4g
VGhlIGFic29sdXRlIG51bWJlciBvZiBieXRlcyBwcm9jZXNzZWQgaW4gdGhlIHNlc3Npb24u
CgoNCgUEBgIABRIEygECBwoNCgUEBgIAARIEygEIFwoNCgUEBgIAAxIEygEaGwoNCgUEBgIA
CBIEygEcRAoQCggEBgIACJwIABIEygEdQwpACgIEBxIGzgEA0QEBGjIgSW5kaWNhdGVzIHRo
YXQgdGhlIHNlc3Npb24gaXMgcGVybWFuZW50bHkgZW5kZWQuCgoLCgMEBwESBM4BCBgKOQoE
BAcCABIE0AECSBorIFJlcXVpcmVkLiBUaGUgc2Vzc2lvbiB0ZXJtaW5hdGlvbiBzdGF0dXMu
CgoNCgUEBwIABhIE0AECEwoNCgUEBwIAARIE0AEUGgoNCgUEBwIAAxIE0AEdHgoNCgUEBwIA
CBIE0AEfRwoQCggEBwIACJwIABIE0AEgRgp2CgIFABIG1QEA3AEBGmggVGhlIHNlc3Npb24g
ZmVhdHVyZXMuIFRoZSBzZXJ2ZXIgbXVzdCBzZW5kIHRoZSBzdXBwb3J0ZWQgZmVhdHVyZXMg
aW4gaXRzCiBmaXJzdCBtZXNzYWdlIHRvIHRoZSBjbGllbnQuCgoLCgMFAAESBNUBBRMKTAoE
BQACABIE1wECIxo+IFRoZSBmZWF0dXJlIGlzIG5vdCBzcGVjaWZpZWQuIFRoaXMgdmFsdWUg
c2hvdWxkIG5vdCBiZSB1c2VkLgoKDQoFBQACAAESBNcBAh4KDQoFBQACAAISBNcBISIKnQEK
BAUAAgESBNsBAiEajgEgVGhlIHNlcnZlciBzdXBwb3J0cyByZWNvbm5lY3RpbmcgdG8gdGhl
IHNlc3Npb24uIElmIHRoaXMgZmVhdHVyZSBpcyBub3QKIHByZXNlbnQsIHRoZSBjbGllbnQg
c2hvdWxkIG5vdCBhdHRlbXB0IHRvIHJlY29ubmVjdCB0byB0aGUgc2Vzc2lvbi4KCg0KBQUA
AgEBEgTbAQIcCg0KBQUAAgECEgTbAR8gYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest ===
    # Fields for StreamSqlDataRequest
    # Field: ack Type: 11 (.google.cloud.sql.v1beta4.Ack)
    # Field: start_session Type: 11 (.google.cloud.sql.v1beta4.StartSession)
    # Field: continue_session Type: 11 (.google.cloud.sql.v1beta4.ContinueSession)
    # Field: data Type: 11 (.google.cloud.sql.v1beta4.DataPacket)
    # Field: terminate_session Type: 11 (.google.cloud.sql.v1beta4.TerminateSession)
    # Field: instance_id Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::StartSession ===
    # Fields for StartSession
    # Field: location_id Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: session_id Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::ContinueSession ===
    # Fields for ContinueSession
    # Field: location_id Type: 9 ()
    # Field: instance_id Type: 9 ()
    # Field: session_id Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse ===
    # Fields for StreamSqlDataResponse
    # Field: ack Type: 11 (.google.cloud.sql.v1beta4.Ack)
    # Field: session_metadata Type: 11 (.google.cloud.sql.v1beta4.SessionMetadata)
    # Field: data Type: 11 (.google.cloud.sql.v1beta4.DataPacket)
    # Field: terminate_session Type: 11 (.google.cloud.sql.v1beta4.TerminateSession)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::SessionMetadata ===
    # Fields for SessionMetadata
    # Field: supported_features Type: 14 (.google.cloud.sql.v1beta4.SqlDataFeature)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket ===
    # Fields for DataPacket
    # Field: first_byte_offset Type: 3 ()
    # Field: data Type: 12 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::Ack ===
    # Fields for Ack
    # Field: received_offset Type: 3 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession ===
    # Fields for TerminateSession
    # Field: status Type: 11 (.google.rpc.Status)

# === Service Client: Google::Cloud::Sql::V1beta4::CloudSqlData::SqlDataServiceClient ===
package Google::Cloud::Sql::V1beta4::CloudSqlData::SqlDataServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1beta4::CloudSqlData::SqlDataServiceClient

Client stub representing the remote C<SqlDataService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub stream_sql_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlDataService',
        method         => 'StreamSqlData',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlData - Compiled Protocol Buffers messages for google/cloud/sql/v1beta4/cloud_sql_data.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4::CloudSqlData;

    my $msg = Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest->new({
        ack => $ack,
        start_session => $start_session,
        continue_session => $continue_session,
        data => $data,
    });

    # Read or update a field
    my $val = $msg->ack();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1beta4/cloud_sql_data.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest

Message sent from the client to `SqlDataService`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ack() >> / C<< $msg->ack($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::Ack>)

Optional. Acknowledges data received by the client.

=item * C<< $msg->start_session() >> / C<< $msg->start_session($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::StartSession>)

Starts a new session. When starting a new session, this is the first
message the client sends.

=item * C<< $msg->continue_session() >> / C<< $msg->continue_session($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::ContinueSession>)

Continues an existing session. When continuing an existing session, this
is the first message the client sends.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket>)

Database data.

=item * C<< $msg->terminate_session() >> / C<< $msg->terminate_session($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession>)

Terminates the session. This closes the connection to the database.

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Optional. Deprecated: Use `StartSession.instance_id` or
`ContinueSession.instance_id` instead.
The Cloud SQL instance resource name, for example:
projects/example-project/instances/example-instance

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::StartSession

Start a new session. The client must send this as the first message to the
server to start a new session. The client may immediately send Data messages
without waiting for a reply from the server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

Required. `location_id` is used to route the
request to a specific region. Use the same region which was used to create
the instance. Use the format `locations/{location}`, for example:
`locations/us-central1`.

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Required. The Cloud SQL instance resource name, for example:
projects/example-project/instances/example-instance

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

Optional. The session id, chosen by the client. This should be an
unguessable string. If the client does not intend to reconnect to this
session, the client may leave session_id unset.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::ContinueSession

Reconnects to an existing session. The client must send this as the first
message to the server to reconnect to an existing session. The client may
immediately send Data messages without waiting for a reply from the server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

Required. `location_id` is used to route the
request to a specific region. Use the same region which was used to create
the instance. Use the format `locations/{location}`, for example:
`locations/us-central1`.

=item * C<< $msg->instance_id() >> / C<< $msg->instance_id($value) >>

Type: C<String>

Required. The Cloud SQL instance resource name, for example:
projects/example-project/instances/example-instance

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

Required. The id of the session to reconnect.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse

Message sent from SqlDataService back to the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ack() >> / C<< $msg->ack($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::Ack>)

Acknowledges data received by the server.

=item * C<< $msg->session_metadata() >> / C<< $msg->session_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::SessionMetadata>)

The first message from the server to the client, containing metadata
about this session.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket>)

Data from the database.

=item * C<< $msg->terminate_session() >> / C<< $msg->terminate_session($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession>)

Terminates the session. This indicates that the database connection
is closed. When the client receives this message, it should not
attempt to reconnect.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::SessionMetadata

Metadata from the server to the client about the session. The server will
always send this as the first message

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->supported_features() >> / C<< $msg->supported_features($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::SqlDataFeature>)

The features supported by the server for this session. This field is used
by the client to determine which features are available on the server.
The features supported by the server for this session.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket

Contains data being sent or received by the database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->first_byte_offset() >> / C<< $msg->first_byte_offset($value) >>

Type: C<Int64>

Optional. The absolute byte offset of the first byte in this payload.
0 for new connections or resumed connections that hasn't acked any bytes
from server. Non-zero for resumed connections

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

Required. Raw data being sent or received by the database.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::Ack

Acknowledges data received by the client or server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->received_offset() >> / C<< $msg->received_offset($value) >>

Type: C<Int64>

Required. The absolute number of bytes processed in the session.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession

Indicates that the session is permanently ended.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Required. The session termination status.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1beta4::CloudSqlData::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
