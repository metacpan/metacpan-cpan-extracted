package Google::Cloud::Bigquery::V2::JobStatus;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Bigquery::V2::Error };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvam9iX3N0YXR1cy5wcm90bxIYZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGiRnb29n
bGUvY2xvdWQvYmlncXVlcnkvdjIvZXJyb3IucHJvdG8itwEKCUpvYlN0YXR1cxJMCgxlcnJv
cl9yZXN1bHQYASABKAsyJC5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuRXJyb3JQcm90b0ID
4EEDUgtlcnJvclJlc3VsdBJBCgZlcnJvcnMYAiADKAsyJC5nb29nbGUuY2xvdWQuYmlncXVl
cnkudjIuRXJyb3JQcm90b0ID4EEDUgZlcnJvcnMSGQoFc3RhdGUYAyABKAlCA+BBA1IFc3Rh
dGVCawocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIOSm9iU3RhdHVzUHJvdG9aO2Ns
b3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlwYjtiaWdxdWVy
eXBiSqMLCgYSBA4AJwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAuCggKAQgSAxUAUgoJCgIICxIDFQBSCggKAQgS
AxYALwoJCgIICBIDFgAvCggKAQgSAxcANQoJCgIIARIDFwA1CgoKAgQAEgQZACcBCgoKAwQA
ARIDGQgRCoIBCgQEAAIAEgMcAkoadSBPdXRwdXQgb25seS4gRmluYWwgZXJyb3IgcmVzdWx0
IG9mIHRoZSBqb2IuIElmIHByZXNlbnQsIGluZGljYXRlcyB0aGF0IHRoZQogam9iIGhhcyBj
b21wbGV0ZWQgYW5kIHdhcyB1bnN1Y2Nlc3NmdWwuCgoMCgUEAAIABhIDHAIMCgwKBQQAAgAB
EgMcDRkKDAoFBAACAAMSAxwcHQoMCgUEAAIACBIDHB5JCg8KCAQAAgAInAgAEgMcH0gKhAIK
BAQAAgESAyICTRr2ASBPdXRwdXQgb25seS4gVGhlIGZpcnN0IGVycm9ycyBlbmNvdW50ZXJl
ZCBkdXJpbmcgdGhlIHJ1bm5pbmcgb2YgdGhlIGpvYi4KIFRoZSBmaW5hbCBtZXNzYWdlIGlu
Y2x1ZGVzIHRoZSBudW1iZXIgb2YgZXJyb3JzIHRoYXQgY2F1c2VkIHRoZSBwcm9jZXNzIHRv
CiBzdG9wLiBFcnJvcnMgaGVyZSBkbyBub3QgbmVjZXNzYXJpbHkgbWVhbiB0aGF0IHRoZSBq
b2IgaGFzIG5vdCBjb21wbGV0ZWQgb3IKIHdhcyB1bnN1Y2Nlc3NmdWwuCgoMCgUEAAIBBBID
IgIKCgwKBQQAAgEGEgMiCxUKDAoFBAACAQESAyIWHAoMCgUEAAIBAxIDIh8gCgwKBQQAAgEI
EgMiIUwKDwoIBAACAQicCAASAyIiSwpuCgQEAAICEgMmAj8aYSBPdXRwdXQgb25seS4gUnVu
bmluZyBzdGF0ZSBvZiB0aGUgam9iLiAgVmFsaWQgc3RhdGVzIGluY2x1ZGUgJ1BFTkRJTkcn
LAogJ1JVTk5JTkcnLCBhbmQgJ0RPTkUnLgoKDAoFBAACAgUSAyYCCAoMCgUEAAICARIDJgkO
CgwKBQQAAgIDEgMmERIKDAoFBAACAggSAyYTPgoPCggEAAICCJwIABIDJhQ9YgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::JobStatus::JobStatus ===
    # Fields for JobStatus
    # Field: error_result Type: 11 (.google.cloud.bigquery.v2.ErrorProto)
    # Field: errors Type: 11 (.google.cloud.bigquery.v2.ErrorProto)
    # Field: state Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::JobStatus - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/job_status.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::JobStatus;

    my $msg = Google::Cloud::Bigquery::V2::JobStatus::JobStatus->new({
        error_result => $error_result,
        errors => $errors,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->error_result();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::JobStatus::JobStatus->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/job_status.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::JobStatus::JobStatus

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_result() >> / C<< $msg->error_result($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::Error::ErrorProto>)

Output only. Final error result of the job. If present, indicates that the
job has completed and was unsuccessful.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::Error::ErrorProto>)

Output only. The first errors encountered during the running of the job.
The final message includes the number of errors that caused the process to
stop. Errors here do not necessarily mean that the job has not completed or
was unsuccessful.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<String>

Output only. Running state of the job.  Valid states include 'PENDING',
'RUNNING', and 'DONE'.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::JobStatus::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
