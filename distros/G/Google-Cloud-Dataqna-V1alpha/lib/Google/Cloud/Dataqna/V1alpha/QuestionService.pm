package Google::Cloud::Dataqna::V1alpha::QuestionService;

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
    eval { require Google::Cloud::Dataqna::V1alpha::Question };
    eval { require Google::Cloud::Dataqna::V1alpha::UserFeedback };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFscGhhL3F1ZXN0aW9uX3NlcnZpY2UucHJvdG8S
HGdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGitnb29nbGUvY2xvdWQvZGF0
YXFuYS92MWFscGhhL3F1ZXN0aW9uLnByb3RvGjBnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFs
cGhhL3VzZXJfZmVlZGJhY2sucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvIooBChJHZXRRdWVzdGlvblJlcXVlc3QSOwoEbmFtZRgBIAEoCUIn4EEC+kEhCh9kYXRh
cW5hLmdvb2dsZWFwaXMuY29tL1F1ZXN0aW9uUgRuYW1lEjcKCXJlYWRfbWFzaxgCIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCHJlYWRNYXNrIqMBChVDcmVhdGVRdWVzdGlv
blJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlz
LmNvbS9Mb2NhdGlvblIGcGFyZW50EkcKCHF1ZXN0aW9uGAIgASgLMiYuZ29vZ2xlLmNsb3Vk
LmRhdGFxbmEudjFhbHBoYS5RdWVzdGlvbkID4EECUghxdWVzdGlvbiJpChZFeGVjdXRlUXVl
c3Rpb25SZXF1ZXN0EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRI2ChRpbnRlcnByZXRhdGlv
bl9pbmRleBgCIAEoBUID4EECUhNpbnRlcnByZXRhdGlvbkluZGV4IlkKFkdldFVzZXJGZWVk
YmFja1JlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNkYXRhcW5hLmdvb2dsZWFwaXMu
Y29tL1VzZXJGZWVkYmFja1IEbmFtZSKuAQoZVXBkYXRlVXNlckZlZWRiYWNrUmVxdWVzdBJU
Cg11c2VyX2ZlZWRiYWNrGAEgASgLMiouZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5V
c2VyRmVlZGJhY2tCA+BBAlIMdXNlckZlZWRiYWNrEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzazLsCAoPUXVlc3Rpb25TZXJ2
aWNlEqoBCgtHZXRRdWVzdGlvbhIwLmdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEuR2V0
UXVlc3Rpb25SZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5RdWVzdGlv
biJBgtPkkwI0EjIvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3F1ZXN0
aW9ucy8qfdpBBG5hbWUSxQEKDkNyZWF0ZVF1ZXN0aW9uEjMuZ29vZ2xlLmNsb3VkLmRhdGFx
bmEudjFhbHBoYS5DcmVhdGVRdWVzdGlvblJlcXVlc3QaJi5nb29nbGUuY2xvdWQuZGF0YXFu
YS52MWFscGhhLlF1ZXN0aW9uIlaC0+STAj4iMi92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKn0vcXVlc3Rpb25zOghxdWVzdGlvbtpBD3BhcmVudCxxdWVzdGlvbhLS
AQoPRXhlY3V0ZVF1ZXN0aW9uEjQuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5FeGVj
dXRlUXVlc3Rpb25SZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5RdWVz
dGlvbiJhgtPkkwI/IjovdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3F1
ZXN0aW9ucy8qfTpleGVjdXRlOgEq2kEZbmFtZSxpbnRlcnByZXRhdGlvbl9pbmRleBLDAQoP
R2V0VXNlckZlZWRiYWNrEjQuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5HZXRVc2Vy
RmVlZGJhY2tSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5Vc2VyRmVl
ZGJhY2siToLT5JMCQRI/L3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9x
dWVzdGlvbnMvKi91c2VyRmVlZGJhY2t92kEEbmFtZRL8AQoSVXBkYXRlVXNlckZlZWRiYWNr
EjcuZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5VcGRhdGVVc2VyRmVlZGJhY2tSZXF1
ZXN0GiouZ29vZ2xlLmNsb3VkLmRhdGFxbmEudjFhbHBoYS5Vc2VyRmVlZGJhY2sigAGC0+ST
Al4yTS92MWFscGhhL3t1c2VyX2ZlZWRiYWNrLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9xdWVzdGlvbnMvKi91c2VyRmVlZGJhY2t9Og11c2VyX2ZlZWRiYWNr2kEZdXNlcl9mZWVk
YmFjayx1cGRhdGVfbWFzaxpKykEWZGF0YXFuYS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C1gEKIGNvbS5nb29nbGUu
Y2xvdWQuZGF0YXFuYS52MWFscGhhQhRRdWVzdGlvblNlcnZpY2VQcm90b1ABWjpjbG91ZC5n
b29nbGUuY29tL2dvL2RhdGFxbmEvYXBpdjFhbHBoYS9kYXRhcW5hcGI7ZGF0YXFuYXBiqgIc
R29vZ2xlLkNsb3VkLkRhdGFRbkEuVjFBbHBoYcoCHEdvb2dsZVxDbG91ZFxEYXRhUW5BXFYx
YWxwaGHqAh9Hb29nbGU6OkNsb3VkOjpEYXRhUW5BOjpWMWFscGhhStUjCgcSBQ4AoQEBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACYK
CQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANQoJCgIDBRIDFwA6
CgkKAgMGEgMYACoKCAoBCBIDGgA5CgkKAgglEgMaADkKCAoBCBIDGwBRCgkKAggLEgMbAFEK
CAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA1CgkKAggIEgMdADUKCAoBCBIDHgA5CgkK
AggBEgMeADkKCAoBCBIDHwA5CgkKAggpEgMfADkKCAoBCBIDIAA4CgkKAggtEgMgADgKuQYK
AgYAEgQxAGABGqwGIFNlcnZpY2UgdG8gaW50ZXJwcmV0IG5hdHVyYWwgbGFuZ3VhZ2UgcXVl
cmllcy4KIFRoZSBzZXJ2aWNlIGFsbG93cyB0byBjcmVhdGUgYFF1ZXN0aW9uYCByZXNvdXJj
ZXMgdGhhdCBhcmUgaW50ZXJwcmV0ZWQgYW5kCiBhcmUgZmlsbGVkIHdpdGggb25lIG9yIG1v
cmUgaW50ZXJwcmV0YXRpb25zIGlmIHRoZSBxdWVzdGlvbiBjb3VsZCBiZQogaW50ZXJwcmV0
ZWQuIE9uY2UgYSBgUXVlc3Rpb25gIHJlc291cmNlIGlzIGNyZWF0ZWQgYW5kIGhhcyBhdCBs
ZWFzdCBvbmUKIGludGVycHJldGF0aW9uLCBhbiBpbnRlcnByZXRhdGlvbiBjYW4gYmUgY2hv
c2VuIGZvciBleGVjdXRpb24sIHdoaWNoCiB0cmlnZ2VycyBhIHF1ZXJ5IHRvIHRoZSBiYWNr
ZW5kIChmb3IgQmlnUXVlcnksIGl0IHdpbGwgY3JlYXRlIGEgam9iKS4KIFVwb24gc3VjY2Vz
c2Z1bCBleGVjdXRpb24gb2YgdGhhdCBpbnRlcnByZXRhdGlvbiwgYmFja2VuZCBzcGVjaWZp
YwogaW5mb3JtYXRpb24gd2lsbCBiZSByZXR1cm5lZCBzbyB0aGF0IHRoZSBjbGllbnQgY2Fu
IHJldHJpZXZlIHRoZSByZXN1bHRzCiBmcm9tIHRoZSBiYWNrZW5kLgoKIFRoZSBgUXVlc3Rp
b25gIHJlc291cmNlcyBhcmUgbmFtZWQgYHByb2plY3RzLyovbG9jYXRpb25zLyovcXVlc3Rp
b25zLypgLgoKIFRoZSBgUXVlc3Rpb25gIHJlc291cmNlIGhhcyBhIHNpbmdsZXRpb24gc3Vi
LXJlc291cmNlIGBVc2VyRmVlZGJhY2tgIG5hbWVkCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9xdWVzdGlvbnMvKi91c2VyRmVlZGJhY2tgLCB3aGljaCBhbGxvd3MgYWNjZXNzIHRvCiB1
c2VyIGZlZWRiYWNrLgoKCgoDBgABEgMxCBcKCgoDBgADEgMyAj4KDAoFBgADmQgSAzICPgoK
CgMGAAMSAzMCVgoMCgUGAAOaCBIDMwJWCjMKBAYAAgASBDYCOwMaJSBHZXRzIGEgcHJldmlv
dXNseSBjcmVhdGVkIHF1ZXN0aW9uLgoKDAoFBgACAAESAzYGEQoMCgUGAAIAAhIDNhIkCgwK
BQYAAgADEgM2LzcKDQoFBgACAAQSBDcEOQYKEQoJBgACAASwyrwiEgQ3BDkGCgwKBQYAAgAE
EgM6BDIKDwoIBgACAASbCAASAzoEMgojCgQGAAIBEgQ+AkQDGhUgQ3JlYXRlcyBhIHF1ZXN0
aW9uLgoKDAoFBgACAQESAz4GFAoMCgUGAAIBAhIDPhUqCgwKBQYAAgEDEgM+NT0KDQoFBgAC
AQQSBD8EQgYKEQoJBgACAQSwyrwiEgQ/BEIGCgwKBQYAAgEEEgNDBD0KDwoIBgACAQSbCAAS
A0MEPQorCgQGAAICEgRHAk0DGh0gRXhlY3V0ZXMgYW4gaW50ZXJwcmV0YXRpb24uCgoMCgUG
AAICARIDRwYVCgwKBQYAAgICEgNHFiwKDAoFBgACAgMSA0c3PwoNCgUGAAICBBIESARLBgoR
CgkGAAICBLDKvCISBEgESwYKDAoFBgACAgQSA0wERwoPCggGAAICBJsIABIDTARHCjYKBAYA
AgMSBFACVQMaKCBHZXRzIHByZXZpb3VzbHkgY3JlYXRlZCB1c2VyIGZlZWRiYWNrLgoKDAoF
BgACAwESA1AGFQoMCgUGAAIDAhIDUBYsCgwKBQYAAgMDEgNQN0MKDQoFBgACAwQSBFEEUwYK
EQoJBgACAwSwyrwiEgRRBFMGCgwKBQYAAgMEEgNUBDIKDwoIBgACAwSbCAASA1QEMgplCgQG
AAIEEgRZAl8DGlcgVXBkYXRlcyB1c2VyIGZlZWRiYWNrLiBUaGlzIGNyZWF0ZXMgdXNlciBm
ZWVkYmFjayBpZiB0aGVyZSB3YXMgbm9uZSBiZWZvcmUKICh1cHNlcnQpLgoKDAoFBgACBAES
A1kGGAoMCgUGAAIEAhIDWRkyCgwKBQYAAgQDEgNZPUkKDQoFBgACBAQSBFoEXQYKEQoJBgAC
BASwyrwiEgRaBF0GCgwKBQYAAgQEEgNeBEcKDwoIBgACBASbCAASA14ERwo9CgIEABIEYwBv
ARoxIEEgcmVxdWVzdCB0byBnZXQgYSBwcmV2aW91c2x5IGNyZWF0ZWQgcXVlc3Rpb24uCgoK
CgMEAAESA2MIGgp3CgQEAAIAEgRmAmsEGmkgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRp
ZmllciBmb3IgdGhlIHF1ZXN0aW9uLgogRXhhbXBsZTogYHByb2plY3RzL2Zvby9sb2NhdGlv
bnMvYmFyL3F1ZXN0aW9ucy8xMjM0YAoKDAoFBAACAAUSA2YCCAoMCgUEAAIAARIDZgkNCgwK
BQQAAgADEgNmEBEKDQoFBAACAAgSBGYSawMKDwoIBAACAAicCAASA2cEKgoPCgcEAAIACJ8I
EgRoBGoFCjIKBAQAAgESA24CKholIFRoZSBsaXN0IG9mIGZpZWxkcyB0byBiZSByZXRyaWV2
ZWQuCgoMCgUEAAIBBhIDbgIbCgwKBQQAAgEBEgNuHCUKDAoFBAACAQMSA24oKQo0CgIEARIE
cgB+ARooIFJlcXVlc3QgdG8gY3JlYXRlIGEgcXVlc3Rpb24gcmVzb3VyY2UuCgoKCgMEAQES
A3IIHQp/CgQEAQIAEgR1AnoEGnEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwcm9qZWN0
IHRoaXMgZGF0YSBzb3VyY2UgcmVmZXJlbmNlIGJlbG9uZ3MgdG8uCiBFeGFtcGxlOiBgcHJv
amVjdHMvZm9vL2xvY2F0aW9ucy9iYXJgCgoMCgUEAQIABRIDdQIICgwKBQQBAgABEgN1CQ8K
DAoFBAECAAMSA3USEwoNCgUEAQIACBIEdRR6AwoPCggEAQIACJwIABIDdgQqCg8KBwQBAgAI
nwgSBHcEeQUKMAoEBAECARIDfQJBGiMgUmVxdWlyZWQuIFRoZSBxdWVzdGlvbiB0byBjcmVh
dGUuCgoMCgUEAQIBBhIDfQIKCgwKBQQBAgEBEgN9CxMKDAoFBAECAQMSA30WFwoMCgUEAQIB
CBIDfRhACg8KCAQBAgEInAgAEgN9GT8KNQoCBAISBoEBAIgBARonIFJlcXVlc3QgdG8gZXhl
Y3V0ZSBhbiBpbnRlcnByZXRhdGlvbi4KCgsKAwQCARIEgQEIHgp3CgQEAgIAEgSEAQI7Gmkg
UmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIHF1ZXN0aW9uLgogRXhh
bXBsZTogYHByb2plY3RzL2Zvby9sb2NhdGlvbnMvYmFyL3F1ZXN0aW9ucy8xMjM0YAoKDQoF
BAICAAUSBIQBAggKDQoFBAICAAESBIQBCQ0KDQoFBAICAAMSBIQBEBEKDQoFBAICAAgSBIQB
EjoKEAoIBAICAAicCAASBIQBEzkKQQoEBAICARIEhwECShozIFJlcXVpcmVkLiBJbmRleCBv
ZiB0aGUgaW50ZXJwcmV0YXRpb24gdG8gZXhlY3V0ZS4KCg0KBQQCAgEFEgSHAQIHCg0KBQQC
AgEBEgSHAQgcCg0KBQQCAgEDEgSHAR8gCg0KBQQCAgEIEgSHASFJChAKCAQCAgEInAgAEgSH
ASJICi0KAgQDEgaLAQCVAQEaHyBSZXF1ZXN0IHRvIGdldCB1c2VyIGZlZWRiYWNrLgoKCwoD
BAMBEgSLAQgeCsIBCgQEAwIAEgaPAQKUAQQasQEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRl
bnRpZmllciBmb3IgdGhlIHVzZXIgZmVlZGJhY2suCiBVc2VyIGZlZWRiYWNrIGlzIGEgc2lu
Z2xldG9uIHJlc291cmNlIG9uIGEgUXVlc3Rpb24uCiBFeGFtcGxlOiBgcHJvamVjdHMvZm9v
L2xvY2F0aW9ucy9iYXIvcXVlc3Rpb25zLzEyMzQvdXNlckZlZWRiYWNrYAoKDQoFBAMCAAUS
BI8BAggKDQoFBAMCAAESBI8BCQ0KDQoFBAMCAAMSBI8BEBEKDwoFBAMCAAgSBo8BEpQBAwoQ
CggEAwIACJwIABIEkAEEKgoRCgcEAwIACJ8IEgaRAQSTAQUKMQoCBAQSBpgBAKEBARojIFJl
cXVlc3QgdG8gdXBkYXRlcyB1c2VyIGZlZWRiYWNrLgoKCwoDBAQBEgSYAQghCuMBCgQEBAIA
EgSdAQJKGtQBIFJlcXVpcmVkLiBUaGUgdXNlciBmZWVkYmFjayB0byB1cGRhdGUuIFRoaXMg
Y2FuIGJlIGNhbGxlZCBldmVuIGlmIHRoZXJlIGlzIG5vCiB1c2VyIGZlZWRiYWNrIHNvIGZh
ci4KIFRoZSBmZWVkYmFjaydzIG5hbWUgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUg
dXNlciBmZWVkYmFjayAoYW5kIHRoZQogY29ycmVzcG9uZGluZyBxdWVzdGlvbikgdG8gdXBk
YXRlLgoKDQoFBAQCAAYSBJ0BAg4KDQoFBAQCAAESBJ0BDxwKDQoFBAQCAAMSBJ0BHyAKDQoF
BAQCAAgSBJ0BIUkKEAoIBAQCAAicCAASBJ0BIkgKMQoEBAQCARIEoAECLBojIFRoZSBsaXN0
IG9mIGZpZWxkcyB0byBiZSB1cGRhdGVkLgoKDQoFBAQCAQYSBKABAhsKDQoFBAQCAQESBKAB
HCcKDQoFBAQCAQMSBKABKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest ===
    # Fields for GetQuestionRequest
    # Field: name Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dataqna::V1alpha::QuestionService::CreateQuestionRequest ===
    # Fields for CreateQuestionRequest
    # Field: parent Type: 9 ()
    # Field: question Type: 11 (.google.cloud.dataqna.v1alpha.Question)

# === Message: Google::Cloud::Dataqna::V1alpha::QuestionService::ExecuteQuestionRequest ===
    # Fields for ExecuteQuestionRequest
    # Field: name Type: 9 ()
    # Field: interpretation_index Type: 5 ()

# === Message: Google::Cloud::Dataqna::V1alpha::QuestionService::GetUserFeedbackRequest ===
    # Fields for GetUserFeedbackRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest ===
    # Fields for UpdateUserFeedbackRequest
    # Field: user_feedback Type: 11 (.google.cloud.dataqna.v1alpha.UserFeedback)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Dataqna::V1alpha::QuestionService::QuestionServiceClient ===
package Google::Cloud::Dataqna::V1alpha::QuestionService::QuestionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dataqna::V1alpha::QuestionService::QuestionServiceClient

Client stub representing the remote C<QuestionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dataqna.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataqna.googleapis.com:443' );

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

sub get_question {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataqna.v1alpha.QuestionService',
        method         => 'GetQuestion',
        request        => $req,
        response_class => 'Google::Cloud::Dataqna::V1alpha::Question::Question',
    });
}

sub create_question {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataqna::V1alpha::QuestionService::CreateQuestionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataqna.v1alpha.QuestionService',
        method         => 'CreateQuestion',
        request        => $req,
        response_class => 'Google::Cloud::Dataqna::V1alpha::Question::Question',
    });
}

sub execute_question {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataqna::V1alpha::QuestionService::ExecuteQuestionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataqna.v1alpha.QuestionService',
        method         => 'ExecuteQuestion',
        request        => $req,
        response_class => 'Google::Cloud::Dataqna::V1alpha::Question::Question',
    });
}

sub get_user_feedback {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataqna::V1alpha::QuestionService::GetUserFeedbackRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataqna.v1alpha.QuestionService',
        method         => 'GetUserFeedback',
        request        => $req,
        response_class => 'Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback',
    });
}

sub update_user_feedback {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataqna.v1alpha.QuestionService',
        method         => 'UpdateUserFeedback',
        request        => $req,
        response_class => 'Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataqna::V1alpha::QuestionService - Compiled Protocol Buffers messages for google/cloud/dataqna/v1alpha/question_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataqna::V1alpha::QuestionService;

    my $msg = Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest->new({
        name => $name,
        read_mask => $read_mask,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataqna/v1alpha/question_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest

A request to get a previously created question.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the question.
Example: `projects/foo/locations/bar/questions/1234`

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be retrieved.

=back

=head2 Google::Cloud::Dataqna::V1alpha::QuestionService::CreateQuestionRequest

Request to create a question resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project this data source reference belongs to.
Example: `projects/foo/locations/bar`

=item * C<< $msg->question() >> / C<< $msg->question($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::Question::Question>)

Required. The question to create.

=back

=head2 Google::Cloud::Dataqna::V1alpha::QuestionService::ExecuteQuestionRequest

Request to execute an interpretation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the question.
Example: `projects/foo/locations/bar/questions/1234`

=item * C<< $msg->interpretation_index() >> / C<< $msg->interpretation_index($value) >>

Type: C<Int32>

Required. Index of the interpretation to execute.

=back

=head2 Google::Cloud::Dataqna::V1alpha::QuestionService::GetUserFeedbackRequest

Request to get user feedback.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier for the user feedback.
User feedback is a singleton resource on a Question.
Example: `projects/foo/locations/bar/questions/1234/userFeedback`

=back

=head2 Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest

Request to updates user feedback.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_feedback() >> / C<< $msg->user_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback>)

Required. The user feedback to update. This can be called even if there is no
user feedback so far.
The feedback's name field is used to identify the user feedback (and the
corresponding question) to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to be updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataqna::V1alpha::QuestionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
