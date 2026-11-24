package Google::Cloud::Dialogflow::Cx::V3::AudioConfig;

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
CjBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9hdWRpb19jb25maWcucHJvdG8SHWdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVy
YXRpb24ucHJvdG8ivAEKDlNwZWVjaFdvcmRJbmZvEhIKBHdvcmQYAyABKAlSBHdvcmQSPAoM
c3RhcnRfb2Zmc2V0GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgtzdGFydE9m
ZnNldBI4CgplbmRfb2Zmc2V0GAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgll
bmRPZmZzZXQSHgoKY29uZmlkZW5jZRgEIAEoAlIKY29uZmlkZW5jZSKdAQoNQmFyZ2VJbkNv
bmZpZxJKChRub19iYXJnZV9pbl9kdXJhdGlvbhgBIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5E
dXJhdGlvblIRbm9CYXJnZUluRHVyYXRpb24SQAoOdG90YWxfZHVyYXRpb24YAiABKAsyGS5n
b29nbGUucHJvdG9idWYuRHVyYXRpb25SDXRvdGFsRHVyYXRpb24ingQKEElucHV0QXVkaW9D
b25maWcSWAoOYXVkaW9fZW5jb2RpbmcYASABKA4yLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5BdWRpb0VuY29kaW5nQgPgQQJSDWF1ZGlvRW5jb2RpbmcSKgoRc2FtcGxlX3Jh
dGVfaGVydHoYAiABKAVSD3NhbXBsZVJhdGVIZXJ0ehIoChBlbmFibGVfd29yZF9pbmZvGA0g
ASgIUg5lbmFibGVXb3JkSW5mbxIhCgxwaHJhc2VfaGludHMYBCADKAlSC3BocmFzZUhpbnRz
EhQKBW1vZGVsGAcgASgJUgVtb2RlbBJWCg1tb2RlbF92YXJpYW50GAogASgOMjEuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU3BlZWNoTW9kZWxWYXJpYW50Ugxtb2RlbFZhcmlh
bnQSKQoQc2luZ2xlX3V0dGVyYW5jZRgIIAEoCFIPc2luZ2xlVXR0ZXJhbmNlElQKD2Jhcmdl
X2luX2NvbmZpZxgPIAEoCzIsLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkJhcmdl
SW5Db25maWdSDWJhcmdlSW5Db25maWcSSAohb3B0X291dF9jb25mb3JtZXJfbW9kZWxfbWln
cmF0aW9uGBogASgIUh1vcHRPdXRDb25mb3JtZXJNb2RlbE1pZ3JhdGlvbiJ7ChRWb2ljZVNl
bGVjdGlvblBhcmFtcxISCgRuYW1lGAEgASgJUgRuYW1lEk8KC3NzbWxfZ2VuZGVyGAIgASgO
Mi4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU3NtbFZvaWNlR2VuZGVyUgpzc21s
R2VuZGVyIvIBChZTeW50aGVzaXplU3BlZWNoQ29uZmlnEiMKDXNwZWFraW5nX3JhdGUYASAB
KAFSDHNwZWFraW5nUmF0ZRIUCgVwaXRjaBgCIAEoAVIFcGl0Y2gSJAoOdm9sdW1lX2dhaW5f
ZGIYAyABKAFSDHZvbHVtZUdhaW5EYhIsChJlZmZlY3RzX3Byb2ZpbGVfaWQYBSADKAlSEGVm
ZmVjdHNQcm9maWxlSWQSSQoFdm9pY2UYBCABKAsyMy5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5Wb2ljZVNlbGVjdGlvblBhcmFtc1IFdm9pY2UikAIKEU91dHB1dEF1ZGlvQ29u
ZmlnEl4KDmF1ZGlvX2VuY29kaW5nGAEgASgOMjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjMuT3V0cHV0QXVkaW9FbmNvZGluZ0ID4EECUg1hdWRpb0VuY29kaW5nEioKEXNhbXBs
ZV9yYXRlX2hlcnR6GAIgASgFUg9zYW1wbGVSYXRlSGVydHoSbwoYc3ludGhlc2l6ZV9zcGVl
Y2hfY29uZmlnGAMgASgLMjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU3ludGhl
c2l6ZVNwZWVjaENvbmZpZ1IWc3ludGhlc2l6ZVNwZWVjaENvbmZpZyKpAgoUVGV4dFRvU3Bl
ZWNoU2V0dGluZ3MSjAEKGXN5bnRoZXNpemVfc3BlZWNoX2NvbmZpZ3MYASADKAsyUC5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5UZXh0VG9TcGVlY2hTZXR0aW5ncy5TeW50aGVz
aXplU3BlZWNoQ29uZmlnc0VudHJ5UhdzeW50aGVzaXplU3BlZWNoQ29uZmlncxqBAQocU3lu
dGhlc2l6ZVNwZWVjaENvbmZpZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRJLCgV2YWx1ZRgC
IAEoCzI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlN5bnRoZXNpemVTcGVlY2hD
b25maWdSBXZhbHVlOgI4ASqUAgoNQXVkaW9FbmNvZGluZxIeChpBVURJT19FTkNPRElOR19V
TlNQRUNJRklFRBAAEhwKGEFVRElPX0VOQ09ESU5HX0xJTkVBUl8xNhABEhcKE0FVRElPX0VO
Q09ESU5HX0ZMQUMQAhIYChRBVURJT19FTkNPRElOR19NVUxBVxADEhYKEkFVRElPX0VOQ09E
SU5HX0FNUhAEEhkKFUFVRElPX0VOQ09ESU5HX0FNUl9XQhAFEhsKF0FVRElPX0VOQ09ESU5H
X09HR19PUFVTEAYSKQolQVVESU9fRU5DT0RJTkdfU1BFRVhfV0lUSF9IRUFERVJfQllURRAH
EhcKE0FVRElPX0VOQ09ESU5HX0FMQVcQCCp2ChJTcGVlY2hNb2RlbFZhcmlhbnQSJAogU1BF
RUNIX01PREVMX1ZBUklBTlRfVU5TUEVDSUZJRUQQABIWChJVU0VfQkVTVF9BVkFJTEFCTEUQ
ARIQCgxVU0VfU1RBTkRBUkQQAhIQCgxVU0VfRU5IQU5DRUQQAyqNAQoPU3NtbFZvaWNlR2Vu
ZGVyEiEKHVNTTUxfVk9JQ0VfR0VOREVSX1VOU1BFQ0lGSUVEEAASGgoWU1NNTF9WT0lDRV9H
RU5ERVJfTUFMRRABEhwKGFNTTUxfVk9JQ0VfR0VOREVSX0ZFTUFMRRACEh0KGVNTTUxfVk9J
Q0VfR0VOREVSX05FVVRSQUwQAyqQAgoTT3V0cHV0QXVkaW9FbmNvZGluZxIlCiFPVVRQVVRf
QVVESU9fRU5DT0RJTkdfVU5TUEVDSUZJRUQQABIjCh9PVVRQVVRfQVVESU9fRU5DT0RJTkdf
TElORUFSXzE2EAESIQoZT1VUUFVUX0FVRElPX0VOQ09ESU5HX01QMxACGgIIARIlCiFPVVRQ
VVRfQVVESU9fRU5DT0RJTkdfTVAzXzY0X0tCUFMQBBIiCh5PVVRQVVRfQVVESU9fRU5DT0RJ
TkdfT0dHX09QVVMQAxIfChtPVVRQVVRfQVVESU9fRU5DT0RJTkdfTVVMQVcQBRIeChpPVVRQ
VVRfQVVESU9fRU5DT0RJTkdfQUxBVxAGQosCCiFjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjNCEEF1ZGlvQ29uZmlnUHJvdG9QAVoxY2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFs
b2dmbG93L2N4L2FwaXYzL2N4cGI7Y3hwYqICAkRGqgIdR29vZ2xlLkNsb3VkLkRpYWxvZ2Zs
b3cuQ3guVjPqAiFHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjPqQVUKG2F1dG9t
bC5nb29nbGVhcGlzLmNvbS9Nb2RlbBI2cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L21vZGVscy97bW9kZWx9Sut7CgcSBQ4A+AIBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgID
AhIDFAAoCggKAQgSAxYAOgoJCgIIJRIDFgA6CggKAQgSAxcASAoJCgIICxIDFwBICggKAQgS
AxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMQoJCgIICBIDGQAxCggKAQgSAxoAOgoJCgIIARID
GgA6CggKAQgSAxsAIAoJCgIIJBIDGwAgCggKAQgSAxwAOgoJCgIILRIDHAA6CgkKAQgSBB0A
IAIKDAoECJ0IABIEHQAgAgrVAQoCBQASBCcAVQEayAEgQXVkaW8gZW5jb2Rpbmcgb2YgdGhl
IGF1ZGlvIGNvbnRlbnQgc2VudCBpbiB0aGUgY29udmVyc2F0aW9uYWwgcXVlcnkgcmVxdWVz
dC4KIFJlZmVyIHRvIHRoZQogW0Nsb3VkIFNwZWVjaCBBUEkKIGRvY3VtZW50YXRpb25dKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4dC9kb2NzL2Jhc2ljcykgZm9y
IG1vcmUKIGRldGFpbHMuCgoKCgMFAAESAycFEgodCgQFAAIAEgMpAiEaECBOb3Qgc3BlY2lm
aWVkLgoKDAoFBQACAAESAykCHAoMCgUFAAIAAhIDKR8gCmEKBAUAAgESAy0CHxpUIFVuY29t
cHJlc3NlZCAxNi1iaXQgc2lnbmVkIGxpdHRsZS1lbmRpYW4gc2FtcGxlcyAoTGluZWFyIFBD
TSkuCiBMSU5UOiBMRUdBQ1lfTkFNRVMKCgwKBQUAAgEBEgMtAhoKDAoFBQACAQISAy0dHgrs
AgoEBQACAhIDNAIaGt4CIFtgRkxBQ2BdKGh0dHBzOi8veGlwaC5vcmcvZmxhYy9kb2N1bWVu
dGF0aW9uLmh0bWwpIChGcmVlIExvc3NsZXNzIEF1ZGlvCiBDb2RlYykgaXMgdGhlIHJlY29t
bWVuZGVkIGVuY29kaW5nIGJlY2F1c2UgaXQgaXMgbG9zc2xlc3MgKHRoZXJlZm9yZQogcmVj
b2duaXRpb24gaXMgbm90IGNvbXByb21pc2VkKSBhbmQgcmVxdWlyZXMgb25seSBhYm91dCBo
YWxmIHRoZQogYmFuZHdpZHRoIG9mIGBMSU5FQVIxNmAuIGBGTEFDYCBzdHJlYW0gZW5jb2Rp
bmcgc3VwcG9ydHMgMTYtYml0IGFuZAogMjQtYml0IHNhbXBsZXMsIGhvd2V2ZXIsIG5vdCBh
bGwgZmllbGRzIGluIGBTVFJFQU1JTkZPYCBhcmUgc3VwcG9ydGVkLgoKDAoFBQACAgESAzQC
FQoMCgUFAAICAhIDNBgZClcKBAUAAgMSAzcCGxpKIDgtYml0IHNhbXBsZXMgdGhhdCBjb21w
YW5kIDE0LWJpdCBhdWRpbyBzYW1wbGVzIHVzaW5nIEcuNzExIFBDTVUvbXUtbGF3LgoKDAoF
BQACAwESAzcCFgoMCgUFAAIDAhIDNxkaClYKBAUAAgQSAzoCGRpJIEFkYXB0aXZlIE11bHRp
LVJhdGUgTmFycm93YmFuZCBjb2RlYy4gYHNhbXBsZV9yYXRlX2hlcnR6YCBtdXN0IGJlIDgw
MDAuCgoMCgUFAAIEARIDOgIUCgwKBQUAAgQCEgM6FxgKVQoEBQACBRIDPQIcGkggQWRhcHRp
dmUgTXVsdGktUmF0ZSBXaWRlYmFuZCBjb2RlYy4gYHNhbXBsZV9yYXRlX2hlcnR6YCBtdXN0
IGJlIDE2MDAwLgoKDAoFBQACBQESAz0CFwoMCgUFAAIFAhIDPRobCooBCgQFAAIGEgNCAh4a
fSBPcHVzIGVuY29kZWQgYXVkaW8gZnJhbWVzIGluIE9nZyBjb250YWluZXIKIChbT2dnT3B1
c10oaHR0cHM6Ly93aWtpLnhpcGgub3JnL09nZ09wdXMpKS4KIGBzYW1wbGVfcmF0ZV9oZXJ0
emAgbXVzdCBiZSAxNjAwMC4KCgwKBQUAAgYBEgNCAhkKDAoFBQACBgISA0IcHQrTBgoEBQAC
BxIDUQIsGsUGIEFsdGhvdWdoIHRoZSB1c2Ugb2YgbG9zc3kgZW5jb2RpbmdzIGlzIG5vdCBy
ZWNvbW1lbmRlZCwgaWYgYSB2ZXJ5IGxvdwogYml0cmF0ZSBlbmNvZGluZyBpcyByZXF1aXJl
ZCwgYE9HR19PUFVTYCBpcyBoaWdobHkgcHJlZmVycmVkIG92ZXIKIFNwZWV4IGVuY29kaW5n
LiBUaGUgW1NwZWV4XShodHRwczovL3NwZWV4Lm9yZy8pIGVuY29kaW5nIHN1cHBvcnRlZCBi
eQogRGlhbG9nZmxvdyBBUEkgaGFzIGEgaGVhZGVyIGJ5dGUgaW4gZWFjaCBibG9jaywgYXMg
aW4gTUlNRSB0eXBlCiBgYXVkaW8veC1zcGVleC13aXRoLWhlYWRlci1ieXRlYC4KIEl0IGlz
IGEgdmFyaWFudCBvZiB0aGUgUlRQIFNwZWV4IGVuY29kaW5nIGRlZmluZWQgaW4KIFtSRkMg
NTU3NF0oaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL3JmYzU1NzQpLgogVGhlIHN0cmVh
bSBpcyBhIHNlcXVlbmNlIG9mIGJsb2Nrcywgb25lIGJsb2NrIHBlciBSVFAgcGFja2V0LiBF
YWNoIGJsb2NrCiBzdGFydHMgd2l0aCBhIGJ5dGUgY29udGFpbmluZyB0aGUgbGVuZ3RoIG9m
IHRoZSBibG9jaywgaW4gYnl0ZXMsIGZvbGxvd2VkCiBieSBvbmUgb3IgbW9yZSBmcmFtZXMg
b2YgU3BlZXggZGF0YSwgcGFkZGVkIHRvIGFuIGludGVncmFsIG51bWJlciBvZgogYnl0ZXMg
KG9jdGV0cykgYXMgc3BlY2lmaWVkIGluIFJGQyA1NTc0LiBJbiBvdGhlciB3b3JkcywgZWFj
aCBSVFAgaGVhZGVyCiBpcyByZXBsYWNlZCB3aXRoIGEgc2luZ2xlIGJ5dGUgY29udGFpbmlu
ZyB0aGUgYmxvY2sgbGVuZ3RoLiBPbmx5IFNwZWV4CiB3aWRlYmFuZCBpcyBzdXBwb3J0ZWQu
IGBzYW1wbGVfcmF0ZV9oZXJ0emAgbXVzdCBiZSAxNjAwMC4KCgwKBQUAAgcBEgNRAicKDAoF
BQACBwISA1EqKwpWCgQFAAIIEgNUAhoaSSA4LWJpdCBzYW1wbGVzIHRoYXQgY29tcGFuZCAx
My1iaXQgYXVkaW8gc2FtcGxlcyB1c2luZyBHLjcxMSBQQ01VL2EtbGF3LgoKDAoFBQACCAES
A1QCFQoMCgUFAAIIAhIDVBgZCsYDCgIFARIEXwB4ARq5AyBWYXJpYW50IG9mIHRoZSBzcGVj
aWZpZWQgW1NwZWVjaAogbW9kZWxdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLklu
cHV0QXVkaW9Db25maWcubW9kZWxdIHRvIHVzZS4KCiBTZWUgdGhlIFtDbG91ZCBTcGVlY2gK
IGRvY3VtZW50YXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcGVlY2gtdG8tdGV4
dC9kb2NzL2VuaGFuY2VkLW1vZGVscykKIGZvciB3aGljaCBtb2RlbHMgaGF2ZSBkaWZmZXJl
bnQgdmFyaWFudHMuIEZvciBleGFtcGxlLCB0aGUgInBob25lX2NhbGwiIG1vZGVsCiBoYXMg
Ym90aCBhIHN0YW5kYXJkIGFuZCBhbiBlbmhhbmNlZCB2YXJpYW50LiBXaGVuIHlvdSB1c2Ug
YW4gZW5oYW5jZWQgbW9kZWwsCiB5b3Ugd2lsbCBnZW5lcmFsbHkgcmVjZWl2ZSBoaWdoZXIg
cXVhbGl0eSByZXN1bHRzIHRoYW4gZm9yIGEgc3RhbmRhcmQgbW9kZWwuCgoKCgMFAQESA18F
FwpjCgQFAQIAEgNiAicaViBObyBtb2RlbCB2YXJpYW50IHNwZWNpZmllZC4gSW4gdGhpcyBj
YXNlIERpYWxvZ2Zsb3cgZGVmYXVsdHMgdG8KIFVTRV9CRVNUX0FWQUlMQUJMRS4KCgwKBQUB
AgABEgNiAiIKDAoFBQECAAISA2IlJgp9CgQFAQIBEgNmAhkacCBVc2UgdGhlIGJlc3QgYXZh
aWxhYmxlIHZhcmlhbnQgb2YgdGhlIFtTcGVlY2gKIG1vZGVsXVtJbnB1dEF1ZGlvQ29uZmln
Lm1vZGVsXSB0aGF0IHRoZSBjYWxsZXIgaXMgZWxpZ2libGUgZm9yLgoKDAoFBQECAQESA2YC
FAoMCgUFAQIBAhIDZhcYCtwBCgQFAQICEgNsAhMazgEgVXNlIHN0YW5kYXJkIG1vZGVsIHZh
cmlhbnQgZXZlbiBpZiBhbiBlbmhhbmNlZCBtb2RlbCBpcyBhdmFpbGFibGUuICBTZWUgdGhl
CiBbQ2xvdWQgU3BlZWNoCiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vc3BlZWNoLXRvLXRleHQvZG9jcy9lbmhhbmNlZC1tb2RlbHMpCiBmb3IgZGV0YWlscyBh
Ym91dCBlbmhhbmNlZCBtb2RlbHMuCgoMCgUFAQICARIDbAIOCgwKBQUBAgICEgNsERIKhwMK
BAUBAgMSA3cCExr5AiBVc2UgYW4gZW5oYW5jZWQgbW9kZWwgdmFyaWFudDoKCiAqIElmIGFu
IGVuaGFuY2VkIHZhcmlhbnQgZG9lcyBub3QgZXhpc3QgZm9yIHRoZSBnaXZlbgogICBbbW9k
ZWxdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLklucHV0QXVkaW9Db25maWcubW9k
ZWxdIGFuZCByZXF1ZXN0CiAgIGxhbmd1YWdlLCBEaWFsb2dmbG93IGZhbGxzIGJhY2sgdG8g
dGhlIHN0YW5kYXJkIHZhcmlhbnQuCgogICBUaGUgW0Nsb3VkIFNwZWVjaAogICBkb2N1bWVu
dGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3BlZWNoLXRvLXRleHQvZG9jcy9l
bmhhbmNlZC1tb2RlbHMpCiAgIGRlc2NyaWJlcyB3aGljaCBtb2RlbHMgaGF2ZSBlbmhhbmNl
ZCB2YXJpYW50cy4KCgwKBQUBAgMBEgN3Ag4KDAoFBQECAwISA3cREgpKCgIEABIFewCRAQEa
PSBJbmZvcm1hdGlvbiBmb3IgYSB3b3JkIHJlY29nbml6ZWQgYnkgdGhlIHNwZWVjaCByZWNv
Z25pemVyLgoKCgoDBAABEgN7CBYKKQoEBAACABIDfQISGhwgVGhlIHdvcmQgdGhpcyBpbmZv
IGlzIGZvci4KCgwKBQQAAgAFEgN9AggKDAoFBAACAAESA30JDQoMCgUEAAIAAxIDfRARCsUB
CgQEAAIBEgSCAQIsGrYBIFRpbWUgb2Zmc2V0IHJlbGF0aXZlIHRvIHRoZSBiZWdpbm5pbmcg
b2YgdGhlIGF1ZGlvIHRoYXQgY29ycmVzcG9uZHMgdG8gdGhlCiBzdGFydCBvZiB0aGUgc3Bv
a2VuIHdvcmQuIFRoaXMgaXMgYW4gZXhwZXJpbWVudGFsIGZlYXR1cmUgYW5kIHRoZSBhY2N1
cmFjeQogb2YgdGhlIHRpbWUgb2Zmc2V0IGNhbiB2YXJ5LgoKDQoFBAACAQYSBIIBAhoKDQoF
BAACAQESBIIBGycKDQoFBAACAQMSBIIBKisKwwEKBAQAAgISBIcBAioatAEgVGltZSBvZmZz
ZXQgcmVsYXRpdmUgdG8gdGhlIGJlZ2lubmluZyBvZiB0aGUgYXVkaW8gdGhhdCBjb3JyZXNw
b25kcyB0byB0aGUKIGVuZCBvZiB0aGUgc3Bva2VuIHdvcmQuIFRoaXMgaXMgYW4gZXhwZXJp
bWVudGFsIGZlYXR1cmUgYW5kIHRoZSBhY2N1cmFjeSBvZgogdGhlIHRpbWUgb2Zmc2V0IGNh
biB2YXJ5LgoKDQoFBAACAgYSBIcBAhoKDQoFBAACAgESBIcBGyUKDQoFBAACAgMSBIcBKCkK
iQMKBAQAAgMSBJABAhca+gIgVGhlIFNwZWVjaCBjb25maWRlbmNlIGJldHdlZW4gMC4wIGFu
ZCAxLjAgZm9yIHRoaXMgd29yZC4gQSBoaWdoZXIgbnVtYmVyCiBpbmRpY2F0ZXMgYW4gZXN0
aW1hdGVkIGdyZWF0ZXIgbGlrZWxpaG9vZCB0aGF0IHRoZSByZWNvZ25pemVkIHdvcmQgaXMK
IGNvcnJlY3QuIFRoZSBkZWZhdWx0IG9mIDAuMCBpcyBhIHNlbnRpbmVsIHZhbHVlIGluZGlj
YXRpbmcgdGhhdCBjb25maWRlbmNlCiB3YXMgbm90IHNldC4KCiBUaGlzIGZpZWxkIGlzIG5v
dCBndWFyYW50ZWVkIHRvIGJlIGZ1bGx5IHN0YWJsZSBvdmVyIHRpbWUgZm9yIHRoZSBzYW1l
CiBhdWRpbyBpbnB1dC4gVXNlcnMgc2hvdWxkIGFsc28gbm90IHJlbHkgb24gaXQgdG8gYWx3
YXlzIGJlIHByb3ZpZGVkLgoKDQoFBAACAwUSBJABAgcKDQoFBAACAwESBJABCBIKDQoFBAAC
AwMSBJABFRYKhAkKAgQBEgarAQCyAQEa9QggQ29uZmlndXJhdGlvbiBvZiB0aGUgYmFyZ2Ut
aW4gYmVoYXZpb3IuIEJhcmdlLWluIGluc3RydWN0cyB0aGUgQVBJIHRvIHJldHVybgogYSBk
ZXRlY3RlZCB1dHRlcmFuY2UgYXQgYSBwcm9wZXIgdGltZSB3aGlsZSB0aGUgY2xpZW50IGlz
IHBsYXlpbmcgYmFjayB0aGUKIHJlc3BvbnNlIGF1ZGlvIGZyb20gYSBwcmV2aW91cyByZXF1
ZXN0LiBXaGVuIHRoZSBjbGllbnQgc2VlcyB0aGUKIHV0dGVyYW5jZSwgaXQgc2hvdWxkIHN0
b3AgdGhlIHBsYXliYWNrIGFuZCBpbW1lZGlhdGVseSBnZXQgcmVhZHkgZm9yCiByZWNlaXZp
bmcgdGhlIHJlc3BvbnNlcyBmb3IgdGhlIGN1cnJlbnQgcmVxdWVzdC4KCiBUaGUgYmFyZ2Ut
aW4gaGFuZGxpbmcgcmVxdWlyZXMgdGhlIGNsaWVudCB0byBzdGFydCBzdHJlYW1pbmcgYXVk
aW8gaW5wdXQKIGFzIHNvb24gYXMgaXQgc3RhcnRzIHBsYXlpbmcgYmFjayB0aGUgYXVkaW8g
ZnJvbSB0aGUgcHJldmlvdXMgcmVzcG9uc2UuIFRoZQogcGxheWJhY2sgaXMgbW9kZWxlZCBp
bnRvIHR3byBwaGFzZXM6CgogKiBObyBiYXJnZS1pbiBwaGFzZTogd2hpY2ggZ29lcyBmaXJz
dCBhbmQgZHVyaW5nIHdoaWNoIHNwZWVjaCBkZXRlY3Rpb24KICAgc2hvdWxkIG5vdCBiZSBj
YXJyaWVkIG91dC4KCiAqIEJhcmdlLWluIHBoYXNlOiB3aGljaCBmb2xsb3dzIHRoZSBubyBi
YXJnZS1pbiBwaGFzZSBhbmQgZHVyaW5nIHdoaWNoCiAgIHRoZSBBUEkgc3RhcnRzIHNwZWVj
aCBkZXRlY3Rpb24gYW5kIG1heSBpbmZvcm0gdGhlIGNsaWVudCB0aGF0IGFuIHV0dGVyYW5j
ZQogICBoYXMgYmVlbiBkZXRlY3RlZC4gTm90ZSB0aGF0IG5vLXNwZWVjaCBldmVudCBpcyBu
b3QgZXhwZWN0ZWQgaW4gdGhpcwogICBwaGFzZS4KCiBUaGUgY2xpZW50IHByb3ZpZGVzIHRo
aXMgY29uZmlndXJhdGlvbiBpbiB0ZXJtcyBvZiB0aGUgZHVyYXRpb25zIG9mIHRob3NlCiB0
d28gcGhhc2VzLiBUaGUgZHVyYXRpb25zIGFyZSBtZWFzdXJlZCBpbiB0ZXJtcyBvZiB0aGUg
YXVkaW8gbGVuZ3RoIGZyb20gdGhlCiBzdGFydCBvZiB0aGUgaW5wdXQgYXVkaW8uCgogTm8t
c3BlZWNoIGV2ZW50IGlzIGEgcmVzcG9uc2Ugd2l0aCBFTkRfT0ZfVVRURVJBTkNFIHdpdGhv
dXQgYW55IHRyYW5zY3JpcHQKIGZvbGxvd2luZyB1cC4KCgsKAwQBARIEqwEIFQpgCgQEAQIA
EgSuAQI0GlIgRHVyYXRpb24gdGhhdCBpcyBub3QgZWxpZ2libGUgZm9yIGJhcmdlLWluIGF0
IHRoZSBiZWdpbm5pbmcgb2YgdGhlIGlucHV0CiBhdWRpby4KCg0KBQQBAgAGEgSuAQIaCg0K
BQQBAgABEgSuARsvCg0KBQQBAgADEgSuATIzClQKBAQBAgESBLEBAi4aRiBUb3RhbCBkdXJh
dGlvbiBmb3IgdGhlIHBsYXliYWNrIGF0IHRoZSBiZWdpbm5pbmcgb2YgdGhlIGlucHV0IGF1
ZGlvLgoKDQoFBAECAQYSBLEBAhoKDQoFBAECAQESBLEBGykKDQoFBAECAQMSBLEBLC0KVAoC
BAISBrUBAOwBARpGIEluc3RydWN0cyB0aGUgc3BlZWNoIHJlY29nbml6ZXIgb24gaG93IHRv
IHByb2Nlc3MgdGhlIGF1ZGlvIGNvbnRlbnQuCgoLCgMEAgESBLUBCBgKSQoEBAICABIEtwEC
TBo7IFJlcXVpcmVkLiBBdWRpbyBlbmNvZGluZyBvZiB0aGUgYXVkaW8gY29udGVudCB0byBw
cm9jZXNzLgoKDQoFBAICAAYSBLcBAg8KDQoFBAICAAESBLcBEB4KDQoFBAICAAMSBLcBISIK
DQoFBAICAAgSBLcBI0sKEAoIBAICAAicCAASBLcBJEoKxAEKBAQCAgESBL4BAh4atQEgU2Ft
cGxlIHJhdGUgKGluIEhlcnR6KSBvZiB0aGUgYXVkaW8gY29udGVudCBzZW50IGluIHRoZSBx
dWVyeS4KIFJlZmVyIHRvCiBbQ2xvdWQgU3BlZWNoIEFQSQogZG9jdW1lbnRhdGlvbl0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL3NwZWVjaC10by10ZXh0L2RvY3MvYmFzaWNzKSBmb3IK
IG1vcmUgZGV0YWlscy4KCg0KBQQCAgEFEgS+AQIHCg0KBQQCAgEBEgS+AQgZCg0KBQQCAgED
EgS+ARwdCvYCCgQEAgICEgTGAQIdGucCIE9wdGlvbmFsLiBJZiBgdHJ1ZWAsIERpYWxvZ2Zs
b3cgcmV0dXJucwogW1NwZWVjaFdvcmRJbmZvXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5TcGVlY2hXb3JkSW5mb10gaW4KIFtTdHJlYW1pbmdSZWNvZ25pdGlvblJlc3VsdF1b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU3RyZWFtaW5nUmVjb2duaXRpb25SZXN1
bHRdCiB3aXRoIGluZm9ybWF0aW9uIGFib3V0IHRoZSByZWNvZ25pemVkIHNwZWVjaCB3b3Jk
cywgZS5nLiBzdGFydCBhbmQgZW5kIHRpbWUKIG9mZnNldHMuIElmIGZhbHNlIG9yIHVuc3Bl
Y2lmaWVkLCBTcGVlY2ggZG9lc24ndCByZXR1cm4gYW55IHdvcmQtbGV2ZWwKIGluZm9ybWF0
aW9uLgoKDQoFBAICAgUSBMYBAgYKDQoFBAICAgESBMYBBxcKDQoFBAICAgMSBMYBGhwKiwIK
BAQCAgMSBM4BAiMa/AEgT3B0aW9uYWwuIEEgbGlzdCBvZiBzdHJpbmdzIGNvbnRhaW5pbmcg
d29yZHMgYW5kIHBocmFzZXMgdGhhdCB0aGUgc3BlZWNoCiByZWNvZ25pemVyIHNob3VsZCBy
ZWNvZ25pemUgd2l0aCBoaWdoZXIgbGlrZWxpaG9vZC4KCiBTZWUgW3RoZSBDbG91ZCBTcGVl
Y2gKIGRvY3VtZW50YXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9zcGVlY2gtdG8t
dGV4dC9kb2NzL2Jhc2ljcyNwaHJhc2UtaGludHMpCiBmb3IgbW9yZSBkZXRhaWxzLgoKDQoF
BAICAwQSBM4BAgoKDQoFBAICAwUSBM4BCxEKDQoFBAICAwESBM4BEh4KDQoFBAICAwMSBM4B
ISIKvwEKBAQCAgQSBNQBAhMasAEgT3B0aW9uYWwuIFdoaWNoIFNwZWVjaCBtb2RlbCB0byBz
ZWxlY3QgZm9yIHRoZSBnaXZlbiByZXF1ZXN0LgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNl
ZQogW1NwZWVjaAogbW9kZWxzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxv
dy9jeC9kb2NzL2NvbmNlcHQvc3BlZWNoLW1vZGVscykuCgoNCgUEAgIEBRIE1AECCAoNCgUE
AgIEARIE1AEJDgoNCgUEAgIEAxIE1AEREgp8CgQEAgIFEgTYAQIoGm4gT3B0aW9uYWwuIFdo
aWNoIHZhcmlhbnQgb2YgdGhlIFtTcGVlY2gKIG1vZGVsXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52My5JbnB1dEF1ZGlvQ29uZmlnLm1vZGVsXSB0byB1c2UuCgoNCgUEAgIFBhIE
2AECFAoNCgUEAgIFARIE2AEVIgoNCgUEAgIFAxIE2AElJwrXAwoEBAICBhIE4gECHBrIAyBP
cHRpb25hbC4gSWYgYGZhbHNlYCAoZGVmYXVsdCksIHJlY29nbml0aW9uIGRvZXMgbm90IGNl
YXNlIHVudGlsIHRoZQogY2xpZW50IGNsb3NlcyB0aGUgc3RyZWFtLgogSWYgYHRydWVgLCB0
aGUgcmVjb2duaXplciB3aWxsIGRldGVjdCBhIHNpbmdsZSBzcG9rZW4gdXR0ZXJhbmNlIGlu
IGlucHV0CiBhdWRpby4gUmVjb2duaXRpb24gY2Vhc2VzIHdoZW4gaXQgZGV0ZWN0cyB0aGUg
YXVkaW8ncyB2b2ljZSBoYXMKIHN0b3BwZWQgb3IgcGF1c2VkLiBJbiB0aGlzIGNhc2UsIG9u
Y2UgYSBkZXRlY3RlZCBpbnRlbnQgaXMgcmVjZWl2ZWQsIHRoZQogY2xpZW50IHNob3VsZCBj
bG9zZSB0aGUgc3RyZWFtIGFuZCBzdGFydCBhIG5ldyByZXF1ZXN0IHdpdGggYSBuZXcgc3Ry
ZWFtIGFzCiBuZWVkZWQuCiBOb3RlOiBUaGlzIHNldHRpbmcgaXMgcmVsZXZhbnQgb25seSBm
b3Igc3RyZWFtaW5nIG1ldGhvZHMuCgoNCgUEAgIGBRIE4gECBgoNCgUEAgIGARIE4gEHFwoN
CgUEAgIGAxIE4gEaGwpXCgQEAgIHEgTlAQIlGkkgQ29uZmlndXJhdGlvbiBvZiBiYXJnZS1p
biBiZWhhdmlvciBkdXJpbmcgdGhlIHN0cmVhbWluZyBvZiBpbnB1dCBhdWRpby4KCg0KBQQC
AgcGEgTlAQIPCg0KBQQCAgcBEgTlARAfCg0KBQQCAgcDEgTlASIkCqsCCgQEAgIIEgTrAQIu
GpwCIElmIGB0cnVlYCwgdGhlIHJlcXVlc3Qgd2lsbCBvcHQgb3V0IGZvciBTVFQgY29uZm9y
bWVyIG1vZGVsIG1pZ3JhdGlvbi4KIFRoaXMgZmllbGQgd2lsbCBiZSBkZXByZWNhdGVkIG9u
Y2UgZm9yY2UgbWlncmF0aW9uIHRha2VzIHBsYWNlIGluIEp1bmUKIDIwMjQuIFBsZWFzZSBy
ZWZlciB0byBbRGlhbG9nZmxvdyBDWCBTcGVlY2ggbW9kZWwKIG1pZ3JhdGlvbl0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvY3gvZG9jcy9jb25jZXB0L3NwZWVjaC1t
b2RlbC1taWdyYXRpb24pLgoKDQoFBAICCAUSBOsBAgYKDQoFBAICCAESBOsBBygKDQoFBAIC
CAMSBOsBKy0KgAEKAgUCEgbwAQD9AQEaciBHZW5kZXIgb2YgdGhlIHZvaWNlIGFzIGRlc2Ny
aWJlZCBpbgogW1NTTUwgdm9pY2UgZWxlbWVudF0oaHR0cHM6Ly93d3cudzMub3JnL1RSL3Nw
ZWVjaC1zeW50aGVzaXMxMS8jZWRlZl92b2ljZSkuCgoLCgMFAgESBPABBRQKewoEBQICABIE
8wECJBptIEFuIHVuc3BlY2lmaWVkIGdlbmRlciwgd2hpY2ggbWVhbnMgdGhhdCB0aGUgY2xp
ZW50IGRvZXNuJ3QgY2FyZSB3aGljaAogZ2VuZGVyIHRoZSBzZWxlY3RlZCB2b2ljZSB3aWxs
IGhhdmUuCgoNCgUFAgIAARIE8wECHwoNCgUFAgIAAhIE8wEiIwodCgQFAgIBEgT2AQIdGg8g
QSBtYWxlIHZvaWNlLgoKDQoFBQICAQESBPYBAhgKDQoFBQICAQISBPYBGxwKHwoEBQICAhIE
+QECHxoRIEEgZmVtYWxlIHZvaWNlLgoKDQoFBQICAgESBPkBAhoKDQoFBQICAgISBPkBHR4K
JwoEBQICAxIE/AECIBoZIEEgZ2VuZGVyLW5ldXRyYWwgdm9pY2UuCgoNCgUFAgIDARIE/AEC
GwoNCgUFAgIDAhIE/AEeHwpHCgIEAxIGgAIAkAIBGjkgRGVzY3JpcHRpb24gb2Ygd2hpY2gg
dm9pY2UgdG8gdXNlIGZvciBzcGVlY2ggc3ludGhlc2lzLgoKCwoDBAMBEgSAAggcCvICCgQE
AwIAEgSHAgISGuMCIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdm9pY2UuIElmIG5vdCBz
ZXQsIHRoZSBzZXJ2aWNlIHdpbGwgY2hvb3NlIGEKIHZvaWNlIGJhc2VkIG9uIHRoZSBvdGhl
ciBwYXJhbWV0ZXJzIHN1Y2ggYXMgbGFuZ3VhZ2VfY29kZSBhbmQKIFtzc21sX2dlbmRlcl1b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVm9pY2VTZWxlY3Rpb25QYXJhbXMuc3Nt
bF9nZW5kZXJdLgoKIEZvciB0aGUgbGlzdCBvZiBhdmFpbGFibGUgdm9pY2VzLCBwbGVhc2Ug
cmVmZXIgdG8gW1N1cHBvcnRlZCB2b2ljZXMgYW5kCiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS90ZXh0LXRvLXNwZWVjaC9kb2NzL3ZvaWNlcykuCgoNCgUEAwIABRIE
hwICCAoNCgUEAwIAARIEhwIJDQoNCgUEAwIAAxIEhwIQEQqxAwoEBAMCARIEjwICIhqiAyBP
cHRpb25hbC4gVGhlIHByZWZlcnJlZCBnZW5kZXIgb2YgdGhlIHZvaWNlLiBJZiBub3Qgc2V0
LCB0aGUgc2VydmljZSB3aWxsCiBjaG9vc2UgYSB2b2ljZSBiYXNlZCBvbiB0aGUgb3RoZXIg
cGFyYW1ldGVycyBzdWNoIGFzIGxhbmd1YWdlX2NvZGUgYW5kCiBbbmFtZV1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuVm9pY2VTZWxlY3Rpb25QYXJhbXMubmFtZV0uIE5vdGUg
dGhhdAogdGhpcyBpcyBvbmx5IGEgcHJlZmVyZW5jZSwgbm90IHJlcXVpcmVtZW50LiBJZiBh
IHZvaWNlIG9mIHRoZSBhcHByb3ByaWF0ZQogZ2VuZGVyIGlzIG5vdCBhdmFpbGFibGUsIHRo
ZSBzeW50aGVzaXplciBzdWJzdGl0dXRlcyBhIHZvaWNlIHdpdGggYQogZGlmZmVyZW50IGdl
bmRlciByYXRoZXIgdGhhbiBmYWlsaW5nIHRoZSByZXF1ZXN0LgoKDQoFBAMCAQYSBI8CAhEK
DQoFBAMCAQESBI8CEh0KDQoFBAMCAQMSBI8CICEKQgoCBAQSBpMCALACARo0IENvbmZpZ3Vy
YXRpb24gb2YgaG93IHNwZWVjaCBzaG91bGQgYmUgc3ludGhlc2l6ZWQuCgoLCgMEBAESBJMC
CB4KowIKBAQEAgASBJgCAhsalAIgT3B0aW9uYWwuIFNwZWFraW5nIHJhdGUvc3BlZWQsIGlu
IHRoZSByYW5nZSBbMC4yNSwgNC4wXS4gMS4wIGlzIHRoZSBub3JtYWwKIG5hdGl2ZSBzcGVl
ZCBzdXBwb3J0ZWQgYnkgdGhlIHNwZWNpZmljIHZvaWNlLiAyLjAgaXMgdHdpY2UgYXMgZmFz
dCwgYW5kCiAwLjUgaXMgaGFsZiBhcyBmYXN0LiBJZiB1bnNldCgwLjApLCBkZWZhdWx0cyB0
byB0aGUgbmF0aXZlIDEuMCBzcGVlZC4gQW55CiBvdGhlciB2YWx1ZXMgPCAwLjI1IG9yID4g
NC4wIHdpbGwgcmV0dXJuIGFuIGVycm9yLgoKDQoFBAQCAAUSBJgCAggKDQoFBAQCAAESBJgC
CRYKDQoFBAQCAAMSBJgCGRoKuQEKBAQEAgESBJ0CAhMaqgEgT3B0aW9uYWwuIFNwZWFraW5n
IHBpdGNoLCBpbiB0aGUgcmFuZ2UgWy0yMC4wLCAyMC4wXS4gMjAgbWVhbnMgaW5jcmVhc2Ug
MjAKIHNlbWl0b25lcyBmcm9tIHRoZSBvcmlnaW5hbCBwaXRjaC4gLTIwIG1lYW5zIGRlY3Jl
YXNlIDIwIHNlbWl0b25lcyBmcm9tIHRoZQogb3JpZ2luYWwgcGl0Y2guCgoNCgUEBAIBBRIE
nQICCAoNCgUEBAIBARIEnQIJDgoNCgUEBAIBAxIEnQIREgq8BAoEBAQCAhIEpwICHBqtBCBP
cHRpb25hbC4gVm9sdW1lIGdhaW4gKGluIGRCKSBvZiB0aGUgbm9ybWFsIG5hdGl2ZSB2b2x1
bWUgc3VwcG9ydGVkIGJ5IHRoZQogc3BlY2lmaWMgdm9pY2UsIGluIHRoZSByYW5nZSBbLTk2
LjAsIDE2LjBdLiBJZiB1bnNldCwgb3Igc2V0IHRvIGEgdmFsdWUgb2YKIDAuMCAoZEIpLCB3
aWxsIHBsYXkgYXQgbm9ybWFsIG5hdGl2ZSBzaWduYWwgYW1wbGl0dWRlLiBBIHZhbHVlIG9m
IC02LjAgKGRCKQogd2lsbCBwbGF5IGF0IGFwcHJveGltYXRlbHkgaGFsZiB0aGUgYW1wbGl0
dWRlIG9mIHRoZSBub3JtYWwgbmF0aXZlIHNpZ25hbAogYW1wbGl0dWRlLiBBIHZhbHVlIG9m
ICs2LjAgKGRCKSB3aWxsIHBsYXkgYXQgYXBwcm94aW1hdGVseSB0d2ljZSB0aGUKIGFtcGxp
dHVkZSBvZiB0aGUgbm9ybWFsIG5hdGl2ZSBzaWduYWwgYW1wbGl0dWRlLiBXZSBzdHJvbmds
eSByZWNvbW1lbmQgbm90CiB0byBleGNlZWQgKzEwIChkQikgYXMgdGhlcmUncyB1c3VhbGx5
IG5vIGVmZmVjdGl2ZSBpbmNyZWFzZSBpbiBsb3VkbmVzcyBmb3IKIGFueSB2YWx1ZSBncmVh
dGVyIHRoYW4gdGhhdC4KCg0KBQQEAgIFEgSnAgIICg0KBQQEAgIBEgSnAgkXCg0KBQQEAgID
EgSnAhobCs4BCgQEBAIDEgSsAgIpGr8BIE9wdGlvbmFsLiBBbiBpZGVudGlmaWVyIHdoaWNo
IHNlbGVjdHMgJ2F1ZGlvIGVmZmVjdHMnIHByb2ZpbGVzIHRoYXQgYXJlCiBhcHBsaWVkIG9u
IChwb3N0IHN5bnRoZXNpemVkKSB0ZXh0IHRvIHNwZWVjaC4gRWZmZWN0cyBhcmUgYXBwbGll
ZCBvbiB0b3Agb2YKIGVhY2ggb3RoZXIgaW4gdGhlIG9yZGVyIHRoZXkgYXJlIGdpdmVuLgoK
DQoFBAQCAwQSBKwCAgoKDQoFBAQCAwUSBKwCCxEKDQoFBAQCAwESBKwCEiQKDQoFBAQCAwMS
BKwCJygKRQoEBAQCBBIErwICIRo3IE9wdGlvbmFsLiBUaGUgZGVzaXJlZCB2b2ljZSBvZiB0
aGUgc3ludGhlc2l6ZWQgYXVkaW8uCgoNCgUEBAIEBhIErwICFgoNCgUEBAIEARIErwIXHAoN
CgUEBAIEAxIErwIfIApMCgIFAxIGswIAzgIBGj4gQXVkaW8gZW5jb2Rpbmcgb2YgdGhlIG91
dHB1dCBhdWRpbyBmb3JtYXQgaW4gVGV4dC1Uby1TcGVlY2guCgoLCgMFAwESBLMCBRgKHgoE
BQMCABIEtQICKBoQIE5vdCBzcGVjaWZpZWQuCgoNCgUFAwIAARIEtQICIwoNCgUFAwIAAhIE
tQImJwqjAQoEBQMCARIEugICJhqUASBVbmNvbXByZXNzZWQgMTYtYml0IHNpZ25lZCBsaXR0
bGUtZW5kaWFuIHNhbXBsZXMgKExpbmVhciBQQ00pLgogQXVkaW8gY29udGVudCByZXR1cm5l
ZCBhcyBMSU5FQVIxNiBhbHNvIGNvbnRhaW5zIGEgV0FWIGhlYWRlci4KIExJTlQ6IExFR0FD
WV9OQU1FUwoKDQoFBQMCAQESBLoCAiEKDQoFBQMCAQISBLoCJCUKJAoEBQMCAhIEvQICNBoW
IE1QMyBhdWRpbyBhdCA2NGticHMuCgoNCgUFAwICARIEvQICGwoNCgUFAwICAhIEvQIeHwoN
CgUFAwICAxIEvQIgMwoOCgYFAwICAwESBL0CITIKOAoEBQMCAxIEwQICKBoqIE1QMyBhdWRp
byBhdCA2NGticHMuCiBMSU5UOiBMRUdBQ1lfTkFNRVMKCg0KBQUDAgMBEgTBAgIjCg0KBQUD
AgMCEgTBAiYnCp0CCgQFAwIEEgTHAgIlGo4CIE9wdXMgZW5jb2RlZCBhdWRpbyB3cmFwcGVk
IGluIGFuIG9nZyBjb250YWluZXIuIFRoZSByZXN1bHQgd2lsbCBiZSBhCiBmaWxlIHdoaWNo
IGNhbiBiZSBwbGF5ZWQgbmF0aXZlbHkgb24gQW5kcm9pZCwgYW5kIGluIGJyb3dzZXJzIChh
dCBsZWFzdAogQ2hyb21lIGFuZCBGaXJlZm94KS4gVGhlIHF1YWxpdHkgb2YgdGhlIGVuY29k
aW5nIGlzIGNvbnNpZGVyYWJseSBoaWdoZXIKIHRoYW4gTVAzIHdoaWxlIHVzaW5nIGFwcHJv
eGltYXRlbHkgdGhlIHNhbWUgYml0cmF0ZS4KCg0KBQUDAgQBEgTHAgIgCg0KBQUDAgQCEgTH
AiMkClgKBAUDAgUSBMoCAiIaSiA4LWJpdCBzYW1wbGVzIHRoYXQgY29tcGFuZCAxNC1iaXQg
YXVkaW8gc2FtcGxlcyB1c2luZyBHLjcxMSBQQ01VL211LWxhdy4KCg0KBQUDAgUBEgTKAgId
Cg0KBQUDAgUCEgTKAiAhClcKBAUDAgYSBM0CAiEaSSA4LWJpdCBzYW1wbGVzIHRoYXQgY29t
cGFuZCAxMy1iaXQgYXVkaW8gc2FtcGxlcyB1c2luZyBHLjcxMSBQQ01VL2EtbGF3LgoKDQoF
BQMCBgESBM0CAhwKDQoFBQMCBgISBM0CHyAKWgoCBAUSBtECAOICARpMIEluc3RydWN0cyB0
aGUgc3BlZWNoIHN5bnRoZXNpemVyIGhvdyB0byBnZW5lcmF0ZSB0aGUgb3V0cHV0IGF1ZGlv
IGNvbnRlbnQuCgoLCgMEBQESBNECCBkKTAoEBAUCABIG0wIC1AIvGjwgUmVxdWlyZWQuIEF1
ZGlvIGVuY29kaW5nIG9mIHRoZSBzeW50aGVzaXplZCBhdWRpbyBjb250ZW50LgoKDQoFBAUC
AAYSBNMCAhUKDQoFBAUCAAESBNMCFiQKDQoFBAUCAAMSBNMCJygKDQoFBAUCAAgSBNQCBi4K
EAoIBAUCAAicCAASBNQCBy0K9QIKBAQFAgESBNsCAh4a5gIgT3B0aW9uYWwuIFRoZSBzeW50
aGVzaXMgc2FtcGxlIHJhdGUgKGluIGhlcnR6KSBmb3IgdGhpcyBhdWRpby4gSWYgbm90CiBw
cm92aWRlZCwgdGhlbiB0aGUgc3ludGhlc2l6ZXIgd2lsbCB1c2UgdGhlIGRlZmF1bHQgc2Ft
cGxlIHJhdGUgYmFzZWQgb24KIHRoZSBhdWRpbyBlbmNvZGluZy4gSWYgdGhpcyBpcyBkaWZm
ZXJlbnQgZnJvbSB0aGUgdm9pY2UncyBuYXR1cmFsIHNhbXBsZQogcmF0ZSwgdGhlbiB0aGUg
c3ludGhlc2l6ZXIgd2lsbCBob25vciB0aGlzIHJlcXVlc3QgYnkgY29udmVydGluZyB0byB0
aGUKIGRlc2lyZWQgc2FtcGxlIHJhdGUgKHdoaWNoIG1pZ2h0IHJlc3VsdCBpbiB3b3JzZSBh
dWRpbyBxdWFsaXR5KS4KCg0KBQQFAgEFEgTbAgIHCg0KBQQFAgEBEgTbAggZCg0KBQQFAgED
EgTbAhwdCssBCgQEBQICEgThAgI2GrwBIE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIG9mIGhv
dyBzcGVlY2ggc2hvdWxkIGJlIHN5bnRoZXNpemVkLgogSWYgbm90IHNwZWNpZmllZCwKIFtB
Z2VudC50ZXh0X3RvX3NwZWVjaF9zZXR0aW5nc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjMuQWdlbnQudGV4dF90b19zcGVlY2hfc2V0dGluZ3NdCiBpcyBhcHBsaWVkLgoKDQoF
BAUCAgYSBOECAhgKDQoFBAUCAgESBOECGTEKDQoFBAUCAgMSBOECNDUKOAoCBAYSBuUCAPgC
ARoqIFNldHRpbmdzIHJlbGF0ZWQgdG8gc3BlZWNoIHN5bnRoZXNpemluZy4KCgsKAwQGARIE
5QIIHAquBgoEBAYCABIE9wICRBqfBiBDb25maWd1cmF0aW9uIG9mIGhvdyBzcGVlY2ggc2hv
dWxkIGJlIHN5bnRoZXNpemVkLCBtYXBwaW5nIGZyb20gbGFuZ3VhZ2UKIChodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL3JlZmVyZW5jZS9sYW5ndWFnZSkg
dG8KIFN5bnRoZXNpemVTcGVlY2hDb25maWcuCgogVGhlc2Ugc2V0dGluZ3MgYWZmZWN0OgoK
ICAtIFRoZSBbcGhvbmUKICBnYXRld2F5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlh
bG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvaW50ZWdyYXRpb24vcGhvbmUtZ2F0ZXdheSkKICAg
IHN5bnRoZXNpemUgY29uZmlndXJhdGlvbiBzZXQgdmlhCiAgICBbQWdlbnQudGV4dF90b19z
cGVlY2hfc2V0dGluZ3NdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkFnZW50LnRl
eHRfdG9fc3BlZWNoX3NldHRpbmdzXS4KCiAgLSBIb3cgc3BlZWNoIGlzIHN5bnRoZXNpemVk
IHdoZW4gaW52b2tpbmcKICBbc2Vzc2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djMuU2Vzc2lvbnNdIEFQSXMuCiAgICBbQWdlbnQudGV4dF90b19zcGVlY2hfc2V0dGluZ3Nd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkFnZW50LnRleHRfdG9fc3BlZWNoX3Nl
dHRpbmdzXQogICAgb25seSBhcHBsaWVzIGlmCiAgICBbT3V0cHV0QXVkaW9Db25maWcuc3lu
dGhlc2l6ZV9zcGVlY2hfY29uZmlnXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5P
dXRwdXRBdWRpb0NvbmZpZy5zeW50aGVzaXplX3NwZWVjaF9jb25maWddCiAgICBpcyBub3Qg
c3BlY2lmaWVkLgoKDQoFBAYCAAYSBPcCAiUKDQoFBAYCAAESBPcCJj8KDQoFBAYCAAMSBPcC
QkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo ===
    # Fields for SpeechWordInfo
    # Field: word Type: 9 ()
    # Field: start_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_offset Type: 11 (.google.protobuf.Duration)
    # Field: confidence Type: 2 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::BargeInConfig ===
    # Fields for BargeInConfig
    # Field: no_barge_in_duration Type: 11 (.google.protobuf.Duration)
    # Field: total_duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::InputAudioConfig ===
    # Fields for InputAudioConfig
    # Field: audio_encoding Type: 14 (.google.cloud.dialogflow.cx.v3.AudioEncoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: enable_word_info Type: 8 ()
    # Field: phrase_hints Type: 9 ()
    # Field: model Type: 9 ()
    # Field: model_variant Type: 14 (.google.cloud.dialogflow.cx.v3.SpeechModelVariant)
    # Field: single_utterance Type: 8 ()
    # Field: barge_in_config Type: 11 (.google.cloud.dialogflow.cx.v3.BargeInConfig)
    # Field: opt_out_conformer_model_migration Type: 8 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::VoiceSelectionParams ===
    # Fields for VoiceSelectionParams
    # Field: name Type: 9 ()
    # Field: ssml_gender Type: 14 (.google.cloud.dialogflow.cx.v3.SsmlVoiceGender)

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SynthesizeSpeechConfig ===
    # Fields for SynthesizeSpeechConfig
    # Field: speaking_rate Type: 1 ()
    # Field: pitch Type: 1 ()
    # Field: volume_gain_db Type: 1 ()
    # Field: effects_profile_id Type: 9 ()
    # Field: voice Type: 11 (.google.cloud.dialogflow.cx.v3.VoiceSelectionParams)

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::OutputAudioConfig ===
    # Fields for OutputAudioConfig
    # Field: audio_encoding Type: 14 (.google.cloud.dialogflow.cx.v3.OutputAudioEncoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: synthesize_speech_config Type: 11 (.google.cloud.dialogflow.cx.v3.SynthesizeSpeechConfig)

# === Message: Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings ===
    # Fields for TextToSpeechSettings
    # Field: synthesize_speech_configs Type: 11 (.google.cloud.dialogflow.cx.v3.TextToSpeechSettings.SynthesizeSpeechConfigsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::AudioConfig - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/audio_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::AudioConfig;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo->new({
        word => $word,
        start_offset => $start_offset,
        end_offset => $end_offset,
        confidence => $confidence,
    });

    # Read or update a field
    my $val = $msg->word();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/audio_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo

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

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::BargeInConfig

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

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::InputAudioConfig

Instructs the speech recognizer on how to process the audio content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_encoding() >> / C<< $msg->audio_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::AudioEncoding>)

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
[SpeechWordInfo][google.cloud.dialogflow.cx.v3.SpeechWordInfo] in
[StreamingRecognitionResult][google.cloud.dialogflow.cx.v3.StreamingRecognitionResult]
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

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SpeechModelVariant>)

Optional. Which variant of the [Speech
model][google.cloud.dialogflow.cx.v3.InputAudioConfig.model] to use.

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

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::AudioConfig::BargeInConfig>)

Configuration of barge-in behavior during the streaming of input audio.

=item * C<< $msg->opt_out_conformer_model_migration() >> / C<< $msg->opt_out_conformer_model_migration($value) >>

Type: C<Bool>

If `true`, the request will opt out for STT conformer model migration.
This field will be deprecated once force migration takes place in June
2024. Please refer to [Dialogflow CX Speech model
migration](https://cloud.google.com/dialogflow/cx/docs/concept/speech-model-migration).

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::VoiceSelectionParams

Description of which voice to use for speech synthesis.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the voice. If not set, the service will choose a
voice based on the other parameters such as language_code and
[ssml_gender][google.cloud.dialogflow.cx.v3.VoiceSelectionParams.ssml_gender].

For the list of available voices, please refer to [Supported voices and
languages](https://cloud.google.com/text-to-speech/docs/voices).

=item * C<< $msg->ssml_gender() >> / C<< $msg->ssml_gender($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SsmlVoiceGender>)

Optional. The preferred gender of the voice. If not set, the service will
choose a voice based on the other parameters such as language_code and
[name][google.cloud.dialogflow.cx.v3.VoiceSelectionParams.name]. Note that
this is only a preference, not requirement. If a voice of the appropriate
gender is not available, the synthesizer substitutes a voice with a
different gender rather than failing the request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SynthesizeSpeechConfig

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

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::AudioConfig::VoiceSelectionParams>)

Optional. The desired voice of the synthesized audio.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::OutputAudioConfig

Instructs the speech synthesizer how to generate the output audio content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_encoding() >> / C<< $msg->audio_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::OutputAudioEncoding>)

Required. Audio encoding of the synthesized audio content.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Optional. The synthesis sample rate (in hertz) for this audio. If not
provided, then the synthesizer will use the default sample rate based on
the audio encoding. If this is different from the voice's natural sample
rate, then the synthesizer will honor this request by converting to the
desired sample rate (which might result in worse audio quality).

=item * C<< $msg->synthesize_speech_config() >> / C<< $msg->synthesize_speech_config($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SynthesizeSpeechConfig>)

Optional. Configuration of how speech should be synthesized.
If not specified,
[Agent.text_to_speech_settings][google.cloud.dialogflow.cx.v3.Agent.text_to_speech_settings]
is applied.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings

Settings related to speech synthesizing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->synthesize_speech_configs() >> / C<< $msg->synthesize_speech_configs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings::SynthesizeSpeechConfigsEntry>)

Configuration of how speech should be synthesized, mapping from language
(https://cloud.google.com/dialogflow/cx/docs/reference/language) to
SynthesizeSpeechConfig.

These settings affect:

 - The [phone
 gateway](https://cloud.google.com/dialogflow/cx/docs/concept/integration/phone-gateway)
   synthesize configuration set via
   [Agent.text_to_speech_settings][google.cloud.dialogflow.cx.v3.Agent.text_to_speech_settings].

 - How speech is synthesized when invoking
 [session][google.cloud.dialogflow.cx.v3.Sessions] APIs.
   [Agent.text_to_speech_settings][google.cloud.dialogflow.cx.v3.Agent.text_to_speech_settings]
   only applies if
   [OutputAudioConfig.synthesize_speech_config][google.cloud.dialogflow.cx.v3.OutputAudioConfig.synthesize_speech_config]
   is not specified.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::AudioConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
