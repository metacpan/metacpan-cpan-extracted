package Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvYmlncXVlcnkvZGF0YXBvbGljaWVzL3YxYmV0YTEvZGF0YXBvbGlj
eS5wcm90bxIqZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MWJldGExGhxn
b29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5w
cm90bxoeZ29vZ2xlL2lhbS92MS9pYW1fcG9saWN5LnByb3RvGhpnb29nbGUvaWFtL3YxL3Bv
bGljeS5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9i
dWYvZmllbGRfbWFzay5wcm90byLFAQoXQ3JlYXRlRGF0YVBvbGljeVJlcXVlc3QSTAoGcGFy
ZW50GAEgASgJQjTgQQL6QS4SLGJpZ3F1ZXJ5ZGF0YXBvbGljeS5nb29nbGVhcGlzLmNvbS9E
YXRhUG9saWN5UgZwYXJlbnQSXAoLZGF0YV9wb2xpY3kYAiABKAsyNi5nb29nbGUuY2xvdWQu
YmlncXVlcnkuZGF0YXBvbGljaWVzLnYxYmV0YTEuRGF0YVBvbGljeUID4EECUgpkYXRhUG9s
aWN5IrQBChdVcGRhdGVEYXRhUG9saWN5UmVxdWVzdBJcCgtkYXRhX3BvbGljeRgBIAEoCzI2
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjFiZXRhMS5EYXRhUG9saWN5
QgPgQQJSCmRhdGFQb2xpY3kSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrImMKF0RlbGV0ZURhdGFQb2xpY3lSZXF1ZXN0EkgK
BG5hbWUYASABKAlCNOBBAvpBLgosYmlncXVlcnlkYXRhcG9saWN5Lmdvb2dsZWFwaXMuY29t
L0RhdGFQb2xpY3lSBG5hbWUiYAoUR2V0RGF0YVBvbGljeVJlcXVlc3QSSAoEbmFtZRgBIAEo
CUI04EEC+kEuCixiaWdxdWVyeWRhdGFwb2xpY3kuZ29vZ2xlYXBpcy5jb20vRGF0YVBvbGlj
eVIEbmFtZSKjAQoXTGlzdERhdGFQb2xpY2llc1JlcXVlc3QSTAoGcGFyZW50GAEgASgJQjTg
QQL6QS4SLGJpZ3F1ZXJ5ZGF0YXBvbGljeS5nb29nbGVhcGlzLmNvbS9EYXRhUG9saWN5UgZw
YXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJ
UglwYWdlVG9rZW4inwEKGExpc3REYXRhUG9saWNpZXNSZXNwb25zZRJbCg1kYXRhX3BvbGlj
aWVzGAEgAygLMjYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MWJldGEx
LkRhdGFQb2xpY3lSDGRhdGFQb2xpY2llcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4i0AQKCkRhdGFQb2xpY3kSHwoKcG9saWN5X3RhZxgEIAEoCUgAUglwb2xp
Y3lUYWcSbwoTZGF0YV9tYXNraW5nX3BvbGljeRgFIAEoCzI9Lmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5kYXRhcG9saWNpZXMudjFiZXRhMS5EYXRhTWFza2luZ1BvbGljeUgBUhFkYXRhTWFz
a2luZ1BvbGljeRIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSbwoQZGF0YV9wb2xpY3lfdHlw
ZRgCIAEoDjJFLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjFiZXRhMS5E
YXRhUG9saWN5LkRhdGFQb2xpY3lUeXBlUg5kYXRhUG9saWN5VHlwZRIkCg5kYXRhX3BvbGlj
eV9pZBgDIAEoCVIMZGF0YVBvbGljeUlkIm0KDkRhdGFQb2xpY3lUeXBlEiAKHERBVEFfUE9M
SUNZX1RZUEVfVU5TUEVDSUZJRUQQABIgChxDT0xVTU5fTEVWRUxfU0VDVVJJVFlfUE9MSUNZ
EAMSFwoTREFUQV9NQVNLSU5HX1BPTElDWRACOnXqQXIKLGJpZ3F1ZXJ5ZGF0YXBvbGljeS5n
b29nbGVhcGlzLmNvbS9EYXRhUG9saWN5EkJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGF0YVBvbGljaWVzL3tkYXRhX3BvbGljeX1CEAoObWF0Y2hpbmdfbGFi
ZWxCCAoGcG9saWN5IqwCChFEYXRhTWFza2luZ1BvbGljeRKJAQoVcHJlZGVmaW5lZF9leHBy
ZXNzaW9uGAEgASgOMlIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MWJl
dGExLkRhdGFNYXNraW5nUG9saWN5LlByZWRlZmluZWRFeHByZXNzaW9uSABSFHByZWRlZmlu
ZWRFeHByZXNzaW9uInUKFFByZWRlZmluZWRFeHByZXNzaW9uEiUKIVBSRURFRklORURfRVhQ
UkVTU0lPTl9VTlNQRUNJRklFRBAAEgoKBlNIQTI1NhADEg8KC0FMV0FZU19OVUxMEAUSGQoV
REVGQVVMVF9NQVNLSU5HX1ZBTFVFEAdCFAoSbWFza2luZ19leHByZXNzaW9uMv8NChFEYXRh
UG9saWN5U2VydmljZRLwAQoQQ3JlYXRlRGF0YVBvbGljeRJDLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5kYXRhcG9saWNpZXMudjFiZXRhMS5DcmVhdGVEYXRhUG9saWN5UmVxdWVzdBo2Lmdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjFiZXRhMS5EYXRhUG9saWN5Il+C
0+STAkQiNS92MWJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZGF0YVBv
bGljaWVzOgtkYXRhX3BvbGljedpBEnBhcmVudCxkYXRhX3BvbGljeRKBAgoQVXBkYXRlRGF0
YVBvbGljeRJDLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjFiZXRhMS5V
cGRhdGVEYXRhUG9saWN5UmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9s
aWNpZXMudjFiZXRhMS5EYXRhUG9saWN5InCC0+STAlAyQS92MWJldGExL3tkYXRhX3BvbGlj
eS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVzLyp9OgtkYXRhX3Bv
bGljedpBF2RhdGFfcG9saWN5LHVwZGF0ZV9tYXNrErUBChBEZWxldGVEYXRhUG9saWN5EkMu
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MWJldGExLkRlbGV0ZURhdGFQ
b2xpY3lSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkSC0+STAjcqNS92MWJldGEx
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVzLyp92kEEbmFtZRLP
AQoNR2V0RGF0YVBvbGljeRJALmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMu
djFiZXRhMS5HZXREYXRhUG9saWN5UmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5k
YXRhcG9saWNpZXMudjFiZXRhMS5EYXRhUG9saWN5IkSC0+STAjcSNS92MWJldGExL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVBvbGljaWVzLyp92kEEbmFtZRLlAQoQTGlz
dERhdGFQb2xpY2llcxJDLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5kYXRhcG9saWNpZXMudjFi
ZXRhMS5MaXN0RGF0YVBvbGljaWVzUmVxdWVzdBpELmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5k
YXRhcG9saWNpZXMudjFiZXRhMS5MaXN0RGF0YVBvbGljaWVzUmVzcG9uc2UiRoLT5JMCNxI1
L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kYXRhUG9saWNpZXPa
QQZwYXJlbnQSnAEKDEdldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuR2V0SWFtUG9saWN5
UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IlGC0+STAksiRi92MWJldGExL3tyZXNv
dXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xpY2llcy8qfTpnZXRJYW1Qb2xp
Y3k6ASoSnAEKDFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuU2V0SWFtUG9saWN5UmVx
dWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IlGC0+STAksiRi92MWJldGExL3tyZXNvdXJj
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFQb2xpY2llcy8qfTpzZXRJYW1Qb2xpY3k6
ASoSwgEKElRlc3RJYW1QZXJtaXNzaW9ucxIoLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1p
c3Npb25zUmVxdWVzdBopLmdvb2dsZS5pYW0udjEuVGVzdElhbVBlcm1pc3Npb25zUmVzcG9u
c2UiV4LT5JMCUSJML3YxYmV0YTEve3Jlc291cmNlPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGF0YVBvbGljaWVzLyp9OnRlc3RJYW1QZXJtaXNzaW9uczoBKhp+ykEhYmlncXVlcnlkYXRh
cG9saWN5Lmdvb2dsZWFwaXMuY29t0kFXaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9iaWdxdWVyeSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtQqICCi5jb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LmRhdGFwb2xpY2llcy52MWJldGEx
Qg9EYXRhUG9saWN5UHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS9kYXRh
cG9saWNpZXMvYXBpdjFiZXRhMS9kYXRhcG9saWNpZXNwYjtkYXRhcG9saWNpZXNwYqoCKkdv
b2dsZS5DbG91ZC5CaWdRdWVyeS5EYXRhUG9saWNpZXMuVjFCZXRhMcoCKkdvb2dsZVxDbG91
ZFxCaWdRdWVyeVxEYXRhUG9saWNpZXNcVjFiZXRhMeoCLkdvb2dsZTo6Q2xvdWQ6OkJpZ3F1
ZXJ5OjpEYXRhUG9saWNpZXM6OlYxYmV0YTFKjkEKBxIFDgCeAgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADMKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkK
AgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAoCgkKAgMFEgMXACQKCQoCAwYSAxgAJQoJ
CgIDBxIDGQAqCggKAQgSAxsARwoJCgIIJRIDGwBHCggKAQgSAxwAaQoJCgIICxIDHABpCggK
AQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4AMAoJCgIICBIDHgAwCggKAQgSAx8ARwoJCgII
ARIDHwBHCggKAQgSAyAASAoJCgIIKRIDIABICggKAQgSAyEARwoJCgIILRIDIQBHClcKAgYA
EgQkAG0BGksgRGF0YSBQb2xpY3kgU2VydmljZSBwcm92aWRlcyBBUElzIGZvciBtYW5hZ2lu
ZyB0aGUgbGFiZWwtcG9saWN5IGJpbmRpbmdzLgoKCgoDBgABEgMkCBkKCgoDBgADEgMlAkkK
DAoFBgADmQgSAyUCSQoLCgMGAAMSBCYCKDcKDQoFBgADmggSBCYCKDcKlwEKBAYAAgASBCwC
MgMaiAEgQ3JlYXRlcyBhIG5ldyBkYXRhIHBvbGljeSB1bmRlciBhIHByb2plY3Qgd2l0aCB0
aGUgZ2l2ZW4gYGRhdGFQb2xpY3lJZGAKICh1c2VkIGFzIHRoZSBkaXNwbGF5IG5hbWUpLCBw
b2xpY3kgdGFnLCBhbmQgZGF0YSBwb2xpY3kgdHlwZS4KCgwKBQYAAgABEgMsBhYKDAoFBgAC
AAISAywXLgoMCgUGAAIAAxIDLDlDCg0KBQYAAgAEEgQtBDAGChEKCQYAAgAEsMq8IhIELQQw
BgoMCgUGAAIABBIDMQRACg8KCAYAAgAEmwgAEgMxBEAKgAEKBAYAAgESBDYCPAMaciBVcGRh
dGVzIHRoZSBtZXRhZGF0YSBmb3IgYW4gZXhpc3RpbmcgZGF0YSBwb2xpY3kuIFRoZSB0YXJn
ZXQgZGF0YSBwb2xpY3kKIGNhbiBiZSBzcGVjaWZpZWQgYnkgdGhlIHJlc291cmNlIG5hbWUu
CgoMCgUGAAIBARIDNgYWCgwKBQYAAgECEgM2Fy4KDAoFBgACAQMSAzY5QwoNCgUGAAIBBBIE
NwQ6BgoRCgkGAAIBBLDKvCISBDcEOgYKDAoFBgACAQQSAzsERQoPCggGAAIBBJsIABIDOwRF
CkcKBAYAAgISBD8CRAMaOSBEZWxldGVzIHRoZSBkYXRhIHBvbGljeSBzcGVjaWZpZWQgYnkg
aXRzIHJlc291cmNlIG5hbWUuCgoMCgUGAAICARIDPwYWCgwKBQYAAgICEgM/Fy4KDAoFBgAC
AgMSAz85TgoNCgUGAAICBBIEQARCBgoRCgkGAAICBLDKvCISBEAEQgYKDAoFBgACAgQSA0ME
MgoPCggGAAICBJsIABIDQwQyCkQKBAYAAgMSBEcCTAMaNiBHZXRzIHRoZSBkYXRhIHBvbGlj
eSBzcGVjaWZpZWQgYnkgaXRzIHJlc291cmNlIG5hbWUuCgoMCgUGAAIDARIDRwYTCgwKBQYA
AgMCEgNHFCgKDAoFBgACAwMSA0czPQoNCgUGAAIDBBIESARKBgoRCgkGAAIDBLDKvCISBEgE
SgYKDAoFBgACAwQSA0sEMgoPCggGAAIDBJsIABIDSwQyCk4KBAYAAgQSBE8CVAMaQCBMaXN0
IGFsbCBvZiB0aGUgZGF0YSBwb2xpY2llcyBpbiB0aGUgc3BlY2lmaWVkIHBhcmVudCBwcm9q
ZWN0LgoKDAoFBgACBAESA08GFgoMCgUGAAIEAhIDTxcuCgwKBQYAAgQDEgNPOVEKDQoFBgAC
BAQSBFAEUgYKEQoJBgACBASwyrwiEgRQBFIGCgwKBQYAAgQEEgNTBDQKDwoIBgACBASbCAAS
A1MENApCCgQGAAIFEgRXAlwDGjQgR2V0cyB0aGUgSUFNIHBvbGljeSBmb3IgdGhlIHNwZWNp
ZmllZCBkYXRhIHBvbGljeS4KCgwKBQYAAgUBEgNXBhIKDAoFBgACBQISA1cTNAoMCgUGAAIF
AxIDVz9TCg0KBQYAAgUEEgRYBFsGChEKCQYAAgUEsMq8IhIEWARbBgpCCgQGAAIGEgRfAmQD
GjQgU2V0cyB0aGUgSUFNIHBvbGljeSBmb3IgdGhlIHNwZWNpZmllZCBkYXRhIHBvbGljeS4K
CgwKBQYAAgYBEgNfBhIKDAoFBgACBgISA18TNAoMCgUGAAIGAxIDXz9TCg0KBQYAAgYEEgRg
BGMGChEKCQYAAgYEsMq8IhIEYARjBgpWCgQGAAIHEgRnAmwDGkggUmV0dXJucyB0aGUgY2Fs
bGVyJ3MgcGVybWlzc2lvbiBvbiB0aGUgc3BlY2lmaWVkIGRhdGEgcG9saWN5IHJlc291cmNl
LgoKDAoFBgACBwESA2cGGAoMCgUGAAIHAhIDZxlACgwKBQYAAgcDEgNnS3MKDQoFBgACBwQS
BGgEawYKEQoJBgACBwSwyrwiEgRoBGsGCj4KAgQAEgRwAH0BGjIgUmVxdWVzdCBtZXNzYWdl
IGZvciB0aGUgQ3JlYXRlRGF0YVBvbGljeSBtZXRob2QuCgoKCgMEAAESA3AIHwqgAQoEBAAC
ABIEcwJ4BBqRASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJvamVjdCB0aGF0
IHRoZSBkYXRhIHBvbGljeSB3aWxsIGJlbG9uZyB0by4gVGhlCiBmb3JtYXQgaXMgYHByb2pl
Y3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH1gLgoKDAoFBAAC
AAUSA3MCCAoMCgUEAAIAARIDcwkPCgwKBQQAAgADEgNzEhMKDQoFBAACAAgSBHMUeAMKDwoI
BAACAAicCAASA3QEKgoPCgcEAAIACJ8IEgR1BHcFCoABCgQEAAIBEgN8AkYacyBSZXF1aXJl
ZC4gVGhlIGRhdGEgcG9saWN5IHRvIGNyZWF0ZS4gVGhlIGBuYW1lYCBmaWVsZCBkb2VzIG5v
dCBuZWVkIHRvIGJlCiBwcm92aWRlZCBmb3IgdGhlIGRhdGEgcG9saWN5IGNyZWF0aW9uLgoK
DAoFBAACAQYSA3wCDAoMCgUEAAIBARIDfA0YCgwKBQQAAgEDEgN8GxwKDAoFBAACAQgSA3wd
RQoPCggEAAIBCJwIABIDfB5ECkEKAgQBEgaAAQCOAQEaMyBSZXNwb25zZSBtZXNzYWdlIGZv
ciB0aGUgVXBkYXRlRGF0YVBvbGljeSBtZXRob2QuCgoLCgMEAQESBIABCB8KxQEKBAQBAgAS
BIUBAkYatgEgUmVxdWlyZWQuIFVwZGF0ZSB0aGUgZGF0YSBwb2xpY3kncyBtZXRhZGF0YS4K
CiBUaGUgdGFyZ2V0IGRhdGEgcG9saWN5IGlzIGRldGVybWluZWQgYnkgdGhlIGBuYW1lYCBm
aWVsZC4KIE90aGVyIGZpZWxkcyBhcmUgdXBkYXRlZCB0byB0aGUgc3BlY2lmaWVkIHZhbHVl
cyBiYXNlZCBvbiB0aGUgZmllbGQgbWFza3MuCgoNCgUEAQIABhIEhQECDAoNCgUEAQIAARIE
hQENGAoNCgUEAQIAAxIEhQEbHAoNCgUEAQIACBIEhQEdRQoQCggEAQIACJwIABIEhQEeRArB
AgoEBAECARIEjQECLBqyAiBUaGUgdXBkYXRlIG1hc2sgYXBwbGllcyB0byB0aGUgcmVzb3Vy
Y2UuIEZvciB0aGUgYEZpZWxkTWFza2AgZGVmaW5pdGlvbiwKIHNlZQogaHR0cHM6Ly9kZXZl
bG9wZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29n
bGUucHJvdG9idWYjZmllbGRtYXNrCiBJZiBub3Qgc2V0LCBkZWZhdWx0cyB0byBhbGwgb2Yg
dGhlIGZpZWxkcyB0aGF0IGFyZSBhbGxvd2VkIHRvIHVwZGF0ZS4KCiBVcGRhdGVzIHRvIHRo
ZSBgbmFtZWAgYW5kIGBkYXRhUG9saWN5SWRgIGZpZWxkcyBhcmUgbm90IGFsbG93ZWQuCgoN
CgUEAQIBBhIEjQECGwoNCgUEAQIBARIEjQEcJwoNCgUEAQIBAxIEjQEqKwpACgIEAhIGkQEA
mgEBGjIgUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgRGVsZXRlRGF0YVBvbGljeSBtZXRob2Qu
CgoLCgMEAgESBJEBCB8KpgEKBAQCAgASBpQBApkBBBqVASBSZXF1aXJlZC4gUmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZGF0YSBwb2xpY3kgdG8gZGVsZXRlLiBGb3JtYXQgaXMKIGBwcm9qZWN0
cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2RhdGFQb2xpY2ll
cy97ZGF0YV9wb2xpY3lfaWR9YC4KCg0KBQQCAgAFEgSUAQIICg0KBQQCAgABEgSUAQkNCg0K
BQQCAgADEgSUARARCg8KBQQCAgAIEgaUARKZAQMKEAoIBAICAAicCAASBJUBBCoKEQoHBAIC
AAifCBIGlgEEmAEFCj0KAgQDEgadAQCmAQEaLyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBH
ZXREYXRhUG9saWN5IG1ldGhvZC4KCgsKAwQDARIEnQEIHAqmAQoEBAMCABIGoAECpQEEGpUB
IFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSByZXF1ZXN0ZWQgZGF0YSBwb2xpY3ku
IEZvcm1hdCBpcwogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2Nh
dGlvbl9pZH0vZGF0YVBvbGljaWVzL3tkYXRhX3BvbGljeV9pZH1gLgoKDQoFBAMCAAUSBKAB
AggKDQoFBAMCAAESBKABCQ0KDQoFBAMCAAMSBKABEBEKDwoFBAMCAAgSBqABEqUBAwoQCggE
AwIACJwIABIEoQEEKgoRCgcEAwIACJ8IEgaiAQSkAQUKQAoCBAQSBqkBALsBARoyIFJlcXVl
c3QgbWVzc2FnZSBmb3IgdGhlIExpc3REYXRhUG9saWNpZXMgbWV0aG9kLgoKCwoDBAQBEgSp
AQgfCpoBCgQEBAIAEgasAQKxAQQaiQEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhl
IHByb2plY3QgZm9yIHdoaWNoIHRvIGxpc3QgZGF0YSBwb2xpY2llcy4gRm9ybWF0IGlzCiBg
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfWAuCgoN
CgUEBAIABRIErAECCAoNCgUEBAIAARIErAEJDwoNCgUEBAIAAxIErAESEwoPCgUEBAIACBIG
rAEUsQEDChAKCAQEAgAInAgAEgStAQQqChEKBwQEAgAInwgSBq4BBLABBQqAAQoEBAQCARIE
tgECFhpyIFRoZSBtYXhpbXVtIG51bWJlciBvZiBkYXRhIHBvbGljaWVzIHRvIHJldHVybi4g
TXVzdCBiZSBhIHZhbHVlIGJldHdlZW4gMQogYW5kIDEwMDAuCiBJZiBub3Qgc2V0LCBkZWZh
dWx0cyB0byA1MC4KCg0KBQQEAgEFEgS2AQIHCg0KBQQEAgEBEgS2AQgRCg0KBQQEAgEDEgS2
ARQVCoIBCgQEBAICEgS6AQIYGnQgVGhlIGBuZXh0UGFnZVRva2VuYCB2YWx1ZSByZXR1cm5l
ZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBhbnkuIElmCiBub3Qgc2V0LCBk
ZWZhdWx0cyB0byBhbiBlbXB0eSBzdHJpbmcuCgoNCgUEBAICBRIEugECCAoNCgUEBAICARIE
ugEJEwoNCgUEBAICAxIEugEWFwpBCgIEBRIGvgEAxQEBGjMgUmVzcG9uc2UgbWVzc2FnZSBm
b3IgdGhlIExpc3REYXRhUG9saWNpZXMgbWV0aG9kLgoKCwoDBAUBEgS+AQggCkMKBAQFAgAS
BMABAigaNSBEYXRhIHBvbGljaWVzIHRoYXQgYmVsb25nIHRvIHRoZSByZXF1ZXN0ZWQgcHJv
amVjdC4KCg0KBQQFAgAEEgTAAQIKCg0KBQQFAgAGEgTAAQsVCg0KBQQFAgABEgTAARYjCg0K
BQQFAgADEgTAASYnCmgKBAQFAgESBMQBAh0aWiBUb2tlbiB1c2VkIHRvIHJldHJpZXZlIHRo
ZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3Jl
IHJlc3VsdHMuCgoNCgUEBQIBBRIExAECCAoNCgUEBQIBARIExAEJGAoNCgUEBQIBAxIExAEb
HAo0CgIEBhIGyAEA8wEBGiYgUmVwcmVzZW50cyB0aGUgbGFiZWwtcG9saWN5IGJpbmRpbmcu
CgoLCgMEBgESBMgBCBIKDQoDBAYHEgbJAQLMAQQKDwoFBAYHnQgSBskBAswBBAo4CgQEBgQA
EgbPAQLZAQMaKCBBIGxpc3Qgb2Ygc3VwcG9ydGVkIGRhdGEgcG9saWN5IHR5cGVzLgoKDQoF
BAYEAAESBM8BBxUKUgoGBAYEAAIAEgTRAQQlGkIgRGVmYXVsdCB2YWx1ZSBmb3IgdGhlIGRh
dGEgcG9saWN5IHR5cGUuIFRoaXMgc2hvdWxkIG5vdCBiZSB1c2VkLgoKDwoHBAYEAAIAARIE
0QEEIAoPCgcEBgQAAgACEgTRASMkCmAKBgQGBAACARIE1QEEJRpQIFVzZWQgdG8gY3JlYXRl
IGEgZGF0YSBwb2xpY3kgZm9yIGNvbHVtbi1sZXZlbCBzZWN1cml0eSwgd2l0aG91dCBkYXRh
CiBtYXNraW5nLgoKDwoHBAYEAAIBARIE1QEEIAoPCgcEBgQAAgECEgTVASMkCkAKBgQGBAAC
AhIE2AEEHBowIFVzZWQgdG8gY3JlYXRlIGEgZGF0YSBwb2xpY3kgZm9yIGRhdGEgbWFza2lu
Zy4KCg8KBwQGBAACAgESBNgBBBcKDwoHBAYEAAICAhIE2AEaGwo6CgQEBggAEgbcAQLgAQMa
KiBMYWJlbCB0aGF0IGlzIGJvdW5kIHRvIHRoaXMgZGF0YSBwb2xpY3kuCgoNCgUEBggAARIE
3AEIFgqkAQoEBAYCABIE3wEEGhqVASBQb2xpY3kgdGFnIHJlc291cmNlIG5hbWUsIGluIHRo
ZSBmb3JtYXQgb2YKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9j
YXRpb25faWR9L3RheG9ub21pZXMve3RheG9ub215X2lkfS9wb2xpY3lUYWdzL3twb2xpY3lU
YWdfaWR9YC4KCg0KBQQGAgAFEgTfAQQKCg0KBQQGAgABEgTfAQsVCg0KBQQGAgADEgTfARgZ
Cj8KBAQGCAESBuMBAuYBAxovIFRoZSBwb2xpY3kgdGhhdCBpcyBib3VuZCB0byB0aGlzIGRh
dGEgcG9saWN5LgoKDQoFBAYIAQESBOMBCA4KVAoEBAYCARIE5QEELhpGIFRoZSBkYXRhIG1h
c2tpbmcgcG9saWN5IHRoYXQgc3BlY2lmaWVzIHRoZSBkYXRhIG1hc2tpbmcgcnVsZSB0byB1
c2UuCgoNCgUEBgIBBhIE5QEEFQoNCgUEBgIBARIE5QEWKQoNCgUEBgIBAxIE5QEsLQqlAQoE
BAYCAhIE6gECPhqWASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbmFtZSBvZiB0aGlzIGRhdGEg
cG9saWN5LCBpbiB0aGUgZm9ybWF0IG9mCiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9s
b2NhdGlvbnMve2xvY2F0aW9uX2lkfS9kYXRhUG9saWNpZXMve2RhdGFfcG9saWN5X2lkfWAu
CgoNCgUEBgICBRIE6gECCAoNCgUEBgICARIE6gEJDQoNCgUEBgICAxIE6gEQEQoNCgUEBgIC
CBIE6gESPQoQCggEBgICCJwIABIE6gETPAokCgQEBgIDEgTtAQImGhYgVHlwZSBvZiBkYXRh
IHBvbGljeS4KCg0KBQQGAgMGEgTtAQIQCg0KBQQGAgMBEgTtAREhCg0KBQQGAgMDEgTtASQl
CqgBCgQEBgIEEgTyAQIcGpkBIFVzZXItYXNzaWduZWQgKGh1bWFuIHJlYWRhYmxlKSBJRCBv
ZiB0aGUgZGF0YSBwb2xpY3kgdGhhdCBuZWVkcyB0byBiZQogdW5pcXVlIHdpdGhpbiBhIHBy
b2plY3QuIFVzZWQgYXMge2RhdGFfcG9saWN5X2lkfSBpbiBwYXJ0IG9mIHRoZSByZXNvdXJj
ZQogbmFtZS4KCg0KBQQGAgQFEgTyAQIICg0KBQQGAgQBEgTyAQkXCg0KBQQGAgQDEgTyARob
ClIKAgQHEgb2AQCeAgEaRCBUaGUgZGF0YSBtYXNraW5nIHBvbGljeSB0aGF0IGlzIHVzZWQg
dG8gc3BlY2lmeSBkYXRhIG1hc2tpbmcgcnVsZS4KCgsKAwQHARIE9gEIGQqTAQoEBAcEABIG
+QEClwIDGoIBIFRoZSBhdmFpbGFibGUgbWFza2luZyBydWxlcy4gTGVhcm4gbW9yZSBoZXJl
OgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpZ3F1ZXJ5L2RvY3MvY29sdW1uLWRhdGEt
bWFza2luZy1pbnRybyNtYXNraW5nX29wdGlvbnMuCgoNCgUEBwQAARIE+QEHGwp7CgYEBwQA
AgASBPwBBCoaayBEZWZhdWx0LCB1bnNwZWNpZmllZCBwcmVkZWZpbmVkIGV4cHJlc3Npb24u
IE5vIG1hc2tpbmcgd2lsbCB0YWtlIHBsYWNlCiBzaW5jZSBubyBleHByZXNzaW9uIGlzIHNw
ZWNpZmllZC4KCg8KBwQHBAACAAESBPwBBCUKDwoHBAcEAAIAAhIE/AEoKQpHCgYEBwQAAgES
BP8BBA8aNyBNYXNraW5nIGV4cHJlc3Npb24gdG8gcmVwbGFjZSBkYXRhIHdpdGggU0hBLTI1
NiBoYXNoLgoKDwoHBAcEAAIBARIE/wEECgoPCgcEBwQAAgECEgT/AQ0OCkAKBgQHBAACAhIE
ggIEFBowIE1hc2tpbmcgZXhwcmVzc2lvbiB0byByZXBsYWNlIGRhdGEgd2l0aCBOVUxMcy4K
Cg8KBwQHBAACAgESBIICBA8KDwoHBAcEAAICAhIEggISEwq4AwoGBAcEAAIDEgSWAgQeGqcD
IE1hc2tpbmcgZXhwcmVzc2lvbiB0byByZXBsYWNlIGRhdGEgd2l0aCB0aGVpciBkZWZhdWx0
IG1hc2tpbmcgdmFsdWVzLgogVGhlIGRlZmF1bHQgbWFza2luZyB2YWx1ZXMgZm9yIGVhY2gg
dHlwZSBsaXN0ZWQgYXMgYmVsb3c6CgogKiBTVFJJTkc6ICIiCiAqIEJZVEVTOiBiJycKICog
SU5URUdFUjogMAogKiBGTE9BVDogMC4wCiAqIE5VTUVSSUM6IDAKICogQk9PTEVBTjogRkFM
U0UKICogVElNRVNUQU1QOiAwMDAxLTAxLTAxIDAwOjAwOjAwIFVUQwogKiBEQVRFOiAwMDAx
LTAxLTAxCiAqIFRJTUU6IDAwOjAwOjAwCiAqIERBVEVUSU1FOiAwMDAxLTAxLTAxVDAwOjAw
OjAwCiAqIEdFT0dSQVBIWTogUE9JTlQoMCAwKQogKiBCSUdOVU1FUklDOiAwCiAqIEFSUkFZ
OiBbXQogKiBTVFJVQ1Q6IE5PVF9BUFBMSUNBQkxFCiAqIEpTT046IE5VTEwKCg8KBwQHBAAC
AwESBJYCBBkKDwoHBAcEAAIDAhIElgIcHQpICgQEBwgAEgaaAgKdAgMaOCBBIG1hc2tpbmcg
ZXhwcmVzc2lvbiB0byBiaW5kIHRvIHRoZSBkYXRhIG1hc2tpbmcgcnVsZS4KCg0KBQQHCAAB
EgSaAggaCjAKBAQHAgASBJwCBDMaIiBBIHByZWRlZmluZWQgbWFza2luZyBleHByZXNzaW9u
LgoKDQoFBAcCAAYSBJwCBBgKDQoFBAcCAAESBJwCGS4KDQoFBAcCAAMSBJwCMTJiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::CreateDataPolicyRequest ===
    # Fields for CreateDataPolicyRequest
    # Field: parent Type: 9 ()
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v1beta1.DataPolicy)

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::UpdateDataPolicyRequest ===
    # Fields for UpdateDataPolicyRequest
    # Field: data_policy Type: 11 (.google.cloud.bigquery.datapolicies.v1beta1.DataPolicy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DeleteDataPolicyRequest ===
    # Fields for DeleteDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::GetDataPolicyRequest ===
    # Fields for GetDataPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::ListDataPoliciesRequest ===
    # Fields for ListDataPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::ListDataPoliciesResponse ===
    # Fields for ListDataPoliciesResponse
    # Field: data_policies Type: 11 (.google.cloud.bigquery.datapolicies.v1beta1.DataPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy ===
    # Fields for DataPolicy
    # Field: policy_tag Type: 9 ()
    # Field: data_masking_policy Type: 11 (.google.cloud.bigquery.datapolicies.v1beta1.DataMaskingPolicy)
    # Field: name Type: 9 ()
    # Field: data_policy_type Type: 14 (.google.cloud.bigquery.datapolicies.v1beta1.DataPolicy.DataPolicyType)
    # Field: data_policy_id Type: 9 ()

# Enum: DataPolicy::DataPolicyType
our $DataPolicy_DATA_POLICY_TYPE_UNSPECIFIED = 0;
our $DataPolicy_COLUMN_LEVEL_SECURITY_POLICY = 3;
our $DataPolicy_DATA_MASKING_POLICY = 2;

# === Message: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataMaskingPolicy ===
    # Fields for DataMaskingPolicy
    # Field: predefined_expression Type: 14 (.google.cloud.bigquery.datapolicies.v1beta1.DataMaskingPolicy.PredefinedExpression)

# Enum: DataMaskingPolicy::PredefinedExpression
our $DataMaskingPolicy_PREDEFINED_EXPRESSION_UNSPECIFIED = 0;
our $DataMaskingPolicy_SHA256 = 3;
our $DataMaskingPolicy_ALWAYS_NULL = 5;
our $DataMaskingPolicy_DEFAULT_MASKING_VALUE = 7;

# === Service Client: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicyServiceClient ===
package Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicyServiceClient

Client stub representing the remote C<DataPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub create_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::CreateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'CreateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy',
    });
}

sub update_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::UpdateDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'UpdateDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy',
    });
}

sub delete_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DeleteDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'DeleteDataPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_data_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::GetDataPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'GetDataPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy',
    });
}

sub list_data_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::ListDataPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'ListDataPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::ListDataPoliciesResponse',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.datapolicies.v1beta1.DataPolicyService',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy - Compiled Protocol Buffers messages for google/cloud/bigquery/datapolicies/v1beta1/datapolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy;

    my $msg = Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::CreateDataPolicyRequest->new({
        parent => $parent,
        data_policy => $data_policy,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::CreateDataPolicyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/datapolicies/v1beta1/datapolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::CreateDataPolicyRequest

Request message for the CreateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project that the data policy will belong to. The
format is `projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy>)

Required. The data policy to create. The `name` field does not need to be
provided for the data policy creation.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::UpdateDataPolicyRequest

Response message for the UpdateDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policy() >> / C<< $msg->data_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy>)

Required. Update the data policy's metadata.

The target data policy is determined by the `name` field.
Other fields are updated to the specified values based on the field masks.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
If not set, defaults to all of the fields that are allowed to update.

Updates to the `name` and `dataPolicyId` fields are not allowed.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DeleteDataPolicyRequest

Request message for the DeleteDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the data policy to delete. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::GetDataPolicyRequest

Request message for the GetDataPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the requested data policy. Format is
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::ListDataPoliciesRequest

Request message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the project for which to list data policies. Format is
`projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of data policies to return. Must be a value between 1
and 1000.
If not set, defaults to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The `nextPageToken` value returned from a previous list request, if any. If
not set, defaults to an empty string.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::ListDataPoliciesResponse

Response message for the ListDataPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_policies() >> / C<< $msg->data_policies($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy>)

Data policies that belong to the requested project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token used to retrieve the next page of results, or empty if there are no
more results.

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataPolicy

Represents the label-policy binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_tag() >> / C<< $msg->policy_tag($value) >>

Type: C<String>

Policy tag resource name, in the format of
`projects/{project_number}/locations/{location_id}/taxonomies/{taxonomy_id}/policyTags/{policyTag_id}`.

=item * C<< $msg->data_masking_policy() >> / C<< $msg->data_masking_policy($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataMaskingPolicy>)

The data masking policy that specifies the data masking rule to use.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of this data policy, in the format of
`projects/{project_number}/locations/{location_id}/dataPolicies/{data_policy_id}`.

=item * C<< $msg->data_policy_type() >> / C<< $msg->data_policy_type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V1beta1::DataPolicy::DataPolicyType>)

Type of data policy.

=item * C<< $msg->data_policy_id() >> / C<< $msg->data_policy_id($value) >>

Type: C<String>

User-assigned (human readable) ID of the data policy that needs to be
unique within a project. Used as {data_policy_id} in part of the resource
name.

=back

=head3 Enum: DataPolicy::DataPolicyType

=over 4

=item * C<DATA_POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<COLUMN_LEVEL_SECURITY_POLICY> => C<3>

=item * C<DATA_MASKING_POLICY> => C<2>

=back

=head2 Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::DataMaskingPolicy

The data masking policy that is used to specify data masking rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->predefined_expression() >> / C<< $msg->predefined_expression($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Datapolicies::V1beta1::DataMaskingPolicy::PredefinedExpression>)

A predefined masking expression.

=back

=head3 Enum: DataMaskingPolicy::PredefinedExpression

=over 4

=item * C<PREDEFINED_EXPRESSION_UNSPECIFIED> => C<0>

=item * C<SHA256> => C<3>

=item * C<ALWAYS_NULL> => C<5>

=item * C<DEFAULT_MASKING_VALUE> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Datapolicies::V1beta1::Datapolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
