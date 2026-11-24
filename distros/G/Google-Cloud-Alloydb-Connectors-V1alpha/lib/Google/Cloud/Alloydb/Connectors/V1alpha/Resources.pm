package Google::Cloud::Alloydb::Connectors::V1alpha::Resources;

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
Cjdnb29nbGUvY2xvdWQvYWxsb3lkYi9jb25uZWN0b3JzL3YxYWxwaGEvcmVzb3VyY2VzLnBy
b3RvEidnb29nbGUuY2xvdWQuYWxsb3lkYi5jb25uZWN0b3JzLnYxYWxwaGEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8ijAIKF01ldGFkYXRhRXhjaGFuZ2VSZXF1ZXN0EiIK
CnVzZXJfYWdlbnQYASABKAlCA+BBAVIJdXNlckFnZW50EmYKCWF1dGhfdHlwZRgCIAEoDjJJ
Lmdvb2dsZS5jbG91ZC5hbGxveWRiLmNvbm5lY3RvcnMudjFhbHBoYS5NZXRhZGF0YUV4Y2hh
bmdlUmVxdWVzdC5BdXRoVHlwZVIIYXV0aFR5cGUSIQoMb2F1dGgyX3Rva2VuGAMgASgJUgtv
YXV0aDJUb2tlbiJCCghBdXRoVHlwZRIZChVBVVRIX1RZUEVfVU5TUEVDSUZJRUQQABINCglE
Ql9OQVRJVkUQARIMCghBVVRPX0lBTRACIuwBChhNZXRhZGF0YUV4Y2hhbmdlUmVzcG9uc2US
cwoNcmVzcG9uc2VfY29kZRgBIAEoDjJOLmdvb2dsZS5jbG91ZC5hbGxveWRiLmNvbm5lY3Rv
cnMudjFhbHBoYS5NZXRhZGF0YUV4Y2hhbmdlUmVzcG9uc2UuUmVzcG9uc2VDb2RlUgxyZXNw
b25zZUNvZGUSGQoFZXJyb3IYAiABKAlCA+BBAVIFZXJyb3IiQAoMUmVzcG9uc2VDb2RlEh0K
GVJFU1BPTlNFX0NPREVfVU5TUEVDSUZJRUQQABIGCgJPSxABEgkKBUVSUk9SEAJCjgIKK2Nv
bS5nb29nbGUuY2xvdWQuYWxsb3lkYi5jb25uZWN0b3JzLnYxYWxwaGFCDlJlc291cmNlc1By
b3RvUAFaS2Nsb3VkLmdvb2dsZS5jb20vZ28vYWxsb3lkYi9jb25uZWN0b3JzL2FwaXYxYWxw
aGEvY29ubmVjdG9yc3BiO2Nvbm5lY3RvcnNwYqoCJ0dvb2dsZS5DbG91ZC5BbGxveURiLkNv
bm5lY3RvcnMuVjFBbHBoYcoCJ0dvb2dsZVxDbG91ZFxBbGxveURiXENvbm5lY3RvcnNcVjFh
bHBoYeoCK0dvb2dsZTo6Q2xvdWQ6OkFsbG95RGI6OkNvbm5lY3RvcnM6OlYxYWxwaGFKnhQK
BhIEDgBPAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMAoJ
CgIDABIDEgApCggKAQgSAxQARAoJCgIIJRIDFABECggKAQgSAxUAYgoJCgIICxIDFQBiCggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgSAxgARAoJCgII
ARIDGABECggKAQgSAxkARQoJCgIIKRIDGQBFCggKAQgSAxoARAoJCgIILRIDGgBECqEDCgIE
ABIEIgA4ARqUAyBNZXNzYWdlIHVzZWQgYnkgQWxsb3lEQiBjb25uZWN0b3JzIHRvIGV4Y2hh
bmdlIGNsaWVudCBhbmQgY29ubmVjdGlvbiBtZXRhZGF0YQogd2l0aCB0aGUgc2VydmVyIGFm
dGVyIGEgc3VjY2Vzc2Z1bCBUTFMgaGFuZHNoYWtlLiBUaGlzIG1ldGFkYXRhIGluY2x1ZGVz
IGFuCiBJQU0gdG9rZW4sIHdoaWNoIGlzIHVzZWQgdG8gYXV0aGVudGljYXRlIHVzZXJzIGJh
c2VkIG9uIHRoZWlyIElBTSBpZGVudGl0eS4KIFRoZSBzb2xlIHB1cnBvc2Ugb2YgdGhpcyBt
ZXNzYWdlIGlzIGZvciB0aGUgdXNlIG9mIEFsbG95REIgY29ubmVjdG9ycy4KIENsaWVudHMg
c2hvdWxkIG5vdCByZWx5IG9uIHRoaXMgbWVzc2FnZSBkaXJlY3RseSBhcyB0aGVyZSBjYW4g
YmUgYnJlYWtpbmcKIGNoYW5nZXMgaW4gdGhlIGZ1dHVyZS4KCgoKAwQAARIDIggfCkUKBAQA
BAASBCQCLQMaNyBBdXRoVHlwZSBjb250YWlucyBhbGwgc3VwcG9ydGVkIGF1dGhlbnRpY2F0
aW9uIHR5cGVzLgoKDAoFBAAEAAESAyQHDwpUCgYEAAQAAgASAyYEHhpFIEF1dGhlbnRpY2F0
aW9uIHR5cGUgaXMgdW5zcGVjaWZpZWQgYW5kIERCX05BVElWRSBpcyB1c2VkIGJ5IGRlZmF1
bHQKCg4KBwQABAACAAESAyYEGQoOCgcEAAQAAgACEgMmHB0KPwoGBAAEAAIBEgMpBBIaMCBE
YXRhYmFzZSBuYXRpdmUgYXV0aGVudGljYXRpb24gKHVzZXIvcGFzc3dvcmQpCgoOCgcEAAQA
AgEBEgMpBA0KDgoHBAAEAAIBAhIDKRARCi0KBgQABAACAhIDLAQRGh4gQXV0b21hdGljIElB
TSBhdXRoZW50aWNhdGlvbgoKDgoHBAAEAAICARIDLAQMCg4KBwQABAACAgISAywPEAovCgQE
AAIAEgMwAkEaIiBPcHRpb25hbC4gQ29ubmVjdG9yIGluZm9ybWF0aW9uLgoKDAoFBAACAAUS
AzACCAoMCgUEAAIAARIDMAkTCgwKBQQAAgADEgMwFhcKDAoFBAACAAgSAzAYQAoPCggEAAIA
CJwIABIDMBk/CiMKBAQAAgESAzMCGRoWIEF1dGhlbnRpY2F0aW9uIHR5cGUuCgoMCgUEAAIB
BhIDMwIKCgwKBQQAAgEBEgMzCxQKDAoFBAACAQMSAzMXGApwCgQEAAICEgM3AhoaYyBJQU0g
dG9rZW4gdXNlZCBmb3IgYm90aCBJQU0gdXNlciBhdXRoZW50aWF0aW9uIGFuZAogYGFsbG95
ZGIuaW5zdGFuY2VzLmNvbm5lY3RgIHBlcm1pc3Npb24gY2hlY2suCgoMCgUEAAICBRIDNwII
CgwKBQQAAgIBEgM3CRUKDAoFBAACAgMSAzcYGQrrAQoCBAESBD0ATwEa3gEgTWVzc2FnZSBm
b3IgcmVzcG9uc2UgdG8gbWV0YWRhdGEgZXhjaGFuZ2UgcmVxdWVzdC4gVGhlIHNvbGUgcHVy
cG9zZSBvZiB0aGlzCiBtZXNzYWdlIGlzIGZvciB0aGUgdXNlIG9mIEFsbG95REIgY29ubmVj
dG9ycy4gQ2xpZW50cyBzaG91bGQgbm90IHJlbHkgb24gdGhpcwogbWVzc2FnZSBkaXJlY3Rs
eSBhcyB0aGVyZSBjYW4gYmUgYnJlYWtpbmcgY2hhbmdlcyBpbiB0aGUgZnV0dXJlLgoKCgoD
BAEBEgM9CCAKHgoEBAEEABIEPwJIAxoQIFJlc3BvbnNlIGNvZGUuCgoMCgUEAQQAARIDPwcT
CiYKBgQBBAACABIDQQQiGhcgVW5rbm93biByZXNwb25zZSBjb2RlCgoOCgcEAQQAAgABEgNB
BB0KDgoHBAEEAAIAAhIDQSAhChgKBgQBBAACARIDRAQLGgkgU3VjY2VzcwoKDgoHBAEEAAIB
ARIDRAQGCg4KBwQBBAACAQISA0QJCgoYCgYEAQQAAgISA0cEDhoJIEZhaWx1cmUKCg4KBwQB
BAACAgESA0cECQoOCgcEAQQAAgICEgNHDA0KHQoEBAECABIDSwIhGhAgUmVzcG9uc2UgY29k
ZS4KCgwKBQQBAgAGEgNLAg4KDAoFBAECAAESA0sPHAoMCgUEAQIAAxIDSx8gCicKBAQBAgES
A04CPBoaIE9wdGlvbmFsLiBFcnJvciBtZXNzYWdlLgoKDAoFBAECAQUSA04CCAoMCgUEAQIB
ARIDTgkOCgwKBQQBAgEDEgNOERIKDAoFBAECAQgSA04TOwoPCggEAQIBCJwIABIDThQ6YgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::Connectors::V1alpha::Resources::MetadataExchangeRequest ===
    # Fields for MetadataExchangeRequest
    # Field: user_agent Type: 9 ()
    # Field: auth_type Type: 14 (.google.cloud.alloydb.connectors.v1alpha.MetadataExchangeRequest.AuthType)
    # Field: oauth2_token Type: 9 ()

# Enum: MetadataExchangeRequest::AuthType
our $MetadataExchangeRequest_AUTH_TYPE_UNSPECIFIED = 0;
our $MetadataExchangeRequest_DB_NATIVE = 1;
our $MetadataExchangeRequest_AUTO_IAM = 2;

# === Message: Google::Cloud::Alloydb::Connectors::V1alpha::Resources::MetadataExchangeResponse ===
    # Fields for MetadataExchangeResponse
    # Field: response_code Type: 14 (.google.cloud.alloydb.connectors.v1alpha.MetadataExchangeResponse.ResponseCode)
    # Field: error Type: 9 ()

# Enum: MetadataExchangeResponse::ResponseCode
our $MetadataExchangeResponse_RESPONSE_CODE_UNSPECIFIED = 0;
our $MetadataExchangeResponse_OK = 1;
our $MetadataExchangeResponse_ERROR = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::Connectors::V1alpha::Resources - Compiled Protocol Buffers messages for google/cloud/alloydb/connectors/v1alpha/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::Connectors::V1alpha::Resources;

    my $msg = Google::Cloud::Alloydb::Connectors::V1alpha::Resources::MetadataExchangeRequest->new({
        user_agent => $user_agent,
        auth_type => $auth_type,
        oauth2_token => $oauth2_token,
    });

    # Read or update a field
    my $val = $msg->user_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::Connectors::V1alpha::Resources::MetadataExchangeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/connectors/v1alpha/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::Connectors::V1alpha::Resources::MetadataExchangeRequest

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

Type: C<Enum> (L<Google::Cloud::Alloydb::Connectors::V1alpha::MetadataExchangeRequest::AuthType>)

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

=head2 Google::Cloud::Alloydb::Connectors::V1alpha::Resources::MetadataExchangeResponse

Message for response to metadata exchange request. The sole purpose of this
message is for the use of AlloyDB connectors. Clients should not rely on this
message directly as there can be breaking changes in the future.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->response_code() >> / C<< $msg->response_code($value) >>

Type: C<Enum> (L<Google::Cloud::Alloydb::Connectors::V1alpha::MetadataExchangeResponse::ResponseCode>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::Connectors::V1alpha::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
