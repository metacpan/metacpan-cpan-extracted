package Google::Actions::Sdk::V2::Settings;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::AccountLinking };
    eval { require Google::Actions::Sdk::V2::LocalizedSettings };
    eval { require Google::Actions::Sdk::V2::Surface };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvYWN0aW9ucy9zZGsvdjIvc2V0dGluZ3MucHJvdG8SFWdvb2dsZS5hY3Rpb25z
LnNkay52MhorZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2FjY291bnRfbGlua2luZy5wcm90bxou
Z29vZ2xlL2FjdGlvbnMvc2RrL3YyL2xvY2FsaXplZF9zZXR0aW5ncy5wcm90bxojZ29vZ2xl
L2FjdGlvbnMvc2RrL3YyL3N1cmZhY2UucHJvdG8i7QoKCFNldHRpbmdzEh0KCnByb2plY3Rf
aWQYASABKAlSCXByb2plY3RJZBIlCg5kZWZhdWx0X2xvY2FsZRgCIAEoCVINZGVmYXVsdExv
Y2FsZRInCg9lbmFibGVkX3JlZ2lvbnMYAyADKAlSDmVuYWJsZWRSZWdpb25zEikKEGRpc2Fi
bGVkX3JlZ2lvbnMYBCADKAlSD2Rpc2FibGVkUmVnaW9ucxJECghjYXRlZ29yeRgFIAEoDjIo
Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5TZXR0aW5ncy5DYXRlZ29yeVIIY2F0ZWdvcnkSMgoV
dXNlc190cmFuc2FjdGlvbnNfYXBpGAYgASgIUhN1c2VzVHJhbnNhY3Rpb25zQXBpEjkKGXVz
ZXNfZGlnaXRhbF9wdXJjaGFzZV9hcGkYByABKAhSFnVzZXNEaWdpdGFsUHVyY2hhc2VBcGkS
NgoXdXNlc19pbnRlcmFjdGl2ZV9jYW52YXMYCCABKAhSFXVzZXNJbnRlcmFjdGl2ZUNhbnZh
cxIqChF1c2VzX2hvbWVfc3RvcmFnZRgRIAEoCFIPdXNlc0hvbWVTdG9yYWdlEi4KE2Rlc2ln
bmVkX2Zvcl9mYW1pbHkYCSABKAhSEWRlc2lnbmVkRm9yRmFtaWx5EkwKI2NvbnRhaW5zX2Fs
Y29ob2xfb3JfdG9iYWNjb19jb250ZW50GAsgASgIUh9jb250YWluc0FsY29ob2xPclRvYmFj
Y29Db250ZW50EiQKDmtlZXBzX21pY19vcGVuGAwgASgIUgxrZWVwc01pY09wZW4SXQoUc3Vy
ZmFjZV9yZXF1aXJlbWVudHMYDSABKAsyKi5nb29nbGUuYWN0aW9ucy5zZGsudjIuU3VyZmFj
ZVJlcXVpcmVtZW50c1ITc3VyZmFjZVJlcXVpcmVtZW50cxIxChR0ZXN0aW5nX2luc3RydWN0
aW9ucxgOIAEoCVITdGVzdGluZ0luc3RydWN0aW9ucxJXChJsb2NhbGl6ZWRfc2V0dGluZ3MY
DyABKAsyKC5nb29nbGUuYWN0aW9ucy5zZGsudjIuTG9jYWxpemVkU2V0dGluZ3NSEWxvY2Fs
aXplZFNldHRpbmdzEk4KD2FjY291bnRfbGlua2luZxgQIAEoCzIlLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5BY2NvdW50TGlua2luZ1IOYWNjb3VudExpbmtpbmcSMgoVc2VsZWN0ZWRfYW5k
cm9pZF9hcHBzGBQgAygJUhNzZWxlY3RlZEFuZHJvaWRBcHBzIpoDCghDYXRlZ29yeRIYChRD
QVRFR09SWV9VTlNQRUNJRklFRBAAEhgKFEJVU0lORVNTX0FORF9GSU5BTkNFEAISGwoXRURV
Q0FUSU9OX0FORF9SRUZFUkVOQ0UQAxISCg5GT09EX0FORF9EUklOSxAEEhQKEEdBTUVTX0FO
RF9UUklWSUEQBRIWChJIRUFMVEhfQU5EX0ZJVE5FU1MQBhITCg9LSURTX0FORF9GQU1JTFkQ
FBINCglMSUZFU1RZTEUQBxIJCgVMT0NBTBAIEhEKDU1PVklFU19BTkRfVFYQCRITCg9NVVNJ
Q19BTkRfQVVESU8QChIICgRORVdTEAESFQoRTk9WRUxUWV9BTkRfSFVNT1IQCxIQCgxQUk9E
VUNUSVZJVFkQDBIMCghTSE9QUElORxANEgoKBlNPQ0lBTBAOEgoKBlNQT1JUUxAPEh0KGVRS
QVZFTF9BTkRfVFJBTlNQT1JUQVRJT04QEBINCglVVElMSVRJRVMQERILCgdXRUFUSEVSEBIS
EAoMSE9NRV9DT05UUk9MEBNCZgoZY29tLmdvb2dsZS5hY3Rpb25zLnNkay52MkINU2V0dGlu
Z3NQcm90b1ABWjhnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlv
bnMvc2RrL3YyO3Nka0rlLwoHEgUOALkBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAHgoJCgIDABIDEgA1CgkKAgMBEgMTADgKCQoCAwISAxQALQoICgEI
EgMWAE8KCQoCCAsSAxYATwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC4KCQoCCAgS
AxgALgoICgEIEgMZADIKCQoCCAESAxkAMgpWCgIEABIFHAC5AQEaSSBSZXByZXNlbnRzIHNl
dHRpbmdzIG9mIGFuIEFjdGlvbnMgcHJvamVjdCB0aGF0IGFyZSBub3QgbG9jYWxlIHNwZWNp
ZmljLgoKCgoDBAABEgMcCBAKPAoEBAAEABIEHgJdAxouIFRoZSBjYXRlZ29yeSBjaG9pY2Vz
IGZvciBhbiBBY3Rpb25zIHByb2plY3QuCgoMCgUEAAQAARIDHgcPCicKBgQABAACABIDIAQd
GhggVW5rbm93biAvIFVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDIAQYCg4KBwQABAACAAIS
AyAbHAovCgYEAAQAAgESAyMEHRogIEJ1c2luZXNzIGFuZCBGaW5hbmNlIGNhdGVnb3J5LgoK
DgoHBAAEAAIBARIDIwQYCg4KBwQABAACAQISAyMbHAoyCgYEAAQAAgISAyYEIBojIEVkdWNh
dGlvbiBhbmQgUmVmZXJlbmNlIGNhdGVnb3J5LgoKDgoHBAAEAAICARIDJgQbCg4KBwQABAAC
AgISAyYeHwopCgYEAAQAAgMSAykEFxoaIEZvb2QgYW5kIERyaW5rIGNhdGVnb3J5LgoKDgoH
BAAEAAIDARIDKQQSCg4KBwQABAACAwISAykVFgorCgYEAAQAAgQSAywEGRocIEdhbWVzIGFu
ZCBUcml2aWEgY2F0ZWdvcnkuCgoOCgcEAAQAAgQBEgMsBBQKDgoHBAAEAAIEAhIDLBcYCi0K
BgQABAACBRIDLwQbGh4gSGVhbHRoIGFuZCBGaXRuZXNzIGNhdGVnb3J5LgoKDgoHBAAEAAIF
ARIDLwQWCg4KBwQABAACBQISAy8ZGgoqCgYEAAQAAgYSAzIEGRobIEtpZHMgYW5kIEZhbWls
eSBjYXRlZ29yeS4KCg4KBwQABAACBgESAzIEEwoOCgcEAAQAAgYCEgMyFhgKJAoGBAAEAAIH
EgM1BBIaFSBMaWZlc3R5bGUgY2F0ZWdvcnkuCgoOCgcEAAQAAgcBEgM1BA0KDgoHBAAEAAIH
AhIDNRARCiAKBgQABAACCBIDOAQOGhEgTG9jYWwgY2F0ZWdvcnkuCgoOCgcEAAQAAggBEgM4
BAkKDgoHBAAEAAIIAhIDOAwNCigKBgQABAACCRIDOwQWGhkgTW92aWVzIGFuZCBUViBjYXRl
Z29yeS4KCg4KBwQABAACCQESAzsEEQoOCgcEAAQAAgkCEgM7FBUKKgoGBAAEAAIKEgM+BBka
GyBNdXNpYyBhbmQgQXVkaW8gY2F0ZWdvcnkuCgoOCgcEAAQAAgoBEgM+BBMKDgoHBAAEAAIK
AhIDPhYYCh8KBgQABAACCxIDQQQNGhAgTmV3cyBjYXRlZ29yeSwKCg4KBwQABAACCwESA0EE
CAoOCgcEAAQAAgsCEgNBCwwKLAoGBAAEAAIMEgNEBBsaHSBOb3ZlbHR5IGFuZCBIdW1vciBj
YXRlZ29yeS4KCg4KBwQABAACDAESA0QEFQoOCgcEAAQAAgwCEgNEGBoKJwoGBAAEAAINEgNH
BBYaGCBQcm9kdWN0aXZpdHkgY2F0ZWdvcnkuCgoOCgcEAAQAAg0BEgNHBBAKDgoHBAAEAAIN
AhIDRxMVCiMKBgQABAACDhIDSgQSGhQgU2hvcHBpbmcgY2F0ZWdvcnkuCgoOCgcEAAQAAg4B
EgNKBAwKDgoHBAAEAAIOAhIDSg8RCiEKBgQABAACDxIDTQQQGhIgU29jaWFsIGNhdGVnb3J5
LgoKDgoHBAAEAAIPARIDTQQKCg4KBwQABAACDwISA00NDwohCgYEAAQAAhASA1AEEBoSIFNw
b3J0cyBjYXRlZ29yeS4KCg4KBwQABAACEAESA1AECgoOCgcEAAQAAhACEgNQDQ8KNAoGBAAE
AAIREgNTBCMaJSBUcmF2ZWwgYW5kIFRyYW5zcG9ydGF0aW9uIGNhdGVnb3J5LgoKDgoHBAAE
AAIRARIDUwQdCg4KBwQABAACEQISA1MgIgokCgYEAAQAAhISA1YEExoVIFV0aWxpdGllcyBj
YXRlZ29yeS4KCg4KBwQABAACEgESA1YEDQoOCgcEAAQAAhICEgNWEBIKIgoGBAAEAAITEgNZ
BBEaEyBXZWF0aGVyIGNhdGVnb3J5LgoKDgoHBAAEAAITARIDWQQLCg4KBwQABAACEwISA1kO
EAonCgYEAAQAAhQSA1wEFhoYIEhvbWUgQ29udHJvbCBjYXRlZ29yeS4KCg4KBwQABAACFAES
A1wEEAoOCgcEAAQAAhQCEgNcExUKIgoEBAACABIDYAIYGhUgQWN0aW9ucyBwcm9qZWN0IGlk
LgoKDAoFBAACAAUSA2ACCAoMCgUEAAIAARIDYAkTCgwKBQQAAgADEgNgFhcKlwIKBAQAAgES
A2YCHBqJAiBMb2NhbGUgd2hpY2ggaXMgZGVmYXVsdCBmb3IgdGhlIHByb2plY3QuIEZvciBh
bGwgZmlsZXMgZXhjZXB0IHVuZGVyCiBgcmVzb3VyY2VzL2Agd2l0aCBubyBsb2NhbGUgaW4g
dGhlIHBhdGgsIHRoZSBsb2NhbGl6ZWQgZGF0YSBpcyBhdHRyaWJ1dGVkCiB0byB0aGlzIGBk
ZWZhdWx0X2xvY2FsZWAuIEZvciBmaWxlcyB1bmRlciBgcmVzb3VyY2VzL2Agbm8gbG9jYWxl
IG1lYW5zIHRoYXQKIHRoZSByZXNvdXJjZSBpcyBhcHBsaWNhYmxlIHRvIGFsbCBsb2NhbGVz
LgoKDAoFBAACAQUSA2YCCAoMCgUEAAIBARIDZgkXCgwKBQQAAgEDEgNmGhsK1wQKBAQAAgIS
A3cCJhrJBCBSZXByZXNlbnRzIHRoZSByZWdpb25zIHdoZXJlIHVzZXJzIGNhbiBpbnZva2Ug
eW91ciBBY3Rpb25zLCB3aGljaCBpcwogYmFzZWQgb24gdGhlIHVzZXIncyBsb2NhdGlvbiBv
ZiBwcmVzZW5jZS4gQ2Fubm90IGJlIHNldCBpZgogYGRpc2FibGVkX3JlZ2lvbnNgIGlzIHNl
dC4gSWYgYm90aCBgZW5hYmxlZF9yZWdpb25zYCBhbmQgYGRpc2FibGVkX3JlZ2lvbnNgCiBh
cmUgbm90IHNwZWNpZmllZCwgdXNlcnMgY2FuIGludm9rZSB5b3VyIEFjdGlvbnMgaW4gYWxs
IHJlZ2lvbnMuIEVhY2gKIHJlZ2lvbiBpcyByZXByZXNlbnRlZCB1c2luZyB0aGUgQ2Fub25p
Y2FsIE5hbWUgb2YgQWR3b3JkcyBnZW90YXJnZXRzLiBTZWUKIGh0dHBzOi8vZGV2ZWxvcGVy
cy5nb29nbGUuY29tL2Fkd29yZHMvYXBpL2RvY3MvYXBwZW5kaXgvZ2VvdGFyZ2V0aW5nCiBF
eGFtcGxlcyBpbmNsdWRlOgogLSAiR2VybWFueSIKIC0gIkdoYW5hIgogLSAiR3JlZWNlIgog
LSAiR3JlbmFkYSIKIC0gIlVuaXRlZCBLaW5nZG9tIgogLSAiVW5pdGVkIFN0YXRlcyIKIC0g
IlVuaXRlZCBTdGF0ZXMgTWlub3IgT3V0bHlpbmcgSXNsYW5kcyIKIC0gIlVydWd1YXkiCgoM
CgUEAAICBBIDdwIKCgwKBQQAAgIFEgN3CxEKDAoFBAACAgESA3cSIQoMCgUEAAICAxIDdyQl
CtUDCgQEAAIDEgSGAQInGsYDIFJlcHJlc2VudHMgdGhlIHJlZ2lvbnMgd2hlcmUgeW91ciBB
Y3Rpb25zIGFyZSBibG9ja2VkLCBiYXNlZCBvbiB0aGUgdXNlcidzCiBsb2NhdGlvbiBvZiBw
cmVzZW5jZS4gQ2Fubm90IGJlIHNldCBpZiBgZW5hYmxlZF9yZWdpb25zYCBpcyBzZXQuCiBF
YWNoIHJlZ2lvbiBpcyByZXByZXNlbnRlZCB1c2luZyB0aGUgQ2Fub25pY2FsIE5hbWUgb2Yg
QWR3b3JkcyBnZW90YXJnZXRzLgogU2VlIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29t
L2Fkd29yZHMvYXBpL2RvY3MvYXBwZW5kaXgvZ2VvdGFyZ2V0aW5nCiBFeGFtcGxlcyBpbmNs
dWRlOgogLSAiR2VybWFueSIKIC0gIkdoYW5hIgogLSAiR3JlZWNlIgogLSAiR3JlbmFkYSIK
IC0gIlVuaXRlZCBLaW5nZG9tIgogLSAiVW5pdGVkIFN0YXRlcyIKIC0gIlVuaXRlZCBTdGF0
ZXMgTWlub3IgT3V0bHlpbmcgSXNsYW5kcyIKIC0gIlVydWd1YXkiCgoNCgUEAAIDBBIEhgEC
CgoNCgUEAAIDBRIEhgELEQoNCgUEAAIDARIEhgESIgoNCgUEAAIDAxIEhgElJgo2CgQEAAIE
EgSJAQIYGiggVGhlIGNhdGVnb3J5IGZvciB0aGlzIEFjdGlvbnMgcHJvamVjdC4KCg0KBQQA
AgQGEgSJAQIKCg0KBQQAAgQBEgSJAQsTCg0KBQQAAgQDEgSJARYXCqsBCgQEAAIFEgSOAQIh
GpwBIFdoZXRoZXIgQWN0aW9ucyBjYW4gdXNlIHRyYW5zYWN0aW9ucyAoZm9yIGV4YW1wbGUs
IG1ha2luZwogcmVzZXJ2YXRpb25zLCB0YWtpbmcgb3JkZXJzLCBldGMuKS4gSWYgZmFsc2Us
IHRoZW4gYXR0ZW1wdHMgdG8gdXNlIHRoZQogVHJhbnNhY3Rpb25zIEFQSXMgZmFpbC4KCg0K
BQQAAgUFEgSOAQIGCg0KBQQAAgUBEgSOAQccCg0KBQQAAgUDEgSOAR8gCksKBAQAAgYSBJEB
AiUaPSBXaGV0aGVyIEFjdGlvbnMgY2FuIHBlcmZvcm0gdHJhbnNhY3Rpb25zIGZvciBkaWdp
dGFsIGdvb2RzLgoKDQoFBAACBgUSBJEBAgYKDQoFBAACBgESBJEBByAKDQoFBAACBgMSBJEB
IyQKNwoEBAACBxIElAECIxopIFdoZXRoZXIgQWN0aW9ucyB1c2UgSW50ZXJhY3RpdmUgQ2Fu
dmFzLgoKDQoFBAACBwUSBJQBAgYKDQoFBAACBwESBJQBBx4KDQoFBAACBwMSBJQBISIKPQoE
BAACCBIElwECHhovIFdoZXRoZXIgQWN0aW9ucyB1c2UgdGhlIGhvbWUgc3RvcmFnZSBmZWF0
dXJlLgoKDQoFBAACCAUSBJcBAgYKDQoFBAACCAESBJcBBxgKDQoFBAACCAMSBJcBGx0KRQoE
BAACCRIEmgECHxo3IFdoZXRoZXIgQWN0aW9ucyBjb250ZW50IGlzIGRlc2lnbmVkIGZvciBm
YW1pbHkgKERGRikuCgoNCgUEAAIJBRIEmgECBgoNCgUEAAIJARIEmgEHGgoNCgUEAAIJAxIE
mgEdHgpMCgQEAAIKEgSdAQIwGj4gV2hldGhlciBBY3Rpb25zIGNvbnRhaW5zIGFsY29ob2wg
b3IgdG9iYWNjbyByZWxhdGVkIGNvbnRlbnQuCgoNCgUEAAIKBRIEnQECBgoNCgUEAAIKARIE
nQEHKgoNCgUEAAIKAxIEnQEtLwpjCgQEAAILEgShAQIbGlUgV2hldGhlciBBY3Rpb25zIG1h
eSBsZWF2ZSBtaWMgb3BlbiB3aXRob3V0IGFuIGV4cGxpY2l0IHByb21wdCBkdXJpbmcKIGNv
bnZlcnNhdGlvbi4KCg0KBQQAAgsFEgShAQIGCg0KBQQAAgsBEgShAQcVCg0KBQQAAgsDEgSh
ARgaCm8KBAQAAgwSBKUBAjAaYSBUaGUgc3VyZmFjZSByZXF1aXJlbWVudHMgdGhhdCBhIGNs
aWVudCBzdXJmYWNlIG11c3Qgc3VwcG9ydCB0byBpbnZva2UKIEFjdGlvbnMgaW4gdGhpcyBw
cm9qZWN0LgoKDQoFBAACDAYSBKUBAhUKDQoFBAACDAESBKUBFioKDQoFBAACDAMSBKUBLS8K
cQoEBAACDRIEqQECIxpjIEZyZWUtZm9ybSB0ZXN0aW5nIGluc3RydWN0aW9ucyBmb3IgQWN0
aW9ucyByZXZpZXdlciAoZm9yIGV4YW1wbGUsIGFjY291bnQKIGxpbmtpbmcgaW5zdHJ1Y3Rp
b25zKS4KCg0KBQQAAg0FEgSpAQIICg0KBQQAAg0BEgSpAQkdCg0KBQQAAg0DEgSpASAiCpYB
CgQEAAIOEgStAQIsGocBIExvY2FsaXplZCBzZXR0aW5ncyBmb3IgdGhlIHByb2plY3QncyBk
ZWZhdWx0IGxvY2FsZS4gRXZlcnkgYWRkaXRpb25hbAogbG9jYWxlIHNob3VsZCBoYXZlIGl0
cyBvd24gc2V0dGluZ3MgZmlsZSBpbiBpdHMgb3duIGRpcmVjdG9yeS4KCg0KBQQAAg4GEgSt
AQITCg0KBQQAAg4BEgStARQmCg0KBQQAAg4DEgStASkrCm0KBAQAAg8SBLEBAiYaXyBBbGxv
dyB1c2VycyB0byBjcmVhdGUgb3IgbGluayBhY2NvdW50cyB0aHJvdWdoIEdvb2dsZSBzaWdu
LWluIGFuZC9vciB5b3VyCiBvd24gT0F1dGggc2VydmljZS4KCg0KBQQAAg8GEgSxAQIQCg0K
BQQAAg8BEgSxAREgCg0KBQQAAg8DEgSxASMlCr8CCgQEAAIQEgS4AQItGrACIEFuZHJvaWQg
YXBwcyBzZWxlY3RlZCB0byBhY2NjZXNzIEdvb2dsZSBQbGF5IHB1cmNoYXNlcyBmb3IgdHJh
bnNhY3Rpb25zLgogVGhpcyBpcyBhIHNlbGVjdGlvbiBmcm9tIHRoZSBBbmRyb2lkIGFwcHMg
Y29ubmVjdGVkIHRvIHRoZSBhY3Rpb25zIHByb2plY3QKIHRvIHZlcmlmeSBicmFuZCBvd25l
cnNoaXAgYW5kIGVuYWJsZSBhZGRpdGlvbmFsIGZlYXR1cmVzLiBTZWUKIGh0dHBzOi8vZGV2
ZWxvcGVycy5nb29nbGUuY29tL2Fzc2lzdGFudC9jb25zb2xlL2JyYW5kLXZlcmlmaWNhdGlv
biBmb3IgbW9yZQogaW5mb3JtYXRpb24uCgoNCgUEAAIQBBIEuAECCgoNCgUEAAIQBRIEuAEL
EQoNCgUEAAIQARIEuAESJwoNCgUEAAIQAxIEuAEqLGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Settings::Settings ===
    # Fields for Settings
    # Field: project_id Type: 9 ()
    # Field: default_locale Type: 9 ()
    # Field: enabled_regions Type: 9 ()
    # Field: disabled_regions Type: 9 ()
    # Field: category Type: 14 (.google.actions.sdk.v2.Settings.Category)
    # Field: uses_transactions_api Type: 8 ()
    # Field: uses_digital_purchase_api Type: 8 ()
    # Field: uses_interactive_canvas Type: 8 ()
    # Field: uses_home_storage Type: 8 ()
    # Field: designed_for_family Type: 8 ()
    # Field: contains_alcohol_or_tobacco_content Type: 8 ()
    # Field: keeps_mic_open Type: 8 ()
    # Field: surface_requirements Type: 11 (.google.actions.sdk.v2.SurfaceRequirements)
    # Field: testing_instructions Type: 9 ()
    # Field: localized_settings Type: 11 (.google.actions.sdk.v2.LocalizedSettings)
    # Field: account_linking Type: 11 (.google.actions.sdk.v2.AccountLinking)
    # Field: selected_android_apps Type: 9 ()

# Enum: Settings::Category
our $Settings_CATEGORY_UNSPECIFIED = 0;
our $Settings_BUSINESS_AND_FINANCE = 2;
our $Settings_EDUCATION_AND_REFERENCE = 3;
our $Settings_FOOD_AND_DRINK = 4;
our $Settings_GAMES_AND_TRIVIA = 5;
our $Settings_HEALTH_AND_FITNESS = 6;
our $Settings_KIDS_AND_FAMILY = 20;
our $Settings_LIFESTYLE = 7;
our $Settings_LOCAL = 8;
our $Settings_MOVIES_AND_TV = 9;
our $Settings_MUSIC_AND_AUDIO = 10;
our $Settings_NEWS = 1;
our $Settings_NOVELTY_AND_HUMOR = 11;
our $Settings_PRODUCTIVITY = 12;
our $Settings_SHOPPING = 13;
our $Settings_SOCIAL = 14;
our $Settings_SPORTS = 15;
our $Settings_TRAVEL_AND_TRANSPORTATION = 16;
our $Settings_UTILITIES = 17;
our $Settings_WEATHER = 18;
our $Settings_HOME_CONTROL = 19;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Settings - Compiled Protocol Buffers messages for google/actions/sdk/v2/settings.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Settings;

    my $msg = Google::Actions::Sdk::V2::Settings::Settings->new({
        project_id => $project_id,
        default_locale => $default_locale,
        enabled_regions => $enabled_regions,
        disabled_regions => $disabled_regions,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Settings::Settings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Settings::Settings

Represents settings of an Actions project that are not locale specific.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Actions project id.

=item * C<< $msg->default_locale() >> / C<< $msg->default_locale($value) >>

Type: C<String>

Locale which is default for the project. For all files except under
`resources/` with no locale in the path, the localized data is attributed
to this `default_locale`. For files under `resources/` no locale means that
the resource is applicable to all locales.

=item * C<< $msg->enabled_regions() >> / C<< $msg->enabled_regions($value) >>

Type: C<String>

Represents the regions where users can invoke your Actions, which is
based on the user's location of presence. Cannot be set if
`disabled_regions` is set. If both `enabled_regions` and `disabled_regions`
are not specified, users can invoke your Actions in all regions. Each
region is represented using the Canonical Name of Adwords geotargets. See
https://developers.google.com/adwords/api/docs/appendix/geotargeting
Examples include:
- "Germany"
- "Ghana"
- "Greece"
- "Grenada"
- "United Kingdom"
- "United States"
- "United States Minor Outlying Islands"
- "Uruguay"

=item * C<< $msg->disabled_regions() >> / C<< $msg->disabled_regions($value) >>

Type: C<String>

Represents the regions where your Actions are blocked, based on the user's
location of presence. Cannot be set if `enabled_regions` is set.
Each region is represented using the Canonical Name of Adwords geotargets.
See https://developers.google.com/adwords/api/docs/appendix/geotargeting
Examples include:
- "Germany"
- "Ghana"
- "Greece"
- "Grenada"
- "United Kingdom"
- "United States"
- "United States Minor Outlying Islands"
- "Uruguay"

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Settings::Category>)

The category for this Actions project.

=item * C<< $msg->uses_transactions_api() >> / C<< $msg->uses_transactions_api($value) >>

Type: C<Bool>

Whether Actions can use transactions (for example, making
reservations, taking orders, etc.). If false, then attempts to use the
Transactions APIs fail.

=item * C<< $msg->uses_digital_purchase_api() >> / C<< $msg->uses_digital_purchase_api($value) >>

Type: C<Bool>

Whether Actions can perform transactions for digital goods.

=item * C<< $msg->uses_interactive_canvas() >> / C<< $msg->uses_interactive_canvas($value) >>

Type: C<Bool>

Whether Actions use Interactive Canvas.

=item * C<< $msg->uses_home_storage() >> / C<< $msg->uses_home_storage($value) >>

Type: C<Bool>

Whether Actions use the home storage feature.

=item * C<< $msg->designed_for_family() >> / C<< $msg->designed_for_family($value) >>

Type: C<Bool>

Whether Actions content is designed for family (DFF).

=item * C<< $msg->contains_alcohol_or_tobacco_content() >> / C<< $msg->contains_alcohol_or_tobacco_content($value) >>

Type: C<Bool>

Whether Actions contains alcohol or tobacco related content.

=item * C<< $msg->keeps_mic_open() >> / C<< $msg->keeps_mic_open($value) >>

Type: C<Bool>

Whether Actions may leave mic open without an explicit prompt during
conversation.

=item * C<< $msg->surface_requirements() >> / C<< $msg->surface_requirements($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Surface::SurfaceRequirements>)

The surface requirements that a client surface must support to invoke
Actions in this project.

=item * C<< $msg->testing_instructions() >> / C<< $msg->testing_instructions($value) >>

Type: C<String>

Free-form testing instructions for Actions reviewer (for example, account
linking instructions).

=item * C<< $msg->localized_settings() >> / C<< $msg->localized_settings($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings>)

Localized settings for the project's default locale. Every additional
locale should have its own settings file in its own directory.

=item * C<< $msg->account_linking() >> / C<< $msg->account_linking($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::AccountLinking::AccountLinking>)

Allow users to create or link accounts through Google sign-in and/or your
own OAuth service.

=item * C<< $msg->selected_android_apps() >> / C<< $msg->selected_android_apps($value) >>

Type: C<String>

Android apps selected to acccess Google Play purchases for transactions.
This is a selection from the Android apps connected to the actions project
to verify brand ownership and enable additional features. See
https://developers.google.com/assistant/console/brand-verification for more
information.

=back

=head3 Enum: Settings::Category

=over 4

=item * C<CATEGORY_UNSPECIFIED> => C<0>

=item * C<BUSINESS_AND_FINANCE> => C<2>

=item * C<EDUCATION_AND_REFERENCE> => C<3>

=item * C<FOOD_AND_DRINK> => C<4>

=item * C<GAMES_AND_TRIVIA> => C<5>

=item * C<HEALTH_AND_FITNESS> => C<6>

=item * C<KIDS_AND_FAMILY> => C<20>

=item * C<LIFESTYLE> => C<7>

=item * C<LOCAL> => C<8>

=item * C<MOVIES_AND_TV> => C<9>

=item * C<MUSIC_AND_AUDIO> => C<10>

=item * C<NEWS> => C<1>

=item * C<NOVELTY_AND_HUMOR> => C<11>

=item * C<PRODUCTIVITY> => C<12>

=item * C<SHOPPING> => C<13>

=item * C<SOCIAL> => C<14>

=item * C<SPORTS> => C<15>

=item * C<TRAVEL_AND_TRANSPORTATION> => C<16>

=item * C<UTILITIES> => C<17>

=item * C<WEATHER> => C<18>

=item * C<HOME_CONTROL> => C<19>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Settings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
