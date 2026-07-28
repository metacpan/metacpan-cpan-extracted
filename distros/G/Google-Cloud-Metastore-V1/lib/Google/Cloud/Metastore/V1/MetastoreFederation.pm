package Google::Cloud::Metastore::V1::MetastoreFederation;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Metastore::V1::Metastore };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvbWV0YXN0b3JlL3YxL21ldGFzdG9yZV9mZWRlcmF0aW9uLnByb3Rv
Ehlnb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxopZ29vZ2xlL2Nsb3VkL21ldGFz
dG9yZS92MS9tZXRhc3RvcmUucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25z
LnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9m
aWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqwHCgpG
ZWRlcmF0aW9uEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRh
dGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRl
VGltZRJJCgZsYWJlbHMYBCADKAsyMS5nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxLkZlZGVy
YXRpb24uTGFiZWxzRW50cnlSBmxhYmVscxIdCgd2ZXJzaW9uGAUgASgJQgPgQQVSB3ZlcnNp
b24SawoSYmFja2VuZF9tZXRhc3RvcmVzGAYgAygLMjwuZ29vZ2xlLmNsb3VkLm1ldGFzdG9y
ZS52MS5GZWRlcmF0aW9uLkJhY2tlbmRNZXRhc3RvcmVzRW50cnlSEWJhY2tlbmRNZXRhc3Rv
cmVzEiYKDGVuZHBvaW50X3VyaRgHIAEoCUID4EEDUgtlbmRwb2ludFVyaRJGCgVzdGF0ZRgI
IAEoDjIrLmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjEuRmVkZXJhdGlvbi5TdGF0ZUID4EED
UgVzdGF0ZRIoCg1zdGF0ZV9tZXNzYWdlGAkgASgJQgPgQQNSDHN0YXRlTWVzc2FnZRIVCgN1
aWQYCiABKAlCA+BBA1IDdWlkGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAEacQoWQmFja2VuZE1ldGFzdG9yZXNFbnRyeRIQCgNr
ZXkYASABKAVSA2tleRJBCgV2YWx1ZRgCIAEoCzIrLmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUu
djEuQmFja2VuZE1ldGFzdG9yZVIFdmFsdWU6AjgBIl8KBVN0YXRlEhUKEVNUQVRFX1VOU1BF
Q0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIMCghVUERBVElORxADEgwKCERF
TEVUSU5HEAQSCQoFRVJST1IQBTpq6kFnCiNtZXRhc3RvcmUuZ29vZ2xlYXBpcy5jb20vRmVk
ZXJhdGlvbhJAcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2ZlZGVy
YXRpb25zL3tmZWRlcmF0aW9ufSLfAQoQQmFja2VuZE1ldGFzdG9yZRISCgRuYW1lGAEgASgJ
UgRuYW1lEmAKDm1ldGFzdG9yZV90eXBlGAIgASgOMjkuZ29vZ2xlLmNsb3VkLm1ldGFzdG9y
ZS52MS5CYWNrZW5kTWV0YXN0b3JlLk1ldGFzdG9yZVR5cGVSDW1ldGFzdG9yZVR5cGUiVQoN
TWV0YXN0b3JlVHlwZRIeChpNRVRBU1RPUkVfVFlQRV9VTlNQRUNJRklFRBAAEgwKCEJJR1FV
RVJZEAISFgoSREFUQVBST0NfTUVUQVNUT1JFEAMi4AEKFkxpc3RGZWRlcmF0aW9uc1JlcXVl
c3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI21ldGFzdG9yZS5nb29nbGVhcGlzLmNvbS9G
ZWRlcmF0aW9uUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIK
CnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEB
UgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSKsAQoXTGlzdEZlZGVy
YXRpb25zUmVzcG9uc2USRwoLZmVkZXJhdGlvbnMYASADKAsyJS5nb29nbGUuY2xvdWQubWV0
YXN0b3JlLnYxLkZlZGVyYXRpb25SC2ZlZGVyYXRpb25zEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUi
VwoUR2V0RmVkZXJhdGlvblJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNtZXRhc3Rv
cmUuZ29vZ2xlYXBpcy5jb20vRmVkZXJhdGlvblIEbmFtZSL4AQoXQ3JlYXRlRmVkZXJhdGlv
blJlcXVlc3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI21ldGFzdG9yZS5nb29nbGVhcGlz
LmNvbS9GZWRlcmF0aW9uUgZwYXJlbnQSKAoNZmVkZXJhdGlvbl9pZBgCIAEoCUID4EECUgxm
ZWRlcmF0aW9uSWQSSgoKZmVkZXJhdGlvbhgDIAEoCzIlLmdvb2dsZS5jbG91ZC5tZXRhc3Rv
cmUudjEuRmVkZXJhdGlvbkID4EECUgpmZWRlcmF0aW9uEiIKCnJlcXVlc3RfaWQYBCABKAlC
A+BBAVIJcmVxdWVzdElkIssBChdVcGRhdGVGZWRlcmF0aW9uUmVxdWVzdBJACgt1cGRhdGVf
bWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFz
axJKCgpmZWRlcmF0aW9uGAIgASgLMiUuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MS5GZWRl
cmF0aW9uQgPgQQJSCmZlZGVyYXRpb24SIgoKcmVxdWVzdF9pZBgDIAEoCUID4EEBUglyZXF1
ZXN0SWQifgoXRGVsZXRlRmVkZXJhdGlvblJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kEl
CiNtZXRhc3RvcmUuZ29vZ2xlYXBpcy5jb20vRmVkZXJhdGlvblIEbmFtZRIiCgpyZXF1ZXN0
X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZDLcCQobRGF0YXByb2NNZXRhc3RvcmVGZWRlcmF0
aW9uEroBCg9MaXN0RmVkZXJhdGlvbnMSMS5nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxLkxp
c3RGZWRlcmF0aW9uc1JlcXVlc3QaMi5nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxLkxpc3RG
ZWRlcmF0aW9uc1Jlc3BvbnNlIkCC0+STAjESLy92MS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyp9L2ZlZGVyYXRpb25z2kEGcGFyZW50EqcBCg1HZXRGZWRlcmF0aW9uEi8uZ29v
Z2xlLmNsb3VkLm1ldGFzdG9yZS52MS5HZXRGZWRlcmF0aW9uUmVxdWVzdBolLmdvb2dsZS5j
bG91ZC5tZXRhc3RvcmUudjEuRmVkZXJhdGlvbiI+gtPkkwIxEi8vdjEve25hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9mZWRlcmF0aW9ucy8qfdpBBG5hbWUSiQIKEENyZWF0ZUZlZGVy
YXRpb24SMi5nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxLkNyZWF0ZUZlZGVyYXRpb25SZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKhAYLT5JMCPSIvL3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZmVkZXJhdGlvbnM6CmZlZGVyYXRpb27aQR9w
YXJlbnQsZmVkZXJhdGlvbixmZWRlcmF0aW9uX2lkykE5CgpGZWRlcmF0aW9uEitnb29nbGUu
Y2xvdWQubWV0YXN0b3JlLnYxLk9wZXJhdGlvbk1ldGFkYXRhEosCChBVcGRhdGVGZWRlcmF0
aW9uEjIuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MS5VcGRhdGVGZWRlcmF0aW9uUmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iowGC0+STAkgyOi92MS97ZmVkZXJh
dGlvbi5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZmVkZXJhdGlvbnMvKn06CmZlZGVy
YXRpb27aQRZmZWRlcmF0aW9uLHVwZGF0ZV9tYXNrykE5CgpGZWRlcmF0aW9uEitnb29nbGUu
Y2xvdWQubWV0YXN0b3JlLnYxLk9wZXJhdGlvbk1ldGFkYXRhEu0BChBEZWxldGVGZWRlcmF0
aW9uEjIuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MS5EZWxldGVGZWRlcmF0aW9uUmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ihQGC0+STAjEqLy92MS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2ZlZGVyYXRpb25zLyp92kEEbmFtZcpBRAoVZ29vZ2xl
LnByb3RvYnVmLkVtcHR5Eitnb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxLk9wZXJhdGlvbk1l
dGFkYXRhGkzKQRhtZXRhc3RvcmUuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQngKHWNvbS5nb29nbGUuY2xvdWQubWV0
YXN0b3JlLnYxQhhNZXRhc3RvcmVGZWRlcmF0aW9uUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNv
bS9nby9tZXRhc3RvcmUvYXBpdjEvbWV0YXN0b3JlcGI7bWV0YXN0b3JlcGJK32YKBxIFDgD1
AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACIKCQoCAwAS
AxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAzCgkKAgMF
EgMXAC0KCQoCAwYSAxgAJQoJCgIDBxIDGQAqCgkKAgMIEgMaACkKCAoBCBIDHABSCgkKAggL
EgMcAFIKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgA5CgkKAggIEgMeADkKCAoBCBID
HwA2CgkKAggBEgMfADYK7QUKAgYAEgQuAGwBGuAFIENvbmZpZ3VyZXMgYW5kIG1hbmFnZXMg
bWV0YXN0b3JlIGZlZGVyYXRpb24gc2VydmljZXMuCiBEYXRhcHJvYyBNZXRhc3RvcmUgRmVk
ZXJhdGlvbiBTZXJ2aWNlIGFsbG93cyBmZWRlcmF0aW5nIGEgY29sbGVjdGlvbiBvZgogYmFj
a2VuZCBtZXRhc3RvcmVzIGxpa2UgQmlnUXVlcnksIERhdGFwbGV4IExha2VzLCBhbmQgb3Ro
ZXIgRGF0YXByb2MKIE1ldGFzdG9yZXMuIFRoZSBGZWRlcmF0aW9uIFNlcnZpY2UgZXhwb3Nl
cyBhIGdSUEMgVVJMIHRocm91Z2ggd2hpY2ggbWV0YWRhdGEKIGZyb20gdGhlIGJhY2tlbmQg
bWV0YXN0b3JlcyBhcmUgc2VydmVkIGF0IHF1ZXJ5IHRpbWUuCgogVGhlIERhdGFwcm9jIE1l
dGFzdG9yZSBGZWRlcmF0aW9uIEFQSSBkZWZpbmVzIHRoZSBmb2xsb3dpbmcgcmVzb3VyY2Ug
bW9kZWw6CiAqIFRoZSBzZXJ2aWNlIHdvcmtzIHdpdGggYSBjb2xsZWN0aW9uIG9mIEdvb2ds
ZSBDbG91ZCBwcm9qZWN0cy4KICogRWFjaCBwcm9qZWN0IGhhcyBhIGNvbGxlY3Rpb24gb2Yg
YXZhaWxhYmxlIGxvY2F0aW9ucy4KICogRWFjaCBsb2NhdGlvbiBoYXMgYSBjb2xsZWN0aW9u
IG9mIGZlZGVyYXRpb25zLgogKiBEYXRhcHJvYyBNZXRhc3RvcmUgRmVkZXJhdGlvbnMgYXJl
IHJlc291cmNlcyB3aXRoIG5hbWVzIG9mIHRoZQogZm9ybToKIGBwcm9qZWN0cy97cHJvamVj
dF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2ZlZGVyYXRpb25zL3tmZWRlcmF0
aW9uX2lkfWAuCgoKCgMGAAESAy4IIwoKCgMGAAMSAy8CQAoMCgUGAAOZCBIDLwJACgsKAwYA
AxIEMAIxNwoNCgUGAAOaCBIEMAIxNwo8CgQGAAIAEgQ0AjoDGi4gTGlzdHMgZmVkZXJhdGlv
bnMgaW4gYSBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgM0BhUKDAoFBgACAAIS
AzQWLAoMCgUGAAIAAxIDNQ8mCg0KBQYAAgAEEgQ2BDgGChEKCQYAAgAEsMq8IhIENgQ4BgoM
CgUGAAIABBIDOQQ0Cg8KCAYAAgAEmwgAEgM5BDQKOAoEBgACARIEPQJCAxoqIEdldHMgdGhl
IGRldGFpbHMgb2YgYSBzaW5nbGUgZmVkZXJhdGlvbi4KCgwKBQYAAgEBEgM9BhMKDAoFBgAC
AQISAz0UKAoMCgUGAAIBAxIDPTM9Cg0KBQYAAgEEEgQ+BEAGChEKCQYAAgEEsMq8IhIEPgRA
BgoMCgUGAAIBBBIDQQQyCg8KCAYAAgEEmwgAEgNBBDIKSQoEBgACAhIERQJQAxo7IENyZWF0
ZXMgYSBtZXRhc3RvcmUgZmVkZXJhdGlvbiBpbiBhIHByb2plY3QgYW5kIGxvY2F0aW9uLgoK
DAoFBgACAgESA0UGFgoMCgUGAAICAhIDRRcuCgwKBQYAAgIDEgNGDysKDQoFBgACAgQSBEcE
SgYKEQoJBgACAgSwyrwiEgRHBEoGCgwKBQYAAgIEEgNLBE0KDwoIBgACAgSbCAASA0sETQoN
CgUGAAICBBIETARPBgoPCgcGAAICBJkIEgRMBE8GCjMKBAYAAgMSBFMCXgMaJSBVcGRhdGVz
IHRoZSBmaWVsZHMgb2YgYSBmZWRlcmF0aW9uLgoKDAoFBgACAwESA1MGFgoMCgUGAAIDAhID
UxcuCgwKBQYAAgMDEgNUDysKDQoFBgACAwQSBFUEWAYKEQoJBgACAwSwyrwiEgRVBFgGCgwK
BQYAAgMEEgNZBEQKDwoIBgACAwSbCAASA1kERAoNCgUGAAIDBBIEWgRdBgoPCgcGAAIDBJkI
EgRaBF0GCiwKBAYAAgQSBGECawMaHiBEZWxldGVzIGEgc2luZ2xlIGZlZGVyYXRpb24uCgoM
CgUGAAIEARIDYQYWCgwKBQYAAgQCEgNhFy4KDAoFBgACBAMSA2IPKwoNCgUGAAIEBBIEYwRl
BgoRCgkGAAIEBLDKvCISBGMEZQYKDAoFBgACBAQSA2YEMgoPCggGAAIEBJsIABIDZgQyCg0K
BQYAAgQEEgRnBGoGCg8KBwYAAgQEmQgSBGcEagYKRgoCBAASBW8AtQEBGjkgUmVwcmVzZW50
cyBhIGZlZGVyYXRpb24gb2YgbXVsdGlwbGUgYmFja2VuZCBtZXRhc3RvcmVzLgoKCgoDBAAB
EgNvCBIKCwoDBAAHEgRwAnMECg0KBQQAB50IEgRwAnMECjUKBAQABAASBXYCigEDGiYgVGhl
IGN1cnJlbnQgc3RhdGUgb2YgdGhlIGZlZGVyYXRpb24uCgoMCgUEAAQAARIDdgcMCkIKBgQA
BAACABIDeAQaGjMgVGhlIHN0YXRlIG9mIHRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiBpcyB1
bmtub3duLgoKDgoHBAAEAAIAARIDeAQVCg4KBwQABAACAAISA3gYGQpNCgYEAAQAAgESA3sE
ERo+IFRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiBpcyBpbiB0aGUgcHJvY2VzcyBvZiBiZWlu
ZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDewQMCg4KBwQABAACAQISA3sPEApQCgYEAAQAAgIS
A34EDxpBIFRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiBpcyBydW5uaW5nIGFuZCByZWFkeSB0
byBzZXJ2ZSBxdWVyaWVzLgoKDgoHBAAEAAICARIDfgQKCg4KBwQABAACAgISA34NDgqZAQoG
BAAEAAIDEgSCAQQRGogBIFRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiBpcyBiZWluZyB1cGRh
dGVkLiBJdCByZW1haW5zIHVzYWJsZSBidXQgY2Fubm90CiBhY2NlcHQgYWRkaXRpb25hbCB1
cGRhdGUgcmVxdWVzdHMgb3IgYmUgZGVsZXRlZCBhdCB0aGlzIHRpbWUuCgoPCgcEAAQAAgMB
EgSCAQQMCg8KBwQABAACAwISBIIBDxAKVQoGBAAEAAIEEgSFAQQRGkUgVGhlIG1ldGFzdG9y
ZSBmZWRlcmF0aW9uIGlzIHVuZGVyZ29pbmcgZGVsZXRpb24uIEl0IGNhbm5vdCBiZSB1c2Vk
LgoKDwoHBAAEAAIEARIEhQEEDAoPCgcEAAQAAgQCEgSFAQ8QCoQBCgYEAAQAAgUSBIkBBA4a
dCBUaGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gaGFzIGVuY291bnRlcmVkIGFuIGVycm9yIGFu
ZCBjYW5ub3QgYmUgdXNlZC4gVGhlCiBtZXRhc3RvcmUgZmVkZXJhdGlvbiBzaG91bGQgYmUg
ZGVsZXRlZC4KCg8KBwQABAACBQESBIkBBAkKDwoHBAAEAAIFAhIEiQEMDQqoAQoEBAACABIE
jwECPBqZASBJbW11dGFibGUuIFRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBm
ZWRlcmF0aW9uLCBvZiB0aGUKIGZvcm06CiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xv
Y2F0aW9ucy97bG9jYXRpb25faWR9L2ZlZGVyYXRpb25zL3tmZWRlcmF0aW9uX2lkfWAuCgoN
CgUEAAIABRIEjwECCAoNCgUEAAIAARIEjwEJDQoNCgUEAAIAAxIEjwEQEQoNCgUEAAIACBIE
jwESOwoQCggEAAIACJwIABIEjwETOgpSCgQEAAIBEgaSAQKTATIaQiBPdXRwdXQgb25seS4g
VGhlIHRpbWUgd2hlbiB0aGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoN
CgUEAAIBBhIEkgECGwoNCgUEAAIBARIEkgEcJwoNCgUEAAIBAxIEkgEqKwoNCgUEAAIBCBIE
kwEGMQoQCggEAAIBCJwIABIEkwEHMApXCgQEAAICEgaWAQKXATIaRyBPdXRwdXQgb25seS4g
VGhlIHRpbWUgd2hlbiB0aGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gd2FzIGxhc3QgdXBkYXRl
ZC4KCg0KBQQAAgIGEgSWAQIbCg0KBQQAAgIBEgSWARwnCg0KBQQAAgIDEgSWASorCg0KBQQA
AgIIEgSXAQYxChAKCAQAAgIInAgAEgSXAQcwCkEKBAQAAgMSBJoBAiEaMyBVc2VyLWRlZmlu
ZWQgbGFiZWxzIGZvciB0aGUgbWV0YXN0b3JlIGZlZGVyYXRpb24uCgoNCgUEAAIDBhIEmgEC
FQoNCgUEAAIDARIEmgEWHAoNCgUEAAIDAxIEmgEfIAqgAQoEBAACBBIEngECPxqRASBJbW11
dGFibGUuIFRoZSBBcGFjaGUgSGl2ZSBtZXRhc3RvcmUgdmVyc2lvbiBvZiB0aGUgZmVkZXJh
dGlvbi4gQWxsIGJhY2tlbmQKIG1ldGFzdG9yZSB2ZXJzaW9ucyBtdXN0IGJlIGNvbXBhdGli
bGUgd2l0aCB0aGUgZmVkZXJhdGlvbiB2ZXJzaW9uLgoKDQoFBAACBAUSBJ4BAggKDQoFBAAC
BAESBJ4BCRAKDQoFBAACBAMSBJ4BExQKDQoFBAACBAgSBJ4BFT4KEAoIBAACBAicCAASBJ4B
Fj0KpAMKBAQAAgUSBKYBAjYalQMgQSBtYXAgZnJvbSBgQmFja2VuZE1ldGFzdG9yZWAgcmFu
ayB0byBgQmFja2VuZE1ldGFzdG9yZWBzIGZyb20gd2hpY2ggdGhlCiBmZWRlcmF0aW9uIHNl
cnZpY2Ugc2VydmVzIG1ldGFkYXRhIGF0IHF1ZXJ5IHRpbWUuIFRoZSBtYXAga2V5IHJlcHJl
c2VudHMKIHRoZSBvcmRlciBpbiB3aGljaCBgQmFja2VuZE1ldGFzdG9yZWBzIHNob3VsZCBi
ZSBldmFsdWF0ZWQgdG8gcmVzb2x2ZQogZGF0YWJhc2UgbmFtZXMgYXQgcXVlcnkgdGltZSBh
bmQgc2hvdWxkIGJlIGdyZWF0ZXIgdGhhbiBvciBlcXVhbCB0byB6ZXJvLiBBCiBgQmFja2Vu
ZE1ldGFzdG9yZWAgd2l0aCBhIGxvd2VyIG51bWJlciB3aWxsIGJlIGV2YWx1YXRlZCBiZWZv
cmUgYQogYEJhY2tlbmRNZXRhc3RvcmVgIHdpdGggYSBoaWdoZXIgbnVtYmVyLgoKDQoFBAAC
BQYSBKYBAh4KDQoFBAACBQESBKYBHzEKDQoFBAACBQMSBKYBNDUKNQoEBAACBhIEqQECRhon
IE91dHB1dCBvbmx5LiBUaGUgZmVkZXJhdGlvbiBlbmRwb2ludC4KCg0KBQQAAgYFEgSpAQII
Cg0KBQQAAgYBEgSpAQkVCg0KBQQAAgYDEgSpARgZCg0KBQQAAgYIEgSpARpFChAKCAQAAgYI
nAgAEgSpARtECkEKBAQAAgcSBKwBAj4aMyBPdXRwdXQgb25seS4gVGhlIGN1cnJlbnQgc3Rh
dGUgb2YgdGhlIGZlZGVyYXRpb24uCgoNCgUEAAIHBhIErAECBwoNCgUEAAIHARIErAEIDQoN
CgUEAAIHAxIErAEQEQoNCgUEAAIHCBIErAESPQoQCggEAAIHCJwIABIErAETPAp3CgQEAAII
EgSwAQJHGmkgT3V0cHV0IG9ubHkuIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gYWJvdXQgdGhl
IGN1cnJlbnQgc3RhdGUgb2YgdGhlCiBtZXRhc3RvcmUgZmVkZXJhdGlvbiwgaWYgYXZhaWxh
YmxlLgoKDQoFBAACCAUSBLABAggKDQoFBAACCAESBLABCRYKDQoFBAACCAMSBLABGRoKDQoF
BAACCAgSBLABG0YKEAoIBAACCAicCAASBLABHEUKYgoEBAACCRIEtAECPhpUIE91dHB1dCBv
bmx5LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIHJlc291cmNlIGlkZW50aWZpZXIgb2YgdGhlIG1l
dGFzdG9yZQogZmVkZXJhdGlvbi4KCg0KBQQAAgkFEgS0AQIICg0KBQQAAgkBEgS0AQkMCg0K
BQQAAgkDEgS0AQ8RCg0KBQQAAgkIEgS0ARI9ChAKCAQAAgkInAgAEgS0ARM8CkIKAgQBEga4
AQDRAQEaNCBSZXByZXNlbnRzIGEgYmFja2VuZCBtZXRhc3RvcmUgZm9yIHRoZSBmZWRlcmF0
aW9uLgoKCwoDBAEBEgS4AQgYCjQKBAQBBAASBroBAsMBAxokIFRoZSB0eXBlIG9mIHRoZSBi
YWNrZW5kIG1ldGFzdG9yZS4KCg0KBQQBBAABEgS6AQcUCjAKBgQBBAACABIEvAEEIxogIFRo
ZSBtZXRhc3RvcmUgdHlwZSBpcyBub3Qgc2V0LgoKDwoHBAEEAAIAARIEvAEEHgoPCgcEAQQA
AgACEgS8ASEiCjQKBgQBBAACARIEvwEEERokIFRoZSBiYWNrZW5kIG1ldGFzdG9yZSBpcyBC
aWdRdWVyeS4KCg8KBwQBBAACAQESBL8BBAwKDwoHBAEEAAIBAhIEvwEPEAo+CgYEAQQAAgIS
BMIBBBsaLiBUaGUgYmFja2VuZCBtZXRhc3RvcmUgaXMgRGF0YXByb2MgTWV0YXN0b3JlLgoK
DwoHBAEEAAICARIEwgEEFgoPCgcEAQQAAgICEgTCARkaCscCCgQEAQIAEgTNAQISGrgCIFRo
ZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtZXRhc3RvcmUgdGhhdCBpcyBiZWlu
ZyBmZWRlcmF0ZWQuCiBUaGUgZm9ybWF0cyBvZiB0aGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFt
ZXMgZm9yIHRoZSBjdXJyZW50bHkgc3VwcG9ydGVkCiBtZXRhc3RvcmVzIGFyZSBsaXN0ZWQg
YmVsb3c6CgogKiBCaWdRdWVyeQogICAgICogYHByb2plY3RzL3twcm9qZWN0X2lkfWAKICog
RGF0YXByb2MgTWV0YXN0b3JlCiAgICAgKiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0
aW9ucy97bG9jYXRpb259L3NlcnZpY2VzL3tzZXJ2aWNlX2lkfWAKCg0KBQQBAgAFEgTNAQII
Cg0KBQQBAgABEgTNAQkNCg0KBQQBAgADEgTNARARCjIKBAQBAgESBNABAiMaJCBUaGUgdHlw
ZSBvZiB0aGUgYmFja2VuZCBtZXRhc3RvcmUuCgoNCgUEAQIBBhIE0AECDwoNCgUEAQIBARIE
0AEQHgoNCgUEAQIBAxIE0AEhIgo0CgIEAhIG1AEA9gEBGiYgUmVxdWVzdCBtZXNzYWdlIGZv
ciBMaXN0RmVkZXJhdGlvbnMuCgoLCgMEAgESBNQBCB4KtwEKBAQCAgASBtgBAt0BBBqmASBS
ZXF1aXJlZC4gVGhlIHJlbGF0aXZlIHJlc291cmNlIG5hbWUgb2YgdGhlIGxvY2F0aW9uIG9m
IG1ldGFzdG9yZQogZmVkZXJhdGlvbnMgdG8gbGlzdCwgaW4gdGhlIGZvbGxvd2luZyBmb3Jt
OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH1g
LgoKDQoFBAICAAUSBNgBAggKDQoFBAICAAESBNgBCQ8KDQoFBAICAAMSBNgBEhMKDwoFBAIC
AAgSBtgBFN0BAwoQCggEAgIACJwIABIE2QEEKgoRCgcEAgIACJ8IEgbaAQTcAQUK+wEKBAQC
AgESBOMBAj8a7AEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBmZWRlcmF0aW9u
cyB0byByZXR1cm4uIFRoZSByZXNwb25zZSBtYXkKIGNvbnRhaW4gbGVzcyB0aGFuIHRoZSBt
YXhpbXVtIG51bWJlci4gSWYgdW5zcGVjaWZpZWQsIG5vIG1vcmUgdGhhbiA1MDAKIHNlcnZp
Y2VzIGFyZSByZXR1cm5lZC4gVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFi
b3ZlIDEwMDAgYXJlCiBjaGFuZ2VkIHRvIDEwMDAuCgoNCgUEAgIBBRIE4wECBwoNCgUEAgIB
ARIE4wEIEQoNCgUEAgIBAxIE4wEUFQoNCgUEAgIBCBIE4wEWPgoQCggEAgIBCJwIABIE4wEX
PQrIAgoEBAICAhIE7QECQRq5AiBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBm
cm9tIGEgcHJldmlvdXMgTGlzdEZlZGVyYXRpb25TZXJ2aWNlcwogY2FsbC4gUHJvdmlkZSB0
aGlzIHRva2VuIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogVG8gcmV0cmll
dmUgdGhlIGZpcnN0IHBhZ2UsIHN1cHBseSBhbiBlbXB0eSBwYWdlIHRva2VuLgoKIFdoZW4g
cGFnaW5hdGluZywgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogTGlzdEZlZGVyYXRp
b25TZXJ2aWNlcyBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlCiBwYWdl
IHRva2VuLgoKDQoFBAICAgUSBO0BAggKDQoFBAICAgESBO0BCRMKDQoFBAICAgMSBO0BFhcK
DQoFBAICAggSBO0BGEAKEAoIBAICAgicCAASBO0BGT8KPgoEBAICAxIE8AECPRowIE9wdGlv
bmFsLiBUaGUgZmlsdGVyIHRvIGFwcGx5IHRvIGxpc3QgcmVzdWx0cy4KCg0KBQQCAgMFEgTw
AQIICg0KBQQCAgMBEgTwAQkPCg0KBQQCAgMDEgTwARITCg0KBQQCAgMIEgTwARQ8ChAKCAQC
AgMInAgAEgTwARU7CuQBCgQEAgIEEgT1AQI/GtUBIE9wdGlvbmFsLiBTcGVjaWZ5IHRoZSBv
cmRlcmluZyBvZiByZXN1bHRzIGFzIGRlc2NyaWJlZCBpbiBbU29ydGluZwogT3JkZXJdKGh0
dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9kZXNpZ25fcGF0dGVybnMjc29y
dGluZ19vcmRlcikuCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgcmVzdWx0cyB3aWxsIGJlIHNv
cnRlZCBpbiB0aGUgZGVmYXVsdCBvcmRlci4KCg0KBQQCAgQFEgT1AQIICg0KBQQCAgQBEgT1
AQkRCg0KBQQCAgQDEgT1ARQVCg0KBQQCAgQIEgT1ARY+ChAKCAQCAgQInAgAEgT1ARc9CjQK
AgQDEgb5AQCDAgEaJiBSZXNwb25zZSBtZXNzYWdlIGZvciBMaXN0RmVkZXJhdGlvbnMKCgsK
AwQDARIE+QEIHwo3CgQEAwIAEgT7AQImGikgVGhlIHNlcnZpY2VzIGluIHRoZSBzcGVjaWZp
ZWQgbG9jYXRpb24uCgoNCgUEAwIABBIE+wECCgoNCgUEAwIABhIE+wELFQoNCgUEAwIAARIE
+wEWIQoNCgUEAwIAAxIE+wEkJQqNAQoEBAMCARIE/wECHRp/IEEgdG9rZW4gdGhhdCBjYW4g
YmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4gSWYg
dGhpcwogZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMu
CgoNCgUEAwIBBRIE/wECCAoNCgUEAwIBARIE/wEJGAoNCgUEAwIBAxIE/wEbHAo0CgQEAwIC
EgSCAgIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAwIC
BBIEggICCgoNCgUEAwICBRIEggILEQoNCgUEAwICARIEggISHQoNCgUEAwICAxIEggIgIQoy
CgIEBBIGhgIAkQIBGiQgUmVxdWVzdCBtZXNzYWdlIGZvciBHZXRGZWRlcmF0aW9uLgoKCwoD
BAQBEgSGAggcCssBCgQEBAIAEgaLAgKQAgQaugEgUmVxdWlyZWQuIFRoZSByZWxhdGl2ZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiB0bwogcmV0cmlldmUs
IGluIHRoZSBmb2xsb3dpbmcgZm9ybToKCiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9s
b2NhdGlvbnMve2xvY2F0aW9uX2lkfS9mZWRlcmF0aW9ucy97ZmVkZXJhdGlvbl9pZH1gLgoK
DQoFBAQCAAUSBIsCAggKDQoFBAQCAAESBIsCCQ0KDQoFBAQCAAMSBIsCEBEKDwoFBAQCAAgS
BosCEpACAwoQCggEBAIACJwIABIEjAIEKgoRCgcEBAIACJ8IEgaNAgSPAgUKNQoCBAUSBpQC
ALoCARonIFJlcXVlc3QgbWVzc2FnZSBmb3IgQ3JlYXRlRmVkZXJhdGlvbi4KCgsKAwQFARIE
lAIIHwq/AQoEBAUCABIGmQICngIEGq4BIFJlcXVpcmVkLiBUaGUgcmVsYXRpdmUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgbG9jYXRpb24gaW4gd2hpY2ggdG8gY3JlYXRlIGEKIGZlZGVyYXRp
b24gc2VydmljZSwgaW4gdGhlIGZvbGxvd2luZyBmb3JtOgoKIGBwcm9qZWN0cy97cHJvamVj
dF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9YC4KCg0KBQQFAgAFEgSZAgIICg0K
BQQFAgABEgSZAgkPCg0KBQQFAgADEgSZAhITCg8KBQQFAgAIEgaZAhSeAgMKEAoIBAUCAAic
CAASBJoCBCoKEQoHBAUCAAifCBIGmwIEnQIFCrcCCgQEBQIBEgSmAgJEGqgCIFJlcXVpcmVk
LiBUaGUgSUQgb2YgdGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uLCB3aGljaCBpcyB1c2VkIGFz
IHRoZSBmaW5hbAogY29tcG9uZW50IG9mIHRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbidzIG5h
bWUuCgogVGhpcyB2YWx1ZSBtdXN0IGJlIGJldHdlZW4gMiBhbmQgNjMgY2hhcmFjdGVycyBs
b25nIGluY2x1c2l2ZSwgYmVnaW4gd2l0aCBhCiBsZXR0ZXIsIGVuZCB3aXRoIGEgbGV0dGVy
IG9yIG51bWJlciwgYW5kIGNvbnNpc3Qgb2YgYWxwaGEtbnVtZXJpYwogQVNDSUkgY2hhcmFj
dGVycyBvciBoeXBoZW5zLgoKDQoFBAUCAQUSBKYCAggKDQoFBAUCAQESBKYCCRYKDQoFBAUC
AQMSBKYCGRoKDQoFBAUCAQgSBKYCG0MKEAoIBAUCAQicCAASBKYCHEIKwQEKBAQFAgISBKsC
AkUasgEgUmVxdWlyZWQuIFRoZSBNZXRhc3RvcmUgRmVkZXJhdGlvbiB0byBjcmVhdGUuIFRo
ZSBgbmFtZWAgZmllbGQgaXMKIGlnbm9yZWQuIFRoZSBJRCBvZiB0aGUgY3JlYXRlZCBtZXRh
c3RvcmUgZmVkZXJhdGlvbiBtdXN0IGJlCiBwcm92aWRlZCBpbiB0aGUgcmVxdWVzdCdzIGBm
ZWRlcmF0aW9uX2lkYCBmaWVsZC4KCg0KBQQFAgIGEgSrAgIMCg0KBQQFAgIBEgSrAg0XCg0K
BQQFAgIDEgSrAhobCg0KBQQFAgIIEgSrAhxEChAKCAQFAgIInAgAEgSrAh1DCvkECgQEBQID
EgS5AgJBGuoEIE9wdGlvbmFsLiBBIHJlcXVlc3QgSUQuIFNwZWNpZnkgYSB1bmlxdWUgcmVx
dWVzdCBJRCB0byBhbGxvdyB0aGUgc2VydmVyIHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYg
aXQgaGFzIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsIGlnbm9yZSBzdWJzZXF1ZW50CiBy
ZXF1ZXN0cyB0aGF0IHByb3ZpZGUgYSBkdXBsaWNhdGUgcmVxdWVzdCBJRCBmb3IgYXQgbGVh
c3QgNjAgbWludXRlcyBhZnRlcgogdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUs
IGlmIGFuIGluaXRpYWwgcmVxdWVzdCB0aW1lcyBvdXQsIGZvbGxvd2VkIGJ5IGFub3RoZXIg
cmVxdWVzdAogd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElELCB0aGUgc2VydmVyIGlnbm9yZXMg
dGhlIHNlY29uZCByZXF1ZXN0IHRvIHByZXZlbnQKIHRoZSBjcmVhdGlvbiBvZiBkdXBsaWNh
dGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkCiBbVVVJ
RF0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvVW5pdmVyc2FsbHlfdW5pcXVlX2lk
ZW50aWZpZXIjRm9ybWF0KQogQSB6ZXJvIFVVSUQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAw
LTAwMDAwMDAwMDAwMCkgaXMgbm90IHN1cHBvcnRlZC4KCg0KBQQFAgMFEgS5AgIICg0KBQQF
AgMBEgS5AgkTCg0KBQQFAgMDEgS5AhYXCg0KBQQFAgMIEgS5AhhAChAKCAQFAgMInAgAEgS5
Ahk/CjUKAgQGEga9AgDZAgEaJyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZUZlZGVyYXRp
b24uCgoLCgMEBgESBL0CCB8KmAIKBAQGAgASBsICAsMCLxqHAiBSZXF1aXJlZC4gQSBmaWVs
ZCBtYXNrIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGlu
IHRoZQogbWV0YXN0b3JlIGZlZGVyYXRpb24gcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIEZp
ZWxkcyBzcGVjaWZpZWQgaW4gdGhlIGB1cGRhdGVfbWFza2AgYXJlIHJlbGF0aXZlIHRvIHRo
ZSByZXNvdXJjZSAobm90CiB0byB0aGUgZnVsbCByZXF1ZXN0KS4gQSBmaWVsZCBpcyBvdmVy
d3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4KCg0KBQQGAgAGEgTCAgIbCg0KBQQGAgAB
EgTCAhwnCg0KBQQGAgADEgTCAiorCg0KBQQGAgAIEgTDAgYuChAKCAQGAgAInAgAEgTDAgct
CvgBCgQEBgIBEgTKAgJFGukBIFJlcXVpcmVkLiBUaGUgbWV0YXN0b3JlIGZlZGVyYXRpb24g
dG8gdXBkYXRlLiBUaGUgc2VydmVyIG9ubHkgbWVyZ2VzIGZpZWxkcwogaW4gdGhlIHNlcnZp
Y2UgaWYgdGhleSBhcmUgc3BlY2lmaWVkIGluIGB1cGRhdGVfbWFza2AuCgogVGhlIG1ldGFz
dG9yZSBmZWRlcmF0aW9uJ3MgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhl
CiBtZXRhc3RvcmUgc2VydmljZSB0byBiZSB1cGRhdGVkLgoKDQoFBAYCAQYSBMoCAgwKDQoF
BAYCAQESBMoCDRcKDQoFBAYCAQMSBMoCGhsKDQoFBAYCAQgSBMoCHEQKEAoIBAYCAQicCAAS
BMoCHUMK+QQKBAQGAgISBNgCAkEa6gQgT3B0aW9uYWwuIEEgcmVxdWVzdCBJRC4gU3BlY2lm
eSBhIHVuaXF1ZSByZXF1ZXN0IElEIHRvIGFsbG93IHRoZSBzZXJ2ZXIgdG8KIGlnbm9yZSB0
aGUgcmVxdWVzdCBpZiBpdCBoYXMgY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwgaWdub3Jl
IHN1YnNlcXVlbnQKIHJlcXVlc3RzIHRoYXQgcHJvdmlkZSBhIGR1cGxpY2F0ZSByZXF1ZXN0
IElEIGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIGFmdGVyCiB0aGUgZmlyc3QgcmVxdWVzdC4K
CiBGb3IgZXhhbXBsZSwgaWYgYW4gaW5pdGlhbCByZXF1ZXN0IHRpbWVzIG91dCwgZm9sbG93
ZWQgYnkgYW5vdGhlciByZXF1ZXN0CiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQsIHRoZSBz
ZXJ2ZXIgaWdub3JlcyB0aGUgc2Vjb25kIHJlcXVlc3QgdG8gcHJldmVudAogdGhlIGNyZWF0
aW9uIG9mIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJl
IGEgdmFsaWQKIFtVVUlEXShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJz
YWxseV91bmlxdWVfaWRlbnRpZmllciNGb3JtYXQpCiBBIHplcm8gVVVJRCAoMDAwMDAwMDAt
MDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKSBpcyBub3Qgc3VwcG9ydGVkLgoKDQoFBAYC
AgUSBNgCAggKDQoFBAYCAgESBNgCCRMKDQoFBAYCAgMSBNgCFhcKDQoFBAYCAggSBNgCGEAK
EAoIBAYCAgicCAASBNgCGT8KNQoCBAcSBtwCAPUCARonIFJlcXVlc3QgbWVzc2FnZSBmb3Ig
RGVsZXRlRmVkZXJhdGlvbi4KCgsKAwQHARIE3AIIHwrJAQoEBAcCABIG4QIC5gIEGrgBIFJl
cXVpcmVkLiBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbWV0YXN0b3JlIGZl
ZGVyYXRpb24gdG8gZGVsZXRlLAogaW4gdGhlIGZvbGxvd2luZyBmb3JtOgoKIGBwcm9qZWN0
cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2ZlZGVyYXRpb25z
L3tmZWRlcmF0aW9uX2lkfWAuCgoNCgUEBwIABRIE4QICCAoNCgUEBwIAARIE4QIJDQoNCgUE
BwIAAxIE4QIQEQoPCgUEBwIACBIG4QIS5gIDChAKCAQHAgAInAgAEgTiAgQqChEKBwQHAgAI
nwgSBuMCBOUCBQr5BAoEBAcCARIE9AICQRrqBCBPcHRpb25hbC4gQSByZXF1ZXN0IElELiBT
cGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQgdG8gYWxsb3cgdGhlIHNlcnZlciB0bwogaWdu
b3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbCBp
Z25vcmUgc3Vic2VxdWVudAogcmVxdWVzdHMgdGhhdCBwcm92aWRlIGEgZHVwbGljYXRlIHJl
cXVlc3QgSUQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgYWZ0ZXIKIHRoZSBmaXJzdCByZXF1
ZXN0LgoKIEZvciBleGFtcGxlLCBpZiBhbiBpbml0aWFsIHJlcXVlc3QgdGltZXMgb3V0LCBm
b2xsb3dlZCBieSBhbm90aGVyIHJlcXVlc3QKIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRCwg
dGhlIHNlcnZlciBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdCB0byBwcmV2ZW50CiB0aGUg
Y3JlYXRpb24gb2YgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11
c3QgYmUgYSB2YWxpZAogW1VVSURdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1Vu
aXZlcnNhbGx5X3VuaXF1ZV9pZGVudGlmaWVyI0Zvcm1hdCkKIEEgemVybyBVVUlEICgwMDAw
MDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApIGlzIG5vdCBzdXBwb3J0ZWQuCgoN
CgUEBwIBBRIE9AICCAoNCgUEBwIBARIE9AIJEwoNCgUEBwIBAxIE9AIWFwoNCgUEBwIBCBIE
9AIYQAoQCggEBwIBCJwIABIE9AIZP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::Federation ===
    # Fields for Federation
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.metastore.v1.Federation.LabelsEntry)
    # Field: version Type: 9 ()
    # Field: backend_metastores Type: 11 (.google.cloud.metastore.v1.Federation.BackendMetastoresEntry)
    # Field: endpoint_uri Type: 9 ()
    # Field: state Type: 14 (.google.cloud.metastore.v1.Federation.State)
    # Field: state_message Type: 9 ()
    # Field: uid Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::Federation - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::Federation->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<labels>

Type: Message (.google.cloud.metastore.v1.Federation.LabelsEntry)

=item * B<version>

Type: String

=item * B<backend_metastores>

Type: Message (.google.cloud.metastore.v1.Federation.BackendMetastoresEntry)

=item * B<endpoint_uri>

Type: String

=item * B<state>

Type: Enum (.google.cloud.metastore.v1.Federation.State)

=item * B<state_message>

Type: String

=item * B<uid>

Type: String

=back

=cut

# Enum: Federation::State
our $Federation_STATE_UNSPECIFIED = 0;
our $Federation_CREATING = 1;
our $Federation_ACTIVE = 2;
our $Federation_UPDATING = 3;
our $Federation_DELETING = 4;
our $Federation_ERROR = 5;

=pod

=head2 Enum: Federation::State

Values:

=over 4

=item * C<STATE_UNSPECIFIED> => 0

=item * C<CREATING> => 1

=item * C<ACTIVE> => 2

=item * C<UPDATING> => 3

=item * C<DELETING> => 4

=item * C<ERROR> => 5

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::BackendMetastore ===
    # Fields for BackendMetastore
    # Field: name Type: 9 ()
    # Field: metastore_type Type: 14 (.google.cloud.metastore.v1.BackendMetastore.MetastoreType)

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::BackendMetastore - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::BackendMetastore->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<metastore_type>

Type: Enum (.google.cloud.metastore.v1.BackendMetastore.MetastoreType)

=back

=cut

# Enum: BackendMetastore::MetastoreType
our $BackendMetastore_METASTORE_TYPE_UNSPECIFIED = 0;
our $BackendMetastore_BIGQUERY = 2;
our $BackendMetastore_DATAPROC_METASTORE = 3;

=pod

=head2 Enum: BackendMetastore::MetastoreType

Values:

=over 4

=item * C<METASTORE_TYPE_UNSPECIFIED> => 0

=item * C<BIGQUERY> => 2

=item * C<DATAPROC_METASTORE> => 3

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsRequest ===
    # Fields for ListFederationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<filter>

Type: String

=item * B<order_by>

Type: String

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsResponse ===
    # Fields for ListFederationsResponse
    # Field: federations Type: 11 (.google.cloud.metastore.v1.Federation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsResponse->new(
        federations => $value,
    );

=head1 FIELDS

=over 4

=item * B<federations>

Type: Message (.google.cloud.metastore.v1.Federation)

=item * B<next_page_token>

Type: String

=item * B<unreachable>

Type: String

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::GetFederationRequest ===
    # Fields for GetFederationRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::GetFederationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::GetFederationRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::CreateFederationRequest ===
    # Fields for CreateFederationRequest
    # Field: parent Type: 9 ()
    # Field: federation_id Type: 9 ()
    # Field: federation Type: 11 (.google.cloud.metastore.v1.Federation)
    # Field: request_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::CreateFederationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::CreateFederationRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<federation_id>

Type: String

=item * B<federation>

Type: Message (.google.cloud.metastore.v1.Federation)

=item * B<request_id>

Type: String

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::UpdateFederationRequest ===
    # Fields for UpdateFederationRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: federation Type: 11 (.google.cloud.metastore.v1.Federation)
    # Field: request_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::UpdateFederationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::UpdateFederationRequest->new(
        update_mask => $value,
    );

=head1 FIELDS

=over 4

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=item * B<federation>

Type: Message (.google.cloud.metastore.v1.Federation)

=item * B<request_id>

Type: String

=back

=cut

# === Message: Google::Cloud::Metastore::V1::MetastoreFederation::DeleteFederationRequest ===
    # Fields for DeleteFederationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::DeleteFederationRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1::MetastoreFederation::DeleteFederationRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<request_id>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Metastore::V1::MetastoreFederation::DataprocMetastoreFederationClient ===
package Google::Cloud::Metastore::V1::MetastoreFederation::DataprocMetastoreFederationClient;

=pod

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation::DataprocMetastoreFederationClient - Client stub representing the remote DataprocMetastoreFederation service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<metastore.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'metastore.googleapis.com:443' );

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

sub list_federations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1.DataprocMetastoreFederation',
        method         => 'ListFederations',
        request        => $req,
        response_class => 'Google::Cloud::Metastore::V1::MetastoreFederation::ListFederationsResponse',
    });
}

sub get_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1::MetastoreFederation::GetFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1.DataprocMetastoreFederation',
        method         => 'GetFederation',
        request        => $req,
        response_class => 'Google::Cloud::Metastore::V1::MetastoreFederation::Federation',
    });
}

sub create_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1::MetastoreFederation::CreateFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1.DataprocMetastoreFederation',
        method         => 'CreateFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1::MetastoreFederation::UpdateFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1.DataprocMetastoreFederation',
        method         => 'UpdateFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1::MetastoreFederation::DeleteFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1.DataprocMetastoreFederation',
        method         => 'DeleteFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Metastore::V1::MetastoreFederation - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
