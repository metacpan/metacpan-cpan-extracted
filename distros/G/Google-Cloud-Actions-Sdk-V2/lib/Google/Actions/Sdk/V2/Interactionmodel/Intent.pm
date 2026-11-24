package Google::Actions::Sdk::V2::Interactionmodel::Intent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9pbnRlbnQucHJvdG8S
Jmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsGkFnb29nbGUvYWN0aW9u
cy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL2NsYXNzX3JlZmVyZW5jZS5wcm90bxof
Z29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKtBQoGSW50ZW50El4KCnBhcmFtZXRl
cnMYASADKAsyPi5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5JbnRl
bnQuSW50ZW50UGFyYW1ldGVyUgpwYXJhbWV0ZXJzEikKEHRyYWluaW5nX3BocmFzZXMYAiAD
KAlSD3RyYWluaW5nUGhyYXNlcxqXBAoPSW50ZW50UGFyYW1ldGVyEhcKBG5hbWUYASABKAlC
A+BBAlIEbmFtZRJWCgR0eXBlGAIgASgLMjsuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVy
YWN0aW9ubW9kZWwudHlwZS5DbGFzc1JlZmVyZW5jZUID4EEBSABSBHR5cGUSjQEKFWVudGl0
eV9zZXRfcmVmZXJlbmNlcxgDIAEoCzJSLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFj
dGlvbm1vZGVsLkludGVudC5JbnRlbnRQYXJhbWV0ZXIuRW50aXR5U2V0UmVmZXJlbmNlc0ID
4EEBSABSE2VudGl0eVNldFJlZmVyZW5jZXMa8AEKE0VudGl0eVNldFJlZmVyZW5jZXMSngEK
FWVudGl0eV9zZXRfcmVmZXJlbmNlcxgBIAMoCzJlLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5p
bnRlcmFjdGlvbm1vZGVsLkludGVudC5JbnRlbnRQYXJhbWV0ZXIuRW50aXR5U2V0UmVmZXJl
bmNlcy5FbnRpdHlTZXRSZWZlcmVuY2VCA+BBAlITZW50aXR5U2V0UmVmZXJlbmNlcxo4ChJF
bnRpdHlTZXRSZWZlcmVuY2USIgoKZW50aXR5X3NldBgBIAEoCUID4EECUgllbnRpdHlTZXRC
EAoOcGFyYW1ldGVyX3R5cGVCkwEKKmNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJh
Y3Rpb25tb2RlbEILSW50ZW50UHJvdG9QAVpWZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8v
Z29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsO2ludGVyYWN0aW9u
bW9kZWxKvhwKBhIEDgBUAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAALwoJCgIDABIDEgBLCgkKAgMBEgMTACkKCAoBCBIDFQBtCgkKAggLEgMVAG0KCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAsCgkKAggIEgMXACwKCAoBCBIDGABDCgkKAggB
EgMYAEMKvgIKAgQAEgQfAFQBGrECIEludGVudHMgbWFwIG9wZW4tZW5kZWQgdXNlciBpbnB1
dCB0byBzdHJ1Y3R1cmVkIG9iamVjdHMuIFNwb2tlbgogcGhyYXNlcyBhcmUgbWF0Y2hlZCB0
byBpbnRlbnRzIHdpdGggR29vZ2xlJ3MgTmF0dXJhbCBMYW5ndWFnZSBVbmRlcnN0YW5kaW5n
CiAoTkxVKS4gSW50ZW50IG1hdGNoZXMgY2FuIHRyaWdnZXIgZXZlbnRzIGluIHlvdXIgY29u
dmVyc2F0aW9uIGRlc2lnbiB0bwogcHJvZ3Jlc3MgdGhlIHVzZXIncyBjb252ZXJzYXRpb24u
CiBUaGUgaW50ZW50IG5hbWUgaXMgc3BlY2lmaWVkIGluIHRoZSBuYW1lIG9mIHRoZSBmaWxl
LgoKCgoDBAABEgMfCA4KVAoEBAADABIEIQJAAxpGIERlZmluaXRpb24gb2YgYSBwYXJhbWV0
ZXIgd2hpY2ggY2FuIGJlIHVzZWQgaW5zaWRlIHRyYWluaW5nIHBocmFzZXMuCgoMCgUEAAMA
ARIDIQoZCkAKBgQAAwADABIEIwQuBRowIEVudGl0eSBzZXQgcmVmZXJlbmNlcyBmb3IgYW4g
aW50ZW50IHBhcmFtZXRlci4KCg4KBwQAAwADAAESAyMMHwpZCggEAAMAAwADABIEJQYqBxpH
IEEgcmVmZXJlbmNlIHRvIHRoZSBzZXQgb2YgYWxsb3dlZCBlbnRpdGllcyBmb3IgdGhpcyBp
bnRlbnQgcGFyYW1ldGVyLgoKEAoJBAADAAMAAwABEgMlDiAK1wEKCgQAAwADAAMAAgASAykI
RxrDASBSZXF1aXJlZC4gSWRlbnRpZmllcyB0aGUgc3BlY2lmaWMgY29sbGVjdGlvbiBvZiBl
bnRpdGllcyB0byBiZSBjb25zaWRlcmVkIGZvciBhCiBnaXZlbiBwYXJhbWV0ZXIuIFRoZSBj
b3JyZXNwb25kaW5nIGVudGl0eSBzZXQgZGVmaW5pdGlvbiBzaG91bGQgYmUKIHByZXNlbnQg
aW4gdGhlIGN1c3RvbS9lbnRpdHlTZXRzLyBkaXJlY3RvcnkuCgoSCgsEAAMAAwADAAIABRID
KQgOChIKCwQAAwADAAMAAgABEgMpDxkKEgoLBAADAAMAAwACAAMSAykcHQoSCgsEAAMAAwAD
AAIACBIDKR5GChUKDgQAAwADAAMAAgAInAgAEgMpH0UKSwoIBAADAAMAAgASAy0GZRo6IFJl
cXVpcmVkLiBFbnRpdHkgc2V0IHJlZmVyZW5jZXMgZm9yIGFuIGludGVudCBwYXJhbWV0ZXIu
CgoQCgkEAAMAAwACAAQSAy0GDgoQCgkEAAMAAwACAAYSAy0PIQoQCgkEAAMAAwACAAESAy0i
NwoQCgkEAAMAAwACAAMSAy06OwoQCgkEAAMAAwACAAgSAy08ZAoTCgwEAAMAAwACAAicCAAS
Ay09Ywq+AQoGBAADAAIAEgMzBD0argEgUmVxdWlyZWQuIFVuaXF1ZSBuYW1lIG9mIHRoZSBp
bnRlbnQgcGFyYW1ldGVyLiBDYW4gYmUgdXNlZCBpbiBjb25kaXRpb25zIGFuZAogcmVzcG9u
c2VzIHRvIHJlZmVyZW5jZSBpbnRlbnQgcGFyYW1ldGVycyBleHRyYWN0ZWQgYnkgTkxVIHdp
dGgKICRpbnRlbnQucGFyYW1zLltuYW1lXS5yZXNvbHZlZAoKDgoHBAADAAIABRIDMwQKCg4K
BwQAAwACAAESAzMLDwoOCgcEAAMAAgADEgMzEhMKDgoHBAADAAIACBIDMxQ8ChEKCgQAAwAC
AAicCAASAzMVOwozCgYEAAMACAASBDYEPwUaIyBUaGUgdHlwZSBvZiB0aGUgaW50ZW50IHBh
cmFtZXRlci4KCg4KBwQAAwAIAAESAzYKGApyCgYEAAMAAgESAzkGcxpjIE9wdGlvbmFsLiBE
ZWNsYXJlcyB0aGUgZGF0YSB0eXBlIG9mIHRoaXMgcGFyYW1ldGVyLgogVGhpcyBzaG91bGQg
bm90IGJlIHNldCBmb3IgYnVpbHQtaW4gaW50ZW50cy4KCg4KBwQAAwACAQYSAzkGQAoOCgcE
AAMAAgEBEgM5QUUKDgoHBAADAAIBAxIDOUhJCg4KBwQAAwACAQgSAzlKcgoRCgoEAAMAAgEI
nAgAEgM5S3EK3wEKBgQAAwACAhIDPgZdGs8BIE9wdGlvbmFsLiBSZWZlcmVuY2VzIHRvIHRo
ZSBzZXRzIG9mIGFsbG93ZWQgZW50aXRpZXMgZm9yIHRoaXMgaW50ZW50IHBhcmFtZXRlci4K
IE9ubHkgdmFsaWQgZm9yIHBhcmFtZXRlcnMgb2YgYSBidWlsdC1pbiBpbnRlbnQuIFRoZXNl
CiByZWZlcmVuY2VzIHBvaW50IHRvIGVudGl0eSBzZXRzIGluIHRoZSAnY3VzdG9tL2VudGl0
eVNldHMnIGRpcmVjdG9yeS4KCg4KBwQAAwACAgYSAz4GGQoOCgcEAAMAAgIBEgM+Gi8KDgoH
BAADAAICAxIDPjIzCg4KBwQAAwACAggSAz40XAoRCgoEAAMAAgIInAgAEgM+NVsKigEKBAQA
AgASA0QCKhp9IFRoZSBsaXN0IG9mIHBhcmFtZXRlcnMgd2l0aGluIHRoZSB0cmFpbmluZyBw
aHJhc2VzLiBBbGwgcGFyYW1ldGVycyBtdXN0IGJlCiBkZWZpbmVkIGhlcmUgdG8gYmUgdXNl
ZCBpbiB0aGUgdHJhaW5pbmcgcGhyYXNlLgoKDAoFBAACAAQSA0QCCgoMCgUEAAIABhIDRAsa
CgwKBQQAAgABEgNEGyUKDAoFBAACAAMSA0QoKQrBBQoEBAACARIDUwInGrMFIFRyYWluaW5n
IHBocmFzZXMgYWxsb3cgR29vZ2xl4oCZcyBOTFUgdG8gYXV0b21hdGljYWxseSBtYXRjaCBp
bnRlbnRzIHdpdGgKIHVzZXIgaW5wdXQuIFRoZSBtb3JlIHVuaXF1ZSBwaHJhc2VzIHRoYXQg
YXJlIHByb3ZpZGVkLCB0aGUgYmV0dGVyIGNoYW5jZQogdGhpcyBpbnRlbnQgd2lsbCBiZSBt
YXRjaGVkLgogVGhlIGZvbGxvd2luZyBpcyB0aGUgZm9ybWF0IG9mIHRyYWluaW5nIHBocmFz
ZSBwYXJ0IHdoaWNoIGFyZSBhbm5vdGF0ZWQuCiBOb3RlIHRoYXQgYGF1dG9gIGZpZWxkIGlz
IG9wdGlvbmFsIGFuZCB0aGUgZGVmYXVsdCBiZWhhdmlvciB3aGVuIGBhdXRvYCBpcwogbm90
IHNwZWNpZmllZCBpcyBlcXVpdmFsZW50IHRvIGBhdXRvPWZhbHNlYC4KIGAoJDxwYXJhbU5h
bWU+ICc8c2FtcGxlIHRleHQ+JyBhdXRvPTx0cnVlIG9yIGZhbHNlPilgCiBgYXV0byA9IHRy
dWVgIG1lYW5zIHRoZSBwYXJ0IHdhcyBhdXRvIGFubm90YXRlZCBieSBOTFUuCiBgYXV0byA9
IGZhbHNlYCBtZWFucyB0aGUgcGFydCB3YXMgYW5ub3RhdGVkIGJ5IHRoZSB1c2VyLiBUaGlz
IGlzIHRoZQogICAgIGRlZmF1bHQgd2hlbiBhdXRvIGlzIG5vdCBzcGVjaWZpZWQuCiBFeGFt
cGxlOgogIkJvb2sgYSBmbGlnaHQgZnJvbSAoJHNvdXJjZSAnU2FuIEZyYW5jaXNjbycgYXV0
bz1mYWxzZSkgdG8gKCRkZXN0CiAnVmFuY291dmVyJykiCgoMCgUEAAIBBBIDUwIKCgwKBQQA
AgEFEgNTCxEKDAoFBAACAQESA1MSIgoMCgUEAAIBAxIDUyUmYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent ===
    # Fields for Intent
    # Field: parameters Type: 11 (.google.actions.sdk.v2.interactionmodel.Intent.IntentParameter)
    # Field: training_phrases Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Intent - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/intent.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Intent;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent->new({
        parameters => $parameters,
        training_phrases => $training_phrases,
    });

    # Read or update a field
    my $val = $msg->parameters();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/intent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent

Intents map open-ended user input to structured objects. Spoken
phrases are matched to intents with Google's Natural Language Understanding
(NLU). Intent matches can trigger events in your conversation design to
progress the user's conversation.
The intent name is specified in the name of the file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameters() >> / C<< $msg->parameters($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent::IntentParameter>)

The list of parameters within the training phrases. All parameters must be
defined here to be used in the training phrase.

=item * C<< $msg->training_phrases() >> / C<< $msg->training_phrases($value) >>

Type: C<String>

Training phrases allow Google’s NLU to automatically match intents with
user input. The more unique phrases that are provided, the better chance
this intent will be matched.
The following is the format of training phrase part which are annotated.
Note that `auto` field is optional and the default behavior when `auto` is
not specified is equivalent to `auto=false`.
`($<paramName> '<sample text>' auto=<true or false>)`
`auto = true` means the part was auto annotated by NLU.
`auto = false` means the part was annotated by the user. This is the
    default when auto is not specified.
Example:
"Book a flight from ($source 'San Francisco' auto=false) to ($dest
'Vancouver')"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Intent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
