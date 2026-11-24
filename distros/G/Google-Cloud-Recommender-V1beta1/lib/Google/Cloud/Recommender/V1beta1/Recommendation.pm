package Google::Cloud::Recommender::V1beta1::Recommendation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Money };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvcmVjb21tZW5kZXIvdjFiZXRhMS9yZWNvbW1lbmRhdGlvbi5wcm90
bxIgZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxYmV0YTEaGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxocZ29vZ2xlL3Byb3Rv
YnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29v
Z2xlL3R5cGUvbW9uZXkucHJvdG8i5goKDlJlY29tbWVuZGF0aW9uEhIKBG5hbWUYASABKAlS
BG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEi8KE3JlY29tbWVuZGVy
X3N1YnR5cGUYDCABKAlSEnJlY29tbWVuZGVyU3VidHlwZRJGChFsYXN0X3JlZnJlc2hfdGlt
ZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD2xhc3RSZWZyZXNoVGltZRJP
Cg5wcmltYXJ5X2ltcGFjdBgFIAEoCzIoLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJl
dGExLkltcGFjdFINcHJpbWFyeUltcGFjdBJVChFhZGRpdGlvbmFsX2ltcGFjdBgGIAMoCzIo
Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLkltcGFjdFIQYWRkaXRpb25hbElt
cGFjdBJVCghwcmlvcml0eRgRIAEoDjI5Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJl
dGExLlJlY29tbWVuZGF0aW9uLlByaW9yaXR5Ughwcmlvcml0eRJRCgdjb250ZW50GAcgASgL
MjcuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxYmV0YTEuUmVjb21tZW5kYXRpb25Db250
ZW50Ugdjb250ZW50ElgKCnN0YXRlX2luZm8YCiABKAsyOS5nb29nbGUuY2xvdWQucmVjb21t
ZW5kZXIudjFiZXRhMS5SZWNvbW1lbmRhdGlvblN0YXRlSW5mb1IJc3RhdGVJbmZvEhIKBGV0
YWcYCyABKAlSBGV0YWcScgoTYXNzb2NpYXRlZF9pbnNpZ2h0cxgOIAMoCzJBLmdvb2dsZS5j
bG91ZC5yZWNvbW1lbmRlci52MWJldGExLlJlY29tbWVuZGF0aW9uLkluc2lnaHRSZWZlcmVu
Y2VSEmFzc29jaWF0ZWRJbnNpZ2h0cxIgCgx4b3JfZ3JvdXBfaWQYEiABKAlSCnhvckdyb3Vw
SWQaLAoQSW5zaWdodFJlZmVyZW5jZRIYCgdpbnNpZ2h0GAEgASgJUgdpbnNpZ2h0IkQKCFBy
aW9yaXR5EhgKFFBSSU9SSVRZX1VOU1BFQ0lGSUVEEAASBgoCUDQQARIGCgJQMxACEgYKAlAy
EAMSBgoCUDEQBDraA+pB1gMKKXJlY29tbWVuZGVyLmdvb2dsZWFwaXMuY29tL1JlY29tbWVu
ZGF0aW9uEmNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVjb21t
ZW5kZXJzL3tyZWNvbW1lbmRlcn0vcmVjb21tZW5kYXRpb25zL3tyZWNvbW1lbmRhdGlvbn0S
cmJpbGxpbmdBY2NvdW50cy97YmlsbGluZ19hY2NvdW50fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9yZWNvbW1lbmRlcnMve3JlY29tbWVuZGVyfS9yZWNvbW1lbmRhdGlvbnMve3JlY29tbWVu
ZGF0aW9ufRJhZm9sZGVycy97Zm9sZGVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZWNvbW1l
bmRlcnMve3JlY29tbWVuZGVyfS9yZWNvbW1lbmRhdGlvbnMve3JlY29tbWVuZGF0aW9ufRJt
b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZWNv
bW1lbmRlcnMve3JlY29tbWVuZGVyfS9yZWNvbW1lbmRhdGlvbnMve3JlY29tbWVuZGF0aW9u
fSKpAQoVUmVjb21tZW5kYXRpb25Db250ZW50ElsKEG9wZXJhdGlvbl9ncm91cHMYAiADKAsy
MC5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMS5PcGVyYXRpb25Hcm91cFIPb3Bl
cmF0aW9uR3JvdXBzEjMKCG92ZXJ2aWV3GAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVj
dFIIb3ZlcnZpZXciXQoOT3BlcmF0aW9uR3JvdXASSwoKb3BlcmF0aW9ucxgBIAMoCzIrLmdv
b2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLk9wZXJhdGlvblIKb3BlcmF0aW9ucyL6
BQoJT3BlcmF0aW9uEhYKBmFjdGlvbhgBIAEoCVIGYWN0aW9uEiMKDXJlc291cmNlX3R5cGUY
AiABKAlSDHJlc291cmNlVHlwZRIaCghyZXNvdXJjZRgDIAEoCVIIcmVzb3VyY2USEgoEcGF0
aBgEIAEoCVIEcGF0aBInCg9zb3VyY2VfcmVzb3VyY2UYBSABKAlSDnNvdXJjZVJlc291cmNl
Eh8KC3NvdXJjZV9wYXRoGAYgASgJUgpzb3VyY2VQYXRoEi4KBXZhbHVlGAcgASgLMhYuZ29v
Z2xlLnByb3RvYnVmLlZhbHVlSABSBXZhbHVlElUKDXZhbHVlX21hdGNoZXIYCiABKAsyLi5n
b29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMS5WYWx1ZU1hdGNoZXJIAFIMdmFsdWVN
YXRjaGVyEl8KDHBhdGhfZmlsdGVycxgIIAMoCzI8Lmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRl
ci52MWJldGExLk9wZXJhdGlvbi5QYXRoRmlsdGVyc0VudHJ5UgtwYXRoRmlsdGVycxJyChNw
YXRoX3ZhbHVlX21hdGNoZXJzGAsgAygLMkIuZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYx
YmV0YTEuT3BlcmF0aW9uLlBhdGhWYWx1ZU1hdGNoZXJzRW50cnlSEXBhdGhWYWx1ZU1hdGNo
ZXJzGlYKEFBhdGhGaWx0ZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLAoFdmFsdWUYAiAB
KAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVSBXZhbHVlOgI4ARp0ChZQYXRoVmFsdWVNYXRj
aGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkQKBXZhbHVlGAIgASgLMi4uZ29vZ2xlLmNs
b3VkLnJlY29tbWVuZGVyLnYxYmV0YTEuVmFsdWVNYXRjaGVyUgV2YWx1ZToCOAFCDAoKcGF0
aF92YWx1ZSJKCgxWYWx1ZU1hdGNoZXISKQoPbWF0Y2hlc19wYXR0ZXJuGAEgASgJSABSDm1h
dGNoZXNQYXR0ZXJuQg8KDW1hdGNoX3ZhcmlhbnQibwoOQ29zdFByb2plY3Rpb24SJgoEY29z
dBgBIAEoCzISLmdvb2dsZS50eXBlLk1vbmV5UgRjb3N0EjUKCGR1cmF0aW9uGAIgASgLMhku
Z29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJhdGlvbiJHChJTZWN1cml0eVByb2plY3Rp
b24SMQoHZGV0YWlscxgCIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSB2RldGFpbHMi
awoYU3VzdGFpbmFiaWxpdHlQcm9qZWN0aW9uEhgKCGtnX2NfbzJlGAEgASgBUgZrZ0NPMmUS
NQoIZHVyYXRpb24YAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCGR1cmF0aW9u
IpwECgZJbXBhY3QSTQoIY2F0ZWdvcnkYASABKA4yMS5nb29nbGUuY2xvdWQucmVjb21tZW5k
ZXIudjFiZXRhMS5JbXBhY3QuQ2F0ZWdvcnlSCGNhdGVnb3J5ElsKD2Nvc3RfcHJvamVjdGlv
bhhkIAEoCzIwLmdvb2dsZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLkNvc3RQcm9qZWN0
aW9uSABSDmNvc3RQcm9qZWN0aW9uEmcKE3NlY3VyaXR5X3Byb2plY3Rpb24YZSABKAsyNC5n
b29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMS5TZWN1cml0eVByb2plY3Rpb25IAFIS
c2VjdXJpdHlQcm9qZWN0aW9uEnkKGXN1c3RhaW5hYmlsaXR5X3Byb2plY3Rpb24YZiABKAsy
Oi5nb29nbGUuY2xvdWQucmVjb21tZW5kZXIudjFiZXRhMS5TdXN0YWluYWJpbGl0eVByb2pl
Y3Rpb25IAFIYc3VzdGFpbmFiaWxpdHlQcm9qZWN0aW9uInQKCENhdGVnb3J5EhgKFENBVEVH
T1JZX1VOU1BFQ0lGSUVEEAASCAoEQ09TVBABEgwKCFNFQ1VSSVRZEAISDwoLUEVSRk9STUFO
Q0UQAxIRCg1NQU5BR0VBQklMSVRZEAQSEgoOU1VTVEFJTkFCSUxJVFkQBUIMCgpwcm9qZWN0
aW9uIooDChdSZWNvbW1lbmRhdGlvblN0YXRlSW5mbxJVCgVzdGF0ZRgBIAEoDjI/Lmdvb2ds
ZS5jbG91ZC5yZWNvbW1lbmRlci52MWJldGExLlJlY29tbWVuZGF0aW9uU3RhdGVJbmZvLlN0
YXRlUgVzdGF0ZRJzCg5zdGF0ZV9tZXRhZGF0YRgCIAMoCzJMLmdvb2dsZS5jbG91ZC5yZWNv
bW1lbmRlci52MWJldGExLlJlY29tbWVuZGF0aW9uU3RhdGVJbmZvLlN0YXRlTWV0YWRhdGFF
bnRyeVINc3RhdGVNZXRhZGF0YRpAChJTdGF0ZU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJhCgVTdGF0ZRIVChFTVEFURV9VTlNQ
RUNJRklFRBAAEgoKBkFDVElWRRABEgsKB0NMQUlNRUQQBhINCglTVUNDRUVERUQQAxIKCgZG
QUlMRUQQBBINCglESVNNSVNTRUQQBSKXAwoPUmVjb21tZW5kZXJUeXBlEhIKBG5hbWUYASAB
KAlSBG5hbWU67wLqQesCCiZyZWNvbW1lbmRlci5nb29nbGVhcGlzLmNvbS9SZWNvbW1lbmRl
chJCcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlY29tbWVuZGVy
cy97cmVjb21tZW5kZXJ9ElFiaWxsaW5nQWNjb3VudHMve2JpbGxpbmdfYWNjb3VudH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vcmVjb21tZW5kZXJzL3tyZWNvbW1lbmRlcn0SQGZvbGRlcnMv
e2ZvbGRlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVjb21tZW5kZXJzL3tyZWNvbW1lbmRl
cn0STG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cmVjb21tZW5kZXJzL3tyZWNvbW1lbmRlcn0SGnJlY29tbWVuZGVycy97cmVjb21tZW5kZXJ9
QpoBCiRjb20uZ29vZ2xlLmNsb3VkLnJlY29tbWVuZGVyLnYxYmV0YTFQAVpGY2xvdWQuZ29v
Z2xlLmNvbS9nby9yZWNvbW1lbmRlci9hcGl2MWJldGExL3JlY29tbWVuZGVycGI7cmVjb21t
ZW5kZXJwYqICBENSRUOqAiBHb29nbGUuQ2xvdWQuUmVjb21tZW5kZXIuVjFCZXRhMUr5ZgoH
EgUOAPECAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJ
CgIDABIDEgAjCgkKAgMBEgMTACgKCQoCAwISAxQAJgoJCgIDAxIDFQApCgkKAgMEEgMWACEK
CAoBCBIDGAA9CgkKAgglEgMYAD0KCAoBCBIDGQBdCgkKAggLEgMZAF0KCAoBCBIDGgAiCgkK
AggKEgMaACIKCAoBCBIDGwA9CgkKAggBEgMbAD0KCAoBCBIDHAAiCgkKAggkEgMcACIKmQEK
AgQAEgQgAHYBGowBIEEgcmVjb21tZW5kYXRpb24gYWxvbmcgd2l0aCBhIHN1Z2dlc3RlZCBh
Y3Rpb24uIEUuZy4sIGEgcmlnaHRzaXppbmcKIHJlY29tbWVuZGF0aW9uIGZvciBhbiB1bmRl
cnV0aWxpemVkIFZNLCBJQU0gcm9sZSByZWNvbW1lbmRhdGlvbnMsIGV0YwoKCgoDBAABEgMg
CBYKCwoDBAAHEgQhAicECg0KBQQAB50IEgQhAicECi8KBAQABAASBCoCOQMaISBSZWNvbW1l
bmRhdGlvbiBwcmlvcml0eSBsZXZlbHMuCgoMCgUEAAQAARIDKgcPCjkKBgQABAACABIDLAQd
GiogUmVjb21tZW5kYXRpb24gaGFzIHVuc3BlY2lmaWVkIHByaW9yaXR5LgoKDgoHBAAEAAIA
ARIDLAQYCg4KBwQABAACAAISAywbHApCCgYEAAQAAgESAy8ECxozIFJlY29tbWVuZGF0aW9u
IGhhcyBQNCBwcmlvcml0eSAobG93ZXN0IHByaW9yaXR5KS4KCg4KBwQABAACAQESAy8EBgoO
CgcEAAQAAgECEgMvCQoKSQoGBAAEAAICEgMyBAsaOiBSZWNvbW1lbmRhdGlvbiBoYXMgUDMg
cHJpb3JpdHkgKHNlY29uZCBsb3dlc3QgcHJpb3JpdHkpLgoKDgoHBAAEAAICARIDMgQGCg4K
BwQABAACAgISAzIJCgpKCgYEAAQAAgMSAzUECxo7IFJlY29tbWVuZGF0aW9uIGhhcyBQMiBw
cmlvcml0eSAoc2Vjb25kIGhpZ2hlc3QgcHJpb3JpdHkpLgoKDgoHBAAEAAIDARIDNQQGCg4K
BwQABAACAwISAzUJCgpDCgYEAAQAAgQSAzgECxo0IFJlY29tbWVuZGF0aW9uIGhhcyBQMSBw
cmlvcml0eSAoaGlnaGVzdCBwcmlvcml0eSkuCgoOCgcEAAQAAgQBEgM4BAYKDgoHBAAEAAIE
AhIDOAkKCjMKBAQAAwASBDwCQAMaJSBSZWZlcmVuY2UgdG8gYW4gYXNzb2NpYXRlZCBpbnNp
Z2h0LgoKDAoFBAADAAESAzwKGgqSAQoGBAADAAIAEgM/BBcaggEgSW5zaWdodCByZXNvdXJj
ZSBuYW1lLCBlLmcuCiBwcm9qZWN0cy9bUFJPSkVDVF9OVU1CRVJdL2xvY2F0aW9ucy9bTE9D
QVRJT05dL2luc2lnaHRUeXBlcy9bSU5TSUdIVF9UWVBFX0lEXS9pbnNpZ2h0cy9bSU5TSUdI
VF9JRF0KCg4KBwQAAwACAAUSAz8ECgoOCgcEAAMAAgABEgM/CxIKDgoHBAADAAIAAxIDPxUW
CiYKBAQAAgASA0MCEhoZIE5hbWUgb2YgcmVjb21tZW5kYXRpb24uCgoMCgUEAAIABRIDQwII
CgwKBQQAAgABEgNDCQ0KDAoFBAACAAMSA0MQEQpiCgQEAAIBEgNHAhkaVSBGcmVlLWZvcm0g
aHVtYW4gcmVhZGFibGUgc3VtbWFyeSBpbiBFbmdsaXNoLiBUaGUgbWF4aW11bSBsZW5ndGgg
aXMgNTAwCiBjaGFyYWN0ZXJzLgoKDAoFBAACAQUSA0cCCAoMCgUEAAIBARIDRwkUCgwKBQQA
AgEDEgNHFxgK5wMKBAQAAgISA1ICIhrZAyBDb250YWlucyBhbiBpZGVudGlmaWVyIGZvciBh
IHN1YnR5cGUgb2YgcmVjb21tZW5kYXRpb25zIHByb2R1Y2VkIGZvciB0aGUKIHNhbWUgcmVj
b21tZW5kZXIuIFN1YnR5cGUgaXMgYSBmdW5jdGlvbiBvZiBjb250ZW50IGFuZCBpbXBhY3Qs
IG1lYW5pbmcgYQogbmV3IHN1YnR5cGUgbWlnaHQgYmUgYWRkZWQgd2hlbiBzaWduaWZpY2Fu
dCBjaGFuZ2VzIHRvIGBjb250ZW50YCBvcgogYHByaW1hcnlfaW1wYWN0LmNhdGVnb3J5YCBh
cmUgaW50cm9kdWNlZC4gU2VlIHRoZSBSZWNvbW1lbmRlcnMgc2VjdGlvbgogdG8gc2VlIGEg
bGlzdCBvZiBzdWJ0eXBlcyBmb3IgYSBnaXZlbiBSZWNvbW1lbmRlci4KCiBFeGFtcGxlczoK
ICAgRm9yIHJlY29tbWVuZGVyID0gImdvb2dsZS5pYW0ucG9saWN5LlJlY29tbWVuZGVyIiwK
ICAgcmVjb21tZW5kZXJfc3VidHlwZSBjYW4gYmUgb25lIG9mICJSRU1PVkVfUk9MRSIvIlJF
UExBQ0VfUk9MRSIKCgwKBQQAAgIFEgNSAggKDAoFBAACAgESA1IJHAoMCgUEAAICAxIDUh8h
Cm0KBAQAAgMSA1YCMhpgIExhc3QgdGltZSB0aGlzIHJlY29tbWVuZGF0aW9uIHdhcyByZWZy
ZXNoZWQgYnkgdGhlIHN5c3RlbSB0aGF0IGNyZWF0ZWQgaXQKIGluIHRoZSBmaXJzdCBwbGFj
ZS4KCgwKBQQAAgMGEgNWAhsKDAoFBAACAwESA1YcLQoMCgUEAAIDAxIDVjAxCm8KBAQAAgQS
A1oCHBpiIFRoZSBwcmltYXJ5IGltcGFjdCB0aGF0IHRoaXMgcmVjb21tZW5kYXRpb24gY2Fu
IGhhdmUgd2hpbGUgdHJ5aW5nIHRvCiBvcHRpbWl6ZSBmb3Igb25lIGNhdGVnb3J5LgoKDAoF
BAACBAYSA1oCCAoMCgUEAAIEARIDWgkXCgwKBQQAAgQDEgNaGhsKqgEKBAQAAgUSA18CKBqc
ASBPcHRpb25hbCBzZXQgb2YgYWRkaXRpb25hbCBpbXBhY3QgdGhhdCB0aGlzIHJlY29tbWVu
ZGF0aW9uIG1heSBoYXZlIHdoZW4KIHRyeWluZyB0byBvcHRpbWl6ZSBmb3IgdGhlIHByaW1h
cnkgY2F0ZWdvcnkuIFRoZXNlIG1heSBiZSBwb3NpdGl2ZQogb3IgbmVnYXRpdmUuCgoMCgUE
AAIFBBIDXwIKCgwKBQQAAgUGEgNfCxEKDAoFBAACBQESA18SIwoMCgUEAAIFAxIDXyYnCikK
BAQAAgYSA2ICGRocIFJlY29tbWVuZGF0aW9uJ3MgcHJpb3JpdHkuCgoMCgUEAAIGBhIDYgIK
CgwKBQQAAgYBEgNiCxMKDAoFBAACBgMSA2IWGApZCgQEAAIHEgNlAiQaTCBDb250ZW50IG9m
IHRoZSByZWNvbW1lbmRhdGlvbiBkZXNjcmliaW5nIHJlY29tbWVuZGVkIGNoYW5nZXMgdG8g
cmVzb3VyY2VzLgoKDAoFBAACBwYSA2UCFwoMCgUEAAIHARIDZRgfCgwKBQQAAgcDEgNlIiMK
QgoEBAACCBIDaAIqGjUgSW5mb3JtYXRpb24gZm9yIHN0YXRlLiBDb250YWlucyBzdGF0ZSBh
bmQgbWV0YWRhdGEuCgoMCgUEAAIIBhIDaAIZCgwKBQQAAggBEgNoGiQKDAoFBAACCAMSA2gn
KQpkCgQEAAIJEgNsAhMaVyBGaW5nZXJwcmludCBvZiB0aGUgUmVjb21tZW5kYXRpb24uIFBy
b3ZpZGVzIG9wdGltaXN0aWMgbG9ja2luZyB3aGVuCiB1cGRhdGluZyBzdGF0ZXMuCgoMCgUE
AAIJBRIDbAIICgwKBQQAAgkBEgNsCQ0KDAoFBAACCQMSA2wQEgo4CgQEAAIKEgNvAjUaKyBJ
bnNpZ2h0cyB0aGF0IGxlZCB0byB0aGlzIHJlY29tbWVuZGF0aW9uLgoKDAoFBAACCgQSA28C
CgoMCgUEAAIKBhIDbwsbCgwKBQQAAgoBEgNvHC8KDAoFBAACCgMSA28yNAqCAgoEBAACCxID
dQIbGvQBIENvcnJlc3BvbmRzIHRvIGEgbXV0dWFsbHkgZXhjbHVzaXZlIGdyb3VwIElEIHdp
dGhpbiBhIHJlY29tbWVuZGVyLgogQSBub24tZW1wdHkgSUQgaW5kaWNhdGVzIHRoYXQgdGhl
IHJlY29tbWVuZGF0aW9uIGJlbG9uZ3MgdG8gYSBtdXR1YWxseQogZXhjbHVzaXZlIGdyb3Vw
LiBUaGlzIG1lYW5zIHRoYXQgb25seSBvbmUgcmVjb21tZW5kYXRpb24gd2l0aGluIHRoZSBn
cm91cAogaXMgc3VnZ2VzdGVkIHRvIGJlIGFwcGxpZWQuCgoMCgUEAAILBRIDdQIICgwKBQQA
AgsBEgN1CRUKDAoFBAACCwMSA3UYGgpOCgIEARIFeQCBAQEaQSBDb250YWlucyB3aGF0IHJl
c291cmNlcyBhcmUgY2hhbmdpbmcgYW5kIGhvdyB0aGV5IGFyZSBjaGFuZ2luZy4KCgoKAwQB
ARIDeQgdCrcBCgQEAQIAEgN9Ai8aqQEgT3BlcmF0aW9ucyB0byBvbmUgb3IgbW9yZSBHb29n
bGUgQ2xvdWQgcmVzb3VyY2VzIGdyb3VwZWQgaW4gc3VjaCBhIHdheQogdGhhdCwgYWxsIG9w
ZXJhdGlvbnMgd2l0aGluIG9uZSBncm91cCBhcmUgZXhwZWN0ZWQgdG8gYmUgcGVyZm9ybWVk
CiBhdG9taWNhbGx5IGFuZCBpbiBhbiBvcmRlci4KCgwKBQQBAgAEEgN9AgoKDAoFBAECAAYS
A30LGQoMCgUEAQIAARIDfRoqCgwKBQQBAgADEgN9LS4KSAoEBAECARIEgAECJho6IENvbmRl
bnNlZCBvdmVydmlldyBpbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVjb21tZW5kYXRpb24uCgoN
CgUEAQIBBhIEgAECGAoNCgUEAQIBARIEgAEZIQoNCgUEAQIBAxIEgAEkJQpJCgIEAhIGhAEA
iAEBGjsgR3JvdXAgb2Ygb3BlcmF0aW9ucyB0aGF0IG5lZWQgdG8gYmUgcGVyZm9ybWVkIGF0
b21pY2FsbHkuCgoLCgMEAgESBIQBCBYKpwEKBAQCAgASBIcBAiQamAEgTGlzdCBvZiBvcGVy
YXRpb25zIGFjcm9zcyBvbmUgb3IgbW9yZSByZXNvdXJjZXMgdGhhdCBiZWxvbmcgdG8gdGhp
cyBncm91cC4KIExvb3NlbHkgYmFzZWQgb24gUkZDNjkwMiBhbmQgc2hvdWxkIGJlIHBlcmZv
cm1lZCBpbiB0aGUgb3JkZXIgdGhleSBhcHBlYXIuCgoNCgUEAgIABBIEhwECCgoNCgUEAgIA
BhIEhwELFAoNCgUEAgIAARIEhwEVHwoNCgUEAgIAAxIEhwEiIwrOAwoCBAMSBpMBAOMBARq/
AyBDb250YWlucyBhbiBvcGVyYXRpb24gZm9yIGEgcmVzb3VyY2UgbG9vc2VseSBiYXNlZCBv
biB0aGUgSlNPTi1QQVRDSCBmb3JtYXQKIHdpdGggc3VwcG9ydCBmb3I6CgogKiBDdXN0b20g
ZmlsdGVycyBmb3IgZGVzY3JpYmluZyBwYXJ0aWFsIGFycmF5IHBhdGNoLgogKiBFeHRlbmRl
ZCBwYXRoIHZhbHVlcyBmb3IgZGVzY3JpYmluZyBuZXN0ZWQgYXJyYXlzLgogKiBDdXN0b20g
ZmllbGRzIGZvciBkZXNjcmliaW5nIHRoZSByZXNvdXJjZSBmb3Igd2hpY2ggdGhlIG9wZXJh
dGlvbiBpcyBiZWluZwogICBkZXNjcmliZWQuCiAqIEFsbG93cyBleHRlbnNpb24gdG8gY3Vz
dG9tIG9wZXJhdGlvbnMgbm90IG5hdGl2ZWx5IHN1cHBvcnRlZCBieSBSRkM2OTAyLgogU2Vl
IGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmM2OTAyIGZvciBkZXRhaWxzIG9uIHRo
ZSBvcmlnaW5hbCBSRkMuCgoLCgMEAwESBJMBCBEKuwEKBAQDAgASBJcBAhQarAEgVHlwZSBv
ZiB0aGlzIG9wZXJhdGlvbi4gQ29udGFpbnMgb25lIG9mICdhZGQnLCAncmVtb3ZlJywgJ3Jl
cGxhY2UnLCAnbW92ZScsCiAnY29weScsICd0ZXN0JyBhbmQgJ2N1c3RvbScgb3BlcmF0aW9u
cy4gVGhpcyBmaWVsZCBpcyBjYXNlLWluc2Vuc2l0aXZlIGFuZAogYWx3YXlzIHBvcHVsYXRl
ZC4KCg0KBQQDAgAFEgSXAQIICg0KBQQDAgABEgSXAQkPCg0KBQQDAgADEgSXARITCrQBCgQE
AwIBEgScAQIbGqUBIFR5cGUgb2YgR0NQIHJlc291cmNlIGJlaW5nIG1vZGlmaWVkL3Rlc3Rl
ZC4gVGhpcyBmaWVsZCBpcyBhbHdheXMgcG9wdWxhdGVkLgogRXhhbXBsZTogY2xvdWRyZXNv
dXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdCwKIGNvbXB1dGUuZ29vZ2xlYXBp
cy5jb20vSW5zdGFuY2UKCg0KBQQDAgEFEgScAQIICg0KBQQDAgEBEgScAQkWCg0KBQQDAgED
EgScARkaCpUBCgQEAwICEgSgAQIWGoYBIENvbnRhaW5zIHRoZSBmdWxseSBxdWFsaWZpZWQg
cmVzb3VyY2UgbmFtZS4gVGhpcyBmaWVsZCBpcyBhbHdheXMgcG9wdWxhdGVkLgogZXg6IC8v
Y2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMvZm9vLgoKDQoF
BAMCAgUSBKABAggKDQoFBAMCAgESBKABCREKDQoFBAMCAgMSBKABFBUKoQEKBAQDAgMSBKQB
AhIakgEgUGF0aCB0byB0aGUgdGFyZ2V0IGZpZWxkIGJlaW5nIG9wZXJhdGVkIG9uLiBJZiB0
aGUgb3BlcmF0aW9uIGlzIGF0IHRoZQogcmVzb3VyY2UgbGV2ZWwsIHRoZW4gcGF0aCBzaG91
bGQgYmUgIi8iLiBUaGlzIGZpZWxkIGlzIGFsd2F5cyBwb3B1bGF0ZWQuCgoNCgUEAwIDBRIE
pAECCAoNCgUEAwIDARIEpAEJDQoNCgUEAwIDAxIEpAEQEQrAAgoEBAMCBBIEqwECHRqxAiBD
YW4gYmUgc2V0IHdpdGggYWN0aW9uICdjb3B5JyB0byBjb3B5IHJlc291cmNlIGNvbmZpZ3Vy
YXRpb24gYWNyb3NzCiBkaWZmZXJlbnQgcmVzb3VyY2VzIG9mIHRoZSBzYW1lIHR5cGUuIEV4
YW1wbGU6IEEgcmVzb3VyY2UgY2xvbmUgY2FuIGJlCiBkb25lIHZpYSBhY3Rpb24gPSAnY29w
eScsIHBhdGggPSAiLyIsIGZyb20gPSAiLyIsCiBzb3VyY2VfcmVzb3VyY2UgPSA8c291cmNl
PiBhbmQgcmVzb3VyY2VfbmFtZSA9IDx0YXJnZXQ+LgogVGhpcyBmaWVsZCBpcyBlbXB0eSBm
b3IgYWxsIG90aGVyIHZhbHVlcyBvZiBgYWN0aW9uYC4KCg0KBQQDAgQFEgSrAQIICg0KBQQD
AgQBEgSrAQkYCg0KBQQDAgQDEgSrARscCqkBCgQEAwIFEgSvAQIZGpoBIENhbiBiZSBzZXQg
d2l0aCBhY3Rpb24gJ2NvcHknIG9yICdtb3ZlJyB0byBpbmRpY2F0ZSB0aGUgc291cmNlIGZp
ZWxkIHdpdGhpbgogcmVzb3VyY2Ugb3Igc291cmNlX3Jlc291cmNlLCBpZ25vcmVkIGlmIHBy
b3ZpZGVkIGZvciBvdGhlciBvcGVyYXRpb24gdHlwZXMuCgoNCgUEAwIFBRIErwECCAoNCgUE
AwIFARIErwEJFAoNCgUEAwIFAxIErwEXGAp4CgQEAwgAEgazAQK8AQMaaCBPbmUgb2YgdGhl
IGZpZWxkcyBpbiB0aGUgZm9sbG93aW5nIGJsb2NrIHdpbGwgYmUgc2V0IGFuZCBpbnRlbmQg
dG8KIGRlc2NyaWJlIGEgdmFsdWUgZm9yICdwYXRoJyBmaWVsZC4KCg0KBQQDCAABEgSzAQgS
CtgBCgQEAwIGEgS3AQQkGskBIFZhbHVlIGZvciB0aGUgYHBhdGhgIGZpZWxkLiBXaWxsIGJl
IHNldCBmb3IgYWN0aW9uczonYWRkJy8ncmVwbGFjZScuCiBNYXliZSBzZXQgZm9yIGFjdGlv
bjogJ3Rlc3QnLiBFaXRoZXIgdGhpcyBvciBgdmFsdWVfbWF0Y2hlcmAgd2lsbCBiZSBzZXQK
IGZvciAndGVzdCcgb3BlcmF0aW9uLiBBbiBleGFjdCBtYXRjaCBtdXN0IGJlIHBlcmZvcm1l
ZC4KCg0KBQQDAgYGEgS3AQQZCg0KBQQDAgYBEgS3ARofCg0KBQQDAgYDEgS3ASIjCpwBCgQE
AwIHEgS7AQQkGo0BIENhbiBiZSBzZXQgZm9yIGFjdGlvbiAndGVzdCcgZm9yIGFkdmFuY2Vk
IG1hdGNoaW5nIGZvciB0aGUgdmFsdWUgb2YKICdwYXRoJyBmaWVsZC4gRWl0aGVyIHRoaXMg
b3IgYHZhbHVlYCB3aWxsIGJlIHNldCBmb3IgJ3Rlc3QnIG9wZXJhdGlvbi4KCg0KBQQDAgcG
EgS7AQQQCg0KBQQDAgcBEgS7AREeCg0KBQQDAgcDEgS7ASEjCsoFCgQEAwIIEgTbAQI2GrsF
IFNldCBvZiBmaWx0ZXJzIHRvIGFwcGx5IGlmIGBwYXRoYCByZWZlcnMgdG8gYXJyYXkgZWxl
bWVudHMgb3IgbmVzdGVkIGFycmF5CiBlbGVtZW50cyBpbiBvcmRlciB0byBuYXJyb3cgZG93
biB0byBhIHNpbmdsZSB1bmlxdWUgZWxlbWVudCB0aGF0IGlzIGJlaW5nCiB0ZXN0ZWQvbW9k
aWZpZWQuCiBUaGlzIGlzIGludGVuZGVkIHRvIGJlIGFuIGV4YWN0IG1hdGNoIHBlciBmaWx0
ZXIuIFRvIHBlcmZvcm0gYWR2YW5jZWQKIG1hdGNoaW5nLCB1c2UgcGF0aF92YWx1ZV9tYXRj
aGVycy4KCiAqIEV4YW1wbGU6CiBgYGAKIHsKICAgIi92ZXJzaW9ucy8qL25hbWUiIDogIml0
LTEyMyIKICAgIi92ZXJzaW9ucy8qL3RhcmdldFNpemUvcGVyY2VudCI6IDIwCiB9CiBgYGAK
ICogRXhhbXBsZToKIGBgYAogewogICAiL2JpbmRpbmdzLyovcm9sZSI6ICJyb2xlcy9vd25l
ciIKICAgIi9iaW5kaW5ncy8qL2NvbmRpdGlvbiIgOiBudWxsCiB9CiBgYGAKICogRXhhbXBs
ZToKIGBgYAogewogICAiL2JpbmRpbmdzLyovcm9sZSI6ICJyb2xlcy9vd25lciIKICAgIi9i
aW5kaW5ncy8qL21lbWJlcnMvKiIgOiBbInhAZXhhbXBsZS5jb20iLCAieUBleGFtcGxlLmNv
bSJdCiB9CiBgYGAKIFdoZW4gYm90aCBwYXRoX2ZpbHRlcnMgYW5kIHBhdGhfdmFsdWVfbWF0
Y2hlcnMgYXJlIHNldCwgYW4gaW1wbGljaXQgQU5ECiBtdXN0IGJlIHBlcmZvcm1lZC4KCg0K
BQQDAggGEgTbAQIkCg0KBQQDAggBEgTbASUxCg0KBQQDAggDEgTbATQ1Cr4CCgQEAwIJEgTi
AQI1Gq8CIFNpbWlsYXIgdG8gcGF0aF9maWx0ZXJzLCB0aGlzIGNvbnRhaW5zIHNldCBvZiBm
aWx0ZXJzIHRvIGFwcGx5IGlmIGBwYXRoYAogZmllbGQgcmVmZXJzIHRvIGFycmF5IGVsZW1l
bnRzLiBUaGlzIGlzIG1lYW50IHRvIHN1cHBvcnQgdmFsdWUgbWF0Y2hpbmcKIGJleW9uZCBl
eGFjdCBtYXRjaC4gVG8gcGVyZm9ybSBleGFjdCBtYXRjaCwgdXNlIHBhdGhfZmlsdGVycy4K
IFdoZW4gYm90aCBwYXRoX2ZpbHRlcnMgYW5kIHBhdGhfdmFsdWVfbWF0Y2hlcnMgYXJlIHNl
dCwgYW4gaW1wbGljaXQgQU5ECiBtdXN0IGJlIHBlcmZvcm1lZC4KCg0KBQQDAgkGEgTiAQIb
Cg0KBQQDAgkBEgTiARwvCg0KBQQDAgkDEgTiATI0ClYKAgQEEgbmAQDtAQEaSCBDb250YWlu
cyB2YXJpb3VzIG1hdGNoaW5nIG9wdGlvbnMgZm9yIHZhbHVlcyBmb3IgYSBHQ1AgcmVzb3Vy
Y2UgZmllbGQuCgoLCgMEBAESBOYBCBQKDgoEBAQIABIG5wEC7AEDCg0KBQQECAABEgTnAQgV
CrsBCgQEBAIAEgTrAQQfGqwBIFRvIGJlIHVzZWQgZm9yIGZ1bGwgcmVnZXggbWF0Y2hpbmcu
IFRoZSByZWd1bGFyIGV4cHJlc3Npb24gaXMgdXNpbmcgdGhlCiBHb29nbGUgUkUyIHN5bnRh
eCAoaHR0cHM6Ly9naXRodWIuY29tL2dvb2dsZS9yZTIvd2lraS9TeW50YXgpLCBzbyB0byBi
ZQogdXNlZCB3aXRoIFJFMjo6RnVsbE1hdGNoCgoNCgUEBAIABRIE6wEECgoNCgUEBAIAARIE
6wELGgoNCgUEBAIAAxIE6wEdHgpaCgIEBRIG8AEA+wEBGkwgQ29udGFpbnMgbWV0YWRhdGEg
YWJvdXQgaG93IG11Y2ggbW9uZXkgYSByZWNvbW1lbmRhdGlvbiBjYW4gc2F2ZSBvciBpbmN1
ci4KCgsKAwQFARIE8AEIFgrTAgoEBAUCABIE9wECHRrEAiBBbiBhcHByb3hpbWF0ZSBwcm9q
ZWN0aW9uIG9uIGFtb3VudCBzYXZlZCBvciBhbW91bnQgaW5jdXJyZWQuIE5lZ2F0aXZlIGNv
c3QKIHVuaXRzIGluZGljYXRlIGNvc3Qgc2F2aW5ncyBhbmQgcG9zaXRpdmUgY29zdCB1bml0
cyBpbmRpY2F0ZSBpbmNyZWFzZS4KIFNlZSBnb29nbGUudHlwZS5Nb25leSBkb2N1bWVudGF0
aW9uIGZvciBwb3NpdGl2ZS9uZWdhdGl2ZSB1bml0cy4KCiBBIHVzZXIncyBwZXJtaXNzaW9u
cyBtYXkgYWZmZWN0IHdoZXRoZXIgdGhlIGNvc3QgaXMgY29tcHV0ZWQgdXNpbmcgbGlzdAog
cHJpY2VzIG9yIGN1c3RvbSBjb250cmFjdCBwcmljZXMuCgoNCgUEBQIABhIE9wECEwoNCgUE
BQIAARIE9wEUGAoNCgUEBQIAAxIE9wEbHAo1CgQEBQIBEgT6AQIoGicgRHVyYXRpb24gZm9y
IHdoaWNoIHRoaXMgY29zdCBhcHBsaWVzLgoKDQoFBAUCAQYSBPoBAhoKDQoFBAUCAQESBPoB
GyMKDQoFBAUCAQMSBPoBJicKSwoCBAYSBv4BAIICARo9IENvbnRhaW5zIHZhcmlvdXMgd2F5
cyBvZiBkZXNjcmliaW5nIHRoZSBpbXBhY3Qgb24gU2VjdXJpdHkuCgoLCgMEBgESBP4BCBoK
aQoEBAYCABIEgQICJRpbIFRoaXMgZmllbGQgY2FuIGJlIHVzZWQgYnkgdGhlIHJlY29tbWVu
ZGVyIHRvIGRlZmluZSBkZXRhaWxzIHNwZWNpZmljIHRvCiBzZWN1cml0eSBpbXBhY3QuCgoN
CgUEBgIABhIEgQICGAoNCgUEBgIAARIEgQIZIAoNCgUEBgIAAxIEgQIjJApkCgIEBxIGhgIA
jQIBGlYgQ29udGFpbnMgbWV0YWRhdGEgYWJvdXQgaG93IG11Y2ggc3VzdGFpbmFiaWxpdHkg
YSByZWNvbW1lbmRhdGlvbiBjYW4gc2F2ZSBvcgogaW5jdXIuCgoLCgMEBwESBIYCCCAKjQEK
BAQHAgASBIkCAhYafyBDYXJib24gRm9vdHByaW50IGdlbmVyYXRlZCBpbiBrZyBvZiBDTzIg
ZXF1aXZhbGVudC4KIENob3NlIGtnX2NfbzJlIHNvIHRoYXQgdGhlIG5hbWUgcmVuZGVycyBj
b3JyZWN0bHkgaW4gY2FtZWxDYXNlIChrZ0NPMmUpLgoKDQoFBAcCAAUSBIkCAggKDQoFBAcC
AAESBIkCCREKDQoFBAcCAAMSBIkCFBUKPgoEBAcCARIEjAICKBowIER1cmF0aW9uIGZvciB3
aGljaCB0aGlzIHN1c3RhbmFiaWxpdHkgYXBwbGllcy4KCg0KBQQHAgEGEgSMAgIaCg0KBQQH
AgEBEgSMAhsjCg0KBQQHAgEDEgSMAiYnClMKAgQIEgaQAgC0AgEaRSBDb250YWlucyB0aGUg
aW1wYWN0IGEgcmVjb21tZW5kYXRpb24gY2FuIGhhdmUgZm9yIGEgZ2l2ZW4gY2F0ZWdvcnku
CgoLCgMECAESBJACCA4KLQoEBAgEABIGkgICpAIDGh0gVGhlIGNhdGVnb3J5IG9mIHRoZSBp
bXBhY3QuCgoNCgUECAQAARIEkgIHDwpDCgYECAQAAgASBJQCBB0aMyBEZWZhdWx0IHVuc3Bl
Y2lmaWVkIGNhdGVnb3J5LiBEb24ndCB1c2UgZGlyZWN0bHkuCgoPCgcECAQAAgABEgSUAgQY
Cg8KBwQIBAACAAISBJQCGxwKRQoGBAgEAAIBEgSXAgQNGjUgSW5kaWNhdGVzIGEgcG90ZW50
aWFsIGluY3JlYXNlIG9yIGRlY3JlYXNlIGluIGNvc3QuCgoPCgcECAQAAgEBEgSXAgQICg8K
BwQIBAACAQISBJcCCwwKSQoGBAgEAAICEgSaAgQRGjkgSW5kaWNhdGVzIGEgcG90ZW50aWFs
IGluY3JlYXNlIG9yIGRlY3JlYXNlIGluIHNlY3VyaXR5LgoKDwoHBAgEAAICARIEmgIEDAoP
CgcECAQAAgICEgSaAg8QCkwKBgQIBAACAxIEnQIEFBo8IEluZGljYXRlcyBhIHBvdGVudGlh
bCBpbmNyZWFzZSBvciBkZWNyZWFzZSBpbiBwZXJmb3JtYW5jZS4KCg8KBwQIBAACAwESBJ0C
BA8KDwoHBAgEAAIDAhIEnQISEwpOCgYECAQAAgQSBKACBBYaPiBJbmRpY2F0ZXMgYSBwb3Rl
bnRpYWwgaW5jcmVhc2Ugb3IgZGVjcmVhc2UgaW4gbWFuYWdlYWJpbGl0eS4KCg8KBwQIBAAC
BAESBKACBBEKDwoHBAgEAAIEAhIEoAIUFQpPCgYECAQAAgUSBKMCBBcaPyBJbmRpY2F0ZXMg
YSBwb3RlbnRpYWwgaW5jcmVhc2Ugb3IgZGVjcmVhc2UgaW4gc3VzdGFpbmFiaWxpdHkuCgoP
CgcECAQAAgUBEgSjAgQSCg8KBwQIBAACBQISBKMCFRYKMAoEBAgCABIEpwICGBoiIENhdGVn
b3J5IHRoYXQgaXMgYmVpbmcgdGFyZ2V0ZWQuCgoNCgUECAIABhIEpwICCgoNCgUECAIAARIE
pwILEwoNCgUECAIAAxIEpwIWFwpCCgQECAgAEgaqAgKzAgMaMiBDb250YWlucyBwcm9qZWN0
aW9ucyAoaWYgYW55KSBmb3IgdGhpcyBjYXRlZ29yeS4KCg0KBQQICAABEgSqAggSCioKBAQI
AgESBKwCBCkaHCBVc2Ugd2l0aCBDYXRlZ29yeVR5cGUuQ09TVAoKDQoFBAgCAQYSBKwCBBIK
DQoFBAgCAQESBKwCEyIKDQoFBAgCAQMSBKwCJSgKLgoEBAgCAhIErwIEMRogIFVzZSB3aXRo
IENhdGVnb3J5VHlwZS5TRUNVUklUWQoKDQoFBAgCAgYSBK8CBBYKDQoFBAgCAgESBK8CFyoK
DQoFBAgCAgMSBK8CLTAKNAoEBAgCAxIEsgIEPRomIFVzZSB3aXRoIENhdGVnb3J5VHlwZS5T
VVNUQUlOQUJJTElUWQoKDQoFBAgCAwYSBLICBBwKDQoFBAgCAwESBLICHTYKDQoFBAgCAwMS
BLICOTwKQwoCBAkSBrcCAOECARo1IEluZm9ybWF0aW9uIGZvciBzdGF0ZS4gQ29udGFpbnMg
c3RhdGUgYW5kIG1ldGFkYXRhLgoKCwoDBAkBEgS3AggfCjIKBAQJBAASBrkCAtoCAxoiIFJl
cHJlc2VudHMgUmVjb21tZW5kYXRpb24gU3RhdGUuCgoNCgUECQQAARIEuQIHDAo0CgYECQQA
AgASBLsCBBoaJCBEZWZhdWx0IHN0YXRlLiBEb24ndCB1c2UgZGlyZWN0bHkuCgoPCgcECQQA
AgABEgS7AgQVCg8KBwQJBAACAAISBLsCGBkKuwEKBgQJBAACARIEwQIEDxqqASBSZWNvbW1l
bmRhdGlvbiBpcyBhY3RpdmUgYW5kIGNhbiBiZSBhcHBsaWVkLiBSZWNvbW1lbmRhdGlvbnMg
Y29udGVudCBjYW4KIGJlIHVwZGF0ZWQgYnkgR29vZ2xlLgoKIEFDVElWRSByZWNvbW1lbmRh
dGlvbnMgY2FuIGJlIG1hcmtlZCBhcyBDTEFJTUVELCBTVUNDRUVERUQsIG9yIEZBSUxFRC4K
Cg8KBwQJBAACAQESBMECBAoKDwoHBAkEAAIBAhIEwQINDgrHAQoGBAkEAAICEgTHAgQQGrYB
IFJlY29tbWVuZGF0aW9uIGlzIGluIGNsYWltZWQgc3RhdGUuIFJlY29tbWVuZGF0aW9ucyBj
b250ZW50IGlzCiBpbW11dGFibGUgYW5kIGNhbm5vdCBiZSB1cGRhdGVkIGJ5IEdvb2dsZS4K
CiBDTEFJTUVEIHJlY29tbWVuZGF0aW9ucyBjYW4gYmUgbWFya2VkIGFzIENMQUlNRUQsIFNV
Q0NFRURFRCwgb3IgRkFJTEVELgoKDwoHBAkEAAICARIExwIECwoPCgcECQQAAgICEgTHAg4P
CsIBCgYECQQAAgMSBM0CBBIasQEgUmVjb21tZW5kYXRpb24gaXMgaW4gc3VjY2VlZGVkIHN0
YXRlLiBSZWNvbW1lbmRhdGlvbnMgY29udGVudCBpcwogaW1tdXRhYmxlIGFuZCBjYW5ub3Qg
YmUgdXBkYXRlZCBieSBHb29nbGUuCgogU1VDQ0VFREVEIHJlY29tbWVuZGF0aW9ucyBjYW4g
YmUgbWFya2VkIGFzIFNVQ0NFRURFRCwgb3IgRkFJTEVELgoKDwoHBAkEAAIDARIEzQIEDQoP
CgcECQQAAgMCEgTNAhARCrwBCgYECQQAAgQSBNMCBA8aqwEgUmVjb21tZW5kYXRpb24gaXMg
aW4gZmFpbGVkIHN0YXRlLiBSZWNvbW1lbmRhdGlvbnMgY29udGVudCBpcyBpbW11dGFibGUK
IGFuZCBjYW5ub3QgYmUgdXBkYXRlZCBieSBHb29nbGUuCgogRkFJTEVEIHJlY29tbWVuZGF0
aW9ucyBjYW4gYmUgbWFya2VkIGFzIFNVQ0NFRURFRCwgb3IgRkFJTEVELgoKDwoHBAkEAAIE
ARIE0wIECgoPCgcECQQAAgQCEgTTAg0OCp8BCgYECQQAAgUSBNkCBBIajgEgUmVjb21tZW5k
YXRpb24gaXMgaW4gZGlzbWlzc2VkIHN0YXRlLiBSZWNvbW1lbmRhdGlvbiBjb250ZW50IGNh
biBiZQogdXBkYXRlZCBieSBHb29nbGUuCgogRElTTUlTU0VEIHJlY29tbWVuZGF0aW9ucyBj
YW4gYmUgbWFya2VkIGFzIEFDVElWRS4KCg8KBwQJBAACBQESBNkCBA0KDwoHBAkEAAIFAhIE
2QIQEQpOCgQECQIAEgTdAgISGkAgVGhlIHN0YXRlIG9mIHRoZSByZWNvbW1lbmRhdGlvbiwg
RWcgQUNUSVZFLCBTVUNDRUVERUQsIEZBSUxFRC4KCg0KBQQJAgAGEgTdAgIHCg0KBQQJAgAB
EgTdAggNCg0KBQQJAgADEgTdAhARClkKBAQJAgESBOACAikaSyBBIG1hcCBvZiBtZXRhZGF0
YSBmb3IgdGhlIHN0YXRlLCBwcm92aWRlZCBieSB1c2VyIG9yIGF1dG9tYXRpb25zIHN5c3Rl
bXMuCgoNCgUECQIBBhIE4AICFQoNCgUECQIBARIE4AIWJAoNCgUECQIBAxIE4AInKAoqCgIE
ChIG5AIA8QIBGhwgVGhlIHR5cGUgb2YgYSByZWNvbW1lbmRlci4KCgsKAwQKARIE5AIIFwoN
CgMECgcSBuUCAuwCBAoPCgUECgedCBIG5QIC7AIECokBCgQECgIAEgTwAgISGnsgVGhlIHJl
Y29tbWVuZGVyJ3MgbmFtZSBpbiBmb3JtYXQgUmVjb21tZW5kZXJUeXBlcy97cmVjb21tZW5k
ZXJfdHlwZX0KIGVnOiAgcmVjb21tZW5kZXJUeXBlcy9nb29nbGUuaWFtLnBvbGljeS5SZWNv
bW1lbmRlcgoKDQoFBAoCAAUSBPACAggKDQoFBAoCAAESBPACCQ0KDQoFBAoCAAMSBPACEBFi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation ===
    # Fields for Recommendation
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: recommender_subtype Type: 9 ()
    # Field: last_refresh_time Type: 11 (.google.protobuf.Timestamp)
    # Field: primary_impact Type: 11 (.google.cloud.recommender.v1beta1.Impact)
    # Field: additional_impact Type: 11 (.google.cloud.recommender.v1beta1.Impact)
    # Field: priority Type: 14 (.google.cloud.recommender.v1beta1.Recommendation.Priority)
    # Field: content Type: 11 (.google.cloud.recommender.v1beta1.RecommendationContent)
    # Field: state_info Type: 11 (.google.cloud.recommender.v1beta1.RecommendationStateInfo)
    # Field: etag Type: 9 ()
    # Field: associated_insights Type: 11 (.google.cloud.recommender.v1beta1.Recommendation.InsightReference)
    # Field: xor_group_id Type: 9 ()

# Enum: Recommendation::Priority
our $Recommendation_PRIORITY_UNSPECIFIED = 0;
our $Recommendation_P4 = 1;
our $Recommendation_P3 = 2;
our $Recommendation_P2 = 3;
our $Recommendation_P1 = 4;

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationContent ===
    # Fields for RecommendationContent
    # Field: operation_groups Type: 11 (.google.cloud.recommender.v1beta1.OperationGroup)
    # Field: overview Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::OperationGroup ===
    # Fields for OperationGroup
    # Field: operations Type: 11 (.google.cloud.recommender.v1beta1.Operation)

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::Operation ===
    # Fields for Operation
    # Field: action Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: path Type: 9 ()
    # Field: source_resource Type: 9 ()
    # Field: source_path Type: 9 ()
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: value_matcher Type: 11 (.google.cloud.recommender.v1beta1.ValueMatcher)
    # Field: path_filters Type: 11 (.google.cloud.recommender.v1beta1.Operation.PathFiltersEntry)
    # Field: path_value_matchers Type: 11 (.google.cloud.recommender.v1beta1.Operation.PathValueMatchersEntry)

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::ValueMatcher ===
    # Fields for ValueMatcher
    # Field: matches_pattern Type: 9 ()

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::CostProjection ===
    # Fields for CostProjection
    # Field: cost Type: 11 (.google.type.Money)
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::SecurityProjection ===
    # Fields for SecurityProjection
    # Field: details Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::SustainabilityProjection ===
    # Fields for SustainabilityProjection
    # Field: kg_c_o2e Type: 1 ()
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::Impact ===
    # Fields for Impact
    # Field: category Type: 14 (.google.cloud.recommender.v1beta1.Impact.Category)
    # Field: cost_projection Type: 11 (.google.cloud.recommender.v1beta1.CostProjection)
    # Field: security_projection Type: 11 (.google.cloud.recommender.v1beta1.SecurityProjection)
    # Field: sustainability_projection Type: 11 (.google.cloud.recommender.v1beta1.SustainabilityProjection)

# Enum: Impact::Category
our $Impact_CATEGORY_UNSPECIFIED = 0;
our $Impact_COST = 1;
our $Impact_SECURITY = 2;
our $Impact_PERFORMANCE = 3;
our $Impact_MANAGEABILITY = 4;
our $Impact_SUSTAINABILITY = 5;

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo ===
    # Fields for RecommendationStateInfo
    # Field: state Type: 14 (.google.cloud.recommender.v1beta1.RecommendationStateInfo.State)
    # Field: state_metadata Type: 11 (.google.cloud.recommender.v1beta1.RecommendationStateInfo.StateMetadataEntry)

# Enum: RecommendationStateInfo::State
our $RecommendationStateInfo_STATE_UNSPECIFIED = 0;
our $RecommendationStateInfo_ACTIVE = 1;
our $RecommendationStateInfo_CLAIMED = 6;
our $RecommendationStateInfo_SUCCEEDED = 3;
our $RecommendationStateInfo_FAILED = 4;
our $RecommendationStateInfo_DISMISSED = 5;

# === Message: Google::Cloud::Recommender::V1beta1::Recommendation::RecommenderType ===
    # Fields for RecommenderType
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Recommender::V1beta1::Recommendation - Compiled Protocol Buffers messages for google/cloud/recommender/v1beta1/recommendation.proto

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1beta1::Recommendation;

    my $msg = Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation->new({
        name => $name,
        description => $description,
        recommender_subtype => $recommender_subtype,
        last_refresh_time => $last_refresh_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/recommender/v1beta1/recommendation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation

A recommendation along with a suggested action. E.g., a rightsizing
recommendation for an underutilized VM, IAM role recommendations, etc

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of recommendation.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Free-form human readable summary in English. The maximum length is 500
characters.

=item * C<< $msg->recommender_subtype() >> / C<< $msg->recommender_subtype($value) >>

Type: C<String>

Contains an identifier for a subtype of recommendations produced for the
same recommender. Subtype is a function of content and impact, meaning a
new subtype might be added when significant changes to `content` or
`primary_impact.category` are introduced. See the Recommenders section
to see a list of subtypes for a given Recommender.

Examples:
  For recommender = "google.iam.policy.Recommender",
  recommender_subtype can be one of "REMOVE_ROLE"/"REPLACE_ROLE"

=item * C<< $msg->last_refresh_time() >> / C<< $msg->last_refresh_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Last time this recommendation was refreshed by the system that created it
in the first place.

=item * C<< $msg->primary_impact() >> / C<< $msg->primary_impact($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Impact>)

The primary impact that this recommendation can have while trying to
optimize for one category.

=item * C<< $msg->additional_impact() >> / C<< $msg->additional_impact($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Impact>)

Optional set of additional impact that this recommendation may have when
trying to optimize for the primary category. These may be positive
or negative.

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Priority>)

Recommendation's priority.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationContent>)

Content of the recommendation describing recommended changes to resources.

=item * C<< $msg->state_info() >> / C<< $msg->state_info($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo>)

Information for state. Contains state and metadata.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Fingerprint of the Recommendation. Provides optimistic locking when
updating states.

=item * C<< $msg->associated_insights() >> / C<< $msg->associated_insights($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation::InsightReference>)

Insights that led to this recommendation.

=item * C<< $msg->xor_group_id() >> / C<< $msg->xor_group_id($value) >>

Type: C<String>

Corresponds to a mutually exclusive group ID within a recommender.
A non-empty ID indicates that the recommendation belongs to a mutually
exclusive group. This means that only one recommendation within the group
is suggested to be applied.

=back

=head3 Enum: Recommendation::Priority

=over 4

=item * C<PRIORITY_UNSPECIFIED> => C<0>

=item * C<P4> => C<1>

=item * C<P3> => C<2>

=item * C<P2> => C<3>

=item * C<P1> => C<4>

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationContent

Contains what resources are changing and how they are changing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_groups() >> / C<< $msg->operation_groups($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::OperationGroup>)

Operations to one or more Google Cloud resources grouped in such a way
that, all operations within one group are expected to be performed
atomically and in an order.

=item * C<< $msg->overview() >> / C<< $msg->overview($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Condensed overview information about the recommendation.

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::OperationGroup

Group of operations that need to be performed atomically.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operations() >> / C<< $msg->operations($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Operation>)

List of operations across one or more resources that belong to this group.
Loosely based on RFC6902 and should be performed in the order they appear.

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::Operation

Contains an operation for a resource loosely based on the JSON-PATCH format
with support for:

* Custom filters for describing partial array patch.
* Extended path values for describing nested arrays.
* Custom fields for describing the resource for which the operation is being
  described.
* Allows extension to custom operations not natively supported by RFC6902.
See https://tools.ietf.org/html/rfc6902 for details on the original RFC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Type of this operation. Contains one of 'add', 'remove', 'replace', 'move',
'copy', 'test' and 'custom' operations. This field is case-insensitive and
always populated.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Type of GCP resource being modified/tested. This field is always populated.
Example: cloudresourcemanager.googleapis.com/Project,
compute.googleapis.com/Instance

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Contains the fully qualified resource name. This field is always populated.
ex: //cloudresourcemanager.googleapis.com/projects/foo.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Path to the target field being operated on. If the operation is at the
resource level, then path should be "/". This field is always populated.

=item * C<< $msg->source_resource() >> / C<< $msg->source_resource($value) >>

Type: C<String>

Can be set with action 'copy' to copy resource configuration across
different resources of the same type. Example: A resource clone can be
done via action = 'copy', path = "/", from = "/",
source_resource = <source> and resource_name = <target>.
This field is empty for all other values of `action`.

=item * C<< $msg->source_path() >> / C<< $msg->source_path($value) >>

Type: C<String>

Can be set with action 'copy' or 'move' to indicate the source field within
resource or source_resource, ignored if provided for other operation types.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Value for the `path` field. Will be set for actions:'add'/'replace'.
Maybe set for action: 'test'. Either this or `value_matcher` will be set
for 'test' operation. An exact match must be performed.

=item * C<< $msg->value_matcher() >> / C<< $msg->value_matcher($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::ValueMatcher>)

Can be set for action 'test' for advanced matching for the value of
'path' field. Either this or `value` will be set for 'test' operation.

=item * C<< $msg->path_filters() >> / C<< $msg->path_filters($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathFiltersEntry>)

Set of filters to apply if `path` refers to array elements or nested array
elements in order to narrow down to a single unique element that is being
tested/modified.
This is intended to be an exact match per filter. To perform advanced
matching, use path_value_matchers.

* Example:
```
{
  "/versions/*/name" : "it-123"
  "/versions/*/targetSize/percent": 20
}
```
* Example:
```
{
  "/bindings/*/role": "roles/owner"
  "/bindings/*/condition" : null
}
```
* Example:
```
{
  "/bindings/*/role": "roles/owner"
  "/bindings/*/members/*" : ["x@example.com", "y@example.com"]
}
```
When both path_filters and path_value_matchers are set, an implicit AND
must be performed.

=item * C<< $msg->path_value_matchers() >> / C<< $msg->path_value_matchers($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathValueMatchersEntry>)

Similar to path_filters, this contains set of filters to apply if `path`
field refers to array elements. This is meant to support value matching
beyond exact match. To perform exact match, use path_filters.
When both path_filters and path_value_matchers are set, an implicit AND
must be performed.

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::ValueMatcher

Contains various matching options for values for a GCP resource field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matches_pattern() >> / C<< $msg->matches_pattern($value) >>

Type: C<String>

To be used for full regex matching. The regular expression is using the
Google RE2 syntax (https://github.com/google/re2/wiki/Syntax), so to be
used with RE2::FullMatch

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::CostProjection

Contains metadata about how much money a recommendation can save or incur.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cost() >> / C<< $msg->cost($value) >>

Type: C<Message> (L<Google::Type::Money::Money>)

An approximate projection on amount saved or amount incurred. Negative cost
units indicate cost savings and positive cost units indicate increase.
See google.type.Money documentation for positive/negative units.

A user's permissions may affect whether the cost is computed using list
prices or custom contract prices.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration for which this cost applies.

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::SecurityProjection

Contains various ways of describing the impact on Security.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

This field can be used by the recommender to define details specific to
security impact.

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::SustainabilityProjection

Contains metadata about how much sustainability a recommendation can save or
incur.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kg_c_o2e() >> / C<< $msg->kg_c_o2e($value) >>

Type: C<Double>

Carbon Footprint generated in kg of CO2 equivalent.
Chose kg_c_o2e so that the name renders correctly in camelCase (kgCO2e).

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration for which this sustanability applies.

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::Impact

Contains the impact a recommendation can have for a given category.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::Impact::Category>)

Category that is being targeted.

=item * C<< $msg->cost_projection() >> / C<< $msg->cost_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::CostProjection>)

Use with CategoryType.COST

=item * C<< $msg->security_projection() >> / C<< $msg->security_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::SecurityProjection>)

Use with CategoryType.SECURITY

=item * C<< $msg->sustainability_projection() >> / C<< $msg->sustainability_projection($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::SustainabilityProjection>)

Use with CategoryType.SUSTAINABILITY

=back

=head3 Enum: Impact::Category

=over 4

=item * C<CATEGORY_UNSPECIFIED> => C<0>

=item * C<COST> => C<1>

=item * C<SECURITY> => C<2>

=item * C<PERFORMANCE> => C<3>

=item * C<MANAGEABILITY> => C<4>

=item * C<SUSTAINABILITY> => C<5>

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo

Information for state. Contains state and metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Recommender::V1beta1::RecommendationStateInfo::State>)

The state of the recommendation, Eg ACTIVE, SUCCEEDED, FAILED.

=item * C<< $msg->state_metadata() >> / C<< $msg->state_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo::StateMetadataEntry>)

A map of metadata for the state, provided by user or automations systems.

=back

=head3 Enum: RecommendationStateInfo::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<CLAIMED> => C<6>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<DISMISSED> => C<5>

=back

=head2 Google::Cloud::Recommender::V1beta1::Recommendation::RecommenderType

The type of a recommender.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The recommender's name in format RecommenderTypes/{recommender_type}
eg:  recommenderTypes/google.iam.policy.Recommender

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Recommender::V1beta1::Recommendation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
