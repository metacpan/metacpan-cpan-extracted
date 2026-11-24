package Google::Actions::Sdk::V2::Conversation::Simple;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9zaW1wbGUucHJv
dG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24iNAoGU2ltcGxlEhYKBnNw
ZWVjaBgBIAEoCVIGc3BlZWNoEhIKBHRleHQYAiABKAlSBHRleHRChwEKJmNvbS5nb29nbGUu
YWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uQgtTaW1wbGVQcm90b1ABWk5nb29nbGUuZ29s
YW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlv
bjtjb252ZXJzYXRpb25K6woKBhIEDgAlAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAKwoICgEIEgMSAGUKCQoCCAsSAxIAZQoICgEIEgMTACIKCQoCCAoS
AxMAIgoICgEIEgMUACwKCQoCCAgSAxQALAoICgEIEgMVAD8KCQoCCAESAxUAPwo+CgIEABIE
GAAlARoyIFJlcHJlc2VudHMgYSBzaW1wbGUgcHJvbXB0IHRvIGJlIHNlbmQgdG8gYSB1c2Vy
LgoKCgoDBAABEgMYCA4K9gEKBAQAAgASAx0CFBroASBPcHRpb25hbC4gUmVwcmVzZW50cyB0
aGUgc3BlZWNoIHRvIGJlIHNwb2tlbiB0byB0aGUgdXNlci4gQ2FuIGJlIFNTTUwgb3IKIHRl
eHQgdG8gc3BlZWNoLgogSWYgdGhlICJvdmVycmlkZSIgZmllbGQgaW4gdGhlIGNvbnRhaW5p
bmcgcHJvbXB0IGlzICJ0cnVlIiwgdGhlIHNwZWVjaAogZGVmaW5lZCBpbiB0aGlzIGZpZWxk
IHJlcGxhY2VzIHRoZSBwcmV2aW91cyBTaW1wbGUgcHJvbXB0J3Mgc3BlZWNoLgoKDAoFBAAC
AAUSAx0CCAoMCgUEAAIAARIDHQkPCgwKBQQAAgADEgMdEhMKqgIKBAQAAgESAyQCEhqcAiBP
cHRpb25hbCB0ZXh0IHRvIGRpc3BsYXkgaW4gdGhlIGNoYXQgYnViYmxlLiBJZiBub3QgZ2l2
ZW4sIGEgZGlzcGxheQogcmVuZGVyaW5nIG9mIHRoZSBzcGVlY2ggZmllbGQgYWJvdmUgd2ls
bCBiZSB1c2VkLiBMaW1pdGVkIHRvIDY0MAogY2hhcnMuCiBJZiB0aGUgIm92ZXJyaWRlIiBm
aWVsZCBpbiB0aGUgY29udGFpbmluZyBwcm9tcHQgaXMgInRydWUiLCB0aGUgdGV4dAogZGVm
aW5lZCBpbiB0aGlzIGZpZWxkIHJlcGxhY2VzIHRvIHRoZSBwcmV2aW91cyBTaW1wbGUgcHJv
bXB0J3MgdGV4dC4KCgwKBQQAAgEFEgMkAggKDAoFBAACAQESAyQJDQoMCgUEAAIBAxIDJBAR
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Simple::Simple ===
    # Fields for Simple
    # Field: speech Type: 9 ()
    # Field: text Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Simple - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/simple.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Simple;

    my $msg = Google::Actions::Sdk::V2::Conversation::Simple::Simple->new({
        speech => $speech,
        text => $text,
    });

    # Read or update a field
    my $val = $msg->speech();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Simple::Simple->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/simple.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Simple::Simple

Represents a simple prompt to be send to a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->speech() >> / C<< $msg->speech($value) >>

Type: C<String>

Optional. Represents the speech to be spoken to the user. Can be SSML or
text to speech.
If the "override" field in the containing prompt is "true", the speech
defined in this field replaces the previous Simple prompt's speech.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Optional text to display in the chat bubble. If not given, a display
rendering of the speech field above will be used. Limited to 640
chars.
If the "override" field in the containing prompt is "true", the text
defined in this field replaces to the previous Simple prompt's text.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Simple::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
