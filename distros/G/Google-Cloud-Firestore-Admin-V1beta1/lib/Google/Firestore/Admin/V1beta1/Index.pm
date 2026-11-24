package Google::Firestore::Admin::V1beta1::Index;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTEvaW5kZXgucHJvdG8SHmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90byLB
AQoKSW5kZXhGaWVsZBIdCgpmaWVsZF9wYXRoGAEgASgJUglmaWVsZFBhdGgSQwoEbW9kZRgC
IAEoDjIvLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5JbmRleEZpZWxkLk1vZGVS
BG1vZGUiTwoETW9kZRIUChBNT0RFX1VOU1BFQ0lGSUVEEAASDQoJQVNDRU5ESU5HEAISDgoK
REVTQ0VORElORxADEhIKDkFSUkFZX0NPTlRBSU5TEAQiiwIKBUluZGV4EhIKBG5hbWUYASAB
KAlSBG5hbWUSIwoNY29sbGVjdGlvbl9pZBgCIAEoCVIMY29sbGVjdGlvbklkEkIKBmZpZWxk
cxgDIAMoCzIqLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMS5JbmRleEZpZWxkUgZm
aWVsZHMSQQoFc3RhdGUYBiABKA4yKy5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTEu
SW5kZXguU3RhdGVSBXN0YXRlIkIKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoI
Q1JFQVRJTkcQAxIJCgVSRUFEWRACEgkKBUVSUk9SEAVCoAEKImNvbS5nb29nbGUuZmlyZXN0
b3JlLmFkbWluLnYxYmV0YTFCCkluZGV4UHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9m
aXJlc3RvcmUvYWRtaW4vYXBpdjFiZXRhMS9hZG1pbnBiO2FkbWlucGKiAgRHQ0ZTqgIkR29v
Z2xlLkNsb3VkLkZpcmVzdG9yZS5BZG1pbi5WMUJldGExSo8aCgYSBA8AZAEKvQQKAQwSAw8A
EjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAnCgkKAgMAEgMTACYKCAoBCBID
FQBBCgkKAgglEgMVAEEKCAoBCBIDFgBVCgkKAggLEgMWAFUKCAoBCBIDFwAiCgkKAggKEgMX
ACIKCAoBCBIDGAArCgkKAggIEgMYACsKCAoBCBIDGQA7CgkKAggBEgMZADsKCAoBCBIDGgAi
CgkKAggkEgMaACIKIgoCBAASBB0AOAEaFiBBIGZpZWxkIG9mIGFuIGluZGV4LgoKCgoDBAAB
EgMdCBIKOwoEBAAEABIEHwIuAxotIFRoZSBtb2RlIGRldGVybWluZXMgaG93IGEgZmllbGQg
aXMgaW5kZXhlZC4KCgwKBQQABAABEgMfBwsKKQoGBAAEAAIAEgMhBBkaGiBUaGUgbW9kZSBp
cyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAyEEFAoOCgcEAAQAAgACEgMhFxgKhgEKBgQA
BAACARIDJQQSGncgVGhlIGZpZWxkJ3MgdmFsdWVzIGFyZSBpbmRleGVkIHNvIGFzIHRvIHN1
cHBvcnQgc2VxdWVuY2luZyBpbgogYXNjZW5kaW5nIG9yZGVyIGFuZCBhbHNvIHF1ZXJ5IGJ5
IDwsID4sIDw9LCA+PSwgYW5kID0uCgoOCgcEAAQAAgEBEgMlBA0KDgoHBAAEAAIBAhIDJRAR
CocBCgYEAAQAAgISAykEExp4IFRoZSBmaWVsZCdzIHZhbHVlcyBhcmUgaW5kZXhlZCBzbyBh
cyB0byBzdXBwb3J0IHNlcXVlbmNpbmcgaW4KIGRlc2NlbmRpbmcgb3JkZXIgYW5kIGFsc28g
cXVlcnkgYnkgPCwgPiwgPD0sID49LCBhbmQgPS4KCg4KBwQABAACAgESAykEDgoOCgcEAAQA
AgICEgMpERIKcAoGBAAEAAIDEgMtBBcaYSBUaGUgZmllbGQncyBhcnJheSB2YWx1ZXMgYXJl
IGluZGV4ZWQgc28gYXMgdG8gc3VwcG9ydCBtZW1iZXJzaGlwIHVzaW5nCiBBUlJBWV9DT05U
QUlOUyBxdWVyaWVzLgoKDgoHBAAEAAIDARIDLQQSCg4KBwQABAACAwISAy0VFgqPAgoEBAAC
ABIDNAIYGoECIFRoZSBwYXRoIG9mIHRoZSBmaWVsZC4gTXVzdCBtYXRjaCB0aGUgZmllbGQg
cGF0aCBzcGVjaWZpY2F0aW9uIGRlc2NyaWJlZAogYnkgW2dvb2dsZS5maXJlc3RvcmUudjFi
ZXRhMS5Eb2N1bWVudC5maWVsZHNdW2ZpZWxkc10uCiBTcGVjaWFsIGZpZWxkIHBhdGggYF9f
bmFtZV9fYCBtYXkgYmUgdXNlZCBieSBpdHNlbGYgb3IgYXQgdGhlIGVuZCBvZiBhCiBwYXRo
LiBgX190eXBlX19gIG1heSBiZSB1c2VkIG9ubHkgYXQgdGhlIGVuZCBvZiBwYXRoLgoKDAoF
BAACAAUSAzQCCAoMCgUEAAIAARIDNAkTCgwKBQQAAgADEgM0FhcKIAoEBAACARIDNwIQGhMg
VGhlIGZpZWxkJ3MgbW9kZS4KCgwKBQQAAgEGEgM3AgYKDAoFBAACAQESAzcHCwoMCgUEAAIB
AxIDNw4PCiIKAgQBEgQ7AGQBGhYgQW4gaW5kZXggZGVmaW5pdGlvbi4KCgoKAwQBARIDOwgN
CosCCgQEAQQAEgRAAlUDGvwBIFRoZSBzdGF0ZSBvZiBhbiBpbmRleC4gRHVyaW5nIGluZGV4
IGNyZWF0aW9uLCBhbiBpbmRleCB3aWxsIGJlIGluIHRoZQogYENSRUFUSU5HYCBzdGF0ZS4g
SWYgdGhlIGluZGV4IGlzIGNyZWF0ZWQgc3VjY2Vzc2Z1bGx5LCBpdCB3aWxsIHRyYW5zaXRp
b24KIHRvIHRoZSBgUkVBRFlgIHN0YXRlLiBJZiB0aGUgaW5kZXggaXMgbm90IGFibGUgdG8g
YmUgY3JlYXRlZCwgaXQgd2lsbAogdHJhbnNpdGlvbiB0byB0aGUgYEVSUk9SYCBzdGF0ZS4K
CgwKBQQBBAABEgNABwwKKgoGBAEEAAIAEgNCBBoaGyBUaGUgc3RhdGUgaXMgdW5zcGVjaWZp
ZWQuCgoOCgcEAQQAAgABEgNCBBUKDgoHBAEEAAIAAhIDQhgZCrIBCgYEAQQAAgESA0gEERqi
ASBUaGUgaW5kZXggaXMgYmVpbmcgY3JlYXRlZC4KIFRoZXJlIGlzIGFuIGFjdGl2ZSBsb25n
LXJ1bm5pbmcgb3BlcmF0aW9uIGZvciB0aGUgaW5kZXguCiBUaGUgaW5kZXggaXMgdXBkYXRl
ZCB3aGVuIHdyaXRpbmcgYSBkb2N1bWVudC4KIFNvbWUgaW5kZXggZGF0YSBtYXkgZXhpc3Qu
CgoOCgcEAQQAAgEBEgNIBAwKDgoHBAEEAAIBAhIDSA8QCqYBCgYEAQQAAgISA00EDhqWASBU
aGUgaW5kZXggaXMgcmVhZHkgdG8gYmUgdXNlZC4KIFRoZSBpbmRleCBpcyB1cGRhdGVkIHdo
ZW4gd3JpdGluZyBhIGRvY3VtZW50LgogVGhlIGluZGV4IGlzIGZ1bGx5IHBvcHVsYXRlZCBm
cm9tIGFsbCBzdG9yZWQgZG9jdW1lbnRzIGl0IGFwcGxpZXMgdG8uCgoOCgcEAQQAAgIBEgNN
BAkKDgoHBAEEAAICAhIDTQwNCpACCgYEAQQAAgMSA1QEDhqAAiBUaGUgaW5kZXggd2FzIGJl
aW5nIGNyZWF0ZWQsIGJ1dCBzb21ldGhpbmcgd2VudCB3cm9uZy4KIFRoZXJlIGlzIG5vIGFj
dGl2ZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uIGZvciB0aGUgaW5kZXgsCiBhbmQgdGhlIG1v
c3QgcmVjZW50bHkgZmluaXNoZWQgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbiBmYWlsZWQuCiBU
aGUgaW5kZXggaXMgbm90IHVwZGF0ZWQgd2hlbiB3cml0aW5nIGEgZG9jdW1lbnQuCiBTb21l
IGluZGV4IGRhdGEgbWF5IGV4aXN0LgoKDgoHBAEEAAIDARIDVAQJCg4KBwQBBAACAwISA1QM
DQo8CgQEAQIAEgNZAhIaLyBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgaW5kZXguCiBPdXRw
dXQgb25seS4KCgwKBQQBAgAFEgNZAggKDAoFBAECAAESA1kJDQoMCgUEAQIAAxIDWRARCkcK
BAQBAgESA1wCGxo6IFRoZSBjb2xsZWN0aW9uIElEIHRvIHdoaWNoIHRoaXMgaW5kZXggYXBw
bGllcy4gUmVxdWlyZWQuCgoMCgUEAQIBBRIDXAIICgwKBQQBAgEBEgNcCRYKDAoFBAECAQMS
A1wZGgojCgQEAQICEgNfAiEaFiBUaGUgZmllbGRzIHRvIGluZGV4LgoKDAoFBAECAgQSA18C
CgoMCgUEAQICBhIDXwsVCgwKBQQBAgIBEgNfFhwKDAoFBAECAgMSA18fIAo0CgQEAQIDEgNj
AhIaJyBUaGUgc3RhdGUgb2YgdGhlIGluZGV4LgogT3V0cHV0IG9ubHkuCgoMCgUEAQIDBhID
YwIHCgwKBQQBAgMBEgNjCA0KDAoFBAECAwMSA2MQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta1::Index::IndexField ===
    # Fields for IndexField
    # Field: field_path Type: 9 ()
    # Field: mode Type: 14 (.google.firestore.admin.v1beta1.IndexField.Mode)

# Enum: IndexField::Mode
our $IndexField_MODE_UNSPECIFIED = 0;
our $IndexField_ASCENDING = 2;
our $IndexField_DESCENDING = 3;
our $IndexField_ARRAY_CONTAINS = 4;

# === Message: Google::Firestore::Admin::V1beta1::Index::Index ===
    # Fields for Index
    # Field: name Type: 9 ()
    # Field: collection_id Type: 9 ()
    # Field: fields Type: 11 (.google.firestore.admin.v1beta1.IndexField)
    # Field: state Type: 14 (.google.firestore.admin.v1beta1.Index.State)

# Enum: Index::State
our $Index_STATE_UNSPECIFIED = 0;
our $Index_CREATING = 3;
our $Index_READY = 2;
our $Index_ERROR = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta1::Index - Compiled Protocol Buffers messages for google/firestore/admin/v1beta1/index.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta1::Index;

    my $msg = Google::Firestore::Admin::V1beta1::Index::IndexField->new({
        field_path => $field_path,
        mode => $mode,
    });

    # Read or update a field
    my $val = $msg->field_path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta1::Index::IndexField->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta1/index.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta1::Index::IndexField

A field of an index.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field_path() >> / C<< $msg->field_path($value) >>

Type: C<String>

The path of the field. Must match the field path specification described
by [google.firestore.v1beta1.Document.fields][fields].
Special field path `__name__` may be used by itself or at the end of a
path. `__type__` may be used only at the end of path.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta1::IndexField::Mode>)

The field's mode.

=back

=head3 Enum: IndexField::Mode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<ASCENDING> => C<2>

=item * C<DESCENDING> => C<3>

=item * C<ARRAY_CONTAINS> => C<4>

=back

=head2 Google::Firestore::Admin::V1beta1::Index::Index

An index definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the index.
Output only.

=item * C<< $msg->collection_id() >> / C<< $msg->collection_id($value) >>

Type: C<String>

The collection ID to which this index applies. Required.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta1::Index::IndexField>)

The fields to index.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta1::Index::State>)

The state of the index.
Output only.

=back

=head3 Enum: Index::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<3>

=item * C<READY> => C<2>

=item * C<ERROR> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta1::Index::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
