package Google::Cloud::Alloydb::Connectors::V1beta::Resources;

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
CjZnb29nbGUvY2xvdWQvYWxsb3lkYi9jb25uZWN0b3JzL3YxYmV0YS9yZXNvdXJjZXMucHJv
dG8SJmdvb2dsZS5jbG91ZC5hbGxveWRiLmNvbm5lY3RvcnMudjFiZXRhGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvIosCChdNZXRhZGF0YUV4Y2hhbmdlUmVxdWVzdBIiCgp1
c2VyX2FnZW50GAEgASgJQgPgQQFSCXVzZXJBZ2VudBJlCglhdXRoX3R5cGUYAiABKA4ySC5n
b29nbGUuY2xvdWQuYWxsb3lkYi5jb25uZWN0b3JzLnYxYmV0YS5NZXRhZGF0YUV4Y2hhbmdl
UmVxdWVzdC5BdXRoVHlwZVIIYXV0aFR5cGUSIQoMb2F1dGgyX3Rva2VuGAMgASgJUgtvYXV0
aDJUb2tlbiJCCghBdXRoVHlwZRIZChVBVVRIX1RZUEVfVU5TUEVDSUZJRUQQABINCglEQl9O
QVRJVkUQARIMCghBVVRPX0lBTRACIusBChhNZXRhZGF0YUV4Y2hhbmdlUmVzcG9uc2UScgoN
cmVzcG9uc2VfY29kZRgBIAEoDjJNLmdvb2dsZS5jbG91ZC5hbGxveWRiLmNvbm5lY3RvcnMu
djFiZXRhLk1ldGFkYXRhRXhjaGFuZ2VSZXNwb25zZS5SZXNwb25zZUNvZGVSDHJlc3BvbnNl
Q29kZRIZCgVlcnJvchgCIAEoCUID4EEBUgVlcnJvciJACgxSZXNwb25zZUNvZGUSHQoZUkVT
UE9OU0VfQ09ERV9VTlNQRUNJRklFRBAAEgYKAk9LEAESCQoFRVJST1IQAkKJAgoqY29tLmdv
b2dsZS5jbG91ZC5hbGxveWRiLmNvbm5lY3RvcnMudjFiZXRhQg5SZXNvdXJjZXNQcm90b1AB
WkpjbG91ZC5nb29nbGUuY29tL2dvL2FsbG95ZGIvY29ubmVjdG9ycy9hcGl2MWJldGEvY29u
bmVjdG9yc3BiO2Nvbm5lY3RvcnNwYqoCJkdvb2dsZS5DbG91ZC5BbGxveURiLkNvbm5lY3Rv
cnMuVjFCZXRhygImR29vZ2xlXENsb3VkXEFsbG95RGJcQ29ubmVjdG9yc1xWMWJldGHqAipH
b29nbGU6OkNsb3VkOjpBbGxveURiOjpDb25uZWN0b3JzOjpWMWJldGFKnhQKBhIEDgBPAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALwoJCgIDABIDEgAp
CggKAQgSAxQAQwoJCgIIJRIDFABDCggKAQgSAxUAYQoJCgIICxIDFQBhCggKAQgSAxYAIgoJ
CgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgAQwoJCgIIARIDGABDCggK
AQgSAxkARAoJCgIIKRIDGQBECggKAQgSAxoAQwoJCgIILRIDGgBDCqEDCgIEABIEIgA4ARqU
AyBNZXNzYWdlIHVzZWQgYnkgQWxsb3lEQiBjb25uZWN0b3JzIHRvIGV4Y2hhbmdlIGNsaWVu
dCBhbmQgY29ubmVjdGlvbiBtZXRhZGF0YQogd2l0aCB0aGUgc2VydmVyIGFmdGVyIGEgc3Vj
Y2Vzc2Z1bCBUTFMgaGFuZHNoYWtlLiBUaGlzIG1ldGFkYXRhIGluY2x1ZGVzIGFuCiBJQU0g
dG9rZW4sIHdoaWNoIGlzIHVzZWQgdG8gYXV0aGVudGljYXRlIHVzZXJzIGJhc2VkIG9uIHRo
ZWlyIElBTSBpZGVudGl0eS4KIFRoZSBzb2xlIHB1cnBvc2Ugb2YgdGhpcyBtZXNzYWdlIGlz
IGZvciB0aGUgdXNlIG9mIEFsbG95REIgY29ubmVjdG9ycy4KIENsaWVudHMgc2hvdWxkIG5v
dCByZWx5IG9uIHRoaXMgbWVzc2FnZSBkaXJlY3RseSBhcyB0aGVyZSBjYW4gYmUgYnJlYWtp
bmcKIGNoYW5nZXMgaW4gdGhlIGZ1dHVyZS4KCgoKAwQAARIDIggfCkUKBAQABAASBCQCLQMa
NyBBdXRoVHlwZSBjb250YWlucyBhbGwgc3VwcG9ydGVkIGF1dGhlbnRpY2F0aW9uIHR5cGVz
LgoKDAoFBAAEAAESAyQHDwpUCgYEAAQAAgASAyYEHhpFIEF1dGhlbnRpY2F0aW9uIHR5cGUg
aXMgdW5zcGVjaWZpZWQgYW5kIERCX05BVElWRSBpcyB1c2VkIGJ5IGRlZmF1bHQKCg4KBwQA
BAACAAESAyYEGQoOCgcEAAQAAgACEgMmHB0KPwoGBAAEAAIBEgMpBBIaMCBEYXRhYmFzZSBu
YXRpdmUgYXV0aGVudGljYXRpb24gKHVzZXIvcGFzc3dvcmQpCgoOCgcEAAQAAgEBEgMpBA0K
DgoHBAAEAAIBAhIDKRARCi0KBgQABAACAhIDLAQRGh4gQXV0b21hdGljIElBTSBhdXRoZW50
aWNhdGlvbgoKDgoHBAAEAAICARIDLAQMCg4KBwQABAACAgISAywPEAovCgQEAAIAEgMwAkEa
IiBPcHRpb25hbC4gQ29ubmVjdG9yIGluZm9ybWF0aW9uLgoKDAoFBAACAAUSAzACCAoMCgUE
AAIAARIDMAkTCgwKBQQAAgADEgMwFhcKDAoFBAACAAgSAzAYQAoPCggEAAIACJwIABIDMBk/
CiMKBAQAAgESAzMCGRoWIEF1dGhlbnRpY2F0aW9uIHR5cGUuCgoMCgUEAAIBBhIDMwIKCgwK
BQQAAgEBEgMzCxQKDAoFBAACAQMSAzMXGApwCgQEAAICEgM3AhoaYyBJQU0gdG9rZW4gdXNl
ZCBmb3IgYm90aCBJQU0gdXNlciBhdXRoZW50aWF0aW9uIGFuZAogYGFsbG95ZGIuaW5zdGFu
Y2VzLmNvbm5lY3RgIHBlcm1pc3Npb24gY2hlY2suCgoMCgUEAAICBRIDNwIICgwKBQQAAgIB
EgM3CRUKDAoFBAACAgMSAzcYGQrrAQoCBAESBD0ATwEa3gEgTWVzc2FnZSBmb3IgcmVzcG9u
c2UgdG8gbWV0YWRhdGEgZXhjaGFuZ2UgcmVxdWVzdC4gVGhlIHNvbGUgcHVycG9zZSBvZiB0
aGlzCiBtZXNzYWdlIGlzIGZvciB0aGUgdXNlIG9mIEFsbG95REIgY29ubmVjdG9ycy4gQ2xp
ZW50cyBzaG91bGQgbm90IHJlbHkgb24gdGhpcwogbWVzc2FnZSBkaXJlY3RseSBhcyB0aGVy
ZSBjYW4gYmUgYnJlYWtpbmcgY2hhbmdlcyBpbiB0aGUgZnV0dXJlLgoKCgoDBAEBEgM9CCAK
HgoEBAEEABIEPwJIAxoQIFJlc3BvbnNlIGNvZGUuCgoMCgUEAQQAARIDPwcTCiYKBgQBBAAC
ABIDQQQiGhcgVW5rbm93biByZXNwb25zZSBjb2RlCgoOCgcEAQQAAgABEgNBBB0KDgoHBAEE
AAIAAhIDQSAhChgKBgQBBAACARIDRAQLGgkgU3VjY2VzcwoKDgoHBAEEAAIBARIDRAQGCg4K
BwQBBAACAQISA0QJCgoYCgYEAQQAAgISA0cEDhoJIEZhaWx1cmUKCg4KBwQBBAACAgESA0cE
CQoOCgcEAQQAAgICEgNHDA0KHQoEBAECABIDSwIhGhAgUmVzcG9uc2UgY29kZS4KCgwKBQQB
AgAGEgNLAg4KDAoFBAECAAESA0sPHAoMCgUEAQIAAxIDSx8gCicKBAQBAgESA04CPBoaIE9w
dGlvbmFsLiBFcnJvciBtZXNzYWdlLgoKDAoFBAECAQUSA04CCAoMCgUEAQIBARIDTgkOCgwK
BQQBAgEDEgNOERIKDAoFBAECAQgSA04TOwoPCggEAQIBCJwIABIDThQ6YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest ===
    # Fields for MetadataExchangeRequest
    # Field: user_agent Type: 9 ()
    # Field: auth_type Type: 14 (.google.cloud.alloydb.connectors.v1beta.MetadataExchangeRequest.AuthType)
    # Field: oauth2_token Type: 9 ()

# Enum: MetadataExchangeRequest::AuthType
our $MetadataExchangeRequest_AUTH_TYPE_UNSPECIFIED = 0;
our $MetadataExchangeRequest_DB_NATIVE = 1;
our $MetadataExchangeRequest_AUTO_IAM = 2;

# === Message: Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeResponse ===
    # Fields for MetadataExchangeResponse
    # Field: response_code Type: 14 (.google.cloud.alloydb.connectors.v1beta.MetadataExchangeResponse.ResponseCode)
    # Field: error Type: 9 ()

# Enum: MetadataExchangeResponse::ResponseCode
our $MetadataExchangeResponse_RESPONSE_CODE_UNSPECIFIED = 0;
our $MetadataExchangeResponse_OK = 1;
our $MetadataExchangeResponse_ERROR = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::Connectors::V1beta::Resources - Compiled Protocol Buffers messages for google/cloud/alloydb/connectors/v1beta/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::Connectors::V1beta::Resources;

    my $msg = Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest->new({
        user_agent => $user_agent,
        auth_type => $auth_type,
        oauth2_token => $oauth2_token,
    });

    # Read or update a field
    my $val = $msg->user_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/connectors/v1beta/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeRequest

Message used by AlloyDB connectors to exchange client and connection metadata
with the server after a successful TLS handshake. This metadata includes an
IAM token, which is used to authenticate users based on their IAM identity.
The sole purpose of this message is for the use of AlloyDB connectors.
Clients should not rely on this message directly as there can be breaking
changes in the future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<String>

Optional. Connector information.

=item * C<< $msg->auth_type() >> / C<< $msg->auth_type($value) >>

Type: C<Enum> (L<Google::Cloud::Alloydb::Connectors::V1beta::MetadataExchangeRequest::AuthType>)

Authentication type.

=item * C<< $msg->oauth2_token() >> / C<< $msg->oauth2_token($value) >>

Type: C<String>

IAM token used for both IAM user authentiation and
`alloydb.instances.connect` permission check.

=back

=head3 Enum: MetadataExchangeRequest::AuthType

=over 4

=item * C<AUTH_TYPE_UNSPECIFIED> => C<0>

=item * C<DB_NATIVE> => C<1>

=item * C<AUTO_IAM> => C<2>

=back

=head2 Google::Cloud::Alloydb::Connectors::V1beta::Resources::MetadataExchangeResponse

Message for response to metadata exchange request. The sole purpose of this
message is for the use of AlloyDB connectors. Clients should not rely on this
message directly as there can be breaking changes in the future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->response_code() >> / C<< $msg->response_code($value) >>

Type: C<Enum> (L<Google::Cloud::Alloydb::Connectors::V1beta::MetadataExchangeResponse::ResponseCode>)

Response code.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<String>

Optional. Error message.

=back

=head3 Enum: MetadataExchangeResponse::ResponseCode

=over 4

=item * C<RESPONSE_CODE_UNSPECIFIED> => C<0>

=item * C<OK> => C<1>

=item * C<ERROR> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::Connectors::V1beta::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
