package Google::Cloud::Oracledatabase::V1::GoldengateConnectionType;

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
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZ29sZGVuZ2F0ZV9jb25uZWN0aW9u
X3R5cGUucHJvdG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byL6BwoY
R29sZGVuZ2F0ZUNvbm5lY3Rpb25UeXBlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJ1Cg9j
b25uZWN0aW9uX3R5cGUYAiABKA4yRy5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEu
R29sZGVuZ2F0ZUNvbm5lY3Rpb25UeXBlLkNvbm5lY3Rpb25UeXBlQgPgQQNSDmNvbm5lY3Rp
b25UeXBlEi4KEHRlY2hub2xvZ3lfdHlwZXMYAyADKAlCA+BBA1IPdGVjaG5vbG9neVR5cGVz
IskECg5Db25uZWN0aW9uVHlwZRIfChtDT05ORUNUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABIO
CgpHT0xERU5HQVRFEAESCQoFS0FGS0EQAhIZChVLQUZLQV9TQ0hFTUFfUkVHSVNUUlkQAxIJ
CgVNWVNRTBAEEhgKFEpBVkFfTUVTU0FHRV9TRVJWSUNFEAUSFwoTTUlDUk9TT0ZUX1NRTFNF
UlZFUhAGEhYKEk9DSV9PQkpFQ1RfU1RPUkFHRRAHEgoKBk9SQUNMRRAIEhsKF0FaVVJFX0RB
VEFfTEFLRV9TVE9SQUdFEAkSDgoKUE9TVEdSRVNRTBAKEhsKF0FaVVJFX1NZTkFQU0VfQU5B
TFlUSUNTEAsSDQoJU05PV0ZMQUtFEAwSDQoJQU1BWk9OX1MzEA0SCAoESERGUxAOEhsKF09S
QUNMRV9BSV9EQVRBX1BMQVRGT1JNEA8SEAoMT1JBQ0xFX05PU1FMEBASCwoHTU9OR09EQhAR
EhIKDkFNQVpPTl9LSU5FU0lTEBISEwoPQU1BWk9OX1JFRFNISUZUEBMSBwoDREIyEBQSCQoF
UkVESVMQFRIRCg1FTEFTVElDU0VBUkNIEBYSCwoHR0VORVJJQxAXEhgKFEdPT0dMRV9DTE9V
RF9TVE9SQUdFEBgSEwoPR09PR0xFX0JJR1FVRVJZEBkSDgoKREFUQUJSSUNLUxAaEhEKDUdP
T0dMRV9QVUJTVUIQGxIUChBNSUNST1NPRlRfRkFCUklDEBwSCwoHSUNFQkVSRxAdOtEB6kHN
AQo2b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vR29sZGVuZ2F0ZUNvbm5lY3Rpb25U
eXBlEl5wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZ29sZGVuZ2F0
ZUNvbm5lY3Rpb25UeXBlcy97Z29sZGVuZ2F0ZV9jb25uZWN0aW9uX3R5cGV9Khlnb2xkZW5n
YXRlQ29ubmVjdGlvblR5cGVzMhhnb2xkZW5nYXRlQ29ubmVjdGlvblR5cGUi4QEKJExpc3RH
b2xkZW5nYXRlQ29ubmVjdGlvblR5cGVzUmVxdWVzdBJWCgZwYXJlbnQYASABKAlCPuBBAvpB
OBI2b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vR29sZGVuZ2F0ZUNvbm5lY3Rpb25U
eXBlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2Vf
dG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0
ZXIi8AEKJUxpc3RHb2xkZW5nYXRlQ29ubmVjdGlvblR5cGVzUmVzcG9uc2USeAobZ29sZGVu
Z2F0ZV9jb25uZWN0aW9uX3R5cGVzGAEgAygLMjguZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFi
YXNlLnYxLkdvbGRlbmdhdGVDb25uZWN0aW9uVHlwZVIZZ29sZGVuZ2F0ZUNvbm5lY3Rpb25U
eXBlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SJQoLdW5yZWFj
aGFibGUYAyADKAlCA+BBBlILdW5yZWFjaGFibGVC9wEKImNvbS5nb29nbGUuY2xvdWQub3Jh
Y2xlZGF0YWJhc2UudjFCHUdvbGRlbmdhdGVDb25uZWN0aW9uVHlwZVByb3RvUAFaSmNsb3Vk
Lmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtv
cmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xlLkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29v
Z2xlXENsb3VkXE9yYWNsZURhdGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0
YWJhc2U6OlYxSr8wCgcSBQ4AtwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADsKCQoCCCUSAxUA
OwoICgEIEgMWAGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAD4K
CQoCCAgSAxgAPgoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoI
CgEIEgMbADoKCQoCCC0SAxsAOgpCCgIEABIFHgCRAQEaNSBEZXRhaWxzIG9mIHRoZSBHb2xk
ZW5nYXRlIENvbm5lY3Rpb24gVHlwZSByZXNvdXJjZS4KCgoKAwQAARIDHgggCgsKAwQABxIE
HwIkBAoNCgUEAAedCBIEHwIkBApQCgQEAAQAEgUnAoEBAxpBIFRoZSBjb25uZWN0aW9uIHR5
cGUgb2YgdGhlIEdvbGRlbmdhdGUgQ29ubmVjdGlvbiBUeXBlIHJlc291cmNlLgoKDAoFBAAE
AAESAycHFQorCgYEAAQAAgASAykEJBocIERlZmF1bHQgdW5zcGVjaWZpZWQgdmFsdWUuCgoO
CgcEAAQAAgABEgMpBB8KDgoHBAAEAAIAAhIDKSIjCkMKBgQABAACARIDLAQTGjQgR29sZGVu
Z2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0ZWdvcnkgaXMgR09MREVOR0FURS4KCg4KBwQABAAC
AQESAywEDgoOCgcEAAQAAgECEgMsERIKPgoGBAAEAAICEgMvBA4aLyBHb2xkZW5nYXRlIENv
bm5lY3Rpb24gVHlwZSBjYXRlZ29yeSBpcyBLQUZLQS4KCg4KBwQABAACAgESAy8ECQoOCgcE
AAQAAgICEgMvDA0KTgoGBAAEAAIDEgMyBB4aPyBHb2xkZW5nYXRlIENvbm5lY3Rpb24gVHlw
ZSBjYXRlZ29yeSBpcyBLQUZLQV9TQ0hFTUFfUkVHSVNUUlkuCgoOCgcEAAQAAgMBEgMyBBkK
DgoHBAAEAAIDAhIDMhwdCj4KBgQABAACBBIDNQQOGi8gR29sZGVuZ2F0ZSBDb25uZWN0aW9u
IFR5cGUgY2F0ZWdvcnkgaXMgTVlTUUwuCgoOCgcEAAQAAgQBEgM1BAkKDgoHBAAEAAIEAhID
NQwNCk0KBgQABAACBRIDOAQdGj4gR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0ZWdv
cnkgaXMgSkFWQV9NRVNTQUdFX1NFUlZJQ0UuCgoOCgcEAAQAAgUBEgM4BBgKDgoHBAAEAAIF
AhIDOBscCkwKBgQABAACBhIDOwQcGj0gR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0
ZWdvcnkgaXMgTUlDUk9TT0ZUX1NRTFNFUlZFUi4KCg4KBwQABAACBgESAzsEFwoOCgcEAAQA
AgYCEgM7GhsKSwoGBAAEAAIHEgM+BBsaPCBHb2xkZW5nYXRlIENvbm5lY3Rpb24gVHlwZSBj
YXRlZ29yeSBpcyBPQ0lfT0JKRUNUX1NUT1JBR0UuCgoOCgcEAAQAAgcBEgM+BBYKDgoHBAAE
AAIHAhIDPhkaCj8KBgQABAACCBIDQQQPGjAgR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUg
Y2F0ZWdvcnkgaXMgT1JBQ0xFLgoKDgoHBAAEAAIIARIDQQQKCg4KBwQABAACCAISA0ENDgpQ
CgYEAAQAAgkSA0QEIBpBIEdvbGRlbmdhdGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlz
IEFaVVJFX0RBVEFfTEFLRV9TVE9SQUdFLgoKDgoHBAAEAAIJARIDRAQbCg4KBwQABAACCQIS
A0QeHwpDCgYEAAQAAgoSA0cEFBo0IEdvbGRlbmdhdGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVn
b3J5IGlzIFBPU1RHUkVTUUwuCgoOCgcEAAQAAgoBEgNHBA4KDgoHBAAEAAIKAhIDRxETClAK
BgQABAACCxIDSgQhGkEgR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0ZWdvcnkgaXMg
QVpVUkVfU1lOQVBTRV9BTkFMWVRJQ1MuCgoOCgcEAAQAAgsBEgNKBBsKDgoHBAAEAAILAhID
Sh4gCkIKBgQABAACDBIDTQQTGjMgR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0ZWdv
cnkgaXMgU05PV0ZMQUtFLgoKDgoHBAAEAAIMARIDTQQNCg4KBwQABAACDAISA00QEgpCCgYE
AAQAAg0SA1AEExozIEdvbGRlbmdhdGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlzIEFN
QVpPTl9TMy4KCg4KBwQABAACDQESA1AEDQoOCgcEAAQAAg0CEgNQEBIKPQoGBAAEAAIOEgNT
BA4aLiBHb2xkZW5nYXRlIENvbm5lY3Rpb24gVHlwZSBjYXRlZ29yeSBpcyBIREZTLgoKDgoH
BAAEAAIOARIDUwQICg4KBwQABAACDgISA1MLDQpQCgYEAAQAAg8SA1YEIRpBIEdvbGRlbmdh
dGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlzIE9SQUNMRV9BSV9EQVRBX1BMQVRGT1JN
LgoKDgoHBAAEAAIPARIDVgQbCg4KBwQABAACDwISA1YeIApFCgYEAAQAAhASA1kEFho2IEdv
bGRlbmdhdGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlzIE9SQUNMRV9OT1NRTC4KCg4K
BwQABAACEAESA1kEEAoOCgcEAAQAAhACEgNZExUKQAoGBAAEAAIREgNcBBEaMSBHb2xkZW5n
YXRlIENvbm5lY3Rpb24gVHlwZSBjYXRlZ29yeSBpcyBNT05HT0RCLgoKDgoHBAAEAAIRARID
XAQLCg4KBwQABAACEQISA1wOEApHCgYEAAQAAhISA18EGBo4IEdvbGRlbmdhdGUgQ29ubmVj
dGlvbiBUeXBlIGNhdGVnb3J5IGlzIEFNQVpPTl9LSU5FU0lTLgoKDgoHBAAEAAISARIDXwQS
Cg4KBwQABAACEgISA18VFwpICgYEAAQAAhMSA2IEGRo5IEdvbGRlbmdhdGUgQ29ubmVjdGlv
biBUeXBlIGNhdGVnb3J5IGlzIEFNQVpPTl9SRURTSElGVC4KCg4KBwQABAACEwESA2IEEwoO
CgcEAAQAAhMCEgNiFhgKPAoGBAAEAAIUEgNlBA0aLSBHb2xkZW5nYXRlIENvbm5lY3Rpb24g
VHlwZSBjYXRlZ29yeSBpcyBEQjIuCgoOCgcEAAQAAhQBEgNlBAcKDgoHBAAEAAIUAhIDZQoM
Cj4KBgQABAACFRIDaAQPGi8gR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0ZWdvcnkg
aXMgUkVESVMuCgoOCgcEAAQAAhUBEgNoBAkKDgoHBAAEAAIVAhIDaAwOCkYKBgQABAACFhID
awQXGjcgR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgY2F0ZWdvcnkgaXMgRUxBU1RJQ1NF
QVJDSC4KCg4KBwQABAACFgESA2sEEQoOCgcEAAQAAhYCEgNrFBYKQAoGBAAEAAIXEgNuBBEa
MSBHb2xkZW5nYXRlIENvbm5lY3Rpb24gVHlwZSBjYXRlZ29yeSBpcyBHRU5FUklDLgoKDgoH
BAAEAAIXARIDbgQLCg4KBwQABAACFwISA24OEApNCgYEAAQAAhgSA3EEHho+IEdvbGRlbmdh
dGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlzIEdPT0dMRV9DTE9VRF9TVE9SQUdFLgoK
DgoHBAAEAAIYARIDcQQYCg4KBwQABAACGAISA3EbHQpICgYEAAQAAhkSA3QEGRo5IEdvbGRl
bmdhdGUgQ29ubmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlzIEdPT0dMRV9CSUdRVUVSWS4KCg4K
BwQABAACGQESA3QEEwoOCgcEAAQAAhkCEgN0FhgKQwoGBAAEAAIaEgN3BBQaNCBHb2xkZW5n
YXRlIENvbm5lY3Rpb24gVHlwZSBjYXRlZ29yeSBpcyBEQVRBQlJJQ0tTLgoKDgoHBAAEAAIa
ARIDdwQOCg4KBwQABAACGgISA3cREwpGCgYEAAQAAhsSA3oEFxo3IEdvbGRlbmdhdGUgQ29u
bmVjdGlvbiBUeXBlIGNhdGVnb3J5IGlzIEdPT0dMRV9QVUJTVUIuCgoOCgcEAAQAAhsBEgN6
BBEKDgoHBAAEAAIbAhIDehQWCkkKBgQABAACHBIDfQQaGjogR29sZGVuZ2F0ZSBDb25uZWN0
aW9uIFR5cGUgY2F0ZWdvcnkgaXMgTUlDUk9TT0ZUX0ZBQlJJQy4KCg4KBwQABAACHAESA30E
FAoOCgcEAAQAAhwCEgN9FxkKQQoGBAAEAAIdEgSAAQQRGjEgR29sZGVuZ2F0ZSBDb25uZWN0
aW9uIFR5cGUgY2F0ZWdvcnkgaXMgSUNFQkVSRy4KCg8KBwQABAACHQESBIABBAsKDwoHBAAE
AAIdAhIEgAEOEArAAQoEBAACABIEhgECPRqxASBJZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0
aGUgR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUgcmVzb3VyY2Ugd2l0aCB0aGUKIGZvcm1h
dDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve3JlZ2lvbn0vZ29sZGVuZ2F0ZUNv
bm5lY3Rpb25UeXBlcy97Z29sZGVuZ2F0ZV9jb25uZWN0aW9uX3R5cGV9CgoNCgUEAAIABRIE
hgECCAoNCgUEAAIAARIEhgEJDQoNCgUEAAIAAxIEhgEQEQoNCgUEAAIACBIEhgESPAoQCggE
AAIACJwIABIEhgETOwpfCgQEAAIBEgaKAQKLATIaTyBPdXRwdXQgb25seS4gVGhlIGNvbm5l
Y3Rpb24gdHlwZSBvZiB0aGUgR29sZGVuZ2F0ZSBDb25uZWN0aW9uIFR5cGUKIHJlc291cmNl
LgoKDQoFBAACAQYSBIoBAhAKDQoFBAACAQESBIoBESAKDQoFBAACAQMSBIoBIyQKDQoFBAAC
AQgSBIsBBjEKEAoIBAACAQicCAASBIsBBzAKXwoEBAACAhIGjwECkAEyGk8gT3V0cHV0IG9u
bHkuIFRoZSB0ZWNobm9sb2d5IHR5cGUgb2YgdGhlIEdvbGRlbmdhdGUgQ29ubmVjdGlvbiBU
eXBlCiByZXNvdXJjZS4KCg0KBQQAAgIEEgSPAQIKCg0KBQQAAgIFEgSPAQsRCg0KBQQAAgIB
EgSPARIiCg0KBQQAAgIDEgSPASUmCg0KBQQAAgIIEgSQAQYxChAKCAQAAgIInAgAEgSQAQcw
Cj4KAgQBEgaUAQCpAQEaMCBNZXNzYWdlIGZvciBsaXN0aW5nIEdvbGRlbmdhdGVDb25uZWN0
aW9uVHlwZXMuCgoLCgMEAQESBJQBCCwKggEKBAQBAgASBpcBApwBBBpyIFJlcXVpcmVkLiBQ
YXJlbnQgdmFsdWUgZm9yIExpc3RHb2xkZW5nYXRlQ29ubmVjdGlvblR5cGVzUmVxdWVzdAog
Rm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCg0KBQQB
AgAFEgSXAQIICg0KBQQBAgABEgSXAQkPCg0KBQQBAgADEgSXARITCg8KBQQBAgAIEgaXARSc
AQMKEAoIBAECAAicCAASBJgBBCoKEQoHBAECAAifCBIGmQEEmwEFCpcBCgQEAQIBEgSgAQI/
GogBIE9wdGlvbmFsLiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJldHVybiBm
ZXdlciBpdGVtcyB0aGFuCiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2ls
bCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAQIBBRIEoAECBwoNCgUEAQIB
ARIEoAEIEQoNCgUEAQIBAxIEoAEUFQoNCgUEAQIBCBIEoAEWPgoQCggEAQIBCJwIABIEoAEX
PQpZCgQEAQICEgSjAQJBGksgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdl
IG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDQoFBAECAgUSBKMBAggK
DQoFBAECAgESBKMBCRMKDQoFBAECAgMSBKMBFhcKDQoFBAECAggSBKMBGEAKEAoIBAECAgic
CAASBKMBGT8KqwEKBAQBAgMSBKgBAj0anAEgT3B0aW9uYWwuIEFuIGV4cHJlc3Npb24gZm9y
IGZpbHRlcmluZyB0aGUgcmVzdWx0cyBvZiB0aGUgcmVxdWVzdC4gVGhlCiBjb25uZWN0aW9u
X3R5cGUgZmllbGQgbXVzdCBiZSBzcGVjaWZpZWQgaW4gdGhlIGZvcm1hdDoKIGBjb25uZWN0
aW9uX3R5cGU9Ik9SQUNMRSJgLgoKDQoFBAECAwUSBKgBAggKDQoFBAECAwESBKgBCQ8KDQoF
BAECAwMSBKgBEhMKDQoFBAECAwgSBKgBFDwKEAoIBAECAwicCAASBKgBFTsKSQoCBAISBqwB
ALcBARo7IE1lc3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGxpc3RpbmcgR29sZGVuZ2F0ZUNvbm5l
Y3Rpb25UeXBlcwoKCwoDBAIBEgSsAQgtCjQKBAQCAgASBK4BAkQaJiBUaGUgbGlzdCBvZiBH
b2xkZW5nYXRlQ29ubmVjdGlvblR5cGUKCg0KBQQCAgAEEgSuAQIKCg0KBQQCAgAGEgSuAQsj
Cg0KBQQCAgABEgSuASQ/Cg0KBQQCAgADEgSuAUJDCpABCgQEAgIBEgSyAQIdGoEBIEEgdG9r
ZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vi
c2VxdWVudCBwYWdlcy4KCg0KBQQCAgEFEgSyAQIICg0KBQQCAgEBEgSyAQkYCg0KBQQCAgED
EgSyARscCkYKBAQCAgISBrUBArYBNRo2IFVub3JkZXJlZCBsaXN0LiBMb2NhdGlvbnMgdGhh
dCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQCAgIEEgS1AQIKCg0KBQQCAgIFEgS1AQsR
Cg0KBQQCAgIBEgS1ARIdCg0KBQQCAgIDEgS1ASAhCg0KBQQCAgIIEgS2AQY0ChAKCAQCAgII
nAgAEgS2AQczYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType ===
    # Fields for GoldengateConnectionType
    # Field: name Type: 9 ()
    # Field: connection_type Type: 14 (.google.cloud.oracledatabase.v1.GoldengateConnectionType.ConnectionType)
    # Field: technology_types Type: 9 ()

# Enum: GoldengateConnectionType::ConnectionType
our $GoldengateConnectionType_CONNECTION_TYPE_UNSPECIFIED = 0;
our $GoldengateConnectionType_GOLDENGATE = 1;
our $GoldengateConnectionType_KAFKA = 2;
our $GoldengateConnectionType_KAFKA_SCHEMA_REGISTRY = 3;
our $GoldengateConnectionType_MYSQL = 4;
our $GoldengateConnectionType_JAVA_MESSAGE_SERVICE = 5;
our $GoldengateConnectionType_MICROSOFT_SQLSERVER = 6;
our $GoldengateConnectionType_OCI_OBJECT_STORAGE = 7;
our $GoldengateConnectionType_ORACLE = 8;
our $GoldengateConnectionType_AZURE_DATA_LAKE_STORAGE = 9;
our $GoldengateConnectionType_POSTGRESQL = 10;
our $GoldengateConnectionType_AZURE_SYNAPSE_ANALYTICS = 11;
our $GoldengateConnectionType_SNOWFLAKE = 12;
our $GoldengateConnectionType_AMAZON_S3 = 13;
our $GoldengateConnectionType_HDFS = 14;
our $GoldengateConnectionType_ORACLE_AI_DATA_PLATFORM = 15;
our $GoldengateConnectionType_ORACLE_NOSQL = 16;
our $GoldengateConnectionType_MONGODB = 17;
our $GoldengateConnectionType_AMAZON_KINESIS = 18;
our $GoldengateConnectionType_AMAZON_REDSHIFT = 19;
our $GoldengateConnectionType_DB2 = 20;
our $GoldengateConnectionType_REDIS = 21;
our $GoldengateConnectionType_ELASTICSEARCH = 22;
our $GoldengateConnectionType_GENERIC = 23;
our $GoldengateConnectionType_GOOGLE_CLOUD_STORAGE = 24;
our $GoldengateConnectionType_GOOGLE_BIGQUERY = 25;
our $GoldengateConnectionType_DATABRICKS = 26;
our $GoldengateConnectionType_GOOGLE_PUBSUB = 27;
our $GoldengateConnectionType_MICROSOFT_FABRIC = 28;
our $GoldengateConnectionType_ICEBERG = 29;

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesRequest ===
    # Fields for ListGoldengateConnectionTypesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesResponse ===
    # Fields for ListGoldengateConnectionTypesResponse
    # Field: goldengate_connection_types Type: 11 (.google.cloud.oracledatabase.v1.GoldengateConnectionType)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateConnectionType - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/goldengate_connection_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::GoldengateConnectionType;

    my $msg = Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType->new({
        name => $name,
        connection_type => $connection_type,
        technology_types => $technology_types,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/goldengate_connection_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType

Details of the Goldengate Connection Type resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Goldengate Connection Type resource with the
format:
projects/{project}/locations/{region}/goldengateConnectionTypes/{goldengate_connection_type}

=item * C<< $msg->connection_type() >> / C<< $msg->connection_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ConnectionType>)

Output only. The connection type of the Goldengate Connection Type
resource.

=item * C<< $msg->technology_types() >> / C<< $msg->technology_types($value) >>

Type: C<String>

Output only. The technology type of the Goldengate Connection Type
resource.

=back

=head3 Enum: GoldengateConnectionType::ConnectionType

=over 4

=item * C<CONNECTION_TYPE_UNSPECIFIED> => C<0>

=item * C<GOLDENGATE> => C<1>

=item * C<KAFKA> => C<2>

=item * C<KAFKA_SCHEMA_REGISTRY> => C<3>

=item * C<MYSQL> => C<4>

=item * C<JAVA_MESSAGE_SERVICE> => C<5>

=item * C<MICROSOFT_SQLSERVER> => C<6>

=item * C<OCI_OBJECT_STORAGE> => C<7>

=item * C<ORACLE> => C<8>

=item * C<AZURE_DATA_LAKE_STORAGE> => C<9>

=item * C<POSTGRESQL> => C<10>

=item * C<AZURE_SYNAPSE_ANALYTICS> => C<11>

=item * C<SNOWFLAKE> => C<12>

=item * C<AMAZON_S3> => C<13>

=item * C<HDFS> => C<14>

=item * C<ORACLE_AI_DATA_PLATFORM> => C<15>

=item * C<ORACLE_NOSQL> => C<16>

=item * C<MONGODB> => C<17>

=item * C<AMAZON_KINESIS> => C<18>

=item * C<AMAZON_REDSHIFT> => C<19>

=item * C<DB2> => C<20>

=item * C<REDIS> => C<21>

=item * C<ELASTICSEARCH> => C<22>

=item * C<GENERIC> => C<23>

=item * C<GOOGLE_CLOUD_STORAGE> => C<24>

=item * C<GOOGLE_BIGQUERY> => C<25>

=item * C<DATABRICKS> => C<26>

=item * C<GOOGLE_PUBSUB> => C<27>

=item * C<MICROSOFT_FABRIC> => C<28>

=item * C<ICEBERG> => C<29>

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesRequest

Message for listing GoldengateConnectionTypes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListGoldengateConnectionTypesRequest
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. The
connection_type field must be specified in the format:
`connection_type="ORACLE"`.

=back

=head2 Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::ListGoldengateConnectionTypesResponse

Message for response to listing GoldengateConnectionTypes

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->goldengate_connection_types() >> / C<< $msg->goldengate_connection_types($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::GoldengateConnectionType>)

The list of GoldengateConnectionType

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::GoldengateConnectionType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
