package Google::Appengine::V1::Application;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvYXBwZW5naW5lL3YxL2FwcGxpY2F0aW9uLnByb3RvEhNnb29nbGUuYXBwZW5n
aW5lLnYxGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8iwAoKC0FwcGxpY2F0aW9u
EhIKBG5hbWUYASABKAlSBG5hbWUSDgoCaWQYAiABKAlSAmlkEksKDmRpc3BhdGNoX3J1bGVz
GAMgAygLMiQuZ29vZ2xlLmFwcGVuZ2luZS52MS5VcmxEaXNwYXRjaFJ1bGVSDWRpc3BhdGNo
UnVsZXMSHwoLYXV0aF9kb21haW4YBiABKAlSCmF1dGhEb21haW4SHwoLbG9jYXRpb25faWQY
ByABKAlSCmxvY2F0aW9uSWQSHwoLY29kZV9idWNrZXQYCCABKAlSCmNvZGVCdWNrZXQSVQoZ
ZGVmYXVsdF9jb29raWVfZXhwaXJhdGlvbhgJIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJh
dGlvblIXZGVmYXVsdENvb2tpZUV4cGlyYXRpb24SVQoOc2VydmluZ19zdGF0dXMYCiABKA4y
Li5nb29nbGUuYXBwZW5naW5lLnYxLkFwcGxpY2F0aW9uLlNlcnZpbmdTdGF0dXNSDXNlcnZp
bmdTdGF0dXMSKQoQZGVmYXVsdF9ob3N0bmFtZRgLIAEoCVIPZGVmYXVsdEhvc3RuYW1lEiUK
DmRlZmF1bHRfYnVja2V0GAwgASgJUg1kZWZhdWx0QnVja2V0EicKD3NlcnZpY2VfYWNjb3Vu
dBgNIAEoCVIOc2VydmljZUFjY291bnQSRQoDaWFwGA4gASgLMjMuZ29vZ2xlLmFwcGVuZ2lu
ZS52MS5BcHBsaWNhdGlvbi5JZGVudGl0eUF3YXJlUHJveHlSA2lhcBIdCgpnY3JfZG9tYWlu
GBAgASgJUglnY3JEb21haW4SUgoNZGF0YWJhc2VfdHlwZRgRIAEoDjItLmdvb2dsZS5hcHBl
bmdpbmUudjEuQXBwbGljYXRpb24uRGF0YWJhc2VUeXBlUgxkYXRhYmFzZVR5cGUSWwoQZmVh
dHVyZV9zZXR0aW5ncxgSIAEoCzIwLmdvb2dsZS5hcHBlbmdpbmUudjEuQXBwbGljYXRpb24u
RmVhdHVyZVNldHRpbmdzUg9mZWF0dXJlU2V0dGluZ3MayQEKEklkZW50aXR5QXdhcmVQcm94
eRIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEigKEG9hdXRoMl9jbGllbnRfaWQYAiABKAlS
Dm9hdXRoMkNsaWVudElkEjAKFG9hdXRoMl9jbGllbnRfc2VjcmV0GAMgASgJUhJvYXV0aDJD
bGllbnRTZWNyZXQSPQobb2F1dGgyX2NsaWVudF9zZWNyZXRfc2hhMjU2GAQgASgJUhhvYXV0
aDJDbGllbnRTZWNyZXRTaGEyNTYafgoPRmVhdHVyZVNldHRpbmdzEi4KE3NwbGl0X2hlYWx0
aF9jaGVja3MYASABKAhSEXNwbGl0SGVhbHRoQ2hlY2tzEjsKGnVzZV9jb250YWluZXJfb3B0
aW1pemVkX29zGAIgASgIUhd1c2VDb250YWluZXJPcHRpbWl6ZWRPcyJVCg1TZXJ2aW5nU3Rh
dHVzEg8KC1VOU1BFQ0lGSUVEEAASCwoHU0VSVklORxABEhEKDVVTRVJfRElTQUJMRUQQAhIT
Cg9TWVNURU1fRElTQUJMRUQQAyJ6CgxEYXRhYmFzZVR5cGUSHQoZREFUQUJBU0VfVFlQRV9V
TlNQRUNJRklFRBAAEhMKD0NMT1VEX0RBVEFTVE9SRRABEhMKD0NMT1VEX0ZJUkVTVE9SRRAC
EiEKHUNMT1VEX0RBVEFTVE9SRV9DT01QQVRJQklMSVRZEAMiVwoPVXJsRGlzcGF0Y2hSdWxl
EhYKBmRvbWFpbhgBIAEoCVIGZG9tYWluEhIKBHBhdGgYAiABKAlSBHBhdGgSGAoHc2Vydmlj
ZRgDIAEoCVIHc2VydmljZULBAQoXY29tLmdvb2dsZS5hcHBlbmdpbmUudjFCEEFwcGxpY2F0
aW9uUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBlbmdpbmUvYXBpdjEvYXBwZW5n
aW5lcGI7YXBwZW5naW5lcGKqAhlHb29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxygIZR29vZ2xl
XENsb3VkXEFwcEVuZ2luZVxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFKvTQK
BxIFDgDFAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwK
CQoCAwASAxIAKAoICgEIEgMUADYKCQoCCCUSAxQANgoICgEIEgMVAFIKCQoCCAsSAxUAUgoI
CgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADEKCQoCCAgSAxcAMQoICgEIEgMYADAKCQoC
CAESAxgAMAoICgEIEgMZADYKCQoCCCkSAxkANgoICgEIEgMaADUKCQoCCC0SAxoANQpqCgIE
ABIFHgCwAQEaXSBBbiBBcHBsaWNhdGlvbiByZXNvdXJjZSBjb250YWlucyB0aGUgdG9wLWxl
dmVsIGNvbmZpZ3VyYXRpb24gb2YgYW4gQXBwCiBFbmdpbmUgYXBwbGljYXRpb24uCgoKCgME
AAESAx4IEwoMCgQEAAQAEgQfAisDCgwKBQQABAABEgMfBxQKLwoGBAAEAAIAEgMhBBQaICBT
ZXJ2aW5nIHN0YXR1cyBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAyEEDwoOCgcEAAQA
AgACEgMhEhMKKAoGBAAEAAIBEgMkBBAaGSBBcHBsaWNhdGlvbiBpcyBzZXJ2aW5nLgoKDgoH
BAAEAAIBARIDJAQLCg4KBwQABAACAQISAyQODwo7CgYEAAQAAgISAycEFhosIEFwcGxpY2F0
aW9uIGhhcyBiZWVuIGRpc2FibGVkIGJ5IHRoZSB1c2VyLgoKDgoHBAAEAAICARIDJwQRCg4K
BwQABAACAgISAycUFQo9CgYEAAQAAgMSAyoEGBouIEFwcGxpY2F0aW9uIGhhcyBiZWVuIGRp
c2FibGVkIGJ5IHRoZSBzeXN0ZW0uCgoOCgcEAAQAAgMBEgMqBBMKDgoHBAAEAAIDAhIDKhYX
CiQKBAQAAwASBC4CRgMaFiBJZGVudGl0eS1Bd2FyZSBQcm94eQoKDAoFBAADAAESAy4KHArE
AQoGBAADAAIAEgM0BBUatAEgV2hldGhlciB0aGUgc2VydmluZyBpbmZyYXN0cnVjdHVyZSB3
aWxsIGF1dGhlbnRpY2F0ZSBhbmQKIGF1dGhvcml6ZSBhbGwgaW5jb21pbmcgcmVxdWVzdHMu
CgogSWYgdHJ1ZSwgdGhlIGBvYXV0aDJfY2xpZW50X2lkYCBhbmQgYG9hdXRoMl9jbGllbnRf
c2VjcmV0YAogZmllbGRzIG11c3QgYmUgbm9uLWVtcHR5LgoKDgoHBAADAAIABRIDNAQICg4K
BwQAAwACAAESAzQJEAoOCgcEAAMAAgADEgM0ExQKRQoGBAADAAIBEgM3BCAaNiBPQXV0aDIg
Y2xpZW50IElEIHRvIHVzZSBmb3IgdGhlIGF1dGhlbnRpY2F0aW9uIGZsb3cuCgoOCgcEAAMA
AgEFEgM3BAoKDgoHBAADAAIBARIDNwsbCg4KBwQAAwACAQMSAzceHwr8AQoGBAADAAICEgNA
BCQa7AEgT0F1dGgyIGNsaWVudCBzZWNyZXQgdG8gdXNlIGZvciB0aGUgYXV0aGVudGljYXRp
b24gZmxvdy4KCiBGb3Igc2VjdXJpdHkgcmVhc29ucywgdGhpcyB2YWx1ZSBjYW5ub3QgYmUg
cmV0cmlldmVkIHZpYSB0aGUgQVBJLgogSW5zdGVhZCwgdGhlIFNIQS0yNTYgaGFzaCBvZiB0
aGUgdmFsdWUgaXMgcmV0dXJuZWQgaW4gdGhlCiBgb2F1dGgyX2NsaWVudF9zZWNyZXRfc2hh
MjU2YCBmaWVsZC4KCiBASW5wdXRPbmx5CgoOCgcEAAMAAgIFEgNABAoKDgoHBAADAAICARID
QAsfCg4KBwQAAwACAgMSA0AiIwpNCgYEAAMAAgMSA0UEKxo+IEhleC1lbmNvZGVkIFNIQS0y
NTYgaGFzaCBvZiB0aGUgY2xpZW50IHNlY3JldC4KCiBAT3V0cHV0T25seQoKDgoHBAADAAID
BRIDRQQKCg4KBwQAAwACAwESA0ULJgoOCgcEAAMAAgMDEgNFKSoKDAoEBAAEARIESAJUAwoM
CgUEAAQBARIDSAcTCi4KBgQABAECABIDSgQiGh8gRGF0YWJhc2UgdHlwZSBpcyB1bnNwZWNp
ZmllZC4KCg4KBwQABAECAAESA0oEHQoOCgcEAAQBAgACEgNKICEKIAoGBAAEAQIBEgNNBBga
ESBDbG91ZCBEYXRhc3RvcmUKCg4KBwQABAECAQESA00EEwoOCgcEAAQBAgECEgNNFhcKJwoG
BAAEAQICEgNQBBgaGCBDbG91ZCBGaXJlc3RvcmUgTmF0aXZlCgoOCgcEAAQBAgIBEgNQBBMK
DgoHBAAEAQICAhIDUBYXCjIKBgQABAECAxIDUwQmGiMgQ2xvdWQgRmlyZXN0b3JlIGluIERh
dGFzdG9yZSBNb2RlCgoOCgcEAAQBAgMBEgNTBCEKDgoHBAAEAQIDAhIDUyQlCoABCgQEAAMB
EgRYAmQDGnIgVGhlIGZlYXR1cmUgc3BlY2lmaWMgc2V0dGluZ3MgdG8gYmUgdXNlZCBpbiB0
aGUgYXBwbGljYXRpb24uIFRoZXNlIGRlZmluZQogYmVoYXZpb3JzIHRoYXQgYXJlIHVzZXIg
Y29uZmlndXJhYmxlLgoKDAoFBAADAQESA1gKGQrqAgoGBAADAQIAEgNfBCEa2gIgQm9vbGVh
biB2YWx1ZSBpbmRpY2F0aW5nIGlmIHNwbGl0IGhlYWx0aCBjaGVja3Mgc2hvdWxkIGJlIHVz
ZWQgaW5zdGVhZAogb2YgdGhlIGxlZ2FjeSBoZWFsdGggY2hlY2tzLiBBdCBhbiBhcHAueWFt
bCBsZXZlbCwgdGhpcyBtZWFucyBkZWZhdWx0aW5nCiB0byAncmVhZGluZXNzX2NoZWNrJyBh
bmQgJ2xpdmVuZXNzX2NoZWNrJyB2YWx1ZXMgaW5zdGVhZCBvZgogJ2hlYWx0aF9jaGVjaycg
b25lcy4gT25jZSB0aGUgbGVnYWN5ICdoZWFsdGhfY2hlY2snIGJlaGF2aW9yIGlzCiBkZXBy
ZWNhdGVkLCBhbmQgdGhpcyB2YWx1ZSBpcyBhbHdheXMgdHJ1ZSwgdGhpcyBzZXR0aW5nIGNh
bgogYmUgcmVtb3ZlZC4KCg4KBwQAAwECAAUSA18ECAoOCgcEAAMBAgABEgNfCRwKDgoHBAAD
AQIAAxIDXx8gCp8BCgYEAAMBAgESA2MEKBqPASBJZiB0cnVlLCB1c2UgW0NvbnRhaW5lci1P
cHRpbWl6ZWQgT1NdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb250YWluZXItb3B0aW1p
emVkLW9zLykKIGJhc2UgaW1hZ2UgZm9yIFZNcywgcmF0aGVyIHRoYW4gYSBiYXNlIERlYmlh
biBpbWFnZS4KCg4KBwQAAwECAQUSA2MECAoOCgcEAAMBAgEBEgNjCSMKDgoHBAADAQIBAxID
YyYnCmYKBAQAAgASA2oCEhpZIEZ1bGwgcGF0aCB0byB0aGUgQXBwbGljYXRpb24gcmVzb3Vy
Y2UgaW4gdGhlIEFQSS4KIEV4YW1wbGU6IGBhcHBzL215YXBwYC4KCiBAT3V0cHV0T25seQoK
DAoFBAACAAUSA2oCCAoMCgUEAAIAARIDagkNCgwKBQQAAgADEgNqEBEKzAEKBAQAAgESA3AC
EBq+ASBJZGVudGlmaWVyIG9mIHRoZSBBcHBsaWNhdGlvbiByZXNvdXJjZS4gVGhpcyBpZGVu
dGlmaWVyIGlzIGVxdWl2YWxlbnQKIHRvIHRoZSBwcm9qZWN0IElEIG9mIHRoZSBHb29nbGUg
Q2xvdWQgUGxhdGZvcm0gcHJvamVjdCB3aGVyZSB5b3Ugd2FudCB0bwogZGVwbG95IHlvdXIg
YXBwbGljYXRpb24uCiBFeGFtcGxlOiBgbXlhcHBgLgoKDAoFBAACAQUSA3ACCAoMCgUEAAIB
ARIDcAkLCgwKBQQAAgEDEgNwDg8KwwEKBAQAAgISA3UCLhq1ASBIVFRQIHBhdGggZGlzcGF0
Y2ggcnVsZXMgZm9yIHJlcXVlc3RzIHRvIHRoZSBhcHBsaWNhdGlvbiB0aGF0IGRvIG5vdAog
ZXhwbGljaXRseSB0YXJnZXQgYSBzZXJ2aWNlIG9yIHZlcnNpb24uIFJ1bGVzIGFyZSBvcmRl
ci1kZXBlbmRlbnQuCiBVcCB0byAyMCBkaXNwYXRjaCBydWxlcyBjYW4gYmUgc3VwcG9ydGVk
LgoKDAoFBAACAgQSA3UCCgoMCgUEAAICBhIDdQsaCgwKBQQAAgIBEgN1GykKDAoFBAACAgMS
A3UsLQqbAQoEBAACAxIDewIZGo0BIEdvb2dsZSBBcHBzIGF1dGhlbnRpY2F0aW9uIGRvbWFp
biB0aGF0IGNvbnRyb2xzIHdoaWNoIHVzZXJzIGNhbiBhY2Nlc3MKIHRoaXMgYXBwbGljYXRp
b24uCgogRGVmYXVsdHMgdG8gb3BlbiBhY2Nlc3MgZm9yIGFueSBHb29nbGUgQWNjb3VudC4K
CgwKBQQAAgMFEgN7AggKDAoFBAACAwESA3sJFAoMCgUEAAIDAxIDexcYCs0CCgQEAAIEEgSF
AQIZGr4CIExvY2F0aW9uIGZyb20gd2hpY2ggdGhpcyBhcHBsaWNhdGlvbiBydW5zLiBBcHBs
aWNhdGlvbiBpbnN0YW5jZXMKIHJ1biBvdXQgb2YgdGhlIGRhdGEgY2VudGVycyBpbiB0aGUg
c3BlY2lmaWVkIGxvY2F0aW9uLCB3aGljaCBpcyBhbHNvIHdoZXJlCiBhbGwgb2YgdGhlIGFw
cGxpY2F0aW9uJ3MgZW5kIHVzZXIgY29udGVudCBpcyBzdG9yZWQuCgogRGVmYXVsdHMgdG8g
YHVzLWNlbnRyYWxgLgoKIFZpZXcgdGhlIGxpc3Qgb2YKIFtzdXBwb3J0ZWQgbG9jYXRpb25z
XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBwZW5naW5lL2RvY3MvbG9jYXRpb25zKS4K
Cg0KBQQAAgQFEgSFAQIICg0KBQQAAgQBEgSFAQkUCg0KBQQAAgQDEgSFARcYCuMBCgQEAAIF
EgSMAQIZGtQBIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGJ1Y2tldCB0aGF0IGNhbiBiZSB1c2Vk
IGZvciBzdG9yaW5nIGZpbGVzCiBhc3NvY2lhdGVkIHdpdGggdGhpcyBhcHBsaWNhdGlvbi4g
VGhpcyBidWNrZXQgaXMgYXNzb2NpYXRlZCB3aXRoIHRoZQogYXBwbGljYXRpb24gYW5kIGNh
biBiZSB1c2VkIGJ5IHRoZSBnY2xvdWQgZGVwbG95bWVudCBjb21tYW5kcy4KCiBAT3V0cHV0
T25seQoKDQoFBAACBQUSBIwBAggKDQoFBAACBQESBIwBCRQKDQoFBAACBQMSBIwBFxgKPgoE
BAACBhIEjwECORowIENvb2tpZSBleHBpcmF0aW9uIHBvbGljeSBmb3IgdGhpcyBhcHBsaWNh
dGlvbi4KCg0KBQQAAgYGEgSPAQIaCg0KBQQAAgYBEgSPARs0Cg0KBQQAAgYDEgSPATc4CjMK
BAQAAgcSBJIBAiQaJSBTZXJ2aW5nIHN0YXR1cyBvZiB0aGlzIGFwcGxpY2F0aW9uLgoKDQoF
BAACBwYSBJIBAg8KDQoFBAACBwESBJIBEB4KDQoFBAACBwMSBJIBISMKYQoEBAACCBIElwEC
HxpTIEhvc3RuYW1lIHVzZWQgdG8gcmVhY2ggdGhpcyBhcHBsaWNhdGlvbiwgYXMgcmVzb2x2
ZWQgYnkgQXBwIEVuZ2luZS4KCiBAT3V0cHV0T25seQoKDQoFBAACCAUSBJcBAggKDQoFBAAC
CAESBJcBCRkKDQoFBAACCAMSBJcBHB4KcQoEBAACCRIEnQECHRpjIEdvb2dsZSBDbG91ZCBT
dG9yYWdlIGJ1Y2tldCB0aGF0IGNhbiBiZSB1c2VkIGJ5IHRoaXMgYXBwbGljYXRpb24gdG8g
c3RvcmUKIGNvbnRlbnQuCgogQE91dHB1dE9ubHkKCg0KBQQAAgkFEgSdAQIICg0KBQQAAgkB
EgSdAQkXCg0KBQQAAgkDEgSdARocCsMBCgQEAAIKEgSiAQIeGrQBIFRoZSBzZXJ2aWNlIGFj
Y291bnQgYXNzb2NpYXRlZCB3aXRoIHRoZSBhcHBsaWNhdGlvbi4KIFRoaXMgaXMgdGhlIGFw
cC1sZXZlbCBkZWZhdWx0IGlkZW50aXR5LiBJZiBubyBpZGVudGl0eSBwcm92aWRlZCBkdXJp
bmcKIGNyZWF0ZSB2ZXJzaW9uLCBBZG1pbiBBUEkgd2lsbCBmYWxsYmFjayB0byB0aGlzIG9u
ZS4KCg0KBQQAAgoFEgSiAQIICg0KBQQAAgoBEgSiAQkYCg0KBQQAAgoDEgSiARsdCgwKBAQA
AgsSBKQBAh4KDQoFBAACCwYSBKQBAhQKDQoFBAACCwESBKQBFRgKDQoFBAACCwMSBKQBGx0K
eAoEBAACDBIEqAECGRpqIFRoZSBHb29nbGUgQ29udGFpbmVyIFJlZ2lzdHJ5IGRvbWFpbiB1
c2VkIGZvciBzdG9yaW5nIG1hbmFnZWQgYnVpbGQgZG9ja2VyCiBpbWFnZXMgZm9yIHRoaXMg
YXBwbGljYXRpb24uCgoNCgUEAAIMBRIEqAECCAoNCgUEAAIMARIEqAEJEwoNCgUEAAIMAxIE
qAEWGApuCgQEAAINEgSsAQIiGmAgVGhlIHR5cGUgb2YgdGhlIENsb3VkIEZpcmVzdG9yZSBv
ciBDbG91ZCBEYXRhc3RvcmUgZGF0YWJhc2UgYXNzb2NpYXRlZCB3aXRoCiB0aGlzIGFwcGxp
Y2F0aW9uLgoKDQoFBAACDQYSBKwBAg4KDQoFBAACDQESBKwBDxwKDQoFBAACDQMSBKwBHyEK
TAoEBAACDhIErwECKBo+IFRoZSBmZWF0dXJlIHNwZWNpZmljIHNldHRpbmdzIHRvIGJlIHVz
ZWQgaW4gdGhlIGFwcGxpY2F0aW9uLgoKDQoFBAACDgYSBK8BAhEKDQoFBAACDgESBK8BEiIK
DQoFBAACDgMSBK8BJScKVgoCBAESBrMBAMUBARpIIFJ1bGVzIHRvIG1hdGNoIGFuIEhUVFAg
cmVxdWVzdCBhbmQgZGlzcGF0Y2ggdGhhdCByZXF1ZXN0IHRvIGEgc2VydmljZS4KCgsKAwQB
ARIEswEIFwqgAQoEBAECABIEuAECFBqRASBEb21haW4gbmFtZSB0byBtYXRjaCBhZ2FpbnN0
LiBUaGUgd2lsZGNhcmQgImAqYCIgaXMgc3VwcG9ydGVkIGlmCiBzcGVjaWZpZWQgYmVmb3Jl
IGEgcGVyaW9kOiAiYCouYCIuCgogRGVmYXVsdHMgdG8gbWF0Y2hpbmcgYWxsIGRvbWFpbnM6
ICJgKmAiLgoKDQoFBAECAAUSBLgBAggKDQoFBAECAAESBLgBCQ8KDQoFBAECAAMSBLgBEhMK
ywEKBAQBAgESBL8BAhIavAEgUGF0aG5hbWUgd2l0aGluIHRoZSBob3N0LiBNdXN0IHN0YXJ0
IHdpdGggYSAiYC9gIi4gQQogc2luZ2xlICJgKmAiIGNhbiBiZSBpbmNsdWRlZCBhdCB0aGUg
ZW5kIG9mIHRoZSBwYXRoLgoKIFRoZSBzdW0gb2YgdGhlIGxlbmd0aHMgb2YgdGhlIGRvbWFp
biBhbmQgcGF0aCBtYXkgbm90CiBleGNlZWQgMTAwIGNoYXJhY3RlcnMuCgoNCgUEAQIBBRIE
vwECCAoNCgUEAQIBARIEvwEJDQoNCgUEAQIBAxIEvwEQEQqaAQoEBAECAhIExAECFRqLASBS
ZXNvdXJjZSBJRCBvZiBhIHNlcnZpY2UgaW4gdGhpcyBhcHBsaWNhdGlvbiB0aGF0IHNob3Vs
ZAogc2VydmUgdGhlIG1hdGNoZWQgcmVxdWVzdC4gVGhlIHNlcnZpY2UgbXVzdCBhbHJlYWR5
CiBleGlzdC4gRXhhbXBsZTogYGRlZmF1bHRgLgoKDQoFBAECAgUSBMQBAggKDQoFBAECAgES
BMQBCRAKDQoFBAECAgMSBMQBExRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Application::Application ===
    # Fields for Application
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: dispatch_rules Type: 11 (.google.appengine.v1.UrlDispatchRule)
    # Field: auth_domain Type: 9 ()
    # Field: location_id Type: 9 ()
    # Field: code_bucket Type: 9 ()
    # Field: default_cookie_expiration Type: 11 (.google.protobuf.Duration)
    # Field: serving_status Type: 14 (.google.appengine.v1.Application.ServingStatus)
    # Field: default_hostname Type: 9 ()
    # Field: default_bucket Type: 9 ()
    # Field: service_account Type: 9 ()
    # Field: iap Type: 11 (.google.appengine.v1.Application.IdentityAwareProxy)
    # Field: gcr_domain Type: 9 ()
    # Field: database_type Type: 14 (.google.appengine.v1.Application.DatabaseType)
    # Field: feature_settings Type: 11 (.google.appengine.v1.Application.FeatureSettings)

# Enum: Application::ServingStatus
our $Application_UNSPECIFIED = 0;
our $Application_SERVING = 1;
our $Application_USER_DISABLED = 2;
our $Application_SYSTEM_DISABLED = 3;

# Enum: Application::DatabaseType
our $Application_DATABASE_TYPE_UNSPECIFIED = 0;
our $Application_CLOUD_DATASTORE = 1;
our $Application_CLOUD_FIRESTORE = 2;
our $Application_CLOUD_DATASTORE_COMPATIBILITY = 3;

# === Message: Google::Appengine::V1::Application::UrlDispatchRule ===
    # Fields for UrlDispatchRule
    # Field: domain Type: 9 ()
    # Field: path Type: 9 ()
    # Field: service Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Application - Compiled Protocol Buffers messages for google/appengine/v1/application.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Application;

    my $msg = Google::Appengine::V1::Application::Application->new({
        name => $name,
        id => $id,
        dispatch_rules => $dispatch_rules,
        auth_domain => $auth_domain,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Application::Application->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/application.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Application::Application

An Application resource contains the top-level configuration of an App
Engine application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the Application resource in the API.
Example: `apps/myapp`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Identifier of the Application resource. This identifier is equivalent
to the project ID of the Google Cloud Platform project where you want to
deploy your application.
Example: `myapp`.

=item * C<< $msg->dispatch_rules() >> / C<< $msg->dispatch_rules($value) >>

Type: C<Message> (L<Google::Appengine::V1::Application::UrlDispatchRule>)

HTTP path dispatch rules for requests to the application that do not
explicitly target a service or version. Rules are order-dependent.
Up to 20 dispatch rules can be supported.

=item * C<< $msg->auth_domain() >> / C<< $msg->auth_domain($value) >>

Type: C<String>

Google Apps authentication domain that controls which users can access
this application.

Defaults to open access for any Google Account.

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

Location from which this application runs. Application instances
run out of the data centers in the specified location, which is also where
all of the application's end user content is stored.

Defaults to `us-central`.

View the list of
[supported locations](https://cloud.google.com/appengine/docs/locations).

=item * C<< $msg->code_bucket() >> / C<< $msg->code_bucket($value) >>

Type: C<String>

Google Cloud Storage bucket that can be used for storing files
associated with this application. This bucket is associated with the
application and can be used by the gcloud deployment commands.

@OutputOnly

=item * C<< $msg->default_cookie_expiration() >> / C<< $msg->default_cookie_expiration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Cookie expiration policy for this application.

=item * C<< $msg->serving_status() >> / C<< $msg->serving_status($value) >>

Type: C<Enum> (L<Google::Appengine::V1::Application::ServingStatus>)

Serving status of this application.

=item * C<< $msg->default_hostname() >> / C<< $msg->default_hostname($value) >>

Type: C<String>

Hostname used to reach this application, as resolved by App Engine.

@OutputOnly

=item * C<< $msg->default_bucket() >> / C<< $msg->default_bucket($value) >>

Type: C<String>

Google Cloud Storage bucket that can be used by this application to store
content.

@OutputOnly

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

The service account associated with the application.
This is the app-level default identity. If no identity provided during
create version, Admin API will fallback to this one.

=item * C<< $msg->iap() >> / C<< $msg->iap($value) >>

Type: C<Message> (L<Google::Appengine::V1::Application::Application::IdentityAwareProxy>)

=item * C<< $msg->gcr_domain() >> / C<< $msg->gcr_domain($value) >>

Type: C<String>

The Google Container Registry domain used for storing managed build docker
images for this application.

=item * C<< $msg->database_type() >> / C<< $msg->database_type($value) >>

Type: C<Enum> (L<Google::Appengine::V1::Application::DatabaseType>)

The type of the Cloud Firestore or Cloud Datastore database associated with
this application.

=item * C<< $msg->feature_settings() >> / C<< $msg->feature_settings($value) >>

Type: C<Message> (L<Google::Appengine::V1::Application::Application::FeatureSettings>)

The feature specific settings to be used in the application.

=back

=head3 Enum: Application::ServingStatus

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<SERVING> => C<1>

=item * C<USER_DISABLED> => C<2>

=item * C<SYSTEM_DISABLED> => C<3>

=back

=head3 Enum: Application::DatabaseType

=over 4

=item * C<DATABASE_TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_DATASTORE> => C<1>

=item * C<CLOUD_FIRESTORE> => C<2>

=item * C<CLOUD_DATASTORE_COMPATIBILITY> => C<3>

=back

=head2 Google::Appengine::V1::Application::UrlDispatchRule

Rules to match an HTTP request and dispatch that request to a service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

Domain name to match against. The wildcard "`*`" is supported if
specified before a period: "`*.`".

Defaults to matching all domains: "`*`".

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Pathname within the host. Must start with a "`/`". A
single "`*`" can be included at the end of the path.

The sum of the lengths of the domain and path may not
exceed 100 characters.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Resource ID of a service in this application that should
serve the matched request. The service must already
exist. Example: `default`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Application::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
