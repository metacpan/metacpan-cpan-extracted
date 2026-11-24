package Google::Cloud::Websecurityscanner::V1::FindingAddon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL2ZpbmRpbmdfYWRkb24ucHJv
dG8SImdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjEiPQoERm9ybRIdCgphY3Rp
b25fdXJpGAEgASgJUglhY3Rpb25VcmkSFgoGZmllbGRzGAIgAygJUgZmaWVsZHMidgoPT3V0
ZGF0ZWRMaWJyYXJ5EiEKDGxpYnJhcnlfbmFtZRgBIAEoCVILbGlicmFyeU5hbWUSGAoHdmVy
c2lvbhgCIAEoCVIHdmVyc2lvbhImCg9sZWFybl9tb3JlX3VybHMYAyADKAlSDWxlYXJuTW9y
ZVVybHMiWQoRVmlvbGF0aW5nUmVzb3VyY2USIQoMY29udGVudF90eXBlGAEgASgJUgtjb250
ZW50VHlwZRIhCgxyZXNvdXJjZV91cmwYAiABKAlSC3Jlc291cmNlVXJsIj8KFFZ1bG5lcmFi
bGVQYXJhbWV0ZXJzEicKD3BhcmFtZXRlcl9uYW1lcxgBIAMoCVIOcGFyYW1ldGVyTmFtZXMi
hgIKEVZ1bG5lcmFibGVIZWFkZXJzElYKB2hlYWRlcnMYASADKAsyPC5nb29nbGUuY2xvdWQu
d2Vic2VjdXJpdHlzY2FubmVyLnYxLlZ1bG5lcmFibGVIZWFkZXJzLkhlYWRlclIHaGVhZGVy
cxJlCg9taXNzaW5nX2hlYWRlcnMYAiADKAsyPC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlz
Y2FubmVyLnYxLlZ1bG5lcmFibGVIZWFkZXJzLkhlYWRlclIObWlzc2luZ0hlYWRlcnMaMgoG
SGVhZGVyEhIKBG5hbWUYASABKAlSBG5hbWUSFAoFdmFsdWUYAiABKAlSBXZhbHVlIpkECgNY
c3MSIQoMc3RhY2tfdHJhY2VzGAEgAygJUgtzdGFja1RyYWNlcxIjCg1lcnJvcl9tZXNzYWdl
GAIgASgJUgxlcnJvck1lc3NhZ2USWQoNYXR0YWNrX3ZlY3RvchgDIAEoDjI0Lmdvb2dsZS5j
bG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjEuWHNzLkF0dGFja1ZlY3RvclIMYXR0YWNrVmVj
dG9yEjMKFnN0b3JlZF94c3Nfc2VlZGluZ191cmwYBCABKAlSE3N0b3JlZFhzc1NlZWRpbmdV
cmwiuQIKDEF0dGFja1ZlY3RvchIdChlBVFRBQ0tfVkVDVE9SX1VOU1BFQ0lGSUVEEAASEQoN
TE9DQUxfU1RPUkFHRRABEhMKD1NFU1NJT05fU1RPUkFHRRACEg8KC1dJTkRPV19OQU1FEAMS
DAoIUkVGRVJSRVIQBBIOCgpGT1JNX0lOUFVUEAUSCgoGQ09PS0lFEAYSEAoMUE9TVF9NRVNT
QUdFEAcSEgoOR0VUX1BBUkFNRVRFUlMQCBIQCgxVUkxfRlJBR01FTlQQCRIQCgxIVE1MX0NP
TU1FTlQQChITCg9QT1NUX1BBUkFNRVRFUlMQCxIMCghQUk9UT0NPTBAMEg4KClNUT1JFRF9Y
U1MQDRIPCgtTQU1FX09SSUdJThAOEhkKFVVTRVJfQ09OVFJPTExBQkxFX1VSTBAPIsgBCgNY
eGUSIwoNcGF5bG9hZF92YWx1ZRgBIAEoCVIMcGF5bG9hZFZhbHVlElsKEHBheWxvYWRfbG9j
YXRpb24YAiABKA4yMC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLlh4ZS5M
b2NhdGlvblIPcGF5bG9hZExvY2F0aW9uIj8KCExvY2F0aW9uEhgKFExPQ0FUSU9OX1VOU1BF
Q0lGSUVEEAASGQoVQ09NUExFVEVfUkVRVUVTVF9CT0RZEAFChwIKJmNvbS5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxQhFGaW5kaW5nQWRkb25Qcm90b1ABWlZjbG91ZC5n
b29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9hcGl2MS93ZWJzZWN1cml0eXNjYW5u
ZXJwYjt3ZWJzZWN1cml0eXNjYW5uZXJwYqoCIkdvb2dsZS5DbG91ZC5XZWJTZWN1cml0eVNj
YW5uZXIuVjHKAiJHb29nbGVcQ2xvdWRcV2ViU2VjdXJpdHlTY2FubmVyXFYx6gIlR29vZ2xl
OjpDbG91ZDo6V2ViU2VjdXJpdHlTY2FubmVyOjpWMUrnKQoHEgUOAKUBAQq8BAoBDBIDDgAS
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
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoICgEIEgMSAD8KCQoCCCUSAxIA
PwoICgEIEgMTAG0KCQoCCAsSAxMAbQoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADIK
CQoCCAgSAxUAMgoICgEIEgMWAD8KCQoCCAESAxYAPwoICgEIEgMXAD8KCQoCCCkSAxcAPwoI
CgEIEgMYAD4KCQoCCC0SAxgAPgo/CgIEABIEGwAhARozICEgSW5mb3JtYXRpb24gYWJvdXQg
YSB2dWxuZXJhYmlsaXR5IHdpdGggYW4gSFRNTC4KCgoKAwQAARIDGwgMCkQKBAQAAgASAx0C
GBo3ICEgVGhlIFVSSSB3aGVyZSB0byBzZW5kIHRoZSBmb3JtIHdoZW4gaXQncyBzdWJtaXR0
ZWQuCgoMCgUEAAIABRIDHQIICgwKBQQAAgABEgMdCRMKDAoFBAACAAMSAx0WFwpHCgQEAAIB
EgMgAh0aOiAhIFRoZSBuYW1lcyBvZiBmb3JtIGZpZWxkcyByZWxhdGVkIHRvIHRoZSB2dWxu
ZXJhYmlsaXR5LgoKDAoFBAACAQQSAyACCgoMCgUEAAIBBRIDIAsRCgwKBQQAAgEBEgMgEhgK
DAoFBAACAQMSAyAbHAo7CgIEARIEJAAtARovIEluZm9ybWF0aW9uIHJlcG9ydGVkIGZvciBh
biBvdXRkYXRlZCBsaWJyYXJ5LgoKCgoDBAEBEgMkCBcKMAoEBAECABIDJgIaGiMgVGhlIG5h
bWUgb2YgdGhlIG91dGRhdGVkIGxpYnJhcnkuCgoMCgUEAQIABRIDJgIICgwKBQQBAgABEgMm
CRUKDAoFBAECAAMSAyYYGQoiCgQEAQIBEgMpAhUaFSBUaGUgdmVyc2lvbiBudW1iZXIuCgoM
CgUEAQIBBRIDKQIICgwKBQQBAgEBEgMpCRAKDAoFBAECAQMSAykTFApXCgQEAQICEgMsAiYa
SiBVUkxzIHRvIGxlYXJuIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHZ1bG5lcmFiaWxp
dGllcyBpbiB0aGUgbGlicmFyeS4KCgwKBQQBAgIEEgMsAgoKDAoFBAECAgUSAywLEQoMCgUE
AQICARIDLBIhCgwKBQQBAgIDEgMsJCUKgAEKAgQCEgQxADcBGnQgSW5mb3JtYXRpb24gcmVn
YXJkaW5nIGFueSByZXNvdXJjZSBjYXVzaW5nIHRoZSB2dWxuZXJhYmlsaXR5IHN1Y2gKIGFz
IEphdmFTY3JpcHQgc291cmNlcywgaW1hZ2UsIGF1ZGlvIGZpbGVzLCBldGMuCgoKCgMEAgES
AzEIGQouCgQEAgIAEgMzAhoaISBUaGUgTUlNRSB0eXBlIG9mIHRoaXMgcmVzb3VyY2UuCgoM
CgUEAgIABRIDMwIICgwKBQQCAgABEgMzCRUKDAoFBAICAAMSAzMYGQouCgQEAgIBEgM2Ahoa
ISBVUkwgb2YgdGhpcyB2aW9sYXRpbmcgcmVzb3VyY2UuCgoMCgUEAgIBBRIDNgIICgwKBQQC
AgEBEgM2CRUKDAoFBAICAQMSAzYYGQo+CgIEAxIEOgA9ARoyIEluZm9ybWF0aW9uIGFib3V0
IHZ1bG5lcmFibGUgcmVxdWVzdCBwYXJhbWV0ZXJzLgoKCgoDBAMBEgM6CBwKLgoEBAMCABID
PAImGiEgVGhlIHZ1bG5lcmFibGUgcGFyYW1ldGVyIG5hbWVzLgoKDAoFBAMCAAQSAzwCCgoM
CgUEAwIABRIDPAsRCgwKBQQDAgABEgM8EiEKDAoFBAMCAAMSAzwkJQpDCgIEBBIEQABPARo3
IEluZm9ybWF0aW9uIGFib3V0IHZ1bG5lcmFibGUgb3IgbWlzc2luZyBIVFRQIEhlYWRlcnMu
CgoKCgMEBAESA0AIGQooCgQEBAMAEgRCAkgDGhogRGVzY3JpYmVzIGEgSFRUUCBIZWFkZXIu
CgoMCgUEBAMAARIDQgoQCh0KBgQEAwACABIDRAQUGg4gSGVhZGVyIG5hbWUuCgoOCgcEBAMA
AgAFEgNEBAoKDgoHBAQDAAIAARIDRAsPCg4KBwQEAwACAAMSA0QSEwoeCgYEBAMAAgESA0cE
FRoPIEhlYWRlciB2YWx1ZS4KCg4KBwQEAwACAQUSA0cECgoOCgcEBAMAAgEBEgNHCxAKDgoH
BAQDAAIBAxIDRxMUCioKBAQEAgASA0sCHhodIExpc3Qgb2YgdnVsbmVyYWJsZSBoZWFkZXJz
LgoKDAoFBAQCAAQSA0sCCgoMCgUEBAIABhIDSwsRCgwKBQQEAgABEgNLEhkKDAoFBAQCAAMS
A0scHQonCgQEBAIBEgNOAiYaGiBMaXN0IG9mIG1pc3NpbmcgaGVhZGVycy4KCgwKBQQEAgEE
EgNOAgoKDAoFBAQCAQYSA04LEQoMCgUEBAIBARIDThIhCgwKBQQEAgEDEgNOJCUKLwoCBAUS
BVIAkgEBGiIgSW5mb3JtYXRpb24gcmVwb3J0ZWQgZm9yIGFuIFhTUy4KCgoKAwQFARIDUggL
CiwKBAQFBAASBVQChQEDGh0gVHlwZXMgb2YgWFNTIGF0dGFjayB2ZWN0b3IuCgoMCgUEBQQA
ARIDVAcTCicKBgQFBAACABIDVgQiGhggVW5rbm93biBhdHRhY2sgdmVjdG9yLgoKDgoHBAUE
AAIAARIDVgQdCg4KBwQFBAACAAISA1YgIQpKCgYEBQQAAgESA1kEFho7IFRoZSBhdHRhY2sg
Y29tZXMgZnJvbSBmdXp6aW5nIHRoZSBicm93c2VyJ3MgbG9jYWxTdG9yYWdlLgoKDgoHBAUE
AAIBARIDWQQRCg4KBwQFBAACAQISA1kUFQpMCgYEBQQAAgISA1wEGBo9IFRoZSBhdHRhY2sg
Y29tZXMgZnJvbSBmdXp6aW5nIHRoZSBicm93c2VyJ3Mgc2Vzc2lvblN0b3JhZ2UuCgoOCgcE
BQQAAgIBEgNcBBMKDgoHBAUEAAICAhIDXBYXCkoKBgQFBAACAxIDXwQUGjsgVGhlIGF0dGFj
ayBjb21lcyBmcm9tIGZ1enppbmcgdGhlIHdpbmRvdydzIG5hbWUgcHJvcGVydHkuCgoOCgcE
BQQAAgMBEgNfBA8KDgoHBAUEAAIDAhIDXxITCkUKBgQFBAACBBIDYgQRGjYgVGhlIGF0dGFj
ayBjb21lcyBmcm9tIGZ1enppbmcgdGhlIHJlZmVycmVyIHByb3BlcnR5LgoKDgoHBAUEAAIE
ARIDYgQMCg4KBwQFBAACBAISA2IPEApACgYEBQQAAgUSA2UEExoxIFRoZSBhdHRhY2sgY29t
ZXMgZnJvbSBmdXp6aW5nIGFuIGlucHV0IGVsZW1lbnQuCgoOCgcEBQQAAgUBEgNlBA4KDgoH
BAUEAAIFAhIDZRESCkUKBgQFBAACBhIDaAQPGjYgVGhlIGF0dGFjayBjb21lcyBmcm9tIGZ1
enppbmcgdGhlIGJyb3dzZXIncyBjb29raWVzLgoKDgoHBAUEAAIGARIDaAQKCg4KBwQFBAAC
BgISA2gNDgpOCgYEBQQAAgcSA2sEFRo/IFRoZSBhdHRhY2sgY29tZXMgZnJvbSBoaWphY2tp
bmcgdGhlIHBvc3QgbWVzc2FnaW5nIG1lY2hhbmlzbS4KCg4KBwQFBAACBwESA2sEEAoOCgcE
BQQAAgcCEgNrExQKRQoGBAUEAAIIEgNuBBcaNiBUaGUgYXR0YWNrIGNvbWVzIGZyb20gZnV6
emluZyBwYXJhbWV0ZXJzIGluIHRoZSB1cmwuCgoOCgcEBQQAAggBEgNuBBIKDgoHBAUEAAII
AhIDbhUWCkcKBgQFBAACCRIDcQQVGjggVGhlIGF0dGFjayBjb21lcyBmcm9tIGZ1enppbmcg
dGhlIGZyYWdtZW50IGluIHRoZSB1cmwuCgoOCgcEBQQAAgkBEgNxBBAKDgoHBAUEAAIJAhID
cRMUCkEKBgQFBAACChIDdAQWGjIgVGhlIGF0dGFjayBjb21lcyBmcm9tIGZ1enppbmcgdGhl
IEhUTUwgY29tbWVudHMuCgoOCgcEBQQAAgoBEgN0BBAKDgoHBAUEAAIKAhIDdBMVCkMKBgQF
BAACCxIDdwQZGjQgVGhlIGF0dGFjayBjb21lcyBmcm9tIGZ1enppbmcgdGhlIFBPU1QgcGFy
YW1ldGVycy4KCg4KBwQFBAACCwESA3cEEwoOCgcEBQQAAgsCEgN3FhgKPAoGBAUEAAIMEgN6
BBIaLSBUaGUgYXR0YWNrIGNvbWVzIGZyb20gZnV6emluZyB0aGUgcHJvdG9jb2wuCgoOCgcE
BQQAAgwBEgN6BAwKDgoHBAUEAAIMAhIDeg8RCkUKBgQFBAACDRIDfQQUGjYgVGhlIGF0dGFj
ayBjb21lcyBmcm9tIHRoZSBzZXJ2ZXIgc2lkZSBhbmQgaXMgc3RvcmVkLgoKDgoHBAUEAAIN
ARIDfQQOCg4KBwQFBAACDQISA30REwpaCgYEBQQAAg4SBIABBBUaSiBUaGUgYXR0YWNrIGlz
IGEgU2FtZS1PcmlnaW4gTWV0aG9kIEV4ZWN1dGlvbiBhdHRhY2sgdmlhIGEgR0VUIHBhcmFt
ZXRlci4KCg8KBwQFBAACDgESBIABBA8KDwoHBAUEAAIOAhIEgAESFAptCgYEBQQAAg8SBIQB
BB8aXSBUaGUgYXR0YWNrIHBheWxvYWQgaXMgcmVjZWl2ZWQgZnJvbSBhIHRoaXJkLXBhcnR5
IGhvc3QgdmlhIGEgVVJMIHRoYXQgaXMKIHVzZXItY29udHJvbGxhYmxlCgoPCgcEBQQAAg8B
EgSEAQQZCg8KBwQFBAACDwISBIQBHB4KSQoEBAUCABIEiAECIxo7IFN0YWNrIHRyYWNlcyBs
ZWFkaW5nIHRvIHRoZSBwb2ludCB3aGVyZSB0aGUgWFNTIG9jY3VycmVkLgoKDQoFBAUCAAQS
BIgBAgoKDQoFBAUCAAUSBIgBCxEKDQoFBAUCAAESBIgBEh4KDQoFBAUCAAMSBIgBISIKRAoE
BAUCARIEiwECGxo2IEFuIGVycm9yIG1lc3NhZ2UgZ2VuZXJhdGVkIGJ5IGEgamF2YXNjcmlw
dCBicmVha2FnZS4KCg0KBQQFAgEFEgSLAQIICg0KBQQFAgEBEgSLAQkWCg0KBQQFAgEDEgSL
ARkaCkUKBAQFAgISBI4BAiEaNyBUaGUgYXR0YWNrIHZlY3RvciBvZiB0aGUgcGF5bG9hZCB0
cmlnZ2VyaW5nIHRoaXMgWFNTLgoKDQoFBAUCAgYSBI4BAg4KDQoFBAUCAgESBI4BDxwKDQoF
BAUCAgMSBI4BHyAKUgoEBAUCAxIEkQECJBpEIFRoZSByZXByb2R1Y3Rpb24gdXJsIGZvciB0
aGUgc2VlZGluZyBQT1NUIHJlcXVlc3Qgb2YgYSBTdG9yZWQgWFNTLgoKDQoFBAUCAwUSBJEB
AggKDQoFBAUCAwESBJEBCR8KDQoFBAUCAwMSBJEBIiMKMAoCBAYSBpUBAKUBARoiIEluZm9y
bWF0aW9uIHJlcG9ydGVkIGZvciBhbiBYWEUuCgoLCgMEBgESBJUBCAsKRwoEBAYEABIGlwEC
nQEDGjcgTG9jYXRpb25zIHdpdGhpbiBhIHJlcXVlc3Qgd2hlcmUgWE1MIHdhcyBzdWJzdGl0
dXRlZC4KCg0KBQQGBAABEgSXAQcPCiMKBgQGBAACABIEmQEEHRoTIFVua25vd24gTG9jYXRp
b24uCgoPCgcEBgQAAgABEgSZAQQYCg8KBwQGBAACAAISBJkBGxwKRQoGBAYEAAIBEgScAQQe
GjUgVGhlIFhNTCBwYXlsb2FkIHJlcGxhY2VkIHRoZSBjb21wbGV0ZSByZXF1ZXN0IGJvZHku
CgoPCgcEBgQAAgEBEgScAQQZCg8KBwQGBAACAQISBJwBHB0KawoEBAYCABIEoQECGxpdIFRo
ZSBYTUwgc3RyaW5nIHRoYXQgdHJpZ2dlcmVkIHRoZSBYWEUgdnVsbmVyYWJpbGl0eS4gTm9u
LXBheWxvYWQgdmFsdWVzCiBtaWdodCBiZSByZWRhY3RlZC4KCg0KBQQGAgAFEgShAQIICg0K
BQQGAgABEgShAQkWCg0KBQQGAgADEgShARkaCkkKBAQGAgESBKQBAiAaOyBMb2NhdGlvbiB3
aXRoaW4gdGhlIHJlcXVlc3Qgd2hlcmUgdGhlIHBheWxvYWQgd2FzIHBsYWNlZC4KCg0KBQQG
AgEGEgSkAQIKCg0KBQQGAgEBEgSkAQsbCg0KBQQGAgEDEgSkAR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::Form ===
    # Fields for Form
    # Field: action_uri Type: 9 ()
    # Field: fields Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::OutdatedLibrary ===
    # Fields for OutdatedLibrary
    # Field: library_name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: learn_more_urls Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::ViolatingResource ===
    # Fields for ViolatingResource
    # Field: content_type Type: 9 ()
    # Field: resource_url Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableParameters ===
    # Fields for VulnerableParameters
    # Field: parameter_names Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders ===
    # Fields for VulnerableHeaders
    # Field: headers Type: 11 (.google.cloud.websecurityscanner.v1.VulnerableHeaders.Header)
    # Field: missing_headers Type: 11 (.google.cloud.websecurityscanner.v1.VulnerableHeaders.Header)

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::Xss ===
    # Fields for Xss
    # Field: stack_traces Type: 9 ()
    # Field: error_message Type: 9 ()
    # Field: attack_vector Type: 14 (.google.cloud.websecurityscanner.v1.Xss.AttackVector)
    # Field: stored_xss_seeding_url Type: 9 ()

# Enum: Xss::AttackVector
our $Xss_ATTACK_VECTOR_UNSPECIFIED = 0;
our $Xss_LOCAL_STORAGE = 1;
our $Xss_SESSION_STORAGE = 2;
our $Xss_WINDOW_NAME = 3;
our $Xss_REFERRER = 4;
our $Xss_FORM_INPUT = 5;
our $Xss_COOKIE = 6;
our $Xss_POST_MESSAGE = 7;
our $Xss_GET_PARAMETERS = 8;
our $Xss_URL_FRAGMENT = 9;
our $Xss_HTML_COMMENT = 10;
our $Xss_POST_PARAMETERS = 11;
our $Xss_PROTOCOL = 12;
our $Xss_STORED_XSS = 13;
our $Xss_SAME_ORIGIN = 14;
our $Xss_USER_CONTROLLABLE_URL = 15;

# === Message: Google::Cloud::Websecurityscanner::V1::FindingAddon::Xxe ===
    # Fields for Xxe
    # Field: payload_value Type: 9 ()
    # Field: payload_location Type: 14 (.google.cloud.websecurityscanner.v1.Xxe.Location)

# Enum: Xxe::Location
our $Xxe_LOCATION_UNSPECIFIED = 0;
our $Xxe_COMPLETE_REQUEST_BODY = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::FindingAddon - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/finding_addon.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::FindingAddon;

    my $msg = Google::Cloud::Websecurityscanner::V1::FindingAddon::Form->new({
        action_uri => $action_uri,
        fields => $fields,
    });

    # Read or update a field
    my $val = $msg->action_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::FindingAddon::Form->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/finding_addon.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::Form

! Information about a vulnerability with an HTML.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action_uri() >> / C<< $msg->action_uri($value) >>

Type: C<String>

! The URI where to send the form when it's submitted.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<String>

! The names of form fields related to the vulnerability.

=back

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::OutdatedLibrary

Information reported for an outdated library.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->library_name() >> / C<< $msg->library_name($value) >>

Type: C<String>

The name of the outdated library.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version number.

=item * C<< $msg->learn_more_urls() >> / C<< $msg->learn_more_urls($value) >>

Type: C<String>

URLs to learn more information about the vulnerabilities in the library.

=back

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::ViolatingResource

Information regarding any resource causing the vulnerability such
as JavaScript sources, image, audio files, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content_type() >> / C<< $msg->content_type($value) >>

Type: C<String>

The MIME type of this resource.

=item * C<< $msg->resource_url() >> / C<< $msg->resource_url($value) >>

Type: C<String>

URL of this violating resource.

=back

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableParameters

Information about vulnerable request parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameter_names() >> / C<< $msg->parameter_names($value) >>

Type: C<String>

The vulnerable parameter names.

=back

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders

Information about vulnerable or missing HTTP Headers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders::Header>)

List of vulnerable headers.

=item * C<< $msg->missing_headers() >> / C<< $msg->missing_headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders::Header>)

List of missing headers.

=back

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::Xss

Information reported for an XSS.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stack_traces() >> / C<< $msg->stack_traces($value) >>

Type: C<String>

Stack traces leading to the point where the XSS occurred.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

An error message generated by a javascript breakage.

=item * C<< $msg->attack_vector() >> / C<< $msg->attack_vector($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::Xss::AttackVector>)

The attack vector of the payload triggering this XSS.

=item * C<< $msg->stored_xss_seeding_url() >> / C<< $msg->stored_xss_seeding_url($value) >>

Type: C<String>

The reproduction url for the seeding POST request of a Stored XSS.

=back

=head3 Enum: Xss::AttackVector

=over 4

=item * C<ATTACK_VECTOR_UNSPECIFIED> => C<0>

=item * C<LOCAL_STORAGE> => C<1>

=item * C<SESSION_STORAGE> => C<2>

=item * C<WINDOW_NAME> => C<3>

=item * C<REFERRER> => C<4>

=item * C<FORM_INPUT> => C<5>

=item * C<COOKIE> => C<6>

=item * C<POST_MESSAGE> => C<7>

=item * C<GET_PARAMETERS> => C<8>

=item * C<URL_FRAGMENT> => C<9>

=item * C<HTML_COMMENT> => C<10>

=item * C<POST_PARAMETERS> => C<11>

=item * C<PROTOCOL> => C<12>

=item * C<STORED_XSS> => C<13>

=item * C<SAME_ORIGIN> => C<14>

=item * C<USER_CONTROLLABLE_URL> => C<15>

=back

=head2 Google::Cloud::Websecurityscanner::V1::FindingAddon::Xxe

Information reported for an XXE.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payload_value() >> / C<< $msg->payload_value($value) >>

Type: C<String>

The XML string that triggered the XXE vulnerability. Non-payload values
might be redacted.

=item * C<< $msg->payload_location() >> / C<< $msg->payload_location($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::Xxe::Location>)

Location within the request where the payload was placed.

=back

=head3 Enum: Xxe::Location

=over 4

=item * C<LOCATION_UNSPECIFIED> => C<0>

=item * C<COMPLETE_REQUEST_BODY> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::FindingAddon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
