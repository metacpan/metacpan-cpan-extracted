package Google::Spanner::V1::Keys;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Chxnb29nbGUvc3Bhbm5lci92MS9rZXlzLnByb3RvEhFnb29nbGUuc3Bhbm5lci52MRocZ29v
Z2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byKgAgoIS2V5UmFuZ2USPwoMc3RhcnRfY2xvc2Vk
GAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkxpc3RWYWx1ZUgAUgtzdGFydENsb3NlZBI7Cgpz
dGFydF9vcGVuGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkxpc3RWYWx1ZUgAUglzdGFydE9w
ZW4SOwoKZW5kX2Nsb3NlZBgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5MaXN0VmFsdWVIAVIJ
ZW5kQ2xvc2VkEjcKCGVuZF9vcGVuGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLkxpc3RWYWx1
ZUgBUgdlbmRPcGVuQhAKDnN0YXJ0X2tleV90eXBlQg4KDGVuZF9rZXlfdHlwZSJ/CgZLZXlT
ZXQSLgoEa2V5cxgBIAMoCzIaLmdvb2dsZS5wcm90b2J1Zi5MaXN0VmFsdWVSBGtleXMSMwoG
cmFuZ2VzGAIgAygLMhsuZ29vZ2xlLnNwYW5uZXIudjEuS2V5UmFuZ2VSBnJhbmdlcxIQCgNh
bGwYAyABKAhSA2FsbEKsAQoVY29tLmdvb2dsZS5zcGFubmVyLnYxQglLZXlzUHJvdG9QAVo1
Y2xvdWQuZ29vZ2xlLmNvbS9nby9zcGFubmVyL2FwaXYxL3NwYW5uZXJwYjtzcGFubmVycGKq
AhdHb29nbGUuQ2xvdWQuU3Bhbm5lci5WMcoCF0dvb2dsZVxDbG91ZFxTcGFubmVyXFYx6gIa
R29vZ2xlOjpDbG91ZDo6U3Bhbm5lcjo6VjFK/CsKBxIFDgCiAQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABoKCQoCAwASAxIAJgoICgEIEgMUADQKCQoC
CCUSAxQANAoICgEIEgMVAEwKCQoCCAsSAxUATAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXACoKCQoCCAgSAxcAKgoICgEIEgMYAC4KCQoCCAESAxgALgoICgEIEgMZADQKCQoCCCkS
AxkANAoICgEIEgMaADMKCQoCCC0SAxoAMwq1FQoCBAASBXQAigEBGqcVIEtleVJhbmdlIHJl
cHJlc2VudHMgYSByYW5nZSBvZiByb3dzIGluIGEgdGFibGUgb3IgaW5kZXguCgogQSByYW5n
ZSBoYXMgYSBzdGFydCBrZXkgYW5kIGFuIGVuZCBrZXkuIFRoZXNlIGtleXMgY2FuIGJlIG9w
ZW4gb3IKIGNsb3NlZCwgaW5kaWNhdGluZyBpZiB0aGUgcmFuZ2UgaW5jbHVkZXMgcm93cyB3
aXRoIHRoYXQga2V5LgoKIEtleXMgYXJlIHJlcHJlc2VudGVkIGJ5IGxpc3RzLCB3aGVyZSB0
aGUgaXRoIHZhbHVlIGluIHRoZSBsaXN0CiBjb3JyZXNwb25kcyB0byB0aGUgaXRoIGNvbXBv
bmVudCBvZiB0aGUgdGFibGUgb3IgaW5kZXggcHJpbWFyeSBrZXkuCiBJbmRpdmlkdWFsIHZh
bHVlcyBhcmUgZW5jb2RlZCBhcyBkZXNjcmliZWQKIFtoZXJlXVtnb29nbGUuc3Bhbm5lci52
MS5UeXBlQ29kZV0uCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIHRoZSBmb2xsb3dpbmcgdGFi
bGUgZGVmaW5pdGlvbjoKCiAgICAgQ1JFQVRFIFRBQkxFIFVzZXJFdmVudHMgKAogICAgICAg
VXNlck5hbWUgU1RSSU5HKE1BWCksCiAgICAgICBFdmVudERhdGUgU1RSSU5HKDEwKQogICAg
ICkgUFJJTUFSWSBLRVkoVXNlck5hbWUsIEV2ZW50RGF0ZSk7CgogVGhlIGZvbGxvd2luZyBr
ZXlzIG5hbWUgcm93cyBpbiB0aGlzIHRhYmxlOgoKICAgICBbIkJvYiIsICIyMDE0LTA5LTIz
Il0KICAgICBbIkFsZnJlZCIsICIyMDE1LTA2LTEyIl0KCiBTaW5jZSB0aGUgYFVzZXJFdmVu
dHNgIHRhYmxlJ3MgYFBSSU1BUlkgS0VZYCBjbGF1c2UgbmFtZXMgdHdvCiBjb2x1bW5zLCBl
YWNoIGBVc2VyRXZlbnRzYCBrZXkgaGFzIHR3byBlbGVtZW50czsgdGhlIGZpcnN0IGlzIHRo
ZQogYFVzZXJOYW1lYCwgYW5kIHRoZSBzZWNvbmQgaXMgdGhlIGBFdmVudERhdGVgLgoKIEtl
eSByYW5nZXMgd2l0aCBtdWx0aXBsZSBjb21wb25lbnRzIGFyZSBpbnRlcnByZXRlZAogbGV4
aWNvZ3JhcGhpY2FsbHkgYnkgY29tcG9uZW50IHVzaW5nIHRoZSB0YWJsZSBvciBpbmRleCBr
ZXkncyBkZWNsYXJlZAogc29ydCBvcmRlci4gRm9yIGV4YW1wbGUsIHRoZSBmb2xsb3dpbmcg
cmFuZ2UgcmV0dXJucyBhbGwgZXZlbnRzIGZvcgogdXNlciBgIkJvYiJgIHRoYXQgb2NjdXJy
ZWQgaW4gdGhlIHllYXIgMjAxNToKCiAgICAgInN0YXJ0X2Nsb3NlZCI6IFsiQm9iIiwgIjIw
MTUtMDEtMDEiXQogICAgICJlbmRfY2xvc2VkIjogWyJCb2IiLCAiMjAxNS0xMi0zMSJdCgog
U3RhcnQgYW5kIGVuZCBrZXlzIGNhbiBvbWl0IHRyYWlsaW5nIGtleSBjb21wb25lbnRzLiBU
aGlzIGFmZmVjdHMgdGhlCiBpbmNsdXNpb24gYW5kIGV4Y2x1c2lvbiBvZiByb3dzIHRoYXQg
ZXhhY3RseSBtYXRjaCB0aGUgcHJvdmlkZWQga2V5CiBjb21wb25lbnRzOiBpZiB0aGUga2V5
IGlzIGNsb3NlZCwgdGhlbiByb3dzIHRoYXQgZXhhY3RseSBtYXRjaCB0aGUKIHByb3ZpZGVk
IGNvbXBvbmVudHMgYXJlIGluY2x1ZGVkOyBpZiB0aGUga2V5IGlzIG9wZW4sIHRoZW4gcm93
cwogdGhhdCBleGFjdGx5IG1hdGNoIGFyZSBub3QgaW5jbHVkZWQuCgogRm9yIGV4YW1wbGUs
IHRoZSBmb2xsb3dpbmcgcmFuZ2UgaW5jbHVkZXMgYWxsIGV2ZW50cyBmb3IgYCJCb2IiYCB0
aGF0CiBvY2N1cnJlZCBkdXJpbmcgYW5kIGFmdGVyIHRoZSB5ZWFyIDIwMDA6CgogICAgICJz
dGFydF9jbG9zZWQiOiBbIkJvYiIsICIyMDAwLTAxLTAxIl0KICAgICAiZW5kX2Nsb3NlZCI6
IFsiQm9iIl0KCiBUaGUgbmV4dCBleGFtcGxlIHJldHJpZXZlcyBhbGwgZXZlbnRzIGZvciBg
IkJvYiJgOgoKICAgICAic3RhcnRfY2xvc2VkIjogWyJCb2IiXQogICAgICJlbmRfY2xvc2Vk
IjogWyJCb2IiXQoKIFRvIHJldHJpZXZlIGV2ZW50cyBiZWZvcmUgdGhlIHllYXIgMjAwMDoK
CiAgICAgInN0YXJ0X2Nsb3NlZCI6IFsiQm9iIl0KICAgICAiZW5kX29wZW4iOiBbIkJvYiIs
ICIyMDAwLTAxLTAxIl0KCiBUaGUgZm9sbG93aW5nIHJhbmdlIGluY2x1ZGVzIGFsbCByb3dz
IGluIHRoZSB0YWJsZToKCiAgICAgInN0YXJ0X2Nsb3NlZCI6IFtdCiAgICAgImVuZF9jbG9z
ZWQiOiBbXQoKIFRoaXMgcmFuZ2UgcmV0dXJucyBhbGwgdXNlcnMgd2hvc2UgYFVzZXJOYW1l
YCBiZWdpbnMgd2l0aCBhbnkKIGNoYXJhY3RlciBmcm9tIEEgdG8gQzoKCiAgICAgInN0YXJ0
X2Nsb3NlZCI6IFsiQSJdCiAgICAgImVuZF9vcGVuIjogWyJEIl0KCiBUaGlzIHJhbmdlIHJl
dHVybnMgYWxsIHVzZXJzIHdob3NlIGBVc2VyTmFtZWAgYmVnaW5zIHdpdGggQjoKCiAgICAg
InN0YXJ0X2Nsb3NlZCI6IFsiQiJdCiAgICAgImVuZF9vcGVuIjogWyJDIl0KCiBLZXkgcmFu
Z2VzIGhvbm9yIGNvbHVtbiBzb3J0IG9yZGVyLiBGb3IgZXhhbXBsZSwgc3VwcG9zZSBhIHRh
YmxlIGlzCiBkZWZpbmVkIGFzIGZvbGxvd3M6CgogICAgIENSRUFURSBUQUJMRSBEZXNjZW5k
aW5nU29ydGVkVGFibGUgewogICAgICAgS2V5IElOVDY0LAogICAgICAgLi4uCiAgICAgKSBQ
UklNQVJZIEtFWShLZXkgREVTQyk7CgogVGhlIGZvbGxvd2luZyByYW5nZSByZXRyaWV2ZXMg
YWxsIHJvd3Mgd2l0aCBrZXkgdmFsdWVzIGJldHdlZW4gMQogYW5kIDEwMCBpbmNsdXNpdmU6
CgogICAgICJzdGFydF9jbG9zZWQiOiBbIjEwMCJdCiAgICAgImVuZF9jbG9zZWQiOiBbIjEi
XQoKIE5vdGUgdGhhdCAxMDAgaXMgcGFzc2VkIGFzIHRoZSBzdGFydCwgYW5kIDEgaXMgcGFz
c2VkIGFzIHRoZSBlbmQsCiBiZWNhdXNlIGBLZXlgIGlzIGEgZGVzY2VuZGluZyBjb2x1bW4g
aW4gdGhlIHNjaGVtYS4KCgoKAwQAARIDdAgQClAKBAQACAASBHYCfgMaQiBUaGUgc3RhcnQg
a2V5IG11c3QgYmUgcHJvdmlkZWQuIEl0IGNhbiBiZSBlaXRoZXIgY2xvc2VkIG9yIG9wZW4u
CgoMCgUEAAgAARIDdggWCpMBCgQEAAIAEgN5BC8ahQEgSWYgdGhlIHN0YXJ0IGlzIGNsb3Nl
ZCwgdGhlbiB0aGUgcmFuZ2UgaW5jbHVkZXMgYWxsIHJvd3Mgd2hvc2UKIGZpcnN0IGBsZW4o
c3RhcnRfY2xvc2VkKWAga2V5IGNvbHVtbnMgZXhhY3RseSBtYXRjaCBgc3RhcnRfY2xvc2Vk
YC4KCgwKBQQAAgAGEgN5BB0KDAoFBAACAAESA3keKgoMCgUEAAIAAxIDeS0uCogBCgQEAAIB
EgN9BC0aeyBJZiB0aGUgc3RhcnQgaXMgb3BlbiwgdGhlbiB0aGUgcmFuZ2UgZXhjbHVkZXMg
cm93cyB3aG9zZSBmaXJzdAogYGxlbihzdGFydF9vcGVuKWAga2V5IGNvbHVtbnMgZXhhY3Rs
eSBtYXRjaCBgc3RhcnRfb3BlbmAuCgoMCgUEAAIBBhIDfQQdCgwKBQQAAgEBEgN9HigKDAoF
BAACAQMSA30rLApQCgQEAAgBEgaBAQKJAQMaQCBUaGUgZW5kIGtleSBtdXN0IGJlIHByb3Zp
ZGVkLiBJdCBjYW4gYmUgZWl0aGVyIGNsb3NlZCBvciBvcGVuLgoKDQoFBAAIAQESBIEBCBQK
jQEKBAQAAgISBIQBBC0afyBJZiB0aGUgZW5kIGlzIGNsb3NlZCwgdGhlbiB0aGUgcmFuZ2Ug
aW5jbHVkZXMgYWxsIHJvd3Mgd2hvc2UKIGZpcnN0IGBsZW4oZW5kX2Nsb3NlZClgIGtleSBj
b2x1bW5zIGV4YWN0bHkgbWF0Y2ggYGVuZF9jbG9zZWRgLgoKDQoFBAACAgYSBIQBBB0KDQoF
BAACAgESBIQBHigKDQoFBAACAgMSBIQBKywKgwEKBAQAAgMSBIgBBCsadSBJZiB0aGUgZW5k
IGlzIG9wZW4sIHRoZW4gdGhlIHJhbmdlIGV4Y2x1ZGVzIHJvd3Mgd2hvc2UgZmlyc3QKIGBs
ZW4oZW5kX29wZW4pYCBrZXkgY29sdW1ucyBleGFjdGx5IG1hdGNoIGBlbmRfb3BlbmAuCgoN
CgUEAAIDBhIEiAEEHQoNCgUEAAIDARIEiAEeJgoNCgUEAAIDAxIEiAEpKgqGAwoCBAESBpMB
AKIBARr3AiBgS2V5U2V0YCBkZWZpbmVzIGEgY29sbGVjdGlvbiBvZiBDbG91ZCBTcGFubmVy
IGtleXMgYW5kL29yIGtleSByYW5nZXMuIEFsbAogdGhlIGtleXMgYXJlIGV4cGVjdGVkIHRv
IGJlIGluIHRoZSBzYW1lIHRhYmxlIG9yIGluZGV4LiBUaGUga2V5cyBuZWVkCiBub3QgYmUg
c29ydGVkIGluIGFueSBwYXJ0aWN1bGFyIHdheS4KCiBJZiB0aGUgc2FtZSBrZXkgaXMgc3Bl
Y2lmaWVkIG11bHRpcGxlIHRpbWVzIGluIHRoZSBzZXQgKGZvciBleGFtcGxlCiBpZiB0d28g
cmFuZ2VzLCB0d28ga2V5cywgb3IgYSBrZXkgYW5kIGEgcmFuZ2Ugb3ZlcmxhcCksIENsb3Vk
IFNwYW5uZXIKIGJlaGF2ZXMgYXMgaWYgdGhlIGtleSB3ZXJlIG9ubHkgc3BlY2lmaWVkIG9u
Y2UuCgoLCgMEAQESBJMBCA4KigIKBAQBAgASBJgBAi4a+wEgQSBsaXN0IG9mIHNwZWNpZmlj
IGtleXMuIEVudHJpZXMgaW4gYGtleXNgIHNob3VsZCBoYXZlIGV4YWN0bHkgYXMKIG1hbnkg
ZWxlbWVudHMgYXMgdGhlcmUgYXJlIGNvbHVtbnMgaW4gdGhlIHByaW1hcnkgb3IgaW5kZXgg
a2V5CiB3aXRoIHdoaWNoIHRoaXMgYEtleVNldGAgaXMgdXNlZC4gIEluZGl2aWR1YWwga2V5
IHZhbHVlcyBhcmUKIGVuY29kZWQgYXMgZGVzY3JpYmVkIFtoZXJlXVtnb29nbGUuc3Bhbm5l
ci52MS5UeXBlQ29kZV0uCgoNCgUEAQIABBIEmAECCgoNCgUEAQIABhIEmAELJAoNCgUEAQIA
ARIEmAElKQoNCgUEAQIAAxIEmAEsLQqGAQoEBAECARIEnAECHxp4IEEgbGlzdCBvZiBrZXkg
cmFuZ2VzLiBTZWUgW0tleVJhbmdlXVtnb29nbGUuc3Bhbm5lci52MS5LZXlSYW5nZV0gZm9y
IG1vcmUKIGluZm9ybWF0aW9uIGFib3V0IGtleSByYW5nZSBzcGVjaWZpY2F0aW9ucy4KCg0K
BQQBAgEEEgScAQIKCg0KBQQBAgEGEgScAQsTCg0KBQQBAgEBEgScARQaCg0KBQQBAgEDEgSc
AR0eCs4BCgQEAQICEgShAQIPGr8BIEZvciBjb252ZW5pZW5jZSBgYWxsYCBjYW4gYmUgc2V0
IHRvIGB0cnVlYCB0byBpbmRpY2F0ZSB0aGF0IHRoaXMKIGBLZXlTZXRgIG1hdGNoZXMgYWxs
IGtleXMgaW4gdGhlIHRhYmxlIG9yIGluZGV4LiBOb3RlIHRoYXQgYW55IGtleXMKIHNwZWNp
ZmllZCBpbiBga2V5c2Agb3IgYHJhbmdlc2AgYXJlIG9ubHkgeWllbGRlZCBvbmNlLgoKDQoF
BAECAgUSBKEBAgYKDQoFBAECAgESBKEBBwoKDQoFBAECAgMSBKEBDQ5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::V1::Keys::KeyRange ===
    # Fields for KeyRange
    # Field: start_closed Type: 11 (.google.protobuf.ListValue)
    # Field: start_open Type: 11 (.google.protobuf.ListValue)
    # Field: end_closed Type: 11 (.google.protobuf.ListValue)
    # Field: end_open Type: 11 (.google.protobuf.ListValue)

# === Message: Google::Spanner::V1::Keys::KeySet ===
    # Fields for KeySet
    # Field: keys Type: 11 (.google.protobuf.ListValue)
    # Field: ranges Type: 11 (.google.spanner.v1.KeyRange)
    # Field: all Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::V1::Keys - Compiled Protocol Buffers messages for google/spanner/v1/keys.proto

=head1 SYNOPSIS

    use Google::Spanner::V1::Keys;

    my $msg = Google::Spanner::V1::Keys::KeyRange->new({
        start_closed => $start_closed,
        start_open => $start_open,
        end_closed => $end_closed,
        end_open => $end_open,
    });

    # Read or update a field
    my $val = $msg->start_closed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::V1::Keys::KeyRange->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/v1/keys.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::V1::Keys::KeyRange

KeyRange represents a range of rows in a table or index.

A range has a start key and an end key. These keys can be open or
closed, indicating if the range includes rows with that key.

Keys are represented by lists, where the ith value in the list
corresponds to the ith component of the table or index primary key.
Individual values are encoded as described
[here][google.spanner.v1.TypeCode].

For example, consider the following table definition:

    CREATE TABLE UserEvents (
      UserName STRING(MAX),
      EventDate STRING(10)
    ) PRIMARY KEY(UserName, EventDate);

The following keys name rows in this table:

    ["Bob", "2014-09-23"]
    ["Alfred", "2015-06-12"]

Since the `UserEvents` table's `PRIMARY KEY` clause names two
columns, each `UserEvents` key has two elements; the first is the
`UserName`, and the second is the `EventDate`.

Key ranges with multiple components are interpreted
lexicographically by component using the table or index key's declared
sort order. For example, the following range returns all events for
user `"Bob"` that occurred in the year 2015:

    "start_closed": ["Bob", "2015-01-01"]
    "end_closed": ["Bob", "2015-12-31"]

Start and end keys can omit trailing key components. This affects the
inclusion and exclusion of rows that exactly match the provided key
components: if the key is closed, then rows that exactly match the
provided components are included; if the key is open, then rows
that exactly match are not included.

For example, the following range includes all events for `"Bob"` that
occurred during and after the year 2000:

    "start_closed": ["Bob", "2000-01-01"]
    "end_closed": ["Bob"]

The next example retrieves all events for `"Bob"`:

    "start_closed": ["Bob"]
    "end_closed": ["Bob"]

To retrieve events before the year 2000:

    "start_closed": ["Bob"]
    "end_open": ["Bob", "2000-01-01"]

The following range includes all rows in the table:

    "start_closed": []
    "end_closed": []

This range returns all users whose `UserName` begins with any
character from A to C:

    "start_closed": ["A"]
    "end_open": ["D"]

This range returns all users whose `UserName` begins with B:

    "start_closed": ["B"]
    "end_open": ["C"]

Key ranges honor column sort order. For example, suppose a table is
defined as follows:

    CREATE TABLE DescendingSortedTable {
      Key INT64,
      ...
    ) PRIMARY KEY(Key DESC);

The following range retrieves all rows with key values between 1
and 100 inclusive:

    "start_closed": ["100"]
    "end_closed": ["1"]

Note that 100 is passed as the start, and 1 is passed as the end,
because `Key` is a descending column in the schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_closed() >> / C<< $msg->start_closed($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

If the start is closed, then the range includes all rows whose
first `len(start_closed)` key columns exactly match `start_closed`.

=item * C<< $msg->start_open() >> / C<< $msg->start_open($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

If the start is open, then the range excludes rows whose first
`len(start_open)` key columns exactly match `start_open`.

=item * C<< $msg->end_closed() >> / C<< $msg->end_closed($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

If the end is closed, then the range includes all rows whose
first `len(end_closed)` key columns exactly match `end_closed`.

=item * C<< $msg->end_open() >> / C<< $msg->end_open($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

If the end is open, then the range excludes rows whose first
`len(end_open)` key columns exactly match `end_open`.

=back

=head2 Google::Spanner::V1::Keys::KeySet

`KeySet` defines a collection of Cloud Spanner keys and/or key ranges. All
the keys are expected to be in the same table or index. The keys need
not be sorted in any particular way.

If the same key is specified multiple times in the set (for example
if two ranges, two keys, or a key and a range overlap), Cloud Spanner
behaves as if the key were only specified once.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->keys() >> / C<< $msg->keys($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

A list of specific keys. Entries in `keys` should have exactly as
many elements as there are columns in the primary or index key
with which this `KeySet` is used.  Individual key values are
encoded as described [here][google.spanner.v1.TypeCode].

=item * C<< $msg->ranges() >> / C<< $msg->ranges($value) >>

Type: C<Message> (L<Google::Spanner::V1::Keys::KeyRange>)

A list of key ranges. See [KeyRange][google.spanner.v1.KeyRange] for more
information about key range specifications.

=item * C<< $msg->all() >> / C<< $msg->all($value) >>

Type: C<Bool>

For convenience `all` can be set to `true` to indicate that this
`KeySet` matches all keys in the table or index. Note that any keys
specified in `keys` or `ranges` are only yielded once.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::V1::Keys::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
