package Google::Cloud::Bigquery::V2::JobReference;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvam9iX3JlZmVyZW5jZS5wcm90bxIYZ29vZ2xl
LmNsb3VkLmJpZ3F1ZXJ5LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh5n
b29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8ijQEKDEpvYlJlZmVyZW5jZRIiCgpwcm9q
ZWN0X2lkGAEgASgJQgPgQQJSCXByb2plY3RJZBIaCgZqb2JfaWQYAiABKAlCA+BBAlIFam9i
SWQSPQoIbG9jYXRpb24YAyABKAsyHC5nb29nbGUucHJvdG9idWYuU3RyaW5nVmFsdWVCA+BB
AVIIbG9jYXRpb25CbgocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIRSm9iUmVmZXJl
bmNlUHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVl
cnlwYjtiaWdxdWVyeXBiSqALCgYSBA4AKQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAoCggKAQgSAxUAUgoJCgII
CxIDFQBSCggKAQgSAxYAMgoJCgIICBIDFgAyCggKAQgSAxcANQoJCgIIARIDFwA1ClUKAgQA
EgQaACkBGkkgQSBqb2IgcmVmZXJlbmNlIGlzIGEgZnVsbHkgcXVhbGlmaWVkIGlkZW50aWZp
ZXIgZm9yIHJlZmVycmluZyB0byBhIGpvYi4KCgoKAwQAARIDGggUCkMKBAQAAgASAxwCQRo2
IFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIHByb2plY3QgY29udGFpbmluZyB0aGlzIGpvYi4K
CgwKBQQAAgAFEgMcAggKDAoFBAACAAESAxwJEwoMCgUEAAIAAxIDHBYXCgwKBQQAAgAIEgMc
GEAKDwoIBAACAAicCAASAxwZPwqyAQoEBAACARIDIQI9GqQBIFJlcXVpcmVkLiBUaGUgSUQg
b2YgdGhlIGpvYi4gVGhlIElEIG11c3QgY29udGFpbiBvbmx5IGxldHRlcnMgKGEteiwgQS1a
KSwKIG51bWJlcnMgKDAtOSksIHVuZGVyc2NvcmVzIChfKSwgb3IgZGFzaGVzICgtKS4gVGhl
IG1heGltdW0gbGVuZ3RoIGlzIDEsMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAQUSAyECCAoM
CgUEAAIBARIDIQkPCgwKBQQAAgEDEgMhEhMKDAoFBAACAQgSAyEUPAoPCggEAAIBCJwIABID
IRU7Cr8BCgQEAAICEgQnAigvGrABIE9wdGlvbmFsLiBUaGUgZ2VvZ3JhcGhpYyBsb2NhdGlv
biBvZiB0aGUgam9iLiBUaGUgZGVmYXVsdCB2YWx1ZSBpcyBVUy4KCiBGb3IgbW9yZSBpbmZv
cm1hdGlvbiBhYm91dCBCaWdRdWVyeSBsb2NhdGlvbnMsIHNlZToKIGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL2xvY2F0aW9ucwoKDAoFBAACAgYSAycCHQoMCgUE
AAICARIDJx4mCgwKBQQAAgIDEgMnKSoKDAoFBAACAggSAygGLgoPCggEAAICCJwIABIDKAct
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::JobReference::JobReference ===
    # Fields for JobReference
    # Field: project_id Type: 9 ()
    # Field: job_id Type: 9 ()
    # Field: location Type: 11 (.google.protobuf.StringValue)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::JobReference - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/job_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::JobReference;

    my $msg = Google::Cloud::Bigquery::V2::JobReference::JobReference->new({
        project_id => $project_id,
        job_id => $job_id,
        location => $location,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::JobReference::JobReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/job_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::JobReference::JobReference

A job reference is a fully qualified identifier for referring to a job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the project containing this job.

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

Required. The ID of the job. The ID must contain only letters (a-z, A-Z),
numbers (0-9), underscores (_), or dashes (-). The maximum length is 1,024
characters.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::StringValue>)

Optional. The geographic location of the job. The default value is US.

For more information about BigQuery locations, see:
https://cloud.google.com/bigquery/docs/locations

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::JobReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
