package Google::Firestore::Admin::V1beta2::Field;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Firestore::Admin::V1beta2::Index };
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTIvZmllbGQucHJvdG8SHmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMhoqZ29vZ2xlL2ZpcmVzdG9yZS9hZG1pbi92MWJldGEy
L2luZGV4LnByb3RvGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvIrkCCgVGaWVsZBIS
CgRuYW1lGAEgASgJUgRuYW1lElQKDGluZGV4X2NvbmZpZxgCIAEoCzIxLmdvb2dsZS5maXJl
c3RvcmUuYWRtaW4udjFiZXRhMi5GaWVsZC5JbmRleENvbmZpZ1ILaW5kZXhDb25maWcaxQEK
C0luZGV4Q29uZmlnEj8KB2luZGV4ZXMYASADKAsyJS5nb29nbGUuZmlyZXN0b3JlLmFkbWlu
LnYxYmV0YTIuSW5kZXhSB2luZGV4ZXMSMAoUdXNlc19hbmNlc3Rvcl9jb25maWcYAiABKAhS
EnVzZXNBbmNlc3RvckNvbmZpZxIlCg5hbmNlc3Rvcl9maWVsZBgDIAEoCVINYW5jZXN0b3JG
aWVsZBIcCglyZXZlcnRpbmcYBCABKAhSCXJldmVydGluZ0KgAQoiY29tLmdvb2dsZS5maXJl
c3RvcmUuYWRtaW4udjFiZXRhMkIKRmllbGRQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dv
L2ZpcmVzdG9yZS9hZG1pbi9hcGl2MWJldGEyL2FkbWlucGI7YWRtaW5wYqICBEdDRlOqAiRH
b29nbGUuQ2xvdWQuRmlyZXN0b3JlLkFkbWluLlYxQmV0YTJKgx0KBhIEDwBbAQq9BAoBDBID
DwASMrIEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCgoICgECEgMRACcKCQoCAwASAxMANAoJCgID
ARIDFAAmCggKAQgSAxYAQQoJCgIIJRIDFgBBCggKAQgSAxcAVQoJCgIICxIDFwBVCggKAQgS
AxgAIgoJCgIIChIDGAAiCggKAQgSAxkAKwoJCgIICBIDGQArCggKAQgSAxoAOwoJCgIIARID
GgA7CggKAQgSAxsAIgoJCgIIJBIDGwAiCq4BCgIEABIEIQBbARqhASBSZXByZXNlbnRzIGEg
c2luZ2xlIGZpZWxkIGluIHRoZSBkYXRhYmFzZS4KCiBGaWVsZHMgYXJlIGdyb3VwZWQgYnkg
dGhlaXIgIkNvbGxlY3Rpb24gR3JvdXAiLCB3aGljaCByZXByZXNlbnQgYWxsCiBjb2xsZWN0
aW9ucyBpbiB0aGUgZGF0YWJhc2Ugd2l0aCB0aGUgc2FtZSBpZC4KCgoKAwQAARIDIQgNCjcK
BAQAAwASBCMCOAMaKSBUaGUgaW5kZXggY29uZmlndXJhdGlvbiBmb3IgdGhpcyBmaWVsZC4K
CgwKBQQAAwABEgMjChUKNgoGBAADAAIAEgMlBB8aJyBUaGUgaW5kZXhlcyBzdXBwb3J0ZWQg
Zm9yIHRoaXMgZmllbGQuCgoOCgcEAAMAAgAEEgMlBAwKDgoHBAADAAIABhIDJQ0SCg4KBwQA
AwACAAESAyUTGgoOCgcEAAMAAgADEgMlHR4K0wEKBgQAAwACARIDKgQiGsMBIE91dHB1dCBv
bmx5LiBXaGVuIHRydWUsIHRoZSBgRmllbGRgJ3MgaW5kZXggY29uZmlndXJhdGlvbiBpcyBz
ZXQgZnJvbSB0aGUKIGNvbmZpZ3VyYXRpb24gc3BlY2lmaWVkIGJ5IHRoZSBgYW5jZXN0b3Jf
ZmllbGRgLgogV2hlbiBmYWxzZSwgdGhlIGBGaWVsZGAncyBpbmRleCBjb25maWd1cmF0aW9u
IGlzIGRlZmluZWQgZXhwbGljaXRseS4KCg4KBwQAAwACAQUSAyoECAoOCgcEAAMAAgEBEgMq
CR0KDgoHBAADAAIBAxIDKiAhCpcCCgYEAAMAAgISAzAEHhqHAiBPdXRwdXQgb25seS4gU3Bl
Y2lmaWVzIHRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBgRmllbGRgIGZyb20gd2hpY2ggdGhp
cyBmaWVsZCdzCiBpbmRleCBjb25maWd1cmF0aW9uIGlzIHNldCAod2hlbiBgdXNlc19hbmNl
c3Rvcl9jb25maWdgIGlzIHRydWUpLAogb3IgZnJvbSB3aGljaCBpdCAqd291bGQqIGJlIHNl
dCBpZiB0aGlzIGZpZWxkIGhhZCBubyBpbmRleCBjb25maWd1cmF0aW9uCiAod2hlbiBgdXNl
c19hbmNlc3Rvcl9jb25maWdgIGlzIGZhbHNlKS4KCg4KBwQAAwACAgUSAzAECgoOCgcEAAMA
AgIBEgMwCxkKDgoHBAADAAICAxIDMBwdCrcCCgYEAAMAAgMSAzcEFxqnAiBPdXRwdXQgb25s
eQogV2hlbiB0cnVlLCB0aGUgYEZpZWxkYCdzIGluZGV4IGNvbmZpZ3VyYXRpb24gaXMgaW4g
dGhlIHByb2Nlc3Mgb2YgYmVpbmcKIHJldmVydGVkLiBPbmNlIGNvbXBsZXRlLCB0aGUgaW5k
ZXggY29uZmlnIHdpbGwgdHJhbnNpdGlvbiB0byB0aGUgc2FtZQogc3RhdGUgYXMgdGhlIGZp
ZWxkIHNwZWNpZmllZCBieSBgYW5jZXN0b3JfZmllbGRgLCBhdCB3aGljaCBwb2ludAogYHVz
ZXNfYW5jZXN0b3JfY29uZmlnYCB3aWxsIGJlIGB0cnVlYCBhbmQgYHJldmVydGluZ2Agd2ls
bCBiZSBgZmFsc2VgLgoKDgoHBAADAAIDBRIDNwQICg4KBwQAAwACAwESAzcJEgoOCgcEAAMA
AgMDEgM3FRYKkAoKBAQAAgASA1QCEhqCCiBBIGZpZWxkIG5hbWUgb2YgdGhlIGZvcm0KIGBw
cm9qZWN0cy97cHJvamVjdF9pZH0vZGF0YWJhc2VzL3tkYXRhYmFzZV9pZH0vY29sbGVjdGlv
bkdyb3Vwcy97Y29sbGVjdGlvbl9pZH0vZmllbGRzL3tmaWVsZF9wYXRofWAKCiBBIGZpZWxk
IHBhdGggbWF5IGJlIGEgc2ltcGxlIGZpZWxkIG5hbWUsIGUuZy4gYGFkZHJlc3NgIG9yIGEg
cGF0aCB0byBmaWVsZHMKIHdpdGhpbiBtYXBfdmFsdWUgLCBlLmcuIGBhZGRyZXNzLmNpdHlg
LAogb3IgYSBzcGVjaWFsIGZpZWxkIHBhdGguIFRoZSBvbmx5IHZhbGlkIHNwZWNpYWwgZmll
bGQgaXMgYCpgLCB3aGljaAogcmVwcmVzZW50cyBhbnkgZmllbGQuCgogRmllbGQgcGF0aHMg
bWF5IGJlIHF1b3RlZCB1c2luZyBgIChiYWNrdGljaykuIFRoZSBvbmx5IGNoYXJhY3RlciB0
aGF0IG5lZWRzCiB0byBiZSBlc2NhcGVkIHdpdGhpbiBhIHF1b3RlZCBmaWVsZCBwYXRoIGlz
IHRoZSBiYWNrdGljayBjaGFyYWN0ZXIgaXRzZWxmLAogZXNjYXBlZCB1c2luZyBhIGJhY2tz
bGFzaC4gU3BlY2lhbCBjaGFyYWN0ZXJzIGluIGZpZWxkIHBhdGhzIHRoYXQKIG11c3QgYmUg
cXVvdGVkIGluY2x1ZGU6IGAqYCwgYC5gLAogYGBgIChiYWNrdGljayksIGBbYCwgYF1gLCBh
cyB3ZWxsIGFzIGFueSBhc2NpaSBzeW1ib2xpYyBjaGFyYWN0ZXJzLgoKIEV4YW1wbGVzOgog
KE5vdGU6IENvbW1lbnRzIGhlcmUgYXJlIHdyaXR0ZW4gaW4gbWFya2Rvd24gc3ludGF4LCBz
byB0aGVyZSBpcyBhbgogIGFkZGl0aW9uYWwgbGF5ZXIgb2YgYmFja3RpY2tzIHRvIHJlcHJl
c2VudCBhIGNvZGUgYmxvY2spCiBgXGBhZGRyZXNzLmNpdHlcYGAgcmVwcmVzZW50cyBhIGZp
ZWxkIG5hbWVkIGBhZGRyZXNzLmNpdHlgLCBub3QgdGhlIG1hcCBrZXkKIGBjaXR5YCBpbiB0
aGUgZmllbGQgYGFkZHJlc3NgLgogYFxgKlxgYCByZXByZXNlbnRzIGEgZmllbGQgbmFtZWQg
YCpgLCBub3QgYW55IGZpZWxkLgoKIEEgc3BlY2lhbCBgRmllbGRgIGNvbnRhaW5zIHRoZSBk
ZWZhdWx0IGluZGV4aW5nIHNldHRpbmdzIGZvciBhbGwgZmllbGRzLgogVGhpcyBmaWVsZCdz
IHJlc291cmNlIG5hbWUgaXM6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97
ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25Hcm91cHMvX19kZWZhdWx0X18vZmllbGRzLypgCiBJ
bmRleGVzIGRlZmluZWQgb24gdGhpcyBgRmllbGRgIHdpbGwgYmUgYXBwbGllZCB0byBhbGwg
ZmllbGRzIHdoaWNoIGRvIG5vdAogaGF2ZSB0aGVpciBvd24gYEZpZWxkYCBpbmRleCBjb25m
aWd1cmF0aW9uLgoKDAoFBAACAAUSA1QCCAoMCgUEAAIAARIDVAkNCgwKBQQAAgADEgNUEBEK
/QEKBAQAAgESA1oCHxrvASBUaGUgaW5kZXggY29uZmlndXJhdGlvbiBmb3IgdGhpcyBmaWVs
ZC4gSWYgdW5zZXQsIGZpZWxkIGluZGV4aW5nIHdpbGwKIHJldmVydCB0byB0aGUgY29uZmln
dXJhdGlvbiBkZWZpbmVkIGJ5IHRoZSBgYW5jZXN0b3JfZmllbGRgLiBUbwogZXhwbGljaXRs
eSByZW1vdmUgYWxsIGluZGV4ZXMgZm9yIHRoaXMgZmllbGQsIHNwZWNpZnkgYW4gaW5kZXgg
Y29uZmlnCiB3aXRoIGFuIGVtcHR5IGxpc3Qgb2YgaW5kZXhlcy4KCgwKBQQAAgEGEgNaAg0K
DAoFBAACAQESA1oOGgoMCgUEAAIBAxIDWh0eYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta2::Field::Field ===
    # Fields for Field
    # Field: name Type: 9 ()
    # Field: index_config Type: 11 (.google.firestore.admin.v1beta2.Field.IndexConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta2::Field - Compiled Protocol Buffers messages for google/firestore/admin/v1beta2/field.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta2::Field;

    my $msg = Google::Firestore::Admin::V1beta2::Field::Field->new({
        name => $name,
        index_config => $index_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta2::Field::Field->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta2/field.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta2::Field::Field

Represents a single field in the database.

Fields are grouped by their "Collection Group", which represent all
collections in the database with the same id.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

A field name of the form
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_path}`

A field path may be a simple field name, e.g. `address` or a path to fields
within map_value , e.g. `address.city`,
or a special field path. The only valid special field is `*`, which
represents any field.

Field paths may be quoted using ` (backtick). The only character that needs
to be escaped within a quoted field path is the backtick character itself,
escaped using a backslash. Special characters in field paths that
must be quoted include: `*`, `.`,
``` (backtick), `[`, `]`, as well as any ascii symbolic characters.

Examples:
(Note: Comments here are written in markdown syntax, so there is an
 additional layer of backticks to represent a code block)
`\`address.city\`` represents a field named `address.city`, not the map key
`city` in the field `address`.
`\`*\`` represents a field named `*`, not any field.

A special `Field` contains the default indexing settings for all fields.
This field's resource name is:
`projects/{project_id}/databases/{database_id}/collectionGroups/__default__/fields/*`
Indexes defined on this `Field` will be applied to all fields which do not
have their own `Field` index configuration.

=item * C<< $msg->index_config() >> / C<< $msg->index_config($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Field::Field::IndexConfig>)

The index configuration for this field. If unset, field indexing will
revert to the configuration defined by the `ancestor_field`. To
explicitly remove all indexes for this field, specify an index config
with an empty list of indexes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta2::Field::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
