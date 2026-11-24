package Google::Cloud::Networksecurity::V1beta1::NetworkSecurity;

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
    eval { require Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy };
    eval { require Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy };
    eval { require Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvbmV0d29ya19zZWN1cml0
eS5wcm90bxIkZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxo/Z29vZ2xl
L2Nsb3VkL25ldHdvcmtzZWN1cml0eS92MWJldGExL2F1dGhvcml6YXRpb25fcG9saWN5LnBy
b3RvGjxnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvY2xpZW50X3Rsc19w
b2xpY3kucHJvdG8aPGdvb2dsZS9jbG91ZC9uZXR3b3Jrc2VjdXJpdHkvdjFiZXRhMS9zZXJ2
ZXJfdGxzX3BvbGljeS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJv
dG8y3iIKD05ldHdvcmtTZWN1cml0eRL9AQoZTGlzdEF1dGhvcml6YXRpb25Qb2xpY2llcxJG
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5MaXN0QXV0aG9yaXphdGlv
blBvbGljaWVzUmVxdWVzdBpHLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRh
MS5MaXN0QXV0aG9yaXphdGlvblBvbGljaWVzUmVzcG9uc2UiT4LT5JMCQBI+L3YxYmV0YTEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9hdXRob3JpemF0aW9uUG9saWNpZXPa
QQZwYXJlbnQS5wEKFkdldEF1dGhvcml6YXRpb25Qb2xpY3kSQy5nb29nbGUuY2xvdWQubmV0
d29ya3NlY3VyaXR5LnYxYmV0YTEuR2V0QXV0aG9yaXphdGlvblBvbGljeVJlcXVlc3QaOS5n
b29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQXV0aG9yaXphdGlvblBvbGlj
eSJNgtPkkwJAEj4vdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2F1dGhv
cml6YXRpb25Qb2xpY2llcy8qfdpBBG5hbWUS5wIKGUNyZWF0ZUF1dGhvcml6YXRpb25Qb2xp
Y3kSRi5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQ3JlYXRlQXV0aG9y
aXphdGlvblBvbGljeVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIuIB
gtPkkwJWIj4vdjFiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2F1dGhv
cml6YXRpb25Qb2xpY2llczoUYXV0aG9yaXphdGlvbl9wb2xpY3naQTNwYXJlbnQsYXV0aG9y
aXphdGlvbl9wb2xpY3ksYXV0aG9yaXphdGlvbl9wb2xpY3lfaWTKQU0KE0F1dGhvcml6YXRp
b25Qb2xpY3kSNmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5PcGVyYXRp
b25NZXRhZGF0YRLpAgoZVXBkYXRlQXV0aG9yaXphdGlvblBvbGljeRJGLmdvb2dsZS5jbG91
ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5VcGRhdGVBdXRob3JpemF0aW9uUG9saWN5UmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i5AGC0+STAmsyUy92MWJldGEx
L3thdXRob3JpemF0aW9uX3BvbGljeS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYXV0
aG9yaXphdGlvblBvbGljaWVzLyp9OhRhdXRob3JpemF0aW9uX3BvbGljedpBIGF1dGhvcml6
YXRpb25fcG9saWN5LHVwZGF0ZV9tYXNrykFNChNBdXRob3JpemF0aW9uUG9saWN5EjZnb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuT3BlcmF0aW9uTWV0YWRhdGESpAIK
GURlbGV0ZUF1dGhvcml6YXRpb25Qb2xpY3kSRi5nb29nbGUuY2xvdWQubmV0d29ya3NlY3Vy
aXR5LnYxYmV0YTEuRGVsZXRlQXV0aG9yaXphdGlvblBvbGljeVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIp8BgtPkkwJAKj4vdjFiZXRhMS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2F1dGhvcml6YXRpb25Qb2xpY2llcy8qfdpBBG5hbWXKQU8KFWdv
b2dsZS5wcm90b2J1Zi5FbXB0eRI2Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJl
dGExLk9wZXJhdGlvbk1ldGFkYXRhEu0BChVMaXN0U2VydmVyVGxzUG9saWNpZXMSQi5nb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuTGlzdFNlcnZlclRsc1BvbGljaWVz
UmVxdWVzdBpDLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5MaXN0U2Vy
dmVyVGxzUG9saWNpZXNSZXNwb25zZSJLgtPkkwI8EjovdjFiZXRhMS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyp9L3NlcnZlclRsc1BvbGljaWVz2kEGcGFyZW50EtcBChJHZXRT
ZXJ2ZXJUbHNQb2xpY3kSPy5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEu
R2V0U2VydmVyVGxzUG9saWN5UmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJp
dHkudjFiZXRhMS5TZXJ2ZXJUbHNQb2xpY3kiSYLT5JMCPBI6L3YxYmV0YTEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9zZXJ2ZXJUbHNQb2xpY2llcy8qfdpBBG5hbWUSzgIKFUNy
ZWF0ZVNlcnZlclRsc1BvbGljeRJCLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFi
ZXRhMS5DcmVhdGVTZXJ2ZXJUbHNQb2xpY3lSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbiLRAYLT5JMCTyI6L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qfS9zZXJ2ZXJUbHNQb2xpY2llczoRc2VydmVyX3Rsc19wb2xpY3naQS1wYXJlbnQs
c2VydmVyX3Rsc19wb2xpY3ksc2VydmVyX3Rsc19wb2xpY3lfaWTKQUkKD1NlcnZlclRsc1Bv
bGljeRI2Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLk9wZXJhdGlvbk1l
dGFkYXRhEtACChVVcGRhdGVTZXJ2ZXJUbHNQb2xpY3kSQi5nb29nbGUuY2xvdWQubmV0d29y
a3NlY3VyaXR5LnYxYmV0YTEuVXBkYXRlU2VydmVyVGxzUG9saWN5UmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24i0wGC0+STAmEyTC92MWJldGExL3tzZXJ2ZXJfdGxz
X3BvbGljeS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2VydmVyVGxzUG9saWNpZXMv
Kn06EXNlcnZlcl90bHNfcG9saWN52kEdc2VydmVyX3Rsc19wb2xpY3ksdXBkYXRlX21hc2vK
QUkKD1NlcnZlclRsc1BvbGljeRI2Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJl
dGExLk9wZXJhdGlvbk1ldGFkYXRhEpgCChVEZWxldGVTZXJ2ZXJUbHNQb2xpY3kSQi5nb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuRGVsZXRlU2VydmVyVGxzUG9saWN5
UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24imwGC0+STAjwqOi92MWJl
dGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2VydmVyVGxzUG9saWNpZXMvKn3a
QQRuYW1lykFPChVnb29nbGUucHJvdG9idWYuRW1wdHkSNmdvb2dsZS5jbG91ZC5uZXR3b3Jr
c2VjdXJpdHkudjFiZXRhMS5PcGVyYXRpb25NZXRhZGF0YRLtAQoVTGlzdENsaWVudFRsc1Bv
bGljaWVzEkIuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkxpc3RDbGll
bnRUbHNQb2xpY2llc1JlcXVlc3QaQy5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYx
YmV0YTEuTGlzdENsaWVudFRsc1BvbGljaWVzUmVzcG9uc2UiS4LT5JMCPBI6L3YxYmV0YTEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jbGllbnRUbHNQb2xpY2llc9pBBnBh
cmVudBLXAQoSR2V0Q2xpZW50VGxzUG9saWN5Ej8uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1
cml0eS52MWJldGExLkdldENsaWVudFRsc1BvbGljeVJlcXVlc3QaNS5nb29nbGUuY2xvdWQu
bmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQ2xpZW50VGxzUG9saWN5IkmC0+STAjwSOi92MWJl
dGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2xpZW50VGxzUG9saWNpZXMvKn3a
QQRuYW1lEs4CChVDcmVhdGVDbGllbnRUbHNQb2xpY3kSQi5nb29nbGUuY2xvdWQubmV0d29y
a3NlY3VyaXR5LnYxYmV0YTEuQ3JlYXRlQ2xpZW50VGxzUG9saWN5UmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24i0QGC0+STAk8iOi92MWJldGExL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKn0vY2xpZW50VGxzUG9saWNpZXM6EWNsaWVudF90bHNfcG9s
aWN52kEtcGFyZW50LGNsaWVudF90bHNfcG9saWN5LGNsaWVudF90bHNfcG9saWN5X2lkykFJ
Cg9DbGllbnRUbHNQb2xpY3kSNmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRh
MS5PcGVyYXRpb25NZXRhZGF0YRLQAgoVVXBkYXRlQ2xpZW50VGxzUG9saWN5EkIuZ29vZ2xl
LmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLlVwZGF0ZUNsaWVudFRsc1BvbGljeVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uItMBgtPkkwJhMkwvdjFiZXRh
MS97Y2xpZW50X3Rsc19wb2xpY3kubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NsaWVu
dFRsc1BvbGljaWVzLyp9OhFjbGllbnRfdGxzX3BvbGljedpBHWNsaWVudF90bHNfcG9saWN5
LHVwZGF0ZV9tYXNrykFJCg9DbGllbnRUbHNQb2xpY3kSNmdvb2dsZS5jbG91ZC5uZXR3b3Jr
c2VjdXJpdHkudjFiZXRhMS5PcGVyYXRpb25NZXRhZGF0YRKYAgoVRGVsZXRlQ2xpZW50VGxz
UG9saWN5EkIuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkRlbGV0ZUNs
aWVudFRsc1BvbGljeVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpsB
gtPkkwI8KjovdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NsaWVudFRs
c1BvbGljaWVzLyp92kEEbmFtZcpBTwoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EjZnb29nbGUu
Y2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuT3BlcmF0aW9uTWV0YWRhdGEaUspBHm5l
dHdvcmtzZWN1cml0eS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C+AEKKGNvbS5nb29nbGUuY2xvdWQubmV0d29ya3Nl
Y3VyaXR5LnYxYmV0YTFQAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkv
YXBpdjFiZXRhMS9uZXR3b3Jrc2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCJEdvb2ds
ZS5DbG91ZC5OZXR3b3JrU2VjdXJpdHkuVjFCZXRhMcoCJEdvb2dsZVxDbG91ZFxOZXR3b3Jr
U2VjdXJpdHlcVjFiZXRhMeoCJ0dvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjFi
ZXRhMUq9HwoHEgUOAMgBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAALQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQASQoJCgIDAxIDFQBGCgkK
AgMEEgMWAEYKCQoCAwUSAxcALQoICgEIEgMZAEEKCQoCCCUSAxkAQQoICgEIEgMaAGkKCQoC
CAsSAxoAaQoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcAEEKCQoCCAESAxwAQQoICgEI
EgMdAEEKCQoCCCkSAx0AQQoICgEIEgMeAEAKCQoCCC0SAx4AQAqvAQoCBgASBSMAyAEBGqEB
IE5ldHdvcmsgU2VjdXJpdHkgQVBJIHByb3ZpZGVzIHJlc291cmNlcyB0byBjb25maWd1cmUg
YXV0aGVudGljYXRpb24gYW5kCiBhdXRob3JpemF0aW9uIHBvbGljaWVzLiBSZWZlciB0byBw
ZXIgQVBJIHJlc291cmNlIGRvY3VtZW50YXRpb24gZm9yIG1vcmUKIGluZm9ybWF0aW9uLgoK
CgoDBgABEgMjCBcKCgoDBgADEgMkAkYKDAoFBgADmQgSAyQCRgoKCgMGAAMSAyUCVgoMCgUG
AAOaCBIDJQJWCkwKBAYAAgASBCgCLQMaPiBMaXN0cyBBdXRob3JpemF0aW9uUG9saWNpZXMg
aW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMoBh8KDAoFBgAC
AAISAyggQAoMCgUGAAIAAxIDKEtsCg0KBQYAAgAEEgQpBCsGChEKCQYAAgAEsMq8IhIEKQQr
BgoMCgUGAAIABBIDLAQ0Cg8KCAYAAgAEmwgAEgMsBDQKPQoEBgACARIEMAI1AxovIEdldHMg
ZGV0YWlscyBvZiBhIHNpbmdsZSBBdXRob3JpemF0aW9uUG9saWN5LgoKDAoFBgACAQESAzAG
HAoMCgUGAAIBAhIDMB06CgwKBQYAAgEDEgMwRVgKDQoFBgACAQQSBDEEMwYKEQoJBgACAQSw
yrwiEgQxBDMGCgwKBQYAAgEEEgM0BDIKDwoIBgACAQSbCAASAzQEMgpSCgQGAAICEgQ4AkID
GkQgQ3JlYXRlcyBhIG5ldyBBdXRob3JpemF0aW9uUG9saWN5IGluIGEgZ2l2ZW4gcHJvamVj
dCBhbmQgbG9jYXRpb24uCgoMCgUGAAICARIDOAYfCgwKBQYAAgICEgM4IEAKDAoFBgACAgMS
AzhLZwoNCgUGAAICBBIEOQQ8BgoRCgkGAAICBLDKvCISBDkEPAYKDAoFBgACAgQSAz0EYQoP
CggGAAICBJsIABIDPQRhCg0KBQYAAgIEEgQ+BEEGCg8KBwYAAgIEmQgSBD4EQQYKRwoEBgAC
AxIERQJPAxo5IFVwZGF0ZXMgdGhlIHBhcmFtZXRlcnMgb2YgYSBzaW5nbGUgQXV0aG9yaXph
dGlvblBvbGljeS4KCgwKBQYAAgMBEgNFBh8KDAoFBgACAwISA0UgQAoMCgUGAAIDAxIDRUtn
Cg0KBQYAAgMEEgRGBEkGChEKCQYAAgMEsMq8IhIERgRJBgoMCgUGAAIDBBIDSgROCg8KCAYA
AgMEmwgAEgNKBE4KDQoFBgACAwQSBEsETgYKDwoHBgACAwSZCBIESwROBgo1CgQGAAIEEgRS
AlsDGicgRGVsZXRlcyBhIHNpbmdsZSBBdXRob3JpemF0aW9uUG9saWN5LgoKDAoFBgACBAES
A1IGHwoMCgUGAAIEAhIDUiBACgwKBQYAAgQDEgNSS2cKDQoFBgACBAQSBFMEVQYKEQoJBgAC
BASwyrwiEgRTBFUGCgwKBQYAAgQEEgNWBDIKDwoIBgACBASbCAASA1YEMgoNCgUGAAIEBBIE
VwRaBgoPCgcGAAIEBJkIEgRXBFoGCkgKBAYAAgUSBF4CYwMaOiBMaXN0cyBTZXJ2ZXJUbHNQ
b2xpY2llcyBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACBQESA14G
GwoMCgUGAAIFAhIDXhw4CgwKBQYAAgUDEgNeQ2AKDQoFBgACBQQSBF8EYQYKEQoJBgACBQSw
yrwiEgRfBGEGCgwKBQYAAgUEEgNiBDQKDwoIBgACBQSbCAASA2IENAo5CgQGAAIGEgRmAmsD
GisgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIFNlcnZlclRsc1BvbGljeS4KCgwKBQYAAgYB
EgNmBhgKDAoFBgACBgISA2YZMgoMCgUGAAIGAxIDZj1MCg0KBQYAAgYEEgRnBGkGChEKCQYA
AgYEsMq8IhIEZwRpBgoMCgUGAAIGBBIDagQyCg8KCAYAAgYEmwgAEgNqBDIKTgoEBgACBxIE
bgJ4AxpAIENyZWF0ZXMgYSBuZXcgU2VydmVyVGxzUG9saWN5IGluIGEgZ2l2ZW4gcHJvamVj
dCBhbmQgbG9jYXRpb24uCgoMCgUGAAIHARIDbgYbCgwKBQYAAgcCEgNuHDgKDAoFBgACBwMS
A25DXwoNCgUGAAIHBBIEbwRyBgoRCgkGAAIHBLDKvCISBG8EcgYKDAoFBgACBwQSA3MEWwoP
CggGAAIHBJsIABIDcwRbCg0KBQYAAgcEEgR0BHcGCg8KBwYAAgcEmQgSBHQEdwYKRAoEBgAC
CBIFewKFAQMaNSBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIFNlcnZlclRs
c1BvbGljeS4KCgwKBQYAAggBEgN7BhsKDAoFBgACCAISA3scOAoMCgUGAAIIAxIDe0NfCg0K
BQYAAggEEgR8BH8GChEKCQYAAggEsMq8IhIEfAR/BgoNCgUGAAIIBBIEgAEESwoQCggGAAII
BJsIABIEgAEESwoPCgUGAAIIBBIGgQEEhAEGChEKBwYAAggEmQgSBoEBBIQBBgozCgQGAAIJ
EgaIAQKRAQMaIyBEZWxldGVzIGEgc2luZ2xlIFNlcnZlclRsc1BvbGljeS4KCg0KBQYAAgkB
EgSIAQYbCg0KBQYAAgkCEgSIARw4Cg0KBQYAAgkDEgSIAUNfCg8KBQYAAgkEEgaJAQSLAQYK
EwoJBgACCQSwyrwiEgaJAQSLAQYKDQoFBgACCQQSBIwBBDIKEAoIBgACCQSbCAASBIwBBDIK
DwoFBgACCQQSBo0BBJABBgoRCgcGAAIJBJkIEgaNAQSQAQYKSgoEBgACChIGlAECmQEDGjog
TGlzdHMgQ2xpZW50VGxzUG9saWNpZXMgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlv
bi4KCg0KBQYAAgoBEgSUAQYbCg0KBQYAAgoCEgSUARw4Cg0KBQYAAgoDEgSUAUNgCg8KBQYA
AgoEEgaVAQSXAQYKEwoJBgACCgSwyrwiEgaVAQSXAQYKDQoFBgACCgQSBJgBBDQKEAoIBgAC
CgSbCAASBJgBBDQKOwoEBgACCxIGnAECoQEDGisgR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xl
IENsaWVudFRsc1BvbGljeS4KCg0KBQYAAgsBEgScAQYYCg0KBQYAAgsCEgScARkyCg0KBQYA
AgsDEgScAT1MCg8KBQYAAgsEEgadAQSfAQYKEwoJBgACCwSwyrwiEgadAQSfAQYKDQoFBgAC
CwQSBKABBDIKEAoIBgACCwSbCAASBKABBDIKUAoEBgACDBIGpAECrgEDGkAgQ3JlYXRlcyBh
IG5ldyBDbGllbnRUbHNQb2xpY3kgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4K
Cg0KBQYAAgwBEgSkAQYbCg0KBQYAAgwCEgSkARw4Cg0KBQYAAgwDEgSkAUNfCg8KBQYAAgwE
EgalAQSoAQYKEwoJBgACDASwyrwiEgalAQSoAQYKDQoFBgACDAQSBKkBBFsKEAoIBgACDASb
CAASBKkBBFsKDwoFBgACDAQSBqoBBK0BBgoRCgcGAAIMBJkIEgaqAQStAQYKRQoEBgACDRIG
sQECuwEDGjUgVXBkYXRlcyB0aGUgcGFyYW1ldGVycyBvZiBhIHNpbmdsZSBDbGllbnRUbHNQ
b2xpY3kuCgoNCgUGAAINARIEsQEGGwoNCgUGAAINAhIEsQEcOAoNCgUGAAINAxIEsQFDXwoP
CgUGAAINBBIGsgEEtQEGChMKCQYAAg0EsMq8IhIGsgEEtQEGCg0KBQYAAg0EEgS2AQRLChAK
CAYAAg0EmwgAEgS2AQRLCg8KBQYAAg0EEga3AQS6AQYKEQoHBgACDQSZCBIGtwEEugEGCjMK
BAYAAg4SBr4BAscBAxojIERlbGV0ZXMgYSBzaW5nbGUgQ2xpZW50VGxzUG9saWN5LgoKDQoF
BgACDgESBL4BBhsKDQoFBgACDgISBL4BHDgKDQoFBgACDgMSBL4BQ18KDwoFBgACDgQSBr8B
BMEBBgoTCgkGAAIOBLDKvCISBr8BBMEBBgoNCgUGAAIOBBIEwgEEMgoQCggGAAIOBJsIABIE
wgEEMgoPCgUGAAIOBBIGwwEExgEGChEKBwYAAg4EmQgSBsMBBMYBBmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Networksecurity::V1beta1::NetworkSecurity::NetworkSecurityClient ===
package Google::Cloud::Networksecurity::V1beta1::NetworkSecurity::NetworkSecurityClient;

=pod

=head2 Service Client: Google::Cloud::Networksecurity::V1beta1::NetworkSecurity::NetworkSecurityClient

Client stub representing the remote C<NetworkSecurity> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networksecurity.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networksecurity.googleapis.com:443' );

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

sub list_authorization_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::ListAuthorizationPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'ListAuthorizationPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::ListAuthorizationPoliciesResponse',
    });
}

sub get_authorization_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::GetAuthorizationPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'GetAuthorizationPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::AuthorizationPolicy',
    });
}

sub create_authorization_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::CreateAuthorizationPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'CreateAuthorizationPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_authorization_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::UpdateAuthorizationPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'UpdateAuthorizationPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_authorization_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::AuthorizationPolicy::DeleteAuthorizationPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'DeleteAuthorizationPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_server_tls_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ListServerTlsPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'ListServerTlsPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ListServerTlsPoliciesResponse',
    });
}

sub get_server_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::GetServerTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'GetServerTlsPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::ServerTlsPolicy',
    });
}

sub create_server_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::CreateServerTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'CreateServerTlsPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_server_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::UpdateServerTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'UpdateServerTlsPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_server_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ServerTlsPolicy::DeleteServerTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'DeleteServerTlsPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_client_tls_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ListClientTlsPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'ListClientTlsPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ListClientTlsPoliciesResponse',
    });
}

sub get_client_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::GetClientTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'GetClientTlsPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy',
    });
}

sub create_client_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::CreateClientTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'CreateClientTlsPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_client_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::UpdateClientTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'UpdateClientTlsPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_client_tls_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::DeleteClientTlsPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networksecurity.v1beta1.NetworkSecurity',
        method         => 'DeleteClientTlsPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1beta1::NetworkSecurity - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/network_security.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/network_security.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::NetworkSecurity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
