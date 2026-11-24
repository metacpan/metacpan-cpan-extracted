package Google::Cloud::Ces::V1beta::FileContext;

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
Cipnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9maWxlX2NvbnRleHQucHJvdG8SF2dvb2dsZS5j
bG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvItUBCgtG
aWxlQ29udGV4dBJUCgpmaWxlX2J5dGVzGAEgASgLMi4uZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuRmlsZUNvbnRleHQuRmlsZUJ5dGVzQgPgQQFIAFIJZmlsZUJ5dGVzGmgKCUZpbGVCeXRl
cxIgCglmaWxlX25hbWUYASABKAlCA+BBAlIIZmlsZU5hbWUSIAoJbWltZV90eXBlGAIgASgJ
QgPgQQJSCG1pbWVUeXBlEhcKBGRhdGEYAyABKAxCA+BBAlIEZGF0YUIGCgRmaWxlQmAKG2Nv
bS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YUIQRmlsZUNvbnRleHRQcm90b1ABWi1jbG91ZC5n
b29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJKvwsKBhIEDgAsAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCggK
AQgSAxQARAoJCgIICxIDFABECggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAMQoJCgII
CBIDFgAxCggKAQgSAxcANAoJCgIIARIDFwA0Ck4KAgQAEgQaACwBGkIgRmlsZXMgdG8gYmUg
dXNlZCBhcyBjb250ZXh0LiBGaWxlcyBjYW4gYmUgcHJvdmlkZWQgYXMgcmF3IGJ5dGVzLgoK
CgoDBAABEgMaCBMKKwoEBAADABIEHAIlAxodIEZpbGUgcHJvdmlkZWQgYXMgcmF3IGJ5dGVz
LgoKDAoFBAADAAESAxwKEwpGCgYEAAMAAgASAx4EQho3IFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgZmlsZSBwcm92aWRlZCBhcyByYXcgYnl0ZXMuCgoOCgcEAAMAAgAFEgMeBAoKDgoH
BAADAAIAARIDHgsUCg4KBwQAAwACAAMSAx4XGAoOCgcEAAMAAgAIEgMeGUEKEQoKBAADAAIA
CJwIABIDHhpACkoKBgQAAwACARIDIQRCGjsgUmVxdWlyZWQuIFRoZSBJQU5BIHN0YW5kYXJk
IE1JTUUgdHlwZSBvZiB0aGUgc291cmNlIGRhdGEuCgoOCgcEAAMAAgEFEgMhBAoKDgoHBAAD
AAIBARIDIQsUCg4KBwQAAwACAQMSAyEXGAoOCgcEAAMAAgEIEgMhGUEKEQoKBAADAAIBCJwI
ABIDIRpACjEKBgQAAwACAhIDJAQ8GiIgUmVxdWlyZWQuIFJhdyBieXRlcyBvZiB0aGUgZmls
ZS4KCg4KBwQAAwACAgUSAyQECQoOCgcEAAMAAgIBEgMkCg4KDgoHBAADAAICAxIDJBESCg4K
BwQAAwACAggSAyQTOwoRCgoEAAMAAgIInAgAEgMkFDoKKQoEBAAIABIEKAIrAxobIEZpbGUg
cHJvdmlkZWQgYXMgY29udGV4dC4KCgwKBQQACAABEgMoCAwKNAoEBAACABIDKgRGGicgT3B0
aW9uYWwuIEZpbGUgcHJvdmlkZWQgYXMgcmF3IGJ5dGVzLgoKDAoFBAACAAYSAyoEDQoMCgUE
AAIAARIDKg4YCgwKBQQAAgADEgMqGxwKDAoFBAACAAgSAyodRQoPCggEAAIACJwIABIDKh5E
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::FileContext::FileContext ===
    # Fields for FileContext
    # Field: file_bytes Type: 11 (.google.cloud.ces.v1beta.FileContext.FileBytes)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::FileContext - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/file_context.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::FileContext;

    my $msg = Google::Cloud::Ces::V1beta::FileContext::FileContext->new({
        file_bytes => $file_bytes,
    });

    # Read or update a field
    my $val = $msg->file_bytes();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::FileContext::FileContext->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/file_context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::FileContext::FileContext

Files to be used as context. Files can be provided as raw bytes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_bytes() >> / C<< $msg->file_bytes($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::FileContext::FileContext::FileBytes>)

Optional. File provided as raw bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::FileContext::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
