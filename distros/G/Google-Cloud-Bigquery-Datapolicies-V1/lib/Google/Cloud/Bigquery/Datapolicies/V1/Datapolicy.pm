package Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy;

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
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvYmlncXVlcnkvZGF0YXBvbGljaWVzL3YxL2RhdGFwb2xpY3kucHJv
dG8SJWdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29n
bGUvaWFtL3YxL2lhbV9wb2xpY3kucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnByb3Rv
Ghtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9t
YXNrLnByb3RvIsABChdDcmVhdGVEYXRhUG9saWN5UmVxdWVzdBJMCgZwYXJlbnQYASABKAlC
NOBBAvpBLhIsYmlncXVlcnlkYXRhcG9saWN5Lmdvb2dsZWFwaXMuY29tL0RhdGFQb2xpY3lS
BnBhcmVudBJXCgtkYXRhX3BvbGljeRgCIAEoCzIxLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5k
YXRhcG9saWNpZXMudjEuRGF0YVBvbGljeUID4EECUgpkYXRhUG9saWN5Iq8BChdVcGRhdGVE
YXRhUG9saWN5UmVxdWVzdBJXCgtkYXRhX3BvbGljeRgBIAEoCzIxLmdvb2dsZS5jbG91ZC5i
aWdxdWVyeS5kYXRhcG9saWNpZXMudjEuRGF0YVBvbGljeUID4EECUgpkYXRhUG9saWN5EjsK
C3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRl
TWFzayJkChdSZW5hbWVEYXRhUG9saWN5UmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5h
bWUSMAoSbmV3X2RhdGFfcG9saWN5X2lkGAIgASgJQgPgQQJSD25ld0RhdGFQb2xpY3lJZCJj
ChdEZWxldGVEYXRhUG9saWN5UmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGJpZ3F1
ZXJ5ZGF0YXBvbGljeS5nb29nbGVhcGlzLmNvbS9EYXRhUG9saWN5UgRuYW1lImAKFEdldERh
dGFQb2xpY3lSZXF1ZXN0EkgKBG5hbWUYASABKAlCNOBBAvpBLgosYmlncXVlcnlkYXRhcG9s
aWN5Lmdvb2dsZWFwaXMuY29tL0RhdGFQb2xpY3lSBG5hbWUiuwEKF0xpc3REYXRhUG9saWNp
ZXNSZXF1ZXN0EkwKBnBhcmVudBgBIAEoCUI04EEC+kEuEixiaWdxdWVyeWRhdGFwb2xpY3ku
Z29vZ2xlYXBpcy5jb20vRGF0YVBvbGljeVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVII
cGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEhYKBmZpbHRlchgEIAEo
CVIGZmlsdGVyIpoBChhMaXN0RGF0YVBvbGljaWVzUmVzcG9uc2USVgoNZGF0YV9wb2xpY2ll
cxgBIAMoCzIxLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjEuRGF0YVBv
bGljeVIMZGF0YVBvbGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiLGBAoKRGF0YVBvbGljeRIfCgpwb2xpY3lfdGFnGAQgASgJSABSCXBvbGljeVRhZxJq
ChNkYXRhX21hc2tpbmdfcG9saWN5GAUgASgLMjguZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRh
dGFwb2xpY2llcy52MS5EYXRhTWFza2luZ1BvbGljeUgBUhFkYXRhTWFza2luZ1BvbGljeRIX
CgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSagoQZGF0YV9wb2xpY3lfdHlwZRgCIAEoDjJALmdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjEuRGF0YVBvbGljeS5EYXRhUG9s
aWN5VHlwZVIOZGF0YVBvbGljeVR5cGUSJAoOZGF0YV9wb2xpY3lfaWQYAyABKAlSDGRhdGFQ
b2xpY3lJZCJtCg5EYXRhUG9saWN5VHlwZRIgChxEQVRBX1BPTElDWV9UWVBFX1VOU1BFQ0lG
SUVEEAASIAocQ09MVU1OX0xFVkVMX1NFQ1VSSVRZX1BPTElDWRADEhcKE0RBVEFfTUFTS0lO
R19QT0xJQ1kQAjp16kFyCixiaWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20vRGF0
YVBvbGljeRJCcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFQ
b2xpY2llcy97ZGF0YV9wb2xpY3l9QhAKDm1hdGNoaW5nX2xhYmVsQggKBnBvbGljeSKdAwoR
RGF0YU1hc2tpbmdQb2xpY3kShAEKFXByZWRlZmluZWRfZXhwcmVzc2lvbhgBIAEoDjJNLmdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjEuRGF0YU1hc2tpbmdQb2xpY3ku
UHJlZGVmaW5lZEV4cHJlc3Npb25IAFIUcHJlZGVmaW5lZEV4cHJlc3Npb24SGgoHcm91dGlu
ZRgDIAEoCUgAUgdyb3V0aW5lIs4BChRQcmVkZWZpbmVkRXhwcmVzc2lvbhIlCiFQUkVERUZJ
TkVEX0VYUFJFU1NJT05fVU5TUEVDSUZJRUQQABIKCgZTSEEyNTYQAxIPCgtBTFdBWVNfTlVM
TBAFEhkKFURFRkFVTFRfTUFTS0lOR19WQUxVRRAHEhgKFExBU1RfRk9VUl9DSEFSQUNURVJT
EAkSGQoVRklSU1RfRk9VUl9DSEFSQUNURVJTEAoSDgoKRU1BSUxfTUFTSxAMEhIKDkRBVEVf
WUVBUl9NQVNLEA1CFAoSbWFza2luZ19leHByZXNzaW9uMpAPChFEYXRhUG9saWN5U2Vydmlj
ZRLhAQoQQ3JlYXRlRGF0YVBvbGljeRI+Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9s
aWNpZXMudjEuQ3JlYXRlRGF0YVBvbGljeVJlcXVlc3QaMS5nb29nbGUuY2xvdWQuYmlncXVl
cnkuZGF0YXBvbGljaWVzLnYxLkRhdGFQb2xpY3kiWoLT5JMCPyIwL3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKn0vZGF0YVBvbGljaWVzOgtkYXRhX3BvbGljedpBEnBhcmVu
dCxkYXRhX3BvbGljeRLyAQoQVXBkYXRlRGF0YVBvbGljeRI+Lmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5kYXRhcG9saWNpZXMudjEuVXBkYXRlRGF0YVBvbGljeVJlcXVlc3QaMS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkuZGF0YXBvbGljaWVzLnYxLkRhdGFQb2xpY3kia4LT5JMCSzI8L3Yx
L3tkYXRhX3BvbGljeS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVz
Lyp9OgtkYXRhX3BvbGljedpBF2RhdGFfcG9saWN5LHVwZGF0ZV9tYXNrEuMBChBSZW5hbWVE
YXRhUG9saWN5Ej4uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MS5SZW5h
bWVEYXRhUG9saWN5UmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNp
ZXMudjEuRGF0YVBvbGljeSJcgtPkkwI8IjcvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9kYXRhUG9saWNpZXMvKn06cmVuYW1lOgEq2kEXbmFtZSxuZXdfZGF0YV9wb2xpY3lf
aWQSqwEKEERlbGV0ZURhdGFQb2xpY3kSPi5nb29nbGUuY2xvdWQuYmlncXVlcnkuZGF0YXBv
bGljaWVzLnYxLkRlbGV0ZURhdGFQb2xpY3lSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5Ij+C0+STAjIqMC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xp
Y2llcy8qfdpBBG5hbWUSwAEKDUdldERhdGFQb2xpY3kSOy5nb29nbGUuY2xvdWQuYmlncXVl
cnkuZGF0YXBvbGljaWVzLnYxLkdldERhdGFQb2xpY3lSZXF1ZXN0GjEuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MS5EYXRhUG9saWN5Ij+C0+STAjISMC92MS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xpY2llcy8qfdpBBG5hbWUS1gEKEExp
c3REYXRhUG9saWNpZXMSPi5nb29nbGUuY2xvdWQuYmlncXVlcnkuZGF0YXBvbGljaWVzLnYx
Lkxpc3REYXRhUG9saWNpZXNSZXF1ZXN0Gj8uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFw
b2xpY2llcy52MS5MaXN0RGF0YVBvbGljaWVzUmVzcG9uc2UiQYLT5JMCMhIwL3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZGF0YVBvbGljaWVz2kEGcGFyZW50EpcBCgxH
ZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5nb29n
bGUuaWFtLnYxLlBvbGljeSJMgtPkkwJGIkEvdjEve3Jlc291cmNlPXByb2plY3RzLyovbG9j
YXRpb25zLyovZGF0YVBvbGljaWVzLyp9OmdldElhbVBvbGljeToBKhKXAQoMU2V0SWFtUG9s
aWN5EiIuZ29vZ2xlLmlhbS52MS5TZXRJYW1Qb2xpY3lSZXF1ZXN0GhUuZ29vZ2xlLmlhbS52
MS5Qb2xpY3kiTILT5JMCRiJBL3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2RhdGFQb2xpY2llcy8qfTpzZXRJYW1Qb2xpY3k6ASoSvQEKElRlc3RJYW1QZXJtaXNzaW9u
cxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVxdWVzdBopLmdvb2dsZS5p
YW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9uc2UiUoLT5JMCTCJHL3YxL3tyZXNvdXJj
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xpY2llcy8qfTp0ZXN0SWFtUGVybWlz
c2lvbnM6ASoafspBIWJpZ3F1ZXJ5ZGF0YXBvbGljeS5nb29nbGVhcGlzLmNvbdJBV2h0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvYmlncXVlcnksaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKJAgopY29tLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5kYXRhcG9saWNpZXMudjFCD0RhdGFQb2xpY3lQcm90b1ABWk1jbG91ZC5nb29nbGUu
Y29tL2dvL2JpZ3F1ZXJ5L2RhdGFwb2xpY2llcy9hcGl2MS9kYXRhcG9saWNpZXNwYjtkYXRh
cG9saWNpZXNwYqoCJUdvb2dsZS5DbG91ZC5CaWdRdWVyeS5EYXRhUG9saWNpZXMuVjHKAiVH
b29nbGVcQ2xvdWRcQmlnUXVlcnlcRGF0YVBvbGljaWVzXFYx6gIpR29vZ2xlOjpDbG91ZDo6
QmlncXVlcnk6OkRhdGFQb2xpY2llczo6VjFK4FgKBxIFDgDvAgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC4KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAoCgkKAgMFEgMXACQKCQoCAwYSAxgAJQoJ
CgIDBxIDGQAqCggKAQgSAxsAQgoJCgIIJRIDGwBCCggKAQgSAxwAZAoJCgIICxIDHABkCggK
AQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4AMAoJCgIICBIDHgAwCggKAQgSAx8AQgoJCgII
ARIDHwBCCggKAQgSAyAAQwoJCgIIKRIDIABDCggKAQgSAyEAQgoJCgIILRIDIQBCClcKAgYA
EgQkAHsBGksgRGF0YSBQb2xpY3kgU2VydmljZSBwcm92aWRlcyBBUElzIGZvciBtYW5hZ2lu
ZyB0aGUgbGFiZWwtcG9saWN5IGJpbmRpbmdzLgoKCgoDBgABEgMkCBkKCgoDBgADEgMlAkkK
DAoFBgADmQgSAyUCSQoLCgMGAAMSBCYCKDcKDQoFBgADmggSBCYCKDcKlwEKBAYAAgASBCwC
MgMaiAEgQ3JlYXRlcyBhIG5ldyBkYXRhIHBvbGljeSB1bmRlciBhIHByb2plY3Qgd2l0aCB0
aGUgZ2l2ZW4gYGRhdGFQb2xpY3lJZGAKICh1c2VkIGFzIHRoZSBkaXNwbGF5IG5hbWUpLCBw
b2xpY3kgdGFnLCBhbmQgZGF0YSBwb2xpY3kgdHlwZS4KCgwKBQYAAgABEgMsBhYKDAoFBgAC
AAISAywXLgoMCgUGAAIAAxIDLDlDCg0KBQYAAgAEEgQtBDAGChEKCQYAAgAEsMq8IhIELQQw
BgoMCgUGAAIABBIDMQRACg8KCAYAAgAEmwgAEgMxBEAKgAEKBAYAAgESBDYCPAMaciBVcGRh
dGVzIHRoZSBtZXRhZGF0YSBmb3IgYW4gZXhpc3RpbmcgZGF0YSBwb2xpY3kuIFRoZSB0YXJn
ZXQgZGF0YSBwb2xpY3kKIGNhbiBiZSBzcGVjaWZpZWQgYnkgdGhlIHJlc291cmNlIG5hbWUu
CgoMCgUGAAIBARIDNgYWCgwKBQYAAgECEgM2Fy4KDAoFBgACAQMSAzY5QwoNCgUGAAIBBBIE
NwQ6BgoRCgkGAAIBBLDKvCISBDcEOgYKDAoFBgACAQQSAzsERQoPCggGAAIBBJsIABIDOwRF
CksKBAYAAgISBD8CRQMaPSBSZW5hbWVzIHRoZSBpZCAoZGlzcGxheSBuYW1lKSBvZiB0aGUg
c3BlY2lmaWVkIGRhdGEgcG9saWN5LgoKDAoFBgACAgESAz8GFgoMCgUGAAICAhIDPxcuCgwK
BQYAAgIDEgM/OUMKDQoFBgACAgQSBEAEQwYKEQoJBgACAgSwyrwiEgRABEMGCgwKBQYAAgIE
EgNEBEUKDwoIBgACAgSbCAASA0QERQpHCgQGAAIDEgRIAk4DGjkgRGVsZXRlcyB0aGUgZGF0
YSBwb2xpY3kgc3BlY2lmaWVkIGJ5IGl0cyByZXNvdXJjZSBuYW1lLgoKDAoFBgACAwESA0gG
FgoMCgUGAAIDAhIDSBcuCgwKBQYAAgMDEgNJDyQKDQoFBgACAwQSBEoETAYKEQoJBgACAwSw
yrwiEgRKBEwGCgwKBQYAAgMEEgNNBDIKDwoIBgACAwSbCAASA00EMgpECgQGAAIEEgRRAlYD
GjYgR2V0cyB0aGUgZGF0YSBwb2xpY3kgc3BlY2lmaWVkIGJ5IGl0cyByZXNvdXJjZSBuYW1l
LgoKDAoFBgACBAESA1EGEwoMCgUGAAIEAhIDURQoCgwKBQYAAgQDEgNRMz0KDQoFBgACBAQS
BFIEVAYKEQoJBgACBASwyrwiEgRSBFQGCgwKBQYAAgQEEgNVBDIKDwoIBgACBASbCAASA1UE
MgpOCgQGAAIFEgRZAl8DGkAgTGlzdCBhbGwgb2YgdGhlIGRhdGEgcG9saWNpZXMgaW4gdGhl
IHNwZWNpZmllZCBwYXJlbnQgcHJvamVjdC4KCgwKBQYAAgUBEgNZBhYKDAoFBgACBQISA1kX
LgoMCgUGAAIFAxIDWg8nCg0KBQYAAgUEEgRbBF0GChEKCQYAAgUEsMq8IhIEWwRdBgoMCgUG
AAIFBBIDXgQ0Cg8KCAYAAgUEmwgAEgNeBDQKQgoEBgACBhIEYgJoAxo0IEdldHMgdGhlIElB
TSBwb2xpY3kgZm9yIHRoZSBzcGVjaWZpZWQgZGF0YSBwb2xpY3kuCgoMCgUGAAIGARIDYgYS
CgwKBQYAAgYCEgNiEzQKDAoFBgACBgMSA2MPIwoNCgUGAAIGBBIEZARnBgoRCgkGAAIGBLDK
vCISBGQEZwYKQgoEBgACBxIEawJxAxo0IFNldHMgdGhlIElBTSBwb2xpY3kgZm9yIHRoZSBz
cGVjaWZpZWQgZGF0YSBwb2xpY3kuCgoMCgUGAAIHARIDawYSCgwKBQYAAgcCEgNrEzQKDAoF
BgACBwMSA2wPIwoNCgUGAAIHBBIEbQRwBgoRCgkGAAIHBLDKvCISBG0EcAYKVgoEBgACCBIE
dAJ6AxpIIFJldHVybnMgdGhlIGNhbGxlcidzIHBlcm1pc3Npb24gb24gdGhlIHNwZWNpZmll
ZCBkYXRhIHBvbGljeSByZXNvdXJjZS4KCgwKBQYAAggBEgN0BhgKDAoFBgACCAISA3QZQAoM
CgUGAAIIAxIDdQ83Cg0KBQYAAggEEgR2BHkGChEKCQYAAggEsMq8IhIEdgR5Bgo/CgIEABIF
fgCLAQEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBDcmVhdGVEYXRhUG9saWN5IG1ldGhv
ZC4KCgoKAwQAARIDfggfCqIBCgQEAAIAEgaBAQKGAQQakQEgUmVxdWlyZWQuIFJlc291cmNl
IG5hbWUgb2YgdGhlIHByb2plY3QgdGhhdCB0aGUgZGF0YSBwb2xpY3kgd2lsbCBiZWxvbmcg
dG8uCiBUaGUgZm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9u
cy97bG9jYXRpb25faWR9YC4KCg0KBQQAAgAFEgSBAQIICg0KBQQAAgABEgSBAQkPCg0KBQQA
AgADEgSBARITCg8KBQQAAgAIEgaBARSGAQMKEAoIBAACAAicCAASBIIBBCoKEQoHBAACAAif
CBIGgwEEhQEFCoEBCgQEAAIBEgSKAQJGGnMgUmVxdWlyZWQuIFRoZSBkYXRhIHBvbGljeSB0
byBjcmVhdGUuIFRoZSBgbmFtZWAgZmllbGQgZG9lcyBub3QgbmVlZCB0byBiZQogcHJvdmlk
ZWQgZm9yIHRoZSBkYXRhIHBvbGljeSBjcmVhdGlvbi4KCg0KBQQAAgEGEgSKAQIMCg0KBQQA
AgEBEgSKAQ0YCg0KBQQAAgEDEgSKARscCg0KBQQAAgEIEgSKAR1FChAKCAQAAgEInAgAEgSK
AR5ECkEKAgQBEgaOAQCcAQEaMyBSZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgVXBkYXRlRGF0
YVBvbGljeSBtZXRob2QuCgoLCgMEAQESBI4BCB8KxQEKBAQBAgASBJMBAkYatgEgUmVxdWly
ZWQuIFVwZGF0ZSB0aGUgZGF0YSBwb2xpY3kncyBtZXRhZGF0YS4KCiBUaGUgdGFyZ2V0IGRh
dGEgcG9saWN5IGlzIGRldGVybWluZWQgYnkgdGhlIGBuYW1lYCBmaWVsZC4KIE90aGVyIGZp
ZWxkcyBhcmUgdXBkYXRlZCB0byB0aGUgc3BlY2lmaWVkIHZhbHVlcyBiYXNlZCBvbiB0aGUg
ZmllbGQgbWFza3MuCgoNCgUEAQIABhIEkwECDAoNCgUEAQIAARIEkwENGAoNCgUEAQIAAxIE
kwEbHAoNCgUEAQIACBIEkwEdRQoQCggEAQIACJwIABIEkwEeRArBAgoEBAECARIEmwECLBqy
AiBUaGUgdXBkYXRlIG1hc2sgYXBwbGllcyB0byB0aGUgcmVzb3VyY2UuIEZvciB0aGUgYEZp
ZWxkTWFza2AgZGVmaW5pdGlvbiwKIHNlZQogaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5j
b20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYjZmll
bGRtYXNrCiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byBhbGwgb2YgdGhlIGZpZWxkcyB0aGF0
IGFyZSBhbGxvd2VkIHRvIHVwZGF0ZS4KCiBVcGRhdGVzIHRvIHRoZSBgbmFtZWAgYW5kIGBk
YXRhUG9saWN5SWRgIGZpZWxkcyBhcmUgbm90IGFsbG93ZWQuCgoNCgUEAQIBBhIEmwECGwoN
CgUEAQIBARIEmwEcJwoNCgUEAQIBAxIEmwEqKwpACgIEAhIGnwEApgEBGjIgUmVxdWVzdCBt
ZXNzYWdlIGZvciB0aGUgUmVuYW1lRGF0YVBvbGljeSBtZXRob2QuCgoLCgMEAgESBJ8BCB8K
pwEKBAQCAgASBKIBAjsamAEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIGRhdGEg
cG9saWN5IHRvIHJlbmFtZS4gVGhlIGZvcm1hdCBpcwogYHByb2plY3RzL3twcm9qZWN0X251
bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZGF0YVBvbGljaWVzL3tkYXRhX3BvbGlj
eV9pZH1gCgoNCgUEAgIABRIEogECCAoNCgUEAgIAARIEogEJDQoNCgUEAgIAAxIEogEQEQoN
CgUEAgIACBIEogESOgoQCggEAgIACJwIABIEogETOQoxCgQEAgIBEgSlAQJJGiMgUmVxdWly
ZWQuIFRoZSBuZXcgZGF0YSBwb2xpY3kgaWQuCgoNCgUEAgIBBRIEpQECCAoNCgUEAgIBARIE
pQEJGwoNCgUEAgIBAxIEpQEeHwoNCgUEAgIBCBIEpQEgSAoQCggEAgIBCJwIABIEpQEhRwpA
CgIEAxIGqQEAsgEBGjIgUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgRGVsZXRlRGF0YVBvbGlj
eSBtZXRob2QuCgoLCgMEAwESBKkBCB8KpgEKBAQDAgASBqwBArEBBBqVASBSZXF1aXJlZC4g
UmVzb3VyY2UgbmFtZSBvZiB0aGUgZGF0YSBwb2xpY3kgdG8gZGVsZXRlLiBGb3JtYXQgaXMK
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2Rh
dGFQb2xpY2llcy97ZGF0YV9wb2xpY3lfaWR9YC4KCg0KBQQDAgAFEgSsAQIICg0KBQQDAgAB
EgSsAQkNCg0KBQQDAgADEgSsARARCg8KBQQDAgAIEgasARKxAQMKEAoIBAMCAAicCAASBK0B
BCoKEQoHBAMCAAifCBIGrgEEsAEFCj0KAgQEEga1AQC+AQEaLyBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIHRoZSBHZXREYXRhUG9saWN5IG1ldGhvZC4KCgsKAwQEARIEtQEIHAqmAQoEBAQCABIG
uAECvQEEGpUBIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSByZXF1ZXN0ZWQgZGF0
YSBwb2xpY3kuIEZvcm1hdCBpcwogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbl9pZH0vZGF0YVBvbGljaWVzL3tkYXRhX3BvbGljeV9pZH1gLgoKDQoF
BAQCAAUSBLgBAggKDQoFBAQCAAESBLgBCQ0KDQoFBAQCAAMSBLgBEBEKDwoFBAQCAAgSBrgB
Er0BAwoQCggEBAIACJwIABIEuQEEKgoRCgcEBAIACJ8IEga6AQS8AQUKQAoCBAUSBsEBAN0B
ARoyIFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIExpc3REYXRhUG9saWNpZXMgbWV0aG9kLgoK
CwoDBAUBEgTBAQgfCpoBCgQEBQIAEgbEAQLJAQQaiQEgUmVxdWlyZWQuIFJlc291cmNlIG5h
bWUgb2YgdGhlIHByb2plY3QgZm9yIHdoaWNoIHRvIGxpc3QgZGF0YSBwb2xpY2llcy4KIEZv
cm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9u
X2lkfWAuCgoNCgUEBQIABRIExAECCAoNCgUEBQIAARIExAEJDwoNCgUEBQIAAxIExAESEwoP
CgUEBQIACBIGxAEUyQEDChAKCAQFAgAInAgAEgTFAQQqChEKBwQFAgAInwgSBsYBBMgBBQqA
AQoEBAUCARIEzgECFhpyIFRoZSBtYXhpbXVtIG51bWJlciBvZiBkYXRhIHBvbGljaWVzIHRv
IHJldHVybi4gTXVzdCBiZSBhIHZhbHVlIGJldHdlZW4gMQogYW5kIDEwMDAuCiBJZiBub3Qg
c2V0LCBkZWZhdWx0cyB0byA1MC4KCg0KBQQFAgEFEgTOAQIHCg0KBQQFAgEBEgTOAQgRCg0K
BQQFAgEDEgTOARQVCoIBCgQEBQICEgTSAQIYGnQgVGhlIGBuZXh0UGFnZVRva2VuYCB2YWx1
ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBhbnkuIElmCiBu
b3Qgc2V0LCBkZWZhdWx0cyB0byBhbiBlbXB0eSBzdHJpbmcuCgoNCgUEBQICBRIE0gECCAoN
CgUEBQICARIE0gEJEwoNCgUEBQICAxIE0gEWFwrNAwoEBAUCAxIE3AECFBq+AyBGaWx0ZXJz
IHRoZSBkYXRhIHBvbGljaWVzIGJ5IHBvbGljeSB0YWdzIHRoYXQgdGhleQogYXJlIGFzc29j
aWF0ZWQgd2l0aC4gQ3VycmVudGx5IGZpbHRlciBvbmx5IHN1cHBvcnRzCiAicG9saWN5PHNw
YW4+PC9zcGFuPl90YWciIGJhc2VkIGZpbHRlcmluZyBhbmQgT1IgYmFzZWQgcHJlZGljYXRl
cy4gU2FtcGxlCiBmaWx0ZXIgY2FuIGJlICJwb2xpY3k8c3Bhbj48L3NwYW4+X3RhZzoKIHBy
b2plY3RzLzEvbG9jYXRpb25zL3VzL3RheG9ub21pZXMvMi9wb2xpY3lUYWdzLzMiLgogWW91
IG1heSBhbHNvIHVzZSB3aWxkY2FyZCBzdWNoIGFzICJwb2xpY3k8c3Bhbj48L3NwYW4+X3Rh
ZzoKIHByb2plY3RzLzEvbG9jYXRpb25zL3VzL3RheG9ub21pZXMvMioiLiBQbGVhc2Ugbm90
ZSB0aGF0IE9SIHByZWRpY2F0ZXMKIGNhbm5vdCBiZSB1c2VkIHdpdGggd2lsZGNhcmQgZmls
dGVycy4KCg0KBQQFAgMFEgTcAQIICg0KBQQFAgMBEgTcAQkPCg0KBQQFAgMDEgTcARITCkEK
AgQGEgbgAQDnAQEaMyBSZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgTGlzdERhdGFQb2xpY2ll
cyBtZXRob2QuCgoLCgMEBgESBOABCCAKQwoEBAYCABIE4gECKBo1IERhdGEgcG9saWNpZXMg
dGhhdCBiZWxvbmcgdG8gdGhlIHJlcXVlc3RlZCBwcm9qZWN0LgoKDQoFBAYCAAQSBOIBAgoK
DQoFBAYCAAYSBOIBCxUKDQoFBAYCAAESBOIBFiMKDQoFBAYCAAMSBOIBJicKaAoEBAYCARIE
5gECHRpaIFRva2VuIHVzZWQgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRz
LCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cy4KCg0KBQQGAgEFEgTm
AQIICg0KBQQGAgEBEgTmAQkYCg0KBQQGAgEDEgTmARscCjQKAgQHEgbqAQCVAgEaJiBSZXBy
ZXNlbnRzIHRoZSBsYWJlbC1wb2xpY3kgYmluZGluZy4KCgsKAwQHARIE6gEIEgoNCgMEBwcS
BusBAu4BBAoPCgUEBwedCBIG6wEC7gEECjgKBAQHBAASBvEBAvsBAxooIEEgbGlzdCBvZiBz
dXBwb3J0ZWQgZGF0YSBwb2xpY3kgdHlwZXMuCgoNCgUEBwQAARIE8QEHFQpSCgYEBwQAAgAS
BPMBBCUaQiBEZWZhdWx0IHZhbHVlIGZvciB0aGUgZGF0YSBwb2xpY3kgdHlwZS4gVGhpcyBz
aG91bGQgbm90IGJlIHVzZWQuCgoPCgcEBwQAAgABEgTzAQQgCg8KBwQHBAACAAISBPMBIyQK
YAoGBAcEAAIBEgT3AQQlGlAgVXNlZCB0byBjcmVhdGUgYSBkYXRhIHBvbGljeSBmb3IgY29s
dW1uLWxldmVsIHNlY3VyaXR5LCB3aXRob3V0IGRhdGEKIG1hc2tpbmcuCgoPCgcEBwQAAgEB
EgT3AQQgCg8KBwQHBAACAQISBPcBIyQKQAoGBAcEAAICEgT6AQQcGjAgVXNlZCB0byBjcmVh
dGUgYSBkYXRhIHBvbGljeSBmb3IgZGF0YSBtYXNraW5nLgoKDwoHBAcEAAICARIE+gEEFwoP
CgcEBwQAAgICEgT6ARobCjoKBAQHCAASBv4BAoICAxoqIExhYmVsIHRoYXQgaXMgYm91bmQg
dG8gdGhpcyBkYXRhIHBvbGljeS4KCg0KBQQHCAABEgT+AQgWCqQBCgQEBwIAEgSBAgQaGpUB
IFBvbGljeSB0YWcgcmVzb3VyY2UgbmFtZSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3Rz
L3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vdGF4b25vbWllcy97
dGF4b25vbXlfaWR9L3BvbGljeVRhZ3Mve3BvbGljeVRhZ19pZH1gLgoKDQoFBAcCAAUSBIEC
BAoKDQoFBAcCAAESBIECCxUKDQoFBAcCAAMSBIECGBkKPwoEBAcIARIGhQICiAIDGi8gVGhl
IHBvbGljeSB0aGF0IGlzIGJvdW5kIHRvIHRoaXMgZGF0YSBwb2xpY3kuCgoNCgUEBwgBARIE
hQIIDgpUCgQEBwIBEgSHAgQuGkYgVGhlIGRhdGEgbWFza2luZyBwb2xpY3kgdGhhdCBzcGVj
aWZpZXMgdGhlIGRhdGEgbWFza2luZyBydWxlIHRvIHVzZS4KCg0KBQQHAgEGEgSHAgQVCg0K
BQQHAgEBEgSHAhYpCg0KBQQHAgEDEgSHAiwtCqUBCgQEBwICEgSMAgI+GpYBIE91dHB1dCBv
bmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRoaXMgZGF0YSBwb2xpY3ksIGluIHRoZSBmb3JtYXQg
b2YKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9
L2RhdGFQb2xpY2llcy97ZGF0YV9wb2xpY3lfaWR9YC4KCg0KBQQHAgIFEgSMAgIICg0KBQQH
AgIBEgSMAgkNCg0KBQQHAgIDEgSMAhARCg0KBQQHAgIIEgSMAhI9ChAKCAQHAgIInAgAEgSM
AhM8CiQKBAQHAgMSBI8CAiYaFiBUeXBlIG9mIGRhdGEgcG9saWN5LgoKDQoFBAcCAwYSBI8C
AhAKDQoFBAcCAwESBI8CESEKDQoFBAcCAwMSBI8CJCUKqAEKBAQHAgQSBJQCAhwamQEgVXNl
ci1hc3NpZ25lZCAoaHVtYW4gcmVhZGFibGUpIElEIG9mIHRoZSBkYXRhIHBvbGljeSB0aGF0
IG5lZWRzIHRvIGJlCiB1bmlxdWUgd2l0aGluIGEgcHJvamVjdC4gVXNlZCBhcyB7ZGF0YV9w
b2xpY3lfaWR9IGluIHBhcnQgb2YgdGhlIHJlc291cmNlCiBuYW1lLgoKDQoFBAcCBAUSBJQC
AggKDQoFBAcCBAESBJQCCRcKDQoFBAcCBAMSBJQCGhsKUgoCBAgSBpgCAO8CARpEIFRoZSBk
YXRhIG1hc2tpbmcgcG9saWN5IHRoYXQgaXMgdXNlZCB0byBzcGVjaWZ5IGRhdGEgbWFza2lu
ZyBydWxlLgoKCwoDBAgBEgSYAggZCpMBCgQECAQAEgabAgLjAgMaggEgVGhlIGF2YWlsYWJs
ZSBtYXNraW5nIHJ1bGVzLiBMZWFybiBtb3JlIGhlcmU6CiBodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYmlncXVlcnkvZG9jcy9jb2x1bW4tZGF0YS1tYXNraW5nLWludHJvI21hc2tpbmdf
b3B0aW9ucy4KCg0KBQQIBAABEgSbAgcbCnsKBgQIBAACABIEngIEKhprIERlZmF1bHQsIHVu
c3BlY2lmaWVkIHByZWRlZmluZWQgZXhwcmVzc2lvbi4gTm8gbWFza2luZyB3aWxsIHRha2Ug
cGxhY2UKIHNpbmNlIG5vIGV4cHJlc3Npb24gaXMgc3BlY2lmaWVkLgoKDwoHBAgEAAIAARIE
ngIEJQoPCgcECAQAAgACEgSeAigpCkcKBgQIBAACARIEoQIEDxo3IE1hc2tpbmcgZXhwcmVz
c2lvbiB0byByZXBsYWNlIGRhdGEgd2l0aCBTSEEtMjU2IGhhc2guCgoPCgcECAQAAgEBEgSh
AgQKCg8KBwQIBAACAQISBKECDQ4KQAoGBAgEAAICEgSkAgQUGjAgTWFza2luZyBleHByZXNz
aW9uIHRvIHJlcGxhY2UgZGF0YSB3aXRoIE5VTExzLgoKDwoHBAgEAAICARIEpAIEDwoPCgcE
CAQAAgICEgSkAhITCrgDCgYECAQAAgMSBLgCBB4apwMgTWFza2luZyBleHByZXNzaW9uIHRv
IHJlcGxhY2UgZGF0YSB3aXRoIHRoZWlyIGRlZmF1bHQgbWFza2luZyB2YWx1ZXMuCiBUaGUg
ZGVmYXVsdCBtYXNraW5nIHZhbHVlcyBmb3IgZWFjaCB0eXBlIGxpc3RlZCBhcyBiZWxvdzoK
CiAqIFNUUklORzogIiIKICogQllURVM6IGInJwogKiBJTlRFR0VSOiAwCiAqIEZMT0FUOiAw
LjAKICogTlVNRVJJQzogMAogKiBCT09MRUFOOiBGQUxTRQogKiBUSU1FU1RBTVA6IDE5NzAt
MDEtMDEgMDA6MDA6MDAgVVRDCiAqIERBVEU6IDE5NzAtMDEtMDEKICogVElNRTogMDA6MDA6
MDAKICogREFURVRJTUU6IDE5NzAtMDEtMDFUMDA6MDA6MDAKICogR0VPR1JBUEhZOiBQT0lO
VCgwIDApCiAqIEJJR05VTUVSSUM6IDAKICogQVJSQVk6IFtdCiAqIFNUUlVDVDogTk9UX0FQ
UExJQ0FCTEUKICogSlNPTjogTlVMTAoKDwoHBAgEAAIDARIEuAIEGQoPCgcECAQAAgMCEgS4
AhwdCpQCCgYECAQAAgQSBMACBB0agwIgTWFza2luZyBleHByZXNzaW9uIHNob3dzIHRoZSBs
YXN0IGZvdXIgY2hhcmFjdGVycyBvZiB0ZXh0LgogVGhlIG1hc2tpbmcgYmVoYXZpb3IgaXMg
YXMgZm9sbG93czoKCiAqIElmIHRleHQgbGVuZ3RoID4gNCBjaGFyYWN0ZXJzOiBSZXBsYWNl
IHRleHQgd2l0aCBYWFhYWCwgYXBwZW5kIGxhc3QKIGZvdXIgY2hhcmFjdGVycyBvZiBvcmln
aW5hbCB0ZXh0LgogKiBJZiB0ZXh0IGxlbmd0aCA8PSA0IGNoYXJhY3RlcnM6IEFwcGx5IFNI
QS0yNTYgaGFzaC4KCg8KBwQIBAACBAESBMACBBgKDwoHBAgEAAIEAhIEwAIbHAqXAgoGBAgE
AAIFEgTIAgQfGoYCIE1hc2tpbmcgZXhwcmVzc2lvbiBzaG93cyB0aGUgZmlyc3QgZm91ciBj
aGFyYWN0ZXJzIG9mIHRleHQuCiBUaGUgbWFza2luZyBiZWhhdmlvciBpcyBhcyBmb2xsb3dz
OgoKICogSWYgdGV4dCBsZW5ndGggPiA0IGNoYXJhY3RlcnM6IFJlcGxhY2UgdGV4dCB3aXRo
IFhYWFhYLCBwcmVwZW5kIGZpcnN0CiBmb3VyIGNoYXJhY3RlcnMgb2Ygb3JpZ2luYWwgdGV4
dC4KICogSWYgdGV4dCBsZW5ndGggPD0gNCBjaGFyYWN0ZXJzOiBBcHBseSBTSEEtMjU2IGhh
c2guCgoPCgcECAQAAgUBEgTIAgQZCg8KBwQIBAACBQISBMgCHB4KkgMKBgQIBAACBhIE0wIE
FBqBAyBNYXNraW5nIGV4cHJlc3Npb24gZm9yIGVtYWlsIGFkZHJlc3Nlcy4KIFRoZSBtYXNr
aW5nIGJlaGF2aW9yIGlzIGFzIGZvbGxvd3M6CgogKiBTeW50YXgtdmFsaWQgZW1haWwgYWRk
cmVzczogUmVwbGFjZSB1c2VybmFtZSB3aXRoIFhYWFhYLiBGb3IgZXhhbXBsZSwKIGNsb3Vk
eXNhbmZyYW5jaXNjb0BnbWFpbC5jb20gYmVjb21lcyBYWFhYWEBnbWFpbC5jb20uCiAqIFN5
bnRheC1pbnZhbGlkIGVtYWlsIGFkZHJlc3M6IEFwcGx5IFNIQS0yNTYgaGFzaC4KCiBGb3Ig
bW9yZSBpbmZvcm1hdGlvbiwgc2VlIFtFbWFpbAogbWFza10oaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL2JpZ3F1ZXJ5L2RvY3MvY29sdW1uLWRhdGEtbWFza2luZy1pbnRybyNtYXNraW5n
X29wdGlvbnMpLgoKDwoHBAgEAAIGARIE0wIEDgoPCgcECAQAAgYCEgTTAhETCowECgYECAQA
AgcSBOICBBga+wMgTWFza2luZyBleHByZXNzaW9uIHRvIG9ubHkgc2hvdyB0aGUgeWVhciBv
ZiBgRGF0ZWAsCiBgRGF0ZVRpbWVgIGFuZCBgVGltZVN0YW1wYC4gRm9yIGV4YW1wbGUsIHdp
dGggdGhlCiB5ZWFyIDIwNzY6CgogKiBEQVRFICAgICAgICAgOiAgMjA3Ni0wMS0wMQogKiBE
QVRFVElNRSAgICAgOiAgMjA3Ni0wMS0wMVQwMDowMDowMAogKiBUSU1FU1RBTVAgICAgOiAg
MjA3Ni0wMS0wMSAwMDowMDowMCBVVEMKCiBUcnVuY2F0aW9uIG9jY3VycyBhY2NvcmRpbmcg
dG8gdGhlIFVUQyB0aW1lIHpvbmUuIFRvIGNoYW5nZSB0aGlzLCBhZGp1c3QKIHRoZSBkZWZh
dWx0IHRpbWUgem9uZSB1c2luZyB0aGUgYHRpbWVfem9uZWAgc3lzdGVtIHZhcmlhYmxlLgog
Rm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSB0aGUgPGEKIGhyZWY9Imh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL3JlZmVyZW5jZS9zeXN0ZW0tdmFyaWFibGVzIj5T
eXN0ZW0KIHZhcmlhYmxlcyByZWZlcmVuY2U8L2E+LgoKDwoHBAgEAAIHARIE4gIEEgoPCgcE
CAQAAgcCEgTiAhUXCkgKBAQICAASBuYCAu4CAxo4IEEgbWFza2luZyBleHByZXNzaW9uIHRv
IGJpbmQgdG8gdGhlIGRhdGEgbWFza2luZyBydWxlLgoKDQoFBAgIAAESBOYCCBoKMAoEBAgC
ABIE6AIEMxoiIEEgcHJlZGVmaW5lZCBtYXNraW5nIGV4cHJlc3Npb24uCgoNCgUECAIABhIE
6AIEGAoNCgUECAIAARIE6AIZLgoNCgUECAIAAxIE6AIxMgq3AQoEBAgCARIE7QIEFxqoASBU
aGUgbmFtZSBvZiB0aGUgQmlnUXVlcnkgcm91dGluZSB0aGF0IGNvbnRhaW5zIHRoZSBjdXN0
b20gbWFza2luZwogcm91dGluZSwgaW4gdGhlIGZvcm1hdCBvZgogYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vZGF0YXNldHMve2RhdGFzZXRfaWR9L3JvdXRpbmVzL3tyb3V0aW5lX2lk
fWAuCgoNCgUECAIBBRIE7QIECgoNCgUECAIBARIE7QILEgoNCgUECAIBAxIE7QIVFmIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::CreateDataPolicyRequest ===
    # Fields for CreateDataPolicyRequest
    # Field: parent Type: 9 ()
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v1.DataPolicy)

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::UpdateDataPolicyRequest ===
    # Fields for UpdateDataPolicyRequest
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v1.DataPolicy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::RenameDataPolicyRequest ===
    # Fields for RenameDataPolicyRequest
    # Field: name Type: 9 ()
    # Field: new_data_policy_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DeleteDataPolicyRequest ===
    # Fields for DeleteDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::GetDataPolicyRequest ===
    # Fields for GetDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::ListDataPoliciesRequest ===
    # Fields for ListDataPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::ListDataPoliciesResponse ===
    # Fields for ListDataPoliciesResponse
    # Field: data_policies Type: 11 (.google.cloud.bigquery.datapolicies.v1.DataPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy ===
    # Fields for DataPolicy
    # Field: policy_tag Type: 9 ()
    # Field: data_masking_policy Type: 11 (.google.cloud.bigquery.datapolicies.v1.DataMaskingPolicy)
    # Field: name Type: 9 ()
    # Field: data_policy_type Type: 14 (.google.cloud.bigquery.datapolicies.v1.DataPolicy.DataPolicyType)
    # Field: data_policy_id Type: 9 ()

# Enum: DataPolicy::DataPolicyType
our $DataPolicy_DATA_POLICY_TYPE_UNSPECIFIED = 0;
our $DataPolicy_COLUMN_LEVEL_SECURITY_POLICY = 3;
our $DataPolicy_DATA_MASKING_POLICY = 2;

# === Message: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataMaskingPolicy ===
    # Fields for DataMaskingPolicy
    # Field: predefined_expression Type: 14 (.google.cloud.bigquery.datapolicies.v1.DataMaskingPolicy.PredefinedExpression)
    # Field: routine Type: 9 ()

# Enum: DataMaskingPolicy::PredefinedExpression
our $DataMaskingPolicy_PREDEFINED_EXPRESSION_UNSPECIFIED = 0;
our $DataMaskingPolicy_SHA256 = 3;
our $DataMaskingPolicy_ALWAYS_NULL = 5;
our $DataMaskingPolicy_DEFAULT_MASKING_VALUE = 7;
our $DataMaskingPolicy_LAST_FOUR_CHARACTERS = 9;
our $DataMaskingPolicy_FIRST_FOUR_CHARACTERS = 10;
our $DataMaskingPolicy_EMAIL_MASK = 12;
our $DataMaskingPolicy_DATE_YEAR_MASK = 13;

# === Service Client: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicyServiceClient ===
package Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicyServiceClient

Client stub representing the remote C<DataPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::CreateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'CreateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy',
    });
}

sub update_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::UpdateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'UpdateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy',
    });
}

sub rename_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::RenameDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'RenameDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy',
    });
}

sub delete_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DeleteDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'DeleteDataPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::GetDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'GetDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy',
    });
}

sub list_data_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::ListDataPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'ListDataPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::ListDataPoliciesResponse',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
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
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
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
        service        => 'google.cloud.bigquery.datapolicies.v1.DataPolicyService',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy - Compiled Protocol Buffers messages for google/cloud/bigquery/datapolicies/v1/datapolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy;

    my $msg = Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::CreateDataPolicyRequest->new({
        parent => $parent,
        data_policy => $data_policy,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::CreateDataPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/datapolicies/v1/datapolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::CreateDataPolicyRequest

Request message for the CreateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the data policy will belong to.
The format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy>)

Required. The data policy to create. The `name` field does not need to be
provided for the data policy creation.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::UpdateDataPolicyRequest

Response message for the UpdateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy>)

Required. Update the data policy's metadata.

The target data policy is determined by the `name` field.
Other fields are updated to the specified values based on the field masks.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
If not set, defaults to all of the fields that are allowed to update.

Updates to the `name` and `dataPolicyId` fields are not allowed.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::RenameDataPolicyRequest

Request message for the RenameDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the data policy to rename. The format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`

=item * C<< $msg->new_data_policy_id() >> / C<< $msg->new_data_policy_id($value) >>

Type: C<String>

Required. The new data policy id.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DeleteDataPolicyRequest

Request message for the DeleteDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the data policy to delete. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::GetDataPolicyRequest

Request message for the GetDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the requested data policy. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::ListDataPoliciesRequest

Request message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project for which to list data policies.
Format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of data policies to return. Must be a value between 1
and 1000.
If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The `nextPageToken` value returned from a previous list request, if any. If
not set, defaults to an empty string.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filters the data policies by policy tags that they
are associated with. Currently filter only supports
"policy<span></span>_tag" based filtering and OR based predicates. Sample
filter can be "policy<span></span>_tag:
projects/1/locations/us/taxonomies/2/policyTags/3".
You may also use wildcard such as "policy<span></span>_tag:
projects/1/locations/us/taxonomies/2*". Please note that OR predicates
cannot be used with wildcard filters.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::ListDataPoliciesResponse

Response message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policies() >> / C<< $msg->data_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy>)

Data policies that belong to the requested project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token used to retrieve the next page of results, or empty if there are no
more results.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataPolicy

Represents the label-policy binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<String>

Policy tag resource name, in the format of
`projects/{project_number}/locations/{location_id}/taxonomies/{taxonomy_id}/policyTags/{policyTag_id}`.

=item * C<< $msg->data_masking_policy() >> / C<< $msg->data_masking_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataMaskingPolicy>)

The data masking policy that specifies the data masking rule to use.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->data_policy_type() >> / C<< $msg->data_policy_type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V1::DataPolicy::DataPolicyType>)

Type of data policy.

=item * C<< $msg->data_policy_id() >> / C<< $msg->data_policy_id($value) >>

Type: C<String>

User-assigned (human readable) ID of the data policy that needs to be
unique within a project. Used as {data_policy_id} in part of the resource
name.

=back

=head3 Enum: DataPolicy::DataPolicyType

=over 4

=item * C<DATA_POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<COLUMN_LEVEL_SECURITY_POLICY> => C<3>

=item * C<DATA_MASKING_POLICY> => C<2>

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::DataMaskingPolicy

The data masking policy that is used to specify data masking rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predefined_expression() >> / C<< $msg->predefined_expression($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V1::DataMaskingPolicy::PredefinedExpression>)

A predefined masking expression.

=item * C<< $msg->routine() >> / C<< $msg->routine($value) >>

Type: C<String>

The name of the BigQuery routine that contains the custom masking
routine, in the format of
`projects/{project_number}/datasets/{dataset_id}/routines/{routine_id}`.

=back

=head3 Enum: DataMaskingPolicy::PredefinedExpression

=over 4

=item * C<PREDEFINED_EXPRESSION_UNSPECIFIED> => C<0>

=item * C<SHA256> => C<3>

=item * C<ALWAYS_NULL> => C<5>

=item * C<DEFAULT_MASKING_VALUE> => C<7>

=item * C<LAST_FOUR_CHARACTERS> => C<9>

=item * C<FIRST_FOUR_CHARACTERS> => C<10>

=item * C<EMAIL_MASK> => C<12>

=item * C<DATE_YEAR_MASK> => C<13>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Datapolicies::V1::Datapolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
