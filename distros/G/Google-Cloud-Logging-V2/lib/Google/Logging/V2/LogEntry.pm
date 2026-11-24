package Google::Logging::V2::LogEntry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::MonitoredResource };
    eval { require Google::Api::Resource };
    eval { require Google::Logging::Type::HttpRequest };
    eval { require Google::Logging::Type::LogSeverity };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvbG9nZ2luZy92Mi9sb2dfZW50cnkucHJvdG8SEWdvb2dsZS5sb2dnaW5nLnYy
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGiNnb29nbGUvYXBpL21vbml0b3Jl
ZF9yZXNvdXJjZS5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxomZ29vZ2xlL2xv
Z2dpbmcvdHlwZS9odHRwX3JlcXVlc3QucHJvdG8aJmdvb2dsZS9sb2dnaW5nL3R5cGUvbG9n
X3NldmVyaXR5LnByb3RvGhlnb29nbGUvcHJvdG9idWYvYW55LnByb3RvGhxnb29nbGUvcHJv
dG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIs8J
CghMb2dFbnRyeRIeCghsb2dfbmFtZRgMIAEoCUID4EECUgdsb2dOYW1lEj4KCHJlc291cmNl
GAggASgLMh0uZ29vZ2xlLmFwaS5Nb25pdG9yZWRSZXNvdXJjZUID4EECUghyZXNvdXJjZRI7
Cg1wcm90b19wYXlsb2FkGAIgASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueUgAUgxwcm90b1Bh
eWxvYWQSIwoMdGV4dF9wYXlsb2FkGAMgASgJSABSC3RleHRQYXlsb2FkEjwKDGpzb25fcGF5
bG9hZBgGIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RIAFILanNvblBheWxvYWQSPQoJ
dGltZXN0YW1wGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBUgl0aW1l
c3RhbXASTAoRcmVjZWl2ZV90aW1lc3RhbXAYGCABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSEHJlY2VpdmVUaW1lc3RhbXASQQoIc2V2ZXJpdHkYCiABKA4yIC5nb29n
bGUubG9nZ2luZy50eXBlLkxvZ1NldmVyaXR5QgPgQQFSCHNldmVyaXR5EiAKCWluc2VydF9p
ZBgEIAEoCUID4EEBUghpbnNlcnRJZBJICgxodHRwX3JlcXVlc3QYByABKAsyIC5nb29nbGUu
bG9nZ2luZy50eXBlLkh0dHBSZXF1ZXN0QgPgQQFSC2h0dHBSZXF1ZXN0EkQKBmxhYmVscxgL
IAMoCzInLmdvb2dsZS5sb2dnaW5nLnYyLkxvZ0VudHJ5LkxhYmVsc0VudHJ5QgPgQQFSBmxh
YmVscxJHCglvcGVyYXRpb24YDyABKAsyJC5nb29nbGUubG9nZ2luZy52Mi5Mb2dFbnRyeU9w
ZXJhdGlvbkID4EEBUglvcGVyYXRpb24SGQoFdHJhY2UYFiABKAlCA+BBAVIFdHJhY2USHAoH
c3Bhbl9pZBgbIAEoCUID4EEBUgZzcGFuSWQSKAoNdHJhY2Vfc2FtcGxlZBgeIAEoCEID4EEB
Ugx0cmFjZVNhbXBsZWQSVwoPc291cmNlX2xvY2F0aW9uGBcgASgLMikuZ29vZ2xlLmxvZ2dp
bmcudjIuTG9nRW50cnlTb3VyY2VMb2NhdGlvbkID4EEBUg5zb3VyY2VMb2NhdGlvbhI2CgVz
cGxpdBgjIAEoCzIbLmdvb2dsZS5sb2dnaW5nLnYyLkxvZ1NwbGl0QgPgQQFSBXNwbGl0GjkK
C0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToC
OAE6vQHqQbkBChpsb2dnaW5nLmdvb2dsZWFwaXMuY29tL0xvZxIdcHJvamVjdHMve3Byb2pl
Y3R9L2xvZ3Mve2xvZ30SJ29yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9ncy97bG9n
fRIbZm9sZGVycy97Zm9sZGVyfS9sb2dzL3tsb2d9EixiaWxsaW5nQWNjb3VudHMve2JpbGxp
bmdfYWNjb3VudH0vbG9ncy97bG9nfRoIbG9nX25hbWVCCQoHcGF5bG9hZCJ9ChFMb2dFbnRy
eU9wZXJhdGlvbhITCgJpZBgBIAEoCUID4EEBUgJpZBIfCghwcm9kdWNlchgCIAEoCUID4EEB
Ughwcm9kdWNlchIZCgVmaXJzdBgDIAEoCEID4EEBUgVmaXJzdBIXCgRsYXN0GAQgASgIQgPg
QQFSBGxhc3QiawoWTG9nRW50cnlTb3VyY2VMb2NhdGlvbhIXCgRmaWxlGAEgASgJQgPgQQFS
BGZpbGUSFwoEbGluZRgCIAEoA0ID4EEBUgRsaW5lEh8KCGZ1bmN0aW9uGAMgASgJQgPgQQFS
CGZ1bmN0aW9uIlUKCExvZ1NwbGl0EhAKA3VpZBgBIAEoCVIDdWlkEhQKBWluZGV4GAIgASgF
UgVpbmRleBIhCgx0b3RhbF9zcGxpdHMYAyABKAVSC3RvdGFsU3BsaXRzQrMBChVjb20uZ29v
Z2xlLmxvZ2dpbmcudjJCDUxvZ0VudHJ5UHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9s
b2dnaW5nL2FwaXYyL2xvZ2dpbmdwYjtsb2dnaW5ncGL4AQGqAhdHb29nbGUuQ2xvdWQuTG9n
Z2luZy5WMsoCF0dvb2dsZVxDbG91ZFxMb2dnaW5nXFYy6gIaR29vZ2xlOjpDbG91ZDo6TG9n
Z2luZzo6VjJK9l0KBxIFDgCXAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQABoKCQoCAwASAxIAKQoJCgIDARIDEwAtCgkKAgMCEgMUACMKCQoCAwMSAxUA
MAoJCgIDBBIDFgAwCgkKAgMFEgMXACMKCQoCAwYSAxgAJgoJCgIDBxIDGQApCggKAQgSAxsA
HwoJCgIIHxIDGwAfCggKAQgSAxwANAoJCgIIJRIDHAA0CggKAQgSAx0ATAoJCgIICxIDHQBM
CggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8ALgoJCgIICBIDHwAuCggKAQgSAyAALgoJ
CgIIARIDIAAuCggKAQgSAyEANAoJCgIIKRIDIQA0CggKAQgSAyIAMwoJCgIILRIDIgAzCiwK
AgQAEgUlAN4BARofIEFuIGluZGl2aWR1YWwgZW50cnkgaW4gYSBsb2cuCgoKCgMEAAESAyUI
EAoLCgMEAAcSBCYCLQQKDQoFBAAHnQgSBCYCLQQK8ggKBAQAAgASA0YCQBrkCCBSZXF1aXJl
ZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGxvZyB0byB3aGljaCB0aGlzIGxvZyBlbnRy
eSBiZWxvbmdzOgoKICAgICAicHJvamVjdHMvW1BST0pFQ1RfSURdL2xvZ3MvW0xPR19JRF0i
CiAgICAgIm9yZ2FuaXphdGlvbnMvW09SR0FOSVpBVElPTl9JRF0vbG9ncy9bTE9HX0lEXSIK
ICAgICAiYmlsbGluZ0FjY291bnRzL1tCSUxMSU5HX0FDQ09VTlRfSURdL2xvZ3MvW0xPR19J
RF0iCiAgICAgImZvbGRlcnMvW0ZPTERFUl9JRF0vbG9ncy9bTE9HX0lEXSIKCiBBIHByb2pl
Y3QgbnVtYmVyIG1heSBiZSB1c2VkIGluIHBsYWNlIG9mIFBST0pFQ1RfSUQuIFRoZSBwcm9q
ZWN0IG51bWJlciBpcwogdHJhbnNsYXRlZCB0byBpdHMgY29ycmVzcG9uZGluZyBQUk9KRUNU
X0lEIGludGVybmFsbHkgYW5kIHRoZSBgbG9nX25hbWVgCiBmaWVsZCB3aWxsIGNvbnRhaW4g
UFJPSkVDVF9JRCBpbiBxdWVyaWVzIGFuZCBleHBvcnRzLgoKIGBbTE9HX0lEXWAgbXVzdCBi
ZSBVUkwtZW5jb2RlZCB3aXRoaW4gYGxvZ19uYW1lYC4gRXhhbXBsZToKIGAib3JnYW5pemF0
aW9ucy8xMjM0NTY3ODkwL2xvZ3MvY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5j
b20lMkZhY3Rpdml0eSJgLgoKIGBbTE9HX0lEXWAgbXVzdCBiZSBsZXNzIHRoYW4gNTEyIGNo
YXJhY3RlcnMgbG9uZyBhbmQgY2FuIG9ubHkgaW5jbHVkZSB0aGUKIGZvbGxvd2luZyBjaGFy
YWN0ZXJzOiB1cHBlciBhbmQgbG93ZXIgY2FzZSBhbHBoYW51bWVyaWMgY2hhcmFjdGVycywK
IGZvcndhcmQtc2xhc2gsIHVuZGVyc2NvcmUsIGh5cGhlbiwgYW5kIHBlcmlvZC4KCiBGb3Ig
YmFja3dhcmQgY29tcGF0aWJpbGl0eSwgaWYgYGxvZ19uYW1lYCBiZWdpbnMgd2l0aCBhIGZv
cndhcmQtc2xhc2gsIHN1Y2gKIGFzIGAvcHJvamVjdHMvLi4uYCwgdGhlbiB0aGUgbG9nIGVu
dHJ5IGlzIGluZ2VzdGVkIGFzIHVzdWFsLCBidXQgdGhlCiBmb3J3YXJkLXNsYXNoIGlzIHJl
bW92ZWQuIExpc3RpbmcgdGhlIGxvZyBlbnRyeSB3aWxsIG5vdCBzaG93IHRoZSBsZWFkaW5n
CiBzbGFzaCBhbmQgZmlsdGVyaW5nIGZvciBhIGxvZyBuYW1lIHdpdGggYSBsZWFkaW5nIHNs
YXNoIHdpbGwgbmV2ZXIgcmV0dXJuCiBhbnkgcmVzdWx0cy4KCgwKBQQAAgAFEgNGAggKDAoF
BAACAAESA0YJEQoMCgUEAAIAAxIDRhQWCgwKBQQAAgAIEgNGFz8KDwoIBAACAAicCAASA0YY
PgrzAQoEBAACARIETQJOLxrkASBSZXF1aXJlZC4gVGhlIG1vbml0b3JlZCByZXNvdXJjZSB0
aGF0IHByb2R1Y2VkIHRoaXMgbG9nIGVudHJ5LgoKIEV4YW1wbGU6IGEgbG9nIGVudHJ5IHRo
YXQgcmVwb3J0cyBhIGRhdGFiYXNlIGVycm9yIHdvdWxkIGJlIGFzc29jaWF0ZWQgd2l0aAog
dGhlIG1vbml0b3JlZCByZXNvdXJjZSBkZXNpZ25hdGluZyB0aGUgcGFydGljdWxhciBkYXRh
YmFzZSB0aGF0IHJlcG9ydGVkCiB0aGUgZXJyb3IuCgoMCgUEAAIBBhIDTQIeCgwKBQQAAgEB
EgNNHycKDAoFBAACAQMSA00qKwoMCgUEAAIBCBIDTgYuCg8KCAQAAgEInAgAEgNOBy0KSgoE
BAAIABIEUQJiAxo8IFRoZSBsb2cgZW50cnkgcGF5bG9hZCwgd2hpY2ggY2FuIGJlIG9uZSBv
ZiBtdWx0aXBsZSB0eXBlcy4KCgwKBQQACAABEgNRCA8K7AIKBAQAAgISA1oEKhreAiBUaGUg
bG9nIGVudHJ5IHBheWxvYWQsIHJlcHJlc2VudGVkIGFzIGEgcHJvdG9jb2wgYnVmZmVyLiBT
b21lIEdvb2dsZQogQ2xvdWQgUGxhdGZvcm0gc2VydmljZXMgdXNlIHRoaXMgZmllbGQgZm9y
IHRoZWlyIGxvZyBlbnRyeSBwYXlsb2Fkcy4KCiBUaGUgZm9sbG93aW5nIHByb3RvY29sIGJ1
ZmZlciB0eXBlcyBhcmUgc3VwcG9ydGVkOyB1c2VyLWRlZmluZWQgdHlwZXMKIGFyZSBub3Qg
c3VwcG9ydGVkOgoKICAgInR5cGUuZ29vZ2xlYXBpcy5jb20vZ29vZ2xlLmNsb3VkLmF1ZGl0
LkF1ZGl0TG9nIgogICAidHlwZS5nb29nbGVhcGlzLmNvbS9nb29nbGUuYXBwZW5naW5lLmxv
Z2dpbmcudjEuUmVxdWVzdExvZyIKCgwKBQQAAgIGEgNaBBcKDAoFBAACAgESA1oYJQoMCgUE
AAICAxIDWigpCk4KBAQAAgMSA10EHBpBIFRoZSBsb2cgZW50cnkgcGF5bG9hZCwgcmVwcmVz
ZW50ZWQgYXMgYSBVbmljb2RlIHN0cmluZyAoVVRGLTgpLgoKDAoFBAACAwUSA10ECgoMCgUE
AAIDARIDXQsXCgwKBQQAAgMDEgNdGhsKZQoEBAACBBIDYQQsGlggVGhlIGxvZyBlbnRyeSBw
YXlsb2FkLCByZXByZXNlbnRlZCBhcyBhIHN0cnVjdHVyZSB0aGF0IGlzCiBleHByZXNzZWQg
YXMgYSBKU09OIG9iamVjdC4KCgwKBQQAAgQGEgNhBBoKDAoFBAACBAESA2EbJwoMCgUEAAIE
AxIDYSorCqwFCgQEAAIFEgRwAnEvGp0FIE9wdGlvbmFsLiBUaGUgdGltZSB0aGUgZXZlbnQg
ZGVzY3JpYmVkIGJ5IHRoZSBsb2cgZW50cnkgb2NjdXJyZWQuIFRoaXMgdGltZQogaXMgdXNl
ZCB0byBjb21wdXRlIHRoZSBsb2cgZW50cnkncyBhZ2UgYW5kIHRvIGVuZm9yY2UgdGhlIGxv
Z3MgcmV0ZW50aW9uCiBwZXJpb2QuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCBpbiBhIG5l
dyBsb2cgZW50cnksIHRoZW4gTG9nZ2luZyBhc3NpZ25zCiBpdCB0aGUgY3VycmVudCB0aW1l
LiBUaW1lc3RhbXBzIGhhdmUgbmFub3NlY29uZCBhY2N1cmFjeSwgYnV0IHRyYWlsaW5nCiB6
ZXJvcyBpbiB0aGUgZnJhY3Rpb25hbCBzZWNvbmRzIG1pZ2h0IGJlIG9taXR0ZWQgd2hlbiB0
aGUgdGltZXN0YW1wIGlzCiBkaXNwbGF5ZWQuCgogSW5jb21pbmcgbG9nIGVudHJpZXMgbXVz
dCBoYXZlIHRpbWVzdGFtcHMgdGhhdCBkb24ndCBleGNlZWQgdGhlCiBbbG9ncyByZXRlbnRp
b24KIHBlcmlvZF0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2xvZ2dpbmcvcXVvdGFzI2xv
Z3NfcmV0ZW50aW9uX3BlcmlvZHMpIGluCiB0aGUgcGFzdCwgYW5kIHRoYXQgZG9uJ3QgZXhj
ZWVkIDI0IGhvdXJzIGluIHRoZSBmdXR1cmUuIExvZyBlbnRyaWVzIG91dHNpZGUKIHRob3Nl
IHRpbWUgYm91bmRhcmllcyBhcmVuJ3QgaW5nZXN0ZWQgYnkgTG9nZ2luZy4KCgwKBQQAAgUG
EgNwAhsKDAoFBAACBQESA3AcJQoMCgUEAAIFAxIDcCgpCgwKBQQAAgUIEgNxBi4KDwoIBAAC
BQicCAASA3EHLQpMCgQEAAIGEgR0AnUyGj4gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBs
b2cgZW50cnkgd2FzIHJlY2VpdmVkIGJ5IExvZ2dpbmcuCgoMCgUEAAIGBhIDdAIbCgwKBQQA
AgYBEgN0HC0KDAoFBAACBgMSA3QwMgoMCgUEAAIGCBIDdQYxCg8KCAQAAgYInAgAEgN1BzAK
ZQoEBAACBxIEeQJ6LxpXIE9wdGlvbmFsLiBUaGUgc2V2ZXJpdHkgb2YgdGhlIGxvZyBlbnRy
eS4gVGhlIGRlZmF1bHQgdmFsdWUgaXMKIGBMb2dTZXZlcml0eS5ERUZBVUxUYC4KCgwKBQQA
AgcGEgN5AiEKDAoFBAACBwESA3kiKgoMCgUEAAIHAxIDeS0vCgwKBQQAAgcIEgN6Bi4KDwoI
BAACBwicCAASA3oHLQrOBAoEBAACCBIEhwECQBq/BCBPcHRpb25hbC4gQSB1bmlxdWUgaWRl
bnRpZmllciBmb3IgdGhlIGxvZyBlbnRyeS4gSWYgeW91IHByb3ZpZGUgYSB2YWx1ZSwKIHRo
ZW4gTG9nZ2luZyBjb25zaWRlcnMgb3RoZXIgbG9nIGVudHJpZXMgaW4gdGhlIHNhbWUgcHJv
amVjdCwgd2l0aCB0aGUgc2FtZQogYHRpbWVzdGFtcGAsIGFuZCB3aXRoIHRoZSBzYW1lIGBp
bnNlcnRfaWRgIHRvIGJlIGR1cGxpY2F0ZXMgd2hpY2ggYXJlCiByZW1vdmVkIGluIGEgc2lu
Z2xlIHF1ZXJ5IHJlc3VsdC4gSG93ZXZlciwgdGhlcmUgYXJlIG5vIGd1YXJhbnRlZXMgb2YK
IGRlLWR1cGxpY2F0aW9uIGluIHRoZSBleHBvcnQgb2YgbG9ncy4KCiBJZiB0aGUgYGluc2Vy
dF9pZGAgaXMgb21pdHRlZCB3aGVuIHdyaXRpbmcgYSBsb2cgZW50cnksIHRoZSBMb2dnaW5n
IEFQSQogYXNzaWducyBpdHMgb3duIHVuaXF1ZSBpZGVudGlmaWVyIGluIHRoaXMgZmllbGQu
CgogSW4gcXVlcmllcywgdGhlIGBpbnNlcnRfaWRgIGlzIGFsc28gdXNlZCB0byBvcmRlciBs
b2cgZW50cmllcyB0aGF0IGhhdmUKIHRoZSBzYW1lIGBsb2dfbmFtZWAgYW5kIGB0aW1lc3Rh
bXBgIHZhbHVlcy4KCg0KBQQAAggFEgSHAQIICg0KBQQAAggBEgSHAQkSCg0KBQQAAggDEgSH
ARUWCg0KBQQAAggIEgSHARc/ChAKCAQAAggInAgAEgSHARg+Cm4KBAQAAgkSBosBAowBLxpe
IE9wdGlvbmFsLiBJbmZvcm1hdGlvbiBhYm91dCB0aGUgSFRUUCByZXF1ZXN0IGFzc29jaWF0
ZWQgd2l0aCB0aGlzIGxvZwogZW50cnksIGlmIGFwcGxpY2FibGUuCgoNCgUEAAIJBhIEiwEC
IQoNCgUEAAIJARIEiwEiLgoNCgUEAAIJAxIEiwExMgoNCgUEAAIJCBIEjAEGLgoQCggEAAIJ
CJwIABIEjAEHLQqkBQoEBAACChIEnAECSxqVBSBPcHRpb25hbC4gQSBtYXAgb2Yga2V5LCB2
YWx1ZSBwYWlycyB0aGF0IHByb3ZpZGVzIGFkZGl0aW9uYWwgaW5mb3JtYXRpb24KIGFib3V0
IHRoZSBsb2cgZW50cnkuIFRoZSBsYWJlbHMgY2FuIGJlIHVzZXItZGVmaW5lZCBvciBzeXN0
ZW0tZGVmaW5lZC4KCiBVc2VyLWRlZmluZWQgbGFiZWxzIGFyZSBhcmJpdHJhcnkga2V5LCB2
YWx1ZSBwYWlycyB0aGF0IHlvdSBjYW4gdXNlIHRvCiBjbGFzc2lmeSBsb2dzLgoKIFN5c3Rl
bS1kZWZpbmVkIGxhYmVscyBhcmUgZGVmaW5lZCBieSBHQ1Agc2VydmljZXMgZm9yIHBsYXRm
b3JtIGxvZ3MuCiBUaGV5IGhhdmUgdHdvIGNvbXBvbmVudHMgLSBhIHNlcnZpY2UgbmFtZXNw
YWNlIGNvbXBvbmVudCBhbmQgdGhlCiBhdHRyaWJ1dGUgbmFtZS4gRm9yIGV4YW1wbGU6IGBj
b21wdXRlLmdvb2dsZWFwaXMuY29tL3Jlc291cmNlX25hbWVgLgoKIENsb3VkIExvZ2dpbmcg
dHJ1bmNhdGVzIGxhYmVsIGtleXMgdGhhdCBleGNlZWQgNTEyIEIgYW5kIGxhYmVsCiB2YWx1
ZXMgdGhhdCBleGNlZWQgNjQgS0IgdXBvbiB0aGVpciBhc3NvY2lhdGVkIGxvZyBlbnRyeSBi
ZWluZwogd3JpdHRlbi4gVGhlIHRydW5jYXRpb24gaXMgaW5kaWNhdGVkIGJ5IGFuIGVsbGlw
c2lzIGF0IHRoZQogZW5kIG9mIHRoZSBjaGFyYWN0ZXIgc3RyaW5nLgoKDQoFBAACCgYSBJwB
AhUKDQoFBAACCgESBJwBFhwKDQoFBAACCgMSBJwBHyEKDQoFBAACCggSBJwBIkoKEAoIBAAC
CgicCAASBJwBI0kKZwoEBAACCxIEoAECTBpZIE9wdGlvbmFsLiBJbmZvcm1hdGlvbiBhYm91
dCBhbiBvcGVyYXRpb24gYXNzb2NpYXRlZCB3aXRoIHRoZSBsb2cgZW50cnksIGlmCiBhcHBs
aWNhYmxlLgoKDQoFBAACCwYSBKABAhMKDQoFBAACCwESBKABFB0KDQoFBAACCwMSBKABICIK
DQoFBAACCwgSBKABI0sKEAoIBAACCwicCAASBKABJEoKsQQKBAQAAgwSBKsBAj0aogQgT3B0
aW9uYWwuIFRoZSBSRVNUIHJlc291cmNlIG5hbWUgb2YgdGhlIHRyYWNlIGJlaW5nIHdyaXR0
ZW4gdG8KIFtDbG91ZCBUcmFjZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3RyYWNlKSBp
bgogYXNzb2NpYXRpb24gd2l0aCB0aGlzIGxvZyBlbnRyeS4gRm9yIGV4YW1wbGUsIGlmIHlv
dXIgdHJhY2UgZGF0YSBpcyBzdG9yZWQKIGluIHRoZSBDbG91ZCBwcm9qZWN0ICJteS10cmFj
ZS1wcm9qZWN0IiBhbmQgaWYgdGhlIHNlcnZpY2UgdGhhdCBpcyBjcmVhdGluZwogdGhlIGxv
ZyBlbnRyeSByZWNlaXZlcyBhIHRyYWNlIGhlYWRlciB0aGF0IGluY2x1ZGVzIHRoZSB0cmFj
ZSBJRCAiMTIzNDUiLAogdGhlbiB0aGUgc2VydmljZSBzaG91bGQgdXNlICJwcm9qZWN0cy9t
eS10cmFjaW5nLXByb2plY3QvdHJhY2VzLzEyMzQ1Ii4KCiBUaGUgYHRyYWNlYCBmaWVsZCBw
cm92aWRlcyB0aGUgbGluayBiZXR3ZWVuIGxvZ3MgYW5kIHRyYWNlcy4gQnkgdXNpbmcKIHRo
aXMgZmllbGQsIHlvdSBjYW4gbmF2aWdhdGUgZnJvbSBhIGxvZyBlbnRyeSB0byBhIHRyYWNl
LgoKDQoFBAACDAUSBKsBAggKDQoFBAACDAESBKsBCQ4KDQoFBAACDAMSBKsBERMKDQoFBAAC
DAgSBKsBFDwKEAoIBAACDAicCAASBKsBFTsKkgsKBAQAAg0SBMsBAj8agwsgT3B0aW9uYWwu
IFRoZSBJRCBvZiB0aGUgW0Nsb3VkIFRyYWNlXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
dHJhY2UpIHNwYW4KIGFzc29jaWF0ZWQgd2l0aCB0aGUgY3VycmVudCBvcGVyYXRpb24gaW4g
d2hpY2ggdGhlIGxvZyBpcyBiZWluZyB3cml0dGVuLgogRm9yIGV4YW1wbGUsIGlmIGEgc3Bh
biBoYXMgdGhlIFJFU1QgcmVzb3VyY2UgbmFtZSBvZgogInByb2plY3RzL3NvbWUtcHJvamVj
dC90cmFjZXMvc29tZS10cmFjZS9zcGFucy9zb21lLXNwYW4taWQiLCB0aGVuIHRoZQogYHNw
YW5faWRgIGZpZWxkIGlzICJzb21lLXNwYW4taWQiLgoKIEEKIFtTcGFuXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vdHJhY2UvZG9jcy9yZWZlcmVuY2UvdjIvcmVzdC92Mi9wcm9qZWN0
cy50cmFjZXMvYmF0Y2hXcml0ZSNTcGFuKQogcmVwcmVzZW50cyBhIHNpbmdsZSBvcGVyYXRp
b24gd2l0aGluIGEgdHJhY2UuIFdoZXJlYXMgYSB0cmFjZSBtYXkgaW52b2x2ZQogbXVsdGlw
bGUgZGlmZmVyZW50IG1pY3Jvc2VydmljZXMgcnVubmluZyBvbiBtdWx0aXBsZSBkaWZmZXJl
bnQgbWFjaGluZXMsCiBhIHNwYW4gZ2VuZXJhbGx5IGNvcnJlc3BvbmRzIHRvIGEgc2luZ2xl
IGxvZ2ljYWwgb3BlcmF0aW9uIGJlaW5nIHBlcmZvcm1lZAogaW4gYSBzaW5nbGUgaW5zdGFu
Y2Ugb2YgYSBtaWNyb3NlcnZpY2Ugb24gb25lIHNwZWNpZmljIG1hY2hpbmUuIFNwYW5zCiBh
cmUgdGhlIG5vZGVzIHdpdGhpbiB0aGUgdHJlZSB0aGF0IGlzIGEgdHJhY2UuCgogQXBwbGlj
YXRpb25zIHRoYXQgYXJlIFtpbnN0cnVtZW50ZWQgZm9yCiB0cmFjaW5nXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vdHJhY2UvZG9jcy9zZXR1cCkgd2lsbCBnZW5lcmFsbHkgYXNzaWdu
IGEKIG5ldywgdW5pcXVlIHNwYW4gSUQgb24gZWFjaCBpbmNvbWluZyByZXF1ZXN0LiBJdCBp
cyBhbHNvIGNvbW1vbiB0byBjcmVhdGUKIGFuZCByZWNvcmQgYWRkaXRpb25hbCBzcGFucyBj
b3JyZXNwb25kaW5nIHRvIGludGVybmFsIHByb2Nlc3NpbmcgZWxlbWVudHMKIGFzIHdlbGwg
YXMgaXNzdWluZyByZXF1ZXN0cyB0byBkZXBlbmRlbmNpZXMuCgogVGhlIHNwYW4gSUQgaXMg
ZXhwZWN0ZWQgdG8gYmUgYSAxNi1jaGFyYWN0ZXIsIGhleGFkZWNpbWFsIGVuY29kaW5nIG9m
IGFuCiA4LWJ5dGUgYXJyYXkgYW5kIHNob3VsZCBub3QgYmUgemVyby4gSXQgc2hvdWxkIGJl
IHVuaXF1ZSB3aXRoaW4gdGhlIHRyYWNlCiBhbmQgc2hvdWxkLCBpZGVhbGx5LCBiZSBnZW5l
cmF0ZWQgaW4gYSBtYW5uZXIgdGhhdCBpcyB1bmlmb3JtbHkgcmFuZG9tLgoKIEV4YW1wbGUg
dmFsdWVzOgoKICAgLSBgMDAwMDAwMDAwMDAwMDA0YWAKICAgLSBgN2EyMTkwMzU2YzNmYzk0
YmAKICAgLSBgMDAwMGYwMDMwMDA5MDAyMWAKICAgLSBgZDM5MjIzZTEwMTk2MDA3NmAKCg0K
BQQAAg0FEgTLAQIICg0KBQQAAg0BEgTLAQkQCg0KBQQAAg0DEgTLARMVCg0KBQQAAg0IEgTL
ARY+ChAKCAQAAg0InAgAEgTLARc9CrwDCgQEAAIOEgTUAQJDGq0DIE9wdGlvbmFsLiBUaGUg
c2FtcGxpbmcgZGVjaXNpb24gb2YgdGhlIHRyYWNlIGFzc29jaWF0ZWQgd2l0aCB0aGUgbG9n
IGVudHJ5LgoKIFRydWUgbWVhbnMgdGhhdCB0aGUgdHJhY2UgcmVzb3VyY2UgbmFtZSBpbiB0
aGUgYHRyYWNlYCBmaWVsZCB3YXMgc2FtcGxlZAogZm9yIHN0b3JhZ2UgaW4gYSB0cmFjZSBi
YWNrZW5kLiBGYWxzZSBtZWFucyB0aGF0IHRoZSB0cmFjZSB3YXMgbm90IHNhbXBsZWQKIGZv
ciBzdG9yYWdlIHdoZW4gdGhpcyBsb2cgZW50cnkgd2FzIHdyaXR0ZW4sIG9yIHRoZSBzYW1w
bGluZyBkZWNpc2lvbiB3YXMKIHVua25vd24gYXQgdGhlIHRpbWUuIEEgbm9uLXNhbXBsZWQg
YHRyYWNlYCB2YWx1ZSBpcyBzdGlsbCB1c2VmdWwgYXMgYQogcmVxdWVzdCBjb3JyZWxhdGlv
biBpZGVudGlmaWVyLiBUaGUgZGVmYXVsdCBpcyBGYWxzZS4KCg0KBQQAAg4FEgTUAQIGCg0K
BQQAAg4BEgTUAQcUCg0KBQQAAg4DEgTUARcZCg0KBQQAAg4IEgTUARpCChAKCAQAAg4InAgA
EgTUARtBCmQKBAQAAg8SBtgBAtkBLxpUIE9wdGlvbmFsLiBTb3VyY2UgY29kZSBsb2NhdGlv
biBpbmZvcm1hdGlvbiBhc3NvY2lhdGVkIHdpdGggdGhlIGxvZyBlbnRyeSwKIGlmIGFueS4K
Cg0KBQQAAg8GEgTYAQIYCg0KBQQAAg8BEgTYARkoCg0KBQQAAg8DEgTYASstCg0KBQQAAg8I
EgTZAQYuChAKCAQAAg8InAgAEgTZAQctCosBCgQEAAIQEgTdAQI/Gn0gT3B0aW9uYWwuIElu
Zm9ybWF0aW9uIGluZGljYXRpbmcgdGhpcyBMb2dFbnRyeSBpcyBwYXJ0IG9mIGEgc2VxdWVu
Y2Ugb2YKIG11bHRpcGxlIGxvZyBlbnRyaWVzIHNwbGl0IGZyb20gYSBzaW5nbGUgTG9nRW50
cnkuCgoNCgUEAAIQBhIE3QECCgoNCgUEAAIQARIE3QELEAoNCgUEAAIQAxIE3QETFQoNCgUE
AAIQCBIE3QEWPgoQCggEAAIQCJwIABIE3QEXPQp4CgIEARIG4gEA8QEBGmogQWRkaXRpb25h
bCBpbmZvcm1hdGlvbiBhYm91dCBhIHBvdGVudGlhbGx5IGxvbmctcnVubmluZyBvcGVyYXRp
b24gd2l0aCB3aGljaAogYSBsb2cgZW50cnkgaXMgYXNzb2NpYXRlZC4KCgsKAwQBARIE4gEI
GQqRAQoEBAECABIE5QECORqCASBPcHRpb25hbC4gQW4gYXJiaXRyYXJ5IG9wZXJhdGlvbiBp
ZGVudGlmaWVyLiBMb2cgZW50cmllcyB3aXRoIHRoZSBzYW1lCiBpZGVudGlmaWVyIGFyZSBh
c3N1bWVkIHRvIGJlIHBhcnQgb2YgdGhlIHNhbWUgb3BlcmF0aW9uLgoKDQoFBAECAAUSBOUB
AggKDQoFBAECAAESBOUBCQsKDQoFBAECAAMSBOUBDg8KDQoFBAECAAgSBOUBEDgKEAoIBAEC
AAicCAASBOUBETcK4AEKBAQBAgESBOoBAj8a0QEgT3B0aW9uYWwuIEFuIGFyYml0cmFyeSBw
cm9kdWNlciBpZGVudGlmaWVyLiBUaGUgY29tYmluYXRpb24gb2YgYGlkYCBhbmQKIGBwcm9k
dWNlcmAgbXVzdCBiZSBnbG9iYWxseSB1bmlxdWUuIEV4YW1wbGVzIGZvciBgcHJvZHVjZXJg
OgogYCJNeURpdmlzaW9uLk15QmlnQ29tcGFueS5jb20iYCwgYCJnaXRodWIuY29tL015UHJv
amVjdC9NeUFwcGxpY2F0aW9uImAuCgoNCgUEAQIBBRIE6gECCAoNCgUEAQIBARIE6gEJEQoN
CgUEAQIBAxIE6gEUFQoNCgUEAQIBCBIE6gEWPgoQCggEAQIBCJwIABIE6gEXPQpbCgQEAQIC
EgTtAQI6Gk0gT3B0aW9uYWwuIFNldCB0aGlzIHRvIFRydWUgaWYgdGhpcyBpcyB0aGUgZmly
c3QgbG9nIGVudHJ5IGluIHRoZSBvcGVyYXRpb24uCgoNCgUEAQICBRIE7QECBgoNCgUEAQIC
ARIE7QEHDAoNCgUEAQICAxIE7QEPEAoNCgUEAQICCBIE7QEROQoQCggEAQICCJwIABIE7QES
OApaCgQEAQIDEgTwAQI5GkwgT3B0aW9uYWwuIFNldCB0aGlzIHRvIFRydWUgaWYgdGhpcyBp
cyB0aGUgbGFzdCBsb2cgZW50cnkgaW4gdGhlIG9wZXJhdGlvbi4KCg0KBQQBAgMFEgTwAQIG
Cg0KBQQBAgMBEgTwAQcLCg0KBQQBAgMDEgTwAQ4PCg0KBQQBAgMIEgTwARA4ChAKCAQBAgMI
nAgAEgTwARE3CmMKAgQCEgb1AQCFAgEaVSBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFib3V0
IHRoZSBzb3VyY2UgY29kZSBsb2NhdGlvbiB0aGF0IHByb2R1Y2VkIHRoZSBsb2cKIGVudHJ5
LgoKCwoDBAIBEgT1AQgeCokBCgQEAgIAEgT4AQI7GnsgT3B0aW9uYWwuIFNvdXJjZSBmaWxl
IG5hbWUuIERlcGVuZGluZyBvbiB0aGUgcnVudGltZSBlbnZpcm9ubWVudCwgdGhpcwogbWln
aHQgYmUgYSBzaW1wbGUgbmFtZSBvciBhIGZ1bGx5LXF1YWxpZmllZCBuYW1lLgoKDQoFBAIC
AAUSBPgBAggKDQoFBAICAAESBPgBCQ0KDQoFBAICAAMSBPgBEBEKDQoFBAICAAgSBPgBEjoK
EAoIBAICAAicCAASBPgBEzkKZgoEBAICARIE/AECOhpYIE9wdGlvbmFsLiBMaW5lIHdpdGhp
biB0aGUgc291cmNlIGZpbGUuIDEtYmFzZWQ7IDAgaW5kaWNhdGVzIG5vIGxpbmUgbnVtYmVy
CiBhdmFpbGFibGUuCgoNCgUEAgIBBRIE/AECBwoNCgUEAgIBARIE/AEIDAoNCgUEAgIBAxIE
/AEPEAoNCgUEAgIBCBIE/AEROQoQCggEAgIBCJwIABIE/AESOAqIAwoEBAICAhIEhAICPxr5
AiBPcHRpb25hbC4gSHVtYW4tcmVhZGFibGUgbmFtZSBvZiB0aGUgZnVuY3Rpb24gb3IgbWV0
aG9kIGJlaW5nIGludm9rZWQsIHdpdGgKIG9wdGlvbmFsIGNvbnRleHQgc3VjaCBhcyB0aGUg
Y2xhc3Mgb3IgcGFja2FnZSBuYW1lLiBUaGlzIGluZm9ybWF0aW9uIG1heSBiZQogdXNlZCBp
biBjb250ZXh0cyBzdWNoIGFzIHRoZSBsb2dzIHZpZXdlciwgd2hlcmUgYSBmaWxlIGFuZCBs
aW5lIG51bWJlciBhcmUKIGxlc3MgbWVhbmluZ2Z1bC4gVGhlIGZvcm1hdCBjYW4gdmFyeSBi
eSBsYW5ndWFnZS4gRm9yIGV4YW1wbGU6CiBgcXVhbC5pZi5pZWQuQ2xhc3MubWV0aG9kYCAo
SmF2YSksIGBkaXIvcGFja2FnZS5mdW5jYCAoR28pLCBgZnVuY3Rpb25gCiAoUHl0aG9uKS4K
Cg0KBQQCAgIFEgSEAgIICg0KBQQCAgIBEgSEAgkRCg0KBQQCAgIDEgSEAhQVCg0KBQQCAgII
EgSEAhY+ChAKCAQCAgIInAgAEgSEAhc9CsgBCgIEAxIGigIAlwIBGrkBIEFkZGl0aW9uYWwg
aW5mb3JtYXRpb24gdXNlZCB0byBjb3JyZWxhdGUgbXVsdGlwbGUgbG9nIGVudHJpZXMuIFVz
ZWQgd2hlbiBhCiBzaW5nbGUgTG9nRW50cnkgd291bGQgZXhjZWVkIHRoZSBHb29nbGUgQ2xv
dWQgTG9nZ2luZyBzaXplIGxpbWl0IGFuZCBpcwogc3BsaXQgYWNyb3NzIG11bHRpcGxlIGxv
ZyBlbnRyaWVzLgoKCwoDBAMBEgSKAggQCtYBCgQEAwIAEgSOAgIRGscBIEEgZ2xvYmFsbHkg
dW5pcXVlIGlkZW50aWZpZXIgZm9yIGFsbCBsb2cgZW50cmllcyBpbiBhIHNlcXVlbmNlIG9m
IHNwbGl0IGxvZwogZW50cmllcy4gQWxsIGxvZyBlbnRyaWVzIHdpdGggdGhlIHNhbWUgfExv
Z1NwbGl0LnVpZHwgYXJlIGFzc3VtZWQgdG8gYmUKIHBhcnQgb2YgdGhlIHNhbWUgc2VxdWVu
Y2Ugb2Ygc3BsaXQgbG9nIGVudHJpZXMuCgoNCgUEAwIABRIEjgICCAoNCgUEAwIAARIEjgIJ
DAoNCgUEAwIAAxIEjgIPEAqoAQoEBAMCARIEkwICEhqZASBUaGUgaW5kZXggb2YgdGhpcyBM
b2dFbnRyeSBpbiB0aGUgc2VxdWVuY2Ugb2Ygc3BsaXQgbG9nIGVudHJpZXMuIExvZwogZW50
cmllcyBhcmUgZ2l2ZW4gfGluZGV4fCB2YWx1ZXMgMCwgMSwgLi4uLCBuLTEgZm9yIGEgc2Vx
dWVuY2Ugb2YgbiBsb2cKIGVudHJpZXMuCgoNCgUEAwIBBRIEkwICBwoNCgUEAwIBARIEkwII
DQoNCgUEAwIBAxIEkwIQEQpaCgQEAwICEgSWAgIZGkwgVGhlIHRvdGFsIG51bWJlciBvZiBs
b2cgZW50cmllcyB0aGF0IHRoZSBvcmlnaW5hbCBMb2dFbnRyeSB3YXMgc3BsaXQgaW50by4K
Cg0KBQQDAgIFEgSWAgIHCg0KBQQDAgIBEgSWAggUCg0KBQQDAgIDEgSWAhcYYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Logging::V2::LogEntry::LogEntry ===
    # Fields for LogEntry
    # Field: log_name Type: 9 ()
    # Field: resource Type: 11 (.google.api.MonitoredResource)
    # Field: proto_payload Type: 11 (.google.protobuf.Any)
    # Field: text_payload Type: 9 ()
    # Field: json_payload Type: 11 (.google.protobuf.Struct)
    # Field: timestamp Type: 11 (.google.protobuf.Timestamp)
    # Field: receive_timestamp Type: 11 (.google.protobuf.Timestamp)
    # Field: severity Type: 14 (.google.logging.type.LogSeverity)
    # Field: insert_id Type: 9 ()
    # Field: http_request Type: 11 (.google.logging.type.HttpRequest)
    # Field: labels Type: 11 (.google.logging.v2.LogEntry.LabelsEntry)
    # Field: operation Type: 11 (.google.logging.v2.LogEntryOperation)
    # Field: trace Type: 9 ()
    # Field: span_id Type: 9 ()
    # Field: trace_sampled Type: 8 ()
    # Field: source_location Type: 11 (.google.logging.v2.LogEntrySourceLocation)
    # Field: split Type: 11 (.google.logging.v2.LogSplit)

# === Message: Google::Logging::V2::LogEntry::LogEntryOperation ===
    # Fields for LogEntryOperation
    # Field: id Type: 9 ()
    # Field: producer Type: 9 ()
    # Field: first Type: 8 ()
    # Field: last Type: 8 ()

# === Message: Google::Logging::V2::LogEntry::LogEntrySourceLocation ===
    # Fields for LogEntrySourceLocation
    # Field: file Type: 9 ()
    # Field: line Type: 3 ()
    # Field: function Type: 9 ()

# === Message: Google::Logging::V2::LogEntry::LogSplit ===
    # Fields for LogSplit
    # Field: uid Type: 9 ()
    # Field: index Type: 5 ()
    # Field: total_splits Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Logging::V2::LogEntry - Compiled Protocol Buffers messages for google/logging/v2/log_entry.proto

=head1 SYNOPSIS

    use Google::Logging::V2::LogEntry;

    my $msg = Google::Logging::V2::LogEntry::LogEntry->new({
        log_name => $log_name,
        resource => $resource,
        proto_payload => $proto_payload,
        text_payload => $text_payload,
    });

    # Read or update a field
    my $val = $msg->log_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Logging::V2::LogEntry::LogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/logging/v2/log_entry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Logging::V2::LogEntry::LogEntry

An individual entry in a log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->log_name() >> / C<< $msg->log_name($value) >>

Type: C<String>

Required. The resource name of the log to which this log entry belongs:

    "projects/[PROJECT_ID]/logs/[LOG_ID]"
    "organizations/[ORGANIZATION_ID]/logs/[LOG_ID]"
    "billingAccounts/[BILLING_ACCOUNT_ID]/logs/[LOG_ID]"
    "folders/[FOLDER_ID]/logs/[LOG_ID]"

A project number may be used in place of PROJECT_ID. The project number is
translated to its corresponding PROJECT_ID internally and the `log_name`
field will contain PROJECT_ID in queries and exports.

`[LOG_ID]` must be URL-encoded within `log_name`. Example:
`"organizations/1234567890/logs/cloudresourcemanager.googleapis.com%2Factivity"`.

`[LOG_ID]` must be less than 512 characters long and can only include the
following characters: upper and lower case alphanumeric characters,
forward-slash, underscore, hyphen, and period.

For backward compatibility, if `log_name` begins with a forward-slash, such
as `/projects/...`, then the log entry is ingested as usual, but the
forward-slash is removed. Listing the log entry will not show the leading
slash and filtering for a log name with a leading slash will never return
any results.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Api::MonitoredResource::MonitoredResource>)

Required. The monitored resource that produced this log entry.

Example: a log entry that reports a database error would be associated with
the monitored resource designating the particular database that reported
the error.

=item * C<< $msg->proto_payload() >> / C<< $msg->proto_payload($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The log entry payload, represented as a protocol buffer. Some Google
Cloud Platform services use this field for their log entry payloads.

The following protocol buffer types are supported; user-defined types
are not supported:

  "type.googleapis.com/google.cloud.audit.AuditLog"
  "type.googleapis.com/google.appengine.logging.v1.RequestLog"

=item * C<< $msg->text_payload() >> / C<< $msg->text_payload($value) >>

Type: C<String>

The log entry payload, represented as a Unicode string (UTF-8).

=item * C<< $msg->json_payload() >> / C<< $msg->json_payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The log entry payload, represented as a structure that is
expressed as a JSON object.

=item * C<< $msg->timestamp() >> / C<< $msg->timestamp($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The time the event described by the log entry occurred. This time
is used to compute the log entry's age and to enforce the logs retention
period. If this field is omitted in a new log entry, then Logging assigns
it the current time. Timestamps have nanosecond accuracy, but trailing
zeros in the fractional seconds might be omitted when the timestamp is
displayed.

Incoming log entries must have timestamps that don't exceed the
[logs retention
period](https://cloud.google.com/logging/quotas#logs_retention_periods) in
the past, and that don't exceed 24 hours in the future. Log entries outside
those time boundaries aren't ingested by Logging.

=item * C<< $msg->receive_timestamp() >> / C<< $msg->receive_timestamp($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the log entry was received by Logging.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Logging::Type::LogSeverity>)

Optional. The severity of the log entry. The default value is
`LogSeverity.DEFAULT`.

=item * C<< $msg->insert_id() >> / C<< $msg->insert_id($value) >>

Type: C<String>

Optional. A unique identifier for the log entry. If you provide a value,
then Logging considers other log entries in the same project, with the same
`timestamp`, and with the same `insert_id` to be duplicates which are
removed in a single query result. However, there are no guarantees of
de-duplication in the export of logs.

If the `insert_id` is omitted when writing a log entry, the Logging API
assigns its own unique identifier in this field.

In queries, the `insert_id` is also used to order log entries that have
the same `log_name` and `timestamp` values.

=item * C<< $msg->http_request() >> / C<< $msg->http_request($value) >>

Type: C<Message> (L<Google::Logging::Type::HttpRequest::HttpRequest>)

Optional. Information about the HTTP request associated with this log
entry, if applicable.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Logging::V2::LogEntry::LogEntry::LabelsEntry>)

Optional. A map of key, value pairs that provides additional information
about the log entry. The labels can be user-defined or system-defined.

User-defined labels are arbitrary key, value pairs that you can use to
classify logs.

System-defined labels are defined by GCP services for platform logs.
They have two components - a service namespace component and the
attribute name. For example: `compute.googleapis.com/resource_name`.

Cloud Logging truncates label keys that exceed 512 B and label
values that exceed 64 KB upon their associated log entry being
written. The truncation is indicated by an ellipsis at the
end of the character string.

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<Message> (L<Google::Logging::V2::LogEntry::LogEntryOperation>)

Optional. Information about an operation associated with the log entry, if
applicable.

=item * C<< $msg->trace() >> / C<< $msg->trace($value) >>

Type: C<String>

Optional. The REST resource name of the trace being written to
[Cloud Trace](https://cloud.google.com/trace) in
association with this log entry. For example, if your trace data is stored
in the Cloud project "my-trace-project" and if the service that is creating
the log entry receives a trace header that includes the trace ID "12345",
then the service should use "projects/my-tracing-project/traces/12345".

The `trace` field provides the link between logs and traces. By using
this field, you can navigate from a log entry to a trace.

=item * C<< $msg->span_id() >> / C<< $msg->span_id($value) >>

Type: C<String>

Optional. The ID of the [Cloud Trace](https://cloud.google.com/trace) span
associated with the current operation in which the log is being written.
For example, if a span has the REST resource name of
"projects/some-project/traces/some-trace/spans/some-span-id", then the
`span_id` field is "some-span-id".

A
[Span](https://cloud.google.com/trace/docs/reference/v2/rest/v2/projects.traces/batchWrite#Span)
represents a single operation within a trace. Whereas a trace may involve
multiple different microservices running on multiple different machines,
a span generally corresponds to a single logical operation being performed
in a single instance of a microservice on one specific machine. Spans
are the nodes within the tree that is a trace.

Applications that are [instrumented for
tracing](https://cloud.google.com/trace/docs/setup) will generally assign a
new, unique span ID on each incoming request. It is also common to create
and record additional spans corresponding to internal processing elements
as well as issuing requests to dependencies.

The span ID is expected to be a 16-character, hexadecimal encoding of an
8-byte array and should not be zero. It should be unique within the trace
and should, ideally, be generated in a manner that is uniformly random.

Example values:

  - `000000000000004a`
  - `7a2190356c3fc94b`
  - `0000f00300090021`
  - `d39223e101960076`

=item * C<< $msg->trace_sampled() >> / C<< $msg->trace_sampled($value) >>

Type: C<Bool>

Optional. The sampling decision of the trace associated with the log entry.

True means that the trace resource name in the `trace` field was sampled
for storage in a trace backend. False means that the trace was not sampled
for storage when this log entry was written, or the sampling decision was
unknown at the time. A non-sampled `trace` value is still useful as a
request correlation identifier. The default is False.

=item * C<< $msg->source_location() >> / C<< $msg->source_location($value) >>

Type: C<Message> (L<Google::Logging::V2::LogEntry::LogEntrySourceLocation>)

Optional. Source code location information associated with the log entry,
if any.

=item * C<< $msg->split() >> / C<< $msg->split($value) >>

Type: C<Message> (L<Google::Logging::V2::LogEntry::LogSplit>)

Optional. Information indicating this LogEntry is part of a sequence of
multiple log entries split from a single LogEntry.

=back

=head2 Google::Logging::V2::LogEntry::LogEntryOperation

Additional information about a potentially long-running operation with which
a log entry is associated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional. An arbitrary operation identifier. Log entries with the same
identifier are assumed to be part of the same operation.

=item * C<< $msg->producer() >> / C<< $msg->producer($value) >>

Type: C<String>

Optional. An arbitrary producer identifier. The combination of `id` and
`producer` must be globally unique. Examples for `producer`:
`"MyDivision.MyBigCompany.com"`, `"github.com/MyProject/MyApplication"`.

=item * C<< $msg->first() >> / C<< $msg->first($value) >>

Type: C<Bool>

Optional. Set this to True if this is the first log entry in the operation.

=item * C<< $msg->last() >> / C<< $msg->last($value) >>

Type: C<Bool>

Optional. Set this to True if this is the last log entry in the operation.

=back

=head2 Google::Logging::V2::LogEntry::LogEntrySourceLocation

Additional information about the source code location that produced the log
entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<String>

Optional. Source file name. Depending on the runtime environment, this
might be a simple name or a fully-qualified name.

=item * C<< $msg->line() >> / C<< $msg->line($value) >>

Type: C<Int64>

Optional. Line within the source file. 1-based; 0 indicates no line number
available.

=item * C<< $msg->function() >> / C<< $msg->function($value) >>

Type: C<String>

Optional. Human-readable name of the function or method being invoked, with
optional context such as the class or package name. This information may be
used in contexts such as the logs viewer, where a file and line number are
less meaningful. The format can vary by language. For example:
`qual.if.ied.Class.method` (Java), `dir/package.func` (Go), `function`
(Python).

=back

=head2 Google::Logging::V2::LogEntry::LogSplit

Additional information used to correlate multiple log entries. Used when a
single LogEntry would exceed the Google Cloud Logging size limit and is
split across multiple log entries.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

A globally unique identifier for all log entries in a sequence of split log
entries. All log entries with the same |LogSplit.uid| are assumed to be
part of the same sequence of split log entries.

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

The index of this LogEntry in the sequence of split log entries. Log
entries are given |index| values 0, 1, ..., n-1 for a sequence of n log
entries.

=item * C<< $msg->total_splits() >> / C<< $msg->total_splits($value) >>

Type: C<Int32>

The total number of log entries that the original LogEntry was split into.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Logging::V2::LogEntry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
