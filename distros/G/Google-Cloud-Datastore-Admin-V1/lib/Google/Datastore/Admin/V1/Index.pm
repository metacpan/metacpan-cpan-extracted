package Google::Datastore::Admin::V1::Index;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvZGF0YXN0b3JlL2FkbWluL3YxL2luZGV4LnByb3RvEhlnb29nbGUuZGF0YXN0
b3JlLmFkbWluLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIq4FCgVJbmRl
eBIiCgpwcm9qZWN0X2lkGAEgASgJQgPgQQNSCXByb2plY3RJZBIeCghpbmRleF9pZBgDIAEo
CUID4EEDUgdpbmRleElkEhcKBGtpbmQYBCABKAlCA+BBAlIEa2luZBJOCghhbmNlc3RvchgF
IAEoDjItLmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjEuSW5kZXguQW5jZXN0b3JNb2RlQgPg
QQJSCGFuY2VzdG9yElUKCnByb3BlcnRpZXMYBiADKAsyMC5nb29nbGUuZGF0YXN0b3JlLmFk
bWluLnYxLkluZGV4LkluZGV4ZWRQcm9wZXJ0eUID4EECUgpwcm9wZXJ0aWVzEkEKBXN0YXRl
GAcgASgOMiYuZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MS5JbmRleC5TdGF0ZUID4EEDUgVz
dGF0ZRp5Cg9JbmRleGVkUHJvcGVydHkSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEk0KCWRp
cmVjdGlvbhgCIAEoDjIqLmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjEuSW5kZXguRGlyZWN0
aW9uQgPgQQJSCWRpcmVjdGlvbiJKCgxBbmNlc3Rvck1vZGUSHQoZQU5DRVNUT1JfTU9ERV9V
TlNQRUNJRklFRBAAEggKBE5PTkUQARIRCg1BTExfQU5DRVNUT1JTEAIiRQoJRGlyZWN0aW9u
EhkKFURJUkVDVElPTl9VTlNQRUNJRklFRBAAEg0KCUFTQ0VORElORxABEg4KCkRFU0NFTkRJ
TkcQAiJQCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCQoF
UkVBRFkQAhIMCghERUxFVElORxADEgkKBUVSUk9SEARC0gEKHWNvbS5nb29nbGUuZGF0YXN0
b3JlLmFkbWluLnYxQgpJbmRleFByb3RvUAFaOWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YXN0
b3JlL2FkbWluL2FwaXYxL2FkbWlucGI7YWRtaW5wYqoCH0dvb2dsZS5DbG91ZC5EYXRhc3Rv
cmUuQWRtaW4uVjHKAh9Hb29nbGVcQ2xvdWRcRGF0YXN0b3JlXEFkbWluXFYx6gIjR29vZ2xl
OjpDbG91ZDo6RGF0YXN0b3JlOjpBZG1pbjo6VjFK7iAKBhIEDgB5AQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgApCggKAQgSAxQAPAoJ
CgIIJRIDFAA8CggKAQgSAxUAUAoJCgIICxIDFQBQCggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcAKwoJCgIICBIDFwArCggKAQgSAxgANgoJCgIIARIDGAA2CggKAQgSAxkAPQoJCgII
KRIDGQA9CggKAQgSAxoAPAoJCgIILRIDGgA8CjMKAgQAEgQdAHkBGicgRGF0YXN0b3JlIGNv
bXBvc2l0ZSBpbmRleCBkZWZpbml0aW9uLgoKCgoDBAABEgMdCA0KaQoEBAAEABIEIAIpAxpb
IEZvciBhbiBvcmRlcmVkIGluZGV4LCBzcGVjaWZpZXMgd2hldGhlciBlYWNoIG9mIHRoZSBl
bnRpdHkncyBhbmNlc3RvcnMKIHdpbGwgYmUgaW5jbHVkZWQuCgoMCgUEAAQAARIDIAcTCjIK
BgQABAACABIDIgQiGiMgVGhlIGFuY2VzdG9yIG1vZGUgaXMgdW5zcGVjaWZpZWQuCgoOCgcE
AAQAAgABEgMiBB0KDgoHBAAEAAIAAhIDIiAhCkQKBgQABAACARIDJQQNGjUgRG8gbm90IGlu
Y2x1ZGUgdGhlIGVudGl0eSdzIGFuY2VzdG9ycyBpbiB0aGUgaW5kZXguCgoOCgcEAAQAAgEB
EgMlBAgKDgoHBAAEAAIBAhIDJQsMCkEKBgQABAACAhIDKAQWGjIgSW5jbHVkZSBhbGwgdGhl
IGVudGl0eSdzIGFuY2VzdG9ycyBpbiB0aGUgaW5kZXguCgoOCgcEAAQAAgIBEgMoBBEKDgoH
BAAEAAICAhIDKBQVCkMKBAQABAESBCwCNwMaNSBUaGUgZGlyZWN0aW9uIGRldGVybWluZXMg
aG93IGEgcHJvcGVydHkgaXMgaW5kZXhlZC4KCgwKBQQABAEBEgMsBxAKLgoGBAAEAQIAEgMu
BB4aHyBUaGUgZGlyZWN0aW9uIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAEAQIAARIDLgQZCg4K
BwQABAECAAISAy4cHQqJAQoGBAAEAQIBEgMyBBIaeiBUaGUgcHJvcGVydHkncyB2YWx1ZXMg
YXJlIGluZGV4ZWQgc28gYXMgdG8gc3VwcG9ydCBzZXF1ZW5jaW5nIGluCiBhc2NlbmRpbmcg
b3JkZXIgYW5kIGFsc28gcXVlcnkgYnkgPCwgPiwgPD0sID49LCBhbmQgPS4KCg4KBwQABAEC
AQESAzIEDQoOCgcEAAQBAgECEgMyEBEKigEKBgQABAECAhIDNgQTGnsgVGhlIHByb3BlcnR5
J3MgdmFsdWVzIGFyZSBpbmRleGVkIHNvIGFzIHRvIHN1cHBvcnQgc2VxdWVuY2luZyBpbgog
ZGVzY2VuZGluZyBvcmRlciBhbmQgYWxzbyBxdWVyeSBieSA8LCA+LCA8PSwgPj0sIGFuZCA9
LgoKDgoHBAAEAQICARIDNgQOCg4KBwQABAECAgISAzYREgonCgQEAAMAEgQ6AkEDGhkgQSBw
cm9wZXJ0eSBvZiBhbiBpbmRleC4KCgwKBQQAAwABEgM6ChkKNgoGBAADAAIAEgM8BD0aJyBS
ZXF1aXJlZC4gVGhlIHByb3BlcnR5IG5hbWUgdG8gaW5kZXguCgoOCgcEAAMAAgAFEgM8BAoK
DgoHBAADAAIAARIDPAsPCg4KBwQAAwACAAMSAzwSEwoOCgcEAAMAAgAIEgM8FDwKEQoKBAAD
AAIACJwIABIDPBU7CmEKBgQAAwACARIDQARFGlIgUmVxdWlyZWQuIFRoZSBpbmRleGVkIHBy
b3BlcnR5J3MgZGlyZWN0aW9uLiAgTXVzdCBub3QgYmUKIERJUkVDVElPTl9VTlNQRUNJRklF
RC4KCg4KBwQAAwACAQYSA0AEDQoOCgcEAAMAAgEBEgNADhcKDgoHBAADAAIBAxIDQBobCg4K
BwQAAwACAQgSA0AcRAoRCgoEAAMAAgEInAgAEgNAHUMKNwoEBAAEAhIERAJgAxopIFRoZSBw
b3NzaWJsZSBzZXQgb2Ygc3RhdGVzIG9mIGFuIGluZGV4LgoKDAoFBAAEAgESA0QHDAoqCgYE
AAQCAgASA0YEGhobIFRoZSBzdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAICAAESA0YE
FQoOCgcEAAQCAgACEgNGGBkK0AEKBgQABAICARIDTAQRGsABIFRoZSBpbmRleCBpcyBiZWlu
ZyBjcmVhdGVkLCBhbmQgY2Fubm90IGJlIHVzZWQgYnkgcXVlcmllcy4KIFRoZXJlIGlzIGFu
IGFjdGl2ZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uIGZvciB0aGUgaW5kZXguCiBUaGUgaW5k
ZXggaXMgdXBkYXRlZCB3aGVuIHdyaXRpbmcgYW4gZW50aXR5LgogU29tZSBpbmRleCBkYXRh
IG1heSBleGlzdC4KCg4KBwQABAICAQESA0wEDAoOCgcEAAQCAgECEgNMDxAKpAEKBgQABAIC
AhIDUQQOGpQBIFRoZSBpbmRleCBpcyByZWFkeSB0byBiZSB1c2VkLgogVGhlIGluZGV4IGlz
IHVwZGF0ZWQgd2hlbiB3cml0aW5nIGFuIGVudGl0eS4KIFRoZSBpbmRleCBpcyBmdWxseSBw
b3B1bGF0ZWQgZnJvbSBhbGwgc3RvcmVkIGVudGl0aWVzIGl0IGFwcGxpZXMgdG8uCgoOCgcE
AAQCAgIBEgNRBAkKDgoHBAAEAgICAhIDUQwNCtQBCgYEAAQCAgMSA1cEERrEASBUaGUgaW5k
ZXggaXMgYmVpbmcgZGVsZXRlZCwgYW5kIGNhbm5vdCBiZSB1c2VkIGJ5IHF1ZXJpZXMuCiBU
aGVyZSBpcyBhbiBhY3RpdmUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbiBmb3IgdGhlIGluZGV4
LgogVGhlIGluZGV4IGlzIG5vdCB1cGRhdGVkIHdoZW4gd3JpdGluZyBhbiBlbnRpdHkuCiBT
b21lIGluZGV4IGRhdGEgbWF5IGV4aXN0LgoKDgoHBAAEAgIDARIDVwQMCg4KBwQABAICAwIS
A1cPEArAAgoGBAAEAgIEEgNfBA4asAIgVGhlIGluZGV4IHdhcyBiZWluZyBjcmVhdGVkIG9y
IGRlbGV0ZWQsIGJ1dCBzb21ldGhpbmcgd2VudCB3cm9uZy4KIFRoZSBpbmRleCBjYW5ub3Qg
YnkgdXNlZCBieSBxdWVyaWVzLgogVGhlcmUgaXMgbm8gYWN0aXZlIGxvbmctcnVubmluZyBv
cGVyYXRpb24gZm9yIHRoZSBpbmRleCwKIGFuZCB0aGUgbW9zdCByZWNlbnRseSBmaW5pc2hl
ZCBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uIGZhaWxlZC4KIFRoZSBpbmRleCBpcyBub3QgdXBk
YXRlZCB3aGVuIHdyaXRpbmcgYW4gZW50aXR5LgogU29tZSBpbmRleCBkYXRhIG1heSBleGlz
dC4KCg4KBwQABAICBAESA18ECQoOCgcEAAQCAgQCEgNfDA0KJwoEBAACABIDYwJEGhogT3V0
cHV0IG9ubHkuIFByb2plY3QgSUQuCgoMCgUEAAIABRIDYwIICgwKBQQAAgABEgNjCRMKDAoF
BAACAAMSA2MWFwoMCgUEAAIACBIDYxhDCg8KCAQAAgAInAgAEgNjGUIKOQoEBAACARIDZgJC
GiwgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBJRCBvZiB0aGUgaW5kZXguCgoMCgUEAAIB
BRIDZgIICgwKBQQAAgEBEgNmCREKDAoFBAACAQMSA2YUFQoMCgUEAAIBCBIDZhZBCg8KCAQA
AgEInAgAEgNmF0AKRQoEBAACAhIDaQI7GjggUmVxdWlyZWQuIFRoZSBlbnRpdHkga2luZCB0
byB3aGljaCB0aGlzIGluZGV4IGFwcGxpZXMuCgoMCgUEAAICBRIDaQIICgwKBQQAAgIBEgNp
CQ0KDAoFBAACAgMSA2kQEQoMCgUEAAICCBIDaRI6Cg8KCAQAAgIInAgAEgNpEzkKXAoEBAAC
AxIDbQJFGk8gUmVxdWlyZWQuIFRoZSBpbmRleCdzIGFuY2VzdG9yIG1vZGUuICBNdXN0IG5v
dCBiZQogQU5DRVNUT1JfTU9ERV9VTlNQRUNJRklFRC4KCgwKBQQAAgMGEgNtAg4KDAoFBAAC
AwESA20PFwoMCgUEAAIDAxIDbRobCgwKBQQAAgMIEgNtHEQKDwoIBAACAwicCAASA20dQwqI
AQoEBAACBBIEdAJ1Lxp6IFJlcXVpcmVkLiBBbiBvcmRlcmVkIHNlcXVlbmNlIG9mIHByb3Bl
cnR5IG5hbWVzIGFuZCB0aGVpciBpbmRleCBhdHRyaWJ1dGVzLgoKIFJlcXVpcmVzOgoKICog
QSBtYXhpbXVtIG9mIDEwMCBwcm9wZXJ0aWVzLgoKDAoFBAACBAQSA3QCCgoMCgUEAAIEBhID
dAsaCgwKBQQAAgQBEgN0GyUKDAoFBAACBAMSA3QoKQoMCgUEAAIECBIDdQYuCg8KCAQAAgQI
nAgAEgN1By0KMwoEBAACBRIDeAI+GiYgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUg
aW5kZXguCgoMCgUEAAIFBhIDeAIHCgwKBQQAAgUBEgN4CA0KDAoFBAACBQMSA3gQEQoMCgUE
AAIFCBIDeBI9Cg8KCAQAAgUInAgAEgN4EzxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::Admin::V1::Index::Index ===
    # Fields for Index
    # Field: project_id Type: 9 ()
    # Field: index_id Type: 9 ()
    # Field: kind Type: 9 ()
    # Field: ancestor Type: 14 (.google.datastore.admin.v1.Index.AncestorMode)
    # Field: properties Type: 11 (.google.datastore.admin.v1.Index.IndexedProperty)
    # Field: state Type: 14 (.google.datastore.admin.v1.Index.State)

# Enum: Index::AncestorMode
our $Index_ANCESTOR_MODE_UNSPECIFIED = 0;
our $Index_NONE = 1;
our $Index_ALL_ANCESTORS = 2;

# Enum: Index::Direction
our $Index_DIRECTION_UNSPECIFIED = 0;
our $Index_ASCENDING = 1;
our $Index_DESCENDING = 2;

# Enum: Index::State
our $Index_STATE_UNSPECIFIED = 0;
our $Index_CREATING = 1;
our $Index_READY = 2;
our $Index_DELETING = 3;
our $Index_ERROR = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::Admin::V1::Index - Compiled Protocol Buffers messages for google/datastore/admin/v1/index.proto

=head1 SYNOPSIS

    use Google::Datastore::Admin::V1::Index;

    my $msg = Google::Datastore::Admin::V1::Index::Index->new({
        project_id => $project_id,
        index_id => $index_id,
        kind => $kind,
        ancestor => $ancestor,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::Admin::V1::Index::Index->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/admin/v1/index.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::Admin::V1::Index::Index

Datastore composite index definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Output only. Project ID.

=item * C<< $msg->index_id() >> / C<< $msg->index_id($value) >>

Type: C<String>

Output only. The resource ID of the index.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

Required. The entity kind to which this index applies.

=item * C<< $msg->ancestor() >> / C<< $msg->ancestor($value) >>

Type: C<Enum> (L<Google::Datastore::Admin::V1::Index::AncestorMode>)

Required. The index's ancestor mode.  Must not be
ANCESTOR_MODE_UNSPECIFIED.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1::Index::Index::IndexedProperty>)

Required. An ordered sequence of property names and their index attributes.

Requires:

* A maximum of 100 properties.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Datastore::Admin::V1::Index::State>)

Output only. The state of the index.

=back

=head3 Enum: Index::AncestorMode

=over 4

=item * C<ANCESTOR_MODE_UNSPECIFIED> => C<0>

=item * C<NONE> => C<1>

=item * C<ALL_ANCESTORS> => C<2>

=back

=head3 Enum: Index::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<ASCENDING> => C<1>

=item * C<DESCENDING> => C<2>

=back

=head3 Enum: Index::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=item * C<ERROR> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::Admin::V1::Index::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
