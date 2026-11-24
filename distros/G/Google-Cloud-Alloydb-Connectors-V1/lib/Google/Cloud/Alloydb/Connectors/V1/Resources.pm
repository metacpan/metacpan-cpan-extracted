package Google::Cloud::Alloydb::Connectors::V1::Resources;

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
CjJnb29nbGUvY2xvdWQvYWxsb3lkYi9jb25uZWN0b3JzL3YxL3Jlc291cmNlcy5wcm90bxIi
Z29vZ2xlLmNsb3VkLmFsbG95ZGIuY29ubmVjdG9ycy52MRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90byKHAgoXTWV0YWRhdGFFeGNoYW5nZVJlcXVlc3QSIgoKdXNlcl9hZ2Vu
dBgBIAEoCUID4EEBUgl1c2VyQWdlbnQSYQoJYXV0aF90eXBlGAIgASgOMkQuZ29vZ2xlLmNs
b3VkLmFsbG95ZGIuY29ubmVjdG9ycy52MS5NZXRhZGF0YUV4Y2hhbmdlUmVxdWVzdC5BdXRo
VHlwZVIIYXV0aFR5cGUSIQoMb2F1dGgyX3Rva2VuGAMgASgJUgtvYXV0aDJUb2tlbiJCCghB
dXRoVHlwZRIZChVBVVRIX1RZUEVfVU5TUEVDSUZJRUQQABINCglEQl9OQVRJVkUQARIMCghB
VVRPX0lBTRACIucBChhNZXRhZGF0YUV4Y2hhbmdlUmVzcG9uc2USbgoNcmVzcG9uc2VfY29k
ZRgBIAEoDjJJLmdvb2dsZS5jbG91ZC5hbGxveWRiLmNvbm5lY3RvcnMudjEuTWV0YWRhdGFF
eGNoYW5nZVJlc3BvbnNlLlJlc3BvbnNlQ29kZVIMcmVzcG9uc2VDb2RlEhkKBWVycm9yGAIg
ASgJQgPgQQFSBWVycm9yIkAKDFJlc3BvbnNlQ29kZRIdChlSRVNQT05TRV9DT0RFX1VOU1BF
Q0lGSUVEEAASBgoCT0sQARIJCgVFUlJPUhACQvUBCiZjb20uZ29vZ2xlLmNsb3VkLmFsbG95
ZGIuY29ubmVjdG9ycy52MUIOUmVzb3VyY2VzUHJvdG9QAVpGY2xvdWQuZ29vZ2xlLmNvbS9n
by9hbGxveWRiL2Nvbm5lY3RvcnMvYXBpdjEvY29ubmVjdG9yc3BiO2Nvbm5lY3RvcnNwYqoC
Ikdvb2dsZS5DbG91ZC5BbGxveURiLkNvbm5lY3RvcnMuVjHKAiJHb29nbGVcQ2xvdWRcQWxs
b3lEYlxDb25uZWN0b3JzXFYx6gImR29vZ2xlOjpDbG91ZDo6QWxsb3lEYjo6Q29ubmVjdG9y
czo6VjFKnhQKBhIEDgBPAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAAKwoJCgIDABIDEgApCggKAQgSAxQAPwoJCgIIJRIDFAA/CggKAQgSAxUAXQoJCgII
CxIDFQBdCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgS
AxgAPwoJCgIIARIDGAA/CggKAQgSAxkAQAoJCgIIKRIDGQBACggKAQgSAxoAPwoJCgIILRID
GgA/CqEDCgIEABIEIgA4ARqUAyBNZXNzYWdlIHVzZWQgYnkgQWxsb3lEQiBjb25uZWN0b3Jz
IHRvIGV4Y2hhbmdlIGNsaWVudCBhbmQgY29ubmVjdGlvbiBtZXRhZGF0YQogd2l0aCB0aGUg
c2VydmVyIGFmdGVyIGEgc3VjY2Vzc2Z1bCBUTFMgaGFuZHNoYWtlLiBUaGlzIG1ldGFkYXRh
IGluY2x1ZGVzIGFuCiBJQU0gdG9rZW4sIHdoaWNoIGlzIHVzZWQgdG8gYXV0aGVudGljYXRl
IHVzZXJzIGJhc2VkIG9uIHRoZWlyIElBTSBpZGVudGl0eS4KIFRoZSBzb2xlIHB1cnBvc2Ug
b2YgdGhpcyBtZXNzYWdlIGlzIGZvciB0aGUgdXNlIG9mIEFsbG95REIgY29ubmVjdG9ycy4K
IENsaWVudHMgc2hvdWxkIG5vdCByZWx5IG9uIHRoaXMgbWVzc2FnZSBkaXJlY3RseSBhcyB0
aGVyZSBjYW4gYmUgYnJlYWtpbmcKIGNoYW5nZXMgaW4gdGhlIGZ1dHVyZS4KCgoKAwQAARID
IggfCkUKBAQABAASBCQCLQMaNyBBdXRoVHlwZSBjb250YWlucyBhbGwgc3VwcG9ydGVkIGF1
dGhlbnRpY2F0aW9uIHR5cGVzLgoKDAoFBAAEAAESAyQHDwpUCgYEAAQAAgASAyYEHhpFIEF1
dGhlbnRpY2F0aW9uIHR5cGUgaXMgdW5zcGVjaWZpZWQgYW5kIERCX05BVElWRSBpcyB1c2Vk
IGJ5IGRlZmF1bHQKCg4KBwQABAACAAESAyYEGQoOCgcEAAQAAgACEgMmHB0KPwoGBAAEAAIB
EgMpBBIaMCBEYXRhYmFzZSBuYXRpdmUgYXV0aGVudGljYXRpb24gKHVzZXIvcGFzc3dvcmQp
CgoOCgcEAAQAAgEBEgMpBA0KDgoHBAAEAAIBAhIDKRARCi0KBgQABAACAhIDLAQRGh4gQXV0
b21hdGljIElBTSBhdXRoZW50aWNhdGlvbgoKDgoHBAAEAAICARIDLAQMCg4KBwQABAACAgIS
AywPEAovCgQEAAIAEgMwAkEaIiBPcHRpb25hbC4gQ29ubmVjdG9yIGluZm9ybWF0aW9uLgoK
DAoFBAACAAUSAzACCAoMCgUEAAIAARIDMAkTCgwKBQQAAgADEgMwFhcKDAoFBAACAAgSAzAY
QAoPCggEAAIACJwIABIDMBk/CiMKBAQAAgESAzMCGRoWIEF1dGhlbnRpY2F0aW9uIHR5cGUu
CgoMCgUEAAIBBhIDMwIKCgwKBQQAAgEBEgMzCxQKDAoFBAACAQMSAzMXGApwCgQEAAICEgM3
AhoaYyBJQU0gdG9rZW4gdXNlZCBmb3IgYm90aCBJQU0gdXNlciBhdXRoZW50aWF0aW9uIGFu
ZAogYGFsbG95ZGIuaW5zdGFuY2VzLmNvbm5lY3RgIHBlcm1pc3Npb24gY2hlY2suCgoMCgUE
AAICBRIDNwIICgwKBQQAAgIBEgM3CRUKDAoFBAACAgMSAzcYGQrrAQoCBAESBD0ATwEa3gEg
TWVzc2FnZSBmb3IgcmVzcG9uc2UgdG8gbWV0YWRhdGEgZXhjaGFuZ2UgcmVxdWVzdC4gVGhl
IHNvbGUgcHVycG9zZSBvZiB0aGlzCiBtZXNzYWdlIGlzIGZvciB0aGUgdXNlIG9mIEFsbG95
REIgY29ubmVjdG9ycy4gQ2xpZW50cyBzaG91bGQgbm90IHJlbHkgb24gdGhpcwogbWVzc2Fn
ZSBkaXJlY3RseSBhcyB0aGVyZSBjYW4gYmUgYnJlYWtpbmcgY2hhbmdlcyBpbiB0aGUgZnV0
dXJlLgoKCgoDBAEBEgM9CCAKHgoEBAEEABIEPwJIAxoQIFJlc3BvbnNlIGNvZGUuCgoMCgUE
AQQAARIDPwcTCiYKBgQBBAACABIDQQQiGhcgVW5rbm93biByZXNwb25zZSBjb2RlCgoOCgcE
AQQAAgABEgNBBB0KDgoHBAEEAAIAAhIDQSAhChgKBgQBBAACARIDRAQLGgkgU3VjY2VzcwoK
DgoHBAEEAAIBARIDRAQGCg4KBwQBBAACAQISA0QJCgoYCgYEAQQAAgISA0cEDhoJIEZhaWx1
cmUKCg4KBwQBBAACAgESA0cECQoOCgcEAQQAAgICEgNHDA0KHQoEBAECABIDSwIhGhAgUmVz
cG9uc2UgY29kZS4KCgwKBQQBAgAGEgNLAg4KDAoFBAECAAESA0sPHAoMCgUEAQIAAxIDSx8g
CicKBAQBAgESA04CPBoaIE9wdGlvbmFsLiBFcnJvciBtZXNzYWdlLgoKDAoFBAECAQUSA04C
CAoMCgUEAQIBARIDTgkOCgwKBQQBAgEDEgNOERIKDAoFBAECAQgSA04TOwoPCggEAQIBCJwI
ABIDThQ6YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::Connectors::V1::Resources::MetadataExchangeRequest ===
    # Fields for MetadataExchangeRequest
    # Field: user_agent Type: 9 ()
    # Field: auth_type Type: 14 (.google.cloud.alloydb.connectors.v1.MetadataExchangeRequest.AuthType)
    # Field: oauth2_token Type: 9 ()

# Enum: MetadataExchangeRequest::AuthType
our $MetadataExchangeRequest_AUTH_TYPE_UNSPECIFIED = 0;
our $MetadataExchangeRequest_DB_NATIVE = 1;
our $MetadataExchangeRequest_AUTO_IAM = 2;

# === Message: Google::Cloud::Alloydb::Connectors::V1::Resources::MetadataExchangeResponse ===
    # Fields for MetadataExchangeResponse
    # Field: response_code Type: 14 (.google.cloud.alloydb.connectors.v1.MetadataExchangeResponse.ResponseCode)
    # Field: error Type: 9 ()

# Enum: MetadataExchangeResponse::ResponseCode
our $MetadataExchangeResponse_RESPONSE_CODE_UNSPECIFIED = 0;
our $MetadataExchangeResponse_OK = 1;
our $MetadataExchangeResponse_ERROR = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::Connectors::V1::Resources - Compiled Protocol Buffers messages for google/cloud/alloydb/connectors/v1/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::Connectors::V1::Resources;

    my $msg = Google::Cloud::Alloydb::Connectors::V1::Resources::MetadataExchangeRequest->new({
        user_agent => $user_agent,
        auth_type => $auth_type,
        oauth2_token => $oauth2_token,
    });

    # Read or update a field
    my $val = $msg->user_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::Connectors::V1::Resources::MetadataExchangeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/connectors/v1/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::Connectors::V1::Resources::MetadataExchangeRequest

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

Type: C<Enum> (L<Google::Cloud::Alloydb::Connectors::V1::MetadataExchangeRequest::AuthType>)

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

=head2 Google::Cloud::Alloydb::Connectors::V1::Resources::MetadataExchangeResponse

Message for response to metadata exchange request. The sole purpose of this
message is for the use of AlloyDB connectors. Clients should not rely on this
message directly as there can be breaking changes in the future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->response_code() >> / C<< $msg->response_code($value) >>

Type: C<Enum> (L<Google::Cloud::Alloydb::Connectors::V1::MetadataExchangeResponse::ResponseCode>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::Connectors::V1::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
