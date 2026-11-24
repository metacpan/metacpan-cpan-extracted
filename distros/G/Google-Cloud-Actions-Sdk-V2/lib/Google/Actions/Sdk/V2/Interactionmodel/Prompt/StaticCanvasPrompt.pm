package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
ClBnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfY2FudmFzX3Byb21wdC5wcm90bxItZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwucHJvbXB0Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIv0BChJTdGF0aWNDYW52YXNQcm9tcHQS
FQoDdXJsGAEgASgJQgPgQQJSA3VybBIvCgRkYXRhGAIgAygLMhYuZ29vZ2xlLnByb3RvYnVm
LlZhbHVlQgPgQQFSBGRhdGESJgoMc3VwcHJlc3NfbWljGAMgASgIQgPgQQFSC3N1cHByZXNz
TWljEkQKHXNlbmRfc3RhdGVfZGF0YV90b19jYW52YXNfYXBwGAUgASgIQgPgQQFSGHNlbmRT
dGF0ZURhdGFUb0NhbnZhc0FwcBIxChJlbmFibGVfZnVsbF9zY3JlZW4YBiABKAhCA+BBAVIQ
ZW5hYmxlRnVsbFNjcmVlbkKjAQoxY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFj
dGlvbm1vZGVsLnByb21wdEIXU3RhdGljQ2FudmFzUHJvbXB0UHJvdG9QAVpTZ29vZ2xlLmdv
bGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlv
bm1vZGVsL3Byb21wdDtwcm9tcHRK2REKBhIEDgA1AQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAANgoJCgIDABIDEgApCgkKAgMBEgMTACYKCAoBCBIDFQBq
CgkKAggLEgMVAGoKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA4CgkKAggIEgMXADgK
CAoBCBIDGABKCgkKAggBEgMYAEoK9wEKAgQAEgQeADUBGuoBIFJlcHJlc2VudHMgYSBJbnRl
cmFjdGl2ZSBDYW52YXMgcmVzcG9uc2UgdG8gYmUgc2VudCB0byB0aGUgdXNlci4KIFRoaXMg
Y2FuIGJlIHVzZWQgaW4gY29uanVuY3Rpb24gd2l0aCB0aGUgYGZpcnN0X3NpbXBsZWAgZmll
bGQgaW4gdGhlCiBjb250YWluaW5nIHByb21wdCB0byBzcGVhayB0byB0aGUgdXNlciBpbiBh
ZGRpdGlvbiB0byBkaXNwbGF5aW5nIGEKIGludGVyYWN0aXZlIGNhbnZhcyByZXNwb25zZS4K
CgoKAwQAARIDHggaCjUKBAQAAgASAyACOhooIFJlcXVpcmVkLiBVUkwgb2YgdGhlIHdlYiB2
aWV3IHRvIGxvYWQuCgoMCgUEAAIABRIDIAIICgwKBQQAAgABEgMgCQwKDAoFBAACAAMSAyAP
EAoMCgUEAAIACBIDIBE5Cg8KCAQAAgAInAgAEgMgEjgKlwIKBAQAAgESAyYCUxqJAiBPcHRp
b25hbC4gSlNPTiBkYXRhIHRvIGJlIHBhc3NlZCB0aHJvdWdoIHRvIHRoZSBpbW1lcnNpdmUg
ZXhwZXJpZW5jZSB3ZWIgcGFnZSBhcyBhbgogZXZlbnQuIElmIHRoZSBgb3ZlcnJpZGVgIGZp
ZWxkIGluIHRoZSBjb250YWluaW5nIHByb21wdCBpcyBgZmFsc2VgIGRhdGEKIHZhbHVlcyBk
ZWZpbmVkIGluIHRoaXMgQ2FudmFzIHByb21wdCB3aWxsIGJlIGFkZGVkIGFmdGVyIGRhdGEg
dmFsdWVzCiBkZWZpbmVkIGluIHByZXZpb3VzIENhbnZhcyBwcm9tcHRzLgoKDAoFBAACAQQS
AyYCCgoMCgUEAAIBBhIDJgsgCgwKBQQAAgEBEgMmISUKDAoFBAACAQMSAyYoKQoMCgUEAAIB
CBIDJipSCg8KCAQAAgEInAgAEgMmK1EKlgEKBAQAAgISAyoCQRqIASBPcHRpb25hbC4gQSB0
cnVlIHZhbHVlIG1lYW5zIHRoYXQgdGhlIG1pYyB3b24ndCBiZSBvcGVuZWQgZm9yIGNhcHR1
cmluZyBpbnB1dCBhZnRlcgogdGhpcyBpbW1lcnNpdmUgcmVzcG9uc2UgaXMgcHJlc2VudGVk
IHRvIHRoZSB1c2VyLgoKDAoFBAACAgUSAyoCBgoMCgUEAAICARIDKgcTCgwKBQQAAgIDEgMq
FhcKDAoFBAACAggSAyoYQAoPCggEAAICCJwIABIDKhk/CncKBAQAAgMSAy4CUhpqIE9wdGlv
bmFsLiBJZiBgdHJ1ZWAsIGNvbnZlcnNhdGlvbiByZWxhdGVkIG1ldGFkYXRhIGlzIGluY2x1
ZGVkIGFuZCBzZW5kIGJhY2sgdG8gdGhlCiBjYW52YXMgYXBwbGljYXRpb24uCgoMCgUEAAID
BRIDLgIGCgwKBQQAAgMBEgMuByQKDAoFBAACAwMSAy4nKAoMCgUEAAIDCBIDLilRCg8KCAQA
AgMInAgAEgMuKlAKtwIKBAQAAgQSAzQCRxqpAiBPcHRpb25hbC4gSWYgYHRydWVgIHRoZSBj
YW52YXMgYXBwbGljYXRpb24gb2NjdXBpZXMgdGhlIGZ1bGwgc2NyZWVuIGFuZCB3b24ndAog
aGF2ZSBhIGhlYWRlciBhdCB0aGUgdG9wLiBBIHRvYXN0IG1lc3NhZ2Ugd2lsbCBhbHNvIGJl
IGRpc3BsYXllZCBvbiB0aGUKIGxvYWRpbmcgc2NyZWVuIHRoYXQgaW5jbHVkZXMgdGhlIEFj
dGlvbidzIGRpc3BsYXkgbmFtZSwgdGhlIGRldmVsb3BlcidzCiBuYW1lLCBhbmQgaW5zdHJ1
Y3Rpb25zIGZvciBleGl0aW5nIHRoZSBBY3Rpb24uIERlZmF1bHQgdmFsdWU6IGBmYWxzZWAu
CgoMCgUEAAIEBRIDNAIGCgwKBQQAAgQBEgM0BxkKDAoFBAACBAMSAzQcHQoMCgUEAAIECBID
NB5GCg8KCAQAAgQInAgAEgM0H0ViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt ===
    # Fields for StaticCanvasPrompt
    # Field: url Type: 9 ()
    # Field: data Type: 11 (.google.protobuf.Value)
    # Field: suppress_mic Type: 8 ()
    # Field: send_state_data_to_canvas_app Type: 8 ()
    # Field: enable_full_screen Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_canvas_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt->new({
        url => $url,
        data => $data,
        suppress_mic => $suppress_mic,
        send_state_data_to_canvas_app => $send_state_data_to_canvas_app,
    });

    # Read or update a field
    my $val = $msg->url();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_canvas_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt

Represents a Interactive Canvas response to be sent to the user.
This can be used in conjunction with the `first_simple` field in the
containing prompt to speak to the user in addition to displaying a
interactive canvas response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Required. URL of the web view to load.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. JSON data to be passed through to the immersive experience web page as an
event. If the `override` field in the containing prompt is `false` data
values defined in this Canvas prompt will be added after data values
defined in previous Canvas prompts.

=item * C<< $msg->suppress_mic() >> / C<< $msg->suppress_mic($value) >>

Type: C<Bool>

Optional. A true value means that the mic won't be opened for capturing input after
this immersive response is presented to the user.

=item * C<< $msg->send_state_data_to_canvas_app() >> / C<< $msg->send_state_data_to_canvas_app($value) >>

Type: C<Bool>

Optional. If `true`, conversation related metadata is included and send back to the
canvas application.

=item * C<< $msg->enable_full_screen() >> / C<< $msg->enable_full_screen($value) >>

Type: C<Bool>

Optional. If `true` the canvas application occupies the full screen and won't
have a header at the top. A toast message will also be displayed on the
loading screen that includes the Action's display name, the developer's
name, and instructions for exiting the Action. Default value: `false`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
