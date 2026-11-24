package Google::Cloud::Eventarc::Publishing::V1::Publisher;

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
    eval { require Google::Api::FieldInfo };
    eval { require Google::Cloud::Eventarc::Publishing::V1::CloudEvent };
    eval { require Google::Protobuf::Any };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZXZlbnRhcmMvcHVibGlzaGluZy92MS9wdWJsaXNoZXIucHJvdG8S
I2dvb2dsZS5jbG91ZC5ldmVudGFyYy5wdWJsaXNoaW5nLnYxGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGjVnb29nbGUv
Y2xvdWQvZXZlbnRhcmMvcHVibGlzaGluZy92MS9jbG91ZF9ldmVudC5wcm90bxoZZ29vZ2xl
L3Byb3RvYnVmL2FueS5wcm90byKlAQolUHVibGlzaENoYW5uZWxDb25uZWN0aW9uRXZlbnRz
UmVxdWVzdBItChJjaGFubmVsX2Nvbm5lY3Rpb24YASABKAlSEWNoYW5uZWxDb25uZWN0aW9u
EiwKBmV2ZW50cxgCIAMoCzIULmdvb2dsZS5wcm90b2J1Zi5BbnlSBmV2ZW50cxIfCgt0ZXh0
X2V2ZW50cxgDIAMoCVIKdGV4dEV2ZW50cyIoCiZQdWJsaXNoQ2hhbm5lbENvbm5lY3Rpb25F
dmVudHNSZXNwb25zZSJ/ChRQdWJsaXNoRXZlbnRzUmVxdWVzdBIYCgdjaGFubmVsGAEgASgJ
UgdjaGFubmVsEiwKBmV2ZW50cxgCIAMoCzIULmdvb2dsZS5wcm90b2J1Zi5BbnlSBmV2ZW50
cxIfCgt0ZXh0X2V2ZW50cxgDIAMoCVIKdGV4dEV2ZW50cyIXChVQdWJsaXNoRXZlbnRzUmVz
cG9uc2Ui4gEKDlB1Ymxpc2hSZXF1ZXN0EiQKC21lc3NhZ2VfYnVzGAEgASgJQgPgQQJSCm1l
c3NhZ2VCdXMSVgoNcHJvdG9fbWVzc2FnZRgCIAEoCzIvLmdvb2dsZS5jbG91ZC5ldmVudGFy
Yy5wdWJsaXNoaW5nLnYxLkNsb3VkRXZlbnRIAFIMcHJvdG9NZXNzYWdlEiMKDGpzb25fbWVz
c2FnZRgDIAEoCUgAUgtqc29uTWVzc2FnZRIjCgxhdnJvX21lc3NhZ2UYBCABKAxIAFILYXZy
b01lc3NhZ2VCCAoGZm9ybWF0IhEKD1B1Ymxpc2hSZXNwb25zZTKTBgoJUHVibGlzaGVyEpgC
Ch5QdWJsaXNoQ2hhbm5lbENvbm5lY3Rpb25FdmVudHMSSi5nb29nbGUuY2xvdWQuZXZlbnRh
cmMucHVibGlzaGluZy52MS5QdWJsaXNoQ2hhbm5lbENvbm5lY3Rpb25FdmVudHNSZXF1ZXN0
GksuZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnB1Ymxpc2hpbmcudjEuUHVibGlzaENoYW5uZWxD
b25uZWN0aW9uRXZlbnRzUmVzcG9uc2UiXYLT5JMCVyJSL3YxL3tjaGFubmVsX2Nvbm5lY3Rp
b249cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jaGFubmVsQ29ubmVjdGlvbnMvKn06cHVibGlz
aEV2ZW50czoBKhLQAQoNUHVibGlzaEV2ZW50cxI5Lmdvb2dsZS5jbG91ZC5ldmVudGFyYy5w
dWJsaXNoaW5nLnYxLlB1Ymxpc2hFdmVudHNSZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLmV2ZW50
YXJjLnB1Ymxpc2hpbmcudjEuUHVibGlzaEV2ZW50c1Jlc3BvbnNlIkiC0+STAkIiPS92MS97
Y2hhbm5lbD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NoYW5uZWxzLyp9OnB1Ymxpc2hFdmVu
dHM6ASoSwAEKB1B1Ymxpc2gSMy5nb29nbGUuY2xvdWQuZXZlbnRhcmMucHVibGlzaGluZy52
MS5QdWJsaXNoUmVxdWVzdBo0Lmdvb2dsZS5jbG91ZC5ldmVudGFyYy5wdWJsaXNoaW5nLnYx
LlB1Ymxpc2hSZXNwb25zZSJKgtPkkwJEIj8vdjEve21lc3NhZ2VfYnVzPXByb2plY3RzLyov
bG9jYXRpb25zLyovbWVzc2FnZUJ1c2VzLyp9OnB1Ymxpc2g6ASoaVcpBIWV2ZW50YXJjcHVi
bGlzaGluZy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm1C+gEKJ2NvbS5nb29nbGUuY2xvdWQuZXZlbnRhcmMucHVibGlz
aGluZy52MUIOUHVibGlzaGVyUHJvdG9QAVpHY2xvdWQuZ29vZ2xlLmNvbS9nby9ldmVudGFy
Yy9wdWJsaXNoaW5nL2FwaXYxL3B1Ymxpc2hpbmdwYjtwdWJsaXNoaW5ncGKqAiNHb29nbGUu
Q2xvdWQuRXZlbnRhcmMuUHVibGlzaGluZy5WMcoCI0dvb2dsZVxDbG91ZFxFdmVudGFyY1xQ
dWJsaXNoaW5nXFYx6gInR29vZ2xlOjpDbG91ZDo6RXZlbnRhcmM6OlB1Ymxpc2hpbmc6OlYx
Sp8sCgcSBQ4AoAEaCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACUKCQoCAwQS
AxYAPwoJCgIDBRIDFwAjCggKAQgSAxkAQAoJCgIIJRIDGQBACggKAQgSAxoAXgoJCgIICxID
GgBeCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwALwoJCgIICBIDHAAvCggKAQgSAx0A
QAoJCgIIARIDHQBACggKAQgSAx4AQQoJCgIIKRIDHgBBCggKAQgSAx8AQAoJCgIILRIDHwBA
CsQKCgIGABIEPgBbARq3CiBFdmVudGFyYyBwcm9jZXNzZXMgZXZlbnRzIGdlbmVyYXRlZCBi
eSBhbiBldmVudCBwcm92aWRlciBhbmQgZGVsaXZlcnMgdGhlbSB0bwogYSBzdWJzY3JpYmVy
LgoKIEFuIGV2ZW50IHByb3ZpZGVyIGlzIGEgc29mdHdhcmUtYXMtYS1zZXJ2aWNlIChTYWFT
KSBzeXN0ZW0gb3IKIHByb2R1Y3QgdGhhdCBjYW4gZ2VuZXJhdGUgYW5kIGRlbGl2ZXIgZXZl
bnRzIHRocm91Z2ggRXZlbnRhcmMuCgogQSB0aGlyZC1wYXJ0eSBldmVudCBwcm92aWRlciBp
cyBhbiBldmVudCBwcm92aWRlciBmcm9tIG91dHNpZGUgb2YgR29vZ2xlLgoKIEEgcGFydG5l
ciBpcyBhIHRoaXJkLXBhcnR5IGV2ZW50IHByb3ZpZGVyIHRoYXQgaXMgaW50ZWdyYXRlZCB3
aXRoIEV2ZW50YXJjLgoKIEEgc3Vic2NyaWJlciBpcyBhIEdvb2dsZSBDbG91ZCBjdXN0b21l
ciBpbnRlcmVzdGVkIGluIHJlY2VpdmluZyBldmVudHMuCgogQ2hhbm5lbCBpcyBhIGZpcnN0
LWNsYXNzIEV2ZW50YXJjIHJlc291cmNlIHRoYXQgaXMgY3JlYXRlZCBhbmQgbWFuYWdlZAog
YnkgdGhlIHN1YnNjcmliZXIgaW4gdGhlaXIgR29vZ2xlIENsb3VkIHByb2plY3QuIEEgQ2hh
bm5lbCByZXByZXNlbnRzIGEKIHN1YnNjcmliZXIncyBpbnRlbnQgdG8gcmVjZWl2ZSBldmVu
dHMgZnJvbSBhbiBldmVudCBwcm92aWRlci4gQSBDaGFubmVsIGlzCiBhc3NvY2lhdGVkIHdp
dGggZXhhY3RseSBvbmUgZXZlbnQgcHJvdmlkZXIuCgogQ2hhbm5lbENvbm5lY3Rpb24gaXMg
YSBmaXJzdC1jbGFzcyBFdmVudGFyYyByZXNvdXJjZSB0aGF0CiBpcyBjcmVhdGVkIGFuZCBt
YW5hZ2VkIGJ5IHRoZSBwYXJ0bmVyIGluIHRoZWlyIEdvb2dsZSBDbG91ZCBwcm9qZWN0LiBB
CiBDaGFubmVsQ29ubmVjdGlvbiByZXByZXNlbnRzIGEgY29ubmVjdGlvbiBiZXR3ZWVuIGEg
cGFydG5lciBhbmQgYQogc3Vic2NyaWJlcidzIENoYW5uZWwuIEEgQ2hhbm5lbENvbm5lY3Rp
b24gaGFzIGEgb25lLXRvLW9uZSBtYXBwaW5nIHdpdGggYQogQ2hhbm5lbC4KCiBCdXMgaXMg
YSBmaXJzdC1jbGFzcyBFdmVudGFyYyByZXNvdXJjZSB0aGF0IGlzIGNyZWF0ZWQgYW5kIG1h
bmFnZWQgaW4gYQogR29vZ2xlIENsb3VkIHByb2plY3QuIEEgQnVzIHByb3ZpZGVzIGEgZGlz
Y292ZXJhYmxlIGVuZHBvaW50IGZvciBldmVudHMgYW5kCiBpcyBhIHJvdXRlciB0aGF0IHJl
Y2VpdmVzIGFsbCBldmVudHMgcHVibGlzaGVkIGJ5IGV2ZW50IHByb3ZpZGVycyBhbmQKIGRl
bGl2ZXJzIHRoZW0gdG8gemVybyBvciBtb3JlIHN1YnNjcmliZXJzLgoKIFB1Ymxpc2hlciBh
bGxvd3MgYW4gZXZlbnQgcHJvdmlkZXIgdG8gcHVibGlzaCBldmVudHMgdG8gRXZlbnRhcmMu
CgoKCgMGAAESAz4IEQoKCgMGAAMSAz8CSQoMCgUGAAOZCBIDPwJJCgsKAwYAAxIEQAJBNwoN
CgUGAAOaCBIEQAJBNwpNCgQGAAIAEgREAkoDGj8gUHVibGlzaCBldmVudHMgdG8gYSBDaGFu
bmVsQ29ubmVjdGlvbiBpbiBhIHBhcnRuZXIncyBwcm9qZWN0LgoKDAoFBgACAAESA0QGJAoM
CgUGAAIAAhIDRCVKCgwKBQYAAgADEgNFDzUKDQoFBgACAAQSBEYESQYKEQoJBgACAASwyrwi
EgRGBEkGCjkKBAYAAgESBE0CUgMaKyBQdWJsaXNoIGV2ZW50cyB0byBhIHN1YnNjcmliZXIn
cyBjaGFubmVsLgoKDAoFBgACAQESA00GEwoMCgUGAAIBAhIDTRQoCgwKBQYAAgEDEgNNM0gK
DQoFBgACAQQSBE4EUQYKEQoJBgACAQSwyrwiEgROBFEGCjAKBAYAAgISBFUCWgMaIiBQdWJs
aXNoIGV2ZW50cyB0byBhIG1lc3NhZ2UgYnVzLgoKDAoFBgACAgESA1UGDQoMCgUGAAICAhID
VQ4cCgwKBQYAAgIDEgNVJzYKDQoFBgACAgQSBFYEWQYKEQoJBgACAgSwyrwiEgRWBFkGClAK
AgQAEgReAG0BGkQgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIFB1Ymxpc2hDaGFubmVs
Q29ubmVjdGlvbkV2ZW50cyBtZXRob2QuCgoKCgMEAAESA14ILQq5AQoEBAACABIDYQIgGqsB
IFRoZSBjaGFubmVsX2Nvbm5lY3Rpb24gdGhhdCB0aGUgZXZlbnRzIGFyZSBwdWJsaXNoZWQg
ZnJvbS4gRm9yIGV4YW1wbGU6CiBgcHJvamVjdHMve3BhcnRuZXJfcHJvamVjdF9pZH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY2hhbm5lbENvbm5lY3Rpb25zL3tjaGFubmVsX2Nvbm5lY3Rp
b25faWR9YC4KCgwKBQQAAgAFEgNhAggKDAoFBAACAAESA2EJGwoMCgUEAAIAAxIDYR4fCpkB
CgQEAAIBEgNlAioaiwEgVGhlIENsb3VkRXZlbnRzIHYxLjAgZXZlbnRzIHRvIHB1Ymxpc2gu
IE5vIG90aGVyIHR5cGVzIGFyZSBhbGxvd2VkLgogSWYgdGhpcyBmaWVsZCBpcyBzZXQsIHRo
ZW4gdGhlIGB0ZXh0X2V2ZW50c2AgZmllbGRzIG11c3Qgbm90IGJlIHNldC4KCgwKBQQAAgEE
EgNlAgoKDAoFBAACAQYSA2ULHgoMCgUEAAIBARIDZR8lCgwKBQQAAgEDEgNlKCkKqQIKBAQA
AgISA2wCIhqbAiBUaGUgdGV4dCByZXByZXNlbnRhdGlvbiBvZiBldmVudHMgdG8gcHVibGlz
aC4KIENsb3VkRXZlbnQgdjEuMCBpbiBKU09OIGZvcm1hdCBpcyB0aGUgb25seSBhbGxvd2Vk
IHR5cGUuIFJlZmVyIHRvCiBodHRwczovL2dpdGh1Yi5jb20vY2xvdWRldmVudHMvc3BlYy9i
bG9iL3YxLjAuMi9jbG91ZGV2ZW50cy9mb3JtYXRzL2pzb24tZm9ybWF0Lm1kCiBmb3Igc3Bl
Y2lmaWNhdGlvbi4KIElmIHRoaXMgZmllbGQgaXMgc2V0LCB0aGVuIHRoZSBgZXZlbnRzYCBm
aWVsZHMgbXVzdCBub3QgYmUgc2V0LgoKDAoFBAACAgQSA2wCCgoMCgUEAAICBRIDbAsRCgwK
BQQAAgIBEgNsEh0KDAoFBAACAgMSA2wgIQpQCgIEARIDcAAxGkUgVGhlIHJlc3BvbnNlIG1l
c3NhZ2UgZm9yIHRoZSBQdWJsaXNoQ2hhbm5lbENvbm5lY3Rpb25FdmVudHMgbWV0aG9kLgoK
CgoDBAEBEgNwCC4KQAoCBAISBXMAggEBGjMgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhl
IFB1Ymxpc2hFdmVudHMgbWV0aG9kLgoKCgoDBAIBEgNzCBwKiQEKBAQCAgASA3YCFRp8IFRo
ZSBmdWxsIG5hbWUgb2YgdGhlIGNoYW5uZWwgdG8gcHVibGlzaCB0by4gRm9yIGV4YW1wbGU6
CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NoYW5uZWxzL3tj
aGFubmVsLWlkfWAuCgoMCgUEAgIABRIDdgIICgwKBQQCAgABEgN2CRAKDAoFBAICAAMSA3YT
FAqZAQoEBAICARIDegIqGosBIFRoZSBDbG91ZEV2ZW50cyB2MS4wIGV2ZW50cyB0byBwdWJs
aXNoLiBObyBvdGhlciB0eXBlcyBhcmUgYWxsb3dlZC4KIElmIHRoaXMgZmllbGQgaXMgc2V0
LCB0aGVuIHRoZSBgdGV4dF9ldmVudHNgIGZpZWxkcyBtdXN0IG5vdCBiZSBzZXQuCgoMCgUE
AgIBBBIDegIKCgwKBQQCAgEGEgN6Cx4KDAoFBAICAQESA3ofJQoMCgUEAgIBAxIDeigpCqoC
CgQEAgICEgSBAQIiGpsCIFRoZSB0ZXh0IHJlcHJlc2VudGF0aW9uIG9mIGV2ZW50cyB0byBw
dWJsaXNoLgogQ2xvdWRFdmVudCB2MS4wIGluIEpTT04gZm9ybWF0IGlzIHRoZSBvbmx5IGFs
bG93ZWQgdHlwZS4gUmVmZXIgdG8KIGh0dHBzOi8vZ2l0aHViLmNvbS9jbG91ZGV2ZW50cy9z
cGVjL2Jsb2IvdjEuMC4yL2Nsb3VkZXZlbnRzL2Zvcm1hdHMvanNvbi1mb3JtYXQubWQKIGZv
ciBzcGVjaWZpY2F0aW9uLgogSWYgdGhpcyBmaWVsZCBpcyBzZXQsIHRoZW4gdGhlIGBldmVu
dHNgIGZpZWxkcyBtdXN0IG5vdCBiZSBzZXQuCgoNCgUEAgICBBIEgQECCgoNCgUEAgICBRIE
gQELEQoNCgUEAgICARIEgQESHQoNCgUEAgICAxIEgQEgIQpACgIEAxIEhQEAIBo0IFRoZSBy
ZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgUHVibGlzaEV2ZW50cyBtZXRob2QuCgoLCgMEAwES
BIUBCB0KOwoCBAQSBogBAJ0BARotIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBQdWJs
aXNoIG1ldGhvZC4KCgsKAwQEARIEiAEIFgqfAQoEBAQCABIEiwECQhqQASBSZXF1aXJlZC4g
VGhlIGZ1bGwgbmFtZSBvZiB0aGUgbWVzc2FnZSBidXMgdG8gcHVibGlzaCBldmVudHMgdG8u
IEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbWVz
c2FnZUJ1c2VzL3ttZXNzYWdlQnVzfWAuCgoNCgUEBAIABRIEiwECCAoNCgUEBAIAARIEiwEJ
FAoNCgUEBAIAAxIEiwEXGAoNCgUEBAIACBIEiwEZQQoQCggEBAIACJwIABIEiwEaQAoOCgQE
BAgAEgaNAQKcAQMKDQoFBAQIAAESBI0BCA4KwQEKBAQEAgESBJEBBCEasgEgVGhlIFByb3Rv
YnVmIGZvcm1hdCBvZiB0aGUgQ2xvdWRFdmVudCBiZWluZyBwdWJsaXNoZWQuIFNwZWNpZmlj
YXRpb24gY2FuCiBiZSBmb3VuZCBoZXJlOgogaHR0cHM6Ly9naXRodWIuY29tL2Nsb3VkZXZl
bnRzL3NwZWMvYmxvYi92MS4wLjIvY2xvdWRldmVudHMvZm9ybWF0cy9wcm90b2J1Zi1mb3Jt
YXQubWQKCg0KBQQEAgEGEgSRAQQOCg0KBQQEAgEBEgSRAQ8cCg0KBQQEAgEDEgSRAR8gCrkB
CgQEBAICEgSWAQQcGqoBIFRoZSBKU09OIGZvcm1hdCBvZiB0aGUgQ2xvdWRFdmVudCBiZWlu
ZyBwdWJsaXNoZWQuIFNwZWNpZmljYXRpb24gY2FuIGJlCiBmb3VuZCBoZXJlOgogaHR0cHM6
Ly9naXRodWIuY29tL2Nsb3VkZXZlbnRzL3NwZWMvYmxvYi92MS4wLjIvY2xvdWRldmVudHMv
Zm9ybWF0cy9qc29uLWZvcm1hdC5tZAoKDQoFBAQCAgUSBJYBBAoKDQoFBAQCAgESBJYBCxcK
DQoFBAQCAgMSBJYBGhsKuQEKBAQEAgMSBJsBBBsaqgEgVGhlIEF2cm8gZm9ybWF0IG9mIHRo
ZSBDbG91ZEV2ZW50IGJlaW5nIHB1Ymxpc2hlZC4gU3BlY2lmaWNhdGlvbiBjYW4KIGJlIGZv
dW5kIGhlcmU6CiBodHRwczovL2dpdGh1Yi5jb20vY2xvdWRldmVudHMvc3BlYy9ibG9iL3Yx
LjAuMi9jbG91ZGV2ZW50cy9mb3JtYXRzL2F2cm8tZm9ybWF0Lm1kCgoNCgUEBAIDBRIEmwEE
CQoNCgUEBAIDARIEmwEKFgoNCgUEBAIDAxIEmwEZGgo6CgIEBRIEoAEAGhouIFRoZSByZXNw
b25zZSBtZXNzYWdlIGZvciB0aGUgUHVibGlzaCBtZXRob2QuCgoLCgMEBQESBKABCBdiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest ===
    # Fields for PublishChannelConnectionEventsRequest
    # Field: channel_connection Type: 9 ()
    # Field: events Type: 11 (.google.protobuf.Any)
    # Field: text_events Type: 9 ()

# === Message: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsResponse ===
    # Fields for PublishChannelConnectionEventsResponse

# === Message: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsRequest ===
    # Fields for PublishEventsRequest
    # Field: channel Type: 9 ()
    # Field: events Type: 11 (.google.protobuf.Any)
    # Field: text_events Type: 9 ()

# === Message: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsResponse ===
    # Fields for PublishEventsResponse

# === Message: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishRequest ===
    # Fields for PublishRequest
    # Field: message_bus Type: 9 ()
    # Field: proto_message Type: 11 (.google.cloud.eventarc.publishing.v1.CloudEvent)
    # Field: json_message Type: 9 ()
    # Field: avro_message Type: 12 ()

# === Message: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishResponse ===
    # Fields for PublishResponse

# === Service Client: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublisherClient ===
package Google::Cloud::Eventarc::Publishing::V1::Publisher::PublisherClient;

=pod

=head2 Service Client: Google::Cloud::Eventarc::Publishing::V1::Publisher::PublisherClient

Client stub representing the remote C<Publisher> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<eventarc.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'eventarc.googleapis.com:443' );

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

sub publish_channel_connection_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.eventarc.publishing.v1.Publisher',
        method         => 'PublishChannelConnectionEvents',
        request        => $req,
        response_class => 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsResponse',
    });
}

sub publish_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.eventarc.publishing.v1.Publisher',
        method         => 'PublishEvents',
        request        => $req,
        response_class => 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsResponse',
    });
}

sub publish {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.eventarc.publishing.v1.Publisher',
        method         => 'Publish',
        request        => $req,
        response_class => 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::Publishing::V1::Publisher - Compiled Protocol Buffers messages for google/cloud/eventarc/publishing/v1/publisher.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::Publishing::V1::Publisher;

    my $msg = Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest->new({
        channel_connection => $channel_connection,
        events => $events,
        text_events => $text_events,
    });

    # Read or update a field
    my $val = $msg->channel_connection();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/publishing/v1/publisher.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest

The request message for the PublishChannelConnectionEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->channel_connection() >> / C<< $msg->channel_connection($value) >>

Type: C<String>

The channel_connection that the events are published from. For example:
`projects/{partner_project_id}/locations/{location}/channelConnections/{channel_connection_id}`.

=item * C<< $msg->events() >> / C<< $msg->events($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The CloudEvents v1.0 events to publish. No other types are allowed.
If this field is set, then the `text_events` fields must not be set.

=item * C<< $msg->text_events() >> / C<< $msg->text_events($value) >>

Type: C<String>

The text representation of events to publish.
CloudEvent v1.0 in JSON format is the only allowed type. Refer to
https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md
for specification.
If this field is set, then the `events` fields must not be set.

=back

=head2 Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsResponse

The response message for the PublishChannelConnectionEvents method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsRequest

The request message for the PublishEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->channel() >> / C<< $msg->channel($value) >>

Type: C<String>

The full name of the channel to publish to. For example:
`projects/{project}/locations/{location}/channels/{channel-id}`.

=item * C<< $msg->events() >> / C<< $msg->events($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The CloudEvents v1.0 events to publish. No other types are allowed.
If this field is set, then the `text_events` fields must not be set.

=item * C<< $msg->text_events() >> / C<< $msg->text_events($value) >>

Type: C<String>

The text representation of events to publish.
CloudEvent v1.0 in JSON format is the only allowed type. Refer to
https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md
for specification.
If this field is set, then the `events` fields must not be set.

=back

=head2 Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsResponse

The response message for the PublishEvents method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishRequest

The request message for the Publish method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_bus() >> / C<< $msg->message_bus($value) >>

Type: C<String>

Required. The full name of the message bus to publish events to. Format:
`projects/{project}/locations/{location}/messageBuses/{messageBus}`.

=item * C<< $msg->proto_message() >> / C<< $msg->proto_message($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Publishing::V1::CloudEvent::CloudEvent>)

The Protobuf format of the CloudEvent being published. Specification can
be found here:
https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/protobuf-format.md

=item * C<< $msg->json_message() >> / C<< $msg->json_message($value) >>

Type: C<String>

The JSON format of the CloudEvent being published. Specification can be
found here:
https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md

=item * C<< $msg->avro_message() >> / C<< $msg->avro_message($value) >>

Type: C<Bytes>

The Avro format of the CloudEvent being published. Specification can
be found here:
https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/avro-format.md

=back

=head2 Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishResponse

The response message for the Publish method.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::Publishing::V1::Publisher::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
