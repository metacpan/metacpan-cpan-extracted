package Google::Cloud::Support::V2::Attachment;

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
    eval { require Google::Cloud::Support::V2::Actor };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9hdHRhY2htZW50LnByb3RvEhdnb29nbGUuY2xv
dWQuc3VwcG9ydC52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIvYWN0b3IucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ivgMKCkF0dGFjaG1lbnQSGgoE
bmFtZRgBIAEoCUIG4EED4EEIUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEj0KB2NyZWF0b3IYAyABKAsy
Hi5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5BY3RvckID4EEDUgdjcmVhdG9yEhoKCGZpbGVu
YW1lGAQgASgJUghmaWxlbmFtZRIgCgltaW1lX3R5cGUYBSABKAlCA+BBA1IIbWltZVR5cGUS
IgoKc2l6ZV9ieXRlcxgGIAEoA0ID4EEDUglzaXplQnl0ZXM6sAHqQawBCiZjbG91ZHN1cHBv
cnQuZ29vZ2xlYXBpcy5jb20vQXR0YWNobWVudBJFb3JnYW5pemF0aW9ucy97b3JnYW5pemF0
aW9ufS9jYXNlcy97Y2FzZX0vYXR0YWNobWVudHMve2F0dGFjaG1lbnRfaWR9Ejtwcm9qZWN0
cy97cHJvamVjdH0vY2FzZXMve2Nhc2V9L2F0dGFjaG1lbnRzL3thdHRhY2htZW50X2lkfUK4
AQobY29tLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyQg9BdHRhY2htZW50UHJvdG9QAVo1Y2xv
dWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2FwaXYyL3N1cHBvcnRwYjtzdXBwb3J0cGKqAhdH
b29nbGUuQ2xvdWQuU3VwcG9ydC5WMsoCF0dvb2dsZVxDbG91ZFxTdXBwb3J0XFYy6gIaR29v
Z2xlOjpDbG91ZDo6U3VwcG9ydDo6VjJKhxEKBhIEDgBEAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQALQoJCgIDAxIDFQApCggKAQgSAxcANAoJCgIIJRIDFwA0CggKAQgSAxgATAoJCgIICxID
GABMCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMAoJCgIICBIDGgAwCggKAQgSAxsA
NAoJCgIIARIDGwA0CggKAQgSAxwANAoJCgIIKRIDHAA0CggKAQgSAx0AMwoJCgIILRIDHQAz
Co0DCgIEABIEJwBEARqAAyBBbiBBdHRhY2htZW50IGNvbnRhaW5zIG1ldGFkYXRhIGFib3V0
IGEgZmlsZSB0aGF0IHdhcyB1cGxvYWRlZCB0byBhCiBjYXNlIC0gaXQgaXMgTk9UIGEgZmls
ZSBpdHNlbGYuIFRoYXQgYmVpbmcgc2FpZCwgdGhlIG5hbWUgb2YgYW4gQXR0YWNobWVudAog
b2JqZWN0IGNhbiBiZSB1c2VkIHRvIGRvd25sb2FkIGl0cyBhY2NvbXBhbnlpbmcgZmlsZSB0
aHJvdWdoIHRoZQogYG1lZGlhLmRvd25sb2FkYCBlbmRwb2ludC4KCiBXaGlsZSBhdHRhY2ht
ZW50cyBjYW4gYmUgdXBsb2FkZWQgaW4gdGhlIGNvbnNvbGUgYXQgdGhlCiBzYW1lIHRpbWUg
YXMgYSBjb21tZW50LCB0aGV5J3JlIGFzc29jaWF0ZWQgb24gYSAiY2FzZSIgbGV2ZWwsIG5v
dCBhCiAiY29tbWVudCIgbGV2ZWwuCgoKCgMEAAESAycIEgoLCgMEAAcSBCgCLAQKDQoFBAAH
nQgSBCgCLAQKTQoEBAACABIELwIyBBo/IE91dHB1dCBvbmx5LiBJZGVudGlmaWVyLiBUaGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgYXR0YWNobWVudC4KCgwKBQQAAgAFEgMvAggKDAoFBAAC
AAESAy8JDQoMCgUEAAIAAxIDLxARCg0KBQQAAgAIEgQvEjIDCg8KCAQAAgAInAgAEgMwBC0K
DwoIBAACAAicCAESAzEELApKCgQEAAIBEgQ1AjYyGjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
IGF0IHdoaWNoIHRoZSBhdHRhY2htZW50IHdhcyBjcmVhdGVkLgoKDAoFBAACAQYSAzUCGwoM
CgUEAAIBARIDNRwnCgwKBQQAAgEDEgM1KisKDAoFBAACAQgSAzYGMQoPCggEAAIBCJwIABID
NgcwCqEBCgQEAAICEgM6AkAakwEgT3V0cHV0IG9ubHkuIFRoZSB1c2VyIHdobyB1cGxvYWRl
ZCB0aGUgYXR0YWNobWVudC4gTm90ZSwgdGhlIG5hbWUgYW5kIGVtYWlsCiB3aWxsIGJlIG9i
ZnVzY2F0ZWQgaWYgdGhlIGF0dGFjaG1lbnQgd2FzIHVwbG9hZGVkIGJ5IEdvb2dsZSBzdXBw
b3J0LgoKDAoFBAACAgYSAzoCBwoMCgUEAAICARIDOggPCgwKBQQAAgIDEgM6EhMKDAoFBAAC
AggSAzoUPwoPCggEAAICCJwIABIDOhU+CkMKBAQAAgMSAz0CFho2IFRoZSBmaWxlbmFtZSBv
ZiB0aGUgYXR0YWNobWVudCAoZS5nLiBgImdyYXBoLmpwZyJgKS4KCgwKBQQAAgMFEgM9AggK
DAoFBAACAwESAz0JEQoMCgUEAAIDAxIDPRQVCk4KBAQAAgQSA0ACQxpBIE91dHB1dCBvbmx5
LiBUaGUgTUlNRSB0eXBlIG9mIHRoZSBhdHRhY2htZW50IChlLmcuIHRleHQvcGxhaW4pLgoK
DAoFBAACBAUSA0ACCAoMCgUEAAIEARIDQAkSCgwKBQQAAgQDEgNAFRYKDAoFBAACBAgSA0AX
QgoPCggEAAIECJwIABIDQBhBCkAKBAQAAgUSA0MCQxozIE91dHB1dCBvbmx5LiBUaGUgc2l6
ZSBvZiB0aGUgYXR0YWNobWVudCBpbiBieXRlcy4KCgwKBQQAAgUFEgNDAgcKDAoFBAACBQES
A0MIEgoMCgUEAAIFAxIDQxUWCgwKBQQAAgUIEgNDF0IKDwoIBAACBQicCAASA0MYQWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::Attachment::Attachment ===
    # Fields for Attachment
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 11 (.google.cloud.support.v2.Actor)
    # Field: filename Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: size_bytes Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::Attachment - Compiled Protocol Buffers messages for google/cloud/support/v2/attachment.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::Attachment;

    my $msg = Google::Cloud::Support::V2::Attachment::Attachment->new({
        name => $name,
        create_time => $create_time,
        creator => $creator,
        filename => $filename,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::Attachment::Attachment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/attachment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::Attachment::Attachment

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

Type: C<Message> (L<Google::Cloud::Support::V2::Actor::Actor>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::Attachment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
