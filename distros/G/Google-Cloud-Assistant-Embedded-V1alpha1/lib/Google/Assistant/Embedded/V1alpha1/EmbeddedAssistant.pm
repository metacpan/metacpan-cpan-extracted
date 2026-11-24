package Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvYXNzaXN0YW50L2VtYmVkZGVkL3YxYWxwaGExL2VtYmVkZGVkX2Fzc2lzdGFu
dC5wcm90bxIiZ29vZ2xlLmFzc2lzdGFudC5lbWJlZGRlZC52MWFscGhhMRocZ29vZ2xlL2Fw
aS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8iowIKDkNvbnZl
cnNlQ29uZmlnElkKD2F1ZGlvX2luX2NvbmZpZxgBIAEoCzIxLmdvb2dsZS5hc3Npc3RhbnQu
ZW1iZWRkZWQudjFhbHBoYTEuQXVkaW9JbkNvbmZpZ1INYXVkaW9JbkNvbmZpZxJcChBhdWRp
b19vdXRfY29uZmlnGAIgASgLMjIuZ29vZ2xlLmFzc2lzdGFudC5lbWJlZGRlZC52MWFscGhh
MS5BdWRpb091dENvbmZpZ1IOYXVkaW9PdXRDb25maWcSWAoOY29udmVyc2Vfc3RhdGUYAyAB
KAsyMS5nb29nbGUuYXNzaXN0YW50LmVtYmVkZGVkLnYxYWxwaGExLkNvbnZlcnNlU3RhdGVS
DWNvbnZlcnNlU3RhdGUi0QEKDUF1ZGlvSW5Db25maWcSVgoIZW5jb2RpbmcYASABKA4yOi5n
b29nbGUuYXNzaXN0YW50LmVtYmVkZGVkLnYxYWxwaGExLkF1ZGlvSW5Db25maWcuRW5jb2Rp
bmdSCGVuY29kaW5nEioKEXNhbXBsZV9yYXRlX2hlcnR6GAIgASgFUg9zYW1wbGVSYXRlSGVy
dHoiPAoIRW5jb2RpbmcSGAoURU5DT0RJTkdfVU5TUEVDSUZJRUQQABIMCghMSU5FQVIxNhAB
EggKBEZMQUMQAiKQAgoOQXVkaW9PdXRDb25maWcSVwoIZW5jb2RpbmcYASABKA4yOy5nb29n
bGUuYXNzaXN0YW50LmVtYmVkZGVkLnYxYWxwaGExLkF1ZGlvT3V0Q29uZmlnLkVuY29kaW5n
UghlbmNvZGluZxIqChFzYW1wbGVfcmF0ZV9oZXJ0ehgCIAEoBVIPc2FtcGxlUmF0ZUhlcnR6
EisKEXZvbHVtZV9wZXJjZW50YWdlGAMgASgFUhB2b2x1bWVQZXJjZW50YWdlIkwKCEVuY29k
aW5nEhgKFEVOQ09ESU5HX1VOU1BFQ0lGSUVEEAASDAoITElORUFSMTYQARIHCgNNUDMQAhIP
CgtPUFVTX0lOX09HRxADIj4KDUNvbnZlcnNlU3RhdGUSLQoSY29udmVyc2F0aW9uX3N0YXRl
GAEgASgMUhFjb252ZXJzYXRpb25TdGF0ZSIpCghBdWRpb091dBIdCgphdWRpb19kYXRhGAEg
ASgMUglhdWRpb0RhdGEimQMKDkNvbnZlcnNlUmVzdWx0Ei4KE3Nwb2tlbl9yZXF1ZXN0X3Rl
eHQYASABKAlSEXNwb2tlblJlcXVlc3RUZXh0EjAKFHNwb2tlbl9yZXNwb25zZV90ZXh0GAIg
ASgJUhJzcG9rZW5SZXNwb25zZVRleHQSLQoSY29udmVyc2F0aW9uX3N0YXRlGAMgASgMUhFj
b252ZXJzYXRpb25TdGF0ZRJqCg9taWNyb3Bob25lX21vZGUYBCABKA4yQS5nb29nbGUuYXNz
aXN0YW50LmVtYmVkZGVkLnYxYWxwaGExLkNvbnZlcnNlUmVzdWx0Lk1pY3JvcGhvbmVNb2Rl
Ug5taWNyb3Bob25lTW9kZRIrChF2b2x1bWVfcGVyY2VudGFnZRgFIAEoBVIQdm9sdW1lUGVy
Y2VudGFnZSJdCg5NaWNyb3Bob25lTW9kZRIfChtNSUNST1BIT05FX01PREVfVU5TUEVDSUZJ
RUQQABIUChBDTE9TRV9NSUNST1BIT05FEAESFAoQRElBTE9HX0ZPTExPV19PThACIpABCg9D
b252ZXJzZVJlcXVlc3QSTAoGY29uZmlnGAEgASgLMjIuZ29vZ2xlLmFzc2lzdGFudC5lbWJl
ZGRlZC52MWFscGhhMS5Db252ZXJzZUNvbmZpZ0gAUgZjb25maWcSGwoIYXVkaW9faW4YAiAB
KAxIAFIHYXVkaW9JbkISChBjb252ZXJzZV9yZXF1ZXN0Io4DChBDb252ZXJzZVJlc3BvbnNl
EioKBWVycm9yGAEgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNIAFIFZXJyb3ISXwoKZXZlbnRf
dHlwZRgCIAEoDjI+Lmdvb2dsZS5hc3Npc3RhbnQuZW1iZWRkZWQudjFhbHBoYTEuQ29udmVy
c2VSZXNwb25zZS5FdmVudFR5cGVIAFIJZXZlbnRUeXBlEksKCWF1ZGlvX291dBgDIAEoCzIs
Lmdvb2dsZS5hc3Npc3RhbnQuZW1iZWRkZWQudjFhbHBoYTEuQXVkaW9PdXRIAFIIYXVkaW9P
dXQSTAoGcmVzdWx0GAUgASgLMjIuZ29vZ2xlLmFzc2lzdGFudC5lbWJlZGRlZC52MWFscGhh
MS5Db252ZXJzZVJlc3VsdEgAUgZyZXN1bHQiPQoJRXZlbnRUeXBlEhoKFkVWRU5UX1RZUEVf
VU5TUEVDSUZJRUQQABIUChBFTkRfT0ZfVVRURVJBTkNFEAFCEwoRY29udmVyc2VfcmVzcG9u
c2UyjgEKEUVtYmVkZGVkQXNzaXN0YW50EnkKCENvbnZlcnNlEjMuZ29vZ2xlLmFzc2lzdGFu
dC5lbWJlZGRlZC52MWFscGhhMS5Db252ZXJzZVJlcXVlc3QaNC5nb29nbGUuYXNzaXN0YW50
LmVtYmVkZGVkLnYxYWxwaGExLkNvbnZlcnNlUmVzcG9uc2UoATABQoYBCiZjb20uZ29vZ2xl
LmFzc2lzdGFudC5lbWJlZGRlZC52MWFscGhhMUIOQXNzaXN0YW50UHJvdG9QAVpKZ29vZ2xl
LmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hc3Npc3RhbnQvZW1iZWRkZWQvdjFh
bHBoYTE7ZW1iZWRkZWRKrl4KBxIFDgCYAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwAhCggKAQgSAxUAYQoJCgII
CxIDFQBhCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgS
AxgAPwoJCgIIARIDGAA/CjsKAgYAEgQbAEYBGi8gU2VydmljZSB0aGF0IGltcGxlbWVudHMg
R29vZ2xlIEFzc2lzdGFudCBBUEkuCgoKCgMGAAESAxsIGQq7DQoEBgACABIDRQJJGq0NIElu
aXRpYXRlcyBvciBjb250aW51ZXMgYSBjb252ZXJzYXRpb24gd2l0aCB0aGUgZW1iZWRkZWQg
YXNzaXN0YW50IHNlcnZpY2UuCiBFYWNoIGNhbGwgcGVyZm9ybXMgb25lIHJvdW5kLXRyaXAs
IHNlbmRpbmcgYW4gYXVkaW8gcmVxdWVzdCB0byB0aGUgc2VydmljZQogYW5kIHJlY2Vpdmlu
ZyB0aGUgYXVkaW8gcmVzcG9uc2UuIFVzZXMgYmlkaXJlY3Rpb25hbCBzdHJlYW1pbmcgdG8g
cmVjZWl2ZQogcmVzdWx0cywgc3VjaCBhcyB0aGUgYEVORF9PRl9VVFRFUkFOQ0VgIGV2ZW50
LCB3aGlsZSBzZW5kaW5nIGF1ZGlvLgoKIEEgY29udmVyc2F0aW9uIGlzIG9uZSBvciBtb3Jl
IGdSUEMgY29ubmVjdGlvbnMsIGVhY2ggY29uc2lzdGluZyBvZiBzZXZlcmFsCiBzdHJlYW1l
ZCByZXF1ZXN0cyBhbmQgcmVzcG9uc2VzLgogRm9yIGV4YW1wbGUsIHRoZSB1c2VyIHNheXMg
KkFkZCB0byBteSBzaG9wcGluZyBsaXN0KiBhbmQgdGhlIGFzc2lzdGFudAogcmVzcG9uZHMg
KldoYXQgZG8geW91IHdhbnQgdG8gYWRkPyouIFRoZSBzZXF1ZW5jZSBvZiBzdHJlYW1lZCBy
ZXF1ZXN0cyBhbmQKIHJlc3BvbnNlcyBpbiB0aGUgZmlyc3QgZ1JQQyBtZXNzYWdlIGNvdWxk
IGJlOgoKICogICBDb252ZXJzZVJlcXVlc3QuY29uZmlnCiAqICAgQ29udmVyc2VSZXF1ZXN0
LmF1ZGlvX2luCiAqICAgQ29udmVyc2VSZXF1ZXN0LmF1ZGlvX2luCiAqICAgQ29udmVyc2VS
ZXF1ZXN0LmF1ZGlvX2luCiAqICAgQ29udmVyc2VSZXF1ZXN0LmF1ZGlvX2luCiAqICAgQ29u
dmVyc2VSZXNwb25zZS5ldmVudF90eXBlLkVORF9PRl9VVFRFUkFOQ0UKICogICBDb252ZXJz
ZVJlc3BvbnNlLnJlc3VsdC5taWNyb3Bob25lX21vZGUuRElBTE9HX0ZPTExPV19PTgogKiAg
IENvbnZlcnNlUmVzcG9uc2UuYXVkaW9fb3V0CiAqICAgQ29udmVyc2VSZXNwb25zZS5hdWRp
b19vdXQKICogICBDb252ZXJzZVJlc3BvbnNlLmF1ZGlvX291dAoKIFRoZSB1c2VyIHRoZW4g
c2F5cyAqYmFnZWxzKiBhbmQgdGhlIGFzc2lzdGFudCByZXNwb25kcwogKk9LLCBJJ3ZlIGFk
ZGVkIGJhZ2VscyB0byB5b3VyIHNob3BwaW5nIGxpc3QqLiBUaGlzIGlzIHNlbnQgYXMgYW5v
dGhlciBnUlBDCiBjb25uZWN0aW9uIGNhbGwgdG8gdGhlIGBDb252ZXJzZWAgbWV0aG9kLCBh
Z2FpbiB3aXRoIHN0cmVhbWVkIHJlcXVlc3RzIGFuZAogcmVzcG9uc2VzLCBzdWNoIGFzOgoK
ICogICBDb252ZXJzZVJlcXVlc3QuY29uZmlnCiAqICAgQ29udmVyc2VSZXF1ZXN0LmF1ZGlv
X2luCiAqICAgQ29udmVyc2VSZXF1ZXN0LmF1ZGlvX2luCiAqICAgQ29udmVyc2VSZXF1ZXN0
LmF1ZGlvX2luCiAqICAgQ29udmVyc2VSZXNwb25zZS5ldmVudF90eXBlLkVORF9PRl9VVFRF
UkFOQ0UKICogICBDb252ZXJzZVJlc3BvbnNlLnJlc3VsdC5taWNyb3Bob25lX21vZGUuQ0xP
U0VfTUlDUk9QSE9ORQogKiAgIENvbnZlcnNlUmVzcG9uc2UuYXVkaW9fb3V0CiAqICAgQ29u
dmVyc2VSZXNwb25zZS5hdWRpb19vdXQKICogICBDb252ZXJzZVJlc3BvbnNlLmF1ZGlvX291
dAogKiAgIENvbnZlcnNlUmVzcG9uc2UuYXVkaW9fb3V0CgogQWx0aG91Z2ggdGhlIHByZWNp
c2Ugb3JkZXIgb2YgcmVzcG9uc2VzIGlzIG5vdCBndWFyYW50ZWVkLCBzZXF1ZW50aWFsCiBD
b252ZXJzZVJlc3BvbnNlLmF1ZGlvX291dCBtZXNzYWdlcyB3aWxsIGFsd2F5cyBjb250YWlu
IHNlcXVlbnRpYWwgcG9ydGlvbnMKIG9mIGF1ZGlvLgoKDAoFBgACAAESA0UGDgoMCgUGAAIA
BRIDRQ8VCgwKBQYAAgACEgNFFiUKDAoFBgACAAYSA0UwNgoMCgUGAAIAAxIDRTdHCkYKAgQA
EgRJAFIBGjogU3BlY2lmaWVzIGhvdyB0byBwcm9jZXNzIHRoZSBgQ29udmVyc2VSZXF1ZXN0
YCBtZXNzYWdlcy4KCgoKAwQAARIDSQgWClEKBAQAAgASA0sCJBpEICpSZXF1aXJlZCogU3Bl
Y2lmaWVzIGhvdyB0byBwcm9jZXNzIHRoZSBzdWJzZXF1ZW50IGluY29taW5nIGF1ZGlvLgoK
DAoFBAACAAYSA0sCDwoMCgUEAAIAARIDSxAfCgwKBQQAAgADEgNLIiMKUgoEBAACARIDTgIm
GkUgKlJlcXVpcmVkKiBTcGVjaWZpZXMgaG93IHRvIGZvcm1hdCB0aGUgYXVkaW8gdGhhdCB3
aWxsIGJlIHJldHVybmVkLgoKDAoFBAACAQYSA04CEAoMCgUEAAIBARIDThEhCgwKBQQAAgED
EgNOJCUKPgoEBAACAhIDUQIjGjEgKlJlcXVpcmVkKiBSZXByZXNlbnRzIHRoZSBjdXJyZW50
IGRpYWxvZyBzdGF0ZS4KCgwKBQQAAgIGEgNRAg8KDAoFBAACAgESA1EQHgoMCgUEAAICAxID
USEiCoQCCgIEARIEWAB2ARr3ASBTcGVjaWZpZXMgaG93IHRvIHByb2Nlc3MgdGhlIGBhdWRp
b19pbmAgZGF0YSB0aGF0IHdpbGwgYmUgcHJvdmlkZWQgaW4KIHN1YnNlcXVlbnQgcmVxdWVz
dHMuIEZvciByZWNvbW1lbmRlZCBzZXR0aW5ncywgc2VlIHRoZSBHb29nbGUgQXNzaXN0YW50
IFNESwogW2Jlc3QKIHByYWN0aWNlc10oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20v
YXNzaXN0YW50L3Nkay9kZXZlbG9wL2dycGMvYmVzdC1wcmFjdGljZXMvYXVkaW8pLgoKCgoD
BAEBEgNYCBUKkQEKBAQBBAASBFsCawMaggEgQXVkaW8gZW5jb2Rpbmcgb2YgdGhlIGRhdGEg
c2VudCBpbiB0aGUgYXVkaW8gbWVzc2FnZS4KIEF1ZGlvIG11c3QgYmUgb25lLWNoYW5uZWwg
KG1vbm8pLiBUaGUgb25seSBsYW5ndWFnZSBzdXBwb3J0ZWQgaXMgImVuLVVTIi4KCgwKBQQB
BAABEgNbBw8KWAoGBAEEAAIAEgNdBB0aSSBOb3Qgc3BlY2lmaWVkLiBXaWxsIHJldHVybiBy
ZXN1bHQgW2dvb2dsZS5ycGMuQ29kZS5JTlZBTElEX0FSR1VNRU5UXVtdLgoKDgoHBAEEAAIA
ARIDXQQYCg4KBwQBBAACAAISA10bHAqMAQoGBAEEAAIBEgNhBBEafSBVbmNvbXByZXNzZWQg
MTYtYml0IHNpZ25lZCBsaXR0bGUtZW5kaWFuIHNhbXBsZXMgKExpbmVhciBQQ00pLgogVGhp
cyBlbmNvZGluZyBpbmNsdWRlcyBubyBoZWFkZXIsIG9ubHkgdGhlIHJhdyBhdWRpbyBieXRl
cy4KCg4KBwQBBAACAQESA2EEDAoOCgcEAQQAAgECEgNhDxAKpAMKBgQBBAACAhIDagQNGpQD
IFtgRkxBQ2BdKGh0dHBzOi8veGlwaC5vcmcvZmxhYy9kb2N1bWVudGF0aW9uLmh0bWwpIChG
cmVlIExvc3NsZXNzIEF1ZGlvCiBDb2RlYykgaXMgdGhlIHJlY29tbWVuZGVkIGVuY29kaW5n
IGJlY2F1c2UgaXQgaXMKIGxvc3NsZXNzLS10aGVyZWZvcmUgcmVjb2duaXRpb24gaXMgbm90
IGNvbXByb21pc2VkLS1hbmQKIHJlcXVpcmVzIG9ubHkgYWJvdXQgaGFsZiB0aGUgYmFuZHdp
ZHRoIG9mIGBMSU5FQVIxNmAuIFRoaXMgZW5jb2RpbmcKIGluY2x1ZGVzIHRoZSBgRkxBQ2Ag
c3RyZWFtIGhlYWRlciBmb2xsb3dlZCBieSBhdWRpbyBkYXRhLiBJdCBzdXBwb3J0cwogMTYt
Yml0IGFuZCAyNC1iaXQgc2FtcGxlcywgaG93ZXZlciwgbm90IGFsbCBmaWVsZHMgaW4gYFNU
UkVBTUlORk9gIGFyZQogc3VwcG9ydGVkLgoKDgoHBAEEAAICARIDagQICg4KBwQBBAACAgIS
A2oLDApRCgQEAQIAEgNuAhgaRCAqUmVxdWlyZWQqIEVuY29kaW5nIG9mIGF1ZGlvIGRhdGEg
c2VudCBpbiBhbGwgYGF1ZGlvX2luYCBtZXNzYWdlcy4KCgwKBQQBAgAGEgNuAgoKDAoFBAEC
AAESA24LEwoMCgUEAQIAAxIDbhYXCssCCgQEAQIBEgN1Ah4avQIgKlJlcXVpcmVkKiBTYW1w
bGUgcmF0ZSAoaW4gSGVydHopIG9mIHRoZSBhdWRpbyBkYXRhIHNlbnQgaW4gYWxsIGBhdWRp
b19pbmAKIG1lc3NhZ2VzLiBWYWxpZCB2YWx1ZXMgYXJlIGZyb20gMTYwMDAtMjQwMDAsIGJ1
dCAxNjAwMCBpcyBvcHRpbWFsLgogRm9yIGJlc3QgcmVzdWx0cywgc2V0IHRoZSBzYW1wbGlu
ZyByYXRlIG9mIHRoZSBhdWRpbyBzb3VyY2UgdG8gMTYwMDAgSHouCiBJZiB0aGF0J3Mgbm90
IHBvc3NpYmxlLCB1c2UgdGhlIG5hdGl2ZSBzYW1wbGUgcmF0ZSBvZiB0aGUgYXVkaW8gc291
cmNlCiAoaW5zdGVhZCBvZiByZS1zYW1wbGluZykuCgoMCgUEAQIBBRIDdQIHCgwKBQQBAgEB
EgN1CBkKDAoFBAECAQMSA3UcHQpoCgIEAhIFegCZAQEaWyBTcGVjaWZpZXMgdGhlIGRlc2ly
ZWQgZm9ybWF0IGZvciB0aGUgc2VydmVyIHRvIHVzZSB3aGVuIGl0IHJldHVybnMKIGBhdWRp
b19vdXRgIG1lc3NhZ2VzLgoKCgoDBAIBEgN6CBYKmQEKBAQCBAASBX0CjAEDGokBIEF1ZGlv
IGVuY29kaW5nIG9mIHRoZSBkYXRhIHJldHVybmVkIGluIHRoZSBhdWRpbyBtZXNzYWdlLiBB
bGwgZW5jb2RpbmdzIGFyZQogcmF3IGF1ZGlvIGJ5dGVzIHdpdGggbm8gaGVhZGVyLCBleGNl
cHQgYXMgaW5kaWNhdGVkIGJlbG93LgoKDAoFBAIEAAESA30HDwpYCgYEAgQAAgASA38EHRpJ
IE5vdCBzcGVjaWZpZWQuIFdpbGwgcmV0dXJuIHJlc3VsdCBbZ29vZ2xlLnJwYy5Db2RlLklO
VkFMSURfQVJHVU1FTlRdW10uCgoOCgcEAgQAAgABEgN/BBgKDgoHBAIEAAIAAhIDfxscClAK
BgQCBAACARIEggEEERpAIFVuY29tcHJlc3NlZCAxNi1iaXQgc2lnbmVkIGxpdHRsZS1lbmRp
YW4gc2FtcGxlcyAoTGluZWFyIFBDTSkuCgoPCgcEAgQAAgEBEgSCAQQMCg8KBwQCBAACAQIS
BIIBDxAKUAoGBAIEAAICEgSFAQQMGkAgTVAzIGF1ZGlvIGVuY29kaW5nLiBUaGUgc2FtcGxl
IHJhdGUgaXMgZW5jb2RlZCBpbiB0aGUgcGF5bG9hZC4KCg8KBwQCBAACAgESBIUBBAcKDwoH
BAIEAAICAhIEhQEKCwqzAgoGBAIEAAIDEgSLAQQUGqICIE9wdXMtZW5jb2RlZCBhdWRpbyB3
cmFwcGVkIGluIGFuIG9nZyBjb250YWluZXIuIFRoZSByZXN1bHQgd2lsbCBiZSBhCiBmaWxl
IHdoaWNoIGNhbiBiZSBwbGF5ZWQgbmF0aXZlbHkgb24gQW5kcm9pZCBhbmQgaW4gc29tZSBi
cm93c2VycyAoc3VjaAogYXMgQ2hyb21lKS4gVGhlIHF1YWxpdHkgb2YgdGhlIGVuY29kaW5n
IGlzIGNvbnNpZGVyYWJseSBoaWdoZXIgdGhhbiBNUDMKIHdoaWxlIHVzaW5nIHRoZSBzYW1l
IGJpdHJhdGUuIFRoZSBzYW1wbGUgcmF0ZSBpcyBlbmNvZGVkIGluIHRoZSBwYXlsb2FkLgoK
DwoHBAIEAAIDARIEiwEEDwoPCgcEAgQAAgMCEgSLARITCmIKBAQCAgASBJABAhgaVCAqUmVx
dWlyZWQqIFRoZSBlbmNvZGluZyBvZiBhdWRpbyBkYXRhIHRvIGJlIHJldHVybmVkIGluIGFs
bCBgYXVkaW9fb3V0YAogbWVzc2FnZXMuCgoNCgUEAgIABhIEkAECCgoNCgUEAgIAARIEkAEL
EwoNCgUEAgIAAxIEkAEWFwqHAQoEBAICARIElAECHhp5ICpSZXF1aXJlZCogVGhlIHNhbXBs
ZSByYXRlIGluIEhlcnR6IG9mIHRoZSBhdWRpbyBkYXRhIHJldHVybmVkIGluCiBgYXVkaW9f
b3V0YCBtZXNzYWdlcy4gVmFsaWQgdmFsdWVzIGFyZTogMTYwMDAtMjQwMDAuCgoNCgUEAgIB
BRIElAECBwoNCgUEAgIBARIElAEIGQoNCgUEAgIBAxIElAEcHQqJAQoEBAICAhIEmAECHhp7
ICpSZXF1aXJlZCogQ3VycmVudCB2b2x1bWUgc2V0dGluZyBvZiB0aGUgZGV2aWNlJ3MgYXVk
aW8gb3V0cHV0LgogVmFsaWQgdmFsdWVzIGFyZSAxIHRvIDEwMCAoY29ycmVzcG9uZGluZyB0
byAxJSB0byAxMDAlKS4KCg0KBQQCAgIFEgSYAQIHCg0KBQQCAgIBEgSYAQgZCg0KBQQCAgID
EgSYARwdCkQKAgQDEgacAQCjAQEaNiBQcm92aWRlcyBpbmZvcm1hdGlvbiBhYm91dCB0aGUg
Y3VycmVudCBkaWFsb2cgc3RhdGUuCgoLCgMEAwESBJwBCBUKyQIKBAQDAgASBKIBAh8augIg
KlJlcXVpcmVkKiBUaGUgYGNvbnZlcnNhdGlvbl9zdGF0ZWAgdmFsdWUgcmV0dXJuZWQgaW4g
dGhlIHByaW9yCiBgQ29udmVyc2VSZXNwb25zZWAuIE9taXQgKGRvIG5vdCBzZXQgdGhlIGZp
ZWxkKSBpZiB0aGVyZSB3YXMgbm8gcHJpb3IKIGBDb252ZXJzZVJlc3BvbnNlYC4gSWYgdGhl
cmUgd2FzIGEgcHJpb3IgYENvbnZlcnNlUmVzcG9uc2VgLCBkbyBub3Qgb21pdAogdGhpcyBm
aWVsZDsgZG9pbmcgc28gd2lsbCBlbmQgdGhhdCBjb252ZXJzYXRpb24gKGFuZCB0aGlzIG5l
dyByZXF1ZXN0IHdpbGwKIHN0YXJ0IGEgbmV3IGNvbnZlcnNhdGlvbikuCgoNCgUEAwIABRIE
ogECBwoNCgUEAwIAARIEogEIGgoNCgUEAwIAAxIEogEdHgqlAQoCBAQSBqcBAKwBARqWASBU
aGUgYXVkaW8gY29udGFpbmluZyB0aGUgYXNzaXN0YW50J3MgcmVzcG9uc2UgdG8gdGhlIHF1
ZXJ5LiBTZXF1ZW50aWFsIGNodW5rcwogb2YgYXVkaW8gZGF0YSBhcmUgcmVjZWl2ZWQgaW4g
c2VxdWVudGlhbCBgQ29udmVyc2VSZXNwb25zZWAgbWVzc2FnZXMuCgoLCgMEBAESBKcBCBAK
uQEKBAQEAgASBKsBAhcaqgEgKk91dHB1dC1vbmx5KiBUaGUgYXVkaW8gZGF0YSBjb250YWlu
aW5nIHRoZSBhc3Npc3RhbnQncyByZXNwb25zZSB0byB0aGUKIHF1ZXJ5LiBTZXF1ZW50aWFs
IGNodW5rcyBvZiBhdWRpbyBkYXRhIGFyZSByZWNlaXZlZCBpbiBzZXF1ZW50aWFsCiBgQ29u
dmVyc2VSZXNwb25zZWAgbWVzc2FnZXMuCgoNCgUEBAIABRIEqwECBwoNCgUEBAIAARIEqwEI
EgoNCgUEBAIAAxIEqwEVFgpACgIEBRIGrwEA2wEBGjIgVGhlIHNlbWFudGljIHJlc3VsdCBm
b3IgdGhlIHVzZXIncyBzcG9rZW4gcXVlcnkuCgoLCgMEBQESBK8BCBYKVQoEBAUEABIGsQEC
vQEDGkUgUG9zc2libGUgc3RhdGVzIG9mIHRoZSBtaWNyb3Bob25lIGFmdGVyIGEgYENvbnZl
cnNlYCBSUEMgY29tcGxldGVzLgoKDQoFBAUEAAESBLEBBxUKJAoGBAUEAAIAEgSzAQQkGhQg
Tm8gbW9kZSBzcGVjaWZpZWQuCgoPCgcEBQQAAgABEgSzAQQfCg8KBwQFBAACAAISBLMBIiMK
lQEKBgQFBAACARIEtwEEGRqEASBUaGUgc2VydmljZSBpcyBub3QgZXhwZWN0aW5nIGEgZm9s
bG93LW9uIHF1ZXN0aW9uIGZyb20gdGhlIHVzZXIuCiBUaGUgbWljcm9waG9uZSBzaG91bGQg
cmVtYWluIG9mZiB1bnRpbCB0aGUgdXNlciByZS1hY3RpdmF0ZXMgaXQuCgoPCgcEBQQAAgEB
EgS3AQQUCg8KBwQFBAACAQISBLcBFxgK2gEKBgQFBAACAhIEvAEEGRrJASBUaGUgc2Vydmlj
ZSBpcyBleHBlY3RpbmcgYSBmb2xsb3ctb24gcXVlc3Rpb24gZnJvbSB0aGUgdXNlci4gVGhl
CiBtaWNyb3Bob25lIHNob3VsZCBiZSByZS1vcGVuZWQgd2hlbiB0aGUgYEF1ZGlvT3V0YCBw
bGF5YmFjayBjb21wbGV0ZXMKIChieSBzdGFydGluZyBhIG5ldyBgQ29udmVyc2VgIFJQQyBj
YWxsIHRvIHNlbmQgdGhlIG5ldyBhdWRpbykuCgoPCgcEBQQAAgIBEgS8AQQUCg8KBwQFBAAC
AgISBLwBFxgKTgoEBAUCABIEwAECIRpAICpPdXRwdXQtb25seSogVGhlIHJlY29nbml6ZWQg
dHJhbnNjcmlwdCBvZiB3aGF0IHRoZSB1c2VyIHNhaWQuCgoNCgUEBQIABRIEwAECCAoNCgUE
BQIAARIEwAEJHAoNCgUEBQIAAxIEwAEfIAp2CgQEBQIBEgTEAQIiGmggKk91dHB1dC1vbmx5
KiBUaGUgdGV4dCBvZiB0aGUgYXNzaXN0YW50J3Mgc3Bva2VuIHJlc3BvbnNlLiBUaGlzIGlz
IG9ubHkKIHJldHVybmVkIGZvciBhbiBJRlRUVCBhY3Rpb24uCgoNCgUEBQIBBRIExAECCAoN
CgUEBQIBARIExAEJHQoNCgUEBQIBAxIExAEgIQrQAgoEBAUCAhIEywECHxrBAiAqT3V0cHV0
LW9ubHkqIFN0YXRlIGluZm9ybWF0aW9uIGZvciBzdWJzZXF1ZW50IGBDb252ZXJzZVJlcXVl
c3RgLiBUaGlzCiB2YWx1ZSBzaG91bGQgYmUgc2F2ZWQgaW4gdGhlIGNsaWVudCBhbmQgcmV0
dXJuZWQgaW4gdGhlCiBgY29udmVyc2F0aW9uX3N0YXRlYCB3aXRoIHRoZSBuZXh0IGBDb252
ZXJzZVJlcXVlc3RgLiAoVGhlIGNsaWVudCBkb2VzIG5vdAogbmVlZCB0byBpbnRlcnByZXQg
b3Igb3RoZXJ3aXNlIHVzZSB0aGlzIHZhbHVlLikgVGhlcmUgaXMgbm8gbmVlZCB0byBzYXZl
CiB0aGlzIGluZm9ybWF0aW9uIGFjcm9zcyBkZXZpY2UgcmVzdGFydHMuCgoNCgUEBQICBRIE
ywECBwoNCgUEBQICARIEywEIGgoNCgUEBQICAxIEywEdHgprCgQEBQIDEgTPAQIlGl0gKk91
dHB1dC1vbmx5KiBTcGVjaWZpZXMgdGhlIG1vZGUgb2YgdGhlIG1pY3JvcGhvbmUgYWZ0ZXIg
dGhpcyBgQ29udmVyc2VgCiBSUEMgaXMgcHJvY2Vzc2VkLgoKDQoFBAUCAwYSBM8BAhAKDQoF
BAUCAwESBM8BESAKDQoFBAUCAwMSBM8BIyQKmgUKBAQFAgQSBNoBAh4aiwUgKk91dHB1dC1v
bmx5KiBVcGRhdGVkIHZvbHVtZSBsZXZlbC4gVGhlIHZhbHVlIHdpbGwgYmUgMCBvciBvbWl0
dGVkCiAoaW5kaWNhdGluZyBubyBjaGFuZ2UpIHVubGVzcyBhIHZvaWNlIGNvbW1hbmQgc3Vj
aCBhcyAiSW5jcmVhc2UgdGhlIHZvbHVtZSIKIG9yICJTZXQgdm9sdW1lIGxldmVsIDQiIHdh
cyByZWNvZ25pemVkLCBpbiB3aGljaCBjYXNlIHRoZSB2YWx1ZSB3aWxsIGJlCiBiZXR3ZWVu
IDEgYW5kIDEwMCAoY29ycmVzcG9uZGluZyB0byB0aGUgbmV3IHZvbHVtZSBsZXZlbCBvZiAx
JSB0byAxMDAlKS4KIFR5cGljYWxseSwgYSBjbGllbnQgc2hvdWxkIHVzZSB0aGlzIHZvbHVt
ZSBsZXZlbCB3aGVuIHBsYXlpbmcgdGhlCiBgYXVkaW9fb3V0YCBkYXRhLCBhbmQgcmV0YWlu
IHRoaXMgdmFsdWUgYXMgdGhlIGN1cnJlbnQgdm9sdW1lIGxldmVsIGFuZAogc3VwcGx5IGl0
IGluIHRoZSBgQXVkaW9PdXRDb25maWdgIG9mIHRoZSBuZXh0IGBDb252ZXJzZVJlcXVlc3Rg
LiAoU29tZQogY2xpZW50cyBtYXkgYWxzbyBpbXBsZW1lbnQgb3RoZXIgd2F5cyB0byBhbGxv
dyB0aGUgY3VycmVudCB2b2x1bWUgbGV2ZWwgdG8KIGJlIGNoYW5nZWQsIGZvciBleGFtcGxl
LCBieSBwcm92aWRpbmcgYSBrbm9iIHRoYXQgdGhlIHVzZXIgY2FuIHR1cm4uKQoKDQoFBAUC
BAUSBNoBAgcKDQoFBAUCBAESBNoBCBkKDQoFBAUCBAMSBNoBHB0KxwIKAgQGEgbiAQD0AQEa
uAIgVGhlIHRvcC1sZXZlbCBtZXNzYWdlIHNlbnQgYnkgdGhlIGNsaWVudC4gQ2xpZW50cyBt
dXN0IHNlbmQgYXQgbGVhc3QgdHdvLCBhbmQKIHR5cGljYWxseSBudW1lcm91cyBgQ29udmVy
c2VSZXF1ZXN0YCBtZXNzYWdlcy4gVGhlIGZpcnN0IG1lc3NhZ2UgbXVzdAogY29udGFpbiBh
IGBjb25maWdgIG1lc3NhZ2UgYW5kIG11c3Qgbm90IGNvbnRhaW4gYGF1ZGlvX2luYCBkYXRh
LiBBbGwKIHN1YnNlcXVlbnQgbWVzc2FnZXMgbXVzdCBjb250YWluIGBhdWRpb19pbmAgZGF0
YSBhbmQgbXVzdCBub3QgY29udGFpbiBhCiBgY29uZmlnYCBtZXNzYWdlLgoKCwoDBAYBEgTi
AQgXCloKBAQGCAASBuQBAvMBAxpKIEV4YWN0bHkgb25lIG9mIHRoZXNlIGZpZWxkcyBtdXN0
IGJlIHNwZWNpZmllZCBpbiBlYWNoIGBDb252ZXJzZVJlcXVlc3RgLgoKDQoFBAYIAAESBOQB
CBgKvgEKBAQGAgASBOgBBB4arwEgVGhlIGBjb25maWdgIG1lc3NhZ2UgcHJvdmlkZXMgaW5m
b3JtYXRpb24gdG8gdGhlIHJlY29nbml6ZXIgdGhhdAogc3BlY2lmaWVzIGhvdyB0byBwcm9j
ZXNzIHRoZSByZXF1ZXN0LgogVGhlIGZpcnN0IGBDb252ZXJzZVJlcXVlc3RgIG1lc3NhZ2Ug
bXVzdCBjb250YWluIGEgYGNvbmZpZ2AgbWVzc2FnZS4KCg0KBQQGAgAGEgToAQQSCg0KBQQG
AgABEgToARMZCg0KBQQGAgADEgToARwdCvIDCgQEBgIBEgTyAQQXGuMDIFRoZSBhdWRpbyBk
YXRhIHRvIGJlIHJlY29nbml6ZWQuIFNlcXVlbnRpYWwgY2h1bmtzIG9mIGF1ZGlvIGRhdGEg
YXJlIHNlbnQKIGluIHNlcXVlbnRpYWwgYENvbnZlcnNlUmVxdWVzdGAgbWVzc2FnZXMuIFRo
ZSBmaXJzdCBgQ29udmVyc2VSZXF1ZXN0YAogbWVzc2FnZSBtdXN0IG5vdCBjb250YWluIGBh
dWRpb19pbmAgZGF0YSBhbmQgYWxsIHN1YnNlcXVlbnQKIGBDb252ZXJzZVJlcXVlc3RgIG1l
c3NhZ2VzIG11c3QgY29udGFpbiBgYXVkaW9faW5gIGRhdGEuIFRoZSBhdWRpbyBieXRlcwog
bXVzdCBiZSBlbmNvZGVkIGFzIHNwZWNpZmllZCBpbiBgQXVkaW9JbkNvbmZpZ2AuCiBBdWRp
byBtdXN0IGJlIHNlbnQgYXQgYXBwcm94aW1hdGVseSByZWFsLXRpbWUgKDE2MDAwIHNhbXBs
ZXMgcGVyIHNlY29uZCkuCiBBbiBlcnJvciB3aWxsIGJlIHJldHVybmVkIGlmIGF1ZGlvIGlz
IHNlbnQgc2lnbmlmaWNhbnRseSBmYXN0ZXIgb3IKIHNsb3dlci4KCg0KBQQGAgEFEgTyAQQJ
Cg0KBQQGAgEBEgTyAQoSCg0KBQQGAgEDEgTyARUWCpQBCgIEBxIG+AEAmAIBGoUBIFRoZSB0
b3AtbGV2ZWwgbWVzc2FnZSByZWNlaXZlZCBieSB0aGUgY2xpZW50LiBBIHNlcmllcyBvZiBv
bmUgb3IgbW9yZQogYENvbnZlcnNlUmVzcG9uc2VgIG1lc3NhZ2VzIGFyZSBzdHJlYW1lZCBi
YWNrIHRvIHRoZSBjbGllbnQuCgoLCgMEBwESBPgBCBgKLgoEBAcEABIG+gEChQIDGh4gSW5k
aWNhdGVzIHRoZSB0eXBlIG9mIGV2ZW50LgoKDQoFBAcEAAESBPoBBxAKJQoGBAcEAAIAEgT8
AQQfGhUgTm8gZXZlbnQgc3BlY2lmaWVkLgoKDwoHBAcEAAIAARIE/AEEGgoPCgcEBwQAAgAC
EgT8AR0eCqsDCgYEBwQAAgESBIQCBBkamgMgVGhpcyBldmVudCBpbmRpY2F0ZXMgdGhhdCB0
aGUgc2VydmVyIGhhcyBkZXRlY3RlZCB0aGUgZW5kIG9mIHRoZSB1c2VyJ3MKIHNwZWVjaCB1
dHRlcmFuY2UgYW5kIGV4cGVjdHMgbm8gYWRkaXRpb25hbCBzcGVlY2guIFRoZXJlZm9yZSwg
dGhlIHNlcnZlcgogd2lsbCBub3QgcHJvY2VzcyBhZGRpdGlvbmFsIGF1ZGlvIChhbHRob3Vn
aCBpdCBtYXkgc3Vic2VxdWVudGx5IHJldHVybgogYWRkaXRpb25hbCByZXN1bHRzKS4gVGhl
IGNsaWVudCBzaG91bGQgc3RvcCBzZW5kaW5nIGFkZGl0aW9uYWwgYXVkaW8KIGRhdGEsIGhh
bGYtY2xvc2UgdGhlIGdSUEMgY29ubmVjdGlvbiwgYW5kIHdhaXQgZm9yIGFueSBhZGRpdGlv
bmFsIHJlc3VsdHMKIHVudGlsIHRoZSBzZXJ2ZXIgY2xvc2VzIHRoZSBnUlBDIGNvbm5lY3Rp
b24uCgoPCgcEBwQAAgEBEgSEAgQUCg8KBwQHBAACAQISBIQCFxgKWwoEBAcIABIGiAIClwID
GksgRXhhY3RseSBvbmUgb2YgdGhlc2UgZmllbGRzIHdpbGwgYmUgcG9wdWxhdGVkIGluIGVh
Y2ggYENvbnZlcnNlUmVzcG9uc2VgLgoKDQoFBAcIAAESBIgCCBkK+QEKBAQHAgASBI0CBCAa
6gEgKk91dHB1dC1vbmx5KiBJZiBzZXQsIHJldHVybnMgYSBbZ29vZ2xlLnJwYy5TdGF0dXNd
W2dvb2dsZS5ycGMuU3RhdHVzXQogbWVzc2FnZSB0aGF0IHNwZWNpZmllcyB0aGUgZXJyb3Ig
Zm9yIHRoZSBvcGVyYXRpb24uIElmIGFuIGVycm9yIG9jY3VycwogZHVyaW5nIHByb2Nlc3Np
bmcsIHRoaXMgbWVzc2FnZSB3aWxsIGJlIHNldCBhbmQgdGhlcmUgd2lsbCBiZSBubyBmdXJ0
aGVyCiBtZXNzYWdlcyBzZW50LgoKDQoFBAcCAAYSBI0CBBUKDQoFBAcCAAESBI0CFhsKDQoF
BAcCAAMSBI0CHh8KOgoEBAcCARIEkAIEHRosICpPdXRwdXQtb25seSogSW5kaWNhdGVzIHRo
ZSB0eXBlIG9mIGV2ZW50LgoKDQoFBAcCAQYSBJACBA0KDQoFBAcCAQESBJACDhgKDQoFBAcC
AQMSBJACGxwKWQoEBAcCAhIEkwIEGxpLICpPdXRwdXQtb25seSogVGhlIGF1ZGlvIGNvbnRh
aW5pbmcgdGhlIGFzc2lzdGFudCdzIHJlc3BvbnNlIHRvIHRoZSBxdWVyeS4KCg0KBQQHAgIG
EgSTAgQMCg0KBQQHAgIBEgSTAg0WCg0KBQQHAgIDEgSTAhkaCk4KBAQHAgMSBJYCBB4aQCAq
T3V0cHV0LW9ubHkqIFRoZSBzZW1hbnRpYyByZXN1bHQgZm9yIHRoZSB1c2VyJ3Mgc3Bva2Vu
IHF1ZXJ5LgoKDQoFBAcCAwYSBJYCBBIKDQoFBAcCAwESBJYCExkKDQoFBAcCAwMSBJYCHB1i
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig ===
    # Fields for ConverseConfig
    # Field: audio_in_config Type: 11 (.google.assistant.embedded.v1alpha1.AudioInConfig)
    # Field: audio_out_config Type: 11 (.google.assistant.embedded.v1alpha1.AudioOutConfig)
    # Field: converse_state Type: 11 (.google.assistant.embedded.v1alpha1.ConverseState)

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioInConfig ===
    # Fields for AudioInConfig
    # Field: encoding Type: 14 (.google.assistant.embedded.v1alpha1.AudioInConfig.Encoding)
    # Field: sample_rate_hertz Type: 5 ()

# Enum: AudioInConfig::Encoding
our $AudioInConfig_ENCODING_UNSPECIFIED = 0;
our $AudioInConfig_LINEAR16 = 1;
our $AudioInConfig_FLAC = 2;

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOutConfig ===
    # Fields for AudioOutConfig
    # Field: encoding Type: 14 (.google.assistant.embedded.v1alpha1.AudioOutConfig.Encoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: volume_percentage Type: 5 ()

# Enum: AudioOutConfig::Encoding
our $AudioOutConfig_ENCODING_UNSPECIFIED = 0;
our $AudioOutConfig_LINEAR16 = 1;
our $AudioOutConfig_MP3 = 2;
our $AudioOutConfig_OPUS_IN_OGG = 3;

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseState ===
    # Fields for ConverseState
    # Field: conversation_state Type: 12 ()

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOut ===
    # Fields for AudioOut
    # Field: audio_data Type: 12 ()

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResult ===
    # Fields for ConverseResult
    # Field: spoken_request_text Type: 9 ()
    # Field: spoken_response_text Type: 9 ()
    # Field: conversation_state Type: 12 ()
    # Field: microphone_mode Type: 14 (.google.assistant.embedded.v1alpha1.ConverseResult.MicrophoneMode)
    # Field: volume_percentage Type: 5 ()

# Enum: ConverseResult::MicrophoneMode
our $ConverseResult_MICROPHONE_MODE_UNSPECIFIED = 0;
our $ConverseResult_CLOSE_MICROPHONE = 1;
our $ConverseResult_DIALOG_FOLLOW_ON = 2;

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseRequest ===
    # Fields for ConverseRequest
    # Field: config Type: 11 (.google.assistant.embedded.v1alpha1.ConverseConfig)
    # Field: audio_in Type: 12 ()

# === Message: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResponse ===
    # Fields for ConverseResponse
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: event_type Type: 14 (.google.assistant.embedded.v1alpha1.ConverseResponse.EventType)
    # Field: audio_out Type: 11 (.google.assistant.embedded.v1alpha1.AudioOut)
    # Field: result Type: 11 (.google.assistant.embedded.v1alpha1.ConverseResult)

# Enum: ConverseResponse::EventType
our $ConverseResponse_EVENT_TYPE_UNSPECIFIED = 0;
our $ConverseResponse_END_OF_UTTERANCE = 1;

# === Service Client: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::EmbeddedAssistantClient ===
package Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::EmbeddedAssistantClient;

=pod

=head2 Service Client: Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::EmbeddedAssistantClient

Client stub representing the remote C<EmbeddedAssistant> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<assistant.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'assistant.googleapis.com:443' );

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

sub converse {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.assistant.embedded.v1alpha1.EmbeddedAssistant',
        method         => 'Converse',
        request        => $req,
        response_class => 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant - Compiled Protocol Buffers messages for google/assistant/embedded/v1alpha1/embedded_assistant.proto

=head1 SYNOPSIS

    use Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant;

    my $msg = Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig->new({
        audio_in_config => $audio_in_config,
        audio_out_config => $audio_out_config,
        converse_state => $converse_state,
    });

    # Read or update a field
    my $val = $msg->audio_in_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/assistant/embedded/v1alpha1/embedded_assistant.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig

Specifies how to process the `ConverseRequest` messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_in_config() >> / C<< $msg->audio_in_config($value) >>

Type: C<Message> (L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioInConfig>)

*Required* Specifies how to process the subsequent incoming audio.

=item * C<< $msg->audio_out_config() >> / C<< $msg->audio_out_config($value) >>

Type: C<Message> (L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOutConfig>)

*Required* Specifies how to format the audio that will be returned.

=item * C<< $msg->converse_state() >> / C<< $msg->converse_state($value) >>

Type: C<Message> (L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseState>)

*Required* Represents the current dialog state.

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioInConfig

Specifies how to process the `audio_in` data that will be provided in
subsequent requests. For recommended settings, see the Google Assistant SDK
[best
practices](https://developers.google.com/assistant/sdk/develop/grpc/best-practices/audio).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encoding() >> / C<< $msg->encoding($value) >>

Type: C<Enum> (L<Google::Assistant::Embedded::V1alpha1::AudioInConfig::Encoding>)

*Required* Encoding of audio data sent in all `audio_in` messages.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

*Required* Sample rate (in Hertz) of the audio data sent in all `audio_in`
messages. Valid values are from 16000-24000, but 16000 is optimal.
For best results, set the sampling rate of the audio source to 16000 Hz.
If that's not possible, use the native sample rate of the audio source
(instead of re-sampling).

=back

=head3 Enum: AudioInConfig::Encoding

=over 4

=item * C<ENCODING_UNSPECIFIED> => C<0>

=item * C<LINEAR16> => C<1>

=item * C<FLAC> => C<2>

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOutConfig

Specifies the desired format for the server to use when it returns
`audio_out` messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->encoding() >> / C<< $msg->encoding($value) >>

Type: C<Enum> (L<Google::Assistant::Embedded::V1alpha1::AudioOutConfig::Encoding>)

*Required* The encoding of audio data to be returned in all `audio_out`
messages.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

*Required* The sample rate in Hertz of the audio data returned in
`audio_out` messages. Valid values are: 16000-24000.

=item * C<< $msg->volume_percentage() >> / C<< $msg->volume_percentage($value) >>

Type: C<Int32>

*Required* Current volume setting of the device's audio output.
Valid values are 1 to 100 (corresponding to 1% to 100%).

=back

=head3 Enum: AudioOutConfig::Encoding

=over 4

=item * C<ENCODING_UNSPECIFIED> => C<0>

=item * C<LINEAR16> => C<1>

=item * C<MP3> => C<2>

=item * C<OPUS_IN_OGG> => C<3>

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseState

Provides information about the current dialog state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation_state() >> / C<< $msg->conversation_state($value) >>

Type: C<Bytes>

*Required* The `conversation_state` value returned in the prior
`ConverseResponse`. Omit (do not set the field) if there was no prior
`ConverseResponse`. If there was a prior `ConverseResponse`, do not omit
this field; doing so will end that conversation (and this new request will
start a new conversation).

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOut

The audio containing the assistant's response to the query. Sequential chunks
of audio data are received in sequential `ConverseResponse` messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->audio_data() >> / C<< $msg->audio_data($value) >>

Type: C<Bytes>

*Output-only* The audio data containing the assistant's response to the
query. Sequential chunks of audio data are received in sequential
`ConverseResponse` messages.

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResult

The semantic result for the user's spoken query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->spoken_request_text() >> / C<< $msg->spoken_request_text($value) >>

Type: C<String>

*Output-only* The recognized transcript of what the user said.

=item * C<< $msg->spoken_response_text() >> / C<< $msg->spoken_response_text($value) >>

Type: C<String>

*Output-only* The text of the assistant's spoken response. This is only
returned for an IFTTT action.

=item * C<< $msg->conversation_state() >> / C<< $msg->conversation_state($value) >>

Type: C<Bytes>

*Output-only* State information for subsequent `ConverseRequest`. This
value should be saved in the client and returned in the
`conversation_state` with the next `ConverseRequest`. (The client does not
need to interpret or otherwise use this value.) There is no need to save
this information across device restarts.

=item * C<< $msg->microphone_mode() >> / C<< $msg->microphone_mode($value) >>

Type: C<Enum> (L<Google::Assistant::Embedded::V1alpha1::ConverseResult::MicrophoneMode>)

*Output-only* Specifies the mode of the microphone after this `Converse`
RPC is processed.

=item * C<< $msg->volume_percentage() >> / C<< $msg->volume_percentage($value) >>

Type: C<Int32>

*Output-only* Updated volume level. The value will be 0 or omitted
(indicating no change) unless a voice command such as "Increase the volume"
or "Set volume level 4" was recognized, in which case the value will be
between 1 and 100 (corresponding to the new volume level of 1% to 100%).
Typically, a client should use this volume level when playing the
`audio_out` data, and retain this value as the current volume level and
supply it in the `AudioOutConfig` of the next `ConverseRequest`. (Some
clients may also implement other ways to allow the current volume level to
be changed, for example, by providing a knob that the user can turn.)

=back

=head3 Enum: ConverseResult::MicrophoneMode

=over 4

=item * C<MICROPHONE_MODE_UNSPECIFIED> => C<0>

=item * C<CLOSE_MICROPHONE> => C<1>

=item * C<DIALOG_FOLLOW_ON> => C<2>

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseRequest

The top-level message sent by the client. Clients must send at least two, and
typically numerous `ConverseRequest` messages. The first message must
contain a `config` message and must not contain `audio_in` data. All
subsequent messages must contain `audio_in` data and must not contain a
`config` message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig>)

The `config` message provides information to the recognizer that
specifies how to process the request.
The first `ConverseRequest` message must contain a `config` message.

=item * C<< $msg->audio_in() >> / C<< $msg->audio_in($value) >>

Type: C<Bytes>

The audio data to be recognized. Sequential chunks of audio data are sent
in sequential `ConverseRequest` messages. The first `ConverseRequest`
message must not contain `audio_in` data and all subsequent
`ConverseRequest` messages must contain `audio_in` data. The audio bytes
must be encoded as specified in `AudioInConfig`.
Audio must be sent at approximately real-time (16000 samples per second).
An error will be returned if audio is sent significantly faster or
slower.

=back

=head2 Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResponse

The top-level message received by the client. A series of one or more
`ConverseResponse` messages are streamed back to the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

*Output-only* If set, returns a [google.rpc.Status][google.rpc.Status]
message that specifies the error for the operation. If an error occurs
during processing, this message will be set and there will be no further
messages sent.

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<Enum> (L<Google::Assistant::Embedded::V1alpha1::ConverseResponse::EventType>)

*Output-only* Indicates the type of event.

=item * C<< $msg->audio_out() >> / C<< $msg->audio_out($value) >>

Type: C<Message> (L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOut>)

*Output-only* The audio containing the assistant's response to the query.

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Message> (L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResult>)

*Output-only* The semantic result for the user's spoken query.

=back

=head3 Enum: ConverseResponse::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<END_OF_UTTERANCE> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
