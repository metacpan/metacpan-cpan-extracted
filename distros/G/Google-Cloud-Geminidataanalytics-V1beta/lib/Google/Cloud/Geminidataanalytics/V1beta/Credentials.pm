package Google::Cloud::Geminidataanalytics::V1beta::Credentials;

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
Cjlnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWJldGEvY3JlZGVudGlhbHMu
cHJvdG8SJ2dvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYmV0YRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90byJoCgtDcmVkZW50aWFscxJRCgVvYXV0aBgBIAEo
CzI5Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYmV0YS5PQXV0aENyZWRl
bnRpYWxzSABSBW9hdXRoQgYKBGtpbmQi6gIKEE9BdXRoQ3JlZGVudGlhbHMSXwoGc2VjcmV0
GAIgASgLMkUuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhLk9BdXRo
Q3JlZGVudGlhbHMuU2VjcmV0QmFzZWRIAFIGc2VjcmV0ElwKBXRva2VuGAMgASgLMkQuZ29v
Z2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFiZXRhLk9BdXRoQ3JlZGVudGlhbHMu
VG9rZW5CYXNlZEgAUgV0b2tlbhpZCgtTZWNyZXRCYXNlZBIgCgljbGllbnRfaWQYAiABKAlC
A+BBAlIIY2xpZW50SWQSKAoNY2xpZW50X3NlY3JldBgDIAEoCUID4EECUgxjbGllbnRTZWNy
ZXQaNAoKVG9rZW5CYXNlZBImCgxhY2Nlc3NfdG9rZW4YASABKAlCA+BBAlILYWNjZXNzVG9r
ZW5CBgoEa2luZEKhAgorY29tLmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYx
YmV0YUIQQ3JlZGVudGlhbHNQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL2dlbWluaWRh
dGFhbmFseXRpY3MvYXBpdjFiZXRhL2dlbWluaWRhdGFhbmFseXRpY3NwYjtnZW1pbmlkYXRh
YW5hbHl0aWNzcGKqAidHb29nbGUuQ2xvdWQuR2VtaW5pRGF0YUFuYWx5dGljcy5WMUJldGHK
AidHb29nbGVcQ2xvdWRcR2VtaW5pRGF0YUFuYWx5dGljc1xWMWJldGHqAipHb29nbGU6OkNs
b3VkOjpHZW1pbmlEYXRhQW5hbHl0aWNzOjpWMWJldGFKqg8KBhIEDgBAAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMAoJCgIDABIDEgApCggKAQgSAxQA
RAoJCgIIJRIDFABECggKAQgSAxUAdAoJCgIICxIDFQB0CggKAQgSAxYAIgoJCgIIChIDFgAi
CggKAQgSAxcAMQoJCgIICBIDFwAxCggKAQgSAxgARAoJCgIIARIDGABECggKAQgSAxkARAoJ
CgIIKRIDGQBECggKAQgSAxoAQwoJCgIILRIDGgBDCkUKAgQAEgQdACMBGjkgUmVwcmVzZW50
cyBkaWZmZXJlbnQgZm9ybXMgb2YgY3JlZGVudGlhbCBzcGVjaWZpY2F0aW9uLgoKCgoDBAAB
EgMdCBMKKAoEBAAIABIEHwIiAxoaIFRoZSBraW5kIG9mIGNyZWRlbnRpYWxzLgoKDAoFBAAI
AAESAx8IDAohCgQEAAIAEgMhBB8aFCBPQXV0aCBjcmVkZW50aWFscy4KCgwKBQQAAgAGEgMh
BBQKDAoFBAACAAESAyEVGgoMCgUEAAIAAxIDIR0eCisKAgQBEgQmAEABGh8gUmVwcmVzZW50
cyBPQXV0aCBjcmVkZW50aWFscy4KCgoKAwQBARIDJggYCm8KBAQBAwASBCkCLwMaYSBUaGUg
bmFtZSBvZiB0aGUgc2VjcmV0IGNvbnRhaW5pbmcgdGhlIGFjY2VzcyB0b2tlbi4KIFJlcHJl
c2VudHMgc2VjcmV0LWJhc2VkIE9BdXRoIGNyZWRlbnRpYWxzLgoKDAoFBAEDAAESAykKFQou
CgYEAQMAAgASAysEQhofIFJlcXVpcmVkLiBBbiBPQXV0aCBjbGllbnQgSUQuCgoOCgcEAQMA
AgAFEgMrBAoKDgoHBAEDAAIAARIDKwsUCg4KBwQBAwACAAMSAysXGAoOCgcEAQMAAgAIEgMr
GUEKEQoKBAEDAAIACJwIABIDKxpACjIKBgQBAwACARIDLgRGGiMgUmVxdWlyZWQuIEFuIE9B
dXRoIGNsaWVudCBzZWNyZXQuCgoOCgcEAQMAAgEFEgMuBAoKDgoHBAEDAAIBARIDLgsYCg4K
BwQBAwACAQMSAy4bHAoOCgcEAQMAAgEIEgMuHUUKEQoKBAEDAAIBCJwIABIDLh5ECn0KBAQB
AwESBDMCNgMabyBSZWFkIG1vcmUgYWJvdXQgTG9va2VyIGFjY2VzcyB0b2tlbnMgaGVyZToK
IGh0dHBzOi8vZGV2ZWxvcGVycy5sb29rZXIuY29tL2FwaS9hZHZhbmNlZC11c2FnZS9sb29r
ZXItYXBpLW9hdXRoCgoMCgUEAQMBARIDMwoUCk4KBgQBAwECABIDNQRFGj8gUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBzZWNyZXQgY29udGFpbmluZyB0aGUgYWNjZXNzIHRva2VuLgoK
DgoHBAEDAQIABRIDNQQKCg4KBwQBAwECAAESAzULFwoOCgcEAQMBAgADEgM1GhsKDgoHBAED
AQIACBIDNRxEChEKCgQBAwECAAicCAASAzUdQwouCgQEAQgAEgQ5Aj8DGiAgVGhlIGtpbmQg
b2YgT0F1dGggY3JlZGVudGlhbHMuCgoMCgUEAQgAARIDOQgMCi4KBAQBAgASAzsEGxohIFNl
Y3JldC1iYXNlZCBPQXV0aCBjcmVkZW50aWFscy4KCgwKBQQBAgAGEgM7BA8KDAoFBAECAAES
AzsQFgoMCgUEAQIAAxIDOxkaCi0KBAQBAgESAz4EGRogIFRva2VuLWJhc2VkIE9BdXRoIGNy
ZWRlbnRpYWxzLgoKDAoFBAECAQYSAz4EDgoMCgUEAQIBARIDPg8UCgwKBQQBAgEDEgM+Fxhi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Credentials::Credentials ===
    # Fields for Credentials
    # Field: oauth Type: 11 (.google.cloud.geminidataanalytics.v1beta.OAuthCredentials)

# === Message: Google::Cloud::Geminidataanalytics::V1beta::Credentials::OAuthCredentials ===
    # Fields for OAuthCredentials
    # Field: secret Type: 11 (.google.cloud.geminidataanalytics.v1beta.OAuthCredentials.SecretBased)
    # Field: token Type: 11 (.google.cloud.geminidataanalytics.v1beta.OAuthCredentials.TokenBased)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::Credentials - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1beta/credentials.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1beta::Credentials;

    my $msg = Google::Cloud::Geminidataanalytics::V1beta::Credentials::Credentials->new({
        oauth => $oauth,
    });

    # Read or update a field
    my $val = $msg->oauth();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1beta::Credentials::Credentials->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1beta/credentials.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1beta::Credentials::Credentials

Represents different forms of credential specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth() >> / C<< $msg->oauth($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Credentials::OAuthCredentials>)

OAuth credentials.

=back

=head2 Google::Cloud::Geminidataanalytics::V1beta::Credentials::OAuthCredentials

Represents OAuth credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->secret() >> / C<< $msg->secret($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Credentials::OAuthCredentials::SecretBased>)

Secret-based OAuth credentials.

=item * C<< $msg->token() >> / C<< $msg->token($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1beta::Credentials::OAuthCredentials::TokenBased>)

Token-based OAuth credentials.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1beta::Credentials::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
