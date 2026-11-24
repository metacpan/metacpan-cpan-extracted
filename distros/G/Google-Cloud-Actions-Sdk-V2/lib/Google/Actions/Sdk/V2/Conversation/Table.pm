package Google::Actions::Sdk::V2::Conversation::Table;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Image };
    eval { require Google::Actions::Sdk::V2::Conversation::Link };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L3Rh
YmxlLnByb3RvEiJnb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uGj1nb29nbGUv
YWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2ltYWdlLnByb3Rv
Gjxnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2xp
bmsucHJvdG8iyQIKBVRhYmxlEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIaCghzdWJ0aXRsZRgC
IAEoCVIIc3VidGl0bGUSPwoFaW1hZ2UYBCABKAsyKS5nb29nbGUuYWN0aW9ucy5zZGsudjIu
Y29udmVyc2F0aW9uLkltYWdlUgVpbWFnZRJJCgdjb2x1bW5zGAUgAygLMi8uZ29vZ2xlLmFj
dGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5UYWJsZUNvbHVtblIHY29sdW1ucxJACgRyb3dz
GAYgAygLMiwuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5UYWJsZVJvd1IE
cm93cxJACgZidXR0b24YByABKAsyKC5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0
aW9uLkxpbmtSBmJ1dHRvbiLPAQoLVGFibGVDb2x1bW4SFgoGaGVhZGVyGAEgASgJUgZoZWFk
ZXISWQoFYWxpZ24YAiABKA4yQy5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9u
LlRhYmxlQ29sdW1uLkhvcml6b250YWxBbGlnbm1lbnRSBWFsaWduIk0KE0hvcml6b250YWxB
bGlnbm1lbnQSDwoLVU5TUEVDSUZJRUQQABILCgdMRUFESU5HEAESCgoGQ0VOVEVSEAISDAoI
VFJBSUxJTkcQAyIfCglUYWJsZUNlbGwSEgoEdGV4dBgBIAEoCVIEdGV4dCJpCghUYWJsZVJv
dxJDCgVjZWxscxgBIAMoCzItLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24u
VGFibGVDZWxsUgVjZWxscxIYCgdkaXZpZGVyGAIgASgIUgdkaXZpZGVyQoYBCiZjb20uZ29v
Z2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbkIKVGFibGVQcm90b1ABWk5nb29nbGUu
Z29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNh
dGlvbjtjb252ZXJzYXRpb25KuRcKBhIEDgBbAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgBHCgkKAgMBEgMTAEYKCAoBCBIDFQBlCgkK
AggLEgMVAGUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwArCgkKAggIEgMXACsKCAoB
CBIDGAA/CgkKAggBEgMYAD8KOgoCBAASBBsAMQEaLiBBIHRhYmxlIGNhcmQgZm9yIGRpc3Bs
YXlpbmcgYSB0YWJsZSBvZiB0ZXh0LgoKCgoDBAABEgMbCA0KVwoEBAACABIDHQITGkogT3Zl
cmFsbCB0aXRsZSBvZiB0aGUgdGFibGUuIE9wdGlvbmFsIGJ1dCBtdXN0IGJlIHNldCBpZiBz
dWJ0aXRsZSBpcyBzZXQuCgoMCgUEAAIABRIDHQIICgwKBQQAAgABEgMdCQ4KDAoFBAACAAMS
Ax0REgowCgQEAAIBEgMgAhYaIyBTdWJ0aXRsZSBmb3IgdGhlIHRhYmxlLiBPcHRpb25hbC4K
CgwKBQQAAgEFEgMgAggKDAoFBAACAQESAyAJEQoMCgUEAAIBAxIDIBQVCjkKBAQAAgISAyMC
EhosIEltYWdlIGFzc29jaWF0ZWQgd2l0aCB0aGUgdGFibGUuIE9wdGlvbmFsLgoKDAoFBAAC
AgYSAyMCBwoMCgUEAAICARIDIwgNCgwKBQQAAgIDEgMjEBEKMAoEBAACAxIDJgIjGiMgSGVh
ZGVycyBhbmQgYWxpZ25tZW50IG9mIGNvbHVtbnMuCgoMCgUEAAIDBBIDJgIKCgwKBQQAAgMG
EgMmCxYKDAoFBAACAwESAyYXHgoMCgUEAAIDAxIDJiEiCsECCgQEAAIEEgMtAh0aswIgUm93
IGRhdGEgb2YgdGhlIHRhYmxlLiBUaGUgZmlyc3QgMyByb3dzIGFyZSBndWFyYW50ZWVkIHRv
IGJlIHNob3duIGJ1dAogb3RoZXJzIG1pZ2h0IGJlIGN1dCBvbiBjZXJ0YWluIHN1cmZhY2Vz
LiBQbGVhc2UgdGVzdCB3aXRoIHRoZSBzaW11bGF0b3IgdG8KIHNlZSB3aGljaCByb3dzIHdp
bGwgYmUgc2hvd24gZm9yIGEgZ2l2ZW4gc3VyZmFjZS4gT24gc3VyZmFjZXMgdGhhdCBzdXBw
b3J0CiB0aGUgV0VCX0JST1dTRVIgY2FwYWJpbGl0eSwgeW91IGNhbiBwb2ludCB0aGUgdXNl
ciB0bwogYSB3ZWIgcGFnZSB3aXRoIG1vcmUgZGF0YS4KCgwKBQQAAgQEEgMtAgoKDAoFBAAC
BAYSAy0LEwoMCgUEAAIEARIDLRQYCgwKBQQAAgQDEgMtGxwKFgoEBAACBRIDMAISGgkgQnV0
dG9uLgoKDAoFBAACBQYSAzACBgoMCgUEAAIFARIDMAcNCgwKBQQAAgUDEgMwEBEKLAoCBAES
BDQASgEaICBEZXNjcmliZXMgYSBjb2x1bW4gaW4gYSB0YWJsZS4KCgoKAwQBARIDNAgTCj0K
BAQBBAASBDYCQgMaLyBUaGUgYWxpZ25tZW50IG9mIHRoZSBjb250ZW50IHdpdGhpbiB0aGUg
Y2VsbC4KCgwKBQQBBAABEgM2BxoKMgoGBAEEAAIAEgM4BBQaIyBVbnNwZWNpZmllZCBob3Jp
em9udGFsIGFsaWdubWVudC4KCg4KBwQBBAACAAESAzgEDwoOCgcEAQQAAgACEgM4EhMKPwoG
BAEEAAIBEgM7BBAaMCBMZWFkaW5nIGVkZ2Ugb2YgdGhlIGNlbGwuIFRoaXMgaXMgdGhlIGRl
ZmF1bHQuCgoOCgcEAQQAAgEBEgM7BAsKDgoHBAEEAAIBAhIDOw4PCkAKBgQBBAACAhIDPgQP
GjEgQ29udGVudCBpcyBhbGlnbmVkIHRvIHRoZSBjZW50ZXIgb2YgdGhlIGNvbHVtbi4KCg4K
BwQBBAACAgESAz4ECgoOCgcEAQQAAgICEgM+DQ4KRwoGBAEEAAIDEgNBBBEaOCBDb250ZW50
IGlzIGFsaWduZWQgdG8gdGhlIHRyYWlsaW5nIGVkZ2Ugb2YgdGhlIGNvbHVtbi4KCg4KBwQB
BAACAwESA0EEDAoOCgcEAQQAAgMCEgNBDxAKKgoEBAECABIDRQIUGh0gSGVhZGVyIHRleHQg
Zm9yIHRoZSBjb2x1bW4uCgoMCgUEAQIABRIDRQIICgwKBQQBAgABEgNFCQ8KDAoFBAECAAMS
A0USEwp6CgQEAQIBEgNJAiAabSBIb3Jpem9udGFsIGFsaWdubWVudCBvZiBjb250ZW50IHcu
ci50IGNvbHVtbi4gSWYgdW5zcGVjaWZpZWQsIGNvbnRlbnQKIHdpbGwgYmUgYWxpZ25lZCB0
byB0aGUgbGVhZGluZyBlZGdlLgoKDAoFBAECAQYSA0kCFQoMCgUEAQIBARIDSRYbCgwKBQQB
AgEDEgNJHh8KKAoCBAISBE0AUAEaHCBEZXNjcmliZXMgYSBjZWxsIGluIGEgcm93LgoKCgoD
BAIBEgNNCBEKKAoEBAICABIDTwISGhsgVGV4dCBjb250ZW50IG9mIHRoZSBjZWxsLgoKDAoF
BAICAAUSA08CCAoMCgUEAgIAARIDTwkNCgwKBQQCAgADEgNPEBEKKwoCBAMSBFMAWwEaHyBE
ZXNjcmliZXMgYSByb3cgaW4gdGhlIHRhYmxlLgoKCgoDBAMBEgNTCBAK0wEKBAQDAgASA1cC
HxrFASBDZWxscyBpbiB0aGlzIHJvdy4gVGhlIGZpcnN0IDMgY2VsbHMgYXJlIGd1YXJhbnRl
ZWQgdG8gYmUgc2hvd24gYnV0CiBvdGhlcnMgbWlnaHQgYmUgY3V0IG9uIGNlcnRhaW4gc3Vy
ZmFjZXMuIFBsZWFzZSB0ZXN0IHdpdGggdGhlIHNpbXVsYXRvcgogdG8gc2VlIHdoaWNoIGNl
bGxzIHdpbGwgYmUgc2hvd24gZm9yIGEgZ2l2ZW4gc3VyZmFjZS4KCgwKBQQDAgAEEgNXAgoK
DAoFBAMCAAYSA1cLFAoMCgUEAwIAARIDVxUaCgwKBQQDAgADEgNXHR4KSgoEBAMCARIDWgIT
Gj0gSW5kaWNhdGVzIHdoZXRoZXIgdGhlcmUgc2hvdWxkIGJlIGEgZGl2aWRlciBhZnRlciBl
YWNoIHJvdy4KCgwKBQQDAgEFEgNaAgYKDAoFBAMCAQESA1oHDgoMCgUEAwIBAxIDWhESYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Table::Table ===
    # Fields for Table
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: image Type: 11 (.google.actions.sdk.v2.conversation.Image)
    # Field: columns Type: 11 (.google.actions.sdk.v2.conversation.TableColumn)
    # Field: rows Type: 11 (.google.actions.sdk.v2.conversation.TableRow)
    # Field: button Type: 11 (.google.actions.sdk.v2.conversation.Link)

# === Message: Google::Actions::Sdk::V2::Conversation::Table::TableColumn ===
    # Fields for TableColumn
    # Field: header Type: 9 ()
    # Field: align Type: 14 (.google.actions.sdk.v2.conversation.TableColumn.HorizontalAlignment)

# Enum: TableColumn::HorizontalAlignment
our $TableColumn_UNSPECIFIED = 0;
our $TableColumn_LEADING = 1;
our $TableColumn_CENTER = 2;
our $TableColumn_TRAILING = 3;

# === Message: Google::Actions::Sdk::V2::Conversation::Table::TableCell ===
    # Fields for TableCell
    # Field: text Type: 9 ()

# === Message: Google::Actions::Sdk::V2::Conversation::Table::TableRow ===
    # Fields for TableRow
    # Field: cells Type: 11 (.google.actions.sdk.v2.conversation.TableCell)
    # Field: divider Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Table - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/table.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Table;

    my $msg = Google::Actions::Sdk::V2::Conversation::Table::Table->new({
        title => $title,
        subtitle => $subtitle,
        image => $image,
        columns => $columns,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Table::Table->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/table.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Table::Table

A table card for displaying a table of text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Overall title of the table. Optional but must be set if subtitle is set.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Subtitle for the table. Optional.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Image::Image>)

Image associated with the table. Optional.

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Table::TableColumn>)

Headers and alignment of columns.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Table::TableRow>)

Row data of the table. The first 3 rows are guaranteed to be shown but
others might be cut on certain surfaces. Please test with the simulator to
see which rows will be shown for a given surface. On surfaces that support
the WEB_BROWSER capability, you can point the user to
a web page with more data.

=item * C<< $msg->button() >> / C<< $msg->button($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Link::Link>)

Button.

=back

=head2 Google::Actions::Sdk::V2::Conversation::Table::TableColumn

Describes a column in a table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->header() >> / C<< $msg->header($value) >>

Type: C<String>

Header text for the column.

=item * C<< $msg->align() >> / C<< $msg->align($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::TableColumn::HorizontalAlignment>)

Horizontal alignment of content w.r.t column. If unspecified, content
will be aligned to the leading edge.

=back

=head3 Enum: TableColumn::HorizontalAlignment

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<LEADING> => C<1>

=item * C<CENTER> => C<2>

=item * C<TRAILING> => C<3>

=back

=head2 Google::Actions::Sdk::V2::Conversation::Table::TableCell

Describes a cell in a row.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Text content of the cell.

=back

=head2 Google::Actions::Sdk::V2::Conversation::Table::TableRow

Describes a row in the table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cells() >> / C<< $msg->cells($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Table::TableCell>)

Cells in this row. The first 3 cells are guaranteed to be shown but
others might be cut on certain surfaces. Please test with the simulator
to see which cells will be shown for a given surface.

=item * C<< $msg->divider() >> / C<< $msg->divider($value) >>

Type: C<Bool>

Indicates whether there should be a divider after each row.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Table::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
