package Google::Iam::V2::Policy;

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
    eval { require Google::Iam::V2::Deny };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Chpnb29nbGUvaWFtL3YyL3BvbGljeS5wcm90bxINZ29vZ2xlLmlhbS52MhocZ29vZ2xlL2Fw
aS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGGdvb2dsZS9pYW0vdjIvZGVueS5wcm90bxojZ29v
Z2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8ivQQKBlBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQVSBG5hbWUSFQoDdWlk
GAIgASgJQgPgQQVSA3VpZBIXCgRraW5kGAMgASgJQgPgQQNSBGtpbmQSIQoMZGlzcGxheV9u
YW1lGAQgASgJUgtkaXNwbGF5TmFtZRJICgthbm5vdGF0aW9ucxgFIAMoCzImLmdvb2dsZS5p
YW0udjIuUG9saWN5LkFubm90YXRpb25zRW50cnlSC2Fubm90YXRpb25zEhIKBGV0YWcYBiAB
KAlSBGV0YWcSQAoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSQAoLZGVsZXRlX3RpbWUYCSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmRlbGV0ZVRpbWUSLwoFcnVsZXMY
CiADKAsyGS5nb29nbGUuaWFtLnYyLlBvbGljeVJ1bGVSBXJ1bGVzEjIKEm1hbmFnaW5nX2F1
dGhvcml0eRgLIAEoCUID4EEFUhFtYW5hZ2luZ0F1dGhvcml0eRo+ChBBbm5vdGF0aW9uc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEibgoKUG9s
aWN5UnVsZRI2CglkZW55X3J1bGUYAiABKAsyFy5nb29nbGUuaWFtLnYyLkRlbnlSdWxlSABS
CGRlbnlSdWxlEiAKC2Rlc2NyaXB0aW9uGAEgASgJUgtkZXNjcmlwdGlvbkIGCgRraW5kIm4K
E0xpc3RQb2xpY2llc1JlcXVlc3QSGwoGcGFyZW50GAEgASgJQgPgQQJSBnBhcmVudBIbCglw
YWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tl
biJxChRMaXN0UG9saWNpZXNSZXNwb25zZRIxCghwb2xpY2llcxgBIAMoCzIVLmdvb2dsZS5p
YW0udjIuUG9saWN5Ughwb2xpY2llcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4iKwoQR2V0UG9saWN5UmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUi
gwEKE0NyZWF0ZVBvbGljeVJlcXVlc3QSGwoGcGFyZW50GAEgASgJQgPgQQJSBnBhcmVudBIy
CgZwb2xpY3kYAiABKAsyFS5nb29nbGUuaWFtLnYyLlBvbGljeUID4EECUgZwb2xpY3kSGwoJ
cG9saWN5X2lkGAMgASgJUghwb2xpY3lJZCJJChNVcGRhdGVQb2xpY3lSZXF1ZXN0EjIKBnBv
bGljeRgBIAEoCzIVLmdvb2dsZS5pYW0udjIuUG9saWN5QgPgQQJSBnBvbGljeSJHChNEZWxl
dGVQb2xpY3lSZXF1ZXN0EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIXCgRldGFnGAIgASgJ
QgPgQQFSBGV0YWciVgoXUG9saWN5T3BlcmF0aW9uTWV0YWRhdGESOwoLY3JlYXRlX3RpbWUY
ASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lMtAGCghQb2xp
Y2llcxKDAQoMTGlzdFBvbGljaWVzEiIuZ29vZ2xlLmlhbS52Mi5MaXN0UG9saWNpZXNSZXF1
ZXN0GiMuZ29vZ2xlLmlhbS52Mi5MaXN0UG9saWNpZXNSZXNwb25zZSIqgtPkkwIbEhkvdjIv
e3BhcmVudD1wb2xpY2llcy8qLyp92kEGcGFyZW50Em0KCUdldFBvbGljeRIfLmdvb2dsZS5p
YW0udjIuR2V0UG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjIuUG9saWN5IiiC0+STAhsS
GS92Mi97bmFtZT1wb2xpY2llcy8qLyovKn3aQQRuYW1lEroBCgxDcmVhdGVQb2xpY3kSIi5n
b29nbGUuaWFtLnYyLkNyZWF0ZVBvbGljeVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcu
T3BlcmF0aW9uImeC0+STAiMiGS92Mi97cGFyZW50PXBvbGljaWVzLyovKn06BnBvbGljedpB
F3BhcmVudCxwb2xpY3kscG9saWN5X2lkykEhCgZQb2xpY3kSF1BvbGljeU9wZXJhdGlvbk1l
dGFkYXRhEqcBCgxVcGRhdGVQb2xpY3kSIi5nb29nbGUuaWFtLnYyLlVwZGF0ZVBvbGljeVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIlSC0+STAioaIC92Mi97cG9s
aWN5Lm5hbWU9cG9saWNpZXMvKi8qLyp9OgZwb2xpY3nKQSEKBlBvbGljeRIXUG9saWN5T3Bl
cmF0aW9uTWV0YWRhdGESnwEKDERlbGV0ZVBvbGljeRIiLmdvb2dsZS5pYW0udjIuRGVsZXRl
UG9saWN5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iTILT5JMCGyoZ
L3YyL3tuYW1lPXBvbGljaWVzLyovKi8qfdpBBG5hbWXKQSEKBlBvbGljeRIXUG9saWN5T3Bl
cmF0aW9uTWV0YWRhdGEaRspBEmlhbS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CeQoRY29tLmdvb2dsZS5pYW0udjJC
C1BvbGljeVByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vaWFtL2FwaXYyL2lhbXBiO2lh
bXBiqgITR29vZ2xlLkNsb3VkLklhbS5WMsoCE0dvb2dsZVxDbG91ZFxJYW1cVjJK+08KBxIF
DgCeAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABYKCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIgoJCgIDBBIDFgAtCgkK
AgMFEgMXACkKCAoBCBIDGQAwCgkKAgglEgMZADAKCAoBCBIDGgBACgkKAggLEgMaAEAKCAoB
CBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAsCgkKAggIEgMcACwKCAoBCBIDHQAqCgkKAggB
EgMdACoKCAoBCBIDHgAwCgkKAggpEgMeADAKVgoCBgASBCEAZwEaSiBBbiBpbnRlcmZhY2Ug
Zm9yIG1hbmFnaW5nIElkZW50aXR5IGFuZCBBY2Nlc3MgTWFuYWdlbWVudCAoSUFNKSBwb2xp
Y2llcy4KCgoKAwYAARIDIQgQCgoKAwYAAxIDIgI6CgwKBQYAA5kIEgMiAjoKCgoDBgADEgMj
AlYKDAoFBgADmggSAyMCVgq0AQoEBgACABIEKgIvAxqlASBSZXRyaWV2ZXMgdGhlIHBvbGlj
aWVzIG9mIHRoZSBzcGVjaWZpZWQga2luZCB0aGF0IGFyZSBhdHRhY2hlZCB0byBhCiByZXNv
dXJjZS4KCiBUaGUgcmVzcG9uc2UgbGlzdHMgb25seSBwb2xpY3kgbWV0YWRhdGEuIEluIHBh
cnRpY3VsYXIsIHBvbGljeSBydWxlcyBhcmUKIG9taXR0ZWQuCgoMCgUGAAIAARIDKgYSCgwK
BQYAAgACEgMqEyYKDAoFBgACAAMSAyoxRQoNCgUGAAIABBIEKwQtBgoRCgkGAAIABLDKvCIS
BCsELQYKDAoFBgACAAQSAy4ENAoPCggGAAIABJsIABIDLgQ0Ch4KBAYAAgESBDICNwMaECBH
ZXRzIGEgcG9saWN5LgoKDAoFBgACAQESAzIGDwoMCgUGAAIBAhIDMhAgCgwKBQYAAgEDEgMy
KzEKDQoFBgACAQQSBDMENQYKEQoJBgACAQSwyrwiEgQzBDUGCgwKBQYAAgEEEgM2BDIKDwoI
BgACAQSbCAASAzYEMgohCgQGAAICEgQ6AkQDGhMgQ3JlYXRlcyBhIHBvbGljeS4KCgwKBQYA
AgIBEgM6BhIKDAoFBgACAgISAzoTJgoMCgUGAAICAxIDOjFNCg0KBQYAAgIEEgQ7BD4GChEK
CQYAAgIEsMq8IhIEOwQ+BgoMCgUGAAICBBIDPwRFCg8KCAYAAgIEmwgAEgM/BEUKDQoFBgAC
AgQSBEAEQwYKDwoHBgACAgSZCBIEQARDBgqsAwoEBgACAxIEUQJaAxqdAyBVcGRhdGVzIHRo
ZSBzcGVjaWZpZWQgcG9saWN5LgoKIFlvdSBjYW4gdXBkYXRlIG9ubHkgdGhlIHJ1bGVzIGFu
ZCB0aGUgZGlzcGxheSBuYW1lIGZvciB0aGUgcG9saWN5LgoKIFRvIHVwZGF0ZSBhIHBvbGlj
eSwgeW91IHNob3VsZCB1c2UgYSByZWFkLW1vZGlmeS13cml0ZSBsb29wOgoKIDEuIFVzZSBb
R2V0UG9saWN5XVtnb29nbGUuaWFtLnYyLlBvbGljaWVzLkdldFBvbGljeV0gdG8gcmVhZCB0
aGUgY3VycmVudCB2ZXJzaW9uIG9mIHRoZSBwb2xpY3kuCiAyLiBNb2RpZnkgdGhlIHBvbGlj
eSBhcyBuZWVkZWQuCiAzLiBVc2UgYFVwZGF0ZVBvbGljeWAgdG8gd3JpdGUgdGhlIHVwZGF0
ZWQgcG9saWN5LgoKIFRoaXMgcGF0dGVybiBoZWxwcyBwcmV2ZW50IGNvbmZsaWN0cyBiZXR3
ZWVuIGNvbmN1cnJlbnQgdXBkYXRlcy4KCgwKBQYAAgMBEgNRBhIKDAoFBgACAwISA1ETJgoM
CgUGAAIDAxIDUTFNCg0KBQYAAgMEEgRSBFUGChEKCQYAAgMEsMq8IhIEUgRVBgoNCgUGAAID
BBIEVgRZBgoPCgcGAAIDBJkIEgRWBFkGCjsKBAYAAgQSBF0CZgMaLSBEZWxldGVzIGEgcG9s
aWN5LiBUaGlzIGFjdGlvbiBpcyBwZXJtYW5lbnQuCgoMCgUGAAIEARIDXQYSCgwKBQYAAgQC
EgNdEyYKDAoFBgACBAMSA10xTQoNCgUGAAIEBBIEXgRgBgoRCgkGAAIEBLDKvCISBF4EYAYK
DAoFBgACBAQSA2EEMgoPCggGAAIEBJsIABIDYQQyCg0KBQYAAgQEEgRiBGUGCg8KBwYAAgQE
mQgSBGIEZQYKJgoCBAASBWoAoAEBGhkgRGF0YSBmb3IgYW4gSUFNIHBvbGljeS4KCgoKAwQA
ARIDaggOCt4ECgQEAAIAEgN3Ajwa0AQgSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgYFBvbGljeWAsIHdoaWNoIG11c3QgYmUgdW5pcXVlLiBGb3JtYXQ6CiBgcG9saWNp
ZXMve2F0dGFjaG1lbnRfcG9pbnR9L2Rlbnlwb2xpY2llcy97cG9saWN5X2lkfWAKCgogVGhl
IGF0dGFjaG1lbnQgcG9pbnQgaXMgaWRlbnRpZmllZCBieSBpdHMgVVJMLWVuY29kZWQgZnVs
bCByZXNvdXJjZSBuYW1lLAogd2hpY2ggbWVhbnMgdGhhdCB0aGUgZm9yd2FyZC1zbGFzaCBj
aGFyYWN0ZXIsIGAvYCwgbXVzdCBiZSB3cml0dGVuIGFzCiBgJTJGYC4gRm9yIGV4YW1wbGUs
CiBgcG9saWNpZXMvY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20lMkZwcm9q
ZWN0cyUyRm15LXByb2plY3QvZGVueXBvbGljaWVzL215LWRlbnktcG9saWN5YC4KCiBGb3Ig
b3JnYW5pemF0aW9ucyBhbmQgZm9sZGVycywgdXNlIHRoZSBudW1lcmljIElEIGluIHRoZSBm
dWxsIHJlc291cmNlCiBuYW1lLiBGb3IgcHJvamVjdHMsIHJlcXVlc3RzIGNhbiB1c2UgdGhl
IGFscGhhbnVtZXJpYyBvciB0aGUgbnVtZXJpYyBJRC4KIFJlc3BvbnNlcyBhbHdheXMgY29u
dGFpbiB0aGUgbnVtZXJpYyBJRC4KCgwKBQQAAgAFEgN3AggKDAoFBAACAAESA3cJDQoMCgUE
AAIAAxIDdxARCgwKBQQAAgAIEgN3EjsKDwoIBAACAAicCAASA3cTOgp3CgQEAAIBEgN7Ajsa
aiBJbW11dGFibGUuIFRoZSBnbG9iYWxseSB1bmlxdWUgSUQgb2YgdGhlIGBQb2xpY3lgLiBB
c3NpZ25lZCBhdXRvbWF0aWNhbGx5IHdoZW4gdGhlCiBgUG9saWN5YCBpcyBjcmVhdGVkLgoK
DAoFBAACAQUSA3sCCAoMCgUEAAIBARIDewkMCgwKBQQAAgEDEgN7DxAKDAoFBAACAQgSA3sR
OgoPCggEAAIBCJwIABIDexI5Cl0KBAQAAgISA34CPhpQIE91dHB1dCBvbmx5LiBUaGUga2lu
ZCBvZiB0aGUgYFBvbGljeWAuIEFsd2F5cyBjb250YWlucyB0aGUgdmFsdWUgYERlbnlQb2xp
Y3lgLgoKDAoFBAACAgUSA34CCAoMCgUEAAICARIDfgkNCgwKBQQAAgIDEgN+EBEKDAoFBAAC
AggSA34SPQoPCggEAAICCJwIABIDfhM8CmUKBAQAAgMSBIIBAhoaVyBBIHVzZXItc3BlY2lm
aWVkIGRlc2NyaXB0aW9uIG9mIHRoZSBgUG9saWN5YC4gVGhpcyB2YWx1ZSBjYW4gYmUgdXAg
dG8gNjMKIGNoYXJhY3RlcnMuCgoNCgUEAAIDBRIEggECCAoNCgUEAAIDARIEggEJFQoNCgUE
AAIDAxIEggEYGQqUAQoEBAACBBIEhgECJhqFASBBIGtleS12YWx1ZSBtYXAgdG8gc3RvcmUg
YXJiaXRyYXJ5IG1ldGFkYXRhIGZvciB0aGUgYFBvbGljeWAuIEtleXMKIGNhbiBiZSB1cCB0
byA2MyBjaGFyYWN0ZXJzLiBWYWx1ZXMgY2FuIGJlIHVwIHRvIDI1NSBjaGFyYWN0ZXJzLgoK
DQoFBAACBAYSBIYBAhUKDQoFBAACBAESBIYBFiEKDQoFBAACBAMSBIYBJCUKmwIKBAQAAgUS
BI4BAhIajAIgQW4gb3BhcXVlIHRhZyB0aGF0IGlkZW50aWZpZXMgdGhlIGN1cnJlbnQgdmVy
c2lvbiBvZiB0aGUgYFBvbGljeWAuIElBTSB1c2VzCiB0aGlzIHZhbHVlIHRvIGhlbHAgbWFu
YWdlIGNvbmN1cnJlbnQgdXBkYXRlcywgc28gdGhleSBkbyBub3QgY2F1c2Ugb25lCiB1cGRh
dGUgdG8gYmUgb3ZlcndyaXR0ZW4gYnkgYW5vdGhlci4KCiBJZiB0aGlzIGZpZWxkIGlzIHBy
ZXNlbnQgaW4gYSBbQ3JlYXRlUG9saWN5XVtdIHJlcXVlc3QsIHRoZSB2YWx1ZSBpcwogaWdu
b3JlZC4KCg0KBQQAAgUFEgSOAQIICg0KBQQAAgUBEgSOAQkNCg0KBQQAAgUDEgSOARARCkQK
BAQAAgYSBJEBAlgaNiBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgYFBvbGljeWAg
d2FzIGNyZWF0ZWQuCgoNCgUEAAIGBhIEkQECGwoNCgUEAAIGARIEkQEcJwoNCgUEAAIGAxIE
kQEqKwoNCgUEAAIGCBIEkQEsVwoQCggEAAIGCJwIABIEkQEtVgpJCgQEAAIHEgSUAQJYGjsg
T3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIGBQb2xpY3lgIHdhcyBsYXN0IHVwZGF0
ZWQuCgoNCgUEAAIHBhIElAECGwoNCgUEAAIHARIElAEcJwoNCgUEAAIHAxIElAEqKwoNCgUE
AAIHCBIElAEsVwoQCggEAAIHCJwIABIElAEtVgpoCgQEAAIIEgSXAQJYGlogT3V0cHV0IG9u
bHkuIFRoZSB0aW1lIHdoZW4gdGhlIGBQb2xpY3lgIHdhcyBkZWxldGVkLiBFbXB0eSBpZiB0
aGUgcG9saWN5IGlzIG5vdCBkZWxldGVkLgoKDQoFBAACCAYSBJcBAhsKDQoFBAACCAESBJcB
HCcKDQoFBAACCAMSBJcBKisKDQoFBAACCAgSBJcBLFcKEAoIBAACCAicCAASBJcBLVYKkAEK
BAQAAgkSBJsBAiEagQEgQSBsaXN0IG9mIHJ1bGVzIHRoYXQgc3BlY2lmeSB0aGUgYmVoYXZp
b3Igb2YgdGhlIGBQb2xpY3lgLiBBbGwgb2YgdGhlIHJ1bGVzCiBzaG91bGQgYmUgb2YgdGhl
IGBraW5kYCBzcGVjaWZpZWQgaW4gdGhlIGBQb2xpY3lgLgoKDQoFBAACCQQSBJsBAgoKDQoF
BAACCQYSBJsBCxUKDQoFBAACCQESBJsBFhsKDQoFBAACCQMSBJsBHiAKkwEKBAQAAgoSBJ8B
AksahAEgSW1tdXRhYmxlLiBTcGVjaWZpZXMgdGhhdCB0aGlzIHBvbGljeSBpcyBtYW5hZ2Vk
IGJ5IGFuIGF1dGhvcml0eSBhbmQgY2FuIG9ubHkgYmUKIG1vZGlmaWVkIGJ5IHRoYXQgYXV0
aG9yaXR5LiBVc2FnZSBpcyByZXN0cmljdGVkLgoKDQoFBAACCgUSBJ8BAggKDQoFBAACCgES
BJ8BCRsKDQoFBAACCgMSBJ8BHiAKDQoFBAACCggSBJ8BIUoKEAoIBAACCgicCAASBJ8BIkkK
LAoCBAESBqMBAKwBARoeIEEgc2luZ2xlIHJ1bGUgaW4gYSBgUG9saWN5YC4KCgsKAwQBARIE
owEIEgoOCgQEAQgAEgakAQKnAQMKDQoFBAEIAAESBKQBCAwKKQoEBAECABIEpgEEGxobIEEg
cnVsZSBmb3IgYSBkZW55IHBvbGljeS4KCg0KBQQBAgAGEgSmAQQMCg0KBQQBAgABEgSmAQ0W
Cg0KBQQBAgADEgSmARkaCmIKBAQBAgESBKsBAhkaVCBBIHVzZXItc3BlY2lmaWVkIGRlc2Ny
aXB0aW9uIG9mIHRoZSBydWxlLiBUaGlzIHZhbHVlIGNhbiBiZSB1cCB0byAyNTYKIGNoYXJh
Y3RlcnMuCgoNCgUEAQIBBRIEqwECCAoNCgUEAQIBARIEqwEJFAoNCgUEAQIBAxIEqwEXGAoz
CgIEAhIGrwEAxQEBGiUgUmVxdWVzdCBtZXNzYWdlIGZvciBgTGlzdFBvbGljaWVzYC4KCgsK
AwQCARIErwEIGwqwBAoEBAICABIEvAECPRqhBCBSZXF1aXJlZC4gVGhlIHJlc291cmNlIHRo
YXQgdGhlIHBvbGljeSBpcyBhdHRhY2hlZCB0bywgYWxvbmcgd2l0aCB0aGUga2luZCBvZiBw
b2xpY3kKIHRvIGxpc3QuIEZvcm1hdDoKIGBwb2xpY2llcy97YXR0YWNobWVudF9wb2ludH0v
ZGVueXBvbGljaWVzYAoKCiBUaGUgYXR0YWNobWVudCBwb2ludCBpcyBpZGVudGlmaWVkIGJ5
IGl0cyBVUkwtZW5jb2RlZCBmdWxsIHJlc291cmNlIG5hbWUsCiB3aGljaCBtZWFucyB0aGF0
IHRoZSBmb3J3YXJkLXNsYXNoIGNoYXJhY3RlciwgYC9gLCBtdXN0IGJlIHdyaXR0ZW4gYXMK
IGAlMkZgLiBGb3IgZXhhbXBsZSwKIGBwb2xpY2llcy9jbG91ZHJlc291cmNlbWFuYWdlci5n
b29nbGVhcGlzLmNvbSUyRnByb2plY3RzJTJGbXktcHJvamVjdC9kZW55cG9saWNpZXNgLgoK
IEZvciBvcmdhbml6YXRpb25zIGFuZCBmb2xkZXJzLCB1c2UgdGhlIG51bWVyaWMgSUQgaW4g
dGhlIGZ1bGwgcmVzb3VyY2UKIG5hbWUuIEZvciBwcm9qZWN0cywgeW91IGNhbiB1c2UgdGhl
IGFscGhhbnVtZXJpYyBvciB0aGUgbnVtZXJpYyBJRC4KCg0KBQQCAgAFEgS8AQIICg0KBQQC
AgABEgS8AQkPCg0KBQQCAgADEgS8ARITCg0KBQQCAgAIEgS8ARQ8ChAKCAQCAgAInAgAEgS8
ARU7CmoKBAQCAgESBMABAhYaXCBUaGUgbWF4aW11bSBudW1iZXIgb2YgcG9saWNpZXMgdG8g
cmV0dXJuLiBJQU0gaWdub3JlcyB0aGlzIHZhbHVlIGFuZCB1c2VzCiB0aGUgdmFsdWUgMTAw
MC4KCg0KBQQCAgEFEgTAAQIHCg0KBQQCAgEBEgTAAQgRCg0KBQQCAgEDEgTAARQVCpYBCgQE
AgICEgTEAQIYGocBIEEgcGFnZSB0b2tlbiByZWNlaXZlZCBpbiBhIFtMaXN0UG9saWNpZXNS
ZXNwb25zZV1bZ29vZ2xlLmlhbS52Mi5MaXN0UG9saWNpZXNSZXNwb25zZV0uIFByb3ZpZGUg
dGhpcyB0b2tlbiB0bwogcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KCg0KBQQCAgIFEgTEAQII
Cg0KBQQCAgIBEgTEAQkTCg0KBQQCAgIDEgTEARYXCjQKAgQDEgbIAQDPAQEaJiBSZXNwb25z
ZSBtZXNzYWdlIGZvciBgTGlzdFBvbGljaWVzYC4KCgsKAwQDARIEyAEIHApMCgQEAwIAEgTK
AQIfGj4gTWV0YWRhdGEgZm9yIHRoZSBwb2xpY2llcyB0aGF0IGFyZSBhdHRhY2hlZCB0byB0
aGUgcmVzb3VyY2UuCgoNCgUEAwIABBIEygECCgoNCgUEAwIABhIEygELEQoNCgUEAwIAARIE
ygESGgoNCgUEAwIAAxIEygEdHgrBAQoEBAMCARIEzgECHRqyASBBIHBhZ2UgdG9rZW4gdGhh
dCB5b3UgY2FuIHVzZSBpbiBhIFtMaXN0UG9saWNpZXNSZXF1ZXN0XVtnb29nbGUuaWFtLnYy
Lkxpc3RQb2xpY2llc1JlcXVlc3RdIHRvIHJldHJpZXZlIHRoZQogbmV4dCBwYWdlLiBJZiB0
aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBhZGRpdGlvbmFsIHBhZ2VzLgoK
DQoFBAMCAQUSBM4BAggKDQoFBAMCAQESBM4BCRgKDQoFBAMCAQMSBM4BGxwKMAoCBAQSBtIB
AN4BARoiIFJlcXVlc3QgbWVzc2FnZSBmb3IgYEdldFBvbGljeWAuCgoLCgMEBAESBNIBCBgK
+wMKBAQEAgASBN0BAjsa7AMgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBw
b2xpY3kgdG8gcmV0cmlldmUuIEZvcm1hdDoKIGBwb2xpY2llcy97YXR0YWNobWVudF9wb2lu
dH0vZGVueXBvbGljaWVzL3twb2xpY3lfaWR9YAoKCiBVc2UgdGhlIFVSTC1lbmNvZGVkIGZ1
bGwgcmVzb3VyY2UgbmFtZSwgd2hpY2ggbWVhbnMgdGhhdCB0aGUgZm9yd2FyZC1zbGFzaAog
Y2hhcmFjdGVyLCBgL2AsIG11c3QgYmUgd3JpdHRlbiBhcyBgJTJGYC4gRm9yIGV4YW1wbGUs
CiBgcG9saWNpZXMvY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20lMkZwcm9q
ZWN0cyUyRm15LXByb2plY3QvZGVueXBvbGljaWVzL215LXBvbGljeWAuCgogRm9yIG9yZ2Fu
aXphdGlvbnMgYW5kIGZvbGRlcnMsIHVzZSB0aGUgbnVtZXJpYyBJRCBpbiB0aGUgZnVsbCBy
ZXNvdXJjZQogbmFtZS4gRm9yIHByb2plY3RzLCB5b3UgY2FuIHVzZSB0aGUgYWxwaGFudW1l
cmljIG9yIHRoZSBudW1lcmljIElELgoKDQoFBAQCAAUSBN0BAggKDQoFBAQCAAESBN0BCQ0K
DQoFBAQCAAMSBN0BEBEKDQoFBAQCAAgSBN0BEjoKEAoIBAQCAAicCAASBN0BEzkKMwoCBAUS
BuEBAPcBARolIFJlcXVlc3QgbWVzc2FnZSBmb3IgYENyZWF0ZVBvbGljeWAuCgoLCgMEBQES
BOEBCBsKsQQKBAQFAgASBO0BAj0aogQgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSB0aGF0IHRo
ZSBwb2xpY3kgaXMgYXR0YWNoZWQgdG8sIGFsb25nIHdpdGggdGhlIGtpbmQgb2YgcG9saWN5
CiB0byBjcmVhdGUuIEZvcm1hdDogYHBvbGljaWVzL3thdHRhY2htZW50X3BvaW50fS9kZW55
cG9saWNpZXNgCgoKIFRoZSBhdHRhY2htZW50IHBvaW50IGlzIGlkZW50aWZpZWQgYnkgaXRz
IFVSTC1lbmNvZGVkIGZ1bGwgcmVzb3VyY2UgbmFtZSwKIHdoaWNoIG1lYW5zIHRoYXQgdGhl
IGZvcndhcmQtc2xhc2ggY2hhcmFjdGVyLCBgL2AsIG11c3QgYmUgd3JpdHRlbiBhcwogYCUy
RmAuIEZvciBleGFtcGxlLAogYHBvbGljaWVzL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2ds
ZWFwaXMuY29tJTJGcHJvamVjdHMlMkZteS1wcm9qZWN0L2Rlbnlwb2xpY2llc2AuCgogRm9y
IG9yZ2FuaXphdGlvbnMgYW5kIGZvbGRlcnMsIHVzZSB0aGUgbnVtZXJpYyBJRCBpbiB0aGUg
ZnVsbCByZXNvdXJjZQogbmFtZS4gRm9yIHByb2plY3RzLCB5b3UgY2FuIHVzZSB0aGUgYWxw
aGFudW1lcmljIG9yIHRoZSBudW1lcmljIElELgoKDQoFBAUCAAUSBO0BAggKDQoFBAUCAAES
BO0BCQ8KDQoFBAUCAAMSBO0BEhMKDQoFBAUCAAgSBO0BFDwKEAoIBAUCAAicCAASBO0BFTsK
LwoEBAUCARIE8AECPRohIFJlcXVpcmVkLiBUaGUgcG9saWN5IHRvIGNyZWF0ZS4KCg0KBQQF
AgEGEgTwAQIICg0KBQQFAgEBEgTwAQkPCg0KBQQFAgEDEgTwARITCg0KBQQFAgEIEgTwARQ8
ChAKCAQFAgEInAgAEgTwARU7CqgCCgQEBQICEgT2AQIXGpkCIFRoZSBJRCB0byB1c2UgZm9y
IHRoaXMgcG9saWN5LCB3aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwgY29tcG9uZW50IG9m
CiB0aGUgcG9saWN5J3MgcmVzb3VyY2UgbmFtZS4gVGhlIElEIG11c3QgY29udGFpbiAzIHRv
IDYzIGNoYXJhY3RlcnMuIEl0IGNhbgogY29udGFpbiBsb3dlcmNhc2UgbGV0dGVycyBhbmQg
bnVtYmVycywgYXMgd2VsbCBhcyBkYXNoZXMgKGAtYCkgYW5kIHBlcmlvZHMKIChgLmApLiBU
aGUgZmlyc3QgY2hhcmFjdGVyIG11c3QgYmUgYSBsb3dlcmNhc2UgbGV0dGVyLgoKDQoFBAUC
AgUSBPYBAggKDQoFBAUCAgESBPYBCRIKDQoFBAUCAgMSBPYBFRYKMwoCBAYSBvoBAIECARol
IFJlcXVlc3QgbWVzc2FnZSBmb3IgYFVwZGF0ZVBvbGljeWAuCgoLCgMEBgESBPoBCBsK9AEK
BAQGAgASBIACAj0a5QEgUmVxdWlyZWQuIFRoZSBwb2xpY3kgdG8gdXBkYXRlLgoKIFRvIHBy
ZXZlbnQgY29uZmxpY3RpbmcgdXBkYXRlcywgdGhlIGBldGFnYCB2YWx1ZSBtdXN0IG1hdGNo
IHRoZSB2YWx1ZSB0aGF0CiBpcyBzdG9yZWQgaW4gSUFNLiBJZiB0aGUgYGV0YWdgIHZhbHVl
cyBkbyBub3QgbWF0Y2gsIHRoZSByZXF1ZXN0IGZhaWxzIHdpdGgKIGEgYDQwOWAgZXJyb3Ig
Y29kZSBhbmQgYEFCT1JURURgIHN0YXR1cy4KCg0KBQQGAgAGEgSAAgIICg0KBQQGAgABEgSA
AgkPCg0KBQQGAgADEgSAAhITCg0KBQQGAgAIEgSAAhQ8ChAKCAQGAgAInAgAEgSAAhU7CjMK
AgQHEgaEAgCYAgEaJSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBEZWxldGVQb2xpY3lgLgoKCwoD
BAcBEgSEAggbCvkDCgQEBwIAEgSPAgI7GuoDIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgcG9saWN5IHRvIGRlbGV0ZS4gRm9ybWF0OgogYHBvbGljaWVzL3thdHRhY2ht
ZW50X3BvaW50fS9kZW55cG9saWNpZXMve3BvbGljeV9pZH1gCgoKIFVzZSB0aGUgVVJMLWVu
Y29kZWQgZnVsbCByZXNvdXJjZSBuYW1lLCB3aGljaCBtZWFucyB0aGF0IHRoZSBmb3J3YXJk
LXNsYXNoCiBjaGFyYWN0ZXIsIGAvYCwgbXVzdCBiZSB3cml0dGVuIGFzIGAlMkZgLiBGb3Ig
ZXhhbXBsZSwKIGBwb2xpY2llcy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNv
bSUyRnByb2plY3RzJTJGbXktcHJvamVjdC9kZW55cG9saWNpZXMvbXktcG9saWN5YC4KCiBG
b3Igb3JnYW5pemF0aW9ucyBhbmQgZm9sZGVycywgdXNlIHRoZSBudW1lcmljIElEIGluIHRo
ZSBmdWxsIHJlc291cmNlCiBuYW1lLiBGb3IgcHJvamVjdHMsIHlvdSBjYW4gdXNlIHRoZSBh
bHBoYW51bWVyaWMgb3IgdGhlIG51bWVyaWMgSUQuCgoNCgUEBwIABRIEjwICCAoNCgUEBwIA
ARIEjwIJDQoNCgUEBwIAAxIEjwIQEQoNCgUEBwIACBIEjwISOgoQCggEBwIACJwIABIEjwIT
OQqZAgoEBAcCARIElwICOxqKAiBPcHRpb25hbC4gVGhlIGV4cGVjdGVkIGBldGFnYCBvZiB0
aGUgcG9saWN5IHRvIGRlbGV0ZS4gSWYgdGhlIHZhbHVlIGRvZXMgbm90IG1hdGNoCiB0aGUg
dmFsdWUgdGhhdCBpcyBzdG9yZWQgaW4gSUFNLCB0aGUgcmVxdWVzdCBmYWlscyB3aXRoIGEg
YDQwOWAgZXJyb3IgY29kZQogYW5kIGBBQk9SVEVEYCBzdGF0dXMuCgogSWYgeW91IG9taXQg
dGhpcyBmaWVsZCwgdGhlIHBvbGljeSBpcyBkZWxldGVkIHJlZ2FyZGxlc3Mgb2YgaXRzIGN1
cnJlbnQKIGBldGFnYC4KCg0KBQQHAgEFEgSXAgIICg0KBQQHAgEBEgSXAgkNCg0KBQQHAgED
EgSXAhARCg0KBQQHAgEIEgSXAhI6ChAKCAQHAgEInAgAEgSXAhM5Cj4KAgQIEgabAgCeAgEa
MCBNZXRhZGF0YSBmb3IgbG9uZy1ydW5uaW5nIGBQb2xpY3lgIG9wZXJhdGlvbnMuCgoLCgME
CAESBJsCCB8KTgoEBAgCABIEnQICLBpAIFRpbWVzdGFtcCB3aGVuIHRoZSBgZ29vZ2xlLmxv
bmdydW5uaW5nLk9wZXJhdGlvbmAgd2FzIGNyZWF0ZWQuCgoNCgUECAIABhIEnQICGwoNCgUE
CAIAARIEnQIcJwoNCgUECAIAAxIEnQIqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V2::Policy::Policy ===
    # Fields for Policy
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: kind Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v2.Policy.AnnotationsEntry)
    # Field: etag Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: rules Type: 11 (.google.iam.v2.PolicyRule)
    # Field: managing_authority Type: 9 ()

# === Message: Google::Iam::V2::Policy::PolicyRule ===
    # Fields for PolicyRule
    # Field: deny_rule Type: 11 (.google.iam.v2.DenyRule)
    # Field: description Type: 9 ()

# === Message: Google::Iam::V2::Policy::ListPoliciesRequest ===
    # Fields for ListPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Iam::V2::Policy::ListPoliciesResponse ===
    # Fields for ListPoliciesResponse
    # Field: policies Type: 11 (.google.iam.v2.Policy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Iam::V2::Policy::GetPolicyRequest ===
    # Fields for GetPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Iam::V2::Policy::CreatePolicyRequest ===
    # Fields for CreatePolicyRequest
    # Field: parent Type: 9 ()
    # Field: policy Type: 11 (.google.iam.v2.Policy)
    # Field: policy_id Type: 9 ()

# === Message: Google::Iam::V2::Policy::UpdatePolicyRequest ===
    # Fields for UpdatePolicyRequest
    # Field: policy Type: 11 (.google.iam.v2.Policy)

# === Message: Google::Iam::V2::Policy::DeletePolicyRequest ===
    # Fields for DeletePolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

# === Message: Google::Iam::V2::Policy::PolicyOperationMetadata ===
    # Fields for PolicyOperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Iam::V2::Policy::PoliciesClient ===
package Google::Iam::V2::Policy::PoliciesClient;

=pod

=head2 Service Client: Google::Iam::V2::Policy::PoliciesClient

Client stub representing the remote C<Policies> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<iam.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iam.googleapis.com:443' );

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

sub list_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2::Policy::ListPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2.Policies',
        method         => 'ListPolicies',
        request        => $req,
        response_class => 'Google::Iam::V2::Policy::ListPoliciesResponse',
    });
}

sub get_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2::Policy::GetPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2.Policies',
        method         => 'GetPolicy',
        request        => $req,
        response_class => 'Google::Iam::V2::Policy::Policy',
    });
}

sub create_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2::Policy::CreatePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2.Policies',
        method         => 'CreatePolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2::Policy::UpdatePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2.Policies',
        method         => 'UpdatePolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V2::Policy::DeletePolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.iam.v2.Policies',
        method         => 'DeletePolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V2::Policy - Compiled Protocol Buffers messages for google/iam/v2/policy.proto

=head1 SYNOPSIS

    use Google::Iam::V2::Policy;

    my $msg = Google::Iam::V2::Policy::Policy->new({
        name => $name,
        uid => $uid,
        kind => $kind,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V2::Policy::Policy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v2/policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V2::Policy::Policy

Data for an IAM policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the `Policy`, which must be unique. Format:
`policies/{attachment_point}/denypolicies/{policy_id}`


The attachment point is identified by its URL-encoded full resource name,
which means that the forward-slash character, `/`, must be written as
`%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies/my-deny-policy`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, requests can use the alphanumeric or the numeric ID.
Responses always contain the numeric ID.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Immutable. The globally unique ID of the `Policy`. Assigned automatically when the
`Policy` is created.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

Output only. The kind of the `Policy`. Always contains the value `DenyPolicy`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A user-specified description of the `Policy`. This value can be up to 63
characters.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Iam::V2::Policy::Policy::AnnotationsEntry>)

A key-value map to store arbitrary metadata for the `Policy`. Keys
can be up to 63 characters. Values can be up to 255 characters.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

An opaque tag that identifies the current version of the `Policy`. IAM uses
this value to help manage concurrent updates, so they do not cause one
update to be overwritten by another.

If this field is present in a [CreatePolicy][] request, the value is
ignored.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the `Policy` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the `Policy` was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the `Policy` was deleted. Empty if the policy is not deleted.

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Iam::V2::Policy::PolicyRule>)

A list of rules that specify the behavior of the `Policy`. All of the rules
should be of the `kind` specified in the `Policy`.

=item * C<< $msg->managing_authority() >> / C<< $msg->managing_authority($value) >>

Type: C<String>

Immutable. Specifies that this policy is managed by an authority and can only be
modified by that authority. Usage is restricted.

=back

=head2 Google::Iam::V2::Policy::PolicyRule

A single rule in a `Policy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deny_rule() >> / C<< $msg->deny_rule($value) >>

Type: C<Message> (L<Google::Iam::V2::Deny::DenyRule>)

A rule for a deny policy.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A user-specified description of the rule. This value can be up to 256
characters.

=back

=head2 Google::Iam::V2::Policy::ListPoliciesRequest

Request message for `ListPolicies`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource that the policy is attached to, along with the kind of policy
to list. Format:
`policies/{attachment_point}/denypolicies`


The attachment point is identified by its URL-encoded full resource name,
which means that the forward-slash character, `/`, must be written as
`%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of policies to return. IAM ignores this value and uses
the value 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token received in a [ListPoliciesResponse][google.iam.v2.ListPoliciesResponse]. Provide this token to
retrieve the next page.

=back

=head2 Google::Iam::V2::Policy::ListPoliciesResponse

Response message for `ListPolicies`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policies() >> / C<< $msg->policies($value) >>

Type: C<Message> (L<Google::Iam::V2::Policy::Policy>)

Metadata for the policies that are attached to the resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A page token that you can use in a [ListPoliciesRequest][google.iam.v2.ListPoliciesRequest] to retrieve the
next page. If this field is omitted, there are no additional pages.

=back

=head2 Google::Iam::V2::Policy::GetPolicyRequest

Request message for `GetPolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the policy to retrieve. Format:
`policies/{attachment_point}/denypolicies/{policy_id}`


Use the URL-encoded full resource name, which means that the forward-slash
character, `/`, must be written as `%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies/my-policy`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=back

=head2 Google::Iam::V2::Policy::CreatePolicyRequest

Request message for `CreatePolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource that the policy is attached to, along with the kind of policy
to create. Format: `policies/{attachment_point}/denypolicies`


The attachment point is identified by its URL-encoded full resource name,
which means that the forward-slash character, `/`, must be written as
`%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V2::Policy::Policy>)

Required. The policy to create.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

The ID to use for this policy, which will become the final component of
the policy's resource name. The ID must contain 3 to 63 characters. It can
contain lowercase letters and numbers, as well as dashes (`-`) and periods
(`.`). The first character must be a lowercase letter.

=back

=head2 Google::Iam::V2::Policy::UpdatePolicyRequest

Request message for `UpdatePolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V2::Policy::Policy>)

Required. The policy to update.

To prevent conflicting updates, the `etag` value must match the value that
is stored in IAM. If the `etag` values do not match, the request fails with
a `409` error code and `ABORTED` status.

=back

=head2 Google::Iam::V2::Policy::DeletePolicyRequest

Request message for `DeletePolicy`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the policy to delete. Format:
`policies/{attachment_point}/denypolicies/{policy_id}`


Use the URL-encoded full resource name, which means that the forward-slash
character, `/`, must be written as `%2F`. For example,
`policies/cloudresourcemanager.googleapis.com%2Fprojects%2Fmy-project/denypolicies/my-policy`.

For organizations and folders, use the numeric ID in the full resource
name. For projects, you can use the alphanumeric or the numeric ID.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The expected `etag` of the policy to delete. If the value does not match
the value that is stored in IAM, the request fails with a `409` error code
and `ABORTED` status.

If you omit this field, the policy is deleted regardless of its current
`etag`.

=back

=head2 Google::Iam::V2::Policy::PolicyOperationMetadata

Metadata for long-running `Policy` operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the `google.longrunning.Operation` was created.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V2::Policy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
