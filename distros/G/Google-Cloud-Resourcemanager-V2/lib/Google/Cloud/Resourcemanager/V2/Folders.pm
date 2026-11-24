package Google::Cloud::Resourcemanager::V2::Folders;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvcmVzb3VyY2VtYW5hZ2VyL3YyL2ZvbGRlcnMucHJvdG8SH2dvb2ds
ZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvaWFtL3YxL2lhbV9w
b2xpY3kucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnByb3RvGiNnb29nbGUvbG9uZ3J1
bm5pbmcvb3BlcmF0aW9ucy5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i4wMKBkZvbGRlchIXCgRuYW1l
GAEgASgJQgPgQQNSBG5hbWUSGwoGcGFyZW50GAIgASgJQgPgQQJSBnBhcmVudBIhCgxkaXNw
bGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lEmQKD2xpZmVjeWNsZV9zdGF0ZRgEIAEoDjI2
Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVyLkxpZmVjeWNsZVN0YXRl
QgPgQQNSDmxpZmVjeWNsZVN0YXRlEkAKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAYgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lIlMKDkxpZmVj
eWNsZVN0YXRlEh8KG0xJRkVDWUNMRV9TVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRAB
EhQKEERFTEVURV9SRVFVRVNURUQQAjpB6kE+CipjbG91ZHJlc291cmNlbWFuYWdlci5nb29n
bGVhcGlzLmNvbS9Gb2xkZXISEGZvbGRlcnMve2ZvbGRlcn0ipQEKEkxpc3RGb2xkZXJzUmVx
dWVzdBIhCgZwYXJlbnQYASABKAlCCeBBAvpBAxIBKlIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgC
IAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tl
bhImCgxzaG93X2RlbGV0ZWQYBCABKAhCA+BBAVILc2hvd0RlbGV0ZWQigAEKE0xpc3RGb2xk
ZXJzUmVzcG9uc2USQQoHZm9sZGVycxgBIAMoCzInLmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1h
bmFnZXIudjIuRm9sZGVyUgdmb2xkZXJzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiJyChRTZWFyY2hGb2xkZXJzUmVxdWVzdBIgCglwYWdlX3NpemUYASABKAVC
A+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgCIAEoCUID4EEBUglwYWdlVG9rZW4SFAoF
cXVlcnkYAyABKAlSBXF1ZXJ5IoIBChVTZWFyY2hGb2xkZXJzUmVzcG9uc2USQQoHZm9sZGVy
cxgBIAMoCzInLmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVyUgdmb2xk
ZXJzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJaChBHZXRGb2xk
ZXJSZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqY2xvdWRyZXNvdXJjZW1hbmFnZXIu
Z29vZ2xlYXBpcy5jb20vRm9sZGVyUgRuYW1lIn4KE0NyZWF0ZUZvbGRlclJlcXVlc3QSIQoG
cGFyZW50GAEgASgJQgngQQL6QQMSASpSBnBhcmVudBJECgZmb2xkZXIYAiABKAsyJy5nb29n
bGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYyLkZvbGRlckID4EECUgZmb2xkZXIilQEKEU1v
dmVGb2xkZXJSZXF1ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqY2xvdWRyZXNvdXJjZW1h
bmFnZXIuZ29vZ2xlYXBpcy5jb20vRm9sZGVyUgRuYW1lEjgKEmRlc3RpbmF0aW9uX3BhcmVu
dBgCIAEoCUIJ4EEC+kEDEgEqUhFkZXN0aW5hdGlvblBhcmVudCKdAQoTVXBkYXRlRm9sZGVy
UmVxdWVzdBJECgZmb2xkZXIYASABKAsyJy5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2Vy
LnYyLkZvbGRlckID4EECUgZmb2xkZXISQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1hc2siiAEKE0RlbGV0ZUZvbGRlclJl
cXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCipjbG91ZHJlc291cmNlbWFuYWdlci5nb29n
bGVhcGlzLmNvbS9Gb2xkZXJSBG5hbWUSKQoQcmVjdXJzaXZlX2RlbGV0ZRgCIAEoCFIPcmVj
dXJzaXZlRGVsZXRlIl8KFVVuZGVsZXRlRm9sZGVyUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLg
QQL6QSwKKmNsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL0ZvbGRlclIEbmFt
ZSK2AgoPRm9sZGVyT3BlcmF0aW9uEiEKDGRpc3BsYXlfbmFtZRgBIAEoCVILZGlzcGxheU5h
bWUSZQoOb3BlcmF0aW9uX3R5cGUYAiABKA4yPi5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5h
Z2VyLnYyLkZvbGRlck9wZXJhdGlvbi5PcGVyYXRpb25UeXBlUg1vcGVyYXRpb25UeXBlEiMK
DXNvdXJjZV9wYXJlbnQYAyABKAlSDHNvdXJjZVBhcmVudBItChJkZXN0aW5hdGlvbl9wYXJl
bnQYBCABKAlSEWRlc3RpbmF0aW9uUGFyZW50IkUKDU9wZXJhdGlvblR5cGUSHgoaT1BFUkFU
SU9OX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZDUkVBVEUQARIICgRNT1ZFEAIyvg8KB0ZvbGRl
cnMSowEKC0xpc3RGb2xkZXJzEjMuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52Mi5M
aXN0Rm9sZGVyc1JlcXVlc3QaNC5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYyLkxp
c3RGb2xkZXJzUmVzcG9uc2UiKYLT5JMCDRILL3YyL2ZvbGRlcnPaQRNwYXJlbnQsc2hvd19k
ZWxldGVkEqUBCg1TZWFyY2hGb2xkZXJzEjUuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdl
ci52Mi5TZWFyY2hGb2xkZXJzUmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFn
ZXIudjIuU2VhcmNoRm9sZGVyc1Jlc3BvbnNlIiWC0+STAhciEi92Mi9mb2xkZXJzOnNlYXJj
aDoBKtpBBXF1ZXJ5EowBCglHZXRGb2xkZXISMS5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5h
Z2VyLnYyLkdldEZvbGRlclJlcXVlc3QaJy5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2Vy
LnYyLkZvbGRlciIjgtPkkwIWEhQvdjIve25hbWU9Zm9sZGVycy8qfdpBBG5hbWUSrAEKDENy
ZWF0ZUZvbGRlchI0Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuQ3JlYXRlRm9s
ZGVyUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iR4LT5JMCFSILL3Yy
L2ZvbGRlcnM6BmZvbGRlctpBDXBhcmVudCxmb2xkZXLKQRkKBkZvbGRlchIPRm9sZGVyT3Bl
cmF0aW9uEq8BCgxVcGRhdGVGb2xkZXISNC5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2Vy
LnYyLlVwZGF0ZUZvbGRlclJlcXVlc3QaJy5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2Vy
LnYyLkZvbGRlciJAgtPkkwIlMhsvdjIve2ZvbGRlci5uYW1lPWZvbGRlcnMvKn06BmZvbGRl
ctpBEmZvbGRlcix1cGRhdGVfbWFzaxK7AQoKTW92ZUZvbGRlchIyLmdvb2dsZS5jbG91ZC5y
ZXNvdXJjZW1hbmFnZXIudjIuTW92ZUZvbGRlclJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIlqC0+STAh4iGS92Mi97bmFtZT1mb2xkZXJzLyp9Om1vdmU6ASraQRdu
YW1lLGRlc3RpbmF0aW9uX3BhcmVudMpBGQoGRm9sZGVyEg9Gb2xkZXJPcGVyYXRpb24SqgEK
DERlbGV0ZUZvbGRlchI0Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuRGVsZXRl
Rm9sZGVyUmVxdWVzdBonLmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVy
IjuC0+STAhYqFC92Mi97bmFtZT1mb2xkZXJzLyp92kEEbmFtZdpBFW5hbWUscmVjdXJzaXZl
X2RlbGV0ZRKiAQoOVW5kZWxldGVGb2xkZXISNi5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5h
Z2VyLnYyLlVuZGVsZXRlRm9sZGVyUmVxdWVzdBonLmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1h
bmFnZXIudjIuRm9sZGVyIi+C0+STAiIiHS92Mi97bmFtZT1mb2xkZXJzLyp9OnVuZGVsZXRl
OgEq2kEEbmFtZRKGAQoMR2V0SWFtUG9saWN5EiIuZ29vZ2xlLmlhbS52MS5HZXRJYW1Qb2xp
Y3lSZXF1ZXN0GhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3kiO4LT5JMCKiIlL3YyL3tyZXNvdXJj
ZT1mb2xkZXJzLyp9OmdldElhbVBvbGljeToBKtpBCHJlc291cmNlEo0BCgxTZXRJYW1Qb2xp
Y3kSIi5nb29nbGUuaWFtLnYxLlNldElhbVBvbGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYx
LlBvbGljeSJCgtPkkwIqIiUvdjIve3Jlc291cmNlPWZvbGRlcnMvKn06c2V0SWFtUG9saWN5
OgEq2kEPcmVzb3VyY2UscG9saWN5ErgBChJUZXN0SWFtUGVybWlzc2lvbnMSKC5nb29nbGUu
aWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9uc1JlcXVlc3QaKS5nb29nbGUuaWFtLnYxLlRlc3RJ
YW1QZXJtaXNzaW9uc1Jlc3BvbnNlIk2C0+STAjAiKy92Mi97cmVzb3VyY2U9Zm9sZGVycy8q
fTp0ZXN0SWFtUGVybWlzc2lvbnM6ASraQRRyZXNvdXJjZSxwZXJtaXNzaW9ucxqQAcpBI2Ns
b3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29t0kFnaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNv
bS9hdXRoL2Nsb3VkLXBsYXRmb3JtLnJlYWQtb25seULIAQojY29tLmdvb2dsZS5jbG91ZC5y
ZXNvdXJjZW1hbmFnZXIudjJCDEZvbGRlcnNQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dv
L3Jlc291cmNlbWFuYWdlci9hcGl2Mi9yZXNvdXJjZW1hbmFnZXJwYjtyZXNvdXJjZW1hbmFn
ZXJwYqoCH0dvb2dsZS5DbG91ZC5SZXNvdXJjZU1hbmFnZXIuVjLKAh9Hb29nbGVcQ2xvdWRc
UmVzb3VyY2VNYW5hZ2VyXFYySrmKAQoHEgUPAPcDAQq9BAoBDBIDDwASMrIEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCgoICgECEgMRACgKCQoCAwASAxMAJgoJCgIDARIDFAAhCgkKAgMCEgMV
ACkKCQoCAwMSAxYAIwoJCgIDBBIDFwAoCgkKAgMFEgMYACQKCQoCAwYSAxkALQoJCgIDBxID
GgAqCgkKAgMIEgMbACkKCAoBCBIDHQA8CgkKAgglEgMdADwKCAoBCBIDHgBkCgkKAggLEgMe
AGQKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAAtCgkKAggIEgMgAC0KCAoBCBIDIQA8
CgkKAggBEgMhADwKCAoBCBIDIgA8CgkKAggpEgMiADwKxAEKAgYAEgUnAPkBARq2ASBNYW5h
Z2VzIENsb3VkIFJlc291cmNlIEZvbGRlcnMuCiBDbG91ZCBSZXNvdXJjZSBGb2xkZXJzIGNh
biBiZSB1c2VkIHRvIG9yZ2FuaXplIHRoZSByZXNvdXJjZXMgdW5kZXIgYW4KIG9yZ2FuaXph
dGlvbiBhbmQgdG8gY29udHJvbCB0aGUgSUFNIHBvbGljaWVzIGFwcGxpZWQgdG8gZ3JvdXBz
IG9mIHJlc291cmNlcy4KCgoKAwYAARIDJwgPCgoKAwYAAxIDKAJLCgwKBQYAA5kIEgMoAksK
CwoDBgADEgQpAitBCg0KBQYAA5oIEgQpAitBCvsCCgQGAAIAEgQ0AjkDGuwCIExpc3RzIHRo
ZSBGb2xkZXJzIHRoYXQgYXJlIGRpcmVjdCBkZXNjZW5kYW50cyBvZiBzdXBwbGllZCBwYXJl
bnQgcmVzb3VyY2UuCiBMaXN0IHByb3ZpZGVzIGEgc3Ryb25nbHkgY29uc2lzdGVudCB2aWV3
IG9mIHRoZSBGb2xkZXJzIHVuZGVybmVhdGgKIHRoZSBzcGVjaWZpZWQgcGFyZW50IHJlc291
cmNlLgogTGlzdCByZXR1cm5zIEZvbGRlcnMgc29ydGVkIGJhc2VkIHVwb24gdGhlIChhc2Nl
bmRpbmcpIGxleGljYWwgb3JkZXJpbmcKIG9mIHRoZWlyIGRpc3BsYXlfbmFtZS4KIFRoZSBj
YWxsZXIgbXVzdCBoYXZlIGByZXNvdXJjZW1hbmFnZXIuZm9sZGVycy5saXN0YCBwZXJtaXNz
aW9uIG9uIHRoZQogaWRlbnRpZmllZCBwYXJlbnQuCgoMCgUGAAIAARIDNAYRCgwKBQYAAgAC
EgM0EiQKDAoFBgACAAMSAzQvQgoNCgUGAAIABBIENQQ3BgoRCgkGAAIABLDKvCISBDUENwYK
DAoFBgACAAQSAzgEQQoPCggGAAIABJsIABIDOARBCq0CCgQGAAIBEgRBAkcDGp4CIFNlYXJj
aCBmb3IgZm9sZGVycyB0aGF0IG1hdGNoIHNwZWNpZmljIGZpbHRlciBjcml0ZXJpYS4KIFNl
YXJjaCBwcm92aWRlcyBhbiBldmVudHVhbGx5IGNvbnNpc3RlbnQgdmlldyBvZiB0aGUgZm9s
ZGVycyBhIHVzZXIgaGFzCiBhY2Nlc3MgdG8gd2hpY2ggbWVldCB0aGUgc3BlY2lmaWVkIGZp
bHRlciBjcml0ZXJpYS4KCiBUaGlzIHdpbGwgb25seSByZXR1cm4gZm9sZGVycyBvbiB3aGlj
aCB0aGUgY2FsbGVyIGhhcyB0aGUKIHBlcm1pc3Npb24gYHJlc291cmNlbWFuYWdlci5mb2xk
ZXJzLmdldGAuCgoMCgUGAAIBARIDQQYTCgwKBQYAAgECEgNBFCgKDAoFBgACAQMSA0EzSAoN
CgUGAAIBBBIEQgRFBgoRCgkGAAIBBLDKvCISBEIERQYKDAoFBgACAQQSA0YEMwoPCggGAAIB
BJsIABIDRgQzCooCCgQGAAICEgROAlMDGvsBIFJldHJpZXZlcyBhIEZvbGRlciBpZGVudGlm
aWVkIGJ5IHRoZSBzdXBwbGllZCByZXNvdXJjZSBuYW1lLgogVmFsaWQgRm9sZGVyIHJlc291
cmNlIG5hbWVzIGhhdmUgdGhlIGZvcm1hdCBgZm9sZGVycy97Zm9sZGVyX2lkfWAKIChmb3Ig
ZXhhbXBsZSwgYGZvbGRlcnMvMTIzNGApLgogVGhlIGNhbGxlciBtdXN0IGhhdmUgYHJlc291
cmNlbWFuYWdlci5mb2xkZXJzLmdldGAgcGVybWlzc2lvbiBvbiB0aGUKIGlkZW50aWZpZWQg
Zm9sZGVyLgoKDAoFBgACAgESA04GDwoMCgUGAAICAhIDThAgCgwKBQYAAgIDEgNOKzEKDQoF
BgACAgQSBE8EUQYKEQoJBgACAgSwyrwiEgRPBFEGCgwKBQYAAgIEEgNSBDIKDwoIBgACAgSb
CAASA1IEMgqJCgoEBgACAxIEcAJ6Axr6CSBDcmVhdGVzIGEgRm9sZGVyIGluIHRoZSByZXNv
dXJjZSBoaWVyYXJjaHkuCiBSZXR1cm5zIGFuIE9wZXJhdGlvbiB3aGljaCBjYW4gYmUgdXNl
ZCB0byB0cmFjayB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBmb2xkZXIgY3JlYXRpb24gd29ya2Zs
b3cuCiBVcG9uIHN1Y2Nlc3MgdGhlIE9wZXJhdGlvbi5yZXNwb25zZSBmaWVsZCB3aWxsIGJl
IHBvcHVsYXRlZCB3aXRoIHRoZQogY3JlYXRlZCBGb2xkZXIuCgogSW4gb3JkZXIgdG8gc3Vj
Y2VlZCwgdGhlIGFkZGl0aW9uIG9mIHRoaXMgbmV3IEZvbGRlciBtdXN0IG5vdCB2aW9sYXRl
CiB0aGUgRm9sZGVyIG5hbWluZywgaGVpZ2h0IG9yIGZhbm91dCBjb25zdHJhaW50cy4KCiAr
IFRoZSBGb2xkZXIncyBkaXNwbGF5X25hbWUgbXVzdCBiZSBkaXN0aW5jdCBmcm9tIGFsbCBv
dGhlciBGb2xkZXIncyB0aGF0CiBzaGFyZSBpdHMgcGFyZW50LgogKyBUaGUgYWRkaXRpb24g
b2YgdGhlIEZvbGRlciBtdXN0IG5vdCBjYXVzZSB0aGUgYWN0aXZlIEZvbGRlciBoaWVyYXJj
aHkKIHRvIGV4Y2VlZCBhIGhlaWdodCBvZiA0LiBOb3RlLCB0aGUgZnVsbCBhY3RpdmUgKyBk
ZWxldGVkIEZvbGRlciBoaWVyYXJjaHkKIGlzIGFsbG93ZWQgdG8gcmVhY2ggYSBoZWlnaHQg
b2YgODsgdGhpcyBwcm92aWRlcyBhZGRpdGlvbmFsIGhlYWRyb29tIHdoZW4KIG1vdmluZyBm
b2xkZXJzIHRoYXQgY29udGFpbiBkZWxldGVkIGZvbGRlcnMuCiArIFRoZSBhZGRpdGlvbiBv
ZiB0aGUgRm9sZGVyIG11c3Qgbm90IGNhdXNlIHRoZSB0b3RhbCBudW1iZXIgb2YgRm9sZGVy
cwogdW5kZXIgaXRzIHBhcmVudCB0byBleGNlZWQgMTAwLgoKIElmIHRoZSBvcGVyYXRpb24g
ZmFpbHMgZHVlIHRvIGEgZm9sZGVyIGNvbnN0cmFpbnQgdmlvbGF0aW9uLCBzb21lIGVycm9y
cwogbWF5IGJlIHJldHVybmVkIGJ5IHRoZSBDcmVhdGVGb2xkZXIgcmVxdWVzdCwgd2l0aCBz
dGF0dXMgY29kZQogRkFJTEVEX1BSRUNPTkRJVElPTiBhbmQgYW4gZXJyb3IgZGVzY3JpcHRp
b24uIE90aGVyIGZvbGRlciBjb25zdHJhaW50CiB2aW9sYXRpb25zIHdpbGwgYmUgY29tbXVu
aWNhdGVkIGluIHRoZSBPcGVyYXRpb24sIHdpdGggdGhlIHNwZWNpZmljCiBQcmVjb25kaXRp
b25GYWlsdXJlIHJldHVybmVkIHZpYSB0aGUgZGV0YWlscyBsaXN0IGluIHRoZSBPcGVyYXRp
b24uZXJyb3IKIGZpZWxkLgoKIFRoZSBjYWxsZXIgbXVzdCBoYXZlIGByZXNvdXJjZW1hbmFn
ZXIuZm9sZGVycy5jcmVhdGVgIHBlcm1pc3Npb24gb24gdGhlCiBpZGVudGlmaWVkIHBhcmVu
dC4KCgwKBQYAAgMBEgNwBhIKDAoFBgACAwISA3ATJgoMCgUGAAIDAxIDcDFNCg0KBQYAAgME
EgRxBHQGChEKCQYAAgMEsMq8IhIEcQR0BgoMCgUGAAIDBBIDdQQ7Cg8KCAYAAgMEmwgAEgN1
BDsKDQoFBgACAwQSBHYEeQYKDwoHBgACAwSZCBIEdgR5BgqyBgoEBgACBBIGiwECkQEDGqEG
IFVwZGF0ZXMgYSBGb2xkZXIsIGNoYW5naW5nIGl0cyBkaXNwbGF5X25hbWUuCiBDaGFuZ2Vz
IHRvIHRoZSBmb2xkZXIgZGlzcGxheV9uYW1lIHdpbGwgYmUgcmVqZWN0ZWQgaWYgdGhleSB2
aW9sYXRlIGVpdGhlcgogdGhlIGRpc3BsYXlfbmFtZSBmb3JtYXR0aW5nIHJ1bGVzIG9yIG5h
bWluZyBjb25zdHJhaW50cyBkZXNjcmliZWQgaW4KIHRoZSBbQ3JlYXRlRm9sZGVyXVtnb29n
bGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYyLkZvbGRlcnMuQ3JlYXRlRm9sZGVyXSBkb2N1
bWVudGF0aW9uLgoKIFRoZSBGb2xkZXIncyBkaXNwbGF5IG5hbWUgbXVzdCBzdGFydCBhbmQg
ZW5kIHdpdGggYSBsZXR0ZXIgb3IgZGlnaXQsCiBtYXkgY29udGFpbiBsZXR0ZXJzLCBkaWdp
dHMsIHNwYWNlcywgaHlwaGVucyBhbmQgdW5kZXJzY29yZXMgYW5kIGNhbiBiZQogbm8gbG9u
Z2VyIHRoYW4gMzAgY2hhcmFjdGVycy4gVGhpcyBpcyBjYXB0dXJlZCBieSB0aGUgcmVndWxh
ciBleHByZXNzaW9uOgogW1xwe0x9XHB7Tn1dKFtccHtMfVxwe059Xy0gXXswLDI4fVtccHtM
fVxwe059XSk/LgogVGhlIGNhbGxlciBtdXN0IGhhdmUgYHJlc291cmNlbWFuYWdlci5mb2xk
ZXJzLnVwZGF0ZWAgcGVybWlzc2lvbiBvbiB0aGUKIGlkZW50aWZpZWQgZm9sZGVyLgoKIElm
IHRoZSB1cGRhdGUgZmFpbHMgZHVlIHRvIHRoZSB1bmlxdWUgbmFtZSBjb25zdHJhaW50IHRo
ZW4gYQogUHJlY29uZGl0aW9uRmFpbHVyZSBleHBsYWluaW5nIHRoaXMgdmlvbGF0aW9uIHdp
bGwgYmUgcmV0dXJuZWQKIGluIHRoZSBTdGF0dXMuZGV0YWlscyBmaWVsZC4KCg0KBQYAAgQB
EgSLAQYSCg0KBQYAAgQCEgSLARMmCg0KBQYAAgQDEgSLATE3Cg8KBQYAAgQEEgaMAQSPAQYK
EwoJBgACBASwyrwiEgaMAQSPAQYKDQoFBgACBAQSBJABBEAKEAoIBgACBASbCAASBJABBEAK
2QcKBAYAAgUSBqQBAq4BAxrIByBNb3ZlcyBhIEZvbGRlciB1bmRlciBhIG5ldyByZXNvdXJj
ZSBwYXJlbnQuCiBSZXR1cm5zIGFuIE9wZXJhdGlvbiB3aGljaCBjYW4gYmUgdXNlZCB0byB0
cmFjayB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBmb2xkZXIgbW92ZSB3b3JrZmxvdy4KIFVwb24g
c3VjY2VzcyB0aGUgT3BlcmF0aW9uLnJlc3BvbnNlIGZpZWxkIHdpbGwgYmUgcG9wdWxhdGVk
IHdpdGggdGhlCiBtb3ZlZCBGb2xkZXIuCiBVcG9uIGZhaWx1cmUsIGEgRm9sZGVyT3BlcmF0
aW9uRXJyb3IgY2F0ZWdvcml6aW5nIHRoZSBmYWlsdXJlIGNhdXNlIHdpbGwKIGJlIHJldHVy
bmVkIC0gaWYgdGhlIGZhaWx1cmUgb2NjdXJzIHN5bmNocm9ub3VzbHkgdGhlbiB0aGUKIEZv
bGRlck9wZXJhdGlvbkVycm9yIHdpbGwgYmUgcmV0dXJuZWQgdmlhIHRoZSBTdGF0dXMuZGV0
YWlscyBmaWVsZAogYW5kIGlmIGl0IG9jY3VycyBhc3luY2hyb25vdXNseSB0aGVuIHRoZSBG
b2xkZXJPcGVyYXRpb24gd2lsbCBiZSByZXR1cm5lZAogdmlhIHRoZSBPcGVyYXRpb24uZXJy
b3IgZmllbGQuCiBJbiBhZGRpdGlvbiwgdGhlIE9wZXJhdGlvbi5tZXRhZGF0YSBmaWVsZCB3
aWxsIGJlIHBvcHVsYXRlZCB3aXRoIGEKIEZvbGRlck9wZXJhdGlvbiBtZXNzYWdlIGFzIGFu
IGFpZCB0byBzdGF0ZWxlc3MgY2xpZW50cy4KIEZvbGRlciBtb3ZlcyB3aWxsIGJlIHJlamVj
dGVkIGlmIHRoZXkgdmlvbGF0ZSBlaXRoZXIgdGhlIG5hbWluZywgaGVpZ2h0CiBvciBmYW5v
dXQgY29uc3RyYWludHMgZGVzY3JpYmVkIGluIHRoZQogW0NyZWF0ZUZvbGRlcl1bZ29vZ2xl
LmNsb3VkLnJlc291cmNlbWFuYWdlci52Mi5Gb2xkZXJzLkNyZWF0ZUZvbGRlcl0gZG9jdW1l
bnRhdGlvbi4KIFRoZSBjYWxsZXIgbXVzdCBoYXZlIGByZXNvdXJjZW1hbmFnZXIuZm9sZGVy
cy5tb3ZlYCBwZXJtaXNzaW9uIG9uIHRoZQogZm9sZGVyJ3MgY3VycmVudCBhbmQgcHJvcG9z
ZWQgbmV3IHBhcmVudC4KCg0KBQYAAgUBEgSkAQYQCg0KBQYAAgUCEgSkAREiCg0KBQYAAgUD
EgSkAS1JCg8KBQYAAgUEEgalAQSoAQYKEwoJBgACBQSwyrwiEgalAQSoAQYKDQoFBgACBQQS
BKkBBEUKEAoIBgACBQSbCAASBKkBBEUKDwoFBgACBQQSBqoBBK0BBgoRCgcGAAIFBJkIEgaq
AQStAQYK7QQKBAYAAgYSBrkBAr8BAxrcBCBSZXF1ZXN0cyBkZWxldGlvbiBvZiBhIEZvbGRl
ci4gVGhlIEZvbGRlciBpcyBtb3ZlZCBpbnRvIHRoZQogW0RFTEVURV9SRVFVRVNURURdW2dv
b2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVyLkxpZmVjeWNsZVN0YXRlLkRF
TEVURV9SRVFVRVNURURdIHN0YXRlCiBpbW1lZGlhdGVseSwgYW5kIGlzIGRlbGV0ZWQgYXBw
cm94aW1hdGVseSAzMCBkYXlzIGxhdGVyLiBUaGlzIG1ldGhvZCBtYXkKIG9ubHkgYmUgY2Fs
bGVkIG9uIGFuIGVtcHR5IEZvbGRlciBpbiB0aGUKIFtBQ1RJVkVdW2dvb2dsZS5jbG91ZC5y
ZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVyLkxpZmVjeWNsZVN0YXRlLkFDVElWRV0gc3RhdGUs
IHdoZXJlIGEgRm9sZGVyIGlzIGVtcHR5IGlmCiBpdCBkb2Vzbid0IGNvbnRhaW4gYW55IEZv
bGRlcnMgb3IgUHJvamVjdHMgaW4gdGhlCiBbQUNUSVZFXVtnb29nbGUuY2xvdWQucmVzb3Vy
Y2VtYW5hZ2VyLnYyLkZvbGRlci5MaWZlY3ljbGVTdGF0ZS5BQ1RJVkVdIHN0YXRlLgogVGhl
IGNhbGxlciBtdXN0IGhhdmUgYHJlc291cmNlbWFuYWdlci5mb2xkZXJzLmRlbGV0ZWAgcGVy
bWlzc2lvbiBvbiB0aGUKIGlkZW50aWZpZWQgZm9sZGVyLgoKDQoFBgACBgESBLkBBhIKDQoF
BgACBgISBLkBEyYKDQoFBgACBgMSBLkBMTcKDwoFBgACBgQSBroBBLwBBgoTCgkGAAIGBLDK
vCISBroBBLwBBgoNCgUGAAIGBBIEvQEEMgoQCggGAAIGBJsIABIEvQEEMgoNCgUGAAIGBBIE
vgEEQwoQCggGAAIGBJsIARIEvgEEQwqUBQoEBgACBxIGywEC0QEDGoMFIENhbmNlbHMgdGhl
IGRlbGV0aW9uIHJlcXVlc3QgZm9yIGEgRm9sZGVyLiBUaGlzIG1ldGhvZCBtYXkgb25seSBi
ZQogY2FsbGVkIG9uIGEgRm9sZGVyIGluIHRoZQogW0RFTEVURV9SRVFVRVNURURdW2dvb2ds
ZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVyLkxpZmVjeWNsZVN0YXRlLkRFTEVU
RV9SRVFVRVNURURdIHN0YXRlLgogSW4gb3JkZXIgdG8gc3VjY2VlZCwgdGhlIEZvbGRlcidz
IHBhcmVudCBtdXN0IGJlIGluIHRoZQogW0FDVElWRV1bZ29vZ2xlLmNsb3VkLnJlc291cmNl
bWFuYWdlci52Mi5Gb2xkZXIuTGlmZWN5Y2xlU3RhdGUuQUNUSVZFXSBzdGF0ZS4KIEluIGFk
ZGl0aW9uLCByZWludHJvZHVjaW5nIHRoZSBmb2xkZXIgaW50byB0aGUgdHJlZSBtdXN0IG5v
dCB2aW9sYXRlCiBmb2xkZXIgbmFtaW5nLCBoZWlnaHQgYW5kIGZhbm91dCBjb25zdHJhaW50
cyBkZXNjcmliZWQgaW4gdGhlCiBbQ3JlYXRlRm9sZGVyXVtnb29nbGUuY2xvdWQucmVzb3Vy
Y2VtYW5hZ2VyLnYyLkZvbGRlcnMuQ3JlYXRlRm9sZGVyXSBkb2N1bWVudGF0aW9uLgogVGhl
IGNhbGxlciBtdXN0IGhhdmUgYHJlc291cmNlbWFuYWdlci5mb2xkZXJzLnVuZGVsZXRlYCBw
ZXJtaXNzaW9uIG9uIHRoZQogaWRlbnRpZmllZCBmb2xkZXIuCgoNCgUGAAIHARIEywEGFAoN
CgUGAAIHAhIEywEVKgoNCgUGAAIHAxIEywE1OwoPCgUGAAIHBBIGzAEEzwEGChMKCQYAAgcE
sMq8IhIGzAEEzwEGCg0KBQYAAgcEEgTQAQQyChAKCAYAAgcEmwgAEgTQAQQyCrsCCgQGAAII
EgbYAQLeAQMaqgIgR2V0cyB0aGUgYWNjZXNzIGNvbnRyb2wgcG9saWN5IGZvciBhIEZvbGRl
ci4gVGhlIHJldHVybmVkIHBvbGljeSBtYXkgYmUKIGVtcHR5IGlmIG5vIHN1Y2ggcG9saWN5
IG9yIHJlc291cmNlIGV4aXN0cy4gVGhlIGByZXNvdXJjZWAgZmllbGQgc2hvdWxkCiBiZSB0
aGUgRm9sZGVyJ3MgcmVzb3VyY2UgbmFtZSwgZS5nLiAiZm9sZGVycy8xMjM0Ii4KIFRoZSBj
YWxsZXIgbXVzdCBoYXZlIGByZXNvdXJjZW1hbmFnZXIuZm9sZGVycy5nZXRJYW1Qb2xpY3lg
IHBlcm1pc3Npb24KIG9uIHRoZSBpZGVudGlmaWVkIGZvbGRlci4KCg0KBQYAAggBEgTYAQYS
Cg0KBQYAAggCEgTYARM0Cg0KBQYAAggDEgTYAT9TCg8KBQYAAggEEgbZAQTcAQYKEwoJBgAC
CASwyrwiEgbZAQTcAQYKDQoFBgACCAQSBN0BBDYKEAoIBgACCASbCAASBN0BBDYKkgIKBAYA
AgkSBuUBAusBAxqBAiBTZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgb24gYSBGb2xk
ZXIsIHJlcGxhY2luZyBhbnkgZXhpc3RpbmcgcG9saWN5LgogVGhlIGByZXNvdXJjZWAgZmll
bGQgc2hvdWxkIGJlIHRoZSBGb2xkZXIncyByZXNvdXJjZSBuYW1lLCBlLmcuCiAiZm9sZGVy
cy8xMjM0Ii4KIFRoZSBjYWxsZXIgbXVzdCBoYXZlIGByZXNvdXJjZW1hbmFnZXIuZm9sZGVy
cy5zZXRJYW1Qb2xpY3lgIHBlcm1pc3Npb24KIG9uIHRoZSBpZGVudGlmaWVkIGZvbGRlci4K
Cg0KBQYAAgkBEgTlAQYSCg0KBQYAAgkCEgTlARM0Cg0KBQYAAgkDEgTlAT9TCg8KBQYAAgkE
EgbmAQTpAQYKEwoJBgACCQSwyrwiEgbmAQTpAQYKDQoFBgACCQQSBOoBBD0KEAoIBgACCQSb
CAASBOoBBD0K4QEKBAYAAgoSBvIBAvgBAxrQASBSZXR1cm5zIHBlcm1pc3Npb25zIHRoYXQg
YSBjYWxsZXIgaGFzIG9uIHRoZSBzcGVjaWZpZWQgRm9sZGVyLgogVGhlIGByZXNvdXJjZWAg
ZmllbGQgc2hvdWxkIGJlIHRoZSBGb2xkZXIncyByZXNvdXJjZSBuYW1lLAogZS5nLiAiZm9s
ZGVycy8xMjM0Ii4KCiBUaGVyZSBhcmUgbm8gcGVybWlzc2lvbnMgcmVxdWlyZWQgZm9yIG1h
a2luZyB0aGlzIEFQSSBjYWxsLgoKDQoFBgACCgESBPIBBhgKDQoFBgACCgISBPIBGUAKDQoF
BgACCgMSBPIBS3MKDwoFBgACCgQSBvMBBPYBBgoTCgkGAAIKBLDKvCISBvMBBPYBBgoNCgUG
AAIKBBIE9wEEQgoQCggGAAIKBJsIABIE9wEEQgpyCgIEABIG/QEArAIBGmQgQSBGb2xkZXIg
aW4gYW4gT3JnYW5pemF0aW9uJ3MgcmVzb3VyY2UgaGllcmFyY2h5LCB1c2VkIHRvCiBvcmdh
bml6ZSB0aGF0IE9yZ2FuaXphdGlvbidzIHJlc291cmNlcy4KCgsKAwQAARIE/QEIDgoNCgME
AAcSBv4BAoECBAoPCgUEAAedCBIG/gECgQIECioKBAQABAASBoQCAo0CAxoaIEZvbGRlciBs
aWZlY3ljbGUgc3RhdGVzLgoKDQoFBAAEAAESBIQCBxUKJAoGBAAEAAIAEgSGAgQkGhQgVW5z
cGVjaWZpZWQgc3RhdGUuCgoPCgcEAAQAAgABEgSGAgQfCg8KBwQABAACAAISBIYCIiMKLgoG
BAAEAAIBEgSJAgQPGh4gVGhlIG5vcm1hbCBhbmQgYWN0aXZlIHN0YXRlLgoKDwoHBAAEAAIB
ARIEiQIECgoPCgcEAAQAAgECEgSJAg0OCkYKBgQABAACAhIEjAIEGRo2IFRoZSBmb2xkZXIg
aGFzIGJlZW4gbWFya2VkIGZvciBkZWxldGlvbiBieSB0aGUgdXNlci4KCg8KBwQABAACAgES
BIwCBBQKDwoHBAAEAAICAhIEjAIXGAqAAQoEBAACABIEkQICPhpyIE91dHB1dCBvbmx5LiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRm9sZGVyLgogSXRzIGZvcm1hdCBpcyBgZm9sZGVy
cy97Zm9sZGVyX2lkfWAsIGZvciBleGFtcGxlOiAiZm9sZGVycy8xMjM0Ii4KCg0KBQQAAgAF
EgSRAgIICg0KBQQAAgABEgSRAgkNCg0KBQQAAgADEgSRAhARCg0KBQQAAgAIEgSRAhI9ChAK
CAQAAgAInAgAEgSRAhM8CroBCgQEAAIBEgSWAgI9GqsBIFJlcXVpcmVkLiBUaGUgRm9sZGVy
4oCZcyBwYXJlbnQncyByZXNvdXJjZSBuYW1lLgogVXBkYXRlcyB0byB0aGUgZm9sZGVyJ3Mg
cGFyZW50IG11c3QgYmUgcGVyZm9ybWVkIHZpYQogW01vdmVGb2xkZXJdW2dvb2dsZS5jbG91
ZC5yZXNvdXJjZW1hbmFnZXIudjIuRm9sZGVycy5Nb3ZlRm9sZGVyXS4KCg0KBQQAAgEFEgSW
AgIICg0KBQQAAgEBEgSWAgkPCg0KBQQAAgEDEgSWAhITCg0KBQQAAgEIEgSWAhQ8ChAKCAQA
AgEInAgAEgSWAhU7CrwDCgQEAAICEgSfAgIaGq0DIFRoZSBmb2xkZXLigJlzIGRpc3BsYXkg
bmFtZS4KIEEgZm9sZGVy4oCZcyBkaXNwbGF5IG5hbWUgbXVzdCBiZSB1bmlxdWUgYW1vbmdz
dCBpdHMgc2libGluZ3MsIGUuZy4KIG5vIHR3byBmb2xkZXJzIHdpdGggdGhlIHNhbWUgcGFy
ZW50IGNhbiBzaGFyZSB0aGUgc2FtZSBkaXNwbGF5IG5hbWUuCiBUaGUgZGlzcGxheSBuYW1l
IG11c3Qgc3RhcnQgYW5kIGVuZCB3aXRoIGEgbGV0dGVyIG9yIGRpZ2l0LCBtYXkgY29udGFp
bgogbGV0dGVycywgZGlnaXRzLCBzcGFjZXMsIGh5cGhlbnMgYW5kIHVuZGVyc2NvcmVzIGFu
ZCBjYW4gYmUgbm8gbG9uZ2VyCiB0aGFuIDMwIGNoYXJhY3RlcnMuIFRoaXMgaXMgY2FwdHVy
ZWQgYnkgdGhlIHJlZ3VsYXIgZXhwcmVzc2lvbjoKIFtccHtMfVxwe059XShbXHB7TH1ccHtO
fV8tIF17MCwyOH1bXHB7TH1ccHtOfV0pPy4KCg0KBQQAAgIFEgSfAgIICg0KBQQAAgIBEgSf
AgkVCg0KBQQAAgIDEgSfAhgZCosCCgQEAAIDEgSlAgJRGvwBIE91dHB1dCBvbmx5LiBUaGUg
bGlmZWN5Y2xlIHN0YXRlIG9mIHRoZSBmb2xkZXIuCiBVcGRhdGVzIHRvIHRoZSBsaWZlY3lj
bGVfc3RhdGUgbXVzdCBiZSBwZXJmb3JtZWQgdmlhCiBbRGVsZXRlRm9sZGVyXVtnb29nbGUu
Y2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYyLkZvbGRlcnMuRGVsZXRlRm9sZGVyXSBhbmQKIFtV
bmRlbGV0ZUZvbGRlcl1bZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52Mi5Gb2xkZXJz
LlVuZGVsZXRlRm9sZGVyXS4KCg0KBQQAAgMGEgSlAgIQCg0KBQQAAgMBEgSlAhEgCg0KBQQA
AgMDEgSlAiMkCg0KBQQAAgMIEgSlAiVQChAKCAQAAgMInAgAEgSlAiZPClsKBAQAAgQSBKgC
AlgaTSBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIEZvbGRlciB3YXMgY3JlYXRl
ZC4gQXNzaWduZWQgYnkgdGhlIHNlcnZlci4KCg0KBQQAAgQGEgSoAgIbCg0KBQQAAgQBEgSo
AhwnCg0KBQQAAgQDEgSoAiorCg0KBQQAAgQIEgSoAixXChAKCAQAAgQInAgAEgSoAi1WCkkK
BAQAAgUSBKsCAlgaOyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIEZvbGRlciB3
YXMgbGFzdCBtb2RpZmllZC4KCg0KBQQAAgUGEgSrAgIbCg0KBQQAAgUBEgSrAhwnCg0KBQQA
AgUDEgSrAiorCg0KBQQAAgUIEgSrAixXChAKCAQAAgUInAgAEgSrAi1WCjAKAgQBEgavAgDH
AgEaIiBUaGUgTGlzdEZvbGRlcnMgcmVxdWVzdCBtZXNzYWdlLgoKCwoDBAEBEgSvAggaCqYC
CgQEAQIAEga1AgK6AgQalQIgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBP
cmdhbml6YXRpb24gb3IgRm9sZGVyIHdob3NlIEZvbGRlcnMgYXJlCiBiZWluZyBsaXN0ZWQu
CiBNdXN0IGJlIG9mIHRoZSBmb3JtIGBmb2xkZXJzL3tmb2xkZXJfaWR9YCBvciBgb3JnYW5p
emF0aW9ucy97b3JnX2lkfWAuCiBBY2Nlc3MgdG8gdGhpcyBtZXRob2QgaXMgY29udHJvbGxl
ZCBieSBjaGVja2luZyB0aGUKIGByZXNvdXJjZW1hbmFnZXIuZm9sZGVycy5saXN0YCBwZXJt
aXNzaW9uIG9uIHRoZSBgcGFyZW50YC4KCg0KBQQBAgAFEgS1AgIICg0KBQQBAgABEgS1AgkP
Cg0KBQQBAgADEgS1AhITCg8KBQQBAgAIEga1AhS6AgMKEAoIBAECAAicCAASBLYCBCoKEQoH
BAECAAifCBIGtwIEuQIFClIKBAQBAgESBL0CAj8aRCBPcHRpb25hbC4gVGhlIG1heGltdW0g
bnVtYmVyIG9mIEZvbGRlcnMgdG8gcmV0dXJuIGluIHRoZSByZXNwb25zZS4KCg0KBQQBAgEF
EgS9AgIHCg0KBQQBAgEBEgS9AggRCg0KBQQBAgEDEgS9AhQVCg0KBQQBAgEIEgS9AhY+ChAK
CAQBAgEInAgAEgS9Ahc9CpUBCgQEAQICEgTBAgJBGoYBIE9wdGlvbmFsLiBBIHBhZ2luYXRp
b24gdG9rZW4gcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGNhbGwgdG8gYExpc3RGb2xkZXJz
YAogdGhhdCBpbmRpY2F0ZXMgd2hlcmUgdGhpcyBsaXN0aW5nIHNob3VsZCBjb250aW51ZSBm
cm9tLgoKDQoFBAECAgUSBMECAggKDQoFBAECAgESBMECCRMKDQoFBAECAgMSBMECFhcKDQoF
BAECAggSBMECGEAKEAoIBAECAgicCAASBMECGT8KxAEKBAQBAgMSBMYCAkEatQEgT3B0aW9u
YWwuIENvbnRyb2xzIHdoZXRoZXIgRm9sZGVycyBpbiB0aGUKIFtERUxFVEVfUkVRVUVTVEVE
XVtnb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYyLkZvbGRlci5MaWZlY3ljbGVTdGF0
ZS5ERUxFVEVfUkVRVUVTVEVEXQogc3RhdGUgc2hvdWxkIGJlIHJldHVybmVkLiBEZWZhdWx0
cyB0byBmYWxzZS4KCg0KBQQBAgMFEgTGAgIGCg0KBQQBAgMBEgTGAgcTCg0KBQQBAgMDEgTG
AhYXCg0KBQQBAgMIEgTGAhhAChAKCAQBAgMInAgAEgTGAhk/CjEKAgQCEgbKAgDSAgEaIyBU
aGUgTGlzdEZvbGRlcnMgcmVzcG9uc2UgbWVzc2FnZS4KCgsKAwQCARIEygIIGwpzCgQEAgIA
EgTNAgIeGmUgQSBwb3NzaWJseSBwYWdpbmF0ZWQgbGlzdCBvZiBGb2xkZXJzIHRoYXQgYXJl
IGRpcmVjdCBkZXNjZW5kYW50cyBvZgogdGhlIHNwZWNpZmllZCBwYXJlbnQgcmVzb3VyY2Uu
CgoNCgUEAgIABBIEzQICCgoNCgUEAgIABhIEzQILEQoNCgUEAgIAARIEzQISGQoNCgUEAgIA
AxIEzQIcHQqFAQoEBAICARIE0QICHRp3IEEgcGFnaW5hdGlvbiB0b2tlbiByZXR1cm5lZCBm
cm9tIGEgcHJldmlvdXMgY2FsbCB0byBgTGlzdEZvbGRlcnNgCiB0aGF0IGluZGljYXRlcyBm
cm9tIHdoZXJlIGxpc3Rpbmcgc2hvdWxkIGNvbnRpbnVlLgoKDQoFBAICAQUSBNECAggKDQoF
BAICAQESBNECCRgKDQoFBAICAQMSBNECGxwKOgoCBAMSBtUCAPUCARosIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yIHNlYXJjaGluZyBmb2xkZXJzLgoKCwoDBAMBEgTVAggcClIKBAQDAgAS
BNcCAj8aRCBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGZvbGRlcnMgdG8gcmV0
dXJuIGluIHRoZSByZXNwb25zZS4KCg0KBQQDAgAFEgTXAgIHCg0KBQQDAgABEgTXAggRCg0K
BQQDAgADEgTXAhQVCg0KBQQDAgAIEgTXAhY+ChAKCAQDAgAInAgAEgTXAhc9CpEBCgQEAwIB
EgTbAgJBGoIBIE9wdGlvbmFsLiBBIHBhZ2luYXRpb24gdG9rZW4gcmV0dXJuZWQgZnJvbSBh
IHByZXZpb3VzIGNhbGwgdG8gYFNlYXJjaEZvbGRlcnNgCiB0aGF0IGluZGljYXRlcyBmcm9t
IHdoZXJlIHNlYXJjaCBzaG91bGQgY29udGludWUuCgoNCgUEAwIBBRIE2wICCAoNCgUEAwIB
ARIE2wIJEwoNCgUEAwIBAxIE2wIWFwoNCgUEAwIBCBIE2wIYQAoQCggEAwIBCJwIABIE2wIZ
Pwq7CAoEBAMCAhIE9AICExqsCCBTZWFyY2ggY3JpdGVyaWEgdXNlZCB0byBzZWxlY3QgdGhl
IEZvbGRlcnMgdG8gcmV0dXJuLgogSWYgbm8gc2VhcmNoIGNyaXRlcmlhIGlzIHNwZWNpZmll
ZCB0aGVuIGFsbCBhY2Nlc3NpYmxlIGZvbGRlcnMgd2lsbCBiZQogcmV0dXJuZWQuCgogUXVl
cnkgZXhwcmVzc2lvbnMgY2FuIGJlIHVzZWQgdG8gcmVzdHJpY3QgcmVzdWx0cyBiYXNlZCB1
cG9uIGRpc3BsYXlOYW1lLAogbGlmZWN5Y2xlU3RhdGUgYW5kIHBhcmVudCwgd2hlcmUgdGhl
IG9wZXJhdG9ycyBgPWAsIGBOT1RgLCBgQU5EYCBhbmQgYE9SYAogY2FuIGJlIHVzZWQgYWxv
bmcgd2l0aCB0aGUgc3VmZml4IHdpbGRjYXJkIHN5bWJvbCBgKmAuCgogVGhlIGRpc3BsYXlO
YW1lIGZpZWxkIGluIGEgcXVlcnkgZXhwcmVzc2lvbiBzaG91bGQgdXNlIGVzY2FwZWQgcXVv
dGVzCiBmb3IgdmFsdWVzIHRoYXQgaW5jbHVkZSB3aGl0ZXNwYWNlIHRvIHByZXZlbnQgdW5l
eHBlY3RlZCBiZWhhdmlvci4KCiBTb21lIGV4YW1wbGUgcXVlcmllcyBhcmU6CgogKiBRdWVy
eSBgZGlzcGxheU5hbWU9VGVzdCpgIHJldHVybnMgRm9sZGVyIHJlc291cmNlcyB3aG9zZSBk
aXNwbGF5IG5hbWUKIHN0YXJ0cyB3aXRoICJUZXN0Ii4KICogUXVlcnkgYGxpZmVjeWNsZVN0
YXRlPUFDVElWRWAgcmV0dXJucyBGb2xkZXIgcmVzb3VyY2VzIHdpdGgKIGBsaWZlY3ljbGVT
dGF0ZWAgc2V0IHRvIGBBQ1RJVkVgLgogKiBRdWVyeSBgcGFyZW50PWZvbGRlcnMvMTIzYCBy
ZXR1cm5zIEZvbGRlciByZXNvdXJjZXMgdGhhdCBoYXZlCiBgZm9sZGVycy8xMjNgIGFzIGEg
cGFyZW50IHJlc291cmNlLgogKiBRdWVyeSBgcGFyZW50PWZvbGRlcnMvMTIzIEFORCBsaWZl
Y3ljbGVTdGF0ZT1BQ1RJVkVgIHJldHVybnMgYWN0aXZlCiBGb2xkZXIgcmVzb3VyY2VzIHRo
YXQgaGF2ZSBgZm9sZGVycy8xMjNgIGFzIGEgcGFyZW50IHJlc291cmNlLgogKiBRdWVyeSBg
ZGlzcGxheU5hbWU9XFwiVGVzdCBTdHJpbmdcXCJgIHJldHVybnMgRm9sZGVyIHJlc291cmNl
cyB3aXRoCiBkaXNwbGF5IG5hbWVzIHRoYXQgaW5jbHVkZSBib3RoICJUZXN0IiBhbmQgIlN0
cmluZyIuCgoNCgUEAwICBRIE9AICCAoNCgUEAwICARIE9AIJDgoNCgUEAwICAxIE9AIREgo7
CgIEBBIG+AIAgAMBGi0gVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yIHNlYXJjaGluZyBmb2xk
ZXJzLgoKCwoDBAQBEgT4AggdClsKBAQEAgASBPsCAh4aTSBBIHBvc3NpYmx5IHBhZ2luYXRl
ZCBmb2xkZXIgc2VhcmNoIHJlc3VsdHMuCiB0aGUgc3BlY2lmaWVkIHBhcmVudCByZXNvdXJj
ZS4KCg0KBQQEAgAEEgT7AgIKCg0KBQQEAgAGEgT7AgsRCg0KBQQEAgABEgT7AhIZCg0KBQQE
AgADEgT7AhwdCokBCgQEBAIBEgT/AgIdGnsgQSBwYWdpbmF0aW9uIHRva2VuIHJldHVybmVk
IGZyb20gYSBwcmV2aW91cyBjYWxsIHRvIGBTZWFyY2hGb2xkZXJzYAogdGhhdCBpbmRpY2F0
ZXMgZnJvbSB3aGVyZSBzZWFyY2hpbmcgc2hvdWxkIGNvbnRpbnVlLgoKDQoFBAQCAQUSBP8C
AggKDQoFBAQCAQESBP8CCRgKDQoFBAQCAQMSBP8CGxwKLgoCBAUSBoMDAIwDARogIFRoZSBH
ZXRGb2xkZXIgcmVxdWVzdCBtZXNzYWdlLgoKCwoDBAUBEgSDAwgYCnQKBAQFAgASBoYDAosD
BBpkIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRm9sZGVyIHRvIHJldHJp
ZXZlLgogTXVzdCBiZSBvZiB0aGUgZm9ybSBgZm9sZGVycy97Zm9sZGVyX2lkfWAuCgoNCgUE
BQIABRIEhgMCCAoNCgUEBQIAARIEhgMJDQoNCgUEBQIAAxIEhgMQEQoPCgUEBQIACBIGhgMS
iwMDChAKCAQFAgAInAgAEgSHAwQqChEKBwQFAgAInwgSBogDBIoDBQoxCgIEBhIGjwMAnAMB
GiMgVGhlIENyZWF0ZUZvbGRlciByZXF1ZXN0IG1lc3NhZ2UuCgoLCgMEBgESBI8DCBsKkgEK
BAQGAgASBpIDApcDBBqBASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIG5l
dyBGb2xkZXIncyBwYXJlbnQuCiBNdXN0IGJlIG9mIHRoZSBmb3JtIGBmb2xkZXJzL3tmb2xk
ZXJfaWR9YCBvciBgb3JnYW5pemF0aW9ucy97b3JnX2lkfWAuCgoNCgUEBgIABRIEkgMCCAoN
CgUEBgIAARIEkgMJDwoNCgUEBgIAAxIEkgMSEwoPCgUEBgIACBIGkgMUlwMDChAKCAQGAgAI
nAgAEgSTAwQqChEKBwQGAgAInwgSBpQDBJYDBQp/CgQEBgIBEgSbAwI9GnEgUmVxdWlyZWQu
IFRoZSBGb2xkZXIgYmVpbmcgY3JlYXRlZCwgb25seSB0aGUgZGlzcGxheSBuYW1lIHdpbGwg
YmUgY29uc3VsdGVkLgogQWxsIG90aGVyIGZpZWxkcyB3aWxsIGJlIGlnbm9yZWQuCgoNCgUE
BgIBBhIEmwMCCAoNCgUEBgIBARIEmwMJDwoNCgUEBgIBAxIEmwMSEwoNCgUEBgIBCBIEmwMU
PAoQCggEBgIBCJwIABIEmwMVOwovCgIEBxIGnwMAsgMBGiEgVGhlIE1vdmVGb2xkZXIgcmVx
dWVzdCBtZXNzYWdlLgoKCwoDBAcBEgSfAwgZCm0KBAQHAgASBqIDAqcDBBpdIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRm9sZGVyIHRvIG1vdmUuCiBNdXN0IGJlIG9m
IHRoZSBmb3JtIGZvbGRlcnMve2ZvbGRlcl9pZH0KCg0KBQQHAgAFEgSiAwIICg0KBQQHAgAB
EgSiAwkNCg0KBQQHAgADEgSiAxARCg8KBQQHAgAIEgaiAxKnAwMKEAoIBAcCAAicCAASBKMD
BCoKEQoHBAcCAAifCBIGpAMEpgMFCrMBCgQEBwIBEgasAwKxAwQaogEgUmVxdWlyZWQuIFRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBGb2xkZXIgb3IgT3JnYW5pemF0aW9uIHRvIHJlcGFy
ZW50CiB0aGUgZm9sZGVyIHVuZGVyLgogTXVzdCBiZSBvZiB0aGUgZm9ybSBgZm9sZGVycy97
Zm9sZGVyX2lkfWAgb3IgYG9yZ2FuaXphdGlvbnMve29yZ19pZH1gLgoKDQoFBAcCAQUSBKwD
AggKDQoFBAcCAQESBKwDCRsKDQoFBAcCAQMSBKwDHh8KDwoFBAcCAQgSBqwDILEDAwoQCggE
BwIBCJwIABIErQMEKgoRCgcEBwIBCJ8IEgauAwSwAwUKSQoCBAgSBrUDAL4DARo7IFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yIHVwZGF0aW5nIGEgZm9sZGVyJ3MgZGlzcGxheSBuYW1lLgoK
CwoDBAgBEgS1AwgbCpUBCgQECAIAEgS5AwI9GoYBIFJlcXVpcmVkLiBUaGUgbmV3IGRlZmlu
aXRpb24gb2YgdGhlIEZvbGRlci4gSXQgbXVzdCBpbmNsdWRlIGEKIGEgYG5hbWVgIGFuZCBg
ZGlzcGxheV9uYW1lYCBmaWVsZC4gVGhlIG90aGVyIGZpZWxkcwogd2lsbCBiZSBpZ25vcmVk
LgoKDQoFBAgCAAYSBLkDAggKDQoFBAgCAAESBLkDCQ8KDQoFBAgCAAMSBLkDEhMKDQoFBAgC
AAgSBLkDFDwKEAoIBAgCAAicCAASBLkDFTsKWAoEBAgCARIEvQMCVRpKIFJlcXVpcmVkLiBG
aWVsZHMgdG8gYmUgdXBkYXRlZC4KIE9ubHkgdGhlIGBkaXNwbGF5X25hbWVgIGNhbiBiZSB1
cGRhdGVkLgoKDQoFBAgCAQYSBL0DAhsKDQoFBAgCAQESBL0DHCcKDQoFBAgCAQMSBL0DKisK
DQoFBAgCAQgSBL0DLFQKEAoIBAgCAQicCAASBL0DLVMKMQoCBAkSBsEDAM4DARojIFRoZSBE
ZWxldGVGb2xkZXIgcmVxdWVzdCBtZXNzYWdlLgoKCwoDBAkBEgTBAwgbCnYKBAQJAgASBsQD
AskDBBpmIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRm9sZGVyIHRvIGJl
IGRlbGV0ZWQuCiBNdXN0IGJlIG9mIHRoZSBmb3JtIGBmb2xkZXJzL3tmb2xkZXJfaWR9YC4K
Cg0KBQQJAgAFEgTEAwIICg0KBQQJAgABEgTEAwkNCg0KBQQJAgADEgTEAxARCg8KBQQJAgAI
EgbEAxLJAwMKEAoIBAkCAAicCAASBMUDBCoKEQoHBAkCAAifCBIGxgMEyAMFCmMKBAQJAgES
BM0DAhwaVSBJbnN0cnVjdHMgRGVsZXRlRm9sZGVyQWN0aW9uIHRvIGRlbGV0ZSBhIGZvbGRl
ciBldmVuIHdoZW4gdGhlIGZvbGRlciBpcyBub3QKIGVtcHR5LgoKDQoFBAkCAQUSBM0DAgYK
DQoFBAkCAQESBM0DBxcKDQoFBAkCAQMSBM0DGhsKMwoCBAoSBtEDANoDARolIFRoZSBVbmRl
bGV0ZUZvbGRlciByZXF1ZXN0IG1lc3NhZ2UuCgoLCgMECgESBNEDCB0KdAoEBAoCABIG1AMC
2QMEGmQgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBGb2xkZXIgdG8gdW5k
ZWxldGUuCiBNdXN0IGJlIG9mIHRoZSBmb3JtIGBmb2xkZXJzL3tmb2xkZXJfaWR9YC4KCg0K
BQQKAgAFEgTUAwIICg0KBQQKAgABEgTUAwkNCg0KBQQKAgADEgTUAxARCg8KBQQKAgAIEgbU
AxLZAwMKEAoIBAoCAAicCAASBNUDBCoKEQoHBAoCAAifCBIG1gME2AMFCkMKAgQLEgbdAwD3
AwEaNSBNZXRhZGF0YSBkZXNjcmliaW5nIGEgbG9uZyBydW5uaW5nIGZvbGRlciBvcGVyYXRp
b24KCgsKAwQLARIE3QMIFwo0CgQECwQAEgbfAwLoAwMaJCBUaGUgdHlwZSBvZiBvcGVyYXRp
b24gdGhhdCBmYWlsZWQuCgoNCgUECwQAARIE3wMHFAovCgYECwQAAgASBOEDBCMaHyBPcGVy
YXRpb24gdHlwZSBub3Qgc3BlY2lmaWVkLgoKDwoHBAsEAAIAARIE4QMEHgoPCgcECwQAAgAC
EgThAyEiCiwKBgQLBAACARIE5AMEDxocIEEgY3JlYXRlIGZvbGRlciBvcGVyYXRpb24uCgoP
CgcECwQAAgEBEgTkAwQKCg8KBwQLBAACAQISBOQDDQ4KKgoGBAsEAAICEgTnAwQNGhogQSBt
b3ZlIGZvbGRlciBvcGVyYXRpb24uCgoPCgcECwQAAgIBEgTnAwQICg8KBwQLBAACAgISBOcD
CwwKLwoEBAsCABIE6wMCGhohIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGZvbGRlci4KCg0K
BQQLAgAFEgTrAwIICg0KBQQLAgABEgTrAwkVCg0KBQQLAgADEgTrAxgZCisKBAQLAgESBO4D
AiMaHSBUaGUgdHlwZSBvZiB0aGlzIG9wZXJhdGlvbi4KCg0KBQQLAgEGEgTuAwIPCg0KBQQL
AgEBEgTuAxAeCg0KBQQLAgEDEgTuAyEiCmsKBAQLAgISBPIDAhsaXSBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZm9sZGVyJ3MgcGFyZW50LgogT25seSBhcHBsaWNhYmxlIHdoZW4gdGhl
IG9wZXJhdGlvbl90eXBlIGlzIE1PVkUuCgoNCgUECwICBRIE8gMCCAoNCgUECwICARIE8gMJ
FgoNCgUECwICAxIE8gMZGgqBAQoEBAsCAxIE9gMCIBpzIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBmb2xkZXIgb3Igb3JnYW5pemF0aW9uIHdlIGFyZSBlaXRoZXIgY3JlYXRpbmcKIHRo
ZSBmb2xkZXIgdW5kZXIgb3IgbW92aW5nIHRoZSBmb2xkZXIgdG8uCgoNCgUECwIDBRIE9gMC
CAoNCgUECwIDARIE9gMJGwoNCgUECwIDAxIE9gMeH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Resourcemanager::V2::Folders::Folder ===
    # Fields for Folder
    # Field: name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: lifecycle_state Type: 14 (.google.cloud.resourcemanager.v2.Folder.LifecycleState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Folder::LifecycleState
our $Folder_LIFECYCLE_STATE_UNSPECIFIED = 0;
our $Folder_ACTIVE = 1;
our $Folder_DELETE_REQUESTED = 2;

# === Message: Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest ===
    # Fields for ListFoldersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: show_deleted Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse ===
    # Fields for ListFoldersResponse
    # Field: folders Type: 11 (.google.cloud.resourcemanager.v2.Folder)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest ===
    # Fields for SearchFoldersRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: query Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse ===
    # Fields for SearchFoldersResponse
    # Field: folders Type: 11 (.google.cloud.resourcemanager.v2.Folder)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest ===
    # Fields for GetFolderRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest ===
    # Fields for CreateFolderRequest
    # Field: parent Type: 9 ()
    # Field: folder Type: 11 (.google.cloud.resourcemanager.v2.Folder)

# === Message: Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest ===
    # Fields for MoveFolderRequest
    # Field: name Type: 9 ()
    # Field: destination_parent Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest ===
    # Fields for UpdateFolderRequest
    # Field: folder Type: 11 (.google.cloud.resourcemanager.v2.Folder)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest ===
    # Fields for DeleteFolderRequest
    # Field: name Type: 9 ()
    # Field: recursive_delete Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest ===
    # Fields for UndeleteFolderRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V2::Folders::FolderOperation ===
    # Fields for FolderOperation
    # Field: display_name Type: 9 ()
    # Field: operation_type Type: 14 (.google.cloud.resourcemanager.v2.FolderOperation.OperationType)
    # Field: source_parent Type: 9 ()
    # Field: destination_parent Type: 9 ()

# Enum: FolderOperation::OperationType
our $FolderOperation_OPERATION_TYPE_UNSPECIFIED = 0;
our $FolderOperation_CREATE = 1;
our $FolderOperation_MOVE = 2;

# === Service Client: Google::Cloud::Resourcemanager::V2::Folders::FoldersClient ===
package Google::Cloud::Resourcemanager::V2::Folders::FoldersClient;

=pod

=head2 Service Client: Google::Cloud::Resourcemanager::V2::Folders::FoldersClient

Client stub representing the remote C<Folders> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<resourcemanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'resourcemanager.googleapis.com:443' );

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

sub list_folders {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'ListFolders',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse',
    });
}

sub search_folders {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'SearchFolders',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse',
    });
}

sub get_folder {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'GetFolder',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V2::Folders::Folder',
    });
}

sub create_folder {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'CreateFolder',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_folder {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'UpdateFolder',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V2::Folders::Folder',
    });
}

sub move_folder {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'MoveFolder',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_folder {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'DeleteFolder',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V2::Folders::Folder',
    });
}

sub undelete_folder {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'UndeleteFolder',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V2::Folders::Folder',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v2.Folders',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Resourcemanager::V2::Folders - Compiled Protocol Buffers messages for google/cloud/resourcemanager/v2/folders.proto

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V2::Folders;

    my $msg = Google::Cloud::Resourcemanager::V2::Folders::Folder->new({
        name => $name,
        parent => $parent,
        display_name => $display_name,
        lifecycle_state => $lifecycle_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Resourcemanager::V2::Folders::Folder->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/resourcemanager/v2/folders.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Resourcemanager::V2::Folders::Folder

A Folder in an Organization's resource hierarchy, used to
organize that Organization's resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the Folder.
Its format is `folders/{folder_id}`, for example: "folders/1234".

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Folder’s parent's resource name.
Updates to the folder's parent must be performed via
[MoveFolder][google.cloud.resourcemanager.v2.Folders.MoveFolder].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The folder’s display name.
A folder’s display name must be unique amongst its siblings, e.g.
no two folders with the same parent can share the same display name.
The display name must start and end with a letter or digit, may contain
letters, digits, spaces, hyphens and underscores and can be no longer
than 30 characters. This is captured by the regular expression:
[\p{L}\p{N}]([\p{L}\p{N}_- ]{0,28}[\p{L}\p{N}])?.

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Resourcemanager::V2::Folder::LifecycleState>)

Output only. The lifecycle state of the folder.
Updates to the lifecycle_state must be performed via
[DeleteFolder][google.cloud.resourcemanager.v2.Folders.DeleteFolder] and
[UndeleteFolder][google.cloud.resourcemanager.v2.Folders.UndeleteFolder].

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Folder was created. Assigned by the server.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Folder was last modified.

=back

=head3 Enum: Folder::LifecycleState

=over 4

=item * C<LIFECYCLE_STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<DELETE_REQUESTED> => C<2>

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest

The ListFolders request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the Organization or Folder whose Folders are
being listed.
Must be of the form `folders/{folder_id}` or `organizations/{org_id}`.
Access to this method is controlled by checking the
`resourcemanager.folders.list` permission on the `parent`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of Folders to return in the response.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to `ListFolders`
that indicates where this listing should continue from.

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

Optional. Controls whether Folders in the
[DELETE_REQUESTED][google.cloud.resourcemanager.v2.Folder.LifecycleState.DELETE_REQUESTED]
state should be returned. Defaults to false.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse

The ListFolders response message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->folders() >> / C<< $msg->folders($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V2::Folders::Folder>)

A possibly paginated list of Folders that are direct descendants of
the specified parent resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to `ListFolders`
that indicates from where listing should continue.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest

The request message for searching folders.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of folders to return in the response.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to `SearchFolders`
that indicates from where search should continue.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Search criteria used to select the Folders to return.
If no search criteria is specified then all accessible folders will be
returned.

Query expressions can be used to restrict results based upon displayName,
lifecycleState and parent, where the operators `=`, `NOT`, `AND` and `OR`
can be used along with the suffix wildcard symbol `*`.

The displayName field in a query expression should use escaped quotes
for values that include whitespace to prevent unexpected behavior.

Some example queries are:

* Query `displayName=Test*` returns Folder resources whose display name
starts with "Test".
* Query `lifecycleState=ACTIVE` returns Folder resources with
`lifecycleState` set to `ACTIVE`.
* Query `parent=folders/123` returns Folder resources that have
`folders/123` as a parent resource.
* Query `parent=folders/123 AND lifecycleState=ACTIVE` returns active
Folder resources that have `folders/123` as a parent resource.
* Query `displayName=\\"Test String\\"` returns Folder resources with
display names that include both "Test" and "String".

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse

The response message for searching folders.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->folders() >> / C<< $msg->folders($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V2::Folders::Folder>)

A possibly paginated folder search results.
the specified parent resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token returned from a previous call to `SearchFolders`
that indicates from where searching should continue.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest

The GetFolder request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Folder to retrieve.
Must be of the form `folders/{folder_id}`.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest

The CreateFolder request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the new Folder's parent.
Must be of the form `folders/{folder_id}` or `organizations/{org_id}`.

=item * C<< $msg->folder() >> / C<< $msg->folder($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V2::Folders::Folder>)

Required. The Folder being created, only the display name will be consulted.
All other fields will be ignored.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest

The MoveFolder request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Folder to move.
Must be of the form folders/{folder_id}

=item * C<< $msg->destination_parent() >> / C<< $msg->destination_parent($value) >>

Type: C<String>

Required. The resource name of the Folder or Organization to reparent
the folder under.
Must be of the form `folders/{folder_id}` or `organizations/{org_id}`.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest

The request message for updating a folder's display name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->folder() >> / C<< $msg->folder($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V2::Folders::Folder>)

Required. The new definition of the Folder. It must include a
a `name` and `display_name` field. The other fields
will be ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Fields to be updated.
Only the `display_name` can be updated.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest

The DeleteFolder request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Folder to be deleted.
Must be of the form `folders/{folder_id}`.

=item * C<< $msg->recursive_delete() >> / C<< $msg->recursive_delete($value) >>

Type: C<Bool>

Instructs DeleteFolderAction to delete a folder even when the folder is not
empty.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest

The UndeleteFolder request message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Folder to undelete.
Must be of the form `folders/{folder_id}`.

=back

=head2 Google::Cloud::Resourcemanager::V2::Folders::FolderOperation

Metadata describing a long running folder operation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the folder.

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Resourcemanager::V2::FolderOperation::OperationType>)

The type of this operation.

=item * C<< $msg->source_parent() >> / C<< $msg->source_parent($value) >>

Type: C<String>

The resource name of the folder's parent.
Only applicable when the operation_type is MOVE.

=item * C<< $msg->destination_parent() >> / C<< $msg->destination_parent($value) >>

Type: C<String>

The resource name of the folder or organization we are either creating
the folder under or moving the folder to.

=back

=head3 Enum: FolderOperation::OperationType

=over 4

=item * C<OPERATION_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE> => C<1>

=item * C<MOVE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Resourcemanager::V2::Folders::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
