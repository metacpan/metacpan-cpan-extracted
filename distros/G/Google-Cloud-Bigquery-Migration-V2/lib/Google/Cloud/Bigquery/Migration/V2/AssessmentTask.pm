package Google::Cloud::Bigquery::Migration::V2::AssessmentTask;

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
Cjhnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL2Fzc2Vzc21lbnRfdGFzay5w
cm90bxIiZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MhofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90byK6AgoVQXNzZXNzbWVudFRhc2tEZXRhaWxzEiIKCmlucHV0
X3BhdGgYASABKAlCA+BBAlIJaW5wdXRQYXRoEioKDm91dHB1dF9kYXRhc2V0GAIgASgJQgPg
QQJSDW91dHB1dERhdGFzZXQSKgoOcXVlcnlsb2dzX3BhdGgYAyABKAlCA+BBAVINcXVlcnls
b2dzUGF0aBIkCgtkYXRhX3NvdXJjZRgEIAEoCUID4EECUgpkYXRhU291cmNlEmwKDmZlYXR1
cmVfaGFuZGxlGAYgASgLMjsuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5B
c3Nlc3NtZW50RmVhdHVyZUhhbmRsZUID4EEBSABSDWZlYXR1cmVIYW5kbGWIAQFCEQoPX2Zl
YXR1cmVfaGFuZGxlInEKF0Fzc2Vzc21lbnRGZWF0dXJlSGFuZGxlEjwKFWFkZF9zaGFyZWFi
bGVfZGF0YXNldBgBIAEoCEID4EEBSABSE2FkZFNoYXJlYWJsZURhdGFzZXSIAQFCGAoWX2Fk
ZF9zaGFyZWFibGVfZGF0YXNldELPAQomY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdy
YXRpb24udjJCE0Fzc2Vzc21lbnRUYXNrUHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9i
aWdxdWVyeS9taWdyYXRpb24vYXBpdjIvbWlncmF0aW9ucGI7bWlncmF0aW9ucGKqAiJHb29n
bGUuQ2xvdWQuQmlnUXVlcnkuTWlncmF0aW9uLlYyygIiR29vZ2xlXENsb3VkXEJpZ1F1ZXJ5
XE1pZ3JhdGlvblxWMkqWDwoGEgQOADYBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAArCgkKAgMAEgMSACkKCAoBCBIDFAA/CgkKAgglEgMUAD8KCAoBCBID
FQBbCgkKAggLEgMVAFsKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA0CgkKAggIEgMX
ADQKCAoBCBIDGAA/CgkKAggBEgMYAD8KCAoBCBIDGQBACgkKAggpEgMZAEAKJQoCBAASBBwA
LgEaGSBBc3Nlc3NtZW50IHRhc2sgY29uZmlnLgoKCgoDBAABEgMcCB0KSwoEBAACABIDHgJB
Gj4gUmVxdWlyZWQuIFRoZSBDbG91ZCBTdG9yYWdlIHBhdGggZm9yIGFzc2Vzc21lbnQgaW5w
dXQgZmlsZXMuCgoMCgUEAAIABRIDHgIICgwKBQQAAgABEgMeCRMKDAoFBAACAAMSAx4WFwoM
CgUEAAIACBIDHhhACg8KCAQAAgAInAgAEgMeGT8KOQoEBAACARIDIQJFGiwgUmVxdWlyZWQu
IFRoZSBCaWdRdWVyeSBkYXRhc2V0IGZvciBvdXRwdXQuCgoMCgUEAAIBBRIDIQIICgwKBQQA
AgEBEgMhCRcKDAoFBAACAQMSAyEaGwoMCgUEAAIBCBIDIRxECg8KCAQAAgEInAgAEgMhHUMK
jwEKBAQAAgISAyUCRRqBASBPcHRpb25hbC4gQW4gb3B0aW9uYWwgQ2xvdWQgU3RvcmFnZSBw
YXRoIHRvIHdyaXRlIHRoZSBxdWVyeSBsb2dzICh3aGljaCBpcwogdGhlbiB1c2VkIGFzIGFu
IGlucHV0IHBhdGggb24gdGhlIHRyYW5zbGF0aW9uIHRhc2spCgoMCgUEAAICBRIDJQIICgwK
BQQAAgIBEgMlCRcKDAoFBAACAgMSAyUaGwoMCgUEAAICCBIDJRxECg8KCAQAAgIInAgAEgMl
HUMKgAEKBAQAAgMSAykCQhpzIFJlcXVpcmVkLiBUaGUgZGF0YSBzb3VyY2Ugb3IgZGF0YSB3
YXJlaG91c2UgdHlwZSAoZWc6IFRFUkFEQVRBL1JFRFNISUZUKQogZnJvbSB3aGljaCB0aGUg
aW5wdXQgZGF0YSBpcyBleHRyYWN0ZWQuCgoMCgUEAAIDBRIDKQIICgwKBQQAAgMBEgMpCRQK
DAoFBAACAwMSAykXGAoMCgUEAAIDCBIDKRlBCg8KCAQAAgMInAgAEgMpGkAKVwoEBAACBBIE
LAItLxpJIE9wdGlvbmFsLiBBIGNvbGxlY3Rpb24gb2YgYWRkaXRpb25hbCBmZWF0dXJlIGZs
YWdzIGZvciB0aGlzIGFzc2Vzc21lbnQuCgoMCgUEAAIEBBIDLAIKCgwKBQQAAgQGEgMsCyIK
DAoFBAACBAESAywjMQoMCgUEAAIEAxIDLDQ1CgwKBQQAAgQIEgMtBi4KDwoIBAACBAicCAAS
Ay0HLQpACgIEARIEMQA2ARo0IFVzZXItZGVmaW5hYmxlIGZlYXR1cmUgZmxhZ3MgZm9yIGFz
c2Vzc21lbnQgdGFza3MuCgoKCgMEAQESAzEIHwpxCgQEAQIAEgQ0AjUvGmMgT3B0aW9uYWwu
IFdoZXRoZXIgdG8gY3JlYXRlIGEgZGF0YXNldCBjb250YWluaW5nIG5vbi1QSUkgZGF0YSBp
biBhZGRpdGlvbgogdG8gdGhlIG91dHB1dCBkYXRhc2V0LgoKDAoFBAECAAQSAzQCCgoMCgUE
AQIABRIDNAsPCgwKBQQBAgABEgM0ECUKDAoFBAECAAMSAzQoKQoMCgUEAQIACBIDNQYuCg8K
CAQBAgAInAgAEgM1By1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails ===
    # Fields for AssessmentTaskDetails
    # Field: input_path Type: 9 ()
    # Field: output_dataset Type: 9 ()
    # Field: querylogs_path Type: 9 ()
    # Field: data_source Type: 9 ()
    # Field: feature_handle Type: 11 (.google.cloud.bigquery.migration.v2.AssessmentFeatureHandle)

# === Message: Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentFeatureHandle ===
    # Fields for AssessmentFeatureHandle
    # Field: add_shareable_dataset Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::AssessmentTask - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/assessment_task.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::AssessmentTask;

    my $msg = Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails->new({
        input_path => $input_path,
        output_dataset => $output_dataset,
        querylogs_path => $querylogs_path,
        data_source => $data_source,
    });

    # Read or update a field
    my $val = $msg->input_path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/assessment_task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails

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

=item * C<< $msg->feature_handle() >> / C<< $msg->feature_handle($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentFeatureHandle>)

Optional. A collection of additional feature flags for this assessment.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentFeatureHandle

User-definable feature flags for assessment tasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->add_shareable_dataset() >> / C<< $msg->add_shareable_dataset($value) >>

Type: C<Bool>

Optional. Whether to create a dataset containing non-PII data in addition
to the output dataset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::AssessmentTask::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
