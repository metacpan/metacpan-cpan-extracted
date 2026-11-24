package Google::Cloud::Support::V2beta::Attachment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Support::V2beta::Actor };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvYXR0YWNobWVudC5wcm90bxIbZ29vZ2xl
LmNsb3VkLnN1cHBvcnQudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJl
dGEvYWN0b3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iwgMKCkF0
dGFjaG1lbnQSGgoEbmFtZRgBIAEoCUIG4EED4EEIUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkEKB2Ny
ZWF0b3IYAyABKAsyIi5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQWN0b3JCA+BBA1IH
Y3JlYXRvchIaCghmaWxlbmFtZRgEIAEoCVIIZmlsZW5hbWUSIAoJbWltZV90eXBlGAUgASgJ
QgPgQQNSCG1pbWVUeXBlEiIKCnNpemVfYnl0ZXMYBiABKANCA+BBA1IJc2l6ZUJ5dGVzOrAB
6kGsAQomY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tL0F0dGFjaG1lbnQSRW9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vY2FzZXMve2Nhc2V9L2F0dGFjaG1lbnRzL3thdHRhY2ht
ZW50X2lkfRI7cHJvamVjdHMve3Byb2plY3R9L2Nhc2VzL3tjYXNlfS9hdHRhY2htZW50cy97
YXR0YWNobWVudF9pZH1CzAEKH2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGFCD0F0
dGFjaG1lbnRQcm90b1ABWjljbG91ZC5nb29nbGUuY29tL2dvL3N1cHBvcnQvYXBpdjJiZXRh
L3N1cHBvcnRwYjtzdXBwb3J0cGKqAhtHb29nbGUuQ2xvdWQuU3VwcG9ydC5WMkJldGHKAhtH
b29nbGVcQ2xvdWRcU3VwcG9ydFxWMmJldGHqAh5Hb29nbGU6OkNsb3VkOjpTdXBwb3J0OjpW
MmJldGFKhxEKBhIEDgBEAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
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
AQISAxAAJAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAMQoJCgIDAxIDFQApCggK
AQgSAxcAOAoJCgIIJRIDFwA4CggKAQgSAxgAUAoJCgIICxIDGABQCggKAQgSAxkAIgoJCgII
ChIDGQAiCggKAQgSAxoAMAoJCgIICBIDGgAwCggKAQgSAxsAOAoJCgIIARIDGwA4CggKAQgS
AxwAOAoJCgIIKRIDHAA4CggKAQgSAx0ANwoJCgIILRIDHQA3Co0DCgIEABIEJwBEARqAAyBB
biBBdHRhY2htZW50IGNvbnRhaW5zIG1ldGFkYXRhIGFib3V0IGEgZmlsZSB0aGF0IHdhcyB1
cGxvYWRlZCB0byBhCiBjYXNlIC0gaXQgaXMgTk9UIGEgZmlsZSBpdHNlbGYuIFRoYXQgYmVp
bmcgc2FpZCwgdGhlIG5hbWUgb2YgYW4gQXR0YWNobWVudAogb2JqZWN0IGNhbiBiZSB1c2Vk
IHRvIGRvd25sb2FkIGl0cyBhY2NvbXBhbnlpbmcgZmlsZSB0aHJvdWdoIHRoZQogYG1lZGlh
LmRvd25sb2FkYCBlbmRwb2ludC4KCiBXaGlsZSBhdHRhY2htZW50cyBjYW4gYmUgdXBsb2Fk
ZWQgaW4gdGhlIGNvbnNvbGUgYXQgdGhlCiBzYW1lIHRpbWUgYXMgYSBjb21tZW50LCB0aGV5
J3JlIGFzc29jaWF0ZWQgb24gYSAiY2FzZSIgbGV2ZWwsIG5vdCBhCiAiY29tbWVudCIgbGV2
ZWwuCgoKCgMEAAESAycIEgoLCgMEAAcSBCgCLAQKDQoFBAAHnQgSBCgCLAQKTQoEBAACABIE
LwIyBBo/IE91dHB1dCBvbmx5LiBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0
aGUgYXR0YWNobWVudC4KCgwKBQQAAgAFEgMvAggKDAoFBAACAAESAy8JDQoMCgUEAAIAAxID
LxARCg0KBQQAAgAIEgQvEjIDCg8KCAQAAgAInAgAEgMwBC0KDwoIBAACAAicCAESAzEELApK
CgQEAAIBEgQ1AjYyGjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBhdHRh
Y2htZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAzUCGwoMCgUEAAIBARIDNRwnCgwKBQQA
AgEDEgM1KisKDAoFBAACAQgSAzYGMQoPCggEAAIBCJwIABIDNgcwCqEBCgQEAAICEgM6AkAa
kwEgT3V0cHV0IG9ubHkuIFRoZSB1c2VyIHdobyB1cGxvYWRlZCB0aGUgYXR0YWNobWVudC4g
Tm90ZSwgdGhlIG5hbWUgYW5kIGVtYWlsCiB3aWxsIGJlIG9iZnVzY2F0ZWQgaWYgdGhlIGF0
dGFjaG1lbnQgd2FzIHVwbG9hZGVkIGJ5IEdvb2dsZSBzdXBwb3J0LgoKDAoFBAACAgYSAzoC
BwoMCgUEAAICARIDOggPCgwKBQQAAgIDEgM6EhMKDAoFBAACAggSAzoUPwoPCggEAAICCJwI
ABIDOhU+CkMKBAQAAgMSAz0CFho2IFRoZSBmaWxlbmFtZSBvZiB0aGUgYXR0YWNobWVudCAo
ZS5nLiBgImdyYXBoLmpwZyJgKS4KCgwKBQQAAgMFEgM9AggKDAoFBAACAwESAz0JEQoMCgUE
AAIDAxIDPRQVCk4KBAQAAgQSA0ACQxpBIE91dHB1dCBvbmx5LiBUaGUgTUlNRSB0eXBlIG9m
IHRoZSBhdHRhY2htZW50IChlLmcuIHRleHQvcGxhaW4pLgoKDAoFBAACBAUSA0ACCAoMCgUE
AAIEARIDQAkSCgwKBQQAAgQDEgNAFRYKDAoFBAACBAgSA0AXQgoPCggEAAIECJwIABIDQBhB
CkAKBAQAAgUSA0MCQxozIE91dHB1dCBvbmx5LiBUaGUgc2l6ZSBvZiB0aGUgYXR0YWNobWVu
dCBpbiBieXRlcy4KCgwKBQQAAgUFEgNDAgcKDAoFBAACBQESA0MIEgoMCgUEAAIFAxIDQxUW
CgwKBQQAAgUIEgNDF0IKDwoIBAACBQicCAASA0MYQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::Attachment::Attachment ===
    # Fields for Attachment
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 11 (.google.cloud.support.v2beta.Actor)
    # Field: filename Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: size_bytes Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::Attachment - Compiled Protocol Buffers messages for google/cloud/support/v2beta/attachment.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::Attachment;

    my $msg = Google::Cloud::Support::V2beta::Attachment::Attachment->new({
        name => $name,
        create_time => $create_time,
        creator => $creator,
        filename => $filename,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::Attachment::Attachment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/attachment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::Attachment::Attachment

An Attachment contains metadata about a file that was uploaded to a
case - it is NOT a file itself. That being said, the name of an Attachment
object can be used to download its accompanying file through the
`media.download` endpoint.

While attachments can be uploaded in the console at the
same time as a comment, they're associated on a "case" level, not a
"comment" level.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the attachment.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the attachment was created.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Actor::Actor>)

Output only. The user who uploaded the attachment. Note, the name and email
will be obfuscated if the attachment was uploaded by Google support.

=item * C<< $msg->filename() >> / C<< $msg->filename($value) >>

Type: C<String>

The filename of the attachment (e.g. `"graph.jpg"`).

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Output only. The MIME type of the attachment (e.g. text/plain).

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

Output only. The size of the attachment in bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::Attachment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
