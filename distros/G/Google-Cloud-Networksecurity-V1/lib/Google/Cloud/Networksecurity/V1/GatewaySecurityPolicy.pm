package Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL2dhdGV3YXlfc2VjdXJpdHlfcG9s
aWN5LnByb3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29n
bGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFt
cC5wcm90byLjAwoVR2F0ZXdheVNlY3VyaXR5UG9saWN5EhcKBG5hbWUYASABKAlCA+BBAlIE
bmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIlCgtkZXNjcmlwdGlvbhgEIAEoCUID4EEB
UgtkZXNjcmlwdGlvbhJuChV0bHNfaW5zcGVjdGlvbl9wb2xpY3kYBSABKAlCOuBBAfpBNAoy
bmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL1Rsc0luc3BlY3Rpb25Qb2xpY3lSE3Rs
c0luc3BlY3Rpb25Qb2xpY3k6lQHqQZEBCjRuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5j
b20vR2F0ZXdheVNlY3VyaXR5UG9saWN5Ellwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZ2F0ZXdheVNlY3VyaXR5UG9saWNpZXMve2dhdGV3YXlfc2VjdXJpdHlf
cG9saWN5fSKxAgoiQ3JlYXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5UmVxdWVzdBJUCgZwYXJl
bnQYASABKAlCPOBBAvpBNhI0bmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0dhdGV3
YXlTZWN1cml0eVBvbGljeVIGcGFyZW50EkAKGmdhdGV3YXlfc2VjdXJpdHlfcG9saWN5X2lk
GAIgASgJQgPgQQJSF2dhdGV3YXlTZWN1cml0eVBvbGljeUlkEnMKF2dhdGV3YXlfc2VjdXJp
dHlfcG9saWN5GAMgASgLMjYuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MS5HYXRl
d2F5U2VjdXJpdHlQb2xpY3lCA+BBAlIVZ2F0ZXdheVNlY3VyaXR5UG9saWN5IqMBCiJMaXN0
R2F0ZXdheVNlY3VyaXR5UG9saWNpZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEj
CiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3Np
emUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiLjAQoj
TGlzdEdhdGV3YXlTZWN1cml0eVBvbGljaWVzUmVzcG9uc2UScgoZZ2F0ZXdheV9zZWN1cml0
eV9wb2xpY2llcxgBIAMoCzI2Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjEuR2F0
ZXdheVNlY3VyaXR5UG9saWN5UhdnYXRld2F5U2VjdXJpdHlQb2xpY2llcxImCg9uZXh0X3Bh
Z2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3Vu
cmVhY2hhYmxlInMKH0dldEdhdGV3YXlTZWN1cml0eVBvbGljeVJlcXVlc3QSUAoEbmFtZRgB
IAEoCUI84EEC+kE2CjRuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20vR2F0ZXdheVNl
Y3VyaXR5UG9saWN5UgRuYW1lInYKIkRlbGV0ZUdhdGV3YXlTZWN1cml0eVBvbGljeVJlcXVl
c3QSUAoEbmFtZRgBIAEoCUI84EEC+kE2CjRuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5j
b20vR2F0ZXdheVNlY3VyaXR5UG9saWN5UgRuYW1lItsBCiJVcGRhdGVHYXRld2F5U2VjdXJp
dHlQb2xpY3lSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVm
LkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrEnMKF2dhdGV3YXlfc2VjdXJpdHlfcG9saWN5
GAIgASgLMjYuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MS5HYXRld2F5U2VjdXJp
dHlQb2xpY3lCA+BBAlIVZ2F0ZXdheVNlY3VyaXR5UG9saWN5QvsBCiNjb20uZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZWN1cml0eS52MUIaR2F0ZXdheVNlY3VyaXR5UG9saWN5UHJvdG9QAVpN
Y2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkvYXBpdjEvbmV0d29ya3NlY3Vy
aXR5cGI7bmV0d29ya3NlY3VyaXR5cGKqAh9Hb29nbGUuQ2xvdWQuTmV0d29ya1NlY3VyaXR5
LlYxygIfR29vZ2xlXENsb3VkXE5ldHdvcmtTZWN1cml0eVxWMeoCIkdvb2dsZTo6Q2xvdWQ6
Ok5ldHdvcmtTZWN1cml0eTo6VjFK4ioKBxIFDgCiAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMU
ACoKCQoCAwMSAxUAKQoICgEIEgMXADwKCQoCCCUSAxcAPAoICgEIEgMYAGQKCQoCCAsSAxgA
ZAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADsKCQoCCAgSAxoAOwoICgEIEgMbADwK
CQoCCAESAxsAPAoICgEIEgMcADwKCQoCCCkSAxwAPAoICgEIEgMdADsKCQoCCC0SAx0AOwp+
CgIEABIEIQBAARpyIFRoZSBHYXRld2F5U2VjdXJpdHlQb2xpY3kgcmVzb3VyY2UgY29udGFp
bnMgYSBjb2xsZWN0aW9uIG9mCiBHYXRld2F5U2VjdXJpdHlQb2xpY3lSdWxlcyBhbmQgYXNz
b2NpYXRlZCBtZXRhZGF0YS4KCgoKAwQAARIDIQgdCgsKAwQABxIEIgIlBAoNCgUEAAedCBIE
IgIlBAr2AQoEBAACABIDKwI7GugBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZS4g
TmFtZSBpcyBvZiB0aGUgZm9ybQogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2dhdGV3YXlTZWN1cml0eVBvbGljaWVzL3tnYXRld2F5X3NlY3VyaXR5X3BvbGlj
eX0KIGdhdGV3YXlfc2VjdXJpdHlfcG9saWN5IHNob3VsZCBtYXRjaCB0aGUKIHBhdHRlcm46
KF5bYS16XShbYS16MC05LV17MCw2MX1bYS16MC05XSk/JCkuCgoMCgUEAAIABRIDKwIICgwK
BQQAAgABEgMrCQ0KDAoFBAACAAMSAysQEQoMCgUEAAIACBIDKxI6Cg8KCAQAAgAInAgAEgMr
EzkKSQoEBAACARIELgIvMho7IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhl
IHJlc291cmNlIHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAy4CGwoMCgUEAAIBARIDLhwnCgwK
BQQAAgEDEgMuKisKDAoFBAACAQgSAy8GMQoPCggEAAIBCJwIABIDLwcwCkkKBAQAAgISBDIC
MzIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMg
dXBkYXRlZC4KCgwKBQQAAgIGEgMyAhsKDAoFBAACAgESAzIcJwoMCgUEAAICAxIDMiorCgwK
BQQAAgIIEgMzBjEKDwoIBAACAgicCAASAzMHMAo/CgQEAAIDEgM2AkIaMiBPcHRpb25hbC4g
RnJlZS10ZXh0IGRlc2NyaXB0aW9uIG9mIHRoZSByZXNvdXJjZS4KCgwKBQQAAgMFEgM2AggK
DAoFBAACAwESAzYJFAoMCgUEAAIDAxIDNhcYCgwKBQQAAgMIEgM2GUEKDwoIBAACAwicCAAS
AzYaQAqYAQoEBAACBBIEOgI/BBqJASBPcHRpb25hbC4gTmFtZSBvZiBhIFRMUyBJbnNwZWN0
aW9uIFBvbGljeSByZXNvdXJjZSB0aGF0IGRlZmluZXMgaG93IFRMUwogaW5zcGVjdGlvbiB3
aWxsIGJlIHBlcmZvcm1lZCBmb3IgYW55IHJ1bGUocykgd2hpY2ggZW5hYmxlcyBpdC4KCgwK
BQQAAgQFEgM6AggKDAoFBAACBAESAzoJHgoMCgUEAAIEAxIDOiEiCg0KBQQAAgQIEgQ6Iz8D
Cg8KCAQAAgQInAgAEgM7BCoKDwoHBAACBAifCBIEPAQ+BQpFCgIEARIEQwBXARo5IFJlcXVl
c3QgdXNlZCBieSB0aGUgQ3JlYXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5IG1ldGhvZC4KCgoK
AwQBARIDQwgqCo0BCgQEAQIAEgRGAksEGn8gUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3Vy
Y2Ugb2YgdGhlIEdhdGV3YXlTZWN1cml0eVBvbGljeS4gTXVzdCBiZSBpbiB0aGUKIGZvcm1h
dCBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCgwKBQQBAgAF
EgNGAggKDAoFBAECAAESA0YJDwoMCgUEAQIAAxIDRhITCg0KBQQBAgAIEgRGFEsDCg8KCAQB
AgAInAgAEgNHBCoKDwoHBAECAAifCBIESARKBQqJAgoEBAECARIEUQJSLxr6ASBSZXF1aXJl
ZC4gU2hvcnQgbmFtZSBvZiB0aGUgR2F0ZXdheVNlY3VyaXR5UG9saWN5IHJlc291cmNlIHRv
IGJlIGNyZWF0ZWQuCiBUaGlzIHZhbHVlIHNob3VsZCBiZSAxLTYzIGNoYXJhY3RlcnMgbG9u
ZywgY29udGFpbmluZyBvbmx5CiBsZXR0ZXJzLCBudW1iZXJzLCBoeXBoZW5zLCBhbmQgdW5k
ZXJzY29yZXMsIGFuZCBzaG91bGQgbm90IHN0YXJ0CiB3aXRoIGEgbnVtYmVyLiBFLmcuICJn
YXRld2F5X3NlY3VyaXR5X3BvbGljeTEiLgoKDAoFBAECAQUSA1ECCAoMCgUEAQIBARIDUQkj
CgwKBQQBAgEDEgNRJicKDAoFBAECAQgSA1IGLgoPCggEAQIBCJwIABIDUgctCkcKBAQBAgIS
BFUCVi8aOSBSZXF1aXJlZC4gR2F0ZXdheVNlY3VyaXR5UG9saWN5IHJlc291cmNlIHRvIGJl
IGNyZWF0ZWQuCgoMCgUEAQICBhIDVQIXCgwKBQQBAgIBEgNVGC8KDAoFBAECAgMSA1UyMwoM
CgUEAQICCBIDVgYuCg8KCAQBAgIInAgAEgNWBy0KRwoCBAISBFoAbQEaOyBSZXF1ZXN0IHVz
ZWQgd2l0aCB0aGUgTGlzdEdhdGV3YXlTZWN1cml0eVBvbGljaWVzIG1ldGhvZC4KCgoKAwQC
ARIDWggqCrEBCgQEAgIAEgReAmMEGqIBIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9j
YXRpb24gZnJvbSB3aGljaCB0aGUgR2F0ZXdheVNlY3VyaXR5UG9saWNpZXMKIHNob3VsZCBi
ZSBsaXN0ZWQsIHNwZWNpZmllZCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCgwKBQQCAgAFEgNeAggKDAoFBAICAAESA14JDwoM
CgUEAgIAAxIDXhITCg0KBQQCAgAIEgReFGMDCg8KCAQCAgAInAgAEgNfBCoKDwoHBAICAAif
CBIEYARiBQpMCgQEAgIBEgNmAhYaPyBNYXhpbXVtIG51bWJlciBvZiBHYXRld2F5U2VjdXJp
dHlQb2xpY2llcyB0byByZXR1cm4gcGVyIGNhbGwuCgoMCgUEAgIBBRIDZgIHCgwKBQQCAgEB
EgNmCBEKDAoFBAICAQMSA2YUFQrlAQoEBAICAhIDbAIYGtcBIFRoZSB2YWx1ZSByZXR1cm5l
ZCBieSB0aGUgbGFzdAogJ0xpc3RHYXRld2F5U2VjdXJpdHlQb2xpY2llc1Jlc3BvbnNlJyBJ
bmRpY2F0ZXMgdGhhdCB0aGlzIGlzIGEKIGNvbnRpbnVhdGlvbiBvZiBhIHByaW9yICdMaXN0
R2F0ZXdheVNlY3VyaXR5UG9saWNpZXMnIGNhbGwsIGFuZAogdGhhdCB0aGUgc3lzdGVtIHNo
b3VsZCByZXR1cm4gdGhlIG5leHQgcGFnZSBvZiBkYXRhLgoKDAoFBAICAgUSA2wCCAoMCgUE
AgICARIDbAkTCgwKBQQCAgIDEgNsFhcKSgoCBAMSBHAAewEaPiBSZXNwb25zZSByZXR1cm5l
ZCBieSB0aGUgTGlzdEdhdGV3YXlTZWN1cml0eVBvbGljaWVzIG1ldGhvZC4KCgoKAwQDARID
cAgrCjkKBAQDAgASA3ICPxosIExpc3Qgb2YgR2F0ZXdheVNlY3VyaXR5UG9saWNpZXMgcmVz
b3VyY2VzLgoKDAoFBAMCAAQSA3ICCgoMCgUEAwIABhIDcgsgCgwKBQQDAgABEgNyIToKDAoF
BAMCAAMSA3I9PgroAQoEBAMCARIDdwIdGtoBIElmIHRoZXJlIG1pZ2h0IGJlIG1vcmUgcmVz
dWx0cyB0aGFuIHRob3NlIGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiAnbmV4
dF9wYWdlX3Rva2VuJyBpcyBpbmNsdWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiByZXN1
bHRzLCBjYWxsIHRoaXMKIG1ldGhvZCBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgJ25leHRf
cGFnZV90b2tlbicgYXMgJ3BhZ2VfdG9rZW4nLgoKDAoFBAMCAQUSA3cCCAoMCgUEAwIBARID
dwkYCgwKBQQDAgEDEgN3GxwKMwoEBAMCAhIDegIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQg
bm90IGJlIHJlYWNoZWQuCgoMCgUEAwICBBIDegIKCgwKBQQDAgIFEgN6CxEKDAoFBAMCAgES
A3oSHQoMCgUEAwICAxIDeiAhCkMKAgQEEgV+AIcBARo2IFJlcXVlc3QgdXNlZCBieSB0aGUg
R2V0R2F0ZXdheVNlY3VyaXR5UG9saWN5IG1ldGhvZC4KCgoKAwQEARIDfggnCqQBCgQEBAIA
EgaBAQKGAQQakwEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgR2F0ZXdheVNlY3VyaXR5UG9s
aWN5IHRvIGdldC4gTXVzdCBiZSBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2dhdGV3YXlTZWN1cml0eVBvbGljaWVzLypgLgoKDQoF
BAQCAAUSBIEBAggKDQoFBAQCAAESBIEBCQ0KDQoFBAQCAAMSBIEBEBEKDwoFBAQCAAgSBoEB
EoYBAwoQCggEBAIACJwIABIEggEEKgoRCgcEBAIACJ8IEgaDAQSFAQUKRwoCBAUSBooBAJMB
ARo5IFJlcXVlc3QgdXNlZCBieSB0aGUgRGVsZXRlR2F0ZXdheVNlY3VyaXR5UG9saWN5IG1l
dGhvZC4KCgsKAwQFARIEigEIKgqnAQoEBAUCABIGjQECkgEEGpYBIFJlcXVpcmVkLiBBIG5h
bWUgb2YgdGhlIEdhdGV3YXlTZWN1cml0eVBvbGljeSB0byBkZWxldGUuIE11c3QgYmUgaW4g
dGhlCiBmb3JtYXQgYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9n
YXRld2F5U2VjdXJpdHlQb2xpY2llcy8qYC4KCg0KBQQFAgAFEgSNAQIICg0KBQQFAgABEgSN
AQkNCg0KBQQFAgADEgSNARARCg8KBQQFAgAIEgaNARKSAQMKEAoIBAUCAAicCAASBI4BBCoK
EQoHBAUCAAifCBIGjwEEkQEFCkcKAgQGEgaWAQCiAQEaOSBSZXF1ZXN0IHVzZWQgYnkgdGhl
IFVwZGF0ZUdhdGV3YXlTZWN1cml0eVBvbGljeSBtZXRob2QuCgoLCgMEBgESBJYBCCoK5wIK
BAQGAgASBpwBAp0BLxrWAiBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1c2VkIHRvIHNwZWNp
ZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIEdhdGV3YXlTZWN1cml0
eVBvbGljeSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVjaWZpZWQg
aW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAog
dGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlz
IGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sgdGhl
biBhbGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEBgIABhIEnAECGwoNCgUE
BgIAARIEnAEcJwoNCgUEBgIAAxIEnAEqKwoNCgUEBgIACBIEnQEGLgoQCggEBgIACJwIABIE
nQEHLQpDCgQEBgIBEgagAQKhAS8aMyBSZXF1aXJlZC4gVXBkYXRlZCBHYXRld2F5U2VjdXJp
dHlQb2xpY3kgcmVzb3VyY2UuCgoNCgUEBgIBBhIEoAECFwoNCgUEBgIBARIEoAEYLwoNCgUE
BgIBAxIEoAEyMwoNCgUEBgIBCBIEoQEGLgoQCggEBgIBCJwIABIEoQEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy ===
    # Fields for GatewaySecurityPolicy
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: tls_inspection_policy Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::CreateGatewaySecurityPolicyRequest ===
    # Fields for CreateGatewaySecurityPolicyRequest
    # Field: parent Type: 9 ()
    # Field: gateway_security_policy_id Type: 9 ()
    # Field: gateway_security_policy Type: 11 (.google.cloud.networksecurity.v1.GatewaySecurityPolicy)

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesRequest ===
    # Fields for ListGatewaySecurityPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesResponse ===
    # Fields for ListGatewaySecurityPoliciesResponse
    # Field: gateway_security_policies Type: 11 (.google.cloud.networksecurity.v1.GatewaySecurityPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GetGatewaySecurityPolicyRequest ===
    # Fields for GetGatewaySecurityPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::DeleteGatewaySecurityPolicyRequest ===
    # Fields for DeleteGatewaySecurityPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::UpdateGatewaySecurityPolicyRequest ===
    # Fields for UpdateGatewaySecurityPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: gateway_security_policy Type: 11 (.google.cloud.networksecurity.v1.GatewaySecurityPolicy)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1/gateway_security_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1/gateway_security_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy

The GatewaySecurityPolicy resource contains a collection of
GatewaySecurityPolicyRules and associated metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource. Name is of the form
projects/{project}/locations/{location}/gatewaySecurityPolicies/{gateway_security_policy}
gateway_security_policy should match the
pattern:(^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->tls_inspection_policy() >> / C<< $msg->tls_inspection_policy($value) >>

Type: C<String>

Optional. Name of a TLS Inspection Policy resource that defines how TLS
inspection will be performed for any rule(s) which enables it.

=back

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::CreateGatewaySecurityPolicyRequest

Request used by the CreateGatewaySecurityPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the GatewaySecurityPolicy. Must be in the
format `projects/{project}/locations/{location}`.

=item * C<< $msg->gateway_security_policy_id() >> / C<< $msg->gateway_security_policy_id($value) >>

Type: C<String>

Required. Short name of the GatewaySecurityPolicy resource to be created.
This value should be 1-63 characters long, containing only
letters, numbers, hyphens, and underscores, and should not start
with a number. E.g. "gateway_security_policy1".

=item * C<< $msg->gateway_security_policy() >> / C<< $msg->gateway_security_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy>)

Required. GatewaySecurityPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesRequest

Request used with the ListGatewaySecurityPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the GatewaySecurityPolicies
should be listed, specified in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of GatewaySecurityPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last
'ListGatewaySecurityPoliciesResponse' Indicates that this is a
continuation of a prior 'ListGatewaySecurityPolicies' call, and
that the system should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::ListGatewaySecurityPoliciesResponse

Response returned by the ListGatewaySecurityPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gateway_security_policies() >> / C<< $msg->gateway_security_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy>)

List of GatewaySecurityPolicies resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
'next_page_token' is included. To get the next set of results, call this
method again using the value of 'next_page_token' as 'page_token'.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GetGatewaySecurityPolicyRequest

Request used by the GetGatewaySecurityPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the GatewaySecurityPolicy to get. Must be in the format
`projects/{project}/locations/{location}/gatewaySecurityPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::DeleteGatewaySecurityPolicyRequest

Request used by the DeleteGatewaySecurityPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the GatewaySecurityPolicy to delete. Must be in the
format `projects/{project}/locations/{location}/gatewaySecurityPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::UpdateGatewaySecurityPolicyRequest

Request used by the UpdateGatewaySecurityPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
GatewaySecurityPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->gateway_security_policy() >> / C<< $msg->gateway_security_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::GatewaySecurityPolicy>)

Required. Updated GatewaySecurityPolicy resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
