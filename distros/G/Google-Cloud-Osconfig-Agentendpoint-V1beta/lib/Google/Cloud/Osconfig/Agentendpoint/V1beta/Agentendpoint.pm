package Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies };
    eval { require Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MWJldGEvYWdlbnRlbmRw
b2ludC5wcm90bxIqZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRh
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxo/Z29vZ2xlL2Nsb3VkL29zY29uZmlnL2FnZW50ZW5kcG9pbnQvdjFiZXRhL2d1ZXN0
X3BvbGljaWVzLnByb3RvGjZnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92
MWJldGEvdGFza3MucHJvdG8iewoeUmVjZWl2ZVRhc2tOb3RpZmljYXRpb25SZXF1ZXN0Ei8K
EWluc3RhbmNlX2lkX3Rva2VuGAEgASgJQgPgQQJSD2luc3RhbmNlSWRUb2tlbhIoCg1hZ2Vu
dF92ZXJzaW9uGAIgASgJQgPgQQJSDGFnZW50VmVyc2lvbiIhCh9SZWNlaXZlVGFza05vdGlm
aWNhdGlvblJlc3BvbnNlIkcKFFN0YXJ0TmV4dFRhc2tSZXF1ZXN0Ei8KEWluc3RhbmNlX2lk
X3Rva2VuGAEgASgJQgPgQQJSD2luc3RhbmNlSWRUb2tlbiJdChVTdGFydE5leHRUYXNrUmVz
cG9uc2USRAoEdGFzaxgBIAEoCzIwLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBv
aW50LnYxYmV0YS5UYXNrUgR0YXNrItEDChlSZXBvcnRUYXNrUHJvZ3Jlc3NSZXF1ZXN0Ei8K
EWluc3RhbmNlX2lkX3Rva2VuGAEgASgJQgPgQQJSD2luc3RhbmNlSWRUb2tlbhIcCgd0YXNr
X2lkGAIgASgJQgPgQQJSBnRhc2tJZBJWCgl0YXNrX3R5cGUYAyABKA4yNC5nb29nbGUuY2xv
dWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuVGFza1R5cGVCA+BBAlIIdGFza1R5
cGUShQEKG2FwcGx5X3BhdGNoZXNfdGFza19wcm9ncmVzcxgEIAEoCzJELmdvb2dsZS5jbG91
ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YS5BcHBseVBhdGNoZXNUYXNrUHJvZ3Jl
c3NIAFIYYXBwbHlQYXRjaGVzVGFza1Byb2dyZXNzEnkKF2V4ZWNfc3RlcF90YXNrX3Byb2dy
ZXNzGAUgASgLMkAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRh
LkV4ZWNTdGVwVGFza1Byb2dyZXNzSABSFGV4ZWNTdGVwVGFza1Byb2dyZXNzQgoKCHByb2dy
ZXNzIn4KGlJlcG9ydFRhc2tQcm9ncmVzc1Jlc3BvbnNlEmAKDnRhc2tfZGlyZWN0aXZlGAEg
ASgOMjkuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLlRhc2tE
aXJlY3RpdmVSDXRhc2tEaXJlY3RpdmUi5wMKGVJlcG9ydFRhc2tDb21wbGV0ZVJlcXVlc3QS
LwoRaW5zdGFuY2VfaWRfdG9rZW4YASABKAlCA+BBAlIPaW5zdGFuY2VJZFRva2VuEhwKB3Rh
c2tfaWQYAiABKAlCA+BBAlIGdGFza0lkElYKCXRhc2tfdHlwZRgDIAEoDjI0Lmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YS5UYXNrVHlwZUID4EECUgh0YXNr
VHlwZRIjCg1lcnJvcl9tZXNzYWdlGAQgASgJUgxlcnJvck1lc3NhZ2USfwoZYXBwbHlfcGF0
Y2hlc190YXNrX291dHB1dBgFIAEoCzJCLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVu
ZHBvaW50LnYxYmV0YS5BcHBseVBhdGNoZXNUYXNrT3V0cHV0SABSFmFwcGx5UGF0Y2hlc1Rh
c2tPdXRwdXQScwoVZXhlY19zdGVwX3Rhc2tfb3V0cHV0GAYgASgLMj4uZ29vZ2xlLmNsb3Vk
Lm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkV4ZWNTdGVwVGFza091dHB1dEgAUhJl
eGVjU3RlcFRhc2tPdXRwdXRCCAoGb3V0cHV0IhwKGlJlcG9ydFRhc2tDb21wbGV0ZVJlc3Bv
bnNlIrsCChRSZWdpc3RlckFnZW50UmVxdWVzdBIvChFpbnN0YW5jZV9pZF90b2tlbhgBIAEo
CUID4EECUg9pbnN0YW5jZUlkVG9rZW4SKAoNYWdlbnRfdmVyc2lvbhgCIAEoCUID4EECUgxh
Z2VudFZlcnNpb24SOgoWc3VwcG9ydGVkX2NhcGFiaWxpdGllcxgDIAMoCUID4EECUhVzdXBw
b3J0ZWRDYXBhYmlsaXRpZXMSIAoMb3NfbG9uZ19uYW1lGAQgASgJUgpvc0xvbmdOYW1lEiIK
DW9zX3Nob3J0X25hbWUYBSABKAlSC29zU2hvcnROYW1lEh0KCm9zX3ZlcnNpb24YBiABKAlS
CW9zVmVyc2lvbhInCg9vc19hcmNoaXRlY3R1cmUYByABKAlSDm9zQXJjaGl0ZWN0dXJlIhcK
FVJlZ2lzdGVyQWdlbnRSZXNwb25zZTKlCgoUQWdlbnRFbmRwb2ludFNlcnZpY2US2AEKF1Jl
Y2VpdmVUYXNrTm90aWZpY2F0aW9uEkouZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5k
cG9pbnQudjFiZXRhLlJlY2VpdmVUYXNrTm90aWZpY2F0aW9uUmVxdWVzdBpLLmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YS5SZWNlaXZlVGFza05vdGlmaWNh
dGlvblJlc3BvbnNlIiLaQR9pbnN0YW5jZV9pZF90b2tlbixhZ2VudF92ZXJzaW9uMAESqgEK
DVN0YXJ0TmV4dFRhc2sSQC5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52
MWJldGEuU3RhcnROZXh0VGFza1JlcXVlc3QaQS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdl
bnRlbmRwb2ludC52MWJldGEuU3RhcnROZXh0VGFza1Jlc3BvbnNlIhTaQRFpbnN0YW5jZV9p
ZF90b2tlbhLLAQoSUmVwb3J0VGFza1Byb2dyZXNzEkUuZ29vZ2xlLmNsb3VkLm9zY29uZmln
LmFnZW50ZW5kcG9pbnQudjFiZXRhLlJlcG9ydFRhc2tQcm9ncmVzc1JlcXVlc3QaRi5nb29n
bGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MWJldGEuUmVwb3J0VGFza1Byb2dy
ZXNzUmVzcG9uc2UiJtpBI2luc3RhbmNlX2lkX3Rva2VuLHRhc2tfaWQsdGFza190eXBlEtkB
ChJSZXBvcnRUYXNrQ29tcGxldGUSRS5nb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRw
b2ludC52MWJldGEuUmVwb3J0VGFza0NvbXBsZXRlUmVxdWVzdBpGLmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YS5SZXBvcnRUYXNrQ29tcGxldGVSZXNwb25z
ZSI02kExaW5zdGFuY2VfaWRfdG9rZW4sdGFza19pZCx0YXNrX3R5cGUsZXJyb3JfbWVzc2Fn
ZRLsAQoaTG9va3VwRWZmZWN0aXZlR3Vlc3RQb2xpY3kSTS5nb29nbGUuY2xvdWQub3Njb25m
aWcuYWdlbnRlbmRwb2ludC52MWJldGEuTG9va3VwRWZmZWN0aXZlR3Vlc3RQb2xpY3lSZXF1
ZXN0GkAuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLkVmZmVj
dGl2ZUd1ZXN0UG9saWN5Ij3aQTppbnN0YW5jZV9pZF90b2tlbixvc19zaG9ydF9uYW1lLG9z
X3ZlcnNpb24sb3NfYXJjaGl0ZWN0dXJlEs8BCg1SZWdpc3RlckFnZW50EkAuZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLlJlZ2lzdGVyQWdlbnRSZXF1ZXN0
GkEuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQudjFiZXRhLlJlZ2lzdGVy
QWdlbnRSZXNwb25zZSI52kE2aW5zdGFuY2VfaWRfdG9rZW4sYWdlbnRfdmVyc2lvbixzdXBw
b3J0ZWRfY2FwYWJpbGl0aWVzGhrKQRdvc2NvbmZpZy5nb29nbGVhcGlzLmNvbUK7AQouY29t
Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxYmV0YUISQWdlbnRFbmRw
b2ludFByb3RvUAFaVGNsb3VkLmdvb2dsZS5jb20vZ28vb3Njb25maWcvYWdlbnRlbmRwb2lu
dC9hcGl2MWJldGEvYWdlbnRlbmRwb2ludHBiO2FnZW50ZW5kcG9pbnRwYsoCHEdvb2dsZVxD
bG91ZFxPc0NvbmZpZ1xWMWJldGFK1zkKBxIFDgDNAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQADMKCQoCAwASAxIAIQoJCgIDARIDEwApCgkKAgMCEgMU
AEkKCQoCAwMSAxUAQAoICgEIEgMXAGsKCQoCCAsSAxcAawoICgEIEgMYACIKCQoCCAoSAxgA
IgoICgEIEgMZADMKCQoCCAgSAxkAMwoICgEIEgMaAEcKCQoCCAESAxoARwoICgEIEgMbADkK
CQoCCCkSAxsAOQorCgIGABIEHgBAARofIE9TIENvbmZpZyBhZ2VudCBlbmRwb2ludCBBUEku
CgoKCgMGAAESAx4IHAoKCgMGAAMSAx8CPwoMCgUGAAOZCBIDHwI/CksKBAYAAgASBCICJAMa
PSBTdHJlYW0gZXN0YWJsaXNoZWQgYnkgY2xpZW50IHRvIHJlY2VpdmUgVGFzayBub3RpZmlj
YXRpb25zLgoKDAoFBgACAAESAyIGHQoMCgUGAAIAAhIDIh48CgwKBQYAAgAGEgMiR00KDAoF
BgACAAMSAyJObQoMCgUGAAIABBIDIwRNCg8KCAYAAgAEmwgAEgMjBE0KUAoEBgACARIEJwIp
AxpCIFNpZ25hbHMgdGhlIHN0YXJ0IG9mIGEgdGFzayBleGVjdXRpb24gYW5kIHJldHVybnMg
dGhlIHRhc2sgaW5mby4KCgwKBQYAAgEBEgMnBhMKDAoFBgACAQISAycUKAoMCgUGAAIBAxID
JzNICgwKBQYAAgEEEgMoBD8KDwoIBgACAQSbCAASAygEPwpOCgQGAAICEgQsAi4DGkAgU2ln
bmFscyBhbiBpbnRlcm1lZGlhcnkgcHJvZ3Jlc3MgY2hlY2twb2ludCBpbiB0YXNrIGV4ZWN1
dGlvbi4KCgwKBQYAAgIBEgMsBhgKDAoFBgACAgISAywZMgoMCgUGAAICAxIDLD1XCgwKBQYA
AgIEEgMtBFEKDwoIBgACAgSbCAASAy0EUQpiCgQGAAIDEgQyAjQDGlQgU2lnbmFscyB0aGF0
IHRoZSB0YXNrIGV4ZWN1dGlvbiBpcyBjb21wbGV0ZSBhbmQgb3B0aW9uYWxseSByZXR1cm5z
IHRoZSBuZXh0CiB0YXNrLgoKDAoFBgACAwESAzIGGAoMCgUGAAIDAhIDMhkyCgwKBQYAAgMD
EgMyPVcKDAoFBgACAwQSAzMEXwoPCggGAAIDBJsIABIDMwRfCp4BCgQGAAIEEgQ4AjoDGo8B
IExvb2t1cCB0aGUgZWZmZWN0aXZlIGd1ZXN0IHBvbGljeSB0aGF0IGFwcGxpZXMgdG8gYSBW
TSBpbnN0YW5jZS4gVGhpcwogbG9va3VwIG1lcmdlcyBhbGwgcG9saWNpZXMgdGhhdCBhcmUg
YXNzaWduZWQgdG8gdGhlIGluc3RhbmNlIGFuY2VzdHJ5LgoKDAoFBgACBAESAzgGIAoMCgUG
AAIEAhIDOCFCCgwKBQYAAgQDEgM4TWEKDAoFBgACBAQSAzkEaAoPCggGAAIEBJsIABIDOQRo
CjYKBAYAAgUSBD0CPwMaKCBSZWdpc3RlcnMgdGhlIGFnZW50IHJ1bm5pbmcgb24gdGhlIFZN
LgoKDAoFBgACBQESAz0GEwoMCgUGAAIFAhIDPRQoCgwKBQYAAgUDEgM9M0gKDAoFBgACBQQS
Az4EZAoPCggGAAIFBJsIABIDPgRkCj4KAgQAEgRDAEsBGjIgQSByZXF1ZXN0IG1lc3NhZ2Ug
dG8gcmVjZWl2ZSB0YXNrIG5vdGlmaWNhdGlvbnMuCgoKCgMEAAESA0MIJgrxAQoEBAACABID
RwJIGuMBIFJlcXVpcmVkLiBUaGlzIGlzIHRoZSBDb21wdXRlIEVuZ2luZSBpbnN0YW5jZSBp
ZGVudGl0eSB0b2tlbiBkZXNjcmliZWQgaW4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9j
b21wdXRlL2RvY3MvaW5zdGFuY2VzL3ZlcmlmeWluZy1pbnN0YW5jZS1pZGVudGl0eQogd2hl
cmUgdGhlIGF1ZGllbmNlIGlzICdvc2NvbmZpZy5nb29nbGVhcGlzLmNvbScgYW5kIHRoZSBm
b3JtYXQgaXMgJ2Z1bGwnLgoKDAoFBAACAAUSA0cCCAoMCgUEAAIAARIDRwkaCgwKBQQAAgAD
EgNHHR4KDAoFBAACAAgSA0cfRwoPCggEAAIACJwIABIDRyBGCkUKBAQAAgESA0oCRBo4IFJl
cXVpcmVkLiBUaGUgdmVyc2lvbiBvZiB0aGUgYWdlbnQgbWFraW5nIHRoZSByZXF1ZXN0LgoK
DAoFBAACAQUSA0oCCAoMCgUEAAIBARIDSgkWCgwKBQQAAgEDEgNKGRoKDAoFBAACAQgSA0ob
QwoPCggEAAIBCJwIABIDShxCCoABCgIEARIETwBRARp0IFRoZSBzdHJlYW1pbmcgcnBjIG1l
c3NhZ2UgdGhhdCBub3RpZmllcyB0aGUgYWdlbnQgd2hlbiBpdCBoYXMgYSB0YXNrCiB0aGF0
IGl0IG5lZWRzIHRvIHBlcmZvcm0gb24gdGhlIFZNIGluc3RhbmNlLgoKCgoDBAEBEgNPCCcK
TAoCBAISBFQAWQEaQCBBIHJlcXVlc3QgbWVzc2FnZSBmb3Igc2lnbmFsaW5nIHRoZSBzdGFy
dCBvZiBhIHRhc2sgZXhlY3V0aW9uLgoKCgoDBAIBEgNUCBwK8QEKBAQCAgASA1gCSBrjASBS
ZXF1aXJlZC4gVGhpcyBpcyB0aGUgQ29tcHV0ZSBFbmdpbmUgaW5zdGFuY2UgaWRlbnRpdHkg
dG9rZW4gZGVzY3JpYmVkIGluCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9k
b2NzL2luc3RhbmNlcy92ZXJpZnlpbmctaW5zdGFuY2UtaWRlbnRpdHkKIHdoZXJlIHRoZSBh
dWRpZW5jZSBpcyAnb3Njb25maWcuZ29vZ2xlYXBpcy5jb20nIGFuZCB0aGUgZm9ybWF0IGlz
ICdmdWxsJy4KCgwKBQQCAgAFEgNYAggKDAoFBAICAAESA1gJGgoMCgUEAgIAAxIDWB0eCgwK
BQQCAgAIEgNYH0cKDwoIBAICAAicCAASA1ggRgpSCgIEAxIEXABgARpGIEEgcmVzcG9uc2Ug
bWVzc2FnZSB0aGF0IGNvbnRhaW5zIHRoZSBkZXRhaWxzIG9mIHRoZSB0YXNrIHRvIHdvcmsg
b24uCgoKCgMEAwESA1wIHQpzCgQEAwIAEgNfAhAaZiBUaGUgZGV0YWlscyBvZiB0aGUgdGFz
ayB0aGF0IHNob3VsZCBiZSB3b3JrZWQgb24uICBDYW4gYmUgZW1wdHkgaWYgdGhlcmUKIGlz
IG5vIG5ldyB0YXNrIHRvIHdvcmsgb24uCgoMCgUEAwIABhIDXwIGCgwKBQQDAgABEgNfBwsK
DAoFBAMCAAMSA18ODwpLCgIEBBIEYwB9ARo/IEEgcmVxdWVzdCBtZXNzYWdlIGZvciByZXBv
cnRpbmcgdGhlIHByb2dyZXNzIG9mIGN1cnJlbnQgdGFzay4KCgoKAwQEARIDYwghCvEBCgQE
BAIAEgNnAkga4wEgUmVxdWlyZWQuIFRoaXMgaXMgdGhlIENvbXB1dGUgRW5naW5lIGluc3Rh
bmNlIGlkZW50aXR5IHRva2VuIGRlc2NyaWJlZCBpbgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2NvbXB1dGUvZG9jcy9pbnN0YW5jZXMvdmVyaWZ5aW5nLWluc3RhbmNlLWlkZW50aXR5
CiB3aGVyZSB0aGUgYXVkaWVuY2UgaXMgJ29zY29uZmlnLmdvb2dsZWFwaXMuY29tJyBhbmQg
dGhlIGZvcm1hdCBpcyAnZnVsbCcuCgoMCgUEBAIABRIDZwIICgwKBQQEAgABEgNnCRoKDAoF
BAQCAAMSA2cdHgoMCgUEBAIACBIDZx9HCg8KCAQEAgAInAgAEgNnIEYKRwoEBAQCARIDagI+
GjogUmVxdWlyZWQuIFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSB0YXNrIHRoaXMgYXBwbGll
cyB0by4KCgwKBQQEAgEFEgNqAggKDAoFBAQCAQESA2oJEAoMCgUEBAIBAxIDahMUCgwKBQQE
AgEIEgNqFT0KDwoIBAQCAQicCAASA2oWPAqjAgoEBAQCAhIDcwJCGpUCIFJlcXVpcmVkLiBU
aGUgdHlwZSBvZiB0YXNrIHRvIHJlcG9ydCBwcm9ncmVzcyBvbi4KCiBQcm9ncmVzcyBtdXN0
IGluY2x1ZGUgdGhlIGFwcHJvcHJpYXRlIG1lc3NhZ2UgYmFzZWQgb24gdGhpcyBlbnVtIGFz
CiBzcGVjaWZpZWQgYmVsb3c6CiBBUFBMWV9QQVRDSEVTID0gQXBwbHlQYXRjaGVzVGFza1By
b2dyZXNzCiBFWEVDX1NURVAgPSBQcm9ncmVzcyBub3Qgc3VwcG9ydGVkIGZvciB0aGlzIHR5
cGUuCiBBUFBMWV9DT05GSUdfVEFTSyA9IEFwcGx5Q29uZmlnVGFza1Byb2dyZXNzCgoMCgUE
BAICBhIDcwIKCgwKBQQEAgIBEgNzCxQKDAoFBAQCAgMSA3MXGAoMCgUEBAICCBIDcxlBCg8K
CAQEAgIInAgAEgNzGkAKOgoEBAQIABIEdgJ8AxosIEludGVybWVkaWF0ZSBwcm9ncmVzcyBv
ZiB0aGUgY3VycmVudCB0YXNrLgoKDAoFBAQIAAESA3YIEApECgQEBAIDEgN4BD0aNyBEZXRh
aWxzIGFib3V0IHRoZSBwcm9ncmVzcyBvZiB0aGUgYXBwbHkgcGF0Y2hlcyB0YXNrLgoKDAoF
BAQCAwYSA3gEHAoMCgUEBAIDARIDeB04CgwKBQQEAgMDEgN4OzwKQAoEBAQCBBIDewQ1GjMg
RGV0YWlscyBhYm91dCB0aGUgcHJvZ3Jlc3Mgb2YgdGhlIGV4ZWMgc3RlcCB0YXNrLgoKDAoF
BAQCBAYSA3sEGAoMCgUEBAIEARIDexkwCgwKBQQEAgQDEgN7MzQKWAoCBAUSBoABAIMBARpK
IFRoZSByZXNwb25zZSBtZXNzYWdlIGFmdGVyIHRoZSBhZ2VudCByZXBvcnRlZCB0aGUgY3Vy
cmVudCB0YXNrIHByb2dyZXNzLgoKCwoDBAUBEgSAAQgiCjMKBAQFAgASBIIBAiMaJSBJbnN0
cnVjdHMgYWdlbnQgdG8gY29udGludWUgb3Igbm90LgoKDQoFBAUCAAYSBIIBAg8KDQoFBAUC
AAESBIIBEB4KDQoFBAUCAAMSBIIBISIKUwoCBAYSBoYBAKMBARpFIEEgcmVxdWVzdCBtZXNz
YWdlIGZvciBzaWduYWxpbmcgdGhlIGNvbXBsZXRpb24gb2YgYSB0YXNrIGV4ZWN1dGlvbi4K
CgsKAwQGARIEhgEIIQryAQoEBAYCABIEigECSBrjASBSZXF1aXJlZC4gVGhpcyBpcyB0aGUg
Q29tcHV0ZSBFbmdpbmUgaW5zdGFuY2UgaWRlbnRpdHkgdG9rZW4gZGVzY3JpYmVkIGluCiBo
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2luc3RhbmNlcy92ZXJpZnlp
bmctaW5zdGFuY2UtaWRlbnRpdHkKIHdoZXJlIHRoZSBhdWRpZW5jZSBpcyAnb3Njb25maWcu
Z29vZ2xlYXBpcy5jb20nIGFuZCB0aGUgZm9ybWF0IGlzICdmdWxsJy4KCg0KBQQGAgAFEgSK
AQIICg0KBQQGAgABEgSKAQkaCg0KBQQGAgADEgSKAR0eCg0KBQQGAgAIEgSKAR9HChAKCAQG
AgAInAgAEgSKASBGCkgKBAQGAgESBI0BAj4aOiBSZXF1aXJlZC4gVW5pcXVlIGlkZW50aWZp
ZXIgb2YgdGhlIHRhc2sgdGhpcyBhcHBsaWVzIHRvLgoKDQoFBAYCAQUSBI0BAggKDQoFBAYC
AQESBI0BCRAKDQoFBAYCAQMSBI0BExQKDQoFBAYCAQgSBI0BFT0KEAoIBAYCAQicCAASBI0B
FjwKigIKBAQGAgISBJYBAkIa+wEgUmVxdWlyZWQuIFRoZSB0eXBlIG9mIHRhc2sgdG8gcmVw
b3J0IGNvbXBsZXRlZC4KCiBUaGUgb3V0cHV0IG11c3QgaW5jbHVkZSB0aGUgYXBwcm9wcmlh
dGUgbWVzc2FnZSBiYXNlZCBvbiB0aGUgZm9sbG93aW5nCiBlbnVtIHZhbHVlczoKIEFQUExZ
X1BBVENIRVMgPSBBcHBseVBhdGNoZXNUYXNrT3V0cHV0CiBFWEVDX1NURVAgPSBFeGVjU3Rl
cFRhc2tPdXRwdXQKIEFQUExZX0NPTkZJR19UQVNLID0gQXBwbHlDb25maWdUYXNrT3V0cHV0
CgoNCgUEBgICBhIElgECCgoNCgUEBgICARIElgELFAoNCgUEBgICAxIElgEXGAoNCgUEBgIC
CBIElgEZQQoQCggEBgICCJwIABIElgEaQApPCgQEBgIDEgSZAQIbGkEgRGVzY3JpcHRpdmUg
ZXJyb3IgbWVzc2FnZSBpZiB0aGUgdGFzayBleGVjdXRpb24gZW5kZWQgaW4gZXJyb3IuCgoN
CgUEBgIDBRIEmQECCAoNCgUEBgIDARIEmQEJFgoNCgUEBgIDAxIEmQEZGgo7CgQEBggAEgac
AQKiAQMaKyBGaW5hbCBvdXRwdXQgZGV0YWlscyBvZiB0aGUgY3VycmVudCB0YXNrLgoKDQoF
BAYIAAESBJwBCA4KPwoEBAYCBBIEngEEORoxIEZpbmFsIG91dHB1dCBkZXRhaWxzIG9mIHRo
ZSBhcHBseSBwYXRjaGVzIHRhc2s7CgoNCgUEBgIEBhIEngEEGgoNCgUEBgIEARIEngEbNAoN
CgUEBgIEAxIEngE3OAo7CgQEBgIFEgShAQQxGi0gRmluYWwgb3V0cHV0IGRldGFpbHMgb2Yg
dGhlIGV4ZWMgc3RlcCB0YXNrOwoKDQoFBAYCBQYSBKEBBBYKDQoFBAYCBQESBKEBFywKDQoF
BAYCBQMSBKEBLzAKWAoCBAcSBqYBAKgBARpKIFRoZSByZXNwb25zZSBtZXNzYWdlIGFmdGVy
IHRoZSBhZ2VudCBzaWduYWxlZCB0aGUgY3VycmVudCB0YXNrIGNvbXBsZXRlLgoKCwoDBAcB
EgSmAQgiCj4KAgQIEgarAQDIAQEaMCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvciByZWdpc3Rl
cmluZyB0aGUgYWdlbnQuCgoLCgMECAESBKsBCBwK8gEKBAQIAgASBK8BAkga4wEgUmVxdWly
ZWQuIFRoaXMgaXMgdGhlIENvbXB1dGUgRW5naW5lIGluc3RhbmNlIGlkZW50aXR5IHRva2Vu
IGRlc2NyaWJlZCBpbgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9p
bnN0YW5jZXMvdmVyaWZ5aW5nLWluc3RhbmNlLWlkZW50aXR5CiB3aGVyZSB0aGUgYXVkaWVu
Y2UgaXMgJ29zY29uZmlnLmdvb2dsZWFwaXMuY29tJyBhbmQgdGhlIGZvcm1hdCBpcyAnZnVs
bCcuCgoNCgUECAIABRIErwECCAoNCgUECAIAARIErwEJGgoNCgUECAIAAxIErwEdHgoNCgUE
CAIACBIErwEfRwoQCggECAIACJwIABIErwEgRgozCgQECAIBEgSyAQJEGiUgUmVxdWlyZWQu
IFRoZSB2ZXJzaW9uIG9mIHRoZSBhZ2VudC4KCg0KBQQIAgEFEgSyAQIICg0KBQQIAgEBEgSy
AQkWCg0KBQQIAgEDEgSyARkaCg0KBQQIAgEIEgSyARtDChAKCAQIAgEInAgAEgSyARxCCoAB
CgQECAICEgS4AQJWGnIgUmVxdWlyZWQuIFRoZSBjYXBhYmlsaXRpZXMgc3VwcG9ydGVkIGJ5
IHRoZSBhZ2VudC4gU3VwcG9ydGVkIHZhbHVlcyBhcmU6CiBQQVRDSF9HQQogR1VFU1RfUE9M
SUNZX0JFVEEKIENPTkZJR19WMQoKDQoFBAgCAgQSBLgBAgoKDQoFBAgCAgUSBLgBCxEKDQoF
BAgCAgESBLgBEigKDQoFBAgCAgMSBLgBKywKDQoFBAgCAggSBLgBLVUKEAoIBAgCAgicCAAS
BLgBLlQKgAEKBAQIAgMSBL0BAhoaciBUaGUgb3BlcmF0aW5nIHN5c3RlbSBsb25nIG5hbWUu
CiBGb3IgZXhhbXBsZSAnRGViaWFuIEdOVS9MaW51eCA5JyBvciAnTWljcm9zb2Z0IFdpbmRv
dyBTZXJ2ZXIgMjAxOQogRGF0YWNlbnRlcicuCgoNCgUECAIDBRIEvQECCAoNCgUECAIDARIE
vQEJFQoNCgUECAIDAxIEvQEYGQpVCgQECAIEEgTBAQIbGkcgVGhlIG9wZXJhdGluZyBzeXN0
ZW0gc2hvcnQgbmFtZS4KIEZvciBleGFtcGxlLCAnd2luZG93cycgb3IgJ2RlYmlhbicuCgoN
CgUECAIEBRIEwQECCAoNCgUECAIEARIEwQEJFgoNCgUECAIEAxIEwQEZGgo0CgQECAIFEgTE
AQIYGiYgVGhlIHZlcnNpb24gb2YgdGhlIG9wZXJhdGluZyBzeXN0ZW0uCgoNCgUECAIFBRIE
xAECCAoNCgUECAIFARIExAEJEwoNCgUECAIFAxIExAEWFwpACgQECAIGEgTHAQIdGjIgVGhl
IHN5c3RlbSBhcmNoaXRlY3R1cmUgb2YgdGhlIG9wZXJhdGluZyBzeXN0ZW0uCgoNCgUECAIG
BRIExwECCAoNCgUECAIGARIExwEJGAoNCgUECAIGAxIExwEbHApACgIECRIGywEAzQEBGjIg
VGhlIHJlc3BvbnNlIG1lc3NhZ2UgYWZ0ZXIgdGhlIGFnZW50IHJlZ2lzdGVyZWQuCgoLCgME
CQESBMsBCB1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest ===
    # Fields for ReceiveTaskNotificationRequest
    # Field: instance_id_token Type: 9 ()
    # Field: agent_version Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse ===
    # Fields for ReceiveTaskNotificationResponse

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest ===
    # Fields for StartNextTaskRequest
    # Field: instance_id_token Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse ===
    # Fields for StartNextTaskResponse
    # Field: task Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.Task)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest ===
    # Fields for ReportTaskProgressRequest
    # Field: instance_id_token Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.TaskType)
    # Field: apply_patches_task_progress Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ApplyPatchesTaskProgress)
    # Field: exec_step_task_progress Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepTaskProgress)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse ===
    # Fields for ReportTaskProgressResponse
    # Field: task_directive Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.TaskDirective)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest ===
    # Fields for ReportTaskCompleteRequest
    # Field: instance_id_token Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.osconfig.agentendpoint.v1beta.TaskType)
    # Field: error_message Type: 9 ()
    # Field: apply_patches_task_output Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ApplyPatchesTaskOutput)
    # Field: exec_step_task_output Type: 11 (.google.cloud.osconfig.agentendpoint.v1beta.ExecStepTaskOutput)

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse ===
    # Fields for ReportTaskCompleteResponse

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest ===
    # Fields for RegisterAgentRequest
    # Field: instance_id_token Type: 9 ()
    # Field: agent_version Type: 9 ()
    # Field: supported_capabilities Type: 9 ()
    # Field: os_long_name Type: 9 ()
    # Field: os_short_name Type: 9 ()
    # Field: os_version Type: 9 ()
    # Field: os_architecture Type: 9 ()

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse ===
    # Fields for RegisterAgentResponse

# === Service Client: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::AgentEndpointServiceClient ===
package Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::AgentEndpointServiceClient;

=pod

=head2 Service Client: Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::AgentEndpointServiceClient

Client stub representing the remote C<AgentEndpointService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<osconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'osconfig.googleapis.com:443' );

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

sub receive_task_notification {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'ReceiveTaskNotification',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse',
    });
}

sub start_next_task {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'StartNextTask',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse',
    });
}

sub report_task_progress {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'ReportTaskProgress',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse',
    });
}

sub report_task_complete {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'ReportTaskComplete',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse',
    });
}

sub lookup_effective_guest_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'LookupEffectiveGuestPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies::EffectiveGuestPolicy',
    });
}

sub register_agent {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'RegisterAgent',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1beta/agentendpoint.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest->new({
        instance_id_token => $instance_id_token,
        agent_version => $agent_version,
    });

    # Read or update a field
    my $val = $msg->instance_id_token();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1beta/agentendpoint.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest

A request message to receive task notifications.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->agent_version() >> / C<< $msg->agent_version($value) >>

Type: C<String>

Required. The version of the agent making the request.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse

The streaming rpc message that notifies the agent when it has a task
that it needs to perform on the VM instance.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest

A request message for signaling the start of a task execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse

A response message that contains the details of the task to work on.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task() >> / C<< $msg->task($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task>)

The details of the task that should be worked on.  Can be empty if there
is no new task to work on.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest

A request message for reporting the progress of current task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Required. Unique identifier of the task this applies to.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::TaskType>)

Required. The type of task to report progress on.

Progress must include the appropriate message based on this enum as
specified below:
APPLY_PATCHES = ApplyPatchesTaskProgress
EXEC_STEP = Progress not supported for this type.
APPLY_CONFIG_TASK = ApplyConfigTaskProgress

=item * C<< $msg->apply_patches_task_progress() >> / C<< $msg->apply_patches_task_progress($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskProgress>)

Details about the progress of the apply patches task.

=item * C<< $msg->exec_step_task_progress() >> / C<< $msg->exec_step_task_progress($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskProgress>)

Details about the progress of the exec step task.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse

The response message after the agent reported the current task progress.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->task_directive() >> / C<< $msg->task_directive($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::TaskDirective>)

Instructs agent to continue or not.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest

A request message for signaling the completion of a task execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

Required. Unique identifier of the task this applies to.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::TaskType>)

Required. The type of task to report completed.

The output must include the appropriate message based on the following
enum values:
APPLY_PATCHES = ApplyPatchesTaskOutput
EXEC_STEP = ExecStepTaskOutput
APPLY_CONFIG_TASK = ApplyConfigTaskOutput

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Descriptive error message if the task execution ended in error.

=item * C<< $msg->apply_patches_task_output() >> / C<< $msg->apply_patches_task_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskOutput>)

Final output details of the apply patches task;

=item * C<< $msg->exec_step_task_output() >> / C<< $msg->exec_step_task_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskOutput>)

Final output details of the exec step task;

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse

The response message after the agent signaled the current task complete.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest

The request message for registering the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance_id_token() >> / C<< $msg->instance_id_token($value) >>

Type: C<String>

Required. This is the Compute Engine instance identity token described in
https://cloud.google.com/compute/docs/instances/verifying-instance-identity
where the audience is 'osconfig.googleapis.com' and the format is 'full'.

=item * C<< $msg->agent_version() >> / C<< $msg->agent_version($value) >>

Type: C<String>

Required. The version of the agent.

=item * C<< $msg->supported_capabilities() >> / C<< $msg->supported_capabilities($value) >>

Type: C<String>

Required. The capabilities supported by the agent. Supported values are:
PATCH_GA
GUEST_POLICY_BETA
CONFIG_V1

=item * C<< $msg->os_long_name() >> / C<< $msg->os_long_name($value) >>

Type: C<String>

The operating system long name.
For example 'Debian GNU/Linux 9' or 'Microsoft Window Server 2019
Datacenter'.

=item * C<< $msg->os_short_name() >> / C<< $msg->os_short_name($value) >>

Type: C<String>

The operating system short name.
For example, 'windows' or 'debian'.

=item * C<< $msg->os_version() >> / C<< $msg->os_version($value) >>

Type: C<String>

The version of the operating system.

=item * C<< $msg->os_architecture() >> / C<< $msg->os_architecture($value) >>

Type: C<String>

The system architecture of the operating system.

=back

=head2 Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse

The response message after the agent registered.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
