package Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization;

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
    eval { require Google::Cloud::Datacatalog::V1beta1::Policytagmanager };
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS9wb2xpY3l0YWdtYW5hZ2Vyc2Vy
aWFsaXphdGlvbi5wcm90bxIgZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEaHGdv
b2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGjdnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS9wb2xpY3l0YWdtYW5hZ2Vy
LnByb3RvIqMCChJTZXJpYWxpemVkVGF4b25vbXkSJgoMZGlzcGxheV9uYW1lGAEgASgJQgPg
QQJSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbhJWCgtw
b2xpY3lfdGFncxgDIAMoCzI1Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlNl
cmlhbGl6ZWRQb2xpY3lUYWdSCnBvbGljeVRhZ3MSawoWYWN0aXZhdGVkX3BvbGljeV90eXBl
cxgEIAMoDjI1Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlRheG9ub215LlBv
bGljeVR5cGVSFGFjdGl2YXRlZFBvbGljeVR5cGVzIuEBChNTZXJpYWxpemVkUG9saWN5VGFn
Eh0KCnBvbGljeV90YWcYASABKAlSCXBvbGljeVRhZxImCgxkaXNwbGF5X25hbWUYAiABKAlC
A+BBAlILZGlzcGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEmEK
EWNoaWxkX3BvbGljeV90YWdzGAQgAygLMjUuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYx
YmV0YTEuU2VyaWFsaXplZFBvbGljeVRhZ1IPY2hpbGRQb2xpY3lUYWdzIr8BChdJbXBvcnRU
YXhvbm9taWVzUmVxdWVzdBJDCgZwYXJlbnQYASABKAlCK+BBAvpBJRIjZGF0YWNhdGFsb2cu
Z29vZ2xlYXBpcy5jb20vVGF4b25vbXlSBnBhcmVudBJVCg1pbmxpbmVfc291cmNlGAIgASgL
Mi4uZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuSW5saW5lU291cmNlSABSDGlu
bGluZVNvdXJjZUIICgZzb3VyY2UiaQoMSW5saW5lU291cmNlElkKCnRheG9ub21pZXMYASAD
KAsyNC5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5TZXJpYWxpemVkVGF4b25v
bXlCA+BBAlIKdGF4b25vbWllcyJmChhJbXBvcnRUYXhvbm9taWVzUmVzcG9uc2USSgoKdGF4
b25vbWllcxgBIAMoCzIqLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlRheG9u
b215Ugp0YXhvbm9taWVzIvEBChdFeHBvcnRUYXhvbm9taWVzUmVxdWVzdBJDCgZwYXJlbnQY
ASABKAlCK+BBAvpBJRIjZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vVGF4b25vbXlSBnBh
cmVudBJLCgp0YXhvbm9taWVzGAIgAygJQivgQQL6QSUKI2RhdGFjYXRhbG9nLmdvb2dsZWFw
aXMuY29tL1RheG9ub215Ugp0YXhvbm9taWVzEjUKFXNlcmlhbGl6ZWRfdGF4b25vbWllcxgD
IAEoCEgAUhRzZXJpYWxpemVkVGF4b25vbWllc0INCgtkZXN0aW5hdGlvbiJwChhFeHBvcnRU
YXhvbm9taWVzUmVzcG9uc2USVAoKdGF4b25vbWllcxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5k
YXRhY2F0YWxvZy52MWJldGExLlNlcmlhbGl6ZWRUYXhvbm9teVIKdGF4b25vbWllczKSBAod
UG9saWN5VGFnTWFuYWdlclNlcmlhbGl6YXRpb24S0AEKEEltcG9ydFRheG9ub21pZXMSOS5n
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5JbXBvcnRUYXhvbm9taWVzUmVxdWVz
dBo6Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLkltcG9ydFRheG9ub21pZXNS
ZXNwb25zZSJFgtPkkwI/IjovdjFiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
Lyp9L3RheG9ub21pZXM6aW1wb3J0OgEqEs0BChBFeHBvcnRUYXhvbm9taWVzEjkuZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEuRXhwb3J0VGF4b25vbWllc1JlcXVlc3QaOi5n
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMS5FeHBvcnRUYXhvbm9taWVzUmVzcG9u
c2UiQoLT5JMCPBI6L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS90
YXhvbm9taWVzOmV4cG9ydBpOykEaZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQoACCiRjb20uZ29v
Z2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTFCIlBvbGljeVRhZ01hbmFnZXJTZXJpYWxp
emF0aW9uUHJvdG9QAVpGY2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9hcGl2MWJl
dGExL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoCIEdvb2dsZS5DbG91ZC5EYXRhQ2F0
YWxvZy5WMUJldGExygIgR29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYxYmV0YTHqAiNHb29n
bGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFiZXRhMUqJKAoHEgUOAKgBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEEKCAoBCBIDGAA9CgkKAgglEgMY
AD0KCAoBCBIDGQBdCgkKAggLEgMZAF0KCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwBD
CgkKAggIEgMbAEMKCAoBCBIDHAA9CgkKAggBEgMcAD0KCAoBCBIDHQA9CgkKAggpEgMdAD0K
CAoBCBIDHgA8CgkKAggtEgMeADwKlwEKAgYAEgQiAD4BGooBIFBvbGljeSB0YWcgbWFuYWdl
ciBzZXJpYWxpemF0aW9uIEFQSSBzZXJ2aWNlIGFsbG93cyBjbGllbnRzIHRvIG1hbmlwdWxh
dGUKIHRoZWlyIHRheG9ub21pZXMgYW5kIHBvbGljeSB0YWdzIGRhdGEgd2l0aCBzZXJpYWxp
emVkIGZvcm1hdC4KCgoKAwYAARIDIgglCgoKAwYAAxIDIwJCCgwKBQYAA5kIEgMjAkIKCwoD
BgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3CroBCgQGAAIAEgQsAjIDGqsBIEltcG9ydHMgYWxs
IHRheG9ub21pZXMgYW5kIHRoZWlyIHBvbGljeSB0YWdzIHRvIGEgcHJvamVjdCBhcyBuZXcK
IHRheG9ub21pZXMuCgogVGhpcyBtZXRob2QgcHJvdmlkZXMgYSBidWxrIHRheG9ub215IC8g
cG9saWN5IHRhZyBjcmVhdGlvbiB1c2luZyBuZXN0ZWQKIHByb3RvIHN0cnVjdHVyZS4KCgwK
BQYAAgABEgMsBhYKDAoFBgACAAISAywXLgoMCgUGAAIAAxIDLQ8nCg0KBQYAAgAEEgQuBDEG
ChEKCQYAAgAEsMq8IhIELgQxBgrWAQoEBgACARIEOAI9AxrHASBFeHBvcnRzIGFsbCB0YXhv
bm9taWVzIGFuZCB0aGVpciBwb2xpY3kgdGFncyBpbiBhIHByb2plY3QuCgogVGhpcyBtZXRo
b2QgZ2VuZXJhdGVzIFNlcmlhbGl6ZWRUYXhvbm9teSBwcm90b3Mgd2l0aCBuZXN0ZWQgcG9s
aWN5IHRhZ3MKIHRoYXQgY2FuIGJlIHVzZWQgYXMgYW4gaW5wdXQgZm9yIGZ1dHVyZSBJbXBv
cnRUYXhvbm9taWVzIGNhbGxzLgoKDAoFBgACAQESAzgGFgoMCgUGAAIBAhIDOBcuCgwKBQYA
AgEDEgM5DycKDQoFBgACAQQSBDoEPAYKEQoJBgACAQSwyrwiEgQ6BDwGCokBCgIEABIEQgBR
ARp9IE1lc3NhZ2UgY2FwdHVyaW5nIGEgdGF4b25vbXkgYW5kIGl0cyBwb2xpY3kgdGFnIGhp
ZXJhcmNoeSBhcyBhIG5lc3RlZCBwcm90by4KIFVzZWQgZm9yIHRheG9ub215IGltcG9ydC9l
eHBvcnQgYW5kIG11dGF0aW9uLgoKCgoDBAABEgNCCBoKXAoEBAACABIDRQJDGk8gUmVxdWly
ZWQuIERpc3BsYXkgbmFtZSBvZiB0aGUgdGF4b25vbXkuIE1heCAyMDAgYnl0ZXMgd2hlbiBl
bmNvZGVkIGluCiBVVEYtOC4KCgwKBQQAAgAFEgNFAggKDAoFBAACAAESA0UJFQoMCgUEAAIA
AxIDRRgZCgwKBQQAAgAIEgNFGkIKDwoIBAACAAicCAASA0UbQQq1AQoEBAACARIDSgIZGqcB
IERlc2NyaXB0aW9uIG9mIHRoZSBzZXJpYWxpemVkIHRheG9ub215LiBUaGUgbGVuZ3RoIG9m
IHRoZQogZGVzY3JpcHRpb24gaXMgbGltaXRlZCB0byAyMDAwIGJ5dGVzIHdoZW4gZW5jb2Rl
ZCBpbiBVVEYtOC4gSWYgbm90IHNldCwKIGRlZmF1bHRzIHRvIGFuIGVtcHR5IGRlc2NyaXB0
aW9uLgoKDAoFBAACAQUSA0oCCAoMCgUEAAIBARIDSgkUCgwKBQQAAgEDEgNKFxgKSQoEBAAC
AhIDTQIvGjwgVG9wIGxldmVsIHBvbGljeSB0YWdzIGFzc29jaWF0ZWQgd2l0aCB0aGUgdGF4
b25vbXkgaWYgYW55LgoKDAoFBAACAgQSA00CCgoMCgUEAAICBhIDTQseCgwKBQQAAgIBEgNN
HyoKDAoFBAACAgMSA00tLgpICgQEAAIDEgNQAjoaOyBBIGxpc3Qgb2YgcG9saWN5IHR5cGVz
IHRoYXQgYXJlIGFjdGl2YXRlZCBmb3IgYSB0YXhvbm9teS4KCgwKBQQAAgMEEgNQAgoKDAoF
BAACAwYSA1ALHgoMCgUEAAIDARIDUB81CgwKBQQAAgMDEgNQODkKUgoCBAESBFQAZQEaRiBN
ZXNzYWdlIHJlcHJlc2VudGluZyBvbmUgcG9saWN5IHRhZyB3aGVuIGV4cG9ydGVkIGFzIGEg
bmVzdGVkIHByb3RvLgoKCgoDBAEBEgNUCBsKawoEBAECABIDWAIYGl4gUmVzb3VyY2UgbmFt
ZSBvZiB0aGUgcG9saWN5IHRhZy4KCiBUaGlzIGZpZWxkIHdpbGwgYmUgaWdub3JlZCB3aGVu
IGNhbGxpbmcgSW1wb3J0VGF4b25vbWllcy4KCgwKBQQBAgAFEgNYAggKDAoFBAECAAESA1gJ
EwoMCgUEAQIAAxIDWBYXCl4KBAQBAgESA1wCQxpRIFJlcXVpcmVkLiBEaXNwbGF5IG5hbWUg
b2YgdGhlIHBvbGljeSB0YWcuIE1heCAyMDAgYnl0ZXMgd2hlbiBlbmNvZGVkIGluCiBVVEYt
OC4KCgwKBQQBAgEFEgNcAggKDAoFBAECAQESA1wJFQoMCgUEAQIBAxIDXBgZCgwKBQQBAgEI
EgNcGkIKDwoIBAECAQicCAASA1wbQQq3AQoEBAECAhIDYQIZGqkBIERlc2NyaXB0aW9uIG9m
IHRoZSBzZXJpYWxpemVkIHBvbGljeSB0YWcuIFRoZSBsZW5ndGggb2YgdGhlCiBkZXNjcmlw
dGlvbiBpcyBsaW1pdGVkIHRvIDIwMDAgYnl0ZXMgd2hlbiBlbmNvZGVkIGluIFVURi04LiBJ
ZiBub3Qgc2V0LAogZGVmYXVsdHMgdG8gYW4gZW1wdHkgZGVzY3JpcHRpb24uCgoMCgUEAQIC
BRIDYQIICgwKBQQBAgIBEgNhCRQKDAoFBAECAgMSA2EXGAoxCgQEAQIDEgNkAjUaJCBDaGls
ZHJlbiBvZiB0aGUgcG9saWN5IHRhZyBpZiBhbnkuCgoMCgUEAQIDBBIDZAIKCgwKBQQBAgMG
EgNkCx4KDAoFBAECAwESA2QfMAoMCgUEAQIDAxIDZDM0CocBCgIEAhIEaQB4ARp7IFJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtJbXBvcnRUYXhvbm9taWVzXVtnb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFiZXRhMS5Qb2xpY3lUYWdNYW5hZ2VyU2VyaWFsaXphdGlvbi5JbXBvcnRUYXhv
bm9taWVzXS4KCgoKAwQCARIDaQgfCmAKBAQCAgASBGwCcQQaUiBSZXF1aXJlZC4gUmVzb3Vy
Y2UgbmFtZSBvZiBwcm9qZWN0IHRoYXQgdGhlIGltcG9ydGVkIHRheG9ub21pZXMgd2lsbCBi
ZWxvbmcKIHRvLgoKDAoFBAICAAUSA2wCCAoMCgUEAgIAARIDbAkPCgwKBQQCAgADEgNsEhMK
DQoFBAICAAgSBGwUcQMKDwoIBAICAAicCAASA20EKgoPCgcEAgIACJ8IEgRuBHAFCjEKBAQC
CAASBHQCdwMaIyBTb3VyY2UgdGF4b25vbWllcyB0byBiZSBpbXBvcnRlZC4KCgwKBQQCCAAB
EgN0CA4KQAoEBAICARIDdgQjGjMgSW5saW5lIHNvdXJjZSB1c2VkIGZvciB0YXhvbm9taWVz
IHRvIGJlIGltcG9ydGVkLgoKDAoFBAICAQYSA3YEEAoMCgUEAgIBARIDdhEeCgwKBQQCAgED
EgN2ISIKNwoCBAMSBHsAfwEaKyBJbmxpbmUgc291cmNlIHVzZWQgZm9yIHRheG9ub21pZXMg
aW1wb3J0LgoKCgoDBAMBEgN7CBQKNAoEBAMCABIEfQJ+LxomIFJlcXVpcmVkLiBUYXhvbm9t
aWVzIHRvIGJlIGltcG9ydGVkLgoKDAoFBAMCAAQSA30CCgoMCgUEAwIABhIDfQsdCgwKBQQD
AgABEgN9HigKDAoFBAMCAAMSA30rLAoMCgUEAwIACBIDfgYuCg8KCAQDAgAInAgAEgN+By0K
igEKAgQEEgaDAQCGAQEafCBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0ltcG9ydFRheG9ub21p
ZXNdW2dvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlBvbGljeVRhZ01hbmFnZXJT
ZXJpYWxpemF0aW9uLkltcG9ydFRheG9ub21pZXNdLgoKCwoDBAQBEgSDAQggCi4KBAQEAgAS
BIUBAiMaICBUYXhvbm9taWVzIHRoYXQgd2VyZSBpbXBvcnRlZC4KCg0KBQQEAgAEEgSFAQIK
Cg0KBQQEAgAGEgSFAQsTCg0KBQQEAgABEgSFARQeCg0KBQQEAgADEgSFASEiCokBCgIEBRIG
igEAoQEBGnsgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0V4cG9ydFRheG9ub21pZXNdW2dvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlBvbGljeVRhZ01hbmFnZXJTZXJpYWxpemF0
aW9uLkV4cG9ydFRheG9ub21pZXNdLgoKCwoDBAUBEgSKAQgfCmQKBAQFAgASBo0BApIBBBpU
IFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9qZWN0IHRoYXQgdGF4b25vbWll
cyB0byBiZSBleHBvcnRlZAogd2lsbCBzaGFyZS4KCg0KBQQFAgAFEgSNAQIICg0KBQQFAgAB
EgSNAQkPCg0KBQQFAgADEgSNARITCg8KBQQFAgAIEgaNARSSAQMKEAoIBAUCAAicCAASBI4B
BCoKEQoHBAUCAAifCBIGjwEEkQEFCkwKBAQFAgESBpUBApoBBBo8IFJlcXVpcmVkLiBSZXNv
dXJjZSBuYW1lcyBvZiB0aGUgdGF4b25vbWllcyB0byBiZSBleHBvcnRlZC4KCg0KBQQFAgEE
EgSVAQIKCg0KBQQFAgEFEgSVAQsRCg0KBQQFAgEBEgSVARIcCg0KBQQFAgEDEgSVAR8gCg8K
BQQFAgEIEgaVASGaAQMKEAoIBAUCAQicCAASBJYBBCoKEQoHBAUCAQifCBIGlwEEmQEFCjoK
BAQFCAASBp0BAqABAxoqIFJlcXVpcmVkLiBUYXhvbm9taWVzIGV4cG9ydCBkZXN0aW5hdGlv
bi4KCg0KBQQFCAABEgSdAQgTCjsKBAQFAgISBJ8BBCMaLSBFeHBvcnQgdGF4b25vbWllcyBh
cyBzZXJpYWxpemVkIHRheG9ub21pZXMuCgoNCgUEBQICBRIEnwEECAoNCgUEBQICARIEnwEJ
HgoNCgUEBQICAxIEnwEhIgqKAQoCBAYSBqUBAKgBARp8IFJlc3BvbnNlIG1lc3NhZ2UgZm9y
CiBbRXhwb3J0VGF4b25vbWllc11bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxYmV0YTEu
UG9saWN5VGFnTWFuYWdlclNlcmlhbGl6YXRpb24uRXhwb3J0VGF4b25vbWllc10uCgoLCgME
BgESBKUBCCAKRwoEBAYCABIEpwECLRo5IExpc3Qgb2YgdGF4b25vbWllcyBhbmQgcG9saWN5
IHRhZ3MgaW4gYSB0cmVlIHN0cnVjdHVyZS4KCg0KBQQGAgAEEgSnAQIKCg0KBQQGAgAGEgSn
AQsdCg0KBQQGAgABEgSnAR4oCg0KBQQGAgADEgSnASssYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy ===
    # Fields for SerializedTaxonomy
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: policy_tags Type: 11 (.google.cloud.datacatalog.v1beta1.SerializedPolicyTag)
    # Field: activated_policy_types Type: 14 (.google.cloud.datacatalog.v1beta1.Taxonomy.PolicyType)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag ===
    # Fields for SerializedPolicyTag
    # Field: policy_tag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: child_policy_tags Type: 11 (.google.cloud.datacatalog.v1beta1.SerializedPolicyTag)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesRequest ===
    # Fields for ImportTaxonomiesRequest
    # Field: parent Type: 9 ()
    # Field: inline_source Type: 11 (.google.cloud.datacatalog.v1beta1.InlineSource)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::InlineSource ===
    # Fields for InlineSource
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1beta1.SerializedTaxonomy)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesResponse ===
    # Fields for ImportTaxonomiesResponse
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1beta1.Taxonomy)

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesRequest ===
    # Fields for ExportTaxonomiesRequest
    # Field: parent Type: 9 ()
    # Field: taxonomies Type: 9 ()
    # Field: serialized_taxonomies Type: 8 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesResponse ===
    # Fields for ExportTaxonomiesResponse
    # Field: taxonomies Type: 11 (.google.cloud.datacatalog.v1beta1.SerializedTaxonomy)

# === Service Client: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::PolicyTagManagerSerializationClient ===
package Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::PolicyTagManagerSerializationClient;

=pod

=head2 Service Client: Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::PolicyTagManagerSerializationClient

Client stub representing the remote C<PolicyTagManagerSerialization> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<datacatalog.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'datacatalog.googleapis.com:443' );

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

sub import_taxonomies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManagerSerialization',
        method         => 'ImportTaxonomies',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesResponse',
    });
}

sub export_taxonomies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.datacatalog.v1beta1.PolicyTagManagerSerialization',
        method         => 'ExportTaxonomies',
        request        => $req,
        response_class => 'Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/policytagmanagerserialization.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization;

    my $msg = Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy->new({
        display_name => $display_name,
        description => $description,
        policy_tags => $policy_tags,
        activated_policy_types => $activated_policy_types,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/policytagmanagerserialization.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy

Message capturing a taxonomy and its policy tag hierarchy as a nested proto.
Used for taxonomy import/export and mutation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the taxonomy. Max 200 bytes when encoded in
UTF-8.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the serialized taxonomy. The length of the
description is limited to 2000 bytes when encoded in UTF-8. If not set,
defaults to an empty description.

=item * C<< $msg->policy_tags() >> / C<< $msg->policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag>)

Top level policy tags associated with the taxonomy if any.

=item * C<< $msg->activated_policy_types() >> / C<< $msg->activated_policy_types($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1beta1::Taxonomy::PolicyType>)

A list of policy types that are activated for a taxonomy.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag

Message representing one policy tag when exported as a nested proto.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<String>

Resource name of the policy tag.

This field will be ignored when calling ImportTaxonomies.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the policy tag. Max 200 bytes when encoded in
UTF-8.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the serialized policy tag. The length of the
description is limited to 2000 bytes when encoded in UTF-8. If not set,
defaults to an empty description.

=item * C<< $msg->child_policy_tags() >> / C<< $msg->child_policy_tags($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedPolicyTag>)

Children of the policy tag if any.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesRequest

Request message for
[ImportTaxonomies][google.cloud.datacatalog.v1beta1.PolicyTagManagerSerialization.ImportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of project that the imported taxonomies will belong
to.

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::InlineSource>)

Inline source used for taxonomies to be imported.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::InlineSource

Inline source used for taxonomies import.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy>)

Required. Taxonomies to be imported.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ImportTaxonomiesResponse

Response message for
[ImportTaxonomies][google.cloud.datacatalog.v1beta1.PolicyTagManagerSerialization.ImportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanager::Taxonomy>)

Taxonomies that were imported.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesRequest

Request message for
[ExportTaxonomies][google.cloud.datacatalog.v1beta1.PolicyTagManagerSerialization.ExportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that taxonomies to be exported
will share.

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<String>

Required. Resource names of the taxonomies to be exported.

=item * C<< $msg->serialized_taxonomies() >> / C<< $msg->serialized_taxonomies($value) >>

Type: C<Bool>

Export taxonomies as serialized taxonomies.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::ExportTaxonomiesResponse

Response message for
[ExportTaxonomies][google.cloud.datacatalog.v1beta1.PolicyTagManagerSerialization.ExportTaxonomies].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->taxonomies() >> / C<< $msg->taxonomies($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::SerializedTaxonomy>)

List of taxonomies and policy tags in a tree structure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::Policytagmanagerserialization::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
