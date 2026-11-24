package Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask;

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
Cj1nb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvYXNzZXNzbWVudF90
YXNrLnByb3RvEidnb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iuQEKFUFzc2Vzc21lbnRUYXNrRGV0YWls
cxIiCgppbnB1dF9wYXRoGAEgASgJQgPgQQJSCWlucHV0UGF0aBIqCg5vdXRwdXRfZGF0YXNl
dBgCIAEoCUID4EECUg1vdXRwdXREYXRhc2V0EioKDnF1ZXJ5bG9nc19wYXRoGAMgASgJQgPg
QQFSDXF1ZXJ5bG9nc1BhdGgSJAoLZGF0YV9zb3VyY2UYBCABKAlCA+BBAlIKZGF0YVNvdXJj
ZSJsCiRBc3Nlc3NtZW50T3JjaGVzdHJhdGlvblJlc3VsdERldGFpbHMSRAocb3V0cHV0X3Rh
Ymxlc19zY2hlbWFfdmVyc2lvbhgBIAEoCUID4EEBUhlvdXRwdXRUYWJsZXNTY2hlbWFWZXJz
aW9uQuMBCitjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhQhNB
c3Nlc3NtZW50VGFza1Byb3RvUAFaSWNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWln
cmF0aW9uL2FwaXYyYWxwaGEvbWlncmF0aW9ucGI7bWlncmF0aW9ucGKqAidHb29nbGUuQ2xv
dWQuQmlnUXVlcnkuTWlncmF0aW9uLlYyQWxwaGHKAidHb29nbGVcQ2xvdWRcQmlnUXVlcnlc
TWlncmF0aW9uXFYyYWxwaGFKsA0KBhIEDgAwAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAMAoJCgIDABIDEgApCggKAQgSAxQARAoJCgIIJRIDFABECggK
AQgSAxUAYAoJCgIICxIDFQBgCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANAoJCgII
CBIDFwA0CggKAQgSAxgARAoJCgIIARIDGABECggKAQgSAxkARQoJCgIIKRIDGQBFCiUKAgQA
EgQcACoBGhkgQXNzZXNzbWVudCB0YXNrIGNvbmZpZy4KCgoKAwQAARIDHAgdCksKBAQAAgAS
Ax4CQRo+IFJlcXVpcmVkLiBUaGUgQ2xvdWQgU3RvcmFnZSBwYXRoIGZvciBhc3Nlc3NtZW50
IGlucHV0IGZpbGVzLgoKDAoFBAACAAUSAx4CCAoMCgUEAAIAARIDHgkTCgwKBQQAAgADEgMe
FhcKDAoFBAACAAgSAx4YQAoPCggEAAIACJwIABIDHhk/CjkKBAQAAgESAyECRRosIFJlcXVp
cmVkLiBUaGUgQmlnUXVlcnkgZGF0YXNldCBmb3Igb3V0cHV0LgoKDAoFBAACAQUSAyECCAoM
CgUEAAIBARIDIQkXCgwKBQQAAgEDEgMhGhsKDAoFBAACAQgSAyEcRAoPCggEAAIBCJwIABID
IR1DCo8BCgQEAAICEgMlAkUagQEgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIENsb3VkIFN0b3Jh
Z2UgcGF0aCB0byB3cml0ZSB0aGUgcXVlcnkgbG9ncyAod2hpY2ggaXMKIHRoZW4gdXNlZCBh
cyBhbiBpbnB1dCBwYXRoIG9uIHRoZSB0cmFuc2xhdGlvbiB0YXNrKQoKDAoFBAACAgUSAyUC
CAoMCgUEAAICARIDJQkXCgwKBQQAAgIDEgMlGhsKDAoFBAACAggSAyUcRAoPCggEAAICCJwI
ABIDJR1DCoABCgQEAAIDEgMpAkIacyBSZXF1aXJlZC4gVGhlIGRhdGEgc291cmNlIG9yIGRh
dGEgd2FyZWhvdXNlIHR5cGUgKGVnOiBURVJBREFUQS9SRURTSElGVCkKIGZyb20gd2hpY2gg
dGhlIGlucHV0IGRhdGEgaXMgZXh0cmFjdGVkLgoKDAoFBAACAwUSAykCCAoMCgUEAAIDARID
KQkUCgwKBQQAAgMDEgMpFxgKDAoFBAACAwgSAykZQQoPCggEAAIDCJwIABIDKRpACkIKAgQB
EgQtADABGjYgRGV0YWlscyBmb3IgYW4gYXNzZXNzbWVudCB0YXNrIG9yY2hlc3RyYXRpb24g
cmVzdWx0LgoKCgoDBAEBEgMtCCwKRwoEBAECABIDLwJTGjogT3B0aW9uYWwuIFRoZSB2ZXJz
aW9uIHVzZWQgZm9yIHRoZSBvdXRwdXQgdGFibGUgc2NoZW1hcy4KCgwKBQQBAgAFEgMvAggK
DAoFBAECAAESAy8JJQoMCgUEAQIAAxIDLygpCgwKBQQBAgAIEgMvKlIKDwoIBAECAAicCAAS
Ay8rUWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentTaskDetails ===
    # Fields for AssessmentTaskDetails
    # Field: input_path Type: 9 ()
    # Field: output_dataset Type: 9 ()
    # Field: querylogs_path Type: 9 ()
    # Field: data_source Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentOrchestrationResultDetails ===
    # Fields for AssessmentOrchestrationResultDetails
    # Field: output_tables_schema_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/assessment_task.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentTaskDetails->new({
        input_path => $input_path,
        output_dataset => $output_dataset,
        querylogs_path => $querylogs_path,
        data_source => $data_source,
    });

    # Read or update a field
    my $val = $msg->input_path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentTaskDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/assessment_task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentTaskDetails

Assessment task config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_path() >> / C<< $msg->input_path($value) >>

Type: C<String>

Required. The Cloud Storage path for assessment input files.

=item * C<< $msg->output_dataset() >> / C<< $msg->output_dataset($value) >>

Type: C<String>

Required. The BigQuery dataset for output.

=item * C<< $msg->querylogs_path() >> / C<< $msg->querylogs_path($value) >>

Type: C<String>

Optional. An optional Cloud Storage path to write the query logs (which is
then used as an input path on the translation task)

=item * C<< $msg->data_source() >> / C<< $msg->data_source($value) >>

Type: C<String>

Required. The data source or data warehouse type (eg: TERADATA/REDSHIFT)
from which the input data is extracted.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentOrchestrationResultDetails

Details for an assessment task orchestration result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_tables_schema_version() >> / C<< $msg->output_tables_schema_version($value) >>

Type: C<String>

Optional. The version used for the output table schemas.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
