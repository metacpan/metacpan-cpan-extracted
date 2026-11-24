package Google::Cloud::Documentai::V1beta3::DocumentIo;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Documentai::V1beta3::Document };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL2RvY3VtZW50X2lvLnByb3RvEh9n
b29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzGi5nb29nbGUvY2xvdWQvZG9jdW1lbnRh
aS92MWJldGEzL2RvY3VtZW50LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5w
cm90byJUCglEb2N1bWVudHMSRwoJZG9jdW1lbnRzGAEgAygLMikuZ29vZ2xlLmNsb3VkLmRv
Y3VtZW50YWkudjFiZXRhMy5Eb2N1bWVudFIJZG9jdW1lbnRzImcKC1Jhd0RvY3VtZW50EhgK
B2NvbnRlbnQYASABKAxSB2NvbnRlbnQSGwoJbWltZV90eXBlGAIgASgJUghtaW1lVHlwZRIh
CgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lIkMKC0djc0RvY3VtZW50EhcKB2dj
c191cmkYASABKAlSBmdjc1VyaRIbCgltaW1lX3R5cGUYAiABKAlSCG1pbWVUeXBlIloKDEdj
c0RvY3VtZW50cxJKCglkb2N1bWVudHMYASADKAsyLC5nb29nbGUuY2xvdWQuZG9jdW1lbnRh
aS52MWJldGEzLkdjc0RvY3VtZW50Uglkb2N1bWVudHMiMQoJR2NzUHJlZml4EiQKDmdjc191
cmlfcHJlZml4GAEgASgJUgxnY3NVcmlQcmVmaXgiWgoMUmF3RG9jdW1lbnRzEkoKCWRvY3Vt
ZW50cxgBIAMoCzIsLmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuUmF3RG9jdW1l
bnRSCWRvY3VtZW50cyLIAQoZQmF0Y2hEb2N1bWVudHNJbnB1dENvbmZpZxJLCgpnY3NfcHJl
Zml4GAEgASgLMiouZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5HY3NQcmVmaXhI
AFIJZ2NzUHJlZml4ElQKDWdjc19kb2N1bWVudHMYAiABKAsyLS5nb29nbGUuY2xvdWQuZG9j
dW1lbnRhaS52MWJldGEzLkdjc0RvY3VtZW50c0gAUgxnY3NEb2N1bWVudHNCCAoGc291cmNl
IuADChREb2N1bWVudE91dHB1dENvbmZpZxJzChFnY3Nfb3V0cHV0X2NvbmZpZxgBIAEoCzJF
Lmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuRG9jdW1lbnRPdXRwdXRDb25maWcu
R2NzT3V0cHV0Q29uZmlnSABSD2djc091dHB1dENvbmZpZxrDAgoPR2NzT3V0cHV0Q29uZmln
EhcKB2djc191cmkYASABKAlSBmdjc1VyaRI5CgpmaWVsZF9tYXNrGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLkZpZWxkTWFza1IJZmllbGRNYXNrEn0KD3NoYXJkaW5nX2NvbmZpZxgDIAEo
CzJULmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuRG9jdW1lbnRPdXRwdXRDb25m
aWcuR2NzT3V0cHV0Q29uZmlnLlNoYXJkaW5nQ29uZmlnUg5zaGFyZGluZ0NvbmZpZxpdCg5T
aGFyZGluZ0NvbmZpZxImCg9wYWdlc19wZXJfc2hhcmQYASABKAVSDXBhZ2VzUGVyU2hhcmQS
IwoNcGFnZXNfb3ZlcmxhcBgCIAEoBVIMcGFnZXNPdmVybGFwQg0KC2Rlc3RpbmF0aW9uIukF
CglPY3JDb25maWcSRgoFaGludHMYAiABKAsyMC5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52
MWJldGEzLk9jckNvbmZpZy5IaW50c1IFaGludHMSOQoZZW5hYmxlX25hdGl2ZV9wZGZfcGFy
c2luZxgDIAEoCFIWZW5hYmxlTmF0aXZlUGRmUGFyc2luZxI9ChtlbmFibGVfaW1hZ2VfcXVh
bGl0eV9zY29yZXMYBCABKAhSGGVuYWJsZUltYWdlUXVhbGl0eVNjb3JlcxIwChRhZHZhbmNl
ZF9vY3Jfb3B0aW9ucxgFIAMoCVISYWR2YW5jZWRPY3JPcHRpb25zEiMKDWVuYWJsZV9zeW1i
b2wYBiABKAhSDGVuYWJsZVN5bWJvbBIwChJjb21wdXRlX3N0eWxlX2luZm8YCCABKAhCAhgB
UhBjb21wdXRlU3R5bGVJbmZvEkkKIWRpc2FibGVfY2hhcmFjdGVyX2JveGVzX2RldGVjdGlv
bhgKIAEoCFIeZGlzYWJsZUNoYXJhY3RlckJveGVzRGV0ZWN0aW9uEmUKEHByZW1pdW1fZmVh
dHVyZXMYCyABKAsyOi5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLk9jckNvbmZp
Zy5QcmVtaXVtRmVhdHVyZXNSD3ByZW1pdW1GZWF0dXJlcxouCgVIaW50cxIlCg5sYW5ndWFn
ZV9oaW50cxgBIAMoCVINbGFuZ3VhZ2VIaW50cxquAQoPUHJlbWl1bUZlYXR1cmVzEkUKH2Vu
YWJsZV9zZWxlY3Rpb25fbWFya19kZXRlY3Rpb24YAyABKAhSHGVuYWJsZVNlbGVjdGlvbk1h
cmtEZXRlY3Rpb24SLAoSY29tcHV0ZV9zdHlsZV9pbmZvGAQgASgIUhBjb21wdXRlU3R5bGVJ
bmZvEiYKD2VuYWJsZV9tYXRoX29jchgFIAEoCFINZW5hYmxlTWF0aE9jckLmAQojY29tLmdv
b2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTNCD0RvY3VtZW50SW9Qcm90b1ABWkNjbG91
ZC5nb29nbGUuY29tL2dvL2RvY3VtZW50YWkvYXBpdjFiZXRhMy9kb2N1bWVudGFpcGI7ZG9j
dW1lbnRhaXBiqgIfR29vZ2xlLkNsb3VkLkRvY3VtZW50QUkuVjFCZXRhM8oCH0dvb2dsZVxD
bG91ZFxEb2N1bWVudEFJXFYxYmV0YTPqAiJHb29nbGU6OkNsb3VkOjpEb2N1bWVudEFJOjpW
MWJldGEzSvE0CgcSBQ4AuwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAoCgkKAgMAEgMSADgKCQoCAwESAxMAKgoICgEIEgMVADwKCQoCCCUSAxUAPAoI
CgEIEgMWAFoKCQoCCAsSAxYAWgoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoC
CAgSAxgAMAoICgEIEgMZADwKCQoCCAESAxkAPAoICgEIEgMaADwKCQoCCCkSAxoAPAoICgEI
EgMbADsKCQoCCC0SAxsAOwooCgIEABIEHgAhARocIEEgc2V0IG9mIGlubGluZSBkb2N1bWVu
dHMuCgoKCgMEAAESAx4IEQolCgQEAAIAEgMgAiIaGCBUaGUgbGlzdCBvZiBkb2N1bWVudHMu
CgoMCgUEAAIABBIDIAIKCgwKBQQAAgAGEgMgCxMKDAoFBAACAAESAyAUHQoMCgUEAAIAAxID
ICAhCj4KAgQBEgQkADIBGjIgUGF5bG9hZCBtZXNzYWdlIG9mIHJhdyBkb2N1bWVudCBjb250
ZW50IChieXRlcykuCgoKCgMEAQESAyQIEwonCgQEAQIAEgMmAhQaGiBJbmxpbmUgZG9jdW1l
bnQgY29udGVudC4KCgwKBQQBAgAFEgMmAgcKDAoFBAECAAESAyYIDwoMCgUEAQIAAxIDJhIT
CpQBCgQEAQIBEgMqAhcahgEgQW4gSUFOQSBNSU1FIHR5cGUgKFJGQzY4MzgpIGluZGljYXRp
bmcgdGhlIG5hdHVyZSBhbmQgZm9ybWF0IG9mIHRoZQogW2NvbnRlbnRdW2dvb2dsZS5jbG91
ZC5kb2N1bWVudGFpLnYxYmV0YTMuUmF3RG9jdW1lbnQuY29udGVudF0uCgoMCgUEAQIBBRID
KgIICgwKBQQBAgEBEgMqCRIKDAoFBAECAQMSAyoVFgrrAQoEBAECAhIDMQIaGt0BIFRoZSBk
aXNwbGF5IG5hbWUgb2YgdGhlIGRvY3VtZW50LCBpdCBzdXBwb3J0cyBhbGwgVW5pY29kZSBj
aGFyYWN0ZXJzIGV4Y2VwdAogdGhlIGZvbGxvd2luZzoKIGAqYCwgYD9gLCBgW2AsIGBdYCwg
YCVgLCBge2AsIGB9YCxgJ2AsIGBcImAsIGAsYAogYH5gLCBgPWAgYW5kIGA6YCBhcmUgcmVz
ZXJ2ZWQuCiBJZiBub3Qgc3BlY2lmaWVkLCBhIGRlZmF1bHQgSUQgaXMgZ2VuZXJhdGVkLgoK
DAoFBAECAgUSAzECCAoMCgUEAQICARIDMQkVCgwKBQQBAgIDEgMxGBkKOwoCBAISBDUAOwEa
LyBTcGVjaWZpZXMgYSBkb2N1bWVudCBzdG9yZWQgb24gQ2xvdWQgU3RvcmFnZS4KCgoKAwQC
ARIDNQgTCiwKBAQCAgASAzcCFRofIFRoZSBDbG91ZCBTdG9yYWdlIG9iamVjdCB1cmkuCgoM
CgUEAgIABRIDNwIICgwKBQQCAgABEgM3CRAKDAoFBAICAAMSAzcTFAo6CgQEAgIBEgM6Ahca
LSBBbiBJQU5BIE1JTUUgdHlwZSAoUkZDNjgzOCkgb2YgdGhlIGNvbnRlbnQuCgoMCgUEAgIB
BRIDOgIICgwKBQQCAgEBEgM6CRIKDAoFBAICAQMSAzoVFgo8CgIEAxIEPgBBARowIFNwZWNp
ZmllcyBhIHNldCBvZiBkb2N1bWVudHMgb24gQ2xvdWQgU3RvcmFnZS4KCgoKAwQDARIDPggU
CiUKBAQDAgASA0ACJRoYIFRoZSBsaXN0IG9mIGRvY3VtZW50cy4KCgwKBQQDAgAEEgNAAgoK
DAoFBAMCAAYSA0ALFgoMCgUEAwIAARIDQBcgCgwKBQQDAgADEgNAIyQKTAoCBAQSBEQARwEa
QCBTcGVjaWZpZXMgYWxsIGRvY3VtZW50cyBvbiBDbG91ZCBTdG9yYWdlIHdpdGggYSBjb21t
b24gcHJlZml4LgoKCgoDBAQBEgNECBEKHgoEBAQCABIDRgIcGhEgVGhlIFVSSSBwcmVmaXgu
CgoMCgUEBAIABRIDRgIICgwKBQQEAgABEgNGCRcKDAoFBAQCAAMSA0YaGwovCgIEBRIESgBN
ARojIFNwZWNpZmllcyBhIHNldCBvZiByYXcgZG9jdW1lbnRzLgoKCgoDBAUBEgNKCBQKPAoE
BAUCABIDTAIlGi8gU3BlY2lmaWVzIHJhdyBkb2N1bWVudCBjb250ZW50IGFuZCBtaW1lIHR5
cGUuCgoMCgUEBQIABBIDTAIKCgwKBQQFAgAGEgNMCxYKDAoFBAUCAAESA0wXIAoMCgUEBQIA
AxIDTCMkCkwKAgQGEgRQAFoBGkAgVGhlIGNvbW1vbiBjb25maWcgdG8gc3BlY2lmeSBhIHNl
dCBvZiBkb2N1bWVudHMgdXNlZCBhcyBpbnB1dC4KCgoKAwQGARIDUAghCnAKBAQGCAASBFMC
WQMaYiBUaGUgc291cmNlLiBNYWtlIHN1cmUgdGhhdCB0aGUgY2FsbGVyIG9mIHRoZSBBUEkg
aGFzIHN0b3JhZ2Uub2JqZWN0cy5nZXQKIGFjY2VzcyB0byB0aGUgYnVja2V0cy4KCgwKBQQG
CAABEgNTCA4KWAoEBAYCABIDVQQdGksgVGhlIHNldCBvZiBkb2N1bWVudHMgdGhhdCBtYXRj
aCB0aGUgc3BlY2lmaWVkIENsb3VkIFN0b3JhZ2UgYGdjc19wcmVmaXhgLgoKDAoFBAYCAAYS
A1UEDQoMCgUEBgIAARIDVQ4YCgwKBQQGAgADEgNVGxwKTAoEBAYCARIDWAQjGj8gVGhlIHNl
dCBvZiBkb2N1bWVudHMgaW5kaXZpZHVhbGx5IHNwZWNpZmllZCBvbiBDbG91ZCBTdG9yYWdl
LgoKDAoFBAYCAQYSA1gEEAoMCgUEBgIBARIDWBEeCgwKBQQGAgEDEgNYISIKagoCBAcSBF4A
ewEaXiBDb25maWcgdGhhdCBjb250cm9scyB0aGUgb3V0cHV0IG9mIGRvY3VtZW50cy4gQWxs
IGRvY3VtZW50cyB3aWxsIGJlIHdyaXR0ZW4KIGFzIGEgSlNPTiBmaWxlLgoKCgoDBAcBEgNe
CBwKQQoEBAcDABIEYAJ0AxozIFRoZSBjb25maWd1cmF0aW9uIHVzZWQgd2hlbiBvdXRwdXR0
aW5nIGRvY3VtZW50cy4KCgwKBQQHAwABEgNgChkKPgoGBAcDAAMAEgRiBGgFGi4gVGhlIHNo
YXJkaW5nIGNvbmZpZyBmb3IgdGhlIG91dHB1dCBkb2N1bWVudC4KCg4KBwQHAwADAAESA2IM
GgoxCggEBwMAAwACABIDZAYgGiAgVGhlIG51bWJlciBvZiBwYWdlcyBwZXIgc2hhcmQuCgoQ
CgkEBwMAAwACAAUSA2QGCwoQCgkEBwMAAwACAAESA2QMGwoQCgkEBwMAAwACAAMSA2QeHwpO
CggEBwMAAwACARIDZwYeGj0gVGhlIG51bWJlciBvZiBvdmVybGFwcGluZyBwYWdlcyBiZXR3
ZWVuIGNvbnNlY3V0aXZlIHNoYXJkcy4KChAKCQQHAwADAAIBBRIDZwYLChAKCQQHAwADAAIB
ARIDZwwZChAKCQQHAwADAAIBAxIDZxwdCkMKBgQHAwACABIDawQXGjQgVGhlIENsb3VkIFN0
b3JhZ2UgdXJpIChhIGRpcmVjdG9yeSkgb2YgdGhlIG91dHB1dC4KCg4KBwQHAwACAAUSA2sE
CgoOCgcEBwMAAgABEgNrCxIKDgoHBAcDAAIAAxIDaxUWCtIBCgYEBwMAAgESA3AELRrCASBT
cGVjaWZpZXMgd2hpY2ggZmllbGRzIHRvIGluY2x1ZGUgaW4gdGhlIG91dHB1dCBkb2N1bWVu
dHMuCiBPbmx5IHN1cHBvcnRzIHRvcCBsZXZlbCBkb2N1bWVudCBhbmQgcGFnZXMgZmllbGQg
c28gaXQgbXVzdCBiZSBpbiB0aGUKIGZvcm0gb2YgYHtkb2N1bWVudF9maWVsZF9uYW1lfWAg
b3IgYHBhZ2VzLntwYWdlX2ZpZWxkX25hbWV9YC4KCg4KBwQHAwACAQYSA3AEHQoOCgcEBwMA
AgEBEgNwHigKDgoHBAcDAAIBAxIDcCssCkcKBgQHAwACAhIDcwQnGjggU3BlY2lmaWVzIHRo
ZSBzaGFyZGluZyBjb25maWcgZm9yIHRoZSBvdXRwdXQgZG9jdW1lbnQuCgoOCgcEBwMAAgIG
EgNzBBIKDgoHBAcDAAICARIDcxMiCg4KBwQHAwACAgMSA3MlJgovCgQEBwgAEgR3AnoDGiEg
VGhlIGRlc3RpbmF0aW9uIG9mIHRoZSByZXN1bHRzLgoKDAoFBAcIAAESA3cIEwpDCgQEBwIA
EgN5BCoaNiBPdXRwdXQgY29uZmlnIHRvIHdyaXRlIHRoZSByZXN1bHRzIHRvIENsb3VkIFN0
b3JhZ2UuCgoMCgUEBwIABhIDeQQTCgwKBQQHAgABEgN5FCUKDAoFBAcCAAMSA3koKQonCgIE
CBIFfgC7AQEaGiBDb25maWcgZm9yIERvY3VtZW50IE9DUi4KCgoKAwQIARIDfggRCiYKBAQI
AwASBoABAogBAxoWIEhpbnRzIGZvciBPQ1IgRW5naW5lCgoNCgUECAMAARIEgAEKDwqpAwoG
BAgDAAIAEgSHAQQnGpgDIExpc3Qgb2YgQkNQLTQ3IGxhbmd1YWdlIGNvZGVzIHRvIHVzZSBm
b3IgT0NSLiBJbiBtb3N0IGNhc2VzLCBub3QKIHNwZWNpZnlpbmcgaXQgeWllbGRzIHRoZSBi
ZXN0IHJlc3VsdHMgc2luY2UgaXQgZW5hYmxlcyBhdXRvbWF0aWMgbGFuZ3VhZ2UKIGRldGVj
dGlvbi4gRm9yIGxhbmd1YWdlcyBiYXNlZCBvbiB0aGUgTGF0aW4gYWxwaGFiZXQsIHNldHRp
bmcgaGludHMgaXMKIG5vdCBuZWVkZWQuIEluIHJhcmUgY2FzZXMsIHdoZW4gdGhlIGxhbmd1
YWdlIG9mIHRoZSB0ZXh0IGluIHRoZQogaW1hZ2UgaXMga25vd24sIHNldHRpbmcgYSBoaW50
IHdpbGwgaGVscCBnZXQgYmV0dGVyIHJlc3VsdHMgKGFsdGhvdWdoIGl0CiB3aWxsIGJlIGEg
c2lnbmlmaWNhbnQgaGluZHJhbmNlIGlmIHRoZSBoaW50IGlzIHdyb25nKS4KCg8KBwQIAwAC
AAQSBIcBBAwKDwoHBAgDAAIABRIEhwENEwoPCgcECAMAAgABEgSHARQiCg8KBwQIAwACAAMS
BIcBJSYKOgoEBAgDARIGiwEClQEDGiogQ29uZmlndXJhdGlvbnMgZm9yIHByZW1pdW0gT0NS
IGZlYXR1cmVzLgoKDQoFBAgDAQESBIsBChkKcwoGBAgDAQIAEgSOAQQtGmMgVHVybiBvbiBz
ZWxlY3Rpb24gbWFyayBkZXRlY3RvciBpbiBPQ1IgZW5naW5lLiBPbmx5IGF2YWlsYWJsZSBp
biBPQ1IgMi4wCiAoYW5kIGxhdGVyKSBwcm9jZXNzb3JzLgoKDwoHBAgDAQIABRIEjgEECAoP
CgcECAMBAgABEgSOAQkoCg8KBwQIAwECAAMSBI4BKywKVgoGBAgDAQIBEgSRAQQgGkYgVHVy
biBvbiBmb250IGlkZW50aWZpY2F0aW9uIG1vZGVsIGFuZCByZXR1cm4gZm9udCBzdHlsZSBp
bmZvcm1hdGlvbi4KCg8KBwQIAwECAQUSBJEBBAgKDwoHBAgDAQIBARIEkQEJGwoPCgcECAMB
AgEDEgSRAR4fCkkKBgQIAwECAhIElAEEHRo5IFR1cm4gb24gdGhlIG1vZGVsIHRoYXQgY2Fu
IGV4dHJhY3QgTGFUZVggbWF0aCBmb3JtdWxhcy4KCg8KBwQIAwECAgUSBJQBBAgKDwoHBAgD
AQICARIElAEJGAoPCgcECAMBAgIDEgSUARscCigKBAQIAgASBJgBAhIaGiBIaW50cyBmb3Ig
dGhlIE9DUiBtb2RlbC4KCg0KBQQIAgAGEgSYAQIHCg0KBQQIAgABEgSYAQgNCg0KBQQIAgAD
EgSYARARCpEBCgQECAIBEgScAQIlGoIBIEVuYWJsZXMgc3BlY2lhbCBoYW5kbGluZyBmb3Ig
UERGcyB3aXRoIGV4aXN0aW5nIHRleHQgaW5mb3JtYXRpb24uIFJlc3VsdHMKIGluIGJldHRl
ciB0ZXh0IGV4dHJhY3Rpb24gcXVhbGl0eSBpbiBzdWNoIFBERiBpbnB1dHMuCgoNCgUECAIB
BRIEnAECBgoNCgUECAIBARIEnAEHIAoNCgUECAIBAxIEnAEjJAriAQoEBAgCAhIEoQECJxrT
ASBFbmFibGVzIGludGVsbGlnZW50IGRvY3VtZW50IHF1YWxpdHkgc2NvcmVzIGFmdGVyIE9D
Ui4gQ2FuIGhlbHAgd2l0aAogZGlhZ25vc2luZyB3aHkgT0NSIHJlc3BvbnNlcyBhcmUgb2Yg
cG9vciBxdWFsaXR5IGZvciBhIGdpdmVuIGlucHV0LgogQWRkcyBhZGRpdGlvbmFsIGxhdGVu
Y3kgY29tcGFyYWJsZSB0byByZWd1bGFyIE9DUiB0byB0aGUgcHJvY2VzcyBjYWxsLgoKDQoF
BAgCAgUSBKEBAgYKDQoFBAgCAgESBKEBByIKDQoFBAgCAgMSBKEBJSYK0wIKBAQIAgMSBKoB
AisaxAIgQSBsaXN0IG9mIGFkdmFuY2VkIE9DUiBvcHRpb25zIHRvIGZ1cnRoZXIgZmluZS10
dW5lIE9DUiBiZWhhdmlvci4gQ3VycmVudAogdmFsaWQgdmFsdWVzIGFyZToKCiAtIGBsZWdh
Y3lfbGF5b3V0YDogYSBoZXVyaXN0aWNzIGxheW91dCBkZXRlY3Rpb24gYWxnb3JpdGhtLCB3
aGljaCBzZXJ2ZXMgYXMKIGFuIGFsdGVybmF0aXZlIHRvIHRoZSBjdXJyZW50IE1MLWJhc2Vk
IGxheW91dCBkZXRlY3Rpb24gYWxnb3JpdGhtLgogQ3VzdG9tZXJzIGNhbiBjaG9vc2UgdGhl
IGJlc3Qgc3VpdGFibGUgbGF5b3V0IGFsZ29yaXRobSBiYXNlZCBvbiB0aGVpcgogc2l0dWF0
aW9uLgoKDQoFBAgCAwQSBKoBAgoKDQoFBAgCAwUSBKoBCxEKDQoFBAgCAwESBKoBEiYKDQoF
BAgCAwMSBKoBKSoKRQoEBAgCBBIErQECGRo3IEluY2x1ZGVzIHN5bWJvbCBsZXZlbCBPQ1Ig
aW5mb3JtYXRpb24gaWYgc2V0IHRvIHRydWUuCgoNCgUECAIEBRIErQECBgoNCgUECAIEARIE
rQEHFAoNCgUECAIEAxIErQEXGArkAQoEBAgCBRIEswECMhrVASBUdXJuIG9uIGZvbnQgaWRl
bnRpZmljYXRpb24gbW9kZWwgYW5kIHJldHVybiBmb250IHN0eWxlIGluZm9ybWF0aW9uLgog
RGVwcmVjYXRlZCwgdXNlCiBbUHJlbWl1bUZlYXR1cmVzLmNvbXB1dGVfc3R5bGVfaW5mb11b
Z29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5PY3JDb25maWcuUHJlbWl1bUZlYXR1
cmVzLmNvbXB1dGVfc3R5bGVfaW5mb10KIGluc3RlYWQuCgoNCgUECAIFBRIEswECBgoNCgUE
CAIFARIEswEHGQoNCgUECAIFAxIEswEcHQoNCgUECAIFCBIEswEeMQoOCgYECAIFCAMSBLMB
HzAKkQEKBAQIAgYSBLcBAi4aggEgVHVybiBvZmYgY2hhcmFjdGVyIGJveCBkZXRlY3RvciBp
biBPQ1IgZW5naW5lLiBDaGFyYWN0ZXIgYm94IGRldGVjdGlvbiBpcwogZW5hYmxlZCBieSBk
ZWZhdWx0IGluIE9DUiAyLjAgKGFuZCBsYXRlcikgcHJvY2Vzc29ycy4KCg0KBQQIAgYFEgS3
AQIGCg0KBQQIAgYBEgS3AQcoCg0KBQQIAgYDEgS3ASstCjgKBAQIAgcSBLoBAigaKiBDb25m
aWd1cmF0aW9ucyBmb3IgcHJlbWl1bSBPQ1IgZmVhdHVyZXMuCgoNCgUECAIHBhIEugECEQoN
CgUECAIHARIEugESIgoNCgUECAIHAxIEugElJ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::Documents ===
    # Fields for Documents
    # Field: documents Type: 11 (.google.cloud.documentai.v1beta3.Document)

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocument ===
    # Fields for RawDocument
    # Field: content Type: 12 ()
    # Field: mime_type Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocument ===
    # Fields for GcsDocument
    # Field: gcs_uri Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocuments ===
    # Fields for GcsDocuments
    # Field: documents Type: 11 (.google.cloud.documentai.v1beta3.GcsDocument)

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::GcsPrefix ===
    # Fields for GcsPrefix
    # Field: gcs_uri_prefix Type: 9 ()

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocuments ===
    # Fields for RawDocuments
    # Field: documents Type: 11 (.google.cloud.documentai.v1beta3.RawDocument)

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::BatchDocumentsInputConfig ===
    # Fields for BatchDocumentsInputConfig
    # Field: gcs_prefix Type: 11 (.google.cloud.documentai.v1beta3.GcsPrefix)
    # Field: gcs_documents Type: 11 (.google.cloud.documentai.v1beta3.GcsDocuments)

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig ===
    # Fields for DocumentOutputConfig
    # Field: gcs_output_config Type: 11 (.google.cloud.documentai.v1beta3.DocumentOutputConfig.GcsOutputConfig)

# === Message: Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig ===
    # Fields for OcrConfig
    # Field: hints Type: 11 (.google.cloud.documentai.v1beta3.OcrConfig.Hints)
    # Field: enable_native_pdf_parsing Type: 8 ()
    # Field: enable_image_quality_scores Type: 8 ()
    # Field: advanced_ocr_options Type: 9 ()
    # Field: enable_symbol Type: 8 ()
    # Field: compute_style_info Type: 8 ()
    # Field: disable_character_boxes_detection Type: 8 ()
    # Field: premium_features Type: 11 (.google.cloud.documentai.v1beta3.OcrConfig.PremiumFeatures)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::DocumentIo - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/document_io.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::DocumentIo;

    my $msg = Google::Cloud::Documentai::V1beta3::DocumentIo::Documents->new({
        documents => $documents,
    });

    # Read or update a field
    my $val = $msg->documents();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::DocumentIo::Documents->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/document_io.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::Documents

A set of inline documents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Document::Document>)

The list of documents.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocument

Payload message of raw document content (bytes).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Bytes>

Inline document content.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

An IANA MIME type (RFC6838) indicating the nature and format of the
[content][google.cloud.documentai.v1beta3.RawDocument.content].

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the document, it supports all Unicode characters except
the following:
`*`, `?`, `[`, `]`, `%`, `{`, `}`,`'`, `\"`, `,`
`~`, `=` and `:` are reserved.
If not specified, a default ID is generated.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocument

Specifies a document stored on Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_uri() >> / C<< $msg->gcs_uri($value) >>

Type: C<String>

The Cloud Storage object uri.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

An IANA MIME type (RFC6838) of the content.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocuments

Specifies a set of documents on Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocument>)

The list of documents.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::GcsPrefix

Specifies all documents on Cloud Storage with a common prefix.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_uri_prefix() >> / C<< $msg->gcs_uri_prefix($value) >>

Type: C<String>

The URI prefix.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocuments

Specifies a set of raw documents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocument>)

Specifies raw document content and mime type.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::BatchDocumentsInputConfig

The common config to specify a set of documents used as input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::GcsPrefix>)

The set of documents that match the specified Cloud Storage `gcs_prefix`.

=item * C<< $msg->gcs_documents() >> / C<< $msg->gcs_documents($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocuments>)

The set of documents individually specified on Cloud Storage.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig

Config that controls the output of documents. All documents will be written
as a JSON file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_output_config() >> / C<< $msg->gcs_output_config($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig>)

Output config to write the results to Cloud Storage.

=back

=head2 Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig

Config for Document OCR.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->hints() >> / C<< $msg->hints($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::Hints>)

Hints for the OCR model.

=item * C<< $msg->enable_native_pdf_parsing() >> / C<< $msg->enable_native_pdf_parsing($value) >>

Type: C<Bool>

Enables special handling for PDFs with existing text information. Results
in better text extraction quality in such PDF inputs.

=item * C<< $msg->enable_image_quality_scores() >> / C<< $msg->enable_image_quality_scores($value) >>

Type: C<Bool>

Enables intelligent document quality scores after OCR. Can help with
diagnosing why OCR responses are of poor quality for a given input.
Adds additional latency comparable to regular OCR to the process call.

=item * C<< $msg->advanced_ocr_options() >> / C<< $msg->advanced_ocr_options($value) >>

Type: C<String>

A list of advanced OCR options to further fine-tune OCR behavior. Current
valid values are:

- `legacy_layout`: a heuristics layout detection algorithm, which serves as
an alternative to the current ML-based layout detection algorithm.
Customers can choose the best suitable layout algorithm based on their
situation.

=item * C<< $msg->enable_symbol() >> / C<< $msg->enable_symbol($value) >>

Type: C<Bool>

Includes symbol level OCR information if set to true.

=item * C<< $msg->compute_style_info() >> / C<< $msg->compute_style_info($value) >>

Type: C<Bool>

Turn on font identification model and return font style information.
Deprecated, use
[PremiumFeatures.compute_style_info][google.cloud.documentai.v1beta3.OcrConfig.PremiumFeatures.compute_style_info]
instead.

=item * C<< $msg->disable_character_boxes_detection() >> / C<< $msg->disable_character_boxes_detection($value) >>

Type: C<Bool>

Turn off character box detector in OCR engine. Character box detection is
enabled by default in OCR 2.0 (and later) processors.

=item * C<< $msg->premium_features() >> / C<< $msg->premium_features($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::PremiumFeatures>)

Configurations for premium OCR features.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::DocumentIo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
