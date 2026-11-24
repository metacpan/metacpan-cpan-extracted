package Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails;

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
CkVnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvbWlncmF0aW9uX2Vy
cm9yX2RldGFpbHMucHJvdG8SJ2dvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJh
bHBoYRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoeZ29vZ2xlL3JwYy9lcnJv
cl9kZXRhaWxzLnByb3RvIt8BChNSZXNvdXJjZUVycm9yRGV0YWlsEkIKDXJlc291cmNlX2lu
Zm8YASABKAsyGC5nb29nbGUucnBjLlJlc291cmNlSW5mb0ID4EECUgxyZXNvdXJjZUluZm8S
XgoNZXJyb3JfZGV0YWlscxgCIAMoCzI0Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRp
b24udjJhbHBoYS5FcnJvckRldGFpbEID4EECUgxlcnJvckRldGFpbHMSJAoLZXJyb3JfY291
bnQYAyABKAVCA+BBAlIKZXJyb3JDb3VudCKhAQoLRXJyb3JEZXRhaWwSVwoIbG9jYXRpb24Y
ASABKAsyNi5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuRXJyb3JM
b2NhdGlvbkID4EEBUghsb2NhdGlvbhI5CgplcnJvcl9pbmZvGAIgASgLMhUuZ29vZ2xlLnJw
Yy5FcnJvckluZm9CA+BBAlIJZXJyb3JJbmZvIkUKDUVycm9yTG9jYXRpb24SFwoEbGluZRgB
IAEoBUID4EEBUgRsaW5lEhsKBmNvbHVtbhgCIAEoBUID4EEBUgZjb2x1bW5C6gEKK2NvbS5n
b29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGFCGk1pZ3JhdGlvbkVycm9y
RGV0YWlsc1Byb3RvUAFaSWNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWlncmF0aW9u
L2FwaXYyYWxwaGEvbWlncmF0aW9ucGI7bWlncmF0aW9ucGKqAidHb29nbGUuQ2xvdWQuQmln
UXVlcnkuTWlncmF0aW9uLlYyQWxwaGHKAidHb29nbGVcQ2xvdWRcQmlnUXVlcnlcTWlncmF0
aW9uXFYyYWxwaGFKoRIKBhIEDgA9AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAMAoJCgIDABIDEgApCgkKAgMBEgMTACgKCAoBCBIDFQBECgkKAgglEgMV
AEQKCAoBCBIDFgBgCgkKAggLEgMWAGAKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA7
CgkKAggIEgMYADsKCAoBCBIDGQBECgkKAggBEgMZAEQKCAoBCBIDGgBFCgkKAggpEgMaAEUK
SgoCBAASBB0AKAEaPiBQcm92aWRlcyBkZXRhaWxzIGZvciBlcnJvcnMgYW5kIHRoZSBjb3Jy
ZXNwb25kaW5nIHJlc291cmNlcy4KCgoKAwQAARIDHQgbClMKBAQAAgASAx8CVRpGIFJlcXVp
cmVkLiBJbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVzb3VyY2Ugd2hlcmUgdGhlIGVycm9yIGlz
IGxvY2F0ZWQuCgoMCgUEAAIABhIDHwIZCgwKBQQAAgABEgMfGicKDAoFBAACAAMSAx8qKwoM
CgUEAAIACBIDHyxUCg8KCAQAAgAInAgAEgMfLVMKPAoEBAACARIDIgJSGi8gUmVxdWlyZWQu
IFRoZSBlcnJvciBkZXRhaWxzIGZvciB0aGUgcmVzb3VyY2UuCgoMCgUEAAIBBBIDIgIKCgwK
BQQAAgEGEgMiCxYKDAoFBAACAQESAyIXJAoMCgUEAAIBAxIDIicoCgwKBQQAAgEIEgMiKVEK
DwoIBAACAQicCAASAyIqUAq4AQoEBAACAhIDJwJBGqoBIFJlcXVpcmVkLiBIb3cgbWFueSBl
cnJvcnMgdGhlcmUgYXJlIGluIHRvdGFsIGZvciB0aGUgcmVzb3VyY2UuIFRydW5jYXRpb24g
Y2FuIGJlCiBpbmRpY2F0ZWQgYnkgaGF2aW5nIGFuIGBlcnJvcl9jb3VudGAgdGhhdCBpcyBo
aWdoZXIgdGhhbiB0aGUgc2l6ZSBvZgogYGVycm9yX2RldGFpbHNgLgoKDAoFBAACAgUSAycC
BwoMCgUEAAICARIDJwgTCgwKBQQAAgIDEgMnFhcKDAoFBAACAggSAycYQAoPCggEAAICCJwI
ABIDJxk/CmkKAgQBEgQsADIBGl0gUHJvdmlkZXMgZGV0YWlscyBmb3IgZXJyb3JzLCBlLmcu
IGlzc3VlcyB0aGF0IHdoZXJlIGVuY291bnRlcmVkIHdoZW4KIHByb2Nlc3NpbmcgYSBzdWJ0
YXNrLgoKCgoDBAEBEgMsCBMKUAoEBAECABIDLgJGGkMgT3B0aW9uYWwuIFRoZSBleGFjdCBs
b2NhdGlvbiB3aXRoaW4gdGhlIHJlc291cmNlIChpZiBhcHBsaWNhYmxlKS4KCgwKBQQBAgAG
EgMuAg8KDAoFBAECAAESAy4QGAoMCgUEAQIAAxIDLhscCgwKBQQBAgAIEgMuHUUKDwoIBAEC
AAicCAASAy4eRApRCgQEAQIBEgMxAk8aRCBSZXF1aXJlZC4gRGVzY3JpYmVzIHRoZSBjYXVz
ZSBvZiB0aGUgZXJyb3Igd2l0aCBzdHJ1Y3R1cmVkIGRldGFpbC4KCgwKBQQBAgEGEgMxAhYK
DAoFBAECAQESAzEXIQoMCgUEAQIBAxIDMSQlCgwKBQQBAgEIEgMxJk4KDwoIBAECAQicCAAS
AzEnTQpBCgIEAhIENQA9ARo1IEhvbGRzIGluZm9ybWF0aW9uIGFib3V0IHdoZXJlIHRoZSBl
cnJvciBpcyBsb2NhdGVkLgoKCgoDBAIBEgM1CBUKiQEKBAQCAgASAzgCOhp8IE9wdGlvbmFs
LiBJZiBhcHBsaWNhYmxlLCBkZW5vdGVzIHRoZSBsaW5lIHdoZXJlIHRoZSBlcnJvciBvY2N1
cnJlZC4gQSB6ZXJvIHZhbHVlCiBtZWFucyB0aGF0IHRoZXJlIGlzIG5vIGxpbmUgaW5mb3Jt
YXRpb24uCgoMCgUEAgIABRIDOAIHCgwKBQQCAgABEgM4CAwKDAoFBAICAAMSAzgPEAoMCgUE
AgIACBIDOBE5Cg8KCAQCAgAInAgAEgM4EjgKjwEKBAQCAgESAzwCPBqBASBPcHRpb25hbC4g
SWYgYXBwbGljYWJsZSwgZGVub3RlcyB0aGUgY29sdW1uIHdoZXJlIHRoZSBlcnJvciBvY2N1
cnJlZC4gQSB6ZXJvIHZhbHVlCiBtZWFucyB0aGF0IHRoZXJlIGlzIG5vIGNvbHVtbnMgaW5m
b3JtYXRpb24uCgoMCgUEAgIBBRIDPAIHCgwKBQQCAgEBEgM8CA4KDAoFBAICAQMSAzwREgoM
CgUEAgIBCBIDPBM7Cg8KCAQCAgEInAgAEgM8FDpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail ===
    # Fields for ResourceErrorDetail
    # Field: resource_info Type: 11 (.google.rpc.ResourceInfo)
    # Field: error_details Type: 11 (.google.cloud.bigquery.migration.v2alpha.ErrorDetail)
    # Field: error_count Type: 5 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorDetail ===
    # Fields for ErrorDetail
    # Field: location Type: 11 (.google.cloud.bigquery.migration.v2alpha.ErrorLocation)
    # Field: error_info Type: 11 (.google.rpc.ErrorInfo)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorLocation ===
    # Fields for ErrorLocation
    # Field: line Type: 5 ()
    # Field: column Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/migration_error_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail->new({
        resource_info => $resource_info,
        error_details => $error_details,
        error_count => $error_count,
    });

    # Read or update a field
    my $val = $msg->resource_info();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/migration_error_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail

Provides details for errors and the corresponding resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_info() >> / C<< $msg->resource_info($value) >>

Type: C<Message> (L<Google::Rpc::ErrorDetails::ResourceInfo>)

Required. Information about the resource where the error is located.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorDetail>)

Required. The error details for the resource.

=item * C<< $msg->error_count() >> / C<< $msg->error_count($value) >>

Type: C<Int32>

Required. How many errors there are in total for the resource. Truncation can be
indicated by having an `error_count` that is higher than the size of
`error_details`.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorDetail

Provides details for errors, e.g. issues that where encountered when
processing a subtask.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorLocation>)

Optional. The exact location within the resource (if applicable).

=item * C<< $msg->error_info() >> / C<< $msg->error_info($value) >>

Type: C<Message> (L<Google::Rpc::ErrorDetails::ErrorInfo>)

Required. Describes the cause of the error with structured detail.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorLocation

Holds information about where the error is located.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->line() >> / C<< $msg->line($value) >>

Type: C<Int32>

Optional. If applicable, denotes the line where the error occurred. A zero value
means that there is no line information.

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<Int32>

Optional. If applicable, denotes the column where the error occurred. A zero value
means that there is no columns information.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
