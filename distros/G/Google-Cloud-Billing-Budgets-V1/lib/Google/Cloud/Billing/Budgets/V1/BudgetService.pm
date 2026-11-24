package Google::Cloud::Billing::Budgets::V1::BudgetService;

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
    eval { require Google::Cloud::Billing::Budgets::V1::BudgetModel };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvYmlsbGluZy9idWRnZXRzL3YxL2J1ZGdldF9zZXJ2aWNlLnByb3Rv
Eh9nb29nbGUuY2xvdWQuYmlsbGluZy5idWRnZXRzLnYxGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoyZ29vZ2xlL2Nsb3Vk
L2JpbGxpbmcvYnVkZ2V0cy92MS9idWRnZXRfbW9kZWwucHJvdG8aG2dvb2dsZS9wcm90b2J1
Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8ioQEKE0Ny
ZWF0ZUJ1ZGdldFJlcXVlc3QSRAoGcGFyZW50GAEgASgJQizgQQL6QSYSJGJpbGxpbmdidWRn
ZXRzLmdvb2dsZWFwaXMuY29tL0J1ZGdldFIGcGFyZW50EkQKBmJ1ZGdldBgCIAEoCzInLmdv
b2dsZS5jbG91ZC5iaWxsaW5nLmJ1ZGdldHMudjEuQnVkZ2V0QgPgQQJSBmJ1ZGdldCKdAQoT
VXBkYXRlQnVkZ2V0UmVxdWVzdBJECgZidWRnZXQYASABKAsyJy5nb29nbGUuY2xvdWQuYmls
bGluZy5idWRnZXRzLnYxLkJ1ZGdldEID4EECUgZidWRnZXQSQAoLdXBkYXRlX21hc2sYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siVAoQR2V0
QnVkZ2V0UmVxdWVzdBJACgRuYW1lGAEgASgJQizgQQL6QSYKJGJpbGxpbmdidWRnZXRzLmdv
b2dsZWFwaXMuY29tL0J1ZGdldFIEbmFtZSK7AQoSTGlzdEJ1ZGdldHNSZXF1ZXN0EkQKBnBh
cmVudBgBIAEoCUIs4EEC+kEmEiRiaWxsaW5nYnVkZ2V0cy5nb29nbGVhcGlzLmNvbS9CdWRn
ZXRSBnBhcmVudBIZCgVzY29wZRgEIAEoCUID4EEBUgVzY29wZRIgCglwYWdlX3NpemUYAiAB
KAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4i
gAEKE0xpc3RCdWRnZXRzUmVzcG9uc2USQQoHYnVkZ2V0cxgBIAMoCzInLmdvb2dsZS5jbG91
ZC5iaWxsaW5nLmJ1ZGdldHMudjEuQnVkZ2V0UgdidWRnZXRzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJXChNEZWxldGVCdWRnZXRSZXF1ZXN0EkAKBG5hbWUY
ASABKAlCLOBBAvpBJgokYmlsbGluZ2J1ZGdldHMuZ29vZ2xlYXBpcy5jb20vQnVkZ2V0UgRu
YW1lMvcHCg1CdWRnZXRTZXJ2aWNlErUBCgxDcmVhdGVCdWRnZXQSNC5nb29nbGUuY2xvdWQu
YmlsbGluZy5idWRnZXRzLnYxLkNyZWF0ZUJ1ZGdldFJlcXVlc3QaJy5nb29nbGUuY2xvdWQu
YmlsbGluZy5idWRnZXRzLnYxLkJ1ZGdldCJGgtPkkwIwIiYvdjEve3BhcmVudD1iaWxsaW5n
QWNjb3VudHMvKn0vYnVkZ2V0czoGYnVkZ2V02kENcGFyZW50LGJ1ZGdldBLBAQoMVXBkYXRl
QnVkZ2V0EjQuZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0cy52MS5VcGRhdGVCdWRnZXRS
ZXF1ZXN0GicuZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0cy52MS5CdWRnZXQiUoLT5JMC
NzItL3YxL3tidWRnZXQubmFtZT1iaWxsaW5nQWNjb3VudHMvKi9idWRnZXRzLyp9OgZidWRn
ZXTaQRJidWRnZXQsdXBkYXRlX21hc2sSngEKCUdldEJ1ZGdldBIxLmdvb2dsZS5jbG91ZC5i
aWxsaW5nLmJ1ZGdldHMudjEuR2V0QnVkZ2V0UmVxdWVzdBonLmdvb2dsZS5jbG91ZC5iaWxs
aW5nLmJ1ZGdldHMudjEuQnVkZ2V0IjWC0+STAigSJi92MS97bmFtZT1iaWxsaW5nQWNjb3Vu
dHMvKi9idWRnZXRzLyp92kEEbmFtZRKxAQoLTGlzdEJ1ZGdldHMSMy5nb29nbGUuY2xvdWQu
YmlsbGluZy5idWRnZXRzLnYxLkxpc3RCdWRnZXRzUmVxdWVzdBo0Lmdvb2dsZS5jbG91ZC5i
aWxsaW5nLmJ1ZGdldHMudjEuTGlzdEJ1ZGdldHNSZXNwb25zZSI3gtPkkwIoEiYvdjEve3Bh
cmVudD1iaWxsaW5nQWNjb3VudHMvKn0vYnVkZ2V0c9pBBnBhcmVudBKTAQoMRGVsZXRlQnVk
Z2V0EjQuZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0cy52MS5EZWxldGVCdWRnZXRSZXF1
ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IjWC0+STAigqJi92MS97bmFtZT1iaWxsaW5n
QWNjb3VudHMvKi9idWRnZXRzLyp92kEEbmFtZRp/ykEdYmlsbGluZ2J1ZGdldHMuZ29vZ2xl
YXBpcy5jb23SQVxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLWJpbGxp
bmcsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJ6CiNj
b20uZ29vZ2xlLmNsb3VkLmJpbGxpbmcuYnVkZ2V0cy52MUISQnVkZ2V0U2VydmljZVByb3Rv
UAFaPWNsb3VkLmdvb2dsZS5jb20vZ28vYmlsbGluZy9idWRnZXRzL2FwaXYxL2J1ZGdldHNw
YjtidWRnZXRzcGJK2C4KBxIFDgC+AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
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
c2UuCgoICgECEgMQACgKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMS
AxUAIwoJCgIDBBIDFgA8CgkKAgMFEgMXACUKCQoCAwYSAxgAKgoICgEIEgMaAFQKCQoCCAsS
AxoAVAoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADMKCQoCCAgSAxwAMwoICgEIEgMd
ADwKCQoCCAESAx0APAqQAQoCBgASBCEAYAEagwEgQnVkZ2V0U2VydmljZSBzdG9yZXMgQ2xv
dWQgQmlsbGluZyBidWRnZXRzLCB3aGljaCBkZWZpbmUgYQogYnVkZ2V0IHBsYW4gYW5kIHJ1
bGVzIHRvIGV4ZWN1dGUgYXMgd2UgdHJhY2sgc3BlbmQgYWdhaW5zdCB0aGF0IHBsYW4uCgoK
CgMGAAESAyEIFQoKCgMGAAMSAyICRQoMCgUGAAOZCBIDIgJFCgsKAwYAAxIEIwIlNwoNCgUG
AAOaCBIEIwIlNwq1AQoEBgACABIEKgIwAxqmASBDcmVhdGVzIGEgbmV3IGJ1ZGdldC4gU2Vl
CiBbUXVvdGFzIGFuZCBsaW1pdHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9iaWxsaW5n
L3F1b3RhcykKIGZvciBtb3JlIGluZm9ybWF0aW9uIG9uIHRoZSBsaW1pdHMgb2YgdGhlIG51
bWJlciBvZiBidWRnZXRzIHlvdSBjYW4gY3JlYXRlLgoKDAoFBgACAAESAyoGEgoMCgUGAAIA
AhIDKhMmCgwKBQYAAgADEgMqMTcKDQoFBgACAAQSBCsELgYKEQoJBgACAASwyrwiEgQrBC4G
CgwKBQYAAgAEEgMvBDsKDwoIBgACAASbCAASAy8EOwr+AQoEBgACARIENwI9AxrvASBVcGRh
dGVzIGEgYnVkZ2V0IGFuZCByZXR1cm5zIHRoZSB1cGRhdGVkIGJ1ZGdldC4KCiBXQVJOSU5H
OiBUaGVyZSBhcmUgc29tZSBmaWVsZHMgZXhwb3NlZCBvbiB0aGUgR29vZ2xlIENsb3VkIENv
bnNvbGUgdGhhdAogYXJlbid0IGF2YWlsYWJsZSBvbiB0aGlzIEFQSS4gQnVkZ2V0IGZpZWxk
cyB0aGF0IGFyZSBub3QgZXhwb3NlZCBpbgogdGhpcyBBUEkgd2lsbCBub3QgYmUgY2hhbmdl
ZCBieSB0aGlzIG1ldGhvZC4KCgwKBQYAAgEBEgM3BhIKDAoFBgACAQISAzcTJgoMCgUGAAIB
AxIDNzE3Cg0KBQYAAgEEEgQ4BDsGChEKCQYAAgEEsMq8IhIEOAQ7BgoMCgUGAAIBBBIDPARA
Cg8KCAYAAgEEmwgAEgM8BEAKjwIKBAYAAgISBEUCSgMagAIgUmV0dXJucyBhIGJ1ZGdldC4K
CiBXQVJOSU5HOiBUaGVyZSBhcmUgc29tZSBmaWVsZHMgZXhwb3NlZCBvbiB0aGUgR29vZ2xl
IENsb3VkIENvbnNvbGUgdGhhdAogYXJlbid0IGF2YWlsYWJsZSBvbiB0aGlzIEFQSS4gV2hl
biByZWFkaW5nIGZyb20gdGhlIEFQSSwgeW91IHdpbGwgbm90CiBzZWUgdGhlc2UgZmllbGRz
IGluIHRoZSByZXR1cm4gdmFsdWUsIHRob3VnaCB0aGV5IG1heSBoYXZlIGJlZW4gc2V0CiBp
biB0aGUgQ2xvdWQgQ29uc29sZS4KCgwKBQYAAgIBEgNFBg8KDAoFBgACAgISA0UQIAoMCgUG
AAICAxIDRSsxCg0KBQYAAgIEEgRGBEgGChEKCQYAAgIEsMq8IhIERgRIBgoMCgUGAAICBBID
SQQyCg8KCAYAAgIEmwgAEgNJBDIKrgIKBAYAAgMSBFICVwManwIgUmV0dXJucyBhIGxpc3Qg
b2YgYnVkZ2V0cyBmb3IgYSBiaWxsaW5nIGFjY291bnQuCgogV0FSTklORzogVGhlcmUgYXJl
IHNvbWUgZmllbGRzIGV4cG9zZWQgb24gdGhlIEdvb2dsZSBDbG91ZCBDb25zb2xlIHRoYXQK
IGFyZW4ndCBhdmFpbGFibGUgb24gdGhpcyBBUEkuIFdoZW4gcmVhZGluZyBmcm9tIHRoZSBB
UEksIHlvdSB3aWxsIG5vdAogc2VlIHRoZXNlIGZpZWxkcyBpbiB0aGUgcmV0dXJuIHZhbHVl
LCB0aG91Z2ggdGhleSBtYXkgaGF2ZSBiZWVuIHNldAogaW4gdGhlIENsb3VkIENvbnNvbGUu
CgoMCgUGAAIDARIDUgYRCgwKBQYAAgMCEgNSEiQKDAoFBgACAwMSA1IvQgoNCgUGAAIDBBIE
UwRVBgoRCgkGAAIDBLDKvCISBFMEVQYKDAoFBgACAwQSA1YENAoPCggGAAIDBJsIABIDVgQ0
CkoKBAYAAgQSBFoCXwMaPCBEZWxldGVzIGEgYnVkZ2V0LiBSZXR1cm5zIHN1Y2Nlc3NmdWxs
eSBpZiBhbHJlYWR5IGRlbGV0ZWQuCgoMCgUGAAIEARIDWgYSCgwKBQYAAgQCEgNaEyYKDAoF
BgACBAMSA1oxRgoNCgUGAAIEBBIEWwRdBgoRCgkGAAIEBLDKvCISBFsEXQYKDAoFBgACBAQS
A14EMgoPCggGAAIEBJsIABIDXgQyCiYKAgQAEgRjAG8BGhogUmVxdWVzdCBmb3IgQ3JlYXRl
QnVkZ2V0CgoKCgMEAAESA2MIGwqRAQoEBAACABIEZgJrBBqCASBSZXF1aXJlZC4gVGhlIG5h
bWUgb2YgdGhlIGJpbGxpbmcgYWNjb3VudCB0byBjcmVhdGUgdGhlIGJ1ZGdldCBpbi4gVmFs
dWVzCiBhcmUgb2YgdGhlIGZvcm0gYGJpbGxpbmdBY2NvdW50cy97YmlsbGluZ0FjY291bnRJ
ZH1gLgoKDAoFBAACAAUSA2YCCAoMCgUEAAIAARIDZgkPCgwKBQQAAgADEgNmEhMKDQoFBAAC
AAgSBGYUawMKDwoIBAACAAicCAASA2cEKgoPCgcEAAIACJ8IEgRoBGoFCioKBAQAAgESA24C
PRodIFJlcXVpcmVkLiBCdWRnZXQgdG8gY3JlYXRlLgoKDAoFBAACAQYSA24CCAoMCgUEAAIB
ARIDbgkPCgwKBQQAAgEDEgNuEhMKDAoFBAACAQgSA24UPAoPCggEAAIBCJwIABIDbhU7CiYK
AgQBEgRyAH8BGhogUmVxdWVzdCBmb3IgVXBkYXRlQnVkZ2V0CgoKCgMEAQESA3IIGwp4CgQE
AQIAEgN1Aj0aayBSZXF1aXJlZC4gVGhlIHVwZGF0ZWQgYnVkZ2V0IG9iamVjdC4KIFRoZSBi
dWRnZXQgdG8gdXBkYXRlIGlzIHNwZWNpZmllZCBieSB0aGUgYnVkZ2V0IG5hbWUgaW4gdGhl
IGJ1ZGdldC4KCgwKBQQBAgAGEgN1AggKDAoFBAECAAESA3UJDwoMCgUEAQIAAxIDdRITCgwK
BQQBAgAIEgN1FDwKDwoIBAECAAicCAASA3UVOwrbAgoEBAECARIEfQJ+LxrMAiBPcHRpb25h
bC4gSW5kaWNhdGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQgYnVkZ2V0IHRvIHVw
ZGF0ZS4KIFJlYWQtb25seSBmaWVsZHMgKHN1Y2ggYXMgYG5hbWVgKSBjYW5ub3QgYmUgY2hh
bmdlZC4gSWYgdGhpcyBpcyBub3QKIHByb3ZpZGVkLCB0aGVuIG9ubHkgZmllbGRzIHdpdGgg
bm9uLWRlZmF1bHQgdmFsdWVzIGZyb20gdGhlIHJlcXVlc3QgYXJlCiB1cGRhdGVkLiBTZWUK
IGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9w
cm90bzMjZGVmYXVsdCBmb3IgbW9yZQogZGV0YWlscyBhYm91dCBkZWZhdWx0IHZhbHVlcy4K
CgwKBQQBAgEGEgN9AhsKDAoFBAECAQESA30cJwoMCgUEAQIBAxIDfSorCgwKBQQBAgEIEgN+
Bi4KDwoIBAECAQicCAASA34HLQolCgIEAhIGggEAiwEBGhcgUmVxdWVzdCBmb3IgR2V0QnVk
Z2V0CgoLCgMEAgESBIIBCBgKgwEKBAQCAgASBoUBAooBBBpzIFJlcXVpcmVkLiBOYW1lIG9m
IGJ1ZGdldCB0byBnZXQuIFZhbHVlcyBhcmUgb2YgdGhlIGZvcm0KIGBiaWxsaW5nQWNjb3Vu
dHMve2JpbGxpbmdBY2NvdW50SWR9L2J1ZGdldHMve2J1ZGdldElkfWAuCgoNCgUEAgIABRIE
hQECCAoNCgUEAgIAARIEhQEJDQoNCgUEAgIAAxIEhQEQEQoPCgUEAgIACBIGhQESigEDChAK
CAQCAgAInAgAEgSGAQQqChEKBwQCAgAInwgSBocBBIkBBQonCgIEAxIGjgEAqAEBGhkgUmVx
dWVzdCBmb3IgTGlzdEJ1ZGdldHMKCgsKAwQDARIEjgEIGgqIAQoEBAMCABIGkQEClgEEGngg
UmVxdWlyZWQuIE5hbWUgb2YgYmlsbGluZyBhY2NvdW50IHRvIGxpc3QgYnVkZ2V0cyB1bmRl
ci4gVmFsdWVzCiBhcmUgb2YgdGhlIGZvcm0gYGJpbGxpbmdBY2NvdW50cy97YmlsbGluZ0Fj
Y291bnRJZH1gLgoKDQoFBAMCAAUSBJEBAggKDQoFBAMCAAESBJEBCQ8KDQoFBAMCAAMSBJEB
EhMKDwoFBAMCAAgSBpEBFJYBAwoQCggEAwIACJwIABIEkgEEKgoRCgcEAwIACJ8IEgaTAQSV
AQUKzgMKBAQDAgESBJ4BAjwavwMgT3B0aW9uYWwuIFNldCB0aGUgc2NvcGUgb2YgdGhlIGJ1
ZGdldHMgdG8gYmUgcmV0dXJuZWQsIGluIHRoZSBmb3JtYXQgb2YgdGhlCiByZXNvdXJjZSBu
YW1lLiBUaGUgc2NvcGUgb2YgYSBidWRnZXQgaXMgdGhlIGNvc3QgdGhhdCBpdCB0cmFja3Ms
IHN1Y2ggYXMKIGNvc3RzIGZvciBhIHNpbmdsZSBwcm9qZWN0LCBvciB0aGUgY29zdHMgZm9y
IGFsbCBwcm9qZWN0cyBpbiBhIGZvbGRlci4gT25seQogcHJvamVjdCBzY29wZSAoaW4gdGhl
IGZvcm1hdCBvZiAicHJvamVjdHMvcHJvamVjdC1pZCIgb3IgInByb2plY3RzLzEyMyIpIGlz
CiBzdXBwb3J0ZWQgaW4gdGhpcyBmaWVsZC4gV2hlbiB0aGlzIGZpZWxkIGlzIHNldCB0byBh
IHByb2plY3QncyByZXNvdXJjZQogbmFtZSwgdGhlIGJ1ZGdldHMgcmV0dXJuZWQgYXJlIHRy
YWNraW5nIHRoZSBjb3N0cyBmb3IgdGhhdCBwcm9qZWN0LgoKDQoFBAMCAQUSBJ4BAggKDQoF
BAMCAQESBJ4BCQ4KDQoFBAMCAQMSBJ4BERIKDQoFBAMCAQgSBJ4BEzsKEAoIBAMCAQicCAAS
BJ4BFDoKcwoEBAMCAhIEogECPxplIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
YnVkZ2V0cyB0byByZXR1cm4gcGVyIHBhZ2UuCiBUaGUgZGVmYXVsdCBhbmQgbWF4aW11bSB2
YWx1ZSBhcmUgMTAwLgoKDQoFBAMCAgUSBKIBAgcKDQoFBAMCAgESBKIBCBEKDQoFBAMCAgMS
BKIBFBUKDQoFBAMCAggSBKIBFj4KEAoIBAMCAgicCAASBKIBFz0K1QEKBAQDAgMSBKcBAkEa
xgEgT3B0aW9uYWwuIFRoZSB2YWx1ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBgTGlzdEJ1ZGdl
dHNSZXNwb25zZWAgd2hpY2gKIGluZGljYXRlcyB0aGF0IHRoaXMgaXMgYSBjb250aW51YXRp
b24gb2YgYSBwcmlvciBgTGlzdEJ1ZGdldHNgIGNhbGwsCiBhbmQgdGhhdCB0aGUgc3lzdGVt
IHNob3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBkYXRhLgoKDQoFBAMCAwUSBKcBAggK
DQoFBAMCAwESBKcBCRMKDQoFBAMCAwMSBKcBFhcKDQoFBAMCAwgSBKcBGEAKEAoIBAMCAwic
CAASBKcBGT8KKAoCBAQSBqsBALIBARoaIFJlc3BvbnNlIGZvciBMaXN0QnVkZ2V0cwoKCwoD
BAQBEgSrAQgbCksKBAQEAgASBK0BAh4aPSBMaXN0IG9mIHRoZSBidWRnZXRzIG93bmVkIGJ5
IHRoZSByZXF1ZXN0ZWQgYmlsbGluZyBhY2NvdW50LgoKDQoFBAQCAAQSBK0BAgoKDQoFBAQC
AAYSBK0BCxEKDQoFBAQCAAESBK0BEhkKDQoFBAQCAAMSBK0BHB0KmwEKBAQEAgESBLEBAh0a
jAEgSWYgbm90IGVtcHR5LCBpbmRpY2F0ZXMgdGhhdCB0aGVyZSBtYXkgYmUgbW9yZSBidWRn
ZXRzIHRoYXQgbWF0Y2ggdGhlCiByZXF1ZXN0OyB0aGlzIHZhbHVlIHNob3VsZCBiZSBwYXNz
ZWQgaW4gYSBuZXcgYExpc3RCdWRnZXRzUmVxdWVzdGAuCgoNCgUEBAIBBRIEsQECCAoNCgUE
BAIBARIEsQEJGAoNCgUEBAIBAxIEsQEbHAooCgIEBRIGtQEAvgEBGhogUmVxdWVzdCBmb3Ig
RGVsZXRlQnVkZ2V0CgoLCgMEBQESBLUBCBsKigEKBAQFAgASBrgBAr0BBBp6IFJlcXVpcmVk
LiBOYW1lIG9mIHRoZSBidWRnZXQgdG8gZGVsZXRlLiBWYWx1ZXMgYXJlIG9mIHRoZSBmb3Jt
CiBgYmlsbGluZ0FjY291bnRzL3tiaWxsaW5nQWNjb3VudElkfS9idWRnZXRzL3tidWRnZXRJ
ZH1gLgoKDQoFBAUCAAUSBLgBAggKDQoFBAUCAAESBLgBCQ0KDQoFBAUCAAMSBLgBEBEKDwoF
BAUCAAgSBrgBEr0BAwoQCggEBQIACJwIABIEuQEEKgoRCgcEBQIACJ8IEga6AQS8AQViBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest ===
    # Fields for CreateBudgetRequest
    # Field: parent Type: 9 ()
    # Field: budget Type: 11 (.google.cloud.billing.budgets.v1.Budget)

# === Message: Google::Cloud::Billing::Budgets::V1::BudgetService::UpdateBudgetRequest ===
    # Fields for UpdateBudgetRequest
    # Field: budget Type: 11 (.google.cloud.billing.budgets.v1.Budget)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Billing::Budgets::V1::BudgetService::GetBudgetRequest ===
    # Fields for GetBudgetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsRequest ===
    # Fields for ListBudgetsRequest
    # Field: parent Type: 9 ()
    # Field: scope Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsResponse ===
    # Fields for ListBudgetsResponse
    # Field: budgets Type: 11 (.google.cloud.billing.budgets.v1.Budget)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Billing::Budgets::V1::BudgetService::DeleteBudgetRequest ===
    # Fields for DeleteBudgetRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Billing::Budgets::V1::BudgetService::BudgetServiceClient ===
package Google::Cloud::Billing::Budgets::V1::BudgetService::BudgetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Billing::Budgets::V1::BudgetService::BudgetServiceClient

Client stub representing the remote C<BudgetService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<billing.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'billing.googleapis.com:443' );

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

sub create_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1.BudgetService',
        method         => 'CreateBudget',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1::BudgetModel::Budget',
    });
}

sub update_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1::BudgetService::UpdateBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1.BudgetService',
        method         => 'UpdateBudget',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1::BudgetModel::Budget',
    });
}

sub get_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1::BudgetService::GetBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1.BudgetService',
        method         => 'GetBudget',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1::BudgetModel::Budget',
    });
}

sub list_budgets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1.BudgetService',
        method         => 'ListBudgets',
        request        => $req,
        response_class => 'Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsResponse',
    });
}

sub delete_budget {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::Budgets::V1::BudgetService::DeleteBudgetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.budgets.v1.BudgetService',
        method         => 'DeleteBudget',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Billing::Budgets::V1::BudgetService - Compiled Protocol Buffers messages for google/cloud/billing/budgets/v1/budget_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Billing::Budgets::V1::BudgetService;

    my $msg = Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest->new({
        parent => $parent,
        budget => $budget,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/billing/budgets/v1/budget_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest

Request for CreateBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the billing account to create the budget in. Values
are of the form `billingAccounts/{billingAccountId}`.

=item * C<< $msg->budget() >> / C<< $msg->budget($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1::BudgetModel::Budget>)

Required. Budget to create.

=back

=head2 Google::Cloud::Billing::Budgets::V1::BudgetService::UpdateBudgetRequest

Request for UpdateBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->budget() >> / C<< $msg->budget($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1::BudgetModel::Budget>)

Required. The updated budget object.
The budget to update is specified by the budget name in the budget.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided budget to update.
Read-only fields (such as `name`) cannot be changed. If this is not
provided, then only fields with non-default values from the request are
updated. See
https://developers.google.com/protocol-buffers/docs/proto3#default for more
details about default values.

=back

=head2 Google::Cloud::Billing::Budgets::V1::BudgetService::GetBudgetRequest

Request for GetBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of budget to get. Values are of the form
`billingAccounts/{billingAccountId}/budgets/{budgetId}`.

=back

=head2 Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsRequest

Request for ListBudgets

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of billing account to list budgets under. Values
are of the form `billingAccounts/{billingAccountId}`.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Optional. Set the scope of the budgets to be returned, in the format of the
resource name. The scope of a budget is the cost that it tracks, such as
costs for a single project, or the costs for all projects in a folder. Only
project scope (in the format of "projects/project-id" or "projects/123") is
supported in this field. When this field is set to a project's resource
name, the budgets returned are tracking the costs for that project.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of budgets to return per page.
The default and maximum value are 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value returned by the last `ListBudgetsResponse` which
indicates that this is a continuation of a prior `ListBudgets` call,
and that the system should return the next page of data.

=back

=head2 Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsResponse

Response for ListBudgets

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->budgets() >> / C<< $msg->budgets($value) >>

Type: C<Message> (L<Google::Cloud::Billing::Budgets::V1::BudgetModel::Budget>)

List of the budgets owned by the requested billing account.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If not empty, indicates that there may be more budgets that match the
request; this value should be passed in a new `ListBudgetsRequest`.

=back

=head2 Google::Cloud::Billing::Budgets::V1::BudgetService::DeleteBudgetRequest

Request for DeleteBudget

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the budget to delete. Values are of the form
`billingAccounts/{billingAccountId}/budgets/{budgetId}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Billing::Budgets::V1::BudgetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
