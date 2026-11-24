package Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig;

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
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2F1ZGlvX2NvbmZpZy5wcm90
bxIiZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3By
b3RvYnVmL2R1cmF0aW9uLnByb3RvIrwBCg5TcGVlY2hXb3JkSW5mbxISCgR3b3JkGAMgASgJ
UgR3b3JkEjwKDHN0YXJ0X29mZnNldBgBIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
blILc3RhcnRPZmZzZXQSOAoKZW5kX29mZnNldBgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5E
dXJhdGlvblIJZW5kT2Zmc2V0Eh4KCmNvbmZpZGVuY2UYBCABKAJSCmNvbmZpZGVuY2UinQEK
DUJhcmdlSW5Db25maWcSSgoUbm9fYmFyZ2VfaW5fZHVyYXRpb24YASABKAsyGS5nb29nbGUu
cHJvdG9idWYuRHVyYXRpb25SEW5vQmFyZ2VJbkR1cmF0aW9uEkAKDnRvdGFsX2R1cmF0aW9u
GAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg10b3RhbER1cmF0aW9uIq0EChBJ
bnB1dEF1ZGlvQ29uZmlnEl0KDmF1ZGlvX2VuY29kaW5nGAEgASgOMjEuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5BdWRpb0VuY29kaW5nQgPgQQJSDWF1ZGlvRW5jb2Rp
bmcSKgoRc2FtcGxlX3JhdGVfaGVydHoYAiABKAVSD3NhbXBsZVJhdGVIZXJ0ehIoChBlbmFi
bGVfd29yZF9pbmZvGA0gASgIUg5lbmFibGVXb3JkSW5mbxIhCgxwaHJhc2VfaGludHMYBCAD
KAlSC3BocmFzZUhpbnRzEhQKBW1vZGVsGAcgASgJUgVtb2RlbBJbCg1tb2RlbF92YXJpYW50
GAogASgOMjYuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TcGVlY2hNb2Rl
bFZhcmlhbnRSDG1vZGVsVmFyaWFudBIpChBzaW5nbGVfdXR0ZXJhbmNlGAggASgIUg9zaW5n
bGVVdHRlcmFuY2USWQoPYmFyZ2VfaW5fY29uZmlnGA8gASgLMjEuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5CYXJnZUluQ29uZmlnUg1iYXJnZUluQ29uZmlnEkgKIW9w
dF9vdXRfY29uZm9ybWVyX21vZGVsX21pZ3JhdGlvbhgaIAEoCFIdb3B0T3V0Q29uZm9ybWVy
TW9kZWxNaWdyYXRpb24igAEKFFZvaWNlU2VsZWN0aW9uUGFyYW1zEhIKBG5hbWUYASABKAlS
BG5hbWUSVAoLc3NtbF9nZW5kZXIYAiABKA4yMy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLlNzbWxWb2ljZUdlbmRlclIKc3NtbEdlbmRlciL3AQoWU3ludGhlc2l6ZVNw
ZWVjaENvbmZpZxIjCg1zcGVha2luZ19yYXRlGAEgASgBUgxzcGVha2luZ1JhdGUSFAoFcGl0
Y2gYAiABKAFSBXBpdGNoEiQKDnZvbHVtZV9nYWluX2RiGAMgASgBUgx2b2x1bWVHYWluRGIS
LAoSZWZmZWN0c19wcm9maWxlX2lkGAUgAygJUhBlZmZlY3RzUHJvZmlsZUlkEk4KBXZvaWNl
GAQgASgLMjguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5Wb2ljZVNlbGVj
dGlvblBhcmFtc1IFdm9pY2UimgIKEU91dHB1dEF1ZGlvQ29uZmlnEmMKDmF1ZGlvX2VuY29k
aW5nGAEgASgOMjcuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5PdXRwdXRB
dWRpb0VuY29kaW5nQgPgQQJSDWF1ZGlvRW5jb2RpbmcSKgoRc2FtcGxlX3JhdGVfaGVydHoY
AiABKAVSD3NhbXBsZVJhdGVIZXJ0ehJ0ChhzeW50aGVzaXplX3NwZWVjaF9jb25maWcYAyAB
KAsyOi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlN5bnRoZXNpemVTcGVl
Y2hDb25maWdSFnN5bnRoZXNpemVTcGVlY2hDb25maWciswIKFFRleHRUb1NwZWVjaFNldHRp
bmdzEpEBChlzeW50aGVzaXplX3NwZWVjaF9jb25maWdzGAEgAygLMlUuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5UZXh0VG9TcGVlY2hTZXR0aW5ncy5TeW50aGVzaXpl
U3BlZWNoQ29uZmlnc0VudHJ5UhdzeW50aGVzaXplU3BlZWNoQ29uZmlncxqGAQocU3ludGhl
c2l6ZVNwZWVjaENvbmZpZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRJQCgV2YWx1ZRgCIAEo
CzI6Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU3ludGhlc2l6ZVNwZWVj
aENvbmZpZ1IFdmFsdWU6AjgBKpQCCg1BdWRpb0VuY29kaW5nEh4KGkFVRElPX0VOQ09ESU5H
X1VOU1BFQ0lGSUVEEAASHAoYQVVESU9fRU5DT0RJTkdfTElORUFSXzE2EAESFwoTQVVESU9f
RU5DT0RJTkdfRkxBQxACEhgKFEFVRElPX0VOQ09ESU5HX01VTEFXEAMSFgoSQVVESU9fRU5D
T0RJTkdfQU1SEAQSGQoVQVVESU9fRU5DT0RJTkdfQU1SX1dCEAUSGwoXQVVESU9fRU5DT0RJ
TkdfT0dHX09QVVMQBhIpCiVBVURJT19FTkNPRElOR19TUEVFWF9XSVRIX0hFQURFUl9CWVRF
EAcSFwoTQVVESU9fRU5DT0RJTkdfQUxBVxAIKnYKElNwZWVjaE1vZGVsVmFyaWFudBIkCiBT
UEVFQ0hfTU9ERUxfVkFSSUFOVF9VTlNQRUNJRklFRBAAEhYKElVTRV9CRVNUX0FWQUlMQUJM
RRABEhAKDFVTRV9TVEFOREFSRBACEhAKDFVTRV9FTkhBTkNFRBADKo0BCg9Tc21sVm9pY2VH
ZW5kZXISIQodU1NNTF9WT0lDRV9HRU5ERVJfVU5TUEVDSUZJRUQQABIaChZTU01MX1ZPSUNF
X0dFTkRFUl9NQUxFEAESHAoYU1NNTF9WT0lDRV9HRU5ERVJfRkVNQUxFEAISHQoZU1NNTF9W
T0lDRV9HRU5ERVJfTkVVVFJBTBADKpACChNPdXRwdXRBdWRpb0VuY29kaW5nEiUKIU9VVFBV
VF9BVURJT19FTkNPRElOR19VTlNQRUNJRklFRBAAEiMKH09VVFBVVF9BVURJT19FTkNPRElO
R19MSU5FQVJfMTYQARIhChlPVVRQVVRfQVVESU9fRU5DT0RJTkdfTVAzEAIaAggBEiUKIU9V
VFBVVF9BVURJT19FTkNPRElOR19NUDNfNjRfS0JQUxAEEiIKHk9VVFBVVF9BVURJT19FTkNP
RElOR19PR0dfT1BVUxADEh8KG09VVFBVVF9BVURJT19FTkNPRElOR19NVUxBVxAFEh4KGk9V
VFBVVF9BVURJT19FTkNPRElOR19BTEFXEAZCnwIKJmNvbS5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52M2JldGExQhBBdWRpb0NvbmZpZ1Byb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20v
Z28vZGlhbG9nZmxvdy9jeC9hcGl2M2JldGExL2N4cGI7Y3hwYqICAkRGqgIiR29vZ2xlLkNs
b3VkLkRpYWxvZ2Zsb3cuQ3guVjNCZXRhMeoCJkdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6
OkNYOjpWM2JldGEx6kFVChthdXRvbWwuZ29vZ2xlYXBpcy5jb20vTW9kZWwSNnByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tb2RlbHMve21vZGVsfUqufAoHEgUO
APgCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKAoICgEIEgMWAD8KCQoCCCUSAxYAPwoICgEI
EgMXAE0KCQoCCAsSAxcATQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADEKCQoCCAgS
AxkAMQoICgEIEgMaAD8KCQoCCAESAxoAPwoICgEIEgMbACAKCQoCCCQSAxsAIAoICgEIEgMc
AD8KCQoCCC0SAxwAPwoJCgEIEgQdACACCgwKBAidCAASBB0AIAIK1QEKAgUAEgQnAFUBGsgB
IEF1ZGlvIGVuY29kaW5nIG9mIHRoZSBhdWRpbyBjb250ZW50IHNlbnQgaW4gdGhlIGNvbnZl
cnNhdGlvbmFsIHF1ZXJ5IHJlcXVlc3QuCiBSZWZlciB0byB0aGUKIFtDbG91ZCBTcGVlY2gg
QVBJCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3BlZWNoLXRv
LXRleHQvZG9jcy9iYXNpY3MpIGZvciBtb3JlCiBkZXRhaWxzLgoKCgoDBQABEgMnBRIKHQoE
BQACABIDKQIhGhAgTm90IHNwZWNpZmllZC4KCgwKBQUAAgABEgMpAhwKDAoFBQACAAISAykf
IAphCgQFAAIBEgMtAh8aVCBVbmNvbXByZXNzZWQgMTYtYml0IHNpZ25lZCBsaXR0bGUtZW5k
aWFuIHNhbXBsZXMgKExpbmVhciBQQ00pLgogTElOVDogTEVHQUNZX05BTUVTCgoMCgUFAAIB
ARIDLQIaCgwKBQUAAgECEgMtHR4K7AIKBAUAAgISAzQCGhreAiBbYEZMQUNgXShodHRwczov
L3hpcGgub3JnL2ZsYWMvZG9jdW1lbnRhdGlvbi5odG1sKSAoRnJlZSBMb3NzbGVzcyBBdWRp
bwogQ29kZWMpIGlzIHRoZSByZWNvbW1lbmRlZCBlbmNvZGluZyBiZWNhdXNlIGl0IGlzIGxv
c3NsZXNzICh0aGVyZWZvcmUKIHJlY29nbml0aW9uIGlzIG5vdCBjb21wcm9taXNlZCkgYW5k
IHJlcXVpcmVzIG9ubHkgYWJvdXQgaGFsZiB0aGUKIGJhbmR3aWR0aCBvZiBgTElORUFSMTZg
LiBgRkxBQ2Agc3RyZWFtIGVuY29kaW5nIHN1cHBvcnRzIDE2LWJpdCBhbmQKIDI0LWJpdCBz
YW1wbGVzLCBob3dldmVyLCBub3QgYWxsIGZpZWxkcyBpbiBgU1RSRUFNSU5GT2AgYXJlIHN1
cHBvcnRlZC4KCgwKBQUAAgIBEgM0AhUKDAoFBQACAgISAzQYGQpXCgQFAAIDEgM3AhsaSiA4
LWJpdCBzYW1wbGVzIHRoYXQgY29tcGFuZCAxNC1iaXQgYXVkaW8gc2FtcGxlcyB1c2luZyBH
LjcxMSBQQ01VL211LWxhdy4KCgwKBQUAAgMBEgM3AhYKDAoFBQACAwISAzcZGgpWCgQFAAIE
EgM6AhkaSSBBZGFwdGl2ZSBNdWx0aS1SYXRlIE5hcnJvd2JhbmQgY29kZWMuIGBzYW1wbGVf
cmF0ZV9oZXJ0emAgbXVzdCBiZSA4MDAwLgoKDAoFBQACBAESAzoCFAoMCgUFAAIEAhIDOhcY
ClUKBAUAAgUSAz0CHBpIIEFkYXB0aXZlIE11bHRpLVJhdGUgV2lkZWJhbmQgY29kZWMuIGBz
YW1wbGVfcmF0ZV9oZXJ0emAgbXVzdCBiZSAxNjAwMC4KCgwKBQUAAgUBEgM9AhcKDAoFBQAC
BQISAz0aGwqKAQoEBQACBhIDQgIeGn0gT3B1cyBlbmNvZGVkIGF1ZGlvIGZyYW1lcyBpbiBP
Z2cgY29udGFpbmVyCiAoW09nZ09wdXNdKGh0dHBzOi8vd2lraS54aXBoLm9yZy9PZ2dPcHVz
KSkuCiBgc2FtcGxlX3JhdGVfaGVydHpgIG11c3QgYmUgMTYwMDAuCgoMCgUFAAIGARIDQgIZ
CgwKBQUAAgYCEgNCHB0K0wYKBAUAAgcSA1ECLBrFBiBBbHRob3VnaCB0aGUgdXNlIG9mIGxv
c3N5IGVuY29kaW5ncyBpcyBub3QgcmVjb21tZW5kZWQsIGlmIGEgdmVyeSBsb3cKIGJpdHJh
dGUgZW5jb2RpbmcgaXMgcmVxdWlyZWQsIGBPR0dfT1BVU2AgaXMgaGlnaGx5IHByZWZlcnJl
ZCBvdmVyCiBTcGVleCBlbmNvZGluZy4gVGhlIFtTcGVleF0oaHR0cHM6Ly9zcGVleC5vcmcv
KSBlbmNvZGluZyBzdXBwb3J0ZWQgYnkKIERpYWxvZ2Zsb3cgQVBJIGhhcyBhIGhlYWRlciBi
eXRlIGluIGVhY2ggYmxvY2ssIGFzIGluIE1JTUUgdHlwZQogYGF1ZGlvL3gtc3BlZXgtd2l0
aC1oZWFkZXItYnl0ZWAuCiBJdCBpcyBhIHZhcmlhbnQgb2YgdGhlIFJUUCBTcGVleCBlbmNv
ZGluZyBkZWZpbmVkIGluCiBbUkZDIDU1NzRdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRt
bC9yZmM1NTc0KS4KIFRoZSBzdHJlYW0gaXMgYSBzZXF1ZW5jZSBvZiBibG9ja3MsIG9uZSBi
bG9jayBwZXIgUlRQIHBhY2tldC4gRWFjaCBibG9jawogc3RhcnRzIHdpdGggYSBieXRlIGNv
bnRhaW5pbmcgdGhlIGxlbmd0aCBvZiB0aGUgYmxvY2ssIGluIGJ5dGVzLCBmb2xsb3dlZAog
Ynkgb25lIG9yIG1vcmUgZnJhbWVzIG9mIFNwZWV4IGRhdGEsIHBhZGRlZCB0byBhbiBpbnRl
Z3JhbCBudW1iZXIgb2YKIGJ5dGVzIChvY3RldHMpIGFzIHNwZWNpZmllZCBpbiBSRkMgNTU3
NC4gSW4gb3RoZXIgd29yZHMsIGVhY2ggUlRQIGhlYWRlcgogaXMgcmVwbGFjZWQgd2l0aCBh
IHNpbmdsZSBieXRlIGNvbnRhaW5pbmcgdGhlIGJsb2NrIGxlbmd0aC4gT25seSBTcGVleAog
d2lkZWJhbmQgaXMgc3VwcG9ydGVkLiBgc2FtcGxlX3JhdGVfaGVydHpgIG11c3QgYmUgMTYw
MDAuCgoMCgUFAAIHARIDUQInCgwKBQUAAgcCEgNRKisKVgoEBQACCBIDVAIaGkkgOC1iaXQg
c2FtcGxlcyB0aGF0IGNvbXBhbmQgMTMtYml0IGF1ZGlvIHNhbXBsZXMgdXNpbmcgRy43MTEg
UENNVS9hLWxhdy4KCgwKBQUAAggBEgNUAhUKDAoFBQACCAISA1QYGQrLAwoCBQESBF8AeAEa
vgMgVmFyaWFudCBvZiB0aGUgc3BlY2lmaWVkIFtTcGVlY2gKIG1vZGVsXVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLklucHV0QXVkaW9Db25maWcubW9kZWxdIHRvIHVz
ZS4KCiBTZWUgdGhlIFtDbG91ZCBTcGVlY2gKIGRvY3VtZW50YXRpb25dKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4dC9kb2NzL2VuaGFuY2VkLW1vZGVscykKIGZv
ciB3aGljaCBtb2RlbHMgaGF2ZSBkaWZmZXJlbnQgdmFyaWFudHMuIEZvciBleGFtcGxlLCB0
aGUgInBob25lX2NhbGwiIG1vZGVsCiBoYXMgYm90aCBhIHN0YW5kYXJkIGFuZCBhbiBlbmhh
bmNlZCB2YXJpYW50LiBXaGVuIHlvdSB1c2UgYW4gZW5oYW5jZWQgbW9kZWwsCiB5b3Ugd2ls
bCBnZW5lcmFsbHkgcmVjZWl2ZSBoaWdoZXIgcXVhbGl0eSByZXN1bHRzIHRoYW4gZm9yIGEg
c3RhbmRhcmQgbW9kZWwuCgoKCgMFAQESA18FFwpjCgQFAQIAEgNiAicaViBObyBtb2RlbCB2
YXJpYW50IHNwZWNpZmllZC4gSW4gdGhpcyBjYXNlIERpYWxvZ2Zsb3cgZGVmYXVsdHMgdG8K
IFVTRV9CRVNUX0FWQUlMQUJMRS4KCgwKBQUBAgABEgNiAiIKDAoFBQECAAISA2IlJgp9CgQF
AQIBEgNmAhkacCBVc2UgdGhlIGJlc3QgYXZhaWxhYmxlIHZhcmlhbnQgb2YgdGhlIFtTcGVl
Y2gKIG1vZGVsXVtJbnB1dEF1ZGlvQ29uZmlnLm1vZGVsXSB0aGF0IHRoZSBjYWxsZXIgaXMg
ZWxpZ2libGUgZm9yLgoKDAoFBQECAQESA2YCFAoMCgUFAQIBAhIDZhcYCtwBCgQFAQICEgNs
AhMazgEgVXNlIHN0YW5kYXJkIG1vZGVsIHZhcmlhbnQgZXZlbiBpZiBhbiBlbmhhbmNlZCBt
b2RlbCBpcyBhdmFpbGFibGUuICBTZWUgdGhlCiBbQ2xvdWQgU3BlZWNoCiBkb2N1bWVudGF0
aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3BlZWNoLXRvLXRleHQvZG9jcy9lbmhh
bmNlZC1tb2RlbHMpCiBmb3IgZGV0YWlscyBhYm91dCBlbmhhbmNlZCBtb2RlbHMuCgoMCgUF
AQICARIDbAIOCgwKBQUBAgICEgNsERIKjAMKBAUBAgMSA3cCExr+AiBVc2UgYW4gZW5oYW5j
ZWQgbW9kZWwgdmFyaWFudDoKCiAqIElmIGFuIGVuaGFuY2VkIHZhcmlhbnQgZG9lcyBub3Qg
ZXhpc3QgZm9yIHRoZSBnaXZlbgogICBbbW9kZWxdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuSW5wdXRBdWRpb0NvbmZpZy5tb2RlbF0gYW5kCiAgIHJlcXVlc3QgbGFu
Z3VhZ2UsIERpYWxvZ2Zsb3cgZmFsbHMgYmFjayB0byB0aGUgc3RhbmRhcmQgdmFyaWFudC4K
CiAgIFRoZSBbQ2xvdWQgU3BlZWNoCiAgIGRvY3VtZW50YXRpb25dKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4dC9kb2NzL2VuaGFuY2VkLW1vZGVscykKICAgZGVz
Y3JpYmVzIHdoaWNoIG1vZGVscyBoYXZlIGVuaGFuY2VkIHZhcmlhbnRzLgoKDAoFBQECAwES
A3cCDgoMCgUFAQIDAhIDdxESCkoKAgQAEgV7AJEBARo9IEluZm9ybWF0aW9uIGZvciBhIHdv
cmQgcmVjb2duaXplZCBieSB0aGUgc3BlZWNoIHJlY29nbml6ZXIuCgoKCgMEAAESA3sIFgop
CgQEAAIAEgN9AhIaHCBUaGUgd29yZCB0aGlzIGluZm8gaXMgZm9yLgoKDAoFBAACAAUSA30C
CAoMCgUEAAIAARIDfQkNCgwKBQQAAgADEgN9EBEKxQEKBAQAAgESBIIBAiwatgEgVGltZSBv
ZmZzZXQgcmVsYXRpdmUgdG8gdGhlIGJlZ2lubmluZyBvZiB0aGUgYXVkaW8gdGhhdCBjb3Jy
ZXNwb25kcyB0byB0aGUKIHN0YXJ0IG9mIHRoZSBzcG9rZW4gd29yZC4gVGhpcyBpcyBhbiBl
eHBlcmltZW50YWwgZmVhdHVyZSBhbmQgdGhlIGFjY3VyYWN5CiBvZiB0aGUgdGltZSBvZmZz
ZXQgY2FuIHZhcnkuCgoNCgUEAAIBBhIEggECGgoNCgUEAAIBARIEggEbJwoNCgUEAAIBAxIE
ggEqKwrDAQoEBAACAhIEhwECKhq0ASBUaW1lIG9mZnNldCByZWxhdGl2ZSB0byB0aGUgYmVn
aW5uaW5nIG9mIHRoZSBhdWRpbyB0aGF0IGNvcnJlc3BvbmRzIHRvIHRoZQogZW5kIG9mIHRo
ZSBzcG9rZW4gd29yZC4gVGhpcyBpcyBhbiBleHBlcmltZW50YWwgZmVhdHVyZSBhbmQgdGhl
IGFjY3VyYWN5IG9mCiB0aGUgdGltZSBvZmZzZXQgY2FuIHZhcnkuCgoNCgUEAAICBhIEhwEC
GgoNCgUEAAICARIEhwEbJQoNCgUEAAICAxIEhwEoKQqJAwoEBAACAxIEkAECFxr6AiBUaGUg
U3BlZWNoIGNvbmZpZGVuY2UgYmV0d2VlbiAwLjAgYW5kIDEuMCBmb3IgdGhpcyB3b3JkLiBB
IGhpZ2hlciBudW1iZXIKIGluZGljYXRlcyBhbiBlc3RpbWF0ZWQgZ3JlYXRlciBsaWtlbGlo
b29kIHRoYXQgdGhlIHJlY29nbml6ZWQgd29yZCBpcwogY29ycmVjdC4gVGhlIGRlZmF1bHQg
b2YgMC4wIGlzIGEgc2VudGluZWwgdmFsdWUgaW5kaWNhdGluZyB0aGF0IGNvbmZpZGVuY2UK
IHdhcyBub3Qgc2V0LgoKIFRoaXMgZmllbGQgaXMgbm90IGd1YXJhbnRlZWQgdG8gYmUgZnVs
bHkgc3RhYmxlIG92ZXIgdGltZSBmb3IgdGhlIHNhbWUKIGF1ZGlvIGlucHV0LiBVc2VycyBz
aG91bGQgYWxzbyBub3QgcmVseSBvbiBpdCB0byBhbHdheXMgYmUgcHJvdmlkZWQuCgoNCgUE
AAIDBRIEkAECBwoNCgUEAAIDARIEkAEIEgoNCgUEAAIDAxIEkAEVFgqECQoCBAESBqsBALIB
ARr1CCBDb25maWd1cmF0aW9uIG9mIHRoZSBiYXJnZS1pbiBiZWhhdmlvci4gQmFyZ2UtaW4g
aW5zdHJ1Y3RzIHRoZSBBUEkgdG8gcmV0dXJuCiBhIGRldGVjdGVkIHV0dGVyYW5jZSBhdCBh
IHByb3BlciB0aW1lIHdoaWxlIHRoZSBjbGllbnQgaXMgcGxheWluZyBiYWNrIHRoZQogcmVz
cG9uc2UgYXVkaW8gZnJvbSBhIHByZXZpb3VzIHJlcXVlc3QuIFdoZW4gdGhlIGNsaWVudCBz
ZWVzIHRoZQogdXR0ZXJhbmNlLCBpdCBzaG91bGQgc3RvcCB0aGUgcGxheWJhY2sgYW5kIGlt
bWVkaWF0ZWx5IGdldCByZWFkeSBmb3IKIHJlY2VpdmluZyB0aGUgcmVzcG9uc2VzIGZvciB0
aGUgY3VycmVudCByZXF1ZXN0LgoKIFRoZSBiYXJnZS1pbiBoYW5kbGluZyByZXF1aXJlcyB0
aGUgY2xpZW50IHRvIHN0YXJ0IHN0cmVhbWluZyBhdWRpbyBpbnB1dAogYXMgc29vbiBhcyBp
dCBzdGFydHMgcGxheWluZyBiYWNrIHRoZSBhdWRpbyBmcm9tIHRoZSBwcmV2aW91cyByZXNw
b25zZS4gVGhlCiBwbGF5YmFjayBpcyBtb2RlbGVkIGludG8gdHdvIHBoYXNlczoKCiAqIE5v
IGJhcmdlLWluIHBoYXNlOiB3aGljaCBnb2VzIGZpcnN0IGFuZCBkdXJpbmcgd2hpY2ggc3Bl
ZWNoIGRldGVjdGlvbgogICBzaG91bGQgbm90IGJlIGNhcnJpZWQgb3V0LgoKICogQmFyZ2Ut
aW4gcGhhc2U6IHdoaWNoIGZvbGxvd3MgdGhlIG5vIGJhcmdlLWluIHBoYXNlIGFuZCBkdXJp
bmcgd2hpY2gKICAgdGhlIEFQSSBzdGFydHMgc3BlZWNoIGRldGVjdGlvbiBhbmQgbWF5IGlu
Zm9ybSB0aGUgY2xpZW50IHRoYXQgYW4gdXR0ZXJhbmNlCiAgIGhhcyBiZWVuIGRldGVjdGVk
LiBOb3RlIHRoYXQgbm8tc3BlZWNoIGV2ZW50IGlzIG5vdCBleHBlY3RlZCBpbiB0aGlzCiAg
IHBoYXNlLgoKIFRoZSBjbGllbnQgcHJvdmlkZXMgdGhpcyBjb25maWd1cmF0aW9uIGluIHRl
cm1zIG9mIHRoZSBkdXJhdGlvbnMgb2YgdGhvc2UKIHR3byBwaGFzZXMuIFRoZSBkdXJhdGlv
bnMgYXJlIG1lYXN1cmVkIGluIHRlcm1zIG9mIHRoZSBhdWRpbyBsZW5ndGggZnJvbSB0aGUK
IHN0YXJ0IG9mIHRoZSBpbnB1dCBhdWRpby4KCiBOby1zcGVlY2ggZXZlbnQgaXMgYSByZXNw
b25zZSB3aXRoIEVORF9PRl9VVFRFUkFOQ0Ugd2l0aG91dCBhbnkgdHJhbnNjcmlwdAogZm9s
bG93aW5nIHVwLgoKCwoDBAEBEgSrAQgVCmAKBAQBAgASBK4BAjQaUiBEdXJhdGlvbiB0aGF0
IGlzIG5vdCBlbGlnaWJsZSBmb3IgYmFyZ2UtaW4gYXQgdGhlIGJlZ2lubmluZyBvZiB0aGUg
aW5wdXQKIGF1ZGlvLgoKDQoFBAECAAYSBK4BAhoKDQoFBAECAAESBK4BGy8KDQoFBAECAAMS
BK4BMjMKVAoEBAECARIEsQECLhpGIFRvdGFsIGR1cmF0aW9uIGZvciB0aGUgcGxheWJhY2sg
YXQgdGhlIGJlZ2lubmluZyBvZiB0aGUgaW5wdXQgYXVkaW8uCgoNCgUEAQIBBhIEsQECGgoN
CgUEAQIBARIEsQEbKQoNCgUEAQIBAxIEsQEsLQpUCgIEAhIGtQEA7AEBGkYgSW5zdHJ1Y3Rz
IHRoZSBzcGVlY2ggcmVjb2duaXplciBvbiBob3cgdG8gcHJvY2VzcyB0aGUgYXVkaW8gY29u
dGVudC4KCgsKAwQCARIEtQEIGApJCgQEAgIAEgS3AQJMGjsgUmVxdWlyZWQuIEF1ZGlvIGVu
Y29kaW5nIG9mIHRoZSBhdWRpbyBjb250ZW50IHRvIHByb2Nlc3MuCgoNCgUEAgIABhIEtwEC
DwoNCgUEAgIAARIEtwEQHgoNCgUEAgIAAxIEtwEhIgoNCgUEAgIACBIEtwEjSwoQCggEAgIA
CJwIABIEtwEkSgrEAQoEBAICARIEvgECHhq1ASBTYW1wbGUgcmF0ZSAoaW4gSGVydHopIG9m
IHRoZSBhdWRpbyBjb250ZW50IHNlbnQgaW4gdGhlIHF1ZXJ5LgogUmVmZXIgdG8KIFtDbG91
ZCBTcGVlY2ggQVBJCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
c3BlZWNoLXRvLXRleHQvZG9jcy9iYXNpY3MpIGZvcgogbW9yZSBkZXRhaWxzLgoKDQoFBAIC
AQUSBL4BAgcKDQoFBAICAQESBL4BCBkKDQoFBAICAQMSBL4BHB0KgAMKBAQCAgISBMYBAh0a
8QIgT3B0aW9uYWwuIElmIGB0cnVlYCwgRGlhbG9nZmxvdyByZXR1cm5zCiBbU3BlZWNoV29y
ZEluZm9dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuU3BlZWNoV29yZElu
Zm9dIGluCiBbU3RyZWFtaW5nUmVjb2duaXRpb25SZXN1bHRdW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzYmV0YTEuU3RyZWFtaW5nUmVjb2duaXRpb25SZXN1bHRdCiB3aXRoIGlu
Zm9ybWF0aW9uIGFib3V0IHRoZSByZWNvZ25pemVkIHNwZWVjaCB3b3JkcywgZS5nLiBzdGFy
dCBhbmQgZW5kIHRpbWUKIG9mZnNldHMuIElmIGZhbHNlIG9yIHVuc3BlY2lmaWVkLCBTcGVl
Y2ggZG9lc24ndCByZXR1cm4gYW55IHdvcmQtbGV2ZWwKIGluZm9ybWF0aW9uLgoKDQoFBAIC
AgUSBMYBAgYKDQoFBAICAgESBMYBBxcKDQoFBAICAgMSBMYBGhwKiwIKBAQCAgMSBM4BAiMa
/AEgT3B0aW9uYWwuIEEgbGlzdCBvZiBzdHJpbmdzIGNvbnRhaW5pbmcgd29yZHMgYW5kIHBo
cmFzZXMgdGhhdCB0aGUgc3BlZWNoCiByZWNvZ25pemVyIHNob3VsZCByZWNvZ25pemUgd2l0
aCBoaWdoZXIgbGlrZWxpaG9vZC4KCiBTZWUgW3RoZSBDbG91ZCBTcGVlY2gKIGRvY3VtZW50
YXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4dC9kb2NzL2Jh
c2ljcyNwaHJhc2UtaGludHMpCiBmb3IgbW9yZSBkZXRhaWxzLgoKDQoFBAICAwQSBM4BAgoK
DQoFBAICAwUSBM4BCxEKDQoFBAICAwESBM4BEh4KDQoFBAICAwMSBM4BISIKvwEKBAQCAgQS
BNQBAhMasAEgT3B0aW9uYWwuIFdoaWNoIFNwZWVjaCBtb2RlbCB0byBzZWxlY3QgZm9yIHRo
ZSBnaXZlbiByZXF1ZXN0LgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQogW1NwZWVjaAog
bW9kZWxzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2Nv
bmNlcHQvc3BlZWNoLW1vZGVscykuCgoNCgUEAgIEBRIE1AECCAoNCgUEAgIEARIE1AEJDgoN
CgUEAgIEAxIE1AEREgqBAQoEBAICBRIE2AECKBpzIE9wdGlvbmFsLiBXaGljaCB2YXJpYW50
IG9mIHRoZSBbU3BlZWNoCiBtb2RlbF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5JbnB1dEF1ZGlvQ29uZmlnLm1vZGVsXSB0byB1c2UuCgoNCgUEAgIFBhIE2AECFAoN
CgUEAgIFARIE2AEVIgoNCgUEAgIFAxIE2AElJwrXAwoEBAICBhIE4gECHBrIAyBPcHRpb25h
bC4gSWYgYGZhbHNlYCAoZGVmYXVsdCksIHJlY29nbml0aW9uIGRvZXMgbm90IGNlYXNlIHVu
dGlsIHRoZQogY2xpZW50IGNsb3NlcyB0aGUgc3RyZWFtLgogSWYgYHRydWVgLCB0aGUgcmVj
b2duaXplciB3aWxsIGRldGVjdCBhIHNpbmdsZSBzcG9rZW4gdXR0ZXJhbmNlIGluIGlucHV0
CiBhdWRpby4gUmVjb2duaXRpb24gY2Vhc2VzIHdoZW4gaXQgZGV0ZWN0cyB0aGUgYXVkaW8n
cyB2b2ljZSBoYXMKIHN0b3BwZWQgb3IgcGF1c2VkLiBJbiB0aGlzIGNhc2UsIG9uY2UgYSBk
ZXRlY3RlZCBpbnRlbnQgaXMgcmVjZWl2ZWQsIHRoZQogY2xpZW50IHNob3VsZCBjbG9zZSB0
aGUgc3RyZWFtIGFuZCBzdGFydCBhIG5ldyByZXF1ZXN0IHdpdGggYSBuZXcgc3RyZWFtIGFz
CiBuZWVkZWQuCiBOb3RlOiBUaGlzIHNldHRpbmcgaXMgcmVsZXZhbnQgb25seSBmb3Igc3Ry
ZWFtaW5nIG1ldGhvZHMuCgoNCgUEAgIGBRIE4gECBgoNCgUEAgIGARIE4gEHFwoNCgUEAgIG
AxIE4gEaGwpXCgQEAgIHEgTlAQIlGkkgQ29uZmlndXJhdGlvbiBvZiBiYXJnZS1pbiBiZWhh
dmlvciBkdXJpbmcgdGhlIHN0cmVhbWluZyBvZiBpbnB1dCBhdWRpby4KCg0KBQQCAgcGEgTl
AQIPCg0KBQQCAgcBEgTlARAfCg0KBQQCAgcDEgTlASIkCqsCCgQEAgIIEgTrAQIuGpwCIElm
IGB0cnVlYCwgdGhlIHJlcXVlc3Qgd2lsbCBvcHQgb3V0IGZvciBTVFQgY29uZm9ybWVyIG1v
ZGVsIG1pZ3JhdGlvbi4KIFRoaXMgZmllbGQgd2lsbCBiZSBkZXByZWNhdGVkIG9uY2UgZm9y
Y2UgbWlncmF0aW9uIHRha2VzIHBsYWNlIGluIEp1bmUKIDIwMjQuIFBsZWFzZSByZWZlciB0
byBbRGlhbG9nZmxvdyBDWCBTcGVlY2ggbW9kZWwKIG1pZ3JhdGlvbl0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvY3gvZG9jcy9jb25jZXB0L3NwZWVjaC1tb2RlbC1t
aWdyYXRpb24pLgoKDQoFBAICCAUSBOsBAgYKDQoFBAICCAESBOsBBygKDQoFBAICCAMSBOsB
Ky0KgAEKAgUCEgbwAQD9AQEaciBHZW5kZXIgb2YgdGhlIHZvaWNlIGFzIGRlc2NyaWJlZCBp
bgogW1NTTUwgdm9pY2UgZWxlbWVudF0oaHR0cHM6Ly93d3cudzMub3JnL1RSL3NwZWVjaC1z
eW50aGVzaXMxMS8jZWRlZl92b2ljZSkuCgoLCgMFAgESBPABBRQKewoEBQICABIE8wECJBpt
IEFuIHVuc3BlY2lmaWVkIGdlbmRlciwgd2hpY2ggbWVhbnMgdGhhdCB0aGUgY2xpZW50IGRv
ZXNuJ3QgY2FyZSB3aGljaAogZ2VuZGVyIHRoZSBzZWxlY3RlZCB2b2ljZSB3aWxsIGhhdmUu
CgoNCgUFAgIAARIE8wECHwoNCgUFAgIAAhIE8wEiIwodCgQFAgIBEgT2AQIdGg8gQSBtYWxl
IHZvaWNlLgoKDQoFBQICAQESBPYBAhgKDQoFBQICAQISBPYBGxwKHwoEBQICAhIE+QECHxoR
IEEgZmVtYWxlIHZvaWNlLgoKDQoFBQICAgESBPkBAhoKDQoFBQICAgISBPkBHR4KJwoEBQIC
AxIE/AECIBoZIEEgZ2VuZGVyLW5ldXRyYWwgdm9pY2UuCgoNCgUFAgIDARIE/AECGwoNCgUF
AgIDAhIE/AEeHwpHCgIEAxIGgAIAkAIBGjkgRGVzY3JpcHRpb24gb2Ygd2hpY2ggdm9pY2Ug
dG8gdXNlIGZvciBzcGVlY2ggc3ludGhlc2lzLgoKCwoDBAMBEgSAAggcCvcCCgQEAwIAEgSH
AgISGugCIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdm9pY2UuIElmIG5vdCBzZXQsIHRo
ZSBzZXJ2aWNlIHdpbGwgY2hvb3NlIGEKIHZvaWNlIGJhc2VkIG9uIHRoZSBvdGhlciBwYXJh
bWV0ZXJzIHN1Y2ggYXMgbGFuZ3VhZ2VfY29kZSBhbmQKIFtzc21sX2dlbmRlcl1bZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5Wb2ljZVNlbGVjdGlvblBhcmFtcy5zc21s
X2dlbmRlcl0uCgogRm9yIHRoZSBsaXN0IG9mIGF2YWlsYWJsZSB2b2ljZXMsIHBsZWFzZSBy
ZWZlciB0byBbU3VwcG9ydGVkIHZvaWNlcyBhbmQKIGxhbmd1YWdlc10oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL3RleHQtdG8tc3BlZWNoL2RvY3Mvdm9pY2VzKS4KCg0KBQQDAgAFEgSH
AgIICg0KBQQDAgABEgSHAgkNCg0KBQQDAgADEgSHAhARCrwDCgQEAwIBEgSPAgIiGq0DIE9w
dGlvbmFsLiBUaGUgcHJlZmVycmVkIGdlbmRlciBvZiB0aGUgdm9pY2UuIElmIG5vdCBzZXQs
IHRoZSBzZXJ2aWNlIHdpbGwKIGNob29zZSBhIHZvaWNlIGJhc2VkIG9uIHRoZSBvdGhlciBw
YXJhbWV0ZXJzIHN1Y2ggYXMgbGFuZ3VhZ2VfY29kZSBhbmQKIFtuYW1lXVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlZvaWNlU2VsZWN0aW9uUGFyYW1zLm5hbWVdLiBO
b3RlCiB0aGF0IHRoaXMgaXMgb25seSBhIHByZWZlcmVuY2UsIG5vdCByZXF1aXJlbWVudC4g
SWYgYSB2b2ljZSBvZiB0aGUKIGFwcHJvcHJpYXRlIGdlbmRlciBpcyBub3QgYXZhaWxhYmxl
LCB0aGUgc3ludGhlc2l6ZXIgc2hvdWxkIHN1YnN0aXR1dGUgYQogdm9pY2Ugd2l0aCBhIGRp
ZmZlcmVudCBnZW5kZXIgcmF0aGVyIHRoYW4gZmFpbGluZyB0aGUgcmVxdWVzdC4KCg0KBQQD
AgEGEgSPAgIRCg0KBQQDAgEBEgSPAhIdCg0KBQQDAgEDEgSPAiAhCkIKAgQEEgaTAgCwAgEa
NCBDb25maWd1cmF0aW9uIG9mIGhvdyBzcGVlY2ggc2hvdWxkIGJlIHN5bnRoZXNpemVkLgoK
CwoDBAQBEgSTAggeCqMCCgQEBAIAEgSYAgIbGpQCIE9wdGlvbmFsLiBTcGVha2luZyByYXRl
L3NwZWVkLCBpbiB0aGUgcmFuZ2UgWzAuMjUsIDQuMF0uIDEuMCBpcyB0aGUgbm9ybWFsCiBu
YXRpdmUgc3BlZWQgc3VwcG9ydGVkIGJ5IHRoZSBzcGVjaWZpYyB2b2ljZS4gMi4wIGlzIHR3
aWNlIGFzIGZhc3QsIGFuZAogMC41IGlzIGhhbGYgYXMgZmFzdC4gSWYgdW5zZXQoMC4wKSwg
ZGVmYXVsdHMgdG8gdGhlIG5hdGl2ZSAxLjAgc3BlZWQuIEFueQogb3RoZXIgdmFsdWVzIDwg
MC4yNSBvciA+IDQuMCB3aWxsIHJldHVybiBhbiBlcnJvci4KCg0KBQQEAgAFEgSYAgIICg0K
BQQEAgABEgSYAgkWCg0KBQQEAgADEgSYAhkaCrkBCgQEBAIBEgSdAgITGqoBIE9wdGlvbmFs
LiBTcGVha2luZyBwaXRjaCwgaW4gdGhlIHJhbmdlIFstMjAuMCwgMjAuMF0uIDIwIG1lYW5z
IGluY3JlYXNlIDIwCiBzZW1pdG9uZXMgZnJvbSB0aGUgb3JpZ2luYWwgcGl0Y2guIC0yMCBt
ZWFucyBkZWNyZWFzZSAyMCBzZW1pdG9uZXMgZnJvbSB0aGUKIG9yaWdpbmFsIHBpdGNoLgoK
DQoFBAQCAQUSBJ0CAggKDQoFBAQCAQESBJ0CCQ4KDQoFBAQCAQMSBJ0CERIKvAQKBAQEAgIS
BKcCAhwarQQgT3B0aW9uYWwuIFZvbHVtZSBnYWluIChpbiBkQikgb2YgdGhlIG5vcm1hbCBu
YXRpdmUgdm9sdW1lIHN1cHBvcnRlZCBieSB0aGUKIHNwZWNpZmljIHZvaWNlLCBpbiB0aGUg
cmFuZ2UgWy05Ni4wLCAxNi4wXS4gSWYgdW5zZXQsIG9yIHNldCB0byBhIHZhbHVlIG9mCiAw
LjAgKGRCKSwgd2lsbCBwbGF5IGF0IG5vcm1hbCBuYXRpdmUgc2lnbmFsIGFtcGxpdHVkZS4g
QSB2YWx1ZSBvZiAtNi4wIChkQikKIHdpbGwgcGxheSBhdCBhcHByb3hpbWF0ZWx5IGhhbGYg
dGhlIGFtcGxpdHVkZSBvZiB0aGUgbm9ybWFsIG5hdGl2ZSBzaWduYWwKIGFtcGxpdHVkZS4g
QSB2YWx1ZSBvZiArNi4wIChkQikgd2lsbCBwbGF5IGF0IGFwcHJveGltYXRlbHkgdHdpY2Ug
dGhlCiBhbXBsaXR1ZGUgb2YgdGhlIG5vcm1hbCBuYXRpdmUgc2lnbmFsIGFtcGxpdHVkZS4g
V2Ugc3Ryb25nbHkgcmVjb21tZW5kIG5vdAogdG8gZXhjZWVkICsxMCAoZEIpIGFzIHRoZXJl
J3MgdXN1YWxseSBubyBlZmZlY3RpdmUgaW5jcmVhc2UgaW4gbG91ZG5lc3MgZm9yCiBhbnkg
dmFsdWUgZ3JlYXRlciB0aGFuIHRoYXQuCgoNCgUEBAICBRIEpwICCAoNCgUEBAICARIEpwIJ
FwoNCgUEBAICAxIEpwIaGwrOAQoEBAQCAxIErAICKRq/ASBPcHRpb25hbC4gQW4gaWRlbnRp
ZmllciB3aGljaCBzZWxlY3RzICdhdWRpbyBlZmZlY3RzJyBwcm9maWxlcyB0aGF0IGFyZQog
YXBwbGllZCBvbiAocG9zdCBzeW50aGVzaXplZCkgdGV4dCB0byBzcGVlY2guIEVmZmVjdHMg
YXJlIGFwcGxpZWQgb24gdG9wIG9mCiBlYWNoIG90aGVyIGluIHRoZSBvcmRlciB0aGV5IGFy
ZSBnaXZlbi4KCg0KBQQEAgMEEgSsAgIKCg0KBQQEAgMFEgSsAgsRCg0KBQQEAgMBEgSsAhIk
Cg0KBQQEAgMDEgSsAicoCkUKBAQEAgQSBK8CAiEaNyBPcHRpb25hbC4gVGhlIGRlc2lyZWQg
dm9pY2Ugb2YgdGhlIHN5bnRoZXNpemVkIGF1ZGlvLgoKDQoFBAQCBAYSBK8CAhYKDQoFBAQC
BAESBK8CFxwKDQoFBAQCBAMSBK8CHyAKTAoCBQMSBrMCAM4CARo+IEF1ZGlvIGVuY29kaW5n
IG9mIHRoZSBvdXRwdXQgYXVkaW8gZm9ybWF0IGluIFRleHQtVG8tU3BlZWNoLgoKCwoDBQMB
EgSzAgUYCh4KBAUDAgASBLUCAigaECBOb3Qgc3BlY2lmaWVkLgoKDQoFBQMCAAESBLUCAiMK
DQoFBQMCAAISBLUCJicKowEKBAUDAgESBLoCAiYalAEgVW5jb21wcmVzc2VkIDE2LWJpdCBz
aWduZWQgbGl0dGxlLWVuZGlhbiBzYW1wbGVzIChMaW5lYXIgUENNKS4KIEF1ZGlvIGNvbnRl
bnQgcmV0dXJuZWQgYXMgTElORUFSMTYgYWxzbyBjb250YWlucyBhIFdBViBoZWFkZXIuCiBM
SU5UOiBMRUdBQ1lfTkFNRVMKCg0KBQUDAgEBEgS6AgIhCg0KBQUDAgECEgS6AiQlCiQKBAUD
AgISBL0CAjQaFiBNUDMgYXVkaW8gYXQgNjRrYnBzLgoKDQoFBQMCAgESBL0CAhsKDQoFBQMC
AgISBL0CHh8KDQoFBQMCAgMSBL0CIDMKDgoGBQMCAgMBEgS9AiEyCjgKBAUDAgMSBMECAiga
KiBNUDMgYXVkaW8gYXQgNjRrYnBzLgogTElOVDogTEVHQUNZX05BTUVTCgoNCgUFAwIDARIE
wQICIwoNCgUFAwIDAhIEwQImJwqdAgoEBQMCBBIExwICJRqOAiBPcHVzIGVuY29kZWQgYXVk
aW8gd3JhcHBlZCBpbiBhbiBvZ2cgY29udGFpbmVyLiBUaGUgcmVzdWx0IHdpbGwgYmUgYQog
ZmlsZSB3aGljaCBjYW4gYmUgcGxheWVkIG5hdGl2ZWx5IG9uIEFuZHJvaWQsIGFuZCBpbiBi
cm93c2VycyAoYXQgbGVhc3QKIENocm9tZSBhbmQgRmlyZWZveCkuIFRoZSBxdWFsaXR5IG9m
IHRoZSBlbmNvZGluZyBpcyBjb25zaWRlcmFibHkgaGlnaGVyCiB0aGFuIE1QMyB3aGlsZSB1
c2luZyBhcHByb3hpbWF0ZWx5IHRoZSBzYW1lIGJpdHJhdGUuCgoNCgUFAwIEARIExwICIAoN
CgUFAwIEAhIExwIjJApYCgQFAwIFEgTKAgIiGkogOC1iaXQgc2FtcGxlcyB0aGF0IGNvbXBh
bmQgMTQtYml0IGF1ZGlvIHNhbXBsZXMgdXNpbmcgRy43MTEgUENNVS9tdS1sYXcuCgoNCgUF
AwIFARIEygICHQoNCgUFAwIFAhIEygIgIQpXCgQFAwIGEgTNAgIhGkkgOC1iaXQgc2FtcGxl
cyB0aGF0IGNvbXBhbmQgMTMtYml0IGF1ZGlvIHNhbXBsZXMgdXNpbmcgRy43MTEgUENNVS9h
LWxhdy4KCg0KBQUDAgYBEgTNAgIcCg0KBQUDAgYCEgTNAh8gCloKAgQFEgbRAgDiAgEaTCBJ
bnN0cnVjdHMgdGhlIHNwZWVjaCBzeW50aGVzaXplciBob3cgdG8gZ2VuZXJhdGUgdGhlIG91
dHB1dCBhdWRpbyBjb250ZW50LgoKCwoDBAUBEgTRAggZCkwKBAQFAgASBtMCAtQCLxo8IFJl
cXVpcmVkLiBBdWRpbyBlbmNvZGluZyBvZiB0aGUgc3ludGhlc2l6ZWQgYXVkaW8gY29udGVu
dC4KCg0KBQQFAgAGEgTTAgIVCg0KBQQFAgABEgTTAhYkCg0KBQQFAgADEgTTAicoCg0KBQQF
AgAIEgTUAgYuChAKCAQFAgAInAgAEgTUAgctCvUCCgQEBQIBEgTbAgIeGuYCIE9wdGlvbmFs
LiBUaGUgc3ludGhlc2lzIHNhbXBsZSByYXRlIChpbiBoZXJ0eikgZm9yIHRoaXMgYXVkaW8u
IElmIG5vdAogcHJvdmlkZWQsIHRoZW4gdGhlIHN5bnRoZXNpemVyIHdpbGwgdXNlIHRoZSBk
ZWZhdWx0IHNhbXBsZSByYXRlIGJhc2VkIG9uCiB0aGUgYXVkaW8gZW5jb2RpbmcuIElmIHRo
aXMgaXMgZGlmZmVyZW50IGZyb20gdGhlIHZvaWNlJ3MgbmF0dXJhbCBzYW1wbGUKIHJhdGUs
IHRoZW4gdGhlIHN5bnRoZXNpemVyIHdpbGwgaG9ub3IgdGhpcyByZXF1ZXN0IGJ5IGNvbnZl
cnRpbmcgdG8gdGhlCiBkZXNpcmVkIHNhbXBsZSByYXRlICh3aGljaCBtaWdodCByZXN1bHQg
aW4gd29yc2UgYXVkaW8gcXVhbGl0eSkuCgoNCgUEBQIBBRIE2wICBwoNCgUEBQIBARIE2wII
GQoNCgUEBQIBAxIE2wIcHQrQAQoEBAUCAhIE4QICNhrBASBPcHRpb25hbC4gQ29uZmlndXJh
dGlvbiBvZiBob3cgc3BlZWNoIHNob3VsZCBiZSBzeW50aGVzaXplZC4KIElmIG5vdCBzcGVj
aWZpZWQsCiBbQWdlbnQudGV4dF90b19zcGVlY2hfc2V0dGluZ3NdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzYmV0YTEuQWdlbnQudGV4dF90b19zcGVlY2hfc2V0dGluZ3NdCiBp
cyBhcHBsaWVkLgoKDQoFBAUCAgYSBOECAhgKDQoFBAUCAgESBOECGTEKDQoFBAUCAgMSBOEC
NDUKOAoCBAYSBuUCAPgCARoqIFNldHRpbmdzIHJlbGF0ZWQgdG8gc3BlZWNoIHN5bnRoZXNp
emluZy4KCgsKAwQGARIE5QIIHArCBgoEBAYCABIE9wICRBqzBiBDb25maWd1cmF0aW9uIG9m
IGhvdyBzcGVlY2ggc2hvdWxkIGJlIHN5bnRoZXNpemVkLCBtYXBwaW5nIGZyb20gbGFuZ3Vh
Z2UKIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL3JlZmVy
ZW5jZS9sYW5ndWFnZSkgdG8KIFN5bnRoZXNpemVTcGVlY2hDb25maWcuCgogVGhlc2Ugc2V0
dGluZ3MgYWZmZWN0OgoKICAtIFRoZSBbcGhvbmUKICBnYXRld2F5XShodHRwczovL2Nsb3Vk
Lmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvaW50ZWdyYXRpb24vcGhv
bmUtZ2F0ZXdheSkKICAgIHN5bnRoZXNpemUgY29uZmlndXJhdGlvbiBzZXQgdmlhCiAgICBb
QWdlbnQudGV4dF90b19zcGVlY2hfc2V0dGluZ3NdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzYmV0YTEuQWdlbnQudGV4dF90b19zcGVlY2hfc2V0dGluZ3NdLgoKICAtIEhvdyBz
cGVlY2ggaXMgc3ludGhlc2l6ZWQgd2hlbiBpbnZva2luZwogIFtzZXNzaW9uXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlc3Npb25zXSBBUElzLgogICAgW0FnZW50
LnRleHRfdG9fc3BlZWNoX3NldHRpbmdzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
M2JldGExLkFnZW50LnRleHRfdG9fc3BlZWNoX3NldHRpbmdzXQogICAgb25seSBhcHBsaWVz
IGlmCiAgICBbT3V0cHV0QXVkaW9Db25maWcuc3ludGhlc2l6ZV9zcGVlY2hfY29uZmlnXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLk91dHB1dEF1ZGlvQ29uZmlnLnN5
bnRoZXNpemVfc3BlZWNoX2NvbmZpZ10KICAgIGlzIG5vdCBzcGVjaWZpZWQuCgoNCgUEBgIA
BhIE9wICJQoNCgUEBgIAARIE9wImPwoNCgUEBgIAAxIE9wJCQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SpeechWordInfo ===
    # Fields for SpeechWordInfo
    # Field: word Type: 9 ()
    # Field: start_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_offset Type: 11 (.google.protobuf.Duration)
    # Field: confidence Type: 2 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::BargeInConfig ===
    # Fields for BargeInConfig
    # Field: no_barge_in_duration Type: 11 (.google.protobuf.Duration)
    # Field: total_duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::InputAudioConfig ===
    # Fields for InputAudioConfig
    # Field: audio_encoding Type: 14 (.google.cloud.dialogflow.cx.v3beta1.AudioEncoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: enable_word_info Type: 8 ()
    # Field: phrase_hints Type: 9 ()
    # Field: model Type: 9 ()
    # Field: model_variant Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SpeechModelVariant)
    # Field: single_utterance Type: 8 ()
    # Field: barge_in_config Type: 11 (.google.cloud.dialogflow.cx.v3beta1.BargeInConfig)
    # Field: opt_out_conformer_model_migration Type: 8 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::VoiceSelectionParams ===
    # Fields for VoiceSelectionParams
    # Field: name Type: 9 ()
    # Field: ssml_gender Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SsmlVoiceGender)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SynthesizeSpeechConfig ===
    # Fields for SynthesizeSpeechConfig
    # Field: speaking_rate Type: 1 ()
    # Field: pitch Type: 1 ()
    # Field: volume_gain_db Type: 1 ()
    # Field: effects_profile_id Type: 9 ()
    # Field: voice Type: 11 (.google.cloud.dialogflow.cx.v3beta1.VoiceSelectionParams)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::OutputAudioConfig ===
    # Fields for OutputAudioConfig
    # Field: audio_encoding Type: 14 (.google.cloud.dialogflow.cx.v3beta1.OutputAudioEncoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: synthesize_speech_config Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SynthesizeSpeechConfig)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::TextToSpeechSettings ===
    # Fields for TextToSpeechSettings
    # Field: synthesize_speech_configs Type: 11 (.google.cloud.dialogflow.cx.v3beta1.TextToSpeechSettings.SynthesizeSpeechConfigsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/audio_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SpeechWordInfo->new({
        word => $word,
        start_offset => $start_offset,
        end_offset => $end_offset,
        confidence => $confidence,
    });

    # Read or update a field
    my $val = $msg->word();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SpeechWordInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/audio_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SpeechWordInfo

Information for a word recognized by the speech recognizer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->word() >> / C<< $msg->word($value) >>

Type: C<String>

The word this info is for.

=item * C<< $msg->start_offset() >> / C<< $msg->start_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time offset relative to the beginning of the audio that corresponds to the
start of the spoken word. This is an experimental feature and the accuracy
of the time offset can vary.

=item * C<< $msg->end_offset() >> / C<< $msg->end_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time offset relative to the beginning of the audio that corresponds to the
end of the spoken word. This is an experimental feature and the accuracy of
the time offset can vary.

=item * C<< $msg->confidence() >> / C<< $msg->confidence($value) >>

Type: C<Float>

The Speech confidence between 0.0 and 1.0 for this word. A higher number
indicates an estimated greater likelihood that the recognized word is
correct. The default of 0.0 is a sentinel value indicating that confidence
was not set.

This field is not guaranteed to be fully stable over time for the same
audio input. Users should also not rely on it to always be provided.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::BargeInConfig

Configuration of the barge-in behavior. Barge-in instructs the API to return
a detected utterance at a proper time while the client is playing back the
response audio from a previous request. When the client sees the
utterance, it should stop the playback and immediately get ready for
receiving the responses for the current request.

The barge-in handling requires the client to start streaming audio input
as soon as it starts playing back the audio from the previous response. The
playback is modeled into two phases:

* No barge-in phase: which goes first and during which speech detection
  should not be carried out.

* Barge-in phase: which follows the no barge-in phase and during which
  the API starts speech detection and may inform the client that an utterance
  has been detected. Note that no-speech event is not expected in this
  phase.

The client provides this configuration in terms of the durations of those
two phases. The durations are measured in terms of the audio length from the
start of the input audio.

No-speech event is a response with END_OF_UTTERANCE without any transcript
following up.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->no_barge_in_duration() >> / C<< $msg->no_barge_in_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration that is not eligible for barge-in at the beginning of the input
audio.

=item * C<< $msg->total_duration() >> / C<< $msg->total_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Total duration for the playback at the beginning of the input audio.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::InputAudioConfig

Instructs the speech recognizer on how to process the audio content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_encoding() >> / C<< $msg->audio_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioEncoding>)

Required. Audio encoding of the audio content to process.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Sample rate (in Hertz) of the audio content sent in the query.
Refer to
[Cloud Speech API
documentation](https://cloud.google.com/speech-to-text/docs/basics) for
more details.

=item * C<< $msg->enable_word_info() >> / C<< $msg->enable_word_info($value) >>

Type: C<Bool>

Optional. If `true`, Dialogflow returns
[SpeechWordInfo][google.cloud.dialogflow.cx.v3beta1.SpeechWordInfo] in
[StreamingRecognitionResult][google.cloud.dialogflow.cx.v3beta1.StreamingRecognitionResult]
with information about the recognized speech words, e.g. start and end time
offsets. If false or unspecified, Speech doesn't return any word-level
information.

=item * C<< $msg->phrase_hints() >> / C<< $msg->phrase_hints($value) >>

Type: C<String>

Optional. A list of strings containing words and phrases that the speech
recognizer should recognize with higher likelihood.

See [the Cloud Speech
documentation](https://cloud.google.com/speech-to-text/docs/basics#phrase-hints)
for more details.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Optional. Which Speech model to select for the given request.
For more information, see
[Speech
models](https://cloud.google.com/dialogflow/cx/docs/concept/speech-models).

=item * C<< $msg->model_variant() >> / C<< $msg->model_variant($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SpeechModelVariant>)

Optional. Which variant of the [Speech
model][google.cloud.dialogflow.cx.v3beta1.InputAudioConfig.model] to use.

=item * C<< $msg->single_utterance() >> / C<< $msg->single_utterance($value) >>

Type: C<Bool>

Optional. If `false` (default), recognition does not cease until the
client closes the stream.
If `true`, the recognizer will detect a single spoken utterance in input
audio. Recognition ceases when it detects the audio's voice has
stopped or paused. In this case, once a detected intent is received, the
client should close the stream and start a new request with a new stream as
needed.
Note: This setting is relevant only for streaming methods.

=item * C<< $msg->barge_in_config() >> / C<< $msg->barge_in_config($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::BargeInConfig>)

Configuration of barge-in behavior during the streaming of input audio.

=item * C<< $msg->opt_out_conformer_model_migration() >> / C<< $msg->opt_out_conformer_model_migration($value) >>

Type: C<Bool>

If `true`, the request will opt out for STT conformer model migration.
This field will be deprecated once force migration takes place in June
2024. Please refer to [Dialogflow CX Speech model
migration](https://cloud.google.com/dialogflow/cx/docs/concept/speech-model-migration).

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::VoiceSelectionParams

Description of which voice to use for speech synthesis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the voice. If not set, the service will choose a
voice based on the other parameters such as language_code and
[ssml_gender][google.cloud.dialogflow.cx.v3beta1.VoiceSelectionParams.ssml_gender].

For the list of available voices, please refer to [Supported voices and
languages](https://cloud.google.com/text-to-speech/docs/voices).

=item * C<< $msg->ssml_gender() >> / C<< $msg->ssml_gender($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SsmlVoiceGender>)

Optional. The preferred gender of the voice. If not set, the service will
choose a voice based on the other parameters such as language_code and
[name][google.cloud.dialogflow.cx.v3beta1.VoiceSelectionParams.name]. Note
that this is only a preference, not requirement. If a voice of the
appropriate gender is not available, the synthesizer should substitute a
voice with a different gender rather than failing the request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SynthesizeSpeechConfig

Configuration of how speech should be synthesized.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->speaking_rate() >> / C<< $msg->speaking_rate($value) >>

Type: C<Double>

Optional. Speaking rate/speed, in the range [0.25, 4.0]. 1.0 is the normal
native speed supported by the specific voice. 2.0 is twice as fast, and
0.5 is half as fast. If unset(0.0), defaults to the native 1.0 speed. Any
other values < 0.25 or > 4.0 will return an error.

=item * C<< $msg->pitch() >> / C<< $msg->pitch($value) >>

Type: C<Double>

Optional. Speaking pitch, in the range [-20.0, 20.0]. 20 means increase 20
semitones from the original pitch. -20 means decrease 20 semitones from the
original pitch.

=item * C<< $msg->volume_gain_db() >> / C<< $msg->volume_gain_db($value) >>

Type: C<Double>

Optional. Volume gain (in dB) of the normal native volume supported by the
specific voice, in the range [-96.0, 16.0]. If unset, or set to a value of
0.0 (dB), will play at normal native signal amplitude. A value of -6.0 (dB)
will play at approximately half the amplitude of the normal native signal
amplitude. A value of +6.0 (dB) will play at approximately twice the
amplitude of the normal native signal amplitude. We strongly recommend not
to exceed +10 (dB) as there's usually no effective increase in loudness for
any value greater than that.

=item * C<< $msg->effects_profile_id() >> / C<< $msg->effects_profile_id($value) >>

Type: C<String>

Optional. An identifier which selects 'audio effects' profiles that are
applied on (post synthesized) text to speech. Effects are applied on top of
each other in the order they are given.

=item * C<< $msg->voice() >> / C<< $msg->voice($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::VoiceSelectionParams>)

Optional. The desired voice of the synthesized audio.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::OutputAudioConfig

Instructs the speech synthesizer how to generate the output audio content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_encoding() >> / C<< $msg->audio_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::OutputAudioEncoding>)

Required. Audio encoding of the synthesized audio content.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Optional. The synthesis sample rate (in hertz) for this audio. If not
provided, then the synthesizer will use the default sample rate based on
the audio encoding. If this is different from the voice's natural sample
rate, then the synthesizer will honor this request by converting to the
desired sample rate (which might result in worse audio quality).

=item * C<< $msg->synthesize_speech_config() >> / C<< $msg->synthesize_speech_config($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::SynthesizeSpeechConfig>)

Optional. Configuration of how speech should be synthesized.
If not specified,
[Agent.text_to_speech_settings][google.cloud.dialogflow.cx.v3beta1.Agent.text_to_speech_settings]
is applied.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::TextToSpeechSettings

Settings related to speech synthesizing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->synthesize_speech_configs() >> / C<< $msg->synthesize_speech_configs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::TextToSpeechSettings::SynthesizeSpeechConfigsEntry>)

Configuration of how speech should be synthesized, mapping from language
(https://cloud.google.com/dialogflow/cx/docs/reference/language) to
SynthesizeSpeechConfig.

These settings affect:

 - The [phone
 gateway](https://cloud.google.com/dialogflow/cx/docs/concept/integration/phone-gateway)
   synthesize configuration set via
   [Agent.text_to_speech_settings][google.cloud.dialogflow.cx.v3beta1.Agent.text_to_speech_settings].

 - How speech is synthesized when invoking
 [session][google.cloud.dialogflow.cx.v3beta1.Sessions] APIs.
   [Agent.text_to_speech_settings][google.cloud.dialogflow.cx.v3beta1.Agent.text_to_speech_settings]
   only applies if
   [OutputAudioConfig.synthesize_speech_config][google.cloud.dialogflow.cx.v3beta1.OutputAudioConfig.synthesize_speech_config]
   is not specified.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
