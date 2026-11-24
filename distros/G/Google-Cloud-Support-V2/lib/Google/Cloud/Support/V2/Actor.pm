package Google::Cloud::Support::V2::Actor;

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
CiNnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9hY3Rvci5wcm90bxIXZ29vZ2xlLmNsb3VkLnN1
cHBvcnQudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8ikQEKBUFjdG9yEiEK
DGRpc3BsYXlfbmFtZRgBIAEoCVILZGlzcGxheU5hbWUSGAoFZW1haWwYAiABKAlCAhgBUgVl
bWFpbBIqCg5nb29nbGVfc3VwcG9ydBgEIAEoCEID4EEDUg1nb29nbGVTdXBwb3J0Eh8KCHVz
ZXJuYW1lGAUgASgJQgPgQQNSCHVzZXJuYW1lQrMBChtjb20uZ29vZ2xlLmNsb3VkLnN1cHBv
cnQudjJCCkFjdG9yUHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2FwaXYy
L3N1cHBvcnRwYjtzdXBwb3J0cGKqAhdHb29nbGUuQ2xvdWQuU3VwcG9ydC5WMsoCF0dvb2ds
ZVxDbG91ZFxTdXBwb3J0XFYy6gIaR29vZ2xlOjpDbG91ZDo6U3VwcG9ydDo6VjJKsREKBhIE
DgA3AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgID
ABIDEgApCggKAQgSAxQANAoJCgIIJRIDFAA0CggKAQgSAxUATAoJCgIICxIDFQBMCggKAQgS
AxYAIgoJCgIIChIDFgAiCggKAQgSAxcAKwoJCgIICBIDFwArCggKAQgSAxgANAoJCgIIARID
GAA0CggKAQgSAxkANAoJCgIIKRIDGQA0CggKAQgSAxoAMwoJCgIILRIDGgAzCusBCgIEABIE
HwA3ARreASBBbiBBY3RvciByZXByZXNlbnRzIGFuIGVudGl0eSB0aGF0IHBlcmZvcm1lZCBh
biBhY3Rpb24uIEZvciBleGFtcGxlLCBhbiBhY3RvcgogY291bGQgYmUgYSB1c2VyIHdobyBw
b3N0ZWQgYSBjb21tZW50IG9uIGEgc3VwcG9ydCBjYXNlLCBhIHVzZXIgd2hvCiB1cGxvYWRl
ZCBhbiBhdHRhY2htZW50LCBvciBhIHNlcnZpY2UgYWNjb3VudCB0aGF0IGNyZWF0ZWQgYSBz
dXBwb3J0IGNhc2UuCgoKCgMEAAESAx8IDQqFAgoEBAACABIDJAIaGvcBIFRoZSBuYW1lIHRv
IGRpc3BsYXkgZm9yIHRoZSBhY3Rvci4gSWYgbm90IHByb3ZpZGVkLCBpdCBpcyBpbmZlcnJl
ZCBmcm9tCiBjcmVkZW50aWFscyBzdXBwbGllZCBkdXJpbmcgY2FzZSBjcmVhdGlvbi4gV2hl
biBhbiBlbWFpbCBpcyBwcm92aWRlZCwgYQogZGlzcGxheSBuYW1lIG11c3QgYWxzbyBiZSBw
cm92aWRlZC4gVGhpcyB3aWxsIGJlIG9iZnVzY2F0ZWQgaWYgdGhlIHVzZXIKIGlzIGEgR29v
Z2xlIFN1cHBvcnQgYWdlbnQuCgoMCgUEAAIABRIDJAIICgwKBQQAAgABEgMkCRUKDAoFBAAC
AAMSAyQYGQquAgoEBAACARIDLAInGqACIFRoZSBlbWFpbCBhZGRyZXNzIG9mIHRoZSBhY3Rv
ci4gSWYgbm90IHByb3ZpZGVkLCBpdCBpcyBpbmZlcnJlZCBmcm9tIHRoZQogY3JlZGVudGlh
bHMgc3VwcGxpZWQgZHVyaW5nIGNhc2UgY3JlYXRpb24uIFdoZW4gYSBuYW1lIGlzIHByb3Zp
ZGVkLCBhbgogZW1haWwgbXVzdCBhbHNvIGJlIHByb3ZpZGVkLiBJZiB0aGUgdXNlciBpcyBh
IEdvb2dsZSBTdXBwb3J0IGFnZW50LCB0aGlzIGlzCiBvYmZ1c2NhdGVkLgoKIFRoaXMgZmll
bGQgaXMgZGVwcmVjYXRlZC4gVXNlIGB1c2VybmFtZWAgaW5zdGVhZC4KCgwKBQQAAgEFEgMs
AggKDAoFBAACAQESAywJDgoMCgUEAAIBAxIDLBESCgwKBQQAAgEIEgMsEyYKDQoGBAACAQgD
EgMsFCUKSAoEBAACAhIDLwJGGjsgT3V0cHV0IG9ubHkuIFdoZXRoZXIgdGhlIGFjdG9yIGlz
IGEgR29vZ2xlIHN1cHBvcnQgYWN0b3IuCgoMCgUEAAICBRIDLwIGCgwKBQQAAgIBEgMvBxUK
DAoFBAACAgMSAy8YGQoMCgUEAAICCBIDLxpFCg8KCAQAAgIInAgAEgMvG0QKvwIKBAQAAgMS
AzYCQhqxAiBPdXRwdXQgb25seS4gVGhlIHVzZXJuYW1lIG9mIHRoZSBhY3Rvci4gSXQgbWF5
IGxvb2sgbGlrZSBhbiBlbWFpbCBvciBvdGhlcgogZm9ybWF0IHByb3ZpZGVkIGJ5IHRoZSBp
ZGVudGl0eSBwcm92aWRlci4gSWYgbm90IHByb3ZpZGVkLCBpdCBpcyBpbmZlcnJlZAogZnJv
bSB0aGUgY3JlZGVudGlhbHMgc3VwcGxpZWQuIFdoZW4gYSBuYW1lIGlzIHByb3ZpZGVkLCBh
IHVzZXJuYW1lIG11c3QKIGFsc28gYmUgcHJvdmlkZWQuIElmIHRoZSB1c2VyIGlzIGEgR29v
Z2xlIFN1cHBvcnQgYWdlbnQsIHRoaXMgd2lsbCBub3QgYmUKIHNldC4KCgwKBQQAAgMFEgM2
AggKDAoFBAACAwESAzYJEQoMCgUEAAIDAxIDNhQVCgwKBQQAAgMIEgM2FkEKDwoIBAACAwic
CAASAzYXQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::Actor::Actor ===
    # Fields for Actor
    # Field: display_name Type: 9 ()
    # Field: email Type: 9 ()
    # Field: google_support Type: 8 ()
    # Field: username Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::Actor - Compiled Protocol Buffers messages for google/cloud/support/v2/actor.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::Actor;

    my $msg = Google::Cloud::Support::V2::Actor::Actor->new({
        display_name => $display_name,
        email => $email,
        google_support => $google_support,
        username => $username,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::Actor::Actor->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/actor.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::Actor::Actor

An Actor represents an entity that performed an action. For example, an actor
could be a user who posted a comment on a support case, a user who
uploaded an attachment, or a service account that created a support case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The name to display for the actor. If not provided, it is inferred from
credentials supplied during case creation. When an email is provided, a
display name must also be provided. This will be obfuscated if the user
is a Google Support agent.

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

The email address of the actor. If not provided, it is inferred from the
credentials supplied during case creation. When a name is provided, an
email must also be provided. If the user is a Google Support agent, this is
obfuscated.

This field is deprecated. Use `username` instead.

=item * C<< $msg->google_support() >> / C<< $msg->google_support($value) >>

Type: C<Bool>

Output only. Whether the actor is a Google support actor.

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

Output only. The username of the actor. It may look like an email or other
format provided by the identity provider. If not provided, it is inferred
from the credentials supplied. When a name is provided, a username must
also be provided. If the user is a Google Support agent, this will not be
set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::Actor::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
