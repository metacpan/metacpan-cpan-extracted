package Google::Cloud::Ids::Logging::V1::Logging;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvaWRzL2xvZ2dpbmcvdjEvbG9nZ2luZy5wcm90bxIbZ29vZ2xlLmNs
b3VkLmlkcy5sb2dnaW5nLnYxGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iqgcKCVRocmVhdExvZxISCgRuYW1lGAEg
ASgJUgRuYW1lEhsKCXRocmVhdF9pZBgNIAEoCVIIdGhyZWF0SWQSOQoKYWxlcnRfdGltZRgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWFsZXJ0VGltZRJWCg5hbGVydF9z
ZXZlcml0eRgTIAEoDjIvLmdvb2dsZS5jbG91ZC5pZHMubG9nZ2luZy52MS5UaHJlYXRMb2cu
U2V2ZXJpdHlSDWFsZXJ0U2V2ZXJpdHkSEgoEdHlwZRgEIAEoCVIEdHlwZRIaCghjYXRlZ29y
eRgSIAEoCVIIY2F0ZWdvcnkSKgoRc291cmNlX2lwX2FkZHJlc3MYBSABKAlSD3NvdXJjZUlw
QWRkcmVzcxIfCgtzb3VyY2VfcG9ydBgGIAEoBVIKc291cmNlUG9ydBI0ChZkZXN0aW5hdGlv
bl9pcF9hZGRyZXNzGAcgASgJUhRkZXN0aW5hdGlvbklwQWRkcmVzcxIpChBkZXN0aW5hdGlv
bl9wb3J0GAggASgFUg9kZXN0aW5hdGlvblBvcnQSHwoLaXBfcHJvdG9jb2wYCSABKAlSCmlw
UHJvdG9jb2wSTgoJZGlyZWN0aW9uGAogASgOMjAuZ29vZ2xlLmNsb3VkLmlkcy5sb2dnaW5n
LnYxLlRocmVhdExvZy5EaXJlY3Rpb25SCWRpcmVjdGlvbhIdCgpzZXNzaW9uX2lkGA4gASgJ
UglzZXNzaW9uSWQSIQoMcmVwZWF0X2NvdW50GA8gASgJUgtyZXBlYXRDb3VudBIgCgthcHBs
aWNhdGlvbhgQIAEoCVILYXBwbGljYXRpb24SJgoPdXJpX29yX2ZpbGVuYW1lGBEgASgJUg11
cmlPckZpbGVuYW1lEhIKBGN2ZXMYFCADKAlSBGN2ZXMSGAoHZGV0YWlscxgLIAEoCVIHZGV0
YWlscxIYCgduZXR3b3JrGAwgASgJUgduZXR3b3JrImQKCFNldmVyaXR5EhgKFFNFVkVSSVRZ
X1VOU1BFQ0lGSUVEEAASBwoDTE9XEAISCgoGTUVESVVNEAMSCAoESElHSBAEEgwKCENSSVRJ
Q0FMEAUSEQoNSU5GT1JNQVRJT05BTBAGIlAKCURpcmVjdGlvbhIXChNESVJFQ1RJT05fVU5E
RUZJTkVEEAASFAoQQ0xJRU5UX1RPX1NFUlZFUhABEhQKEFNFUlZFUl9UT19DTElFTlQQAiKY
BAoKVHJhZmZpY0xvZxI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIJc3RhcnRUaW1lEjwKDGVsYXBzZWRfdGltZRgCIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvblILZWxhcHNlZFRpbWUSGAoHbmV0d29yaxgDIAEoCVIHbmV0d29yaxIq
ChFzb3VyY2VfaXBfYWRkcmVzcxgEIAEoCVIPc291cmNlSXBBZGRyZXNzEh8KC3NvdXJjZV9w
b3J0GAUgASgFUgpzb3VyY2VQb3J0EjQKFmRlc3RpbmF0aW9uX2lwX2FkZHJlc3MYBiABKAlS
FGRlc3RpbmF0aW9uSXBBZGRyZXNzEikKEGRlc3RpbmF0aW9uX3BvcnQYByABKAVSD2Rlc3Rp
bmF0aW9uUG9ydBIfCgtpcF9wcm90b2NvbBgIIAEoCVIKaXBQcm90b2NvbBIgCgthcHBsaWNh
dGlvbhgJIAEoCVILYXBwbGljYXRpb24SHQoKc2Vzc2lvbl9pZBgMIAEoCVIJc2Vzc2lvbklk
EiEKDHJlcGVhdF9jb3VudBgNIAEoCVILcmVwZWF0Q291bnQSHwoLdG90YWxfYnl0ZXMYDiAB
KANSCnRvdGFsQnl0ZXMSIwoNdG90YWxfcGFja2V0cxgPIAEoA1IMdG90YWxQYWNrZXRzQmwK
H2NvbS5nb29nbGUuY2xvdWQuaWRzLmxvZ2dpbmcudjFCDExvZ2dpbmdQcm90b1ABWjljbG91
ZC5nb29nbGUuY29tL2dvL2lkcy9sb2dnaW5nL2FwaXYxL2xvZ2dpbmdwYjtsb2dnaW5ncGJK
yicKBxIFDgCdAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACQKCQoCAwASAxIAKAoJCgIDARIDEwApCggKAQgSAxUAUAoJCgIICxIDFQBQCggKAQgSAxYA
IgoJCgIIChIDFgAiCggKAQgSAxcALQoJCgIICBIDFwAtCggKAQgSAxgAOAoJCgIIARIDGAA4
Ci0KAgQAEgQbAHABGiEgQSB0aHJlYXQgZGV0ZWN0ZWQgYnkgQ2xvdWQgSURTLgoKCgoDBAAB
EgMbCBEKPQoEBAAEABIEHQIqAxovIERlc2NyaWJlcyB0aGUgdHlwZSBvZiBzZXZlcml0eSBv
ZiB0aGUgdGhyZWF0LgoKDAoFBAAEAAESAx0HDwo2CgYEAAQAAgASAx8EHRonIERlZmF1bHQg
dmFsdWUgLSBzaG91bGQgbmV2ZXIgYmUgdXNlZC4KCg4KBwQABAACAAESAx8EGAoOCgcEAAQA
AgACEgMfGxwKDQoGBAAEAAIBEgMhBAwKDgoHBAAEAAIBARIDIQQHCg4KBwQABAACAQISAyEK
CwoNCgYEAAQAAgISAyMEDwoOCgcEAAQAAgIBEgMjBAoKDgoHBAAEAAICAhIDIw0OCg0KBgQA
BAACAxIDJQQNCg4KBwQABAACAwESAyUECAoOCgcEAAQAAgMCEgMlCwwKDQoGBAAEAAIEEgMn
BBEKDgoHBAAEAAIEARIDJwQMCg4KBwQABAACBAISAycPEAoNCgYEAAQAAgUSAykEFgoOCgcE
AAQAAgUBEgMpBBEKDgoHBAAEAAIFAhIDKRQVCgwKBAQABAESBCwCNQMKDAoFBAAEAQESAywH
EApHCgYEAAQBAgASAy4EHBo4IERlZmF1bHQgdmFsdWUgLSBwZXJtaXR0ZWQgc2luY2UgRGly
ZWN0aW9uIGlzIG9wdGlvbmFsLgoKDgoHBAAEAQIAARIDLgQXCg4KBwQABAECAAISAy4aGwoh
CgYEAAQBAgESAzEEGRoSIEluZ3Jlc3MgdHJhZmZpYy4KCg4KBwQABAECAQESAzEEFAoOCgcE
AAQBAgECEgMxFxgKIAoGBAAEAQICEgM0BBkaESBFZ3Jlc3MgdHJhZmZpYy4KCg4KBwQABAEC
AgESAzQEFAoOCgcEAAQBAgICEgM0FxgKQQoEBAACABIDOAISGjQgTmFtZSBvZiB0aGUgdGhy
ZWF0LCBlLGcuICJTdXNwaWNpb3VzIEhUVFAgRXZhc2lvbiIKCgwKBQQAAgAFEgM4AggKDAoF
BAACAAESAzgJDQoMCgUEAAIAAxIDOBARCicKBAQAAgESAzsCGBoaIFVuaXF1ZSBJRCBvZiB0
aGUgdGhyZWF0LgoKDAoFBAACAQUSAzsCCAoMCgUEAAIBARIDOwkSCgwKBQQAAgEDEgM7FRcK
JQoEBAACAhIDPgIrGhggVGhlIHRpbWUgb2YgdGhlIGFsZXJ0LgoKDAoFBAACAgYSAz4CGwoM
CgUEAAICARIDPhwmCgwKBQQAAgIDEgM+KSoKIgoEBAACAxIDQQIfGhUgU2V2ZXJpdHkgb2Yg
dGhyZWF0LgoKDAoFBAACAwYSA0ECCgoMCgUEAAIDARIDQQsZCgwKBQQAAgMDEgNBHB4KNgoE
BAACBBIDRAISGikgVGhlIHR5cGUgb2YgdGhlIHRocmVhdCwgZS5nLiAiU3B5d2FyZSIuCgoM
CgUEAAIEBRIDRAIICgwKBQQAAgQBEgNECQ0KDAoFBAACBAMSA0QQEQpICgQEAAIFEgNHAhca
OyBDYXRlZ29yeSAoc3ViLXR5cGUpIG9mIHRoZSB0aHJlYXQsIGUuZy4gImNvZGUtZXhlY3V0
aW9uIi4KCgwKBQQAAgUFEgNHAggKDAoFBAACBQESA0cJEQoMCgUEAAIFAxIDRxQWCkYKBAQA
AgYSA0oCHxo5IFRoZSBzb3VyY2UgSVAgQWRkcmVzcyBvZiB0aGUgcGFja2V0LCBlLmcuICIz
NS4xOTEuOC43OSIKCgwKBQQAAgYFEgNKAggKDAoFBAACBgESA0oJGgoMCgUEAAIGAxIDSh0e
CjcKBAQAAgcSA00CGBoqIFRoZSBzb3VyY2UgcG9ydCBvZiB0aGUgcGFja2V0LCBlLmcuIDgw
ODAKCgwKBQQAAgcFEgNNAgcKDAoFBAACBwESA00IEwoMCgUEAAIHAxIDTRYXCk0KBAQAAggS
A1ACJBpAIFRoZSBkZXN0aW5hdGlvbiBJUCBBZGRyZXNzIG9mIHRoZSBwYWNrZXQsIGUuZy4g
IjE5Mi4xNjguMTAwLjIiCgoMCgUEAAIIBRIDUAIICgwKBQQAAggBEgNQCR8KDAoFBAACCAMS
A1AiIwo7CgQEAAIJEgNTAh0aLiBUaGUgZGVzdGluYXRpb24gcG9ydCBvZiB0aGUgcGFja2V0
LCBlLmcuIDEwMAoKDAoFBAACCQUSA1MCBwoMCgUEAAIJARIDUwgYCgwKBQQAAgkDEgNTGxwK
OQoEBAACChIDVgIZGiwgVGhlIElQIHByb3RvY29sIG9mIHRoZSBwYWNrZXQsIGUuZy4gIlRD
UCIuCgoMCgUEAAIKBRIDVgIICgwKBQQAAgoBEgNWCRQKDAoFBAACCgMSA1YXGAo/CgQEAAIL
EgNZAhsaMiBUaGUgZGlyZWN0aW9uIG9mIHRoZSBwYWNrZXQgLSBhbiBvcHRpb25hbCBmaWVs
ZC4KCgwKBQQAAgsGEgNZAgsKDAoFBAACCwESA1kMFQoMCgUEAAILAxIDWRgaCjcKBAQAAgwS
A1wCGRoqIElEIG9mIHRoZSBMYXllciA0IHNlc3Npb24gb2YgdGhlIHRocmVhdC4KCgwKBQQA
AgwFEgNcAggKDAoFBAACDAESA1wJEwoMCgUEAAIMAxIDXBYYCnQKBAQAAg0SA2ACGxpnIE51
bWJlciBvZiBzZXNzaW9ucyB3aXRoIHNhbWUgc291cmNlIElQLCBkZXN0aW5hdGlvbiBJUCwg
YXBwbGljYXRpb24sIGFuZAogdHlwZSBzZWVuIHdpdGhpbiA1IHNlY29uZHMuCgoMCgUEAAIN
BRIDYAIICgwKBQQAAg0BEgNgCRUKDAoFBAACDQMSA2AYGgo3CgQEAAIOEgNjAhoaKiBBcHBs
aWNhdGlvbiBhc3NvY2lhdGVkIHdpdGggdGhlIHNlc3Npb24uCgoMCgUEAAIOBRIDYwIICgwK
BQQAAg4BEgNjCRQKDAoFBAACDgMSA2MXGQpVCgQEAAIPEgNmAh4aSCBWYXJpYWJsZSBmaWVs
ZC4gVVJJIG9yIGZpbGVuYW1lIG9mIHRoZSByZWxldmFudCB0aHJlYXQsIGlmIGFwcGxpY2Fi
bGUuCgoMCgUEAAIPBRIDZgIICgwKBQQAAg8BEgNmCRgKDAoFBAACDwMSA2YbHQolCgQEAAIQ
EgNpAhwaGCBDVkUgSURzIG9mIHRoZSB0aHJlYXQuCgoMCgUEAAIQBBIDaQIKCgwKBQQAAhAF
EgNpCxEKDAoFBAACEAESA2kSFgoMCgUEAAIQAxIDaRkbCjsKBAQAAhESA2wCFhouIERldGFp
bHMgb2YgdGhlIHRocmVhdCByZXBvcnRlZCBieSB0aGUgSURTIFZNCgoMCgUEAAIRBRIDbAII
CgwKBQQAAhEBEgNsCRAKDAoFBAACEQMSA2wTFQo8CgQEAAISEgNvAhYaLyBUaGUgbmV0d29y
ayBhc3NvY2lhdGVkIHdpdGggdGhlIElEUyBFbmRwb2ludC4KCgwKBQQAAhIFEgNvAggKDAoF
BAACEgESA28JEAoMCgUEAAISAxIDbxMVCtUBCgIEARIFdQCdAQEaxwEgVHJhZmZpYyBkZXRl
Y3RlZCBieSBDbG91ZCBJRFMuCiBGaWVsZHMgdGFrZW4gZnJvbToKIGh0dHBzOi8vZG9jcy5w
YWxvYWx0b25ldHdvcmtzLmNvbS9wYW4tb3MvOC0xL3Bhbi1vcy1hZG1pbi9tb25pdG9yaW5n
L3VzZS1zeXNsb2ctZm9yLW1vbml0b3Jpbmcvc3lzbG9nLWZpZWxkLWRlc2NyaXB0aW9ucy90
cmFmZmljLWxvZy1maWVsZHMuaHRtbC4KCgoKAwQBARIDdQgSCiUKBAQBAgASA3cCKxoYIFRp
bWUgb2Ygc2Vzc2lvbiBzdGFydC4KCgwKBQQBAgAGEgN3AhsKDAoFBAECAAESA3ccJgoMCgUE
AQIAAxIDdykqCisKBAQBAgESA3oCLBoeIEVsYXBzZWQgdGltZSBvZiB0aGUgc2Vzc2lvbi4K
CgwKBQQBAgEGEgN6AhoKDAoFBAECAQESA3obJwoMCgUEAQIBAxIDeiorCjwKBAQBAgISA30C
FRovIFRoZSBuZXR3b3JrIGFzc29jaWF0ZWQgd2l0aCB0aGUgSURTIEVuZHBvaW50LgoKDAoF
BAECAgUSA30CCAoMCgUEAQICARIDfQkQCgwKBQQBAgIDEgN9ExQKRwoEBAECAxIEgAECHxo5
IFRoZSBzb3VyY2UgSVAgQWRkcmVzcyBvZiB0aGUgcGFja2V0LCBlLmcuICIzNS4xOTEuOC43
OSIKCg0KBQQBAgMFEgSAAQIICg0KBQQBAgMBEgSAAQkaCg0KBQQBAgMDEgSAAR0eCjgKBAQB
AgQSBIMBAhgaKiBUaGUgc291cmNlIHBvcnQgb2YgdGhlIHBhY2tldCwgZS5nLiA4MDgwCgoN
CgUEAQIEBRIEgwECBwoNCgUEAQIEARIEgwEIEwoNCgUEAQIEAxIEgwEWFwpOCgQEAQIFEgSG
AQIkGkAgVGhlIGRlc3RpbmF0aW9uIElQIEFkZHJlc3Mgb2YgdGhlIHBhY2tldCwgZS5nLiAi
MTkyLjE2OC4xMDAuMiIKCg0KBQQBAgUFEgSGAQIICg0KBQQBAgUBEgSGAQkfCg0KBQQBAgUD
EgSGASIjCjwKBAQBAgYSBIkBAh0aLiBUaGUgZGVzdGluYXRpb24gcG9ydCBvZiB0aGUgcGFj
a2V0LCBlLmcuIDEwMAoKDQoFBAECBgUSBIkBAgcKDQoFBAECBgESBIkBCBgKDQoFBAECBgMS
BIkBGxwKOgoEBAECBxIEjAECGRosIFRoZSBJUCBwcm90b2NvbCBvZiB0aGUgcGFja2V0LCBl
LmcuICJUQ1AiLgoKDQoFBAECBwUSBIwBAggKDQoFBAECBwESBIwBCRQKDQoFBAECBwMSBIwB
FxgKOAoEBAECCBIEjwECGRoqIEFwcGxpY2F0aW9uIGFzc29jaWF0ZWQgd2l0aCB0aGUgc2Vz
c2lvbi4KCg0KBQQBAggFEgSPAQIICg0KBQQBAggBEgSPAQkUCg0KBQQBAggDEgSPARcYCiwK
BAQBAgkSBJIBAhkaHiBUaGUgZGlyZWN0aW9uIG9mIHRoZSBwYWNrZXQuCgoNCgUEAQIJBRIE
kgECCAoNCgUEAQIJARIEkgEJEwoNCgUEAQIJAxIEkgEWGAp1CgQEAQIKEgSWAQIbGmcgTnVt
YmVyIG9mIHNlc3Npb25zIHdpdGggc2FtZSBzb3VyY2UgSVAsIGRlc3RpbmF0aW9uIElQLCBh
cHBsaWNhdGlvbiwgYW5kCiB0eXBlIHNlZW4gd2l0aGluIDUgc2Vjb25kcy4KCg0KBQQBAgoF
EgSWAQIICg0KBQQBAgoBEgSWAQkVCg0KBQQBAgoDEgSWARgaCkEKBAQBAgsSBJkBAhkaMyBU
b3RhbCBudW1iZXIgb2YgYnl0ZXMgdHJhbnNmZXJyZWQgaW4gdGhlIHNlc3Npb24uCgoNCgUE
AQILBRIEmQECBwoNCgUEAQILARIEmQEIEwoNCgUEAQILAxIEmQEWGApDCgQEAQIMEgScAQIb
GjUgVG90YWwgbnVtYmVyIG9mIHBhY2tldHMgdHJhbnNmZXJyZWQgaW4gdGhlIHNlc3Npb24u
CgoNCgUEAQIMBRIEnAECBwoNCgUEAQIMARIEnAEIFQoNCgUEAQIMAxIEnAEYGmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ids::Logging::V1::Logging::ThreatLog ===
    # Fields for ThreatLog
    # Field: name Type: 9 ()
    # Field: threat_id Type: 9 ()
    # Field: alert_time Type: 11 (.google.protobuf.Timestamp)
    # Field: alert_severity Type: 14 (.google.cloud.ids.logging.v1.ThreatLog.Severity)
    # Field: type Type: 9 ()
    # Field: category Type: 9 ()
    # Field: source_ip_address Type: 9 ()
    # Field: source_port Type: 5 ()
    # Field: destination_ip_address Type: 9 ()
    # Field: destination_port Type: 5 ()
    # Field: ip_protocol Type: 9 ()
    # Field: direction Type: 14 (.google.cloud.ids.logging.v1.ThreatLog.Direction)
    # Field: session_id Type: 9 ()
    # Field: repeat_count Type: 9 ()
    # Field: application Type: 9 ()
    # Field: uri_or_filename Type: 9 ()
    # Field: cves Type: 9 ()
    # Field: details Type: 9 ()
    # Field: network Type: 9 ()

# Enum: ThreatLog::Severity
our $ThreatLog_SEVERITY_UNSPECIFIED = 0;
our $ThreatLog_LOW = 2;
our $ThreatLog_MEDIUM = 3;
our $ThreatLog_HIGH = 4;
our $ThreatLog_CRITICAL = 5;
our $ThreatLog_INFORMATIONAL = 6;

# Enum: ThreatLog::Direction
our $ThreatLog_DIRECTION_UNDEFINED = 0;
our $ThreatLog_CLIENT_TO_SERVER = 1;
our $ThreatLog_SERVER_TO_CLIENT = 2;

# === Message: Google::Cloud::Ids::Logging::V1::Logging::TrafficLog ===
    # Fields for TrafficLog
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: elapsed_time Type: 11 (.google.protobuf.Duration)
    # Field: network Type: 9 ()
    # Field: source_ip_address Type: 9 ()
    # Field: source_port Type: 5 ()
    # Field: destination_ip_address Type: 9 ()
    # Field: destination_port Type: 5 ()
    # Field: ip_protocol Type: 9 ()
    # Field: application Type: 9 ()
    # Field: session_id Type: 9 ()
    # Field: repeat_count Type: 9 ()
    # Field: total_bytes Type: 3 ()
    # Field: total_packets Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ids::Logging::V1::Logging - Compiled Protocol Buffers messages for google/cloud/ids/logging/v1/logging.proto

=head1 SYNOPSIS

    use Google::Cloud::Ids::Logging::V1::Logging;

    my $msg = Google::Cloud::Ids::Logging::V1::Logging::ThreatLog->new({
        name => $name,
        threat_id => $threat_id,
        alert_time => $alert_time,
        alert_severity => $alert_severity,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ids::Logging::V1::Logging::ThreatLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ids/logging/v1/logging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ids::Logging::V1::Logging::ThreatLog

A threat detected by Cloud IDS.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the threat, e,g. "Suspicious HTTP Evasion"

=item * C<< $msg->threat_id() >> / C<< $msg->threat_id($value) >>

Type: C<String>

Unique ID of the threat.

=item * C<< $msg->alert_time() >> / C<< $msg->alert_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time of the alert.

=item * C<< $msg->alert_severity() >> / C<< $msg->alert_severity($value) >>

Type: C<Enum> (L<Google::Cloud::Ids::Logging::V1::ThreatLog::Severity>)

Severity of threat.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the threat, e.g. "Spyware".

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

Category (sub-type) of the threat, e.g. "code-execution".

=item * C<< $msg->source_ip_address() >> / C<< $msg->source_ip_address($value) >>

Type: C<String>

The source IP Address of the packet, e.g. "35.191.8.79"

=item * C<< $msg->source_port() >> / C<< $msg->source_port($value) >>

Type: C<Int32>

The source port of the packet, e.g. 8080

=item * C<< $msg->destination_ip_address() >> / C<< $msg->destination_ip_address($value) >>

Type: C<String>

The destination IP Address of the packet, e.g. "192.168.100.2"

=item * C<< $msg->destination_port() >> / C<< $msg->destination_port($value) >>

Type: C<Int32>

The destination port of the packet, e.g. 100

=item * C<< $msg->ip_protocol() >> / C<< $msg->ip_protocol($value) >>

Type: C<String>

The IP protocol of the packet, e.g. "TCP".

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Cloud::Ids::Logging::V1::ThreatLog::Direction>)

The direction of the packet - an optional field.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

ID of the Layer 4 session of the threat.

=item * C<< $msg->repeat_count() >> / C<< $msg->repeat_count($value) >>

Type: C<String>

Number of sessions with same source IP, destination IP, application, and
type seen within 5 seconds.

=item * C<< $msg->application() >> / C<< $msg->application($value) >>

Type: C<String>

Application associated with the session.

=item * C<< $msg->uri_or_filename() >> / C<< $msg->uri_or_filename($value) >>

Type: C<String>

Variable field. URI or filename of the relevant threat, if applicable.

=item * C<< $msg->cves() >> / C<< $msg->cves($value) >>

Type: C<String>

CVE IDs of the threat.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<String>

Details of the threat reported by the IDS VM

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

The network associated with the IDS Endpoint.

=back

=head3 Enum: ThreatLog::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<LOW> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<HIGH> => C<4>

=item * C<CRITICAL> => C<5>

=item * C<INFORMATIONAL> => C<6>

=back

=head3 Enum: ThreatLog::Direction

=over 4

=item * C<DIRECTION_UNDEFINED> => C<0>

=item * C<CLIENT_TO_SERVER> => C<1>

=item * C<SERVER_TO_CLIENT> => C<2>

=back

=head2 Google::Cloud::Ids::Logging::V1::Logging::TrafficLog

Traffic detected by Cloud IDS.
Fields taken from:
https://docs.paloaltonetworks.com/pan-os/8-1/pan-os-admin/monitoring/use-syslog-for-monitoring/syslog-field-descriptions/traffic-log-fields.html.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time of session start.

=item * C<< $msg->elapsed_time() >> / C<< $msg->elapsed_time($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Elapsed time of the session.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

The network associated with the IDS Endpoint.

=item * C<< $msg->source_ip_address() >> / C<< $msg->source_ip_address($value) >>

Type: C<String>

The source IP Address of the packet, e.g. "35.191.8.79"

=item * C<< $msg->source_port() >> / C<< $msg->source_port($value) >>

Type: C<Int32>

The source port of the packet, e.g. 8080

=item * C<< $msg->destination_ip_address() >> / C<< $msg->destination_ip_address($value) >>

Type: C<String>

The destination IP Address of the packet, e.g. "192.168.100.2"

=item * C<< $msg->destination_port() >> / C<< $msg->destination_port($value) >>

Type: C<Int32>

The destination port of the packet, e.g. 100

=item * C<< $msg->ip_protocol() >> / C<< $msg->ip_protocol($value) >>

Type: C<String>

The IP protocol of the packet, e.g. "TCP".

=item * C<< $msg->application() >> / C<< $msg->application($value) >>

Type: C<String>

Application associated with the session.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

The direction of the packet.

=item * C<< $msg->repeat_count() >> / C<< $msg->repeat_count($value) >>

Type: C<String>

Number of sessions with same source IP, destination IP, application, and
type seen within 5 seconds.

=item * C<< $msg->total_bytes() >> / C<< $msg->total_bytes($value) >>

Type: C<Int64>

Total number of bytes transferred in the session.

=item * C<< $msg->total_packets() >> / C<< $msg->total_packets($value) >>

Type: C<Int64>

Total number of packets transferred in the session.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ids::Logging::V1::Logging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
