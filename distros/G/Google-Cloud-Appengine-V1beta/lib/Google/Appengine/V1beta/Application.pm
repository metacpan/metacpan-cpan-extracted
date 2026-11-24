package Google::Appengine::V1beta::Application;

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
Cilnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9hcHBsaWNhdGlvbi5wcm90bxIXZ29vZ2xlLmFw
cGVuZ2luZS52MWJldGEaHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byKrCgoLQXBw
bGljYXRpb24SEgoEbmFtZRgBIAEoCVIEbmFtZRIOCgJpZBgCIAEoCVICaWQSTwoOZGlzcGF0
Y2hfcnVsZXMYAyADKAsyKC5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5VcmxEaXNwYXRjaFJ1
bGVSDWRpc3BhdGNoUnVsZXMSHwoLYXV0aF9kb21haW4YBiABKAlSCmF1dGhEb21haW4SHwoL
bG9jYXRpb25faWQYByABKAlSCmxvY2F0aW9uSWQSHwoLY29kZV9idWNrZXQYCCABKAlSCmNv
ZGVCdWNrZXQSVQoZZGVmYXVsdF9jb29raWVfZXhwaXJhdGlvbhgJIAEoCzIZLmdvb2dsZS5w
cm90b2J1Zi5EdXJhdGlvblIXZGVmYXVsdENvb2tpZUV4cGlyYXRpb24SWQoOc2VydmluZ19z
dGF0dXMYCiABKA4yMi5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5BcHBsaWNhdGlvbi5TZXJ2
aW5nU3RhdHVzUg1zZXJ2aW5nU3RhdHVzEikKEGRlZmF1bHRfaG9zdG5hbWUYCyABKAlSD2Rl
ZmF1bHRIb3N0bmFtZRIlCg5kZWZhdWx0X2J1Y2tldBgMIAEoCVINZGVmYXVsdEJ1Y2tldBJJ
CgNpYXAYDiABKAsyNy5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5BcHBsaWNhdGlvbi5JZGVu
dGl0eUF3YXJlUHJveHlSA2lhcBIdCgpnY3JfZG9tYWluGBAgASgJUglnY3JEb21haW4SVgoN
ZGF0YWJhc2VfdHlwZRgRIAEoDjIxLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLkFwcGxpY2F0
aW9uLkRhdGFiYXNlVHlwZVIMZGF0YWJhc2VUeXBlEl8KEGZlYXR1cmVfc2V0dGluZ3MYEiAB
KAsyNC5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5BcHBsaWNhdGlvbi5GZWF0dXJlU2V0dGlu
Z3NSD2ZlYXR1cmVTZXR0aW5ncxrJAQoSSWRlbnRpdHlBd2FyZVByb3h5EhgKB2VuYWJsZWQY
ASABKAhSB2VuYWJsZWQSKAoQb2F1dGgyX2NsaWVudF9pZBgCIAEoCVIOb2F1dGgyQ2xpZW50
SWQSMAoUb2F1dGgyX2NsaWVudF9zZWNyZXQYAyABKAlSEm9hdXRoMkNsaWVudFNlY3JldBI9
ChtvYXV0aDJfY2xpZW50X3NlY3JldF9zaGEyNTYYBCABKAlSGG9hdXRoMkNsaWVudFNlY3Jl
dFNoYTI1Nhp+Cg9GZWF0dXJlU2V0dGluZ3MSLgoTc3BsaXRfaGVhbHRoX2NoZWNrcxgBIAEo
CFIRc3BsaXRIZWFsdGhDaGVja3MSOwoadXNlX2NvbnRhaW5lcl9vcHRpbWl6ZWRfb3MYAiAB
KAhSF3VzZUNvbnRhaW5lck9wdGltaXplZE9zIlUKDVNlcnZpbmdTdGF0dXMSDwoLVU5TUEVD
SUZJRUQQABILCgdTRVJWSU5HEAESEQoNVVNFUl9ESVNBQkxFRBACEhMKD1NZU1RFTV9ESVNB
QkxFRBADInoKDERhdGFiYXNlVHlwZRIdChlEQVRBQkFTRV9UWVBFX1VOU1BFQ0lGSUVEEAAS
EwoPQ0xPVURfREFUQVNUT1JFEAESEwoPQ0xPVURfRklSRVNUT1JFEAISIQodQ0xPVURfREFU
QVNUT1JFX0NPTVBBVElCSUxJVFkQAyJXCg9VcmxEaXNwYXRjaFJ1bGUSFgoGZG9tYWluGAEg
ASgJUgZkb21haW4SEgoEcGF0aBgCIAEoCVIEcGF0aBIYCgdzZXJ2aWNlGAMgASgJUgdzZXJ2
aWNlQtYBChtjb20uZ29vZ2xlLmFwcGVuZ2luZS52MWJldGFCEEFwcGxpY2F0aW9uUHJvdG9Q
AVpAZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hcHBlbmdpbmUvdjFi
ZXRhO2FwcGVuZ2luZaoCHUdvb2dsZS5DbG91ZC5BcHBFbmdpbmUuVjFCZXRhygIdR29vZ2xl
XENsb3VkXEFwcEVuZ2luZVxWMWJldGHqAiBHb29nbGU6OkNsb3VkOjpBcHBFbmdpbmU6OlYx
YmV0YUrKMgoHEgUOAMABAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAAIAoJCgIDABIDEgAoCggKAQgSAxQAOgoJCgIIJRIDFAA6CggKAQgSAxUAVwoJCgII
CxIDFQBXCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMQoJCgIICBIDFwAxCggKAQgS
AxgANAoJCgIIARIDGAA0CggKAQgSAxkAOgoJCgIIKRIDGQA6CggKAQgSAxoAOQoJCgIILRID
GgA5CmoKAgQAEgUeAKsBARpdIEFuIEFwcGxpY2F0aW9uIHJlc291cmNlIGNvbnRhaW5zIHRo
ZSB0b3AtbGV2ZWwgY29uZmlndXJhdGlvbiBvZiBhbiBBcHAKIEVuZ2luZSBhcHBsaWNhdGlv
bi4KCgoKAwQAARIDHggTCiQKBAQAAwASBCACOAMaFiBJZGVudGl0eS1Bd2FyZSBQcm94eQoK
DAoFBAADAAESAyAKHArEAQoGBAADAAIAEgMmBBUatAEgV2hldGhlciB0aGUgc2VydmluZyBp
bmZyYXN0cnVjdHVyZSB3aWxsIGF1dGhlbnRpY2F0ZSBhbmQKIGF1dGhvcml6ZSBhbGwgaW5j
b21pbmcgcmVxdWVzdHMuCgogSWYgdHJ1ZSwgdGhlIGBvYXV0aDJfY2xpZW50X2lkYCBhbmQg
YG9hdXRoMl9jbGllbnRfc2VjcmV0YAogZmllbGRzIG11c3QgYmUgbm9uLWVtcHR5LgoKDgoH
BAADAAIABRIDJgQICg4KBwQAAwACAAESAyYJEAoOCgcEAAMAAgADEgMmExQKRQoGBAADAAIB
EgMpBCAaNiBPQXV0aDIgY2xpZW50IElEIHRvIHVzZSBmb3IgdGhlIGF1dGhlbnRpY2F0aW9u
IGZsb3cuCgoOCgcEAAMAAgEFEgMpBAoKDgoHBAADAAIBARIDKQsbCg4KBwQAAwACAQMSAyke
Hwr8AQoGBAADAAICEgMyBCQa7AEgT0F1dGgyIGNsaWVudCBzZWNyZXQgdG8gdXNlIGZvciB0
aGUgYXV0aGVudGljYXRpb24gZmxvdy4KCiBGb3Igc2VjdXJpdHkgcmVhc29ucywgdGhpcyB2
YWx1ZSBjYW5ub3QgYmUgcmV0cmlldmVkIHZpYSB0aGUgQVBJLgogSW5zdGVhZCwgdGhlIFNI
QS0yNTYgaGFzaCBvZiB0aGUgdmFsdWUgaXMgcmV0dXJuZWQgaW4gdGhlCiBgb2F1dGgyX2Ns
aWVudF9zZWNyZXRfc2hhMjU2YCBmaWVsZC4KCiBASW5wdXRPbmx5CgoOCgcEAAMAAgIFEgMy
BAoKDgoHBAADAAICARIDMgsfCg4KBwQAAwACAgMSAzIiIwpNCgYEAAMAAgMSAzcEKxo+IEhl
eC1lbmNvZGVkIFNIQS0yNTYgaGFzaCBvZiB0aGUgY2xpZW50IHNlY3JldC4KCiBAT3V0cHV0
T25seQoKDgoHBAADAAIDBRIDNwQKCg4KBwQAAwACAwESAzcLJgoOCgcEAAMAAgMDEgM3KSoK
gAEKBAQAAwESBDwCSAMaciBUaGUgZmVhdHVyZSBzcGVjaWZpYyBzZXR0aW5ncyB0byBiZSB1
c2VkIGluIHRoZSBhcHBsaWNhdGlvbi4gVGhlc2UgZGVmaW5lCiBiZWhhdmlvcnMgdGhhdCBh
cmUgdXNlciBjb25maWd1cmFibGUuCgoMCgUEAAMBARIDPAoZCuoCCgYEAAMBAgASA0MEIRra
AiBCb29sZWFuIHZhbHVlIGluZGljYXRpbmcgaWYgc3BsaXQgaGVhbHRoIGNoZWNrcyBzaG91
bGQgYmUgdXNlZCBpbnN0ZWFkCiBvZiB0aGUgbGVnYWN5IGhlYWx0aCBjaGVja3MuIEF0IGFu
IGFwcC55YW1sIGxldmVsLCB0aGlzIG1lYW5zIGRlZmF1bHRpbmcKIHRvICdyZWFkaW5lc3Nf
Y2hlY2snIGFuZCAnbGl2ZW5lc3NfY2hlY2snIHZhbHVlcyBpbnN0ZWFkIG9mCiAnaGVhbHRo
X2NoZWNrJyBvbmVzLiBPbmNlIHRoZSBsZWdhY3kgJ2hlYWx0aF9jaGVjaycgYmVoYXZpb3Ig
aXMKIGRlcHJlY2F0ZWQsIGFuZCB0aGlzIHZhbHVlIGlzIGFsd2F5cyB0cnVlLCB0aGlzIHNl
dHRpbmcgY2FuCiBiZSByZW1vdmVkLgoKDgoHBAADAQIABRIDQwQICg4KBwQAAwECAAESA0MJ
HAoOCgcEAAMBAgADEgNDHyAKnwEKBgQAAwECARIDRwQoGo8BIElmIHRydWUsIHVzZSBbQ29u
dGFpbmVyLU9wdGltaXplZCBPU10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbnRhaW5l
ci1vcHRpbWl6ZWQtb3MvKQogYmFzZSBpbWFnZSBmb3IgVk1zLCByYXRoZXIgdGhhbiBhIGJh
c2UgRGViaWFuIGltYWdlLgoKDgoHBAADAQIBBRIDRwQICg4KBwQAAwECAQESA0cJIwoOCgcE
AAMBAgEDEgNHJicKDAoEBAAEABIESgJWAwoMCgUEAAQAARIDSgcUCi8KBgQABAACABIDTAQU
GiAgU2VydmluZyBzdGF0dXMgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgNMBA8KDgoH
BAAEAAIAAhIDTBITCigKBgQABAACARIDTwQQGhkgQXBwbGljYXRpb24gaXMgc2VydmluZy4K
Cg4KBwQABAACAQESA08ECwoOCgcEAAQAAgECEgNPDg8KOwoGBAAEAAICEgNSBBYaLCBBcHBs
aWNhdGlvbiBoYXMgYmVlbiBkaXNhYmxlZCBieSB0aGUgdXNlci4KCg4KBwQABAACAgESA1IE
EQoOCgcEAAQAAgICEgNSFBUKPQoGBAAEAAIDEgNVBBgaLiBBcHBsaWNhdGlvbiBoYXMgYmVl
biBkaXNhYmxlZCBieSB0aGUgc3lzdGVtLgoKDgoHBAAEAAIDARIDVQQTCg4KBwQABAACAwIS
A1UWFwoMCgQEAAQBEgRYAmQDCgwKBQQABAEBEgNYBxMKLgoGBAAEAQIAEgNaBCIaHyBEYXRh
YmFzZSB0eXBlIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAEAQIAARIDWgQdCg4KBwQABAECAAIS
A1ogIQogCgYEAAQBAgESA10EGBoRIENsb3VkIERhdGFzdG9yZQoKDgoHBAAEAQIBARIDXQQT
Cg4KBwQABAECAQISA10WFwonCgYEAAQBAgISA2AEGBoYIENsb3VkIEZpcmVzdG9yZSBOYXRp
dmUKCg4KBwQABAECAgESA2AEEwoOCgcEAAQBAgICEgNgFhcKMgoGBAAEAQIDEgNjBCYaIyBD
bG91ZCBGaXJlc3RvcmUgaW4gRGF0YXN0b3JlIE1vZGUKCg4KBwQABAECAwESA2MEIQoOCgcE
AAQBAgMCEgNjJCUKZgoEBAACABIDagISGlkgRnVsbCBwYXRoIHRvIHRoZSBBcHBsaWNhdGlv
biByZXNvdXJjZSBpbiB0aGUgQVBJLgogRXhhbXBsZTogYGFwcHMvbXlhcHBgLgoKIEBPdXRw
dXRPbmx5CgoMCgUEAAIABRIDagIICgwKBQQAAgABEgNqCQ0KDAoFBAACAAMSA2oQEQrMAQoE
BAACARIDcAIQGr4BIElkZW50aWZpZXIgb2YgdGhlIEFwcGxpY2F0aW9uIHJlc291cmNlLiBU
aGlzIGlkZW50aWZpZXIgaXMgZXF1aXZhbGVudAogdG8gdGhlIHByb2plY3QgSUQgb2YgdGhl
IEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBwcm9qZWN0IHdoZXJlIHlvdSB3YW50IHRvCiBkZXBs
b3kgeW91ciBhcHBsaWNhdGlvbi4KIEV4YW1wbGU6IGBteWFwcGAuCgoMCgUEAAIBBRIDcAII
CgwKBQQAAgEBEgNwCQsKDAoFBAACAQMSA3AODwrDAQoEBAACAhIDdQIuGrUBIEhUVFAgcGF0
aCBkaXNwYXRjaCBydWxlcyBmb3IgcmVxdWVzdHMgdG8gdGhlIGFwcGxpY2F0aW9uIHRoYXQg
ZG8gbm90CiBleHBsaWNpdGx5IHRhcmdldCBhIHNlcnZpY2Ugb3IgdmVyc2lvbi4gUnVsZXMg
YXJlIG9yZGVyLWRlcGVuZGVudC4KIFVwIHRvIDIwIGRpc3BhdGNoIHJ1bGVzIGNhbiBiZSBz
dXBwb3J0ZWQuCgoMCgUEAAICBBIDdQIKCgwKBQQAAgIGEgN1CxoKDAoFBAACAgESA3UbKQoM
CgUEAAICAxIDdSwtCpsBCgQEAAIDEgN7AhkajQEgR29vZ2xlIEFwcHMgYXV0aGVudGljYXRp
b24gZG9tYWluIHRoYXQgY29udHJvbHMgd2hpY2ggdXNlcnMgY2FuIGFjY2VzcwogdGhpcyBh
cHBsaWNhdGlvbi4KCiBEZWZhdWx0cyB0byBvcGVuIGFjY2VzcyBmb3IgYW55IEdvb2dsZSBB
Y2NvdW50LgoKDAoFBAACAwUSA3sCCAoMCgUEAAIDARIDewkUCgwKBQQAAgMDEgN7FxgKzQIK
BAQAAgQSBIUBAhkavgIgTG9jYXRpb24gZnJvbSB3aGljaCB0aGlzIGFwcGxpY2F0aW9uIHJ1
bnMuIEFwcGxpY2F0aW9uIGluc3RhbmNlcwogcnVuIG91dCBvZiB0aGUgZGF0YSBjZW50ZXJz
IGluIHRoZSBzcGVjaWZpZWQgbG9jYXRpb24sIHdoaWNoIGlzIGFsc28gd2hlcmUKIGFsbCBv
ZiB0aGUgYXBwbGljYXRpb24ncyBlbmQgdXNlciBjb250ZW50IGlzIHN0b3JlZC4KCiBEZWZh
dWx0cyB0byBgdXMtY2VudHJhbGAuCgogVmlldyB0aGUgbGlzdCBvZgogW3N1cHBvcnRlZCBs
b2NhdGlvbnNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcHBlbmdpbmUvZG9jcy9sb2Nh
dGlvbnMpLgoKDQoFBAACBAUSBIUBAggKDQoFBAACBAESBIUBCRQKDQoFBAACBAMSBIUBFxgK
4wEKBAQAAgUSBIwBAhka1AEgR29vZ2xlIENsb3VkIFN0b3JhZ2UgYnVja2V0IHRoYXQgY2Fu
IGJlIHVzZWQgZm9yIHN0b3JpbmcgZmlsZXMKIGFzc29jaWF0ZWQgd2l0aCB0aGlzIGFwcGxp
Y2F0aW9uLiBUaGlzIGJ1Y2tldCBpcyBhc3NvY2lhdGVkIHdpdGggdGhlCiBhcHBsaWNhdGlv
biBhbmQgY2FuIGJlIHVzZWQgYnkgdGhlIGdjbG91ZCBkZXBsb3ltZW50IGNvbW1hbmRzLgoK
IEBPdXRwdXRPbmx5CgoNCgUEAAIFBRIEjAECCAoNCgUEAAIFARIEjAEJFAoNCgUEAAIFAxIE
jAEXGAo+CgQEAAIGEgSPAQI5GjAgQ29va2llIGV4cGlyYXRpb24gcG9saWN5IGZvciB0aGlz
IGFwcGxpY2F0aW9uLgoKDQoFBAACBgYSBI8BAhoKDQoFBAACBgESBI8BGzQKDQoFBAACBgMS
BI8BNzgKMwoEBAACBxIEkgECJBolIFNlcnZpbmcgc3RhdHVzIG9mIHRoaXMgYXBwbGljYXRp
b24uCgoNCgUEAAIHBhIEkgECDwoNCgUEAAIHARIEkgEQHgoNCgUEAAIHAxIEkgEhIwphCgQE
AAIIEgSXAQIfGlMgSG9zdG5hbWUgdXNlZCB0byByZWFjaCB0aGlzIGFwcGxpY2F0aW9uLCBh
cyByZXNvbHZlZCBieSBBcHAgRW5naW5lLgoKIEBPdXRwdXRPbmx5CgoNCgUEAAIIBRIElwEC
CAoNCgUEAAIIARIElwEJGQoNCgUEAAIIAxIElwEcHgpxCgQEAAIJEgSdAQIdGmMgR29vZ2xl
IENsb3VkIFN0b3JhZ2UgYnVja2V0IHRoYXQgY2FuIGJlIHVzZWQgYnkgdGhpcyBhcHBsaWNh
dGlvbiB0byBzdG9yZQogY29udGVudC4KCiBAT3V0cHV0T25seQoKDQoFBAACCQUSBJ0BAggK
DQoFBAACCQESBJ0BCRcKDQoFBAACCQMSBJ0BGhwKDAoEBAACChIEnwECHgoNCgUEAAIKBhIE
nwECFAoNCgUEAAIKARIEnwEVGAoNCgUEAAIKAxIEnwEbHQp4CgQEAAILEgSjAQIZGmogVGhl
IEdvb2dsZSBDb250YWluZXIgUmVnaXN0cnkgZG9tYWluIHVzZWQgZm9yIHN0b3JpbmcgbWFu
YWdlZCBidWlsZCBkb2NrZXIKIGltYWdlcyBmb3IgdGhpcyBhcHBsaWNhdGlvbi4KCg0KBQQA
AgsFEgSjAQIICg0KBQQAAgsBEgSjAQkTCg0KBQQAAgsDEgSjARYYCm4KBAQAAgwSBKcBAiIa
YCBUaGUgdHlwZSBvZiB0aGUgQ2xvdWQgRmlyZXN0b3JlIG9yIENsb3VkIERhdGFzdG9yZSBk
YXRhYmFzZSBhc3NvY2lhdGVkIHdpdGgKIHRoaXMgYXBwbGljYXRpb24uCgoNCgUEAAIMBhIE
pwECDgoNCgUEAAIMARIEpwEPHAoNCgUEAAIMAxIEpwEfIQpMCgQEAAINEgSqAQIoGj4gVGhl
IGZlYXR1cmUgc3BlY2lmaWMgc2V0dGluZ3MgdG8gYmUgdXNlZCBpbiB0aGUgYXBwbGljYXRp
b24uCgoNCgUEAAINBhIEqgECEQoNCgUEAAINARIEqgESIgoNCgUEAAINAxIEqgElJwpWCgIE
ARIGrgEAwAEBGkggUnVsZXMgdG8gbWF0Y2ggYW4gSFRUUCByZXF1ZXN0IGFuZCBkaXNwYXRj
aCB0aGF0IHJlcXVlc3QgdG8gYSBzZXJ2aWNlLgoKCwoDBAEBEgSuAQgXCqABCgQEAQIAEgSz
AQIUGpEBIERvbWFpbiBuYW1lIHRvIG1hdGNoIGFnYWluc3QuIFRoZSB3aWxkY2FyZCAiYCpg
IiBpcyBzdXBwb3J0ZWQgaWYKIHNwZWNpZmllZCBiZWZvcmUgYSBwZXJpb2Q6ICJgKi5gIi4K
CiBEZWZhdWx0cyB0byBtYXRjaGluZyBhbGwgZG9tYWluczogImAqYCIuCgoNCgUEAQIABRIE
swECCAoNCgUEAQIAARIEswEJDwoNCgUEAQIAAxIEswESEwrLAQoEBAECARIEugECEhq8ASBQ
YXRobmFtZSB3aXRoaW4gdGhlIGhvc3QuIE11c3Qgc3RhcnQgd2l0aCBhICJgL2AiLiBBCiBz
aW5nbGUgImAqYCIgY2FuIGJlIGluY2x1ZGVkIGF0IHRoZSBlbmQgb2YgdGhlIHBhdGguCgog
VGhlIHN1bSBvZiB0aGUgbGVuZ3RocyBvZiB0aGUgZG9tYWluIGFuZCBwYXRoIG1heSBub3QK
IGV4Y2VlZCAxMDAgY2hhcmFjdGVycy4KCg0KBQQBAgEFEgS6AQIICg0KBQQBAgEBEgS6AQkN
Cg0KBQQBAgEDEgS6ARARCpoBCgQEAQICEgS/AQIVGosBIFJlc291cmNlIElEIG9mIGEgc2Vy
dmljZSBpbiB0aGlzIGFwcGxpY2F0aW9uIHRoYXQgc2hvdWxkCiBzZXJ2ZSB0aGUgbWF0Y2hl
ZCByZXF1ZXN0LiBUaGUgc2VydmljZSBtdXN0IGFscmVhZHkKIGV4aXN0LiBFeGFtcGxlOiBg
ZGVmYXVsdGAuCgoNCgUEAQICBRIEvwECCAoNCgUEAQICARIEvwEJEAoNCgUEAQICAxIEvwET
FGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Application::Application ===
    # Fields for Application
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: dispatch_rules Type: 11 (.google.appengine.v1beta.UrlDispatchRule)
    # Field: auth_domain Type: 9 ()
    # Field: location_id Type: 9 ()
    # Field: code_bucket Type: 9 ()
    # Field: default_cookie_expiration Type: 11 (.google.protobuf.Duration)
    # Field: serving_status Type: 14 (.google.appengine.v1beta.Application.ServingStatus)
    # Field: default_hostname Type: 9 ()
    # Field: default_bucket Type: 9 ()
    # Field: iap Type: 11 (.google.appengine.v1beta.Application.IdentityAwareProxy)
    # Field: gcr_domain Type: 9 ()
    # Field: database_type Type: 14 (.google.appengine.v1beta.Application.DatabaseType)
    # Field: feature_settings Type: 11 (.google.appengine.v1beta.Application.FeatureSettings)

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

# === Message: Google::Appengine::V1beta::Application::UrlDispatchRule ===
    # Fields for UrlDispatchRule
    # Field: domain Type: 9 ()
    # Field: path Type: 9 ()
    # Field: service Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Application - Compiled Protocol Buffers messages for google/appengine/v1beta/application.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Application;

    my $msg = Google::Appengine::V1beta::Application::Application->new({
        name => $name,
        id => $id,
        dispatch_rules => $dispatch_rules,
        auth_domain => $auth_domain,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Application::Application->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/application.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Application::Application

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

Type: C<Message> (L<Google::Appengine::V1beta::Application::UrlDispatchRule>)

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

Type: C<Enum> (L<Google::Appengine::V1beta::Application::ServingStatus>)

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

=item * C<< $msg->iap() >> / C<< $msg->iap($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Application::Application::IdentityAwareProxy>)

=item * C<< $msg->gcr_domain() >> / C<< $msg->gcr_domain($value) >>

Type: C<String>

The Google Container Registry domain used for storing managed build docker
images for this application.

=item * C<< $msg->database_type() >> / C<< $msg->database_type($value) >>

Type: C<Enum> (L<Google::Appengine::V1beta::Application::DatabaseType>)

The type of the Cloud Firestore or Cloud Datastore database associated with
this application.

=item * C<< $msg->feature_settings() >> / C<< $msg->feature_settings($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Application::Application::FeatureSettings>)

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

=head2 Google::Appengine::V1beta::Application::UrlDispatchRule

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Application::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
