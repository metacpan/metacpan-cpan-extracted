package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ck9nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfdGFibGVfcHJvbXB0LnByb3RvEi1nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50
ZXJhY3Rpb25tb2RlbC5wcm9tcHQaT2dvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlv
bm1vZGVsL3Byb21wdC9jb250ZW50L3N0YXRpY19pbWFnZV9wcm9tcHQucHJvdG8aTmdvb2ds
ZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3Byb21wdC9jb250ZW50L3N0YXRp
Y19saW5rX3Byb21wdC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byK3
AwoRU3RhdGljVGFibGVQcm9tcHQSGQoFdGl0bGUYASABKAlCA+BBAVIFdGl0bGUSHwoIc3Vi
dGl0bGUYAiABKAlCA+BBAVIIc3VidGl0bGUSWwoFaW1hZ2UYAyABKAsyQC5nb29nbGUuYWN0
aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3RhdGljSW1hZ2VQcm9tcHRC
A+BBAVIFaW1hZ2USWQoHY29sdW1ucxgEIAMoCzI6Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5p
bnRlcmFjdGlvbm1vZGVsLnByb21wdC5UYWJsZUNvbHVtbkID4EEBUgdjb2x1bW5zElAKBHJv
d3MYBSADKAsyNy5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9t
cHQuVGFibGVSb3dCA+BBAVIEcm93cxJcCgZidXR0b24YBiABKAsyPy5nb29nbGUuYWN0aW9u
cy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3RhdGljTGlua1Byb21wdEID4EEB
UgZidXR0b24i2gEKC1RhYmxlQ29sdW1uEhYKBmhlYWRlchgBIAEoCVIGaGVhZGVyEmQKBWFs
aWduGAIgASgOMk4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJv
bXB0LlRhYmxlQ29sdW1uLkhvcml6b250YWxBbGlnbm1lbnRSBWFsaWduIk0KE0hvcml6b250
YWxBbGlnbm1lbnQSDwoLVU5TUEVDSUZJRUQQABILCgdMRUFESU5HEAESCgoGQ0VOVEVSEAIS
DAoIVFJBSUxJTkcQAyIfCglUYWJsZUNlbGwSEgoEdGV4dBgBIAEoCVIEdGV4dCJ0CghUYWJs
ZVJvdxJOCgVjZWxscxgBIAMoCzI4Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlv
bm1vZGVsLnByb21wdC5UYWJsZUNlbGxSBWNlbGxzEhgKB2RpdmlkZXIYAiABKAhSB2Rpdmlk
ZXJCogEKMWNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9t
cHRCFlN0YXRpY1RhYmxlUHJvbXB0UHJvdG9QAVpTZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJv
dG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3Byb21wdDtw
cm9tcHRKnBkKBhIEDgBcAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAANgoJCgIDABIDEgBZCgkKAgMBEgMTAFgKCQoCAwISAxQAKQoICgEIEgMWAGoKCQoC
CAsSAxYAagoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADcKCQoCCAgSAxgANwoICgEI
EgMZAEoKCQoCCAESAxkASgo6CgIEABIEHAAyARouIEEgdGFibGUgY2FyZCBmb3IgZGlzcGxh
eWluZyBhIHRhYmxlIG9mIHRleHQuCgoKCgMEAAESAxwIGQpUCgQEAAIAEgMeAjwaRyBPcHRp
b25hbC4gT3ZlcmFsbCB0aXRsZSBvZiB0aGUgdGFibGUuIE11c3QgYmUgc2V0IGlmIHN1YnRp
dGxlIGlzIHNldC4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JDgoMCgUEAAIAAxIDHhES
CgwKBQQAAgAIEgMeEzsKDwoIBAACAAicCAASAx4UOgowCgQEAAIBEgMhAj8aIyBPcHRpb25h
bC4gU3VidGl0bGUgZm9yIHRoZSB0YWJsZS4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJ
EQoMCgUEAAIBAxIDIRQVCgwKBQQAAgEIEgMhFj4KDwoIBAACAQicCAASAyEXPQo5CgQEAAIC
EgMkAkcaLCBPcHRpb25hbC4gSW1hZ2UgYXNzb2NpYXRlZCB3aXRoIHRoZSB0YWJsZS4KCgwK
BQQAAgIGEgMkAhMKDAoFBAACAgESAyQUGQoMCgUEAAICAxIDJBwdCgwKBQQAAgIIEgMkHkYK
DwoIBAACAgicCAASAyQfRQo6CgQEAAIDEgMnAkwaLSBPcHRpb25hbC4gSGVhZGVycyBhbmQg
YWxpZ25tZW50IG9mIGNvbHVtbnMuCgoMCgUEAAIDBBIDJwIKCgwKBQQAAgMGEgMnCxYKDAoF
BAACAwESAycXHgoMCgUEAAIDAxIDJyEiCgwKBQQAAgMIEgMnI0sKDwoIBAACAwicCAASAyck
SgrNAgoEBAACBBIDLgJGGr8CIE9wdGlvbmFsLiBSb3cgZGF0YSBvZiB0aGUgdGFibGUuIFRo
ZSBmaXJzdCAzIHJvd3MgYXJlIGd1YXJhbnRlZWQgdG8gYmUgc2hvd24gYnV0CiBvdGhlcnMg
bWlnaHQgYmUgY3V0IG9uIGNlcnRhaW4gc3VyZmFjZXMuIFBsZWFzZSB0ZXN0IHdpdGggdGhl
IHNpbXVsYXRvciB0bwogc2VlIHdoaWNoIHJvd3Mgd2lsbCBiZSBzaG93biBmb3IgYSBnaXZl
biBzdXJmYWNlLiBPbiBzdXJmYWNlcyB0aGF0IHN1cHBvcnQKIHRoZSBgV0VCX0JST1dTRVJg
IGNhcGFiaWxpdHksIHlvdSBjYW4gcG9pbnQgdGhlIHVzZXIgdG8KIGEgd2ViIHBhZ2Ugd2l0
aCBtb3JlIGRhdGEuCgoMCgUEAAIEBBIDLgIKCgwKBQQAAgQGEgMuCxMKDAoFBAACBAESAy4U
GAoMCgUEAAIEAxIDLhscCgwKBQQAAgQIEgMuHUUKDwoIBAACBAicCAASAy4eRAogCgQEAAIF
EgMxAkcaEyBPcHRpb25hbC4gQnV0dG9uLgoKDAoFBAACBQYSAzECEgoMCgUEAAIFARIDMRMZ
CgwKBQQAAgUDEgMxHB0KDAoFBAACBQgSAzEeRgoPCggEAAIFCJwIABIDMR9FCi4KAgQBEgQ1
AEsBGiIgRGVzY3JpYmVzIGEgY29sdW1uIGluIHRoZSB0YWJsZS4KCgoKAwQBARIDNQgTCj0K
BAQBBAASBDcCQwMaLyBUaGUgYWxpZ25tZW50IG9mIHRoZSBjb250ZW50IHdpdGhpbiB0aGUg
Y2VsbC4KCgwKBQQBBAABEgM3BxoKMQoGBAEEAAIAEgM5BBQaIiBIb3Jpem9udGFsQWxpZ25t
ZW50IHVuc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDOQQPCg4KBwQBBAACAAISAzkSEwo/CgYE
AQQAAgESAzwEEBowIExlYWRpbmcgZWRnZSBvZiB0aGUgY2VsbC4gVGhpcyBpcyB0aGUgZGVm
YXVsdC4KCg4KBwQBBAACAQESAzwECwoOCgcEAQQAAgECEgM8Dg8KQAoGBAEEAAICEgM/BA8a
MSBDb250ZW50IGlzIGFsaWduZWQgdG8gdGhlIGNlbnRlciBvZiB0aGUgY29sdW1uLgoKDgoH
BAEEAAICARIDPwQKCg4KBwQBBAACAgISAz8NDgpHCgYEAQQAAgMSA0IEERo4IENvbnRlbnQg
aXMgYWxpZ25lZCB0byB0aGUgdHJhaWxpbmcgZWRnZSBvZiB0aGUgY29sdW1uLgoKDgoHBAEE
AAIDARIDQgQMCg4KBwQBBAACAwISA0IPEAoqCgQEAQIAEgNGAhQaHSBIZWFkZXIgdGV4dCBm
b3IgdGhlIGNvbHVtbi4KCgwKBQQBAgAFEgNGAggKDAoFBAECAAESA0YJDwoMCgUEAQIAAxID
RhITCnoKBAQBAgESA0oCIBptIEhvcml6b250YWwgYWxpZ25tZW50IG9mIGNvbnRlbnQgdy5y
LnQgY29sdW1uLiBJZiB1bnNwZWNpZmllZCwgY29udGVudAogd2lsbCBiZSBhbGlnbmVkIHRv
IHRoZSBsZWFkaW5nIGVkZ2UuCgoMCgUEAQIBBhIDSgIVCgwKBQQBAgEBEgNKFhsKDAoFBAEC
AQMSA0oeHwooCgIEAhIETgBRARocIERlc2NyaWJlcyBhIGNlbGwgaW4gYSByb3cuCgoKCgME
AgESA04IEQooCgQEAgIAEgNQAhIaGyBUZXh0IGNvbnRlbnQgb2YgdGhlIGNlbGwuCgoMCgUE
AgIABRIDUAIICgwKBQQCAgABEgNQCQ0KDAoFBAICAAMSA1AQEQorCgIEAxIEVABcARofIERl
c2NyaWJlcyBhIHJvdyBpbiB0aGUgdGFibGUuCgoKCgMEAwESA1QIEArTAQoEBAMCABIDWAIf
GsUBIENlbGxzIGluIHRoaXMgcm93LiBUaGUgZmlyc3QgMyBjZWxscyBhcmUgZ3VhcmFudGVl
ZCB0byBiZSBzaG93biBidXQKIG90aGVycyBtaWdodCBiZSBjdXQgb24gY2VydGFpbiBzdXJm
YWNlcy4gUGxlYXNlIHRlc3Qgd2l0aCB0aGUgc2ltdWxhdG9yCiB0byBzZWUgd2hpY2ggY2Vs
bHMgd2lsbCBiZSBzaG93biBmb3IgYSBnaXZlbiBzdXJmYWNlLgoKDAoFBAMCAAQSA1gCCgoM
CgUEAwIABhIDWAsUCgwKBQQDAgABEgNYFRoKDAoFBAMCAAMSA1gdHgpKCgQEAwIBEgNbAhMa
PSBJbmRpY2F0ZXMgd2hldGhlciB0aGVyZSBzaG91bGQgYmUgYSBkaXZpZGVyIGFmdGVyIGVh
Y2ggcm93LgoKDAoFBAMCAQUSA1sCBgoMCgUEAwIBARIDWwcOCgwKBQQDAgEDEgNbERJiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt ===
    # Fields for StaticTablePrompt
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: image Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt)
    # Field: columns Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.TableColumn)
    # Field: rows Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.TableRow)
    # Field: button Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticLinkPrompt)

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableColumn ===
    # Fields for TableColumn
    # Field: header Type: 9 ()
    # Field: align Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.TableColumn.HorizontalAlignment)

# Enum: TableColumn::HorizontalAlignment
our $TableColumn_UNSPECIFIED = 0;
our $TableColumn_LEADING = 1;
our $TableColumn_CENTER = 2;
our $TableColumn_TRAILING = 3;

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableCell ===
    # Fields for TableCell
    # Field: text Type: 9 ()

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableRow ===
    # Fields for TableRow
    # Field: cells Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.TableCell)
    # Field: divider Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_table_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt->new({
        title => $title,
        subtitle => $subtitle,
        image => $image,
        columns => $columns,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_table_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt

A table card for displaying a table of text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. Overall title of the table. Must be set if subtitle is set.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Optional. Subtitle for the table.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt>)

Optional. Image associated with the table.

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableColumn>)

Optional. Headers and alignment of columns.

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableRow>)

Optional. Row data of the table. The first 3 rows are guaranteed to be shown but
others might be cut on certain surfaces. Please test with the simulator to
see which rows will be shown for a given surface. On surfaces that support
the `WEB_BROWSER` capability, you can point the user to
a web page with more data.

=item * C<< $msg->button() >> / C<< $msg->button($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::StaticLinkPrompt>)

Optional. Button.

=back

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableColumn

Describes a column in the table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->header() >> / C<< $msg->header($value) >>

Type: C<String>

Header text for the column.

=item * C<< $msg->align() >> / C<< $msg->align($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::TableColumn::HorizontalAlignment>)

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

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableCell

Describes a cell in a row.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Text content of the cell.

=back

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableRow

Describes a row in the table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cells() >> / C<< $msg->cells($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableCell>)

Cells in this row. The first 3 cells are guaranteed to be shown but
others might be cut on certain surfaces. Please test with the simulator
to see which cells will be shown for a given surface.

=item * C<< $msg->divider() >> / C<< $msg->divider($value) >>

Type: C<Bool>

Indicates whether there should be a divider after each row.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
