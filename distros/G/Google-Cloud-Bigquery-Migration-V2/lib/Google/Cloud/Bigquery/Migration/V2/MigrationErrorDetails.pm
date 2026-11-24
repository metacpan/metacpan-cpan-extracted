package Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Rpc::ErrorDetails };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL21pZ3JhdGlvbl9lcnJvcl9k
ZXRhaWxzLnByb3RvEiJnb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh5nb29nbGUvcnBjL2Vycm9yX2RldGFpbHMu
cHJvdG8i2gEKE1Jlc291cmNlRXJyb3JEZXRhaWwSQgoNcmVzb3VyY2VfaW5mbxgBIAEoCzIY
Lmdvb2dsZS5ycGMuUmVzb3VyY2VJbmZvQgPgQQJSDHJlc291cmNlSW5mbxJZCg1lcnJvcl9k
ZXRhaWxzGAIgAygLMi8uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5FcnJv
ckRldGFpbEID4EECUgxlcnJvckRldGFpbHMSJAoLZXJyb3JfY291bnQYAyABKAVCA+BBAlIK
ZXJyb3JDb3VudCKcAQoLRXJyb3JEZXRhaWwSUgoIbG9jYXRpb24YASABKAsyMS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLkVycm9yTG9jYXRpb25CA+BBAVIIbG9jYXRp
b24SOQoKZXJyb3JfaW5mbxgCIAEoCzIVLmdvb2dsZS5ycGMuRXJyb3JJbmZvQgPgQQJSCWVy
cm9ySW5mbyJFCg1FcnJvckxvY2F0aW9uEhcKBGxpbmUYASABKAVCA+BBAVIEbGluZRIbCgZj
b2x1bW4YAiABKAVCA+BBAVIGY29sdW1uQtYBCiZjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5
Lm1pZ3JhdGlvbi52MkIaTWlncmF0aW9uRXJyb3JEZXRhaWxzUHJvdG9QAVpEY2xvdWQuZ29v
Z2xlLmNvbS9nby9iaWdxdWVyeS9taWdyYXRpb24vYXBpdjIvbWlncmF0aW9ucGI7bWlncmF0
aW9ucGKqAiJHb29nbGUuQ2xvdWQuQmlnUXVlcnkuTWlncmF0aW9uLlYyygIiR29vZ2xlXENs
b3VkXEJpZ1F1ZXJ5XE1pZ3JhdGlvblxWMkqjEgoGEgQOAD8BCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACkKCQoCAwESAxMAKAoICgEI
EgMVAD8KCQoCCCUSAxUAPwoICgEIEgMWAFsKCQoCCAsSAxYAWwoICgEIEgMXACIKCQoCCAoS
AxcAIgoICgEIEgMYADsKCQoCCAgSAxgAOwoICgEIEgMZAD8KCQoCCAESAxkAPwoICgEIEgMa
AEAKCQoCCCkSAxoAQApKCgIEABIEHQAqARo+IFByb3ZpZGVzIGRldGFpbHMgZm9yIGVycm9y
cyBhbmQgdGhlIGNvcnJlc3BvbmRpbmcgcmVzb3VyY2VzLgoKCgoDBAABEgMdCBsKVAoEBAAC
ABIEHwIgLxpGIFJlcXVpcmVkLiBJbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVzb3VyY2Ugd2hl
cmUgdGhlIGVycm9yIGlzIGxvY2F0ZWQuCgoMCgUEAAIABhIDHwIZCgwKBQQAAgABEgMfGicK
DAoFBAACAAMSAx8qKwoMCgUEAAIACBIDIAYuCg8KCAQAAgAInAgAEgMgBy0KPQoEBAACARIE
IwIkLxovIFJlcXVpcmVkLiBUaGUgZXJyb3IgZGV0YWlscyBmb3IgdGhlIHJlc291cmNlLgoK
DAoFBAACAQQSAyMCCgoMCgUEAAIBBhIDIwsWCgwKBQQAAgEBEgMjFyQKDAoFBAACAQMSAyMn
KAoMCgUEAAIBCBIDJAYuCg8KCAQAAgEInAgAEgMkBy0KuAEKBAQAAgISAykCQRqqASBSZXF1
aXJlZC4gSG93IG1hbnkgZXJyb3JzIHRoZXJlIGFyZSBpbiB0b3RhbCBmb3IgdGhlIHJlc291
cmNlLiBUcnVuY2F0aW9uCiBjYW4gYmUgaW5kaWNhdGVkIGJ5IGhhdmluZyBhbiBgZXJyb3Jf
Y291bnRgIHRoYXQgaXMgaGlnaGVyIHRoYW4gdGhlIHNpemUgb2YKIGBlcnJvcl9kZXRhaWxz
YC4KCgwKBQQAAgIFEgMpAgcKDAoFBAACAgESAykIEwoMCgUEAAICAxIDKRYXCgwKBQQAAgII
EgMpGEAKDwoIBAACAgicCAASAykZPwppCgIEARIELgA0ARpdIFByb3ZpZGVzIGRldGFpbHMg
Zm9yIGVycm9ycywgZS5nLiBpc3N1ZXMgdGhhdCB3aGVyZSBlbmNvdW50ZXJlZCB3aGVuCiBw
cm9jZXNzaW5nIGEgc3VidGFzay4KCgoKAwQBARIDLggTClAKBAQBAgASAzACRhpDIE9wdGlv
bmFsLiBUaGUgZXhhY3QgbG9jYXRpb24gd2l0aGluIHRoZSByZXNvdXJjZSAoaWYgYXBwbGlj
YWJsZSkuCgoMCgUEAQIABhIDMAIPCgwKBQQBAgABEgMwEBgKDAoFBAECAAMSAzAbHAoMCgUE
AQIACBIDMB1FCg8KCAQBAgAInAgAEgMwHkQKUQoEBAECARIDMwJPGkQgUmVxdWlyZWQuIERl
c2NyaWJlcyB0aGUgY2F1c2Ugb2YgdGhlIGVycm9yIHdpdGggc3RydWN0dXJlZCBkZXRhaWwu
CgoMCgUEAQIBBhIDMwIWCgwKBQQBAgEBEgMzFyEKDAoFBAECAQMSAzMkJQoMCgUEAQIBCBID
MyZOCg8KCAQBAgEInAgAEgMzJ00KQQoCBAISBDcAPwEaNSBIb2xkcyBpbmZvcm1hdGlvbiBh
Ym91dCB3aGVyZSB0aGUgZXJyb3IgaXMgbG9jYXRlZC4KCgoKAwQCARIDNwgVCokBCgQEAgIA
EgM6AjoafCBPcHRpb25hbC4gSWYgYXBwbGljYWJsZSwgZGVub3RlcyB0aGUgbGluZSB3aGVy
ZSB0aGUgZXJyb3Igb2NjdXJyZWQuIEEgemVybwogdmFsdWUgbWVhbnMgdGhhdCB0aGVyZSBp
cyBubyBsaW5lIGluZm9ybWF0aW9uLgoKDAoFBAICAAUSAzoCBwoMCgUEAgIAARIDOggMCgwK
BQQCAgADEgM6DxAKDAoFBAICAAgSAzoROQoPCggEAgIACJwIABIDOhI4Co8BCgQEAgIBEgM+
AjwagQEgT3B0aW9uYWwuIElmIGFwcGxpY2FibGUsIGRlbm90ZXMgdGhlIGNvbHVtbiB3aGVy
ZSB0aGUgZXJyb3Igb2NjdXJyZWQuIEEKIHplcm8gdmFsdWUgbWVhbnMgdGhhdCB0aGVyZSBp
cyBubyBjb2x1bW5zIGluZm9ybWF0aW9uLgoKDAoFBAICAQUSAz4CBwoMCgUEAgIBARIDPggO
CgwKBQQCAgEDEgM+ERIKDAoFBAICAQgSAz4TOwoPCggEAgIBCJwIABIDPhQ6YgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ResourceErrorDetail ===
    # Fields for ResourceErrorDetail
    # Field: resource_info Type: 11 (.google.rpc.ResourceInfo)
    # Field: error_details Type: 11 (.google.cloud.bigquery.migration.v2.ErrorDetail)
    # Field: error_count Type: 5 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ErrorDetail ===
    # Fields for ErrorDetail
    # Field: location Type: 11 (.google.cloud.bigquery.migration.v2.ErrorLocation)
    # Field: error_info Type: 11 (.google.rpc.ErrorInfo)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ErrorLocation ===
    # Fields for ErrorLocation
    # Field: line Type: 5 ()
    # Field: column Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/migration_error_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails;

    my $msg = Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ResourceErrorDetail->new({
        resource_info => $resource_info,
        error_details => $error_details,
        error_count => $error_count,
    });

    # Read or update a field
    my $val = $msg->resource_info();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ResourceErrorDetail->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/migration_error_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ResourceErrorDetail

Provides details for errors and the corresponding resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_info() >> / C<< $msg->resource_info($value) >>

Type: C<Message> (L<Google::Rpc::ErrorDetails::ResourceInfo>)

Required. Information about the resource where the error is located.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ErrorDetail>)

Required. The error details for the resource.

=item * C<< $msg->error_count() >> / C<< $msg->error_count($value) >>

Type: C<Int32>

Required. How many errors there are in total for the resource. Truncation
can be indicated by having an `error_count` that is higher than the size of
`error_details`.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ErrorDetail

Provides details for errors, e.g. issues that where encountered when
processing a subtask.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ErrorLocation>)

Optional. The exact location within the resource (if applicable).

=item * C<< $msg->error_info() >> / C<< $msg->error_info($value) >>

Type: C<Message> (L<Google::Rpc::ErrorDetails::ErrorInfo>)

Required. Describes the cause of the error with structured detail.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::ErrorLocation

Holds information about where the error is located.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->line() >> / C<< $msg->line($value) >>

Type: C<Int32>

Optional. If applicable, denotes the line where the error occurred. A zero
value means that there is no line information.

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<Int32>

Optional. If applicable, denotes the column where the error occurred. A
zero value means that there is no columns information.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::MigrationErrorDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
