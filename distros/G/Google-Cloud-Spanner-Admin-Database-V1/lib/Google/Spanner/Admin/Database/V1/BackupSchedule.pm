package Google::Spanner::Admin::Database::V1::BackupSchedule;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Spanner::Admin::Database::V1::Backup };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvc3Bhbm5lci9hZG1pbi9kYXRhYmFzZS92MS9iYWNrdXBfc2NoZWR1bGUucHJv
dG8SIGdvb2dsZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJv
dG9idWYvZHVyYXRpb24ucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGi1nb29nbGUvc3Bhbm5lci9hZG1p
bi9kYXRhYmFzZS92MS9iYWNrdXAucHJvdG8icwoSQmFja3VwU2NoZWR1bGVTcGVjEkwKCWNy
b25fc3BlYxgBIAEoCzItLmdvb2dsZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxLkNyb250
YWJTcGVjSABSCGNyb25TcGVjQg8KDXNjaGVkdWxlX3NwZWMiiAYKDkJhY2t1cFNjaGVkdWxl
EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJNCgRzcGVjGAYgASgLMjQuZ29vZ2xlLnNwYW5u
ZXIuYWRtaW4uZGF0YWJhc2UudjEuQmFja3VwU2NoZWR1bGVTcGVjQgPgQQFSBHNwZWMSTQoS
cmV0ZW50aW9uX2R1cmF0aW9uGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPg
QQFSEXJldGVudGlvbkR1cmF0aW9uEnAKEWVuY3J5cHRpb25fY29uZmlnGAQgASgLMj4uZ29v
Z2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2UudjEuQ3JlYXRlQmFja3VwRW5jcnlwdGlvbkNv
bmZpZ0ID4EEBUhBlbmNyeXB0aW9uQ29uZmlnElwKEGZ1bGxfYmFja3VwX3NwZWMYByABKAsy
MC5nb29nbGUuc3Bhbm5lci5hZG1pbi5kYXRhYmFzZS52MS5GdWxsQmFja3VwU3BlY0gAUg5m
dWxsQmFja3VwU3BlYxJxChdpbmNyZW1lbnRhbF9iYWNrdXBfc3BlYxgIIAEoCzI3Lmdvb2ds
ZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxLkluY3JlbWVudGFsQmFja3VwU3BlY0gAUhVp
bmNyZW1lbnRhbEJhY2t1cFNwZWMSQAoLdXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWU6pQHqQaEBCiVzcGFubmVyLmdvb2ds
ZWFwaXMuY29tL0JhY2t1cFNjaGVkdWxlEldwcm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2Vz
L3tpbnN0YW5jZX0vZGF0YWJhc2VzL3tkYXRhYmFzZX0vYmFja3VwU2NoZWR1bGVzL3tzY2hl
ZHVsZX0qD2JhY2t1cFNjaGVkdWxlczIOYmFja3VwU2NoZWR1bGVCEgoQYmFja3VwX3R5cGVf
c3BlYyKRAQoLQ3JvbnRhYlNwZWMSFwoEdGV4dBgBIAEoCUID4EECUgR0ZXh0EiAKCXRpbWVf
em9uZRgCIAEoCUID4EEDUgh0aW1lWm9uZRJHCg9jcmVhdGlvbl93aW5kb3cYAyABKAsyGS5n
b29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBA1IOY3JlYXRpb25XaW5kb3ci8QEKG0NyZWF0
ZUJhY2t1cFNjaGVkdWxlUmVxdWVzdBI/CgZwYXJlbnQYASABKAlCJ+BBAvpBIQofc3Bhbm5l
ci5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZVIGcGFyZW50EjEKEmJhY2t1cF9zY2hlZHVsZV9p
ZBgCIAEoCUID4EECUhBiYWNrdXBTY2hlZHVsZUlkEl4KD2JhY2t1cF9zY2hlZHVsZRgDIAEo
CzIwLmdvb2dsZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxLkJhY2t1cFNjaGVkdWxlQgPg
QQJSDmJhY2t1cFNjaGVkdWxlIl0KGEdldEJhY2t1cFNjaGVkdWxlUmVxdWVzdBJBCgRuYW1l
GAEgASgJQi3gQQL6QScKJXNwYW5uZXIuZ29vZ2xlYXBpcy5jb20vQmFja3VwU2NoZWR1bGVS
BG5hbWUiYAobRGVsZXRlQmFja3VwU2NoZWR1bGVSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBB
AvpBJwolc3Bhbm5lci5nb29nbGVhcGlzLmNvbS9CYWNrdXBTY2hlZHVsZVIEbmFtZSKjAQoa
TGlzdEJhY2t1cFNjaGVkdWxlc1JlcXVlc3QSPwoGcGFyZW50GAEgASgJQifgQQL6QSEKH3Nw
YW5uZXIuZ29vZ2xlYXBpcy5jb20vRGF0YWJhc2VSBnBhcmVudBIgCglwYWdlX3NpemUYAiAB
KAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgEIAEoCUID4EEBUglwYWdlVG9rZW4i
ogEKG0xpc3RCYWNrdXBTY2hlZHVsZXNSZXNwb25zZRJbChBiYWNrdXBfc2NoZWR1bGVzGAEg
AygLMjAuZ29vZ2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2UudjEuQmFja3VwU2NoZWR1bGVS
D2JhY2t1cFNjaGVkdWxlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4ivwEKG1VwZGF0ZUJhY2t1cFNjaGVkdWxlUmVxdWVzdBJeCg9iYWNrdXBfc2NoZWR1bGUY
ASABKAsyMC5nb29nbGUuc3Bhbm5lci5hZG1pbi5kYXRhYmFzZS52MS5CYWNrdXBTY2hlZHVs
ZUID4EECUg5iYWNrdXBTY2hlZHVsZRJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFza0KFAgokY29tLmdvb2dsZS5zcGFu
bmVyLmFkbWluLmRhdGFiYXNlLnYxQhNCYWNrdXBTY2hlZHVsZVByb3RvUAFaRmNsb3VkLmdv
b2dsZS5jb20vZ28vc3Bhbm5lci9hZG1pbi9kYXRhYmFzZS9hcGl2MS9kYXRhYmFzZXBiO2Rh
dGFiYXNlcGKqAiZHb29nbGUuQ2xvdWQuU3Bhbm5lci5BZG1pbi5EYXRhYmFzZS5WMcoCJkdv
b2dsZVxDbG91ZFxTcGFubmVyXEFkbWluXERhdGFiYXNlXFYx6gIrR29vZ2xlOjpDbG91ZDo6
U3Bhbm5lcjo6QWRtaW46OkRhdGFiYXNlOjpWMUqVRQoHEgUOAOUBAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQAKAoJCgIDAxIDFQAqCgkKAgMEEgMWACkKCQoCAwUSAxcANwoICgEIEgMZAEMK
CQoCCCUSAxkAQwoICgEIEgMaAF0KCQoCCAsSAxoAXQoICgEIEgMbACIKCQoCCAoSAxsAIgoI
CgEIEgMcADQKCQoCCAgSAxwANAoICgEIEgMdAD0KCQoCCAESAx0APQoICgEIEgMeAEUKCQoC
CCkSAx4ARQoICgEIEgMfAEQKCQoCCC0SAx8ARAo8CgIEABIEIgAoARowIERlZmluZXMgc3Bl
Y2lmaWNhdGlvbnMgb2YgdGhlIGJhY2t1cCBzY2hlZHVsZS4KCgoKAwQAARIDIggaChkKBAQA
CAASBCQCJwMaCyBSZXF1aXJlZC4KCgwKBQQACAABEgMkCBUKMQoEBAACABIDJgQeGiQgQ3Jv
biBzdHlsZSBzY2hlZHVsZSBzcGVjaWZpY2F0aW9uLgoKDAoFBAACAAYSAyYEDwoMCgUEAAIA
ARIDJhAZCgwKBQQAAgADEgMmHB0KeAoCBAESBC0AXwEabCBCYWNrdXBTY2hlZHVsZSBleHBy
ZXNzZXMgdGhlIGF1dG9tYXRlZCBiYWNrdXAgY3JlYXRpb24gc3BlY2lmaWNhdGlvbiBmb3Ig
YQogU3Bhbm5lciBkYXRhYmFzZS4KIE5leHQgSUQ6IDEwCgoKCgMEAQESAy0IFgoLCgMEAQcS
BC4CMwQKDQoFBAEHnQgSBC4CMwQKkgQKBAQBAgASAz4CPRqEBCBJZGVudGlmaWVyLiBPdXRw
dXQgb25seSBmb3IgdGhlCiBbQ3JlYXRlQmFja3VwU2NoZWR1bGVdW0RhdGFiYXNlQWRtaW4u
Q3JlYXRlQmFja3VwU2NoZWRlZHVsZV0gb3BlcmF0aW9uLgogUmVxdWlyZWQgZm9yIHRoZQog
W1VwZGF0ZUJhY2t1cFNjaGVkdWxlXVtnb29nbGUuc3Bhbm5lci5hZG1pbi5kYXRhYmFzZS52
MS5EYXRhYmFzZUFkbWluLlVwZGF0ZUJhY2t1cFNjaGVkdWxlXQogb3BlcmF0aW9uLiBBIGds
b2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUgYmFja3VwIHNjaGVkdWxlIHdoaWNo
CiBjYW5ub3QgYmUgY2hhbmdlZC4gVmFsdWVzIGFyZSBvZiB0aGUgZm9ybQogYHByb2plY3Rz
Lzxwcm9qZWN0Pi9pbnN0YW5jZXMvPGluc3RhbmNlPi9kYXRhYmFzZXMvPGRhdGFiYXNlPi9i
YWNrdXBTY2hlZHVsZXMvW2Etel1bYS16MC05X1wtXSpbYS16MC05XWAKIFRoZSBmaW5hbCBz
ZWdtZW50IG9mIHRoZSBuYW1lIG11c3QgYmUgYmV0d2VlbiAyIGFuZCA2MCBjaGFyYWN0ZXJz
IGluCiBsZW5ndGguCgoMCgUEAQIABRIDPgIICgwKBQQBAgABEgM+CQ0KDAoFBAECAAMSAz4Q
EQoMCgUEAQIACBIDPhI8Cg8KCAQBAgAInAgAEgM+EzsKZwoEBAECARIDQgJHGlogT3B0aW9u
YWwuIFRoZSBzY2hlZHVsZSBzcGVjaWZpY2F0aW9uIGJhc2VkIG9uIHdoaWNoIHRoZSBiYWNr
dXAgY3JlYXRpb25zCiBhcmUgdHJpZ2dlcmVkLgoKDAoFBAECAQYSA0ICFAoMCgUEAQIBARID
QhUZCgwKBQQBAgEDEgNCHB0KDAoFBAECAQgSA0IeRgoPCggEAQIBCJwIABIDQh9FCs0BCgQE
AQICEgRHAkgvGr4BIE9wdGlvbmFsLiBUaGUgcmV0ZW50aW9uIGR1cmF0aW9uIG9mIGEgYmFj
a3VwIHRoYXQgbXVzdCBiZSBhdCBsZWFzdCA2IGhvdXJzCiBhbmQgYXQgbW9zdCAzNjYgZGF5
cy4gVGhlIGJhY2t1cCBpcyBlbGlnaWJsZSB0byBiZSBhdXRvbWF0aWNhbGx5IGRlbGV0ZWQK
IG9uY2UgdGhlIHJldGVudGlvbiBwZXJpb2QgaGFzIGVsYXBzZWQuCgoMCgUEAQICBhIDRwIa
CgwKBQQBAgIBEgNHGy0KDAoFBAECAgMSA0cwMQoMCgUEAQICCBIDSAYuCg8KCAQBAgIInAgA
EgNIBy0KyQEKBAQBAgMSBE0CTi8augEgT3B0aW9uYWwuIFRoZSBlbmNyeXB0aW9uIGNvbmZp
Z3VyYXRpb24gdGhhdCB3aWxsIGJlIHVzZWQgdG8gZW5jcnlwdCB0aGUKIGJhY2t1cC4gSWYg
dGhpcyBmaWVsZCBpcyBub3Qgc3BlY2lmaWVkLCB0aGUgYmFja3VwIHdpbGwgdXNlIHRoZSBz
YW1lCiBlbmNyeXB0aW9uIGNvbmZpZ3VyYXRpb24gYXMgdGhlIGRhdGFiYXNlLgoKDAoFBAEC
AwYSA00CHgoMCgUEAQIDARIDTR8wCgwKBQQBAgMDEgNNMzQKDAoFBAECAwgSA04GLgoPCggE
AQIDCJwIABIDTgctCp4BCgQEAQgAEgRSAlgDGo8BIFJlcXVpcmVkLiBCYWNrdXAgdHlwZSBz
cGVjIGRldGVybWluZXMgdGhlIHR5cGUgb2YgYmFja3VwIHRoYXQgaXMgY3JlYXRlZCBieQog
dGhlIGJhY2t1cCBzY2hlZHVsZS4gQ3VycmVudGx5LCBvbmx5IGZ1bGwgYmFja3VwcyBhcmUg
c3VwcG9ydGVkLgoKDAoFBAEIAAESA1IIGAo2CgQEAQIEEgNUBCgaKSBUaGUgc2NoZWR1bGUg
Y3JlYXRlcyBvbmx5IGZ1bGwgYmFja3Vwcy4KCgwKBQQBAgQGEgNUBBIKDAoFBAECBAESA1QT
IwoMCgUEAQIEAxIDVCYnCj4KBAQBAgUSA1cENhoxIFRoZSBzY2hlZHVsZSBjcmVhdGVzIGlu
Y3JlbWVudGFsIGJhY2t1cCBjaGFpbnMuCgoMCgUEAQIFBhIDVwQZCgwKBQQBAgUBEgNXGjEK
DAoFBAECBQMSA1c0NQrEAQoEBAECBhIEXQJeMhq1ASBPdXRwdXQgb25seS4gVGhlIHRpbWVz
dGFtcCBhdCB3aGljaCB0aGUgc2NoZWR1bGUgd2FzIGxhc3QgdXBkYXRlZC4KIElmIHRoZSBz
Y2hlZHVsZSBoYXMgbmV2ZXIgYmVlbiB1cGRhdGVkLCB0aGlzIGZpZWxkIGNvbnRhaW5zIHRo
ZSB0aW1lc3RhbXAKIHdoZW4gdGhlIHNjaGVkdWxlIHdhcyBmaXJzdCBjcmVhdGVkLgoKDAoF
BAECBgYSA10CGwoMCgUEAQIGARIDXRwnCgwKBQQBAgYDEgNdKisKDAoFBAECBggSA14GMQoP
CggEAQIGCJwIABIDXgcwCncKAgQCEgRjAH8BGmsgQ3JvbnRhYlNwZWMgY2FuIGJlIHVzZWQg
dG8gc3BlY2lmeSB0aGUgdmVyc2lvbiB0aW1lIGFuZCBmcmVxdWVuY3kgYXQKIHdoaWNoIHRo
ZSBiYWNrdXAgc2hvdWxkIGJlIGNyZWF0ZWQuCgoKCgMEAgESA2MIEwr4BQoEBAICABIDcAI7
GuoFIFJlcXVpcmVkLiBUZXh0dWFsIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBjcm9udGFiLiBV
c2VyIGNhbiBjdXN0b21pemUgdGhlCiBiYWNrdXAgZnJlcXVlbmN5IGFuZCB0aGUgYmFja3Vw
IHZlcnNpb24gdGltZSB1c2luZyB0aGUgY3JvbgogZXhwcmVzc2lvbi4gVGhlIHZlcnNpb24g
dGltZSBtdXN0IGJlIGluIFVUQyB0aW1lem9uZS4KCiBUaGUgYmFja3VwIHdpbGwgY29udGFp
biBhbiBleHRlcm5hbGx5IGNvbnNpc3RlbnQgY29weSBvZiB0aGUKIGRhdGFiYXNlIGF0IHRo
ZSB2ZXJzaW9uIHRpbWUuIEFsbG93ZWQgZnJlcXVlbmNpZXMgYXJlIDEyIGhvdXIsIDEgZGF5
LAogMSB3ZWVrIGFuZCAxIG1vbnRoLiBFeGFtcGxlcyBvZiB2YWxpZCBjcm9uIHNwZWNpZmlj
YXRpb25zOgogICAqIGAwIDIvMTIgKiAqICogYCA6IGV2ZXJ5IDEyIGhvdXJzIGF0ICgyLCAx
NCkgaG91cnMgcGFzdCBtaWRuaWdodCBpbiBVVEMuCiAgICogYDAgMiwxNCAqICogKiBgIDog
ZXZlcnkgMTIgaG91cnMgYXQgKDIsMTQpIGhvdXJzIHBhc3QgbWlkbmlnaHQgaW4gVVRDLgog
ICAqIGAwIDIgKiAqICogYCAgICA6IG9uY2UgYSBkYXkgYXQgMiBwYXN0IG1pZG5pZ2h0IGlu
IFVUQy4KICAgKiBgMCAyICogKiAwIGAgICAgOiBvbmNlIGEgd2VlayBldmVyeSBTdW5kYXkg
YXQgMiBwYXN0IG1pZG5pZ2h0IGluIFVUQy4KICAgKiBgMCAyIDggKiAqIGAgICAgOiBvbmNl
IGEgbW9udGggb24gOHRoIGRheSBhdCAyIHBhc3QgbWlkbmlnaHQgaW4gVVRDLgoKDAoFBAIC
AAUSA3ACCAoMCgUEAgIAARIDcAkNCgwKBQQCAgADEgNwEBEKDAoFBAICAAgSA3ASOgoPCggE
AgIACJwIABIDcBM5Cm8KBAQCAgESA3QCQxpiIE91dHB1dCBvbmx5LiBUaGUgdGltZSB6b25l
IG9mIHRoZSB0aW1lcyBpbiBgQ3JvbnRhYlNwZWMudGV4dGAuIEN1cnJlbnRseQogb25seSBV
VEMgaXMgc3VwcG9ydGVkLgoKDAoFBAICAQUSA3QCCAoMCgUEAgIBARIDdAkSCgwKBQQCAgED
EgN0FRYKDAoFBAICAQgSA3QXQgoPCggEAgIBCJwIABIDdBhBCsEDCgQEAgICEgR9An4yGrID
IE91dHB1dCBvbmx5LiBTY2hlZHVsZSBiYWNrdXBzIHdpbGwgY29udGFpbiBhbiBleHRlcm5h
bGx5IGNvbnNpc3RlbnQgY29weQogb2YgdGhlIGRhdGFiYXNlIGF0IHRoZSB2ZXJzaW9uIHRp
bWUgc3BlY2lmaWVkIGluCiBgc2NoZWR1bGVfc3BlYy5jcm9uX3NwZWNgLiBIb3dldmVyLCBT
cGFubmVyIG1heSBub3QgaW5pdGlhdGUgdGhlIGNyZWF0aW9uCiBvZiB0aGUgc2NoZWR1bGVk
IGJhY2t1cHMgYXQgdGhhdCB2ZXJzaW9uIHRpbWUuIFNwYW5uZXIgd2lsbCBpbml0aWF0ZQog
dGhlIGNyZWF0aW9uIG9mIHNjaGVkdWxlZCBiYWNrdXBzIHdpdGhpbiB0aGUgdGltZSB3aW5k
b3cgYm91bmRlZCBieSB0aGUKIHZlcnNpb25fdGltZSBzcGVjaWZpZWQgaW4gYHNjaGVkdWxl
X3NwZWMuY3Jvbl9zcGVjYCBhbmQgdmVyc2lvbl90aW1lICsKIGBjcmVhdGlvbl93aW5kb3dg
LgoKDAoFBAICAgYSA30CGgoMCgUEAgICARIDfRsqCgwKBQQCAgIDEgN9LS4KDAoFBAICAggS
A34GMQoPCggEAgICCJwIABIDfgcwCn0KAgQDEgaDAQCTAQEabyBUaGUgcmVxdWVzdCBmb3IK
IFtDcmVhdGVCYWNrdXBTY2hlZHVsZV1bZ29vZ2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2Uu
djEuRGF0YWJhc2VBZG1pbi5DcmVhdGVCYWNrdXBTY2hlZHVsZV0uCgoLCgMEAwESBIMBCCMK
WgoEBAMCABIGhQECigEEGkogUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBkYXRhYmFzZSB0
aGF0IHRoaXMgYmFja3VwIHNjaGVkdWxlIGFwcGxpZXMgdG8uCgoNCgUEAwIABRIEhQECCAoN
CgUEAwIAARIEhQEJDwoNCgUEAwIAAxIEhQESEwoPCgUEAwIACBIGhQEUigEDChAKCAQDAgAI
nAgAEgSGAQQqChEKBwQDAgAInwgSBocBBIkBBQqGAgoEBAMCARIEjwECSRr3ASBSZXF1aXJl
ZC4gVGhlIElkIHRvIHVzZSBmb3IgdGhlIGJhY2t1cCBzY2hlZHVsZS4gVGhlIGBiYWNrdXBf
c2NoZWR1bGVfaWRgCiBhcHBlbmRlZCB0byBgcGFyZW50YCBmb3JtcyB0aGUgZnVsbCBiYWNr
dXAgc2NoZWR1bGUgbmFtZSBvZiB0aGUgZm9ybQogYHByb2plY3RzLzxwcm9qZWN0Pi9pbnN0
YW5jZXMvPGluc3RhbmNlPi9kYXRhYmFzZXMvPGRhdGFiYXNlPi9iYWNrdXBTY2hlZHVsZXMv
PGJhY2t1cF9zY2hlZHVsZV9pZD5gLgoKDQoFBAMCAQUSBI8BAggKDQoFBAMCAQESBI8BCRsK
DQoFBAMCAQMSBI8BHh8KDQoFBAMCAQgSBI8BIEgKEAoIBAMCAQicCAASBI8BIUcKOAoEBAMC
AhIEkgECThoqIFJlcXVpcmVkLiBUaGUgYmFja3VwIHNjaGVkdWxlIHRvIGNyZWF0ZS4KCg0K
BQQDAgIGEgSSAQIQCg0KBQQDAgIBEgSSAREgCg0KBQQDAgIDEgSSASMkCg0KBQQDAgIIEgSS
ASVNChAKCAQDAgIInAgAEgSSASZMCncKAgQEEgaXAQChAQEaaSBUaGUgcmVxdWVzdCBmb3IK
IFtHZXRCYWNrdXBTY2hlZHVsZV1bZ29vZ2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2UudjEu
RGF0YWJhc2VBZG1pbi5HZXRCYWNrdXBTY2hlZHVsZV0uCgoLCgMEBAESBJcBCCAKwAEKBAQE
AgASBpsBAqABBBqvASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNjaGVkdWxlIHRvIHJl
dHJpZXZlLgogVmFsdWVzIGFyZSBvZiB0aGUgZm9ybQogYHByb2plY3RzLzxwcm9qZWN0Pi9p
bnN0YW5jZXMvPGluc3RhbmNlPi9kYXRhYmFzZXMvPGRhdGFiYXNlPi9iYWNrdXBTY2hlZHVs
ZXMvPGJhY2t1cF9zY2hlZHVsZV9pZD5gLgoKDQoFBAQCAAUSBJsBAggKDQoFBAQCAAESBJsB
CQ0KDQoFBAQCAAMSBJsBEBEKDwoFBAQCAAgSBpsBEqABAwoQCggEBAIACJwIABIEnAEEKgoR
CgcEBAIACJ8IEgadAQSfAQUKfQoCBAUSBqUBAK8BARpvIFRoZSByZXF1ZXN0IGZvcgogW0Rl
bGV0ZUJhY2t1cFNjaGVkdWxlXVtnb29nbGUuc3Bhbm5lci5hZG1pbi5kYXRhYmFzZS52MS5E
YXRhYmFzZUFkbWluLkRlbGV0ZUJhY2t1cFNjaGVkdWxlXS4KCgsKAwQFARIEpQEIIwq+AQoE
BAUCABIGqQECrgEEGq0BIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2NoZWR1bGUgdG8g
ZGVsZXRlLgogVmFsdWVzIGFyZSBvZiB0aGUgZm9ybQogYHByb2plY3RzLzxwcm9qZWN0Pi9p
bnN0YW5jZXMvPGluc3RhbmNlPi9kYXRhYmFzZXMvPGRhdGFiYXNlPi9iYWNrdXBTY2hlZHVs
ZXMvPGJhY2t1cF9zY2hlZHVsZV9pZD5gLgoKDQoFBAUCAAUSBKkBAggKDQoFBAUCAAESBKkB
CQ0KDQoFBAUCAAMSBKkBEBEKDwoFBAUCAAgSBqkBEq4BAwoQCggEBQIACJwIABIEqgEEKgoR
CgcEBQIACJ8IEgarAQStAQUKewoCBAYSBrMBAMgBARptIFRoZSByZXF1ZXN0IGZvcgogW0xp
c3RCYWNrdXBTY2hlZHVsZXNdW2dvb2dsZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxLkRh
dGFiYXNlQWRtaW4uTGlzdEJhY2t1cFNjaGVkdWxlc10uCgoLCgMEBgESBLMBCCIKuwEKBAQG
AgASBrcBArwBBBqqASBSZXF1aXJlZC4gRGF0YWJhc2UgaXMgdGhlIHBhcmVudCByZXNvdXJj
ZSB3aG9zZSBiYWNrdXAgc2NoZWR1bGVzIHNob3VsZCBiZQogbGlzdGVkLiBWYWx1ZXMgYXJl
IG9mIHRoZSBmb3JtCiBwcm9qZWN0cy88cHJvamVjdD4vaW5zdGFuY2VzLzxpbnN0YW5jZT4v
ZGF0YWJhc2VzLzxkYXRhYmFzZT4KCg0KBQQGAgAFEgS3AQIICg0KBQQGAgABEgS3AQkPCg0K
BQQGAgADEgS3ARITCg8KBQQGAgAIEga3ARS8AQMKEAoIBAYCAAicCAASBLgBBCoKEQoHBAYC
AAifCBIGuQEEuwEFCpgBCgQEBgIBEgTAAQI/GokBIE9wdGlvbmFsLiBOdW1iZXIgb2YgYmFj
a3VwIHNjaGVkdWxlcyB0byBiZSByZXR1cm5lZCBpbiB0aGUgcmVzcG9uc2UuIElmIDAKIG9y
IGxlc3MsIGRlZmF1bHRzIHRvIHRoZSBzZXJ2ZXIncyBtYXhpbXVtIGFsbG93ZWQgcGFnZSBz
aXplLgoKDQoFBAYCAQUSBMABAgcKDQoFBAYCAQESBMABCBEKDQoFBAYCAQMSBMABFBUKDQoF
BAYCAQgSBMABFj4KEAoIBAYCAQicCAASBMABFz0KrAIKBAQGAgISBMcBAkEanQIgT3B0aW9u
YWwuIElmIG5vbi1lbXB0eSwgYHBhZ2VfdG9rZW5gIHNob3VsZCBjb250YWluIGEKIFtuZXh0
X3BhZ2VfdG9rZW5dW2dvb2dsZS5zcGFubmVyLmFkbWluLmRhdGFiYXNlLnYxLkxpc3RCYWNr
dXBTY2hlZHVsZXNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dCiBmcm9tIGEgcHJldmlvdXMK
IFtMaXN0QmFja3VwU2NoZWR1bGVzUmVzcG9uc2VdW2dvb2dsZS5zcGFubmVyLmFkbWluLmRh
dGFiYXNlLnYxLkxpc3RCYWNrdXBTY2hlZHVsZXNSZXNwb25zZV0KIHRvIHRoZSBzYW1lIGBw
YXJlbnRgLgoKDQoFBAYCAgUSBMcBAggKDQoFBAYCAgESBMcBCRMKDQoFBAYCAgMSBMcBFhcK
DQoFBAYCAggSBMcBGEAKEAoIBAYCAgicCAASBMcBGT8KfAoCBAcSBswBANQBARpuIFRoZSBy
ZXNwb25zZSBmb3IKIFtMaXN0QmFja3VwU2NoZWR1bGVzXVtnb29nbGUuc3Bhbm5lci5hZG1p
bi5kYXRhYmFzZS52MS5EYXRhYmFzZUFkbWluLkxpc3RCYWNrdXBTY2hlZHVsZXNdLgoKCwoD
BAcBEgTMAQgjCjwKBAQHAgASBM4BAi8aLiBUaGUgbGlzdCBvZiBiYWNrdXAgc2NoZWR1bGVz
IGZvciBhIGRhdGFiYXNlLgoKDQoFBAcCAAQSBM4BAgoKDQoFBAcCAAYSBM4BCxkKDQoFBAcC
AAESBM4BGioKDQoFBAcCAAMSBM4BLS4KvwEKBAQHAgESBNMBAh0asAEgYG5leHRfcGFnZV90
b2tlbmAgY2FuIGJlIHNlbnQgaW4gYSBzdWJzZXF1ZW50CiBbTGlzdEJhY2t1cFNjaGVkdWxl
c11bZ29vZ2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2UudjEuRGF0YWJhc2VBZG1pbi5MaXN0
QmFja3VwU2NoZWR1bGVzXQogY2FsbCB0byBmZXRjaCBtb3JlIG9mIHRoZSBzY2hlZHVsZXMu
CgoNCgUEBwIBBRIE0wECCAoNCgUEBwIBARIE0wEJGAoNCgUEBwIBAxIE0wEbHAqEAQoCBAgS
BtgBAOUBARp2IFRoZSByZXF1ZXN0IGZvcgogW1VwZGF0ZUJhY2t1cFNjaGVkdWxlUmVxdWVz
dF1bZ29vZ2xlLnNwYW5uZXIuYWRtaW4uZGF0YWJhc2UudjEuRGF0YWJhc2VBZG1pbi5VcGRh
dGVCYWNrdXBTY2hlZHVsZV0uCgoLCgMECAESBNgBCCMKtgEKBAQIAgASBNwBAk4apwEgUmVx
dWlyZWQuIFRoZSBiYWNrdXAgc2NoZWR1bGUgdG8gdXBkYXRlLiBgYmFja3VwX3NjaGVkdWxl
Lm5hbWVgLCBhbmQgdGhlCiBmaWVsZHMgdG8gYmUgdXBkYXRlZCBhcyBzcGVjaWZpZWQgYnkg
YHVwZGF0ZV9tYXNrYCBhcmUgcmVxdWlyZWQuIE90aGVyCiBmaWVsZHMgYXJlIGlnbm9yZWQu
CgoNCgUECAIABhIE3AECEAoNCgUECAIAARIE3AERIAoNCgUECAIAAxIE3AEjJAoNCgUECAIA
CBIE3AElTQoQCggECAIACJwIABIE3AEmTAqsAgoEBAgCARIG4wEC5AEvGpsCIFJlcXVpcmVk
LiBBIG1hc2sgc3BlY2lmeWluZyB3aGljaCBmaWVsZHMgaW4gdGhlIEJhY2t1cFNjaGVkdWxl
IHJlc291cmNlCiBzaG91bGQgYmUgdXBkYXRlZC4gVGhpcyBtYXNrIGlzIHJlbGF0aXZlIHRv
IHRoZSBCYWNrdXBTY2hlZHVsZSByZXNvdXJjZSwKIG5vdCB0byB0aGUgcmVxdWVzdCBtZXNz
YWdlLiBUaGUgZmllbGQgbWFzayBtdXN0IGFsd2F5cyBiZQogc3BlY2lmaWVkOyB0aGlzIHBy
ZXZlbnRzIGFueSBmdXR1cmUgZmllbGRzIGZyb20gYmVpbmcgZXJhc2VkCiBhY2NpZGVudGFs
bHkuCgoNCgUECAIBBhIE4wECGwoNCgUECAIBARIE4wEcJwoNCgUECAIBAxIE4wEqKwoNCgUE
CAIBCBIE5AEGLgoQCggECAIBCJwIABIE5AEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec ===
    # Fields for BackupScheduleSpec
    # Field: cron_spec Type: 11 (.google.spanner.admin.database.v1.CrontabSpec)

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule ===
    # Fields for BackupSchedule
    # Field: name Type: 9 ()
    # Field: spec Type: 11 (.google.spanner.admin.database.v1.BackupScheduleSpec)
    # Field: retention_duration Type: 11 (.google.protobuf.Duration)
    # Field: encryption_config Type: 11 (.google.spanner.admin.database.v1.CreateBackupEncryptionConfig)
    # Field: full_backup_spec Type: 11 (.google.spanner.admin.database.v1.FullBackupSpec)
    # Field: incremental_backup_spec Type: 11 (.google.spanner.admin.database.v1.IncrementalBackupSpec)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::CrontabSpec ===
    # Fields for CrontabSpec
    # Field: text Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: creation_window Type: 11 (.google.protobuf.Duration)

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::CreateBackupScheduleRequest ===
    # Fields for CreateBackupScheduleRequest
    # Field: parent Type: 9 ()
    # Field: backup_schedule_id Type: 9 ()
    # Field: backup_schedule Type: 11 (.google.spanner.admin.database.v1.BackupSchedule)

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::GetBackupScheduleRequest ===
    # Fields for GetBackupScheduleRequest
    # Field: name Type: 9 ()

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::DeleteBackupScheduleRequest ===
    # Fields for DeleteBackupScheduleRequest
    # Field: name Type: 9 ()

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesRequest ===
    # Fields for ListBackupSchedulesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesResponse ===
    # Fields for ListBackupSchedulesResponse
    # Field: backup_schedules Type: 11 (.google.spanner.admin.database.v1.BackupSchedule)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Spanner::Admin::Database::V1::BackupSchedule::UpdateBackupScheduleRequest ===
    # Fields for UpdateBackupScheduleRequest
    # Field: backup_schedule Type: 11 (.google.spanner.admin.database.v1.BackupSchedule)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::Admin::Database::V1::BackupSchedule - Compiled Protocol Buffers messages for google/spanner/admin/database/v1/backup_schedule.proto

=head1 SYNOPSIS

    use Google::Spanner::Admin::Database::V1::BackupSchedule;

    my $msg = Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec->new({
        cron_spec => $cron_spec,
    });

    # Read or update a field
    my $val = $msg->cron_spec();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/admin/database/v1/backup_schedule.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec

Defines specifications of the backup schedule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cron_spec() >> / C<< $msg->cron_spec($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::BackupSchedule::CrontabSpec>)

Cron style schedule specification.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule

BackupSchedule expresses the automated backup creation specification for a
Spanner database.
Next ID: 10

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Output only for the
[CreateBackupSchedule][DatabaseAdmin.CreateBackupSchededule] operation.
Required for the
[UpdateBackupSchedule][google.spanner.admin.database.v1.DatabaseAdmin.UpdateBackupSchedule]
operation. A globally unique identifier for the backup schedule which
cannot be changed. Values are of the form
`projects/<project>/instances/<instance>/databases/<database>/backupSchedules/[a-z][a-z0-9_\-]*[a-z0-9]`
The final segment of the name must be between 2 and 60 characters in
length.

=item * C<< $msg->spec() >> / C<< $msg->spec($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec>)

Optional. The schedule specification based on which the backup creations
are triggered.

=item * C<< $msg->retention_duration() >> / C<< $msg->retention_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The retention duration of a backup that must be at least 6 hours
and at most 366 days. The backup is eligible to be automatically deleted
once the retention period has elapsed.

=item * C<< $msg->encryption_config() >> / C<< $msg->encryption_config($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::Backup::CreateBackupEncryptionConfig>)

Optional. The encryption configuration that will be used to encrypt the
backup. If this field is not specified, the backup will use the same
encryption configuration as the database.

=item * C<< $msg->full_backup_spec() >> / C<< $msg->full_backup_spec($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::Backup::FullBackupSpec>)

The schedule creates only full backups.

=item * C<< $msg->incremental_backup_spec() >> / C<< $msg->incremental_backup_spec($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::Backup::IncrementalBackupSpec>)

The schedule creates incremental backup chains.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which the schedule was last updated.
If the schedule has never been updated, this field contains the timestamp
when the schedule was first created.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::CrontabSpec

CrontabSpec can be used to specify the version time and frequency at
which the backup should be created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. Textual representation of the crontab. User can customize the
backup frequency and the backup version time using the cron
expression. The version time must be in UTC timezone.

The backup will contain an externally consistent copy of the
database at the version time. Allowed frequencies are 12 hour, 1 day,
1 week and 1 month. Examples of valid cron specifications:
  * `0 2/12 * * * ` : every 12 hours at (2, 14) hours past midnight in UTC.
  * `0 2,14 * * * ` : every 12 hours at (2,14) hours past midnight in UTC.
  * `0 2 * * * `    : once a day at 2 past midnight in UTC.
  * `0 2 * * 0 `    : once a week every Sunday at 2 past midnight in UTC.
  * `0 2 8 * * `    : once a month on 8th day at 2 past midnight in UTC.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Output only. The time zone of the times in `CrontabSpec.text`. Currently
only UTC is supported.

=item * C<< $msg->creation_window() >> / C<< $msg->creation_window($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. Schedule backups will contain an externally consistent copy
of the database at the version time specified in
`schedule_spec.cron_spec`. However, Spanner may not initiate the creation
of the scheduled backups at that version time. Spanner will initiate
the creation of scheduled backups within the time window bounded by the
version_time specified in `schedule_spec.cron_spec` and version_time +
`creation_window`.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::CreateBackupScheduleRequest

The request for
[CreateBackupSchedule][google.spanner.admin.database.v1.DatabaseAdmin.CreateBackupSchedule].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the database that this backup schedule applies to.

=item * C<< $msg->backup_schedule_id() >> / C<< $msg->backup_schedule_id($value) >>

Type: C<String>

Required. The Id to use for the backup schedule. The `backup_schedule_id`
appended to `parent` forms the full backup schedule name of the form
`projects/<project>/instances/<instance>/databases/<database>/backupSchedules/<backup_schedule_id>`.

=item * C<< $msg->backup_schedule() >> / C<< $msg->backup_schedule($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule>)

Required. The backup schedule to create.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::GetBackupScheduleRequest

The request for
[GetBackupSchedule][google.spanner.admin.database.v1.DatabaseAdmin.GetBackupSchedule].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the schedule to retrieve.
Values are of the form
`projects/<project>/instances/<instance>/databases/<database>/backupSchedules/<backup_schedule_id>`.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::DeleteBackupScheduleRequest

The request for
[DeleteBackupSchedule][google.spanner.admin.database.v1.DatabaseAdmin.DeleteBackupSchedule].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the schedule to delete.
Values are of the form
`projects/<project>/instances/<instance>/databases/<database>/backupSchedules/<backup_schedule_id>`.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesRequest

The request for
[ListBackupSchedules][google.spanner.admin.database.v1.DatabaseAdmin.ListBackupSchedules].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Database is the parent resource whose backup schedules should be
listed. Values are of the form
projects/<project>/instances/<instance>/databases/<database>

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Number of backup schedules to be returned in the response. If 0
or less, defaults to the server's maximum allowed page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. If non-empty, `page_token` should contain a
[next_page_token][google.spanner.admin.database.v1.ListBackupSchedulesResponse.next_page_token]
from a previous
[ListBackupSchedulesResponse][google.spanner.admin.database.v1.ListBackupSchedulesResponse]
to the same `parent`.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesResponse

The response for
[ListBackupSchedules][google.spanner.admin.database.v1.DatabaseAdmin.ListBackupSchedules].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_schedules() >> / C<< $msg->backup_schedules($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule>)

The list of backup schedules for a database.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

`next_page_token` can be sent in a subsequent
[ListBackupSchedules][google.spanner.admin.database.v1.DatabaseAdmin.ListBackupSchedules]
call to fetch more of the schedules.

=back

=head2 Google::Spanner::Admin::Database::V1::BackupSchedule::UpdateBackupScheduleRequest

The request for
[UpdateBackupScheduleRequest][google.spanner.admin.database.v1.DatabaseAdmin.UpdateBackupSchedule].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_schedule() >> / C<< $msg->backup_schedule($value) >>

Type: C<Message> (L<Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule>)

Required. The backup schedule to update. `backup_schedule.name`, and the
fields to be updated as specified by `update_mask` are required. Other
fields are ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. A mask specifying which fields in the BackupSchedule resource
should be updated. This mask is relative to the BackupSchedule resource,
not to the request message. The field mask must always be
specified; this prevents any future fields from being erased
accidentally.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::Admin::Database::V1::BackupSchedule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
