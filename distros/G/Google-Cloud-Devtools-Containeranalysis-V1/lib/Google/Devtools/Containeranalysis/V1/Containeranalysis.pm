package Google::Devtools::Containeranalysis::V1::Containeranalysis;

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
    eval { require Grafeas::V1::Severity };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvZGV2dG9vbHMvY29udGFpbmVyYW5hbHlzaXMvdjEvY29udGFpbmVyYW5hbHlz
aXMucHJvdG8SJGdvb2dsZS5kZXZ0b29scy5jb250YWluZXJhbmFseXNpcy52MRocZ29vZ2xl
L2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
Hmdvb2dsZS9pYW0vdjEvaWFtX3BvbGljeS5wcm90bxoaZ29vZ2xlL2lhbS92MS9wb2xpY3ku
cHJvdG8aGWdyYWZlYXMvdjEvc2V2ZXJpdHkucHJvdG8i2gEKEUV4cG9ydFNCT01SZXF1ZXN0
EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRKJAQoWY2xvdWRfc3RvcmFnZV9sb2NhdGlvbhgC
IAEoCzJMLmdvb2dsZS5kZXZ0b29scy5jb250YWluZXJhbmFseXNpcy52MS5FeHBvcnRTQk9N
UmVxdWVzdC5DbG91ZFN0b3JhZ2VMb2NhdGlvbkID4EEBSABSFGNsb3VkU3RvcmFnZUxvY2F0
aW9uGhYKFENsb3VkU3RvcmFnZUxvY2F0aW9uQggKBnRhcmdldCJHChJFeHBvcnRTQk9NUmVz
cG9uc2USMQoUZGlzY292ZXJ5X29jY3VycmVuY2UYASABKAlSE2Rpc2NvdmVyeU9jY3VycmVu
Y2UikAEKKUdldFZ1bG5lcmFiaWxpdHlPY2N1cnJlbmNlc1N1bW1hcnlSZXF1ZXN0EksKBnBh
cmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNv
bS9Qcm9qZWN0UgZwYXJlbnQSFgoGZmlsdGVyGAIgASgJUgZmaWx0ZXIiyQIKH1Z1bG5lcmFi
aWxpdHlPY2N1cnJlbmNlc1N1bW1hcnkScgoGY291bnRzGAEgAygLMlouZ29vZ2xlLmRldnRv
b2xzLmNvbnRhaW5lcmFuYWx5c2lzLnYxLlZ1bG5lcmFiaWxpdHlPY2N1cnJlbmNlc1N1bW1h
cnkuRml4YWJsZVRvdGFsQnlEaWdlc3RSBmNvdW50cxqxAQoURml4YWJsZVRvdGFsQnlEaWdl
c3QSIQoMcmVzb3VyY2VfdXJpGAEgASgJUgtyZXNvdXJjZVVyaRIwCghzZXZlcml0eRgCIAEo
DjIULmdyYWZlYXMudjEuU2V2ZXJpdHlSCHNldmVyaXR5EiMKDWZpeGFibGVfY291bnQYAyAB
KANSDGZpeGFibGVDb3VudBIfCgt0b3RhbF9jb3VudBgEIAEoA1IKdG90YWxDb3VudDKQDgoR
Q29udGFpbmVyQW5hbHlzaXMS2wIKDFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuU2V0
SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5Io8CgtPkkwL2ASIuL3Yx
L3tyZXNvdXJjZT1wcm9qZWN0cy8qL25vdGVzLyp9OnNldElhbVBvbGljeToBKlo5IjQvdjEv
e3Jlc291cmNlPXByb2plY3RzLyovb2NjdXJyZW5jZXMvKn06c2V0SWFtUG9saWN5OgEqWj8i
Oi92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9ub3Rlcy8qfTpzZXRJYW1Q
b2xpY3k6ASpaRSJAL3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL29jY3Vy
cmVuY2VzLyp9OnNldElhbVBvbGljeToBKtpBD3Jlc291cmNlLHBvbGljeRLUAgoMR2V0SWFt
UG9saWN5EiIuZ29vZ2xlLmlhbS52MS5HZXRJYW1Qb2xpY3lSZXF1ZXN0GhUuZ29vZ2xlLmlh
bS52MS5Qb2xpY3kiiAKC0+STAvYBIi4vdjEve3Jlc291cmNlPXByb2plY3RzLyovbm90ZXMv
Kn06Z2V0SWFtUG9saWN5OgEqWjkiNC92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9vY2N1cnJl
bmNlcy8qfTpnZXRJYW1Qb2xpY3k6ASpaPyI6L3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL25vdGVzLyp9OmdldElhbVBvbGljeToBKlpFIkAvdjEve3Jlc291cmNlPXBy
b2plY3RzLyovbG9jYXRpb25zLyovb2NjdXJyZW5jZXMvKn06Z2V0SWFtUG9saWN5OgEq2kEI
cmVzb3VyY2USmAMKElRlc3RJYW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElh
bVBlcm1pc3Npb25zUmVxdWVzdBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25z
UmVzcG9uc2UirAKC0+STAo4CIjQvdjEve3Jlc291cmNlPXByb2plY3RzLyovbm90ZXMvKn06
dGVzdElhbVBlcm1pc3Npb25zOgEqWj8iOi92MS97cmVzb3VyY2U9cHJvamVjdHMvKi9vY2N1
cnJlbmNlcy8qfTp0ZXN0SWFtUGVybWlzc2lvbnM6ASpaRSJAL3YxL3tyZXNvdXJjZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL25vdGVzLyp9OnRlc3RJYW1QZXJtaXNzaW9uczoBKlpLIkYv
djEve3Jlc291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyovb2NjdXJyZW5jZXMvKn06dGVz
dElhbVBlcm1pc3Npb25zOgEq2kEUcmVzb3VyY2UscGVybWlzc2lvbnMS2AIKIkdldFZ1bG5l
cmFiaWxpdHlPY2N1cnJlbmNlc1N1bW1hcnkSTy5nb29nbGUuZGV2dG9vbHMuY29udGFpbmVy
YW5hbHlzaXMudjEuR2V0VnVsbmVyYWJpbGl0eU9jY3VycmVuY2VzU3VtbWFyeVJlcXVlc3Qa
RS5nb29nbGUuZGV2dG9vbHMuY29udGFpbmVyYW5hbHlzaXMudjEuVnVsbmVyYWJpbGl0eU9j
Y3VycmVuY2VzU3VtbWFyeSKZAYLT5JMCggESOC92MS97cGFyZW50PXByb2plY3RzLyp9L29j
Y3VycmVuY2VzOnZ1bG5lcmFiaWxpdHlTdW1tYXJ5WkYSRC92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L29jY3VycmVuY2VzOnZ1bG5lcmFiaWxpdHlTdW1tYXJ52kENcGFy
ZW50LGZpbHRlchL5AQoKRXhwb3J0U0JPTRI3Lmdvb2dsZS5kZXZ0b29scy5jb250YWluZXJh
bmFseXNpcy52MS5FeHBvcnRTQk9NUmVxdWVzdBo4Lmdvb2dsZS5kZXZ0b29scy5jb250YWlu
ZXJhbmFseXNpcy52MS5FeHBvcnRTQk9NUmVzcG9uc2UieILT5JMCciItL3YxL3tuYW1lPXBy
b2plY3RzLyovcmVzb3VyY2VzLyoqfTpleHBvcnRTQk9NOgEqWj4iOS92MS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL3Jlc291cmNlcy8qKn06ZXhwb3J0U0JPTToBKhpUykEgY29u
dGFpbmVyYW5hbHlzaXMuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQvYBCh9jb20uZ29vZ2xlLmNvbnRhaW5lcmFuYWx5
c2lzLnYxUAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28vY29udGFpbmVyYW5hbHlzaXMvYXBpdjEv
Y29udGFpbmVyYW5hbHlzaXNwYjtjb250YWluZXJhbmFseXNpc3BiogIDR0NBqgIqR29vZ2xl
LkNsb3VkLkRldlRvb2xzLkNvbnRhaW5lckFuYWx5c2lzLlYxygIhR29vZ2xlXENsb3VkXENv
bnRhaW5lckFuYWx5c2lzXFYx6gIkR29vZ2xlOjpDbG91ZDo6Q29udGFpbmVyQW5hbHlzaXM6
OlYxSvMsCgcSBQ4A5AEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoC
AwQSAxYAKAoJCgIDBRIDFwAkCgkKAgMGEgMYACMKCAoBCBIDGgBHCgkKAgglEgMaAEcKCAoB
CBIDGwBqCgkKAggLEgMbAGoKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA4CgkKAggB
EgMdADgKCAoBCBIDHgAhCgkKAggkEgMeACEKCAoBCBIDHwA+CgkKAggpEgMfAD4KCAoBCBID
IAA9CgkKAggtEgMgAD0K5wUKAgYAEgUvAKIBARrZBSBSZXRyaWV2ZXMgYW5hbHlzaXMgcmVz
dWx0cyBvZiBDbG91ZCBjb21wb25lbnRzIHN1Y2ggYXMgRG9ja2VyIGNvbnRhaW5lcgogaW1h
Z2VzLiBUaGUgQ29udGFpbmVyIEFuYWx5c2lzIEFQSSBpcyBhbiBpbXBsZW1lbnRhdGlvbiBv
ZiB0aGUKIFtHcmFmZWFzXShodHRwczovL2dyYWZlYXMuaW8pIEFQSS4KCiBBbmFseXNpcyBy
ZXN1bHRzIGFyZSBzdG9yZWQgYXMgYSBzZXJpZXMgb2Ygb2NjdXJyZW5jZXMuIEFuIGBPY2N1
cnJlbmNlYAogY29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgYSBzcGVjaWZpYyBhbmFseXNp
cyBpbnN0YW5jZSBvbiBhIHJlc291cmNlLiBBbgogb2NjdXJyZW5jZSByZWZlcnMgdG8gYSBg
Tm90ZWAuIEEgbm90ZSBjb250YWlucyBkZXRhaWxzIGRlc2NyaWJpbmcgdGhlCiBhbmFseXNp
cyBhbmQgaXMgZ2VuZXJhbGx5IHN0b3JlZCBpbiBhIHNlcGFyYXRlIHByb2plY3QsIGNhbGxl
ZCBhIGBQcm92aWRlcmAuCiBNdWx0aXBsZSBvY2N1cnJlbmNlcyBjYW4gcmVmZXIgdG8gdGhl
IHNhbWUgbm90ZS4KCiBGb3IgZXhhbXBsZSwgYW4gU1NMIHZ1bG5lcmFiaWxpdHkgY291bGQg
YWZmZWN0IG11bHRpcGxlIGltYWdlcy4gSW4gdGhpcyBjYXNlLAogdGhlcmUgd291bGQgYmUg
b25lIG5vdGUgZm9yIHRoZSB2dWxuZXJhYmlsaXR5IGFuZCBhbiBvY2N1cnJlbmNlIGZvciBl
YWNoCiBpbWFnZSB3aXRoIHRoZSB2dWxuZXJhYmlsaXR5IHJlZmVycmluZyB0byB0aGF0IG5v
dGUuCgoKCgMGAAESAy8IGQoKCgMGAAMSAzACSAoMCgUGAAOZCBIDMAJICgsKAwYAAxIEMQIy
NwoNCgUGAAOaCBIEMQIyNwqZAwoEBgACABIEPAJPAxqKAyBTZXRzIHRoZSBhY2Nlc3MgY29u
dHJvbCBwb2xpY3kgb24gdGhlIHNwZWNpZmllZCBub3RlIG9yIG9jY3VycmVuY2UuCiBSZXF1
aXJlcyBgY29udGFpbmVyYW5hbHlzaXMubm90ZXMuc2V0SWFtUG9saWN5YCBvcgogYGNvbnRh
aW5lcmFuYWx5c2lzLm9jY3VycmVuY2VzLnNldElhbVBvbGljeWAgcGVybWlzc2lvbiBpZiB0
aGUgcmVzb3VyY2UgaXMKIGEgbm90ZSBvciBhbiBvY2N1cnJlbmNlLCByZXNwZWN0aXZlbHku
CgogVGhlIHJlc291cmNlIHRha2VzIHRoZSBmb3JtYXQgYHByb2plY3RzL1tQUk9KRUNUX0lE
XS9ub3Rlcy9bTk9URV9JRF1gIGZvcgogbm90ZXMgYW5kIGBwcm9qZWN0cy9bUFJPSkVDVF9J
RF0vb2NjdXJyZW5jZXMvW09DQ1VSUkVOQ0VfSURdYCBmb3IKIG9jY3VycmVuY2VzLgoKDAoF
BgACAAESAzwGEgoMCgUGAAIAAhIDPBM0CgwKBQYAAgADEgM9DyMKDQoFBgACAAQSBD4ETQYK
EQoJBgACAASwyrwiEgQ+BE0GCgwKBQYAAgAEEgNOBD0KDwoIBgACAASbCAASA04EPQqXAwoE
BgACARIEWQJsAxqIAyBHZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgZm9yIGEgbm90
ZSBvciBhbiBvY2N1cnJlbmNlIHJlc291cmNlLgogUmVxdWlyZXMgYGNvbnRhaW5lcmFuYWx5
c2lzLm5vdGVzLnNldElhbVBvbGljeWAgb3IKIGBjb250YWluZXJhbmFseXNpcy5vY2N1cnJl
bmNlcy5zZXRJYW1Qb2xpY3lgIHBlcm1pc3Npb24gaWYgdGhlIHJlc291cmNlIGlzCiBhIG5v
dGUgb3Igb2NjdXJyZW5jZSwgcmVzcGVjdGl2ZWx5LgoKIFRoZSByZXNvdXJjZSB0YWtlcyB0
aGUgZm9ybWF0IGBwcm9qZWN0cy9bUFJPSkVDVF9JRF0vbm90ZXMvW05PVEVfSURdYCBmb3IK
IG5vdGVzIGFuZCBgcHJvamVjdHMvW1BST0pFQ1RfSURdL29jY3VycmVuY2VzL1tPQ0NVUlJF
TkNFX0lEXWAgZm9yCiBvY2N1cnJlbmNlcy4KCgwKBQYAAgEBEgNZBhIKDAoFBgACAQISA1kT
NAoMCgUGAAIBAxIDWg8jCg0KBQYAAgEEEgRbBGoGChEKCQYAAgEEsMq8IhIEWwRqBgoMCgUG
AAIBBBIDawQ2Cg8KCAYAAgEEmwgAEgNrBDYK1gIKBAYAAgISBXUCiAEDGsYCIFJldHVybnMg
dGhlIHBlcm1pc3Npb25zIHRoYXQgYSBjYWxsZXIgaGFzIG9uIHRoZSBzcGVjaWZpZWQgbm90
ZSBvcgogb2NjdXJyZW5jZS4gUmVxdWlyZXMgbGlzdCBwZXJtaXNzaW9uIG9uIHRoZSBwcm9q
ZWN0IChmb3IgZXhhbXBsZSwKIGBjb250YWluZXJhbmFseXNpcy5ub3Rlcy5saXN0YCkuCgog
VGhlIHJlc291cmNlIHRha2VzIHRoZSBmb3JtYXQgYHByb2plY3RzL1tQUk9KRUNUX0lEXS9u
b3Rlcy9bTk9URV9JRF1gIGZvcgogbm90ZXMgYW5kIGBwcm9qZWN0cy9bUFJPSkVDVF9JRF0v
b2NjdXJyZW5jZXMvW09DQ1VSUkVOQ0VfSURdYCBmb3IKIG9jY3VycmVuY2VzLgoKDAoFBgAC
AgESA3UGGAoMCgUGAAICAhIDdRlACgwKBQYAAgIDEgN2DzcKDgoFBgACAgQSBXcEhgEGChIK
CQYAAgIEsMq8IhIFdwSGAQYKDQoFBgACAgQSBIcBBEIKEAoIBgACAgSbCAASBIcBBEIKSwoE
BgACAxIGiwEClQEDGjsgR2V0cyBhIHN1bW1hcnkgb2YgdGhlIG51bWJlciBhbmQgc2V2ZXJp
dHkgb2Ygb2NjdXJyZW5jZXMuCgoNCgUGAAIDARIEiwEGKAoNCgUGAAIDAhIEjAEGLwoNCgUG
AAIDAxIEjQEPLgoPCgUGAAIDBBIGjgEEkwEGChMKCQYAAgMEsMq8IhIGjgEEkwEGCg0KBQYA
AgMEEgSUAQQ7ChAKCAYAAgMEmwgAEgSUAQQ7CjsKBAYAAgQSBpgBAqEBAxorIEdlbmVyYXRl
cyBhbiBTQk9NIGZvciB0aGUgZ2l2ZW4gcmVzb3VyY2UuCgoNCgUGAAIEARIEmAEGEAoNCgUG
AAIEAhIEmAERIgoNCgUGAAIEAxIEmAEtPwoPCgUGAAIEBBIGmQEEoAEGChMKCQYAAgQEsMq8
IhIGmQEEoAEGCmMKAgQAEgamAQC2AQEaVSBUaGUgcmVxdWVzdCB0byBnZW5lcmF0ZSBhbmQg
ZXhwb3J0IFNCT00uIFRhcmdldCBtdXN0IGJlIHNwZWNpZmllZCBmb3IgdGhlCiByZXF1ZXN0
LgoKCwoDBAABEgSmAQgZCmAKBAQAAwASBKkBAiEaUiBFbXB0eSBwbGFjZWhvbGRlciB0byBk
ZW5vdGUgdGhhdCB0aGlzIGlzIGEgR29vZ2xlIENsb3VkIFN0b3JhZ2UKIGV4cG9ydCByZXF1
ZXN0LgoKDQoFBAADAAESBKkBCh4KdAoEBAACABIErQECOxpmIFJlcXVpcmVkLiBUaGUgbmFt
ZSBvZiB0aGUgcmVzb3VyY2UgaW4gdGhlIGZvcm0gb2YKIGBwcm9qZWN0cy9bUFJPSkVDVF9J
RF0vcmVzb3VyY2VzL1tSRVNPVVJDRV9VUkxdYC4KCg0KBQQAAgAFEgStAQIICg0KBQQAAgAB
EgStAQkNCg0KBQQAAgADEgStARARCg0KBQQAAgAIEgStARI6ChAKCAQAAgAInAgAEgStARM5
CjIKBAQACAASBrABArUBAxoiIFRoZSBsb2NhdGlvbiBvZiB0aGUgU0JPTSBleHBvcnQuCgoN
CgUEAAgAARIEsAEIDgpsCgQEAAIBEgazAQS0ATEaXCBPcHRpb25hbC4gRW1wdHkgcGxhY2Vo
b2xkZXIgdG8gZGVub3RlIHRoYXQgdGhpcyBpcyBhIEdvb2dsZSBDbG91ZCBTdG9yYWdlCiBl
eHBvcnQgcmVxdWVzdC4KCg0KBQQAAgEGEgSzAQQYCg0KBQQAAgEBEgSzARkvCg0KBQQAAgED
EgSzATIzCg0KBQQAAgEIEgS0AQgwChAKCAQAAgEInAgAEgS0AQkvCjcKAgQBEga5AQC+AQEa
KSBUaGUgcmVzcG9uc2UgZnJvbSBhIGNhbGwgdG8gRXhwb3J0U0JPTS4KCgsKAwQBARIEuQEI
GgqvAQoEBAECABIEvQECIhqgASBUaGUgbmFtZSBvZiB0aGUgZGlzY292ZXJ5IG9jY3VycmVu
Y2UgaW4gdGhlIGZvcm0KICJwcm9qZWN0cy97cHJvamVjdF9pZH0vb2NjdXJyZW5jZXMve09D
Q1VSUkVOQ0VfSUR9CiBJdCBjYW4gYmUgdXNlZCB0byB0cmFjayB0aGUgcHJvZ3Jlc3Mgb2Yg
dGhlIFNCT00gZXhwb3J0LgoKDQoFBAECAAUSBL0BAggKDQoFBAECAAESBL0BCR0KDQoFBAEC
AAMSBL0BICEKUwoCBAISBsEBAM0BARpFIFJlcXVlc3QgdG8gZ2V0IGEgdnVsbmVyYWJpbGl0
eSBzdW1tYXJ5IGZvciBzb21lIHNldCBvZiBvY2N1cnJlbmNlcy4KCgsKAwQCARIEwQEIMQp/
CgQEAgIAEgbEAQLJAQQabyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHByb2plY3QgdG8g
Z2V0IGEgdnVsbmVyYWJpbGl0eSBzdW1tYXJ5IGZvciBpbiB0aGUKIGZvcm0gb2YgYHByb2pl
Y3RzL1tQUk9KRUNUX0lEXWAuCgoNCgUEAgIABRIExAECCAoNCgUEAgIAARIExAEJDwoNCgUE
AgIAAxIExAESEwoPCgUEAgIACBIGxAEUyQEDChAKCAQCAgAInAgAEgTFAQQqChEKBwQCAgAI
nwgSBsYBBMgBBQomCgQEAgIBEgTMAQIUGhggVGhlIGZpbHRlciBleHByZXNzaW9uLgoKDQoF
BAICAQUSBMwBAggKDQoFBAICAQESBMwBCQ8KDQoFBAICAQMSBMwBEhMKagoCBAMSBtEBAOQB
ARpcIEEgc3VtbWFyeSBvZiBob3cgbWFueSB2dWxuZXJhYmlsaXR5IG9jY3VycmVuY2VzIHRo
ZXJlIGFyZSBwZXIgcmVzb3VyY2UgYW5kCiBzZXZlcml0eSB0eXBlLgoKCwoDBAMBEgTRAQgn
ClgKBAQDAwASBtMBAuABAxpIIFBlciByZXNvdXJjZSBhbmQgc2V2ZXJpdHkgY291bnRzIG9m
IGZpeGFibGUgYW5kIHRvdGFsIHZ1bG5lcmFiaWxpdGllcy4KCg0KBQQDAwABEgTTAQoeCigK
BgQDAwACABIE1QEEHBoYIFRoZSBhZmZlY3RlZCByZXNvdXJjZS4KCg8KBwQDAwACAAUSBNUB
BAoKDwoHBAMDAAIAARIE1QELFwoPCgcEAwMAAgADEgTVARobCmsKBgQDAwACARIE2QEEJRpb
IFRoZSBzZXZlcml0eSBmb3IgdGhpcyBjb3VudC4gU0VWRVJJVFlfVU5TUEVDSUZJRUQgaW5k
aWNhdGVzIHRvdGFsIGFjcm9zcwogYWxsIHNldmVyaXRpZXMuCgoPCgcEAwMAAgEGEgTZAQQX
Cg8KBwQDAwACAQESBNkBGCAKDwoHBAMDAAIBAxIE2QEjJApWCgYEAwMAAgISBNwBBBwaRiBU
aGUgbnVtYmVyIG9mIGZpeGFibGUgdnVsbmVyYWJpbGl0aWVzIGFzc29jaWF0ZWQgd2l0aCB0
aGlzIHJlc291cmNlLgoKDwoHBAMDAAICBRIE3AEECQoPCgcEAwMAAgIBEgTcAQoXCg8KBwQD
AwACAgMSBNwBGhsKVAoGBAMDAAIDEgTfAQQaGkQgVGhlIHRvdGFsIG51bWJlciBvZiB2dWxu
ZXJhYmlsaXRpZXMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgcmVzb3VyY2UuCgoPCgcEAwMAAgMF
EgTfAQQJCg8KBwQDAwACAwESBN8BChUKDwoHBAMDAAIDAxIE3wEYGQpZCgQEAwIAEgTjAQIr
GksgQSBsaXN0aW5nIGJ5IHJlc291cmNlIG9mIHRoZSBudW1iZXIgb2YgZml4YWJsZSBhbmQg
dG90YWwgdnVsbmVyYWJpbGl0aWVzLgoKDQoFBAMCAAQSBOMBAgoKDQoFBAMCAAYSBOMBCx8K
DQoFBAMCAAESBOMBICYKDQoFBAMCAAMSBOMBKSpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest ===
    # Fields for ExportSBOMRequest
    # Field: name Type: 9 ()
    # Field: cloud_storage_location Type: 11 (.google.devtools.containeranalysis.v1.ExportSBOMRequest.CloudStorageLocation)

# === Message: Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMResponse ===
    # Fields for ExportSBOMResponse
    # Field: discovery_occurrence Type: 9 ()

# === Message: Google::Devtools::Containeranalysis::V1::Containeranalysis::GetVulnerabilityOccurrencesSummaryRequest ===
    # Fields for GetVulnerabilityOccurrencesSummaryRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary ===
    # Fields for VulnerabilityOccurrencesSummary
    # Field: counts Type: 11 (.google.devtools.containeranalysis.v1.VulnerabilityOccurrencesSummary.FixableTotalByDigest)

# === Service Client: Google::Devtools::Containeranalysis::V1::Containeranalysis::ContainerAnalysisClient ===
package Google::Devtools::Containeranalysis::V1::Containeranalysis::ContainerAnalysisClient;

=pod

=head2 Service Client: Google::Devtools::Containeranalysis::V1::Containeranalysis::ContainerAnalysisClient

Client stub representing the remote C<ContainerAnalysis> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.containeranalysis.v1.ContainerAnalysis',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.containeranalysis.v1.ContainerAnalysis',
        method         => 'GetIamPolicy',
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
        service        => 'google.devtools.containeranalysis.v1.ContainerAnalysis',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

sub get_vulnerability_occurrences_summary {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Containeranalysis::V1::Containeranalysis::GetVulnerabilityOccurrencesSummaryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.containeranalysis.v1.ContainerAnalysis',
        method         => 'GetVulnerabilityOccurrencesSummary',
        request        => $req,
        response_class => 'Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary',
    });
}

sub export_s_b_o_m {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.containeranalysis.v1.ContainerAnalysis',
        method         => 'ExportSBOM',
        request        => $req,
        response_class => 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Containeranalysis::V1::Containeranalysis - Compiled Protocol Buffers messages for google/devtools/containeranalysis/v1/containeranalysis.proto

=head1 SYNOPSIS

    use Google::Devtools::Containeranalysis::V1::Containeranalysis;

    my $msg = Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest->new({
        name => $name,
        cloud_storage_location => $cloud_storage_location,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/containeranalysis/v1/containeranalysis.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest

The request to generate and export SBOM. Target must be specified for the
request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource in the form of
`projects/[PROJECT_ID]/resources/[RESOURCE_URL]`.

=item * C<< $msg->cloud_storage_location() >> / C<< $msg->cloud_storage_location($value) >>

Type: C<Message> (L<Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest::CloudStorageLocation>)

Optional. Empty placeholder to denote that this is a Google Cloud Storage
export request.

=back

=head2 Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMResponse

The response from a call to ExportSBOM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->discovery_occurrence() >> / C<< $msg->discovery_occurrence($value) >>

Type: C<String>

The name of the discovery occurrence in the form
"projects/{project_id}/occurrences/{OCCURRENCE_ID}
It can be used to track the progress of the SBOM export.

=back

=head2 Google::Devtools::Containeranalysis::V1::Containeranalysis::GetVulnerabilityOccurrencesSummaryRequest

Request to get a vulnerability summary for some set of occurrences.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project to get a vulnerability summary for in the
form of `projects/[PROJECT_ID]`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The filter expression.

=back

=head2 Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary

A summary of how many vulnerability occurrences there are per resource and
severity type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->counts() >> / C<< $msg->counts($value) >>

Type: C<Message> (L<Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary::FixableTotalByDigest>)

A listing by resource of the number of fixable and total vulnerabilities.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Containeranalysis::V1::Containeranalysis::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
