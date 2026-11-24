package Google::Actions::Sdk::V2::LocalizedSettings;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::ThemeCustomization };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvYWN0aW9ucy9zZGsvdjIvbG9jYWxpemVkX3NldHRpbmdzLnByb3RvEhVnb29n
bGUuYWN0aW9ucy5zZGsudjIaL2dvb2dsZS9hY3Rpb25zL3Nkay92Mi90aGVtZV9jdXN0b21p
emF0aW9uLnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIsUFChFMb2Nh
bGl6ZWRTZXR0aW5ncxImCgxkaXNwbGF5X25hbWUYASABKAlCA+BBAlILZGlzcGxheU5hbWUS
KQoNcHJvbnVuY2lhdGlvbhgCIAEoCUID4EECUg1wcm9udW5jaWF0aW9uEjAKEXNob3J0X2Rl
c2NyaXB0aW9uGAMgASgJQgPgQQJSEHNob3J0RGVzY3JpcHRpb24SLgoQZnVsbF9kZXNjcmlw
dGlvbhgEIAEoCUID4EECUg9mdWxsRGVzY3JpcHRpb24SLQoQc21hbGxfbG9nb19pbWFnZRgF
IAEoCUID4EECUg5zbWFsbExvZ29JbWFnZRIxChJsYXJnZV9iYW5uZXJfaW1hZ2UYBiABKAlC
A+BBAVIQbGFyZ2VCYW5uZXJJbWFnZRIqCg5kZXZlbG9wZXJfbmFtZRgHIAEoCUID4EECUg1k
ZXZlbG9wZXJOYW1lEiwKD2RldmVsb3Blcl9lbWFpbBgIIAEoCUID4EECUg5kZXZlbG9wZXJF
bWFpbBI0ChR0ZXJtc19vZl9zZXJ2aWNlX3VybBgJIAEoCUID4EEBUhF0ZXJtc09mU2Vydmlj
ZVVybBIZCgV2b2ljZRgKIAEoCUID4EECUgV2b2ljZRImCgx2b2ljZV9sb2NhbGUYDiABKAlC
A+BBAVILdm9pY2VMb2NhbGUSMQoScHJpdmFjeV9wb2xpY3lfdXJsGAsgASgJQgPgQQJSEHBy
aXZhY3lQb2xpY3lVcmwSMgoSc2FtcGxlX2ludm9jYXRpb25zGAwgAygJQgPgQQFSEXNhbXBs
ZUludm9jYXRpb25zEl8KE3RoZW1lX2N1c3RvbWl6YXRpb24YDSABKAsyKS5nb29nbGUuYWN0
aW9ucy5zZGsudjIuVGhlbWVDdXN0b21pemF0aW9uQgPgQQFSEnRoZW1lQ3VzdG9taXphdGlv
bkJvChljb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyQhZMb2NhbGl6ZWRTZXR0aW5nc1Byb3Rv
UAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsv
djI7c2RrSoQhCgYSBA4AWwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQAB4KCQoCAwASAxIAOQoJCgIDARIDEwApCggKAQgSAxUATwoJCgIICxIDFQBPCggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANwoJCgIICBIDFwA3CggKAQgSAxgAMgoJCgII
ARIDGAAyCsMBCgIEABIEHQBbARq2ASBSZXByZXNlbnRzIHNldHRpbmdzIG9mIGFuIEFjdGlv
bnMgcHJvamVjdCB0aGF0IGFyZSBzcGVjaWZpYyB0byBhIHVzZXIgbG9jYWxlLgogSW4gdGhp
cyBpbnN0YW5jZSwgdXNlciBtZWFucyB0aGUgZW5kIHVzZXIgd2hvIGludm9rZXMgeW91ciBB
Y3Rpb25zLgogKipUaGlzIG1lc3NhZ2UgaXMgbG9jYWxpemFibGUuKioKCgoKAwQAARIDHQgZ
CnIKBAQAAgASAyACQxplIFJlcXVpcmVkLiBUaGUgZGVmYXVsdCBkaXNwbGF5IG5hbWUgZm9y
IHRoaXMgQWN0aW9ucyBwcm9qZWN0IChpZiB0aGVyZSBpcyBubwogdHJhbnNsYXRpb24gYXZh
aWxhYmxlKQoKDAoFBAACAAUSAyACCAoMCgUEAAIAARIDIAkVCgwKBQQAAgADEgMgGBkKDAoF
BAACAAgSAyAaQgoPCggEAAIACJwIABIDIBtBCm0KBAQAAgESAyQCRBpgIFJlcXVpcmVkLiBU
aGUgcHJvbnVuY2lhdGlvbiBvZiB0aGUgZGlzcGxheSBuYW1lIHRvIGludm9rZSBpdCB3aXRo
aW4gYSB2b2ljZQogKHNwb2tlbikgY29udGV4dC4KCgwKBQQAAgEFEgMkAggKDAoFBAACAQES
AyQJFgoMCgUEAAIBAxIDJBkaCgwKBQQAAgEIEgMkG0MKDwoIBAACAQicCAASAyQcQgqLAQoE
BAACAhIDKAJIGn4gUmVxdWlyZWQuIFRoZSBkZWZhdWx0IHNob3J0IGRlc2NyaXB0aW9uIGZv
ciB0aGUgQWN0aW9ucyBwcm9qZWN0IChpZiB0aGVyZSBpcyBubwogdHJhbnNsYXRpb24gYXZh
aWxhYmxlKS4gODAgY2hhcmFjdGVyIGxpbWl0LgoKDAoFBAACAgUSAygCCAoMCgUEAAICARID
KAkaCgwKBQQAAgIDEgMoHR4KDAoFBAACAggSAygfRwoPCggEAAICCJwIABIDKCBGCowBCgQE
AAIDEgMsAkcafyBSZXF1aXJlZC4gVGhlIGRlZmF1bHQgbG9uZyBkZXNjcmlwdGlvbiBmb3Ig
dGhlIEFjdGlvbnMgcHJvamVjdCAoaWYgdGhlcmUgaXMgbm8KIHRyYW5zbGF0aW9uIGF2YWls
YWJsZSkuIDQwMDAgY2hhcmFjdGVyIGxpbWl0LgoKDAoFBAACAwUSAywCCAoMCgUEAAIDARID
LAkZCgwKBQQAAgMDEgMsHB0KDAoFBAACAwgSAyweRgoPCggEAAIDCJwIABIDLB9FCpYDCgQE
AAIEEgM0AkcaiAMgUmVxdWlyZWQuIFNtYWxsIHNxdWFyZSBpbWFnZSwgMTkyIHggMTkyIHB4
LgogVGhpcyBzaG91bGQgYmUgc3BlY2lmaWVkIGFzIGEgcmVmZXJlbmNlIHRvIHRoZSBjb3Jy
ZXNwb25kaW5nIGltYWdlIGluIHRoZQogYHJlc291cmNlcy9pbWFnZXMvYCBkaXJlY3Rvcnku
IEZvciBleGFtcGxlLCBgJHJlc291cmNlcy5pbWFnZXMuZm9vYCAod2l0aG91dCB0aGUKIGV4
dGVuc2lvbikgZm9yIGltYWdlIGluIGByZXNvdXJjZXMvaW1hZ2VzL2Zvby5qcGdgCiBXaGVu
IHdvcmtpbmcgb24gYSBwcm9qZWN0IHB1bGxlZCBmcm9tIENvbnNvbGUsIHRoZSBHb29nbGUt
bWFuYWdlZCBVUkwKIHB1bGxlZCBjb3VsZCBiZSB1c2VkLiBVUkxzIGZyb20gZXh0ZXJuYWwg
c291cmNlcyBhcmUgbm90IGFsbG93ZWQuCgoMCgUEAAIEBRIDNAIICgwKBQQAAgQBEgM0CRkK
DAoFBAACBAMSAzQcHQoMCgUEAAIECBIDNB5GCg8KCAQAAgQInAgAEgM0H0UKmwMKBAQAAgUS
AzwCSRqNAyBPcHRpb25hbC4gTGFyZ2UgbGFuZHNjYXBlIGltYWdlLCAxOTIwIHggMTA4MCBw
eC4KIFRoaXMgc2hvdWxkIGJlIHNwZWNpZmllZCBhcyBhIHJlZmVyZW5jZSB0byB0aGUgY29y
cmVzcG9uZGluZyBpbWFnZSBpbiB0aGUKIGByZXNvdXJjZXMvaW1hZ2VzL2AgZGlyZWN0b3J5
LiBGb3IgZXhhbXBsZSwgYCRyZXNvdXJjZXMuaW1hZ2VzLmZvb2AgKHdpdGhvdXQgdGhlCiBl
eHRlbnNpb24pIGZvciBpbWFnZSBpbiBgcmVzb3VyY2VzL2ltYWdlcy9mb28uanBnYAogV2hl
biB3b3JraW5nIG9uIGEgcHJvamVjdCBwdWxsZWQgZnJvbSBDb25zb2xlLCB0aGUgR29vZ2xl
LW1hbmFnZWQgVVJMCiBwdWxsZWQgY291bGQgYmUgdXNlZC4gVVJMcyBmcm9tIGV4dGVybmFs
IHNvdXJjZXMgYXJlIG5vdCBhbGxvd2VkLgoKDAoFBAACBQUSAzwCCAoMCgUEAAIFARIDPAkb
CgwKBQQAAgUDEgM8Hh8KDAoFBAACBQgSAzwgSAoPCggEAAIFCJwIABIDPCFHCkwKBAQAAgYS
Az8CRRo/IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgZGV2ZWxvcGVyIHRvIGJlIGRpc3Bs
YXllZCB0byB1c2Vycy4KCgwKBQQAAgYFEgM/AggKDAoFBAACBgESAz8JFwoMCgUEAAIGAxID
PxobCgwKBQQAAgYIEgM/HEQKDwoIBAACBgicCAASAz8dQwpFCgQEAAIHEgNCAkYaOCBSZXF1
aXJlZC4gVGhlIGNvbnRhY3QgZW1haWwgYWRkcmVzcyBmb3IgdGhlIGRldmVsb3Blci4KCgwK
BQQAAgcFEgNCAggKDAoFBAACBwESA0IJGAoMCgUEAAIHAxIDQhscCgwKBQQAAgcIEgNCHUUK
DwoIBAACBwicCAASA0IeRAoyCgQEAAIIEgNFAksaJSBPcHRpb25hbC4gVGhlIHRlcm1zIG9m
IHNlcnZpY2UgVVJMLgoKDAoFBAACCAUSA0UCCAoMCgUEAAIIARIDRQkdCgwKBQQAAggDEgNF
ICEKDAoFBAACCAgSA0UiSgoPCggEAAIICJwIABIDRSNJCroBCgQEAAIJEgNKAj0arAEgUmVx
dWlyZWQuIFRoZSBHb29nbGUgQXNzaXN0YW50IHZvaWNlIHR5cGUgdGhhdCB1c2VycyBoZWFy
IHdoZW4gdGhleSBpbnRlcmFjdCB3aXRoCiB5b3VyIEFjdGlvbnMuIFRoZSBzdXBwb3J0ZWQg
dmFsdWVzIGFyZSAibWFsZV8xIiwgIm1hbGVfMiIsICJmZW1hbGVfMSIsIGFuZAogImZlbWFs
ZV8yIi4KCgwKBQQAAgkFEgNKAggKDAoFBAACCQESA0oJDgoMCgUEAAIJAxIDShETCgwKBQQA
AgkIEgNKFDwKDwoIBAACCQicCAASA0oVOwrtAQoEBAACChIDTwJEGt8BIE9wdGlvbmFsLiBU
aGUgbG9jYWxlIGZvciB0aGUgc3BlY2lmaWVkIHZvaWNlLiBJZiBub3Qgc3BlY2lmaWVkLCB0
aGlzIHJlc29sdmVzCiB0byB0aGUgdXNlcidzIEFzc2lzdGFudCBsb2NhbGUuIElmIHNwZWNp
ZmllZCwgdGhlIHZvaWNlIGxvY2FsZSBtdXN0IGhhdmUKIHRoZSBzYW1lIHJvb3QgbGFuZ3Vh
Z2UgYXMgdGhlIGxvY2FsZSBzcGVjaWZpZWQgaW4gTG9jYWxpemVkU2V0dGluZ3MuCgoMCgUE
AAIKBRIDTwIICgwKBQQAAgoBEgNPCRUKDAoFBAACCgMSA08YGgoMCgUEAAIKCBIDTxtDCg8K
CAQAAgoInAgAEgNPHEIKMAoEBAACCxIDUgJKGiMgUmVxdWlyZWQuIFRoZSBwcml2YWN5IHBv
bGljeSBVUkwuCgoMCgUEAAILBRIDUgIICgwKBQQAAgsBEgNSCRsKDAoFBAACCwMSA1IeIAoM
CgUEAAILCBIDUiFJCg8KCAQAAgsInAgAEgNSIkgKswEKBAQAAgwSA1cCUxqlASBPcHRpb25h
bC4gU2FtcGxlIGludm9jYXRpb24gcGhyYXNlcyBkaXNwbGF5ZWQgYXMgcGFydCBvZiB5b3Vy
IEFjdGlvbnMgcHJvamVjdCdzCiBkZXNjcmlwdGlvbiBpbiB0aGUgQXNzaXN0YW50IGRpcmVj
dG9yeS4gVGhpcyB3aWxsIGhlbHAgdXNlcnMgbGVhcm4gaG93IHRvCiB1c2UgaXQuCgoMCgUE
AAIMBBIDVwIKCgwKBQQAAgwFEgNXCxEKDAoFBAACDAESA1cSJAoMCgUEAAIMAxIDVycpCgwK
BQQAAgwIEgNXKlIKDwoIBAACDAicCAASA1crUQpUCgQEAAINEgNaAlcaRyBPcHRpb25hbC4g
VGhlbWUgY3VzdG9taXphdGlvbnMgZm9yIHZpc3VhbCBjb21wb25lbnRzIG9mIHlvdXIgQWN0
aW9ucy4KCgwKBQQAAg0GEgNaAhQKDAoFBAACDQESA1oVKAoMCgUEAAINAxIDWistCgwKBQQA
Ag0IEgNaLlYKDwoIBAACDQicCAASA1ovVWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings ===
    # Fields for LocalizedSettings
    # Field: display_name Type: 9 ()
    # Field: pronunciation Type: 9 ()
    # Field: short_description Type: 9 ()
    # Field: full_description Type: 9 ()
    # Field: small_logo_image Type: 9 ()
    # Field: large_banner_image Type: 9 ()
    # Field: developer_name Type: 9 ()
    # Field: developer_email Type: 9 ()
    # Field: terms_of_service_url Type: 9 ()
    # Field: voice Type: 9 ()
    # Field: voice_locale Type: 9 ()
    # Field: privacy_policy_url Type: 9 ()
    # Field: sample_invocations Type: 9 ()
    # Field: theme_customization Type: 11 (.google.actions.sdk.v2.ThemeCustomization)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::LocalizedSettings - Compiled Protocol Buffers messages for google/actions/sdk/v2/localized_settings.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::LocalizedSettings;

    my $msg = Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings->new({
        display_name => $display_name,
        pronunciation => $pronunciation,
        short_description => $short_description,
        full_description => $full_description,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/localized_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings

Represents settings of an Actions project that are specific to a user locale.
In this instance, user means the end user who invokes your Actions.
B<This message is localizable.>

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The default display name for this Actions project (if there is no
translation available)

=item * C<< $msg->pronunciation() >> / C<< $msg->pronunciation($value) >>

Type: C<String>

Required. The pronunciation of the display name to invoke it within a voice
(spoken) context.

=item * C<< $msg->short_description() >> / C<< $msg->short_description($value) >>

Type: C<String>

Required. The default short description for the Actions project (if there is no
translation available). 80 character limit.

=item * C<< $msg->full_description() >> / C<< $msg->full_description($value) >>

Type: C<String>

Required. The default long description for the Actions project (if there is no
translation available). 4000 character limit.

=item * C<< $msg->small_logo_image() >> / C<< $msg->small_logo_image($value) >>

Type: C<String>

Required. Small square image, 192 x 192 px.
This should be specified as a reference to the corresponding image in the
`resources/images/` directory. For example, `$resources.images.foo` (without the
extension) for image in `resources/images/foo.jpg`
When working on a project pulled from Console, the Google-managed URL
pulled could be used. URLs from external sources are not allowed.

=item * C<< $msg->large_banner_image() >> / C<< $msg->large_banner_image($value) >>

Type: C<String>

Optional. Large landscape image, 1920 x 1080 px.
This should be specified as a reference to the corresponding image in the
`resources/images/` directory. For example, `$resources.images.foo` (without the
extension) for image in `resources/images/foo.jpg`
When working on a project pulled from Console, the Google-managed URL
pulled could be used. URLs from external sources are not allowed.

=item * C<< $msg->developer_name() >> / C<< $msg->developer_name($value) >>

Type: C<String>

Required. The name of the developer to be displayed to users.

=item * C<< $msg->developer_email() >> / C<< $msg->developer_email($value) >>

Type: C<String>

Required. The contact email address for the developer.

=item * C<< $msg->terms_of_service_url() >> / C<< $msg->terms_of_service_url($value) >>

Type: C<String>

Optional. The terms of service URL.

=item * C<< $msg->voice() >> / C<< $msg->voice($value) >>

Type: C<String>

Required. The Google Assistant voice type that users hear when they interact with
your Actions. The supported values are "male_1", "male_2", "female_1", and
"female_2".

=item * C<< $msg->voice_locale() >> / C<< $msg->voice_locale($value) >>

Type: C<String>

Optional. The locale for the specified voice. If not specified, this resolves
to the user's Assistant locale. If specified, the voice locale must have
the same root language as the locale specified in LocalizedSettings.

=item * C<< $msg->privacy_policy_url() >> / C<< $msg->privacy_policy_url($value) >>

Type: C<String>

Required. The privacy policy URL.

=item * C<< $msg->sample_invocations() >> / C<< $msg->sample_invocations($value) >>

Type: C<String>

Optional. Sample invocation phrases displayed as part of your Actions project's
description in the Assistant directory. This will help users learn how to
use it.

=item * C<< $msg->theme_customization() >> / C<< $msg->theme_customization($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization>)

Optional. Theme customizations for visual components of your Actions.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::LocalizedSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
